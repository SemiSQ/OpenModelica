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

encapsulated package Matching
" file:        Matching.mo
  package:     Matching
  description: Matching contains functions for matching algorithms
               
  RCS: $Id: Matching.mo 11428 2012-03-14 17:38:09Z Frenkel TUD $"


public import Absyn;
public import BackendDAE;
public import DAE;

protected import BackendDAEEXT;
protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import Flags;
protected import IndexReduction;
protected import List;
protected import Util;
protected import System;


/*************************************/
/*   Interfaces */
/*************************************/

partial function StructurallySingularSystemHandlerFunc
  input list<Integer> eqns;
  input Integer actualEqn;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input array<Integer> inAssignments1;
  input array<Integer> inAssignments2;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output list<Integer> changedEqns;
  output Integer continueEqn;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output array<Integer> outAssignments1;
  output array<Integer> outAssignments2; 
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
end StructurallySingularSystemHandlerFunc; 

partial function matchingAlgorithmFunc
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
end matchingAlgorithmFunc;


/*************************************/
/*   Matching Algorithms */
/*************************************/

public function DFSLH
"function: DFSLH"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      array<Integer> vec1,vec2,emark,vmark;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;      
      list<Integer> unassigned;

    case (BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        checkSystemForMatching(nvars,neqns,inMatchingOptions);
        vmark = arrayCreate(nvars,-1);
        emark = arrayCreate(neqns,-1);
        vec1 = arrayCreate(nvars,-1);
        vec2 = arrayCreate(neqns,-1);
        _ = ks_rand_cheapmatching(nvars,neqns,m,mt,vec1,vec2);
        (vec1,vec2,syst,shared,arg) = DFSLH2(isyst,ishared,nvars,neqns,1,emark,vmark,vec1,vec2,inMatchingOptions,sssHandler,inArg);
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(vec1,vec2,{})); 
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,ishared,inArg);        
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "- Matching.DFSLH failed\n");
      then
        fail();
  end matchcontinue;
end DFSLH;

protected function DFSLH2
"function: DFSLH2
  author: PA
  This is the outer loop of the matching algorithm
  The find_path algorithm is called for each equation/variable.
  inputs:  (BackendDAE,IncidenceMatrix, IncidenceMatrixT
             ,int /* number of vars */
             ,int /* number of eqns */
             ,int /* current var */
             ,Assignments  /* assignments, array of eqn indices */
             ,Assignments /* assignments, array of var indices */
             ,MatchingOptions) /* options for matching alg. */
  outputs: (Assignments, /* assignments, array of equation indices */
              Assignments, /* assignments, list of variable indices */
              BackendDAE, BackendDAE.IncidenceMatrix, IncidenceMatrixT)"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer nv;
  input Integer nf;
  input Integer i;
  input array<Integer> emark;
  input array<Integer> vmark;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input BackendDAE.MatchingOptions inMatchingOptions9;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output array<Integer> outAssignments1;
  output array<Integer> outAssignments2;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outAssignments1,outAssignments2,osyst,oshared,outArg):=
  matchcontinue (isyst,ishared,nv,nf,i,emark,vmark,ass1,ass2,inMatchingOptions9,sssHandler,inArg)
    local
      array<Integer> ass1_1,ass2_1,ass1_2,ass2_2,ass1_3,ass2_3;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      Integer i_1,nv_1,nf_1;
      BackendDAE.EquationArray eqns;
      BackendDAE.EquationConstraints eq_cons;
      list<Integer> eqn_lst,var_lst,meqns;
      String eqn_str,var_str;
      BackendDAE.StructurallySingularSystemHandlerArg arg,arg1;
      DAE.ElementSource source;
      Absyn.Info info;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;   
      BackendDAE.MatchingOptions match_opts;   

    case (syst as BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intGe(i,nv);
        (ass1_1,ass2_1) = pathFound(m, mt, i, i,emark, vmark, ass1, ass2) "eMark(i)=vMark(i)=false; eMark(i)=vMark(i)=false exit loop";
      then
        (ass1_1,ass2_1,syst,ishared,inArg);

    case (syst as BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_,_,_,_,_,_,_)
      equation
        i_1 = i + 1;
        true = intGt(ass2[i],0);
        (ass1_2,ass2_2,syst,shared,arg) = DFSLH2(syst, ishared, nv, nf, i_1, emark, vmark, ass1, ass2, inMatchingOptions9, sssHandler, inArg);
      then
        (ass1_2,ass2_2,syst,shared,arg);

    case (syst as BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_,_,_,_,_,_,_)
      equation
        i_1 = i + 1;
        (ass1_1,ass2_1) = pathFound(m, mt, i, i,emark, vmark, ass1, ass2) "eMark(i)=vMark(i)=false" ;
        (ass1_2,ass2_2,syst,shared,arg) = DFSLH2(syst, ishared, nv, nf, i_1, emark, vmark, ass1_1, ass2_1, inMatchingOptions9, sssHandler, inArg);
      then
        (ass1_2,ass2_2,syst,shared,arg);

    case (_,_,_,_,_,_,_,_,_,match_opts as (BackendDAE.INDEX_REDUCTION(),eq_cons),_,_)
      equation
        meqns = getMarked(nf,i,emark,{});
        (_,i_1,syst,shared,ass1_1,ass2_1,arg) = sssHandler(meqns,i,isyst,ishared,ass1,ass2,inArg) 
        "path_found failed, Try index reduction using dummy derivatives.
         When a constraint exist between states and index reduction is needed
         the dummy derivative will select one of the states as a dummy state
         (and the derivative of that state as a dummy derivative).
         For instance, u1=u2 is a constraint between states. Choose u1 as dummy state
         and der(u1) as dummy derivative, named der_u1. The differentiated function
         then becomes: der_u1 = der(u2).
         In the dummy derivative method this equation is added and the original equation
         u1=u2 is kept. This is not the case for the original pantilides algorithm, where
         the original equation is removed from the system." ;
        eqns = BackendEquation.daeEqns(syst);
        nf_1 = BackendDAEUtil.equationSize(eqns) "and try again, restarting. This could be optimized later. It should not
                                   be necessary to restart the matching, according to Bernard Bachmann. Instead one
                                   could continue the matching as usual. This was tested (2004-11-22) and it does not
                                   work to continue without restarting.
                                   For instance the Influenca model \"../testsuite/mofiles/Influenca.mo\" does not work if
                                   not restarting.
                                   2004-12-29 PA. This was a bug, assignment lists needed to be expanded with the size
                                   of the system in order to work. SO: Matching is not needed to be restarted from
                                   scratch." ;
        nv_1 = BackendVariable.varsSize(BackendVariable.daeVars(syst));
        ass1_2 = assignmentsArrayExpand(ass1_1, nv_1,arrayLength(ass1_1),-1);
        ass2_2 = assignmentsArrayExpand(ass2_1, nf_1,arrayLength(ass2_1),-1);
        vmark = assignmentsArrayExpand(vmark, nv_1,arrayLength(vmark),-1);
        emark = assignmentsArrayExpand(emark, nf_1,arrayLength(emark),-1);
        (ass1_3,ass2_3,syst,shared,arg1) = DFSLH2(syst,shared,nv_1,nf_1,i_1,emark, vmark,ass1_2,ass2_2,match_opts,sssHandler,arg);
      then
        (ass1_3,ass2_3,syst,shared,arg1);

    else
      equation
        // "When index reduction also fails, the model is structurally singular." ;
        eqn_lst = getMarked(nf,i,emark,{});
        var_lst = getMarked(nv,i,vmark,{});
        eqn_str = BackendDump.dumpMarkedEqns(isyst, eqn_lst);
        var_str = BackendDump.dumpMarkedVars(isyst, var_lst);
        i_1::_ = eqn_lst;
        source = BackendEquation.markedEquationSource(isyst, i_1);
        info = DAEUtil.getElementSourceFileInfo(source);
        Error.addSourceMessage(Error.STRUCT_SINGULAR_SYSTEM, {eqn_str,var_str}, info);
      then
        fail();
  end matchcontinue;
end DFSLH2;

protected function pathFound "function: pathFound
  author: PA
  This function is part of the matching algorithm.
  It tries to find a matching for the equation index given as
  third argument, i.
  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT, int /* equation */,
               Assignments, Assignments)
  outputs: (Assignments, Assignments)"
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer i;
  input Integer imark;
  input array<Integer> emark;
  input array<Integer> vmark;
  input array<Integer> ass1;
  input array<Integer> ass2;
  output array<Integer> outAssignments1;
  output array<Integer> outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (m,mt,i,imark,emark,vmark,ass1,ass2)
    local
      array<Integer> ass1_1,ass2_1;
    case (_,_,_,_,_,_,_,_)
      equation
        _ = arrayUpdate(emark,i,imark) "Side effect";
        (ass1_1,ass2_1) = assignOneInEqn(m, mt, i, ass1, ass2);
      then
        (ass1_1,ass2_1);
    case (_,_,_,_,_,_,_,_)
      equation
        (ass1_1,ass2_1) = forallUnmarkedVarsInEqn(m, mt, i, imark, emark, vmark, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end pathFound;

protected function assignOneInEqn "function: assignOneInEqn
  author: PA
  Helper function to pathFound."
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer i;
  input array<Integer> ass1;
  input array<Integer> ass2;
  output array<Integer> outAssignments1;
  output array<Integer> outAssignments2;
protected
  list<Integer> vars;
algorithm
  vars := BackendDAEUtil.varsInEqn(m, i);
  (outAssignments1,outAssignments2):= assignFirstUnassigned(i, vars, ass1, ass2);
end assignOneInEqn;

protected function assignFirstUnassigned
"function: assignFirstUnassigned
  author: PA
  This function assigns the first unassign variable to the equation
  given as first argument. It is part of the matching algorithm.
  inputs:  (int /* equation */,
            int list /* variables */,
            BackendDAE.Assignments /* ass1 */,
            BackendDAE.Assignments /* ass2 */)
  outputs: (Assignments,  /* ass1 */
            Assignments)  /* ass2 */"
  input Integer i;
  input list<Integer> inIntegerLst2;
  input array<Integer> ass1;
  input array<Integer> ass2;
  output array<Integer> outAssignments1;
  output array<Integer> outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (i,inIntegerLst2,ass1,ass2)
    local
      array<Integer> ass1_1,ass2_1;
      Integer v;
      list<Integer> vs;
    case (_,(v :: vs),_,_)
      equation
        false = intGt(ass1[v],0);
        ass1_1 = arrayUpdate(ass1,v,i);
        ass2_1 = arrayUpdate(ass2,i,v);
      then
        (ass1_1,ass2_1);
    case (_,(v :: vs),_,_)
      equation
        (ass1_1,ass2_1) = assignFirstUnassigned(i, vs, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end assignFirstUnassigned;

protected function forallUnmarkedVarsInEqn
"function: forallUnmarkedVarsInEqn
  author: PA
  This function is part of the matching algorithm.
  It loops over all umarked variables in an equation.
  inputs:  (IncidenceMatrix,
            IncidenceMatrixT,
            int,
            BackendDAE.Assignments /* ass1 */,
            BackendDAE.Assignments /* ass2 */)
  outputs: (Assignments, Assignments)"
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer i;
  input Integer imark;
  input array<Integer> emark;
  input array<Integer> vmark;  
  input array<Integer> ass1;
  input array<Integer> ass2;
  output array<Integer> outAssignments1;
  output array<Integer> outAssignments2;
protected
  list<Integer> vars,vars_1;
algorithm
  vars := BackendDAEUtil.varsInEqn(m, i);
  vars_1 := List.filter1(vars, isNotVMarked, (imark, vmark));
 (outAssignments1,outAssignments2) := forallUnmarkedVarsInEqnBody(m, mt, i, imark, emark, vmark, vars_1, ass1, ass2);
end forallUnmarkedVarsInEqn;

protected function isNotVMarked
"function: isNotVMarked
  author: PA
  This function succeds for variables that are not marked."
  input Integer i;
  input tuple<Integer,array<Integer>> inTpl;
protected
  Integer imark;
  array<Integer> vmark;
algorithm
  (imark,vmark) := inTpl;
  false := intEq(imark,vmark[i]);
end isNotVMarked;

protected function forallUnmarkedVarsInEqnBody
"function: forallUnmarkedVarsInEqnBody
  author: PA
  This function is part of the matching algorithm.
  It is the body of the loop over all unmarked variables.
  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT,
            int,
            int list /* var list */
            Assignments
            Assignments)
  outputs: (Assignments, Assignments)"
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer i;
  input Integer imark;
  input array<Integer> emark;
  input array<Integer> vmark;   
  input list<Integer> inIntegerLst4;
  input array<Integer> ass1;
  input array<Integer> ass2;
  output array<Integer> outAssignments1;
  output array<Integer> outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (m,mt,i,imark,emark,vmark,inIntegerLst4,ass1,ass2)
    local
      Integer assarg,v;
      array<Integer> ass1_1,ass2_1,ass1_2,ass2_2;
      list<Integer> vars,vs;
    case (_,_,_,_,_,_,(vars as (v :: vs)),_,_)
      equation
        _ = arrayUpdate(vmark,v,imark);
        assarg = ass1[v];
        (ass1_1,ass2_1) = pathFound(m, mt, assarg, imark, emark, vmark, ass1, ass2);
        ass1_2 = arrayUpdate(ass1_1,v,i);
        ass2_2 = arrayUpdate(ass2_1,i,v);       
      then
        (ass1_2,ass2_2);
    case (_,_,_,_,_,_,(vars as (v :: vs)),_,_)
      equation
        (ass1_1,ass2_1) = forallUnmarkedVarsInEqnBody(m, mt, i, imark, emark, vmark, vs, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end forallUnmarkedVarsInEqnBody;


public function BFSB
"function Breath first search based algorithm using augmenting paths
          complexity O(n*tau)
 autor: Frenkel TUD 2012-03"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg; 
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;    
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> rowmarks,parentcolum;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;      
      list<Integer> unassigned;

    case (BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        checkSystemForMatching(nvars,neqns,inMatchingOptions);
        rowmarks = arrayCreate(nvars,-1);
        parentcolum = arrayCreate(nvars,-1);
        vec1 = arrayCreate(neqns,-1);
        vec2 = arrayCreate(nvars,-1);
        _ = ks_rand_cheapmatching(nvars,neqns,m,mt,vec1,vec2);
        (vec1,vec2,syst,shared,arg) = BFSB1(1,1,nvars,neqns,m,mt,rowmarks,parentcolum,vec1,vec2,isyst,ishared,inMatchingOptions, sssHandler, inArg);
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,ishared,inArg);         
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "- Matching.BFSB failed\n");
      then
        fail();
  end matchcontinue;
end BFSB;

protected function BFSB1
"function helper for BFSB, traverses all colums and perform a BFSB phase on each
 autor: Frenkel TUD 2012-03"
  input Integer i;
  input Integer rowmark;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> rowmarks;
  input array<Integer> parentcolum;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output array<Integer> outAss1;
  output array<Integer> outAss2;  
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outAss1,outAss2,osyst,oshared,outArg):=
  matchcontinue (i,rowmark,nv,ne,m,mT,rowmarks,parentcolum,ass1,ass2,isyst,ishared,inMatchingOptions,sssHandler,inArg)
    local 
      list<Integer> visitedcolums;
      String s;
      BackendDAE.IncidenceMatrix m1,mt1;
      Integer nv_1,ne_1,i_1;
      BackendDAE.EquationConstraints eq_cons;
      BackendDAE.StructurallySingularSystemHandlerArg arg,arg1;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;    
      array<Integer> ass1_1,ass1_2,ass2_1,ass2_2,rowmarks1;      
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true=intGt(i,ne);
      then
        (ass1,ass2,isyst,ishared,inArg);
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // not assigned
        false = intGt(ass1[i],0);
        // search augmenting paths
        visitedcolums = BFSBphase({i},rowmark,i,nv,ne,m,mT,rowmarks,parentcolum,ass1,ass2,{},{});
        // if visitedcolums is not zero matching fails -> try index reduction and matching aggain
        (_,i_1,syst as BackendDAE.EQSYSTEM(m=SOME(m1),mT=SOME(mt1)),shared,nv_1,ne_1,ass1_1,ass2_1,arg) = reduceIndexifNecessary(visitedcolums,i,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg);
        rowmarks1 = assignmentsArrayExpand(rowmarks,nv_1,arrayLength(rowmarks),-1);
        (ass1_2,ass2_2,syst,shared,arg) = BFSB1(i_1,rowmark+1,nv_1,ne_1,m1,mt1,rowmarks1,parentcolum,ass1_1,ass2_1,syst,shared,inMatchingOptions,sssHandler,arg);
      then
        (ass1_2,ass2_2,syst,shared,arg);
        
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intGt(ass1[i],0);
        (ass1_1,ass2_1,syst,shared,arg) = BFSB1(i+1,rowmark,nv,ne,m,mT,rowmarks,parentcolum,ass1,ass2,isyst,ishared,inMatchingOptions,sssHandler,inArg);
      then
        (ass1_1,ass2_1,syst,shared,arg);

    else
      equation
        s = "Matching.BFSB1 failed in Equation " +& intString(i) +& "\n";
        Error.addMessage(Error.INTERNAL_ERROR,{s});
      then
        fail();

  end matchcontinue;
end BFSB1;

protected function BFSBphase
"function helper for BFSB, traverses all colums and perform a BFSB phase on each
 autor: Frenkel TUD 2012-03"
  input list<Integer> queue;
  input Integer rowmark;
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> parentcolum;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<Integer> nextQueue;
  input list<Integer> inVisitedColums;
  output list<Integer> outVisitedColums "This list stores all visited collums, if no augmenting path is found 
                                         it could be used to prune the nodes, if a path is found the list is empty";
algorithm
  outVisitedColums :=
  match (queue,rowmark,i,nv,ne,m,mT,rowmarks,parentcolum,ass1,ass2,nextQueue,inVisitedColums)
    local
      list<Integer> rest,queue1,rows; 
      Integer c;  
      Boolean b;   
    case ({},_,_,_,_,_,_,_,_,_,_,{},_) then inVisitedColums;
    case ({},_,_,_,_,_,_,_,_,_,_,_,_)
       then 
         BFSBphase(nextQueue,rowmark,i,nv,ne,m,mT,rowmarks,parentcolum,ass1,ass2,{},inVisitedColums);
    case (c::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // traverse all adiacent rows
        rows = List.select(m[c], Util.intPositive);
        (queue1,b) = BFSBtraverseRows(rows,nextQueue,rowmark,i,c,nv,ne,m,mT,rowmarks,parentcolum,ass1,ass2);
      then
        BFSBphase1(b,rest,rowmark,i,nv,ne,m,mT,rowmarks,parentcolum,ass1,ass2,queue1,c::inVisitedColums);
    else
      equation
        print("Matching.BFSBphase failed in Equation " +& intString(i) +& "\n");
      then
        fail();

  end match;
end BFSBphase;

protected function BFSBphase1
"function helper for BFSB, traverses all colums and perform a BFSB phase on each
 autor: Frenkel TUD 2012-03"
  input Boolean inPathFound;
  input list<Integer> queue;
  input Integer rowmark;
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> parentcolum;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<Integer> nextQueue;
  input list<Integer> inVisitedColums;
  output list<Integer> outVisitedColums; 
algorithm
  outVisitedColums :=
  match (inPathFound,queue,rowmark,i,nv,ne,m,mT,rowmarks,parentcolum,ass1,ass2,nextQueue,inVisitedColums)
    case (true,_,_,_,_,_,_,_,_,_,_,_,_,_) then {};
    case (false,_,_,_,_,_,_,_,_,_,_,_,_,_)
      then
        BFSBphase(queue,rowmark,i,nv,ne,m,mT,rowmarks,parentcolum,ass1,ass2,nextQueue,inVisitedColums);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Matching.BFSBphase1 failed\n"});
      then
        fail();
  end match;
end BFSBphase1;

protected function BFSBtraverseRows
"function helper for BFSB, traverses all vars of a equations and search a augmenting path
 autor: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input list<Integer> queue;  
  input Integer rowmark;
  input Integer i;
  input Integer c;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> parentcolum;
  input array<Integer> ass1;
  input array<Integer> ass2;
  output list<Integer> outEqnqueue; 
  output Boolean pathFound;
algorithm
  (outEqnqueue,pathFound):=
  matchcontinue (rows,queue,rowmark,i,c,nv,ne,m,mT,rowmarks,parentcolum,ass1,ass2)
    local
      list<Integer> rest,queue1,queue2; 
      Integer rc,r;    
      Boolean b;
      case ({},_,_,_,_,_,_,_,_,_,_,_,_) then (listReverse(queue),false);
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is unmatched -> augmenting path found
        true = intLt(ass2[r],0);
        BFSBreasign(i,c,parentcolum,r,ass1,ass2);  
      then
        ({},true);
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is matched
        rc = ass2[r];
        false = intLt(rc,0);
        queue1 = BFSBenque(queue,rowmark,c,rc,r,intLt(rowmarks[r],rowmark),rowmarks,parentcolum);
        (queue2,b) = BFSBtraverseRows(rest,queue1,rowmark,i,c,nv,ne,m,mT,rowmarks,parentcolum,ass1,ass2);        
      then
        (queue2,b);
    else
      equation
        print("Matching.BFSBtraverseRows failed in Equation " +& intString(i) +& "\n");
      then
        fail();

  end matchcontinue;
end BFSBtraverseRows;

protected function BFSBreasign
"function helper for BFSB, reasignment(rematching) allong the augmenting path
 remove all edges from the assignments that are in the path
 add all other edges to the assignment
 autor: Frenkel TUD 2012-03"
  input Integer i;
  input Integer c;
  input array<Integer> parentcolum;
  input Integer l;
  input array<Integer> ass1;
  input array<Integer> ass2;
algorithm  
  _ := matchcontinue (i,c,parentcolum,l,ass1,ass2)
    local 
      Integer r,rc;
    case (_,_,_,_,_,_)
      equation
        true = intEq(i,c);
        _ = arrayUpdate(ass1,c,l);
        _ = arrayUpdate(ass2,l,c);
      then ();
    case (_,_,_,_,_,_)
      equation
        r = ass1[c];
        _ = arrayUpdate(ass1,c,l);
        _ = arrayUpdate(ass2,l,c);
        BFSBreasign(i,parentcolum[r],parentcolum,r,ass1,ass2);
      then
        ();        
   end matchcontinue;
end BFSBreasign;

protected function BFSBenque
"function helper for BFSB, enque a collum if the row is not visited
 autor: Frenkel TUD 2012-03"
  input list<Integer> queue;  
  input Integer rowmark;
  input Integer c;
  input Integer rc;
  input Integer r;
  input Boolean visited;
  input array<Integer> rowmarks;
  input array<Integer> parentcolum;
  output list<Integer> outEqnqueue;  
algorithm
  outEqnqueue:=
  match (queue,rowmark,c,rc,r,visited,rowmarks,parentcolum)   
    case (_,_,_,_,_,false,_,_) then queue;
    case (_,_,_,_,_,true,_,_)
      equation
        // mark row
        _ = arrayUpdate(rowmarks,r,rowmark);
        // store parent colum
        _ = arrayUpdate(parentcolum,r,c);
      then
        (rc::queue);        
    else
      equation
        print("Matching.BFSBenque failed!\n");
      then
        fail();

  end match;
end BFSBenque;


public function DFSB
"function Depth first search based algorithm using augmenting paths
          complexity O(n*tau)
 autor: Frenkel TUD 2012-03"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg; 
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns,memsize;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;      
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> rowmarks;
      list<Integer> unassigned;

    case (BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        checkSystemForMatching(nvars,neqns,inMatchingOptions);
        rowmarks = arrayCreate(nvars,-1);
        vec1 = arrayCreate(neqns,-1);
        vec2 = arrayCreate(nvars,-1);
        _ = ks_rand_cheapmatching(nvars,neqns,m,mt,vec1,vec2);
        (vec1,vec2,syst,shared,arg) = DFSB1(1,1,nvars,neqns,m,mt,rowmarks,vec1,vec2,isyst,ishared,inMatchingOptions,sssHandler,inArg);
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,ishared,inArg);          
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "- Matching.BFSB failed\n");
      then
        fail();
  end matchcontinue;
end DFSB;

protected function DFSB1
"function helper for DFSB, traverses all colums and perform a DFSB phase on each
 autor: Frenkel TUD 2012-03"
  input Integer i;
  input Integer rowmark;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> rowmarks;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output array<Integer> outAss1;
  output array<Integer> outAss2;  
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;   
algorithm
  (outAss1,outAss2,osyst,oshared,outArg):=
  matchcontinue (i,rowmark,nv,ne,m,mT,rowmarks,ass1,ass2,isyst,ishared,inMatchingOptions,sssHandler,inArg)
    local 
      list<Integer> visitedcolums;
      BackendDAE.IncidenceMatrix m1,mt1;
      Integer nv_1,ne_1,i_1;
      BackendDAE.EquationConstraints eq_cons;
      BackendDAE.StructurallySingularSystemHandlerArg arg,arg1;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;    
      array<Integer> ass1_1,ass1_2,ass2_1,ass2_2,rowmarks1;      
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true=intGt(i,ne);
      then
        (ass1,ass2,isyst,ishared,inArg);
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // not assigned
        false = intGt(ass1[i],0);
        // search augmenting paths
        visitedcolums = DFSBphase({i},rowmark,i,nv,ne,m,mT,rowmarks,ass1,ass2,{i});
        // if visitedcolums is not zero matching fails -> try index reduction and matching aggain
        // if visitedcolums is not zero matching fails -> try index reduction and matching aggain
        (_,i_1,syst as BackendDAE.EQSYSTEM(m=SOME(m1),mT=SOME(mt1)),shared,nv_1,ne_1,ass1_1,ass2_1,arg) = reduceIndexifNecessary(visitedcolums,i,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg);
        rowmarks1 = assignmentsArrayExpand(rowmarks,nv_1,arrayLength(rowmarks),-1);
        (ass1_2,ass2_2,syst,shared,arg) = DFSB1(i_1,rowmark+1,nv_1,ne_1,m1,mt1,rowmarks1,ass1_1,ass2_1,syst,shared,inMatchingOptions,sssHandler,arg);
      then
        (ass1_2,ass2_2,syst,shared,arg);
        
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intGt(ass1[i],0);
        (ass1_1,ass2_1,syst,shared,arg) = DFSB1(i+1,rowmark,nv,ne,m,mT,rowmarks,ass1,ass2,isyst,ishared,inMatchingOptions,sssHandler,inArg);
      then
        (ass1_1,ass2_1,syst,shared,arg);

    else
      equation
        print("Matching.DFSB1 failed in Equation " +& intString(i) +& "\n");
      then
        fail();

  end matchcontinue;
end DFSB1;

protected function DFSBphase
"function helper for DFSB, traverses all colums and perform a DFSB phase on each
 autor: Frenkel TUD 2012-03"
  input list<Integer> stack;
  input Integer i;
  input Integer c;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<Integer> inVisitedColums;
  output list<Integer> outVisitedColums "This list stores all visited collums, if no augmenting path is found 
                                         it could be used to prune the nodes, if a path is found the list is empty";
algorithm
  outVisitedColums :=
  match (stack,i,c,nv,ne,m,mT,rowmarks,ass1,ass2,inVisitedColums)
    local
      list<Integer> rows;  
    case ({},_,_,_,_,_,_,_,_,_,_) then inVisitedColums;
    case (_,_,_,_,_,_,_,_,_,_,_)
      equation
        // traverse all adiacent rows
        rows = List.select(m[c], Util.intPositive);
      then
        DFSBtraverseRows(rows,stack,i,nv,ne,m,mT,rowmarks,ass1,ass2,inVisitedColums);
    else
      equation
        print("Matching.DFSBphase failed in Equation " +& intString(c) +& "\n");
      then
        fail();

  end match;
end DFSBphase;

protected function DFSBtraverseRows
"function helper for DFSB, traverses all vars of a equations and search a augmenting path
 autor: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input list<Integer> stack;  
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<Integer> inVisitedColums;
  output list<Integer> outVisitedColums; 
algorithm
  outVisitedColums:=
  matchcontinue (rows,stack,i,nv,ne,m,mT,rowmarks,ass1,ass2,inVisitedColums)
    local
      list<Integer> rest,visitedColums; 
      Integer rc,r;   
    case ({},_,_,_,_,_,_,_,_,_,_) then inVisitedColums;
    case (r::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is unmatched -> augmenting path found
        true = intLt(ass2[r],0);
        DFSBreasign(stack,r,ass1,ass2);  
      then
        {};
    case (r::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is matched
        rc = ass2[r];
        false = intLt(rc,0);
        true = intLt(rowmarks[r],i);
        _ = arrayUpdate(rowmarks,r,i);
        visitedColums = DFSBphase(rc::stack,i,rc,nv,ne,m,mT,rowmarks,ass1,ass2,rc::inVisitedColums);
      then
        DFSBtraverseRows1(rest,stack,i,nv,ne,m,mT,rowmarks,ass1,ass2,visitedColums);
    case (_::rest,_,_,_,_,_,_,_,_,_,_)
      then
        DFSBtraverseRows(rest,stack,i,nv,ne,m,mT,rowmarks,ass1,ass2,inVisitedColums);        
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Matching.DFSBtraverseRows failed\n"});
      then
        fail();

  end matchcontinue;
end DFSBtraverseRows;

protected function DFSBtraverseRows1
"function helper for DFSBtraverseRows
 autor: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input list<Integer> stack;  
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<Integer> inVisitedColums;
  output list<Integer> outVisitedColums; 
algorithm
  outVisitedColums:=
  match (rows,stack,i,nv,ne,m,mT,rowmarks,ass1,ass2,inVisitedColums)
    case (_,_,_,_,_,_,_,_,_,_,{}) then inVisitedColums;
    else DFSBtraverseRows(rows,stack,i,nv,ne,m,mT,rowmarks,ass1,ass2,inVisitedColums);
  end match;
end DFSBtraverseRows1;

protected function DFSBreasign
"function helper for DFSB, reasignment(rematching) allong the augmenting path
 remove all edges from the assignments that are in the path
 add all other edges to the assignment
 autor: Frenkel TUD 2012-03"
  input list<Integer> stack;
  input Integer r;
  input array<Integer> ass1;
  input array<Integer> ass2;
algorithm  
  _ := match (stack,r,ass1,ass2)
    local 
      Integer c,rc;
      list<Integer> rest;
    case ({},_,_,_) then ();
    case (c::rest,_,_,_)
      equation
        rc = ass1[c];
        _ = arrayUpdate(ass1,c,r);
        _ = arrayUpdate(ass2,r,c);
        DFSBreasign(rest,rc,ass1,ass2);
      then ();
   end match;
end DFSBreasign;

public function MC21A
"function Depth first search based algorithm using augmenting paths with lookahead mechanism
          complexity O(n*tau)
 autor: Frenkel TUD 2012-03"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg; 
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;      
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> rowmarks,lookahead;
      list<Integer> unassigned;

    case (syst as BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        checkSystemForMatching(nvars,neqns,inMatchingOptions);
        rowmarks = arrayCreate(nvars,-1);
        lookahead = arrayCreate(neqns,0);
        vec1 = arrayCreate(neqns,-1);
        vec2 = arrayCreate(nvars,-1);
        _ = ks_rand_cheapmatching(nvars,neqns,m,mt,vec1,vec2);        
        (vec1,vec2,syst,shared,arg) = MC21A1(1,1,nvars,neqns,m,mt,rowmarks,lookahead,vec1,vec2,isyst,ishared,inMatchingOptions,sssHandler,inArg);
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,ishared,inArg);        
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "- Matching.MC21A failed\n");
      then
        fail();
  end matchcontinue;
end MC21A;

protected function MC21A1
"function helper for MC21A, traverses all colums and perform a MC21A phase on each
 autor: Frenkel TUD 2012-03"
  input Integer i;
  input Integer rowmark;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output array<Integer> outAss1;
  output array<Integer> outAss2;  
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outAss1,outAss2,osyst,oshared,outArg):=
  matchcontinue (i,rowmark,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,isyst,ishared,inMatchingOptions,sssHandler,inArg)
    local 
      list<Integer> visitedcolums,changedEqns;
      BackendDAE.IncidenceMatrix m1,mt1;
      Integer nv_1,ne_1,i_1;
      BackendDAE.EquationConstraints eq_cons;
      BackendDAE.StructurallySingularSystemHandlerArg arg,arg1;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;    
      array<Integer> ass1_1,ass1_2,ass2_1,ass2_2,rowmarks1,lookahead1;
            
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true=intGt(i,ne);
      then
        (ass1,ass2,isyst,ishared,inArg);
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // not assigned
        false = intGt(ass1[i],0);
        // search augmenting paths
        visitedcolums = MC21Aphase({i},rowmark,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,{i});
        // if visitedcolums is not zero matching fails -> try index reduction and matching aggain
        (changedEqns,i_1,syst as BackendDAE.EQSYSTEM(m=SOME(m1),mT=SOME(mt1)),shared,nv_1,ne_1,ass1_1,ass2_1,arg) = reduceIndexifNecessary(visitedcolums,i,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg);
        (rowmarks1,lookahead1) = MC21A1fixArrays(visitedcolums,nv_1,ne_1,rowmarks,lookahead,changedEqns);
        (ass1_2,ass2_2,syst,shared,arg) = MC21A1(i_1,rowmark+1,nv_1,ne_1,m1,mt1,rowmarks1,lookahead1,ass1_1,ass2_1,syst,shared,inMatchingOptions,sssHandler,arg);
      then
        (ass1_2,ass2_2,syst,shared,arg);
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intGt(ass1[i],0);
        (ass1_1,ass2_1,syst,shared,arg) = MC21A1(i+1,rowmark,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,isyst,ishared,inMatchingOptions,sssHandler,inArg); 
      then
        (ass1_1,ass2_1,syst,shared,arg);
    else
      equation
        print("Matching.MC21A1 failed in Equation " +& intString(i) +& "\n");
      then
        fail();
  end matchcontinue;
end MC21A1;

protected function MC21A1fixArrays
"function: MC21A1fixArrays, fixes lookahead and rowmarks after system has been index reduced
  author: Frenkel TUD 2012-04"
  input list<Integer> meqns "Marked Equations for Index Reduction";
  input Integer nv;
  input Integer ne;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input list<Integer> changedEqns;
  output array<Integer> outrowmarks;
  output array<Integer> outlookahead;
algorithm
  (outrowmarks,outlookahead):=
  match (meqns,nv,ne,rowmarks,lookahead,changedEqns)
    local
      Integer memsize;
      array<Integer> rowmarks1,lookahead1;  
    case ({},_,_,_,_,_) then (rowmarks,lookahead);
    case (_::_,_,_,_,_,_)
      equation
        memsize = arrayLength(rowmarks);
        rowmarks1 = assignmentsArrayExpand(rowmarks,nv,memsize,-1);
        lookahead1 = assignmentsArrayExpand(lookahead,ne,memsize,0);
        MC21A1fixArray(changedEqns,lookahead1);
      then
        (rowmarks1,lookahead1);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Matching.MC21A1fixArrays failed!\n"});
      then
        fail();        
  end match;
end MC21A1fixArrays;

protected function MC21A1fixArray
"function: MC21A1fixArray
  author: Frenkel TUD 2012-04"
  input list<Integer> meqns "Marked Equations for Index Reduction";
  input array<Integer> arr;
algorithm
  _ :=
  match (meqns,arr)
    local
      Integer e;
      list<Integer> rest;  
    case ({},_) then ();
    case (e::rest,_)
      equation
        _= arrayUpdate(arr,e,0);
        MC21A1fixArray(rest,arr);
      then
        ();
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Matching.MC21A1fixArray failed!\n"});
      then
        fail();        
  end match;
end MC21A1fixArray;

protected function MC21Aphase
"function helper for MC21A, traverses all colums and perform a MC21A phase on each
 autor: Frenkel TUD 2012-03"
  input list<Integer> stack;
  input Integer i;
  input Integer c;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<Integer> inVisitedColums;
  output list<Integer> outVisitedColums "This list stores all visited collums, if no augmenting path is found 
                                         it could be used to prune the nodes, if a path is found the list is empty";
algorithm
  outVisitedColums :=
  match (stack,i,c,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inVisitedColums)
    local
      list<Integer> rows;  
      Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_,_) then inVisitedColums;
    case (_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // traverse all adiacent rows
        rows = List.select(m[c], Util.intPositive);
        b = intLt(lookahead[c],listLength(rows));
     then
        MC21Achecklookahead(b,rows,stack,i,c,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inVisitedColums);
    else
      equation
        print("Matching.MC21Aphase failed in Equation " +& intString(c) +& "\n");
      then
        fail();
  end match;
end MC21Aphase;

protected function MC21Achecklookahead
"function helper for MC21A, traverses all vars of a equations and search a augmenting path
 autor: Frenkel TUD 2012-03"
  input Boolean dolookahaed;
  input list<Integer> rows;
  input list<Integer> stack;  
  input Integer i;
  input Integer c;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<Integer> inVisitedColums;
  output list<Integer> outVisitedColums; 
algorithm
  outVisitedColums:=
  match (dolookahaed,rows,stack,i,c,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inVisitedColums)
    case (true,_,_,_,_,_,_,_,_,_,_,_,_,_)
      then 
        MC21AtraverseRowsUnmatched(rows,rows,stack,i,c,listLength(rows),nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inVisitedColums);
    else
      MC21AtraverseRows(rows,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inVisitedColums);
  end match;
end MC21Achecklookahead;

protected function MC21AtraverseRowsUnmatched
"function helper for MC21A, traverses all vars of a equations and search a augmenting path
 autor: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input list<Integer> rows1;
  input list<Integer> stack;  
  input Integer i;
  input Integer c;
  input Integer l;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<Integer> inVisitedColums;
  output list<Integer> outVisitedColums; 
algorithm
  outVisitedColums:=
  matchcontinue (rows,rows1,stack,i,c,l,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inVisitedColums)
    local
      list<Integer> rest; 
      Integer rc,r;   
    case ({},_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        _ = arrayUpdate(lookahead,c,l);
       then 
         MC21AtraverseRows(rows1,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inVisitedColums);
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is unmatched -> augmenting path found
        true = intLt(ass2[r],0);
        DFSBreasign(stack,r,ass1,ass2);  
      then
        {};         
    case (_::rest,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      then
        MC21AtraverseRowsUnmatched(rest,rows1,stack,i,c,l,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inVisitedColums);
  end matchcontinue;
end MC21AtraverseRowsUnmatched;

protected function MC21AtraverseRows
"function helper for MC21A, traverses all vars of a equations and search a augmenting path
 autor: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input list<Integer> stack;  
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<Integer> inVisitedColums;
  output list<Integer> outVisitedColums; 
algorithm
  outVisitedColums:=
  matchcontinue (rows,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inVisitedColums)
    local
      list<Integer> rest,visitedColums; 
      Integer rc,r;   
    case ({},_,_,_,_,_,_,_,_,_,_,_) then inVisitedColums;
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is matched
        rc = ass2[r];
        false = intLt(rc,0);
        true = intLt(rowmarks[r],i);
        _ = arrayUpdate(rowmarks,r,i);
        visitedColums = MC21Aphase(rc::stack,i,rc,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,rc::inVisitedColums);
      then
        MC21AtraverseRows1(rest,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,visitedColums);
    case (_::rest,_,_,_,_,_,_,_,_,_,_,_)
      then
        MC21AtraverseRows(rest,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inVisitedColums);        
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Matching.MC21AtraverseRows failed\n"});
      then
        fail();
  end matchcontinue;
end MC21AtraverseRows;

protected function MC21AtraverseRows1
"function helper for MC21AtraverseRows
 autor: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input list<Integer> stack;  
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<Integer> inVisitedColums;
  output list<Integer> outVisitedColums; 
algorithm
  outVisitedColums:=
  match (rows,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inVisitedColums)
    case (_,_,_,_,_,_,_,_,_,_,_,{}) then inVisitedColums;
    else MC21AtraverseRows(rows,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inVisitedColums);
  end match;
end MC21AtraverseRows1;


public function PF
"function Depth first search based algorithm using augmenting paths with lookahead mechanism
          complexity O(n*tau)
 autor: Frenkel TUD 2012-03"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg; 
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;      
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> rowmarks,lookahead;
      list<Integer> unmatched;      
    case (BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        checkSystemForMatching(nvars,neqns,inMatchingOptions);
        vec1 = arrayCreate(neqns,-1);
        vec2 = arrayCreate(nvars,-1);
        rowmarks = arrayCreate(nvars,-1);
        lookahead = arrayCreate(neqns,0);        
        //unmatched = List.intRange(neqns);
        //unmatched = cheapmatching(1,nvars,neqns,m,mt,vec1,vec2,{});
        unmatched = ks_rand_cheapmatching(nvars,neqns,m,mt,vec1,vec2);
        (vec1,vec2,syst,shared,arg) = PF1(0,unmatched,rowmarks,lookahead,isyst,ishared,nvars,neqns,vec1,vec2,inMatchingOptions,sssHandler,inArg);
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,ishared,inArg);        
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "- Matching.PF failed\n");
      then
        fail();
  end matchcontinue;
end PF;

protected function PF1
"function: PF1, helper for PF
  author: Frenkel TUD 2012-03"
  input Integer i;
  input list<Integer> unmatched;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer nv;
  input Integer ne;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output array<Integer> outAss1;
  output array<Integer> outAss2;  
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outAss1,outAss2,osyst,oshared,outArg):=
  matchcontinue (i,unmatched,rowmarks,lookahead,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg)
    local
      BackendDAE.IncidenceMatrix m,mt;
      Integer nv_1,ne_1,memsize,i_1;
      BackendDAE.EquationConstraints eq_cons;
      list<Integer> var_lst,unmatched1,changedEqns,meqns_1;
      String eqn_str,var_str;
      BackendDAE.StructurallySingularSystemHandlerArg arg,arg1;
      DAE.ElementSource source;
      Absyn.Info info;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;    
      array<Integer> ass1_1,ass1_2,ass1_3,ass2_1,ass2_2,ass2_3,rowmarks1,lookahead1; 

    case (_,{},_,_,_,_,_,_,_,_,_,_,_) 
      then 
        (ass1,ass2,isyst,ishared,inArg);
    case (_,_,_,_,syst as BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_,_,_,_)
      equation
        (i_1,unmatched1) = PFaugmentmatching(i,unmatched,nv,ne,m,mt,rowmarks,lookahead,ass1,ass2,listLength(unmatched),{});
        meqns_1 = getEqnsforIndexReduction(unmatched1,ne,m,ass2);
        (unmatched1,rowmarks1,lookahead1,nv_1,ne_1,ass1_1,ass2_1,syst,shared,arg) = PF2(meqns_1,unmatched1,{},rowmarks,lookahead,syst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg);
        (ass1_2,ass2_2,syst,shared,arg1) = PF1(i_1+1,unmatched1,rowmarks1,lookahead1,syst,shared,nv_1,ne_1,ass1,ass2,inMatchingOptions,sssHandler,arg);
      then
        (ass1_2,ass2_2,syst,shared,arg1);
    else
      equation
        eqn_str = BackendDump.dumpMarkedEqns(isyst, unmatched);
        source = BackendEquation.markedEquationSource(isyst, listGet(unmatched,1));
        info = DAEUtil.getElementSourceFileInfo(source);
        Error.addSourceMessage(Error.STRUCT_SINGULAR_SYSTEM, {eqn_str,""}, info);
      then
        fail();
  end matchcontinue;
end PF1;

protected function PF2
"function: PF2, helper for PF
  author: Frenkel TUD 2012-03"
  input list<Integer> meqns "Marked Equations for Index Reduction";
  input list<Integer> unmatched;
  input list<Integer> changedEqns;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer nv;
  input Integer ne;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output list<Integer> outunmatched;
  output array<Integer> outrowmarks;
  output array<Integer> outlookahead;  
  output Integer nvars;
  output Integer neqns;  
  output array<Integer> outAss1;
  output array<Integer> outAss2;  
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outunmatched,outrowmarks,outlookahead,nvars,neqns,outAss1,outAss2,osyst,oshared,outArg):=
  match (meqns,unmatched,changedEqns,rowmarks,lookahead,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg)
    local
      BackendDAE.IncidenceMatrix m,mt;
      Integer nv_1,ne_1,memsize,i_1;
      BackendDAE.EquationConstraints eq_cons;
      list<Integer> var_lst,meqns_1,unmatched1;
      String eqn_str,var_str;
      BackendDAE.StructurallySingularSystemHandlerArg arg,arg1;
      DAE.ElementSource source;
      Absyn.Info info;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;    
      array<Integer> ass1_1,ass1_2,ass2_1,ass2_2,rowmarks1,lookahead1; 

    case ({},_,_,_,_,_,_,_,_,_,_,_,_,_) 
      then 
        (unmatched,rowmarks,lookahead,nv,ne,ass1,ass2,isyst,ishared,inArg);
    case (_,_,_,_,_,_,_,_,_,_,_,(BackendDAE.INDEX_REDUCTION(),eq_cons),_,_)
      equation
        (unmatched1,_,syst,shared,ass2_1,ass1_1,arg) = sssHandler(meqns,0,isyst,ishared,ass2,ass1,inArg);
        ne_1 = BackendDAEUtil.systemSize(syst);
        nv_1 = BackendVariable.daenumVariables(syst);
        ass1_1 = assignmentsArrayExpand(ass1_1,ne_1,ne,-1);
        ass2_1 = assignmentsArrayExpand(ass2_1,nv_1,nv,-1);
        rowmarks1 = assignmentsArrayExpand(rowmarks,nv_1,nv,-1);
        lookahead1 = assignmentsArrayExpand(lookahead,ne_1,ne,0);
        MC21A1fixArray(unmatched1,lookahead1);   
      then
        (unmatched1,rowmarks1,lookahead1,nv_1,ne_1,ass1_1,ass2_1,syst,shared,arg);
  end match;
end PF2;

protected function PFaugmentmatching
"function helper for PFaugmentmatching, traverses all unmatched
 colums and perform one pass of the augmenting proceure
 autor: Frenkel TUD 2012-03"
  input Integer i;
  input list<Integer> U;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input Integer previousUnmatched;
  input list<Integer> unMatched;
  output Integer outI;
  output list<Integer> outUnmatched;
algorithm
  (outI,outUnmatched):=
  matchcontinue (i,U,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,previousUnmatched,unMatched)
    local 
      list<Integer> rest,rows,unmatched;
      Integer c,i_1;
      Boolean b;
    case (_,{},_,_,_,_,_,_,_,_,_,_)
      equation
        // no augmenting path is found in pass
        true=intEq(previousUnmatched,listLength(unMatched));
      then
        (i,unMatched);
    case (_,{},_,_,_,_,_,_,_,_,_,_)
      equation
       // augmenting path is found in pass, next round
       (i_1,unmatched) = PFaugmentmatching(i+1,unMatched,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,listLength(unMatched),{});
      then
        (i_1,unmatched);
    case (_,c::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intGt(ass1[c],-1);
        (i_1,unmatched) = PFaugmentmatching(i,rest,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,previousUnmatched,unMatched);
      then
        (i_1,unmatched);        
    case (_,c::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        b = PFphase({c},i,c,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2);
        unmatched = List.consOnTrue(not b, c, unMatched);
        (i_1,unmatched) = PFaugmentmatching(i,rest,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,previousUnmatched,unmatched);
      then
        (i_1,unmatched);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Matching.PFaugmentmatching failed\n"});
      then
        fail();
  end matchcontinue;
end PFaugmentmatching;

protected function PFphase
"function helper for PF, traverses all colums and perform a PF phase on each
 autor: Frenkel TUD 2012-03"
  input list<Integer> stack;
  input Integer i;
  input Integer c;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1;
  input array<Integer> ass2;
  output Boolean matched;
algorithm
  matched :=
  match (stack,i,c,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2)
    local
      list<Integer> rows;  
      Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_) then false;
    case (_,_,_,_,_,_,_,_,_,_,_)
      equation
        // traverse all adiacent rows
        rows = List.select(m[c], Util.intPositive);
        b = intLt(lookahead[c],listLength(rows));
      then
        PFchecklookahead(b,rows,stack,i,c,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2);
    else
      equation
        print("Matching.PFphase failed in Equation " +& intString(c) +& "\n");
      then
        fail();

  end match;
end PFphase;

protected function PFchecklookahead
"function helper for PF, traverses all vars of a equations and search a augmenting path
 autor: Frenkel TUD 2012-03"
  input Boolean dolookahaed;
  input list<Integer> rows;
  input list<Integer> stack;  
  input Integer i;
  input Integer c;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1;
  input array<Integer> ass2;
  output Boolean matched; 
algorithm
  matched:=
  match (dolookahaed,rows,stack,i,c,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2)
    case (true,_,_,_,_,_,_,_,_,_,_,_,_)
      then 
        PFtraverseRowsUnmatched(rows,rows,stack,i,c,listLength(rows),nv,ne,m,mT,rowmarks,lookahead,ass1,ass2);
    else
      PFtraverseRows(rows,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2);
  end match;
end PFchecklookahead;

protected function PFtraverseRowsUnmatched
"function helper for PF, traverses all vars of a equations and search a augmenting path
 autor: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input list<Integer> rows1;
  input list<Integer> stack;  
  input Integer i;
  input Integer c;
  input Integer l;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1;
  input array<Integer> ass2;
  output Boolean matched;
algorithm
  matched:=
  matchcontinue (rows,rows1,stack,i,c,l,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2)
    local
      list<Integer> rest; 
      Integer rc,r;   
    case ({},_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        _ = arrayUpdate(lookahead,c,l);
       then 
         PFtraverseRows(rows1,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2);
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is unmatched -> augmenting path found
        true = intLt(ass2[r],0);
        DFSBreasign(stack,r,ass1,ass2);  
      then
        true;         
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_,_,_)
      then
        PFtraverseRowsUnmatched(rest,rows1,stack,i,c,l,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2);
  end matchcontinue;
end PFtraverseRowsUnmatched;

protected function PFtraverseRows
"function helper for PF, traverses all vars of a equations and search a augmenting path
 autor: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input list<Integer> stack;  
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1;
  input array<Integer> ass2;
  output Boolean matched;
algorithm
  matched:=
  matchcontinue (rows,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2)
    local
      list<Integer> rest,visitedColums; 
      Integer rc,r;  
      Boolean b; 
    case ({},_,_,_,_,_,_,_,_,_,_) then false;
    case (r::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is matched
        rc = ass2[r];
        false = intLt(rc,0);
        false = intEq(rowmarks[r],i);
        _ = arrayUpdate(rowmarks,r,i);
        b = PFphase(rc::stack,i,rc,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2);
      then
        PFtraverseRows1(rest,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,b);
    case (r::rest,_,_,_,_,_,_,_,_,_,_)
      then
        PFtraverseRows(rest,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2);        
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Matching.PFtraverseRows failed\n"});
      then
        fail();
  end matchcontinue;
end PFtraverseRows;

protected function PFtraverseRows1
"function helper for PFtraverseRows
 autor: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input list<Integer> stack;  
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input Boolean inMatched;
  output Boolean matched;
algorithm
  matched:=
  match (rows,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inMatched)
    case (_,_,_,_,_,_,_,_,_,_,_,true) then inMatched;
    else PFtraverseRows(rows,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2);
  end match;
end PFtraverseRows1;

public function PFPlus
"function Depth first search based algorithm using augmenting paths with lookahead mechanism
          complexity O(n*tau)
 autor: Frenkel TUD 2012-03"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg; 
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns,i;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;      
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> rowmarks,lookahead;
      list<Integer> unmatched;      
    case (BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        checkSystemForMatching(nvars,neqns,inMatchingOptions);
        vec1 = arrayCreate(neqns,-1);
        vec2 = arrayCreate(nvars,-1);
        rowmarks = arrayCreate(nvars,-1);
        lookahead = arrayCreate(neqns,0);        
        //matchFunctionCallResultVars(syst,ishared,vec1,vec2);
        //unmatched = checkAssignment(1,neqns,vec1,vec2,{});
        //unmatched = List.intRange(neqns);
        //unmatched = cheapmatching(1,nvars,neqns,m,mt,vec1,vec2,{});
        unmatched = ks_rand_cheapmatching(nvars,neqns,m,mt,vec1,vec2);
        (i,vec1,vec2,syst,shared,arg) = PFPlus1(0,unmatched,rowmarks,lookahead,isyst,ishared,nvars,neqns,vec1,vec2,inMatchingOptions,sssHandler,inArg);
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,ishared,inArg);         
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "- Matching.PFPlus failed\n");
      then
        fail();
  end matchcontinue;
end PFPlus;

protected function PFPlus1
"function: PFPlus1, helper for PFPlus
  author: Frenkel TUD 2012-03"
  input Integer i;
  input list<Integer> unmatched;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer nv;
  input Integer ne;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output Integer outI;
  output array<Integer> outAss1;
  output array<Integer> outAss2;  
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outI,outAss1,outAss2,osyst,oshared,outArg):=
  matchcontinue (i,unmatched,rowmarks,lookahead,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg)
    local
      BackendDAE.IncidenceMatrix m,mt;
      Integer nv_1,ne_1,memsize,i_1;
      BackendDAE.EquationConstraints eq_cons;
      list<Integer> var_lst,unmatched1,changedEqns,meqns_1;
      String eqn_str,var_str;
      BackendDAE.StructurallySingularSystemHandlerArg arg,arg1;
      DAE.ElementSource source;
      Absyn.Info info;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;    
      array<Integer> ass1_1,ass1_2,ass1_3,ass2_1,ass2_2,ass2_3,rowmarks1,lookahead1; 

    case (_,{},_,_,_,_,_,_,_,_,_,_,_) 
      then 
        (i,ass1,ass2,isyst,ishared,inArg);
    case (_,_,_,_,syst as BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_,_,_,_)
      equation
        (i_1,unmatched1) = PFPlusaugmentmatching(i,unmatched,nv,ne,m,mt,rowmarks,lookahead,ass1,ass2,listLength(unmatched),{},false);
        meqns_1 = getEqnsforIndexReduction(unmatched1,ne,m,ass2);
        (unmatched1,rowmarks1,lookahead1,nv_1,ne_1,ass1_1,ass2_1,syst,shared,arg) = PF2(meqns_1,unmatched1,{},rowmarks,lookahead,syst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg);
        (i_1,ass1_2,ass2_2,syst,shared,arg1) = PFPlus1(i_1+1,unmatched1,rowmarks1,lookahead1,syst,shared,nv_1,ne_1,ass1_1,ass2_1,inMatchingOptions,sssHandler,arg);
      then
        (i_1,ass1_2,ass2_2,syst,shared,arg1);
    else
      equation
        eqn_str = BackendDump.dumpMarkedEqns(isyst, unmatched);
        source = BackendEquation.markedEquationSource(isyst, listGet(unmatched,1));
        info = DAEUtil.getElementSourceFileInfo(source);
        Error.addSourceMessage(Error.STRUCT_SINGULAR_SYSTEM, {eqn_str,""}, info);
      then
        fail();
  end matchcontinue;
end PFPlus1;

protected function PFPlusaugmentmatching
"function helper for PFPlusaugmentmatching, traverses all unmatched
 colums and perform one pass of the augmenting proceure
 autor: Frenkel TUD 2012-03"
  input Integer i;
  input list<Integer> U;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input Integer previousUnmatched;
  input list<Integer> unMatched;
  input Boolean reverseRows;
  output Integer outI;
  output list<Integer> outUnMatched;
algorithm
  (outI,outUnMatched) :=
  matchcontinue (i,U,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,previousUnmatched,unMatched,reverseRows)
    local 
      list<Integer> rest,rows,visitedcolums,unmatched;
      Integer c,i_1;
      Boolean b;
    case (_,{},_,_,_,_,_,_,_,_,_,_,_)
      equation
        // no augmenting path is found in pass
        true=intEq(previousUnmatched,listLength(unMatched));
      then
        (i,unMatched);
    case (_,{},_,_,_,_,_,_,_,_,_,_,_)
      equation
       // augmenting path is found in pass, next round
       (i_1,unmatched) = PFPlusaugmentmatching(i+1,unMatched,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,listLength(unMatched),{},reverseRows);
      then
        (i_1,unmatched);
    case (_,c::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intGt(ass1[c],-1);
        (i_1,unmatched) = PFPlusaugmentmatching(i,rest,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,previousUnmatched,unMatched,reverseRows);
      then
        (i_1,unmatched);        
    case (_,c::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        b = PFPlusphase({c},i,c,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows);
        unmatched = List.consOnTrue(not b, c, unMatched);
        (i_1,unmatched) = PFPlusaugmentmatching(i,rest,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,previousUnmatched,unmatched,not reverseRows);
      then
        (i_1,unmatched);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Matching.PFPlusaugmentmatching failed\n"});
      then
        fail();
  end matchcontinue;
end PFPlusaugmentmatching;

protected function PFPlusphase
"function helper for PFPlus, traverses all colums and perform a PFPlus phase on each
 autor: Frenkel TUD 2012-03"
  input list<Integer> stack;
  input Integer i;
  input Integer c;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input Boolean reverseRows;
  output Boolean matched;
algorithm
  matched :=
  match (stack,i,c,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows)
    local
      list<Integer> rows;  
      Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_,_) then false;
    case (_,_,_,_,_,_,_,_,_,_,_,false)
      equation
        // traverse all adiacent rows
        rows = List.select(m[c], Util.intPositive);
        b = intLt(lookahead[c],listLength(rows));
     then
        PFPluschecklookahead(b,rows,stack,i,c,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows);
    case (_,_,_,_,_,_,_,_,_,_,_,true)
      equation
        // traverse all adiacent rows
        rows = List.select(m[c], Util.intPositive);
        b = intLt(lookahead[c],listLength(rows));
      then
        PFPluschecklookahead(b,listReverse(rows),stack,i,c,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows);
    else
      equation
        print("Matching.PFPlusphase failed in Equation " +& intString(c) +& "\n");
      then
        fail();

  end match;
end PFPlusphase;

protected function PFPluschecklookahead
"function helper for PFPlus, traverses all vars of a equations and search a augmenting path
 autor: Frenkel TUD 2012-03"
  input Boolean dolookahaed;
  input list<Integer> rows;
  input list<Integer> stack;  
  input Integer i;
  input Integer c;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input Boolean reverseRows;
  output Boolean matched; 
algorithm
  matched:=
  match (dolookahaed,rows,stack,i,c,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows)
    case (true,_,_,_,_,_,_,_,_,_,_,_,_,_)
      then 
        PFPlustraverseRowsUnmatched(rows,rows,stack,i,c,listLength(rows),nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows);
    else
      PFPlustraverseRows(rows,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows);
  end match;
end PFPluschecklookahead;

protected function PFPlustraverseRowsUnmatched
"function helper for PFPlus, traverses all vars of a equations and search a augmenting path
 autor: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input list<Integer> rows1;
  input list<Integer> stack;  
  input Integer i;
  input Integer c;
  input Integer l;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input Boolean reverseRows;
  output Boolean matched;
algorithm
  matched:=
  matchcontinue (rows,rows1,stack,i,c,l,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows)
    local
      list<Integer> rest; 
      Integer rc,r;   
    case ({},_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        _ = arrayUpdate(lookahead,c,l);
       then 
         PFPlustraverseRows(rows1,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows);
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is unmatched -> augmenting path found
        true = intLt(ass2[r],0);
        DFSBreasign(stack,r,ass1,ass2);  
      then
        true;         
    case (_::rest,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      then
        PFPlustraverseRowsUnmatched(rest,rows1,stack,i,c,l,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows);
  end matchcontinue;
end PFPlustraverseRowsUnmatched;

protected function PFPlustraverseRows
"function helper for PFPlus, traverses all vars of a equations and search a augmenting path
 autor: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input list<Integer> stack;  
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input Boolean reverseRows;
  output Boolean matched; 
algorithm
  matched:=
  matchcontinue (rows,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows)
    local
      list<Integer> rest,visitedColums; 
      Integer rc,r;   
      Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_,_) then false;
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is matched
        rc = ass2[r];
        false = intLt(rc,0);
        false = intEq(rowmarks[r],i);
        _ = arrayUpdate(rowmarks,r,i);
        b = PFPlusphase(rc::stack,i,rc,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows);
      then
        PFPlustraverseRows1(rest,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,b,reverseRows);
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_)
      then
        PFPlustraverseRows(rest,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows);        
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Matching.PFPlustraverseRows failed\n"});
      then
        fail();
  end matchcontinue;
end PFPlustraverseRows;

protected function PFPlustraverseRows1
"function helper for PFPlustraverseRows
 autor: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input list<Integer> stack;  
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input Boolean inMatched;
  input Boolean reverseRows;
  output Boolean matched;
algorithm
  matched:=
  match (rows,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inMatched,reverseRows)
    case (_,_,_,_,_,_,_,_,_,_,_,true,_) then inMatched;
    else PFPlustraverseRows(rows,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows);
  end match;
end PFPlustraverseRows1;

public function HK
"function Combined BFS and DFS algorithm 
          complexity O(sqrt(n)*tau)
 autor: Frenkel TUD 2012-03"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg; 
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;      
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> rowmarks,level,collummarks;
      list<Integer> unmatched;      
    case (BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);        
        checkSystemForMatching(nvars,neqns,inMatchingOptions);
        vec1 = arrayCreate(neqns,-1);
        vec2 = arrayCreate(nvars,-1);
        rowmarks = arrayCreate(nvars,-1);
        collummarks = arrayCreate(neqns,-1);
        level = arrayCreate(neqns,-1);      
        //unmatched = List.intRange(neqns);
        //unmatched = cheapmatching(1,nvars,neqns,m,mt,vec1,vec2,{});
        unmatched = ks_rand_cheapmatching(nvars,neqns,m,mt,vec1,vec2);
        (vec1,vec2,syst,shared,arg) = HK1(0,unmatched,rowmarks,collummarks,level,isyst,ishared,nvars,neqns,vec1,vec2,inMatchingOptions,sssHandler,inArg);
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,ishared,inArg);         
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "- Matching.HK failed\n");
      then
        fail();
  end matchcontinue;
end HK;

protected function HK1
"function: HK1, helper for HK
  author: Frenkel TUD 2012-03"
  input Integer i;
  input list<Integer> unmatched;
  input array<Integer> rowmarks;
  input array<Integer> collummarks;
  input array<Integer> level;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer nv;
  input Integer ne;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output array<Integer> outAss1;
  output array<Integer> outAss2;  
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outAss1,outAss2,osyst,oshared,outArg):=
  matchcontinue (i,unmatched,rowmarks,collummarks,level,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg)
    local
      BackendDAE.IncidenceMatrix m,mt;
      Integer nv_1,ne_1,i_1;
      BackendDAE.EquationConstraints eq_cons;
      list<Integer> var_lst,unmatched1,changedEqns,meqns_1;
      String eqn_str,var_str;
      BackendDAE.StructurallySingularSystemHandlerArg arg,arg1;
      DAE.ElementSource source;
      Absyn.Info info;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;    
      array<Integer> ass1_1,ass1_2,ass1_3,ass2_1,ass2_2,ass2_3,rowmarks1,collummarks1,level1; 

    case (_,{},_,_,_,_,_,_,_,_,_,_,_,_) 
      then 
        (ass1,ass2,isyst,ishared,inArg);
    case (_,_,_,_,_,syst as BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_,_,_,_)
      equation
        (i_1,unmatched1) = HKphase(i,unmatched,nv,ne,m,mt,rowmarks,collummarks,level,ass1,ass2,listLength(unmatched),{});
        meqns_1 = getEqnsforIndexReduction(unmatched1,ne,m,ass2);
        (unmatched1,rowmarks1,collummarks1,level1,nv_1,ne_1,ass1_1,ass2_1,syst,shared,arg) = HK2(meqns_1,unmatched1,{},rowmarks,collummarks,level,syst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg);
        (ass1_2,ass2_2,syst,shared,arg1) = HK1(i_1+1,unmatched1,rowmarks1,collummarks1,level1,syst,shared,nv_1,ne_1,ass1,ass2,inMatchingOptions,sssHandler,arg);
      then
        (ass1_2,ass2_2,syst,shared,arg1);
    else
      equation
        eqn_str = BackendDump.dumpMarkedEqns(isyst, unmatched);
        source = BackendEquation.markedEquationSource(isyst, listGet(unmatched,1));
        info = DAEUtil.getElementSourceFileInfo(source);
        Error.addSourceMessage(Error.STRUCT_SINGULAR_SYSTEM, {eqn_str,""}, info);
      then
        fail();
  end matchcontinue;
end HK1;

protected function HK2
"function: HK2, helper for HK
  author: Frenkel TUD 2012-03"
  input list<Integer> meqns "Marked Equations for Index Reduction";
  input list<Integer> unmatched;
  input list<Integer> changedEqns;
  input array<Integer> rowmarks;
  input array<Integer> collummarks;
  input array<Integer> level;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer nv;
  input Integer ne;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output list<Integer> outunmatched;
  output array<Integer> outrowmarks;
  output array<Integer> outcollummarks;
  output array<Integer> outlevel;  
  output Integer nvars;
  output Integer neqns;  
  output array<Integer> outAss1;
  output array<Integer> outAss2;  
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outunmatched,outrowmarks,outcollummarks,outlevel,nvars,neqns,outAss1,outAss2,osyst,oshared,outArg):=
  match (meqns,unmatched,changedEqns,rowmarks,collummarks,level,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg)
    local
      BackendDAE.IncidenceMatrix m,mt;
      Integer nv_1,ne_1,i_1;
      BackendDAE.EquationConstraints eq_cons;
      list<Integer> var_lst,meqns_1,unmatched1;
      String eqn_str,var_str;
      BackendDAE.StructurallySingularSystemHandlerArg arg,arg1;
      DAE.ElementSource source;
      Absyn.Info info;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;    
      array<Integer> ass1_1,ass1_2,ass2_1,ass2_2,rowmarks1,collummarks1,level1; 

    case ({},_,_,_,_,_,_,_,_,_,_,_,_,_,_) 
      then 
        (unmatched,rowmarks,collummarks,level,nv,ne,ass1,ass2,isyst,ishared,inArg);
    case (_,_,_,_,_,_,_,_,_,_,_,_,(BackendDAE.INDEX_REDUCTION(),eq_cons),_,_)
      equation
        (unmatched1,_,syst,shared,ass2_1,ass1_1,arg) = sssHandler(meqns,0,isyst,ishared,ass2,ass1,inArg);
        ne_1 = BackendDAEUtil.systemSize(syst);
        nv_1 = BackendVariable.daenumVariables(syst);
        ass1_1 = assignmentsArrayExpand(ass1_1,ne_1,arrayLength(ass1),-1);
        ass2_1 = assignmentsArrayExpand(ass2_1,nv_1,arrayLength(ass2),-1);
        rowmarks1 = assignmentsArrayExpand(rowmarks,nv_1,arrayLength(rowmarks),-1);
        collummarks1 = assignmentsArrayExpand(collummarks,ne_1,arrayLength(collummarks),-1);
        level1 = assignmentsArrayExpand(level,ne_1,arrayLength(level),-1);   
      then
        (unmatched1,rowmarks1,collummarks1,level1,nv_1,ne_1,ass1_1,ass2_1,syst,shared,arg);
  end match;
end HK2;

protected function HKphase
"function helper for HK, traverses all unmatched
 colums and run a BFS and DFS
 autor: Frenkel TUD 2012-03"
  input Integer i;
  input list<Integer> U;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> rowmarks;
  input array<Integer> collummarks;
  input array<Integer> level;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input Integer previousUnmatched;
  input list<Integer> unMatched;
  output Integer outI;
  output list<Integer> outunMatched;
algorithm
  (outI,outunMatched):=
  matchcontinue (i,U,nv,ne,m,mT,rowmarks,collummarks,level,ass1,ass2,previousUnmatched,unMatched)
    local 
      list<Integer> rest,unmatched;
      list<tuple<Integer,Integer>> rows;
      Integer c,i_1;
      Boolean b;
    case (_,{},_,_,_,_,_,_,_,_,_,_,_)
      equation
        // no augmenting path is found in phase
        true=intEq(previousUnmatched,listLength(unMatched));
      then
        (i,unMatched);
    case (_,{},_,_,_,_,_,_,_,_,_,_,_)
      equation
        // augmenting path is found in phase, next round
        (i_1,unmatched) = HKphase(i+1,unMatched,nv,ne,m,mT,rowmarks,collummarks,level,ass1,ass2,listLength(unMatched),{});
      then
        (i_1,unmatched);
    case (_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // BFS phase to get the level information
        rows = HKBFS(U,nv,ne,m,mT,rowmarks,i,level,NONE(),ass1,ass2,{});
        // DFS to match 
        _ = HKDFS(rows,i,nv,ne,m,mT,collummarks,level,ass1,ass2,{});
        // remove matched collums from U
        unmatched = HKgetUnmatched(U,ass1,{});
        (i_1,unmatched) = HKphase(i,{},nv,ne,m,mT,rowmarks,collummarks,level,ass1,ass2,previousUnmatched,unmatched);
      then
        (i_1,unmatched);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Matching.HKphase failed\n"});
      then
        fail();
  end matchcontinue;
end HKphase;

protected function HKgetUnmatched
  input list<Integer> U;
  input array<Integer> ass1;
  input list<Integer> inUnmatched;
  output list<Integer> outUnmatched;
algorithm
  outUnmatched:=
  matchcontinue (U,ass1,inUnmatched)
    local 
      list<Integer> rest;
      Integer c,r;
    case ({},_,_) then inUnmatched;
    case (c::rest,_,_)
      equation
        true = intGt(ass1[c],0);
      then
        HKgetUnmatched(rest,ass1,inUnmatched);        
    case (c::rest,_,_)
      then
        HKgetUnmatched(rest,ass1,c::inUnmatched); 
  end matchcontinue;  
end HKgetUnmatched;

protected function HKBFS
"function helper for HK, traverses all colums and perform a BFSB phase on each to get the level information
 the BFS stops at a colum with unmatched rows
 autor: Frenkel TUD 2012-03"
  input list<Integer> colums;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> rowmarks;
  input Integer i;
  input array<Integer> level;
  input Option<Integer> lowestL "lowest level find unmatched rows";
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input list<tuple<Integer,Integer>> inRows "(row,level)";
  output list<tuple<Integer,Integer>> outRows "unmatched rows found by BFS";
algorithm
  outRows:=
  match (colums,nv,ne,m,mT,rowmarks,i,level,lowestL,ass1,ass2,inRows)
    local 
      list<Integer> rest;
      list<tuple<Integer,Integer>> rows;
      Integer c;
      Option<Integer> ll;
    case ({},_,_,_,_,_,_,_,_,_,_,_) then inRows;
    case (c::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        (rows,ll) = HKBFSBphase({c},i,0,lowestL,nv,ne,m,mT,rowmarks,level,ass1,ass2,inRows,{});
      then
        HKBFS(rest,nv,ne,m,mT,rowmarks,i,level,ll,ass1,ass2,rows);        
    else
      equation
        print("Matching.HKBFS failed in Phase " +& intString(i) +& "\n");
      then
        fail();
  end match;
end HKBFS;

protected function HKBFSBphase
"function helper for HKBFS, traverses all colums and perform a BFSB phase on each
 autor: Frenkel TUD 2012-03"
  input list<Integer> queue;
  input Integer i;
  input Integer l "current level";
  input Option<Integer> lowestL "lowest level find unmatched rows";
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> level;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<tuple<Integer,Integer>> inRows;
  input list<Integer> queue1;
  output list<tuple<Integer,Integer>> outRows;
  output Option<Integer> outlowestL;
algorithm
  (outRows,outlowestL) :=
  match (queue,i,l,lowestL,nv,ne,m,mT,rowmarks,level,ass1,ass2,inRows,queue1)
    local
      list<Integer> rest,queue2,cr;
      list<tuple<Integer,Integer>> rows; 
      Integer c,lowl,l_1;  
      Boolean b;   
      Option<Integer> ll;
    case ({},_,_,_,_,_,_,_,_,_,_,_,_,{}) then (inRows,lowestL);
    case ({},_,_,SOME(lowl),_,_,_,_,_,_,_,_,_,_)
      equation
        l_1 = l+1;
        b = intGt(l_1,lowl);
        (rows,ll) = HKBFSBphase1(b,queue1,i,l_1,lowestL,nv,ne,m,mT,rowmarks,level,ass1,ass2,inRows,{});
      then 
        (rows,ll);
    case ({},_,_,NONE(),_,_,_,_,_,_,_,_,_,_)
      equation
        (rows,ll) = HKBFSBphase(queue1,i,l+1,lowestL,nv,ne,m,mT,rowmarks,level,ass1,ass2,inRows,{});
      then 
        (rows,ll);        
    case (c::rest,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // traverse all adiacent rows
        cr = List.select(m[c], Util.intPositive);
        _ = arrayUpdate(level,c,l);
        (queue2,rows,b) = HKBFStraverseRows(cr,{},i,l,m,mT,rowmarks,level,ass1,ass2,inRows,false);
        queue2 = listAppend(queue1,queue2);
        ll = Util.if_(b,SOME(l),lowestL);
        (rows,ll) = HKBFSBphase(rest,i,l,ll,nv,ne,m,mT,rowmarks,level,ass1,ass2,rows,queue2);
      then
        (rows,ll);
    else
      equation
        print("Matching.HKBFSBphase failed in Phase " +& intString(i) +& "\n");
      then
        fail();

  end match;
end HKBFSBphase;

protected function HKBFSBphase1
"function helper for HKBFSB
 autor: Frenkel TUD 2012-03"
  input Boolean inUnMaRowFound;
  input list<Integer> queue;
  input Integer i;
  input Integer l;
  input Option<Integer> lowestL;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> level;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<tuple<Integer,Integer>> inRows;
  input list<Integer> queue1;
  output list<tuple<Integer,Integer>> outRows; 
  output Option<Integer> outlowestL;
algorithm
  (outRows,outlowestL) :=
  match (inUnMaRowFound,queue,i,l,lowestL,nv,ne,m,mT,rowmarks,level,ass1,ass2,inRows,queue1)
    local 
      Option<Integer> ll;
      list<tuple<Integer,Integer>> rows;
    case (true,_,_,_,_,_,_,_,_,_,_,_,_,_,_) then (inRows,SOME(l));
    case (false,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        (rows,ll) = HKBFSBphase(queue,i,l,lowestL,nv,ne,m,mT,rowmarks,level,ass1,ass2,inRows,queue1);
      then 
        (rows,ll);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Matching.HKBFSBphase1 failed\n"});
      then
        fail();
  end match;
end HKBFSBphase1;

protected function HKBFStraverseRows
"function helper for BFSB, traverses all rows of a collum and set level
 autor: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input list<Integer> queue;  
  input Integer i;
  input Integer l;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> level;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<tuple<Integer,Integer>> inRows;
  input Boolean inunmarowFound;
  output list<Integer> outEqnqueue; 
  output list<tuple<Integer,Integer>> outRows;
  output Boolean unmarowFound;
algorithm
  (outEqnqueue,outRows,unmarowFound):=
  matchcontinue (rows,queue,i,l,m,mT,rowmarks,level,ass1,ass2,inRows,inunmarowFound)
    local
      list<Integer> rest,queue1; 
      list<tuple<Integer,Integer>> rowstpl;
      Integer rc,r;    
      Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_,_) then (listReverse(queue),inRows,inunmarowFound);
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is visited
        false = intLt(rowmarks[r],i);
        (queue1,rowstpl,b) = HKBFStraverseRows(rest,queue,i,l,m,mT,rowmarks,level,ass1,ass2,inRows,inunmarowFound);  
      then
        (queue1,rowstpl,b);      
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is unmatched
        true = intLt(ass2[r],0);
        _ = arrayUpdate(rowmarks,r,i);
        (queue1,rowstpl,b) = HKBFStraverseRows(rest,queue,i,l,m,mT,rowmarks,level,ass1,ass2,(r,l)::inRows,true);  
      then
        (queue1,rowstpl,b); 
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is matched
        rc = ass2[r];
        false = intLt(rc,0);
        _ = arrayUpdate(rowmarks,r,i);
        (queue1,rowstpl,b) = HKBFStraverseRows(rest,rc::queue,i,l,m,mT,rowmarks,level,ass1,ass2,inRows,inunmarowFound);  
      then
        (queue1,rowstpl,b); 
    else
      equation
        print("Matching.HKBFStraverseRows failed in Phase " +& intString(i) +& "\n");
      then
        fail();

  end matchcontinue;
end HKBFStraverseRows;

protected function HKDFS
"function helper for HKDFSB, traverses all colums and perform a DFSB phase on each
 autor: Frenkel TUD 2012-03"
  input list<tuple<Integer,Integer>> unmatchedRows;
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> collummarks;
  input array<Integer> level;  
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input list<Integer> inUnmatchedRows;
  output list<Integer> outUnmatchedRows;
algorithm
  outUnmatchedRows:=
  match (unmatchedRows,i,nv,ne,m,mT,collummarks,level,ass1,ass2,inUnmatchedRows)
    local
       list<tuple<Integer,Integer>> rest;
       list<Integer> ur;
       Integer r,l;
       Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_) then inUnmatchedRows;
    case ((r,l)::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        // search augmenting paths
        b = HKDFSphase({r},i,r,l,nv,ne,m,mT,collummarks,level,ass1,ass2,false);
        ur = List.consOnTrue(not b,r,inUnmatchedRows);
      then
        HKDFS(rest,i,nv,ne,m,mT,collummarks,level,ass1,ass2,ur);
    else
      equation
        print("Matching.HKDFSB failed in Phase " +& intString(i) +& "\n");
      then
        fail();

  end match;
end HKDFS;

protected function HKDFSphase
"function helper for HKDFSBphase, traverses all colums and perform a DFSB phase on each
 autor: Frenkel TUD 2012-03"
  input list<Integer> stack;
  input Integer i;
  input Integer r;
  input Integer l;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> collummarks;
  input array<Integer> level;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input Boolean inMatched;
  output Boolean matched;  
algorithm
  matched :=
  match (stack,i,r,l,nv,ne,m,mT,collummarks,level,ass1,ass2,inMatched)
    local
      list<Integer> collums;  
    case ({},_,_,_,_,_,_,_,_,_,_,_,_) then inMatched;
    case (_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // traverse all adiacent rows
        collums = List.select(mT[r], Util.intPositive);
      then
        HKDFStraverseCollums(collums,stack,i,l,nv,ne,m,mT,collummarks,level,ass1,ass2,inMatched);
    else
      equation
        print("Matching.HKDFSphase failed in Phase " +& intString(i) +& "\n");
      then
        fail();
  end match;
end HKDFSphase;

protected function HKDFStraverseCollums
"function helper for HKDFSB, traverses all collums of a row and search a augmenting path
 autor: Frenkel TUD 2012-03"
  input list<Integer> collums;
  input list<Integer> stack;  
  input Integer i;
  input Integer l;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> collummarks;
  input array<Integer> level; 
  input array<Integer> ass1;
  input array<Integer> ass2;
  input Boolean inMatched;
  output Boolean matched;
algorithm
  matched:=
  matchcontinue (collums,stack,i,l,nv,ne,m,mT,collummarks,level,ass1,ass2,inMatched)
    local
      list<Integer> rest,visitedColums; 
      Integer r,c;   
      Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_,_,_) then inMatched;
    case (c::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // collum is not in graph
        false = intEq(level[c],l);
      then
        HKDFStraverseCollums(rest,stack,i,l,nv,ne,m,mT,collummarks,level,ass1,ass2,inMatched);
    case (c::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // collum is in graph
        true = intEq(level[c],l);        
        // collum is unvisited
        true = intLt(collummarks[c],i);
        // collum is unmatched
        true = intLt(ass1[c],0);
        HKDFSreasign(stack,c,ass1,ass2);
      then
        true;        
    case (c::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // collum is in graph
        true = intEq(level[c],l);        
        // collum is unvisited
        true = intLt(collummarks[c],i);
        // collum is matched
        r = ass1[c];
        false = intLt(r,0);
        _ = arrayUpdate(collummarks,c,i);
        b = HKDFSphase(r::stack,i,r,l-1,nv,ne,m,mT,collummarks,level,ass1,ass2,inMatched);
      then
        HKDFStraverseCollums1(b,rest,stack,i,l,nv,ne,m,mT,collummarks,level,ass1,ass2); 
    case (c::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // collum is in graph
        true = intEq(level[c],l);        
        // collum is visited
        false = intLt(collummarks[c],i);
      then
        HKDFStraverseCollums(rest,stack,i,l,nv,ne,m,mT,collummarks,level,ass1,ass2,inMatched);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Matching.HKDFSBtraverseCollums failed\n"});
      then
        fail();
  end matchcontinue;
end HKDFStraverseCollums;

protected function HKDFStraverseCollums1
"function helper for HKDFSBtraverseCollums
 autor: Frenkel TUD 2012-03"
  input Boolean inMatched;
  input list<Integer> rows;
  input list<Integer> stack;  
  input Integer i;
  input Integer l;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> collummarks;
  input array<Integer> level;  
  input array<Integer> ass1;
  input array<Integer> ass2;
  output Boolean matched;
algorithm
  matched:=
  match (inMatched,rows,stack,i,l,nv,ne,m,mT,collummarks,level,ass1,ass2)
    case (true,_,_,_,_,_,_,_,_,_,_,_,_) then inMatched;
    else HKDFStraverseCollums(rows,stack,i,l,nv,ne,m,mT,collummarks,level,ass1,ass2,inMatched);
  end match;
end HKDFStraverseCollums1;

protected function HKDFSreasign
"function helper for HKDFS, reasignment(rematching) allong the augmenting path
 remove all edges from the assignments that are in the path
 add all other edges to the assignment
 autor: Frenkel TUD 2012-03"
  input list<Integer> stack;
  input Integer c;
  input array<Integer> ass1;
  input array<Integer> ass2;
algorithm  
  _ := match (stack,c,ass1,ass2)
    local 
      Integer r,cr;
      list<Integer> rest;
    case ({},_,_,_) then ();
    case (r::rest,_,_,_)
      equation
        cr = ass2[r];
        _ = arrayUpdate(ass1,c,r);
        _ = arrayUpdate(ass2,r,c);
        HKDFSreasign(rest,cr,ass1,ass2);
      then ();
   end match;
end HKDFSreasign;


public function HKDW
"function Combined BFS and DFS algorithm 
          complexity O(sqrt(n)*tau)
 autor: Frenkel TUD 2012-03"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg; 
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns,memsize;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;      
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> rowmarks,level,collummarks;
      list<Integer> unmatched;      
    case (BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);        
        checkSystemForMatching(nvars,neqns,inMatchingOptions);
        vec1 = arrayCreate(neqns,-1);
        vec2 = arrayCreate(nvars,-1);
        rowmarks = arrayCreate(nvars,-1);
        collummarks = arrayCreate(neqns,-1);
        level = arrayCreate(neqns,-1);      
        //unmatched = List.intRange(neqns);
        //unmatched = cheapmatching(1,nvars,neqns,m,mt,vec1,vec2,{});
        unmatched = ks_rand_cheapmatching(nvars,neqns,m,mt,vec1,vec2);
        (vec1,vec2,syst,shared,arg) = HKDW1(0,unmatched,rowmarks,collummarks,level,isyst,ishared,nvars,neqns,vec1,vec2,inMatchingOptions,sssHandler,inArg);
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,ishared,inArg); 
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "- Matching.HKDW failed\n");
      then
        fail();
  end matchcontinue;
end HKDW;

protected function HKDW1
"function: HKDW1, helper for HKDW
  author: Frenkel TUD 2012-03"
  input Integer i;
  input list<Integer> unmatched;
  input array<Integer> rowmarks;
  input array<Integer> collummarks;
  input array<Integer> level;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer nv;
  input Integer ne;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output array<Integer> outAss1;
  output array<Integer> outAss2;  
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outAss1,outAss2,osyst,oshared,outArg):=
  matchcontinue (i,unmatched,rowmarks,collummarks,level,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg)
    local
      BackendDAE.IncidenceMatrix m,mt;
      Integer nv_1,ne_1,i_1;
      BackendDAE.EquationConstraints eq_cons;
      list<Integer> var_lst,unmatched1,changedEqns,meqns_1;
      String eqn_str,var_str;
      BackendDAE.StructurallySingularSystemHandlerArg arg,arg1;
      DAE.ElementSource source;
      Absyn.Info info;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;    
      array<Integer> ass1_1,ass1_2,ass1_3,ass2_1,ass2_2,ass2_3,rowmarks1,collummarks1,level1; 

    case (_,{},_,_,_,_,_,_,_,_,_,_,_,_) 
      then 
        (ass1,ass2,isyst,ishared,inArg);
    case (_,_,_,_,_,syst as BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_,_,_,_)
      equation
        (i_1,unmatched1) = HKDWphase(i,unmatched,nv,ne,m,mt,rowmarks,collummarks,level,ass1,ass2,listLength(unmatched),{});
        meqns_1 = getEqnsforIndexReduction(unmatched1,ne,m,ass2);
        (unmatched1,rowmarks1,collummarks1,level1,nv_1,ne_1,ass1_1,ass2_1,syst,shared,arg) = HK2(meqns_1,unmatched1,{},rowmarks,collummarks,level,syst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg);
        (ass1_2,ass2_2,syst,shared,arg1) = HKDW1(i_1+1,unmatched1,rowmarks1,collummarks1,level1,syst,shared,nv_1,ne_1,ass1,ass2,inMatchingOptions,sssHandler,arg);
      then
        (ass1_2,ass2_2,syst,shared,arg1);
    else
      equation
        eqn_str = BackendDump.dumpMarkedEqns(isyst, unmatched);
        source = BackendEquation.markedEquationSource(isyst, listGet(unmatched,1));
        info = DAEUtil.getElementSourceFileInfo(source);
        Error.addSourceMessage(Error.STRUCT_SINGULAR_SYSTEM, {eqn_str,""}, info);
      then
        fail();
  end matchcontinue;
end HKDW1;

protected function HKDWphase
"function helper for HKDW, traverses all unmatched
 colums and run a BFS and DFS
 autor: Frenkel TUD 2012-03"
  input Integer i;
  input list<Integer> U;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> rowmarks;
  input array<Integer> collummarks;
  input array<Integer> level;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input Integer previousUnmatched;
  input list<Integer> unMatched;
  output Integer outI;
  output list<Integer> outunMatched;
algorithm
  (outI,outunMatched):=
  matchcontinue (i,U,nv,ne,m,mT,rowmarks,collummarks,level,ass1,ass2,previousUnmatched,unMatched)
    local 
      list<Integer> rest,unmatched;
      list<tuple<Integer,Integer>> rows;
      list<Integer> ur;
      Integer c,i_1;
      Boolean b;
    case (_,{},_,_,_,_,_,_,_,_,_,_,_)
      equation
        // no augmenting path is found in phase
        true=intEq(previousUnmatched,listLength(unMatched));
      then
        (i,unMatched);
    case (_,{},_,_,_,_,_,_,_,_,_,_,_)
      equation
       // augmenting path is found in phase, next round
        (i_1,unmatched) = HKphase(i+1,unMatched,nv,ne,m,mT,rowmarks,collummarks,level,ass1,ass2,listLength(unMatched),{});
      then
        (i_1,unmatched);
    case (_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // BFS phase to get the level information
        rows = HKBFS(U,nv,ne,m,mT,rowmarks,i,level,NONE(),ass1,ass2,{});
        // DFS to match 
        ur = HKDFS(rows,i,nv,ne,m,mT,collummarks,level,ass1,ass2,{});
        // second DFS in full graph
        HKDWDFS(ur,i,nv,ne,m,mT,collummarks,ass1,ass2);
        // remove matched collums from U
        unmatched = HKgetUnmatched(U,ass1,{});
        (i_1,unmatched) = HKphase(i,{},nv,ne,m,mT,rowmarks,collummarks,level,ass1,ass2,previousUnmatched,unmatched);
      then
        (i_1,unmatched);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Matching.HKphase failed\n"});
      then
        fail();
  end matchcontinue;
end HKDWphase;

protected function HKDWDFS
"function helper for HKDWDFSB, traverses all colums and perform a DFSB phase on each
 autor: Frenkel TUD 2012-03"
  input list<Integer> unmatchedRows;
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> collummarks;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
algorithm
  _:=
  match (unmatchedRows,i,nv,ne,m,mT,collummarks,ass1,ass2)
    local
       list<Integer> rest;
       Integer r;
    case ({},_,_,_,_,_,_,_,_) then ();
    case (r::rest,_,_,_,_,_,_,_,_)
      equation
        // search augmenting paths
        _ = HKDWDFSphase({r},i,r,nv,ne,m,mT,collummarks,ass1,ass2,false);
        HKDWDFS(rest,i,nv,ne,m,mT,collummarks,ass1,ass2);
      then
        ();
    else
      equation
        print("Matching.HKDWDFSB failed in Phase " +& intString(i) +& "\n");
      then
        fail();

  end match;
end HKDWDFS;

protected function HKDWDFSphase
"function helper for HKDWDFSBphase, traverses all colums and perform a DFSB phase on each
 autor: Frenkel TUD 2012-03"
  input list<Integer> stack;
  input Integer i;
  input Integer r;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> collummarks;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input Boolean inMatched;
  output Boolean matched;  
algorithm
  matched :=
  match (stack,i,r,nv,ne,m,mT,collummarks,ass1,ass2,inMatched)
    local
      list<Integer> collums;  
    case ({},_,_,_,_,_,_,_,_,_,_) then inMatched;
    case (_,_,_,_,_,_,_,_,_,_,_)
      equation
        // traverse all adiacent rows
        collums = List.select(mT[r], Util.intPositive);
      then
        HKDWDFStraverseCollums(collums,stack,i,nv,ne,m,mT,collummarks,ass1,ass2,inMatched);
    else
      equation
        print("Matching.HKDWDFSphase failed in Phase " +& intString(i) +& "\n");
      then
        fail();
  end match;
end HKDWDFSphase;

protected function HKDWDFStraverseCollums
"function helper for HKDWDFSB, traverses all collums of a row and search a augmenting path
 autor: Frenkel TUD 2012-03"
  input list<Integer> collums;
  input list<Integer> stack;  
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> collummarks;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input Boolean inMatched;
  output Boolean matched;
algorithm
  matched:=
  matchcontinue (collums,stack,i,nv,ne,m,mT,collummarks,ass1,ass2,inMatched)
    local
      list<Integer> rest,visitedColums; 
      Integer r,c;   
      Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_) then inMatched;
    case (c::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        // collum is unvisited
        true = intLt(collummarks[c],i);
        // collum is unmatched
        true = intLt(ass1[c],0);
        HKDFSreasign(stack,c,ass1,ass2);
      then
        true;        
    case (c::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        // collum is unvisited
        true = intLt(collummarks[c],i);
        // collum is matched
        r = ass1[c];
        false = intLt(r,0);
        _ = arrayUpdate(collummarks,c,i);
        b = HKDWDFSphase(r::stack,i,r,nv,ne,m,mT,collummarks,ass1,ass2,inMatched);
      then
        HKDWDFStraverseCollums1(b,rest,stack,i,nv,ne,m,mT,collummarks,ass1,ass2); 
    case (c::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        // collum is visited
        false = intLt(collummarks[c],i);
      then
        HKDWDFStraverseCollums(rest,stack,i,nv,ne,m,mT,collummarks,ass1,ass2,inMatched);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Matching.HKDWDFSBtraverseCollums failed\n"});
      then
        fail();
  end matchcontinue;
end HKDWDFStraverseCollums;

protected function HKDWDFStraverseCollums1
"function helper for HKDWDFSBtraverseCollums
 autor: Frenkel TUD 2012-03"
  input Boolean inMatched;
  input list<Integer> rows;
  input list<Integer> stack;  
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> collummarks;
  input array<Integer> ass1;
  input array<Integer> ass2;
  output Boolean matched;
algorithm
  matched:=
  match (inMatched,rows,stack,i,nv,ne,m,mT,collummarks,ass1,ass2)
    case (true,_,_,_,_,_,_,_,_,_,_) then inMatched;
    else HKDWDFStraverseCollums(rows,stack,i,nv,ne,m,mT,collummarks,ass1,ass2,inMatched);
  end match;
end HKDWDFStraverseCollums1;


public function ABMP
"function Combined BFS and DFS algorithm 
          complexity O(sqrt(n)*tau)
 autor: Frenkel TUD 2012-03"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg; 
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;      
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> rowmarks,level,collummarks,rlevel,colptrs;
      list<Integer> unmatched;      
    case (BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);        
        checkSystemForMatching(nvars,neqns,inMatchingOptions);
        vec1 = arrayCreate(neqns,-1);
        vec2 = arrayCreate(nvars,-1);
        rowmarks = arrayCreate(nvars,-1);
        collummarks = arrayCreate(neqns,-1);
        level = arrayCreate(neqns,-1);     
        rlevel = arrayCreate(nvars,nvars);
        colptrs = arrayCreate(neqns,-1);
        //unmatched = List.intRange(neqns);
        //unmatched = cheapmatching(1,nvars,neqns,m,mt,vec1,vec2,{});
        unmatched = ks_rand_cheapmatching(nvars,neqns,m,mt,vec1,vec2);
        (vec1,vec2,syst,shared,arg) = ABMP1(1,unmatched,rowmarks,collummarks,level,rlevel,colptrs,isyst,ishared,nvars,neqns,vec1,vec2,inMatchingOptions,sssHandler,inArg);
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,ishared,inArg);         
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "- Matching.ABMP failed\n");
      then
        fail();
  end matchcontinue;
end ABMP;

protected function ABMP1
"function: ABMP1, helper for HKABMP
  author: Frenkel TUD 2012-03"
  input Integer i;
  input list<Integer> unmatched;
  input array<Integer> rowmarks;
  input array<Integer> collummarks;
  input array<Integer> level;
  input array<Integer> rlevel;
  input array<Integer> colptrs;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer nv;
  input Integer ne;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output array<Integer> outAss1;
  output array<Integer> outAss2;  
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outAss1,outAss2,osyst,oshared,outArg):=
  matchcontinue (i,unmatched,rowmarks,collummarks,level,rlevel,colptrs,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg)
    local
      BackendDAE.IncidenceMatrix m,mt;
      Integer nv_1,ne_1,i_1,lim;
      BackendDAE.EquationConstraints eq_cons;
      list<Integer> var_lst,unmatched1,changedEqns,meqns_1;
      String eqn_str,var_str;
      BackendDAE.StructurallySingularSystemHandlerArg arg,arg1;
      DAE.ElementSource source;
      Absyn.Info info;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;    
      array<Integer> ass1_1,ass1_2,ass1_3,ass2_1,ass2_2,ass2_3,rowmarks1,collummarks1,level1,rlevel1; 

    case (_,{},_,_,_,_,_,_,_,_,_,_,_,_,_,_) 
      then 
        (ass1,ass2,isyst,ishared,inArg);
    case (_,_,_,_,_,_,_,syst as BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_,_,_,_)
      equation
        lim = realInt(realMul(0.1,realSqrt(intReal(arrayLength(ass1)))));
        unmatched1 = ABMPphase(unmatched,i,nv,ne,m,mt,rowmarks,rlevel,colptrs,lim,ass1,ass2);
        (i_1,unmatched1) = HKphase(i+1,unmatched,nv,ne,m,mt,rowmarks,collummarks,level,ass1,ass2,listLength(unmatched),{});
        meqns_1 = getEqnsforIndexReduction(unmatched1,ne,m,ass2);
        (unmatched1,rowmarks1,collummarks1,level1,rlevel1,nv_1,ne_1,ass1_1,ass2_1,syst,shared,arg) = ABMP2(meqns_1,unmatched1,{},rowmarks,collummarks,level,rlevel,syst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg);
        (ass1_2,ass2_2,syst,shared,arg1) = ABMP1(i_1+1,unmatched1,rowmarks1,collummarks1,level1,rlevel1,colptrs,syst,shared,nv_1,ne_1,ass1,ass2,inMatchingOptions,sssHandler,arg);
      then
        (ass1_2,ass2_2,syst,shared,arg1);
    else
      equation
        eqn_str = BackendDump.dumpMarkedEqns(isyst, unmatched);
        source = BackendEquation.markedEquationSource(isyst, listGet(unmatched,1));
        info = DAEUtil.getElementSourceFileInfo(source);
        Error.addSourceMessage(Error.STRUCT_SINGULAR_SYSTEM, {eqn_str,""}, info);
      then
        fail();
  end matchcontinue;
end ABMP1;

protected function ABMP2
"function: ABMP2, helper for ABMP
  author: Frenkel TUD 2012-03"
  input list<Integer> meqns "Marked Equations for Index Reduction";
  input list<Integer> unmatched;
  input list<Integer> changedEqns;
  input array<Integer> rowmarks;
  input array<Integer> collummarks;
  input array<Integer> level;
  input array<Integer> rlevel;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer nv;
  input Integer ne;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output list<Integer> outunmatched;
  output array<Integer> outrowmarks;
  output array<Integer> outcollummarks;
  output array<Integer> outlevel;  
  output array<Integer> outrlevel;
  output Integer nvars;
  output Integer neqns;  
  output array<Integer> outAss1;
  output array<Integer> outAss2;  
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outunmatched,outrowmarks,outcollummarks,outlevel,outrlevel,nvars,neqns,outAss1,outAss2,osyst,oshared,outArg):=
  match (meqns,unmatched,changedEqns,rowmarks,collummarks,level,rlevel,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg)
    local
      BackendDAE.IncidenceMatrix m,mt;
      Integer nv_1,ne_1,i_1;
      BackendDAE.EquationConstraints eq_cons;
      list<Integer> var_lst,meqns_1,unmatched1;
      String eqn_str,var_str;
      BackendDAE.StructurallySingularSystemHandlerArg arg,arg1;
      DAE.ElementSource source;
      Absyn.Info info;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;    
      array<Integer> ass1_1,ass1_2,ass2_1,ass2_2,rowmarks1,collummarks1,level1,rlevel1; 

    case ({},_,_,_,_,_,_,_,_,_,_,_,_,_,_,_) 
      then 
        (unmatched,rowmarks,collummarks,level,rlevel,nv,ne,ass1,ass2,isyst,ishared,inArg);
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,(BackendDAE.INDEX_REDUCTION(),eq_cons),_,_)
      equation
        (unmatched1,_,syst,shared,ass2_1,ass1_1,arg) = sssHandler(meqns,0,isyst,ishared,ass2,ass1,inArg);
        ne_1 = BackendDAEUtil.systemSize(syst);
        nv_1 = BackendVariable.daenumVariables(syst);
        ass1_1 = assignmentsArrayExpand(ass1_1,ne_1,arrayLength(ass1_1),-1);
        ass2_1 = assignmentsArrayExpand(ass2_1,nv_1,arrayLength(ass2_1),-1);
        rowmarks1 = assignmentsArrayExpand(rowmarks,nv_1,arrayLength(rowmarks),-1);
        collummarks1 = assignmentsArrayExpand(collummarks,ne_1,arrayLength(collummarks),-1);
        rlevel1 = arrayCreate(arrayLength(ass2_1),arrayLength(ass2_1));
        level1 = assignmentsArrayExpand(level,ne_1,arrayLength(level),-1);   
      then
        (unmatched1,rowmarks1,collummarks1,level1,rlevel1,nv_1,ne_1,ass1_1,ass2_1,syst,shared,arg);
  end match;
end ABMP2;

protected function ABMPphase
"function helper for ABMP, traverses all unmatched
 colums and run a BFS and DFS to assign level information
 and increase matching.
 autor: Frenkel TUD 2012-03"
  input list<Integer> U;
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> rowmarks;
  input array<Integer> level;
  input array<Integer> colptrs;
  input Integer lim;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  output list<Integer> unMatched;
algorithm
  unMatched:=
  match (U,i,nv,ne,m,mT,rowmarks,level,colptrs,lim,ass1,ass2)
    local 
      list<Integer> rest,ur;
    case ({},_,_,_,_,_,_,_,_,_,_,_) then {};     
    case (_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // BFS to assign levels 
        ur = ABMPBFSphase(U,i,0,lim,listLength(U),nv,ne,m,mT,rowmarks,level,ass1,ass2,{},{});
      then
        ABMPphase1(U,ur,i,nv,ne,m,mT,rowmarks,level,colptrs,lim,ass1,ass2);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Matching.ABMPphase failed\n"});
      then
        fail();
  end match;
end ABMPphase;

protected function ABMPphase1
"function helper for ABMP, traverses all unmatched
 colums and run a BFS and DFS to assign level information
 and increase matching.
 autor: Frenkel TUD 2012-03"
  input list<Integer> U;
  input list<Integer> unmatchedRows;
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> rowmarks;
  input array<Integer> level;
  input array<Integer> colptrs;
  input Integer lim;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  output list<Integer> unMatched;
algorithm
  unMatched:=
  match (U,unmatchedRows,i,nv,ne,m,mT,rowmarks,level,colptrs,lim,ass1,ass2)
    local 
      list<Integer> rest,unmatched;
      Integer L,r;
    case (_,{},_,_,_,_,_,_,_,_,_,_,_) then U;
    case (_,r::_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        L = level[r];
        ABMPDFS(unmatchedRows,0,L,nv,ne,m,mT,level,colptrs,ass1,ass2,{});
        // remove unmatched collums from U
        unmatched = HKgetUnmatched(U,ass1,{});
      then
        ABMPphase2(unmatched,i,L,nv,ne,m,mT,rowmarks,level,colptrs,lim,ass1,ass2);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Matching.ABMPphase1 failed\n"});
      then
        fail();
  end match;
end ABMPphase1;

protected function ABMPphase2
"function helper for ABMP, traverses all unmatched
 colums and run a BFS and DFS to assign level information
 and increase matching.
 autor: Frenkel TUD 2012-03"
  input list<Integer> U;
  input Integer i;
  input Integer L;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> rowmarks;
  input array<Integer> level;
  input array<Integer> colptrs;
  input Integer lim;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  output list<Integer> unMatched;
algorithm
  unMatched:=
  matchcontinue (U,i,L,nv,ne,m,mT,rowmarks,level,colptrs,lim,ass1,ass2)
    case ({},_,_,_,_,_,_,_,_,_,_,_,_) then U;
    case (_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intGt(50*L,listLength(U));
      then
       U;       
    case (_,_,_,_,_,_,_,_,_,_,_,_,_)
      // next round width updated level
      then
       ABMPphase(U,i,nv,ne,m,mT,rowmarks,level,colptrs,lim,ass1,ass2);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Matching.ABMPphase2 failed\n"});
      then
        fail();
  end matchcontinue;
end ABMPphase2;

protected function ABMPBFSphase
"function helper for ABMP, traverses all colums and set level information
 autor: Frenkel TUD 2012-03"
  input list<Integer> queue;
  input Integer i;
  input Integer L;
  input Integer lim;
  input Integer lim1;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> level;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<Integer> nextqueue;
  input list<Integer> unMatched;
  output list<Integer> outunMatched;
algorithm
  outunMatched :=
  match (queue,i,L,lim,lim1,nv,ne,m,mT,rowmarks,level,ass1,ass2,nextqueue,unMatched)
    local
      list<Integer> rest,rows,queue1,unmatched; 
      Integer c,l;  
      Boolean b;   
    case ({},_,_,_,_,_,_,_,_,_,_,_,_,{},_) then unMatched;
    case ({},_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        l = L+2;
        b = intGt(l,lim) or intGt(50*l,lim1);
      then 
        ABMPBFSphase1(b,nextqueue,i,l,lim,lim1,nv,ne,m,mT,rowmarks,level,ass1,ass2,{},unMatched);
    case (c::rest,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // traverse all adiacent rows
        rows = List.select(m[c], Util.intPositive);
        (queue1,unmatched) = ABMPBFStraverseRows(rows,i,L,nv,ne,m,mT,rowmarks,level,ass1,ass2,nextqueue,unMatched);
      then
        ABMPBFSphase(rest,i,L,lim,lim1,nv,ne,m,mT,rowmarks,level,ass1,ass2,queue1,unmatched);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Matching.ABMPBFSphase failed\n"});
      then
        fail();
  end match;
end ABMPBFSphase;

protected function ABMPBFSphase1
"function helper for ABMPBFSphase
 autor: Frenkel TUD 2012-03"
  input Boolean inStop;
  input list<Integer> queue;
  input Integer i;
  input Integer L;
  input Integer lim;
  input Integer lim1;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> level;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<Integer> nextqueue;
  input list<Integer> unMatched;
  output list<Integer> outunMatched; 
algorithm
  outunMatched :=
  match (inStop,queue,i,L,lim,lim1,nv,ne,m,mT,rowmarks,level,ass1,ass2,nextqueue,unMatched)
    case (true,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_) then unMatched;
    case (false,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      then
        ABMPBFSphase(queue,i,L,lim,lim1,nv,ne,m,mT,rowmarks,level,ass1,ass2,nextqueue,unMatched);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Matching.ABMPBFSphase1 failed\n"});
      then
        fail();
  end match;
end ABMPBFSphase1;

protected function ABMPBFStraverseRows
"function helper for ABMPBFS, traverses all rows and assign level informaiton
 autor: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input Integer i;
  input Integer L;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> level;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<Integer> queue;  
  input list<Integer> unMatched;  
  output list<Integer> outEqnqueue; 
  output list<Integer> outUnmatched;
algorithm
  (outEqnqueue,outUnmatched):=
  matchcontinue (rows,i,L,nv,ne,m,mT,rowmarks,level,ass1,ass2,queue,unMatched)
    local
      list<Integer> rest,queue1,unmatched; 
      Integer rc,r;    
      Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_,_,_) then (listReverse(queue),unMatched);
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is unvisited
        false = intEq(rowmarks[r],i);
        // row is unmatched 
        true = intLt(ass2[r],0);
        _ = arrayUpdate(level,r,L);
        _ = arrayUpdate(rowmarks,r,i);  
        (queue1,unmatched) = ABMPBFStraverseRows(rest,i,L,nv,ne,m,mT,rowmarks,level,ass1,ass2,queue,r::unMatched);
      then
        (queue1,unmatched);
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is unvisited
        false = intEq(rowmarks[r],i);        
        // row is matched
        rc = ass2[r];
        false = intLt(rc,0);
        _ = arrayUpdate(rowmarks,r,i);
        (queue1,unmatched) = ABMPBFStraverseRows(rest,i,L,nv,ne,m,mT,rowmarks,level,ass1,ass2,rc::queue,unMatched);
      then
        (queue1,unmatched);
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is visited
        true = intEq(rowmarks[r],i);        
        (queue1,unmatched) = ABMPBFStraverseRows(rest,i,L,nv,ne,m,mT,rowmarks,level,ass1,ass2,queue,unMatched);
      then
        (queue1,unmatched);        
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Matching.ABMPBFStraverseRows failed\n"});
      then
        fail();
  end matchcontinue;
end ABMPBFStraverseRows;

protected function ABMPDFS
"function helper for ABMPDFS, traverses all rows and perform a DFSB phase on each
 autor: Frenkel TUD 2012-03"
  input list<Integer> unmatchedRows;
  input Integer i;
  input Integer L;  
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> level;
  input array<Integer> colptrs;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input list<Integer> unMatched;  
algorithm
  _:=
  matchcontinue (unmatchedRows,i,L,nv,ne,m,mT,level,colptrs,ass1,ass2,unMatched)
    local
       list<Integer> rest,unmatched;
       Integer r,i_1;
       Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_,_) then ();
    case (_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        false = intLt(i,ne);
      then ();       
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // search augmenting paths
        _ = arrayUpdate(colptrs,r,0);
        (i_1,b) = ABMPDFSphase({r},i,r,nv,ne,m,mT,level,colptrs,ass1,ass2);
        unmatched = List.consOnTrue(not b, r, unMatched);
        ABMPDFS1(b,r,rest,unmatched,i_1,L,nv,ne,m,mT,level,colptrs,ass1,ass2);
      then
        ();
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Matching.ABMPBFS failed\n"});
      then
        fail();
  end matchcontinue;
end ABMPDFS;

protected function ABMPDFS1
"function helper for ABMPDFS, traverses all rows and perform a DFSB phase on each
 autor: Frenkel TUD 2012-03"
  input Boolean inMatched;
  input Integer r;
  input list<Integer> unmatchedRows;
  input list<Integer> unMatched;  
  input Integer i;
  input Integer L;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> level;
  input array<Integer> colptrs;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
algorithm
  _:=
  matchcontinue (inMatched,r,unmatchedRows,unMatched,i,L,nv,ne,m,mT,level,colptrs,ass1,ass2)
    local
       list<Integer> unmatched;
       Integer r1,r2,i_1,l;
    case (_,_,{},_,_,_,_,_,_,_,_,_,_,_) then ();
    case (true,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intGt(50*L,listLength(unmatchedRows)+listLength(unMatched));
      then ();  
    case (true,_,_,{},_,_,_,_,_,_,_,_,_,_)
      equation
        false = intGt(50*L,listLength(unmatchedRows)+listLength(unMatched));
        ABMPDFS(unmatchedRows,i,L,nv,ne,m,mT,level,colptrs,ass1,ass2,{});      
      then ();
    case (true,_,r1::_,r2::{},_,_,_,_,_,_,_,_,_,_)
      equation
        false = intGt(50*L,listLength(unmatchedRows)+listLength(unMatched));
        false = intEq(L,level[r1]);
        l = level[r2];
        ABMPDFS(r2::unmatchedRows,i,l,nv,ne,m,mT,level,colptrs,ass1,ass2,{});      
      then ();          
    case (true,_,r1::_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        false = intGt(50*L,listLength(unmatchedRows)+listLength(unMatched));
        false = intEq(L,level[r1]);
        (r2::unmatched) = listReverse(unMatched);
        l = level[r2];
        unmatched = listAppend(unmatched,r2::unmatchedRows);
        ABMPDFS(unmatchedRows,i,l,nv,ne,m,mT,level,colptrs,ass1,ass2,{});      
      then (); 
    case (_,_,r1::_,{},_,_,_,_,_,_,_,_,_,_)
      equation
        false = intEq(L,level[r1]);
        l = level[r];
        ABMPDFS(unmatchedRows,i,l,nv,ne,m,mT,level,colptrs,ass1,ass2,{});      
      then ();                        
    case (_,_,r1::_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        false = intEq(L,level[r1]);
        (r2::unmatched) = listReverse(unMatched);
        l = level[r2];
        unmatched = listAppend(r2::unmatched,unmatchedRows);
        ABMPDFS(unmatched,i,l,nv,ne,m,mT,level,colptrs,ass1,ass2,{});      
      then (); 
    case (_,_,r1::_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intEq(L,level[r1]);
        ABMPDFS(unmatchedRows,i,L,nv,ne,m,mT,level,colptrs,ass1,ass2,unMatched);      
      then ();   
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Matching.ABMPBFS1 failed\n"});
      then
        fail();
  end matchcontinue;
end ABMPDFS1;

protected function ABMPDFSphase
"function helper for ABMPDFSBphase, traverses all colums and perform a DFSB phase on each
 autor: Frenkel TUD 2012-03"
  input list<Integer> stack;
  input Integer i;
  input Integer r;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> level;
  input array<Integer> colptrs;
  input array<Integer> ass1;
  input array<Integer> ass2;
  output Integer outI;  
  output Boolean matched;
algorithm
  (outI,matched) :=
  match (stack,i,r,nv,ne,m,mT,level,colptrs,ass1,ass2)
    local
      list<Integer> collums;
      Integer desL,i_1;
      Boolean b;  
    case ({},_,_,_,_,_,_,_,_,_,_) then (i,false);
    case (_,_,_,_,_,_,_,_,_,_,_)
      equation
        // traverse all adiacent rows
        collums = List.select(mT[r], Util.intPositive);
        collums = List.stripN(collums,colptrs[r]);
        desL = level[r]-2;
        (i_1,b) = ABMPDFStraverseCollums(collums,1,stack,r,i,desL,nv,ne,m,mT,level,colptrs,ass1,ass2);
      then
        (i_1,b);
    else
      equation
        print("Matching.ABMPDFSphase failed in Phase " +& intString(i) +& "\n");
      then
        fail();
  end match;
end ABMPDFSphase;

protected function ABMPDFStraverseCollums
"function helper for ABMPDFSB, traverses all collums of a row and search a augmenting path
 autor: Frenkel TUD 2012-03"
  input list<Integer> collums;
  input Integer counter;
  input list<Integer> stack;
  input Integer r;
  input Integer i;  
  input Integer desL;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> level;
  input array<Integer> colptrs;
  input array<Integer> ass1;
  input array<Integer> ass2;
  output Integer outI;
  output Boolean matched;
algorithm
  (outI,matched):=
  matchcontinue (collums,counter,stack,r,i,desL,nv,ne,m,mT,level,colptrs,ass1,ass2)
    local
      list<Integer> rest; 
      Integer rc,c,i_1;   
      Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        _ = arrayUpdate(level,r,level[r]+2);
        _ = arrayUpdate(colptrs,r,0);
      then 
        (i+1,false);
    case (c::rest,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // collum is unmatched
        true = intLt(ass1[c],0);
        _ = arrayUpdate(colptrs,r,counter);
        HKDFSreasign(stack,c,ass1,ass2);
      then
        (i,true);        
    case (c::rest,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // collum is unvisited
        true = intEq(level[c],desL);
        // collum is matched
        rc = ass1[c];
        true = intGt(rc,0);
        _ = arrayUpdate(colptrs,r,counter);
        (i_1,b) = ABMPDFSphase(rc::stack,i,rc,nv,ne,m,mT,level,colptrs,ass1,ass2);
        (i_1,b) = ABMPDFStraverseCollums1(b,counter+1,rest,stack,r,i_1,desL,nv,ne,m,mT,level,colptrs,ass1,ass2); 
      then
        (i_1,b);
    case (_::rest,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        (i_1,b) = ABMPDFStraverseCollums(rest,counter+1,stack,r,i,desL,nv,ne,m,mT,level,colptrs,ass1,ass2);
      then
        (i_1,b);        
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Matching.ABMPDFSBtraverseCollums failed\n"});
      then
        fail();
  end matchcontinue;
end ABMPDFStraverseCollums;

protected function ABMPDFStraverseCollums1
"function helper for ABMPDFSBtraverseCollums
 autor: Frenkel TUD 2012-03"
  input Boolean inMatched;
  input Integer counter;
  input list<Integer> rows;
  input list<Integer> stack;  
  input Integer r;
  input Integer i;  
  input Integer desL;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> level;
  input array<Integer> colptrs;
  input array<Integer> ass1;
  input array<Integer> ass2;
  output Integer outI;
  output Boolean matched;
algorithm
 (outI,matched):=
  match (inMatched,counter,rows,stack,r,i,desL,nv,ne,m,mT,level,colptrs,ass1,ass2)
    local
      Integer i_1;   
      Boolean b;     
    case (true,_,_,_,_,i_1,_,_,_,_,_,_,_,_,_)
       then (i_1,true);
    else
      equation
        (i_1,b) = ABMPDFStraverseCollums(rows,counter,stack,r,i,desL,nv,ne,m,mT,level,colptrs,ass1,ass2);
      then
        (i_1,b);   
  end match;
end ABMPDFStraverseCollums1;


public function PR_FIFO_FAIR
"function matching algorithm using push relabel  
          complexity O(n*tau)
 autor: Frenkel TUD 2012-04"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg; 
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns,memsize;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;      
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> l_label,r_label;
      list<Integer> unmatched;      

    case (BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);   
        checkSystemForMatching(nvars,neqns,inMatchingOptions);     
        vec1 = arrayCreate(neqns,-1);
        vec2 = arrayCreate(nvars,-1);
        l_label = arrayCreate(neqns,-1);
        r_label = arrayCreate(nvars,-1);       
        //unmatched = List.intRange(neqns);
        //unmatched = cheapmatching(1,nvars,neqns,m,mt,vec1,vec2,{});
        unmatched = ks_rand_cheapmatching(nvars,neqns,m,mt,vec1,vec2);
        (vec1,vec2,syst,shared,arg) = PR_FIFO_FAIR1(unmatched,l_label,r_label,isyst,ishared,nvars,neqns,vec1,vec2,inMatchingOptions,sssHandler,inArg);
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,ishared,inArg);          
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "- Matching.PR_FIFO_FAIR failed\n");
      then
        fail();
  end matchcontinue;
end PR_FIFO_FAIR;

protected function PR_FIFO_FAIR1
"function: PR_FIFO_FAIR1, helper for PR_FIFO_FAIR
  author: Frenkel TUD 2012-03"
  input list<Integer> unmatched;
  input array<Integer> l_label;
  input array<Integer> r_label;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer nv;
  input Integer ne;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output array<Integer> outAss1;
  output array<Integer> outAss2;  
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outAss1,outAss2,osyst,oshared,outArg):=
  matchcontinue (unmatched,l_label,r_label,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg)
    local
      BackendDAE.IncidenceMatrix m,mt;
      Integer nv_1,ne_1,memsize,i_1;
      BackendDAE.EquationConstraints eq_cons;
      list<Integer> var_lst,unmatched1,changedEqns,meqns_1;
      String eqn_str,var_str;
      BackendDAE.StructurallySingularSystemHandlerArg arg,arg1;
      DAE.ElementSource source;
      Absyn.Info info;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;    
      array<Integer> ass1_1,ass1_2,ass1_3,ass2_1,ass2_2,ass2_3,l_label1,r_label1; 

    case ({},_,_,_,_,_,_,_,_,_,_,_) 
      then 
        (ass1,ass2,isyst,ishared,inArg);
    case (_,_,_,syst as BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_,_,_,_)
      equation
        PR_Global_Relabel(l_label,r_label,nv,ne,m,mt,ass1,ass2);
        PR_FIFO_FAIRphase(0,unmatched,nv+ne,-1,nv,ne,m,mt,l_label,r_label,ass1,ass2,{});
        unmatched1 = getUnassigned(ne, ass1, {});
        meqns_1 = getEqnsforIndexReduction(unmatched1,ne,m,ass2);
        (unmatched1,l_label1,r_label1,nv_1,ne_1,ass1_1,ass2_1,syst,shared,arg) = PR_FIFO_FAIR2(meqns_1,unmatched1,{},l_label,r_label,syst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg);
        (ass1_2,ass2_2,syst,shared,arg1) = PR_FIFO_FAIR1(unmatched1,l_label1,r_label1,syst,shared,nv_1,ne_1,ass1,ass2,inMatchingOptions,sssHandler,arg);
      then
        (ass1_2,ass2_2,syst,shared,arg1);
    else
      equation
        eqn_str = BackendDump.dumpMarkedEqns(isyst, unmatched);
        source = BackendEquation.markedEquationSource(isyst, listGet(unmatched,1));
        info = DAEUtil.getElementSourceFileInfo(source);
        Error.addSourceMessage(Error.STRUCT_SINGULAR_SYSTEM, {eqn_str,""}, info);
      then
        fail();
  end matchcontinue;
end PR_FIFO_FAIR1;

protected function PR_FIFO_FAIR2
"function: PR_FIFO_FAIR2, helper for PR_FIFO_FAIR
  author: Frenkel TUD 2012-03"
  input list<Integer> meqns "Marked Equations for Index Reduction";
  input list<Integer> unmatched;
  input list<Integer> changedEqns;
  input array<Integer> l_label;
  input array<Integer> r_label;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer nv;
  input Integer ne;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output list<Integer> outunmatched;
  output array<Integer> outl_label;
  output array<Integer> outr_label;  
  output Integer nvars;
  output Integer neqns;  
  output array<Integer> outAss1;
  output array<Integer> outAss2;  
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outunmatched,outl_label,outr_label,nvars,neqns,outAss1,outAss2,osyst,oshared,outArg):=
  match (meqns,unmatched,changedEqns,l_label,r_label,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg)
    local
      BackendDAE.IncidenceMatrix m,mt;
      Integer nv_1,ne_1,i_1;
      BackendDAE.EquationConstraints eq_cons;
      list<Integer> var_lst,meqns_1,unmatched1,changedEqns1;
      String eqn_str,var_str;
      BackendDAE.StructurallySingularSystemHandlerArg arg,arg1;
      DAE.ElementSource source;
      Absyn.Info info;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;    
      array<Integer> ass1_1,ass1_2,ass2_1,ass2_2,l_label1,r_label1; 

    case ({},_,_,_,_,_,_,_,_,_,_,_,_,_) 
      then 
        (unmatched,l_label,r_label,nv,ne,ass1,ass2,isyst,ishared,inArg);
    case (_,_,_,_,_,_,_,_,_,_,_,(BackendDAE.INDEX_REDUCTION(),eq_cons),_,_)
      equation
        (unmatched1,_,syst,shared,ass2_1,ass1_1,arg) = sssHandler(meqns,0,isyst,ishared,ass2,ass1,inArg);
        ne_1 = BackendDAEUtil.systemSize(syst);
        nv_1 = BackendVariable.daenumVariables(syst);
        ass1_1 = assignmentsArrayExpand(ass1_1,ne_1,arrayLength(ass1_1),-1);
        ass2_1 = assignmentsArrayExpand(ass2_1,nv_1,arrayLength(ass2_1),-1);
        l_label1 = assignmentsArrayExpand(l_label,ne_1,arrayLength(l_label),-1);
        r_label1 = assignmentsArrayExpand(r_label,nv_1,arrayLength(r_label),-1); 
      then
        (unmatched1,l_label1,r_label1,nv_1,ne_1,ass1_1,ass2_1,syst,shared,arg);
  end match;
end PR_FIFO_FAIR2;

protected function PR_Global_Relabel
"function PR_Global_Relabel, helper for PR_FIFO_FAIR, 
          update the labels of eatch vertex
 autor: Frenkel TUD 2012-04"
  input array<Integer> l_label;
  input array<Integer> r_label;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ass1;
  input array<Integer> ass2;
protected
  list<Integer> queue; 
  Integer max; 
algorithm
  max := nv+ne;
  PR_Global_Relabel_init_l_label(1,ne,max,l_label);
  queue := PR_Global_Relabel_init_r_label(1,nv,max,r_label,ass2,{});
  PR_Global_Relabel1(queue,l_label,r_label,max,nv,ne,m,mT,ass1,ass2,{});
end PR_Global_Relabel;

protected function PR_Global_Relabel_init_l_label
"function PR_Global_Relabel_init_l_label, helper for PR_Global_Relabel
 autor: Frenkel TUD 2012-04"
  input Integer i;
  input Integer ne;
  input Integer max;
  input array<Integer> l_label;
algorithm
  _ := matchcontinue(i,ne,max,l_label)
    case(_,_,_,_)
      equation
        true = intGt(i,ne);
      then
        ();
    else
      equation
        _ = arrayUpdate(l_label,i,max);
        PR_Global_Relabel_init_l_label(i+1,ne,max,l_label);
      then
        ();
  end matchcontinue;          
end PR_Global_Relabel_init_l_label;

protected function PR_Global_Relabel_init_r_label
"function PR_Global_Relabel_init_r_label, helper for PR_Global_Relabel
 autor: Frenkel TUD 2012-04"
  input Integer i;
  input Integer nv;
  input Integer max;
  input array<Integer> r_label;
  input array<Integer> ass2;
  input list<Integer> inQueue;
  output list<Integer> outQueue;
algorithm
  outQueue := matchcontinue(i,nv,max,r_label,ass2,inQueue)
    case(_,_,_,_,_,_)
      equation
        true = intGt(i,nv);
      then
        listReverse(inQueue);
    case(_,_,_,_,_,_)
      equation
        false = intGt(i,nv);
        false = intGt(ass2[i],0);
        _ = arrayUpdate(r_label,i,0);
      then
        PR_Global_Relabel_init_r_label(i+1,nv,max,r_label,ass2,i::inQueue);     
    else
      equation
        _ = arrayUpdate(r_label,i,max);
      then
        PR_Global_Relabel_init_r_label(i+1,nv,max,r_label,ass2,inQueue);
  end matchcontinue;          
end PR_Global_Relabel_init_r_label;

protected function PR_Global_Relabel1
"function PR_Global_Relabel, helper for PR_FIFO_FAIR, 
          update the labels of eatch vertex
 autor: Frenkel TUD 2012-04"
  input list<Integer> queue;
  input array<Integer> l_label;
  input array<Integer> r_label;
  input Integer max;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<Integer> nextqueue; 
algorithm
  _ := matchcontinue(queue,l_label,r_label,max,nv,ne,m,mT,ass1,ass2,nextqueue)
    local
      list<Integer> rest,collums,queue; 
      Integer r;      
    case({},_,_,_,_,_,_,_,_,_,{}) then ();
    case({},_,_,_,_,_,_,_,_,_,_)
      equation
        PR_Global_Relabel1(listReverse(nextqueue),l_label,r_label,max,nv,ne,m,mT,ass1,ass2,{});
      then
        ();
    case(r::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        collums = List.select(mT[r], Util.intPositive);
        queue = PR_Global_Relabel_traverseCollums(collums,max,r,l_label,r_label,nv,ne,m,mT,ass1,ass2,nextqueue);
        PR_Global_Relabel1(rest,l_label,r_label,max,nv,ne,m,mT,ass1,ass2,queue);
      then
        ();
  end matchcontinue;
end PR_Global_Relabel1;

protected function PR_Global_Relabel_traverseCollums
"function helper for PR_Global_Relabel1, traverses all collums of a row and asing label indexes
 autor: Frenkel TUD 2012-04"
  input list<Integer> collums;
  input Integer max;
  input Integer r;
  input array<Integer> l_label;
  input array<Integer> r_label;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<Integer> nextqueue; 
  output list<Integer> outQueue;
algorithm
  outQueue:=
  matchcontinue (collums,max,r,l_label,r_label,nv,ne,m,mT,ass1,ass2,nextqueue)
    local
      list<Integer> rest; 
      Integer rc,c;   
    case ({},_,_,_,_,_,_,_,_,_,_,_) then nextqueue;
    case (c::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intEq(l_label[c],max);
        _ = arrayUpdate(l_label,c,r_label[r]+1);
        rc = ass1[c];
        true = intGt(rc,-1);
        true = intEq(r_label[rc] ,max);
        _ = arrayUpdate(r_label,rc,l_label[c]+1);
      then
        PR_Global_Relabel_traverseCollums(rest,max,r,l_label,r_label,nv,ne,m,mT,ass1,ass2,rc::nextqueue);      
    case (c::rest,_,_,_,_,_,_,_,_,_,_,_)
      then
        PR_Global_Relabel_traverseCollums(rest,max,r,l_label,r_label,nv,ne,m,mT,ass1,ass2,nextqueue);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Matching.PR_Global_Relabel_traverseCollums failed\n"});
      then
        fail();
  end matchcontinue;
end PR_Global_Relabel_traverseCollums;


protected function PR_FIFO_FAIRphase
"function PR_FIFO_FAIRphase, match rows and collums with push relabel tecnic
 autor: Frenkel TUD 2012-04"
  input Integer relabels;
  input list<Integer> U;
  input Integer max;
  input Integer min_vertex;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> l_label;
  input array<Integer> r_label;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<Integer> nextqueue; 
algorithm
  _ := matchcontinue(relabels,U,max,min_vertex,nv,ne,m,mT,l_label,r_label,ass1,ass2,nextqueue)
    local
      list<Integer> rest,queue;
      Integer c,min_label,rlcount,minvertex;
    case(_,{},_,_,_,_,_,_,_,_,_,_,{}) then ();
    case(_,{},_,_,_,_,_,_,_,_,_,_,_)
      equation
        PR_FIFO_FAIRphase(relabels,nextqueue,max,min_vertex,nv,ne,m,mT,l_label,r_label,ass1,ass2,{});
      then ();
    case(_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intEq(relabels,max);
        PR_Global_Relabel(l_label,r_label,nv,ne,m,mT,ass1,ass2);
        PR_FIFO_FAIRphase(0,U,max,min_vertex,nv,ne,m,mT,l_label,r_label,ass1,ass2,nextqueue);
      then ();    
    case(_,c::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        (rlcount,min_label,minvertex) = PR_FIFO_FAIRphase1(intLt(l_label[c],max),relabels+1,c,min_vertex,max,max,nv,ne,m,mT,l_label,r_label,ass1,ass2);
        queue = PR_FIFO_FAIRrelabel(c,minvertex,min_label,max,nv,ne,m,mT,l_label,r_label,ass1,ass2,nextqueue);
        PR_FIFO_FAIRphase(rlcount,rest,max,minvertex,nv,ne,m,mT,l_label,r_label,ass1,ass2,queue);
      then ();   
  end matchcontinue;
end PR_FIFO_FAIRphase; 

protected function PR_FIFO_FAIRphase1
"function helper for PR_FIFO_FAIRphase
 autor: Frenkel TUD 2012-04" 
  input Boolean b;
  input Integer relabels;
  input Integer max_vertex;
  input Integer min_vertec;
  input Integer min_label;
  input Integer max;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> l_label;
  input array<Integer> r_label;
  input array<Integer> ass1;
  input array<Integer> ass2;   
  output Integer outRelabels;
  output Integer outMinLabels;
  output Integer outMinVertex;
algorithm
  (outRelabels,outMinLabels,outMinVertex) := 
  match(b,relabels,max_vertex,min_vertec,min_label,max,nv,ne,m,mT,l_label,r_label,ass1,ass2)
    local
      Integer rel,minlab,minvert,tmp;
    case(true,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        tmp = intMod(l_label[max_vertex],4);
        (rel,minlab,minvert) = PR_FIFO_FAIRphase2(intEq(tmp,1),relabels,max_vertex,min_vertec,min_label,max,nv,ne,m,mT,l_label,r_label,ass1,ass2);
      then
        (rel,minlab,minvert);
    else
      then
       (relabels,min_label,min_vertec);
  end match;
end PR_FIFO_FAIRphase1;

protected function PR_FIFO_FAIRphase2
"function helper for PR_FIFO_FAIRphase
 autor: Frenkel TUD 2012-04" 
  input Boolean b;
  input Integer relabels;
  input Integer max_vertex;
  input Integer min_vertec;
  input Integer min_label;
  input Integer max;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> l_label;
  input array<Integer> r_label;
  input array<Integer> ass1;
  input array<Integer> ass2;   
  output Integer outRelabels;
  output Integer outMinLabels;
  output Integer outMinVertex;
algorithm
  (outRelabels,outMinLabels,outMinVertex) := 
  match(b,relabels,max_vertex,min_vertec,min_label,max,nv,ne,m,mT,l_label,r_label,ass1,ass2)
    local
      list<Integer> rows;
      Integer rel,minlab,minvert,tmp;
    case(true,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        rows = List.select(m[max_vertex], Util.intPositive);
        (rel,minlab,minvert) = PR_FIFO_FAIRphase_traverseRows(rows,relabels,max_vertex,min_vertec,min_label,max,nv,ne,m,mT,l_label,r_label,ass1,ass2);
      then
        (rel,minlab,minvert);
    else
      equation
        rows = List.select(m[max_vertex], Util.intPositive);
        rows = listReverse(rows);
        (rel,minlab,minvert) = PR_FIFO_FAIRphase_traverseRows(rows,relabels,max_vertex,min_vertec,min_label,max,nv,ne,m,mT,l_label,r_label,ass1,ass2);
      then
       (rel,minlab,minvert);
  end match;
end PR_FIFO_FAIRphase2;

protected function PR_FIFO_FAIRphase_traverseRows
"function helper for PR_FIFO_FAIRphase2
 autor: Frenkel TUD 2012-04"
  input list<Integer> rows;
  input Integer relabels;
  input Integer max_vertex;
  input Integer min_vertex;
  input Integer min_label;
  input Integer max;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> l_label;
  input array<Integer> r_label;
  input array<Integer> ass1;
  input array<Integer> ass2;   
  output Integer outRelabels;
  output Integer outMinLabels;
  output Integer outMinVertex;
algorithm
  (outRelabels,outMinLabels,outMinVertex) := 
  matchcontinue(rows,relabels,max_vertex,min_vertex,min_label,max,nv,ne,m,mT,l_label,r_label,ass1,ass2)
    local
      list<Integer> rest; 
      Integer rc,r,minlabel,minvertex,rel;   
    case ({},_,_,_,_,_,_,_,_,_,_,_,_,_) then (relabels,min_label,min_vertex);
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intLt(r_label[r],min_label);
        minlabel = r_label[r];
        minvertex = r;
        true = intEq(r_label[minvertex],l_label[max_vertex]-1);
      then
        (relabels-1,minlabel,minvertex);  
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intLt(r_label[r],min_label);
        minlabel = r_label[r];
        minvertex = r;
        false = intEq(r_label[minvertex],l_label[max_vertex]-1);
        (rel,minlabel,minvertex) = PR_FIFO_FAIRphase_traverseRows(rest,relabels,max_vertex,minvertex,minlabel,max,nv,ne,m,mT,l_label,r_label,ass1,ass2);
      then
        (rel,minlabel,minvertex);          
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        (rel,minlabel,minvertex) = PR_FIFO_FAIRphase_traverseRows(rest,relabels,max_vertex,min_vertex,min_label,max,nv,ne,m,mT,l_label,r_label,ass1,ass2);
      then
        (rel,minlabel,minvertex);          
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Matching.PR_FIFO_FAIRphase_traverseRows failed\n"});
      then
        fail();
  end matchcontinue;
end PR_FIFO_FAIRphase_traverseRows;

protected function PR_FIFO_FAIRrelabel
"function helper for PR_FIFO_FAIRphase
 autor: Frenkel TUD 2012-04"  
  input Integer max_vertex;
  input Integer min_vertex;
  input Integer min_label;
  input Integer max;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> l_label;
  input array<Integer> r_label;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<Integer> inQueue;
  output list<Integer> outQueue;
algorithm
  outQueue := matchcontinue (max_vertex,min_vertex,min_label,max,nv,ne,m,mT,l_label,r_label,ass1,ass2,inQueue)
    local
      Integer next_vertex;
    case(_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intLt(min_label,max);
        true = intLt(ass2[min_vertex],0);
        _ = arrayUpdate(ass2,min_vertex,max_vertex);
        _ = arrayUpdate(ass1,max_vertex,min_vertex);
        _ = arrayUpdate(r_label,min_vertex,min_label+2);
      then 
        inQueue;
    case(_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intLt(min_label,max);
        false = intLt(ass2[min_vertex],0);
        next_vertex = ass2[min_vertex];
        _=arrayUpdate(ass2,min_vertex,max_vertex);
        _=arrayUpdate(ass1,max_vertex,min_vertex);
        _=arrayUpdate(ass1,next_vertex,-1);
        _=arrayUpdate(l_label,max_vertex,min_label+1);
        _=arrayUpdate(r_label,min_vertex,min_label+2);
      then 
        next_vertex::inQueue;
    else 
      then
        inQueue;        
  end matchcontinue;
end PR_FIFO_FAIRrelabel;


/******************************************
  cheap matching implementations
 *****************************************/

protected function matchSingleVars
"function matchSingleVars, match all vars with one equation
 autor: Frenkel TUD 2012-04"
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
algorithm
  _:=
  matchcontinue (i,nv,ne,m,mT,ass1,ass2)
    local 
      list<Integer> rows;
    case (_,_,_,_,_,_,_)
      equation
        true=intGt(i,ne);
      then
        ();
    case (_,_,_,_,_,_,_)
      equation
        // search cheap matching
        rows = List.select(m[i], Util.intPositive);
        matchSingleVars1(rows,i,ass1,ass2);
        matchSingleVars(i+1,nv,ne,m,mT,ass1,ass2);
      then
        ();
    case (_,_,_,_,_,_,_)
      equation
        matchSingleVars(i+1,nv,ne,m,mT,ass1,ass2);
      then
        ();
    else
      equation
        print("Matching.matchSingleVars failed in Equation " +& intString(i) +& "\n");
      then
        fail();
  end matchcontinue;
end matchSingleVars;

protected function matchSingleVars1
"function helper for matchSingleVars
 autor: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input Integer c;
  input array<Integer> ass1;
  input array<Integer> ass2;
algorithm
  _:=
  match (rows,c,ass1,ass2)
    local
      list<Integer> rest; 
      Integer r;   
    case (r::{},_,_,_)
      equation
        // row is unmatched -> return
        true = intLt(ass2[r],0); 
        _ = arrayUpdate(ass1,c,r);
        _ = arrayUpdate(ass2,r,c);        
      then
        ();         
  end match;
end matchSingleVars1;

protected function cheapmatching
"function cheapmatching, traverses all colums and look for a cheap matching, a unmatch row
 autor: Frenkel TUD 2012-03"
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input list<Integer> inUnMatched;
  output list<Integer> outUnMatched;
algorithm
  outUnMatched:=
  matchcontinue (i,nv,ne,m,mT,ass1,ass2,inUnMatched)
    local 
      list<Integer> rows;
    case (_,_,_,_,_,_,_,_)
      equation
        true=intGt(i,ne);
      then
        inUnMatched;
    case (_,_,_,_,_,_,_,_)
      equation
        // search cheap matching
        rows = List.select(m[i], Util.intPositive);
        cheapmatching1(rows,i,ass1,ass2);
      then
        cheapmatching(i+1,nv,ne,m,mT,ass1,ass2,inUnMatched);
    case (_,_,_,_,_,_,_,_)
        // unmatched add to list
      then
        cheapmatching(i+1,nv,ne,m,mT,ass1,ass2,i::inUnMatched);
    else
      equation
        print("Matching.cheapmatching failed in Equation " +& intString(i) +& "\n");
      then
        fail();
  end matchcontinue;
end cheapmatching;

protected function cheapmatching1
"function helper for cheapmatching, traverses all rows, fails if no unmatched is found
 autor: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input Integer c;
  input array<Integer> ass1;
  input array<Integer> ass2;
algorithm
  _:=
  matchcontinue (rows,c,ass1,ass2)
    local
      list<Integer> rest; 
      Integer r;   
    case (r::rest,_,_,_)
      equation
        // row is unmatched -> return
        true = intLt(ass2[r],0); 
        _ = arrayUpdate(ass1,c,r);
        _ = arrayUpdate(ass2,r,c);        
      then
        ();         
    case (_::rest,_,_,_) 
      equation
        cheapmatching1(rest,c,ass1,ass2);
      then
        ();
  end matchcontinue;
end cheapmatching1;

protected function ks_rand_cheapmatching
"function ks_rand_cheapmatching, Random Karp-Sipser
 autor: Frenkel TUD 2012-04"
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  output list<Integer> outUnMatched;
protected
  list<Integer> onecolums, onerows;
  array<Integer> col_degrees, row_degrees,randarr;
algorithm
  col_degrees := arrayCreate(ne,0);
  row_degrees := arrayCreate(ne,0);
  onerows := getOneRows(ne,mT,row_degrees,{});
  onecolums := getOneRows(nv,m,col_degrees,{});
  randarr := listArray(List.intRange(ne));
  setrandArray(ne,randarr);
  ks_rand_cheapmatching1(1,ne,onecolums,onerows,col_degrees,row_degrees,randarr,m,mT,ass1,ass2);
  outUnMatched := getUnassigned(ne,ass1,{});
end ks_rand_cheapmatching;

protected function ks_rand_cheapmatching1
"function ks_rand_cheapmatching1, helper for ks_rand_cheapmatching.
 autor: Frenkel TUD 2012-04"
  input Integer i;
  input Integer ne;
  input list<Integer> onecolums;
  input list<Integer> onerows;
  input array<Integer> col_degrees;
  input array<Integer> row_degrees;
  input array<Integer> randarr;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ass1;
  input array<Integer> ass2;
algorithm
  _  := matchcontinue (i,ne,onecolums,onerows,col_degrees,row_degrees,randarr,m,mT,ass1,ass2)
    local
      list<Integer> onecolums1,onerows1;
      Integer c,i_1;
      Boolean b;
      case (_,_,_,_,_,_,_,_,_,_,_)
        equation
          false = intLe(i,ne);
        then 
          ();
      case (_,_,_,_,_,_,_,_,_,_,_)
        equation
          ks_rand_match(onerows,onecolums,row_degrees,col_degrees,mT,m,ass2,ass1);
          c = randarr[i];
          b = intLt(ass1[c],0) and intGt(col_degrees[c],0);
          (onecolums1,onerows1) = ks_rand_cheapmatching2(b,c,col_degrees,row_degrees,randarr,m,mT,ass1,ass2);           
          ks_rand_cheapmatching1(i+1,ne,onecolums1,onerows1,col_degrees,row_degrees,randarr,m,mT,ass1,ass2);
        then
          ();
    end matchcontinue;
end ks_rand_cheapmatching1;

protected function ks_rand_cheapmatching2
"function ks_rand_cheapmatching2, helper for ks_rand_cheapmatching.
 autor: Frenkel TUD 2012-04"
  input Boolean b;
  input Integer c;
  input array<Integer> col_degrees;
  input array<Integer> row_degrees;
  input array<Integer> randarr;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ass1;
  input array<Integer> ass2;
  output list<Integer> onecolums;
  output list<Integer> onerows;
algorithm
  (onecolums,onerows) := match (b,c,col_degrees,row_degrees,randarr,m,mT,ass1,ass2)
    local 
      list<Integer> clst,rlst,lst;
      Integer e_id,r;
    case (true,_,_,_,_,_,_,_,_)
      equation
        e_id = realInt(realMod(System.realRand(),intReal(col_degrees[c])));
        lst = List.select(m[c], Util.intPositive);
        (rlst,r) = ks_rand_cheapmatching3(e_id,lst,row_degrees,c,ass1,ass2,{},0);
        lst = List.select(mT[r], Util.intPositive);
        clst = ks_rand_cheapmatching4(lst,row_degrees[r],col_degrees,ass1,{});
      then
        (clst,rlst);
    else
      ({},{});  
  end match;
end ks_rand_cheapmatching2;
  
protected function ks_rand_cheapmatching3
"function ks_rand_cheapmatching3, helper for ks_rand_match.
 autor: Frenkel TUD 2012-04"
  input Integer e_id;
  input list<Integer> rows;
  input array<Integer> row_degrees;
  input Integer c;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<Integer> onerows;
  input Integer inR;
  output list<Integer> outonerows;
  output Integer outR;
algorithm
  (outonerows,outR)  := matchcontinue(e_id,rows,row_degrees,c,ass1,ass2,onerows,inR)
    local
        list<Integer> rest,stack,statck1;
        Integer r,r_1;
      case (_,{},_,_,_,_,_,_) then (onerows,inR);
      case (_,r::rest,_,_,_,_,_,_)
        equation
          true = intLt(ass2[r],0);
          true = intEq(e_id,0);
          _ = arrayUpdate(ass1,c,r);
          _ = arrayUpdate(ass2,r,c); 
          stack = ks_rand_match_degree(rest,row_degrees,ass2,onerows);        
        then
          (stack,r); 
      case (_,r::rest,_,_,_,_,_,_)
        equation
           true = intLt(ass2[r],0);
          _ = arrayUpdate(row_degrees,r,row_degrees[r]-1);
          stack = List.consOnTrue(intEq(row_degrees[r],1),r,onerows);         
         (statck1,r_1) = ks_rand_cheapmatching3(e_id-1,rest,row_degrees,c,ass1,ass2,stack,r); 
        then
          (statck1,r_1);
      case (_,r::rest,_,_,_,_,_,_)
        equation
         (statck1,r_1) = ks_rand_cheapmatching3(e_id-1,rest,row_degrees,c,ass1,ass2,onerows,r); 
        then
          (statck1,r_1);          
    end matchcontinue;
end ks_rand_cheapmatching3;  
  
protected function ks_rand_cheapmatching4
"function ks_rand_cheapmatching4, helper for ks_rand_cheapmatching.
 autor: Frenkel TUD 2012-04"
  input list<Integer> cols;
  input Integer count;
  input array<Integer> col_degrees;
  input array<Integer> ass1;
  input list<Integer> inStack;
  output list<Integer> outStack;
algorithm
  outStack  := matchcontinue(cols,count,col_degrees,ass1,inStack)
    local
        list<Integer> rest,stack;
        Integer c;
      case ({},_,_,_,_) then inStack;
      case (_,_,_,_,_)
        equation
          false = intGt(count,0);
        then 
          inStack;
      case (c::rest,_,_,_,_)
        equation
          true = intLt(ass1[c],0);
          _ = arrayUpdate(col_degrees,c,col_degrees[c]-1);
          stack = List.consOnTrue(intEq(col_degrees[c],1),c,inStack);
        then
          ks_rand_cheapmatching4(rest,count-1,col_degrees,ass1,stack);
      case (_::rest,_,_,_,_)
        then
         ks_rand_cheapmatching4(rest,count,col_degrees,ass1,inStack); 
    end matchcontinue;
end ks_rand_cheapmatching4;  
  
protected function getOneRows
"function getOneRows, helper for ks_rand_cheapmatching.
 return all rows with length == 1
 autor: Frenkel TUD 2012-04"
 input Integer n;
 input BackendDAE.IncidenceMatrix m;
 input array<Integer> degrees;
 input list<Integer> inOneRows;
 output list<Integer> outOneRows;
algorithm
 outOneRows := match(n,m,degrees,inOneRows)
    local
      list<Integer> lst,onerows;
      Integer l;     
    case(0,_,_,_) then listReverse(inOneRows);
    else 
      equation
        lst = List.select(m[n], Util.intPositive);
        l = listLength(lst);
        _= arrayUpdate(degrees,n,l);
        onerows = List.consOnTrue(intEq(l,1),n,inOneRows);
     then
        getOneRows(n-1,m,degrees,onerows);
  end match; 
end getOneRows;

protected function setrandArray
"function setrandArray, helper for ks_rand_cheapmatching.
 return all rows with length == 1
 autor: Frenkel TUD 2012-04"
 input Integer n;
 input array<Integer> randarr;
algorithm
 _ := match(n,randarr)
    local
      Integer z,tmp;     
    case(0,_) then ();
    else 
      equation
        z = realInt(realMod(System.realRand(),intReal(n)))+1;
        tmp = randarr[n]; 
        _ = arrayUpdate(randarr,n,randarr[z]);
        _ = arrayUpdate(randarr,z,tmp);        
        setrandArray(n-1,randarr);
     then
       ();
  end match; 
end setrandArray;

protected function ks_rand_match
"function ks_rand_match, helper for ks_rand_cheapmatching.
 autor: Frenkel TUD 2012-04"
  input list<Integer> stack1;
  input list<Integer> stack2;
  input array<Integer> degrees1;
  input array<Integer> degrees2;
  input BackendDAE.IncidenceMatrix m1;
  input BackendDAE.IncidenceMatrix m2;
  input array<Integer> ass1;
  input array<Integer> ass2;
algorithm
  _  := matchcontinue (stack1,stack2,degrees1,degrees2,m1,m2,ass1,ass2)
    local
      Integer e;
      list<Integer> rest,lst,stack,stack_1;
    case ({},{},_,_,_,_,_,_) then ();
    case (e::rest,{},_,_,_,_,_,_)
      equation
        true = intEq(degrees1[e],1);
        true = intLt(ass1[e],0);
        lst = List.select(m1[e], Util.intPositive);
        stack = ks_rand_match1(e,lst,rest,degrees1,degrees2,m2,ass1,ass2);
        ks_rand_match(stack,{},degrees1,degrees2,m1,m2,ass1,ass2);
      then
        ();
    case (_::rest,{},_,_,_,_,_,_)
      equation
        ks_rand_match(rest,{},degrees1,degrees2,m1,m2,ass1,ass2);
      then
        ();   
    case ({},e::rest,_,_,_,_,_,_)
      equation
        true = intEq(degrees2[e],1);
        true = intLt(ass2[e],0);
        lst = List.select(m2[e], Util.intPositive);
        stack = ks_rand_match1(e,lst,rest,degrees2,degrees1,m1,ass2,ass1);
        ks_rand_match(stack,{},degrees2,degrees1,m2,m1,ass2,ass1);
      then
        ();        
    case ({},_::rest,_,_,_,_,_,_)
      equation
        ks_rand_match(rest,{},degrees2,degrees1,m2,m1,ass2,ass1);
      then
        ();                
    case (e::rest,_,_,_,_,_,_,_)
      equation
        true = intEq(degrees1[e],1);
        true = intLt(ass1[e],0);
        lst = List.select(m1[e], Util.intPositive);
        stack = ks_rand_match1(e,lst,rest,degrees1,degrees2,m2,ass1,ass2);
        ks_rand_match(stack2,stack,degrees2,degrees1,m2,m1,ass2,ass1);
      then
        ();
    case (_::rest,_,_,_,_,_,_,_)
      equation
        ks_rand_match(stack2,rest,degrees2,degrees1,m2,m1,ass2,ass1);
      then
        ();        
  end matchcontinue;  
end ks_rand_match;

protected function ks_rand_match1
"function ks_rand_match1, helper for ks_rand_match.
 autor: Frenkel TUD 2012-04"
  input Integer i;
  input list<Integer> entries;
  input list<Integer> stack;
  input array<Integer> degrees1;
  input array<Integer> degrees2;
  input BackendDAE.IncidenceMatrix incidence;
  input array<Integer> ass1;
  input array<Integer> ass2;  
  output list<Integer> outStack;
algorithm
  outStack  := matchcontinue(i,entries,stack,degrees1,degrees2,incidence,ass1,ass2)
    local
        list<Integer> rest,stack_1,lst;
        Integer e;
      case (_,{},_,_,_,_,_,_) then stack;
      case (_,e::rest,_,_,_,_,_,_)
        equation
          true = intLt(ass2[e],0);
          lst = List.select(incidence[e], Util.intPositive);
          _ = arrayUpdate(ass1,i,e);
          _ = arrayUpdate(ass2,e,i);          
        then
          ks_rand_match_degree(lst,degrees1,ass1,stack);
      case (_,_::rest,_,_,_,_,_,_)
        then
          ks_rand_match1(i,rest,stack,degrees1,degrees2,incidence,ass1,ass2);
    end matchcontinue;
end ks_rand_match1;

protected function ks_rand_match_degree
"function ks_rand_match_degree, helper for ks_rand_match.
 autor: Frenkel TUD 2012-04"
  input list<Integer> entries;
  input array<Integer> degrees;
  input array<Integer> ass;
  input list<Integer> inStack;
  output list<Integer> outStack;
algorithm
  outStack  := matchcontinue(entries,degrees,ass,inStack)
    local
        list<Integer> rest,stack;
        Integer e;
      case ({},_,_,_) then inStack;
      case (e::rest,_,_,_)
        equation
          true = intLt(ass[e],0);
          _ = arrayUpdate(degrees,e,degrees[e]-1);
          stack = List.consOnTrue(intEq(degrees[e],1),e,inStack);
        then
          ks_rand_match_degree(rest,degrees,ass,stack);
      case (_::rest,_,_,_)
        then
         ks_rand_match_degree(rest,degrees,ass,inStack); 
    end matchcontinue;
end ks_rand_match_degree;

/******************************************
 C-Implementation Stuff from 
 Kamer Kaya, Johannes Langguth and Bora Ucar
 see: http://bmi.osu.edu/~kamer/index.html
 *****************************************/

public function DFSBExternal
"function: DFSBExternal"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);        
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        checkSystemForMatching(nvars,neqns,inMatchingOptions);
        vec1 = arrayCreate(neqns,-1);
        vec2 = arrayCreate(nvars,-1);
        (vec1,vec2,syst,shared,arg) = matchingExternal({},false,1,3,1,isyst,ishared,nvars, neqns, vec1, vec2, inMatchingOptions, sssHandler, inArg);
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,ishared,inArg);
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "- Matching.DFSBExternal failed\n");
      then
        fail();
  end matchcontinue;
end DFSBExternal;

public function BFSBExternal
"function: BFSBExternal"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);        
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        checkSystemForMatching(nvars,neqns,inMatchingOptions);
        vec1 = arrayCreate(neqns,-1);
        vec2 = arrayCreate(nvars,-1);
        (vec1,vec2,syst,shared,arg) = matchingExternal({},false,2,3,1,isyst,ishared,nvars, neqns, vec1, vec2, inMatchingOptions, sssHandler, inArg);
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,ishared,inArg);
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "- Matching.BFSBExternal failed\n");
      then
        fail();
  end matchcontinue;
end BFSBExternal;

public function MC21AExternal
"function: MC21AExternal"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);        
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        checkSystemForMatching(nvars,neqns,inMatchingOptions);
        vec1 = arrayCreate(neqns,-1);
        vec2 = arrayCreate(nvars,-1);
        (vec1,vec2,syst,shared,arg) = matchingExternal({},false,3,3,1,isyst,ishared,nvars, neqns, vec1, vec2, inMatchingOptions, sssHandler, inArg);
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,ishared,inArg);
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "- Matching.MC21AExternal failed\n");
      then
        fail();
  end matchcontinue;
end MC21AExternal;

public function PFExternal
"function: PFExternal"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);        
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        checkSystemForMatching(nvars,neqns,inMatchingOptions);
        vec1 = arrayCreate(neqns,-1);
        vec2 = arrayCreate(nvars,-1);
        (vec1,vec2,syst,shared,arg) = matchingExternal({},false,4,3,1,isyst,ishared,nvars, neqns, vec1, vec2, inMatchingOptions, sssHandler, inArg);
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,ishared,inArg);
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "- Matching.PFExternal failed\n");
      then
        fail();
  end matchcontinue;
end PFExternal;

public function PFPlusExternal
"function: PFExternal"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);        
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        checkSystemForMatching(nvars,neqns,inMatchingOptions);
        vec1 = arrayCreate(neqns,-1);
        vec2 = arrayCreate(nvars,-1);
        (vec1,vec2,syst,shared,arg) = matchingExternal({},false,5,3,1,isyst,ishared,nvars, neqns, vec1, vec2, inMatchingOptions, sssHandler, inArg);
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,ishared,inArg);
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "- Matching.PFPlusExternal failed\n");
      then
        fail();
  end matchcontinue;
end PFPlusExternal;

public function HKExternal
"function: HKExternal"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);        
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        checkSystemForMatching(nvars,neqns,inMatchingOptions);
        vec1 = arrayCreate(neqns,-1);
        vec2 = arrayCreate(nvars,-1);
        (vec1,vec2,syst,shared,arg) = matchingExternal({},false,6,3,1,isyst,ishared,nvars, neqns, vec1, vec2, inMatchingOptions, sssHandler, inArg);
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,ishared,inArg);
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "- Matching.HKExternal failed\n");
      then
        fail();
  end matchcontinue;
end HKExternal;

public function HKDWExternal
"function: HKDWExternal"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);        
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        checkSystemForMatching(nvars,neqns,inMatchingOptions);
        vec1 = arrayCreate(neqns,-1);
        vec2 = arrayCreate(nvars,-1);
        (vec1,vec2,syst,shared,arg) = matchingExternal({},false,7,3,1,isyst,ishared,nvars, neqns, vec1, vec2, inMatchingOptions, sssHandler, inArg);
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,ishared,inArg);
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "- Matching.HKDWExternal failed\n");
      then
        fail();
  end matchcontinue;
end HKDWExternal;

public function ABMPExternal
"function: ABMPExternal"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);        
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        checkSystemForMatching(nvars,neqns,inMatchingOptions);
        vec1 = arrayCreate(neqns,-1);
        vec2 = arrayCreate(nvars,-1);
        (vec1,vec2,syst,shared,arg) = matchingExternal({},false,8,3,1,isyst,ishared,nvars, neqns, vec1, vec2, inMatchingOptions, sssHandler, inArg);
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,ishared,inArg);
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "- Matching.ABMPExternal failed\n");
      then
        fail();
  end matchcontinue;
end ABMPExternal;

public function PR_FIFO_FAIRExternal
"function: PR_FIFO_FAIRExternal"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);        
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        checkSystemForMatching(nvars,neqns,inMatchingOptions);
        vec1 = arrayCreate(neqns,-1);
        vec2 = arrayCreate(nvars,-1);
        (vec1,vec2,syst,shared,arg) = matchingExternal({},false,10,3,1,isyst,ishared,nvars, neqns, vec1, vec2, inMatchingOptions, sssHandler, inArg);
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_)
      equation
        nvars = BackendDAEUtil.systemSize(isyst);
        neqns = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{})); 
      then
        (syst,ishared,inArg);
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "- Matching.PR_FIFO_FAIRExternal failed\n");
      then
        fail();
  end matchcontinue;
end PR_FIFO_FAIRExternal;

protected function matchingExternal
"function: matchingExternal, helper for external matching algorithms
  author: Frenkel TUD"
  input list<Integer> meqns "Marked Equations for Index Reduction";
  input Boolean internalCall "true if function is called from it self";
  input Integer algIndx "Index of the algorithm, see BackendDAEEXT.matching";
  input Integer cheapMatching "Method for cheap Matching";
  input Integer clearMatching;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer nv;
  input Integer ne;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output array<Integer> outAss1;
  output array<Integer> outAss2;  
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outAss1,outAss2,osyst,oshared,outArg):=
  matchcontinue (meqns,internalCall,algIndx,cheapMatching,clearMatching,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg)
    local
      BackendDAE.IncidenceMatrix m,mt;
      Integer nv_1,ne_1,memsize,clearmatching;
      BackendDAE.EquationConstraints eq_cons;
      list<Integer> var_lst,meqns_1;
      String eqn_str,var_str;
      BackendDAE.StructurallySingularSystemHandlerArg arg,arg1;
      DAE.ElementSource source;
      Absyn.Info info;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;    
      array<Integer> ass1_1,ass1_2,ass1_3,ass2_1,ass2_2,ass2_3;  

    case ({},true,_,_,_,syst,_,_,_,_,_,_,_,_) 
      then 
        (ass1,ass2,syst,ishared,inArg);
    case ({},false,_,_,_,syst as BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_,_,_,_)
      equation
        matchingExternalsetIncidenceMatrix(nv,ne,m);
        BackendDAEEXT.matching(nv,ne,algIndx,cheapMatching,1.0,clearMatching);
        meqns_1 = BackendDAEEXT.getEqnsforIndexReduction();
        BackendDAEEXT.getAssignment(ass1,ass2);
        (ass1_1,ass2_1,syst,shared,arg) = matchingExternal(meqns_1,true,algIndx,-1,0,syst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg);
      then
        (ass1_1,ass2_1,syst,shared,arg);
    case (_::_,_,_,_,_,_,_,_,_,_,_,(BackendDAE.INDEX_REDUCTION(),eq_cons),_,_)
      equation
        memsize = arrayLength(ass1);
        (_,_,syst,shared,ass2_1,ass1_1,arg) = sssHandler(meqns,0,isyst,ishared,ass2,ass1,inArg);
        ne_1 = BackendDAEUtil.systemSize(syst);
        nv_1 = BackendVariable.daenumVariables(syst);
        ass1_2 = assignmentsArrayExpand(ass1_1,ne_1,memsize,-1);
        ass2_2 = assignmentsArrayExpand(ass2_1,nv_1,memsize,-1);
        true = BackendDAEEXT.setAssignment(ne_1,nv_1,ass1_2,ass2_2);
        (ass1_3,ass2_3,syst,shared,arg1) = matchingExternal({},false,algIndx,cheapMatching,clearMatching,syst,shared,nv_1,ne_1,ass1_2,ass2_2,inMatchingOptions,sssHandler,arg);
      then
        (ass1_3,ass2_3,syst,shared,arg1);

    else
      equation
        eqn_str = "";
        var_str = "";
        source = BackendEquation.markedEquationSource(isyst, listGet({},1));
        info = DAEUtil.getElementSourceFileInfo(source);
        Error.addSourceMessage(Error.STRUCT_SINGULAR_SYSTEM, {eqn_str,var_str}, info);
      then
        fail();

  end matchcontinue;
end matchingExternal;

protected function countincidenceMatrixEntries
  input Integer i;
  input BackendDAE.IncidenceMatrix m;
  input Integer inCount;
  output Integer outCount;
algorithm
  outCount := match(i,m,inCount)
    local 
      list<Integer> lst;
      Integer l;
    case(0,_,_) then inCount;
    else
      equation
        lst = List.select(m[i], Util.intPositive);
        l = listLength(lst);           
      then 
        countincidenceMatrixEntries(i-1,m,inCount + l);
  end match;
end countincidenceMatrixEntries;

public function matchingExternalsetIncidenceMatrix
"function: matchingExternalsetIncidenceMatrix
  author: Frenkel TUD 2012-04
  "
  input Integer nv;
  input Integer ne;  
  input array<list<Integer>> m;
protected
 Integer l;
 Integer nz;
algorithm
  l:=arrayLength(m);
  nz := countincidenceMatrixEntries(l,m,0);
  BackendDAEEXT.setIncidenceMatrix(nv,ne,nz,m);
end matchingExternalsetIncidenceMatrix;

/*****************************************************/
/*              Util Functions                       */
/*****************************************************/

public function isAssigned
"function isAssigned
  author: Frenkel TUD 2012-05"
  input array<Integer> ass;
  input Integer i;
  output Boolean b;
algorithm
  b := intGt(ass[intAbs(i)],0);
end isAssigned;

public function isUnAssigned
"function isUnAssigned
  author: Frenkel TUD 2012-05"
  input array<Integer> ass;
  input Integer i;
  output Boolean b;
algorithm
  b := intLt(ass[intAbs(i)],1);
end isUnAssigned;

public function getMarked
"function getMarked
  author: Frenkel TUD 2012-05"
  input Integer ne;
  input Integer mark;
  input array<Integer> markArr;
  input list<Integer> iMarked;
  output list<Integer> oMarked;
algorithm
  oMarked := match(ne,mark,markArr,iMarked)
    local 
      list<Integer> marked;
    case (0,_,_,_)
      then
        iMarked;
    case (_,_,_,_)
      equation
        marked = List.consOnTrue(intEq(markArr[ne],mark), ne, iMarked);
      then
        getMarked(ne-1,mark,markArr,marked);
  end match;
end getMarked;

public function getUnassigned
"function getUnassigned
  author: Frenkel TUD 2012-05
  return all Indixes with ass[indx]<1, traverses the 
  array from the ne element to the first."
  input Integer ne;
  input array<Integer> ass;
  input list<Integer> inUnassigned;
  output list<Integer> outUnassigned;
algorithm
  outUnassigned := match(ne,ass,inUnassigned)
    local 
      list<Integer> unassigned;
    case (0,_,_)
      then
        inUnassigned;
    case (_,_,_)
      equation
        unassigned = List.consOnTrue(intLt(ass[ne],1), ne, inUnassigned);
      then
        getUnassigned(ne-1,ass,unassigned);
  end match;
end getUnassigned;

public function getAssigned
"function getAssigned
  author: Frenkel TUD 2012-05
  return all Indixes with ass[indx]>0, traverses the 
  array from the ne element to the first."
  input Integer ne;
  input array<Integer> ass;
  input list<Integer> inAssigned;
  output list<Integer> outAssigned;
algorithm
  outAssigned := match(ne,ass,inAssigned)
    local 
      list<Integer> assigned;
    case (0,_,_)
      then
        inAssigned;
    case (_,_,_)
      equation
        assigned = List.consOnTrue(intGt(ass[ne],0), ne, inAssigned);
      then
        getAssigned(ne-1,ass,assigned);
  end match;
end getAssigned;

protected function getEqnsforIndexReduction
"function getEqnsforIndexReduction, collect all equations for the index reduction from a given set of 
 unmatched equations
 autor: Frenkel TUD 2012-04"
  input list<Integer> U;
  input Integer neqns;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  output list<Integer> eqns;
algorithm
  eqns := match(U,neqns,m,ass2)
    local array<Boolean> colummarks;
    case({},_,_,_) then {};
    else
      equation
        colummarks = arrayCreate(neqns,false);
      then
        getEqnsforIndexReduction1(U,m,colummarks,ass2,{});
    end match;
end getEqnsforIndexReduction;

protected function getEqnsforIndexReduction1
"function getEqnsforIndexReduction1, helper for getEqnsforIndexReduction
 autor: Frenkel TUD 2012-04"
  input list<Integer> U;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input array<Boolean> colummarks;
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input list<Integer> inEqns;
  output list<Integer> outEqns;
algorithm
  outEqns:= matchcontinue (U,m,colummarks,ass2,inEqns)
    local 
      list<Integer> rest,eqns;
      Integer e;
    case ({},_,_,_,_) then listReverse(inEqns);
    case (e::rest,_,_,_,_)
      equation
        // row is not visited
        false = colummarks[e];
        _= arrayUpdate(colummarks,e,true);
        eqns = getEqnsforIndexReductionphase(e,m,colummarks,ass2,e::inEqns);
      then
        getEqnsforIndexReduction1(rest,m,colummarks,ass2,eqns);
    case (_::rest,_,_,_,_)
      then
        getEqnsforIndexReduction1(rest,m,colummarks,ass2,inEqns);        
  end matchcontinue;
end getEqnsforIndexReduction1;

protected function getEqnsforIndexReductionphase
"function helper for getEqnsforIndexReduction
 autor: Frenkel TUD 2012-04"
  input Integer e;
  input BackendDAE.IncidenceMatrix m;
  input array<Boolean> colummarks;
  input array<Integer> ass2;
  input list<Integer> inEqns;
  output list<Integer> outEqns;
algorithm
  outEqns :=
  match (e,m,colummarks,ass2,inEqns)
    local
      list<Integer> rest,rows; 
    case (_,_,_,_,_)
      equation
        // traverse all adiacent rows
        rows = List.select(m[e], Util.intPositive);
      then
        getEqnsforIndexReductiontraverseRows(rows,m,colummarks,ass2,inEqns);
    else
      then
        fail();
  end match;
end getEqnsforIndexReductionphase;

protected function getEqnsforIndexReductiontraverseRows
"function helper for getEqnsforIndexReductiont
 autor: Frenkel TUD 2012-04"
  input list<Integer> rows;
  input BackendDAE.IncidenceMatrix m;
  input array<Boolean> colummarks;
  input array<Integer> ass2;
  input list<Integer> inEqns;
  output list<Integer> outEqns;
algorithm
  outEqns:=
  matchcontinue (rows,m,colummarks,ass2,inEqns)
    local
      list<Integer> rest,queue,queue2; 
      Integer rc,r;    
      Boolean b;
    case ({},_,_,_,_) then inEqns;
    case (r::rest,_,_,_,_)
      equation
        // row is matched
        rc = ass2[r];
        true = intGt(rc,0);
        false = colummarks[rc];
        _= arrayUpdate(colummarks,rc,true);        
        queue = getEqnsforIndexReductionphase(rc,m,colummarks,ass2,rc::inEqns);
      then
        getEqnsforIndexReductiontraverseRows(rest,m,colummarks,ass2,queue);
    case (_::rest,_,_,_,_)
      then
        getEqnsforIndexReductiontraverseRows(rest,m,colummarks,ass2,inEqns);
  end matchcontinue;
end getEqnsforIndexReductiontraverseRows;

protected function reduceIndexifNecessary
"function: reduceIndexifNecessary, calls sssHandler if system need index reduction
  author: Frenkel TUD 2012-04"
  input list<Integer> meqns "Marked Equations for Index Reduction";
  input Integer actualEqn;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer nv;
  input Integer ne;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output list<Integer> outchangedEqns;
  output Integer continueEqn;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output Integer nvars;
  output Integer neqns;
  output array<Integer> outAss1;
  output array<Integer> outAss2;  
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outchangedEqns,continueEqn,osyst,oshared,nvars,neqns,outAss1,outAss2,outArg):=
  match (meqns,actualEqn,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg)
    local
      Integer nv_1,ne_1,i_1;
      BackendDAE.EquationConstraints eq_cons;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;    
      array<Integer> ass1_1,ass1_2,ass2_1,ass2_2; 
      list<Integer> changedEqns; 

    case ({},_,_,_,_,_,_,_,_,_,_) 
      then 
        ({},actualEqn+1,isyst,ishared,nv,ne,ass1,ass2,inArg);
    case (_::_,_,_,_,_,_,_,_,(BackendDAE.INDEX_REDUCTION(),eq_cons),_,_)
      equation
        (changedEqns,i_1,syst,shared,ass2_1,ass1_1,arg) = sssHandler(meqns,actualEqn,isyst,ishared,ass2,ass1,inArg);
        ne_1 = BackendDAEUtil.systemSize(syst);
        nv_1 = BackendVariable.daenumVariables(syst);
        ass1_2 = assignmentsArrayExpand(ass1_1,ne_1,arrayLength(ass1_1),-1);
        ass2_2 = assignmentsArrayExpand(ass2_1,nv_1,arrayLength(ass2_1),-1);
      then
        (changedEqns,i_1,syst,shared,nv_1,ne_1,ass1_2,ass2_2,arg);
  end match;
end reduceIndexifNecessary;

protected function assignmentsArrayExpand
"function helper for assignmentsArrayExpand
 autor: Frenkel TUD 2012-04"
 input array<Integer> ass;
 input Integer needed;
 input Integer memsize;
 input Integer default;
 output array<Integer> outAss;
algorithm
  outAss := matchcontinue(ass,needed,memsize,default)
    case (_,_,_,_)
      equation
        true = intGt(memsize,needed);
      then
        ass;
    case (_,_,_,_)
      equation
        false = intGt(memsize,needed);
      then
        Util.arrayExpand(needed-memsize, ass, default);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Matching.assignmentsArrayExpand failed!"});
      then
        fail();
  end matchcontinue;    
end assignmentsArrayExpand;

protected function prune
"function: checkSystemForMatching
  author: Frenkel TUD 2012-06
  function to prune, mark as never again test, collums"
  input list<Integer> inVisitedcolums;
  input Integer ne;
  input array<Integer> rowmarks;
  input array<Integer> ass1;
algorithm
  _:= match (inVisitedcolums,ne,rowmarks,ass1)
     local 
       Integer c,r;
       list<Integer> rest;
     case ({},_,_,_) then ();
     case (c::rest,_,_,_)
       equation
         r = ass1[c];
         _ = arrayUpdate(rowmarks,r,ne+1);
         prune(rest,ne,rowmarks,ass1);
       then
         ();
   end match; 
end prune;

public function checkSystemForMatching
"function: checkSystemForMatching
  author: Frenkel TUD 2012-06

  Checks that the system is qualified for matching, i.e. that the number of variables
  is the same as the number of equations. If not, the function fails and
  prints an error message.
  If matching options indicate that underconstrained systems are ok, no
  check is performed."
  input Integer nvars;
  input Integer neqns;
  input BackendDAE.MatchingOptions inMatchingOptions;
algorithm
  _ := matchcontinue (nvars,neqns,inMatchingOptions)
    local
      Integer esize,vars_size;
      BackendDAE.EquationArray eqns;
      String esize_str,vsize_str;
    case (_,_,(_,BackendDAE.ALLOW_UNDERCONSTRAINED())) then ();
    case (_,_,_)
      equation
        true = intEq(nvars,neqns);
      then
        ();
    case (_,_,_)
      equation
        true = intGt(nvars,neqns);
        esize = neqns - 1;
        vars_size = nvars - 1 "remove dummy var" ;
        esize_str = intString(esize) "remove dummy var" ;
        vsize_str = intString(vars_size);
        Error.addMessage(Error.UNDERDET_EQN_SYSTEM, {esize_str,vsize_str});
      then
        fail();
    case (_,_,_)
      equation
        true = intLt(nvars,neqns);
        esize = neqns - 1;
        vars_size = nvars - 1 "remove dummy var" ;
        esize_str = intString(esize) "remove dummy var" ;
        vsize_str = intString(vars_size);
        Error.addMessage(Error.OVERDET_EQN_SYSTEM, {esize_str,vsize_str});
      then
        fail();
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "- Matching.checkSystemForMatching failed\n");
      then
        fail();
  end matchcontinue;
end checkSystemForMatching;


protected function checkAssignment
"function: checkAssignment
  author: Frenkel TUD 2012-06
  Check if the assignment is complet/maximum,
  returns all unmatched equations"  
  input Integer indx;
  input Integer ne;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<Integer> inUnassigned;
  output list<Integer> outUnassigned;
algorithm
  outUnassigned := matchcontinue(indx,ne,ass1,ass2,inUnassigned)
    local 
      Integer r,c;
      list<Integer> unassigned;
    case (_,_,_,_,_)
      equation
        true = intGt(indx,ne);
      then
        inUnassigned;
    case (_,_,_,_,_)
      equation
        r = ass1[indx];
        unassigned = List.consOnTrue(intLt(r,0), indx, inUnassigned);
      then
        checkAssignment(indx+1,ne,ass1,ass2,unassigned);
  end matchcontinue;
end checkAssignment;

/*************************************/
/*   tests */
/*************************************/

public function testMatchingAlgorithms
"function testMatchingAlgorithms, test all matching algorithms
 autor: Frenkel TUD 2012-03"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
protected
  Real t;
  Integer nv,ne,cheapID;
  array<list<Integer>> m;
  array<Integer> vec1,vec2;
  list<Integer> unassigned,meqns;
  list<tuple<String,matchingAlgorithmFunc>> matchingAlgorithms;
  list<tuple<String,Integer>> extmatchingAlgorithms;
  BackendDAE.EqSystem syst;
algorithm
  ne := BackendDAEUtil.systemSize(isyst);
  nv := BackendVariable.daenumVariables(isyst);
  print("Systemsize: " +& intString(ne) +& "\n");
  matchingAlgorithms := {("OMCNew:   ",DFSLH),
                         ("BFSB:     ",BFSB),
                         ("DFSB:     ",DFSB),
                         ("MC21A:    ",MC21A),
                         ("PF:       ",PF),
                         ("PFPlus:   ",PFPlus),
                         ("HK:       ",HK),
                         ("HKDW:     ",HKDW),
                         ("ABMP:     ",ABMP),
                         ("PR:       ",PR_FIFO_FAIR)};

  syst := randSortSystem(isyst,ishared);
  testMatchingAlgorithms1(matchingAlgorithms,syst,ishared,inMatchingOptions);
  
  System.realtimeTick(BackendDAE.RT_PROFILER0);
  (_,m,_) := BackendDAEUtil.getIncidenceMatrixfromOption(syst,ishared,BackendDAE.NORMAL());
  matchingExternalsetIncidenceMatrix(nv,ne,m);
  cheapID := 3;
  t := System.realtimeTock(BackendDAE.RT_PROFILER0);
  print("SetMEXT:     " +& realString(t) +& "\n"); 
  extmatchingAlgorithms := {("DFSEXT:   ",1),
                            ("BFSEXT:   ",2),
                            ("MC21AEXT: ",3),
                            ("PFEXT:    ",4),
                            ("PFPlusEXT:",5),
                            ("HKEXT:    ",6),
                            ("HKDWEXT   ",7),
                            ("ABMPEXT   ",8),
                            ("PREXT:    ",10)};
  testExternMatchingAlgorithms1(extmatchingAlgorithms,cheapID,nv,ne);
  System.realtimeTick(BackendDAE.RT_PROFILER0);
  vec1 := arrayCreate(ne,-1);
  vec2 := arrayCreate(nv,-1);
  BackendDAEEXT.getAssignment(vec1,vec2);
  print("GetAssEXT:   " +& realString(t) +& "\n"); 
  System.realtimeTick(BackendDAE.RT_PROFILER0);
  //unassigned := checkAssignment(1,ne,vec1,vec2,{});
  //print("Unnasigned: " +& intString(listLength(unassigned)) +& "\n");
  //print("Unassigned:\n");
  //BackendDump.debuglst((unassigned,intString,"\n","\n"));
  //BackendDump.dumpMatching(vec1);  
end testMatchingAlgorithms;

public function testMatchingAlgorithms1
"function testMatchingAlgorithms1, helper for testMatchingAlgorithms
 autor: Frenkel TUD 2012-04"
  input list<tuple<String,matchingAlgorithmFunc>> matchingAlgorithms;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions; 
  partial function matchingAlgorithmFunc
    input BackendDAE.EqSystem isyst;
    input BackendDAE.Shared ishared;
    input BackendDAE.MatchingOptions inMatchingOptions;
    input StructurallySingularSystemHandlerFunc sssHandler;
    input BackendDAE.StructurallySingularSystemHandlerArg inArg;
    output BackendDAE.EqSystem osyst;
    output BackendDAE.Shared oshared;
    output BackendDAE.StructurallySingularSystemHandlerArg outArg;
    partial function StructurallySingularSystemHandlerFunc
      input list<Integer> eqns;
      input Integer actualEqn;
      input BackendDAE.EqSystem isyst;
      input BackendDAE.Shared ishared;
      input array<Integer> inAssignments1;
      input array<Integer> inAssignments2;
      input BackendDAE.StructurallySingularSystemHandlerArg inArg;
      output list<Integer> changedEqns;
      output Integer continueEqn;
      output BackendDAE.EqSystem osyst;
      output BackendDAE.Shared oshared;
      output array<Integer> outAssignments1;
      output array<Integer> outAssignments2; 
      output BackendDAE.StructurallySingularSystemHandlerArg outArg;
    end StructurallySingularSystemHandlerFunc;  
  end matchingAlgorithmFunc;   
algorithm
  _ :=
  matchcontinue (matchingAlgorithms,isyst,ishared,inMatchingOptions)    
      local 
        list<tuple<String,matchingAlgorithmFunc>> rest;
        String str;
        matchingAlgorithmFunc matchingAlgorithm;
        Real t;
    case ({},_,_,_)
      then ();
    case ((str,matchingAlgorithm)::rest,_,_,_)
      equation
        System.realtimeTick(BackendDAE.RT_PROFILER0);
        testMatchingAlgorithm(10,matchingAlgorithm,isyst,ishared,inMatchingOptions);
        t = System.realtimeTock(BackendDAE.RT_PROFILER0);
        print(str +& realString(realDiv(t,10.0)) +& "\n");       
        testMatchingAlgorithms1(rest,isyst,ishared,inMatchingOptions);
      then
        ();
    case ((str,matchingAlgorithm)::rest,_,_,_)
      equation
        print(str +& "failed!\n");       
        testMatchingAlgorithms1(rest,isyst,ishared,inMatchingOptions);
      then
        ();        
  end matchcontinue;
end testMatchingAlgorithms1;

public function testMatchingAlgorithm
"function testMatchingAlgorithm, tests a specific matching algorithm
 autor: Frenkel TUD 2012-04"
  input Integer index;
  input matchingAlgorithmFunc matchingAlgorithm;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions; 
  partial function matchingAlgorithmFunc
    input BackendDAE.EqSystem isyst;
    input BackendDAE.Shared ishared;
    input BackendDAE.MatchingOptions inMatchingOptions;
    input StructurallySingularSystemHandlerFunc sssHandler;
    input BackendDAE.StructurallySingularSystemHandlerArg inArg;
    output BackendDAE.EqSystem osyst;
    output BackendDAE.Shared oshared;
    output BackendDAE.StructurallySingularSystemHandlerArg outArg;
    partial function StructurallySingularSystemHandlerFunc
      input list<Integer> eqns;
      input Integer actualEqn;
      input BackendDAE.EqSystem isyst;
      input BackendDAE.Shared ishared;
      input array<Integer> inAssignments1;
      input array<Integer> inAssignments2;
      input BackendDAE.StructurallySingularSystemHandlerArg inArg;
      output list<Integer> changedEqns;
      output Integer continueEqn;
      output BackendDAE.EqSystem osyst;
      output BackendDAE.Shared oshared;
      output array<Integer> outAssignments1;
      output array<Integer> outAssignments2; 
      output BackendDAE.StructurallySingularSystemHandlerArg outArg;
    end StructurallySingularSystemHandlerFunc;  
  end matchingAlgorithmFunc; 
algorithm
  _ :=
  matchcontinue (index,matchingAlgorithm,isyst,ishared,inMatchingOptions) 
    local
      BackendDAE.StructurallySingularSystemHandlerArg arg;   
    case (0,_,_,_,_)
      then ();
    else
      equation
        arg = IndexReduction.getStructurallySingularSystemHandlerArg(isyst,ishared);
        (_,_,_) = matchingAlgorithm(isyst,ishared,inMatchingOptions,IndexReduction.pantelidesIndexReduction,arg);
        testMatchingAlgorithm(index-1,matchingAlgorithm,isyst,ishared,inMatchingOptions);
      then
        ();
  end matchcontinue;
end testMatchingAlgorithm;

public function testExternMatchingAlgorithms1
"function testExternMatchingAlgorithms1, helper for testMatchingAlgorithms
 autor: Frenkel TUD 2012-04"
  input list<tuple<String,Integer>> matchingAlgorithms;
  input Integer cheapId;
  input Integer nv;
  input Integer ne;   
algorithm
  _ :=
  matchcontinue (matchingAlgorithms,cheapId,nv,ne)    
      local 
        list<tuple<String,Integer>> rest;
        String str;
        Integer matchingAlgorithm;
        Real t;
    case ({},_,_,_)
      then ();
    case ((str,matchingAlgorithm)::rest,_,_,_)
      equation
        System.realtimeTick(BackendDAE.RT_PROFILER0);
        testExternMatchingAlgorithm(10,matchingAlgorithm,cheapId,nv,ne);
        t = System.realtimeTock(BackendDAE.RT_PROFILER0);
        print(str +& realString(realDiv(t,10.0)) +& "\n");       
        testExternMatchingAlgorithms1(rest,cheapId,nv,ne);
      then
        ();
    case ((str,matchingAlgorithm)::rest,_,_,_)
      equation
        print(str +& "failed!\n");       
        testExternMatchingAlgorithms1(rest,cheapId,nv,ne);
      then
        ();        
  end matchcontinue;
end testExternMatchingAlgorithms1;

public function testExternMatchingAlgorithm
"function testMatchingAlgorithm, tests a specific matching algorithm
 autor: Frenkel TUD 2012-04"
  input Integer index;
  input Integer matchingAlgorithm;
  input Integer cheapId;
  input Integer nv;
  input Integer ne;   
algorithm
  _ :=
  matchcontinue (index,matchingAlgorithm,cheapId,nv,ne)    
    case (0,_,_,_,_)
      then ();
    else
      equation
        BackendDAEEXT.matching(nv,ne,matchingAlgorithm,cheapId,1.0,1);
        testExternMatchingAlgorithm(index-1,matchingAlgorithm,cheapId,nv,ne);
      then
        ();
  end matchcontinue;
end testExternMatchingAlgorithm;

protected function randSortSystem
"function randSortSystem, resort all equations and variables in random order
 autor: Frenkel TUD 2012-043"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  output BackendDAE.EqSystem osyst;
algorithm
  osyst := match(isyst,ishared)
     local
     Integer ne,nv;
     array<Integer> randarr,randarr1;     
     BackendDAE.Variables vars,vars1;
     BackendDAE.EquationArray eqns,eqns1;
     BackendDAE.IncidenceMatrix m;
     BackendDAE.IncidenceMatrixT mT;  
     BackendDAE.EqSystem syst; 
   case (BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),_)
     equation
       ne = BackendDAEUtil.systemSize(isyst);
       nv = BackendVariable.daenumVariables(isyst);
       randarr = listArray(List.intRange(ne));
       setrandArray(ne,randarr);
       randarr1 = listArray(List.intRange(nv));
       setrandArray(nv,randarr1);
       eqns1 = randSortSystem1(ne,-1,randarr,eqns,BackendDAEUtil.listEquation({}),BackendDAEUtil.equationNth,BackendEquation.equationAdd);
       vars1 = randSortSystem1(nv,0,randarr1,vars,BackendDAEUtil.emptyVars(),BackendVariable.getVarAt,BackendVariable.addVar);
       (syst,_,_) = BackendDAEUtil.getIncidenceMatrix(BackendDAE.EQSYSTEM(vars1,eqns1,NONE(),NONE(),BackendDAE.NO_MATCHING()),ishared,BackendDAE.NORMAL());
     then 
       syst;
  end match;       
end randSortSystem;

protected function randSortSystem1
  input Integer index;
  input Integer offset;
  input array<Integer> randarr;
  input Type_a oldTypeA;
  input Type_a newTypeA;
  input getFunc get;
  input setFunc set;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;  
  partial function getFunc
    input Type_a inTypeA;
    input Integer inInteger;
    output Type_b outTypeB;
  end getFunc;  
  partial function setFunc
    input Type_b inTypeB;
    input Type_a inTypeA;
    output Type_a outTypeA;
  end setFunc; 
algorithm
  outTypeA := match(index,offset,randarr,oldTypeA,newTypeA,get,set)
    local 
      Type_b tb;
      Type_a ta;
    case (0,_,_,_,_,_,_)
      then newTypeA;
    else
      equation
        tb = get(oldTypeA,randarr[index]+offset);
        ta = set(tb,newTypeA);
      then
       randSortSystem1(index-1,offset,randarr,oldTypeA,ta,get,set);
  end match; 
end randSortSystem1;


end Matching;