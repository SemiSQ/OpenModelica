#ifndef INC_flat_modelica_parser_hpp_
#define INC_flat_modelica_parser_hpp_

#include "antlr/config.hpp"
/* $ANTLR 2.7.1: "flat_modelica_parser.g" -> "flat_modelica_parser.hpp"$ */
#include "antlr/TokenStream.hpp"
#include "antlr/TokenBuffer.hpp"
#include "flat_modelica_parserTokenTypes.hpp"
#include "antlr/LLkParser.hpp"

#line 2 "flat_modelica_parser.g"


#define null 0


#line 18 "flat_modelica_parser.hpp"
class flat_modelica_parser : public ANTLR_USE_NAMESPACE(antlr)LLkParser, public flat_modelica_parserTokenTypes
 {
#line 1 "flat_modelica_parser.g"
#line 22 "flat_modelica_parser.hpp"
protected:
	flat_modelica_parser(ANTLR_USE_NAMESPACE(antlr)TokenBuffer& tokenBuf, int k);
public:
	flat_modelica_parser(ANTLR_USE_NAMESPACE(antlr)TokenBuffer& tokenBuf);
protected:
	flat_modelica_parser(ANTLR_USE_NAMESPACE(antlr)TokenStream& lexer, int k);
public:
	flat_modelica_parser(ANTLR_USE_NAMESPACE(antlr)TokenStream& lexer);
	flat_modelica_parser(const ANTLR_USE_NAMESPACE(antlr)ParserSharedInputState& state);
	public: void stored_definition();
	public: void within_clause();
	public: void class_definition();
	public: void name_path();
	public: void class_type();
	public: void class_specifier();
	public: void string_comment();
	public: void composition();
	public: void base_prefix();
	public: void array_subscripts();
	public: void class_modification();
	public: void comment();
	public: void enumeration();
	public: void type_prefix();
	public: void enum_list();
	public: void enumeration_literal();
	public: void element_list();
	public: void public_element_list();
	public: void protected_element_list();
	public: void initial_equation_clause();
	public: void initial_algorithm_clause();
	public: void equation_clause();
	public: void algorithm_clause();
	public: void external_clause();
	public: void language_specification();
	public: void external_function_call();
	public: void annotation();
	public: void component_reference();
	public: void expression_list();
	public: void element();
	public: void import_clause();
	public: void extends_clause();
	public: void component_clause();
	public: void constraining_clause();
	public: void explicit_import_name();
	public: void implicit_import_name();
	public: bool  name_path_star();
	public: void type_specifier();
	public: void component_list();
	public: void component_declaration();
	public: void declaration();
	public: void modification();
	public: void expression();
	public: void argument_list();
	public: void argument();
	public: void element_modification();
	public: void element_redeclaration();
	public: void component_clause1();
	public: void equation_annotation_list();
	public: void equation();
	public: void algorithm();
	public: void simple_expression();
	public: void equality_equation();
	public: void conditional_equation_e();
	public: void for_clause_e();
	public: void connect_clause();
	public: void when_clause_e();
	public: void function_call();
	public: void assign_clause_a();
	public: void multi_assign_clause_a();
	public: void conditional_equation_a();
	public: void for_clause_a();
	public: void while_clause();
	public: void when_clause_a();
	public: void equation_list();
	public: void equation_elseif();
	public: void algorithm_list();
	public: void algorithm_elseif();
	public: void for_indices();
	public: void else_when_e();
	public: void else_when_a();
	public: void connector_ref();
	public: void connector_ref_2();
	public: void if_expression();
	public: void elseif_expression();
	public: void for_index();
	public: void for_indices2();
	public: void logical_expression();
	public: void logical_term();
	public: void logical_factor();
	public: void relation();
	public: void arithmetic_expression();
	public: void rel_op();
	public: void unary_arithmetic_expression();
	public: void term();
	public: void factor();
	public: void primary();
	public: void component_reference__function_call();
	public: void function_arguments();
	public: void for_or_expression_list();
	public: void named_arguments();
	public: void for_or_expression_list2();
	public: void named_arguments2();
	public: void named_argument();
	public: void expression_list2();
	public: void subscript();
private:
	static const char* _tokenNames[];
	
	static const unsigned long _tokenSet_0_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_0;
	static const unsigned long _tokenSet_1_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_1;
	static const unsigned long _tokenSet_2_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_2;
	static const unsigned long _tokenSet_3_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_3;
	static const unsigned long _tokenSet_4_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_4;
	static const unsigned long _tokenSet_5_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_5;
	static const unsigned long _tokenSet_6_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_6;
	static const unsigned long _tokenSet_7_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_7;
	static const unsigned long _tokenSet_8_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_8;
	static const unsigned long _tokenSet_9_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_9;
	static const unsigned long _tokenSet_10_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_10;
	static const unsigned long _tokenSet_11_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_11;
	static const unsigned long _tokenSet_12_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_12;
	static const unsigned long _tokenSet_13_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_13;
	static const unsigned long _tokenSet_14_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_14;
	static const unsigned long _tokenSet_15_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_15;
	static const unsigned long _tokenSet_16_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_16;
};

#endif /*INC_flat_modelica_parser_hpp_*/
