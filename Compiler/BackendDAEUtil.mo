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

package BackendDAEUtil
" file:	       BackendDAEUtil.mo
  package:     BackendDAEUtil 
  description: BackendDAEUtil comprised functions for BackendDAE data types.

  RCS: $Id: BackendDAEUtil.mo 6426 2010-10-19 08:01:48Z adrpo $

  This module is a lowered form of a DAE including equations
  and simple equations in
  two separate lists. The variables are split into known variables
  parameters and constants, and unknown variables,
  states and algebraic variables.
  The module includes the BLT sorting algorithm which sorts the
  equations into blocks, and the index reduction algorithm using
  dummy derivatives for solving higher index problems.
  It also includes the tarjan algorithm to detect strong components
  in the BLT sorting."

public import BackendDAE;
public import DAE;
public import ComponentReference;
public import Exp;
public import Util;

protected import DAELow;
protected import Debug;

public function checkBackendDAEWithErrorMsg"function: checkBackendDAEWithErrorMsg
  author: Frenkel TUD
  run checkDEALow and prints all errors"
  input BackendDAE.DAELow inBackendDAE;
  list<tuple<DAE.Exp,list<DAE.ComponentRef>>> expCrefs;
algorithm  
  expCrefs := checkBackendDAE(inBackendDAE);
  printcheckBackendDAEWithErrorMsg(expCrefs);
end checkBackendDAEWithErrorMsg;
 
public function printcheckBackendDAEWithErrorMsg"function: printcheckBackendDAEWithErrorMsg
  author: Frenkel TUD
  helper for checkDEALowWithErrorMsg"
  input list<tuple<DAE.Exp,list<DAE.ComponentRef>>> inExpCrefs;  
algorithm   
  _:=
  matchcontinue (inExpCrefs)
    local
      DAE.Exp e;
      list<DAE.ComponentRef> crefs;
      list<tuple<DAE.Exp,list<DAE.ComponentRef>>> res;
      list<String> strcrefs;
      case ({}) then ();
      case (((e,crefs))::res)
        equation
          print("Error in Exp ");
          print(Exp.printExpStr(e));print("\n Variables: ");
          strcrefs = Util.listMap(crefs,ComponentReference.crefStr);
          print(Util.stringDelimitList(strcrefs,", "));print("\nnot found in BackendDAE object.\n");
          printcheckBackendDAEWithErrorMsg(res);
        then
          ();
  end matchcontinue;
end printcheckBackendDAEWithErrorMsg;      
      
public function checkBackendDAE "function: checkBackendDAE
  author: Frenkel TUD

  This function checks the BackendDAE object if 
  all component refercences used in the expressions are 
  part of the BackendDAE object. Returns all component references
  which not part of the BackendDAE object. 
"
  input BackendDAE.DAELow inBackendDAE;
  output list<tuple<DAE.Exp,list<DAE.ComponentRef>>> outExpCrefs;
algorithm
  outExpCrefs :=
  matchcontinue (inBackendDAE)
    local
      BackendDAE.Variables vars1,vars2,allvars;
      list<BackendDAE.Var> varlst1,varlst2,allvarslst;
      list<tuple<DAE.Exp,list<DAE.ComponentRef>>> expcrefs;
    case (BackendDAE.DAELOW(orderedVars = vars1,knownVars = vars2))
      equation
        varlst1 = DAELow.varList(vars1);
        varlst2 = DAELow.varList(vars2);
        allvarslst = listAppend(varlst1,varlst2);
        allvars = DAELow.listVar(allvarslst);
        expcrefs = DAELow.traverseDEALowExps(inBackendDAE,false,checkBackendDAEExp,allvars);
      then
        expcrefs;
    case (_)
      equation
        Debug.fprintln("failtrace", "- BackendDAE.checkBackendDAE failed");
      then
        fail();
  end matchcontinue;
end checkBackendDAE;

protected function checkBackendDAEExp
  input DAE.Exp inExp;
  input BackendDAE.Variables inVars;
  output list<tuple<DAE.Exp,list<DAE.ComponentRef>>> outExpCrefs;
algorithm
  outExpCrefs :=
  matchcontinue (inExp,inVars)
    local  
      DAE.Exp exp;
      BackendDAE.Variables vars;
      list<DAE.ComponentRef> crefs;
      list<tuple<DAE.Exp,list<DAE.ComponentRef>>> lstExpCrefs;
    case (exp,vars)
      equation
        ((_,(_,crefs))) = Exp.traverseExpTopDown(exp,traversecheckBackendDAEExp,((vars,{})));
        lstExpCrefs = Util.if_(listLength(crefs)>0,{(exp,crefs)},{});
       then
        lstExpCrefs;
  end matchcontinue;      
end checkBackendDAEExp;

protected function traversecheckBackendDAEExp
	input tuple<DAE.Exp, tuple<BackendDAE.Variables,list<DAE.ComponentRef>>> inTuple;
	output tuple<DAE.Exp, tuple<BackendDAE.Variables,list<DAE.ComponentRef>>> outTuple;
algorithm
	outTuple := matchcontinue(inTuple)
		local
			DAE.Exp e;
			BackendDAE.Variables vars;
			DAE.ComponentRef cr;
			list<DAE.ComponentRef> crefs;
			list<DAE.Exp> expl;
		// special case for time, it is never part of the equation system	
		case ((e as DAE.CREF(componentRef = DAE.CREF_IDENT(ident="time")),(vars,crefs)))
		  then ((e, (vars,crefs)));
    /* Special Case for Records */
    case ((e as DAE.CREF(componentRef = cr),(vars,crefs)))
      local 
        list<list<tuple<DAE.Exp,list<DAE.ComponentRef>>>> expcreflstlst;
        list<tuple<DAE.Exp,list<DAE.ComponentRef>>> expcreflst;
        list<list<DAE.ComponentRef>> creflstlst;
        list<DAE.ComponentRef> crlst;
        list<DAE.ExpVar> varLst;
      equation
        DAE.ET_COMPLEX(varLst=varLst) = ComponentReference.crefLastType(cr);
        expl = Util.listMap1(varLst,DAELow.generateCrefsExpFromType,e);
        expcreflstlst = Util.listMap1(expl,checkBackendDAEExp,vars);
        expcreflst = Util.listFlatten(expcreflstlst);
        creflstlst = Util.listMap(expcreflst,Util.tuple22);
        crlst = Util.listFlatten(creflstlst);
      then
        ((e, (vars,listAppend(crlst,crefs))));  
		case ((e as DAE.REDUCTION(ident = ident),(vars,crefs)))
		  local 
		    DAE.Ident ident;
		    BackendDAE.Var  var;
		  equation
		    // add ident to vars
		    cr = ComponentReference.makeCrefIdent(ident,DAE.ET_INT(),{});
		    var = BackendDAE.VAR(cr,BackendDAE.VARIABLE(),DAE.BIDIR(),BackendDAE.INT(),NONE(),NONE(),{},0,
		          DAE.emptyElementSource,NONE(),NONE(),DAE.NON_CONNECTOR(),DAE.NON_STREAM_CONNECTOR());
		    vars = DAELow.addVar(var,vars);
		  then
		    ((e, (vars,crefs)));
		case ((e as DAE.CREF(componentRef = cr),(vars,crefs)))
		  equation
		     (_,_) = DAELow.getVar(cr, vars);
		  then
		    ((e, (vars,crefs)));
		case ((e as DAE.CREF(componentRef = cr),(vars,crefs)))
		  equation
		     failure((_,_) = DAELow.getVar(cr, vars));
		  then
		    ((e, (vars,cr::crefs)));
		case (_) then inTuple;
	end matchcontinue;
end traversecheckBackendDAEExp;

end BackendDAEUtil;
