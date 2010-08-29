/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linkoping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
grammar Modelica;

options {
  ASTLabelType = pANTLR3_BASE_TREE;
  language = C;
}

tokens {
  T_ALGORITHM  = 'algorithm'  ;
  T_AND    = 'and'    ;
  T_ANNOTATION  = 'annotation'  ;
  BLOCK    = 'block'  ;
  CODE    = '$Code'  ;
  CLASS    = 'class'  ;
  CONNECT  = 'connect'  ;
  CONNECTOR  = 'connector'  ;
  CONSTANT  = 'constant'  ;
  DISCRETE  = 'discrete'  ;
  DER           = 'der'   ;
  DEFINEUNIT    = 'defineunit'  ;
  EACH    = 'each'  ;
  ELSE    = 'else'  ;
  ELSEIF  = 'elseif'  ;
  ELSEWHEN  = 'elsewhen'  ;
  T_END    = 'end'    ;
  ENUMERATION  = 'enumeration'  ;
  EQUATION  = 'equation'  ;
  ENCAPSULATED  = 'encapsulated';
  EXPANDABLE  = 'expandable'  ;
  EXTENDS  = 'extends'     ;
  CONSTRAINEDBY = 'constrainedby' ;
  EXTERNAL  = 'external'  ;
  T_FALSE  = 'false'  ;
  FINAL    = 'final'  ;
  FLOW    = 'flow'  ;
  FOR    = 'for'    ;
  FUNCTION  = 'function'  ;
  IF    = 'if'    ;
  IMPORT  = 'import'  ;
  T_IN    = 'in'    ;
  INITIAL  = 'initial'  ;
  INNER    = 'inner'  ;
  T_INPUT  = 'input'  ;
  LOOP    = 'loop'  ;
  MODEL    = 'model'  ;
  T_NOT    = 'not'    ;
  T_OUTER  = 'outer'  ;
  OPERATOR  = 'operator'; 
  OVERLOAD  = 'overload'  ;
  T_OR    = 'or'    ;
  T_OUTPUT  = 'output'  ;
  PACKAGE  = 'package'  ;
  PARAMETER  = 'parameter'  ;
  PARTIAL  = 'partial'  ;
  PROTECTED  = 'protected'  ;
  PUBLIC  = 'public'  ;
  RECORD  = 'record'  ;
  REDECLARE  = 'redeclare'  ;
  REPLACEABLE  = 'replaceable'  ;
  RESULTS  = 'results'  ;
  THEN    = 'then'  ;
  T_TRUE  = 'true'  ;
  TYPE    = 'type'  ;
  UNSIGNED_REAL  = 'unsigned_real';
  WHEN    = 'when'  ;
  WHILE    = 'while'  ;
  WITHIN  = 'within'   ;
  RETURN  = 'return'  ;
  BREAK    = 'break'  ;
  STREAM  = 'stream'  ; /* for Modelica 3.1 stream connectors */  
  /* MetaModelica keywords. I guess not all are needed here. */
  AS    = 'as'            ;
  CASE    = 'case'    ;
  EQUALITY  = 'equality'      ;
  FAILURE  = 'failure'       ;
  LOCAL    = 'local'    ;
  MATCH    = 'match'    ;
  MATCHCONTINUE  = 'matchcontinue' ;
  UNIONTYPE  = 'uniontype'    ;
  WILD    = '_'      ;
  SUBTYPEOF     = 'subtypeof'     ;
  COLONCOLON ;
  
  // ---------
  // Operators
  // ---------
  
  DOT    = '.'           ;  
  LPAR    = '('    ;
  RPAR    = ')'    ;
  LBRACK  = '['    ;
  RBRACK  = ']'    ;
  LBRACE  = '{'    ;
  RBRACE  = '}'    ;
  EQUALS  = '='    ;
  ASSIGN  = ':='    ;
  COMMA    = ','    ;
  COLON    = ':'    ;
  SEMICOLON  = ';'    ;
  /* elementwise operators */  
  PLUS_EW       = '.+'    ; /* Modelica 3.0 */
  MINUS_EW      = '.-'       ; /* Modelica 3.0 */    
  STAR_EW       = '.*'       ; /* Modelica 3.0 */
  SLASH_EW      = './'    ; /* Modelica 3.0 */  
  POWER_EW      = '.^'     ; /* Modelica 3.0 */
  
  /* MetaModelica operators */
  COLONCOLON    = '::'    ;
  MOD    = '%'   ;
  
  // parser tokens 
ALGORITHM_STATEMENT;
ARGUMENT_LIST;
CLASS_DEFINITION;
CLASS_EXTENDS ;
CLASS_MODIFICATION;
CODE_EXPRESSION;
CODE_MODIFICATION;
CODE_ELEMENT;
CODE_EQUATION;
CODE_INITIALEQUATION;
CODE_ALGORITHM;
CODE_INITIALALGORITHM;
COMMENT;
COMPONENT_DEFINITION;
DECLARATION  ;
DEFINITION ;
ENUMERATION_LITERAL;
ELEMENT    ;
ELEMENT_MODIFICATION    ;
ELEMENT_REDECLARATION  ;
EQUATION_STATEMENT;
EXTERNAL_ANNOTATION ;
INITIAL_EQUATION;
INITIAL_ALGORITHM;
IMPORT_DEFINITION;
IDENT_LIST;
EXPRESSION_LIST;
EXTERNAL_FUNCTION_CALL;
FOR_INDICES ;
FOR_ITERATOR ;
FUNCTION_CALL    ;
INITIAL_FUNCTION_CALL    ;
FUNCTION_ARGUMENTS;
NAMED_ARGUMENTS;
QUALIFIED;
RANGE2    ;
RANGE3    ;
STORED_DEFINITION ;
STRING_COMMENT;
UNARY_MINUS  ;
UNARY_PLUS  ;
UNARY_MINUS_EW ;
UNARY_PLUS_EW ;
UNQUALIFIED;
FLAT_IDENT;
TYPE_LIST;
EMPTY;
OPERATOR;
}


@includes {
  #include <stdio.h>
  #include "rml.h"
  #include "Absyn.h"
  /* Eat anything so we can test code gen */
  void* mk_box_eat_all(int ix, ...);
  #define or_nil(x) (x != 0 ? x : mk_nil())
  #define mk_some_or_none(x) (x ? mk_some(x) : mk_none())
  #define mk_scon(x) x
  #define mk_rcon(x) mk_box_eat_all(0,x)
  #define mk_tuple2(x1,x2) mk_box_eat_all(0,x1,x2)
  #define mk_box0(x1) mk_box_eat_all(x1)
  #define mk_box1(x1,x2) mk_box_eat_all(x1,x2)
  #define mk_box2(x1,x2,x3) mk_box_eat_all(x1,x2,x3)
  #define mk_box3(x1,x2,x3,x4) mk_box_eat_all(x1,x2,x3,x4)
  #define mk_box4(x1,x2,x3,x4,x5) mk_box_eat_all(x1,x2,x3,x4,x5)
  #define mk_box5(x1,x2,x3,x4,x5,x6) mk_box_eat_all(x1,x2,x3,x4,x5,x6)
  #define mk_box6(x1,x2,x3,x4,x5,x6,x7) mk_box_eat_all(x1,x2,x3,x4,x5,x6,x7)
  #define mk_box7(x1,x2,x3,x4,x5,x6,x7,x8) mk_box_eat_all(x1,x2,x3,x4,x5,x6,x7,x8)
  #define mk_box8(x1,x2,x3,x4,x5,x6,x7,x8,x9) mk_box_eat_all(x1,x2,x3,x4,x5,x6,x7,x8,x9)
  #define mk_box9(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10) mk_box_eat_all(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10)
  #define mk_cons(x1,x2) mk_box_eat_all(0,x1,x2)
  #define mk_some(x1) mk_box_eat_all(0,x1)
  #define mk_none(void) NULL
  #define mk_nil() NULL
  #define getCurrentTime(void) 0
  #define token_to_scon(tok) mk_scon(tok->getText(tok)->chars)
  #define INFO(start,stop) Absyn__INFO(file, isReadOnly, start->line, start->charPosition, stop->line, stop->charPosition, getCurrentTime())
  typedef unsigned char bool;
}

@members
{
  const char* file = "ENTER FILENAME HERE";
  const int isReadOnly = RML_FALSE;
  void* mk_box_eat_all(int ix, ...) {return NULL;}
}




/*------------------------------------------------------------------
 * LEXER RULES
 *------------------------------------------------------------------*/

STAR    : '*'('.')?         ;
MINUS    : '-'('.')?          ;
PLUS    : '+'('.'|'&')?        ; 
LESS    : '<'('.')?          ;
LESSEQ    : '<='('.')?        ;
LESSGT    : '!='('.')?|'<>'('.')?    ;
GREATER    : '>'('.')?          ;
GREATEREQ  : '>='('.')?        ;
EQEQ    : '=='('.'|'&')?      ;
POWER    : '^'('.')?          ;
SLASH    : '/'('.')?          ;

WS : ( ' ' | '\t' | NL )+ { $channel=HIDDEN; }
  ;
  
LINE_COMMENT
    : '//' ( ~('\r'|'\n')* ) (NL|EOF) { $channel=HIDDEN; }
    ;  

ML_COMMENT
    :   '/*' (options {greedy=false;} : .)* '*/' { $channel=HIDDEN;  }
    ;

fragment 
NL: (('\r')? '\n');

IDENT :
       ('_' {  $type = WILD; } | NONDIGIT { $type = IDENT; })
       (('_' | NONDIGIT | DIGIT) { $type = IDENT; })*
    | (QIDENT { $type = IDENT; })
    ;

fragment
QIDENT :
         '\'' (QCHAR | SESCAPE) (QCHAR | SESCAPE)* '\'' ;

fragment
QCHAR :  NL  | '\t' | ~('\n' | '\t' | '\r' | '\\' | '\'');

fragment
NONDIGIT :   ('a'..'z' | 'A'..'Z');

fragment
DIGIT :
  '0'..'9'
  ;

fragment
EXPONENT :
  ('e'|'E') ('+' | '-')? (DIGIT)+
  ;


UNSIGNED_INTEGER :
    (DIGIT)+ ('.' (DIGIT)* { $type = UNSIGNED_REAL; } )? (EXPONENT { $type = UNSIGNED_REAL; } )?
  | ('.' { $type = DOT; } )
      ( (DIGIT)+ { $type = UNSIGNED_REAL; } (EXPONENT { $type = UNSIGNED_REAL; } )?
         | /* Modelica 3.0 element-wise operators! */
         (('+' { $type = PLUS_EW; }) 
          |('-' { $type = MINUS_EW; }) 
          |('*' { $type = STAR_EW; }) 
          |('/' { $type = SLASH_EW; }) 
          |('^' { $type = POWER_EW; })
          )?
      )
  ;

STRING : '"' STRING_GUTS '"'
       {SETTEXT($STRING_GUTS.text);};

fragment
STRING_GUTS: (SCHAR | SESCAPE)*
       ;

fragment
SCHAR :  NL | '\t' | ~('\n' | '\t' | '\r' | '\\' | '"');

fragment
SESCAPE : '\\' ('\\' | '"' | '\'' | '?' | 'a' | 'b' | 'f' | 'n' | 'r' | 't' | 'v');


/*------------------------------------------------------------------
 * PARSER RULES
 *------------------------------------------------------------------*/

stored_definition returns [void* ast] :
  (within=within_clause SEMICOLON)?
  cl=class_definition_list?
    {
      ast = Absyn__PROGRAM(or_nil(cl), within || Absyn__TOP, Absyn__TIMESTAMP(mk_rcon(0.0), mk_rcon(getCurrentTime())));
    }
  ;

within_clause returns [void* ast] :
    WITHIN (name=name_path)? {ast = Absyn__WITHIN(name);}
  ;

class_definition_list returns [void* ast] :
  ((f=FINAL)? cd=class_definition[f != NULL] SEMICOLON) cl=class_definition_list?
    {
      ast = mk_cons(cd, or_nil(cl));
    }
  ;

class_definition [bool final] returns [void* ast]
@declarations {
  void* ast = 0;
  void* name = 0;
}
  :
  ((e=ENCAPSULATED)? (p=PARTIAL)? class_type class_specifier[&name])
    {
      ast = Absyn__CLASS(
                name,
                RML_PRIM_MKBOOL(p != 0),
                RML_PRIM_MKBOOL(final),
                RML_PRIM_MKBOOL(e != 0),
                class_type,
                class_specifier,
                INFO($start,$stop)
            );
    }
  ;

class_type returns [void* ast] :
  ( CLASS { ast = Absyn__R_5fCLASS; }
  | MODEL { ast = Absyn__R_5fMODEL; }
  | RECORD { ast = Absyn__R_5fRECORD; }
  | BLOCK { ast = Absyn__R_5fBLOCK; }
  | ( e=EXPANDABLE )? CONNECTOR { ast = e ? Absyn__R_5fEXP_5fCONNECTOR : Absyn__R_5fCONNECTOR; }
  | TYPE { ast = Absyn__R_5fTYPE; }
  | PACKAGE { ast = Absyn__R_5fPACKAGE; }
  | FUNCTION { ast = Absyn__R_5fFUNCTION; } 
  | UNIONTYPE { ast = Absyn__R_5fUNIONTYPE; }
  | OPERATOR (f=FUNCTION | r=RECORD)? 
          { 
            ast = f ? Absyn__R_5fOPERATOR_5fFUNCTION : 
                  r ? Absyn__R_5fOPERATOR_5fRECORD : 
                  Absyn__R_5fOPERATOR;
          }
  )
  ;

class_specifier [void** name] returns [void* ast] :
        i1=IDENT {*name = token_to_scon(i1);} spec=class_specifier2 {ast = spec;}
    |   EXTENDS i1=IDENT {*name = token_to_scon(i1);} (class_modification)? string_comment composition T_END i2=IDENT
        ;

class_specifier2 returns [void* ast] :
( 
  string_comment c=composition T_END i2=IDENT 
  /* { fprintf(stderr,"position composition for \%s -> \%d\n", $i2.text->chars, $c->getLine()); } */
| EQUALS base_prefix type_specifier ( cm=class_modification )? cmt=comment
  {
  }
| EQUALS cs=enumeration {ast=cs;}
| EQUALS cs=pder {ast=cs;}
| EQUALS cs=overloading {ast=cs;}
| SUBTYPEOF type_specifier
)
;

pder returns [void* ast] :
  DER LPAR func=name_path COMMA var_lst=ident_list RPAR cmt=comment
  {
    ast = Absyn__PDER(func, var_lst, mk_some_or_none(cmt));
  }
  ;

ident_list returns [void* ast]:
  i=IDENT (COMMA il=ident_list)?
    {
      ast = mk_cons(i, or_nil(il));
    }
  ;


overloading returns [void* ast] :
  OVERLOAD LPAR name_list RPAR cmt=comment
    {
      ast = Absyn__OVERLOAD(name_list, mk_some_or_none(cmt));
    }
  ;

base_prefix :
  type_prefix
  ;

name_list returns [void* ast] :
  n=name_path (COMMA nl=name_list)?
    {
      ast = mk_cons(n, or_nil(nl));
    }
  ;

enumeration returns [void* ast] :
  ENUMERATION LPAR (el=enum_list | c=COLON ) RPAR cmt=comment
    {
      if (c) {
        ast = Absyn__ENUMERATION(Absyn__ENUM_5fCOLON, mk_some_or_none(cmt));
      } else {
        ast = Absyn__ENUMERATION(Absyn__ENUMLITERALS(el), mk_some_or_none(cmt));
      }
    }
  ;

enum_list returns [void* ast] :
  e=enumeration_literal ( COMMA el=enum_list )?
    {
      ast = mk_cons(e, or_nil(el));
    }
  ;

enumeration_literal returns [void* ast] :
  i1=IDENT c1=comment
    {
      ast = Absyn__ENUMLITERAL(token_to_scon(i1),mk_some_or_none(c1));
    }
  ;

composition :
  element_list
  ( public_element_list
  | protected_element_list
  | initial_equation_clause
  | initial_algorithm_clause
  | equation_clause
  | algorithm_clause
  )*
  ( external_clause )?
  ;

external_clause returns [void* ast] :
        EXTERNAL
        ( lang=language_specification )?
        ( ( retexp=component_reference EQUALS )?
          funcname=IDENT LPAR ( expl=expression_list )? RPAR )?
        ( ann1 = annotation )? SEMICOLON
        ( ann2 = external_annotation )?
          {
            ast = Absyn__EXTERNALDECL(mk_some_or_none(funcname), mk_some_or_none(lang), mk_some_or_none(retexp), or_nil(expl), mk_some_or_none(ann1));
            ast = Absyn__EXTERNAL(ast, mk_some_or_none(ann2));
          }
        ;

external_annotation returns [void* ast] :
  ann=annotation SEMICOLON {ast = ann;}
  ;

public_element_list :
  PUBLIC element_list
  ;

protected_element_list :
  PROTECTED element_list
  ;

language_specification returns [void* ast] :
  id=STRING {ast = token_to_scon(id);}
  ;

element_list :
  ((e=element | a=annotation ) s=SEMICOLON)*
  ;

element :
    ic=import_clause
  | ec=extends_clause
  | defineunit_clause
  | (REDECLARE)? (f=FINAL)? (INNER)? (T_OUTER)?
  ( (class_definition[f != NULL] | cc=component_clause) 
  | (REPLACEABLE ( class_definition[f != NULL] | cc2=component_clause ) (constraining_clause comment)? )
  )
  ;

import_clause returns [void* ast] :
  IMPORT (imp=explicit_import_name | imp=implicit_import_name) cmt=comment
    {
      ast = Absyn__IMPORT(imp, mk_some_or_none(cmt));
    }
  ;
defineunit_clause :
  DEFINEUNIT IDENT (LPAR named_arguments RPAR)?    
  ;

explicit_import_name returns [void* ast] :
  id=IDENT EQUALS p=name_path {ast = Absyn__NAMED_5fIMPORT(token_to_scon(id),p);}
  ;

implicit_import_name returns [void* ast]
@declarations {
  bool unqual = 0;
} :
  np=name_path_star[&unqual]
  {
    ast = unqual ? Absyn__UNQUAL_5fIMPORT(np) : Absyn__QUAL_5fIMPORT(np);
  }
;

/*
 * 2.2.3 Extends
 */

// Note that this is a minor modification of the standard by
// allowing the comment.
extends_clause :
  EXTENDS name_path (class_modification)? (annotation)?
    ;

constraining_clause :
    EXTENDS name_path  (class_modification)? 
  | CONSTRAINEDBY name_path ( class_modification )?
  ;

/*
 * 2.2.4 Component clause
 */

component_clause :
  tp = type_prefix np=type_specifier clst=component_list
  ;

type_prefix :
  (FLOW|STREAM)? (DISCRETE|PARAMETER|CONSTANT)? (T_INPUT|T_OUTPUT)?
  ;

type_specifier returns [void* ast] :
  np=name_path
  (LESS ts=type_specifier_list GREATER)?
  (as=array_subscripts)?
    {
      if (ts != NULL)
        ast = Absyn__TCOMPLEX(np,ts,mk_some_or_none(as));
      else
        ast = Absyn__TPATH(np,mk_some_or_none(as));
    }
  ;

type_specifier_list returns [void* ast] :
  np1=type_specifier (COMMA np2=type_specifier)? {ast = mk_cons(np1,or_nil(np2));}
  ;

component_list returns [void* ast] :
  c=component_declaration (COMMA cs=component_list)? {ast = mk_cons(c, or_nil(cs));}
  ;

component_declaration returns [void* ast] :
  decl=declaration (cond=conditional_attribute)? cmt=comment
    {
      ast = Absyn__COMPONENTITEM(decl, mk_some_or_none(cond), mk_some_or_none(cmt));
    }
  ;

conditional_attribute returns [void* ast] :
        IF e=expression {ast = e;}
        ;

declaration returns [void* ast] :
  ( id=IDENT | id=OPERATOR ) (as=array_subscripts)? (mod=modification)?
    {
      ast = Absyn__COMPONENT(token_to_scon(id), or_nil(as), mk_some_or_none(mod));
    }
  ;

/*
 * 2.2.5 Modification
 */

modification returns [void* ast] :
  ( cm=class_modification ( EQUALS e=expression )?
  | EQUALS e=expression
  | ASSIGN e=expression
  )
    {
      ast = Absyn__CLASSMOD(or_nil(cm), mk_some_or_none(e));
    }
  ;

class_modification returns [void* ast] :
  LPAR ( as=argument_list )? RPAR {ast = or_nil(as);}
  ;

argument_list returns [void* ast] :
  a=argument ( COMMA as=argument_list )? {ast = mk_cons(a, or_nil(as));}
  ;

argument returns [void* ast] :
  (
    em=element_modification_or_replaceable /* -> (ELEMENT_MODIFICATION em) */
  | er=element_redeclaration  /* -> (ELEMENT_REDECLARATION er) */
  )
  ;

element_modification_or_replaceable:
        (EACH)? (f=FINAL)? (element_modification | element_replaceable[f != NULL])
    ;

element_modification :
  component_reference ( modification )? string_comment
  ;

element_redeclaration :
  REDECLARE (EACH)? (f=FINAL)?
  ( (class_definition[f != NULL] | component_clause1) | element_replaceable[f != NULL] )
  ;

element_replaceable [bool final] :
        REPLACEABLE ( class_definition[final] | component_clause1 ) (constraining_clause comment)?
  ;
  
component_clause1 :
  type_prefix type_specifier component_declaration1
  ;

component_declaration1 :
        declaration comment
  ;


/*
 * 2.2.6 Equations
 */

initial_equation_clause :
  { LA(2)==EQUATION }?
  INITIAL ec=equation_clause /* -> (INITIAL_EQUATION ec) */
  ;

equation_clause :
  EQUATION equation_annotation_list
    ;

equation_annotation_list :
  { LA(1) == T_END || LA(1) == EQUATION || LA(1) == T_ALGORITHM || LA(1)==INITIAL || LA(1) == PROTECTED || LA(1) == PUBLIC }?
  |
  ( equation SEMICOLON | annotation SEMICOLON) equation_annotation_list
  ;

algorithm_clause :
  T_ALGORITHM algorithm_annotation_list
  ;

initial_algorithm_clause :
  { LA(2)==T_ALGORITHM }?
  INITIAL ac = algorithm_clause /* -> (INITIAL_ALGORITHM ac) */
  ;

algorithm_annotation_list :
  { LA(1) == T_END || LA(1) == EQUATION || LA(1) == T_ALGORITHM || LA(1)==INITIAL || LA(1) == PROTECTED || LA(1) == PUBLIC }?
  |
  ( algorithm SEMICOLON | annotation SEMICOLON) algorithm_annotation_list
  ;

equation :
  ( equality_equation   
  | conditional_equation_e
  | for_clause_e
  | connect_clause
  | when_clause_e   
  | FAILURE LPAR equation RPAR
  | EQUALITY LPAR equation RPAR
  )
  comment
        
        /* -> (EQUATION_STATEMENT equation); */

  ;

algorithm :
  ( assign_clause_a
  | conditional_equation_a
  | for_clause_a
  | while_clause
  | when_clause_a
  | BREAK
  | RETURN
  | FAILURE LPAR algorithm RPAR
  | EQUALITY LPAR algorithm RPAR
  )
  comment
  
  /* -> (ALGORITHM_STATEMENT algorithm) */
  ;

assign_clause_a :                
  simple_expression 
  ( ASSIGN expression  | i1 = EQUALS expression
  /* 
          {      
             throw ANTLR_USE_NAMESPACE(antlr)RecognitionException(
            "Algorithms can not contain equations ('='), use assignments (':=') instead", 
            modelicafilename, $i1->getLine(), $i1->getColumn());
          }
          */
        )?  
  ;

equality_equation :      
  simple_expression ( EQUALS expression )?     
  ;

conditional_equation_e :
  IF expression THEN equation_list ( equation_elseif )* ( ELSE equation_list )? T_END IF
  ;

conditional_equation_a :
  IF expression THEN algorithm_list ( algorithm_elseif )* ( ELSE algorithm_list )? T_END IF
  ;

for_clause_e :
  FOR for_indices LOOP equation_list T_END FOR
  ;

for_clause_a :
  FOR for_indices LOOP algorithm_list T_END FOR
  ;

while_clause :
  WHILE expression LOOP algorithm_list T_END WHILE
  ;

when_clause_e :
  WHEN expression THEN equation_list (else_when_e)* T_END WHEN
  ;

else_when_e :
  ELSEWHEN expression THEN equation_list
  ;

when_clause_a :
  WHEN expression THEN algorithm_list (else_when_a)* T_END WHEN
  ;

else_when_a :
  ELSEWHEN expression THEN algorithm_list
  ;

equation_elseif :
  ELSEIF expression THEN equation_list
  ;

algorithm_elseif :
  ELSEIF expression THEN algorithm_list
  ;

equation_list_then :
        { LA(1) == THEN }?
  | (equation SEMICOLON equation_list_then)
  ;


equation_list :
  {LA(1) != T_END || (LA(1) == T_END && LA(2) != IDENT)}?
  |
  ( equation SEMICOLON equation_list )
  ;

algorithm_list :
  {LA(1) != T_END || (LA(1) == T_END && LA(2) != IDENT)}?
  |
  ( algorithm SEMICOLON algorithm_list )
  ;

connect_clause returns [void* ast] :
  CONNECT LPAR cr1=connector_ref COMMA cr2=connector_ref RPAR {ast = Absyn__EQ_5fCONNECT(cr1,cr2);}
  ;

connector_ref returns [void* ast] :
  id=IDENT ( as=array_subscripts )? ( DOT cr2=connector_ref_2 )?
    {
      if (cr2)
        ast = Absyn__CREF_5fQUAL(token_to_scon(id),or_nil(as),cr2);
      else
        ast = Absyn__CREF_5fIDENT(token_to_scon(id),or_nil(as));
    }
  ;

connector_ref_2 returns [void* ast] :
  id=IDENT ( as=array_subscripts )? {ast = Absyn__CREF_5fIDENT(token_to_scon(id),or_nil(as));}
  ;

/*
 * 2.2.7 Expressions
 */
expression returns [void* ast] :
  ( e=if_expression {ast = e;}
  | e=simple_expression {ast = e;}
  | e=code_expression {ast = e;}
  | (MATCHCONTINUE expression_or_empty
     local_clause
     cases
     T_END MATCHCONTINUE)
  | (MATCH expression_or_empty
     local_clause
     cases
     T_END MATCH)
  )
  ;

expression_or_empty returns [void* ast] :
  e = expression {ast = e;}
  | LPAR RPAR {ast = Absyn__TUPLE(mk_nil());}
  ;

local_clause:
  (LOCAL element_list)?
  ;

cases:
  (onecase)+ (ELSE (string_comment local_clause (EQUATION equation_list_then)? THEN)? expression_or_empty SEMICOLON)?
  ;

onecase:
  (CASE pattern string_comment local_clause (EQUATION equation_list_then)?
  THEN expression_or_empty SEMICOLON)
  ;

pattern:
  expression_or_empty
  ;

if_expression returns [void* ast] :
  IF cond=expression THEN e1=expression es=elseif_expression_list ELSE e2=expression {Absyn__IFEXP(cond,e1,e2,es);}
  ;

elseif_expression_list returns [void* ast] :
  e=elseif_expression es=elseif_expression_list { ast = mk_cons(e,es); }
  | { ast = mk_nil(); }
  ;

elseif_expression returns [void* ast] :
  ELSEIF e1=expression THEN e2=expression { ast = mk_tuple2(e1,e2); }
  ;

for_indices returns [void* ast] :
     i=for_index (COMMA is=for_indices)? {ast = mk_cons(i, or_nil(is));}
  ;

for_index returns [void* ast] :
     (i=IDENT (T_IN e=expression)? {ast = mk_tuple2(token_to_scon(i),mk_some_or_none(e));})
  ;

simple_expression returns [void* ast] :
    e=simple_expr {ast = e;} (COLONCOLON e=simple_expr {ast = Absyn__CONS(ast,e);})*
  | i=IDENT AS e=simple_expression {ast = Absyn__AS(token_to_scon(i),e);}
  ;

simple_expr returns [void* ast] :
  e1=logical_expression ( COLON e2=logical_expression ( COLON e3=logical_expression )? )?
    {
      if (e3)
        ast = Absyn__RANGE(e1,mk_some(e2),e3);
      else if (e2)
        ast = Absyn__RANGE(e1,mk_none(),e2);
      else
        ast = e1;
    }
  ;

logical_expression returns [void* ast] :
  e1=logical_term {ast = e1;} ( T_OR e2=logical_term {ast = Absyn__BINARY(ast,Absyn__OR,e2);})*
  ;

logical_term returns [void* ast] :
  e1=logical_factor {ast = e1;} ( T_AND e2=logical_factor {ast = Absyn__BINARY(ast,Absyn__AND,e2);} )*
  ;

logical_factor returns [void* ast] :
  ( n=T_NOT )? e=relation {ast = n ? Absyn__LUNARY(Absyn__NOT, e) : e;}
  ;

relation returns [void* ast] @declarations {
  void* op;
} :
  e1=arithmetic_expression 
  ( ( LESS {op = Absyn__LESS;} | LESSEQ {op = Absyn__LESSEQ;}
    | GREATER {op = Absyn__GREATER;} | GREATEREQ {op = Absyn__GREATEREQ;}
    | EQEQ {op = Absyn__EQUAL;} | LESSGT {op = Absyn__NEQUAL;}
    ) e2=arithmetic_expression )?
    {
      ast = e2 ? Absyn__BINARY(e1,op,e2) : e1;
    }
  ;

arithmetic_expression returns [void* ast] @declarations {
  void* op;
} :
  e1=unary_arithmetic_expression {ast = e1;}
    ( ( PLUS {op=Absyn__ADD;} | MINUS {op=Absyn__SUB;} | PLUS_EW {op=Absyn__ADD_5fEW;} | MINUS_EW {op=Absyn__SUB_5fEW;}
      ) e2=term { ast = Absyn__BINARY(ast,op,e2); }
    )*
  ;

unary_arithmetic_expression returns [void* ast] :
  ( PLUS t=term     { ast = Absyn__UNARY(Absyn__UPLUS,t); }
  | MINUS t=term    { ast = Absyn__UNARY(Absyn__SUB,t); }
  | PLUS_EW t=term  { ast = Absyn__UNARY(Absyn__UPLUS_5fEW,t); }
  | MINUS_EW t=term { ast = Absyn__UNARY(Absyn__SUB_5fEW,t); }
  | t=term          { ast = t; }
  )
  ;

term returns [void* ast] @declarations {
  void* op;
} :
  e1=factor {ast = e1;}
    (
      ( STAR {op=Absyn__MUL;} | SLASH {op=Absyn__DIV;} | STAR_EW {op=Absyn__MUL_5fEW;} | SLASH_EW {op=Absyn__DIV_5fEW;} )
      e2=factor {ast = Absyn__BINARY(e1,op,e2);}
    )*
  ;

factor returns [void* ast] :
  e1=primary ( ( pw=POWER | pw_ew=POWER_EW ) e2=primary )?
    {
      ast = e2 ? Absyn__BINARY(e1, pw ? Absyn__POW : Absyn__POW_5fEW, e2) : e1;
    }
  ;

primary returns [void* ast] @declarations {
  bool isFor = 0;
} :
  ( v=UNSIGNED_INTEGER {ast = Absyn__INTEGER(mk_icon($v.int));}
  | v=UNSIGNED_REAL    {ast = Absyn__REAL(mk_rcon(atof($v.text->chars)));}
  | v=STRING           {ast = Absyn__STRING(mk_scon($v.text->chars));}
  | T_FALSE            {ast = Absyn__BOOL(RML_FALSE);}
  | T_TRUE             {ast = Absyn__BOOL(RML_TRUE);}
  | ptr=component_reference__function_call {ast = ptr;}
  | DER el=function_call {ast = Absyn__CALL(Absyn__CREF_5fIDENT(mk_scon("der"), mk_nil()),el);}
  | LPAR expression_list RPAR {ast = Absyn__TUPLE(el);}
  | LBRACK el=matrix_expression_list RBRACK {ast = Absyn__MATRIX(el);}
  | LBRACE for_or_el=for_or_expression_list[&isFor] RBRACE
    {
      if (isFor)
        ast = Absyn__ARRAY(for_or_el);
      else
        ast = Absyn__CALL(Absyn__CREF_5fIDENT(mk_scon("array"), mk_nil()),for_or_el);
    }
  | T_END { ast = Absyn__END; }
  )
  ;

matrix_expression_list returns [void* ast] :
  e1=expression_list (SEMICOLON e2=matrix_expression_list)? {ast = mk_cons(e1, or_nil(e2));}
  ;

component_reference__function_call returns [void* ast] :
  cr=component_reference ( fc=function_call )? {
      if (fc != NULL) {
        ast = Absyn__CALL(cr,fc);
      }
    }
  | i=INITIAL LPAR RPAR {
      ast = Absyn__CALL(Absyn__CREF_5fIDENT(mk_scon("initial"), mk_nil()),Absyn__FUNCTIONARGS(mk_nil(),mk_nil()));
    }
  ;

name_path returns [void* ast] :
  { LA(2)!=DOT }? id=IDENT {ast = Absyn__IDENT(token_to_scon(id));}
  | id=IDENT DOT p=name_path {ast = Absyn__QUALIFIED(token_to_scon(id),p);}
  ;

name_path_star [bool* unqual] returns [void* ast] :
    { LA(2) != DOT }? id=IDENT ( uq=STAR_EW )?
    {
      ast = Absyn__IDENT(token_to_scon(id));
      *unqual = uq != 0;
    }
  | id=IDENT DOT p=name_path_star[unqual] {ast = Absyn__QUALIFIED(token_to_scon(id),p);}
  ;

component_reference returns [void* ast] :
    ( id=IDENT | id=OPERATOR) ( arr=array_subscripts )? ( DOT cr=component_reference )?
    {
      if (cr)
        ast = Absyn__CREF_5fQUAL(token_to_scon(id), or_nil(arr), cr);
      else
        ast = Absyn__CREF_5fIDENT(token_to_scon(id), or_nil(arr));
    }
  | WILD {ast = Absyn__WILD;}
  ;

function_call returns [void* ast] :
  LPAR (function_arguments) RPAR {ast = function_arguments;}
  ;

function_arguments returns [void* ast] @declarations {
  bool isFor = 0;
} :
  (for_or_el=for_or_expression_list[&isFor]) (namel=named_arguments) ?
    {
      ast = isFor ? for_or_el : Absyn__FUNCTIONARGS(for_or_el,namel);
    }
  ;

for_or_expression_list [bool* isFor] returns [void* ast]:
  ({LA(1)==IDENT || LA(1)==OPERATOR && LA(2) == EQUALS || LA(1) == RPAR || LA(1) == RBRACE}?
   {ast = mk_nil();} /* empty */
  |(e=expression {ast = e;} ( COMMA el=for_or_expression_list2 {ast = mk_cons(e,el);} | FOR forind=for_indices {ast = Absyn__FOR_5fITER_5fFARG(e, forind); *isFor = 1;})? )
  )
    ;

for_or_expression_list2 returns [void* ast] :
    {LA(2) == EQUALS}? {ast = mk_nil();}
  | e=expression (COMMA el=for_or_expression_list2)? {ast = mk_cons(e, or_nil(el));}
  ;

named_arguments returns [void* ast] :
  a=named_argument (COMMA as=named_arguments)? {ast = mk_cons(a, or_nil(as));}
  ;

named_argument returns [void* ast] :
  ( id=IDENT | id=OPERATOR) EQUALS e=expression {ast = Absyn__NAMEDARG(token_to_scon(id),e);}
  ;

expression_list returns [void* ast] :
  e1=expression (COMMA el=expression_list)? { ast = (el==NULL ? mk_cons(e1,mk_nil()) : mk_cons(e1,el)); }
  ;

array_subscripts returns [void* ast] :
  LBRACK sl=subscript_list RBRACK {ast = sl;}
  ;

subscript_list returns [void* ast] :
  s1=subscript ( COMMA s2=subscript_list )? {ast = mk_cons(s1, or_nil(s2));}
  ;

subscript returns [void* ast] :
    e=expression {ast = Absyn__SUBSCRIPT(e);}
  | COLON {ast = Absyn__NOSUB;}
  ;

comment returns [void* ast] :
  (cmt=string_comment (ann=annotation)?)
    {
       if (cmt || ann) {
         ast = Absyn__COMMENT(mk_some_or_none(ann), mk_some_or_none(cmt));
       }
    }
  ;

string_comment returns [void* ast]
@declarations {
  pANTLR3_STRING t1;
} :
  ( s1=STRING {t1 = s1->getText(s1);} (PLUS s2=STRING {t1->appendS(t1,s2->getText(s2));})* {ast = mk_scon(t1->chars);})?
  ;

annotation returns [void* ast] :
  T_ANNOTATION cmod=class_modification {ast = Absyn__ANNOTATION(cmod);}
  ;


/* Code quotation mechanism */
code_expression returns [void* ast] :
  CODE LPAR ((expression RPAR)=> e=expression | m=modification | el=element (SEMICOLON)?
  | eq=code_equation_clause | ieq=code_initial_equation_clause
  | alg=code_algorithm_clause | ialg=code_initial_algorithm_clause
  )  RPAR
  ;

code_equation_clause :
  ( EQUATION ( equation SEMICOLON | annotation SEMICOLON )*  )
  ;

code_initial_equation_clause :
  { LA(2)==EQUATION }?
  INITIAL ec=code_equation_clause 
  ;

code_algorithm_clause :
  T_ALGORITHM (algorithm SEMICOLON | annotation SEMICOLON)*
  ;

code_initial_algorithm_clause :
  { LA(2) == T_ALGORITHM }?
  INITIAL T_ALGORITHM
  ( algorithm SEMICOLON | annotation SEMICOLON )* 
  ;
/* End Code quotation mechanism */
