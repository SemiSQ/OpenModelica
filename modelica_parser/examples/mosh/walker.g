
header "post_include_hpp" {

#define null 0
#include "value.hpp"
#include <cmath>
#include "symboltable.hpp"
#include "modelica_runtime_error.hpp"
#include <string>
}

options {
	language = "Cpp";
}

class modelica_tree_parser extends TreeParser;

options {
	importVocab = modelica_parser;
	k = 2;
	buildAST = false;
    defaultErrorHandler = false;
}

{
// This stuff goes into modelica_tree_parser.hpp
protected:
    symboltable* m_symboltable;
}

stored_definition
			{
				// Put your initialization here
			}
			:
			#(STORED_DEFINITION (within_clause)?
				((FINAL)? class_definition)*)
			{
			// Put your actions here
			}
			;

within_clause 
			{
				// Initialization
			}
			:
  			#(WITHIN^ (name_path)?)
			{
				// Actions
			}
			;

class_definition 
		{
			// Initialization
		}
		:
		#(CLASS_DEFINITION 
			(ENCAPSULATED)? 
			(PARTIAL)?
			class_type
			IDENT
			class_specifier)
		{ 
			// Actions
		}
		;

class_type 
		{
			// Initialization
		}
		:
		( CLASS | MODEL | RECORD | BLOCK | CONNECTOR | TYPE | PACKAGE 
			| FUNCTION 
		)
		{
			// Actions
		}
		;

class_specifier 
		{
			// Initialization
		}
		:
		( string_comment composition
		| EQUALS name_path ( array_subscripts )? ( class_modification )? comment
		)
		{
			// Actions
		}
		;

composition 
		{
			// Initialization
		}
		:
		element_list
		(	public_element_list
		|	protected_element_list
		|	equation_clause
		|	algorithm_clause
		)*
		( EXTERNAL	( language_specification )? 
			( external_function_call )?
			( annotation )?
		)?
		{
			// Actions
		}
		;

public_element_list 
		{
			// Initialization
		}
		:
		#(PUBLIC element_list)
		{
			// Actions
		}
		;

protected_element_list
		{
			// Initialization
		}
		:
		#(PROTECTED element_list)
		{
			// Actions
		}
		;

language_specification 
		{
			// Initialization
		}
		:
		STRING
		{
			// Actions
		}
		;

external_function_call 
		{
			// Initialization
		}
		:
		#(EXTERNAL_FUNCTION_CALL 
			(
				(IDENT (expression_list)?)
				|#(EQUALS component_reference IDENT (expression_list)?)
			)
		)
		{
			// Actions
		}
		;

element_list 
		{
			// Initialization
		}
		:
		(	(	element
			|	element_list_annotation
			)
		)*
		{
			// Actions
		}
		;

element_list_annotation 
		{
			// Initialization
		}
		:
		annotation
		{ 
			// Actions
		}
		;


element 
		{
			// Initialization:
		}
		:
		import_clause
		|extends_clause
		|
		#(DECLARATION 
			( (FINAL)? (INNER | OUTER)?
			( component_clause
				| REPLACEABLE component_clause (constraining_clause)?
			)
			)
		)
		|
		#(DEFINITION
			( (FINAL)?
			(INNER | OUTER)?
			( class_definition
				| REPLACEABLE class_definition (constraining_clause)?
			)
			)
		)
		{ 
			// Actions
		}
		;

import_clause 
		{
			// Initialization
		}
		:
		#(IMPORT (explicit_import_name|implicit_import_name) comment)
		{
			// Actions
		}
		;

explicit_import_name
		{
			// Initialization
		}
		:
		#(EQUALS IDENT name_path)
		{
			// Actions
		}
		;

implicit_import_name
		{
			//Initialization
		}
		:
		#(UNQUALIFIED name_path)
		|#(QUALIFIED name_path)
		{
			//Actions
		}
		;


// Note that this is a minor modification of the standard by 
// allowing the comment.
extends_clause
		{
			// Initialization
		}
		: 
		#(EXTENDS name_path ( class_modification )? comment)
		{
			// Actions
		}
		;

constraining_clause 
		{
			// Initialization
		}
		:
		extends_clause
		{
			// Actions
		}
		;

component_clause 
		{
			// Initialization
		}
		:
		type_prefix type_specifier (array_subscripts)? component_list
		{
			// Actions
		}
		;

type_prefix 
		{
			// Initialization
		}
		:
		(FLOW)?
		(DISCRETE
		|PARAMETER
		|CONSTANT
		)?
		(INPUT
		|OUTPUT
		)?
		
		{
			// Actions
		}
		;

type_specifier 
		{
			// Initialization
		}
		:
		name_path
		{
			// Actions
		}
		;

component_list
		{
			// Initialization
		}
		:
		component_declaration (component_declaration)*
		{
			// Actions
		}
		;

component_declaration 
		{
			// Initialization
		}
		:
		declaration comment
		{
			// Actions
		}
		;

declaration
		{
			// Initialization
		} 
		:
		#(IDENT (array_subscripts)? (modification)?)
		{
			// Actions
		}
		;

modification 
		{
			// Initialization
		}
		:
		(	class_modification ( expression )?
		|#(EQUALS expression)
		|#(ASSIGN expression)
		)
		{
			// Actions
		}
		;

class_modification
		{
			// Initialization
		}
		:
		#(CLASS_MODIFICATION (argument_list)?)
		{
			// Actions
		}
		;

argument_list
		{
			// Initialization
		}
		:
		#(ARGUMENT_LIST argument (argument)*)
		{	
			// Actions
		}
		;

argument
		{
			// Initialization
		}
		:
		#(ELEMENT_MODIFICATION element_modification)
		{ 
			// Actions
		}
		|
		#(ELEMENT_REDECLARATION element_redeclaration) 
		{ 
			// Actions
		}
		;

element_modification 
		{
			// Initialization
		}
		:
		(FINAL)? component_reference modification string_comment
		{
			// Actions
		}
		;

element_redeclaration 
		{
			// Initialization
		}
		:
		#(REDECLARE
		(	(class_definition | component_clause1)
			|
			( REPLACEABLE ( class_definition | component_clause1 )
				(constraining_clause)?
			)
		)
		)
		{
			// Actions
		};

component_clause1 
		{
			// Initialization
		}
		:
		type_prefix type_specifier component_declaration
		{
			//Actions
		}
		;

equation_clause 
		{
			// Initialization
		}
		:
		#(EQUATION (equation |annotation)*)
		{
			// Actions
		}
		;

algorithm_clause 
		{
			// Initializatioon
		}
		:
		#(ALGORITHM (algorithm | annotation)*)
		{
			// Actions
		}
		;

equation 
		{
			// Initialization
		}
		:
        #(EQUATION_STATEMENT
            (	equality_equation
            |	conditional_equation_e
            |	for_clause_e
            |	when_clause_e
            |	connect_clause
            |	assert_clause
            )
            comment
        )
		{
			//Actions
		}
		;

algorithm 
		{
			value val;
            value* ptr;
		}
		:
        #(ALGORITHM_STATEMENT 
            (#(ASSIGN (
                        (component_reference val = expression)
                        {
                         // 0   if (!ptr) // New symbol
                         //   {
//                       //         symtab.insert(
                         //   }
                          
                        }
                    |	(expression_list component_reference function_call)
                    )
                )
            | component_reference function_call
            |	conditional_equation_a
            |	for_clause_a
            |	while_clause
            |	when_clause_a
            |	assert_clause
            )
            comment
        )
		{
			// Actions
		}
		;

equality_equation 
		{
			//Initialization
		}
		:
		#(EQUALS simple_expression expression)
		{
			// Actions
		}
		;

conditional_equation_e
		{
			// Initialization
		}
		:
		#(IF expression equation_list
		( equation_elseif )*
		( ELSE equation_list )?
		)
		{
			// Actions
		}
		;

conditional_equation_a 
		{
			// Initialization
		}
		:
		#(IF expression algorithm_list
		( algorithm_elseif )*
		( ELSE algorithm_list )?
		)
		{
			// Actions
		}
		;

for_clause_e 
		{
			// Initialization
		}
		:
		#(FOR IDENT expression equation_list)
		{
			// Actions
		}
		;

for_clause_a 
		{
			// Initialization
		}
		:
		#(FOR IDENT expression algorithm_list)
		{
			// Initialization
		}
		;

while_clause 
		{
			// Initialization
		}
		:
		#(WHILE expression algorithm_list)
		{
			// Actions
		}
		;

when_clause_e
		{
			// Initialization
		}
		:
		#(WHEN expression equation_list)
		{
			// Actions
		}
		;

when_clause_a 
		{
			// Initialization
		}
		:
		#(WHEN expression algorithm_list (else_when_a)*)
		{
			// Actions
		}
		;

else_when_a
		{
			// Initializations
		}
		:
		#(ELSEWHEN expression algorithm_list)
		{
			// Actions
		}
		;

equation_elseif 
		{
			// Initialization
		}
		:
		#(ELSEIF expression equation_list)
		{
			// Actions
		}
		;

algorithm_elseif
		{
			// Initialization
		}
		:
		#(ELSEIF expression	algorithm_list)
		{
			// Actions
		}
		;

equation_list 
		{
			// Initialization
		}
		:
		(equation)*
		{
			// Actions
		}
		;

algorithm_list 
		{
			// Initialization
		}
		:
		(algorithm)*
		{
			// Actions
		}
		;

connect_clause 
		{
			// Initialization
		}
		:
		#(CONNECT connector_ref connector_ref)
		{
			// Actions
		}
		;

connector_ref
		{
			// Initialization
		}
		:
		#(IDENT (array_subscripts)?)
		|#(DOT #(IDENT (array_subscripts)?) connector_ref_2)
		{
			// Actions
		}
		;

connector_ref_2 
		{
			// Initialization
		}
		:
		#(IDENT ( array_subscripts )?)
		{
			// Actions
		}
		;

assert_clause 
		{
			// Initialization
		}
		:
		#(ASSERT expression STRING ( PLUS STRING )*)
	    |#(TERMINATE STRING ( PLUS STRING )*)
		{
			// Actions
		}
		;

start_expression[symboltable* symtab] returns [value val]
		{
            m_symboltable = symtab;
		}
		:
		val = expression //{ print(val);}
		;

expression returns [value val]
		{
		
		}
		:
		(	val = simple_expression //{ print(val);}
		|	val = if_expression //{print(val);}
		)
		{

		}
		;

if_expression returns [value val] 
		{
			value expr1,expr2,expr3;
		}
		:
		#(IF expr1 = expression expr2 = expression expr3 = expression)
		{
			val = modelica_if(expr1, expr2, expr3);
		}
		;

simple_expression returns [value val] 
		{
			value log_expr1,log_expr2,log_expr3;
		}
		:
		#(RANGE3 log_expr1 = logical_expression log_expr2 = logical_expression log_expr3 = logical_expression)
		{
			val = create_array(log_expr1,log_expr2,log_expr3);
		}
		|#(RANGE2 log_expr1 = logical_expression log_expr2 = logical_expression)
		{
	  		val = create_array(log_expr1,log_expr2);
		}
		|val = logical_expression
		{
			// Actions
		}
		;

logical_expression returns [value val] 
		{
			value val_expr, val_term;
		}
		:
		val = logical_term
		| #(OR val_expr = logical_expression val_term = logical_term)
		{
			val = or_bool(val_expr, val_term);
		}
		;

logical_term returns [value val]
		{
			value val_term, val_factor;
		}
		:
		val = logical_factor
		|
		#(AND val_term = logical_term val_factor = logical_factor )
		{
	  		val = and_bool(val_term, val_factor);
		}
		;

logical_factor returns [value val] 
		{
			// Initialization
		}
		:
		#(NOT val = relation) {val = not_bool(val); }
		| val = relation
		{
			// Actions
		}
		;

relation returns [value val]
		{
			value arith_val1, arith_val2;
		}
		:
		val = arithmetic_expression //( rel_op arithmetic_expression )?
		|#(LESS arith_val1 = arithmetic_expression arith_val2 = arithmetic_expression) 
			{ 
				//val = less(arith_val1,arith_val2);
			}
		|#(LESSEQ arith_val1 = arithmetic_expression arith_val2 = arithmetic_expression)
			{
				val = lesseq(arith_val1,arith_val2);
			}	
		|#(GREATER arith_val1 = arithmetic_expression arith_val2 = arithmetic_expression)
			{
				//val = greater(arith_val1,arith_val2);
			}
		|#(GREATEREQ arith_val1 = arithmetic_expression arith_val2 = arithmetic_expression)
			{
				val = greatereq(arith_val1,arith_val2);
			}
		|#(EQEQ arith_val1 = arithmetic_expression arith_val2 = arithmetic_expression)
			{
				val = eqeq(arith_val1,arith_val2);
			}
		|#(LESSGT arith_val1 = arithmetic_expression arith_val2 = arithmetic_expression)
			{
				val = lessgt(arith_val1,arith_val2);
			}
		;

rel_op 
		{
			// Initialization
		}
		:
		( LESS | LESSEQ | GREATER | GREATEREQ | EQEQ | LESSGT )
		{
			// Actions
		}
		;

arithmetic_expression returns [value val]
		{
			value val_arith,val_term;
		}
		:
		val = unary_arithmetic_expression
		|#(PLUS val_arith = arithmetic_expression val_term = term) 
			{
	  			val = val_arith + val_term;
			}
		|#(MINUS val_arith = arithmetic_expression val_term = term)
		{
	  		val = val_arith - val_term;
		}
		;

unary_arithmetic_expression returns [value val]  
		:
		#(UNARY_PLUS val = term )
		|#(UNARY_MINUS val = term ) {val = -val;}
		|val = term 
		;

term returns [value val]
		{
			value val_term,val_factor;
		}
		:
		val = factor
		|#(STAR val_term = term val_factor = factor) 
			{
	  			val = val_term * val_factor;
			}
		|#(SLASH val_term = term val_factor = factor)
		{
			val = val_term / val_factor;
		}
		;

factor returns [value val]
		{
  			value prim1,prim2;
		}
		:
		val = primary 
		|#(POWER prim1 = primary prim2 = primary) 
			{
	  			val = power(prim1,prim2);
			}
		;

primary	returns [value val]
		{
			value expr_val;
            value* tmp_val;
		}
		:
		( ui:UNSIGNED_INTEGER   		
			{
				val.set_value(atoi(ui->getText().c_str()));
	  		}
		| ur:UNSIGNED_REAL {val.set_value(atof(ur->getText().c_str()));}
		| s:STRING {val.set_value(s->getText());}
		| f:FALSE {val.set_value(false);}
		| t:TRUE {val.set_value(true);}
		|   component_reference__function_call
            {
                cout << "primary: matched component reference" << endl;
            /*    if (!tmp_val)
                {
                   throw modelica_runtime_error("Undefined symbol");
                }
                else
                {
                    val = value(*tmp_val);
                }
            */
            }
		| #(LPAR expression_list)
		| #(LBRACK expr_val = expression_list 
			{val = create_array(expr_val);}
            (expr_val = expression_list {val.append_to_array(expr_val);})*)
		| #(LBRACE val = expression_list)
		)
		{
			// Actions
		}
		;


component_reference__function_call returns [value* val]
		{
			// Initialization
		}
		:
		#(FUNCTION_CALL component_reference (function_call)?
            {
//                cout << "Function call" << endl;
            }
        )
        | component_reference
		{
			// Actions
		}
		;

name_path 
		{
			// Initialization
		}
		:
		IDENT
		|#(DOT IDENT name_path)
		{
			// Actions
		}
		;

component_reference returns [value val] 
		{
		
		}
		:
		#(i:IDENT (array_subscripts )? 
            {
                value* tmp = m_symboltable->lookup(i->getText());
                if (!tmp)
                {
                    std::string error = i->getText()+" undefined symbol";
                    throw modelica_runtime_error(error.c_str());
                }
            else
                {
                    return value(*tmp);
                }
                return tmp;
                
            }
            ) 
		|#(DOT #(IDENT (array_subscripts)?) component_reference)
		{
			// Actions
		}
		;

function_call returns [value val]
		{
			// Initialization
		}
		:
		#(FUNCTION_ARGUMENTS val = function_arguments)
		{
			// Actions
		}
		;

function_arguments returns [value val]
		{
			// Initialization
		}
		:
		( val = expression_list
		| named_arguments
		)
		{
			// Actions
		}
		;

named_arguments 
		{
			// Initialization
		}
		:
		named_argument (named_argument)*
		{
			// Actions
		}
		;

named_argument 
		{
			// Initialization
		}
		:
		#(EQUALS IDENT expression)
		{
			// Actions
		}
		;

expression_list returns [value val]
		{
			value expr_val;
		}
		:
		#(EXPRESSION_LIST expr_val = expression {val.set_type(value::array);val.append_to_array(expr_val);}
			(expr_val = expression {val.append_to_array(expr_val);})*)
		{
			
		}
		;

array_subscripts 
		{
			// Initialization
		}
		:
		#(LBRACK subscript (subscript)*)
		{
			// Actions
		}
		;

subscript 
		{
			// Initialization
		}
		:
		expression | COLON
		{
			// Actions
		}
		;

comment 
		{
			// Initialization
		}
		:
		#(COMMENT string_comment (annotation)?)|
		{
			// Actions
		}
		;

string_comment 
		{
			// Initialization
		}
		:
		#(STRING_COMMENT string_concatenation)|
		{
			// Actions
		}
		;

string_concatenation
        {
            // Initialization
        }
        :
        STRING
        | #(PLUS string_concatenation STRING)
        {
            // Actions
        }
        ;

annotation 
		{
			// Initialization
		}
		:
		#(ANNOTATION class_modification)
		{
			// Actions
		}
		;
