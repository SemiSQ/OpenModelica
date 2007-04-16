/*
 * This file is part of OpenModelica.
 * 
 * Copyright (c) 1998-2007, Link�pings universitet, Department of
 * Computer and Information Science, PELAB
 * 
 * All rights reserved.
 * 
 * (The new BSD license, see also
 * http://www.opensource.org/licenses/bsd-license.php)
 * 
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 
 *  Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * 
 *  Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in
 *   the documentation and/or other materials provided with the
 *   distribution.
 * 
 *  Neither the name of Link�pings universitet nor the names of its
 *   contributors may be used to endorse or promote products derived from
 *   this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 */

package Util 
" file:	 Util.mo
  module:      Util
  description: Miscellanous MetaModelica Compiler (MMC) utilities
 
  RCS: $Id$
  
  This module contains various MetaModelica Compiler (MMC) utilities sigh, mostly 
  related to lists.
  It is used pretty much everywhere. The difference between this 
  module and the ModUtil module is that ModUtil contains modelica 
  related utilities. The Util module only contains \"low-level\" 
  MetaModelica Compiler (MMC) utilities, for example finding elements in lists.
  
  This modules contains many functions that use \'type variables\' in MetaModelica Compiler (MMC).
  A type variable is exactly what it sounds like, a type bound to a variable.
  It is used for higher order functions, i.e. in MetaModelica Compiler (MMC) the possibility to pass a 
  \"pointer\" to a function into another function. But it can also be used for 
  generic data types, like in  C++ templates.

  A type variable in MetaModelica Compiler (MMC) is written as:
  replaceable type TyVar subtypeof Any;
  For instance,
  function listFill
    replaceable type TyVar subtypeof Any; 
  	input TyVar in;
  	input Integer i;
  	output list<TyVar>
  ...
  end listFill;
  the type variable TyVar is here used as a generic type for the function listFill, 
  which returns a list of n elements of a certain type."

public uniontype ReplacePattern
  record REPLACEPATTERN
    String from "from string (ie \".\"" ;
    String to "to string (ie \"$p\") ))" ;
  end REPLACEPATTERN;
end ReplacePattern;

protected constant list<ReplacePattern> replaceStringPatterns={REPLACEPATTERN(".","$point"),
          REPLACEPATTERN("[","$leftBracket"),REPLACEPATTERN("]","$rightBracket"),
          REPLACEPATTERN("(","$leftParanthesis"),REPLACEPATTERN(")","$rightParanthesis"),
          REPLACEPATTERN(",","$comma")};

protected import System;
protected import Print;
protected import Debug;

public function flagValue "function flagValue
  author: x02lucpo
  Extracts the flagvalue from an argument list:
  flagValue('-s',{'-d','hej','-s','file'}) => 'file'"
  input String flag;
  input list<String> arguments;
  output String flagVal;
algorithm
  flagVal :=
   matchcontinue(flag,arguments)
   local 
      String flag,arg,value;
      list<String> args;
   case(flag,{}) then "";
   case(flag,arg::{})
      equation
        0 = System.strcmp(flag,arg);
      then
        "";
   case(flag,arg::value::args)
      equation
        0 = System.strcmp(flag,arg);
      then
        value;
   case(flag,arg::args)
      equation
        value = flagValue(flag,args);
      then
        value;
   case(_,_)
      equation
       print("- Util.flagValue failed\n");
      then
       fail();
   end matchcontinue;
end flagValue;

public function listFill "function: listFill
  Returns a list of n elements of variable type: replaceable type X subtypeof Any.
  Example: listFill(\"foo\",3) => {\"foo\",\"foo\",\"foo\"}"
  input Type_a inTypeA;
  input Integer inInteger;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeALst:= listFill_tail(inTypeA, inInteger, {});
end listFill;

public function listFill_tail 
"function: listFill_tail
 @author adrpo
 tail recursive implementation for listFill"
  input Type_a inTypeA;
  input Integer inInteger;
  input list<Type_a> accumulator;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeA,inInteger, accumulator)
    local
      Type_a a;
      Integer n_1,n;
      list<Type_a> res;
    case(a,n,_) 
      equation
        true = n < 0;
        print("Internal Error, negative value to Util.listFill_tail\n");
      then {};
    case (a,0,accumulator) then accumulator; 
    case (a,n,accumulator)
      equation 
        n_1 = n - 1;
        accumulator = a::accumulator;
        res = listFill_tail(a, n_1, accumulator);
      then
        res;
  end matchcontinue;
end listFill_tail;

public function listMake2 "function listMake2
  Takes two arguments of same type and returns a list containing the two."
  input Type_a inTypeA1;
  input Type_a inTypeA2;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeALst := {inTypeA1, inTypeA2};
end listMake2;

public function listIntRange "function: listIntRange
  Returns a list of n integers from 1 to N.
  Example: listIntRange(3) => {1,2,3}"
  input Integer n;
  output list<Integer> res;
algorithm 
  res := listIntRange2(1,n); /* listIntRange_tail(1, n, {}); */
end listIntRange;

protected function listIntRange_tail
  input Integer startInt;
  input Integer endInt;
  input list<Integer> accIntegerLst;
  output list<Integer> outIntegerLst;
algorithm 
  outIntegerLst:=
  matchcontinue (startInt,endInt,accIntegerLst)
    local
      Integer i_1,i,n,hd;
      list<Integer> res;
    case (i,n,accIntegerLst)
      equation 
        (i < n) = true;
        i_1 = i + 1;
        hd = n-i+1;
        accIntegerLst = hd::accIntegerLst;
        res = listIntRange_tail(i_1, n, accIntegerLst);
      then
        res;
    case (i,n,accIntegerLst) 
      equation
        hd = n-i+1; 
      then hd::accIntegerLst;
  end matchcontinue;
end listIntRange_tail;

protected function listIntRange2
  input Integer inInteger1;
  input Integer inInteger2;
  output list<Integer> outIntegerLst;
algorithm 
  outIntegerLst:=
  matchcontinue (inInteger1,inInteger2)
    local
      Integer i_1,i,n;
      list<Integer> res;
    case (i,n)
      equation 
        (i < n) = true;
        i_1 = i + 1;
        
        res = listIntRange2(i_1, n);
      then
        (i :: res);
    case (i,n) then {i}; 
  end matchcontinue;
end listIntRange2;

public function listFirst "function: listFirst 
  Returns the first element of a list
  Example: listFirst({3,5,7,11,13}) => 3"
  input list<Type_a> inTypeALst;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeA:= listNth(inTypeALst, 0);
end listFirst;

public function listRest "function: listRest
  Returns the rest of a list.
  Example: listRest({3,5,7,11,13}) => {5,7,11,13}"
  input list<Type_a> inTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeALst)
    local list<Type_a> x;
    case ((_ :: x)) then x; 
  end matchcontinue;
end listRest;

public function listLast "function: listLast
  Returns the last element of a list. If the list is the empty list, the function fails.
  Example:
    listLast({3,5,7,11,13}) => 13
    listLast({}) => fail"
  input list<Type_a> inTypeALst;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeA:=
  matchcontinue (inTypeALst)
    local
      Type_a a;
      list<Type_a> rest;
    case {} then fail(); 
    case {a} then a; 
    case ((_ :: rest))
      equation 
        a = listLast(rest);
      then
        a;
  end matchcontinue;
end listLast;

public function listCons "function: listCons
  Performs the cons operation, i.e. elt::list."
  input list<Type_a> inTypeALst;
  input Type_a inTypeA;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeALst:= (inTypeA::inTypeALst);
end listCons;

public function listCreate "function: listCreate 
  Create a list from an element."
  input Type_a inTypeA;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeALst:= {inTypeA};
end listCreate;

public function listStripLast "function: listStripLast
  Remove the last element of a list. If the list is the empty list, the function 
  returns empty list
  Example:
    listStripLast({3,5,7,11,13}) => {3,5,7,11}
    listStripLast({}) => {}"
  input list<Type_a> inTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeALst)
    local
      Type_a a;
      list<Type_a> lstTmp,lst;
    case {} then {}; 
    case {a} then {};
    case a::lst 
      equation 
        lstTmp = listStripLast(lst);
      then
        a::lstTmp;
  end matchcontinue;
end listStripLast;

public function listFlatten "function: listFlatten
  Takes a list of lists and flattens it out, 
  producing one list of all elements of the sublists.
  Example: listFlatten({ {1,2},{3,4,5},{6},{} }) => {1,2,3,4,5,6}"
  input list<list<Type_a>> inTypeALstLst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeALst:= listFlatten_tail(inTypeALstLst, {});
end listFlatten;


public function listFlatten_tail 
"function: listFlatten_tail
 tail recursive helper to listFlatten"
  input list<list<Type_a>> inTypeALstLst;
  input list<Type_a> accTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeALstLst, accTypeALst)
    local
      list<Type_a> r_1,l,f;
      list<list<Type_a>> r;
    case ({},accTypeALst) then accTypeALst; 
    case (f :: r,accTypeALst)
      equation 
        r_1 = listAppend(accTypeALst, f);
        l = listFlatten_tail(r, r_1);
      then
        l;
  end matchcontinue;
end listFlatten_tail;


public function listAppendElt "function: listAppendElt
  This function adds an element last to the list
  Example: listAppendElt(1,{2,3}) => {2,3,1}"
  input Type_a inTypeA;
  input list<Type_a> inTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeALst:= listAppend(inTypeALst, {inTypeA});
  /*
  matchcontinue (inTypeA,inTypeALst)
    local
      Type_a elt,x;
      list<Type_a> xs_1,xs;
    case (elt,{}) then {elt}; 
    case (elt,(x :: xs))
      equation 
        xs_1 = listAppendElt(elt, xs);
      then
        (x :: xs_1);
  end matchcontinue;
  */
end listAppendElt;

public function applyAndAppend
"@author adrpo
 fun f(x) => y
 fun applyAndAppend(x,f,a) => a @ {(f x)})"
  input Type_a element;
  input FuncTypeType_aToType_b f;
  input list<Type_b> accLst;
  output list<Type_b> outLst;
  replaceable type Type_b subtypeof Any;    
  replaceable type Type_b subtypeof Any;  
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
  end FuncTypeType_aToType_b;
algorithm 
  outLst := matchcontinue(element, f, accLst)
    case(element, f, accLst)
      local Type_b result;
      equation
        result = f(element);
        accLst = listAppend(accLst, {result});
      then accLst;
  end matchcontinue;
end applyAndAppend;


public function applyAndCons
"@author adrpo
 fun f(x) => y
 fun applyAndCons(x,f,a) => (f x)::a)"
  input Type_a element;
  input FuncTypeType_aToType_b f;
  input list<Type_b> accLst;
  output list<Type_b> outLst;
  replaceable type Type_b subtypeof Any;    
  replaceable type Type_b subtypeof Any;  
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
  end FuncTypeType_aToType_b;
algorithm 
  outLst := matchcontinue(element, f, accLst)
    case(element, f, accLst)
      local Type_b result;
      equation
        result = f(element);
      then result::accLst;
  end matchcontinue;
end applyAndCons;


public function listApplyAndFold 
"@author adrpo
 listApplyAndFold(list<'a>, apply:(x,f,a) => (f x)::a, f:a=>b, accumulator) => list<'b>"
  input list<Type_a> lst;
  input FoldFunc foldFunc;
  input FuncType_a2Type_b typeA2typeB;
  input list<Type_b> accumulator;
  output list<Type_b> result;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FoldFunc
    input Type_a inElement;
    input FuncType_a2Type_b typeA2typeB;
    input list<Type_b> accumulator;
    output list<Type_b> outLst;
    partial function FuncType_a2Type_b
      input Type_a inElement;
      output Type_b outElement;
    end FuncType_a2Type_b;      
  end FoldFunc;
  partial function FuncType_a2Type_b
    input Type_a inElement;
    output Type_b outElement;
  end FuncType_a2Type_b;  
algorithm 
  result :=
  matchcontinue (lst,foldFunc,typeA2typeB,accumulator)
    local
      list<Type_b> foldArg1, foldArg2;
      list<Type_a> rest;
      Type_a hd;
    case ({},_,_,accumulator) then accumulator; 
    case (hd :: rest,foldFunc,typeA2typeB,accumulator)
      equation 
        foldArg1 = foldFunc(hd,typeA2typeB,accumulator);
        foldArg2 = listApplyAndFold(rest, foldFunc, typeA2typeB, foldArg1);        
      then
        foldArg2;
  end matchcontinue;
end listApplyAndFold;


public function listMap "function: listMap
  Takes a list and a function over the elements of the lists, which is applied
  for each element, producing a new list.
  Example: listMap({1,2,3}, intString) => { \"1\", \"2\", \"3\"}"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToType_b inFuncTypeTypeAToTypeB;
  output list<Type_b> outTypeBLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
    replaceable type Type_b subtypeof Any;
  end FuncTypeType_aToType_b;
  replaceable type Type_b subtypeof Any;
algorithm 
  /* implementation 0 - adrpo: seems to be the fastest */
  outTypeBLst := listApplyAndFold(inTypeALst, applyAndAppend, inFuncTypeTypeAToTypeB, {});
  /* implementation 1 
  outTypeBLst := listReverse(listApplyAndFold(inTypeALst, applyAndCons, inFuncTypeTypeAToTypeB, {}));
  */
  /* implementation 2
  outTypeBLst := 
  matchcontinue (inTypeALst,inFuncTypeTypeAToTypeB)
    local
      Type_b f_1;
      list<Type_b> r_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aToType_b fn;
    case ({},_) then {}; 
    case ((f :: r),fn)
      equation 
        f_1 = fn(f);
        r_1 = listMap(r, fn);
      then
        (f_1::r_1);
  end matchcontinue;
  */
end listMap;

public function listMap_2 "function listMap_2
  Takes a list and a function over the elements returning a tuple of 
  two types, which is applied for each element producing two new lists.
  Example:
    function split_real_string (real) => (string,string)  returns the string value at 
    each side of the decimal point.
    listMap_2({1.5,2.01,3.1415}, split_real_string) => ({\"1\",\"2\",\"3\"},{\"5\",\"01\",\"1415\"})"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToType_bType_c inFuncTypeTypeAToTypeBTypeC;
  output list<Type_b> outTypeBLst;
  output list<Type_c> outTypeCLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToType_bType_c
    input Type_a inTypeA;
    output Type_b outTypeB;
    output Type_c outTypeC;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
  end FuncTypeType_aToType_bType_c;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm 
  (outTypeBLst,outTypeCLst):=
  matchcontinue (inTypeALst,inFuncTypeTypeAToTypeBTypeC)
    local
      Type_b f1_1;
      Type_c f2_1;
      list<Type_b> r1_1;
      list<Type_c> r2_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aToType_bType_c fn;
    case ({},_) then ({},{}); 
    case ((f :: r),fn)
      equation 
        (f1_1,f2_1) = fn(f);
        (r1_1,r2_1) = listMap_2(r, fn);
      then
        ((f1_1 :: r1_1),(f2_1 :: r2_1));
  end matchcontinue;
end listMap_2;

public function listMap1 "function listMap1
  Takes a list and a function over the list plus an extra argument sent to the function.
  The function produces a new value which is used for creating a new list.
  Example: listMap1({1,2,3},intAdd,2) => {3,4,5}"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bToType_c inFuncTypeTypeATypeBToTypeC;
  input Type_b inTypeB;
  output list<Type_c> outTypeCLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bToType_c
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Type_c outTypeC;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
  end FuncTypeType_aType_bToType_c;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm 
  outTypeCLst:= listMap1_tail(inTypeALst,inFuncTypeTypeATypeBToTypeC,inTypeB,{});
  /*
  matchcontinue (inTypeALst,inFuncTypeTypeATypeBToTypeC,inTypeB)
    local
      Type_c f_1;
      list<Type_c> r_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aType_bToType_c fn;
      Type_b extraarg;
    case ({},_,_) then {}; 
    case ((f :: r),fn,extraarg)
      equation 
        f_1 = fn(f, extraarg);
        r_1 = listMap1(r, fn, extraarg);
      then
        (f_1 :: r_1);
  end matchcontinue;
  */
end listMap1;

public function listMap1_tail 
"function listMap1_tail
 tail recurstive implmentation of listMap1"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bToType_c inFuncTypeTypeATypeBToTypeC;
  input Type_b inTypeB;
  input list<Type_c> accTypeCLst;
  output list<Type_c> outTypeCLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bToType_c
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Type_c outTypeC;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
  end FuncTypeType_aType_bToType_c;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm 
  outTypeCLst:=
  matchcontinue (inTypeALst,inFuncTypeTypeATypeBToTypeC,inTypeB,accTypeCLst)
    local
      Type_c f_1;
      list<Type_c> r_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aType_bToType_c fn;
      Type_b extraarg;
    case ({},_,_,accTypeCLst) then accTypeCLst; 
    case ((f :: r),fn,extraarg,accTypeCLst)
      equation 
        f_1 = fn(f, extraarg);
        accTypeCLst = listAppend(accTypeCLst, {f_1});
        r_1 = listMap1_tail(r, fn, extraarg, accTypeCLst);
      then
        r_1;
  end matchcontinue;
end listMap1_tail;

public function listMap1r "function listMap1r
  Same as listMap1 but swapped arguments on function."
  input list<Type_a> inTypeALst;
  input FuncTypeType_bType_aToType_c inFuncTypeTypeBTypeAToTypeC;
  input Type_b inTypeB;
  output list<Type_c> outTypeCLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_bType_aToType_c
    input Type_b inTypeB;
    input Type_a inTypeA;
    output Type_c outTypeC;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
  end FuncTypeType_bType_aToType_c;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm 
  outTypeCLst:= listMap1r_tail(inTypeALst,inFuncTypeTypeBTypeAToTypeC,inTypeB,{});
  /*
  matchcontinue (inTypeALst,inFuncTypeTypeBTypeAToTypeC,inTypeB)
    local
      Type_c f_1;
      list<Type_c> r_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_bType_aToType_c fn;
      Type_b extraarg;
    case ({},_,_) then {}; 
    case ((f :: r),fn,extraarg)
      equation 
        f_1 = fn(extraarg, f);
        r_1 = listMap1r(r, fn, extraarg);
      then
        (f_1 :: r_1);
  end matchcontinue;
  */
end listMap1r;

public function listMap1r_tail 
"function listMap1r
 tail recursive implementation of listMap1r"
  input list<Type_a> inTypeALst;
  input FuncTypeType_bType_aToType_c inFuncTypeTypeBTypeAToTypeC;
  input Type_b inTypeB;
  input list<Type_c> accTypeCLst;
  output list<Type_c> outTypeCLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_bType_aToType_c
    input Type_b inTypeB;
    input Type_a inTypeA;
    output Type_c outTypeC;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
  end FuncTypeType_bType_aToType_c;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm 
  outTypeCLst:=
  matchcontinue (inTypeALst,inFuncTypeTypeBTypeAToTypeC,inTypeB,accTypeCLst)
    local
      Type_c f_1;
      list<Type_c> r_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_bType_aToType_c fn;
      Type_b extraarg;
    case ({},_,_,accTypeCLst) then accTypeCLst; 
    case ((f :: r),fn,extraarg,accTypeCLst)
      equation 
        f_1 = fn(extraarg, f);
        accTypeCLst = listAppend(accTypeCLst, {f_1});
        r_1 = listMap1r_tail(r, fn, extraarg, accTypeCLst);
      then
        (r_1);
  end matchcontinue;
end listMap1r_tail;


public function listMap2 "function listMap2
  Takes a list and a function and two extra arguments passed to the function.
  The function produces one new value which is used for creating a new list.
  Example:
    replaceable type Type_a subtypeof Any;
    function select:(Boolean,Type_a,Type_a) => Type_a
    listMap2({true,false,false},1,0,select) => {1,0,0}"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bType_cToType_d inFuncTypeTypeATypeBTypeCToTypeD;
  input Type_b inTypeB;
  input Type_c inTypeC;
  output list<Type_d> outTypeDLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bType_cToType_d
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    output Type_d outTypeD;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
    replaceable type Type_d subtypeof Any;
  end FuncTypeType_aType_bType_cToType_d;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
algorithm 
  outTypeDLst:=
  matchcontinue (inTypeALst,inFuncTypeTypeATypeBTypeCToTypeD,inTypeB,inTypeC)
    local
      Type_d f_1;
      list<Type_d> r_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aType_bType_cToType_d fn;
      Type_b extraarg1;
      Type_c extraarg2;
    case ({},_,_,_) then {}; 
    case ((f :: r),fn,extraarg1,extraarg2)
      equation 
        f_1 = fn(f, extraarg1, extraarg2);
        r_1 = listMap2(r, fn, extraarg1, extraarg2);
      then
        (f_1 :: r_1);
  end matchcontinue;
end listMap2;

public function listMap3 "function listMap3
  Takes a list and a function and three extra arguments passed to the function.
  The function produces one new value which is used for creating a new list."
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bType_cType_dToType_e inFuncTypeTypeATypeBTypeCTypeDToTypeE;
  input Type_b inTypeB;
  input Type_c inTypeC;
  input Type_d inTypeD;
  output list<Type_e> outTypeELst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bType_cType_dToType_e
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d inTypeD;
    output Type_e outTypeE;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
    replaceable type Type_d subtypeof Any;
    replaceable type Type_e subtypeof Any;
  end FuncTypeType_aType_bType_cType_dToType_e;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
algorithm 
  outTypeELst:=
  matchcontinue (inTypeALst,inFuncTypeTypeATypeBTypeCTypeDToTypeE,inTypeB,inTypeC,inTypeD)
    local
      Type_e f_1;
      list<Type_e> r_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aType_bType_cType_dToType_e fn;
      Type_b extraarg1;
      Type_c extraarg2;
      Type_d extraarg3;
    case ({},_,_,_,_) then {}; 
    case ((f :: r),fn,extraarg1,extraarg2,extraarg3)
      equation 
        f_1 = fn(f, extraarg1, extraarg2, extraarg3);
        r_1 = listMap3(r, fn, extraarg1, extraarg2, extraarg3);
      then
        (f_1 :: r_1);
  end matchcontinue;
end listMap3;

public function listMap32 "function listMap32
  Takes a list and a function and three extra arguments passed to the function.
  The function produces two values which is used for creating two new lists."
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bType_cType_dToType_eType_f inFuncTypeTypeATypeBTypeCTypeDToTypeETypeF;
  input Type_b inTypeB;
  input Type_c inTypeC;
  input Type_d inTypeD;
  output list<Type_e> outTypeELst;
  output list<Type_f> outTypeFLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bType_cType_dToType_eType_f
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d inTypeD;
    output Type_e outTypeE;
    output Type_f outTypeF;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
    replaceable type Type_d subtypeof Any;
    replaceable type Type_e subtypeof Any;
    replaceable type Type_f subtypeof Any;
  end FuncTypeType_aType_bType_cType_dToType_eType_f;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
  replaceable type Type_f subtypeof Any;
algorithm 
  (outTypeELst,outTypeFLst):=
  matchcontinue (inTypeALst,inFuncTypeTypeATypeBTypeCTypeDToTypeETypeF,inTypeB,inTypeC,inTypeD)
    local
      Type_e f1_1;
      Type_f f2_1;
      list<Type_e> r1_1;
      list<Type_f> r2_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aType_bType_cType_dToType_eType_f fn;
      Type_b extraarg1;
      Type_c extraarg2;
      Type_d extraarg3;
    case ({},_,_,_,_) then ({},{}); 
    case ((f :: r),fn,extraarg1,extraarg2,extraarg3)
      equation 
        (f1_1,f2_1) = fn(f, extraarg1, extraarg2, extraarg3);
        (r1_1,r2_1) = listMap32(r, fn, extraarg1, extraarg2, extraarg3);
      then
        ((f1_1 :: r1_1),(f2_1 :: r2_1));
  end matchcontinue;
end listMap32;

public function listMap12 "function: listMap12
  Takes a list and a function with one extra arguments passed to the function.
  The function returns a tuple of two values which are used for creating 
  two new lists."
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bToType_cType_d inFuncTypeTypeATypeBToTypeCTypeD;
  input Type_b inTypeB;
  output list<Type_c> outTypeCLst;
  output list<Type_d> outTypeDLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bToType_cType_d
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Type_c outTypeC;
    output Type_d outTypeD;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
    replaceable type Type_d subtypeof Any;
  end FuncTypeType_aType_bToType_cType_d;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
algorithm 
  (outTypeCLst,outTypeDLst):=
  matchcontinue (inTypeALst,inFuncTypeTypeATypeBToTypeCTypeD,inTypeB)
    local
      Type_c f1;
      Type_d f2;
      list<Type_c> r1;
      list<Type_d> r2;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aType_bToType_cType_d fn;
      Type_b extraarg1;
    case ({},_,_) then ({},{}); 
    case ((f :: r),fn,extraarg1)
      equation 
        (f1,f2) = fn(f, extraarg1);
        (r1,r2) = listMap12(r, fn, extraarg1);
      then
        ((f1 :: r1),(f2 :: r2));
  end matchcontinue;
end listMap12;

public function listMap22 "function: listMap22
  Takes a list and a function with two extra arguments passed to the function.
  The function returns a tuple of two values which are used for creating two new lists
  Example:
    function foo(int,string,string) => (string,string) 
      concatenates each string with itself n times. foo(2,\"a\",b\") => (\"aa\",\"bb\")
    listMap22 ({2,3},foo,\"a\",\"b\") => {(\"aa\",\"bb\"),(\"aa\",\"bbb\")}"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bType_cToType_dType_e inFuncTypeTypeATypeBTypeCToTypeDTypeE;
  input Type_b inTypeB;
  input Type_c inTypeC;
  output list<tuple<Type_d, Type_e>> outTplTypeDTypeELst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bType_cToType_dType_e
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    output Type_d outTypeD;
    output Type_e outTypeE;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
    replaceable type Type_d subtypeof Any;
    replaceable type Type_e subtypeof Any;
  end FuncTypeType_aType_bType_cToType_dType_e;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
algorithm 
  outTplTypeDTypeELst:=
  matchcontinue (inTypeALst,inFuncTypeTypeATypeBTypeCToTypeDTypeE,inTypeB,inTypeC)
    local
      Type_d f1;
      Type_e f2;
      list<tuple<Type_d, Type_e>> r_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aType_bType_cToType_dType_e fn;
      Type_b extraarg1;
      Type_c extraarg2;
    case ({},_,_,_) then {}; 
    case ((f :: r),fn,extraarg1,extraarg2)
      equation 
        (f1,f2) = fn(f, extraarg1, extraarg2);
        r_1 = listMap22(r, fn, extraarg1, extraarg2);
      then
        ((f1,f2) :: r_1);
  end matchcontinue;
end listMap22;

public function listMap0 "function: listMap0
  Takes a list and a function which does not return a value
  The function is probably a function with side effects, like print.
  Example: listMap0({\"a\",\"b\",\"c\"},print) => ()"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
algorithm 
  _:=
  matchcontinue (inTypeALst,inFuncTypeTypeATo)
    local
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aTo fn;
    case ({},_) then (); 
    case ((f :: r),fn)
      equation 
        fn(f);
        listMap0(r, fn);
      then
        ();
  end matchcontinue;
end listMap0;

public function listListMap "function: listListMap 
  Takes a list of lists and a function producing one value.
  The function is applied to each element of the lists resulting
  in a new list of lists.
  Example: listListMap({ {1,2},{3},{4}},int_string) => { {\"1\",\"2\"},{\"3\"},{\"4\"} }"
  input list<list<Type_a>> inTypeALstLst;
  input FuncTypeType_aToType_b inFuncTypeTypeAToTypeB;
  output list<list<Type_b>> outTypeBLstLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
    replaceable type Type_b subtypeof Any;
  end FuncTypeType_aToType_b;
  replaceable type Type_b subtypeof Any;
algorithm 
  outTypeBLstLst:=
  matchcontinue (inTypeALstLst,inFuncTypeTypeAToTypeB)
    local
      list<Type_b> f_1;
      list<list<Type_b>> r_1;
      list<Type_a> f;
      list<list<Type_a>> r;
      FuncTypeType_aToType_b fn;
    case ({},_) then {}; 
    case ((f :: r),fn)
      equation 
        f_1 = listMap(f, fn);
        r_1 = listListMap(r, fn);
      then
        (f_1 :: r_1);
  end matchcontinue;
end listListMap;

public function listListMap1 "function listListMap1
  author: PA
  similar to listListMap but for functions taking two arguments.
  The second argument is passed as an extra argument."
  input list<list<Type_a>> inTypeALstLst;
  input FuncTypeType_aType_bToType_c inFuncTypeTypeATypeBToTypeC;
  input Type_b inTypeB;
  output list<list<Type_c>> outTypeCLstLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bToType_c
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Type_c outTypeC;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
  end FuncTypeType_aType_bToType_c;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm 
  outTypeCLstLst:=
  matchcontinue (inTypeALstLst,inFuncTypeTypeATypeBToTypeC,inTypeB)
    local
      list<Type_c> f_1;
      list<list<Type_c>> r_1;
      list<Type_a> f;
      list<list<Type_a>> r;
      FuncTypeType_aType_bToType_c fn;
      Type_b e;
    case ({},_,_) then {}; 
    case ((f :: r),fn,e)
      equation 
        f_1 = listMap1(f, fn, e);
        r_1 = listListMap1(r, fn, e);
      then
        (f_1 :: r_1);
  end matchcontinue;
end listListMap1;

public function listFold "function: listFold
  Takes a list and a function operating on list elements having an extra argument that is \'updated\'
  thus returned from the function. The third argument is the startvalue for the updated value.
  listFold will call the function for each element in a sequence, updating the startvalue 
  Example:
    listFold({1,2,3},intAdd,2) =>  8
    intAdd(1,2) => 3, intAdd(2,3) => 5, intAdd(3,5) => 8"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bToType_b inFuncTypeTypeATypeBToTypeB;
  input Type_b inTypeB;
  output Type_b outTypeB;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bToType_b
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Type_b outTypeB;
    replaceable type Type_b subtypeof Any;
  end FuncTypeType_aType_bToType_b;
  replaceable type Type_b subtypeof Any;
algorithm 
  outTypeB:=
  matchcontinue (inTypeALst,inFuncTypeTypeATypeBToTypeB,inTypeB)
    local
      FuncTypeType_aType_bToType_b r;
      Type_b b,b_1,b_2;
      Type_a l;
      list<Type_a> lst;
    case ({},r,b) then b; 
    case ((l :: lst),r,b)
      equation 
        b_1 = r(l, b);
        b_2 = listFold(lst, r, b_1);
      then
        b_2;
  end matchcontinue;
end listFold;

public function listFold_2 "function: listFold_2
  Similar to listFold but relation takes three arguments. 
  The first argument is folded (i.e. passed through each relation)
  The second argument is constant (given as argument)
  The third argument is iterated over list."
  input list<Type_a> lst;
  input FoldFunc foldFunc;
  input Type_b foldArg;
  input Type_c extraArg;
  output Type_b res;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  partial function FoldFunc
    input Type_b foldArg;
    input Type_c extraArg;
    input Type_a iterated;
    output Type_b foldArg;
  end FoldFunc;
algorithm 
  res:=
  matchcontinue (lst,foldFunc,foldArg,extraArg)
    local
      Type_b foldArg1,foldArg2;
      Type_a l;
      list<Type_a> lst;
    case ({},foldFunc,foldArg,extraArg) then foldArg; 
    case ((l :: lst),foldFunc,foldArg,extraArg)
      equation 
        foldArg1 = foldFunc(foldArg,extraArg,l);
        foldArg2 = listFold_2(lst, foldFunc,foldArg1, extraArg);
      then
        foldArg2;
  end matchcontinue;
end listFold_2;

public function listFold_2r "function: listFold_2
  Similar to listFold_2 but reversed argument order in function."
  input list<Type_a> lst;
  input FoldFunc foldFunc;
  input Type_b foldArg;
  input Type_c extraArg;
  output Type_b res;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  partial function FoldFunc
    input Type_b foldArg;
    input Type_a iterated;
    input Type_c extraArg;
    output Type_b foldArg;
  end FoldFunc;
algorithm 
  res:=
  matchcontinue (lst,foldFunc,foldArg,extraArg)
    local
      Type_b foldArg1,foldArg2;
      Type_a l;
      list<Type_a> lst;
    case ({},foldFunc,foldArg,extraArg) then foldArg; 
    case ((l :: lst),foldFunc,foldArg,extraArg)
      equation 
        foldArg1 = foldFunc(foldArg,l,extraArg);
        foldArg2 = listFold_2r(lst, foldFunc,foldArg1, extraArg);
      then
        foldArg2;
  end matchcontinue;
end listFold_2r;


public function listlistFoldMap "function: listlistFoldMap
  For example see Interactive.traverseExp."
  input list<list<Type_a>> inTypeALst;
  input FuncTypeTplType_aType_bToTplType_aType_b inFuncTypeTplTypeATypeBToTplTypeATypeB;
  input Type_b inTypeB;
  output list<list<Type_a>> outTypeALst;
  output Type_b outTypeB;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeTplType_aType_bToTplType_aType_b
    input tuple<Type_a, Type_b> inTplTypeATypeB;
    output tuple<Type_a, Type_b> outTplTypeATypeB;
    replaceable type Type_b subtypeof Any;
  end FuncTypeTplType_aType_bToTplType_aType_b;
  replaceable type Type_b subtypeof Any;
algorithm 
  (outTypeALst,outTypeB):=
  matchcontinue (inTypeALst,inFuncTypeTplTypeATypeBToTplTypeATypeB,inTypeB)
    local
      FuncTypeTplType_aType_bToTplType_aType_b rel;
      Type_b e_arg,b_1,b_2,b;
      list<Type_a> elt_1,elt;
      list<list<Type_a>> elts_1,elts;
    case ({},rel,e_arg) then ({},e_arg); 
    case ((elt :: elts),rel,b)
      equation 
        (elt_1,b_1) = listFoldMap(elt,rel,b);
        (elts_1,b_2) = listlistFoldMap(elts, rel, b_1);
      then
        ((elt_1 :: elts_1),b_2);
  end matchcontinue;
end listlistFoldMap;

public function listFoldMap "function: listFoldMap
  author: PA
  For example see Exp.traverseExp."
  input list<Type_a> inTypeALst;
  input FuncTypeTplType_aType_bToTplType_aType_b inFuncTypeTplTypeATypeBToTplTypeATypeB;
  input Type_b inTypeB;
  output list<Type_a> outTypeALst;
  output Type_b outTypeB;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeTplType_aType_bToTplType_aType_b
    input tuple<Type_a, Type_b> inTplTypeATypeB;
    output tuple<Type_a, Type_b> outTplTypeATypeB;
    replaceable type Type_b subtypeof Any;
  end FuncTypeTplType_aType_bToTplType_aType_b;
  replaceable type Type_b subtypeof Any;
algorithm 
  (outTypeALst,outTypeB):=
  matchcontinue (inTypeALst,inFuncTypeTplTypeATypeBToTplTypeATypeB,inTypeB)
    local
      FuncTypeTplType_aType_bToTplType_aType_b rel;
      Type_b e_arg,b_1,b_2,b;
      Type_a elt_1,elt;
      list<Type_a> elts_1,elts;
    case ({},rel,e_arg) then ({},e_arg); 
    case ((elt :: elts),rel,b)
      equation 
        ((elt_1,b_1)) = rel((elt,b));
        (elts_1,b_2) = listFoldMap(elts, rel, b_1);
      then
        ((elt_1 :: elts_1),b_2);
  end matchcontinue;
end listFoldMap;

public function listListReverse "function: listListReverse
  Takes a list of lists and reverses it at both 
  levels, i.e. both the list itself and each sublist
  Example: listListReverse({{1,2},{3,4,5},{6} }) => { {6}, {5,4,3}, {2,1} }"
  input list<list<Type_a>> lsts;
  output list<list<Type_a>> lsts_2;
  replaceable type Type_a subtypeof Any;
  list<list<Type_a>> lsts_1,lsts_2;
algorithm 
  lsts_1 := listMap(lsts, listReverse);
  lsts_2 := listReverse(lsts_1);
end listListReverse;

public function listThread "function: listThread
  Takes two lists of the same type and threads (interleaves) them togheter.
  Example: listThread({1,2,3},{4,5,6}) => {4,1,5,2,6,3}"
  input list<Type_a> inTypeALst1;
  input list<Type_a> inTypeALst2;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeALst1,inTypeALst2)
    local
      list<Type_a> r_1,c,d,ra,rb;
      Type_a fa,fb;
    case ({},{}) then {}; 
    case ((fa :: ra),(fb :: rb))
      equation 
        r_1 = listThread(ra, rb);
        c = (fb :: r_1);
        d = (fa :: c);
      then
        d;
  end matchcontinue;
end listThread;

public function listThread3 "function: listThread
  Takes three lists of the same type and threads (interleaves) them togheter.
  Example: listThread3({1,2,3},{4,5,6},{7,8,9}) => {7,4,1,8,5,2,9,6,3}"
  input list<Type_a> inTypeALst1;
  input list<Type_a> inTypeALst2;
  input list<Type_a> inTypeALst3;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeALst1,inTypeALst2,inTypeALst3)
    local
      list<Type_a> r_1,c,d,ra,rb,rc;
      Type_a fa,fb,fc;
    case ({},{},{}) then {}; 
    case ((fa :: ra),(fb :: rb),fc::rc)
      equation 
        r_1 = listThread3(ra, rb,rc);
      then
        fa::fb::fc::r_1;
  end matchcontinue;
end listThread3;

public function listThreadMap "function: listThreadMap
  Takes two lists and a function and threads (interleaves) and maps the elements of the two lists
  creating a new list.
  Example: listThreadMap({1,2},{3,4},intAdd) => {1+3, 2+4}"
  input list<Type_a> inTypeALst;
  input list<Type_b> inTypeBLst;
  input FuncTypeType_aType_bToType_c inFuncTypeTypeATypeBToTypeC;
  output list<Type_c> outTypeCLst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncTypeType_aType_bToType_c
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Type_c outTypeC;
    replaceable type Type_c subtypeof Any;
  end FuncTypeType_aType_bToType_c;
  replaceable type Type_c subtypeof Any;
algorithm 
  outTypeCLst:=
  matchcontinue (inTypeALst,inTypeBLst,inFuncTypeTypeATypeBToTypeC)
    local
      Type_c fr;
      list<Type_c> res;
      Type_a fa;
      list<Type_a> ra;
      Type_b fb;
      list<Type_b> rb;
      FuncTypeType_aType_bToType_c fn;
    case ({},{},_) then {}; 
    case ((fa :: ra),(fb :: rb),fn)
      equation 
        fr = fn(fa, fb);
        res = listThreadMap(ra, rb, fn);
      then
        (fr :: res);
  end matchcontinue;
end listThreadMap;

public function listListThreadMap "function: listListThreadMap
  Takes two lists of lists and a function and threads (interleaves) 
  and maps the elements  of the elements of the two lists creating a new list.
  Example: listListThreadMap({{1,2}},{{3,4}},int_add) => {{1+3, 2+4}}"
  input list<list<Type_a>> inTypeALst;
  input list<list<Type_b>> inTypeBLst;
  input FuncTypeType_aType_bToType_c inFuncTypeTypeATypeBToTypeC;
  output list<list<Type_c>> outTypeCLst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncTypeType_aType_bToType_c
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Type_c outTypeC;
    replaceable type Type_c subtypeof Any;
  end FuncTypeType_aType_bToType_c;
  replaceable type Type_c subtypeof Any;
algorithm 
  outTypeCLst:=
  matchcontinue (inTypeALst,inTypeBLst,inFuncTypeTypeATypeBToTypeC)
    local
      Type_c fr;
      list<Type_c> res;
      Type_a fa;
      list<Type_a> ra;
      Type_b fb;
      list<Type_b> rb;
      FuncTypeType_aType_bToType_c fn;
    case ({},{},_) then {}; 
    case ((fa :: ra),(fb :: rb),fn)
      equation 
        fr = listThreadMap(fa,fb,fn);
        res = listListThreadMap(ra, rb, fn);
      then
        (fr :: res);
  end matchcontinue;
end listListThreadMap;

public function listThreadTuple "function: listThreadTuple
  Takes two lists and threads (interleaves) the arguments into 
  a list of tuples consisting of the two element types.
  Example: listThreadTuple({1,2,3},{true,false,true}) => {(1,true),(2,false),(3,true)}"
  input list<Type_a> inTypeALst;
  input list<Type_b> inTypeBLst;
  output list<tuple<Type_a, Type_b>> outTplTypeATypeBLst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm 
  outTplTypeATypeBLst:=
  matchcontinue (inTypeALst,inTypeBLst)
    local
      list<tuple<Type_a, Type_b>> r;
      Type_a fa;
      list<Type_a> ra;
      Type_b fb;
      list<Type_b> rb;
    case ({},{}) then {}; 
    case ((fa :: ra),(fb :: rb))
      equation 
        r = listThreadTuple(ra, rb);
      then
        ((fa,fb) :: r);
  end matchcontinue;
end listThreadTuple;

public function listListThreadTuple "function: listListThreadTuple
  Takes two list of lists as arguments and produces a list of 
  lists of a two tuple of the element types of each list.
  Example:
    listListThreadTuple({{1},{2,3}},{{\"a\"},{\"b\",\"c\"}}) => { {(1,\"a\")},{(2,\"b\"),(3,\"c\")} }"
  input list<list<Type_a>> inTypeALstLst;
  input list<list<Type_b>> inTypeBLstLst;
  output list<list<tuple<Type_a, Type_b>>> outTplTypeATypeBLstLst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm 
  outTplTypeATypeBLstLst:=
  matchcontinue (inTypeALstLst,inTypeBLstLst)
    local
      list<tuple<Type_a, Type_b>> f;
      list<list<tuple<Type_a, Type_b>>> r;
      list<Type_a> fa;
      list<list<Type_a>> ra;
      list<Type_b> fb;
      list<list<Type_b>> rb;
    case ({},{}) then {}; 
    case ((fa :: ra),(fb :: rb))
      equation 
        f = listThreadTuple(fa, fb);
        r = listListThreadTuple(ra, rb);
      then
        (f :: r);
  end matchcontinue;
end listListThreadTuple;

public function listSelect "function: listSelect
  This function retrieves all elements of a list for which
  the passed function evaluates to true. The elements that 
  evaluates to false are thus removed from the list."
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToBoolean inFuncTypeTypeAToBoolean;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToBoolean
    input Type_a inTypeA;
    output Boolean outBoolean;
  end FuncTypeType_aToBoolean;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeALst,inFuncTypeTypeAToBoolean)
    local
      list<Type_a> xs_1,xs;
      Type_a x;
      FuncTypeType_aToBoolean cond;
    case ({},_) then {}; 
    case ((x :: xs),cond)
      equation 
        true = cond(x);
        xs_1 = listSelect(xs, cond);
      then
        (x :: xs_1);
    case ((x :: xs),cond)
      equation 
        false = cond(x);
        xs_1 = listSelect(xs, cond);
      then
        xs_1;
  end matchcontinue;
end listSelect;

public function listSelect1 "function listSelect1
  Same as listSelect above, but with extra argument to testing function."
  input list<Type_a> inTypeALst;
  input Type_b inTypeB;
  input FuncTypeType_aType_bToBoolean inFuncTypeTypeATypeBToBoolean;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncTypeType_aType_bToBoolean
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Boolean outBoolean;
  end FuncTypeType_aType_bToBoolean;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeALst,inTypeB,inFuncTypeTypeATypeBToBoolean)
    local
      Type_b arg;
      list<Type_a> xs_1,xs;
      Type_a x;
      FuncTypeType_aType_bToBoolean cond;
    case ({},arg,_) then {}; 
    case ((x :: xs),arg,cond)
      equation 
        true = cond(x, arg);
        xs_1 = listSelect1(xs, arg, cond);
      then
        (x :: xs_1);
    case ((x :: xs),arg,cond)
      equation 
        false = cond(x, arg);
        xs_1 = listSelect1(xs, arg, cond);
      then
        xs_1;
  end matchcontinue;
end listSelect1;

public function listSelect2 "function listSelect1
  Same as listSelect above, but with extra argument to testing function."
  input list<Type_a> inTypeALst;
  input Type_b inTypeB;
  input Type_c inTypeC;
  input FuncTypeType_aType_bToBoolean inFuncTypeTypeATypeBToBoolean;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;  
  partial function FuncTypeType_aType_bToBoolean
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeB;
    output Boolean outBoolean;
  end FuncTypeType_aType_bToBoolean;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeALst,inTypeB,inTypeC,inFuncTypeTypeATypeBToBoolean)
    local
      Type_b arg1; Type_c arg2;
      list<Type_a> xs_1,xs;
      Type_a x;
      FuncTypeType_aType_bToBoolean cond;
    case ({},arg1,arg2,_) then {}; 
    case ((x :: xs),arg1,arg2,cond)
      equation 
        true = cond(x, arg1,arg2);
        xs_1 = listSelect2(xs, arg1,arg2, cond);
      then
        (x :: xs_1);
    case ((x :: xs),arg1,arg2,cond)
      equation 
        false = cond(x, arg1,arg2);
        xs_1 = listSelect2(xs, arg1,arg2, cond);
      then
        xs_1;
  end matchcontinue;
end listSelect2;

public function listSelect1R "function listSelect1R
  Same as listSelect1 above, but with swapped arguments."
  input list<Type_a> inTypeALst;
  input Type_b inTypeB;
  input FuncTypeType_bType_aToBoolean inFuncTypeTypeBTypeAToBoolean;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncTypeType_bType_aToBoolean
    input Type_b inTypeB;
    input Type_a inTypeA;
    output Boolean outBoolean;
  end FuncTypeType_bType_aToBoolean;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeALst,inTypeB,inFuncTypeTypeBTypeAToBoolean)
    local
      Type_b arg;
      list<Type_a> xs_1,xs;
      Type_a x;
      FuncTypeType_bType_aToBoolean cond;
    case ({},arg,_) then {}; 
    case ((x :: xs),arg,cond)
      equation 
        true = cond(arg, x);
        xs_1 = listSelect1R(xs, arg, cond);
      then
        (x :: xs_1);
    case ((x :: xs),arg,cond)
      equation 
        false = cond(arg, x);
        xs_1 = listSelect1R(xs, arg, cond);
      then
        xs_1;
  end matchcontinue;
end listSelect1R;

public function listPosition "function: listPosition
  Takes a value and a list of values and returns the (first) position
  the value has in the list. Position index start at zero, such that 
  listNth can be used on the resulting position directly.
  Example: listPosition(2,{0,1,2,3}) => 2"
  input Type_a x;
  input list<Type_a> ys;
  output Integer n;
  replaceable type Type_a subtypeof Any;
algorithm 
  n := listPos(x, ys, 0);
end listPosition;

protected function listPos "helper function to listPosition"
  input Type_a inTypeA;
  input list<Type_a> inTypeALst;
  input Integer inInteger;
  output Integer outInteger;
  replaceable type Type_a subtypeof Any;
algorithm 
  outInteger:=
  matchcontinue (inTypeA,inTypeALst,inInteger)
    local
      Type_a x,y,i;
      list<Type_a> ys;
      Integer i_1,n;
    case (x,(y :: ys),i)
      equation 
        equality(x = y);
      then
        i;
    case (x,(y :: ys),i)
      local Integer i;
      equation 
        failure(equality(x = y));
        i_1 = i + 1;
        n = listPos(x, ys, i_1);
      then
        n;
  end matchcontinue;
end listPos;

public function listGetMember "function: listGetMember
  Takes a value and a list of values and returns the value 
  if present in the list. If not present, the function will fail.
  Example:
    listGetMember(0,{1,2,3}) => fail
    listGetMember(1,{1,2,3}) => 1"
  input Type_a inTypeA;
  input list<Type_a> inTypeALst;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeA:=
  matchcontinue (inTypeA,inTypeALst)
    local
      Type_a x,y,res;
      list<Type_a> ys;
    case (_,{}) then fail(); 
    case (x,(y :: ys))
      equation 
        equality(x = y);
      then
        y;
    case (x,(y :: ys))
      equation 
        failure(equality(x = y));
        res = listGetMember(x, ys);
      then
        res;
  end matchcontinue;
end listGetMember;

public function listDeleteMember "function: listDeleteMember
  Takes a list and a value and deletes the first occurence of the value in the list
  Example: listDeleteMember({1,2,3,2},2) => {1,3,2}"
  input list<Type_a> inTypeALst;
  input Type_a inTypeA;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeALst,inTypeA)
    local
      Integer pos;
      list<Type_a> lst_1,lst;
      Type_a elt;
    case (lst,elt)
      equation 
        pos = listPosition(elt, lst);
        lst_1 = listDelete(lst, pos);
      then
        lst_1;
    case (lst,_) then lst; 
  end matchcontinue;
end listDeleteMember;

public function listDeleteMemberOnTrue "function: listDeleteMemberOnTrue
  Takes a list and a value and a comparison function and deletes the first 
  occurence of the value in the list for which the function returns true.
  Example: listDeleteMemberOnTrue({1,2,3,2},2,intEq) => {1,3,2}"
  input list<Type_a> inTypeALst;
  input Type_a inTypeA;
  input FuncTypeType_aType_aToBoolean inFuncTypeTypeATypeAToBoolean;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_aToBoolean
    input Type_a inTypeA1;
    input Type_a inTypeA2;
    output Boolean outBoolean;
  end FuncTypeType_aType_aToBoolean;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeALst,inTypeA,inFuncTypeTypeATypeAToBoolean)
    local
      Type_a elt_1,elt;
      Integer pos;
      list<Type_a> lst_1,lst;
      FuncTypeType_aType_aToBoolean cond;
    case (lst,elt,cond)
      equation 
        elt_1 = listGetMemberOnTrue(elt, lst, cond) "A bit ugly" ;
        pos = listPosition(elt_1, lst);
        lst_1 = listDelete(lst, pos);
      then
        lst_1;
    case (lst,_,_) then lst; 
  end matchcontinue;
end listDeleteMemberOnTrue;

public function listGetMemberOnTrue "function listGetmemberOnTrue
  Takes a value and a list of values and a comparison function over two values.
  If the value is present in the list (using the comparison function returning true)
  the value is returned, otherwise the function fails.
  Example:
    function equalLength(string,string) returns true if the strings are of same length
    listGetMemberOnTrue(\"a\",{\"bb\",\"b\",\"ccc\"},equalLength) => \"b\""
  input Type_a inTypeA;
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_aToBoolean inFuncTypeTypeATypeAToBoolean;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_aToBoolean
    input Type_a inTypeA1;
    input Type_a inTypeA2;
    output Boolean outBoolean;
  end FuncTypeType_aType_aToBoolean;
algorithm 
  outTypeA:=
  matchcontinue (inTypeA,inTypeALst,inFuncTypeTypeATypeAToBoolean)
    local
      FuncTypeType_aType_aToBoolean p;
      Type_a x,y,res;
      list<Type_a> ys;
    case (_,{},p) then fail(); 
    case (x,(y :: ys),p)
      equation 
        true = p(x, y);
      then
        y;
    case (x,(y :: ys),p)
      equation 
        false = p(x, y);
        res = listGetMemberOnTrue(x, ys, p);
      then
        res;
  end matchcontinue;
end listGetMemberOnTrue;

public function listUnionElt "function: listUnionElt
  Takes a value and a list of values and inserts the 
  value into the list if it is not already in the list.
  If it is in the list it is not inserted.
  Example:
    listUnionElt(1,{2,3}) => {1,2,3}
    listUnionElt(0,{0,1,2}) => {0,1,2}"
  input Type_a inTypeA;
  input list<Type_a> inTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeA,inTypeALst)
    local
      Type_a x;
      list<Type_a> lst;
    case (x,lst)
      equation 
        _ = listGetMember(x, lst);
      then
        lst;
    case (x,lst)
      equation 
        failure(_ = listGetMember(x, lst));
      then
        (x :: lst);
  end matchcontinue;
end listUnionElt;

public function listUnion "function listUnion
  Takes two lists and returns the union of the two lists, 
  i.e. a list of all elements combined without duplicates.
  Example: listUnion({0,1},{2,1}) => {0,1,2}"
  input list<Type_a> inTypeALst1;
  input list<Type_a> inTypeALst2;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeALst1,inTypeALst2)
    local
      list<Type_a> res,r1,xs,lst2;
      Type_a x;
    case ({},{}) then {};
    case ({},x::xs) then listUnionElt(x,listUnion({},xs)); 
    case ((x :: xs),lst2)
      equation 
        r1 = listUnionElt(x, lst2);
        res = listUnion(xs, r1);
      then
        res;
  end matchcontinue;
end listUnion;

public function listListUnion "function: listListUnion
  Takes a list of lists and returns the union of the sublists
  Example: listListUnion({{1},{1,2},{3,4},{5}}) => {1,2,3,4,5}"
  input list<list<Type_a>> inTypeALstLst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeALstLst)
    local
      list<Type_a> x,r1,res,x1,x2;
      list<list<Type_a>> rest;
    case ({}) then {}; 
    case ({x}) then x; 
    case ((x1 :: (x2 :: rest)))
      equation 
        r1 = listUnion(x1, x2);
        res = listListUnion((r1 :: rest));
      then
        res;
  end matchcontinue;
end listListUnion;

public function listUnionEltOnTrue "function: listUnionEltOnTrue
  Takes an elemement and a list and a comparison function over the two values.
  It returns the list with the element inserted if not already present in the
  list, according to the comparison function.
  Example: listUnionEltOnTrue(1,{2,3},intEq) => {1,2,3}"
  input Type_a inTypeA;
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_aToBoolean inFuncTypeTypeATypeAToBoolean;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_aToBoolean
    input Type_a inTypeA1;
    input Type_a inTypeA2;
    output Boolean outBoolean;
  end FuncTypeType_aType_aToBoolean;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeA,inTypeALst,inFuncTypeTypeATypeAToBoolean)
    local
      Type_a x;
      list<Type_a> lst;
      FuncTypeType_aType_aToBoolean p;
    case (x,lst,p)
      equation 
        _ = listGetMemberOnTrue(x, lst, p);
      then
        lst;
    case (x,lst,p)
      equation 
        failure(_ = listGetMemberOnTrue(x, lst, p));
      then
        (x :: lst);
  end matchcontinue;
end listUnionEltOnTrue;

public function listUnionOnTrue "function: listUnionOnTrue
  Takes two lists and a comparison function over two elements of the list.
  It returns the union of the two lists, using the comparison function passed 
  as argument to determine identity between two elements.
  Example:
    given the function equalLength(string,string) returning true if the strings are of same length
    listUnionOnTrue({\"a\",\"aa\"},{\"b\",\"bbb\"},equalLength) => {\"a\",\"aa\",\"bbb\"}"
  input list<Type_a> inTypeALst1;
  input list<Type_a> inTypeALst2;
  input FuncTypeType_aType_aToBoolean inFuncTypeTypeATypeAToBoolean3;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_aToBoolean
    input Type_a inTypeA1;
    input Type_a inTypeA2;
    output Boolean outBoolean;
  end FuncTypeType_aType_aToBoolean;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeALst1,inTypeALst2,inFuncTypeTypeATypeAToBoolean3)
    local
      list<Type_a> res,r1,xs,lst2;
      FuncTypeType_aType_aToBoolean p;
      Type_a x;
    case ({},res,p) then res; 
    case ((x :: xs),lst2,p)
      equation 
        r1 = listUnionEltOnTrue(x, lst2, p);
        res = listUnionOnTrue(xs, r1, p);
      then
        res;
  end matchcontinue;
end listUnionOnTrue;

public function listIntersectionOnTrue "function: listIntersectionOnTrue
  Takes two lists and a comparison function over two elements of the list.
  It returns the intersection of the two lists, using the comparison function passed as 
  argument to determine identity between two elements.
  Example:
    given the function stringEqual(string,string) returning true if the strings are equal
    listIntersectionOnTrue({\"a\",\"aa\"},{\"b\",\"aa\"},stringEqual) => {\"aa\"}"
  input list<Type_a> inTypeALst1;
  input list<Type_a> inTypeALst2;
  input FuncTypeType_aType_aToBoolean inFuncTypeTypeATypeAToBoolean3;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_aToBoolean
    input Type_a inTypeA1;
    input Type_a inTypeA2;
    output Boolean outBoolean;
  end FuncTypeType_aType_aToBoolean;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeALst1,inTypeALst2,inFuncTypeTypeATypeAToBoolean3)
    local
      list<Type_a> res,xs1,xs2;
      Type_a x1;
      FuncTypeType_aType_aToBoolean cond;
    case ({},_,_) then {}; 
    case ((x1 :: xs1),xs2,cond)
      equation 
        _ = listGetMemberOnTrue(x1, xs2, cond);
        res = listIntersectionOnTrue(xs1, xs2, cond);
      then
        (x1 :: res);
    case ((x1 :: xs1),xs2,cond)
      equation 
        res = listIntersectionOnTrue(xs1, xs2, cond) "not list_getmember_p(x1,xs2,cond) => _" ;
      then
        res;
  end matchcontinue;
end listIntersectionOnTrue;

public function listSetEqualOnTrue "function: listSetEqualOnTrue
  Takes two lists and a comparison function over two elements of the list.
  It returns true if the two sets are equal, false otherwise."
  input list<Type_a> lst1;
  input list<Type_a> lst2;
  input CompareFunc compare;
  output Boolean equal;
  replaceable type Type_a subtypeof Any;
  partial function CompareFunc
    input Type_a inTypeA1;
    input Type_a inTypeA2;
    output Boolean outBoolean;
  end CompareFunc;
algorithm 
   equal := matchcontinue(lst1,lst2,compare)
     case (lst1,lst2,compare) 
       local list<Type_a> lst;
       equation
       	lst = listIntersectionOnTrue(lst1,lst2,compare);
       	true = intEq(listLength(lst), listLength(lst1));
       	true = intEq(listLength(lst), listLength(lst2));
       then true;
     case (_,_,_) then false;
  end matchcontinue;
end listSetEqualOnTrue;

public function listSetDifferenceOnTrue "function: listSetDifferenceOnTrue
  Takes two lists and a comparison function over two elements of the list.
  It returns the set difference of the two lists A-B, using the comparison 
  function passed as argument to determine identity between two elements.
  Example:
    given the function string_equal(string,string) returning true if the strings are equal
    listSetDifferenceOnTrue({\"a\",\"b\",\"c\"},{\"a\",\"c\"},string_equal) => {\"b\"}"
  input list<Type_a> inTypeALst1;
  input list<Type_a> inTypeALst2;
  input FuncTypeType_aType_aToBoolean inFuncTypeTypeATypeAToBoolean3;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_aToBoolean
    input Type_a inTypeA1;
    input Type_a inTypeA2;
    output Boolean outBoolean;
  end FuncTypeType_aType_aToBoolean;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeALst1,inTypeALst2,inFuncTypeTypeATypeAToBoolean3)
    local
      list<Type_a> a,a_1,a_2,xs;
      FuncTypeType_aType_aToBoolean cond;
      Type_a x1;
    case (a,{},cond) then a;  /* A B */ 
    case (a,(x1 :: xs),cond)
      equation 
        a_1 = listDeleteMemberOnTrue(a, x1, cond);
        a_2 = listSetDifferenceOnTrue(a_1, xs, cond);
      then
        a_2;
    case (_,_,_)
      equation 
        print("- Util.listSetDifferenceOnTrue failed\n");
      then
        fail();
  end matchcontinue;
end listSetDifferenceOnTrue;

public function listListUnionOnTrue "function: listListUnionOnTrue
  Takes a list of lists and a comparison function over two elements of the lists.
  It returns the union of all sublists using the comparison function for identity.
  Example: listListUnionOnTrue({{1},{1,2},{3,4}},intEq) => {1,2,3,4}"
  input list<list<Type_a>> inTypeALstLst;
  input FuncTypeType_aType_aToBoolean inFuncTypeTypeATypeAToBoolean;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_aToBoolean
    input Type_a inTypeA1;
    input Type_a inTypeA2;
    output Boolean outBoolean;
  end FuncTypeType_aType_aToBoolean;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeALstLst,inFuncTypeTypeATypeAToBoolean)
    local
      FuncTypeType_aType_aToBoolean p;
      list<Type_a> x,r1,res,x1,x2;
      list<list<Type_a>> rest;
    case ({},p) then {}; 
    case ({x},p) then x; 
    case ((x1 :: (x2 :: rest)),p)
      equation 
        r1 = listUnionOnTrue(x1, x2, p);
        res = listListUnionOnTrue((r1 :: rest), p);
      then
        res;
  end matchcontinue;
end listListUnionOnTrue;

public function listReplaceAt "function: listReplaceAt
  Takes an element, a position and a list and replaces the value at the given position in 
  the list. Position is an integer between 0 and n-1 for a list of n elements
  Example: listReplaceAt(\"A\", 2, {\"a\",\"b\",\"c\"}) => {\"a\",\"b\",\"A\"}"
  input Type_a inTypeA;
  input Integer inInteger;
  input list<Type_a> inTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeA,inInteger,inTypeALst)
    local
      Type_a x,y;
      list<Type_a> ys,res;
      Integer nn,n;
    case (x,0,(y :: ys)) then (x :: ys);
    case (x,n,(y :: ys))  
      equation 
        (n >= 1) = true;
        nn = n - 1;
        res = listReplaceAt(x, nn, ys);
      then
        (y :: res);
  end matchcontinue;
end listReplaceAt;

public function listReplaceAtWithFill "function: listReplaceatWithFill
  Takes 
  - an element, 
  - a position 
  - a list and 
  - a fill value 
  The function replaces the value at the given position in the list, if the given position is 
  out of range, the fill value is used to padd the list up to that element position and then
  insert the value at the position
  Example: listReplaceAtWithFill(\"A\", 5, {\"a\",\"b\",\"c\"},\"dummy\") => {\"a\",\"b\",\"c\",\"dummy\",\"A\"}"
  input Type_a inTypeA1;
  input Integer inInteger2;
  input list<Type_a> inTypeALst3;
  input Type_a inTypeA4;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeA1,inInteger2,inTypeALst3,inTypeA4)
    local
      Type_a x,fillv,y;
      list<Type_a> ys,res,res_1;
      Integer numfills_1,numfills,nn,n,p;
      String pos;
    case (x,0,{},fillv) then {x}; 
    case (x,0,(y :: ys),fillv) then (x :: ys); 
    case (x,1,{},fillv) then {fillv,x}; 
    case (x,numfills,{},fillv)
      equation 
        (numfills > 1) = true;
        numfills_1 = numfills - 1;
        res = listFill(fillv, numfills_1);
        res_1 = listAppend(res, {x});
      then
        res_1;
    case (x,n,(y :: ys),fillv)
      equation 
        (n >= 1) = true;
        nn = n - 1;
        res = listReplaceAtWithFill(x, nn, ys, fillv);
      then
        (y :: res);
    case (_,p,_,_)
      equation 
        print("- Util.listReplaceAtWithFill failed row: ");
        pos = intString(p);
        print(pos);
        print("\n");
      then
        fail();
  end matchcontinue;
end listReplaceAtWithFill;

public function listReduce "function: listReduce
  Takes a list and a function operating on two elements of the list.
  The function performs a reduction of the lists to a single value using the function.
  Example: listReduce({1,2,3},int_add) => 6"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_aToType_a inFuncTypeTypeATypeAToTypeA;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_aToType_a
    input Type_a inTypeA1;
    input Type_a inTypeA2;
    output Type_a outTypeA;
  end FuncTypeType_aType_aToType_a;
algorithm 
  outTypeA:=
  matchcontinue (inTypeALst,inFuncTypeTypeATypeAToTypeA)
    local
      Type_a e,res,a,b,res1,res2;
      FuncTypeType_aType_aToType_a r;
      list<Type_a> xs;
    case ({e},r) then e; 
    case ({a,b},r)
      equation 
        res = r(a, b);
      then
        res;
    case ((a :: (b :: (xs as (_ :: _)))),r)
      equation 
        res1 = r(a, b);
        res = listReduce_tail(xs, r, res1);
      then
        res;
  end matchcontinue;
end listReduce;


public function listReduce_tail 
"function: listReduce_tail
 Takes a list and a function operating on two elements of the list and an accumulator value.
 The function performs a reduction of the lists to a single value using the function.
 Example: listReduce_tail({1,2,3},int_add, 0) => 6"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_aToType_a inFuncTypeTypeATypeAToTypeA;
  input Type_a accumulator;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_aToType_a
    input Type_a inTypeA1;
    input Type_a inTypeA2;
    output Type_a outTypeA;
  end FuncTypeType_aType_aToType_a;
algorithm 
  outTypeA:=
  matchcontinue (inTypeALst,inFuncTypeTypeATypeAToTypeA,accumulator)
    local
      Type_a e,res,a,b,res1,res2;
      FuncTypeType_aType_aToType_a r;
      list<Type_a> xs;
    case ({},r,accumulator) then accumulator;
    case ({a},r,accumulator)
      equation 
        res = r(accumulator, a);
      then
        res;
    case (a::xs,r,accumulator)
      equation 
        res1 = r(accumulator, a);
        res = listReduce_tail(xs, r, res1);
      then
        res;
  end matchcontinue;
end listReduce_tail;


public function arrayReplaceAtWithFill "function: arrayReplaceAtWithFill
  Takes 
  - an element, 
  - a position 
  - an array and 
  - a fill value 
  The function replaces the value at the given position in the array, if the given position is 
  out of range, the fill value is used to padd the array up to that element position and then
  insert the value at the position.
  Example:
    arrayReplaceAtWithFill(\"A\", 5, {\"a\",\"b\",\"c\"},\"dummy\") => {\"a\",\"b\",\"c\",\"dummy\",\"A\"}"
  input Type_a inTypeA1;
  input Integer inInteger2;
  input Type_a[:] inTypeAArray3;
  input Type_a inTypeA4;
  output Type_a[:] outTypeAArray;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeAArray:=
  matchcontinue (inTypeA1,inInteger2,inTypeAArray3,inTypeA4)
    local
      Integer alen,pos,pos_1;
      Type_a[:] res,arr,newarr,res_1;
      Type_a x,fillv;
    case (x,pos,arr,fillv)
      equation 
        alen = arrayLength(arr) "Replacing element with index in range of the array" ;
        (pos < alen) = true;
        res = arrayUpdate(arr, pos + 1, x);
      then
        res;
    case (x,pos,arr,fillv)
      equation 
        pos_1 = pos + 1 "Replacing element out of range of array, create new array, and copy elts." ;
        newarr = fill(fillv, pos_1);
        res = arrayCopy(arr, newarr);
        res_1 = arrayUpdate(res, pos + 1, x);
      then
        res_1;
    case (_,_,_,_)
      equation 
        print("- Util.arrayReplaceAtWithFill failed\n");
      then
        fail();
  end matchcontinue;
end arrayReplaceAtWithFill;

public function arrayExpand "function: arrayExpand
  Increases the number of elements of a list with n.
  Each of the new elements have the value v."
  input Integer n;
  input Type_a[:] arr;
  input Type_a v;
  output Type_a[:] newarr_1;
  replaceable type Type_a subtypeof Any;
  Integer len,newlen;
  Type_a[:] newarr,newarr_1;
algorithm 
  len := arrayLength(arr);
  newlen := n + len;
  newarr := fill(v, newlen);
  newarr_1 := arrayCopy(arr, newarr);
end arrayExpand;

public function arrayNCopy "function arrayNCopy
  Copeis n elements in src array into dest array
  The function fails if all elements can not be fit into dest array."
  input Type_a[:] src;
  input Type_a[:] dst;
  input Integer n;
  output Type_a[:] dst_1;
  replaceable type Type_a subtypeof Any;
  Integer n_1;
  Type_a[:] dst_1;
algorithm 
  n_1 := n - 1;
  dst_1 := arrayCopy2(src, dst, n_1);
end arrayNCopy;

public function arrayCopy "function: arrayCopy
  copies all values in src array into dest array.
  The function fails if all elements can not be fit into dest array."
  input Type_a[:] inTypeAArray1;
  input Type_a[:] inTypeAArray2;
  output Type_a[:] outTypeAArray;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeAArray:=
  matchcontinue (inTypeAArray1,inTypeAArray2)
    local
      Integer srclen,dstlen;
      Type_a[:] src,dst,dst_1;
    case (src,dst) /* src dst */ 
      equation 
        srclen = arrayLength(src);
        dstlen = arrayLength(dst);
        (srclen > dstlen) = true;
        print(
          "- Util.arrayCopy failed. Can not fit elements into dest array\n");
      then
        fail();
    case (src,dst)
      equation 
        srclen = arrayLength(src);
        srclen = srclen - 1;
        dst_1 = arrayCopy2(src, dst, srclen);
      then
        dst_1;
  end matchcontinue;
end arrayCopy;

protected function arrayCopy2
  input Type_a[:] inTypeAArray1;
  input Type_a[:] inTypeAArray2;
  input Integer inInteger3;
  output Type_a[:] outTypeAArray;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeAArray:=
  matchcontinue (inTypeAArray1,inTypeAArray2,inInteger3)
    local
      Type_a[:] src,dst,dst_1,dst_2;
      Type_a elt;
      Integer pos;
    case (src,dst,-1) then dst;  /* src dst current pos */ 
    case (src,dst,pos)
      equation 
        elt = src[pos + 1];
        dst_1 = arrayUpdate(dst, pos + 1, elt);
        pos = pos - 1;
        dst_2 = arrayCopy2(src, dst_1, pos);
      then
        dst_2;
  end matchcontinue;
end arrayCopy2;

public function tuple21 "function: tuple21
  Takes a tuple of two values and returns the first value.
  Example: tuple21((\"a\",1)) => \"a\""
  input tuple<Type_a, Type_b> inTplTypeATypeB;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm 
  outTypeA:=
  matchcontinue (inTplTypeATypeB)
    local Type_a a;
    case ((a,_)) then a; 
  end matchcontinue;
end tuple21;

public function tuple22 "function: tuple22
  Takes a tuple of two values and returns the second value.
  Example: tuple22((\"a\",1)) => 1"
  input tuple<Type_a, Type_b> inTplTypeATypeB;
  output Type_b outTypeB;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm 
  outTypeB:=
  matchcontinue (inTplTypeATypeB)
    local Type_b b;
    case ((_,b)) then b; 
  end matchcontinue;
end tuple22;

public function splitTuple2List "function: splitTuple2List
  Takes a list of two-tuples and splits it into two lists.
  Example: splitTuple2List({(\"a\",1),(\"b\",2),(\"c\",3)}) => ({\"a\",\"b\",\"c\"}, {1,2,3})"
  input list<tuple<Type_a, Type_b>> inTplTypeATypeBLst;
  output list<Type_a> outTypeALst;
  output list<Type_b> outTypeBLst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm 
  (outTypeALst,outTypeBLst):=
  matchcontinue (inTplTypeATypeBLst)
    local
      list<Type_a> xs;
      list<Type_b> ys;
      Type_a x;
      Type_b y;
      list<tuple<Type_a, Type_b>> rest;
    case ({}) then ({},{}); 
    case (((x,y) :: rest))
      equation 
        (xs,ys) = splitTuple2List(rest);
      then
        ((x :: xs),(y :: ys));
  end matchcontinue;
end splitTuple2List;

public function if_ "function: if_
  Takes a boolean and two values.
  Returns the first value (second argument) if the boolean value is 
  true, otherwise the second value (third argument) is returned.
  Example: if_(true,\"a\",\"b\") => \"a\"
"
  input Boolean inBoolean1;
  input Type_a inTypeA2;
  input Type_a inTypeA3;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeA:=
  matchcontinue (inBoolean1,inTypeA2,inTypeA3)
    local Type_a r;
    case (true,r,_) then r; 
    case (false,_,r) then r; 
  end matchcontinue;
end if_;

public function stringContainsChar "Returns true if a string contains a specified character"
  input String str;
  input String char;
  output Boolean res;
algorithm
  res := matchcontinue(str,char)
    case(str,char) equation
      _::_::_ = stringSplitAtChar(str,char);
      then true;
    case(str,char) then false;
  end matchcontinue;
end stringContainsChar;

public function stringAppendList "function stringAppendList
  Takes a list of strings and appends them.
  Example: stringAppendList({\"foo\", \" \", \"bar\"}) => \"foo bar\""
  input list<String> inStringLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inStringLst)
    local
      String f,r_1,str;
      list<String> r;
    case {} then ""; 
    case {f} then f; 
    case (f :: r)
      equation 
        r_1 = stringAppendList(r);
        str = stringAppend(f, r_1);
      then
        str;
  end matchcontinue;
end stringAppendList;

public function stringDelimitList "function stringDelimitList
  Takes a list of strings and a string delimiter and appends all 
  list elements with the string delimiter inserted between elements.
  Example: stringDelimitList({\"x\",\"y\",\"z\"}, \", \") => \"x, y, z\""
  input list<String> inStringLst;
  input String inString;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inStringLst,inString)
    local
      String f,delim,str1,str2,str;
      list<String> r;
    case ({},_) then ""; 
    case ({f},delim) then f; 
    case ((f :: r),delim)
      equation 
        str1 = stringDelimitList(r, delim);
        str2 = stringAppend(f, delim);
        str = stringAppend(str2, str1);
      then
        str;
  end matchcontinue;
end stringDelimitList;

public function stringDelimitListAndSeparate "function: stringDelimitListAndSeparate
  author: PA
  This function is similar to stringDelimitList, i.e it inserts string delimiters between 
  consecutive strings in a list. But it also count the lists and inserts a second string delimiter
  when the counter is reached. This can be used when for instance outputting large lists of values
  and a newline is needed after ten or so items."
  input list<String> str;
  input String sep1;
  input String sep2;
  input Integer n;
  output String res;
algorithm 
  res := stringDelimitListAndSeparate2(str, sep1, sep2, n, 0);
end stringDelimitListAndSeparate;

protected function stringDelimitListAndSeparate2 "function: stringDelimitListAndSeparate2
  author: PA
  Helper function to stringDelimitListAndSeparate"
  input list<String> inStringLst1;
  input String inString2;
  input String inString3;
  input Integer inInteger4;
  input Integer inInteger5;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inStringLst1,inString2,inString3,inInteger4,inInteger5)
    local
      String s,str1,str,f,sep1,sep2;
      list<String> r;
      Integer n,iter_1,iter;
    case ({},_,_,_,_) then "";  /* iterator */ 
    case ({s},_,_,_,_) then s; 
    case ((f :: r),sep1,sep2,n,0)
      equation 
        str1 = stringDelimitListAndSeparate2(r, sep1, sep2, n, 1) "special case for first element" ;
        str = stringAppendList({f,sep1,str1});
      then
        str;
    case ((f :: r),sep1,sep2,n,iter)
      equation 
        0 = intMod(iter, n) "insert second delimiter" ;
        iter_1 = iter + 1;
        str1 = stringDelimitListAndSeparate2(r, sep1, sep2, n, iter_1);
        str = stringAppendList({f,sep1,sep2,str1});
      then
        str;
    case ((f :: r),sep1,sep2,n,iter)
      equation 
        iter_1 = iter + 1 "not inserting second delimiter" ;
        str1 = stringDelimitListAndSeparate2(r, sep1, sep2, n, iter_1);
        str = stringAppendList({f,sep1,str1});
      then
        str;
    case (_,_,_,_,_)
      equation 
        print("- Util.stringDelimitListAndSeparate2 failed\n");
      then
        fail();
  end matchcontinue;
end stringDelimitListAndSeparate2;

public function stringDelimitListNonEmptyElts "function stringDelimitListNonEmptyElts
  Takes a list of strings and a string delimiter and appends all list elements with
  the string delimiter inserted between those elements that are not empty.
  Example: stringDelimitListNonEmptyElts({\"x\",\"\",\"z\"}, \", \") => \"x, z\""
  input list<String> lst;
  input String delim;
  output String str;
  list<String> lst1;
algorithm 
  lst1 := listSelect(lst, isNotEmptyString);
  str := stringDelimitList(lst1, delim);
end stringDelimitListNonEmptyElts;

public function stringReplaceChar "function stringReplaceChar
  Takes a string and two chars and replaces the first char with the second char:
  Example: string_replace_char(\"hej.b.c\",\".\",\"_\") => \"hej_b_c\""
  input String inString1;
  input String inString2;
  input String inString3;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inString1,inString2,inString3)
    local
      list<String> strList,resList;
      String res,str;
      String fromChar,toChar;
    case (str,fromChar,toChar)
      equation 
        strList = string_list_string_char(str);
        resList = stringReplaceChar2(strList, fromChar, toChar);
        res = string_char_list_string(resList);
      then
        res;
    case (strList,_,_)
      local String strList;
      equation 
        print("- Util.stringReplaceChar failed\n");
      then
        strList;
  end matchcontinue;
end stringReplaceChar;

protected function stringReplaceChar2
  input list<String> inStringLst1;
  input String inString2;
  input String inString3;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inStringLst1,inString2,inString3)
    local
      list<String> res,rest,strList;
      String firstChar,fromChar,toChar;
    case ({},_,_) then {}; 
    case ((firstChar :: rest),fromChar,toChar)
      equation 
        equality(firstChar = fromChar);
        res = stringReplaceChar2(rest, fromChar, toChar);
      then
        (toChar :: res);
    case ((firstChar :: rest),fromChar,toChar)
      equation 
        failure(equality(firstChar = fromChar));
        res = stringReplaceChar2(rest, fromChar, toChar);
      then
        (firstChar :: res);
    case (strList,_,_)
      equation 
        print("- Util.stringReplaceChar2 failed\n");
      then
        strList;
  end matchcontinue;
end stringReplaceChar2;

public function stringSplitAtChar "function stringSplitAtChar
  Takes a string and a char and split the string at the char returning the list of components.
  Example: stringSplitAtChar(\"hej.b.c\",\".\") => {\"hej,\"b\",\"c\"}"
  input String inString1;
  input String inString2;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inString1,inString2)
    local
      list<String> chrList;
      list<String> stringList;
      String str,strList;
      String chr;
    case (str,chr)
      equation 
        chrList = string_list_string_char(str);
        stringList = stringSplitAtChar2(chrList, chr, {}) "listString(resList) => res" ;
      then
        stringList;
    case (strList,_) then {strList}; 
  end matchcontinue;
end stringSplitAtChar;

protected function stringSplitAtChar2
  input list<String> inStringLst1;
  input String inString2;
  input list<String> inStringLst3;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inStringLst1,inString2,inStringLst3)
    local
      list<String> chr_rest_1,chr_rest,chrList,rest,strList;
      String res;
      list<String> res_str;
      String firstChar,chr;
    case ({},_,chr_rest)
      equation 
        chr_rest_1 = listReverse(chr_rest);
        res = string_char_list_string(chr_rest_1);
      then
        {res};
    case ((firstChar :: rest),chr,chr_rest)
      equation 
        equality(firstChar = chr);
        chrList = listReverse(chr_rest) "this is needed because it returns the reversed list" ;
        res = string_char_list_string(chrList);
        res_str = stringSplitAtChar2(rest, chr, {});
      then
        (res :: res_str);
    case ((firstChar :: rest),chr,chr_rest)
      local list<String> res;
      equation 
        failure(equality(firstChar = chr));
        res = stringSplitAtChar2(rest, chr, (firstChar :: chr_rest));
      then
        res;
    case (strList,_,_)
      equation 
        print("- Util.stringSplitAtChar2 failed\n");
      then
        fail();
  end matchcontinue;
end stringSplitAtChar2;

public function modelicaStringToCStr "function modelicaStringToCStr
 this replaces symbols that are illegal in C to legal symbols
 see replaceStringPatterns to see the format. (example: \".\" becomes \"$p\")
  author: x02lucpo"
  input String str;
  output String res_str;
algorithm 
  res_str := modelicaStringToCStr1(str, replaceStringPatterns);
end modelicaStringToCStr;

protected function modelicaStringToCStr1
  input String inString;
  input list<ReplacePattern> inReplacePatternLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inString,inReplacePatternLst)
    local
      String str,str_1,res_str,from,to;
      list<ReplacePattern> res;
    case (str,{}) then str; 
    case (str,(REPLACEPATTERN(from = from,to = to) :: res))
      equation 
        str_1 = modelicaStringToCStr1(str, res);
        res_str = System.stringReplace(str_1, from, to);
      then
        res_str;
    case (_,_)
      equation 
        print("- Util.modelicaStringToCStr1 failed\n");
      then
        fail();
  end matchcontinue;
end modelicaStringToCStr1;

public function cStrToModelicaString "function cStrToModelicaString
 this replaces symbols that have been replace to correct value for modelica string
 see replaceStringPatterns to see the format. (example: \"$p\" becomes \".\")
  author: x02lucpo"
  input String str;
  output String res_str;
algorithm 
  res_str := cStrToModelicaString1(str, replaceStringPatterns);
end cStrToModelicaString;

protected function cStrToModelicaString1
  input String inString;
  input list<ReplacePattern> inReplacePatternLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inString,inReplacePatternLst)
    local
      String str,str_1,res_str,from,to;
      list<ReplacePattern> res;
    case (str,{}) then str; 
    case (str,(REPLACEPATTERN(from = from,to = to) :: res))
      equation 
        str_1 = cStrToModelicaString1(str, res);
        res_str = System.stringReplace(str_1, to, from);
      then
        res_str;
  end matchcontinue;
end cStrToModelicaString1;

public function boolOrList "function boolOrList
  Takes a list of boolean values and applies the boolean OR operator  to the list elements
  Example:
    boolOrList({true,false,false})  => true
    boolOrList({false,false,false}) => false"
  input list<Boolean> inBooleanLst;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inBooleanLst)
    local
      Boolean b,res;
      list<Boolean> rest;
    case ({b}) then b; 
    case ((true :: rest))  then true;
    case ((false :: rest)) then boolOrList(rest);
  end matchcontinue;
end boolOrList;

public function boolAndList "function: boolAndList
  Takes a list of boolean values and applies the boolean AND operator on the elements
  Example:
  boolAndList({}) => true
  boolAndList({true, true}) => true
  boolAndList({false,false,true}) => false"
  input list<Boolean> inBooleanLst;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inBooleanLst)
    local
      Boolean b,res;
      list<Boolean> rest;
    case({}) then true;
    case ({b}) then b; 
    case ((false :: rest)) then false;
    case ((true :: rest))  then boolAndList(rest);
  end matchcontinue;
end boolAndList;

public function boolString "function: boolString
  Takes a boolean value and returns a string representation of the boolean value.
  Example: boolString(true) => \"true\""
  input Boolean inBoolean;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inBoolean)
    case true  then "true"; 
    case false then "false"; 
  end matchcontinue;
end boolString;

public function boolEqual "Returns true if two booleans are equal, false otherwise"
	input Boolean b1;
	input Boolean b2;
	output Boolean res;
algorithm
  res := matchcontinue(b1,b2)
    case (true,  true)  then true;
    case (false, false) then true;
    case (_,_) then false;
  end matchcontinue;
end boolEqual;

/*
adrpo - 2007-02-19 this function already exists in MMC/RML
public function stringEqual "function: stringEqual
  Takes two strings and returns true if the strings are equal
  Example: stringEqual(\"a\",\"a\") => true"
  input String inString1;
  input String inString2;
  output Boolean outBoolean;
algorithm 
  outBoolean:= inString1 ==& intString2;
end stringEqual;
*/

public function listFilter 
"function: listFilter
  Takes a list of values and a filter function over the values and 
  returns a sub list of values for which the matching function succeeds.
  Example:
    given function is_numeric(string) => ()  which succeeds if the string is numeric.
    listFilter({\"foo\",\"1\",\"bar\",\"4\"},is_numeric) => {\"1\",\"4\"}"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
algorithm 
  outTypeALst:= listFilter_tail(inTypeALst, inFuncTypeTypeATo, {});
  /*
  matchcontinue (inTypeALst,inFuncTypeTypeATo)
    local
      list<Type_a> vl_1,vl;
      Type_a v;
      FuncTypeType_aTo cond;
    case ({},_) then {}; 
    case ((v :: vl),cond)
      equation 
        cond(v);
        vl_1 = listFilter(vl, cond);
      then
        (v :: vl_1);
    case ((v :: vl),cond)
      equation 
        failure(cond(v));
        vl_1 = listFilter(vl, cond);
      then
        vl_1;
  end matchcontinue;
  */
end listFilter;

public function listFilter_tail 
"function: listFilter_tail
 @author adrpo
 tail recursive implementation of listFilter"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  input list<Type_a> accTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeALst,inFuncTypeTypeATo,accTypeALst)
    local
      list<Type_a> vl_1,vl;
      Type_a v;
      FuncTypeType_aTo cond;
    case ({},_,accTypeALst) then accTypeALst; 
    case ((v :: vl), cond, accTypeALst)
      equation 
        cond(v);
        accTypeALst = listAppend(accTypeALst, {v});
        vl_1 = listFilter_tail(vl, cond, accTypeALst);
      then
        (vl_1);
    case ((v :: vl),cond, accTypeALst)
      equation 
        failure(cond(v));
        vl_1 = listFilter_tail(vl, cond, accTypeALst);
      then
        vl_1;
  end matchcontinue;
end listFilter_tail;

public function listFilterBoolean 
"function: listFilterBoolean
 @author adrpo
  Takes a list of values and a filter function over the values and 
  returns a sub list of values for which the matching function returns true.
  Example:
    given function is_numeric(string) => Boolean  which returns true if the string is numeric.
    listFilter({\"foo\",\"1\",\"bar\",\"4\"},is_numeric) => {\"1\",\"4\"}"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToBoolean inFuncTypeTypeAToBoolean;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToBoolean
    input Type_a inTypeA;
    output Boolean result;
  end FuncTypeType_aToBoolean;
algorithm 
  outTypeALst:= listFilterBoolean_tail(inTypeALst, inFuncTypeTypeAToBoolean, {});
end listFilterBoolean;

public function listFilterBoolean_tail 
"function: listFilter_tail
 @author adrpo
 tail recursive implementation of listFilterBoolean"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToBoolean inFuncTypeTypeAToBoolean;
  input list<Type_a> accTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToBoolean
    input Type_a inTypeA;
    output Boolean result;
  end FuncTypeType_aToBoolean;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeALst,inFuncTypeTypeAToBoolean,accTypeALst)
    local
      list<Type_a> vl_1,vl;
      Type_a v;
      FuncTypeType_aToBoolean cond;
    case ({}, _, accTypeALst) then accTypeALst; 
    case ((v :: vl), cond, accTypeALst)
      equation 
        true = cond(v);
        accTypeALst = listAppend(accTypeALst, {v});
        vl_1 = listFilterBoolean_tail(vl, cond, accTypeALst);
      then
        (vl_1);
    case ((v :: vl), cond, accTypeALst)
      equation 
        false = cond(v);
        vl_1 = listFilterBoolean_tail(vl, cond, accTypeALst);
      then
        vl_1;
  end matchcontinue;
end listFilterBoolean_tail;

public function applyOption "function: applyOption
  Takes an option value and a function over the value. 
  It returns in another option value, resulting 
  from the application of the function on the value.
  Example:
    applyOption(SOME(1), intString) => SOME(\"1\")
    applyOption(NONE,    intString) => NONE"
  input Option<Type_a> inTypeAOption;
  input FuncTypeType_aToType_b inFuncTypeTypeAToTypeB;
  output Option<Type_b> outTypeBOption;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
    replaceable type Type_b subtypeof Any;
  end FuncTypeType_aToType_b;
  replaceable type Type_b subtypeof Any;
algorithm 
  outTypeBOption:=
  matchcontinue (inTypeAOption,inFuncTypeTypeAToTypeB)
    local
      Type_b b;
      Type_a a;
      FuncTypeType_aToType_b rel;
    case (NONE,_) then NONE; 
    case (SOME(a),rel)
      equation 
        b = rel(a);
      then
        SOME(b);
  end matchcontinue;
end applyOption;

public function makeOption "function makeOption
  Makes a value into value option, using SOME(value)"
  input Type_a inTypeA;
  output Option<Type_a> outTypeAOption;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeAOption:= SOME(inTypeA);
end makeOption;

public function stringOption "function: stringOption
  author: PA
  Returns string value or empty string from string option."
  input Option<String> inStringOption;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inStringOption)
    local String s;
    case (NONE) then ""; 
    case (SOME(s)) then s; 
  end matchcontinue;
end stringOption;

public function listSplit "function: listSplit
  Takes a list of values and an position value.
  The function returns the list splitted into two lists at the position given as argument.
  Example: listSplit({1,2,5,7},2) => ({1,2},{5,7})"
  input list<Type_a> inTypeALst;
  input Integer inInteger;
  output list<Type_a> outTypeALst1;
  output list<Type_a> outTypeALst2;
  replaceable type Type_a subtypeof Any;
algorithm 
  (outTypeALst1,outTypeALst2):=
  matchcontinue (inTypeALst,inInteger)
    local
      list<Type_a> a,b,c;
      Integer length,index;
    case (a,0) then ({},a); 
    case (a,index)
      equation 
        length = listLength(a);
        (index > length) = true;
        print("Index out of bounds (greater than list length) in relation listSplit\n");
      then
        fail();
    case (a,index)
      equation 
        (index < 0) = true;
        print("Index out of bounds (less than zero) in relation listSplit\n");
      then
        fail();
    case (a,index)
      equation 
        (index >= 0) = true;
        length = listLength(a);
        (index <= length) = true;
        (b,c) = listSplit2(a, {}, index);
      then
        (c,b);
  end matchcontinue;
end listSplit;

protected function listSplit2 "helper function to listSplit"
  input list<Type_a> inTypeALst1;
  input list<Type_a> inTypeALst2;
  input Integer inInteger3;
  output list<Type_a> outTypeALst1;
  output list<Type_a> outTypeALst2;
  replaceable type Type_a subtypeof Any;
algorithm 
  (outTypeALst1,outTypeALst2):=
  matchcontinue (inTypeALst1,inTypeALst2,inInteger3)
    local
      list<Type_a> a,b,c,d,rest;
      Integer index,new_index;
    case (a,b,index)
      equation 
        (index == 0) = true;
      then
        (a,b);
    case ((a :: rest),b,index)
      local Type_a a;
      equation 
        new_index = index - 1;
        c = listAppend(b, {a});
        (c,d) = listSplit2(rest, c, new_index);
      then
        (c,d);
    case (_,_,_)
      equation 
        print("- Util.listSplit2 failed\n");
      then
        fail();
  end matchcontinue;
end listSplit2;

public function intPositive "function: intPositive
  Returns true if integer value is positive (>= 0)"
  input Integer v;
  output Boolean res;
algorithm 
  res := (v >= 0);
end intPositive;

public function optionToList "function: optionToList
  Returns an empty list for NONE and a list containing
  the element for SOME(element). To use with listAppend"
  input Option<Type_a> inTypeAOption;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeAOption)
    local Type_a e;
    case NONE then {}; 
    case SOME(e) then {e}; 
  end matchcontinue;
end optionToList;

public function flattenOption "function: flattenOption
  Returns the second argument if NONE or the element in SOME(element)"
  input Option<Type_a> inTypeAOption;
  input Type_a inTypeA;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeA := matchcontinue (inTypeAOption,inTypeA)
    local Type_a n,c;
    case (NONE,n) then n; 
    case (SOME(c),n) then c;
  end matchcontinue;
end flattenOption;

public function isEmptyString "function: isEmptyString
  Returns true if string is the empty string."
  input String inString;
  output Boolean outBoolean;
algorithm 
  outBoolean := stringEqual(inString, "");
end isEmptyString;

public function isNotEmptyString "function: isNotEmptyString 
  Returns true if string is not the empty string."
  input String inString;
  output Boolean outBoolean;
algorithm 
  outBoolean := boolNot(stringEqual(inString, ""));
end isNotEmptyString;

public function writeFileOrErrorMsg "function: writeFileOrErrorMsg
  This function tries to write to a file and if it fails then it 
  outputs \"# Cannot write to file: <filename>.\" to errorBuf"
  input String inString1;
  input String inString2;
algorithm 
  _:=
  matchcontinue (inString1,inString2)
    local String filename,str,error_str;
    case (filename,str) /* filename the string to be written */ 
      equation 
        System.writeFile(filename, str);
      then
        ();
    case (filename,str)
      equation 
        error_str = stringAppendList({"# Cannot write to file: ",filename,"."});
        Print.printErrorBuf(error_str);
      then
        ();
  end matchcontinue;
end writeFileOrErrorMsg;

public function systemCallWithErrorMsg "
  This function executes a command with System.systemCall 
  if System.systemCall does not return 0 then the msg 
  is outputed to errorBuf and the function fails."
  input String inString1;
  input String inString2;
algorithm 
  _:=
  matchcontinue (inString1,inString2)
    local String s_call,e_msg;
    case (s_call,_) /* command errorMsg to errorBuf if fail */ 
      equation 
        0 = System.systemCall(s_call);
      then
        ();
    case (_,e_msg)
      equation 
        Print.printErrorBuf(e_msg);
      then
        fail();
  end matchcontinue;
end systemCallWithErrorMsg;

/* adrpo - 2007-02-19 - not used anymore
public function charListCompare "function: charListCompare
  Compares two char lists up to the nth 
  position and returns true if they are equal."
  input list<String> inStringLst1;
  input list<String> inStringLst2;
  input Integer inInteger3;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inStringLst1,inStringLst2,inInteger3)
    local
      String a,b;
      Integer n1,n;
      list<String> l1,l2;
    case ((a :: _),(b :: _),1) then stringEqual(a, b);
    case ((a :: l1),(b :: l2),n)
      equation 
        n1 = n - 1;
        true = stringEqual(a, b);
        true = charListCompare(l1, l2, n1);
      then
        true;
    case (_,_,_) then false; 
  end matchcontinue;
end charListCompare;
*/
public function strncmp "function: strncmp
  Compare two strings up to the nth character
  Returns true if they are equal."
  input String inString1;
  input String inString2;
  input Integer inInteger3;
  output Boolean outBoolean;
algorithm 
  outBoolean := (0==System.strncmp(inString1,inString2,inInteger3));
  /*
  matchcontinue (inString1,inString2,inInteger3)
    local
      list<String> clst1,clst2;
      Integer s1len,s2len,n;
      String s1,s2;
    case (s1,s2,n)
      equation 
        clst1 = string_list_string_char(s1);
        clst2 = string_list_string_char(s2);
        s1len = stringLength(s1);
        s2len = stringLength(s2);
        (s1len >= n) = true;
        (s2len >= n) = true;
        true = charListCompare(clst1, clst2, n);
      then
        true;
    case (_,_,_) then false; 
  end matchcontinue;
  */
end strncmp;

public function tickStr "function: tickStr
  author: PA 
  Returns tick as a string, i.e. an unique number."
  output String s;
algorithm 
  s := intString(tick());
end tickStr;

protected function replaceSlashWithPathDelimiter "function replaceSlashWithPathDelimiter
  author: x02lucpo
  replace the / with the system-pathdelimiter.
  On Windows must be \\ so that the function getAbsoluteDirectoryAndFile works"
  input String str;
  output String ret_string;
  String pd;
algorithm 
  pd := System.pathDelimiter();
  ret_string := System.stringReplace(str, "/", pd);
end replaceSlashWithPathDelimiter;

public function getAbsoluteDirectoryAndFile "function getAbsoluteDirectoryAndFile
  author: x02lucpo
  splits the filepath in directory and filename
  (\"c:\\programs\\file.mo\") => (\"c:\\programs\",\"file.mo\")
  (\"..\\work\\file.mo\") => (\"c:\\openmodelica123\\work\", \"file.mo\")"
  input String inString;
  output String outString1;
  output String outString2;
algorithm 
  (outString1,outString2):=
  matchcontinue (inString)
    local
      String file,pd,list_path,res,file_1,file_path,dir_path,current_dir,name;
      String pd_chr;
      list<String> list_path_1;
    case (file_1)
      equation 
        file = replaceSlashWithPathDelimiter(file_1);
        pd = System.pathDelimiter();
        /* (pd_chr :: {}) = string_list_string_char(pd); */
        (list_path :: {}) = stringSplitAtChar(file, pd) "same dir only filename as param" ;
        res = System.pwd();
      then
        (res,list_path);
    case (file_1)
      local list<String> list_path;
      equation 
        file = replaceSlashWithPathDelimiter(file_1);
        pd = System.pathDelimiter();
        /* (pd_chr :: {}) = string_list_string_char(pd); */
        list_path = stringSplitAtChar(file, pd);
        file_path = listLast(list_path);
        list_path_1 = listStripLast(list_path);
        dir_path = stringDelimitList(list_path_1, pd);
        current_dir = System.pwd();
        0 = System.cd(dir_path);
        res = System.pwd();
        0 = System.cd(current_dir);
      then
        (res,file_path);
    case (name)
      equation 
        Debug.fprint("failtrace", "- Util.getAbsoluteDirectoryAndFile failed");
      then
        fail();
  end matchcontinue;
end getAbsoluteDirectoryAndFile;


public function rawStringToInputString "function: rawStringToInputString
  author: x02lucpo
  replace the double-backslash with backslash"
  input String inString;
  output String s;
algorithm 
  (s) :=
  matchcontinue (inString)
    local
      String retString,rawString;
    case (rawString)
      equation 
         retString = System.stringReplace(rawString, "\\\"", "\"") "change backslash-double-quote to double-quote ";
         retString = System.stringReplace(retString, "\\\\", "\\") "double-backslash with backslash ";
      then
        (retString);
  end matchcontinue;
end  rawStringToInputString;
/*
public function matrixToVector "function: matrixToVector
  Convert a 1-X // X-1 dimensional Matrix to a one-dimensional vector "
  input Matrix inMatrix;
	output Vector v;
algorithm
  (v):=
  matchcontinue(inMatrix)
  local 
  
  equation
    
    then
  	(tail);    
  end matchcontinue
end matrixToVektor
*/		
end Util;

