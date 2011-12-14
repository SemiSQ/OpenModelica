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

encapsulated package PartFn
" file:        PartFn.mo
  package:     PartFn
  description: partially evaluated functions

  RCS: $Id$

  This module contains data structures and functions for partially evaulated functions.
  entry point: createPartEvalFunctions, partEvalBackendDAE, partEvalDAE
  "

public import Absyn;
public import BackendDAE;
public import DAE;
public import Debug;
public import SCode;
public import Values;

protected import ComponentReference;
protected import DAEUtil;
protected import Error;
protected import Expression;
protected import Flags;
protected import List;
protected import Types;
protected import Util;

type Ident = String;

public function partEvalBackendDAE
"function: partEvalBackendDAE
  handles partially evaluated function in BackendDAE format"
  input BackendDAE.EqSystem syst;
  input Boolean dummy;
  input tuple<BackendDAE.Shared,list<DAE.Function>> sharedAndFuncs;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared,list<DAE.Function>> osharedAndFuncs;
algorithm
  (osyst,osharedAndFuncs) := matchcontinue(syst,dummy,sharedAndFuncs)
    local
      list<DAE.Function> dae;
      BackendDAE.Variables orderedVars;
      BackendDAE.Variables knownVars;
      BackendDAE.Variables externalObjects;
      BackendDAE.AliasVariables aliasVars "alias-variables' hashtable";
      BackendDAE.EquationArray orderedEqs;
      BackendDAE.EquationArray removedEqs;
      BackendDAE.EquationArray initialEqs;
      array<BackendDAE.MultiDimEquation> arrayEqs;
      array<DAE.Algorithm> algorithms;
      BackendDAE.EventInfo eventInfo;
      BackendDAE.ExternalObjectClasses extObjClasses;
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.BackendDAEType btp;
      BackendDAE.Matching matching;
      BackendDAE.Shared shared;
    /*case(dae,dlow)
      equation
        false = Flags.isSet(Flags.FNPTR) or Config.acceptMetaModelicaGrammar();
      then
        (dae,dlow);*/
    case (BackendDAE.EQSYSTEM(orderedVars,orderedEqs,m,mT,matching),_,(BackendDAE.SHARED(knownVars,externalObjects,aliasVars,initialEqs,removedEqs,arrayEqs,algorithms,eventInfo,extObjClasses,btp),dae))
      equation
        (orderedVars,dae) = partEvalVars(orderedVars,dae);
        (knownVars,dae) = partEvalVars(knownVars,dae);
        (externalObjects,dae) = partEvalVars(externalObjects,dae);
        (orderedEqs,dae) = partEvalEqArr(orderedEqs,dae);
        (removedEqs,dae) = partEvalEqArr(removedEqs,dae);
        (initialEqs,dae) = partEvalEqArr(initialEqs,dae);
        (arrayEqs,dae) = partEvalArrEqs(arrayList(arrayEqs),dae);
        (algorithms,dae) = partEvalAlgs(algorithms,dae);
      then
        (BackendDAE.EQSYSTEM(orderedVars,orderedEqs,m,mT,matching),(BackendDAE.SHARED(knownVars,externalObjects,aliasVars,initialEqs,removedEqs,arrayEqs,algorithms,eventInfo,extObjClasses,btp),dae));
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"PartFn.partEvalBackendDAE failed"});
      then
        fail();
  end matchcontinue;
end partEvalBackendDAE;

protected function partEvalAlgs
"function: partEvalAlgs
  elabs an algorithm section in BackendDAE"
  input array<DAE.Algorithm> inAlgorithms;
  input list<DAE.Function> inElementList;
  output array<DAE.Algorithm> outAlgorithms;
  output list<DAE.Function> outElementList;
algorithm
  (outAlgorithms,outElementList) := matchcontinue(inAlgorithms,inElementList)
    local
      array<DAE.Algorithm> algarr,algarr_1;
      list<DAE.Algorithm> alglst,alglst_1;
      list<DAE.Function> dae;
    case(algarr,dae)
      equation
        alglst = arrayList(algarr);
        (alglst_1,dae) = partEvalAlgLst(alglst,dae);
        algarr_1 = listArray(alglst_1);
      then
        (algarr_1,dae);
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"- PartFn.partEvalAlgs failed");
      then
        fail();
  end matchcontinue;
end partEvalAlgs;

protected function partEvalAlgLst
"function: partEvalAlgLst
  elabs a list of algorithm sections"
  input list<DAE.Algorithm> inAlgorithmList;
  input list<DAE.Function> inElementList;
  output list<DAE.Algorithm> outAlgorithmList;
  output list<DAE.Function> outElementList;
algorithm
  (outAlgorithmList,outElementList) := matchcontinue(inAlgorithmList,inElementList)
    local
      list<DAE.Algorithm> cdr,cdr_1;
      list<DAE.Function> dae;
      DAE.Algorithm alg,alg_1;
    case({},dae) then ({},dae);
    case(alg :: cdr,dae)
      equation
        (alg_1,dae) = elabAlg(alg,dae);
        (cdr_1,dae) = partEvalAlgLst(cdr,dae);
      then
        (alg_1 :: cdr,dae);
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"- PartFn.partEvalAlgLst failed");
      then
        fail();
  end matchcontinue;
end partEvalAlgLst;

protected function partEvalArrEqs
"function: partEvalArrEqs
  elabs calls in array equations"
  input list<BackendDAE.MultiDimEquation> inMultiDimList;
  input list<DAE.Function> inElementList;
  output array<BackendDAE.MultiDimEquation> outMultiDimArr;
  output list<DAE.Function> outElementList;
algorithm
  (outMultiDimArr,outElementList) := matchcontinue(inMultiDimList,inElementList)
    local
      list<BackendDAE.MultiDimEquation> cdr,mdelst;
      list<DAE.Function> dae;
      array<BackendDAE.MultiDimEquation> res,cdr_1;
      list<Integer> ds;
      DAE.Exp e1,e1_1,e2,e2_1;
      DAE.ElementSource source "the origin of the element";

    case({},dae) then (listArray({}),dae);
    case(BackendDAE.MULTIDIM_EQUATION(ds,e1,e2,source) :: cdr,dae)
      equation
        ((e1_1,dae)) = Expression.traverseExp(e1,elabExp,dae);
        ((e2_1,dae)) = Expression.traverseExp(e2,elabExp,dae);
        (cdr_1,dae) = partEvalArrEqs(cdr,dae);
        mdelst = {BackendDAE.MULTIDIM_EQUATION(ds,e1_1,e2_1,source)};
        res = Util.arrayAppend(listArray(mdelst),cdr_1);
      then
        (res,dae);
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"- PartFn.partEvalArrEqs failed");
      then
        fail();
  end matchcontinue;
end partEvalArrEqs;

protected function partEvalVars
"function: partEvalVars
  elab calls in lowered variables"
  input BackendDAE.Variables inVariables;
  input list<DAE.Function> inFunctions;
  output BackendDAE.Variables outVariables;
  output list<DAE.Function> outFunctions;
algorithm
  (outVariables,outFunctions) := matchcontinue(inVariables,inFunctions)
    local
      list<DAE.Function> dae;
      array<list<BackendDAE.CrefIndex>> crind;
      Integer bsi,nov,noe,asi;
      array<Option<BackendDAE.Var>> varr,varr_1;
      list<Option<BackendDAE.Var>> vlst,vlst_1;
    
    case(BackendDAE.VARIABLES(crind,BackendDAE.VARIABLE_ARRAY(noe,asi,varr),bsi,nov),dae)
      equation
        vlst = arrayList(varr);
        (vlst_1,dae) = partEvalVarLst(vlst,dae);
        varr_1 = listArray(vlst_1);
      then
        (BackendDAE.VARIABLES(crind,BackendDAE.VARIABLE_ARRAY(noe,asi,varr_1),bsi,nov),dae);
    
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"- PartFn.partEvalVars failed");
      then
        fail();
  end matchcontinue;
end partEvalVars;

protected function partEvalVarLst
"function: partEvalVarLst
  evals partevalfuncs in a BackendDAE.var option list"
  input list<Option<BackendDAE.Var>> inVarList;
  input list<DAE.Function> inElementList;
  output list<Option<BackendDAE.Var>> outVarList;
  output list<DAE.Function> outElementList;
algorithm
  (outVarList,outElementList) := matchcontinue(inVarList,inElementList)
    local
      list<DAE.Function> dae;
      list<Option<BackendDAE.Var>> cdr,cdr_1;
      DAE.ComponentRef varName;
      BackendDAE.VarKind varKind;
      DAE.VarDirection varDirection;
      BackendDAE.Type varType;
      Option<DAE.Exp> bindExp,bindExp_1;
      Option<Values.Value> bindValue;
      DAE.InstDims arryDim;
      Integer index;
      Option<DAE.VariableAttributes> values;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      DAE.ElementSource source "the origin of the element";

    case({},dae) then ({},dae);
    case( NONE():: cdr,dae)
      equation
        (cdr_1,dae) = partEvalVarLst(cdr,dae);
      then
        ( NONE():: cdr_1,dae);
    case(SOME(BackendDAE.VAR(varName,varKind,varDirection,varType,bindExp,bindValue,arryDim,index,
                         source,values,comment,flowPrefix,streamPrefix)) :: cdr,dae)
      equation
        (bindExp_1,dae) = elabExpOption(bindExp,dae);
        (cdr_1,dae) = partEvalVarLst(cdr,dae);
      then
        (SOME(BackendDAE.VAR(varName,varKind,varDirection,varType,bindExp_1,bindValue,arryDim,index,
                         source,values,comment,flowPrefix,streamPrefix)) :: cdr_1,dae);
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"- PartFn.partEvalVarLst failed");
      then
        fail();
  end matchcontinue;
end partEvalVarLst;

protected function partEvalEqArr
"function: partEvalEqArr
  elabs calls in equations"
  input BackendDAE.EquationArray inEquationArray;
  input list<DAE.Function> inFunctions;
  output BackendDAE.EquationArray outEquationArray;
  output list<DAE.Function> outFunctions;
algorithm
  (outEquationArray,outFunctions) := matchcontinue(inEquationArray,inFunctions)
    local
      list<DAE.Function> dae;
      list<Option<BackendDAE.Equation>> eqlst;
      array<Option<BackendDAE.Equation>> eqarr;
      Integer num,size;
    case(BackendDAE.EQUATION_ARRAY(num,size,eqarr),dae)
      equation
        eqlst = arrayList(eqarr);
        (eqlst,dae) = partEvalEqs(eqlst,dae);
        eqarr = listArray(eqlst);
      then
        (BackendDAE.EQUATION_ARRAY(num,size,eqarr),dae);
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"- PartFn.partEvalEqArr failed");
      then
        fail();
  end matchcontinue;
end partEvalEqArr;

protected function partEvalEqs
"function: partEvalEqs
  elabs calls in equations"
  input list<Option<BackendDAE.Equation>> inEquationList;
  input list<DAE.Function> inFunctions;
  output list<Option<BackendDAE.Equation>> outEquationList;
  output list<DAE.Function> outFunctions;
algorithm
  (outEquationList,outFunctions) := matchcontinue(inEquationList,inFunctions)
    local
      list<Option<BackendDAE.Equation>> cdr,cdr_1;
      list<DAE.Function> dae;
      DAE.Exp e,e_1,e1,e1_1,e2,e2_1;
      Integer i;
      list<DAE.Exp> elst,elst_1,elst1,elst1_1,elst2,elst2_1;
      DAE.ComponentRef cref;
      BackendDAE.WhenEquation we,we_1;
      DAE.ElementSource source "the origin of the element";

    case({},dae) then ({},dae);
    case( NONE():: cdr,dae)
      equation
        (cdr_1,dae) = partEvalEqs(cdr,dae);
      then
        ( NONE():: cdr_1,dae);

    case(SOME(BackendDAE.EQUATION(e1,e2,source)) :: cdr,dae)
      equation
        ((e1_1,dae)) = Expression.traverseExp(e1,elabExp,dae);
        ((e2_1,dae)) = Expression.traverseExp(e2,elabExp,dae);
        (cdr_1,dae) = partEvalEqs(cdr,dae);
      then
        (SOME(BackendDAE.EQUATION(e1_1,e2_1,source)) :: cdr_1,dae);

    case(SOME(BackendDAE.ARRAY_EQUATION(i,elst,source)) :: cdr,dae)
      equation
        (elst_1,dae) = elabExpList(elst,dae);
        (cdr_1,dae) = partEvalEqs(cdr,dae);
      then
        (SOME(BackendDAE.ARRAY_EQUATION(i,elst_1,source)) :: cdr_1,dae);

    case(SOME(BackendDAE.SOLVED_EQUATION(cref,e,source)) :: cdr,dae)
      equation
        ((e_1,dae)) = Expression.traverseExp(e,elabExp,dae);
        (cdr_1,dae) = partEvalEqs(cdr,dae);
      then
        (SOME(BackendDAE.SOLVED_EQUATION(cref,e_1,source)) :: cdr_1,dae);

    case(SOME(BackendDAE.RESIDUAL_EQUATION(e,source)) :: cdr,dae)
      equation
        ((e_1,dae)) = Expression.traverseExp(e,elabExp,dae);
        (cdr_1,dae) = partEvalEqs(cdr,dae);
      then
        (SOME(BackendDAE.RESIDUAL_EQUATION(e_1,source)) :: cdr_1,dae);

    case(SOME(BackendDAE.ALGORITHM(i,elst1,elst2,source)) :: cdr,dae)
      equation
        (elst1_1,dae) = elabExpList(elst1,dae);
        (elst2_1,dae) = elabExpList(elst2,dae);
        (cdr_1,dae) = partEvalEqs(cdr,dae);
      then
        (SOME(BackendDAE.ALGORITHM(i,elst1_1,elst2_1,source)) :: cdr_1,dae);

    case(SOME(BackendDAE.WHEN_EQUATION(we,source)) :: cdr,dae)
      equation
        (we_1,dae) = partEvalWhenEq(we,dae);
        (cdr_1,dae) = partEvalEqs(cdr,dae);
      then
        (SOME(BackendDAE.WHEN_EQUATION(we_1,source)) :: cdr_1,dae);

    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"- PartFn.partEvalEqs failed");
      then
        fail();
  end matchcontinue;
end partEvalEqs;

protected function partEvalWhenEq
"function: partEvalWhenEq
  elabs calls in a BackendDAE when equation"
  input BackendDAE.WhenEquation inWhenEquation;
  input list<DAE.Function> inElementList;
  output BackendDAE.WhenEquation outWhenEquation;
  output list<DAE.Function> outElementList;
algorithm
  (outWhenEquation,outElementList) := matchcontinue(inWhenEquation,inElementList)
    local
      list<DAE.Function> dae;
      Integer i;
      DAE.ComponentRef cref;
      DAE.Exp e,e_1;
      BackendDAE.WhenEquation we,we_1;
    case(BackendDAE.WHEN_EQ(i,cref,e,SOME(we)),dae)
      equation
        ((e_1,dae)) = Expression.traverseExp(e,elabExp,dae);
        (we_1,dae) = partEvalWhenEq(we,dae);
      then
        (BackendDAE.WHEN_EQ(i,cref,e_1,SOME(we_1)),dae);
    case(BackendDAE.WHEN_EQ(i,cref,e,NONE()),dae)
      equation
        ((e_1,dae)) = Expression.traverseExp(e,elabExp,dae);
      then
        (BackendDAE.WHEN_EQ(i,cref,e_1,NONE()),dae);
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"- PartFn.partEvalWhenEq failed");
      then
        fail();
  end matchcontinue;
end partEvalWhenEq;

public function partEvalDAE
"function: partEvalDAE
  goes through the DAE for Expression.PARTEVALFUNCTION, creates new classes and changes the function calls"
  input DAE.DAElist inDAE;
  input list<DAE.Function> infuncs;
  output DAE.DAElist outDAE;
  output list<DAE.Function> outfuncs;
algorithm
  (outDAE,outfuncs) := matchcontinue(inDAE,infuncs)
    local
      list<DAE.Element> elts,elts_1;
      list<DAE.Function> dae;
      DAE.DAElist dlst;
    /*case(dlst,dae)
      equation
        false = Flags.isSet(Flags.FNPTR) or Config.acceptMetaModelicaGrammar();
      then
        (dlst,dae);*/
    case(DAE.DAE(elts),dae)
      equation
        (elts_1,dae) = elabElements(elts,dae);
        dlst = DAE.DAE(elts_1);
      then
        (dlst,dae);
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"- PartFn.partEvalDAE failed");
      then
        fail();
  end matchcontinue;
end partEvalDAE;

public function createPartEvalFunctions
"function: createPartEvalFunctions
  goes through the DAE for Expression.PARTEVALFUNCTION, creates new classes and changes the function calls"
  input list<DAE.Function> inDAElist;
  output list<DAE.Function> outDAElist;
algorithm
  outDAElist := matchcontinue(inDAElist)
    local
      list<DAE.Function> elts,elts_1;
    /*case(elts)
      equation
        false = Flags.isSet(Flags.FNPTR) or Config.acceptMetaModelicaGrammar();
      then
        elts;*/
    case(elts)
      equation
        (_,elts_1) = elabFunctions(elts,elts);
      then
        elts_1;
    case(_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"PartFn.createPartEvalFunctions failed");
      then
        fail();
  end matchcontinue;
end createPartEvalFunctions;

protected function replaceFnInFnLst
"function: replaceFnInFnLst
  takes a given function and replaces the function with the same path in the daelist with it"
  input DAE.Function inFunction;
  input list<DAE.Function> inElementList;
  output list<DAE.Function> outElementList;
algorithm
  outElementList := matchcontinue(inFunction,inElementList)
    local
      list<DAE.Function> cdr,cdr_1;
      Absyn.Path newFn,p;
      DAE.Function fn, el;
    case(_,{})
      equation
        Debug.fprintln(Flags.FAILTRACE,"- PartFn.replaceFnInFnLst failed");
      then
        fail();
    case(fn as DAE.FUNCTION(path = newFn),DAE.FUNCTION(path = p) :: cdr)
      equation
        true = Absyn.pathEqual(newFn,p);
      then
        fn :: cdr;
    case(fn, el :: cdr)
      equation
        cdr_1 = replaceFnInFnLst(fn,cdr);
      then
        el :: cdr_1;
  end matchcontinue;
end replaceFnInFnLst;

protected function elabElements
"function: elabElements
  goes through a list of DAE.Element for partevalfunction"
  input list<DAE.Element> els;
  input list<DAE.Function> dae;
  output list<DAE.Element> oels;
  output list<DAE.Function> odae;
algorithm
  (oels,odae) := List.mapFold(els,elabElement,dae);
end elabElements;

protected function elabElement
"function: elabElements
  goes through a list of DAE.Element for partevalfunction"
  input DAE.Element iel;
  input list<DAE.Function> idae;
  output DAE.Element oel;
  output list<DAE.Function> odae;
algorithm
  (oel,odae) := match (iel,idae)
    local
      DAE.Function f1,f2;
      DAE.Element el_1,el;
      list<DAE.Element> cdr,cdr_1,elts,elts_1;
      list<list<DAE.Element>> elm,elm_1;
      DAE.ComponentRef cref;
      DAE.VarKind kind;
      DAE.VarDirection direction;
      DAE.VarVisibility protection;
      DAE.Type ty;
      Option<DAE.Exp> binding;
      DAE.InstDims dims;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      Option<DAE.VariableAttributes> variableAttributesOption;
      Option<SCode.Comment> absynCommentOption;
      Absyn.InnerOuter innerOuter;
      DAE.Dimensions ilst;
      Ident i;
      Absyn.Path p;
      list<DAE.Exp> elst,elst_1;
      DAE.Exp e,e_1,e1,e1_1,e2,e2_1;
      DAE.Algorithm alg,alg_1;
      DAE.ElementSource source "the origin of the element";
      list<DAE.Function> dae;

    case(DAE.VAR(cref,kind,direction,protection,ty,binding,dims,flowPrefix,streamPrefix,source,
                 variableAttributesOption,absynCommentOption,innerOuter),dae)
      equation
        (binding,dae) = elabExpOption(binding,dae);
      then
        (DAE.VAR(cref,kind,direction,protection,ty,binding,dims,flowPrefix,streamPrefix,source,
                 variableAttributesOption,absynCommentOption,innerOuter),dae);

    case(DAE.DEFINE(cref,e,source),dae)
      equation
        ((e_1,dae)) = Expression.traverseExp(e,elabExp,dae);
      then
        (DAE.DEFINE(cref,e_1,source),dae);

    case(DAE.INITIALDEFINE(cref,e,source),dae)
      equation
        ((e_1,dae)) = Expression.traverseExp(e,elabExp,dae);
      then
        (DAE.INITIALDEFINE(cref,e_1,source),dae);

    case(DAE.EQUATION(e1,e2,source),dae)
      equation
        ((e1_1,dae)) = Expression.traverseExp(e1,elabExp,dae);
        ((e2_1,dae)) = Expression.traverseExp(e2,elabExp,dae);
      then
        (DAE.EQUATION(e1_1,e2_1,source),dae);

    case(DAE.ARRAY_EQUATION(ilst,e1,e2,source),dae)
      equation
        ((e1_1,dae)) = Expression.traverseExp(e1,elabExp,dae);
        ((e2_1,dae)) = Expression.traverseExp(e2,elabExp,dae);
      then
        (DAE.ARRAY_EQUATION(ilst,e1_1,e2_1,source),dae);

    case(DAE.INITIAL_ARRAY_EQUATION(ilst,e1,e2,source),dae)
      equation
        ((e1_1,dae)) = Expression.traverseExp(e1,elabExp,dae);
        ((e2_1,dae)) = Expression.traverseExp(e2,elabExp,dae);
      then
        (DAE.INITIAL_ARRAY_EQUATION(ilst,e1_1,e2_1,source),dae);

    case(DAE.COMPLEX_EQUATION(e1,e2,source),dae)
      equation
        ((e1_1,dae)) = Expression.traverseExp(e1,elabExp,dae);
        ((e2_1,dae)) = Expression.traverseExp(e2,elabExp,dae);
      then
        (DAE.COMPLEX_EQUATION(e1_1,e2_1,source),dae);

    case(DAE.INITIAL_COMPLEX_EQUATION(e1,e2,source),dae)
      equation
        ((e1_1,dae)) = Expression.traverseExp(e1,elabExp,dae);
        ((e2_1,dae)) = Expression.traverseExp(e2,elabExp,dae);
      then
        (DAE.INITIAL_COMPLEX_EQUATION(e1_1,e2_1,source),dae);

    case(DAE.WHEN_EQUATION(e,elts,NONE(),source),dae)
      equation
        ((e_1,dae)) = Expression.traverseExp(e,elabExp,dae);
        (elts_1,dae) = elabElements(elts,dae);
      then
        (DAE.WHEN_EQUATION(e_1,elts_1,NONE(),source),dae);

    case(DAE.WHEN_EQUATION(e,elts,SOME(el),source),dae)
      equation
        ((e_1,dae)) = Expression.traverseExp(e,elabExp,dae);
        (elts_1,dae) = elabElements(elts,dae);
        ({el_1},dae) = elabElements({el},dae);
      then
        (DAE.WHEN_EQUATION(e_1,elts_1,SOME(el_1),source),dae);

    case(DAE.IF_EQUATION(elst,elm,elts,source),dae)
      equation
        (elst_1,dae) = elabExpList(elst,dae);
        (elm_1,{dae}) = List.map1_2(elm,elabElements,dae);
        (elts_1,dae) = elabElements(elts,dae);
      then
        (DAE.IF_EQUATION(elst_1,elm_1,elts_1,source),dae);

    case(DAE.INITIAL_IF_EQUATION(elst,elm,elts,source),dae)
      equation
        (elst_1,dae) = elabExpList(elst,dae);
        (elm_1,{dae}) = List.map1_2(elm,elabElements,dae);
        (elts_1,dae) = elabElements(elts,dae);
      then
        (DAE.INITIAL_IF_EQUATION(elst_1,elm_1,elts_1,source),dae);

    case(DAE.INITIALEQUATION(e1,e2,source),dae)
      equation
        ((e1_1,dae)) = Expression.traverseExp(e1,elabExp,dae);
        ((e2_1,dae)) = Expression.traverseExp(e2,elabExp,dae);
      then
        (DAE.INITIALEQUATION(e1_1,e2_1,source),dae);

    case(DAE.ALGORITHM(alg,source),dae)
      equation
        (alg_1,dae) = elabAlg(alg,dae);
      then
        (DAE.ALGORITHM(alg_1,source),dae);

    case(DAE.INITIALALGORITHM(alg,source),dae)
      equation
        (alg_1,dae) = elabAlg(alg,dae);
      then
        (DAE.INITIALALGORITHM(alg_1,source),dae);

    case(DAE.COMP(i,elts,source,absynCommentOption),dae)
      equation
        (elts_1,dae) = elabElements(elts,dae);
      then
        (DAE.COMP(i,elts_1,source,absynCommentOption),dae);

    case(DAE.ASSERT(e1,e2,source),dae)
      equation
        ((e1_1,dae)) = Expression.traverseExp(e1,elabExp,dae);
        ((e2_1,dae)) = Expression.traverseExp(e2,elabExp,dae);
      then
        (DAE.ASSERT(e1_1,e2_1,source),dae);

    case(DAE.TERMINATE(e,source),dae)
      equation
        ((e_1,dae)) = Expression.traverseExp(e,elabExp,dae);
      then
        (DAE.TERMINATE(e_1,source),dae);

    case(DAE.REINIT(cref,e,source),dae)
      equation
        ((e_1,dae)) = Expression.traverseExp(e,elabExp,dae);
      then
        (DAE.REINIT(cref,e_1,source),dae);

    case(DAE.NORETCALL(p,elst,source),dae)
      equation
        (elst_1,dae) = elabExpList(elst,dae);
      then
        (DAE.NORETCALL(p,elst_1,source),dae);

    case(el,dae) then (el,dae);

  end match;
end elabElement;

protected function elabFunctions
  input list<DAE.Function> fns;
  input list<DAE.Function> idae;
  output list<DAE.Function> ofn;
  output list<DAE.Function> odae;
algorithm
  (ofn,odae) := matchcontinue (fns,idae)
    local
      list<DAE.Element> elts,elts_1;
      DAE.Function fn;
      list<DAE.Function> cdr,cdr_1,dae;
      DAE.Type fullType;
      Absyn.Path p;
      Boolean pp;
      DAE.ExternalDecl ed;
      DAE.InlineType inlineType;
      DAE.ElementSource source "the origin of the element";
      Option<SCode.Comment> cmt;
      
    case ({},dae) then ({},dae);
    case(DAE.FUNCTION(p,{DAE.FUNCTION_DEF(elts)},fullType,pp,inlineType,source,cmt) :: cdr,dae)
      equation
        (elts_1,dae) = elabElements(elts,dae);
        (cdr_1,dae) = elabFunctions(cdr,dae);
        fn = DAE.FUNCTION(p,{DAE.FUNCTION_DEF(elts_1)},fullType,pp,inlineType,source,cmt);
        dae = replaceFnInFnLst(fn,dae);
      then
        (fn :: cdr_1,dae);

    case(DAE.FUNCTION(p,{DAE.FUNCTION_EXT(elts,ed)},fullType,pp,inlineType,source,cmt) :: cdr,dae)
      equation
        (elts_1,dae) = elabElements(elts,dae);
        (cdr_1,dae) = elabFunctions(cdr,dae);
        fn = DAE.FUNCTION(p,{DAE.FUNCTION_EXT(elts_1,ed)},fullType,pp,inlineType,source,cmt);
        dae = replaceFnInFnLst(fn,dae);
      then
        (fn :: cdr_1,dae);

    case(fn :: cdr,dae)
      equation
        (cdr_1,dae) = elabFunctions(cdr,dae);
      then
        (fn :: cdr_1,dae);

    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"PartFn.elabFunctions failed");
      then
        fail();
  end matchcontinue;
end elabFunctions;

protected function elabAlg
"function: elabAlg
  elaborates an algorithm section"
  input DAE.Algorithm inAlgorithm;
  input list<DAE.Function> inElementList;
  output DAE.Algorithm outAlgorithm;
  output list<DAE.Function> outElementList;
algorithm
  (outAlgorithm,outElementList) := matchcontinue(inAlgorithm,inElementList)
    local
      list<DAE.Statement> stmts,stmts_1;
      list<DAE.Function> dae;
    case(DAE.ALGORITHM_STMTS(stmts),dae)
      equation
        (stmts_1,dae) = elabStmts(stmts,dae);
      then
        (DAE.ALGORITHM_STMTS(stmts_1),dae);
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"- PartFn.elabAlg failed");
      then
        fail();
  end matchcontinue;
end elabAlg;

protected function elabStmts
"function: elabStmts
  elaborates a list of algorithm statements"
  input list<DAE.Statement> inStatements;
  input list<DAE.Function> inElementList;
  output list<DAE.Statement> outStatements;
  output list<DAE.Function> outElementList;
algorithm
  (outStatements,outElementList) := matchcontinue(inStatements,inElementList)
    local
      list<DAE.Statement> cdr,cdr_1,stmts,stmts_1;
      list<DAE.Function> dae;
      DAE.Type ty;
      DAE.Exp e,e_1,e1,e1_1,e2,e2_1;
      list<DAE.Exp> elst,elst_1;
      DAE.Else els,els_1;
      Boolean b;
      Ident i;
      list<Integer> ilst;
      DAE.Statement stmt,stmt_1;
      DAE.ElementSource source;
    case({},dae) then ({},dae);
    case(DAE.STMT_ASSIGN(ty,e1,e2,source) :: cdr,dae)
      equation
        ((e1_1,dae)) = Expression.traverseExp(e1,elabExp,dae);
        ((e2_1,dae)) = Expression.traverseExp(e2,elabExp,dae);
        (cdr_1,dae) = elabStmts(cdr,dae);
      then
        (DAE.STMT_ASSIGN(ty,e1_1,e2_1,source) :: cdr_1,dae);
    case(DAE.STMT_TUPLE_ASSIGN(ty,elst,e,source) :: cdr,dae)
      equation
        (elst_1,dae) = elabExpList(elst,dae);
        ((e_1,dae)) = Expression.traverseExp(e,elabExp,dae);
        (cdr_1,dae) = elabStmts(cdr,dae);
      then
        (DAE.STMT_TUPLE_ASSIGN(ty,elst_1,e_1,source) :: cdr_1,dae);
    case(DAE.STMT_IF(e,stmts,els,source) :: cdr,dae)
      equation
        ((e_1,dae)) = Expression.traverseExp(e,elabExp,dae);
        (stmts_1,dae) = elabStmts(stmts,dae);
        (els_1,dae) = elabElse(els,dae);
        (cdr_1,dae) = elabStmts(cdr,dae);
      then
        (DAE.STMT_IF(e_1,stmts_1,els_1,source) :: cdr_1,dae);
    case(DAE.STMT_FOR(ty,b,i,e,stmts,source) :: cdr,dae)
      equation
        ((e_1,dae)) = Expression.traverseExp(e,elabExp,dae);
        (stmts_1,dae) = elabStmts(stmts,dae);
        (cdr_1,dae) = elabStmts(cdr,dae);
      then
        (DAE.STMT_FOR(ty,b,i,e_1,stmts_1,source) :: cdr_1,dae);
    case(DAE.STMT_WHILE(e,stmts,source) :: cdr,dae)
      equation
        ((e_1,dae)) = Expression.traverseExp(e,elabExp,dae);
        (stmts_1,dae) = elabStmts(stmts,dae);
        (cdr_1,dae) = elabStmts(cdr,dae);
      then
        (DAE.STMT_WHILE(e_1,stmts_1,source) :: cdr_1,dae);
    case(DAE.STMT_WHEN(e,stmts,SOME(stmt),ilst,source) :: cdr,dae)
      equation
        ((e_1,dae)) = Expression.traverseExp(e,elabExp,dae);
        (stmts_1,dae) = elabStmts(stmts,dae);
        ({stmt_1},dae) = elabStmts({stmt},dae);
        (cdr_1,dae) = elabStmts(cdr,dae);
      then
        (DAE.STMT_WHEN(e_1,stmts_1,SOME(stmt_1),ilst,source) :: cdr_1,dae);
    case(DAE.STMT_WHEN(e,stmts,NONE(),ilst,source) :: cdr,dae)
      equation
        ((e_1,dae)) = Expression.traverseExp(e,elabExp,dae);
        (stmts_1,dae) = elabStmts(stmts,dae);
        (cdr_1,dae) = elabStmts(cdr,dae);
      then
        (DAE.STMT_WHEN(e_1,stmts_1,NONE(),ilst,source) :: cdr_1,dae);
    case(DAE.STMT_ASSERT(e1,e2,source) :: cdr,dae)
      equation
        ((e1_1,dae)) = Expression.traverseExp(e1,elabExp,dae);
        ((e2_1,dae)) = Expression.traverseExp(e2,elabExp,dae);
        (cdr_1,dae) = elabStmts(cdr,dae);
      then
        (DAE.STMT_ASSERT(e1_1,e2_1,source) :: cdr_1,dae);
    case(DAE.STMT_TERMINATE(e,source) :: cdr,dae)
      equation
        ((e_1,dae)) = Expression.traverseExp(e,elabExp,dae);
        (cdr_1,dae) = elabStmts(cdr,dae);
      then
        (DAE.STMT_TERMINATE(e_1,source) :: cdr_1,dae);
    case(DAE.STMT_REINIT(e1,e2,source) :: cdr,dae)
      equation
        ((e1_1,dae)) = Expression.traverseExp(e1,elabExp,dae);
        ((e2_1,dae)) = Expression.traverseExp(e2,elabExp,dae);
        (cdr_1,dae) = elabStmts(cdr,dae);
      then
        (DAE.STMT_REINIT(e1_1,e2_1,source) :: cdr_1,dae);
    case(DAE.STMT_NORETCALL(e,source) :: cdr,dae)
      equation
        ((e_1,dae)) = Expression.traverseExp(e,elabExp,dae);
        (cdr_1,dae) = elabStmts(cdr,dae);
      then
        (DAE.STMT_NORETCALL(e_1,source) :: cdr_1,dae);
    case(DAE.STMT_FAILURE(stmts,source) :: cdr,dae)
      equation
        (stmts_1,dae) = elabStmts(stmts,dae);
        (cdr_1,dae) = elabStmts(cdr,dae);
      then
        (DAE.STMT_FAILURE(stmts_1,source) :: cdr_1,dae);
    case(DAE.STMT_TRY(stmts,source) :: cdr,dae)
      equation
        (stmts_1,dae) = elabStmts(stmts,dae);
        (cdr_1,dae) = elabStmts(cdr,dae);
      then
        (DAE.STMT_TRY(stmts_1,source) :: cdr_1,dae);
    case(DAE.STMT_CATCH(stmts,source) :: cdr,dae)
      equation
        (stmts_1,dae) = elabStmts(stmts,dae);
        (cdr_1,dae) = elabStmts(cdr,dae);
      then
        (DAE.STMT_CATCH(stmts_1,source) :: cdr_1,dae);
    case(stmt :: cdr,dae)
      equation
        (cdr_1,dae) = elabStmts(cdr,dae);
      then
        (stmt :: cdr_1,dae);
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"- PartFn.elabStmts failed");
      then
        fail();
  end matchcontinue;
end elabStmts;

protected function elabElse
"function: elabElse
  elabs an algorithm else case"
  input DAE.Else inElse;
  input list<DAE.Function> inElementList;
  output DAE.Else outElse;
  output list<DAE.Function> outElementList;
algorithm
  (outElse,outElementList) := matchcontinue(inElse,inElementList)
    local
      DAE.Exp e,e_1;
      list<DAE.Statement> stmts,stmts_1;
      DAE.Else els,els_1;
      list<DAE.Function> dae;
    case(DAE.NOELSE(),dae) then (DAE.NOELSE(),dae);
    case(DAE.ELSEIF(e,stmts,els),dae)
      equation
        ((e_1,dae)) = Expression.traverseExp(e,elabExp,dae);
        (stmts_1,dae) = elabStmts(stmts,dae);
        (els_1,dae) = elabElse(els,dae);
      then
        (DAE.ELSEIF(e_1,stmts_1,els_1),dae);
    case(DAE.ELSE(stmts),dae)
      equation
        (stmts_1,dae) = elabStmts(stmts,dae);
      then
        (DAE.ELSE(stmts),dae);
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"- PartFn.elabElse failed");
      then
        fail();
  end matchcontinue;
end elabElse;

protected function elabExpMatrix
"function: elabExpMatrix
  elabs an exp matrix"
  input list<list<DAE.Exp>> inExpMatrix;
  input list<DAE.Function> inElementList;
  output list<list<DAE.Exp>> outExpMatrix;
  output list<DAE.Function> outElementList;
algorithm
  (outExpMatrix,outElementList) := matchcontinue(inExpMatrix,inElementList)
    local
      list<DAE.Function> dae;
      list<list<DAE.Exp>> cdr,cdr_1;
      list<DAE.Exp> elst,elst_1;
    case({},dae) then ({},dae);
    case(elst :: cdr,dae)
      equation
        (elst_1,dae) = elabExpList(elst,dae);
        (cdr_1,dae) = elabExpMatrix(cdr,dae);
      then
        (elst_1 :: cdr_1,dae);
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"- PartFn.elabExpMatrix failed");
      then
        fail();
  end matchcontinue;
end elabExpMatrix;

protected function elabExpList
"function: elabExpList
  elabs an exp list"
  input list<DAE.Exp> inExpList;
  input list<DAE.Function> inElementList;
  output list<DAE.Exp> outExpList;
  output list<DAE.Function> outElementList;
algorithm
  (outExpList,outElementList) := matchcontinue(inExpList,inElementList)
    local
      list<DAE.Function> dae;
      list<DAE.Exp> cdr,cdr_1;
      DAE.Exp e,e_1;
    case({},dae) then ({},dae);
    case(e :: cdr,dae)
      equation
        ((e_1,dae)) = Expression.traverseExp(e,elabExp,dae);
        (cdr_1,dae) = elabExpList(cdr,dae);
      then
        (e_1 :: cdr_1,dae);
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"- PartFn.elabExpMatrix failed");
      then
        fail();
  end matchcontinue;
end elabExpList;

protected function elabExpOption
"function: elabExpOption
  elabs an exp option if it is SOME, returns NONE() otherwise"
  input Option<DAE.Exp> inExp;
  input list<DAE.Function> inElementList;
  output Option<DAE.Exp> outExp;
  output list<DAE.Function> outElementList;
algorithm
  (outExp,outElementList) := match(inExp,inElementList)
    local
      DAE.Exp e,e_1;
      list<DAE.Function> dae;
    case(NONE(),dae) then (NONE(),dae);
    case(SOME(e),dae)
      equation
        ((e_1,dae)) = Expression.traverseExp(e,elabExp,dae);
      then
        (SOME(e_1),dae);
  end match;
end elabExpOption;

protected function elabExp
"function: elabExp
  looks for a function call, checks the arguments for DAE.PARTEVALFUNCTION
  creates new functions and replaces the call as necessary"
  input tuple<DAE.Exp, list<DAE.Function>> inTuple;
  output tuple<DAE.Exp, list<DAE.Function>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e;
      list<DAE.Function> dae;
      Absyn.Path p,p1,p_1;
      list<DAE.Exp> args,args1,args_1;
      DAE.Type ty;
      Boolean tu,bi;
      DAE.InlineType inl;
      Integer i,numArgs;
      DAE.CallAttributes attr;
    case((DAE.CALL(p,args,attr),dae))
      equation
        (DAE.PARTEVALFUNCTION(p1,args1,_),i) = getPartEvalFunction(args,0);
        numArgs = listLength(args1);
        args_1 = List.replaceAtWithList(args1,i,args);
        p_1 = makeNewFnPath(p,p1);
        dae = buildNewFunction(dae,p,p1,numArgs);
      then
        ((DAE.CALL(p_1,args_1,attr),dae));
    case((e,dae)) then ((e,dae));
  end matchcontinue;
end elabExp;

protected function makeNewFnPath
"function: makeNewFnPath
  creates a path for the new function using the path for the caller and the callee"
  input Absyn.Path inCaller;
  input Absyn.Path inCallee;
  output Absyn.Path newPath;
protected
  String s1,s2,s;
algorithm
  s1 := Absyn.pathStringNoQual(inCaller);
  s2 := Absyn.pathStringNoQual(inCallee);
  s := s1 +& "_" +& s2;
  newPath := Absyn.makeIdentPathFromString(s);
end makeNewFnPath;

protected function buildNewFunction
"function: buildNewFunction
  creates a new function from the old one, given the old and new paths"
  input list<DAE.Function> inElementList;
  input Absyn.Path inPath1;
  input Absyn.Path inPath2;
  input Integer inInteger;
  output list<DAE.Function> outElementList;
algorithm
  outElementList := matchcontinue(inElementList,inPath1,inPath2,inInteger)
    local
      list<DAE.Function> dae;
      DAE.Function fn1,fn2,newFn;
      Absyn.Path p1,p2,newPath;
      Integer numArgs;
    case(dae,p1,p2,numArgs)
      equation
        fn1 = DAEUtil.getNamedFunctionFromList(p1,dae);
        fn2 = DAEUtil.getNamedFunctionFromList(p2,dae);
        newPath = makeNewFnPath(p1,p2);
        newFn = buildNewFunction2(fn1,fn2,newPath,dae,numArgs);
      then
        newFn :: dae;
    case(_,_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"PartFn.buildNewFunction failed");
      then
        fail();
  end matchcontinue;
end buildNewFunction;

protected function buildNewFunction2
"function: buildNewFunction2
  creates a new function based on given data"
  input DAE.Function bigFunction;
  input DAE.Function smallFunction;
  input Absyn.Path inPath;
  input list<DAE.Function> inElementList;
  input Integer inInteger;
  output DAE.Function outFunction;
algorithm
  outFunction := matchcontinue(bigFunction,smallFunction,inPath,inElementList,inInteger)
    local
      DAE.Function bigfn,smallfn,res;
      Absyn.Path p,current;
      list<DAE.Function> dae;
      list<DAE.Element> fnparts,fnparts_1;
      DAE.Type ty;
      Boolean pp;
      Integer numArgs;
      list<DAE.Var> vars;
      DAE.InlineType inlineType;
      DAE.ElementSource source "the origin of the element";
      Option<SCode.Comment> cmt;

    case(bigfn as DAE.FUNCTION(current,{DAE.FUNCTION_DEF(fnparts)},ty,pp,inlineType,source,cmt),smallfn,p,dae,numArgs)
      equation
        (fnparts_1,vars) = buildNewFunctionParts(fnparts,smallfn,dae,numArgs,current);
        ty = buildNewFunctionType(ty,vars);
        res = DAE.FUNCTION(p,{DAE.FUNCTION_DEF(fnparts_1)},ty,pp,inlineType,source,cmt);
      then
        res;
    case(_,_,_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"PartFn.buildNewFunction2 failed");
      then
        fail();
  end matchcontinue;
end buildNewFunction2;

protected function buildNewFunctionType
"function: buildNewFunctionType
  removes the funcarg that is of T_FUNCTION type and inserts the list of vars as funcargs at the end"
  input DAE.Type inType;
  input list<DAE.Var> inVarList;
  output DAE.Type outType;
algorithm
  outType := matchcontinue(inType,inVarList)
    local
      list<DAE.Var> vars;
      list<DAE.FuncArg> args,args_1,args_2,new_args;
      DAE.Type retType;
      DAE.TypeSource ts;
      DAE.FunctionAttributes functionAttributes;
      
    case(DAE.T_FUNCTION(args,retType,functionAttributes,ts),vars)
      equation
        new_args = Types.makeFargsList(vars);
        args_1 = List.select(args,isNotFunctionType);
        args_2 = listAppend(args_1,new_args);
      then
        DAE.T_FUNCTION(args_2,retType,functionAttributes,ts);
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"- PartFn.buildNewFunctionType failed");
      then
        fail();
  end matchcontinue;
end buildNewFunctionType;

protected function isNotFunctionType
"function: isNotFunctionType
  checks to make sure a DAE.FuncArg is not of type T_FUNCTION"
  input DAE.FuncArg inFuncArg;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue(inFuncArg)
    case((_,DAE.T_FUNCTION(funcArg = _),_,_)) then false;
    case(_) then true;
  end matchcontinue;
end isNotFunctionType;

protected function buildNewFunctionParts
"function: buildNewFunctionParts
  inserts variables and alters call expressions in the new function"
  input list<DAE.Element> inFunctionParts;
  input DAE.Function smallFunction;
  input list<DAE.Function> inFunctions;
  input Integer inInteger;
  input Absyn.Path inPath;
  output list<DAE.Element> outFunctionParts;
  output list<DAE.Var> outVarList;
algorithm
  (outFunctionParts,outVarList) := matchcontinue(inFunctionParts,smallFunction,inFunctions,inInteger,inPath)
    local
      list<DAE.Function> dae;
      list<DAE.Element> parts,inputs,res,smallparts;
      DAE.Function smallfn;
      Absyn.Path p,current;
      String s;
      Integer numArgs;
      list<DAE.Var> vars;
    case(parts,smallfn as DAE.FUNCTION(path=p,
         functions={DAE.FUNCTION_DEF(smallparts)}),
         dae,numArgs,current)
      equation
        inputs = List.select(smallparts,isInput);
        s = Absyn.pathStringNoQual(p);
        inputs = List.map1(inputs,renameInput,s);
        inputs = listReverse(getFirstNInputs(listReverse(inputs),numArgs));
        res = insertAfterInputs(parts,inputs);
        res = fixCalls(res,dae,p,inputs,current);
        res = List.select(res,isNotFunctionInput);
        vars = List.map(inputs,buildTypeVar);
      then
        (res,vars);
    case(_,_,_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"PartFn.buildNewFunctionParts failed");
      then
        fail();
  end matchcontinue;
end buildNewFunctionParts;

protected function buildTypeVar
"function: buildTypeVar
  turns a DAE.VAR into Types.VAR"
  input DAE.Element inElement;
  output DAE.Var outVar;
algorithm
  outVar := matchcontinue(inElement)
    local
      DAE.ComponentRef cref;
      Ident i;
      DAE.Type ty;
      DAE.Var res;
    case(DAE.VAR(componentRef = cref,ty = ty))
      equation
        i = ComponentReference.printComponentRefStr(cref);
        // TODO: FIXME: binding?
        res = DAE.TYPES_VAR(i,DAE.ATTR(SCode.NOT_FLOW(),SCode.NOT_STREAM(),SCode.VAR(),Absyn.INPUT(),Absyn.NOT_INNER_OUTER()),SCode.PUBLIC(),ty,DAE.UNBOUND(),NONE()); 
      then
        res;
    case(_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"- PartFn.buildTypeVar failed");
      then
        fail();
  end matchcontinue;
end buildTypeVar;

protected function isNotFunctionInput
"function: isNotFunctionInput
  checks if an input var is of T_FUNCTION type"
  input DAE.Element inElement;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue(inElement)
    case DAE.VAR(direction = DAE.INPUT(),ty = DAE.T_FUNCTION(funcArg = _)) then false;
    case _ then true;
  end matchcontinue;
end isNotFunctionInput;

protected function getFirstNInputs
"function: getLastNInputs
  returns the last n inputs from a given list"
  input list<DAE.Element> inInputs;
  input Integer inInteger;
  output list<DAE.Element> outInputs;
algorithm
  outInputs := matchcontinue(inInputs,inInteger)
    local
      list<DAE.Element> cdr,cdr_1;
      DAE.Element el;
      Integer numArgs;
    case({},_) then {};
    case(_,0) then {};
    case(el :: cdr,numArgs)
      equation
        cdr_1 = getFirstNInputs(cdr,numArgs-1);
      then
        el :: cdr_1;
  end matchcontinue;
end getFirstNInputs;

protected function insertAfterInputs
"function: insertAfterInputs
  goes through the first list of DAE.Element until it finds the end of the inputs
  then inserts the given list of DAE.Element"
  input list<DAE.Element> inParts;
  input list<DAE.Element> inInputs;
  output list<DAE.Element> outParts;
algorithm
  outParts := matchcontinue(inParts,inInputs)
    local
      list<DAE.Element> cdr,inputs,res;
      DAE.Element e;
    case({},_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"PartFn.insertAfterInputs failed - no inputs found");
      then
        fail();
    case((e as DAE.VAR(direction = DAE.INPUT())) :: cdr,inputs)
      equation
        DAE.VAR(direction = DAE.INPUT()) = List.first(cdr);
        res = insertAfterInputs(cdr,inputs);
      then
        e :: res;
    case((e as DAE.VAR(direction = DAE.INPUT())) :: cdr,inputs)
      equation
        res = listAppend(inputs,cdr);
      then
        e :: res;
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"PartFn.insertAfterInputs failed - no inputs found");
      then
        fail();
  end matchcontinue;
end insertAfterInputs;

protected function renameInput
"function: renameInput
  assumes that the given element is a DAE.VAR with Input direction
  prepends the given string to the ComponentRef"
  input DAE.Element inElement;
  input String inString;
  output DAE.Element outElement;
algorithm
  outElement := matchcontinue(inElement,inString)
    local
      DAE.Element e,res;
      DAE.ComponentRef cref,cref_1;
      String s,s_1;
    case(e as DAE.VAR(componentRef = cref,direction=DAE.INPUT()),s)
      equation
        s_1 = stringAppend(s,"_");
        cref_1 = ComponentReference.prependStringCref(s_1,cref);
        res = DAEUtil.replaceCrefInVar(cref_1,e);
      then
        res;
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"PartFn.renameInput failed - expected input variable");
      then
        fail();
  end matchcontinue;
end renameInput;

protected function isInput
"function: isInput
  checks if a DAE.Element is an input var or not"
  input DAE.Element inElement;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue(inElement)
    case(DAE.VAR(direction = DAE.INPUT())) then true;
    case(_) then false;
  end matchcontinue;
end isInput;

protected function fixCalls
"function: fixCalls
  replaces calls in the newly built function with calls to the appropriate function, with the correct number of args"
  input list<DAE.Element> inParts;
  input list<DAE.Function> inDAE;
  input Absyn.Path inPath;
  input list<DAE.Element> inInputs;
  input Absyn.Path inCurrent;
  output list<DAE.Element> outParts;
algorithm
  outParts := matchcontinue(inParts,inDAE,inPath,inInputs,inCurrent)
    local
      list<DAE.Function> dae;
      list<DAE.Element> cdr,cdr_1,inputs;
      Absyn.Path p,current;
      DAE.Element part;
      DAE.ComponentRef cref;
      DAE.Exp e,e_1,e1,e1_1,e2,e2_1;
      list<DAE.Statement> alg,alg_1;
      DAE.Dimensions ilst;
      DAE.ComponentRef componentRef " The variable name";
      DAE.VarKind kind "varible kind: variable, constant, parameter, discrete etc." ;
      DAE.VarDirection direction "input, output or bidir" ;
      DAE.VarVisibility protection "if protected or public";
      DAE.Type ty "Full type information required";
      DAE.Exp binding "Binding expression e.g. for parameters ; value of start attribute" ;
      DAE.InstDims  dims "dimensions";
      DAE.Flow flowPrefix "Flow of connector variable. Needed for unconnected flow variables" ;
      DAE.Stream streamPrefix "Stream variables in connectors" ;
      Option<DAE.VariableAttributes> variableAttributesOption;
      Option<SCode.Comment> absynCommentOption;
      Absyn.InnerOuter innerOuter "inner/outer required to 'change' outer references";
      DAE.ElementSource source "the origin of the element";

    case({},_,_,_,_) then {};
    case(DAE.VAR(componentRef,kind,direction,protection,ty,SOME(binding),dims,flowPrefix,streamPrefix,source,
                 variableAttributesOption,absynCommentOption,innerOuter) :: cdr,dae,p,inputs,current)
      equation
        ((binding,_)) = Expression.traverseExp(binding,fixCall,(p,inputs,dae,current));
        cdr_1 = fixCalls(cdr,dae,p,inputs,current);
      then
        DAE.VAR(componentRef,kind,direction,protection,ty,SOME(binding),dims,flowPrefix,streamPrefix,source,
                variableAttributesOption,absynCommentOption,innerOuter) :: cdr_1;

    case(DAE.DEFINE(cref,e,source) :: cdr,dae,p,inputs,current)
      equation
        ((e_1,_)) = Expression.traverseExp(e,fixCall,(p,inputs,dae,current));
        cdr_1 = fixCalls(cdr,dae,p,inputs,current);
      then
        DAE.DEFINE(cref,e_1,source) :: cdr_1;

    case(DAE.INITIALDEFINE(cref,e,source) :: cdr,dae,p,inputs,current)
      equation
        ((e_1,_)) = Expression.traverseExp(e,fixCall,(p,inputs,dae,current));
        cdr_1 = fixCalls(cdr,dae,p,inputs,current);
      then
        DAE.INITIALDEFINE(cref,e_1,source) :: cdr_1;

    case(DAE.EQUATION(e1,e2,source) :: cdr,dae,p,inputs,current)
      equation
        ((e1_1,_)) = Expression.traverseExp(e1,fixCall,(p,inputs,dae,current));
        ((e2_1,_)) = Expression.traverseExp(e2,fixCall,(p,inputs,dae,current));
        cdr_1 = fixCalls(cdr,dae,p,inputs,current);
      then
        DAE.EQUATION(e1_1,e2_1,source) :: cdr_1;

    case(DAE.ARRAY_EQUATION(ilst,e1,e2,source) :: cdr,dae,p,inputs,current)
      equation
        ((e1_1,_)) = Expression.traverseExp(e1,fixCall,(p,inputs,dae,current));
        ((e2_1,_)) = Expression.traverseExp(e2,fixCall,(p,inputs,dae,current));
        cdr_1 = fixCalls(cdr,dae,p,inputs,current);
      then
        DAE.ARRAY_EQUATION(ilst,e1_1,e2_1,source) :: cdr_1;

    case(DAE.INITIAL_ARRAY_EQUATION(ilst,e1,e2,source) :: cdr,dae,p,inputs,current)
      equation
        ((e1_1,_)) = Expression.traverseExp(e1,fixCall,(p,inputs,dae,current));
        ((e2_1,_)) = Expression.traverseExp(e2,fixCall,(p,inputs,dae,current));
        cdr_1 = fixCalls(cdr,dae,p,inputs,current);
      then
        DAE.INITIAL_ARRAY_EQUATION(ilst,e1_1,e2_1,source) :: cdr_1;

    case(DAE.COMPLEX_EQUATION(e1,e2,source) :: cdr,dae,p,inputs,current)
      equation
        ((e1_1,_)) = Expression.traverseExp(e1,fixCall,(p,inputs,dae,current));
        ((e2_1,_)) = Expression.traverseExp(e2,fixCall,(p,inputs,dae,current));
        cdr_1 = fixCalls(cdr,dae,p,inputs,current);
      then
        DAE.COMPLEX_EQUATION(e1_1,e2_1,source) :: cdr_1;

    case(DAE.INITIAL_COMPLEX_EQUATION(e1,e2,source) :: cdr,dae,p,inputs,current)
      equation
        ((e1_1,_)) = Expression.traverseExp(e1,fixCall,(p,inputs,dae,current));
        ((e2_1,_)) = Expression.traverseExp(e2,fixCall,(p,inputs,dae,current));
        cdr_1 = fixCalls(cdr,dae,p,inputs,current);
      then
        DAE.INITIAL_COMPLEX_EQUATION(e1_1,e2_1,source) :: cdr_1;

    case(DAE.INITIALEQUATION(e1,e2,source) :: cdr,dae,p,inputs,current)
      equation
        ((e1_1,_)) = Expression.traverseExp(e1,fixCall,(p,inputs,dae,current));
        ((e2_1,_)) = Expression.traverseExp(e2,fixCall,(p,inputs,dae,current));
        cdr_1 = fixCalls(cdr,dae,p,inputs,current);
      then
        DAE.INITIALEQUATION(e1_1,e2_1,source) :: cdr_1;

    case(DAE.ALGORITHM(DAE.ALGORITHM_STMTS(alg),source) :: cdr,dae,p,inputs,current)
      equation
        alg_1 = fixCallsAlg(alg,dae,p,inputs,current);
        cdr_1 = fixCalls(cdr,dae,p,inputs,current);
      then
        DAE.ALGORITHM(DAE.ALGORITHM_STMTS(alg_1),source) :: cdr_1;

    case(DAE.INITIALALGORITHM(DAE.ALGORITHM_STMTS(alg),source) :: cdr,dae,p,inputs,current)
      equation
        alg_1 = fixCallsAlg(alg,dae,p,inputs,current);
        cdr_1 = fixCalls(cdr,dae,p,inputs,current);
      then
        DAE.INITIALALGORITHM(DAE.ALGORITHM_STMTS(alg_1),source) :: cdr_1;

    case(part :: cdr,dae,p,inputs,current)
      equation
        cdr_1 = fixCalls(cdr,dae,p,inputs,current);
      then
        part :: cdr_1;

    case(_,_,_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"PartFn.fixCalls failed");
      then
        fail();
  end matchcontinue;
end fixCalls;

protected function fixCallsAlg
"function: fixCallsAlg
  fixes calls in algorithm sections of the new function"
  input list<DAE.Statement> inStmts;
  input list<DAE.Function> inDAE;
  input Absyn.Path inPath;
  input list<DAE.Element> inInputs;
  input Absyn.Path inCurrent;
  output list<DAE.Statement> outStmts;
algorithm
  outStmts := matchcontinue(inStmts,inDAE,inPath,inInputs,inCurrent)
    local
      list<DAE.Statement> cdr,cdr_1,stmts,stmts_1;
      list<DAE.Function> dae;
      list<DAE.Element> inputs;
      Absyn.Path p,current;
      DAE.Type ty;
      DAE.ComponentRef cref;
      DAE.Else el,el_1;
      Ident i;
      Boolean b;
      DAE.Statement stmt,stmt_1;
      list<Integer> ilst;
      DAE.Exp e,e_1,e1,e1_1,e2,e2_1;
      list<DAE.Exp> elst,elst_1;
      DAE.ElementSource source;
    case({},_,_,_,_) then {};
    case(DAE.STMT_ASSIGN(ty,e1,e2,source) :: cdr,dae,p,inputs,current)
      equation
        ((e1_1,_)) = Expression.traverseExp(e1,fixCall,(p,inputs,dae,current));
        ((e2_1,_)) = Expression.traverseExp(e2,fixCall,(p,inputs,dae,current));
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs,current);
      then
        DAE.STMT_ASSIGN(ty,e1_1,e2_1,source) :: cdr_1;
    case(DAE.STMT_TUPLE_ASSIGN(ty,elst,e,source) :: cdr,dae,p,inputs,current)
      equation
        elst_1 = List.map1(elst,handleExpList2,(p,inputs,dae,current));
        ((e_1,_)) = Expression.traverseExp(e,fixCall,(p,inputs,dae,current));
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs,current);
      then
        DAE.STMT_TUPLE_ASSIGN(ty,elst_1,e_1,source) :: cdr_1;
    case(DAE.STMT_ASSIGN_ARR(ty,cref,e,source) :: cdr,dae,p,inputs,current)
      equation
        ((e_1,_)) = Expression.traverseExp(e,fixCall,(p,inputs,dae,current));
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs,current);
      then
        DAE.STMT_ASSIGN_ARR(ty,cref,e_1,source) :: cdr_1;
    case(DAE.STMT_IF(e,stmts,el,source) :: cdr,dae,p,inputs,current)
      equation
        ((e_1,_)) = Expression.traverseExp(e,fixCall,(p,inputs,dae,current));
        stmts_1 = fixCallsAlg(stmts,dae,p,inputs,current);
        el_1 = fixCallsElse(el,dae,p,inputs,current);
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs,current);
      then
        DAE.STMT_IF(e_1,stmts_1,el_1,source) :: cdr_1;
    case(DAE.STMT_FOR(ty,b,i,e,stmts,source) :: cdr,dae,p,inputs,current)
      equation
        ((e_1,_)) = Expression.traverseExp(e,fixCall,(p,inputs,dae,current));
        stmts_1 = fixCallsAlg(stmts,dae,p,inputs,current);
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs,current);
      then
        DAE.STMT_FOR(ty,b,i,e_1,stmts_1,source) :: cdr_1;
    case(DAE.STMT_WHILE(e,stmts,source) :: cdr,dae,p,inputs,current)
      equation
        ((e_1,_)) = Expression.traverseExp(e,fixCall,(p,inputs,dae,current));
        stmts_1 = fixCallsAlg(stmts,dae,p,inputs,current);
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs,current);
      then
        DAE.STMT_WHILE(e_1,stmts_1,source) :: cdr_1;
    case(DAE.STMT_WHEN(e,stmts,SOME(stmt),ilst,source) :: cdr,dae,p,inputs,current)
      equation
        ((e_1,_)) = Expression.traverseExp(e,fixCall,(p,inputs,dae,current));
        stmts_1 = fixCallsAlg(stmts,dae,p,inputs,current);
        {stmt,stmt_1} = fixCallsAlg({stmt},dae,p,inputs,current);
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs,current);
      then
        DAE.STMT_WHEN(e_1,stmts_1,SOME(stmt_1),ilst,source) :: cdr_1;
    case(DAE.STMT_WHEN(e,stmts,NONE(),ilst,source) :: cdr,dae,p,inputs,current)
      equation
        ((e_1,_)) = Expression.traverseExp(e,fixCall,(p,inputs,dae,current));
        stmts_1 = fixCallsAlg(stmts,dae,p,inputs,current);
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs,current);
      then
        DAE.STMT_WHEN(e_1,stmts_1,NONE(),ilst,source) :: cdr_1;
    case(DAE.STMT_ASSERT(e1,e2,source) :: cdr,dae,p,inputs,current)
      equation
        ((e1_1,_)) = Expression.traverseExp(e1,fixCall,(p,inputs,dae,current));
        ((e2_1,_)) = Expression.traverseExp(e2,fixCall,(p,inputs,dae,current));
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs,current);
      then
        DAE.STMT_ASSERT(e1_1,e2_1,source) :: cdr_1;
    case(DAE.STMT_TERMINATE(e,source) :: cdr,dae,p,inputs,current)
      equation
        ((e_1,_)) = Expression.traverseExp(e,fixCall,(p,inputs,dae,current));
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs,current);
      then
        DAE.STMT_TERMINATE(e_1,source) :: cdr_1;
    case(DAE.STMT_REINIT(e1,e2,source) :: cdr,dae,p,inputs,current)
      equation
        ((e1_1,_)) = Expression.traverseExp(e1,fixCall,(p,inputs,dae,current));
        ((e2_1,_)) = Expression.traverseExp(e2,fixCall,(p,inputs,dae,current));
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs,current);
      then
        DAE.STMT_REINIT(e1_1,e2_1,source) :: cdr_1;
    case(DAE.STMT_NORETCALL(e,source) :: cdr,dae,p,inputs,current)
      equation
        ((e_1,_)) = Expression.traverseExp(e,fixCall,(p,inputs,dae,current));
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs,current);
      then
        DAE.STMT_NORETCALL(e,source) :: cdr_1;
    case(DAE.STMT_FAILURE(stmts,source) :: cdr,dae,p,inputs,current)
      equation
        stmts_1 = fixCallsAlg(stmts,dae,p,inputs,current);
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs,current);
      then
        DAE.STMT_FAILURE(stmts_1,source) :: cdr_1;
    case(DAE.STMT_TRY(stmts,source) :: cdr,dae,p,inputs,current)
      equation
        stmts_1 = fixCallsAlg(stmts,dae,p,inputs,current);
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs,current);
      then
        DAE.STMT_TRY(stmts_1,source) :: cdr_1;
    case(DAE.STMT_CATCH(stmts,source) :: cdr,dae,p,inputs,current)
      equation
        stmts_1 = fixCallsAlg(stmts,dae,p,inputs,current);
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs,current);
      then
        DAE.STMT_CATCH(stmts_1,source) :: cdr_1;
    case(stmt :: cdr,dae,p,inputs,current)
      equation
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs,current);
      then
        stmt :: cdr_1;
    case(_,_,_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"PartFn.fixCallsAlg failed");
      then
        fail();
  end matchcontinue;
end fixCallsAlg;

protected function fixCallsElse
"function: fixCallsElse
  fixes calls in an DAE.Else"
  input DAE.Else inElse;
  input list<DAE.Function> inDAE;
  input Absyn.Path inPath;
  input list<DAE.Element> inInputs;
  input Absyn.Path inCurrent;
  output DAE.Else outElse;
algorithm
  outElse := matchcontinue(inElse,inDAE,inPath,inInputs,inCurrent)
    local
      DAE.Exp e,e_1;
      list<DAE.Statement> stmts,stmts_1;
      DAE.Else el,el_1;
      list<DAE.Function> dae;
      list<DAE.Element> inputs;
      Absyn.Path p,current;
    case(DAE.ELSEIF(e,stmts,el),dae,p,inputs,current)
      equation
        ((e_1,_)) = Expression.traverseExp(e,fixCall,(p,inputs,dae,current));
        stmts_1 = fixCallsAlg(stmts,dae,p,inputs,current);
        el_1 = fixCallsElse(el,dae,p,inputs,current);
      then
        DAE.ELSEIF(e_1,stmts_1,el_1);
    case(DAE.ELSE(stmts),dae,p,inputs,current)
      equation
        stmts_1 = fixCallsAlg(stmts,dae,p,inputs,current);
      then
        DAE.ELSE(stmts_1);
    case(el,_,_,_,_) then el;
  end matchcontinue;
end fixCallsElse;

protected function handleExpList2
"function: handleExpList2
  helper function to fixCallsAlg"
  input DAE.Exp inExp;
  input tuple<Absyn.Path, list<DAE.Element>, list<DAE.Function>, Absyn.Path> inTuple;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExp,inTuple)
    local
      DAE.Exp e,e_1;
      tuple<Absyn.Path, list<DAE.Element>, list<DAE.Function>, Absyn.Path> tup;
    case(e,tup)
      equation
        ((e_1,_)) = Expression.traverseExp(e,fixCall,tup);
      then
        e_1;
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"PartFn.handleExpList2 failed");
      then
        fail();
  end matchcontinue;
end handleExpList2;

protected function fixCall
"function: fixCall
  replaces the path and args in a function call"
  input tuple<DAE.Exp, tuple<Absyn.Path, list<DAE.Element>, list<DAE.Function>, Absyn.Path>> inTuple;
  output tuple<DAE.Exp, tuple<Absyn.Path, list<DAE.Element>, list<DAE.Function>, Absyn.Path>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e;
      Absyn.Path p,orig_p,new_p,current;
      list<DAE.Function> dae;
      list<DAE.Element> inputs;
      DAE.Type ty,ty_1;
      Boolean tup,bui;
      DAE.InlineType inl;
      list<DAE.Exp> args,args2,args_1;
      list<DAE.ComponentRef> crefs;
      DAE.CallAttributes attr;
      DAE.TailCall tc;
    // remove unbox calls from simple types
    case((DAE.UNBOX(exp = e as DAE.CALL(path=orig_p)),(p,inputs,dae,current)))
      equation
        true = Absyn.pathEqual(p,orig_p);
      then
        ((e,(p,inputs,dae,current)));
    // fix recursive calls
    case((DAE.CALL(orig_p,args,attr),(p,inputs,dae,current)))
      equation
        true = Absyn.pathEqual(orig_p,current);
        new_p = makeNewFnPath(orig_p,p);
        crefs = List.map(inputs,DAEUtil.varCref);
        args2 = List.map(crefs,Expression.crefExp);
        args_1 = replaceFnRef(args,args2);
      then
        ((DAE.CALL(new_p,args_1,attr),(p,inputs,dae,current)));
    // fix calls to function pointer
    case((DAE.CALL(orig_p,args,DAE.CALL_ATTR(ty,tup,false,inl,tc)),(p,inputs,dae,current)))
      equation
        failure(_ = DAEUtil.getNamedFunctionFromList(orig_p,dae)); // if function exists, do not replace call
        crefs = List.map(inputs,DAEUtil.varCref);
        args2 = List.map(crefs,Expression.crefExp);
        args = List.map(args,Expression.unboxExp); // Unbox args here
        args_1 = listAppend(args,args2);
        ty_1 = Expression.unboxExpType(ty);
      then
        ((DAE.CALL(p,args_1,DAE.CALL_ATTR(ty_1,tup,false,inl,tc)),(p,inputs,dae,current)));
    case((e,(p,inputs,dae,current))) then ((e,(p,inputs,dae,current)));
  end matchcontinue;
end fixCall;

protected function replaceFnRef
"function: replaceFnRef
  takes 2 arg lists, replaces the function ref in the first one wtih the exps in the second one"
  input list<DAE.Exp> inOriginalArgs;
  input list<DAE.Exp> inNewArgs;
  output list<DAE.Exp> outNewArgs;
algorithm
  outNewArgs := matchcontinue(inOriginalArgs,inNewArgs)
    local
      list<DAE.Exp> newArgs,cdr,cdr_1;
      DAE.Exp e;
    
    case({},_) then fail();
    
    case(DAE.CREF(ty = DAE.T_FUNCTION_REFERENCE_VAR(source = _)) :: cdr,newArgs) 
      then 
        listAppend(newArgs,cdr);
    
    case(DAE.CREF(ty = DAE.T_FUNCTION_REFERENCE_FUNC(builtin = _)) :: cdr,newArgs) 
      then 
        listAppend(newArgs,cdr);
    
    case(e :: cdr,newArgs)
      equation
        cdr_1 = replaceFnRef(cdr,newArgs);
      then
        e :: cdr_1;
  end matchcontinue;
end replaceFnRef;

protected function isSimpleArg
"function: isSimpleArg
  checks if a funcarg list is simple or not"
  input list<DAE.Exp> inArgs;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue(inArgs)
    local
      DAE.Type et;
    case({DAE.ICONST(_)}) then true;
    case({DAE.RCONST(_)}) then true;
    case({DAE.BCONST(_)}) then true;
    case({DAE.SCONST(_)}) then true;
    case({DAE.CREF(ty = et)})
      equation
        true = Expression.typeBuiltin(et);
      then
        true;
    case({DAE.CALL(attr=DAE.CALL_ATTR(ty = DAE.T_METABOXED(ty = et)))})
      equation
        true = Expression.typeBuiltin(et);
      then
        true;
    case({DAE.CALL(attr=DAE.CALL_ATTR(ty = et))})
      equation
        true = Expression.typeBuiltin(et);
      then
        true;
    else false;
  end matchcontinue;
end isSimpleArg;

protected function getPartEvalFunction
"function: getPartEvalFunction
  gets the exp and index of a partevalfunction from a list of exps
  fail if no partevalfunction is present"
  input list<DAE.Exp> inExpList;
  input Integer inInteger "accumulator";
  output DAE.Exp outExp;
  output Integer outInteger;
algorithm
  (outExp,outInteger) := matchcontinue(inExpList,inInteger)
    local
      list<DAE.Exp> cdr;
      Integer index,index_1;
      DAE.Exp e;
    case({},_) then fail();
    case((e as DAE.PARTEVALFUNCTION(path=_)) :: _,index) then (e,index);
    case(_ :: cdr,index)
      equation
        (e,index_1) = getPartEvalFunction(cdr,index+1);
      then
        (e,index_1);
  end matchcontinue;
end getPartEvalFunction;

end PartFn;

