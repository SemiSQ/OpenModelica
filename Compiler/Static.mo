package Static "
This file is part of OpenModelica.

Copyright (c) 1998-2006, Link�pings universitet, Department of
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

  
  file:	 Static.mo
  module:      Static
  description: Static analysis of expressions
 
  RCS: $Id$
  
  This module does static analysis on expressions.
  The analyzed expressions are built using the
  constructors in the `Exp\' module from expressions defined in \'Absyn\'.  
  Also, a set of properties of the expressions is calculated during analysis.
  Properties of expressions include type information and a boolean indicating if the
  expression is constant or not.
  If the expression is constant, the \'Ceval\' module is used to evaluate the expression
  value. A value of an expression is described using the \'Values\' module.

  The main function in this module is \'eval_exp\' which takes an Absyn.Exp and transform it 
  into an Exp.Exp, while performing type checking and automatic type conversions, etc.
  To determine types of builtin functions and operators, the module also contain an elaboration
  handler for functions and operators. This function is called \'elab_builtin_handler\'. 
  NOTE: These functions should only determine the type and properties of the builtin functions and
  operators and not evaluate them. Constant evaluation is performed by the \'Ceval\' module.
  The module also contain a function for deoverloading of operators, in the \'deoverload\' function.
  It transforms operators like \'+\' to its specific form, ADD, ADD_ARR, etc.
 
  Interactive function calls are also given their types by \'elab_exp\', which calls 
  \'elab_call_interactive\'.
 
  Elaboration for functions involve checking the types of the arguments by filling slots of the
  argument list with first positional and then named arguments to find a matching function. The 
  details of this mechanism can be found in the Modelica specification.
  The elaboration also contain function deoverloading which will be added to Modelica in the future.
"

public import Absyn;
public import Exp;
public import SCode;
public import Types;
public import Env;
public import Values;
public import Interactive;

public 
type Ident = String;

public 
uniontype Slot
  record SLOT
    Types.FuncArg an "An argument to a function" ;
    Boolean true_ "True if the slot has been filled, i.e. argument has been given a value" ;
    Option<Exp.Exp> expExpOption;
    list<Types.ArrayDim> typesArrayDimLst;
  end SLOT;

end Slot;

protected import ClassInf;
protected import Dump;
protected import Print;
protected import System;
protected import Lookup;
protected import Debug;
protected import Inst;
protected import Codegen;
protected import ModUtil;
protected import DAE;
protected import Util;
protected import Mod;
protected import Prefix;
protected import Ceval;
protected import Connect;
protected import Error;

public function elabExpList "Expression elaboration of Absyn.Exp list, i.e. lists of expressions."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean performVectorization;
  output Env.Cache outCache;
  output list<Exp.Exp> outExpExpLst;
  output list<Types.Properties> outTypesPropertiesLst;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outExpExpLst,outTypesPropertiesLst,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,performVectorization)
    local
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st,st_1,st_2;
      Exp.Exp exp;
      Types.Properties p;
      list<Exp.Exp> exps;
      list<Types.Properties> props;
      list<Env.Frame> env;
      Absyn.Exp e;
      list<Absyn.Exp> rest;
      Env.Cache cache;
      Boolean doVect;
    case (cache,_,{},impl,st,doVect) then (cache,{},{},st); 
    case (cache,env,(e :: rest),impl,st,doVect)
      equation 
        (cache,exp,p,st_1) = elabExp(cache,env, e, impl, st,doVect);
        (cache,exps,props,st_2) = elabExpList(cache,env, rest, impl, st_1,doVect);
      then
        (cache,(exp :: exps),(p :: props),st_2);
  end matchcontinue;
end elabExpList;

public function elabExpListList "function: elabExpListList
 
  Expression elaboration of lists of lists of expressions. Used in for 
  instance matrices, etc.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<list<Absyn.Exp>> inAbsynExpLstLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean performVectorization;
  output Env.Cache outCache;
  output list<list<Exp.Exp>> outExpExpLstLst;
  output list<list<Types.Properties>> outTypesPropertiesLstLst;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outExpExpLstLst,outTypesPropertiesLstLst,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inAbsynExpLstLst,inBoolean,inInteractiveInteractiveSymbolTableOption,performVectorization)
    local
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st,st_1,st_2;
      list<Exp.Exp> exp;
      list<Types.Properties> p;
      list<list<Exp.Exp>> exps;
      list<list<Types.Properties>> props;
      list<Env.Frame> env;
      list<Absyn.Exp> e;
      list<list<Absyn.Exp>> rest;
      Env.Cache cache;
      Boolean doVect;
    case (cache,_,{},impl,st,doVect) then (cache,{},{},st); 
    case (cache,env,(e :: rest),impl,st,doVect)
      equation 
        (cache,exp,p,st_1) = elabExpList(cache,env, e, impl, st,doVect);
        (cache,exps,props,st_2) = elabExpListList(cache,env, rest, impl, st_1,doVect);
      then
        (cache,(exp :: exps),(p :: props),st_2);
  end matchcontinue;
end elabExpListList;

protected function cevalIfConstant "function: cevalIfConstant
 
  This function calls Ceval.ceval if the Constant parameter indicates
  C_CONST. If not constant, it also tries to simplify the expression using
  Exp.simplify
"
	input Env.Cache inCache;
  input Exp.Exp inExp;
  input Types.Properties inProperties;
  input Types.Const inConst;
  input Boolean inBoolean;
  input Env.Env inEnv;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inExp,inProperties,inConst,inBoolean,inEnv)
    local
      Exp.Exp e_1,e;
      String before, after;
      Types.Properties prop;
      Boolean impl;
      Values.Value v;
      tuple<Types.TType, Option<Absyn.Path>> vt;
      Types.Const c,const;
      list<Env.Frame> env;
      Env.Cache cache;
    case (cache,e,prop,Types.C_VAR(),_,_) /* impl */ 
      equation 
        e_1 = Exp.simplify(e);
      then
        (cache,e_1,prop);
    case (cache,e,prop,Types.C_PARAM(),_,_)
      equation 
        e_1 = Exp.simplify(e);
      then
        (cache,e_1,prop);
    case (cache,e,prop,Types.C_CONST(),(impl as true),_)
      equation 
        e_1 = Exp.simplify(e);
      then
        (cache,e_1,prop);
    case (cache,e,(prop as Types.PROP(constFlag = c)),Types.C_CONST(),impl,env) /* as false */ 
      equation 
        (cache,v,_) = Ceval.ceval(cache,env, e, impl, NONE, NONE, Ceval.MSG());
        e_1 = valueExp(v);
        vt = valueType(v);
      then
        (cache,e_1,Types.PROP(vt,c));
       
    case (cache,e,(prop as Types.PROP_TUPLE(tupleConst = c)),Types.C_CONST(),impl,env) /* as false */ 
      local Types.TupleConst c;
      equation 
        (cache,v,_) = Ceval.ceval(cache,env, e, impl, NONE, NONE, Ceval.MSG());
        e_1 = valueExp(v);
        vt = valueType(v);
      then
        (cache,e_1,Types.PROP_TUPLE(vt,c));
    case (cache,e,prop,const,impl,env)
      equation 
        e_1 = Exp.simplify(e);
      then
        (cache,e_1,prop);
  end matchcontinue;
end cevalIfConstant;

public function elabExp "function: elabExp
 
  Static analysis of expressions means finding out the properties of
  the expression.  These properties are described by the
  `Types.Properties\' type, and include the type and the variability of the
  expression.  This function performs analysis, and returns an
  `Exp.Exp\' and the properties.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Exp inExp;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean performVectorization;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outExp,outProperties,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inInteractiveInteractiveSymbolTableOption,performVectorization)
    local
      Integer x,l,nmax;
      Option<Integer> dim1,dim2;
      Boolean impl,a,havereal;
      Option<Interactive.InteractiveSymbolTable> st,st_1,st_2,st_3;
      Ident id,expstr,envstr;
      Exp.Exp exp,e1_1,e2_1,e1_2,e2_2,exp_1,exp_2,e_1,e_2,e3_1,start_1,stop_1,start_2,stop_2,step_1,step_2,mexp,mexp_1;
      Types.Properties prop,prop_1,prop1,prop2,prop3;
      list<Env.Frame> env;
      Absyn.ComponentRef cr,fn;
      tuple<Types.TType, Option<Absyn.Path>> t1,t2,rtype,t,start_t,stop_t,step_t,t_1,t_2,tp;
      Types.Const c1,c2,c,c_start,c_stop,const,c_step;
      list<tuple<Exp.Operator, list<tuple<Types.TType, Option<Absyn.Path>>>, tuple<Types.TType, Option<Absyn.Path>>>> ops;
      Exp.Operator op_1;
      Absyn.Exp e1,e2,e,e3,iterexp,start,stop,step;
      Absyn.Operator op;
      list<Absyn.Exp> args,rest,es;
      list<Absyn.NamedArg> nargs;
      list<Exp.Exp> es_1;
      list<Types.Properties> props;
      list<tuple<Types.TType, Option<Absyn.Path>>> types,tps_2;
      list<Types.TupleConst> consts;
      Exp.Type rt,at,tp_1;
      list<list<Types.Properties>> tps;
      list<list<tuple<Types.TType, Option<Absyn.Path>>>> tps_1;
      Env.Cache cache;
      Boolean doVect;
            /* The types below should contain the default values of the attributes of the builtin
       types. But since they are default, we can leave them out for now, unit=\"\" is not 
       that interesting to find out.
       */ 
    case (cache,_,Absyn.INTEGER(value = x),impl,st,doVect) then (cache,Exp.ICONST(x),Types.PROP((Types.T_INTEGER({}),NONE),Types.C_CONST()),st);  

    case (cache,_,Absyn.REAL(value = x),impl,st,doVect)
      local Real x;
      then
        (cache,Exp.RCONST(x),Types.PROP((Types.T_REAL({}),NONE),Types.C_CONST()),st);

    case (cache,_,Absyn.STRING(value = x),impl,st,doVect)
      local Ident x;
      then
        (cache,Exp.SCONST(x),Types.PROP((Types.T_STRING({}),NONE),Types.C_CONST()),st);

    case (cache,_,Absyn.BOOL(value = x),impl,st,doVect)
      local Boolean x;
      then
        (cache,Exp.BCONST(x),Types.PROP((Types.T_BOOL({}),NONE),Types.C_CONST()),st);

    case (cache,_,Absyn.END(),impl,st,doVect) 
    then (cache,Exp.END(),Types.PROP((Types.T_INTEGER({}),NONE),Types.C_CONST()),st); 
      
    case (cache,env,Absyn.CREF(componentReg = cr),impl,st,doVect)
      equation 
        (cache,exp,prop,_) = elabCref(cache,env, cr, impl,doVect);
      then
        (cache,exp,prop,st);
    case (cache,env,(exp as Absyn.BINARY(exp1 = e1,op = op,exp2 = e2)),impl,st,doVect) /* Binary and unary operations */ 
      local Absyn.Exp exp;
      equation 
        (cache,e1_1,Types.PROP(t1,c1),st_1) = elabExp(cache,env, e1, impl, st,doVect);
        (cache,e2_1,Types.PROP(t2,c2),st_2) = elabExp(cache,env, e2, impl, st_1,doVect);
        c = Types.constAnd(c1, c2);
        (cache,ops) = operators(cache,op, env, t1, t2);
        (op_1,{e1_2,e2_2},rtype) = deoverload(ops, {(e1_1,t1),(e2_1,t2)}, exp);
        exp_1 = replaceOperatorWithFcall(Exp.BINARY(e1_2,op_1,e2_2), c);
        prop = Types.PROP(rtype,c);
        (cache,exp_2,prop_1) = cevalIfConstant(cache,exp_1, prop, c, impl, env);
      then
        (cache,exp_2,prop_1,st_2);
    case (cache,env,(exp as Absyn.UNARY(op = op,exp = e)),impl,st,doVect)
      local Absyn.Exp exp;
      equation 
        (cache,e_1,Types.PROP(t,c),st_1) = elabExp(cache,env, e, impl, st,doVect);
        (cache,ops) = operators(cache,op, env, t, (Types.T_NOTYPE(),NONE));
        (op_1,{e_2},rtype) = deoverload(ops, {(e_1,t)}, exp);
        exp_1 = replaceOperatorWithFcall(Exp.UNARY(op_1,e_2), c);
        prop = Types.PROP(rtype,c);
        (cache,exp_2,prop_1) = cevalIfConstant(cache,exp_1, prop, c, impl, env);
      then
        (cache,exp_2,prop_1,st_1);
    case (cache,env,(exp as Absyn.LBINARY(exp1 = e1,op = op,exp2 = e2)),impl,st,doVect)
      local Absyn.Exp exp;
      equation 
        (cache,e1_1,Types.PROP(t1,c1),st_1) = elabExp(cache,env, e1, impl, st,doVect) "Logical binary expressions" ;
        (cache,e2_1,Types.PROP(t2,c2),st_2) = elabExp(cache,env, e2, impl, st_1,doVect);
        c = Types.constAnd(c1, c2);
        (cache,ops) = operators(cache,op, env, t1, t2);
        (op_1,{e1_2,e2_2},rtype) = deoverload(ops, {(e1_1,t1),(e2_1,t2)}, exp);
        exp_1 = replaceOperatorWithFcall(Exp.LBINARY(e1_2,op_1,e2_2), c);
        prop = Types.PROP(rtype,c);
        (cache,exp_2,prop_1) = cevalIfConstant(cache,exp_1, prop, c, impl, env);
      then
        (cache,exp_2,prop_1,st_2);
    case (cache,env,(exp as Absyn.LUNARY(op = op,exp = e)),impl,st,doVect)
      local Absyn.Exp exp;
      equation 
        (cache,e_1,Types.PROP(t,c),st_1) = elabExp(cache,env, e, impl, st,doVect) "Logical unary expressions" ;
        (cache,ops) = operators(cache,op, env, t, (Types.T_NOTYPE(),NONE));
        (op_1,{e_2},rtype) = deoverload(ops, {(e_1,t)}, exp);
        exp_1 = replaceOperatorWithFcall(Exp.LUNARY(op_1,e_2), c);
        prop = Types.PROP(rtype,c);
        (cache,exp_2,prop_1) = cevalIfConstant(cache,exp_1, prop, c, impl, env);
      then
        (cache,exp_2,prop_1,st_1);
    case (cache,env,(exp as Absyn.RELATION(exp1 = e1,op = op,exp2 = e2)),impl,st,doVect)
      local Absyn.Exp exp;
      equation 
        (cache,e1_1,Types.PROP(t1,c1),st_1) = elabExp(cache,env, e1, impl, st,doVect) "Relations, e.g. a < b" ;
        (cache,e2_1,Types.PROP(t2,c2),st_2) = elabExp(cache,env, e2, impl, st_1,doVect);
        c = Types.constAnd(c1, c2);
        (cache,ops) = operators(cache,op, env, t1, t2);
        (op_1,{e1_2,e2_2},rtype) = deoverload(ops, {(e1_1,t1),(e2_1,t2)}, exp);
        exp_1 = replaceOperatorWithFcall(Exp.RELATION(e1_2,op_1,e2_2), c);
        prop = Types.PROP(rtype,c);
        (cache,exp_2,prop_1) = cevalIfConstant(cache,exp_1, prop, c, impl, env);
      then
        (cache,exp_2,prop_1,st_2);
    case (cache,env,Absyn.IFEXP(ifExp = e1,trueBranch = e2,elseBranch = e3),impl,st,doVect) /* Conditional expressions */ 
      local Exp.Exp e;
      equation 
        (cache,e1_1,prop1,st_1) = elabExp(cache,env, e1, impl, st,doVect) "if expressions" ;
        (cache,e2_1,prop2,st_2) = elabExp(cache,env, e2, impl, st_1,doVect);
        (cache,e3_1,prop3,st_3) = elabExp(cache,env, e3, impl, st_2,doVect);
        (cache,e,prop) = elabIfexp(cache,env, e1_1, prop1, e2_1, prop2, e3_1, prop3, impl, st);
         /* TODO elseif part */ 
      then
        (cache,e,prop,st_3);
    case (cache,env,Absyn.CALL(function_ = fn,functionArgs = Absyn.FUNCTIONARGS(args = args,argNames = nargs)),impl,st,doVect)
      local Exp.Exp e;
      equation 
        Debug.fprintln("sei", "elab_exp CALL...") "Function calls PA. Only positional arguments are elaborated for now. TODO: Implement elaboration of named arguments." ;
        (cache,e,prop,st_1) = elabCall(cache,env, fn, args, nargs, impl, st);
        c = Types.propAllConst(prop);
        (cache,e_1,prop_1) = cevalIfConstant(cache,e, prop, c, impl, env);
        Debug.fprintln("sei", "elab_exp CALL done");
      then
        (cache,e_1,prop_1,st_1);
    case (cache,env,Absyn.TUPLE(expressions = (e as (e1 :: rest))),impl,st,doVect) /* PR. Get the properties for each expression in the tuple. 
	 Each expression has its own constflag.
	 !!The output from functions does just have one const flag. 
	 Fix this!!
	 */ 
      local
        list<Exp.Exp> e_1;
        list<Absyn.Exp> e;
      equation 
        (cache,e_1,props) = elabTuple(cache,env, e, impl,doVect) "Tuple function calls" ;
        (types,consts) = splitProps(props);
      then
        (cache,Exp.TUPLE(e_1),Types.PROP_TUPLE((Types.T_TUPLE(types),NONE),Types.TUPLE_CONST(consts)),st);
    case (cache,env,Absyn.CALL(function_ = fn,functionArgs = Absyn.FOR_ITER_FARG(from = exp,var = id,to = iterexp)),impl,st,doVect) /* Array-related expressions Elab reduction expressions, including array() constructor */ 
      local
        Exp.Exp e;
        Absyn.Exp exp;
      equation 
        (cache,e,prop,st_1) = elabCallReduction(cache,env, fn, exp, id, iterexp, impl, st,doVect);
      then
        (cache,e,prop,st_1);
    case (cache,env,Absyn.RANGE(start = start,step = NONE,stop = stop),impl,st,doVect)
      equation 
        (cache,start_1,Types.PROP(start_t,c_start),st_1) = elabExp(cache,env, start, impl, st,doVect) "Range expressions without step value, e.g. 1:5" ;
        (cache,stop_1,Types.PROP(stop_t,c_stop),st_2) = elabExp(cache,env, stop, impl, st_1,doVect);
        (start_2,NONE,stop_2,rt) = deoverloadRange((start_1,start_t), NONE, (stop_1,stop_t));
        const = Types.constAnd(c_start, c_stop);
        (cache,t) = elabRangeType(cache,env, start_2, NONE, stop_2, const, rt, impl);
      then 
        (cache,Exp.RANGE(rt,start_1,NONE,stop_1),Types.PROP(t,const),st_2);
    case (cache,env,Absyn.RANGE(start = start,step = SOME(step),stop = stop),impl,st,doVect)
      equation 
        (cache,start_1,Types.PROP(start_t,c_start),st_1) = elabExp(cache,env, start, impl, st,doVect) "Range expressions with step value, e.g. 1:0.5:4" ;
        (cache,step_1,Types.PROP(step_t,c_step),st_2) = elabExp(cache,env, step, impl, st_1,doVect);
        (cache,stop_1,Types.PROP(stop_t,c_stop),st_3) = elabExp(cache,env, stop, impl, st_2,doVect);
        (start_2,SOME(step_2),stop_2,rt) = deoverloadRange((start_1,start_t), SOME((step_1,step_t)), (stop_1,stop_t));
        c1 = Types.constAnd(c_start, c_step);
        const = Types.constAnd(c1, c_stop);
        (cache,t) = elabRangeType(cache,env, start_2, SOME(step_2), stop_2, const, rt, impl);
      then
        (cache,Exp.RANGE(rt,start_2,SOME(step_2),stop_2),Types.PROP(t,const),st_3);
    case (cache,env,Absyn.ARRAY(arrayExp = es),impl,st,doVect)
      equation 
        (cache,es_1,Types.PROP(t,const)) = elabArray(cache,env, es, impl, st,doVect) "array expressions, e.g. {1,2,3}" ;
        l = listLength(es_1);
        at = Types.elabType(t);
        a = Types.isArray(t);
        a = boolNot(a); // scalar = !array
      then
        (cache,Exp.ARRAY(at,a,es_1),Types.PROP((Types.T_ARRAY(Types.DIM(SOME(l)),t),NONE),const),st);
    case (cache,env,Absyn.MATRIX(matrix = es),impl,st,doVect)
      local list<list<Absyn.Exp>> es;
        Integer d1,d2;
      equation 
        (cache,_,tps,_) = elabExpListList(cache,env, es, impl, st,doVect) "matrix expressions, e.g. {1,0;0,1} with elements of simple type." ;
        tps_1 = Util.listListMap(tps, Types.getPropType);
        tps_2 = Util.listFlatten(tps_1);
        nmax = matrixConstrMaxDim(tps_2);
        havereal = Types.containReal(tps_2);                
        (cache,mexp,Types.PROP(t,c),dim1,dim2) 
        	= elabMatrixSemi(cache,env, es, impl, st, havereal, nmax,doVect);
        mexp = Util.if_(havereal,Exp.CAST(Exp.T_ARRAY(Exp.REAL(),{dim1,dim2}),mexp)
        													 , mexp);
        mexp=Exp.simplify(mexp); // to propagate cast down to scalar elts
        mexp_1 = elabMatrixToMatrixExp(mexp);
        t_1 = Types.unliftArray(t);
        t_2 = Types.unliftArray(t_1) "All elts promoted to matrix, therefore unlifting" ;
      then
        (cache,mexp_1,Types.PROP(
          (
          Types.T_ARRAY(Types.DIM(dim1),
          (Types.T_ARRAY(Types.DIM(dim2),t_2),NONE)),NONE),c),st);
    case (cache,env,Absyn.CODE(code = c),impl,st,doVect)
      local Absyn.CodeNode c;
      equation 
        tp = elabCodeType(env, c) "Code expressions" ;
        tp_1 = Types.elabType(tp);
      then
        (cache,Exp.CODE(c,tp_1),Types.PROP(tp,Types.C_CONST()),st);
    case (cache,env,e,_,_,_)
      equation 
        Debug.fprint("failtrace", "- elab_exp failed: ");
        expstr = Debug.fcallret("failtrace", Dump.dumpExpStr, e, "");
        Debug.fprintln("failtrace", expstr);
        Debug.fprint("failtrace", "\n env : ");
        envstr = Debug.fcallret("failtrace", Env.printEnvStr, env, "");
        Debug.fprintln("failtrace", envstr);
        Debug.fprintln("failtrace", "\n----------------------- FINISHED ENV ------------------------\n");
      then
        fail();
  end matchcontinue;
end elabExp;

protected function elabMatrixGetDimensions "function: elabMatrixGetDimensions
 
  Helper function to elab_exp (MATRIX). Calculates the dimensions of the
  matrix by investigating the elaborated expression.
"
  input Exp.Exp inExp;
  output Integer outInteger1;
  output Integer outInteger2;
algorithm 
  (outInteger1,outInteger2):=
  matchcontinue (inExp)
    local
      Integer dim1,dim2;
      list<Exp.Exp> lst2,lst;
    case (Exp.ARRAY(array = lst))
      equation 
        dim1 = listLength(lst);
        (Exp.ARRAY(array = lst2) :: _) = lst;
        dim2 = listLength(lst2);
      then
        (dim1,dim2);
  end matchcontinue;
end elabMatrixGetDimensions;

protected function elabMatrixToMatrixExp "function: elabMatrixToMatrixExp
 
  Convert an array expression (which is a matrix or higher dim.) to 
  a matrix expression (using MATRIX).
"
  input Exp.Exp inExp;
  output Exp.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp)
    local
      list<list<tuple<Exp.Exp, Boolean>>> mexpl;
      Integer dim;
      Exp.Type a,elt_ty;
      Boolean at;
      Option<Integer> dim;
      Integer d1;
      list<Exp.Exp> expl;
      Exp.Exp e;
    case (Exp.ARRAY(ty = a,scalar = at,array = expl))
      equation 
        mexpl = elabMatrixToMatrixExp2(expl);
        d1 = listLength(mexpl); 
        a = Exp.liftArray(a,SOME(d1));
      then
        Exp.MATRIX(a,d1,mexpl);
    case (e) then e;  /* if fails, skip conversion, use generic array expression as is. */ 
  end matchcontinue;
end elabMatrixToMatrixExp;

protected function elabMatrixToMatrixExp2 "function: elabMatrixToMatrixExp2
 
  Helper function to elab_matrix_to_matrix_exp
"
  input list<Exp.Exp> inExpExpLst;
  output list<list<tuple<Exp.Exp, Boolean>>> outTplExpExpBooleanLstLst;
algorithm 
  (outTplExpExpBooleanLstLst):=
  matchcontinue (inExpExpLst)
    local
      list<tuple<Exp.Exp, Boolean>> expl_1;
      list<list<tuple<Exp.Exp, Boolean>>> es_1;
      Exp.Type a;
      Boolean at;
      list<Exp.Exp> expl,es;
    case ({}) then {}; 
    case ((Exp.ARRAY(ty = a,scalar = at,array = expl) :: es))
      equation 
        expl_1 = elabMatrixToMatrixExp3(expl);
        es_1 = elabMatrixToMatrixExp2(es);
      then
        expl_1 :: es_1;
  end matchcontinue;
end elabMatrixToMatrixExp2;

protected function elabMatrixToMatrixExp3
  input list<Exp.Exp> inExpExpLst;
  output list<tuple<Exp.Exp, Boolean>> outTplExpExpBooleanLst;
algorithm 
  outTplExpExpBooleanLst:=
  matchcontinue (inExpExpLst)
    local
      Exp.Type tp;
      Boolean scalar;
      Ident s;
      list<tuple<Exp.Exp, Boolean>> es_1;
      Exp.Exp e;
      list<Exp.Exp> es;
    case ({}) then {}; 
    case ((e :: es))
      equation 
        tp = Exp.typeof(e);
        scalar = Exp.typeBuiltin(tp);
        s = Util.boolString(scalar);
        es_1 = elabMatrixToMatrixExp3(es);
      then
        ((e,scalar) :: es_1);
  end matchcontinue;
end elabMatrixToMatrixExp3;

protected function matrixConstrMaxDim "function: matrixConstrMaxDim
 
  Helper function to elab_exp (MATRIX).
  Determines the maximum dimension of the array arguments to the matrix
  constructor as.
  max(2, ndims(A), ndims(B), ndims(C),..) for matrix constructor arguments
  A, B, C, ...
"
  input list<Types.Type> inTypesTypeLst;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inTypesTypeLst)
    local
      Integer tn,tn2,res;
      tuple<Types.TType, Option<Absyn.Path>> t;
      list<tuple<Types.TType, Option<Absyn.Path>>> ts;
    case ({}) then 2; 
    case ((t :: ts))
      equation 
        tn = Types.ndims(t);
        tn2 = matrixConstrMaxDim(ts);
        res = intMax(tn, tn2);
      then
        res;
    case (_)
      equation 
        Debug.fprint("failtrace", "-matrix_constr_max_dim failed\n");
      then
        fail();
  end matchcontinue;
end matrixConstrMaxDim;

protected function addForLoopScopeConst "function: addForLoopScopeConst 
 
  Creates a new scope on the environment used for loops and adds a loop 
  variable which is named by the second argument. The variable is given 
  the value 1 (one) such that elaboration of expressions of containing the 
  loop variable become constant.
"
  input Env.Env env;
  input Ident i;
  input Types.Type typ;
  output Env.Env env_2;
  list<Env.Frame> env_1,env_2;
algorithm 
  env_1 := Env.openScope(env, false, SOME("$for loop scope$")) "encapsulated?" ;
  env_2 := Env.extendFrameV(env_1, 
          Types.VAR(i,Types.ATTR(false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),
          false,typ,Types.VALBOUND(Values.INTEGER(1))), NONE, Env.VAR_UNTYPED(), {});
end addForLoopScopeConst;

protected function elabCallReduction "function: elabCallReduction
  
  This function elaborates reduction expressions, that look like function
  calls. For example an array constructor.
"
	input Env.Cache inCache;
  input Env.Env inEnv1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.Exp inExp3;
  input Ident inIdent4;
  input Absyn.Exp inExp5;
  input Boolean inBoolean6;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption7;
  input Boolean performVectorization;
	output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outExp,outProperties,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv1,inComponentRef2,inExp3,inIdent4,inExp5,inBoolean6,inInteractiveInteractiveSymbolTableOption7,performVectorization)
    local
      Exp.Exp iterexp_1,exp_1;
      Types.ArrayDim arraydim;
      tuple<Types.TType, Option<Absyn.Path>> iterty,expty;
      Types.Const iterconst,expconst,const;
      list<Env.Frame> env_1,env;
      Option<Interactive.InteractiveSymbolTable> st;
      Types.Properties prop;
      Absyn.Path fn_1;
      Absyn.ComponentRef fn;
      Absyn.Exp exp,iterexp;
      Ident iter;
      Boolean impl,doVect;
      Env.Cache cache;
    case (cache,env,fn,exp,iter,iterexp,impl,st,doVect)
      equation 
        (cache,iterexp_1,Types.PROP((Types.T_ARRAY((arraydim as Types.DIM(_)),iterty),_),iterconst),_) 
        	= elabExp(cache,env, iterexp, impl, st,doVect);
        env_1 = addForLoopScopeConst(env, iter, iterty);
        (cache,exp_1,Types.PROP(expty,expconst),st) = elabExp(cache,env_1, exp, impl, st,doVect) "const so that expr is elaborated to const" ;
        const = Types.constAnd(expconst, iterconst);
        prop = Types.PROP((Types.T_ARRAY(arraydim,expty),NONE),const);
        fn_1 = Absyn.crefToPath(fn);
      then
        (cache,Exp.REDUCTION(fn_1,exp_1,iter,iterexp_1),prop,st);
  end matchcontinue;
end elabCallReduction;

protected function replaceOperatorWithFcall "function: replaceOperatorWithFcall
 
  Replaces a userdefined operator expression with a corresponding function 
  call expression. Other expressions just passes through.
"
  input Exp.Exp inExp;
  input Types.Const inConst;
  output Exp.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp,inConst)
    local
      Exp.Exp e1,e2,e;
      Absyn.Path funcname;
      Types.Const c;
    case (Exp.BINARY(exp1 = e1,operator = Exp.USERDEFINED(fqName = funcname),exp2 = e2),c) then Exp.CALL(funcname,{e1,e2},false,false,Exp.OTHER()); 
    case (Exp.UNARY(operator = Exp.USERDEFINED(fqName = funcname),exp = e1),c) then Exp.CALL(funcname,{e1},false,false,Exp.OTHER()); 
    case (Exp.LBINARY(exp1 = e1,operator = Exp.USERDEFINED(fqName = funcname),exp2 = e2),c) then Exp.CALL(funcname,{e1,e2},false,false,Exp.OTHER()); 
    case (Exp.LUNARY(operator = Exp.USERDEFINED(fqName = funcname),exp = e1),c) then Exp.CALL(funcname,{e1},false,false,Exp.OTHER()); 
    case (Exp.RELATION(exp1 = e1,operator = Exp.USERDEFINED(fqName = funcname),exp2 = e2),c) then Exp.CALL(funcname,{e1,e2},false,false,Exp.OTHER()); 
    case (e,_) then e; 
  end matchcontinue;
end replaceOperatorWithFcall;

protected function elabCodeType "function: elabCodeType
 
  This function will construct the correct type for the given Code 
  expression. The types are built-in classes of different types. E.g. 
  the class TypeName is the type
  of Code expressions corresponding to a type name Code expression. 
"
  input Env.Env inEnv;
  input Absyn.CodeNode inCode;
  output Types.Type outType;
algorithm 
  outType:=
  matchcontinue (inEnv,inCode)
    local list<Env.Frame> env;
    case (env,Absyn.C_TYPENAME(path = _)) then ((Types.T_COMPLEX(ClassInf.UNKNOWN("TypeName"),{},NONE),NONE)); 
    case (env,Absyn.C_VARIABLENAME(componentRef = _)) then ((Types.T_COMPLEX(ClassInf.UNKNOWN("VariableName"),{},NONE),
          NONE)); 
    case (env,Absyn.C_EQUATIONSECTION(boolean = _)) then ((
          Types.T_COMPLEX(ClassInf.UNKNOWN("EquationSection"),{},NONE),NONE)); 
    case (env,Absyn.C_ALGORITHMSECTION(boolean = _)) then ((
          Types.T_COMPLEX(ClassInf.UNKNOWN("AlgorithmSection"),{},NONE),NONE)); 
    case (env,Absyn.C_ELEMENT(element = _)) then ((Types.T_COMPLEX(ClassInf.UNKNOWN("Element"),{},NONE),NONE)); 
    case (env,Absyn.C_EXPRESSION(exp = _)) then ((Types.T_COMPLEX(ClassInf.UNKNOWN("Expression"),{},NONE),
          NONE)); 
    case (env,Absyn.C_MODIFICATION(modification = _)) then ((Types.T_COMPLEX(ClassInf.UNKNOWN("Modification"),{},NONE),
          NONE)); 
  end matchcontinue;
end elabCodeType;

public function elabGraphicsExp "function elabGraphicsExp
 
  This function is specially designed for elaboration of expressions when
  investigating Modelica 2.0 graphical annotations.
  These have an array of records representing graphical objects. These 
  elements can have different types, therefore elab_graphic_exp will allow
  arrays with elements of varying types. 
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Exp inExp;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inExp,inBoolean)
    local
      Integer x,l,nmax;
      Option<Integer> dim1,dim2;
      Boolean impl,a,havereal;
      Ident fnstr;
      Exp.Exp exp,e1_1,e2_1,e1_2,e2_2,e_1,e_2,e3_1,start_1,stop_1,start_2,stop_2,step_1,step_2,mexp,mexp_1;
      Types.Properties prop,prop1,prop2,prop3;
      list<Env.Frame> env;
      Absyn.ComponentRef cr,fn;
      tuple<Types.TType, Option<Absyn.Path>> t1,t2,rtype,t,start_t,stop_t,step_t,t_1,t_2;
      Types.Const c1,c2,c,c_start,c_stop,const,c_step;
      list<tuple<Exp.Operator, list<tuple<Types.TType, Option<Absyn.Path>>>, tuple<Types.TType, Option<Absyn.Path>>>> ops;
      Exp.Operator op_1;
      Absyn.Exp e1,e2,e,e3,start,stop,step;
      Absyn.Operator op;
      list<Absyn.Exp> args,rest,es;
      list<Absyn.NamedArg> nargs;
      list<Exp.Exp> es_1;
      list<Types.Properties> props;
      list<tuple<Types.TType, Option<Absyn.Path>>> types,tps_2;
      list<Types.TupleConst> consts;
      Exp.Type rt,at;
      list<list<Types.Properties>> tps;
      list<list<tuple<Types.TType, Option<Absyn.Path>>>> tps_1;
      Env.Cache cache;
    case (cache,_,Absyn.INTEGER(value = x),impl) then (cache,Exp.ICONST(x),Types.PROP((Types.T_INTEGER({}),NONE),Types.C_CONST()));  /* impl */ 
    case (cache,_,Absyn.REAL(value = x),impl)
      local Real x;
      then
        (cache,Exp.RCONST(x),Types.PROP((Types.T_REAL({}),NONE),Types.C_CONST()));
    case (cache,_,Absyn.STRING(value = x),impl)
      local Ident x;
      then
        (cache,Exp.SCONST(x),Types.PROP((Types.T_STRING({}),NONE),Types.C_CONST()));
    case (cache,_,Absyn.BOOL(value = x),impl)
      local Boolean x;
      then
        (cache,Exp.BCONST(x),Types.PROP((Types.T_BOOL({}),NONE),Types.C_CONST()));
    case (cache,env,Absyn.CREF(componentReg = cr),impl)
      equation 
        Debug.fprint("tcvt","before elabCref in elabGraphicsExp\n");

        (cache,exp,prop,_) = elabCref(cache,env, cr, impl,true/*perform vectorization*/);
        Debug.fprint("tcvt","after elabCref in elabGraphicsExp\n");
      then
        (cache,exp,prop);
    case (cache,env,(exp as Absyn.BINARY(exp1 = e1,op = op,exp2 = e2)),impl) /* Binary and unary operations */ 
      local Absyn.Exp exp;
      equation 
        (cache,e1_1,Types.PROP(t1,c1)) = elabGraphicsExp(cache,env, e1, impl);
        (cache,e2_1,Types.PROP(t2,c2)) = elabGraphicsExp(cache,env, e2, impl);
        c = Types.constAnd(c1, c2);
        (cache,ops) = operators(cache,op, env, t1, t2);
        (op_1,{e1_2,e2_2},rtype) = deoverload(ops, {(e1_1,t1),(e2_1,t2)}, exp);
      then
        (cache,Exp.BINARY(e1_2,op_1,e2_2),Types.PROP(rtype,c));
    case (cache,env,(exp as Absyn.UNARY(op = op,exp = e)),impl)
      local Absyn.Exp exp;
      equation 
        (cache,e_1,Types.PROP(t,c)) = elabGraphicsExp(cache,env, e, impl);
        (cache,ops) = operators(cache,op, env, t, (Types.T_NOTYPE(),NONE));
        (op_1,{e_2},rtype) = deoverload(ops, {(e_1,t)}, exp);
      then
        (cache,Exp.UNARY(op_1,e_2),Types.PROP(rtype,c));
    case (cache,env,(exp as Absyn.LBINARY(exp1 = e1,op = op,exp2 = e2)),impl)
      local Absyn.Exp exp;
      equation 
        (cache,e1_1,Types.PROP(t1,c1)) = elabGraphicsExp(cache,env, e1, impl) "Logical binary expressions" ;
        (cache,e2_1,Types.PROP(t2,c2)) = elabGraphicsExp(cache,env, e2, impl);
        c = Types.constAnd(c1, c2);
        (cache,ops) = operators(cache,op, env, t1, t2);
        (op_1,{e1_2,e2_2},rtype) = deoverload(ops, {(e1_1,t1),(e2_1,t2)}, exp);
      then
        (cache,Exp.LBINARY(e1_2,op_1,e2_2),Types.PROP(rtype,c));
    case (cache,env,(exp as Absyn.LUNARY(op = op,exp = e)),impl)
      local Absyn.Exp exp;
      equation 
        (cache,e_1,Types.PROP(t,c)) = elabGraphicsExp(cache,env, e, impl) "Logical unary expressions" ;
        (cache,ops) = operators(cache,op, env, t, (Types.T_NOTYPE(),NONE));
        (op_1,{e_2},rtype) = deoverload(ops, {(e_1,t)}, exp);
      then
        (cache,Exp.LUNARY(op_1,e_2),Types.PROP(rtype,c));
    case (cache,env,(exp as Absyn.RELATION(exp1 = e1,op = op,exp2 = e2)),impl)
      local Absyn.Exp exp;
      equation 
        (cache,e1_1,Types.PROP(t1,c1)) = elabGraphicsExp(cache,env, e1, impl) "Relation expressions" ;
        (cache,e2_1,Types.PROP(t2,c2)) = elabGraphicsExp(cache,env, e2, impl);
        c = Types.constAnd(c1, c2);
        (cache,ops) = operators(cache,op, env, t1, t2);
        (op_1,{e1_2,e2_2},rtype) = deoverload(ops, {(e1_1,t1),(e2_1,t2)}, exp);
      then
        (cache,Exp.RELATION(e1_2,op_1,e2_2),Types.PROP(rtype,c));
    case (cache,env,Absyn.IFEXP(ifExp = e1,trueBranch = e2,elseBranch = e3),impl) /* Conditional expressions */ 
      local Exp.Exp e;
      equation 
        (cache,e1_1,prop1) = elabGraphicsExp(cache,env, e1, impl);
        (cache,e2_1,prop2) = elabGraphicsExp(cache,env, e2, impl);
        (cache,e3_1,prop3) = elabGraphicsExp(cache,env, e3, impl);
        (cache,e,prop) = elabIfexp(cache,env, e1_1, prop1, e2_1, prop2, e3_1, prop3, impl, NONE);
         /* TODO elseif part */ 
      then
        (cache,e,prop);
    case (cache,env,Absyn.CALL(function_ = fn,functionArgs = Absyn.FUNCTIONARGS(args = args,argNames = nargs)),impl) /* Function calls */ 
      local Exp.Exp e;
      equation 
        fnstr = Dump.printComponentRefStr(fn);
        (cache,e,prop,_) = elabCall(cache,env, fn, args, nargs, true, NONE);
      then
        (cache,e,prop);
    case (cache,env,Absyn.TUPLE(expressions = (e as (e1 :: rest))),impl) /* PR. Get the properties for each expression in the tuple. 
	 Each expression has its own constflag.
	 !!The output from functions does just have one const flag. 
	 Fix this!!
	 */ 
      local
        list<Exp.Exp> e_1;
        list<Absyn.Exp> e;
      equation 
        (cache,e_1,props) = elabTuple(cache,env, e, impl,false);
        (types,consts) = splitProps(props);
      then
        (cache,Exp.TUPLE(e_1),Types.PROP_TUPLE((Types.T_TUPLE(types),NONE),Types.TUPLE_CONST(consts)));
    case (cache,env,Absyn.RANGE(start = start,step = NONE,stop = stop),impl) /* Array-related expressions */ 
      equation 
        (cache,start_1,Types.PROP(start_t,c_start)) = elabGraphicsExp(cache,env, start, impl);
        (cache,stop_1,Types.PROP(stop_t,c_stop)) = elabGraphicsExp(cache,env, stop, impl);
        (start_2,NONE,stop_2,rt) = deoverloadRange((start_1,start_t), NONE, (stop_1,stop_t));
        const = Types.constAnd(c_start, c_stop);
        (cache,t) = elabRangeType(cache,env, start_2, NONE, stop_2, const, rt, impl);
      then
        (cache,Exp.RANGE(rt,start_1,NONE,stop_1),Types.PROP(t,const));
    case (cache,env,Absyn.RANGE(start = start,step = SOME(step),stop = stop),impl)
      equation 
        (cache,start_1,Types.PROP(start_t,c_start)) = elabGraphicsExp(cache,env, start, impl) "Debug.fprintln(\"setr\", \"elab_graphics_exp_range2\") &" ;
        (cache,step_1,Types.PROP(step_t,c_step)) = elabGraphicsExp(cache,env, step, impl);
        (cache,stop_1,Types.PROP(stop_t,c_stop)) = elabGraphicsExp(cache,env, stop, impl);
        (start_2,SOME(step_2),stop_2,rt) = deoverloadRange((start_1,start_t), SOME((step_1,step_t)), (stop_1,stop_t));
        c1 = Types.constAnd(c_start, c_step);
        const = Types.constAnd(c1, c_stop);
        (cache,t) = elabRangeType(cache,env, start_2, SOME(step_2), stop_2, const, rt, impl);
      then
        (cache,Exp.RANGE(rt,start_2,SOME(step_2),stop_2),Types.PROP(t,const));
    case (cache,env,Absyn.ARRAY(arrayExp = es),impl)
      equation 
        (cache,es_1,Types.PROP(t,const)) = elabGraphicsArray(cache,env, es, impl);
        l = listLength(es_1);
        at = Types.elabType(t);
        a = Types.isArray(t);
      then
        (cache,Exp.ARRAY(at,a,es_1),Types.PROP((Types.T_ARRAY(Types.DIM(SOME(l)),t),NONE),const));
    case (cache,env,Absyn.MATRIX(matrix = es),impl)
      local list<list<Absyn.Exp>> es;
      equation 
        (cache,_,tps,_) = elabExpListList(cache,env, es, impl, NONE,true);
        tps_1 = Util.listListMap(tps, Types.getPropType);
        tps_2 = Util.listFlatten(tps_1);
        nmax = matrixConstrMaxDim(tps_2);
        havereal = Types.containReal(tps_2);
        (cache,mexp,Types.PROP(t,c),dim1,dim2) = elabMatrixSemi(cache,env, es, impl, NONE, havereal, nmax,true);
        at = Types.elabType(t);
        mexp_1 = elabMatrixToMatrixExp(mexp);
        t_1 = Types.unliftArray(t);
        t_2 = Types.unliftArray(t_1);
      then
        (cache,mexp,Types.PROP(
          (
          Types.T_ARRAY(Types.DIM(dim1),
          (Types.T_ARRAY(Types.DIM(dim2),t_2),NONE)),NONE),c));
    case (cache,_,e,impl)
      local Ident es;
      equation 
        Print.printErrorBuf("- elab_graphics_exp failed: ");
        es = Dump.printExpStr(e);
        Print.printErrorBuf(es);
        Print.printErrorBuf("\n");
      then
        fail();
  end matchcontinue;
end elabGraphicsExp;

protected function deoverloadRange "function: deoverloadRange
 
  Does deoverloading of range expressions. They can be both Integer ranges 
  and Real ranges. This function determines which one to use.
"
  input tuple<Exp.Exp, Types.Type> inTplExpExpTypesType1;
  input Option<tuple<Exp.Exp, Types.Type>> inTplExpExpTypesTypeOption2;
  input tuple<Exp.Exp, Types.Type> inTplExpExpTypesType3;
  output Exp.Exp outExp1;
  output Option<Exp.Exp> outExpExpOption2;
  output Exp.Exp outExp3;
  output Exp.Type outType4;
algorithm 
  (outExp1,outExpExpOption2,outExp3,outType4):=
  matchcontinue (inTplExpExpTypesType1,inTplExpExpTypesTypeOption2,inTplExpExpTypesType3)
    local
      Exp.Exp e1,e3,e2,e1_1,e3_1,e2_1;
      tuple<Types.TType, Option<Absyn.Path>> t1,t3,t2;
    case ((e1,(Types.T_INTEGER(varLstInt = _),_)),NONE,(e3,(Types.T_INTEGER(varLstInt = _),_))) then (e1,NONE,e3,Exp.INT()); 
    case ((e1,(Types.T_INTEGER(varLstInt = _),_)),SOME((e2,(Types.T_INTEGER(_),_))),(e3,(Types.T_INTEGER(varLstInt = _),_))) then (e1,SOME(e2),e3,Exp.INT()); 
    case ((e1,t1),NONE,(e3,t3))
      equation 
        ({e1_1,e3_1},_) = elabArglist({(Types.T_REAL({}),NONE),(Types.T_REAL({}),NONE)}, 
          {(e1,t1),(e3,t3)});
      then
        (e1_1,NONE,e3_1,Exp.REAL());
    case ((e1,t1),SOME((e2,t2)),(e3,t3))
      equation 
        ({e1_1,e2_1,e3_1},_) = elabArglist(
          {(Types.T_REAL({}),NONE),(Types.T_REAL({}),NONE),
          (Types.T_REAL({}),NONE)}, {(e1,t1),(e2,t2),(e3,t3)});
      then
        (e1_1,SOME(e2_1),e3_1,Exp.REAL());
  end matchcontinue;
end deoverloadRange;

protected function elabRangeType "function: elabRangeType 
 
  Helper function to elab_range. Calculates the dimension of the 
  range expression.
"
	input Env.Cache inCache;
  input Env.Env inEnv1;
  input Exp.Exp inExp2;
  input Option<Exp.Exp> inExpExpOption3;
  input Exp.Exp inExp4;
  input Types.Const inConst5;
  input Exp.Type inType6;
  input Boolean inBoolean7;
  output Env.Cache outCache;
  output Types.Type outType;
algorithm 
  (outCache,outType) :=
  matchcontinue (inCache,inEnv1,inExp2,inExpExpOption3,inExp4,inConst5,inType6,inBoolean7)
    local
      Integer startv,stopv,n,n_1,stepv,n_2,n_3,n_4;
      list<Env.Frame> env;
      Exp.Exp start,stop,step;
      Types.Const const;
      Boolean impl;
      Ident s1,s2,s3,s4,s5,s6,str;
      Option<Ident> s2opt;
      Exp.Type expty;
      Env.Cache cache;
    case (cache,env,start,NONE,stop,const,_,impl) /* impl as false */ 
      equation 
        (cache,Values.INTEGER(startv),_) = Ceval.ceval(cache,env, start, impl, NONE, NONE, Ceval.MSG());
        (cache,Values.INTEGER(stopv),_) = Ceval.ceval(cache,env, stop, impl, NONE, NONE, Ceval.MSG());
        n = stopv - startv;
        n_1 = n + 1;
      then
        (cache,(
          Types.T_ARRAY(Types.DIM(SOME(n_1)),(Types.T_INTEGER({}),NONE)),NONE));
    case (cache,env,start,SOME(step),stop,const,_,impl) /* as false */ 
      equation 
        (cache,Values.INTEGER(startv),_) = Ceval.ceval(cache,env, start, impl, NONE, NONE, Ceval.MSG());
        (cache,Values.INTEGER(stepv),_) = Ceval.ceval(cache,env, step, impl, NONE, NONE, Ceval.MSG());
        (cache,Values.INTEGER(stopv),_) = Ceval.ceval(cache,env, stop, impl, NONE, NONE, Ceval.MSG());
        n = stopv - startv;
        n_1 = n/stepv;
        n_2 = n_1 + 1;
      then
        (cache,(
          Types.T_ARRAY(Types.DIM(SOME(n_2)),(Types.T_INTEGER({}),NONE)),NONE));
    case (cache,env,start,NONE,stop,const,_,impl) /* as false */ 
      local Real startv,stopv,n,n_2;
      equation 
        (cache,Values.REAL(startv),_) = Ceval.ceval(cache,env, start, impl, NONE, NONE, Ceval.MSG());
        (cache,Values.REAL(stopv),_) = Ceval.ceval(cache,env, stop, impl, NONE, NONE, Ceval.MSG());
        n = stopv -. startv;
        n_2 = realFloor(n);
        n_3 = realInt(n_2);
        n_1 = n_3 + 1;
      then
        (cache,(
          Types.T_ARRAY(Types.DIM(SOME(n_1)),(Types.T_REAL({}),NONE)),NONE));
    case (cache,env,start,SOME(step),stop,const,_,impl) /* as false */ 
      local Real startv,stepv,stopv,n,n_1,n_3;
      equation 
        (cache,Values.REAL(startv),_) = Ceval.ceval(cache,env, start, impl, NONE, NONE, Ceval.MSG());
        (cache,Values.REAL(stepv),_) = Ceval.ceval(cache,env, step, impl, NONE, NONE, Ceval.MSG());
        (cache,Values.REAL(stopv),_) = Ceval.ceval(cache,env, stop, impl, NONE, NONE, Ceval.MSG());
        n = stopv -. startv;
        n_1 = n/.stepv;
        n_3 = realFloor(n_1);
        n_4 = realInt(n_3);
        n_2 = n_4 + 1;
      then
        (cache,(
          Types.T_ARRAY(Types.DIM(SOME(n_2)),(Types.T_REAL({}),NONE)),NONE));
    case (cache,_,_,_,_,const,Exp.INT(),(impl as true)) 
    then (cache,(Types.T_ARRAY(Types.DIM(NONE),(Types.T_INTEGER({}),NONE)), NONE)); 
    
    case (cache,_,_,_,_,const,Exp.REAL(),(impl as true)) 
    then (cache,(Types.T_ARRAY(Types.DIM(NONE),(Types.T_REAL({}),NONE)),NONE)); 
    
    case (cache,env,start,step,stop,const,expty,impl)
      local Option<Exp.Exp> step;
      equation 
        Debug.fprint("failtrace", "- elab_range_type failed: ");
        s1 = Exp.printExpStr(start);
        s2opt = Util.applyOption(step, Exp.printExpStr);
        s2 = Util.flattenOption(s2opt, "none");
        s3 = Exp.printExpStr(stop);
        s4 = Types.unparseConst(const);
        s5 = Util.if_(impl, "impl", "expl");
        s6 = Exp.typeString(expty);
        str = Util.stringAppendList({"(",s1,":",s2,":",s3,") ",s4," ",s5," ",s6});
        Debug.fprintln("failtrace", str);
      then
        fail();
  end matchcontinue;
end elabRangeType;

protected function elabTuple "function: elabTuple
 
  This function does elaboration of tuples, i.e. function calls returning 
  several values.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Boolean performVectorization;
  output Env.Cache outCache;
  output list<Exp.Exp> outExpExpLst;
  output list<Types.Properties> outTypesPropertiesLst;
algorithm 
  (outCache,outExpExpLst,outTypesPropertiesLst):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean,performVectorization)
    local
      Exp.Exp e_1;
      Types.Properties p;
      list<Exp.Exp> exps_1;
      list<Types.Properties> props;
      list<Env.Frame> env;
      Absyn.Exp e;
      list<Absyn.Exp> exps;
      Boolean impl;
      Env.Cache cache;
      Boolean doVect;
    case (cache,env,(e :: exps),impl,doVect) /* impl */ 
      equation 
        (cache,e_1,p,_) = elabExp(cache,env, e, impl, NONE,doVect) "Debug.print \"\\nEntered elab_tuple.\" &" ;
        (cache,exps_1,props) = elabTuple(cache,env, exps, impl,doVect) "	Debug.print \"\\nElaborated expression.\" &" ;
         /* 	Debug.print \"\\nElaborated expression.\" & 	Debug.print \"\\nThe last element was just elaborated.\" */ 
      then
        (cache,(e_1 :: exps_1),(p :: props));
    case (cache,env,{},impl,doVect) /* Debug.print \"elaborating last element.\" */  
    then (cache,{},{}); 
  end matchcontinue;
end elabTuple;

protected function elabArray "function: elabArray 
 
  This function elaborates on array expressions.
  
  All types of an array should be equivalent. However, mixed Integer and Real
  elements are allowed in an array and in that case the Integer elements
  are converted to Real elements.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean performVectorization;
  output Env.Cache outCache;
  output list<Exp.Exp> outExpExpLst;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExpExpLst,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,performVectorization)
    local
      list<Exp.Exp> expl_1;
      Types.Properties prop;
      list<Env.Frame> env;
      list<Absyn.Exp> expl;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Env.Cache cache;
      Boolean doVect;
    case (cache,env,expl,impl,st,doVect) /* impl array contains mixed Integer and Real types */ 
      equation 
        elabArrayHasMixedIntReals(cache,env, expl, impl, st,doVect);
        (cache,expl_1,prop) = elabArrayReal(cache,env, expl, impl, st,doVect);
      then
        (cache,expl_1,prop);
    case (cache,env,expl,impl,st,doVect)
      equation 
        (cache,expl_1,prop) = elabArray2(cache,env, expl, impl, st,doVect);
      then
        (cache,expl_1,prop);
  end matchcontinue;
end elabArray;

protected function elabArrayHasMixedIntReals "function: elabArrayHasMixedIntReals
 
  Helper function to elab_array, checks if expression list contains both
  Integer and Real types.
"
	input Env.Cache inCache;
  input Env.Env env;
  input list<Absyn.Exp> expl;
  input Boolean impl;
  input Option<Interactive.InteractiveSymbolTable> st;
  input Boolean performVectorization;
algorithm 
  elabArrayHasInt(inCache,env, expl, impl, st, performVectorization);
  elabArrayHasReal(inCache,env, expl, impl, st, performVectorization);
end elabArrayHasMixedIntReals;

protected function elabArrayHasInt "function: elabArrayHasInt
  author :PA
 
  Helper function to elabArray.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean performVectorization;
algorithm 
  _:=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,performVectorization)
    local
      Exp.Exp e_1;
      tuple<Types.TType, Option<Absyn.Path>> tp;
      list<Env.Frame> env;
      Absyn.Exp e;
      list<Absyn.Exp> expl;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Env.Cache cache;
      Boolean doVect;
    case (cache,env,(e :: expl),impl,st,doVect) /* impl */ 
      equation 
        (cache,e_1,Types.PROP(tp,_),_) = elabExp(cache,env, e, impl, st,doVect);
        ((Types.T_INTEGER({}),_)) = Types.arrayElementType(tp);
      then
        ();
    case (cache,env,(e :: expl),impl,st,doVect)
      equation 
        elabArrayHasInt(cache,env, expl, impl, st,doVect);
      then
        ();
  end matchcontinue;
end elabArrayHasInt;

protected function elabArrayHasReal "function: elabArrayHasReal
  author :PA
 
  Helper function to elab_array. 
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean performVectorization;
algorithm 
  _:=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,performVectorization)
    local
      Exp.Exp e_1;
      tuple<Types.TType, Option<Absyn.Path>> tp;
      list<Env.Frame> env;
      Absyn.Exp e;
      list<Absyn.Exp> expl;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Env.Cache cache;
      Boolean doVect;
    case (cache,env,(e :: expl),impl,st,doVect) /* impl */ 
      equation 
        (cache,e_1,Types.PROP(tp,_),_) = elabExp(cache,env, e, impl, st,doVect);
        ((Types.T_INTEGER({}),_)) = Types.arrayElementType(tp);
      then
        ();
    case (cache,env,(e :: expl),impl,st,doVect)
      equation 
        elabArrayHasReal(cache,env, expl, impl, st,doVect);
      then
        ();
  end matchcontinue;
end elabArrayHasReal;

protected function elabArrayReal "function: elabArrayReal
  
  Helper function to elab_array, converts all elements to Real
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean performVectorization;
  output Env.Cache outCache;
  output list<Exp.Exp> outExpExpLst;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExpExpLst,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,performVectorization)
    local
      list<Exp.Exp> expl_1,expl_2;
      list<Types.Properties> props;
      tuple<Types.TType, Option<Absyn.Path>> real_tp,real_tp_1;
      Ident s;
      Types.Const const;
      list<tuple<Types.TType, Option<Absyn.Path>>> types;
      list<Env.Frame> env;
      list<Absyn.Exp> expl;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Env.Cache cache;
      Boolean doVect;
    case (cache,env,expl,impl,st,doVect) /* impl elaborate each expression, pick first realtype
	    and type_convert all expressions to that type */ 
      equation 
        (cache,expl_1,props,_) = elabExpList(cache,env, expl, impl, st,doVect);
        real_tp = elabArrayFirstPropsReal(props);
        s = Types.unparseType(real_tp);
        const = elabArrayConst(props);
        types = Util.listMap(props, Types.getPropType);
        (expl_2,real_tp_1) = elabArrayReal2(expl_1, types, real_tp);
      then
        (cache,expl_2,Types.PROP(real_tp_1,const));
    case (cache,env,expl,impl,st,doVect)
      equation 
        Debug.fprint("failtrace", "-elab_array_real failed\n");
      then
        fail();
  end matchcontinue;
end elabArrayReal;

protected function elabArrayFirstPropsReal "function: elabArrayFirstPropsReal
  author: PA
 
  Pick the first type among the list of properties which has elementype
  Real.
"
  input list<Types.Properties> inTypesPropertiesLst;
  output Types.Type outType;
algorithm 
  outType:=
  matchcontinue (inTypesPropertiesLst)
    local
      tuple<Types.TType, Option<Absyn.Path>> tp;
      list<Types.Properties> rest;
    case ((Types.PROP(type_ = tp) :: _))
      equation 
        ((Types.T_REAL(_),_)) = Types.arrayElementType(tp);
      then
        tp;
    case ((_ :: rest))
      equation 
        tp = elabArrayFirstPropsReal(rest);
      then
        tp;
  end matchcontinue;
end elabArrayFirstPropsReal;

protected function elabArrayConst "function: elabArrayConst
 
  Constructs a const value from a list of properties, using const_and.
"
  input list<Types.Properties> inTypesPropertiesLst;
  output Types.Const outConst;
algorithm 
  outConst:=
  matchcontinue (inTypesPropertiesLst)
    local
      tuple<Types.TType, Option<Absyn.Path>> tp;
      Types.Const c,c2,c1;
      list<Types.Properties> rest;
    case ({Types.PROP(type_ = tp,constFlag = c)}) then c; 
    case ((Types.PROP(constFlag = c1) :: rest))
      equation 
        c2 = elabArrayConst(rest);
        c = Types.constAnd(c2, c1);
      then
        c;
    case (_) equation Debug.fprint("failtrace", "-elabArrayConst failed\n"); then fail();
  end matchcontinue;
end elabArrayConst;

protected function elabArrayReal2 "function: elabArrayReal2
  author: PA
  
  Applies type_convert to all expressions in a list to the type given
  as argument.
"
  input list<Exp.Exp> inExpExpLst;
  input list<Types.Type> inTypesTypeLst;
  input Types.Type inType;
  output list<Exp.Exp> outExpExpLst;
  output Types.Type outType;
algorithm 
  (outExpExpLst,outType):=
  matchcontinue (inExpExpLst,inTypesTypeLst,inType)
    local
      tuple<Types.TType, Option<Absyn.Path>> tp,res_type,t,to_type;
      list<Exp.Exp> res,es;
      Exp.Exp e,e_1;
      list<tuple<Types.TType, Option<Absyn.Path>>> ts;
      Ident s,s2,s3;
    case ({},{},tp) then ({},tp);  /* expl to_type new_expl res_type */ 
    case ((e :: es),(t :: ts),to_type) /* No need for type conversion. */ 
      equation 
        true = Types.equivtypes(t, to_type);
        (res,res_type) = elabArrayReal2(es, ts, to_type);
      then
        ((e :: res),res_type);
    case ((e :: es),(t :: ts),to_type) /* type conversion */ 
      equation 
        (e_1,res_type) = Types.typeConvert(e, t, to_type);
        (res,_) = elabArrayReal2(es, ts, to_type);
      then
        ((e_1 :: res),res_type);
    case ((e :: es),(t :: ts),to_type)
      equation 
        print("elab_array_real2 failed\n");
        s = Exp.printExpStr(e);
        s2 = Types.unparseType(t);
        print("exp = ");
        print(s);
        print(" type:");
        print(s2);
        print("\n");
        s3 = Types.unparseType(to_type);
        print(" to type :");
        print(s3);
        print("\n");
      then
        fail();
  end matchcontinue;
end elabArrayReal2;

protected function elabArray2 "function: elabArray2
  
  Helper function to elab_array, checks that all elements are equivalent.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean performVectorization;
  output Env.Cache outCache;
  output list<Exp.Exp> outExpExpLst;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExpExpLst,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,performVectorization)
    local
      Exp.Exp e_1;
      Types.Properties prop;
      list<Env.Frame> env;
      Absyn.Exp e;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      tuple<Types.TType, Option<Absyn.Path>> t1,t2;
      Types.Const c1,c2,c;
      list<Exp.Exp> es_1;
      list<Absyn.Exp> es,expl;
      Ident e_str,str,elt_str,t1_str,t2_str;
      list<Ident> strs;
      Env.Cache cache;
      Boolean doVect;
    case (cache,env,{e},impl,st,doVect) /* impl */ 
      equation 
        (cache,e_1,prop,_) = elabExp(cache,env, e, impl, st,doVect);
      then
        (cache,{e_1},prop);
    case (cache,env,(e :: es),impl,st,doVect)
      equation 
        (cache,e_1,Types.PROP(t1,c1),_) = elabExp(cache,env, e, impl, st,doVect);
        (cache,es_1,Types.PROP(t2,c2)) = elabArray2(cache,env, es, impl, st,doVect);
        true = Types.equivtypes(t1, t2);
        c = Types.constAnd(c1, c2);
      then
        (cache,(e_1 :: es_1),Types.PROP(t1,c));
    case (cache,env,(e :: es),impl,st,doVect)
      equation 
        (cache,e_1,Types.PROP(t1,c1),_) = elabExp(cache,env, e, impl, st,doVect);
        (cache,es_1,Types.PROP(t2,c2)) = elabArray2(cache,env, es, impl, st,doVect);
        false = Types.equivtypes(t1, t2);
        e_str = Dump.printExpStr(e);
        strs = Util.listMap(es, Dump.printExpStr);
        str = Util.stringDelimitList(strs, ",");
        elt_str = Util.stringAppendList({"[",str,"]"});
        t1_str = Types.unparseType(t1);
        t2_str = Types.unparseType(t2);
        Error.addMessage(Error.TYPE_MISMATCH_ARRAY_EXP, {str,t1_str,elt_str,t2_str});
      then
        fail();
    case (cache,_,expl,_,_,_)
      equation 
        Debug.fprint("failtrace", "elab_array failed\n");
      then
        fail();
  end matchcontinue;
end elabArray2;

protected function elabGraphicsArray "function: elabGraphicsArray
 
  This function elaborates array expressions for graphics elaboration.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output list<Exp.Exp> outExpExpLst;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExpExpLst,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp e_1;
      Types.Properties prop;
      list<Env.Frame> env;
      Absyn.Exp e;
      Boolean impl;
      tuple<Types.TType, Option<Absyn.Path>> t1,t2;
      Types.Const c1,c2,c;
      list<Exp.Exp> es_1;
      list<Absyn.Exp> es;
      Env.Cache cache;
    case (cache,env,{e},impl) /* impl */ 
      equation 
        (cache,e_1,prop) = elabGraphicsExp(cache,env, e, impl);
      then
        (cache,{e_1},prop);
    case (cache,env,(e :: es),impl)
      equation 
        (cache,e_1,Types.PROP(t1,c1)) = elabGraphicsExp(cache,env, e, impl);
        (cache,es_1,Types.PROP(t2,c2)) = elabGraphicsArray(cache,env, es, impl);
        c = Types.constAnd(c1, c2);
      then
        (cache,(e_1 :: es_1),Types.PROP(t1,c));
    case (_,_,_,impl)
      equation 
        Error.addMessage(Error.INTERNAL_ERROR, {"elab_graphics_array failed\n"});
      then
        fail();
  end matchcontinue;
end elabGraphicsArray;

protected function elabMatrixComma "function elabMatrixComma
 
  This function is a helper function for elab_matrix_semi.
  It elaborates one matrix row of a matrix.
"
	input Env.Cache inCache;
  input Env.Env inEnv1;
  input list<Absyn.Exp> inAbsynExpLst2;
  input Boolean inBoolean3;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption4;
  input Boolean inBoolean5;
  input Integer inInteger6;
  input Boolean performVectorization;
  output Env.Cache outCache;
  output Exp.Exp outExp1;
  output Types.Properties outProperties2;
  output Option<Integer> outInteger3;
  output Option<Integer> outInteger4;
algorithm 
  (outCache,outExp1,outProperties2,outInteger3,outInteger4):=
  matchcontinue (inCache,inEnv1,inAbsynExpLst2,inBoolean3,inInteractiveInteractiveSymbolTableOption4,inBoolean5,inInteger6,performVectorization)
    local
      Exp.Exp el_1,el_2;
      Types.Properties prop,prop1,prop1_1,prop2,props;
      tuple<Types.TType, Option<Absyn.Path>> t1,t1_1;
      Integer t1_dim1,nmax_2,nmax,t1_ndims,dim;
      Option<Integer> t1_dim1_1,t1_dim2_1,dim1,dim2,dim2_1;
      Boolean array,impl,havereal,a,scalar,doVect;
      Exp.Type at;
      list<Env.Frame> env;
      Absyn.Exp el;
      Option<Interactive.InteractiveSymbolTable> st;
      list<Exp.Exp> els_1;
      list<Absyn.Exp> els;
      Env.Cache cache;
    case (cache,env,{el},impl,st,havereal,nmax,doVect) /* implicit inst. have real nmax dim1 dim2 */ 
      equation 
        (cache,el_1,(prop as Types.PROP(t1,_)),_) = elabExp(cache,env, el, impl, st,doVect);
        t1_dim1 = Types.ndims(t1);
        nmax_2 = nmax - t1_dim1;
        (el_2,(prop as Types.PROP(t1_1,_))) = promoteExp(el_1, prop, nmax_2);
        (_,t1_dim1_1 :: (t1_dim2_1 :: _)) = Types.flattenArrayTypeOpt(t1_1);
        array = Types.isArray(Types.unliftArray(Types.unliftArray(t1_1)));
        scalar = boolNot(array);
        at = Types.elabType(t1_1);
      then
        (cache,Exp.ARRAY(at,scalar,{el_2}),prop,t1_dim1_1,t1_dim2_1);
    case (cache,env,(el :: els),impl,st,havereal,nmax,doVect)
      equation 
        (cache,el_1,(prop1 as Types.PROP(t1,_)),_) = elabExp(cache,env, el, impl, st,doVect);
        t1_ndims = Types.ndims(t1);
        nmax_2 = nmax - t1_ndims;
        (el_2,(prop1_1 as Types.PROP(t1_1,_))) = promoteExp(el_1, prop1, nmax_2);
         (_,t1_dim1_1 :: (t1_dim2_1 :: _)) = Types.flattenArrayTypeOpt(t1_1);
        (cache,Exp.ARRAY(at,a,els_1),prop2,dim1,dim2) = elabMatrixComma(cache,env, els, impl, st, havereal, nmax,doVect);
        dim2_1 = Types.dimensionsAdd(t1_dim2_1,dim2)"comma between matrices => concatenation along second dimension" ;
        props = Types.matchWithPromote(prop1_1, prop2, havereal);
        dim = listLength((el :: els));
      then
        (cache,Exp.ARRAY(at,a,(el_2 :: els_1)),props,dim1,dim2_1);
    case (_,_,_,_,_,_,_,_)
      equation 
        Debug.fprint("failtrace", "- elabMatrixComma failed\n");
      then
        fail();
  end matchcontinue;
end elabMatrixComma;

protected function elabMatrixCatTwoExp "function: elabMatrixCatTwoExp
  author: PA
 
  This function takes an array expression of dimension >=3 and
  concatenates each array element along the second dimension.
  For instance
  elab_matrix_cat_two( {{1,2;5,6}, {3,4;7,8}}) => {1,2,3,4;5,6,7,8}
"
  input Exp.Exp inExp;
  output Exp.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp)
    local
      Exp.Exp res;
      list<Exp.Exp> expl;
    case (Exp.ARRAY(array = expl))
      equation 
        res = elabMatrixCatTwo(expl);
      then
        res;
    case (_)
      equation 
        Debug.fprint("failtrace", "-elab_matrix_cat_one failed\n");
      then
        fail();
  end matchcontinue;
end elabMatrixCatTwoExp;

protected function elabMatrixCatTwo "function: elabMatrixCatTwo
  author: PA
 
  Concatenates a list of matrix(or higher dim) expressions along
  the second dimension.
"
  input list<Exp.Exp> inExpExpLst;
  output Exp.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExpExpLst)
    local
      Exp.Exp e,res,e1,e2;
      list<Exp.Exp> rest,expl;
    case ({e}) then e; 
    case ({e1,e2})
      equation 
        res = elabMatrixCatTwo2(e1, e2);
      then
        res;
    case ((e1 :: rest))
      equation 
        e2 = elabMatrixCatTwo(rest);
        res = elabMatrixCatTwo2(e1, e2);
      then
        res;
    case (expl)
      local Exp.Type tp;
      equation
        tp = Exp.typeof(Util.listFirst(expl));
       then Exp.CALL(Absyn.IDENT("cat"),(Exp.ICONST(2) :: expl),false,true,tp); 
  end matchcontinue;
end elabMatrixCatTwo;

protected function elabMatrixCatTwo2 "function: elabMatrixCatTwo2
 
  Helper function to elab_matrix_cat_two
  Concatenates two array expressions that are matrices (or higher dimension)
  along the first dimension (row).
"
  input Exp.Exp inExp1;
  input Exp.Exp inExp2;
  output Exp.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp1,inExp2)
    local
      list<Exp.Exp> expl,expl1,expl2;
      Exp.Type a1,a2;
      Boolean at1,at2;
    case (Exp.ARRAY(ty = a1,scalar = at1,array = expl1),Exp.ARRAY(ty = a2,scalar = at2,array = expl2))
      equation 
        expl = elabMatrixCatTwo3(expl1, expl2);
      then
        Exp.ARRAY(a1,at1,expl);
  end matchcontinue;
end elabMatrixCatTwo2;

protected function elabMatrixCatTwo3 "function: elabMatrixCatTwo3
 
  Helper function to elab_matrix_cat_two_2
"
  input list<Exp.Exp> inExpExpLst1;
  input list<Exp.Exp> inExpExpLst2;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inExpExpLst1,inExpExpLst2)
    local
      list<Exp.Exp> expl,es_1,expl1,es1,expl2,es2;
      Exp.Type a1,a2;
      Boolean at1,at2;
    case ({},{}) then {}; 
    case ((Exp.ARRAY(ty = a1,scalar = at1,array = expl1) :: es1),(Exp.ARRAY(ty = a2,scalar = at2,array = expl2) :: es2))
      equation 
        expl = listAppend(expl1, expl2);
        es_1 = elabMatrixCatTwo3(es1, es2);
      then
        (Exp.ARRAY(a1,at1,expl) :: es_1);
  end matchcontinue;
end elabMatrixCatTwo3;

protected function elabMatrixCatOne "function: elabMatrixCatOne
  author: PA
 
  Concatenates a list of matrix(or higher dim) expressions along
  the first dimension. 
  i.e. elabMatrixCatOne( { {1,2;3,4}, {5,6;7,8} }) => {1,2;3,4;5,6;7,8} 
"
  input list<Exp.Exp> inExpExpLst;
  output Exp.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExpExpLst)
    local
      Exp.Exp e;
      Exp.Type a;
      Boolean at;
      list<Exp.Exp> expl,expl1,expl2,es;
    case ({(e as Exp.ARRAY(ty = a,scalar = at,array = expl))}) then e; 
    case ({Exp.ARRAY(ty = a,scalar = at,array = expl1),Exp.ARRAY(array = expl2)})
      equation 
        expl = listAppend(expl1, expl2);
      then
        Exp.ARRAY(a,at,expl);
    case ((Exp.ARRAY(ty = a,scalar = at,array = expl1) :: es))
      equation 
        Exp.ARRAY(_,_,expl2) = elabMatrixCatOne(es);
        expl = listAppend(expl1, expl2);
      then
        Exp.ARRAY(a,at,expl);
    case (expl) local
      Exp.Type tp;
      equation
        tp = Exp.typeof(Util.listFirst(expl));
        then Exp.CALL(Absyn.IDENT("cat"),(Exp.ICONST(1) :: expl),false,true,tp); 
  end matchcontinue;
end elabMatrixCatOne;

protected function promoteExp "function: promoteExp
  author: PA
  
  Adds onesized array dimensions to an expressions n times to the right
  of array dimensions.
  For instance 
  promote_exp( {1,2},1) => {{1},{2}}
  promote_exp( {1,2},2) => { {{1}},{{2}} }
  See also promote_real_array in real_array.c
"
  input Exp.Exp inExp;
  input Types.Properties inProperties;
  input Integer inInteger;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outExp,outProperties):=
  matchcontinue (inExp,inProperties,inInteger)
    local
      Exp.Exp e,e_1,e_2;
      Types.Properties prop,prop_1;
      Integer n_1,n;
      Exp.Type e_tp,e_tp_1;
      tuple<Types.TType, Option<Absyn.Path>> tp_1,tp;
      Boolean array;
      Types.Const c;
    case (e,prop,-1) then (e,prop);  /* n */ 
    case (e,prop,0) then (e,prop); 
    case (e,Types.PROP(type_ = tp,constFlag = c),n)
      equation 
        n_1 = n - 1;
        e_tp = Types.elabType(tp);
        tp_1 = Types.liftArrayRight(tp, SOME(1));
        e_tp_1 = Types.elabType(tp_1);
        array = Exp.typeBuiltin(e_tp);
        e_1 = promoteExp2(e, (n,tp));
        (e_2,prop_1) = promoteExp(e_1, Types.PROP(tp_1,c), n_1);
      then
        (e_2,prop_1);
    case(_,_,_) equation
      Debug.fprint("failtrace","-promoteExp failed\n");
      then fail();
  end matchcontinue;
end promoteExp;

protected function promoteExp2 "function: promoteExp2
 
  Helper function to promote_exp, adds dimension to the right of
  the expression.
"
  input Exp.Exp inExp;
  input tuple<Integer, Types.Type> inTplIntegerTypesType;
  output Exp.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp,inTplIntegerTypesType)
    local
      Integer n_1,n;
      tuple<Types.TType, Option<Absyn.Path>> tp_1,tp,tp2;
      list<Exp.Exp> expl_1,expl;
      Exp.Type a;
      Boolean at;
      Exp.Exp e;
      Ident es;
    case (Exp.ARRAY(ty = a,scalar = at,array = expl),(n,tp))
      equation 
        n_1 = n - 1;
        tp_1 = Types.unliftArray(tp);
        expl_1 = Util.listMap1(expl, promoteExp2, (n_1,tp_1));
      then
        Exp.ARRAY(a,at,expl_1);
    case (e,(_,tp)) /* scalars can be promoted from s to {s} */ 
      local Exp.Type at;
      equation 
        false = Types.isArray(tp);
        at = Exp.typeof(e);
      then
        Exp.ARRAY(Exp.T_ARRAY(at,{SOME(1)}),true,{e});
    case (e,(_,(Types.T_ARRAY(arrayDim = Types.DIM(integerOption = SOME(1)),arrayType = tp2),_))) /* arrays of one dimension can be promoted from a to {a} */ 
      local Exp.Type at;
      equation 
        at = Exp.typeof(e);
        false = Types.isArray(tp2);
      then
        Exp.ARRAY(Exp.T_ARRAY(at,{SOME(1)}),true,{e});
    case (e,(n,tp)) /* fallback, use \"builtin\" operator promote */ 
      local Exp.Type etp,tp1;
      equation 
        es = Exp.printExpStr(e);
        etp = Types.elabType(tp);
        tp1 = promoteExpType(etp,n);
      then
        Exp.CALL(Absyn.IDENT("promote"),{e,Exp.ICONST(n)},false,true,tp1);
  end matchcontinue;
end promoteExp2;

function promoteExpType "lifts the type using liftArrayRight n times"
  input Exp.Type inType;
  input Integer n;
  output Exp.Type outType;
algorithm
  outType :=  matchcontinue(inType,n)

    case(inType,0) then inType;
    case(inType,n) 
      local Exp.Type tp1,tp2;
      equation
      tp1=Exp.liftArrayRight(inType,SOME(1));
      tp2 = promoteExpType(tp1,n-1);
    then tp2;
  end matchcontinue;
end promoteExpType; 

protected function elabMatrixSemi "function: elabMatrixSemi
 
  This function elaborates Matrix expressions, e.g. {1,0;2,1} 
  A row is elaborated with elab_matrix_comma.
"
	input Env.Cache inCache;
  input Env.Env inEnv1;
  input list<list<Absyn.Exp>> inAbsynExpLstLst2;
  input Boolean inBoolean3;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption4;
  input Boolean inBoolean5;
  input Integer inInteger6;
  input Boolean performVectorization;
  output Env.Cache outCache;
  output Exp.Exp outExp1;
  output Types.Properties outProperties2;
  output Option<Integer> outInteger3;
  output Option<Integer> outInteger4;
algorithm 
  (outCache,outExp1,outProperties2,outInteger3,outInteger4):=
  matchcontinue (inCache,inEnv1,inAbsynExpLstLst2,inBoolean3,inInteractiveInteractiveSymbolTableOption4,inBoolean5,inInteger6,performVectorization)
    local
      Exp.Exp el_1,el_2,els_1,els_2;
      Types.Properties props,props1,props2;
      tuple<Types.TType, Option<Absyn.Path>> t,t1,t2;
      Integer maxn,dim;
      Option<Integer> dim1,dim2,dim1_1,dim2_1,dim1_2;
      Exp.Type at;
      Boolean a,impl,havereal;
      list<Env.Frame> env;
      list<Absyn.Exp> el;
      Option<Interactive.InteractiveSymbolTable> st;
      list<list<Absyn.Exp>> els;
      Ident el_str,t1_str,t2_str,dim1_str,dim2_str,el_str1;
      Env.Cache cache;
      Boolean doVect;
    case (cache,env,{el},impl,st,havereal,maxn,doVect) /* implicit inst. contain real maxn */ 
      equation 
        (cache,el_1,(props as Types.PROP(t,_)),dim1,dim2) = elabMatrixComma(cache,env, el, impl, st, havereal, maxn,doVect);
        at = Types.elabType(t);
        a = Types.isPropArray(props);
        el_2 = elabMatrixCatTwoExp(el_1);
      then
        (cache,el_2,props,dim1,dim2);
    case (cache,env,(el :: els),impl,st,havereal,maxn,doVect)
      equation 
        dim = listLength((el :: els));
        (cache,el_1,props1,dim1,dim2) = elabMatrixComma(cache,env, el, impl, st, havereal, maxn,doVect);
        el_2 = elabMatrixCatTwoExp(el_1);
        (cache,els_1,props2,dim1_1,dim2_1) = elabMatrixSemi(cache,env, els, impl, st, havereal, maxn,doVect);
        els_2 = elabMatrixCatOne({el_2,els_1});
        true = Types.dimensionsEqual(dim2,dim2_1) "semicoloned values a;b must have same no of columns" ;
        dim1_2 = Types.dimensionsAdd(dim1, dim1_1) "number of rows added." ;
        (props) = Types.matchWithPromote(props1, props2, havereal);
      then
        (cache,els_2,props,dim1_2,dim2);
    case (_,_,_,_,_,_,_,_)
      equation 
        Debug.fprint("failtrace", "- elab_matrix_semi failed\n");
      then
        fail();
    case (cache,env,(el :: els),impl,st,havereal,maxn,doVect) /* Error messages */ 
      equation 
        (cache,el_1,Types.PROP(t1,_),_,_) = elabMatrixComma(cache,env, el, impl, st, havereal, maxn,doVect);
        (cache,els_1,Types.PROP(t2,_),_,_) = elabMatrixSemi(cache,env, els, impl, st, havereal, maxn,doVect);
        failure(equality(t1 = t2));
        el_str = Exp.printListStr(el, Dump.printExpStr, ", ");
        t1_str = Types.unparseType(t1);
        t2_str = Types.unparseType(t2);
        Error.addMessage(Error.TYPE_MISMATCH_MATRIX_EXP, {el_str,t1_str,t2_str});
      then
        fail();
    case (cache,env,(el :: els),impl,st,havereal,maxn,doVect)
      equation 
        (cache,el_1,Types.PROP(t1,_),dim1,_) = elabMatrixComma(cache,env, el, impl, st, havereal, maxn,doVect);
        (cache,els_1,props2,_,dim2) = elabMatrixSemi(cache,env, els, impl, st, havereal, maxn,doVect);
        false = Types.dimensionsEqual(dim1,dim2);
        dim1_str = Types.dimensionStr(dim1);
        dim2_str = Types.dimensionStr(dim2);
        el_str = Exp.printListStr(el, Dump.printExpStr, ", ");
        el_str1 = Util.stringAppendList({"[",el_str,"]"});
        Error.addMessage(Error.MATRIX_EXP_ROW_SIZE, {el_str1,dim1_str,dim2_str});
      then
        fail();
  end matchcontinue;
end elabMatrixSemi;

protected function elabBuiltinCardinality "function: elabBuiltinCardinality
  author: PA
  
  This function elaborates the cardinality operator.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp exp_1;
      Exp.ComponentRef cr_1;
      tuple<Types.TType, Option<Absyn.Path>> tp1;
      list<Env.Frame> env;
      Absyn.Exp exp;
      Absyn.ComponentRef cr;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,{(exp as Absyn.CREF(componentReg = cr))},impl) /* impl */ 
      equation 
        (cache,(exp_1 as Exp.CREF(cr_1,_)),Types.PROP(tp1,_),_) = elabExp(cache,env, exp, impl, NONE,true);
      then
        (cache,Exp.CALL(Absyn.IDENT("cardinality"),{exp_1},false,true,Exp.INT()),Types.PROP((Types.T_INTEGER({}),NONE),Types.C_CONST()));
  end matchcontinue;
end elabBuiltinCardinality;

protected function elabBuiltinSize "function: elabBuiltinSize
  
  This function elaborates the size operator.
  Input is the list of arguments to size as Absyn.Exp expressions and the 
  environment, Env.Env.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp dimp,arraycrefe,exp;
      Types.Const c1,c2_1,c,c_1;
      tuple<Types.TType, Option<Absyn.Path>> arrtp;
      Boolean c2,impl;
      list<Env.Frame> env;
      Absyn.Exp arraycr,dim;
      list<Absyn.Exp> expl;
      Env.Cache cache;
    case (cache,env,{arraycr,dim},impl) /* impl */ 
      equation 
        (cache,dimp,Types.PROP(_,c1),_) = elabExp(cache,env, dim, impl, NONE,true) "size(A,x) that returns size of x:th dimension" ;
        (cache,arraycrefe,Types.PROP(arrtp,_),_) = elabExp(cache,env, arraycr, impl, NONE,true);
        c2 = Types.dimensionsKnown(arrtp);
        c2_1 = Types.boolConst(c2);
        c = Types.constAnd(c1, c2_1);
        exp = Exp.SIZE(arraycrefe,SOME(dimp));
      then
        (cache,exp,Types.PROP((Types.T_INTEGER({}),NONE),c));
    case (cache,env,{arraycr},impl)
      local Boolean c;
      equation 
        (cache,arraycrefe,Types.PROP(arrtp,_),_) = elabExp(cache,env, arraycr, impl, NONE,true) "size(A)" ;
        c = Types.dimensionsKnown(arrtp);
        c_1 = Types.boolConst(c);
        exp = Exp.SIZE(arraycrefe,NONE);
      then
        (cache,exp,Types.PROP(
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE),c_1));
    case (cache,env,expl,impl)
      equation 
        Debug.fprint("failtrace", "- elab_builtin_size failed\n");
      then
        fail();
  end matchcontinue;
end elabBuiltinSize;

protected function elabBuiltinFill "function: elabBuiltinFill
 
  This function elaborates the builtin operator fill.
  The input is the arguments to fill as Absyn.Exp expressions and the environment Env.Env
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
	output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp s_1,exp;
      Types.Properties prop;
      list<Exp.Exp> dims_1;
      list<Types.Properties> dimprops;
      tuple<Types.TType, Option<Absyn.Path>> sty;
      list<Values.Value> dimvals;
      list<Env.Frame> env;
      Absyn.Exp s;
      list<Absyn.Exp> dims;
      Boolean impl;
      Ident implstr,expstr,str;
      list<Ident> expstrs;
      Env.Cache cache;
    case (cache,env,(s :: dims),impl) /* impl */ 
      equation 
        (cache,s_1,prop,_) = elabExp(cache,env, s, impl, NONE,true);
        (cache,dims_1,dimprops,_) = elabExpList(cache,env, dims, impl, NONE,true);
        sty = Types.getPropType(prop);
        (cache,dimvals) = Ceval.cevalList(cache,env, dims_1, impl, NONE, Ceval.MSG());
        (cache,exp,prop) = elabBuiltinFill2(cache,env, s_1, sty, dimvals);
      then
        (cache,exp,prop);
    case (cache,env,dims,impl)
      equation 
        Debug.fprint("failtrace", 
          "- elab_builtin_fill: Couldn't elaborate fill(): ");
        implstr = Util.boolString(impl);
        expstrs = Util.listMap(dims, Dump.printExpStr);
        expstr = Util.stringDelimitList(expstrs, ", ");
        str = Util.stringAppendList({expstr," impl=",implstr});
        Debug.fprintln("failtrace", str);
      then
        fail();
  end matchcontinue;
end elabBuiltinFill;

protected function elabBuiltinFill2 "function: elabBuiltinFill2
 
  Helper function to elab_builtin_fill
"
	input Env.Cache inCache;
	input Env.Env inEnv;
  input Exp.Exp inExp;
  input Types.Type inType;
  input list<Values.Value> inValuesValueLst;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inExp,inType,inValuesValueLst)
    local
      list<Exp.Exp> arraylist;
      Ident dimension;
      Exp.Type at;
      Boolean a;
      list<Env.Frame> env;
      Exp.Exp s,exp;
      tuple<Types.TType, Option<Absyn.Path>> sty,ty;
      Integer v;
      Types.Const con;
      list<Values.Value> rest;
      Env.Cache cache;
    case (cache,env,s,sty,{Values.INTEGER(integer = v)})
      equation 
        arraylist = buildExpList(s, v);
        dimension = intString(v);
        at = Types.elabType(sty);
        a = Types.isArray(sty);
      then
        (cache,Exp.ARRAY(at,a,arraylist),Types.PROP((Types.T_ARRAY(Types.DIM(SOME(v)),sty),NONE),
          Types.C_CONST()));
    case (cache,env,s,sty,(Values.INTEGER(integer = v) :: rest))
      equation 
        (cache,exp,Types.PROP(ty,con)) = elabBuiltinFill2(cache,env, s, sty, rest);
        arraylist = buildExpList(exp, v);
        dimension = intString(v);
        at = Types.elabType(ty);
        a = Types.isArray(ty);
      then
        (cache,Exp.ARRAY(at,a,arraylist),Types.PROP((Types.T_ARRAY(Types.DIM(SOME(v)),ty),NONE),Types.C_CONST()));
    case (_,_,_,_,_)
      equation 
        Error.addMessage(Error.INTERNAL_ERROR, {"elab_builtin_fill_2 failed"});
      then
        fail();
  end matchcontinue;
end elabBuiltinFill2;

protected function elabBuiltinTranspose "function: elabBuiltinTranspose
 
  This function elaborates the builtin operator transpose
  The input is the arguments to fill as Absyn.Exp expressions and the environment Env.Env
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Type tp;
      Boolean sc,impl;
      list<Exp.Exp> expl,exp_2;
      Types.ArrayDim d1,d2;
      tuple<Types.TType, Option<Absyn.Path>> eltp,newtp;
      Integer dim1;
      Types.Properties prop;
      list<Env.Frame> env;
      Absyn.Exp matexp;
      Exp.Exp exp_1,exp;
      Env.Cache cache;
    case (cache,env,{matexp},impl) /* impl try symbolically transpose the ARRAY expression */ 
      equation 
        (cache,Exp.ARRAY(tp,sc,expl),Types.PROP((Types.T_ARRAY(d1,(Types.T_ARRAY(d2,eltp),_)),_),_),_) 
        	= elabExp(cache,env, matexp, impl, NONE,true);
        dim1 = Types.arraydimInt(d1);
        exp_2 = elabBuiltinTranspose2(expl, 1, dim1);
        newtp = (Types.T_ARRAY(d2,(Types.T_ARRAY(d1,eltp),NONE)),NONE);
        prop = Types.PROP(newtp,Types.C_VAR());
      then
        (cache,Exp.ARRAY(tp,sc,exp_2),prop);
    case (cache,env,{matexp},impl) /* try symbolically transpose the MATRIX expression */ 
      local
        Integer sc;
        list<list<tuple<Exp.Exp, Boolean>>> expl,exp_2;
      equation 
        (cache,Exp.MATRIX(tp,sc,expl),Types.PROP((Types.T_ARRAY(d1,(Types.T_ARRAY(d2,eltp),_)),_),_),_) 
        	= elabExp(cache,env, matexp, impl, NONE,true);
        dim1 = Types.arraydimInt(d1);
        exp_2 = elabBuiltinTranspose3(expl, 1, dim1);
        newtp = (Types.T_ARRAY(d2,(Types.T_ARRAY(d1,eltp),NONE)),NONE);
        prop = Types.PROP(newtp,Types.C_VAR());
      then
        (cache,Exp.MATRIX(tp,sc,exp_2),prop);
    case (cache,env,{matexp},impl) /* .. otherwise create transpose call */ 
      local Exp.Type tp;
      equation 
        (cache,exp_1,Types.PROP((Types.T_ARRAY(d1,(Types.T_ARRAY(d2,eltp),_)),_),_),_) 
        	= elabExp(cache,env, matexp, impl, NONE,true);
        newtp = (Types.T_ARRAY(d2,(Types.T_ARRAY(d1,eltp),NONE)),NONE);
        tp = Types.elabType(newtp);
        exp = Exp.CALL(Absyn.IDENT("transpose"),{exp_1},false,true,tp);
        prop = Types.PROP(newtp,Types.C_VAR());
      then
        (cache,exp,prop);
  end matchcontinue;
end elabBuiltinTranspose;

protected function elabBuiltinTranspose2 "function: elabBuiltinTranspose2
  author: PA
 
  Helper function to elab_builtin_transpose. Tries to symbolically transpose
  a matrix expression in ARRAY form.
"
  input list<Exp.Exp> inExpExpLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inExpExpLst1,inInteger2,inInteger3)
    local
      Exp.Exp e;
      list<Exp.Exp> es,rest,elst;
      Exp.Type tp;
      Integer indx_1,indx,dim1;
    case (elst,indx,dim1)
      equation 
        (indx <= dim1) = true;
        (e :: es) = Util.listMap1(elst, Exp.nthArrayExp, indx);
        tp = Exp.typeof(e);
        indx_1 = indx + 1;
        rest = elabBuiltinTranspose2(elst, indx_1, dim1);
      then
        (Exp.ARRAY(tp,false,(e :: es)) :: rest);
    case (_,_,_) then {}; 
  end matchcontinue;
end elabBuiltinTranspose2;

protected function elabBuiltinTranspose3 "function: elabBuiltinTranspose3
  author: PA
 
  Helper function to elab_builtin_transpose. Tries to symbolically transpose
  a MATRIX expression list
"
  input list<list<tuple<Exp.Exp, Boolean>>> inTplExpExpBooleanLstLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<list<tuple<Exp.Exp, Boolean>>> outTplExpExpBooleanLstLst;
algorithm 
  outTplExpExpBooleanLstLst:=
  matchcontinue (inTplExpExpBooleanLstLst1,inInteger2,inInteger3)
    local
      Integer lindx,indx_1,indx,dim1;
      tuple<Exp.Exp, Boolean> e;
      list<tuple<Exp.Exp, Boolean>> es;
      Exp.Exp e_1;
      Exp.Type tp;
      list<list<tuple<Exp.Exp, Boolean>>> rest,res,elst;
    case (elst,indx,dim1)
      equation 
        (indx <= dim1) = true;
        lindx = indx - 1;
        (e :: es) = Util.listMap1(elst, list_nth, lindx);
        e_1 = Util.tuple21(e);
        tp = Exp.typeof(e_1);
        indx_1 = indx + 1;
        rest = elabBuiltinTranspose3(elst, indx_1, dim1);
        res = listAppend({(e :: es)}, rest);
      then
        res;
    case (_,_,_) then {}; 
  end matchcontinue;
end elabBuiltinTranspose3;

protected function buildExpList "function: buildExpList
 
  Helper function to e.g. elab_builtin_fill_2. Creates n copies of the same 
  expression given as input.
"
  input Exp.Exp inExp;
  input Integer inInteger;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inExp,inInteger)
    local
      Exp.Exp e;
      Integer c_1,c;
      list<Exp.Exp> rest;
    case (e,0) then {};  /* n */ 
    case (e,1) then {e}; 
    case (e,c)
      equation 
        c_1 = c - 1;
        rest = buildExpList(e, c_1);
      then
        (e :: rest);
  end matchcontinue;
end buildExpList;

protected function elabBuiltinSum "function: elabBuiltinSum
 
  This function elaborates the builtin operator sum.
  The input is the arguments to fill as Absyn.Exp expressions and the environment Env.Env
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
	output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp exp_1,exp_2;
      Types.ArrayDim dim;
      tuple<Types.TType, Option<Absyn.Path>> tp;
      Types.Const c;
      list<Env.Frame> env;
      Absyn.Exp arrexp;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,{arrexp},impl) /* impl */ 
      local String str;
      equation 
        (cache,exp_1,Types.PROP((Types.T_INTEGER({}),_),c),_) = elabExp(cache,env, arrexp, impl, NONE,true);
        str = Dump.printExpStr(arrexp);
        Error.addMessage(Error.BUILTIN_FUNCTION_SUM_HAS_SCALAR_PARAMETER, {str});
      then
         (cache,exp_1,Types.PROP((Types.T_INTEGER({}),NONE),c));
    case (cache,env,{arrexp},impl) /* impl */ 
      local String str;
      equation 
        (cache,exp_1,Types.PROP((Types.T_REAL({}),_),c),_) = elabExp(cache,env, arrexp, impl, NONE,true);
        str = Dump.printExpStr(arrexp);
        Error.addMessage(Error.BUILTIN_FUNCTION_SUM_HAS_SCALAR_PARAMETER, {str});
      then
         (cache,exp_1,Types.PROP((Types.T_REAL({}),NONE),c));
    case (cache,env,{arrexp},impl) /* impl */ 
      local Exp.Type etp; Types.Type t;
      equation 
        (cache,exp_1,Types.PROP(t as (Types.T_ARRAY(dim,tp),_),c),_) = elabExp(cache,env, arrexp, impl, NONE,true);
        tp = Types.arrayElementType(t);        
        etp = Types.elabType(tp);
        exp_2 = elabBuiltinSum2(Exp.CALL(Absyn.IDENT("sum"),{exp_1},false,true,etp));  
      then
        (cache,exp_2,Types.PROP(tp,c)); 
  end matchcontinue;
end elabBuiltinSum;

protected function elabBuiltinSum2 " replaces sum({a1,a2,...an}) with a1+a2+...+an} and
sum([a11,a12,...,a1n;...,am1,am2,..amn]) with a11+a12+...+amn
"
input Exp.Exp inExp;
output Exp.Exp outExp;
algorithm
  outExp := matchcontinue(inExp)
    local 
      Exp.Type ty;
      Boolean sc;
      list<Exp.Exp> expl;
      Exp.Exp e;
      list<list<tuple<Exp.Exp, Boolean>>> mexpl;
      Integer dim;
    case(Exp.CALL(_,{Exp.ARRAY(ty,sc,expl)},_,_,_)) equation
      e = Exp.makeSum(expl);
    then e;
    case(Exp.CALL(_,{Exp.MATRIX(ty,dim,mexpl)},_,_,_)) equation
      expl = Util.listMap(Util.listFlatten(mexpl), Util.tuple21);
      e = Exp.makeSum(expl);
    then e;
      
    case (e) then e;
  end matchcontinue;
end elabBuiltinSum2;

protected function elabBuiltinPre "function: elabBuiltinPre
 
  This function elaborates the builtin operator pre.
  Input is the arguments to the pre operator and the environment, Env.Env.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp exp_1,exp_2;
      tuple<Types.TType, Option<Absyn.Path>> tp;
      Types.Const c;
      list<Env.Frame> env;
      Absyn.Exp exp;
      Boolean impl;
      Ident s,el_str;
      list<Absyn.Exp> expl;
      Env.Cache cache;
    case (cache,env,{exp},impl) /* impl */ 
      local Exp.Type t;
      equation 
        (cache,exp_1,Types.PROP(tp,c),_) = elabExp(cache,env, exp, impl, NONE,true);
        true = Types.basicType(tp);
        t = Types.elabType(tp);
        exp_2 = Exp.CALL(Absyn.IDENT("pre"),{exp_1},false,true,t);
      then
        (cache,exp_2,Types.PROP(tp,c));
    case (cache,env,{exp},impl)
      local Exp.Exp exp;
      equation 
        (cache,exp,Types.PROP(tp,c),_) = elabExp(cache,env, exp, impl, NONE,true);
        false = Types.basicType(tp);
        s = Exp.printExpStr(exp);
        Error.addMessage(Error.OPERAND_BUILTIN_TYPE, {"pre",s});
      then
        fail();
    case (cache,env,expl,_)
      equation 
        el_str = Exp.printListStr(expl, Dump.printExpStr, ", ");
        s = Util.stringAppendList({"pre(",el_str,")"});
        Error.addMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS, {s});
      then
        fail();
  end matchcontinue;
end elabBuiltinPre;

protected function elabBuiltinInitial "function: elabBuiltinInitial
 
  This function elaborates the builtin operator \'initial()\'
  Input is the arguments to the operator, which should be an empty list.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      list<Env.Frame> env;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,{},impl) then (cache,Exp.CALL(Absyn.IDENT("initial"),{},false,true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()));  /* impl */ 
    case (cache,env,_,_)
      equation 
        Error.addMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS, 
          {"initial takes no arguments"});
      then
        fail();
  end matchcontinue;
end elabBuiltinInitial;

protected function elabBuiltinTerminal "function: elabBuiltinTerminal
 
  This function elaborates the builtin operator \'terminal()\'
  Input is the arguments to the operator, which should be an empty list.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      list<Env.Frame> env;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,{},impl) then (cache,Exp.CALL(Absyn.IDENT("terminal"),{},false,true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()));  /* impl */ 
    case (cache,env,_,impl)
      equation 
        Error.addMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS, 
          {"terminal takes no arguments"});
      then
        fail();
  end matchcontinue;
end elabBuiltinTerminal;

protected function elabBuiltinArray "function: elabBuiltinArray
 
  This function elaborates the builtin operator \'array\'. For instance, 
  array(1,4,6) which is the same as {1,4,6}.
  Input is the list of arguments to the operator, as Absyn.Exp list.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      list<Exp.Exp> exp_1,exp_2;
      list<Types.Properties> typel;
      tuple<Types.TType, Option<Absyn.Path>> tp,newtp;
      Types.Const c;
      Integer len;
      Exp.Type newtp_1;
      Boolean scalar,impl;
      Exp.Exp exp;
      list<Env.Frame> env;
      list<Absyn.Exp> expl;
      Env.Cache cache;
    case (cache,env,expl,impl) /* impl */ 
      equation 
        (cache,exp_1,typel,_) = elabExpList(cache,env, expl, impl, NONE,true);
        (exp_2,Types.PROP(tp,c)) = elabBuiltinArray2(exp_1, typel);
        len = listLength(expl);
        newtp = (Types.T_ARRAY(Types.DIM(SOME(len)),tp),NONE);
        newtp_1 = Types.elabType(newtp);
        scalar = Types.isArray(tp);
        exp = Exp.ARRAY(newtp_1,scalar,exp_1);
      then
        (cache,exp,Types.PROP(newtp,c));
  end matchcontinue;
end elabBuiltinArray;

protected function elabBuiltinArray2 "function elabBuiltinArray2.
 
  Helper function to elab_builtin_array.
  Asserts that all types are of same dimensionality and of same 
  builtin types.
"
  input list<Exp.Exp> inExpExpLst;
  input list<Types.Properties> inTypesPropertiesLst;
  output list<Exp.Exp> outExpExpLst;
  output Types.Properties outProperties;
algorithm 
  (outExpExpLst,outProperties):=
  matchcontinue (inExpExpLst,inTypesPropertiesLst)
    local
      list<Exp.Exp> expl,expl_1;
      list<Types.Properties> tpl;
      list<tuple<Types.TType, Option<Absyn.Path>>> tpl_1;
      Types.Properties tp;
    case (expl,tpl)
      equation 
        false = sameDimensions(tpl);
        Error.addMessage(Error.DIFFERENT_DIM_SIZE_IN_ARGUMENTS, {"array"});
      then
        fail();
    case (expl,tpl)
      equation 
        tpl_1 = Util.listMap(tpl, Types.getPropType) "If first elt is Integer but arguments contain Real, convert all to Real" ;
        true = Types.containReal(tpl_1);
        (expl_1,tp) = elabBuiltinArray3(expl, tpl, 
          Types.PROP((Types.T_REAL({}),NONE),Types.C_VAR()));
      then
        (expl_1,tp);
    case (expl,(tpl as (tp :: _)))
      equation 
        (expl_1,tp) = elabBuiltinArray3(expl, tpl, tp);
      then
        (expl_1,tp);
  end matchcontinue;
end elabBuiltinArray2;

protected function elabBuiltinArray3 "function: elab_bultin_array3
 
  Helper function to elab_builtin_array.
"
  input list<Exp.Exp> inExpExpLst;
  input list<Types.Properties> inTypesPropertiesLst;
  input Types.Properties inProperties;
  output list<Exp.Exp> outExpExpLst;
  output Types.Properties outProperties;
algorithm 
  (outExpExpLst,outProperties):=
  matchcontinue (inExpExpLst,inTypesPropertiesLst,inProperties)
    local
      Types.Properties tp,t1;
      Exp.Exp e1_1,e1;
      list<Exp.Exp> expl_1,expl;
      list<Types.Properties> tpl;
    case ({},{},tp) then ({},tp); 
    case ((e1 :: expl),(t1 :: tpl),tp)
      equation 
        (e1_1,_) = Types.matchProp(e1, t1, tp);
        (expl_1,_) = elabBuiltinArray3(expl, tpl, tp);
      then
        ((e1_1 :: expl_1),t1);
  end matchcontinue;
end elabBuiltinArray3;

protected function elabBuiltinZeros "function: elabBuiltinZeros
 
  This function elaborates the builtin operator \'zeros(n)\'.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp e;
      Types.Properties p;
      list<Env.Frame> env;
      list<Absyn.Exp> args;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,args,impl) /* impl */ 
      equation 
        (cache,e,p) = elabBuiltinFill(cache,env, (Absyn.INTEGER(0) :: args), impl);
      then
        (cache,e,p);
  end matchcontinue;
end elabBuiltinZeros;

protected function sameDimensions "function: sameDimensions
 
  This function returns true of all the properties, containing types, 
  have the same dimensions, otherwise false. 
"
  input list<Types.Properties> tpl;
  output Boolean res;
  list<tuple<Types.TType, Option<Absyn.Path>>> tpl_1;
  list<list<Integer>> dimsizes;
algorithm 
  tpl_1 := Util.listMap(tpl, Types.getPropType);
  dimsizes := Util.listMap(tpl_1, Types.getDimensionSizes);
  res := sameDimensions2(dimsizes);
end sameDimensions;

protected function sameDimensions2
  input list<list<Integer>> inIntegerLstLst;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inIntegerLstLst)
    local
      list<list<Integer>> l,restelts;
      list<Integer> elts;
    case (l)
      equation 
        {} = Util.listFlatten(l);
      then
        true;
    case (l)
      equation 
        elts = Util.listMap(l, Util.listFirst);
        restelts = Util.listMap(l, Util.listRest);
        true = sameDimensions3(elts);
        true = sameDimensions2(restelts);
      then
        true;
    case (_) then false; 
  end matchcontinue;
end sameDimensions2;

protected function sameDimensions3 "function: sameDimensions3
 
  Helper function to same_dimensions2
"
  input list<Integer> inIntegerLst;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inIntegerLst)
    local
      Integer i1,i2;
      Boolean res,res2,res_1;
      list<Integer> rest;
    case ({}) then true; 
    case ({_}) then true; 
    case ({i1,i2}) then (i1 == i2); 
    case ((i1 :: (i2 :: rest)))
      equation 
        res = sameDimensions3((i2 :: rest));
        res2 = (i1 == i2);
        res_1 = boolAnd(res, res2);
      then
        res_1;
    case (_) then false; 
  end matchcontinue;
end sameDimensions3;

protected function elabBuiltinOnes "function: elabBuiltinOnes
 
  This function elaborates on the builtin opeator \'ones(n)\'.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp e;
      Types.Properties p;
      list<Env.Frame> env;
      list<Absyn.Exp> args;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,args,impl) /* impl */ 
      equation 
        (cache,e,p) = elabBuiltinFill(cache,env, (Absyn.INTEGER(1) :: args), impl);
      then
        (cache,e,p);
  end matchcontinue;
end elabBuiltinOnes;

protected function elabBuiltinMax "function: elabBuiltinMax
 
   This function elaborates on the builtin operator \'max(v1,v2)\'
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp arrexp_1,s1_1,s2_1;
      tuple<Types.TType, Option<Absyn.Path>> ty,elt_ty;
      Types.Const c,c1,c2;
      list<Env.Frame> env;
      Absyn.Exp arrexp,s1,s2;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,{arrexp},impl) /* impl max(vector) */ 
      local Exp.Type tp;
      equation 
        (cache,arrexp_1,Types.PROP(ty,c),_) = elabExp(cache,env, arrexp, impl, NONE,true);
        elt_ty = Types.arrayElementType(ty);
        tp = Types.elabType(ty);
      then
        (cache,Exp.CALL(Absyn.IDENT("max"),{arrexp_1},false,true,tp),Types.PROP(elt_ty,c));
    case (cache,env,{s1,s2},impl)
      local Exp.Type tp;
      equation 
        (cache,s1_1,Types.PROP(ty,c1),_) = elabExp(cache,env, s1, impl, NONE,true) "max(x,y) where x & y are scalars" ;
        (cache,s2_1,Types.PROP(_,c2),_) = elabExp(cache,env, s2, impl, NONE,true);
        c = Types.constAnd(c1, c2);
        tp = Types.elabType(ty);
      then
        (cache,Exp.CALL(Absyn.IDENT("max"),{s1_1,s2_1},false,true,tp),Types.PROP(ty,c));
  end matchcontinue;
end elabBuiltinMax;

protected function elabBuiltinMin "function: elabBuiltinMin
 
  This function elaborates the builtin operator \'min(a,b)\'
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp arrexp_1,s1_1,s2_1;
      tuple<Types.TType, Option<Absyn.Path>> ty,elt_ty;
      Types.Const c,c1,c2;
      list<Env.Frame> env;
      Absyn.Exp arrexp,s1,s2;
      Boolean impl;
      Env.Cache cache;
      Exp.Type tp;
    case (cache,env,{arrexp},impl) /* impl min(vector) */ 
      equation 
        (cache,arrexp_1,Types.PROP(ty,c),_) = elabExp(cache,env, arrexp, impl, NONE,true);
        elt_ty = Types.arrayElementType(ty);
        tp = Types.elabType(ty);
      then
        (cache,Exp.CALL(Absyn.IDENT("min"),{arrexp_1},false,true,tp),Types.PROP(elt_ty,c));
    case (cache,env,{s1,s2},impl)
      equation 
        (cache,s1_1,Types.PROP(ty,c1),_) = elabExp(cache,env, s1, impl, NONE,true) "min(x,y) where x & y are scalars" ;
        (cache,s2_1,Types.PROP(_,c2),_) = elabExp(cache,env, s2, impl, NONE,true);
        c = Types.constAnd(c1, c2);
        tp = Types.elabType(ty);
      then
        (cache,Exp.CALL(Absyn.IDENT("min"),{s1_1,s2_1},false,true,tp),Types.PROP(ty,c));
  end matchcontinue;
end elabBuiltinMin;

protected function elabBuiltinFloor "function: elabBuiltinFloor
 
  This function elaborates on the builtin operator floor.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp s1_1;
      Types.Const c;
      list<Env.Frame> env;
      Absyn.Exp s1;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,{s1},impl) /* impl */ 
      equation 
        (cache,s1_1,Types.PROP((Types.T_REAL({}),NONE),c),_) = elabExp(cache,env, s1, impl, NONE,true) "print \"# floor function not implemented yet\\n\" &" ;
      then
        (cache,Exp.CALL(Absyn.IDENT("floor"),{s1_1},false,true,Exp.REAL()),Types.PROP((Types.T_INTEGER({}),NONE),c));
  end matchcontinue;
end elabBuiltinFloor;

protected function elabBuiltinCeil "function: elabBuiltinCeil
 
  This function elaborates on the builtin operator ceil.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp s1_1;
      Types.Const c;
      list<Env.Frame> env;
      Absyn.Exp s1;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,{s1},impl) /* impl */ 
      equation 
        (cache,s1_1,Types.PROP((Types.T_REAL({}),NONE),c),_) = elabExp(cache,env, s1, impl, NONE,true);
      then
        (cache,Exp.CALL(Absyn.IDENT("ceil"),{s1_1},false,true,Exp.REAL()),Types.PROP((Types.T_INTEGER({}),NONE),c));
  end matchcontinue;
end elabBuiltinCeil;

protected function elabBuiltinAbs "function: elabBuiltinAbs
 
  This function elaborates on the builtin operator abs
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp s1_1;
      Types.Const c;
      list<Env.Frame> env;
      Absyn.Exp s1;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,{s1},impl) /* impl */ 
      equation 
        (cache,s1_1,Types.PROP((Types.T_REAL({}),NONE),c),_) = elabExp(cache,env, s1, impl, NONE,true);
      then
        (cache,Exp.CALL(Absyn.IDENT("abs"),{s1_1},false,true,Exp.REAL()),Types.PROP((Types.T_REAL({}),NONE),c));
    case (cache,env,{s1},impl)
      equation 
        (cache,s1_1,Types.PROP((Types.T_INTEGER({}),NONE),c),_) = elabExp(cache,env, s1, impl, NONE,true);
      then
        (cache,Exp.CALL(Absyn.IDENT("abs"),{s1_1},false,true,Exp.INT()),Types.PROP((Types.T_INTEGER({}),NONE),c));
  end matchcontinue;
end elabBuiltinAbs;

protected function elabBuiltinSqrt "function: elabBuiltinSqrt
 
  This function elaborates on the builtin operator sqrt.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp s1_1;
      Types.Const c;
      list<Env.Frame> env;
      Absyn.Exp s1;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,{s1},impl) /* impl */ 
      equation 
        (cache,s1_1,Types.PROP((Types.T_REAL({}),NONE),c),_) = elabExp(cache,env, s1, impl, NONE,true);
         /* print \"# sqrt function not implemented yet REAL\\n\" */ 
      then
        (cache,Exp.CALL(Absyn.IDENT("sqrt"),{s1_1},false,true,Exp.REAL()),Types.PROP((Types.T_REAL({}),NONE),c));
  end matchcontinue;
end elabBuiltinSqrt;

protected function elabBuiltinDiv "function: elabBuiltinDiv
 
  This function elaborates on the builtin operator div.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp s1_1,s2_1;
      Types.Const c1,c2,c;
      list<Env.Frame> env;
      Absyn.Exp s1,s2;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,{s1,s2},impl) /* impl */ 
      equation 
        (cache,s1_1,Types.PROP((Types.T_REAL({}),NONE),c1),_) = elabExp(cache,env, s1, impl, NONE,true);
        (cache,s2_1,Types.PROP((Types.T_REAL({}),NONE),c2),_) = elabExp(cache,env, s2, impl, NONE,true);
        c = Types.constAnd(c1, c2);
      then
        (cache,Exp.CALL(Absyn.IDENT("div"),{s1_1,s2_1},false,true,Exp.REAL()),Types.PROP((Types.T_REAL({}),NONE),c));
    case (cache,env,{s1,s2},impl)
      equation 
        (cache,s1_1,Types.PROP((Types.T_INTEGER({}),NONE),c1),_) = elabExp(cache,env, s1, impl, NONE,true);
        (cache,s2_1,Types.PROP((Types.T_REAL({}),NONE),c2),_) = elabExp(cache,env, s2, impl, NONE,true);
        c = Types.constAnd(c1, c2);
      then
        (cache,Exp.CALL(Absyn.IDENT("div"),{s1_1,s2_1},false,true,Exp.REAL()),Types.PROP((Types.T_REAL({}),NONE),c));
    case (cache,env,{s1,s2},impl)
      equation 
        (cache,s1_1,Types.PROP((Types.T_REAL({}),NONE),c1),_) = elabExp(cache,env, s1, impl, NONE,true);
        (cache,s2_1,Types.PROP((Types.T_INTEGER({}),NONE),c2),_) = elabExp(cache,env, s2, impl, NONE,true);
        c = Types.constAnd(c1, c2);
      then
        (cache,Exp.CALL(Absyn.IDENT("div"),{s1_1,s2_1},false,true,Exp.REAL()),Types.PROP((Types.T_REAL({}),NONE),c));
    case (cache,env,{s1,s2},impl)
      equation 
        (cache,s1_1,Types.PROP((Types.T_INTEGER({}),NONE),c1),_) = elabExp(cache,env, s1, impl, NONE,true);
        (cache,s2_1,Types.PROP((Types.T_INTEGER({}),NONE),c2),_) = elabExp(cache,env, s2, impl, NONE,true);
        c = Types.constAnd(c1, c2);
      then
        (cache,Exp.CALL(Absyn.IDENT("div"),{s1_1,s2_1},false,true,Exp.INT()),Types.PROP((Types.T_INTEGER({}),NONE),c));
  end matchcontinue;
end elabBuiltinDiv;

protected function elabBuiltinMod "function: elabBuiltinMod
  This function elaborates on the builtin operator mod.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp s1_1,s2_1;
      Types.Const c1,c2,c;
      list<Env.Frame> env;
      Absyn.Exp s1,s2;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,{s1,s2},impl) /* impl */ 
      equation 
        (cache,s1_1,Types.PROP((Types.T_REAL({}),NONE),c1),_) = elabExp(cache,env, s1, impl, NONE,true);
        (cache,s2_1,Types.PROP((Types.T_REAL({}),NONE),c2),_) = elabExp(cache,env, s2, impl, NONE,true);
        c = Types.constAnd(c1, c2);
      then
        (cache,Exp.CALL(Absyn.IDENT("mod"),{s1_1,s2_1},false,true,Exp.REAL()),Types.PROP((Types.T_REAL({}),NONE),c));
    case (cache,env,{s1,s2},impl)
      equation 
        (cache,s1_1,Types.PROP((Types.T_INTEGER({}),NONE),c1),_) = elabExp(cache,env, s1, impl, NONE,true);
        (cache,s2_1,Types.PROP((Types.T_REAL({}),NONE),c2),_) = elabExp(cache,env, s2, impl, NONE,true);
        c = Types.constAnd(c1, c2);
      then
        (cache,Exp.CALL(Absyn.IDENT("mod"),{s1_1,s2_1},false,true,Exp.REAL()),Types.PROP((Types.T_REAL({}),NONE),c));
    case (cache,env,{s1,s2},impl)
      equation 
        (cache,s1_1,Types.PROP((Types.T_REAL({}),NONE),c1),_) = elabExp(cache,env, s1, impl, NONE,true);
        (cache,s2_1,Types.PROP((Types.T_INTEGER({}),NONE),c2),_) = elabExp(cache,env, s2, impl, NONE,true);
        c = Types.constAnd(c1, c2);
      then
        (cache,Exp.CALL(Absyn.IDENT("mod"),{s1_1,s2_1},false,true,Exp.REAL()),Types.PROP((Types.T_REAL({}),NONE),c));
    case (cache,env,{s1,s2},impl)
      equation 
        (cache,s1_1,Types.PROP((Types.T_INTEGER({}),NONE),c1),_) = elabExp(cache,env, s1, impl, NONE,true);
        (cache,s2_1,Types.PROP((Types.T_INTEGER({}),NONE),c2),_) = elabExp(cache,env, s2, impl, NONE,true);
        c = Types.constAnd(c1, c2);
      then
        (cache,Exp.CALL(Absyn.IDENT("mod"),{s1_1,s2_1},false,true,Exp.INT()),Types.PROP((Types.T_INTEGER({}),NONE),c));
  end matchcontinue;
end elabBuiltinMod;

protected function elabBuiltinRem "function: elab_builtin_sqrt
 
  This function elaborates on the builtin operator rem.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp s1_1,s2_1;
      Types.Const c1,c2,c;
      list<Env.Frame> env;
      Absyn.Exp s1,s2;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,{s1,s2},impl) /* impl */ 
      equation 
        (cache,s1_1,Types.PROP((Types.T_REAL({}),NONE),c1),_) = elabExp(cache,env, s1, impl, NONE,true);
        (cache,s2_1,Types.PROP((Types.T_REAL({}),NONE),c2),_) = elabExp(cache,env, s2, impl, NONE,true);
        c = Types.constAnd(c1, c2);
      then
        (cache,Exp.CALL(Absyn.IDENT("rem"),{s1_1,s2_1},false,true,Exp.REAL()),Types.PROP((Types.T_REAL({}),NONE),c));
    case (cache,env,{s1,s2},impl)
      equation 
        (cache,s1_1,Types.PROP((Types.T_INTEGER({}),NONE),c1),_) = elabExp(cache,env, s1, impl, NONE,true);
        (cache,s2_1,Types.PROP((Types.T_REAL({}),NONE),c2),_) = elabExp(cache,env, s2, impl, NONE,true);
        c = Types.constAnd(c1, c2);
      then
        (cache,Exp.CALL(Absyn.IDENT("rem"),{s1_1,s2_1},false,true,Exp.REAL()),Types.PROP((Types.T_REAL({}),NONE),c));
    case (cache,env,{s1,s2},impl)
      equation 
        (cache,s1_1,Types.PROP((Types.T_REAL({}),NONE),c1),_) = elabExp(cache,env, s1, impl, NONE,true);
        (cache,s2_1,Types.PROP((Types.T_INTEGER({}),NONE),c2),_) = elabExp(cache,env, s2, impl, NONE,true);
        c = Types.constAnd(c1, c2);
      then
        (cache,Exp.CALL(Absyn.IDENT("rem"),{s1_1,s2_1},false,true,Exp.REAL()),Types.PROP((Types.T_REAL({}),NONE),c));
    case (cache,env,{s1,s2},impl)
      equation 
        (cache,s1_1,Types.PROP((Types.T_INTEGER({}),NONE),c1),_) = elabExp(cache,env, s1, impl, NONE,true);
        (cache,s2_1,Types.PROP((Types.T_INTEGER({}),NONE),c2),_) = elabExp(cache,env, s2, impl, NONE,true);
        c = Types.constAnd(c1, c2);
      then
        (cache,Exp.CALL(Absyn.IDENT("rem"),{s1_1,s2_1},false,true,Exp.REAL()),Types.PROP((Types.T_INTEGER({}),NONE),c));
  end matchcontinue;
end elabBuiltinRem;

protected function elabBuiltinInteger "function: elabBuiltinInteger
 
  This function elaborates on the builtin operator integer, which extracts 
  the Integer value of a Real value.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp s1_1;
      Types.Const c;
      list<Env.Frame> env;
      Absyn.Exp s1;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,{s1},impl) /* impl */ 
      equation 
        (cache,s1_1,Types.PROP((Types.T_REAL({}),NONE),c),_) = elabExp(cache,env, s1, impl, NONE,true);
         /* print \"# integer function not implemented yet REAL\\n\" */ 
      then
        (cache,Exp.CALL(Absyn.IDENT("integer"),{s1_1},false,true,Exp.INT()),Types.PROP((Types.T_INTEGER({}),NONE),c));
  end matchcontinue;
end elabBuiltinInteger;

protected function elabBuiltinDiagonal "function: elabBuiltinDiagonal
 
  This function elaborates on the builtin operator diagonal, creating a
  matrix with a value of the diagonal. The other elements are zero.
"
	input Env.Cache cache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Type tp;
      Boolean sc,impl;
      list<Exp.Exp> expl;
      Types.ArrayDim dim;
      Integer dimension;
      tuple<Types.TType, Option<Absyn.Path>> arrType;
      Types.Const c;
      Exp.Exp res,s1_1;
      list<Env.Frame> env;
      Absyn.Exp v1,s1;
      Env.Cache cache;
    case (cache,env,{v1},impl) /* impl */ 
      equation 
        (cache,Exp.ARRAY(tp,sc,expl),Types.PROP((Types.T_ARRAY((dim as Types.DIM(SOME(dimension))),arrType),NONE),c),_) 
        	= elabExp(cache,env, v1, impl, NONE,true);
        res = elabBuiltinDiagonal2(expl);
      then
        (cache,res,Types.PROP(
          (Types.T_ARRAY(dim,(Types.T_ARRAY(dim,arrType),NONE)),NONE),c));
    case (cache,env,{s1},impl)
      local Types.Type t; Exp.Type tp;
      equation 
        (cache,s1_1,Types.PROP((Types.T_ARRAY((dim as Types.DIM(SOME(dimension))),arrType),NONE),c),_) 
        	= elabExp(cache,env, s1, impl, NONE,true);
         /* print \"# integer function not implemented yet REAL\\n\" */ 
         t = (Types.T_ARRAY(dim,(Types.T_ARRAY(dim,arrType),NONE)),NONE);
         tp = Types.elabType(t);
      then
        (cache,Exp.CALL(Absyn.IDENT("diagonal"),{s1_1},false,true,tp),Types.PROP(t,c));
    case (_,_,_,_)
      equation 
        print(
          "#-- elab_builtin_diagonal: Couldn't elaborate diagonal()\n");
      then
        fail();
  end matchcontinue;
end elabBuiltinDiagonal;

protected function elabBuiltinDiagonal2 "function: elabBuiltinDiagonal2
  author: PA
 
  Tries to symbolically simplify diagonal.
  For instance diagonal({a,b}) => {a,0;0,b}
"
  input list<Exp.Exp> expl;
  output Exp.Exp res;
  Integer dim;
algorithm 
  dim := listLength(expl);
  res := elabBuiltinDiagonal3(expl, 0, dim);
end elabBuiltinDiagonal2;

protected function elabBuiltinDiagonal3
  input list<Exp.Exp> inExpExpLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  output Exp.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExpExpLst1,inInteger2,inInteger3)
    local
      Exp.Type tp;
      Boolean sc;
      list<Boolean> scs;
      list<Exp.Exp> expl,expl_1,es;
      list<tuple<Exp.Exp, Boolean>> row;
      Exp.Exp e;
      Integer indx,dim,indx_1,mdim;
      list<list<tuple<Exp.Exp, Boolean>>> rows;
    case ({e},indx,dim)
      equation 
        tp = Exp.typeof(e);
        sc = Exp.typeBuiltin(tp);
        scs = Util.listFill(sc, dim);
        expl = Util.listFill(Exp.ICONST(0), dim);
        expl_1 = Util.listReplaceat(e, indx, expl);
        row = Util.listThreadTuple(expl_1, scs);
      then
        Exp.MATRIX(tp,dim,{row});
    case ((e :: es),indx,dim)
      equation 
        indx_1 = indx + 1;
        Exp.MATRIX(tp,mdim,rows) = elabBuiltinDiagonal3(es, indx_1, dim);
        tp = Exp.typeof(e);
        sc = Exp.typeBuiltin(tp);
        scs = Util.listFill(sc, dim);
        expl = Util.listFill(Exp.ICONST(0), dim);
        expl_1 = Util.listReplaceat(e, indx, expl);
        row = Util.listThreadTuple(expl_1, scs);
      then
        Exp.MATRIX(tp,mdim,(row :: rows));
  end matchcontinue;
end elabBuiltinDiagonal3;

protected function elabBuiltinDifferentiate "function: elabBuiltinDifferentiate
 
  This function elaborates on the builtin operator differentiate, 
  by deriving the Exp
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      list<Absyn.ComponentRef> cref_list1,cref_list2,cref_list;
      Interactive.InteractiveSymbolTable symbol_table;
      list<Env.Frame> gen_env,env;
      Exp.Exp s1_1,s2_1;
      Types.Properties st;
      Absyn.Exp s1,s2;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,{s1,s2},impl) /* impl */ 
      equation 
        cref_list1 = Absyn.getCrefFromExp(s1);
        cref_list2 = Absyn.getCrefFromExp(s2);
        cref_list = listAppend(cref_list1, cref_list2);
        symbol_table = absynCrefListToInteractiveVarList(cref_list, Interactive.emptySymboltable, 
          (Types.T_REAL({}),NONE));
        gen_env = Interactive.buildEnvFromSymboltable(symbol_table);
        (cache,s1_1,st,_) = elabExp(cache,gen_env, s1, impl, NONE,true);
        (cache,s2_1,st,_) = elabExp(cache,gen_env, s2, impl, NONE,true);
      then
        (cache,Exp.CALL(Absyn.IDENT("differentiate"),{s1_1,s2_1},false,true,Exp.REAL()),st);
    case (_,_,_,_)
      equation 
        print(
          "#-- elab_builtin_differentiate: Couldn't elaborate differentiate()\n");
      then
        fail();
  end matchcontinue;
end elabBuiltinDifferentiate;

protected function elabBuiltinSimplify "function: elabBuiltinSimplify
 
  This function elaborates the simplify function.
  The call in mosh is: simplify(x+yx-x,\"Real\") if the variable should be 
  Real or simplify(x+yx-x,\"Integer\") if the variable should be Integer
  This function is only for testing Exp.simplify
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      list<Absyn.ComponentRef> cref_list;
      Interactive.InteractiveSymbolTable symbol_table;
      list<Env.Frame> gen_env,env;
      Exp.Exp s1_1;
      Types.Properties st;
      Absyn.Exp s1;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,{s1,Absyn.STRING(value = "Real")},impl) /* impl */ 
      equation 
        cref_list = Absyn.getCrefFromExp(s1);
        symbol_table = absynCrefListToInteractiveVarList(cref_list, Interactive.emptySymboltable, 
          (Types.T_REAL({}),NONE));
        gen_env = Interactive.buildEnvFromSymboltable(symbol_table);
        (cache,s1_1,st,_) = elabExp(cache,gen_env, s1, impl, NONE,true);
      then
        (cache,Exp.CALL(Absyn.IDENT("simplify"),{s1_1},false,true,Exp.REAL()),st);
    case (cache,env,{s1,Absyn.STRING(value = "Integer")},impl)
      equation 
        cref_list = Absyn.getCrefFromExp(s1);
        symbol_table = absynCrefListToInteractiveVarList(cref_list, Interactive.emptySymboltable, 
          (Types.T_INTEGER({}),NONE));
        gen_env = Interactive.buildEnvFromSymboltable(symbol_table);
        (cache,s1_1,st,_) = elabExp(cache,gen_env, s1, impl, NONE,true);
      then
        (cache,Exp.CALL(Absyn.IDENT("simplify"),{s1_1},false,true,Exp.INT()),st);
    case (_,_,_,_)
      equation 
        print("#-- elab_builtin_simplify: Couldn't elaborate simplify()\n");
      then
        fail();
  end matchcontinue;
end elabBuiltinSimplify;

protected function absynCrefListToInteractiveVarList "function: absynCrefListToInteractiveVarList
 
  Creates Interactive variables from the list of component references. Each
  variable will get a value that is the AST code for the variable itself.
  This is used when calling differentiate, etc., to be able to evaluate
  a variable and still get the variable name.
"
  input list<Absyn.ComponentRef> inAbsynComponentRefLst;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Types.Type inType;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  outInteractiveSymbolTable:=
  matchcontinue (inAbsynComponentRefLst,inInteractiveSymbolTable,inType)
    local
      Interactive.InteractiveSymbolTable symbol_table,symbol_table_1,symbol_table_2;
      Absyn.Path path;
      Ident path_str;
      Absyn.ComponentRef cr;
      list<Absyn.ComponentRef> rest;
      tuple<Types.TType, Option<Absyn.Path>> tp;
    case ({},symbol_table,_) then symbol_table; 
    case ((cr :: rest),symbol_table,tp)
      equation 
        path = Absyn.crefToPath(cr);
        path_str = Absyn.pathString(path);
        symbol_table_1 = Interactive.addVarToSymboltable(path_str, Values.CODE(Absyn.C_VARIABLENAME(cr)), tp, 
          symbol_table);
        symbol_table_2 = absynCrefListToInteractiveVarList(rest, symbol_table_1, tp);
      then
        symbol_table_2;
    case (_,_,_)
      equation 
        Debug.fprint("failtrace", 
          "-absyn_cref_list_to_interactive_var_list failed\n");
      then
        fail();
  end matchcontinue;
end absynCrefListToInteractiveVarList;

protected function elabBuiltinDymtabletimeini "function: elabBuiltinDymtabletimeini
 
  This function elaborates on the function dymtabletimeini, which is a Dymola
  builtin function for table initialization. Should probably be removed in the future.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp e1_1,e2_1,e3_1,e4_1,e5_1,e6_1;
      Types.Const c;
      Types.ArrayDim dim;
      tuple<Types.TType, Option<Absyn.Path>> arrType;
      list<Env.Frame> env;
      Absyn.Exp e1,e2,e3,e4,e5,e6;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,{e1,e2,e3,e4,e5,e6},impl) /* impl */ 
      equation 
        (cache,e1_1,Types.PROP((Types.T_REAL({}),NONE),c),_) = elabExp(cache,env, e1, impl, NONE,true);
        (cache,e2_1,Types.PROP((Types.T_INTEGER({}),NONE),c),_) = elabExp(cache,env, e2, impl, NONE,true);
        (cache,e3_1,Types.PROP((Types.T_STRING({}),NONE),c),_) = elabExp(cache,env, e3, impl, NONE,true);
        (cache,e4_1,Types.PROP((Types.T_STRING({}),NONE),c),_) = elabExp(cache,env, e4, impl, NONE,true);
        (cache,e5_1,Types.PROP((Types.T_ARRAY(dim,arrType),NONE),c),_) = elabExp(cache,env, e5, impl, NONE,true);
        (cache,e6_1,Types.PROP((Types.T_INTEGER({}),NONE),c),_) = elabExp(cache,env, e6, impl, NONE,true);
         /* print \"# integer function not implemented yet REAL\\n\" */ 
      then
        (cache,Exp.CALL(Absyn.IDENT("dymTableTimeIni"),
          {e1_1,e2_1,e3_1,e4_1,e5_1,e6_1},false,true,Exp.REAL()),Types.PROP((Types.T_REAL({}),NONE),Types.C_VAR()));
    case (_,_,_,_)
      equation 
        print(
          "#-- elab_builtin_dymtabletimeini: Couldn't elaborate diagonal()\n");
      then
        fail();
  end matchcontinue;
end elabBuiltinDymtabletimeini;

protected function elabBuiltinNoevent "function: elabBuiltinNoevent
 
  The builtin operator noevent makes sure that events are not generated
  for the expression.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp exp_1;
      Types.Properties prop;
      list<Env.Frame> env;
      Absyn.Exp exp;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,{exp},impl) /* impl */ 
      equation 
        (cache,exp_1,prop,_) = elabExp(cache,env, exp, impl, NONE,true);
      then
        (cache,Exp.CALL(Absyn.IDENT("noEvent"),{exp_1},false,true,Exp.BOOL()),prop);
  end matchcontinue;
end elabBuiltinNoevent;

protected function elabBuiltinEdge "function: elabBuiltinEdge
 
  This function handles the built in edge operator. If the operand is 
  constant edge is always false.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp exp_1,exp_2;
      list<Env.Frame> env;
      Absyn.Exp exp;
      Boolean impl;
      Types.Const c;
      Env.Cache cache;
    case (cache,env,{exp},impl) /* impl Constness: C_VAR */ 
      equation 
        (cache,exp_1,Types.PROP((Types.T_BOOL({}),_),Types.C_VAR()),_) = elabExp(cache,env, exp, impl, NONE,true);
      then
        (cache,Exp.CALL(Absyn.IDENT("edge"),{exp_1},false,true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()));
    case (cache,env,{exp},impl) /* constness: C_PARAM & C_CONST */ 
      equation 
        (cache,exp_1,Types.PROP((Types.T_BOOL({}),_),c),_) = elabExp(cache,env, exp, impl, NONE,true);
        exp_2 = valueExp(Values.BOOL(false));
      then
        (cache,exp_2,Types.PROP((Types.T_BOOL({}),NONE),c));
    case (_,env,_,_)
      equation 
        Error.addMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS, {"edge"});
      then
        fail();
  end matchcontinue;
end elabBuiltinEdge;

protected function elabBuiltinSign "function: elabBuiltinSign
 
  This function handles the built in sign operator. 
  sign(v) is expanded into (if v>0 then 1 else if v < 0 then -1 else 0)
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp exp_1,exp_2;
      list<Env.Frame> env;
      list<Absyn.Exp> expl;
      Absyn.Exp exp;
      Boolean impl;
      Types.Const c;
      Types.Type tp1;
      Exp.Type tp_1;
      Exp.Exp zero,one;
      Env.Cache cache;
    case (cache,env,{exp},impl) /* Argument to sign must be an Integer or Real expression */ 
      equation 
        (cache,exp_1,Types.PROP(tp1,c),_) = elabExp(cache,env, exp, impl, NONE,true);
        Types.integerOrReal(tp1);
        tp_1 = Types.elabType(tp1);
        zero = Exp.makeConstZero(tp_1);
        one = Exp.makeConstOne(tp_1);
      then
        (cache, 
        // Expanded to : (if v>0 then 1 else if v < 0 then -1 else 0)
        Exp.IFEXP(Exp.RELATION(exp_1,Exp.GREATER(tp_1),zero), 
        					one,
        					Exp.IFEXP(Exp.RELATION(exp_1,Exp.LESS(tp_1),zero),
        										Exp.UNARY(Exp.UMINUS(tp_1),one),
        										zero)),
        Types.PROP(tp1,c));
    case (cache,env,expl,_)
      local String s;
      equation 
        s = Util.stringDelimitList(Util.listMap(expl, Dump.printExpStr),", ");
				s = Util.stringAppendList({"sign(",s,")"});
        Error.addMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS, {s});
      then
        fail();
  end matchcontinue;
end elabBuiltinSign;

protected function elabBuiltinDer "function: elabBuiltinDer
 
  This function handles the built in der operator.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsaynExpLst,inBoolean)
    local
      Exp.Exp e,exp_1;
      Types.Properties prop;
      list<Env.Frame> env;
      Absyn.Exp exp;
      Absyn.ComponentRef cr;
      Boolean impl;
      Types.Const c;
      list<Ident> lst;
      Ident s;
      list<Absyn.Exp> expl;
      Env.Cache cache;
    case (cache,env,{(exp as Absyn.CREF(componentReg = cr))},impl) /* impl use elab_call_args to also try vectorized calls */ 
      equation 
        (cache,e,(prop as Types.PROP(_,Types.C_VAR()))) = elabCallArgs(cache,env, Absyn.IDENT("der"), {exp}, {}, impl, NONE);
      then
        (cache,e,prop);
    case (cache,env,{(exp as Absyn.CREF(componentReg = cr))},impl) /* Constant expressions should fail */ 
      equation 
        (cache,exp_1,Types.PROP((Types.T_REAL({}),_),c),_) = elabExp(cache,env, exp, impl, NONE,true);
        Error.addMessage(Error.DER_APPLIED_TO_CONST, {});
      then
        fail();
    case (cache,env,expl,_)
      equation 
        lst = Util.listMap(expl, Dump.printExpStr);
        s = Util.stringDelimitList(lst, ", ");
        s = Util.stringAppendList({"der(",s,")'.\n"});
        Error.addMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS, {s});
      then
        fail();
  end matchcontinue;
end elabBuiltinDer;

protected function elabBuiltinSample "function: elabBuiltinSample
  author: PA
 
  This function handles the built in sample operator.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp start_1,interval_1;
      tuple<Types.TType, Option<Absyn.Path>> tp1,tp2;
      list<Env.Frame> env;
      Absyn.Exp start,interval;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,{start,interval},impl) /* impl */ 
      equation 
        (cache,start_1,Types.PROP(tp1,_),_) = elabExp(cache,env, start, impl, NONE,true);
        (cache,interval_1,Types.PROP(tp2,_),_) = elabExp(cache,env, interval, impl, NONE,true);
        Types.integerOrReal(tp1);
        Types.integerOrReal(tp2);
      then
        (cache,Exp.CALL(Absyn.IDENT("sample"),{start_1,interval_1},false,true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()));
    case (cache,env,{start,interval},impl)
      equation 
        (cache,start_1,Types.PROP(tp1,_),_) = elabExp(cache,env, start, impl, NONE,true);
        failure(Types.integerOrReal(tp1));
        Error.addMessage(Error.ARGUMENT_MUST_BE_INTEGER_OR_REAL, {"First","sample"});
      then
        fail();
    case (cache,env,{start,interval},impl)
      equation 
        (cache,start_1,Types.PROP(tp1,_),_) = elabExp(cache,env, interval, impl, NONE,true);
        failure(Types.integerOrReal(tp1));
        Error.addMessage(Error.ARGUMENT_MUST_BE_INTEGER_OR_REAL, {"Second","sample"});
      then
        fail();
  end matchcontinue;
end elabBuiltinSample;

protected function elabBuiltinChange "function: elabBuiltinChange
  author: PA
 
  This function handles the built in change operator.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp exp_1;
      Exp.ComponentRef cr_1;
      tuple<Types.TType, Option<Absyn.Path>> tp1;
      list<Env.Frame> env;
      Absyn.Exp exp;
      Absyn.ComponentRef cr;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,{(exp as Absyn.CREF(componentReg = cr))},impl) /* impl simple type, \'discrete\' variable */ 
      equation 
        (cache,(exp_1 as Exp.CREF(cr_1,_)),Types.PROP(tp1,_),_) = elabExp(cache,env, exp, impl, NONE,true);
        Types.simpleType(tp1);
        (cache,Types.ATTR(_,_,SCode.DISCRETE(),_),_,_) = Lookup.lookupVar(cache,env, cr_1);
      then
        (cache,Exp.CALL(Absyn.IDENT("change"),{exp_1},false,true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()));

    case (cache,env,{(exp as Absyn.CREF(componentReg = cr))},impl) /* simple type, boolean or integer => discrete variable */ 
      equation 
        (cache,(exp_1 as Exp.CREF(cr_1,_)),Types.PROP(tp1,_),_) = elabExp(cache,env, exp, impl, NONE,true);
        Types.simpleType(tp1);
        Types.discreteType(tp1);
      then
        (cache,Exp.CALL(Absyn.IDENT("change"),{exp_1},false,true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()));
    case (cache,env,{(exp as Absyn.CREF(componentReg = cr))},impl) /* simple type, constant variability */ 
      equation 
        (cache,(exp_1 as Exp.CREF(cr_1,_)),Types.PROP(tp1,Types.C_CONST()),_) = elabExp(cache,env, exp, impl, NONE,true);
        Types.simpleType(tp1);
      then
        (cache,Exp.CALL(Absyn.IDENT("change"),{exp_1},false,true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()));
    case (cache,env,{(exp as Absyn.CREF(componentReg = cr))},impl) /* simple type, param variability */ 
      equation 
        (cache,(exp_1 as Exp.CREF(cr_1,_)),Types.PROP(tp1,Types.C_PARAM()),_) = elabExp(cache,env, exp, impl, NONE,true);
        Types.simpleType(tp1);
      then
        (cache,Exp.CALL(Absyn.IDENT("change"),{exp_1},false,true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()));
    case (cache,env,{(exp as Absyn.CREF(componentReg = cr))},impl)
      equation 
        (cache,(exp_1 as Exp.CREF(cr_1,_)),Types.PROP(tp1,_),_) = elabExp(cache,env, exp, impl, NONE,true);
        Types.simpleType(tp1);
        (cache,Types.ATTR(_,_,_,_),_,_) = Lookup.lookupVar(cache,env, cr_1);
        Error.addMessage(Error.ARGUMENT_MUST_BE_DISCRETE_VAR, {"First","change"});
      then
        fail();
    case (cache,env,{(exp as Absyn.CREF(componentReg = cr))},impl)
      equation 
        (cache,exp_1,Types.PROP(tp1,_),_) = elabExp(cache,env, exp, impl, NONE,true);
        failure(Types.simpleType(tp1));
        Error.addMessage(Error.TYPE_MUST_BE_SIMPLE, {"operand to change"});
      then
        fail();
    case (cache,env,{exp},impl)
      equation 
        Error.addMessage(Error.ARGUMENT_MUST_BE_VARIABLE, {"First","change"});
      then
        fail();
  end matchcontinue;
end elabBuiltinChange;

protected function elabBuiltinCat "function: elabBuiltinCat
  author: PA
 
  This function handles the built in cat operator.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp dim_exp;
      Types.Const const1,const2,const;
      Integer dim,num_matrices;
      list<Exp.Exp> matrices_1;
      list<Types.Properties> props;
      tuple<Types.TType, Option<Absyn.Path>> result_type,result_type_1;
      list<Env.Frame> env;
      list<Absyn.Exp> matrices;
      Boolean impl;
      Types.Properties tp;
      list<Ident> lst;
      Ident s,str;
      Env.Cache cache;
      Exp.Type etp;
    case (cache,env,(dim :: matrices),impl) /* impl */ 
      equation 
        (cache,dim_exp,Types.PROP((Types.T_INTEGER(_),_),const1),_) = elabExp(cache,env, dim, impl, NONE,true);
        (cache,Values.INTEGER(dim),_) = Ceval.ceval(cache,env, dim_exp, false, NONE, NONE, Ceval.MSG());
        (cache,matrices_1,props,_) = elabExpList(cache,env, matrices, impl, NONE,true);
        true = sameDimensions(props);
        const2 = elabArrayConst(props);
        const = Types.constAnd(const1, const2);
        num_matrices = listLength(matrices_1);
        (Types.PROP(type_ = result_type) :: _) = props;
        result_type_1 = elabBuiltinCat2(result_type, dim, num_matrices);
        etp = Types.elabType(result_type_1);
      then
        (cache,Exp.CALL(Absyn.IDENT("cat"),(dim_exp :: matrices_1),false,true,etp),Types.PROP(result_type_1,const));
    case (cache,env,(dim :: matrices),impl)
      local Absyn.Exp dim;
      equation 
        (cache,dim_exp,tp,_) = elabExp(cache,env, dim, impl, NONE,true);
        failure(Types.PROP((Types.T_INTEGER(_),_),const1) = tp);
        Error.addMessage(Error.ARGUMENT_MUST_BE_INTEGER, {"First","cat"});
      then
        fail();
    case (cache,env,(dim :: matrices),impl)
      local Absyn.Exp dim;
      equation 
        (cache,dim_exp,Types.PROP((Types.T_INTEGER(_),_),const1),_) = elabExp(cache,env, dim, impl, NONE,true);
        (cache,matrices_1,props,_) = elabExpList(cache,env, matrices, impl, NONE,true);
        false = sameDimensions(props);
        lst = Util.listMap((dim :: matrices), Dump.printExpStr);
        s = Util.stringDelimitList(lst, ", ");
        str = Util.stringAppendList({"cat(",s,")"});
        Error.addMessage(Error.DIFFERENT_DIM_SIZE_IN_ARGUMENTS, {str});
      then
        fail();
  end matchcontinue;
end elabBuiltinCat;

protected function elabBuiltinCat2 "function: elabBuiltinCat2
 
  Helper function to elab_builtin_cat. Updates the result type given
  the input type, number of matrices given to cat and dimension to concatenate
  along.
"
  input Types.Type inType1;
  input Integer inInteger2;
  input Integer inInteger3;
  output Types.Type outType;
algorithm 
  outType:=
  matchcontinue (inType1,inInteger2,inInteger3)
    local
      Integer new_d,old_d,n_args,n_1,n;
      tuple<Types.TType, Option<Absyn.Path>> tp,tp_1;
      Option<Absyn.Path> p;
      Types.ArrayDim dim;
    case ((Types.T_ARRAY(arrayDim = Types.DIM(integerOption = SOME(old_d)),arrayType = tp),p),1,n_args) /* dim num_args */ 
      equation 
        new_d = old_d*n_args;
      then
        ((Types.T_ARRAY(Types.DIM(SOME(new_d)),tp),p));
    case ((Types.T_ARRAY(arrayDim = dim,arrayType = tp),p),n,n_args)
      equation 
        n_1 = n - 1;
        tp_1 = elabBuiltinCat2(tp, n_1, n_args);
      then
        ((Types.T_ARRAY(dim,tp_1),p));
  end matchcontinue;
end elabBuiltinCat2;

protected function elabBuiltinIdentity "function: elabBuiltinIdentity
  author: PA
 
  This function handles the built in identity operator.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp dim_exp;
      Integer size;
      list<Env.Frame> env;
      Absyn.Exp dim;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,{dim},impl) /* impl */ 
      equation 
        (cache,dim_exp,Types.PROP((Types.T_INTEGER(_),_),Types.C_CONST()),_) = elabExp(cache,env, dim, impl, NONE,true);
        (cache,Values.INTEGER(size),_) = Ceval.ceval(cache,env, dim_exp, false, NONE, NONE, Ceval.MSG());
      then
        (cache,Exp.CALL(Absyn.IDENT("identity"),{dim_exp},false,true,Exp.INT()),Types.PROP(
          (
          Types.T_ARRAY(Types.DIM(SOME(size)),
          (
          Types.T_ARRAY(Types.DIM(SOME(size)),(Types.T_INTEGER({}),NONE)),NONE)),NONE),Types.C_CONST()));
    case (cache,env,{dim},impl)
      equation 
        (cache,dim_exp,Types.PROP((Types.T_INTEGER(_),_),Types.C_PARAM()),_) = elabExp(cache,env, dim, impl, NONE,true);
        (cache,Values.INTEGER(size),_) = Ceval.ceval(cache,env, dim_exp, false, NONE, NONE, Ceval.MSG());
      then
        (cache,Exp.CALL(Absyn.IDENT("identity"),{dim_exp},false,true,Exp.INT()),Types.PROP(
          (
          Types.T_ARRAY(Types.DIM(SOME(size)),
          (
          Types.T_ARRAY(Types.DIM(SOME(size)),(Types.T_INTEGER({}),NONE)),NONE)),NONE),Types.C_PARAM()));
    case (cache,env,{dim},impl)
      equation 
        (cache,dim_exp,Types.PROP((Types.T_INTEGER(_),_),Types.C_VAR()),_) = elabExp(cache,env, dim, impl, NONE,true);
      then
        (cache,Exp.CALL(Absyn.IDENT("identity"),{dim_exp},false,true,Exp.INT()),Types.PROP(
          (
          Types.T_ARRAY(Types.DIM(NONE),
          (Types.T_ARRAY(Types.DIM(NONE),(Types.T_INTEGER({}),NONE)),
          NONE)),NONE),Types.C_VAR()));
    case (cache,env,{dim},impl)
      equation 
        print("-elab_builtin_identity failed\n");
      then
        fail();
  end matchcontinue;
end elabBuiltinIdentity;

protected function elabBuiltinScalar "function: elab_builtin_
  author: PA
 
  This function handles the built in scalar operator.
  For example, scalar({1}) => 1 or scalar({a}) => a
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp e;
      tuple<Types.TType, Option<Absyn.Path>> tp,scalar_tp,tp_1;
      Types.Const c;
      list<Env.Frame> env;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,{e},impl) /* impl scalar({a}) => a */ 
      equation 
        (cache,Exp.ARRAY(_,_,{e}),Types.PROP(tp,c),_) = elabExp(cache,env, e, impl, NONE,true);
        scalar_tp = Types.unliftArray(tp);
        Types.simpleType(scalar_tp);
      then
        (cache,e,Types.PROP(scalar_tp,c));
    case (cache,env,{e},impl) /* scalar({a}) => a */ 
      equation 
        (cache,Exp.MATRIX(_,_,{{(e,_)}}),Types.PROP(tp,c),_) = elabExp(cache,env, e, impl, NONE,true);
        tp_1 = Types.unliftArray(tp);
        scalar_tp = Types.unliftArray(tp_1);
        Types.simpleType(scalar_tp);
      then
        (cache,e,Types.PROP(scalar_tp,c));
  end matchcontinue;
end elabBuiltinScalar;

protected function elabBuiltinCross "
  author: PA
 
  This function handles the built in cross operator.
  For example, scalar({x[1],x[2],x[3]},{y[1],y[2],y[3]}) 
  => {x[2]*y[3]-x[3]*y[2],x[3]*y[1]-x[1]*y[3],x[1]*y[2]-x[2]*y[1]}
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp e1,e2;
      tuple<Types.TType, Option<Absyn.Path>> tp1,tp2;
      Types.Const c1,c2,c;
      Boolean scalar1,scalar2;
      list<Env.Frame> env;
      Boolean impl;
      Env.Cache cache;
      Absyn.Exp v1,v2;
      list<Exp.Exp> expl1,expl2,expl3;
      Exp.Type etp1,etp2,etp,etp3;
      Types.Type eltTp;
      
			//First, try symbolic simplification      
    case (cache,env,{v1,v2},impl) equation
      (cache,Exp.ARRAY(etp1,scalar1,expl1),Types.PROP(tp1,c1),_) = elabExp(cache,env, v1, impl, NONE,true);
      (cache,Exp.ARRAY(etp2,scalar2,expl2),Types.PROP(tp2,c2),_) = elabExp(cache,env, v2, impl, NONE,true);
      {3} = Types.getDimensionSizes(tp1);
      {3} = Types.getDimensionSizes(tp2);
      expl3 = elabBuiltinCross2(expl1,expl2);
      c = Types.constAnd(c1,c2);
      etp3 = Types.elabType(tp1);
      then 
        (cache,Exp.ARRAY(etp3,scalar1,expl3),Types.PROP(tp1,c));

		//Fallback, use builtin function cross
    case (cache,env,{v1,v2},impl) equation
      (cache,e1,Types.PROP(tp1,c1),_) = elabExp(cache,env, v1, impl, NONE,true);
      (cache,e2,Types.PROP(tp2,c2),_) = elabExp(cache,env, v2, impl, NONE,true);
       {3} = Types.getDimensionSizes(tp1);
       {3} = Types.getDimensionSizes(tp2);
       etp = Exp.typeof(e1);
       eltTp = Types.arrayElementType(tp1);
       then (cache,Exp.CALL(Absyn.IDENT("cross"),{e1,e2},false,true,Exp.T_ARRAY(etp,{SOME(3)})),
         		 Types.PROP((Types.T_ARRAY(Types.DIM(SOME(3)),eltTp),NONE),Types.C_VAR()));
  end matchcontinue;
end elabBuiltinCross;
  
protected function elabBuiltinCross2 "help function to elabBuiltinCross"
	input list<Exp.Exp> v1;
	input list<Exp.Exp> v2;
	output list<Exp.Exp> res;
algorithm
  res := matchcontinue(v1,v2)
  local Exp.Exp x1,x2,x3,y1,y2,y3,p1,p2,r1,r2,r3;
 		
 		// {x[2]*y[3]-x[3]*y[2],x[3]*y[1]-x[1]*y[3],x[1]*y[2]-x[2]*y[1]}
    case({x1,x2,x3},{y1,y2,y3}) equation
    	  r1 = Exp.makeDiff(Exp.makeProductLst({x2,y3}),Exp.makeProductLst({x3,y2}));
    	  r2 = Exp.makeDiff(Exp.makeProductLst({x3,y1}),Exp.makeProductLst({x1,y3}));
    	  r3 = Exp.makeDiff(Exp.makeProductLst({x1,y2}),Exp.makeProductLst({x2,y1}));
    then {r1,r2,r3};
  end matchcontinue; 
end elabBuiltinCross2;

  
protected function elabBuiltinVector "function: elabBuiltinVector
  author: PA
 
  This function handles the built in vector operator.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean)
    local
      Exp.Exp exp;
      tuple<Types.TType, Option<Absyn.Path>> tp,arr_tp;
      Types.Const c;
      Exp.Type tp_1,etp;
      list<Env.Frame> env;
      Absyn.Exp e;
      Boolean impl,scalar;
      list<Exp.Exp> expl,expl_1;
      list<Integer> dims;
      Env.Cache cache;
    case (cache,env,{e},impl) /* impl vector(scalar) = {scalar} */ 
      equation 
        (cache,exp,Types.PROP(tp,c),_) = elabExp(cache,env, e, impl, NONE,true);
        Types.simpleType(tp);
        tp_1 = Types.elabType(tp);
        arr_tp = Types.liftArray(tp, SOME(1));
      then
        (cache,Exp.ARRAY(tp_1,true,{exp}),Types.PROP(arr_tp,c));
    case (cache,env,{e},impl) /* vector(array of scalars) = array of scalars */ 
      equation 
        (cache,Exp.ARRAY(etp,scalar,expl),Types.PROP(tp,c),_) = elabExp(cache,env, e, impl, NONE,true);
        1 = Types.ndims(tp);
      then
        (cache,Exp.ARRAY(etp,scalar,expl),Types.PROP(tp,c));
    case (cache,env,{e},impl) /* vector of multi dimensional array, at most one dim > 1 */ 
      local tuple<Types.TType, Option<Absyn.Path>> tp_1;
      equation 
        (cache,Exp.ARRAY(_,_,expl),Types.PROP(tp,c),_) = elabExp(cache,env, e, impl, NONE,true);
        tp_1 = Types.arrayElementType(tp);
        etp = Types.elabType(tp_1);
        dims = Types.getDimensionSizes(tp);
        expl_1 = elabBuiltinVector2(expl, dims);
      then
        (cache,Exp.ARRAY(etp,true,expl_1),Types.PROP(tp,c));
  end matchcontinue;
end elabBuiltinVector;

protected function elabBuiltinVector2 "function: elabBuiltinVector2
 
  Helper function to elab_builtin_vector.
"
  input list<Exp.Exp> inExpExpLst;
  input list<Integer> inIntegerLst;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inExpExpLst,inIntegerLst)
    local
      list<Exp.Exp> expl_1,expl;
      Integer dim;
      list<Integer> dims;
    case (expl,(dim :: dims))
      equation 
        (dim > 1) = true;
        expl_1 = elabBuiltinVector3(expl) "Util.list_map_1(dims,int_gt,1) => b_lst &
	Util.bool_or_list(b_lst) => false &" ;
      then
        expl_1;
    case ({Exp.ARRAY(array = expl)},(dim :: dims))
      equation 
        expl_1 = elabBuiltinVector2(expl, dims);
      then
        expl_1;
  end matchcontinue;
end elabBuiltinVector2;

protected function elabBuiltinVector3
  input list<Exp.Exp> inExpExpLst;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inExpExpLst)
    local
      Exp.Exp e,expl;
      list<Exp.Exp> es,es_1;
    case ({}) then {}; 
    case ((Exp.ARRAY(array = {expl}) :: es))
      equation 
        {e} = elabBuiltinVector3({expl});
        es = elabBuiltinVector3(es);
      then
        (e :: es);
    case ((e :: es))
      equation 
        es_1 = elabBuiltinVector3(es);
      then
        (e :: es_1);
  end matchcontinue;
end elabBuiltinVector3;

public function elabBuiltinHandlerGeneric "function: elabBuiltinHandlerGeneric
 
  This function dispatches the elaboration of special builtin operators by 
  returning the appropriate function, see also elab_builtin_handler.
  These special builtin operators can not be represented in the 
  environment since they must be generated on the fly, given a generated 
  type.
"
  input Ident inIdent;
  output FuncTypeEnv_EnvAbsyn_ExpLstBooleanToExp_ExpTypes_Properties outFuncTypeEnvEnvAbsynExpLstBooleanToExpExpTypesProperties;
  partial function FuncTypeEnv_EnvAbsyn_ExpLstBooleanToExp_ExpTypes_Properties
	  input Env.Cache inCache;
    input Env.Env inEnv;
    input list<Absyn.Exp> inAbsynExpLst;
    input Boolean inBoolean;
    output Env.Cache outCache;
    output Exp.Exp outExp;
    output Types.Properties outProperties;
  end FuncTypeEnv_EnvAbsyn_ExpLstBooleanToExp_ExpTypes_Properties;
algorithm 
  outFuncTypeEnvEnvAbsynExpLstBooleanToExpExpTypesProperties:=
  matchcontinue (inIdent)
    case "cardinality" then elabBuiltinCardinality;  /* impl */ 
  end matchcontinue;
end elabBuiltinHandlerGeneric;

public function elabBuiltinHandler "function: elabBuiltinHandler
 
  This function dispatches the elaboration of builtin operators by 
  returning the appropriate function. When a new builtin operator is 
  added, a new rule has to be added to this function.
"
  input Ident inIdent;
  output FuncTypeEnv_EnvAbsyn_ExpLstBooleanToExp_ExpTypes_Properties outFuncTypeEnvEnvAbsynExpLstBooleanToExpExpTypesProperties;
  partial function FuncTypeEnv_EnvAbsyn_ExpLstBooleanToExp_ExpTypes_Properties
	  input Env.Cache inCache;
    input Env.Env inEnv;
    input list<Absyn.Exp> inAbsynExpLst;
    input Boolean inBoolean;
    output Env.Cache outCache;
    output Exp.Exp outExp;
    output Types.Properties outProperties;
  end FuncTypeEnv_EnvAbsyn_ExpLstBooleanToExp_ExpTypes_Properties;
algorithm 
  outFuncTypeEnvEnvAbsynExpLstBooleanToExpExpTypesProperties:=
  matchcontinue (inIdent)
    case "size" then elabBuiltinSize;  /* impl */ 

    case "zeros" then elabBuiltinZeros; 

    case "ones" then elabBuiltinOnes; 

    case "fill" then elabBuiltinFill; 

    case "max" then elabBuiltinMax; 

    case "min" then elabBuiltinMin; 

    case "transpose" then elabBuiltinTranspose; 

    case "array" then elabBuiltinArray; 

    case "sum" then elabBuiltinSum; 

    case "pre" then elabBuiltinPre; 

    case "initial" then elabBuiltinInitial; 

    case "terminal" then elabBuiltinTerminal; 

    case "floor" then elabBuiltinFloor; 

    case "ceil" then elabBuiltinCeil; 

    case "abs" then elabBuiltinAbs; 

    case "sqrt" then elabBuiltinSqrt; 

    case "div" then elabBuiltinDiv; 

    case "integer" then elabBuiltinInteger; 

    case "mod" then elabBuiltinMod; 

    case "rem" then elabBuiltinRem; 

    case "diagonal" then elabBuiltinDiagonal; 

    case "differentiate" then elabBuiltinDifferentiate; 

    case "simplify" then elabBuiltinSimplify; 

    case "noEvent" then elabBuiltinNoevent; 

    case "edge" then elabBuiltinEdge; 

    case "sign" then elabBuiltinSign; 

    case "der" then elabBuiltinDer; 

    case "sample" then elabBuiltinSample; 

    case "change" then elabBuiltinChange; 

    case "cat" then elabBuiltinCat; 

    case "identity" then elabBuiltinIdentity; 

    case "vector" then elabBuiltinVector; 

    case "scalar" then elabBuiltinScalar; 
      
    case "cross" then elabBuiltinCross;

    case "dymTableTimeIni" then elabBuiltinDymtabletimeini; 
  end matchcontinue;
end elabBuiltinHandler;

protected function isBuiltinFunc "function: isBuiltinFunc
 
  Returns true if the function name given as argument
  is a builtin function, which either has a elab_builtin_handler function
  or can be found in the builtin environment.
"
	input Env.Cache inCache;
  input Absyn.Path inPath;
  output Env.Cache outCache;
  output Boolean outBoolean;
algorithm 
  (outCache,outBoolean):=
  matchcontinue (inCache,inPath)
    local
      Ident id;
      Absyn.Path path;
      Env.Cache cache;
    case (cache,Absyn.IDENT(name = id))
      equation 
        _ = elabBuiltinHandler(id);
      then
        (cache,true);
    case (cache,path)
      equation 
        (cache,true) = Lookup.isInBuiltinEnv(cache,path);
      then
        (cache,true);
    case (cache,_) then (cache,false); 
  end matchcontinue;
end isBuiltinFunc;

protected function elabCallBuiltin "function: elabCallBuiltin
 
  This function elaborates on builtin operators (such as \"pre\", \"der\" etc.), 
  by calling the builtin handler to retrieve the correct function to call.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inComponentRef,inAbsynExpLst,inBoolean)
    local
      partial function handlerFunc
      	input Env.Cache inCache;
        input list<Env.Frame> inEnvFrameLst;
        input list<Absyn.Exp> inAbsynExpLst;
        input Boolean inBoolean;
        output Env.Cache outCache;
        output Exp.Exp outExp;
        output Types.Properties outProperties;
      end handlerFunc;
      handlerFunc handler;
      Exp.Exp exp;
      Types.Properties prop;
      list<Env.Frame> env;
      Ident name;
      list<Absyn.Exp> args;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,Absyn.CREF_IDENT(name = name,subscripts = {}),args,impl) /* impl for normal builtin operators and functions */ 
      equation 
        handler = elabBuiltinHandler(name);
        (cache,exp,prop) = handler(cache,env, args, impl);
      then
        (cache,exp,prop);
    case (cache,env,Absyn.CREF_IDENT(name = name,subscripts = {}),args,impl) /* For generic types, like e.g. cardinality */ 
      equation 
        handler = elabBuiltinHandlerGeneric(name);
        (cache,exp,prop) = handler(cache,env, args, impl);
      then
        (cache,exp,prop);
  end matchcontinue;
end elabCallBuiltin;

protected function elabCall "function: elabCall
 
  This function elaborates on a function call.  It converts the name
  to a `Path\', and used the `elab_call_args\' to do the rest of the
  work.
 
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outExp,outProperties,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inComponentRef,inAbsynExpLst,inAbsynNamedArgLst,inBoolean,inInteractiveInteractiveSymbolTableOption)
    local
      Exp.Exp e;
      Types.Properties prop;
      Option<Interactive.InteractiveSymbolTable> st,st_1;
      list<Env.Frame> env;
      Absyn.ComponentRef fn;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs;
      Boolean impl;
      Absyn.Path fn_1;
      Ident fnstr,argstr;
      list<Ident> argstrs;
      Env.Cache cache;
    case (cache,env,fn,args,nargs,impl,st) /* impl LS: Check if a builtin function call, e.g. size()
	      and calculate if so */ 
      equation 
        (cache,e,prop,st) = elabCallInteractive(cache,env, fn, args, nargs, impl, st) "Elaborate interactive function calls, such as simulate(), plot() etc." ;
      then
        (cache,e,prop,st);
    case (cache,env,fn,args,nargs,impl,st)
      equation 
        (cache,e,prop) = elabCallBuiltin(cache,env, fn, args, impl) "Built in functions (e.g. \"pre\", \"der\"), have only possitional arguments" ;
      then
        (cache,e,prop,st);
    case (cache,env,fn,args,nargs,(impl as true),st) /* Interactive mode */ 
      equation 
        Debug.fprintln("sei", "elab_call 3");
        fn_1 = Absyn.crefToPath(fn);
        (cache,e,prop) = elabCallArgs(cache,env, fn_1, args, nargs, impl, st);
        (cache,st_1) = generateCompiledFunction(cache,env, fn, e, prop, st);
        Debug.fprint("sei", "elab_call 3 succeeded: ");
        fnstr = Dump.printComponentRefStr(fn);
        Debug.fprintln("sei", fnstr);
      then
        (cache,e,prop,st_1);
    case (cache,env,fn,args,nargs,(impl as false),st) /* Non-interactive mode */ 
      equation 
        Debug.fprint("sei", "elab_call 4: ");
        fnstr = Dump.printComponentRefStr(fn);
        Debug.fprintln("sei", fnstr);
        fn_1 = Absyn.crefToPath(fn);
        (cache,e,prop) = elabCallArgs(cache,env, fn_1, args, nargs, impl, st);
        (cache,st_1) = generateCompiledFunction(cache,env, fn, e, prop, st);
        Debug.fprint("sei", "elab_call 4 succeeded: ");
        Debug.fprintln("sei", fnstr);
      then
        (cache,e,prop,st_1);
    case (cache,env,fn,args,nargs,impl,st)
      equation 
        Debug.fprint("failtrace", "- elab_call failed\n");
        Debug.fprint("failtrace", " function: ");
        fnstr = Dump.printComponentRefStr(fn);
        Debug.fprint("failtrace", fnstr);
        Debug.fprint("failtrace", "   posargs: ");
        argstrs = Util.listMap(args, Dump.printExpStr);
        argstr = Util.stringDelimitList(argstrs, ", ");
        Debug.fprintln("failtrace", argstr);
      then
        fail();
  end matchcontinue;
end elabCall;

protected function elabCallInteractive "function: elabCallInteractive
 
  This function elaborates the functions defined in the interactive environment.
  Since some of these functions are meta-functions, they can not be described in the type 
  system, and is thus given the the type T_NOTYPE
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outExp,outProperties,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inComponentRef,inAbsynExpLst,inAbsynNamedArgLst,inBoolean,inInteractiveInteractiveSymbolTableOption)
    local
      Absyn.Path path,classname;
      Exp.ComponentRef cr_1,cr2_1;
      list<Env.Frame> env;
      Absyn.ComponentRef cr,cr2;
      Boolean impl;
      Interactive.InteractiveSymbolTable st;
      Ident varid,cname_str,filename,str;
      Exp.Exp filenameprefix,startTime,stopTime,numberOfIntervals,method,size_exp,exp_1,bool_exp_1;
      tuple<Types.TType, Option<Absyn.Path>> recordtype;
      list<Absyn.NamedArg> args;
      list<Exp.Exp> vars_1;
      Types.Properties ptop,prop;
      Option<Interactive.InteractiveSymbolTable> st_1;
      Integer size,var_len;
      list<Absyn.Exp> vars;
      Absyn.Exp size_absyn,exp,bool_exp;
      Env.Cache cache;

    case (cache,env,Absyn.CREF_IDENT(name = "typeOf"),{Absyn.CREF(componentReg = Absyn.CREF_IDENT(name = varid,subscripts = {}))},{},impl,SOME(st)) then (cache,Exp.CALL(Absyn.IDENT("typeOf"),
          {Exp.CODE(Absyn.C_VARIABLENAME(Absyn.CREF_IDENT(varid,{})),Exp.OTHER())},false,true,Exp.STRING()),Types.PROP((Types.T_STRING({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "clear"),{},{},impl,SOME(st)) then (cache,Exp.CALL(Absyn.IDENT("clear"),{},false,true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "clearVariables"),{},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("clearVariables"),{},false,true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "list"),{},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("list"),{},false,true,Exp.STRING()),Types.PROP((Types.T_STRING({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "list"),{Absyn.CREF(componentReg = cr)},{},impl,SOME(st))
      local Absyn.Path className;
      equation 
				className = Absyn.crefToPath(cr);	
      then
        (cache,Exp.CALL(Absyn.IDENT("list"),{Exp.CODE(Absyn.C_TYPENAME(className),Exp.OTHER())},false,true,Exp.STRING()),Types.PROP((Types.T_STRING({}),NONE),Types.C_VAR()),SOME(st));

		case (cache,env,Absyn.CREF_IDENT(name = "checkModel"),{Absyn.CREF(componentReg = cr)},{},impl,SOME(st)) 
		  local Absyn.Path className;
		  equation
		  className = Absyn.crefToPath(cr);
		then (cache,Exp.CALL(Absyn.IDENT("checkModel"),
          {Exp.CODE(Absyn.C_TYPENAME(className),Exp.OTHER())},false,true,Exp.STRING()),Types.PROP((Types.T_STRING({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "translateModel"),{Absyn.CREF(componentReg = cr)},args,impl,SOME(st))
      local
        Absyn.Path className;
      equation 
        className = Absyn.crefToPath(cr); 
        cname_str = Absyn.pathString(className);
        (cache,filenameprefix) = getOptionalNamedArg(cache,env, SOME(st), impl, "fileNamePrefix", 
          (Types.T_STRING({}),NONE), args, Exp.SCONST(cname_str));
        recordtype = (
          Types.T_COMPLEX(ClassInf.RECORD("SimulationObject"),
          {
          Types.VAR("flatClass",
          Types.ATTR(false,SCode.RO(),SCode.VAR(),Absyn.BIDIR()),false,(Types.T_STRING({}),NONE),Types.UNBOUND()),
          Types.VAR("exeFile",
          Types.ATTR(false,SCode.RO(),SCode.VAR(),Absyn.BIDIR()),false,(Types.T_STRING({}),NONE),Types.UNBOUND())},NONE),NONE);
      then
        (cache,Exp.CALL(Absyn.IDENT("translateModel"),
          {Exp.CODE(Absyn.C_TYPENAME(className),Exp.OTHER()),filenameprefix},false,true,Exp.STRING()),Types.PROP(recordtype,Types.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "instantiateModel"),{Absyn.CREF(componentReg = cr)},{},impl,SOME(st))
      local Absyn.Path className;
      equation
        className = Absyn.crefToPath(cr); 
        (cache,cr_1) = elabUntypedCref(cache,env, cr, impl);
      then
        (cache, Exp.CALL(Absyn.IDENT("instantiateModel"),
          {Exp.CODE(Absyn.C_TYPENAME(className),Exp.OTHER())},false,true,Exp.STRING()),Types.PROP((Types.T_STRING({}),NONE),Types.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "buildModel"),{Absyn.CREF(componentReg = cr)},args,impl,SOME(st))
      local Absyn.Path className; Exp.Exp storeInTemp;
      equation 
        className = Absyn.crefToPath(cr); 
        (cache,startTime) = getOptionalNamedArg(cache,env, SOME(st), impl, "startTime", (Types.T_REAL({}),NONE), 
          args, Exp.RCONST(0.0));
        (cache,stopTime) = getOptionalNamedArg(cache,env, SOME(st), impl, "stopTime", (Types.T_REAL({}),NONE), 
          args, Exp.RCONST(1.0));
        (cache,numberOfIntervals) = getOptionalNamedArg(cache,env, SOME(st), impl, "numberOfIntervals", 
          (Types.T_INTEGER({}),NONE), args, Exp.ICONST(500));
        (cache,method) = getOptionalNamedArg(cache,env, SOME(st), impl, "method", (Types.T_STRING({}),NONE), 
          args, Exp.SCONST("dassl"));
        cname_str = Absyn.pathString(className);
        (cache,filenameprefix) = getOptionalNamedArg(cache,env, SOME(st), impl, "fileNamePrefix", 
          (Types.T_STRING({}),NONE), args, Exp.SCONST(cname_str));
        (cache,storeInTemp) = getOptionalNamedArg(cache,env, SOME(st), impl, "storeInTemp", 
          (Types.T_BOOL({}),NONE), args, Exp.BCONST(false));  
      then
        (cache,Exp.CALL(Absyn.IDENT("buildModel"),
          {Exp.CODE(Absyn.C_TYPENAME(className),Exp.OTHER()),startTime,stopTime,
          numberOfIntervals,method,filenameprefix,storeInTemp},false,true,Exp.OTHER()),Types.PROP(
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_STRING({}),NONE)),NONE),Types.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "simulate"),{Absyn.CREF(componentReg = cr)},args,impl,SOME(st)) /* Fill in rest of defaults here */ 
      local Absyn.Path className; Exp.Exp storeInTemp;
      equation 
        className = Absyn.crefToPath(cr); 
        (cache,cr_1) = elabUntypedCref(cache,env, cr, impl);
        (cache,startTime) = getOptionalNamedArg(cache,env, SOME(st), impl, "startTime", (Types.T_REAL({}),NONE), 
          args, Exp.RCONST(0.0));
        (cache,stopTime) = getOptionalNamedArg(cache,env, SOME(st), impl, "stopTime", (Types.T_REAL({}),NONE), 
          args, Exp.RCONST(1.0));
        (cache,numberOfIntervals) = getOptionalNamedArg(cache,env, SOME(st), impl, "numberOfIntervals", 
          (Types.T_INTEGER({}),NONE), args, Exp.ICONST(500));
        (cache,method) = getOptionalNamedArg(cache,env, SOME(st), impl, "method", (Types.T_STRING({}),NONE), 
          args, Exp.SCONST("dassl"));
        classname = componentRefToPath(cr_1) "this extracts the fileNamePrefix which is used when generating code and init-file" ;
        cname_str = Absyn.pathString(classname);
        (cache,filenameprefix) = getOptionalNamedArg(cache,env, SOME(st), impl, "fileNamePrefix", 
          (Types.T_STRING({}),NONE), args, Exp.SCONST(cname_str));
         (cache,storeInTemp) = getOptionalNamedArg(cache,env, SOME(st), impl, "storeInTemp", 
          (Types.T_BOOL({}),NONE), args, Exp.BCONST(false));  
        recordtype = (
          Types.T_COMPLEX(ClassInf.RECORD("SimulationResult"),
          {
          Types.VAR("resultFile",
          Types.ATTR(false,SCode.RO(),SCode.VAR(),Absyn.BIDIR()),false,(Types.T_STRING({}),NONE),Types.UNBOUND())},NONE),NONE);
      then
        (cache,Exp.CALL(Absyn.IDENT("simulate"),
          {Exp.CODE(Absyn.C_TYPENAME(className),Exp.OTHER()),startTime,stopTime,
          numberOfIntervals,method,filenameprefix,storeInTemp},false,true,Exp.OTHER()),Types.PROP(recordtype,Types.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "jacobian"),{Absyn.CREF(componentReg = cr)},args,impl,SOME(st)) /* Fill in rest of defaults here */ 
      equation 
        (cache,cr_1) = elabUntypedCref(cache,env, cr, impl);
      then
        (cache,Exp.CALL(Absyn.IDENT("jacobian"),{Exp.CREF(cr_1,Exp.OTHER())},false,
          true,Exp.STRING()),Types.PROP((Types.T_STRING({}),NONE),Types.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "readSimulationResult"),{Absyn.STRING(value = filename),Absyn.ARRAY(arrayExp = vars),size_absyn},args,impl,SOME(st))
      equation 
        vars_1 = elabVariablenames(vars);
        (cache,size_exp,ptop,st_1) = elabExp(cache,env, size_absyn, false, SOME(st),true);
        (cache,Values.INTEGER(size),_) = Ceval.ceval(cache,env, size_exp, false, st_1, NONE, Ceval.MSG());
        var_len = listLength(vars);
      then
        (cache,Exp.CALL(Absyn.IDENT("readSimulationResult"),
          {Exp.SCONST(filename),Exp.ARRAY(Exp.OTHER(),false,vars_1),
          size_exp},false,true,Exp.T_ARRAY(Exp.REAL(),{SOME(var_len),SOME(size)})),Types.PROP(
          (
          Types.T_ARRAY(Types.DIM(SOME(var_len)),
          (
          Types.T_ARRAY(Types.DIM(SOME(size)),(Types.T_REAL({}),NONE)),NONE)),NONE),Types.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "readSimulationResultSize"),{Absyn.STRING(value = filename)},args,impl,SOME(st)) /* elab_variablenames(vars) => vars\' &
	list_length(vars) => var_len */  then (cache, Exp.CALL(Absyn.IDENT("readSimulationResultSize"),
          {Exp.SCONST(filename)},false,true,Exp.OTHER()),Types.PROP((Types.T_INTEGER({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "plot"),{(cr as Absyn.CREF(componentReg = _))},{},impl,SOME(st))
      local Absyn.Exp cr;
      equation 
        vars_1 = elabVariablenames({cr});
      then
        (cache,Exp.CALL(Absyn.IDENT("plot"),{Exp.ARRAY(Exp.OTHER(),false,vars_1)},
          false,true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "plot"),{Absyn.ARRAY(arrayExp = vars)},{},impl,SOME(st))
      equation 
        vars_1 = elabVariablenames(vars);
      then
        (cache,Exp.CALL(Absyn.IDENT("plot"),{Exp.ARRAY(Exp.OTHER(),false,vars_1)},
          false,true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()),SOME(st));

   case (cache,env,Absyn.CREF_IDENT(name = "val"),{(cr as Absyn.CREF(componentReg = _)),(cd as Absyn.REAL(value = _))},{},impl,SOME(st))
      local 
        Absyn.Exp cr,cd;
        Exp.Exp cd1;
      equation 
        vars_1 = elabVariablenames({cr});
        (cache,cd1,ptop,st_1) = elabExp(cache,env, cd, false, SOME(st),true); 
        vars_1 = listAppend(vars_1, {cd1});        
      then
        (cache,Exp.CALL(Absyn.IDENT("val"),{Exp.ARRAY(Exp.OTHER(),false,vars_1)},
          false,true,Exp.REAL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()),SOME(st));

   case (cache,env,Absyn.CREF_IDENT(name = "val"),{(cr as Absyn.CREF(componentReg = _)),(cd as Absyn.INTEGER(value = _))},{},impl,SOME(st))
      local 
        Absyn.Exp cr,cd;
        Exp.Exp cd1;
      equation 
        vars_1 = elabVariablenames({cr});
        (cache,cd1,ptop,st_1) = elabExp(cache,env, cd, false, SOME(st),true); 
        vars_1 = listAppend(vars_1, {cd1});        
      then
        (cache,Exp.CALL(Absyn.IDENT("val"),{Exp.ARRAY(Exp.OTHER(),false,vars_1)},
          false,true,Exp.REAL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "plotParametric"),vars,{},impl,SOME(st)) /* PlotParametric is similar to plot but does not allow a single CREF as an 
   argument as you are plotting at least one variable as a function of another.
   Thus, plotParametric has to take an array as an argument, or two componentRefs. */ 
      equation 
        vars_1 = elabVariablenames(vars);
      then
        (cache,Exp.CALL(Absyn.IDENT("plotParametric"),
          vars_1,false,true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "timing"),{exp},{},impl,SOME(st))
      equation 
        (cache,exp_1,prop,st_1) = elabExp(cache,env, exp, impl, SOME(st),true);
      then
        (cache,Exp.CALL(Absyn.IDENT("timing"),{exp_1},false,true,Exp.REAL()),Types.PROP((Types.T_REAL({}),NONE),Types.C_VAR()),st_1);

    case (cache,env,Absyn.CREF_IDENT(name = "generateCode"),{Absyn.CREF(componentReg = cr)},{},impl,SOME(st))
      local Absyn.Path className;
      equation 
        className = Absyn.crefToPath(cr); 
      then
        (cache,Exp.CALL(Absyn.IDENT("generateCode"),{Exp.CODE(Absyn.C_TYPENAME(className),Exp.OTHER())},
          false,true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "setCompiler"),{Absyn.STRING(value = str)},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("setCompiler"),{Exp.SCONST(str)},false,true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "setCompileCommand"),{Absyn.STRING(value = str)},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("setCompileCommand"),{Exp.SCONST(str)},false,
          true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "setPlotCommand"),{Absyn.STRING(value = str)},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("setPlotCommand"),{Exp.SCONST(str)},false,true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "getSettings"),{},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("getSettings"),{},false,true,Exp.STRING()),Types.PROP((Types.T_STRING({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "setTempDirectoryPath"),{Absyn.STRING(value = str)},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("setTempDirectoryPath"),{Exp.SCONST(str)},
          false,true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()),SOME(st)); 
          
    case (cache,env,Absyn.CREF_IDENT(name = "getTempDirectoryPath"),{},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("getTempDirectoryPath"),
          {},false,true,Exp.STRING()),Types.PROP((Types.T_STRING({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "setInstallationDirectoryPath"),{Absyn.STRING(value = str)},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("setInstallationDirectoryPath"),
          {Exp.SCONST(str)},false,true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()),SOME(st)); 
   
    case (cache,env,Absyn.CREF_IDENT(name = "getInstallationDirectoryPath"),{},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("getInstallationDirectoryPath"),
          {},false,true,Exp.STRING()),Types.PROP((Types.T_STRING({}),NONE),Types.C_VAR()),SOME(st)); 

		case (cache,env,Absyn.CREF_IDENT(name = "setModelicaPath"),{Absyn.STRING(value = str)},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("setModelicaPath"),
          {Exp.SCONST(str)},false,true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "setCompilerFlags"),{Absyn.STRING(value = str)},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("setCompilerFlags"),{Exp.SCONST(str)},false,
          true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "setDebugFlags"),{Absyn.STRING(value = str)},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("setDebugFlags"),{Exp.SCONST(str)},false,true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "cd"),{Absyn.STRING(value = str)},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("cd"),{Exp.SCONST(str)},false,true,Exp.STRING()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "cd"),{},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("cd"),{},false,true,Exp.STRING()),Types.PROP((Types.T_STRING({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "getVersion"),{},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("getVersion"),{},false,true,Exp.STRING()),Types.PROP((Types.T_STRING({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "getTempDirectoryPath"),{},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("getTempDirectoryPath"),{},false,true,Exp.STRING()),Types.PROP((Types.T_STRING({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "system"),{Absyn.STRING(value = str)},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("system"),{Exp.SCONST(str)},false,true,Exp.INT()),Types.PROP((Types.T_INTEGER({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "readFile"),{Absyn.STRING(value = str)},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("readFile"),{Exp.SCONST(str)},false,true,Exp.STRING()),Types.PROP((Types.T_STRING({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "listVariables"),{},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("listVariables"),{},false,true,Exp.OTHER()),Types.PROP(
          (Types.T_ARRAY(Types.DIM(NONE),(Types.T_NOTYPE(),NONE)),NONE),Types.C_VAR()),SOME(st));  /* Returns an array of \"component references\" */ 

    case (cache,env,Absyn.CREF_IDENT(name = "getErrorString"),{},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("getErrorString"),{},false,true,Exp.STRING()),Types.PROP((Types.T_STRING({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "getMessagesString"),{},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("getMessagesString"),{},false,true,Exp.STRING()),Types.PROP((Types.T_STRING({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "getMessagesStringInternal"),{},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("getMessagesStringInternal"),{},false,true,Exp.STRING()),Types.PROP((Types.T_STRING({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "runScript"),{Absyn.STRING(value = str)},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("runScript"),{Exp.SCONST(str)},false,true,Exp.STRING()),Types.PROP((Types.T_STRING({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "loadModel"),{Absyn.CREF(componentReg = cr)},{},impl,SOME(st))
      local Absyn.Path className;
      equation 
        className = Absyn.crefToPath(cr); 
      then
        (cache,Exp.CALL(Absyn.IDENT("loadModel"),{Exp.CODE(Absyn.C_TYPENAME(className),Exp.OTHER())},
          false,true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "deleteFile"),{Absyn.STRING(value = str)},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("deleteFile"),{Exp.SCONST(str)},false,true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "loadFile"),{Absyn.STRING(value = str)},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("loadFile"),{Exp.SCONST(str)},false,true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "saveModel"),{Absyn.STRING(value = str),Absyn.CREF(componentReg = cr)},{},impl,SOME(st))
      local Absyn.Path className;
      equation 
          className = Absyn.crefToPath(cr); 
      then
        (cache,Exp.CALL(Absyn.IDENT("saveModel"),
          {Exp.SCONST(str),Exp.CODE(Absyn.C_TYPENAME(className),Exp.OTHER())},false,true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "save"),{Absyn.CREF(componentReg = cr)},{},impl,SOME(st))
      local Absyn.Path className;
      equation 
        className = Absyn.crefToPath(cr); 
      then
        (cache,Exp.CALL(Absyn.IDENT("save"),{Exp.CODE(Absyn.C_TYPENAME(className),Exp.OTHER())},false,true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "saveAll"),{Absyn.STRING(value = str)},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("saveAll"),{Exp.SCONST(str)},false,true,Exp.BOOL()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "help"),{},{},impl,SOME(st)) then (cache, Exp.CALL(Absyn.IDENT("help"),{},false,true,Exp.STRING()),Types.PROP((Types.T_STRING({}),NONE),Types.C_VAR()),SOME(st)); 

    case (cache,env,Absyn.CREF_IDENT(name = "getUnit"),{Absyn.CREF(componentReg = cr),Absyn.CREF(componentReg = cr2)},{},impl,SOME(st))
      equation 
        (cache,cr_1) = elabUntypedCref(cache,env, cr, impl);
        (cache,cr2_1) = elabUntypedCref(cache,env, cr2, impl);
      then
        (cache,Exp.CALL(Absyn.IDENT("getUnit"),
          {Exp.CREF(cr_1,Exp.OTHER()),Exp.CREF(cr2_1,Exp.OTHER())},false,true,Exp.STRING()),Types.PROP((Types.T_STRING({}),NONE),Types.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "getQuantity"),{Absyn.CREF(componentReg = cr),Absyn.CREF(componentReg = cr2)},{},impl,SOME(st))
      equation 
        (cache,cr_1) = elabUntypedCref(cache,env, cr, impl);
        (cache,cr2_1) = elabUntypedCref(cache,env, cr2, impl);
      then
        (cache,Exp.CALL(Absyn.IDENT("getQuantity"),
          {Exp.CREF(cr_1,Exp.OTHER()),Exp.CREF(cr2_1,Exp.OTHER())},false,true,Exp.STRING()),Types.PROP((Types.T_STRING({}),NONE),Types.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "getDisplayUnit"),{Absyn.CREF(componentReg = cr),Absyn.CREF(componentReg = cr2)},{},impl,SOME(st))
      equation 
        (cache,cr_1) = elabUntypedCref(cache,env, cr, impl);
        (cache,cr2_1) = elabUntypedCref(cache,env, cr2, impl);
      then
        (cache,Exp.CALL(Absyn.IDENT("getDisplayUnit"),
          {Exp.CREF(cr_1,Exp.OTHER()),Exp.CREF(cr2_1,Exp.OTHER())},false,true,Exp.STRING()),Types.PROP((Types.T_STRING({}),NONE),Types.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "getMin"),{Absyn.CREF(componentReg = cr),Absyn.CREF(componentReg = cr2)},{},impl,SOME(st))
      equation 
        (cache,cr_1) = elabUntypedCref(cache,env, cr, impl);
        (cache,cr2_1) = elabUntypedCref(cache,env, cr2, impl);
      then
        (cache,Exp.CALL(Absyn.IDENT("getMin"),
          {Exp.CREF(cr_1,Exp.OTHER()),Exp.CREF(cr2_1,Exp.OTHER())},false,true,Exp.STRING()),Types.PROP((Types.T_REAL({}),NONE),Types.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "getMax"),{Absyn.CREF(componentReg = cr),Absyn.CREF(componentReg = cr2)},{},impl,SOME(st))
      equation 
        (cache,cr_1) = elabUntypedCref(cache,env, cr, impl);
        (cache,cr2_1) = elabUntypedCref(cache,env, cr2, impl);
      then
        (cache,Exp.CALL(Absyn.IDENT("getMax"),
          {Exp.CREF(cr_1,Exp.OTHER()),Exp.CREF(cr2_1,Exp.OTHER())},false,true,Exp.STRING()),Types.PROP((Types.T_REAL({}),NONE),Types.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "getStart"),{Absyn.CREF(componentReg = cr),Absyn.CREF(componentReg = cr2)},{},impl,SOME(st))
      equation 
        (cache,cr_1) = elabUntypedCref(cache,env, cr, impl);
        (cache,cr2_1) = elabUntypedCref(cache,env, cr2, impl);
      then
        (cache,Exp.CALL(Absyn.IDENT("getStart"),
          {Exp.CREF(cr_1,Exp.OTHER()),Exp.CREF(cr2_1,Exp.OTHER())},false,true,Exp.STRING()),Types.PROP((Types.T_REAL({}),NONE),Types.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "getFixed"),{Absyn.CREF(componentReg = cr),Absyn.CREF(componentReg = cr2)},{},impl,SOME(st))
      equation 
        (cache,cr_1) = elabUntypedCref(cache,env, cr, impl);
        (cache,cr2_1) = elabUntypedCref(cache,env, cr2, impl);
      then
        (cache,Exp.CALL(Absyn.IDENT("getFixed"),
          {Exp.CREF(cr_1,Exp.OTHER()),Exp.CREF(cr2_1,Exp.OTHER())},false,true,Exp.STRING()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "getNominal"),{Absyn.CREF(componentReg = cr),Absyn.CREF(componentReg = cr2)},{},impl,SOME(st))
      equation 
        (cache,cr_1) = elabUntypedCref(cache,env, cr, impl);
        (cache,cr2_1) = elabUntypedCref(cache,env, cr2, impl);
      then
        (cache,Exp.CALL(Absyn.IDENT("getNominal"),
          {Exp.CREF(cr_1,Exp.OTHER()),Exp.CREF(cr2_1,Exp.OTHER())},false,true,Exp.STRING()),Types.PROP((Types.T_REAL({}),NONE),Types.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "getStateSelect"),{Absyn.CREF(componentReg = cr),Absyn.CREF(componentReg = cr2)},{},impl,SOME(st))
      equation 
        (cache,cr_1) = elabUntypedCref(cache,env, cr, impl);
        (cache,cr2_1) = elabUntypedCref(cache,env, cr2, impl);
      then
        (cache,Exp.CALL(Absyn.IDENT("getStateSelect"),
          {Exp.CREF(cr_1,Exp.OTHER()),Exp.CREF(cr2_1,Exp.OTHER())},false,true,Exp.STRING()),Types.PROP(
          (
          Types.T_ENUMERATION({"never","avoid","default","prefer","always"},{}),NONE),Types.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "echo"),{bool_exp},{},impl,SOME(st))
      equation 
        (cache,bool_exp_1,prop,st_1) = elabExp(cache,env, bool_exp, impl, SOME(st),true);
      then
        (cache,Exp.CALL(Absyn.IDENT("echo"),{bool_exp_1},false,true,Exp.STRING()),Types.PROP((Types.T_BOOL({}),NONE),Types.C_CONST()),SOME(st));
  end matchcontinue;
end elabCallInteractive;

protected function elabVariablenames "function: elabVariablenames
  This function elaborates variablenames to Exp.Exp. A variablename can
  be used in e.g. plot(model,{v1{3},v2.t}) It should only be used in interactive 
  functions that uses variablenames as componentreferences.
"
  input list<Absyn.Exp> inAbsynExpLst;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inAbsynExpLst)
    local
      Exp.ComponentRef cr_1;
      list<Exp.Exp> xs_1;
      Absyn.ComponentRef cr;
      list<Absyn.Exp> xs;
    case {} then {}; 
    case ((Absyn.CREF(componentReg = cr) :: xs))
      equation 
        
        xs_1 = elabVariablenames(xs);
      then
        (Exp.CODE(Absyn.C_VARIABLENAME(cr),Exp.OTHER()) :: xs_1);
  end matchcontinue;
end elabVariablenames;

protected function getOptionalNamedArg "function: getOptionalNamedArg
   This function is used to \"elaborate\" interactive functions optional parameters, 
  e.g. simulate(A.b, startTime=1), startTime is an optional parameter 
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean inBoolean;
  input Ident inIdent;
  input Types.Type inType;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Exp.Exp inExp;
  output Env.Cache outCache;
  output Exp.Exp outExp;
algorithm 
  (outCache,outExp):=
  matchcontinue (inCache,inEnv,inInteractiveInteractiveSymbolTableOption,inBoolean,inIdent,inType,inAbsynNamedArgLst,inExp)
    local
      Exp.Exp exp,exp_1,exp_2,dexp;
      tuple<Types.TType, Option<Absyn.Path>> t,tp;
      Types.Const c1;
      list<Env.Frame> env;
      Option<Interactive.InteractiveSymbolTable> st;
      Boolean impl;
      Ident id,id2;
      list<Absyn.NamedArg> xs;
      Env.Cache cache;
    case (cache,_,_,_,_,_,{},exp) then (cache,exp);  /* The expected type */ 
    case (cache,env,st,impl,id,tp,(Absyn.NAMEDARG(argName = id2,argValue = exp) :: xs),dexp)
      local Absyn.Exp exp;
      equation 
        equality(id = id2);
        (cache,exp_1,Types.PROP(t,c1),_) = elabExp(cache,env, exp, impl, st,true);
        (exp_2,_) = Types.matchType(exp_1, t, tp);
      then
        (cache,exp_2);
    case (cache,env,st,impl,id,tp,(Absyn.NAMEDARG(argName = id2,argValue = exp) :: xs),dexp)
      local Absyn.Exp exp;
      equation 
        (cache,exp_1) = getOptionalNamedArg(cache,env, st, impl, id, tp, xs, dexp);
      then
        (cache,exp_1);
  end matchcontinue;
end getOptionalNamedArg;

public function elabUntypedCref "function: elabUntypedCref
  This function elaborates a ComponentRef without adding type information. 
   Environment is passed along, such that constant subscripts can be elabed using existing
  functions
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef inComponentRef;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.ComponentRef outComponentRef;
algorithm 
  (outCache,outComponentRef) :=
  matchcontinue (inCache,inEnv,inComponentRef,inBoolean)
    local
      list<Exp.Subscript> subs_1;
      list<Env.Frame> env;
      Ident id;
      list<Absyn.Subscript> subs;
      Boolean impl;
      Exp.ComponentRef cr_1;
      Absyn.ComponentRef cr;
      Env.Cache cache;
    case (cache,env,Absyn.CREF_IDENT(name = id,subscripts = subs),impl) /* impl */ 
      equation 
        (cache,subs_1,_) = elabSubscripts(cache,env, subs, impl);
      then
        (cache,Exp.CREF_IDENT(id,subs_1));
    case (cache,env,Absyn.CREF_QUAL(name = id,subScripts = subs,componentRef = cr),impl)
      equation 
        (cache,subs_1,_) = elabSubscripts(cache,env, subs, impl);
        (cache,cr_1) = elabUntypedCref(cache,env, cr, impl);
      then
        (cache,Exp.CREF_QUAL(id,subs_1,cr_1));
  end matchcontinue;
end elabUntypedCref;

protected function pathToComponentRef "function: pathToComponentRef
  This function tranlates a typename to a variable name.
"
  input Absyn.Path inPath;
  output Exp.ComponentRef outComponentRef;
algorithm 
  outComponentRef:=
  matchcontinue (inPath)
    local
      Ident s,id;
      Exp.ComponentRef cref;
      Absyn.Path path;
    case (Absyn.IDENT(name = s)) then Exp.CREF_IDENT(s,{}); 
    case (Absyn.QUALIFIED(name = id,path = path))
      equation 
        cref = pathToComponentRef(path);
      then
        Exp.CREF_QUAL(id,{},cref);
  end matchcontinue;
end pathToComponentRef;

public function componentRefToPath "function: componentRefToPath
  This function translates a variable name to a type name.
"
  input Exp.ComponentRef inComponentRef;
  output Absyn.Path outPath;
algorithm 
  outPath:=
  matchcontinue (inComponentRef)
    local
      Ident s,id;
      Absyn.Path path;
      Exp.ComponentRef cref;
    case (Exp.CREF_IDENT(ident = s,subscriptLst = {})) then Absyn.IDENT(s); 
    case (Exp.CREF_QUAL(ident = id,componentRef = cref))
      equation 
        path = componentRefToPath(cref);
      then
        Absyn.QUALIFIED(id,path);
  end matchcontinue;
end componentRefToPath;

protected function generateCompiledFunction "function: generateCompiledFunction 
  TODO: This currently only works for top level functions. For functions inside packages 
  we need to reimplement without using lookup functions, since we can not build
  correct env for packages containing functions.   
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef inComponentRef;
  input Exp.Exp inExp;
  input Types.Properties inProperties;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  output Env.Cache outCache;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outInteractiveInteractiveSymbolTableOption) :=
  matchcontinue (inCache,inEnv,inComponentRef,inExp,inProperties,inInteractiveInteractiveSymbolTableOption)
    local
      Absyn.Path pfn,path;
      list<Env.Frame> env,env_1,env_2;
      Absyn.ComponentRef fn,cr;
      Exp.Exp e,exp;
      Types.Properties prop;
      Interactive.InteractiveSymbolTable st;
      Absyn.Program p;
      list<tuple<Absyn.Path, tuple<Types.TType, Option<Absyn.Path>>>> cflist;
      SCode.Class cdef,cls;
      Ident fid,pathstr,filename,str1,str2;
      Option<Absyn.ExternalDecl> extdecl;
      Option<Ident> id,lan;
      Option<Absyn.ComponentRef> out;
      list<Absyn.Exp> args;
      list<SCode.Class> p_1,a;
      list<DAE.Element> d;
      DAE.DAElist d_1;
      list<Ident> libs;
      tuple<Types.TType, Option<Absyn.Path>> t;
      list<Interactive.InstantiatedClass> b;
      list<Interactive.InteractiveVariable> c;
      Env.Cache cache;
    case (cache,env,fn,e,prop,SOME((st as Interactive.SYMBOLTABLE(p,_,_,_,cflist)))) /* axiom generate_compiled_function(_,_,_,_,NONE) => NONE */ 
      equation 
        Debug.fprintln("sei", "generate_compiled_function: start1");
        pfn = Absyn.crefToPath(fn);
        true = isFunctionInCflist(cflist, pfn);
      then
        (cache,SOME(st));
    case (cache,env,fn,e,prop,st) /* Don not compile if is \"known\" external function, e.g. math lib. */ 
      local Option<Interactive.InteractiveSymbolTable> st;
      equation 
        path = Absyn.crefToPath(fn);
        (cache,cdef,env_1) = Lookup.lookupClass(cache,env, path, false);
        SCode.CLASS(name = fid,restriction = SCode.R_EXT_FUNCTION(),parts = SCode.PARTS(used = extdecl)) = cdef;
        SOME(Absyn.EXTERNALDECL(id,lan,out,args,_)) = extdecl;
        Ceval.isKnownExternalFunc(fid, id);
      then
        (cache,st);
    case (cache,env,fn,e,prop,SOME((st as Interactive.SYMBOLTABLE(p,a,b,c,cflist))))
      equation 
        Debug.fprintln("sei", "generate_compiled_function: start2");
        path = Absyn.crefToPath(fn);
        false = isFunctionInCflist(cflist, path);
        (cache,false) = isExternalObjectFunction(cache,env,path);
        p_1 = SCode.elaborate(p);
        Debug.fprintln("sei", "generate_compiled_function: elaborated");
        (cache,cls,env_1) = Lookup.lookupClass(cache,env, path, false) "	Inst.instantiate_implicit(p\') => d & message" ;
        Debug.fprintln("sei", "generate_compiled_function: class looked up");
        (cache,env_2,d) = Inst.implicitFunctionInstantiation(cache,env_1, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          cls, {});
        Debug.fprintln("sei", "generate_compiled_function: function instantiated");
        Print.clearBuf();
        d_1 = ModUtil.stringPrefixParams(DAE.DAE(d));
        libs = Codegen.generateFunctions(d_1);
        Debug.fprintln("sei", "generate_compiled_function: function generated");
        pathstr = ModUtil.pathString2(path, "_");
        filename = stringAppend(pathstr, ".c");
        Print.printBuf(
          "#include \"modelica.h\"\n#include <stdio.h>\n#include <stdlib.h>\n#include <errno.h>\n");
        Print.printBuf(
          "\nint main(int argc, char** argv)\n{\n\n  if (argc != 3)\n    {\n      fprintf(stderr,\"# Incorrrect number of arguments\\n\");\n      return 1;\n    }\n");
        Print.printBuf("    _");
        Print.printBuf(pathstr);
        Print.printBuf("_read_call_write(argv[1],argv[2]);\n  return 0;\n}\n");
        Print.writeBuf(filename);
        Print.clearBuf();
        System.compileCFile(filename);
        t = Types.getPropType(prop) "	& Debug.fprintln(\"sei\", \"generate_compiled_function: compiled\")" ;
      then
        (cache,SOME(Interactive.SYMBOLTABLE(p,a,b,c,((path,t) :: cflist))));
    case (cache,env,fn,e,prop,NONE) /* PROP_TUPLE? */ 
      equation 
        Debug.fprintln("sei", "generate_compiled_function: start3");
      then
        (cache,NONE);
    case (cache,env,cr,exp,prop,st) /* 
  rule	( If fails, skip it. ))
	--------------------------------------------------
	generate_compiled_function(_,_,_,_,st) => st
 */ 
      local Option<Interactive.InteractiveSymbolTable> st;
      equation 
        Debug.fprintln("failtrace", "- generate_compiled_function failed4");
        str1 = Dump.printComponentRefStr(cr);
        str2 = Exp.printExpStr(exp);
        Debug.fprint("failtrace", str1);
        Debug.fprint("failtrace", " -- ");
        Debug.fprintln("failtrace", str2);
      then
        (cache,st);
    case (cache,_,_,_,_,st)
      local Option<Interactive.InteractiveSymbolTable> st;
         /* If fails, skip it. */ 
      then
        (cache,st);
  end matchcontinue;
end generateCompiledFunction;

public function isFunctionInCflist "function: isFunctionInCflist
 
  This function returns true if a function, named by an Absyn.Path, 
  is present in the list of precompiled functions that can be executed
  in the interactive mode.
"
  input list<tuple<Absyn.Path, Types.Type>> inTplAbsynPathTypesTypeLst;
  input Absyn.Path inPath;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inTplAbsynPathTypesTypeLst,inPath)
    local
      Absyn.Path path1,path2;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      list<tuple<Absyn.Path, tuple<Types.TType, Option<Absyn.Path>>>> rest;
      Boolean res;
    case ({},_) then false; 
    case (((path1,ty) :: rest),path2)
      equation 
        true = ModUtil.pathEqual(path1, path2);
      then
        true;
    case (((path1,ty) :: rest),path2)
      equation 
        false = ModUtil.pathEqual(path1, path2);
        res = isFunctionInCflist(rest, path2);
      then
        res;
  end matchcontinue;
end isFunctionInCflist;

protected function elabCallArgs "function: elabCallArgs
 
  Given the name of a function and two lists of expression and 
  NamedArg respectively to be used 
  as actual arguments in a function call to that function, this
  function finds the function definition and matches the actual
  arguments to the formal parameters.
"
	input Env.Cache cache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
	output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties) :=
  matchcontinue (inCache,inEnv,inPath,inAbsynExpLst,inAbsynNamedArgLst,inBoolean,inInteractiveInteractiveSymbolTableOption)
    local
      tuple<Types.TType, Option<Absyn.Path>> t,outtype,restype,functype;
      list<tuple<Ident, tuple<Types.TType, Option<Absyn.Path>>>> fargs;
      list<Env.Frame> env_1,env_2,env;
      list<Slot> slots,newslots,newslots2,slots2;
      list<Exp.Exp> args_1,args_2;
      list<Types.Const> constlist;
      Types.Const const;
      Types.TupleConst tyconst;
      Types.Properties prop,prop_1;
      SCode.Class cl;
      Absyn.Path fn,fn_1;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs;
      Boolean impl,tuple_,builtin;
      Option<Interactive.InteractiveSymbolTable> st;
      list<tuple<Types.TType, Option<Absyn.Path>>> typelist,ktypelist;
      list<Types.ArrayDim> vect_dims;
      Exp.Exp call_exp;
      list<Ident> t_lst;
      Ident fn_str,types_str,scope;
      String s;
      Env.Cache cache;
    case (cache,env,fn,args,nargs,impl,st) /* impl Record constructors, user defined or implicit tuple builtin */ 
      equation 
        (cache,(t as (Types.T_FUNCTION(fargs,(outtype as (Types.T_COMPLEX(ClassInf.RECORD(_),_,_),_))),_)),env_1) 
        	= Lookup.lookupType(cache,env, fn, true);
        slots = makeEmptySlots(fargs);
        (cache,args_1,newslots,constlist) = elabInputArgs(cache,env, args, nargs, slots, impl);
        const = Util.listReduce(constlist, Types.constAnd);
        tyconst = elabConsts(outtype, const);
        prop = getProperties(outtype, tyconst);
        (cl,env_2) = Lookup.lookupRecordConstructorClass(env_1, fn);
        (cache,newslots2) = fillDefaultSlots(cache,newslots, cl, env_2, impl);
        args_2 = expListFromSlots(newslots2);
      then
        (cache,Exp.CALL(fn,args_2,false,false,Exp.OTHER()),prop);
    case (cache,env,fn,args,nargs,impl,st) /* ..Other functions */ 
      local Exp.Type tp;
      equation 
        (cache,typelist as _::_) = Lookup.lookupFunctionsInEnv(cache,env, fn) "PR. A function can have several types. Taking an array with
	 different dimensions as parameter for example. Because of this we
	 cannot just lookup the function name and trust that it
	 returns the correct function. It returns just one
	 functiontype of several possibilites. The solution is to send
	 in the funktion type of the user function and check both the
	 funktion name and the function\'s type. 
	" ;			
        (cache,args_1,constlist,restype,functype,vect_dims,slots) = elabTypes(cache,env, args,nargs, typelist, impl) "The constness of a function depends on the inputs. If all inputs are
	  constant the call itself is constant.
	" ;
	
        fn_1 = deoverloadFuncname(fn, functype);
        tuple_ = isTuple(restype);
        (cache,builtin) = isBuiltinFunc(cache,fn_1);
        const = Util.listReduce(constlist, Types.constAnd);
        (cache,const) = determineConstSpecialFunc(cache,env,const,fn);
        tyconst = elabConsts(restype, const);
        prop = getProperties(restype, tyconst);
 	      tp = Types.elabType(restype);
 	      (cache,args_2,slots2) = addDefaultArgs(cache,env,args_1,fn,slots,impl);
         
        (call_exp,prop_1) = vectorizeCall(Exp.CALL(fn_1,args_2,tuple_,builtin,tp), restype, vect_dims, 
          slots2, prop);
      then
        (cache,call_exp,prop_1);
        
        /*case above failed. Also consider koening lookup.*/
    /*case (cache,env,fn,args,nargs,impl,st)
      equation 
        (cache,ktypelist) = getKoeningFunctionTypes(cache,env, fn, args, nargs, impl)  ;
        (cache,args_1,constlist,restype,functype,vect_dims,slots) = elabTypes(cache,env, args, nargs, ktypelist, impl);
        fn_1 = deoverloadFuncname(fn, functype);
        tuple_ = isTuple(restype);
        (cache,builtin) = isBuiltinFunc(cache,fn_1);
        const = Util.listReduce(constlist, Types.constAnd);
        (cache,const) = determineConstSpecialFunc(cache,env,const,fn);
        tyconst = elabConsts(restype, const);
        prop = getProperties(restype, tyconst);
        (call_exp,prop_1) = vectorizeCall(Exp.CALL(fn_1,args_1,tuple_,builtin), restype, vect_dims, 
          slots, prop);
      then
        (cache,call_exp,prop);*/
    case (cache,env,fn,args,nargs,impl,st) /* no matching type found. */ 
      equation 
        (cache,typelist) = Lookup.lookupFunctionsInEnv(cache,env, fn);
        t_lst = Util.listMap(typelist, Types.unparseType);
        fn_str = Absyn.pathString(fn);
        types_str = Util.stringDelimitList(t_lst, "\n -");
        Error.addMessage(Error.NO_MATCHING_FUNCTION_FOUND, {fn_str,types_str});
      then
        fail();
    case (cache,env,fn,args,nargs,impl,st)
      equation 
        failure((_,_,_) = Lookup.lookupType(cache,env, fn, false)) "msg" ;
        scope = Env.printEnvPathStr(env);
        fn_str = Absyn.pathString(fn);
        Error.addMessage(Error.LOOKUP_ERROR, {fn_str,scope});
      then
        fail();
    case (cache,env,fn,args,nargs,impl,st)
      equation 
        Debug.fprint("failtrace", "- elabCallArgs failed\n") ;
      then
        fail();
  end matchcontinue;
end elabCallArgs;

protected function addDefaultArgs "adds default values (from slots) to argument list of function call.
This is needed because when generating C-code all arguments must be present in the function call. 

If in future C++ code is generated instead, this is not required, since C++ allows default values for arguments.
"
  input Env.Cache inCache;
  input Env.Env env;
  input list<Exp.Exp> inArgs;
  input Absyn.Path fn;
  input list<Slot> slots;
  input Boolean impl;
  output Env.Cache outCache;
  output list<Exp.Exp> outArgs;
  output list<Slot> outSlots;
algorithm
  (outCache,outArgs,outSlots) := matchcontinue(cache,env,inArgs,fn,slots,impl)
    local Env.Cache cache;
      SCode.Class cl;
      Env.Env env_2;
      list<Exp.Exp> args_2;
      list<Slot> slots2;
      // If we find a class
    case(cache,env,inArgs,fn,slots,impl) equation
      // We need the class to fill default slots
      (cache,cl,env_2) = Lookup.lookupClass(cache,env,fn,false);
      (cache,slots2) = fillDefaultSlots(cache,slots, cl, env_2, impl);
      // Update argument list to include default values.
      args_2 = expListFromSlots(slots2);
    then (cache,args_2,slots2);
      
      // If no class found. builtin, with no defaults. NOTE: if builtin class with defaults exist
      // both its type -and- its class must be added to Builtin.mo
    case(cache,env,inArgs,fn,slots,impl) 
    then (cache,inArgs,slots);
  end matchcontinue;
end addDefaultArgs;


protected function determineConstSpecialFunc "For the special functions constructor and destructor,
in external object, 
the constantness is always variable, even if arguments are constant, because they should be called during
runtime and not during compiletime.

"	
	input Env.Cache inCache;
	input Env.Env env;
  input Types.Const inConst;
  input Absyn.Path funcName;
  output Env.Cache outCache;
  output Types.Const outConst;
algorithm
  (outCache,outConst) := matchcontinue(inCache,env,inConst,funcName)
  local Absyn.Path path;
    Env.Cache cache;
    SCode.Class c;
    Env.Env env_1;
    list<SCode.Element> els;
		/* External Object found, constructor call is not constant.*/
    case (cache,env,inConst, path) equation 
      (cache,true) = isExternalObjectFunction(cache,env,path);
      then (cache,Types.C_VAR());        
    case (cache,env,inConst,path) then (cache,inConst);
  end matchcontinue;
end determineConstSpecialFunc;
    
public function isExternalObjectFunction
	input Env.Cache cache;
	input Env.Env env;
	input Absyn.Path path;
  output Env.Cache outCache;
	output Boolean res;
algorithm 
  (outCache,res) := matchcontinue(cache,env,path)
    local Env.Cache cache; Env.Env env_1;
      list<SCode.Element> els;
    case (cache,env,path) equation
      (cache,SCode.CLASS(parts = SCode.PARTS(elementLst = els)),env_1) 
        	= Lookup.lookupClass(cache,env, path, false);
      true = Inst.isExternalObject(els);
      then (cache,true);
    case (cache,env,path) equation
      "constructor" = Absyn.pathLastIdent(path); then (cache,true);
    case (cache,env,path) equation
      "destructor" = Absyn.pathLastIdent(path); then (cache,true);
    case (cache,env,path)  then (cache,false);
  end matchcontinue;
end isExternalObjectFunction;

protected function vectorizeCall "function: vectorizeCall
  author: PA
 
  Takes an expression and a list of array dimensions and the Slot list.
  It will vectorize the expression over the dimension given as array dim
  for the slots which have that dimension.
  For example foo:(Real,Real{:})=> Real
  foo(1:2,{1,2;3,4}) vectorizes with arraydim {2} to 
  {foo(1,{1,2}),foo(2,{3,4})}
"
  input Exp.Exp inExp;
  input Types.Type inType;
  input list<Types.ArrayDim> inTypesArrayDimLst;
  input list<Slot> inSlotLst;
  input Types.Properties inProperties;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outExp,outProperties):=
  matchcontinue (inExp,inType,inTypesArrayDimLst,inSlotLst,inProperties)
    local
      Exp.Exp e,vect_exp,vect_exp_1;
      tuple<Types.TType, Option<Absyn.Path>> e_type,tp,tp_1;
      Types.Properties prop;
      Exp.Type exp_type;
      Types.Const c;
      Absyn.Path fn;
      list<Exp.Exp> args,expl;
      Boolean tuple_,builtin,scalar;
      Integer dim;
      list<Types.ArrayDim> ad;
      list<Slot> slots;
      Exp.Type etp;
    case (e,e_type,{},_,prop) then (e,prop);  /* exp exp_type */ 
    case (Exp.CALL(path = fn,expLst = args,tuple_ = tuple_,builtin = builtin,ty = etp),e_type,(Types.DIM(integerOption = SOME(dim)) :: ad),slots,prop) /* Scalar expression, i.e function call */ 
      equation 
        exp_type = Types.elabType(e_type);
        vect_exp = vectorizeCallScalar(Exp.CALL(fn,args,tuple_,builtin,etp), exp_type, dim, slots);
        (vect_exp_1,Types.PROP(tp,c)) = vectorizeCall(vect_exp, e_type, ad, slots, prop);
        tp_1 = Types.liftArray(tp, SOME(dim));
      then
        (vect_exp_1,Types.PROP(tp_1,c));
    case (Exp.ARRAY(ty = tp,scalar = scalar,array = expl),e_type,(Types.DIM(integerOption = SOME(dim)) :: ad),slots,prop) /* array expression of function calls */ 
      equation 
        exp_type = Types.elabType(e_type);
        vect_exp = vectorizeCallArray(Exp.ARRAY(tp,scalar,expl), exp_type, dim, slots);
        (vect_exp_1,Types.PROP(tp,c)) = vectorizeCall(vect_exp, e_type, ad, slots, prop);
        tp_1 = Types.liftArray(tp, SOME(dim));
      then
        (vect_exp_1,Types.PROP(tp_1,c));
    case (_,_,_,_,_)
      equation 
        Debug.fprint("failtrace", "-vectorize_call failed\n");
      then
        fail();
  end matchcontinue;
end vectorizeCall;

protected function vectorizeCallArray "function : vectorizeCallArray
  author: PA
 
  Helper function to vectorize_call, vectoriezes ARRAY expression to
  an array of array expressions.
"
  input Exp.Exp inExp;
  input Exp.Type inType;
  input Integer inInteger;
  input list<Slot> inSlotLst;
  output Exp.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp,inType,inInteger,inSlotLst)
    local
      list<Exp.Exp> arr_expl,expl;
      Boolean scalar_1,scalar;
      Exp.Exp res_exp;
      Exp.Type tp,exp_tp;
      Integer cur_dim;
      list<Slot> slots;
    case (Exp.ARRAY(ty = tp,scalar = scalar,array = expl),exp_tp,cur_dim,slots) /* cur_dim */ 
      equation 
        arr_expl = vectorizeCallArray2(expl, exp_tp, cur_dim, slots);
        scalar_1 = Exp.typeBuiltin(exp_tp);
        res_exp = Exp.ARRAY(tp,scalar_1,arr_expl);
      then
        res_exp;
  end matchcontinue;
end vectorizeCallArray;

protected function vectorizeCallArray2 "function: vectorizeCallArray2
  author: PA
 
  Helper function to vectorize_call_array
"
  input list<Exp.Exp> inExpExpLst;
  input Exp.Type inType;
  input Integer inInteger;
  input list<Slot> inSlotLst;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inExpExpLst,inType,inInteger,inSlotLst)
    local
      Exp.Type tp,e_tp;
      Integer cur_dim;
      list<Slot> slots;
      Exp.Exp e_1,e;
      list<Exp.Exp> es_1,es;
    case ({},tp,cur_dim,slots) then {}; 
    case ((e :: es),e_tp,cur_dim,slots)
      equation 
        e_1 = vectorizeCallArray3(e, e_tp, cur_dim, slots);
        es_1 = vectorizeCallArray2(es, e_tp, cur_dim, slots);
      then
        (e_1 :: es_1);
  end matchcontinue;
end vectorizeCallArray2;

protected function vectorizeCallArray3 "function: vectorizeCallArray3
  author: PA
 
  Helper function to vectorize_call_array_2
"
  input Exp.Exp inExp;
  input Exp.Type inType;
  input Integer inInteger;
  input list<Slot> inSlotLst;
  output Exp.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp,inType,inInteger,inSlotLst)
    local
      Exp.Exp e_1,e;
      Exp.Type e_tp;
      Integer cur_dim;
      list<Slot> slots;
    case ((e as Exp.CALL(path = _)),e_tp,cur_dim,slots) /* cur_dim */ 
      equation 
        e_1 = vectorizeCallScalar(e, e_tp, cur_dim, slots);
      then
        e_1;
    case ((e as Exp.ARRAY(ty = _)),e_tp,cur_dim,slots)
      equation 
        e_1 = vectorizeCallArray(e, e_tp, cur_dim, slots);
      then
        e_1;
  end matchcontinue;
end vectorizeCallArray3;

protected function vectorizeCallScalar "function: vectorizeCallScalar
  author: PA
 
  Helper function to vectorize_call, vectorizes CALL expressions to 
  array expressions.
"
  input Exp.Exp inExp;
  input Exp.Type inType;
  input Integer inInteger;
  input list<Slot> inSlotLst;
  output Exp.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp,inType,inInteger,inSlotLst)
    local
      list<Exp.Exp> expl,args;
      Boolean scalar,tuple_,builtin;
      Exp.Exp new_exp,callexp;
      Absyn.Path fn;
      Exp.Type e_type;
      Integer dim;
      list<Slot> slots;
    case ((callexp as Exp.CALL(path = fn,expLst = args,tuple_ = tuple_,builtin = builtin)),e_type,dim,slots) /* cur_dim */ 
      equation 
        expl = vectorizeCallScalar2(args, slots, 1, dim, callexp);
        scalar = Exp.typeBuiltin(e_type);
        new_exp = Exp.ARRAY(e_type,scalar,expl);
      then
        new_exp;
    case (_,_,_,_)
      equation 
        Debug.fprint("failtrace", "-vectorize_call_scalar failed\n");
      then
        fail();
  end matchcontinue;
end vectorizeCallScalar;

protected function vectorizeCallScalar2 "function: vectorizeCallScalar2
  author: PA
 
  Iterates through vectorized dimension an creates argument list according
  to vectorized dimension in corresponding slot.
"
  input list<Exp.Exp> inExpExpLst1;
  input list<Slot> inSlotLst2;
  input Integer inInteger3;
  input Integer inInteger4;
  input Exp.Exp inExp5;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inExpExpLst1,inSlotLst2,inInteger3,inInteger4,inExp5)
    local
      list<Exp.Exp> callargs,res,expl,args;
      Integer cur_dim_1,cur_dim,dim;
      list<Slot> slots;
      Absyn.Path fn;
      Boolean t,b;
      Exp.Type tp;
    case (expl,slots,cur_dim,dim,Exp.CALL(path = fn,expLst = args,tuple_ = t,builtin = b,ty=tp)) /* cur_dim - current indx in dim dim - dimension size */ 
      equation 
        (cur_dim <= dim) = true;
        callargs = vectorizeCallScalar3(expl, slots, cur_dim);
        cur_dim_1 = cur_dim + 1;
        res = vectorizeCallScalar2(expl, slots, cur_dim_1, dim, Exp.CALL(fn,args,t,b,tp));
      then
        (Exp.CALL(fn,callargs,t,b,tp) :: res);
    case (_,_,_,_,_) then {}; 
  end matchcontinue;
end vectorizeCallScalar2;

protected function vectorizeCallScalar3 "function: vectorizeCallScalar3
  author: PA
 
  Helper function to vectorize_call_scalar_2
"
  input list<Exp.Exp> inExpExpLst;
  input list<Slot> inSlotLst;
  input Integer inInteger;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inExpExpLst,inSlotLst,inInteger)
    local
      list<Exp.Exp> res,es;
      Exp.Exp e,asub_exp;
      list<Slot> ss;
      Integer dim_indx;
    case ({},{},_) then {};  /* dim_indx */ 
    case ((e :: es),(SLOT(typesArrayDimLst = {}) :: ss),dim_indx) /* scalar argument */ 
      equation 
        res = vectorizeCallScalar3(es, ss, dim_indx);
      then
        (e :: res);
    case ((e :: es),(SLOT(typesArrayDimLst = (_ :: _)) :: ss),dim_indx) /* foreach argument */ 
      equation 
        res = vectorizeCallScalar3(es, ss, dim_indx);
        asub_exp = Exp.simplify(Exp.ASUB(e,dim_indx));
      then
        (asub_exp :: res);
  end matchcontinue;
end vectorizeCallScalar3;

protected function deoverloadFuncname "function: deoverloadFuncname
 
  This function is used to deoverload function calls. It investigates the
  type of the function to see if it has the optional functionname set. If 
  so this is returned. Otherwise return input.
"
  input Absyn.Path inPath;
  input Types.Type inType;
  output Absyn.Path outPath;
algorithm 
  outPath:=
  matchcontinue (inPath,inType)
    local Absyn.Path fn,fn_1;
    case (fn,(Types.T_FUNCTION(funcArg = _),SOME(fn_1))) then fn_1; 
    case (fn,(_,_)) then fn; 
  end matchcontinue;
end deoverloadFuncname;

protected function isTuple "function: isTuple
 
  Return true if Type is a Tuple type.
"
  input Types.Type inType;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inType)
    case ((Types.T_TUPLE(tupleType = _),_)) then true; 
    case ((_,_)) then false; 
  end matchcontinue;
end isTuple;

protected function elabTypes "function: elabTypes 
 
  Elaborate input parameters to a function and select matching function 
  type from a list of types.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input list<Types.Type> inTypesTypeLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output list<Exp.Exp> outExpExpLst1;
  output list<Types.Const> outTypesConstLst2;
  output Types.Type outType3;
  output Types.Type outType4;
  output list<Types.ArrayDim> outTypesArrayDimLst5;
  output list<Slot> outSlotLst6;
algorithm 
  (outCache,outExpExpLst1,outTypesConstLst2,outType3,outType4,outTypesArrayDimLst5,outSlotLst6):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inAbsynNamedArgLst,inTypesTypeLst,inBoolean)
    local
      list<Slot> slots,newslots;
      list<Exp.Exp> args_1;
      list<Types.Const> clist;
      list<Types.ArrayDim> dims;
      list<Env.Frame> env;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs;
      tuple<Types.TType, Option<Absyn.Path>> t,restype;
      list<tuple<Ident, tuple<Types.TType, Option<Absyn.Path>>>> params;
      list<tuple<Types.TType, Option<Absyn.Path>>> trest;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,args,nargs,((t as (Types.T_FUNCTION(funcArg = params,funcResultType = restype),_)) :: trest),impl) /* argument expressions function candidate types impl const result type function type Vectorized dimensions slots, needed for vectorization We found a match. */ 
      equation 
        slots = makeEmptySlots(params);
        (cache,args_1,newslots,clist) = elabInputArgs(cache,env, args, nargs, slots, impl);
        dims = slotsVectorizable(newslots);
      then
        (cache,args_1,clist,restype,t,dims,newslots);
    case (cache,env,args,nargs,((Types.T_FUNCTION(funcArg = params,funcResultType = restype),_) :: trest),impl) /* We did not found a match, try next function type */ 
      equation 
        (cache,args_1,clist,restype,t,dims,slots) = elabTypes(cache,env, args,nargs,trest, impl);
      then
        (cache,args_1,clist,restype,t,dims,slots);
    case (cache,env,_,_,_,_)
      equation 
        Debug.fprintln("failtrace", "elabTypes failed.\n");
      then
        fail();
  end matchcontinue;
end elabTypes;

protected function slotsVectorizable "function: slotsVectorizable
  author: PA
 
  This function checks all vectorized array dimensions in the slots and
  confirms that they all are of same dimension,or no dimension, i.e. not
  vectorized. The uniform vectorized array dimension is returned.
"
  input list<Slot> inSlotLst;
  output list<Types.ArrayDim> outTypesArrayDimLst;
algorithm 
  outTypesArrayDimLst:=
  matchcontinue (inSlotLst)
    local
      list<Types.ArrayDim> ad;
      list<Slot> rest;
    case ({}) then {}; 
    case ((SLOT(typesArrayDimLst = (ad as (_ :: _))) :: rest))
      equation 
        sameSlotsVectorizable(rest, ad);
      then
        ad;
    case ((SLOT(typesArrayDimLst = {}) :: rest))
      equation 
        ad = slotsVectorizable(rest);
      then
        ad;
    case (_)
      equation 
        Debug.fprint("failtrace", "-slots_vectorizable failed\n");
      then
        fail();
  end matchcontinue;
end slotsVectorizable;

protected function sameSlotsVectorizable "function: sameSlotsVectorizable
  author: PA
  
  This function succeds if all slots in the list either has the array 
  dimension as given by the second argument or no array dimension at all.
  The array dimension must match both in dimension size and number of 
  dimensions.
"
  input list<Slot> inSlotLst;
  input list<Types.ArrayDim> inTypesArrayDimLst;
algorithm 
  _:=
  matchcontinue (inSlotLst,inTypesArrayDimLst)
    local
      list<Types.ArrayDim> slot_ad,ad;
      list<Slot> rest;
    case ({},_) then (); 
    case ((SLOT(typesArrayDimLst = (slot_ad as (_ :: _))) :: rest),ad) /* arraydim must match */ 
      equation 
        sameArraydimLst(ad, slot_ad);
        sameSlotsVectorizable(rest, ad);
      then
        ();
    case ((SLOT(typesArrayDimLst = {}) :: rest),ad) /* empty arradim matches too */ 
      equation 
        sameSlotsVectorizable(rest, ad);
      then
        ();
  end matchcontinue;
end sameSlotsVectorizable;

protected function sameArraydimLst "function: sameArraydimLst
  author: PA
 
   Helper function to same_slots_vectorizable. 
"
  input list<Types.ArrayDim> inTypesArrayDimLst1;
  input list<Types.ArrayDim> inTypesArrayDimLst2;
algorithm 
  _:=
  matchcontinue (inTypesArrayDimLst1,inTypesArrayDimLst2)
    local
      Integer i1,i2;
      list<Types.ArrayDim> ads1,ads2;
    case ({},{}) then (); 
    case ((Types.DIM(integerOption = SOME(i1)) :: ads1),(Types.DIM(integerOption = SOME(i2)) :: ads2))
      equation 
        equality(i1 = i2);
        sameArraydimLst(ads1, ads2);
      then
        ();
    case ((Types.DIM(integerOption = NONE) :: ads1),(Types.DIM(integerOption = NONE) :: ads2))
      equation 
        sameArraydimLst(ads1, ads2);
      then
        ();
  end matchcontinue;
end sameArraydimLst;

protected function getProperties "function: getProperties
  This function creates a Properties object from a Types.Type and a 
  Types.TupleConst value.
"
  input Types.Type inType;
  input Types.TupleConst inTupleConst;
  output Types.Properties outProperties;
algorithm 
  outProperties:=
  matchcontinue (inType,inTupleConst)
    local
      tuple<Types.TType, Option<Absyn.Path>> tt,t,ty;
      Types.TupleConst const;
      Types.Const b;
      Ident tystr,conststr;
    case ((tt as (Types.T_TUPLE(tupleType = _),_)),const) then Types.PROP_TUPLE(tt,const);  /* At least two elements in the type list, this is a tuple. LS: Tuples are fixed before here */ 
    case (t,Types.TUPLE_CONST(tupleConstLst = (Types.CONST(const = b) :: {}))) then Types.PROP(t,b);  /* One type, this is a tuple with one element. The resulting properties 
	  is then identical to that of a single expression. */ 
    case (t,Types.TUPLE_CONST(tupleConstLst = (Types.CONST(const = b) :: {}))) then Types.PROP(t,b); 
    case (t,Types.CONST(const = b)) then Types.PROP(t,b); 
    case (ty,const)
      equation 
        Debug.fprint("failtrace", "- get_properties failed: ");
        tystr = Types.unparseType(ty);
        conststr = Types.unparseTupleconst(const);
        Debug.fprint("failtrace", tystr);
        Debug.fprint("failtrace", ", ");
        Debug.fprintln("failtrace", conststr);
      then
        fail();
  end matchcontinue;
end getProperties;

protected function buildTupleConst "function: buildTupleConst
  author: LS
  
  Build a TUPLE_CONST (Types.TupleConst) for a PROP_TUPLE for a function call
  from a list of bools derived from arguments
 
  We should check functions actual arguments instead of their formal
  parameters as done below
"
  input list<Types.Const> blist;
  output Types.TupleConst outTupleConst;
  list<Types.TupleConst> clist;
algorithm 
  clist := buildTupleConstList(blist);
  outTupleConst := Types.TUPLE_CONST(clist);
end buildTupleConst;

protected function buildTupleConstList "function: buildTupleConstList
 
  Helper function to build_tuple_const
"
  input list<Types.Const> inTypesConstLst;
  output list<Types.TupleConst> outTypesTupleConstLst;
algorithm 
  outTypesTupleConstLst:=
  matchcontinue (inTypesConstLst)
    local
      list<Types.TupleConst> restlist;
      Types.Const c;
      list<Types.Const> crest;
    case {} then {}; 
    case (c :: crest)
      equation 
        restlist = buildTupleConstList(crest);
      then
        (Types.CONST(c) :: restlist);
  end matchcontinue;
end buildTupleConstList;

protected function elabConsts "function: elabConsts
  author: PR
 
  This just splits the properties list into a type list and a const list. 
  LS: Changed to take a Type, which is the functions return type.
  LS: Update: const is derived from the input arguments and sent here.
"
  input Types.Type inType;
  input Types.Const inConst;
  output Types.TupleConst outTupleConst;
algorithm 
  outTupleConst:=
  matchcontinue (inType,inConst)
    local
      list<Types.TupleConst> consts;
      list<tuple<Types.TType, Option<Absyn.Path>>> tys;
      Types.Const c;
      tuple<Types.TType, Option<Absyn.Path>> ty;
    case ((Types.T_TUPLE(tupleType = tys),_),c)
      equation 
        consts = checkConsts(tys, c);
      then
        Types.TUPLE_CONST(consts);
    case (ty,c) /* LS: If not a tuple then one normal type, T_INTEGER etc, but we make a list of types
     with one element and call the same check_consts, so that we always have Types.TUPLE_CONST as result
 */ 
      equation 
        consts = checkConsts({ty}, c);
      then
        Types.TUPLE_CONST(consts);
  end matchcontinue;
end elabConsts;

protected function checkConsts "function: checkConsts
  
  LS: Changed to take a Type list, which is the functions return type. Only
   for functions returning a tuple 
  LS: Update: const is derived from the input arguments and sent here 
"
  input list<Types.Type> inTypesTypeLst;
  input Types.Const inConst;
  output list<Types.TupleConst> outTypesTupleConstLst;
algorithm 
  outTypesTupleConstLst:=
  matchcontinue (inTypesTypeLst,inConst)
    local
      Types.TupleConst c;
      list<Types.TupleConst> rest_1;
      tuple<Types.TType, Option<Absyn.Path>> a;
      list<tuple<Types.TType, Option<Absyn.Path>>> rest;
      Types.Const const;
    case ({},_) then {}; 
    case ((a :: rest),const)
      equation 
        c = checkConst(a, const);
        rest_1 = checkConsts(rest, const);
      then
        (c :: rest_1);
  end matchcontinue;
end checkConsts;

protected function checkConst "function: checkConst
  author: PR
   At the moment this make all outputs non cons.
  All ouputs should be checked in the function body for constness. 
  LS: but it says true? 
  LS: Adapted to check one type instead of funcarg, since it just checks 
  return type 
  LS: Update: const is derived from the input arguments and sent here 
"
  input Types.Type inType;
  input Types.Const inConst;
  output Types.TupleConst outTupleConst;
algorithm 
  outTupleConst:=
  matchcontinue (inType,inConst)
    local Types.Const c;
    case ((Types.T_TUPLE(tupleType = _),_),c)
      equation 
        Error.addMessage(Error.INTERNAL_ERROR, 
          {"No suport for tuples built by tuples"});
      then
        fail();
    case ((_,_),c) then Types.CONST(c); 
  end matchcontinue;
end checkConst;

protected function splitProps "function: splitProps
 
  Splits the properties list into the separated types list and const list. 
"
  input list<Types.Properties> inTypesPropertiesLst;
  output list<Types.Type> outTypesTypeLst;
  output list<Types.TupleConst> outTypesTupleConstLst;
algorithm 
  (outTypesTypeLst,outTypesTupleConstLst):=
  matchcontinue (inTypesPropertiesLst)
    local
      list<tuple<Types.TType, Option<Absyn.Path>>> types;
      list<Types.TupleConst> consts;
      tuple<Types.TType, Option<Absyn.Path>> t;
      Types.Const c;
      list<Types.Properties> props;
      Types.TupleConst t_c;
    case ((Types.PROP(type_ = t,constFlag = c) :: props))
      equation 
        (types,consts) = splitProps(props) "list_append(ts,t::{}) => t1 &
	list_append(cs,Types.CONST(c)::{}) => t2 &
" ;
      then
        ((t :: types),(Types.CONST(c) :: consts));
    case ((Types.PROP_TUPLE(type_ = t,tupleConst = t_c) :: props))
      equation 
        (types,consts) = splitProps(props) "list_append(ts,t::{}) => ts\' & list_append(cs, t_c::{}) => cs\' & 
" ;
      then
        ((t :: types),(t_c :: consts));
    case ({}) then ({},{}); 
  end matchcontinue;
end splitProps;

protected function getTypes "function: getTypes
 
  This relatoin returns the types of a Types.FuncArg list.
"
  input list<Types.FuncArg> inTypesFuncArgLst;
  output list<Types.Type> outTypesTypeLst;
algorithm 
  outTypesTypeLst:=
  matchcontinue (inTypesFuncArgLst)
    local
      list<tuple<Types.TType, Option<Absyn.Path>>> types;
      Ident n;
      tuple<Types.TType, Option<Absyn.Path>> t;
      list<tuple<Ident, tuple<Types.TType, Option<Absyn.Path>>>> rest;
    case (((n,t) :: rest))
      equation 
        types = getTypes(rest) "print(\"\\nDebug: Got a type for output of function. \") &" ;
      then
        (t :: types);
    case ({}) then {}; 
  end matchcontinue;
end getTypes;

protected function functionParams "function: functionParams
 
  A function definition is just a clas definition where all publi
  components are declared as either inpu or outpu.  This
  function_ find all those components and_ separates them into two
  separate lists.

  LS: This can probably replaced by Types.get_input_vars and
   Types.get_output_vars"
  input list<Types.Var> inTypesVarLst;
  output list<Types.FuncArg> outTypesFuncArgLst1;
  output list<Types.FuncArg> outTypesFuncArgLst2;
algorithm 
  (outTypesFuncArgLst1,outTypesFuncArgLst2):=
  matchcontinue (inTypesVarLst)
    local
      list<tuple<Ident, tuple<Types.TType, Option<Absyn.Path>>>> in_,out;
      list<Types.Var> vs;
      Ident n;
      tuple<Types.TType, Option<Absyn.Path>> t;
      Types.Var v;
    case {} then ({},{}); 
    case ((Types.VAR(protected_ = true) :: vs)) /* Ignore protected components */ 
      equation 
        (in_,out) = functionParams(vs) "Debug.print(\"protected\") &" ;
      then
        (in_,out);
    case ((Types.VAR(name = n,attributes = Types.ATTR(direction = Absyn.INPUT()),protected_ = false,type_ = t,binding = Types.UNBOUND()) :: vs))
      equation 
        (in_,out) = functionParams(vs) "Debug.print(\"not protected. intput\") &" ;
      then
        (((n,t) :: in_),out);
    case ((Types.VAR(name = n,attributes = Types.ATTR(direction = Absyn.OUTPUT()),protected_ = false,type_ = t,binding = Types.UNBOUND()) :: vs))
      equation 
        (in_,out) = functionParams(vs) "Debug.print(\"not protected. output\") &" ;
      then
        (in_,((n,t) :: out));
    case (((v as Types.VAR(name = n,attributes = Types.ATTR(direction = Absyn.BIDIR()))) :: vs))
      equation 
        Error.addMessage(Error.FUNCTION_COMPS_MUST_HAVE_DIRECTION, {n});
      then
        fail();
    case _
      equation 
        Debug.fprint("failtrace", "-function_params failed\n");
      then
        fail();
  end matchcontinue;
end functionParams;

protected function elabInputArgs "function_: elabInputArgs
 
  This function_ elaborates on a number of expressions and_ matches
  them to a number of `Types.Var\' objects, applying type_ conversions
  on the expressions when necessary to match the type_ of the
  `Types.Var\'.

  PA: Positional arguments and named arguments are filled in the argument slots as:
 1. Positional arguments fill the first slots according to their position.
 2. Named arguments fill slots with the same name as the named argument.
 3. Unfilled slots are checks so that they have default values, otherwise error.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input list<Slot> inSlotLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output list<Exp.Exp> outExpExpLst;
  output list<Slot> outSlotLst;
  output list<Types.Const> outTypesConstLst;
algorithm 
  (outCache,outExpExpLst,outSlotLst,outTypesConstLst):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inAbsynNamedArgLst,inSlotLst,inBoolean)
    local
      list<tuple<Ident, tuple<Types.TType, Option<Absyn.Path>>>> farg;
      list<Slot> slots_1,newslots,slots;
      list<Types.Const> clist1,clist2,clist;
      list<Exp.Exp> explst,newexp;
      list<Env.Frame> env;
      list<Absyn.Exp> exp;
      list<Absyn.NamedArg> narg;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,(exp as (_ :: _)),narg,slots,impl) /* impl const Fill slots with positional arguments */ 
      equation 
        farg = funcargLstFromSlots(slots);
        (cache,slots_1,clist1) = elabPositionalInputArgs(cache,env, exp, farg, slots, impl);
        (cache,_,newslots,clist2) = elabInputArgs(cache,env, {}, narg, slots_1, impl) "recursive call fills named arguments" ;
        clist = listAppend(clist1, clist2);
        explst = expListFromSlots(newslots);
      then
        (cache,explst,newslots,clist);
    case (cache,env,{},narg,slots,impl) /* Fill slots with named arguments */ 
       local String s;
      equation 
        farg = funcargLstFromSlots(slots);
        s = printSlotsStr(slots);
        (cache,newslots,clist) = elabNamedInputArgs(cache,env, narg, farg, slots, impl);
            s = printSlotsStr(newslots);
        newexp = expListFromSlots(newslots);
      then
        (cache,newexp,newslots,clist);
    case (cache,env,{},{},slots,impl) then (cache,{},slots,{}); 
      
    case (_,_,_,_,_,_) equation Debug.fprint("failtrace","elabInputArgs failed\n"); then fail();
  end matchcontinue;
end elabInputArgs;

protected function makeEmptySlots "function: makeEmptySlots
 
  Helper function to elab_input_args.
  Creates the slots to be filled with arguments. Intially they are empty.
"
  input list<Types.FuncArg> inTypesFuncArgLst;
  output list<Slot> outSlotLst;
algorithm 
  outSlotLst:=
  matchcontinue (inTypesFuncArgLst)
    local
      list<Slot> ss;
      tuple<Ident, tuple<Types.TType, Option<Absyn.Path>>> fa;
      list<tuple<Ident, tuple<Types.TType, Option<Absyn.Path>>>> fs;
    case ({}) then {}; 
    case ((fa :: fs))
      equation 
        ss = makeEmptySlots(fs);
      then
        (SLOT(fa,false,NONE,{}) :: ss);
  end matchcontinue;
end makeEmptySlots;

protected function funcargLstFromSlots "function: funcargLstFromSlots
 
  Converts slots to Types.Funcarg
"
  input list<Slot> inSlotLst;
  output list<Types.FuncArg> outTypesFuncArgLst;
algorithm 
  outTypesFuncArgLst:=
  matchcontinue (inSlotLst)
    local
      list<tuple<Ident, tuple<Types.TType, Option<Absyn.Path>>>> fs;
      tuple<Ident, tuple<Types.TType, Option<Absyn.Path>>> fa;
      list<Slot> xs;
    case {} then {}; 
    case ((SLOT(an = fa) :: xs))
      equation 
        fs = funcargLstFromSlots(xs);
      then
        (fa :: fs);
  end matchcontinue;
end funcargLstFromSlots;

protected function expListFromSlots "function expListFromSlots
 
  Convers slots to expressions 
"
  input list<Slot> inSlotLst;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inSlotLst)
    local
      list<Exp.Exp> lst;
      Exp.Exp e;
      list<Slot> xs;
    case {} then {}; 
    case ((SLOT(expExpOption = SOME(e)) :: xs))
      equation 
        lst = expListFromSlots(xs);
      then
        (e :: lst);
    case ((SLOT(expExpOption = NONE) :: xs))
      equation 
        lst = expListFromSlots(xs);
      then
        lst;
  end matchcontinue;
end expListFromSlots;

protected function fillDefaultSlots "function: fillDefaultSlots
 
  This function takes a slot list and a class definition of a function 
  and fills  default values into slots which have not been filled.
"
	input Env.Cache inCache;
  input list<Slot> inSlotLst;
  input SCode.Class inClass;
  input Env.Env inEnv;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output list<Slot> outSlotLst;
algorithm 
  (outCache,outSlotLst) :=
  matchcontinue (inCache,inSlotLst,inClass,inEnv,inBoolean)
    local
      list<Slot> res,xs;
      tuple<Ident, tuple<Types.TType, Option<Absyn.Path>>> fa;
      Option<Exp.Exp> e;
      list<Types.ArrayDim> ds;
      SCode.Class class_;
      list<Env.Frame> env;
      Boolean impl;
      Absyn.Exp dexp;
      Exp.Exp exp,exp_1;
      tuple<Types.TType, Option<Absyn.Path>> t,tp;
      Types.Const c1;
      Ident id;
      Env.Cache cache;
    case (cache,(SLOT(an = fa,true_ = true,expExpOption = e,typesArrayDimLst = ds) :: xs),class_,env,impl) /* impl */ 
      equation 
        (cache,res) = fillDefaultSlots(cache,xs, class_, env, impl);
      then
        (cache,SLOT(fa,true,e,ds) :: res);
    case (cache,(SLOT(an = (id,tp),true_ = false,expExpOption = e,typesArrayDimLst = ds) :: xs),class_,env,impl)
      equation 
        (cache,res) = fillDefaultSlots(cache,xs, class_, env, impl);
        SCode.COMPONENT(_,_,_,_,_,_,SCode.MOD(_,_,_,SOME(dexp)),_,_) = SCode.getElementNamed(id, class_);
        (cache,exp,Types.PROP(t,c1),_) = elabExp(cache,env, dexp, impl, NONE,true);
        (exp_1,_) = Types.matchType(exp, t, tp);
      then
        (cache,SLOT((id,tp),true,SOME(exp_1),ds) :: res);
    case (cache,(SLOT(an = (id,tp),true_ = false,expExpOption = e,typesArrayDimLst = ds) :: xs),class_,env,impl)
      equation 
        (cache,res) = fillDefaultSlots(cache,xs, class_, env, impl) "Error.add_message(Error.INTERNAL_ERROR,{id})" ;
      then
        (cache,SLOT((id,tp),true,e,ds) :: xs);
    case (cache,{},_,_,_) then (cache,{}); 
  end matchcontinue;
end fillDefaultSlots;

protected function printSlotsStr "function printSlotsStr
 
  prints the slots to a string
"
  input list<Slot> inSlotLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inSlotLst)
    local
      Ident farg_str,filled,str,s,s1,s2,res;
      list<Ident> str_lst;
      tuple<Ident, tuple<Types.TType, Option<Absyn.Path>>> farg;
      Option<Exp.Exp> exp;
      list<Types.ArrayDim> ds;
      list<Slot> xs;
    case ((SLOT(an = farg,true_ = filled,expExpOption = exp,typesArrayDimLst = ds) :: xs))
      equation 
        farg_str = Types.printFargStr(farg);
        filled = Util.if_(filled, "filled", "not filled");
        str = Dump.getOptionStr(exp, Exp.printExpStr);
        str_lst = Util.listMap(ds, Types.getArraydimStr);
        s = Util.stringDelimitList(str_lst, ", ");
        s1 = Util.stringAppendList({"SLOT(",farg_str,", ",filled,", ",str,", [",s,"])\n"});
        s2 = printSlotsStr(xs);
        res = stringAppend(s1, s2);
      then
        res;
    case ({}) then ""; 
  end matchcontinue;
end printSlotsStr;

protected function elabPositionalInputArgs "function: elabPositionalInputArgs
 
  This function elaborates the positional input arguments of a function.
  A list of slots is filled from the beginning with types of each 
  positional argument.
  
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Types.FuncArg> inTypesFuncArgLst;
  input list<Slot> inSlotLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output list<Slot> outSlotLst;
  output list<Types.Const> outTypesConstLst;
algorithm 
  (outCache,outSlotLst,outTypesConstLst):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inTypesFuncArgLst,inSlotLst,inBoolean)
    local
      list<Slot> slots,slots_1,newslots;
      Boolean impl;
      Exp.Exp e_1,e_2;
      tuple<Types.TType, Option<Absyn.Path>> t,vt;
      Types.Const c1;
      list<Types.Const> clist;
      list<Env.Frame> env;
      Absyn.Exp e;
      list<Absyn.Exp> es;
      tuple<Ident, tuple<Types.TType, Option<Absyn.Path>>> farg;
      list<tuple<Ident, tuple<Types.TType, Option<Absyn.Path>>>> vs;
      list<Types.ArrayDim> ds;
      Env.Cache cache;
    case (cache,_,{},_,slots,impl) then (cache,slots,{});  /* impl const */ 
    case (cache,env,(e :: es),((farg as (_,vt)) :: vs),slots,impl) /* Exact match */ 
      equation 
        (cache,e_1,Types.PROP(t,c1),_) = elabExp(cache,env, e, impl, NONE,true);
        (e_2,_) = Types.matchType(e_1, t, vt);
        (cache,slots_1,clist) = elabPositionalInputArgs(cache,env, es, vs, slots, impl);
        newslots = fillSlot(farg, e_2, {}, slots_1) "no vectorized dim" ;
      then
        (cache,newslots,(c1 :: clist));
    case (cache,env,(e :: es),((farg as (_,vt)) :: vs),slots,impl) /* check if vectorized argument */ 
      equation 
        (cache,e_1,Types.PROP(t,c1),_) = elabExp(cache,env, e, impl, NONE,true);
        (e_2,_,ds) = Types.vectorizableType(e_1, t, vt);
        (cache,slots_1,clist) = elabPositionalInputArgs(cache,env, es, vs, slots, impl);
        newslots = fillSlot(farg, e_2, ds, slots_1);
      then
        (cache,newslots,(c1 :: clist));
  end matchcontinue;
end elabPositionalInputArgs;

protected function elabNamedInputArgs "function elabNamedInputArgs
 
  This function takes an Env, a NamedArg list, a Types.FuncArg list and a 
  Slot list.
  It builds up a new slot list and a list of elaborated expressions.
  If a slot is filled twice the function fails. If a slot is not filled at 
  all and the 
  value is not a parameter or a constant the function also fails.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input list<Types.FuncArg> inTypesFuncArgLst;
  input list<Slot> inSlotLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output list<Slot> outSlotLst;
  output list<Types.Const> outTypesConstLst;
algorithm 
  (outCache,outSlotLst,outTypesConstLst) :=
  matchcontinue (inCache,inEnv,inAbsynNamedArgLst,inTypesFuncArgLst,inSlotLst,inBoolean)
    local
      Exp.Exp e_1,e_2;
      tuple<Types.TType, Option<Absyn.Path>> t,vt;
      Types.Const c1;
      list<Slot> slots_1,newslots,slots;
      list<Types.Const> clist;
      list<Env.Frame> env;
      Ident id;
      Absyn.Exp e;
      list<Absyn.NamedArg> nas,narg;
      list<tuple<Ident, tuple<Types.TType, Option<Absyn.Path>>>> farg;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,(Absyn.NAMEDARG(argName = id,argValue = e) :: nas),farg,slots,impl) /* impl const TODO: implement check_slots_filled.
  rule	check_slots_filled(env,slots) 
 	----------------------------
 	elab_named_input_args(env,{},farg,slots) => ({},slots) 
 */ 
      equation 
        (cache,e_1,Types.PROP(t,c1),_) = elabExp(cache,env, e, impl, NONE,true);
        vt = findNamedArgType(id, farg);
        (e_2,_) = Types.matchType(e_1, t, vt);
        slots_1 = fillSlot((id,vt), e_2, {}, slots);
        (cache,newslots,clist) = elabNamedInputArgs(cache,env, nas, farg, slots_1, impl);
      then
        (cache,newslots,(c1 :: clist));
    case (cache,_,{},_,slots,impl) then (cache,slots,{}); 
    case (cache,env,narg,farg,_,impl)
      equation 
        Debug.fprint("failtrace", "- elab_named_input_args failed\n");
      then
        fail();
  end matchcontinue;
end elabNamedInputArgs;

protected function findNamedArgType "function findNamedArgType
 
  This function takes an Ident and a FuncArg list, and returns the FuncArg
  which has  that identifier.
  Used for instance when looking up named arguments from the function type.
"
  input Ident inIdent;
  input list<Types.FuncArg> inTypesFuncArgLst;
  output Types.Type outType;
algorithm 
  outType:=
  matchcontinue (inIdent,inTypesFuncArgLst)
    local
      Ident id,id2;
      tuple<Types.TType, Option<Absyn.Path>> farg;
      list<tuple<Ident, tuple<Types.TType, Option<Absyn.Path>>>> ts;
    case (id,((id2,farg) :: ts))
      equation 
        equality(id = id2);
      then
        farg;
    case (id,((farg as (id2,_)) :: ts))
      equation 
        failure(equality(id = id2));
        farg = findNamedArgType(id, ts);
      then
        farg;
  end matchcontinue;
end findNamedArgType;

protected function fillSlot "function: fillSlot
 
  This function takses a `FuncArg\' and an Exp.Exp and a Slot list and fills 
  the slot holding the FuncArg, by setting the boolean value of the slot 
  and setting the expression. The function fails if the slot is allready set.
"
  input Types.FuncArg inFuncArg;
  input Exp.Exp inExp;
  input list<Types.ArrayDim> inTypesArrayDimLst;
  input list<Slot> inSlotLst;
  output list<Slot> outSlotLst;
algorithm 
  outSlotLst:=
  matchcontinue (inFuncArg,inExp,inTypesArrayDimLst,inSlotLst)
    local
      Ident fa1,fa2,fa;
      Exp.Exp exp;
      list<Types.ArrayDim> ds;
      tuple<Types.TType, Option<Absyn.Path>> b;
      list<Slot> xs,newslots;
      tuple<Ident, tuple<Types.TType, Option<Absyn.Path>>> farg;
      Slot s1;
    case ((fa1,_),exp,ds,(SLOT(an = (fa2,b),true_ = false) :: xs))
      equation 
        equality(fa1 = fa2);
      then
        (SLOT((fa2,b),true,SOME(exp),ds) :: xs);
    case ((fa1,_),exp,ds,(SLOT(an = (fa2,b),true_ = true) :: xs))
      equation 
        equality(fa1 = fa2);
        Error.addMessage(Error.FUNCTION_SLOT_ALLREADY_FILLED, {fa2});
      then
        fail();
    case ((farg as (fa1,_)),exp,ds,((s1 as SLOT(an = (fa2,_))) :: xs))
      equation 
        failure(equality(fa1 = fa2));
        newslots = fillSlot(farg, exp, ds, xs);
      then
        (s1 :: newslots);
    case ((fa,_),_,_,_)
      equation 
        Error.addMessage(Error.NO_SUCH_ARGUMENT, {fa});
      then
        fail();
  end matchcontinue;
end fillSlot;

public function elabCref "function: elabCref
 
  Elaborate on a component reference.  Check the type of the
  component referred to, and check if the environment contains
  either a constant binding for that variable, or if it contains an
  equation binding with a constant expression.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef inComponentRef;
  input Boolean inBoolean "implicit instantiation";
  input Boolean performVectorization "true => generates vectorized expressions, {v[1],v[2],...}";
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
  output SCode.Accessibility outAccessibility;
algorithm 
  (outCache,outExp,outProperties,outAccessibility):=
  matchcontinue (inCache,inEnv,inComponentRef,inBoolean,performVectorization)
    local
      Exp.ComponentRef c_1;
      Types.Const const;
      SCode.Accessibility acc,acc_1;
      SCode.Variability variability;
      tuple<Types.TType, Option<Absyn.Path>> t;
      Types.Binding binding;
      Exp.Exp exp;
      list<Env.Frame> env;
      Absyn.ComponentRef c;
      Boolean impl;
      Ident s,scope;
      Env.Cache cache;
      Boolean doVect;
    case (cache,env,c,impl,doVect) /* impl */ 
      local String str;
         Types.Properties props;
      equation 
        (cache,c_1,const) = elabCrefSubs(cache,env, c, impl);
        (cache,Types.ATTR(_,acc,variability,_),t,binding) = Lookup.lookupVar(cache,env, c_1);
        (cache,exp,const,acc_1) = elabCref2(cache,env, c_1, acc, variability, t, binding,doVect);
      then
        (cache,exp,Types.PROP(t,const),acc_1);
    case (cache,env,c,impl,doVect)
      equation 
        (cache,c_1,const) = elabCrefSubs(cache,env, c, impl);
        s = Dump.printComponentRefStr(c);
        scope = Env.printEnvPathStr(env);
        Error.addMessage(Error.LOOKUP_VARIABLE_ERROR, {s,scope});
      then
        fail();
    case (cache,env,c,impl,doVect)
      local String s;
      equation 
        Debug.fprint("failtrace", "- elab_cref failed: ");
        s = Dump.printComponentRefStr(c);
        Debug.fprint("failtrace", s);
        Debug.fprint("failtrace", "\nENV:");
        Debug.fprint("failtrace",Env.printEnvStr(env));
      then
        fail();
  end matchcontinue;
end elabCref;

protected function fillCrefSubscripts "function: fillCrefSubscripts
 
  This is a helper function to elab_cref2.
  It investigates a Types.Type in order to fill the subscript lists of a 
  component reference. For instance, the name \'a.b\' with the type array of 
  one dimension will become \'a.b[:]\'.
"
  input Exp.ComponentRef inComponentRef;
  input Types.Type inType;
  output Exp.ComponentRef outComponentRef;
algorithm 
  outComponentRef:=
  matchcontinue (inComponentRef,inType)
    local
      Exp.ComponentRef e,cref_1,cref;
      tuple<Types.TType, Option<Absyn.Path>> t;
      list<Exp.Subscript> subs_1,subs;
      Ident id;
    case ((e as Exp.CREF_IDENT(subscriptLst = {})),t) then e; 
    case (Exp.CREF_IDENT(ident = id,subscriptLst = subs),t)
      equation 
        subs_1 = fillSubscripts(subs, t);
      then
        Exp.CREF_IDENT(id,subs_1);
    case (Exp.CREF_QUAL(ident = id,subscriptLst = subs,componentRef = cref),t)
      equation 
        cref_1 = fillCrefSubscripts(cref, t);
      then
        Exp.CREF_QUAL(id,subs,cref_1);
  end matchcontinue;
end fillCrefSubscripts;

protected function fillSubscripts "function: fillSubscripts
  
  Helper function to fill_cref_subscripts.
"
  input list<Exp.Subscript> inExpSubscriptLst;
  input Types.Type inType;
  output list<Exp.Subscript> outExpSubscriptLst;
algorithm 
  outExpSubscriptLst:=
  matchcontinue (inExpSubscriptLst,inType)
    local
      list<Exp.Subscript> subs_1,subs_2,subs;
      tuple<Types.TType, Option<Absyn.Path>> t;
      Exp.Subscript fs;
    case ({},(Types.T_ARRAY(arrayType = t),_))
      equation 
        subs_1 = fillSubscripts({}, t);
        subs_2 = listAppend({Exp.WHOLEDIM()}, subs_1);
      then
        subs_2;
    case ((fs :: subs),(Types.T_ARRAY(arrayType = t),_))
      equation 
        subs_1 = fillSubscripts(subs, t);
      then
        (fs :: subs_1);
    case (subs,_) then subs; 
  end matchcontinue;
end fillSubscripts;

protected function elabCref2 "function: elabCref2
 
  This function check whether the component reference found in
  `elab_cref\' has a binding, and if that binding is constant.  If
  the binding is a `VALBOUND\' binding, the value is substituted.
  Constant values are e.g.: 1+5, c1+c2, ps12   ,where c1 and c2 are modelica constants,
 						    ps1 and ps2 are structural parameters.
  Non Constant values are e.g. : p1+p2, x1x2  ,where p1,p2 are modelica parameters, 
 						  x1,x2 modelica variables.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.ComponentRef inComponentRef;
  input SCode.Accessibility inAccessibility;
  input SCode.Variability inVariability;
  input Types.Type inType;
  input Types.Binding inBinding;
  input Boolean performVectorization "true => vectorized expressions";
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Const outConst;
  output SCode.Accessibility outAccessibility;
algorithm 
  (outCache,outExp,outConst,outAccessibility):=
  matchcontinue (inCache,inEnv,inComponentRef,inAccessibility,inVariability,inType,inBinding,performVectorization)
    local
      Exp.Type t_1;
      Exp.ComponentRef cr,cr_1,cref;
      SCode.Accessibility acc,acc_1;
      tuple<Types.TType, Option<Absyn.Path>> t,tt,et,tp;
      Exp.Exp e,e_1,exp;
      Values.Value v;
      list<Env.Frame> env;
      Types.Const const;
      SCode.Variability variability_1,variability,var;
      Types.Binding binding_1,bind;
      Ident s,str,scope;
      Types.Binding binding;
      Env.Cache cache;
      Boolean doVect;
    case (cache,_,cr,acc,_,(t as (Types.T_NOTYPE(),_)),_,doVect) /* If type not yet determined, component must be referencing itself. 
	    constantness undecidable since binding not available, 
	    return C_VAR */ 
      equation 
        t_1 = Types.elabType(t);
      then
        (cache,Exp.CREF(cr,t_1),Types.C_VAR(),acc);
    case (cache,_,cr,acc,SCode.VAR(),tt,_,doVect)
      local Exp.Type t;
      equation 
        t = Types.elabType(tt);
        cr_1 = fillCrefSubscripts(cr, tt);
        e = crefVectorize(doVect,Exp.CREF(cr_1,t), tt) "PA: added2006-01-11" ;
      then
        (cache,e,Types.C_VAR(),acc);
    case (cache,_,cr,acc,SCode.DISCRETE(),tt,_,doVect)
      local Exp.Type t;
      equation 
        t = Types.elabType(tt);
        cr_1 = fillCrefSubscripts(cr, tt);
        e = crefVectorize(doVect,Exp.CREF(cr_1,t), tt);
      then
        (cache,e,Types.C_VAR(),acc);
    case (cache,env,cr,acc,SCode.CONST(),t,binding,doVect)
      //local Exp.Type t;
      equation 
        (cache,v) = Ceval.cevalCrefBinding(cache,env,cr,binding,false,Ceval.MSG());
        e = valueExp(v);
        et = Types.typeOfValue(v);
        (e_1,_) = Types.matchType(e, et, t);
      then
        (cache,e_1,Types.C_CONST(),SCode.RO());

    case (cache,env,cr,acc,SCode.PARAM(),tt,Types.VALBOUND(valBound = v),doVect)
      local Exp.Type t;
      equation 
        t = Types.elabType(tt);
        cr_1 = fillCrefSubscripts(cr, tt);
        e_1 = crefVectorize(doVect,Exp.CREF(cr_1,t), tt);
      then
        (cache,e_1,Types.C_PARAM(),acc);
    case (cache,env,cr,acc,SCode.CONST(),tt,Types.EQBOUND(exp = exp,constant_ = const),doVect) 
      local Exp.Type t;
      equation 
        t = Types.elabType(tt) "Constants with equal binings should be constant, i.e. true
	 but const is passed on, allowing constants to have wrong bindings
	 This must be caught later on." ;
        cr_1 = fillCrefSubscripts(cr, tt);
        e_1 = crefVectorize(doVect,Exp.CREF(cr_1,t), tt);
      then
        (cache,e_1,const,acc);
    case (cache,env,cr,acc,SCode.STRUCTPARAM(),tt,Types.EQBOUND(exp = exp,constant_ = const),doVect)
      local Exp.Type t;
      equation 
        t = Types.elabType(tt) "...the same goes for structural parameters." ;
        cr_1 = fillCrefSubscripts(cr, tt);
        e_1 = crefVectorize(doVect,Exp.CREF(cr_1,t), tt);
      then
        (cache,e_1,const,acc);
    case (cache,env,cr,acc,SCode.PARAM(),tt,Types.EQBOUND(exp = exp,constant_ = const),doVect)
      local Exp.Type t;
      equation 
        t = Types.elabType(tt) "parameters with equal binding becomes C_PARAM" ;
        cr_1 = fillCrefSubscripts(cr, tt);
        e_1 = crefVectorize(doVect,Exp.CREF(cr_1,t), tt);
      then
        (cache,e_1,Types.C_PARAM(),acc);
    case (cache,env,cr,acc,_,tt,Types.EQBOUND(exp = exp,constant_ = const),doVect)
      local Exp.Type t;
      equation 
        t = Types.elabType(tt) "..the rest should be non constant, even if they have a 
	 constant binding." ;
        cr_1 = fillCrefSubscripts(cr, tt);
        e_1 = crefVectorize(doVect,Exp.CREF(cr_1,t), tt);
      then
        (cache,e_1,Types.C_VAR(),acc);
    case (cache,env,cr,acc,_,(tt as (Types.T_ENUM(),_)),_,doVect) /* Enum constants does not have a value expression */ 
      local Exp.Type t;
      equation 
        t = Types.elabType(tt);
      then
        (cache,Exp.CREF(cr,t),Types.C_CONST(),acc);
    case (cache,env,cr,acc,variability,tp,Types.EQBOUND(exp = Exp.CREF(componentRef = cref,ty = t),constant_ = Types.C_VAR()),doVect)
      local
        tuple<Types.TType, Option<Absyn.Path>> t_1;
        Exp.Type t;
      equation 
        (cache,Types.ATTR(_,acc_1,variability_1,_),t_1,binding_1) = Lookup.lookupVar(cache,env, cref) "If value not constant, but references another parameter, which has a value We need to perform value propagation." ;
        (cache,e,const,acc) = elabCref2(cache,env, cref, acc_1, variability_1, t_1, binding_1,doVect);
      then
        (cache,e,const,acc);
    case (cache,_,cr,_,_,_,Types.EQBOUND(exp = exp,constant_ = Types.C_VAR()),doVect)
      equation 
        s = Exp.printComponentRefStr(cr);
        str = Exp.printExpStr(exp);
        Error.addMessage(Error.CONSTANT_OR_PARAM_WITH_NONCONST_BINDING, {s,str});
      then
        fail();
    case (cache,env,cr,_,SCode.CONST(),_,Types.UNBOUND(),doVect) /* constants without value produce error. */ 
      equation 
        s = Exp.printComponentRefStr(cr);
        scope = Env.printEnvPathStr(env);
        Error.addMessage(Error.NO_CONSTANT_BINDING, {s,scope});
      then
        fail();
    case (cache,env,cr,acc,SCode.PARAM(),tt,Types.UNBOUND(),doVect) /* Parameters without value produce warning */ 
      local Exp.Type t;
      equation 
        s = Exp.printComponentRefStr(cr);
        Error.addMessage(Error.UNBOUND_PARAMETER_WARNING, {s});
        t = Types.elabType(tt);
        cr_1 = fillCrefSubscripts(cr, tt);
      then
        (cache,Exp.CREF(cr_1,t),Types.C_PARAM(),acc);
    case (cache,env,cr,acc,var,tp,bind,doVect)
      equation 
        Debug.fprint("failtrace", "-elab_cref2 failed\n");
      then
        fail();
  end matchcontinue;
end elabCref2;

protected function crefVectorize "function: crefVectorize
 
  This function takes a 'Exp.Exp' and a 'Types.Type' and if the expression
  is a ComponentRef and the type is an array it returns an array of 
  component references with subscripts for each index.
  For instance, parameter Real x[3];   
  gives cref_vectorize('x', <arraytype>) => '{x[1],x[2],x[3]}
  This is needed since the DAE does not know what the variable 'x' is, it only
  knows the variables 'x[1]', 'x[2]' and 'x[3]'.
  NOTE: Currently only works for one and two dimensions.
"
	input Boolean performVectorization "if false, return input";
  input Exp.Exp inExp;
  input Types.Type inType;
  output Exp.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (performVectorization,inExp,inType)
    local
      Boolean b1,b2,doVect;
      Exp.Type elt_tp,exptp;
      Exp.Exp e;
      Exp.ComponentRef cr;
      Integer ds,ds2;
      tuple<Types.TType, Option<Absyn.Path>> t;
      
    case(false,e,_) then e;

      /* types extending basictype */
    case (doVect,e,(Types.T_COMPLEX(_,_,SOME(t)),_))
      equation
        e = crefVectorize(doVect,e,t);
      then e;

        /* matrix sizes > 20 is not vectorized */         
    case (_,Exp.CREF(componentRef = cr,ty = exptp),(Types.T_ARRAY(arrayDim = Types.DIM(integerOption = SOME(ds)),arrayType = (t as (Types.T_ARRAY(arrayDim = Types.DIM(integerOption = SOME(ds2))),_))),_)) 
      equation 
        b1 = (ds < 20);
        b2 = (ds2 < 20);
        true = boolAnd(b1, b2);
        //elt_tp = Exp.arrayEltType(exptp);
        e = createCrefArray2d(cr, 1, ds, ds2, exptp, t);
      then
        e;

        /* vectorsizes > 20 is not vectorized */ 
    case (_,Exp.CREF(componentRef = cr,ty = exptp),(Types.T_ARRAY(arrayDim = Types.DIM(integerOption = SOME(ds)),arrayType = t),_)) 
      equation 
        false = Types.isArray(t);
        (ds < 20) = true;
        //elt_tp = Exp.arrayEltType(exptp);
        e = createCrefArray(cr, 1, ds, exptp, t);
      then
        e;
    case (_,e,_) then e; 
  end matchcontinue;
end crefVectorize;

protected function callVectorize "function: callVectorize
  author: PA
 
  Takes an expression that is a function call and an expresion list
  and maps the call to each expression in the list.
  For instance, call_vectorize(Exp.CALL(XX(\"der\",),...),{1,2,3}))
  => {Exp.CALL(XX(\"der\"),{1}), Exp.CALL(XX(\"der\"),{2}),Exp.CALL(XX(\"der\",{3}))}
  NOTE: the vectorized expression is inserted first in the argument list
 of the call, so if extra arguments should be passed these can be given as
 input to the call expression.	    
"
  input Exp.Exp inExp;
  input list<Exp.Exp> inExpExpLst;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inExp,inExpExpLst)
    local
      Exp.Exp e,callexp;
      list<Exp.Exp> es_1,args,es;
      Absyn.Path fn;
      Boolean tuple_,builtin;
      Exp.Type tp;
    case (e,{}) then {}; 
    case ((callexp as Exp.CALL(path = fn,expLst = args,tuple_ = tuple_,builtin = builtin,ty=tp)),(e :: es))
      equation 
        es_1 = callVectorize(callexp, es);
      then
        (Exp.CALL(fn,(e :: args),tuple_,builtin,tp) :: es_1);
    case (_,_)
      equation 
        Debug.fprint("failtrace", "-call_vectorize failed\n");
      then
        fail();
  end matchcontinue;
end callVectorize;

protected function createCrefArray "function: createCrefArray
 
  helper function to cref_vectorize, creates each individual cref, 
  e.g. {x{1},x{2}, ...} from x.
"
  input Exp.ComponentRef inComponentRef1;
  input Integer inInteger2;
  input Integer inInteger3;
  input Exp.Type inType4;
  input Types.Type inType5;
  output Exp.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inComponentRef1,inInteger2,inInteger3,inType4,inType5)
    local
      Exp.ComponentRef cr,cr_1;
      Integer indx,ds,indx_1;
      Exp.Type et,elt_tp;
      tuple<Types.TType, Option<Absyn.Path>> t;
      list<Exp.Exp> expl;
      Exp.Exp e_1;
      list<Exp.Subscript> ss;
    case (cr,indx,ds,et,t) /* index iterator dimension size */ 
      equation 
        (indx > ds) = true;
      then
        Exp.ARRAY(et,true,{});
    case (cr,indx,ds,et,t) /* for crefs with wholedim */ 
      equation 
        indx_1 = indx + 1;
        Exp.ARRAY(_,_,expl) = createCrefArray(cr, indx_1, ds, et, t);
        Exp.WHOLEDIM()::ss = Exp.crefLastSubs(cr);
        cr_1 = Exp.crefStripLastSubs(cr);
        cr_1 = Exp.subscriptCref(cr_1, Exp.INDEX(Exp.ICONST(indx))::ss);
        elt_tp = Exp.unliftArray(et);
        e_1 = crefVectorize(true,Exp.CREF(cr_1,elt_tp), t);
      then
        Exp.ARRAY(et,true,(e_1 :: expl));
    case (cr,indx,ds,et,t) /* no subscript */ 
      equation 
        indx_1 = indx + 1;
        {} = Exp.crefLastSubs(cr);
        Exp.ARRAY(_,_,expl) = createCrefArray(cr, indx_1, ds, et, t);
        cr_1 = Exp.subscriptCref(cr, {Exp.INDEX(Exp.ICONST(indx))});
        elt_tp = Exp.unliftArray(et);
        e_1 = crefVectorize(true,Exp.CREF(cr_1,elt_tp), t);
      then
        Exp.ARRAY(et,true,(e_1 :: expl));
    case (cr,indx,ds,et,t) /* index */ 
      equation 
        (Exp.INDEX(e_1) :: ss) = Exp.crefLastSubs(cr);
        cr_1 = Exp.crefStripLastSubs(cr);
        cr_1 = Exp.subscriptCref(cr_1,ss); 
        Exp.ARRAY(_,_,expl) = createCrefArray(cr_1, indx, ds, et, t);
        expl = Util.listMap1(expl,Exp.prependSubscriptExp,Exp.INDEX(e_1));
      then
        Exp.ARRAY(et,true,expl);
        
    case (cr,indx,ds,et,t)
      equation 
        Debug.fprint("failtrace", "create_cref_array failed\n");
      then
        fail();
  end matchcontinue;
end createCrefArray;

protected function createCrefArray2d "function: createCrefArray2d
 
  helper function to cref_vectorize, creates each individual cref, 
  e.g. {x{1,1},x{2,1}, ...} from x.
"
  input Exp.ComponentRef inComponentRef1;
  input Integer inInteger2;
  input Integer inInteger3;
  input Integer inInteger4;
  input Exp.Type inType5;
  input Types.Type inType6;
  output Exp.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inComponentRef1,inInteger2,inInteger3,inInteger4,inType5,inType6)
    local
      Exp.ComponentRef cr,cr_1;
      Integer indx,ds,ds2,indx_1;
      Exp.Type et,tp,elt_tp;
      tuple<Types.TType, Option<Absyn.Path>> t;
      list<list<tuple<Exp.Exp, Boolean>>> ms;
      Boolean sc;
      list<Exp.Exp> expl;
      list<Boolean> scs;
      list<tuple<Exp.Exp, Boolean>> row;
    case (cr,indx,ds,ds2,et,t) /* index iterator dimension size 1 dimension size 2 */ 
      equation 
        (indx > ds) = true;
      then
        Exp.MATRIX(et,0,{});
    case (cr,indx,ds,ds2,et,t)
      equation 
        indx_1 = indx + 1;
        Exp.MATRIX(_,_,ms) = createCrefArray2d(cr, indx_1, ds, ds2, et, t);
        cr_1 = Exp.subscriptCref(cr, {Exp.INDEX(Exp.ICONST(indx))});
        elt_tp = Exp.unliftArray(et);
        Exp.ARRAY(tp,sc,expl) = crefVectorize(true,Exp.CREF(cr_1,elt_tp), t);
        scs = Util.listFill(sc, ds2);
        row = Util.listThreadTuple(expl, scs);
      then
        Exp.MATRIX(et,ds,(row :: ms));
    case (cr,indx,ds,ds2,et,t)
      equation 
        Debug.fprint("failtrace", "create_cref_array failed\n");
      then
        fail();
  end matchcontinue;
end createCrefArray2d;

protected function elabCrefSubs "function: elabCrefSubs
 
  This function elaborates on all subscripts in a component reference.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef inComponentRef;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.ComponentRef outComponentRef;
  output Types.Const outConst;
algorithm 
  (outCache,outComponentRef,outConst):=
  matchcontinue (inCache,inEnv,inComponentRef,inBoolean)
    local
      tuple<Types.TType, Option<Absyn.Path>> t;
      list<Integer> sl;
      list<Exp.Subscript> ss_1;
      Types.Const const,const1,const2;
      list<Env.Frame> env;
      Ident id;
      list<Absyn.Subscript> ss;
      Boolean impl;
      Exp.ComponentRef cr;
      Absyn.ComponentRef subs;
      Env.Cache cache;
    case (cache,env,Absyn.CREF_IDENT(name = id,subscripts = ss),impl) /* impl */ 
      equation 
        (cache,_,t,_) = Lookup.lookupVar(cache,env, Exp.CREF_IDENT(id,{}));
        sl = Types.getDimensionSizes(t);
        (cache,ss_1,const) = elabSubscriptsDims(cache,env, ss, sl, impl);


         /* elab_subscripts (env, ss) => (ss\', const) */ 
      then
        (cache,Exp.CREF_IDENT(id,ss_1),const);
    case (cache,env,Absyn.CREF_IDENT(name = id,subscripts = ss),impl)
      equation 
        (cache,ss_1,const) = elabSubscripts(cache,env, ss, impl);
      then
        (cache,Exp.CREF_IDENT(id,ss_1),const);
    case (cache,env,Absyn.CREF_QUAL(name = id,subScripts = ss,componentRef = subs),impl)
      equation 
        (cache,ss_1,const1) = elabSubscripts(cache,env, ss, impl);
        (cache,cr,const2) = elabCrefSubs(cache,env, subs, impl);
        const = Types.constAnd(const1, const2);
      then
        (cache,Exp.CREF_QUAL(id,ss_1,cr),const);
    case (cache,_,_,impl)
      equation 
        Debug.fprint("failtrace", "- elab_cref_subs failed\n");
      then
        fail();
  end matchcontinue;
end elabCrefSubs;

public function elabSubscripts "function: elabSubscripts
 
  This function converts a list of `Absyn.Subscript\' to a list of
  `Exp.Subscript\', and checks if all subscripts are constant.
  HJ: not checking for constant, returning if constant or not
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Subscript> inAbsynSubscriptLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output list<Exp.Subscript> outExpSubscriptLst;
  output Types.Const outConst;
algorithm 
  (outCache,outExpSubscriptLst,outConst):=
  matchcontinue (inCache,inEnv,inAbsynSubscriptLst,inBoolean)
    local
      Exp.Subscript sub_1;
      Types.Const const1,const2,const;
      list<Exp.Subscript> subs_1;
      list<Env.Frame> env;
      Absyn.Subscript sub;
      list<Absyn.Subscript> subs;
      Boolean impl;
      Env.Cache cache;
    case (cache,_,{},_) then (cache,{},Types.C_CONST());  /* impl */ 
    case (cache,env,(sub :: subs),impl)
      equation 
        (cache,sub_1,const1) = elabSubscript(cache,env, sub, impl);
        (cache,subs_1,const2) = elabSubscripts(cache,env, subs, impl);
        const = Types.constAnd(const1, const2);
      then
        (cache,(sub_1 :: subs_1),const);
  end matchcontinue;
end elabSubscripts;

protected function elabSubscriptsDims "function: elabSubscriptsDims
 
  Helper function to elab_subscripts
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Subscript> inAbsynSubscriptLst;
  input list<Integer> inIntegerLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output list<Exp.Subscript> outExpSubscriptLst;
  output Types.Const outConst;
algorithm 
  (outCache,outExpSubscriptLst,outConst):=
  matchcontinue (inCache,inEnv,inAbsynSubscriptLst,inIntegerLst,inBoolean)
    local
      Exp.Subscript sub_1;
      Types.Const const1,const2,const;
      list<Exp.Subscript> subs_1,ss;
      list<Env.Frame> env;
      Absyn.Subscript sub;
      list<Absyn.Subscript> subs;
      Integer dim;
      list<Integer> restdims;
      Boolean impl;
      Env.Cache cache;
    case (cache,_,{},_,_) then (cache,{},Types.C_CONST());  /* impl */ 
    //if the subscript contains a param the it should be evaluated to the 
    //value
    case (cache,env,(sub :: subs),(dim :: restdims),impl) /* If param, call ceval. */ 
      equation 
        (cache,sub_1,const1) = elabSubscript(cache,env, sub, impl);
        (cache,subs_1,const2) = elabSubscriptsDims(cache,env, subs, restdims, impl);
        Types.C_PARAM() = Types.constAnd(const1, const2);
        (cache,ss) = Ceval.cevalSubscripts(cache,env, (sub_1 :: subs_1), (dim :: restdims), impl, 
          Ceval.MSG());
      then
        (cache,ss,Types.C_PARAM());
    //if the subscript contains a const the it should be evaluated to the 
    //value
    case (cache,env,(sub :: subs),(dim :: restdims),impl) /* If constant, call ceval. */ 
      equation 
        (cache,sub_1,const1) = elabSubscript(cache,env, sub, impl);
        (cache,subs_1,const2) = elabSubscriptsDims(cache,env, subs, restdims, impl);
        Types.C_CONST() = Types.constAnd(const1, const2);
        (cache,ss) = Ceval.cevalSubscripts(cache,env, (sub_1 :: subs_1), (dim :: restdims), impl, 
          Ceval.MSG());
      then
        (cache,ss,Types.C_CONST());
    case (cache,env,(sub :: subs),(dim :: restdims),impl)
      equation 
        (cache,sub_1,const1) = elabSubscript(cache,env, sub, impl);
        (cache,subs_1,const2) = elabSubscriptsDims(cache,env, subs, restdims, impl);
        const = Types.constAnd(const1, const2);
      then
        (cache,(sub_1 :: subs_1),const);
  end matchcontinue;
end elabSubscriptsDims;

protected function elabSubscript "function: elabSubscript
 
  This function converts an `Absyn.Subscript\' to an
  `Exp.Subscript\'.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Subscript inSubscript;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.Subscript outSubscript;
  output Types.Const outConst;
algorithm 
  (outCache,outSubscript,outConst):=
  matchcontinue (inCache,inEnv,inSubscript,inBoolean)
    local
      Boolean impl;
      Exp.Exp sub_1;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Types.Const const;
      Exp.Subscript sub_2;
      list<Env.Frame> env;
      Absyn.Exp sub;
      Env.Cache cache;
    case (cache,_,Absyn.NOSUB(),impl) then (cache,Exp.WHOLEDIM(),Types.C_CONST());  /* impl */ 
    case (cache,env,Absyn.SUBSCRIPT(subScript = sub),impl)
      equation 
        (cache,sub_1,Types.PROP(ty,const),_) = elabExp(cache,env, sub, impl, NONE,true);
        sub_2 = elabSubscriptType(ty, sub, sub_1);
      then
        (cache,sub_2,const);
  end matchcontinue;
end elabSubscript;

protected function elabSubscriptType "function: elabSubscriptType
 
  This function is used to find the correct constructor for
  `Exp.Subscript\' to use for an indexing expression.  If an integer
  is given as index, `Exp.INDEX()\' is used, and if an integer array
  is given, `Exp.SLICE()\' is used.
"
  input Types.Type inType1;
  input Absyn.Exp inExp2;
  input Exp.Exp inExp3;
  output Exp.Subscript outSubscript;
algorithm 
  outSubscript:=
  matchcontinue (inType1,inExp2,inExp3)
    local
      Exp.Exp sub;
      Ident e_str,t_str;
      tuple<Types.TType, Option<Absyn.Path>> t;
      Absyn.Exp e;
    case ((Types.T_INTEGER(varLstInt = _),_),_,sub) then Exp.INDEX(sub); 
    case ((Types.T_ARRAY(arrayType = (Types.T_INTEGER(varLstInt = _),_)),_),_,sub) then Exp.SLICE(sub); 
    case (t,e,_)
      equation 
        e_str = Dump.printExpStr(e);
        t_str = Types.unparseType(t);
        Error.addMessage(Error.SUBSCRIPT_NOT_INT_OR_INT_ARRAY, {e_str,t_str});
      then
        fail();
  end matchcontinue;
end elabSubscriptType;

protected function subscriptCrefType "function: subscriptCrefType
 
  If a component of an array type is subscripted, the type of the
  component reference is of lower dimensionality than the
  component.  This function shows the function between the component
  type and the component reference expression type.
 
  This function might actually not be needed.
"
  input Exp.Exp inExp;
  input Types.Type inType;
  output Types.Type outType;
algorithm 
  outType:=
  matchcontinue (inExp,inType)
    local
      tuple<Types.TType, Option<Absyn.Path>> t_1,t;
      Exp.ComponentRef c;
      Exp.Exp e;
    case (Exp.CREF(componentRef = c),t)
      equation 
        t_1 = subscriptCrefType2(c, t);
      then
        t_1;
    case (e,t) then t; 
  end matchcontinue;
end subscriptCrefType;

protected function subscriptCrefType2
  input Exp.ComponentRef inComponentRef;
  input Types.Type inType;
  output Types.Type outType;
algorithm 
  outType:=
  matchcontinue (inComponentRef,inType)
    local
      tuple<Types.TType, Option<Absyn.Path>> t,t_1;
      list<Exp.Subscript> subs;
      Exp.ComponentRef c;
    case (Exp.CREF_IDENT(subscriptLst = {}),t) then t; 
    case (Exp.CREF_IDENT(subscriptLst = subs),t)
      equation 
        t_1 = subscriptType(t, subs);
      then
        t_1;
    case (Exp.CREF_QUAL(componentRef = c),t)
      equation 
        t_1 = subscriptCrefType2(c, t);
      then
        t_1;
  end matchcontinue;
end subscriptCrefType2;

protected function subscriptType "function: subscriptType
 
  Given an array dimensionality and a list of subscripts, this
  function reduces the dimensionality.
 
  This does not handle slices or check that subscripts are not out
  of bounds.
"
  input Types.Type inType;
  input list<Exp.Subscript> inExpSubscriptLst;
  output Types.Type outType;
algorithm 
  outType:=
  matchcontinue (inType,inExpSubscriptLst)
    local
      tuple<Types.TType, Option<Absyn.Path>> t,t_1;
      list<Exp.Subscript> subs;
      Types.ArrayDim dim;
      Option<Absyn.Path> p;
    case (t,{}) then t; 
    case ((Types.T_ARRAY(arrayDim = Types.DIM(integerOption = _),arrayType = t),_),(Exp.INDEX(exp = _) :: subs))
      equation 
        t_1 = subscriptType(t, subs);
      then
        t_1;
    case ((Types.T_ARRAY(arrayDim = dim,arrayType = t),p),(Exp.SLICE(exp = _) :: subs))
      equation 
        t_1 = subscriptType(t, subs);
      then
        ((Types.T_ARRAY(dim,t_1),p));
    case ((Types.T_ARRAY(arrayDim = dim,arrayType = t),p),(Exp.WHOLEDIM() :: subs))
      equation 
        t_1 = subscriptType(t, subs);
      then
        ((Types.T_ARRAY(dim,t_1),p));
    case (t,_)
      equation 
        Print.printBuf("- subscript_type failed (");
        Types.printType(t);
        Print.printBuf(" , [...])\n");
      then
        fail();
  end matchcontinue;
end subscriptType;

protected function elabIfexp "function: elabIfexp
  
  This function elaborates on the parts of an if expression.
"
	input Env.Cache inCache;
  input Env.Env inEnv1;
  input Exp.Exp inExp2;
  input Types.Properties inProperties3;
  input Exp.Exp inExp4;
  input Types.Properties inProperties5;
  input Exp.Exp inExp6;
  input Types.Properties inProperties7;
  input Boolean inBoolean8;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption9;
  output Env.Cache outCache;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
algorithm 
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv1,inExp2,inProperties3,inExp4,inProperties5,inExp6,inProperties7,inBoolean8,inInteractiveInteractiveSymbolTableOption9)
    local
      Types.Const c,c1,c2,c3;
      Exp.Exp exp,e1,e2,e3,e2_1,e3_1;
      list<Env.Frame> env;
      tuple<Types.TType, Option<Absyn.Path>> t2,t3,t2_1,t3_1,t1;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Ident e_str,t_str,e1_str,t1_str,e2_str,t2_str;
      Env.Cache cache;
    case (cache,env,e1,Types.PROP(type_ = (Types.T_BOOL(varLstBool = _),_),constFlag = c1),e2,Types.PROP(type_ = t2,constFlag = c2),e3,Types.PROP(type_ = t3,constFlag = c3),impl,st)
      equation 
        true = Types.equivtypes(t2, t3);
        c = constIfexp(e1, c1, c2, c3);
        (cache,exp) = cevalIfexpIfConstant(cache,env, e1, e2, e3, c1, impl, st);
      then
        (cache,exp,Types.PROP(t2,c));
    case (cache,env,e1,Types.PROP(type_ = (Types.T_BOOL(varLstBool = _),_),constFlag = c1),e2,Types.PROP(type_ = t2,constFlag = c2),e3,Types.PROP(type_ = t3,constFlag = c3),impl,st)
      equation 
        (e2_1,t2_1) = Types.matchType(e2, t2, t3);
        c = constIfexp(e1, c1, c2, c3) "then-part type converted to match else-part" ;
        (cache,exp) = cevalIfexpIfConstant(cache,env, e1, e2_1, e3, c1, impl, st);
      then
        (cache,exp,Types.PROP(t2_1,c));
    case (cache,env,e1,Types.PROP(type_ = (Types.T_BOOL(varLstBool = _),_),constFlag = c1),e2,Types.PROP(type_ = t2,constFlag = c2),e3,Types.PROP(type_ = t3,constFlag = c3),impl,st)
      equation 
        (e3_1,t3_1) = Types.matchType(e3, t3, t2);
        c = constIfexp(e1, c1, c2, c3) "else-part type converted to match then-part" ;
        (cache,exp) = cevalIfexpIfConstant(cache,env, e1, e2, e3_1, c1, impl, st);
      then
        (cache,exp,Types.PROP(t2,c));
    case (cache,env,e1,Types.PROP(type_ = t1,constFlag = c1),e2,Types.PROP(type_ = t2,constFlag = c2),e3,Types.PROP(type_ = t3,constFlag = c3),impl,st)
      equation 
        failure(equality(t1 = (Types.T_BOOL({}),NONE)));
        e_str = Exp.printExpStr(e1);
        t_str = Types.unparseType(t1);
        Error.addMessage(Error.IF_CONDITION_TYPE_ERROR, {e_str,t_str});
      then
        fail();
    case (cache,env,e1,Types.PROP(type_ = (Types.T_BOOL(varLstBool = _),_),constFlag = c1),e2,Types.PROP(type_ = t2,constFlag = c2),e3,Types.PROP(type_ = t3,constFlag = c3),impl,st)
      equation 
        false = Types.equivtypes(t2, t3);
        e1_str = Exp.printExpStr(e2);
        t1_str = Types.unparseType(t2);
        e2_str = Exp.printExpStr(e3);
        t2_str = Types.unparseType(t3);
        Error.addMessage(Error.TYPE_MISMATCH_IF_EXP, {e1_str,t1_str,e2_str,t2_str});
      then
        fail();
    case (_,_,_,_,_,_,_,_,_,_)
      equation 
        Print.printBuf("- elab_ifexp failed\n");
      then
        fail();
  end matchcontinue;
end elabIfexp;

protected function cevalIfexpIfConstant "function: cevalIfexpIfConstant
  author: PA
 
  Constant evaluates the condition of an expression if it is constants and
  elimitates the if expressions by selecting branch.
"
	input Env.Cache inCache;
  input Env.Env inEnv1;
  input Exp.Exp inExp2;
  input Exp.Exp inExp3;
  input Exp.Exp inExp4;
  input Types.Const inConst5;
  input Boolean inBoolean6;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption7;
	output Env.Cache outCache;
  output Exp.Exp outExp;
algorithm 
  (outCache,outExp) :=
  matchcontinue (inCache,inEnv1,inExp2,inExp3,inExp4,inConst5,inBoolean6,inInteractiveInteractiveSymbolTableOption7)
    local
      list<Env.Frame> env;
      Exp.Exp e1,e2,e3,res;
      Boolean impl,cond;
      Option<Interactive.InteractiveSymbolTable> st;
      Env.Cache cache;
    case (cache,env,e1,e2,e3,Types.C_VAR(),impl,st) then (cache,Exp.IFEXP(e1,e2,e3)); 
    case (cache,env,e1,e2,e3,Types.C_PARAM(),impl,st) then (cache,Exp.IFEXP(e1,e2,e3)); 
    case (cache,env,e1,e2,e3,Types.C_CONST(),impl,st)
      equation 
        (cache,Values.BOOL(cond),_) = Ceval.ceval(cache,env, e1, impl, st, NONE, Ceval.MSG());
        res = Util.if_(cond, e2, e3);
      then
        (cache,res);
  end matchcontinue;
end cevalIfexpIfConstant;

protected function constIfexp "function: constIfexp
 
  Tests wether an `if\' expression is constant.  This is done by
  first testing if the conditional is constant, and if so evaluating
  it to see which branch should be tested for constant-ness.
 
  This will miss some occations where the expression actually is
  constant, as in the expression `if x then 1.0 else 1.0\'.
"
  input Exp.Exp inExp1;
  input Types.Const inConst2;
  input Types.Const inConst3;
  input Types.Const inConst4;
  output Types.Const outConst;
algorithm 
  outConst:=
  matchcontinue (inExp1,inConst2,inConst3,inConst4)
    local Types.Const const,c1,c2,c3;
    case (_,c1,c2,c3)
      equation 
        const = Util.listReduce({c1,c2,c3}, Types.constAnd);
      then
        const;
  end matchcontinue;
end constIfexp;

public function valueExp
  input Values.Value inValue;
  output Exp.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inValue)
    local
      Integer x;
      Boolean a;
      list<Exp.Exp> explist;
      tuple<Types.TType, Option<Absyn.Path>> vt;
      Exp.Type t;
      Values.Value v;
      list<Values.Value> xs,vallist;
    case (Values.INTEGER(integer = x)) then Exp.ICONST(x); 
    case (Values.REAL(real = x))
      local Real x;
      then
        Exp.RCONST(x);
    case (Values.STRING(string = x))
      local Ident x;
      then
        Exp.SCONST(x);
    case (Values.BOOL(boolean = x))
      local Boolean x;
      then
        Exp.BCONST(x);
    case (Values.ARRAY(valueLst = {})) then Exp.ARRAY(Exp.OTHER(),false,{}); 
    case (Values.ARRAY(valueLst = (x :: xs)))
      local Values.Value x;
      equation 
        explist = Util.listMap((x :: xs), valueExp);
        vt = valueType(x);
        t = Types.elabType(vt);
        a = Types.isArray(vt);
      then
        Exp.ARRAY(t,a,explist);
    case (Values.TUPLE(valueLst = vallist))
      equation 
        explist = Util.listMap(vallist, valueExp);
      then
        Exp.TUPLE(explist);
    case v
      equation 
        Error.addMessage(Error.INTERNAL_ERROR, {"value_exp failed"});
      then
        fail();
  end matchcontinue;
end valueExp;

protected function valueType "
  function: valueType
  This function investigates a Value and return the Type of this value.

  LS: Removed. Using Types.typeOfValue instead
"
  input Values.Value v;
  output Types.Type t;
algorithm 
  t := Types.typeOfValue(v);
end valueType;

protected function canonCref2 "function: canonCref2
 
  This function relates a `Exp.ComponentRef\' to its canonical form,
  which is when all subscripts are evaluated to constant values.  If
  Such an evaluation is not possible, there is no canonical form and
  this function fails.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.ComponentRef inComponentRef;
  input Exp.ComponentRef inPrefixCref;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.ComponentRef outComponentRef;
algorithm 
  (outCache,outComponentRef) :=
  matchcontinue (inCache,inEnv,inComponentRef,inPrefixCref,inBoolean)
    local
      list<Exp.Subscript> ss_1,ss;
      list<Env.Frame> env;
      Ident n;
      Boolean impl;
      Env.Cache cache;
      Exp.ComponentRef prefixCr,cr;
      list<Integer> sl;
      tuple<Types.TType, Option<Absyn.Path>> t;
    case (cache,env,Exp.CREF_IDENT(ident = n,subscriptLst = ss),prefixCr,impl) /* impl */ 
      equation 
        cr = Exp.joinCrefs(prefixCr,Exp.CREF_IDENT(n,{}));
        (cache,_,t,_) = Lookup.lookupVar(cache,env, cr);
        sl = Types.getDimensionSizes(t);          
        (cache,ss_1) = Ceval.cevalSubscripts(cache,env, ss, sl, impl, Ceval.MSG());
      then
        (cache,Exp.CREF_IDENT(n,ss_1));
  end matchcontinue;
end canonCref2;

public function canonCref "function: canonCref
 
  Transform expression to canonical form by constant evaluating all 
  subscripts.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.ComponentRef inComponentRef;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Exp.ComponentRef outComponentRef;
algorithm 
  (outCache,outComponentRef) :=
  matchcontinue (inCache,inEnv,inComponentRef,inBoolean)
    local
      tuple<Types.TType, Option<Absyn.Path>> t;
      list<Integer> sl;
      list<Exp.Subscript> ss_1,ss;
      list<Env.Frame> env;
      Ident n;
      Boolean impl;
      Exp.ComponentRef c_1,c,cr;
      Env.Cache cache;
    case (cache,env,Exp.CREF_IDENT(ident = n,subscriptLst = ss),impl) /* impl */ 
      equation 
        (cache,_,t,_) = Lookup.lookupVar(cache,env, Exp.CREF_IDENT(n,{}));
        sl = Types.getDimensionSizes(t);
        (cache,ss_1) = Ceval.cevalSubscripts(cache,env, ss, sl, impl, Ceval.MSG());
      then
        (cache,Exp.CREF_IDENT(n,ss_1));
    case (cache,env,Exp.CREF_QUAL(ident = n,subscriptLst = ss,componentRef = c),impl)
      equation 
        (cache,_,t,_) = Lookup.lookupVar(cache,env, Exp.CREF_IDENT(n,{}));
        sl = Types.getDimensionSizes(t);
        (cache,ss_1) = Ceval.cevalSubscripts(cache,env, ss, sl, impl, Ceval.MSG());
       (cache,c_1) = canonCref2(cache,env, c, Exp.CREF_IDENT(n,ss), impl);
      then
        (cache,Exp.CREF_QUAL(n,ss_1,c_1));
    case (cache,env,cr,_)
      equation 
        Debug.fprint("failtrace", "-canon_cref failed, cr: ");
        Debug.fprint("failtrace", Exp.printComponentRefStr(cr));
        Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end canonCref;

public function eqCref "- Equality functions
  function: eqCref
 
  This function checks if two component references can be considered
  equal and fails if not.  Two component references are equal if all
  corresponding identifiers are the same, and if the subscripts are
  equal, according to the function `eq_subscripts\'.
"
  input Exp.ComponentRef inComponentRef1;
  input Exp.ComponentRef inComponentRef2;
algorithm 
  _:=
  matchcontinue (inComponentRef1,inComponentRef2)
    local
      Ident n1,n2;
      list<Exp.Subscript> s1,s2;
      Exp.ComponentRef c1,c2;
    case (Exp.CREF_IDENT(ident = n1,subscriptLst = s1),Exp.CREF_IDENT(ident = n2,subscriptLst = s2))
      equation 
        equality(n1 = n2);
        eqSubscripts(s1, s2);
      then
        ();
    case (Exp.CREF_QUAL(ident = n1,subscriptLst = s1,componentRef = c1),Exp.CREF_QUAL(ident = n2,subscriptLst = s2,componentRef = c2))
      equation 
        equality(n1 = n2);
        eqSubscripts(s1, s2);
        eqCref(c1, c2);
      then
        ();
  end matchcontinue;
end eqCref;

protected function eqSubscripts "function: eqSubscripts
 
  Two list of subscripts are equal if they are of equal length and
  all their elements are pairwise equal according to the function
  `eq_subscript\'.
"
  input list<Exp.Subscript> inExpSubscriptLst1;
  input list<Exp.Subscript> inExpSubscriptLst2;
algorithm 
  _:=
  matchcontinue (inExpSubscriptLst1,inExpSubscriptLst2)
    local
      Exp.Subscript s1,s2;
      list<Exp.Subscript> ss1,ss2;
    case ({},{}) then (); 
    case ((s1 :: ss1),(s2 :: ss2))
      equation 
        eqSubscript(s1, s2);
        eqSubscripts(ss1, ss2);
      then
        ();
  end matchcontinue;
end eqSubscripts;

protected function eqSubscript "function: eqSubscript
 
  This function test whether two subscripts are equal.  Two
  subscripts are equal if they have the same constructor, and if all
  corresponding expressions are either syntactically equal, or if
  they have the same constant value.
"
  input Exp.Subscript inSubscript1;
  input Exp.Subscript inSubscript2;
algorithm 
  _:=
  matchcontinue (inSubscript1,inSubscript2)
    local Exp.Exp s1,s2;
    case (Exp.WHOLEDIM(),Exp.WHOLEDIM()) then (); 
    case (Exp.INDEX(exp = s1),Exp.INDEX(exp = s2))
      equation 
        equality(s1 = s2);
      then
        ();
  end matchcontinue;
end eqSubscript;

protected function elabArglist "- Argument type casting and operator de-overloading
 
  If a function is called with arguments that don\'t match the
  expected parameter types, implicit type conversions are performed
  in some cases.  Usually it is an integer argument that is promoted
  to a real.
 
  Many operators in Modelica are overloaded, meaning that they can
  operate on several different types of arguments.  To describe what
  it means to add, say, an integer and a real number, the
  expressions have to be de-overloaded, with one operator for each
  distinct operation.
 
 
  function: elabArglist
 
  Given a list of parameter types and an argument list, this
  function tries to match the two, promoting the type of arguments
  when necessary.
"
  input list<Types.Type> inTypesTypeLst;
  input list<tuple<Exp.Exp, Types.Type>> inTplExpExpTypesTypeLst;
  output list<Exp.Exp> outExpExpLst;
  output list<Types.Type> outTypesTypeLst;
algorithm 
  (outExpExpLst,outTypesTypeLst):=
  matchcontinue (inTypesTypeLst,inTplExpExpTypesTypeLst)
    local
      Exp.Exp arg_1,arg;
      tuple<Types.TType, Option<Absyn.Path>> atype_1,pt,atype;
      list<Exp.Exp> args_1;
      list<tuple<Types.TType, Option<Absyn.Path>>> atypes_1,pts;
      list<tuple<Exp.Exp, tuple<Types.TType, Option<Absyn.Path>>>> args;
    case ({},{}) then ({},{}); 
    case ((pt :: pts),((arg,atype) :: args))
      equation 
        (arg_1,atype_1) = Types.matchType(arg, atype, pt);
        (args_1,atypes_1) = elabArglist(pts, args);
      then
        ((arg_1 :: args_1),(atype_1 :: atypes_1));
  end matchcontinue;
end elabArglist;

public function deoverload "function: deoverload
 
  Given several lists of parameter types and one argument list, this
  function tries to find one list of parameter types which is
  compatible with the argument list.  It uses `elab_arglist\' to do
  the matching, which means that automatic type conversions will be
  made when necessary.  The new argument list, together with a new
  operator that corresponds to the parameter type list is returned.
 
  The basic principle is that the first operator that matches is
  chosen.
 
  The third argument to the function is the expression containing
  the operation to be deoverloaded.  It is only used for error
  messages.
"
  input list<tuple<Exp.Operator, list<Types.Type>, Types.Type>> inTplExpOperatorTypesTypeLstTypesTypeLst;
  input list<tuple<Exp.Exp, Types.Type>> inTplExpExpTypesTypeLst;
  input Absyn.Exp inExp;
  output Exp.Operator outOperator;
  output list<Exp.Exp> outExpExpLst;
  output Types.Type outType;
algorithm 
  (outOperator,outExpExpLst,outType):=
  matchcontinue (inTplExpOperatorTypesTypeLstTypesTypeLst,inTplExpExpTypesTypeLst,inExp)
    local
      list<Exp.Exp> args_1,exps;
      list<tuple<Types.TType, Option<Absyn.Path>>> types_1,params,tps;
      tuple<Types.TType, Option<Absyn.Path>> rtype_1,rtype;
      Exp.Operator op;
      list<tuple<Exp.Exp, tuple<Types.TType, Option<Absyn.Path>>>> args;
      list<tuple<Exp.Operator, list<tuple<Types.TType, Option<Absyn.Path>>>, tuple<Types.TType, Option<Absyn.Path>>>> xs;
      Absyn.Exp exp;
      Ident s,estr,tpsstr;
      list<Ident> exps_str,tps_str;
    case (((op,params,rtype) :: _),args,_)
      equation 
        Debug.fprintList("dovl", params, Types.printType, "\n");
        Debug.fprint("dovl", "\n===\n");
        (args_1,types_1) = elabArglist(params, args);
        rtype_1 = computeReturnType(op, types_1, rtype);
      then
        (op,args_1,rtype_1);
    case ((_ :: xs),args,exp)
      equation 
        (op,args_1,rtype) = deoverload(xs, args, exp);
      then
        (op,args_1,rtype);
    case ({},args,exp)
      equation 
        s = Dump.printExpStr(exp);
        exps = Util.listMap(args, Util.tuple21);
        tps = Util.listMap(args, Util.tuple22);
        exps_str = Util.listMap(exps, Exp.printExpStr);
        estr = Util.stringDelimitList(exps_str, ", ");
        tps_str = Util.listMap(tps, Types.unparseType);
        tpsstr = Util.stringDelimitList(tps_str, ", ");
        s = Util.stringAppendList({s," (expressions :",estr," types: ",tpsstr,")"});
        Error.addMessage(Error.UNRESOLVABLE_TYPE, {s});
      then
        fail();
  end matchcontinue;
end deoverload;

protected function computeReturnType "function: computeReturnType
  This function determines the return type of an operator and the types of 
  the operands.
"
  input Exp.Operator inOperator;
  input list<Types.Type> inTypesTypeLst;
  input Types.Type inType;
  output Types.Type outType;
algorithm 
  outType:=
  matchcontinue (inOperator,inTypesTypeLst,inType)
    local
      tuple<Types.TType, Option<Absyn.Path>> typ1,typ2,rtype,etype,typ;
      Ident t1_str,t2_str;
      Integer n1,n2,m,n,m1,m2,p;
    case (Exp.ADD_ARR(ty = _),{typ1,typ2},rtype)
      equation 
        true = Types.subtype(typ1, typ2);
      then
        typ1;

    case (Exp.ADD_ARR(ty = _),{typ1,typ2},rtype)
      equation 
        true = Types.subtype(typ1, typ2);
      then
        typ1;

    case (Exp.ADD_ARR(ty = _),{typ1,typ2},_)
      equation 
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        Error.addMessage(Error.INCOMPATIBLE_TYPES, {"vector addition",t1_str,t2_str});
      then
        fail();

    case (Exp.SUB_ARR(ty = _),{typ1,typ2},rtype)
      equation 
        true = Types.subtype(typ1, typ2);
      then
        typ1;

    case (Exp.SUB_ARR(ty = _),{typ1,typ2},rtype)
      equation 
        true = Types.subtype(typ1, typ2);
      then
        typ1;

    case (Exp.SUB_ARR(ty = _),{typ1,typ2},_)
      equation 
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        Error.addMessage(Error.INCOMPATIBLE_TYPES, 
          {"vector subtraction",t1_str,t2_str});
      then
        fail();

    case (Exp.MUL_SCALAR_PRODUCT(ty = _),{typ1,typ2},rtype)
      equation 
        true = Types.subtype(typ1, typ2);
      then
        rtype;

    case (Exp.MUL_SCALAR_PRODUCT(ty = _),{typ1,typ2},rtype)
      equation 
        true = Types.subtype(typ1, typ2);
      then
        rtype;

    case (Exp.MUL_SCALAR_PRODUCT(ty = _),{typ1,typ2},rtype)
      equation 
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        Error.addMessage(Error.INCOMPATIBLE_TYPES, {"scalar product",t1_str,t2_str});
      then
        fail();

        /* Vector[n]*Matrix[n,m] */
    case (Exp.MUL_MATRIX_PRODUCT(ty = _),{typ1,typ2},_)
      equation 
        1 = nDims(typ1);
        2 = nDims(typ2);
        n1 = dimSize(typ1, 1);
        n2 = dimSize(typ2, 1);
        m = dimSize(typ2, 2);
        equality(n1 = n2);
        etype = elementType(typ1);
        rtype = (Types.T_ARRAY(Types.DIM(SOME(m)),etype),NONE);
      then
        rtype;
        /* Matrix[n,m]*Vector[m] */
    case (Exp.MUL_MATRIX_PRODUCT(ty = _),{typ1,typ2},_)
      equation 
        2 = nDims(typ1);
        1 = nDims(typ2);
        n = dimSize(typ1, 1);
        m1 = dimSize(typ1, 2);
        m2 = dimSize(typ2, 1);
        equality(m1 = m2);
        etype = elementType(typ2);
        rtype = (Types.T_ARRAY(Types.DIM(SOME(n)),etype),NONE);
      then
        rtype;

    case (Exp.MUL_MATRIX_PRODUCT(ty = _),{typ1,typ2},_)
      equation 
        2 = nDims(typ1);
        2 = nDims(typ2);
        n = dimSize(typ1, 1);
        m1 = dimSize(typ1, 2);
        m2 = dimSize(typ2, 1);
        p = dimSize(typ2, 2);
        equality(m1 = m2);
        etype = elementType(typ1);
        rtype = (
          Types.T_ARRAY(Types.DIM(SOME(n)),
          (Types.T_ARRAY(Types.DIM(SOME(p)),etype),NONE)),NONE);
      then
        rtype;

    case (Exp.MUL_MATRIX_PRODUCT(ty = _),{typ1,typ2},rtype)
      equation 
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        Error.addMessage(Error.INCOMPATIBLE_TYPES, 
          {"matrix multiplication",t1_str,t2_str});
      then
        fail();

    case (Exp.MUL_SCALAR_ARRAY(ty = _),{typ1,typ2},rtype) then typ2;  /* rtype */ 

    case (Exp.MUL_ARRAY_SCALAR(ty = _),{typ1,typ2},rtype) then typ1;  /* rtype */ 

    case (Exp.DIV_ARRAY_SCALAR(ty = _),{typ1,typ2},rtype) then typ1;  /* rtype */ 

    case (Exp.ADD(ty = _),_,typ) then typ; 

    case (Exp.SUB(ty = _),_,typ) then typ; 

    case (Exp.MUL(ty = _),_,typ) then typ; 

    case (Exp.DIV(ty = _),_,typ) then typ; 

    case (Exp.POW(ty = _),_,typ) then typ; 

    case (Exp.UMINUS(ty = _),_,typ) then typ; 

    case (Exp.UMINUS_ARR(ty = _),(typ1 :: _),_) then typ1; 

    case (Exp.UPLUS(ty = _),_,typ) then typ; 

    case (Exp.UPLUS_ARR(ty = _),(typ1 :: _),_) then typ1; 

    case (Exp.AND(),_,typ) then typ; 

    case (Exp.OR(),_,typ) then typ; 

    case (Exp.NOT(),_,typ) then typ; 

    case (Exp.LESS(ty = _),_,typ) then typ; 

    case (Exp.LESSEQ(ty = _),_,typ) then typ; 

    case (Exp.GREATER(ty = _),_,typ) then typ; 

    case (Exp.GREATEREQ(ty = _),_,typ) then typ; 

    case (Exp.EQUAL(ty = _),_,typ) then typ; 

    case (Exp.NEQUAL(ty = _),_,typ) then typ; 

    case (Exp.USERDEFINED(fqName = _),_,typ) then typ; 
  end matchcontinue;
end computeReturnType;

public function nDims "function nDims
  Returns the number of dimensions of a Type.
"
  input Types.Type inType;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inType)
    local
      Integer ns;
      tuple<Types.TType, Option<Absyn.Path>> t;
    case ((Types.T_INTEGER(varLstInt = _),_)) then 0; 
    case ((Types.T_REAL(varLstReal = _),_)) then 0; 
    case ((Types.T_STRING(varLstString = _),_)) then 0; 
    case ((Types.T_BOOL(varLstBool = _),_)) then 0; 
    case ((Types.T_ARRAY(arrayType = t),_))
      equation 
        ns = nDims(t);
      then
        ns + 1;
    case ((Types.T_COMPLEX(_,_,SOME(t)),_)) 
    equation
      ns = nDims(t);
      then ns;
  end matchcontinue;
end nDims;

protected function dimSize "function: dimSize
  Returns the dimension size of the given dimesion.
"
  input Types.Type inType;
  input Integer inInteger;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inType,inInteger)
    local
      Integer n,d_1,d;
      tuple<Types.TType, Option<Absyn.Path>> t;
    case ((Types.T_ARRAY(arrayDim = Types.DIM(integerOption = SOME(n))),_),1) then n;  /* n:th dimension size of n:nth dimension */ 
    case ((Types.T_ARRAY(arrayType = t),_),d)
      equation 
        (d > 1) = true;
        d_1 = d - 1;
        n = dimSize(t, d_1);
      then
        n;
    case ((Types.T_COMPLEX(_,_,SOME(t)),_),d)
      equation 
       n = dimSize(t, d);
      then
        n;
  end matchcontinue;
end dimSize;

protected function elementType "function: elementType
  Returns the element type of a type, i.e. for arrays, return the element type, and for 
  bulitin scalar types return the type itself.
"
  input Types.Type inType;
  output Types.Type outType;
algorithm 
  outType:=
  matchcontinue (inType)
    local tuple<Types.TType, Option<Absyn.Path>> t,t_1;
    case ((t as (Types.T_INTEGER(varLstInt = _),_))) then t; 
    case ((t as (Types.T_REAL(varLstReal = _),_))) then t; 
    case ((t as (Types.T_STRING(varLstString = _),_))) then t; 
    case ((t as (Types.T_BOOL(varLstBool = _),_))) then t; 
    case ((Types.T_ARRAY(arrayType = t),_))
      equation 
        t_1 = elementType(t);
      then
        t_1;
    case ((Types.T_COMPLEX(_,_,SOME(t)),_)) 
      equation
        t_1 = elementType(t);
      then t_1;
  end matchcontinue;
end elementType;

public function operators "function: operators
 
  This function relates the operators in the abstract syntax to the
  de-overaloaded operators in the SCode. It produces a list of available
  types for a specific operator, that the overload function chooses from.
  Therefore, in order for the builtin type conversion from Integer to 
  Real to work, operators that work on both Integers and Reals must 
  return the Integer type -before- the Real type in the list.
"
	input Env.Cache inCache;
  input Absyn.Operator inOperator1;
  input Env.Env inEnv2;
  input Types.Type inType3;
  input Types.Type inType4;
  output Env.Cache outCache;
  output list<tuple<Exp.Operator, list<Types.Type>, Types.Type>> outTplExpOperatorTypesTypeLstTypesTypeLst;
algorithm 
  (outCache,outTplExpOperatorTypesTypeLstTypesTypeLst) :=
  matchcontinue (inCache,inOperator1,inEnv2,inType3,inType4)
    local
      list<tuple<Types.TType, Option<Absyn.Path>>> intarrtypes,realarrtypes,stringarrtypes,inttypes,realtypes;
      list<tuple<Exp.Operator, list<tuple<Types.TType, Option<Absyn.Path>>>, tuple<Types.TType, Option<Absyn.Path>>>> intarrs,realarrs,stringarrs,scalars,userops,arrays,types,scalarprod,matrixprod,intscalararrs,realscalararrs,intarrsscalar,realarrsscalar,realarrscalar,arrscalar;
      list<Env.Frame> env;
      tuple<Types.TType, Option<Absyn.Path>> t1,t2,int_scalar,int_vector,int_matrix,real_scalar,real_vector,real_matrix;
      Exp.Operator int_mul,real_mul,int_mul_sp,real_mul_sp,int_mul_mp,real_mul_mp,real_div,real_pow,int_pow;
      Ident s;
      Absyn.Operator op;
      Env.Cache cache;
    case (cache,Absyn.ADD(),env,t1,t2) /* Arithmetical operators */ 
      equation 
        intarrtypes = arrayTypeList(9, (Types.T_INTEGER({}),NONE)) "The ADD operator" ;
        realarrtypes = arrayTypeList(9, (Types.T_REAL({}),NONE));
        stringarrtypes = arrayTypeList(9, (Types.T_STRING({}),NONE));
        intarrs = operatorReturn(Exp.ADD_ARR(Exp.INT()), intarrtypes, intarrtypes, 
          intarrtypes);
        realarrs = operatorReturn(Exp.ADD_ARR(Exp.REAL()), realarrtypes, realarrtypes, 
          realarrtypes);
        stringarrs = operatorReturn(Exp.ADD_ARR(Exp.STRING()), stringarrtypes, stringarrtypes, 
          stringarrtypes);
        scalars = {
          (Exp.ADD(Exp.INT()),
          {(Types.T_INTEGER({}),NONE),(Types.T_INTEGER({}),NONE)},(Types.T_INTEGER({}),NONE)),
          (Exp.ADD(Exp.REAL()),
          {(Types.T_REAL({}),NONE),(Types.T_REAL({}),NONE)},(Types.T_REAL({}),NONE)),
          (Exp.ADD(Exp.STRING()),
          {(Types.T_STRING({}),NONE),(Types.T_STRING({}),NONE)},(Types.T_STRING({}),NONE))};
        /*(cache,userops) = getKoeningOperatorTypes(cache,"plus", env, t1, t2);*/
        arrays = Util.listFlatten({intarrs,realarrs,stringarrs});
        types = Util.listFlatten({scalars,arrays/*,userops*/});
      then
        (cache,types);
    case (cache,Absyn.SUB(),env,t1,t2)
      equation 
        intarrtypes = arrayTypeList(9, (Types.T_INTEGER({}),NONE)) "the SUB operator" ;
        realarrtypes = arrayTypeList(9, (Types.T_REAL({}),NONE));
        intarrs = operatorReturn(Exp.SUB_ARR(Exp.INT()), intarrtypes, intarrtypes, 
          intarrtypes);
        realarrs = operatorReturn(Exp.SUB_ARR(Exp.REAL()), realarrtypes, realarrtypes, 
          realarrtypes);
        scalars = {
          (Exp.SUB(Exp.INT()),
          {(Types.T_INTEGER({}),NONE),(Types.T_INTEGER({}),NONE)},(Types.T_INTEGER({}),NONE)),
          (Exp.SUB(Exp.REAL()),
          {(Types.T_REAL({}),NONE),(Types.T_REAL({}),NONE)},(Types.T_REAL({}),NONE))};
        /*(cache,userops) = getKoeningOperatorTypes(cache,"minus", env, t1, t2);*/
        types = Util.listFlatten({scalars,intarrs,realarrs/*,userops*/});
      then
        (cache,types);
    case (cache,Absyn.MUL(),env,t1,t2)
      equation 
        intarrtypes = arrayTypeList(9, (Types.T_INTEGER({}),NONE)) "The MUL operator" ;
        realarrtypes = arrayTypeList(9, (Types.T_REAL({}),NONE));
        inttypes = nTypes(9, (Types.T_INTEGER({}),NONE));
        realtypes = nTypes(9, (Types.T_REAL({}),NONE));
        int_mul = Exp.MUL(Exp.INT());
        real_mul = Exp.MUL(Exp.REAL());
        int_mul_sp = Exp.MUL_SCALAR_PRODUCT(Exp.INT());
        real_mul_sp = Exp.MUL_SCALAR_PRODUCT(Exp.REAL());
        int_mul_mp = Exp.MUL_MATRIX_PRODUCT(Exp.INT());
        real_mul_mp = Exp.MUL_MATRIX_PRODUCT(Exp.REAL());
        int_scalar = (Types.T_INTEGER({}),NONE);
        int_vector = (Types.T_ARRAY(Types.DIM(NONE),int_scalar),NONE);
        int_matrix = (Types.T_ARRAY(Types.DIM(NONE),int_vector),NONE);
        real_scalar = (Types.T_REAL({}),NONE);
        real_vector = (Types.T_ARRAY(Types.DIM(NONE),real_scalar),NONE);
        real_matrix = (Types.T_ARRAY(Types.DIM(NONE),real_vector),NONE);
        scalars = {(int_mul,{int_scalar,int_scalar},int_scalar),
          (real_mul,{real_scalar,real_scalar},real_scalar)};
        scalarprod = {(int_mul_sp,{int_vector,int_vector},int_scalar),
          (real_mul_sp,{real_vector,real_vector},real_scalar)};
        matrixprod = {(int_mul_mp,{int_vector,int_matrix},int_vector),
          (int_mul_mp,{int_matrix,int_vector},int_vector),(int_mul_mp,{int_matrix,int_matrix},int_matrix),
          (real_mul_mp,{real_vector,real_matrix},real_vector),(real_mul_mp,{real_matrix,real_vector},real_vector),
          (real_mul_mp,{real_matrix,real_matrix},real_matrix)};
        intscalararrs = operatorReturn(Exp.MUL_SCALAR_ARRAY(Exp.INT()), inttypes, intarrtypes, 
          intarrtypes);
        realscalararrs = operatorReturn(Exp.MUL_SCALAR_ARRAY(Exp.REAL()), realtypes, realarrtypes, 
          realarrtypes);
        intarrsscalar = operatorReturn(Exp.MUL_ARRAY_SCALAR(Exp.INT()), intarrtypes, inttypes, 
          intarrtypes);
        realarrsscalar = operatorReturn(Exp.MUL_ARRAY_SCALAR(Exp.REAL()), realarrtypes, realtypes, 
          realarrtypes);
        /*(cache,userops) = getKoeningOperatorTypes(cache,"times", env, t1, t2);*/
        types = Util.listFlatten(
          {scalars,intscalararrs,realscalararrs,intarrsscalar,
          realarrsscalar,scalarprod,matrixprod/*,userops*/});
      then
        (cache,types);
    case (cache,Absyn.DIV(),env,t1,t2)
      equation 
        realarrtypes = arrayTypeList(9, (Types.T_REAL({}),NONE)) "The DIV operator" ;
        realtypes = nTypes(9, (Types.T_REAL({}),NONE));
        real_div = Exp.DIV(Exp.REAL());
        real_scalar = (Types.T_REAL({}),NONE);
        scalars = {(real_div,{real_scalar,real_scalar},real_scalar)};
        realarrscalar = operatorReturn(Exp.DIV_ARRAY_SCALAR(Exp.REAL()), realarrtypes, realtypes, 
          realarrtypes);
        /*(cache,userops) = getKoeningOperatorTypes(cache,"divide", env, t1, t2);*/
        types = Util.listFlatten({scalars,realarrscalar/*,userops*/});
      then
        (cache,types);
    case (cache,Absyn.POW(),env,t1,t2)
      equation 
        real_scalar = (Types.T_REAL({}),NONE) "The POW operator. a^b is only defined for integer exponents, i.e. b must
	  be of type Integer" ;
        int_scalar = (Types.T_INTEGER({}),NONE);
        real_vector = (Types.T_ARRAY(Types.DIM(NONE),real_scalar),NONE);
        real_matrix = (Types.T_ARRAY(Types.DIM(NONE),real_vector),NONE);
        real_pow = Exp.POW(Exp.REAL());
        int_pow = Exp.POW(Exp.INT());
        scalars = {(int_pow,{int_scalar,int_scalar},int_scalar),
          (real_pow,{real_scalar,real_scalar},real_scalar)};
        arrscalar = {
          (Exp.POW_ARR(Exp.REAL()),{real_matrix,int_scalar},
          real_matrix)};
        /*(cache,userops) = getKoeningOperatorTypes(cache,"power", env, t1, t2);*/
        types = Util.listFlatten({scalars,arrscalar/*,userops*/});
      then
        (cache,types);
    case (cache,Absyn.UMINUS(),env,t1,t2)
      equation 
        scalars = {
          (Exp.UMINUS(Exp.INT()),{(Types.T_INTEGER({}),NONE)},
          (Types.T_INTEGER({}),NONE)),
          (Exp.UMINUS(Exp.REAL()),{(Types.T_REAL({}),NONE)},
          (Types.T_REAL({}),NONE))} "The UMINUS operator, unary minus" ;
        intarrtypes = arrayTypeList(9, (Types.T_INTEGER({}),NONE));
        realarrtypes = arrayTypeList(9, (Types.T_REAL({}),NONE));
        intarrs = operatorReturnUnary(Exp.UMINUS_ARR(Exp.INT()), intarrtypes, intarrtypes);
        realarrs = operatorReturnUnary(Exp.UMINUS_ARR(Exp.REAL()), realarrtypes, realarrtypes);
        /*(cache,userops) = getKoeningOperatorTypes(cache,"unaryMinus", env, t1, t2);*/
        types = Util.listFlatten({scalars,intarrs,realarrs/*,userops*/});
      then
        (cache,types);
    case (cache,Absyn.UPLUS(),env,t1,t2)
      equation 
        scalars = {
          (Exp.UPLUS(Exp.INT()),{(Types.T_INTEGER({}),NONE)},
          (Types.T_INTEGER({}),NONE)),
          (Exp.UPLUS(Exp.REAL()),{(Types.T_REAL({}),NONE)},
          (Types.T_REAL({}),NONE))} "The UPLUS operator, unary plus." ;
        intarrtypes = arrayTypeList(9, (Types.T_INTEGER({}),NONE));
        realarrtypes = arrayTypeList(9, (Types.T_REAL({}),NONE));
        intarrs = operatorReturnUnary(Exp.UPLUS(Exp.INT()), intarrtypes, intarrtypes);
        realarrs = operatorReturnUnary(Exp.UPLUS(Exp.REAL()), realarrtypes, realarrtypes);
        /*(cache,userops) = getKoeningOperatorTypes(cache,"unaryPlus", env, t1, t2);*/
        types = Util.listFlatten({scalars,intarrs,realarrs/*,userops*/});
      then
        (cache,types);
    case (cache,Absyn.AND(),env,t1,t2) then (cache,{
          (Exp.AND(),
          {(Types.T_BOOL({}),NONE),(Types.T_BOOL({}),NONE)},(Types.T_BOOL({}),NONE))});  /* Logical operators Not considered for overloading yet. */ 
    case (cache,Absyn.OR(),env,t1,t2) then (cache,{
          (Exp.OR(),{(Types.T_BOOL({}),NONE),(Types.T_BOOL({}),NONE)},
          (Types.T_BOOL({}),NONE))}); 
    case (cache,Absyn.NOT(),env,t1,t2) then (cache,{
          (Exp.NOT(),{(Types.T_BOOL({}),NONE)},(Types.T_BOOL({}),NONE))}); 
    case (cache,Absyn.LESS(),env,t1,t2) /* Relational operators */ 
      equation 
        scalars = {
          (Exp.LESS(Exp.INT()),
          {(Types.T_INTEGER({}),NONE),(Types.T_INTEGER({}),NONE)},(Types.T_BOOL({}),NONE)),
          (Exp.LESS(Exp.REAL()),
          {(Types.T_REAL({}),NONE),(Types.T_REAL({}),NONE)},(Types.T_BOOL({}),NONE))} "\'<\' operator" ;
        /*(cache,userops) = getKoeningOperatorTypes(cache,"less", env, t1, t2);*/
        types = Util.listFlatten({scalars/*,userops*/});
      then
        (cache,types);
    case (cache,Absyn.LESSEQ(),env,t1,t2)
      equation 
        scalars = {
          (Exp.LESSEQ(Exp.INT()),
          {(Types.T_INTEGER({}),NONE),(Types.T_INTEGER({}),NONE)},(Types.T_BOOL({}),NONE)),
          (Exp.LESSEQ(Exp.REAL()),
          {(Types.T_REAL({}),NONE),(Types.T_REAL({}),NONE)},(Types.T_BOOL({}),NONE))} "\'<=\' operator" ;
        /*(cache,userops) = getKoeningOperatorTypes(cache,"lessEqual", env, t1, t2);*/
        types = Util.listFlatten({scalars/*,userops*/});
      then
        (cache,types);
    case (cache,Absyn.GREATER(),env,t1,t2)
      equation 
        scalars = {
          (Exp.GREATER(Exp.INT()),
          {(Types.T_INTEGER({}),NONE),(Types.T_INTEGER({}),NONE)},(Types.T_BOOL({}),NONE)),
          (Exp.GREATER(Exp.REAL()),
          {(Types.T_REAL({}),NONE),(Types.T_REAL({}),NONE)},(Types.T_BOOL({}),NONE))} "\'>\' operator" ;
        /*(cache,userops) = getKoeningOperatorTypes(cache,"greater", env, t1, t2);*/
        types = Util.listFlatten({scalars/*,userops*/});
      then
        (cache,types);
    case (cache,Absyn.GREATEREQ(),env,t1,t2)
      equation 
        scalars = {
          (Exp.GREATEREQ(Exp.INT()),
          {(Types.T_INTEGER({}),NONE),(Types.T_INTEGER({}),NONE)},(Types.T_BOOL({}),NONE)),
          (Exp.GREATEREQ(Exp.REAL()),
          {(Types.T_REAL({}),NONE),(Types.T_REAL({}),NONE)},(Types.T_BOOL({}),NONE))} "\'>=\' operator" ;
        /*(cache,userops) = getKoeningOperatorTypes(cache,"greaterEqual", env, t1, t2);*/
        types = Util.listFlatten({scalars/*,userops*/});
      then
        (cache,types);
    case (cache,Absyn.EQUAL(),env,t1,t2)
      equation 
        scalars = {
          (Exp.EQUAL(Exp.INT()),
          {(Types.T_INTEGER({}),NONE),(Types.T_INTEGER({}),NONE)},(Types.T_BOOL({}),NONE)),
          (Exp.EQUAL(Exp.REAL()),
          {(Types.T_REAL({}),NONE),(Types.T_REAL({}),NONE)},(Types.T_BOOL({}),NONE)),
          (Exp.EQUAL(Exp.STRING()),
          {(Types.T_STRING({}),NONE),(Types.T_STRING({}),NONE)},(Types.T_BOOL({}),NONE)),
          (Exp.EQUAL(Exp.BOOL()),
          {(Types.T_BOOL({}),NONE),(Types.T_BOOL({}),NONE)},(Types.T_BOOL({}),NONE))} "\'==\' operator" ;
        /*(cache,userops) = getKoeningOperatorTypes(cache,"equal", env, t1, t2);*/
        types = Util.listFlatten({scalars/*,userops*/});
      then
        (cache,types);
    case (cache,Absyn.NEQUAL(),env,t1,t2)
      equation 
        scalars = {
          (Exp.NEQUAL(Exp.INT()),
          {(Types.T_INTEGER({}),NONE),(Types.T_INTEGER({}),NONE)},(Types.T_BOOL({}),NONE)),
          (Exp.NEQUAL(Exp.REAL()),
          {(Types.T_REAL({}),NONE),(Types.T_REAL({}),NONE)},(Types.T_BOOL({}),NONE)),
          (Exp.NEQUAL(Exp.STRING()),
          {(Types.T_STRING({}),NONE),(Types.T_STRING({}),NONE)},(Types.T_BOOL({}),NONE)),
          (Exp.NEQUAL(Exp.BOOL()),
          {(Types.T_BOOL({}),NONE),(Types.T_BOOL({}),NONE)},(Types.T_BOOL({}),NONE))} "\'!=\' operator" ;
        /*(cache,userops) = getKoeningOperatorTypes(cache,"notEqual", env, t1, t2);*/
        types = Util.listFlatten({scalars/*,userops*/});
      then
        (cache,types);
    case (cache,op,env,t1,t2)
      equation 
        Debug.fprint("failtrace", "-operators failed, op: ");
        s = Dump.opSymbol(op);
        Debug.fprint("failtrace", s);
        Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end operators;

protected function getKoeningFunctionTypes "function: getKoeningFunctionTypes
 
  Used for userdefined function overloads.
  This function will search the types of the arguments for matching function definitions 
  corresponding to the koening C++ lookup rule.
  Question: What happens if we have A.foo(x,y)? Should we search for function A.foo in
  scope where type of x and y are defined? Or is it an error?
  See also: get_koening_operator_types
  Note: The reason for having two functions here is that operators and functions differs a lot.
  Operators have fixed no of arguments, functions can both have positional and named 
  arguments, etc. Perhaps these two could be unified. This would require major refactoring.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output list<Types.Type> outTypesTypeLst;
algorithm 
  (outCache,outTypesTypeLst):=
  matchcontinue (inCache,inEnv,inPath,inAbsynExpLst,inAbsynNamedArgLst,inBoolean)
    local
      tuple<Types.TType, Option<Absyn.Path>> t;
      Absyn.Path p1,fn;
      SCode.Class c;
      Env.Frame f,f_1;
      list<tuple<Types.TType, Option<Absyn.Path>>> typelist,typelist2,res;
      list<Env.Frame> env;
      Absyn.Exp e1,exp;
      list<Absyn.Exp> exps;
      list<Absyn.NamedArg> na;
      Boolean impl;
      Ident id,fnstr,str;
      Env.Cache cache;
    case (cache,env,(fn as Absyn.IDENT(name = _)),(e1 :: exps),na,impl) /* impl */ 
      equation 
        (cache,_,Types.PROP(t,_),_) = elabExp(cache,env, e1, impl, NONE,true);
        p1 = Types.getClassname(t);
        (cache,c,(f :: _)) = Lookup.lookupClass(cache,env, p1, false) "msg" ;
        (cache,_,(f_1 :: _)) = Lookup.lookupType(cache,{f}, fn, false) "To make sure the function is implicitly instantiated." ;
        (cache,typelist) = Lookup.lookupFunctionsInEnv(cache,{f_1}, fn);
        (cache,typelist2) = getKoeningFunctionTypes(cache,env, fn, exps, na, impl);
        res = listAppend(typelist, typelist2);
      then
        (cache,res);
    case (cache,env,(fn as Absyn.IDENT(name = _)),(e1 :: exps),na,impl)
      equation 
        (cache,typelist) = getKoeningFunctionTypes(cache,env, fn, exps, na, impl);
      then
        (cache,typelist);
    case (cache,env,(fn as Absyn.IDENT(name = _)),{},(Absyn.NAMEDARG(argName = id,argValue = exp) :: na),impl)
      equation 
        (cache,_,Types.PROP(t,_),_) = elabExp(cache,env, exp, impl, NONE,true);
        ((p1 as Absyn.QUALIFIED(_,_))) = Types.getClassname(t);
        (cache,c,(f :: _)) = Lookup.lookupClass(cache,env, p1, false);
        (cache,_,(f_1 :: _)) = Lookup.lookupType(cache,{f}, fn, false) "To make sure the function is implicitly instantiated." ;
        (cache,typelist) = Lookup.lookupFunctionsInEnv(cache,{f_1}, fn);
        (cache,typelist2) = getKoeningFunctionTypes(cache,env, fn, {}, na, impl);
        res = listAppend(typelist, typelist2);
      then
        (cache,res);
    case (cache,env,(fn as Absyn.IDENT(name = _)),{},(_ :: na),impl)
      equation 
        (cache,res) = getKoeningFunctionTypes(cache,env, fn, {}, na, impl);
      then
        (cache,res);
    case (cache,env,(fn as Absyn.IDENT(name = _)),{},{},impl) then (cache,{}); 
    case (cache,env,(fn as Absyn.QUALIFIED(name = _)),_,_,impl)
      equation 
        fnstr = Absyn.pathString(fn);
        str = stringAppend("koening lookup of non-simple function name ", fnstr);
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        fail();
  end matchcontinue;
end getKoeningFunctionTypes;

protected function getKoeningOperatorTypes "function: getKoeningOperatorTypes
 
  Used for userdefined operator overloads.
  This function will search the scopes of the classes of the two 
  corresponding types and look for user defined operator overloaded
  functions, such as \'plus\', \'minus\' and \'times\'. This corresponds
  to the koening C++ lookup rule.
"
	input Env.Cache inCache;
  input String inString1;
  input Env.Env inEnv2;
  input Types.Type inType3;
  input Types.Type inType4;
  output Env.Cache outCache;
  output list<tuple<Exp.Operator, list<Types.Type>, Types.Type>> outTplExpOperatorTypesTypeLstTypesTypeLst;
algorithm 
  (outCache,outTplExpOperatorTypesTypeLstTypesTypeLst) :=
  matchcontinue (inCache,inString1,inEnv2,inType3,inType4)
    local
      Absyn.Path p1,p2;
      SCode.Class c;
      list<Env.Frame> env1,env2,env;
      list<tuple<Exp.Operator, list<tuple<Types.TType, Option<Absyn.Path>>>, tuple<Types.TType, Option<Absyn.Path>>>> res1,res2,res;
      Ident op;
      tuple<Types.TType, Option<Absyn.Path>> t1,t2;
      Env.Cache cache;
      //NOTE: Koening operator disabled. Not part of Modelica yet.
      // When introduced in standard, remove case below.
      case (cache,op,env,t1,t2) then (cache,{});  
    case (cache,op,env,t1,t2)
      equation 
        ((p1 as Absyn.QUALIFIED(_,_))) = Types.getClassname(t1) "Both types user defined" ;
        (cache,c,env1) = Lookup.lookupClass(cache,env, p1, false);
        (cache,res1) = getKoeningOperatorTypesInScope(cache,op, env1);
        ((p2 as Absyn.QUALIFIED(_,_))) = Types.getClassname(t2);
        (cache,c,env2) = Lookup.lookupClass(cache,env, p2, false);
        (cache,res2) = getKoeningOperatorTypesInScope(cache,op, env2);
        res = listAppend(res1, res2);
      then
        (cache,res);
    case (cache,op,env,t1,t2)
      equation 
        failure(Absyn.QUALIFIED(_,_) = Types.getClassname(t1)) "User defined types only in t2" ;
        ((p2 as Absyn.QUALIFIED(_,_))) = Types.getClassname(t2);
        (cache,c,env2) = Lookup.lookupClass(cache,env, p2, false);
        (cache,res) = getKoeningOperatorTypesInScope(cache,op, env2);
      then
        (cache,res);
    case (cache,op,env,t1,t2)
      equation 
        failure(Absyn.QUALIFIED(_,_) = Types.getClassname(t2)) "User defined types only in t1" ;
        ((p1 as Absyn.QUALIFIED(_,_))) = Types.getClassname(t1);
        (cache,c,env1) = Lookup.lookupClass(cache,env, p1, false);
        (cache,res) = getKoeningOperatorTypesInScope(cache,op, env1);
      then
        (cache,res);
    case (cache,op,env,t1,t2)
      equation 
        failure(Absyn.QUALIFIED(_,_) = Types.getClassname(t1)) "No User defined types at all." ;
        failure(Absyn.QUALIFIED(_,_) = Types.getClassname(t2));
      then
        (cache,{});
    case (cache,op,env,t1,t2) then (cache,{}); 
  end matchcontinue;
end getKoeningOperatorTypes;

protected function getKoeningOperatorTypesInScope "function: getKoeningOperatorTypesInScope
 
  This function is a help function to get_koening_operator_types
  and it will look for functions in the current scope of the passed
  environment, according to the koening rule. 
"
	input Env.Cache inCache;
  input String inString;
  input Env.Env inEnv;
  output Env.Cache outCache;
  output list<tuple<Exp.Operator, list<Types.Type>, Types.Type>> outTplExpOperatorTypesTypeLstTypesTypeLst;
algorithm 
  (outCache,outTplExpOperatorTypesTypeLstTypesTypeLst) :=
  matchcontinue (inCache,inString,inEnv)
    local
      Env.Frame f_1,f;
      list<tuple<Types.TType, Option<Absyn.Path>>> tplst;
      Integer tplen;
      Absyn.Path fullfuncname;
      list<tuple<Exp.Operator, list<tuple<Types.TType, Option<Absyn.Path>>>, tuple<Types.TType, Option<Absyn.Path>>>> res;
      Ident funcname;
      list<Env.Frame> fs;
      Env.Cache cache;
    case (cache,funcname,(f :: fs))
      equation 
        (cache,_,(f_1 :: _)) = Lookup.lookupType(cache,{f}, Absyn.IDENT(funcname), false) "To make sure the function is implicitly instantiated." ;
        (cache,tplst) = Lookup.lookupFunctionsInEnv(cache,{f_1}, Absyn.IDENT(funcname)) "TODO: Fix so lookup_functions_in_env also does instantiation to get type" ;
        tplen = listLength(tplst);
        (cache,fullfuncname) = Inst.makeFullyQualified(cache,(f_1 :: fs), Absyn.IDENT(funcname));
        res = buildOperatorTypes(tplst, fullfuncname);
      then
        (cache,res);
  end matchcontinue;
end getKoeningOperatorTypesInScope;

protected function buildOperatorTypes "function: buildOperatorTypes
 
  This function takes the types operator overloaded user functions and
  builds  the type list structure suitable for the deoverload function. 
"
  input list<Types.Type> inTypesTypeLst;
  input Absyn.Path inPath;
  output list<tuple<Exp.Operator, list<Types.Type>, Types.Type>> outTplExpOperatorTypesTypeLstTypesTypeLst;
algorithm 
  outTplExpOperatorTypesTypeLstTypesTypeLst:=
  matchcontinue (inTypesTypeLst,inPath)
    local
      list<tuple<Types.TType, Option<Absyn.Path>>> argtypes,tps;
      list<tuple<Exp.Operator, list<tuple<Types.TType, Option<Absyn.Path>>>, tuple<Types.TType, Option<Absyn.Path>>>> rest;
      list<tuple<Ident, tuple<Types.TType, Option<Absyn.Path>>>> args;
      tuple<Types.TType, Option<Absyn.Path>> tp;
      Absyn.Path funcname;
    case ({},_) then {}; 
    case (((Types.T_FUNCTION(funcArg = args,funcResultType = tp),_) :: tps),funcname)
      equation 
        argtypes = Util.listMap(args, Util.tuple22);
        rest = buildOperatorTypes(tps, funcname);
      then
        ((Exp.USERDEFINED(funcname),argtypes,tp) :: rest);
  end matchcontinue;
end buildOperatorTypes;

protected function nDimArray "function: nDimArray
  Returns a type based on the type given as input but as an array type with
  n dimensions.
"
  input Integer inInteger;
  input Types.Type inType;
  output Types.Type outType;
algorithm 
  outType:=
  matchcontinue (inInteger,inType)
    local
      tuple<Types.TType, Option<Absyn.Path>> t,t_1;
      Integer n_1,n;
    case (0,t) then t;  /* n orig type array type of n dimensions with element type = orig type */ 
    case (n,t)
      equation 
        n_1 = n - 1;
        t_1 = nDimArray(n_1, t);
      then
        ((Types.T_ARRAY(Types.DIM(NONE),t_1),NONE));
  end matchcontinue;
end nDimArray;

protected function nTypes "function: nTypes
  Creates n copies of the type type.
  This could instead be accomplished with Util.list_fill...
"
  input Integer inInteger;
  input Types.Type inType;
  output list<Types.Type> outTypesTypeLst;
algorithm 
  outTypesTypeLst:=
  matchcontinue (inInteger,inType)
    local
      Integer n_1,n;
      list<tuple<Types.TType, Option<Absyn.Path>>> l;
      tuple<Types.TType, Option<Absyn.Path>> t;
    case (0,_) then {}; 
    case (n,t)
      equation 
        n_1 = n - 1;
        l = nTypes(n_1, t);
      then
        (t :: l);
  end matchcontinue;
end nTypes;

protected function operatorReturn "function: operatorReturn
  This function collects the types and operator lists into a tuple list, suitable
  for the deoverloading function for binary operations.
"
  input Exp.Operator inOperator1;
  input list<Types.Type> inTypesTypeLst2;
  input list<Types.Type> inTypesTypeLst3;
  input list<Types.Type> inTypesTypeLst4;
  output list<tuple<Exp.Operator, list<Types.Type>, Types.Type>> outTplExpOperatorTypesTypeLstTypesTypeLst;
algorithm 
  outTplExpOperatorTypesTypeLstTypesTypeLst:=
  matchcontinue (inOperator1,inTypesTypeLst2,inTypesTypeLst3,inTypesTypeLst4)
    local
      list<tuple<Exp.Operator, list<tuple<Types.TType, Option<Absyn.Path>>>, tuple<Types.TType, Option<Absyn.Path>>>> rest;
      tuple<Exp.Operator, list<tuple<Types.TType, Option<Absyn.Path>>>, tuple<Types.TType, Option<Absyn.Path>>> t;
      Exp.Operator op;
      tuple<Types.TType, Option<Absyn.Path>> l,r,re;
      list<tuple<Types.TType, Option<Absyn.Path>>> lr,rr,rer;
    case (_,{},{},{}) then {}; 
    case (op,(l :: lr),(r :: rr),(re :: rer))
      equation 
        rest = operatorReturn(op, lr, rr, rer);
        t = (op,{l,r},re) "list contains two types, i.e. BINARY operations" ;
      then
        (t :: rest);
  end matchcontinue;
end operatorReturn;

protected function operatorReturnUnary "function: operatorReturnUnary
  This function collects the types and operator lists into a tuple list, 
  suitable for the deoverloading function to be used for unary 
  expressions.
"
  input Exp.Operator inOperator1;
  input list<Types.Type> inTypesTypeLst2;
  input list<Types.Type> inTypesTypeLst3;
  output list<tuple<Exp.Operator, list<Types.Type>, Types.Type>> outTplExpOperatorTypesTypeLstTypesTypeLst;
algorithm 
  outTplExpOperatorTypesTypeLstTypesTypeLst:=
  matchcontinue (inOperator1,inTypesTypeLst2,inTypesTypeLst3)
    local
      list<tuple<Exp.Operator, list<tuple<Types.TType, Option<Absyn.Path>>>, tuple<Types.TType, Option<Absyn.Path>>>> rest;
      tuple<Exp.Operator, list<tuple<Types.TType, Option<Absyn.Path>>>, tuple<Types.TType, Option<Absyn.Path>>> t;
      Exp.Operator op;
      tuple<Types.TType, Option<Absyn.Path>> l,re;
      list<tuple<Types.TType, Option<Absyn.Path>>> lr,rer;
    case (_,{},{}) then {}; 
    case (op,(l :: lr),(re :: rer))
      equation 
        rest = operatorReturnUnary(op, lr, rer);
        t = (op,{l},re) "list only contains one type, i.e. for UNARY operations" ;
      then
        (t :: rest);
  end matchcontinue;
end operatorReturnUnary;

protected function arrayTypeList "function: arrayTypeList
  This function creates a list of types using the original type passed as input, but 
  as array types up to n dimensions.
"
  input Integer inInteger;
  input Types.Type inType;
  output list<Types.Type> outTypesTypeLst;
algorithm 
  outTypesTypeLst:=
  matchcontinue (inInteger,inType)
    local
      Integer n_1,n;
      tuple<Types.TType, Option<Absyn.Path>> f,t;
      list<tuple<Types.TType, Option<Absyn.Path>>> r;
    case (0,_) then {};  /* n orig type array types */ 
    case (n,t)
      equation 
        n_1 = n - 1;
        f = nDimArray(n, t);
        r = arrayTypeList(n_1, t);
      then
        (f :: r);
  end matchcontinue;
end arrayTypeList;
end Static;

