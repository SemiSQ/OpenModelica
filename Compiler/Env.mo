package Env "
This file is part of OpenModelica.

Copyright (c) 1998-2006, Link�pings universitet, Department of
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

 Neither the name of Link�pings universitet nor the names of its
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

  
  file:	 Env.mo
  module:      Env
  description: Environmane management
 
  RCS: $Id$
 
  An environment is a stack of frames, where each frame contains a
  number of class and variable bindings.
  Each frame consist of:
  - a frame name (corresponding to the class partially instantiated in that frame)
  - a binary tree containing a list of classes
  - a binary tree containing a list of functions (functions are overloaded so serveral
						     function names can exist)
  - a list of unnamed items consisting of import statements
 
  As an example lets consider the following Modelica code:
  package A
    package B
     import Modelica.SIunits.;
     constant Voltage V=3.3;
     function foo
     end foo;
     model M1
       Real x,y;  
     end M1;
     model M2
     end M2;
   end B;
  end A;
  
  When instantiating M1 we will first create the environment for its surrounding scope
  by a recursive instantiation on A.B giving the environment:
   { 
   FRAME(\"A\", {Class:B},{},{},false) ,  
   FRAME(\"B\", {Class:M1, Class:M2, Variable:V}, {Type:foo},
	   {import Modelica.SIunits.},false)
   }
 
  Then, the class M1 is instantiated in a new scope/Frame giving the environment:
   { 
   FRAME(\"A\", {Class:B},{},{},false) ,  
   FRAME(\"B\", {Class:M1, Class:M2, Variable:V}, {Type:foo}, 
	   {Import Modelica.SIunits.},false),
   FRAME(\"M1, {Variable:x, Variable:y},{},{},false)
   }

  NOTE: The instance hierachy (components and variables) and the class hierachy 
  (packages and classes) are combined into the same data structure, enabling a 
  uniform lookup mechanism
"

public import Absyn;
public import SCode;
public import Types;
public import ClassInf;
public import Exp;

public 
type Ident = String " An identifier is just a string " ;

public uniontype Cache
  record CACHE 
    Option<EnvCache> envCache "The cache consists of environments from which classes can be found";
    Option<Env> initialEnv "and the initial environment";
  end CACHE;
end Cache;

public uniontype EnvCache 
 record ENVCACHE "Cache for environments. The cache consists of a tree of environments from which lookup
 		can be performed."
   		CacheTree envTree;
  end ENVCACHE;
end EnvCache;

public uniontype CacheTree
  record CACHETREE
		Ident	name;
		Env env;
		list<CacheTree> children;
  end CACHETREE;
end CacheTree;

public 
uniontype Frame
  record FRAME
    Option<Ident> class_1 "Class name" ;
    BinTree list_2 "List of uniquely named classes and variables" ;
    BinTree list_3 "List of types, which DOES NOT be uniquely named, eg. size have several types" ;
    list<Item> list_4 "list of unnamed items (imports)" ;
    list<Frame> list_5 "list of frames for inherited elements" ;
    tuple<list<Exp.ComponentRef>,Exp.ComponentRef> current6 "current connection set crefs" ;
    Boolean encapsulated_7 "encapsulated bool=true means that FRAME is created due to encapsulated class" ;
  end FRAME;

end Frame;

public uniontype InstStatus "Used to distinguish between different phases of the instantiation of a component
A component is first added to environment untyped. It can thereafter be instantiated to get its type 
and finally instantiated to produce the DAE. These three states are indicated by this datatype."

  record VAR_UNTYPED "Untyped variables, initially added to env"
  end VAR_UNTYPED;
  
  record VAR_TYPED "Typed variables, when instantiation to get type has been performed"
  end VAR_TYPED;
  
  record VAR_DAE "Typed variables that also have been instantiated to generate dae. Required to distinguish
                  between typed variables without DAE to know when to skip multiply declared dae elements"
  end VAR_DAE;                  
end InstStatus;

public 
uniontype Item
  record VAR
    Types.Var instantiated "instantiated component" ;
    Option<tuple<SCode.Element, Types.Mod>> declaration "declaration if not fully instantiated." ;
    InstStatus instStatus "if it untyped, typed or fully instantiated (dae)" ;
    Env env "The environment of the instantiated component
			       Contains e.g. all sub components 
			" ;
  end VAR;

  record CLASS
    SCode.Class class_;
    Env env;
  end CLASS;

  record TYPE
    list<Types.Type> list_ "list since several types with the same name can exist in the same scope (overloading)" ;
  end TYPE;

  record IMPORT
    Absyn.Import import_;
  end IMPORT;

end Item;

public 
type Env = list<Frame>;

public 
uniontype BinTree "The binary tree data structure
  ==============================
  The binary tree data structure used for the environment is generic and can 
  be used in any MetaModelica Compiler (MMC) application.
  The Tree data structure BinTree is defined as:"
  record TREENODE
    Option<TreeValue> value "Value" ;
    Option<BinTree> left "left subtree" ;
    Option<BinTree> right "right subtree" ;
  end TREENODE;

end BinTree;

public 
uniontype TreeValue "Each node in the binary tree can have a value associated with it."
  record TREEVALUE
    Key key "Key" ;
    Value value "Value" ;
  end TREEVALUE;

end TreeValue;

public 
type Key = Ident "Key" ;

public 
type Value = Item;
  
public 

protected import Dump;
protected import Graphviz;
protected import DAE;
protected import Print;
protected import Util;
protected import System;

public constant Env emptyEnv={} "- Values" ;

public constant Cache emptyCache = CACHE(NONE,NONE);

public function newFrame "- Relations
  function: newFrame
 
  This function creates a new frame, which includes setting up the 
  hashtable for the frame.
"
  input Boolean enc;
  output Frame outFrame;
  BinTree ht,httypes;
algorithm 
  ht := treeNew();
  httypes := treeNew();
  outFrame := FRAME(NONE,ht,httypes,{},{},({},Exp.CREF_IDENT("",{})),enc);
end newFrame;

public function openScope "function: openScope
 
  Opening a new scope in the environment mans adding a new frame on
  top of the stack of frames. If the scope is not the top scope a classname
  of the scope should be provided such that a name for the scope can be
  derived, see name_scope.
"
  input Env inEnv;
  input Boolean inBoolean;
  input Option<Ident> inIdentOption;
  output Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inEnv,inBoolean,inIdentOption)
    local
      Frame frame;
      Env env_1,env;
      Boolean encflag;
      Ident id;
    case (env,encflag,SOME(id)) /* encapsulated classname */ 
      equation 
        frame = newFrame(encflag);
        env_1 = nameScope((frame :: env), id);
      then
        env_1;
    case (env,encflag,NONE)
      equation 
        frame = newFrame(encflag);
      then
        (frame :: env);
  end matchcontinue;
end openScope;

protected function nameScope "function: nameScope
 
  This function names the current scope, giving it an identifier.
  Scopes needs to be named for several reasons. First, it is needed for
  debugging purposes, since it is easier to follow the environment if we 
  know what the current class being instantiated is.
  
  Secondly, it is needed when expanding type names in the context of 
  flattening of the inheritance hiergearchy. The reason for this is that types
  of inherited components needs to be expanded such that the types can be 
  looked up from the environment of the base class.
  See also openScope, getScopeName.
"
  input Env inEnv;
  input Ident inIdent;
  output Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inEnv,inIdent)
    local
      BinTree ht,httypes;
      list<Value> imps;
      Env bcframes,res;
      tuple<list<Exp.ComponentRef>,Exp.ComponentRef> crs;
      Boolean encflag;
      Ident id;
    case ((FRAME(list_2 = ht,list_3 = httypes,list_4 = imps,list_5 = bcframes,current6 = crs,encapsulated_7 = encflag) :: res),id) then (FRAME(SOME(id),ht,httypes,imps,bcframes,crs,encflag) :: res); 
  end matchcontinue;
end nameScope;

public function getScopeName "function: getScopeName
 Returns the name of a scope, if no name exist, the function fails.
"
  input Env inEnv;
  output Ident name;
algorithm 
  name:=
  matchcontinue (inEnv)
    case ((FRAME(class_1 = SOME(name))::_)) then (name); 
  end matchcontinue;
end getScopeName;


public function extendFrameC "function: extendFrameC
 
  This function adds a class definition to the environment.
"
  input Env inEnv;
  input SCode.Class inClass;
  output Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inEnv,inClass)
    local
      BinTree ht_1,ht,httypes;
      Env env,bcframes,fs;
      Option<Ident> id;
      list<Value> imps;
      tuple<list<Exp.ComponentRef>,Exp.ComponentRef> crs;
      Boolean encflag;
      SCode.Class c;
      Ident n;
    case ((env as (FRAME(class_1 = id,list_2 = ht,list_3 = httypes,list_4 = imps,list_5 = bcframes,current6 = crs,encapsulated_7 = encflag) :: fs)),(c as SCode.CLASS(name = n)))
      equation 
        (ht_1) = treeAdd(ht, n, CLASS(c,env), System.hash);
      then
        (FRAME(id,ht_1,httypes,imps,bcframes,crs,encflag) :: fs);
    case (_,_)
      equation 
        print("extend_frame_c FAILED\n");
      then
        fail();
  end matchcontinue;
end extendFrameC;

public function extendFrameClasses "function: extendFrameClasses
 
  Adds all clases in a Program to the environment.
"
  input Env inEnv;
  input SCode.Program inProgram;
  output Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inEnv,inProgram)
    local
      Env env,env_1,env_2;
      SCode.Class c;
      list<SCode.Class> cs;
    case (env,{}) then env; 
    case (env,(c :: cs))
      equation 
        env_1 = extendFrameC(env, c);
        env_2 = extendFrameClasses(env_1, cs);
      then
        env_2;
  end matchcontinue;
end extendFrameClasses;

public function extendFrameV "function: extendFrameV
 
  This function adds a component to the environment.
"
  input Env inEnv1;
  input Types.Var inVar2;
  input Option<tuple<SCode.Element, Types.Mod>> inTplSCodeElementTypesModOption3;
  input InstStatus instStatus;
  input Env inEnv5;
  output Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inEnv1,inVar2,inTplSCodeElementTypesModOption3,instStatus,inEnv5)
    local
      BinTree ht_1,ht,httypes;
      Option<Ident> id;
      list<Value> imps;
      Env bcframes,fs,env;
      tuple<list<Exp.ComponentRef>,Exp.ComponentRef> crs;
      Boolean encflag;
      InstStatus i;
      Types.Var v;
      Ident n;
      Option<tuple<SCode.Element, Types.Mod>> c;
    case ((FRAME(class_1 = id,list_2 = ht,list_3 = httypes,list_4 = imps,list_5 = bcframes,current6 = crs,encapsulated_7 = encflag) :: fs),(v as Types.VAR(name = n)),c,i,env) /* environment of component */ 
      equation 
        failure((_)= treeGet(ht, n, System.hash)); 
        (ht_1) = treeAdd(ht, n, VAR(v,c,i,env), System.hash);
      then
        (FRAME(id,ht_1,httypes,imps,bcframes,crs,encflag) :: fs);

        // Variable already added, perhaps from baseclass
    case ((FRAME(class_1 = id,list_2 = ht,list_3 = httypes,list_4 = imps,list_5 = bcframes,current6 = crs,encapsulated_7 = encflag) :: fs),(v as Types.VAR(name = n)),c,i,env) /* environment of component */ 
      equation 
        (_)= treeGet(ht, n, System.hash); 
      then
        (FRAME(id,ht,httypes,imps,bcframes,crs,encflag) :: fs);
  end matchcontinue;
end extendFrameV;

public function updateFrameV "function: updateFrameV
 
  This function updates a component already added to the environment, but 
  that prior to the update did not have any binding. I.e this function is
  called in the second stage of instantiation with declare before use.
"
  input Env inEnv1;
  input Types.Var inVar2;
  input InstStatus instStatus;
  input Env inEnv4;
  output Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inEnv1,inVar2,instStatus,inEnv4)
    local
      Boolean encflag;
      InstStatus i;
      Option<tuple<SCode.Element, Types.Mod>> c;
      BinTree ht_1,ht,httypes;
      Option<Ident> sid;
      list<Value> imps;
      Env bcframes,fs,env,frames;
      tuple<list<Exp.ComponentRef>,Exp.ComponentRef> crs;
      Types.Var v;
      Ident n,id;
    case ({},_,i,_) then {};  /* fully instantiated env of component */ 
    case ((FRAME(class_1 = sid,list_2 = ht,list_3 = httypes,list_4 = imps,list_5 = bcframes,current6 = crs,encapsulated_7 = encflag) :: fs),(v as Types.VAR(name = n)),i,env)
      equation 
        VAR(_,c,_,_) = treeGet(ht, n, System.hash);
        (ht_1) = treeAdd(ht, n, VAR(v,c,i,env), System.hash);
      then
        (FRAME(sid,ht_1,httypes,imps,bcframes,crs,encflag) :: fs);
    case ((FRAME(class_1 = sid,list_2 = ht,list_3 = httypes,list_4 = imps,list_5 = bcframes,current6 = crs,encapsulated_7 = encflag) :: fs),(v as Types.VAR(name = n)),i,env) /* Also check frames above, e.g. when variable is in base class */ 
      equation 
        frames = updateFrameV(fs, v, i, env);
      then
        (FRAME(sid,ht,httypes,imps,bcframes,crs,encflag) :: frames);
    case ((FRAME(class_1 = sid,list_2 = ht,list_3 = httypes,list_4 = imps,list_5 = bcframes,current6 = crs,encapsulated_7 = encflag) :: fs),Types.VAR(name = n),_,_)
      equation 
        Print.printBuf("- update_frame_v, variable ");
        Print.printBuf(n);
        Print.printBuf(" not found\n rest of env:");
        printEnv(fs);
        Print.printBuf("\n");
      then
        (FRAME(sid,ht,httypes,imps,bcframes,crs,encflag) :: fs);
    case (_,(v as Types.VAR(name = id)),_,_)
      equation 
        Print.printBuf("- update_frame_v failed\n");
        Print.printBuf("  - variable: ");
        Types.printVar(v);
        Print.printBuf("\n");
      then
        fail();
  end matchcontinue;
end updateFrameV;

public function extendFrameT "function: extendFrameT
 
  This function adds a type to the environment.  Types in the
  environment are used for looking up constants etc. inside class
  definitions, such as packages.  For each type in the environment,
  there is a class definition with the same name in the
  environment.
"
  input Env inEnv;
  input Ident inIdent;
  input Types.Type inType;
  output Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inEnv,inIdent,inType)
    local
      list<tuple<Types.TType, Option<Absyn.Path>>> tps;
      BinTree httypes_1,ht,httypes;
      Option<Ident> sid;
      list<Value> imps;
      Env bcframes,fs;
      tuple<list<Exp.ComponentRef>,Exp.ComponentRef> crs;
      Boolean encflag;
      Ident n;
      tuple<Types.TType, Option<Absyn.Path>> t;
    case ((FRAME(class_1 = sid,list_2 = ht,list_3 = httypes,list_4 = imps,list_5 = bcframes,current6 = crs,encapsulated_7 = encflag) :: fs),n,t)
      equation 
        TYPE(tps) = treeGet(httypes, n, System.hash) "Other types with that name allready exist, add this type as well" ;
        (httypes_1) = treeAdd(httypes, n, TYPE((t :: tps)), System.hash);
      then
        (FRAME(sid,ht,httypes_1,imps,bcframes,crs,encflag) :: fs);
    case ((FRAME(class_1 = sid,list_2 = ht,list_3 = httypes,list_4 = imps,list_5 = bcframes,current6 = crs,encapsulated_7 = encflag) :: fs),n,t)
      equation 
        failure(TYPE(_) = treeGet(httypes, n, System.hash)) "No other types exists" ;
        (httypes_1) = treeAdd(httypes, n, TYPE({t}), System.hash);
      then
        (FRAME(sid,ht,httypes_1,imps,bcframes,crs,encflag) :: fs);
  end matchcontinue;
end extendFrameT;

public function extendFrameI "function: extends_frame_i
 
  Adds an import statement to the environment.
"
  input Env inEnv;
  input Absyn.Import inImport;
  output Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inEnv,inImport)
    local
      Option<Ident> sid;
      BinTree ht,httypes;
      list<Value> imps;
      Env bcframes,fs;
      tuple<list<Exp.ComponentRef>,Exp.ComponentRef> crs;
      Boolean encflag;
      Absyn.Import imp;
      Env env;
    case ((FRAME(class_1 = sid,list_2 = ht,list_3 = httypes,list_4 = imps,list_5 = bcframes,current6 = crs,encapsulated_7 = encflag) :: fs),imp) 
      equation
        false = memberImportList(imps,imp);
    then (FRAME(sid,ht,httypes,(IMPORT(imp) :: imps),bcframes,crs,encflag) :: fs);
      case (env,imp) then env;
  end matchcontinue;
end extendFrameI;

protected function memberImportList "Returns true if import exist in imps"
	input list<Item> imps;
	input Absyn.Import imp;
  output Boolean res "true if import exist in imps, false otherwise";	
algorithm
  res := matchcontinue (imps,imp) 
  	local 
  	  list<Item> ims;
  		Absyn.Import imp2;
  		Boolean res;
    case (IMPORT(imp2)::ims,imp) 
      equation
     		equality(imp2 = imp); 
    then true;
   
    case (_::ims,imp) equation 
       res=memberImportList(ims,imp);
    then res;
    case (_,_) then false;
   end matchcontinue;
end memberImportList;

public function addBcFrame "function: addBcFrame
  author: PA
 
  Adds a baseclass frame to the environment from the baseclass environment
  to the list of base classes of the top frame of the passed environment.
"
  input Env inEnv1;
  input Env inEnv2;
  output Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inEnv1,inEnv2)
    local
      Option<Ident> sid;
      BinTree cls,tps;
      list<Value> imps;
      Env bc,fs;
      tuple<list<Exp.ComponentRef>,Exp.ComponentRef> crefs;
      Boolean enc;
      Frame f;
    case ((FRAME(class_1 = sid,list_2 = cls,list_3 = tps,list_4 = imps,list_5 = bc,current6 = crefs,encapsulated_7 = enc) :: fs),(f :: _)) then (FRAME(sid,cls,tps,imps,(f :: bc),crefs,enc) :: fs);  /* env bc env */ 
  end matchcontinue;
end addBcFrame;

public function topFrame "function: topFrame
 
  Returns the top frame.
"
  input Env inEnv;
  output Frame outFrame;
algorithm 
  outFrame:=
  matchcontinue (inEnv)
    local
      Frame fr,elt;
      Env lst;
    case ({fr}) then fr; 
    case ((elt :: (lst as (_ :: _))))
      equation 
        fr = topFrame(lst);
      then
        fr;
  end matchcontinue;
end topFrame;

public function getClassName
  input Env inEnv;
  output Ident name;
algorithm
   name := matchcontinue (inEnv) 
   	local Ident n;
   	case FRAME(class_1 = SOME(n))::_ then n;
  end matchcontinue;
end getClassName;    	

public function getEnvPath "function: getEnvPath
 
  This function returns all partially instantiated parents as an Absyn.Path 
  option I.e. it collects all identifiers of each frame until it reaches 
  the topmost unnamed frame. If the environment is only the topmost frame, 
  NONE is returned.
"
  input Env inEnv;
  output Option<Absyn.Path> outAbsynPathOption;
algorithm 
  outAbsynPathOption:=
  matchcontinue (inEnv)
    local
      Ident id;
      Absyn.Path path,path_1;
      Env rest;
    case ({FRAME(class_1 = SOME(id)),FRAME(class_1 = NONE)}) then SOME(Absyn.IDENT(id)); 
    case ((FRAME(class_1 = SOME(id)) :: rest))
      equation 
        SOME(path) = getEnvPath(rest);
        path_1 = Absyn.joinPaths(path, Absyn.IDENT(id));
      then
        SOME(path_1);
    case (_) then NONE; 
  end matchcontinue;
end getEnvPath;

public function printEnvPathStr "function: printEnvPathStr
 
  Retrive the environment path as a string, see get_env_path.
"
  input Env inEnv;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inEnv)
    local
      Absyn.Path path;
      Ident pathstr;
      Env env;
    case (env)
      equation 
        SOME(path) = getEnvPath(env);
        pathstr = Absyn.pathString(path);
      then
        pathstr;
    case (env) then "<global scope>"; 
  end matchcontinue;
end printEnvPathStr;

public function printEnvPath "function: printEnvPath
 
  Print the environment path to the Print buffer. 
  See also get_env_path
"
  input Env inEnv;
algorithm 
  _:=
  matchcontinue (inEnv)
    local
      Absyn.Path path;
      Ident pathstr;
      Env env;
    case (env)
      equation 
        SOME(path) = getEnvPath(env);
        pathstr = Absyn.pathString(path);
        Print.printBuf(pathstr);
      then
        ();
    case (env)
      equation 
        Print.printBuf("TOPENV");
      then
        ();
  end matchcontinue;
end printEnvPath;

public function printEnvStr "function: printEnvStr
 
  Print the environment as a string.
"
  input Env inEnv;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inEnv)
    local
      Ident s1,s2,res;
      Frame fr;
      Env frs;
    case {} then "Empty env\n"; 
    case (fr :: frs)
      equation 
        s1 = printFrameStr(fr);
        s2 = printEnvStr(frs);
        res = stringAppend(s1, s2);
      then
        res;
  end matchcontinue;
end printEnvStr;

public function printEnv "function: printEnv
 
  Print the environment to the Print buffer.
"
  input Env e;
  Ident s;
algorithm 
  s := printEnvStr(e);
  Print.printBuf(s);
end printEnv;

protected function printFrameStr "function: printFrameStr
 
  Print a Frame to a string.
"
  input Frame inFrame;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inFrame)
    local
      Ident s1,s2,s3,encflag_str,s4,res,sid;
      BinTree ht,httypes;
      list<Value> imps;
      Env bcframes;
      tuple<list<Exp.ComponentRef>,Exp.ComponentRef> crs;
      Boolean encflag;
    case FRAME(class_1 = SOME(sid),list_2 = ht,list_3 = httypes,list_4 = imps,list_5 = bcframes,current6 = crs,encapsulated_7 = encflag)
      equation 
        s1 = printBintreeStr(ht);
        s2 = printBintreeStr(httypes);
        s3 = printImportsStr(imps);
        encflag_str = Util.boolString(encflag);
        s4 = printEnvStr(bcframes);
        res = Util.stringAppendList(
          {"FRAME: ",sid," (enc=",encflag_str,
          ") \nclasses and vars:\n=============\n",s1,"   Types:\n======\n",s2,"   Imports:\n=======\n",s3,"baseclass:\n======\n",s4,"end baseclass\n"});
      then
        res;
    case FRAME(class_1 = NONE,list_2 = ht,list_3 = httypes,list_4 = imps,list_5 = bcframes,current6 = crs,encapsulated_7 = encflag)
      equation 
        s1 = printBintreeStr(ht);
        s2 = printBintreeStr(httypes);
        s3 = printImportsStr(imps);
        s4 = printEnvStr(bcframes);
        encflag_str = Util.boolString(encflag);
        res = Util.stringAppendList(
          {"FRAME: unnamed (enc=",encflag_str,
          ") \nclasses and vars:\n=============\n",s1,"   Types:\n======\n",s2,"   Imports:\n=======\n",s3,"baseclass:\n======\n",s4,"end baseclass\n"});
      then
        res;
  end matchcontinue;
end printFrameStr;

protected function printFrameVarsStr "function: printFrameVarsStr
 
  Print only the variables in a Frame to a string.
"
  input Frame inFrame;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inFrame)
    local
      Ident s1,encflag_str,res,sid;
      BinTree ht,httypes;
      list<Value> imps;
      Env bcframes;
      tuple<list<Exp.ComponentRef>,Exp.ComponentRef> crs;
      Boolean encflag;
    case FRAME(class_1 = SOME(sid),list_2 = ht,list_3 = httypes,list_4 = imps,list_5 = bcframes,current6 = crs,encapsulated_7 = encflag)
      equation 
        s1 = printBintreeStr(ht);
        encflag_str = Util.boolString(encflag);
        res = Util.stringAppendList(
          {"FRAME: ",sid," (enc=",encflag_str,
          ") \nclasses and vars:\n=============\n",s1,"\n\n\n"});
      then
        res;
    case FRAME(class_1 = NONE,list_2 = ht,list_3 = httypes,list_4 = imps,list_5 = bcframes,current6 = crs,encapsulated_7 = encflag)
      equation 
        s1 = printBintreeStr(ht);
        encflag_str = Util.boolString(encflag);
        res = Util.stringAppendList(
          {"FRAME: unnamed (enc=",encflag_str,
          ") \nclasses and vars:\n=============\n",s1,"\n\n\n"});
      then
        res;
    case _ then ""; 
  end matchcontinue;
end printFrameVarsStr;

protected function printImportsStr "function: printImportsStr
 
  Print import statements to a string.
"
  input list<Item> inItemLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inItemLst)
    local
      Ident s1,s2,res;
      Value e;
      list<Value> rst;
    case {} then ""; 
    case {e}
      equation 
        s1 = printFrameElementStr(("",e));
      then
        s1;
    case ((e :: rst))
      equation 
        s1 = printFrameElementStr(("",e));
        s2 = printImportsStr(rst);
        res = Util.stringAppendList({s1,", ",s2});
      then
        res;
  end matchcontinue;
end printImportsStr;

protected function printFrameElementStr "function: printFrameElementStr
 
  Print frame element to a string
"
  input tuple<Ident, Item> inTplIdentItem;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inTplIdentItem)
    local
      Ident s,elt_str,tp_str,var_str,frame_str,bind_str,res,n,lenstr;
      Types.Var tv;
      SCode.Variability var;
      tuple<Types.TType, Option<Absyn.Path>> tp;
      Types.Binding bind,bnd;
      SCode.Element elt;
      InstStatus i;
      Frame compframe;
      Env env;
      Integer len;
      list<tuple<Types.TType, Option<Absyn.Path>>> lst;
      Absyn.Import imp;
    case ((n,VAR(instantiated = (tv as Types.VAR(attributes = Types.ATTR(parameter_ = var),type_ = tp,binding = bind)),declaration = SOME((elt,_)),instStatus = i,env = (compframe :: _))))
      equation 
        s = SCode.variabilityString(var);
        elt_str = SCode.printElementStr(elt);
        tp_str = Types.unparseType(tp);
        var_str = Types.unparseVar(tv);
        frame_str = printFrameVarsStr(compframe);
        bind_str = Types.printBindingStr(bind);
        res = Util.stringAppendList(
          {"v:",n," ",s,"(",elt_str,") [",tp_str,"] {",var_str,
          "}, binding:",bind_str});
      then
        res;
    case ((n,VAR(instantiated = (tv as Types.VAR(attributes = Types.ATTR(parameter_ = var),type_ = tp)),declaration = SOME((elt,_)),instStatus = i,env = {})))
      equation 
        s = SCode.variabilityString(var);
        elt_str = SCode.printElementStr(elt);
        tp_str = Types.unparseType(tp);
        var_str = Types.unparseVar(tv);
        res = Util.stringAppendList(
          {"v:",n," ",s,"(",elt_str,") [",tp_str,"] {",var_str,
          "}, compframe: []"});
      then
        res;
    case ((n,VAR(instantiated = Types.VAR(binding = bnd),declaration = NONE,instStatus = i,env = env)))
      equation 
        res = Util.stringAppendList({"v:",n,"\n"});
      then
        res;
    case ((n,CLASS(class_ = _)))
      equation 
        res = Util.stringAppendList({"c:",n,"\n"});
      then
        res;
    case ((n,TYPE(list_ = lst)))
      equation 
        len = listLength(lst);
        lenstr = intString(len);
        res = Util.stringAppendList({"t:",n," (",lenstr,")\n"});
      then
        res;
    case ((n,IMPORT(import_ = imp)))
      equation 
        s = Dump.unparseImportStr(imp);
        res = Util.stringAppendList({"imp:",s,"\n"});
      then
        res;
  end matchcontinue;
end printFrameElementStr;

public function printEnvGraphviz "function: printEnvGraphviz
 
  Print the environment in Graphviz format to the Print buffer.
"
  input tuple<Env, String> inTplEnvString;
algorithm 
  _:=
  matchcontinue (inTplEnvString)
    local
      Graphviz.Node r;
      Env env;
      Ident str;
    case ((env,str))
      equation 
        r = buildEnvGraphviz((env,str));
        Graphviz.dump(r);
      then
        ();
  end matchcontinue;
end printEnvGraphviz;

protected function buildEnvGraphviz "function: buildEnvGraphviz
 
  Build the graphviz graph from an Env.
"
  input tuple<Env, String> inTplEnvString;
  output Graphviz.Node outNode;
algorithm 
  outNode:=
  matchcontinue (inTplEnvString)
    local
      Ident str_1,str;
      list<Graphviz.Node> nodelist;
      Env env;
    case ((env,str))
      equation 
        str_1 = stringAppend("ROOT: ", str);
        nodelist = buildEnvGraphviz2(env);
      then
        Graphviz.NODE(str_1,{},nodelist);
  end matchcontinue;
end buildEnvGraphviz;

protected function buildEnvGraphviz2 "function: buildEnvGraphviz2
 
  Helper function to build_env_graphviz.
"
  input Env inEnv;
  output list<Graphviz.Node> outGraphvizNodeLst;
algorithm 
  outGraphvizNodeLst:=
  matchcontinue (inEnv)
    local
      list<Graphviz.Node> nodelist;
      Graphviz.Node node;
      Frame frame;
      Env rest;
    case {} then {}; 
    case (frame :: rest)
      equation 
        nodelist = buildEnvGraphviz2(rest);
        node = buildFrameGraphviz(frame);
      then
        (node :: nodelist);
  end matchcontinue;
end buildEnvGraphviz2;

protected function isVarItem "function: isVarItem
 
  Succeeds if item is a VAR.
"
  input tuple<Type_a, Item> inTplTypeAItem;
  replaceable type Type_a subtypeof Any;
algorithm 
  _:=
  matchcontinue (inTplTypeAItem)
    case ((_,VAR(instantiated = _))) then (); 
  end matchcontinue;
end isVarItem;

protected function isClassItem "function: isClassItem
 
  Succeeds if item is a CLASS.
"
  input tuple<Type_a, Item> inTplTypeAItem;
  replaceable type Type_a subtypeof Any;
algorithm 
  _:=
  matchcontinue (inTplTypeAItem)
    case ((_,CLASS(class_ = _))) then (); 
  end matchcontinue;
end isClassItem;

protected function isTypeItem "function: isTypeItem
 
  Succeds if item is a TYPE.
"
  input tuple<Type_a, Item> inTplTypeAItem;
  replaceable type Type_a subtypeof Any;
algorithm 
  _:=
  matchcontinue (inTplTypeAItem)
    case ((_,TYPE(list_ = _))) then (); 
  end matchcontinue;
end isTypeItem;

protected function buildFrameGraphviz "function: buildFrameGraphviz
 
  Build a Grapviz Node from a Frame.
"
  input Frame inFrame;
  output Graphviz.Node outNode;
algorithm 
  outNode:=
  matchcontinue (inFrame)
    local
      Option<Ident> sid;
      BinTree ht,httypes;
      list<Value> imps;
      Env bcframes;
      tuple<list<Exp.ComponentRef>,Exp.ComponentRef> crs;
      Boolean encflag;
    case FRAME(class_1 = sid,list_2 = ht,list_3 = httypes,list_4 = imps,list_5 = bcframes,current6 = crs,encapsulated_7 = encflag) then Graphviz.NODE("FRAME",{},{}); 
  end matchcontinue;
end buildFrameGraphviz;

protected function buildItemListnode "function: buildItemListnode
 
  Build a Graphviz Node from a list of items, selected by a condition
  function among the input list.
"
  input list<tuple<Ident, Item>> items;
  input FuncTypeTplIdentItemTo cond;
  input String name;
  output Graphviz.Node outNode;
  partial function FuncTypeTplIdentItemTo
    input tuple<Ident, Item> inTplIdentItem;
  end FuncTypeTplIdentItemTo;
  list<tuple<Ident, Value>> selitems;
  Graphviz.Node node;
algorithm 
  selitems := Util.listMatching(items, cond);
  node := buildItemListnode2(selitems, 1);
  outNode := Graphviz.NODE(name,{},{node});
end buildItemListnode;

protected function buildItemListnode2 "function: buildItemListnode2
 
  Helper function to build_item_listnode.
"
  input list<tuple<Ident, Item>> inTplIdentItemLst;
  input Integer inInteger;
  output Graphviz.Node outNode;
algorithm 
  outNode:=
  matchcontinue (inTplIdentItemLst,inInteger)
    local
      list<Ident> strlist;
      Ident cstr;
      list<tuple<Ident, Value>> items,ignored;
      Integer count,count_1;
      Graphviz.Node restnode;
    case (items,count)
      equation 
        (strlist,{}) = DAE.buildGrStrlist(items, buildItemStr, 10);
        cstr = intString(count);
      then
        Graphviz.LNODE(cstr,strlist,{Graphviz.box},{});
    case (items,count)
      equation 
        (strlist,ignored) = DAE.buildGrStrlist(items, buildItemStr, 10);
        cstr = intString(count);
        count_1 = count + 1;
        restnode = buildItemListnode2(ignored, count_1);
      then
        Graphviz.LNODE(cstr,strlist,{Graphviz.box},{restnode});
  end matchcontinue;
end buildItemListnode2;

protected function buildItemStr "function: buildItemStr
 
  Helper function to build_item_listnode_2, creates a string from an item.
"
  input tuple<Ident, Item> inTplIdentItem;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inTplIdentItem)
    local
      Ident s,id;
      SCode.Class cls;
      Env env;
    case ((id,VAR(instantiated = _)))
      equation 
        s = stringAppend("VAR: ", id);
      then
        s;
    case ((id,CLASS(class_ = cls,env = env)))
      equation 
        s = stringAppend("CLASS: ", id) "build_env_graphviz env => r &" ;
      then
        s;
    case ((id,TYPE(list_ = _)))
      equation 
        s = stringAppend("TYPE: ", id);
      then
        s;
  end matchcontinue;
end buildItemStr;

public function myhash "BinTree implementation
  function: myhash
 
  Hash function for binary tree implementation, using standard string
  hashing.
"
  input Key str;
  output Integer res;
algorithm 
  res := System.hash(str);
end myhash;

protected function treeNew "function: treeNew
 
  Create a new binary tree.
"
  output BinTree outBinTree;
algorithm 
  outBinTree:=
  matchcontinue ()
    case () then TREENODE(NONE,NONE,NONE); 
  end matchcontinue;
end treeNew;

public function treeAdd "function: treeAdd
 
  Add a tree to a binary tree.
"
  input BinTree inBinTree;
  input Key inKey;
  input Value inValue;
  input FuncTypeKeyToInteger inFuncTypeKeyToInteger;
  output BinTree outBinTree;
  partial function FuncTypeKeyToInteger
    input Key inKey;
    output Integer outInteger;
  end FuncTypeKeyToInteger;
algorithm 
  outBinTree:=
  matchcontinue (inBinTree,inKey,inValue,inFuncTypeKeyToInteger)
    local
      partial function FuncTypeStringToInteger
        input String inString;
        output Integer outInteger;
      end FuncTypeStringToInteger;
      Ident key,rkey;
      Value value,rval;
      Option<BinTree> left,right;
      FuncTypeStringToInteger hashfunc;
      Integer hval,rhval;
      BinTree t_1,t,right_1,left_1;
    case (TREENODE(value = NONE,left = NONE,right = NONE),key,value,_) then TREENODE(SOME(TREEVALUE(key,value)),NONE,NONE);  /* hash func */ 
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),left = left,right = right),key,value,hashfunc) /* Replace this node */ 
      equation 
        equality(rkey = key);
      then
        TREENODE(SOME(TREEVALUE(rkey,value)),left,right);
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),left = left,right = (right as SOME(t))),key,value,hashfunc) /* Insert to right subtree */ 
      equation 
        hval = hashfunc(key);
        rhval = hashfunc(rkey);
        (hval > rhval) = true;
        t_1 = treeAdd(t, key, value, hashfunc);
      then
        TREENODE(SOME(TREEVALUE(rkey,rval)),left,SOME(t_1));
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),left = left,right = (right as NONE)),key,value,hashfunc) /* Insert to right node */ 
      equation 
        hval = hashfunc(key);
        rhval = hashfunc(rkey);
        (hval > rhval) = true;
        right_1 = treeAdd(TREENODE(NONE,NONE,NONE), key, value, hashfunc);
      then
        TREENODE(SOME(TREEVALUE(rkey,rval)),left,SOME(right_1));
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),left = (left as SOME(t)),right = right),key,value,hashfunc) /* Insert to left subtree */ 
      equation 
        hval = hashfunc(key);
        rhval = hashfunc(rkey);
        (hval <= rhval) = true;
        t_1 = treeAdd(t, key, value, hashfunc);
      then
        TREENODE(SOME(TREEVALUE(rkey,rval)),SOME(t_1),right);
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),left = (left as NONE),right = right),key,value,hashfunc) /* Insert to left node */ 
      equation 
        hval = hashfunc(key);
        rhval = hashfunc(rkey);
        (hval <= rhval) = true;
        left_1 = treeAdd(TREENODE(NONE,NONE,NONE), key, value, hashfunc);
      then
        TREENODE(SOME(TREEVALUE(rkey,rval)),SOME(left_1),right);
    case (_,_,_,_)
      equation 
        print("tree_add failed\n");
      then
        fail();
  end matchcontinue;
end treeAdd;

public function getCachedInitialEnv "get the initial environment from the cache"
  input Cache cache;
  output Env env;
algorithm	
  env := matchcontinue(cache) 
    //case (_) then fail();
    case (CACHE(_,SOME(env))) equation
    //	print("getCachedInitialEnv\n");
      then env;
  end matchcontinue;
end getCachedInitialEnv;  

public function setCachedInitialEnv "set the initial environment in the cache"
  input Cache inCache;
  input Env env;
  output Cache outCache;
algorithm	
  outCache := matchcontinue(inCache,env) 
  local
    	Option<EnvCache> envCache;

    case (CACHE(envCache,_),env) equation 
 //    	print("setCachedInitialEnv\n");
      then CACHE(envCache,SOME(env));
  end matchcontinue;
end setCachedInitialEnv;  
    
public function cacheGet "Get an environment from the cache."
  input Absyn.Path scope;
  input Absyn.Path path;
  input Cache cache;
  output Env env;
algorithm
  env:= matchcontinue(scope,path,cache)
  local CacheTree tree;
   case (scope,path,CACHE(SOME(ENVCACHE(tree)),_))
      equation
        
        env = cacheGetEnv(scope,path,tree);
        //print("got cached env for ");print(Absyn.pathString(path)); print("\n");
      then env;          
    case (_,_,_) then fail();
  end matchcontinue;
end cacheGet;


public function cacheAdd "Add an environment to the cache."
  input Absyn.Path fullpath "Fully qualified path to the environment";
  input Cache inCache ;
  input Env env "environment";
  output Cache outCache;
algorithm
  outCache := matchcontinue(fullpath,inCache,env)
  local CacheTree tree;
    Option<Env> ie;
      
    case (fullpath,CACHE(NONE,ie),env) 
      equation
        tree = cacheAddEnv(fullpath,CACHETREE("$global",emptyEnv,{}),env);
        //print("Adding ");print(Absyn.pathString(fullpath));print(" to empty cache\n");
      then CACHE(SOME(ENVCACHE(tree)),ie);
    case (fullpath,CACHE(SOME(ENVCACHE(tree)),ie),env) 
      equation
       // print(" about to Adding ");print(Absyn.pathString(fullpath));print(" to cache:\n");
      tree = cacheAddEnv(fullpath,tree,env);
      
       //print("Adding ");print(Absyn.pathString(fullpath));print(" to cache\n");
        //print(printCacheStr(CACHE(SOME(ENVCACHE(tree)),ie)));
      then CACHE(SOME(ENVCACHE(tree)),ie);
    case (_,_,_) equation print("cacheAdd failed\n"); then fail();
  end matchcontinue;
end cacheAdd;

protected function cacheGetEnv "get an environment from the tree cache."
	input Absyn.Path scope;
	input Absyn.Path path;
	input CacheTree tree;
	output Env env;
algorithm
  env := matchcontinue(scope,path,tree)
  local
    	Absyn.Path path2;
    	Ident id;
    	list<CacheTree> children;
    	
			// Search this scope.
    case (path2,path,tree)
      equation
        env = cacheGetEnv2(path2,path,tree);
        //print("found ");print(Absyn.pathString(path));print(" in cache at scope");
				//print(Absyn.pathString(path2));print("\n");
      then env;

		   // Go up one level. Only if we search for e.g. M.C.E and in scope M
 /*   case (path2,path,tree)
      local Ident id1,id2;
      equation
        id1=Absyn.pathFirstIdent(path2);
        id2 = Absyn.pathFirstIdent(path);
        id1 = id2; // only then because otherwise we might lookup wrong class (Eg. Modelica.Math instead of Modelica.Blocks.Math)
        path2 =Absyn.stripLast(path2);
        env = cacheGetEnv(path2,path,tree);
        //print("found in cache\n");
      then env;      
   */     
/*        // Finally try top level
    case (Absyn.IDENT(_),path,CACHETREE(_,_,children))
      equation
        env = cacheGetEnv3(path,children);
        //print("found in cache\n");
      then env;      
  */     
  end matchcontinue;
end cacheGetEnv;
 
protected function cacheGetEnv2 "Help function to cacheGetEnv. Searches in one scope by 
  first looking up the scope and then search from there."
  input Absyn.Path scope;
  input Absyn.Path path;
  input CacheTree tree;
  output Env env;
  
algorithm
   env := matchcontinue(scope,path,tree)
	local 	
	  	Env env2;
	  	Ident id,id2;
	  	list<CacheTree> children,children2;
	  	Absyn.Path path2;

	  //	Simple name found in children, search for model from this scope.
     case (Absyn.IDENT(id),path,CACHETREE(_,_,CACHETREE(id2,env2,children2)::_))
       equation 
         equality(id = id2);
         //print("found (1) ");print(id); print("\n");
         env=cacheGetEnv3(path,children2); 
       then env;
         
         //	Simple name. try next.
     case (Absyn.IDENT(id),path,CACHETREE(id2,env2,_::children))
       equation 
         //print("try next ");print(id);print("\n");
         env=cacheGetEnv2(Absyn.IDENT(id),path,CACHETREE(id2,env2,children));
       then env;
         
    // for qualified name, found first matching identifier in child
     case (Absyn.QUALIFIED(id,path2),path,CACHETREE(_,_,CACHETREE(id2,env2,children2)::_))
       equation
         equality(id=id2);
         //print("found qualified (1) ");print(id);print("\n");
         env = cacheGetEnv2(path2,path,CACHETREE(id2,env2,children2));
       then env;
           
    // for qualified name, try next
     case (Absyn.QUALIFIED(id,path2),path,CACHETREE(id2,env2,_::children2))
       equation
         //print("try next qualified ");print(id);print("\n");
         env = cacheGetEnv2(path2,path,CACHETREE(id2,env2,children2));
       then env;
   end matchcontinue;  
end cacheGetEnv2;

protected function cacheGetEnv3 "Help function to cacheGetEnv2, searches down in tree for env."
  input Absyn.Path path;
  input list<CacheTree> children;
  output Env env;
algorithm
  env := matchcontinue(path,tree)

    local
      Ident id,id2;

		//found matching simple name
    case (Absyn.IDENT(id),CACHETREE(id2,env,_)::_)
      equation
        equality(id =id2); then env;
     
     // found matching qualified name
    case (Absyn.QUALIFIED(id,path),CACHETREE(id2,_,children)::_) 
      equation
        equality(id =id2);
        	env = cacheGetEnv3(path,children);
         then env;

     // try next      
    case (path,_::children) 
      equation
        	env = cacheGetEnv3(path,children);
         then env;
  end matchcontinue;
end cacheGetEnv3;

public function cacheAddEnv "Add an environment to the cache"
  input Absyn.Path fullpath "Fully qualified path to the environment";
  input CacheTree tree ;
  input Env env "environment";
  output CacheTree outTree;
algorithm
  outTree := matchcontinue(path,tree,env)
    local 
      Ident id,globalID,id2;
      Absyn.Path path;
      Env globalEnv,oldEnv;
      list<CacheTree> children,children2;
      CacheTree child;
      // simple names already added
      case (Absyn.IDENT(id),(tree as CACHETREE(globalID,globalEnv,CACHETREE(id2,oldEnv,children)::children2)),env) 
        equation
          //print(id);print(" already added\n");
          equality(id=id2);
          then tree;
            
       // simple names try next
      case (Absyn.IDENT(id),tree as CACHETREE(globalID,globalEnv,child::children),env) 
        equation
          CACHETREE(globalID,globalEnv,children) = cacheAddEnv(Absyn.IDENT(id),CACHETREE(globalID,globalEnv,children),env);
          then CACHETREE(globalID,globalEnv,child::children);
                        
      // Simple names, not found
    case (Absyn.IDENT(id),CACHETREE(globalID,globalEnv,{}),env) 
    then CACHETREE(globalID,globalEnv,{CACHETREE(id,env,{})});
      
      // Qualified names.
    case (path as Absyn.QUALIFIED(_,_),CACHETREE(globalID,globalEnv,children),env)
      equation
        children=cacheAddEnv2(path,children,env);
      then CACHETREE(globalID,globalEnv,children);
    case (path,_,_) equation print("cacheAddEnv path=");print(Absyn.pathString(path));print(" failed\n");
      then fail();
  end matchcontinue;
end cacheAddEnv;

protected function cacheAddEnv2
  input Absyn.Path path;
  input list<CacheTree> inChilren;
  input Env env;
  output list<CacheTree> outChildren;
algorithm
  outChildren := matchcontinue(path,inChildren,env)
    local 
      Ident id,id2;
      Absyn.Path path;
      list<CacheTree> children,children2;
      CacheTree child;
      Env env2;
      
      // qualified name, found matching    
    case(Absyn.QUALIFIED(id,path),CACHETREE(id2,env2,children2)::children,env)
      equation
        equality(id=id2);
        children2 = cacheAddEnv2(path,children2,env);
      then	CACHETREE(id2,env2,children2)::children;

		// simple name, found matching
    case (Absyn.IDENT(id),CACHETREE(id2,env2,children2)::children,env) 
      equation
        equality(id=id2);
        //print("single name, found matching\n");
      then CACHETREE(id2,env2,children2)::children;
        
        // try next
    case(path,child::children,env)
      equation
        //print("try next\n");
        children = cacheAddEnv2(path,children,env);
      then	child::children;
        
    // qualified name no child found, create one.
    case (Absyn.QUALIFIED(id,path),{},env) 
      equation        
        children = cacheAddEnv2(path,{},env);
        //print("qualified name no child found, create one.\n");
      then {CACHETREE(id,emptyEnv,children)};   

    // simple name no child found, create one.
    case (Absyn.IDENT(id),{},env) 
      equation
        //print("simple name no child found, create one.\n");
      then {CACHETREE(id,env,{})};
        
    case (_,_,_) equation print("cacheAddEnv2 failed\n"); then fail();
  end matchcontinue;
end cacheAddEnv2;  

public function printCacheStr
  input Cache cache;
  output String str;
algorithm
  str := matchcontinue(cache)
  local CacheTree tree;
    case CACHE(SOME(ENVCACHE(tree)),_) 
      local String s;
      equation
      s = printCacheTreeStr(tree,1); 
      str = Util.stringAppendList({"Cache:\n",s,"\n"});
      then str;
    case CACHE(NONE,_) then "EMPTY CACHE";
  end matchcontinue;
end printCacheStr;

protected function printCacheTreeStr
	input CacheTree tree;
	input Integer indent;
  output String str;
algorithm
	str:= matchcontinue(tree,indent)
	local Ident id;
	  list<CacheTree> children;
	  case (CACHETREE(id,_,children),indent) 
	    local
	      String s,s1;
	    equation
	      s = Util.stringDelimitList(Util.listMap1(children,printCacheTreeStr,indent+1),"\n");
	    	s1 = Util.stringAppendList(Util.listFill(" ",indent));
	    	str = Util.stringAppendList({s1,id,"\n",s});
	    then str;
	end matchcontinue;
end printCacheTreeStr;
public function localOutsideConnectorFlowvars "function: localOutsideConnectorFlowvars
 
  Return the outside connector variables that are flow in the local scope.
"
  input Env inEnv;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inEnv)
    local
      list<Exp.ComponentRef> res;
      Option<Ident> sid;
      BinTree ht;
    case ((FRAME(class_1 = sid,list_2 = ht) :: _))
      equation 
        res = localOutsideConnectorFlowvars2(SOME(ht));
      then
        res;
  end matchcontinue;
end localOutsideConnectorFlowvars;

protected function localOutsideConnectorFlowvars2 "function: localOutsideConnectorFlowvars2
 
  Helper function to local_outside_connector_flowvars
"
  input Option<BinTree> inBinTreeOption;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inBinTreeOption)
    local
      list<Exp.ComponentRef> lst1,lst2,lst3,res;
      Ident id;
      list<Types.Var> vars;
      Option<BinTree> l,r;
    case (NONE) then {}; 
    case (SOME(TREENODE(SOME(TREEVALUE(_,VAR(Types.VAR(id,_,_,(Types.T_COMPLEX(ClassInf.CONNECTOR(_),vars,_),_),_),_,_,_))),l,r)))
      equation 
        lst1 = localOutsideConnectorFlowvars2(l);
        lst2 = localOutsideConnectorFlowvars2(r);
        lst3 = Types.flowVariables(vars, Exp.CREF_IDENT(id,{}));
        res = Util.listFlatten({lst1,lst2,lst3});
      then
        res;
    case (SOME(TREENODE(SOME(_),l,r)))
      equation 
        lst1 = localOutsideConnectorFlowvars2(l);
        lst2 = localOutsideConnectorFlowvars2(r);
        res = listAppend(lst1, lst2);
      then
        res;
  end matchcontinue;
end localOutsideConnectorFlowvars2;

public function localInsideConnectorFlowvars "function: localInsideConnectorFlowvars
 
  Returns the inside connector variables that are flow from the local scope.
"
  input Env inEnv;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inEnv)
    local
      list<Exp.ComponentRef> res;
      Option<Ident> sid;
      BinTree ht;
    case ((FRAME(class_1 = sid,list_2 = ht) :: _))
      equation 
        res = localInsideConnectorFlowvars2(SOME(ht));
      then
        res;
  end matchcontinue;
end localInsideConnectorFlowvars;

protected function localInsideConnectorFlowvars2 "function: localInsideConnectorFlowvars2
  
  Helper function to local_inside_connector_flowvars
"
  input Option<BinTree> inBinTreeOption;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inBinTreeOption)
    local
      list<Exp.ComponentRef> lst1,lst2,res,lst3;
      Ident id;
      Option<BinTree> l,r;
      list<Types.Var> vars;
      tuple<Types.TType, Option<Absyn.Path>> t;
    case (NONE) then {}; 
    case (SOME(TREENODE(SOME(TREEVALUE(_,VAR(Types.VAR(id,_,_,(Types.T_COMPLEX(ClassInf.CONNECTOR(_),_,_),_),_),_,_,_))),l,r))) /* If CONNECTOR then  outside and not inside, skip.. */ 
      equation 
        lst1 = localInsideConnectorFlowvars2(l);
        lst2 = localInsideConnectorFlowvars2(r);
        res = listAppend(lst1, lst2);
      then
        res;
    case (SOME(TREENODE(SOME(TREEVALUE(_,VAR(Types.VAR(id,_,_,(Types.T_COMPLEX(_,vars,_),_),_),_,_,_))),l,r))) /* ... else retrieve connectors as subcomponents */ 
      equation 
        lst1 = localInsideConnectorFlowvars3(vars, id);
        lst2 = localInsideConnectorFlowvars2(l);
        lst3 = localInsideConnectorFlowvars2(r);
        res = Util.listFlatten({lst1,lst2,lst3});
      then
        res;
    case (SOME(TREENODE(SOME(TREEVALUE(_,VAR(Types.VAR(id,_,_,t,_),_,_,_))),l,r))) /* if not complex, skip */ 
      equation 
        lst1 = localInsideConnectorFlowvars2(l);
        lst2 = localInsideConnectorFlowvars2(r);
        res = listAppend(lst1, lst2);
      then
        res;
  end matchcontinue;
end localInsideConnectorFlowvars2;

protected function localInsideConnectorFlowvars3 "function: localInsideConnectorFlowvars3
 
  Helper function to local_inside_connector_flowvars2
"
  input list<Types.Var> inTypesVarLst;
  input Ident inIdent;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inTypesVarLst,inIdent)
    local
      list<Exp.ComponentRef> lst1,lst2,res;
      Ident id,oid;
      list<Types.Var> vars,xs;
    case ({},_) then {}; 
    case ((Types.VAR(name = id,type_ = (Types.T_COMPLEX(complexClassType = ClassInf.CONNECTOR(string = _),complexVarLst = vars),_)) :: xs),oid)
      equation 
        lst1 = localInsideConnectorFlowvars3(xs, oid);
        lst2 = Types.flowVariables(vars, Exp.CREF_QUAL(oid,{},Exp.CREF_IDENT(id,{})));
        res = listAppend(lst1, lst2);
      then
        res;
    case ((_ :: xs),oid)
      equation 
        res = localInsideConnectorFlowvars3(xs, oid);
      then
        res;
  end matchcontinue;
end localInsideConnectorFlowvars3;

public function treeGet "function: treeGet
 
  Get a value from the binary tree given a key.
"
  input BinTree inBinTree;
  input Key inKey;
  input FuncTypeKeyToInteger inFuncTypeKeyToInteger;
  output Value outValue;
  partial function FuncTypeKeyToInteger
    input Key inKey;
    output Integer outInteger;
  end FuncTypeKeyToInteger;
algorithm 
  outValue:=
  matchcontinue (inBinTree,inKey,inFuncTypeKeyToInteger)
    local
      partial function FuncTypeStringToInteger
        input String inString;
        output Integer outInteger;
      end FuncTypeStringToInteger;
      Ident rkey,key;
      Value rval,res;
      Option<BinTree> left,right;
      FuncTypeStringToInteger hashfunc;
      Integer hval,rhval;
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),left = left,right = right),key,hashfunc) /* hash func Search to the right */ 
      equation 
        equality(rkey = key);
      then
        rval;
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),left = left,right = SOME(right)),key,hashfunc) /* Search to the right */ 
      local BinTree right;
      equation 
        hval = hashfunc(key);
        rhval = hashfunc(rkey);
        (hval > rhval) = true;
        res = treeGet(right, key, hashfunc);
      then
        res;
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),left = SOME(left),right = right),key,hashfunc) /* Search to the left */ 
      local BinTree left;
      equation 
        hval = hashfunc(key);
        rhval = hashfunc(rkey);
        (hval <= rhval) = true;
        res = treeGet(left, key, hashfunc);
      then
        res;
  end matchcontinue;
end treeGet;

protected function printBintreeStr "function: printBintreeStr
 
  Prints the binary tree to a string
"
  input BinTree inBinTree;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inBinTree)
    local
      Ident s1,s2,s3,res,rkey;
      Value rval;
      Option<BinTree> l,r;
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),left = l,right = r))
      equation 
        s1 = printFrameElementStr((rkey,rval));
        s2 = Dump.getOptionStr(l, printBintreeStr);
        s3 = Dump.getOptionStr(r, printBintreeStr);
        res = Util.stringAppendList({s2,s1,s3});
      then
        res;
    case (TREENODE(value = NONE,left = l,right = r))
      equation 
        s2 = Dump.getOptionStr(l, printBintreeStr);
        s3 = Dump.getOptionStr(r, printBintreeStr);
        res = stringAppend(s2, s3);
      then
        res;
  end matchcontinue;
end printBintreeStr;
end Env;

