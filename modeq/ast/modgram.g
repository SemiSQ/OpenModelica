/* -*- C -*- */

#header <<

/* #include "bool.h" */
typedef int bool;
#define false 0
#define true  1

#include "attrib.h"
#include "parser.h"
/* #include "modAST.h" */

#define AST_FIELDS Attrib *attr; void *rml; void *aux[5];
#define zzcr_ast(ast,atr,ttype,text) \
	ast->attr=copy_attr(atr); \
	ast->rml=NULL; \
	ast->aux[0]=NULL; \
	ast->aux[1]=NULL; \
	ast->aux[2]=NULL; \
	ast->aux[3]=NULL; \
	ast->aux[4]=NULL;

/* #define MATCH */

extern int parse_failed;
>>

<<

#include <stdlib.h>

#include "rml.h"
#include "yacclib.h"
#include "absyn.h"
#include "errno.h"

static int errors=0;

static char *filename=NULL;
static char *outputfilename=NULL;

void newline()
{
  zzline++;
}

AST *zzmk_ast(AST *ast, Attrib *at)
{
  ast->attr = copy_attr(at);
  return ast;
}

extern void *sibling_list(AST *ast);

>>

/**************************************************************/
/* Token definitions for the the lexical analyzer. */

#lexclass START
#token "/\*"		<< zzskip(); zzmode(C_STYLE_COMMENT); >>
#token IMPORT		"import"
#token CLASS_		"class"
#token BOUNDARY		"boundary"
#token MODEL		"model"
#token FUNCTION		"function"
#token PACKAGE		"package"
#token RECORD		"record"
#token BLOCK		"block"
#token CONNECTOR	"connector"
#token TYPE		"type"
#token END		"end"

#token ANNOTATION	"annotation"

#token EXTERNAL		"external"
#token EXTENDS		"extends"
#token PARAMETER	"parameter"
#token CONSTANT		"constant"
#token REPLACEABLE	"replaceable"
#token PARTIAL		"partial"
#token REDECLARE	"redeclare"
#token INPUT		"input"
#token OUTPUT		"output"
#token FLOW		"flow"

#token EQUATION		"equation"
#token ALGORITHM	"algorithm"
#token RESULTS		"results"

#token FINAL		"final"
#token PUBLIC		"public"
/* #token PRIVATE		"private" */
#token PROTECTED	"protected"
#token LPAR		"\("
#token RPAR		"\)"
#token LBRACK		"\["
#token RBRACK		"\]"
/* #token RECORD_BEGIN	"\{" */
/* #token RECORD_END	"\}" */
#token IF		"if"
#token THEN		"then"
#token ELSE		"else"
#token ELSEIF		"elseif"
/* #token ENDIF		"endif" */
/* #token WHEN		"when" */
/* #token ENDWHEN		"endwhen" */
#token OR		"or"
#token AND		"and"
#token NOT		"not"
#token FALS		"false"
#token TRU		"true"
#token CONNECT		"connect"

#token IN		"in"
#token FOR		"for"
#token WHILE		"while"
#token LOOP		"loop"

/* #token DER		"der" */

/*
#token NEW		"new"
#token INIT		"init"
#token DER		"der"
#token RESIDUE		"residue"
*/

#token EQUALS           "="
#token ASSIGN           ":="
#token PLUS             "\+"
#token MINUS            "\-"
#token MULT             "\*"
#token DIV              "/"
#token DOT		"."
#token LESS		"<"
#token LESSEQ		"<="
#token GREATER		">"
#token GREATEREQ	">="
#token EQEQ		"=="
#token LESSGT		"<>"

/* #tokclass COMP_BEGIN	{ LPAR RECORD_BEGIN } */
/* #tokclass COMP_END	{ RPAR RECORD_END } */

/* #tokclass ARR_ARG_BEG	{ LPAR LBRACK } */
/* #tokclass ARR_ARG_END   { RPAR RBRACK } */

#tokclass REL_OP 	{ LESS LESSEQ GREATER GREATEREQ EQEQ LESSGT }
#tokclass ADD_OP	{ PLUS MINUS }
#tokclass MUL_OP	{ MULT DIV }

/* synthetic nodes */
#token EXTRA_TOKEN	/* used for synthetic nodes */
#token COMPONENTS
#token TYPE_PREFIX
#token FUNCALL
#token ELEMENT
#token MODIFICATION
#token SUBSCRIPT

#token "//(~[\n])*"  << zzskip(); >> /* skip C++-style comments */

#token IDENT 		"([a-z]|[A-Z])([a-z]|[A-Z]|[0-9]|_)*"

#token STRING		"\"(~[\"])*\""

#token UNSIGNED_INTEGER	"[0-9]+"
#token UNSIGNED_REAL	"[0-9]+{\.[0-9]*}{[eE]{[\+\-]}[0-9]+}"

#token "[\ \t]+"    << zzskip(); >>
#token "\n"         << zzskip(); newline(); >>

#lexclass C_STYLE_COMMENT

#token	"[\n\r]"	<< zzskip(); newline(); >>
#token	"\*/"		<< zzskip(); zzmode(START); >>
#token	"\*"		<< zzskip(); >>
#token	"~[\*\n\r]+"	<< zzskip(); >>


#lexclass START

/**************************************************************/
/* The main part of the Modelica parser. */

/* exception */
/*   default : */
/*     << parse_failed = 1; >> */

model_specification :
	(
	  cl:class_definition[false,false] ";"! 
	| import_statement
	)+
	"@"!
	;

import_statement :
	im:IMPORT^ STRING ";"! << /* #im->ni.type=IMPORT_STATEMENT; */ >>
	;

class_definition[bool is_replaceable,bool is_final] :
        << void *restr;
	   bool partial=false, has_array_dim=false, has_class_spec=false; >>
	{ PARTIAL << partial = true; >> }
        ( CLASS_                  << restr = Absyn__R_5fCLASS; >>
	| MODEL			  << restr = Absyn__R_5fMODEL; >>
	| RECORD		  << restr = Absyn__R_5fRECORD; >>
	| BLOCK			  << restr = Absyn__R_5fBLOCK; >>
	| CONNECTOR		  << restr = Absyn__R_5fCONNECTOR; >>
	| TYPE			  << restr = Absyn__R_5fTYPE; >>
	| PACKAGE		  << restr = Absyn__R_5fPACKAGE; >>
	| { EXTERNAL } FUNCTION   << restr = Absyn__R_5fFUNCTION; >>
	)
        i:IDENT
	comment
	( c:composition END! { IDENT! }
	  << 
	     Attrib a = $[CLASS_,"---"];
	     #0 = #(#[&a], #0);
	     #0->rml = Absyn__CLASS(mk_scon($i.u.stringval),
				    RML_PRIM_MKBOOL(partial),
				    restr, Absyn__PARTS(sibling_list(#c)));
	  >>
	| EQUALS dp:name_path
	  { da:array_dimensions << has_array_dim=true; >> }
	  { ds:class_modification << has_class_spec=true; >> } 
	  << 
	     Attrib a = $[CLASS_,"---"];
	     #0 = #(#[&a], #0);
	     #0->rml = Absyn__CLASS(mk_scon($i.u.stringval),
				    RML_PRIM_MKBOOL(partial),
				    restr,
				    Absyn__DERIVED(#dp->rml,
						   (has_array_dim
						    ? #da->rml
						    : Absyn__NODIM),
						   (has_class_spec
						    ? #ds->rml
						    : mk_nil())));
	  >>
	)
	;

composition :
	default_public
	( public_elements    |
	  protected_elements |
	  equation_clause    |
	  algorithm_clause
	)*
	;

default_public:
	element_list[false]
	<< 
	   Attrib a = $[PUBLIC,"---"];
	   void *els = sibling_list(#0);
	   #0 = #(#[&a],#0);
	   #0->rml = Absyn__PUBLIC(els);
	>>
        ;

public_elements:
	PUBLIC^ el:element_list[false]
	<< #0->rml = Absyn__PUBLIC(sibling_list(#el)); >>
	;
protected_elements:
	PROTECTED^ el:element_list[true]
	<< #0->rml = Absyn__PROTECTED(sibling_list(#el)); >>
	;

element_list[bool is_protected] :
	( el:element ";"!
	| annotation! ";"! )*
	;

element :
	<< bool is_replaceable=false; bool is_final=false; void *spec; >>
	{ FINAL << is_final = true; >> }
	( { REPLACEABLE << is_replaceable=true; >> }
	  c:class_definition[is_replaceable,is_final]
	  << spec=Absyn__CLASSDEF(RML_PRIM_MKBOOL(is_replaceable), #c->rml); >>
	| ec:extends_clause << spec = #ec->rml; >>
	| cc:component_clause << spec = #cc->rml; >>  )
	<< Attrib a = $[ELEMENT,"---"];
	   #0 = #(#[&a],#0);
	   #0->rml = Absyn__ELEMENT(RML_PRIM_MKBOOL(is_final),
				    mk_scon(""), spec); >>
	;

/*
 * Extends
 */

extends_clause:
	EXTENDS^ i:name_path
	{ m:class_modification }
	<< #0->rml = Absyn__EXTENDS(#i->rml, #m ? #m->rml : mk_nil() ); >>
	;

/*
 * Component clause
 */

component_clause!:
	<< bool fl=false, pa=false, co=false, in=false, ou=false;
	   Attrib a = $[COMPONENTS,"---"]; >>
        /* inline type_prefix for easy access to the flags */
	{ f:FLOW      << fl = true; >> } 
	{ p:PARAMETER << pa = true; >>
	| c:CONSTANT  << co = true; >> }
	{ i:INPUT     << in = true; >>
	| o:OUTPUT    << ou = true; >> }
	s:type_specifier
	l:component_list
        << #0 = #(#[&a], #p, #s, #l);
	   #0->rml = Absyn__COMPONENTS(Absyn__ATTR(mk_none(),
						   RML_PRIM_MKBOOL(fl),
						   pa ? Absyn__PARAM :
						   co ? Absyn__CONST :
						   Absyn__VAR,
						   in ? Absyn__INPUT :
						   ou ? Absyn__OUTPUT:
						   Absyn__BIDIR),
				       #s->rml,
				       sibling_list(#l));
				       
	>> 
	;

type_prefix : << Attrib a = $[TYPE_PREFIX,"---"]; >>
	{ f:FLOW      } 
	{ p:PARAMETER
	| c:CONSTANT  }
	{ i:INPUT     
	| o:OUTPUT    }
        << #0 = #(#[&a],#0); >>
	;

type_specifier :
	name_path
	;

component_list :
        component_declaration ( ","! component_declaration )*
	;

component_declaration :
        declaration comment!
	;

declaration :
	i:IDENT^
	{ a:array_dimensions }
	{ s:modification }
	<< #i->rml = Absyn__COMPONENT(mk_scon($i.u.stringval),
				      #a ? #a->rml : Absyn__NODIM,
				      #s ? mk_some(#s->rml) : mk_none()); >>
        ;

array_dimensions :
	brak:LBRACK^
	s1:subscript { ","! s2:subscript }
	RBRACK!
	<< if(#s2) #0->rml = Absyn__TWODIM(#s1->rml,#s2->rml);
	   else #0->rml = Absyn__ONEDIM(#s1->rml); >>
	;

subscripts :
	brak:LBRACK^
	s:subscript_list
	RBRACK!
	<< #0->rml = sibling_list(#s); >>
	;

subscript_list :
	subscript { ","! subscript { ","! subscript }}
	;

subscript :
	<< Attrib a = $[SUBSCRIPT,"---"]; >>
	ex1:expression { ":"! ex2:expression { ":"! ex3:expression } }
	<<
	   #0 = #(#[&a],#0);
	   if(#ex3)
	     #0->rml = Absyn__SUB3(#ex1->rml, #ex2->rml, #ex3->rml);
	   else if(#ex2)
	     #0->rml = Absyn__SUB2(#ex1->rml, #ex2->rml);
	   else
	     #0->rml = Absyn__SUB1(#ex1->rml);
	>>

        | ":"!
	<<
	   #0 = #(#[&a],#0);
	   #0->rml = Absyn__NOSUB;
	>>
  ;

/*
 * Modification (here: modification)
 */

modification :
	  c:class_modification { EQUALS! e1:expression } /* FIXME */
	  << #0->rml = Absyn__CLASSMOD(#0->rml,
				       #e1 ? mk_some(#e1->rml) : mk_none()); >>
	| EQUALS^ e2:expression
	  << #0->rml = Absyn__CLASSMOD(mk_nil(), mk_some(#e2->rml)); >>
	;

class_modification :
	  LPAR^ al:argument_list RPAR! 
	  << #0->rml = sibling_list(#al); >>
	;

argument_list :
	  argument ( ","! argument )*
	;

argument :
	  element_modification
	| element_redeclaration
	;
 
element_modification : << bool is_final=false; >>
	{ FINAL << is_final=true; >> } 
	np:name_path /* Not in spec */
	sp:modification
	<< 
	   Attrib a = $[MODIFICATION,"---"];
	   #0 = #(#[&a],#0);
	   #0->rml = Absyn__MODIFICATION(RML_PRIM_MKBOOL(is_final),
					 #np->rml,
					 #sp->rml);
	>>
	;

element_redeclaration :
	  << bool is_final=false; void *spec = NULL; >>
	  REDECLARE ^
	  { FINAL << is_final=true; >> }
	  ( ec:extends_clause                   << spec = #ec->rml; >>
	  | cd:class_definition[false,is_final]
	    << spec = Absyn__CLASSDEF(RML_PRIM_MKBOOL(false), #cd->rml); >>
	  | cc:component_clause1
	    << spec = #cc->rml; >> )
          << #0->rml = Absyn__REDECLARATION(RML_PRIM_MKBOOL(is_final), spec);
	  >>
	;

component_clause1!:
	<< bool fl=false, pa=false, co=false, in=false, ou=false;
	   Attrib a = $[COMPONENTS,"---"]; >>
        /* inline type_prefix for easy access to the flags */
	{ f:FLOW      << fl = true; >> } 
	{ p:PARAMETER << pa = true; >>
	| c:CONSTANT  << co = true; >> }
	{ i:INPUT     << in = true; >>
	| o:OUTPUT    << ou = true; >> }
	s:type_specifier
	d:component_declaration
        << #0 = #(#[&a], #p, #s, #d);
	   #0->rml = Absyn__COMPONENTS(Absyn__ATTR(mk_none(),
						   RML_PRIM_MKBOOL(fl),
						   pa ? Absyn__PARAM :
						   co ? Absyn__CONST :
						   Absyn__VAR,
						   in ? Absyn__INPUT :
						   ou ? Absyn__OUTPUT:
						   Absyn__BIDIR),
				       #s->rml,
				       mk_cons(#d->rml, mk_nil()));
				       
	>> 
	;

/* component_clause1 : */
/* 	type_prefix */
/* 	type_specifier */
/* 	component_declaration */
/* 	; */

/* component_clause1![NodeType nt] : */
/* 	  type_prefix  */
/* 	  t:type_specifier << #t->ni.type=nt; >> */
/* 	  c:component_declaration[ET_COMPONENT] */
/* 	  // manual tree construction: */
/* 	  // the type specifier is a new root with the component_declaration */
/* 	  // as a child. */
/* 	  << #0=#(#t,#c); >> */
/* 	  ; */

/*
 * Equations
 */


equation_clause	: 
	EQUATION^ ( equation ";"! | annotation! ";"! )*
	<< #0->rml = Absyn__EQUATIONS(sibling_list(#0->down)); >>
	;

algorithm_clause :
	ALGORITHM^ ( equation ";"! | annotation! ";"! )*
	<< #0->rml = Absyn__ALGORITHMS(mk_nil()); >>
	;

equation : << bool is_assign = false; AST *top; >>
	CONNECT^ LPAR c1: component_reference "," c2:component_reference RPAR
	  << #0->rml = Absyn__EQ_5fCONNECT(#c1->rml,#c2->rml); >>
	| ( lh:simple_expression << top = #lh; >>
	    { ( a:ASSIGN^ << top = #a; >>
	      | e:EQUALS^ << top = #e; >> )
	      rh:expression << is_assign=true; >> }
	    << 
	       if(is_assign)
		 top->rml = Absyn__EQ_5fEQUALS(#lh->rml, #rh->rml);
	       else
		 top->rml = Absyn__EQ_5fEXPR(#lh->rml);
	    >>
	| conditional_equation
	| for_clause
	| while_clause )
	comment!
	;

/* conditional_equation : */
/* 	  i:IF^ expression << #i->setOpType(OP_FUNCTION); #i->setTranslation("If"); >>  */
/* 	  THEN! */
/* 	  el:equation_list << #el->setTranslation(";"); >> */
/* 	  ( */
/* 	   elseif_clause */
/* 	  | ELSE! */
/* 	    el2:equation_list << #el2->setTranslation(";"); >> */
/* 	  |  */
/* 	  ) */
/* 	    END! IF! */
/* 	  ; */

/* elseif_clause: */
/* 	  e:ELSEIF^ << #e->setOpType(OP_FUNCTION); #e->setTranslation("If"); >> */
/* 	  expression THEN!  */
/* 	  el:equation_list << #el->setTranslation(";"); >> */
/* 	  ( elseif_clause | ELSE! el2:equation_list << #el2->setTranslation(";"); >> | ) */
/* 	  ; */

conditional_equation :
	<< bool is_elseif=false; /* AST *e_ast; */ >>

	i:IF^ expression THEN!

	el:equation_list << /* #el->setTranslation(";"); */ >>

	( ELSEIF! << is_elseif=true; >> expression THEN!
	el1:equation_list << /* #el1->setTranslation(";"); */ >> )*

/* 	The LT(1) is there just to silence an ANTLR warning. It's not used. */
	{ ( <</*LT(1),*/is_elseif>>? els:ELSE << /* #els->setTranslation("True"); */ >> | ELSE! )
	  el2:equation_list << /* #el2->setTranslation(";"); */ >> }

	END! IF!
	<< if (is_elseif) {
	  /* #i->setOpType(OP_FUNCTION); 
	     #i->setTranslation("Which"); */
	   } else {
	  /* #i->setOpType(OP_FUNCTION); 
	     #i->setTranslation("If");  */
	   }
	>>
	;

for_clause :
	FOR^ id:IDENT IN! e1:expression LOOP!
	el:equation_list
	END! FOR!
	<< 
	   #0->rml = Absyn__EQ_5fFOR(mk_scon($id.u.stringval),
				     #e1->rml,
				     sibling_list(#el));
	>>
	;

while_clause :
	while_:WHILE^ expression LOOP!

	el:equation_list << /* #el->setTranslation(";"); */ >>
	END! WHILE!
	<< /* #while_->setOpType(OP_FUNCTION); 
	      #while_->setTranslation("While"); */
	>>
	;

equation_list :
	( equation ";"! )*
	<< /* #0=#(#[EXTRA_TOKEN],#0); */ >>
	;

/*
 * Expressions
 */

expression :

	range_expression 
	| ifpart:IF^
	  e1:expression 
	  THEN!
	  e2:range_expression
	  ELSE!
	  e3:expression
	  << #0->rml = Absyn__IFEXP(#e1->rml, #e2->rml, #e3->rml); >>
	;

range_expression :
	e1:simple_expression
	{ ":"^ e2:simple_expression { ":"! e3:simple_expression } }
	<<
	   if (#e2)
     	     if (#e3)
               #0->rml = Absyn__RANGE(#e1->rml,mk_some(#e2->rml),#e3->rml);
             else
               #0->rml = Absyn__RANGE(#e1->rml,mk_none(),#e2->rml);
        >>
	;

simple_expression : << void *l, *op; >>
	logical_term << l = #0->rml; >>
	( o:OR^ e2:logical_term
	  << #0->rml = Absyn__LBINARY(l, Absyn__OR, #e2->rml);
	     l = #0->rml; >>
	)*
	;

logical_term : << void *l, *op; >>
	logical_factor << l = #0->rml; >>
	( a:AND^ e2:logical_factor
	  << #0->rml = Absyn__LBINARY(l, Absyn__AND, #e2->rml);
	     l = #0->rml; >>
	)*
	;

logical_factor :
	not:NOT^ r:relation << #0->rml = Absyn__LUNARY(Absyn__NOT,#r->rml); >>
	| relation 
	;

relation : << void *relop; >>
	e1:arithmetic_expression 
	{ ( LESS^      << relop = Absyn__LESS; >>
	  | LESSEQ^    << relop = Absyn__LESSEQ; >>
	  | GREATER^   << relop = Absyn__GREATER; >>
	  | GREATEREQ^ << relop = Absyn__GREATEREQ; >>
	  | EQEQ^      << relop = Absyn__EQUAL; >>
	  | LESSGT^    << relop = Absyn__NEQUAL; >>
	  ) e2:arithmetic_expression 
	  << #0->rml = Absyn__RELATION(#e1->rml, relop, #e2->rml); >>
	}
	;

arithmetic_expression : << void *op; >>

	unary_arithmetic_expression
	(
	  ( PLUS^ << op = Absyn__ADD; >> | MINUS^ << op = Absyn__SUB; >> )
	  e2:term
	  << #0->rml = Absyn__BINARY(#0->down->rml,op,#e2->rml); >>
	)*
	;

unary_arithmetic_expression:

	PLUS^ t1:term  << #0->rml = Absyn__UNARY(Absyn__UPLUS,#t1->rml); >>
      | MINUS^ t2:term << #0->rml = Absyn__UNARY(Absyn__UMINUS,#t2->rml); >>
      | term
	;

term : << void *op; >>

	factor
	(
	  ( MULT^ << op = Absyn__MUL; >>
	  | DIV^  << op = Absyn__DIV; >> )
	  f:factor
	  << #0->rml = Absyn__BINARY(#0->down->rml,op,#f->rml); >>
	)*
	;

factor :
	  e1:primary 
	  { "^"^ e2:primary << #0->rml = Absyn__BINARY(#e1->rml,
						     Absyn__POW,
						     #e2->rml); >> }
	;

primary : << bool is_matrix; >>
	  par:LPAR^
	  e:expression RPAR!
	  << #par->rml = #e->rml; >>
	| op:LBRACK^
	  c:column_expression > [is_matrix] 
	  << 
	     if (is_matrix) {
	       /* FIXME */
	     } else {
	       #0->rml = Absyn__ARRAY(sibling_list(#c));
	     }
	  >>
	  RBRACK!
	| ni:UNSIGNED_INTEGER << #ni->rml = Absyn__INTEGER(mk_icon($ni.u.ival)); >>
	| nr:UNSIGNED_REAL   << #nr->rml = Absyn__REAL(mk_rcon($nr.u.realval)); >>
	| f:FALS/*E*/        << #f->rml = Absyn__BOOL(RML_FALSE); >>
	| t:TRU/*E*/         << #t->rml = Absyn__BOOL(RML_TRUE); >>
	| (name_path_function_arguments)?
	| i:component_reference << #0->rml = Absyn__CREF(#i->rml); >>
	| s:STRING           << #s->rml = Absyn__STRING(mk_scon($s.u.stringval)); >>
	;

name_path_function_arguments ! : << Attrib a = $[FUNCALL,"---"]; >>
	n:name_path f:function_arguments
	<< 
	   #0=#(#[&a],#n,#f);
	   #0->rml = Absyn__CALL(#n->rml, sibling_list(#f));
	>>
	;

name_path : << bool qualified = false; >>
	i:IDENT^
	{ dot:DOT^ n:name_path << qualified = true; >> }
        << if(qualified)
	     #0->rml = Absyn__QUALIFIED(mk_scon($i.u.stringval),#n->rml);
           else
             #0->rml = Absyn__IDENT(mk_scon($i.u.stringval)); >>
	;

/* member_list: */
/* 	comp_ref { dot:DOT^ */
/* 	( (member_list)? | name_path ) } */
/* 	; */

/* comp_ref: */
/* 	name_path b:LBRACK^ subscript_list RBRACK! */
/* 	; */

component_reference : << void *tail = NULL;>>
	  i:IDENT^ { a:subscripts }
	  << #i->rml = mk_scon($i.u.stringval); >>
	  { dot:DOT^ c:component_reference << tail = #c->rml; >> }
	  << if(tail)
	       #0->rml = Absyn__CREF_5fQUAL(#i->rml, #a?#a->rml:mk_nil(), tail);
             else
	       #0->rml = Absyn__CREF_5fIDENT(#i->rml, #a?#a->rml:mk_nil()); >>
	;

/* not in document's grammar */
column_expression > [bool is_matrix] :
	<< $is_matrix=false; >>
	row_expression ( ";"! row_expression << $is_matrix=true; >> )*
	;

row_expression :
	expression 
	( ","! expression 
	)*
        /* create token with translation {, balancer }, type BALANCED */
	<< /* #0=#(#[EXTRA_TOKEN,"{",OP_BALANCED,'}'],#0); */ >>
	;

function_arguments :
	p:LPAR! expression ( ","! expression )* RPAR! 
	;

comment : 
        /* several strings in a row is really one string continued on
	   several lines. */
	( s:STRING! )*
        /* Why is this syntactic predicate necessary?? */
	{ (annotation)? annotation! }
	;

annotation :
	ANNOTATION class_modification
	;
