/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Link�ping University,
 * Department of Computer and Information Science,
 * SE-58183 Link�ping, Sweden.
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
 * from Link�ping University, either from the above address,
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

encapsulated package Error
"
  file:         Error.mo
  package:     Error
  description: Error handling

  RCS: $Id$

  This file contains the Error handling for the Compiler. The following steps
  are used to add a new error message:
  
    1) Add a new ErrorID constant below with an unique id.

    2) Add a new entry in the errorTable. Each entry is a tuple consisting of
       the ErrorID, a MessageType, a Severity and a message string. See the
       MessageType and Severity uniontypes below for more information about 
       them.

      The message string is the error message that should be displayed, which 
      may contain directives to insert tokens given when the message is used. 
      These directives are:
      
        %s: Inserts the next token in the list.
        %n: Inserts token number n in the list, where n is a number from 1 to 9.
       
      Note that these two directives do not affect each other. I.e. %s will move
      to the next token in the list regardless of any positional directives, and
      %1 will always point to the first token regardless of any %s before it.
      An example:

        Message: '%2: This is a %s of %2 %s and %1'
        Tokens: {'test', 'error', 'directives', 'messages'}
        Result: 'error: This is a test of error messages and directives'

    3) Use the new error message by calling addSourceMessage or addMessage with
       it's ErrorID.
"


public
uniontype Severity "severity of message"
  record ERROR "Error when tool can not succed in translation" end ERROR;

  record WARNING "Warning when tool succeds but with warning" end WARNING;

  record NOTIFICATION "Additional information to user, e.g. what
             actions tool has taken to succed in translation" end NOTIFICATION;
end Severity;

public
uniontype MessageType "runtime scripting /interpretation error"
  record SYNTAX "syntax errors" end SYNTAX;

  record GRAMMAR "grammar errors" end GRAMMAR;

  record TRANSLATION "instantiation errors: up to
           flat modelica" end TRANSLATION;

  record SYMBOLIC "Symbolic manipulation error,
           simcodegen, up to .exe file" end SYMBOLIC;

  record SIMULATION "Runtime simulation error" end SIMULATION;

  record SCRIPTING "runtime scripting /interpretation error" end SCRIPTING;

end MessageType;

public
type ErrorID = Integer "Unique error id. Used to
        look up message string and type and severity";

public
type MessageTokens = list<String>   "\"Tokens\" to insert into message at
            positions identified by
            - %s for string
            - %n for string number n" ;

public import Absyn;

/*
"Errors WARNINGS Notifications"
*/

public constant ErrorID SYNTAX_ERROR=1 "module" ;
public constant ErrorID GRAMMATIC_ERROR=2;
public constant ErrorID LOOKUP_ERROR=3;
public constant ErrorID LOOKUP_ERROR_COMPNAME=4;
public constant ErrorID LOOKUP_VARIABLE_ERROR=5;
public constant ErrorID ASSIGN_CONSTANT_ERROR=6;
public constant ErrorID ASSIGN_PARAM_ERROR=7;
public constant ErrorID ASSIGN_READONLY_ERROR=8;
public constant ErrorID ASSIGN_TYPE_MISMATCH_ERROR=9;
public constant ErrorID IF_CONDITION_TYPE_ERROR=10;
public constant ErrorID FOR_EXPRESSION_TYPE_ERROR=11;
public constant ErrorID WHEN_CONDITION_TYPE_ERROR=12;
public constant ErrorID WHILE_CONDITION_TYPE_ERROR=13;
public constant ErrorID END_ILLEGAL_USE_ERROR=14;
public constant ErrorID DIVISION_BY_ZERO=15;
public constant ErrorID MODULO_BY_ZERO=16;
public constant ErrorID REM_ARG_ZERO=17;
public constant ErrorID SCRIPT_READ_SIM_RES_ERROR=18;
public constant ErrorID SCRIPT_READ_SIM_RES_SIZE_ERROR=19;
public constant ErrorID LOAD_MODEL_ERROR=20;
public constant ErrorID WRITING_FILE_ERROR=21;
public constant ErrorID SIMULATOR_BUILD_ERROR=22;
public constant ErrorID DIMENSION_NOT_KNOWN=23;
public constant ErrorID UNBOUND_VALUE=24;
public constant ErrorID NEGATIVE_SQRT=25;
public constant ErrorID NO_CONSTANT_BINDING=26;
public constant ErrorID TYPE_NOT_FROM_PREDEFINED=27;
public constant ErrorID EQUATION_IN_RECORD=28;
public constant ErrorID EQUATION_IN_CONNECTOR=29;
public constant ErrorID UNKNOWN_EXTERNAL_LANGUAGE=30;
public constant ErrorID DIFFERENT_NO_EQUATION_IF_BRANCHES=31;
public constant ErrorID UNDERDET_EQN_SYSTEM=32;
public constant ErrorID OVERDET_EQN_SYSTEM=33;
public constant ErrorID STRUCT_SINGULAR_SYSTEM=34;
public constant ErrorID UNSUPPORTED_LANGUAGE_FEATURE=35;
public constant ErrorID NON_EXISTING_DERIVATIVE=36;
public constant ErrorID NO_CLASSES_LOADED=37;
public constant ErrorID INST_PARTIAL_CLASS=38;
public constant ErrorID LOOKUP_BASECLASS_ERROR=39;
public constant ErrorID REDECLARE_CLASS_AS_VAR=40;
public constant ErrorID REDECLARE_NON_REPLACEABLE=41;
public constant ErrorID COMPONENT_INPUT_OUTPUT_MISMATCH=42;
public constant ErrorID ARRAY_DIMENSION_MISMATCH=43;
public constant ErrorID ARRAY_DIMENSION_INTEGER=44;
public constant ErrorID EQUATION_TYPE_MISMATCH_ERROR=45;
public constant ErrorID INST_ARRAY_EQ_UNKNOWN_SIZE=46;
public constant ErrorID TUPLE_ASSIGN_FUNCALL_ONLY=47;
public constant ErrorID INVALID_CONNECTOR_TYPE=48;
public constant ErrorID CONNECT_TWO_INPUTS=49;
public constant ErrorID CONNECT_TWO_OUTPUTS=50;
public constant ErrorID CONNECT_FLOW_TO_NONFLOW=51;
public constant ErrorID INVALID_CONNECTOR_VARIABLE=52;
public constant ErrorID TYPE_ERROR=53;
public constant ErrorID MODIFY_PROTECTED=54;
public constant ErrorID INVALID_TUPLE_CONTENT=55;
public constant ErrorID IMPORT_PACKAGES_ONLY=56;
public constant ErrorID IMPORT_SEVERAL_NAMES=57;
public constant ErrorID LOOKUP_TYPE_FOUND_COMP=58;
public constant ErrorID LOOKUP_ENCAPSULATED_RESTRICTION_VIOLATION=59;
public constant ErrorID REFERENCE_PROTECTED=60;
public constant ErrorID ILLEGAL_SLICE_MOD=61;
public constant ErrorID ILLEGAL_MODIFICATION=62;
public constant ErrorID INTERNAL_ERROR=63;
public constant ErrorID TYPE_MISMATCH_ARRAY_EXP=64;
public constant ErrorID TYPE_MISMATCH_MATRIX_EXP=65;
public constant ErrorID MATRIX_EXP_ROW_SIZE=66;
public constant ErrorID OPERAND_BUILTIN_TYPE=67;
public constant ErrorID WRONG_TYPE_OR_NO_OF_ARGS=68;
public constant ErrorID DIFFERENT_DIM_SIZE_IN_ARGUMENTS=69;
public constant ErrorID DER_APPLIED_TO_CONST=70;
public constant ErrorID ARGUMENT_MUST_BE_INTEGER_OR_REAL=71;
public constant ErrorID ARGUMENT_MUST_BE_INTEGER=72;
public constant ErrorID ARGUMENT_MUST_BE_DISCRETE_VAR=73;
public constant ErrorID TYPE_MUST_BE_SIMPLE=74;
public constant ErrorID ARGUMENT_MUST_BE_VARIABLE=75;
public constant ErrorID NO_MATCHING_FUNCTION_FOUND=76;
public constant ErrorID NO_MATCHING_FUNCTION_FOUND_NO_CANDIDATE = 77;
public constant ErrorID FUNCTION_COMPS_MUST_HAVE_DIRECTION=78;
public constant ErrorID FUNCTION_SLOT_ALLREADY_FILLED=79;
public constant ErrorID NO_SUCH_ARGUMENT=80;
public constant ErrorID CONSTANT_OR_PARAM_WITH_NONCONST_BINDING=81;
public constant ErrorID SUBSCRIPT_NOT_INT_OR_INT_ARRAY=82;
public constant ErrorID TYPE_MISMATCH_IF_EXP=83;
public constant ErrorID UNRESOLVABLE_TYPE=84;
public constant ErrorID INCOMPATIBLE_TYPES=85;
public constant ErrorID ERROR_OPENING_FILE=86;
public constant ErrorID INHERIT_BASIC_WITH_COMPS=87;
public constant ErrorID MODIFIER_TYPE_MISMATCH_ERROR=88;
public constant ErrorID ERROR_FLATTENING=89;
public constant ErrorID DUPLICATE_ELEMENTS_NOT_IDENTICAL=90;
public constant ErrorID PACKAGE_VARIABLE_NOT_CONSTANT=91;
public constant ErrorID RECURSIVE_DEFINITION=92;
public constant ErrorID NOT_ARRAY_TYPE_IN_FOR_STATEMENT= 93;
public constant ErrorID BREAK_OUT_OF_LOOP= 94;
public constant ErrorID DIFFERENT_VARIABLES_SOLVED_IN_ELSEWHEN= 95;
public constant ErrorID GENERIC_TRANSLATION_ERROR = 96;
public constant ErrorID MODIFIER_DECLARATION_TYPE_MISMATCH_ERROR=97;
public constant ErrorID ASSERT_CONSTANT_FALSE_ERROR=98;
public constant ErrorID ARRAY_INDEX_OUT_OF_BOUNDS = 99;
public constant ErrorID COMPONENT_CONDITION_VARIABILITY = 100;
public constant ErrorID SELF_REFERENCE_EQUATION = 101;
public constant ErrorID CLASS_NAME_VARIABLE = 102;
public constant ErrorID DUPLICATE_MODIFICATIONS=103;
public constant ErrorID ILLEGAL_SUBSCRIPT=104;
public constant ErrorID ILLEGAL_EQUATION_TYPE=105;
public constant ErrorID ASSERT_FAILED=106;
public constant ErrorID WARNING_IMPORT_PACKAGES_ONLY=107;
public constant ErrorID MISSING_INNER_PREFIX = 108;
public constant ErrorID CONNECT_STREAM_TO_NONSTREAM=109;
public constant ErrorID IMPLICIT_ITERATOR_NOT_FOUND_IN_LOOP_BODY=110;
public constant ErrorID STRUCT_SINGULAR_SYSTEM_INITIALIZATION=111;
public constant ErrorID CIRCULAR_EQUATION=112;
public constant ErrorID IF_EQUATION_NO_ELSE=113;
public constant ErrorID IF_EQUATION_UNBALANCED=114;
public constant ErrorID LINSPACE_ILLEGAL_SIZE_ARG=115;
public constant ErrorID STRUCT_SINGULAR_SYSTEM_CONNECTORS=116;
public constant ErrorID CONNECT_INCOMPATIBLE_TYPES=117;
public constant ErrorID CONNECT_OUTER_OUTER=118;
public constant ErrorID CONNECTOR_ARRAY_NONCONSTANT=119;
public constant ErrorID CONNECTOR_ARRAY_DIFFERENT=120;
public constant ErrorID MODIFIER_NON_ARRAY_TYPE_WARNING=121;
public constant ErrorID BUILTIN_VECTOR_INVALID_DIMENSIONS=122;
public constant ErrorID UNROLL_LOOP_CONTAINING_WHEN=123;
public constant ErrorID CIRCULAR_PARAM=124;
public constant ErrorID NESTED_WHEN=125;
public constant ErrorID INVALID_ENUM_LITERAL=126;
public constant ErrorID UNEXCPECTED_FUNCTION_INPUTS_WARNING=127;
public constant ErrorID DUPLICATE_CLASSES_NOT_EQUIVALENT=128;
public constant ErrorID HIGHER_VARIABILITY_BINDING=129;
public constant ErrorID STRUCT_SINGULAR_EQUATION=130;
public constant ErrorID IF_EQUATION_WARNING=131;
public constant ErrorID IF_EQUATION_UNBALANCED_2=132;
public constant ErrorID EQUATION_GENERIC_FAILURE=133;
public constant ErrorID INST_PARTIAL_CLASS_CHECK_MODEL_WARNING=134; // adrpo: legal to instantiate a partial class when we run checkModel
public constant ErrorID VARIABLE_BINDING_TYPE_MISMATCH=135;
public constant ErrorID COMPONENT_NAME_SAME_AS_TYPE_NAME=136;
public constant ErrorID MODIFICATION_INDEX_OVERLAP=137;
public constant ErrorID MODIFICATION_AND_MODIFICATION_INDEX_OVERLAP=138;
public constant ErrorID MODIFICATION_OVERLAP=139;
public constant ErrorID MODIFICATION_INDEX_NOT_FOUND=140;
public constant ErrorID DUPLICATE_MODIFICATIONS_WARNING=141;
public constant ErrorID GENERATECODE_INVARS_HAS_FUNCTION_PTR=142;
public constant ErrorID LOOKUP_COMP_FOUND_TYPE=143;
public constant ErrorID DUPLICATE_ELEMENTS_NOT_SYNTACTICALLY_IDENTICAL=144;
public constant ErrorID GENERIC_INST_FUNCTION=145;
public constant ErrorID WRONG_NO_OF_ARGS=146;
public constant ErrorID TUPLE_ASSIGN_CREFS_ONLY=147;
public constant ErrorID LOOKUP_FUNCTION_GOT_CLASS=148;
public constant ErrorID NON_STREAM_OPERAND_IN_STREAM_OPERATOR = 149;
public constant ErrorID UNBALANCED_CONNECTOR = 150;
public constant ErrorID RESTRICTION_VIOLATION=151;
public constant ErrorID ZERO_STEP_IN_ARRAY_CONSTRUCTOR=152;
public constant ErrorID RECURSIVE_SHORT_CLASS_DEFINITION=153;
public constant ErrorID FUNCTION_ELEMENT_WRONG_PROTECTION=154;
public constant ErrorID FUNCTION_ELEMENT_WRONG_KIND=155;
public constant ErrorID WITHOUT_SENDDATA=156 "Used in external C sources; do not use another index";
public constant ErrorID DUPLICATE_CLASSES_TOP_LEVEL=157;
public constant ErrorID WHEN_EQ_LHS=158;
public constant ErrorID GENERIC_ELAB_EXPRESSION=159;
public constant ErrorID EXTENDS_EXTERNAL=160;
public constant ErrorID DOUBLE_DECLARATION_OF_ELEMENTS=161;
public constant ErrorID INVALID_REDECLARATION_OF_CLASS=162;
public constant ErrorID MULTIPLE_QUALIFIED_IMPORTS_WITH_SAME_NAME=163;
public constant ErrorID EXTENDS_INHERITED_FROM_LOCAL_EXTENDS=164;
public constant ErrorID LOOKUP_FUNCTION_ERROR=165;
public constant ErrorID ELAB_CODE_EXP_FAILED=166;
public constant ErrorID EQUATION_TRANSITION_FAILURE=167;
public constant ErrorID METARECORD_CONTAINS_METARECORD_MEMBER=168;
public constant ErrorID INVALID_EXTERNAL_OBJECT=169;
public constant ErrorID CIRCULAR_COMPONENTS=170;
public constant ErrorID FAILURE_TO_DEDUCE_DIMS_FROM_MOD=171;
public constant ErrorID REPLACEABLE_BASE_CLASS=172;
public constant ErrorID NON_REPLACEABLE_CLASS_EXTENDS=173;
public constant ErrorID ERROR_FROM_HERE=174;
public constant ErrorID EXTERNAL_FUNCTION_RESULT_NOT_CREF=175;
public constant ErrorID EXTERNAL_FUNCTION_RESULT_NOT_VAR=176;
public constant ErrorID EXTERNAL_FUNCTION_RESULT_ARRAY_TYPE=177;
public constant ErrorID INVALID_REDECLARE=178;

public constant ErrorID UNBOUND_PARAMETER_WITH_START_VALUE_WARNING=499;
public constant ErrorID UNBOUND_PARAMETER_WARNING=500;
public constant ErrorID BUILTIN_FUNCTION_SUM_HAS_SCALAR_PARAMETER=501;
public constant ErrorID BUILTIN_FUNCTION_PRODUCT_HAS_SCALAR_PARAMETER=502;
public constant ErrorID SETTING_FIXED_ATTRIBUTE = 503;
public constant ErrorID PROPAGATE_START_VALUE = 504;
public constant ErrorID SEMI_SUPPORTED_FUNCTION = 505;
public constant ErrorID FAILED_TO_EVALUATE_FUNCTION = 506;
public constant ErrorID OVERDET_INITIAL_EQN_SYSTEM = 507;
public constant ErrorID FINAL_OVERRIDE = 508;
public constant ErrorID WARNING_RELATION_ON_REAL=509;
public constant ErrorID WARNING_BUILTIN_DELAY=510;
public constant ErrorID When_With_IF=511;
public constant ErrorID OUTER_MODIFICATION=512;
public constant ErrorID REDUNDANT_GUESS=513 "Used by MathCore in Backend";

public constant ErrorID DERIVATIVE_NON_REAL=514;
public constant ErrorID UNUSED_MODIFIER=515;
public constant ErrorID SELECTED_STATES=515;
public constant ErrorID MULTIPLE_MODIFIER=516;
public constant ErrorID INCONSISTENT_UNITS=517;
public constant ErrorID CONSISTENT_UNITS=518;
public constant ErrorID INCOMPLETE_UNITS=519;
public constant ErrorID INCOMPATIBLE_TYPES_FUNC=520;
public constant ErrorID ASSIGN_RHS_ELABORATION=521;
public constant ErrorID FAILED_TO_EVALUATE_EXPRESSION = 522;

public constant ErrorID INDEX_REDUCTION_NOTIFICATION=1000;
public constant ErrorID SELECTED_STATE_DUE_TO_START_NOTIFICATION = 1001;

public constant ErrorID INTERACTIVE_ASSIGN=5000;
public constant ErrorID MATCH_SHADOWING=5001;
public constant ErrorID META_POLYMORPHIC=5002;
public constant ErrorID META_FUNCTION_TYPE_NO_PARTIAL_PREFIX=5003;
public constant ErrorID META_MATCH_EQUATION_FORBIDDEN=5004;
public constant ErrorID META_UNIONTYPE_ALIAS_MODS=5005;
public constant ErrorID META_COMPLEX_TYPE_MOD=5006;
public constant ErrorID META_MATCHEXP_RESULT_NUM_ARGS=5007;
public constant ErrorID META_CEVAL_FUNCTION_REFERENCE=5008;
public constant ErrorID NON_INSTANTIATED_FUNCTION=5009;
public constant ErrorID META_UNSOLVED_POLYMORPHIC_BINDINGS=5010;
public constant ErrorID META_RECORD_FOUND_FAILURE=5011;
public constant ErrorID META_INVALID_PATTERN=5012;
public constant ErrorID META_MATCH_INPUT_OUTPUT_NON_CREF=5013;
public constant ErrorID META_MATCH_GENERAL_FAILURE=5014;
public constant ErrorID META_CONS_TYPE_MATCH=5015;
public constant ErrorID META_STRICT_RML_MATCH_IN_OUT=5016;
public constant ErrorID META_NONE_CREF=5017;
public constant ErrorID META_INVALID_PATTERN_NAMED_FIELD=5018;
public constant ErrorID META_INVALID_LOCAL_ELEMENT=5019;
public constant ErrorID META_INVALID_COMPLEX_TYPE=5020;
public constant ErrorID META_DECONSTRUCTOR_NOT_PART_OF_UNIONTYPE=5021;
public constant ErrorID META_TYPE_MISMATCH_PATTERN=5022;
public constant ErrorID META_DECONSTRUCTOR_NOT_RECORD=5023;
public constant ErrorID META_MATCHEXP_RESULT_TYPES=5024;
public constant ErrorID MATCHCONTINUE_TO_MATCH_OPTIMIZATION=5025;
public constant ErrorID META_DEAD_CODE=5026;
public constant ErrorID META_UNUSED_DECL=5027;
public constant ErrorID META_UNUSED_AS_BINDING=5028;
public constant ErrorID MATCH_TO_SWITCH_OPTIMIZATION=5029;
public constant ErrorID REDUCTION_TYPE_ERROR=5030;
public constant ErrorID UNSUPPORTED_REDUCTION_TYPE=5031;

public constant ErrorID COMPILER_ERROR = 5999;
public constant ErrorID COMPILER_WARNING = 6000;
public constant ErrorID COMPILER_NOTIFICATION = 6001;

public constant ErrorID SUSAN_ERROR = 7000 "Susan compiler error";
public constant ErrorID TEMPLATE_ERROR = 7001 "User error from within a template.";


protected constant list<tuple<Integer, MessageType, Severity, String>> errorTable=
         {(SYNTAX_ERROR,SYNTAX(),ERROR(),"Syntax error near: %s"),
          (GRAMMATIC_ERROR,GRAMMAR(),ERROR(),"%s"),
          (LOOKUP_ERROR,TRANSLATION(),ERROR(),
          "Class %s not found in scope %s."),
          (LOOKUP_ERROR_COMPNAME,TRANSLATION(),ERROR(),
          "Class %s not found in scope %s while instantiating %s."),
          (LOOKUP_VARIABLE_ERROR,TRANSLATION(),ERROR(),
          "Variable %s not found in scope %s"),
          (LOOKUP_BASECLASS_ERROR,TRANSLATION(),ERROR(),
          "Base class %s not found in scope %s"),
          (ASSIGN_CONSTANT_ERROR,TRANSLATION(),ERROR(),
          "Trying to assign to constant component in %s := %s"),
          (ASSIGN_PARAM_ERROR,TRANSLATION(),ERROR(),
          "Trying to assign to parameter component in %s := %s"),
          (ASSIGN_READONLY_ERROR,TRANSLATION(),ERROR(),
          "Trying to assign to readonly component in %s := %s"),
          (ASSIGN_TYPE_MISMATCH_ERROR,TRANSLATION(),ERROR(),
          "Type mismatch in assignment in %s := %s of %s := %s"),
          (IF_CONDITION_TYPE_ERROR,TRANSLATION(),ERROR(),
          "Type error in conditional ( %s). Expected Boolean, got %s."),
          (FOR_EXPRESSION_TYPE_ERROR,TRANSLATION(),ERROR(),
          "Type error in for expression (%s). Expected array got %s."),
          (WHILE_CONDITION_TYPE_ERROR,TRANSLATION(),ERROR(),
          "Type error in while conditional (%s). Expected Boolean got %s."),
          (WHEN_CONDITION_TYPE_ERROR,TRANSLATION(),ERROR(),
          "Type error in when conditional (%s). Expected Boolean scalar or vector, got %s."),
          (END_ILLEGAL_USE_ERROR,TRANSLATION(),ERROR(),
          "'end' can not be used outside array subscripts."),
          (DIVISION_BY_ZERO,TRANSLATION(),ERROR(),
          "Division by zero in %s / %s"),
          (MODULO_BY_ZERO,TRANSLATION(),ERROR(),
          "Modulo by zero in mod(%s,%s)"),
          (REM_ARG_ZERO,TRANSLATION(),ERROR(),
          "Second argument in rem is zero in rem(%s,%s)"),
          (SCRIPT_READ_SIM_RES_ERROR,SCRIPTING(),ERROR(),
          "Error reading simulation result."),
          (SCRIPT_READ_SIM_RES_SIZE_ERROR,SCRIPTING(),ERROR(),
          "Error reading simulation result size"),
          (LOAD_MODEL_ERROR,TRANSLATION(),ERROR(),
          "Class %s not found"),
          (WRITING_FILE_ERROR,SCRIPTING(),ERROR(),
          "Error writing to file %s."),
          (SIMULATOR_BUILD_ERROR,TRANSLATION(),ERROR(),
          "Error building simulator. Buildlog: %s"),
          (DIMENSION_NOT_KNOWN,TRANSLATION(),ERROR(),
          "Dimensions must be parameter or constant expression (in %s)."),
          (UNBOUND_VALUE,TRANSLATION(),ERROR(),
          "Variable %s has no value."),
          (NEGATIVE_SQRT,TRANSLATION(),ERROR(),
          "Negative value as argument to sqrt."),
          (NO_CONSTANT_BINDING,TRANSLATION(),ERROR(),
          "No constant value for variable %s in scope %s."),
          (TYPE_NOT_FROM_PREDEFINED,TRANSLATION(),ERROR(),
          "In class %s, class restriction 'type' can only be derived from predefined types."),
          (EQUATION_IN_RECORD,TRANSLATION(),ERROR(),
          "In class %s, equations not allowed in records"),
          (EQUATION_IN_CONNECTOR,TRANSLATION(),ERROR(),
          "In class %s, equations not allowed in connectors"),
          (EQUATION_TRANSITION_FAILURE,TRANSLATION(),ERROR(),
          "Equations are not allowed in %s."),
          (UNKNOWN_EXTERNAL_LANGUAGE,TRANSLATION(),ERROR(),
          "Unknown external language %s in external function declaration"),
          (DIFFERENT_NO_EQUATION_IF_BRANCHES,TRANSLATION(),ERROR(),
          "Different number of equations in the branches of the if equation: %s"),
          (UNSUPPORTED_LANGUAGE_FEATURE,TRANSLATION(),ERROR(),
          "The language feature %s is not supported. Suggested workaround: %s"),
          (UNDERDET_EQN_SYSTEM,SYMBOLIC(),ERROR(),
          "Too few equations, underdetermined system. The model has %s equation(s) and %s variable(s)"),
          (OVERDET_EQN_SYSTEM,SYMBOLIC(),ERROR(),
          "Too many equations, overdetermined system. The model has %s equation(s) and %s variable(s)"),
          (STRUCT_SINGULAR_SYSTEM,SYMBOLIC(),ERROR(),
          "Model is structurally singular, error found sorting equations %s for variables %s"),
          (STRUCT_SINGULAR_EQUATION,SYMBOLIC(),ERROR(),
          "Model is structurally singular in equation %s."),
          (STRUCT_SINGULAR_SYSTEM_CONNECTORS,SYMBOLIC(),WARNING(),
          "Model is structurally singular, the following connectors are not connected from the outside: %s"),
          (NON_EXISTING_DERIVATIVE,SYMBOLIC(),ERROR(),
          "Derivative of expression %s is non-existent"),
          (NO_CLASSES_LOADED,TRANSLATION(),ERROR(),
          "No classes are loaded."),
          (INST_PARTIAL_CLASS,TRANSLATION(),ERROR(),
          "Illegal to instantiate partial class %s"),
          (INST_PARTIAL_CLASS_CHECK_MODEL_WARNING,TRANSLATION(),WARNING(),
          "Forcing full instantiation of partial class %s during checkModel."),
          (VARIABLE_BINDING_TYPE_MISMATCH,TRANSLATION(),ERROR(),
          "Type mismatch in binding %s = %s, expected subtype of %s, got type %s."),
          (REDECLARE_CLASS_AS_VAR,TRANSLATION(),ERROR(),
          "Trying to redeclare the class %s as a variable"),
          (REDECLARE_NON_REPLACEABLE,TRANSLATION(),ERROR(),
          "Trying to redeclare %1 %2 but %1 not declared as replaceable"),
          (COMPONENT_INPUT_OUTPUT_MISMATCH,TRANSLATION(),ERROR(),
          "Component declared as %s when having the variable %s declared as input"),
          (ARRAY_DIMENSION_MISMATCH,TRANSLATION(),ERROR(),
          "Array dimension mismatch, expression %s has type %s, expected array dimensions [%s]"),
          (ARRAY_DIMENSION_INTEGER,TRANSLATION(),ERROR(),
          "Array dimension must be integer expression in %s which has type %s"),
          (EQUATION_TYPE_MISMATCH_ERROR,TRANSLATION(),ERROR(),
          "Type mismatch in equation %s of type %s"),
          (INST_ARRAY_EQ_UNKNOWN_SIZE,TRANSLATION(),ERROR(),
          "Array equation has unknown size in %s"),
          (TUPLE_ASSIGN_FUNCALL_ONLY,TRANSLATION(),ERROR(),
          "Tuple assignment only allowed when rhs is function call (in %s)"),
          (INVALID_CONNECTOR_TYPE,TRANSLATION(),ERROR(),
          "Cannot connect objects of type %s, not a connector."),
          (CONNECT_TWO_INPUTS,TRANSLATION(),ERROR(),
          "Cannot connect two input variables while connecting %s to %s unless one of them is inside and the other outside connector."),
          (CONNECT_TWO_OUTPUTS,TRANSLATION(),ERROR(),
          "Cannot connect two output variables while connecting %s to %s unless one of them is inside and the other outside connector."),
          (CONNECT_FLOW_TO_NONFLOW,TRANSLATION(),ERROR(),
          "Cannot connect flow component %s to non-flow component %s"),
          (CONNECT_INCOMPATIBLE_TYPES,TRANSLATION(),ERROR(),
          "Incompatible components in connect statement: connect(%s, %s)\n- %s has components %s\n- %s has components %s"),
          (CONNECT_OUTER_OUTER,TRANSLATION(),ERROR(),
          "Illegal connecting two outer connectors in statement connect(%s, %s)"),
          (CONNECTOR_ARRAY_NONCONSTANT,TRANSLATION(),ERROR(),
          "in statement %s, subscript %s is not a parameter or constant"),

          (CONNECTOR_ARRAY_DIFFERENT,TRANSLATION(),ERROR(),
          "Unmatched dimension in equation connect(%s, %s)"),
          (MODIFIER_NON_ARRAY_TYPE_WARNING,TRANSLATION(),WARNING(),
          "Non-array modification '%s' for array component, possibly due to missing 'each'.\n"),
          (BUILTIN_VECTOR_INVALID_DIMENSIONS,TRANSLATION(),ERROR(),
          "In scope %s, in component %s: Invalid dimensions %s in %s, no more than one dimension may have size > 1."),
          (UNROLL_LOOP_CONTAINING_WHEN,TRANSLATION(),ERROR(),
          "Unable to unroll for loop containing when statements or equations: %s\n"),
          (CIRCULAR_PARAM, TRANSLATION(), ERROR(), " Variable '%s' has a cyclic dependency and has variability %s."),
          (NESTED_WHEN, TRANSLATION(), ERROR(),
          "Nested when statements are not allowed."),
          (INVALID_ENUM_LITERAL, TRANSLATION(), ERROR(),
          "Invalid use of reserved attribute name %s as enumeration literal."),
          (UNEXCPECTED_FUNCTION_INPUTS_WARNING,TRANSLATION(), WARNING(),
          "Function %s has not the expected inputs. Expected inputs are %s."), 
          (RESTRICTION_VIOLATION,TRANSLATION(),ERROR(),"Restriction violation: %s is a %s, not a %s"),
          (ZERO_STEP_IN_ARRAY_CONSTRUCTOR, TRANSLATION(), ERROR(),
          "Step equals 0 in array constructor %s."),
          
           /*
          (CONNECT_STREAM_TO_NONSTREAM,TRANSLATION(),ERROR(),
          "Cannot connect stream component %s to non-stream component %s"),
           */
          (INVALID_CONNECTOR_VARIABLE,TRANSLATION(),ERROR(),
          "The type of variables %s (%s) are inconsistent in connect equations"),
          (TYPE_ERROR,TRANSLATION(),ERROR(),
          "Wrong type on %s, expected %s"),
          (MODIFY_PROTECTED,TRANSLATION(),ERROR(),
          "Attempt to modify protected element %s"),
          (INVALID_TUPLE_CONTENT,TRANSLATION(),ERROR(),
          "Tuple %s  must contain component references only"),
          (IMPORT_PACKAGES_ONLY,TRANSLATION(),ERROR(),
          "%s is not a package, imports is only allowed for packages."),
          (IMPORT_SEVERAL_NAMES,TRANSLATION(),ERROR(),
          "%s found in several unqualified import statements."),
          (LOOKUP_TYPE_FOUND_COMP,TRANSLATION(),ERROR(),
          "Found a component with same name when looking for type %s"),
          (LOOKUP_COMP_FOUND_TYPE,TRANSLATION(),WARNING(),
          "Found a type with same name when looking for component %s"),          
          (LOOKUP_ENCAPSULATED_RESTRICTION_VIOLATION,TRANSLATION(),
          ERROR(),"Lookup is restricted to encapsulated elements only, violated in %s"),
          (REFERENCE_PROTECTED,TRANSLATION(),ERROR(),
          "Attempt to reference protected element %s"),
          (ILLEGAL_SLICE_MOD,TRANSLATION(),ERROR(),
          "Illegal slice modification %s"),
          (ILLEGAL_MODIFICATION,TRANSLATION(),ERROR(),
          "Illegal modification %s (of %s)"),(INTERNAL_ERROR,TRANSLATION(),ERROR(),"Internal error %s"),
          (TYPE_MISMATCH_ARRAY_EXP,TRANSLATION(),ERROR(),
          "Type mismatch in array expression in component %s. %s is of type %s while the elements %s are of type %s"),
          (TYPE_MISMATCH_MATRIX_EXP,TRANSLATION(),ERROR(),
          "Type mismatch in matrix rows in component %s. %s is a row of %s, the rest of the matrix is of type %s"),
          (MATRIX_EXP_ROW_SIZE,TRANSLATION(),ERROR(),
          "Incompatible row length in matrix expression in component %s. %s is a row of size %s, the rest of the matrix rows are of size %s"),
          (OPERAND_BUILTIN_TYPE,TRANSLATION(),ERROR(),
          "Operand of %s in component %s must be builtin-type in %s"),
          (WRONG_TYPE_OR_NO_OF_ARGS,TRANSLATION(),ERROR(),
          "Wrong type or wrong number of arguments to %s (in component %s)"),
          (WRONG_NO_OF_ARGS,TRANSLATION(),ERROR(),"Wrong number of arguments to %s"),
          (DIFFERENT_DIM_SIZE_IN_ARGUMENTS,TRANSLATION(),ERROR(),
          "Different dimension sizes in arguments to %s in component %s"),
          (ASSIGN_RHS_ELABORATION,TRANSLATION(),ERROR(),
          "Failed to elaborate rhs of %s"),
          (DER_APPLIED_TO_CONST,TRANSLATION(),ERROR(),
          "der operator applied to constant expression der(%s)"),
          (ARGUMENT_MUST_BE_INTEGER_OR_REAL,TRANSLATION(),ERROR(),
          "%s argument to %s in component %s must be Integer or Real expression"),
          (ARGUMENT_MUST_BE_INTEGER,TRANSLATION(),ERROR(),
          "%s argument to %s in component %s must be Integer expression"),
          (ARGUMENT_MUST_BE_DISCRETE_VAR,TRANSLATION(),ERROR(),
          "%s argument to %s in component %s must be discrete variable"),
          (TYPE_MUST_BE_SIMPLE,TRANSLATION(),ERROR(),
          "Type in %s must be simple type in component %s"),
          (ARGUMENT_MUST_BE_VARIABLE,TRANSLATION(),ERROR(),
          "%s argument to %s in component %s must be a variable"),
          (NO_MATCHING_FUNCTION_FOUND,TRANSLATION(),ERROR(),
          "No matching function found for %s in component %s\ncandidates are %s"),
          (NO_MATCHING_FUNCTION_FOUND_NO_CANDIDATE,TRANSLATION(),ERROR(),
          "No matching function found for %s"),
          (FUNCTION_COMPS_MUST_HAVE_DIRECTION,TRANSLATION(),ERROR(),
          "Component %s in function is neither input nor output"),
          (FUNCTION_SLOT_ALLREADY_FILLED,TRANSLATION(),ERROR(),
          "Slot %s already filled in a function call in component %s"),
          (NO_SUCH_ARGUMENT,TRANSLATION(),ERROR(),
          "No such argument %s in component %s"),
          (CONSTANT_OR_PARAM_WITH_NONCONST_BINDING,TRANSLATION(),
          ERROR(),"%s is a constant or parameter with a non-constant initializer %s"),
          (SUBSCRIPT_NOT_INT_OR_INT_ARRAY,TRANSLATION(),ERROR(),
          "Subscript is not an integer or integer array in %s which is of type %s, in component: %s"),
          (TYPE_MISMATCH_IF_EXP,TRANSLATION(),ERROR(),
          "Type mismatch in if-expression in component %s. True branch: %s has type %s,  false branch: %s has type %s"),
          (UNRESOLVABLE_TYPE,TRANSLATION(),ERROR(),
          "Cannot resolve type of expression %s in component %s"),
          (INCOMPATIBLE_TYPES,TRANSLATION(),ERROR(),
          "Incompatible argument types to operation %s in component %s, left type: %s, right type: %s"),
          (ERROR_OPENING_FILE,TRANSLATION(),ERROR(),
          "Error opening file %s"),
          (INHERIT_BASIC_WITH_COMPS,TRANSLATION(),ERROR(),
          "Class %s inherits primary type but has components"),
          (MODIFIER_TYPE_MISMATCH_ERROR,TRANSLATION(),ERROR(),
          "Type mismatch in modifier of component %s, expected type %s, got modifier %s of type %s"),
          (MODIFIER_DECLARATION_TYPE_MISMATCH_ERROR,TRANSLATION(),ERROR(),
          "Type mismatch in modifier of component %s, declared type %s, got modifier %s of type %s"),
          (ERROR_FLATTENING,TRANSLATION(),ERROR(),
          "Error occured while flattening model %s"),
          (NOT_ARRAY_TYPE_IN_FOR_STATEMENT, TRANSLATION(), ERROR(),
          "Expression %s in for-statement must be an array type"),
          (BREAK_OUT_OF_LOOP, GRAMMAR(), WARNING(),
          "Break statement found inside a loop"),
          (DUPLICATE_CLASSES_TOP_LEVEL,TRANSLATION(),ERROR(),
          "Duplicate classes on top level is not allowed (got %s)."),
          (DUPLICATE_ELEMENTS_NOT_IDENTICAL,TRANSLATION(),ERROR(),
          "Duplicate elements (due to inherited elements) not identical:\n\tfirst element is:  %s\tsecond element is: %s"),
          (DUPLICATE_ELEMENTS_NOT_SYNTACTICALLY_IDENTICAL,TRANSLATION(),WARNING(),
          "Duplicate elements (due to inherited elements) not syntactically identical but semantically identical:\n\tfirst element is:  %s\tsecond element is: %s\tModelica specification requires that elements are exactly identical."),          
          (DUPLICATE_CLASSES_NOT_EQUIVALENT,TRANSLATION(),ERROR(),
          "Duplicate class definitions (due to inheritance) not equivalent, first definiton is: %s, second definition is: %s"),
          (PACKAGE_VARIABLE_NOT_CONSTANT, TRANSLATION(),ERROR(),"Variable %s in package %s is not constant"),
          (RECURSIVE_DEFINITION,TRANSLATION(),ERROR(),"Class %s has a recursive definition, i.e. contains an instance of itself"),
          (NON_STREAM_OPERAND_IN_STREAM_OPERATOR, TRANSLATION(), ERROR(),
          "Operand %s to operator %s is not a stream variable."),
          (UNBALANCED_CONNECTOR, TRANSLATION(), WARNING(),
          "Connector %s is not balanced: %s"),
          (UNBOUND_PARAMETER_WARNING,TRANSLATION(),WARNING(),
          "Parameter %s has neither value nor start value, and is fixed during initialization (fixed=true)"),
          (UNBOUND_PARAMETER_WITH_START_VALUE_WARNING,TRANSLATION(),WARNING(),
          "Parameter %s has no value, and is fixed during initialization (fixed=true), using available start value (start=%s) as default value"),          
          (BUILTIN_FUNCTION_SUM_HAS_SCALAR_PARAMETER,TRANSLATION(),WARNING(),
          "Function \"sum\" has scalar as argument in %s in component %s"),
          (BUILTIN_FUNCTION_PRODUCT_HAS_SCALAR_PARAMETER,TRANSLATION(),WARNING(),
          "Function \"product\" has scalar as argument in %s in component %s"),
          (INDEX_REDUCTION_NOTIFICATION,SYMBOLIC(),NOTIFICATION(),
          "Differentiated equation %s to %s for index reduction"),
          (SELECTED_STATE_DUE_TO_START_NOTIFICATION,SYMBOLIC(),NOTIFICATION(),
          "Selecting %s as state since it has a start value and a potential state variable (appearing inside der()) was found in the same scope without start value."),

          (DIFFERENT_VARIABLES_SOLVED_IN_ELSEWHEN,SYMBOLIC(),ERROR(),
          "The same variables must me solved in elsewhen clause as in the when clause"),
          (ASSERT_CONSTANT_FALSE_ERROR,SYMBOLIC(),ERROR(),
          "Assertion triggered during translation: %s"),
          (SETTING_FIXED_ATTRIBUTE,TRANSLATION(),WARNING(),
          "Using overdeterimed solver for initialization. Setting fixed=false to the following variables: %s"),
          (PROPAGATE_START_VALUE,TRANSLATION(),WARNING(),
          "Failed to propagate the start value from variable dummy state %s to state %s. Provide a start value for the selected state instead"),
          (SEMI_SUPPORTED_FUNCTION,TRANSLATION(),WARNING(),
          "Using non-standardized function %s. For full conformance with language specification please use the appropriate function %s or the Modelica.Math library"),
          (GENERIC_TRANSLATION_ERROR,TRANSLATION(),ERROR(),
          "Error, %s"),
          (ARRAY_INDEX_OUT_OF_BOUNDS,TRANSLATION(),ERROR(),
          "Index out of bounds. Adressing position: %s, while array length is: %s"),
          (SELF_REFERENCE_EQUATION,TRANSLATION(), WARNING(),
          "Circular reference with variable \"%s\""),
/*   ******* INACTIVE FOR NOW
          (CLASS_NAME_VARIABLE, TRANSLATION(),ERROR(),
          "Declared a variable with name %s while having a class named %s"),
*/
          (DUPLICATE_MODIFICATIONS,TRANSLATION(),ERROR(),"Duplicate modifications in %s"),
          (DUPLICATE_MODIFICATIONS_WARNING,TRANSLATION(),WARNING(),
          "Duplicate modifications for attribute: %s in modifier: %s. \n\tConsidering only the first modification: %s and ignoring the rest %s."),
          (MODIFICATION_INDEX_OVERLAP,TRANSLATION(),WARNING(),
          "Index modifications: %s for array component: %s are overlapping. \n\tThe final bindings will be set by the last modifications given for the same index."),
          (MODIFICATION_AND_MODIFICATION_INDEX_OVERLAP,TRANSLATION(),WARNING(),
          "Index modifications: %s are overlapping with array binding modification %s for array component: %s. \n\tThe final bindings will be set by the last index modification given for the same index."),          
          (MODIFICATION_OVERLAP,TRANSLATION(),WARNING(),
          "Modifications: %s for component: %s are overlapping. \n\tThe final bindings will be set by the first modification."),
          (MODIFICATION_INDEX_NOT_FOUND,TRANSLATION(),ERROR(),
          "Instantiation of array component: %s failed because index modification: %s is invalid. \n\tArray component: %s has more dimensions than binding %s."),
          (COMPONENT_CONDITION_VARIABILITY,TRANSLATION(),ERROR(),
          "Component condition must be parameter or constant expression (in %s)."),
          (ILLEGAL_SUBSCRIPT,TRANSLATION(),ERROR(),
          "Illegal subscript %s for dimensions %s in component %s"),
          (ASSERT_FAILED,TRANSLATION(),ERROR(),
          "Assertion failed in function, message: %s "),
          (ILLEGAL_EQUATION_TYPE, TRANSLATION(),ERROR(),
          "Illegal type in equation %s, only builtin types (Real, String, Integer, Boolean or enumeration) or record type allowed in equation."),
          (FAILED_TO_EVALUATE_FUNCTION, TRANSLATION(),ERROR(),
          "Failed to evaluate function: %s"),
          (OVERDET_INITIAL_EQN_SYSTEM,SYMBOLIC(),WARNING(),
          "Overdetermined initial equation system, using solver for overdetermined systems."),
          /* Warning about package restriction, since MSL does not follow standard */
          (FINAL_OVERRIDE,TRANSLATION(),ERROR(),
          "trying to override final variable in class: %s"),
          (WARNING_IMPORT_PACKAGES_ONLY,TRANSLATION(),WARNING(),
          "%s is not a package, imports is only allowed for packages."),
          (WARNING_RELATION_ON_REAL,TRANSLATION(),WARNING(),
          "In component %s, in relation %s, %s on Reals is only allowed inside functions."),
          (WARNING_BUILTIN_DELAY,TRANSLATION(),WARNING(),
          "Improper use of builtin function delay(expr,delayTime,delayMax*) in component %s: %s"),
          (When_With_IF,TRANSLATION(),ERROR(),
          "When equations using if-statements on form 'if a then b=c else b=d' not implemented yet, use 'b=if a then c else d' as workaround\n%s"),
          (OUTER_MODIFICATION,TRANSLATION(),WARNING(),
          "Ignoring the modification on outer element: %s"),
          (REDUNDANT_GUESS,TRANSLATION(),WARNING(),
          "Start value is assigned for variable: %s, but not used since %s"),
          (UNUSED_MODIFIER,TRANSLATION(),ERROR(),
          "In modifier %s"),
          (MISSING_INNER_PREFIX,TRANSLATION(),WARNING(),
          "No corresponding 'inner' declaration found for component %s declared as '%s'.\n  The existing 'inner' components are: \n    %s\n  Check if you have not misspelled the 'outer' component name.\n  Please declare an 'inner' component with the same name in the top scope.\n  Continuing flattening by only considering the 'outer' component declaration."),
          (DERIVATIVE_NON_REAL,TRANSLATION(),ERROR(),
          "Illegal derivative. der(%s) in component %s is of type %s, which is not a subtype of Real"),
          (IMPLICIT_ITERATOR_NOT_FOUND_IN_LOOP_BODY,TRANSLATION(),ERROR(),
          "Identificator %s of implicit for iterator must be present as array subscript in the loop body."),
          (HIGHER_VARIABILITY_BINDING,TRANSLATION(),ERROR(),
          "Component %s of variability %s has binding %s of higher variability %s."),
          
          (INCOMPATIBLE_TYPES_FUNC,SYMBOLIC(),ERROR(),
          "While deriving %s to %s, types of inputs: %s and type of %s: %s did not match"),
          
          (MULTIPLE_MODIFIER,TRANSLATION(),ERROR(),
          "Multiple modifers in same scope for element %s, %s"),
          
          (STRUCT_SINGULAR_SYSTEM_INITIALIZATION,TRANSLATION(),ERROR(),
          "The initialization problem of model is structurally singular, error found sorting equations %s for variables %s"),
          (CIRCULAR_EQUATION, TRANSLATION(),ERROR(), " Equation : '%s'  has circular references for variable %s."),
          (SELECTED_STATES,TRANSLATION(),NOTIFICATION(), "The following variables are selected as states: %s"),
          (INCONSISTENT_UNITS, TRANSLATION(),WARNING(),"The system of units is inconsistent in term %s with the units %s and %s respectively."),
          (CONSISTENT_UNITS, TRANSLATION(),NOTIFICATION(),"The system of units is consistent."),
          (INCOMPLETE_UNITS, TRANSLATION(),NOTIFICATION(),"The system of units is incomplete. Please provide unit information to the model by e.g. using types from the SIunits package."),
          (IF_EQUATION_NO_ELSE, TRANSLATION(),ERROR(),"In equation %s. If-equation with conditions that are not parameter expressions must have an else branch, in equation."),
          (IF_EQUATION_UNBALANCED, TRANSLATION(),ERROR(),"In equation %s. If-equation with conditions that are not parameter expressions must have the same number of equations in each branch, equation count is %s for each respective branch."),
          (IF_EQUATION_UNBALANCED_2,SYMBOLIC(),ERROR(),"If-equation with conditions that are not parameter expressions must have the same number of equations in each branch, equation count is %s for each respective branch."),
          (LINSPACE_ILLEGAL_SIZE_ARG,TRANSLATION(),ERROR(),"In expression %s, third argument to linspace must be >= 2"),
          (INTERACTIVE_ASSIGN, SCRIPTING(),ERROR(), "Interactive assignment of %s failed for expression %s."),
          (MATCH_SHADOWING, TRANSLATION(),ERROR(), " Local variable '%s' shadows input or result variables in a {match,matchcontinue} expression."),
          (META_POLYMORPHIC, TRANSLATION(),ERROR(), " %s uses invalid subtypeof syntax. Only subtypeof Any is supported."),
          (META_FUNCTION_TYPE_NO_PARTIAL_PREFIX, TRANSLATION(),ERROR(), "%s is used as a function reference, but doesn't specify the partial prefix."),
          (IF_EQUATION_WARNING,SYMBOLIC(),WARNING(), "If-equations are only partially supported. Ignoring %s"),
          (EQUATION_GENERIC_FAILURE,TRANSLATION(),ERROR(),"Failed to instantiate equation %s"),
          (COMPONENT_NAME_SAME_AS_TYPE_NAME,GRAMMAR(),WARNING(),"Component %s has the same name as its type %s.\n\tThis is forbidden by Modelica specification and may lead to lookup errors."),
          (META_MATCH_EQUATION_FORBIDDEN,TRANSLATION(),ERROR(),"Match expression equation sections forbid the use of %s-equations."),
          (META_UNIONTYPE_ALIAS_MODS,TRANSLATION(),ERROR(),"Uniontype was not generated correctly. One possible cause is modifications, which are not allowed."),
          (META_COMPLEX_TYPE_MOD,TRANSLATION(),ERROR(),"MetaModelica complex types may not have modifiers."),
          (META_MATCHEXP_RESULT_NUM_ARGS,TRANSLATION(),ERROR(),"Match expression has mismatched number of expected (%s) and actual (%s) outputs. The expressions were %s and %s."),
          (GENERATECODE_INVARS_HAS_FUNCTION_PTR,SYMBOLIC(),ERROR(),"%s has a function pointer as input. OpenModelica does not support this feature in the interactive environment. Suggested workaround: Call this function with the arguments you want from another function (that does not have function pointer input). Then call that function from the interactive environment instead."),
          (META_CEVAL_FUNCTION_REFERENCE,TRANSLATION(),ERROR(),"Cannot evaluate function pointers (got %s)."),
          (NON_INSTANTIATED_FUNCTION,SYMBOLIC(),ERROR(),"Tried to use function %s, but it was not instantiated."),
          (GENERIC_INST_FUNCTION,TRANSLATION(),ERROR(),"Failed to instantiate function %s in scope %s"),
          (META_UNSOLVED_POLYMORPHIC_BINDINGS,TRANSLATION(),ERROR(),"Could not solve the polymorphism in the function call to %s\n  Input bindings:\n%s\n  Solved bindings:\n%s\n  Unsolved bindings:\n%s"),
          (META_RECORD_FOUND_FAILURE,TRANSLATION(),ERROR(),"In metarecord call %s: %s"),
          (META_INVALID_PATTERN,TRANSLATION(),ERROR(),"Invalid pattern: %s"),
          (META_MATCH_INPUT_OUTPUT_NON_CREF,TRANSLATION(),ERROR(),"Only component references are valid as %s of a match expression. Got %s."),
          (META_MATCH_GENERAL_FAILURE,TRANSLATION(),ERROR(),"Failed to elaborate match expression %s"),
          (TUPLE_ASSIGN_CREFS_ONLY,TRANSLATION(),ERROR(),"Tuple assignment only allowed for tuple of component references in lhs (in %s)"),
          (META_CONS_TYPE_MATCH,TRANSLATION(),ERROR(),"Failed to match types of cons expression %s. The head has type %s and the tail %s."),
          (LOOKUP_FUNCTION_GOT_CLASS,TRANSLATION(),ERROR(),"Looking for a function %s but found a %s."),
          (META_STRICT_RML_MATCH_IN_OUT,TRANSLATION(),ERROR(),"%s. Strict RML enforces match expression input and output to be the same as the function's."),
          (META_NONE_CREF,TRANSLATION(),ERROR(),"NONE is not acceptable syntax. Use NONE() instead."),
          (META_INVALID_PATTERN_NAMED_FIELD,TRANSLATION(),ERROR(),"Invalid named fields: %s"),
          (META_INVALID_LOCAL_ELEMENT,TRANSLATION(),ERROR(),"Only components without direction are allowed in local declarations, got: %s"),
          (META_INVALID_COMPLEX_TYPE,TRANSLATION(),ERROR(),"Invalid complex type name: %s"),
          (META_DECONSTRUCTOR_NOT_PART_OF_UNIONTYPE,TRANSLATION(),ERROR(),"In pattern %s: %s is not part of uniontype %s"),
          (META_TYPE_MISMATCH_PATTERN,TRANSLATION(),ERROR(),"Type mismatch in pattern %s\nactual type:\n  %s\nexpected type:\n  %s"),
          (META_DECONSTRUCTOR_NOT_RECORD,TRANSLATION(),ERROR(),"Call pattern is not a record deconstructor %s"),
          (META_MATCHEXP_RESULT_TYPES,TRANSLATION(),ERROR(),"Match expression has mismatched result types:%s"),
          (RECURSIVE_SHORT_CLASS_DEFINITION,TRANSLATION(),ERROR(),"Recursive short class definition of %s in terms of %s"),
          (FUNCTION_ELEMENT_WRONG_PROTECTION,TRANSLATION(),ERROR(),"%s was declared %s but should be %s."),
          (FUNCTION_ELEMENT_WRONG_KIND,TRANSLATION(),ERROR(),"Element is not allowed in function context: %s"),
          (WITHOUT_SENDDATA,SCRIPTING(),ERROR(),"%s failed because OpenModelica was configured without sendData support."),
          (WHEN_EQ_LHS,TRANSLATION(),ERROR(),"Invalid left-hand side of when-equation: %s."),
          (GENERIC_ELAB_EXPRESSION,TRANSLATION(),ERROR(),"Failed to elaborate expression: %s"),
          (EXTENDS_EXTERNAL,TRANSLATION(),WARNING(),"Ignoring external declaration of the extended class: %s."),
          (DOUBLE_DECLARATION_OF_ELEMENTS,TRANSLATION(),ERROR(),
            "An element with name %s is already declared in this scope."),
          (INVALID_REDECLARATION_OF_CLASS,TRANSLATION(),ERROR(),
          "Invalid redeclaration of class %s, class extends only allowed on inherited classes."),
          (MULTIPLE_QUALIFIED_IMPORTS_WITH_SAME_NAME,TRANSLATION(),ERROR(),
          "Qualified import name %s already exists in this scope."),
          (EXTENDS_INHERITED_FROM_LOCAL_EXTENDS,TRANSLATION(),ERROR(),
          "Extends %s depends on inherited element %s."),
          (LOOKUP_FUNCTION_ERROR,TRANSLATION(),ERROR(),
          "Function %s not found in scope %s."),
          (INVALID_EXTERNAL_OBJECT,TRANSLATION(),ERROR(),
          "Invalid external object %s, %s."),
          (CIRCULAR_COMPONENTS,TRANSLATION(),ERROR(),
          "Cyclically dependent constants or parameters found in scope %s: %s"),
          (FAILURE_TO_DEDUCE_DIMS_FROM_MOD,TRANSLATION(),WARNING(),
          "Failed to deduce dimensions of %s due to unknown dimensions of modifier %s."),
          (REPLACEABLE_BASE_CLASS,TRANSLATION(),ERROR(),
          "Base class %s is replaceable."),
          (NON_REPLACEABLE_CLASS_EXTENDS,TRANSLATION(),ERROR(),
          "Non-replaceable base class %s in class extends."),
          (ERROR_FROM_HERE,TRANSLATION(),NOTIFICATION(),
          "From here:"),
          (INVALID_REDECLARE,TRANSLATION(),ERROR(),
          "Redeclaration of %s is not allowed."),
          (MATCHCONTINUE_TO_MATCH_OPTIMIZATION,TRANSLATION(),NOTIFICATION(),"This matchcontinue expression has no overlapping patterns and should be using match instead of matchcontinue."),
          (META_DEAD_CODE,TRANSLATION(),NOTIFICATION(),"Dead code elimination: %s."),
          (META_UNUSED_DECL,TRANSLATION(),NOTIFICATION(),"Unused local variable: %s."),
          (META_UNUSED_AS_BINDING,TRANSLATION(),NOTIFICATION(),"Removing unused as-binding: %s."),
          (FAILED_TO_EVALUATE_EXPRESSION,TRANSLATION(),ERROR(),"Could not evaluate expression: %s"),
          (MATCH_TO_SWITCH_OPTIMIZATION,TRANSLATION(),NOTIFICATION(),"Converted match expression to switch of type %s."),
          (ELAB_CODE_EXP_FAILED,TRANSLATION(),ERROR(),"Failed to elaborate %s as a code expression of type %s."),
          (METARECORD_CONTAINS_METARECORD_MEMBER,TRANSLATION(),ERROR(),"The called uniontype record (%s) contains a member (%s) that has a uniontype record as its type instead of a uniontype."),
          (REDUCTION_TYPE_ERROR,TRANSLATION(),ERROR(),"Reductions require the types of the %s and %s to be %s, but got: %s and %s."),
          (UNSUPPORTED_REDUCTION_TYPE,TRANSLATION(),ERROR(),"Expected a reduction function with type signature ('A,'B) => 'B, but got %s."),
          (EXTERNAL_FUNCTION_RESULT_NOT_CREF,TRANSLATION(),ERROR(),"The lhs (result) of the external function declaration is not a component reference: %s"),
          (EXTERNAL_FUNCTION_RESULT_NOT_VAR,TRANSLATION(),ERROR(),"The lhs (result) of the external function declaration is not a variable"),
          (EXTERNAL_FUNCTION_RESULT_ARRAY_TYPE,TRANSLATION(),ERROR(),"The lhs (result) of the external function declaration has array type (%s), but this is not allowed in the specification. You need to pass it as an input to the function (preferably also with a size()-expression to avoid out-of-bounds errors in the external call)."),

          (COMPILER_NOTIFICATION,TRANSLATION(),NOTIFICATION(),"%s"),
          (COMPILER_WARNING,TRANSLATION(),WARNING(),"%s"),
          (COMPILER_ERROR,TRANSLATION(),ERROR(),"%s"),
          
          (SUSAN_ERROR,TRANSLATION(),ERROR(),"%s"),
          (TEMPLATE_ERROR,TRANSLATION(),ERROR(),"Template error: %s")
          };

protected import ErrorExt;
protected import Print;
protected import RTOpts;
protected import System;

public function updateCurrentComponent "Function: updateCurrentComponent
This function takes a String and set the global var to 
which the current variable the compiler is working with."
  input String component;
  input Absyn.Info info;
protected
  String filename;
  Integer ls, le, cs, ce;
  Boolean ro;
algorithm
  Absyn.INFO(filename, ro, ls, cs, le, ce, _) := info;
  filename := fixFilenameForTestsuite(filename);
  ErrorExt.updateCurrentComponent(component, ro, filename, ls, le, cs, ce);
end updateCurrentComponent;

public function addMessage "Implementation of Relations
  function: addMessage
  Adds a message given ID and tokens. The rest of the info
  is looked up in the message table."
  input ErrorID inErrorID;
  input MessageTokens inMessageTokens;
algorithm
  _ := matchcontinue (inErrorID,inMessageTokens)
    local
      MessageType msg_type;
      Severity severity;
      String msg,msg_type_str,severity_string,id_str;
      ErrorID error_id;
      MessageTokens tokens;
    case (error_id,tokens)
      equation
        //print(" adding message: " +& intString(error_id) +& "\n");
        (msg_type,severity,msg) = lookupMessage(error_id);
        msg_type_str = messageTypeStr(msg_type);
        severity_string = severityStr(severity);
        ErrorExt.addMessage(error_id, msg_type_str, severity_string, msg, tokens);
        //print(" succ add " +& msg_type_str +& " " +& severity_string +& ",  " +& msg +& "\n");
      then
        ();
    case (error_id,tokens)
      equation
        failure((_,_,_) = lookupMessage(error_id));
        Print.printErrorBuf("#Internal error, error message with id ");
        id_str = intString(error_id);
        Print.printErrorBuf(id_str);
        Print.printErrorBuf(" not defined.\n");
      then
        fail();
  end matchcontinue;
end addMessage;

public function addSourceMessage "
  Adds a message given ID, tokens and source file info.
  The rest of the info is looked up in the message table."
  input ErrorID inErrorID;
  input MessageTokens inMessageTokens;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue (inErrorID,inMessageTokens,inInfo)
    local
      MessageType msg_type;
      Severity severity;
      String msg,msg_type_str,severity_string,file,id_str;
      ErrorID error_id,sline,scol,eline,ecol;
      MessageTokens tokens;
      Boolean isReadOnly;
    case (error_id,tokens,Absyn.INFO(fileName = file,isReadOnly = isReadOnly,lineNumberStart = sline,columnNumberStart = scol,lineNumberEnd = eline,columnNumberEnd = ecol))
      equation
        file = fixFilenameForTestsuite(file);
        (msg_type,severity,msg) = lookupMessage(error_id);
        msg_type_str = messageTypeStr(msg_type);
        severity_string = severityStr(severity);
        ErrorExt.addSourceMessage(error_id, msg_type_str, severity_string, sline, scol,
          eline, ecol, isReadOnly, file, msg, tokens);
      then
        ();
    case (error_id,tokens,_)
      equation
        failure((_,_,_) = lookupMessage(error_id));
        Print.printErrorBuf("#Internal error, error message with id ");
        id_str = intString(error_id);
        Print.printErrorBuf(id_str);
        Print.printErrorBuf(" not defined.\n");
      then
        fail();
  end matchcontinue;
end addSourceMessage;


public function addMessageOrSourceMessage
"@author:adrpo
  Adds a message or a source message depending on the OPTIONAL source file info.
  If the source file info is not present a normal message is added.
  If the source file info is present a source message is added"
  input ErrorID inErrorID;
  input MessageTokens inMessageTokens;
  input Option<Absyn.Info> inInfoOpt;
algorithm
  _ := match (inErrorID,inMessageTokens,inInfoOpt)
    local
      Absyn.Info info;
    
    // we DON'T have an info, add message
    case (inErrorID,inMessageTokens,NONE())
      equation
        addMessage(inErrorID, inMessageTokens);
      then ();
    
    // we have an info, add source message
    case (inErrorID,inMessageTokens,SOME(info))
      equation
        addSourceMessage(inErrorID, inMessageTokens, info);
      then ();
  end match;
end addMessageOrSourceMessage;

public function printMessagesStr "Relations for pretty printing.
  function: printMessagesStr
  Prints messages to a string."
  output String res;
algorithm
  res := ErrorExt.printMessagesStr();
end printMessagesStr;

public function printErrorsNoWarning "
  Prints errors only to a string.
"
  output String res;
algorithm
  res := ErrorExt.printErrorsNoWarning();
end printErrorsNoWarning;

public function printMessagesStrLst "function: printMessagesStr
  Returns all messages as a list of strings, one for each message."
  output list<String> outStringLst;
algorithm
  outStringLst := matchcontinue ()
    case () then {"Not impl. yet"};
  end matchcontinue;
end printMessagesStrLst;

public function printMessagesStrLstType "function: printMessagesStrLstType
   Returns all messages as a list of strings, one for each message.
   Filters out messages of certain type."
  input MessageType inMessageType;
  output list<String> outStringLst;
algorithm
  outStringLst := matchcontinue (inMessageType)
    case (_) then {"Not impl. yet"};
  end matchcontinue;
end printMessagesStrLstType;

public function printMessagesStrLstSeverity "function: printMessagesStrLstSeverity
  Returns all messages as a list of strings, one for each message.
  Filters out messages of certain severity"
  input Severity inSeverity;
  output list<String> outStringLst;
algorithm
  outStringLst := matchcontinue (inSeverity)
    case (_) then {"Not impl. yet"};
  end matchcontinue;
end printMessagesStrLstSeverity;

public function clearMessages "clears the message buffer"
algorithm
  ErrorExt.clearMessages();
end clearMessages;

public function getNumMessages "Returns the number of messages in the message queue"
  output Integer num;
algorithm
  num := ErrorExt.getNumMessages();
end getNumMessages;

public function getNumErrorMessages "Returns the number of messages with severity 'Error' in the message queue "
  output Integer num;
algorithm
  num := ErrorExt.getNumErrorMessages();
end getNumErrorMessages;

public function getMessagesStr "Relations for interactive comm. These returns the messages as an array
  of strings, suitable for sending to clients like model editor, MDT, etc.

  function getMessagesStr

  Return all messages in a matrix format, vector of strings for each
  message, written out as a string.
"
  output String res;
algorithm
  res := ErrorExt.getMessagesStr();
end getMessagesStr;

public function getMessagesStrType "function getMessagesStrType

  Return all messages in a matrix format, vector of strings for each
  message, written out as a string.
  Filtered by a specific MessageType.
"
  input MessageType inMessageType;
  output String outString;
algorithm
  outString:=
  matchcontinue (inMessageType)
    case (_) then "not impl yet.";
  end matchcontinue;
end getMessagesStrType;

public function getMessagesStrSeverity "function getMessagesStrSeverity

  Return all messages in a matrix format, vector of strings for each
  message, written out as a string.
  Filtered by a specific MessageType.
"
  input Severity inSeverity;
  output String outString;
algorithm
  outString:=
  matchcontinue (inSeverity)
    case (_) then "not impl yet.";
  end matchcontinue;
end getMessagesStrSeverity;

protected function lookupMessage "Private Relations
  function: lookupMessage

  Finds a message given ErrorID by looking in the message list.
"
  input ErrorID errorID;
  output MessageType msgType;
  output Severity severity;
  output String msg;
algorithm
  (msgType,severity,msg) := lookupMessage2(errorTable, errorID);
end lookupMessage;

protected function lookupMessage2
  input list<tuple<ErrorID, MessageType, Severity, String>> inTplErrorIDMessageTypeSeverityStringLst;
  input ErrorID inErrorID;
  output MessageType outMessageType;
  output Severity outSeverity;
  output String outString;
algorithm
  (outMessageType,outSeverity,outString) := matchcontinue (inTplErrorIDMessageTypeSeverityStringLst,inErrorID)
    local
      ErrorID id1,id2,id;
      MessageType msg_type;
      Severity severity;
      String msg;
      list<tuple<ErrorID, MessageType, Severity, String>> rest;
    
    case (((id1,msg_type,severity,msg) :: _),id2)
      equation
        true = intEq(id1, id2);
      then
        (msg_type,severity,msg);
    
    case ((_ :: rest),id)
      equation
        (msg_type,severity,msg) = lookupMessage2(rest, id);
      then
        (msg_type,severity,msg);
  end matchcontinue;
end lookupMessage2;

protected function messageTypeStr "function: messageTypeStr

  Converts a MessageType to a string.
"
  input MessageType inMessageType;
  output String outString;
algorithm
  outString:=
  match (inMessageType)
    case (SYNTAX()) then "SYNTAX";
    case (GRAMMAR()) then "GRAMMAR";
    case (TRANSLATION()) then "TRANSLATION";
    case (SYMBOLIC()) then "SYMBOLIC";
    case (SIMULATION()) then "SIMULATION";
    case (SCRIPTING()) then "SCRIPTING";
  end match;
end messageTypeStr;

protected function severityStr "function: severityStr

  Converts a Severity to a string.
"
  input Severity inSeverity;
  output String outString;
algorithm
  outString:=
  match (inSeverity)
    case (ERROR()) then "Error";
    case (WARNING()) then "Warning";
    case (NOTIFICATION()) then "Notification";
  end match;
end severityStr;

protected function selectString "function selectString
  author: adrpo, 2006-02-05
  selects first string is bool is true otherwise the second string
"
  input Boolean inBoolean1;
  input String inString2;
  input String inString3;
  output String outString;
algorithm
  outString:=
  matchcontinue (inBoolean1,inString2,inString3)
    local String s1,s2;
    case (true,s1,_) then s1;
    case (false,_,s2) then s2;
  end matchcontinue;
end selectString;

public function infoStr
  "Converts an Absyn.Info into a string ready to be used in error messages.
  Format is [filename:line start:column start-line end:column end]"
  input Absyn.Info info;
  output String str;
algorithm
  str := match(info)
    local 
      String filename, info_str;
      Integer line_start, line_end, col_start, col_end;
    case (Absyn.INFO(fileName = filename, lineNumberStart = line_start, 
        columnNumberStart = col_start, lineNumberEnd = line_end, columnNumberEnd = col_end))
        equation
          info_str = "[" +& filename +& ":" +& 
                     intString(line_start) +& ":" +& intString(col_start) +& "-" +& 
                     intString(line_end) +& ":" +& intString(col_end) +& "]";
      then info_str;
  end match;
end infoStr;

protected function fixFilenameForTestsuite
"Updates the filename if it is used within the testsuite.
This ensures that error messages use the same filename for
everyone running the testsuite."
  input String filename;
  output String outFilename;
algorithm
  outFilename := matchcontinue filename
    case "" then ""; // Absyn.dummyInfo
    case filename
      equation
        true = RTOpts.getRunningTestsuite();
      then System.basename(filename);
    case filename then filename;
  end matchcontinue;
end fixFilenameForTestsuite;

public function assertion
"Used to make compiler-internal assertions. These messages are not meant
to be shown to a user, but rather to show internal error messages."
  input Boolean b;
  input String message;
  input Absyn.Info info;
algorithm
  _ := match (b,message,info)
    case (true,_,_) then ();
    else
      equation
        addSourceMessage(INTERNAL_ERROR, {message}, info);
      then fail();
  end match;
end assertion;

public function assertionOrAddSourceMessage
"Used to make assertions. These messages are meant to be shown to a user when
the condition is true. If the Error-level of the message is Error, this function
fails."
  input Boolean inCond;
  input ErrorID inErrorID;
  input MessageTokens inMessageTokens;
  input Absyn.Info inInfo;
algorithm
  _ := match (inCond, inErrorID, inMessageTokens, inInfo)
    case (true,_,_,_) then ();
    else
      equation
        addSourceMessage(inErrorID, inMessageTokens, inInfo);
        failure((_,ERROR(),_) = lookupMessage(inErrorID));
      then ();
  end match;
end assertionOrAddSourceMessage;

public function addCompilerWarning
"Used to make a compiler warning "
  input String message;
algorithm
  _ := match (message)
    case (message)
      equation
        addMessage(COMPILER_WARNING, {message});
      then 
        ();
  end match;
end addCompilerWarning;

end Error;
