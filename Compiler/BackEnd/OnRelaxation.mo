/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
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
 * from Linköping University, either from the above address,
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

encapsulated package OnRelaxation
" file:        OnRelaxation.mo
  package:     OnRelaxation
  description: OnRelaxation contains functions that do some kind of
               optimization on the BackendDAE datatype:
               - Relaxation for MultiBody Systems
               
  RCS: $Id: OnRelaxation.mo 12002 2012-06-08 07:26:09Z petar $"

public import BackendDAE;
public import DAE;

protected import BackendDAEUtil;
protected import BackendDAEEXT;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import BackendDAETransform;
protected import BaseHashSet;
protected import ComponentReference;
protected import Debug;
protected import Derive;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import HashSet;
protected import HashTable4;
protected import IndexReduction;
protected import List;
protected import Matching;
protected import Util;


/* 
 * relaxation from gausian elemination
 *
 */

public function relaxSystem
"function relaxSystem
  author: Frenkel TUD 2011-05"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
  output Boolean outRunMatching;
algorithm
  (outDAE,outRunMatching) := BackendDAEUtil.mapEqSystemAndFold(inDAE,relaxSystem0,false);
end relaxSystem;

protected function relaxSystem0
"function relaxSystem0
  author: Frenkel TUD 2011-05"
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Shared,Boolean> sharedChanged;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared,Boolean> osharedChanged;
algorithm
  (osyst,osharedChanged) := 
    matchcontinue(isyst,sharedChanged)
    local
      BackendDAE.StrongComponents comps;
      Boolean b,b1,b2;
      BackendDAE.Shared shared;
      BackendDAE.Matching matching;
      BackendDAE.EqSystem syst;
      
    case (syst as BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps)),(shared, b1))
      equation
        (syst,shared,b2) = relaxSystem1(syst,shared,comps);
        b = b1 or b2;
      then
        (syst,(shared,b));
  end matchcontinue;  
end relaxSystem0;

protected function relaxSystem1
"function relaxSystem1
  author: Frenkel TUD 2011-05"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.StrongComponents inComps;  
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output Boolean outRunMatching;
algorithm
  (osyst,oshared,outRunMatching):=
  matchcontinue (isyst,ishared,inComps)
    local
      list<Integer> eindex,vindx,eorphans,eforphans,vorphans,unassigned,otherorphans,roots,constraints,constraintresidual;
      Boolean b,b1;
      BackendDAE.EqSystem syst,subsyst;
      BackendDAE.Shared shared;
      BackendDAE.StrongComponents comps;
      BackendDAE.StrongComponent comp,comp1;   
      array<Integer> ass1,ass2,vec2,rowmarks,colummarks,vec3,vorphansarray,mapIncRowEqn;
      Integer size,eo,io,mark,i1,i2,i3,esize,temp;
      list<BackendDAE.Equation> eqn_lst; 
      list<BackendDAE.Var> var_lst;    
      BackendDAE.Variables vars,tvars,vars1;
      BackendDAE.EquationArray eqns,teqns;
      BackendDAE.IncidenceMatrix m,m1;
      BackendDAE.IncidenceMatrix mt; 
      array<DAE.Constraint> constrs;
      list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
      list<tuple<Integer,list<tuple<Integer,Integer>>>> orphanspairs;
      list<DAE.Exp> beqs;
      array<list<tuple<Integer,DAE.Exp>>> matrix;
      array<DAE.Exp> crefexps;
      list<DAE.Exp> crefexplst;
      array<list<Integer>> vorphansarray1,vorphansarrayT1,mapEqnIncRow,ass22,vec1;
      list<BackendDAE.Equation> neweqns;      
      BackendDAE.StrongComponents othercomps;
      HashTable4.HashTable ht;   
      
    case (_,_,{})
      then (isyst,ishared,false);
    case (_,shared ,
      (comp as BackendDAE.EQUATIONSYSTEM(eqns=eindex,vars=vindx,jac=SOME(jac),jacType=BackendDAE.JAC_TIME_VARYING()))::comps)
      equation
        print("try to relax\n");
        size = listLength(vindx);
        esize = listLength(eindex);
        ass1 = arrayCreate(size,-1);
        ass2 = arrayCreate(size,-1);
        eqn_lst = BackendEquation.getEqns(eindex,BackendEquation.daeEqns(isyst));  
        eqns = BackendDAEUtil.listEquation(eqn_lst);      
        var_lst = List.map1r(vindx, BackendVariable.getVarAt, BackendVariable.daeVars(isyst));
        vars = BackendDAEUtil.listVar1(var_lst);

        subsyst = BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING());
        (subsyst,m,mt,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(subsyst, shared, BackendDAE.ABSOLUTE());
          BackendDump.dumpEqSystem(subsyst);

        // Vector Matching  
        ((_,ass1,ass2)) = List.fold1(eqn_lst,vectorMatching,vars,(1,ass1,ass2));
        m1 = arrayCreate(size,{});
        transformJacToIncidenceMatrix2(jac,m1,mapIncRowEqn,eqns,ass1,ass2,isConstOneMinusOne);
        Matching.matchingExternalsetIncidenceMatrix(size,size,m1);
        true = BackendDAEEXT.setAssignment(size,size,ass2,ass1);
        BackendDAEEXT.matching(size,size,5,-1,1.0,0);
        BackendDAEEXT.getAssignment(ass2,ass1);

        // Natural Matching - seems not to be good enough
        //((_,ass1,ass2)) = List.fold1(eqn_lst,naturalMatching,vars,(1,ass1,ass2));
        //((_,ass1,ass2)) = List.fold1(eqn_lst,naturalMatching1,vars,(1,ass1,ass2));
        //((_,ass1,ass2)) = List.fold1(eqn_lst,naturalMatching2,vars,(1,ass1,ass2));
        //  subsyst = BackendDAEUtil.setEqSystemMatching(subsyst,BackendDAE.MATCHING(ass1,ass2,{}));
        //  IndexReduction.dumpSystemGraphML(subsyst,shared,NONE(),intString(size) +& "SystemVectorMatching.graphml"); 
        //  BackendDump.dumpMatching(ass1);
        //  BackendDump.dumpMatching(ass2);        

        // Boeser hack fuer FourBar
    /*    
        (subsyst,m,mt,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(subsyst, shared, BackendDAE.ABSOLUTE());
        temp::_ = mapEqnIncRow[72]; 
        _ = arrayUpdate(ass1,90,temp);
        _ = arrayUpdate(ass2,temp,90);

        temp::_ = mapEqnIncRow[97]; 
        _ = arrayUpdate(ass1,125,temp);
        _ = arrayUpdate(ass2,temp,125);

        temp::_ = mapEqnIncRow[99]; 
        _ = arrayUpdate(ass1,128,temp);
        _ = arrayUpdate(ass2,temp,128);
          subsyst = BackendDAEUtil.setEqSystemMatching(subsyst,BackendDAE.MATCHING(ass1,ass2,{}));
          IndexReduction.dumpSystemGraphML(subsyst,shared,NONE(),intString(size) +& "SystemHackMatching.graphml");
*/

        // Matching based on Enhanced Adiacency Matrix, take care of the solvability - theems to be good but not good enough
        //  (subsyst,_,_) = BackendDAEUtil.getIncidenceMatrix(subsyst, shared, BackendDAE.ABSOLUTE());
        //   BackendDump.dumpEqSystem(subsyst);
        //   dumpJacMatrix(jac,1,1,size,vars);
        m1 = arrayCreate(size,{});
        //mt1 = arrayCreate(size,{});
        transformJacToIncidenceMatrix1(jac,m1,ass1,ass2,isConstOneMinusOne);
        //  BackendDump.dumpIncidenceMatrix(m1);
        //  BackendDump.dumpIncidenceMatrixT(mt1);
        //transformJacToIncidenceMatrix(jac,1,1,size,m1,mt1,isConstOneMinusOne);
        Matching.matchingExternalsetIncidenceMatrix(size,size,m1);
        true = BackendDAEEXT.setAssignment(size,size,ass2,ass1);
        BackendDAEEXT.matching(size,size,1,-1,1.0,0);
        BackendDAEEXT.getAssignment(ass2,ass1);
        
        //  subsyst = BackendDAEUtil.setEqSystemMatching(subsyst,BackendDAE.MATCHING(ass1,ass2,{}));
        //  IndexReduction.dumpSystemGraphML(subsyst,shared,NONE(),intString(size) +& "SystemOneMatching.graphml");
        //  BackendDump.dumpMatching(ass1);
        //  BackendDump.dumpMatching(ass2);        
        
        // onefreeMatching
        //  print("mapEqnIncRow:\n");
        //  BackendDump.dumpIncidenceMatrix(mapEqnIncRow);
        unassigned = Matching.getUnassigned(size,ass2,{});
        colummarks = arrayCreate(size,-1);
        onefreeMatchingBFS(unassigned,m,mt,size,ass1,ass2,colummarks,1,{});

        //  BackendDump.dumpMatching(ass1);
        //  BackendDump.dumpMatching(ass2);        
          subsyst = BackendDAEUtil.setEqSystemMatching(subsyst,BackendDAE.MATCHING(ass1,ass2,{}));
          IndexReduction.dumpSystemGraphML(subsyst,shared,NONE(),intString(size) +& "SystemOneFreeMatching.graphml");

        // hier sollte zur vorsicht noch mal ein matching durchgefuehrt werden
        
        // collect tearing variables and residual equations
        vorphans = getOrphans(1,size,ass1,{});
        eorphans = getOrphans(1,size,ass2,{});
           print("Var Orphans: \n");
           BackendDump.debuglst((vorphans,intString,", ","\n"));
           print("Equation Orphans: \n");
           BackendDump.debuglst((eorphans,intString,", ","\n"));
        
        // transform to nonscalar 
        ass1 = BackendDAETransform.varAssignmentNonScalar(1,size,ass1,mapIncRowEqn,{});
        ass22 = BackendDAETransform.eqnAssignmentNonScalar(1,arrayLength(mapEqnIncRow),mapEqnIncRow,ass2,{});
        eorphans = List.unique(List.map1r(eorphans,arrayGet,mapIncRowEqn));
        (subsyst,m,mt) = BackendDAEUtil.getIncidenceMatrix(subsyst, shared, BackendDAE.ABSOLUTE());
        //  BackendDump.dumpIncidenceMatrix(m);
        //  BackendDump.dumpIncidenceMatrixT(mt);

        // genereate cliques
        rowmarks = arrayCreate(size,-1);
        colummarks = arrayCreate(size,-1);
        vorphansarray1 = arrayCreate(size,{});
        mark = 1 "init mark value";
        (mark,constraintresidual) = generateCliquesResidual(eorphans,ass1,ass22,m,mt,mark,rowmarks,colummarks,vars,{}) "generate cliques for residual equations";
          print("constraintresidual: \n");
           BackendDump.debuglst((constraintresidual,intString,", ","\n"));        
        (mark,roots,constraints) = prepairOrphansOrder(vorphans,ass1,ass22,m,mt,mark,rowmarks,colummarks,vorphansarray1,vars,{},{}) "generate cliques for tearing vars";
        mark = prepairOrphansOrder2(vorphans,ass1,ass22,m,mt,mark,rowmarks,colummarks,vorphansarray1);
          subsyst = BackendDAE.EQSYSTEM(vars,eqns,SOME(m),SOME(mt),BackendDAE.NO_MATCHING());
          IndexReduction.dumpSystemGraphML(subsyst,shared,NONE(),intString(size) +& "SystemPreIndex.graphml");
          print("roots:\n");
          BackendDump.debuglst((roots,intString,", ","\n")); 
          print("constraints:\n");
          BackendDump.debuglst((constraints,intString,", ","\n")); 

        // Order of orphans 
        vorphansarray1 = arrayCreate(size,{});
        List.map2_0(roots,doMark,rowmarks,mark);
        List.map2_0(constraints,doMark,rowmarks,mark);
        otherorphans = List.select2(vorphans, unmarked, rowmarks, mark);
          print("otherorphans:\n");
          BackendDump.debuglst((otherorphans,intString,", ","\n")); 
        mark = getOrphansOrderEdvanced(otherorphans,ass1,ass22,m,mt,mark,rowmarks,colummarks,vorphansarray1);
        List.map2_0(otherorphans,removeRootConnections,vorphansarray1,roots);
        mark = getConstraintesOrphansOrderEdvanced(constraints,ass1,ass22,m,mt,mark,rowmarks,colummarks,vorphansarray1);
          print("getOrphansOrderEdvanced:\n");
          BackendDump.dumpIncidenceMatrix(vorphansarray1);

        // get pairs of orphans 
        List.map2_0(constraintresidual,doAssign,ass22,{1});
        mark = getOrphansPairs(roots,ass1,ass22,m,mt,mark,rowmarks,colummarks);
        mark = getOrphansPairs(otherorphans,ass1,ass22,m,mt,mark,rowmarks,colummarks);
        List.map2_0(constraintresidual,doAssign,ass22,{});
        mark = getOrphansPairsConstraints(constraints,ass1,ass22,m,mt,mark,rowmarks,colummarks);
          print("Matching with Orphans:\n");
          BackendDump.dumpMatching(ass1);
          BackendDump.dumpIncidenceMatrix(ass22); 

        true = false;
          

        vorphansarrayT1 = arrayCreate(size,{});
        vorphansarrayT1 = List.fold1(vorphans,transposeMatrix,vorphansarray1,vorphansarrayT1);
          print("getOrphansOrderEdvanced:\n");
          BackendDump.dumpIncidenceMatrix(vorphansarray1);
          BackendDump.dumpIncidenceMatrix(vorphansarrayT1);

       
       
        //(subsyst,m,mt,_,_) = BackendDAEUtil.getIncidenceMatrixScalar(subsyst, shared, BackendDAE.ABSOLUTE());
        (mark,orphanspairs) = getOrphanspairs(1,ass2,size,m,mt,mark,rowmarks,colummarks,ass1,{});
          print("Orphans Pairs: \n");
          List.map_0(orphanspairs,dumpOrphansPairs); print("\n");        

          print("getOrphansOrderEdvanced:\n");
          BackendDump.dumpIncidenceMatrix(vorphansarray1);
          BackendDump.dumpIncidenceMatrix(vorphansarrayT1);
        (vorphans,mark) = getOrphansOrderEdvanced3(vorphans,vorphansarray1,vorphansarrayT1,mark,rowmarks);


        // order of orphans fuer Baume
        /*
        vorphansarray = arrayCreate(size,0);
        mark = getOrphansOrder(vorphans,ass1,ass2,m,mt,mark,rowmarks,colummarks,arrayCreate(size,-1),vorphansarray);
          BackendDump.dumpMatching(vorphansarray);
        _ = List.fold1(arrayList(vorphansarray),transposeOrphanVec,vorphansarray1,1);
          BackendDump.dumpIncidenceMatrix(vorphansarray1);
        vorphans = getOrphansOrder3(vorphans,vorphansarray1,vorphansarray,mark,rowmarks,{});
        mark = mark + 1;
        */

          print("sorted Var Orphans: \n");
           List.map1_0(vorphans,dumpVar, vars);
          BackendDump.debuglst((vorphans,intString,", ","\n"));
       //   BackendDump.dumpVarsArray(vars);

        eforphans = matchOrphans(orphanspairs,ass1,ass22,mapIncRowEqn,{});
        //  print("First Orphanspairs " +& intString(listLength(eforphans)) +& "\n");
        //  BackendDump.debuglst((eforphans,intString,", ","\n"));
        //  BackendDump.dumpMatching(ass1);
        //  BackendDump.dumpIncidenceMatrix(ass22); 
        
        vec1 = arrayCreate(esize,{});
        vec2 = arrayCreate(esize,-1);
        
        //getIndexesForEqns(eforphans,1,m,mt,mark,rowmarks,colummarks,ass1,ass2,vec1,vec2,{});

        rowmarks = List.fold1(vorphans,markOrphans,mark,rowmarks);
        //mark = getIndexesForEqnsNew(vorphans,1,m,mt,mark,rowmarks,colummarks,ass1,ass2,vec1,vec2);
        colummarks = List.fold1(eorphans,markOrphans,mark,colummarks);
        (subsyst,m,mt) = BackendDAEUtil.getIncidenceMatrix(subsyst, shared, BackendDAE.ABSOLUTE());
        mark = getIndexesForEqnsAdvanced(vorphans,1,m,mt,mark,rowmarks,colummarks,ass1,ass22,vec1,vec2,arrayCreate(esize,false));
        
        //  BackendDump.dumpIncidenceMatrix(vec1);
        //  BackendDump.dumpMatching(vec2);
        //  vec3 = arrayCreate(size,-1);
        //  _ = List.fold1(arrayList(vec2),transposeOrphanVec,vec3,1);
        //  IndexReduction.dumpSystemGraphML(subsyst,shared,SOME(vec3),"System.graphml");

        ((_,_,_,eqns,vars)) = Util.arrayFold(vec2,getEqnsinOrder,(eqns,vars,ass22,BackendDAEUtil.listEquation({}),BackendDAEUtil.emptyVars()));
        
        // replace evaluated parametes
        //_ = BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(eqns, replaceFinalParameter, BackendVariable.daeKnVars(shared));
        
        subsyst = BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING());
        (subsyst,m,mt) = BackendDAEUtil.getIncidenceMatrix(subsyst, shared, BackendDAE.ABSOLUTE());
        //  BackendDump.dumpEqSystem(subsyst);   
        //  IndexReduction.dumpSystemGraphML(subsyst,shared,NONE(),intString(size) +& "SystemIndexed.graphml"); 
        SOME(jac) = BackendDAEUtil.calculateJacobian(vars, eqns, m, mt,true);
        ((_,beqs,_)) = BackendEquation.traverseBackendDAEEqns(eqns,BackendEquation.equationToExp,(vars,{},{}));
        beqs = listReverse(beqs);
        //  print("Jacobian:\n");
        //  print(BackendDump.dumpJacobianStr(SOME(jac)) +& "\n");
        // dumpJacMatrix(jac,1,1,size,vars);
        
        matrix = arrayCreate(size,{});
        transformJacToMatrix(jac,1,1,size,beqs,matrix);
        //  print("Jacobian as Matrix:\n");
        //  dumpMatrix(1,size,matrix);
        ht = HashTable4.emptyHashTable();
        (tvars,teqns) = gaussElimination(1,size,matrix,BackendDAEUtil.emptyVars(),BackendDAEUtil.listEquation({}),(1,1));
        //  dumpMatrix(1,size,matrix);
        //  subsyst = BackendDAE.EQSYSTEM(tvars,teqns,NONE(),NONE(),BackendDAE.NO_MATCHING());
        //  BackendDump.dumpEqSystem(subsyst);
        eqn_lst = BackendDAEUtil.equationList(teqns);  
        var_lst = BackendDAEUtil.varList(tvars);      
        syst = List.fold(eqn_lst,BackendEquation.equationAddDAE,isyst);
        syst = List.fold(var_lst,BackendVariable.addVarDAE,syst);
        crefexplst = List.map(BackendDAEUtil.varList(vars),makeCrefExps);
        crefexps = listArray(crefexplst);
        neweqns = makeGausElimination(1,size,matrix,crefexps,{});
        syst = replaceEquationsAddNew(eindex,neweqns,syst);
        
        /*
        vars = BackendVariable.addVars(var_lst, vars);
        eqns = BackendEquation.addEquations(neweqns, teqns);
        subsyst = BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING());
          (subsyst,m,mt,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(subsyst, shared, BackendDAE.NORMAL());
          print("Relaxed System:\n");
          BackendDump.dumpEqSystem(subsyst);

          size = arrayLength(m);
          Matching.matchingExternalsetIncidenceMatrix(size,size,m);
          ass1 = arrayCreate(size,-1);
          ass2 = arrayCreate(size,-1);          
          BackendDAEEXT.matching(size,size,5,-1,1.0,1);
          BackendDAEEXT.getAssignment(ass2,ass1);
          subsyst = BackendDAEUtil.setEqSystemMatching(subsyst,BackendDAE.MATCHING(ass1,ass2,{})); 
          (subsyst,othercomps) = BackendDAETransform.strongComponentsScalar(subsyst, shared, mapEqnIncRow, mapIncRowEqn);           
          print("Relaxed System:\n");
          BackendDump.dumpEqSystem(subsyst);
        */
        
        //  (syst,_,_) = BackendDAEUtil.getIncidenceMatrix(syst, shared, BackendDAE.NORMAL());
        //  BackendDump.dumpEqSystem(syst);
        //  (i1,i2,i3) = countOperations1(syst,shared);
        //  print("Add Operations: " +& intString(i1) +& "\n");
        //  print("Mul Operations: " +& intString(i2) +& "\n");
        //  print("Oth Operations: " +& intString(i3) +& "\n");
          print("Ok system relaxed\n");
        (syst,shared,b) = relaxSystem1(syst,shared,comps);
      then
        (syst,shared,true);
    case (_,_,(comp as BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=comp1))::comps)
      equation
        (syst,shared,b) = relaxSystem1(isyst,ishared,{comp1});
        (syst,shared,b1) = relaxSystem1(syst,shared,comps);
      then
        (syst,shared,b1 or b);
    case (_,_,comp::comps)
      equation
        (syst,shared,b) = relaxSystem1(isyst,ishared,comps);
      then
        (syst,shared,b);
  end matchcontinue;  
end relaxSystem1;

protected function removeRootConnects
  input Integer orphan;
  input array<list<Integer>> orphansarray;
  input Integer mark;
  input array<Integer> rowmarks;  
protected
  list<Integer> lst;
algorithm
  lst := List.select2(orphansarray[orphan], unmarked, rowmarks, mark);
  _:= arrayUpdate(orphansarray,orphan,lst);
end removeRootConnects;

protected function removeRootConnections
  input Integer orphan;
  input array<list<Integer>> orphansarray;
  input list<Integer> roots;
algorithm
  _:= matchcontinue(orphan,orphansarray,roots)
    local
      list<Integer> lst;
    case(_,_,_)
      equation
        lst = orphansarray[orphan];
        true = intGt(listLength(lst),1);
        lst = List.fold1(roots,List.removeOnTrue, intEq, lst);
        _= arrayUpdate(orphansarray,orphan,lst);
      then
        ();
    case(_,_,_)
      then
        ();
  end matchcontinue;
end removeRootConnections;

protected function transposeMatrix
  input Integer index;
  input array<list<Integer>> orphansarray;
  input array<list<Integer>> orphansarrayT;
  output array<list<Integer>> outOrphansarrayT;
protected 
  list<Integer> lst;
algorithm
  lst := orphansarray[index];
  outOrphansarrayT := List.fold1(lst,Util.arrayCons,index,orphansarrayT); 
end transposeMatrix;

protected function replaceFinalParameter
"function replaceFinalParameter
  author: Frenkel TUD 2012-06"
  input tuple<DAE.Exp,BackendDAE.Variables> itpl;
  output tuple<DAE.Exp,BackendDAE.Variables> outTpl;
protected
  DAE.Exp e;
  BackendDAE.Variables knvars;
  Boolean b;
algorithm
  (e,knvars) := itpl;
  ((e,(knvars,b))) := Expression.traverseExp(e,traverserExpreplaceFinalParameter,(knvars,false));
  (e,_) := ExpressionSimplify.condsimplify(b, e);
  outTpl := (e,knvars);
end replaceFinalParameter;

protected function traverserExpreplaceFinalParameter
"function traverserExpreplaceFinalParameter
  author: Frenkel TUD 2012-06"
  input tuple<DAE.Exp,tuple<BackendDAE.Variables,Boolean>> tpl;
  output tuple<DAE.Exp,tuple<BackendDAE.Variables,Boolean>> outTpl;
algorithm
  outTpl := matchcontinue(tpl)
    local
      BackendDAE.Variables knvars;
      DAE.Exp e,e1;
      DAE.ComponentRef cr;
      BackendDAE.Var v;
    case((DAE.CREF(componentRef=cr),(knvars,_)))
      equation
        (v::_,_) = BackendVariable.getVar(cr, knvars);
        true = BackendVariable.isFinalVar(v);
        e1 = BackendVariable.varBindExpStartValue(v);
      then 
        ((e1,(knvars,true)));  
                       
    case tpl then tpl;
  end matchcontinue;
end traverserExpreplaceFinalParameter;


protected function replaceEquationsAddNew
  input list<Integer> inEqnIndxes;
  input list<BackendDAE.Equation> inEqns;
  input BackendDAE.EqSystem isyst;
  output BackendDAE.EqSystem osyst;
algorithm
  osyst := match(inEqnIndxes,inEqns,isyst)
    local
      Integer i;
      list<Integer> indxs;
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqns;
      BackendDAE.EqSystem syst;
    case ({},_,_) 
      then
       BackendEquation.equationsAddDAE(inEqns,isyst); 
    case (i::indxs,eqn::eqns,_)
      equation
        syst = BackendEquation.equationSetnthDAE(i-1, eqn, isyst);
      then
        replaceEquationsAddNew(indxs,eqns,syst);
  end match; 
end replaceEquationsAddNew;

protected function dumpVar
"function dumpVar
  author: Frenkel TUD 2012-05"
  input Integer id;
  input BackendDAE.Variables vars;
protected
  BackendDAE.Var v;
algorithm
  v := BackendVariable.getVarAt(vars,id);
  print(ComponentReference.printComponentRefStr(BackendVariable.varCref(v)));
  print("\n");
end dumpVar;

protected function transposeOrphanVec
"function transposeOrphanVec
  author: Frenkel TUD 2012-05"
  input Integer c;
  input array<list<Integer>> vec3;
  input Integer inId;
  output Integer outId;
algorithm
  outId := matchcontinue(c,vec3,inId)
    local list<Integer> lst;
    case (_,_,_)
      equation
        true = intGt(c,0);
        lst = vec3[c];
        _ = arrayUpdate(vec3,c,inId::lst);
      then
        inId + 1;
    else
      inId + 1;
  end matchcontinue;      
end transposeOrphanVec;

protected function markOrphans
"function markOrphans
  author: Frenkel TUD 2012-05"
  input Integer o;
  input Integer mark;
  input array<Integer> rowmark;
  output array<Integer> orowmark;
algorithm
  orowmark := arrayUpdate(rowmark,o,-2);
end markOrphans;

protected function generateCliquesResidual
"function generateCliquesResidual
  author: Frenkel TUD 2012-07"
  input list<Integer> inOrphans;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input BackendDAE.Variables vars;  
  input list<Integer> iconstraints;
  output Integer omark;
  output list<Integer> oconstraints;
algorithm
  (omark,oconstraints) := matchcontinue(inOrphans,ass1,ass2,m,mt,mark,rowmarks,colummarks,vars,iconstraints)
    local
      list<Integer> rest,constraints,rlst;
      array<Integer> sorphans;
      Integer o,c,mark;
      Boolean foundflow;
      list<Boolean> blst;
      list<BackendDAE.Var> vlst;      
    case ({},_,_,_,_,_,_,_,_,_)
      then
       (mark,iconstraints);
    case (o::rest,_,_,_,_,_,_,_,_,_)
      equation
        false = intEq(colummarks[o],mark);
        _ = arrayUpdate(colummarks,o,mark);
        //  print("Process Residual " +& intString(o) +& "\n");
        rlst = m[o];
        //  BackendDump.debuglst((rlst,intString,", ","\n"));
        vlst = List.map1r(rlst,BackendVariable.getVarAt,vars);
        blst = List.map(vlst,BackendVariable.isFlowVar);
        foundflow = Util.boolOrList(blst);
        rlst = selectNonFlows(rlst,blst,{});          
        foundflow = generateCliquesResidual1(rlst,ass1,ass2,m,mt,mark,rowmarks,colummarks,foundflow,vars);
        generateCliquesResidual2(rlst,ass1,ass2,m,mt,mark+1,rowmarks,colummarks,o,o);
        constraints = List.consOnTrue(not foundflow, o, iconstraints);
        (mark,constraints) = generateCliquesResidual(rest,ass1,ass2,m,mt,mark+2,rowmarks,colummarks,vars,constraints);
      then
       (mark,constraints);
    case (_::rest,_,_,_,_,_,_,_,_,_)
      equation
        (mark,constraints) = generateCliquesResidual(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,vars,iconstraints); 
      then
        (mark,constraints);
  end matchcontinue;
end generateCliquesResidual;


protected function generateCliquesResidual1
"function generateCliquesResidual1
  author: Frenkel TUD 2012-05"
  input list<Integer> rows;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input Boolean ifoundFlow;
  input BackendDAE.Variables vars;
  output Boolean ofoundFlow;  
algorithm
  ofoundFlow := matchcontinue(rows,ass1,ass2,m,mt,mark,rowmarks,colummarks,ifoundFlow,vars)
    local
      Integer o,c1,e,r;
      list<Integer> rest,next,olst,rlst,lst;
      Boolean b,b1;
      list<Boolean> blst;
      list<BackendDAE.Var> vlst;      
    case ({},_,_,_,_,_,_,_,_,_)
      then
        ifoundFlow;
    case (r::rest,_,_,_,_,_,_,_,_,_)
      equation
        //  print("check Var " +& intString(r)  +& " ass[e]: " +& intString(ass1[r]) +& "\n");
        false = intEq(rowmarks[r],mark);
        // remove orphans
        next = List.select1(mt[r],isNoResOrphan,ass2);
        // remove visited
        next = List.select2(next, unmarked, colummarks, mark);
        // remove assigned equation of this row
        next = List.removeOnTrue(ass1[r], intEq, next);
        //  print("Eqns use Var " +& intString(r) +& " : " +& stringDelimitList(List.map(next,intString),", ") +& "\n");
        true = intGt(listLength(next),0);
      then
        generateCliquesResidual1(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,ifoundFlow,vars); 
    case (r::rest,_,_,_,_,_,_,_,_,_)
      equation
        false = intEq(rowmarks[r],mark);
        // remove orphans
        next = List.select1(mt[r],isNoResOrphan,ass2);
        // remove visited
        next = List.select2(next, unmarked, colummarks, mark);
        // remove assigned equation of this row
        next = List.removeOnTrue(ass1[r], intEq, next);
        false = intGt(listLength(next),0);
        _ = arrayUpdate(rowmarks,r,mark);
        e = ass1[r];
        // print("Go From " +& intString(r) +& " to " +& intString(e) +& "\n");
        _ = arrayUpdate(colummarks,e,mark);
        rlst = ass2[e];
        next = List.fold1(rlst,List.removeOnTrue, intEq, m[e]);
        vlst = List.map1r(next,BackendVariable.getVarAt,vars);
        blst = List.map(vlst,BackendVariable.isFlowVar);
        b1 = Util.boolOrList(blst);
        next = selectNonFlows(next,blst,{});
        b = generateCliquesResidual1(next,ass1,ass2,m,mt,mark,rowmarks,colummarks,b1 or ifoundFlow,vars); 
      then
        generateCliquesResidual1(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,b,vars); 
    case (_::rest,_,_,_,_,_,_,_,_,_)
      then
        generateCliquesResidual1(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,ifoundFlow,vars); 
  end matchcontinue;
end generateCliquesResidual1;

protected function selectNonFlows
  input list<Integer> rows;
  input list<Boolean> flowFlag;
  input list<Integer> iAcc;
  output list<Integer> oAcc;
algorithm
  oAcc := match(rows,flowFlag,iAcc)
    local
      Integer r;
      list<Integer> rest;
      list<Boolean> brest;
    case({},_,_)
      then
        iAcc;
    case(r::rest,false::brest,_)
      then
        selectNonFlows(rest,brest,r::iAcc); 
    case(_::rest,true::brest,_)
      then
        selectNonFlows(rest,brest,iAcc); 
  end match;
end selectNonFlows;

protected function generateCliquesResidual2
"function generateCliquesResidual2
  author: Frenkel TUD 2012-05"
  input list<Integer> eqns;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input Integer orphan;
  input Integer eqn;
algorithm
  _ := matchcontinue(eqns,ass1,ass2,m,mt,mark,rowmarks,colummarks,orphan,eqn)
    local
      Integer o,c1,e,r;
      list<Integer> rest,next,olst,elst,lst,rlst,lst1;
    case ({},_,_,_,_,_,_,_,_,_)
      then
        ();
    case (r::rest,_,_,_,_,_,_,_,_,_)
      equation
        false = intEq(rowmarks[r],mark);
        // marked?
        e = ass1[r];
        rlst = ass2[e];
        lst = List.fold1(rlst,List.removeOnTrue, intEq, m[e]);
        (lst1 as _::_) = List.select2(lst, unmarked, rowmarks, mark-1);
        // print("generateClique " +& intString(eqn) +& " to " +& stringDelimitList(List.map(lst1,intString),", ") +& "\n");
        List.map4_0(lst1,generateResidualClique,m,mt,orphan,e);
        List.map2_0(rlst,doMark,rowmarks,mark);
        lst = List.select2(lst, marked, rowmarks, mark-1);
        // print("Go From " +& intString(e) +& " to " +& stringDelimitList(List.map(r,intString),", ") +& "\n");
        _ = arrayUpdate(colummarks,e,mark);
        // print("Go From " +& intString(e) +& " to " +& stringDelimitList(List.map(next,intString),", ") +& "\n");
        generateCliquesResidual2(lst,ass1,ass2,m,mt,mark,rowmarks,colummarks,orphan,e); 
        generateCliquesResidual2(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,orphan,eqn); 
      then
        ();
    case (_::rest,_,_,_,_,_,_,_,_,_)
      equation
        generateCliquesResidual2(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,orphan,eqn); 
      then
        ();
  end matchcontinue;
end generateCliquesResidual2;


protected function prepairOrphansOrder
"function prepairOrphansOrder
  author: Frenkel TUD 2012-07"
  input list<Integer> inOrphans;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input array<list<Integer>> orphans;
  input BackendDAE.Variables vars;  
  input list<Integer> iroots;
  input list<Integer> iconstraints;
  output Integer omark;
  output list<Integer> oroots;
  output list<Integer> oconstraints;
algorithm
  (omark,oroots,oconstraints) := matchcontinue(inOrphans,ass1,ass2,m,mt,mark,rowmarks,colummarks,orphans,vars,iroots,iconstraints)
    local
      list<Integer> rest,roots,constraints,elst,rlst;
      Integer o,c,mark;
      Boolean foundflow,constr;
      list<Boolean> blst;
      list<BackendDAE.Var> vlst;      
    case ({},_,_,_,_,_,_,_,_,_,_,_)
      then
       (mark,iroots,iconstraints);
    case (o::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        false = intEq(rowmarks[o],mark);
        _ = arrayUpdate(rowmarks,o,mark);
        elst = mt[o];
        rlst = List.flatten(List.map1r(elst,arrayGet,ass2));
        //  BackendDump.debuglst((rlst,intString,", ","\n"));
        vlst = List.map1r(rlst,BackendVariable.getVarAt,vars);
        blst = List.map(vlst,BackendVariable.isFlowVar);
        constr = Util.boolAndList(blst);        
        constraints = List.consOnTrue(constr, o, iconstraints);
        //  print("Process Orphan " +& intString(o) +& "\n");
        //  BackendDump.debuglst((mt[o],intString,", ","\n"));
        foundflow = prepairOrphansOrder1(mt[o],ass1,ass2,m,mt,mark,rowmarks,colummarks,o,orphans,{o},false,vars);
        roots = List.consOnTrue(foundflow and not constr, o, iroots);
        (mark,roots,constraints) = prepairOrphansOrder(rest,ass1,ass2,m,mt,mark+1,rowmarks,colummarks,orphans,vars,roots,constraints);
      then
       (mark,roots,constraints);
    case (_::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        (mark,roots,constraints) = prepairOrphansOrder(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,orphans,vars,iroots,iconstraints); 
      then
        (mark,roots,constraints);
  end matchcontinue;
end prepairOrphansOrder;

protected function prepairOrphansOrder1
"function prepairOrphansOrder1
  author: Frenkel TUD 2012-05"
  input list<Integer> eqns;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input Integer preorphan;
  input array<list<Integer>> orphans;
  input list<Integer> prer;
  input Boolean ifoundFlow;
  input BackendDAE.Variables vars;
  output Boolean ofoundFlow;  
algorithm
  ofoundFlow := matchcontinue(eqns,ass1,ass2,m,mt,mark,rowmarks,colummarks,preorphan,orphans,prer,ifoundFlow,vars)
    local
      Integer o,c1,e;
      list<Integer> rest,next,olst,r,elst,lst;
      Boolean b,b1;
      list<Boolean> blst;
      list<BackendDAE.Var> vlst;      
    case ({},_,_,_,_,_,_,_,_,_,_,_,_)
      then
        ifoundFlow;
    case (e::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        //  print("check Eqn " +& intString(e)  +& " ass[e]: " +& stringDelimitList(List.map(ass2[e],intString),", ") +& "\n");
        false = intEq(colummarks[e],mark);
        // remove orphans
        next = List.select1(m[e],isNoOrphan,ass1);
        // remove visited
        next = List.select2(next, unmarked, rowmarks, mark);
        // remove assigned
        next = List.fold1(ass2[e],List.removeOnTrue, intEq, next);
        //  print("Used Vars of " +& intString(e) +& " : " +& stringDelimitList(List.map(next,intString),", ") +& "\n");
        true = intGt(listLength(next),0);
      then
        prepairOrphansOrder1(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,preorphan,orphans,prer,ifoundFlow,vars); 
    case (e::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        false = intEq(colummarks[e],mark);
        // remove orphans
        next = List.select1(m[e],isNoOrphan,ass1);
        // remove visited
        next = List.select2(next, unmarked, rowmarks, mark);
        // remove assigned
        next = List.fold1(ass2[e],List.removeOnTrue, intEq, next);
        false = intGt(listLength(next),0);
        _ = arrayUpdate(colummarks,e,mark);
        r = ass2[e];
        // print("Go From " +& intString(e) +& " to " +& stringDelimitList(List.map(r,intString),", ") +& "\n");
        List.map2_0(r,doMark,rowmarks,mark);
        elst = List.select1(List.map1r(r,arrayGet,ass1),intGt,0);
        next = List.flatten(List.map1r(r,arrayGet,mt));
        next = List.fold1(elst,List.removeOnTrue, intEq, next);
        List.map2_0(r,addPreOrphan,preorphan,orphans);
        vlst = List.map1r(r,BackendVariable.getVarAt,vars);
        blst = List.map(vlst,BackendVariable.isFlowVar);
        b1 = Util.boolOrList(blst);        
        // print("Go From " +& intString(e) +& " to " +& stringDelimitList(List.map(next,intString),", ") +& "\n");
        b = prepairOrphansOrder1(next,ass1,ass2,m,mt,mark,rowmarks,colummarks,preorphan,orphans,r,b1 or ifoundFlow,vars); 
      then
        prepairOrphansOrder1(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,preorphan,orphans,prer,b,vars); 
    case (e::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      then
        prepairOrphansOrder1(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,preorphan,orphans,prer,ifoundFlow,vars); 
  end matchcontinue;
end prepairOrphansOrder1;

protected function prepairOrphansOrder2
"function prepairOrphansOrder2
  author: Frenkel TUD 2012-07"
  input list<Integer> inOrphans;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer imark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input array<list<Integer>> orphans;
  output Integer omark;
algorithm
  omark := matchcontinue(inOrphans,ass1,ass2,m,mt,imark,rowmarks,colummarks,orphans)
    local
      list<Integer> rest;
      array<Integer> sorphans;
      Integer o,c;
    case ({},_,_,_,_,_,_,_,_)
      then
       imark;
    case (o::rest,_,_,_,_,_,_,_,_)
      equation
        false = intEq(rowmarks[o],imark);
        _ = arrayUpdate(rowmarks,o,imark);
        //  print("Process Orphan " +& intString(o) +& "\n");
        //  BackendDump.debuglst((mt[o],intString,", ","\n"));
        prepairOrphansOrder3(mt[o],ass1,ass2,m,mt,imark,rowmarks,colummarks,o,orphans,{o});
       then
        prepairOrphansOrder2(rest,ass1,ass2,m,mt,imark+1,rowmarks,colummarks,orphans); 
    case (_::rest,_,_,_,_,_,_,_,_)
      then
        prepairOrphansOrder2(rest,ass1,ass2,m,mt,imark,rowmarks,colummarks,orphans); 
  end matchcontinue;
end prepairOrphansOrder2;

protected function prepairOrphansOrder3
"function prepairOrphansOrder3
  author: Frenkel TUD 2012-05"
  input list<Integer> eqns;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input Integer preorphan;
  input array<list<Integer>> orphans;
  input list<Integer> prer;
algorithm
  _ := matchcontinue(eqns,ass1,ass2,m,mt,mark,rowmarks,colummarks,preorphan,orphans,prer)
    local
      Integer o,c1,e;
      list<Integer> rest,next,olst,r,elst,lst;
    case ({},_,_,_,_,_,_,_,_,_,_)
      then
        ();
    case (e::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        false = intEq(colummarks[e],mark);
        // marked?
        r = ass2[e];
        lst = List.unique(List.flatten(List.map1r(r,arrayGet,orphans)));
        true = listMember(preorphan,lst);      
        _ = arrayUpdate(colummarks,e,mark);
        // print("Go From " +& intString(e) +& " to " +& stringDelimitList(List.map(r,intString),", ") +& "\n");
        List.map2_0(r,doMark,rowmarks,mark);
        elst = List.select1(List.map1r(r,arrayGet,ass1),intGt,0);
        next = List.flatten(List.map1r(r,arrayGet,mt));
        next = List.fold1(elst,List.removeOnTrue, intEq, next);
        // print("Go From " +& intString(e) +& " to " +& stringDelimitList(List.map(next,intString),", ") +& "\n");
        prepairOrphansOrder3(next,ass1,ass2,m,mt,mark,rowmarks,colummarks,preorphan,orphans,r); 
        prepairOrphansOrder3(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,preorphan,orphans,prer); 
      then
        ();
    case (e::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        //  print("check Eqn " +& intString(e)  +& " ass[e]: " +& stringDelimitList(List.map(ass2[e],intString),", ") +& "\n");
        false = intEq(colummarks[e],mark);
        // update Incidence Matrix
        List.map4_0(prer,generateClique,m,mt,preorphan,e);
        prepairOrphansOrder3(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,preorphan,orphans,prer); 
      then
        ();
    case (e::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        prepairOrphansOrder3(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,preorphan,orphans,prer); 
      then
        ();
  end matchcontinue;
end prepairOrphansOrder3;

protected function generateClique
  input Integer r;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer preorphan;
  input Integer e;
protected
  list<Integer> lst;
algorithm
  //  print("Replace " +& intString(r) +& " with " +& intString(preorphan) +& "\n");
  lst := mt[r];
  // mt[r]-e
  lst := List.removeOnTrue(e, intEq, lst);
  //  print("mt[ " +& intString(r) +& "]= " +& stringDelimitList(List.map(lst,intString),", ") +& "\n");
  _ := arrayUpdate(mt,r,lst);
  // mt[preorphan]+e
  lst := mt[preorphan];
  lst := List.unique(e::lst);
  //  print("mt[ " +& intString(preorphan) +& "]= " +& stringDelimitList(List.map(lst,intString),", ") +& "\n");
  _ := arrayUpdate(mt,preorphan,lst);
  // m[e] - r + preorphan
  lst := m[e];
  lst := List.removeOnTrue(r, intEq, lst);
  lst := List.unique(preorphan::lst);
  //  print("m[ " +& intString(e) +& "]= " +& stringDelimitList(List.map(lst,intString),", ") +& "\n");
  _ := arrayUpdate(m,e,lst);
end generateClique;


protected function generateResidualClique
  input Integer r;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer orphan;
  input Integer e;
protected
  list<Integer> lst;
algorithm
  //  print("Replace " +& intString(e) +& " with " +& intString(orphan) +& "\n");
  lst := m[e];
  // mt[e]-r
  lst := List.removeOnTrue(r, intEq, lst);
  //  print("m[ " +& intString(e) +& "]= " +& stringDelimitList(List.map(lst,intString),", ") +& "\n");
  _ := arrayUpdate(m,e,lst);
  // m[orphan]+r
  lst := m[orphan];
  lst := List.unique(r::lst);
  //  print("m[ " +& intString(orphan) +& "]= " +& stringDelimitList(List.map(lst,intString),", ") +& "\n");
  _ := arrayUpdate(m,orphan,lst);
  // mt[r] - e + orphan
  lst := mt[r];
  lst := List.removeOnTrue(e, intEq, lst);
  lst := List.unique(orphan::lst);
  //  print("mt[ " +& intString(r) +& "]= " +& stringDelimitList(List.map(lst,intString),", ") +& "\n");
  _ := arrayUpdate(mt,r,lst);
end generateResidualClique;

protected function getOrphansOrderEdvanced
"function getOrphansOrderEdvanced
  author: Frenkel TUD 2012-07"
  input list<Integer> inOrphans;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input array<list<Integer>> orphans;
  output Integer omark;
algorithm
  omark := matchcontinue(inOrphans,ass1,ass2,m,mt,mark,rowmarks,colummarks,orphans)
    local
      list<Integer> rest;
      array<Integer> sorphans;
      Integer o,c,mark1;
    case ({},_,_,_,_,_,_,_,_)
      then
       mark;
    case (o::rest,_,_,_,_,_,_,_,_)
      equation
        false = intEq(rowmarks[o],mark);
        _ = arrayUpdate(rowmarks,o,mark);
        //  print("Process Orphan " +& intString(o) +& "\n");
        getOrphansOrderEdvanced1(mt[o],ass1,ass2,m,mt,mark,rowmarks,colummarks,o,orphans,{});
      then
        getOrphansOrderEdvanced(rest,ass1,ass2,m,mt,mark+1,rowmarks,colummarks,orphans); 
    case (_::rest,_,_,_,_,_,_,_,_)
      then
        getOrphansOrderEdvanced(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,orphans); 
  end matchcontinue;
end getOrphansOrderEdvanced;

protected function hasOrphanEdvanced
"function hasOrphanEdvanced
  author: Frenkel TUD 2012-07"
  input list<Integer> rows;
  input array<Integer> ass1;
  input list<Integer> iAcc;
  output list<Integer> oAcc;
algorithm
  oAcc := matchcontinue(rows,ass1,iAcc)
    local
      list<Integer> rest,olst;
      Integer r,o;
    case ({},_,_::_)
      then
        iAcc;
    case (r::rest,_,_)
      equation
        false = intGt(ass1[r],0);
      then
        hasOrphanEdvanced(rest,ass1,r::iAcc);
    case (_::rest,_,_)
      then 
        hasOrphanEdvanced(rest,ass1,iAcc);
  end matchcontinue;
end hasOrphanEdvanced;

protected function hasOrphanEdvanced1
"function hasOrphanEdvanced does not look backward
  author: Frenkel TUD 2012-07"
  input Integer r;
  input array<Integer> ass1;
  input Integer preorphan;
  input array<list<Integer>> orphans;
  output list<Integer> Orphan;
algorithm
  Orphan := matchcontinue(r,ass1,preorphan,orphans)
    local
      list<Integer> rest,olst;
      Integer o;
    case (r,_,_,_)
      equation
        false = intEq(r,preorphan);
        false = intGt(ass1[r],0);
      then
        {r};
    case (r,_,_,_)
      equation
        false = intEq(r,preorphan);
        true = intGt(ass1[r],0);
        olst = orphans[r]; 
        (olst as _::_) = List.removeOnTrue(preorphan, intEq, olst);
      then
        olst;
  end matchcontinue;
end hasOrphanEdvanced1;

protected function addPreOrphan
  input Integer orphan;
  input Integer preorphan;
  input array<list<Integer>> arr;
protected 
  list<Integer> olst;
algorithm
  //  print("Add orpan[" +& intString(orphan) +& "] = " +& intString(preorphan) +& "\n");
  olst := arr[orphan];
  olst := List.union({preorphan}, olst);
  _:=arrayUpdate(arr,orphan,olst);
end addPreOrphan;

protected function addPreOrphans
  input Integer orphan;
  input list<Integer> preorphans;
  input array<list<Integer>> arr;
protected 
  list<Integer> olst;
algorithm
  _:=match(orphan,preorphans,arr)
    local
      Integer o;
      list<Integer> rest;
    case(_,{},_) then ();
    case(_,o::rest,_)
      equation
        addPreOrphan(orphan,o,arr);
        addPreOrphans(orphan,rest,arr);
      then
        ();
  end match;
end addPreOrphans;

protected function getOrphansOrderEdvanced1
"function getOrphansOrderEdvanced1
  author: Frenkel TUD 2012-07"
  input list<Integer> eqns;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input Integer preorphan;
  input array<list<Integer>> orphans;
  input list<Integer> nextQueue;
algorithm
  _ := matchcontinue(eqns,ass1,ass2,m,mt,mark,rowmarks,colummarks,preorphan,orphans,nextQueue)
    local
      Integer c1,e;
      list<Integer> rest,next,r,r1,elst,olst;
    case ({},_,_,_,_,_,_,_,_,_,{})
      then
        ();
    case ({},_,_,_,_,_,_,_,_,_,_)
      equation
        getOrphansOrderEdvanced1(nextQueue,ass1,ass2,m,mt,mark,rowmarks,colummarks,preorphan,orphans,{});
      then
        ();
    case (e::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        // print("Check Eqn: " +& intString(e) +& "\n");
        false = intEq(colummarks[e],mark);
        r = List.removeOnTrue(preorphan, intEq, m[e]) "vars of equation without preorphan";
        //  print("search in " +& stringDelimitList(List.map(r,intString),", ") +& "\n");
        olst = hasOrphanEdvanced(r,ass1,{});
        _ = arrayUpdate(colummarks,e,mark);
        //  print("Found Orphans " +& stringDelimitList(List.map(olst,intString),", ") +& " ChildOrphan is " +& intString(preorphan) +& "\n");
        addPreOrphans(preorphan,olst,orphans);
      then
        ();
    case (e::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        false = intEq(colummarks[e],mark);
        r = List.removeOnTrue(preorphan, intEq, m[e]) "vars of equation";
        r1 = List.select1(ass2[e], intGt,0) "vars assignt with equation"; 
        r = List.fold1(r1,List.removeOnTrue, intEq, r) "needed vars of equation";
        elst = List.select1(List.map1r(r,arrayGet,ass1),intGt,0) "equations assigned with needed vars";
        next = listAppend(nextQueue, elst);
        _ = arrayUpdate(colummarks,e,mark);
        //  print("goto " +& stringDelimitList(List.map(next,intString),", ") +& "\n");
        getOrphansOrderEdvanced1(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,preorphan,orphans,next); 
      then
        ();
    case (_::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        getOrphansOrderEdvanced1(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,preorphan,orphans,nextQueue); 
      then
       ();       
  end matchcontinue;
end getOrphansOrderEdvanced1;

protected function isrootOrphan
  input Integer orphan;
  input array<list<Integer>> vorphansarray;
  input list<Integer> roots;
  output list<Integer> oroots;
algorithm
  oroots := matchcontinue(orphan,vorphansarray,roots)
    case (_,_,_)
      equation
        {} = vorphansarray[orphan];
      then
        orphan::roots; 
    case (_,_,_) then roots;
  end matchcontinue;
end isrootOrphan;


protected function getConstraintesOrphansOrderEdvanced
"function getOrphansOrderEdvanced
  author: Frenkel TUD 2012-07"
  input list<Integer> inOrphans;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input array<list<Integer>> orphans;
  output Integer omark;
algorithm
  omark := matchcontinue(inOrphans,ass1,ass2,m,mt,mark,rowmarks,colummarks,orphans)
    local
      list<Integer> rest;
      array<Integer> sorphans;
      Integer o,c,mark1;
    case ({},_,_,_,_,_,_,_,_)
      then
       mark;
    case (o::rest,_,_,_,_,_,_,_,_)
      equation
        false = intEq(rowmarks[o],mark);
        _ = arrayUpdate(rowmarks,o,mark);
          print("Process Orphan " +& intString(o) +& "\n");
        getConstraintesOrphansOrderEdvanced1(mt[o],ass1,ass2,m,mt,mark,rowmarks,colummarks,o,orphans,{});
      then
        getConstraintesOrphansOrderEdvanced(rest,ass1,ass2,m,mt,mark+1,rowmarks,colummarks,orphans); 
    case (_::rest,_,_,_,_,_,_,_,_)
      then
        getConstraintesOrphansOrderEdvanced(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,orphans); 
  end matchcontinue;
end getConstraintesOrphansOrderEdvanced;

protected function getConstraintesOrphansOrderEdvanced1
"function getConstraintesOrphansOrderEdvanced1
  author: Frenkel TUD 2012-07"
  input list<Integer> eqns;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input Integer preorphan;
  input array<list<Integer>> orphans;
  input list<Integer> nextQueue;
algorithm
  _ := matchcontinue(eqns,ass1,ass2,m,mt,mark,rowmarks,colummarks,preorphan,orphans,nextQueue)
    local
      Integer c1,e;
      list<Integer> rest,next,r,r1,elst,olst;
    case ({},_,_,_,_,_,_,_,_,_,{})
      then
        ();
    case ({},_,_,_,_,_,_,_,_,_,_)
      equation
        getConstraintesOrphansOrderEdvanced1(nextQueue,ass1,ass2,m,mt,mark,rowmarks,colummarks,preorphan,orphans,{});
      then
        ();
    case (e::rest,_,_,_,_,_,_,_,_,_,_)
      equation
         print("Check Eqn: " +& intString(e) +& "\n");
        false = intEq(colummarks[e],mark);
        r = List.removeOnTrue(preorphan, intEq, m[e]) "vars of equation without preorphan";
          print("search in " +& stringDelimitList(List.map(r,intString),", ") +& "\n");
        olst = hasOrphanEdvanced(r,ass1,{});
        _ = arrayUpdate(colummarks,e,mark);
          print("Found Orphans " +& stringDelimitList(List.map(olst,intString),", ") +& " ChildOrphan is " +& intString(preorphan) +& "\n");
        addPreOrphans(preorphan,olst,orphans);
        r1 = ass2[e] "vars assignt with equation"; 
        r = List.fold1(r1,List.removeOnTrue, intEq, r) "needed vars of equation";
        elst = List.select1(List.map1r(r,arrayGet,ass1),intGt,0) "equations assigned with needed vars";
        next = listAppend(nextQueue, elst);
        _ = arrayUpdate(colummarks,e,mark);
        getConstraintesOrphansOrderEdvanced1(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,preorphan,orphans,next); 
      then
        ();
    case (e::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        false = intEq(colummarks[e],mark);
        r = List.removeOnTrue(preorphan, intEq, m[e]) "vars of equation";
        r1 = ass2[e] "vars assignt with equation"; 
        r = List.fold1(r1,List.removeOnTrue, intEq, r) "needed vars of equation";
        elst = List.select1(List.map1r(r,arrayGet,ass1),intGt,0) "equations assigned with needed vars";
        next = listAppend(nextQueue, elst);
        _ = arrayUpdate(colummarks,e,mark);
          print("goto " +& stringDelimitList(List.map(next,intString),", ") +& "\n");
        getConstraintesOrphansOrderEdvanced1(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,preorphan,orphans,next); 
      then
        ();
    case (_::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        getConstraintesOrphansOrderEdvanced1(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,preorphan,orphans,nextQueue); 
      then
       ();       
  end matchcontinue;
end getConstraintesOrphansOrderEdvanced1;

protected function getOrphansOrderEdvanced4
  input list<Integer> orphans;
  input array<list<Integer>> vorphansarray;
  input array<list<Integer>> vorphansarrayT;
  input Integer mark;
  input array<Integer> rowmarks;  
  input list<Integer> nextQueue;
  input list<Integer> queue;
  input list<Integer> links;
  output list<Integer> order;
  output list<Integer> linksorder;
algorithm
  (order,linksorder) := match(orphans,vorphansarray,vorphansarrayT,mark,rowmarks,nextQueue,queue,links)
    local
      Integer orphan;
      list<Integer> rest,nextorphans,lst,queue1,links1;
      Boolean b,marked,allmarked;
    case ({},_,_,_,_,{},_,_) then (queue,links);
    case ({},_,_,_,_,_,_,_)
      equation
        (queue1,links1) = getOrphansOrderEdvanced4(nextQueue,vorphansarray,vorphansarrayT,mark,rowmarks,{},queue,links);
      then
        (queue1,links1);
    case (orphan::rest,_,_,_,_,_,_,_)
      equation
        //  print("Process " +& intString(orphan) +& "\n");
        marked = intEq(rowmarks[orphan],mark);
        _ = arrayUpdate(rowmarks,orphan,mark);
        // is not a link
        lst = Util.if_(marked,{},vorphansarray[orphan]);
        b = intLt(listLength(lst),2);
        // if allready visited stop
        nextorphans = Util.if_(marked,{},vorphansarrayT[orphan]);
        nextorphans = List.select2(nextorphans, unmarked, rowmarks, mark);
        // if a link wait until all marked
        lst = List.select2(lst, unmarked, rowmarks, mark);
        allmarked = intEq(listLength(lst),0);
        //  print("Marked: " +& boolString(marked) +& " no Link: " +& boolString(b) +& " AllMarked " +& boolString(allmarked) +& "\n");
        // take next orphans
        nextorphans = listReverse(nextorphans);
        nextorphans = Debug.bcallret2(allmarked, listAppend, nextorphans, nextQueue, nextQueue);
        //   print("nextorphans: " +& stringDelimitList(List.map(nextorphans,intString),", ") +& "\n");
        // add to list if no link
        queue1 = List.consOnTrue(b and not marked, orphan, queue);
        // add to list if link
        links1 = List.consOnTrue(not b and not marked, orphan, links);
        //   print("queue1: " +& stringDelimitList(List.map(queue1,intString),", ") +& "\n");
        (queue1,links1) = getOrphansOrderEdvanced4(rest,vorphansarray,vorphansarrayT,mark,rowmarks,nextorphans,queue1,links1);
      then
        (queue1,links1);       
  end match;
end getOrphansOrderEdvanced4;

protected function getOrphansOrderEdvanced6
  input list<Integer> orphans;
  input array<list<Integer>> vorphansarray;
  input Integer mark;
  input array<Integer> rowmarks;  
  input list<Integer> nextQueue;
  input list<Integer> roots;
  output list<Integer> outroots;
algorithm
  outroots := match(orphans,vorphansarray,mark,rowmarks,nextQueue,roots)
    local
      Integer orphan;
      list<Integer> rest,nextorphans,roots1;
      Boolean b,marked,link;
    case ({},_,_,_,{},_) then roots;
    case ({},_,_,_,_,_)
      then
        getOrphansOrderEdvanced6(nextQueue,vorphansarray,mark,rowmarks,{},roots);
    case (orphan::rest,_,_,_,_,_)
      equation
        marked = intEq(rowmarks[orphan],mark);
        _ = arrayUpdate(rowmarks,orphan,mark);
        // root 
        nextorphans = vorphansarray[orphan];
        b = intEq(listLength(nextorphans),0);
        link = intGt(listLength(nextorphans),1);
        // if allready visited stop
        nextorphans = Debug.bcallret4(not marked and not link, List.select2, nextorphans, unmarked, rowmarks, mark,{});
         // take next orphans
        nextorphans = Debug.bcallret2(not marked and not link, listAppend, nextorphans, nextQueue, nextQueue);
        roots1 = List.consOnTrue(b or link, orphan, roots);
      then
        getOrphansOrderEdvanced6(rest,vorphansarray,mark,rowmarks,nextorphans,roots1);    
  end match;
end getOrphansOrderEdvanced6;

protected function getOrphansOrderEdvanced9
  input list<Integer> order;
  input Integer link;  
  input Integer preorphan;
  input list<Integer> inAcc;
  output list<Integer> outorder;
algorithm
  outorder := match(order,link,preorphan,inAcc)
    local
      Integer orphan;
      list<Integer> rest;
    // Error case
    case ({},_,_,_)
       then
         fail();
    // insert
    case (orphan::rest,_,_,_)
      equation
        true = intEq(orphan,preorphan);
      then
        listAppend(listReverse(orphan::inAcc),link::rest);
    // next
    case (orphan::rest,_,_,_)
      then
        getOrphansOrderEdvanced9(rest,link,preorphan,orphan::inAcc);
  end match;
end getOrphansOrderEdvanced9;

protected function getOrphansOrderEdvanced8
  input list<Integer> orphans;
  input array<list<Integer>> vorphansarrayT;
  input Integer link;  
  input list<Integer> order;
  input Integer preorphan;
  output list<Integer> outorder;
algorithm
  outorder := match(orphans,vorphansarrayT,link,order,preorphan)
    local
      Integer orphan;
    // Error case
    case ({},_,_,_,_)
       then
         fail();
    // no cross go to next
    case (orphan::{},_,_,_,_)
       then
         getOrphansOrderEdvanced8(vorphansarrayT[orphan],vorphansarrayT,link,order,orphan);
    // append after cross
    case (_,_,_,_,_) 
      then
        getOrphansOrderEdvanced9(order,link,preorphan,{});
  end match;
end getOrphansOrderEdvanced8;

protected function getOrphansOrderEdvanced7
  input list<Integer> roots;
  input array<list<Integer>> vorphansarrayT;
  input Integer mark;
  input array<Integer> rowmarks;
  input Integer link;  
  input list<Integer> order;
  output list<Integer> outorder;
algorithm
  outorder := match(roots,vorphansarrayT,mark,rowmarks,link,order)
    local
      Integer orphan;
    // one root go upwards until first cross
    case (orphan::{},_,_,_,_,_) 
      then 
        getOrphansOrderEdvanced8(vorphansarrayT[orphan],vorphansarrayT,link,order,orphan);
    // append in frond
    case (_,_,_,_,_,_) then listAppend(order,{link});
  end match;
end getOrphansOrderEdvanced7;

protected function getOrphansOrderEdvanced5
  input list<Integer> links;
  input array<list<Integer>> vorphansarray;
  input array<list<Integer>> vorphansarrayT;
  input Integer mark;
  input array<Integer> rowmarks;  
  input list<Integer> order;
  output list<Integer> outorder;
  output Integer omark;
algorithm
  (outorder,omark) := match(links,vorphansarray,vorphansarrayT,mark,rowmarks,order)
    local
      Integer orphan,mark1;
      list<Integer> rest,roots,order1;
    case ({},_,_,_,_,_) then (order,mark);
    case (orphan::rest,_,_,_,_,_)
      equation
        //  print("Process Link " +& intString(orphan) +& "\n");
        // build subgraph and collect marked roots
        _ = arrayUpdate(rowmarks,orphan,mark);
        roots = getOrphansOrderEdvanced6(vorphansarray[orphan],vorphansarray,mark,rowmarks,{},{});
        //  print("Roots: " +& stringDelimitList(List.map(roots,intString),", ") +& "\n");
        // get a cuddly place for the link in the list
        order1 = getOrphansOrderEdvanced7(roots,vorphansarrayT,mark,rowmarks,orphan,order); 
        (order1,mark1) = getOrphansOrderEdvanced5(rest,vorphansarray,vorphansarrayT,mark+1,rowmarks,order1);
      then
        (order1,mark1);       
  end match;
end getOrphansOrderEdvanced5;

protected function getChilds
  input Integer orphan;
  input array<list<Integer>> vorphansarrayT;
  output tuple<Integer,list<Integer>> childs;
algorithm
  childs := (orphan,vorphansarrayT[orphan]);
end getChilds;

protected function sortChilds1
  input list<Integer> alst;
  input list<Integer> blst;
  output Boolean b;
algorithm
  b := matchcontinue(alst,blst)
    local
      Integer a;
      list<Integer> rest;
    case ({},_) then true;
    case (a::rest,_)
      equation
        true = listMember(a,blst);
      then
        sortChilds1(rest,blst);
    else
      then 
        false;
  end matchcontinue;
end sortChilds1;

protected function sortChilds
  input tuple<Integer,list<Integer>> a;
  input tuple<Integer,list<Integer>> b;
  output Boolean b;
algorithm
  b := sortChilds1(Util.tuple22(a),Util.tuple22(b));
end sortChilds;

protected function getInvMap
  input Integer orphan;
  input array<Integer> invmap;
  input Integer index;
  output Integer oindex;
algorithm
  _:=arrayUpdate(invmap,orphan,index);
  oindex := index+1;
end getInvMap;

protected function getOrphansIncidenceMatrix
  input list<Integer> orphans;
  input array<Integer> invmap;
  input array<list<Integer>> vorphansarray;
  input array<list<Integer>> vorphansarrayT;
  input list<list<Integer>> m;
  input array<list<Integer>> mT;
  input Boolean addself;
  output array<list<Integer>> outM;
  output array<list<Integer>> outMT;
algorithm
  (outM,outMT) := match(orphans,invmap,vorphansarray,vorphansarrayT,m,mT,addself)
    local
      Integer o,i;
      list<Integer> rest,lst;
      array<list<Integer>> am,amT;
    case ({},_,_,_,_,_,_)
      then
        (listArray(listReverse(m)),mT);
    case (o::rest,_,_,_,_,_,_)
      equation
        //  print("getOrphansIncidenceMatrix for " +& intString(o) +& "\n");
        lst = List.map1r(vorphansarray[o],arrayGet,invmap);
        i = invmap[o];
        lst = List.consOnTrue(addself,i,lst);
        amT = List.fold1(lst,Util.arrayCons,i,mT);
        (am,amT) = getOrphansIncidenceMatrix(rest,invmap,vorphansarray,vorphansarrayT,lst::m,amT,addself);
      then
        (am,amT);   
  end match;
end getOrphansIncidenceMatrix;

protected function getOrder
  input list<Integer> comp;
  input tuple<list<Integer>,list<list<Integer>>> inorder;
  output tuple<list<Integer>,list<list<Integer>>> outorder;
algorithm
  outorder := match(comp,inorder)
    local
      Integer o;
      list<Integer> order;
      list<list<Integer>> links;
    case (o::{},(order,links)) then ((o::order,links));
    case (_,(order,links)) then ((order,comp::links));
  end match;
end getOrder;

protected function getOrphansOrderEdvanced3
  input list<Integer> vorphans;
  input array<list<Integer>> vorphansarray;
  input array<list<Integer>> vorphansarrayT;
  input Integer mark;
  input array<Integer> rowmarks;
  output list<Integer> sortvorphans;
  output Integer omark;
protected
  list<Integer> roots,order,leafs;
  list<tuple<Integer,list<Integer>>> childlist;
  Integer size;
  array<Integer> map,ass,invmap;
  array<List<Integer>> m,mt;
  list<Integer> range,links;
  list<list<Integer>> comps,linkslst;
algorithm
  // get root orphans
  roots := List.fold1(vorphans,isrootOrphan,vorphansarray,{});
    print("Roots: " +& stringDelimitList(List.map(roots,intString),", ") +& "\n");
  // get strong connected parts  
  size := listLength(vorphans);
  map := listArray(vorphans);
    print("map\n");
    BackendDump.dumpMatching(map);
  invmap := arrayCreate(arrayLength(vorphansarray),0);
  _ := List.fold1(vorphans,getInvMap,invmap,1);
  //  print("invmap\n");
  //  BackendDump.dumpMatching(invmap);
  range := List.intRange(size);
  (m,mt) := getOrphansIncidenceMatrix(vorphans,invmap,vorphansarray,vorphansarrayT,{},arrayCreate(size,{}),true);
    BackendDump.dumpIncidenceMatrix(m);  
    BackendDump.dumpIncidenceMatrixT(mt);  
  ass := listArray(range);
  comps := BackendDAETransform.tarjanAlgorithm(m, mt, ass, ass);
    BackendDump.dumpComponentsOLD(comps);
  ((order,linkslst)) := List.fold(comps,getOrder,({},{}));  
    print("order: " +& stringDelimitList(List.map(order,intString),", ") +& "\n");
    print("Links\n");
    BackendDump.dumpComponentsOLD(linkslst);
  (m,mt) := getOrphansIncidenceMatrix(vorphans,invmap,vorphansarray,vorphansarrayT,{},arrayCreate(size,{}),false);
  //  BackendDump.dumpIncidenceMatrix(m);
  //  BackendDump.dumpIncidenceMatrixT(mt); 
  reduceOrphancMatrix(listReverse(comps),m);
  //  BackendDump.dumpIncidenceMatrix(m);
//true := false;
  //(order,links) := getOrphansOrderEdvanced4(roots,vorphansarray,vorphansarrayT,mark,rowmarks,{},{},{});  
  omark := mark + 1;
  // add links to the order
  links := List.flatten(linkslst);
  (sortvorphans,omark) := getOrphansOrderEdvanced5(links,vorphansarray,vorphansarrayT,omark,rowmarks,order);
  // map back to global indexes
  sortvorphans := List.map1r(sortvorphans,arrayGet,map);
  //  print("sortvorphans: " +& stringDelimitList(List.map(sortvorphans,intString),", ") +& "\n");
end getOrphansOrderEdvanced3;

protected function reduceOrphancMatrix
  input list<list<Integer>> comps;
  input array<list<Integer>> m;
algorithm
  _ := match(comps,m)
    local
      Integer c;
      list<Integer> comp;
      list<list<Integer>> rest;
    case({},_) then ();
    case((c::{})::rest,_)
      equation
        reduceOrphancMatrix(rest,m);
      then
        ();   
    case(comp::rest,_)
      equation
        reduceOrphancMatrix1(comp,comp,m);
        reduceOrphancMatrix(rest,m);
      then
        ();   
  end match;
end reduceOrphancMatrix;

protected function reduceOrphancMatrix1
  input list<Integer> comps;
  input list<Integer> comps1;
  input array<list<Integer>> m;
algorithm
  _ := match(comps,comps1,m)
    local
      Integer c;
      list<Integer> rest,lst;
    case({},_,_) then ();
    case(c::rest,_,_)
      equation
        lst = m[c];
        lst = List.setDifference(lst,comps1);
        _=arrayUpdate(m,c,lst);
        reduceOrphancMatrix1(rest,comps1,m);
      then
        ();   
  end match;
end reduceOrphancMatrix1;

protected function getOrphansOrder
"function getOrphansOrder
  author: Frenkel TUD 2012-05"
  input list<Integer> inOrphans;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input array<Integer> columorphans;
  input array<Integer> inSOrphans;
  output Integer omark;
algorithm
  omark := matchcontinue(inOrphans,ass1,ass2,m,mt,mark,rowmarks,colummarks,columorphans,inSOrphans)
    local
      list<Integer> rest;
      array<Integer> sorphans;
      Integer o,c;
    case ({},_,_,_,_,_,_,_,_,_)
      then
       mark;
    case (o::rest,_,_,_,_,_,_,_,_,_)
      equation
        false = intEq(rowmarks[o],mark);
        _ = arrayUpdate(rowmarks,o,mark);
        //  print("Process Orphan " +& intString(o) +& "\n");
        getOrphansOrder1(mt[o],ass1,ass2,m,mt,mark,rowmarks,colummarks,o,columorphans,inSOrphans,{},true);
      then
        getOrphansOrder(rest,ass1,ass2,m,mt,mark+1,rowmarks,colummarks,columorphans,inSOrphans); 
    case (_::rest,_,_,_,_,_,_,_,_,_)
      then
        getOrphansOrder(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,columorphans,inSOrphans); 
  end matchcontinue;
end getOrphansOrder;

protected function assignedEqnOfVar
"function assignedEqnOfVar
  author: Frenkel TUD 2012-05"
  input list<Integer> colums;
  input array<Integer> ass2;
  output Integer outRow;
algorithm
  outRow := matchcontinue(colums,ass2)
    local
      list<Integer> rest;
      Integer c,r;
    case (c::rest,_)
      equation
        r = ass2[c];
        true = intGt(r,0);
      then
        c;
    case (_::rest,_)
      then 
        assignedEqnOfVar(rest,ass2);
  end matchcontinue;
end assignedEqnOfVar;

protected function getOrphansOrder1
"function getOrphansOrder1
  author: Frenkel TUD 2012-05"
  input list<Integer> eqns;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input Integer preorphan;
  input array<Integer> columorphans;
  input array<Integer> inSOrphans;
  input list<Integer> nextQueue;
  input Boolean reverseMode;
algorithm
  _ := matchcontinue(eqns,ass1,ass2,m,mt,mark,rowmarks,colummarks,preorphan,columorphans,inSOrphans,nextQueue,reverseMode)
    local
      Integer o,r,c1,e;
      list<Integer> rest,next;
    case ({},_,_,_,_,_,_,_,_,_,_,{},_)
      then
        ();
    case ({},_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // print("Run Next Queue\n");
        getOrphansOrder1(nextQueue,ass1,ass2,m,mt,mark,rowmarks,colummarks,preorphan,columorphans,inSOrphans,{},reverseMode); 
      then
        ();
    case (e::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // print("Check Eqn: " +& intString(e) +& "\n");
        false = intEq(colummarks[e],mark);
        o = hasOrphan(m[e],ass1,preorphan);
        // is not my pre orphan
        false = intEq(o,preorphan);
        _ = arrayUpdate(colummarks,e,mark);
        //  print("Found Orphan " +& intString(o) +& " PreOrphan is " +& intString(preorphan) +& "\n");
        addOrphanOrder(inSOrphans,preorphan,o);
      then
        ();
    case (e::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        false = intEq(colummarks[e],mark);
        r = ass2[e];
        next = neededVarofEqn(m[e],{r},preorphan,ass1,nextQueue);
        // print("reverseMode " +& boolString(reverseMode) +& " Next: " +& boolString((not reverseMode) or (intGt(listLength(next),0))) +& "\n");
        true = (not reverseMode) or (intGt(listLength(next),0));
        _ = arrayUpdate(colummarks,e,mark);
          print("goto " +& intString(ass2[e]) +& "\n");
        getOrphansOrder1(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,preorphan,columorphans,inSOrphans,next,false); 
      then
        ();
    case (e::rest,_,_,_,_,_,_,_,_,_,_,_,true)
      equation
        false = intEq(colummarks[e],mark);
        r = ass2[e];
        next = neededVarofEqn(m[e],{r},preorphan,ass1,nextQueue);
        // print("reverseMode " +& boolString(reverseMode) +& " Next: " +& intString(listLength(next)) +& "\n");
        false = (not reverseMode) or (intGt(listLength(next),0));
        r = ass2[e];
        false = intEq(r, preorphan);
        e = ass1[r];
        // eqns of var withoud assigned
        // print("Go From " +& intString(r) +& " to all other withoud " +& intString(e) +& "\n");
        next = List.removeOnTrue(e, intEq, mt[r]);
        next = listAppend(next,nextQueue);
        _ = arrayUpdate(colummarks,e,mark);
        //  print("goto " +& intString(r) +& "\n");
        getOrphansOrder1(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,preorphan,columorphans,inSOrphans,next,reverseMode); 
      then
        ();        
    case (_::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        getOrphansOrder1(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,preorphan,columorphans,inSOrphans,nextQueue,reverseMode); 
      then
       ();       
  end matchcontinue;
end getOrphansOrder1;

protected function unmarkedEqnofVar
"function unmarkedEqnofVar
  author: Frenkel TUD 2012-05"
  input list<Integer> colums;
  input Integer mark;
  input array<Integer> colummarks;
  output Integer outRow;
algorithm
  outRow := matchcontinue(colums,mark,colummarks)
    local
      list<Integer> rest;
      Integer c;
    case (c::rest,_,_)
      equation
        false = intEq(colummarks[c],mark);
      then
        c;
    case (_::rest,_,_)
      then 
        unmarkedEqnofVar(rest,mark,colummarks);
  end matchcontinue;
end unmarkedEqnofVar;

protected function addOrphanOrder
"function addOrphanOrder
  author: Frenkel TUD 2012-05"
  input array<Integer> inSOrphans;
  input Integer preorphan;
  input Integer orphan;
algorithm
  //  print("Add Orphan " +& intString(orphan) +& " with pre " +& intString(preorphan) +& "\n");
  _ := arrayUpdate(inSOrphans,preorphan,orphan);
end addOrphanOrder; 

protected function getOrphansOrder3
"function getOrphansOrder3
  author: Frenkel TUD 2012-05"
  input list<Integer> orphans;
  input array<list<Integer>> varray;
  input array<Integer> varrayT;
  input Integer mark;
  input array<Integer> rowmarks;
  input list<Integer> inSOrphans;
  output list<Integer> outSOrphans;  
algorithm
  outSOrphans := matchcontinue(orphans,varray,varrayT,mark,rowmarks,inSOrphans)
    local
      list<Integer> rest,sorphans;
      Integer o,p;
      Boolean b,b1;
    case ({},_,_,_,_,_)
      then
        inSOrphans;
    case (o::rest,_,_,_,_,_)
      equation
        false = intEq(mark,rowmarks[o]);
        // print("Process Orphan " +& intString(o) +& "\n");
        sorphans = getOrphansOrder5(o,varrayT,mark,rowmarks,inSOrphans);
        _ = arrayUpdate(rowmarks,o,mark-1);
        sorphans = getOrphansOrder4(o,varray,mark,rowmarks,sorphans);
        b = intEq(listLength(inSOrphans),listLength(sorphans));
        b1 = not listMember(o,sorphans);
        sorphans = Debug.bcallret2(b and b1,List.appendElt,o,sorphans,sorphans);
      then
        getOrphansOrder3(rest,varray,varrayT,mark,rowmarks,sorphans);
    case (_::rest,_,_,_,_,_)
      then
        getOrphansOrder3(rest,varray,varrayT,mark,rowmarks,inSOrphans);
  end matchcontinue;
end getOrphansOrder3;

protected function getOrphansOrder4
"function getOrphansOrder4
  author: Frenkel TUD 2012-05"
  input Integer orphan;
  input array<list<Integer>> varray;
  input Integer mark;
  input array<Integer> rowmarks;
  input list<Integer> inSOrphans;
  output list<Integer> outSOrphans;  
algorithm
  outSOrphans := matchcontinue(orphan,varray,mark,rowmarks,inSOrphans)
    local
      list<Integer> sorphans;
      Integer p;
    case (_,_,_,_,_)
      equation
        true = intGt(orphan,0);
        false = intEq(mark,rowmarks[orphan]);
        _ = arrayUpdate(rowmarks,orphan,mark);
      then
        getOrphansOrder41(orphan,varray[orphan],varray,mark,rowmarks,inSOrphans);
    case (_,_,_,_,_)
      then
        inSOrphans;
  end matchcontinue;
end getOrphansOrder4;

protected function getOrphansOrder41
"function getOrphansOrder41
  author: Frenkel TUD 2012-05"
  input Integer orphan;
  input list<Integer> plst;
  input array<list<Integer>> varray;
  input Integer mark;
  input array<Integer> rowmarks;
  input list<Integer> inSOrphans;
  output list<Integer> outSOrphans;  
algorithm
  outSOrphans := matchcontinue(orphan,plst,varray,mark,rowmarks,inSOrphans)
    local
      list<Integer> sorphans,rest;
      Integer p;
    case (_,{},_,_,_,_) then inSOrphans;
    case (_,p::rest,_,_,_,_)
      equation
        true = intGt(p,0);
        // print("Add Orphan " +& intString(orphan) +& " with pre " +& intString(p) +& "\n");
        sorphans = addOrphanOrder1(inSOrphans,p,orphan,{});
        // print("New Orphans:\n");
        // BackendDump.debuglst((sorphans,intString,", ","\n"));        
        sorphans = getOrphansOrder4(p,varray,mark,rowmarks,sorphans);
      then
        getOrphansOrder41(orphan,rest,varray,mark,rowmarks,sorphans);
    case (_,_::rest,_,_,_,_)
      then
        getOrphansOrder41(orphan,rest,varray,mark,rowmarks,inSOrphans);
  end matchcontinue;
end getOrphansOrder41;

protected function getOrphansOrder5
"function getOrphansOrder5
  author: Frenkel TUD 2012-05"
  input Integer orphan;
  input array<Integer> varrayT;
  input Integer mark;
  input array<Integer> rowmarks;
  input list<Integer> inSOrphans;
  output list<Integer> outSOrphans;  
algorithm
  outSOrphans := matchcontinue(orphan,varrayT,mark,rowmarks,inSOrphans)
    local
      list<Integer> sorphans;
      Integer o;
    case (_,_,_,_,_)
      equation
        true = intGt(orphan,0);
        false = intEq(mark,rowmarks[orphan]);
        _ = arrayUpdate(rowmarks,orphan,mark);
        o = varrayT[orphan];
        true = intGt(o,0);
        // print("Add Orphan " +& intString(orphan) +& " with suc " +& intString(o) +& "\n");
        sorphans = addOrphanOrder1(inSOrphans,orphan,o,{});
        // print("New Orphans1:\n");
        // BackendDump.debuglst((sorphans,intString,", ","\n"));        
      then
        getOrphansOrder5(o,varrayT,mark,rowmarks,sorphans);
    case (_,_,_,_,_)
      equation
        true = intGt(orphan,0);
        false = intEq(mark,rowmarks[orphan]);
      then
        getOrphansOrder5(varrayT[orphan],varrayT,mark,rowmarks,inSOrphans);
    case (_,_,_,_,_)
      then
        inSOrphans;
  end matchcontinue;
end getOrphansOrder5;

protected function addOrphanOrder1
"function addOrphanOrder1
  author: Frenkel TUD 2012-05"
  input list<Integer> inSOrphans;
  input Integer preorphan;
  input Integer orphan;
  input list<Integer> inAcc;
  output list<Integer> outSOrphans;
algorithm
  outSOrphans := matchcontinue(inSOrphans,preorphan,orphan,inAcc)
    local 
      list<Integer> rest,sorphan;
      Integer o;
    case ({},_,_,_)
       //equation
       //  print("Orphans {" +& intString(preorphan) +& ", " +& intString(orphan) +& "}\n");    
      then
        listAppend({preorphan,orphan},listReverse(inAcc));
    case (o::rest,_,_,_)
      equation
        true = intEq(o,preorphan);
        sorphan = listAppend(listReverse(inAcc),preorphan::(orphan::rest));
        // print("Orphans:\n");
        // BackendDump.debuglst((sorphan,intString,", ","\n"));
      then 
        sorphan;
    case (o::rest,_,_,_)
      equation
        true = intEq(o,orphan);
        sorphan = listAppend(listReverse(inAcc),preorphan::inSOrphans);
        // print("Orphans1:\n");
        // BackendDump.debuglst((sorphan,intString,", ","\n"));
      then 
        sorphan;

    case (o::rest,_,_,_)
      then
        addOrphanOrder1(rest,preorphan,orphan,o::inAcc);
  end matchcontinue;
end addOrphanOrder1;

protected function hasOrphan
"function hasOrphan
  author: Frenkel TUD 2012-05"
  input list<Integer> rows;
  input array<Integer> ass1;
  input Integer preorphan;
  output Integer Orphan;
algorithm
  Orphan := matchcontinue(rows,ass1,preorphan)
    local
      list<Integer> rest;
      Integer r;
    case (r::_,_,_)
      equation
        false = intEq(r,preorphan);
        false = intGt(ass1[r],0);
      then
        r;
    case (_::rest,_,_)
      then 
        hasOrphan(rest,ass1,preorphan);
  end matchcontinue;
end hasOrphan;

protected function hasResidualOrphan
"function hasResidualOrphan
  author: Frenkel TUD 2012-07"
  input list<Integer> eqns;
  input array<list<Integer>> ass;
  output Integer Orphan;
algorithm
  Orphan := matchcontinue(eqns,ass)
    local
      list<Integer> rest;
      Integer e;
    case (e::_,_)
      equation
        {} = ass[e];
      then
        e;
    case (_::rest,_)
      then 
        hasResidualOrphan(rest,ass);
  end matchcontinue;
end hasResidualOrphan;

protected function neededVarofEqn
"function neededVarofEqn
  author: Frenkel TUD 2012-05"
  input list<Integer> rows;
  input list<Integer> assrow;
  input Integer preorphan;
  input array<Integer> ass1;
  input list<Integer> queue;
  output list<Integer> outRow;
algorithm
  outRow := matchcontinue(rows,assrow,preorphan,ass1,queue)
    local
      list<Integer> rest,next;
      Integer r,e;
    case ({},_,_,_,_)
      then
        queue;
    case (r::rest,_,_,_,_)
      equation
        false = listMember(r,assrow);
        false = intEq(r,preorphan);
        e = ass1[r];
        next = List.consOnTrue(intGt(e,0), e, queue);
      then
        neededVarofEqn(rest,assrow,preorphan,ass1,next);
    case (_::rest,_,_,_,_)
      then 
        neededVarofEqn(rest,assrow,preorphan,ass1,queue);        
  end matchcontinue;
end neededVarofEqn;

protected function makeCrefExps
"function makeCrefExps
  author: Frenkel TUD 2012-05"
  input BackendDAE.Var v;
  output DAE.Exp e;
algorithm
  e := Expression.crefExp(BackendVariable.varCref(v));
end makeCrefExps;

protected function makeGausEliminationRow
"function makeGausEliminationRow
  author: Frenkel TUD 2012-05"
  input list<tuple<Integer,DAE.Exp>> lst;
  input Integer size;
  input array<DAE.Exp> vars;
  input DAE.Exp inExp;
  output DAE.Exp outExp;
  output DAE.Exp outExp1;
algorithm
  (outExp,outExp1) := matchcontinue(lst,size,vars,inExp)
    local
      Integer c;
      DAE.Exp e,e1,b;
      list<tuple<Integer,DAE.Exp>> rest;
    case ({},_,_,_)
      then
        (inExp,DAE.RCONST(0.0));        
    case ((c,e)::rest,_,_,_)
      equation
        true = intGt(c,size);
      then
        (inExp,e);
    case ((c,e)::rest,_,_,_)
      equation
        e1 = Expression.expMul(e,vars[c]);
        e1 = Expression.expAdd(e1,inExp);
        //  BackendDump.debugStrExpStrExpStr(("",inExp," => ",e1,"\n"));
        (e1,b) = makeGausEliminationRow(rest,size,vars,e1); 
      then
        (e1,b);
  end matchcontinue;
end makeGausEliminationRow;

protected function makeGausElimination
"function makeGausElimination
  author: Frenkel TUD 2012-05"
  input Integer row;
  input Integer size;
  input array<list<tuple<Integer,DAE.Exp>>> matrix;
  input array<DAE.Exp> vars;
  input list<BackendDAE.Equation> iAcc;
  output list<BackendDAE.Equation> oAcc;
algorithm
  oAcc := matchcontinue(row,size,matrix,vars,iAcc)
    local
      DAE.Exp e,b;
      BackendDAE.Equation eqn;
    case (_,_,_,_,_)
      equation
        true = intGt(row,size);
      then
        listReverse(iAcc);
    case (_,_,_,_,_)
      equation
        (e,b) = makeGausEliminationRow(matrix[row],size,vars,DAE.RCONST(0.0));
        //(e,_) = ExpressionSimplify.simplify(e);
        //(b,_) = ExpressionSimplify.simplify(b);
        //  BackendDump.debugStrExpStrExpStr(("",e," = ",b,"\n"));
        eqn = BackendDAE.EQUATION(e,b,DAE.emptyElementSource);
      then
        makeGausElimination(row+1,size,matrix,vars,eqn::iAcc);
  end matchcontinue;
end makeGausElimination;

protected function dumpMatrix1
"function dumpMatrix1
  author: Frenkel TUD 2012-05"
  input tuple<Integer,DAE.Exp> inTpl;
  output String s;
protected
  Integer c;
  DAE.Exp e;
  String cs,es;
algorithm
  (c,e) := inTpl;
  cs := intString(c);
  es := ExpressionDump.printExpStr(e);
  s := stringAppendList({cs,":",es});
end dumpMatrix1;

protected function dumpMatrix
"function dumpMatrix
  author: Frenkel TUD 2012-05"
  input Integer row;
  input Integer size;
  input array<list<tuple<Integer,DAE.Exp>>> matrix;
algorithm
  _ := matchcontinue(row,size,matrix)
    local
      String estr;
      Integer c,r;
      DAE.Exp e;
      BackendDAE.Var v;
      list<tuple<Integer, Integer, BackendDAE.Equation>> rest;
      DAE.ComponentRef cr;
    case (_,_,_)
      equation
        true = intGt(row,size);
      then
        ();
    case (_,_,_)
      equation
        print(intString(row) +& ": ");
        BackendDump.debuglst((matrix[row],dumpMatrix1,", ","\n"));
        dumpMatrix(row+1,size,matrix);
      then
        ();
   end matchcontinue;
end dumpMatrix;

protected function addRows
"function addRows
  author: Frenkel TUD 2012-05"
  input list<tuple<Integer,DAE.Exp>> inA;
  input list<tuple<Integer,DAE.Exp>> inB;
  input Integer col;
  input BackendDAE.Variables inVars "temporary variables";
  input BackendDAE.EquationArray inEqns "temporary equations";
  input tuple<Integer,Integer> inTpl;
  input list<tuple<Integer,DAE.Exp>> inElst;
  output list<tuple<Integer,DAE.Exp>> outElst;
  output BackendDAE.Variables outVars "temporary variables";
  output BackendDAE.EquationArray outEqns "temporary equations";
  output tuple<Integer,Integer> outTpl;
algorithm
  (outElst,outVars,outEqns,outTpl) := matchcontinue(inA,inB,col,inVars,inEqns,inTpl,inElst)
    local
      Integer ca,cb;
      DAE.Exp ea,eb,e;
      list<tuple<Integer,DAE.Exp>> resta,restb,elst;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      tuple<Integer,Integer> tpl;
    case ({},{},_,_,_,_,_)
      then
        (listReverse(inElst),inVars,inEqns,inTpl);
    case ({},_,_,_,_,_,_)
      then
        (listAppend(listReverse(inElst),inB),inVars,inEqns,inTpl);
    case (_,{},_,_,_,_,_)
      then
        (listAppend(listReverse(inElst),inA),inVars,inEqns,inTpl);
    case ((ca,ea)::resta,(cb,eb)::restb,_,_,_,_,_)
      equation
        true = intEq(ca,cb);
        true = intEq(ca,col);
        (elst,vars,eqns,tpl) = addRows(resta,restb,col,inVars,inEqns,inTpl,inElst); 
      then
        (elst,vars,eqns,tpl);
    case ((ca,ea)::resta,(cb,eb)::restb,_,_,_,_,_)
      equation
        true = intEq(ca,cb);
        e = Expression.expAdd(ea,eb);
        (e,_) = ExpressionSimplify.simplify(e);
        (vars,eqns,e,tpl) = makeDummyVar(inTpl,e,inVars,inEqns);
        (elst,vars,eqns,tpl) = addRows(resta,restb,col,vars,eqns,tpl,(ca,e)::inElst); 
      then
        (elst,vars,eqns,tpl);
    case ((ca,ea)::resta,(cb,eb)::restb,_,_,_,_,_)
      equation
        true = intGt(ca,cb);
        true = intEq(cb,col);
        (elst,vars,eqns,tpl) = addRows(inA,restb,col,inVars,inEqns,inTpl,inElst); 
      then
        (elst,vars,eqns,tpl);
    case ((ca,ea)::resta,(cb,eb)::restb,_,_,_,_,_)
      equation
        true = intGt(ca,cb);
        (elst,vars,eqns,tpl) = addRows(inA,restb,col,inVars,inEqns,inTpl,(cb,eb)::inElst); 
      then
        (elst,vars,eqns,tpl);
    case ((ca,ea)::resta,(cb,eb)::restb,_,_,_,_,_)
      equation
        true = intLt(ca,cb);
        true = intEq(ca,col);
        (elst,vars,eqns,tpl) = addRows(resta,inB,col,inVars,inEqns,inTpl,inElst); 
      then
        (elst,vars,eqns,tpl);
    case ((ca,ea)::resta,(cb,eb)::restb,_,_,_,_,_)
      equation
        true = intLt(ca,cb);
        (elst,vars,eqns,tpl) = addRows(resta,inB,col,inVars,inEqns,inTpl,(ca,ea)::inElst); 
      then
        (elst,vars,eqns,tpl);
  end matchcontinue;  
end addRows;

protected function mulRow
"function mulRow
  author: Frenkel TUD 2012-05"
  input tuple<Integer,DAE.Exp> inTpl;
  input DAE.Exp e1;
  output tuple<Integer,DAE.Exp> outTpl;
protected
  DAE.Exp e;
  Integer c;
algorithm
  (c,e) := inTpl;
  e := Expression.negate(Expression.expMul(e,e1));
  //(e,_) := ExpressionSimplify.simplify(e);
  outTpl := (c,e);
end mulRow;

protected function removeFromCol
"function removeFromCol
  author: Frenkel TUD 2012-05"
  input Integer i;
  input list<tuple<Integer,DAE.Exp>> inTpl;
  input list<tuple<Integer,DAE.Exp>> inAcc;
  output list<tuple<Integer,DAE.Exp>> outAcc;
algorithm
  outAcc := matchcontinue(i,inTpl,inAcc)
    local
      DAE.Exp e;
      Integer c;
      list<tuple<Integer,DAE.Exp>> rest,acc;
      case (_,{},_)
        then
          listReverse(inAcc);
      case (_,(c,e)::rest,_)
        equation
          true = intEq(i,c);
          acc = listReverse(inAcc);
          acc = listAppend(acc,rest);
        then 
          acc;
      case (_,(c,e)::rest,_)
        then 
          removeFromCol(i,rest,(c,e)::inAcc);
  end matchcontinue;
end removeFromCol;

protected function makeDummyVar
"function makeDummyVar
  author: Frenkel TUD 2012-05"
  input tuple<Integer,Integer> inTpl;
  input DAE.Exp e;
  input BackendDAE.Variables inVars "temporary variables";
  input BackendDAE.EquationArray inEqns "temporary equations";
  output BackendDAE.Variables outVars "temporary variables";
  output BackendDAE.EquationArray outEqns "temporary equations";
  output DAE.Exp outExp;
  output tuple<Integer,Integer> outTpl;
algorithm
  (outVars,outEqns,outExp,outTpl) := matchcontinue(inTpl,e,inVars,inEqns)
    local
      DAE.ComponentRef cr;
      BackendDAE.Var v;
      String sa,sb;
      Integer a,b; 
      BackendDAE.EquationArray eqns;
      BackendDAE.Variables vars;
      DAE.Exp cexp;
    case (_,DAE.CREF(componentRef=_),_,_)
      then
        (inVars,inEqns,e,inTpl);
    case (_,DAE.UNARY(exp=DAE.CREF(componentRef=_)),_,_)
      then
        (inVars,inEqns,e,inTpl);
    case (_,DAE.RCONST(real=_),_,_)
      then
        (inVars,inEqns,e,inTpl);
    case (_,_,_,_)
      equation
        true = Expression.isConst(e);
      then
        (inVars,inEqns,e,inTpl);
    case((a,b),_,_,_)
      equation     
      sa = intString(a);
      sb = intString(b);
      cr = ComponentReference.makeCrefIdent(stringAppendList({"$tmp",sa,"_",sb}),DAE.T_REAL_DEFAULT,{});
      cexp = Expression.crefExp(cr);
      eqns = BackendEquation.equationAdd(BackendDAE.EQUATION(cexp,e,DAE.emptyElementSource),inEqns);
      v = BackendDAE.VAR(cr,BackendDAE.VARIABLE(),DAE.BIDIR(),DAE.NON_PARALLEL(),DAE.T_REAL_DEFAULT,NONE(),NONE(),{},-1,DAE.emptyElementSource,NONE(),NONE(),DAE.NON_CONNECTOR(),DAE.NON_STREAM_CONNECTOR());
      vars = BackendVariable.addVar(v,inVars);
    then
      (vars,eqns,cexp,(a,b+1));
  end matchcontinue;
end makeDummyVar;

protected function gaussElimination1
"function gaussElimination1
  author: Frenkel TUD 2012-05"
  input Integer col;
  input Integer row;
  input Integer size;
  input DAE.Exp ce;
  input array<list<tuple<Integer,DAE.Exp>>> matrix;
  input BackendDAE.Variables inVars "temporary variables";
  input BackendDAE.EquationArray inEqns "temporary equations";
  input tuple<Integer,Integer> inTpl;
  output BackendDAE.Variables outVars "temporary variables";
  output BackendDAE.EquationArray outEqns "temporary equations";
  output tuple<Integer,Integer> outTpl;
algorithm
  (outVars,outEqns,outTpl) := matchcontinue (col,row,size,ce,matrix,inVars,inEqns,inTpl)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;    
      DAE.Exp e,e1,cexp;  
      list<tuple<Integer,DAE.Exp>> elst;
       tuple<Integer,Integer> tpl;
    case (_,_,_,_,_,_,_,_)
      equation
        true = intGt(row,size);
      then
        (inVars,inEqns,inTpl);
    case(_,_,_,_,_,_,_,_)
      equation
        SOME(e) = diagonalEntry(col,matrix[row]);
        //  print("Found entriy in " +& intString(row) +& "\n");
        //  BackendDump.debuglst((matrix[row],dumpMatrix1,", ","\n"));       
        e1 = Expression.expDiv(e,ce);
        (e1,_) = ExpressionSimplify.simplify(e1);
        (vars,eqns,cexp,tpl) = makeDummyVar(inTpl,e1,inVars,inEqns);
        elst = matrix[col];
        elst = List.map1(elst,mulRow,cexp);
        //  print("mulRow " +& intString(col) +& " with " +& ExpressionDump.printExpStr(e1) +& "\n");
        //  BackendDump.debuglst((elst,dumpMatrix1,", ","\n"));        
        (elst,vars,eqns,tpl) = addRows(matrix[row],elst,col,vars,eqns,tpl,{});
        //  print("addRow\n");
        //  BackendDump.debuglst((elst,dumpMatrix1,", ","\n"));    
        //elst = removeFromCol(col,elst,{});    
        _ = arrayUpdate(matrix,row,elst);        
        (vars,eqns,tpl) = gaussElimination1(col,row+1,size,ce,matrix,vars,eqns,tpl);
      then
        (vars,eqns,tpl);
    case(_,_,_,_,_,_,_,_)
      equation
        (vars,eqns,tpl) = gaussElimination1(col,row+1,size,ce,matrix,inVars,inEqns,inTpl);
      then
        (vars,eqns,tpl);
  end matchcontinue;
end gaussElimination1;

protected function gaussElimination
"function gaussElimination
  author: Frenkel TUD 2012-05"
  input Integer col;
  input Integer size;
  input array<list<tuple<Integer,DAE.Exp>>> matrix;
  input BackendDAE.Variables inVars "temporary variables";
  input BackendDAE.EquationArray inEqns "temporary equations";
  input tuple<Integer,Integer> inTpl;
  output BackendDAE.Variables outVars "temporary variables";
  output BackendDAE.EquationArray outEqns "temporary equations";
algorithm
  (outVars,outEqns) := matchcontinue (col,size,matrix,inVars,inEqns,inTpl)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      DAE.Exp e;      
      tuple<Integer,Integer> tpl;
    case (_,_,_,_,_,_)
      equation
        true = intGt(col,size);
      then
        (inVars,inEqns);
    case(_,_,_,_,_,_)
      equation
        SOME(e) = diagonalEntry(col,matrix[col]);
        //  print("Jacobian as Matrix " +& intString(col) +& "\n");
        //  BackendDump.debuglst((matrix[col],dumpMatrix1,", ","\n"));
        (vars,eqns,tpl) = gaussElimination1(col,col+1,size,e,matrix,inVars,inEqns,inTpl);
        //  dumpMatrix(1,size,matrix);
        (vars,eqns) = gaussElimination(col+1,size,matrix,vars,eqns,tpl);
      then
        (vars,eqns);
    case(_,_,_,_,_,_)
      equation
        NONE() = diagonalEntry(col,matrix[col]);
        print("gaussElimination failt because of non diagonal Entry for col " +& intString(col) +& "\n");
      then
        fail();        
  end matchcontinue;
end gaussElimination;

protected function diagonalEntry
" function diagonalEntry
  author: Frenkel TUD
  check if row has an entry col, if not
  then it fails"
  input Integer col;
  input list<tuple<Integer,DAE.Exp>> row;
  output Option<DAE.Exp> e;
algorithm
  e := matchcontinue(col,row)
    local
      list<tuple<Integer,DAE.Exp>> rest;
      Integer r;
      DAE.Exp e;
    case (_,(r,e)::_)
      equation
        true = intEq(r,col);
        false = Expression.isZero(e);
      then
        SOME(e);
    case (_,(r,_)::_)
      equation
        true = intGt(r,col);
      then
        NONE();
    case (_,_::rest)
      then
        diagonalEntry(col,rest);
  end matchcontinue;
end diagonalEntry;

protected function isConstOneMinusOne
" function isConstOneMinusOne
  author: Frenkel TUD
  return true if inExp is 1 or -1"
  input DAE.Exp inExp;
  output Boolean b;
algorithm
  b := Expression.isConstOne(inExp) or Expression.isConstMinusOne(inExp);
end isConstOneMinusOne;


protected function transformJacToIncidenceMatrix2
" function transformJacToIncidenceMatrix2
  author: Frenkel TUD
  transforms only array equations"
  input list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
  input BackendDAE.IncidenceMatrix m;
  input array<Integer> mapIncRowEqn;
  input BackendDAE.EquationArray eqns;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input CompareFunc func;
  partial function CompareFunc
    input DAE.Exp inExp;
    output Boolean outBool;
  end CompareFunc;  
algorithm
 _ := match(jac,m,mapIncRowEqn,eqns,ass1,ass2,func)
    local
      Integer c,r,i;
      DAE.Exp e;
      Boolean b,b1,b2;
      list<tuple<Integer, Integer, BackendDAE.Equation>> rest;
      list<Integer> lst;
      BackendDAE.Equation eqn;
    case ({},_,_,_,_,_,_)
      then ();
    case ((r,c,BackendDAE.RESIDUAL_EQUATION(exp = e))::rest,_,_,_,_,_,_)
      equation
        i = mapIncRowEqn[r];
        eqn = BackendDAEUtil.equationNth(eqns, i-1);
        b1 = BackendEquation.isArrayEquation(eqn);
        b = func(e);
        lst = List.consOnTrue(b and b1, c, m[r]);
        _ = arrayUpdate(m,r,lst);
        transformJacToIncidenceMatrix2(rest,m,mapIncRowEqn,eqns,ass1,ass2,func);
      then
        ();
   end match;
end transformJacToIncidenceMatrix2;

protected function transformJacToIncidenceMatrix1
" function transformJacToIncidenceMatrix1
  author: Frenkel TUD
  transforms only not assigned equations"
  input list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
  input BackendDAE.IncidenceMatrix m;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input CompareFunc func;
  partial function CompareFunc
    input DAE.Exp inExp;
    output Boolean outBool;
  end CompareFunc;  
algorithm
 _ := match(jac,m,ass1,ass2,func)
    local
      Integer c,r;
      DAE.Exp e;
      Boolean b,b1;
      list<tuple<Integer, Integer, BackendDAE.Equation>> rest;
      list<Integer> lst;
    case ({},_,_,_,_)
      then ();
    case ((r,c,BackendDAE.RESIDUAL_EQUATION(exp = e))::rest,_,_,_,_)
      equation
        b1 = intLt(ass1[c],1);
        b = func(e);
        lst = List.consOnTrue(b and b1, c, m[r]);
        _ = arrayUpdate(m,r,lst);
        transformJacToIncidenceMatrix1(rest,m,ass1,ass2,func);
      then
        ();
   end match;
end transformJacToIncidenceMatrix1;

protected function transformJacToIncidenceMatrix
" function transformJacToIncidenceMatrix
  author: Frenkel TUD"
  input list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input CompareFunc func;
  partial function CompareFunc
    input DAE.Exp inExp;
    output Boolean outBool;
  end CompareFunc;  
algorithm
 _ := matchcontinue(jac,m,mT,func)
    local
      Integer c,r;
      DAE.Exp e;
      Boolean b;
      list<tuple<Integer, Integer, BackendDAE.Equation>> rest;
      list<Integer> lst,lst1;
    case ({},_,_,_)
      equation
        transformJacToIncidenceMatrix(jac,m,mT,func);
      then ();
    case ((r,c,BackendDAE.RESIDUAL_EQUATION(exp = e))::rest,_,_,_)
      equation
        b = func(e);
        lst = List.consOnTrue(b, c, m[r]);
        lst1 = List.consOnTrue(b, r, mT[c]);
        _ = arrayUpdate(m,r,lst);
        _ = arrayUpdate(mT,c,lst1);
        transformJacToIncidenceMatrix(rest,m,mT,func);
      then
        ();        
   end matchcontinue;
end transformJacToIncidenceMatrix;

protected function transformJacToMatrix
  input list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
  input Integer row;
  input Integer col;
  input Integer size;
  input list<DAE.Exp> b;
  input array<list<tuple<Integer,DAE.Exp>>> matrix;
algorithm
 _ := matchcontinue(jac,row,col,size,b,matrix)
    local
      Integer c,r;
      DAE.Exp e,be;
      list<DAE.Exp> b1;
      list<tuple<Integer, Integer, BackendDAE.Equation>> rest;
      list<tuple<Integer,DAE.Exp>> lst;
    case (_,_,_,_,_,_)
      equation
        true = intGt(row,size);
      then
        ();
    case (_,_,_,_,_,_)
      equation
        true = intGt(col,size);
        be::b1 = b;
        lst = matrix[row];
        lst = List.consOnTrue(not Expression.isZero(be), (col,be), lst);
        lst = listReverse(lst);
        _ = arrayUpdate(matrix,row,lst);
        transformJacToMatrix(jac,row+1,1,size,b1,matrix);
      then
        ();
    case ({},_,_,_,_,_)
      equation
        transformJacToMatrix(jac,row,col+1,size,b,matrix);
      then ();
    case ((r,c,BackendDAE.RESIDUAL_EQUATION(exp = e))::rest,_,_,_,_,_)
      equation
        true = intEq(r,row);
        true = intEq(c,col);
        lst = matrix[r];
        lst = (c,e)::lst;
        _ = arrayUpdate(matrix,row,lst);
        transformJacToMatrix(rest,row,col+1,size,b,matrix);
      then
        ();
    case ((r,c,_)::rest,_,_,_,_,_)
      equation
        true = intEq(r,row);
        true = intLt(col,c);
        transformJacToMatrix(jac,row,col+1,size,b,matrix);
      then
        ();        
    case ((r,c,_)::rest,_,_,_,_,_)
      equation
        false = intEq(r,row);
        transformJacToMatrix(jac,row,col+1,size,b,matrix);
      then
        ();          
   end matchcontinue;
end transformJacToMatrix;

public function dumpJacMatrix
  input list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
  input Integer row;
  input Integer col;
  input Integer size;
  input BackendDAE.Variables vars;
algorithm
  _ := matchcontinue(jac,row,col,size,vars)
    local
      String estr;
      Integer c,r;
      DAE.Exp e;
      BackendDAE.Var v;
      list<tuple<Integer, Integer, BackendDAE.Equation>> rest;
      DAE.ComponentRef cr;
    case (_,_,_,_,_)
      equation
        true = intGt(row,size);
      then
        ();
    case (_,_,_,_,_)
      equation
        true = intGt(col,size);
        v = BackendVariable.getVarAt(vars,row);
        cr = BackendVariable.varCref(v);
        print(";... % ");
        print(intString(row));
        print(" ");
        print(ComponentReference.printComponentRefStr(cr)); print("\n");
        dumpJacMatrix(jac,row+1,1,size,vars);
      then
        ();
    case ({},_,_,_,_)
      equation
        print("0,");
        dumpJacMatrix(jac,row,col+1,size,vars);
      then ();
    case ((r,c,BackendDAE.RESIDUAL_EQUATION(exp = e))::rest,_,_,_,_)
      equation
        true = intEq(r,row);
        true = intEq(c,col);
        estr = ExpressionDump.printExpStr(e);
        print(estr); print(",");
        dumpJacMatrix(rest,row,col+1,size,vars);
      then
        ();
    case ((r,c,_)::rest,_,_,_,_)
      equation
        true = intEq(r,row);
        true = intLt(col,c);
        print("0,");
        dumpJacMatrix(jac,row,col+1,size,vars);
      then
        ();        
    case ((r,c,_)::rest,_,_,_,_)
      equation
        false = intEq(r,row);
        print("0,");
        dumpJacMatrix(jac,row,col+1,size,vars);
      then
        ();          
   end matchcontinue;
end dumpJacMatrix;

protected function dumpOrphansPairs
  input tuple<Integer,list<tuple<Integer,Integer>>> orphanspairs;
protected
  Integer c;
  list<tuple<Integer,Integer>> tpl;
algorithm
  (c,tpl) := orphanspairs;
  print(intString(c) +& ":\n");
  BackendDump.debuglst((tpl,dumpOrphansPairs1,", ","\n"));
end dumpOrphansPairs;

protected function dumpOrphansPairs1
  input tuple<Integer,Integer> orphanspair;
  output String s;
protected
  Integer r,d;
  String rs,ds;
algorithm
  (r,d) := orphanspair;
  rs := intString(r);
  ds := intString(d);
  s := stringAppendList({rs,":",ds});
end dumpOrphansPairs1;

protected function getEqnsinOrder
  input Integer indx;
  input tuple<BackendDAE.EquationArray,BackendDAE.Variables,array<list<Integer>>,BackendDAE.EquationArray,BackendDAE.Variables> inTpl;
  output tuple<BackendDAE.EquationArray,BackendDAE.Variables,array<list<Integer>>,BackendDAE.EquationArray,BackendDAE.Variables> outTpl;
protected
 BackendDAE.Equation e;
 BackendDAE.EquationArray eqns,eqnssort;
 array<list<Integer>> ass2;
 list<BackendDAE.Var> vlst;
 BackendDAE.Variables vars,varssort;
 list<Integer> vindxs;
algorithm
 (eqns,vars,ass2,eqnssort,varssort) := inTpl;
 // get Eqn
 e := BackendDAEUtil.equationNth(eqns,indx-1);
 // add equation
 eqnssort := BackendEquation.equationAdd(e, eqnssort);
 // get vars of equations
 vindxs := ass2[indx];
 vlst := List.map1r(vindxs,BackendVariable.getVarAt,vars); 
 vlst := sortVarsforOrder(e,vlst,vindxs,vars);
 varssort := BackendVariable.addVars(vlst,varssort);
 outTpl := (eqns,vars,ass2,eqnssort,varssort);
end getEqnsinOrder;

protected function sortVarsforOrder
  input BackendDAE.Equation inEqn;
  input list<BackendDAE.Var> inVarLst;
  input list<Integer> vindxs;
  input BackendDAE.Variables vars;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst := matchcontinue(inEqn,inVarLst,vindxs,vars)
    local
      list<BackendDAE.Var> vlst;
      list<DAE.ComponentRef> crlst;
      DAE.Exp e1;
      list<DAE.Exp> elst;
    case(BackendDAE.ARRAY_EQUATION(left=e1),_,_,_)
      equation
        // if array get all elements
        elst = Expression.flattenArrayExpToList(e1);
        // check if all elements crefs
        crlst = List.map(elst,Expression.expCrefNegCref);
        //crlst = List.uniqueOnTrue(crlst,ComponentReference.crefEqualNoStringCompare);
        vlst = sortVarsforOrder1(crlst,1,inVarLst,vindxs,arrayCreate(listLength(vindxs),NONE()),vars);
      then
        vlst;       
    case(BackendDAE.ARRAY_EQUATION(right=e1),_,_,_)
      equation
        // if array get all elements
        elst = Expression.flattenArrayExpToList(e1);
        // check if all elements crefs
        crlst = List.map(elst,Expression.expCrefNegCref);
        //crlst = List.uniqueOnTrue(crlst,ComponentReference.crefEqualNoStringCompare);
        vlst = sortVarsforOrder1(crlst,1,inVarLst,vindxs,arrayCreate(listLength(vindxs),NONE()),vars);
      then
        vlst;          
    case(_,_,_,_)
      equation
         vlst = List.sort(inVarLst, BackendVariable.varSortFunc);     
      then
        vlst;
  end matchcontinue;
end sortVarsforOrder;

protected function sortVarsforOrder1
  input list<DAE.ComponentRef> crlst;
  input Integer index;
  input list<BackendDAE.Var> inVarLst;
  input list<Integer> vindxs;
  input array<Option<BackendDAE.Var>> vararray;
  input BackendDAE.Variables vars;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst := matchcontinue(crlst,index,inVarLst,vindxs,vararray,vars)
    local
      Integer i,p;
      list<Integer> ilst;
      BackendDAE.Var v;
      list<BackendDAE.Var> vlst;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> rest;
    case({},_,_,_,_,_)
      equation
        vlst = List.sort(inVarLst, BackendVariable.varSortFunc); 
        vlst = sortVarsforOrder2(1,vlst,vararray,{});
      then
        vlst;
    case(cr::rest,_,_,_,_,_)
      equation
        (v::{},i::{}) = BackendVariable.getVar(cr,vars);
        p = List.position(i, vindxs);
        ilst = listDelete(vindxs,p);
        vlst = listDelete(inVarLst,p);
        _ = arrayUpdate(vararray,index,SOME(v));        
      then
        sortVarsforOrder1(rest,index+1,vlst,ilst,vararray,vars);
    case(_::rest,_,_,_,_,_)
      then
        sortVarsforOrder1(rest,index+1,inVarLst,vindxs,vararray,vars);        
  end matchcontinue;
end sortVarsforOrder1;

protected function sortVarsforOrder2
  input Integer index;
  input list<BackendDAE.Var> inVarLst;
  input array<Option<BackendDAE.Var>> vararray;
  input list<BackendDAE.Var> iAcc;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst := matchcontinue(index,inVarLst,vararray,iAcc)
    local
      BackendDAE.Var v;
      list<BackendDAE.Var> vlst;
    case(_,_,_,_)
      equation
       true = intGt(index,arrayLength(vararray));
      then
        listReverse(iAcc);
    case(_,_,_,_)
      equation
        SOME(v) = vararray[index];
      then
        sortVarsforOrder2(index+1,inVarLst,vararray,v::iAcc);
    case(_,v::vlst,_,_)
      then
        sortVarsforOrder2(index+1,vlst,vararray,v::iAcc);        
  end matchcontinue;
end sortVarsforOrder2;

protected function matchOrphans
  input list<tuple<Integer,list<tuple<Integer,Integer>>>> inTpllst;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input array<Integer> mapIncRowEqn;
  input list<Integer> inFirstPairs;
  output list<Integer> outFirstPairs;
algorithm
  outFirstPairs := matchcontinue(inTpllst,ass1,ass2,mapIncRowEqn,inFirstPairs)
    local 
      list<Integer> firstpairs;
      Integer c;
      list<tuple<Integer,Integer>> tpl;
      list<tuple<Integer,list<tuple<Integer,Integer>>>> rest;  
    case ({},_,_,_,_) 
      then inFirstPairs;
    case ((c,tpl)::rest,_,_,_,_)
      equation
       //  print("Try to match " +& intString(c) +& "\n");
       firstpairs = matchOrphans1(c,tpl,ass1,ass2,mapIncRowEqn,inFirstPairs);
      then
        matchOrphans(rest,ass1,ass2,mapIncRowEqn,firstpairs);
  end matchcontinue;
end matchOrphans;

protected function matchOrphans1
  input Integer c;
  input list<tuple<Integer,Integer>> inTpl;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input array<Integer> mapIncRowEqn;
  input list<Integer> inFirstPairs;
  output list<Integer> outFirstPairs;
algorithm
  outFirstPairs := matchcontinue(c,inTpl,ass1,ass2,mapIncRowEqn,inFirstPairs)
    local 
      list<Integer> firstpairs,lst;
      Integer r,d,e;
      list<tuple<Integer,Integer>> rest;
    case (_,{},_,_,_,_) 
      then inFirstPairs;
    case (_,(r,d)::rest,_,_,_,_)
      equation
        true = intEq(d,1);
        false = intGt(ass1[r],0);
        e = mapIncRowEqn[c];
        //  print("Match " +& intString(r) +& " with " +& intString(c) +& " with " +& intString(e) +& "\n");
        _ = arrayUpdate(ass1,r,e);        
        lst = ass2[e];
        _ =arrayUpdate(ass2, e, r::lst);
      then
       c::inFirstPairs;
    case (_,(r,d)::rest,_,_,_,_)
      equation
        false = intGt(ass1[r],0);
        e = mapIncRowEqn[c];
        //  print("Match " +& intString(r) +& " with " +& intString(c) +& " with " +& intString(e) +&  " Distanz " +& intString(d) +& "\n");
        _ = arrayUpdate(ass1,r,e);
        lst = ass2[e];
        _ =arrayUpdate(ass2, e, r::lst);
      then
       inFirstPairs; 
    case(_,_::rest,_,_,_,_)
      then
        matchOrphans1(c,rest,ass1,ass2,mapIncRowEqn,inFirstPairs);      
  end matchcontinue;
end matchOrphans1;

protected function getOrphanspairs
"function getOrphanspairs 
 author: Frenkel TUD 2011-05"
  input Integer indx;
  input array<Integer> ass2;
  input Integer size; 
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrix mT;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input array<Integer> ass1;
  input list<tuple<Integer,list<tuple<Integer,Integer>>>> inTpllst;
  output Integer outMark;
  output list<tuple<Integer,list<tuple<Integer,Integer>>>> outTpllst;
algorithm
  (outMark,outTpllst) := matchcontinue(indx,ass2,size,m,mT,mark,rowmarks,colummarks,ass1,inTpllst)
    local   
      Integer i,d,mark1;
      list<tuple<Integer,Integer>> tpl;
      list<tuple<Integer,list<tuple<Integer,Integer>>>> tpllst;
    case(_,_,_,_,_,_,_,_,_,_)
      equation
        // not exceed size
        true = intGt(indx,size);
      then
        (mark,inTpllst);
    case(_,_,_,_,_,_,_,_,_,_)
      equation
        // not exceed size
        false = intGt(indx,size);
        // orphan?
        false = intGt(ass2[indx],0);
        // get orphans dist?
        tpl = getOrphansPairDist({indx},1,m,mT,mark,rowmarks,colummarks,ass1,{},{});  
        ((_,d)) = listGet(tpl,1);   
        tpllst = insertOrphanspair(d,(indx,tpl),inTpllst);  
        (mark1,tpllst) = getOrphanspairs(indx+1,ass2,size,m,mT,mark+1,rowmarks,colummarks,ass1,tpllst);
      then
        (mark1,tpllst);
    case(_,_,_,_,_,_,_,_,_,_)
      equation
       (mark1,tpllst) = getOrphanspairs(indx+1,ass2,size,m,mT,mark,rowmarks,colummarks,ass1,inTpllst);
      then 
       (mark1,tpllst);
  end matchcontinue;
end getOrphanspairs;

protected function insertOrphanspair
"function insertOrphanspair 
 author: Frenkel TUD 2011-05"
  input Integer dist;
  input tuple<Integer,list<tuple<Integer,Integer>>> inTpl;
  input list<tuple<Integer,list<tuple<Integer,Integer>>>> inTpllst;
  output list<tuple<Integer,list<tuple<Integer,Integer>>>> outTpllst;
algorithm
  outTpllst := matchcontinue(dist,inTpl,inTpllst)
    local   
      Integer d;
      list<tuple<Integer,list<tuple<Integer,Integer>>>> rest,tpllst;
      tuple<Integer,list<tuple<Integer,Integer>>> tpl;
    case (_,_,{})
      then
        {inTpl};
    case(_,_,(tpl as (_,((_,d)::_)))::rest)
      equation
        true = intGt(d,dist);
      then
        inTpl::inTpllst;
    case(_,_,tpl::rest)
      equation
        tpllst = insertOrphanspair(dist,inTpl,rest);
      then
        tpl::tpllst;
  end matchcontinue;
end insertOrphanspair;

protected function getOrphansPairDist
"function getOrphansPairDist
 autor: Frenkel TUD 2012-05"
  input list<Integer> queue;
  input Integer id;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrix mT;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input array<Integer> ass1;
  input list<Integer> nextQueue;
  input list<tuple<Integer,Integer>> inTpl;
  output list<tuple<Integer,Integer>> outTpl;
algorithm
  outTpl :=
  matchcontinue (queue,id,m,mT,mark,rowmarks,colummarks,ass1,nextQueue,inTpl)
    local
      list<Integer> rest,queue1; 
      Integer c;  
      list<tuple<Integer,Integer>> tpl; 
    case ({},_,_,_,_,_,_,_,{},_) then listReverse(inTpl);
    case ({},_,_,_,_,_,_,_,_,_)
      then
        getOrphansPairDist(nextQueue,id+1,m,mT,mark,rowmarks,colummarks,ass1,{},inTpl);
    case (c::rest,_,_,_,_,_,_,_,_,_)
      equation
        false = intEq(mark,colummarks[c]);
        _ = arrayUpdate(colummarks,c,mark);
        // traverse all adiacent rows
        (queue1,tpl) = getOrphansPairDisttraverseRows(m[c],nextQueue,id,mT,mark,rowmarks,colummarks,ass1,inTpl);
      then
        getOrphansPairDist(rest,id,m,mT,mark,rowmarks,colummarks,ass1,queue1,tpl);
    case (_::rest,_,_,_,_,_,_,_,_,_)
      then
        getOrphansPairDist(rest,id,m,mT,mark,rowmarks,colummarks,ass1,nextQueue,inTpl);
    else
      equation
        print("BackendDAEOptimize.getOrphansPairDist failed\n");
      then
        fail();
  end matchcontinue;
end getOrphansPairDist;

protected function getOrphansPairDisttraverseRows
  input list<Integer> rows;
  input list<Integer> nextQueue;
  input Integer id;
  input BackendDAE.IncidenceMatrix mT;  
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input array<Integer> ass1;
  input list<tuple<Integer,Integer>> inTpl;
  output list<Integer> queue;
  output list<tuple<Integer,Integer>> outTpl;
algorithm
  (queue,outTpl) := matchcontinue(rows,nextQueue,id,mT,mark,rowmarks,colummarks,ass1,inTpl)
    local
      Integer r,c;
      list<Integer> rest,queue1;
      list<tuple<Integer,Integer>> tpl;
    case ({},_,_,_,_,_,_,_,_) then (nextQueue,inTpl);
    case (r::rest,_,_,_,_,_,_,_,_)
      equation
        false = intEq(mark,rowmarks[r]);
        _ = arrayUpdate(rowmarks,r,mark);
        tpl = List.consOnTrue(intLt(ass1[r],1),(r,id),inTpl);
        queue1 = listAppend(nextQueue,mT[r]);    
        (queue1,tpl) = getOrphansPairDisttraverseRows(rest,queue1,id,mT,mark,rowmarks,colummarks,ass1,tpl); 
      then
        (queue1,tpl);
    case(_::rest,_,_,_,_,_,_,_,_)
      equation
        (queue1,tpl) = getOrphansPairDisttraverseRows(rest,nextQueue,id,mT,mark,rowmarks,colummarks,ass1,inTpl); 
      then
        (queue1,tpl);
  end matchcontinue;
end getOrphansPairDisttraverseRows;


protected function getOrphansPairs
"function getOrphansPairs
  author: Frenkel TUD 2012-07"
  input list<Integer> inOrphans;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  output Integer omark;
algorithm
  omark := matchcontinue(inOrphans,ass1,ass2,m,mt,mark,rowmarks,colummarks)
    local
      list<Integer> rest;
      array<Integer> sorphans;
      Integer o,c,mark1;
    case ({},_,_,_,_,_,_,_)
      then
       mark;
    case (o::rest,_,_,_,_,_,_,_)
      equation
        false = intEq(rowmarks[o],mark);
        _ = arrayUpdate(rowmarks,o,mark);
          print("Process Orphan " +& intString(o) +& "\n");
        getOrphansPairs1({o},ass1,ass2,m,mt,mark,rowmarks,colummarks,o,{});
      then
        getOrphansPairs(rest,ass1,ass2,m,mt,mark+1,rowmarks,colummarks); 
    case (_::rest,_,_,_,_,_,_,_)
      then
        getOrphansPairs(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks); 
  end matchcontinue;
end getOrphansPairs;


protected function getOrphansPairs1
"function getOrphansPairs1
  author: Frenkel TUD 2012-07"
  input list<Integer> rows;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input Integer orphan;
  input list<Integer> nextQueue;
algorithm
  _ := matchcontinue(rows,ass1,ass2,m,mt,mark,rowmarks,colummarks,orphan,nextQueue)
    local
      Integer r,o;
      list<Integer> rest,next,elst;
    case ({},_,_,_,_,_,_,_,_,{})
      then
        ();
    case ({},_,_,_,_,_,_,_,_,_)
      equation
        getOrphansPairs1(nextQueue,ass1,ass2,m,mt,mark,rowmarks,colummarks,orphan,{});
      then
        ();
    case (r::rest,_,_,_,_,_,_,_,_,_)
      equation
         print("Check Var: " +& intString(r) +& "\n");
        false = intEq(rowmarks[r],mark);
          print("search in " +& stringDelimitList(List.map(mt[r],intString),", ") +& "\n");
        o = hasResidualOrphan(mt[r],ass2);
          print("Found Orphanpair " +& intString(o) +& " <-> " +& intString(orphan) +& "\n");
        _ = arrayUpdate(ass1,orphan,o);        
        _ =arrayUpdate(ass2, o, {orphan});          
      then
        ();
    case (r::rest,_,_,_,_,_,_,_,_,_)
      equation
        false = intEq(rowmarks[r],mark);
        elst = mt[r] "equations of var";
        next = List.flatten(List.map1r(elst,arrayGet,ass2)) "vars assignt with equations"; 
        next = List.select1(next,intGt,0);
        next = listAppend(nextQueue, next);
        _ = arrayUpdate(rowmarks,r,mark);
          print("goto " +& stringDelimitList(List.map(next,intString),", ") +& "\n");
        getOrphansPairs1(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,orphan,next); 
      then
        ();
    case (_::rest,_,_,_,_,_,_,_,_,_)
      equation
        getOrphansPairs1(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,orphan,nextQueue); 
      then
       ();       
  end matchcontinue;
end getOrphansPairs1;


protected function getOrphansPairsConstraints
"function getOrphansPairsConstraints
  author: Frenkel TUD 2012-07"
  input list<Integer> inOrphans;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  output Integer omark;
algorithm
  omark := matchcontinue(inOrphans,ass1,ass2,m,mt,mark,rowmarks,colummarks)
    local
      list<Integer> rest;
      array<Integer> sorphans;
      Integer o,c,mark1;
    case ({},_,_,_,_,_,_,_)
      then
       mark;
    case (o::rest,_,_,_,_,_,_,_)
      equation
        false = intEq(colummarks[o],mark);
        _ = arrayUpdate(colummarks,o,mark);
          print("Process Orphan " +& intString(o) +& "\n");
        getOrphansPairsConstraints1(mt[o],ass1,ass2,m,mt,mark,rowmarks,colummarks,o,{});
      then
        getOrphansPairsConstraints(rest,ass1,ass2,m,mt,mark+1,rowmarks,colummarks); 
    case (_::rest,_,_,_,_,_,_,_)
      then
        getOrphansPairsConstraints(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks); 
  end matchcontinue;
end getOrphansPairsConstraints;


protected function getOrphansPairsConstraints1
"function getOrphansPairsConstraints1
  author: Frenkel TUD 2012-07"
  input list<Integer> eqns;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input Integer orphan;
  input list<Integer> nextQueue;
algorithm
  _ := matchcontinue(eqns,ass1,ass2,m,mt,mark,rowmarks,colummarks,orphan,nextQueue)
    local
      Integer e,r,o;
      list<Integer> rest,next,rlst,lst;
    case ({},_,_,_,_,_,_,_,_,{})
      then
        ();
    case ({},_,_,_,_,_,_,_,_,_)
      equation
        getOrphansPairsConstraints1(nextQueue,ass1,ass2,m,mt,mark,rowmarks,colummarks,orphan,{});
      then
        ();
    case (e::rest,_,_,_,_,_,_,_,_,_)
      equation
         print("Check Eqn: " +& intString(e) +& "\n");
        false = intEq(colummarks[e],mark);
        rlst = m[e] "vars of eqns";
        next = List.map1r(rlst,arrayGet,ass1);
          print("search in " +& stringDelimitList(List.map(next,intString),", ") +& "\n");
        o = hasResidualOrphan(next,ass2);
          print("Found Orphanpair " +& intString(o) +& " <-> " +& intString(orphan) +& "\n");
        _ = arrayUpdate(ass1,orphan,o);        
        _ =arrayUpdate(ass2, o, {orphan});          
      then
        ();
    case (e::rest,_,_,_,_,_,_,_,_,_)
      equation
        false = intEq(colummarks[e],mark);
        rlst = m[e] "vars of eqns";
        lst = List.map1r(rlst,arrayGet,ass1) "assigments of eqns";
        rlst = List.fold1(lst,List.removeOnTrue, intEq, rlst);
        next = List.map1r(rlst,arrayGet,ass1);
        next = List.select1(next,intGt,0);
        next = listAppend(nextQueue, next);
        _ = arrayUpdate(colummarks,e,mark);
          print("goto " +& stringDelimitList(List.map(next,intString),", ") +& "\n");
        getOrphansPairsConstraints1(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,orphan,next); 
      then
        ();
    case (_::rest,_,_,_,_,_,_,_,_,_)
      equation
        getOrphansPairsConstraints1(rest,ass1,ass2,m,mt,mark,rowmarks,colummarks,orphan,nextQueue); 
      then
       ();       
  end matchcontinue;
end getOrphansPairsConstraints1;


protected function getIndexesForEqnsAdvanced
"function getIndexesForEqnsAdvanced
 autor: Frenkel TUD 2012-07"
  input list<Integer> orphans;
  input Integer index;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input array<list<Integer>> vec1;
  input array<Integer> vec2;
  input array<Boolean> queuemark;
  output Integer outMark;
algorithm
  outMark := match(orphans,index,m,mT,mark,rowmarks,colummarks,ass1,ass2,vec1,vec2,queuemark)
    local
      Integer vorphan,eorphan,index1;
      list<Integer> rest,rows,queue;
      list<list<Integer>> queuelst;
    case ({},_,_,_,_,_,_,_,_,_,_,_)
      equation
        //markIndexdColums(1,arrayLength(vec1),mark+1,colummarks,vec2);
        //getIndexesForEqnsRest(1,arrayLength(vec1),index,mark+1,colummarks,ass1,ass2,vec1,vec2);
      then mark+2;
    case (vorphan::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation      
        eorphan = ass1[vorphan];
        //  print("Process Orphan " +& intString(vorphan) +& "  " +& intString(eorphan) +& "\n"); 
        // generate subgraph from residual equation to tearing variable
        rows = List.select(m[eorphan], Util.intPositive);
        rows = List.fold1(ass2[eorphan],List.removeOnTrue, intEq, rows);
        // BackendDump.debuglst((rows,intString,", ","\n"));
        _ = getIndexSubGraph(rows,vorphan,m,mT,mark,rowmarks,colummarks,ass1,ass2,false);        
        // generate queue with BFS from tearing var to residual equation
        // print("getIndex ");
        // BackendDump.debuglst((mT[vorphan],intString,", ","\n"));
        queue = mT[vorphan]; 
        queuelst = getIndexQueque(queue,m,mT,mark,rowmarks,colummarks,ass1,ass2,vec2,queuemark,{},{},{});
        queue = List.flatten(queuelst);
        // print("queue ");
        // BackendDump.debuglst((queue,intString,", ","\n"));
        // set indexes
        index1 = List.fold1(queue,setIndexQueue,(vec1,vec2,ass2,queuemark),index);
        _=arrayUpdate(vec1,index1,{vorphan});
        _=arrayUpdate(vec2,index1,eorphan);
        _=arrayUpdate(queuemark,eorphan,true);
      then
       getIndexesForEqnsAdvanced(rest,index1+1,m,mT,mark+2,rowmarks,colummarks,ass1,ass2,vec1,vec2,queuemark);
  end match;
end getIndexesForEqnsAdvanced;  

protected function setIndexQueue
"function setIndexQueue
 autor: Frenkel TUD 2012-07"
 input Integer col;
 input tuple<array<list<Integer>>,array<Integer>,array<list<Integer>>,array<Boolean>> tpl;
 input Integer index;
 output Integer oindex;
algorithm
  oindex := matchcontinue(col,tpl,index)
    local
      array<Integer> vec2;
      array<List<Integer>> vec1,ass2;
      list<Integer> r;
      array<Boolean> queuemark;
    case (_,(vec1,vec2,ass2,queuemark),_)
      equation      
        r = ass2[col];
        false = queuemark[col];
        //  print("Index: " +& intString(index) +& ":" +& stringDelimitList(List.map(r,intString),", ") +& "  " +& intString(col) +& "\n"); 
        _ = arrayUpdate(vec1,index,r);
        _ = arrayUpdate(vec2,index,col);
        _ = arrayUpdate(queuemark,col,true);
      then
        index+1;
    else
      index;        
  end matchcontinue;
end setIndexQueue;

protected function getIndexQueque
"function getIndexQueque
 autor: Frenkel TUD 2012-07"
  input list<Integer> colums;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input array<Integer> vec2;
  input array<Boolean> queuemark;
  input list<Integer> nextqueue;
  input list<Integer> iqueue;
  input list<list<Integer>> iqueue1;
  output list<list<Integer>> oqueue;
algorithm
  oqueue := match(colums,m,mT,mark,rowmarks,colummarks,ass1,ass2,vec2,queuemark,nextqueue,iqueue,iqueue1)
    local
      Integer c;
      list<Integer> rest,queue,r,queue1,colums1;
      Boolean b,b1,b2;
    case ({},_,_,_,_,_,_,_,_,_,{},_,_) then iqueue1;
    case ({},_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        queue = List.unique(iqueue);
        // print("append level: "); BackendDump.debuglst((queue,intString,", ","\n"));
      then
        getIndexQueque(nextqueue,m,mT,mark,rowmarks,colummarks,ass1,ass2,vec2,queuemark,{},{},queue::iqueue1);
    case (c::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        r = ass2[c];
        b = queuemark[c];
        // print("Process Colum " +& intString(c) +& " Rows " +& stringDelimitList(List.map(r,intString),", ") +& "  " +& boolString(b) +&"\n");
        (colums1,b2) = getIndexQueque1(r,c,mT,mark,rowmarks,{},false);
        // BackendDump.debuglst((colums1,intString,", ","\n"));
        b1 = intGt(listLength(colums),0);
        // cons next rows in front to jump over marked nodes 
        queue = Debug.bcallret3(b1, List.unionOnTrue, colums1, nextqueue, intEq, nextqueue);
        // print("queue: "); BackendDump.debuglst((queue,intString,", ","\n"));
        queue1 = List.consOnTrue(b2, c, iqueue);
      then
       getIndexQueque(rest,m,mT,mark,rowmarks,colummarks,ass1,ass2,vec2,queuemark,queue,queue1,iqueue1);
  end match;
end getIndexQueque;

protected function getIndexQueque1
  input list<Integer> rows;
  input Integer c;
  input BackendDAE.IncidenceMatrixT mT;
  input Integer mark;
  input array<Integer> rowmarks;  
  input list<Integer> icolums;
  input Boolean ib;
  output list<Integer> ocolums;
  output Boolean ob;
algorithm
  (ocolums,ob) := matchcontinue (rows,c,mT,mark,rowmarks,icolums,ib)
    local
      Integer r;
      list<Integer> rest,colums;
    case ({},_,_,_,_,_,_)
      equation
        rest = List.unique(icolums);
      then
        (rest,ib);
    case (r::rest,_,_,_,_,_,_)
      equation
        true = intEq(rowmarks[r],mark);
        //  print("Go from: " +& intString(c) +& " to " +& intString(r) +& "\n"); 
        colums = List.select(mT[r], Util.intPositive);
        colums = List.removeOnTrue(c, intEq , colums);
        colums = listAppend(colums,icolums); 
        (ocolums,ob) = getIndexQueque1(rest,c,mT,mark,rowmarks,colums,true); 
      then
        (ocolums,ob);         
    case (_::rest,_,_,_,_,_,_)
      equation
        (ocolums,ob) = getIndexQueque1(rest,c,mT,mark,rowmarks,icolums,ib); 
      then
        (ocolums,ob);
  end matchcontinue;  
end getIndexQueque1;

protected function unmarked
  input Integer indx;
  input array<Integer> markarray;
  input Integer mark;
  output Boolean b;
algorithm
  b := intLt(markarray[indx],mark);
end unmarked;

protected function marked
  input Integer indx;
  input array<Integer> markarray;
  input Integer mark;
  output Boolean b;
algorithm
  b := intEq(markarray[indx],mark);
end marked;

protected function isOrphan
  input Integer indx;
  input array<Integer> ass;
  output Boolean b;
algorithm
  b := intLt(ass[indx],1);
end isOrphan;

protected function isNoOrphan
  input Integer indx;
  input array<Integer> ass;
  output Boolean b;
algorithm
  b := intGt(ass[indx],0);
end isNoOrphan;

protected function isNoResOrphan
  input Integer indx;
  input array<list<Integer>> ass;
  output Boolean b;
algorithm
  b := intGt(listLength(ass[indx]),0);
end isNoResOrphan;

protected function doAssign
"function doAssign
  author: Frenkel TUD 2012-05"
  input Integer index;
  input array<list<Integer>> arr;
  input list<Integer> assign;
algorithm
  _ := arrayUpdate(arr,index,assign);
end doAssign; 

protected function doMark
"function mark
  author: Frenkel TUD 2012-05"
  input Integer index;
  input array<Integer> arr;
  input Integer mark;
algorithm
  _ := arrayUpdate(arr,index,mark);
end doMark; 

protected function getIndexSubGraph
"function getIndexSubGraph
 autor: Frenkel TUD 2012-07"
  input list<Integer> rows;
  input Integer vorphan;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input Boolean ifound;
  output Boolean found;
algorithm
  found := matchcontinue(rows,vorphan,m,mT,mark,rowmarks,colummarks,ass1,ass2,ifound)
    local
      Integer r,e;
      list<Integer> rest,nextrows,queue1;
      Boolean b;
    case ({},_,_,_,_,_,_,_,_,_) then ifound;
    case (r::rest,_,_,_,_,_,_,_,_,_)
      equation
        // is my var orphan?
        true = intEq(r,vorphan);
        // mark all entries in the queue
        // print("Found orphan " +& intString(r) +& "\n");
      then
        true;
    case (r::rest,_,_,_,_,_,_,_,_,_)
      equation
        false = intEq(r,vorphan);
        // stop if it is an orphan
        false = intEq(rowmarks[r],-2);
        true = intEq(rowmarks[r],mark);
        e = ass1[r];
        markIndexSubgraph(true,ass2[e],mark,rowmarks);         
      then
        getIndexSubGraph(rest,vorphan,m,mT,mark,rowmarks,colummarks,ass1,ass2,true);        
    case (r::rest,_,_,_,_,_,_,_,_,_)
      equation
        false = intEq(r,vorphan);
        // stop if it is an orphan
        false = intEq(rowmarks[r],-2);
        //false = intEq(rowmarks[r],mark);
        e = ass1[r];
        false = intEq(colummarks[e],-2);
        false = intEq(colummarks[e],mark);
        nextrows = List.select(m[e], Util.intPositive);
        nextrows = List.setDifferenceOnTrue(nextrows,ass2[e],intEq);
        //  print("search Subgraph: " +& intString(r) +& " across " +& intString(e) +& "\n");  
        //_ = arrayUpdate(rowmarks,r,mark);
        _ = arrayUpdate(colummarks,e,mark);
        //  BackendDump.debuglst((nextrows,intString,", ","\n"));
        b = getIndexSubGraph(nextrows,vorphan,m,mT,mark,rowmarks,colummarks,ass1,ass2,false);
        markIndexSubgraph(b,ass2[e],mark,rowmarks);         
      then
        getIndexSubGraph(rest,vorphan,m,mT,mark,rowmarks,colummarks,ass1,ass2,b or ifound);
    case (r::rest,_,_,_,_,_,_,_,_,_)
      then
        getIndexSubGraph(rest,vorphan,m,mT,mark,rowmarks,colummarks,ass1,ass2,ifound);         
  end matchcontinue;
end getIndexSubGraph;

protected function markIndexSubgraph
"function markIndexSubgraph
 autor: Frenkel TUD 2012-07"
  input Boolean b;
  input list<Integer> r;
  input Integer mark;
  input array<Integer> rowmarks;
algorithm
  _ := match(b,r,mark,rowmarks)
    case(false,_,_,_) then ();
    case(true,_,_,_)
      equation
        markIndexSubgraph1(r,mark,rowmarks);
      then
        ();
  end match;
end markIndexSubgraph;

protected function markIndexSubgraph1
"function markIndexSubgraph
 autor: Frenkel TUD 2012-07"
  input list<Integer> row;
  input Integer mark;
  input array<Integer> rowmarks;
algorithm
  _ := match(row,mark,rowmarks)
    local
      Integer r;
      list<Integer> rest;
    case({},_,_) then ();
    case(r::rest,_,_)
      equation
        // print("Add " +& intString(r) +& " to Graph\n");
        _ = arrayUpdate(rowmarks,r,mark);
        markIndexSubgraph1(rest,mark,rowmarks);
      then
        ();
  end match;
end markIndexSubgraph1;

protected function getIndexesForEqnsRest
  input Integer i;
  input Integer size;
  input Integer id;
  input Integer mark;
  input array<Integer> colummarks;  
  input array<Integer> ass1;
  input array<Integer> ass2;
  input array<Integer> vec1;
  input array<Integer> vec2;
algorithm
  _ := matchcontinue(i,size,id,mark,colummarks,ass1,ass2,vec1,vec2)
  case(_,_,_,_,_,_,_,_,_)
    equation
      false = intGt(i,size);
      true = intEq(mark,colummarks[i]);
      getIndexesForEqnsRest(i+1,size,id,mark,colummarks,ass1,ass2,vec1,vec2);
    then 
      (); 
  case(_,_,_,_,_,_,_,_,_)
    equation
      false = intGt(i,size);
      _ = arrayUpdate(vec1,id,ass2[i]);      
      _ = arrayUpdate(vec2,id,i);
      getIndexesForEqnsRest(i+1,size,id+1,mark,colummarks,ass1,ass2,vec1,vec2);
    then 
      (); 
  else
    then 
      (); 
  end matchcontinue;
end getIndexesForEqnsRest;

protected function markIndexdColums
  input Integer i;
  input Integer size;
  input Integer mark;
  input array<Integer> colummarks;  
  input array<Integer> vec2;
algorithm
  _ := matchcontinue(i,size,mark,colummarks,vec2)
  case(_,_,_,_,_)
    equation
      false = intGt(i,size);
      true = intGt(vec2[i],0);
      _ = arrayUpdate(colummarks,vec2[i],mark);      
      markIndexdColums(i+1,size,mark,colummarks,vec2);
    then 
      (); 
  case(_,_,_,_,_)
    equation
      false = intGt(i,size);
      markIndexdColums(i+1,size,mark,colummarks,vec2);
    then 
      (); 
  else
    then 
      (); 
  end matchcontinue;
end markIndexdColums;

protected function getIndexesForEqnsNew
"function getIndexesForEqnsNew
 autor: Frenkel TUD 2012-05"
  input list<Integer> orphans;
  input Integer id;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input array<Integer> vec1;
  input array<Integer> vec2;
  output Integer outMark;
algorithm
  outMark :=
  matchcontinue (orphans,id,m,mT,mark,rowmarks,colummarks,ass1,ass2,vec1,vec2)
    local
      list<Integer> rest,queue1,rows; 
      Integer c,r,id1;  
    case ({},_,_,_,_,_,_,_,_,_,_)
      equation
        markIndexdColums(1,arrayLength(vec1),mark+1,colummarks,vec2);
        getIndexesForEqnsRest(1,arrayLength(vec1),id,mark+1,colummarks,ass1,ass2,vec1,vec2);
      then mark+2;
    case (r::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        // get eorphan
        c = ass1[r];
        // print("Process Orphan pair " +& intString(r) +& " " +& intString(c) +& "\n");
        // traverse all adiacent rows
        id1 = getIndexesForEqnsNew1({c},id,m,mT,mark,rowmarks,colummarks,ass1,ass2,vec1,vec2,intEq(listLength(rest),0),{});
        // print("Id for pair " +& intString(id1) +& "\n");
        _ = arrayUpdate(vec1,id1,r);
        _ = arrayUpdate(vec2,id1,c);
      then
        getIndexesForEqnsNew(rest,id1+1,m,mT,mark,rowmarks,colummarks,ass1,ass2,vec1,vec2);
    else
      equation
        print("BackendDAEOptimize.getIndexesForEqnsNew failed\n");
      then
        fail();
  end matchcontinue;
end getIndexesForEqnsNew;

protected function getIndexesForEqnsNew1
"function getIndexesForEqnsNew1
 autor: Frenkel TUD 2012-05"
  input list<Integer> queue;
  input Integer id;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input array<Integer> vec1;
  input array<Integer> vec2;
  input Boolean last;
  input list<Integer> nextQueue;
  output Integer outId;
algorithm
  outId :=
  matchcontinue (queue,id,m,mT,mark,rowmarks,colummarks,ass1,ass2,vec1,vec2,last,nextQueue)
    local
      list<Integer> rest,queue1,rows; 
      Integer c,id1;  
    case ({},_,_,_,_,_,_,_,_,_,_,_,{}) then id;
    case ({},_,_,_,_,_,_,_,_,_,_,_,_)
      then
        getIndexesForEqnsNew1(nextQueue,id,m,mT,mark,rowmarks,colummarks,ass1,ass2,vec1,vec2,last,{});
    case (c::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        false = intEq(colummarks[c],mark);
        _ = arrayUpdate(colummarks,c,mark);
        rows = List.removeOnTrue(ass2[c],intEq,m[c]);
        // traverse all adiacent rows
        (queue1,id1) = getIndexesForEqstraverseRowsNew(rows,nextQueue,id,m,mT,mark,rowmarks,colummarks,ass1,ass2,vec1,vec2,last);
      then
        getIndexesForEqnsNew1(rest,id1,m,mT,mark,rowmarks,colummarks,ass1,ass2,vec1,vec2,last,queue1);
    case (_::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      then
        getIndexesForEqnsNew1(rest,id,m,mT,mark,rowmarks,colummarks,ass1,ass2,vec1,vec2,last,nextQueue);
    else
      equation
        print("BackendDAEOptimize.getIndexesForEqnsNew1 failed\n");
      then
        fail();
  end matchcontinue;
end getIndexesForEqnsNew1;

protected function getIndexesForEqstraverseRowsNew
  input list<Integer> rows;
  input list<Integer> nextQueue;
  input Integer id;
  input BackendDAE.IncidenceMatrix m;  
  input BackendDAE.IncidenceMatrixT mT;  
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input array<Integer> vec1;
  input array<Integer> vec2;
  input Boolean last;
  output list<Integer> queue;
  output Integer outId;
algorithm
  (queue,outId) := matchcontinue(rows,nextQueue,id,m,mT,mark,rowmarks,colummarks,ass1,ass2,vec1,vec2,last)
    local
      Integer r,id1,c;
      list<Integer> rest,queue1;
      Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_,_,_) then (nextQueue,id);
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        false = intEq(rowmarks[r],-2);
        false = intEq(rowmarks[r],mark);
        _ = arrayUpdate(rowmarks,r,mark);
        c = ass1[r];
        _ = arrayUpdate(vec1,id,r);
        _ = arrayUpdate(vec2,id,c);  
        b = eqnHasNoOrphan(m[c],rowmarks);
        // print("Do Const " +& boolString(last) +& "\n");
        queue1 = List.consOnTrue(b or last,c,nextQueue);
        (queue1,id1) = getIndexesForEqstraverseRowsNew(rest,queue1,id+1,m,mT,mark,rowmarks,colummarks,ass1,ass2,vec1,vec2,last); 
      then
        (queue1,id1);
    case(_::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        (queue1,id1) = getIndexesForEqstraverseRowsNew(rest,nextQueue,id,m,mT,mark,rowmarks,colummarks,ass1,ass2,vec1,vec2,last);
      then
        (queue1,id1);
  end matchcontinue;
end getIndexesForEqstraverseRowsNew;

protected function eqnHasNoOrphan
  input list<Integer> rows;
  input array<Integer> rowmarks;
  output Boolean b;
algorithm
  b := matchcontinue(rows,rowmarks)
    local 
      Integer r;
      list<Integer> rest;
    case ({},_) then true;
    case(r::rest,_)
      equation
        false = intEq(rowmarks[r],-2);
      then
        eqnHasNoOrphan(rest,rowmarks);
    case (_,_) then false;
  end matchcontinue;
end eqnHasNoOrphan;

protected function getIndexesForEqns
"function getIndexesForEqns
 autor: Frenkel TUD 2012-05"
  input list<Integer> queue;
  input Integer id;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrix mT;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input array<Integer> vec1;
  input array<Integer> vec2;
  input list<Integer> nextQueue;
algorithm
  _ :=
  matchcontinue (queue,id,m,mT,mark,rowmarks,colummarks,ass1,ass2,vec1,vec2,nextQueue)
    local
      list<Integer> rest,queue1; 
      Integer c,r,id1;  
    case ({},_,_,_,_,_,_,_,_,_,_,{}) then ();
    case ({},_,_,_,_,_,_,_,_,_,_,_)
      equation
        getIndexesForEqns(nextQueue,id,m,mT,mark,rowmarks,colummarks,ass1,ass2,vec1,vec2,{});
      then
       (); 
    case (c::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        false = intEq(colummarks[c],mark);
        _ = arrayUpdate(colummarks,c,mark);
        r = ass2[c];
        _ = arrayUpdate(vec1,id,r);
        _ = arrayUpdate(vec2,id,c);
        // traverse all adiacent rows
        (queue1,id1) = getIndexesForEqstraverseRows(m[c],nextQueue,id+1,mT,mark,rowmarks,colummarks,ass1,ass2,vec1,vec2);
        getIndexesForEqns(rest,id1,m,mT,mark,rowmarks,colummarks,ass1,ass2,vec1,vec2,queue1);
      then
        ();       
    case (_::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        getIndexesForEqns(rest,id,m,mT,mark,rowmarks,colummarks,ass1,ass2,vec1,vec2,nextQueue);
      then
        ();        
    else
      equation
        print("BackendDAEOptimize.getIndexesForEqns failed\n");
      then
        fail();
  end matchcontinue;
end getIndexesForEqns;

protected function getIndexesForEqstraverseRows
  input list<Integer> rows;
  input list<Integer> nextQueue;
  input Integer id;
  input BackendDAE.IncidenceMatrix mT;  
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input array<Integer> vec1;
  input array<Integer> vec2;
  output list<Integer> queue;
  output Integer outId;
algorithm
  (queue,outId) := matchcontinue(rows,nextQueue,id,mT,mark,rowmarks,colummarks,ass1,ass2,vec1,vec2)
    local
      Integer r,id1;
      list<Integer> rest,queue1;
    case ({},_,_,_,_,_,_,_,_,_,_) then (nextQueue,id);
    case (r::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        false = intEq(rowmarks[r],mark);
        _ = arrayUpdate(rowmarks,r,mark);
        queue1 = listAppend(nextQueue,mT[r]);    
        (queue1,id1) = getIndexesForEqstraverseRows(rest,queue1,id,mT,mark,rowmarks,colummarks,ass1,ass2,vec1,vec2); 
      then
        (queue1,id1);
    case(_::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        (queue1,id1) = getIndexesForEqstraverseRows(rest,nextQueue,id,mT,mark,rowmarks,colummarks,ass1,ass2,vec1,vec2);
      then
        (queue1,id1);
  end matchcontinue;
end getIndexesForEqstraverseRows;


protected function getOrphanspair
"function getOrphanspair 
 author: Frenkel TUD 2011-05" 
  input BackendDAE.IncidenceMatrix m;
  input Integer indx;
  input Integer size;
  input array<Integer> vec1;
  input array<Integer> vec2;
  output tuple<Integer,Integer> outTpl;
algorithm
  outTpl := matchcontinue(m,indx,size,vec1,vec2)
    local   
      Integer i;
      BackendDAE.Equation eqn;
    case(_,_,_,_,_)
      equation
        // not exceed size
        false = intGt(indx,size);
        // orphan?
        false = intGt(vec2[indx],0);
        // has orphan var?
        i = getOrphanspair1(m[indx],vec1);        
      then
        ((indx,i));
    case(_,_,_,_,_)
      then
       getOrphanspair(m,indx+1,size,vec1,vec2);
  end matchcontinue;
end getOrphanspair;

protected function getOrphanspair1
"function getOrphanspair1 
 author: Frenkel TUD 2011-05" 
  input list<Integer> vars;
  input array<Integer> vec1;
  output Integer outOrphan;
algorithm
  outOrphan := matchcontinue(vars,vec1)
    local   
      list<Integer> rest;
      Integer i;
    case(i::rest,_)
      equation
        // orphan?
        false = intGt(vec1[i],0);
      then
        i;
    case(_::rest,_)
      then
       getOrphanspair1(rest,vec1);
  end matchcontinue;
end getOrphanspair1;

protected function getOrphans
"function getOrphans 
 author: Frenkel TUD 2011-05" 
  input Integer indx;
  input Integer size;
  input array<Integer> ass;
  input list<Integer> inOrphans;
  output list<Integer> outOrphans;
algorithm
  outOrphans := matchcontinue(indx,size,ass,inOrphans)
    local 
      list<Integer> orphans;
    case (_,_,_,_)
      equation
        true = intGt(indx,size);
      then
        inOrphans;
    case (_,_,_,_)
      equation
        orphans = List.consOnTrue(intLt(ass[indx],1), indx, inOrphans);
      then
        getOrphans(indx+1,size,ass,orphans);
  end matchcontinue;
end getOrphans;

protected function expHasCref
"function expHasCref 
 author: Frenkel TUD 2012-05
  traverses an expression and check if the cref or parents of them are there"
 input DAE.Exp inExp;
 input DAE.ComponentRef cr;
 output Boolean isthere;
protected
  HashSet.HashSet set; 
algorithm 
  set := HashSet.emptyHashSet();
  set := addCrefandParentsToSet(cr,set,NONE());
  ((_,(_,isthere))) := Expression.traverseExpTopDown(inExp, expHasCreftraverser, (set,false));
end expHasCref;

protected function addCrefandParentsToSet
  input DAE.ComponentRef inCref;
  input HashSet.HashSet ihs;
  input Option<DAE.ComponentRef> oprecr;
  output HashSet.HashSet ohs;
algorithm
  ohs := match(inCref,ihs,oprecr)
    local
      DAE.ComponentRef cr,idcr,precr,subcr; 
      list<DAE.ComponentRef> crlst;
      HashSet.HashSet set;
      DAE.Type ty;
      DAE.Ident ident;
      list<DAE.Subscript> subscriptLst;
    case (cr as DAE.CREF_IDENT(ident=_),_,NONE())
      equation
        crlst = ComponentReference.expandCref(cr,true);
        set = List.fold(cr::crlst,BaseHashSet.add,ihs);
      then set;
    case (cr as DAE.CREF_IDENT(ident=_),_,SOME(precr))
      equation
        crlst = ComponentReference.expandCref(cr,true);
        crlst = List.map1r(cr::crlst,ComponentReference.joinCrefs,precr);
        set = List.fold(crlst,BaseHashSet.add,ihs);
      then set;
    case (cr as DAE.CREF_QUAL(ident=ident,identType=ty,subscriptLst=subscriptLst,componentRef=subcr),_,NONE())
      equation
        idcr = ComponentReference.makeCrefIdent(ident,ty,{});
        set = BaseHashSet.add(idcr,ihs);
        idcr = ComponentReference.makeCrefIdent(ident,ty,subscriptLst);
        set = BaseHashSet.add(idcr,set);
      then 
        addCrefandParentsToSet(subcr,set,SOME(idcr));
    case (cr as DAE.CREF_QUAL(ident=ident,identType=ty,subscriptLst=subscriptLst,componentRef=subcr),_,SOME(precr))
      equation
        idcr = ComponentReference.makeCrefIdent(ident,ty,{});
        idcr = ComponentReference.joinCrefs(precr,idcr);
        set = BaseHashSet.add(idcr,ihs);
        idcr = ComponentReference.makeCrefIdent(ident,ty,subscriptLst);
        precr = ComponentReference.joinCrefs(precr,idcr);
        set = BaseHashSet.add(precr,ihs);
      then 
        addCrefandParentsToSet(subcr,set,SOME(precr));
  end match;
end addCrefandParentsToSet;

protected function expHasCreftraverser
"function expHasCref 
 author: Frenkel TUD 2012-05
  helper for expHasCref"
  input tuple<DAE.Exp, tuple<HashSet.HashSet,Boolean>> inTpl;
  output tuple<DAE.Exp, Boolean, tuple<HashSet.HashSet,Boolean>> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
    local
      Boolean b;
      DAE.ComponentRef cr;
      DAE.Exp e;
      HashSet.HashSet set;
    
    case ((e as DAE.CREF(componentRef = cr), (set,false)))
      equation
        b = BaseHashSet.has(cr,set);
      then
        ((e,not b,(set,b)));
    
    case (((e,(set,b)))) then ((e,not b,(set,b)));
    
  end matchcontinue;    
end expHasCreftraverser;

protected function assignLst
  input list<Integer> vlst;
  input Integer e;
  input array<Integer> ass1;
  input array<Integer> ass2;
algorithm
  _ := match(vlst,e,ass1,ass2)
    local
      Integer v;
      list<Integer> rest;
    case ({},_,_,_) then ();
    case (v::rest,_,_,_)
      equation
        _ = arrayUpdate(ass1,v,e);
        _ = arrayUpdate(ass2,e,v);
        assignLst(rest,e+1,ass1,ass2);
      then
        ();
  end match; 
end assignLst;

protected function unassignedLst
  input list<Integer> vlst;
  input array<Integer> ass1;
algorithm
  _ := match(vlst,ass1)
    local
      Integer v;
      list<Integer> rest;
    case ({},_) then ();
    case (v::rest,_)
      equation
        false = intGt(ass1[v],0);
        unassignedLst(rest,ass1);
      then
        ();
  end match; 
end unassignedLst;

protected function onefreeMatchingBFS
"function onefreeMatchingBFS
  author: Frenkel TUD 2012-05"
  input BackendDAE.IncidenceMatrixElement queue;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer size;
  input array<Integer> ass1; 
  input array<Integer> ass2;
  input array<Integer> columark;
  input Integer mark;
  input BackendDAE.IncidenceMatrixElement nextQeue;
algorithm
  _ := match(queue,m,mt,size,ass1,ass2,columark,mark,nextQeue)
    local 
      Integer c;
      BackendDAE.IncidenceMatrixElement rest,newqueue,rows;
    case ({},_,_,_,_,_,_,_,{}) then ();
    case ({},_,_,_,_,_,_,_,_)
      equation
        //  print("NextQeue\n");
        onefreeMatchingBFS(nextQeue,m,mt,size,ass1,ass2,columark,mark,{});
      then 
        ();
    case(c::rest,_,_,_,_,_,_,_,_)
      equation
        //  print("Process Eqn " +& intString(c) +& "\n");
        rows = List.removeOnTrue(ass1, isAssignedSaveEnhanced, m[c]); 
        //_ = arrayUpdate(columark,c,mark);
        newqueue = onefreeMatchingBFS1(rows,c,mt,ass1,ass2,columark,mark,nextQeue);
        onefreeMatchingBFS(rest,m,mt,size,ass1,ass2,columark,mark,newqueue);
      then 
        ();
  end match; 
end onefreeMatchingBFS;

protected function isAssignedSaveEnhanced
"function isAssigned
  author: Frenkel TUD 2012-05"
  input array<Integer> ass;
  input Integer inTpl;
  output Boolean outB;
algorithm
  outB := matchcontinue(ass,inTpl)
    local
      Integer i;
    case (_,i)
      equation
        true = intGt(i,0);
      then
        intGt(ass[i],0); 
    else
      true;
  end matchcontinue;
end isAssignedSaveEnhanced;

protected function onefreeMatchingBFS1
"function onefreeMatchingBFS1
  author: Frenkel TUD 2012-05"
  input BackendDAE.IncidenceMatrixElement rows;
  input Integer c;
  input BackendDAE.IncidenceMatrix mt;
  input array<Integer> ass1; 
  input array<Integer> ass2;
  input array<Integer> columark;
  input Integer mark;
  input BackendDAE.IncidenceMatrixElement inNextQeue;
  output BackendDAE.IncidenceMatrixElement outNextQeue;
algorithm
  outNextQeue := matchcontinue(rows,c,mt,ass1,ass2,columark,mark,inNextQeue)
    local 
      Integer r;
      BackendDAE.IncidenceMatrixElement vareqns,newqueue;
    case (r::{},_,_,_,_,_,_,_)
      equation
        //  print("Assign Var" +& intString(r) +& " with Eqn " +& intString(c) +& "\n");
        // assigen 
        _ = arrayUpdate(ass1,r,c);
        _ = arrayUpdate(ass2,c,r);
        vareqns = List.removeOnTrue(ass2, isAssignedSaveEnhanced, mt[r]);  
        //vareqns = List.removeOnTrue((columark,mark), isMarked, vareqns);   
        //markEqns(vareqns,columark,mark);     
      then 
        listAppend(inNextQeue,vareqns);
    else then inNextQeue;
  end matchcontinue; 
end onefreeMatchingBFS1;

protected function vectorMatching
"function vectorMatching 
 author: Frenkel TUD 2012-05
  try to match functions like a = f(...), f(..)=a for 
  array/complex equations" 
  input BackendDAE.Equation eqn;
  input BackendDAE.Variables vars;
  input tuple<Integer,array<Integer>,array<Integer>> inTpl;
  output tuple<Integer,array<Integer>,array<Integer>> outTpl;
algorithm
  outTpl := matchcontinue(eqn,vars,inTpl)
    local 
      Integer id,size;
      array<Integer> vec1,vec2;
      DAE.Exp e1,e2;
      list<Integer> ds;

    // array equations
    case (BackendDAE.ARRAY_EQUATION(dimSize=ds, left=e1,right=e2),_,(id,vec1,vec2))
      equation
        size = List.fold(ds,intMul,1);
        ((id,vec1,vec2)) = vectorMatching1(e1,e2,size,vars,(id,vec1,vec2));
      then ((id,vec1,vec2));      
    case (BackendDAE.ARRAY_EQUATION(dimSize=ds, left=e2,right=e1),_,(id,vec1,vec2))
      equation
        size = List.fold(ds,intMul,1);
        ((id,vec1,vec2)) = vectorMatching1(e2,e1,size,vars,(id,vec1,vec2));
      then ((id,vec1,vec2));      
    // complex equations
    case (BackendDAE.COMPLEX_EQUATION(size=size, left=e1,right=e2),_,(id,vec1,vec2))
      equation
        ((id,vec1,vec2)) = vectorMatching1(e1,e2,size,vars,(id,vec1,vec2));
      then ((id,vec1,vec2));      
    case (BackendDAE.COMPLEX_EQUATION(size=size, left=e2,right=e1),_,(id,vec1,vec2))
      equation
        ((id,vec1,vec2)) = vectorMatching1(e2,e1,size,vars,(id,vec1,vec2));
      then ((id,vec1,vec2));      
    case (_,_,(id,vec1,vec2))
      equation
        size = BackendEquation.equationSize(eqn);
      then ((id+size,vec1,vec2));
  end matchcontinue;
end vectorMatching;

protected function vectorMatching1
"function vectorMatching 
 author: Frenkel TUD 2012-05
  try to match functions like a = f(...), f(..)=a for 
  array/complex equations" 
  input DAE.Exp e1;
  input DAE.Exp e2;
  input Integer size;
  input BackendDAE.Variables vars;
  input tuple<Integer,array<Integer>,array<Integer>> inTpl;
  output tuple<Integer,array<Integer>,array<Integer>> outTpl;
algorithm
  outTpl := matchcontinue(e1,e2,size,vars,inTpl)
    local 
      Integer id,i;
      array<Integer> vec1,vec2;
      DAE.ComponentRef cr,crnosubs;
      list<DAE.ComponentRef> crlst,crlst1;
      DAE.Exp e;
      list<DAE.Exp> elst;
      list<BackendDAE.Var> vlst;
      list<Integer> ds,ilst;
      list<Boolean> blst;    
      HashSet.HashSet set;

    // a = f(...)
    case (DAE.CREF(componentRef=cr),_,_,_,(id,vec1,vec2))
      equation
        // check if cref is not also at the other side
        false = expHasCref(e2, cr);
        // get Vars
        (_,ilst) = BackendVariable.getVar(cr,vars);
        // size equal        
        true = intEq(size,listLength(ilst));
        // unassgned
        unassignedLst(ilst,vec1);
        // assign
        assignLst(ilst,id,vec1,vec2);
      then ((id+size,vec1,vec2));      
    // f(...) = a
    case (_,DAE.CREF(componentRef=cr),_,_,(id,vec1,vec2))
      equation
        // check if cref is not also at the other side
        false = expHasCref(e1, cr);
        // get Vars
        (_,ilst) = BackendVariable.getVar(cr,vars);
        // size equal        
        true = intEq(size,listLength(ilst));
        // unassgned
        unassignedLst(ilst,vec1);        
        // assign
        assignLst(ilst,id,vec1,vec2);
      then ((id+size,vec1,vec2));          
    // a = f(...)
    case (DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef=cr)),_,_,_,(id,vec1,vec2))
      equation
        // check if cref is not also at the other side
        false = expHasCref(e2, cr);
        // get Vars
        (_,ilst) = BackendVariable.getVar(cr,vars);
        // size equal        
        true = intEq(size,listLength(ilst));
        // unassgned
        unassignedLst(ilst,vec1);
        // assign
        assignLst(ilst,id,vec1,vec2);
      then ((id+size,vec1,vec2));      
    // f(...) = a
    case (_,DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef=cr)),_,_,(id,vec1,vec2))
      equation
        // check if cref is not also at the other side
        false = expHasCref(e1, cr);
        // get Vars
        (_,ilst) = BackendVariable.getVar(cr,vars);
        // size equal        
        true = intEq(size,listLength(ilst));
        // unassgned
        unassignedLst(ilst,vec1);        
        // assign
        assignLst(ilst,id,vec1,vec2);
      then ((id+size,vec1,vec2));               
    // {a[1],a[2],a[3]} = f(...)
    case (_,_,_,_,(id,vec1,vec2))
      equation
        // if array get all elements
        elst = Expression.flattenArrayExpToList(e1);
        // check if all elements crefs
        crlst = List.map(elst,Expression.expCrefNegCref);
        crlst = List.uniqueOnTrue(crlst,ComponentReference.crefEqualNoStringCompare);  
        true = intEq(size,listLength(crlst));
        cr::crlst1 = crlst;
        blst = List.map1(crlst1,ComponentReference.crefEqualWithoutLastSubs,cr);
        true = Util.boolAndList(blst);
        // check if crefs no on other side
        set = HashSet.emptyHashSet();
        crnosubs = ComponentReference.crefStripLastSubs(cr);
        set = addCrefandParentsToSet(crnosubs,set,NONE());
        set = List.fold(crlst,BaseHashSet.add,set);
        ((_,(_,false))) = Expression.traverseExpTopDown(e2, expHasCreftraverser, (set,false));        
        (_,ilst) = BackendVariable.getVarLst(crlst,vars,{},{});
        // unassgned
        unassignedLst(ilst,vec1);        
        // assign
        assignLst(ilst,id,vec1,vec2);    
      then ((id+size,vec1,vec2));
    // f(...) = {a[1],a[2],a[3]} 
    case (_,_,_,_,(id,vec1,vec2))
      equation
        // if array get all elements
        elst = Expression.flattenArrayExpToList(e2);
        // check if all elements crefs
        crlst = List.map(elst,Expression.expCrefNegCref);
        crlst = List.uniqueOnTrue(crlst,ComponentReference.crefEqualNoStringCompare);  
        true = intEq(size,listLength(crlst));
        cr::crlst1 = crlst;
        blst = List.map1(crlst1,ComponentReference.crefEqualWithoutLastSubs,cr);
        true = Util.boolAndList(blst);
        // check if crefs no on other side
        set = HashSet.emptyHashSet();
        crnosubs = ComponentReference.crefStripLastSubs(cr);
        set = addCrefandParentsToSet(crnosubs,set,NONE());
        set = List.fold(crlst,BaseHashSet.add,set);
        ((_,(_,false))) = Expression.traverseExpTopDown(e1, expHasCreftraverser, (set,false));        
        (_,ilst) = BackendVariable.getVarLst(crlst,vars,{},{});
        // unassgned
        unassignedLst(ilst,vec1);         
        // assign
        assignLst(ilst,id,vec1,vec2);    
      then ((id+size,vec1,vec2));
  end matchcontinue;
end vectorMatching1;

protected function naturalMatching
"function naturalMatching 
 author: Frenkel TUD 2011-05" 
  input BackendDAE.Equation eqn;
  input BackendDAE.Variables vars;
  input tuple<Integer,array<Integer>,array<Integer>> inTpl;
  output tuple<Integer,array<Integer>,array<Integer>> outTpl;
algorithm
  outTpl := matchcontinue(eqn,vars,inTpl)
    local 
      Integer id,i;
      array<Integer> vec1,vec2;
      DAE.ComponentRef cr;
      DAE.Exp e,e1,e2;
      list<BackendDAE.Var> vlst;
      
    case (BackendDAE.EQUATION(exp = DAE.CREF(componentRef=cr)),_,(id,vec1,vec2))
      equation
        false = intGt(vec2[id],0);
        (_,i::_) = BackendVariable.getVar(cr,vars);
        false = intGt(vec1[i],0);
        vec1 = arrayUpdate(vec1,i,id);
        vec2 = arrayUpdate(vec2,id,i);
      then ((id+1,vec1,vec2));
    case (_,_,(id,vec1,vec2))
      then ((id+1,vec1,vec2));
  end matchcontinue;
end naturalMatching;

protected function naturalMatching1
"function naturalMatching1 
 author: Frenkel TUD 2011-05" 
  input BackendDAE.Equation eqn;
  input BackendDAE.Variables vars;
  input tuple<Integer,array<Integer>,array<Integer>> inTpl;
  output tuple<Integer,array<Integer>,array<Integer>> outTpl;
algorithm
  outTpl := matchcontinue(eqn,vars,inTpl)
    local 
      Integer id,i;
      array<Integer> vec1,vec2;
      DAE.ComponentRef cr;
      DAE.Exp e,e1,e2;
      list<BackendDAE.Var> vlst;

    case (BackendDAE.EQUATION(scalar = DAE.CREF(componentRef=cr)),_,(id,vec1,vec2))
      equation
        false = intGt(vec2[id],0);
        (_,i::_) = BackendVariable.getVar(cr,vars);
        false = intGt(vec1[i],0);
        vec1 = arrayUpdate(vec1,i,id);
        vec2 = arrayUpdate(vec2,id,i);
      then ((id+1,vec1,vec2));
    case (_,_,(id,vec1,vec2))
      then ((id+1,vec1,vec2));
  end matchcontinue;
end naturalMatching1;

protected function naturalMatching2
"function naturalMatching2 
 author: Frenkel TUD 2011-05" 
  input BackendDAE.Equation eqn;
  input BackendDAE.Variables vars;
  input tuple<Integer,array<Integer>,array<Integer>> inTpl;
  output tuple<Integer,array<Integer>,array<Integer>> outTpl;
algorithm
  outTpl := matchcontinue(eqn,vars,inTpl)
    local 
      Integer id,i;
      array<Integer> vec1,vec2;
      DAE.ComponentRef cr;
      DAE.Exp e,e1,e2;
      list<BackendDAE.Var> vlst;
     
    case (BackendDAE.EQUATION(exp=e1,scalar = e2),_,(id,vec1,vec2))
      equation
        false = intGt(vec2[id],0);
        e = Expression.expSub(e1,e2);
        vlst = BackendDAEUtil.varList(BackendEquation.equationVars(eqn,vars));
        (cr,i) = getConstOneVariable(vlst,e,vec1,vars);
        vec1 = arrayUpdate(vec1,i,id);
        vec2 = arrayUpdate(vec2,id,i);
      then ((id+1,vec1,vec2));
    case (_,_,(id,vec1,vec2))
      then ((id+1,vec1,vec2));
  end matchcontinue;
end naturalMatching2;

protected function getConstOneVariable
"function getConstOneVariable 
 author: Frenkel TUD 2011-05" 
  input list<BackendDAE.Var> vlst;
  input DAE.Exp e;
  input array<Integer> vec1;
  input BackendDAE.Variables vars;
  output DAE.ComponentRef outCr;
  output Integer i;
algorithm
  (outCr,i) := matchcontinue(vlst,e,vec1,vars)
    local 
      BackendDAE.Var v;
      list<BackendDAE.Var> rest;
      DAE.ComponentRef cr;
      DAE.Exp e1,e2;
      Integer i;
    case (v::rest,_,_,_)
      equation
        cr = BackendVariable.varCref(v);
        (_,i::_) = BackendVariable.getVar(cr,vars);
        false = intGt(vec1[i],0);        
        e1 = Derive.differentiateExp(e, cr, false);
        (e2,_) = ExpressionSimplify.simplify(e1);
        true = Expression.isConstOne(e2) or Expression.isConstMinusOne(e2);
      then
        (cr,i);
    case (_::rest,_,_,_)
      equation
        (cr,i) = getConstOneVariable(rest,e,vec1,vars);
      then
        (cr,i);
  end matchcontinue;
end getConstOneVariable;

end OnRelaxation;
