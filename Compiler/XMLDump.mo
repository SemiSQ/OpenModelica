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
 *
 *
 * For any request about the implementation of this package,
 * please contact Filippo Donida (donida@elet.polimi.it).
 *
 */


/////////////////////////////////////////////////////////////////
// Important discrete states are not recognised as states. //////
// The varKind shoud be varVariability and another method  //////
// and also the relative structure for the variable should //////
// be implemented to output the information like: state,   //////
// dummy der, dummy state,...                              //////
/////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////
// With a delaration like:                          ///
// parameter Real a = 1;                            ///
// the bindValue Optional value of the DAELow.VAR   ///
// record is everytime empty.  Why?                 ///
///////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////
// In order to compile the XMLDump module (XMLDump.mo package)   ///
// XMLDump.mo text in the Compiler/Makefile.common file (SRCMO   ///
// variable) has been added.                                     ///
////////////////////////////////////////////////////////////////////

/*
Probably it's better to put a link to the corresponging
algorithm/variable/when/zeroCross/...
One solution could be to add an attribute like: Algorithm_Number
to the algorith tab, like:
<ALGORITHM LABEL=algorithm_Number>
and then when dumping the algorithm reference in this function put
the corresponding tag:
<ANCHOR id=algorithm_Number/>
within the equation element.
*/


package XMLDump
" file:         XMLDump.mo
  package:     XMLDump
  description: Dumping of DAE as XML

  RCS: $Id$"

public import Absyn;
public import DAE;
public import DAEEXT;
public import DAELow;
public import Values;
public import SCode;
public import RTOpts;

protected import Algorithm;
protected import DAEUtil;
protected import Dump;
protected import Exp;
protected import ModUtil;
protected import Print;
protected import Util;
protected import DAEDump;
protected import ValuesUtil;


  protected constant String HEADER        = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
  protected constant String DAE_OPEN      = "dae xmlns:p1=\"http://www.w3.org/1998/Math/MathML\"
                                                xmlns:xlink=\"http://www.w3.org/1999/xlink\"
                                                xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
                                                xsi:noNamespaceSchemaLocation=\"http://home.dei.polimi.it/donida/Projects/AutoEdit/Images/DAE.xsd\"";
  protected constant String DAE_CLOSE      = "dae";

  protected constant String LABEL          = "label";
  protected constant String ANCHOR         = "anchor";
  protected constant String ALGORITHM_NAME = "algorithmName";

  /*
  This String is used in:
    1 - dunmAbsynPathList - function to print a list of paths:
        <ELEMENT>
          Content
        </ELEMENT>
        <ELEMENT>
          ...
    2 - dumpCrefIdxLst to print a list of DAELow.CrefIndex:
        <ELEMENT ID=...>CrefIndex</ELEMENT>
        ...
    3 - dumpStrLst to print a list of String
        <ELEMENT>FirstStringOfList</ELEMENT>
        ...
        <ELEMENT>LastStringOfList</ELEMENT>
    4 - dumpStringIdxLst2 to dump a list of StringIndex:
        <ELEMENT ID=...>StringIndex</ELEMENT>
  */
  protected constant String ELEMENT  = "element";
  protected constant String ELEMENT_ = "Element";


  protected constant String INDEX = "index";

  protected constant String LIST_ = "List";

  //Is the Dimension attribute of a list element.
  protected constant String DIMENSION              = "dimension";
  //Is the reference attribute for an element.
  protected constant String ID                     = "id";
  protected constant String ID_                    = "Id";

  //This is the String attribute for the textual representation of the expressions.
  protected constant String EXP_STRING               = "string";

  //This constant is used when is necessary to bind equations, variables, whenequations,..
  protected constant String INVOLVED = "involved";

  protected constant String ADDITIONAL_INFO = "additionalInfo";
  protected constant String SOLVING_INFO    = "solvingInfo";

  //This is the name that identifies the Variables' block. It's also used to compose the other
  //Variables' names, such as KnownVariables, OrderedVariables, and so on.
  protected constant String VARIABLES  = "variables";
  protected constant String VARIABLES_ = "Variables";

  protected constant String ORDERED  = "ordered";
  protected constant String KNOWN    = "known";
  protected constant String EXTERNAL = "external";
  protected constant String CLASSES  = "classes";
  protected constant String CLASSES_ = "Classes";

  protected constant String CLASS   = "class";
  protected constant String CLASS_  = "Class";
  protected constant String NAMES_  = "Names";

  //This is used all the time a variable is referenced.
  protected constant String VARIABLE = "variable";

  protected constant String VAR_ID       = ID;
  protected constant String VAR_NAME     = "name";
  protected constant String VAR_INDEX    = INDEX;
  protected constant String VAR_ORIGNAME = "origName";

  protected constant String STATE_SELECT_NEVER   = "Never";
  protected constant String STATE_SELECT_AVOID   = "Avoid";
  protected constant String STATE_SELECT_DEFAULT = "Default";
  protected constant String STATE_SELECT_PREFER  = "Prefer";
  protected constant String STATE_SELECT_ALWAYS  = "Always";

  protected constant String VAR_FLOW              = "flow";
  protected constant String VAR_FLOW_FLOW         = "Flow";
  protected constant String VAR_FLOW_NONFLOW      = "NonFlow";
  protected constant String VAR_FLOW_NONCONNECTOR = "NonConnector";

  protected constant String VAR_STREAM                     = "stream";
  protected constant String VAR_STREAM_STREAM              = "Stream";
  protected constant String VAR_STREAM_NONSTREAM           = "NonStream";
  protected constant String VAR_STREAM_NONSTREAM_CONNECTOR = "NonStreamConnector";

  ///  TO CORRECT WITHIN THE OMC!!!  ///
  // The variability is related to the
  // possible values a variable can assume
  // In this case also information for the
  // variable are stored. For example it would be useful
  // to print the information about state, dummyState, dummyDer separately.

  //In addition to this there's a problem with the discrete states,
  //since they aren't recognised as states.
  protected constant String VAR_VARIABILITY = "variability";

  protected constant String VARIABILITY_CONTINUOUS            = "continuous";
  protected constant String VARIABILITY_CONTINUOUS_STATE      = "continuousState";
  protected constant String VARIABILITY_CONTINUOUS_DUMMYDER   = "continuousDummyDer";
  protected constant String VARIABILITY_CONTINUOUS_DUMMYSTATE = "continuousDummyState";
  protected constant String VARIABILITY_DISCRETE              = "discrete";
  protected constant String VARIABILITY_PARAMETER             = "parameter";
  protected constant String VARIABILITY_CONSTANT              = "constant";
  protected constant String VARIABILITY_EXTERNALOBJECT        = "externalObject";

  protected constant String VAR_TYPE                    = "type";
  protected constant String VARTYPE_INTEGER             = "Integer";
  protected constant String VARTYPE_REAL                = "Real";
  protected constant String VARTYPE_STRING              = "String";
  protected constant String VARTYPE_BOOLEAN             = "Boolean";
  protected constant String VARTYPE_ENUM                = "Enum";
  protected constant String VARTYPE_ENUMERATION         = "enumeration";
  protected constant String VARTYPE_EXTERNALOBJECT      = "ExternalObject";

  protected constant String VAR_DIRECTION         = "direction";
  protected constant String VARDIR_INPUT          = "input";
  protected constant String VARDIR_OUTPUT         = "output";
  protected constant String VARDIR_NONE           = "none";

  protected constant String VAR_FIXED             = "fixed";
  protected constant String VAR_COMMENT           = "comment";

  protected constant String VAR_ATTRIBUTES_VALUES = "attributesValues";
  protected constant String VAR_ATTR_QUANTITY     = "quantity";
  protected constant String VAR_ATTR_UNIT         = "unit";
  protected constant String VAR_ATTR_DISPLAY_UNIT = "displayUnit";
  protected constant String VAR_ATTR_STATESELECT  = "stateSelect";
  protected constant String VAR_ATTR_MINVALUE     = "minValue";
  protected constant String VAR_ATTR_MAXVALUE     = "maxValue";
  protected constant String VAR_ATTR_NOMINAL      = "nominal";
  protected constant String VAR_ATTR_INITIALVALUE = "initialValue";
  protected constant String VAR_ATTR_FIXED        = "fixed";

  //Name of the element containing the binding information
  //for the variables (both expression (BindExpression) and value (BindValue).
  //For example consider:
  //parameter Real a = 3*2+e; //With Real constant e = 3;
  //BindExpression 3*2+e
  //BindValue = 9
  protected constant String BIND_VALUE_EXPRESSION   = "bindValueExpression";
  protected constant String BIND_EXPRESSION         = "bindExpression";
  protected constant String BIND_VALUE              = "bindValue";

  //Name of the element representing the subscript, for example the array's index.
  protected constant String SUBSCRIPT               = "subScript";

  //Additional info for variables.
  protected constant String HASH_TB_CREFS_LIST          = "hashTb";
  protected constant String HASH_TB_STRING_LIST_OLDVARS = "hashTbOldVars";

  //All this constants below are used in the dumpDAELow method.
  protected constant String EQUATIONS          = "equations";
  protected constant String EQUATIONS_         = "Equations";
  protected constant String SIMPLE             = "simple";
  protected constant String INITIAL            = "initial";
  protected constant String ZERO_CROSSING      = "zeroCrossing";
  protected constant String ARRAY_OF_EQUATIONS = "arrayOfEquations";//This is used also in the dumpEquation method.

  protected constant String EQUATION  = "equation";
  protected constant String EQUATION_ = "Equation";
  protected constant String SOLVED    = "solved";
  protected constant String SOLVED_   = "Solved";
  protected constant String WHEN      = "when";
  protected constant String WHEN_     = "When";
  protected constant String RESIDUAL  = "residual";
  protected constant String RESIDUAL_ = "Residual";

  /*
  This String constant is used in:
    1 - dumpAlgorithms to print out the list of Algorithms:
        <ALGORITHM LABEL=Algorithm_ID>
          ...
        </ALGORITHM>
    2 - dumpEquation if the equation element is an algorithm:
        <ALGORITHM ID=...>
          <AlgorithmID>...</AlgorithmID>
          <ANCHOR ALGORITHM_NAME=Algorithm_No></ANCHOR>
        </ALGORITHM>
  */
  protected constant String ALGORITHM              = "algorithm";
  /*
  This String constant is used to print the reference to the
  corresponding algorithm.
  */
  protected constant String ALGORITHM_REF          = "algorithm_ref";

  /*
  This String constant represents the single equation of an array of
  equations and it is used in:
    1 - dumpArrayEqns to print the list of equations
    2 - dumpEquation to print the list of equations corresponding to
        the array
  */
  protected constant String ARRAY_EQUATION         = "arrayEquation";

  protected constant String ALGORITHMS              = "algorithms";
  protected constant String FUNCTIONS               = "functions";
  protected constant String FUNCTION                = "function";
  protected constant String FUNCTION_NAME           = "name";
  protected constant String FUNCTION_ORIGNAME       = VAR_ORIGNAME;
  protected constant String NAME_BINDINGS           = "nameBindings";
  protected constant String C_NAME                  = "cName";
  protected constant String C_IMPLEMENTATIONS       = "cImplementations";
  protected constant String MODELICA_IMPLEMENTATION = "ModelicaImplementation";


  /*This strings here below are used for printing additionalInfo
  concerning the DAE system of equations, such as:
   - the original incidence matrix (before performing matching and BLT
   - the matching algorithm output
   - the blocks obtained after running the BLT algorithm (Tarjan)
   */
  protected constant String MATCHING_ALGORITHM        = "matchingAlgorithm";
  protected constant String SOLVED_IN                 = "solvedIn";
  protected constant String BLT_REPRESENTATION        = "bltRepresentation";
  protected constant String BLT_BLOCK                 = "bltBlock";
  protected constant String ORIGINAL_INCIDENCE_MATRIX = "originalIncidenceMatrix";


  protected constant String MATH                   = "math";
  protected constant String MathML                 = "MathML";
  protected constant String MathMLApply            = "apply";
  protected constant String MathMLWeb              = "http://www.w3.org/1998/Math/MathML";
  protected constant String MathMLXmlns            = "xmlns";
  protected constant String MathMLType             = "type";
  protected constant String MathMLNumber           = "cn";
  protected constant String MathMLVariable         = "ci";
  protected constant String MathMLConstant         = "constant";
  protected constant String MathMLInteger          = "integer";
  protected constant String MathMLReal             = "real";
  protected constant String MathMLVector           = "vector";
  protected constant String MathMLMatrixrow        = "matrixrow";
  protected constant String MathMLMatrix           = "matrix";
  protected constant String MathMLTrue             = "true";
  protected constant String MathMLFalse            = "false";
  protected constant String MathMLAnd              = "and";
  protected constant String MathMLOr               = "or";
  protected constant String MathMLNot              = "not";
  protected constant String MathMLEqual            = "eq";
  protected constant String MathMLLessThan         = "lt";
  protected constant String MathMLLessEqualThan    = "leq";
  protected constant String MathMLGreaterThan      = "gt";
  protected constant String MathMLGreaterEqualThan = "geq";
  protected constant String MathMLEquivalent       = "equivalent";
  protected constant String MathMLNotEqual         = "neq";
  protected constant String MathMLPlus             = "plus";
  protected constant String MathMLMinus            = "minus";
  protected constant String MathMLTimes            = "times";
  protected constant String MathMLDivide           = "divide";
  protected constant String MathMLPower            = "power";
  protected constant String MathMLTranspose        = "transpose";
  protected constant String MathMLScalarproduct    = "scalarproduct";
  protected constant String MathMLVectorproduct    = "vectorproduct";
  protected constant String MathMLInterval         = "interval";
  protected constant String MathMLSelector         = "selector";

  protected constant String MathMLIfClause         = "piecewise";
  protected constant String MathMLIfBranch         = "piece";
  protected constant String MathMLElseBranch       = "otherwise";

  protected constant String MathMLOperator         = "mo";
  protected constant String MathMLArccos           = "arccos";
  protected constant String MathMLArcsin           = "arcsin";
  protected constant String MathMLArctan           = "arctan";
  protected constant String MathMLLn               = "ln";
  protected constant String MathMLLog              = "log";


public function binopSymbol "
function: binopSymbol
  Return a string representation of the Operator
  corresponding to the MathML encode.
"
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString:=
  matchcontinue (inOperator)
    local
      DAE.Ident s;
      DAE.Operator op;
    case op
      equation
        s = binopSymbol2(op);
      then
        s;
  end matchcontinue;
end binopSymbol;


public function binopSymbol2 "
Helper function to binopSymbol
"
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString:=
  matchcontinue (inOperator)
    case (DAE.ADD(ty = _)) then MathMLPlus;
    case (DAE.SUB(ty = _)) then MathMLMinus;
    case (DAE.MUL(ty = _)) then MathMLTimes;
    case (DAE.DIV(ty = _)) then MathMLDivide;
    case (DAE.POW(ty = _)) then MathMLPower;
    case (DAE.ADD_ARR(ty = _)) then MathMLPlus;
    case (DAE.SUB_ARR(ty = _)) then MathMLMinus;
    case (DAE.MUL_SCALAR_ARRAY(ty = _)) then MathMLTimes;
    case (DAE.MUL_ARRAY_SCALAR(ty = _)) then MathMLTimes;
    case (DAE.MUL_SCALAR_PRODUCT(ty = _)) then MathMLScalarproduct;
    case (DAE.MUL_MATRIX_PRODUCT(ty = _)) then MathMLVectorproduct;
    case (DAE.DIV_ARRAY_SCALAR(ty = _)) then MathMLDivide;
  end matchcontinue;
end binopSymbol2;


public function dumpAbsynPathLst "
This function prints a list od Absyn.Path using
an XML representation. If the list of element is empty
the the methods doesn't print nothing, otherwise, depending
on the value of the second input (the String content) prints:
<Content>
  ...//List of paths
</Content>
"
  input list<Absyn.Path> absynPathLst;
  input String Content;
algorithm
  _ := matchcontinue (absynPathLst,Content)
    case ({},_)
      then();
    case (absynPathLst,Content)
      local Integer len;
      equation
        len = listLength(absynPathLst);
        len >= 1 = false;
      then ();
    case (absynPathLst,Content)
      local Integer len;
      equation
        len = listLength(absynPathLst);
        len >= 1 = true;
        dumpStrOpenTag(Content);
        dumpAbsynPathLst2(absynPathLst);
        dumpStrCloseTag(Content);
      then();
  end matchcontinue;
end dumpAbsynPathLst;


protected function dumpAbsynPathLst2 "
This is an helper function to the dunmAbsynPathList
method.
"
  input list<Absyn.Path> absynPathLst;
algorithm
  _:= matchcontinue (absynPathLst)
        local
          list<Absyn.Path> apLst;
          Absyn.Path ap;
          String str;
      case {} then ();
      case (ap :: apLst)
      equation
        str=Absyn.pathString(ap);
        dumpStrTagContent(ELEMENT,str);
        dumpAbsynPathLst2(apLst);
      then();
    end matchcontinue;
end dumpAbsynPathLst2;


public function dumpAlgorithms "
This function dumps the list of DAE.Algorithm
within using a XML format. If at least one Algorithm
is present the output is:
<ALGORITHMS DIMENSION=...>
  ...
</ALGORITHMS>
"
  input list<DAE.Algorithm> algs;
algorithm
  _:= matchcontinue(algs)
    case {} then ();
    case algs
      local Integer len;
      equation
        len = listLength(algs);
        len >= 1 = false;
    then();
    case algs
      local Integer len;
      equation
        len = listLength(algs);
        len >= 1 = true;
        dumpStrOpenTagAttr(ALGORITHMS,DIMENSION,intString(len));
        dumpAlgorithms2(algs,0);
        dumpStrCloseTag(ALGORITHMS);
    then();
  end matchcontinue;
end dumpAlgorithms;


public function dumpAlgorithms2 "
This function dumps a list of DAE.Algorithm in
XML format. The output is something like:
<ALGORITHM LABEL=Algorithm_ID>
  ...
</ALGORITHM>
<ALGORITHM LABEL=Algorithm_ID+1>
  ...
</ALGORITHM>
  ...
"
  input list<DAE.Algorithm> algs;
  input Integer inAlgNo;
algorithm
  _ := matchcontinue(algs,inAlgNo)
    local
      list<Algorithm.Statement> stmts;
      Integer algNo;
    case({},_) then ();
    case(DAE.ALGORITHM_STMTS(stmts)::algs,algNo)
      local Integer algNo_1;
      equation
        dumpStrOpenTagAttr(ALGORITHM, LABEL, stringAppend(stringAppend(ALGORITHM_REF,"_"),intString(algNo)));
        Print.printBuf(DAEDump.dumpAlgorithmsStr({DAE.ALGORITHM(DAE.ALGORITHM_STMTS(stmts),DAE.emptyElementSource)}));
        dumpStrCloseTag(ALGORITHM);
        algNo_1=algNo+1;
        dumpAlgorithms2(algs,algNo_1);
    then ();
  end matchcontinue;
end dumpAlgorithms2;


public function dumpArrayEqns "
This function dumps an array of Equation using an XML format.
It takes as input the list of MultiDimEquation and a String
for the content.
If the list is empty then is doesn't print anything, otherwise
the output is like:
<Content Dimesion=...>
  ...
</Content>
"
  input list<DAELow.MultiDimEquation> inMultiDimEquationLst;
  input String inContent;
  input DAE.Exp addMathMLCode;
  input DAE.Exp dumpResiduals;
algorithm
  _:=
  matchcontinue (inMultiDimEquationLst,inContent,addMathMLCode,dumpResiduals)
    case ({},_,_,_) then ();
    case (inMultiDimEquationLst,inContent,_,_)
      local Integer len;
      equation
        len = listLength(inMultiDimEquationLst);
        len >= 1 = false;
      then();
    case (inMultiDimEquationLst,inContent,addMathMLCode,dumpResiduals)
      local Integer len;
      equation
        len = listLength(inMultiDimEquationLst);
        len >= 1 = true;
        dumpStrOpenTagAttr(inContent, DIMENSION, intString(len));
        dumpArrayEqns2(inMultiDimEquationLst,addMathMLCode,dumpResiduals);
        dumpStrCloseTag(inContent);
      then ();
  end matchcontinue;
end dumpArrayEqns;


protected function dumpArrayEqns2 "
This is the help function of the dumpArrayEquns function.
It takes the list of MultiDimEquation and print out the
list in a XML format.
The output, if the list is not empty is something like this:
<ARRAY_EQUATION String=Exp.printExpStr(firstEquation)>
  <MathML>
    <MATH>
      ...
    </MATH>
  </MathML>
</ARRAY_EQUATION>
...
<ARRAY_EQUATION String=Exp.printExpStr(lastEquation)>
  <MathML>
    <MATH>
      ...
    </MATH>
  </MathML>
</ARRAY_EQUATION>
"
  input list<DAELow.MultiDimEquation> inMultiDimEquationLst;
  input DAE.Exp addMathMLCode;
  input DAE.Exp dumpResiduals;
algorithm
  _:=
  matchcontinue (inMultiDimEquationLst,addMathMLCode,dumpResiduals)
    local
      String s1,s2,s;
      DAE.Exp e1,e2;
      list<DAELow.MultiDimEquation> es;
    case ({},_,_) then ();
    case ((DAELow.MULTIDIM_EQUATION(left = e1,right = e2) :: es),DAE.BCONST(bool=true),DAE.BCONST(bool=false))
      equation
        s1 = Exp.printExpStr(e1);
        s2 = Exp.printExpStr(e2);
        s1 = Util.xmlEscape(s1);
        s2 = Util.xmlEscape(s2);
        s = Util.stringAppendList({s1," = ",s2,"\n"});
        dumpStrOpenTagAttr(ARRAY_EQUATION, EXP_STRING, s);
        dumpStrOpenTag(MathML);
        dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLEquivalent);
        dumpExp2(e1);
        dumpExp2(e2);
        dumpStrCloseTag(MathMLApply);
        dumpStrCloseTag(MATH);
        dumpStrCloseTag(MathML);
        dumpStrCloseTag(ARRAY_EQUATION);
        dumpArrayEqns2(es,DAE.BCONST(true),DAE.BCONST(false));
      then ();
    case ((DAELow.MULTIDIM_EQUATION(left = e1,right = e2) :: es),DAE.BCONST(bool=false),DAE.BCONST(false))
      equation
        s1 = Exp.printExpStr(e1);
        s2 = Exp.printExpStr(e2);
        s1 = Util.xmlEscape(s1);
        s2 = Util.xmlEscape(s2);
        s = Util.stringAppendList({s1," = ",s2,"\n"});
        dumpStrOpenTagAttr(ARRAY_EQUATION, EXP_STRING, s);
        dumpStrCloseTag(ARRAY_EQUATION);
        dumpArrayEqns2(es,DAE.BCONST(false),DAE.BCONST(false));
      then ();
    case ((DAELow.MULTIDIM_EQUATION(left = e1,right = e2) :: es),DAE.BCONST(bool=true),DAE.BCONST(bool=true))
      equation
        s1 = Exp.printExpStr(e1);
        s2 = Exp.printExpStr(e2);
        s1 = Util.xmlEscape(s1);
        s2 = Util.xmlEscape(s2);
        s = Util.stringAppendList({s1," - (",s2,") = 0\n"});
        dumpStrOpenTagAttr(ARRAY_EQUATION, EXP_STRING, s);
        dumpStrOpenTag(MathML);
        dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLEquivalent);
        dumpStrOpenTag(MathMLApply);
        dumpStrOpenTag(MathMLMinus);
        dumpExp2(e1);
        dumpExp2(e2);
        dumpStrCloseTag(MathMLApply);
        dumpExp2(DAE.RCONST(0.0));
        dumpStrCloseTag(MathMLApply);
        dumpStrCloseTag(MATH);
        dumpStrCloseTag(MathML);
        dumpStrCloseTag(ARRAY_EQUATION);
        dumpArrayEqns2(es,DAE.BCONST(true),DAE.BCONST(true));
      then ();
    case ((DAELow.MULTIDIM_EQUATION(left = e1,right = e2) :: es),DAE.BCONST(bool=false),DAE.BCONST(true))
      equation
        s1 = Exp.printExpStr(e1);
        s2 = Exp.printExpStr(e2);
        s1 = Util.xmlEscape(s1);
        s2 = Util.xmlEscape(s2);
        s = Util.stringAppendList({s1," - (",s2,") = 0\n"});
        dumpStrOpenTagAttr(ARRAY_EQUATION, EXP_STRING, s);
        dumpStrCloseTag(ARRAY_EQUATION);
        dumpArrayEqns2(es,DAE.BCONST(false),DAE.BCONST(true));
      then ();
  end matchcontinue;
end dumpArrayEqns2;


public function dumpBltInvolvedEquations "
This function dumps the equation ID for each block of the BLT
using an xml representation:
<involvedEquation equationId=\"\"/>
...
"
  input list<DAELow.Value> inList;
algorithm
  _:=
  matchcontinue(inList)
      local
        DAELow.Value el;
        list<DAELow.Value> remList;
    case {} then ();
    case(el :: remList)
      equation
        dumpStrTagAttrNoChild(stringAppend(INVOLVED,EQUATION_), stringAppend(EQUATION,ID_), intString(el));
        dumpBltInvolvedEquations(remList);
      then();
  end matchcontinue;
end dumpBltInvolvedEquations;

public function dumpBindValueExpression "
This function is necessary for printing the
BindValue and BindExpression of a variable,
if present. If there are not DAE.Exp nor
Values.Value passed as input nothing is
printed.
"
  input Option<DAE.Exp> inOptExpExp;
  input Option<Values.Value> inOptValuesValue;
  input DAE.Exp addMathMLCode;

  algorithm
    _:=
  matchcontinue (inOptExpExp,inOptValuesValue,addMathMLCode)
      local
        DAE.Exp e;
        Values.Value b;
        DAE.Exp addMMLCode;
  case(NONE,NONE,_)
    equation
    then();
  case(SOME(e),NONE,addMMLCode)
    equation
      dumpStrOpenTag(BIND_VALUE_EXPRESSION);
      dumpOptExp(inOptExpExp,BIND_EXPRESSION,addMMLCode);
      dumpStrCloseTag(BIND_VALUE_EXPRESSION);
    then();
  case(NONE,SOME(b),addMMLCode)
    equation
      dumpStrOpenTag(BIND_VALUE_EXPRESSION);
      dumpOptValue(inOptValuesValue,BIND_VALUE,addMMLCode);
      dumpStrCloseTag(BIND_VALUE_EXPRESSION);
    then();
  case(SOME(e),SOME(b),addMMLCode)
    equation
      dumpStrOpenTag(BIND_VALUE_EXPRESSION);
      dumpOptExp(inOptExpExp,BIND_EXPRESSION,addMMLCode);
      dumpOptValue(inOptValuesValue,BIND_VALUE,addMMLCode);
      dumpStrCloseTag(BIND_VALUE_EXPRESSION);
    then();
  case(_,_,_)
    then ();
  end matchcontinue;
end dumpBindValueExpression;


public function dumpComment "
Function for adding comments using the XML tag.
"
  input String inComment;
algorithm
  Print.printBuf("<!--");
  Print.printBuf(Util.xmlEscape(inComment));
  Print.printBuf("-->");
end dumpComment;


public function dumpComponents "
function: dumpComponents
This function is used to print BLT information using xml format.
The output is something like:
<bltBlock id=\"\">
  <InvolvedEquation equationID=\"\"/>
  ....
</bltBlock>
"
  input list<list<Integer>> l;
algorithm
  _:=
  matchcontinue(l)
    case(l)
      equation
        listLength(l) >=1 = false;
        then();
    case(l)
      equation
        listLength(l)>=1 = true;
        dumpStrOpenTag(BLT_REPRESENTATION);
        dumpComponents2(l, 1);
        dumpStrCloseTag(BLT_REPRESENTATION);
        then();
  end matchcontinue;
end dumpComponents;


protected function dumpComponents2 "
function: dumpComponents2
  Helper function to dump_components.
"
  input list<list<Integer>> inIntegerLstLst;
  input Integer inInteger;
algorithm
  _:=
  matchcontinue (inIntegerLstLst,inInteger)
    local
      DAELow.Value ni,i_1,i;
      list<String> ls;
      String s;
      list<DAELow.Value> l;
      list<list<DAELow.Value>> lst;
    case ({},_) then ();
    case ((l :: lst),i)
      equation
        ni = DAEEXT.getLowLink(i);
        dumpStrOpenTagAttr(BLT_BLOCK, ID, intString(i));
        dumpBltInvolvedEquations(l);
        dumpStrCloseTag(BLT_BLOCK);
        i_1 = i + 1;
        dumpComponents2(lst, i_1);
      then
        ();
  end matchcontinue;
end dumpComponents2;


public function dumpCrefIdxLstArr "
This function prints a list from a list
of array of CrefIndex elements in
a XML format. See dumpCrefIdxLst for details.
"
  input array<list<DAELow.CrefIndex>> crefIdxLstArr;
  input String Content;
  input Integer inInteger;
algorithm
  _:=
  matchcontinue (crefIdxLstArr,Content,inInteger)
    local
    case (crefIdxLstArr,Content,inInteger)
      equation
        listLength(crefIdxLstArr[inInteger]) >= 1  = true;
        dumpCrefIdxLst(crefIdxLstArr[inInteger],Content);
      then ();
    case (crefIdxLstArr,Content,inInteger)
      equation
        listLength(crefIdxLstArr[inInteger]) >= 1  = false;
      then ();
  end matchcontinue;
end dumpCrefIdxLstArr;


public function dumpCrefIdxLst "
This function prints a list of CrefIndex elements
in a XML format. It also takes as input a String
for having information about the Content of the elements.
The output is like:
<Content>
  ...//CrefIdxList
<Content>
See dumpCrefIdxLst2 for details.
"
  input list<DAELow.CrefIndex> crefIdxLst;
  input String Content;
algorithm
  _ := matchcontinue (crefIdxLst,Content)
   local Integer len;
    case ({},_)
      then ();
    case (crefIdxLst,Content)
      equation
        len = listLength(crefIdxLst);
        len >= 1 = false;
      then ();
    case (crefIdxLst,Content)
      equation
        len = listLength(crefIdxLst);
        len >= 1 = true;
        dumpStrOpenTag(Content);
        dumpCrefIdxLst2(crefIdxLst);
        dumpStrCloseTag(Content);
      then();
  end matchcontinue;
end dumpCrefIdxLst;


protected function dumpCrefIdxLst2 "
This function prints a list of CrefIndex adding
information of the index of the element in the list
and using an XML format like:
<ELEMENT ID=...>CrefIndex</ELEMENT>
"
  input list<DAELow.CrefIndex> crefIdxLst;
algorithm
  _:=
  matchcontinue (crefIdxLst)
      local
        list<DAELow.CrefIndex> crefIndexList;
        DAELow.CrefIndex crefIndex;
        Integer index_c;
        DAE.ComponentRef cref_c;
        String cref;
      case {}  then ();
      case ((crefIndex as DAELow.CREFINDEX(cref=cref_c,index=index_c)) :: crefIndexList)
      equation
        cref=Exp.crefStr(cref_c);
        dumpStrOpenTagAttr(ELEMENT,ID,intString(index_c));
        Print.printBuf(cref);
        dumpStrCloseTag(ELEMENT);
        dumpCrefIdxLst2(crefIndexList);
      then ();
  end matchcontinue;
end dumpCrefIdxLst2;


public function dumpDAEInstDims "
This function prints a DAE.InstDims (a list of DAE.Subscript)
using an XML format. The input variables are the list of
DAE.Subscript and a String that store information about the
content of the list. The output could be something like:
<Content>
  ...//List of Subscript XML elements
</Content>
"
  input DAE.InstDims arry_Dim;
  input String Content;
algorithm
    _ := matchcontinue (arry_Dim,Content)
   local Integer len;
    case (arry_Dim,Content)
      equation
        len = listLength(arry_Dim);
        len >= 1 = false;
      then ();
    case (arry_Dim,Content)
      equation
        len = listLength(arry_Dim);
        len >= 1 = true;
        dumpStrOpenTag(Content);
        dumpDAEInstDims2(arry_Dim);
        dumpStrCloseTag(Content);
      then();
  end matchcontinue;
end dumpDAEInstDims;


protected function dumpDAEInstDims2 "
Help function to dumpDAEInstDims. This function here
makes the real job of printing the list of DAE.Subscripts.
The output is something like:
<Subsript>FirstSubscriptOfTheList</Subscript>
...
<Subsript>LastSubscriptOfTheList</Subscript>
See dump Subscript for details.
"
  input DAE.InstDims arry_Dim;
algorithm
  _:= matchcontinue (arry_Dim)
    local
      list<DAE.Subscript> lSub;
      DAE.Subscript sub;
  case {} then ();
  case (sub :: lSub)
  equation
    dumpStrOpenTag(SUBSCRIPT);
    dumpSubscript(sub);
    dumpStrCloseTag(SUBSCRIPT);
    dumpDAEInstDims2(lSub);
  then();
  end matchcontinue;
end dumpDAEInstDims2;


public function dumpDAELow "

  This function dumps the DAELow representaton to stdout as XML format.
  The output is like:

<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?><!DOCTYPE DAE SYSTEM \"http://home.dei.polimi.it/Projects/AutoEdit/DAE.xsd\">
<DAE>
  <VARIABLES DIMENSION=..>
    <stringAppend(ORDERED,VARIABLES_)>
      ...
    </stringAppend(ORDERED,VARIABLES_)>
    <stringAppend(KNOWN,VARIABLES_)>
      ...
    </stringAppend(KNOWN,VARIABLES_)>
    <stringAppend(EXTERNAL,VARIABLES_)>
      ...
    </stringAppend(EXTERNAL,VARIABLES_)>
    <stringAppend(EXTERNAL,CLASSES_)>
      ...
    </stringAppend(EXTERNAL,CLASSES_)>
  </VARIABLES>
  <EQUATIONS>
    ...
  </EQUATIONS>
  <stringAppend(SIMPLE,EQUATIONS_)>
    ...
  </stringAppend(SIMPLE,EQUATIONS_)>
  <stringAppend(INITIAL,EQUATIONS_)>
    ...
  </stringAppend(INITIAL,EQUATIONS_)>
  <stringAppend(ZERO_CROSSING,LIST_)>
    ...
  </stringAppend(ZERO_CROSSING,LIST_)>
  <ARRAY_OF_EQUATIONS>
    ...
  </ARRAY_OF_EQUATIONS>
</DAE>

The XML output could change depending on the content of the DAELow structure, in
particular all the elements are optional, it means that if no element is present
the relative tag is not printed.
"
  input DAELow.DAELow inDAELow;
  input list<Absyn.Path> functionNames;
  input list<DAE.Element> functions;
  input DAE.Exp addOriginalIncidenceMatrix;
  input DAE.Exp addSolvingInfo;
  input DAE.Exp addMathMLCode;
  input DAE.Exp dumpResiduals;
algorithm
  _:=
  matchcontinue (inDAELow,functionNames,functions,addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals)
    local
      list<DAELow.Var> vars,knvars,extvars;

      //Ordered Variables: state & algebraic variables.
      DAELow.Variables vars_orderedVars;
      //VARIABLES record for vars.
      list<DAELow.CrefIndex>[:] crefIdxLstArr_orderedVars;
      list<DAELow.StringIndex>[:] strIdxLstArr_orderedVars;
      DAELow.VariableArray varArr_orderedVars;
      Integer bucketSize_orderedVars;
      Integer numberOfVars_orderedVars;

      //Known Variables: constant & parameter variables.
      DAELow.Variables vars_knownVars;
      //VARIABLES record for vars.
      list<DAELow.CrefIndex>[:] crefIdxLstArr_knownVars;
      list<DAELow.StringIndex>[:] strIdxLstArr_knownVars;
      DAELow.VariableArray varArr_knownVars;
      Integer bucketSize_knownVars;
      Integer numberOfVars_knownVars;

      //External Object: external variables.
      DAELow.Variables vars_externalObject;
      //VARIABLES record for vars.
      list<DAELow.CrefIndex>[:] crefIdxLstArr_externalObject;
      list<DAELow.StringIndex>[:] strIdxLstArr_externalObject;
      DAELow.VariableArray varArr_externalObject;
      Integer bucketSize_externalObject;
      Integer numberOfVars_externalObject;

      //External Classes
      DAELow.ExternalObjectClasses extObjCls;

      DAELow.Value eqnlen;
      String eqnlen_str,s;
      list<DAELow.Equation> eqnsl,reqnsl,ieqnsl;
      list<String> ss;
      list<DAELow.MultiDimEquation> ae_lst;
      DAELow.EquationArray eqns,reqns,ieqns;
      DAELow.MultiDimEquation[:] ae;
      DAE.Algorithm[:] algs;
      list<DAELow.ZeroCrossing> zc;

      list<Absyn.Path> inFunctionNames;
      list<DAE.Element> inFunctions;

      DAE.Exp addOrInMatrix,addSolInfo,addMML,dumpRes;


    case (DAELow.DAELOW(vars_orderedVars as DAELow.VARIABLES(crefIdxLstArr=crefIdxLstArr_orderedVars,strIdxLstArr=strIdxLstArr_orderedVars,varArr=varArr_orderedVars,bucketSize=bucketSize_orderedVars,numberOfVars=numberOfVars_orderedVars),
                 vars_knownVars as DAELow.VARIABLES(crefIdxLstArr=crefIdxLstArr_knownVars,strIdxLstArr=strIdxLstArr_knownVars,varArr=varArr_knownVars,bucketSize=bucketSize_knownVars,numberOfVars=numberOfVars_knownVars),
                 vars_externalObject as DAELow.VARIABLES(crefIdxLstArr=crefIdxLstArr_externalObject,strIdxLstArr=strIdxLstArr_externalObject,varArr=varArr_externalObject,bucketSize=bucketSize_externalObject,numberOfVars=numberOfVars_externalObject),
                 _,eqns,reqns,ieqns,ae,algs,DAELow.EVENT_INFO(zeroCrossingLst = zc),extObjCls),inFunctionNames,inFunctions,addOrInMatrix,addSolInfo,addMML,dumpRes)
      equation

        vars    = DAELow.varList(vars_orderedVars);
        knvars  = DAELow.varList(vars_knownVars);
        extvars = DAELow.varList(vars_externalObject);

        Print.printBuf(HEADER);
        dumpStrOpenTag(DAE_OPEN);

        dumpStrOpenTagAttr(VARIABLES, DIMENSION, intString(listLength(vars)+listLength(knvars)+listLength(extvars)));

        //Bucket size info is no longer present.
        dumpVars(vars,crefIdxLstArr_orderedVars,strIdxLstArr_orderedVars,stringAppend(ORDERED,VARIABLES_),addMML);
        dumpVars(knvars,crefIdxLstArr_knownVars,strIdxLstArr_knownVars,stringAppend(KNOWN,VARIABLES_),addMML);
        dumpVars(extvars,crefIdxLstArr_externalObject,strIdxLstArr_externalObject,stringAppend(EXTERNAL,VARIABLES_),addMML);
        dumpExtObjCls(extObjCls,stringAppend(EXTERNAL,CLASSES_));

        dumpStrCloseTag(VARIABLES);

        eqnsl  = DAELow.equationList(eqns);
        dumpEqns(eqnsl,EQUATIONS,addMML,dumpRes);
        reqnsl = DAELow.equationList(reqns);
        dumpEqns(reqnsl,stringAppend(SIMPLE,EQUATIONS_),addMML,dumpRes);
        ieqnsl = DAELow.equationList(ieqns);
        dumpEqns(ieqnsl,stringAppend(INITIAL,EQUATIONS_),addMML,dumpRes);
        dumpZeroCrossing(zc,stringAppend(ZERO_CROSSING,LIST_),addMML);
        ae_lst = arrayList(ae);
        dumpArrayEqns(ae_lst,ARRAY_OF_EQUATIONS,addMML,dumpRes);
        dumpAlgorithms(arrayList(algs));
        dumpFunctions(inFunctionNames,inFunctions);
        dumpSolvingInfo(addOrInMatrix,addSolInfo,inDAELow);
        dumpStrCloseTag(DAE_CLOSE);
      then ();
  end matchcontinue;
end dumpDAELow;


public function dumpDAEVariableAttributes "
This function dump the attributes a variable could have,
sudh as:
 - Quantity
 - Unit
 - Unit to diplay
 - State selection
 - Min value
 - Max value
 - Nominal
 - Initial value
 - Fixed
 in a new XML element. The ouptut is like:
<Content>
 <Quantity String=...>
  <MathML>
   ...
  </MathML>
 </Quantity>
 ...
</Content>
"
  input Option<DAE.VariableAttributes> dae_var_attr;
  input String Content;
  input DAE.Exp addMathMLCode;
 algorithm
   _:= matchcontinue(dae_var_attr,Content,addMathMLCode)
     local
       tuple<Option<DAE.Exp>, Option<DAE.Exp>> min_max;
       Option<DAE.Exp> quant,unit,displayUnit;
       Option<DAE.Exp> min,max,Initial,nominal;
       Option<DAE.Exp> fixed;
       Option<DAE.StateSelect> stateSel;
       DAE.Exp addMMLCode;
       Option<DAE.Exp> equationBound;
       Option<Boolean> isProtected;
       Option<Boolean> finalPrefix;

   case (SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),NONE(),NONE(),NONE(),_,_,_)),_,_) then ();
   case (SOME(DAE.VAR_ATTR_INT(NONE(),(NONE(),NONE()),NONE(),NONE(),_,_,_)),_,_) then ();
   case (SOME(DAE.VAR_ATTR_BOOL(NONE(),NONE(),NONE(),_,_,_)),_,_) then ();
   case (SOME(DAE.VAR_ATTR_STRING(NONE(),NONE(),_,_,_)),_,_) then ();
   case (SOME(DAE.VAR_ATTR_ENUMERATION(NONE(),(NONE(),NONE()),NONE(),NONE(),_,_,_)),_,_) then ();
   case (SOME(DAE.VAR_ATTR_REAL(quant,unit,displayUnit,min_max,Initial,fixed,nominal,stateSel,
                                equationBound,isProtected,finalPrefix)),Content,addMMLCode)
      equation
        dumpStrOpenTag(Content);
        dumpOptExp(quant,VAR_ATTR_QUANTITY,addMMLCode);
        dumpOptExp(unit,VAR_ATTR_UNIT,addMMLCode);
        dumpOptExp(displayUnit,VAR_ATTR_DISPLAY_UNIT,addMMLCode);
        dumpOptionDAEStateSelect(stateSel,VAR_ATTR_STATESELECT);
        dumpOptExp(Util.tuple21(min_max),VAR_ATTR_MINVALUE,addMMLCode);
        dumpOptExp(Util.tuple22(min_max),VAR_ATTR_MAXVALUE,addMMLCode);
        dumpOptExp(nominal,VAR_ATTR_NOMINAL,addMMLCode);
        dumpOptExp(Initial,VAR_ATTR_INITIALVALUE,addMMLCode);
        dumpOptExp(fixed,VAR_ATTR_FIXED,addMMLCode);
        // adrpo: TODO! FIXME! add the new information about equationBound,isProtected,finalPrefix
        dumpStrCloseTag(Content);
      then();
    case (SOME(DAE.VAR_ATTR_INT(quant,min_max,Initial,fixed,equationBound,isProtected,finalPrefix)),Content,addMMLCode)
      equation
        dumpStrOpenTag(Content);
        dumpOptExp(quant,VAR_ATTR_QUANTITY,addMMLCode);
        dumpOptExp(Util.tuple21(min_max),VAR_ATTR_MINVALUE,addMMLCode);
        dumpOptExp(Util.tuple22(min_max),VAR_ATTR_MAXVALUE,addMMLCode);
        dumpOptExp(Initial,VAR_ATTR_INITIALVALUE,addMMLCode);
        dumpOptExp(fixed,VAR_ATTR_FIXED,addMMLCode);
        dumpStrCloseTag(Content);
      then();
    case (SOME(DAE.VAR_ATTR_BOOL(quant,Initial,fixed,equationBound,isProtected,finalPrefix)),Content,addMMLCode)
      equation
        dumpStrOpenTag(Content);
        dumpOptExp(quant,VAR_ATTR_QUANTITY,addMMLCode);
        dumpOptExp(Initial,VAR_ATTR_INITIALVALUE,addMMLCode);
        dumpOptExp(fixed,VAR_ATTR_FIXED,addMMLCode);
        dumpStrCloseTag(Content);
      then();
    case (SOME(DAE.VAR_ATTR_STRING(quant,Initial,_,_,_)),Content,addMMLCode)
      equation
        dumpStrOpenTag(Content);
        dumpOptExp(quant,VAR_ATTR_QUANTITY,addMMLCode);
        dumpOptExp(Initial,VAR_ATTR_INITIALVALUE,addMMLCode);
        dumpStrCloseTag(Content);
      then();
    case (SOME(DAE.VAR_ATTR_ENUMERATION(quant,min_max,Initial,fixed,_,_,_)),Content,addMMLCode)
      equation
        dumpStrOpenTag(Content);
        dumpOptExp(quant,VAR_ATTR_QUANTITY,addMMLCode);
        dumpOptExp(Util.tuple21(min_max),VAR_ATTR_MINVALUE,addMMLCode);
        dumpOptExp(Util.tuple22(min_max),VAR_ATTR_MAXVALUE,addMMLCode);
        dumpOptExp(Initial,VAR_ATTR_INITIALVALUE,addMMLCode);
        dumpOptExp(fixed,VAR_ATTR_FIXED,addMMLCode);
        dumpStrCloseTag(Content);
        then();
    case (NONE(),_,_) then ();
    case (_,_,_)
      equation
        dumpComment("unknown VariableAttributes");
      then ();
   end matchcontinue;
end dumpDAEVariableAttributes;


public function dumpDirectionStr "

This function dumps the varDirection of a variable:
 it could be:
 - input
 - output
"
  input DAE.VarDirection inVarDirection;
  output String outString;
algorithm
  outString:=
  matchcontinue (inVarDirection)
    case DAE.INPUT()  then VARDIR_INPUT;
    case DAE.OUTPUT() then VARDIR_OUTPUT;
    case DAE.BIDIR()  then VARDIR_NONE;
  end matchcontinue;
end dumpDirectionStr;


public function dumpEqns "

This function prints a system of equation in XML format.
The output is:
<Content DIMENSION=..>
  ...
</Content>
"
  input list<DAELow.Equation> eqns;
  input String inContent;
  input DAE.Exp addMathMLCode;
  input DAE.Exp dumpResiduals;
algorithm
  _:=
  matchcontinue (eqns,inContent,addMathMLCode,dumpResiduals)
      local DAE.Exp addMMLCode;
    case ({},_,_,_) then ();
    case (eqns,inContent,_,_)
      local Integer len;
      equation
        len = listLength(eqns);
        len >= 1 = false;
      then();
    case (eqns,inContent,addMMLCode,dumpResiduals)
      local Integer len;
      equation
        len = listLength(eqns);
        len >= 1 = true;
        dumpStrOpenTagAttr(inContent, DIMENSION, intString(len));
        dumpEqns2(eqns, 1,addMMLCode,dumpResiduals);
        dumpStrCloseTag(inContent);
      then ();
  end matchcontinue;
end dumpEqns;


protected function dumpEqns2 "
  Helper function to dumpEqns
"
  input list<DAELow.Equation> inEquationLst;
  input Integer inInteger;
  input DAE.Exp addMathMLCode;
  input DAE.Exp dumpResiduals;
algorithm
  _:=
  matchcontinue (inEquationLst,inInteger,addMathMLCode,dumpResiduals)
    local
      String es,is;
      DAELow.Value index;
      DAELow.Equation eqn;
      list<DAELow.Equation> eqns;
      DAE.Exp addMMLCode;
    case ({},_,_,_) then ();
    case ((eqn :: eqns),index,addMMLCode,DAE.BCONST(bool=false))
      equation
        dumpEquation(eqn, intString(index),addMMLCode);
        dumpEqns2(eqns, index+1,addMMLCode,DAE.BCONST(false));
      then ();
    case ((eqn :: eqns),index,addMMLCode,DAE.BCONST(bool=true))
      equation
        //dumpEquation(DAELow.equationToResidualForm(eqn), intString(index),addMMLCode);
        //This should be done as above. The problem is that the DAELow.equationToResidualForm(eqn) method
        //is not working as expected, probably due to the fact that considers only scalar right hand side
        //part of equation, i.e. it works correctly if we have something like a = b (with a and b scalar)
        //thus obtaining a -b = 0.
        //The DAELow.equationToResidualForm is not working properly when the right part of the equation is not
        //a scalar. Cosidering the following equation: x = y - z will then results in obtaining the wrong
        //residual equation x - y - z and not x - (y - z).
        //Even if I didn't debug such a method I made some test via printing the equation that confirmed
        //the problem.
        //By the way, when all doubt will be clearified the follow line:
        dumpResidual(eqn, intString(index),addMMLCode);
        //will be substituted with:
        //dumpEquation(DAELow.equationToResidualForm(eqn), intString(index),addMMLCode);
        dumpEqns2(eqns, index+1,addMMLCode,DAE.BCONST(true));
      then ();
  end matchcontinue;
end dumpEqns2;


public function dumpEquation "
This function is necessary to print an equation element.
Since in Modelica is possible to have different kind of
equations, the DAELow representation of the OMC distinguish
between:
 - normal equations
 - array equations
 - solved equations
 - when equations
 - residual equations
 - algorithm references
This function prints the content using XML representation. The
output changes according to the content of the equation.
For example, if the element is an Array of Equations:
<ArrayOfEquations ID=..>
  <ARRAY_EQUATION>
    ..
    <MathML>
     ...
   </MathML>
   <ADDITIONAL_INFO stringAppend(ARRAY_OF_EQUATIONS,ID_)=...>
     <INVOLVEDVARIABLES>
       <VARIABLE>...</VARIABLE>
       ...
       <VARIABLE>...</VARIABLE>
     </INVOLVEDVARIABLES>
   </ADDITIONAL_INFO>
  </ARRAY_EQUATION>
</ARRAY_OF_EQUATIONS>
"
  input DAELow.Equation inEquation;
  input String inIndexNumber;
  input DAE.Exp addMathMLCode;
algorithm
  _:=
  matchcontinue (inEquation,inIndexNumber,addMathMLCode)
    local
      String s1,s2,res,indx_str,is,var_str,indexS;
      DAE.Exp e1,e2,e;
      DAELow.Value indx,i;
      list<DAE.Exp> expl;
      DAE.ComponentRef cr;
      DAE.Exp addMMLCode;

    case (DAELow.EQUATION(exp = e1,scalar = e2),indexS,DAE.BCONST(bool=true))
      equation
        s1 = Exp.printExpStr(e1);
        s2 = Exp.printExpStr(e2);
        s1 = Util.xmlEscape(s1);
        s2 = Util.xmlEscape(s2);
        res = Util.stringAppendList({s1," = ",s2});
        dumpStrOpenTagAttr(EQUATION,ID,indexS);
        Print.printBuf(res);
        dumpStrOpenTag(MathML);
        dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLEquivalent);
        dumpExp2(e1);
        dumpExp2(e2);
        dumpStrCloseTag(MathMLApply);
        dumpStrCloseTag(MATH);
        dumpStrCloseTag(MathML);
        dumpStrCloseTag(EQUATION);
      then ();
    case (DAELow.EQUATION(exp = e1,scalar = e2),indexS,DAE.BCONST(bool=false))
      equation
        s1 = Exp.printExpStr(e1);
        s2 = Exp.printExpStr(e2);
        s1 = Util.xmlEscape(s1);
        s2 = Util.xmlEscape(s2);
        res = Util.stringAppendList({s1," = ",s2});
        dumpStrOpenTagAttr(EQUATION,ID,indexS);
        Print.printBuf(res);
        dumpStrCloseTag(EQUATION);
      then ();
    case (DAELow.ARRAY_EQUATION(index = indx,crefOrDerCref = expl),indexS,addMMLCode)
      equation
        dumpStrOpenTagAttr(ARRAY_OF_EQUATIONS,ID,indexS);
        dumpLstExp(expl,ARRAY_EQUATION,addMMLCode);
        dumpStrOpenTagAttr(ADDITIONAL_INFO, stringAppend(ARRAY_OF_EQUATIONS,ID_), intString(indx));
        dumpStrOpenTag(stringAppend(INVOLVED,VARIABLES_));
        dumpStrOpenTag(VARIABLE);
        var_str=Util.stringDelimitList(Util.listMap(expl,printExpStr),Util.stringAppendList({"</",VARIABLE,">\n<",VARIABLE,">"}));
        dumpStrCloseTag(VARIABLE);
        dumpStrCloseTag(stringAppend(INVOLVED,VARIABLES_));
        dumpStrCloseTag(ADDITIONAL_INFO);
        dumpStrCloseTag(ARRAY_OF_EQUATIONS);
      then ();
    case (DAELow.SOLVED_EQUATION(componentRef = cr,exp = e2),indexS,DAE.BCONST(bool=true))
      equation
        s1 = Exp.printComponentRefStr(cr);
        s2 = Exp.printExpStr(e2);
        s2 = Util.xmlEscape(s2);
        res = Util.stringAppendList({s1," := ",s2});
        dumpStrOpenTagAttr(stringAppend(SOLVED,EQUATION_),ID,indexS);
        Print.printBuf(res);
        dumpStrOpenTag(MathML);
        dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLEquivalent);
        dumpStrMathMLVariable(s1);
        dumpExp2(e2);
        dumpStrCloseTag(MathMLApply);
        dumpStrCloseTag(MATH);
        dumpStrCloseTag(MathML);
        dumpStrCloseTag(stringAppend(SOLVED,EQUATION_));
      then ();
    case (DAELow.SOLVED_EQUATION(componentRef = cr,exp = e2),indexS,DAE.BCONST(bool=false))
      equation
        s1 = Exp.printComponentRefStr(cr);
        s2 = Exp.printExpStr(e2);
        s2 = Util.stringReplaceChar(s2,">","&gt;");
        res = Util.stringAppendList({s1," := ",s2});
        dumpStrOpenTagAttr(stringAppend(SOLVED,EQUATION_),ID,indexS);
        Print.printBuf(res);
        dumpStrCloseTag(stringAppend(SOLVED,EQUATION_));
      then ();
    case (DAELow.WHEN_EQUATION(whenEquation = DAELow.WHEN_EQ(index = i,left = cr,right = e2)),indexS,DAE.BCONST(bool=true))
      equation
        s1 = Exp.printComponentRefStr(cr);
        s2 = Exp.printExpStr(e2);
        s2 = Util.xmlEscape(s2);
        is = intString(i);
        res = Util.stringAppendList({s1," := ",s2});
        dumpStrOpenTagAttr(stringAppend(WHEN,EQUATION_),ID,indexS);
        Print.printBuf(res);
        dumpStrOpenTag(MathML);
        dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLEquivalent);
        dumpStrMathMLVariable(s1);
        dumpExp2(e2);
        dumpStrCloseTag(MathMLApply);
        dumpStrCloseTag(MATH);
        dumpStrCloseTag(MathML);
        dumpStrTagContent(stringAppend(stringAppend(WHEN,EQUATION_),ID_),is);
        dumpStrCloseTag(stringAppend(WHEN,EQUATION_));
      then ();
    case (DAELow.WHEN_EQUATION(whenEquation = DAELow.WHEN_EQ(index = i,left = cr,right = e2)),indexS,DAE.BCONST(bool=false))
      equation
        s1 = Exp.printComponentRefStr(cr);
        s2 = Exp.printExpStr(e2);
        s2 = Util.xmlEscape(s2);
        is = intString(i);
        res = Util.stringAppendList({s1," := ",s2});
        dumpStrOpenTagAttr(stringAppend(WHEN,EQUATION_),ID,indexS);
        Print.printBuf(res);
        dumpStrTagContent(stringAppend(stringAppend(WHEN,EQUATION_),ID_),is);
        dumpStrCloseTag(stringAppend(WHEN,EQUATION_));
      then ();
    case (DAELow.RESIDUAL_EQUATION(exp = e),indexS,DAE.BCONST(bool=true))
      equation
        s1 = Exp.printExpStr(e);
        s1 = Util.xmlEscape(s1);
        res = Util.stringAppendList({s1," = 0"});
        dumpStrOpenTagAttr(stringAppend(RESIDUAL,EQUATION_),ID,indexS);
        Print.printBuf(res);
        dumpStrOpenTag(MathML);
        dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLEquivalent);
        dumpExp2(e);
        dumpStrMathMLNumber("0");
        dumpStrCloseTag(MathMLApply);
        dumpStrCloseTag(MATH);
        dumpStrCloseTag(MathML);
        dumpStrCloseTag(stringAppend(RESIDUAL,EQUATION_));
      then ();
    case (DAELow.RESIDUAL_EQUATION(exp = e),indexS,DAE.BCONST(bool=false))
      equation
        s1 = Exp.printExpStr(e);
        s1 = Util.xmlEscape(s1);
        res = Util.stringAppendList({s1," = 0"});
        dumpStrOpenTagAttr(stringAppend(RESIDUAL,EQUATION_),ID,indexS);
        Print.printBuf(res);
        dumpStrCloseTag(stringAppend(RESIDUAL,EQUATION_));
      then ();
    case (DAELow.ALGORITHM(index = i),indexS,_)
      equation
        is = intString(i);
        dumpStrOpenTagAttr(ALGORITHM,ID,indexS);
        dumpStrTagContent(stringAppend(ALGORITHM,ID_),is);
        dumpStrTagAttrNoChild(ANCHOR, ALGORITHM_NAME, stringAppend(stringAppend(ALGORITHM_REF,"_"),is));
        //dumpStrOpenTagAttr(ANCHOR, ALGORITHM_NAME, stringAppend(stringAppend(ALGORITHM_REF,"_"),is));
        //dumpStrCloseTag(ANCHOR);
        dumpStrCloseTag(ALGORITHM);
      then ();
  end matchcontinue;
end dumpEquation;


public function dumpExp
"function: dumpExp
  This function prints a complete expression
  as a MathML. The content is like:
  <MathML>
  <MATH xmlns=\"http://www.w3.org/1998/Math/MathML\">
  DAE.Exp
  </MATH>
  </MathML>"
  input DAE.Exp e;
  //output String s;
  input DAE.Exp addMathMLCode;
algorithm
  _:=
  matchcontinue (e,addMathMLCode)
    local
      DAE.Exp inExp;
      DAE.Exp addMMLCode;
    case(inExp,DAE.BCONST(bool=true))
      equation
        dumpStrOpenTag(MathML);
        dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
        dumpExp2(inExp);
        dumpStrCloseTag(MATH);
        dumpStrCloseTag(MathML);
      then();
    case(_,DAE.BCONST(bool=false))
      then();
    case(_,_) then();
  end matchcontinue;
end dumpExp;


public function dumpExp2
"function: dumpExp2
  Helper function to dumpExp. It can also
  be used if it's not necessary to print the headers
  (MathML and MATH tags)."
  input DAE.Exp inExp;
algorithm
  _:=
  matchcontinue (inExp)
    local
      DAE.Ident s,s_1,s_2,sym,s1,s2,s3,s4,s_3,ifstr,thenstr,elsestr,res,fs,argstr,s5,s_4,s_5,res2,str,crstr,dimstr,expstr,iterstr,id;
      DAE.Ident s1_1,s2_1,s1_2,s2_2,cs,ts,fs,cs_1,ts_1,fs_1,s3_1;
      Integer x,pri2_1,pri2,pri3,pri1,ival,i,pe1,p1,p2,pc,pt,pf,p,pstop,pstart,pstep;
      Real rval;
      DAE.ComponentRef c;
      DAE.ExpType t,ty,ty2,tp;
      DAE.Exp e1,e2,e21,e22,e,f,start,stop,step,cr,dim,exp,iterexp,cond,tb,fb;
      DAE.Operator op;
      Absyn.Path fcn;
      list<DAE.Exp> args,es;
    case (DAE.END())
    ////////////////////////////////////////////////
    //////    TO DO: ADD SUPPORT TO END     ////////
    ////////////////////////////////////////////////
      equation
        Print.printBuf("end");
      then ();
    case (DAE.ICONST(integer = x))
      equation
        dumpStrMathMLNumberAttr(intString(x),MathMLType,MathMLInteger);
      then ();
    case (DAE.RCONST(real = x))
      local Real x;
      equation
        dumpStrMathMLNumberAttr(realString(x),MathMLType,MathMLReal);
      then ();
    case (DAE.SCONST(string = s))
      equation
        dumpStrMathMLNumberAttr(s,MathMLType,MathMLConstant);
      then ();
    case (DAE.BCONST(bool = false))
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLFalse);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.BCONST(bool = true))
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLTrue);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.CREF(componentRef = c,ty = t))
      equation
        s = Exp.printComponentRefStr(c);
        dumpStrMathMLVariable(s);
      then ();
    case (e as DAE.BINARY(e1,op,e2))
      equation
        sym = binopSymbol(op);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(sym);
        dumpExp2(e1);
        dumpExp2(e2);
        dumpStrCloseTag(MathMLApply);
      then ();
     case ((e as DAE.UNARY(op,e1)))
      equation
        sym = unaryopSymbol(op);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(sym);
        dumpExp2(e1);
        dumpStrCloseTag(MathMLApply);
      then ();
   case ((e as DAE.LBINARY(e1,op,e2)))
      equation
        sym = lbinopSymbol(op);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(sym);
        dumpExp2(e1);
        dumpExp2(e2);
        dumpStrCloseTag(MathMLApply);
      then ();
   case ((e as DAE.LUNARY(op,e1)))
      equation
        sym = lunaryopSymbol(op);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(sym);
        dumpExp2(e1);
        dumpStrCloseTag(MathMLApply);
      then();
   case ((e as DAE.RELATION(e1,op,e2)))
      equation
        sym = relopSymbol(op);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(sym);
        dumpExp2(e1);
        dumpExp2(e2);
        dumpStrCloseTag(MathMLApply);
      then ();
    case ((e as DAE.IFEXP(cond,tb,fb)))
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrOpenTag(MathMLIfClause);
        dumpStrOpenTag(MathMLIfBranch);
        dumpExp2(tb);
        dumpExp2(cond);
        dumpStrCloseTag(MathMLIfBranch);
        dumpStrOpenTag(MathMLElseBranch);
        dumpExp2(fb);
        dumpStrCloseTag(MathMLElseBranch);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = args))
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag("diff");
        dumpList(args,dumpExp2);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.CALL(path = Absyn.IDENT(name = "acos"),expLst = args))
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLArccos);
        dumpList(args,dumpExp2);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.CALL(path = Absyn.IDENT(name = "asin"),expLst = args))
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLArcsin);
        dumpList(args,dumpExp2);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.CALL(path = Absyn.IDENT(name = "atan"),expLst = args))
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLArctan);
        dumpList(args,dumpExp2);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.CALL(path = Absyn.IDENT(name = "atan2"),expLst = args))
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrOpenTag(MathMLOperator);
        Print.printBuf("atan2");
        dumpStrCloseTag(MathMLOperator);
        dumpStrOpenTag(MathMLOperator);
        Print.printBuf("(");
        dumpStrCloseTag(MathMLOperator);
        dumpList(args,dumpExp2);
        dumpComment("atan2 is not a MathML element it could be possible to use arg in future");
        dumpStrOpenTag(MathMLOperator);
        Print.printBuf(")");
        dumpStrCloseTag(MathMLOperator);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.CALL(path = Absyn.IDENT(name = "log"),expLst = args))
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLLn);
        dumpList(args,dumpExp2);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.CALL(path = Absyn.IDENT(name = "log10"),expLst = args))
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLLog);
        dumpList(args,dumpExp2);
        dumpStrCloseTag(MathMLApply);
      then ();
/*
    case (DAE.CALL(path = Absyn.IDENT(name = "pre"),expLst = args))
      equation
        fs = Absyn.pathString(fcn);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag("selector");          ----THIS IS FOR ALGORITHM----
        dumpList(args,dumpExp2);
        dumpStrMathMLVariable("t-1");
        dumpStrCloseTag("apMathMLApply;
      then ();
*/
    case (DAE.CALL(path = fcn,expLst = args))
      equation
        // Add the ref to path
        fs = Absyn.pathString(fcn);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(fs);
        dumpList(args,dumpExp2);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.ARRAY(array = es,ty=tp))//Array are dumped as vector
      local DAE.ExpType tp; String s3;
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLTranspose);
        dumpStrOpenTag(MathMLApply);
        dumpStrOpenTag(MathMLVector);
        dumpList(es,dumpExp3);
        dumpStrCloseTag(MathMLVector);
        dumpStrCloseTag(MathMLApply);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.TUPLE(PR = es))//Tuple are dumped as vector
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLTranspose);
        dumpStrOpenTag(MathMLApply);
        dumpStrOpenTag(MathMLVector);
        dumpList(es,dumpExp2);
        dumpStrCloseTag(MathMLVector);
        dumpStrCloseTag(MathMLApply);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.MATRIX(scalar = es,ty=tp))
      local list<list<tuple<DAE.Exp, Boolean>>> es;
        DAE.ExpType tp; String s3;
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrOpenTag(MathMLMatrix);
        dumpStrOpenTag(MathMLMatrixrow);
        dumpListSeparator(es, dumpRow, Util.stringAppendList({"\n</",MathMLMatrixrow,">/n<",MathMLMatrixrow,">"}));
        dumpStrCloseTag(MathMLMatrixrow);
        dumpStrCloseTag(MathMLMatrix);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (e as DAE.RANGE(_,start,NONE,stop))
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrOpenTag(MathMLInterval);
        dumpExp2(start);
        dumpExp2(stop);
        dumpStrCloseTag(MathMLInterval);
        dumpStrCloseTag(MathMLApply);
      then ();
    case ((e as DAE.RANGE(_,start,SOME(step),stop)))
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrOpenTag(MathMLOperator);
        Print.printBuf("{");
        dumpStrCloseTag(MathMLOperator);
        dumpExp2(start);
        dumpStrOpenTag(MathMLOperator);
        Print.printBuf(":");
        dumpStrCloseTag(MathMLOperator);
        dumpExp2(step);
        dumpStrOpenTag(MathMLOperator);
        Print.printBuf(":");
        dumpStrCloseTag(MathMLOperator);
        dumpExp2(stop);
        dumpComment("Interval range specification is not supported by MathML standard");
        dumpStrOpenTag(MathMLOperator);
        Print.printBuf("}");
        dumpStrCloseTag(MathMLOperator);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.CAST(ty = DAE.ET_REAL(),exp = DAE.ICONST(integer = ival)))
      equation
        false = RTOpts.modelicaOutput();
        rval = intReal(ival);
        res = realString(rval);
        dumpStrMathMLNumberAttr(res,MathMLType,MathMLReal);
      then ();
    case (DAE.CAST(ty = DAE.ET_REAL(),exp = DAE.UNARY(operator = DAE.UMINUS(ty = _),exp = DAE.ICONST(integer = ival))))
      equation
        false = RTOpts.modelicaOutput();
        rval = intReal(ival);
        res = realString(rval);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLMinus);
        dumpStrMathMLNumberAttr(res,MathMLType,MathMLReal);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.CAST(ty = DAE.ET_REAL(),exp = e))
      equation
        false = RTOpts.modelicaOutput();
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLReal);
        dumpExp2(e);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.CAST(ty = DAE.ET_REAL(),exp = e))
      equation
        true = RTOpts.modelicaOutput();
        dumpExp2(e);
      then ();
    case (DAE.CAST(ty = tp,exp = e))
      equation
        str = Exp.typeString(tp);
        dumpStrOpenTag(MathMLApply);
        dumpStrOpenTag(MathMLOperator);
        Print.printBuf("(");
        dumpStrCloseTag(MathMLOperator);
        dumpStrOpenTag(MathMLOperator);
        Print.printBuf("CAST as ");Print.printBuf(str);
        dumpStrCloseTag(MathMLOperator);
        dumpExp2(e);
        dumpComment("CAST operator is not supported by MathML standard.");
        dumpStrOpenTag(MathMLOperator);
        Print.printBuf(")");
        dumpStrCloseTag(MathMLOperator);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (e as DAE.ASUB(exp = e1,sub = {e2}))
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLSelector);
        dumpExp2(e1);
        dumpExp2(e2);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.SIZE(exp = cr,sz = SOME(dim)))
      equation
        // NOT PART OF THE MODELICA LANGUAGE
      then ();
    case (DAE.SIZE(exp = cr,sz = NONE))
      equation
        // NOT PART OF THE MODELICA LANGUAGE
      then ();
    case (DAE.REDUCTION(path = fcn,expr = exp,ident = id,range = iterexp))
      equation
        // NOT PART OF THE MODELICA LANGUAGE
      then  ();
      // MetaModelica list
    case (DAE.LIST(_,es))
      local list<DAE.Exp> es;
      equation
        // NOT PART OF THE MODELICA LANGUAGE
      then ();
        // MetaModelica list cons
    case (DAE.CONS(_,e1,e2))
      equation
        // NOT PART OF THE MODELICA LANGUAGE
      then ();
    case (_)
      equation
        dumpComment("UNKNOWN EXPRESSION");
      then ();
  end matchcontinue;
end dumpExp2;


public function dumpExp3
"function: dumpExp3
  This function is an auxiliary function for dumpExp2 function.
"
  input DAE.Exp e;
  //output String s;
algorithm
  dumpStrOpenTag(MathML);
  dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
  dumpExp2(e);
  dumpStrCloseTag(MATH);
  dumpStrCloseTag(MathML);
end dumpExp3;


public function dumpExtObjCls "

Dump classes of external objects within the 'classes' attribute
of the '<stringAppend(stringAppend(EXTERNAL,CLASSES_),LIST_)/>' element.
A possible enchancement would be to print the classes as
xml Modelica classes.
"
input DAELow.ExternalObjectClasses cls;
input String Content;
algorithm
  _ := matchcontinue(cls,Content)
   local
     Integer len;
     DAELow.ExternalObjectClasses xs;
    case ({},_) then ();
    case (xs,Content)
      equation
        len = listLength(xs);
        len >= 1 = false;
      then ();
    case (xs,Content)
      equation
        len = listLength(xs);
        len >= 1 = true;
        dumpStrOpenTagAttr(stringAppend(stringAppend(EXTERNAL,CLASSES_),LIST_),DIMENSION,intString(len));
        dumpExtObjCls2(xs,stringAppend(EXTERNAL,CLASS_));
        dumpStrCloseTag(stringAppend(stringAppend(EXTERNAL,CLASSES_),LIST_));
      then ();
  end matchcontinue;
end dumpExtObjCls;


protected function dumpExtObjCls2 "

Help function to dumpExtObjClsXML. It prints
all the class element of the list in the
Content tag, like:
<Content>
model ...
end ...
</Content>
...
"
input DAELow.ExternalObjectClasses cls;
input String Content;
algorithm
  _ := matchcontinue(cls,Content)
   local
     DAELow.ExternalObjectClasses xs;
     DAE.Element constr,destr;
     Absyn.Path path;
     String c;
     DAE.ElementSource source "the origin of the element";

    case ({},_) then ();
    case (DAELow.EXTOBJCLASS(path,constr,destr,source)::xs,c)
      equation
        dumpStrOpenTag(c);
        Print.printBuf("class ");Print.printBuf(Absyn.pathString(path));Print.printBuf("\n  extends ExternalObject");
        Print.printBuf(DAEDump.dumpFunctionStr(constr));Print.printBuf("\n");
        Print.printBuf(DAEDump.dumpFunctionStr(destr));
        Print.printBuf("end");Print.printBuf(Absyn.pathString(path));
        dumpStrCloseTag(c);
        dumpExtObjCls2(xs,c);
      then ();
  end matchcontinue;
end dumpExtObjCls2;


public function dumpFlowStr "
This function returns a string with
the content of the flow type of a variable.
It could be:
 - Flow
 - NonFlow
 - NonConnector
"
  input DAE.Flow inVarFlow;
  output String outString;
algorithm
  outString:=
  matchcontinue (inVarFlow)
    case DAE.FLOW()          then VAR_FLOW_FLOW;
    case DAE.NON_FLOW()      then VAR_FLOW_NONFLOW;
    case DAE.NON_CONNECTOR() then VAR_FLOW_NONCONNECTOR;
  end matchcontinue;
end dumpFlowStr;


public function dumpFunctions "
This function dumps a list of functions
"
  input list<Absyn.Path> inFunctionNames;
  input list<DAE.Element> funcelems;
algorithm
  _:=
  matchcontinue (inFunctionNames,funcelems)
      local
        String s;
        list<Absyn.Path> names;
    case ({},_) then();
    case (names,funcelems)
      equation
        dumpStrOpenTag(FUNCTIONS);
        dumpFunctions2(inFunctionNames,funcelems);
        dumpStrCloseTag(FUNCTIONS);
  then();
  end matchcontinue;
end dumpFunctions;


public function dumpFunctions2 "
Help function for dumpFunctions
"
  input list<Absyn.Path> inFunctionNames;
  input list<DAE.Element> funcelems;
algorithm
  _:=
  matchcontinue (inFunctionNames,funcelems)
      local
        Absyn.Path name;
        DAE.Element fun;
        list<Absyn.Path> rem_names;
        list<DAE.Element> rem_fun;
    case ({},_) then();
    case (_,{}) then();
    case (name::rem_names, fun :: rem_fun)
      equation
        dumpFunctions3(name,fun);
        dumpFunctions2(rem_names,rem_fun);
  then();
  end matchcontinue;
end dumpFunctions2;


protected function dumpFunctions3 "
Help function to dumpFunctions2
"
  input Absyn.Path name;
  input DAE.Element fun;
algorithm
  _:=
  matchcontinue (name,fun)
    case(name,fun)
      equation
      Print.printBuf("\n<");Print.printBuf(FUNCTION);
      Print.printBuf(" ");Print.printBuf(FUNCTION_NAME);Print.printBuf("=\"");Print.printBuf(Absyn.pathString(name));Print.printBuf("\"");
      Print.printBuf(" ");Print.printBuf(MODELICA_IMPLEMENTATION);Print.printBuf("=\"");Print.printBuf(DAEDump.dumpFunctionStr(fun));
      Print.printBuf("\"/>");
    then();
    case (_,_) then();
/*
        dumpStrOpenTag(Function)
        dumpAttribute(name= Absyn.pathString(name));
        dumpAttribute(Modelica implementation = DAEDump.dumpFunctionStr(fun));
        dumpStrCloseTag(Function)
*/
   end matchcontinue;
end dumpFunctions3;


public function dumpFunctionNames "
This function dump the names of all the functions are passed.
The function names are printed as couples of original name
and c function name. See dumpFunctionNames2 for details.
"
  input list<Absyn.Path> libs;
algorithm
  _:=
  matchcontinue (libs)
    local
      list<Absyn.Path> s;
  case ({}) then ();
  case (s)
    equation
      dumpStrOpenTag(NAME_BINDINGS);
      dumpFunctionNames2(s);
      dumpStrCloseTag(NAME_BINDINGS);
    then();
  end matchcontinue;
end dumpFunctionNames;


protected function dumpFunctionNames2 "
Help function to dumpFunctionNames.
"
  input list<Absyn.Path> libs;
algorithm
  _:=
  matchcontinue (libs)
    local
      Absyn.Path s;
      list<Absyn.Path> remaining;
  case ({}) then ();
  case (s :: remaining)
    local
      String fn_name_str;
      String s_path;
    equation
      s_path = Absyn.pathString(s);
      fn_name_str = ModUtil.pathStringReplaceDot(s, "_");
      fn_name_str = stringAppend("_", fn_name_str);
      Print.printBuf("\n<");Print.printBuf(FUNCTION);
      Print.printBuf(" ");Print.printBuf(FUNCTION_ORIGNAME);Print.printBuf("=\"");Print.printBuf(s_path);Print.printBuf("\"");
      Print.printBuf(" ");Print.printBuf(C_NAME);Print.printBuf("=\"");Print.printBuf(fn_name_str);
      Print.printBuf("\"/>");
      dumpFunctionNames2(remaining);
    then();
  end matchcontinue;
end dumpFunctionNames2;


function dumpFunctionsStr "
This function returns the code of all the functions
that are used in the DAELow model.
The functions are printed as Modelica code.
"
  input list<DAE.Element> inL;
  output String FuncsString;
algorithm
  FuncsString :=
  matchcontinue(inL)
    local
      DAE.Element el;
      list<DAE.Element> rem;
      //case (_) then ();
      case {}  then "";
      case (el::rem)  then stringAppend(DAEDump.dumpFunctionStr(el),dumpFunctionsStr(rem));
  end matchcontinue;
end dumpFunctionsStr;



public function dumpIncidenceMatrix "
This function dumps a matrix using an xml representation.
<matrix>
     <matrixrow>
          <cn> 0 </cn>
          <cn> 1 </cn>
          <cn> 0 </cn>
     </matrixrow>
     <matrixrow>
     ...
</matrix>
"
  input DAELow.IncidenceMatrix m;
  list<list<DAELow.Value>> m_1;
algorithm
/*  _:=
  matchcontinue(m)
    case (m)
      equation
        listLength(m)>=1 = false;
    then ();
    case (m)
        local list<list<Value>> m_1;
      equation*/
        //listLength(m)>=1 = true;
        dumpStrOpenTag(MathML);
        dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
        dumpStrOpenTag(MathMLMatrix);
        m_1 := arrayList(m);
        dumpIncidenceMatrix2(m_1,1);
        dumpStrCloseTag(MathMLMatrix);
        dumpStrCloseTag(MATH);
        dumpStrCloseTag(MathML);
/*    then ();
  end matchcontinue;*/
end dumpIncidenceMatrix;


protected function dumpIncidenceMatrix2 "
Help function to dumpMatrix
"
  input list<list<Integer>> m;
  input Integer rowIndex;
algorithm
  _:=
  matchcontinue(m,rowIndex)
    local
      list<DAELow.Value> row;
      list<list<DAELow.Value>> rows;
    case ({},_) then ();
    case ((row :: rows),rowIndex)
      equation
        dumpStrOpenTag(MathMLMatrixrow);
        dumpMatrixIntegerRow(row);
        dumpStrCloseTag(MathMLMatrixrow);
        dumpIncidenceMatrix2(rows,rowIndex+1);
      then ();
  end matchcontinue;
end dumpIncidenceMatrix2;


public function dumpLibs
  input list<String> libs;
algorithm
  _:=
  matchcontinue (libs)
    local
      String s;
      list<String> remaining;
  case ({}) then ();
  case (s :: remaining)
    equation
      Print.printBuf(s);
    then();
  end matchcontinue;
end dumpLibs;


public function dumpMatrixIntegerRow "
Function to print a matrix row of integer elements
using an xml representation, as:
 <cn> integerValue </cn>
 ...
"
  input list<Integer> inIntegerLst;
algorithm
  _:=
  matchcontinue (inIntegerLst)
    local
      String s;
      DAELow.Value x;
      list<DAELow.Value> xs;
    case ({}) then ();
    case ((x :: xs))
      equation
        s = intString(x);
        dumpStrOpenTag(MathMLVariable);
        Print.printBuf(s);
        dumpStrCloseTag(MathMLVariable);
        dumpMatrixIntegerRow(xs);
      then ();
  end matchcontinue;
end dumpMatrixIntegerRow;


public function dumpKind "
This function returns a string containing
the kind of a variable, that could be:
 - Variable
 - State
 - Dummy_der
 - Dummy_state
 - Discrete
 - Parameter
 - Constant
 - ExternalObject:PathRef
"
  input DAELow.VarKind inVarKind;
  output String outString;
algorithm
  outString :=
  matchcontinue (inVarKind)
    case DAELow.VARIABLE()     then (VARIABILITY_CONTINUOUS);
    case DAELow.STATE()        then (VARIABILITY_CONTINUOUS_STATE);
    case DAELow.DUMMY_DER()    then (VARIABILITY_CONTINUOUS_DUMMYDER);
    case DAELow.DUMMY_STATE()  then (VARIABILITY_CONTINUOUS_DUMMYSTATE);
    case DAELow.DISCRETE()     then (VARIABILITY_DISCRETE);
    case DAELow.PARAM()        then (VARIABILITY_PARAMETER);
    case DAELow.CONST()        then (VARIABILITY_CONSTANT);
    case DAELow.EXTOBJ(path)
      local Absyn.Path path;
      then (stringAppend(VARIABILITY_EXTERNALOBJECT,stringAppend(":",Absyn.pathString(path))));
  end matchcontinue;
end dumpKind;


public function dumpList
"function: printList
  Print a list of values given a print
  function."
  input list<Type_a> inTypeALst;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
algorithm
  _:=
  matchcontinue (inTypeALst,inFuncTypeTypeATo)
    local
      Type_a h;
      FuncTypeType_aTo r;
      list<Type_a> t;
      DAE.Ident sep;
    case ({},_)  then ();
    case ({h},r) equation  r(h);  then  ();
    case ((h :: t),r)
      equation
        r(h);
        dumpList(t, r);
      then ();
  end matchcontinue;
end dumpList;


public function dumpListSeparator
"function: dumpListSeparator
  Print a list of values given a print
  function and a separator string."
  input list<Type_a> inTypeALst;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  input String inString;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
algorithm
  _:=
  matchcontinue (inTypeALst,inFuncTypeTypeATo,inString)
    local
      Type_a h;
      FuncTypeType_aTo r;
      list<Type_a> t;
      DAE.Ident sep;
    case ({},_,_)  then ();
    case ({h},r,_) equation  r(h);  then  ();
    case ((h :: t),r,sep)
      equation
        r(h);
        Print.printBuf(sep);
        dumpListSeparator(t, r, sep);
      then ();
  end matchcontinue;
end dumpListSeparator;


public function dumpLstExp "
This function dumps an array of Equation using an XML format.
It takes as input the list of MultiDimEquation and a String
for the content.
If the list is empty then is doesn't print anything, otherwise
the output is like:
<ContentList Dimesion=...>
  <Content>
    ...
  </Content>
  ...
</ContentList>
 "
  input list<DAE.Exp> inLstExp;
  input String inContent;
  input DAE.Exp addMathMLCode;
algorithm
  _:=
  matchcontinue (inLstExp,inContent,addMathMLCode)
    case ({},_,_) then ();
    case (inLstExp,inContent,_)
      local
        Integer len;equation
        len = listLength(inLstExp);
        len >= 1 = false;
      then();
    case (inLstExp,inContent,addMathMLCode)
      local
        Integer len;
        String Lst;
      equation
        len = listLength(inLstExp);
        len >= 1 = true;
        Lst = stringAppend(inContent,LIST_);
        dumpStrOpenTagAttr(Lst, DIMENSION, intString(len));
        dumpLstExp2(inLstExp,inContent,addMathMLCode);
        dumpStrCloseTag(Lst);
      then ();
  end matchcontinue;
end dumpLstExp;


protected function dumpLstExp2 "
This is the help function of the dumpLstExp function.
It takes the list of DAE.Exp and print out the
list in a XML format.
The output, if the list is not empty is something like this:
<ARRAY_EQUATION String=Exp.printExpStr(firstEquation)>
  <MathML>
    <MATH>
      ...
    </MATH>
  </MathML>
</ARRAY_EQUATION>
...
<ARRAY_EQUATION String=Exp.printExpStr(lastEquation)>
  <MathML>
    <MATH>
      ...
    </MATH>
  </MathML>
</ARRAY_EQUATION>
"
  input list<DAE.Exp> inLstExp;
  input String Content;
  input DAE.Exp addMathMLCode;
algorithm
  _:=
  matchcontinue (inLstExp,Content,addMathMLCode)
    local
      String s1,s2,s,inContent;
      DAE.Exp e;
      list<DAE.Exp> es;
    case ({},_,_) then ();
    case ((e :: es),inContent,addMathMLCode)
      equation
        s = Exp.printExpStr(e);
        s = Util.xmlEscape(s);
        dumpStrOpenTagAttr(inContent, EXP_STRING, s);
        dumpExp(e,addMathMLCode);
        dumpStrCloseTag(inContent);
        dumpLstExp2(es,inContent,addMathMLCode);
      then ();
  end matchcontinue;
end dumpLstExp2;


public function dumpLstInt "
function dumpLsTStr dumps a list
of Integer as a list of XML Element.
The method takes the String list and
the element name as inputs.
The output is:

<ElementName>FirstIntegerOfList</ElementName>
..
<ElementName>LastIntegerOfList</ElementName>

"
  input list<Integer> inLstStr;
  input String inElementName;
algorithm
  _:=
  matchcontinue(inLstStr,inElementName)
      local
        Integer h;
        list<Integer> t;
    case ({},_) then ();
    case ({h},"") then ();
    case ({h},inElementName)
      equation
        dumpStrTagContent(inElementName,intString(h));
    then  ();
    case ((h :: t),inElementName)
      equation
        dumpStrTagContent(inElementName,intString(h));
        dumpLstInt(t,inElementName);
    then();
  end matchcontinue;
end dumpLstInt;


public function dumpLstIntAttr "
This function, if the list is not empty, prints
the XML delimiters tag of the list.
"
  input list<Integer> lst;
  input String inContent;
  input String inElementContent;
algorithm
  _:= matchcontinue (lst,inContent,inElementContent)
  local
    list<Integer> l;
    String inLst,inEl;
    case ({},_,_) then ();
    case (l,inLst,inEl)
      equation
        dumpStrOpenTag(inLst);
        dumpLstInt(l,inEl);
        dumpStrCloseTag(inLst);
      then();
  end matchcontinue;
end dumpLstIntAttr;


public function dumpLstStr "
function dumpLsTStr dumps a list
of String as a list of XML Element.
The method takes the String list as
input. The output is:

<ELEMENT>FirstStringOfList</ELEMENT>
..
<ELEMENT>LastStringOfList</ELEMENT>

"
  input list<String> inLstStr;
algorithm
  _:=
  matchcontinue(inLstStr)
      local
        String h;
        list<String> t;
    case {} then ();
    case {h}
      equation
        dumpStrTagContent(ELEMENT,h);
    then  ();
    case (h :: t)
      equation
        dumpStrTagContent(ELEMENT,h);
        dumpLstStr(t);
    then();
  end matchcontinue;
end dumpLstStr;


public function dumpMatching
"function: dumpMatching
  author: PA
  prints the matching information on stdout."
  input Integer[:] v;
  DAELow.Value len;
  String len_str;
algorithm
   _:=
  matchcontinue(v)
  case(v)
    equation
      arrayLength(v) >= 1  = false;
    then();
  case(v)
    equation
      arrayLength(v) >= 1  = true;
      dumpStrOpenTag(MATCHING_ALGORITHM);
      dumpMatching2(v, 0);
      dumpStrCloseTag(MATCHING_ALGORITHM);
  then();
    end matchcontinue;
end dumpMatching;


protected function dumpMatching2
"function: dumpMatching2
  Helper function to dumpMatching."
  input Integer[:] inIntegerArray;
  input Integer inInteger;
algorithm
  _:=
  matchcontinue (inIntegerArray,inInteger)
    local
      DAELow.Value len,i_1,eqn,i;
      String s,s2;
      DAELow.Value[:] v;
    case (v,i)
      equation
        len = array_length(v);
        i_1 = i + 1;
        (len == i_1) = true;
        s = intString(i_1);
        eqn = v[i + 1];
        s2 = intString(eqn);
        Print.printBuf("\n<");Print.printBuf(SOLVED_IN);Print.printBuf(" ");
        Print.printBuf(stringAppend(VARIABLE,ID_));Print.printBuf("=\"");Print.printBuf(s);Print.printBuf("\" ");
        Print.printBuf(stringAppend(EQUATION,ID_));Print.printBuf("=\"");Print.printBuf(s2);Print.printBuf("\" ");
        Print.printBuf("/>");
      then
        ();
    case (v,i)
      equation
        len = array_length(v);
        i_1 = i + 1;
        (len == i_1) = false;
        s = intString(i_1);
        eqn = v[i + 1];
        s2 = intString(eqn);
        Print.printBuf("\n<");Print.printBuf(SOLVED_IN);Print.printBuf(" ");
        Print.printBuf(stringAppend(VARIABLE,ID_));Print.printBuf("=\"");Print.printBuf(s);Print.printBuf("\" ");
        Print.printBuf(stringAppend(EQUATION,ID_));Print.printBuf("=\"");Print.printBuf(s2);Print.printBuf("\" ");
        Print.printBuf("/>");
        dumpMatching2(v, i_1);
      then
        ();
  end matchcontinue;
end dumpMatching2;


public function dumpOptExp "
This function print to a new line the content of
a Optional<DAE.Exp> in a XML element like:
<Content =Exp.printExpStr(e)/>. It also print
the content of the expression as MathML like:
<MathML><MATH xmlns=...>DAE.Exp</MATH></MathML>.
See dumpExp function for more details.
"
  input Option<DAE.Exp> inExpExpOption;
  input String Content;
  input DAE.Exp addMathMLCode;
algorithm
  _:=
  matchcontinue (inExpExpOption,Content,addMathMLCode)
    local
      DAE.Exp e;
    case (NONE(),_,_) then ();
    case (SOME(e),_,addMathMLCode)
      equation
        dumpStrOpenTagAttr(Content,EXP_STRING,printExpStr(e));
        dumpExp(e,addMathMLCode);
        dumpStrCloseTag(Content);
      then ();
  end matchcontinue;
end dumpOptExp;


public function dumpOptionDAEStateSelect "
This function is used to print in a new line
an element corresponding to the StateSelection
choice of a variable. Depending from the String
input, that defines the element's name, the
element is something like:
<Content=StateSelection/>,
"
  input Option<DAE.StateSelect> ss;
  input String Content;
algorithm
  _ :=
  matchcontinue (ss,Content)
    case (NONE(),_)
      equation
        Print.printBuf("");
      then ();
    case (SOME(DAE.NEVER()),_)
      equation dumpStrTagContent(Content, STATE_SELECT_NEVER);   then ();
    case (SOME(DAE.AVOID()),_)
      equation dumpStrTagContent(Content, STATE_SELECT_AVOID);   then ();
    case (SOME(DAE.DEFAULT()),_)
      equation dumpStrTagContent(Content, STATE_SELECT_DEFAULT); then ();
    case (SOME(DAE.PREFER()),_)
      equation dumpStrTagContent(Content, STATE_SELECT_PREFER);  then ();
    case (SOME(DAE.ALWAYS()),_)
      equation dumpStrTagContent(Content, STATE_SELECT_ALWAYS);  then ();
  end matchcontinue;
end dumpOptionDAEStateSelect;


public function dumpOptValue "
 This function print an Optional Values.Value variable
as one attribute of a within a specific XML element.
It takes the optional Values.Value and element name
as input an prints on a new line a string to the
standard output like:
<Content = \"Exp.printExpStr(ValuesUtil.valueExp(Optional<Values.Value>)/>
"
  input Option<Values.Value> inValueValueOption;
  input String Content;
  input DAE.Exp addMathMLCode;
algorithm
  _ :=
  matchcontinue (inValueValueOption,Content,addMathMLCode)
    local
      Values.Value v;
      DAE.Exp addMMLCode;
    case (NONE,_,_)  then ();
    case (SOME(v),Content,addMMLCode)
      equation
        dumpStrOpenTagAttr(Content,EXP_STRING,Exp.printExpStr(ValuesUtil.valueExp(v)));
        dumpExp(ValuesUtil.valueExp(v),addMMLCode);
        dumpStrCloseTag(Content);
      then ();
  end matchcontinue;
end dumpOptValue;


public function dumpRow
"function: printRow
  Prints a list of expressions to a string."
  input list<tuple<DAE.Exp, Boolean>> es;
  list<DAE.Exp> es_1;
algorithm
  es_1 := Util.listMap(es, Util.tuple21);
  dumpList(es_1, dumpExp2);
end dumpRow;


public function dumpSolvingInfo "
  Function necessary to print additional information
  that are useful for solving a DAE system, such as:
  - matching algorithm output
  - BLT form
  This is done using a xml representation such as:
  <AdditionalInfo>
    <SolvingInfo>
      <MatchingAlgorithm>
        <SolvedIn variableID=\"\" equationID=\"\"/>
        ...
        <SolvedIn variableID=\"\" equationID=\"\"/>
      </MatchingAlgorithm>
      <BLTRepresentation>
        <Block id=\"\">
          <InvolvedEquation equationID=\"\"/>
          ....
        </Block>
        ....
      </BLTRepresentation>
    </SolvingInfo>
  </AdditionalInfo>
  "
  input DAE.Exp addOriginalIncidenceMatrix;
  input DAE.Exp addSolvingInfo;
  input DAELow.DAELow inDAELow;
algorithm
  _:=
  matchcontinue (addOriginalIncidenceMatrix,addSolvingInfo,inDAELow)
      local DAELow.DAELow dlow;
  case (DAE.BCONST(bool=false),DAE.BCONST(bool=false),_)
    equation
    then ();
  case (DAE.BCONST(bool=true),DAE.BCONST(bool=true),dlow)
    local
      list<Integer>[:] m,mT;
      Integer[:] v1,v2;
      list<list<Integer>> comps;
    equation
      m = DAELow.incidenceMatrix(dlow);
      mT = DAELow.transposeMatrix(m);
      (v1,v2,_,m,mT) = DAELow.matchingAlgorithm(dlow, m, mT,(DAELow.INDEX_REDUCTION(),DAELow.EXACT(),DAELow.REMOVE_SIMPLE_EQN()),DAEUtil.avlTreeNew());
      (comps) = DAELow.strongComponents(m, mT, v1, v2);
      //(blt_states,blt_no_states) = DAELow.generateStatePartition(comps, dlow, v1, v2, m, mt);
      dumpStrOpenTag(ADDITIONAL_INFO);
      dumpStrOpenTag(ORIGINAL_INCIDENCE_MATRIX);
      dumpIncidenceMatrix(m);
      dumpStrCloseTag(ORIGINAL_INCIDENCE_MATRIX);
      dumpStrOpenTag(SOLVING_INFO);
      dumpMatching(v1);
      dumpComponents(comps);
      dumpStrCloseTag(SOLVING_INFO);
      dumpStrCloseTag(ADDITIONAL_INFO);
    then ();
  case (DAE.BCONST(bool=true),DAE.BCONST(bool=false),dlow)
    local
      list<Integer>[:] m,mT;
      Integer[:] v1,v2;
      list<list<Integer>> comps;
    equation
      m = DAELow.incidenceMatrix(dlow);
      mT = DAELow.transposeMatrix(m);
      dumpStrOpenTag(ADDITIONAL_INFO);
      dumpStrOpenTag(ORIGINAL_INCIDENCE_MATRIX);
      dumpIncidenceMatrix(m);
      dumpStrCloseTag(ORIGINAL_INCIDENCE_MATRIX);
      dumpStrCloseTag(ADDITIONAL_INFO);
    then ();
  case (DAE.BCONST(bool=false),DAE.BCONST(bool=true),dlow)
    local
      list<Integer>[:] m,mT;
      Integer[:] v1,v2;
      list<list<Integer>> comps;
    equation
      m = DAELow.incidenceMatrix(dlow);
      mT = DAELow.transposeMatrix(m);
      (v1,v2,_,m,mT) = DAELow.matchingAlgorithm(dlow, m, mT,(DAELow.INDEX_REDUCTION(),DAELow.EXACT(),DAELow.REMOVE_SIMPLE_EQN()),DAEUtil.avlTreeNew());
      (comps) = DAELow.strongComponents(m, mT, v1, v2);
      //(blt_states,blt_no_states) = DAELow.generateStatePartition(comps, dlow, v1, v2, m, mt);
      dumpStrOpenTag(ADDITIONAL_INFO);
      dumpStrOpenTag(SOLVING_INFO);
      dumpMatching(v1);
      dumpComponents(comps);
      dumpStrCloseTag(SOLVING_INFO);
      dumpStrCloseTag(ADDITIONAL_INFO);
    then ();
  end matchcontinue;
end dumpSolvingInfo;


public function dumpStrCloseTag "
  Function necessary to print the end of an
  XML element. The XML element's name is passed as
  a parameter. The result is to print on a new line
  a string like:
  </Content>
  "
  input String inContent;
algorithm
  _:=
  matchcontinue (inContent)
      local String inString;
  case ("")
    equation
    then ();
  case (inString)
    equation
      Print.printBuf("\n</");Print.printBuf(inString);Print.printBuf(">");
    then ();
  end matchcontinue;
end dumpStrCloseTag;


public function dumpStrFunctions "
This function is used to print all the information of the functions
are used in the DAELow model.
The functions are printed using the inFunctions string containing the
body of the functions.
"
  input String inFunctions;
  input list<Absyn.Path> inFunctionNames;
algorithm
  _:=
  matchcontinue (inFunctions,inFunctionNames)
    local
      String s;
      list<Absyn.Path> names;
    case("",_)
      then();
    case (s,names)
      equation
        dumpStrOpenTag(FUNCTIONS);
        dumpFunctionNames(inFunctionNames);
        dumpStrTagContent(C_IMPLEMENTATIONS, inFunctions);
        dumpStrCloseTag(FUNCTIONS);
      then();
  end matchcontinue;
end dumpStrFunctions;


public function dumpStreamStr "
This function returns a string with
the content of the stream type of a variable.
It could be:
 - Stream
 - NonStream
 - NonStreamConnector
"
  input DAE.Stream inVarStream;
  output String outString;
algorithm
  outString:=
  matchcontinue (inVarStream)
    case DAE.STREAM()               then VAR_STREAM_STREAM;
    case DAE.NON_STREAM()           then VAR_STREAM_NONSTREAM;
    case DAE.NON_STREAM_CONNECTOR() then VAR_STREAM_NONSTREAM_CONNECTOR;
  end matchcontinue;
end dumpStreamStr;


public function dumpStringIdxLstArr "
This function prints a list from a list
of array of StringIndex elements in
a XML format. See dumpStringIdxLst for details.
"
  input list<DAELow.StringIndex>[:] stringIdxLstArr;
  input String Content;
  input Integer inInteger;
algorithm
  _:=
  matchcontinue (stringIdxLstArr,Content,inInteger)
    case (stringIdxLstArr,Content,inInteger)
      equation
        listLength(stringIdxLstArr[inInteger]) >= 1  = true;
        dumpStringIdxLst(stringIdxLstArr[inInteger],Content);
      then ();
    case (stringIdxLstArr,Content,inInteger)
      equation
        listLength(stringIdxLstArr[inInteger]) >= 1  = false;
      then ();
  end matchcontinue;
end dumpStringIdxLstArr;


public function dumpStringIdxLst "
This function prints a list of StringIndex elements
in a XML format. It also takes as input a String
for having information about the Content of the elements.
The output is like:
<StringList>
  ...
<StringList>
See dumpStringIdxLst2 for details.
"
  input list<DAELow.StringIndex> stringIdxLst;
  input String Content;
algorithm
  _ := matchcontinue (stringIdxLst,Content)
   local Integer len;
    case (stringIdxLst,Content)
      equation
        len = listLength(stringIdxLst);
        len >= 1 = false;
      then ();
    case (stringIdxLst,Content)
      equation
        len = listLength(stringIdxLst);
        len >= 1 = true;
        dumpStrOpenTag(Content);
        dumpStringIdxLst2(stringIdxLst);
        dumpStrCloseTag(Content);
      then();
  end matchcontinue;
end dumpStringIdxLst;


protected function dumpStringIdxLst2 "
This function prints a list of StringIndex adding
information of the index of the element in the list
and using an XML format like:
<ELEMENT ID=...>StringIndex</ELEMENT>
"
  input list<DAELow.StringIndex> strIdxLst;
algorithm
  _:=
  matchcontinue (strIdxLst)
      local
        list<DAELow.StringIndex> stringIndexList;
        DAELow.StringIndex stringIndex;
        String str_s;
        Integer index_s;
      case {} then ();
      case ((stringIndex as DAELow.STRINGINDEX(str=str_s,index=index_s)) :: stringIndexList)
        local Boolean ver;
      equation
        dumpStrOpenTagAttr(ELEMENT,ID,intString(index_s));
        Print.printBuf(str_s);
        dumpStrCloseTag(ELEMENT);
        dumpStringIdxLst2(stringIndexList);
      then ();
  end matchcontinue;
end dumpStringIdxLst2;


public function dumpStrMathMLNumber "
This function prints a new MathML element
containing a number, like:
<cn> inNumber </cn>
"
  input String inNumber;
algorithm
  dumpStrOpenTag(MathMLNumber);
  Print.printBuf(" ");Print.printBuf(inNumber);Print.printBuf(" ");
  dumpStrCloseTag(MathMLNumber);
end dumpStrMathMLNumber;


public function dumpStrMathMLNumberAttr "
This function prints a new MathML element
containing a number and one of its attributes,
like:
<cn inAttribute=\"inAttributeValue\"> inNumber
</cn>
"
  input String inNumber;
  input String inAttribute;
  input String inAttributeContent;
algorithm
  dumpStrOpenTagAttr(MathMLNumber, inAttribute, inAttributeContent);
  Print.printBuf(" ");Print.printBuf(inNumber);Print.printBuf(" ");
  dumpStrCloseTag(MathMLNumber);
end dumpStrMathMLNumberAttr;


public function dumpStrMathMLVariable"
This function prints a new MathML element
containing a variable (identifier), like:
<ci> inVariable </ci>
"
  input String inVariable;
algorithm
  dumpStrOpenTag(MathMLVariable);
  Print.printBuf(" ");Print.printBuf(inVariable);Print.printBuf(" ");
  dumpStrCloseTag(MathMLVariable);
end dumpStrMathMLVariable;


public function dumpStrOpenTag "
  Function necessary to print the begin of a new
  XML element. The XML element's name is passed as
  a parameter. The result is to print on a new line
  a string like:
  <Content>
  "
  input String inContent;
algorithm
  _:=
  matchcontinue (inContent)
      local String inString;
  case ("")
    equation
      Print.printBuf("");
    then ();
  case (inString)
    equation
      Print.printBuf("\n<");Print.printBuf(inString);Print.printBuf(">");
    then ();
  end matchcontinue;
end dumpStrOpenTag;


public function dumpStrOpenTagAttr "
  Function necessary to print the begin of a new
  XML element containing an attribute. The XML
  element's name, the name and the content of the
  element's attribute are passed as String inputs.
  The result is to print on a new line
  a string like:
  <Content Attribute=AttributeContent>
  "
  input String inContent;
  input String Attribute;
  input String AttributeContent;
algorithm
  _:=
  matchcontinue (inContent,Attribute,AttributeContent)
      local String inString,inAttribute,inAttributeContent;
  case ("",_,_)  equation  Print.printBuf("");  then();
  case (_,"",_)  equation  Print.printBuf("");  then();
  case (_,_,"")  equation  Print.printBuf("");  then();
  case (inString,"",_)  equation dumpStrOpenTag(inString);  then ();
  case (inString,_,"")  equation dumpStrOpenTag(inString);  then ();
  case (inString,inAttribute,inAttributeContent)
    equation
      Print.printBuf("\n<");Print.printBuf(inString);Print.printBuf(" ");Print.printBuf(Attribute);Print.printBuf("=\"");Print.printBuf(inAttributeContent);Print.printBuf("\">");
    then();
  end matchcontinue;
end dumpStrOpenTagAttr;


public function dumpStrTagAttrNoChild "
  Function necessary to print a new
  XML element containing an attribute. The XML
  element's name, the name and the content of the
  element's attribute are passed as String inputs.
  The result is to print on a new line
  a string like:
  <Content Attribute=AttributeContent>
  "
  input String inContent;
  input String Attribute;
  input String AttributeContent;
algorithm
  _:=
  matchcontinue (inContent,Attribute,AttributeContent)
      local String inString,inAttribute,inAttributeContent;
  case ("",_,_)  equation  Print.printBuf("");  then();
  case (_,"",_)  equation  Print.printBuf("");  then();
  case (_,_,"")  equation  Print.printBuf("");  then();
  case (inString,"",_)  equation dumpStrOpenTag(inString);  then ();
  case (inString,_,"")  equation dumpStrOpenTag(inString);  then ();
  case (inString,inAttribute,inAttributeContent)
    equation
      Print.printBuf("\n<");Print.printBuf(inString);Print.printBuf(" ");Print.printBuf(Attribute);Print.printBuf("=\"");Print.printBuf(inAttributeContent);Print.printBuf("\" />");
    then();
  end matchcontinue;
end dumpStrTagAttrNoChild;


public function dumpStrTagContent "
  Function necessary to print an XML element
  with a String content. The XML element's name
  and the content are passed as String inputs.
  The result is to print on a new line
  a string like:
  <inElementName>inContent</inElementName>
  "
  input String inElementName;
  input String inContent;
algorithm
  _:=
  matchcontinue (inElementName,inContent)
      local String inTagString,inTagContent;
  case ("",_)  then ();
  case (inTagString,"")  then ();
  case (inTagString,inTagContent)
    equation
      dumpStrOpenTag(inTagString);
      Print.printBuf("\n");Print.printBuf(inTagContent);
      dumpStrCloseTag(inTagString);
    then ();
  end matchcontinue;
end dumpStrTagContent;


public function dumpStrVoidTag
"
This function takes as input the name
of the void element to print and then
print on a new line an XML code like:
<ElementName/>
"
  input String inElementName;
algorithm
  _:=matchcontinue(inElementName)
  local String ElementName;
    case("") then();
    case(ElementName)
      equation
        Print.printBuf("\n<");Print.printBuf(ElementName);Print.printBuf("/>");
      then();
  end matchcontinue;
end dumpStrVoidTag;


public function dumpSubscript "
This function print an DAE.Subscript eventually
using the Exp.printExpStr function.
"
  input DAE.Subscript inSubscript;
algorithm
  _:=
  matchcontinue (inSubscript)
    local DAE.Exp e1;
    case (DAE.WHOLEDIM())
      equation
        Print.printBuf(":");
      then
        ();
    case (DAE.INDEX(exp = e1))
      equation
        Print.printBuf(Exp.printExpStr(e1));
      then
        ();
    case (DAE.SLICE(exp = e1))
      equation
        Print.printBuf(Exp.printExpStr(e1));
      then
        ();
  end matchcontinue;
end dumpSubscript;


public function dumpTypeStr "
This function output the Type of a variable, it could be:
 - Integer
 - Real
 - Boolean
 - String
 - Enum
 "
  input DAELow.Type inType;
  output String outString;
algorithm
  outString:=
  matchcontinue (inType)
    local
      DAE.Ident s1,s2,str;
      list<DAE.Ident> l;
    case DAELow.INT()    then VARTYPE_INTEGER;
    case DAELow.REAL()   then VARTYPE_REAL;
    case DAELow.BOOL()   then VARTYPE_BOOLEAN;
    case DAELow.STRING() then VARTYPE_STRING;
    case DAELow.ENUMERATION(stringLst = l)
      equation
        s1 = Util.stringDelimitList(l, ", ");
        s2 = stringAppend(VARTYPE_ENUMERATION,stringAppend("(", s1));
        str = stringAppend(s2, ")");
      then
        str;
    case DAELow.EXT_OBJECT(_) then VARTYPE_EXTERNALOBJECT;
  end matchcontinue;
end dumpTypeStr;


public function dumpVariable "
This function print to the standard output the
content of a variable. In particular it takes:
* varno: the variable number
* cr: the var name
* kind: variable, state, dummy_der, dummy_state,..
* dir: input, output or bi-directional
* var_type: builtin type or enumeration
* indx: corresponding index in the implementation vector
* old_name: the original name of the variable
* varFixed: fixed attribute for variables (default fixed
  value is used if not found. Default is true for parameters
  (and constants) and false for variables)
* flowPrefix: tells if it's a flow variable or not
* streamPrefix: tells if it's a stream variable or not
* comment: a comment associated to the variable.
Please note that all the inputs must be passed as String variables.
"
  input String varno,cr,kind,dir,var_type,indx,varFixed,flowPrefix,streamPrefix,comment;
algorithm
  _:=
  matchcontinue (varno,cr,kind,dir,var_type,indx,varFixed,flowPrefix,streamPrefix,comment)
      //local String str;
    case (varno,cr,kind,dir,var_type,indx,varFixed,flowPrefix,streamPrefix,"")
    equation
    /*
      str= Util.stringAppendList({"\n<Variable id=\"",varno,"\" name=\"",cr,"\" varKind=\"",kind,"\" varDirection=\"",dir,"\" varType=\"",var_type,"\" index=\"",indx,"\" origName=\"",
            old_name,"\" fixed=\"",varFixed,"\" flow=\"",flowPrefix,"\" stream=\"",streamPrefix,"\">"});
    then str;
    */
      Print.printBuf("\n<");Print.printBuf(VARIABLE);Print.printBuf(" ");Print.printBuf(VAR_ID);Print.printBuf("=\"");Print.printBuf(varno);
      Print.printBuf("\" ");Print.printBuf(VAR_NAME);Print.printBuf("=\"");Print.printBuf(cr);
      Print.printBuf("\" ");Print.printBuf(VAR_VARIABILITY);Print.printBuf("=\"");Print.printBuf(kind);
      Print.printBuf("\" ");Print.printBuf(VAR_DIRECTION);Print.printBuf("=\"");Print.printBuf(dir);
      Print.printBuf("\" ");Print.printBuf(VAR_TYPE);Print.printBuf("=\"");Print.printBuf(var_type);
      Print.printBuf("\" ");Print.printBuf(VAR_INDEX);Print.printBuf("=\"");Print.printBuf(indx);
      Print.printBuf("\" ");Print.printBuf(VAR_FIXED);Print.printBuf("=\"");Print.printBuf(varFixed);
      Print.printBuf("\" ");Print.printBuf(VAR_FLOW);Print.printBuf("=\"");Print.printBuf(flowPrefix);
      Print.printBuf("\" ");Print.printBuf(VAR_STREAM);Print.printBuf("=\"");Print.printBuf(streamPrefix);
      Print.printBuf("\">");
    then();
    case (varno,cr,kind,dir,var_type,indx,varFixed,flowPrefix,streamPrefix,comment)
    equation
      Print.printBuf("\n<");Print.printBuf(VARIABLE);Print.printBuf(" ");Print.printBuf(VAR_ID);Print.printBuf("=\"");Print.printBuf(varno);
      Print.printBuf("\" ");Print.printBuf(VAR_NAME);Print.printBuf("=\"");Print.printBuf(cr);
      Print.printBuf("\" ");Print.printBuf(VAR_VARIABILITY);Print.printBuf("=\"");Print.printBuf(kind);
      Print.printBuf("\" ");Print.printBuf(VAR_DIRECTION);Print.printBuf("=\"");Print.printBuf(dir);
      Print.printBuf("\" ");Print.printBuf(VAR_TYPE);Print.printBuf("=\"");Print.printBuf(var_type);
      Print.printBuf("\" ");Print.printBuf(VAR_INDEX);Print.printBuf("=\"");Print.printBuf(indx);
      Print.printBuf("\" ");Print.printBuf(VAR_FIXED);Print.printBuf("=\"");Print.printBuf(varFixed);
      Print.printBuf("\" ");Print.printBuf(VAR_FLOW);Print.printBuf("=\"");Print.printBuf(flowPrefix);
      Print.printBuf("\" ");Print.printBuf(VAR_STREAM);Print.printBuf("=\"");Print.printBuf(streamPrefix);
      Print.printBuf("\" ");Print.printBuf(VAR_COMMENT);Print.printBuf("=\"");Print.printBuf(Util.xmlEscape(comment));
      Print.printBuf("\">");
    then ();
      /*
      str= Util.stringAppendList({"\n<Variable id=\"",varno,"\" name=\"",cr,"\" varKind=\"",kind,"\" varDirection=\"",dir,"\" varType=\"",var_type,"\" index=\"",indx,"\" origName=\"",
            old_name,"\" fixed=\"",varFixed,"\" flow=\"",flowPrefix,"\"  stream=\"",streamPrefix,"\" comment=\"",comment,"\">"});
    then str;
    */
  end matchcontinue;
end dumpVariable;


public function dumpVarsAdditionalInfo "
This function dumps the additional info that a
variable could contain in a XML format.
The output is very simple and is like:
<ADDITIONAL_INFO>
  <CfresList>
    ...
  </CrefList>
  <StringList>
    ...
  </StringList>
</ADDITIONAL_INFO>
"

  input list<DAELow.CrefIndex>[:] crefIdxLstArr;
  input list<DAELow.StringIndex>[:] strIdxLstArr;
  input Integer i;
algorithm
    _ := matchcontinue (crefIdxLstArr,strIdxLstArr,i)
    case (crefIdxLstArr,strIdxLstArr,i)
      equation
        listLength(crefIdxLstArr[1]) >= 1  = false;
      then ();
    case (crefIdxLstArr,strIdxLstArr,i)
      equation
        listLength(crefIdxLstArr[1]) >= 1  = true;
        dumpStrOpenTag(ADDITIONAL_INFO);
        dumpCrefIdxLstArr(crefIdxLstArr,HASH_TB_CREFS_LIST,i);
        dumpStringIdxLstArr(strIdxLstArr,HASH_TB_STRING_LIST_OLDVARS,i);
        dumpStrCloseTag(ADDITIONAL_INFO);
      then ();
  end matchcontinue;
end dumpVarsAdditionalInfo;


public function dumpVars "
This function prints a list of Var in a XML format. If the
list is not empty (in that case nothing is printed) the output
is:
<Content DIMENSION=...>
  <VariableList>
    ...
  </VariableList>
</Content>
"
  input list<DAELow.Var> vars;
  input list<DAELow.CrefIndex>[:] crefIdxLstArr;
  input list<DAELow.StringIndex>[:] strIdxLstArr;
  input String Content;
  input DAE.Exp addMathMLCode;
algorithm
    _ := matchcontinue (vars,crefIdxLstArr,strIdxLstArr,Content,addMathMLCode)
   local Integer len;DAE.Exp addMMLCode;
    case ({},_,_,_,_)
      then();
    case (vars,crefIdxLstArr,strIdxLstArr,Content,_)
      equation
        len = listLength(vars);
        len >= 1 = false;
      then ();
    case (vars,crefIdxLstArr,strIdxLstArr,Content,addMMLCode)
      equation
        len = listLength(vars);
        len >= 1 = true;
        listLength(crefIdxLstArr[1]) >= 1  = true;
        dumpStrOpenTagAttr(Content,DIMENSION,intString(len));
        dumpStrOpenTag(stringAppend(VARIABLES,LIST_));
        dumpVarsAdds2(vars,crefIdxLstArr,strIdxLstArr,1,addMMLCode);
        dumpStrCloseTag(stringAppend(VARIABLES,LIST_));
        dumpStrCloseTag(Content);
      then();
    case (vars,_,_,Content,addMMLCode)
      equation
        len = listLength(vars);
        len >= 1 = true;
        listLength(crefIdxLstArr[1]) >= 1  = false;
        dumpStrOpenTagAttr(Content,DIMENSION,intString(len));
        dumpStrOpenTag(stringAppend(VARIABLES,LIST_));
        dumpVars2(vars,1,addMMLCode);
        dumpStrCloseTag(stringAppend(VARIABLES,LIST_));
        dumpStrCloseTag(Content);
      then ();
    case (vars,_,_,_,_)
      equation
        len = listLength(vars);
        len >= 1 = false;
    then ();
  end matchcontinue;
end dumpVars;


protected function dumpVars2 "
This function is one of the two help function to the
dumpVar method. The two help functions differ from
the number of the output. This function is used for
printing the content of a variable with no AdditionalInfo.
See dumpVariable for more details on the XML output.
"
  input list<DAELow.Var> inVarLst;
  input Integer inInteger;
  input DAE.Exp addMathMLCode;
algorithm
  _ := matchcontinue (inVarLst,inInteger,addMathMLCode)
    local
      String varnostr,dirstr,str,path_str,comment_str,s,indx_str;
      list<String> paths_lst,path_strs;
      DAELow.Value indx,varno;
      DAELow.Var v;
      DAE.ComponentRef cr,old_name;
      DAELow.VarKind kind;
      DAE.VarDirection dir;
      Option<DAE.Exp> e;
      list<Absyn.Path> paths;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<DAELow.Var> xs;
      DAELow.Type var_type;
      DAE.InstDims arry_Dim;
      Option<Values.Value> b;
      Integer var_1;
      DAE.Exp addMMLCode;
      DAE.ElementSource source "the origin of the element";

    case ({},_,_) then ();
    case (((v as DAELow.VAR(varName = cr,
                            varKind = kind,
                            varDirection = dir,
                            varType = var_type,
                            bindExp = e,
                            bindValue = b,
                            arryDim = arry_Dim,
                            index = indx,
                            source = source,
                            values = dae_var_attr,
                            comment = comment,
                            flowPrefix = flowPrefix,
                            streamPrefix = streamPrefix)) :: xs),varno,addMMLCode)
      equation
        dumpVariable(intString(varno),Exp.printComponentRefStr(cr),dumpKind(kind),dumpDirectionStr(dir),dumpTypeStr(var_type),
                     intString(indx),Util.boolString(DAELow.varFixed(v)),dumpFlowStr(flowPrefix),
                     dumpStreamStr(streamPrefix),unparseCommentOptionNoAnnotation(comment));
        dumpBindValueExpression(e,b,addMMLCode);
        //The command below adds information to the XML about the dimension of the
        //containing vector, in the casse the variable is an element of a vector.
        //dumpDAEInstDims(arry_Dim,"ArrayDims");
        paths = DAEUtil.getElementSourceTypes(source);
        dumpAbsynPathLst(paths,stringAppend(CLASSES,NAMES_));
        dumpDAEVariableAttributes(dae_var_attr,VAR_ATTRIBUTES_VALUES,addMMLCode);
        dumpStrCloseTag(VARIABLE);
        var_1=varno+1;
        dumpVars2(xs,var_1,addMMLCode);
      then ();
  end matchcontinue;
end dumpVars2;


protected function dumpVarsAdds2 "
This function is one of the two help function to the
dumpVar method. The two help functions differ from
the number of the output. This function is used for
printing the content of a variable with AdditionalInfo.
See dumpVariable for more details on the XML output.
"
  input list<DAELow.Var> inVarLst;
  input list<DAELow.CrefIndex>[:] crefIdxLstArr;
  input list<DAELow.StringIndex>[:] strIdxLstArr;
  input Integer inInteger;
  input DAE.Exp addMathMLCode;
algorithm
  _ := matchcontinue (inVarLst,crefIdxLstArr,strIdxLstArr,inInteger,addMathMLCode)
    local
      String varnostr,dirstr,str,path_str,comment_str,s,indx_str;
      list<String> paths_lst,path_strs;
      DAELow.Value indx,varno;
      DAELow.Var v;
      DAE.ComponentRef cr,old_name;
      DAELow.VarKind kind;
      DAE.VarDirection dir;
      Option<DAE.Exp> e;
      list<Absyn.Path> paths;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<DAELow.Var> xs;
      DAELow.Type var_type;
      DAE.InstDims arry_Dim;
      Option<Values.Value> b;
      Integer var_1;
      DAE.Exp addMMLCode;
      DAE.ElementSource source "the origin of the element";

    case ({},_,_,_,_) then ();
    case (((v as DAELow.VAR(varName = cr,
                            varKind = kind,
                            varDirection = dir,
                            varType = var_type,
                            bindExp = e,
                            bindValue = b,
                            arryDim = arry_Dim,
                            index = indx,
                            source = source,
                            values = dae_var_attr,
                            comment = comment,
                            flowPrefix = flowPrefix,
                            streamPrefix = streamPrefix)) :: xs),crefIdxLstArr,strIdxLstArr,varno,addMMLCode)
      equation
        dumpVariable(intString(varno),Exp.printComponentRefStr(cr),dumpKind(kind),dumpDirectionStr(dir),dumpTypeStr(var_type),intString(indx),
                        Util.boolString(DAELow.varFixed(v)),dumpFlowStr(flowPrefix),dumpStreamStr(streamPrefix),
                        DAEDump.dumpCommentOptionStr(comment));
        dumpBindValueExpression(e,b,addMMLCode);
        //The command below adds information to the XML about the dimension of the
        //containing vector, in the casse the variable is an element of a vector.
        //dumpDAEInstDims(arry_Dim,"ArrayDims");
        paths = DAEUtil.getElementSourceTypes(source);
        dumpAbsynPathLst(paths,stringAppend(CLASSES,NAMES_));
        dumpDAEVariableAttributes(dae_var_attr,VAR_ATTRIBUTES_VALUES,addMMLCode);
        dumpVarsAdditionalInfo(crefIdxLstArr,strIdxLstArr,varno);
        dumpStrCloseTag(VARIABLE);
        var_1 = varno+1;
        dumpVarsAdds2(xs,crefIdxLstArr,strIdxLstArr,var_1,addMMLCode);
      then ();
  end matchcontinue;
end dumpVarsAdds2;


public function dumpZeroCrossing "
This function prints the list of ZeroCrossing
elements in a XML format. It takes also as input
a string in order to know what is the content of
the zero crossing list. The output is:
<ZeroCrossings DIMENSION=...>
...
</ZeroCrossings>
"
  input list<DAELow.ZeroCrossing> zeroCross;
  input String inContent;
  input DAE.Exp addMathMLCode;
algorithm
  _:=
  matchcontinue (zeroCross,inContent,addMathMLCode)
    case ({},_,_) then ();
    case (zeroCross,inContent,_)
      local Integer len;
      equation
        len = listLength(zeroCross);
        len >= 1 = false;
      then();
    case (zeroCross,inContent,addMathMLCode)
      local Integer len;
      equation
        len = listLength(zeroCross);
        len >= 1 = true;
        dumpStrOpenTagAttr(inContent, DIMENSION, intString(len));
        dumpZcLst(zeroCross,addMathMLCode);
        dumpStrCloseTag(inContent);
      then ();
  end matchcontinue;
end dumpZeroCrossing;


protected function dumpZcLst "
This function prints the content of a ZeroCrossing list
of elements, including the information regarding the origin
of the zero crossing elements in XML format. The output is:
<stringAppend(ZERO_CROSSING,ELEMENT_) EXP_STRING=DAE.Exp>
  <MathML>
    <MATH>
      ...
    </MATH>
  </MathML>
  <stringAppend(INVOLVED,EQUATIONS_)>
    <stringAppend(EQUATION,ID_)>FirstEquationNo</stringAppend(EQUATION,ID_)>
    ...
    <stringAppend(EQUATION,ID_)>LastEquationNo</stringAppend(EQUATION,ID_)>
  </stringAppend(INVOLVED,EQUATIONS_)>
  <stringAppend(INVOLVED,stringAppend(WHEN_,EQUATIONS_))>
    <stringAppend(stringAppend(WHEN,EQUATION_),ID_)>FirstWhenEquationNo</stringAppend(stringAppend(WHEN,EQUATION_),ID_)>
    ...
    <stringAppend(stringAppend(WHEN,EQUATION_),ID_)>LastWhenEquationNo</stringAppend(stringAppend(WHEN,EQUATION_),ID_)>
  </stringAppend(INVOLVED,stringAppend(WHEN_,EQUATIONS_))>
</stringAppend(ZERO_CROSSING,ELEMENT_)>
 "
  input list<DAELow.ZeroCrossing> inZeroCrossingLst;
  input DAE.Exp addMathMLCode;
algorithm
  _:=
  matchcontinue (inZeroCrossingLst,addMathMLCode)
    local
      DAE.Exp e,addMMLCode;
      list<DAELow.Value> eq,wc;
      list<DAELow.ZeroCrossing> zcLst;
    case ({},_) then ();
    case (DAELow.ZERO_CROSSING(relation_ = e,occurEquLst = eq,occurWhenLst = wc) :: zcLst,addMMLCode)
      equation
        dumpStrOpenTagAttr(stringAppend(ZERO_CROSSING,ELEMENT_),EXP_STRING,Exp.printExpStr(e));
        dumpExp(e,addMMLCode);
        dumpLstIntAttr(eq,stringAppend(INVOLVED,EQUATIONS_),stringAppend(EQUATION,ID_));
        dumpLstIntAttr(wc,stringAppend(INVOLVED,stringAppend(WHEN_,EQUATIONS_)),stringAppend(WHEN,stringAppend(EQUATION_,ID_)));
        dumpStrCloseTag(stringAppend(ZERO_CROSSING,ELEMENT_));
        dumpZcLst(zcLst,addMMLCode);
      then ();
  end matchcontinue;
end dumpZcLst;


public function lbinopSymbol "
function: lbinopSymbol
  Return string representation of logical binary operator.
"
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString:=
  matchcontinue (inOperator)
    case (DAE.AND()) then MathMLAnd;
    case (DAE.OR()) then MathMLOr;
  end matchcontinue;
end lbinopSymbol;

public function lunaryopSymbol "
function: lunaryopSymbol
  Return string representation of logical unary operator
  corresponding to the MathML encode.
"
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString:=
  matchcontinue (inOperator)
    case (DAE.NOT()) then MathMLNot;
  end matchcontinue;
end lunaryopSymbol;


protected function printExpStr "
function: printExpStr
  This function prints a complete expression.
  This function is exactly the same of the Print.printExpStr function
  exception with the printing of the DAE.SCONST. The DAE.SCONST
  are printed without quotes.
"
  input DAE.Exp e;
  output String s;
algorithm
  s := Exp.printExp2Str(e, "",NONE(),NONE());
end printExpStr;

public function relopSymbol  "
function: relopSymbol
  Return string representation of function operator.
"
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString:=
  matchcontinue (inOperator)
    case (DAE.LESS(ty = _)) then MathMLLessThan;
    case (DAE.LESSEQ(ty = _)) then MathMLLessEqualThan;
    case (DAE.GREATER(ty = _)) then MathMLGreaterThan;
    case (DAE.GREATEREQ(ty = _)) then MathMLGreaterEqualThan;
    case (DAE.EQUAL(ty = _)) then MathMLEquivalent;
    case (DAE.NEQUAL(ty = _)) then MathMLNotEqual;
  end matchcontinue;
end relopSymbol;


public function dumpResidual "
This function is necessary to print an equation element as a residual.
Since in Modelica is possible to have different kind of
equations, the DAELow representation of the OMC distinguish
between:
 - normal equations
 - array equations
 - solved equations
 - when equations
 - residual equations
 - algorithm references
This function prints the content using XML representation.
The output changes according to the content of the equation.
For example, if the element is an Array of Equations:
<ArrayOfEquations ID=..>
  <ARRAY_EQUATION>
    ..
    <MathML>
     ...
   </MathML>
   <ADDITIONAL_INFO stringAppend(ARRAY_OF_EQUATIONS,ID_)=...>
     <INVOLVEDVARIABLES>
       <VARIABLE>...</VARIABLE>
       ...
       <VARIABLE>...</VARIABLE>
     </INVOLVEDVARIABLES>
   </ADDITIONAL_INFO>
  </ARRAY_EQUATION>
</ARRAY_OF_EQUATIONS>
"
  input DAELow.Equation inEquation;
  input String inIndexNumber;
  input DAE.Exp addMathMLCode;
algorithm
  _:=
  matchcontinue (inEquation,inIndexNumber,addMathMLCode)
    local
      String s1,s2,res,indx_str,is,var_str,indexS;
      DAE.Exp e1,e2,e;
      DAELow.Value indx,i;
      list<DAE.Exp> expl;
      DAE.ComponentRef cr;
      DAE.Exp addMMLCode;

    case (DAELow.EQUATION(exp = e1,scalar = e2),indexS,DAE.BCONST(bool=true))
      equation
        s1 = Exp.printExpStr(e1);
        s2 = Exp.printExpStr(e2);
        s1 = Util.xmlEscape(s1);
        s2 = Util.xmlEscape(s2);
        res = Util.stringAppendList({s1," ( ",s2,") = 0"});
        dumpStrOpenTagAttr(EQUATION,ID,indexS);
        Print.printBuf(res);
        dumpStrOpenTag(MathML);
        dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLEquivalent);
        dumpStrOpenTag(MathMLApply);
        dumpStrOpenTag(MathMLMinus);
        dumpExp2(e1);
        dumpExp2(e2);
        dumpStrCloseTag(MathMLApply);
        dumpExp2(DAE.RCONST(0.0));
        dumpStrCloseTag(MathMLApply);
        dumpStrCloseTag(MATH);
        dumpStrCloseTag(MathML);
        dumpStrCloseTag(EQUATION);
      then ();
    case (DAELow.EQUATION(exp = e1,scalar = e2),indexS,DAE.BCONST(bool=false))
      equation
        s1 = Exp.printExpStr(e1);
        s2 = Exp.printExpStr(e2);
        s1 = Util.xmlEscape(s1);
        s2 = Util.xmlEscape(s2);
        res = Util.stringAppendList({s1," - ( ",s2, " ) = 0"});
        dumpStrOpenTagAttr(EQUATION,ID,indexS);
        Print.printBuf(res);
        dumpStrCloseTag(EQUATION);
      then ();
    case (DAELow.ARRAY_EQUATION(index = indx,crefOrDerCref = expl),indexS,addMMLCode)
      equation
        dumpStrOpenTagAttr(ARRAY_OF_EQUATIONS,ID,indexS);
        dumpLstExp(expl,ARRAY_EQUATION,addMMLCode);
        dumpStrOpenTagAttr(ADDITIONAL_INFO, stringAppend(ARRAY_OF_EQUATIONS,ID_), intString(indx));
        dumpStrOpenTag(stringAppend(INVOLVED,VARIABLES_));
        dumpStrOpenTag(VARIABLE);
        var_str=Util.stringDelimitList(Util.listMap(expl,Exp.printExpStr),Util.stringAppendList({"</",VARIABLE,">\n<",VARIABLE,">"}));
        dumpStrCloseTag(VARIABLE);
        dumpStrCloseTag(stringAppend(INVOLVED,VARIABLES_));
        dumpStrCloseTag(ADDITIONAL_INFO);
        dumpStrCloseTag(ARRAY_OF_EQUATIONS);
      then ();
    case (DAELow.SOLVED_EQUATION(componentRef = cr,exp = e2),indexS,DAE.BCONST(bool=true))
      equation
        s1 = Exp.printComponentRefStr(cr);
        s2 = Exp.printExpStr(e2);
        s2 = Util.xmlEscape(s2);
        res = Util.stringAppendList({s1," - ( ",s2," ) := 0"});
        dumpStrOpenTagAttr(stringAppend(SOLVED,EQUATION_),ID,indexS);
        Print.printBuf(res);
        dumpStrOpenTag(MathML);
        dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLEquivalent);
        dumpStrOpenTag(MathMLApply);
        dumpStrOpenTag(MathMLMinus);
        Print.printBuf(s1);
        dumpExp2(e2);
        dumpStrCloseTag(MathMLApply);
        dumpExp2(DAE.RCONST(0.0));
        dumpStrCloseTag(MathMLApply);
        dumpStrCloseTag(MATH);
        dumpStrCloseTag(MathML);
        dumpStrCloseTag(stringAppend(SOLVED,EQUATION_));
      then ();
    case (DAELow.SOLVED_EQUATION(componentRef = cr,exp = e2),indexS,DAE.BCONST(bool=false))
      equation
        s1 = Exp.printComponentRefStr(cr);
        s2 = Exp.printExpStr(e2);
        s2 = Util.xmlEscape(s2);
        res = Util.stringAppendList({s1," - (",s2,") := 0"});
        dumpStrOpenTagAttr(stringAppend(SOLVED,EQUATION_),ID,indexS);
        Print.printBuf(res);
        dumpStrCloseTag(stringAppend(SOLVED,EQUATION_));
      then ();
    case (DAELow.WHEN_EQUATION(whenEquation = DAELow.WHEN_EQ(index = i,left = cr,right = e2)),indexS,DAE.BCONST(bool=true))
      equation
        s1 = Exp.printComponentRefStr(cr);
        s2 = Exp.printExpStr(e2);
        s2 = Util.xmlEscape(s2);
        is = intString(i);
        res = Util.stringAppendList({s1," - (",s2,") := 0"});
        dumpStrOpenTagAttr(stringAppend(WHEN,EQUATION_),ID,indexS);
        Print.printBuf(res);
        dumpStrOpenTag(MathML);
        dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLEquivalent);
        dumpStrOpenTag(MathMLApply);
        dumpStrOpenTag(MathMLMinus);
        Print.printBuf(s1);
        dumpExp2(e2);
        dumpStrCloseTag(MathMLApply);
        dumpExp2(DAE.RCONST(0.0));
        dumpStrCloseTag(MathMLApply);
        dumpStrCloseTag(MATH);
        dumpStrCloseTag(MathML);
        dumpStrTagContent(stringAppend(stringAppend(WHEN,EQUATION_),ID_),is);
        dumpStrCloseTag(stringAppend(WHEN,EQUATION_));
      then ();
    case (DAELow.WHEN_EQUATION(whenEquation = DAELow.WHEN_EQ(index = i,left = cr,right = e2)),indexS,DAE.BCONST(bool=false))
      equation
        s1 = Exp.printComponentRefStr(cr);
        s2 = Exp.printExpStr(e2);
        s2 = Util.xmlEscape(s2);
        is = intString(i);
        res = Util.stringAppendList({s1," - (",s2,") := 0"});
        dumpStrOpenTagAttr(stringAppend(WHEN,EQUATION_),ID,indexS);
        Print.printBuf(res);
        dumpStrTagContent(stringAppend(stringAppend(WHEN,EQUATION_),ID_),is);
        dumpStrCloseTag(stringAppend(WHEN,EQUATION_));
      then ();
    case (DAELow.RESIDUAL_EQUATION(exp = e),indexS,DAE.BCONST(bool=true))
      equation
        s1 = Exp.printExpStr(e);
        s1 = Util.xmlEscape(s1);
        res = Util.stringAppendList({s1," = 0"});
        dumpStrOpenTagAttr(stringAppend(RESIDUAL,EQUATION_),ID,indexS);
        Print.printBuf(res);
        dumpStrOpenTag(MathML);
        dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLEquivalent);
        dumpExp2(e);
        dumpStrMathMLNumber("0");
        dumpStrCloseTag(MathMLApply);
        dumpStrCloseTag(MATH);
        dumpStrCloseTag(MathML);
        dumpStrCloseTag(stringAppend(RESIDUAL,EQUATION_));
      then ();
    case (DAELow.RESIDUAL_EQUATION(exp = e),indexS,DAE.BCONST(bool=false))
      equation
        s1 = Exp.printExpStr(e);
        s1 = Util.xmlEscape(s1);
        res = Util.stringAppendList({s1," = 0"});
        dumpStrOpenTagAttr(stringAppend(RESIDUAL,EQUATION_),ID,indexS);
        Print.printBuf(res);
        dumpStrCloseTag(stringAppend(RESIDUAL,EQUATION_));
      then ();
    case (DAELow.ALGORITHM(index = i),indexS,_)
      equation
        is = intString(i);
        dumpStrOpenTagAttr(ALGORITHM,ID,indexS);
        dumpStrTagContent(stringAppend(ALGORITHM,ID_),is);
        dumpStrTagAttrNoChild(ANCHOR, ALGORITHM_NAME, stringAppend(stringAppend(ALGORITHM_REF,"_"),is));
        //dumpStrOpenTagAttr(ANCHOR, ALGORITHM_NAME, stringAppend(stringAppend(ALGORITHM_REF,"_"),is));
        //dumpStrCloseTag(ANCHOR);
        dumpStrCloseTag(ALGORITHM);
      then ();
  end matchcontinue;
end dumpResidual;


public function unaryopSymbol "
function: unaryopSymbol
  Return string representation of unary operators
  corresponding to the MathML encode.
"
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString:=
  matchcontinue (inOperator)
    case (DAE.UMINUS(ty = _)) then MathMLMinus;
    case (DAE.UPLUS(ty = _)) then "";//Not necessay
    case (DAE.UMINUS_ARR(ty = _)) then MathMLMinus;
    case (DAE.UPLUS_ARR(ty = _)) then "";//Not necessary
  end matchcontinue;
end unaryopSymbol;


public function unparseCommentOptionNoAnnotation "
function: unparseCommentOptionNoAnnotation

  Prettyprints a Comment without printing the annotation part.
"
  input Option<SCode.Comment> inAbsynCommentOption;
  output String outString;
algorithm
  outString:=
  matchcontinue (inAbsynCommentOption)
    local Dump.Ident str,cmt;
    case (SOME(SCode.COMMENT(_,SOME(cmt))))
      equation
        //str = Util.stringAppendList({" \"",cmt,"\""});
        str = cmt;
      then
        str;
    case (_) then "";
  end matchcontinue;
end unparseCommentOptionNoAnnotation;

end XMLDump;
