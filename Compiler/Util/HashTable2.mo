encapsulated package HashTable2 "
  This file is an extension to OpenModelica.

  Copyright (c) 2007 MathCore Engineering AB

  All rights reserved.

  file:        HashTable2.mo
  package:     HashTable2
  description: DAE.CR to DAE.Exp

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

public type Key = DAE.ComponentRef;
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
  input Integer mod;
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

public function hashFunc
"Calculates a hash value for Key"
  input Key cr;
  input Integer mod;
  output Integer res;
protected
  String crstr;
algorithm
  crstr := ComponentReference.printComponentRefStr(cr);
  res := System.stringHashDjb2Mod(crstr,mod);
end hashFunc;

public function emptyHashTable
"
  Returns an empty HashTable.
  Using the default bucketsize..
"
  output HashTable hashTable;
algorithm
  hashTable := emptyHashTableSized(BaseHashTable.defaultBucketSize);
end emptyHashTable;

public function emptyHashTableSized
"Returns an empty HashTable.
 Using the bucketsize size."
  input Integer size;
  output HashTable hashTable;
algorithm
  hashTable := BaseHashTable.emptyHashTableWork(size,(hashFunc,ComponentReference.crefEqual,ComponentReference.printComponentRefStr,ExpressionDump.printExpStr));
end emptyHashTableSized;

end HashTable2;
