package Error "
This file is part of OpenModelica.

Copyright (c) 1998-2005, Link�pings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

 Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

 Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

 Neither the name of Link�pings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

  
  file:	 Error.rml
  module:      Error
  description: Error handling
 
  RCS: $Id$
 
  This file contains the Error handling for the Compiler.
   
"

public 
uniontype Severity "severity of message"
  record ERROR "Error when tool can not succed in translation" end ERROR;

  record WARNING "Warning when tool succeds but with warning" end WARNING;

  record NOTIFICATION "Additional information to user, e.g. what
				     actions tool has taken to succed in translation" end NOTIFICATION;

end Severity;

public 
uniontype MessageType
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
type ErrorID = Integer "runtime scripting /interpretation error" ;

public 
type MessageTokens = list<String> "Unique error id. Used to 
			  look up message string and type and severity" ;

public import OpenModelica.Compiler.Absyn "\"Tokens\" to insert into message at 
				    positions identified by 
				    - %s for string 
				    - %l for line no.
				    - %c for col. no.
				" ;

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

public constant ErrorID FUNCTION_COMPS_MUST_HAVE_DIRECTION=77;

public constant ErrorID FUNCTION_SLOT_ALLREADY_FILLED=78;

public constant ErrorID NO_SUCH_ARGUMENT=79;

public constant ErrorID CONSTANT_OR_PARAM_WITH_NONCONST_BINDING=80;

public constant ErrorID SUBSCRIPT_NOT_INT_OR_INT_ARRAY=81;

public constant ErrorID TYPE_MISMATCH_IF_EXP=82;

public constant ErrorID UNRESOLVABLE_TYPE=83;

public constant ErrorID INCOMPATIBLE_TYPES=84;

public constant ErrorID ERROR_OPENING_FILE=85;

public constant ErrorID INHERIT_BASIC_WITH_COMPS=86;

public constant ErrorID MODIFIER_TYPE_MISMATCH_ERROR=87;

public constant ErrorID ERROR_FLATTENING=88;

public constant ErrorID DUPLICATE_ELEMENTS_NOT_IDENTICAL=89;

public constant ErrorID PACKAGE_VARIABLE_NOT_CONSTANT=90;

public constant ErrorID RECURSIVE_DEFINITION= 91; 
 
public constant ErrorID NOT_ARRAY_TYPE_IN_FOR_STATEMENT= 92;

public constant ErrorID UNBOUND_PARAMETER_WARNING=500;

public constant ErrorID BUILTIN_FUNCTION_SUM_HAS_SCALAR_PARAMETER=501;

public constant ErrorID INDEX_REDUCTION_NOTIFICATION=1000;

protected constant list<tuple<Integer, MessageType, Severity, String>> errorTable={(SYNTAX_ERROR,SYNTAX(),ERROR(),"Syntax error near: %s"),
          (GRAMMATIC_ERROR,GRAMMAR(),ERROR(),"error: %s"),
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
          "Class %s not found in OPENMODELICALIBRARY"),
          (WRITING_FILE_ERROR,SCRIPTING(),ERROR(),
          "Error writing to file %s."),
          (SIMULATOR_BUILD_ERROR,TRANSLATION(),ERROR(),
          "Error building simulator. Buildlog: %s"),
          (DIMENSION_NOT_KNOWN,TRANSLATION(),ERROR(),
          "Dimensions must be parameter or constant expression (in %s)."),
          (UNBOUND_VALUE,TRANSLATION(),ERROR(),
          "Variable %s has no bound value."),
          (NEGATIVE_SQRT,TRANSLATION(),ERROR(),
          "Error, negative value as argument to sqrt."),
          (NO_CONSTANT_BINDING,TRANSLATION(),ERROR(),
          "No constant binding for variable %s in scope %s."),
          (TYPE_NOT_FROM_PREDEFINED,TRANSLATION(),ERROR(),
          "In class %s, class restriction 'type' can only be derived from predefined types."),
          (EQUATION_IN_RECORD,TRANSLATION(),ERROR(),
          "In class %s, equations not allowed in records"),
          (EQUATION_IN_CONNECTOR,TRANSLATION(),ERROR(),
          "In class %s, equations not allowed in connectors"),
          (UNKNOWN_EXTERNAL_LANGUAGE,TRANSLATION(),ERROR(),
          "Unknown external language %s in external function declaration"),
          (DIFFERENT_NO_EQUATION_IF_BRANCHES,TRANSLATION(),ERROR(),
          "Different number of equations in the branches of the if equation: %s"),
          (UNSUPPORTED_LANGUAGE_FEATURE,TRANSLATION(),ERROR(),
          "The language feature %s is not supported. Suggested workaroung: %s"),
          (UNDERDET_EQN_SYSTEM,SYMBOLIC(),ERROR(),
          "Too few equations, underdetermined system. The model has %s variables and %s equations"),
          (OVERDET_EQN_SYSTEM,SYMBOLIC(),ERROR(),
          "Too many equations, overdetermined system. The model has %s variables and %s equations"),
          (STRUCT_SINGULAR_SYSTEM,SYMBOLIC(),ERROR(),
          "Model is structurally singular, error found sorting equations %s for variables %s"),
          (NON_EXISTING_DERIVATIVE,SYMBOLIC(),ERROR(),
          "Derivative of expression %s is non-existent"),
          (NO_CLASSES_LOADED,TRANSLATION(),ERROR(),
          "No classes are loaded."),
          (INST_PARTIAL_CLASS,TRANSLATION(),ERROR(),
          "Illegal to instantiate partial class %s"),
          (REDECLARE_CLASS_AS_VAR,TRANSLATION(),ERROR(),
          "Trying to redeclare the class %s as a variable"),
          (REDECLARE_NON_REPLACEABLE,TRANSLATION(),ERROR(),
          "Trying to redeclare class %s but class not declared as repleacable"),
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
          (INVALID_CONNECTOR_VARIABLE,TRANSLATION(),ERROR(),
          "The type of variables %s (%s) are inconsistent in connect equations"),
          (TYPE_ERROR,TRANSLATION(),ERROR(),
          "Wrong type on %s, expected %s"),
          (MODIFY_PROTECTED,TRANSLATION(),ERROR(),
          "Trying to modify protected element %s"),
          (INVALID_TUPLE_CONTENT,TRANSLATION(),ERROR(),
          "Tuple %s  must contain component references only"),
          (IMPORT_PACKAGES_ONLY,TRANSLATION(),ERROR(),
          "%s is not a package, imports is only allowed for packages."),
          (IMPORT_SEVERAL_NAMES,TRANSLATION(),ERROR(),
          "%s found in several unqualified import statements."),
          (LOOKUP_TYPE_FOUND_COMP,TRANSLATION(),ERROR(),
          "Found a component with same name when looking for type %s"),
          (LOOKUP_ENCAPSULATED_RESTRICTION_VIOLATION,TRANSLATION(),
          ERROR(),"Lookup is restricted to encapsulated elements only, violated in %s"),
          (REFERENCE_PROTECTED,TRANSLATION(),ERROR(),
          "Referencing protected element %s is not allowed"),
          (ILLEGAL_SLICE_MOD,TRANSLATION(),ERROR(),
          "Illegal slice modification %s"),
          (ILLEGAL_MODIFICATION,TRANSLATION(),ERROR(),
          "Illegal modification %s (of %s)"),(INTERNAL_ERROR,TRANSLATION(),ERROR(),"Internal error %s"),
          (TYPE_MISMATCH_ARRAY_EXP,TRANSLATION(),ERROR(),
          "Type mismatch in array expression. %s is of type %s while the elements %s are of type %s"),
          (TYPE_MISMATCH_MATRIX_EXP,TRANSLATION(),ERROR(),
          "Type mismatch in matrix rows. %s is a row of %s, the rest of the matrix is of type %s"),
          (MATRIX_EXP_ROW_SIZE,TRANSLATION(),ERROR(),
          "Incompatible row length in matrix expression. %s is a row of size %s, the rest of the matrix rows are of size %s"),
          (OPERAND_BUILTIN_TYPE,TRANSLATION(),ERROR(),
          "Operand of %s must be builtin-type in %s"),
          (WRONG_TYPE_OR_NO_OF_ARGS,TRANSLATION(),ERROR(),
          "Wrong type or wrong number of arguments to %s"),
          (DIFFERENT_DIM_SIZE_IN_ARGUMENTS,TRANSLATION(),ERROR(),
          "Different dimension sizes in arguments to %s"),
          (DER_APPLIED_TO_CONST,TRANSLATION(),ERROR(),
          "der operator applied to constant expression"),
          (ARGUMENT_MUST_BE_INTEGER_OR_REAL,TRANSLATION(),ERROR(),
          "%s argument to %s must be Integer or Real expression"),
          (ARGUMENT_MUST_BE_INTEGER,TRANSLATION(),ERROR(),
          "%s argument to %s must be Integer expression"),
          (ARGUMENT_MUST_BE_DISCRETE_VAR,TRANSLATION(),ERROR(),
          "%s argument to %s must be discrete variable"),
          (TYPE_MUST_BE_SIMPLE,TRANSLATION(),ERROR(),
          "Type in %s must be simple type"),
          (ARGUMENT_MUST_BE_VARIABLE,TRANSLATION(),ERROR(),
          "%s argument to %s must be a variable"),
          (NO_MATCHING_FUNCTION_FOUND,TRANSLATION(),ERROR(),
          "No matching function found for %s, candidates are %s"),
          (FUNCTION_COMPS_MUST_HAVE_DIRECTION,TRANSLATION(),ERROR(),
          "Component %s in function is neither input nor output"),
          (FUNCTION_SLOT_ALLREADY_FILLED,TRANSLATION(),ERROR(),
          "Slot %s allready filled"),
          (NO_SUCH_ARGUMENT,TRANSLATION(),ERROR(),
          "No such argument %s"),
          (CONSTANT_OR_PARAM_WITH_NONCONST_BINDING,TRANSLATION(),
          ERROR(),"%s is a constant or parameter with a non-constant initializer %s"),
          (SUBSCRIPT_NOT_INT_OR_INT_ARRAY,TRANSLATION(),ERROR(),
          "Subscript is not an integer or integer array in %s whis is of type %s"),
          (TYPE_MISMATCH_IF_EXP,TRANSLATION(),ERROR(),
          "Type mismatch in if-expression, true branch: %s has type %s,  false branch: %s has type %s"),
          (UNRESOLVABLE_TYPE,TRANSLATION(),ERROR(),
          "Cannot resolve type of expression %s"),
          (INCOMPATIBLE_TYPES,TRANSLATION(),ERROR(),
          "Incompatible argument types to operation %s, left type: %s, right type: %s"),
          (ERROR_OPENING_FILE,TRANSLATION(),ERROR(),
          "Error opening file %s"),
          (INHERIT_BASIC_WITH_COMPS,TRANSLATION(),ERROR(),
          "Class %s inherits primary type but has components"),
          (MODIFIER_TYPE_MISMATCH_ERROR,TRANSLATION(),ERROR(),
          "Type mismatch in modifier, expected type %s, got modifier %s of type %s"),
          (ERROR_FLATTENING,TRANSLATION(),ERROR(),
          "Error occured while flattening model %s"),
		      (NOT_ARRAY_TYPE_IN_FOR_STATEMENT, TRANSLATION(), ERROR(),
		      "Expression %s in for-statement must be an array type"),    
          (DUPLICATE_ELEMENTS_NOT_IDENTICAL,TRANSLATION(),ERROR(),
          "Error duplicate elements (due to inherited elements) not identical, first element is: %s, second element is: %s"),
          (PACKAGE_VARIABLE_NOT_CONSTANT, TRANSLATION(),ERROR(),"Variable %s in package %s is not constant"),
          (RECURSIVE_DEFINITION,TRANSLATION(),ERROR(),"Class %s has a recursive definition, i.e. contains an instance of itself"),
          (UNBOUND_PARAMETER_WARNING,TRANSLATION(),WARNING(),
          "Warning, parameter %s has no value"),
          (BUILTIN_FUNCTION_SUM_HAS_SCALAR_PARAMETER,TRANSLATION(),WARNING(),
          "Warning, function \"sum\" has scalar as argument in sum(%s)"),
          (INDEX_REDUCTION_NOTIFICATION,SYMBOLIC(),NOTIFICATION(),
          "Notification, differentiated equation %s to %s for index reduction")};

protected import OpenModelica.Compiler.ErrorExt "Errors
WARNING		
Notification" ;
 
protected import OpenModelica.Compiler.Util;

protected import OpenModelica.Compiler.Print;

public function addMessage "Implementation of Relations
  function: addMessage
 
  Adds a message given ID and tokens. The rest of the info
  is looked up in the message table.
"
  input ErrorID inErrorID;
  input MessageTokens inMessageTokens;
algorithm 
  _:=
  matchcontinue (inErrorID,inMessageTokens)
    local
      MessageType msg_type;
      Severity severity;
      String msg,msg_type_str,severity_string,id_str;
      ErrorID error_id;
      MessageTokens tokens;
    case (error_id,tokens)
      equation 
        (msg_type,severity,msg) = lookupMessage(error_id);
        msg_type_str = messageTypeStr(msg_type);
        severity_string = severityStr(severity);
        ErrorExt.addMessage(error_id, msg_type_str, severity_string, msg, tokens);
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

public function addSourceMessage "function: addSourceMessage
 
  Adds a message given ID, tokens and source file info.
  The rest of the info is looked up in the message table.
"
  input ErrorID inErrorID;
  input MessageTokens inMessageTokens;
  input Absyn.Info inInfo;
algorithm 
  _:=
  matchcontinue (inErrorID,inMessageTokens,inInfo)
    local
      MessageType msg_type;
      Severity severity;
      String msg,msg_type_str,severity_string,file,id_str;
      ErrorID error_id,sline,scol,eline,ecol;
      MessageTokens tokens;
      Boolean isReadOnly;
      Absyn.Info sinfo;
    case (error_id,tokens,Absyn.INFO(fileName = file,isReadOnly = isReadOnly,lineNumberStart = sline,columnNumberStart = scol,lineNumberEnd = eline,columnNumberEnd = ecol))
      equation 
        (msg_type,severity,msg) = lookupMessage(error_id);
        msg_type_str = messageTypeStr(msg_type);
        severity_string = severityStr(severity);
        ErrorExt.addSourceMessage(error_id, msg_type_str, severity_string, sline, scol, 
          eline, ecol, isReadOnly, file, msg, tokens);
      then
        ();
    case (error_id,tokens,sinfo)
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

public function printMessagesStr "Relations for pretty printing.
  function: printMessagesStr
 
  Prints messages to a string.
"
  output String res;
algorithm 
  res := ErrorExt.printMessagesStr();
end printMessagesStr;

public function printMessagesStrLst "function: print_messages_str
 
  Returns all messages as a list of strings, one for each message.
"
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue ()
    case () then {"Not impl. yet"}; 
  end matchcontinue;
end printMessagesStrLst;

public function printMessagesStrLstType "function: printMessagesStrLstType
 
   Returns all messages as a list of strings, one for each message.
   Filters out messages of certain type.
"
  input MessageType inMessageType;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inMessageType)
    case (_) then {"Not impl. yet"}; 
  end matchcontinue;
end printMessagesStrLstType;

public function printMessagesStrLstSeverity "function: printMessagesStrLstSeverity
  
   Returns all messages as a list of strings, one for each message.
  Filters out messages of certain severity
"
  input Severity inSeverity;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inSeverity)
    case (_) then {"Not impl. yet"}; 
  end matchcontinue;
end printMessagesStrLstSeverity;

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
  input ErrorID inErrorID;
  output MessageType outMessageType;
  output Severity outSeverity;
  output String outString;
algorithm 
  (outMessageType,outSeverity,outString):=
  matchcontinue (inErrorID)
    local
      MessageType msg_tp;
      Severity severity;
      String msg;
      ErrorID error_id;
    case (error_id)
      equation 
        (msg_tp,severity,msg) = lookupMessage2(errorTable, error_id);
      then
        (msg_tp,severity,msg);
  end matchcontinue;
end lookupMessage;

protected function lookupMessage2
  input list<tuple<ErrorID, MessageType, Severity, String>> inTplErrorIDMessageTypeSeverityStringLst;
  input ErrorID inErrorID;
  output MessageType outMessageType;
  output Severity outSeverity;
  output String outString;
algorithm 
  (outMessageType,outSeverity,outString):=
  matchcontinue (inTplErrorIDMessageTypeSeverityStringLst,inErrorID)
    local
      ErrorID id1,id2,id;
      MessageType msg_type;
      Severity severity;
      String msg;
      list<tuple<ErrorID, MessageType, Severity, String>> rest;
    case (((id1,msg_type,severity,msg) :: _),id2)
      equation 
        equality(id1 = id2);
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
  matchcontinue (inMessageType)
    case (SYNTAX()) then "SYNTAX"; 
    case (GRAMMAR()) then "GRAMMAR"; 
    case (TRANSLATION()) then "TRANSLATION"; 
    case (SYMBOLIC()) then "SYMBOLIC"; 
    case (SIMULATION()) then "SIMULATION"; 
    case (SCRIPTING()) then "SCRIPTING"; 
  end matchcontinue;
end messageTypeStr;

protected function severityStr "function: severityStr
 
  Converts a Severity to a string.
"
  input Severity inSeverity;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inSeverity)
    case (ERROR()) then "ERROR"; 
    case (WARNING()) then "WARNING"; 
    case (NOTIFICATION()) then "NOTIFICATION"; 
  end matchcontinue;
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

protected function infoStr "function: infoStr
 
  Converts a Absyn.Info to a string.
  adrpo changed 2006-02-05 to match the new Absyn.INFO specification
  
"
  input Absyn.Info inInfo;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inInfo)
    local
      String s1,sline_str,scol_str,eline_str,ecol_str,res,filename;
      Boolean isReadOnly;
      ErrorID sline,scol,eline,ecol;
    case (Absyn.INFO(fileName = filename,isReadOnly = isReadOnly,lineNumberStart = sline,columnNumberStart = scol,lineNumberEnd = eline,columnNumberEnd = ecol))
      equation 
        s1 = selectString(isReadOnly, "readonly", "writable");
        sline_str = intString(sline);
        scol_str = intString(scol);
        eline_str = intString(eline);
        ecol_str = intString(ecol);
        res = Util.stringAppendList(
          {"{",filename,", ",s1,",",sline_str,", ",scol_str,", ",
          eline_str,", ",ecol_str,"}"});
      then
        res;
  end matchcontinue;
end infoStr;
end Error;

