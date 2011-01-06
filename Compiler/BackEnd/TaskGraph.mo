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

package TaskGraph
" file:	       TaskGraph.mo
  package:     TaskGraph
  description: Building of task graphs from expressions, and equation systems.

  RCS: $Id$

  This module is used in the modpar part of OpenModelica for bulding task graphs
  from the BLT decomposition for automatic parallelization.
  The exported function buildTaskgraph takes the lowered form of the DAE defined in
  BackendDAE and two assignments vectors (which variable is solved in which equation) and
  the list of blocks given by the BLT decomposition.

  The package uses TaskGraphExt for the task graph datastructure itself, which
  is implemented using Boost Graph Library in C++"

public import BackendDAE;
public import SCode;

protected import Absyn;
protected import BackendDAEUtil;
protected import BackendVariable;
protected import ComponentReference;
protected import DAE;
protected import DAEUtil;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSolve;
protected import TaskGraphExt;
protected import Util;
protected import Values;
protected import ValuesUtil;
protected import VarTransform;

public function buildTaskgraph ""
  input BackendDAE.BackendDAE inBackendDAE1;
  input array<Integer> inIntegerArray2;
  input array<Integer> inIntegerArray3;
  input list<list<Integer>> inIntegerLstLst4;
algorithm
  _ := matchcontinue (inBackendDAE1,inIntegerArray2,inIntegerArray3,inIntegerLstLst4)
    local
      Integer starttask,endtask;
      list<BackendDAE.Var> vars,knvars;
      BackendDAE.BackendDAE dae;
      BackendDAE.VariableArray vararr,knvararr;
      array<Integer> ass1,ass2;
      list<list<Integer>> blocks;
      DAE.ComponentRef cref_;

    case ((dae as BackendDAE.DAE(orderedVars = BackendDAE.VARIABLES(varArr = vararr),knownVars = BackendDAE.VARIABLES(varArr = knvararr))),ass1,ass2,blocks)
      equation
        print("starting buildtaskgraph\n");
        starttask = TaskGraphExt.newTask("start");
        endtask = TaskGraphExt.newTask("end");
        TaskGraphExt.setExecCost(starttask, 1.0);
        TaskGraphExt.setExecCost(starttask, 1.0);
        TaskGraphExt.registerStartStop(starttask, endtask);
        vars = BackendDAEUtil.vararrayList(vararr);
        knvars = BackendDAEUtil.vararrayList(knvararr);
        addVariables(vars, starttask);
        addVariables(knvars, starttask);
        cref_ = ComponentReference.makeCrefIdent("sim_time",DAE.ET_REAL(),{});
        addVariables({BackendDAE.VAR(cref_,BackendDAE.VARIABLE(),
                      DAE.INPUT(),BackendDAE.REAL(),NONE(),NONE(),{},0,DAE.emptyElementSource,NONE(),
                      NONE(),DAE.NON_CONNECTOR(),DAE.NON_STREAM())}, starttask);
        buildBlocks(dae, ass1, ass2, blocks);
        print("done building taskgraph, about to build inits.\n");
        buildInits(dae);
        print("leaving TaskGraph.buildTaskgraph\n");
      then
        ();

    case (_,_,_,_)
      equation
        print("-TaskGraph.buildTaskgraph failed\n");
      then
        fail();
  end matchcontinue;
end buildTaskgraph;

protected function buildInits "function: buildInits
  This function traverses the DAE and calls external functions to build
  the initialization values for the DAE
  This is implemented in C++ as a set of vectors"
  input BackendDAE.BackendDAE inBackendDAE;
algorithm
  _ := match (inBackendDAE)
    local
      list<BackendDAE.Var> vars,kvars;
      BackendDAE.VariableArray vararr,kvararr;
    case (BackendDAE.DAE(orderedVars = BackendDAE.VARIABLES(varArr = vararr),knownVars = BackendDAE.VARIABLES(varArr = kvararr)))
      equation
        vars = BackendDAEUtil.vararrayList(vararr);
        kvars = BackendDAEUtil.vararrayList(kvararr);
        buildInits2(vars);
        buildInits2(kvars);
      then
        ();
  end match;
end buildInits;

protected function buildInits2
  input list<BackendDAE.Var> inBackendDAEVarLst;
algorithm
  _ := matchcontinue (inBackendDAEVarLst)
    local
      String v,origname_str;
      Integer indx;
      DAE.ComponentRef origname;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      list<BackendDAE.Var> rest;
      DAE.Exp e;
      Values.Value value;
    case ({}) then ();
    case ((BackendDAE.VAR(varKind = BackendDAE.VARIABLE(),index = indx,varName = origname,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: rest))
      equation
        e = DAEUtil.getStartAttr(dae_var_attr);
        v = ExpressionDump.printExpStr(e);
        origname_str = ComponentReference.printComponentRefStr(origname);
        TaskGraphExt.addInitVar(indx, v, origname_str);
        buildInits2(rest);
      then
        ();
    case ((BackendDAE.VAR(varKind = BackendDAE.VARIABLE(),index = indx,varName = origname,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: rest))
      equation
        origname_str = ComponentReference.printComponentRefStr(origname);
        TaskGraphExt.addInitVar(indx, "0.0", origname_str);
        buildInits2(rest);
      then
        ();
    case ((BackendDAE.VAR(varKind = BackendDAE.STATE(),index = indx,varName = origname,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: rest))
      equation
        e = DAEUtil.getStartAttr(dae_var_attr);
        v = ExpressionDump.printExpStr(e);
        origname_str = ComponentReference.printComponentRefStr(origname);
        TaskGraphExt.addInitState(indx, v, origname_str);
        buildInits2(rest);
      then
        ();
    case ((BackendDAE.VAR(varKind = BackendDAE.STATE(),index = indx,varName = origname,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: rest))
      equation
        origname_str = ComponentReference.printComponentRefStr(origname);
        TaskGraphExt.addInitState(indx, "0.0", origname_str);
        buildInits2(rest);
      then
        ();
    case ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER(),index = indx,varName = origname,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: rest))
      equation
        e = DAEUtil.getStartAttr(dae_var_attr);
        v = ExpressionDump.printExpStr(e);
        origname_str = ComponentReference.printComponentRefStr(origname);
        TaskGraphExt.addInitVar(indx, v, origname_str);
        buildInits2(rest);
      then
        ();
    case ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER(),index = indx,varName = origname,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: rest))
      equation
        origname_str = ComponentReference.printComponentRefStr(origname);
        TaskGraphExt.addInitVar(indx, "0.0", origname_str);
        buildInits2(rest);
      then
        ();
    case ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE(),index = indx,varName = origname,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: rest))
      equation
        e = DAEUtil.getStartAttr(dae_var_attr);
        v = ExpressionDump.printExpStr(e);
        origname_str = ComponentReference.printComponentRefStr(origname);
        TaskGraphExt.addInitVar(indx, v, origname_str);
        buildInits2(rest);
      then
        ();
    case ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE(),index = indx,varName = origname,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: rest))
      equation
        origname_str = ComponentReference.printComponentRefStr(origname);
        TaskGraphExt.addInitVar(indx, "0.0", origname_str);
        buildInits2(rest);
      then
        ();
    case ((BackendDAE.VAR(varKind = BackendDAE.PARAM(),bindValue = SOME(value),index = indx,varName = origname,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: rest))
      equation
        v = ValuesUtil.valString(value);
        origname_str = ComponentReference.printComponentRefStr(origname);
        TaskGraphExt.addInitParam(indx, v, origname_str);
        buildInits2(rest);
      then
        ();
    case ((BackendDAE.VAR(varKind = BackendDAE.PARAM(),bindValue = NONE(),index = indx,varName = origname,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: rest))
      equation
        origname_str = ComponentReference.printComponentRefStr(origname);
        TaskGraphExt.addInitParam(indx, "0.0", origname_str);
        buildInits2(rest);
      then
        ();
    case ((BackendDAE.VAR(varKind = BackendDAE.CONST(),bindValue = SOME(value),index = indx,varName = origname,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: rest))
      equation
        v = ValuesUtil.valString(value);
        origname_str = ComponentReference.printComponentRefStr(origname);
        TaskGraphExt.addInitParam(indx, v, origname_str);
        buildInits2(rest);
      then
        ();
    case ((BackendDAE.VAR(varKind = BackendDAE.CONST(),bindValue = NONE(),index = indx,varName = origname,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: rest))
      equation
        origname_str = ComponentReference.printComponentRefStr(origname);
        TaskGraphExt.addInitParam(indx, "0.0", origname_str);
        buildInits2(rest);
      then
        ();
  end matchcontinue;
end buildInits2;

protected function addVariables
  input list<BackendDAE.Var> inBackendDAEVarLst;
  input Integer inInteger;
algorithm
  _:=
  match (inBackendDAEVarLst,inInteger)
    local
      Integer start;
      BackendDAE.Var v;
      list<BackendDAE.Var> vs;
    case ({},start) then ();
    case ((v :: vs),start)
      equation
        addVariable(v, start);
        addVariables(vs, start);
      then
        ();
  end match;
end addVariables;

protected function buildBlocks
  input BackendDAE.BackendDAE inBackendDAE1;
  input array<Integer> inIntegerArray2;
  input array<Integer> inIntegerArray3;
  input list<list<Integer>> inIntegerLstLst4;
algorithm
  _:=
  matchcontinue (inBackendDAE1,inIntegerArray2,inIntegerArray3,inIntegerLstLst4)
    local
      BackendDAE.BackendDAE dae;
      array<Integer> ass1,ass2;
      list<Integer> block_;
      list<list<Integer>> blocks;
      Integer eqn;
    case (_,_,_,{}) then ();
    case (dae,ass1,ass2,((block_ as (_ :: (_ :: _))) :: blocks))
      equation
        buildSystem(dae, ass1, ass2, block_) "For system of equations" ;
        buildBlocks(dae, ass1, ass2, blocks);
      then
        ();
    case (dae,ass1,ass2,((block_ as {eqn}) :: blocks))
      equation
        buildEquation(dae, ass1, ass2, eqn) "for single equations" ;
        buildBlocks(dae, ass1, ass2, blocks);
      then
        ();
    case (_,_,_,_)
      equation
        print("-build_blocks failed\n");
      then
        fail();
  end matchcontinue;
end buildBlocks;

protected function buildEquation "Build task graph for a single equation."
  input BackendDAE.BackendDAE inBackendDAE1;
  input array<Integer> inIntegerArray2;
  input array<Integer> inIntegerArray3;
  input Integer inInteger4;
algorithm
  _:=
  matchcontinue (inBackendDAE1,inIntegerArray2,inIntegerArray3,inInteger4)
    local
      Integer e_1,i,v_1,e,indx;
      DAE.Exp e1,e2,varexp,expr;
      BackendDAE.Var v;
      list<BackendDAE.Var> varlst;
      DAE.ComponentRef cr,cr_1;
      BackendDAE.VarKind kind;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      String origname_str,indxs,name,c_name,id;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      array<Integer> ass1,ass2;
    case (BackendDAE.DAE(orderedVars = vars,orderedEqs = eqns),ass1,ass2,e)
      equation
        e_1 = e - 1 "Solving for non-states" ;
        BackendDAE.EQUATION(e1,e2,_) = BackendDAEUtil.equationNth(eqns, e_1);
        v_1 = ass2[e_1 + 1] - 1 "v == variable no solved in this equation" ;
        varlst = BackendDAEUtil.varList(vars);
        ((v as BackendDAE.VAR(cr,kind,_,_,_,_,_,_,_,dae_var_attr,comment,flowPrefix,streamPrefix))) = listNth(varlst, v_1);
        origname_str = ComponentReference.printComponentRefStr(cr);
        true = BackendVariable.isNonStateVar(v);
        varexp = Expression.crefExp(cr) "print \"Solving for non-states\\n\" &" ;
        (expr,{}) = ExpressionSolve.solve(e1, e2, varexp);
        buildAssignment(cr, expr, origname_str) "	Expression.print_exp_str e1 => e1s &
	Expression.print_exp_str e2 => e2s &
	print \"Equation \" & print e1s & print \" = \" & print e2s &
	print \" solved for \" & Expression.print_exp_str varexp => s &
	print s & print \" giving \" &
	Expression.print_exp_str expr => s2 & print s2 & print \"\\n\" &" ;
      then
        ();
    case (BackendDAE.DAE(orderedVars = vars,orderedEqs = eqns),ass1,ass2,e)
      equation
        e_1 = e - 1 "Solving the state s means solving for der(s)" ;
        BackendDAE.EQUATION(e1,e2,_) = BackendDAEUtil.equationNth(eqns, e_1);
        i = ass2[e_1 + 1];
        v_1 = i - 1 "i == variable no solved in this equation" ;
        varlst = BackendDAEUtil.varList(vars);
        BackendDAE.VAR(cr,BackendDAE.STATE(),_,_,_,_,_,indx,_,dae_var_attr,comment,flowPrefix,streamPrefix) = listNth(varlst, v_1);
        indxs = intString(indx) "	print \"solving for state\\n\" &" ;
        origname_str = ComponentReference.printComponentRefStr(cr);
        name = ComponentReference.printComponentRefStr(cr) "	Util.string_append_list({\"xd{\",indxs,\"}\"}) => id &" ;
        //c_name = Util.modelicaStringToCStr(name,true);
        c_name = name;
        //id = stringAppendList({BackendDAE.derivativeNamePrefix,c_name});
        id = c_name;
        cr_1 = ComponentReference.makeCrefIdent(id,DAE.ET_REAL(),{});
        varexp = Expression.crefExp(cr_1);
        (expr,{}) = ExpressionSolve.solve(e1, e2, varexp);
        buildAssignment(cr_1, expr, origname_str) "	Expression.print_exp_str e1 => e1s &
	Expression.print_exp_str e2 => e2s &
	print \"Equation \" & print e1s & print \" = \" & print e2s &
	print \"solved for \" & Expression.print_exp_str varexp => s &
	print s & print \"giving \" &
	Expression.print_exp_str expr => s2 & print s2 & print \"\\n\" &" ;
      then
        ();
    case (BackendDAE.DAE(orderedVars = vars,orderedEqs = eqns),ass1,ass2,e) /* rule	intSub(e,1) => e\' &
	BackendDAE.equation_nth(eqns,e\') => BackendDAE.EQUATION(e1,e2,_) &
	vector_nth(ass2,e\') => v & ( v==variable no solved in this equation ))
	intSub(v,1) => v\' &
	BackendDAE.vararray_nth(vararr,v\') => BackendDAE.VAR(cr,_,_,_,_,_,_,_,_,origname,_,dae_var_attr,comment,flow) &
	let varexp = Expression.crefExp(cr) &
	not ExpressionSolve.solve(e1,e2,varexp) => _ &
	print \"nonlinear equation not implemented yet\\n\"
	--------------------------------
	build_equation(BackendDAE.DAE(BackendDAE.VARIABLES(_,_,vararr,_,_),_,eqns,_,_,_,_,_),ass1,ass2,e) => fail
 */
      equation
        e_1 = e - 1 "state nonlinear" ;
        BackendDAE.EQUATION(e1,e2,_) = BackendDAEUtil.equationNth(eqns, e_1);
        i = ass2[e_1 + 1];
        v_1 = i - 1 "i == variable no solved in this equation" ;
        varlst = BackendDAEUtil.varList(vars);
        BackendDAE.VAR(cr,BackendDAE.STATE(),_,_,_,_,_,indx,_,dae_var_attr,_,flowPrefix,streamPrefix) = listNth(varlst, v_1);
        indxs = intString(indx);
        name = ComponentReference.printComponentRefStr(cr) "	Util.string_append_list({\"xd{\",indxs,\"}\"}) => id &" ;
        //c_name = Util.modelicaStringToCStr(name,true);
        c_name = name;
        //id = stringAppendList({BackendDAE.derivativeNamePrefix,c_name});
        id = c_name;
        cr_1 = ComponentReference.makeCrefIdent(id,DAE.ET_REAL(),{});
        varexp = Expression.crefExp(cr_1);
        failure((_,_) = ExpressionSolve.solve(e1, e2, varexp));
        buildNonlinearEquations({varexp}, {DAE.BINARY(e1,DAE.SUB(DAE.ET_REAL()),e2)});
      then
        ();
    case (BackendDAE.DAE(orderedVars = vars,orderedEqs = eqns),ass1,ass2,e)
      equation
        e_1 = e - 1 "Solving nonlinear for non-states" ;
        BackendDAE.EQUATION(e1,e2,_) = BackendDAEUtil.equationNth(eqns, e_1);
        i = ass2[e_1 + 1];
        v_1 = i - 1 "v == variable no solved in this equation" ;
        varlst = BackendDAEUtil.varList(vars);
        ((v as BackendDAE.VAR(cr,kind,_,_,_,_,_,_,_,dae_var_attr,comment,flowPrefix,streamPrefix))) = listNth(varlst, v_1);
        true = BackendVariable.isNonStateVar(v);
        varexp = Expression.crefExp(cr) "print \"Solving for non-states\\n\" &" ;
        failure((_,_) = ExpressionSolve.solve(e1, e2, varexp));
        buildNonlinearEquations({varexp}, {DAE.BINARY(e1,DAE.SUB(DAE.ET_REAL()),e2)});
      then
        ();
    case (_,_,_,_)
      equation
        print("-TaskGraph.buildEquation failed\n");
      then
        fail();
  end matchcontinue;
end buildEquation;

protected function buildNonlinearEquations "function: buildNonlinearEquations
  builds task graph for solving non-linear equations
"
  input list<DAE.Exp> inExpExpLst1;
  input list<DAE.Exp> inExpExpLst2;
algorithm
  _:=
  matchcontinue (inExpExpLst1,inExpExpLst2)
    local
      Integer size,tid;
      String size_str,taskname;
      list<String> varnames;
      list<DAE.Exp> vars,residuals;
    case (vars,residuals) /* variables residuals */
      equation
        size = listLength(vars);
        size_str = intString(size);
        taskname = buildResidualCode(vars, residuals);
        tid = TaskGraphExt.newTask(taskname);
        TaskGraphExt.setTaskType(tid, 3);
        buildNonlinearEquations2(tid, vars, residuals) "See TaskType in TaskGraph.hpp" ;
        varnames = Util.listMap(vars, ExpressionDump.printExpStr);
        storeMultipleResults(varnames, tid);
      then
        ();
    case (vars,residuals)
      equation
        print("build_nonlinear_equatins failed\n");
      then
        fail();
  end matchcontinue;
end buildNonlinearEquations;

protected function buildResidualCode "function: buildResidualCode
  This function takes a list of expressions and builds code for
  calculating the residuals as a string. Used for e.g. solving non-linear equations.
"
  input list<DAE.Exp> inExpExpLst1;
  input list<DAE.Exp> inExpExpLst2;
  output String outString;
algorithm
  outString:=
  matchcontinue (inExpExpLst1,inExpExpLst2)
    local
      VarTransform.VariableReplacements repl;
      String res;
      list<DAE.Exp> vars,es;
    case (vars,es) /* vars residuals */
      equation
        repl = makeResidualReplacements(vars);
        res = buildResidualCode2(es, 0, repl);
      then
        res;
    case (_,_)
      equation
        print("build_residual_code failed\n");
      then
        fail();
  end matchcontinue;
end buildResidualCode;

protected function makeResidualReplacements "function: makeResidualReplacements
  This function makes replacement rules for variables occuring in a
  nonlinear equation system. They should be replaced by x{index}, i.e.
  an unique index in the x vector.
"
  input list<DAE.Exp> expl;
  output VarTransform.VariableReplacements repl_1;
  VarTransform.VariableReplacements repl;
algorithm
  repl := VarTransform.emptyReplacements();
  repl_1 := makeResidualReplacements2(repl, expl, 0);
end makeResidualReplacements;

protected function makeResidualReplacements2
  input VarTransform.VariableReplacements inVariableReplacements;
  input list<DAE.Exp> inExpExpLst;
  input Integer inInteger;
  output VarTransform.VariableReplacements outVariableReplacements;
algorithm
  outVariableReplacements:=
  match (inVariableReplacements,inExpExpLst,inInteger)
    local
      VarTransform.VariableReplacements repl,repl_1,repl_2;
      String pstr,str;
      Integer pos_1,pos;
      DAE.ComponentRef cr,cref_;
      list<DAE.Exp> es;
    case (repl,{},_) then repl;
    case (repl,(DAE.CREF(componentRef = cr) :: es),pos)
      equation
        pstr = intString(pos);
        str = stringAppendList({"xloc[",pstr,"]"});
        cref_ = ComponentReference.makeCrefIdent(str,DAE.ET_REAL(),{});
        repl_1 = VarTransform.addReplacement(repl, cr, Expression.crefExp(cref_));
        pos_1 = pos + 1;
        repl_2 = makeResidualReplacements2(repl_1, es, pos_1);
      then
        repl_2;
  end match;
end makeResidualReplacements2;

protected function buildResidualCode2
  input list<DAE.Exp> inExpExpLst;
  input Integer inInteger;
  input VarTransform.VariableReplacements inVariableReplacements;
  output String outString;
algorithm
  outString:=
  matchcontinue (inExpExpLst,inInteger,inVariableReplacements)
    local
      DAE.Exp e_1,e;
      String s1,s2,pstr,res;
      Integer pos_1,pos;
      list<DAE.Exp> es;
      VarTransform.VariableReplacements repl;
    case ({},_,_) then "";
    case ((e :: es),pos,repl)
      equation
        e_1 = VarTransform.replaceExp(e, repl,NONE());
        //s1 = SimCodegen.printExpCppStr(e_1);
        s1 = "NOT WORKING";
        pos_1 = pos + 1;
        s2 = buildResidualCode2(es, pos_1, repl);
        pstr = intString(pos);
        res = stringAppendList({"res[",pstr,"]=",s1,";\n",s2});
      then
        res;
    case (_,_,_)
      equation
        print("build_residual_code2 failed\n");
      then
        fail();
  end matchcontinue;
end buildResidualCode2;

protected function storeMultipleResults "function storeMultipleResults
  When a task calculates several values, this function is used.
  It collects the names of the values into one string, separated by semicolons
  and uses that as the resultstring.
"
  input list<String> inStringLst;
  input Integer inInteger;
algorithm
  _:=
  matchcontinue (inStringLst,inInteger)
    local
      String result_str;
      list<String> varnames;
      Integer tid;
    case (varnames,tid) /* var names task id */
      equation
        result_str = Util.stringDelimitList(varnames, ";");
        TaskGraphExt.storeResult(result_str, tid, true, result_str);
      then
        ();
    case (_,_)
      equation
        print("store_multiple_results failed\n");
      then
        fail();
  end matchcontinue;
end storeMultipleResults;

protected function buildNonlinearEquations2
  input Integer inInteger1;
  input list<DAE.Exp> inExpExpLst2;
  input list<DAE.Exp> inExpExpLst3;
algorithm
  _:=
  matchcontinue (inInteger1,inExpExpLst2,inExpExpLst3)
    local
      Integer tid;
      list<DAE.ComponentRef> vars1,vars2,vars1_1,varslst;
      list<list<DAE.ComponentRef>> vars_1;
      DAE.Exp res,e;
      list<DAE.Exp> residuals,vars;
      String es;
    case (tid,_,{}) then ();  /* task id vars residuals */
    case (tid,vars,(res :: residuals))
      equation
        vars1 = Expression.extractCrefsFromExp(res) "Collect all variables and construct
	 a string for the residual, that can be directly used in codegen." ;
        vars_1 = Util.listMap(vars, Expression.extractCrefsFromExp);
        vars2 = Util.listFlatten(vars_1);
        vars1_1 = Util.listUnionOnTrue(vars1, vars2, ComponentReference.crefEqual) "No duplicate elements" ;
        varslst = Util.listSetDifferenceOnTrue(vars1_1, vars2, ComponentReference.crefEqual);
        addEdgesFromVars(varslst, tid, 0);
      then
        ();
    case (_,_,(e :: _))
      equation
        print("build_nonlinear_equations2 failed\n");
        es = ExpressionDump.printExpStr(e);
        print("first residual :");
        print(es);
        print("\n");
      then
        fail();
  end matchcontinue;
end buildNonlinearEquations2;

protected function addEdgesFromVars "function: addEdgesFromVars
  Adds an edge between the tasks where the variables are defined and the tasks
  given as second argument.
"
  input list<DAE.ComponentRef> inExpComponentRefLst1;
  input Integer inInteger2;
  input Integer inInteger3;
algorithm
  _:=
  matchcontinue (inExpComponentRefLst1,inInteger2,inInteger3)
    local
      String v_str;
      Integer predt,prio_1,tid,prio;
      DAE.ComponentRef v;
      list<DAE.ComponentRef> vs;
    case ({},_,_) then ();  /* task priority */
    case ((v :: vs),tid,prio)
      equation
        v_str = ComponentReference.crefStr(v);
        predt = TaskGraphExt.getTask(v_str);
        TaskGraphExt.addEdge(predt, tid, v_str, prio);
        prio_1 = prio + 1;
        addEdgesFromVars(vs, tid, prio_1);
      then
        ();
    case ((v :: vs),_,_)
      equation
        v_str = ComponentReference.crefStr(v);
        failure(_ = TaskGraphExt.getTask(v_str));
        print("task ");
        print(v_str);
        print(" not found\n");
      then
        fail();
    case (_,_,_)
      equation
        print("add_edges_from_vars failed\n");
      then
        fail();
  end matchcontinue;
end addEdgesFromVars;

protected function buildSystem "Build task graph for a system of equations"
  input BackendDAE.BackendDAE inBackendDAE1;
  input array<Integer> inIntegerArray2;
  input array<Integer> inIntegerArray3;
  input list<Integer> inIntegerLst4;
algorithm
  _:=
  matchcontinue (inBackendDAE1,inIntegerArray2,inIntegerArray3,inIntegerLst4)
    local
      Integer tid;
      list<String> predtasks;
      list<Integer> predtaskids,system;
      BackendDAE.BackendDAE dae;
      array<Integer> ass1,ass2;
    case (dae,ass1,ass2,system)
      equation
        print("build system\n");
        tid = TaskGraphExt.newTask("equation system");
        predtasks = buildSystem2(dae, ass1, ass2, system, tid);
        predtaskids = Util.listMap(predtasks, TaskGraphExt.getTask);
        addPredecessors(tid, predtaskids, predtasks, 0);
      then
        ();
    case (_,_,_,_)
      equation
        print("build_system failed\n");
      then
        fail();
  end matchcontinue;
end buildSystem;

protected function buildSystem2
  input BackendDAE.BackendDAE inBackendDAE1;
  input array<Integer> inIntegerArray2;
  input array<Integer> inIntegerArray3;
  input list<Integer> inIntegerLst4;
  input Integer inInteger5;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inBackendDAE1,inIntegerArray2,inIntegerArray3,inIntegerLst4,inInteger5)
    local
      BackendDAE.BackendDAE dae;
      array<Integer> ass1,ass2;
      Integer tid,e_1,v_1,e,i;
      DAE.Exp e1,e2;
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<DAE.ComponentRef> cr1,cr2,crs,crs_1;
      list<String> crs_2,crs2,res;
      String crstr,origname_str;
      BackendDAE.VariableArray vararr;
      BackendDAE.EquationArray eqns;
      list<Integer> rest;
    case (dae,ass1,ass2,{},tid) then {};
    case ((dae as BackendDAE.DAE(orderedVars = BackendDAE.VARIABLES(varArr = vararr),orderedEqs = eqns)),ass1,ass2,(e :: rest),tid)
      equation
        e_1 = e - 1;
        BackendDAE.EQUATION(e1,e2,_) = BackendDAEUtil.equationNth(eqns, e_1);
        i = ass2[e_1 + 1];
        v_1 = i - 1 "v == variable no solved in this equation" ;
        ((v as BackendDAE.VAR(cr,BackendDAE.VARIABLE(),_,_,_,_,_,_,_,dae_var_attr,comment,flowPrefix,streamPrefix))) = BackendVariable.vararrayNth(vararr, v_1);
        cr1 = Expression.extractCrefsFromExp(e1);
        cr2 = Expression.extractCrefsFromExp(e2);
        crs = listAppend(cr1, cr2);
        crs_1 = Util.listDeleteMember(crs, cr);
        crs_2 = Util.listMap(crs_1, ComponentReference.crefStr);
        crstr = ComponentReference.crefStr(cr);
        origname_str = ComponentReference.printComponentRefStr(cr);
        TaskGraphExt.storeResult(crstr, tid, true, origname_str);
        crs2 = buildSystem2(dae, ass1, ass2, rest, tid);
        res = Util.listUnion(crs_2, crs2);
      then
        res;
    case (_,_,_,_,_)
      equation
        print("TaskGraph.buildSystem2 failed\n");
      then
        fail();
  end matchcontinue;
end buildSystem2;

protected function addVariable
  input BackendDAE.Var inVar;
  input Integer inInteger;
algorithm
  _:= match (inVar,inInteger)
    local
      String cfs,name_str;
      DAE.ComponentRef cf;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      Integer start;
    case (BackendDAE.VAR(varName = cf,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix,streamPrefix = streamPrefix),start)
      equation
        cfs = ComponentReference.crefStr(cf);
        name_str = ComponentReference.printComponentRefStr(cf) "print \"adding variable \" & print cfs & print \"\\n\" &" ;
        TaskGraphExt.storeResult(cfs, start, false, name_str);
      then
        ();
  end match;
end addVariable;

protected function buildAssignment
  input DAE.ComponentRef inComponentRef;
  input DAE.Exp inExp;
  input String inString;
algorithm
  _:=
  matchcontinue (inComponentRef,inExp,inString)
    local
      Integer task,tid;
      String str,cr2s,crs,origname;
      DAE.ComponentRef cr,cr2;
      DAE.Exp exp;
      DAE.ExpType tp;
    case (cr,(exp as DAE.CREF(componentRef = cr2,ty = tp)),origname) /* varname expression orig. name */
      equation
        (task,str) = buildExpression(exp) "special rule for equation a:=b" ;
        tid = TaskGraphExt.newTask("copy");
        cr2s = ComponentReference.crefStr(cr2);
        TaskGraphExt.addEdge(task, tid, cr2s, 0);
        crs = ComponentReference.crefStr(cr);
        TaskGraphExt.storeResult(crs, tid, true, origname);
        TaskGraphExt.setTaskType(tid, 6) "See TaskType in TaskGraph.hpp" ;
      then
        ();
    case (cr,exp,origname)
      equation
        (task,str) = buildExpression(exp);
        crs = ComponentReference.crefStr(cr);
        TaskGraphExt.storeResult(crs, task, true, origname);
      then
        ();
    case (cr,exp,origname)
      equation
        print("-TaskGraph.buildAssignment failed\n");
      then
        fail();
  end matchcontinue;
end buildAssignment;

protected function buildExpression
"function buildExpression
  Builds the task graph for the expression and returns
  the task no that calculates the result of the expr"
  input DAE.Exp inExp;
  output Integer outInteger;
  output String outString;
algorithm
  (outInteger,outString):=
  matchcontinue (inExp)
    local
      String is,rs,crs,s1,istr,ts,s2,ops,s3,funcstr,s,es;
      Integer tid,i,t1,ival,t,t2,t3,numargs;
      Real r,rval;
      DAE.ComponentRef cr;
      DAE.Exp e1,e2,e3,e;
      DAE.Operator op,relop;
      list<Integer> tasks;
      list<String> strs;
      Absyn.Path func;
      list<DAE.Exp> expl;
    case (DAE.ICONST(integer = i))
      equation
        is = intString(i);
        tid = TaskGraphExt.newTask(is) "& TaskGraphExt.getStartTask() => st & TaskGraphExt.addEdge(st,tid,\"\") & TaskGraphExt.setCommCost(st,tid,0)" ;
      then
        (tid,"");

    case (DAE.RCONST(real = r))
      equation
        rs = realString(r);
        tid = TaskGraphExt.newTask(rs) "& TaskGraphExt.getStartTask() => st & TaskGraphExt.addEdge(st,tid,\"\") & TaskGraphExt.setCommCost(st,tid,0)" ;
      then
        (tid,"");

    case (DAE.CREF(componentRef = cr))
      equation
        crs = ComponentReference.crefStr(cr) "for state variables and alg. variables" ;
        tid = TaskGraphExt.getTask(crs);
      then
        (tid,crs);

    case (DAE.CREF(componentRef = DAE.CREF_IDENT(ident = "time")))
      equation
        tid = TaskGraphExt.getTask("sim_time") "for state variables and alg. variables" ;
      then
        (tid,"sim_time");

    case (DAE.CREF(componentRef = cr))
      equation
        crs = ComponentReference.crefStr(cr) "for constants and parameters, no data to send from proc0" ;
        tid = TaskGraphExt.newTask(crs);
      then
        (tid,crs);

    case (DAE.BINARY(exp1 = e1,operator = DAE.POW(ty = _),exp2 = DAE.RCONST(real = rval)))
      equation
        (t1,s1) = buildExpression(e1) "special case for pow" ;
        ival = realInt(rval);
        istr = intString(ival);
        ts = stringAppendList({"pow(%s,",istr,")"});
        t = TaskGraphExt.newTask(ts);
        TaskGraphExt.addEdge(t1, t, s1, 0);
      then
        (t,"");

    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
        (t1,s1) = buildExpression(e1);
        (t2,s2) = buildExpression(e2);
        ops = ExpressionDump.binopSymbol1(op);
        ts = stringAppendList({"%s",ops,"%s"});
        t = TaskGraphExt.newTask(ts);
        TaskGraphExt.addEdge(t1, t, s1, 0);
        TaskGraphExt.addEdge(t2, t, s2, 1);
      then
        (t,"");

    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
        (t1,s1) = buildExpression(e1);
        (t2,s2) = buildExpression(e2);
        ops = ExpressionDump.binopSymbol1(op);
        ts = stringAppendList({"%s",ops,"%s"});
        t = TaskGraphExt.newTask(ts);
        TaskGraphExt.addEdge(t1, t, s1, 0);
        TaskGraphExt.addEdge(t2, t, s2, 1);
      then
        (t,"");

    case (DAE.UNARY(operator = op,exp = e1))
      equation
        (t1,s1) = buildExpression(e1);
        ops = ExpressionDump.unaryopSymbol(op);
        ts = stringAppendList({ops,"%s"});
        t = TaskGraphExt.newTask(ts);
        TaskGraphExt.addEdge(t1, t, s1, 0);
      then
        (t,"");

    case (DAE.LUNARY(operator = op,exp = e1))
      equation
        (t1,s1) = buildExpression(e1);
        ops = ExpressionDump.lunaryopSymbol(op);
        ts = stringAppendList({ops,"%s"});
        t = TaskGraphExt.newTask(ts);
        TaskGraphExt.addEdge(t1, t, s1, 0);
      then
        (t,"");

    case (DAE.RELATION(exp1 = e1,operator = relop,exp2 = e2))
      equation
        (t1,s1) = buildExpression(e1);
        (t2,s2) = buildExpression(e2);
        ops = ExpressionDump.relopSymbol(relop);
        ts = stringAppendList({"%s",ops,"%s"});
        t = TaskGraphExt.newTask(ts);
        TaskGraphExt.addEdge(t1, t, s1, 0);
        TaskGraphExt.addEdge(t2, t, s2, 1);
      then
        (t,"");

    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation
        (t1,s1) = buildExpression(e1);
        (t2,s2) = buildExpression(e2);
        (t3,s3) = buildExpression(e3);
        ts = stringAppendList({"%s ? %s : %s"});
        t = TaskGraphExt.newTask(ts);
        TaskGraphExt.addEdge(t1, t, s1, 0);
        TaskGraphExt.addEdge(t2, t, s2, 1);
        TaskGraphExt.addEdge(t3, t, s3, 2);
      then
        (t,"");

    case (DAE.CALL(path = func,expLst = expl))
      equation
        funcstr = Absyn.pathString(func);
        numargs = listLength(expl);
        ts = buildCallStr(funcstr, numargs);
        (tasks,strs) = Util.listMap_2(expl, buildExpression);
        t = TaskGraphExt.newTask(ts);
        addPredecessors(t, tasks, strs, 0);
      then
        (t,"");

    case (DAE.ARRAY(ty = _))
      equation
        print("TaskGraph.buildExpression(ARRAY) not impl. yet\n");
      then
        fail();
    case (DAE.ARRAY(ty = _))
      equation
        print("TaskGraph.buildExpression(MATRIX) not impl. yet\n");
      then
        fail();
    case (DAE.RANGE(ty = _))
      equation
        print("TaskGraph.buildExpression(RANGE) not impl. yet\n");
      then
        fail();
    case (DAE.TUPLE(PR = _))
      equation
        print("TaskGraph.buildExpression(TUPLE) not impl. yet\n");
      then
        fail();
    case (DAE.CAST(exp = e))
      equation
        (t,s) = buildExpression(e);
      then
        (t,s);
    case (DAE.ASUB(exp = _))
      equation
        print("TaskGraph.buildExpression(ASUB) not impl. yet\n");
      then
        fail();
    case (DAE.SIZE(exp = _))
      equation
        print("TaskGraph.buildExpression(SIZE) not impl. yet\n");
      then
        fail();
    case (DAE.CODE(code = _))
      equation
        print("TaskGraph.buildExpression(CODE) not impl. yet\n");
      then
        fail();
    case (DAE.REDUCTION(path = _))
      equation
        print("TaskGraph.buildExpression(REDUCTION) not impl. yet\n");
      then
        fail();
    case (DAE.END())
      equation
        print("TaskGraph.buildExpression(END) not impl. yet\n");
      then
        fail();
    case (e)
      equation
        print("-TaskGraph.buildExpression failed\n Exp = ");
        es = ExpressionDump.printExpStr(e);
        print(es);
        print("\n");
      then
        fail();
  end matchcontinue;
end buildExpression;

protected function buildCallStr
  input String str;
  input Integer n;
  output String res;
  list<String> ns;
  String ns_1;
algorithm
  ns := Util.listFill("%s", n);
  ns_1 := Util.stringDelimitList(ns, ", ");
  res := stringAppendList({str,"(",ns_1,")"});
end buildCallStr;

protected function addPredecessors
  input Integer inInteger1;
  input list<Integer> inIntegerLst2;
  input list<String> inStringLst3;
  input Integer inInteger4;
algorithm
  _:=
  match (inInteger1,inIntegerLst2,inStringLst3,inInteger4)
    local
      Integer prio_1,t,t1,prio;
      list<Integer> ts;
      String s;
      list<String> strs;
    case (_,{},{},_) then ();  /* task list of precessors prio */
    case (t,(t1 :: ts),(s :: strs),prio)
      equation
        TaskGraphExt.addEdge(t1, t, s, prio);
        prio_1 = prio + 1;
        addPredecessors(t, ts, strs, prio_1);
      then
        ();
  end match;
end addPredecessors;

end TaskGraph;

