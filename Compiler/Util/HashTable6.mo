encapsulated package HashTable6 "
  This file is an extension to OpenModelica.

  Copyright (c) 2007 MathCore Engineering AB

  All rights reserved.

  RCS: $Id$

  "
  
/* Below is the instance specific code. For each hashtable the user must define:

Key       - The key used to uniquely define elements in a hashtable
Value     - The data to associate with each key
hashFunc   - A function that maps a key to a positive integer.
keyEqual   - A comparison function between two keys, returns true if equal.
*/

/* HashTable instance specific code */

public import BaseHashTable;
public import DAE;
protected import ComponentReference;
protected import ExpressionDump;
protected import System;

public type Key = tuple<DAE.ComponentRef,DAE.ComponentRef>;
public type Value = DAE.Exp;

public type HashTableCrefFunctionsType = tuple<FuncHashCref,FuncCrefEqual,FuncCrefStr,FuncExpStr>;
public type HashTable = tuple<
  array<list<tuple<Key,Integer>>>,
  tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>,
  Integer,
  Integer,
  HashTableCrefFunctionsType
>;

partial function FuncHashCref
  input Key cr;
  output Integer res;
end FuncHashCref;

partial function FuncCrefEqual
  input Key cr1;
  input Key cr2;
  output Boolean res;
end FuncCrefEqual;

partial function FuncCrefStr
  input Key cr;
  output String res;
end FuncCrefStr;

partial function FuncExpStr
  input Value exp;
  output String res;
end FuncExpStr;

protected function hashFunc
"Calculates a hash value for Key"
  input Key cr;
  output Integer res;
  String crstr;
algorithm
  crstr := printKey(cr);
  res := stringHashDjb2(crstr);
end hashFunc;

protected function keyEqual
  input Key tpl1;
  input Key tpl2;
  output Boolean res;
algorithm
  res := matchcontinue (tpl1,tpl2)
    local
      DAE.ComponentRef cr11,cr12,cr21,cr22;
    case ((cr11,cr12),(cr21,cr22))
      then ComponentReference.crefEqual(cr11,cr21) and ComponentReference.crefEqual(cr12,cr22);
  end matchcontinue;
end keyEqual;

protected function printKey
  input Key tpl;
  output String res;
algorithm
  res := ComponentReference.printComponentRefStr(Util.tuple21(tpl))+&","+&ComponentReference.printComponentRefStr(Util.tuple22(tpl));
end printKey;

public function emptyHashTable
"
  Returns an empty HashTable.
  Using the bucketsize 1000 and array size 100.
"
  output HashTable hashTable;
algorithm
  hashTable := emptyHashTableSized(BaseHashTable.defaultBucketSize);
end emptyHashTable;

public function emptyHashTableSized
"
  Returns an empty HashTable.
  Using the bucketsize size and arraysize size/10.
"
  input Integer size;
  output HashTable hashTable;
algorithm
  hashTable := BaseHashTable.emptyHashTableWork(size,intDiv(size,10),(hashFunc,keyEqual,printKey,ExpressionDump.printExpStr));
end emptyHashTableSized;

end HashTable6;
