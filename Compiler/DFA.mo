package DFA "
This file is part of OpenModelica.

Copyright (c) 1998-2006, Linkopings universitet, Department of
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

 Neither the name of Linkopings universitet nor the names of its
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

  
  file:	 DFA.mo
  module:      DFA
  description: DFA intermediate form
"

public import Absyn;
public import Matrix;
public import Util;
public import Env;
public import Lookup;
type Stamp = Integer;
type ArcName = Absyn.Ident;
public import SCode;

public uniontype Dfa
  record DFArec
    list<Absyn.ElementItem> localVarList;
    list<Absyn.ElementItem> pathVarList; // Onodigt?
    Option<Matrix.RightHandSide> elseCase;
    State startState;
    Integer numOfStates;
  end DFArec;
end Dfa;

public uniontype State
  record STATE
    Stamp stamp;
    Integer refCount;
    list<Arc> outgoingArcs;
    Option<Matrix.RightHandSide> rhSide;
  end STATE;
  
  record DUMMIESTATE 
  end DUMMIESTATE;
end State;

public uniontype Arc
  record ARC
    State state;
    ArcName arcName;
    Option<Matrix.RenamedPat> pat;
  end ARC;
end Arc;


public function addNewArc "function: addNewArc
A function that adds a new arc to a states arc-list
"
  input State firstState;
  input ArcName arcName; 
  input State newState;
  input Option<Matrix.RenamedPat> pat;
  output State outState;
algorithm
  outState :=
  matchcontinue (firstState,arcName,newState,pat)
    case (STATE(localStamp,localRefCount,localOutArcs,localRhSide),
        localArcName,localNewState,localPat)
      local
        State localFirstState;
        ArcName localArcName;
        State localNewState;
        Stamp localStamp;
        Integer localRefCount;
        list<Arc> localOutArcs;
        Option<Matrix.RightHandSide> localRhSide;
        Arc newArc;
        Option<Matrix.RenamedPat> localPat;
      equation
        newArc = ARC(localNewState,localArcName,localPat);    
        localOutArcs = listAppend(localOutArcs,(newArc :: {}));  
        localFirstState = STATE(localStamp,localRefCount,localOutArcs,localRhSide);
      then localFirstState;
  end matchcontinue;    
end addNewArc;  

public function fromDFAtoIfNodes "function: fromDFAtoIfNodes
Main function for converting a DFA into a valueblock expression containing
if-statements.
"
  input Dfa dfa;
  input list<Absyn.Exp> resVarList;
  input Env.Cache cache;
  input Env.Env env;
  output Absyn.Exp outExp;
algorithm
  outExp :=
  matchcontinue (dfa,resVarList,cache,env)
    local
      list<Absyn.ElementItem> localVarList,varList;
      Option<Matrix.RightHandSide> elseCase;
      State startState;
      Absyn.Exp exp,resExpr;
      list<Absyn.AlgorithmItem> algs,algs2;
      Integer numStates;
      Absyn.Exp statesList;
      Env.Cache localCache;
      Env.Env localEnv;
      list<Absyn.Exp> expList,localResVarList;
    case (DFArec(localVarList,_,elseCase,startState,numStates),localResVarList,localCache,localEnv)
      equation 

        // Used for catch handling		        
       /* varList = Util.listCreate(Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
            Absyn.TPATH(Absyn.IDENT("Integer"),NONE()),		
            {Absyn.COMPONENTITEM(Absyn.COMPONENT("OLDSTATE",{},NONE()),NONE(),NONE())}),
            Absyn.INFO("f",false,0,0,0,0),NONE())));
        
        localVarList = listAppend(localVarList,varList);	
        
        varList = Util.listCreate(Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
            Absyn.TPATH(Absyn.IDENT("Integer"),NONE()),		
            {Absyn.COMPONENTITEM(Absyn.COMPONENT("CURRENT-STATE",{},NONE()),NONE(),NONE())}),
            Absyn.INFO("f",false,0,0,0,0),NONE())));
        
        localVarList = listAppend(localVarList,varList);
        
        varList = Util.listCreate(Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
            Absyn.TPATH(Absyn.IDENT("Integer"),NONE()),		
            {Absyn.COMPONENTITEM(Absyn.COMPONENT("NEIGHBORSTATES",{Absyn.SUBSCRIPT(Absyn.INTEGER(numStates))},NONE()),NONE(),NONE())}),
            Absyn.INFO("f",false,0,0,0,0),NONE())));
        
        localVarList = listAppend(localVarList,varList);
        */
        
        varList = Util.listCreate(Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
            Absyn.TPATH(Absyn.IDENT("Boolean"),NONE()),		
            {Absyn.COMPONENTITEM(Absyn.COMPONENT("BOOLVAR__",{},SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE(),NONE())}),
            Absyn.INFO("f",false,0,0,0,0),NONE())));
        
        localVarList = listAppend(localVarList,varList);
          
        varList = Util.listCreate(Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
            Absyn.TPATH(Absyn.IDENT("Boolean"),NONE()),		
            {Absyn.COMPONENTITEM(Absyn.COMPONENT("DUMMIE__",{},SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE(),NONE())}),
            Absyn.INFO("f",false,0,0,0,0),NONE())));
        
        localVarList = listAppend(localVarList,varList);
        
        varList = Util.listCreate(Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
            Absyn.TPATH(Absyn.IDENT("Boolean"),NONE()),		
            {Absyn.COMPONENTITEM(Absyn.COMPONENT("ELSEEXISTS__",{},SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE(),NONE())}),
            Absyn.INFO("f",false,0,0,0,0),NONE())));
        
        localVarList = listAppend(localVarList,varList);
        
        // Used for catch handling
        //Absyn.ARRAY(Absyn.ARRAY,...Absyn.ARRAY) 
       // statesList = Absyn.INTEGER(0); // generateStateLists(startState,{});
        
        algs2 = {}; //Util.listCreate(Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.CREF_IDENT("#NEIGHBORSTATES",{})),statesList),NONE())); 
        algs = generateAlgorithmBlock(localResVarList,startState,elseCase,localCache,localEnv);
        algs = listAppend(algs2,algs);
        
        resExpr = Util.listFirst(localResVarList);
        
        //Create a valueblock
        exp = Absyn.VALUEBLOCK(localVarList,Absyn.VALUEBLOCKALGORITHMS(algs),resExpr);
      then exp;     
  end matchcontinue;
end fromDFAtoIfNodes;  


public function generateAlgorithmBlock "function: generateAlgorithmBlock
 Generate the algorithm statements in the value block from the DFA
"
  input list<Absyn.Exp> resVarList; // Component references to the return list variables
  input State startState;
  input Option<Matrix.RightHandSide> elseCase;
  input Env.Cache cache;
  input Env.Env env;
  output list<Absyn.AlgorithmItem> outAlgorithms;
algorithm
  outAlgorithms :=
  matchcontinue (resVarList,startState,elseCase,cache,env)
    local
      Env.Cache localCache;
      Env.Env localEnv;     
      list<Absyn.Exp> localResVarList;
    case (localResVarList,localStartState,NONE(),localCache,localEnv) // NO ELSE-CASE    
      local
        State localStartState;
        list<Absyn.AlgorithmItem> algList,algs;
        Absyn.AlgorithmItem algItem1,algItem2;
      equation 

        algs = fromStatetoAbsynCode(localResVarList,localStartState,NONE(),localCache,localEnv,false); 
        
        //Catch handling
        /* algItem1 = Absyn.ALGORITHMITEM(Absyn.ALG_TRY(algs),NONE());
        print("Efter generateAlgorithmBlock");
        // Create catch clauses
        algs = generateCatchHandling();
        algItem2 = Absyn.ALGORITHMITEM(Absyn.ALG_CATCH(algs),NONE());
        algList = listAppend(Util.listCreate(algItem1),Util.listCreate(algItem2));
        
        algList = Util.listCreate(Absyn.ALGORITHMITEM(Absyn.ALG_WHILE(Absyn.BOOL(true),algList),NONE()));
      then algList; */
      then algs;
   // ELSE-CASE     
    case (localResVarList,localStartState,SOME(Matrix.RIGHTHANDSIDE(localVars,eqs,res)),localCache,localEnv) // AN ELSE-CASE EXIST
      local
        list<Absyn.EquationItem> eqs;
        list<Absyn.ElementItem> localVars;
        list<Absyn.AlgorithmItem> algList,algList2,algList3,bodyIf,algIf;
        Absyn.Exp res,resExpr;
        State localStartState;
        list<Absyn.Exp> expList;
      equation
        
        algList = fromStatetoAbsynCode(localResVarList,localStartState,NONE(),localCache,localEnv,true);
        
        algList2 = fromEquationsToAlgAssignments(eqs,{});
        
        // Create result assignments
        expList = createListFromExpression(res);  
        algList3 = createLastAssignments(localResVarList,expList,{});
        
        algList2 = listAppend(algList2,algList3);
           
        bodyIf = Util.listCreate(Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.CREF_IDENT("DUMMIE__",{})),
          Absyn.VALUEBLOCK(localVars,Absyn.VALUEBLOCKALGORITHMS(algList2),Absyn.BOOL(true))),NONE()));
        
        algIf = Util.listCreate(Absyn.ALGORITHMITEM(Absyn.ALG_IF(Absyn.CREF(
          Absyn.CREF_IDENT("ELSEEXISTS__",{})),bodyIf,{},{}),NONE()));
        
        algList = listAppend(algList,algIf);
      then algList; 
  end matchcontinue;
end generateAlgorithmBlock;  


public function fromStatetoAbsynCode "function: fromStatetoAbsynCode
 Takes a DFA state and recursively generates if-else nodes by investigating 
 the outgoing arcs.
"
  input list<Absyn.Exp> resVarList;  
  input State state;
  input Option<Matrix.RenamedPat> inPat;
  input Env.Cache cache;
  input Env.Env env;
  input Boolean existElse;
  output list<Absyn.AlgorithmItem> ifNodes;
algorithm
  ifNodes :=
  matchcontinue (resVarList,state,inPat,cache,env,existElse)
    local
      Stamp stamp;
      Absyn.Ident stateVar,localInStateVar;
      Matrix.RenamedPat localInPat,pat;
      Env.Cache localCache;
      Env.Env localEnv;
      list<Absyn.Exp> exp2,localResVarList;
      Integer localRetExpLen;
      Boolean localExistElse;
      // JUST FOR SURE    
    case (_,DUMMIESTATE(),_,_,_,_) equation then {};
      
      //FINAL STATE  
    case(localResVarList,STATE(stamp,_,_,SOME(Matrix.RIGHTHANDSIDE({},equations,result))),_,localCache,localEnv,localExistElse)
      local
        list<Absyn.EquationItem> equations;
        Absyn.Exp result,resVars;
        list<Absyn.AlgorithmItem> outList,body,lastAssign,elseVarAssign;
      equation 
        exp2 = createListFromExpression(result);
        
        // Create the assignments that assign the return variables
        lastAssign = createLastAssignments(localResVarList,exp2,{});
        
        body = fromEquationsToAlgAssignments(equations,{}); 
        
        elseVarAssign = elseVarAssignment(localExistElse);
        outList = elseVarAssign;
        outList = listAppend(outList,body);
        outList = listAppend(outList,lastAssign);
      then outList;
                
        //--------------
        //FINAL STATE  , there are some local declerations
    case(localResVarList,STATE(stamp,_,_,SOME(Matrix.RIGHTHANDSIDE(localList,equations,result))),_,localCache,localEnv,localExistElse)
      local
        list<Absyn.EquationItem> equations;
        list<Absyn.ElementItem> localList;
        Absyn.Exp result,vBlock,resVars;
        list<Absyn.AlgorithmItem> outList,body,lastAssign,elseVarAssign;
      equation
        exp2 = createListFromExpression(result);
    
        // Create the assignments that assign the return variables
        lastAssign = createLastAssignments(localResVarList,exp2,{});
        
        body = fromEquationsToAlgAssignments(equations,{}); 
        
        // Set the else-var to false
        elseVarAssign = elseVarAssignment(localExistElse);
        outList = elseVarAssign;
        outList = listAppend(outList,body);
        outList = listAppend(outList,lastAssign);
        
        vBlock = Absyn.VALUEBLOCK(localList,Absyn.VALUEBLOCKALGORITHMS(outList),Absyn.BOOL(true));
        outList = Util.listCreate(Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.CREF_IDENT("DUMMIE__",{})),vBlock),NONE())); 
      then outList;
        
        // THIS IS A TEST STATE, INCOMING ARC WAS AN ELSE-ARC OR THIS IS THE FIRST STATE
    case (localResVarList,STATE(stamp,_,arcs as (ARC(_,_,SOME(pat)) :: _),NONE()),NONE(),localCache,localEnv,localExistElse)    
      local
        list<Arc> arcs;
        list<Absyn.AlgorithmItem> algList;
      equation 	
        algList = generateIfElseifAndElse(localResVarList,arcs,extractPathVar(pat),true,Absyn.INTEGER(0),{},{},localCache,localEnv,localExistElse);
      then algList; 		    		    
        
        // THIS IS A TEST STATE (INCOMING ARC WAS A CONSTRUCTOR)     
    case (localResVarList,STATE(stamp,_,arcs as (ARC(_,_,SOME(pat)) :: _),NONE()),SOME(localInPat),localCache,localEnv,localExistElse)    
      local
        list<Arc> arcs;
        list<Absyn.AlgorithmItem> algList,bindings2,pathAssignList;
        list<Absyn.ElementItem> declList;
        Absyn.Exp valueBlock;
      equation 
        true = constructorOrNot(localInPat);
        
        (declList,pathAssignList) = generatePathVarDeclarations(localInPat,localCache,localEnv);
        
        algList = generateIfElseifAndElse(localResVarList,arcs,extractPathVar(pat),true,Absyn.INTEGER(0),{},{},localCache,localEnv,localExistElse);

        algList = listAppend(pathAssignList,algList);
        
        valueBlock = Absyn.VALUEBLOCK(declList,Absyn.VALUEBLOCKALGORITHMS(algList),Absyn.BOOL(true));
        algList = Util.listCreate(Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.CREF_IDENT("DUMMIE__",{})),valueBlock),NONE()));
    then algList; 
              
        //TEST STATE,THE ARC TO THIS STATE WAS NOT A CONSTRUCTOR	    
    case(localResVarList,STATE(stamp,_,arcs as (ARC(_,_,SOME(pat)) :: _),NONE()),SOME(localInPat),localCache,localEnv,localExistElse)			  	  
      local
        list<Arc> arcs;
        list<Absyn.AlgorithmItem> algList;
      equation 
        algList = generateIfElseifAndElse(localResVarList,arcs,extractPathVar(pat),true,Absyn.INTEGER(0),{},{},localCache,localEnv,localExistElse);
      then algList; 
      
  end matchcontinue;    
end fromStatetoAbsynCode;  


public function createLastAssignments "function: createLastAssignments
Creates the assignments that will assign the result variables
the final values.
(v1,v2...vN) := matchcontinue (x,y...)
                case (...) then (1,2,...N);
Here v1,v2,...,vN should be assigned the values 1,2,...N.                
"
  input list<Absyn.Exp> lhsList;
  input list<Absyn.Exp> rhsList;
  input list<Absyn.AlgorithmItem> accList;
  output list<Absyn.AlgorithmItem> outList;
algorithm
  outList :=
  matchcontinue (lhsList,rhsList,accList)
    local
      list<Absyn.AlgorithmItem> localAccList;
    case ({},{},localAccList) then localAccList;
    case (firstLhs :: restLhs,firstRhs :: restRhs,localAccList)
      local
        Absyn.Exp firstLhs,firstRhs;
        list<Absyn.Exp> restLhs,restRhs;
        Absyn.AlgorithmItem elem;
      equation
        elem = Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(firstLhs,firstRhs),NONE);
        localAccList = listAppend(localAccList,Util.listCreate(elem));
        localAccList = createLastAssignments(restLhs,restRhs,localAccList);
      then localAccList;
  end matchcontinue;        
end createLastAssignments;


public function elseVarAssignment "function: elseVarAssignment
After we have matched a complete pattern and have executed the righthand side
we assign the value false to the ELSEEXISTS__ variable so that
the else-case will not be executed
" 
  input Boolean existElse;
  output list<Absyn.AlgorithmItem> outElse;
algorithm
  outElse :=
  matchcontinue (existElse)
    case (true)
      local
        list<Absyn.AlgorithmItem> algList;
      equation
        algList = Util.listCreate(Absyn.ALGORITHMITEM(
        Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.CREF_IDENT("ELSEEXISTS__",{})),Absyn.BOOL(false)),NONE()));
      then algList;
    case (false) then {};        
  end matchcontinue;   
end elseVarAssignment;


public function generatePathVarDeclarations "function: generatePathVarDeclerations
Used when we have a record constructor call in a pattern and we need to
create path variables of the subpatterns of the record constructor.
"
  input Matrix.RenamedPat pat;
  input Env.Cache cache;
  input Env.Env env;
  output list<Absyn.ElementItem> outDecl;
  output list<Absyn.AlgorithmItem> outAssigns;
algorithm
  (outDecl,outAssigns) :=
  matchcontinue (pat,cache,env)
    local
      Env.Cache localCache;
      Env.Env localEnv;
    case (Matrix.RP_CONS(pathVar,first,second),localCache,localEnv)
      local
        Absyn.Ident pathVar;
        Matrix.RenamedPat first,second;
        list<Absyn.ElementItem> elem1,elem2;
        Absyn.Ident firstPathVar,secondPathVar;
      equation
        firstPathVar = extractPathVar(first);  
        elem1 = Util.listCreate(Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
            Absyn.TPATH(Absyn.IDENT("Integer"),NONE()),		
            {Absyn.COMPONENTITEM(Absyn.COMPONENT(firstPathVar,{},NONE()),NONE(),NONE())}),
            Absyn.INFO("f",false,0,0,0,0),NONE())));
     //   pathVar .first
        
        secondPathVar = extractPathVar(second);
        elem2 = Util.listCreate(Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
            Absyn.TPATH(Absyn.IDENT("Integer"),NONE()),		
            {Absyn.COMPONENTITEM(Absyn.COMPONENT(secondPathVar,{},NONE()),NONE(),NONE())}),
            Absyn.INFO("f",false,0,0,0,0),NONE())));
        
       // pathVar .second
        
        elem1 = listAppend(elem1,elem2);
      then (elem1,{});
    case (Matrix.RP_CALL(pathVar,Absyn.CREF_IDENT(recName,_),argList),localCache,localEnv)
      local
        Absyn.Ident pathVar,recName;
        list<Absyn.Ident> pathVarList,fieldNameList;
        list<Matrix.RenamedPat> argList;
        SCode.Class sClass;
        list<Absyn.TypeSpec> fieldTypes; 
        Absyn.Path pathName;
        list<Absyn.ElementItem> elemList;
        list<Absyn.AlgorithmItem> assignList;
      equation
        pathVarList = Util.listMap(argList,extractPathVar);
        // Get recordnames
        pathName = Absyn.IDENT(recName);
        (localCache,sClass,localEnv) = Lookup.lookupClass(localCache,localEnv,pathName,true);
        (fieldNameList,fieldTypes) = extractFieldNamesAndTypes(sClass);
        
        assignList = createPathVarAssignments(pathVar,pathVarList,fieldNameList,{});
        elemList = createPathVarDeclarations(pathVarList,fieldNameList,fieldTypes,{});
      then (elemList,assignList);	
   /* case (Matrix.RP_TUPLE(lst))	  */
  end matchcontinue;
end generatePathVarDeclarations;


public function extractFieldNamesAndTypes "function: extractFieldNamesAndTypes"
  input SCode.Class sClass;
  output list<Absyn.Ident> fieldNameList;
  output list<Absyn.TypeSpec> fieldTypes;  
algorithm
  (fieldNameList,fieldTypes) :=
  matchcontinue (sClass)
    case (SCode.CLASS(_,_,_,_,SCode.PARTS(elemList,_,_,_,_,_)))
      local
        list<Absyn.Ident> fNameList;
        list<Absyn.TypeSpec> fTypes;
        list<SCode.Element> elemList;  
      equation
        fNameList = Util.listMap(elemList,extractFieldName);
        fTypes = Util.listMap(elemList,extractFieldType);  
      then (fNameList,fTypes);
  end matchcontinue;    
end extractFieldNamesAndTypes;  


public function extractFieldName "function: extractFieldName"
  input SCode.Element elem;
  output Absyn.Ident id;  
algorithm
  id :=
  matchcontinue (elem)
    case (SCode.COMPONENT(localId,_,_,_,_,_,_,_,_,_))
      local
        Absyn.Ident localId;
      equation
      then localId;
  end matchcontinue;  
end extractFieldName;


public function extractFieldType "function: extractFieldType"
  input SCode.Element elem;
  output Absyn.TypeSpec typeSpec;  
algorithm
  typeSpec :=
  matchcontinue (elem)
    case (SCode.COMPONENT(_,_,_,_,_,_,t,_,_,_))
      local
        Absyn.TypeSpec t;
      equation
      then t;
  end matchcontinue;  
end extractFieldType;


public function createPathVarDeclarations "function: createPathVarAssignments
Used when we have a record constructor call in a pattern and we need to
create path variables of the subpatterns of the record constructor.
"
  input list<Absyn.Ident> pathVars;  
  input list<Absyn.Ident> recFieldNames;
  input list<Absyn.TypeSpec> recTypes;
  input list<Absyn.ElementItem> accElemList;
  output list<Absyn.ElementItem> elemList;
algorithm
  elemList :=
  matchcontinue (pathVars,recFieldNames,recTypes,accElemList)
    case ({},{},{},localAccElemList) 
      local
        list<Absyn.ElementItem> localAccElemList;
      equation
    then localAccElemList;
    case (firstPathVar :: restPathVars,firstFieldVar :: restFieldVars,
          firstType :: restTypes,localAccElemList)  
      local
        list<Absyn.ElementItem> elem,localAccElemList;
        Absyn.Ident localRecName,firstPathVar,firstFieldVar;
        list<Absyn.Ident> restPathVars,restFieldVars;
        Absyn.TypeSpec firstType;
        list<Absyn.TypeSpec> restTypes;  
        Absyn.Path p; 
      equation
        p = getPathFromTypeSpec(firstType);
        elem = Util.listCreate(Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
            Absyn.TPATH(p,NONE()),		
            {Absyn.COMPONENTITEM(Absyn.COMPONENT(firstPathVar,{},NONE())
            ,NONE(),NONE())}),
            Absyn.INFO("f",false,0,0,0,0),NONE())));
            
        localAccElemList = listAppend(localAccElemList,elem);
        localAccElemList = createPathVarDeclarations(restPathVars,
          restFieldVars,restTypes,localAccElemList);  
    then localAccElemList;
  end matchcontinue;   
end createPathVarDeclarations;  


public function createPathVarAssignments "function: createPathVarAssignments
Used when we have a record constructor call in a pattern and need to
bind the path variables of the subpatterns of the record constructor
to values.
"
  input Absyn.Ident recVarName;
  input list<Absyn.Ident> pathVarList;
  input list<Absyn.Ident> fieldNameList;
  input list<Absyn.AlgorithmItem> accList;
  output list<Absyn.AlgorithmItem> outList;
algorithm
  outList :=
  matchcontinue (recVarName,pathVarList,fieldNameList,accList)
    local
    list<Absyn.AlgorithmItem> localAccList;
    case (_,{},{},localAccList) then localAccList;
    case (localRecVarName,firstPathVar :: restVar,firstFieldName :: restFieldNames,
        localAccList)
      local
        Absyn.Ident localRecVarName,firstPathVar,firstFieldName;
        list<Absyn.Ident> restVar,restFieldNames;
        list<Absyn.AlgorithmItem> elem;     
      equation
        elem = Util.listCreate(Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(
          Absyn.CREF(Absyn.CREF_IDENT(firstPathVar,{})),
          Absyn.CREF(Absyn.CREF_QUAL(localRecVarName,{},
          Absyn.CREF_IDENT(firstFieldName,{})))),NONE()));

        localAccList = listAppend(localAccList,elem);
        localAccList = createPathVarAssignments(localRecVarName,restVar,restFieldNames,localAccList);        
      then localAccList;
  end matchcontinue;
end createPathVarAssignments;
  

public function generateIfElseifAndElse "function: generateIfElseifAndElse
Generate if-statements.
"
  input list<Absyn.Exp> resVarList;
  input list<Arc> arcs;
  input Absyn.Ident stateVar;
  input Boolean ifOrNotBool;
  input Absyn.Exp trueStatement;
  input list<Absyn.AlgorithmItem> trueBranch;
  input list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> elseIfBranch;
  input Env.Cache cache;
  input Env.Env env;
  input Boolean existElse;
  output list<Absyn.AlgorithmItem> outList;
algorithm
  outList :=
  matchcontinue (resVarList,arcs,stateVar,ifOrNotBool,trueStatement,trueBranch,elseIfBranch,cache,env,existElse)
    local
      State localState;
      Integer stamp;
      list<Arc> rest;
      Absyn.Ident localStateVar;
      Matrix.RenamedPat pat;
      Absyn.Exp localTrueStatement;
      list<Absyn.AlgorithmItem> localTrueBranch,localElseBranch,algList;
      list<Absyn.Exp,list<Absyn.AlgorithmItem>> localElseIfBranch;
      Env.Cache localCache;
      Env.Env localEnv;
      tuple<Absyn.Exp,list<Absyn.AlgorithmItem>> tup;
      Integer localRetExpLen;
      Boolean localExistElse;
      list<Absyn.Exp> localResVarList;
    case(_,{},_,_,localTrueStatement,localTrueBranch,localElseIfBranch,localCache,localEnv,_)
      local 
      equation 
        algList = Util.listCreate(Absyn.ALGORITHMITEM(Absyn.ALG_IF(localTrueStatement,localTrueBranch,localElseIfBranch,{}),NONE()));
      then algList;
        
        // DummieState    
    case(_,ARC(DUMMIESTATE(),_,_) :: _,_,_,localTrueStatement,localTrueBranch,localElseIfBranch,_,_,_) 
      equation
        //print("DUMMIE STATE\n");
        algList = Util.listCreate(Absyn.ALGORITHMITEM(Absyn.ALG_IF(localTrueStatement,localTrueBranch,localElseIfBranch,{}),NONE()));
      then algList;
        
        // Else case   
    case(localResVarList,ARC(localState as STATE(stamp,_,_,_),_,NONE()) :: _,localStateVar,_,localTrueStatement,localTrueBranch,localElseIfBranch,localCache,localEnv,localExistElse)
      local
      equation
        //print("else\n");
        localElseBranch = fromStatetoAbsynCode(localResVarList,localState,NONE(),localCache,localEnv,localExistElse);
        algList = Util.listCreate(Absyn.ALGORITHMITEM(Absyn.ALG_IF(localTrueStatement,localTrueBranch,localElseIfBranch,localElseBranch),NONE()));  
      then algList;
        
        //If, Wildcard case
    case(localResVarList,ARC(localState as STATE(stamp,_,_,_),_,SOME(pat as Matrix.RP_WILDCARD(_,_))) :: rest,localStateVar,true,_,_,_,localCache,localEnv,localExistElse)
      local
        Absyn.Exp exp;
      equation
        localTrueBranch = fromStatetoAbsynCode(localResVarList,localState,SOME(pat),localCache,localEnv,localExistElse);
        exp = Absyn.CREF(Absyn.CREF_IDENT("BOOLVAR__",{})); // Absyn.SUBSCRIPT(Absyn.INTEGER(stamp))
        algList = generateIfElseifAndElse(localResVarList,rest,localStateVar,false,exp,localTrueBranch,{},localCache,localEnv,localExistElse);
      then algList;
        
        //If, Cons case
    case(localResVarList,ARC(localState as STATE(stamp,_,_,_),_,SOME(pat as Matrix.RP_CONS(_,_,_))) :: rest,localStateVar,true,_,_,_,localCache,localEnv,localExistElse)
      local
        Absyn.Exp exp;
      equation
        localTrueBranch = fromStatetoAbsynCode(localResVarList,localState,SOME(pat),localCache,localEnv,localExistElse);
        exp = Absyn.LBINARY(Absyn.RELATION(Absyn.CREF(Absyn.CREF_QUAL(localStateVar,{},Absyn.CREF_IDENT("#TAG",{}))),
          Absyn.EQUAL(),Absyn.STRING("cons")),Absyn.AND(),Absyn.CREF(Absyn.CREF_IDENT("BOOLVAR__",{}))); // Absyn.SUBSCRIPT(Absyn.INTEGER(stamp))
        algList = generateIfElseifAndElse(localResVarList,rest,localStateVar,false,exp,localTrueBranch,{},localCache,localEnv,localExistElse);
      then algList;
        
        //If, CONSTANT
    case(localResVarList,ARC(localState as STATE(stamp,_,_,_),_,SOME(pat)) :: rest,localStateVar,true,_,_,_,localCache,localEnv,localExistElse)
      local
        Absyn.Exp exp,constVal,firstExp;
      equation
        
        localTrueBranch = fromStatetoAbsynCode(localResVarList,localState,SOME(pat),localCache,localEnv,localExistElse);
        constVal = getConstantValue(pat);
        firstExp = getFirstExpression(constVal,localStateVar);    
        exp = Absyn.LBINARY(firstExp,Absyn.AND(),Absyn.CREF(Absyn.CREF_IDENT("BOOLVAR__",{}))); // Absyn.SUBSCRIPT(Absyn.INTEGER(stamp))
        algList = generateIfElseifAndElse(localResVarList,rest,localStateVar,false,exp,localTrueBranch,{},localCache,localEnv,localExistElse);
      then algList;
              
        //If, CALL case
    case(localResVarList,ARC(localState as STATE(stamp,_,_,_),_,SOME(pat as Matrix.RP_CALL(_,Absyn.CREF_IDENT(recordName,_),_))) :: rest,localStateVar,true,_,_,_,localCache,localEnv,localExistElse)
      local
        Absyn.Exp exp;
        Absyn.Ident recordName;
        list<Absyn.Exp> tempList;
      equation
       localTrueBranch = fromStatetoAbsynCode(localResVarList,localState,SOME(pat),localCache,localEnv,localExistElse);

        tempList = Util.listCreate(Absyn.CREF(Absyn.CREF_IDENT(localStateVar,{})));
        exp = Absyn.LBINARY(Absyn.CALL(Absyn.CREF_IDENT("stringCmp",{}),Absyn.FUNCTIONARGS({Absyn.CALL(Absyn.CREF_IDENT("getTag",{}),Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT(localStateVar,{}))},{}))    
          ,Absyn.STRING(recordName)},{})),Absyn.AND(),Absyn.CREF(Absyn.CREF_IDENT("BOOLVAR__",{})));
        algList = generateIfElseifAndElse(localResVarList,rest,localStateVar,false,exp,localTrueBranch,{},localCache,localEnv,localExistElse);  

      then algList; 
        //Elseif, wildcard
    case(localResVarList,ARC(localState as STATE(stamp,_,_,_),_,SOME(pat as Matrix.RP_WILDCARD(_,_))) :: rest,localStateVar,false,localTrueStatement,
        localTrueBranch,localElseIfBranch,localCache,localEnv,localExistElse)
      local
        list<Absyn.AlgorithmItem> eIfBranch;
        Absyn.Exp exp;
      equation
        
        eIfBranch = fromStatetoAbsynCode(localResVarList,localState,SOME(pat),localCache,localEnv,localExistElse);
        exp = Absyn.CREF(Absyn.CREF_IDENT("BOOLVAR__",{})); // Absyn.SUBSCRIPT(Absyn.INTEGER(stamp))
        tup = (exp,eIfBranch);
        localElseIfBranch = listAppend(localElseIfBranch,Util.listCreate(tup));
        algList = generateIfElseifAndElse(localResVarList,rest,localStateVar,false,localTrueStatement,localTrueBranch,localElseIfBranch,localCache,localEnv,localExistElse);
      then algList;
        
        //Elseif, cons
    case(localResVarList,ARC(localState as STATE(stamp,_,_,_),_,SOME(pat as Matrix.RP_CONS(_,_,_))) :: rest,localStateVar,false,localTrueStatement,
        localTrueBranch,localElseIfBranch,localCache,localEnv,localExistElse)
      local
        list<Absyn.AlgorithmItem> eIfBranch;
        Absyn.Exp exp;
      equation
        eIfBranch = fromStatetoAbsynCode(localResVarList,localState,SOME(pat),localCache,localEnv,localExistElse);
        exp = Absyn.LBINARY(Absyn.RELATION(Absyn.CREF(Absyn.CREF_QUAL(localStateVar,{},Absyn.CREF_IDENT("#TAG",{}))),
          Absyn.EQUAL(),Absyn.STRING("cons")),Absyn.AND(),Absyn.CREF(Absyn.CREF_IDENT("BOOLVAR__",{})));
        tup = (exp,eIfBranch);
        localElseIfBranch = listAppend(localElseIfBranch,Util.listCreate(tup));
          algList = generateIfElseifAndElse(localResVarList,rest,localStateVar,false,localTrueStatement,localTrueBranch,localElseIfBranch,localCache,localEnv,localExistElse);
        then algList;
          
          //Elseif, call
        case(localResVarList,ARC(localState as STATE(stamp,_,_,_),_,SOME(pat as Matrix.RP_CALL(_,Absyn.CREF_IDENT(recordName,_),_))) :: rest,localStateVar,false,localTrueStatement,
            localTrueBranch,localElseIfBranch,localCache,localEnv,localExistElse)
          local
            list<Absyn.AlgorithmItem> eIfBranch;
            list<Absyn.Exp> tempList;
            Absyn.Exp exp;
            Absyn.Ident recordName;
          equation

            eIfBranch = fromStatetoAbsynCode(localResVarList,localState,SOME(pat),localCache,localEnv,localExistElse);
            tempList = Util.listCreate(Absyn.CREF(Absyn.CREF_IDENT(localStateVar,{})));
            exp = Absyn.LBINARY(Absyn.CALL(Absyn.CREF_IDENT("stringCmp",{}),Absyn.FUNCTIONARGS({
        Absyn.CALL(Absyn.CREF_IDENT("getTag",{}),Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT(localStateVar,{}))},{})),Absyn.STRING(recordName)},{})),Absyn.AND(),Absyn.CREF(Absyn.CREF_IDENT("BOOLVAR__",{})));
 
         tup = (exp,eIfBranch);
            localElseIfBranch = listAppend(localElseIfBranch,Util.listCreate(tup));
            algList = generateIfElseifAndElse(localResVarList,rest,localStateVar,false,localTrueStatement,localTrueBranch,localElseIfBranch,localCache,localEnv,localExistElse);
          then algList;
          
         
          //Elseif, constant
        case(localResVarList,ARC(localState as STATE(stamp,_,_,_),_,SOME(pat)) :: rest,localStateVar,false,localTrueStatement,
            localTrueBranch,localElseIfBranch,localCache,localEnv,localExistElse)
          local
            list<Absyn.AlgorithmItem> eIfBranch;
            Absyn.Exp exp,constVal,firstExp;
          equation

            constVal = getConstantValue(pat);
            eIfBranch = fromStatetoAbsynCode(localResVarList,localState,SOME(pat),localCache,localEnv,localExistElse);
            firstExp = getFirstExpression(constVal,localStateVar);
            exp = Absyn.LBINARY(firstExp,Absyn.AND(),Absyn.CREF(Absyn.CREF_IDENT("BOOLVAR__",{}))); // Absyn.SUBSCRIPT(Absyn.INTEGER(stamp))
            tup = (exp,eIfBranch);
            localElseIfBranch = listAppend(localElseIfBranch,Util.listCreate(tup));
            algList = generateIfElseifAndElse(localResVarList,rest,localStateVar,false,localTrueStatement,localTrueBranch,localElseIfBranch,localCache,localEnv,localExistElse);
          then algList; 
            
  end matchcontinue;    
end generateIfElseifAndElse;


public function getFirstExpression "function: getFirstExpression
Used by generateIfElseifAndElse
when we want two write an expression for comparing constants
"
  input Absyn.Exp constVal;
  input Absyn.Ident stateVar;  
  output Absyn.Exp outExp;  
algorithm  
  outExp :=
  matchcontinue (constVal,stateVar)
    local
      Integer i;
      Real r;
      String s;
      Boolean b;  
      Absyn.Exp exp;
      Absyn.Ident localStateVar;
    case (Absyn.INTEGER(i),localStateVar)
      equation
      exp = Absyn.RELATION(Absyn.CREF(Absyn.CREF_IDENT(localStateVar,{})),
        Absyn.EQUAL(),Absyn.INTEGER(i));
      then exp;  
    case (Absyn.REAL(r),localStateVar)
      equation
        exp = Absyn.CALL(Absyn.CREF_IDENT("stringCmp",{}),
          Absyn.FUNCTIONARGS({Absyn.CALL(Absyn.CREF_IDENT("String",{}),
          Absyn.FUNCTIONARGS({Absyn.REAL(r),Absyn.INTEGER(5)},{}))
            ,Absyn.CALL(Absyn.CREF_IDENT("String",{}),
          Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT(localStateVar,{})),Absyn.INTEGER(5)},{}))},{}));
      then exp;  
    case (Absyn.STRING(s),localStateVar)
      equation
        exp = Absyn.CALL(Absyn.CREF_IDENT("stringCmp",{}),
        Absyn.FUNCTIONARGS({Absyn.STRING(s),Absyn.CREF(Absyn.CREF_IDENT(localStateVar,{}))},{}));
      then exp;
    case (Absyn.BOOL(b),localStateVar)
      equation
      exp = Absyn.RELATION(Absyn.CREF(Absyn.CREF_IDENT(localStateVar,{})),
        Absyn.EQUAL(),Absyn.BOOL(b));
      then exp;  
 end matchcontinue;   
end getFirstExpression;  


public function fromEquationsToAlgAssignments "function: fromEquationsToAlgAssignments
 Convert equations to algorithm assignments"
  input list<Absyn.EquationItem> eqsIn;
  input list<Absyn.AlgorithmItem> accList;
  output list<Absyn.AlgorithmItem> algsOut;
algorithm
  algOut :=
  matchcontinue (eqsIn,accList)
    local
      list<Absyn.AlgorithmItem> localAccList;  
    case ({},localAccList) equation then localAccList;
    case (Absyn.EQUATIONITEM(first,_) :: rest,localAccList)      
      local
        Absyn.Equation first;
        list<Absyn.EquationItem> rest;
        Absyn.AlgorithmItem firstAlg;
        list<Absyn.AlgorithmItem> restAlgs;
      equation    
        firstAlg = fromEquationToAlgAssignment(first);
        localAccList = listAppend(localAccList,Util.listCreate(firstAlg));
        restAlgs = fromEquationsToAlgAssignments(rest,localAccList);    
      then restAlgs;  
  end matchcontinue;
end fromEquationsToAlgAssignments;

public function fromEquationToAlgAssignment "function: fromEquationToAlgAssignment"
  input Absyn.Equation eq;
  output Absyn.AlgorithmItem algStatement;
algorithm
  algStatement :=
  matchcontinue (eq)
    case (Absyn.EQ_EQUALS(left,right))    
      local
        Absyn.Exp left,right;
        Absyn.AlgorithmItem algItem;
      equation
        algItem = Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(left,right),NONE());  	
      then algItem;
  end matchcontinue;
end fromEquationToAlgAssignment;


//---------------------------------------------------

/*
 public function generateStateLists
 input State state;
 input list<Absyn.Exp> accStamps;
 output Absyn.Exp outStamps;
 algorithm
 outStamps :=
 matchcontinue (state,accStamps)
 local
 Absyn.Exp ret;  
 case (DUMMIESTATE(),localAccStamps)
 equation 
 ret = Absyn.ARRAY(localAccStamps);  
 then ret;
 case (STATE(_,_,_,SOME(_)),localAccStamps)
 equation
 localAccStamps = listAppend(localAccStamps,Absyn.ARRAY({}));
 ret = Absyn.ARRAY(localAccStamps);  
 then ret;   
 case (STATE(_,_,{},_),localAccStamps)
 equation
 localAccStamps = listAppend(localAccStamps,Absyn.ARRAY({}));
 ret = Absyn.ARRAY(localAccStamps);  
 then ret;
 case (STATE(stamp,_,arcs,_),localAccStamps)
 local
 list<Absyn.Exp> stampList;
 list<Absyn.Exp> intList;
 Stamp stamp;
 list<Arc> arcs;
 equation
 intList = getStateStamps(arcs,{});
 localAccStamps = listAppend(localAccStamps,Util.listCreate(Absyn.ARRAY(intList)));
 stampList = generateFromArcs(arcs,{});
 stampList = listAppend(localAccStamps,stampList); 
 ret = Absyn.ARRAY(stampList);  
 then ret;
 end matchcontinue;
 end generateStateLists;
 
 public function generateFromArcs
 input list<Arc> arcList;
 input list<Absyn.Exp> accStampList;
 output list<Absyn.Exp> outStampList;
 algorithm
 outStampList :=
 matchcontinue (arcList,accStampList)
 local
 State state;
 list<Arc> rest;  
 list<Absyn.Exp> localAccStampList,ret,stampList;
 case ({},localAccStampList) equation then localAccStampList;
 case (ARC(state,_,_,_) :: rest,localAccStampList)
 local
 list<Absyn.Exp> stampList;
 equation
 stampList = generateStateLists(state,{});  
 localAccStampList = listAppend(localAccStampList,stampList);
 ret = generateFromArcs(rest,localAccStampList);
 then ret;
 end matchcontinue;  
 end generateFromArcs;
 
 public function getStateStamps
 input list<Arc> arcList;
 input list<Absyn.Exp> accList;
 output list<Absyn.Exp> outList;
 algorithm
 outList :=
 matchcontinue (arcList,accList)
 local
 list<Absyn.Exp> localAccList,ret;  
 case ({},localAccList) equation then localAccList;
 case (ARC(DUMMIESTATE(),_,_,_) :: _,localAccList) equation then localAccList;  
 case (ARC(STATE(stamp,_,_,_),_,_,_) :: rest,localAccList)
 local
 Stamp stamp;
 list<Arc> rest;
 Absyn.Exp stampExp;
 equation
 stampExp = Absyn.INTEGER(stamp);
 localAccList = listAppend(localAccList,Util.listCreate(stampExp));
 ret = getStateStamps(rest,localAccList); 
 then ret;
 end matchcontinue;     
 end getStateStamps;
 */

public function createListFromExpression "function: createListFromExpression"
  input Absyn.Exp exp;
  output list<Absyn.Exp> outList;
algorithm
  outList :=
  matchcontinue (exp)
    local
      list<Absyn.Exp> l;  
      Absyn.Exp e;
    case(Absyn.TUPLE(l)) then l;
    case (e) 
      equation 
        l = Util.listCreate(e); 
      then l;
  end matchcontinue;
end createListFromExpression;


public function generateCatchHandling "function: generatCatchHandling
Not used right now
"
  output list<Absyn.AlgorithmItem> outAlgs;
algorithm  
  outAlgs := 
  matchcontinue ()
    local
      list<Absyn.AlgorithmItem> alg,algs; 
    case ()         
      // We have the following data structures:
      // stack - containing the states visited before the exception interupt
      // boolVar - contains one boolean variable for each state (is it possible to visit this state) 
      // neighborStates - contains one entry for each state, the entry is made up of all the states this
      //                  state leads to
      // The scheme for marking already visited paths works as follows:
      //print("\n //Catch handling\n");
      //print("Integer oldState;\n");
      //print("Integer currentState = 0; \n");
      /*
       alg = Absyn.ALG_WHILE();
       
       //print("while (!stack.empty()) \n");
        //print("currentState := stack.pop(); \n");
         //print("tempArr := neighborStates[currentState];\n");
          //print("if (arrayLength(tempArr) < 1) then \n");
           //print("boolVar[currentState] := false;\n");
            //print("else if (arrayLength(tempArr) == 1) \n");
             //print("boolVar[currentState] := false;\n");
              //print("neighborStates[currentState] := INTEGER[0]; \n");
               //print("else \n");
                //print("neighborStates[currentState] := arrayRemove(tempArr,oldState);\n");
                 //print("break; \n");
                  //print("end if;\n");
                   //print("oldState := currentState;\n");
                    //print("end while; \n");
                     //print("stack.clear();\n");
                      
                      Absyn.WHILE();
                      Absyn.ALG_ASSIGN();
                      Absyn.IF();
                      Absyn.BREAK();
                      Absyn.CALL();
                      outAlgs := algs;
                      */
      equation
        algs = {};
      then algs; 
  end matchcontinue;
end generateCatchHandling;


public function boolString "function:: boolString"
  input Boolean bool;
  output String str;
algorithm
  str :=
  matchcontinue (bool)
    case (true) equation then "true";
    case (false) equation then "false";
  end matchcontinue;       
end boolString;

public function getConstantValue "function: getConstantValue"
  input Matrix.RenamedPat pat;
  output Absyn.Exp val;
algorithm
  val :=
  matchcontinue (pat)
    case (Matrix.RP_INTEGER(_,val))
      local
        Integer val;
      equation
      then Absyn.INTEGER(val); 
    case (Matrix.RP_STRING(_,val))
      local
        String val;
      equation
      then Absyn.STRING(val);
    case (Matrix.RP_BOOL(_,val))
      local
        Boolean val;
      equation
      then Absyn.BOOL(val);
    case (Matrix.RP_REAL(_,val))
      local
        Real val;
      equation
      then Absyn.REAL(val);       
  end matchcontinue;  
end getConstantValue;

public function extractPathVar "function: extractPathVar"
  input Matrix.RenamedPat pat;
  output Absyn.Ident pathVar;
algorithm
  pathVar :=
  matchcontinue (pat)
    local
      Absyn.Ident localPathVar;
    case (Matrix.RP_INTEGER(localPathVar,_)) equation then localPathVar;
    case (Matrix.RP_REAL(localPathVar,_)) equation then localPathVar;
    case (Matrix.RP_BOOL(localPathVar,_)) equation then localPathVar;
    case (Matrix.RP_STRING(localPathVar,_)) equation then localPathVar;
    case (Matrix.RP_CONS(localPathVar,_,_)) equation then localPathVar;
    case (Matrix.RP_CALL(localPathVar,_,_)) equation then localPathVar;
    case (Matrix.RP_TUPLE(localPathVar,_)) equation then localPathVar;
    case (Matrix.RP_WILDCARD(localPathVar,_)) equation then localPathVar;    
  end matchcontinue;    
end extractPathVar;

public function constructorOrNot "function: constructorOrNot"
  input Matrix.RenamedPat pat;
  output Boolean val;
algorithm
  val :=
  matchcontinue (pat)
    case (Matrix.RP_CONS(_,_,_))
      equation
      then true;
    case (Matrix.RP_TUPLE(_,_))
      equation
      then true;
    case (Matrix.RP_CALL(_,_,_))
      equation
      then true;
    case (_)
      equation
      then false;
  end matchcontinue;    
end constructorOrNot;

public function getPathFromTypeSpec "Function: getPathFromTypeSpec"
  input Absyn.TypeSpec tSpec;
  output Absyn.Path outPath;
algorithm
  outPath :=  
  matchcontinue (tSpec)
    local
      Absyn.Path p;  
    case (Absyn.TPATH(p,_)) then p;
    case (Absyn.TCOMPLEX(p,_,_)) then p;
  end matchcontinue;
end getPathFromTypeSpec;

end DFA;