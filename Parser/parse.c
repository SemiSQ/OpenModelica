/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Link�pings University,
 * Department of Computer and Information Science,
 * SE-58183 Link�ping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Link�pings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifdef __cplusplus
/* Make sure we don't use any C++ features anywhere */
#define __cplusplusend
#undef __cplusplus
extern "C" {
#else
#define bool int
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <MetaModelica_Lexer.h>
#include <Modelica_3_Lexer.h>
#include <ModelicaParser.h>
#include <antlr3intstream.h>

#include "runtime/errorext.h"
#include "runtime/rtopts.h" /* for accept_meta_modelica_grammar() function */

static long unsigned int szMemoryUsed = 0;
static long lexerFailed;

static void lexNoRecover(pANTLR3_LEXER lexer)
{
  pANTLR3_INT_STREAM inputStream = NULL;
  lexer->rec->state->error = ANTLR3_TRUE;
  lexer->rec->state->failed = ANTLR3_TRUE;
  inputStream = lexer->input->istream;
  inputStream->consume(inputStream);
}

static void noRecover(pANTLR3_BASE_RECOGNIZER recognizer)
{
  recognizer->state->error = ANTLR3_TRUE;
  recognizer->state->failed = ANTLR3_TRUE;
}

static void* noRecoverFromMismatchedSet(pANTLR3_BASE_RECOGNIZER recognizer, pANTLR3_BITSET_LIST follow)
{
  recognizer->state->error  = ANTLR3_TRUE;
  recognizer->state->failed = ANTLR3_TRUE;
  return NULL;
}

static void* noRecoverFromMismatchedToken(pANTLR3_BASE_RECOGNIZER recognizer, ANTLR3_UINT32 ttype, pANTLR3_BITSET_LIST follow)
{
  pANTLR3_PARSER        parser;
  pANTLR3_TREE_PARSER        tparser;
  pANTLR3_INT_STREAM        is;
  void          * matchedSymbol;

  // Invoke the debugger event if there is a debugger listening to us
  //
  if  (recognizer->debugger != NULL)
  {
    recognizer->debugger->recognitionException(recognizer->debugger, recognizer->state->exception);
  }

  switch  (recognizer->type)
  {
  case  ANTLR3_TYPE_PARSER:

    parser  = (pANTLR3_PARSER) (recognizer->super);
    tparser  = NULL;
    is  = parser->tstream->istream;

    break;

  case  ANTLR3_TYPE_TREE_PARSER:

    tparser = (pANTLR3_TREE_PARSER) (recognizer->super);
    parser  = NULL;
    is  = tparser->ctnstream->tnstream->istream;

    break;

  default:

    ANTLR3_FPRINTF(stderr, "Base recognizer function recoverFromMismatchedToken called by unknown parser type - provide override for this function\n");
    return NULL;

    break;
  }
  recognizer->state->failed = ANTLR3_TRUE;

  // Create an exception if we need one
  //
  if  (recognizer->state->exception == NULL)
  {
    antlr3RecognitionExceptionNew(recognizer);
  }

  if  ( recognizer->mismatchIsUnwantedToken(recognizer, is, ttype) == ANTLR3_TRUE)
  {
    recognizer->state->exception->type    = ANTLR3_UNWANTED_TOKEN_EXCEPTION;
    recognizer->state->exception->message  = (void*)ANTLR3_UNWANTED_TOKEN_EXCEPTION_NAME;
    recognizer->state->exception->expecting  = ttype;
    return NULL;
  }

  if  (recognizer->mismatchIsMissingToken(recognizer, is, follow))
  {
    matchedSymbol = recognizer->getMissingSymbol(recognizer, is, recognizer->state->exception, ttype, follow);
    recognizer->state->exception->type    = ANTLR3_MISSING_TOKEN_EXCEPTION;
    recognizer->state->exception->message  = (void*)ANTLR3_MISSING_TOKEN_EXCEPTION_NAME;
    recognizer->state->exception->token    = matchedSymbol;
    recognizer->state->exception->expecting  = ttype;
    return NULL;
  }

  // Neither deleting nor inserting tokens allows recovery
  // must just report the exception.
  //
  recognizer->state->error      = ANTLR3_TRUE;
  return NULL;
}

static void handleLexerError(pANTLR3_BASE_RECOGNIZER recognizer, pANTLR3_UINT8 * tokenNames)
{
  pANTLR3_LEXER lexer = (pANTLR3_LEXER)(recognizer->super);
  pANTLR3_EXCEPTION ex = lexer->rec->state->exception;
  pANTLR3_STRING ftext;
  int isEOF = lexer->input->istream->_LA(lexer->input->istream, 1) == -1;
  char* chars[] = {
    isEOF ? strdup("<EOF>") : strdup((const char*)(lexer->input->substr(lexer->input, lexer->getCharIndex(lexer), lexer->getCharIndex(lexer)+10)->chars)),
    strdup((const char*)lexer->getText(lexer)->chars)
  };
  int line = 0;
  int offset = 0;

  if (strlen(chars[1]) > 20)
    chars[1][20] = '\0';
  line = lexer->getLine(lexer);
  offset = lexer->getCharPositionInLine(lexer)+1;
  if (*chars[1])
    c_add_source_message(2, "SYNTAX", "Error", "Lexer got '%s' but failed to recognize the rest: '%s'", (const char**) chars, 2, line, offset, line, offset, false, ModelicaParser_filename_C);
  else
    c_add_source_message(2, "SYNTAX", "Error", "Lexer failed to recognize '%s'", (const char**) chars, 1, line, offset, line, offset, false, ModelicaParser_filename_C);
  lexerFailed = ANTLR3_TRUE;
  free(chars[0]);
  free(chars[1]);
}

/* Error handling based on antlr3baserecognizer.c */
static void handleParseError(pANTLR3_BASE_RECOGNIZER recognizer, pANTLR3_UINT8 * tokenNames)
{
  pANTLR3_PARSER      parser;
  pANTLR3_INT_STREAM  is;
  pANTLR3_STRING      ttext;
  pANTLR3_EXCEPTION      ex;
  pANTLR3_COMMON_TOKEN   preToken,nextToken;
  pANTLR3_BASE_TREE      theBaseTree;
  pANTLR3_COMMON_TREE    theCommonTree;
  pANTLR3_TOKEN_STREAM tokenStream;
  ANTLR3_UINT32 ttype;
  int type;
  const char *error_type = "TRANSLATION";
  const char *token_text[3] = {0,0,0};
  int p_offset, n_offset, error_id = 0, p_line, n_line;
  recognizer->state->error = ANTLR3_TRUE;
  recognizer->state->failed = ANTLR3_TRUE;

  if (lexerFailed)
    return;

  // Retrieve some info for easy reading.
  ex      =    recognizer->state->exception;
  ttext   =    NULL;

  switch  (recognizer->type)
  {
  case  ANTLR3_TYPE_PARSER:
    parser = (pANTLR3_PARSER) (recognizer->super);
    token_text[1] = (const char*) ex->message;
    type = ex->type;
    tokenStream = parser->getTokenStream(parser);
    preToken = tokenStream->_LT(tokenStream,1);
    nextToken = tokenStream->_LT(tokenStream,2);
    if (preToken == NULL) preToken = nextToken;
    p_line = preToken->line;
    n_line = nextToken->line;
    p_offset = preToken->charPosition+1;
    n_offset = nextToken->charPosition;
    break;

  default:

    ANTLR3_FPRINTF(stderr, "Base recognizer function displayRecognitionError called by unknown parser type - provide override for this function\n");
    return;
    break;
  }

  switch (type) {
  case ANTLR3_UNWANTED_TOKEN_EXCEPTION:
    token_text[0] = ex->expecting == ANTLR3_TOKEN_EOF ? "<EOF>" : (const char*) tokenNames[ex->expecting];
    c_add_source_message(2, "SYNTAX", "Error", "Unwanted token: %s", token_text, 1, p_line, p_offset, n_line, n_offset, false, ModelicaParser_filename_C);
    break;
  case ANTLR3_MISSING_TOKEN_EXCEPTION:
    token_text[0] = ex->expecting == ANTLR3_TOKEN_EOF ? "<EOF>" : (const char*) tokenNames[ex->expecting];
    c_add_source_message(2, "SYNTAX", "Error", "Missing token: %s", token_text, 1, p_line, p_offset, p_line, p_offset, false, ModelicaParser_filename_C);
    break;
  case ANTLR3_NO_VIABLE_ALT_EXCEPTION:
    token_text[0] = preToken->type == ANTLR3_TOKEN_EOF ? "<EOF>" : (const char*)preToken->getText(preToken)->chars;
    if (preToken->type == ANTLR3_TOKEN_EOF) n_offset = p_offset;
    c_add_source_message(2, "SYNTAX", "Error", "No viable alternative near token: %s", token_text, 1, p_line, p_offset, n_line, n_offset, false, ModelicaParser_filename_C);
    break;
  case ModelicaParserException:
    {
      fileinfo* info = (fileinfo*) ex->custom;
      c_add_source_message(2, "SYNTAX", "Error", "Parse error: %s", token_text+1, 1, info->line1, info->offset1, info->line2, info->offset2, false, ModelicaParser_filename_C);
      free(info);
      ex->custom = 0;
      break;
    }
  case ANTLR3_MISMATCHED_SET_EXCEPTION:
  case ANTLR3_EARLY_EXIT_EXCEPTION:
  case ANTLR3_RECOGNITION_EXCEPTION:
  default:
    token_text[2] = (const char*)ex->message;
    token_text[1] = preToken->type == ANTLR3_TOKEN_EOF ? "" : (const char*)preToken->getText(preToken)->chars;
    token_text[0] = preToken->type == ANTLR3_TOKEN_EOF ? "<EOF>" : (const char*) tokenNames[preToken->type];
    if (preToken->type == ANTLR3_TOKEN_EOF) n_offset = p_offset;
    c_add_source_message(2, "SYNTAX", "Error", "Parser error: %s near: %s (%s)", token_text, 3, p_line, p_offset, n_line, n_offset, false, ModelicaParser_filename_C);
    break;
  }

}

static void* parseStream(pANTLR3_INPUT_STREAM input)
{
  pANTLR3_LEXER               pLexer;
  pANTLR3_COMMON_TOKEN_STREAM tstream;
  pModelicaParser             psr;
  void* lxr = 0;
  void* res = NULL;

  // TODO: Add flags to the actual Parser.parse() call instead of here?
  if (RTOptsImpl__acceptMetaModelicaGrammar()) ModelicaParser_flags |= PARSE_META_MODELICA;

  if (ModelicaParser_flags & PARSE_META_MODELICA) {
    lxr = MetaModelica_LexerNew(input);
    if (lxr == NULL ) { fprintf(stderr, "Unable to create the lexer due to malloc() failure1\n"); exit(ANTLR3_ERR_NOMEM); }
    pLexer = ((pMetaModelica_Lexer)lxr)->pLexer;
    pLexer->rec->displayRecognitionError = handleLexerError;
    pLexer->recover = lexNoRecover;
    tstream = antlr3CommonTokenStreamSourceNew(ANTLR3_SIZE_HINT, TOKENSOURCE(((pMetaModelica_Lexer)lxr)));
  } else {
    lxr = Modelica_3_LexerNew(input);
    if (lxr == NULL ) { fprintf(stderr, "Unable to create the lexer due to malloc() failure1\n"); exit(ANTLR3_ERR_NOMEM); }
    pLexer = ((pModelica_3_Lexer)lxr)->pLexer;
    pLexer->rec->displayRecognitionError = handleLexerError;
    pLexer->recover = lexNoRecover;
    tstream = antlr3CommonTokenStreamSourceNew(ANTLR3_SIZE_HINT, TOKENSOURCE(((pModelica_3_Lexer)lxr)));
  }
  lexerFailed = ANTLR3_FALSE;

  if (tstream == NULL) { fprintf(stderr, "Out of memory trying to allocate token stream\n"); exit(ANTLR3_ERR_NOMEM); }
  tstream->channel = ANTLR3_TOKEN_DEFAULT_CHANNEL;
  tstream->discardOffChannel = ANTLR3_TRUE;
  tstream->discardOffChannelToks(tstream, ANTLR3_TRUE);

  // Finally, now that we have our lexer constructed, create the parser
  psr      = ModelicaParserNew(tstream);  // ModelicaParserNew is generated by ANTLR3

  if (tstream == NULL) { fprintf(stderr, "Out of memory trying to allocate parser\n"); exit(ANTLR3_ERR_NOMEM); }

  psr->pParser->rec->displayRecognitionError = handleParseError;
  psr->pParser->rec->recover = noRecover;
  psr->pParser->rec->recoverFromMismatchedToken = noRecoverFromMismatchedToken;
  // psr->pParser->rec->recoverFromMismatchedSet = noRecoverFromMismatchedSet;

  /* if (ModelicaParser_flags & PARSE_FLAT)
    res = psr->flat_class(psr);
  else */ if (ModelicaParser_flags & PARSE_EXPRESSION)
    res = psr->interactive_stmt(psr);
  else
    res = psr->stored_definition(psr);

  if (lexerFailed || pLexer->rec->state->failed || psr->pParser->rec->state->failed) // Some parts of the AST are NULL if errors are used...
    res = NULL;
  psr->free(psr);
  psr = NULL;
  tstream->free(tstream);
  tstream = NULL;
  if (ModelicaParser_flags & PARSE_META_MODELICA) {
    ((pMetaModelica_Lexer)lxr)->free((pMetaModelica_Lexer)lxr);
  } else {
    ((pModelica_3_Lexer)lxr)->free((pModelica_3_Lexer)lxr);
  }
  lxr = NULL;
  input->close(input);
  input = NULL;

  return res;
}

static void* parseFile(const char* fileName, int flags)
{
  bool debug         = check_debug_flag("parsedebug");
  bool parsedump     = check_debug_flag("parsedump");
  bool parseonly     = check_debug_flag("parseonly");

  pANTLR3_UINT8               fName;
  pANTLR3_INPUT_STREAM        input;
  int len = 0;

  ModelicaParser_filename_C = fileName;
  /* For some reason we get undefined values if we use the old pointer; but only in rare cases */
  ModelicaParser_filename_RML = mk_scon(ModelicaParser_filename_C);
  ModelicaParser_flags = flags;

  if (debug) { fprintf(stderr, "Starting parsing of file: %s\n", ModelicaParser_filename_C); }

  len = strlen(ModelicaParser_filename_C);
  if (len > 3 && 0==strcmp(ModelicaParser_filename_C+len-4,".mof"))
    ModelicaParser_flags |= PARSE_FLAT;

  fName  = (pANTLR3_UINT8)ModelicaParser_filename_C;
  input  = antlr3AsciiFileStreamNew(fName);
  if ( input == NULL ) {
    return NULL;
  }
  return parseStream(input);
}

static void* parseString(const char* data, int flags)
{
  bool debug         = check_debug_flag("parsedebug");
  bool parsedump     = check_debug_flag("parsedump");
  bool parseonly     = check_debug_flag("parseonly");

  pANTLR3_UINT8               fName;
  pANTLR3_INPUT_STREAM        input;

  ModelicaParser_filename_C = "<interactive>";
  ModelicaParser_filename_RML = mk_scon((char*)ModelicaParser_filename_C);
  ModelicaParser_flags = flags;

  if (debug) { fprintf(stderr, "Starting parsing of file: %s\n", ModelicaParser_filename_C); }

  fName  = (pANTLR3_UINT8)ModelicaParser_filename_C;
  input  = antlr3NewAsciiStringInPlaceStream((pANTLR3_UINT8)data,strlen(data),fName);
  if ( input == NULL ) {
    fprintf(stderr, "Unable to open file %s\n", ModelicaParser_filename_C);
    return NULL;
  }
  return parseStream(input);
}

#ifdef __cplusplusend
}
#endif
