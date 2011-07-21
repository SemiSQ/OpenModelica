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

encapsulated package Util
" file:        Util.mo
  package:     Util
  description: Miscellanous MetaModelica Compiler (MMC) utilities

  RCS: $Id$

  This package contains various MetaModelica Compiler (MMC) utilities sigh, mostly
  related to lists.
  It is used pretty much everywhere. The difference between this
  module and the ModUtil module is that ModUtil contains modelica
  related utilities. The Util module only contains *low-level*
  MetaModelica Compiler (MMC) utilities, for example finding elements in lists.

  This modules contains many functions that use *type variables* in MetaModelica Compiler (MMC).
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

public uniontype Status "Used to signal success or failure of a function call"
  record SUCCESS end SUCCESS;
  record FAILURE end FAILURE;
end Status;

public uniontype DateTime
  record DATETIME
    Integer sec;
    Integer min;
    Integer hour;
    Integer mday;
    Integer mon;
    Integer year;
  end DATETIME;
end DateTime;

public import Absyn;
protected import Debug;
protected import Error;
protected import OptManager;
protected import Print;
protected import System;

public constant String derivativeNamePrefix="$DER";
public constant String pointStr = "$P";
public constant String leftBraketStr = "$lB";
public constant String rightBraketStr = "$rB";
public constant String leftParStr = "$lP";
public constant String rightParStr = "$rP";
public constant String commaStr = "$c";

protected constant list<ReplacePattern> replaceStringPatterns=
         {REPLACEPATTERN(".",pointStr),
          REPLACEPATTERN("[",leftBraketStr),REPLACEPATTERN("]",rightBraketStr),
          REPLACEPATTERN("(",leftParStr),REPLACEPATTERN(")",rightParStr),
          REPLACEPATTERN(",",commaStr)};

public function sort "sorts a list given an ordering function.

Uses the mergesort algorithm.

For example.

sort({2,1,3},intGt) => {1,2,3}
sort({2,1,3},intLt) => {3,2,1}
"
  input list<Type_a> lst;
  input greaterThanFunc greaterThan;
  output list<Type_a> outLst;
  replaceable type Type_a subtypeof Any;
  partial function greaterThanFunc
    input Type_a a;
    input Type_a b;
    output Boolean res;
  end greaterThanFunc;
algorithm
  outLst := matchcontinue(lst,greaterThan)
  local Type_a elt; Integer middle; list<Type_a> left,right;
    case({},_) then {};
    case ({elt},greaterThan) then {elt};
    case(lst,greaterThan) equation
      middle = intDiv(listLength(lst),2);
      (left,right) = listSplit(lst,middle);
      left = sort(left,greaterThan);
      right = sort(right,greaterThan);
      outLst = merge(left,right,greaterThan);
   then outLst;
  end matchcontinue;
end sort;

public function isIntGreater "Author: BZ"
input Integer lhs;
input Integer rhs;
output Boolean b;
algorithm b := lhs>rhs;
end isIntGreater;

public function isRealGreater "Author: BZ"
input Real lhs;
input Real rhs;
output Boolean b;
algorithm b := lhs>. rhs;
end isRealGreater;

protected function merge "help function to sort, merges two sorted lists"
  input list<Type_a> left;
  input list<Type_a> right;
  input greaterThanFunc greaterThan;
  output list<Type_a> outLst;
  replaceable type Type_a subtypeof Any;
  partial function greaterThanFunc
    input Type_a a;
    input Type_a b;
    output Boolean res;
  end greaterThanFunc;
algorithm
  outLst := matchcontinue(left,right,greaterThan)
  local Type_a l,r;
    case({},{},greaterThan) then {};

    case(l::left,right as (r::_),greaterThan) equation
      true = greaterThan(r,l);
      outLst =  merge(left,right,greaterThan);
    then l::outLst;

    case(left as (l::_), r::right,greaterThan) equation
      false = greaterThan(r,l);
      outLst =  merge(left,right,greaterThan);
    then r::outLst;
    case({},right,greaterThan) then right;
    case(left,{},greaterThan) then left;
  end matchcontinue;
end merge;

public function linuxDotSlash "If operating system is Linux/Unix, return a './', otherwise return empty string"
  output String str;
algorithm
  str := matchcontinue()
    case()
      equation
        str = System.os();
        true = ("linux" ==& str) or ("OSX" ==& str);
      then "./";
    case() then "";
  end matchcontinue;
end linuxDotSlash;


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
      String arg,value;
      list<String> args;
   case(flag,{}) then "";
   case(flag,arg::{})
      equation
        0 = stringCompare(flag,arg);
      then
        "";
   case(flag,arg::value::args)
      equation
        0 = stringCompare(flag,arg);
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

public function isEqual "function: isEqual
this function does equal(e1,e2) and returns true if it succedes."
  input Type_a input1;
  input Type_a input2;
  output Boolean isequal;
  replaceable type Type_a subtypeof Any;
algorithm isequal := matchcontinue(input1,input2)
  case(input1,input2)
    equation
      equality(input1 = input2);
      then true;
  case(_,_) then false;
  end matchcontinue;
end isEqual;

public function isListEqual "function: isListEqual
this function does equal(e1,e2) and returns true if it succedes."
  input list<Type_a> input1;
  input list<Type_a> input2;
  input Boolean equalLength;
  output Boolean isequal;
  replaceable type Type_a subtypeof Any;
algorithm isequal := matchcontinue(input1,input2,equalLength)
  local
    Type_a a,b;
    list<Type_a> al,bl;
    case({},{},_) then true;
  case({},_,false) then true;
  case(_,{},false) then true;
  case(a::al,b::bl,equalLength)
    equation
      true = isEqual(a,b);
      true = isListEqual(al,bl,equalLength);
    then true;
  case(_,_,_) then false;
  end matchcontinue;
end isListEqual;

public function isListEmpty "function: isListEmpty
  Author: DH 2010-03
  Returns true if the given list is empty, false otherwise." 
  input list<Type_a> inList;
  output Boolean out;
  replaceable type Type_a subtypeof Any;
algorithm
  out := matchcontinue(inList)
  case({}) then true;
  case(_) then false;
  end matchcontinue;
end isListEmpty;

public function isListNotEmpty 
  input list<Type_a> input1;
  output Boolean isempty;
  replaceable type Type_a subtypeof Any;
algorithm isempty := matchcontinue(input1)
  case({}) then false;
  case(_) then true;
  end matchcontinue;
end isListNotEmpty;

public function assertListEmpty
  input list<Type_a> input1;
  replaceable type Type_a subtypeof Any;
algorithm
  _ := match(input1)
    case({}) then ();
  end match;
end assertListEmpty;

public function listFindWithCompareFunc "
Author BZ 2009-04
Search list for a provided element using the provided function.
Return the index of the element if found, otherwise fail."
  input list<Type_a> input1;
  input Type_a input2;
  input compareFunc cmpFunc;
  input Boolean printError;
  output Integer isequal;
  partial function compareFunc
    input Type_a inp1;
    input Type_a inp2;
    output Boolean resFunc;
  end compareFunc;
  replaceable type Type_a subtypeof Any;
algorithm
  isequal := matchcontinue(input1,input2,cmpFunc,printError)
    local
      Type_a a,b;
      list<Type_a> al;
    case(a::al,b,cmpFunc,_)
      equation
        true = cmpFunc(a,b);
      then
        0;
    case(a::al,b,cmpFunc,_)
      equation
        false = cmpFunc(a,b);
      then
        1+listFindWithCompareFunc(al,b,cmpFunc,printError);
    case({},_,_,true)
      equation
        print("listFindWithCompareFunc failed - end of list\n");
      then fail();
  end matchcontinue;
end listFindWithCompareFunc;

public function selectAndRemoveNth "
Author BZ 2009-04
Extracts N'th element and keeping rest of list intact.
For readability a third position argument has to be passed along.
"
input list<Type_a> inList;
input Integer elemPos;
input Integer curPos;
output Type_a selected;
output list<Type_a> rest;
replaceable type Type_a subtypeof Any;
algorithm (selected,rest) := matchcontinue(inList,elemPos,curPos)
  local
    list<Type_a> al,al2;
    Type_a a,a2;
  case(a::al,elemPos,curPos)
    equation
      true = intEq(elemPos,curPos);
      then
        (a,al);
  case(a::al,elemPos,curPos)
    equation
      false = intEq(elemPos,curPos);
      (a2,al2) = selectAndRemoveNth(al,elemPos,curPos+1);
      then
        (a2,a::al2);
  end matchcontinue;
end selectAndRemoveNth;

public function isListEqualWithCompareFunc "
Author BZ 2009-01
Compares the elements of two lists using provided compare function.
"
input list<Type_a> input1;
input list<Type_a> input2;
input compareFunc cmpFunc;
output Boolean isequal;
partial function compareFunc
  input Type_a inp1;
  input Type_a inp2;
  output Boolean resFunc;
end compareFunc;
replaceable type Type_a subtypeof Any;
algorithm isequal := matchcontinue(input1,input2,cmpFunc)
  local
    Type_a a,b;
    list<Type_a> al,bl;
    case({},{},_) then true;
  case({},_,_) then false;
  case(_,{},_) then false;
  case(a::al,b::bl,cmpFunc)
    equation
      true = cmpFunc(a,b);
      true = isListEqualWithCompareFunc(al,bl,cmpFunc);
    then true;
  case(_,_,_) then false;
  end matchcontinue;
end isListEqualWithCompareFunc;

public function isPrefixListComp
  "Checks if the first list is a prefix of the second list, i.e. that all
  elements in the first list is equal to the corresponding elements in the
  second list."
  input list<Type_a> input1;
  input list<Type_a> input2;
  input compareFunc cmpFunc;
  output Boolean isequal;
  partial function compareFunc
    input Type_a inp1;
    input Type_a inp2;
    output Boolean resFunc;
  end compareFunc;
  replaceable type Type_a subtypeof Any;
algorithm isequal := matchcontinue(input1,input2,cmpFunc)
  local
    Type_a a,b;
    list<Type_a> al,bl;
  case({},{},_) then true;
  case({},_,_) then true;
  case(_,{},_) then true;
  case(a::al,b::bl,cmpFunc)
    equation
      true = cmpFunc(a,b);
      true = isPrefixListComp(al,bl,cmpFunc);
    then true;
  case(_,_,_) then false;
  end matchcontinue;
end isPrefixListComp;

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
  outTypeALst := matchcontinue (inTypeA,inInteger, accumulator)
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
        res = listFill_tail(a, n_1, a::accumulator);
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

public function listIntRange3 
  "Returns a list of integers from n to m with step s.
  Example listIntRange2(3,9,2) => {3,5,7,9}"
  input Integer n;
  input Integer s;
  input Integer m;
  output list<Integer> res;
algorithm
  res := listIntRange_tail(n, s, m);
end listIntRange3;

public function listIntRange2 
  "Returns a list of integers from n to m.
  Example listIntRange2(3,5) => {3,4,5}"
  input Integer n;
  input Integer m;
  output list<Integer> res;
protected
  Integer step;
algorithm
  step := if_(intLt(n, m), 1, -1);
  res := listIntRange_tail(n, step, m);
end listIntRange2;

public function listIntRange
  "Returns a list of n integers from 1 to N.
  Example: listIntRange(3) => {1,2,3}"
  input Integer n;
  output list<Integer> res;
algorithm
  res := listIntRange_tail(1, 1, n);
end listIntRange;

protected function listIntRange_tail
  "Tail recursive implementation of list range."
  input Integer inStart;
  input Integer inStep;
  input Integer inStop;
  output list<Integer> outResult;
algorithm
  outResult := matchcontinue(inStart, inStep, inStop)
    local
      String error_str;
      Boolean is_done;

    case (_, 0, _)
      equation
        error_str = stringDelimitList(
          listMap({inStart, inStep, inStop}, intString), ":");
        Error.addMessage(Error.ZERO_STEP_IN_ARRAY_CONSTRUCTOR, {error_str});
      then
        fail();

    case (_, _, _)
      equation
        false = intEq(inStep, 0);
        true = (inStart == inStop);
      then
        {inStart};

    case (_, _, _)
      equation
        false = intEq(inStep, 0);
        true = (inStep > 0);
        is_done = (inStart > inStop);
      then
        listIntRange_tail2(inStart, inStep, inStop, intGt, is_done, {});

    case (_, _, _)
      equation
        false = intEq(inStep, 0);
        true = (inStep < 0);
        is_done = (inStart < inStop);
      then
        listIntRange_tail2(inStart, inStep, inStop, intLt, is_done, {});

  end matchcontinue;
end listIntRange_tail;

protected function listIntRange_tail2
  "Helper function to listIntRange_tail."
  input Integer inStart;
  input Integer inStep;
  input Integer inStop;
  input CompFunc compFunc;
  input Boolean isDone;
  input list<Integer> inValues;
  output list<Integer> outValues;

  partial function CompFunc
    input Integer inValue1;
    input Integer inValue2;
    output Boolean outRes;
  end CompFunc;
algorithm
  outValues := match(inStart, inStep, inStop, compFunc, isDone, inValues)
    local
      Integer next;
      list<Integer> vals;
      Boolean is_done;

    case (_, _, _, _, true, _)
      then listReverse(inValues);

    else
      equation
        next = inStart + inStep;
        vals = inStart :: inValues;
        is_done = compFunc(next, inStop);
      then
        listIntRange_tail2(next, inStep, inStop, compFunc, is_done, vals);

  end match;
end listIntRange_tail2;

public function listFirst "function: listFirst
  Returns the first element of a list
  Example: listFirst({3,5,7,11,13}) => 3"
  input list<Type_a> inTypeALst;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeA:= listNth(inTypeALst, 0);
end listFirst;

public function listFirstOrEmpty "
Author BZ, 2008-09
Same as listFirst, but returns a list of the first element, or empty list if there is no element.
"
  input list<Type_a> inTypeALst;
  output list<Type_a> outTypeA;
  replaceable type Type_a subtypeof Any;
algorithm outTypeA:= matchcontinue(inTypeALst)
  local Type_a aa;
  case({}) then {};
  case(aa::_) then {aa};
end matchcontinue;
end listFirstOrEmpty;

public function list2nd "
  Returns the second element of a list
  Example: listFirst({3,5,7,11,13}) => 5"
  input list<Type_a> inTypeALst;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeA:= listNth(inTypeALst, 1);
end list2nd;

public function listRest "function: listRest
  Returns the rest of a list.
  Example: listRest({3,5,7,11,13}) => {5,7,11,13}"
  input list<Type_a> inTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:= match (inTypeALst)
    local
      list<Type_a> x;
    case ((_ :: x)) then x;
  end match;
end listRest;

public function listRestOrEmpty "
Author BZ, 2008-09
Same as listRest, but it can return a empty list.
"
  input list<Type_a> inTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:=
  match (inTypeALst)
    local list<Type_a> x;
    case ((_ :: x)) then x;
    case({}) then {};
  end match;
end listRestOrEmpty;

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

public function listSplitLast
  "Returns the last element of a list and a list of all previous elements. If the list is the empty list, the function fails.
  Example:
    listLast({3,5,7,11,13}) => (13,{3,5,7,11})
    listLast({}) => fail"
  input list<Type_a> lst;
  output Type_a last;
  output list<Type_a> outLst;
  replaceable type Type_a subtypeof Any;
algorithm
  (last,outLst) := listSplitLastTail(lst,{});
end listSplitLast;

protected function listSplitLastTail
  "Returns the last element of a list and a list of all previous elements. If the list is the empty list, the function fails.
  Example:
    listLast({3,5,7,11,13}) => (13,{3,5,7,11})
    listLast({}) => fail"
  input list<Type_a> lst;
  input list<Type_a> acc;
  output Type_a last;
  output list<Type_a> outLst;
  replaceable type Type_a subtypeof Any;
algorithm
  (last,outLst) := match (lst,acc)
    local
      Type_a a;
      list<Type_a> rest;
    case ({a},acc) then (a,listReverse(acc));
    case (a::rest,acc)
      equation
        (a,acc) = listSplitLastTail(rest,a::acc);
      then
        (a,acc);
  end match;
end listSplitLastTail;

public function listCons "function: listCons
  Performs the cons operation, i.e. elt::list."
  input list<Type_a> inTypeALst;
  input Type_a inTypeA;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:= (inTypeA::inTypeALst);
end listCons;

public function listConsOnTrue "function: listCons
  Performs the cons operation, i.e. elt::list."
  input Boolean b;
  input Type_a a;
  input list<Type_a> lst;
  output list<Type_a> outLst;
  replaceable type Type_a subtypeof Any;
algorithm
  outLst := match (b,a,lst)
    case (true,a,lst) then a::lst;
    else lst;
  end match;
end listConsOnTrue;

public function listConsOnSuccess
"Performs the cons operation if the predicate succeeds."
  input Type_a x;
  input list<Type_a> xs;
  input Predicate fn;
  output list<Type_a> oxs;
  replaceable type Type_a subtypeof Any;
  partial function Predicate
    input Type_a x;
  end Predicate;
algorithm
  oxs := matchcontinue (x,xs,fn)
    case (x,xs,fn)
      equation
        fn(x);
      then x::xs;
    case (_,xs,_) then xs;
  end matchcontinue;
end listConsOnSuccess;

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

public function listContains "function: listContains
Checks wheter a list contains a value or not."
  input Type_a ele;
  input list<Type_a> elems;
  output Boolean contains;
  replaceable type Type_a subtypeof Any;
algorithm
  contains := listMember(ele,elems);
end listContains;

public function listNotContains "function: listNotContains
Checks wheter a list contains a value or not."
  input Type_a ele;
  input list<Type_a> elems;
  output Boolean contains;
  replaceable type Type_a subtypeof Any;
algorithm
  contains := not listMember(ele,elems);
end listNotContains;

public function listContainsWithCompareFunc "function: listContains
  Checks whether a list contains a value or not."
  input Type_a ele;
  input list<Type_b> elems;
  input compareFunc f;
  partial function compareFunc
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Boolean outTypeB;
  end compareFunc;
  output Boolean contains;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  contains := matchcontinue (ele,elems,f)
    local
      Type_a a;
      Type_b b;
      list<Type_b> rest;
      Boolean bool;
    case (_,{},_) then false;
    case (a,b::rest,f)
      equation
        true = f(a,b);
      then
        true;
    case (a,_::rest,f)
      equation
        bool = listContainsWithCompareFunc(a,rest,f);
      then
        bool;
  end matchcontinue;
end listContainsWithCompareFunc;

public function listStripFirst "function: listStripLast
  Remove the last element of a list. If the list is the empty list, the function
  returns empty list
  Example:
    listStripLast({3,5,7,11,13}) => {3,5,7,11}
    listStripLast({}) => {}"
  input list<Type_a> inTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst := matchcontinue (inTypeALst)
    local
      Type_a a;
      list<Type_a> lst;
    case {} then {};
    case {a} then {};
    case a::lst
      then
        lst;
  end matchcontinue;
end listStripFirst;

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
  outTypeALst := match (inTypeALstLst, accTypeALst)
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
  end match;
end listFlatten_tail;


public function listAppendElt "function: listAppendElt
  This function adds an element last to the list
  Example: listAppendElt(1,{2,3}) => {2,3,1}"
  input Type_a inTypeA;
  input list<Type_a> inTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst := listAppend(inTypeALst, {inTypeA});
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
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
  end FuncTypeType_aToType_b;
algorithm
  outLst := matchcontinue(element, f, accLst)
    local Type_b result;
    case(element, f, accLst)
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
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
  end FuncTypeType_aToType_b;
algorithm
  outLst := matchcontinue(element, f, accLst)
    local Type_b result;
    case(element, f, accLst)
      equation
        result = f(element);
      then result::accLst;
  end matchcontinue;
end applyAndCons;


public function listApplyAndFold
  "listFold(listMap(lst,applyFunc),foldFunc,foldArg), but is more memory-efficient"
  input list<Type_a> lst;
  input FoldFunc foldFunc;
  input ApplyFunc applyFunc;
  input Type_b foldArg;
  output Type_b result;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  partial function FoldFunc
    input Type_c inElement;
    input Type_b accumulator;
    output Type_b outLst;
  end FoldFunc;
  partial function ApplyFunc
    input Type_a inElement;
    output Type_c outElement;
  end ApplyFunc;
algorithm
  result := match (lst,foldFunc,applyFunc,foldArg)
    local
      list<Type_a> rest;
      Type_a hd;
      Type_c c;
    case ({},_,_,foldArg) then foldArg;
    case (hd :: rest,foldFunc,applyFunc,foldArg)
      equation
        c = applyFunc(hd);
        foldArg = foldFunc(c,foldArg);
        foldArg = listApplyAndFold(rest, foldFunc, applyFunc, foldArg);
      then
        foldArg;
  end match;
end listApplyAndFold;

public function arrayMapNoCopy "Takes an array and a function over the elements of the array, which is applied for each element.
Since it will update the array values the returned array must have the same type, and thus the applied function must also return 
the same type. 

See also listMap, arrayMap 
  "
  input array<Type_a> array;
  input FuncType func;
  output array<Type_a> outArray;
  replaceable type Type_a subtypeof Any;
  partial function FuncType
    input Type_a x;
    output Type_a y;
  end FuncType;
algorithm
  outArray := arrayMapNoCopyHelp1(array,func,1,arrayLength(array));
end arrayMapNoCopy;

protected function arrayMapNoCopyHelp1 "help function to arrayMap"
  input array<Type_a> array;
  input FuncType func;
  input Integer pos "iterated 1..len";
  input Integer len "length of array";
  output array<Type_a> outArray;
  replaceable type Type_a subtypeof Any;
  partial function FuncType
    input Type_a x;
    output Type_a y;
  end FuncType;
algorithm
  outArray := matchcontinue(array,func,pos,len)
    local 
      Type_a newElt;
    
    case(array,func,pos,len) equation 
      true = pos > len;
    then array;
    
    case(array,func,pos,len) equation
      newElt = func(array[pos]);
      array = arrayUpdate(array,pos,newElt);
      array = arrayMapNoCopyHelp1(array,func,pos+1,len);
    then array;
  end matchcontinue;
end arrayMapNoCopyHelp1;

public function arrayMapNoCopy_1 "
same as arrayMapcopy but with additional argument 

See also listMap, arrayMap 
  "
  input array<Type_a> array;
  input FuncType func;
  input Type_b inArg;
  output array<Type_a> outArray;
  output Type_b outArg;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncType
    input tuple<Type_a,Type_b> inTpl;
    output tuple<Type_a,Type_b> outTpl;
  end FuncType;
algorithm
  (outArray,outArg) := arrayMapNoCopyHelp1_1(array,func,1,arrayLength(array),inArg);
end arrayMapNoCopy_1;

protected function arrayMapNoCopyHelp1_1 "help function to arrayMap"
  input array<Type_a> inArray;
  input FuncType func;
  input Integer pos "iterated 1..len";
  input Integer len "length of array";
  input Type_b inArg;
  output array<Type_a> outArray;
  output Type_b outArg;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncType
    input tuple<Type_a,Type_b> inTpl;
    output tuple<Type_a,Type_b> outTpl;
  end FuncType;
algorithm
  (outArray,outArg) := matchcontinue(inArray,func,pos,len,inArg)
    local 
      array<Type_a> a,a1;
      Type_a newElt;
      Type_b extarg,extarg1;
    
    case(inArray,func,pos,len,inArg) equation 
      true = pos > len;
    then (inArray,inArg);
    
    case(inArray,func,pos,len,inArg) equation
      ((newElt,extarg)) = func((inArray[pos],inArg));
      a = arrayUpdate(inArray,pos,newElt);
      (a1,extarg1) = arrayMapNoCopyHelp1_1(a,func,pos+1,len,extarg);
    then (a1,extarg1);
  end matchcontinue;
end arrayMapNoCopyHelp1_1;

public function arraySelect 
"Takes an array and a list with index and output a new array with the indexed elements. 
 Since it will update the array values the returned array must not have the same type, 
 the array will first be initialized with the result of the first call.
 assume the Indecies are in range 1,arrayLength(array)."
  input array<Type_a> array;
  input list<Integer> lst;
  output array<Type_a> outArray;
  replaceable type Type_a subtypeof Any;
algorithm
  outArray := arrayCreate(listLength(lst),array[1]);
  outArray := arraySelectHelp(array,lst,outArray,1);
end arraySelect;

protected function arraySelectHelp "help function to arrayMap"
  input array<Type_a> array;
  input list<Integer> posistions;
  input array<Type_a> inArray;
  input Integer lstpos;
  output array<Type_a> outArray;
  replaceable type Type_a subtypeof Any;
algorithm
  outArray := matchcontinue(array,posistions,inArray,lstpos)
    local 
    Integer pos,i;
    list<Integer> rest;
    Type_a elmt;
    case(_,{},inArray,_) then inArray;
    case(array,pos::rest,inArray,i) equation 
      elmt = array[pos];
      inArray = arrayUpdate(inArray,i,elmt);
      inArray = arraySelectHelp(array,rest,inArray,i+1);
    then inArray;
    case(_,_,_,i) equation
      print("arraySelectHelp failed\n for i : " +& intString(i));
    then fail();
  end matchcontinue;
end arraySelectHelp;

public function arrayMap 
"@author: unkwnown, adrpo
  Takes an array and a function over the elements of the array, which is applied for each element.
  Since it will update the array values the returned array must not have the same type, the array 
  will first be initialized with the result of the first call if it exists. 
  If the input array is empty use listArray->listMap->arrayList way. 
  See also listMap, arrayMapNoCopy"
  input array<Type_a> array;
  input FuncType func;
  output array<Type_b> outArray;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncType
    input Type_a x;
    output Type_b y;
  end FuncType;
protected 
  Type_b initElt;
algorithm    
  outArray := matchcontinue(array, func)
    // if the array is empty, use list transformations to fix the types!
    case (array, func)
      equation
        true = intEq(0, arrayLength(array));
        outArray = listArray({});
      then
        outArray;
    // otherwise, use the first element to create the new array
    case (array, func)
      equation
        false = intEq(0, arrayLength(array));
        initElt = func(array[1]);
        outArray = arrayMapHelp1(array,arrayCreate(arrayLength(array),initElt),func,1,arrayLength(array));
      then
        outArray;
        
  end matchcontinue;
end arrayMap;

protected function arrayMapHelp1 "help function to arrayMap"
  input array<Type_a> array;
  input array<Type_b> newArray;
  input FuncType func;
  input Integer pos "iterated 1..len";
  input Integer len "length of array";
  output array<Type_b> outArray;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncType
    input Type_a x;
    output Type_b y;
  end FuncType;
algorithm
  outArray := matchcontinue(array,newArray,func,pos,len)
    local 
      Type_b newElt;
    
    case(array,newArray,func,pos,len) equation 
      true = pos > len;
    then newArray;
    
    case(array,newArray,func,pos,len) equation
      newElt = func(array[pos]);
      newArray = arrayUpdate(newArray,pos,newElt);
      newArray = arrayMapHelp1(array,newArray,func,pos+1,len);
    then newArray;
    case(_,_,_,_,_) equation
      print("arrayMapHelp1 failed\n");
    then fail();
  end matchcontinue;
end arrayMapHelp1;

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
  /* Fastest impl. on large lists, 10M elts takes about 3 seconds */
  outTypeBLst := listReverse(listMap_impl(inTypeALst,{},inFuncTypeTypeAToTypeB));
end listMap;

public function listMap_reversed
"listMap, but returns a reversed list"
  replaceable type TypeA subtypeof Any;
  replaceable type TypeB subtypeof Any;
  input  list<TypeA> inLst;
  input  FuncTypeTypeVarToTypeVar fn;
  output list<TypeB> outLst;
  partial function FuncTypeTypeVarToTypeVar
    input TypeA inTypeA;
    output TypeB outTypeB;
    replaceable type TypeA subtypeof Any;
    replaceable type TypeB subtypeof Any;
  end FuncTypeTypeVarToTypeVar;
algorithm
  outLst := listMap_impl(inLst,{},fn);
end listMap_reversed;

protected function listMap_impl
"listMap implementation; uses an accumulator"
  replaceable type TypeA subtypeof Any;
  replaceable type TypeB subtypeof Any;
  input  list<TypeA> inLst;
  input  list<TypeB> accumulator;
  input  FuncTypeTypeVarToTypeVar fn;
  output list<TypeB> outLst;
  partial function FuncTypeTypeVarToTypeVar
    input TypeA inTypeA;
    output TypeB outTypeB;
    replaceable type TypeA subtypeof Any;
    replaceable type TypeB subtypeof Any;
  end FuncTypeTypeVarToTypeVar;
algorithm
  outLst := match(inLst, accumulator, fn)
    local
      TypeA hd;
      TypeB hdChanged;
      list<TypeA> rest;
      list<TypeB> l, result;
    
    // revese at the end
    case ({}, l, _) then l;
    // accumulate in front
    case (hd::rest, l, fn)
      equation
        hdChanged = fn(hd);
        result = listMap_impl(rest, hdChanged::l, fn);
    then
        result;
  end match;
end listMap_impl;

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
  /* adrpo - tail recursive fast implementation */
  (outTypeBLst,outTypeCLst):= listMap_2_tail(inTypeALst,inFuncTypeTypeAToTypeBTypeC, {}, {});
  /*
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
  */
end listMap_2;

function listMap_2_tail
"@author adrpo
 this will work in O(2n) due to listReverse"
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  input  list<Type_a> inLst;
  input FuncTypeType_aToType_bType_c fn;
  input  list<Type_b> accumulator1;
  input  list<Type_c> accumulator2;
  output list<Type_b> outTypeBLst;
  output list<Type_c> outTypeCLst;
  partial function FuncTypeType_aToType_bType_c
    input Type_a inTypeA;
    output Type_b outTypeB;
    output Type_c outTypeC;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
  end FuncTypeType_aToType_bType_c;
algorithm
  (outTypeBLst,outTypeCLst) := match(inLst, fn, accumulator1, accumulator2)
    local
      Type_a hd; Type_b hdChanged1; Type_c hdChanged2;
      list<Type_a> rest;  list<Type_b> l1, result1; list<Type_c> l2, result2;
    case ({}, _, l1, l2) then (listReverse(l1), listReverse(l2));
    case (hd::rest, fn, l1, l2)
      equation
        (hdChanged1, hdChanged2) = fn(hd);
        l1 = hdChanged1::l1;
        l2 = hdChanged2::l2;
        (result1, result2) = listMap_2_tail(rest, fn, l1, l2);
    then
        (result1, result2);
  end match;
end listMap_2_tail;

public function listMap1_2 "
  Takes a list and a function over the elements and an additional argument returning a tuple of
  two types, which is applied for each element producing two new lists.
  See also listMap_2.
  "
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToType_bType_c inFuncTypeTypeAToTypeBTypeC;
  input Type_d extraArg;
  output list<Type_b> outTypeBLst;
  output list<Type_c> outTypeCLst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_d subtypeof Any;
  partial function FuncTypeType_aToType_bType_c
    input Type_a inTypeA;
    input Type_d extraArg;
    output Type_b outTypeB;
    output Type_c outTypeC;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
  end FuncTypeType_aToType_bType_c;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  (outTypeBLst,outTypeCLst):=
  match (inTypeALst,inFuncTypeTypeAToTypeBTypeC,extraArg)
    local
      Type_b f1_1;
      Type_c f2_1;
      list<Type_b> r1_1;
      list<Type_c> r2_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aToType_bType_c fn;
    case ({},_,_) then ({},{});
    case ((f :: r),fn,extraArg)
      equation
        (f1_1,f2_1) = fn(f,extraArg);
        (r1_1,r2_1) = listMap1_2(r, fn,extraArg);
      then
        ((f1_1 :: r1_1),(f2_1 :: r2_1));
  end match;
end listMap1_2;

public function listMap1_3 "
  Takes a list and a function over the elements and an additional argument returning a tuple of
  three types, which is applied for each element producing two new lists.
  See also listMap_2 and listMap1_2.
  "
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToType_bType_c inFuncTypeTypeAToTypeBTypeC;
  input Type_d extraArg;
  output list<Type_b> outTypeBLst;
  output list<Type_c> outTypeCLst;
  output list<Type_e> outTypeELst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_d subtypeof Any;
  partial function FuncTypeType_aToType_bType_c
    input Type_a inTypeA;
    input Type_d extraArg;
    output Type_b outTypeB;
    output Type_c outTypeC;
    output Type_e outTypeE;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
  end FuncTypeType_aToType_bType_c;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_e subtypeof Any;
algorithm
  (outTypeBLst,outTypeCLst,outTypeELst):=
  matchcontinue (inTypeALst,inFuncTypeTypeAToTypeBTypeC,extraArg)
    local
      Type_b f1_1;
      Type_c f2_1;
      Type_e f3_1;
      list<Type_b> r1_1;
      list<Type_c> r2_1;
      list<Type_e> r3_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aToType_bType_c fn;
    case ({},_,_) then ({},{},{});
    case ((f :: r),fn,extraArg)
      equation
        (f1_1,f2_1,f3_1) = fn(f,extraArg);
        (r1_1,r2_1,r3_1) = listMap1_3(r, fn,extraArg);
      then
        ((f1_1 :: r1_1),(f2_1 :: r2_1),(f3_1::r3_1));
  end matchcontinue;
end listMap1_3;

public function listAppendr "
Appends two lists in reverseorder
"
  input list<Type_a> inl1;
  input list<Type_a> inl2;
  output list<Type_a> outl;
  replaceable type Type_a subtypeof Any;
algorithm
  outl := listAppend(inl2,inl1);
end listAppendr;

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
  match (inTypeALst,inFuncTypeTypeATypeBToTypeC,inTypeB,accTypeCLst)
    local
      Type_c f_1;
      list<Type_c> r_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aType_bToType_c fn;
      Type_b extraarg;
    case ({},_,_,accTypeCLst) then listReverse(accTypeCLst);
    case ((f :: r),fn,extraarg,accTypeCLst)
      equation
        f_1 = fn(f, extraarg);
        accTypeCLst = f_1::accTypeCLst;
        r_1 = listMap1_tail(r, fn, extraarg, accTypeCLst);
      then
        r_1;
  end match;
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
  match (inTypeALst,inFuncTypeTypeBTypeAToTypeC,inTypeB,accTypeCLst)
    local
      Type_c f_1;
      list<Type_c> r_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_bType_aToType_c fn;
      Type_b extraarg;
    case ({},_,_,accTypeCLst) then listReverse(accTypeCLst);
    case ((f :: r),fn,extraarg,accTypeCLst)
      equation
        f_1 = fn(extraarg, f);
        accTypeCLst = f_1::accTypeCLst;
        r_1 = listMap1r_tail(r, fn, extraarg, accTypeCLst);
      then
        (r_1);
  end match;
end listMap1r_tail;

public function listMapAndFold
  "Takes a list, an extra argument and a function. The function will be applied
  to each element in the list, and the extra argument will be passed to the
  function and updated."
  input list<Type_a> inList;
  input FuncType inFunc;
  input Type_b inArg;
  output list<Type_c> outList;
  output Type_b outArg;

  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;

  partial function FuncType
    input Type_a inElem;
    input Type_b inArg;
    output Type_c outResult;
    output Type_b outArg;
  end FuncType;
algorithm
  (outList, outArg) := listMapAndFold_tail(inList, inFunc, inArg, {});
end listMapAndFold;

public function listMapAndFold_tail
  "Tail recursive implementation of listMapAndFold."
  input list<Type_a> inList;
  input FuncType inFunc;
  input Type_b inArg;
  input list<Type_c> inAccumList;
  output list<Type_c> outList;
  output Type_b outArg;

  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;

  partial function FuncType
    input Type_a inElem;
    input Type_b inArg;
    output Type_c outResult;
    output Type_b outArg;
  end FuncType;
algorithm
  (outList, outArg) := match(inList, inFunc, inArg, inAccumList)
    local
      Type_a e1;
      list<Type_a> rest_e1;
      Type_c res;
      list<Type_c> rest_res;
    case ({}, _, _, _) then (listReverse(inAccumList), inArg);
    case (e1 :: rest_e1, _, _, _)
      equation
        (res, inArg) = inFunc(e1, inArg);
        inAccumList = res :: inAccumList;
        (rest_res, inArg) = listMapAndFold_tail(rest_e1, inFunc, inArg, inAccumList);
      then
        (rest_res, inArg);
  end match;
end listMapAndFold_tail;

public function listMapAndFold1
  "Takes a list, an extra argument, an extra constant argument, and a function.
  The function will be applied to each element in the list, and the extra
  argument will be passed to the function and updated."
  input list<Type_a> inList;
  input FuncType inFunc;
  input Type_b inArg;
  input Type_c inConstArg;
  output list<Type_d> outList;
  output Type_b outArg;

  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;

  partial function FuncType
    input Type_a inElem;
    input Type_b inArg;
    input Type_c inConstArg;
    output Type_d outResult;
    output Type_b outArg;
  end FuncType;
algorithm
  (outList, outArg) := listMapAndFold1_tail(inList, inFunc, inArg, inConstArg, {});
end listMapAndFold1;

protected function listMapAndFold1_tail
  "Tail recursive implementation of listMapAndFold1."
  input list<Type_a> inList;
  input FuncType inFunc;
  input Type_b inArg;
  input Type_c inConstArg;
  input list<Type_d> inAccumList;
  output list<Type_d> outList;
  output Type_b outArg;

  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;

  partial function FuncType
    input Type_a inElem;
    input Type_b inArg;
    input Type_c inConstArg;
    output Type_d outResult;
    output Type_b outArg;
  end FuncType;
algorithm
  (outList, outArg) := match(inList, inFunc, inArg, inConstArg, inAccumList)
    local
      Type_a e1;
      list<Type_a> rest_e1;
      Type_d res;
      list<Type_d> rest_res;
    case ({}, _, _, _, _) then (listReverse(inAccumList), inArg);
    case (e1 :: rest_e1, _, _, _, _)
      equation
        (res, inArg) = inFunc(e1, inArg, inConstArg);
        inAccumList = res :: inAccumList;
        (rest_res, inArg) = listMapAndFold1_tail(rest_e1, inFunc, inArg, inConstArg, inAccumList);
      then
        (rest_res, inArg);
  end match;
end listMapAndFold1_tail;

public function listListMapAndFold
  "Takes a list of lists, an extra argument, and a function.  The function will
  be applied to each element in the list, and the extra argument will be passed
  to the function and updated for each element."
  input list<list<Type_a>> inListList;
  input FuncType inFunc;
  input Type_b inArg;
  output list<list<Type_c>> outListList;
  output Type_b outArg;

  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;

  partial function FuncType
    input Type_a inElem;
    input Type_b inArg;
    output Type_c outResult;
    output Type_b outArg;
  end FuncType;
algorithm
  (outListList, outArg) := listListMapAndFold_tail(inListList, inFunc, inArg, {});
end listListMapAndFold;

protected function listListMapAndFold_tail
  input list<list<Type_a>> inListList;
  input FuncType inFunc;
  input Type_b inArg;
  input list<list<Type_c>> inAccumList;
  output list<list<Type_c>> outListList;
  output Type_b outArg;

  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;

  partial function FuncType
    input Type_a inElem;
    input Type_b inArg;
    output Type_c outResult;
    output Type_b outArg;
  end FuncType;
algorithm
  (outListList, outArg) := match(inListList, inFunc, inArg, inAccumList)
    local
      list<Type_a> lst;
      list<list<Type_a>> rest_lst;
      list<Type_c> res;
      list<list<Type_c>> rest_res, accum;
      Type_b arg;

    case ({}, _, _, _) then (listReverse(inAccumList), inArg);
    case (lst :: rest_lst, _, _, _)
      equation
        (res, arg) = listMapAndFold(lst, inFunc, inArg);
        accum = res :: inAccumList;
        (rest_res, arg) = listListMapAndFold_tail(rest_lst, inFunc, arg, accum);
      then
        (rest_res, arg);
  end match;
end listListMapAndFold_tail;

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
  end FuncTypeType_aType_bType_cToType_d;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
algorithm
  outTypeDLst:= listMap2_tail(inTypeALst,inFuncTypeTypeATypeBTypeCToTypeD,inTypeB,inTypeC, {});
end listMap2;

function listMap2_tail
"@author adrpo
 this will work in O(2n) due to listReverse"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bType_cToType_d fn;
  input Type_b inTypeB;
  input Type_c inTypeC;
  input  list<Type_d> accumulator;
  output list<Type_d> outLst;
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
  outLst := match(inTypeALst, fn, inTypeB, inTypeC, accumulator)
    local
      Type_a hd; Type_d hdChanged;
      list<Type_a> rest;  list<Type_d> l, result;
      Type_b extraarg1;
      Type_c extraarg2;
    case ({}, _, _, _, l) then listReverse(l);
    case (hd::rest, fn, extraarg1, extraarg2, l)
      equation
        hdChanged = fn(hd, extraarg1, extraarg2);
        l = hdChanged::l;
        result = listMap2_tail(rest, fn, extraarg1, extraarg2, l);
    then
        result;
  end match;
end listMap2_tail;

public function listMap2r "function listMap2r
  Similar to listMap2 but iterating over last argument instead."
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bType_cToType_d inFuncTypeTypeATypeBTypeCToTypeD;
  input Type_b inTypeB;
  input Type_c inTypeC;
  output list<Type_d> outTypeDLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bType_cToType_d
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_a inTypeA;
    output Type_d outTypeD;
  end FuncTypeType_aType_bType_cToType_d;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
algorithm
  outTypeDLst:= listMap2r_tail(inTypeALst,inFuncTypeTypeATypeBTypeCToTypeD,inTypeB,inTypeC, {});
end listMap2r;

function listMap2r_tail
""
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bType_cToType_d fn;
  input Type_b inTypeB;
  input Type_c inTypeC;
  input  list<Type_d> accumulator;
  output list<Type_d> outTypeDLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bType_cToType_d
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_a inTypeA;
    output Type_d outTypeD;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
    replaceable type Type_d subtypeof Any;
  end FuncTypeType_aType_bType_cToType_d;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
algorithm
  outTypeDLst := matchcontinue(inTypeALst, fn, inTypeB, inTypeC, accumulator)
    local
      Type_a hd; Type_d hdChanged;
      list<Type_a> rest;  list<Type_d> l, result;
      Type_b extraarg1;
      Type_c extraarg2;
    case ({}, _, _, _, l) then listReverse(l);
    case (hd::rest, fn, extraarg1, extraarg2, l)
      equation
        hdChanged = fn(extraarg1, extraarg2,hd);
        l = hdChanged::l;
        result = listMap2r_tail(rest, fn, extraarg1, extraarg2, l);
    then
        result;
  end matchcontinue;
end listMap2r_tail;

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
  end FuncTypeType_aType_bType_cType_dToType_e;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
algorithm
  outTypeELst := listMap3_tail(inTypeALst,inFuncTypeTypeATypeBTypeCTypeDToTypeE,inTypeB,inTypeC,inTypeD,{});
end listMap3;

protected function listMap3_tail "function listMap3
  Takes a list and a function and three extra arguments passed to the function.
  The function produces one new value which is used for creating a new list."
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bType_cType_dToType_e inFuncTypeTypeATypeBTypeCTypeDToTypeE;
  input Type_b inTypeB;
  input Type_c inTypeC;
  input Type_d inTypeD;
  input list<Type_e> acc;
  output list<Type_e> outTypeELst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bType_cType_dToType_e
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d inTypeD;
    output Type_e outTypeE;
  end FuncTypeType_aType_bType_cType_dToType_e;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
algorithm
  outTypeELst:=
  match (inTypeALst,inFuncTypeTypeATypeBTypeCTypeDToTypeE,inTypeB,inTypeC,inTypeD,acc)
    local
      Type_e f_1;
      list<Type_e> r_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aType_bType_cType_dToType_e fn;
      Type_b extraarg1;
      Type_c extraarg2;
      Type_d extraarg3;
    case ({},_,_,_,_,acc) then listReverse(acc);
    case ((f :: r),fn,extraarg1,extraarg2,extraarg3,acc)
      equation
        f_1 = fn(f, extraarg1, extraarg2, extraarg3);
        r_1 = listMap3_tail(r, fn, extraarg1, extraarg2, extraarg3, f_1 :: acc);
      then
        r_1;
  end match;
end listMap3_tail;

public function listMap4 "function listMap4
  Takes a list and a function and four extra arguments passed to the function.
  The function produces one new value which is used for creating a new list."
  input list<Type_a> inTypeALst;
  input mapFunc fn;
  input Type_b inTypeB;
  input Type_c inTypeC;
  input Type_d inTypeD;
  input Type_e inTypeE;
  output list<Type_f> outTypeELst;
  replaceable type Type_a subtypeof Any;
  partial function mapFunc
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d inTypeD;
    input Type_e inTypeE;
    output Type_f outTypeF;
  end mapFunc;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
  replaceable type Type_f subtypeof Any;
algorithm
  outTypeELst:=
  matchcontinue (inTypeALst,fn,inTypeB,inTypeC,inTypeD,inTypeE)
    local
      Type_f f_1;
      list<Type_f> r_1;
      Type_a f;
      list<Type_a> r;
      mapFunc fn;
      Type_b extraarg1;
      Type_c extraarg2;
      Type_d extraarg3;
      Type_e extraarg4;
    case ({},_,_,_,_,_) then {};
    case ((f :: r),fn,extraarg1,extraarg2,extraarg3,extraarg4)
      equation
        f_1 = fn(f, extraarg1, extraarg2, extraarg3,extraarg4);
        r_1 = listMap4(r, fn, extraarg1, extraarg2, extraarg3,extraarg4);
      then
        (f_1 :: r_1);
  end matchcontinue;
end listMap4;

public function listMap5 "function listMap5
  Takes a list and a function and five extra arguments passed to the function.
  The function produces one new value which is used for creating a new list."
  input list<Type_a> lst;
  input listMap7Func func;
  input Type_b a1;
  input Type_c a2;
  input Type_d a3;
  input Type_e a4;
  input Type_f a5;
  output list<Type_i> outLst;
  replaceable type Type_a subtypeof Any;
  partial function listMap7Func
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d inTypeD;
    input Type_e inTypeE;
    input Type_f inTypeF;
    output Type_i outTypeI;
  end listMap7Func;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
  replaceable type Type_f subtypeof Any;
  replaceable type Type_g subtypeof Any;
  replaceable type Type_i subtypeof Any;
algorithm
  outLst:=
  match (lst,func,a1,a2,a3,a4,a5)
    local
      Type_i f_1;
      list<Type_i> r_1;
      Type_a f;
      list<Type_a> r;

    case ({},_,_,_,_,_,_) then {};
    case ((f :: r),func,a1,a2,a3,a4,a5)
      equation
        f_1 = func(f, a1,a2,a3,a4,a5);
        r_1 = listMap5(r, func, a1,a2,a3,a4,a5);
      then
        (f_1 :: r_1);
  end match;
end listMap5;

public function listMap6 "function listMap6
  Takes a list and a function and six extra arguments passed to the function.
  The function produces one new value which is used for creating a new list."
  input list<Type_a> lst;
  input listMap7Func func;
  input Type_b a1;
  input Type_c a2;
  input Type_d a3;
  input Type_e a4;
  input Type_f a5;
  input Type_g a6;
  output list<Type_i> outLst;
  partial function listMap7Func
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d inTypeD;
    input Type_e inTypeE;
    input Type_f inTypeF;
    input Type_g inTypeG;
    output Type_i outTypeI;
  end listMap7Func;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
  replaceable type Type_f subtypeof Any;
  replaceable type Type_g subtypeof Any;
  replaceable type Type_h subtypeof Any;
  replaceable type Type_i subtypeof Any;
algorithm
  outLst:=
  match (lst,func,a1,a2,a3,a4,a5,a6)
    local
      Type_i f_1;
      list<Type_i> r_1;
      Type_a f;
      list<Type_a> r;

    case ({},_,_,_,_,_,_,_) then {};
    case ((f :: r),func,a1,a2,a3,a4,a5,a6)
      equation
        f_1 = func(f, a1,a2,a3,a4,a5,a6);
        r_1 = listMap6(r, func, a1,a2,a3,a4,a5,a6);
      then
        (f_1 :: r_1);
  end match;
end listMap6;

/* TODO: listMap9 ... listMapN can also be created upon request... */
public function listMap7 "function listMap7
  Takes a list and a function and seven extra arguments passed to the function.
  The function produces one new value which is used for creating a new list."
  input list<Type_a> lst;
  input listMap7Func func;
  input Type_b a1;
  input Type_c a2;
  input Type_d a3;
  input Type_e a4;
  input Type_f a5;
  input Type_g a6;
  input Type_h a7;
  output list<Type_i> outLst;
  replaceable type Type_a subtypeof Any;
  partial function listMap7Func
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d inTypeD;
    input Type_e inTypeE;
    input Type_f inTypeF;
    input Type_g inTypeG;
    input Type_h inTypeH;
    output Type_i outTypeI;
  end listMap7Func;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
  replaceable type Type_f subtypeof Any;
  replaceable type Type_g subtypeof Any;
  replaceable type Type_h subtypeof Any;
  replaceable type Type_i subtypeof Any;
algorithm
  outLst:=
  matchcontinue (lst,func,a1,a2,a3,a4,a5,a6,a7)
    local
      Type_i f_1;
      list<Type_i> r_1;
      Type_a f;
      list<Type_a> r;

    case ({},_,_,_,_,_,_,_,_) then {};
    case ((f :: r),func,a1,a2,a3,a4,a5,a6,a7)
      equation
        f_1 = func(f, a1,a2,a3,a4,a5,a6,a7);
        r_1 = listMap7(r, func, a1,a2,a3,a4,a5,a6,a7);
      then
        (f_1 :: r_1);
  end matchcontinue;
end listMap7;

public function listMap8 "
Author BZ
  Takes a list and a function and seven extra arguments passed to the function.
  The function produces one new value which is used for creating a new list."
  input list<Type_a> lst;
  input listMap8Func func;
  input Type_b a1;
  input Type_c a2;
  input Type_d a3;
  input Type_e a4;
  input Type_f a5;
  input Type_g a6;
  input Type_h a7;
  input Type_j a8;
  output list<Type_i> outLst;
  replaceable type Type_a subtypeof Any;
  partial function listMap8Func
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d inTypeD;
    input Type_e inTypeE;
    input Type_f inTypeF;
    input Type_g inTypeG;
    input Type_h inTypeH;
    input Type_j inTypeJ;
    output Type_i outTypeI;
  end listMap8Func;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
  replaceable type Type_f subtypeof Any;
  replaceable type Type_g subtypeof Any;
  replaceable type Type_h subtypeof Any;
  replaceable type Type_i subtypeof Any;
  replaceable type Type_j subtypeof Any;
algorithm
  outLst:=
  matchcontinue (lst,func,a1,a2,a3,a4,a5,a6,a7,a8)
    local
      Type_i f_1;
      list<Type_i> r_1;
      Type_a f;
      list<Type_a> r;

    case ({},_,_,_,_,_,_,_,_,_) then {};
    case ((f :: r),func,a1,a2,a3,a4,a5,a6,a7,a8)
      equation
        f_1 = func(f, a1,a2,a3,a4,a5,a6,a7,a8);
        r_1 = listMap8(r, func, a1,a2,a3,a4,a5,a6,a7,a8);
      then
        (f_1 :: r_1);
  end matchcontinue;
end listMap8;


/* TODO: listMap9 ... listMapN can also be created upon request... */
public function listMap7list "function listMap7
  Takes a list and a function and seven extra arguments passed to the function.
  The function produces one new value which is used for creating a new list."
  input list<Type_a> lst;
  input listMap7Func func;
  input Type_b a1;
  input Type_c a2;
  input Type_d a3;
  input Type_e a4;
  input Type_f a5;
  input Type_g a6;
  input Type_h a7;
  output list<list<Type_i>> outLst;
  replaceable type Type_a subtypeof Any;
  partial function listMap7Func
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d inTypeD;
    input Type_e inTypeE;
    input Type_f inTypeF;
    input Type_g inTypeG;
    input Type_h inTypeH;
    output list<Type_i> outTypeI;
  end listMap7Func;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
  replaceable type Type_f subtypeof Any;
  replaceable type Type_g subtypeof Any;
  replaceable type Type_h subtypeof Any;
  replaceable type Type_i subtypeof Any;
algorithm
  outLst:=
  matchcontinue (lst,func,a1,a2,a3,a4,a5,a6,a7)
    local
      list<Type_i> f_1;
      list<Type_i> r_1;
      Type_a f;
      list<Type_a> r;

    case ({},_,_,_,_,_,_,_,_) then {};
    case ((f :: r),func,a1,a2,a3,a4,a5,a6,a7)
      equation
        f_1 = func(f, a1,a2,a3,a4,a5,a6,a7);
        r_1 = listMap7list(r, func, a1,a2,a3,a4,a5,a6,a7);
      then
        (f_1 :: r_1);
  end matchcontinue;
end listMap7list;

/* TODO: listMap9 ... listMapN can also be created upon request... */
public function listMap8list "function listMap7
  Takes a list and a function and seven extra arguments passed to the function.
  The function produces one new value which is used for creating a new list."
  input list<Type_a> lst;
  input listMap7Func func;
  input Type_b a1;
  input Type_c a2;
  input Type_d a3;
  input Type_e a4;
  input Type_f a5;
  input Type_g a6;
  input Type_h a7;
  input Type_i a8;
  output list<list<Type_j>> outLst;
  partial function listMap7Func
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d inTypeD;
    input Type_e inTypeE;
    input Type_f inTypeF;
    input Type_g inTypeG;
    input Type_h inTypeH;
    input Type_i inTypeI;
    output list<Type_j> outTypeI;
  end listMap7Func;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
  replaceable type Type_f subtypeof Any;
  replaceable type Type_g subtypeof Any;
  replaceable type Type_h subtypeof Any;
  replaceable type Type_i subtypeof Any;
  replaceable type Type_j subtypeof Any;
algorithm
  outLst:=
  matchcontinue (lst,func,a1,a2,a3,a4,a5,a6,a7,a8)
    local
      list<Type_j> f_1;
      list<list<Type_j>> r_1;
      Type_a f;
      list<Type_a> r;

    case ({},_,_,_,_,_,_,_,_,_) then {};
    case ((f :: r),func,a1,a2,a3,a4,a5,a6,a7,a8)
      equation
        f_1 = func(f,a1,a2,a3,a4,a5,a6,a7,a8);
        r_1 = listMap8list(r, func, a1,a2,a3,a4,a5,a6,a7,a8);
      then
        (f_1 :: r_1);
  end matchcontinue;
end listMap8list;


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
  end FuncTypeType_aType_bType_cType_dToType_eType_f;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
  replaceable type Type_f subtypeof Any;
algorithm
  (outTypeELst,outTypeFLst):=
  match (inTypeALst,inFuncTypeTypeATypeBTypeCTypeDToTypeETypeF,inTypeB,inTypeC,inTypeD)
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
  end match;
end listMap32;

public function listMap42 "function listMap32
  Takes a list and a function and three extra arguments passed to the function.
  The function produces two values which is used for creating two new lists."
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bType_cType_dToType_eType_f inFuncTypeTypeATypeBTypeCTypeDToTypeETypeF;
  input Type_b inTypeB;
  input Type_c inTypeC;
  input Type_d inTypeD;
  input Type_de inTypeDE;
  output list<Type_e> outTypeELst;
  output list<Type_f> outTypeFLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bType_cType_dToType_eType_f
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d inTypeD;
    input Type_de inTypeDE;
    output Type_e outTypeE;
    output Type_f outTypeF;
  end FuncTypeType_aType_bType_cType_dToType_eType_f;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_de subtypeof Any;
  replaceable type Type_e subtypeof Any;
  replaceable type Type_f subtypeof Any;
algorithm
  (outTypeELst,outTypeFLst):=
  matchcontinue (inTypeALst,inFuncTypeTypeATypeBTypeCTypeDToTypeETypeF,inTypeB,inTypeC,inTypeD,inTypeDE)
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
      Type_de extraarg4;
    case ({},_,_,_,_,_) then ({},{});
    case ((f :: r),fn,extraarg1,extraarg2,extraarg3,extraarg4)
      equation
        (f1_1,f2_1) = fn(f, extraarg1, extraarg2, extraarg3, extraarg4);
        (r1_1,r2_1) = listMap42(r, fn, extraarg1, extraarg2, extraarg3, extraarg4);
      then
        ((f1_1 :: r1_1),(f2_1 :: r2_1));
  end matchcontinue;
end listMap42;

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
  match (inTypeALst,inFuncTypeTypeATypeBToTypeCTypeD,inTypeB)
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
  end match;
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
  //output list<tuple<Type_d, Type_e>> outTplTypeDTypeELst;
  output list<Type_d> outTypeDLst;
  output list<Type_e> outTypeELst;
  partial function FuncTypeType_aType_bType_cToType_dType_e
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    output Type_d outTypeD;
    output Type_e outTypeE;
  end FuncTypeType_aType_bType_cToType_dType_e;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
algorithm
  (outTypeDLst,outTypeELst):=
  match (inTypeALst,inFuncTypeTypeATypeBTypeCToTypeDTypeE,inTypeB,inTypeC)
    local
      Type_d f1;
      Type_e f2;
      list<Type_d> r_1;
      list<Type_e> r_2;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aType_bType_cToType_dType_e fn;
      Type_b extraarg1;
      Type_c extraarg2;
    case ({},_,_,_) then ({},{});
    case ((f :: r),fn,extraarg1,extraarg2)
      equation
        (f1,f2) = fn(f, extraarg1, extraarg2);
        (r_1,r_2) = listMap22(r, fn, extraarg1, extraarg2);
      then
        (f1::r_1,f2::r_2);
  end match;
end listMap22;

public function listMapMap0 "function: listMapMap0
  Takes a list and two functions the first returns a value, the second doesn't. 
  The first function is applied to the element of the list and on its result 
  the second function is called. The second function is usually a function 
  with side effects, like print.
  Example: 
    listMapMap0({1,2,3},intString,print) 
    is equivalent to print(intString(1)), ..."
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToType_b inFuncTypeTypeAToTypeB;
  input FuncTypeType_bTo inFuncTypeTypeBTo;

  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
  end FuncTypeType_aToType_b;

  partial function FuncTypeType_bTo
    input Type_b inTypeB;
  end FuncTypeType_bTo;

  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  _ := matchcontinue (inTypeALst,inFuncTypeTypeAToTypeB,inFuncTypeTypeBTo)
    local
      Type_a f;
      Type_b out;
      list<Type_a> r;
      FuncTypeType_aToType_b fnTranslate;
      FuncTypeType_bTo fnNoOutput;

    case ({}, _, _) then ();
    case ((f :: r), fnTranslate, fnNoOutput)
      equation
        out = fnTranslate(f);
        fnNoOutput(out);
        listMapMap0(r, fnTranslate, fnNoOutput);
      then
        ();
  end matchcontinue;
end listMapMap0;

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
  match (inTypeALst,inFuncTypeTypeATo)
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
  end match;
end listMap0;

public function listMap01 "
  See listMap0
"
  input list<Type_a> inTypeALst;
  input Type_b b;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
    input Type_b b;
  end FuncTypeType_aTo;
algorithm
  _:=
  match (inTypeALst,b,inFuncTypeTypeATo)
    local
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aTo fn;
    case ({},_,_) then ();
    case ((f :: r),b,fn)
      equation
        fn(f,b);
        listMap01(r, b,fn);
      then
        ();
  end match;
end listMap01;

public function listMap02
  input list<Type_a> inList;
  input FuncType inFunc;
  input Type_b inArg1;
  input Type_c inArg2;
  
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;

  partial function FuncType
    input Type_a inElement;
    input Type_b inArg1;
    input Type_c inArg2;
  end FuncType;
algorithm
  _ := match(inList, inFunc, inArg1, inArg2)
    local
      Type_a element;
      list<Type_a> rest;
      
    case ({}, _, _, _) then ();
    case (element :: rest, _, _, _)
      equation
        inFunc(element, inArg1, inArg2);
        listMap02(rest, inFunc, inArg1, inArg2);
      then
        ();
  end match;
end listMap02;

public function listMapFlat "function: listMapFlat
  Takes a list and a function over the elements of the lists, which is applied
  for each element, producing a new list."
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToType_b inFuncTypeTypeAToTypeB;
  output list<Type_b> outTypeBLst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output list<Type_b> outTypeBLst;
  end FuncTypeType_aToType_b;
algorithm
  /* Fastest impl. on large lists, 10M elts takes about 3 seconds */
  outTypeBLst := listMapFlat_impl_2(inTypeALst,{},inFuncTypeTypeAToTypeB);
end listMapFlat;

function listMapFlat_impl_2
"@author Frenkel TUD
 this will work in O(2n) due to listReverse"
  replaceable type TypeA subtypeof Any;
  replaceable type TypeB subtypeof Any;
  input  list<TypeA> inLst;
  input  list<TypeB> accumulator;
  input  FuncTypeTypeVarToTypeVar fn;
  output list<TypeB> outLst;
  partial function FuncTypeTypeVarToTypeVar
    input TypeA inTypeA;
    output list<TypeB> outTypeBLst;
    replaceable type TypeA subtypeof Any;
    replaceable type TypeB subtypeof Any;
  end FuncTypeTypeVarToTypeVar;
algorithm
  outLst := matchcontinue(inLst, accumulator, fn)
    local
      TypeA hd;
      list<TypeB> hdChanged;
      list<TypeA> rest;
      list<TypeB> l, result;
    case ({}, l, _) then listReverse(l);
    case (hd::rest, l, fn)
      equation
        hdChanged = fn(hd);
        l = listAppend(hdChanged,l);
        result = listMapFlat_impl_2(rest, l, fn);
    then
        result;
  end matchcontinue;
end listMapFlat_impl_2;

public function listMapFlat1 "function listMapFlat1
  Takes a list and a function over the list plus an extra argument sent to the function.
  The function produces a new list of values which is used for creating a new list."
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bToType_c inFuncTypeTypeATypeBToTypeC;
  input Type_b inTypeB;
  output list<Type_c> outTypeCLst;
  partial function FuncTypeType_aType_bToType_c
    input Type_a inTypeA;
    input Type_b inTypeB;
    output list<Type_c> outTypeCLst;
  end FuncTypeType_aType_bToType_c;
algorithm
  outTypeCLst:= listMapFlat1_tail(inTypeALst,inFuncTypeTypeATypeBToTypeC,inTypeB,{});
end listMapFlat1;

public function listMapFlat1_tail
"function listMapFlat1_tail
 tail recurstive implmentation of listMapFlat1"
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bToType_c inFuncTypeTypeATypeBToTypeC;
  input Type_b inTypeB;
  input list<Type_c> accTypeCLst;
  output list<Type_c> outTypeCLst;
  partial function FuncTypeType_aType_bToType_c
    input Type_a inTypeA;
    input Type_b inTypeB;
    output list<Type_c> outTypeCLst;
  end FuncTypeType_aType_bToType_c;
algorithm
  outTypeCLst:=
  matchcontinue (inTypeALst,inFuncTypeTypeATypeBToTypeC,inTypeB,accTypeCLst)
    local
      list<Type_c> f_1;
      list<Type_c> r_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aType_bToType_c fn;
      Type_b extraarg;
    case ({},_,_,accTypeCLst) then listReverse(accTypeCLst);
    case ((f :: r),fn,extraarg,accTypeCLst)
      equation
        f_1 = fn(f, extraarg);
        accTypeCLst = listAppend(f_1,accTypeCLst);
        r_1 = listMapFlat1_tail(r, fn, extraarg, accTypeCLst);
      then
        r_1;
  end matchcontinue;
end listMapFlat1_tail;

public function listMapFlat2 "function listMapFlat2
  Takes a list and a function over the list plus two extra argument sent to the function.
  The function produces a new list of values which is used for creating a new list."
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bType_cToType_d inFuncTypeTypeATypeBTypeCToTypeD;
  input Type_b inTypeB;
  input Type_c inTypeC;
  output list<Type_d> outTypeDLst;
  partial function FuncTypeType_aType_bType_cToType_d
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    output list<Type_d> outTypeDLst;
  end FuncTypeType_aType_bType_cToType_d;
algorithm
  outTypeDLst:= listMapFlat2_tail(inTypeALst,inFuncTypeTypeATypeBTypeCToTypeD,inTypeB,inTypeC,{});
end listMapFlat2;

public function listMapFlat2_tail
"function listMapFlat2_tail
 tail recurstive implmentation of listMapFlat2"
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bType_cToType_d inFuncTypeTypeATypeBTypeCToTypeD;
  input Type_b inTypeB;
  input Type_c inTypeC;
  input list<Type_d> accTypeDLst;
  output list<Type_d> outTypeDLst;
  partial function FuncTypeType_aType_bType_cToType_d
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    output list<Type_d> outTypeDLst;
  end FuncTypeType_aType_bType_cToType_d;
algorithm
  outTypeDLst:=
  matchcontinue (inTypeALst,inFuncTypeTypeATypeBTypeCToTypeD,inTypeB,inTypeC,accTypeDLst)
    local
      list<Type_d> f_1;
      list<Type_d> r_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aType_bType_cToType_d fn;
      Type_b extraarg;
      Type_c extraarg1;
    
    // reverse at the end
    case ({},_,_,_,accTypeDLst) then listReverse(accTypeDLst);
    
    // accumulate in front
    case ((f :: r),fn,extraarg,extraarg1,accTypeDLst)
      equation
        f_1 = fn(f, extraarg, extraarg1);
        accTypeDLst = listAppend(f_1,accTypeDLst);
        r_1 = listMapFlat2_tail(r, fn, extraarg, extraarg1, accTypeDLst);
      then
        r_1;
  end matchcontinue;
end listMapFlat2_tail;

public function listListAppendLast "appends to the last element of a list of list of elements"
  input list<list<Type_a>> llst;
  input list<Type_a> lst;
  output list<list<Type_a>> outLst;
  replaceable type Type_a subtypeof Any;
algorithm
  outLst := matchcontinue(llst,lst)
    local 
      list<Type_a> lst1;
    
    case({},lst) then {lst};
    
    case({lst1},lst) 
      equation
        lst1 = listAppend(lst1,lst);
      then 
        {lst1};
    
    case (lst1::llst,lst) 
      equation
        llst = listListAppendLast(llst,lst);
    then 
      lst1::llst;
  end matchcontinue;
end listListAppendLast;

public function listListMap "function: listListMap
  Takes a list of lists and a function producing one value.
  The function is applied to each element of the lists resulting
  in a new list of lists.
  Example: listListMap({ {1,2},{3},{4}},intString) => { {\"1\",\"2\"},{\"3\"},{\"4\"} }"
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
  outTypeBLstLst := listMap1(inTypeALstLst,listMap,inFuncTypeTypeAToTypeB);
end listListMap;

public function listListMap_reversed "
  Takes a list of lists and a function producing one value.
  The function is applied to each element of the lists resulting
  in a new list of lists.
  This function reverses the inner list. 
  Example: listListMapReverse({ {1,2},{3},{4}},intString) => { {\"4\"},{\"3\"},{\"2\",\"1\"} }"
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
  outTypeBLstLst := listMap1(inTypeALstLst,listMap_reversed,inFuncTypeTypeAToTypeB);
end listListMap_reversed;

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
  match (inTypeALstLst,inFuncTypeTypeATypeBToTypeC,inTypeB)
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
  end match;
end listListMap1;

public function listListMap2 "function listListMap1
  author: BZ
  similar to listListMap but for functions taking three arguments.
  The second and third argument is passed as an extra argument."
  input list<list<Type_a>> inTypeALstLst;
  input FuncTypeType_aType_bToType_c inFuncTypeTypeATypeBToTypeC;
  input Type_b inTypeB;
  input Type_e inTypeE;
  output list<list<Type_c>> outTypeCLstLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bToType_c
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_e inTypeE;
    output Type_c outTypeC;
  end FuncTypeType_aType_bToType_c;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_e subtypeof Any;
algorithm
  outTypeCLstLst:=
  match (inTypeALstLst,inFuncTypeTypeATypeBToTypeC,inTypeB,inTypeE)
    local
      list<Type_c> f_1;
      list<list<Type_c>> r_1;
      list<Type_a> f;
      list<list<Type_a>> r;
      FuncTypeType_aType_bToType_c fn;
      Type_b e;
      Type_e d;
    case ({},_,_,_) then {};
    case ((f :: r),fn,e,d)
      equation
        f_1 = listMap2(f, fn, e, d);
        r_1 = listListMap2(r, fn, e, d);
      then
        (f_1 :: r_1);
  end match;
end listListMap2;

public function listFoldList "
Author BZ
apply a function on the heads of two equally length list of generic type.
"
input list<Type_a> lst1;
input list<Type_a> lst2;
input listAddFunc func;
output list<Type_a> mergedList;
  partial function listAddFunc
    input Type_a ia1;
    input Type_a ia2;
    output Type_a oa1;
  end listAddFunc;
  replaceable type Type_a subtypeof Any;
  algorithm
    mergedList := matchcontinue(lst1,lst2,func)
    local
      Type_a a1,a2,aRes;
      case({},{},_) then {};
      case(a1::lst1,a2::lst2,func)
        equation
          aRes = func(a1,a2);
          mergedList = listFoldList(lst1,lst2,func);
          then
            aRes::mergedList;
      end matchcontinue;
end listFoldList;

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
  match (inTypeALst,inFuncTypeTypeATypeBToTypeB,inTypeB)
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
  end match;
end listFold;

public function listFold1 "Like listFold, but relation takes an extra constant argument between the new element and the accumulated value"
  input list<Type_a> inTypeALst;
  input Func func;
  input Type_b inTypeB;
  input Type_c inTypeC;
  output Type_c outTypeC;
  partial function Func
    input Type_a inTypeA "current element";
    input Type_b inTypeB "extra constant";
    input Type_c inTypeC "accumulated value";
    output Type_c outTypeC;
  end Func;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  outTypeC :=
  match (inTypeALst,func,inTypeB,inTypeC)
    local
      Type_b b;
      Type_c c,c_1,c_2;
      Type_a l;
      list<Type_a> lst;
    case ({},func,b,c) then c;
    case ((l :: lst),func,b,c)
      equation
        c_1 = func(l, b, c);
        c_2 = listFold1(lst, func, b, c_1);
      then
        c_2;
  end match;
end listFold1;

public function listFoldR "function: listFoldR
  Similar to listFold but reversed argument order in function."
  input list<Type_a> lst;
  input FoldFunc foldFunc;
  input Type_b foldArg;
  output Type_b res;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FoldFunc
    input Type_b foldArg;
    input Type_a iterated;
    output Type_b ofoldArg;
  end FoldFunc;
algorithm
  res:=
  match (lst,foldFunc,foldArg)
    local
      Type_b foldArg1,foldArg2;
      Type_a l;
    case ({},foldFunc,foldArg) then foldArg;
    case ((l :: lst),foldFunc,foldArg)
      equation
        foldArg1 = foldFunc(foldArg,l);
        foldArg2 = listFoldR(lst, foldFunc,foldArg1);
      then
        foldArg2;
  end match;
end listFoldR;

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
    output Type_b ofoldArg;
  end FoldFunc;
algorithm
  res:=
  match (lst,foldFunc,foldArg,extraArg)
    local
      Type_b foldArg1,foldArg2;
      Type_a l;
    case ({},foldFunc,foldArg,extraArg) then foldArg;
    case ((l :: lst),foldFunc,foldArg,extraArg)
      equation
        foldArg1 = foldFunc(foldArg,extraArg,l);
        foldArg2 = listFold_2(lst, foldFunc,foldArg1, extraArg);
      then
        foldArg2;
  end match;
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
    output Type_b outFoldArg;
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

public function listFold_3 "function: listFold_3
  Similar to listFold but relation takes four arguments.
  The first argument is folded (i.e. passed through each relation)
  The second argument is constant (given as argument)
  The third argument is iterated over list."
  input list<Type_a> lst;
  input FoldFunc foldFunc;
  input Type_b foldArg;
  input Type_c extraArg;
  input Type_d extraArg2;
  output Type_b res;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  partial function FoldFunc
    input Type_b foldArg;
    input Type_a iterated;
    input Type_c extraArg;
    input Type_d extraArg2;
    output Type_b ofoldArg;
  end FoldFunc;
algorithm
  res:=
  match (lst,foldFunc,foldArg,extraArg,extraArg2)
    local
      Type_b foldArg1,foldArg2;
      Type_a l;
    case ({},foldFunc,foldArg,extraArg,extraArg2) then foldArg;
    case ((l :: lst),foldFunc,foldArg,extraArg,extraArg2)
      equation
        foldArg1 = foldFunc(foldArg,l,extraArg,extraArg2);
        foldArg2 = listFold_3(lst, foldFunc,foldArg1, extraArg, extraArg2);
      then
        foldArg2;
  end match;
end listFold_3;

public function listlistFoldMap "function: listlistFoldMap
  For example see Interactive.traverseExpression."
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
  match (inTypeALst,inFuncTypeTplTypeATypeBToTplTypeATypeB,inTypeB)
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
  end match;
end listlistFoldMap;

public function listFoldMap "function: listFoldMap
  author: PA
  For example see Expression.traverseExpression.
  This should be called listMapFold...
"
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
  match (inTypeALst,inFuncTypeTplTypeATypeBToTplTypeATypeB,inTypeB)
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
  end match;
end listFoldMap;

public function listListReverse "function: listListReverse
  Takes a list of lists and reverses it at both
  levels, i.e. both the list itself and each sublist
  Example: listListReverse({{1,2},{3,4,5},{6} }) => { {6}, {5,4,3}, {2,1} }"
  input list<list<Type_a>> lsts;
  output list<list<Type_a>> lsts_2;
  replaceable type Type_a subtypeof Any;
  list<list<Type_a>> lsts_1;
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

public function listMergeSorted
  "This function merges two sorted lists into one sorted list. It takes a
  comparison function that defines a strict weak ordering of the elements, i.e.
  that returns true if the first element should be placed before the second
  element in the sorted list."
  input list<Type_a> inList1;
  input list<Type_a> inList2;
  input CompFunc comp;
  output list<Type_a> outList;

  partial function CompFunc
    input Type_a inElem1;
    input Type_a inElem2;
    output Boolean res;
  end CompFunc;
  replaceable type Type_a subtypeof Any;
algorithm
  outList := matchcontinue(inList1, inList2, comp)
    local
      Type_a e1, e2;
      list<Type_a> l1, l2, res;
    case ({}, l2, _) then l2;
    case (l1, {}, _) then l1;
    case (e1 :: l1, l2 as (e2 :: _), _)
      equation
        true = comp(e1, e2);
        res = listMergeSorted(l1, l2, comp);
      then
        e1 :: res;
    case (l1, e2 :: l2, _)
      equation
        res = listMergeSorted(l1, l2, comp);
      then
        e2 :: res;
  end matchcontinue;
end listMergeSorted;

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
  match (inTypeALst,inTypeBLst,inFuncTypeTypeATypeBToTypeC)
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
  end match;
end listThreadMap;

public function listThread3Map "function: listThread3Map
  Takes two lists and a function and threads (interleaves) and maps the elements of the three lists
  creating a new list.
  Example: listThreadMap({1,2},{3,4},{5,6},intAdd3) => {1+3+5, 2+4+6}"
  input list<Type_a> inTypeALst;
  input list<Type_b> inTypeBLst;
  input list<Type_c> inTypeCLst;
  input FuncType fn;
  output list<Type_d> outTypeCLst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  partial function FuncType
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    output Type_d outTypeC;
  end FuncType;
algorithm
  outTypeCLst:=
  match (inTypeALst,inTypeBLst,inTypeCLst,fn)
    local
      Type_d fr;
      list<Type_d> res;
      Type_a fa;
      list<Type_a> ra;
      Type_b fb;
      list<Type_b> rb;
      Type_c fc;
      list<Type_c> rc;
    case ({},{},{},_) then {};
    case ((fa :: ra),(fb :: rb),(fc :: rc),fn)
      equation
        fr = fn(fa, fb, fc);
        res = listThread3Map(ra, rb, rc, fn);
      then
        (fr :: res);
  end match;
end listThread3Map;

public function listThreadMap1 "function: listThreadMap
  Takes two lists and a function and threads (interleaves) and maps the elements of the two lists
  creating a new list.
  the argument 4 is passed to the functioncall
  Example: listThreadMap({1,2},{3,4},intAdd) => {1+3, 2+4}"
  input list<Type_a> inTypeALst;
  input list<Type_b> inTypeBLst;
  input FuncTypeType_aType_bToType_c inFuncTypeTypeATypeBToTypeC;
  input Type_d inTypeD;
  output list<Type_c> outTypeCLst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_d subtypeof Any;
  partial function FuncTypeType_aType_bToType_c
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_d inTypeD;
    output Type_c outTypeC;
    replaceable type Type_c subtypeof Any;
  end FuncTypeType_aType_bToType_c;
  replaceable type Type_c subtypeof Any;
algorithm
  outTypeCLst:=
  match (inTypeALst,inTypeBLst,inFuncTypeTypeATypeBToTypeC,inTypeD)
    local
      Type_c fr;
      list<Type_c> res;
      Type_a fa;
      list<Type_a> ra;
      Type_b fb;
      list<Type_b> rb;
      FuncTypeType_aType_bToType_c fn;
      Type_d fd;
    case ({},{},_,_) then {};
    case ((fa :: ra),(fb :: rb),fn,fd)
      equation
        fr = fn(fa, fb, fd);
        res = listThreadMap1(ra, rb, fn, fd);
      then
        (fr :: res);
  end match;
end listThreadMap1;


public function listThreadMap3 "function: listThreadMap
  Takes two lists and a function and threads (interleaves) and maps the elements of the two lists
  creating a new list.
  the argument 4 - 6 are passed to the functioncall
  Example: listThreadMap({1,2},{3,4},intAdd) => {1+3, 2+4}"
  input list<Type_a> inTypeALst;
  input list<Type_b> inTypeBLst;
  input FuncTypeType_aType_bToType_c inFuncTypeTypeATypeBToTypeC;
  input Type_d inTypeD;
  input Type_e inTypeE;
  input Type_f inTypeF;
  output list<Type_c> outTypeCLst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
  replaceable type Type_f subtypeof Any;
  partial function FuncTypeType_aType_bToType_c
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_d inTypeD;
    input Type_e inTypeE;
    input Type_f inTypeF;
    output Type_c outTypeC;
    replaceable type Type_c subtypeof Any;
  end FuncTypeType_aType_bToType_c;
  replaceable type Type_c subtypeof Any;
algorithm
  outTypeCLst:=
  match (inTypeALst,inTypeBLst,inFuncTypeTypeATypeBToTypeC,inTypeD,inTypeE,inTypeF)
    local
      Type_c fr;
      list<Type_c> res;
      Type_a fa;
      list<Type_a> ra;
      Type_b fb;
      list<Type_b> rb;
      FuncTypeType_aType_bToType_c fn;
      Type_d fd;
      Type_e fe;
      Type_f ff;
    case ({},{},_,_,_,_) then {};
    case ((fa :: ra),(fb :: rb),fn,fd,fe,ff)
      equation
        fr = fn(fa, fb, fd, fe, ff);
        res = listThreadMap3(ra, rb, fn, fd, fe, ff);
      then
        (fr :: res);
  end match;
end listThreadMap3;


public function listThread3Map3 "function: listThreadMap
  Takes two lists and a function and threads (interleaves) and maps the elements of the two lists
  creating a new list.
  the argument 4 - 6 are passed to the functioncall
  Example: listThreadMap({1,2},{3,4},intAdd) => {1+3, 2+4}"
  input list<Type_a> inTypeALst;
  input list<Type_b> inTypeBLst;
  input list<Type_c> inTypeCLst;
  input FuncTypeType_aType_bType_cTotypeH inFuncTypeTypeATypeBToTypeH;
  input Type_d inTypeD;
  input Type_e inTypeE;
  input Type_f inTypeF;
  output list<Type_h> outTypeHLst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
  replaceable type Type_f subtypeof Any;
  replaceable type Type_h subtypeof Any;
  partial function FuncTypeType_aType_bType_cTotypeH
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d inTypeD;
    input Type_e inTypeE;
    input Type_f inTypeF;
    output Type_h outTypeH;
  end FuncTypeType_aType_bType_cTotypeH;
algorithm
  outTypeHLst:=
  match (inTypeALst,inTypeBLst,inTypeCLst,inFuncTypeTypeATypeBToTypeH,inTypeD,inTypeE,inTypeF)
    local
      Type_c fc;
      list<Type_c> rc;
      Type_a fa;
      list<Type_a> ra;
      Type_b fb;
      list<Type_b> rb;
      FuncTypeType_aType_bType_cTotypeH fn;
      Type_d fd;
      Type_e fe;
      Type_f ff;
      Type_h fr;
      list<Type_h> res;
    case ({},{},_,_,_,_,_) then {};
    case ((fa :: ra),(fb :: rb),(fc :: rc),fn,fd,fe,ff)
      equation
        fr = fn(fa, fb, fc, fd, fe, ff);
        res = listThread3Map3(ra, rb, rc, fn, fd, fe, ff);
      then
        (fr :: res);
  end match;
end listThread3Map3;

public function listlistThreadMap4 "function: listThreadMap
  Takes two lists and a function and threads (interleaves) and maps the elements of the two lists
  creating a new list.
  the argument 4 - 6 are passed to the functioncall
  Example: listThreadMap({1,2},{3,4},intAdd) => {1+3, 2+4}"
  input list<Type_a> inTypeALst;
  input list<Type_b> inTypeBLst;
  input list<Type_c> inTypeCLst;
  input FuncTypeType_aType_bType_cTotypeH inFuncTypeTypeATypeBToTypeH;
  input Type_d inTypeD;
  input Type_e inTypeE;
  input Type_f inTypeF;
  input Type_g inTypeG;
  output list<Type_h> outTypeHLst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
  replaceable type Type_f subtypeof Any;
  replaceable type Type_g subtypeof Any;
  replaceable type Type_h subtypeof Any;
  partial function FuncTypeType_aType_bType_cTotypeH
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeB;
    input Type_d inTypeD;
    input Type_e inTypeE;
    input Type_f inTypeF;
    input Type_g inTypeG;
    output Type_h outTypeH;
  end FuncTypeType_aType_bType_cTotypeH;
algorithm
  outTypeHLst:=
  match (inTypeALst,inTypeBLst,inTypeCLst,inFuncTypeTypeATypeBToTypeH,inTypeD,inTypeE,inTypeF,inTypeG)
    local
      Type_c fc;
      list<Type_c> rc;
      Type_a fa;
      list<Type_a> ra;
      Type_b fb;
      list<Type_b> rb;
      FuncTypeType_aType_bType_cTotypeH fn;
      Type_d fd;
      Type_e fe;
      Type_f ff;
      Type_g fg;
      Type_h fr;
      list<Type_h> res;
    case ({},{},_,_,_,_,_,_) then {};
    case ((fa :: ra),(fb :: rb),(fc :: rc),fn,fd,fe,ff,fg)
      equation
        fr = fn(fa, fb, fc, fd, fe, ff,fg);
        res = listlistThreadMap4(ra, rb, rc, fn, fd, fe, ff,fg);
      then
        (fr :: res);
  end match;
end listlistThreadMap4;


public function listThreadMap32 "function: listThreadMap32
  Takes three lists and a function and threads (interleaves) and maps the elements of the three lists
  creating two new lists.
  Example: listThreadMap({1,2},{3,4},{5,6},intAddSub3) => ({1+3+5, 2+4+6},{1-3-5, 2-4-6})"
  input list<Type_a> inTypeALst;
  input list<Type_b> inTypeBLst;
  input list<Type_c> inTypeCLst;
  input FuncTypeType_aType_bType_cToType_dType_e inFuncTypeTypeATypeBTypeCToTypeDTypeE;
  output list<Type_d> outTypeDLst;
  output list<Type_e> outTypeELst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
  partial function FuncTypeType_aType_bType_cToType_dType_e
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    output Type_d outTypeD;
    output Type_e outTypeE;
  end FuncTypeType_aType_bType_cToType_dType_e;
algorithm
  (outTypeDLst,outTypeELst) :=
  matchcontinue (inTypeALst,inTypeBLst,inTypeCLst,inFuncTypeTypeATypeBTypeCToTypeDTypeE)
    local
      Type_d fr_d;
      Type_e fr_e;
      list<Type_d> res_d;
      list<Type_e> res_e;
      Type_a fa;
      list<Type_a> ra;
      Type_b fb;
      list<Type_b> rb;
      Type_c fc;
      list<Type_c> rc;
      FuncTypeType_aType_bType_cToType_dType_e fn;
    case ({},{},{},_) then ({},{});
    case ((fa :: ra),(fb :: rb),(fc :: rc),fn)
      equation
        (fr_d,fr_e) = fn(fa, fb, fc);
        (res_d,res_e) = listThreadMap32(ra, rb, rc, fn);
      then
        (fr_d :: res_d, fr_e :: res_e);
  end matchcontinue;
end listThreadMap32;

public function listListThreadMap "function: listListThreadMap
  Takes two lists of lists and a function and threads (interleaves)
  and maps the elements  of the elements of the two lists creating a new list.
  Example: listListThreadMap({{1,2}},{{3,4}},intAdd) => {{1+3, 2+4}}"
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
      list<Type_c> fr;
      list<list<Type_c>> res;
      list<Type_a> fa;
      list<list<Type_a>> ra;
      list<Type_b> fb;
      list<list<Type_b>> rb;
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
  match (inTypeALst,inTypeBLst)
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
  end match;
end listThreadTuple;

public function listThread3Tuple "
  Takes three lists and threads (interleaves) the arguments into
  a list of tuples consisting of the three element types.
  Example: listThreadTuple({1,2,3},{true,false,true},{3,4,5}) => {(1,true,3),(2,false,4),(3,true,5)}"
  input list<Type_a> lst1;
  input list<Type_b> lst2;
  input list<Type_c> lst3;
  output list<tuple<Type_a, Type_b,Type_c>> outLst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  outLst :=
  match (lst1,lst2,lst3)
    local
      list<tuple<Type_a, Type_b,Type_c>> r;
      Type_a fa;
      list<Type_a> ra;
      Type_b fb;
      list<Type_b> rb;
      list<Type_c> rc;
      Type_c fc;
    case ({},{},{}) then {};
    case ((fa :: ra),(fb :: rb),(fc::rc))
      equation
        r = listThread3Tuple(ra, rb,rc);
      then
        ((fa,fb,fc) :: r);
  end match;
end listThread3Tuple;

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

public function listThreadFold
  "This is a combination of listThread and listFold that applies a function to
  the heads of two lists with an extra argument that is updated and passed on."
  input list<Type_a> inList_a;
  input list<Type_b> inList_b;
  input FuncType inFunc;
  input Type_c inFoldValue;
  output Type_c outFoldValue;

  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;

  partial function FuncType
    input Type_a inA;
    input Type_b inB;
    input Type_c inC;
    output Type_c outC;
  end FuncType;
algorithm
  outFoldValue := match(inList_a, inList_b, inFunc, inFoldValue)
    local
      Type_a a;
      Type_b b;
      Type_c c;
      list<Type_a> rest_a;
      list<Type_b> rest_b;
    case ({}, {}, _, _) then inFoldValue;
    case (a :: rest_a, b :: rest_b, _, _)
      equation
        c = inFunc(a, b, inFoldValue);
        c = listThreadFold(rest_a, rest_b, inFunc, c);
      then
        c;
  end match;
end listThreadFold;

public function selectFirstNonEmptyString "Selects the first non-empty string from a list of strings.
If all strings a empty or empty list return empty string.
"
input list<String> slst;
output String res;
algorithm
  res := matchcontinue(slst)
  local String s;
    case(s::slst) equation
      true = (s ==& "");
      res = selectFirstNonEmptyString(slst);
    then res;
    case(s::slst) equation
      false= (s ==& "");
    then s;
    case({}) then "";
  end matchcontinue;
end selectFirstNonEmptyString;

public function listSelectFirst "function: listSelectFirst
  This function retrieves the first element of a list for which
  the passed function evaluates to true."
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToBoolean inFuncTypeTypeAToBoolean;
  output Type_a outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToBoolean
    input Type_a inTypeA;
    output Boolean outBoolean;
  end FuncTypeType_aToBoolean;
algorithm
  outTypeALst:=
  matchcontinue (inTypeALst,inFuncTypeTypeAToBoolean)
    local
      list<Type_a> xs;
      Type_a x;
      FuncTypeType_aToBoolean cond;
    case ((x :: xs),cond)
      equation
        true = cond(x);
      then
        x;
    case ((x :: xs),cond) then listSelectFirst(xs, cond);
  end matchcontinue;
end listSelectFirst;

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
  outTypeALst := listSelect_tail(inTypeALst,inFuncTypeTypeAToBoolean, {});
end listSelect;

protected function listSelect_tail "function: listSelect_tail
  This function retrieves all elements of a list for which
  the passed function evaluates to true. The elements that
  evaluates to false are thus removed from the list."
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToBoolean inFuncTypeTypeAToBoolean;
  input list<Type_a> inAcc;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToBoolean
    input Type_a inTypeA;
    output Boolean outBoolean;
  end FuncTypeType_aToBoolean;
algorithm
  outTypeALst := match (inTypeALst,inFuncTypeTypeAToBoolean,inAcc)
    local
      list<Type_a> xs_1,xs, newLst;
      Type_a x;
      FuncTypeType_aToBoolean cond;
      Boolean res;
    
    // revese at end  
    case ({},_,inAcc) then listReverse(inAcc);
    // put in accumulator if result is true
    case ((x :: xs),cond,inAcc)
      equation
        res = cond(x);
        xs_1 = listSelect_tail(xs, cond, if_(res, x::inAcc, inAcc));
      then
        xs_1;
  end match;
end listSelect_tail;

public function listSelect1 "function listSelect1
  This function retrieves all elements of a list for which
  the passed function evaluates to true. The elements that
  evaluates to false are thus removed from the list.
  This function has an extra argument to testing function."
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
  outTypeALst := listSelect1_tail(inTypeALst,inTypeB,inFuncTypeTypeATypeBToBoolean,{});
end listSelect1;

protected function listSelect1_tail "function listSelect1_tail
  This function retrieves all elements of a list for which
  the passed function evaluates to true. The elements that
  evaluates to false are thus removed from the list.
  This function has an extra argument to testing function."
  input list<Type_a> inTypeALst;
  input Type_b inTypeB;
  input FuncTypeType_aType_bToBoolean inFuncTypeTypeATypeBToBoolean;
  input list<Type_a> inAcc;  
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncTypeType_aType_bToBoolean
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Boolean outBoolean;
  end FuncTypeType_aType_bToBoolean;
algorithm
  outTypeALst := match (inTypeALst,inTypeB,inFuncTypeTypeATypeBToBoolean,inAcc)
    local
      Type_b arg;
      list<Type_a> xs_1,xs;
      Type_a x;
      FuncTypeType_aType_bToBoolean cond;
      Boolean res;
    
    // revese at end
    case ({},arg,_,inAcc) then listReverse(inAcc);
    
    // collect the ones that match in the accumulator
    case ((x :: xs),arg,cond,inAcc)
      equation
        res = cond(x, arg);
        xs_1 = listSelect1_tail(xs, arg, cond, if_(res, x::inAcc, inAcc));
      then
        xs_1;
  end match;
end listSelect1_tail;

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
    input Type_c inTypeC;
    output Boolean outBoolean;
  end FuncTypeType_aType_bToBoolean;
algorithm
  outTypeALst := listSelect2_tail(inTypeALst,inTypeB,inTypeC,inFuncTypeTypeATypeBToBoolean,{});
end listSelect2;

protected function listSelect2_tail "function listSelect2_tail
  Same as listSelect above, but with extra argument to testing function."
  input list<Type_a> inTypeALst;
  input Type_b inTypeB;
  input Type_c inTypeC;
  input FuncTypeType_aType_bToBoolean inFuncTypeTypeATypeBToBoolean;
  input list<Type_a> inAcc;  
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  partial function FuncTypeType_aType_bToBoolean
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    output Boolean outBoolean;
  end FuncTypeType_aType_bToBoolean;
algorithm
  outTypeALst:= match (inTypeALst,inTypeB,inTypeC,inFuncTypeTypeATypeBToBoolean,inAcc)
    local
      Type_b arg1; Type_c arg2;
      list<Type_a> xs_1,xs;
      Type_a x;
      FuncTypeType_aType_bToBoolean cond;
      Boolean res;
    
    // revese at the end
    case ({},arg1,arg2,_,inAcc) then listReverse(inAcc);
    
    // collect into the accumulator if it matches!
    case ((x :: xs),arg1,arg2,cond,inAcc)
      equation
        res = cond(x, arg1,arg2);
        xs_1 = listSelect2_tail(xs, arg1,arg2, cond, if_(res, x::inAcc, inAcc));
      then
        xs_1;
  end match;
end listSelect2_tail;

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
  outTypeALst := listSelect1R_tail(inTypeALst,inTypeB,inFuncTypeTypeBTypeAToBoolean,{});
end listSelect1R;

protected function listSelect1R_tail "function listSelect1R_tail
  Same as listSelect1 above, but with swapped arguments."
  input list<Type_a> inTypeALst;
  input Type_b inTypeB;
  input FuncTypeType_bType_aToBoolean inFuncTypeTypeBTypeAToBoolean;
  input list<Type_a> inAcc;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncTypeType_bType_aToBoolean
    input Type_b inTypeB;
    input Type_a inTypeA;
    output Boolean outBoolean;
  end FuncTypeType_bType_aToBoolean;
algorithm
  outTypeALst := matchcontinue (inTypeALst,inTypeB,inFuncTypeTypeBTypeAToBoolean,inAcc)
    local
      Type_b arg;
      list<Type_a> xs_1,xs;
      Type_a x;
      Boolean res;
      FuncTypeType_bType_aToBoolean cond;
    
    // revese at the end
    case ({},arg,_,inAcc) then listReverse(inAcc);
    
    // collect in accumulator if it matches!
    case ((x :: xs),arg,cond,inAcc)
      equation
        res = cond(arg, x);
        xs_1 = listSelect1R_tail(xs, arg, cond, if_(res, x::inAcc, inAcc));
      then
        xs_1;
    
    /*// this case does NOT MATTER!!
    case ((x :: xs),arg,cond,inAcc)
      equation
        false = cond(arg, x);
        xs_1 = listSelect1R_tail(xs, arg, cond, inAcc);
      then
        xs_1;*/
  end matchcontinue;
end listSelect1R_tail;

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
  outInteger := matchcontinue (inTypeA,inTypeALst,inInteger)
    local
      Type_a x,y;
      list<Type_a> ys;
      Integer i,i_1,n;
    case (x,(y :: ys),i)
      equation
        equality(x = y);
      then
        i;
    case (x,(y :: ys),i)
      equation
        failure(equality(x = y));
        i_1 = i + 1;
        n = listPos(x, ys, i_1);
      then
        n;
  end matchcontinue;
end listPos;

public function listlistPosition "function: listPosition
  Takes a value and a list of values and returns the (first) position
  the value has in the list. Position index start at zero, such that
  listNth can be used on the resulting position directly.
  Example: listPosition(2,{0,1,2,3}) => 2"
  input Type_a x;
  input list<list<Type_a>> ys;
  output Integer n;
  replaceable type Type_a subtypeof Any;
algorithm
  n := listlistPos(x, ys, 0);
end listlistPosition;

protected function listlistPos "helper function to listPosition"
  input Type_a inTypeA;
  input list<list<Type_a>> inTypeALst;
  input Integer inInteger;
  output Integer outInteger;
  replaceable type Type_a subtypeof Any;
algorithm
  outInteger := matchcontinue (inTypeA,inTypeALst,inInteger)
    local
      Type_a x,y;
      list<Type_a> y1;
      list<list<Type_a>> ys;
      Integer i,i_1,n;
    case (x,((y::{}):: ys),i)
      equation
        equality(x = y);
      then
        i;
    case (x,((y::{}) :: ys),i)
      equation
        failure(equality(x = y));
        i_1 = i + 1;
        n = listlistPos(x, ys, i_1);
      then
        n;
    case (x,((y1) :: ys),i)
      equation
        //failure(equality(x = y1));
        //i_1 = i + 1;
        true = listPos2(x, y1);
      then
        i;
    case (x,(y1 :: ys),i)
      equation
        false = listPos2(x, y1);
        i_1 = i + 1;
        n = listlistPos(x, ys, i_1);
      then
        n;
  end matchcontinue;
end listlistPos;

protected function listPos2 "helper function to listlistPos"
  input Type_a inTypeA;
  input list<Type_a> inTypeALst;
  output Boolean outInteger;
  replaceable type Type_a subtypeof Any;
algorithm
  outInteger := matchcontinue (inTypeA,inTypeALst)
    local
      Type_a x,y;
      list<Type_a> ys;
      Boolean a;
    case (_,{}) then false;
    case (x,(y :: ys))
      equation
        equality(x = y);
      then
        true;
    case (x,(y :: ys))
      equation
        failure(equality(x = y));
        a = listPos2(x, ys);
        //print("Found with i " +& intString(i) +& " a n: " +& intString(n) +& "\n");
      then
        a;
  end matchcontinue;
end listPos2;

public function listGetMember
 "Takes a value and a list of values and returns the value
  if present in the list. If not present, the function will fail.
  Example:
    listGetMember(0,{1,2,3}) => fail
    listGetMember(1,{1,2,3}) => 1"
  input Type_a inTypeA;
  input list<Type_a> inTypeALst;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeA := match (inTypeA,inTypeALst)
    local
      Type_a x,y,res;
      list<Type_a> ys;
    case (_,{}) then fail();
    case (x,(y :: ys)) then Debug.bcallret2(not valueEq(x,y), listGetMember, x, ys, x);
  end match;
end listGetMember;

public function listDeletePositionsSorted "more efficient implemtation of deleting positions if the position list is sorted
in ascending order. Then it can be done in one traversal => O(n)"
  input list<Type_a> lst;
  input list<Integer> positions;
  output list<Type_a> outLst;
  replaceable type Type_a subtypeof Any;
algorithm
  outLst := listDeletePositionsSorted2(lst,positions,0);
end listDeletePositionsSorted;

public function listDeletePositionsSorted2 "Help function to listDeletePositionsSorted"
  input list<Type_a> lst;
  input list<Integer> positions;
  input Integer n;
  output list<Type_a> outLst;
  replaceable type Type_a subtypeof Any;
algorithm
  outLst := matchcontinue(lst,positions,n)
  local Type_a l; Integer p;
    case(lst,{},n) then lst;
    case(l::lst,p::positions,n) 
      equation
        true = p == n "remove";
        positions = removeMatchesFirst(positions,n) "allows duplicate position elements";
        lst = listDeletePositionsSorted2(lst,positions,n+1);
      then lst;
    case(l::lst,positions as (p::_),n) 
      equation
        false = p == n "keep";
        lst = listDeletePositionsSorted2(lst,positions,n+1);
      then l::lst;
  end matchcontinue;
end listDeletePositionsSorted2;

protected function removeMatchesFirst "removes all matching elements that occur first in list. If first element doesn't match, return"
  input list<Integer> lst;
  input Integer n;
  output list<Integer> outLst;
algorithm
  outLst := matchcontinue(lst,n)
    local Integer l;
    case(l::lst,n) 
      equation
        true = l == n;
        lst = removeMatchesFirst(lst,n);
      then lst;
    case(lst,n) then lst;
  end matchcontinue;
end removeMatchesFirst;

public function listDeletePositions "Takes a list and a list of positions and deletes the positions from the list.
Note that positions are indexed from 0..n-1

For example listDeletePositions({1,2,3,4,5},{2,0,3}) => {2,5}"
  input list<Type_a> lst;
  input list<Integer> positions;
  output list<Type_a> outLst;
  replaceable type Type_a subtypeof Any;
algorithm
  outLst := listDeletePositions2(0,lst,positions);
end listDeletePositions;

protected function listDeletePositions2 "help function to listDeletePositions"
  input Integer p;
  input list<Type_a> lst;
  input list<Integer> positions;
  output list<Type_a> outLst;
  replaceable type Type_a subtypeof Any;
algorithm
  outLst := matchcontinue(p,lst,positions)
  local Type_a el;
    case(p,lst,{}) then lst;
    case(p,{},positions) then {};
    case(p,el::lst,positions) equation
      positions = listDeleteMemberF(positions,p);
      lst = listDeletePositions2(p+1,lst,positions);
    then lst;
    case(p,el::lst,positions) equation
        lst = listDeletePositions2(p+1,lst,positions);
    then el::lst;
  end matchcontinue;
end listDeletePositions2;

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

public function listDeleteMemberF "
  Similar to listDeleteMember but fails if element is not present"
  input list<Type_a> inTypeALst;
  input Type_a inTypeA;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:=
  match (inTypeALst,inTypeA)
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
  end match;
end listDeleteMemberF;

public function listDeleteMemberOnTrue
  "Takes a list and a value and a comparison function and deletes the first
  occurence of the value in the list for which the function returns true. It
  returns the new list and the deleted element, or only the original list if
  no element was removed.
    Example: listDeleteMemberOnTrue({1,2,3,2},2,intEq) => {1,3,2}"
  input TypeA inValue;
  input list<TypeB> inList;
  input CompareFunc inCompareFunc;
  output list<TypeB> outList;
  output Option<TypeB> outDeletedElement;

  replaceable type TypeA subtypeof Any;
  replaceable type TypeB subtypeof Any;

  partial function CompareFunc
    input TypeA inTypeA;
    input TypeB inTypeB;
    output Boolean outIsEqual;
  end CompareFunc;
algorithm
  (outList, outDeletedElement) := matchcontinue(inValue, inList, inCompareFunc)
    local
      TypeB e;
      list<TypeB> el;
      Boolean is_equal;

    case (_, e :: _, _)
      equation
        is_equal = inCompareFunc(inValue, e);
        (el, e) = listDeleteMemberOnTrue_tail(inValue, inList, inCompareFunc,
          {}, is_equal);
      then
        (el, SOME(e));

    else then (inList, NONE());
  end matchcontinue;
end listDeleteMemberOnTrue;

public function listDeleteMemberOnTrue_tail
  input TypeA inValue;
  input list<TypeB> inList;
  input CompareFunc inCompareFunc;
  input list<TypeB> inAccumList;
  input Boolean inIsEqual;
  output list<TypeB> outList;
  output TypeB outDeletedElement;

  replaceable type TypeA subtypeof Any;
  replaceable type TypeB subtypeof Any;

  partial function CompareFunc
    input TypeA inTypeA;
    input TypeB inTypeB;
    output Boolean outIsEqual;
  end CompareFunc;
algorithm
  (outList, outDeletedElement) := 
  match(inValue, inList, inCompareFunc, inAccumList, inIsEqual)
    local
      TypeB e, e2;
      list<TypeB> el, accum_el;
      Boolean is_equal;

    case (_, e :: el, _, _, true)
      then (listAppend(listReverse(inAccumList), el), e);

    case (_, e :: (el as e2 :: _), _, _, _)
      equation
        accum_el = e :: inAccumList;
        is_equal = inCompareFunc(inValue, e2);
        (el, e) = listDeleteMemberOnTrue_tail(inValue, el, inCompareFunc,
          accum_el, is_equal);
      then
        (el, e);
  end match;
end listDeleteMemberOnTrue_tail;
  
        

//public function listDeleteMemberOnTrue "function: listDeleteMemberOnTrue
//  Takes a list and a value and a comparison function and deletes the first
//  occurence of the value in the list for which the function returns true.
//  Example: listDeleteMemberOnTrue({1,2,3,2},2,intEq) => {1,3,2}"
//  input list<Type_a> inTypeALst;
//  input Type_a inTypeA;
//  input FuncTypeType_aType_aToBoolean inFuncTypeTypeATypeAToBoolean;
//  output list<Type_a> outTypeALst;
//  replaceable type Type_a subtypeof Any;
//  partial function FuncTypeType_aType_aToBoolean
//    input Type_a inTypeA1;
//    input Type_a inTypeA2;
//    output Boolean outBoolean;
//  end FuncTypeType_aType_aToBoolean;
//algorithm
//  outTypeALst:=
//  matchcontinue (inTypeALst,inTypeA,inFuncTypeTypeATypeAToBoolean)
//    local
//      Type_a elt_1,elt;
//      Integer pos;
//      list<Type_a> lst_1,lst;
//      FuncTypeType_aType_aToBoolean cond;
//    case (lst,elt,cond)
//      equation
//        elt_1 = listGetMemberOnTrue(elt, lst, cond) "A bit ugly" ;
//        pos = listPosition(elt_1, lst);
//        lst_1 = listDelete(lst, pos);
//      then
//        lst_1;
//    case (lst,_,_) then lst;
//  end matchcontinue;
//end listDeleteMemberOnTrue;

public function listGetMemberOnTrue "function listGetmemberOnTrue
  Takes a value and a list of values and a comparison function over two values.
  If the value is present in the list (using the comparison function returning true)
  the value is returned, otherwise the function fails.
  Example:
    function equalLength(string,string) returns true if the strings are of same length
    listGetMemberOnTrue(\"a\",{\"bb\",\"b\",\"ccc\"},equalLength) => \"b\""
  input Type_a inTypeA;
  input list<Type_b> inTypeBLst;
  input FuncType inFunc;
  output Type_b outTypeB;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncType
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Boolean outBoolean;
  end FuncType;
algorithm
  outTypeB:=
  matchcontinue (inTypeA,inTypeBLst,inFunc)
    local
      FuncType p;
      Type_a x;
      Type_b y,res;
      list<Type_b> ys;
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
  input Type_a a;
  input list<Type_a> lst;
  output list<Type_a> outLst;
  replaceable type Type_a subtypeof Any;
algorithm
  outLst := listConsOnTrue(not listMember(a,lst),a,lst);
end listUnionElt;

public function listUnionEltComp
  "Works as listUnionElt, but with a compare function."
  input Type_a inElem;
  input list<Type_a> inList;
  input CompareFunc inCompFunc;
  output list<Type_a> outList;
  partial function CompareFunc
    input Type_a inElem1;
    input Type_a inElem2;
    output Boolean res;
  end CompareFunc;
  replaceable type Type_a subtypeof Any;
algorithm
  outList := listConsOnTrue(not listContainsWithCompareFunc(inElem,inList,inCompFunc),inElem,inList);
end listUnionEltComp;

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
  match (inTypeALst1,inTypeALst2)
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
  end match;
end listUnion;

public function listUnionComp
  "Works as listUnion, but with a compare function."
  input list<Type_a> inList1;
  input list<Type_a> inList2;
  input CompareFunc inCompFunc;
  output list<Type_a> outList;
  partial function CompareFunc
    input Type_a inElem1;
    input Type_a inElem2;
    output Boolean res;
  end CompareFunc;
  replaceable type Type_a subtypeof Any;
algorithm
  outList := match(inList1, inList2, inCompFunc)
    local
      list<Type_a> res, xs;
      Type_a x;
    case ({}, {}, _) 
      then {};
    case ({}, x :: xs, _) 
      then listUnionEltComp(x, listUnionComp({}, xs, inCompFunc), inCompFunc);
    case ((x :: xs), _, _)
      equation
        res = listUnionComp(xs, inList2, inCompFunc);
        res = listUnionEltComp(x, res, inCompFunc);
      then
        res;
  end match;
end listUnionComp;

public function listListUnion "function: listListUnion
  Takes a list of lists and returns the union of the sublists
  Example: listListUnion({{1},{1,2},{3,4},{5}}) => {1,2,3,4,5}"
  input list<list<Type_a>> inTypeALstLst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:=
  match (inTypeALstLst)
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
  end match;
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

public function equal "
This function is intended to be a replacement for equality,
when sending function as an input argument."
  input Type_a arg1;
  input Type_a arg2;
  output Boolean b;
  replaceable type Type_a subtypeof Any;
algorithm b := matchcontinue(arg1,arg2)
  case(arg1,arg2)
    equation
      equality(arg1 = arg2);
    then
      true;
  case(_,_) then false;
end matchcontinue;
end equal;

public function listlistFunc "Function: listlistFunc
If we have one list to apply function over several lists we can use this function.
it takes list A and list<list B a function and an extra argument(maby make extra argument optional).
It uses function(a,b[x],extarg)
Ex:
listlistFunc({1,2,3},{{3,4,5},{3,6,7}},listUnionOntrue,equal);
will act as
listUnionOnTrue({1,2,3},{3,4,5},equal); => {1,2,3,4,5}
then; listUnionOnTrue({1,2,3,4,5},{3,6,7},equal); => {1,2,3,4,5,6,7}
"
  input list<Type_a> inTypeALst1;
  input list<list<Type_a>> inTypeALst2;
  input FuncTypeType_aType_aToType_b inFunc;
  input Type_c extArg;
  output list<Type_a> outTypeALst;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_a subtypeof Any;
    partial function FuncTypeType_aType_aToType_b
    input list<Type_a> inTypeA1;
    input list<Type_a> inTypeA2;
    input Type_c inTypeC;
    output list<Type_a> outTypeA;
  end FuncTypeType_aType_aToType_b;
algorithm outTypeALst := matchcontinue(inTypeALst1,inTypeALst2,inFunc,extArg)
  local
    list<Type_a> out1;
    list<Type_a> out2;
    list<list<Type_a>> blocks;
    list<Type_a> block_;
  case(inTypeALst1,{},inFunc,extArg) then inTypeALst1;
  case(inTypeALst1, ((block_ as (_::(_)))::blocks) ,inFunc,extArg)
    equation
      out1 = inFunc(inTypeALst1,block_,extArg);
      out2 = listlistFunc(out1,blocks,inFunc,extArg);
      then
        out2;
  case(inTypeALst1, ((block_ as {}) :: blocks) ,inFunc,extArg)
    equation
      out2 = listlistFunc(inTypeALst1,blocks,inFunc,extArg);
    then
      out2;
  case(inTypeALst1, ((block_ as _) :: blocks) ,inFunc,extArg)
    equation
      out1 = inFunc(inTypeALst1,block_,extArg);
      out2 = listlistFunc(out1,blocks,inFunc,extArg);
    then
      out2;
end matchcontinue;
end listlistFunc;

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
  match (inTypeALst1,inTypeALst2,inFuncTypeTypeATypeAToBoolean3)
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
  end match;
end listUnionOnTrue;

public function listRemoveNth
  "Removes the nth element of a list, starting with index 1.
   Example: listRemove({1,2,3,4,5},2) => {1,3,4,5}"
  input list<TypeA> inList;
  input Integer inPos;
  output list<TypeA> outList;
  replaceable type TypeA subtypeof Any;
algorithm
  outList := matchcontinue(inList, inPos)
    local
      TypeA e;
      list<TypeA> el;
    case (e :: el, 1) then el;
    case (e :: el, _)
      equation
        true = inPos > 0;
        el = listRemoveNth(el, inPos - 1);
      then
        e :: el;
  end matchcontinue;
end listRemoveNth;

public function listRemoveOnTrue "
Go trough a list and when function is true, remove that element.
"
  input Type_b inTypeALst1;
  input FuncTypeType_aType_bToBoolean inFuncTypeTypeATypeBToBoolean3;
  input list<Type_a> inTypeALst2;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncTypeType_aType_bToBoolean
    input Type_b inTypeA1;
    input Type_a inTypeA2;
    output Boolean outBoolean;
  end FuncTypeType_aType_bToBoolean;
algorithm
  outTypeALst:=
  matchcontinue (inTypeALst1,inFuncTypeTypeATypeBToBoolean3,inTypeALst2)
    local
      list<Type_a> res,xs;
      FuncTypeType_aType_bToBoolean p;
      Type_a y;
      Type_b x;
    case (x,p,{}) then {};
    case (x,p,y::xs)
      equation
         true = p(x,y);
         res = listRemoveOnTrue(x, p, xs);
      then
        res;
    case (x,p,y::xs)
      equation
        false = p(x,y);
        res = listRemoveOnTrue(x, p, xs);
      then
        y::res;
  end matchcontinue;
end listRemoveOnTrue;

public function listRemoveFirstOnTrue
  "Removes the first element from the list that matches the given element, using
  a boolean function. Ex:
    listRemoveFirstOnTrue(3, intEq, {2,3,4,3}) = {2,4,3}"
  input Type_a inCompElement;
  input FuncType inFunc;
  input list<Type_b> inList;
  output list<Type_b> outList;

  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
 
  partial function FuncType
    input Type_a e1;
    input Type_b e2;
    output Boolean res;
  end FuncType;
algorithm
  outList := matchcontinue(inCompElement, inFunc, inList)
    local
      Type_b e;
      list<Type_b> rest;
      
    case (_, _, {}) then {};
    case (_, _, e :: rest)
      equation
        true = inFunc(inCompElement, e);
      then
        rest;
    case (_, _, e :: rest)
      equation
        rest = listRemoveFirstOnTrue(inCompElement, inFunc, rest);
      then
        e :: rest;
  end matchcontinue;
end listRemoveFirstOnTrue;

public function listIntersectionIntN "provides same functionality as listIntersection, but for integer values between 1 and N
The complexity in this case is O(n)"
  input list<Integer> s1;
  input list<Integer> s2;
  input Integer N;
  output list<Integer> res;
protected array<Integer> a1,a2;
algorithm
  a1:= arrayCreate(N,0);
  a2:= arrayCreate(N,0);
  a1 := listSetPos(s1,a1,1);
  a2 := listSetPos(s2,a2,1);
  res := listIntersectionIntVec(a1,a2,1);
end listIntersectionIntN;

protected function listIntersectionIntVec " help function to listIntersectionIntN"
  input array<Integer> a1;
  input array<Integer> a2;
  input Integer indx;
  output list<Integer> res;
algorithm
  res := matchcontinue(a1,a2,indx)
    case(a1,a2,indx) equation
      true = indx > arrayLength(a1) or indx > arrayLength(a2);
    then {};
    case(a1,a2,indx) equation
      true = a1[indx]==1 and a2[indx]==1;
      res = listIntersectionIntVec(a1,a2,indx+1);
    then indx::res;
    case(a1,a2,indx) equation
      false = a1[indx]==1 and a2[indx]==1;
      res = listIntersectionIntVec(a1,a2,indx+1);
    then res;
  end matchcontinue;
end listIntersectionIntVec;

protected function listSetPos "Help function to listIntersectionIntN"
  input list<Integer> intLst;
  input array<Integer> arr;
  input Integer v;
  output array<Integer> outArr;
algorithm
  outArr := matchcontinue(intLst,arr,v)
  local Integer i;
    case({},arr,v) then arr;
    case(i::intLst,arr,v) equation
      arr = arrayUpdate(arr,i,v);
      arr = listSetPos(intLst,arr,v);
    then arr;
    case(i::_,arr,v) equation
      failure(_ = arrayUpdate(arr,i,1));
      print("Internal error in listSetPos, index = "+&intString(i)+&" but array size is "+&intString(arrayLength(arr))+&"\n");
    then fail();
  end matchcontinue;
end listSetPos;

public function listUnionIntN "provides same functionality as listUnion, but for integer values between 1 and N
The complexity in this case is O(n)"
  input list<Integer> s1;
  input list<Integer> s2;
  input Integer N;
  output list<Integer> res;
protected array<Integer> a1,a2;
algorithm
  a1:= arrayCreate(N,0);
  a2:= arrayCreate(N,0);
  a1 := listSetPos(s1,a1,1);
  a2 := listSetPos(s2,a2,1);
  res := listUnionIntVec(a1,a2,1);
end listUnionIntN;

protected function listUnionIntVec " help function to listIntersectionIntN"
  input array<Integer> a1;
  input array<Integer> a2;
  input Integer indx;
  output list<Integer> res;
algorithm
  res := matchcontinue(a1,a2,indx)
    case(a1,a2,indx) equation
      true = indx > arrayLength(a1) or indx > arrayLength(a2);
    then {};
    case(a1,a2,indx) equation
      true = a1[indx]==1 or a2[indx]==1;
      res = listUnionIntVec(a1,a2,indx+1);
    then indx::res;
    case(a1,a2,indx) equation
      false = a1[indx]==1 or a2[indx]==1;
      res = listUnionIntVec(a1,a2,indx+1);
    then res;
  end matchcontinue;
end listUnionIntVec;

public function listSetDifferenceIntN "provides same functionality as listSetDifference, but for integer values between 1 and N
The complexity in this case is O(n)"
  input list<Integer> s1;
  input list<Integer> s2;
  input Integer N;
  output list<Integer> res;
protected array<Integer> a1,a2;
algorithm
  a1:= arrayCreate(N,0);
  a2:= arrayCreate(N,0);
  a1 := listSetPos(s1,a1,1);
  a2 := listSetPos(s2,a2,1);
  res := listSetDifferenceIntVec(a1,a2,1);
end listSetDifferenceIntN;

protected function listSetDifferenceIntVec " help function to listIntersectionIntN"
  input array<Integer> a1;
  input array<Integer> a2;
  input Integer indx;
  output list<Integer> res;
algorithm
  res := matchcontinue(a1,a2,indx)
    case(a1,a2,indx) equation
      true = indx > arrayLength(a1) or indx > arrayLength(a2);
    then {};
    case(a1,a2,indx) equation
      true = a1[indx] - a2[indx] <> 0;
      res = listSetDifferenceIntVec(a1,a2,indx+1);
    then indx::res;
    case(a1,a2,indx) equation
      false = a1[indx] - a2[indx] <> 0;
      res = listSetDifferenceIntVec(a1,a2,indx+1);
    then res;
  end matchcontinue;
end listSetDifferenceIntVec;

public function listIntersectionOnTrue "function: listIntersectionOnTrue
  Takes two lists and a comparison function over two elements of the list.
  It returns the intersection of the two lists, using the comparison function passed as
  argument to determine identity between two elements.
  Example:
    given the function stringEq(string,string) returning true if the strings are equal
    listIntersectionOnTrue({\"a\",\"aa\"},{\"b\",\"aa\"},stringEq) => {\"aa\"}"
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

public function listIntersectionOnTrue1 "function: listIntersectionOnTrue1
  Takes two lists and a comparison function over two elements of the list.
  It returns the intersection of the two lists, using the comparison function passed as
  argument to determine identity between two elements. A list of the elements from
  list a which not in list b and a list of the elements from list b which not in list a;
  Example:
    given the function stringEq(string,string) returning true if the strings are equal
    listIntersectionOnTrue({\"a\",\"aa\"},{\"b\",\"aa\"},stringEq) => ({\"aa\"},{\"a\"},{\"b\"})"
  input list<Type_a> inTypeALst1;
  input list<Type_a> inTypeALst2;
  input FuncTypeType_aType_aToBoolean inFuncTypeTypeATypeAToBoolean3;
  output list<Type_a> outTypeALst;
  output list<Type_a> outTypeA1Lst;
  output list<Type_a> outTypeA2Lst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_aToBoolean
    input Type_a inTypeA1;
    input Type_a inTypeA2;
    output Boolean outBoolean;
  end FuncTypeType_aType_aToBoolean;
algorithm
  (outTypeALst,outTypeA1Lst):=listIntersectionOnTrue1_help(inTypeALst1,inTypeALst2,inFuncTypeTypeATypeAToBoolean3);
  outTypeA2Lst := listSetDifferenceOnTrue(inTypeALst2,outTypeALst,inFuncTypeTypeATypeAToBoolean3);
end listIntersectionOnTrue1;

protected function listIntersectionOnTrue1_help "function: listIntersectionOnTrue1_help"
  input list<Type_a> inTypeALst1;
  input list<Type_a> inTypeALst2;
  input FuncTypeType_aType_aToBoolean inFuncTypeTypeATypeAToBoolean3;
  output list<Type_a> outTypeALst;
  output list<Type_a> outTypeA1Lst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_aToBoolean
    input Type_a inTypeA1;
    input Type_a inTypeA2;
    output Boolean outBoolean;
  end FuncTypeType_aType_aToBoolean;
algorithm
  (outTypeALst,outTypeA1Lst):=
  matchcontinue (inTypeALst1,inTypeALst2,inFuncTypeTypeATypeAToBoolean3)
    local
      list<Type_a> res,res1,xs1,xs2;
      Type_a x1;
      FuncTypeType_aType_aToBoolean cond;
    case ({},_,_) then ({},{});
    case ((x1 :: xs1),xs2,cond)
      equation
        _ = listGetMemberOnTrue(x1, xs2, cond);
        (res,res1) = listIntersectionOnTrue1_help(xs1, xs2, cond);
      then
        (x1 :: res,res1);
    case ((x1 :: xs1),xs2,cond)
      equation
        (res,res1) = listIntersectionOnTrue1_help(xs1, xs2, cond) "not list_getmember_p(x1,xs2,cond) => _" ;
      then
        (res,x1::res1);
  end matchcontinue;
end listIntersectionOnTrue1_help;

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
     local list<Type_a> lst;
     case (lst1,lst2,compare)
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
    case ({},_,cond) then {};  /* Empty - B = Empty */      
    case (a,{},cond) then a;  /* A B */
    case (a,(x1 :: xs),cond)
      equation
        (a_1, _) = listDeleteMemberOnTrue(x1, a, cond);
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

public function listSetDifference "
 Takes two lists and returns the set difference of the two lists A-B.
 Example:
   listSetDifferenceOnTrue({\"a\",\"b\",\"c\"},{\"a\",\"c\"}) => {\"b\"}
   comparisons is done using the builtin equality mechanism."
  input list<Type_a> A;
  input list<Type_a> B;
  output list<Type_a> res;
  replaceable type Type_a subtypeof Any;
algorithm
  res := matchcontinue (A,B)
    local
      list<Type_a> a,a_1,a_2,xs;
      Type_a x1;
    
    case ({},_) then {};  /* Empty - B = Empty */    
    case (a,{}) then a;  /* A B */
    case (a,(x1 :: xs))
      equation
        a_1 = listDeleteMember(a, x1);
        a_2 = listSetDifference(a_1, xs);
      then
        a_2;
    case (_,_)
      equation
        print("- Util.listSetDifference failed\n");
      then
        fail();
  end matchcontinue;
end listSetDifference;

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
  outTypeALst := match (inTypeALstLst,inFuncTypeTypeATypeAToBoolean)
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
  end match;
end listListUnionOnTrue;

// stefan
public function listReplaceAtWithList
"function: listReplaceAtWithList
  Takes a list, a position, and a list to replace that position
  Replaces the element at the position with the given list
  Example: listReplaceAt({\"A\",\"B\"},1,{\"foo\",\"bar\",\"baz\"}) => {\"foo\",\"A\",\"B\",\"baz\"}"
  input list<Type_a> inReplacementList;
  input Integer inPosition;
  input list<Type_a> inList;
  output list<Type_a> outList;
  replaceable type Type_a subtypeof Any;
algorithm
  outList := matchcontinue (inReplacementList,inPosition,inList)
    local
      list<Type_a> rlst,olst,split1,split2,res,res_1;
      Integer n,n_1;
      Type_a foo;
    case(rlst,0,foo :: olst)
      equation
        res = listAppend(rlst,olst);
      then res;
    case(rlst,n,olst)
      equation
        (split1,_) = listSplit(olst,n);
        n_1 = n + 1;
        (_,split2) = listSplit(olst,n_1);
        res = listAppend(split1,rlst);
        res_1 = listAppend(res,split2);
      then
        res_1;
  end matchcontinue;
end listReplaceAtWithList;

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
        res_1 = listReverse(x::res);
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
  Example: listReduce({1,2,3},intAdd) => 6"
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
  outTypeA := match (inTypeALst,inFuncTypeTypeATypeAToTypeA)
    local
      Type_a e,res,a,b,res1;
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
        // res = listReduce_tail(xs, r, res1);
        res = listReduce(res1::xs, r);
      then
        res;
    // failure, we can't reduce an empty list!
    case ({},r)
      equation
        Debug.fprintln("failtrace", "- Util.listReduce failed on empty list!");
      then fail();
  end match;
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


public function arrayReplaceAtWithFill "
  Takes
  - an element,
  - a position (1..n)
  - an array and
  - a fill value
  The function replaces the value at the given position in the array, if the given position is
  out of range, the fill value is used to padd the array up to that element position and then
  insert the value at the position.
  Example:
    arrayReplaceAtWithFill(\"A\", 5, {\"a\",\"b\",\"c\"},\"dummy\") => {\"a\",\"b\",\"c\",\"dummy\",\"A\"}"
  input Type_a inTypeA1;
  input Integer inInteger2;
  input array<Type_a> inTypeAArray3;
  input Type_a inTypeA4;
  output array<Type_a> outTypeAArray;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeAArray:=
  matchcontinue (inTypeA1,inInteger2,inTypeAArray3,inTypeA4)
    local
      Integer alen,pos;
      array<Type_a> res,arr,newarr,res_1;
      Type_a x,fillv;
    case (x,pos,arr,fillv)
      equation
        alen = arrayLength(arr) "Replacing element with index in range of the array" ;
        (pos <= alen) = true;
        res = arrayUpdate(arr, pos , x);
      then
        res;
    case (x,pos,arr,fillv)
      equation
        //Replacing element out of range of array, create new array, and copy elts.
        newarr = arrayCreate(pos, fillv);
        res = arrayCopy(arr, newarr);
        res_1 = arrayUpdate(res, pos , x);
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
  input array<Type_a> arr;
  input Type_a v;
  output array<Type_a> newarr_1;
  replaceable type Type_a subtypeof Any;
protected
  Integer len,newlen;
  array<Type_a> newarr;
algorithm
  len := arrayLength(arr);
  newlen := n + len;
  newarr := arrayCreate(newlen, v);
  newarr_1 := arrayCopy(arr, newarr);
end arrayExpand;

public function arrayNCopy "function arrayNCopy
  Copeis n elements in src array into dest array
  The function fails if all elements can not be fit into dest array."
  input array<Type_a> src;
  input array<Type_a> dst;
  input Integer n;
  output array<Type_a> dst_1;
  replaceable type Type_a subtypeof Any;
protected
  Integer n_1;
algorithm
  n_1 := n - 1;
  dst_1 := arrayCopy2(src, dst, n_1);
end arrayNCopy;

public function arrayAppend "Function: arrayAppend
function for appending two arrays"
  input array<Type_a> arr1;
  input array<Type_a> arr2;
  output array<Type_a> out;
  replaceable type Type_a subtypeof Any;
protected
  list<Type_a> l1,l2,l3;
algorithm
  l1 := arrayList(arr1);
  l2 := arrayList(arr2);
  l3 := listAppend(l1,l2);
  out := listArray(l3);
end arrayAppend;

public function arrayCopy "function: arrayCopy
  copies all values in src array into dest array.
  The function fails if all elements can not be fit into dest array."
  input array<Type_a> inTypeAArray1;
  input array<Type_a> inTypeAArray2;
  output array<Type_a> outTypeAArray;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeAArray:=
  matchcontinue (inTypeAArray1,inTypeAArray2)
    local
      Integer srclen,dstlen;
      array<Type_a> src,dst,dst_1;
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
  input array<Type_a> inTypeAArray1;
  input array<Type_a> inTypeAArray2;
  input Integer inInteger3;
  output array<Type_a> outTypeAArray;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeAArray:=
  match (inTypeAArray1,inTypeAArray2,inInteger3)
    local
      array<Type_a> src,dst,dst_1,dst_2;
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
  end match;
end arrayCopy2;

public function makeTuple "
Author BZ: 2008-11
Create a tuple list from two lists
"
input list<Type_a> t1;
input list<Type_b> t2;
output list<tuple<Type_a,Type_b>> ot;
replaceable type Type_a subtypeof Any;
replaceable type Type_b subtypeof Any;
algorithm ot := matchcontinue(t1,t2)
  local
    Type_a a;
    Type_b b;
  case({},{}) then {}; // enforce equal length of lists
  case(a::t1,b::t2)
    equation
      ot = makeTuple(t1,t2);
      then
        (a,b)::ot;
  case(_,_) equation print(" failure in makeTuple \n"); then fail();
end matchcontinue;
end makeTuple;

public function tuple21 "function: tuple21
  Takes a tuple of two values and returns the first value.
  Example: tuple21((\"a\",1)) => \"a\""
  input tuple<Type_a, Type_b> inTplTypeATypeB;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  outTypeA:=match (inTplTypeATypeB)
    local Type_a a;
    case ((a,_)) then a;
  end match;
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
  match (inTplTypeATypeB)
    local Type_b b;
    case ((_,b)) then b;
  end match;
end tuple22;

public function optTuple22 "function: optTuple22
  Takes an option tuple of two values and returns the second value.
  Example: optTuple22(SOME(\"a\",1)) => 1"
  input Option<tuple<Type_a, Type_b>> inTplTypeATypeB;
  output Type_b outTypeB;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  SOME((_,outTypeB)) := inTplTypeATypeB;
end optTuple22;

public function tuple312 "
  Takes a tuple of three values and returns the tuple of the two first values.
  Example: tuple312((\"a\",1,2)) => (\"a\",1)"
  input tuple<Type_a, Type_b,Type_c> tpl;
  output tuple<Type_a, Type_b> outTypeA;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  outTypeA:=
  match (tpl)
    local
      Type_a a;
      Type_b b;
    case ((a,b,_)) then ((a,b));
  end match;
end tuple312;

public function tuple31 "
  Takes a tuple of three values and returns the first value.
  Example: tuple31((\"a\",1,2)) => \"a\""
  input tuple<Type_a, Type_b,Type_c> tpl;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  outTypeA:=
  match (tpl)
    local Type_a a;
    case ((a,_,_)) then a;
  end match;
end tuple31;

public function tuple32 "
  Takes a tuple of three values and returns the second value.
  Example: tuple32((\"a\",1,2)) => 1 "
  input tuple<Type_a, Type_b,Type_c> tpl;
  output Type_b outTypeB;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  outTypeB:=
  match (tpl)
    local Type_b b;
    case ((_,b,_)) then b;
  end match;
end tuple32;

public function tuple33 "
  Takes a tuple of three values and returns the third value.
  Example: tuple33((\"a\",1,2)) => 2 "
  input tuple<Type_a, Type_b,Type_c> tpl;
  output Type_c outTypeC;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  outTypeC:=
  match (tpl)
    local Type_c c;
    case ((_,_,c)) then c;
  end match;
end tuple33;

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
  match (inTplTypeATypeBLst)
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
  end match;
end splitTuple2List;

public function filterList "
Author BZ
Taking a list of a generic type and a integer list which are the positions
we are supposed to remove. The final position is the offset, where to start from(normal = 0 )."
  input list<Type_a> lst;
  input list<Integer> positions;
  input Integer pos;
  output list<Type_a> outList;
  replaceable type Type_a subtypeof Any;
algorithm 
  outList := matchcontinue(lst,positions,pos)
    local
      list<Type_a> tail,res;
      Type_a head;
      Integer x;
      list<Integer> xs;
    case({},_,_) then {};
    case(lst,{},_) then lst;
    case(head::tail,x::xs,pos)
      equation
        true = intEq(x, pos); // equality(x=pos);
        res = filterList(tail,xs,pos+1);
      then
        res;
    case(head::tail,x::xs,pos)
      equation
        res = filterList(tail,x::xs,pos+1);
      then
        head::res;
end matchcontinue;
end filterList;

public function if_ "function: if_
  Takes a boolean and two values.
  Returns the first value (second argument) if the boolean value is
  true, otherwise the second value (third argument) is returned.
  Example: if_(true,\"a\",\"b\") => \"a\""
  input Boolean cond;
  input Type_a valTrue;
  input Type_a valFalse;
  output Type_a outVal;
  replaceable type Type_a subtypeof Any;
  // annotation(__OpenModelica_EarlyInline = true);
algorithm
  outVal := match (cond,valTrue,valFalse)
    case (true,_,_) then valTrue;
    else valFalse;
  end match;
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

public function stringDelimitListPrintBuf "
Author: BZ, 2009-11
Same funcitonality as stringDelimitListPrint, but writes to print buffer instead of string variable.
Usefull for heavy string operations(causes malloc error on some models when generating init file).
"
  input list<String> inStringLst;
  input String inString;
algorithm
  _:=
  matchcontinue (inStringLst,inString)
    local
      String f,delim,str1,str2,str;
      list<String> r;
    case ({},_) then ();
    case ({f},delim) equation Print.printBuf(f); then ();
    case ((f :: r),delim)
      equation
        stringDelimitListPrintBuf(r, delim);
        Print.printBuf(f);
        Print.printBuf(delim);

      then
        ();
  end matchcontinue;
end stringDelimitListPrintBuf;

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
protected String tmpBuf;
algorithm
  tmpBuf := Print.getString();
  Print.clearBuf();
  stringDelimitListAndSeparate2(str, sep1, sep2, n, 0);
  res := Print.getString();
  Print.clearBuf();
  Print.printBuf(tmpBuf);
end stringDelimitListAndSeparate;

protected function stringDelimitListAndSeparate2 "function: stringDelimitListAndSeparate2
  author: PA
  Helper function to stringDelimitListAndSeparate"
  input list<String> inStringLst1;
  input String inString2;
  input String inString3;
  input Integer inInteger4;
  input Integer inInteger5;
algorithm
  _ := matchcontinue (inStringLst1,inString2,inString3,inInteger4,inInteger5)
    local
      String s,str1,str,f,sep1,sep2;
      list<String> r;
      Integer n,iter_1,iter;
    case ({},_,_,_,_) then ();  /* iterator */
    case ({s},_,_,_,_) equation
      Print.printBuf(s);
    then ();
    case ((f :: r),sep1,sep2,n,0)
      equation
        Print.printBuf(f);Print.printBuf(sep1);
        stringDelimitListAndSeparate2(r, sep1, sep2, n, 1) "special case for first element" ;
      then
        ();
    case ((f :: r),sep1,sep2,n,iter)
      equation
        0 = intMod(iter, n) "insert second delimiter" ;
        iter_1 = iter + 1;
        Print.printBuf(f);Print.printBuf(sep1);Print.printBuf(sep2);
        stringDelimitListAndSeparate2(r, sep1, sep2, n, iter_1);
      then
        ();
    case ((f :: r),sep1,sep2,n,iter)
      equation
        iter_1 = iter + 1 "not inserting second delimiter" ;
        Print.printBuf(f);Print.printBuf(sep1);
        stringDelimitListAndSeparate2(r, sep1, sep2, n, iter_1);
      then
        ();
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
protected
  list<String> lst1;
algorithm
  lst1 := listSelect(lst, isNotEmptyString);
  str := stringDelimitList(lst1, delim);
end stringDelimitListNonEmptyElts;

public function stringReplaceChar "function stringReplaceChar
  Takes a string and two chars and replaces the first char with the second char:
  Example: string_replace_char(\"hej.b.c\",\".\",\"_\") => \"hej_b_c\"
  2007-11-26 BZ: Now it is possible to replace chars with emptychar, and
                 replace a char with a string
  Example: string_replace_char(\"hej.b.c\",\".\",\"_dot_\") => \"hej_dot_b_dot_c\"
  "
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
        strList = stringListStringChar(str);
        resList = stringReplaceChar2(strList, fromChar, toChar);
        res = stringCharListString(resList);
      then
        res;
    case (_,_,_)
      equation
        print("- Util.stringReplaceChar failed\n");
      then
        fail();
  end matchcontinue;
end stringReplaceChar;

protected function stringReplaceChar2
  input list<String> inStringLst1;
  input String inString2;
  input String inString3;
  output list<String> outStringLst;
algorithm
  outStringLst := matchcontinue (inStringLst1,inString2,inString3)
    local
      list<String> res,rest,strList, charList2;
      String firstChar,fromChar,toChar;
    
    case ({},_,_) then {};
    case ((firstChar :: rest),fromChar,"") // added special case for removal of char.
      equation
        true = stringEq(firstChar, fromChar);
        res = stringReplaceChar2(rest, fromChar, "");
      then
        (res);
    
    case ((firstChar :: rest),fromChar,toChar)
      equation
        true = stringEq(firstChar, fromChar);
        res = stringReplaceChar2(rest, fromChar, toChar);
        charList2 = stringListStringChar(toChar);
        res = listAppend(charList2,res);
      then
        res;

    case ((firstChar :: rest),fromChar,toChar)
      equation
        false = stringEq(firstChar, fromChar);
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
  outStringLst := matchcontinue (inString1,inString2)
    local
      list<String> chrList;
      list<String> stringList;
      String str,strList;
      String chr;
    case (str,chr)
      equation
        chrList = stringListStringChar(str);
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
  outStringLst := matchcontinue (inStringLst1,inString2,inStringLst3)
    local
      list<String> chr_rest_1,chr_rest,chrList,rest,res;
      String firstChar,chr,str;
    
    case ({},_,chr_rest)
      equation
        chr_rest_1 = listReverse(chr_rest);
        str = stringCharListString(chr_rest_1);
      then
        {str};
    
    case ((firstChar :: rest),chr,chr_rest)
      equation
        true = stringEq(firstChar, chr);
        chrList = listReverse(chr_rest) "this is needed because it returns the reversed list" ;
        str = stringCharListString(chrList);
        res = stringSplitAtChar2(rest, chr, {});
      then
        (str :: res);
    case ((firstChar :: rest),chr,chr_rest)
      equation
        false = stringEq(firstChar, chr);
        res = stringSplitAtChar2(rest, chr, (firstChar :: chr_rest));
      then
        res;
    case (_,_,_)
      equation
        print("- Util.stringSplitAtChar2 failed\n");
      then
        fail();
  end matchcontinue;
end stringSplitAtChar2;

public function modelicaStringToCStr "function modelicaStringToCStr
 this replaces symbols that are illegal in C to legal symbols
 see replaceStringPatterns to see the format. (example: \".\" becomes \"$P\")
  author: x02lucpo
  
  NOTE: This function should not be used in OMC, since the OMC backend no longer
    uses stringified components. It is still used by MathCore though."
  input String str;
  input Boolean changeDerCall "if true, first change 'DER(v)' to $derivativev";
  output String res_str;
algorithm

  res_str := matchcontinue(str,changeDerCall)
    case(str,false) // BoschRexroth specifics
      equation
        false = OptManager.getOption("translateDAEString");
        then
          str;
    case(str,false)
      equation
        res_str = "$"+& modelicaStringToCStr1(str, replaceStringPatterns);
        // debug_print("prefix$", res_str);
      then res_str;
    case(str,true) equation
      str = modelicaStringToCStr2(str);
    then str;
  end matchcontinue;
end modelicaStringToCStr;

protected function modelicaStringToCStr2 "help function to modelicaStringToCStr,
first  changes name 'der(v)' to $derivativev and 'pre(v)' to 'pre(v)' with applied rules for v"
  input String derName;
  output String outDerName;
algorithm
  outDerName := matchcontinue(derName)
  local
    String name;
    list<String> names;
    case(derName) equation
      0 = System.strncmp(derName,"der(",4);
      // adrpo: 2009-09-08
      // the commented text: _::name::_ = listLast(System.strtok(derName,"()"));
      // is wrong as der(der(x)) ends up beeing translated to $der$der instead
      // of $der$der$x. Changed to the following 2 lines below!
      _::names = (System.strtok(derName,"()"));
      names = listMap1(names, modelicaStringToCStr, false);
      name = derivativeNamePrefix +& stringAppendList(names);
    then name;
    case(derName) equation
      0 = System.strncmp(derName,"pre(",4);
      _::name::_= System.strtok(derName,"()");
      name = "pre(" +& modelicaStringToCStr(name,false) +& ")";
    then name;
    case(derName) then modelicaStringToCStr(derName,false);
  end matchcontinue;
end modelicaStringToCStr2;

protected function modelicaStringToCStr1 ""
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
    case (str,_)
      equation
        print("- Util.modelicaStringToCStr1 failed for str:"+&str+&"\n");
      then
        fail();
  end matchcontinue;
end modelicaStringToCStr1;

public function cStrToModelicaString "function cStrToModelicaString
 this replaces symbols that have been replace to correct value for modelica string
 see replaceStringPatterns to see the format. (example: \"$p\" becomes \".\")
  author: x02lucpo

  NOTE: This function should not be used in OMC, since the OMC backend no longer
    uses stringified components. It is still used by MathCore though."
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
  outString := match (inString,inReplacePatternLst)
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
  end match;
end cStrToModelicaString1;

public function boolOrList "function boolOrList
  Takes a list of boolean values and applies the boolean OR operator  to the list elements
  Example:
    boolOrList({true,false,false})  => true
    boolOrList({false,false,false}) => false"
  input list<Boolean> inBooleanLst;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inBooleanLst)
    local
      Boolean b;
      list<Boolean> rest;
    case({}) then false;
    case ({b}) then b;
    case ((true :: rest))  then true;
    case ((false :: rest)) then boolOrList(rest);
  end match;
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
  outBoolean := match (inBooleanLst)
    local
      Boolean b;
      list<Boolean> rest;
    case({}) then true;
    case ({b}) then b;
    case ((false :: rest)) then false;
    case ((true :: rest))  then boolAndList(rest);
  end match;
end boolAndList;

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

public function listFilter1
"Author BZ
  Same as listFilter, but with an extra argument
"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  input Type_b extraArg;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
    input Type_b inTypeB;
  end FuncTypeType_aTo;
algorithm outTypeALst:= listFilter1_tail(inTypeALst, inFuncTypeTypeATo, {},extraArg);
end listFilter1;

public function listAddElementFirst "
Author: BZ, 2008-07 Adds an element first to a list.
"
input Type_a inElem;
input list<Type_a> inList;
output list<Type_a> outList;
replaceable type Type_a subtypeof Any;
algorithm outList := inElem::inList;
end listAddElementFirst;

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
    
    // reverse at the end!
    case ({},_,accTypeALst) 
      then 
        listReverse(accTypeALst);
    
    // add to front if the condition works
    case ((v :: vl), cond, accTypeALst)
      equation
        cond(v);
        vl_1 = listFilter_tail(vl, cond, v::accTypeALst);
      then
        (vl_1);
    
    // filter out and move along
    case ((v :: vl),cond, accTypeALst)
      equation
        failure(cond(v));
        vl_1 = listFilter_tail(vl, cond, accTypeALst);
      then
        vl_1;
  end matchcontinue;
end listFilter_tail;

public function listFilter1_tail
"function: listFilter_tail
 @author bz
 tail recursive implementation of listFilter"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  input list<Type_a> accTypeALst;
  input Type_b extraArg;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
    input Type_b inTypeB;
  end FuncTypeType_aTo;
algorithm outTypeALst := matchcontinue (inTypeALst,inFuncTypeTypeATo,accTypeALst,extraArg)
    local
      list<Type_a> vl_1,vl;
      Type_a v;
      FuncTypeType_aTo cond;
    
    // reverse at the end
    case ({},_,accTypeALst,extraArg) then listReverse(accTypeALst);
    
    // accumulate in front
    case ((v :: vl), cond, accTypeALst, extraArg)
      equation
        cond(v,extraArg);
        vl_1 = listFilter1_tail(vl, cond, v::accTypeALst, extraArg);
      then
        (vl_1);
    
    // jump over
    case ((v :: vl),cond, accTypeALst, extraArg)
      equation
        failure(cond(v,extraArg));
        vl_1 = listFilter1_tail(vl, cond, accTypeALst, extraArg);
      then
        vl_1;
  end matchcontinue;
end listFilter1_tail;

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
  outTypeALst := matchcontinue (inTypeALst,inFuncTypeTypeAToBoolean,accTypeALst)
    local
      list<Type_a> vl_1,vl;
      Type_a v;
      FuncTypeType_aToBoolean cond;
    
    // reverse at the end
    case ({}, _, accTypeALst) then listReverse(accTypeALst);
    
    // accumulate in front
    case ((v :: vl), cond, accTypeALst)
      equation
        true = cond(v);
        vl_1 = listFilterBoolean_tail(vl, cond, v::accTypeALst);
      then
        (vl_1);
    
    // jump over
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
    applyOption(NONE(),    intString) => NONE"
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
  match (inTypeAOption,inFuncTypeTypeAToTypeB)
    local
      Type_b b;
      Type_a a;
      FuncTypeType_aToType_b rel;
    case (NONE(),_) then NONE();
    case (SOME(a),rel)
      equation
        b = rel(a);
      then
        SOME(b);
  end match;
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
  match (inStringOption)
    local String s;
    case (NONE()) then "";
    case (SOME(s)) then s;
  end match;
end stringOption;

public function getOption "
  author: PA
  Returns an option value if SOME, otherwise fails"
  input Option<Type_a> inOption;
  output Type_a unOption;
  replaceable type Type_a subtypeof Any;
algorithm
  SOME(unOption) := inOption;
end getOption;

public function getOptionOrDefault
"Returns an option value if SOME, otherwise the default"
  input Option<Type_a> inOption;
  input Type_a default;
  output Type_a unOption;
  replaceable type Type_a subtypeof Any;
algorithm
  unOption := matchcontinue (inOption,default)
    local Type_a item;
    case (SOME(item),_) then item;
    case (_,default) then default;
  end matchcontinue;
end getOptionOrDefault;

public function genericOption "function: genericOption
  author: BZ
  Returns a list with single value or an empty list if there is no optional value."
  input Option<Type_a> inOption;
  output list<Type_a> unOption;
  replaceable type Type_a subtypeof Any;
algorithm unOption := match (inOption)
    local Type_a item;
    case (NONE()) then {};
    case (SOME(item)) then {item};
  end match;
end genericOption;

public function isNone
"
  function: isNone
  Author: DH, 2010-03
"
  input Option<Type_a> inOption;
  output Boolean out;
  replaceable type Type_a subtypeof Any;
algorithm
  out := match (inOption)
    case (NONE()) then true;
    else false;
  end match;
end isNone;

public function isSome
"
  function: isSome
  Author: DH, 2010-03
"
  input Option<Type_a> inOption;
  output Boolean out;
  replaceable type Type_a subtypeof Any;
algorithm
  out := match (inOption)
    case NONE() then false;
    else true;
  end match;
end isSome;

public function makeOptIfNonEmptyList "function: stringOption
  author: BZ
  Construct a Option<Type_a> if the list contains one and only one element. If more, error. On empty=>NONE()"
  input list<Type_a> unOption;
  output Option<Type_a> inOption;
  replaceable type Type_a subtypeof Any;
algorithm inOption := matchcontinue (unOption)
    local Type_a item;
    case ({}) then NONE();
    case ({item}) then SOME(item);
  end matchcontinue;
end makeOptIfNonEmptyList;

public function listSplitOnTrue
  "Splits a list into two sublists depending on predicate function."
  input list<Type_a> inList;
  input PredicateFunc inFunc;
  output list<Type_a> outTrueList;
  output list<Type_a> outFalseList;

  replaceable type Type_a subtypeof Any;

  partial function PredicateFunc
    input Type_a inElement;
    output Boolean outResult;
  end PredicateFunc;
algorithm
  (outTrueList, outFalseList) := 
    listSplitOnTrue_tail(inList, inFunc, {}, {});
end listSplitOnTrue;
  
public function listSplitOnTrue_tail
  "Helper function to listSplitOnTrue."
  input list<Type_a> inList;
  input PredicateFunc inFunc;
  input list<Type_a> inTrueList;
  input list<Type_a> inFalseList;
  output list<Type_a> outTrueList;
  output list<Type_a> outFalseList;

  replaceable type Type_a subtypeof Any;

  partial function PredicateFunc
    input Type_a inElement;
    output Boolean outResult;
  end PredicateFunc;
algorithm
  (outTrueList, outFalseList) := 
  match(inList, inFunc, inTrueList, inFalseList)
    local
      Type_a e;
      list<Type_a> rest_e, tl, fl;
      Boolean pred;

    case ({}, _, tl, fl) 
      then (listReverse(tl), listReverse(fl));

    case (e :: rest_e, _, tl, fl)
      equation
        pred = inFunc(e);
        (tl, fl) = listSplitOnTrue_tail2(e, rest_e, pred, inFunc, tl, fl);
      then
        (tl, fl);
  end match;
end listSplitOnTrue_tail;

public function listSplitOnTrue_tail2
  "Helper function to listSplitOnTrue."
  input Type_a inHead;
  input list<Type_a> inRest;
  input Boolean inPred;
  input PredicateFunc inFunc;
  input list<Type_a> inTrueList;
  input list<Type_a> inFalseList;
  output list<Type_a> outTrueList;
  output list<Type_a> outFalseList;

  replaceable type Type_a subtypeof Any;

  partial function PredicateFunc
    input Type_a inElement;
    output Boolean outResult;
  end PredicateFunc;
algorithm
  (outTrueList, outFalseList) := 
  match(inHead, inRest, inPred, inFunc, inTrueList, inFalseList)
    local
      Boolean pred;
      Type_a e;
      list<Type_a> rl, tl, fl;

    case (_, _, true, _, tl, fl)
      equation
        tl = inHead :: tl;
        (tl, fl) = listSplitOnTrue_tail(inRest, inFunc, tl, fl);
      then
        (tl, fl);

    case (_, _, false, _, tl, fl)
      equation
        fl = inHead :: fl;
        (tl, fl) = listSplitOnTrue_tail(inRest, inFunc, tl, fl);
      then
        (tl, fl);
  end match;
end listSplitOnTrue_tail2;

public function listSplitOnTrue1 "Splits a list into two sublists depending on predicate function
which takes one extra argument "
  input list<Type_a> lst;
  input predicateFunc f;
  input Type_b b;
  output list<Type_a> tlst;
  output list<Type_a> flst;

  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function predicateFunc
    input Type_a inTypeA1;
    input Type_b inTypeb;
    output Boolean outBoolean;
  end predicateFunc;
algorithm
  (tlst,flst) := matchcontinue(lst,f,b)
  local Type_a l;
    case({},f,b) then ({},{});

    case(l::lst,f,b) equation
      true = f(l,b);
      (tlst,flst) = listSplitOnTrue1(lst,f,b);
    then (l::tlst,flst);

    case(l::lst,f,b) equation
      false = f(l,b);
      (tlst,flst) = listSplitOnTrue1(lst,f,b);
    then (tlst,l::flst);
  end matchcontinue;
end listSplitOnTrue1;

public function listSplitOnTrue2 "Splits a list into two sublists depending on predicate function
which takes two extra arguments "
  input list<Type_a> lst;
  input predicateFunc f;
  input Type_b b;
  input Type_c c;
  output list<Type_a> tlst;
  output list<Type_a> flst;

  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  partial function predicateFunc
    input Type_a inTypeA1;
    input Type_b inTypeb;
    input Type_c inTypec;
    output Boolean outBoolean;
  end predicateFunc;
algorithm
  (tlst,flst) := matchcontinue(lst,f,b,c)
  local Type_a l;
    case({},f,b,c) then ({},{});

    case(l::lst,f,b,c) equation
      true = f(l,b,c);
      (tlst,flst) = listSplitOnTrue2(lst,f,b,c);
    then (l::tlst,flst);

    case(l::lst,f,b,c) equation
      false = f(l,b,c);
      (tlst,flst) = listSplitOnTrue2(lst,f,b,c);
    then (tlst,l::flst);
  end matchcontinue;
end listSplitOnTrue2;

public function listSplitOnBoolList
"Splits a list into two sublists depending on second list of bools"
  input list<Type_a> lst;
  input list<Boolean> blst;
  output list<Type_a> tlst;
  output list<Type_a> flst;
  replaceable type Type_a subtypeof Any;
algorithm
  (tlst,flst) := match(lst,blst)
  local Type_a l;
    case({},{}) then ({},{});
    case(l::lst,true::blst) equation
      (tlst,flst) = listSplitOnBoolList(lst,blst);
    then (l::tlst,flst);
    case(l::lst,false::blst) equation
      (tlst,flst) = listSplitOnBoolList(lst,blst);
    then (tlst,l::flst);
  end match;
end listSplitOnBoolList;

public function listSplitOnFirstMatch
  "This function splits a list when the given function first finds a matching
  element. Ex:
    listSplitOnFirstMatch({1,2,3,4,5}, isThree) => ({1,2}, {3,4,5})"
  input list<Type_a> inList;
  input FuncType inFunc;
  output list<Type_a> outList1;
  output list<Type_a> outList2;

  replaceable type Type_a subtypeof Any;
  partial function FuncType
    input Type_a inElement;
  end FuncType;
algorithm
  (outList1, outList2) := matchcontinue(inList, inFunc)
    local
      Type_a e;
      list<Type_a> el, l1, l2;
    case ({}, _) then ({}, {});
    case (e :: el, _)
      equation
        inFunc(e);
      then
        ({}, e :: el);
    case (e :: el, _)
      equation
        (l1, l2) = listSplitOnFirstMatch(el, inFunc);
      then
        (e :: l1, l2);
  end matchcontinue;
end listSplitOnFirstMatch;

public function listSplitEqualParts "function: listSplitEqualParts
  Takes a list of values and an position value.
  The function returns the list splitted into two lists at the position given as argument.
  Example: listSplit({1,2,5,7},2) => ({1,2},{5,7})"
  input list<Type_a> inTypeALst;
  input Integer inInteger;
  output list<list<Type_a>> outTypeALst1;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst1 :=
  matchcontinue (inTypeALst,inInteger)
    local
      list<Type_a> a,b,c;
      Integer length,index,divider,splitLength;
    case (a,0) then {};
    case(a,divider)
      equation
        0 = intMod(listLength(a),divider);
        splitLength = intDiv(listLength(a),divider);
        outTypeALst1 = listSplitEqualParts2(a,splitLength);
        then
          outTypeALst1;
    case(a,divider)
      equation
        true = (intMod(listLength(a),divider) > 0);
        print(" split list into non integersize not possible(call to listSplitEqualParts)\n");
      then
        fail();
  end matchcontinue;
end listSplitEqualParts;

protected function listSplitEqualParts2 "function: listSplitEqualParts
  Takes a list of values and an position value.
  The function returns the list splitted into two lists at the position given as argument.
  Example: listSplit({1,2,5,7},2) => ({1,2},{5,7})"
  input list<Type_a> inTypeALst;
  input Integer inInteger;
  output list<list<Type_a>> outTypeALst1;
  replaceable type Type_a subtypeof Any;
algorithm
  (outTypeALst1):=
  matchcontinue (inTypeALst,inInteger)
    local
      list<Type_a> a,b,c;
      Integer index,divider,splitLength;
      list<list<Type_a>> rec;
    case ({},_) then {};
    case(a,divider)
      equation
        (c,b) = listSplit2(a, {}, divider);
        rec = listSplitEqualParts2(c,divider);
        rec = b::rec;
        then
          rec;
  end matchcontinue;
end listSplitEqualParts2;

public function listPartition "partitions a list of elements into subslists of length n
For example
listPartition({1,2,3,4},2) => {{1,2},{3,4}}
listPartition({1,2,3,4,5},2) => {{1,2},{3,4},{5}}
"
  input list<Type_a> lst;
  replaceable type Type_a subtypeof Any;
  input Integer n;
  output list<list<Type_a>> res;
algorithm
  res := matchcontinue(lst,n)
    local list<Type_a> lst1;
    case({},n) then {};
    case(lst,n)
      equation
        true = n > listLength(lst);
      then {lst};
    case(lst,n)
      equation
        (lst1,lst) = listSplit(lst,n);
        res = listPartition(lst,n);
      then lst1::res;
  end matchcontinue;
end listPartition;

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
      list<Type_a> la,lb,c,d;
      Type_a a;
      Integer index,new_index;
    case (la,lb,index)
      equation
        (index == 0) = true;
        lb = listReverse(lb);
      then
        (la,lb);
    case ((a :: la),lb,index)
      equation
        new_index = index - 1;
        c = a::lb;
        (c,d) = listSplit2(la, c, new_index);
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

public function intNegative "function: intNegative
  Returns true if integer value is negative (< 0)"
  input Integer v;
  output Boolean res;
algorithm
  res := (v < 0);
end intNegative;

public function optionToList "function: optionToList
  Returns an empty list for NONE() and a list containing
  the element for SOME(element). To use with listAppend"
  input Option<Type_a> inTypeAOption;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:=
  matchcontinue (inTypeAOption)
    local Type_a e;
    case NONE() then {};
    case SOME(e) then {e};
  end matchcontinue;
end optionToList;

public function flattenOption "function: flattenOption
  Returns the second argument if NONE() or the element in SOME(element)"
  input Option<Type_a> inTypeAOption;
  input Type_a inTypeA;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeA := matchcontinue (inTypeAOption,inTypeA)
    local Type_a n,c;
    case (NONE(),n) then n;
    case (SOME(c),n) then c;
  end matchcontinue;
end flattenOption;

public function isEmptyArray " isArrayEmpty"
  input list<Type_a> lst;
  replaceable type Type_a subtypeof Any;
  output Boolean b;
algorithm
  b := matchcontinue(lst)
    case({}) then true;
    case(_::_) then false;
  end matchcontinue;
end isEmptyArray;

public function isEmptyString "function: isEmptyString
  Returns true if string is the empty string."
  input String inString;
  output Boolean outBoolean;
algorithm
  outBoolean := stringEq(inString, "");
end isEmptyString;

public function isNotEmptyString "function: isNotEmptyString
  Returns true if string is not the empty string."
  input String inString;
  output Boolean outBoolean;
algorithm
  outBoolean := boolNot(stringEq(inString, ""));
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
    case ((a :: _),(b :: _),1) then stringEq(a, b);
    case ((a :: l1),(b :: l2),n)
      equation
        n1 = n - 1;
        true = stringEq(a, b);
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
        clst1 = stringListStringChar(s1);
        clst2 = stringListStringChar(s2);
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
      String file,pd,path,res,file_1,file_path,dir_path,current_dir,name;
      list<String> list_path_1,list_path;
    case (file_1)
      equation
        file = replaceSlashWithPathDelimiter(file_1);
        pd = System.pathDelimiter();
        /* (pd_chr :: {}) = stringListStringChar(pd); */
        (path :: {}) = stringSplitAtChar(file, pd) "same dir only filename as param" ;
        res = System.pwd();
      then
        (res,path);
    case (file_1)
      equation
        file = replaceSlashWithPathDelimiter(file_1);
        pd = System.pathDelimiter();
        /* (pd_chr :: {}) = stringListStringChar(pd); */
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
  match (inString)
    local
      String retString,rawString;
    case (rawString)
      equation
         retString = System.stringReplace(rawString, "\\\"", "\"") "change backslash-double-quote to double-quote ";
         retString = System.stringReplace(retString, "\\\\", "\\") "double-backslash with backslash ";
      then
        (retString);
  end match;
end  rawStringToInputString;

public function listProduct
"@author adrpo
 given 2 lists, generate a product out of them.
 Example:
  lst1 = {{1}, {2}}, lst2 = {{1}, {2}, {3}}
  result = { {1, 1}, {1, 2}, {1, 3}, {2, 1}, {2, 2}, {2, 3} }"
  input  list<list<Type_a>> inTypeALstLst1;
  input  list<list<Type_a>> inTypeALstLst2;
  output list<list<Type_a>> outTypeALstLst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALstLst := matchcontinue (inTypeALstLst1, inTypeALstLst2)
    local
      list<list<Type_a>> out;
    case (inTypeALstLst1, inTypeALstLst2)
      equation
        out = listProduct_acc(inTypeALstLst1, inTypeALstLst2, {});
      then
        out;
  end matchcontinue;
end listProduct;

public function listProduct_acc
"@author adrpo
 given 2 lists, generate a product out of them in the empty accumulator given as input.
 Example1:
  lst1 = {{1}, {2}}, lst2 = {{1}, {2}, {3}}
  result = { {1, 1}, {1, 2}, {1, 3}, {2, 1}, {2, 2}, {2, 3} }
 Example2:
  lst1 = {{1}, {2}}, lst2 = {}
  result = { {1}, {2}, {3} }"
  input  list<list<Type_a>> inTypeALst1;
  input  list<list<Type_a>> inTypeALst2;
  input  list<list<Type_a>> inTypeALstLst;
  output list<list<Type_a>> outTypeALstLst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALstLst :=
  matchcontinue (inTypeALst1, inTypeALst2, inTypeALstLst)
    local
      list<list<Type_a>> out, out1, out2, tail1, tail2;
      list<Type_a> hd1, hd2, res;
    case (hd1::{}, {}, inTypeALstLst)
      equation
        out = listMap(hd1, listCreate);
      then
        out;

    case ({}, _, inTypeALstLst)
      equation
         //debug_print("1 - inTypeALstLst", inTypeALstLst);
      then
        inTypeALstLst;

    case (hd1::tail1, inTypeALst2, inTypeALstLst)
      equation
        //debug_print("2 - hd1", hd1);
        //debug_print("2 - tail1", tail1);
        //debug_print("2 - inTypeALst2", inTypeALst2);
        //debug_print("2 - inTypeALstLst", inTypeALstLst);
        // append each element from inTypeALst2 to hd1 => { {hd1, el21}, {hd1, el22} ... }
        out1  = listMap1(inTypeALst2, listAppend, hd1);
        // do the same for the rest of the elements in the list
        out2  = listProduct_acc(tail1, inTypeALst2, out1);
        out   = listAppend(out1, out2);
        out   = listAppend(inTypeALstLst, out);
      then
        out;
  end matchcontinue;
end listProduct_acc;

public function escapeModelicaStringToCString
  input String modelicaString;
  output String cString;
algorithm
  // C cannot handle newline in string constants
  cString := System.stringReplace(System.escapedString(modelicaString), "\n", "\\n");
end escapeModelicaStringToCString;

public function escapeModelicaStringToXmlString
  input String modelicaString;
  output String xmlString;
algorithm
  // C cannot handle newline in string constants
  xmlString := System.stringReplace(modelicaString, "&", "&amp;");
  xmlString := System.stringReplace(xmlString, "\\\"", "&quot;");
  xmlString := System.stringReplace(xmlString, "<", "&lt;");
  xmlString := System.stringReplace(xmlString, ">", "&gt;");
end escapeModelicaStringToXmlString;

public function listlistTranspose "{{1,2,3}{4,5,6}} => {{1,4},{2,5},{3,6}}"
  input list<list<Type_a>> inLst;
  output list<list<Type_a>> outLst;
  replaceable type Type_a subtypeof Any;
algorithm
  outLst := matchcontinue (inLst)
    local
      list<Type_a> first;
      list<list<Type_a>> rest;
      list<list<Type_a>> res;
      list<Boolean> boolLst;
    case {} then {{}};
    case (inLst)
      equation
        first = listMap(inLst, listFirst);
        rest = listMap(inLst, listRest);
        res = listlistTranspose(rest);
      then first :: res;
    case (inLst)
      equation
        boolLst = listMap(inLst, isListNotEmpty);
        false = listReduce(boolLst, boolOr);
      then {};
  end matchcontinue;
end listlistTranspose;

public function makeTuple2
  input Type_a a;
  input Type_b b;
  output tuple<Type_a,Type_b> out;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  out := (a,b);
end makeTuple2;

public function makeTupleList
  input list<Type_a> al;
  input list<Type_b> bl;
  output list<tuple<Type_a,Type_b>> out;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  out := matchcontinue(al,bl)
    local
      Type_a a;
      Type_b b;
    case({},_) then {};
    case(a::al,b::bl)
      equation
      out = makeTupleList(al,bl);
    then
      (a,b)::out;
  end matchcontinue;
end makeTupleList;

public function listAppendNoCopy
"author: adrpo
 this function handles special cases
 such as empty lists so it does no
 copy if any of the arguments are
 empty lists"
  input  list<Type_a> inLst1;
  input  list<Type_a> inLst2;
  output list<Type_a> outLst;
  replaceable type Type_a subtypeof Any;
algorithm
  outLst := matchcontinue(inLst1, inLst2)
    case ({},{}) then {};
    case (inLst1, {}) then inLst1;
    case ({}, inLst2) then inLst2;
    case (inLst1, inLst2) then listAppend(inLst1,inLst2);
  end matchcontinue;
end listAppendNoCopy;

public function mulListIntegerOpt
  input list<Option<Integer>> ad;
  input Integer acc "accumulator, should be given 1";
  output Integer i;
algorithm
  i := matchcontinue(ad, acc)
    local
      Integer ii, iii;
      list<Option<Integer>> rest;
    case ({}, acc) then acc;
    case (SOME(ii)::rest, acc)
      equation
        acc = ii * acc;
        iii = mulListIntegerOpt(rest, acc);
      then iii;
    case (NONE()::rest, acc)
      equation
        iii = mulListIntegerOpt(rest, acc);
      then iii;
  end matchcontinue;
end mulListIntegerOpt;

public type StatefulBoolean = array<Boolean> "A single boolean value that can be updated (a destructive operation)";

public function makeStatefulBoolean
"Create a boolean with state (that is, it is mutable)"
  input Boolean b;
  output StatefulBoolean sb;
algorithm
  sb := arrayCreate(1, b);
end makeStatefulBoolean;

public function getStatefulBoolean
"Create a boolean with state (that is, it is mutable)"
  input StatefulBoolean sb;
  output Boolean b;
algorithm
  b := sb[1];
end getStatefulBoolean;

public function setStatefulBoolean
"Update the state of a mutable boolean"
  input StatefulBoolean sb;
  input Boolean b;
algorithm
  _ := arrayUpdate(sb,1,b);
end setStatefulBoolean;

public function optionEqual "
Takes two options and a function to compare the type."
  input Option<Type_a> inOpt1;
  input Option<Type_a> inOpt2;
  input CompareFunc inFunc;
  output Boolean outBool;
  
  replaceable type Type_a subtypeof Any;
  partial function CompareFunc
    input Type_a inType_a1;
    input Type_a inType_a2;
    output Boolean outBool;
  end CompareFunc;
algorithm
  outBool := matchcontinue(inOpt1,inOpt2,inFunc)
  local 
    Type_a a1,a2;
    Boolean b;
    CompareFunc fn;
    
    case (NONE(),NONE(),_) then true;
    case (SOME(a1),SOME(a2),fn)
      equation
        b = fn(a1,a2);
      then
        b;
    case (_,_,_) then false;
  end matchcontinue;
end optionEqual;
  
public function makeValueOrDefault
"Returns the value if the function call succeeds, otherwise the default"
  input FuncAToB inFunc;
  input Type_a inArg;
  input Type_b default;
  output Type_b res;

  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncAToB
    input Type_a inTypeA;
    output Type_b outTypeB;
  end FuncAToB;
algorithm
  res := matchcontinue (inFunc,inArg,default)
    local
      FuncAToB fn;
    case (fn,inArg,_)
      equation
        res = fn(inArg);
      then res;
    case (_,_,default) then default;
  end matchcontinue;
end makeValueOrDefault;

public function xmlEscape "Escapes a String so that it can be used in xml"
  input String s1;
  output String s2;
algorithm
  s2 := stringReplaceChar(s1,"<","&lt;");
  s2 := stringReplaceChar(s2,">","&gt;");
end xmlEscape;

public function listSub
  "Returns a sub list determined by an offset and length.
     Example: listSub({1,2,3,4,5}, 2, 3) => {2,3,4}"
  input list<Type_a> inList;
  input Integer inOffset;
  input Integer inLength;
  output list<Type_a> outList;
  replaceable type Type_a subtypeof Any;
algorithm
  outList := listSub_tail(inList, inOffset, inLength, {});
end listSub;

public function listSub_tail
  "Tail recursive implementation of listSub."
  input list<Type_a> inList;
  input Integer inOffset;
  input Integer inLength;
  input list<Type_a> accumList;
  output list<Type_a> outList;
  replaceable type Type_a subtypeof Any;
algorithm
  outList := matchcontinue(inList, inOffset, inLength, accumList)
    local
      Type_a e;
      list<Type_a> rest_e;
    case ({}, _, _, _) then listReverse(accumList);
    case (_, _, 0, _) then listReverse(accumList);
    case (e :: rest_e, _, _, _)
      equation
        (inOffset > 1) = true;
        rest_e = listSub_tail(rest_e, inOffset - 1, inLength, accumList);
      then
        rest_e;
    case (e :: rest_e, _, _, _)
      equation
        (inLength > 0) = true;
        rest_e = listSub_tail(rest_e, 1, inLength - 1, accumList);
      then
        e :: rest_e;
  end matchcontinue;
end listSub_tail;

public function strcmpBool "As strcmp, but has Boolean output as is expected by the sort function"
  input String s1;
  input String s2;
  output Boolean b;
algorithm
  b := if_(stringCompare(s1,s2) > 0, true, false);
end strcmpBool;

public function stringAppendReverse
"@author: adrpo
 This function will append the first string to the second string"
  input String str1;
  input String str2;
  output String str;
algorithm
  str := stringAppend(str2, str1);
end stringAppendReverse;

// moved from Inst.
public function selectList
"function: select
Author BZ, 2008-09
  This utility function selects one of two objects depending on a list of boolean variables.
  Used to constant evaluate if-equations."
  input list<Boolean> inBools;
  input list<Type_a> inList;
  input Type_a inFalse;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeA:=
  match (inBools,inList,inFalse)
    local
      Type_a x,head;
      case({},{},x) then x;
    case (true::_,head::_,_) then head;
    case (false::inBools,_::inList,x)
      equation
        head = selectList(inBools,inList,x);
      then head;
  end match;
end selectList;

public function listMapOption
"More efficient than: listMap(listMap(lst, getOption), fn)
Also, does not fail if an element is NONE()
"
  input list<Option<Type_a>> lst;
  input FuncTypeType_aToType_b fn;
  output list<Type_b> outTypeBLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
    replaceable type Type_b subtypeof Any;
  end FuncTypeType_aToType_b;
  replaceable type Type_b subtypeof Any;
algorithm
  outTypeBLst := listMapOption_tail(lst, {}, fn);
end listMapOption;

protected function listMapOption_tail
  input list<Option<Type_a>> lst;
  input list<Type_b> acc;
  input FuncTypeType_aToType_b fn;
  output list<Type_b> outTypeBLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
    replaceable type Type_b subtypeof Any;
  end FuncTypeType_aToType_b;
  replaceable type Type_b subtypeof Any;
algorithm
  outTypeBLst := matchcontinue (lst, acc, fn)
    local
      Type_a x;
      Type_b b;
      list<Option<Type_a>> xs;
    case ({}, acc, fn) then listReverse(acc);
    case (SOME(x)::xs, acc, fn)
      equation
        b = fn(x);
      then listMapOption_tail(xs, b::acc, fn);
    case (NONE()::xs, acc, fn) then listMapOption_tail(xs, acc, fn);
  end matchcontinue;
end listMapOption_tail;

public function listMapOption1
"More efficient than: listMap1(listMap(lst, getOption), fn, arg)
Also, does not fail if an element is NONE()
"
  input list<Option<Type_a>> lst;
  input Func fn;
  input Type_b b;
  output list<Type_c> cl;
  partial function Func
    input Type_a a;
    input Type_b b;
    output Type_c c;
  end Func;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  cl := listMapOption1_tail(lst, {}, fn, b);
end listMapOption1;

protected function listMapOption1_tail
  input list<Option<Type_a>> lst;
  input list<Type_c> acc;
  input Func fn;
  input Type_b b;
  output list<Type_c> cl;
  partial function Func
    input Type_a a;
    input Type_b b;
    output Type_c c;
  end Func;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  cl := match (lst, acc, fn, b)
    local
      Type_a a;
      Type_c c;
    case ({}, acc, fn, b) then listReverse(acc);
    case (SOME(a)::lst, acc, fn, b)
      equation
        c = fn(a,b);
      then listMapOption1_tail(lst, c::acc, fn, b);
    case (NONE()::lst, acc, fn, b) then listMapOption1_tail(lst, acc, fn, b);
  end match;
end listMapOption1_tail;

public function listMapMap
"More efficient than: listMap(listMap(lst, fn1), fn2)
"
  input list<Type_a> lst;
  input F_a_b fn1;
  input F_b_c fn2;
  output list<Type_c> outLst;
  partial function F_a_b
    input Type_a inTypeA;
    output Type_b outTypeB;
  end F_a_b;
  partial function F_b_c
    input Type_b inTypeB;
    output Type_c outTypeC;
  end F_b_c;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  outLst := listMapMap_tail(lst, {}, fn1, fn2);
end listMapMap;

protected function listMapMap_tail
"More efficient than: listMap(listMap(lst, fn1), fn2)
"
  input list<Type_a> lst;
  input list<Type_c> acc;
  input F_a_b fn1;
  input F_b_c fn2;
  output list<Type_c> outLst;
  partial function F_a_b
    input Type_a inTypeA;
    output Type_b outTypeB;
  end F_a_b;
  partial function F_b_c
    input Type_b inTypeA;
    output Type_c outTypeC;
  end F_b_c;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  outLst := match (lst, acc, fn1, fn2)
    local
      Type_a a;
      Type_b b;
      Type_c c;
      list<Type_a> xs;
    case ({}, acc, fn1, fn2) then listReverse(acc);
    case (a::xs, acc, fn1, fn2)
      equation
        b = fn1(a);
        c = fn2(b);
      then listMapMap_tail(xs, c::acc, fn1, fn2);
  end match;
end listMapMap_tail;

public function getCurrentDateTime
  output DateTime dt;
  Integer sec;
  Integer min;
  Integer hour;
  Integer mday;
  Integer mon;
  Integer year;
algorithm
  (sec,min,hour,mday,mon,year) := System.getCurrentDateTime();
  dt := DATETIME(sec,min,hour,mday,mon,year);
end getCurrentDateTime;

public function isSuccess
  input Status status;
  output Boolean bool;
algorithm
  bool := match status
    case SUCCESS() then true;
    case FAILURE() then false;
  end match;
end isSuccess;

public function id
  input A a;
  output A oa;
  replaceable type A subtypeof Any;
algorithm
  oa := a;
end id;

public function absIntegerList
"@author: adrpo
  Applies absolute value to all entries in the given list."
  input list<Integer> inLst;
  output list<Integer> outLst;
algorithm
  outLst := listMap(inLst, intAbs);
end absIntegerList;

/*
public function arrayMap "function: arrayMap
  Takes a list and a function over the elements of the array, which is applied
  for each element, producing a new array.
  Example: arrayMap({1,2,3}, intString) => { \"1\", \"2\", \"3\"}"
  input array<Type_a> inTypeAArr;
  input FuncTypeType_aToType_b inFuncTypeTypeAToTypeB;
  output array<Type_b> outTypeBArr;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
    replaceable type Type_b subtypeof Any;
  end FuncTypeType_aToType_b;
  replaceable type Type_b subtypeof Any;
protected
  array<Type_b> outTypeBArr;
  Type_b elB;
  Type_a elA;
  Integer sizeOfArr;
algorithm  
  // get the size
  sizeOfArr := arrayLength(inTypeAArr);
  // get the first elment of the input array
  elA := arrayGet(inTypeAArr, 1);
  // apply the function and transform it to Type_b
  elB := inFuncTypeTypeAToTypeB(elA);
  // create an array populated with the first element trasformed 
  outTypeBArr := arrayCreate(sizeOfArr, elA);
  // set all the other elements on the array!
  outTypeBArr := arrayMapDispatch(inTypeAArr,inFuncTypeTypeAToTypeB,1,sizeOfArr,outTypeBArr);
end arrayMap;

protected function arrayMapDispatch
"@author: adrpo
  Calculates the incidence matrix as an array of list of integers"
  input array<Type_a> inTypeAArr;
  input FuncTypeType_aToType_b inFuncTypeTypeAToTypeB;
  input Integer index;
  input Integer sizeOfArr;
  input array<Type_b> accTypeBArr;
  output array<Type_b> outTypeBArr;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
    replaceable type Type_b subtypeof Any;
  end FuncTypeType_aToType_b;
  replaceable type Type_b subtypeof Any;
algorithm
  outIncidenceArray := matchcontinue (inTypeAArr, inFuncTypeAToTypeB, index, sizeOfArr, accTypeBArr)
    local
      array<Type_a> aArr;
      array<Type_b> bArr;
      Integer i,n;
      Type_a elA;
      Type_b elB;
    
    // i = n (we reach the end)
    case (aArr, inFuncTypeAToTypeB, i, n, bArr)
      equation
        false = intLt(i, n);
      then 
        bArr;
    
    // i < n 
    case (aArr, inFuncTypeAToTypeB, i, n, bArr)
      equation
        true = intLt(i, n);
        // get the element from the input array
        elA = arrayGet(aArr, i + 1);
        // transform the element
        elB = inFuncTypeAToTypeB(elA);
        // put it in the array
        iArr = arrayUpdate(bArr, i+1, elB);
        iArr = arrayMapDispatch(iArr, inFuncTypeAToTypeB, i + 1, n, bArr);
      then
        iArr;
    
    // failure!
    case (aArr, inFuncTypeAToTypeB, i, n, bArr)
      equation
        print("- Util.arrayMapDispatch failed\n");
      then
        fail();
  end matchcontinue;
end arrayMapDispatch;
*/

public function listConsOption
  input Option<A> oa;
  input list<A> lst;
  output list<A> olst;
  replaceable type A subtypeof Any;
algorithm
  olst := match (oa,lst)
    local
      A a;
    case (SOME(a),lst) then a::lst;
    else lst;
  end match;
end listConsOption;

public function listMapAllValue
"@author adrpo
 applies a function to all elements in the lists and checks if all are the same
 as a given value"
  replaceable type TypeA subtypeof Any;
  replaceable type TypeB subtypeof Any;
  input  list<TypeA> inLst;
  input  FuncTypeTypeVarToTypeVar fn;
  input  TypeB value;
  output Boolean b;
  partial function FuncTypeTypeVarToTypeVar
    input TypeA inTypeA;
    output TypeB outTypeB;
    replaceable type TypeA subtypeof Any;
    replaceable type TypeB subtypeof Any;
  end FuncTypeTypeVarToTypeVar;
algorithm
  b := matchcontinue (inLst, fn, value)
    case (inLst, fn, value)
      equation
        listMapAllValue2(inLst, fn, value);
      then true;
    else false;
  end matchcontinue;
end listMapAllValue;

protected function listMapAllValue2
"@author adrpo
 applies a function to all elements in the lists and checks if all are the same
 as a given value"
  replaceable type TypeA subtypeof Any;
  replaceable type TypeB subtypeof Any;
  input  list<TypeA> inLst;
  input  FuncTypeTypeVarToTypeVar fn;
  input  TypeB value;
  partial function FuncTypeTypeVarToTypeVar
    input TypeA inTypeA;
    output TypeB outTypeB;
    replaceable type TypeA subtypeof Any;
    replaceable type TypeB subtypeof Any;
  end FuncTypeTypeVarToTypeVar;
algorithm
  _ := match(inLst, fn, value)
    local
      TypeA hd;
      TypeB hdChanged;
      list<TypeA> rest;
    
    case ({}, _, _) then ();
    
    case (hd::rest, fn, value)
      equation
        hdChanged = fn(hd);
        equality(hdChanged = value);
        listMapAllValue2(rest, fn, value);
      then ();
  end match;
end listMapAllValue2;

public function listMap2AllValue
"@author adrpo
 checks that the mapped function returns the same given value, otherwise fails"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bType_cToType_d fn;
  input Type_b inTypeB;
  input Type_c inTypeC;
  input Type_d inTypeD;
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
  _ := match(inTypeALst, fn, inTypeB, inTypeC, inTypeD)
    local
      Type_a hd;
      Type_d hdChanged;
      list<Type_a> rest;
      Type_b extraarg1;
      Type_c extraarg2;
    
    case ({}, _, _, _, _) then ();
    
    case (hd::rest, fn, extraarg1, extraarg2, inTypeD)
      equation
        hdChanged = fn(hd, extraarg1, extraarg2);
        equality(inTypeD = hdChanged);
        listMap2AllValue(rest, fn, extraarg1, extraarg2, inTypeD);
    then
        ();
  end match;
end listMap2AllValue;

public function listMap1AllValue
"function listMap1AllValue
 maps a function to elements and checks if the result is always the given value!"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bToType_c inFuncTypeTypeATypeBToTypeC;
  input Type_b inTypeB;
  input Type_c value;
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
  _ := match (inTypeALst,inFuncTypeTypeATypeBToTypeC,inTypeB,value)
    local
      Type_c f_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aType_bToType_c fn;
      Type_b extraarg;
    
    case ({},_,_,_) then ();
    
    case ((f :: r),fn,extraarg,value)
      equation
        f_1 = fn(f, extraarg);
        equality(f_1 = value);
        listMap1AllValue(r, fn, extraarg, value);
      then
        ();
  end match;
end listMap1AllValue;

public function listThreadMapAllValue "function: listThreadMapAllValue
  Takes two lists and a function and threads (interleaves) and maps the elements of the two lists
  and checks if the result is the same value.
  Example: listThreadMapAllValue({true,true},{false,true},boolAnd,true) => fail"
  input list<Type_a> inTypeALst;
  input list<Type_b> inTypeBLst;
  input FuncTypeType_aType_bToType_c inFuncTypeTypeATypeBToTypeC;
  input Type_c value;
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
  _ := match (inTypeALst,inTypeBLst,inFuncTypeTypeATypeBToTypeC,value)
    local
      Type_c fr;
      Type_a fa;
      list<Type_a> ra;
      Type_b fb;
      list<Type_b> rb;
      FuncTypeType_aType_bToType_c fn;
    
    case ({},{},_,value) then ();
    
    case ((fa :: ra),(fb :: rb),fn,value)
      equation
        fr = fn(fa, fb);
        equality(fr = value);
        listThreadMapAllValue(ra, rb, fn, value);
      then
        ();
  end match;
end listThreadMapAllValue;

public function buildMapStr "function: buildMapStr
  Takes two lists of the same type and builds a string like x = val1, y = val2, ....
  Example: listThread({1,2,3},{4,5,6},'=',',') => 1=4, 2=5, 3=6"
  input list<String> inLst1;
  input list<String> inLst2;
  input String inMiddleDelimiter;
  input String inEndDelimiter;
  output String outStr;
algorithm
  outStr := matchcontinue (inLst1,inLst2, inMiddleDelimiter, inEndDelimiter)
    local
      list<String> ra,rb;
      String fa,fb, md, ed, str;
    
    case ({},{}, md, ed) then "";
    
    case ({fa},{fb}, md, ed)
      equation
        str = stringAppendList({fa, md, fb});
      then
        str;
    
    case (fa :: ra,fb :: rb, md, ed)
      equation
        str = buildMapStr(ra, rb, md, ed);
        str = stringAppendList({fa, md, fb, ed, str});
      then
        str;
  end matchcontinue;
end buildMapStr;

public function splitUniqueOnBool
"Takes a sorted list and returns two sorted lists:
  * The first is the input with all duplicate elements removed
  * The second is the removed elements
"
  input list<TypeA> sorted;
  input Comp comp;
  output list<TypeA> uniqueLst;
  output list<TypeA> duplicateLst;
  replaceable type TypeA subtypeof Any;
  partial function Comp
    input TypeA a1;
    input TypeA a2;
    output Boolean b;
  end Comp;
algorithm
  (uniqueLst,duplicateLst) := splitUniqueOnBoolWork(sorted,comp,{},{});
end splitUniqueOnBool;


protected function splitUniqueOnBoolWork
"Takes a sorted list and returns two sorted lists:
  * The first is the input with all duplicate elements removed
  * The second is the removed elements
"
  input list<TypeA> sorted;
  input Comp comp;
  input list<TypeA> uniqueAcc;
  input list<TypeA> duplicateAcc;
  output list<TypeA> uniqueLst;
  output list<TypeA> duplicateLst;
  replaceable type TypeA subtypeof Any;
  partial function Comp
    input TypeA a1;
    input TypeA a2;
    output Boolean b;
  end Comp;
algorithm
  (uniqueLst,duplicateLst) := match (sorted,comp,uniqueAcc,duplicateAcc)
    local
      TypeA a1,a2;
      list<TypeA> rest;
      Boolean b;
    case ({},comp,uniqueAcc,duplicateAcc)
      equation
        uniqueAcc = listReverse(uniqueAcc);
        duplicateAcc = listReverse(duplicateAcc);
      then (uniqueAcc,duplicateAcc);
    case ({a1},comp,uniqueAcc,duplicateAcc)
      equation
        uniqueAcc = listReverse(a1::uniqueAcc);
        duplicateAcc = listReverse(duplicateAcc);
      then (uniqueAcc,duplicateAcc);
    case (a1::a2::rest,comp,uniqueAcc,duplicateAcc)
      equation
        b = comp(a1,a2);
        (uniqueAcc,duplicateAcc) = splitUniqueOnBoolWork(a2::rest,comp,if_(b,uniqueAcc,a1::uniqueAcc),if_(b,a1::duplicateAcc,duplicateAcc));
      then (uniqueAcc,duplicateAcc);
  end match;
end splitUniqueOnBoolWork;

public function assoc
"assoc(key,lst) => value, where lst is a tuple of (key,value) pairs.
Does linear search using equality(). This means it is slow for large
inputs (many elements or large elements); if you have large inputs, you
should use a hash-table instead."
  input Key key;
  input list<tuple<Key,Val>> lst;
  output Val val;
  replaceable type Key subtypeof Any;
  replaceable type Val subtypeof Any;
algorithm
  val := match (key,lst)
    local
      Key k1,k2;
      Val v;
    case (k1,(k2,v)::lst) then Debug.bcallret2(not valueEq(k1,k2), assoc, k1, lst, v);
  end match;
end assoc;

public function transposeList
  "Transposes a 2-dimensional rectangular list"
  input list<list<A>> lst;
  output list<list<A>> olst;
  replaceable type A subtypeof Any;
algorithm
  olst := transposeList2(lst,{});
end transposeList;

protected function transposeList2
  "Transposes a 2-dimensional rectangular list"
  input list<list<A>> lst;
  input list<list<A>> acc;
  output list<list<A>> olst;
  replaceable type A subtypeof Any;
algorithm
  olst := match (lst,acc)
    local
      list<A> a;
    case ({},_) then listReverse(acc);
    case ({}::_,_) then listReverse(acc);
    case (lst,acc)
      equation
        a = listMap(lst,listFirst);
        lst = listMap(lst,listRest);
      then transposeList2(lst,a::acc);
  end match;
end transposeList2;

public function allCombinations
  "{{1,2,3},{4,5},{6}} => {{1,4,6},{1,5,6},{2,4,6},...}.
  The output is a 2-dim list with lengths (len1*len2*...*lenN)) and N.
  
  This function screams WARNING I USE COMBINATORIAL EXPLOSION.
  So there are flags that limit the size of the set it works on."
  input list<list<Type_a>> lst;
  input Option<Integer> maxTotalSize;
  input Absyn.Info info;
  output list<list<Type_a>> out;
  replaceable type Type_a subtypeof Any;
algorithm
  out := matchcontinue (lst,maxTotalSize,info)
    local
      Integer sz,maxSz;
    case (lst,SOME(maxSz),info)
      equation
        sz = intMul(listLength(lst),listFold(listMap(lst,listLength),intMul,1));
        true = (sz <= maxSz);
      then allCombinations2(lst);

    case (lst,NONE(),info) then allCombinations2(lst);

    case (_,SOME(_),_)
      equation
        Error.addSourceMessage(Error.COMPILER_NOTIFICATION, {"Util.allCombinations failed because the input was too large"}, info);
      then fail();
  end matchcontinue;
end allCombinations;

protected function allCombinations2
  "{{1,2,3},{4,5},{6}} => {{1,4,6},{1,5,6},{2,4,6},...}.
  The output is a 2-dim list with lengths (len1*len2*...*lenN)) and N.
  
  This function screams WARNING I USE COMBINATORIAL EXPLOSION."
  input list<list<Type_a>> lst;
  output list<list<Type_a>> out;
  replaceable type Type_a subtypeof Any;
algorithm
  out := match (lst)
    local
      list<Type_a> x;
    case {} then {};
    case (x::lst)
      equation
        lst = allCombinations2(lst);
        lst = allCombinations3(x, lst, {});
      then lst;
  end match;
end allCombinations2;

protected function allCombinations3
  input list<Type_a> lst1;
  input list<list<Type_a>> lst2;
  input list<list<Type_a>> acc;
  output list<list<Type_a>> out;
  replaceable type Type_a subtypeof Any;
algorithm
  out := match (lst1,lst2,acc)
    local
      Type_a x;
      list<list<Type_a>> acc2;
    case ({},_,acc) then listReverse(acc);
    case (x::lst1,lst2,acc)
      equation
        acc = allCombinations4(x, lst2, acc);
        acc = allCombinations3(lst1, lst2, acc);
      then acc;
  end match;
end allCombinations3;

protected function allCombinations4
  input Type_a x;
  input list<list<Type_a>> lst;
  input list<list<Type_a>> acc;
  output list<list<Type_a>> out;
  replaceable type Type_a subtypeof Any;
algorithm
  out := match (x,lst,acc)
    local
      list<Type_a> l;
    
    case (x,{},acc) then {x}::acc;
    case (x,{l},acc) then (x::l)::acc;
    case (x,l::lst,acc)
      equation
        acc = allCombinations4(x, lst, (x::l)::acc);
      then acc;
  end match;
end allCombinations4;

public function arrayMember
"returns the index if found or 0 if not found.
 considers array indexed from 1"
  input array<Option<Type_a>> inArr;
  input Integer inFilledSize "the filled size of the array, it might be less than arrayLength";
  input Option<Type_a> inElement;
  output Integer index;
protected
  replaceable type Type_a subtypeof Any;
algorithm
  index := matchcontinue(inArr, inFilledSize, inElement)
    local
      array<Option<Type_a>> arr;
      Integer i, len, pos;
    
    // array is empty
    case (arr, inFilledSize, inElement)
      equation
        true = intEq(0, inFilledSize);
      then
        0;
    
    // array is not empty
    case (arr, inFilledSize, inElement)
      equation
        i = arrayMemberLoop(arr, inElement, 1, inFilledSize);
      then
        i;
  end matchcontinue;
end arrayMember;

protected function arrayMemberLoop
"returns the index if found or 0 if not found.
 considers array indexed from 1"
  input array<Option<Type_a>> inArr;
  input Option<Type_a> inElement;
  input Integer currentIndex;
  input Integer length;
  output Integer index;
protected
  replaceable type Type_a subtypeof Any;
algorithm
  index := matchcontinue(inArr, inElement, currentIndex, length)
    local
      array<Option<Type_a>> arr;
      Integer i, len, pos;
      Option<Type_a> e;
    
    // we're at the end
    case (arr, inElement, i, len)
      equation
        true = intEq(i, len);
      then
        0;
    
    // not at the end, see if we find it
    case (arr, inElement, i, len)
      equation
        e = arrayGet(arr, i);
        true = valueEq(e, inElement);
      then
        i;
        
    // not at the end, see if we find it
    case (arr, inElement, i, len)
      equation
        e = arrayGet(arr, i);
        false = valueEq(e, inElement);
        i = arrayMemberLoop(arr, inElement, i + 1, len);
      then
        i;
  end matchcontinue;
end arrayMemberLoop;

public function arrayFind
"returns the index if found or 0 if not found.
 considers array indexed from 1"
  input array<Option<Type_a>> inArr;
  input Integer inFilledSize "the filled size of the array, it might be less than arrayLength";
  input FuncType inFunc;
  input Type_b inExtra;  
  output Integer index;
protected
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncType
    input Type_a inElement;
    input Type_b inExtra;
    output Boolean isMatch;
  end FuncType;  
algorithm
  index := matchcontinue(inArr, inFilledSize, inFunc, inExtra)
    local
      array<Option<Type_a>> arr;
      Integer i, len, pos;
    
    // array is empty
    case (arr, inFilledSize, inFunc, inExtra)
      equation
        true = intEq(0, inFilledSize);
      then
        0;
    
    // array is not empty
    case (arr, inFilledSize, inFunc, inExtra)
      equation
        i = arrayFindLoop(arr, inFunc, inExtra, 1, inFilledSize);
      then
        i;
  end matchcontinue;
end arrayFind;

protected function arrayFindLoop
"returns the index if found or 0 if not found.
 considers array indexed from 1"
  input array<Option<Type_a>> inArr;
  input FuncType inFunc;
  input Type_b inExtra;
  input Integer currentIndex;
  input Integer length;
  output Integer index;
protected
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncType
    input Type_a inElement;
    input Type_b inExtra;
    output Boolean isMatch;
  end FuncType;
algorithm
  index := matchcontinue(inArr, inFunc, inExtra, currentIndex, length)
    local
      array<Option<Type_a>> arr;
      Integer i, len, pos;
      Type_a e;
    
    // we're at the end
    case (arr, _, _, i, len)
      equation
        true = intEq(i, len);
      then
        0;
    
    // not at the end, see if we find it
    case (arr, inFunc, inExtra, i, len)
      equation
        SOME(e) = arrayGet(arr, i);
        true = inFunc(e, inExtra);
      then
        i;
        
    // not at the end, see if we find it
    case (arr, inFunc, inExtra, i, len)
      equation
        SOME(e) = arrayGet(arr, i);
        false = inFunc(e, inExtra);
        i = arrayFindLoop(arr, inFunc, inExtra, i + 1, len);
      then
        i;
    
    // not at the end, see if we find it
    case (arr, inFunc, inExtra, i, len)
      equation
        NONE() = arrayGet(arr, i);
        i = arrayFindLoop(arr, inFunc, inExtra, i + 1, len);
      then
        i;
  end matchcontinue;
end arrayFindLoop;

public function arrayApply
"apply a function to each element of the array"
  input array<Option<Type_a>> inArr;
  input Integer inFilledSize "the filled size of the array, it might be less than arrayLength";
  input FuncType inFunc;
  input Type_b inExtra;
  output array<Option<Type_a>> outArr;
protected
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncType
    input Option<Type_a> inElement;
    input Type_b inExtra;
  end FuncType;  
algorithm
  outArr := matchcontinue(inArr, inFilledSize, inFunc, inExtra)
    local
      array<Option<Type_a>> arr;
      Integer i, len, pos;
    
    // array is empty
    case (arr, inFilledSize, inFunc, inExtra)
      equation
        true = intEq(0, inFilledSize);
      then
        arr;
    
    // array is not empty
    case (arr, inFilledSize, inFunc, inExtra)
      equation
        arr = arrayApplyLoop(arr, inFunc, inExtra, 1, inFilledSize);
      then
        arr;
  end matchcontinue;
end arrayApply;

protected function arrayApplyLoop
"returns the index if found or 0 if not found.
 considers array indexed from 1"
  input array<Option<Type_a>> inArr;
  input FuncType inFunc;
  input Type_b inExtra;
  input Integer currentIndex;
  input Integer length;
  output array<Option<Type_a>> outArr;
protected
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncType
    input Option<Type_a> inElement;
    input Type_b inExtra;
  end FuncType;
algorithm
  outArr := matchcontinue(inArr, inFunc, inExtra, currentIndex, length)
    local
      array<Option<Type_a>> arr;
      Integer i, len, pos;
      Option<Type_a> e;
    
    // we're at the end
    case (arr, _, _, i, len)
      equation
        true = intEq(i, len);
      then
        arr;
    
    // not at the end, see if we find it
    case (arr, inFunc, inExtra, i, len)
      equation
        e = arrayGet(arr, i);
        inFunc(e, inExtra);
        arr = arrayApplyLoop(arr, inFunc, inExtra, i + 1, len);
      then
        arr;
  end matchcontinue;
end arrayApplyLoop;

public function arrayApplyR
"apply a function to each element of the array;
 the extra is the first argument in the apply function"
  input array<Option<Type_a>> inArr;
  input Integer inFilledSize "the filled size of the array, it might be less than arrayLength";
  input FuncType inFunc;
  input Type_b inExtra;
  output array<Option<Type_a>> outArr;
protected
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncType
    input Type_b inExtra;
    input Option<Type_a> inElement;
  end FuncType;  
algorithm
  outArr := matchcontinue(inArr, inFilledSize, inFunc, inExtra)
    local
      array<Option<Type_a>> arr;
      Integer i, len, pos;
    
    // array is empty
    case (arr, inFilledSize, inFunc, inExtra)
      equation
        true = intEq(0, inFilledSize);
      then
        arr;
    
    // array is not empty
    case (arr, inFilledSize, inFunc, inExtra)
      equation
        arr = arrayApplyRLoop(arr, inFunc, inExtra, 1, inFilledSize);
      then
        arr;
  end matchcontinue;
end arrayApplyR;

protected function arrayApplyRLoop
"returns the index if found or 0 if not found.
 considers array indexed from 1"
  input array<Option<Type_a>> inArr;
  input FuncType inFunc;
  input Type_b inExtra;
  input Integer currentIndex;
  input Integer length;
  output array<Option<Type_a>> outArr;
protected
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncType
    input Type_b inExtra;
    input Option<Type_a> inElement;
  end FuncType;
algorithm
  outArr := matchcontinue(inArr, inFunc, inExtra, currentIndex, length)
    local
      array<Option<Type_a>> arr;
      Integer i, len, pos;
      Option<Type_a> e;
    
    // we're at the end
    case (arr, _, _, i, len)
      equation
        true = intEq(i, len);
      then
        arr;
    
    // not at the end, see if we find it
    case (arr, inFunc, inExtra, i, len)
      equation
        e = arrayGet(arr, i);
        inFunc(inExtra, e);
        arr = arrayApplyRLoop(arr, inFunc, inExtra, i + 1, len);
      then
        arr;
  end matchcontinue;
end arrayApplyRLoop;

public function arrayMemberEqualityFunc
"returns the index if found or 0 if not found.
 considers array indexed from 1.
 it gets an equality check function!"
  input array<Option<Type_a>> inArr;
  input Integer inFilledSize "the filled size of the array, it might be less than arrayLength";
  input Option<Type_a> inElement;
  input FuncTypeEquality inEqualityCheckFunction;
  output Integer index;
protected
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeEquality
    input Option<Type_a> inElOld;
    input Option<Type_a> inElNew;
    output Boolean isEqual;
  end FuncTypeEquality;  
algorithm
  index := matchcontinue(inArr, inFilledSize, inElement, inEqualityCheckFunction)
    local
      array<Option<Type_a>> arr;
      Integer i, len, pos;
    
    // array is empty
    case (arr, inFilledSize, inElement, _)
      equation
        true = intEq(0, inFilledSize);
      then
        0;
    
    // array is not empty
    case (arr, inFilledSize, inElement, inEqualityCheckFunction)
      equation
        i = arrayMemberEqualityFuncLoop(arr, inElement, inEqualityCheckFunction, 1, inFilledSize);
      then
        i;
  end matchcontinue;
end arrayMemberEqualityFunc;

protected function arrayMemberEqualityFuncLoop
"returns the index if found or 0 if not found.
 considers array indexed from 1"
  input array<Option<Type_a>> inArr;
  input Option<Type_a> inElement;
  input FuncTypeEquality inEqualityCheckFunction;
  input Integer currentIndex;
  input Integer length;
  output Integer index;
protected
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeEquality
    input Option<Type_a> inElOld;
    input Option<Type_a> inElNew;
    output Boolean isEqual;
  end FuncTypeEquality;  
algorithm
  index := matchcontinue(inArr, inElement, inEqualityCheckFunction, currentIndex, length)
    local
      array<Option<Type_a>> arr;
      Integer i, len, pos;
      Option<Type_a> e;
    
    // we're at the end
    case (arr, inElement, _, i, len)
      equation
        true = intEq(i, len);
      then
        0;
    
    // not at the end, see if we find it
    case (arr, inElement, inEqualityCheckFunction, i, len)
      equation
        e = arrayGet(arr, i);
        true = inEqualityCheckFunction(e, inElement);
      then
        i;
        
    // not at the end, see if we find it
    case (arr, inElement, inEqualityCheckFunction, i, len)
      equation
        e = arrayGet(arr, i);
        false = inEqualityCheckFunction(e, inElement);
        i = arrayMemberEqualityFuncLoop(arr, inElement, inEqualityCheckFunction, i + 1, len);
      then
        i;
  end matchcontinue;
end arrayMemberEqualityFuncLoop;

end Util;
