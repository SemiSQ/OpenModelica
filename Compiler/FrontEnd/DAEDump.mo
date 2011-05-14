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

encapsulated package DAEDump
" file:        DAEDump.mo
  package:     DAEDump
  description: DAEDump output

  RCS: $Id$

  This module implements functions to print the DAE AST."

// public imports
public import DAE;
public import Graphviz;
public import IOStream;
public import SCode;

// protected imports
protected import ComponentReference;
protected import DAEUtil;
protected import Print;
protected import Util;
protected import Expression;
protected import ExpressionDump;
protected import Absyn;
protected import Dump;
protected import ValuesUtil;
protected import Values;
protected import Types;
protected import ClassInf;
protected import Algorithm;
protected import RTOpts;

public function printDAE "function: printDAE
  This function prints out a list of elements (i.e. a DAE)
  to the stdout. Useful for example when called from Inst.instClass"
  input DAE.DAElist inDAElist;
algorithm
  _ := matchcontinue (inDAElist)
    local
      DAE.DAElist dae;
      String str;
    
    case dae
      equation
        Print.clearBuf();
        dump2(dae);
        str = Print.getString();
        print(str);
      then
        ();
  end matchcontinue;
end printDAE;

public function dump "function: dump
  This function prints the DAE in the standard output format to the Print buffer.
  For printing to the stdout use print(dumpStr(dae)) instead."
  input DAE.DAElist dae;
  input DAE.FunctionTree functionTree;
algorithm
  _ := match (dae,functionTree)
    local
      list<DAE.Element> daelist;
    
    case (DAE.DAE(daelist),functionTree)
      equation
        Util.listMap0(sortFunctions(DAEUtil.getFunctionList(functionTree)),dumpFunction);
        Util.listMap0(daelist, dumpExtObjectClass);
        Util.listMap0(daelist, dumpCompElement);
      then
        ();
  end match;
end dump;

public function dumpFunctionNamesStr "return all function names in a string  (comma separated)"
  input DAE.FunctionTree funcs;
  output String str;
algorithm
  str := matchcontinue(funcs)
    case funcs
      equation
        str = Util.stringDelimitList(Util.listMap(sortFunctions(DAEUtil.getFunctionList(funcs)),functionNameStr),",");
    then str;
  end matchcontinue;
end dumpFunctionNamesStr;

public function functionNameStr
"return the name of a function, if element is not function return  empty string"
  input DAE.Function inElement;
  output String res;
algorithm
  res := matchcontinue (inElement)
    local
      Absyn.Path fpath;
      
     case DAE.FUNCTION(path = fpath)
       equation
         res = Absyn.pathStringNoQual(fpath);
       then res;
     case DAE.RECORD_CONSTRUCTOR(path = fpath)
       equation
         res = Absyn.pathStringNoQual(fpath);
       then res;
     case _ then "";
  end matchcontinue;
end functionNameStr;

protected function sortFunctions "sorts the functions and record constructors in alphabetical order"
  input list<DAE.Function> funcs;
  output list<DAE.Function> sortedFuncs;
algorithm
  sortedFuncs := Util.sort(funcs,funcGreaterThan);
end sortFunctions;

protected function funcGreaterThan "sorting function for two DAE.Element that are functions or record constuctors"
  input DAE.Function func1;
  input DAE.Function func2;
  output Boolean res;
algorithm
  res := matchcontinue(func1,func2)
    case(func1,func2) equation
      res = stringCompare(functionNameStr(func1),functionNameStr(func2)) > 0;
    then res;
    else true;
  end matchcontinue;
end funcGreaterThan;
 
public function dumpOperatorString "
Author bz  printOperator
Dump operator to a string."
  input DAE.Operator op;
  output String str;
algorithm
  str := matchcontinue(op)
    local
      Absyn.Path p;
      DAE.ExpType ty;
    case(DAE.ADD(ty=ty)) then " ADD ";
    case(DAE.SUB(ty=ty)) then " SUB ";
    case(DAE.MUL(ty=ty)) then " MUL ";
    case(DAE.DIV(ty=ty)) then " DIV ";
    case(DAE.POW(ty=ty)) then " POW ";
    case(DAE.UMINUS(ty=ty)) then " UMINUS ";
    case(DAE.UPLUS(ty=ty)) then " UPLUS ";
    case(DAE.UMINUS_ARR(ty=ty)) then " UMINUS_ARR ";
    case(DAE.UPLUS_ARR(ty=ty)) then " UPLUS_ARR ";
    case(DAE.ADD_ARR(ty=ty)) then " ADD_ARR ";
    case(DAE.SUB_ARR(ty=ty)) then " SUB_ARR ";
    case(DAE.MUL_ARR(ty=ty)) then " MUL_ARR ";
    case(DAE.DIV_ARR(ty=ty)) then " DIV_ARR ";
    case(DAE.MUL_SCALAR_ARRAY(ty=ty)) then " MUL_SCALAR_ARRAY ";
    case(DAE.MUL_ARRAY_SCALAR(ty=ty)) then " MUL_ARRAY_SCALAR ";
    case(DAE.ADD_SCALAR_ARRAY(ty=ty)) then " ADD_SCALAR_ARRAY ";
    case(DAE.ADD_ARRAY_SCALAR(ty=ty)) then " ADD_ARRAY_SCALAR ";
    case(DAE.SUB_SCALAR_ARRAY(ty=ty)) then " SUB_SCALAR_ARRAY ";
    case(DAE.SUB_ARRAY_SCALAR(ty=ty)) then " SUB_ARRAY_SCALAR ";
    case(DAE.MUL_SCALAR_PRODUCT(ty=ty)) then " MUL_SCALAR_PRODUCT ";
    case(DAE.MUL_MATRIX_PRODUCT(ty=ty)) then " MUL_MATRIX_PRODUCT ";
    case(DAE.DIV_ARRAY_SCALAR(ty=ty)) then " DIV_ARRAY_SCALAR ";
    case(DAE.DIV_SCALAR_ARRAY(ty=ty)) then " DIV_SCALAR_ARRAY ";
    case(DAE.POW_ARRAY_SCALAR(ty=ty)) then " POW_ARRAY_SCALAR ";
    case(DAE.POW_SCALAR_ARRAY(ty=ty)) then " POW_SCALAR_ARRAY ";
    case(DAE.POW_ARR(ty=ty)) then " POW_ARR ";
    case(DAE.POW_ARR2(ty=ty)) then " POW_ARR2 ";
    case(DAE.OR()) then " OR ";
    case(DAE.AND()) then " AND ";
    case(DAE.NOT()) then " NOT ";
    case(DAE.LESSEQ(ty=ty)) then " LESSEQ ";
    case(DAE.GREATER(ty=ty)) then " GREATER ";
    case(DAE.GREATEREQ(ty=ty)) then " GREATEREQ ";
    case(DAE.LESS(ty=ty)) then " LESS ";
    case(DAE.EQUAL(ty=ty)) then " EQUAL ";
    case(DAE.NEQUAL(ty=ty)) then " NEQUAL ";
    case(DAE.USERDEFINED(p)) then " Userdefined:" +& Absyn.pathString(p) +& " ";
    case(_) then " --UNDEFINED-- ";
  end matchcontinue;
end dumpOperatorString;

public function dump2str "
printDAEString daeString "
input DAE.DAElist inDAElist;
output String str;
algorithm
  dump2(inDAElist);
  str := Print.getString();
  Print.clearBuf();
end dump2str;

public function dump2 "function: dump2
  Helper function to dump. Prints the DAE using module Print."
  input DAE.DAElist inDAElist;
algorithm
  _ := matchcontinue (inDAElist)
    local
      String comment_str,ident;
      DAE.ComponentRef cr,cr2;
      DAE.Exp e,e1,e2;
      DAE.InstDims dims;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      list<DAE.Element> xs,elts;
      list<DAE.Dimension> dl;
      
    case DAE.DAE((DAE.VAR(componentRef = cr,
                               binding = SOME(e),
                               dims = dims,
                               variableAttributesOption = dae_var_attr,
                               absynCommentOption = comment) :: xs))
      equation
        Print.printBuf("VAR(");
        ComponentReference.printComponentRef(cr);

        /* //include type of var

        s1 = ComponentReference.debugPrintComponentRefTypeStr(cr);
        s1 = Util.stringReplaceChar(s1,"\n","");
        Print.printBuf("((" +& s1);
        Print.printBuf("))");
        */
        Print.printBuf("=");
        ExpressionDump.printExp(e);
        Print.printBuf(",dims=");
        Dump.printList(dims, ExpressionDump.printSubscript, ", ");
        comment_str = dumpCommentOptionStr(comment) "  dump_start_value start &" ;
        Print.printBuf("  comment:");
        Print.printBuf(comment_str);
        Print.printBuf(", ");
        dumpVariableAttributes(dae_var_attr);
        Print.printBuf(")\n");
        dump2(DAE.DAE(xs));
      then
        ();
    case DAE.DAE((DAE.VAR(componentRef = cr,binding = NONE(),variableAttributesOption = dae_var_attr,absynCommentOption = comment) :: xs))
      equation
        Print.printBuf("VAR(");
        ComponentReference.printComponentRef(cr);
        /* // include type in dump
        s1 = ComponentReference.debugPrintComponentRefTypeStr(cr);
        s1 = Util.stringReplaceChar(s1,"\n","");
        Print.printBuf("((" +& s1);
        Print.printBuf("))");
        */
        comment_str = dumpCommentOptionStr(comment) "  dump_start_value start &" ;
        Print.printBuf("  comment:");
        Print.printBuf(comment_str);
        Print.printBuf(", ");
        dumpVariableAttributes(dae_var_attr);
        Print.printBuf(")\n");
        dump2(DAE.DAE(xs));
      then
        ();
    case DAE.DAE((DAE.DEFINE(componentRef = cr) :: xs))
      equation
        Print.printBuf("DEFINE(");
        ComponentReference.printComponentRef(cr);
        Print.printBuf(")\n");
        dump2(DAE.DAE(xs));
      then
        ();
    case DAE.DAE((DAE.INITIALDEFINE(componentRef = cr) :: xs))
      equation
        Print.printBuf("INITIALDEFINE(");
        ComponentReference.printComponentRef(cr);
        Print.printBuf(")\n");
        dump2(DAE.DAE(xs));
      then
        ();
    case DAE.DAE((DAE.EQUATION(exp = e1,scalar = e2) :: xs))
      equation
        Print.printBuf("EQUATION(");
        ExpressionDump.printExp(e1);
        Print.printBuf(" = ");
        ExpressionDump.printExp(e2);
        Print.printBuf(")\n");
        dump2(DAE.DAE(xs));
      then
        ();
    case DAE.DAE((DAE.INITIALEQUATION(exp1 = e1,exp2 = e2) :: xs))
      equation
        Print.printBuf("INITIALEQUATION(");
        ExpressionDump.printExp(e1);
        Print.printBuf(" = ");
        ExpressionDump.printExp(e2);
        Print.printBuf(")\n");
        dump2(DAE.DAE(xs));
      then
        ();
    case DAE.DAE((DAE.ARRAY_EQUATION(dimension=dl,exp = e1,array = e2) :: xs))
      equation
        Print.printBuf("ARRAY_EQUATION(");
        Print.printBuf("dims = [");
        Print.printBuf(Util.stringDelimitList(Util.listMap(dl, ExpressionDump.dimensionString), ", "));
        Print.printBuf("]; ");
        ExpressionDump.printExp(e1);
        Print.printBuf(" = ");
        ExpressionDump.printExp(e2);
        Print.printBuf(")\n");
        dump2(DAE.DAE(xs));
      then
        ();
    case DAE.DAE((DAE.INITIAL_ARRAY_EQUATION(dimension=dl,exp = e1,array = e2) :: xs))
      equation
        Print.printBuf("INITIAL_ARRAY_EQUATION(");
        Print.printBuf("dims = [");
        Print.printBuf(Util.stringDelimitList(Util.listMap(dl, ExpressionDump.dimensionString), ", "));
        Print.printBuf("]; ");
        ExpressionDump.printExp(e1);
        Print.printBuf(" = ");
        ExpressionDump.printExp(e2);
        Print.printBuf(")\n");
        dump2(DAE.DAE(xs));
      then
        ();
    case (DAE.DAE((DAE.ALGORITHM(algorithm_ = _) :: xs)))
      equation
        Print.printBuf("ALGORITHM(...)");
        dump2(DAE.DAE(xs));
      then
        ();
    case (DAE.DAE((DAE.INITIALALGORITHM(algorithm_ = _) :: xs)))
      equation
        Print.printBuf("INITIALALGORITHM(...)");
        dump2(DAE.DAE(xs));
      then
        ();
    case (DAE.DAE((DAE.COMP(ident = ident,dAElist = elts) :: xs)))
      equation
        Print.printBuf("COMP(");
        Print.printBuf(ident);
        dump2(DAE.DAE(elts));
        Print.printBuf(")\n");
        dump2(DAE.DAE(xs));
      then
        ();

    case (DAE.DAE((DAE.ASSERT(condition=e1,message=e2) :: xs)))
      equation
        Print.printBuf("ASSERT(\n");
        ExpressionDump.printExp(e1);
        Print.printBuf(",");
        ExpressionDump.printExp(e2);
        Print.printBuf(")\n");
        dump2(DAE.DAE(xs));
      then
        ();
    case(DAE.DAE((DAE.EQUEQUATION(cr1 = cr, cr2 = cr2) :: xs)))
      equation
        Print.printBuf("EQUEQUATION(");
        ComponentReference.printComponentRef(cr);
        Print.printBuf(" = ");
        ComponentReference.printComponentRef(cr2);
        Print.printBuf(")\n");
        dump2(DAE.DAE(xs));
      then
        ();
    case DAE.DAE((DAE.COMPLEX_EQUATION(lhs = e1,rhs = e2) :: xs))
      equation
        Print.printBuf("COMPLEX_EQUATION(");
        ExpressionDump.printExp(e1);
        Print.printBuf(" = ");
        ExpressionDump.printExp(e2);
        Print.printBuf(")\n");
        dump2(DAE.DAE(xs));
      then
        ();
    case DAE.DAE((DAE.INITIAL_COMPLEX_EQUATION(lhs = e1,rhs = e2) :: xs))
      equation
        Print.printBuf("INITIAL_COMPLEX_EQUATION(");
        ExpressionDump.printExp(e1);
        Print.printBuf(" = ");
        ExpressionDump.printExp(e2);
        Print.printBuf(")\n");
        dump2(DAE.DAE(xs));
      then
        ();
    case (DAE.DAE(elementLst = {})) then ();
    
    //BZ Could be nice to know when this failes (when new elements are introduced) 
    case(DAE.DAE((_ :: xs)))
      equation
        Print.printBuf("\n\ndump2 failed to print element\n");
        dump2(DAE.DAE(xs));
      then
        ();
    case (_)
      equation
        Print.printBuf("dump2 failed\n");
      then
        ();
  end matchcontinue;
end dump2;

protected function dumpStartValue "function: dumpStartValue
  Dumps the StartValue for a variable."
  input DAE.StartValue inStartValue;
algorithm
  _ := matchcontinue (inStartValue)
    local
      DAE.Exp e;
    case (SOME(e))
      equation
        Print.printBuf("(start=");
        ExpressionDump.printExp(e);
        Print.printBuf(")");
      then
        ();
    case (_) then ();
  end matchcontinue;
end dumpStartValue;

public function dumpStartValueStr "function: dumpStartValueStr
  Dumps the start value for a variable to a string."
  input DAE.StartValue inStartValue;
  output String outString;
algorithm
  outString := matchcontinue (inStartValue)
    local
      String s,res;
      DAE.Exp e;
    case (SOME(e))
      equation
        s = ExpressionDump.printExpStr(e);
        res = stringAppendList({"(start=",s,")"});
      then
        res;
    case (_) then "";
  end matchcontinue;
end dumpStartValueStr;

public function dumpExtDeclStr "function: dumpExtDeclStr
  Dumps the external declaration to a string."
  input DAE.ExternalDecl inExternalDecl;
  output String outString;
algorithm
  outString := matchcontinue (inExternalDecl)
    local
      String extargsstr,rettystr,str,id,lang;
      list<DAE.ExtArg> extargs;
      DAE.ExtArg retty;
    case DAE.EXTERNALDECL(name = id,args = extargs,returnArg = retty,language = lang)
      equation
        extargsstr = Dump.getStringList(extargs, dumpExtArgStr, ",");
        rettystr = dumpExtArgStr(retty);
        str = stringAppendList(
          {"EXTERNALDECL(",id,", (",extargsstr,"), ",rettystr,", \"",
          lang,"\")"});
      then
        str;
  end matchcontinue;
end dumpExtDeclStr;

public function dumpExtArgStr "function: dumpExtArgStr
  Helper function to dumpExtDeclStr"
  input DAE.ExtArg inExtArg;
  output String outString;
algorithm
  outString := matchcontinue (inExtArg)
    local
      String crstr,dirstr,tystr,str,dimstr;
      DAE.ComponentRef cr;
      SCode.Flow fl;
      SCode.Stream st;
      SCode.Accessibility acc;
      SCode.Variability var;
      Absyn.Direction dir;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      DAE.Exp exp,dim;
      DAE.Attributes attr;
      
    case DAE.NOEXTARG() then "void";
    case DAE.EXTARG(componentRef = cr,attributes = DAE.ATTR(flowPrefix = fl,streamPrefix=st,accessibility = acc,variability = var,direction = dir),type_ = ty)
      equation
        crstr = ComponentReference.printComponentRefStr(cr);
        dirstr = Dump.directionSymbol(dir);
        tystr = Types.getTypeName(ty);
        str = stringAppendList({dirstr," ",tystr," ",crstr});
      then
        str;
    case DAE.EXTARGEXP(exp = exp,type_ = ty)
      equation
        crstr = ExpressionDump.printExpStr(exp);
        tystr = Types.getTypeName(ty);
        str = stringAppendList({"(",tystr,") ",crstr});
      then
        str;
    case DAE.EXTARGSIZE(componentRef = cr,attributes = attr,type_ = ty,exp = dim)
      equation
        crstr = ComponentReference.printComponentRefStr(cr);
        dimstr = ExpressionDump.printExpStr(dim);
        str = stringAppendList({"size(",crstr,",",dimstr,")"});
      then
        str;
  end matchcontinue;
end dumpExtArgStr;

protected function dumpCompElement "function: dumpCompElement
  Dumps Component elements."
  input DAE.Element inElement;
algorithm
  _ := matchcontinue (inElement)
    local
      String n;
      list<DAE.Element> l;
      Option<SCode.Comment> c;
    case DAE.COMP(ident = n,dAElist = l, comment = c)
      equation
        Print.printBuf("class ");
        Print.printBuf(n);
        dumpCommentOption(c);
        Print.printBuf("\n");
        dumpElements(l);
        Print.printBuf("end ");
        Print.printBuf(n);
        Print.printBuf(";\n");
      then
        ();
    case _ then ();  /* LS: for non-COMPS, which are only FUNCTIONS at the moment */
  end matchcontinue;
end dumpCompElement;

public function dumpElements "function: dumpElements
  Dump elements."
  input list<DAE.Element> l;
algorithm
  dumpVars(l, false);
  Util.listMap0(l, dumpExtObjectClass);
  Print.printBuf("initial equation\n");
  Util.listMap0(l, dumpInitialEquation);
  Print.printBuf("equation\n");
  Util.listMap0(l, dumpEquation);
  Util.listMap0(l, dumpInitialAlgorithm);
  Util.listMap0(l, dumpAlgorithm);
  Util.listMap0(l, dumpCompElement);
end dumpElements;

public function dumpFunctionElements "function: dumpElements
  Dump function elements."
  input list<DAE.Element> l;
algorithm
  dumpVars(l, true);
  Util.listMap0(l, dumpAlgorithm);
end dumpFunctionElements;

protected function dumpVars "function: dumpVars
  Dump variables to Print buffer."
  input list<DAE.Element> lst;
  input Boolean printTypeDimension "use true here when printing components in functions as these are not vectorized! Otherwise, use false";
protected
  String str;
  IOStream.IOStream myStream;
algorithm
  myStream := IOStream.create("", IOStream.LIST());
  myStream := dumpVarsStream(lst, printTypeDimension, myStream);
  str := IOStream.string(myStream);
  Print.printBuf(str);
end dumpVars;

protected function dumpKind "function: dumpKind
  Dump VarKind."
  input DAE.VarKind inVarKind;
algorithm
  _ := match (inVarKind)
    case DAE.CONST()
      equation
        Print.printBuf(" constant  ");
      then
        ();
    case DAE.PARAM()
      equation
        Print.printBuf(" parameter ");
      then
        ();
    case DAE.DISCRETE()
      equation
        Print.printBuf(" discrete  ");
      then
        ();
    case DAE.VARIABLE()
      equation
        Print.printBuf("           ");
      then
        ();
  end match;
end dumpKind;

protected function dumpKindStr "function: dumpKindStr
  Dump VarKind to a string."
  input DAE.VarKind inVarKind;
  output String outString;
algorithm
  outString := match (inVarKind)
    case DAE.CONST() then "constant ";
    case DAE.PARAM() then "parameter ";
    case DAE.DISCRETE() then "discrete ";
    case DAE.VARIABLE() then "";
  end match;
end dumpKindStr;

protected function dumpDirection "function: dumpDirection
  Dump VarDirection."
  input DAE.VarDirection inVarDirection;
algorithm
  _ := matchcontinue (inVarDirection)
    case DAE.INPUT()
      equation
        Print.printBuf(" input  ");
      then
        ();
    case DAE.OUTPUT()
      equation
        Print.printBuf(" output ");
      then
        ();
    case DAE.BIDIR()
      equation
        Print.printBuf("        ");
      then
        ();
  end matchcontinue;
end dumpDirection;

public function dumpDirectionStr "function: dumpDirectionStr
  Dump VarDirection to a string"
  input DAE.VarDirection inVarDirection;
  output String outString;
algorithm
  outString := match (inVarDirection)
    case DAE.INPUT() then "input ";
    case DAE.OUTPUT() then "output ";
    case DAE.BIDIR() then "";
  end match;
end dumpDirectionStr;

protected function dumpStateSelectStr "function dumpStateSelectStr
  Dump StateSelect to a string."
  input DAE.StateSelect inStateSelect;
  output String outString;
algorithm
  outString := match (inStateSelect)
    case DAE.NEVER() then "StateSelect.never";
    case DAE.AVOID() then "StateSelect.avoid";
    case DAE.PREFER() then "StateSelect.prefer";
    case DAE.ALWAYS() then "StateSelect.always";
    case DAE.DEFAULT() then "StateSelect.default";
  end match;
end dumpStateSelectStr;

public function dumpVariableAttributes "function: dumpVariableAttributes
  Dump VariableAttributes option."
  input Option<DAE.VariableAttributes> attr;
  String res;
algorithm
  res := dumpVariableAttributesStr(attr);
  Print.printBuf(res);
end dumpVariableAttributes;

public function dumpVariableAttributesStr "function: dumpVariableAttributesStr

  Dump VariableAttributes option to a string.
"
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output String outString;
algorithm
  outString:=
  matchcontinue (inVariableAttributesOption)
    local
      String quantity,unit_str,displayUnit_str,stateSel_str,min_str,max_str,nominal_str,initial_str,fixed_str,res_1,res1,res;
      Boolean is_empty;
      Option<DAE.Exp> quant,unit,displayUnit,min,max,initialExp,nominal,fixed;
      Option<DAE.StateSelect> stateSel;
    
    case (SOME(DAE.VAR_ATTR_REAL(quant,unit,displayUnit,(min,max),initialExp,fixed,nominal,stateSel,_,_,_)))
      equation
        quantity = Dump.getOptionWithConcatStr(quant, ExpressionDump.printExpStr, "quantity = ");
        unit_str = Dump.getOptionWithConcatStr(unit, ExpressionDump.printExpStr, "unit = ");
        displayUnit_str = Dump.getOptionWithConcatStr(displayUnit, ExpressionDump.printExpStr, "displayUnit = ");
        stateSel_str = Dump.getOptionWithConcatStr(stateSel, dumpStateSelectStr , "StateSelect = ");
        min_str = Dump.getOptionWithConcatStr(min, ExpressionDump.printExpStr, "min = ");
        max_str = Dump.getOptionWithConcatStr(max, ExpressionDump.printExpStr, "max = ");
        nominal_str = Dump.getOptionWithConcatStr(nominal, ExpressionDump.printExpStr, "nominal = ");
        initial_str = Dump.getOptionWithConcatStr(initialExp, ExpressionDump.printExpStr, "start = ");
        fixed_str = Dump.getOptionWithConcatStr(fixed, ExpressionDump.printExpStr, "fixed = ");
        res_1 = Util.stringDelimitListNonEmptyElts(
          {quantity,unit_str,displayUnit_str,min_str,max_str,
          initial_str,fixed_str,nominal_str,stateSel_str}, ", ");
        res1 = stringAppendList({"(",res_1,")"});
        is_empty = Util.isEmptyString(res_1);
        res = Util.if_(is_empty, "", res1);
      then
        res;
    
    case (SOME(DAE.VAR_ATTR_INT(quant,(min,max),initialExp,fixed,_,_,_)))
      equation
        quantity = Dump.getOptionWithConcatStr(quant, ExpressionDump.printExpStr, "quantity = ");
        min_str = Dump.getOptionWithConcatStr(min, ExpressionDump.printExpStr, "min = ");
        max_str = Dump.getOptionWithConcatStr(max, ExpressionDump.printExpStr, "max = ");
        initial_str = Dump.getOptionWithConcatStr(initialExp, ExpressionDump.printExpStr, "start = ");
        fixed_str = Dump.getOptionWithConcatStr(fixed, ExpressionDump.printExpStr, "fixed = ");
        res_1 = Util.stringDelimitListNonEmptyElts({quantity,min_str,max_str,initial_str,fixed_str}, ", ");
        res1 = stringAppendList({"(",res_1,")"});
        is_empty = Util.isEmptyString(res_1);
        res = Util.if_(is_empty, "", res1);
      then
        res;
    
    case (SOME(DAE.VAR_ATTR_BOOL(quant,initialExp,fixed,_,_,_)))
      equation
        quantity = Dump.getOptionWithConcatStr(quant, ExpressionDump.printExpStr, "quantity = ");
        initial_str = Dump.getOptionWithConcatStr(initialExp, ExpressionDump.printExpStr, "start = ");
        fixed_str = Dump.getOptionWithConcatStr(fixed, ExpressionDump.printExpStr, "fixed = ");
        res_1 = Util.stringDelimitListNonEmptyElts({quantity,initial_str,fixed_str}, ", ");
        res1 = stringAppendList({"(",res_1,")"});
        is_empty = Util.isEmptyString(res_1);
        res = Util.if_(is_empty, "", res1);
      then
        res;
    
    case (SOME(DAE.VAR_ATTR_STRING(quant,initialExp,_,_,_)))
      equation
        quantity = Dump.getOptionWithConcatStr(quant, ExpressionDump.printExpStr, "quantity = ");
        initial_str = Dump.getOptionWithConcatStr(initialExp, ExpressionDump.printExpStr, "start = ");
        res_1 = Util.stringDelimitListNonEmptyElts({quantity,initial_str}, ", ");
        res1 = stringAppendList({"(",res_1,")"});
        is_empty = Util.isEmptyString(res_1);
        res = Util.if_(is_empty, "", res1);
      then
        res;
    
    case (SOME(DAE.VAR_ATTR_ENUMERATION(quant,(min,max),initialExp,fixed,_,_,_)))
      equation
        quantity = Dump.getOptionWithConcatStr(quant, ExpressionDump.printExpStr, "quantity = ");
        min_str = Dump.getOptionWithConcatStr(min, ExpressionDump.printExpStr, "min = ");
        max_str = Dump.getOptionWithConcatStr(max, ExpressionDump.printExpStr, "max = ");
        initial_str = Dump.getOptionWithConcatStr(initialExp, ExpressionDump.printExpStr, "start = ");
        fixed_str = Dump.getOptionWithConcatStr(fixed, ExpressionDump.printExpStr, "fixed = ");
        res_1 = Util.stringDelimitListNonEmptyElts({quantity,min_str,max_str,initial_str,fixed_str}, ", ");
        res1 = stringAppendList({"(",res_1,")"});
        is_empty = Util.isEmptyString(res_1);
        res = Util.if_(is_empty, "", res1);
      then
        res;
    
    case (NONE()) then "";
    
    case (_) then "unknown VariableAttributes";
  end matchcontinue;
end dumpVariableAttributesStr;

protected function dumpVar "
  Dump Var."
  input DAE.Element inElement;
algorithm
  _ := matchcontinue (inElement)
    local
      DAE.ComponentRef id;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.Type typ;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<Absyn.Path> classlst,class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Exp e;
      DAE.ElementSource source "the element source";

    // var with no binding
    case DAE.VAR(componentRef = id,
             kind = kind,
             direction = dir,
             ty = typ,
             binding = NONE(),
             flowPrefix = flowPrefix,
             streamPrefix = streamPrefix,
             source = source,
             variableAttributesOption = dae_var_attr,
             absynCommentOption = comment)
      equation
        dumpKind(kind);
        dumpDirection(dir);
        Print.printBuf(Types.unparseType(typ));
        Print.printBuf(" ");
        ComponentReference.printComponentRef(id);
        dumpCommentOption(comment);
        dumpVariableAttributes(dae_var_attr);
        Print.printBuf(";\n");
      then
        ();
    // var with binding
    case DAE.VAR(componentRef = id,
             kind = kind,
             direction = dir,
             ty = typ,
             binding = SOME(e),
             flowPrefix = flowPrefix,
             streamPrefix = streamPrefix,
             source = source,
             variableAttributesOption = dae_var_attr,
             absynCommentOption = comment)
      equation
        dumpKind(kind);
        dumpDirection(dir);
        Print.printBuf(Types.unparseType(typ));
        Print.printBuf(" ");
        ComponentReference.printComponentRef(id);
        dumpVariableAttributes(dae_var_attr);
        Print.printBuf(" = ");
        ExpressionDump.printExp(e);
        Print.printBuf(";\n");
      then
        ();
    case (_) then ();
  end matchcontinue;
end dumpVar;

protected function dumpVarVisibilityStr "Prints 'protected' to a string for protected variables"
  input DAE.VarVisibility prot;
  output String str;
algorithm
  str := match(prot)
    case DAE.PUBLIC() then "";
    case DAE.PROTECTED() then "protected ";
  end match;
end dumpVarVisibilityStr;

public function dumpCommentOptionStr "function: dumpCommentOptionStr
  Dump Comment option to a string."
  input Option<SCode.Comment> inAbsynCommentOption;
  output String outString;
algorithm
  outString:=
  matchcontinue (inAbsynCommentOption)
    local
      String str,cmt;
      Option<SCode.Annotation> annopt;
      list<SCode.Annotation> annl;
      Option<SCode.Comment> cmtopt;
      list<String> ann_strl;
    // No comment.
    case (NONE()) then "";
    // String comment with possible annotation.
    case (SOME(SCode.COMMENT(annopt,SOME(cmt))))
      equation
        str = stringAppendList({" \"",cmt,"\""});
        str = str +& dumpAnnotationOptionStr(annopt);
      then
        str;
    // No string comment, but possible annotation.
    case (SOME(SCode.COMMENT(annopt,NONE())))
      equation
        str = dumpAnnotationOptionStr(annopt);
      then
        str;
    // Class comment, show annotations enabled.
    case (SOME(SCode.CLASS_COMMENT(annotations = annl, comment = cmtopt)))
      equation
        true = RTOpts.showAnnotations();
        str = dumpCommentOptionStr(cmtopt);
        ann_strl = Util.listMap1(Util.listMap(annl, dumpAnnotationStr), 
          stringAppend, ";");
        // If there is only one annotations, print it immediately after the
        // class name, otherwise print them in a list below the class name.
        str = str +& Util.if_((listLength(ann_strl) > 1), "\n ", "");
        str = str +& Util.stringDelimitList(ann_strl, "\n ");
      then
        str;
    // Class comment, show annotations disabled.
    case (SOME(SCode.CLASS_COMMENT(comment = cmtopt)))
      equation
        str = dumpCommentOptionStr(cmtopt);
      then
        str;
      end matchcontinue;
end dumpCommentOptionStr;

protected function dumpAnnotationOptionStr
  input Option<SCode.Annotation> inAnnotationOpt;
  output String outString;
algorithm
  outString := matchcontinue(inAnnotationOpt)
    local
      SCode.Annotation ann;
      String s;
    case SOME(ann)
      equation
        true = RTOpts.showAnnotations();
        s = dumpAnnotationStr(ann);
      then
        s;
    case _ then "";
  end matchcontinue;
end dumpAnnotationOptionStr;
  
protected function dumpAnnotationStr
  input SCode.Annotation inAnnotation;
  output String outString;
algorithm
  outString := match(inAnnotation)
    local
      SCode.Mod ann_mod;
      String s;
    case SCode.ANNOTATION(modification = ann_mod)
      equation
        s = " annotation" +& SCode.printModStr(ann_mod);
      then
        s;
  end match;
end dumpAnnotationStr;
    
protected function dumpCommentOption "function: dumpCommentOption_str
  Dump Comment option."
  input Option<SCode.Comment> comment;
  String str;
algorithm
  str := dumpCommentOptionStr(comment);
  Print.printBuf(str);
end dumpCommentOption;

protected function dumpEquation "function: dumpEquation
  Dump equation."
  input DAE.Element inElement;
algorithm
  _ := matchcontinue (inElement)
    local
      DAE.Exp e1,e2,e;
      DAE.ComponentRef c,cr1,cr2;
      Absyn.Path functionName;
      list<DAE.Exp> functionArgs;

    case (DAE.EQUATION(exp = e1,scalar = e2))
      equation
        Print.printBuf("  ");
        ExpressionDump.printExp(e1);
        Print.printBuf(" = ");
        ExpressionDump.printExp(e2);
        Print.printBuf(";\n");
      then
        ();

      case (DAE.EQUEQUATION(cr1=cr1,cr2=cr2))
      equation
        Print.printBuf("  ");
        ComponentReference.printComponentRef(cr1);
        Print.printBuf(" = ");
        ComponentReference.printComponentRef(cr2);
        Print.printBuf(";\n");
      then
        ();

    case (DAE.ARRAY_EQUATION(exp = e1,array= e2))
      equation
        Print.printBuf("  ");
        ExpressionDump.printExp(e1);
        Print.printBuf(" = ");
        ExpressionDump.printExp(e2);
        Print.printBuf(";\n");
      then
        ();

    case (DAE.COMPLEX_EQUATION(lhs = e1,rhs= e2))
      equation
        Print.printBuf("  ");
        ExpressionDump.printExp(e1);
        Print.printBuf(" = ");
        ExpressionDump.printExp(e2);
        Print.printBuf(";\n");
      then
        ();

    case (DAE.DEFINE(componentRef = c,exp = e))
      equation
        Print.printBuf("  ");
        ComponentReference.printComponentRef(c);
        Print.printBuf(" ::= ");
        ExpressionDump.printExp(e);
        Print.printBuf(";\n");
      then
        ();
    case (DAE.ASSERT(condition=e1,message=e2))
      equation
        Print.printBuf("assert(");
        ExpressionDump.printExp(e1);
        Print.printBuf(",");
        ExpressionDump.printExp(e2);
        Print.printBuf(");\n");
      then
        ();
    case (DAE.NORETCALL(functionName = functionName, functionArgs = functionArgs))
      equation
        Print.printBuf(Absyn.pathString(functionName));
        Print.printBuf("(");
        Print.printBuf(ExpressionDump.printExpListStr(functionArgs));
        Print.printBuf(");\n");
      then
        ();
    case _ then ();
  end matchcontinue;
end dumpEquation;

protected function dumpInitialEquation "function: dumpInitialequation
  Dump initial equation."
  input DAE.Element inElement;
algorithm
  _ := matchcontinue (inElement)
    local
      DAE.Exp e1,e2,e;
      DAE.ComponentRef c;
      list<DAE.Element> xs1,xs2;
      list<list<DAE.Element>> trueBranches;
      list<DAE.Exp> conds;
      String  s;
      IOStream.IOStream str;

    case (DAE.INITIALEQUATION(exp1 = e1,exp2 = e2))
      equation
        Print.printBuf("  ");
        ExpressionDump.printExp(e1);
        Print.printBuf(" = ");
        ExpressionDump.printExp(e2);
        Print.printBuf(";\n");
      then
        ();
    
    case (DAE.INITIALDEFINE(componentRef = c,exp = e))
      equation
        Print.printBuf("  ");
        ComponentReference.printComponentRef(c);
        Print.printBuf(" ::= ");
        ExpressionDump.printExp(e);
        Print.printBuf(";\n");
      then
        ();
    
    case (DAE.INITIAL_ARRAY_EQUATION(exp = e1, array = e2))
      equation
        Print.printBuf("  ");
        ExpressionDump.printExp(e1);
        Print.printBuf(" = ");
        ExpressionDump.printExp(e2);
        Print.printBuf(";\n");
      then
        ();
    
    case (DAE.INITIAL_COMPLEX_EQUATION(lhs = e1,rhs = e2))
      equation
        Print.printBuf("  ");
        ExpressionDump.printExp(e1);
        Print.printBuf(" = ");
        ExpressionDump.printExp(e2);
        Print.printBuf(";\n");
      then
        ();
    
    case (DAE.INITIAL_IF_EQUATION(condition1 = (e::conds),equations2 = (xs1::trueBranches),equations3 = xs2))
      equation
        Print.printBuf("  if ");
        ExpressionDump.printExp(e);
        Print.printBuf(" then\n");
        Util.listMap0(xs1,dumpInitialEquation);
        str = dumpIfEquationsStream(conds, trueBranches, IOStream.emptyStreamOfTypeList);
        s = IOStream.string(str);
        Print.printBuf(s);
        Print.printBuf("  else\n");
        Util.listMap0(xs2,dumpInitialEquation);
        Print.printBuf("end if;\n");
      then
        ();
    
    case _ then ();
  end matchcontinue;
end dumpInitialEquation;

public function dumpEquationStr "function: dumpEquationStr
  Dump equation to a string."
  input DAE.Element inElement;
  output String outString;
algorithm
  outString := matchcontinue (inElement)
    local
      String s1,s2,s3,s4,s5,str;
      DAE.Exp e1,e2,e;
      DAE.ComponentRef c,cr1,cr2;
      list<DAE.Exp> es;
      Absyn.Path path;

    case (DAE.EQUATION(exp = e1,scalar = e2))
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(s2, " = ");
        s4 = ExpressionDump.printExpStr(e2);
        s5 = stringAppend(s3, s4);
        str = stringAppend(s5, ";\n");
      then
        str;

     case (DAE.EQUEQUATION(cr1=cr1,cr2=cr2))
      equation
        s1 = ComponentReference.printComponentRefStr(cr1);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(s2, " = ");
        s4 = ComponentReference.printComponentRefStr(cr2);
        s5 = stringAppend(s3, s4);
        str = stringAppend(s5, ";\n");
      then
        str;

    case(DAE.ARRAY_EQUATION(exp=e1,array=e2)) equation
      s1 = ExpressionDump.printExpStr(e1);
      s2 = ExpressionDump.printExpStr(e2);
      str = "  " +& s1 +& " = " +& s2;
    then str;

    case(DAE.COMPLEX_EQUATION(lhs=e1,rhs=e2)) equation
      s1 = ExpressionDump.printExpStr(e1);
      s2 = ExpressionDump.printExpStr(e2);
      str = "  " +& s1 +& " = " +& s2;
    then str;

    case (DAE.DEFINE(componentRef = c,exp = e))
      equation
        s1 = ComponentReference.printComponentRefStr(c);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(" ::= ", s2);
        s4 = ExpressionDump.printExpStr(e);
        s5 = stringAppend(s3, s4);
        str = stringAppend(s5, ";\n");
      then
        str;

    case (DAE.ASSERT(condition=e1,message = e2))
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        str = stringAppendList({"  assert(",s1, ",",s2,");\n"});
      then
        str;

    case (DAE.TERMINATE(message=e1))
      equation
        s1 = ExpressionDump.printExpStr(e1);
        str = stringAppendList({"  terminate(",s1,");\n"});
      then
        str;

    case (DAE.NORETCALL(functionName=path,functionArgs=es))
      equation
        s1 = Absyn.pathString(path);
        s2 = ExpressionDump.printExpStr(DAE.TUPLE(es));
        str = stringAppendList({"  ",s1,s2,";\n"});
      then
        str;
    // adrpo: TODO! FIXME! should we say UNKNOWN equation here? we don't handle all cases!
    case _ then "#UNKNOWN_EQUATION#";
  end matchcontinue;
end dumpEquationStr;

public function dumpAlgorithm "function: dumpAlgorithm
  Dump algorithm."
  input DAE.Element inElement;
algorithm
  _ := matchcontinue (inElement)
    local list<DAE.Statement> stmts;
    case DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = stmts))
      equation
        Print.printBuf("algorithm\n");
        Dump.printList(stmts, ppStatement, "");
      then
        ();
    case _ then ();
  end matchcontinue;
end dumpAlgorithm;

protected function dumpInitialAlgorithm "function: dump_algorithm
  Dump initial algorithm."
  input DAE.Element inElement;
algorithm
  _ := matchcontinue (inElement)
    local list<DAE.Statement> stmts;
    case DAE.INITIALALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = stmts))
      equation
        Print.printBuf("initial algorithm\n");
        Dump.printList(stmts, ppStatement, "");
      then
        ();
    case _ then ();
  end matchcontinue;
end dumpInitialAlgorithm;

public function dumpFunctionNames "
  Author BZ
  print function names"
  input list<DAE.Function> fs;
  output list<String> names;
algorithm 
  names := matchcontinue(fs)
    local
      Absyn.Path p;
      String s1;

    case({}) then {};

    case(DAE.FUNCTION(path=p)::fs)
      equation
        s1 = Absyn.pathStringNoQual(p);
        names = dumpFunctionNames(fs);
      then
        s1::names;

    case(DAE.RECORD_CONSTRUCTOR(path=p)::fs)
      equation
        s1 = Absyn.pathStringNoQual(p);
        names = dumpFunctionNames(fs);
      then
        s1::names;

    case(_::fs) then dumpFunctionNames(fs);
  end matchcontinue;
end dumpFunctionNames;

protected function dumpExtObjectClass
"function: dumpExtObjectClass
  Dump External Object class"
  input DAE.Element inElement;
algorithm
  _ := matchcontinue (inElement)
    local
      String fstr;
      Absyn.Path fpath;
    case DAE.EXTOBJECTCLASS(path = fpath)
      equation
        Print.printBuf("class ");
        fstr = Absyn.pathString(fpath);
        Print.printBuf(fstr);
        Print.printBuf("\n extends ExternalObject;\n");
        Print.printBuf("end ");
        Print.printBuf(fstr);
        Print.printBuf(";\n");
      then
        ();
    case _ then ();
  end matchcontinue;
end dumpExtObjectClass;

public function derivativeCondStr "
  Author BZ
  Function for prinding conditions"
  input DAE.derivativeCond dc;
  output String str;
algorithm 
  str := matchcontinue(dc)
    local DAE.Exp e;
    
    case(DAE.NO_DERIVATIVE(e))
      equation
        str  = "noDerivative(" +& ExpressionDump.printExpStr(e) +& ")";
      then
        str;
    
    case(DAE.ZERO_DERIVATIVE()) then "zeroDerivative";
  end matchcontinue;
end derivativeCondStr;

public function dumpDerivativeCond "debug function "
  input list<tuple<Integer,DAE.derivativeCond>> conditionRefs;
  output list<String> oStrings;
algorithm 
  oStrings := matchcontinue( conditionRefs)
    local
      DAE.derivativeCond derCond;
      String s1;
      Integer name;
    
    case({}) then {};
    
    case((name,derCond)::conditionRefs)
      equation
        oStrings = dumpDerivativeCond(conditionRefs);
        s1 = derivativeCondStr(derCond);
        s1 = intString(name) +& " = " +& s1;
      then
        s1::oStrings;
  end matchcontinue;
end dumpDerivativeCond;

protected function dumpFunction
"function: dumpFunction
  Dump function"
  input DAE.Function inElement;
algorithm
  _ := matchcontinue (inElement)
    local
      String fstr,inlineTypeStr,daestr,str;
      Absyn.Path fpath;
      list<DAE.Element> daeElts;
      DAE.Type t;
      DAE.InlineType inlineType;
      String lang;
      Option<SCode.Comment> c;
    
    case DAE.FUNCTION(path = fpath,inlineType=inlineType,functions = (DAE.FUNCTION_DEF(body = daeElts)::_),type_ = t, comment = c)
      equation
        Print.printBuf("function ");
        fstr = Absyn.pathStringNoQual(fpath);
        Print.printBuf(fstr);
        inlineTypeStr = dumpInlineTypeStr(inlineType);
        Print.printBuf(inlineTypeStr);
        Print.printBuf(dumpCommentOptionStr(c));
        Print.printBuf("\n");
        dumpFunctionElements(daeElts);
        Print.printBuf("end ");
        Print.printBuf(fstr);
        Print.printBuf(";\n\n");
      then
        ();
      
    case DAE.FUNCTION(functions = (DAE.FUNCTION_EXT(externalDecl = DAE.EXTERNALDECL(language="builtin"))::_))
      then
        ();

    case DAE.FUNCTION(path = fpath,inlineType=inlineType,functions = (DAE.FUNCTION_EXT(body = daeElts, externalDecl = DAE.EXTERNALDECL(language=lang))::_),type_ = t, comment = c)
      equation
        Print.printBuf("function ");
        fstr = Absyn.pathStringNoQual(fpath);
        Print.printBuf(fstr);
        inlineTypeStr = dumpInlineTypeStr(inlineType);
        Print.printBuf(inlineTypeStr);
        Print.printBuf(dumpCommentOptionStr(c));
        Print.printBuf("\n");
        dumpFunctionElements(daeElts);
        Print.printBuf("\n  external \"C\";\n");
        Print.printBuf("end ");
        Print.printBuf(fstr);
        Print.printBuf(";\n\n");

      then
        ();
    
    case DAE.RECORD_CONSTRUCTOR(path = fpath,type_=t)
      equation
        Print.printBuf("function ");
        fstr = Absyn.pathStringNoQual(fpath);
        Print.printBuf(fstr);
        Print.printBuf(" \"Automatically generated record constructor for "+&fstr+&"\"\n");
        Print.printBuf(printRecordConstructorInputsStr(t));
        Print.printBuf("  output "+&Absyn.pathLastIdent(fpath)+& " res;\n");
        Print.printBuf("end ");
        Print.printBuf(fstr);
        Print.printBuf(";\n\n");
      then
        ();
    
    case _ then ();
  end matchcontinue;
end dumpFunction;

protected function dumpInlineTypeStr
  input DAE.InlineType inlineType;
  output String str;
algorithm
  str := match(inlineType)
    case(DAE.NO_INLINE()) then "";
    case(DAE.AFTER_INDEX_RED_INLINE()) then " \"Inline after index reduction\"";
    case(DAE.NORM_INLINE()) then " \"Inline before index reduction\"";
  end match;
end dumpInlineTypeStr;

protected function printRecordConstructorInputsStr "help function to dumpFunction. Prints the inputs of a record constructor"
  input DAE.Type tp;
  output String str;
algorithm
  str := matchcontinue(tp)
    local
      Option<Absyn.Path> optPath;
      Option<DAE.Type> optTp;
      DAE.EqualityConstraint ec;
      DAE.Binding binding;
      ClassInf.State cistate;
      String name,s1,s2;
      list<DAE.Var> varLst;

    // handle empty
    case((DAE.T_COMPLEX(complexVarLst={}),_)) then "";

    // protected vars are not input!, see Modelica Spec 3.2, Section 12.6, Record Constructor Functions, page 140
    case((DAE.T_COMPLEX(cistate,DAE.TYPES_VAR(name=name,visibility=SCode.PROTECTED(),ty=tp,binding=binding)::varLst,optTp,ec),optPath)) 
      equation
        s1 ="  protected "+&Types.unparseType(tp)+&" "+&name+&printRecordConstructorBinding(binding)+&";\n";
        s2 = printRecordConstructorInputsStr((DAE.T_COMPLEX(cistate,varLst,optTp,ec),optPath));
        str = s1 +&s2;
      then 
        str;

    // constants are not input! see Modelica Spec 3.2, Section 12.6, Record Constructor Functions, page 140
    case((DAE.T_COMPLEX(cistate,DAE.TYPES_VAR(name=name,attributes=DAE.ATTR(variability=SCode.CONST()),ty=tp,binding=binding)::varLst,optTp,ec),optPath)) 
      equation
        s1 ="  constant "+&Types.unparseType(tp)+&" "+&name+&printRecordConstructorBinding(binding)+&";\n";
        s2 = printRecordConstructorInputsStr((DAE.T_COMPLEX(cistate,varLst,optTp,ec),optPath));
        str = s1 +& s2;
      then 
        str;

    case((DAE.T_COMPLEX(cistate,DAE.TYPES_VAR(name=name,ty=tp,binding=binding)::varLst,optTp,ec),optPath)) 
      equation
        s1 ="  input "+&Types.unparseType(tp)+&" "+&name+&printRecordConstructorBinding(binding)+&";\n";
        s2 = printRecordConstructorInputsStr((DAE.T_COMPLEX(cistate,varLst,optTp,ec),optPath));
        str = s1 +& s2;
      then 
        str;

    case((DAE.T_FUNCTION(funcResultType=tp),_)) then printRecordConstructorInputsStr(tp);
    
  end matchcontinue;
end printRecordConstructorInputsStr;

protected function printRecordConstructorBinding "prints the binding of a record constructor input"
  input DAE.Binding binding;
  output String str;
algorithm
  str := match(binding)
    local DAE.Exp e; Values.Value v;
    case(DAE.UNBOUND()) then "";
    case(DAE.EQBOUND(exp=e, source=DAE.BINDING_FROM_DEFAULT_VALUE())) equation
      str = " = "+&ExpressionDump.printExpStr(e);
    then str;
    case(DAE.VALBOUND(valBound=v, source=DAE.BINDING_FROM_DEFAULT_VALUE())) equation
      str = " = " +& ValuesUtil.valString(v);
    then str;
  end match;
end printRecordConstructorBinding;

protected function ppStatement
"function: ppStatement
  Prettyprint an algorithm statement"
  input DAE.Statement alg;
algorithm
  ppStmt(alg, 2);
end ppStatement;

public function ppStatementStr
"function: ppStatementStr
  Prettyprint an algorithm statement to a string."
  input DAE.Statement alg;
  output String str;
algorithm
  str := ppStmtStr(alg, 2);
end ppStatementStr;

protected function ppStmt
"function: ppStmt
  Helper function to ppStatement."
  input DAE.Statement inStatement;
  input Integer inInteger;
algorithm
  _ := matchcontinue (inStatement,inInteger)
    local
      DAE.ComponentRef c;
      DAE.Exp e,cond,msg,e1,e2;
      Integer i,i_1;
      String s1,s2,s3,str,id;
      list<String> es;
      list<DAE.Exp> expl;
      list<DAE.Statement> then_,stmts;
      DAE.Statement stmt;
      Algorithm.Else else_;
    
    case (DAE.STMT_ASSIGN(exp1 = e2,exp = e),i)
      equation
        indent(i);
        ExpressionDump.printExp(e2);
        Print.printBuf(" := ");
        ExpressionDump.printExp(e);
        Print.printBuf(";\n");
      then
        ();
    
    case (DAE.STMT_ASSIGN_ARR(componentRef = c,exp = e),i)
      equation
        indent(i);
        ComponentReference.printComponentRef(c);
        Print.printBuf(" := ");
        ExpressionDump.printExp(e);
        Print.printBuf(";\n");
      then
        ();
    
    case (DAE.STMT_TUPLE_ASSIGN(expExpLst = expl,exp = e),i)
      equation
        s1 = indentStr(i);
        s2 = ExpressionDump.printExpStr(e);
        es = Util.listMap(expl, ExpressionDump.printExpStr);
        s3 = Util.stringDelimitList(es, ", ");
        str = stringAppendList({s1,"(",s3,") := ",s2,";\n"});
        Print.printBuf(str);
      then
        ();
    
    case (DAE.STMT_IF(exp = e,statementLst = then_,else_ = else_),i)
      equation
        indent(i);
        Print.printBuf("if ");
        ExpressionDump.printExp(e);
        Print.printBuf(" then\n");
        i_1 = i + 2;
        ppStmtList(then_, i_1);
        ppElse(else_, i);
        indent(i);
        Print.printBuf("end if;\n");
      then
        ();
    
    case (DAE.STMT_FOR(iter = id,range = e,statementLst = stmts),i)
      equation
        indent(i);
        Print.printBuf("for ");
        Print.printBuf(id);
        Print.printBuf(" in ");
        ExpressionDump.printExp(e);
        Print.printBuf(" loop\n");
        i_1 = i + 2;
        ppStmtList(stmts, i_1);
        indent(i);
        Print.printBuf("end for;\n");
      then
        ();
    
    case (DAE.STMT_WHILE(exp = e,statementLst = stmts),i)
      equation
        indent(i);
        Print.printBuf("while ");
        ExpressionDump.printExp(e);
        Print.printBuf(" loop\n");
        i_1 = i + 2;
        ppStmtList(stmts, i_1);
        indent(i);
        Print.printBuf("end while;\n");
      then
        ();
    
    case (DAE.STMT_NORETCALL(exp = e1),i)
      equation
        indent(i);
        ExpressionDump.printExp(e1);
        Print.printBuf(";\n");
      then
        ();
    
    case (stmt as DAE.STMT_WHEN(exp = _),i)
      equation
        indent(i);
        Print.printBuf(ppWhenStmtStr(stmt,1));
      then
        ();
    
    case (DAE.STMT_ASSERT(cond = cond,msg = msg),i)
      equation
        indent(i);
        Print.printBuf("assert( ");
        ExpressionDump.printExp(cond);
        Print.printBuf(", ");
        ExpressionDump.printExp(msg);
        Print.printBuf(");\n");
      then
        ();
    
    case (DAE.STMT_RETURN(source = _),i)
      equation
        indent(i);
        Print.printBuf("return;\n");
      then
        ();
    
    case (DAE.STMT_BREAK(source = _),i)
      equation
        indent(i);
        Print.printBuf("break;\n");
      then
        ();
    
    case (DAE.STMT_REINIT(var = e1, value = e2),i)
      equation
        indent(i);
        Print.printBuf("reinit(");
        ExpressionDump.printExp(e1);
        Print.printBuf(",");
        ExpressionDump.printExp(e2);
        Print.printBuf(");\n");
      then
        ();
    
    case (DAE.STMT_FAILURE(body = stmts),i)
      equation
        indent(i);
        Print.printBuf("begin failure\n");
        ppStmtList(stmts, i+2);
        Print.printBuf("end try;\n");
      then
        ();
    
    case (DAE.STMT_TRY(tryBody = stmts),i)
      equation
        indent(i);
        Print.printBuf("try\n");
        ppStmtList(stmts, i+2);
        Print.printBuf("end try;\n");
      then
        ();
    
    case (DAE.STMT_CATCH(catchBody = stmts),i)
      equation
        indent(i);
        Print.printBuf("catch\n");
        ppStmtList(stmts, i+2);
        Print.printBuf("end catch;\n");
      then
        ();
    
    case (_,i)
      equation
        indent(i);
        Print.printBuf("**ALGORITHM**;\n");
      then
        ();
  end matchcontinue;
end ppStmt;


protected function ppWhenStmtStr
  input DAE.Statement inStatement;
  input Integer inInteger;
  output String outString;
algorithm
  outString:=
  match (inStatement,inInteger)
    local
      String s3,s4,s5,s6,str,s7,s8,s9,s10;
      DAE.Exp e;
      Integer i,i_1;
      list<DAE.Statement> stmts;
      DAE.Statement stmt;
    case (DAE.STMT_WHEN(exp = e,statementLst = stmts, elseWhen=NONE()),i)
      equation
        s3 = stringAppend("when ",ExpressionDump.printExpStr(e));
        s5 = stringAppend(s3, " then\n");
        i_1 = i + 2;
        s6 = ppStmtListStr(stmts, i_1);
        s7 = stringAppend(s5, s6);
        s8 = indentStr(i);
        s9 = stringAppend(s7, s8);
        str = stringAppend(s9, "end when;\n");
      then
        str;
    case (DAE.STMT_WHEN(exp = e,statementLst = stmts, elseWhen=SOME(stmt)),i)
      equation
        s3 = ExpressionDump.printExpStr(e);
        s4 = stringAppend("when ", s3);
        s5 = stringAppend(s4, " then\n");
        i_1 = i + 2;
        s6 = ppStmtListStr(stmts, i_1);
        s7 = stringAppend(s5, s6);
        s8 = ppWhenStmtStr(stmt,i);
        s9 = stringAppend(indentStr(i),"else");
        s10= stringAppend(s7,s9);
        str = stringAppend(s10, s8);
      then
        str;
   end match;
end ppWhenStmtStr;

public function ppStmtStr
  "Helper function to ppStatementStr"
  input DAE.Statement inStatement;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inStatement,inInteger)
    local
      String s1,s2,s3,s4,s5,s6,str,s7,s8,s9,s10,s11,id,cond_str,msg_str,e1_str,e2_str;
      DAE.ComponentRef c;
      DAE.Exp e,cond,msg,e1,e2;
      Integer i,i_1;
      list<String> es;
      list<DAE.Exp> expl;
      list<DAE.Statement> then_,stmts;
      DAE.Statement stmt;
      Algorithm.Else else_;
    
    case (DAE.STMT_ASSIGN(exp1 = e2,exp = e),i)
      equation
        s1 = indentStr(i);
        s2 = ExpressionDump.printExpStr(e2);
        s3 = ExpressionDump.printExpStr(e);
        str = stringAppendList({s1,s2," := ",s3,";\n"});
      then
        str;

    case (DAE.STMT_ASSIGN_ARR(componentRef = c,exp = e),i)
      equation
        s1 = indentStr(i);
        s2 = ComponentReference.printComponentRefStr(c);
        s3 = ExpressionDump.printExpStr(e);
        str = stringAppendList({s1,s2," := ",s3,";\n"});
      then
        str;
    
    case (DAE.STMT_TUPLE_ASSIGN(expExpLst = expl,exp = e),i)
      equation
        s1 = indentStr(i);
        s2 = ExpressionDump.printExpStr(e);
        es = Util.listMap(expl, ExpressionDump.printExpStr);
        s3 = Util.stringDelimitList(es, ", ");
        str = stringAppendList({s1,"(",s3,") := ",s2,";\n"});
      then
        str;
    
    case (DAE.STMT_IF(exp = e,statementLst = then_,else_ = else_),i)
      equation
        s1 = indentStr(i);
        s2 = stringAppend(s1, "if ");
        s3 = ExpressionDump.printExpStr(e);
        s4 = stringAppend(s2, s3);
        s5 = stringAppend(s4, " then\n");
        i_1 = i + 2;
        s6 = ppStmtListStr(then_, i_1);
        s7 = stringAppend(s5, s6);
        s8 = ppElseStr(else_, i);
        s9 = stringAppend(s7, s8);
        s10 = indentStr(i);
        s11 = stringAppend(s9, s10);
        str = stringAppend(s11, "end if;\n");
      then
        str;
    
    case (DAE.STMT_FOR(iter = id,range = e,statementLst = stmts),i)
      equation
        s1 = indentStr(i);
        s2 = stringAppend(s1, "for ");
        s3 = stringAppend(s2, id);
        s4 = stringAppend(s3, " in ");
        s5 = ExpressionDump.printExpStr(e);
        s6 = stringAppend(s4, s5);
        s7 = stringAppend(s6, " loop\n");
        i_1 = i + 2;
        s8 = ppStmtListStr(stmts, i_1);
        s9 = stringAppend(s7, s8);
        s10 = indentStr(i);
        s11 = stringAppend(s9, s10);
        str = stringAppend(s11, "end for;\n");
      then
        str;
    
    case (DAE.STMT_WHILE(exp = e,statementLst = stmts),i)
      equation
        s1 = indentStr(i);
        s2 = stringAppend(s1, "while ");
        s3 = ExpressionDump.printExpStr(e);
        s4 = stringAppend(s2, s3);
        s5 = stringAppend(s4, " loop\n");
        i_1 = i + 2;
        s6 = ppStmtListStr(stmts, i_1);
        s7 = stringAppend(s5, s6);
        s8 = indentStr(i);
        s9 = stringAppend(s7, s8);
        str = stringAppend(s9, "end while;\n");
      then
        str;
    
    case (stmt as DAE.STMT_WHEN(exp = _),i)
      equation
        s1 = indentStr(i);
        s2 = ppWhenStmtStr(stmt,i);
        str = stringAppend(s1,s2);
      then
        str;
    
    case (DAE.STMT_ASSERT(cond = cond,msg = msg),i)
      equation
        s1 = indentStr(i);
        cond_str = ExpressionDump.printExpStr(cond);
        msg_str = ExpressionDump.printExpStr(msg);
        str = stringAppendList({s1,"assert(",cond_str,", ",msg_str,");\n"});
      then
        str;

    case (DAE.STMT_TERMINATE(msg = msg),i)
      equation
        s1 = indentStr(i);
        msg_str = ExpressionDump.printExpStr(msg);
        str = stringAppendList({s1,"terminate(",msg_str,");\n"});
      then
        str;

    case (DAE.STMT_NORETCALL(exp = e),i)
      equation
        s1 = indentStr(i);
        s2 = ExpressionDump.printExpStr(e);
        str = stringAppendList({s1,s2,";\n"});
      then
        str;

    case (DAE.STMT_BREAK(source = _),i)
      equation
        s1 = indentStr(i);
        str = stringAppend(s1, "break;\n");
      then
        str;
    
    case (DAE.STMT_REINIT(var = e1, value = e2),i)
      equation
        s1 = indentStr(i);
        e1_str = ExpressionDump.printExpStr(e1);
        e2_str = ExpressionDump.printExpStr(e2);
        str = stringAppendList({s1,"reinit(",e1_str,", ",e2_str,");\n"});
      then str;
        
    case (DAE.STMT_FAILURE(body=stmts),i)
      equation
        s1 = indentStr(i);
        s2 = ppStmtListStr(stmts, i+2);
        str = stringAppendList({s1,"failure(\n",s2,s1,");\n"});
      then str;
        
    case (_,i)
      equation
        s1 = indentStr(i);
        str = stringAppend(s1, "**ALGORITHM COULD NOT BE GENERATED(DAE.mo)**;\n");
      then
        str;
  end matchcontinue;
end ppStmtStr;

protected function ppStmtList "function: ppStmtList

  Helper function to pp_stmt
"
  input list<DAE.Statement> inAlgorithmStatementLst;
  input Integer inInteger;
algorithm
  _:=
  match (inAlgorithmStatementLst,inInteger)
    local
      DAE.Statement stmt;
      list<DAE.Statement> stmts;
      Integer i;
    case ({},_) then ();
    case ((stmt :: stmts),i)
      equation
        ppStmt(stmt, i);
        ppStmtList(stmts, i);
      then
        ();
  end match;
end ppStmtList;

protected function ppStmtListStr "function: ppStmtListStr

  Helper function to pp_stmt_str
"
  input list<DAE.Statement> inAlgorithmStatementLst;
  input Integer inInteger;
  output String outString;
algorithm
  outString:=
  match (inAlgorithmStatementLst,inInteger)
    local
      String s1,s2,str;
      DAE.Statement stmt;
      list<DAE.Statement> stmts;
      Integer i;
    case ({},_) then "";
    case ((stmt :: stmts),i)
      equation
        s1 = ppStmtStr(stmt, i);
        s2 = ppStmtListStr(stmts, i);
        str = stringAppend(s1, s2);
      then
        str;
  end match;
end ppStmtListStr;

protected function ppElse "function: ppElse

  Helper function to pp_stmt
"
  input Algorithm.Else inElse;
  input Integer inInteger;
algorithm
  _:=
  match (inElse,inInteger)
    local
      Integer i_1,i;
      DAE.Exp e;
      list<DAE.Statement> then_,stmts;
      Algorithm.Else else_;
    case (DAE.NOELSE(),_) then ();
    case (DAE.ELSEIF(exp = e,statementLst = then_,else_ = else_),i)
      equation
        indent(i);
        Print.printBuf("elseif ");
        ExpressionDump.printExp(e);
        Print.printBuf(" then\n");
        i_1 = i + 2;
        ppStmtList(then_, i_1);
        ppElse(else_, i);
      then
        ();
    case (DAE.ELSE(statementLst = stmts),i)
      equation
        indent(i);
        Print.printBuf("else\n");
        i_1 = i + 2;
        ppStmtList(stmts, i_1);
      then
        ();
  end match;
end ppElse;

protected function ppElseStr "function: pp_else

  Helper function to ppElseStr
"
  input Algorithm.Else inElse;
  input Integer inInteger;
  output String outString;
algorithm
  outString:=
  match (inElse,inInteger)
    local
      String s1,s2,s3,s4,s5,s6,s7,s8,str;
      Integer i_1,i;
      DAE.Exp e;
      list<DAE.Statement> then_,stmts;
      Algorithm.Else else_;
    case (DAE.NOELSE(),_) then "";
    case (DAE.ELSEIF(exp = e,statementLst = then_,else_ = else_),i)
      equation
        s1 = indentStr(i);
        s2 = stringAppend(s1, "elseif ");
        s3 = ExpressionDump.printExpStr(e);
        s4 = stringAppend(s2, s3);
        s5 = stringAppend(s4, " then\n");
        i_1 = i + 2;
        s6 = ppStmtListStr(then_, i_1);
        s7 = stringAppend(s5, s6);
        s8 = ppElseStr(else_, i);
        str = stringAppend(s7, s8);
      then
        str;
    case (DAE.ELSE(statementLst = stmts),i)
      equation
        s1 = indentStr(i);
        s2 = stringAppend(s1, "else\n");
        i_1 = i + 2;
        s3 = ppStmtListStr(stmts, i_1);
        str = stringAppend(s2, s3);
      then
        str;
  end match;
end ppElseStr;

protected function indent "function: indent

  Print an indentation, given an indent level.
"
  input Integer inInteger;
algorithm
  _:=
  matchcontinue (inInteger)
    local Integer i_1,i;
    case 0 then ();
    case i
      equation
        Print.printBuf(" ");
        i_1 = i - 1;
        indent(i_1);
      then
        ();
  end matchcontinue;
end indent;

protected function indentStr "function: indentStr

  Print an indentation to a string, given an indent level.
"
  input Integer inInteger;
  output String outString;
algorithm
  outString:=
  matchcontinue (inInteger)
    local
      Integer i_1,i;
      String s1,str;
    case 0 then "";
    case i
      equation
        i_1 = i - 1;
        s1 = indentStr(i_1);
        str = stringAppend(" ", s1);
      then
        str;
  end matchcontinue;
end indentStr;

public function dumpDebug "

 Dump the data structures in a
 paranthesised way

"
  input DAE.DAElist inDAElist;
algorithm
  _:=
  match (inDAElist)
    local list<DAE.Element> elist;
    case DAE.DAE(elementLst = elist)
      equation
        Print.printBuf("DAE(");
        dumpDebugElist(elist);
        Print.printBuf(")");
      then
        ();
  end match;
end dumpDebug;

protected function dumpDebugElist "function: dumpDebugElist

  Helper function to dump_debug.
"
  input list<DAE.Element> inElementLst;
algorithm
  _:=
  match (inElementLst)
    local
      DAE.Element first;
      list<DAE.Element> rest;
    case {} then ();
    case (first :: rest)
      equation
        dumpDebugElement(first);
        Print.printBuf("\n");
        dumpDebugElist(rest);
      then
        ();
  end match;
end dumpDebugElist;

public function dumpDebugDAE ""
  input DAE.DAElist dae;
  output String str;
algorithm
  str := match (dae)
    local
      list<DAE.Element> elems;
    case(DAE.DAE(elementLst=elems))
      equation
        Print.clearBuf();
        dumpDebugElist(elems);
        str = Print.getString();
      then
        str;
  end match;
end dumpDebugDAE;

public function dumpDebugElement "function: dumpDebugElement

  Dump element using parenthesis.
"
  input DAE.Element inElement;
algorithm
  _:=
  matchcontinue (inElement)
    local
      String comment_str,tmp_str,n;
      DAE.ComponentRef cr,cr1,cr2;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Exp e,exp,e1,e2;
      list<DAE.Element> l;
    case DAE.VAR(componentRef = cr,
             kind = vk,
             direction = vd,
             binding = NONE(),
             variableAttributesOption = dae_var_attr,
             absynCommentOption = comment)
      equation
        Print.printBuf("VAR(");
        ComponentReference.printComponentRef(cr);
        Print.printBuf(", ");
        dumpKind(vk);
        comment_str = dumpCommentOptionStr(comment);
        Print.printBuf("  comment:");
        Print.printBuf(comment_str);
        tmp_str = dumpVariableAttributesStr(dae_var_attr);
        Print.printBuf(tmp_str);
        Print.printBuf(")");
      then
        ();
    case DAE.VAR(componentRef = cr,
             kind = vk,
             direction = vd,
             binding = SOME(e),
             variableAttributesOption = dae_var_attr,
             absynCommentOption = comment)
      equation
        Print.printBuf("VAR(");
        ComponentReference.printComponentRef(cr);
        Print.printBuf(", ");
        dumpKind(vk);
        Print.printBuf(", binding: ");
        ExpressionDump.printExp(e);
        comment_str = dumpCommentOptionStr(comment);
        Print.printBuf("  comment:");
        Print.printBuf(comment_str);
        tmp_str = dumpVariableAttributesStr(dae_var_attr);
        Print.printBuf(tmp_str);
        Print.printBuf(")");
      then
        ();
    case DAE.DEFINE(componentRef = cr,exp = exp)
      equation
        Print.printBuf("DEFINE(");
        ComponentReference.printComponentRef(cr);
        Print.printBuf(", ");
        ExpressionDump.printExp(exp);
        Print.printBuf(")");
      then
        ();
    case DAE.INITIALDEFINE(componentRef = cr,exp = exp)
      equation
        Print.printBuf("INITIALDEFINE(");
        ComponentReference.printComponentRef(cr);
        Print.printBuf(", ");
        ExpressionDump.printExp(exp);
        Print.printBuf(")");
      then
        ();
    case DAE.EQUATION(exp = e1,scalar = e2)
      equation
        Print.printBuf("EQUATION(");
        ExpressionDump.printExp(e1);
        Print.printBuf(",");
        ExpressionDump.printExp(e2);
        Print.printBuf(")");
      then
        ();

     case DAE.EQUEQUATION(cr1=cr1,cr2=cr2)
      equation
        Print.printBuf("EQUATION(");
        ComponentReference.printComponentRef(cr1);
        Print.printBuf(",");
        ComponentReference.printComponentRef(cr2);
        Print.printBuf(")");
      then
        ();
    case DAE.INITIALEQUATION(exp1 = e1,exp2 = e2)
      equation
        Print.printBuf("INITIALEQUATION(");
        ExpressionDump.printExp(e1);
        Print.printBuf(",");
        ExpressionDump.printExp(e2);
        Print.printBuf(")");
      then
        ();
    case DAE.ALGORITHM(algorithm_ = _)
      equation
        Print.printBuf("ALGORITHM()");
      then
        ();
    case DAE.INITIALALGORITHM(algorithm_ = _)
      equation
        Print.printBuf("INITIALALGORITHM()");
      then
        ();
    case DAE.COMP(ident = n,dAElist = l)
      equation
        Print.printBuf("COMP(");
        Print.printBuf(n);
        Print.printBuf(",");
        dumpDebugElist(l);
        Print.printBuf(")");
      then
        ();
    case DAE.ARRAY_EQUATION(exp = e1,array = e2)
      equation
        Print.printBuf("ARRAY_EQUATION(");
        ExpressionDump.printExp(e1);
        Print.printBuf(",");
        ExpressionDump.printExp(e2);
        Print.printBuf(")");
      then
        ();
    case DAE.INITIAL_ARRAY_EQUATION(exp = e1,array = e2)
      equation
        Print.printBuf("INITIAL_ARRAY_EQUATION(");
        ExpressionDump.printExp(e1);
        Print.printBuf(",");
        ExpressionDump.printExp(e2);
        Print.printBuf(")");
      then
        ();
    case DAE.COMPLEX_EQUATION(lhs = e1,rhs = e2)
      equation
        Print.printBuf("COMPLEX_EQUATION(");
        ExpressionDump.printExp(e1);
        Print.printBuf(",");
        ExpressionDump.printExp(e2);
        Print.printBuf(")");
      then
        ();
    case DAE.INITIAL_COMPLEX_EQUATION(lhs = e1,rhs = e2)
      equation
        Print.printBuf("INITIAL_COMPLEX_EQUATION(");
        ExpressionDump.printExp(e1);
        Print.printBuf(",");
        ExpressionDump.printExp(e2);
        Print.printBuf(")");
      then
        ();
    case DAE.IF_EQUATION(condition1 = _)
      equation
        Print.printBuf("IF_EQUATION()");
      then
        ();
    case DAE.INITIAL_IF_EQUATION(condition1 = _)
      equation
        Print.printBuf("INITIAL_IF_EQUATION()");
      then
        ();
    case DAE.WHEN_EQUATION(condition = _)
      equation
        Print.printBuf("WHEN_EQUATION()");
      then
        ();
    case DAE.EXTOBJECTCLASS(path = _)
      equation
        Print.printBuf("EXTOBJECTCLASS()");
      then
        ();
    case DAE.ASSERT(condition = e1,message = e2)
      equation
        Print.printBuf("ASSERT(");
        ExpressionDump.printExp(e1);
        Print.printBuf(",");
        ExpressionDump.printExp(e2);
        Print.printBuf(")");
      then
        ();
    case DAE.TERMINATE(message = e1)
      equation
        Print.printBuf("TERMINATE(");
        ExpressionDump.printExp(e1);
        Print.printBuf(")");
      then
        ();
    case DAE.REINIT(exp = e1)
      equation
        Print.printBuf("REINIT()");
      then
        ();
    case DAE.NORETCALL(functionName = _)
      equation
        Print.printBuf("NORETCALL()");
      then
        ();
    case _
      equation
        Print.printBuf("UNKNOWN ");
      then
        ();
  end matchcontinue;
end dumpDebugElement;

public function dumpFlow "
Author BZ 2008-07, dump flow properties to string."
  input DAE.Flow var;
  output String flowString;
algorithm
  flowString := matchcontinue(var)
    case DAE.FLOW() then "flow";
    case DAE.NON_FLOW() then "effort";
    case DAE.NON_CONNECTOR() then "non_connector";
  end matchcontinue;
end dumpFlow;

public function dumpGraphviz "
 Graphviz functions to visualize
 the dae
"
  input DAE.DAElist dae;
  Graphviz.Node r;
algorithm
  r := buildGraphviz(dae);
  Graphviz.dump(r);
end dumpGraphviz;

protected function buildGraphviz "function: buildGraphviz

  Builds the graphviz node from a dae list.
"
  input DAE.DAElist inDAElist;
  output Graphviz.Node outNode;
algorithm
  outNode:=
  match (inDAElist)
    local
      list<DAE.Element> vars,nonvars,els;
      list<Graphviz.Node> nonvarnodes,varnodes,nodelist;
    case DAE.DAE(elementLst = els)
      equation
        vars = DAEUtil.getMatchingElements(els, DAEUtil.isVar);
        nonvars = DAEUtil.getMatchingElements(els, DAEUtil.isNotVar);
        nonvarnodes = buildGrList(nonvars);
        varnodes = buildGrVars(vars);
        nodelist = listAppend(nonvarnodes, varnodes);
      then
        Graphviz.NODE("DAE",{},nodelist);
  end match;
end buildGraphviz;

protected function buildGrList "function buildGrList

  Helper function to build_graphviz.
"
  input list<DAE.Element> inElementLst;
  output list<Graphviz.Node> outGraphvizNodeLst;
algorithm
  outGraphvizNodeLst:=
  match (inElementLst)
    local
      Graphviz.Node node;
      list<Graphviz.Node> nodelist;
      DAE.Element el;
      list<DAE.Element> rest;
    case {} then {};
    case (el :: rest)
      equation
        node = buildGrElement(el);
        nodelist = buildGrList(rest);
      then
        (node :: nodelist);
  end match;
end buildGrList;

protected function buildGrVars "function buildGrVars

  Helper function to build_graphviz.
"
  input list<DAE.Element> inElementLst;
  output list<Graphviz.Node> outGraphvizNodeLst;
algorithm
  outGraphvizNodeLst := matchcontinue (inElementLst)
    local
      list<String> strlist;
      list<DAE.Element> vars;
    case {} then {};
    case vars
      equation
        (strlist,_) = buildGrStrlist(vars, buildGrVarStr, 10);
      then
        {Graphviz.LNODE("VARS",strlist,{Graphviz.box},{})};
  end matchcontinue;
end buildGrVars;

public function buildGrStrlist "function buildGrStrlist

  Helper function to build_graphviz.
"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToString inFuncTypeTypeAToString;
  input Integer inInteger;
  output list<String> outStringLst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToString
    input Type_a inTypeA;
    output String outString;
  end FuncTypeType_aToString;
algorithm
  (outStringLst,outTypeALst):=
  matchcontinue (inTypeALst,inFuncTypeTypeAToString,inInteger)
    local
      list<Type_a> ignored,rest;
      FuncTypeType_aToString printer;
      Integer count,count_1;
      list<String> strlist;
      String str;
      Type_a var;
    case ({},_,_) then ({},{});
    case (ignored,printer,count)
      equation
        (count <= 0) = true;
      then
        ({"..."},ignored);
    case ((var :: rest),printer,count)
      equation
        (count > 0) = true;
        count_1 = count - 1;
        (strlist,ignored) = buildGrStrlist(rest, printer, count_1);
        str = printer(var);
      then
        ((str :: strlist),ignored);
  end matchcontinue;
end buildGrStrlist;

protected function buildGrVarStr "function buildGrVarStr

  Helper function to build_graphviz.
"
  input DAE.Element inElement;
  output String outString;
algorithm
  outString:=
  match (inElement)
    local
      String str,expstr,str_1,str_2;
      DAE.ComponentRef cr;
      DAE.Exp exp;
    case DAE.VAR(componentRef = cr,binding = NONE())
      equation
        str = ComponentReference.printComponentRefStr(cr);
      then
        str;
    case DAE.VAR(componentRef = cr,binding = SOME(exp))
      equation
        str = ComponentReference.printComponentRefStr(cr);
        expstr = printExpStrSpecial(exp);
        str_1 = stringAppend(str, " = ");
        str_2 = stringAppend(str_1, expstr);
      then
        str_2;
  end match;
end buildGrVarStr;

protected function printExpStrSpecial "function: printExpStrSpecial

  Prints an expression to a string suitable for graphviz.
"
  input DAE.Exp inExp;
  output String outString;
algorithm
  outString:=
  matchcontinue (inExp)
    local
      String s_1,s_2,s,str;
      DAE.Exp exp;
    case DAE.SCONST(string = s)
      equation
        s_1 = stringAppend("\\\"", s);
        s_2 = stringAppend(s_1, "\\\"");
      then
        s_2;
    case exp
      equation
        str = ExpressionDump.printExpStr(exp);
      then
        str;
  end matchcontinue;
end printExpStrSpecial;

protected function buildGrElement "function: buildGrElement

  Builds a Graphviz.Node from an element.
"
  input DAE.Element inElement;
  output Graphviz.Node outNode;
algorithm
  outNode := match (inElement)
    local
      String crstr,vkstr,expstr,expstr_1,e1str,e2str,n;
      DAE.ComponentRef cr,cr1,cr2;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.Exp exp,e1,e2;
      list<Graphviz.Node> nodes;
      list<DAE.Element> elts;
    case DAE.VAR(componentRef = cr,kind = vk,direction = vd,binding = NONE())
      equation
        crstr = ComponentReference.printComponentRefStr(cr);
        vkstr = dumpKindStr(vk);
      then
        Graphviz.LNODE("VAR",{crstr,vkstr},{},{});
    case DAE.VAR(componentRef = cr,kind = vk,direction = vd,binding = SOME(exp))
      equation
        crstr = ComponentReference.printComponentRefStr(cr);
        vkstr = dumpKindStr(vk);
        expstr = printExpStrSpecial(exp);
        expstr_1 = stringAppend("= ", expstr);
      then
        Graphviz.LNODE("VAR",{crstr,vkstr,expstr_1},{},{});
    case DAE.DEFINE(componentRef = cr,exp = exp)
      equation
        crstr = ComponentReference.printComponentRefStr(cr);
        expstr = printExpStrSpecial(exp);
        expstr_1 = stringAppend("= ", expstr);
      then
        Graphviz.LNODE("DEFINE",{crstr,expstr_1},{},{});
    case DAE.EQUATION(exp = e1,scalar = e2)
      equation
        e1str = printExpStrSpecial(e1);
        e2str = printExpStrSpecial(e2);
      then
        Graphviz.LNODE("EQUATION",{e1str,"=",e2str},{},{});
    case DAE.EQUEQUATION(cr1=cr1,cr2=cr2)
      equation
        e1str = printExpStrSpecial(Expression.crefExp(cr1));
        e2str = printExpStrSpecial(Expression.crefExp(cr2));
      then
        Graphviz.LNODE("EQUEQUATION",{e1str,"=",e2str},{},{});
    case DAE.ALGORITHM(algorithm_ = _) then Graphviz.NODE("ALGORITHM",{},{});
    case DAE.INITIALDEFINE(componentRef = cr,exp = exp)
      equation
        crstr = ComponentReference.printComponentRefStr(cr);
        expstr = printExpStrSpecial(exp);
        expstr_1 = stringAppend("= ", expstr);
      then
        Graphviz.LNODE("INITIALDEFINE",{crstr,expstr_1},{},{});
    case DAE.INITIALEQUATION(exp1 = e1,exp2 = e2)
      equation
        e1str = printExpStrSpecial(e1);
        e2str = printExpStrSpecial(e2);
      then
        Graphviz.LNODE("INITIALEQUATION",{e1str,"=",e2str},{},{});
    case DAE.INITIALALGORITHM(algorithm_ = _) then Graphviz.NODE("INITIALALGORITHM",{},{});
    case DAE.COMP(ident = n,dAElist = elts)
      equation
        nodes = buildGrList(elts);
      then
        Graphviz.LNODE("COMP",{n},{},nodes);
  end match;
end buildGrElement;

protected function unparseType "wrapper function for Types.unparseType, so records and enumerations can be output properly"
  input Types.Type tp;
  output String str;
algorithm
  str := matchcontinue(tp)
    local
      String name; Absyn.Path path;
      Types.Type bc_tp;

    case((DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_)),SOME(path))) equation
      name = Absyn.pathStringNoQual(path);
    then name;

    case((DAE.T_COMPLEX(complexTypeOption = SOME(bc_tp)),_)) then Types.unparseType(bc_tp);

    case(tp) then Types.unparseType(tp);
  end matchcontinue;
end unparseType;

public function unparseDimensions
"prints dimensions to a string"
  input DAE.InstDims dims;
  input Boolean printTypeDimension "use true here when printing components in functions as these are not vectorized! Otherwise, use false";
  output String dimsStr;
algorithm
  dimsStr := matchcontinue(dims, printTypeDimension)
    local
      String str;

    // false gives nothing
    case (_, false) then "";

    // nothing gives nothing
    case ({}, true) then "";
    // dims give something
    case (dims, true)
     equation
       str = "[" +& Util.stringDelimitList(Util.listMap(dims, ExpressionDump.printSubscriptStr), ", ") +& "]";
     then
       str;
  end matchcontinue;
end unparseDimensions;

public function dumpStr "function: dumpStr
  This function prints the DAE to a string."
  input DAE.DAElist inDAElist;
  input DAE.FunctionTree functionTree;
  output String outString;
algorithm
  outString := match (inDAElist,functionTree)
    local      
      IOStream.IOStream myStream;
      String str;

    case (inDAElist,functionTree)
      equation
        myStream = IOStream.create("dae", IOStream.LIST());
        myStream = dumpStream(inDAElist, functionTree, myStream);
        str = IOStream.string(myStream);
      then
        str;
  end match;
end dumpStr;

public function dumpElementsStr "function: dumpElementsStr
  This function prints the DAE to a string."
  input list<DAE.Element> els;
  output String outString;
algorithm
  outString := match (els)
    local      
      IOStream.IOStream myStream;
      String str;

    case (els)
      equation
        myStream = IOStream.create("dae", IOStream.LIST());
        myStream = dumpElementsStream(els, myStream);
        str = IOStream.string(myStream);
      then
        str;
  end match;
end dumpElementsStr;

public function dumpAlgorithmsStr "function: dumpAlgorithmsStr
  This function prints the algorithms to a string."
  input list<DAE.Element> algs;
  output String outString;
algorithm
  outString := match (algs)
    local      
      IOStream.IOStream myStream;
      String str;

    case (algs)
      equation
        myStream = IOStream.create("algs", IOStream.LIST());
        myStream = dumpAlgorithmsStream(algs, myStream);
        str = IOStream.string(myStream);
      then
        str;
  end match;
end dumpAlgorithmsStr;


/************ IOStream based implementation ***************/
/************ IOStream based implementation ***************/
/************ IOStream based implementation ***************/
/************ IOStream based implementation ***************/

public function dumpStream "function: dumpStream
  This function prints the DAE to a stream."
  input DAE.DAElist dae;
  input DAE.FunctionTree functionTree;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := match (dae,functionTree,inStream)
    local      
      list<DAE.Element> daelist;
      list<DAE.Function> funcs;
      IOStream.IOStream str;

    case (DAE.DAE(daelist), functionTree, str)
      equation
        funcs = DAEUtil.getFunctionList(functionTree);
        funcs = sortFunctions(funcs);
        str = Util.listFold(funcs, dumpFunctionStream, str);
        str = IOStream.appendList(str, Util.listMap(daelist, dumpExtObjClassStr));
        str = Util.listFold(daelist, dumpCompElementStream, str);
      then
        str;
  end match;
end dumpStream;

protected function dumpCompElementStream "function: dumpCompElementStream
  Dumps components to a stream."
  input DAE.Element inElement;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := matchcontinue (inElement, inStream)
    local
      String n;
      list<DAE.Element> l;
      Option<SCode.Comment> c;
      IOStream.IOStream str;

    case (DAE.COMP(ident = n,dAElist = l,comment = c), str)
      equation
        str = IOStream.append(str, "class ");
        str = IOStream.append(str, n);
        str = IOStream.append(str, dumpCommentOptionStr(c));
        str = IOStream.append(str, "\n");
        str = dumpElementsStream(l, str);
        str = IOStream.append(str, "end ");
        str = IOStream.append(str, n);
        str = IOStream.append(str, ";\n");
      then
        str;

    case (_, str) then str;  /* LS: for non-COMPS, which are only FUNCTIONS at the moment */
  end matchcontinue;
end dumpCompElementStream;

public function dumpElementsStream "function: dumpElementsStream
  Dump elements to a stream"
  input list<DAE.Element> l;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := match(l, inStream)
    local  
      IOStream.IOStream str;
      list<DAE.Element> v,o,ie,ia,e,a;
      
    case (l, str)
     equation
       // classify DAE 
       (v,ie,ia,e,a,o) = DAEUtil.splitElements(l);

       // dump objects
       str = IOStream.appendList(str, Util.listMap(o, dumpExtObjClassStr));

       // dump variables
       str = dumpVarsStream(v, false, str);

       str = IOStream.append(str, Util.if_(Util.isListEmpty(ie), "", "initial equation\n"));
       str = dumpInitialEquationsStream(ie, str);
       
       str = IOStream.append(str, Util.if_(Util.isListEmpty(ia), "", "initial algorithm\n"));
       str = dumpInitialAlgorithmsStream(ia, str);

       str = IOStream.append(str, Util.if_(Util.isListEmpty(e), "", "equation\n"));
       str = dumpEquationsStream(e, str);

       str = IOStream.append(str, Util.if_(Util.isListEmpty(a), "", "algorithm\n"));
       str = dumpAlgorithmsStream(a, str);
     then
       str;
  end match;
end dumpElementsStream;

public function dumpAlgorithmsStream "function: dumpAlgorithmsStream
  Dump algorithms to a stream."
  input list<DAE.Element> inElementLst;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := matchcontinue (inElementLst, inStream)
    local
      IOStream.IOStream str;
      list<DAE.Statement> stmts;
      list<DAE.Element> xs;

    case ({}, str) then str;

    case (DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = stmts)) :: xs, str)
      equation
        str = IOStream.appendList(str, Util.listMap(stmts, ppStatementStr));
        str = dumpAlgorithmsStream(xs, str);
      then
        str;

    case (_ :: xs, str)
      equation
        str = dumpAlgorithmsStream(xs, str);
      then
        str;
  end matchcontinue;
end dumpAlgorithmsStream;

protected function dumpInitialAlgorithmsStream "function: dumpInitialalgorithmsStream
  Dump initialalgorithms to a stream."
  input list<DAE.Element> inElementLst;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := matchcontinue (inElementLst, inStream)
    local
      IOStream.IOStream str;
      list<DAE.Statement> stmts;
      list<DAE.Element> xs;

    case ({}, str) then str;

    case (DAE.INITIALALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = stmts)) :: xs, str)
      equation
        str = IOStream.appendList(str, Util.listMap(stmts, ppStatementStr));
        str = dumpInitialAlgorithmsStream(xs, str);
      then
        str;

    case (_ :: xs, str)
      equation
        str = dumpInitialAlgorithmsStream(xs, str);
      then
        str;
  end matchcontinue;
end dumpInitialAlgorithmsStream;

protected function dumpEquationsStream "function: dumpEquationsStream
  Dump equations to a stream."
  input list<DAE.Element> inElementLst;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := matchcontinue (inElementLst, inStream)
    local
      String s1,s2,s;
      DAE.Exp e1,e2,e;
      list<DAE.Exp> conds,expl;
      list<DAE.Element> xs,xs1,xs2;
      list<list<DAE.Element>> tb;
      DAE.ComponentRef c,cr,cr1,cr2;
      IOStream.IOStream str;
      DAE.Element el;
      Absyn.Path path;
    
    case ({}, str) then str;
    
    case ((DAE.EQUATION(exp = e1,scalar = e2) :: xs), str)
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        str = IOStream.appendList(str, {"  ", s1, " = ", s2, ";\n"});
        str = dumpEquationsStream(xs, str);
      then
        str;
    
    case ((DAE.EQUEQUATION(cr1=cr1,cr2=cr2) :: xs), str)
      equation
        str = IOStream.append(str, "  " +& ComponentReference.printComponentRefStr(cr1) +&" = " +& ComponentReference.printComponentRefStr(cr2) +& ";\n");
        str = dumpEquationsStream(xs, str);
      then
        str;

    case ((DAE.ARRAY_EQUATION(exp = e1,array = e2) :: xs), str)
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        str = IOStream.appendList(str, {"  ", s1, " = ", s2, ";\n"});
        str = dumpEquationsStream(xs, str);
      then
        str;

    case ((DAE.COMPLEX_EQUATION(lhs = e1,rhs= e2) :: xs), str)
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        str = IOStream.appendList(str, {"  ", s1, " = ", s2, ";\n"});
        str = dumpEquationsStream(xs, str);
      then
        str;

    case ((DAE.DEFINE(componentRef = c,exp = e) :: xs), str)
      equation
        s1 = ComponentReference.printComponentRefStr(c);
        s2 = ExpressionDump.printExpStr(e);
        str = IOStream.appendList(str, {"  ", s1, " = ", s2, ";\n"});
        str = dumpEquationsStream(xs, str);
      then
        str;

    case ((DAE.ASSERT(condition=e1,message = e2) :: xs), str)
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        str = IOStream.appendList(str, {"  assert(",s1,",",s2,");\n"});
        str = dumpEquationsStream(xs, str);
      then
        str;
        
    case (DAE.TERMINATE(message=e1) :: xs, str)
      equation
        s1 = ExpressionDump.printExpStr(e1);
        str = IOStream.appendList(str, {"  terminate(",s1,");\n"});
        str = dumpEquationsStream(xs, str);
      then
        str;
        
    case ((DAE.IF_EQUATION(condition1 = {},equations2 = {},equations3 = {}) :: xs), str) 
      then 
        str;

    case ((DAE.IF_EQUATION(condition1 = (e::conds),equations2 = (xs1::tb),equations3 = {}) :: xs), str)
      equation        
        str = IOStream.append(str, "  if ");
        str = IOStream.append(str, ExpressionDump.printExpStr(e));
        str = IOStream.append(str, " then\n");
        str = dumpEquationsStream(xs1, str);
        str = dumpIfEquationsStream(conds, tb, str);
        str = IOStream.append(str, "  end if;\n");
        str = dumpEquationsStream(xs, str);
      then
        str;

    case ((DAE.IF_EQUATION(condition1 = (e::conds),equations2 = (xs1::tb),equations3 = xs2) :: xs), str)
      equation
        str = IOStream.append(str, "  if ");
        str = IOStream.append(str, ExpressionDump.printExpStr(e));
        str = IOStream.append(str, " then\n");
        str = dumpEquationsStream(xs1, str);
        str = dumpIfEquationsStream(conds, tb, str);
        str = IOStream.append(str, "  else\n");
        str = dumpEquationsStream(xs2, str);
        str = IOStream.append(str, "  end if;\n");
        str = dumpEquationsStream(xs, str);
      then
        str;

    case ((DAE.WHEN_EQUATION(condition = e,equations = xs1,elsewhen_ = SOME(el)) :: xs), str)
      equation
        str = IOStream.append(str, "when ");
        str = IOStream.append(str, ExpressionDump.printExpStr(e));
        str = IOStream.append(str, " then\n");
        str = dumpEquationsStream(xs1, str);
        str = IOStream.append(str, " else");
        str = dumpEquationsStream((el :: xs), str);
      then
        str;

    case ((DAE.WHEN_EQUATION(condition = e,equations = xs1,elsewhen_ = NONE()) :: xs), str)
      equation
        str = IOStream.append(str, "  when ");
        str = IOStream.append(str, ExpressionDump.printExpStr(e));
        str = IOStream.append(str, " then\n");
        str = dumpEquationsStream(xs1, str);
        str = IOStream.append(str, "  end when;\n");
        str = dumpEquationsStream(xs, str);
      then
        str;

    case ((DAE.REINIT(componentRef = cr,exp = e) :: xs), str)
      equation
        s = ComponentReference.printComponentRefStr(cr);
        s1 = ExpressionDump.printExpStr(e);
        str = IOStream.appendList(str, {"  reinit(",s,",",s1,");\n"});
        str = dumpEquationsStream(xs, str);
      then
        str;

    case ((DAE.NORETCALL(functionName=path,functionArgs=expl) :: xs), str)
      equation
        s = Absyn.pathString(path);
        s1 = Util.stringDelimitList(Util.listMap(expl,ExpressionDump.printExpStr),",");
        str = IOStream.appendList(str, {"  ",s,"(",s1,");\n"});
        str = dumpEquationsStream(xs, str);
      then
        str;

    case ((_ :: xs), str)
      equation
        str = dumpEquationsStream(xs, str);
      then
        str;
  end matchcontinue;
end dumpEquationsStream;

protected function dumpIfEquationsStream ""
  input list<DAE.Exp> conds;
  input list<list<DAE.Element>> tbs;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm 
  outStream := match(conds,tbs,inStream)
    local
      DAE.Exp c;
      list<DAE.Element> tb;
      IOStream.IOStream str;

  case({},{},str) then str;

  case(c::conds, tb::tbs, str)
    equation
      str = IOStream.append(str, "  elseif ");
      str = IOStream.append(str, ExpressionDump.printExpStr(c));
      str = IOStream.append(str, " then\n");
      str = dumpEquationsStream(tb, str);
      str = dumpIfEquationsStream(conds,tbs, str);
    then
      str;
  end match;
end dumpIfEquationsStream;

protected function dumpInitialEquationsStream "function: dumpInitialequationsStr
  Dump initial equations to a stream."
  input list<DAE.Element> inElementLst;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := matchcontinue (inElementLst, inStream)
    local
      String s1,s2;
      DAE.Exp e1,e2,e;
      list<DAE.Element> xs,xs1,xs2;
      list<list<DAE.Element>> trueBranches;
      DAE.ComponentRef c;
      IOStream.IOStream str;
      list<DAE.Exp> conds;
    
    case ({}, str) then str;

    case ((DAE.INITIALEQUATION(exp1 = e1,exp2 = e2) :: xs), str)
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        str = IOStream.appendList(str, {"  ", s1, " = ", s2, ";\n"});
        str = dumpInitialEquationsStream(xs, str);
      then
        str;

    case ((DAE.INITIAL_ARRAY_EQUATION(exp = e1, array = e2) :: xs), str)
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        str = IOStream.appendList(str, {"  ", s1, " = ", s2, ";\n"});
        str = dumpInitialEquationsStream(xs, str);
      then
        str;

    case ((DAE.INITIAL_COMPLEX_EQUATION(lhs = e1,rhs = e2) :: xs), str)
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        str = IOStream.appendList(str, {"  ", s1, " = ", s2, ";\n"});
        str = dumpInitialEquationsStream(xs, str);
      then
        str;

    case ((DAE.INITIALDEFINE(componentRef = c,exp = e) :: xs), str)
      equation
        s1 = ComponentReference.printComponentRefStr(c);
        s2 = ExpressionDump.printExpStr(e);
        str = IOStream.appendList(str, {"  ", s1, " = ", s2, ";\n"});
        str = dumpInitialEquationsStream(xs, str);
      then
        str;

    case ((DAE.INITIAL_IF_EQUATION(condition1 = (e::conds),equations2 = (xs1::trueBranches),equations3 = xs2) :: xs), str)
      equation
        str = IOStream.append(str, "  if ");
        str = IOStream.append(str, ExpressionDump.printExpStr(e));
        str = IOStream.append(str, " then\n");
        str = dumpInitialEquationsStream(xs1, str);
        str = dumpIfEquationsStream(conds, trueBranches, str);
        str = IOStream.append(str, "  else\n");
        str = dumpInitialEquationsStream(xs2, str);
        str = IOStream.append(str, "  end if;\n");
        str = dumpInitialEquationsStream(xs, str);
      then
        str;

    case ((_ :: xs), str)
      equation
        str = dumpInitialEquationsStream(xs, str);
      then
        str;
  end matchcontinue;
end dumpInitialEquationsStream;

public function dumpDAEElementsStr "
Author BZ
print a DAE.DAEList to a string"
  input DAE.DAElist d;
  output String str;
algorithm 
  str := match(d)
    local 
      list<DAE.Element> l;
      IOStream.IOStream myStream;
      
    case(DAE.DAE(elementLst=l))
      equation
        myStream = IOStream.create("", IOStream.LIST());
        myStream = dumpElementsStream(l, myStream);
        str = IOStream.string(myStream);
      then str;
  end match;
end dumpDAEElementsStr;

public function dumpVarsStream "function: dumpVarsStream
  Dump variables to a string."
  input list<DAE.Element> inElementLst;
  input Boolean printTypeDimension "use true here when printing components in functions as these are not vectorized! Otherwise, use false";
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := match (inElementLst, printTypeDimension, inStream)
    local
      IOStream.IOStream str;
      DAE.Element first;
      list<DAE.Element> rest;
    // handle nothingness
    case ({},_,inStream) then inStream;
    // the usual case
    case (first :: rest, printTypeDimension, str)
      equation
        str = dumpVarStream(first, printTypeDimension, str);
        str = dumpVarsStream(rest, printTypeDimension, str);
      then
        str;
  end match;
end dumpVarsStream;

protected function dumpVarStream "function: dumpVarStream
  Dump var to a stream."
  input DAE.Element inElement;
  input Boolean printTypeDimension "use true here when printing components in functions as these are not vectorized! Otherwise, use false";
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := matchcontinue (inElement, printTypeDimension, inStream)
    local
      String s1,s2,s3,s4,comment_str,s5,s6,s7,s3_subs,sFinal;
      DAE.ComponentRef id;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.Type typ;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      DAE.ElementSource source "the origin of the element";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Exp e;
      DAE.VarVisibility prot;
      DAE.InstDims dims;
      IOStream.IOStream str;
    // no binding
    case (DAE.VAR(componentRef = id,
             kind = kind,
             direction = dir,
             protection=prot,
             ty = typ,
             dims = dims,
             binding = NONE(),
             flowPrefix = flowPrefix,
             streamPrefix =  streamPrefix,
             source = source,
             variableAttributesOption = dae_var_attr,
             absynCommentOption = comment), printTypeDimension, str)
      equation
        sFinal = Util.if_(DAEUtil.getFinalAttr(dae_var_attr),"final ", "");
        s1 = dumpKindStr(kind);
        s2 = dumpDirectionStr(dir);
        s3 = unparseType(typ);
        s3_subs = unparseDimensions(dims, printTypeDimension);
        s4 = ComponentReference.printComponentRefStr(id);
        s7 = dumpVarVisibilityStr(prot);
        comment_str = dumpCommentOptionStr(comment);
        s5 = dumpVariableAttributesStr(dae_var_attr);
        str = IOStream.appendList(str, {"  ",s7,sFinal,s1,s2,s3,s3_subs," ",s4,s5,comment_str,";\n"});
      then
        str;
    // we have a binding
    case (DAE.VAR(componentRef = id,
             kind = kind,
             direction = dir,
             protection=prot,
             ty = typ,
             dims = dims,
             binding = SOME(e),
             flowPrefix = flowPrefix,
             streamPrefix = streamPrefix,
             source = source,
             variableAttributesOption = dae_var_attr,
             absynCommentOption = comment), printTypeDimension, str)
      equation
        sFinal = Util.if_(DAEUtil.getFinalAttr(dae_var_attr),"final ", "");
        s1 = dumpKindStr(kind);
        s2 = dumpDirectionStr(dir);
        s3 = unparseType(typ);
        s3_subs = unparseDimensions(dims, printTypeDimension);
        s4 = ComponentReference.printComponentRefStr(id);
        s5 = ExpressionDump.printExpStr(e);
        comment_str = dumpCommentOptionStr(comment);
        s6 = dumpVariableAttributesStr(dae_var_attr);
        s7 = dumpVarVisibilityStr(prot);
        str = IOStream.appendList(str, {"  ",s7,sFinal,s1,s2,s3,s3_subs," ",s4,s6," = ",s5,comment_str,";\n"});
      then
        str;
    case (_,_,str) then str;
  end matchcontinue;
end dumpVarStream;

public function dumpAlgorithmStream
"function: dumpAlgorithmStream
  Dump algorithm to a stream"
  input DAE.Element inElement;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := matchcontinue (inElement, inStream)
    local
      IOStream.IOStream str;
      list<DAE.Statement> stmts;
      
    case (DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = stmts)), str)
      equation
        str = IOStream.append(str, "algorithm\n");
        str = Util.listFold(stmts, ppStatementStream, str);
      then
        str;
    case (_,str) then str;
  end matchcontinue;
end dumpAlgorithmStream;

public function dumpInitialAlgorithmStream
"function: dumpInitialAlgorithmStream
  Dump algorithm to a stream"
  input DAE.Element inElement;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := matchcontinue (inElement, inStream)
    local
      IOStream.IOStream str;
      list<DAE.Statement> stmts;
      
    case (DAE.INITIALALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = stmts)), str)
      equation
        str = IOStream.append(str, "initial algorithm\n");
        str = Util.listFold(stmts, ppStatementStream, str);
      then
        str;
    case (_,str) then str;
  end matchcontinue;
end dumpInitialAlgorithmStream;

public function ppStatementStream
"function: ppStatementStr
  Prettyprint an algorithm statement to a string."
  input DAE.Statement alg;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
protected
  String tmp;
algorithm
  tmp := Print.getString();
  Print.clearBuf();
  ppStatement(alg);
  outStream := IOStream.append(inStream, Print.getString());
  Print.clearBuf();
  Print.printBuf(tmp);
end ppStatementStream;

public function dumpFunctionStr "function: dumpFunctionStr
  Dump function to a string."
  input DAE.Function inElement;
  output String outString;
algorithm
  outString := matchcontinue (inElement)
    local
      String s1,s2;

    case(inElement)
      equation
        s1 = Print.getString();
        Print.clearBuf();
        dumpFunction(inElement);
        s2 = Print.getString();
        Print.clearBuf();
        Print.printBuf(s1);
      then
        s2;

    case _ then "";
  end matchcontinue;
end dumpFunctionStr;

protected function dumpExtObjClassStr
"function: dumpExtObjStr
  Dump external object class to a string."
  input DAE.Element inElement;
  output String outString;
algorithm
  outString := matchcontinue (inElement)
    local
      String fstr,str,c_str,d_str;
      Absyn.Path fpath;
    case DAE.EXTOBJECTCLASS(path = fpath)
      equation
        fstr = Absyn.pathString(fpath);
        str = stringAppendList({"class  ",fstr,"\n  extends ExternalObject;\nend ",fstr,";\n"});
      then
        str;
    case _ then "";
  end matchcontinue;
end dumpExtObjClassStr;

protected function dumpFunctionStream
"function: dumpFunctionStream
  Dump function to a stream"
  input DAE.Function inElement;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := matchcontinue (inElement, inStream)
    local
      String fstr, lang;
      Absyn.Path fpath;
      list<DAE.Element> daeElts;
      DAE.Type t;
      DAE.Type tp;
      DAE.InlineType inlineType;
      IOStream.IOStream str;
      Option<SCode.Comment> c;
      
    case (DAE.FUNCTION(path = fpath,inlineType=inlineType,functions = (DAE.FUNCTION_DEF(body = daeElts)::_),type_ = t, comment = c), str)
      equation
        fstr = Absyn.pathStringNoQual(fpath);
        str = IOStream.append(str, "function ");
        str = IOStream.append(str, fstr);
        str = IOStream.append(str, dumpInlineTypeStr(inlineType));
        str = IOStream.append(str, dumpCommentOptionStr(c));
        str = IOStream.append(str, "\n");
        str = dumpFunctionElementsStream(daeElts, str);
        str = IOStream.append(str, "end ");
        str = IOStream.append(str, fstr);
        str = IOStream.append(str, ";\n\n");
      then
        str;

      case (DAE.FUNCTION(functions=(DAE.FUNCTION_EXT(externalDecl = DAE.EXTERNALDECL(language="builtin"))::_)), str)
      then
        str;

      case (DAE.FUNCTION(path = fpath,inlineType=inlineType,functions = (DAE.FUNCTION_EXT(body = daeElts, externalDecl = DAE.EXTERNALDECL(language=lang))::_),type_ = t, comment = c), str)
      equation
        fstr = Absyn.pathStringNoQual(fpath);
        str = IOStream.append(str, "function ");
        str = IOStream.append(str, fstr);
        str = IOStream.append(str, dumpInlineTypeStr(inlineType));
        str = IOStream.append(str, dumpCommentOptionStr(c));
        str = IOStream.append(str, "\n");
        str = dumpFunctionElementsStream(daeElts, str);
        str = IOStream.appendList(str, {"\n  external \"",lang,"\";\nend ",fstr,";\n\n"});
      then
        str;

    case (DAE.RECORD_CONSTRUCTOR(path = fpath,type_=tp), str)
      equation
        fstr = Absyn.pathStringNoQual(fpath);
        str = IOStream.append(str, "function ");
        str = IOStream.append(str, fstr);
        str = IOStream.append(str, " \"Automatically generated record constructor for " +& fstr +& "\"\n");
        str = IOStream.append(str, printRecordConstructorInputsStr(tp));
        str = IOStream.append(str, "  output "+&Absyn.pathLastIdent(fpath) +& " res;\n");
        str = IOStream.append(str, "end ");
        str = IOStream.append(str, fstr);
        str = IOStream.append(str, ";\n\n");
      then
        str;

    case (_, str) then str;
  end matchcontinue;
end dumpFunctionStream;

public function dumpFunctionElementsStream "function: dumpFunctionElementsStream
  Dump function elements to a stream."
  input list<DAE.Element> l;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := dumpVarsStream(l, true, inStream);
  outStream := Util.listFold(l, dumpAlgorithmStream, outStream);
end dumpFunctionElementsStream;

end DAEDump;
