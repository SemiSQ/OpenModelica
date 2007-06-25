package Patternm  "
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

  
  file:	 Patternm.mo
  module:      Patternm
  description: Patternmatching
 
  RCS: $$
  
  This module contains the patternmatch algorithm for the MetaModelica
  matchcontinue expression.
 "
  
public import Matrix;
public import Absyn;
public import DFA;
public import Env;
public import SCode;

protected import Lookup;
protected import Util;
//protected import Debug; 
//protected import Dump;

//Some type simplifications
type RenamedPat = Matrix.RenamedPat;
type RenamedPatVec = Matrix.RenamedPatVec;
type RenamedPatList = list<Matrix.RenamedPat>; 
type RenamedPatMatrix = Matrix.RenamedPatMatrix;  
type RenamedPatMatrix2 = Matrix.RenamedPatMatrix2;  
type RightHandVector = Matrix.RightHandVector;
type RightHandList = Matrix.RightHandList;  
type RightHandSide = Matrix.RightHandSide;
type IndexVector = Matrix.IndexVector;  
type AsList = list<Absyn.EquationItem>;
type AsArray = AsList[:];  
type ArcName = Absyn.Ident;


protected function ASTtoMatrixForm "function: ASTtoMatrixForm
	author: KS	
 	Transforms the Abstract Syntax Tree of a matchcontinue expression into matrix form.
 	The patterns in each case-branch ends up in a matrix and all the right-hand sides
 	ends up in a list/vector. The match algorithm uses these data structures when 
 	when generating the DFA. A right-hand side is simply the code occuring after
	the case keyword: local Integer i; ... equation ... then 3*3;
"
  input Absyn.Exp matchCont; // The matchcontinue expression
  input Env.Cache cache; // The renameMain function will need these two 
  input Env.Env env; // when transforming named arguments in a function call into positional once
  output Env.Cache outCache; 
  output list<Absyn.Exp> outVarList; // The input variables (in exp form), matchcontinue (var1,var2,var3,...) 
  output list<Absyn.ElementItem> outDeclList; // The local declarations, matchcontinue (...) local Integer i; Real r; ... case() ...
  output RightHandVector rhVec; // The righthand side vector 
  output RenamedPatMatrix pMat; // The matrix with renamed patterns (renaming means adding a path variable to each pattern)
  output Option<RightHandSide> outElseRhSide; // An optional else case
algorithm
  (outCache,outVarList,outDeclList,rhVec,pMat,outElseRhSide) :=
  matchcontinue (matchCont,cache,env)
    case (localMatchCont as (Absyn.MATCHEXP(_,varList2,declList,localCases,_)),localCache,localEnv)
      local
        Absyn.Exp localMatchCont;
        RightHandList rhsList;
        list<Absyn.Exp> patList,varList;
        Absyn.Exp varList2; // The input variables to the matchcontinue expression
        RenamedPatMatrix patMat;
        list<Absyn.ElementItem> declList; // The local variable declarations at the begining of the matchc. exp
        Integer varListLength; 
        Option<RightHandSide> elseRhSide; // Used to store the optional else-case of the match. exp
        AsArray asBindings; // Array used for the as constructs, case (var as 3,...)
        list<Absyn.Case> localCases;
        Env.Cache localCache;
        Env.Env localEnv;
      equation
        // Extract from matchcontinue AST       
        (rhsList,patList,elseRhSide) = extractFromMatchAST(localCases,{},{});
        varList = extractListFromTuple(varList2);
        varListLength = listLength(varList);
        
        false = (varListLength == 0); // If there are no input variables, the function will fail
        
        // Create patternmatrix. The as-bindings (  ... case (var1 as 3) ...)
        // are first collected in the fillMatrix function and then 
        // assignments of these variables are added to the RightHandSide list
        patMat = fill({},varListLength);
        asBindings = fill({},listLength(rhsList));   
        (localCache,patMat,asBindings) = 
        fillMatrix(1,asBindings,varList,patList,patMat,localCache,localEnv); 
        rhsList = addAsBindings(rhsList,arrayList(asBindings));	 // Add the as-bindings (assignments) collected 
                                                                 // to the right hand-sides.
        //true = patternCheck(arrayList(patMat));
        
      then (localCache,varList,declList,listArray(rhsList),patMat,elseRhSide);
    case (exp,_,_) local Absyn.Exp exp;  
      equation 
        // Debug.fprint("failtrace", "- ASTtoMatrixForm failed, non-matching patterns in matchcase or zero input variables\n");
       // Debug.fcall("failtrace", Dump.printExp, exp);  
      then fail();
  end matchcontinue; 
end ASTtoMatrixForm;


protected function extractListFromTuple "function: extractListFromTuple
	author: KS	
 Given an Absyn.Exp, this function will extract the list of expressions if the
 expression is a tuple, otherwise a list of length one is created"
  input Absyn.Exp inExp;
  output list<Absyn.Exp> outList;
algorithm
  outList :=
  matchcontinue (inExp)
    case(Absyn.TUPLE(l))
      local 
        list<Absyn.Exp> l;
      equation 
      then l;  
    case(exp)
      local 
        Absyn.Exp exp;
      equation
      then Util.listCreate(exp);    
  end matchcontinue;
end extractListFromTuple;


protected function addAsBindings "function: addAsBindings
	author: KS
	This function will add all the collected as-bindings to a list of
	right-hand sides. A right-hand side is simply the code occuring after
	the case keyword: local Integar i; ... equation ... then 3*3;
	As-binding example:
	v := matchcontinue (inInteger)
  	   case (v2 as 4) local Integer v2; equation ... then 2;
  	   ...
	end matchcontinue;
	A new assignment, v2 = pathVariable, will be added to the equation 
	section. Remember that each pattern has a corresponding path variable.
"
  input RightHandList rhList;
  input list<AsList> asBinds;
  output RightHandList outRhs;
algorithm
  outRhs :=
  matchcontinue (rhList,asBinds)
    case ({},{}) equation then {};
    case (first1 :: rest1,first2 :: rest2) 
      local
        RightHandSide first1;
        RightHandList rest1,rhsList;
        AsList first2;
        list<AsList> rest2;
      equation	
        first1 = addAsBindingsHelper(first1,first2);
        rhsList = addAsBindings(rest1,rest2);
        rhsList = listAppend(Util.listCreate(first1),rhsList);
      then rhsList;
  end matchcontinue;
end addAsBindings; 

protected function addAsBindingsHelper "function: addAsBindingsHelper
	author: KS
	Helper function to addAsBindings"
  input RightHandSide rhSide;
  input AsList asList;
  output RightHandSide rhSideOut;
algorithm
  rhSideOut :=
  matchcontinue (rhSide,asList)
    case (localRhSide,{})
      local
        RightHandSide localRhSide;    
      equation 
      then localRhSide;  
    case (Matrix.RIGHTHANDSIDE(localDecls,eqs,result),localAsList)
      local
        list<Absyn.ElementItem> localDecls;
        list<Absyn.EquationItem> eqs;
        Absyn.Exp result;
        RightHandSide rhS;
        AsList localAsList;
      equation 
        eqs = listAppend(localAsList,eqs);  
        rhS = Matrix.RIGHTHANDSIDE(localDecls,eqs,result);  
      then rhS;        
  end matchcontinue;
end addAsBindingsHelper;


protected function extractFromMatchAST "function: extractFromMatchAST
	author: KS	
	Extract righthand sides, patterns and optional else-case from matchcontinue
	AST.
"
  input list<Absyn.Case> matchCases;
  input RightHandList rhListIn;
  input list<Absyn.Exp> patListIn; // All the patterns are collected in a list.
  output RightHandList rhListOut;
  output list<Absyn.Exp> patListOut; // All the patterns are collected in a list.
  output Option<RightHandSide> elseRhSide; // A matchcontinue expression may contain an else-case
algorithm
  (rhListOut,patListOut,elseRhSide) :=
  matchcontinue (matchCases,rhListIn,patListIn)
    local
      list<Absyn.Case> rest;
      Absyn.Exp localPat,localRes;
      list<Absyn.ElementItem> localDecl;
      list<Absyn.EquationItem> localEq;
      
      // var1,var2,var3 are temp variables
      list<Absyn.Exp> localPatListIn,var2;
      RightHandList localRhListIn,var1;
      Option<RightHandSide> var3;       
    case ({},localRhListIn,localPatListIn) equation then (localRhListIn,localPatListIn,NONE());
    case (Absyn.CASE(localPat,localDecl,localEq,localRes,_) :: rest,localRhListIn,localPatListIn)
      equation
        localPatListIn = listAppend(localPatListIn,localPat :: {});
        localRhListIn = listAppend(localRhListIn,Matrix.RIGHTHANDSIDE(localDecl,localEq,localRes) :: {});   
        (var1,var2,var3) = extractFromMatchAST(rest,localRhListIn,localPatListIn);
      then (var1,var2,var3);
    case (Absyn.ELSE(localDecl,localEq,localRes,_) :: {},localRhListIn,localPatListIn)
      equation
      then (localRhListIn,localPatListIn,SOME(Matrix.RIGHTHANDSIDE(localDecl,localEq,localRes)));      	        
  end matchcontinue;
end extractFromMatchAST;


protected function fillMatrix "function: fillMatrix
	author: KS
	Fill the matrix with renamed patterns (patterns of the form path=pattern, where
	path is a path-variable and pattern is a renamed expression)
"
  input Integer rowNum;
  input AsArray inAsBindings; // List/vector used for the as-construct in Absyn.Exp
  input list<Absyn.Exp> varList; // The matchcontinue input variable list
  input list<Absyn.Exp> patList; // The unrenamed patterns, no path variable added yet
  input RenamedPatMatrix patMat; // The matrix containg the renamed patterns
  input Env.Cache cache;
  input Env.Env env; 
  output Env.Cache outCache;
  output RenamedPatMatrix outPatMat; 
  output AsArray outAsBindings;
algorithm
  (outCache,outPatMat,outAsBindings) := 
  matchcontinue (rowNum,inAsBindings,varList,patList,patMat,cache,env)
    local
      RenamedPatMatrix localPatMat;
      Absyn.Exp first2;
      list<Absyn.Exp> first,rest,localVarList;
      AsArray localAsBindings;
      Integer localRowNum;
    case (_,localAsBindings,_,{},localPatMat,localCache,_)  
      local  
        Env.Cache localCache; 
      equation 
      then (localCache,localPatMat,localAsBindings);    
    case (localRowNum,localAsBindings,localVarList,first2 :: rest,
        localPatMat,localCache,localEnv)
      local
        AsList asBinds;
        Integer len1,len2;
        //Temp variables
        RenamedPatMatrix temp2;
        AsArray temp4;
        
        Env.Env localEnv;
        Env.Cache localCache;
      equation  
        first = extractListFromTuple(first2);
        
        // Add a row to the matrix, rename each pattern as well
        (localCache,localPatMat,asBinds) = addRow({},localVarList,1,first,localPatMat,localCache,localEnv);
        
        len1 = listLength(first);  
        len2 = listLength(localVarList);
        true = (len1 == len2); // The number of input variables, matchcontinue (var1,var2,...), must be
                               // the same as the number of patterns in each case
        
        // Store As-construct bindings for this row
        localAsBindings = arrayUpdate(localAsBindings, localRowNum, asBinds);
        
        // Add the rest of the rows to the matrix	  
        (localCache,temp2,temp4) =
        fillMatrix(localRowNum+1,localAsBindings,localVarList,rest,localPatMat,
          localCache,localEnv);   	
      then (localCache,temp2,temp4);  
    case (_,_,_,e :: _,_,_,_)  local Absyn.Exp e; 
      equation
       // Debug.fprint("failtrace", "- fillMatrix failed, wrong number of patterns in case?\n");
      //  Debug.fcall("failtrace", Dump.printExp, e);  
      then fail();
  end matchcontinue;
end fillMatrix;

protected function addRow "function: addRow 
	author: KS
 	Adds a row to the matrix.
 	This is done by adding one element at a time to the matrix row
"
  input AsList asBindings; // Used to store AS construct bindings
  input list<Absyn.Exp> varList; // Input variable list
  input Integer pivot; // Position in the row
  input list<Absyn.Exp> pats; // The patterns to be stored in the row
  input RenamedPatMatrix patMat;
  input Env.Cache cache;
  input Env.Env env;  
  output Env.Cache outCache;
  output RenamedPatMatrix outPatMat; 
  output AsList outAsBinds;
algorithm
  (outCache,outPatMat,outAsBinds) :=
  matchcontinue (asBindings,varList,pivot,pats,patMat,cache,env)
    local
      Integer localPivot;
      Absyn.Exp firstPat;
      list<Absyn.Exp> restPat,restVar;
      RenamedPatMatrix localPatMat;
      Absyn.Ident firstVar;
      list<Absyn.Ident,Absyn.Ident> localVars;
      Integer localRowNum;
      AsList localAsBindings;
      Env.Cache localCache;
      Env.Env localEnv;
    case (localAsBindings,_,_,{},localPatMat,localCache,_) 
      equation 
      then (localCache,localPatMat,localAsBindings);
    case(localAsBindings,Absyn.CREF(Absyn.CREF_IDENT(firstVar,{})) :: restVar,localPivot,firstPat :: restPat,
        localPatMat,localCache,localEnv)     
      local
        RenamedPat pat;
        list<Absyn.Ident> localPathVars2;
        AsList asBinds;
        String str;
        
        //Temp variables
        RenamedPatMatrix temp2;
        AsList temp4;
        RenamedPatList temp5;
      equation 
        str = "";
        
        //Rename a pattern, that is transform it into path=pattern form
        (localCache,pat,asBinds) = 
        renameMain(firstPat,stringAppend(str,firstVar),{},localCache,localEnv);  	
        localAsBindings = listAppend(localAsBindings,asBinds);       
         
         // Store new element in matrix
        temp5 = listAppend(localPatMat[localPivot],pat :: {});        
        localPatMat = arrayUpdate(localPatMat, localPivot, temp5);
        
        //Add the rest of the elements for this row
        (localCache,temp2,temp4) = addRow(localAsBindings,restVar,localPivot+1,restPat,
        localPatMat,localCache,localEnv); 					         
      then (localCache,temp2,temp4);   
  end matchcontinue;  
end addRow;


protected function renameMain "function: renameMain
 	author: KS
 	Input is an Absyn.Exp (corresponding to a pattern) and a root variable. 
 	The function transforms the pattern into path=pattern form (Matrix.RenamedPat). 
 	As a side effect we also collect the As-bindings.
"
  input Absyn.Exp pat;
  input Absyn.Ident rootVar;
  input AsList inAsBinds;
  input Env.Cache cache;
  input Env.Env env;  
  output Env.Cache outCache;
  output RenamedPat renamedPat;
  output AsList outAsBinds; // New as bindings are added in the as-pattern case
algorithm
  (outCache,renamedPat,outAsBinds) :=
  matchcontinue (pat,rootVar,inAsBinds,cache,env)
    local
      Absyn.Exp localPat;
      Absyn.Ident localVar;
      list<Absyn.Ident,Absyn.Ident> localVars;
      AsList localAsBinds,localAsBinds2;
      Env.Cache localCache;
      Env.Env localEnv;
      // INTEGER EXPRESSION  
    case (Absyn.INTEGER(val),localVar,localAsBinds,localCache,_)  
      local 
        Integer val;
        RenamedPat tempPat;   
      equation
        tempPat = Matrix.RP_INTEGER(localVar,val);
      then (localCache,tempPat,localAsBinds);
        // REAL EXPRESSION
    case (Absyn.REAL(val),localVar,localAsBinds,localCache,_)
      local
        Real val;
        RenamedPat tempPat;   
      equation
        tempPat = Matrix.RP_REAL(localVar,val); 
      then (localCache,tempPat,localAsBinds);
        // BOOLEAN EXPRESSION
    case (Absyn.BOOL(val),localVar,localAsBinds,localCache,_)
      local 
        Boolean val;
        RenamedPat tempPat;   
      equation
        tempPat = Matrix.RP_BOOL(localVar,val); 
      then (localCache,tempPat,localAsBinds);
        // WILDCARD EXPRESSION
    case (Absyn.CREF(Absyn.WILD()),localVar,localAsBinds,localCache,_)
      local 
        RenamedPat tempPat;   
      equation
        tempPat = Matrix.RP_WILDCARD(localVar); 
      then (localCache,tempPat,localAsBinds);
        // STRING EXPRESSION    
    case (Absyn.STRING(val),localVar,localAsBinds,localCache,_)
      local 
        String val;
        RenamedPat pat;   
      equation
        pat = Matrix.RP_STRING(localVar,val);
      then (localCache,pat,localAsBinds);
        // AS BINDINGS        
        // An as-binding is collected as an equation assignment. This assigment will later be
        // added to the correspond righthand side.
    case (Absyn.AS(var,expr),localVar,localAsBinds,localCache,localEnv)
      local
        Absyn.Exp expr;
        Absyn.Ident var;
        
        // Temp variables
        RenamedPat temp1;
        AsList temp3;
      equation     
        localAsBinds2 = Util.listCreate(Absyn.EQUATIONITEM(Absyn.EQ_EQUALS(Absyn.CREF(Absyn.CREF_IDENT(var,{})),
          Absyn.CREF(Absyn.CREF_IDENT(localVar,{}))),NONE()));
        localAsBinds = listAppend(localAsBinds,localAsBinds2);
        
        (localCache,temp1,temp3) = renameMain(expr,localVar,localAsBinds,localCache,localEnv);        	    
      then (localCache,temp1,temp3);        
        
        // COMPONENT REFERENCE EXPRESSION
        // Will be interpretated as: case (var AS _)
        // This expression is transformed into a wildcard but we store the variable
        // reference as well as an AS-binding.
    case (Absyn.CREF(Absyn.CREF_IDENT(var,_)),localVar,localAsBinds,localCache,_)
      local 
        Absyn.Ident var;   
        RenamedPat pat;
      equation
        localAsBinds2 = Util.listCreate(Absyn.EQUATIONITEM(Absyn.EQ_EQUALS(Absyn.CREF(Absyn.CREF_IDENT(var,{})),
          Absyn.CREF(Absyn.CREF_IDENT(localVar,{}))),NONE()));
        localAsBinds = listAppend(localAsBinds,localAsBinds2);
          
        pat = Matrix.RP_WILDCARD(localVar);
      then (localCache,pat,localAsBinds);
        
        // TUPLE EXPRESSION
        // This is a builtin functioncall, all the function arguments are renamed       
    case (Absyn.TUPLE(funcArgs),localVar,localAsBinds,localCache,localEnv)
      local
        Absyn.ComponentRef compRef;
        list<Absyn.Exp> funcArgs,funcArgs2;	  
        RenamedPatList renamedPatList;
        RenamedPat pat;
        AsList localAsBinds2;
      equation
        (localCache,renamedPatList,localAsBinds2) = renamePatList(funcArgs
          ,localVar,1,{},{},localCache,localEnv);
        pat = Matrix.RP_TUPLE(localVar,renamedPatList);
        
      then (localCache,pat,listAppend(localAsBinds,localAsBinds2));
        
        // CONS EXPRESSION
        // This is a builtin functioncall, all the function arguments are renamed
    case (Absyn.CONS(first,second),localVar,localAsBinds,localCache,localEnv)
      local
        Absyn.Exp first,second;	  
        RenamedPatList renamedPatList;
        list<Absyn.Ident> paths;  
        RenamedPat pat,first2,second2;
        AsList localAsBinds2;
      equation
        (localCache,renamedPatList,localAsBinds2) = renamePatList({first,second}
          ,localVar,1,{},{},localCache,localEnv);
        first2 = Util.listFirst(renamedPatList);
        second2 = Util.listFirst(Util.listRest(renamedPatList));
        
        pat = Matrix.RP_CONS(localVar,first2,second2);
        
      then (localCache,pat,listAppend(localAsBinds,localAsBinds2));   
        // CALL EXPRESSION
        // This is a builtin functioncall, all the function arguments are renamed
        // We also must transform named function arguments into positional function 
        // arguments.
    case (Absyn.CALL(compRef,Absyn.FUNCTIONARGS(funcArgs,{})),localVar,localAsBinds,localCache,localEnv)
      local
        Absyn.ComponentRef compRef;
        list<Absyn.Exp> funcArgs;	  
        RenamedPatList renamedPatList; 
        RenamedPat pat;
        AsList localAsBinds2;
      equation
        (localCache,renamedPatList,localAsBinds2) = renamePatList(funcArgs
          ,localVar,1,{},{},localCache,localEnv);
        pat = Matrix.RP_CALL(localVar,compRef,renamedPatList);
        
      then (localCache,pat,listAppend(localAsBinds,localAsBinds2));
        // CALL EXPRESSION
    case (Absyn.CALL(compRef as Absyn.CREF_IDENT(recName,{}),Absyn.FUNCTIONARGS({},namedArgList)),localVar,localAsBinds,localCache,localEnv)
      local
        Absyn.ComponentRef compRef;
        list<Absyn.NamedArg> namedArgList;	  
        RenamedPatList renamedPatList;
        RenamedPat pat;
        AsList localAsBinds2;
        Absyn.Ident recName;
        SCode.Class sClass;
        Absyn.Path pathName;
        list<Absyn.Ident> fieldNameList;
        list<Absyn.Exp> funcArgs;
      equation
        
        // Fetch the names of the fields
        pathName = Absyn.IDENT(recName);
        (localCache,sClass,_) = Lookup.lookupClass(localCache,localEnv,pathName,true);
        (fieldNameList,_) = DFA.extractFieldNamesAndTypes(sClass);
        
        //Sorting of named arguments
        funcArgs = generatePositionalArgs(fieldNameList,namedArgList,{});
        
        (localCache,renamedPatList,localAsBinds2) = renamePatList(funcArgs
          ,localVar,1,{},{},localCache,localEnv);
        pat = Matrix.RP_CALL(localVar,compRef,renamedPatList);
        
      then (localCache,pat,listAppend(localAsBinds,localAsBinds2));    
        // EMPTY LIST EXPRESSION
    case (Absyn.ARRAY({}),localVar,localAsBinds,localCache,_)
      local  
        RenamedPat pat;
      equation
        pat = Matrix.RP_EMPTYLIST(localVar);
      then (localCache,pat,localAsBinds);    
    case (e,_,_,_,_)  local Absyn.Exp e; 
      equation
      //  Debug.fprint("failtrace", "- renameMain failed, unvalid pattern\n");
      //  Debug.fcall("failtrace", Dump.printExp, e);  
      then fail();   
  end matchcontinue;	     
end renameMain;

protected function renamePatList "function: renamePatList
	author: KS
 	Rename the subpatterns in a constructor call one after another.
	Input is a list of patterns to remain.
	 The pivot integer is used for naming purposes.
"
  input list<Absyn.Exp> patList;
  input Absyn.Ident var;
  input Integer pivot;
  input list<RenamedPat> accRenamedPatList;
  input AsList asBindings;
  input Env.Cache cache;
  input Env.Env env; 
  output Env.Cache outCache;
  output list<RenamedPat> renamedPatList;
  output AsList outAsBindings;
algorithm
  (outCache,renamedPatList,outAsBindings) :=
  matchcontinue (patList,var,pivot,accRenamedPatList,asBindings,cache,env)
    local
      list<RenamedPat> localAccRenamedPatList;
      AsList localAsBindings;
      Env.Cache localCache;
      Env.Env localEnv;
    case ({},_,_,localAccRenamedPatList,localAsBindings,localCache,_) 
      equation then (localCache,localAccRenamedPatList,localAsBindings);
    case (first :: rest,localVar,localPivot,localAccRenamedPatList,localAsBindings,
      localCache,localEnv)
      local
        Absyn.Exp first;
        list<Absyn.Exp> rest;
        Absyn.Ident localVar;
        Integer localPivot;
        RenamedPat localRenamedPat;
        AsList localAsBindings2;
        RenamedPatList temp1;
        list<Absyn.Exp> pathVars;
        AsList temp3;
        Absyn.Ident str;
        String tempStr;
      equation
        tempStr = stringAppend("__",intString(localPivot));     
        //Rename first pattern
        (localCache,localRenamedPat,localAsBindings2) = 
        renameMain(first,stringAppend(localVar,tempStr),{},localCache,localEnv);
        
      	str = stringAppend(localVar,tempStr);

      	localAccRenamedPatList = listAppend(localAccRenamedPatList,localRenamedPat :: {});
      	(localCache,temp1,temp3) = renamePatList(rest,localVar,localPivot+1,
        	localAccRenamedPatList,
        	listAppend(localAsBindings,localAsBindings2),localCache,localEnv);
      	then (localCache,temp1,temp3);
  end matchcontinue;
end renamePatList;

protected function generateIdentifiers "function: generateIdentifiers
	author: KS
 	Generate pathvariables for a function call given a root variable.
	Given x we get x__1,x__2,x__3 ...
"
  input Absyn.Ident varName;
  input Integer num; // The number of variable references to be generated
  input Integer pivot;
  output list<Absyn.Ident> outList;
algorithm
  outList :=
  matchcontinue (varName,num,pivot)
    case (_,0,_) equation then {};
    case (localVarName,localNum,localPivot)
      local
        Absyn.Ident localVarName;
        Integer localNum,localPivot;
        list<Absyn.Ident> temp2;
        String temp1,tempStr;
      equation
        tempStr = stringAppend("__",intString(localPivot));
        temp1 = stringAppend(localVarName,tempStr);
        temp2 = generateIdentifiers(localVarName,localNum-1,localPivot+1);
      then listAppend(temp1 :: {},temp2);
  end matchcontinue;  
end generateIdentifiers;

//-----------------------------------------------------------------------

public function matchMain "function: matchMain
	author: KS
 	The main function for the patternmatch algorithm.
 	Calls the ASTtoMatrixForm function for the generation of the pattern
	matrix. Then calls matchFuncHelper for the generation of the DFA
"
  input Absyn.Exp matchCont;
  input list<Absyn.Exp> resultVarList; // These is a list of lhs component refs, (var1,var2,...) = matchcontinue (...) ...
  input Env.Cache cache;
  input Env.Env env; 
  output Env.Cache outCache;
  output Absyn.Exp outExpr; // The final valueblock with nested if-else-elseif statements
algorithm
  (outCache,outExpr) := 
  matchcontinue (matchCont,resultVarList,cache,env)
    case (localMatchCont,localResultVarList,localCache,localEnv)  
      local
        RightHandVector rhVec;
        RenamedPatMatrix patMat;
        list<Absyn.ElementItem> declList;
        list<Absyn.Exp> localResultVarList,inputVarList;
        Option<RightHandSide> elseRhSide;
        Integer stampTemp;
        DFA.State dfaState;
        DFA.Dfa dfaRec;
        Absyn.Exp localMatchCont,expr;
        RenamedPatMatrix2 patMat2;
        Env.Cache localCache;
        Env.Env localEnv;
      equation	
        // Get the pattern matrix, etc.
        (localCache,inputVarList,declList,rhVec,patMat,elseRhSide) = ASTtoMatrixForm(localMatchCont,localCache,localEnv);
        patMat2 = arrayList(patMat);
        
        // A small fix.
        patMat2 = Matrix.matrixFix(patMat2);      
        
        //Matrix.printMatrix(patMat2);
        
        // Start the pattern matching
        (dfaState,stampTemp) = matchFuncHelper(patMat2,arrayList(rhVec),DFA.STATE(1,0,{},NONE()),1);
        //print("Done with the matching");
        dfaRec = DFA.DFArec(declList,{},NONE(),dfaState,stampTemp);
        
        // Transform the DFA into a valueblock with nested if-elseif-else statements.
        (localCache,expr) = DFA.fromDFAtoIfNodes(dfaRec,inputVarList,localResultVarList,localCache,localEnv);
      then (localCache,expr); 
    case (exp,_,_,_)   
      local  
        Absyn.Exp exp;   
      equation
      //  Debug.fprint("failtrace", "- matchMain failed\n");
      //  Debug.fcall("failtrace", Dump.printExp, exp);     
      then fail();
  end matchcontinue;	      
end matchMain;

/*
 The match algorithm:
 We can have tree types of patterns: wildcards, constructors and constants (may also sometimes be viewed
 as constructors with zero arguments).
 
 Case 1:
 All of the top-most patterns consists of wildcards. The leftmost wildcard is used to create an arc.
 Match is invoked on a new state with what is left of the upper row. An else arc is created, Match
 is invoked on a new state with the rest of the matrix with the upper-row removed.
 
 Case 2:
 The top-most column consists of wildcards and constants. Select the left-most column with a constant
 at the uppermost position. 
 If this is the only column in the matrix do the following:
 		Create a new arc with the constant and a new final state. Create an else branch and a new state and
 		invoke match on this new state with what is left of the column. We have to do it this way because we
 		do not won't to loose any right-hand sides (since fail-continue may be implemented). 
 Otherwise: Create an arc and state for each constant and constructor in the same way as case 3. For all
 		the wildcards we create a new arc and state.
 
 Case 3:
 There exists a column whose top-most pattern is a constructor. Select the left-most column containing
 a constructor. We will create a new arc for each constructor c in this column. So for each constructor c:
 Select the rows that match c (wildcards included). Extract the subpatterns, create a new
 arc and state and invoke match on what is left on the matrix appended with the extracted subpatterns.
 
 If this is the only column in the matrix do the following:
 		Create an else arc and a new arc. Invoke match on the matrix consisting of the wildcards and constants.
 		
 Otherwise: create an arc and state for each constant as well, in the same way as for the constructors.
 		Create a new arc and state for all the wildcards. 
 */


protected function matchFuncHelper "function: matchFuncHelper
	author: KS
 	This function is called recursively. It picks out a column and starts the pattern matching. 
 	See above.
"
  input RenamedPatMatrix2 patMat;
  input RightHandList rhList;
  input DFA.State currentState;
  input Integer stampCounter; // Each state will be given a stamp
  output DFA.State outState; 
  output Integer outStampCounter;
algorithm   
  (outState,outStampCounter) :=
  matchcontinue (patMat,rhList,currentState,stampCounter)
    case ({},{},_,localCnt) // Empty pattern matrix
      local
        Integer localCnt;
      equation
        //print("MatchFuncHelper: Two empty lists\n");
      then (DFA.DUMMIESTATE(),localCnt-1); // The dummie states will simply be discarded 
                                           // when if-statements are created.
    case ({{}},{},_,localCnt) // Empty pattern matrix
      local
        Integer localCnt;
      equation
        //print("MatchFuncHelper: Two empty lists\n");
      then (DFA.DUMMIESTATE(),localCnt-1);
        
        // FINAL STATE	        
    case ({},localRhList,_,localCnt) // Empty pattern matrix but one 
      // element in the righthand side list.
      // This means that we should create a final state.
      local 
        RightHandSide rhSide;
        Integer localCnt;
        RightHandList localRhList; 
      equation 
        rhSide = Util.listFirst(localRhList);
      then (DFA.STATE(localCnt,0,{},SOME(rhSide)),localCnt);
        // CASE 1 - ALL WILDCARDS at the top-most matrix row -----------------------
    case (localPatMat,localRhList,localState,localCnt) 
      local
        RenamedPatMatrix2 localPatMat,tempMat;
        RightHandList localRhList;
        DFA.State localState,newState;
        Integer localCnt;
        RenamedPatList firstPatRow;
        RightHandSide v1;
        RenamedPat pat;
        Absyn.Ident arcName;
      equation
        firstPatRow = Matrix.firstRow(localPatMat,{});
        true = allWildcards(firstPatRow); // Check to see if all are wildcards, note that variables are 
                                          // classified as wildcards as well                                    
        localCnt = localCnt + 1;                                       
        newState = DFA.STATE(localCnt,0,{},NONE());
        
        // Start with first column (and the first row).
        v1 = Util.listFirst(localRhList);
        tempMat = Util.listMap(Util.listRest(firstPatRow),Util.listCreate);
        (newState,localCnt) = matchFuncHelper(tempMat,{v1},newState,localCnt);
        
        //Add a wildcard arc    
        pat = Util.listFirst(firstPatRow);
        arcName = "Wildcard";
        localState = DFA.addNewArc(localState,arcName,newState,SOME(pat));
        
        tempMat = Matrix.removeFirstRow(localPatMat,{});
        
        localCnt = localCnt + 1;
        newState = DFA.STATE(localCnt,0,{},NONE());
        
        // Match the rest of the matrix with first row removed
        (newState,localCnt) = matchFuncHelper(tempMat
          ,Util.listRest(localRhList),newState,localCnt);  
        
        // Add an else arc for the result of the matching of the
        // rest of the matrix with the first row removed
        arcName = "else";
        localState = DFA.addNewArc(localState,arcName,newState,NONE());
      then (localState,localCnt);		 	
        //CASE 3 --- THERE EXIST AT LEAST ONE CONSTRUCTOR at the top-most row of the matrix --------------      	
    case (localPatMat,localRhList,localState,localCnt)
      local
        RenamedPatMatrix2 localPatMat;
        RightHandList localRhList;
        DFA.State localState;
        Integer localCnt; 
      equation
        // check to see if there exist a constructor
        true = existConstructor(Matrix.firstRow(localPatMat,{})); 
        
        // Dispatch to a separate function
        (localState,localCnt) = matchCase3(localPatMat,localRhList,localState,localCnt);
      then (localState,localCnt);	  
        
        // CASE 2 - NO CONSTRUCTORS BUT NOT ALL WILDCARDS	at the top-most row of the matrix    		    
    case (localPatMat,localRhList,localState,localCnt) 
      local
        RenamedPatList tempPatL;
        RenamedPatMatrix2 localPatMat;
        RightHandList localRhList;
        DFA.State localState,newState;
        Integer localCnt;
        RenamedPat pat;
        ArcName arcName;
      equation 
        true = (listLength(localPatMat) == 1); //ONLY ONE COLUMN IN THE MATRIX
        // THE TOP ELEMENT MUST BE A CONSTANT
        
        // Match first element 
        localCnt = localCnt + 1;
        newState = DFA.STATE(localCnt,0,{},NONE());
        (newState,localCnt) = matchFuncHelper({},
          Util.listCreate(Util.listFirst(localRhList)),newState,localCnt);
        
        pat = Util.listFirst(Util.listFirst(localPatMat));
        // Add new arc with first element
        arcName = getConstantName(pat);
        localState = DFA.addNewArc(localState,arcName
          ,newState,SOME(pat));	    	 	  
        
        // Match the rest of the column
        tempPatL = Util.listFirst(localPatMat);	    	 	
        localCnt = localCnt + 1;
        newState = DFA.STATE(localCnt,0,{},NONE());
        (newState,localCnt) = matchFuncHelper(Util.listCreate(Util.listRest(tempPatL)),
          Util.listRest(localRhList),newState,localCnt);  
        
        // Add a new arc with rest of column
        arcName= "else";
        localState = DFA.addNewArc(localState,arcName,newState,NONE());
      then (localState,localCnt);
        
        // CASE 2 - NO CONSTRUCTORS BUT NOT ALL WILDCARDS	at the top-most row of the matrix	     		  
    case (localPatMat,localRhList,localState,localCnt) 
      local
        Integer ind,localCnt; 
        RenamedPatList firstR;
        RenamedPatMatrix2 localPatMat;
        RightHandList localRhList;
        DFA.State localState;
        RenamedPat pat;
      equation
        
        firstR = Matrix.firstRow(localPatMat,{});
        ind = findFirstConstant(firstR,1); // Find the left-most column containing a constant
        // Add an arc for each constant
        (localState,localCnt) = addNewArcForEachC(localState,
          ind,localPatMat,localRhList,localCnt);
        
        // Add one arc for all the wildcards
        (localState,localCnt) = addNewArcForWildcards(localState,
          ind,localPatMat,localRhList,localCnt); 
      then (localState,localCnt);
  end matchcontinue;
end matchFuncHelper;


protected function matchCase3 "function: matchCase3
	author: KS
	Case 3, there exist at least one constructor in the top-most row. Helper function
	to matchFuncHelper.
"
  input RenamedPatMatrix2 patMat;
  input RightHandList rhList;
  input DFA.State currentState;
  input Integer stampCounter;
  output DFA.State finalState;
  output Integer outStamp;
algorithm
  (finalState,outStamp) :=
  matchcontinue (patMat,rhList,currentState,stampCounter)
    case (localPatMat,localRhList,localState,localCnt)
      local
        RenamedPatMatrix2 localPatMat;
        RightHandList localRhList;
        DFA.State localState,newState;    
        Integer localCnt,ind; 
        list<Absyn.Ident,Boolean> listOfConstructors;
        IndexVector indVec;
        RenamedPatList tempList;
        RenamedPat pat;
        ArcName arcName;
      equation
        true = (listLength(localPatMat) == 1); // One column in the matrix
        // Get the names of the constructors in the column
        tempList = Util.listFirst(localPatMat);
        listOfConstructors = findConstructors(tempList,{});
        
        // Get the indices of the consts and wildcards
        indVec = findConstAndWildcards(tempList,{},1);
        
        // Add a new arc for each constructor
        (localState,localCnt) = addNewArcForEachCHelper(listOfConstructors,localState,
          1,localPatMat,localRhList,localCnt);
        
        localCnt = localCnt + 1;
        newState = DFA.STATE(localCnt,0,{},NONE());
        
        // Add a new arc for the constants and wildcards 	    	
        (newState,localCnt) = createUnionState(indVec,tempList,
          localRhList,localCnt,newState,true);  
        arcName = "else";
        localState = DFA.addNewArc(localState,arcName,newState,NONE());
      then (localState,localCnt);
        // MORE THAN ONE COLUMN IN THE MATRIX
    case (localPatMat,localRhList,localState,localCnt)
      local 
        RenamedPatMatrix2 localPatMat;
        RightHandList localRhList;
        DFA.State localState;    
        Integer localCnt,ind;
        RenamedPat pat;
        RenamedPatList patList;
      equation
        patList = Matrix.firstRow(localPatMat,{});
        
        // Find the left-most column containing a constructor
        ind = findFirstConstructor(patList,1);
        
        // Add a new arc for each constant and constructor
        (localState,localCnt) = addNewArcForEachC(localState,ind,localPatMat,localRhList,localCnt);
        
        // Add a new arc for all the wildcards (combined)
        (localState,localCnt) = addNewArcForWildcards(localState,ind,localPatMat,localRhList,localCnt);
      then (localState,localCnt);    
  end matchcontinue;
end matchCase3;


protected function findConstAndWildcards "function: findConstAndWildcards
	author: KS	
	Get the indices of all the const and wildcards from a pattern list.
"
  input RenamedPatList inList;
  input IndexVector accList;
  input Integer pivot;
  output IndexVector outVec;
algorithm
  outVec :=
  matchcontinue (inList,accList,localPivot)
    local
      Matrix.IndexVector localAccList;
      Integer localPivot;
    case ({},localAccList,localPivot) equation then localAccList;
    case (first :: rest,localAccList,localPivot)
      local
        RenamedPat first;
        RenamedPatList rest;
        IndexVector localAcclist;
        Integer localPivot;
      equation
        true = (wildcardOrNot(first) or constantOrNot(first));
        localAccList = listAppend(localAccList,{localPivot});  
      then findConstAndWildcards(rest,localAccList,localPivot+1);
    case (_ :: rest,localAccList,localPivot)
      local
        RenamedPatList rest;
        IndexVector localAcclist;
        Integer localPivot;       
      equation 
      then findConstAndWildcards(rest,localAccList,localPivot+1);             
  end matchcontinue;    
end findConstAndWildcards;

protected function findFirstConstant "function: findFirstConstant
	author: KS
	Find the index number of the first column containing a constant.
"
  input RenamedPatList patList;
  input Integer ind;
  output Integer outInd;
algorithm
  patList :=
  matchcontinue (patList,ind)
    local
      Integer localInd;
      RenamedPat first;
      RenamedPatList rest;
    case (first :: rest,localInd)
      equation
        true = constantOrNot(first);
      then localInd;
    case (_ :: rest,localInd) equation then findFirstConstant(rest,localInd+1); 
  end matchcontinue;
end findFirstConstant;


protected function findFirstConstructor "function: findFirstConstructor
	author: KS
	Find the index number of the first column containing a constructor.
"
  input RenamedPatList patList;
  input Integer ind;
  output Integer outInd;
algorithm
  patList :=
  matchcontinue (patList,ind)
    local
      RenamedPat first;
      RenamedPatList rest;
      Integer localInd;
    case (first :: rest,localInd)
      equation
        true = constructorOrNot(first);
      then localInd;
    case (_ :: rest,localInd) equation then findFirstConstructor(rest,localInd+1); 
  end matchcontinue;
end findFirstConstructor; 


protected function createUnionState "function: createUnionState
	author: KS	
	This functions takes a list of patterns, an index vector with indices 
	to wildcard and constant patterns in the list of patterns and 
	then creates a new state with arcs for these patterns. This function
	is used in for instance the following case:
	v := matchcontinue(x)
	  case (_) then A1;
  	case (1) then A2;
  	case (_) then A3;
		case (1) then A4;
		case (3) then A5;
		...
		end matchcontinue;
	Even though we have for instance two wildcards in the above example, we can not
	merge these two into one arc since we need to keep both righ-hand sides A1 and A3.
"
  input IndexVector indVec;
  input RenamedPatList patList;
  input RightHandList rhList;
  input Integer stampCnt;
  input DFA.State state;
  input Boolean firstTime;
  output DFA.State outState;
  output Integer outStamp;
algorithm
  (outstate,outStamp) := 
  matchcontinue (indVec,patList,rhList,stampCnt,state,firstTime)
    case ({},_,_,localCnt,_,true) 
      local
        Integer localCnt;	    
      equation 
      then (DFA.DUMMIESTATE(),localCnt-1);
    case ({},_,_,localCnt,localState,_) 
      local
        Integer localCnt;
        DFA.State localState;	    
      equation 
      then (localState,localCnt);
        
        // Wildcard	       
    case (first :: rest,localPatList,localRhList,localCnt,localState,_)
      local
        RenamedPat pat;
        RightHandSide rhSide;
        Integer first,localCnt;
        IndexVector rest;
        RenamedPatList localPatList;
        RightHandList localRhList;
        DFA.State localState,newState;
      equation
        pat = arrayGet(listArray(localPatList),first);
        true = wildcardOrNot(pat);
        rhSide = arrayGet(listArray(localRhList),first);
        localCnt = localCnt + 1;
        newState = DFA.STATE(localCnt,0,{},SOME(rhSide));
        
        localState = DFA.addNewArc(localState,"Wildcard",newState,SOME(pat));
        (localState,localCnt) = createUnionState(rest,localPatList,localRhList,localCnt,localState,false);
      then (localState,localCnt);     
        
        // Constant	
    case (first :: rest,localPatList,localRhList,localCnt,localState,_)
      local
        RenamedPat pat;
        RightHandSide rhSide;
        Integer first,localCnt;
        IndexVector rest;
        RenamedPatList localPatList;
        RightHandList localRhList;
        DFA.State localState,newState;
        ArcName arcName; 
      equation
        pat = arrayGet(listArray(localPatList),first);
        rhSide = arrayGet(listArray(localRhList),first);
        localCnt = localCnt + 1;
        newState = DFA.STATE(localCnt,0,{},SOME(rhSide));
        arcName = getConstantName(pat);
        localState = DFA.addNewArc(localState,arcName,newState,SOME(pat));
        (localState,localCnt) = createUnionState(rest,localPatList,localRhList,localCnt,localState,false);
      then (localState,localCnt);
  end matchcontinue;      
end createUnionState; 


protected function findConstructors "function: findConstructors
	author: KS	
	This function finds the constructors in a renamed pattern list. 
	The boolean tells wheter it is a constructor (true) or constant (false).
	The functions addNewArcForEachC and addNewArcForEachCHelper makes use of
	this boolean.
"
  input RenamedPatList patList;
  input list<Absyn.Ident,Boolean> accList;
  output list<Absyn.Ident,Boolean> outList;
algorithm
  outList :=
  matchcontinue (patList,accList)
    local
      list<Absyn.Ident,Boolean> localAccList;
    case ({},localAccList) equation then localAccList;
    case (first :: rest,localAccList)
      local
        Absyn.Ident constructorName;
        RenamedPatList rest;
        RenamedPat first;
        list<Absyn.Ident,Boolean> temp;
      equation
        true = (constructorOrNot(first));
        constructorName = getConstructorName(first);
        temp = {(constructorName,true)};
        false = listMember(Util.listFirst(temp),localAccList);
      then findConstructors(rest,listAppend(localAccList,temp));  
    case (_ :: rest,localAccList)
      local
        RenamedPatList rest;
      equation  
      then findConstructors(rest,localAccList);
  end matchcontinue;
end findConstructors;

protected function getConstructorName "function: getConstrucorName	
	author: KS
"
  input RenamedPat constPat;
  output Absyn.Ident name; 
algorithm
  name :=
  matchcontinue (constPat)
    case Matrix.RP_CONS(_,_,_) equation then "CONS";
    case Matrix.RP_TUPLE(_,_) equation then "TUPLE";  
    case Matrix.RP_CALL(_,Absyn.CREF_IDENT(val,_),_) 
    local 
      Absyn.Ident val;
      equation then val;  
  end matchcontinue;     	
end getConstructorName;

protected function getConstantName "function: getConstantName
	author: KS
"
  input RenamedPat constPat;
  output Absyn.Ident name; 
algorithm
  name :=
  matchcontinue (constPat)
    case Matrix.RP_INTEGER(_,val)
    local Integer val; 
      equation then intString(val);
    case Matrix.RP_REAL(_,val)
    local Real val; 
      equation then realString(val); 
    case Matrix.RP_BOOL(_,val)
    local Boolean val; 
      String str;
      equation 
        str = DFA.boolString(val);
      then str;              	        
    case Matrix.RP_STRING(_,val) 
    local 
      String val;
      equation then val;   
    case Matrix.RP_EMPTYLIST(_) then "EmptyList";    
  end matchcontinue;     	
end getConstantName;


protected function addNewArcForWildcards "function: addNewArcForWildcards
	author: KS
 	Used in the case there is more than one column in the matrix.
 	This functions adds one wildcard arc to a new state.
	 Function used in the following case:
 	var := matchcontinue (x,y)
      case (_,...)
      case (3,...)
      case (_,...)
	A new arc is added for all the wildcards in a column.
	(the pattern matrix must have more than one column).
"
  input DFA.State state;
  input Integer ind;
  input RenamedPatMatrix2 patMat;
  input RightHandList rhList;
  input Integer stampCnt;
  output DFA.State finalState;
  output Integer outCnt;
algorithm
  (finalState,outCnt) := 
  matchcontinue (state,ind,patMat,rhList,stampCnt)
    case (localState,localInd,localPatMat,localRhList,localCnt)    
      local
        IndexVector indVec;
        DFA.State localState,newState;
        Integer localInd,localCnt;
        RenamedPatMatrix2 localPatMat,matTemp;
        RightHandList localRhList;
        RenamedPatList listTemp;
        Absyn.Ident var;
        ArcName arcName;
      equation
        listTemp = arrayGet(listArray(localPatMat),localInd);
        indVec = findMatches("Wildcard",listTemp,{},1);
        
        //NO WILDCARDS
        false = (listLength(indVec) == 0);
        
        localCnt = localCnt + 1;
        newState = DFA.STATE(localCnt,0,{},NONE());
        matTemp = arrayList(Matrix.patternsFromOtherCol(listArray(localPatMat),indVec,localInd));
        
        (newState,localCnt) = matchFuncHelper(matTemp,
          selectRightHandSides(indVec,listArray(localRhList),{}),newState,localCnt);
            
        var = DFA.extractPathVar(arrayGet(listArray(listTemp),Util.listFirst(indVec)));   
        arcName = "Wildcard"; 
        localState = DFA.addNewArc(localState,arcName,newState,SOME(Matrix.RP_WILDCARD(var)));
      then (localState,localCnt);
    case (localState,_,_,_,localCnt) 
      local
        DFA.State localState;
        Integer localCnt;
      equation
      then (localState,localCnt);  		  
  end matchcontinue;
end addNewArcForWildcards;


protected function addNewArcForEachC "function: addNewArcForEachC
	author: KS
 	Adds a new arc for each constant and constructor
 	Assumes that the matrix has more than one column
"
  input DFA.State state;
  input Integer ind;
  input RenamedPatMatrix2 patMat;
  input RightHandList rhList;
  input Integer cnt;
  output DFA.State finalState;
  output Integer outCnt;
algorithm
  (finalState,outCnt) :=
  matchcontinue (state,ind,patMat,rhList,cnt)
    case (localState,localInd,localPatMat,localRhList,localCnt)
      local
        DFA.State localState;
        Integer localInd,localCnt;
        RenamedPatMatrix2 localPatMat;
        RightHandList localRhList;
        list<Absyn.Ident,Boolean> listOfC; // The boolean tells wheter it is a constant or constructor
        RenamedPatList listTemp;
      equation
        listTemp = arrayGet(listArray(localPatMat),localInd);
        listOfC = getNamesOfCs(listTemp,{});
        
        (localState,localCnt) = addNewArcForEachCHelper(listOfC,localState,localInd,
          localPatMat,localRhList,localCnt);
      then (localState,localCnt);
  end matchcontinue;
end addNewArcForEachC;


protected function getNamesOfCs "function: getNamesOfCs
	author: KS
	Retrieve the names of all constants and constructs in a matrix column.
 	Each name is stored with a boolean indicating wheter it is constructor or not.
"
  input RenamedPatList patList;
  input list<Absyn.Ident,Boolean> accList;
  output list<Absyn.Ident,Boolean> outList;
algorithm
  outList :=
  matchcontinue (patList,accList)
    local
      list<Absyn.Ident,Boolean> localAccList;
    case ({},localAccList) equation then localAccList;
    case (first :: rest,localAccList) 
      local
        RenamedPat first;
        RenamedPatList rest;
        list<Absyn.Ident,Boolean> temp;
      equation
        true = constructorOrNot(first);
        temp = Util.listCreate((getConstructorName(first),true));
        false = listMember(Util.listFirst(temp),localAccList);
      then getNamesOfCs(rest,listAppend(localAccList,temp));  
    case (first :: rest,localAccList) 
      local  
        RenamedPat first;
        RenamedPatList rest;
        list<Absyn.Ident,Boolean> temp;
      equation
        true = constantOrNot(first);
        temp = Util.listCreate((getConstantName(first),false));
        false = listMember(Util.listFirst(temp),localAccList);
      then getNamesOfCs(rest,listAppend(localAccList,temp));
    case (_ :: rest,localAccList) local
      RenamedPatList rest;
      equation
      then getNamesOfCs(rest,localAccList);
  end matchcontinue;
end getNamesOfCs;


protected function addNewArcForEachCHelper "function: addNewArcForEachCHelper
	author: KS
	Add a new arc for each constructor or constant given a list with names of these.
	Example: 
	matchcontinue (var) 
		case ({}) 
		case (2 :: {})
		case (3 :: {})
		case (_)
  The first pattern is a constant (empty list) and then we have two constructors (cons).
	The input listOfC should have length 2: {EMPTYLIST,CONS}. 
	We start with the EMPTYLIST identifer and then search the column (given by input variable ind)
	for all the patterns containing an empty list (case 1 and case 4). Then we
	do the same with the CONS identifer (case 2,3 and 4 matches).
	For a constant we create a new arc and then call matchFucnHelper on extracted
	patterns from all other columns in the matrix.
	For a constructor we have to extract subpatterns from the constructor call as well. 
"
  input list<Absyn.Ident,Boolean> listOfC;
  input DFA.State state;
  input Integer ind;
  input RenamedPatMatrix2 patMat;
  input RightHandList rhList;
  input Integer stampCnt;
  output DFA.State finalState;
  output Integer outCnt;
algorithm
  (finalState,outCnt) :=
  matchcontinue (listOfC,state,ind,patMat,rhList,stampCnt)
    local
      list<Absyn.Ident,Boolean> rest;
      DFA.State localState,newState;
      Integer localInd,localCnt;
      RenamedPatMatrix2 localPatMat;
      RightHandList localRhList;
    case ({},localState,_,_,_,localCnt) equation then (localState,localCnt);
      
      // CONSTANT      
    case ((first,false) :: rest,localState,localInd,localPatMat,localRhList,localCnt) //Constant 
      local
        Absyn.Ident first;
        Boolean second;
        IndexVector indVec;
        RenamedPatList tempList;
        RenamedPatMatrix2 tempMat;
        DFA.State newState;
        RenamedPat pat;
        Integer ind;
        ArcName arcName;
      equation    
        tempList = arrayGet(listArray(localPatMat),localInd);
        
        indVec = findMatches(first,tempList,{},1); // Find all the matching patterns
        
        localCnt = localCnt + 1;
        newState = DFA.STATE(localCnt,0,{},NONE());
        
        tempMat = arrayList(Matrix.patternsFromOtherCol(listArray(localPatMat),indVec,localInd));
        
        // Match the rest of the matrix
        (newState,localCnt) = matchFuncHelper(tempMat,selectRightHandSides(indVec,listArray(localRhList),{}),newState,localCnt);
        
        // Add a new arc for the constant
        ind = Util.listFirst(indVec);
        pat = arrayGet(listArray(tempList),ind);
        arcName = first;
        localState = DFA.addNewArc(localState,arcName,newState,SOME(pat));
        
        // Add more arcs for the other constants/constructors in the column
        (localState,localCnt) = addNewArcForEachCHelper(rest,
          localState,localInd,localPatMat,localRhList,localCnt);  
      then (localState,localCnt);
        
        // CONSTRUCTOR
    case ((first,second) :: rest,localState,localInd,localPatMat,localRhList,localCnt) 
      local
        Absyn.Ident first;
        Boolean second;
        Integer ind;
        IndexVector indVec;
        RenamedPatMatrix2 extractedPats,mat;
        RenamedPatMatrix extractedPats2;
        list<Absyn.Ident> varList;
        RenamedPatList patList;
        Absyn.Ident constructorName;
        list<Absyn.Ident,Boolean> rest;
        RightHandList newRhL;
        RenamedPat pat;
        ArcName arcName;
      equation
        patList = arrayGet(listArray(localPatMat),localInd);
        constructorName = first;
        indVec = findMatches(constructorName,patList,{},1);
        
        varList = extractPathVariables(indVec,listArray(patList));  		 
        
        //Extract the new matrix from the constructor calls
        extractedPats2 = fill({},listLength(varList));
        extractedPats = arrayList(extractSubpatterns(varList,indVec,patList,extractedPats2));
        
        mat = arrayList(Matrix.patternsFromOtherCol(listArray(localPatMat),
          indVec,localInd));
        
        mat = Matrix.appendMatrices(mat,extractedPats);
        
        newRhL = selectRightHandSides(indVec,listArray(localRhList),{});
        localCnt = localCnt + 1;
        newState = DFA.STATE(localCnt,0,{},NONE());
        
        // Match the matrix with the subpatterns (from the constructor call) 
        // appended to the rest of the matrix
        (newState,localCnt) = matchFuncHelper(mat,newRhL,newState,localCnt);
        
        ind = Util.listFirst(indVec);
        pat = arrayGet(listArray(patList),ind);
        pat = simplifyPattern(pat,varList);
        arcName = constructorName;
        localState = DFA.addNewArc(localState,arcName,newState,SOME(pat)); 
        (localState,localCnt) = addNewArcForEachCHelper(rest,localState,localInd,
          localPatMat,localRhList,localCnt);  			
      then (localState,localCnt); 
  end matchcontinue;
end addNewArcForEachCHelper;


protected function simplifyPattern "function: simplifyPattern
	author: KS
	This function takes a constructor pattern and transforms all the
	subpatterns into wildcards. Only the path variables are left, we
	need these names later on.
"
  input RenamedPat pat;
  input list<Absyn.Ident> varList;
  output RenamedPat outPat;
algorithm
  outPat :=
  matchcontinue (pat,varList)
    local
      list<Absyn.Ident> localVarList;
    case (Matrix.RP_CONS(pathVar,_,_),localVarList)
      local
        RenamedPat consPat,first,second;
        Absyn.Ident pathVar;
        RenamedPatList wcList;  
      equation
        wcList = generateWildcardList(localVarList,{});  
        second = Util.listFirst(Util.listRest(wcList));
        first = Util.listFirst(wcList);
        consPat = Matrix.RP_CONS(pathVar,first,second);
      then consPat;
    case (Matrix.RP_TUPLE(pathVar,_),localVarList)
      local
        RenamedPat tuplePat;
        Absyn.Ident pathVar;
        RenamedPatList wcList;
      equation
        wcList = generateWildcardList(localVarList,{}); 
        tuplePat = Matrix.RP_TUPLE(pathVar,wcList);
      then tuplePat;
    case (Matrix.RP_CALL(pathVar,callName,_),localVarList)      
      local
        Absyn.Ident pathVar;
        Absyn.ComponentRef callName;
        RenamedPat callPat;
        RenamedPatList wcList;
      equation
        wcList = generateWildcardList(localVarList,{});  
        callPat = Matrix.RP_CALL(pathVar,callName,wcList);
      then callPat;
  end matchcontinue;
end simplifyPattern;

protected function generateWildcardList "function: generateWildcardList
	author: KS
	Helper function to simplifyPattern
"
  input list<Absyn.Ident> varList;
  input RenamedPatList patList;
  output RenamedPatList outPatList;
algorithm
  outPatList :=
  matchcontinue (varList,patList)
    local
      RenamedPatList localPatList;    
    case ({},localPatList) equation then localPatList;
    case (first :: rest,localPatList)
      local
        Absyn.Ident first;
        list<Absyn.Ident> rest;
      equation
        localPatList = listAppend(localPatList,Util.listCreate(Matrix.RP_WILDCARD(first)));
      then generateWildcardList(rest,localPatList);
  end matchcontinue;
end generateWildcardList;


protected function extractPathVariables "function: extractPathVariables
	author: KS
	Find the first construct given an IndexVector and extract the path variables.
"
  input IndexVector indList;
  input RenamedPatVec renamedPatVec;
  output list<Absyn.Ident> outPathVars;
algorithm
  outPathVars :=
  matchcontinue (indList,renamedPatVec)
    local
      Integer first;
      IndexVector rest;
      RenamedPatVec localRenamedPatVec;
    case ({},_) equation then {};  
    case (first :: rest,localRenamedPatVec) 
      equation
        true = wildcardOrNot(arrayGet(localRenamedPatVec,first));
      then extractPathVariables(rest,localRenamedPatVec);			
    case (first :: _,localRenamedPatVec) 
      local
        list<Absyn.Ident> varList;
      equation
        varList = getPathVarsFromConstruct(arrayGet(localRenamedPatVec,first));
      then varList;
  end matchcontinue;    
end extractPathVariables;


protected function getPathVarsFromConstruct "function: getPathVarsFromConstruct
	author: KS
	Given a construct, extract a list of the path variables.
"
  input RenamedPat pat;
  output list<Absyn.Ident> outVarList;
algorithm
  outVarList :=
  matchcontinue (pat)
    case Matrix.RP_TUPLE(pathVar,l)
    local
      Absyn.Ident pathVar;
      list<Absyn.Ident> tempList;
      Matrix.RenamedPatList l;
      equation
        tempList = generateIdentifiers(pathVar,listLength(l),1);
      then tempList;
    case Matrix.RP_CONS(pathVar,_,_)
    local
      Absyn.Ident pathVar;
      list<Absyn.Ident> tempList;
      equation
        tempList = generateIdentifiers(pathVar,2,1);
      then tempList;
    case Matrix.RP_CALL(pathVar,_,l)
    local
      Absyn.Ident pathVar;
      list<Absyn.Ident> tempList;
      Matrix.RenamedPatList l;
      equation
        tempList = generateIdentifiers(pathVar,listLength(l),1);
      then tempList;          
  end matchcontinue;
end getPathVarsFromConstruct;

protected function extractSubpatterns "function: extractSubpatterns
	author: KS
 	Extract all the subpatterns from a constructor or a wildcard.
 	For a wildcard, n wildcards are produced (where n is the number of arguments to the constructor). 
  All the extracted subpatterns ends up in a matrix.
  Example: 
  The following column (pattern list), (path) variable list {x__1,x__2}
  and an index vector {1,2,3} ...
  	 (pathVar1 = _)
  	 (pathVar2 = (2 :: {}))
  	 (pathVar3 = (4 :: (3 :: {})))
  ... will result in the following matrix:
  [RP_WILDCARD(x__1)  RP_WILDCARD(x__2)                                        ]
  [RP_INTEGER(x__1,2) RP_EMPTYLIST(x__2)                                       ]
  [RP_INTEGER(x__1,4) RP_CONS(x__2,RP_INTEGER(x__2__1,3),RP_EMPTYLIST(x__2__2) ] 
"
  input list<Absyn.Ident> varList;
  input Matrix.IndexVector indVec;
  input RenamedPatList patList;
  input RenamedPatMatrix accMat;
  output RenamedPatMatrix outMat;
algorithm
  outMat :=
  matchcontinue (varList,indVec,patList,localAccMat)
    local
      RenamedPatList localPatList;
      Matrix.RenamedPatMatrix localAccMat;
    case (_,{},localPatList,localAccMat) equation then localAccMat;
    case (localVarList,first :: rest,localPatList,localAccMat)
      local	      
        list<Absyn.Ident> localVarList;
        Integer first;
        IndexVector rest;
        RenamedPatList tempPatList;  
        RenamedPat pat;
      equation
        pat = arrayGet(listArray(localPatList),first);
        true = wildcardOrNot(pat);
        tempPatList = generateWildcards(localVarList);
        localAccMat = addNewPatRow(localAccMat,tempPatList,1);
        
        localAccMat = extractSubpatterns(localVarList,rest,localPatList,localAccMat);  
      then localAccMat;
    case (localVarList,first :: rest,localPatList,localAccMat)
      local
        list<Absyn.Ident> localVarList;
        Integer first;
        IndexVector rest;
        RenamedPatList tempPatList;  
        RenamedPatList tempPatList;  
      equation
        tempPatList = extractFuncArgs(arrayGet(listArray(localPatList),first));
        localAccMat = addNewPatRow(localAccMat,tempPatList,1);
        localAccMat = extractSubpatterns(localVarList,rest,localPatList,localAccMat);  
      then localAccMat;   
  end matchcontinue;    
end extractSubpatterns;

protected function generateWildcards "function: generateWildcards
	author: KS
	Given a list of identifers, this function will generate a list of
	wildcard patterns with corresponding identifer (path variable)
"
  input list<Absyn.Ident> varList;
  output RenamedPatList outList;
algorithm
  outList :=
  matchcontinue (varList)
    case ({}) equation then {};
    case (first :: rest)
      local
        Absyn.Ident first;
        list<Absyn.Ident> rest;
        RenamedPat pat;
        RenamedPatList l;
      equation
        pat = Matrix.RP_WILDCARD(first); 
        l = generateWildcards(rest);
      then pat :: l;
  end matchcontinue;        
end generateWildcards;

protected function extractFuncArgs "function: extractFuncArgs
	author: KS
	This function is used by extractSubPatterns
"
  input RenamedPat inPat;
  output RenamedPatList outList;
algorithm
  outList :=
  matchcontinue (inPat)
    case (Matrix.RP_CALL(_,_,l)) 
      local 
        RenamedPatList l;  
      equation
      then l;
    case (Matrix.RP_TUPLE(_,l)) 
      local 
        RenamedPatList l;
      equation 
      then l;
    case (Matrix.RP_CONS(_,first,second)) 
      local
        RenamedPat first,second;
        RenamedPatList l;
      equation
        l = {first,second};    
      then l;
  end matchcontinue;             
end extractFuncArgs;


protected function addNewPatRow "function: addNewPatRow
	author: KS
	Adds a new row to a matrix.
"
  input RenamedPatMatrix patMat;
  input RenamedPatList patList;
  input Integer pivot;
  output RenamedPatMatrix outPatMat;
algorithm
  outPatMat :=
  matchcontinue (patMat,patList,pivot)
    local
      RenamedPatMatrix localPatMat;  
    case (localPatMat,{},_) equation then localPatMat;
    case (localPatMat,first :: rest,localPivot)
      local
        Integer localPivot;
        RenamedPat first;
        RenamedPatList rest,tempList;
      equation
        tempList = localPatMat[localPivot];
        tempList = listAppend(tempList,first :: {});               
        localPatMat = arrayUpdate(localPatMat, localPivot, tempList);
      then addNewPatRow(localPatMat,rest,localPivot+1);
  end matchcontinue;
end addNewPatRow; 

protected function findMatches "function: findMatches
	author: KS
	This function takes an identifer and matches this identifer against
	all the patterns in a pattern list. It stores the index of the matched
	pattern in a list of integers"
  input Absyn.Ident matchObj;
  input RenamedPatList patList;
  input list<Integer> accIndList;
  input Integer pivot;
  output list<Integer> indList;
algorithm
  indList :=
  matchcontinue (matchObj,patList,accIndList,pivot)
    local
      RenamedPat first;
      RenamedPatList rest;
      Integer localPivot;
      list<Integer> localAccIndList;
      Absyn.Ident localMatchObj,constName;
    case (_,{},localAccIndList,_) equation then localAccIndList;
    case (localMatchObj,first :: rest,localAccIndList,localPivot)
      equation
        true = wildcardOrNot(first);
      then findMatches(localMatchObj,rest,listAppend(localAccIndList,{localPivot}),localPivot+1);
    case (localMatchObj,first :: rest,localAccIndList,localPivot)
      equation
        true = constantOrNot(first);
        constName = getConstantName(first);
        true = stringEqual(constName,localMatchObj);  
      then findMatches(localMatchObj,rest,listAppend(localAccIndList,{localPivot}),localPivot+1);
    case (localMatchObj,first :: rest,localAccIndList,localPivot)
      local
        Absyn.Ident constructorName;
      equation   
        true = constructorOrNot(first);
        constructorName = getConstructorName(first);
        true = stringEqual(constructorName,localMatchObj); 
      then findMatches(localMatchObj,rest,listAppend(localAccIndList,{localPivot}),localPivot+1);
    case (localMatchObj,_ :: rest,localAccIndList,localPivot)
    then findMatches(localMatchObj,rest,localAccIndList,localPivot+1);
  end matchcontinue;
end findMatches;


protected function generatePositionalArgs "function: generatePositionalArgs
	author: KS
	This function is used in the following cases:
	v := matchcontinue (x)
  	  case REC(a=1,b=2)
   	 ...
	The named arguments a=1 and b=2 must be sorted and transformed into 
	positional arguments (a,b is not necessarely the correct order).
"
  input list<Absyn.Ident> fieldNameList;
  input list<Absyn.NamedArg> namedArgList;
  input list<Absyn.Exp> accList;
  output list<Absyn.Exp> outList;
algorithm
  outList :=
  matchcontinue (fieldNameList,namedArgList,accList)
    local
      list<Absyn.Exp> localAccList;  
    case ({},_,localAccList) then localAccList;
    case (firstFieldName :: restFieldNames,localNamedArgList,localAccList)
      local
        list<Absyn.Ident> restFieldNames;
        Absyn.Ident firstFieldName;
        list<Absyn.Exp> expL;
        list<Absyn.NamedArg> localNamedArgList;
      equation
        expL = Util.listCreate(findFieldExpInList(firstFieldName,localNamedArgList));
        localAccList = listAppend(localAccList,expL);    
        localAccList = generatePositionalArgs(restFieldNames,localNamedArgList,localAccList);  
      then localAccList;  
  end matchcontinue;  
end generatePositionalArgs;  

protected function findFieldExpInList "function: findFieldExpInList
	author: KS
	Helper function to generatePositionalArgs
"
  input Absyn.Ident firstFieldName;
  input list<Absyn.NamedArg> namedArgList;
  output Absyn.Exp outExp;
algorithm
  outExp :=
  matchcontinue (firstFieldName,namedArgList)
    local
      Absyn.Exp e;
      Absyn.Ident localFieldName,aName;
      list<Absyn.NamedArg> restNamedArgList;  
    case (_,{}) then Absyn.CREF(Absyn.WILD());  
    case (localFieldName,Absyn.NAMEDARG(aName,e) :: _)
      equation
        true = stringEqual(localFieldName,aName);
      then e;
    case (localFieldName,_ :: restNamedArgList)
      equation
        e = findFieldExpInList(localFieldName,restNamedArgList);
      then e;  
  end matchcontinue;
end findFieldExpInList;

//-----------------------------------------------------
// Helper functions

protected function allWildcards "function: allWildcards
	author: KS
"
  input RenamedPatList lPat;
  output Boolean val;
algorithm
  val := Util.boolAndList(Util.listMap(lPat,wildcardOrNot));
end allWildcards;


protected function allConst "function: allConst
	author: KS
	Decides wheter a list of Renamed Patterns only contains constant patterns
"
  input RenamedPatList lPat;
  output Boolean val;
algorithm
  val := Util.boolAndList(Util.listMap(lPat,constantOrNot));
end allConst;


protected function existConstructor "function: existConstructor
	author: KS
	Decides wheter a list of Renamed Patterns contains a constructor
"
  input RenamedPatList lPat;
  output Boolean val;
algorithm
  val := Util.boolOrList(Util.listMap(lPat,constructorOrNot));
end existConstructor;


protected function wildcardOrNot "function: wildcardOrNot
	author: KS
	Decides wheter a Renamed Patterns is a wildcard or not
"
  input RenamedPat pat;
  output Boolean val;
algorithm
  val :=
  matchcontinue (pat)
    case (Matrix.RP_WILDCARD(_))
      equation
      then true;
    case (_)
      equation
      then false;
  end matchcontinue;    
end wildcardOrNot;


protected function constantOrNot "function: constantOrNot
	author: KS
	Decides wheter a Renamed Patterns is a constant or not
"
  input RenamedPat pat;
  output Boolean val;
algorithm
  val :=
  matchcontinue (pat)
    case (Matrix.RP_INTEGER(_,_))
      equation
      then true;
    case (Matrix.RP_STRING(_,_))
      equation
      then true;
    case (Matrix.RP_BOOL(_,_))
      equation
      then true;
    case (Matrix.RP_REAL(_,_))
      equation
      then true;      
    case (Matrix.RP_EMPTYLIST(_)) then true;       
    case (Matrix.RP_CREF(_,_))
      equation
      then true;
    case (_)
      equation
      then false;
  end matchcontinue;    
end constantOrNot;


protected function constructorOrNot "function: constructorOrNot
	author:KS
	Decides wheter a Renamed Patterns is a constructor or not
"
  input RenamedPat pat;
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

protected function printList "function: printList
	author: KS
"
  input list<Boolean> boolList;
algorithm
  _ :=
  matchcontinue (boolList)
    case ({}) equation then ();
    case (first :: rest) 
      local
        Boolean first;
        list<Boolean> rest;
      equation
        true = first;
        print("true");
        printList(rest);
      then ();
    case (first :: rest) 
      local
        Boolean first;
        list<Boolean> rest;
      equation
        print("false");
        printList(rest);
      then ();
  end matchcontinue;   
end printList;


protected function printCList "function: printCList
	author:KS
"
  input list<Absyn.Ident,Boolean> cList;
algorithm
  _ :=
  matchcontinue (cList)
    case ({}) then ();
    case ((first,_) :: rest)
      local
        Absyn.Ident first;
        list<Absyn.Ident,Boolean> rest; 
      equation  
        print(first);
        printCList(rest);
      then ();
  end matchcontinue;            
end printCList;


protected function selectRightHandSides "function: selectRightHandSides
	author:KS
	Picks out all the elements from a right hand vector given an index vector.
"
  input IndexVector indVec;
  input RightHandVector rhVec;
  input RightHandList accRhList;
  output RightHandList outRhList;
algorithm
  outRhList :=
  matchcontinue (indVec,rhVec,accRhList)
    local
      Matrix.RightHandList localAccRhList;
    case ({},_,localAccRhList) equation then localAccRhList;
    case (first :: rest,localRhVec,localAccRhList)
      local
        Integer first;
        IndexVector rest;
        RightHandVector localRhVec;
        RightHandList tempRhSideL;
      equation
        tempRhSideL = Util.listCreate(arrayGet(localRhVec,first));
        localAccRhList = listAppend(localAccRhList,tempRhSideL);
      then selectRightHandSides(rest,localRhVec,localAccRhList);    
  end matchcontinue;
end selectRightHandSides;

//-----------------------------------------------
// Some simple "type checking"
/*
public function patternCheck 
  input RenamedPatMatrix2 mat;
  output Boolean b;   
algorithm
  b := 
  matchcontinue (mat)    
    case ({}) then true; 
    case ({{}}) then true;  
    case (firstRow :: restRows) 
      local 
        RenamedPatMatrix2 restRows;
        RenamedPatList firstRow;
        RenamedPat pat; 
        Boolean b2; 
      equation  
        pat = Util.listFirst(firstRow);
        b2 = patternCheck2(pat,firstRow); 
        true = b2; 
        b2 = patternCheck(restRows);
      then b2;
    case (_) then fail(); 
  end matchcontinue;
end patternCheck; 

public function patternCheck2 
  input RenamedPat pat;  
  input RenamedPatList pList; 
  output Boolean outB;
algorithm 
  outB := 
  matchcontinue (pat,pList)
    case (_,{}) then true;  
    case (p,firstP :: restP) 
      local  
      equation  
        true = twoPatternMatch(p,firstP); 
        b = patternCheck2(firstP,restP);
      then b; 
    case (_,_) fail();
  end matchcontinue;
end patternCheck2;  

public function twoPatternMatch 
  input RenamedPat pat1; 
  input RenamedPat pat2;
  output Boolean outB; 
algorithm  
  outB := 
  matchcontinue (pat1,pat2) 
    case (Matrix.RP_WILDCARD(_),_) then true;      
    case (_,Matrix.RP_WILDCARD(_)) then true;
    case (Matrix.RP_EMPTYLIST(_),Matrix.RP_EMPTYLIST(_)) then true;    
    case (Matrix.RP_INTEGER(_),Matrix.RP_INTEGER(_)) then true;    
    case (Matrix.RP_REAL(_),Matrix.RP_REAL(_)) then true;    
    case (Matrix.RP_BOOL(_),Matrix.RP_BOOL(_)) then true;    
    case (Matrix.RP_STRING(_),Matrix.RP_STRING(_)) then true;
    case (Matrix.RP_CALL(_,_,_),Matrix.RP_CALL(_,_,_)) then true;  
    case (Matrix.RP_CREF(_,_),Matrix.RP_CREF(_,_)) then true;  
    case (Matrix.RP_TUPLE(_,_),Matrix.RP_TUPLE(_,_)) then true;  
    case (Matrix.RP_CONS(_,_,_),Matrix.RP_CONS(_,_,_)) then true;  
    case (p1,p2)
      local  RenamedPat p1; RenamedPat p2;
      equation
        Debug.fprint("failtrace", "- twoPatternMatch failed, non-matching patterns\n"); 
        print("Non matching patterns");
        Matrix.printPattern(p1); print(",");
        Matrix.printPattern(p2); print("\n");  
      then fail();  
  end matchcontinue; 
end twoPatternMatch; */

end Patternm;
