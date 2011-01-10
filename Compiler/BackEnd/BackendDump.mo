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

encapsulated package BackendDump
" file:        BackendDump.mo
  package:     BackendDump
  description: Unparsing the BackendDAE structure

  RCS: $Id$
"

public import BackendDAE;
public import DAE;

protected import Absyn;
protected import Algorithm;
protected import BackendDAETransform;
protected import BackendDAEUtil;
protected import BackendVariable;
protected import BackendEquation;
protected import ComponentReference;
protected import BackendDAEEXT;
protected import DAEDump;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import HashTable2;
protected import IOStream;
protected import SCode;
protected import Util;

public function printComponentRefStrDIVISION
  input DAE.ComponentRef inCref;
  input BackendDAE.Variables inVars;
  output String outString;
algorithm 
  outString := matchcontinue(inCref,inVars)
    local 
      DAE.ComponentRef c,co;
      BackendDAE.Variables variables;
      String sc;
    case(c,variables)
      equation
        ((BackendDAE.VAR(varName=co):: _),_) = BackendVariable.getVar(c,variables);
        sc = ComponentReference.printComponentRefStr(co);
      then
        sc;
    case(c,variables)
      equation
        sc = ComponentReference.printComponentRefStr(c);
      then
        sc;
  end matchcontinue;
end printComponentRefStrDIVISION;

public function printCallFunction2StrDIVISION
"function: printCallFunction2Str
  Print the exp of typ DAE.CALL."
  input DAE.Exp inExp;
  input String stringDelimiter;
  input Option<tuple<printComponentRefStrFunc,Type_a>> opcreffunc "tuple of function that print component references and a extra parameter passet throug the function";
  output String outString;
  replaceable type Type_a subtypeof Any;
  partial function printComponentRefStrFunc
    input DAE.ComponentRef inComponentRef;
    input Type_a Param;
    output String outString;
  end printComponentRefStrFunc;     
algorithm
  outString := matchcontinue (inExp,stringDelimiter,opcreffunc)
    local
      Expression.Ident s,s_1,s_2,fs,argstr;
      Absyn.Path fcn;
      list<DAE.Exp> args;
      DAE.Exp e1,e2;
      Expression.Type ty;
    case( DAE.CALL(path = Absyn.IDENT("DIVISION"), expLst = {e1,e2,DAE.SCONST(_)}, tuple_ = false,builtin = true,ty = ty,inlineType = DAE.NO_INLINE()), _, _)
      equation
        s = ExpressionDump.printExp2Str(DAE.BINARY(e1,DAE.DIV(ty),e2),stringDelimiter,opcreffunc, SOME(printCallFunction2StrDIVISION));
      then
        s;
    case( DAE.CALL(path = Absyn.IDENT("DIVISION_ARRAY_SCALAR"),expLst = {e1,e2,DAE.SCONST(_)}, tuple_ = false,builtin = true,ty =ty,inlineType = DAE.NO_INLINE()), _, _)
      equation
        s = ExpressionDump.printExp2Str(DAE.BINARY(e1,DAE.DIV_ARRAY_SCALAR(ty),e2),stringDelimiter,opcreffunc, SOME(printCallFunction2StrDIVISION));
      then
        s;
    case( DAE.CALL(path = Absyn.IDENT("DIVISION_SCALAR_ARRAY"),expLst = {e1,e2,DAE.SCONST(_)}, tuple_ = false,builtin = true,ty =ty,inlineType = DAE.NO_INLINE()), _, _)
      equation
        s = ExpressionDump.printExp2Str(DAE.BINARY(e1,DAE.DIV_SCALAR_ARRAY(ty),e2),stringDelimiter,opcreffunc, SOME(printCallFunction2StrDIVISION));
      then
        s;
    case (DAE.CALL(path = fcn,expLst = args), _,_)
      equation
        fs = Absyn.pathString(fcn);
        argstr = Util.stringDelimitList(
          Util.listMap3(args, ExpressionDump.printExp2Str, stringDelimiter,opcreffunc, SOME(printCallFunction2StrDIVISION)), ",");
        s = stringAppend(fs, "(");
        s_1 = stringAppend(s, argstr);
        s_2 = stringAppend(s_1, ")");
      then
        s_2;
  end matchcontinue;        
end printCallFunction2StrDIVISION;

public function printTuple
  input list<tuple<String,Integer>> outTuple;
algorithm
  _ := matchcontinue(outTuple)
    local
      String currVar;
      Integer currInd;
      list<tuple<String,Integer>> restTuple;
    case ({}) then ();
    case ((currVar,currInd)::restTuple)
      equation
        Debug.fcall("varIndex",print, currVar);
        Debug.fcall("varIndex",print,":   ");
        Debug.fcall("varIndex",print,intString(currInd));
        Debug.fcall("varIndex",print,"\n");
        printTuple(restTuple);
      then ();
    case (_) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"printTuple() failed"});
    then fail();      
  end matchcontinue;
end printTuple;

protected function printPrioTuplesStr
"Debug function for printing the priorities of state selection to a string"
  input tuple<DAE.ComponentRef,Integer,Real> prioTuples;
  output String str;
algorithm
  str := matchcontinue(prioTuples)
    local DAE.ComponentRef cr; Real prio; String s1,s2;
    case((cr,_,prio))
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = realString(prio);
        str = stringAppendList({"(",s1,", ",s2,")"});
      then str;
  end matchcontinue;
end printPrioTuplesStr;

public function printEquations
  input list<Integer> inIntegerLst;
  input BackendDAE.BackendDAE inBackendDAE;
algorithm
  _:=
  match (inIntegerLst,inBackendDAE)
    local
      BackendDAE.Value n;
      list<BackendDAE.Value> rest;
      BackendDAE.BackendDAE dae;
    case ({},_) then ();
    case ((n :: rest),dae)
      equation
        printEquations(rest, dae);
        printEquationNo(n, dae);
      then
        ();
  end match;
end printEquations;

protected function printEquationNo "function: printEquationNo
  author: PA

  Helper function to print_equations
"
  input Integer inInteger;
  input BackendDAE.BackendDAE inBackendDAE;
algorithm
  _:=
  match (inInteger,inBackendDAE)
    local
      BackendDAE.Value eqno_1,eqno;
      BackendDAE.Equation eq;
      BackendDAE.EquationArray eqns;
    case (eqno,BackendDAE.DAE(orderedEqs = eqns))
      equation
        eqno_1 = eqno - 1;
        eq = BackendDAEUtil.equationNth(eqns, eqno_1);
        printEquation(eq);
      then
        ();
  end match;
end printEquationNo;

public function printEquation "function: printEquation
  author: PA

  Helper function to print_equations
"
  input BackendDAE.Equation inEquation;
algorithm
  _:=
  match (inEquation)
    local
      String s1,s2,res;
      DAE.Exp e1,e2;
      DAE.ComponentRef cr;
      BackendDAE.WhenEquation w;
    case (BackendDAE.EQUATION(exp = e1,scalar = e2))
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        res = stringAppendList({s1," = ",s2,"\n"});
        print(res);
      then
        ();
    case (BackendDAE.WHEN_EQUATION(whenEquation = w))
      equation
        (cr,e2) = BackendEquation.getWhenEquationExpr(w);
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = ExpressionDump.printExpStr(e2);
        res = stringAppendList({s1," =  ",s2,"\n"});
        print(res);
      then
        ();
  end match;
end printEquation;

protected function printVarsStatistics "function: printVarsStatistics
  author: PA

  Prints statistics on variables, currently depth of BinTree, etc.
"
  input BackendDAE.Variables inVariables1;
  input BackendDAE.Variables inVariables2;
algorithm
  _:=
  matchcontinue (inVariables1,inVariables2)
    local
      String lenstr,bstr;
      BackendDAE.VariableArray v1,v2;
      BackendDAE.Value bsize1,n1,bsize2,n2;
    case (BackendDAE.VARIABLES(varArr = v1,bucketSize = bsize1,numberOfVars = n1),BackendDAE.VARIABLES(varArr = v2,bucketSize = bsize2,numberOfVars = n2))
      equation
        print("Variable Statistics\n");
        print("===================\n");
        print("Number of variables: ");
        lenstr = intString(n1);
        print(lenstr);
        print("\n");
        print("Bucket size for variables: ");
        bstr = intString(bsize1);
        print(bstr);
        print("\n");
        print("Number of known variables: ");
        lenstr = intString(n2);
        print(lenstr);
        print("\n");
        print("Bucket size for known variables: ");
        bstr = intString(bsize1);
        print(bstr);
        print("\n");
      then
        ();
  end matchcontinue;
end printVarsStatistics;

public function dumpTypeStr
" Dump BackendDAE.Type to a string.
"
  input BackendDAE.Type inType;
  output String outString;
algorithm
  outString:=
  match (inType)
    local
      String s1,s2,str;
      list<String> l;
    case BackendDAE.INT() then "Integer ";
    case BackendDAE.REAL() then "Real ";
    case BackendDAE.BOOL() then "Boolean ";
    case BackendDAE.STRING() then "String ";

    case BackendDAE.ENUMERATION(stringLst = l)
      equation
        s1 = Util.stringDelimitList(l, ", ");
        s2 = stringAppend("enumeration(", s1);
        str = stringAppend(s2, ")");
      then
        str;
    case BackendDAE.EXT_OBJECT(_) then "ExternalObject ";
  end match;
end dumpTypeStr;

public function dumpTearing
" function: dumpTearing
  autor: Frenkel TUD
  Dump tearing vars and residual equations."
  input list<list<Integer>> inResEqn;
  input list<list<Integer>> inTearVar;
algorithm
  _:=
  match (inResEqn,inTearVar)
    local
      list<Integer> tearingvars,residualeqns;
      list<list<Integer>> r,t;
      list<String> str_r,str_t;
      String str_r_f,str_r_1,str_t_f,str_t_1,str,sr,st;
    case (residualeqns::r,tearingvars::t)
      equation
        str_r = Util.listMap(residualeqns, intString);
        str_r_f = Util.stringDelimitList(str_r, ", ");
        str_r_1 = stringAppend(str_r_f, "\n");
        sr = stringAppend("ResidualEqns: ",str_r_1);
        str_t = Util.listMap(tearingvars, intString);
        str_t_f = Util.stringDelimitList(str_t, ", ");
        str_t_1 = stringAppend(str_t_f, "\n");
        st = stringAppend("TearingVars: ",str_t_1);
        str = stringAppend(sr, st);
        print(str);
        print("\n");
        dumpTearing(r,t);
      then
        ();
  end match;
end dumpTearing;

public function dumpBackendDAEEqnList
  input list<BackendDAE.Equation> inBackendDAEEqnList;
  input String header;
  input Boolean printExpTree;
algorithm
   print(header);
   dumpBackendDAEEqnList2(inBackendDAEEqnList,printExpTree);
   print("===================\n");
end dumpBackendDAEEqnList;

protected function dumpBackendDAEEqnList2
  input list<BackendDAE.Equation> inBackendDAEEqnList;
  input Boolean printExpTree;
algorithm
  _ := matchcontinue (inBackendDAEEqnList,printExpTree)
    local
      DAE.Exp e1_1,e2_1,e1,e2,e_1,e;
      String str;
      list<String> strList;
      list<BackendDAE.Equation> res;
      list<DAE.Exp> expList,expList2;
      Integer i;
      DAE.ElementSource source "the element source";

     case ({},_) then ();
     case (BackendDAE.EQUATION(e1,e2,source)::res,printExpTree) /* header */
      equation
        dumpBackendDAEEqnList2(res,printExpTree);
        print("EQUATION: ");
        str = ExpressionDump.printExpStr(e1);
        print(str);
        print("\n");
        str = ExpressionDump.dumpExpStr(e1,0);
        str = Util.if_(printExpTree,str,"");
        print(str);
        print("\n");
      then
        ();
     case (BackendDAE.COMPLEX_EQUATION(i,e1,e2,source)::res,printExpTree) /* header */
      equation
        dumpBackendDAEEqnList2(res,printExpTree);
        print("COMPLEX_EQUATION: ");
        str = ExpressionDump.printExpStr(e1);
        print(str);
        print("\n");
        str = ExpressionDump.dumpExpStr(e1,0);
        str = Util.if_(printExpTree,str,"");
        print(str);
        print("\n");
      then
        ();
    case (BackendDAE.SOLVED_EQUATION(_,e,source)::res,printExpTree)
      equation
        dumpBackendDAEEqnList2(res,printExpTree);
        print("SOLVED_EQUATION: ");
        str = ExpressionDump.printExpStr(e);
        print(str);
        print("\n");
        str = ExpressionDump.dumpExpStr(e,0);
        str = Util.if_(printExpTree,str,"");
        print(str);
        print("\n");
      then
        ();
    case (BackendDAE.RESIDUAL_EQUATION(e,source)::res,printExpTree)
      equation
        dumpBackendDAEEqnList2(res,printExpTree);
        print("RESIDUAL_EQUATION: ");
        str = ExpressionDump.printExpStr(e);
        print(str);
        print("\n");
        str = ExpressionDump.dumpExpStr(e,0);
        str = Util.if_(printExpTree,str,"");
        print(str);
        print("\n");
      then
        ();
    case (BackendDAE.ARRAY_EQUATION(_,expList,source)::res,printExpTree)
      equation
        dumpBackendDAEEqnList2(res,printExpTree);
        print("ARRAY_EQUATION: ");
        strList = Util.listMap(expList,ExpressionDump.printExpStr);
        str = Util.stringDelimitList(strList," | ");
        print(str);
        print("\n");
      then
        ();
     case (BackendDAE.ALGORITHM(_,expList,expList2,source)::res,printExpTree)
      equation
        dumpBackendDAEEqnList2(res,printExpTree);
        print("ALGORITHM: ");
        strList = Util.listMap(expList,ExpressionDump.printExpStr);
        str = Util.stringDelimitList(strList," | ");
        print(str);
        print("\n");
        strList = Util.listMap(expList2,ExpressionDump.printExpStr);
        str = Util.stringDelimitList(strList," | ");
        print(str);
        print("\n");
      then
        ();
     case (BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(_,_,e,_/*TODO handle elsewhe also*/),source)::res,printExpTree)
      equation
        dumpBackendDAEEqnList2(res,printExpTree);
        print("WHEN_EQUATION: ");
        str = ExpressionDump.printExpStr(e);
        print(str);
        print("\n");
        str = ExpressionDump.dumpExpStr(e,0);
        str = Util.if_(printExpTree,str,"");
        print(str);
        print("\n");
      then
        ();
     case (_::res,printExpTree)
      equation
      then ();
  end matchcontinue;
end dumpBackendDAEEqnList2;

protected function dumpZcStr
"function: dumpZcStr
  Dumps a zerocrossing into a string, for debugging purposes."
  input BackendDAE.ZeroCrossing inZeroCrossing;
  output String outString;
algorithm
  outString:=
  match (inZeroCrossing)
    local
      list<String> eq_s_list,wc_s_list;
      String eq_s,wc_s,str,str2;
      DAE.Exp e;
      list<BackendDAE.Value> eq,wc;
    case BackendDAE.ZERO_CROSSING(relation_ = e,occurEquLst = eq,occurWhenLst = wc)
      equation
        eq_s_list = Util.listMap(eq, intString);
        eq_s = Util.stringDelimitList(eq_s_list, ",");
        wc_s_list = Util.listMap(wc, intString);
        wc_s = Util.stringDelimitList(wc_s_list, ",");
        str = ExpressionDump.printExpStr(e);
        str2 = stringAppendList({str," in equations [",eq_s,"] and when conditions [",wc_s,"]"});
      then
        str2;
  end match;
end dumpZcStr;

public function dump
"function: dump
  This function dumps the BackendDAE.BackendDAE representaton to stdout."
  input BackendDAE.BackendDAE inBackendDAE;
algorithm
  _:=
  match (inBackendDAE)
    local
      list<BackendDAE.Var> vars,knvars,extvars;
      BackendDAE.Value varlen,eqnlen;
      String varlen_str,eqnlen_str,s;
      list<BackendDAE.Equation> eqnsl,reqnsl,ieqnsl;
      list<String> ss;
      list<BackendDAE.MultiDimEquation> ae_lst;
      BackendDAE.Variables vars1,vars2,vars3;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray eqns,reqns,ieqns;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> algs;
      list<BackendDAE.ZeroCrossing> zc;
      BackendDAE.ExternalObjectClasses extObjCls;
    case (BackendDAE.DAE(vars1,vars2,vars3,av,eqns,reqns,ieqns,ae,algs,BackendDAE.EVENT_INFO(zeroCrossingLst = zc),extObjCls))
      equation
        print("Variables (");
        vars = BackendDAEUtil.varList(vars1);
        varlen = listLength(vars);
        varlen_str = intString(varlen);
        print(varlen_str);
        print(")\n");
        print("=========\n");
        dumpVars(vars);
        print("\n");
        print("Known Variables (constants) (");
        knvars = BackendDAEUtil.varList(vars2);
        varlen = listLength(knvars);
        varlen_str = intString(varlen);
        print(varlen_str);
        print(")\n");
        print("=============================\n");
        dumpVars(knvars);
        print("External Objects (");
        extvars = BackendDAEUtil.varList(vars3);
        varlen = listLength(extvars);
        varlen_str = intString(varlen);
        print(varlen_str);
        print(")\n");
        print("=============================\n");
        dumpVars(extvars);

        print("Classes of External Objects (");
        varlen = listLength(extObjCls);
        varlen_str = intString(varlen);
        print(varlen_str);
        print(")\n");
        print("=============================\n");
        dumpExtObjCls(extObjCls);
        print("\nEquations (");
        eqnsl = BackendDAEUtil.equationList(eqns);
        eqnlen = listLength(eqnsl);
        eqnlen_str = intString(eqnlen);
        print(eqnlen_str);
        print(")\n");
        print("=========\n");
        dumpEqns(eqnsl);
        print("Simple Equations (");
        reqnsl = BackendDAEUtil.equationList(reqns);
        eqnlen = listLength(reqnsl);
        eqnlen_str = intString(eqnlen);
        print(eqnlen_str);
        print(")\n");
        print("=========\n");
        dumpEqns(reqnsl);
        print("Initial Equations (");
        ieqnsl = BackendDAEUtil.equationList(ieqns);
        eqnlen = listLength(ieqnsl);
        eqnlen_str = intString(eqnlen);
        print(eqnlen_str);
        print(")\n");
        print("=========\n");
        dumpEqns(ieqnsl);
        print("Zero Crossings :\n");
        print("===============\n");
        ss = Util.listMap(zc, dumpZcStr);
        s = Util.stringDelimitList(ss, ",\n");
        print(s);
        print("\n");
        print("Array Equations :\n");
        print("===============\n");
        ae_lst = arrayList(ae);
        dumpArrayEqns(ae_lst,0);

        print("Algorithms:\n");
        print("===============\n");
        dumpAlgorithms(arrayList(algs),0);
      then
        ();
  end match;
end dump;

protected function dumpAlgorithms "Help function to dump, prints algorithms to stdout"
  input list<DAE.Algorithm> algs;
  input Integer indx;
algorithm
  _ := match(algs,indx)
    local 
      list<Algorithm.Statement> stmts;
      IOStream.IOStream myStream;
      String is;
      
    case({},_) then ();
    case(DAE.ALGORITHM_STMTS(stmts)::algs,indx) 
      equation
        is = intString(indx);
        myStream = IOStream.create("", IOStream.LIST()); 
        myStream = IOStream.append(myStream,stringAppend(is,". "));
        myStream = DAEDump.dumpAlgorithmStream(DAE.ALGORITHM(DAE.ALGORITHM_STMTS(stmts),DAE.emptyElementSource), myStream);
        IOStream.print(myStream, IOStream.stdOutput);
        dumpAlgorithms(algs,indx+1);
    then ();
  end match;
end dumpAlgorithms;

public function dumpJacobianStr
"function: dumpJacobianStr
  Dumps the sparse jacobian.
  Uses the variables to determine size of Jacobian matrix."
  input Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> inTplIntegerIntegerEquationLstOption;
  output String outString;
algorithm
  outString:=
  match (inTplIntegerIntegerEquationLstOption)
    local
      list<String> res;
      String res_1;
      list<tuple<BackendDAE.Value, BackendDAE.Value, BackendDAE.Equation>> eqns;
    case (SOME(eqns))
      equation
        res = dumpJacobianStr2(eqns);
        res_1 = Util.stringDelimitList(res, ", ");
      then
        res_1;
    case (NONE()) then "No analytic jacobian available\n";
  end match;
end dumpJacobianStr;

protected function dumpJacobianStr2
"function: dumpJacobianStr2
  Helper function to dumpJacobianStr"
  input list<tuple<Integer, Integer, BackendDAE.Equation>> inTplIntegerIntegerEquationLst;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  match (inTplIntegerIntegerEquationLst)
    local
      String estr,rowstr,colstr,str;
      list<String> strs;
      BackendDAE.Value row,col;
      DAE.Exp e;
      list<tuple<BackendDAE.Value, BackendDAE.Value, BackendDAE.Equation>> eqns;
    case ({}) then {};
    case (((row,col,BackendDAE.RESIDUAL_EQUATION(exp = e)) :: eqns))
      equation
        estr = ExpressionDump.printExpStr(e);
        rowstr = intString(row);
        colstr = intString(col);
        str = stringAppendList({"{",rowstr,",",colstr,"}:",estr});
        strs = dumpJacobianStr2(eqns);
      then
        (str :: strs);
  end match;
end dumpJacobianStr2;

protected function dumpArrayEqns
"function: dumpArrayEqns
  helper function to dump"
  input list<BackendDAE.MultiDimEquation> inMultiDimEquationLst;
  input Integer inInteger;
algorithm
  _ := match (inMultiDimEquationLst,inInteger)
    local
      String s1,s2,s,is;
      DAE.Exp e1,e2;
      list<BackendDAE.MultiDimEquation> es;
    case ({},_) then ();
    case ((BackendDAE.MULTIDIM_EQUATION(left = e1,right = e2) :: es),inInteger)
      equation
        is = intString(inInteger);
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        s = stringAppendList({is," : ",s1," = ",s2,"\n"});
        print(s);
        dumpArrayEqns(es,inInteger + 1);
      then
        ();
  end match;
end dumpArrayEqns;

public function dumpEqns
"function: dumpEqns
  Helper function to dump."
  input list<BackendDAE.Equation> eqns;
algorithm
  dumpEqns2(eqns, 1);
end dumpEqns;

protected function dumpEqns2
"function: dumpEqns2
  Helper function to dump_eqns"
  input list<BackendDAE.Equation> inEquationLst;
  input Integer inInteger;
algorithm
  _ := match (inEquationLst,inInteger)
    local
      String es,is;
      BackendDAE.Value index_1,index;
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqns;
    case ({},_) then ();
    case ((eqn :: eqns),index)
      equation
        es = equationStr(eqn);
        is = intString(index);
        print(is);
        print(" : ");
        print(es);
        print("\n");
        index_1 = index + 1;
        dumpEqns2(eqns, index_1);
      then
        ();
  end match;
end dumpEqns2;

protected function whenEquationStr
"function: whenEquationStr
  Helper function to equationStr"
  input BackendDAE.WhenEquation inWhenEqn;
  output String outString;
algorithm
  outString := match (inWhenEqn)
    local
      String s1,s2,res,is;
      DAE.Exp e2;
      BackendDAE.Value i;
      DAE.ComponentRef cr;
      BackendDAE.WhenEquation weqn;
    case (BackendDAE.WHEN_EQ(index = i,left = cr,right = e2, elsewhenPart = SOME(weqn)))
      equation
        s1 = whenEquationStr(weqn);
        s2 = ExpressionDump.printExpStr(e2);
        is = intString(i);
        res = stringAppendList({" ; ",s2," elsewhen clause no: ",is /*, "\n" */, s1});
      then
        res;
    case (BackendDAE.WHEN_EQ(index = i,left = cr,right = e2, elsewhenPart = NONE()))
      equation
        s2 = ExpressionDump.printExpStr(e2);
        is = intString(i);
        res = stringAppendList({" ; ",s2," elsewhen clause no: ",is /*, "\n" */});
      then
        res;
  end match;
end whenEquationStr;

public function equationStr
"function: equationStr
  Helper function to e.g. dump."
  input BackendDAE.Equation inEquation;
  output String outString;
algorithm
  outString := matchcontinue (inEquation)
    local
      String s1,s2,s3,res,indx_str,is,var_str,intsStr,outsStr;
      DAE.Exp e1,e2,e;
      BackendDAE.Value indx,i;
      list<DAE.Exp> expl,inps,outs;
      DAE.ComponentRef cr;
      BackendDAE.WhenEquation weqn;
    case (BackendDAE.EQUATION(exp = e1,scalar = e2))
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        res = stringAppendList({s1," = ",s2});
      then
        res;
    case (BackendDAE.COMPLEX_EQUATION(lhs = e1,rhs = e2))
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        res = stringAppendList({s1," = ",s2});
      then
        res;
    case (BackendDAE.ARRAY_EQUATION(index = indx,crefOrDerCref = expl))
      equation
        indx_str = intString(indx);
        var_str=Util.stringDelimitList(Util.listMap(expl,ExpressionDump.printExpStr),", ");
        res = stringAppendList({"Array eqn no: ",indx_str," for variables: ",var_str /*,"\n"*/});
      then
        res;
    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2))
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = ExpressionDump.printExpStr(e2);
        res = stringAppendList({s1," := ",s2});
      then
        res;
        
    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(index = i,left = cr,right = e2, elsewhenPart = SOME(weqn))))
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = ExpressionDump.printExpStr(e2);
        is = intString(i);
        s3 = whenEquationStr(weqn);
        res = stringAppendList({s1," := ",s2," when clause no: ",is /*, "\n" */, s3});
      then
        res;
    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(index = i,left = cr,right = e2)))
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = ExpressionDump.printExpStr(e2);
        is = intString(i);
        res = stringAppendList({s1," := ",s2," when clause no: ",is /*, "\n" */});
      then
        res;
    case (BackendDAE.RESIDUAL_EQUATION(exp = e))
      equation
        s1 = ExpressionDump.printExpStr(e);
        res = stringAppendList({s1,"= 0"});
      then
        res;
    case (BackendDAE.ALGORITHM(index = i, in_ = inps, out = outs))
      equation
        is = intString(i);
        intsStr = Util.stringDelimitList(Util.listMap(inps, ExpressionDump.printExpStr), ", ");
        outsStr = Util.stringDelimitList(Util.listMap(outs, ExpressionDump.printExpStr), ", ");        
        res = stringAppendList({"Algorithm no: ", is, " for inputs: (", 
                                      intsStr, ") => outputs: (", 
                                      outsStr, ")" /*,"\n"*/});
      then
        res;
  end matchcontinue;
end equationStr;

protected function dumpExtObjCls "dump classes of external objects"
  input BackendDAE.ExternalObjectClasses cls;
algorithm
  _ := match(cls)
    local
      BackendDAE.ExternalObjectClasses xs;
      DAE.Function constr,destr;
      Absyn.Path path;
      list<Absyn.Path> paths;
      list<String> paths_lst;
      DAE.ElementSource source "the element source";
      String path_str;

    case {} then ();

    case BackendDAE.EXTOBJCLASS(path,constr,destr,source)::xs
      equation
        print("class ");
        print(Absyn.pathString(path));
        print("\n  extends ExternalObject");
        print(DAEDump.dumpFunctionStr(constr));
        print("\n");
        print(DAEDump.dumpFunctionStr(destr));
        print("\n origin: ");
        paths = DAEUtil.getElementSourceTypes(source);
        paths_lst = Util.listMap(paths, Absyn.pathString);
        path_str = Util.stringDelimitList(paths_lst, ", ");
        print(path_str +& "\n");
        print("end ");print(Absyn.pathString(path));
      then ();
  end match;
end dumpExtObjCls;

public function dumpVars
"function: dumpVars
  Helper function to dump."
  input list<BackendDAE.Var> vars;
algorithm
  dumpVars2(vars, 1);
end dumpVars;

protected function dumpVars2
"function: dumpVars2
  Helper function to dumpVars."
  input list<BackendDAE.Var> inVarLst;
  input Integer inInteger;
algorithm
  _ := matchcontinue (inVarLst,inInteger)
    local
      String varnostr,dirstr,str,path_str,comment_str,s,indx_str,sstart;
      list<String> paths_lst,path_strs;
      BackendDAE.Value varno_1,indx,varno;
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      BackendDAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.Exp e;
      list<Absyn.Path> paths;
      DAE.ElementSource source "the origin of the element";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<BackendDAE.Var> xs;
      BackendDAE.Type var_type;
      DAE.InstDims arrayDim;
      Boolean b;

    case ({},_) then ();

    case (((v as BackendDAE.VAR(varName = cr,
                     varKind = kind,
                     varDirection = dir,
                     varType = var_type,
                     arryDim = arrayDim,
                     bindExp = SOME(e),
                     index = indx,
                     source = source,
                     values = dae_var_attr,
                     comment = comment,
                     flowPrefix = flowPrefix,
                     streamPrefix = streamPrefix)) :: xs),varno)
      equation
        varnostr = intString(varno);
        print(varnostr);
        print(": ");
        dirstr = DAEDump.dumpDirectionStr(dir);
        print(dirstr);
        print(" ");
        str = ComponentReference.printComponentRefStr(cr);
        print(str);
        print(":");
        dumpKind(kind);
        paths = DAEUtil.getElementSourceTypes(source);
        paths_lst = Util.listMap(paths, Absyn.pathString);
        path_str = Util.stringDelimitList(paths_lst, ", ");
        comment_str = DAEDump.dumpCommentOptionStr(comment);
        print(" = ");
        s = ExpressionDump.printExpStr(e);
        print(s);
        print(" ");
        print(path_str);
        indx_str = intString(indx) "print \"  \" & print comment_str & print \" former: \" & print old_name &" ;
        str = dumpTypeStr(var_type);print( " type: "); print(str);
        print(ComponentReference.printComponentRef2Str("", arrayDim));
        print(" indx = ");
        print(indx_str);
        varno_1 = varno + 1;
        print(" fixed:");print(boolString(BackendVariable.varFixed(v)));
        print("\n");
        dumpVars2(xs, varno_1) "DAEDump.dump_variable_attributes(dae_var_attr) &" ;
      then
        ();

    case (((v as BackendDAE.VAR(varName = cr,
                     varKind = kind,
                     varDirection = dir,
                     varType = var_type,
                     arryDim = arrayDim,
                     bindExp = NONE(),
                     index = indx,
                     source = source,
                     values = dae_var_attr,
                     comment = comment,
                     flowPrefix = flowPrefix,
                     streamPrefix = streamPrefix)) :: xs),varno)
      equation
        varnostr = intString(varno);
        print(varnostr);
        print(": ");
        dirstr = DAEDump.dumpDirectionStr(dir);
        print(dirstr);
        print(" ");
        str = ComponentReference.printComponentRefStr(cr);
        paths = DAEUtil.getElementSourceTypes(source);
        path_strs = Util.listMap(paths, Absyn.pathString);
        path_str = Util.stringDelimitList(path_strs, ", ");
        comment_str = DAEDump.dumpCommentOptionStr(comment);
        print(str);
        print(":");
        dumpKind(kind);
        b = DAEUtil.hasStartAttr(dae_var_attr);
        sstart = DAEUtil.getStartAttrString(dae_var_attr);
        sstart = Util.if_(b,stringAppendList({"(start = ",sstart,") "})," ");
        print(sstart);
        print(path_str);
        indx_str = intString(indx) "print \" former: \" & print old_name &" ;
        str = dumpTypeStr(var_type);print( " type: "); print(str);
        print(ComponentReference.printComponentRef2Str("", arrayDim));
        print(" indx = ");
        print(indx_str);
        print(" fixed:");print(boolString(BackendVariable.varFixed(v)));
        print("\n");
        varno_1 = varno + 1;
        dumpVars2(xs, varno_1);
      then
        ();

    case (v :: xs,varno)
      equation
        varnostr = intString(varno);
        print(varnostr);
        print(": UNKNOWN VAR!");
        print("\n");
        debug_print("variable",v);
        varno_1 = varno + 1;
        dumpVars2(xs, varno_1);
      then ();

  end matchcontinue;
end dumpVars2;

public function dumpKind
"function: dumpKind
  Helper function to dump."
  input BackendDAE.VarKind inVarKind;
algorithm
  _:=
  match (inVarKind)
    local Absyn.Path path;
    case BackendDAE.VARIABLE()    equation print("VARIABLE");    then ();
    case BackendDAE.STATE()       equation print("STATE");       then ();
    case BackendDAE.STATE_DER()   equation print("STATE_DER");   then ();
    case BackendDAE.DUMMY_DER()   equation print("DUMMY_DER");   then ();
    case BackendDAE.DUMMY_STATE() equation print("DUMMY_STATE"); then ();
    case BackendDAE.DISCRETE()    equation print("DISCRETE");    then ();
    case BackendDAE.PARAM()       equation print("PARAM");       then ();
    case BackendDAE.CONST()       equation print("CONST");       then ();
    case BackendDAE.EXTOBJ(path)  equation print("EXTOBJ: ");print(Absyn.pathString(path)); then ();
  end match;
end dumpKind;

public function dumpIncidenceMatrix
"function: dumpIncidenceMatrix
  author: PA
  Prints the incidence matrix on stdout."
  input BackendDAE.IncidenceMatrix m;
  BackendDAE.Value mlen;
  String mlen_str;
  list<list<BackendDAE.Value>> m_1;
algorithm
  print("Incidence Matrix (row == equation)\n");
  print("====================================\n");
  mlen := arrayLength(m);
  mlen_str := intString(mlen);
  print("number of rows: ");
  print(mlen_str);
  print("\n");
  m_1 := arrayList(m);
  dumpIncidenceMatrix2(m_1,1);
end dumpIncidenceMatrix;

public function dumpIncidenceMatrixT
"function: dumpIncidenceMatrixT
  author: PA
  Prints the transposed incidence matrix on stdout."
  input BackendDAE.IncidenceMatrix m;
  BackendDAE.Value mlen;
  String mlen_str;
  list<list<BackendDAE.Value>> m_1;
algorithm
  print("Transpose Incidence Matrix (row == var)\n");
  print("=====================================\n");
  mlen := arrayLength(m);
  mlen_str := intString(mlen);
  print("number of rows: ");
  print(mlen_str);
  print("\n");
  m_1 := arrayList(m);
  dumpIncidenceMatrix2(m_1,1);
end dumpIncidenceMatrixT;

protected function dumpIncidenceMatrix2
"function: dumpIncidenceMatrix2
  author: PA
  Helper function to dumpIncidenceMatrix (+T)."
  input list<list<Integer>> inIntegerLstLst;
  input Integer rowIndex;
algorithm
  _ := match (inIntegerLstLst,rowIndex)
    local
      list<BackendDAE.Value> row;
      list<list<BackendDAE.Value>> rows;
    case ({},_) then ();
    case ((row :: rows),rowIndex)
      equation
        print(intString(rowIndex));print(":");
        dumpIncidenceRow(row);
        dumpIncidenceMatrix2(rows,rowIndex+1);
      then
        ();
  end match;
end dumpIncidenceMatrix2;

protected function dumpIncidenceRow
"function: dumpIncidenceRow
  author: PA
  Helper function to dumpIncidenceMatrix2."
  input list<Integer> inIntegerLst;
algorithm
  _ := match (inIntegerLst)
    local
      String s;
      BackendDAE.Value x;
      list<BackendDAE.Value> xs;
    case ({})
      equation
        print("\n");
      then
        ();
    case ((x :: xs))
      equation
        s = intString(x);
        print(s);
        print(" ");
        dumpIncidenceRow(xs);
      then
        ();
  end match;
end dumpIncidenceRow;

public function dumpMatching
"function: dumpMatching
  author: PA
  prints the matching information on stdout."
  input array<Integer> v;
  BackendDAE.Value len;
  String len_str;
algorithm
  print("Matching\n");
  print("========\n");
  len := arrayLength(v);
  len_str := intString(len);
  print(len_str);
  print(" variables and equations\n");
  dumpMatching2(v, 0);
end dumpMatching;

protected function dumpMatching2
"function: dumpMatching2
  author: PA
  Helper function to dumpMatching."
  input array<Integer> inIntegerArray;
  input Integer inInteger;
algorithm
  _ := matchcontinue (inIntegerArray,inInteger)
    local
      BackendDAE.Value len,i_1,eqn,i;
      String s,s2;
      array<BackendDAE.Value> v;
    case (v,i)
      equation
        len = arrayLength(v);
        i_1 = i + 1;
        (len == i_1) = true;
        s = intString(i_1);
        eqn = v[i + 1];
        s2 = intString(eqn);
        print("var ");
        print(s);
        print(" is solved in eqn ");
        print(s2);
        print("\n");
      then
        ();
    case (v,i)
      equation
        len = arrayLength(v);
        i_1 = i + 1;
        (len == i_1) = false;
        s = intString(i_1);
        eqn = v[i + 1];
        s2 = intString(eqn);
        print("var ");
        print(s);
        print(" is solved in eqn ");
        print(s2);
        print("\n");
        dumpMatching2(v, i_1);
      then
        ();
  end matchcontinue;
end dumpMatching2;

public function dumpMarkedEqns
"Dumps only the equations given as list of indexes to a string."
  input BackendDAE.BackendDAE inBackendDAE;
  input list<Integer> inIntegerLst;
  output String outString;
algorithm
  outString := match (inBackendDAE,inIntegerLst)
    local
      String s1,s2,res;
      BackendDAE.Value e_1,e;
      BackendDAE.Equation eqn;
      BackendDAE.BackendDAE dae;
      BackendDAE.EquationArray eqns;
      list<BackendDAE.Value> es;
    case (_,{}) then "";
    case ((dae as BackendDAE.DAE(orderedEqs = eqns)),(e :: es))
      equation
        s1 = dumpMarkedEqns(dae, es);
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        s2 = equationStr(eqn);
        res = stringAppendList({s2,";\n",s1});
      then
        res;
  end match;
end dumpMarkedEqns;

public function dumpMarkedVars
"Dumps only the variable names given as list of indexes to a string."
  input BackendDAE.BackendDAE inBackendDAE;
  input list<Integer> inIntegerLst;
  output String outString;
algorithm
  outString:=
  match (inBackendDAE,inIntegerLst)
    local
      String s1,s2,res,s3;
      BackendDAE.Value v;
      DAE.ComponentRef cr;
      BackendDAE.BackendDAE dae;
      BackendDAE.Variables vars;
      list<BackendDAE.Value> vs;
    case (_,{}) then "";
    case ((dae as BackendDAE.DAE(orderedVars = vars)),(v :: vs))
      equation
        s1 = dumpMarkedVars(dae, vs);
        BackendDAE.VAR(varName = cr) = BackendVariable.getVarAt(vars, v);
        s2 = ComponentReference.printComponentRefStr(cr);
        s3 = intString(v);
        res = stringAppendList({s2,"(",s3,"), ",s1});
      then
        res;
  end match;
end dumpMarkedVars;

public function dumpComponentsGraphStr
"Dumps the assignment graph used to determine strong
 components to format suitable for Mathematica"
  input Integer n;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ass1;
  input array<Integer> ass2;
  output String res;
algorithm
  res := match(n,m,mT,ass1,ass2)
    local list<String> lst;  
    case(n,m,mT,ass1,ass2)
      equation
        lst = dumpComponentsGraphStr2(1,n,m,mT,ass1,ass2);
        res = Util.stringDelimitList(lst,",");
        res = stringAppendList({"{",res,"}"});
      then res;
  end match;
end dumpComponentsGraphStr;

protected function dumpComponentsGraphStr2 "help function"
  input Integer i;
  input Integer n;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ass1;
  input array<Integer> ass2;
  output list<String> lst;
algorithm
  lst := matchcontinue(i,n,m,mT,ass1,ass2)
    local
      list<list<Integer>> llst;
      list<Integer> eqns;
      list<String> strLst,slst;
      String str;
    case(i,n,m,mT,ass1,ass2) equation
      true = (i > n);
      then {};
    case(i,n,m,mT,ass1,ass2)
      equation
        eqns = BackendDAETransform.reachableNodes(i, m, mT, ass1, ass2);
        llst = Util.listMap(eqns,Util.listCreate);
        llst = Util.listMap1(llst,Util.listCons,i);
        slst = Util.listMap(llst,intListStr);
        str = Util.stringDelimitList(slst,",");
        str = stringAppendList({"{",str,"}"});
        strLst = dumpComponentsGraphStr2(i+1,n,m,mT,ass1,ass2);
      then str::strLst;
  end matchcontinue;
end dumpComponentsGraphStr2;

protected function dumpList "function: dumpList
  author: PA

  Helper function to dump.
"
  input list<Integer> l;
  input String str;
  list<String> s;
  String sl;
algorithm
  s := Util.listMap(l, intString);
  sl := Util.stringDelimitList(s, ", ");
  print(str);
  print(sl);
  print("\n");
end dumpList;

public function dumpComponents "function: dumpComponents
  author: PA

  Prints the blocks of the BLT sorting on stdout.
"
  input list<list<Integer>> l;
algorithm
  print("Blocks\n");
  print("=======\n");
  dumpComponents2(l, 1);
end dumpComponents;

protected function dumpComponents2 "function: dumpComponents2
  author: PA

  Helper function to dump_components.
"
  input list<list<Integer>> inIntegerLstLst;
  input Integer inInteger;
algorithm
  _:=
  match (inIntegerLstLst,inInteger)
    local
      BackendDAE.Value ni,i_1,i;
      list<String> ls;
      String s;
      list<BackendDAE.Value> l;
      list<list<BackendDAE.Value>> lst;
    case ({},_) then ();
    case ((l :: lst),i)
      equation
        ni = BackendDAEEXT.getLowLink(i);
        print("{");
        ls = Util.listMap(l, intString);
        s = Util.stringDelimitList(ls, ", ");
        print(s);
        print("}\n");
        i_1 = i + 1;
        dumpComponents2(lst, i_1);
      then
        ();
  end match;
end dumpComponents2;

protected function intListStr "Takes a list of Integers and produces a string  on form: \"{1,2,3}\" "
  input list<Integer> lst;
  output String res;
algorithm
  res := Util.stringDelimitList(Util.listMap(lst,intString),",");
  res := stringAppendList({"{",res,"}"});
end intListStr;

public function dumpAliasVariables "function: dumpAliasVariables
  author: Frenkel TUD 2010-12

  dump AliasVariables.
"
  input BackendDAE.AliasVariables inAliasVars;
protected
  HashTable2.HashTable varMappings;
  BackendDAE.Variables aliasVars;
  String sl;
  Integer l;
algorithm
  BackendDAE.ALIASVARS(varMappings,aliasVars) := inAliasVars;
  l := BackendVariable.varsSize(aliasVars);
  sl := intString(l);
  print("AliasVariables: ");
  print(sl);
  print("\n===============\n");
  _ := BackendVariable.traverseBackendDAEVars(aliasVars,dumpAliasVariable,varMappings);
  print("\n");
end dumpAliasVariables;

protected function dumpAliasVariable
"autor: Frenkel TUD 2010-11"
 input tuple<BackendDAE.Var, HashTable2.HashTable> inTpl;
 output tuple<BackendDAE.Var, HashTable2.HashTable> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      HashTable2.HashTable varMappings;
      DAE.Exp e;
      String s,scr,se;
    case ((v,varMappings))
      equation
        cr = BackendVariable.varCref(v);
        // does not work
        //e = BaseHashTable.get(cr,varMappings);
        e = BackendVariable.varBindExp(v);
        scr = ComponentReference.printComponentRefStr(cr);
        se = ExpressionDump.printExpStr(e);
        s = stringAppendList({scr," = ",se,"\n"});
        print(s);
      then ((v,varMappings));
    case inTpl then inTpl; 
  end matchcontinue;
end dumpAliasVariable;

public function dumpStateVariables "function: dumpStateVariables
  author: Frenkel TUD 2010-12

  dump State Variables.
"
  input BackendDAE.Variables inVars;
algorithm
  print("States Variables\n");
  print("=================\n");
  _ := BackendVariable.traverseBackendDAEVars(inVars,dumpStateVariable,1);
  print("\n");
end dumpStateVariables;

protected function dumpStateVariable
"autor: Frenkel TUD 2010-11"
 input tuple<BackendDAE.Var, Integer> inTpl;
 output tuple<BackendDAE.Var, Integer> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      String scr;
      Integer pos;
    case ((v,pos))
      equation
        true = BackendVariable.isStateVar(v);
        cr = BackendVariable.varCref(v);
        scr = ComponentReference.printComponentRefStr(cr);
        print(intString(pos)); print(": ");
        print(scr); print("\n");
      then ((v,pos+1));
    case inTpl then inTpl; 
  end matchcontinue;
end dumpStateVariable;

end BackendDump;
