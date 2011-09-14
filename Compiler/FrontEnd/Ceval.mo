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

encapsulated package Ceval
" file:        Ceval.mo
  package:     Ceval
  description: Constant propagation of expressions

  RCS: $Id$

  This module handles constant propagation (or evaluation)
  When elaborating expressions, in the Static module, expressions are checked to
  find out its type. It also checks whether the expressions are constant and the function
  ceval in this module will then evaluate the expression to a constant value, defined
  in the Values module.

  Input:
    Env: Environment with bindings
    Exp: Expression to check for constant evaluation
    Bool flag determines whether the current instantiation is implicit
    InteractiveSymbolTable is optional, and used in interactive mode, e.g. from OMShell

  Output:
    Value: The evaluated value
    InteractiveSymbolTable: Modified symbol table
    Subscript list : Evaluates subscripts and generates constant expressions."

public import Absyn;
public import AbsynDep;
public import DAE;
public import Env;
public import Interactive;
public import Values;
public import Lookup;

public
uniontype Msg
  record MSG "Give error message" 
    Absyn.Info info;
  end MSG;

  record NO_MSG "Do not give error message" end NO_MSG;
end Msg;

// protected imports
protected import CevalFunction;
protected import CevalScript;
protected import ClassInf;
protected import ComponentReference;
protected import Debug;
protected import Derive;
protected import Dump;
protected import DynLoad;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import InnerOuter;
protected import Inst;
protected import Mod;
protected import ModUtil;
protected import OptManager;
protected import Prefix;
protected import Print;
protected import RTOpts;
protected import SCode;
protected import Static;
protected import System;
protected import Types;
protected import Util;
protected import ValuesUtil;

public function ceval "
  This function is used when the value of a constant expression is
  needed.  It takes an environment and an expression and calculates
  its value.

  The third argument indicates whether the evaluation is performed in the
  interactive environment (implicit instantiation), in which case function
  calls are evaluated.

  The last argument is an optional dimension."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp inExp;
  input Boolean inBoolean "impl";
  input Option<Interactive.SymbolTable> inST;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outST;

  partial function ReductionOperator
    input Values.Value v1;
    input Values.Value v2;
    output Values.Value res;
  end ReductionOperator;
algorithm
  (outCache,outValue,outST):=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inST,inMsg)
    local
      Integer dim,start_1,stop_1,step_1,i,indx_1,indx,index;
      Option<Integer> dimOpt;
      Option<Interactive.SymbolTable> stOpt;
      Real lhvReal,rhvReal,sum,r,realStart1,realStop1,realStep1;
      String str,lhvStr,rhvStr,iter,s;
      Boolean impl,builtin,b,b_1,lhvBool,rhvBool,resBool, bstart, bstop;
      Absyn.Exp exp_1,exp;
      list<Env.Frame> env;
      Msg msg;
      Absyn.Element elt_1,elt;
      Absyn.CodeNode c;
      list<Values.Value> es_1,elts,vallst,vlst1,vlst2,reslst,aval,rhvals,lhvals,arr,arr_1,ivals,rvals,vallst_1,vals;
      list<DAE.Exp> es,expl;
      list<list<DAE.Exp>> expll;
      Values.Value v,newval,value,sval,elt1,elt2,v_1,lhs_1,rhs_1,resVal,lhvVal,rhvVal,startValue;
      DAE.Exp lh,rh,e,lhs,rhs,start,stop,step,e1,e2,iterexp,cond;
      Absyn.Path funcpath,name;
      DAE.Operator relop;
      Env.Cache cache;
      DAE.Exp expExp;
      list<Integer> dims;
      list<DAE.Dimension> arrayDims;
      DAE.ComponentRef cr;
      list<String> fieldNames, n, names;
      DAE.ExpType ety;
      Interactive.SymbolTable st;
      DAE.Ident reductionName;
      DAE.Exp daeExp;
      ReductionOperator op;
      Absyn.Path path;
      Option<Values.Value> ov;
      Option<DAE.Exp> guardExp;
      Option<DAE.Exp> foldExp;
      DAE.Type ty;
      list<DAE.Type> tys;
      DAE.ReductionIterators iterators;
      list<list<Values.Value>> valMatrix;
      Absyn.Info info;

    // uncomment for debugging 
    // case (cache,env,inExp,_,st,_,_) 
    //   equation print("Ceval.ceval: " +& ExpressionDump.printExpStr(inExp) +& " in env: " +& Env.printEnvPathStr(env) +& "\n");
    //   then fail();

    case (cache,_,DAE.ICONST(integer = i),_,stOpt,_) then (cache,Values.INTEGER(i),stOpt);

    case (cache,_,DAE.RCONST(real = r),_,stOpt,_) then (cache,Values.REAL(r),stOpt);

    case (cache,_,DAE.SCONST(string = s),_,stOpt,_) then (cache,Values.STRING(s),stOpt);

    case (cache,_,DAE.BCONST(bool = b),_,stOpt,_) then (cache,Values.BOOL(b),stOpt);

    case (cache,_,DAE.ENUM_LITERAL(name = name, index = i),_,stOpt,_)
      then (cache, Values.ENUM_LITERAL(name, i), stOpt);

    case (cache,env,DAE.CODE(code = Absyn.C_EXPRESSION(exp = exp)),impl,stOpt,msg)
      equation
        (cache,exp_1) = CevalScript.cevalAstExp(cache,env, exp, impl, stOpt, msg, Absyn.dummyInfo);
      then
        (cache,Values.CODE(Absyn.C_EXPRESSION(exp_1)),stOpt);
    
    case (cache,env,DAE.CODE(code = Absyn.C_EXPRESSION(exp = exp)),impl,stOpt,msg)
      equation
        (cache,exp_1) = CevalScript.cevalAstExp(cache,env, exp, impl, stOpt, msg, Absyn.dummyInfo);
      then
        (cache,Values.CODE(Absyn.C_EXPRESSION(exp_1)),stOpt);
    
    case (cache,env,DAE.CODE(code = Absyn.C_ELEMENT(element = elt)),impl,stOpt,msg)
      equation
        (cache,elt_1) = CevalScript.cevalAstElt(cache,env, elt, impl, stOpt, msg);
      then
        (cache,Values.CODE(Absyn.C_ELEMENT(elt_1)),stOpt);
    
    case (cache,env,DAE.CODE(code = c),_,stOpt,_) then (cache,Values.CODE(c),stOpt);
    
    case (cache,env,DAE.ARRAY(array = es, ty = DAE.ET_ARRAY(arrayDimensions = arrayDims)),impl,stOpt,msg)
      equation
        dims = Util.listMap(arrayDims, Expression.dimensionSize);
        (cache,es_1, stOpt) = cevalList(cache,env, es, impl, stOpt, msg);
      then
        (cache,Values.ARRAY(es_1,dims),stOpt);

    case (cache,env,DAE.MATRIX(matrix = expll, ty = DAE.ET_ARRAY(arrayDimensions = arrayDims)),impl,stOpt,msg)
      equation
        dims = Util.listMap(arrayDims, Expression.dimensionSize);
        (cache,elts) = cevalMatrixElt(cache, env, expll, impl, msg);
      then
        (cache,Values.ARRAY(elts,dims),stOpt);

    // MetaModelica List. sjoelund 
    case (cache,env,DAE.LIST(valList = expl),impl,stOpt,msg)
      equation
        (cache,es_1,stOpt) = cevalList(cache,env, expl, impl, stOpt, msg);
      then
        (cache,Values.LIST(es_1),stOpt);

    case (cache,env,DAE.BOX(exp=e1),impl,stOpt,msg)
      equation
        (cache,v,stOpt) = ceval(cache,env,e1,impl,stOpt,msg);
      then
        (cache,v,stOpt);

    case (cache,env,DAE.UNBOX(exp=e1),impl,stOpt,msg)
      equation
        (cache,Values.META_BOX(v),stOpt) = ceval(cache,env,e1,impl,stOpt,msg);
      then
        (cache,v,stOpt);

    case (cache,env,DAE.CONS(car=e1,cdr=e2),impl,stOpt,msg)
      equation
        (cache,v,stOpt) = ceval(cache,env,e1,impl,stOpt,msg);
        (cache,Values.LIST(vallst),stOpt) = ceval(cache,env,e2,impl,stOpt,msg);
      then
        (cache,Values.LIST(v::vallst),stOpt);

    // MetaModelica Partial Function. sjoelund 
    case (cache,env,DAE.CREF(componentRef = cr, 
        ty = DAE.ET_FUNCTION_REFERENCE_VAR()),impl,stOpt,MSG(info = info))
      equation
        str = ComponentReference.crefStr(cr);
        Error.addSourceMessage(Error.META_CEVAL_FUNCTION_REFERENCE, {str}, info);
      then
        fail();

    case (cache,env,DAE.CREF(componentRef = cr, ty = DAE.ET_FUNCTION_REFERENCE_FUNC(builtin = _)),
        impl, stOpt, MSG(info = info))
      equation
        str = ComponentReference.crefStr(cr);
        Error.addSourceMessage(Error.META_CEVAL_FUNCTION_REFERENCE, {str}, info);
      then
        fail();

    // MetaModelica Uniontype Constructor. sjoelund 2009-05-18
    case (cache,env,inExp as DAE.METARECORDCALL(path=funcpath,args=expl,fieldNames=fieldNames,index=index),impl,stOpt,msg)
      equation
        (cache,vallst,stOpt) = cevalList(cache,env, expl, impl, stOpt, msg);
      then (cache,Values.RECORD(funcpath,vallst,fieldNames,index),stOpt);

    // MetaModelica Option type. sjoelund 2009-07-01 
    case (cache,env,DAE.META_OPTION(NONE()),impl,stOpt,msg)
      then (cache,Values.OPTION(NONE()),stOpt);
    case (cache,env,DAE.META_OPTION(SOME(inExp)),impl,stOpt,msg)
      equation
        (cache,value,stOpt) = ceval(cache,env,inExp,impl,stOpt,msg);
      then (cache,Values.OPTION(SOME(value)),stOpt);

    // MetaModelica Tuple. sjoelund 2009-07-02 
    case (cache,env,DAE.META_TUPLE(expl),impl,stOpt,msg)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (cache,vallst,stOpt) = cevalList(cache, env, expl, impl, stOpt, msg);
      then (cache,Values.META_TUPLE(vallst),stOpt);

    case (cache,env,DAE.TUPLE(expl),impl,stOpt,msg)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (cache,vallst,stOpt) = cevalList(cache, env, expl, impl, stOpt, msg);
      then (cache,Values.TUPLE(vallst),stOpt);

    case (cache,env,DAE.CREF(componentRef = cr),(impl as false),SOME(st),msg)
      equation
        (cache,v) = cevalCref(cache, env, cr, false, msg) "When in interactive mode, always evaluate crefs, i.e non-implicit mode.." ;
        //Debug.traceln("cevalCref cr: " +& ComponentReference.printComponentRefStr(c) +& " in s: " +& Env.printEnvPathStr(env) +& " v:" +& ValuesUtil.valString(v));
      then
        (cache,v,SOME(st));

    case (cache,env,DAE.CREF(componentRef = cr),impl,stOpt,msg)
      equation
        (cache,v) = cevalCref(cache,env, cr, impl, msg);
        //Debug.traceln("cevalCref cr: " +& ComponentReference.printComponentRefStr(c) +& " in s: " +& Env.printEnvPathStr(env) +& " v:" +& ValuesUtil.valString(v));
      then
        (cache,v,stOpt);
        
    // Evaluates for build in types. ADD, SUB, MUL, DIV for Reals and Integers.
    case (cache,env,expExp,impl,stOpt,msg)
      equation
        (cache,v,stOpt) = cevalBuiltin(cache,env, expExp, impl, stOpt, msg);
      then
        (cache,v,stOpt);

    // adrpo: TODO! this needs more work as if we don't have a symtab we run into unloading of dlls problem 
    case (cache,env,(e as DAE.CALL(path = funcpath,expLst = expl)),impl,stOpt,msg)
      equation
        // do not handle Connection.isRoot here!        
        false = stringEq("Connection.isRoot", Absyn.pathString(funcpath));
        // do not roll back errors generated by evaluating the arguments
        (cache,vallst,stOpt) = cevalList(cache,env, expl, impl, stOpt, msg);
        
        (cache,newval,stOpt)= cevalCallFunction(cache, env, e, vallst, impl, stOpt, msg);
      then
        (cache,newval,stOpt);

    // Try Interactive functions last
    case (cache,env,(e as DAE.CALL(path = _)),(impl as true),SOME(st),msg)
      equation
        (cache,value,st) = CevalScript.cevalInteractiveFunctions(cache, env, e, st, msg);
      then
        (cache,value,SOME(st));

    case (_,_,e as DAE.CALL(path = _),_,_,_)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "- Ceval.ceval DAE.CALL failed: ");
        str = ExpressionDump.printExpStr(e);
        Debug.fprintln("failtrace", str);
      then
        fail();

    // Strings 
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.ADD(ty = DAE.ET_STRING()),exp2 = rh),impl,stOpt,msg) 
      equation
        (cache,Values.STRING(lhvStr),_) = ceval(cache,env, lh, impl, stOpt, msg);
        (cache,Values.STRING(rhvStr),_) = ceval(cache,env, rh, impl, stOpt, msg);
        str = stringAppend(lhvStr, rhvStr);
      then
        (cache,Values.STRING(str),stOpt);

    // Numerical
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.ADD(ty = DAE.ET_REAL()),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,Values.REAL(lhvReal),stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        (cache,Values.REAL(rhvReal),stOpt) = ceval(cache,env, rh, impl, stOpt, msg);
        sum = lhvReal +. rhvReal;
      then
        (cache,Values.REAL(sum),stOpt);

    // Array addition
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.ADD_ARR(ty = _),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,Values.ARRAY(vlst1,dims),stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        (cache,Values.ARRAY(vlst2,_),stOpt) = ceval(cache,env, rh, impl, stOpt, msg);
        reslst = ValuesUtil.addElementwiseArrayelt(vlst1, vlst2);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    // Array subtraction
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.SUB_ARR(ty = _),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,Values.ARRAY(vlst1,dims),stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        (cache,Values.ARRAY(vlst2,_),stOpt) = ceval(cache,env, rh, impl, stOpt, msg);
        reslst = ValuesUtil.subElementwiseArrayelt(vlst1, vlst2);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    // Array multiplication
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL_ARR(ty = _),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,Values.ARRAY(vlst1,dims),stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        (cache,Values.ARRAY(vlst2,_),stOpt) = ceval(cache,env, rh, impl, stOpt, msg);
        reslst = ValuesUtil.mulElementwiseArrayelt(vlst1, vlst2);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    // Array division
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.DIV_ARR(ty = _),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,Values.ARRAY(vlst1,dims),stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        (cache,Values.ARRAY(vlst2,_),stOpt) = ceval(cache,env, rh, impl, stOpt, msg);
        reslst = ValuesUtil.divElementwiseArrayelt(vlst1, vlst2);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    // Array power
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.POW_ARR2(ty = _),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,Values.ARRAY(vlst1,dims),stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        (cache,Values.ARRAY(vlst2,_),stOpt) = ceval(cache,env, rh, impl, stOpt, msg);
        reslst = ValuesUtil.powElementwiseArrayelt(vlst1, vlst2);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    // Array multipled scalar
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL_SCALAR_ARRAY(ty = _),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,sval,stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        (cache,Values.ARRAY(aval,dims),stOpt) = ceval(cache,env, rh, impl, stOpt, msg);
        reslst = ValuesUtil.multScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL_ARRAY_SCALAR(ty = _),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,sval,stOpt) = ceval(cache,env, rh, impl, stOpt, msg);
        (cache,Values.ARRAY(aval,dims),stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        reslst = ValuesUtil.multScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    // Array add scalar
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.ADD_SCALAR_ARRAY(ty = _),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,sval,stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        (cache,Values.ARRAY(aval,dims),stOpt) = ceval(cache,env, rh, impl, stOpt, msg);
        reslst = ValuesUtil.addScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.ADD_ARRAY_SCALAR(ty = _),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,sval,stOpt) = ceval(cache,env, rh, impl, stOpt, msg);
        (cache,Values.ARRAY(aval,dims),stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        reslst = ValuesUtil.addScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    // Array subtract scalar
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.SUB_SCALAR_ARRAY(ty = _),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,sval,stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        (cache,Values.ARRAY(aval,dims),stOpt) = ceval(cache,env, rh, impl, stOpt, msg);
        reslst = ValuesUtil.subScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.SUB_ARRAY_SCALAR(ty = _),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,sval,stOpt) = ceval(cache,env, rh, impl, stOpt, msg);
        (cache,Values.ARRAY(aval,dims),stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        reslst = ValuesUtil.subArrayeltScalar(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    // Array power scalar
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.POW_SCALAR_ARRAY(ty = _),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,sval,stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        (cache,Values.ARRAY(aval,dims),stOpt) = ceval(cache,env, rh, impl, stOpt, msg);
        reslst = ValuesUtil.powScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    // Array power scalar
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.POW_ARRAY_SCALAR(ty = _),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,sval,stOpt) = ceval(cache,env, rh, impl, stOpt, msg);
        (cache,Values.ARRAY(aval,dims),stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        reslst = ValuesUtil.powArrayeltScalar(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    // scalar div array
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.DIV_SCALAR_ARRAY(ty = _),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,sval,stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        (cache,Values.ARRAY(aval,dims),stOpt) = ceval(cache,env, rh, impl, stOpt, msg);
        reslst = ValuesUtil.divScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    // array div scalar
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.DIV_ARRAY_SCALAR(ty = _),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,sval,stOpt) = ceval(cache,env, rh, impl, stOpt, msg);
        (cache,Values.ARRAY(aval,dims),stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        reslst = ValuesUtil.divArrayeltScalar(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    // scalar multiplied array
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL_SCALAR_PRODUCT(ty = _),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,Values.ARRAY(valueLst = rhvals),stOpt) = ceval(cache,env, rh, impl, stOpt, msg);
        (cache,Values.ARRAY(valueLst = lhvals),stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        resVal = ValuesUtil.multScalarProduct(rhvals, lhvals);
      then
        (cache,resVal,stOpt);

    // array multipled array
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL_MATRIX_PRODUCT(ty = _),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,Values.ARRAY(valueLst = (lhvals as (elt1 :: _))),stOpt) = ceval(cache,env, lh, impl, stOpt, msg) "{{..}..{..}}  {...}" ;
        (cache,Values.ARRAY(valueLst = (rhvals as (elt2 :: _))),stOpt) = ceval(cache,env, rh, impl, stOpt, msg);
        true = ValuesUtil.isArray(elt1);
        false = ValuesUtil.isArray(elt2);
        resVal = ValuesUtil.multScalarProduct(lhvals, rhvals);
      then
        (cache,resVal,stOpt);

    // array multiplied array 
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL_MATRIX_PRODUCT(ty = _),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,Values.ARRAY(valueLst = (rhvals as (elt1 :: _))),stOpt) = ceval(cache,env, rh, impl, stOpt, msg) "{...}  {{..}..{..}}" ;
        (cache,Values.ARRAY(valueLst = (lhvals as (elt2 :: _))),stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        true = ValuesUtil.isArray(elt1);
        false = ValuesUtil.isArray(elt2);
        resVal = ValuesUtil.multScalarProduct(lhvals, rhvals);
      then
        (cache,resVal,stOpt);

    // array multiplied array
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL_MATRIX_PRODUCT(ty = _),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,Values.ARRAY((rhvals as (elt1 :: _)),dims),stOpt) = ceval(cache,env, rh, impl, stOpt, msg) "{{..}..{..}}  {{..}..{..}}" ;
        (cache,Values.ARRAY((lhvals as (elt2 :: _)),_),stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        true = ValuesUtil.isArray(elt1);
        true = ValuesUtil.isArray(elt2);
        vallst = ValuesUtil.multMatrix(lhvals, rhvals);
      then
        (cache,ValuesUtil.makeArray(vallst),stOpt);

    //POW (integer or real)
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.POW(ty=_),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,lhvVal,stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        (cache,rhvVal,stOpt) = ceval(cache,env, rh, impl, stOpt, msg);
        resVal = ValuesUtil.safeIntRealOp(lhvVal, rhvVal, Values.POWOP());
      then
        (cache,resVal,stOpt);

    //MUL (integer or real)
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL(ty=_),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,lhvVal,stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        (cache,rhvVal,stOpt) = ceval(cache,env, rh, impl, stOpt, msg);
        resVal = ValuesUtil.safeIntRealOp(lhvVal, rhvVal, Values.MULOP());
      then
        (cache,resVal,stOpt);

    //DIV (integer or real)
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.DIV(ty=_),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,lhvVal,stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        (cache,rhvVal,stOpt) = ceval(cache,env, rh, impl, stOpt, msg);
        resVal = ValuesUtil.safeIntRealOp(lhvVal, rhvVal, Values.DIVOP());
      then
        (cache,resVal,stOpt);

    //DIV (handle div by zero)
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.DIV(ty =_),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,lhvVal,stOpt) = ceval(cache,env, rh, impl, stOpt, msg);
        true = ValuesUtil.isZero(lhvVal);
        lhvStr = ExpressionDump.printExpStr(lh);
        rhvStr = ExpressionDump.printExpStr(rh);
        Error.addMessage(Error.DIVISION_BY_ZERO, {lhvStr,rhvStr});
      then
        fail();

    //ADD (integer or real)
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.ADD(ty=_),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,lhvVal,stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        (cache,rhvVal,stOpt) = ceval(cache,env, rh, impl, stOpt, msg);
        resVal = ValuesUtil.safeIntRealOp(lhvVal, rhvVal, Values.ADDOP());
      then
        (cache,resVal,stOpt);

    //SUB (integer or real)
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.SUB(ty=_),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,lhvVal,stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        (cache,rhvVal,stOpt) = ceval(cache,env, rh, impl, stOpt, msg);
        resVal = ValuesUtil.safeIntRealOp(lhvVal, rhvVal, Values.SUBOP());
      then
        (cache,resVal,stOpt);

    //  unary minus of array 
    case (cache,env,DAE.UNARY(operator = DAE.UMINUS_ARR(ty = _),exp = daeExp),impl,stOpt,msg)
      equation
        (cache,Values.ARRAY(arr,dims),stOpt) = ceval(cache,env, daeExp, impl, stOpt, msg);
        arr_1 = Util.listMap(arr, ValuesUtil.valueNeg);
      then
        (cache,Values.ARRAY(arr_1,dims),stOpt);

    // unary minus of expression
    case (cache,env,DAE.UNARY(operator = DAE.UMINUS(ty = _),exp = daeExp),impl,stOpt,msg)
      equation
        (cache,v,stOpt) = ceval(cache,env, daeExp, impl, stOpt, msg);
        v_1 = ValuesUtil.valueNeg(v);
      then
        (cache,v_1,stOpt);

    // unary plus of expression
    case (cache,env,DAE.UNARY(operator = DAE.UPLUS(ty = _),exp = daeExp),impl,stOpt,msg)
      equation
        (cache,v,stOpt) = ceval(cache,env, daeExp, impl, stOpt, msg);
      then
        (cache,v,stOpt);

    // Logical operations false AND rhs
    // special case when leftside is false...
    // We allow errors on right hand side. and even if there is no errors, the performance
    // will be better.
    case (cache,env,DAE.LBINARY(exp1 = lh,operator = DAE.AND(_),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,Values.BOOL(false),stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
      then
        (cache,Values.BOOL(false),stOpt);

    // Logical lhs AND rhs
    case (cache,env,DAE.LBINARY(exp1 = lh,operator = DAE.AND(_),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,Values.BOOL(lhvBool),stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        (cache,Values.BOOL(rhvBool),stOpt) = ceval(cache,env, rh, impl, stOpt, msg);
        resBool = boolAnd(rhvBool, rhvBool);
      then
        (cache,Values.BOOL(resBool),stOpt);

    // true OR rhs 
    case (cache,env,DAE.LBINARY(exp1 = lh,operator = DAE.OR(_),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,Values.BOOL(true),stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
      then
        (cache,Values.BOOL(true),stOpt);

    // lhs OR rhs 
    case (cache,env,DAE.LBINARY(exp1 = lh,operator = DAE.OR(_),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,Values.BOOL(lhvBool),stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        (cache,Values.BOOL(rhvBool),stOpt) = ceval(cache,env, rh, impl, stOpt, msg);
        resBool = boolOr(lhvBool, rhvBool);
      then
        (cache,Values.BOOL(resBool),stOpt);

    // Special case for a boolean expression like if( expression or ARRAY_IDEX_OUT_OF_BOUNDS_ERROR)
    // "expression" in this case we return the lh expression to be equall to
    // the previous c-code generation.
    case (cache,env,DAE.LBINARY(exp1 = lh,operator = DAE.OR(_),exp2 = rh),impl,stOpt,msg)
      equation
        (cache,v as Values.BOOL(rhvBool),stOpt) = ceval(cache,env, lh, impl, stOpt, msg);
        failure((_,_,_) = ceval(cache,env, rh, impl, stOpt, msg));
      then
        (cache,v,stOpt);
    
    // NOT
    case (cache,env,DAE.LUNARY(operator = DAE.NOT(_),exp = e),impl,stOpt,msg)
      equation
        (cache,Values.BOOL(b),stOpt) = ceval(cache,env, e, impl, stOpt, msg);
        b_1 = boolNot(b);
      then
        (cache,Values.BOOL(b_1),stOpt);
    
    // relations <, >, <=, >=, <> 
    case (cache,env,DAE.RELATION(exp1 = lhs,operator = relop,exp2 = rhs),impl,stOpt,msg)
      equation
        (cache,lhs_1,stOpt) = ceval(cache,env, lhs, impl, stOpt, msg);
        (cache,rhs_1,stOpt) = ceval(cache,env, rhs, impl, stOpt, msg);
        v = cevalRelation(lhs_1, relop, rhs_1);
      then
        (cache,v,stOpt);
    
    case (cache, env, DAE.RANGE(ty = DAE.ET_INT(), exp = start, expOption = NONE(), 
      range = stop), impl, stOpt, msg)
      equation
        (cache, Values.BOOL(bstart), stOpt) = ceval(cache, env, start, impl, stOpt, msg);
        (cache, Values.BOOL(bstop), stOpt) = ceval(cache, env, stop, impl, stOpt, msg);
        arr = Util.listMap(ExpressionSimplify.simplifyRangeBool(bstart, bstop),
          ValuesUtil.makeBoolean);
      then
        (cache, ValuesUtil.makeArray(arr), stOpt);

    // range first:last for integers
    case (cache,env,DAE.RANGE(ty = DAE.ET_INT(),exp = start,expOption = NONE(),range = stop),impl,stOpt,msg) 
      equation
        (cache,Values.INTEGER(start_1),stOpt) = ceval(cache,env, start, impl, stOpt, msg);
        (cache,Values.INTEGER(stop_1),stOpt) = ceval(cache,env, stop, impl, stOpt, msg);
        arr = Util.listMap(ExpressionSimplify.simplifyRange(start_1, 1, stop_1), ValuesUtil.makeInteger);
      then
        (cache,ValuesUtil.makeArray(arr),stOpt);
    
    // range first:step:last for integers
    case (cache,env,DAE.RANGE(ty = DAE.ET_INT(),exp = start,expOption = SOME(step),range = stop),impl,stOpt,msg)
      equation
        (cache,Values.INTEGER(start_1),stOpt) = ceval(cache,env, start, impl, stOpt, msg);
        (cache,Values.INTEGER(step_1),stOpt) = ceval(cache,env, step, impl, stOpt, msg);
        (cache,Values.INTEGER(stop_1),stOpt) = ceval(cache,env, stop, impl, stOpt, msg);
        arr = Util.listMap(ExpressionSimplify.simplifyRange(start_1, step_1, stop_1), ValuesUtil.makeInteger);
      then
        (cache,ValuesUtil.makeArray(arr),stOpt);
    
    // range first:last for enumerations.
    case (cache,env,DAE.RANGE(ty = ety as DAE.ET_ENUMERATION(path = _),exp = start,expOption = NONE(),range = stop),impl,stOpt,msg)
      equation
        (cache,Values.ENUM_LITERAL(index = start_1),stOpt) = ceval(cache,env, start, impl, stOpt, msg);
        (cache,Values.ENUM_LITERAL(index = stop_1),stOpt) = ceval(cache,env, stop, impl, stOpt, msg);
        arr = cevalRangeEnum(start_1, stop_1, ety);
      then
        (cache,ValuesUtil.makeArray(arr),stOpt);

    // range first:last for reals
    case (cache,env,DAE.RANGE(ty = DAE.ET_REAL(),exp = start,expOption = NONE(),range = stop),impl,stOpt,msg)
      equation
        (cache,Values.REAL(realStart1),stOpt) = ceval(cache,env, start, impl, stOpt, msg);
        (cache,Values.REAL(realStop1),stOpt) = ceval(cache,env, stop, impl, stOpt, msg);
        // diff = realStop1 -. realStart1;
        realStep1 = intReal(1);
        arr = Util.listMap(ExpressionSimplify.simplifyRangeReal(realStart1, realStep1, realStop1), ValuesUtil.makeReal);
      then
        (cache,ValuesUtil.makeArray(arr),stOpt);

    // range first:step:last for reals    
    case (cache,env,DAE.RANGE(ty = DAE.ET_REAL(),exp = start,expOption = SOME(step),range = stop),impl,stOpt,msg)
      equation
        (cache,Values.REAL(realStart1),stOpt) = ceval(cache,env, start, impl, stOpt, msg);
        (cache,Values.REAL(realStep1),stOpt) = ceval(cache,env, step, impl, stOpt, msg);
        (cache,Values.REAL(realStop1),stOpt) = ceval(cache,env, stop, impl, stOpt, msg);
        arr = Util.listMap(ExpressionSimplify.simplifyRangeReal(realStart1, realStep1, realStop1), ValuesUtil.makeReal);
      then
        (cache,ValuesUtil.makeArray(arr),stOpt);

    // cast integer to real
    case (cache,env,DAE.CAST(ty = DAE.ET_REAL(),exp = e),impl,stOpt,msg)
      equation
        (cache,Values.INTEGER(i),stOpt) = ceval(cache,env, e, impl, stOpt, msg);
        r = intReal(i);
      then
        (cache,Values.REAL(r),stOpt);

    // cast real to integer
    case (cache,env,DAE.CAST(ty = DAE.ET_INT(), exp = e),impl,stOpt,msg)
      equation
        (cache,Values.REAL(r),stOpt) = ceval(cache, env, e, impl, stOpt, msg);
        i = realInt(r);
      then
        (cache,Values.INTEGER(i),stOpt);
        
    // cast integer to enum
    case (cache,env,DAE.CAST(ty = DAE.ET_ENUMERATION(path = path, names = n), exp = e), impl, stOpt, msg)
      equation
        (cache, Values.INTEGER(i), stOpt) = ceval(cache, env, e, impl, stOpt, msg);
        str = listNth(n, i - 1);
        path = Absyn.joinPaths(path, Absyn.IDENT(str));
      then
        (cache, Values.ENUM_LITERAL(path, i), stOpt);

    // cast integer array to real array
    case (cache,env,DAE.CAST(ty = DAE.ET_ARRAY(ty = DAE.ET_REAL()),exp = e),impl,stOpt,msg)
      equation
        (cache,Values.ARRAY(ivals,dims),stOpt) = ceval(cache,env, e, impl, stOpt, msg);
        rvals = ValuesUtil.typeConvert(DAE.ET_INT(), DAE.ET_REAL(), ivals);
      then
        (cache,Values.ARRAY(rvals,dims),stOpt);

    // if expressions, select then branch if condition is true
    case (cache,env,DAE.IFEXP(expCond = cond,expThen = e1,expElse = e2),impl,stOpt,msg)
      equation
        (cache,Values.BOOL(true),stOpt) = ceval(cache, env, cond, impl, stOpt, msg) "Ifexp, true branch" ;
        (cache,v,stOpt) = ceval(cache,env, e1, impl, stOpt, msg);
      then
        (cache,v,stOpt);

    // if expressions, select else branch if condition is false
    case (cache,env,DAE.IFEXP(expCond = cond,expThen = e1,expElse = e2),impl,stOpt,msg)
      equation
        (cache,Values.BOOL(false),stOpt) = ceval(cache, env, cond, impl, stOpt, msg) "Ifexp, false branch" ;
        (cache,v,stOpt) = ceval(cache,env, e2, impl, stOpt, msg);
      then
        (cache,v,stOpt);

    // indexing for array[integer index] 
    case (cache,env,DAE.ASUB(exp = e,sub = ((e1 as DAE.ICONST(indx))::{})),impl,stOpt,msg)
      equation
        (cache,Values.ARRAY(vals,_),stOpt) = ceval(cache,env, e, impl, stOpt, msg) "asub" ;
        indx_1 = indx - 1;
        v = listNth(vals, indx_1);
      then
        (cache,v,stOpt);
    
    // indexing for array[subscripts]
    case (cache, env, DAE.ASUB(exp = e,sub = expl ), impl, stOpt, msg)
      equation
        (cache,Values.ARRAY(vals,dims),stOpt) = ceval(cache,env, e, impl, stOpt, msg);
        (cache,es_1,stOpt) = cevalList(cache,env, expl, impl, stOpt, msg);
        v = Util.listFirst(es_1);
        v = ValuesUtil.nthnthArrayelt(es_1,Values.ARRAY(vals,dims),v);
      then
        (cache,v,stOpt);

    case (cache, env, DAE.REDUCTION(reductionInfo=DAE.REDUCTIONINFO(path = path, foldExp = foldExp, defaultValue = ov, exprType = ty), expr = daeExp, iterators = iterators), impl, stOpt, msg)
      equation
        env = Env.openScope(env, SCode.NOT_ENCAPSULATED(), SOME(Env.forScopeName), NONE());
        (cache, valMatrix, names, dims, tys, stOpt) = cevalReductionIterators(cache, env, iterators, impl, stOpt, msg);
        // print("Before:\n");print(Util.stringDelimitList(Util.listMap1(Util.listListMap(valMatrix, ValuesUtil.valString), Util.stringDelimitList, ","), "\n") +& "\n");
        valMatrix = Util.allCombinations(valMatrix,SOME(10000),Absyn.dummyInfo);
        // print("After:\n");print(Util.stringDelimitList(Util.listMap1(Util.listListMap(valMatrix, ValuesUtil.valString), Util.stringDelimitList, ","), "\n") +& "\n");
        // print("Start cevalReduction: " +& Absyn.pathString(path) +& " " +& ValuesUtil.valString(startValue) +& " " +& ValuesUtil.valString(Values.TUPLE(vals)) +& " " +& ExpressionDump.printExpStr(daeExp) +& "\n");
        (cache, ov, stOpt) = cevalReduction(cache, env, path, ov, daeExp, ty, foldExp, names, listReverse(valMatrix), tys, impl, stOpt, msg);
        value = Util.getOptionOrDefault(ov, Values.META_FAIL());
        value = backpatchArrayReduction(path, value, dims);
      then (cache, value, stOpt);

    // ceval can fail and that is ok, caught by other rules... 
    case (cache,env,e,_,_,_) // MSG())
      equation
        true = RTOpts.debugFlag("ceval");
        Debug.traceln("- Ceval.ceval failed: " +& ExpressionDump.printExpStr(e));
        Debug.traceln("  Scope: " +& Env.printEnvPathStr(env));
        // Debug.traceln("  Env:" +& Env.printEnvStr(env));
      then
        fail();
  end matchcontinue;
end ceval;

public function cevalIfConstant
  "This function constant evaluates an expression if the expression is constant,
   or if the expression is a call of parameter constness whose return type
   contains unknown dimensions (in which case we need to determine the size of
   those dimensions)."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp inExp;
  input DAE.Properties inProp;
  input Boolean impl;
  input Absyn.Info inInfo;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProp;
algorithm
  (outCache, outExp, outProp) := 
  matchcontinue(inCache, inEnv, inExp, inProp, impl, inInfo)
    local 
        DAE.Exp e;
        Values.Value v;
        Env.Cache cache;
        DAE.Properties prop;
      DAE.Type tp;
        
    case (_, _, e as DAE.CALL(attr = DAE.CALL_ATTR(ty = DAE.ET_ARRAY(arrayDimensions = _))), 
        DAE.PROP(constFlag = DAE.C_PARAM()), _, _)
      equation
        (e, prop) = cevalWholedimRetCall(e, inCache, inEnv, inInfo);
      then
        (inCache, e, prop);
    
    case (_, _, e, DAE.PROP(constFlag = DAE.C_PARAM(), type_ = tp), _, _) // BoschRexroth specifics
      equation
        false = OptManager.getOption("cevalEquation");
      then
        (inCache, e, DAE.PROP(tp, DAE.C_VAR()));
    
    case (_, _, e, DAE.PROP(constFlag = DAE.C_CONST()), _, _)
      equation
        (cache, v, _) = ceval(inCache, inEnv, e, impl, NONE(), NO_MSG());
        e = ValuesUtil.valueExp(v);
      then
        (cache, e, inProp);
    
    case (_, _, e, DAE.PROP_TUPLE(tupleConst = _), _, _)
      equation
        DAE.C_CONST() = Types.propAllConst(inProp);
        (cache, v, _) = ceval(inCache, inEnv, e, impl, NONE(), NO_MSG());
        e = ValuesUtil.valueExp(v);
      then
        (cache, e, inProp);
    
    case (_, _, e, DAE.PROP_TUPLE(tupleConst = _), _, _) // BoschRexroth specifics
      equation
        false = OptManager.getOption("cevalEquation");
        DAE.C_PARAM() = Types.propAllConst(inProp);
        print(" tuple non constant evaluation not implemented yet\n");
      then
        fail();
    
    case (_, _, _, _, _, _)
      equation
        // If we fail to evaluate, at least we should simplify the expression
        (e,_) = ExpressionSimplify.simplify1(inExp);
      then (inCache, e, inProp);
  
  end matchcontinue;
end cevalIfConstant;

protected function cevalWholedimRetCall
  "Helper function to cevalIfConstant. Determines the size of any unknown
   dimensions in a function calls return type."
  input DAE.Exp inExp;
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Info inInfo;
  output DAE.Exp outExp;
  output DAE.Properties outProp;
algorithm
  (outExp, outProp) := match(inExp, inCache, inEnv, inInfo)
    local
      DAE.Exp e;
      Absyn.Path p;
      list<DAE.Exp> el;
      Boolean t, b;
      DAE.InlineType i;
      list<DAE.Dimension> dims;
      Values.Value v;
      DAE.Type cevalType;
      DAE.ExpType cevalExpType;
      DAE.TailCall tc;
           
     case (e as DAE.CALL(path = p, expLst = el, attr = DAE.CALL_ATTR(tuple_ = t, builtin = b, 
           ty = DAE.ET_ARRAY(arrayDimensions = dims), inlineType = i, tailCall = tc)), _, _, _)
       equation
         true = Expression.arrayContainWholeDimension(dims);
         (_, v, _) = ceval(inCache, inEnv, e, true,NONE(), MSG(inInfo));
         cevalType = Types.typeOfValue(v);
         cevalExpType = Types.elabType(cevalType);
       then
         (DAE.CALL(p, el, DAE.CALL_ATTR(cevalExpType, t, b, i, tc)), DAE.PROP(cevalType, DAE.C_PARAM()));
  end match;
end cevalWholedimRetCall;

public function cevalRangeIfConstant
  "Constant evaluates the limits of a range if they are constant."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp inExp;
  input DAE.Properties inProp;
  input Boolean impl;
  input Absyn.Info inInfo;
  output Env.Cache outCache;
  output DAE.Exp outExp;
algorithm
  (outCache, outExp) := matchcontinue(inCache, inEnv, inExp, inProp, impl, inInfo)
    local
      DAE.Exp e1, e2;
      Option<DAE.Exp> e3;
      DAE.ExpType ty;
      Env.Cache cache;
      
    case (_, _, DAE.RANGE(ty = ty, exp = e1, range = e2, expOption = e3), _, _, _)
      equation
        (cache, e1, _) = cevalIfConstant(inCache, inEnv, e1, inProp, impl, inInfo);
        (cache, e2, _) = cevalIfConstant(cache, inEnv, e2, inProp, impl, inInfo);
      then
        (inCache, DAE.RANGE(ty, e1, e3, e2));
    else (inCache, inExp);
  end matchcontinue;
end cevalRangeIfConstant;

protected function cevalBuiltin
"function: cevalBuiltin
  Helper for ceval. Parts for builtin calls are moved here, for readability.
  See ceval for documentation.
  NOTE:    It\'s ok if cevalBuiltin fails. Just means the call was not a builtin function"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp inExp;
  input Boolean inBoolean "impl";
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
  partial function HandlerFunc
    input Env.Cache inCache;
    input list<Env.Frame> inEnvFrameLst;
    input list<DAE.Exp> inExpExpLst;
    input Boolean inBoolean;
    input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
    input Msg inMsg;
    output Env.Cache outCache;
    output Values.Value outValue;
    output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
  end HandlerFunc;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Values.Value v,newval;
      Option<Interactive.SymbolTable> st;
      list<Env.Frame> env;
      DAE.Exp exp,dim,e;
      Boolean impl,builtin;
      Msg msg;
      HandlerFunc handler;
      String id;
      list<DAE.Exp> args,expl;
      list<Values.Value> vallst;
      Absyn.Path funcpath,path;
      Env.Cache cache;
      Option<Integer> dimOpt;

    case (cache,env,DAE.SIZE(exp = exp,sz = SOME(dim)),impl,st,msg)
      equation
        (cache,v,st) = cevalBuiltinSize(cache,env, exp, dim, impl, st, msg) "Handle size separately" ;
      then
        (cache,v,st);
    case (cache,env,DAE.SIZE(exp = exp,sz = NONE()),impl,st,msg)
      equation
        (cache,v,st) = cevalBuiltinSizeMatrix(cache,env, exp, impl, st, msg);
      then
        (cache,v,st);
    case (cache,env,DAE.CALL(path = path,expLst = args,attr = DAE.CALL_ATTR(builtin = true)),impl,st,msg)
      equation
        id = Absyn.pathString(path);
        handler = cevalBuiltinHandler(id);
        (cache,v,st) = handler(cache,env, args, impl, st, msg);
      then
        (cache,v,st);
    case (cache,env,(e as DAE.CALL(path = funcpath,expLst = expl,attr = DAE.CALL_ATTR(builtin = true))),impl,(st as NONE()),msg)
      equation
        (cache,vallst,st) = cevalList(cache, env, expl, impl, st, msg);
        (cache,newval,st) = cevalCallFunction(cache, env, e, vallst, impl, st, msg);
      then
        (cache,newval,st);
  end matchcontinue;
end cevalBuiltin;

protected function cevalBuiltinHandler
"function: cevalBuiltinHandler
  This function dispatches builtin functions and operators to a dedicated
  function that evaluates that particular function.
  It takes an identifier as input and returns a function that evaluates that
  function or operator.
  NOTE: size handled specially. see cevalBuiltin:
        removed: case (\"size\") => cevalBuiltinSize"
  input Absyn.Ident inIdent;
  output HandlerFunc handler;
  partial function HandlerFunc
    input Env.Cache inCache;
    input Env.Env inEnv;
    input list<DAE.Exp> inExpExpLst;
    input Boolean inBoolean;
    input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
    input Msg inMsg;
    output Env.Cache outCache;
    output Values.Value outValue;
    output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
  end HandlerFunc;
algorithm
  handler := match (inIdent)
    local
      String id;
    case "floor" then cevalBuiltinFloor;
    case "ceil" then cevalBuiltinCeil;
    case "abs" then cevalBuiltinAbs;
    case "sqrt" then cevalBuiltinSqrt;
    case "div" then cevalBuiltinDiv;
    case "sin" then cevalBuiltinSin;
    case "cos" then cevalBuiltinCos;
    case "tan" then cevalBuiltinTan;
    case "sinh" then cevalBuiltinSinh;
    case "cosh" then cevalBuiltinCosh;
    case "tanh" then cevalBuiltinTanh;
    case "asin" then cevalBuiltinAsin;
    case "acos" then cevalBuiltinAcos;
    case "atan" then cevalBuiltinAtan;
    case "atan2" then cevalBuiltinAtan2;
    case "log" then cevalBuiltinLog;
    case "log10" then cevalBuiltinLog10;
    case "integer" then cevalBuiltinInteger;
    case "boolean" then cevalBuiltinBoolean;
    case "mod" then cevalBuiltinMod;
    case "max" then cevalBuiltinMax;
    case "min" then cevalBuiltinMin;
    case "rem" then cevalBuiltinRem;
    case "diagonal" then cevalBuiltinDiagonal;
    case "transpose" then cevalBuiltinTranspose;
    case "differentiate" then cevalBuiltinDifferentiate;
    case "simplify" then cevalBuiltinSimplify;
    case "sign" then cevalBuiltinSign;
    case "exp" then cevalBuiltinExp;
    case "noEvent" then cevalBuiltinNoevent;
    case "cardinality" then cevalBuiltinCardinality;
    case "cat" then cevalBuiltinCat;
    case "identity" then cevalBuiltinIdentity;
    case "promote" then cevalBuiltinPromote;
    case "String" then cevalBuiltinString;
    case "linspace" then cevalBuiltinLinspace;
    case "Integer" then cevalBuiltinIntegerEnumeration;
    case "rooted" then cevalBuiltinRooted; //
    case "cross" then cevalBuiltinCross;
    case "fill" then cevalBuiltinFill;
    case "Modelica.Utilities.Strings.substring" then cevalBuiltinSubstring;
    case "print" then cevalBuiltinPrint;
    // MetaModelica type conversions
    case "intReal" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalIntReal;
    case "intString" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalIntString;
    case "realInt" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalRealInt;
    case "realString" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalRealString;
    case "stringCharInt" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalStringCharInt;
    case "intStringChar" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalIntStringChar;
    case "stringLength" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalStringLength;
    case "stringInt" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalStringInt;
    // case "stringReal" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalStringReal;
    case "stringListStringChar" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalStringListStringChar;
    case "listStringCharString" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalListStringCharString;
    case "stringAppendList" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalStringAppendList;
    case "listLength" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalListLength;
    case "listAppend" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalListAppend;
    case "listReverse" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalListReverse;
    case "listHead" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalListFirst;
    case "listRest" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalListRest;
    case "anyString" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalAnyString;

    //case "semiLinear" then cevalBuiltinSemiLinear;
    //case "delay" then cevalBuiltinDelay;
    case id
      equation
        true = RTOpts.debugFlag("ceval");
        Debug.traceln("No cevalBuiltinHandler found for " +& id);
      then
        fail();
  end match;
end cevalBuiltinHandler;

protected function cevalCallFunction "function: cevalCallFunction
  This function evaluates CALL expressions, i.e. function calls.
  They are currently evaluated by generating code for the function and
  then dynamicly load the function and call it."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp inExp;
  input list<Values.Value> inValuesValueLst;
  input Boolean impl;
  input Option<Interactive.SymbolTable> inSymTab;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outSymTab;
algorithm
  (outCache,outValue,outSymTab) := matchcontinue (inCache,inEnv,inExp,inValuesValueLst,impl,inSymTab,inMsg)
    local
      Values.Value newval;
      list<Env.Frame> env;
      DAE.Exp e;
      Absyn.Path funcpath;
      list<DAE.Exp> expl;
      Boolean builtin;
      list<Values.Value> vallst;
      Msg msg;
      Env.Cache cache;
      list<Interactive.CompiledCFunction> cflist;
      Option<Interactive.SymbolTable> st;
      Absyn.Program p;
      Integer libHandle, funcHandle;
      String fNew,fOld;
      Real buildTime, edit, build;
      AbsynDep.Depends aDep;
      Option<list<SCode.Element>> a;
      list<Interactive.InstantiatedClass> b;
      list<Interactive.Variable> c;
      list<Interactive.CompiledCFunction> cf;
      list<Interactive.LoadedFile> lf;
      Absyn.TimeStamp ts;
      String funcstr,f;
      list<Interactive.CompiledCFunction> newCF;
      String name;
      Boolean ppref, fpref, epref;
      Absyn.ClassDef    body;
      Absyn.Info        info;
      Absyn.Within      w;
      Absyn.Path complexName;
      list<Absyn.Path> functionDependencies;
      list<Expression.Var> varLst;
      list<String> varNames;
      SCode.Element sc;
      SCode.ClassDef cdef;
      String error_Str;
      DAE.Function func;
      SCode.Restriction res;
    
    // External functions that are "known" should be evaluated without compilation, e.g. all math functions
    case (cache,env,(e as DAE.CALL(path = funcpath,expLst = expl)),vallst,impl,st,msg)
      equation
        (cache,newval) = cevalKnownExternalFuncs(cache,env, funcpath, vallst, msg);
      then
        (cache,newval,st);

    // This case prevents the constructor call of external objects of being evaluated
    case (cache,env as _ :: _,(e as DAE.CALL(path = funcpath,expLst = expl)),vallst,impl,st,msg)
      equation
        cevalIsExternalObjectConstructor(cache,funcpath,env,msg);
      then
        fail();
       
    // Record constructors
    case(cache,env,(e as DAE.CALL(path = funcpath,attr = DAE.CALL_ATTR(ty = DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(complexName), varLst=varLst)))),vallst,impl,st,msg)
      equation
        Debug.fprintln("dynload", "CALL: record constructor: func: " +& Absyn.pathString(funcpath) +& " type path: " +& Absyn.pathString(complexName));
        true = ModUtil.pathEqual(funcpath,complexName);
        varNames = Util.listMap(varLst,Expression.varName);
        Debug.fprintln("dynload", "CALL: record constructor: [success] func: " +& Absyn.pathString(funcpath));        
      then 
        (cache,Values.RECORD(funcpath,vallst,varNames,-1),st);

    // try function interpretation
    case (cache,env, DAE.CALL(path = funcpath, attr = DAE.CALL_ATTR(builtin = false)), vallst, impl, st, msg)
      equation
        false = RTOpts.debugFlag("noevalfunc");
        failure(cevalIsExternalObjectConstructor(cache, funcpath, env, msg));
        Debug.fprintln("dynload", "CALL: try constant evaluation: " +& Absyn.pathString(funcpath));
        (cache, 
         sc as SCode.CLASS(
          partialPrefix = SCode.NOT_PARTIAL(), 
          restriction = res,
          classDef = cdef),
         env) = Lookup.lookupClass(cache, env, funcpath, true);
        isCevaluableFunction(sc);
        (cache, env, _) = Inst.implicitFunctionInstantiation(
          cache,
          env,
          InnerOuter.emptyInstHierarchy,
          DAE.NOMOD(),
          Prefix.NOPRE(),
          sc,
          {});
        func = Env.getCachedInstFunc(cache, funcpath);
        (cache, newval, st) = CevalFunction.evaluate(cache, env, func, vallst, st);
        Debug.fprintln("dynload", "CALL: constant evaluation SUCCESS: " +& Absyn.pathString(funcpath));
      then
        (cache, newval, st);

    // see if function is in CF list and the build time is less than the edit time
    case (cache,env,(e as DAE.CALL(path = funcpath, expLst = expl, attr = DAE.CALL_ATTR(builtin = false))),vallst,impl,// (impl as true)
      (st as SOME(Interactive.SYMBOLTABLE(p as Absyn.PROGRAM(globalBuildTimes=Absyn.TIMESTAMP(_,edit)),_,_,_,_,cflist,_))),msg)
      equation
        false = RTOpts.debugFlag("nogen");
        failure(cevalIsExternalObjectConstructor(cache,funcpath,env,msg));
                
        Debug.fprintln("dynload", "CALL: [func from file] check if is in CF list: " +& Absyn.pathString(funcpath));
        
        (true, funcHandle, buildTime, fOld) = Static.isFunctionInCflist(cflist, funcpath);
        Absyn.CLASS(_,_,_,_,Absyn.R_FUNCTION(),_,Absyn.INFO(fileName = fNew)) = Interactive.getPathedClassInProgram(funcpath, p);
        // see if the build time from the class is the same as the build time from the compiled functions list
        false = stringEq(fNew,""); // see if the WE have a file or not!
        false = Static.needToRebuild(fNew,fOld,buildTime); // we don't need to rebuild!
        
        Debug.fprintln("dynload", "CALL: [func from file] About to execute function present in CF list: " +& Absyn.pathString(funcpath));        
        
        newval = DynLoad.executeFunction(funcHandle, vallst);
      then
        (cache,newval,st);
    
    // see if function is in CF list and the build time is less than the edit time
    case (cache,env,(e as DAE.CALL(path = funcpath, expLst = expl, attr = DAE.CALL_ATTR(builtin = false))),vallst,impl,// impl as true
      (st as SOME(Interactive.SYMBOLTABLE(p as Absyn.PROGRAM(globalBuildTimes=Absyn.TIMESTAMP(_,edit)),_,_,_,_,cflist,_))),msg)
      equation
        false = RTOpts.debugFlag("nogen");
        failure(cevalIsExternalObjectConstructor(cache,funcpath,env,msg));
        
        Debug.fprintln("dynload", "CALL: [func from buffer] check if is in CF list: " +& Absyn.pathString(funcpath));
                
        (true, funcHandle, buildTime, fOld) = Static.isFunctionInCflist(cflist, funcpath);
        Absyn.CLASS(_,_,_,_,Absyn.R_FUNCTION(),_,Absyn.INFO(fileName = fNew, buildTimes= Absyn.TIMESTAMP(build,_))) = Interactive.getPathedClassInProgram(funcpath, p);
        // note, this should only work for classes that have no file name!
        true = stringEq(fNew,""); // see that we don't have a file!

        // see if the build time from the class is the same as the build time from the compiled functions list
        true = (buildTime >=. build);
        true = (buildTime >. edit);
        
        Debug.fprintln("dynload", "CALL: [func from buffer] About to execute function present in CF list: " +& Absyn.pathString(funcpath));
        
        newval = DynLoad.executeFunction(funcHandle, vallst);
      then
        (cache,newval,st);

    // not in CF list, we have a symbol table, generate function and update symtab
    case (cache,env,(e as DAE.CALL(path = funcpath,expLst = expl,attr = DAE.CALL_ATTR(builtin = false))),vallst,impl,
          SOME(Interactive.SYMBOLTABLE(p as Absyn.PROGRAM(globalBuildTimes=ts),aDep,a,b,c,cf,lf)),msg) // yeha! we have a symboltable!
      equation
        false = RTOpts.debugFlag("nogen");
        failure(cevalIsExternalObjectConstructor(cache,funcpath,env,msg));
        
        Debug.fprintln("dynload", "CALL: [SOME SYMTAB] not in in CF list: " +& Absyn.pathString(funcpath));        
        
        // remove it and all its dependencies as it might be there with an older build time.
        // get dependencies!
        (_, functionDependencies, _) = CevalScript.getFunctionDependencies(cache, funcpath);
        newCF = Interactive.removeCfAndDependencies(cf, funcpath::functionDependencies);
        
        Debug.fprintln("dynload", "CALL: [SOME SYMTAB] not in in CF list: removed deps:" +& 
          Util.stringDelimitList(Util.listMap(functionDependencies, Absyn.pathString) ,", "));        
        
        // now is safe to generate code 
        (cache, funcstr) = CevalScript.cevalGenerateFunction(cache, env, funcpath);
        
        libHandle = System.loadLibrary(funcstr);
        funcHandle = System.lookupFunction(libHandle, stringAppend("in_", funcstr));
        newval = DynLoad.executeFunction(funcHandle, vallst);
        System.freeLibrary(libHandle);
        buildTime = System.getCurrentTime();
        // update the build time in the class!
        Absyn.CLASS(name,ppref,fpref,epref,Absyn.R_FUNCTION(),body,info) = Interactive.getPathedClassInProgram(funcpath, p);

        info = Absyn.setBuildTimeInInfo(buildTime,info);
        ts = Absyn.setTimeStampBuild(ts, buildTime);
        w = Interactive.buildWithin(funcpath);
        
        Debug.fprintln("dynload", "Updating build time for function path: " +& Absyn.pathString(funcpath) +& " within: " +& Dump.unparseWithin(0, w) +& "\n");
        
        p = Interactive.updateProgram(Absyn.PROGRAM({Absyn.CLASS(name,ppref,fpref,epref,Absyn.R_FUNCTION(),body,info)},w,ts), p);
        f = Absyn.getFileNameFromInfo(info);
        
        Debug.fprintln("dynload", "CALL: [SOME SYMTAB] not in in CF list [finished]: " +& Absyn.pathString(funcpath));
      then
        (cache,newval,SOME(Interactive.SYMBOLTABLE(p, aDep, a, b, c,
          Interactive.CFunction(funcpath,(DAE.T_NOTYPE(),SOME(funcpath)),funcHandle,buildTime,f)::newCF, lf)));

    
    // no symtab, WE SHOULD NOT EVALUATE! 
    case (cache,env,(e as DAE.CALL(path = funcpath,expLst = expl,attr = DAE.CALL_ATTR(builtin = false))),vallst,impl,NONE(),msg) // crap! we have no symboltable!
      equation
        false = RTOpts.debugFlag("nogen");
        failure(cevalIsExternalObjectConstructor(cache,funcpath,env,msg));
         
        Debug.fprintln("dynload", "CALL: [NO SYMTAB] not in in CF list: " +& Absyn.pathString(funcpath));         
         
        // we might actually have a function loaded here already!
        // we need to unload all functions to not get conflicts!
        (cache,funcstr) = CevalScript.cevalGenerateFunction(cache, env, funcpath);
        // generate a uniquely named dll!
        Debug.fprintln("dynload", "cevalCallFunction: about to execute " +& funcstr);
        libHandle = System.loadLibrary(funcstr);
        funcHandle = System.lookupFunction(libHandle, stringAppend("in_", funcstr));
        newval = DynLoad.executeFunction(funcHandle, vallst);
        System.freeFunction(funcHandle);
        System.freeLibrary(libHandle);
        
        Debug.fprintln("dynload", "CALL: [NO SYMTAB] not in in CF list [finished]: " +& Absyn.pathString(funcpath));
        
      then
        (cache,newval,NONE());

    case (cache,env,(e as DAE.CALL(path = funcpath,expLst = expl)),vallst,impl,st,msg)
      equation
        Debug.fprintln("dynload", "CALL: FAILED to constant evaluate function: " +& Absyn.pathString(funcpath)); 
        error_Str = Absyn.pathString(funcpath);
        //TODO: readd this when testsuite is okay.
        //Error.addMessage(Error.FAILED_TO_EVALUATE_FUNCTION, {error_Str});
        true = RTOpts.debugFlag("nogen");
        Debug.fprint("failtrace", "- codegeneration is turned off. switch \"nogen\" flag off\n");
      then
        fail();
  end matchcontinue;
end cevalCallFunction;

protected function cevalIsExternalObjectConstructor
  input Env.Cache cache;
  input Absyn.Path funcpath;
  input Env.Env env;
  input Msg msg;
protected
  Absyn.Path funcpath2;
  DAE.Type tp;
  Option<Absyn.Info> info;
algorithm
  _ := match(cache, funcpath, env, msg)
    case (_, _, {}, NO_MSG()) then fail();
    case (_, _, _, NO_MSG())
      equation
        (funcpath2, Absyn.IDENT("constructor")) = Absyn.splitQualAndIdentPath(funcpath);
        info = Util.if_(Util.isEqual(msg, NO_MSG()), NONE(), SOME(Absyn.dummyInfo));
        (_, tp, _) = Lookup.lookupType(cache, env, funcpath2, info);
        Types.externalObjectConstructorType(tp);
      then
        ();
  end match;
end cevalIsExternalObjectConstructor;

protected function cevalKnownExternalFuncs "function: cevalKnownExternalFuncs
  Evaluates external functions that are known, e.g. all math functions."
  input Env.Cache inCache;
  input Env.Env env;
  input Absyn.Path funcpath;
  input list<Values.Value> vals;
  input Msg msg;
  output Env.Cache outCache;
  output Values.Value res;
protected
  SCode.Element cdef;
  list<Env.Frame> env_1;
  String fid,id;
  Option<SCode.ExternalDecl> extdecl;
  Option<String> lan;
  Option<Absyn.ComponentRef> out;
  list<Absyn.Exp> args;
algorithm
  (outCache,cdef,env_1) := Lookup.lookupClass(inCache,env, funcpath, false);
  SCode.CLASS(name=fid,restriction = SCode.R_EXT_FUNCTION(), classDef=SCode.PARTS(externalDecl=extdecl)) := cdef;
  SOME(SCode.EXTERNALDECL(SOME(id),lan,out,args,_)) := extdecl;
  isKnownExternalFunc(fid, id);
  res := cevalKnownExternalFuncs2(fid, id, vals, msg);
end cevalKnownExternalFuncs;

public function isKnownExternalFunc "function isKnownExternalFunc
  Succeds if external function name is
  \"known\", i.e. no compilation required."
  input String fid;
  input String id;
algorithm
  _:=  match (fid,id)
    case ("acos","acos") then ();
    case ("asin","asin") then ();
    case ("atan","atan") then ();
    case ("atan2","atan2") then ();
    case ("cos","cos") then ();
    case ("cosh","cosh") then ();
    case ("exp","exp") then ();
    case ("log","log") then ();
    case ("log10","log10") then ();
    case ("sin","sin") then ();
    case ("sinh","sinh") then ();
    case ("tan","tan") then ();
    case ("tanh","tanh") then ();
    case ("substring","ModelicaStrings_substring") then ();
  end match;
end isKnownExternalFunc;

protected function isCevaluableFunction
  "Checks if an element is a function or external function that can be evaluated
  by CevalFunction."
  input SCode.Element inElement;
algorithm
  _ := match(inElement)
    local
      String fid;
      SCode.Mod mod;
      Absyn.Exp lib;

    // All functions can be evaluated.
    case (SCode.CLASS(restriction = SCode.R_FUNCTION())) then ();

    // But only some external functions.
    case (SCode.CLASS(restriction = SCode.R_EXT_FUNCTION(), 
        classDef = SCode.PARTS(externalDecl = SOME(SCode.EXTERNALDECL(
          funcName = SOME(fid), 
          annotation_ = SOME(SCode.ANNOTATION(mod)))))))
      equation
        SCode.MOD(binding = SOME((lib, _))) = Mod.getUnelabedSubMod(mod, "Library");
        true = checkLibraryUsage("Lapack", lib);
        isCevaluableFunction2(fid);
      then
        ();
  end match;
end isCevaluableFunction;

protected function checkLibraryUsage
  input String inLibrary;
  input Absyn.Exp inExp;
  output Boolean isUsed;
algorithm
  isUsed := match(inLibrary, inExp)
    local
      String s;
      list<Absyn.Exp> exps;

    case (_, Absyn.STRING(s)) then stringEq(s, inLibrary);
    case (_, Absyn.ARRAY(exps))
      then Util.listMemberWithCompareFunc(inLibrary, exps, checkLibraryUsage);
  end match;
end checkLibraryUsage;
        
protected function isCevaluableFunction2
  "Checks if a function name belongs to a known external function that we can
  constant evaluate."
  input String inFuncName;
algorithm
  _ := match(inFuncName)
    local
      // Lapack functions.
      case "dgbsv" then ();
      case "dgeev" then ();
      case "dgegv" then ();
      case "dgels" then ();
      case "dgelsx" then ();
      case "dgeqpf" then ();
      case "dgesv" then ();
      case "dgesvd" then ();
      case "dgetrf" then ();
      case "dgetri" then ();
      case "dgetrs" then ();
      case "dgglse" then ();
      case "dgtsv" then ();
      case "dorgqr" then ();
  end match;
end isCevaluableFunction2;

protected function cevalKnownExternalFuncs2 "function: cevalKnownExternalFuncs2
  author: PA
  Helper function to cevalKnownExternalFuncs, does the evaluation."
  input String fid;
  input String id;
  input list<Values.Value> inValuesValueLst;
  input Msg inMsg;
  output Values.Value outValue;
algorithm
  outValue := match (fid,id,inValuesValueLst,inMsg)
    local 
      Real rv_1,rv,rv1,rv2,sv,cv;
      String str;
      Integer start, stop;
      
    case ("acos","acos",{Values.REAL(real = rv)},_)
      equation
        rv_1 = realAcos(rv);
      then
        Values.REAL(rv_1);
    case ("asin","asin",{Values.REAL(real = rv)},_)
      equation
        rv_1 = realAsin(rv);
      then
        Values.REAL(rv_1);
    case ("atan","atan",{Values.REAL(real = rv)},_)
      equation
        rv_1 = realAtan(rv);
      then
        Values.REAL(rv_1);
    case ("atan2","atan2",{Values.REAL(real = rv1),Values.REAL(real = rv2)},_)
      equation
        rv_1 = realAtan2(rv1, rv2);
      then
        Values.REAL(rv_1);
    case ("cos","cos",{Values.REAL(real = rv)},_)
      equation
        rv_1 = realCos(rv);
      then
        Values.REAL(rv_1);
    case ("cosh","cosh",{Values.REAL(real = rv)},_)
      equation
        rv_1 = realCosh(rv);
      then
        Values.REAL(rv_1);
    case ("exp","exp",{Values.REAL(real = rv)},_)
      equation
        rv_1 = realExp(rv);
      then
        Values.REAL(rv_1);
    case ("log","log",{Values.REAL(real = rv)},_)
      equation
        rv_1 = realLn(rv);
      then
        Values.REAL(rv_1);
    case ("log10","log10",{Values.REAL(real = rv)},_)
      equation
        rv_1 = realLog10(rv);
      then
        Values.REAL(rv_1);
    case ("sin","sin",{Values.REAL(real = rv)},_)
      equation
        rv_1 = realSin(rv);
      then
        Values.REAL(rv_1);
    case ("sinh","sinh",{Values.REAL(real = rv)},_)
      equation
        rv_1 = realSinh(rv);
      then
        Values.REAL(rv_1);
    case ("tan","tan",{Values.REAL(real = rv)},_)
      equation
        sv = realSin(rv);
        cv = realCos(rv);
        rv_1 = sv/. cv;
      then
        Values.REAL(rv_1);
    case ("tanh","tanh",{Values.REAL(real = rv)},_)
      equation
        rv_1 = realTanh(rv);
      then
        Values.REAL(rv_1);
    
    case ("substring","ModelicaStrings_substring",
          {
           Values.STRING(string = str),
           Values.INTEGER(integer = start),
           Values.INTEGER(integer = stop)
          },_)
      equation
        str = System.substring(str, start, stop);
      then
        Values.STRING(str);
  end match;
end cevalKnownExternalFuncs2;

protected function cevalMatrixElt "function: cevalMatrixElt
  Evaluates the expression of a matrix constructor, e.g. {1,2;3,4}"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<list<DAE.Exp>> inTplExpExpBooleanLstLst "matrix constr. elts";
  input Boolean inBoolean "impl";
  input Msg inMsg;
  output Env.Cache outCache;
  output list<Values.Value> outValuesValueLst;
algorithm
  (outCache,outValuesValueLst) :=
  match (inCache,inEnv,inTplExpExpBooleanLstLst,inBoolean,inMsg)
    local
      Values.Value v;
      list<Values.Value> vl;
      list<Env.Frame> env;
      list<DAE.Exp> expl;
      list<list<DAE.Exp>> expll;
      Boolean impl;
      Msg msg;
      Env.Cache cache;
    case (cache,env,(expl :: expll),impl,msg)
      equation
        (cache,vl,_) = cevalList(cache,env,expl,impl,NONE(),msg);
        v = ValuesUtil.makeArray(vl);
        (cache,vl)= cevalMatrixElt(cache,env, expll, impl, msg);
      then
        (cache,v :: vl);
    case (cache,_,{},_,msg) then (cache,{});
  end match;
end cevalMatrixElt;

protected function cevalBuiltinSize "function: cevalBuiltinSize
  Evaluates the size operator."
  input Env.Cache inCache;
  input Env.Env inEnv1;
  input DAE.Exp inExp2;
  input DAE.Exp inDimExp;
  input Boolean inBoolean4;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption5;
  input Msg inMsg6;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv1,inExp2,inDimExp,inBoolean4,inInteractiveInteractiveSymbolTableOption5,inMsg6)
    local
      DAE.Attributes attr;
      DAE.Type tp;
      DAE.Binding bind,binding;
      list<Integer> sizelst,adims;
      Integer dim,dim_1,dimv,len,i;
      Option<Interactive.SymbolTable> st_1,st;
      list<Env.Frame> env;
      DAE.ComponentRef cr;
      Boolean impl,bl;
      Msg msg;
      list<DAE.Dimension> dims;
      Values.Value v2,val;
      DAE.ExpType crtp,expTp;
      DAE.Exp exp,e,dimExp;
      String cr_str,dim_str,size_str,expstr;
      list<DAE.Exp> es;
      Env.Cache cache;
      list<list<DAE.Exp>> mat;
      Absyn.Info info;
    
    case (cache,_,DAE.MATRIX(matrix=mat),DAE.ICONST(1),_,st,_)
      equation
        i = listLength(mat);
      then
        (cache,Values.INTEGER(i),st);
    
    case (cache,_,DAE.MATRIX(matrix=mat),DAE.ICONST(2),_,st,_)
      equation
        i = listLength(Util.listFirst(mat));
      then
        (cache,Values.INTEGER(i),st);
    
    case (cache,env,DAE.MATRIX(matrix=mat),DAE.ICONST(dim),impl,st,msg)
      equation
        bl = (dim>2);
        true = bl;
        dim_1 = dim-2;
        e = Util.listFirst(Util.listFirst(mat));
        (cache,Values.INTEGER(i),st_1)=cevalBuiltinSize(cache,env,e,DAE.ICONST(dim_1),impl,st,msg);
      then
        (cache,Values.INTEGER(i),st);
    
    case (cache,env,DAE.CREF(componentRef = cr),dimExp,impl,st,msg)
      equation
        (cache,attr,tp,bind,_,_,_,_,_) = Lookup.lookupVar(cache,env, cr) "If dimensions known, always ceval" ;
        true = Types.dimensionsKnown(tp);
        (sizelst as (_ :: _)) = Types.getDimensionSizes(tp);
        (cache,Values.INTEGER(dim),st_1) = ceval(cache, env, dimExp, impl, st, msg);
        dim_1 = dim - 1;
        i = listNth(sizelst, dim_1);
      then
        (cache,Values.INTEGER(i),st_1);
    
    case (cache,env,DAE.CREF(componentRef = cr,ty = expTp),dimExp,(impl as false),st,msg)
      equation
        (cache,dims) = Inst.elabComponentArraydimFromEnv(cache,env,cr,Absyn.dummyInfo) 
        "If component not instantiated yet, recursive definition.
         For example,
           Real x[:](min=fill(1.0,size(x,1))) = {1.0}
         When size(x,1) should be determined, x must be instantiated, but
         that is not done yet. Solution: Examine Element to find modifier
         which will determine dimension size.";
        (cache,Values.INTEGER(dimv),st_1) = ceval(cache, env, dimExp, impl, st, msg);
        v2 = cevalBuiltinSize3(dims, dimv);
      then
        (cache,v2,st_1);
    
    case (cache,env,DAE.CREF(componentRef = cr,ty = expTp),dimExp,(impl as true),st,msg)
      equation
        (cache,attr,tp,bind,_,_,_,_,_) = Lookup.lookupVar(cache, env, cr) "If dimensions not known and impl=true, just silently fail";
        false = Types.dimensionsKnown(tp);
      then
        fail();
    
    case (cache,env,DAE.CREF(componentRef = cr),dimExp,(impl as false),st,
        MSG(info = info))
      equation
        (cache,attr,tp,bind,_,_,_,_,_) = Lookup.lookupVar(cache, env, cr) "If dimensions not known and impl=false, error message";
        false = Types.dimensionsKnown(tp);
        cr_str = ComponentReference.printComponentRefStr(cr);
        dim_str = ExpressionDump.printExpStr(dimExp);
        size_str = stringAppendList({"size(",cr_str,", ",dim_str,")"});
        Error.addSourceMessage(Error.DIMENSION_NOT_KNOWN, {size_str}, info);
      then
        fail();
    
    case (cache,env,DAE.CREF(componentRef = cr),dimExp,(impl as false),st,NO_MSG())
      equation
        (cache,attr,tp,bind,_,_,_,_,_) = Lookup.lookupVar(cache, env, cr);
        false = Types.dimensionsKnown(tp);
      then
        fail();
    
    case (cache,env,(exp as DAE.CREF(componentRef = cr,ty = crtp)),dimExp,
        (impl as false),st,MSG(info = info))
      equation
        (cache,attr,tp,DAE.UNBOUND(),_,_,_,_,_) = Lookup.lookupVar(cache, env, cr) "For crefs without value binding" ;
        expstr = ExpressionDump.printExpStr(exp);
        Error.addSourceMessage(Error.UNBOUND_VALUE, {expstr}, info);
      then
        fail();
    
    case (cache,env,(exp as DAE.CREF(componentRef = cr,ty = crtp)),dimExp,(impl as false),st,NO_MSG())
      equation
        (cache,attr,tp,DAE.UNBOUND(),_,_,_,_,_) = Lookup.lookupVar(cache, env, cr);
      then
        fail();
    
    case (cache,env,(exp as DAE.CREF(componentRef = cr,ty = crtp)),dimExp,(impl as true),st,msg)
      equation
        (cache,attr,tp,DAE.UNBOUND(),_,_,_,_,_) = Lookup.lookupVar(cache, env, cr) "For crefs without value binding. If impl=true just silently fail" ;
      then
        fail();

    // For crefs with value binding e.g. size(x,1) when Real x[:]=fill(0,1);
    case (cache,env,(exp as DAE.CREF(componentRef = cr,ty = crtp)),dimExp,impl,st,msg)
      equation 
        (cache,attr,tp,binding,_,_,_,_,_) = Lookup.lookupVar(cache, env, cr)  ;
        (cache,Values.INTEGER(dimv),st_1) = ceval(cache,env,dimExp,impl,st,msg);
        (cache,val) = cevalCrefBinding(cache,env, cr, binding, impl, msg);
        v2 = cevalBuiltinSize2(val, dimv);
      then
        (cache,v2,st_1);
    
    case (cache,env,DAE.ARRAY(array = (exp :: es)),dimExp,impl,st,msg)
      equation
        expTp = Expression.typeof(exp) "Special case for array expressions with nonconstant
                                        values For now: only arrays of scalar elements:
                                        TODO generalize to arbitrary dimensions";
        true = Expression.typeBuiltin(expTp);
        (cache,Values.INTEGER(1),st_1) = ceval(cache, env, dimExp, impl, st, msg);
        len = listLength((exp :: es));
      then
        (cache,Values.INTEGER(len),st_1);

    // adrpo 2009-06-08: it doen't need to be a builtin type as long as the dimension is an integer!
    case (cache,env,DAE.ARRAY(array = (exp :: es)),dimExp,impl,st,msg)
      equation
        expTp = Expression.typeof(exp) "Special case for array expressions with nonconstant values
                                        For now: only arrays of scalar elements:
                                        TODO generalize to arbitrary dimensions" ;
        false = Expression.typeBuiltin(expTp);
        (cache,Values.INTEGER(1),st_1) = ceval(cache,env, dimExp, impl, st,msg);
        len = listLength((exp :: es));
      then
        (cache,Values.INTEGER(len),st_1);

    // For expressions with value binding that can not determine type
    // e.g. size(x,2) when Real x[:,:]=fill(0.0,0,2); empty array with second dimension == 2, no way of 
    // knowing that from the value. Must investigate the expression itself.
    case (cache,env,exp,dimExp,impl,st,msg)
      equation
        (cache,Values.ARRAY({},adims),st_1) = ceval(cache,env,exp,impl,st,msg) "try to ceval expression, for constant expressions" ;
        (cache,Values.INTEGER(dimv),st_1) = ceval(cache,env,dimExp,impl,st,msg);
        i = listNth(adims,dimv-1);
      then
        (cache,Values.INTEGER(i),st_1);

    case (cache,env,exp,dimExp,impl,st,msg)
      equation
        (cache,val,st_1) = ceval(cache, env,exp,impl,st,msg) "try to ceval expression, for constant expressions" ;
        (cache,Values.INTEGER(dimv),st_1) = ceval(cache,env,dimExp,impl,st,msg);
        v2 = cevalBuiltinSize2(val, dimv);
      then
        (cache,v2,st_1);
    
    case (cache,env,exp,dimExp,impl,st,MSG(info = _))
      equation
        true = RTOpts.debugFlag("failtrace");
        Print.printErrorBuf("#-- Ceval.cevalBuiltinSize failed: ");
        expstr = ExpressionDump.printExpStr(exp);
        Print.printErrorBuf(expstr);
        Print.printErrorBuf("\n");
      then
        fail();
  end matchcontinue;
end cevalBuiltinSize;

protected function cevalBuiltinSize2 "function: cevalBultinSize2
  Helper function to cevalBuiltinSize"
  input Values.Value inValue;
  input Integer inInteger;
  output Values.Value outValue;
algorithm
  outValue := matchcontinue (inValue,inInteger)
    local
      Integer dim,ind_1,ind;
      list<Values.Value> lst;
      Values.Value l;
      Values.Value dimVal;
    
    case (Values.ARRAY(valueLst = lst),1)
      equation
        dim = listLength(lst);
      then
        Values.INTEGER(dim);
    
    case (Values.ARRAY(valueLst = (l :: lst)),ind)
      equation
        ind_1 = ind - 1;
        dimVal = cevalBuiltinSize2(l, ind_1);
      then
        dimVal;
    
    case (_,_)
      equation
        Debug.fprint("failtrace", "- Ceval.cevalBuiltinSize2 failed\n");
      then
        fail();
  end matchcontinue;
end cevalBuiltinSize2;

protected function cevalBuiltinSize3 "function: cevalBuiltinSize3
  author: PA
  Helper function to cevalBuiltinSize.
  Used when recursive definition (attribute modifiers using size) is used."
  input list<DAE.Dimension> inInstDimExpLst;
  input Integer inInteger;
  output Values.Value outValue;
algorithm
  outValue:=
  match (inInstDimExpLst,inInteger)
    local
      Integer n_1,v,n;
      list<DAE.Dimension> dims;
    case (dims,n)
      equation
        n_1 = n - 1;
        DAE.DIM_INTEGER(v) = listNth(dims, n_1);
      then
        Values.INTEGER(v);
  end match;
end cevalBuiltinSize3;

protected function cevalBuiltinAbs "function: cevalBuiltinAbs
  author: LP
  Evaluates the abs operator."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Integer iv;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env,exp,impl,st,msg);
        rv_1 = realAbs(rv);
      then
        (cache,Values.REAL(rv_1),st);
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.INTEGER(iv),_) = ceval(cache,env,exp,impl,st,msg);
        iv = intAbs(iv);
      then
        (cache,Values.INTEGER(iv),st);
  end matchcontinue;
end cevalBuiltinAbs;

protected function cevalBuiltinSign "function: cevalBuiltinSign
  author: PA
  Evaluates the sign operator."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv;
      Boolean b1,b2,b3,impl;
      list<Env.Frame> env;
      DAE.Exp exp;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Integer iv,iv_1;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env,exp,impl,st,msg);
        b1 = (rv >. 0.0);
        b2 = (rv <. 0.0);
        b3 = (rv ==. 0.0);
        {(_,iv_1)} = Util.listSelect({(b1,1),(b2,-1),(b3,0)}, Util.tuple21);
      then
        (cache,Values.INTEGER(iv_1),st);
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.INTEGER(iv),_) = ceval(cache,env,exp,impl,st,msg);
        b1 = (iv > 0);
        b2 = (iv < 0);
        b3 = (iv == 0);
        {(_,iv_1)} = Util.listSelect({(b1,1),(b2,-1),(b3,0)}, Util.tuple21);
      then
        (cache,Values.INTEGER(iv_1),st);
  end matchcontinue;
end cevalBuiltinSign;

protected function cevalBuiltinExp "function: cevalBuiltinExp
  author: PA
  Evaluates the exp function"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env,exp,impl,st,msg);
        rv_1 = realExp(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end match;
end cevalBuiltinExp;

protected function cevalBuiltinNoevent "function: cevalBuiltinNoevent
  author: PA
  Evaluates the noEvent operator. During constant evaluation events are not
  considered, so evaluation will simply remove the operator and evaluate the
  operand."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Values.Value v;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,v,_) = ceval(cache,env,exp,impl,st,msg);
      then
        (cache,v,st);
  end match;
end cevalBuiltinNoevent;

protected function cevalBuiltinCardinality "function: cevalBuiltinCardinality
  author: PA
  Evaluates the cardinality operator. The cardinality of a connector
  instance is its number of (inside and outside) connections, i.e.
  number of occurences in connect equations."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Integer cnt;
      list<Env.Frame> env;
      DAE.ComponentRef cr;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{DAE.CREF(componentRef = cr)},impl,st,msg)
      equation
        (cache,cnt) = cevalCardinality(cache,env, cr);
      then
        (cache,Values.INTEGER(cnt),st);
  end match;
end cevalBuiltinCardinality;

protected function cevalCardinality "function: cevalCardinality
  author: PA
  counts the number of connect occurences of the
  component ref in equations in current scope."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.ComponentRef inComponentRef;
  output Env.Cache outCache;
  output Integer outInteger;
algorithm
  (outCache,outInteger) :=
  match (inCache,inEnv,inComponentRef)
    local
      Env.Env env;
      list<DAE.ComponentRef> cr_lst,cr_lst2,cr_totlst,crs;
      Integer res;
      DAE.ComponentRef cr;
      Env.Cache cache;
      DAE.ComponentRef prefix,currentPrefix;
      Absyn.Ident currentPrefixIdent;
    case (cache,env ,cr)
      equation
        (env as (Env.FRAME(connectionSet = (crs,prefix))::_)) = Env.stripForLoopScope(env);
        cr_lst = Util.listSelect1(crs, cr, ComponentReference.crefContainedIn);
        currentPrefixIdent= ComponentReference.crefLastIdent(prefix);
        currentPrefix = ComponentReference.makeCrefIdent(currentPrefixIdent,DAE.ET_OTHER(),{});
         //  Select connect references that has cr as suffix and correct Prefix.
        cr_lst = Util.listSelect1R(cr_lst, currentPrefix, ComponentReference.crefPrefixOf);

        // Select connect references that are identifiers (inside connectors)
        cr_lst2 = Util.listSelect(crs,ComponentReference.crefIsIdent);
        cr_lst2 = Util.listSelect1(cr_lst2,cr,ComponentReference.crefEqual);

        cr_totlst = Util.listUnionOnTrue(listAppend(cr_lst,cr_lst2),{},ComponentReference.crefEqual);
        res = listLength(cr_totlst);

        /*print("inFrame :");print(Env.printEnvPathStr(env));print("\n");
        print("cardinality(");print(ComponentReference.printComponentRefStr(cr));print(")=");print(intString(res));
        print("\nicrefs =");print(Util.stringDelimitList(Util.listMap(crs,ComponentReference.printComponentRefStr),","));
        print("\ncrefs =");print(Util.stringDelimitList(Util.listMap(cr_totlst,ComponentReference.printComponentRefStr),","));
        print("\n");
         print("prefix =");print(ComponentReference.printComponentRefStr(prefix));print("\n");*/
       //  print("env:");print(Env.printEnvStr(env));
      then
        (cache,res);
  end match;
end cevalCardinality;

protected function cevalBuiltinCat "function: cevalBuiltinCat
  author: PA
  Evaluates the cat operator, for matrix concatenation."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Integer dim_int;
      list<Values.Value> mat_lst;
      Values.Value v;
      list<Env.Frame> env;
      DAE.Exp dim;
      list<DAE.Exp> matrices;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
    
    case (cache,env,(dim :: matrices),impl,st,msg)
      equation
        (cache,Values.INTEGER(dim_int),_) = ceval(cache,env,dim,impl,st,msg);
        (cache,mat_lst,st) = cevalList(cache,env, matrices, impl, st, msg);
        v = cevalCat(mat_lst, dim_int);
      then
        (cache,v,st);
  end match;
end cevalBuiltinCat;

protected function cevalBuiltinIdentity "function: cevalBuiltinIdentity
  author: PA
  Evaluates the identity operator."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Integer dim_int,dim_int_1;
      list<DAE.Exp> expl;
      list<Values.Value> retExp;
      list<Env.Frame> env;
      DAE.Exp dim;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
       Env.Cache cache;
    
    case (cache,env,{dim},impl,st,msg)
      equation
        (cache,Values.INTEGER(dim_int),_) = ceval(cache,env,dim,impl,st,msg);
        dim_int_1 = dim_int + 1;
        expl = Util.listFill(DAE.ICONST(1), dim_int);
        (cache,retExp) = cevalBuiltinDiagonal2(cache,env, DAE.ARRAY(DAE.ET_INT(),true,expl), impl, st, dim_int_1,
          1, {}, msg);
      then
        (cache,ValuesUtil.makeArray(retExp),st);
  end match;
end cevalBuiltinIdentity;

protected function cevalBuiltinPromote "function: cevalBuiltinPromote
  author: PA
  Evaluates the internal promote operator, for promotion of arrays"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Values.Value arr_val,res;
      Integer dim_val;
      list<Env.Frame> env;
      DAE.Exp arr,dim;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
    
    case (cache,env,{arr,dim},impl,st,msg)
      equation
        (cache,arr_val,_) = ceval(cache,env, arr, impl, st, msg);
        (cache,Values.INTEGER(dim_val),_) = ceval(cache,env, dim, impl, st, msg);
        res = cevalBuiltinPromote2(arr_val, dim_val);
      then
        (cache,res,st);
  end match;
end cevalBuiltinPromote;

protected function cevalBuiltinPromote2 "function: cevalBuiltinPromote2
  Helper function to cevalBuiltinPromote"
  input Values.Value inValue;
  input Integer inInteger;
  output Values.Value outValue;
algorithm
  outValue:=
  matchcontinue (inValue,inInteger)
    local
      Values.Value v;
      Integer n_1,n,i;
      list<Values.Value> vs_1,vs;
      list<Integer> il;
    case (v,0) then Values.ARRAY({v},{1});
    case (Values.ARRAY(valueLst = vs, dimLst = i::_),n)
      equation
        n_1 = n - 1;
        (vs_1 as (Values.ARRAY(dimLst = il)::_)) = Util.listMap1(vs, cevalBuiltinPromote2, n_1);
      then
        Values.ARRAY(vs_1,i::il);
    case (_,_)
      equation
        Debug.fprintln("failtrace", "- Ceval.cevalBuiltinPromote2 failed");
      then fail();
  end matchcontinue;
end cevalBuiltinPromote2;

protected function cevalBuiltinSubstring "
  author: PA
  Evaluates the String operator String(r), String(i), String(b), String(e).
  TODO: Also evaluate String(r, significantDigits=d), and String(r, format=s)."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      DAE.Exp str_exp, start_exp, stop_exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      String str;
      Integer start, stop;
    
    case (cache,env,{str_exp, start_exp, stop_exp},impl,st,msg)
      equation
        (cache,Values.STRING(str),_) = ceval(cache,env, str_exp, impl, st, msg);
        (cache,Values.INTEGER(start),_) = ceval(cache,env, start_exp, impl, st, msg);
        (cache,Values.INTEGER(stop),_) = ceval(cache,env, stop_exp, impl, st, msg);
        str = System.substring(str, start, stop);
      then
        (cache,Values.STRING(str),st);
  end match;
end cevalBuiltinSubstring;

protected function cevalBuiltinString "
  author: PA
  Evaluates the String operator String(r), String(i), String(b), String(e).
  TODO: Also evaluate String(r, significantDigits=d), and String(r, format=s)."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      DAE.Exp exp, len_exp, justified_exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      String str;
      Integer i; Real r; Boolean b;
      Absyn.Path p;
    
    case (cache,env,{exp, len_exp, justified_exp},impl,st,msg)
      equation
        (cache,Values.INTEGER(i),_) = ceval(cache,env, exp, impl, st,msg);
        str = intString(i);
        (cache, str) = cevalBuiltinStringFormat(cache, env, str, len_exp, justified_exp, impl, st, msg);
      then
        (cache,Values.STRING(str),st);
    
    case (cache,env,{exp, len_exp, justified_exp, _},impl,st,msg)
      equation
        (cache,Values.REAL(r),_) = ceval(cache,env, exp, impl, st,msg);
        str = realString(r);
        (cache, str) = cevalBuiltinStringFormat(cache, env, str, len_exp, justified_exp, impl, st, msg);
      then
        (cache,Values.STRING(str),st);
    
    case (cache,env,{exp, len_exp, justified_exp},impl,st,msg)
      equation
        (cache,Values.BOOL(b),_) = ceval(cache,env, exp, impl, st,msg);
        str = boolString(b);
        (cache, str) = cevalBuiltinStringFormat(cache, env, str, len_exp, justified_exp, impl, st, msg);
      then
        (cache,Values.STRING(str),st);
    
    case (cache,env,{exp, len_exp, justified_exp},impl,st,msg)
      equation
        (cache,Values.ENUM_LITERAL(name = p),_) = ceval(cache,env, exp, impl, st,msg);
        str = Absyn.pathLastIdent(p);
        (cache, str) = cevalBuiltinStringFormat(cache, env, str, len_exp, justified_exp, impl, st, msg);
      then
        (cache,Values.STRING(str),st);
    
  end matchcontinue;
end cevalBuiltinString;

protected function cevalBuiltinStringFormat
  "This function formats a string by using the minimumLength and leftJustified
  arguments to the String function."  
  input Env.Cache inCache;
  input Env.Env inEnv;
  input String inString;
  input DAE.Exp lengthExp;
  input DAE.Exp justifiedExp;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inST;
  input Msg inMsg;
  output Env.Cache outCache;
  output String outString;
algorithm
  (outCache, outString) := match(inCache, inEnv, inString, lengthExp,
      justifiedExp, inBoolean, inST, inMsg)
    local
      Env.Cache cache;
      Integer min_length;
      Boolean left_justified;
      String str;
    case (cache, _, _, _, _, _, _, _)
      equation
        (cache, Values.INTEGER(integer = min_length), _) = 
          ceval(cache, inEnv, lengthExp, inBoolean, inST,inMsg);
        (cache, Values.BOOL(boolean = left_justified), _) = 
          ceval(cache, inEnv, justifiedExp, inBoolean, inST,inMsg);
        str = ExpressionSimplify.cevalBuiltinStringFormat(inString, stringLength(inString), min_length, left_justified);
      then
        (cache, str);
  end match;
end cevalBuiltinStringFormat;

protected function cevalBuiltinLinspace "
  author: PA
  Evaluates the linpace function"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> st;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outST;
algorithm
  (outCache,outValue,outST):=
  match (inCache,inEnv,inExpExpLst,inBoolean,st,inMsg)
      local
        DAE.Exp x,y,n; Integer size;
        Real rx,ry; list<Values.Value> valLst; Env.Cache cache; Boolean impl; Env.Env env; Msg msg;
    case (cache,env,{x,y,n},impl,st,msg) equation
      (cache,Values.INTEGER(size),_) = ceval(cache,env, n, impl, st,msg);
      verifyLinspaceN(size,{x,y,n});
      (cache,Values.REAL(rx),_) = ceval(cache,env, x, impl, st,msg);
      (cache,Values.REAL(ry),_) = ceval(cache,env, y, impl, st,msg);
      valLst = cevalBuiltinLinspace2(rx,ry,size,1);
    then (cache,ValuesUtil.makeArray(valLst),st);

  end match;
end cevalBuiltinLinspace;

protected function verifyLinspaceN "checks that n>=2 for linspace(x,y,n) "
  input Integer n;
  input list<DAE.Exp> expl;
algorithm
  _ := matchcontinue(n,expl)
  local String s; DAE.Exp x,y,nx;
    case(n,_) equation
      true = n >= 2;
    then ();
    case(_,{x,y,nx})
      equation
        s = "linspace("+&ExpressionDump.printExpStr(x)+&", "+&ExpressionDump.printExpStr(y)+&", "+&ExpressionDump.printExpStr(nx)+&")";
        Error.addMessage(Error.LINSPACE_ILLEGAL_SIZE_ARG,{s});
      then fail();
  end matchcontinue;
end verifyLinspaceN;

protected function cevalBuiltinLinspace2 "Helper function to cevalBuiltinLinspace"
  input Real rx;
  input Real ry;
  input Integer size;
  input Integer i "iterator 1 <= i <= size";
  output list<Values.Value> valLst;
algorithm
  valLst := matchcontinue(rx,ry,size,i)
  local Real r;
    case(rx,ry,size,i) equation
      true = i > size;
    then {};
    case(rx,ry,size,i) equation
      r = rx +. (ry -. rx)*. intReal(i-1) /. intReal(size - 1);
      valLst = cevalBuiltinLinspace2(rx,ry,size,i+1);
    then Values.REAL(r)::valLst;
  end matchcontinue;
end cevalBuiltinLinspace2;

protected function cevalBuiltinPrint "
  author: sjoelund
  Prints a String"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      String str;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.STRING(str),st) = ceval(cache,env, exp, impl, st,msg);
        print(str);
      then
        (cache,Values.NORETCALL(),st);
  end match;
end cevalBuiltinPrint;

protected function cevalIntReal
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      Integer i;
      Real r;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.INTEGER(i),_) = ceval(cache,env, exp, impl, st,msg);
        r = intReal(i);
      then
        (cache,Values.REAL(r),st);
  end match;
end cevalIntReal;

protected function cevalIntString
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      String str;
      Integer i;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.INTEGER(i),st) = ceval(cache,env, exp, impl, st,msg);
        str = intString(i);
      then
        (cache,Values.STRING(str),st);
  end match;
end cevalIntString;

protected function cevalRealInt
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      Integer i;
      Real r;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.REAL(r),st) = ceval(cache,env, exp, impl, st,msg);
        i = realInt(r);
      then
        (cache,Values.INTEGER(i),st);
  end match;
end cevalRealInt;

protected function cevalRealString
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      String str;
      Real r;
      Values.Value v;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,v,st) = ceval(cache,env, exp, impl, st, msg);
        Values.REAL(r) = v;
        str = realString(r);
      then
        (cache,Values.STRING(str),st);
  end match;
end cevalRealString;

protected function cevalStringCharInt
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      String str;
      Integer i;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.STRING(str),_) = ceval(cache,env, exp, impl, st,msg);
        i = stringCharInt(str);
      then
        (cache,Values.INTEGER(i),st);
  end match;
end cevalStringCharInt;

protected function cevalIntStringChar
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      String str;
      Integer i;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.INTEGER(i),st) = ceval(cache,env, exp, impl, st,msg);
        str = intStringChar(i);
      then
        (cache,Values.STRING(str),st);
  end match;
end cevalIntStringChar;

protected function cevalStringInt
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      String str;
      Integer i;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.STRING(str),st) = ceval(cache,env, exp, impl, st,msg);
        i = stringInt(str);
      then
        (cache,Values.INTEGER(i),st);
  end match;
end cevalStringInt;


protected function cevalStringLength
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      String str;
      Integer i;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.STRING(str),st) = ceval(cache,env, exp, impl, st,msg);
        i = stringLength(str);
      then
        (cache,Values.INTEGER(i),st);
  end match;
end cevalStringLength;

protected function cevalStringReal
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      String str;
      Integer i;
      Real r;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.STRING(str),st) = ceval(cache,env, exp, impl, st,msg);
        print("stringReal?");
        // TODO: FIXME: When bootstrapping is done
        // r = stringReal(str);
      then fail();
        // (cache,Values.REAL(r),st);
  end match;
end cevalStringReal;

protected function cevalStringListStringChar
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      String str;
      list<String> chList;
      list<Values.Value> valList;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.STRING(str),st) = ceval(cache,env, exp, impl, st,msg);
        chList = stringListStringChar(str);
        valList = Util.listMap(chList, generateValueString);
      then
        (cache,Values.LIST(valList),st);
  end match;
end cevalStringListStringChar;

protected function generateValueString
  input String str;
  output Values.Value val;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  val := Values.STRING(str);
end generateValueString;

protected function cevalListStringCharString
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      String str;
      list<String> chList;
      list<Values.Value> valList;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.LIST(valList),st) = ceval(cache,env, exp, impl,st,msg);
        // Note that the RML version of the function has a weird name, but is also not implemented yet!
        // The work-around is to check that each String has length 1 and append all the Strings together
        // WARNING: This can be very, very slow for long lists - it grows as O(n^2)
        // TODO: When implemented, use listStringCharString (OMC name) or stringCharListString (RML name) directly
        chList = Util.listMap(valList, extractValueStringChar);
        str = stringAppendList(chList);
      then
        (cache,Values.STRING(str),st);
  end match;
end cevalListStringCharString;

protected function cevalStringAppendList
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      String str;
      list<String> chList;
      list<Values.Value> valList;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.LIST(valList),st) = ceval(cache,env, exp, impl, st,msg);
        chList = Util.listMap(valList, ValuesUtil.extractValueString);
        str = stringAppendList(chList);
      then
        (cache,Values.STRING(str),st);
  end match;
end cevalStringAppendList;

protected function cevalListLength
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      Integer i;
      list<Values.Value> valList;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.LIST(valList),st) = ceval(cache,env, exp, impl, st, msg);
        i = listLength(valList);
      then
        (cache,Values.INTEGER(i),st);
  end match;
end cevalListLength;

protected function cevalListAppend
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      DAE.Exp exp1,exp2;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      list<Values.Value> valList,valList1,valList2;
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation
        (cache,Values.LIST(valList1),st) = ceval(cache,env, exp1, impl, st,msg);
        (cache,Values.LIST(valList2),st) = ceval(cache,env, exp2, impl, st,msg);
        valList = listAppend(valList1, valList2);
      then
        (cache,Values.LIST(valList),st);
  end match;
end cevalListAppend;

protected function cevalListReverse
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      DAE.Exp exp1;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      list<Values.Value> valList,valList1;
    case (cache,env,{exp1},impl,st,msg)
      equation
        (cache,Values.LIST(valList1),st) = ceval(cache,env, exp1, impl, st,msg);
        valList = listReverse(valList1);
      then
        (cache,Values.LIST(valList),st);
  end match;
end cevalListReverse;

protected function cevalListRest
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      DAE.Exp exp1;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      list<Values.Value> valList1;
    case (cache,env,{exp1},impl,st,msg)
      equation
        (cache,Values.LIST(_::valList1),st) = ceval(cache,env, exp1, impl, st,msg);
      then
        (cache,Values.LIST(valList1),st);
  end match;
end cevalListRest;

protected function cevalAnyString
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      DAE.Exp exp1;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      Values.Value v;
      String s;
    case (cache,env,{exp1},impl,st,msg)
      equation
        (cache,v,st) = ceval(cache,env, exp1, impl, st,msg);
        s = ValuesUtil.valString(v);
      then
        (cache,Values.STRING(s),st);
  end match;
end cevalAnyString;

protected function cevalListFirst
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      DAE.Exp exp1;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      Values.Value v;
    case (cache,env,{exp1},impl,st,msg)
      equation
        (cache,Values.LIST(v::_),st) = ceval(cache,env, exp1, impl, st,msg);
      then
        (cache,ValuesUtil.boxIfUnboxedVal(v),st);
  end match;
end cevalListFirst;

protected function extractValueStringChar
  input Values.Value val;
  output String str;
algorithm
  str := match (val)
    case Values.STRING(str) equation 1 = stringLength(str); then str;
  end match;
end extractValueStringChar;

protected function cevalCat "function: cevalCat
  evaluates the cat operator given a list of
  array values and a concatenation dimension."
  input list<Values.Value> v_lst;
  input Integer dim;
  output Values.Value outValue;
protected
  list<Values.Value> v_lst_1;
algorithm
  v_lst_1 := catDimension(v_lst, dim);
  outValue := ValuesUtil.makeArray(v_lst_1);
end cevalCat;

protected function catDimension "function: catDimension
  Helper function to cevalCat, concatenates a list
  arrays as Values, given a dimension as integer."
  input list<Values.Value> inValuesValueLst;
  input Integer inInteger;
  output list<Values.Value> outValuesValueLst;
algorithm
  outValuesValueLst:=
  matchcontinue (inValuesValueLst,inInteger)
    local
      list<list<Values.Value>> vlst_lst,v_lst_lst,v_lst_lst_1;
      list<Values.Value> v_lst_1,vlst,vlst2;
      Integer dim_1,dim,i1,i2;
      list<Integer> il;
    case (vlst,1) /* base case for first dimension */
      equation
        vlst_lst = Util.listMap(vlst, ValuesUtil.arrayValues);
        v_lst_1 = Util.listFlatten(vlst_lst);
      then
        v_lst_1;
    case (vlst,dim)
      equation
        v_lst_lst = Util.listMap(vlst, ValuesUtil.arrayValues);
        dim_1 = dim - 1;
        v_lst_lst_1 = catDimension2(v_lst_lst, dim_1);
        v_lst_1 = Util.listMap(v_lst_lst_1, ValuesUtil.makeArray);
        (Values.ARRAY(valueLst = vlst2, dimLst = i2::il) :: _) = v_lst_1;
        i1 = listLength(v_lst_1);
        v_lst_1 = cevalBuiltinTranspose2(v_lst_1, 1, i2::i1::il);
      then
        v_lst_1;
  end matchcontinue;
end catDimension;

protected function catDimension2 "function: catDimension2
  author: PA
  Helper function to catDimension."
  input list<list<Values.Value>> inValuesValueLstLst;
  input Integer inInteger;
  output list<list<Values.Value>> outValuesValueLstLst;
algorithm
  outValuesValueLstLst:=
  matchcontinue (inValuesValueLstLst,inInteger)
    local
      list<Values.Value> l_lst,first_lst,first_lst_1;
      list<list<Values.Value>> first_lst_2,lst,rest,rest_1,res;
      Integer dim;
    case (lst,dim)
      equation
        l_lst = Util.listFirst(lst);
        1 = listLength(l_lst);
        first_lst = Util.listMap(lst, Util.listFirst);
        first_lst_1 = catDimension(first_lst, dim);
        first_lst_2 = Util.listMap(first_lst_1, Util.listCreate);
      then
        first_lst_2;
    case (lst,dim)
      equation
        first_lst = Util.listMap(lst, Util.listFirst);
        rest = Util.listMap(lst, Util.listRest);
        first_lst_1 = catDimension(first_lst, dim);
        rest_1 = catDimension2(rest, dim);
        res = Util.listThreadMap(rest_1, first_lst_1, Util.listCons);
      then
        res;
  end matchcontinue;
end catDimension2;

protected function cevalBuiltinFloor "function: cevalBuiltinFloor
  author: LP
  evaluates the floor operator."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg);
        rv_1 = realFloor(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end match;
end cevalBuiltinFloor;

protected function cevalBuiltinCeil "function cevalBuiltinCeil
  author: LP
  evaluates the ceil operator."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1,rvt,realRet;
      Integer ri,ri_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg);
        rv_1 = realFloor(rv);
        ri = realInt(rv_1);
        rvt = intReal(ri);
        (rvt ==. rv) = true;
      then
        (cache,Values.REAL(rvt),st);
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg);
        rv_1 = realFloor(rv);
        ri = realInt(rv_1);
        ri_1 = ri + 1;
        realRet = intReal(ri_1);
      then
        (cache,Values.REAL(realRet),st);
  end matchcontinue;
end cevalBuiltinCeil;

protected function cevalBuiltinSqrt "function: cevalBuiltinSqrt
  author: LP
  Evaluates the builtin sqrt operator."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg);
        (rv <. 0.0) = true;
        Error.addMessage(Error.NEGATIVE_SQRT, {});
      then
        fail();
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg);
        rv_1 = realSqrt(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end matchcontinue;
end cevalBuiltinSqrt;

protected function cevalBuiltinSin "function cevalBuiltinSin
  author: LP
  Evaluates the builtin sin function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg);
        rv_1 = realSin(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end match;
end cevalBuiltinSin;

protected function cevalBuiltinSinh "function cevalBuiltinSinh
  author: PA
  Evaluates the builtin sinh function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg);
        rv_1 = realSinh(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end match;
end cevalBuiltinSinh;

protected function cevalBuiltinCos "function cevalBuiltinCos
  author: LP
  Evaluates the builtin cos function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg);
        rv_1 = realCos(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end match;
end cevalBuiltinCos;

protected function cevalBuiltinCosh "function cevalBuiltinCosh
  author: PA
  Evaluates the builtin cosh function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg);
        rv_1 = realCosh(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end match;
end cevalBuiltinCosh;

protected function cevalBuiltinLog "function cevalBuiltinLog
  author: LP
  Evaluates the builtin Log function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg);
        rv_1 = realLn(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end match;
end cevalBuiltinLog;

protected function cevalBuiltinLog10
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg);
        rv_1 = realLog10(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end match;
end cevalBuiltinLog10;

protected function cevalBuiltinTan "function cevalBuiltinTan
  author: LP
  Evaluates the builtin tan function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,sv,cv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg) /* tan is not implemented in MetaModelica Compiler (MMC) for some strange reason. */
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg);
        sv = realSin(rv);
        cv = realCos(rv);
        rv_1 = sv /. cv;
      then
        (cache,Values.REAL(rv_1),st);
  end match;
end cevalBuiltinTan;

protected function cevalBuiltinTanh "function cevalBuiltinTanh
  author: PA
  Evaluates the builtin tanh function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg) /* tanh is not implemented in MetaModelica Compiler (MMC) for some strange reason. */
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg);
         rv_1 = realTanh(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end match;
end cevalBuiltinTanh;

protected function cevalBuiltinAsin "function cevalBuiltinAsin
  author: PA
  Evaluates the builtin asin function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st, msg);
        rv_1 = realAsin(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end match;
end cevalBuiltinAsin;

protected function cevalBuiltinAcos "function cevalBuiltinAcos
  author: PA
  Evaluates the builtin acos function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st, msg);
        rv_1 = realAcos(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end match;
end cevalBuiltinAcos;

protected function cevalBuiltinAtan "function cevalBuiltinAtan
  author: PA
  Evaluates the builtin atan function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg) /* atan is not implemented in MetaModelica Compiler (MMC) for some strange reason. */
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st, msg);
        rv_1 = realAtan(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end match;
end cevalBuiltinAtan;

protected function cevalBuiltinAtan2
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1,rv_2;
      list<Env.Frame> env;
      DAE.Exp exp1,exp2;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation
        (cache,Values.REAL(rv_1),_) = ceval(cache,env, exp1, impl, st, msg);
        (cache,Values.REAL(rv_2),_) = ceval(cache,env, exp2, impl, st, msg);
        rv = realAtan2(rv_1,rv_2);
      then
        (cache,Values.REAL(rv),st);
  end match;
end cevalBuiltinAtan2;

protected function cevalBuiltinDiv "function cevalBuiltinDiv
  author: LP
  Evaluates the builtin div operator."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv1,rv2,rv_1,rv_2;
      Integer ri,ri_1,ri1,ri2;
      list<Env.Frame> env;
      DAE.Exp exp1,exp2;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      String exp1_str,exp2_str,lh_str,rh_str;
      Env.Cache cache; Boolean b;
      Absyn.Info info;

    case (cache,env,{exp1,exp2},impl,st,msg)
      equation
        (cache,Values.REAL(rv1),_) = ceval(cache,env, exp1, impl, st, msg);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, msg);
        rv_1 = rv1/. rv2;
        b = rv_1 <. 0.0;
        rv_2 = Util.if_(b,realCeil(rv_1),realFloor(rv_1));
      then
        (cache,Values.REAL(rv_2),st);
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation
        (cache,Values.INTEGER(ri),_) = ceval(cache,env, exp1, impl, st, msg);
        rv1 = intReal(ri);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, msg);
        rv_1 = rv1/. rv2;
         b = rv_1 <. 0.0;
        rv_2 = Util.if_(b,realCeil(rv_1),realFloor(rv_1));
      then
        (cache,Values.REAL(rv_2),st);
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation
        (cache,Values.REAL(rv1),_) = ceval(cache,env, exp1, impl, st, msg);
        (cache,Values.INTEGER(ri),_) = ceval(cache,env, exp2, impl, st, msg);
        rv2 = intReal(ri);
        rv_1 = rv1/. rv2;
        b = rv_1 <. 0.0;
        rv_2 = Util.if_(b,realCeil(rv_1),realFloor(rv_1));
      then
        (cache,Values.REAL(rv_2),st);
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation
        (cache,Values.INTEGER(ri1),_) = ceval(cache,env, exp1, impl, st, msg);
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st, msg);
        ri_1 = intDiv(ri1,ri2);
      then
        (cache,Values.INTEGER(ri_1),st);
    case (cache,env,{exp1,exp2},impl,st,MSG(info = info))
      equation
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, inMsg);
        (rv2 ==. 0.0) = true;
        exp1_str = ExpressionDump.printExpStr(exp1);
        exp2_str = ExpressionDump.printExpStr(exp2);
        Error.addSourceMessage(Error.DIVISION_BY_ZERO, {exp1_str,exp2_str}, info);
      then
        fail();
    case (cache,env,{exp1,exp2},impl,st,NO_MSG())
      equation
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, NO_MSG());
        (rv2 ==. 0.0) = true;
      then
        fail();
    case (cache,env,{exp1,exp2},impl,st,MSG(info = info))
      equation
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st, inMsg);
        (ri2 == 0) = true;
        lh_str = ExpressionDump.printExpStr(exp1);
        rh_str = ExpressionDump.printExpStr(exp2);
        Error.addMessage(Error.DIVISION_BY_ZERO, {lh_str,rh_str});
      then
        fail();
    case (cache,env,{exp1,exp2},impl,st,NO_MSG())
      equation
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st, NO_MSG());
        (ri2 == 0) = true;
      then
        fail();
  end matchcontinue;
end cevalBuiltinDiv;

protected function cevalBuiltinMod "function cevalBuiltinMod
  author: LP
  Evaluates the builtin mod operator."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv1,rv2,rva,rvb,rvc,rvd;
      list<Env.Frame> env;
      DAE.Exp exp1,exp2;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Integer ri,ri1,ri2,ri_1;
      String lhs_str,rhs_str;
      Env.Cache cache;
      Absyn.Info info;

    case (cache,env,{exp1,exp2},impl,st,msg)
      equation
        (cache,Values.REAL(rv1),_) = ceval(cache,env, exp1, impl, st, msg);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, msg);
        rva = rv1/. rv2;
        rvb = realFloor(rva);
        rvc = rvb*. rv2;
        rvd = rv1 -. rvc;
      then
        (cache,Values.REAL(rvd),st);
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation
        (cache,Values.INTEGER(ri),_) = ceval(cache,env, exp1, impl, st, msg);
        rv1 = intReal(ri);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, msg);
        rva = rv1 /. rv2;
        rvb = realFloor(rva);
        rvc = rvb *. rv2;
        rvd = rv1 -. rvc;
      then
        (cache,Values.REAL(rvd),st);
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation
        (cache,Values.REAL(rv1),_) = ceval(cache,env, exp1, impl, st, msg);
        (cache,Values.INTEGER(ri),_) = ceval(cache,env, exp2, impl, st, msg);
        rv2 = intReal(ri);
        rva = rv1 /. rv2;
        rvb = realFloor(rva);
        rvc = rvb *. rv2;
        rvd = rv1 -. rvc;
      then
        (cache,Values.REAL(rvd),st);
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation
        (cache,Values.INTEGER(ri1),_) = ceval(cache,env, exp1, impl, st, msg);
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st, msg);
        rv1 = intReal(ri1);
        rv2 = intReal(ri2);
        rva = rv1 /. rv2;
        rvb = realFloor(rva);
        rvc = rvb *. rv2;
        rvd = rv1 -. rvc;
        ri_1 = realInt(rvd);
      then
        (cache,Values.INTEGER(ri_1),st);
    case (cache,env,{exp1,exp2},impl,st,MSG(info = info))
      equation
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, inMsg);
        (rv2 ==. 0.0) = true;
        lhs_str = ExpressionDump.printExpStr(exp1);
        rhs_str = ExpressionDump.printExpStr(exp2);
        Error.addSourceMessage(Error.MODULO_BY_ZERO, {lhs_str,rhs_str}, info);
      then
        fail();
    case (cache,env,{exp1,exp2},impl,st,NO_MSG())
      equation
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, NO_MSG());
        (rv2 ==. 0.0) = true;
      then
        fail();
    case (cache,env,{exp1,exp2},impl,st,MSG(info = info))
      equation
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st, inMsg);
        (ri2 == 0) = true;
        lhs_str = ExpressionDump.printExpStr(exp1);
        rhs_str = ExpressionDump.printExpStr(exp2);
        Error.addSourceMessage(Error.MODULO_BY_ZERO, {lhs_str,rhs_str}, info);
      then
        fail();
    case (cache,env,{exp1,exp2},impl,st,NO_MSG())
      equation
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st, NO_MSG());
        (ri2 == 0) = true;
      then
        fail();
  end matchcontinue;
end cevalBuiltinMod;

protected function cevalBuiltinMax "function cevalBuiltinMax
  author: LP
  Evaluates the builtin max function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Values.Value v,v1,v2,v_1;
      list<Env.Frame> env;
      DAE.Exp arr,s1,s2;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Integer i1,i2,i;
      Real r1,r2,r;
      Env.Cache cache;
    case (cache,env,{arr},impl,st,msg)
      equation
        (cache,v,_) = ceval(cache,env, arr, impl, st, msg);
        (v_1) = cevalBuiltinMaxArr(v);
      then
        (cache,v_1,st);
    case (cache,env,{s1,s2},impl,st,msg)
      equation
        (cache,v1,_) = ceval(cache,env, s1, impl, st, msg);
        (cache,v2,_) = ceval(cache,env, s2, impl, st, msg);
        v = cevalBuiltinMax2(v1,v2);
      then
        (cache,v,st);
  end matchcontinue;
end cevalBuiltinMax;

protected function cevalBuiltinMax2
  input Values.Value v1;
  input Values.Value v2;
  output Values.Value outValue;
algorithm
  outValue := match (v1,v2)
    local
      Integer i1,i2,i;
      Real r1,r2,r;
      Boolean b1,b2,b;
      String s1,s2,s;
    case (Values.INTEGER(i1),Values.INTEGER(i2))
      equation
        i = intMax(i1, i2);
      then Values.INTEGER(i);
    case (Values.REAL(r1),Values.REAL(r2))
      equation
        r = realMax(r1, r2);
      then Values.REAL(r);
    case (Values.BOOL(b1),Values.BOOL(b2))
      equation
        b = boolOr(b1, b2);
      then Values.BOOL(b);
  end match;
end cevalBuiltinMax2;

protected function cevalBuiltinMaxArr "function: cevalBuiltinMax2
  Helper function to cevalBuiltinMax."
  input Values.Value inValue;
  output Values.Value outValue;
algorithm
  outValue := matchcontinue (inValue)
    local
      Integer i1,i2,resI,i;
      Real r,r1,r2,resR;
      Values.Value v1,v,vl;
      list<Values.Value> vls;
    
    case (Values.INTEGER(integer = i)) then Values.INTEGER(i);
    
    case (Values.REAL(real = r)) then Values.REAL(r);
    
    case (Values.ARRAY(valueLst = (v1 :: (vls as (_ :: _)))))
      equation
        (Values.INTEGER(i1)) = cevalBuiltinMaxArr(v1);
        (Values.INTEGER(i2)) = cevalBuiltinMaxArr(ValuesUtil.makeArray(vls));
        resI = intMax(i1, i2);
      then
        Values.INTEGER(resI);
    
    case (Values.ARRAY(valueLst = (v1 :: (vls as (_ :: _)))))
      equation
        (Values.REAL(r1)) = cevalBuiltinMaxArr(v1);
        (Values.REAL(r2)) = cevalBuiltinMaxArr(ValuesUtil.makeArray(vls));
        resR = realMax(r1, r2);
      then
        Values.REAL(resR);
    
    case (Values.ARRAY(valueLst = {vl}))
      equation
        (v) = cevalBuiltinMaxArr(vl);
      then
        v;
    
    case (_)
      equation
        //print("- Ceval.cevalBuiltinMax2 failed\n");
      then
        fail();
  end matchcontinue;
end cevalBuiltinMaxArr;

protected function cevalBuiltinMin "function: cevalBuiltinMin
  author: PA
  Constant evaluation of builtin min function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Values.Value v,v1,v2,v_1;
      list<Env.Frame> env;
      DAE.Exp arr,s1,s2;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Integer i1,i2,i;
      Real r1,r2,r;
      Env.Cache cache;
    case (cache,env,{arr},impl,st,msg)
      equation
        (cache,v,_) = ceval(cache,env, arr, impl, st,msg);
        (v_1) = cevalBuiltinMinArr(v);
      then
        (cache,v_1,st);
    case (cache,env,{s1,s2},impl,st,msg)
      equation
        (cache,v1,_) = ceval(cache,env, s1, impl, st,msg);
        (cache,v2,_) = ceval(cache,env, s2, impl, st,msg);
        v = cevalBuiltinMin2(v1,v2);
      then
        (cache,v,st);
  end matchcontinue;
end cevalBuiltinMin;

protected function cevalBuiltinMin2
  input Values.Value v1;
  input Values.Value v2;
  output Values.Value outValue;
algorithm
  outValue := match (v1,v2)
    local
      Integer i1,i2,i;
      Real r1,r2,r;
      Boolean b1,b2,b;
      String s1,s2,s;
    case (Values.INTEGER(i1),Values.INTEGER(i2))
      equation
        i = intMin(i1, i2);
      then Values.INTEGER(i);
    case (Values.REAL(r1),Values.REAL(r2))
      equation
        r = realMin(r1, r2);
      then Values.REAL(r);
    case (Values.BOOL(b1),Values.BOOL(b2))
      equation
        b = boolAnd(b1, b2);
      then Values.BOOL(b);
    else
      equation
        s1 = ValuesUtil.valString(v1);
        s2 = ValuesUtil.valString(v2);
        s = stringAppendList({"cevalBuiltinMin2 failed: min(", s1, ", ", s2, ")"});
        Error.addMessage(Error.INTERNAL_ERROR, {s});
      then fail();
  end match;
end cevalBuiltinMin2;

protected function cevalBuiltinMinArr "function: cevalBuiltinMinArr
  Helper function to cevalBuiltinMin."
  input Values.Value inValue;
  output Values.Value outValue;
algorithm
  outValue := matchcontinue (inValue)
    local
      Integer i1,i2,resI,i;
      Values.Value v1,v,vl;
      list<Values.Value> vls;
      Real r,r1,r2,resR;
    
    case (Values.INTEGER(integer = i)) then Values.INTEGER(i);
    case (Values.REAL(real = r)) then Values.REAL(r);
    
    case (Values.ARRAY(valueLst = (v1 :: (vls as (_ :: _)))))
      equation
        (Values.INTEGER(i1)) = cevalBuiltinMinArr(v1);
        (Values.INTEGER(i2)) = cevalBuiltinMinArr(ValuesUtil.makeArray(vls));
        resI = intMin(i1, i2);
      then
        Values.INTEGER(resI);
    
    case (Values.ARRAY(valueLst = (v1 :: (vls as (_ :: _)))))
      equation
        (Values.REAL(r1)) = cevalBuiltinMinArr(v1);
        (Values.REAL(r2)) = cevalBuiltinMinArr(ValuesUtil.makeArray(vls));
        resR = realMin(r1, r2);
      then
        Values.REAL(resR);
    
    case (Values.ARRAY(valueLst = {vl}))
      equation
        (v) = cevalBuiltinMinArr(vl);
      then
        v;
    
  end matchcontinue;
end cevalBuiltinMinArr;

protected function cevalBuiltinDifferentiate "function cevalBuiltinDifferentiate
  author: LP
  This function differentiates an equation: x^2 + x => 2x + 1"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      DAE.Exp differentiated_exp,differentiated_exp_1,exp1;
      String ret_val;
      list<Env.Frame> env;
      DAE.ComponentRef cr;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp1,DAE.CREF(componentRef = cr)},impl,st,msg)
      equation
        differentiated_exp = Derive.differentiateExpCont(exp1, cr);
        (differentiated_exp_1,_) = ExpressionSimplify.simplify(differentiated_exp);
        /*
         this is wrong... this should be used instead but unelabExp must be able to unelaborate a complete exp
         now it doesn't so the expression is returned as string Expression.unelabExp(differentiated_exp') => absyn_exp
        */
        ret_val = ExpressionDump.printExpStr(differentiated_exp_1);
      then
        (cache,Values.STRING(ret_val),st);
    case (_,_,_,_,st,msg) /* =>  (Values.CODE(Absyn.C_EXPRESSION(absyn_exp)),st) */
      equation
        print("#- Differentiation failed. Celab.cevalBuiltinDifferentiate failed.\n");
      then
        fail();
  end matchcontinue;
end cevalBuiltinDifferentiate;

protected function cevalBuiltinSimplify "function cevalBuiltinSimplify
  author: LP
  this function simplifies an equation: x^2 + x => 2x + 1"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      DAE.Exp exp1_1,exp1;
      String ret_val;
      list<Env.Frame> env;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      Absyn.Info info;

    case (cache,env,{exp1},impl,st,msg)
      equation
        (exp1_1,_) = ExpressionSimplify.simplify(exp1);
        ret_val = ExpressionDump.printExpStr(exp1_1) "this should be used instead but unelab_exp must be able to unelaborate a complete exp Expression.unelab_exp(simplifyd_exp\') => absyn_exp" ;
      then
        (cache,Values.STRING(ret_val),st);
    case (_,_,_,_,st,MSG(info = info)) /* =>  (Values.CODE(Absyn.C_EXPRESSION(absyn_exp)),st) */
      equation
        Error.addSourceMessage(Error.COMPILER_ERROR, 
          {"Simplification failed. Ceval.cevalBuiltinSimplify failed."}, info);
      then
        fail();
  end matchcontinue;
end cevalBuiltinSimplify;

protected function cevalBuiltinRem "function cevalBuiltinRem
  author: LP
  Evaluates the builtin rem operator"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv1,rv2,rvd,dr;
      Integer ri,ri1,ri2,ri_1,di;
      list<Env.Frame> env;
      DAE.Exp exp1,exp2;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      String exp1_str,exp2_str;
      Env.Cache cache;
      Absyn.Info info;

    case (cache,env,{exp1,exp2},impl,st,msg)
      equation
        (cache,Values.REAL(rv1),_) = ceval(cache,env, exp1, impl, st,msg);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st,msg);
        (cache,Values.REAL(dr),_) = cevalBuiltinDiv(cache,env,{exp1,exp2},impl,st,msg);
        rvd = rv1 -. rv2 *. dr;
      then
        (cache,Values.REAL(rvd),st);
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation
        (cache,Values.INTEGER(ri),_) = ceval(cache,env, exp1, impl, st,msg);
        rv1 = intReal(ri);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st,msg);
        (cache,Values.REAL(dr),_) = cevalBuiltinDiv(cache,env,{exp1,exp2},impl,st,msg);
        rvd = rv1 -. rv2 *. dr;
      then
        (cache,Values.REAL(rvd),st);
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation
        (cache,Values.REAL(rv1),_) = ceval(cache,env, exp1, impl, st,msg);
        (cache,Values.INTEGER(ri),_) = ceval(cache,env, exp2, impl, st,msg);
        rv2 = intReal(ri);
        (cache,Values.REAL(dr),_) = cevalBuiltinDiv(cache,env,{exp1,exp2},impl,st,msg);
        rvd = rv1 -. rv2 *. dr;
      then
        (cache,Values.REAL(rvd),st);
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation
        (cache,Values.INTEGER(ri1),_) = ceval(cache,env, exp1, impl, st,msg);
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st,msg);
        (cache,Values.INTEGER(di),_) = cevalBuiltinDiv(cache,env,{exp1,exp2},impl,st,msg);
        ri_1 = ri1 - ri2 * di;
      then
        (cache,Values.INTEGER(ri_1),st);
    case (cache,env,{exp1,exp2},impl,st,MSG(info = info))
      equation
        (cache,Values.REAL(rv2),_) = ceval(cache,env,exp2,impl,st,inMsg);
        (rv2 ==. 0.0) = true;
        exp1_str = ExpressionDump.printExpStr(exp1);
        exp2_str = ExpressionDump.printExpStr(exp2);
        Error.addSourceMessage(Error.REM_ARG_ZERO, {exp1_str,exp2_str}, info);
      then
        fail();
        /*
    case (cache,env,{exp1,exp2},impl,st,NO_MSG())
      equation
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl,st,NO_MSG());
        (rv2 ==. 0.0) = true;
      then
        fail();
        */
    case (cache,env,{exp1,exp2},impl,st,MSG(info = info))
      equation
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st,inMsg);
        (ri2 == 0) = true;
        exp1_str = ExpressionDump.printExpStr(exp1);
        exp2_str = ExpressionDump.printExpStr(exp2);
        Error.addSourceMessage(Error.REM_ARG_ZERO, {exp1_str,exp2_str}, info);
      then
        fail();
        /*
    case (cache,env,{exp1,exp2},impl,st,NO_MSG())
      equation
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st, NO_MSG());
        (ri2 == 0) = true;
      then
        fail();
        */
  end matchcontinue;
end cevalBuiltinRem;

protected function cevalBuiltinInteger "function cevalBuiltinInteger
  author: LP
  Evaluates the builtin integer operator"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv;
      Integer ri;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env,exp,impl,st,msg);
        ri = realInt(rv);
      then
        (cache,Values.INTEGER(ri),st);
  end match;
end cevalBuiltinInteger;

protected function cevalBuiltinBoolean "function cevalBuiltinBoolean
 @author: adrpo
  Evaluates the builtin boolean operator"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv;
      Integer iv;
      Boolean bv;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
    
    // real -> bool
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache, env, exp, impl, st, msg);
        bv = Util.if_(realEq(rv, 0.0), false, true);
      then
        (cache,Values.BOOL(bv),st);
    
    // integer -> bool
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.INTEGER(iv),_) = ceval(cache, env, exp, impl, st, msg);
        bv = Util.if_(intEq(iv, 0), false, true);
      then
        (cache,Values.BOOL(bv),st);
    
    // bool -> bool
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.BOOL(bv),_) = ceval(cache, env, exp, impl, st, msg);
      then
        (cache,Values.BOOL(bv),st);
  end matchcontinue;
end cevalBuiltinBoolean;

protected function cevalBuiltinRooted
"function cevalBuiltinRooted
  author: adrpo
  Evaluates the builtin rooted operator from MultiBody"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,_,_) = ceval(cache,env,exp,impl,st,msg);
      then
        (cache,Values.BOOL(true),st);
  end match;
end cevalBuiltinRooted;

protected function cevalBuiltinIntegerEnumeration "function cevalBuiltinIntegerEnumeration
  author: LP
  Evaluates the builtin Integer operator"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Integer ri;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.ENUM_LITERAL(index = ri),_) = ceval(cache,env,exp,impl,st,msg);
      then
        (cache,Values.INTEGER(ri),st);
  end match;
end cevalBuiltinIntegerEnumeration;

protected function cevalBuiltinDiagonal "function cevalBuiltinDiagonal
  This function generates a matrix{n,n} (A) of the vector {a,b,...,n}
  where the diagonal of A is the vector {a,b,...,n}
  ie A{1,1} == a, A{2,2} == b ..."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Values.Value> rv2,retExp;
      Integer dimension,correctDimension;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      Values.Value res;
      Absyn.Info info;

    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.ARRAY(rv2,{dimension}),_) = ceval(cache,env,exp,impl,st,msg);
        correctDimension = dimension + 1;
        (cache,retExp) = cevalBuiltinDiagonal2(cache,env, exp, impl, st, correctDimension, 1, {}, msg);
        res = Values.ARRAY(retExp,{dimension,dimension});
      then
        (cache,res,st);
    case (_,_,_,_,_,MSG(info = info))
      equation
        Error.addSourceMessage(Error.COMPILER_ERROR,
          {"Could not evaluate diagonal. Ceval.cevalBuiltinDiagonal failed."}, info);
      then
        fail();
  end matchcontinue;
end cevalBuiltinDiagonal;

protected function cevalBuiltinDiagonal2 "function: cevalBuiltinDiagonal2
   This is a help function that is calling itself recursively to
   generate the a nxn matrix with some special diagonal elements.
   See cevalBuiltinDiagonal."
  input Env.Cache inCache;
  input Env.Env inEnv1;
  input DAE.Exp inExp2;
  input Boolean inBoolean3;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption4;
  input Integer inInteger5 "matrix dimension";
  input Integer inInteger6 "row";
  input list<Values.Value> inValuesValueLst7;
  input Msg inMsg8;
  output Env.Cache outCache;
  output list<Values.Value> outValuesValueLst;
algorithm
  (outCache,outValuesValueLst) :=
  matchcontinue (inCache,inEnv1,inExp2,inBoolean3,inInteractiveInteractiveSymbolTableOption4,inInteger5,inInteger6,inValuesValueLst7,inMsg8)
    local
      Real rv2;
      Integer correctDim,correctPlace,newRow,matrixDimension,row,iv2;
      list<Values.Value> zeroList,listWithElement,retExp,appendedList,listIN,list_;
      list<Env.Frame> env;
      DAE.Exp s1,s2;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      Values.Value v;
      Absyn.Info info;
      String str;
    
    case (cache,env,s1,impl,st,matrixDimension,row,{},msg)
      equation
        s2 = DAE.ICONST(row);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, Expression.makeASUB(s1,{s2}), impl, st,msg);
        correctDim = matrixDimension - 1;
        zeroList = Util.listFill(Values.REAL(0.0), correctDim);
        correctPlace = row - 1;
        listWithElement = Util.listReplaceAt(Values.REAL(rv2), correctPlace, zeroList);
        newRow = row + 1;
        v = ValuesUtil.makeArray(listWithElement);
        (cache,retExp) = cevalBuiltinDiagonal2(cache,env, s1, impl, st, matrixDimension, newRow, {v}, msg);
      then
        (cache,retExp);
    
    case (cache,env,s1,impl,st,matrixDimension,row,listIN,msg)
      equation
        s2 = DAE.ICONST(row);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, Expression.makeASUB(s1,{s2}), impl, st,msg);
        
        false = intEq(matrixDimension, row);
        
        correctDim = matrixDimension - 1;
        zeroList = Util.listFill(Values.REAL(0.0), correctDim);
        correctPlace = row - 1;
        listWithElement = Util.listReplaceAt(Values.REAL(rv2), correctPlace, zeroList);
        newRow = row + 1;
        v = ValuesUtil.makeArray(listWithElement);
        appendedList = listAppend(listIN, {v});
        (cache,retExp)= cevalBuiltinDiagonal2(cache,env, s1, impl, st, matrixDimension, newRow, appendedList, msg);
      then
        (cache,retExp);
    
    case (cache,env,s1,impl,st,matrixDimension,row,{},msg)
      equation
        s2 = DAE.ICONST(row);
        (cache,Values.INTEGER(iv2),_) = ceval(cache,env, Expression.makeASUB(s1,{s2}), impl, st,msg);
        correctDim = matrixDimension - 1;
        zeroList = Util.listFill(Values.INTEGER(0), correctDim);
        correctPlace = row - 1;
        listWithElement = Util.listReplaceAt(Values.INTEGER(iv2), correctPlace, zeroList);
        newRow = row + 1;
        v = ValuesUtil.makeArray(listWithElement);
        (cache,retExp) = cevalBuiltinDiagonal2(cache,env, s1, impl, st, matrixDimension, newRow, {v}, msg);
      then
        (cache,retExp);
    
    case (cache,env,s1,impl,st,matrixDimension,row,listIN,msg)
      equation
        s2 = DAE.ICONST(row);
        (cache,Values.INTEGER(iv2),_) = ceval(cache,env, Expression.makeASUB(s1,{s2}), impl, st,msg);
        
        false = intEq(matrixDimension, row);

        correctDim = matrixDimension - 1;
        zeroList = Util.listFill(Values.INTEGER(0), correctDim);
        correctPlace = row - 1;
        listWithElement = Util.listReplaceAt(Values.INTEGER(iv2), correctPlace, zeroList);
        newRow = row + 1;
        v = ValuesUtil.makeArray(listWithElement);
        appendedList = listAppend(listIN, {v});
        (cache,retExp) = cevalBuiltinDiagonal2(cache,env, s1, impl, st, matrixDimension, newRow, appendedList,
          msg);
      then
        (cache,retExp);
    
    case (cache,env,s1,impl,st,matrixDimension,row,listIN,msg)
      equation
        true = intEq(matrixDimension, row);
      then
        (cache,listIN);
    
    case (_,_,_,_,_,matrixDimension,row,list_,MSG(info = info))
      equation
        true = RTOpts.debugFlag("ceval");
        str = Error.infoStr(info);
        Debug.traceln(str +& " Ceval.cevalBuiltinDiagonal2 failed");
      then
        fail();
  end matchcontinue;
end cevalBuiltinDiagonal2;

protected function cevalBuiltinCross "
  x,y => {x[2]*y[3]-x[3]*y[2],x[3]*y[1]-x[1]*y[3],x[1]*y[2]-x[2]*y[1]}"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Values.Value> xv,yv;
      Values.Value res;
      list<Env.Frame> env;
      DAE.Exp xe,ye;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      String str;
      Absyn.Info info;

    case (cache,env,{xe,ye},impl,st,msg)
      equation
        (cache,Values.ARRAY(xv,{3}),_) = ceval(cache,env,xe,impl,st,msg);
        (cache,Values.ARRAY(yv,{3}),_) = ceval(cache,env,ye,impl,st,msg);
        res = ValuesUtil.crossProduct(xv,yv);
      then
        (cache,res,st);
    case (_,_,_,_,_,MSG(info = info))
      equation
        str = "cross" +& ExpressionDump.printExpStr(DAE.TUPLE(inExpExpLst));
        Error.addSourceMessage(Error.FAILED_TO_EVALUATE_EXPRESSION, {str}, info);
      then
        fail();
  end matchcontinue;
end cevalBuiltinCross;

protected function cevalBuiltinTranspose "function cevalBuiltinTranspose
  This function transposes the two first dimension of an array A."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Values.Value> vlst,vlst2,vlst_1;
      Integer i1,i2;
      list<Integer> il;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      Absyn.Info info;

    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.ARRAY(vlst,i1::_),_) = ceval(cache,env,exp,impl,st,msg);
        (Values.ARRAY(valueLst = vlst2, dimLst = i2::il) :: _) = vlst;
        vlst_1 = cevalBuiltinTranspose2(vlst, 1, i2::i1::il);
      then
        (cache,Values.ARRAY(vlst_1,i2::i1::il),st);
    case (_,_,_,_,_,MSG(info = info))
      equation
        Error.addSourceMessage(Error.COMPILER_ERROR, 
          {"Could not evaluate transpose. Celab.cevalBuildinTranspose failed."}, info);
      then
        fail();
  end matchcontinue;
end cevalBuiltinTranspose;

protected function cevalBuiltinTranspose2 "function: cevalBuiltinTranspose2
  author: PA
  Helper function to cevalBuiltinTranspose"
  input list<Values.Value> inValuesValueLst1;
  input Integer inInteger2 "index";
  input list<Integer> inDims "dimension";
  output list<Values.Value> outValuesValueLst;
algorithm
  outValuesValueLst:=
  matchcontinue (inValuesValueLst1,inInteger2,inDims)
    local
      list<Values.Value> transposed_row,rest,vlst;
      Integer indx_1,indx,dim1;
    case (vlst,indx,inDims as (dim1::_))
      equation
        (indx <= dim1) = true;
        transposed_row = Util.listMap1(vlst, ValuesUtil.nthArrayelt, indx);
        indx_1 = indx + 1;
        rest = cevalBuiltinTranspose2(vlst, indx_1, inDims);
      then
        (Values.ARRAY(transposed_row,inDims) :: rest);
    case (_,_,_) then {};
  end matchcontinue;
end cevalBuiltinTranspose2;

protected function cevalBuiltinSizeMatrix "function: cevalBuiltinSizeMatrix
  Helper function for cevalBuiltinSize, for size(A) where A is a matrix."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp inExp;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption) :=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      DAE.Type tp;
      list<Integer> sizelst;
      Values.Value v;
      Env.Env env;
      DAE.ComponentRef cr;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Msg msg;
      Env.Cache cache;
      DAE.Exp exp;
      list<DAE.Dimension> dims;
    
    // size(cr)
    case (cache,env,DAE.CREF(componentRef = cr),impl,st,msg)
      equation
        (cache,_,tp,_,_,_,_,_,_) = Lookup.lookupVar(cache,env, cr);
        sizelst = Types.getDimensionSizes(tp);
        v = ValuesUtil.intlistToValue(sizelst);
      then
        (cache,v,st);
        
    // For matrix expressions: [1,2;3,4]
    case (cache, env, DAE.MATRIX(ty = DAE.ET_ARRAY(arrayDimensions = dims)), impl, st, msg)
      equation
        sizelst = Util.listMap(dims, Expression.dimensionSize);
        v = ValuesUtil.intlistToValue(sizelst);
      then
        (cache, v, st);
    
    // For other matrix expressions e.g. on array form: {{1,2},{3,4}}
    case (cache,env,exp,impl,st,msg)
      equation
        (cache,Values.ARRAY(dimLst=sizelst),st) = ceval(cache,env, exp, impl, st,msg);
        v = ValuesUtil.intlistToValue(sizelst);
      then
        (cache,v,st);
  end matchcontinue;
end cevalBuiltinSizeMatrix;

protected function cevalBuiltinFill
  "This function constant evaluates calls to the fill function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpl;
  input Boolean inImpl;
  input Option<Interactive.SymbolTable> inST;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outST;
algorithm
  (outCache, outValue, outST) :=
  match (inCache, inEnv, inExpl, inImpl, inST, inMsg)
    local
      DAE.Exp fill_exp;
      list<DAE.Exp> dims;
      Values.Value fill_val;
      Env.Cache cache;
      Option<Interactive.SymbolTable> st;
    case (cache, _, fill_exp :: dims, _, st, _)
      equation
        (cache, fill_val, st) = ceval(cache, inEnv, fill_exp, inImpl, st, inMsg);
        (cache, fill_val, st) = cevalBuiltinFill2(cache, inEnv, fill_val, dims,
          inImpl, inST, inMsg);
      then
        (cache, fill_val, st);
  end match;
end cevalBuiltinFill;

protected function cevalBuiltinFill2
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Values.Value inFillValue;
  input list<DAE.Exp> inDims;
  input Boolean inImpl;
  input Option<Interactive.SymbolTable> inST;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.SymbolTable> outST;
algorithm
  (outCache, outValue, outST) := 
  match (inCache, inEnv, inFillValue, inDims, inImpl, inST, inMsg)
    local
      DAE.Exp dim;
      list<DAE.Exp> rest_dims;
      Integer int_dim;
      list<Integer> array_dims;
      Values.Value fill_value;
      list<Values.Value> fill_vals;
      Env.Cache cache;
      Option<Interactive.SymbolTable> st;

    case (cache, _, _, {}, _, st, _) then (cache, inFillValue, st);

    case (cache, _, _, dim :: rest_dims, _, st, _)
      equation
        (cache, fill_value, st) = cevalBuiltinFill2(cache, inEnv, inFillValue,
          rest_dims, inImpl, inST, inMsg);
        (cache, Values.INTEGER(int_dim), st) = 
          ceval(cache, inEnv, dim, inImpl, st, inMsg);
        fill_vals = Util.listFill(fill_value, int_dim);
        array_dims = ValuesUtil.valueDimensions(fill_value);
        array_dims = int_dim :: array_dims;
      then
        (cache, Values.ARRAY(fill_vals, array_dims), st);
  end match;
end cevalBuiltinFill2;

protected function cevalRelation
  "Performs the arithmetic relation check and gives a boolean result."
  input Values.Value inValue1;
  input DAE.Operator inOperator;
  input Values.Value inValue2;
  output Values.Value outValue;

  Boolean result;
algorithm
  result := cevalRelation_dispatch(inValue1, inOperator, inValue2);
  outValue := Values.BOOL(result);
end cevalRelation;

protected function cevalRelation_dispatch
  "Dispatch function for cevalRelation. Call the right relation function
  depending on the operator."
  input Values.Value inValue1;
  input DAE.Operator inOperator;
  input Values.Value inValue2;
  output Boolean result;
algorithm
  result := matchcontinue(inValue1, inOperator, inValue2)
    local 
      Values.Value v1, v2;
      DAE.Operator op;
    
    case (v1, DAE.GREATER(ty = _), v2) then cevalRelationLess(v2, v1);
    case (v1, DAE.LESS(ty = _), v2) then cevalRelationLess(v1, v2);
    case (v1, DAE.LESSEQ(ty = _), v2) then cevalRelationLessEq(v1, v2);
    case (v1, DAE.GREATEREQ(ty = _), v2) then cevalRelationGreaterEq(v1, v2);
    case (v1, DAE.EQUAL(ty = _), v2) then cevalRelationEqual(v1, v2);
    case (v1, DAE.NEQUAL(ty = _), v2) then cevalRelationNotEqual(v1, v2);
    
    case (v1, op, v2)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "- Ceval.cevalRelation failed on: " +&
          ValuesUtil.printValStr(v1) +&
          ExpressionDump.binopSymbol(op) +&
          ValuesUtil.printValStr(v2));
      then
        fail();
  end matchcontinue;
end cevalRelation_dispatch;

protected function cevalRelationLess
  "Returns whether the first value is less than the second value."
  input Values.Value inValue1;
  input Values.Value inValue2;
  output Boolean result;
algorithm
  result := matchcontinue(inValue1, inValue2)
    local
      String s1, s2;
      Integer i1, i2;
      Real r1, r2;
    case (Values.STRING(string = s1), Values.STRING(string = s2))
      then (stringCompare(s1, s2) < 0);
    case (Values.INTEGER(integer = i1), Values.INTEGER(integer = i2))
      then (i1 < i2);
    case (Values.REAL(real = r1), Values.REAL(real = r2)) 
      then (r1 <. r2);
    case (Values.BOOL(boolean = false), Values.BOOL(boolean = true))
      then true;
    case (Values.BOOL(boolean = _), Values.BOOL(boolean = _))
      then false;
    case (Values.ENUM_LITERAL(index = i1), Values.ENUM_LITERAL(index = i2))
      then (i1 < i2);
    case (Values.ENUM_LITERAL(index = i1), Values.INTEGER(integer = i2))
      then (i1 < i2);
    case (Values.INTEGER(integer = i1), Values.ENUM_LITERAL(index = i2))
      then (i1 < i2);
  end matchcontinue;
end cevalRelationLess;

protected function cevalRelationLessEq
  "Returns whether the first value is less than or equal to the second value."
  input Values.Value inValue1;
  input Values.Value inValue2;
  output Boolean result;
algorithm
  result := matchcontinue(inValue1, inValue2)
    local
      String s1, s2;
      Integer i1, i2;
      Real r1, r2;
    case (Values.STRING(string = s1), Values.STRING(string = s2))
      then (stringCompare(s1, s2) <= 0);
    case (Values.INTEGER(integer = i1), Values.INTEGER(integer = i2))
      then (i1 <= i2);
    case (Values.REAL(real = r1), Values.REAL(real = r2)) 
      then (r1 <=. r2);
    case (Values.BOOL(boolean = true), Values.BOOL(boolean = false))
      then false;
    case (Values.BOOL(boolean = _), Values.BOOL(boolean = _))
      then true;
    case (Values.ENUM_LITERAL(index = i1), Values.ENUM_LITERAL(index = i2))
      then (i1 <= i2);
    case (Values.ENUM_LITERAL(index = i1), Values.INTEGER(integer = i2))
      then (i1 <= i2);
    case (Values.INTEGER(integer = i1), Values.ENUM_LITERAL(index = i2))
      then (i1 <= i2);
  end matchcontinue;
end cevalRelationLessEq;

protected function cevalRelationGreaterEq
  "Returns whether the first value is greater than or equal to the second value."
  input Values.Value inValue1;
  input Values.Value inValue2;
  output Boolean result;
algorithm
  result := matchcontinue(inValue1, inValue2)
    local
      String s1, s2;
      Integer i1, i2;
      Real r1, r2;
    case (Values.STRING(string = s1), Values.STRING(string = s2))
      then (stringCompare(s1, s2) >= 0);
    case (Values.INTEGER(integer = i1), Values.INTEGER(integer = i2))
      then (i1 >= i2);
    case (Values.REAL(real = r1), Values.REAL(real = r2)) 
      then (r1 >=. r2);
    case (Values.BOOL(boolean = false), Values.BOOL(boolean = true))
      then false;
    case (Values.BOOL(boolean = _), Values.BOOL(boolean = _))
      then true;
    case (Values.ENUM_LITERAL(index = i1), Values.ENUM_LITERAL(index = i2))
      then (i1 >= i2);
    case (Values.ENUM_LITERAL(index = i1), Values.INTEGER(integer = i2))
      then (i1 >= i2);
    case (Values.INTEGER(integer = i1), Values.ENUM_LITERAL(index = i2))
      then (i1 >= i2);
  end matchcontinue;
end cevalRelationGreaterEq;

protected function cevalRelationEqual
  "Returns whether the first value is equal to the second value."
  input Values.Value inValue1;
  input Values.Value inValue2;
  output Boolean result;
algorithm
  result := match(inValue1, inValue2)
    local
      String s1, s2;
      Integer i1, i2;
      Real r1, r2;
      Boolean b1, b2;
    case (Values.STRING(string = s1), Values.STRING(string = s2))
      then (stringCompare(s1, s2) == 0);
    case (Values.INTEGER(integer = i1), Values.INTEGER(integer = i2))
      then (i1 == i2);
    case (Values.REAL(real = r1), Values.REAL(real = r2)) 
      then (r1 ==. r2);
    case (Values.BOOL(boolean = b1), Values.BOOL(boolean = b2)) 
      then boolEq(b1, b2);
    case (Values.ENUM_LITERAL(index = i1), Values.ENUM_LITERAL(index = i2))
      then (i1 == i2);
    case (Values.ENUM_LITERAL(index = i1), Values.INTEGER(integer = i2))
      then (i1 == i2);
    case (Values.INTEGER(integer = i1), Values.ENUM_LITERAL(index = i2))
      then (i1 == i2);
  end match;
end cevalRelationEqual;

protected function cevalRelationNotEqual
  "Returns whether the first value is not equal to the second value."
  input Values.Value inValue1;
  input Values.Value inValue2;
  output Boolean result;
algorithm
  result := match(inValue1, inValue2)
    local
      String s1, s2;
      Integer i1, i2;
      Real r1, r2;
      Boolean b1, b2;
    case (Values.STRING(string = s1), Values.STRING(string = s2))
      then (stringCompare(s1, s2) <> 0);
    case (Values.INTEGER(integer = i1), Values.INTEGER(integer = i2))
      then (i1 <> i2);
    case (Values.REAL(real = r1), Values.REAL(real = r2)) 
      then (r1 <>. r2);
    case (Values.BOOL(boolean = b1), Values.BOOL(boolean = b2)) 
      then not boolEq(b1, b2);
    case (Values.ENUM_LITERAL(index = i1), Values.ENUM_LITERAL(index = i2))
      then (i1 <> i2);
    case (Values.ENUM_LITERAL(index = i1), Values.INTEGER(integer = i2))
      then (i1 <> i2);
    case (Values.INTEGER(integer = i1), Values.ENUM_LITERAL(index = i2))
      then (i1 <> i2);
  end match;
end cevalRelationNotEqual;

public function cevalRangeEnum
  "Evaluates a range expression on the form enum.lit1 : enum.lit2"
  input Integer startIndex;
  input Integer stopIndex;
  input DAE.ExpType enumType;
  output list<Values.Value> enumValList;
algorithm
  enumValList := match(startIndex, stopIndex, enumType)
    local
      Absyn.Path enum_type;
      list<String> enum_names;
      list<Absyn.Path> enum_paths;
      list<Values.Value> enum_values;
    case (_, _, DAE.ET_ENUMERATION(path = enum_type, names = enum_names))
      equation
        (startIndex <= stopIndex) = true;
        enum_names = Util.listSub(enum_names, startIndex, (stopIndex - startIndex) + 1);
        enum_paths = Util.listMap(enum_names, Absyn.makeIdentPathFromString);
        enum_paths = Util.listMap1r(enum_paths, Absyn.joinPaths, enum_type);
        (enum_values, _) = Util.listMapAndFold(enum_paths, makeEnumValue, startIndex);
      then
        enum_values;
  end match;
end cevalRangeEnum;
  
protected function makeEnumValue
  input Absyn.Path name;
  input Integer index;
  output Values.Value enumValue;
  output Integer newIndex;
algorithm
  enumValue := Values.ENUM_LITERAL(name, index);
  newIndex := index + 1;
end makeEnumValue;

public function cevalList "function: cevalList
  This function does constant
  evaluation on a list of expressions."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output list<Values.Value> outValuesValueLst;
  output Option<Interactive.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValuesValueLst,outInteractiveInteractiveSymbolTableOption) :=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      Msg msg;
      Values.Value v;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      list<Values.Value> vs;
      list<DAE.Exp> exps;
      Env.Cache cache;
    case (cache,env,{},_,st,msg) then (cache,{},st);
    case (cache,env,(exp :: exps ),impl,st,msg)
      equation
        (cache,v,st) = ceval(cache,env, exp, impl, st, msg);
        (cache,vs,st) = cevalList(cache,env, exps, impl, st, msg);
      then
        (cache,v :: vs,st);
  end match;
end cevalList;

protected function cevalCref "function: cevalCref
  Evaluates ComponentRef, i.e. variables, by
  looking up variables in the environment."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.ComponentRef inComponentRef;
  input Boolean inBoolean "impl";
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue) :=
  matchcontinue (inCache,inEnv,inComponentRef,inBoolean,inMsg)
    local
      DAE.Binding binding;
      Values.Value v;
      Env.Env env, classEnv, componentEnv;
      DAE.ComponentRef c;
      Boolean impl;
      Msg msg;
      String scope_str,str, name;
      Env.Cache cache;
      Option<DAE.Const> const_for_range;
      DAE.Type ty;
      DAE.Attributes attr;
      Lookup.SplicedExpData splicedExpData;
      Absyn.Info info;

    // Try to lookup the variables binding and constant evaluate it.
    case (cache, env, c, impl, msg)
      equation
        (cache,attr,ty,binding,const_for_range,splicedExpData,classEnv,componentEnv,name) = Lookup.lookupVar(cache, env, c);
         // send the entire shebang to cevalCref2 so we don't have to do lookup var again!
        (cache, v) = cevalCref_dispatch(cache, env, c, attr, ty, binding, const_for_range, splicedExpData, classEnv, componentEnv, name, impl, msg);
      then
        (cache, v);

    // failure in lookup and we have the MSG go-ahead to print the error
    case (cache,env,c,(impl as false),MSG(info = info))
      equation
        failure((_,_,_,_,_,_,_,_,_) = Lookup.lookupVar(cache,env, c));
        scope_str = Env.printEnvPathStr(env);
        str = ComponentReference.printComponentRefStr(c);
        Error.addSourceMessage(Error.LOOKUP_VARIABLE_ERROR, {str,scope_str}, info);
      then
        fail();
    
    // failure in lookup but NO_MSG, silently fail and move along
    /*case (cache,env,c,(impl as false),NO_MSG())
      equation
        failure((_,_,_,_,_,_,_,_,_) = Lookup.lookupVar(cache,env, c));
      then
        fail();*/
  end matchcontinue;
end cevalCref;

public function cevalCref_dispatch
  "Helper function to cevalCref"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.ComponentRef inCref;
  input DAE.Attributes inAttr;
  input DAE.Type inType;   
  input DAE.Binding inBinding;
  input Option<DAE.Const> constForRange;
  input Lookup.SplicedExpData inSplicedExpData;
  input Env.Env inClassEnv;
  input Env.Env inComponentEnv;
  input String  inFQName;
  input Boolean inImpl;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache, outValue) := match (inCache, inEnv, inCref, inAttr, inType, inBinding, constForRange, inSplicedExpData, inClassEnv, inComponentEnv, inFQName, inImpl, inMsg)
    local
      Env.Cache cache;
      Values.Value v;
      String str, scope_str, s1, s2, s3;
      Absyn.Info info;
      SCode.Variability variability;
    
    // A variable with no binding and SOME for range constness -> a for iterator
    case (_, _, _, _, _, DAE.UNBOUND(), SOME(_), _, _, _, _, _, _) then fail();
    
    // A variable without a binding -> error in a simulation model
    // and we can only check that at the DAE level!
    case (_, _, _, _, _, DAE.UNBOUND(), NONE(), _, _, _, _, false, MSG(info = info))
      equation
        str = ComponentReference.printComponentRefStr(inCref);
        scope_str = Env.printEnvPathStr(inEnv);
        Error.addSourceMessage(Error.NO_CONSTANT_BINDING, {str, scope_str}, info);
        Debug.fprintln("ceval", "- Ceval.cevalCref on: " +& str +& 
          " failed with no constant binding in scope: " +& scope_str);
        // build a default binding for it!
        s1 = Env.printEnvPathStr(inEnv);
        s2 = ComponentReference.printComponentRefStr(inCref);
        s3 = Types.printTypeStr(inType);
        v = Types.typeToValue(inType);
        v = Values.EMPTY(s1, s2, v, s3);
        // i would really like to have Absyn.Info to put in Values.EMPTY here!
        // to easier report errors later on and also to have DAE.ComponentRef and DAE.Type 
        // but unfortunately DAE depends on Values and they should probably be merged !
        // Actually, at a second thought we SHOULD NOT HAVE VALUES AT ALL, WE SHOULD HAVE
        // JUST ONE DAE.Exp.CONSTANT_EXPRESSION(exp, constantness, type)!
      then
        (inCache, v);    
        
    // A variable with a binding -> constant evaluate the binding
    case (_, _, _, DAE.ATTR(variability=variability), _, _, _, _, _, _, _, _, _)
      equation
        // Do not check this; it is needed for some reason :( 
        // true = SCode.isParameterOrConst(variability);
        false = crefEqualValue(inCref, inBinding);
        (cache, v) = cevalCrefBinding(inCache, inEnv, inCref, inBinding, inImpl, inMsg);
        cache = Env.addEvaluatedCref(cache,variability,ComponentReference.crefStripLastSubs(inCref));
      then
        (cache, v);
  end match;
end cevalCref_dispatch;

public function cevalCrefBinding "function: cevalCrefBinding
  Helper function to cevalCref.
  Evaluates variables by evaluating their bindings."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.ComponentRef inComponentRef;
  input DAE.Binding inBinding;
  input Boolean inBoolean "impl";
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue) := matchcontinue (inCache,inEnv,inComponentRef,inBinding,inBoolean,inMsg)
    local
      DAE.ComponentRef cr_1,cr,e1;
      list<DAE.Subscript> subsc;
      DAE.Type tp;
      list<Integer> sizelst;
      Values.Value res,v,e_val;
      list<Env.Frame> env;
      Boolean impl;
      Msg msg;
      String rfn,iter,id,expstr,s1,s2,str;
      DAE.Exp elexp,iterexp,exp;
      Env.Cache cache;

    case (cache,env,cr,DAE.VALBOUND(valBound = v),impl,msg) 
      equation 
        Debug.fprint("tcvt", "+++++++ Ceval.cevalCrefBinding DAE.VALBOUND\n");
        cr_1 = ComponentReference.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        subsc = ComponentReference.crefLastSubs(cr);
        (cache,res) = cevalSubscriptValue(cache, env, subsc, v, impl, msg);
      then
        (cache,res);

    case (cache,env,_,DAE.UNBOUND(),(impl as false),MSG(_)) then fail();

    case (cache,env,_,DAE.UNBOUND(),(impl as true),MSG(_))
      equation
        Debug.fprint("ceval", "#- Ceval.cevalCrefBinding: Ignoring unbound when implicit");
      then
        fail();

    // REDUCTION bindings  
    case (cache,env,cr,DAE.EQBOUND(exp = exp,constant_ = DAE.C_CONST()),impl,msg) 
      equation 
        DAE.REDUCTION(reductionInfo=DAE.REDUCTIONINFO(path = Absyn.IDENT(name = rfn)),expr = elexp, iterators = {DAE.REDUCTIONITER(id=iter,exp=iterexp)}) = exp;
        cr_1 = ComponentReference.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        (cache,v,_) = ceval(cache, env, exp, impl,NONE(), msg);
        subsc = ComponentReference.crefLastSubs(cr);
        (cache,res) = cevalSubscriptValue(cache, env, subsc, v, impl, msg);
      then
        (cache,res);
        
    // arbitrary expressions, C_VAR, value exists. 
    case (cache,env,cr,DAE.EQBOUND(exp = exp,evaluatedExp = SOME(e_val),constant_ = DAE.C_VAR()),impl,msg) 
      equation 
        cr_1 = ComponentReference.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        subsc = ComponentReference.crefLastSubs(cr);
        (cache,res) = cevalSubscriptValue(cache,env, subsc, e_val, impl, msg);
      then
        (cache,res);

    // arbitrary expressions, C_PARAM, value exists.  
    case (cache,env,cr,DAE.EQBOUND(exp = exp,evaluatedExp = SOME(e_val),constant_ = DAE.C_PARAM()),impl,msg) 
      equation 
        cr_1 = ComponentReference.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        subsc = ComponentReference.crefLastSubs(cr);
        (cache,res)= cevalSubscriptValue(cache,env, subsc, e_val, impl, msg);
      then
        (cache,res);

    // arbitrary expressions. When binding has optional value. 
    case (cache,env,cr,DAE.EQBOUND(exp = exp,constant_ = DAE.C_CONST()),impl,msg)
      equation
        cr_1 = ComponentReference.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        (cache,v,_) = ceval(cache, env, exp, impl, NONE(), msg);
        subsc = ComponentReference.crefLastSubs(cr);
        (cache,res) = cevalSubscriptValue(cache,env, subsc, v, impl, msg);
      then
        (cache,res);

    // arbitrary expressions. When binding has optional value.  
    case (cache,env,cr,DAE.EQBOUND(exp = exp,constant_ = DAE.C_PARAM()),impl,msg) 
      equation 
        cr_1 = ComponentReference.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
                
        // TODO: Ugly hack to prevent infinite recursion. If we have a binding r = r that
        // can for instance come from a modifier, this can cause an infinite loop here if r has no value.
        false = isRecursiveBinding(cr,exp);
        
        (cache,v,_) = ceval(cache, env, exp, impl, NONE(), msg);
        subsc = ComponentReference.crefLastSubs(cr);
        (cache,res) = cevalSubscriptValue(cache, env, subsc, v, impl, msg);
      then
        (cache,res);

    // if the binding has constant-ness DAE.C_VAR we cannot constant evaluate.
    case (cache,env,_,DAE.EQBOUND(exp = exp,constant_ = DAE.C_VAR()),impl,MSG(_))
      equation
        true = RTOpts.debugFlag("ceval");
        Debug.fprint("ceval", "#- Ceval.cevalCrefBinding failed (nonconstant EQBOUND(");
        expstr = ExpressionDump.printExpStr(exp);
        Debug.fprint("ceval", expstr);
        Debug.fprintln("ceval", "))");
      then
        fail();

    case (cache,env,e1,inBinding,_,_)
      equation
        true = RTOpts.debugFlag("ceval");
        s1 = ComponentReference.printComponentRefStr(e1);
        s2 = Types.printBindingStr(inBinding);
        str = Env.printEnvPathStr(env);
        str = stringAppendList({"- Ceval.cevalCrefBinding: ", 
                s1, " = [", s2, "] in env:", str, " failed\n"});
        Debug.fprint("ceval", str);
        //print("ENV: " +& Env.printEnvStr(inEnv) +& "\n");
      then
        fail();
  end matchcontinue;
end cevalCrefBinding;

protected function isRecursiveBinding " help function to cevalCrefBinding"
input DAE.ComponentRef cr;
input DAE.Exp exp;
output Boolean res;
algorithm
  res := matchcontinue(cr,exp)
    case(cr,exp) equation
      res = Util.boolOrList(Util.listMap1(Expression.extractCrefsFromExp(exp),ComponentReference.crefEqual,cr));
    then res;
    case(_,_) then false;
  end matchcontinue;
end isRecursiveBinding;
  

protected function cevalSubscriptValue "function: cevalSubscriptValue
  Helper function to cevalCrefBinding. It applies
  subscripts to array values to extract array elements."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Subscript> inExpSubscriptLst "subscripts to extract";
  input Values.Value inValue;
  input Boolean inBoolean "impl";
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue) := matchcontinue (inCache,inEnv,inExpSubscriptLst,inValue,inBoolean,inMsg)
    local
      Integer n,n_1,dim;
      Values.Value subval,res,v;
      list<Env.Frame> env;
      DAE.Exp exp;
      list<DAE.Subscript> subs;
      list<Values.Value> lst,sliceLst,subvals;
      list<Integer> dims,slice;
      Boolean impl;
      Msg msg;
      Env.Cache cache;
      DAE.ComponentRef cr;

    // we have a subscript which is an index, try to constant evaluate it
    case (cache,env,(DAE.INDEX(exp = exp) :: subs),Values.ARRAY(valueLst = lst),impl,msg)
      equation
        (cache,Values.INTEGER(n),_) = ceval(cache, env, exp, impl, NONE(), msg);
        n_1 = n - 1;
        subval = listNth(lst, n_1);
        (cache,res) = cevalSubscriptValue(cache, env, subs, subval, impl, msg);
      then
        (cache,res);
    
    // ceval gives us a enumeration literal scalar
    case (cache,env,(DAE.INDEX(exp = exp) :: subs),Values.ARRAY(valueLst = lst),impl,msg)
      equation
        (cache,Values.ENUM_LITERAL(index = n),_) = ceval(cache, env, exp, impl, NONE(), msg);
        n_1 = n - 1;
        subval = listNth(lst, n_1); // listNth indexes from 0!
        (cache,res) = cevalSubscriptValue(cache, env, subs, subval, impl, msg);
      then
        (cache,res);
    
    // slices
    case (cache,env,(DAE.SLICE(exp = exp) :: subs),Values.ARRAY(valueLst = lst),impl,msg)
      equation
        (cache,subval as Values.ARRAY(valueLst = sliceLst),_) = ceval(cache, env, exp, impl,NONE(), msg);
        slice = Util.listMap(sliceLst, ValuesUtil.valueIntegerMinusOne);
        subvals = Util.listMap1r(slice, listNth, lst);
        (cache,lst) = cevalSubscriptValueList(cache,env, subs, subvals, impl, msg);
        res = ValuesUtil.makeArray(lst);
      then
        (cache,res);
    
    // we have a wholedim, so just pass the whole array on.
    case (cache, env, (DAE.WHOLEDIM() :: subs), subval as Values.ARRAY(valueLst = _), impl, msg)
      equation
        (cache, res) = cevalSubscriptValue(cache, env, subs, subval, impl, msg);
      then
        (cache, res);
       
    // we have no subscripts but we have a value, return it
    case (cache,env,{},v,_,_) then (cache,v);
    
    /*// failtrace
    case (cache, env, subs, inValue, dims, _, _)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "- Ceval.cevalSubscriptValue failed on:" +&
          "\n env: " +& Env.printEnvPathStr(env) +&
          "\n subs: " +& Util.stringDelimitList(Util.listMap(subs, ExpressionDump.printSubscriptStr), ", ") +&
          "\n value: " +& ValuesUtil.printValStr(inValue) +&
          "\n dim sizes: " +& Util.stringDelimitList(Util.listMap(dims, intString), ", ") 
        );
      then
        fail();*/
  end matchcontinue;
end cevalSubscriptValue;

protected function cevalSubscriptValueList "Applies subscripts to array values to extract array elements."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Subscript> inExpSubscriptLst "subscripts to extract";
  input list<Values.Value> inValue;
  input Boolean inBoolean "impl";
  input Msg inMsg;
  output Env.Cache outCache;
  output list<Values.Value> outValue;
algorithm
  (outCache,outValue) :=
  match (inCache,inEnv,inExpSubscriptLst,inValue,inBoolean,inMsg)
    local
      Values.Value subval,res;
      list<Env.Frame> env;
      list<Values.Value> lst,subvals;
      Boolean impl;
      Msg msg;
      list<Integer> dims;
      list<DAE.Subscript> subs;
      Env.Cache cache;
    case (cache,env,subs,{},impl,msg) then (cache,{});
    case (cache,env,subs,subval::subvals,impl,msg)
      equation
        (cache,res) = cevalSubscriptValue(cache,env, subs, subval, impl, msg);
        (cache,lst) = cevalSubscriptValueList(cache,env, subs, subvals, impl, msg);
      then
        (cache,res::lst);
  end match;
end cevalSubscriptValueList;

public function cevalSubscripts "function: cevalSubscripts
  This function relates a list of subscripts to their canonical
  forms, which is when all expressions are evaluated to constant
  values. For instance
  the subscript list {1,p,q} (as in x[1,p,q]) where p and q have constant values 2,3 respectively will become
  {1,2,3} (resulting in x[1,2,3])."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Subscript> inExpSubscriptLst;
  input list<Integer> inIntegerLst;
  input Boolean inBoolean "impl";
  input Msg inMsg;
  output Env.Cache outCache;
  output list<DAE.Subscript> outExpSubscriptLst;
algorithm
  (outCache,outExpSubscriptLst) :=
  match (inCache,inEnv,inExpSubscriptLst,inIntegerLst,inBoolean,inMsg)
    local
      DAE.Subscript sub_1,sub;
      list<DAE.Subscript> subs_1,subs;
      list<Env.Frame> env;
      Integer dim;
      list<Integer> dims;
      Boolean impl;
      Msg msg;
      Env.Cache cache;

    // empty case
    case (cache,_,{},_,_,_) then (cache,{});

    // we have subscripts
    case (cache,env,(sub :: subs),(dim :: dims),impl,msg)
      equation
        (cache,sub_1) = cevalSubscript(cache, env, sub, dim, impl, msg);
        (cache,subs_1) = cevalSubscripts(cache, env, subs, dims, impl, msg);
      then
        (cache,sub_1 :: subs_1);
  end match;
end cevalSubscripts;

public function cevalSubscript "function: cevalSubscript
  This function relates a subscript to its canonical forms, which
  is when all expressions are evaluated to constant values."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Subscript inSubscript;
  input Integer inInteger;
  input Boolean inBoolean "impl";
  input Msg inMsg;
  output Env.Cache outCache;
  output DAE.Subscript outSubscript;
algorithm
  (outCache,outSubscript) :=
  matchcontinue (inCache,inEnv,inSubscript,inInteger,inBoolean,inMsg)
    local
      list<Env.Frame> env;
      Values.Value v1;
      DAE.Exp e1_1,e1;
      Integer dim;
      Boolean impl;
      Msg msg;
      Env.Cache cache;
      Integer indx;

    // the entire dimension, nothing to do
    case (cache,env,DAE.WHOLEDIM(),_,_,_) then (cache,DAE.WHOLEDIM());
      
    // An enumeration literal is already constant
    case (cache, _, DAE.INDEX(exp = DAE.ENUM_LITERAL(name = _)), _, _, _)
      then (cache, inSubscript);
      
    // an expression index that can be constant evaluated
    case (cache,env,DAE.INDEX(exp = e1),dim,impl,msg)
      equation
        (cache,v1 as Values.INTEGER(indx),_) = ceval(cache,env, e1, impl,NONE(), msg);
        e1_1 = ValuesUtil.valueExp(v1);
        true = (indx <= dim) and (indx > 0);
      then
        (cache,DAE.INDEX(e1_1));

    // indexing using enum! 
    case (cache,env,DAE.INDEX(exp = e1),dim,impl,msg)
      equation
        (cache,v1 as Values.ENUM_LITERAL(index = indx),_) = ceval(cache,env, e1, impl,NONE(), msg);
        e1_1 = ValuesUtil.valueExp(v1);
        true = (indx <= dim) and (indx > 0);
      then
        (cache,DAE.INDEX(e1_1));

    // an expression slice that can be constant evaluated
    case (cache,env,DAE.SLICE(exp = e1),dim,impl,msg)
      equation
        (cache,v1,_) = ceval(cache,env, e1, impl,NONE(), msg);
        e1_1 = ValuesUtil.valueExp(v1);
        true = dimensionSliceInRange(v1,dim);
      then
        (cache,DAE.SLICE(e1_1));
        
  end matchcontinue;
end cevalSubscript;

public function getValueString "
Constant evaluates Expression and returns a string representing value."
  input DAE.Exp e;
  output String ostring;
algorithm 
  ostring := matchcontinue(e)
    local 
      Values.Value val;
      String ret;

    case(e)
      equation
        (_,val as Values.STRING(ret),_) = ceval(Env.emptyCache(), Env.emptyEnv,
            e, true, NONE(), MSG(Absyn.dummyInfo));
      then
        ret;
  
    case(e)
      equation
        (_,val,_) = ceval(Env.emptyCache(), Env.emptyEnv, e, true, NONE(),
            MSG(Absyn.dummyInfo));
        ret = ValuesUtil.printValStr(val);
      then
        ret;
  end matchcontinue;
end getValueString;

protected function crefEqualValue ""
  input DAE.ComponentRef c;
  input DAE.Binding v;
  output Boolean outBoolean;
algorithm 
  outBoolean := match (c,v)
    local 
      DAE.ComponentRef cr;
    
    case(c,(v as DAE.EQBOUND(DAE.CREF(cr,_),NONE(),_,_)))
      then ComponentReference.crefEqual(c,cr);
    
    else false;
    
  end match;
end crefEqualValue;

protected function dimensionSliceInRange "
Checks that the values of a dimension slice is all in the range 1 to dim size
if so returns true, else returns false"
  input Values.Value arr;
  input Integer dimSize;
  output Boolean inRange;
algorithm
  inRange := matchcontinue(arr,dimSize)
    local
      Integer indx,dim;
      list<Values.Value> vlst;
      list<Integer> dims;
    
    case(Values.ARRAY(valueLst = {}),_) then true;
    
    case(Values.ARRAY(valueLst = Values.INTEGER(indx)::vlst, dimLst = dim::dims),dimSize) 
      equation
        dim = dim-1;
        dims = dim::dims;
        true = indx <= dimSize;
        true = dimensionSliceInRange(Values.ARRAY(vlst,dims),dimSize);
      then true;
    
    case(_,_) then false;
  
  end matchcontinue;
end dimensionSliceInRange;

protected function cevalReduction
  "Help function to ceval. Evaluates reductions calls, such as
    'sum(i for i in 1:5)'"
  input Env.Cache cache;
  input Env.Env env;
  input Absyn.Path opPath;
  input Option<Values.Value> curValue;
  input DAE.Exp exp;
  input DAE.Type exprType;
  input Option<DAE.Exp> foldExp;
  input list<String> iteratorNames;
  input list<list<Values.Value>> valueMatrix;
  input list<DAE.Type> iterTypes;
  input Boolean impl;
  input Option<Interactive.SymbolTable> st;
  input Msg msg;
  output Env.Cache newCache;
  output Option<Values.Value> result;
  output Option<Interactive.SymbolTable> newSymbolTable;
algorithm
  (newCache, result, newSymbolTable) := matchcontinue (cache, env, opPath, curValue, exp, exprType, foldExp, iteratorNames, valueMatrix, iterTypes, impl, st, msg)
    local
      Values.Value value, value2, reduced_value;
      list<Values.Value> rest_values,vals;
      Env.Env new_env;
      Env.Cache new_cache;
      Option<Interactive.SymbolTable> new_st;
      DAE.ExpType exp_type;
      DAE.Type iter_type;
      list<Integer> dims;
      Boolean guardFilter;
    case (_, _, Absyn.IDENT("listReverse"), SOME(Values.LIST(vals)), exp, exprType, foldExp, iteratorNames, {}, iterTypes, impl, st, msg)
      equation
        vals = listReverse(vals);
      then (cache, SOME(Values.LIST(vals)), st);
    case (_, _, Absyn.IDENT("array"), SOME(Values.ARRAY(vals,dims)), _, _, _, _, {}, iterTypes, impl, st, msg)
      then (cache, SOME(Values.ARRAY(vals,dims)), st);

    case (_, _, _, curValue, _, _, _, _, {}, iterTypes, impl, st, msg)
      then (cache, curValue, st);

    case (cache, env, _, curValue, _, _, _, iteratorNames, vals :: valueMatrix, iterTypes, impl, st, msg)
      equation
        // Bind the iterator
        // print("iterator: " +& iteratorName +& " => " +& ValuesUtil.valString(value) +& "\n");
        new_env = extendFrameForIterators(env, iteratorNames, vals, iterTypes);
        // Calculate var1 of the folding function
        (cache, curValue, st) = cevalReductionEvalAndFold(cache, new_env, opPath, curValue, exp, exprType, foldExp, impl, st, msg);
        // Fold the rest of the reduction
        (cache, curValue, st) = cevalReduction(cache, env, opPath, curValue, exp, exprType, foldExp, iteratorNames, valueMatrix, iterTypes, impl, st, msg);
      then (cache, curValue, st);
  end matchcontinue;
end cevalReduction;

protected function cevalReductionEvalGuard "Evaluate the guard-expression (if any). Returns false if the value should be filtered out."
  input Env.Cache cache;
  input Env.Env env;
  input Option<DAE.Exp> guardExp;
  input Boolean impl;
  input Option<Interactive.SymbolTable> st;
  input Msg msg;
  output Env.Cache newCache;
  output Boolean guardFilter;
  output Option<Interactive.SymbolTable> newSymbolTable;
algorithm
  (newCache,guardFilter,newSymbolTable) := match (cache,env,guardExp,impl,st,msg)
    local
      DAE.Exp exp;
    case (cache,_,NONE(),_,_,_) then (cache,true,st);
    case (cache,_,SOME(exp),_,_,_)
      equation
        // print("guardFilter eval: " +& ExpressionDump.printExpStr(exp) +& "\n");
        (cache, Values.BOOL(guardFilter), st) = ceval(cache, env, exp, impl, st, msg);
      then (cache,guardFilter,st);
  end match;
end cevalReductionEvalGuard;

protected function cevalReductionEvalAndFold "Evaluate the reduction body and fold"
  input Env.Cache cache;
  input Env.Env env;
  input Absyn.Path opPath;
  input Option<Values.Value> curValue;
  input DAE.Exp exp;
  input DAE.Type exprType;
  input Option<DAE.Exp> foldExp;
  input Boolean impl;
  input Option<Interactive.SymbolTable> st;
  input Msg msg;
  output Env.Cache newCache;
  output Option<Values.Value> result;
  output Option<Interactive.SymbolTable> newSymbolTable;
algorithm
  (newCache,result,newSymbolTable) := match (cache,env,opPath,curValue,exp,exprType,foldExp,impl,st,msg)
    local
      Values.Value value;
    case (cache,env,_,curValue,exp,exprType,foldExp,impl,st,msg)
      equation
        (cache, value, st) = ceval(cache, env, exp, impl, st, msg);
        // print("cevalReductionEval: " +& ExpressionDump.printExpStr(exp) +& " => " +& ValuesUtil.valString(value) +& "\n");
        (cache, result, st) = cevalReductionFold(cache, env, opPath, curValue, value, foldExp, exprType, impl, st, msg);
      then (cache, result, st);
  end match;
end cevalReductionEvalAndFold;

protected function cevalReductionFold "Fold the reduction body"
  input Env.Cache cache;
  input Env.Env env;
  input Absyn.Path opPath;
  input Option<Values.Value> curValue;
  input Values.Value inValue;
  input Option<DAE.Exp> foldExp;
  input DAE.Type exprType;
  input Boolean impl;
  input Option<Interactive.SymbolTable> st;
  input Msg msg;
  output Env.Cache newCache;
  output Option<Values.Value> result;
  output Option<Interactive.SymbolTable> newSymbolTable;
algorithm
  (newCache,result,newSymbolTable) := match (cache,env,opPath,curValue,inValue,foldExp,exprType,impl,st,msg)
    local
      DAE.Exp exp;
      DAE.ExpType exp_type;
      DAE.Type iter_type;
      Values.Value value;
    case (cache,_,Absyn.IDENT("array"),SOME(value),_,_,_,_,st,_)
      equation
        value = valueArrayCons(ValuesUtil.unboxIfBoxedVal(inValue),value);
      then (cache,SOME(value),st);
    case (cache,_,Absyn.IDENT("list"),SOME(value),_,_,_,_,st,_)
      equation
        value = valueCons(ValuesUtil.unboxIfBoxedVal(inValue),value);
      then (cache,SOME(value),st);
    case (cache,_,Absyn.IDENT("listReverse"),SOME(value),_,_,_,_,st,_)
      equation
        value = valueCons(ValuesUtil.unboxIfBoxedVal(inValue),value);
      then (cache,SOME(value),st);
    case (cache,env,_,NONE(),inValue,_,exprType,impl,st,msg)
      then (cache,SOME(inValue),st);

    case (cache,env,_,SOME(value),inValue,SOME(exp),exprType,impl,st,msg)
      equation
        // print("cevalReductionFold " +& ExpressionDump.printExpStr(exp) +& ", " +& ValuesUtil.valString(inValue) +& ", " +& ValuesUtil.valString(value) +& "\n");
        /* TODO: Store the actual types somewhere... */
        env = Env.extendFrameForIterator(env, "$reductionFoldTmpA", exprType, DAE.VALBOUND(inValue, DAE.BINDING_FROM_DEFAULT_VALUE()), SCode.VAR(), SOME(DAE.C_CONST()));
        env = Env.extendFrameForIterator(env, "$reductionFoldTmpB", exprType, DAE.VALBOUND(value, DAE.BINDING_FROM_DEFAULT_VALUE()), SCode.VAR(), SOME(DAE.C_CONST()));
        (cache, value, st) = ceval(cache, env, exp, impl, st, msg);
      then (cache, SOME(value), st);
  end match;
end cevalReductionFold;

protected function valueArrayCons
  "Returns the cons of two values. Used by cevalReduction for array reductions."
  input Values.Value v1;
  input Values.Value v2;
  output Values.Value res;
algorithm
  res := match(v1, v2)
    local
      list<Values.Value> vals;
      Integer dim_size;
      list<Integer> rest_dims;

    case (_, Values.ARRAY(valueLst = vals, dimLst = dim_size :: rest_dims))
      equation
        dim_size = dim_size + 1;
      then 
        Values.ARRAY(v1 :: vals, dim_size :: rest_dims);

    else then Values.ARRAY({v1, v2}, {2});
  end match;
end valueArrayCons;

protected function valueCons
  "Returns the cons of two values. Used by cevalReduction for list reductions."
  input Values.Value v1;
  input Values.Value v2;
  output Values.Value res;
algorithm
  res := match(v1, v2)
    local
      list<Values.Value> vals;
      Integer dim_size;
      list<Integer> rest_dims;

    case (Values.META_BOX(v1), Values.LIST(vals)) then Values.LIST(v1::vals);
    case (v1, Values.LIST(vals)) then Values.LIST(v1::vals);
  end match;
end valueCons;

protected function lookupReductionOp
  "Looks up a reduction function based on it's name."
  input DAE.Ident reductionName;
  output ReductionOperator op;

  partial function ReductionOperator
    input Values.Value v1;
    input Values.Value v2;
    output Values.Value res;
  end ReductionOperator;
algorithm
  op := match(reductionName)
    case "array" then valueArrayCons;
    case "list" then valueCons;
    case "listReverse" then valueCons;
  end match;
end lookupReductionOp;

// ************************************************************************
//    hash table implementation for storing function pointes for DLLs/SOs
// ************************************************************************
constant Option<CevalHashTable> cevalHashTable = NONE();

public
type Key = Absyn.Path "the function path";
type Value = Interactive.CompiledCFunction "the compiled function";

public function hashFunc
"author: PA
  Calculates a hash value for Absyn.Path"
  input Absyn.Path p;
  output Integer res;
algorithm
  res := stringHashDjb2(Absyn.pathString(p));
end hashFunc;

public function keyEqual
  input Key key1;
  input Key key2;
  output Boolean res;
algorithm
     res := stringEq(Absyn.pathString(key1),Absyn.pathString(key2));
end keyEqual;

public function dumpCevalHashTable ""
  input CevalHashTable t;
algorithm
  print("CevalHashTable:\n");
  print(Util.stringDelimitList(Util.listMap(hashTableList(t),dumpTuple),"\n"));
  print("\n");
end dumpCevalHashTable;

public function dumpTuple
  input tuple<Key,Value> tpl;
  output String str;
algorithm
  str := matchcontinue(tpl)
    local
      Absyn.Path p; Interactive.CompiledCFunction i;
    case((p,i)) equation
      str = "{" +& Absyn.pathString(p) +& ", OPAQUE_VALUE}";
    then str;
  end matchcontinue;
end dumpTuple;

/* end of CevalHashTable instance specific code */

/* Generic hashtable code below!! */
public
uniontype CevalHashTable
  record HASHTABLE
    array<list<tuple<Key,Integer>>> hashTable " hashtable to translate Key to array indx" ;
    ValueArray valueArr "Array of values" ;
    Integer bucketSize "bucket size" ;
    Integer numberOfEntries "number of entries in hashtable" ;
  end HASHTABLE;
end CevalHashTable;

uniontype ValueArray
"array of values are expandable, to amortize the
 cost of adding elements in a more efficient manner"
  record VALUE_ARRAY
    Integer numberOfElements "number of elements in hashtable" ;
    Integer arrSize "size of crefArray" ;
    array<Option<tuple<Key,Value>>> valueArray "array of values";
  end VALUE_ARRAY;
end ValueArray;

public function cloneCevalHashTable
"Author BZ 2008-06
 Make a stand-alone-copy of hashtable."
input CevalHashTable inHash;
output CevalHashTable outHash;
algorithm outHash := matchcontinue(inHash)
  local
    array<list<tuple<Key,Integer>>> arg1,arg1_2;
    Integer arg3,arg4,arg3_2,arg4_2,arg21,arg21_2,arg22,arg22_2;
    array<Option<tuple<Key,Value>>> arg23,arg23_2;
  case(HASHTABLE(arg1,VALUE_ARRAY(arg21,arg22,arg23),arg3,arg4))
    equation
      arg1_2 = arrayCopy(arg1);
      arg21_2 = arg21;
      arg22_2 = arg22;
      arg23_2 = arrayCopy(arg23);
      arg3_2 = arg3;
      arg4_2 = arg4;
      then
        HASHTABLE(arg1_2,VALUE_ARRAY(arg21_2,arg22_2,arg23_2),arg3_2,arg4_2);
end matchcontinue;
end cloneCevalHashTable;

public function emptyCevalHashTable
"author: PA
  Returns an empty CevalHashTable.
  Using the bucketsize 100 and array size 10."
  output CevalHashTable hashTable;
  array<list<tuple<Key,Integer>>> arr;
  list<Option<tuple<Key,Value>>> lst;
  array<Option<tuple<Key,Value>>> emptyarr;
algorithm
  arr := arrayCreate(1000, {});
  emptyarr := arrayCreate(100, NONE());
  hashTable := HASHTABLE(arr,VALUE_ARRAY(0,100,emptyarr),1000,0);
end emptyCevalHashTable;

public function isEmpty "Returns true if hashtable is empty"
  input CevalHashTable hashTable;
  output Boolean res;
algorithm
  res := matchcontinue(hashTable)
    case(HASHTABLE(_,_,_,0)) then true;
    case(_) then false;
  end matchcontinue;
end isEmpty;

public function add
"author: PA
  Add a Key-Value tuple to hashtable.
  If the Key-Value tuple already exists, the function updates the Value."
  input tuple<Key,Value> entry;
  input CevalHashTable hashTable;
  output CevalHashTable outHashTable;
algorithm
  outHashTable := matchcontinue (entry,hashTable)
    local
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      ValueArray varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      array<list<tuple<Key,Integer>>> hashvec_1,hashvec;
      String name_str;
      tuple<Key,Value> v,newv;
      Key key;
      Value value;
      /* Adding when not existing previously */
    case ((v as (key,value)),(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation
        failure((_) = get(key, hashTable));
        hval = hashFunc(key);
        indx = intMod(hval, bsize);
        newpos = valueArrayLength(varr);
        varr_1 = valueArrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, ((key,newpos) :: indexes));
        n_1 = valueArrayLength(varr_1);
      then HASHTABLE(hashvec_1,varr_1,bsize,n_1);

      /* adding when already present => Updating value */
    case ((newv as (key,value)),(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation
        (_,indx) = get1(key, hashTable);
        //print("adding when present, indx =" );print(intString(indx));print("\n");
        indx_1 = indx - 1;
        varr_1 = valueArraySetnth(varr, indx, newv);
      then HASHTABLE(hashvec,varr_1,bsize,n);
    case (_,_)
      equation
        print("- CevalHashTable.add failed\n");
      then
        fail();
  end matchcontinue;
end add;

public function addNoUpdCheck
"author: PA
  Add a Key-Value tuple to hashtable.
  If the Key-Value tuple already exists, the function updates the Value."
  input tuple<Key,Value> entry;
  input CevalHashTable hashTable;
  output CevalHashTable outHashTable;
algorithm
  outHashTable := matchcontinue (entry,hashTable)
    local
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      ValueArray varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      array<list<tuple<Key,Integer>>> hashvec_1,hashvec;
      String name_str;
      tuple<Key,Value> v,newv;
      Key key;
      Value value;
    // Adding when not existing previously
    case ((v as (key,value)),(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation
        hval = hashFunc(key);
        indx = intMod(hval, bsize);
        newpos = valueArrayLength(varr);
        varr_1 = valueArrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, ((key,newpos) :: indexes));
        n_1 = valueArrayLength(varr_1);
      then HASHTABLE(hashvec_1,varr_1,bsize,n_1);
    case (_,_)
      equation
        print("- CevalHashTable.addNoUpdCheck failed\n");
      then
        fail();
  end matchcontinue;
end addNoUpdCheck;

public function delete
"author: PA
  delete the Value associatied with Key from the CevalHashTable.
  Note: This function does not delete from the index table, only from the ValueArray.
  This means that a lot of deletions will not make the CevalHashTable more compact, it
  will still contain a lot of incices information."
  input Key key;
  input CevalHashTable hashTable;
  output CevalHashTable outHashTable;
algorithm
  outHashTable := matchcontinue (key,hashTable)
    local
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      ValueArray varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      array<list<tuple<Key,Integer>>> hashvec_1,hashvec;
      String name_str;
      tuple<Key,Value> v,newv;
      Key key;
      Value value;
    // adding when already present => Updating value
    case (key,(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation
        (_,indx) = get1(key, hashTable);
        indx_1 = indx - 1;
        varr_1 = valueArrayClearnth(varr, indx);
      then HASHTABLE(hashvec,varr_1,bsize,n);
    case (_,hashTable)
      equation
        print("-CevalHashTable.delete failed\n");
        print("content:"); dumpCevalHashTable(hashTable);
      then
        fail();
  end matchcontinue;
end delete;

public function get
"author: PA
  Returns a Value given a Key and a CevalHashTable."
  input Key key;
  input CevalHashTable hashTable;
  output Value value;
algorithm
  (value,_):= get1(key,hashTable);
end get;

public function get1 "help function to get"
  input Key key;
  input CevalHashTable hashTable;
  output Value value;
  output Integer indx;
algorithm
  (value,indx):= matchcontinue (key,hashTable)
    local
      Integer hval,hashindx,indx_1,bsize,n;
      list<tuple<Key,Integer>> indexes;
      Value v;
      array<list<tuple<Key,Integer>>> hashvec;
      ValueArray varr;
      Key key2;
    case (key,(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation
        hval = hashFunc(key);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = get2(key, indexes);
        v = valueArrayNth(varr, indx);
      then
        (v,indx);
  end matchcontinue;
end get1;

public function get2
"author: PA
  Helper function to get"
  input Key key;
  input list<tuple<Key,Integer>> keyIndices;
  output Integer index;
algorithm
  index := matchcontinue (key,keyIndices)
    local
      Key key2;
      Value res;
      list<tuple<Key,Integer>> xs;
    case (key,((key2,index) :: _))
      equation
        true = keyEqual(key, key2);
      then
        index;
    case (key,(_ :: xs))
      equation
        index = get2(key, xs);
      then
        index;
  end matchcontinue;
end get2;

public function hashTableValueList "return the Value entries as a list of Values"
  input CevalHashTable hashTable;
  output list<Value> valLst;
algorithm
   valLst := Util.listMap(hashTableList(hashTable),Util.tuple22);
end hashTableValueList;

public function hashTableKeyList "return the Key entries as a list of Keys"
  input CevalHashTable hashTable;
  output list<Key> valLst;
algorithm
   valLst := Util.listMap(hashTableList(hashTable),Util.tuple21);
end hashTableKeyList;

public function hashTableList "returns the entries in the hashTable as a list of tuple<Key,Value>"
  input CevalHashTable hashTable;
  output list<tuple<Key,Value>> tplLst;
algorithm
  tplLst := matchcontinue(hashTable)
  local ValueArray varr;
    case(HASHTABLE(valueArr = varr)) equation
      tplLst = valueArrayList(varr);
    then tplLst;
  end matchcontinue;
end hashTableList;

public function valueArrayList
"author: PA
  Transforms a ValueArray to a tuple<Key,Value> list"
  input ValueArray valueArray;
  output list<tuple<Key,Value>> tplLst;
algorithm
  tplLst := matchcontinue (valueArray)
    local
      array<Option<tuple<Key,Value>>> arr;
      tuple<Key,Value> elt;
      Integer lastpos,n,size;
      list<tuple<Key,Value>> lst;
    case (VALUE_ARRAY(numberOfElements = 0,valueArray = arr)) then {};
    case (VALUE_ARRAY(numberOfElements = 1,valueArray = arr))
      equation
        SOME(elt) = arr[0 + 1];
      then
        {elt};
    case (VALUE_ARRAY(numberOfElements = n,arrSize = size,valueArray = arr))
      equation
        lastpos = n - 1;
        lst = valueArrayList2(arr, 0, lastpos);
      then
        lst;
  end matchcontinue;
end valueArrayList;

public function valueArrayList2 "Helper function to valueArrayList"
  input array<Option<tuple<Key,Value>>> inVarOptionArray1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<tuple<Key,Value>> outVarLst;
algorithm
  outVarLst := matchcontinue (inVarOptionArray1,inInteger2,inInteger3)
    local
      tuple<Key,Value> v;
      array<Option<tuple<Key,Value>>> arr;
      Integer pos,lastpos,pos_1;
      list<tuple<Key,Value>> res;
    case (arr,pos,lastpos)
      equation
        (pos == lastpos) = true;
        SOME(v) = arr[pos + 1];
      then
        {v};
    case (arr,pos,lastpos)
      equation
        pos_1 = pos + 1;
        SOME(v) = arr[pos + 1];
        res = valueArrayList2(arr, pos_1, lastpos);
      then
        (v :: res);
    case (arr,pos,lastpos)
      equation
        pos_1 = pos + 1;
        NONE() = arr[pos + 1];
        res = valueArrayList2(arr, pos_1, lastpos);
      then
        (res);
  end matchcontinue;
end valueArrayList2;

public function valueArrayLength
"author: PA
  Returns the number of elements in the ValueArray"
  input ValueArray valueArray;
  output Integer size;
algorithm
  size := matchcontinue (valueArray)
    case (VALUE_ARRAY(numberOfElements = size)) then size;
  end matchcontinue;
end valueArrayLength;

public function valueArrayAdd
"function: valueArrayAdd
  author: PA
  Adds an entry last to the ValueArray, increasing
  array size if no space left by factor 1.4"
  input ValueArray valueArray;
  input tuple<Key,Value> entry;
  output ValueArray outValueArray;
algorithm
  outValueArray := matchcontinue (valueArray,entry)
    local
      Integer n_1,n,size,expandsize,expandsize_1,newsize;
      array<Option<tuple<Key,Value>>> arr_1,arr,arr_2;
      Real rsize,rexpandsize;
    case (VALUE_ARRAY(numberOfElements = n,arrSize = size,valueArray = arr),entry)
      equation
        (n < size) = true "Have space to add array elt." ;
        n_1 = n + 1;
        arr_1 = arrayUpdate(arr, n + 1, SOME(entry));
      then
        VALUE_ARRAY(n_1,size,arr_1);

    case (VALUE_ARRAY(numberOfElements = n,arrSize = size,valueArray = arr),entry)
      equation
        (n < size) = false "Do NOT have splace to add array elt. Expand with factor 1.4" ;
        rsize = intReal(size);
        rexpandsize = rsize *. 0.4;
        expandsize = realInt(rexpandsize);
        expandsize_1 = intMax(expandsize, 1);
        newsize = expandsize_1 + size;
        arr_1 = Util.arrayExpand(expandsize_1, arr,NONE());
        n_1 = n + 1;
        arr_2 = arrayUpdate(arr_1, n + 1, SOME(entry));
      then
        VALUE_ARRAY(n_1,newsize,arr_2);
    case (_,_)
      equation
        print("-CevalHashTable.valueArrayAdd failed\n");
      then
        fail();
  end matchcontinue;
end valueArrayAdd;

public function valueArraySetnth
"function: valueArraySetnth
  author: PA
  Set the n:th variable in the ValueArray to value."
  input ValueArray valueArray;
  input Integer pos;
  input tuple<Key,Value> entry;
  output ValueArray outValueArray;
algorithm
  outValueArray := matchcontinue (valueArray,pos,entry)
    local
      array<Option<tuple<Key,Value>>> arr_1,arr;
      Integer n,size,pos;
    case (VALUE_ARRAY(n,size,arr),pos,entry)
      equation
        (pos < size) = true;
        arr_1 = arrayUpdate(arr, pos + 1, SOME(entry));
      then
        VALUE_ARRAY(n,size,arr_1);
    case (_,_,_)
      equation
        print("-CevalHashTable.valueArraySetnth failed\n");
      then
        fail();
  end matchcontinue;
end valueArraySetnth;

public function valueArrayClearnth
"author: PA
  Clears the n:th variable in the ValueArray (set to NONE())."
  input ValueArray valueArray;
  input Integer pos;
  output ValueArray outValueArray;
algorithm
  outValueArray := matchcontinue (valueArray,pos)
    local
      array<Option<tuple<Key,Value>>> arr_1,arr;
      Integer n,size,pos;
    case (VALUE_ARRAY(n,size,arr),pos)
      equation
        (pos < size) = true;
        arr_1 = arrayUpdate(arr, pos + 1,NONE());
      then
        VALUE_ARRAY(n,size,arr_1);
    case (_,_)
      equation
        print("-CevalHashTable.valueArrayClearnth failed\n");
      then
        fail();
  end matchcontinue;
end valueArrayClearnth;

public function valueArrayNth
"function: valueArrayNth
  author: PA
  Retrieve the n:th Vale from ValueArray, index from 0..n-1."
  input ValueArray valueArray;
  input Integer pos;
  output Value value;
algorithm
  value := matchcontinue (valueArray,pos)
    local
      Value v;
      Integer n,pos,len;
      array<Option<tuple<Key,Value>>> arr;
      String ps,lens,ns;
    case (VALUE_ARRAY(numberOfElements = n,valueArray = arr),pos)
      equation
        (pos < n) = true;
        SOME((_,v)) = arr[pos + 1];
      then
        v;
    case (VALUE_ARRAY(numberOfElements = n,valueArray = arr),pos)
      equation
        (pos < n) = true;
        NONE() = arr[pos + 1];
      then
        fail();
  end matchcontinue;
end valueArrayNth;


protected function cevalReductionIterators
  input Env.Cache cache;
  input Env.Env env;
  input list<DAE.ReductionIterator> iterators;
  input Boolean impl;
  input Option<Interactive.SymbolTable> st;
  input Msg msg;
  output Env.Cache outCache;
  output list<list<Values.Value>> vals;
  output list<String> names;
  output list<Integer> dims;
  output list<DAE.Type> tys;
  output Option<Interactive.SymbolTable> outSt;
algorithm
  (outCache,vals,names,dims,tys,outSt) := match (cache,env,iterators,impl,st,msg)
    local
      Values.Value val;
      list<Values.Value> iterVals;
      Integer dim;
      DAE.Type ty;
      String id;
      DAE.Exp exp;
      Option<DAE.Exp> guardExp;
    case (cache,env,{},_,st,_) then (cache,{},{},{},{},st);
    case (cache,env,DAE.REDUCTIONITER(id,exp,guardExp,ty)::iterators,impl,st,msg)
      equation
        (cache,val,st) = ceval(cache,env,exp,impl,st,msg);
        iterVals = ValuesUtil.arrayOrListVals(val,true);
        (cache,iterVals,st) = filterReductionIterator(cache,env,id,ty,iterVals,guardExp,impl,st,msg);
        dim = listLength(iterVals);
        (cache,vals,names,dims,tys,st) = cevalReductionIterators(cache,env,iterators,impl,st,msg);
      then (cache,iterVals::vals,id::names,dim::dims,ty::tys,st);
  end match;
end cevalReductionIterators;

protected function filterReductionIterator
  input Env.Cache cache;
  input Env.Env env;
  input String id;
  input DAE.Type ty;
  input list<Values.Value> vals;
  input Option<DAE.Exp> guardExp;
  input Boolean impl;
  input Option<Interactive.SymbolTable> st;
  input Msg msg;
  output Env.Cache outCache;
  output list<Values.Value> outVals;
  output Option<Interactive.SymbolTable> outSt;
algorithm
  (outCache,outVals,outSt) := match (cache,env,id,ty,vals,guardExp,impl,st,msg)
    local
      DAE.Exp exp;
      Values.Value val;
      Boolean b;
      Env.Env new_env;
    case (cache,env,_,_,{},_,_,st,_) then (cache,{},st);
    case (cache,env,id,ty,val::vals,SOME(exp),impl,st,msg)
      equation
        new_env = Env.extendFrameForIterator(env, id, ty, DAE.VALBOUND(val, DAE.BINDING_FROM_DEFAULT_VALUE()), SCode.VAR(), SOME(DAE.C_CONST()));
        (cache,Values.BOOL(b),st) = ceval(cache,new_env,exp,impl,st,msg);
        (cache,vals,st) = filterReductionIterator(cache,env,id,ty,vals,guardExp,impl,st,msg);
        vals = Util.if_(b, val::vals, vals);
      then (cache,vals,st);
    case (cache,env,_,_,vals,NONE(),_,st,_) then (cache,vals,st);
  end match;
end filterReductionIterator;

protected function extendFrameForIterators
  input Env.Env env;
  input list<String> names;
  input list<Values.Value> vals;
  input list<DAE.Type> tys;
  output Env.Env outEnv;
algorithm
  outEnv := match (env,names,vals,tys)
    local
      String name;
      Values.Value val;
      DAE.Type ty;
    case (env,{},{},{}) then env;
    case (env,name::names,val::vals,ty::tys)
      equation
        env = Env.extendFrameForIterator(env, name, ty, DAE.VALBOUND(val, DAE.BINDING_FROM_DEFAULT_VALUE()), SCode.VAR(), SOME(DAE.C_CONST()));
        env = extendFrameForIterators(env,names,vals,tys);
      then env;
  end match;
end extendFrameForIterators;

protected function backpatchArrayReduction
  input Absyn.Path path;
  input Values.Value value;
  input list<Integer> dims;
  output Values.Value outValue;
algorithm
  outValue := match (path,value,dims)
    local
      Integer dim;
      list<Values.Value> vals;
    case (_,value,{_}) then value;
    case (Absyn.IDENT("array"),Values.ARRAY(valueLst=vals),dims)
      equation
        value = backpatchArrayReduction3(vals,listReverse(dims));
        // print(ValuesUtil.valString(value));print("\n");
      then value;
    else value;
  end match;
end backpatchArrayReduction;

protected function backpatchArrayReduction3
  input list<Values.Value> vals;
  input list<Integer> dims;
  output Values.Value outValue;
algorithm
  outValue := match (vals,dims)
    local
      Integer dim;
      list<list<Values.Value>> valMatrix;
      Values.Value value;
    case (vals,{dim}) then ValuesUtil.makeArray(vals);
    case (vals,dim::dims)
      equation
        // Split into the smallest of the arrays
        // print("into sublists of length: " +& intString(dim) +& " from length=" +& intString(listLength(vals)) +& "\n");
        valMatrix = Util.listPartition(vals,dim);
        // print("output has length=" +& intString(listLength(valMatrix)) +& "\n");
        vals = Util.listMap(valMatrix,ValuesUtil.makeArray);
        value = backpatchArrayReduction3(vals,dims);
      then value;
  end match;
end backpatchArrayReduction3;

public function cevalSimple
  "A simple expression does not need cache, etc"
  input DAE.Exp exp;
  output Values.Value val;
algorithm
  (_,val,_) := ceval(Env.emptyCache(),{},exp,false,NONE(),MSG(Absyn.dummyInfo));
end cevalSimple;

end Ceval;

