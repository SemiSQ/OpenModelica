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

package Env
"
  file:	       Env.mo
  package:     Env
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
  uniform lookup mechanism "

// public imports
public import Absyn;
public import ClassInf;
public import DAE;
public import SCode;

public type Ident = String " An identifier is just a string " ;
public type Env = list<Frame> "an environment is a list of frames";

public uniontype Cache
  record CACHE
    array<Option<EnvCache>> envCache "The cache contains of environments from which classes can be found";
    Option<Env> initialEnv "and the initial environment";
    array<DAE.FunctionTree> functions "set of Option<DAE.Function>; NONE() means instantiation started; SOME() means it's finished";
  end CACHE;
end Cache;

public uniontype EnvCache
 record ENVCACHE
   "Cache for environments. The cache consists of a tree
    of environments from which lookupcan be performed."
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

type CSetsType = tuple<list<DAE.ComponentRef>,DAE.ComponentRef>;

public uniontype ScopeType
  record FUNCTION_SCOPE end FUNCTION_SCOPE;
  record CLASS_SCOPE end CLASS_SCOPE;
end ScopeType;

public
uniontype Frame
  record FRAME
    Option<Ident>       optName           "Optional class name";
    Option<ScopeType>   optType           "Optional scope type"; 
    AvlTree             clsAndVars        "List of uniquely named classes and variables";
    AvlTree             types             "List of types, which DOES NOT need to be uniquely named, eg. size may have several types";
    list<Item>          imports           "list of unnamed items (imports)";
    CSetsType           connectionSet     "current connection set crefs";
    Boolean             isEncapsulated    "encapsulated bool=true means that FRAME is created due to encapsulated class";
    list<SCode.Element> defineUnits "list of units defined in the frame";
  end FRAME;
end Frame;

public uniontype InstStatus
"Used to distinguish between different phases of the instantiation of a component
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
    DAE.Var instantiated "instantiated component" ;
    Option<tuple<SCode.Element, DAE.Mod>> declaration "declaration if not fully instantiated.";
    InstStatus instStatus "if it untyped, typed or fully instantiated (dae)";
    Env env "The environment of the instantiated component. Contains e.g. all sub components";    
  end VAR;

  record CLASS
    SCode.Class class_;
    Env env;
  end CLASS;

  record TYPE
    list<DAE.Type> list_ "list since several types with the same name can exist in the same scope (overloading)" ;
  end TYPE;

  record IMPORT
    Absyn.Import import_;
  end IMPORT;

end Item;

// protected imports
protected import ComponentReference;
protected import DAEDump;
protected import DAEUtil;
protected import Debug;
protected import Dump;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import Print;
protected import Util;
protected import Types;
protected import OptManager;
protected import RTOpts;

public constant Env emptyEnv={} "- Values" ;

public function emptyCache
"returns an empty cache"
  output Cache cache;
 protected
  array<Option<EnvCache>> arr;
  array<DAE.FunctionTree> instFuncs;
algorithm
  //print("EMPTYCACHE\n");
  arr := listArray({NONE()});
  instFuncs := arrayCreate(1, DAEUtil.emptyFuncTree);
  cache := CACHE(arr,NONE(),instFuncs);
end emptyCache;

public constant String forScopeName="$for loop scope$" "a unique scope used in for equations";
public constant String forIterScopeName="$foriter loop scope$" "a unique scope used in for iterators";
public constant String matchScopeName="$match scope$" "a unique scope used by match expressions";
public constant String caseScopeName="$case scope$" "a unique scope used by match expressions; to be removed when local decls are deprecated";
public constant list<String> implicitScopeNames={forScopeName,forIterScopeName,matchScopeName,caseScopeName};

// functions for dealing with the environment

public function newEnvironment
  "Creates a new empty environment."
  output Env newEnv;
algorithm
  newEnv := Util.listCreate(newFrame(false,NONE(),NONE()));
end newEnvironment;

protected function newFrame "function: newFrame
  This function creates a new frame, which includes setting up the
  hashtable for the frame."
  input Boolean enc;
  input Option<Ident> inName;
  input Option<ScopeType> inType;
  output Frame outFrame;
protected
  AvlTree httypes;
  AvlTree ht;
  DAE.ComponentRef cref_;
algorithm
  ht := avlTreeNew();
  httypes := avlTreeNew();
  cref_ := ComponentReference.makeCrefIdent("",DAE.ET_OTHER(),{});
  outFrame := FRAME(inName,inType,ht,httypes,{},({},cref_),enc,{});
end newFrame;

public function isTyped "
Author BZ 2008-06
This function checks wheter an InstStatus is typed or not.
Currently used by Inst.updateComponentsInEnv."
  input InstStatus is;
  output Boolean b;
algorithm 
  b := matchcontinue(is)
    case(VAR_UNTYPED()) then false;
    case(_) then true;
  end matchcontinue;
end isTyped;

public function openScope "function: openScope
  Opening a new scope in the environment means adding a new frame on
  top of the stack of frames. If the scope is not the top scope a classname
  of the scope should be provided such that a name for the scope can be
  derived, see nameScope."
  input Env inEnv;
  input Boolean inBoolean;
  input Option<Ident> inIdentOption;
  input Option<ScopeType> inTypeOption;
  output Env outEnv;
protected
  Frame f;
algorithm
  f := newFrame(inBoolean, inIdentOption, inTypeOption);
  outEnv := f :: inEnv;
end openScope;

public function inForLoopScope "returns true if environment has a frame that is a for loop"
  input Env env;
  output Boolean res;
algorithm
  res := matchcontinue(env)
    local String name;
    
    case(FRAME(optName = SOME(name))::_) 
      equation
        true = stringEq(name, forScopeName);
      then true;
    
    case(_) then false;
  end matchcontinue;
end inForLoopScope;

public function inForIterLoopScope "returns true if environment has a frame that is a for iterator 'loop'"
  input Env env;
  output Boolean res;
algorithm
  res := matchcontinue(env)
    local String name;
    
    case(FRAME(optName = SOME(name))::_) 
      equation
        true = stringEq(name, forIterScopeName);
      then true;
    
    case(_) then false;
  end matchcontinue;
end inForIterLoopScope;

public function stripForLoopScope "strips for loop scopes"
  input Env env;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(env)
    local String name;
    case(FRAME(optName = SOME(name))::env) 
      equation
        true = stringEq(name, forScopeName);
        env = stripForLoopScope(env);
      then env;
    case(env) then env;
  end matchcontinue;
end stripForLoopScope;

public function getScopeName "function: getScopeName
 Returns the name of a scope, if no name exist, the function fails."
  input Env inEnv;
  output Ident name;
algorithm
  name:= match (inEnv)
    case ((FRAME(optName = SOME(name))::_)) then (name);
  end match;
end getScopeName;

public function getScopeNames "function: getScopeName
 Returns the name of a scope, if no name exist, the function fails."
  input Env inEnv;
  output list<Ident> names;
algorithm 
  names := matchcontinue (inEnv)
    local String name;
    
    // empty list 
    case ({}) then {};
    // frame with a name
    case ((FRAME(optName = SOME(name))::inEnv))
      equation
        names = getScopeNames(inEnv);
      then
        name::names;
    // frame without a name
    case ((FRAME(optName = NONE())::inEnv))
      equation
        names = getScopeNames(inEnv);
      then
        "-NONAME-"::names;
  end matchcontinue;
end getScopeNames;

public function updateEnvClasses "Updates the classes of the top frame on the env passed as argument to the environment
passed as second argument"
  input Env env;
  input Env classEnv;
  output Env outEnv;
algorithm
  outEnv := match(env,classEnv)
    local 
      Option<Ident> optName;
      Option<ScopeType> st;
      AvlTree clsAndVars, types ;
      list<Item> imports;
      list<Frame> fs;
      tuple<list<DAE.ComponentRef>,DAE.ComponentRef> crefs;
      Boolean enc;
      list<SCode.Element> defineUnits;

    case(FRAME(optName,st,clsAndVars,types,imports,crefs,enc,defineUnits)::fs,classEnv)
      equation
        clsAndVars = updateEnvClassesInTree(clsAndVars,classEnv);
      then 
        FRAME(optName,st,clsAndVars,types,imports,crefs,enc,defineUnits)::fs;
  end match;
end updateEnvClasses;

protected function updateEnvClassesInTree "Help function to updateEnvClasses"
  input AvlTree tree;
  input Env classEnv;
  output AvlTree outTree;
algorithm
  outTree := matchcontinue(tree,classEnv)
    local
      SCode.Class cl;
      Option<AvlTree> l,r;
      AvlKey k;
      Env env;
      Item item;
      Integer h;
   // Classes
   case(AVLTREENODE(SOME(AVLTREEVALUE(k,CLASS(cl,env))),h,l,r),classEnv) equation
      l = updateEnvClassesInTreeOpt(l,classEnv);
      r = updateEnvClassesInTreeOpt(r,classEnv);
   then AVLTREENODE(SOME(AVLTREEVALUE(k,CLASS(cl,classEnv))),h,l,r);

   // Other items
   case(AVLTREENODE(SOME(AVLTREEVALUE(k,item)),h,l,r),classEnv) equation
      l = updateEnvClassesInTreeOpt(l,classEnv);
      r = updateEnvClassesInTreeOpt(r,classEnv);
   then AVLTREENODE(SOME(AVLTREEVALUE(k,item)),h,l,r);

   // nothing
   case(AVLTREENODE(NONE(),h,l,r),classEnv) equation
      l = updateEnvClassesInTreeOpt(l,classEnv);
      r = updateEnvClassesInTreeOpt(r,classEnv);
   then AVLTREENODE(NONE(),h,l,r);
  end matchcontinue;
end updateEnvClassesInTree;

protected function updateEnvClassesInTreeOpt "Help function to updateEnvClassesInTree"
  input Option<AvlTree> tree;
  input Env classEnv;
  output Option<AvlTree> outTree;
algorithm
  outTree := match(tree,classEnv)
  local AvlTree t;
    case(NONE(),classEnv) then NONE();
    case(SOME(t),classEnv) equation
      t = updateEnvClassesInTree(t,classEnv);
    then SOME(t);
  end match;
end updateEnvClassesInTreeOpt;

public function extendFrameC "function: extendFrameC
  This function adds a class definition to the environment."
  input Env inEnv;
  input SCode.Class inClass;
  output Env outEnv;
algorithm
  outEnv := matchcontinue (inEnv,inClass)
    local
      AvlTree httypes;
      AvlTree ht,ht_1;
      Env env,fs;
      Option<Ident> id;
      Option<ScopeType> st;
      list<AvlValue> imps;
      tuple<list<DAE.ComponentRef>,DAE.ComponentRef> crs;
      Boolean encflag;
      SCode.Class c;
      Ident n;
      list<SCode.Element> defineUnits;

    case ((env as (FRAME(id,st,ht,httypes,imps,crs,encflag,defineUnits) :: fs)),(c as SCode.CLASS(name = n)))
      equation
        (ht_1) = avlTreeAdd(ht, n, CLASS(c,env));
      then
        (FRAME(id,st,ht_1,httypes,imps,crs,encflag,defineUnits) :: fs);

    case (_,_)
      equation
        print("- Env.extendFrameC FAILED\n");
      then
        fail();
  end matchcontinue;
end extendFrameC;

public function extendFrameClasses "function: extendFrameClasses
  Adds all clases in a Program to the environment."
  input Env inEnv;
  input SCode.Program inProgram;
  output Env outEnv;
algorithm
  outEnv := match (inEnv,inProgram)
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
  end match;
end extendFrameClasses;

public function removeComponentsFromFrameV "function: removeComponentsFromFrameV
  This function removes all components from frame."
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match (inEnv)
    local
      AvlTree httypes;
      AvlTree ht;
      Option<Ident> id;
      Option<ScopeType> st;
      list<AvlValue> imps;
      Env fs,env,remember;
      tuple<list<DAE.ComponentRef>,DAE.ComponentRef> crs;
      Boolean encflag;
      InstStatus i;
      DAE.Var v;
      Ident n;
      Option<tuple<SCode.Element, DAE.Mod>> c;
      list<SCode.Element> defineUnits;

    case ((FRAME(id,st,_,httypes,imps,crs,encflag,defineUnits) :: fs))
      equation
        // make an empty component env!
        ht = avlTreeNew();
      then
        (FRAME(id,st,ht,httypes,imps,crs,encflag,defineUnits) :: fs);
  end match;
end removeComponentsFromFrameV;

public function extendFrameV "function: extendFrameV
  This function adds a component to the environment."
  input Env inEnv1;
  input DAE.Var inVar2;
  input Option<tuple<SCode.Element, DAE.Mod>> inTplSCodeElementTypesModOption3;
  input InstStatus instStatus;
  input Env inEnv5;
  output Env outEnv;
algorithm
  outEnv := matchcontinue (inEnv1,inVar2,inTplSCodeElementTypesModOption3,instStatus,inEnv5)
    local
      AvlTree httypes;
      AvlTree ht,ht_1;
      Option<Ident> id;
      Option<ScopeType> st;
      list<AvlValue> imps;
      Env fs,env,remember;
      tuple<list<DAE.ComponentRef>,DAE.ComponentRef> crs;
      Boolean encflag;
      InstStatus i;
      DAE.Var v;
      Ident n;
      Option<tuple<SCode.Element, DAE.Mod>> c;
      list<SCode.Element> defineUnits;

    case ((FRAME(id,st,ht,httypes,imps,crs,encflag,defineUnits) :: fs),(v as DAE.TYPES_VAR(name = n)),c,i,env) /* environment of component */
      equation
        //failure((_)= avlTreeGet(ht, n));
        (ht_1) = avlTreeAdd(ht, n, VAR(v,c,i,env));
      then
        (FRAME(id,st,ht_1,httypes,imps,crs,encflag,defineUnits) :: fs);

    // Variable already added, perhaps from baseclass
    case (remember as (FRAME(id,st,ht,httypes,imps,crs,encflag,defineUnits) :: fs),
          (v as DAE.TYPES_VAR(name = n)),c,i,env) /* environment of component */
      equation
        (_)= avlTreeGet(ht, n);
      then
        (remember);
  end matchcontinue;
end extendFrameV;

public function updateFrameV "function: updateFrameV
  This function updates a component already added to the environment, but
  that prior to the update did not have any binding. I.e this function is
  called in the second stage of instantiation with declare before use."
  input Env inEnv1;
  input DAE.Var inVar2;
  input InstStatus instStatus;
  input Env inEnv4;
  output Env outEnv;
algorithm
  outEnv := matchcontinue (inEnv1,inVar2,instStatus,inEnv4)
    local
      Boolean encflag;
      InstStatus i;
      Option<tuple<SCode.Element, DAE.Mod>> c;
      AvlTree httypes;
      AvlTree ht,ht_1;
      Option<Ident> sid;
      Option<ScopeType> st;
      list<AvlValue> imps;
      Env fs,env,frames;
      tuple<list<DAE.ComponentRef>,DAE.ComponentRef> crs;
      DAE.Var v;
      Ident n,id;
      list<SCode.Element> defineUnits;

    case ({},_,i,_) then {};  /* fully instantiated env of component */
    case ((FRAME(sid,st,ht,httypes,imps,crs,encflag,defineUnits) :: fs),(v as DAE.TYPES_VAR(name = n)),i,env)
      equation
        VAR(_,c,_,_) = avlTreeGet(ht, n);
        (ht_1) = avlTreeAdd(ht, n, VAR(v,c,i,env));
      then
        (FRAME(sid,st,ht_1,httypes,imps,crs,encflag,defineUnits) :: fs);
    case ((FRAME(sid,st,ht,httypes,imps,crs,encflag,defineUnits) :: fs),(v as DAE.TYPES_VAR(name = n)),i,env) /* Also check frames above, e.g. when variable is in base class */
      equation
        frames = updateFrameV(fs, v, i, env);
      then
        (FRAME(sid,st,ht,httypes,imps,crs,encflag,defineUnits) :: frames);
    case ((FRAME(sid,st,ht, httypes,imps,crs,encflag,defineUnits) :: fs),DAE.TYPES_VAR(name = n),_,_)
      equation
        /*Print.printBuf("- update_frame_v, variable ");
        Print.printBuf(n);
        Print.printBuf(" not found\n rest of env:");
        printEnv(fs);
        Print.printBuf("\n");*/
      then
        (FRAME(sid,st,ht,httypes,imps,crs,encflag,defineUnits) :: fs);
    case (_,(v as DAE.TYPES_VAR(name = id)),_,_)
      equation
        print("- update_frame_v failed\n");
        print("  - variable: ");
        print(Types.printVarStr(v));
        print("\n");
      then
        fail();
  end matchcontinue;
end updateFrameV;

public function extendFrameT "function: extendFrameT
  This function adds a type to the environment.  Types in the
  environment are used for looking up constants etc. inside class
  definitions, such as packages.  For each type in the environment,
  there is a class definition with the same name in the
  environment."
  input Env inEnv;
  input Ident inIdent;
  input DAE.Type inType;
  output Env outEnv;
algorithm
  outEnv := matchcontinue (inEnv,inIdent,inType)
    local
      list<tuple<DAE.TType, Option<Absyn.Path>>> tps;
      AvlTree httypes_1,httypes;
      AvlTree ht;
      Option<Ident> sid;
      Option<ScopeType> st;
      list<AvlValue> imps;
      Env fs;
      tuple<list<DAE.ComponentRef>,DAE.ComponentRef> crs;
      Boolean encflag;
      Ident n;
      tuple<DAE.TType, Option<Absyn.Path>> t;
      list<SCode.Element> defineUnits;

    case ((FRAME(sid,st,ht,httypes,imps,crs,encflag,defineUnits) :: fs),n,t)
      equation
        TYPE(tps) = avlTreeGet(httypes, n) "Other types with that name allready exist, add this type as well" ;
        (httypes_1) = avlTreeAdd(httypes, n, TYPE((t :: tps)));
      then
        (FRAME(sid,st,ht,httypes_1,imps,crs,encflag,defineUnits) :: fs);
    case ((FRAME(sid,st,ht,httypes,imps,crs,encflag,defineUnits) :: fs),n,t)
      equation
        failure(TYPE(_) = avlTreeGet(httypes, n)) "No other types exists" ;
        (httypes_1) = avlTreeAdd(httypes, n, TYPE({t}));
      then
        (FRAME(sid,st,ht,httypes_1,imps,crs,encflag,defineUnits) :: fs);
  end matchcontinue;
end extendFrameT;

public function extendFrameI "function: extendFrameI
  Adds an import statement to the environment."
  input Env inEnv;
  input Absyn.Import inImport;
  output Env outEnv;
algorithm
  outEnv := matchcontinue (inEnv,inImport)
    local
      Option<Ident> sid;
      Option<ScopeType> st;
      AvlTree httypes;
      AvlTree ht;
      list<AvlValue> imps;
      tuple<list<DAE.ComponentRef>,DAE.ComponentRef> crs;
      Boolean encflag;
      Absyn.Import imp;
      Env fs,env;
      list<SCode.Element> defineUnits;

    case ((FRAME(sid,st,ht,httypes,imps,crs,encflag,defineUnits) :: fs),imp)
      equation
        false = memberImportList(imps,imp);
    then (FRAME(sid,st,ht,httypes,(IMPORT(imp) :: imps),crs,encflag,defineUnits) :: fs);

    case (env,imp) then env;
  end matchcontinue;
end extendFrameI;

public function extendFrameDefunit "
  Adds a defineunit to the environment."
  input Env inEnv;
  input SCode.Element defunit;
  output Env outEnv;
algorithm
  outEnv := match (inEnv,defunit)
    local
      Option<Ident> sid;
      Option<ScopeType> st;
      AvlTree httypes;
      AvlTree ht;
      list<AvlValue> imps;
      tuple<list<DAE.ComponentRef>,DAE.ComponentRef> crs;
      Boolean encflag;
      Env fs;
      list<SCode.Element> defineUnits;

    case ((FRAME(sid,st,ht,httypes,imps,crs,encflag,defineUnits) :: fs),defunit)
    then (FRAME(sid,st,ht,httypes,imps,crs,encflag,defunit::defineUnits) :: fs);
  end match;
end extendFrameDefunit;

public function extendFrameForIterator
	"Adds a for loop iterator to the environment."
	input Env env;
	input String name;
	input DAE.Type type_;
	input DAE.Binding binding;
	input SCode.Variability variability;
	input Option<DAE.Const> constOfForIteratorRange;
	output Env new_env;
algorithm
	new_env := match(env, name, type_, binding, variability, constOfForIteratorRange)
		local
			Env new_env_1;
		case (_, _, _, _,variability,constOfForIteratorRange)
			equation
				new_env_1 = extendFrameV(env,
					DAE.TYPES_VAR(
						name,
						DAE.ATTR(false, false, SCode.RW(), variability, Absyn.BIDIR(), Absyn.UNSPECIFIED()),
						false,
						type_,
						binding,
						constOfForIteratorRange),
					NONE(), VAR_UNTYPED(), {});
			then new_env_1;
	end match;
end extendFrameForIterator;

protected function memberImportList "Returns true if import exist in imps"
	input list<Item> imps;
	input Absyn.Import imp;
  output Boolean res "true if import exist in imps, false otherwise";
algorithm
  res := matchcontinue (imps,imp)
    local
      list<Item> ims;
      Absyn.Import imp2;
    
    // first import in the list matches  
    case (IMPORT(imp2)::ims,imp)
      equation
        true = Absyn.importEqual(imp2, imp);
      then true;
    
    // move to next  
    case (_::ims,imp) 
      equation
        res=memberImportList(ims,imp);
      then res;
    
    // other alternatives 
    case (_,_) then false;
   end matchcontinue;
end memberImportList;

/*
public function addBcFrame "function: addBcFrame
  author: PA
  Adds a baseclass frame to the environment from the baseclass environment
  to the list of base classes of the top frame of the passed environment."
  input Env inEnv1;
  input Env inEnv2;
  output Env outEnv;
algorithm
  outEnv := matchcontinue (inEnv1,inEnv2)
    local
      Option<Ident> sid;
      AvlTree tps;
      AvlTree cls;
      list<AvlValue> imps;
      Env bc,fs;
      tuple<list<DAE.ComponentRef>,DAE.ComponentRef> crefs;
      Boolean enc;
      Frame f;
      list<SCode.Element> defineUnits;

    case ((FRAME(sid,cls,tps,imps,bc,crefs,enc,defineUnits) :: fs),(f :: _))
      then (FRAME(sid,cls,tps,imps,(f :: bc),crefs,enc,defineUnits) :: fs);
  end matchcontinue;
end addBcFrame;
*/

public function topFrame "function: topFrame
  Returns the top frame."
  input Env inEnv;
  output Frame outFrame;
algorithm
  outFrame := match (inEnv)
    local
      Frame fr,elt;
      Env lst;
    case ({fr}) then fr;
    case ((elt :: (lst as (_ :: _))))
      equation
        fr = topFrame(lst);
      then
        fr;
  end match;
end topFrame;

/*
public function enclosingScopeEnv "function: enclosingScopeEnv
@author: adrpo
 Returns the environment with the current scope frame removed."
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := matchcontinue (inEnv)
    local
      Env rest;
    case ({}) then {};
    case (_ :: rest)
      then
        rest;
  end matchcontinue;
end enclosingScopeEnv;
*/

public function getClassName
  input Env inEnv;
  output Ident name;
algorithm
   name := match (inEnv)
   	local Ident n;
   	case FRAME(optName = SOME(n))::_ then n;
  end match;
end getClassName;

public function getEnvName "returns the FQ name of the environment, see also getEnvPath"
input Env env;
output Absyn.Path path;
algorithm
  path := matchcontinue(env)
    case(env) equation
      SOME(path) = getEnvPath(env);
    then path;
    case _
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- Env.getEnvName failed");
        _ = getEnvPath(env);
      then fail();
  end matchcontinue;
end getEnvName;

public function getEnvPath "function: getEnvPath
  This function returns all partially instantiated parents as an Absyn.Path
  option I.e. it collects all identifiers of each frame until it reaches
  the topmost unnamed frame. If the environment is only the topmost frame,
  NONE() is returned."
  input Env inEnv;
  output Option<Absyn.Path> outAbsynPathOption;
algorithm
  outAbsynPathOption := match (inEnv)
    local
      Ident id;
      Absyn.Path path,path_1;
      Env rest;
    case ({FRAME(optName = SOME(id)),FRAME(optName = NONE())}) then SOME(Absyn.IDENT(id));
    case ((FRAME(optName = SOME(id)) :: rest))
      equation
        SOME(path) = getEnvPath(rest);
        path_1 = Absyn.joinPaths(path, Absyn.IDENT(id));
      then
        SOME(path_1);
    else NONE();
  end match;
end getEnvPath;

public function getEnvPathNoImplicitScope "function: getEnvPath
  This function returns all partially instantiated parents as an Absyn.Path
  option I.e. it collects all identifiers of each frame until it reaches
  the topmost unnamed frame. If the environment is only the topmost frame,
  NONE() is returned."
  input Env inEnv;
  output Option<Absyn.Path> outAbsynPathOption;
algorithm
  outAbsynPathOption := matchcontinue (inEnv)
    local
      Ident id;
      Absyn.Path path,path_1;
      Env rest;
    case ((FRAME(optName = SOME(id)) :: rest))
      equation
        true = listMember(id,implicitScopeNames);
      then getEnvPathNoImplicitScope(rest);
    case ((FRAME(optName = SOME(id)) :: rest))
      equation
        false = listMember(id,implicitScopeNames);
        SOME(path) = getEnvPathNoImplicitScope(rest);
        path_1 = Absyn.joinPaths(path, Absyn.IDENT(id));
      then
        SOME(path_1);
    case (FRAME(optName = SOME(id))::rest)
      equation
        false = listMember(id,implicitScopeNames);
        NONE() = getEnvPathNoImplicitScope(rest);
      then SOME(Absyn.IDENT(id));
    case (_) then NONE();
  end matchcontinue;
end getEnvPathNoImplicitScope;

public function joinEnvPath "function: joinEnvPath
  Used to join an Env with an Absyn.Path (probably an IDENT)"
  input Env inEnv;
  input Absyn.Path inPath;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue(inEnv,inPath)
    local
      Absyn.Path envPath;
    case (inEnv,inPath)
      equation
        SOME(envPath) = getEnvPath(inEnv);
        envPath = Absyn.joinPaths(envPath,inPath);
      then envPath;
    case (inEnv,inPath)
      equation
        NONE() = getEnvPath(inEnv);
      then inPath;
  end matchcontinue;
end joinEnvPath;

public function printEnvPathStr "function: printEnvPathStr
 Retrive the environment path as a string, see getEnvPath."
  input Env inEnv;
  output String outString;
algorithm
  outString := matchcontinue (inEnv)
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
  See also getEnvPath"
  input Env inEnv;
algorithm
  _ := matchcontinue (inEnv)
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
  Print the environment as a string."
  input Env inEnv;
  output String outString;
algorithm
  outString := match (inEnv)
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
  end match;
end printEnvStr;

public function printEnv "function: printEnv
  Print the environment to the Print buffer."
  input Env e;
  Ident s;
algorithm
  s := printEnvStr(e);
  Print.printBuf(s);
end printEnv;

public function printEnvConnectionCrefs "prints the connection crefs of the top frame"
  input Env env;
algorithm
  _ := matchcontinue(env)
    local
      list<DAE.ComponentRef> crs;
      Env env;
    case(env as (FRAME(connectionSet = (crs,_))::_)) equation
      print(printEnvPathStr(env));print(" :   ");
      print(Util.stringDelimitList(Util.listMap(crs,ComponentReference.printComponentRefStr),", "));
      print("\n");
    then ();
  end matchcontinue;
end printEnvConnectionCrefs;

protected function printFrameStr "function: printFrameStr
  Print a Frame to a string."
  input Frame inFrame;
  output String outString;
algorithm
  outString := match (inFrame)
    local
      Ident s1,s2,s3,encflag_str,res,sid;
      Option<Ident> optName;
      list<Ident> bcstrings;
      AvlTree httypes;
      AvlTree ht;
      list<AvlValue> imps;
      tuple<list<DAE.ComponentRef>,DAE.ComponentRef> crs;
      Boolean encflag;
    case FRAME(optName = optName,clsAndVars = ht,types = httypes,imports = imps,connectionSet = crs,isEncapsulated = encflag)
      equation
        sid = Util.getOptionOrDefault(optName, "unnamed");
        s1 = printAvlTreeStr(ht);
        s2 = printAvlTreeStr(httypes);
        s3 = printImportsStr(imps);
        encflag_str = boolString(encflag);
        res = stringAppendList(
          "FRAME: " :: sid :: " (enc=" :: encflag_str ::
          ") \nclasses and vars:\n=============\n" :: s1 :: "   Types:\n======\n" :: s2 :: "   Imports:\n=======\n" :: s3 :: {});
      then
        res;
  end match;
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
      AvlTree httypes;
      AvlTree ht;
      list<AvlValue> imps;
      tuple<list<DAE.ComponentRef>,DAE.ComponentRef> crs;
      Boolean encflag;
    case FRAME(optName = SOME(sid),clsAndVars = ht,types = httypes,imports = imps,connectionSet = crs,isEncapsulated = encflag)
      equation
        s1 = printAvlTreeStr(ht);
        encflag_str = boolString(encflag);
        res = stringAppendList(
          {"FRAME: ",sid," (enc=",encflag_str,
          ") \nclasses and vars:\n=============\n",s1,"\n\n\n"});
      then
        res;
    case FRAME(optName = NONE(),clsAndVars = ht,types = httypes,imports = imps,connectionSet = crs,isEncapsulated = encflag)
      equation
        s1 = printAvlTreeStr(ht);
        encflag_str = boolString(encflag);
        res = stringAppendList(
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
      AvlValue e;
      list<AvlValue> rst;
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
        res = stringAppendList({s1,", ",s2});
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
  match (inTplIdentItem)
    local
      Ident s,elt_str,tp_str,var_str,frame_str,bind_str,res,n,lenstr;
      DAE.Var tv;
      SCode.Variability var;
      tuple<DAE.TType, Option<Absyn.Path>> tp;
      DAE.Binding bind,bnd;
      SCode.Element elt;
      InstStatus i;
      Frame compframe;
      Env env;
      Integer len;
      list<tuple<DAE.TType, Option<Absyn.Path>>> lst;
      Absyn.Import imp;
    case ((n,VAR(instantiated = (tv as DAE.TYPES_VAR(attributes = DAE.ATTR(parameter_ = var),type_ = tp,binding = bind)),declaration = SOME((elt,_)),instStatus = i,env = (compframe :: _))))
      equation
        s = SCode.variabilityString(var);
        elt_str = SCode.printElementStr(elt);
        tp_str = Types.unparseType(tp);
        var_str = Types.unparseVar(tv);
        frame_str = printFrameVarsStr(compframe);
        bind_str = Types.printBindingStr(bind);
        res = stringAppendList(
          {"v:",n," ",s,"(",elt_str,") [",tp_str,"] {",var_str,
          "}, binding:",bind_str});
      then
        res;
    case ((n,VAR(instantiated = (tv as DAE.TYPES_VAR(attributes = DAE.ATTR(parameter_ = var),type_ = tp)),declaration = SOME((elt,_)),instStatus = i,env = {})))
      equation
        s = SCode.variabilityString(var);
        elt_str = SCode.printElementStr(elt);
        tp_str = Types.unparseType(tp);
        var_str = Types.unparseVar(tv);
        res = stringAppendList(
          {"v:",n," ",s,"(",elt_str,") [",tp_str,"] {",var_str,
          "}, compframe: []"});
      then
        res;
    case ((n,VAR(instantiated = DAE.TYPES_VAR(binding = bnd),declaration = NONE(),instStatus = i,env = env)))
      equation
        res = stringAppendList({"v:",n,"\n"});
      then
        res;
    case ((n,CLASS(class_ = _)))
      equation
        res = stringAppendList({"c:",n,"\n"});
      then
        res;
    case ((n,TYPE(list_ = lst)))
      equation
        len = listLength(lst);
        lenstr = intString(len);
        res = stringAppendList({"t:",n," (",lenstr,")\n"});
      then
        res;
    case ((n,IMPORT(import_ = imp)))
      equation
        s = Dump.unparseImportStr(imp);
        res = stringAppendList({"imp:",s,"\n"});
      then
        res;
  end match;
end printFrameElementStr;

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

public function getCachedInitialEnv "get the initial environment from the cache"
  input Cache cache;
  output Env env;
algorithm
  env := match(cache)
    //case (_) then fail();
    case (CACHE(_,SOME(env),_)) equation
    //	print("getCachedInitialEnv\n");
      then env;
  end match;
end getCachedInitialEnv;

public function setCachedInitialEnv "set the initial environment in the cache"
  input Cache inCache;
  input Env env;
  output Cache outCache;
algorithm
  outCache := match(inCache,env)
  local
    	array<Option<EnvCache>> envCache;
    	array<DAE.FunctionTree> ef;

    case (CACHE(envCache,_,ef),env) equation
 //    	print("setCachedInitialEnv\n");
      then CACHE(envCache,SOME(env),ef);
  end match;
end setCachedInitialEnv;

public function cacheGet "Get an environment from the cache."
  input Absyn.Path scope;
  input Absyn.Path path;
  input Cache cache;
  output Env env;
algorithm
  env:= match (scope,path,cache)
    local
      CacheTree tree;
      array<Option<EnvCache>> arr;
      array<DAE.FunctionTree> ef;
   case (scope,path,CACHE(arr ,_,ef))
      equation
        true = OptManager.getOption("envCache");
        SOME(ENVCACHE(tree)) = arr[1];
        env = cacheGetEnv(scope,path,tree);
        //print("got cached env for ");print(Absyn.pathString(path)); print("\n");
      then env;
  end match;
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
    array<Option<EnvCache>> arr;
    array<DAE.FunctionTree> ef;
    case(_,inCache,env)
      equation
        false = OptManager.getOption("envCache");
      then inCache;

    case (fullpath,CACHE(arr,ie,ef),env)
      equation
        NONE() = arr[1];
        tree = cacheAddEnv(fullpath,CACHETREE("$global",emptyEnv,{}),env);
        //print("Adding ");print(Absyn.pathString(fullpath));print(" to empty cache\n");
        arr = arrayUpdate(arr,1,SOME(ENVCACHE(tree)));
      then CACHE(arr,ie,ef);
    case (fullpath,CACHE(arr,ie,ef),env)
      equation
        SOME(ENVCACHE(tree))=arr[1];
       // print(" about to Adding ");print(Absyn.pathString(fullpath));print(" to cache:\n");
      tree = cacheAddEnv(fullpath,tree,env);

       //print("Adding ");print(Absyn.pathString(fullpath));print(" to cache\n");
        //print(printCacheStr(CACHE(SOME(ENVCACHE(tree)),ie)));
        arr = arrayUpdate(arr,1,SOME(ENVCACHE(tree)));
      then CACHE(arr,ie,ef);
    case (_,_,_)
      equation
        print("cacheAdd failed\n");
      then fail();
  end matchcontinue;
end cacheAdd;

// moved from Inst as is more natural to be here!
public function addCachedEnv
"function: addCachedEnv
  add a new environment in the cache obtaining a new cache"
  input Cache inCache;
  input String id;
  input Env env;
  output Cache outCache;
algorithm
  outCache := matchcontinue(inCache,id,env)
    local
      Absyn.Path path;
      case(inCache,id,env) equation
        false = OptManager.getOption("envCache");
      then inCache;

    case(inCache,id,env)
      equation
        SOME(path) = getEnvPath(env);
        outCache = cacheAdd(path,inCache,env);
      then outCache;

    case(inCache,id,env)
      equation
        // this should be placed in the global environment
        // how do we do that??
        true = RTOpts.debugFlag("env");
        Debug.traceln("<<<< Env.addCachedEnv - failed to add env to cache for: " +& printEnvPathStr(env) +& " [" +& id +& "]");
      then inCache;

  end matchcontinue;
end addCachedEnv;

protected function cacheGetEnv "get an environment from the tree cache."
	input Absyn.Path scope;
	input Absyn.Path path;
	input CacheTree tree;
	output Env env;
algorithm
  env := match(scope,path,tree)
  local
    	Absyn.Path path2;
    	Ident id;
    	list<CacheTree> children;

			// Search only current scope. Since scopes higher up might not be cached, we cannot search upwards.
    case (path2,path,tree)
      equation
        true = OptManager.getOption("envCache");
        env = cacheGetEnv2(path2,path,tree);
        //print("found ");print(Absyn.pathString(path));print(" in cache at scope");
				//print(Absyn.pathString(path2));print("  pathEnv:"+&printEnvPathStr(env)+&"\n");
      then env;
  end match;
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
      Ident id1,id2;
      list<CacheTree> children,children2;
      Absyn.Path path2;
    
	  //	Simple name found in children, search for model from this scope.
    case (Absyn.IDENT(id1),path,CACHETREE(_,_,CACHETREE(id2,env2,children2)::_))
      equation
        true = stringEq(id1, id2);
        //print("found (1) ");print(id); print("\n");
        env = cacheGetEnv3(path,children2);
      then 
        env;
    
    //	Simple name. try next.
    case (scope as Absyn.IDENT(id1),path,CACHETREE(id2,env2,_::children))
      equation
        //print("try next ");print(id);print("\n");
        env = cacheGetEnv2(scope,path,CACHETREE(id2,env2,children));
      then 
        env;

    // for qualified name, found first matching identifier in child
     case (Absyn.QUALIFIED(id1,path2),path,CACHETREE(_,_,CACHETREE(id2,env2,children2)::_))
       equation
         true = stringEq(id1, id2);
         //print("found qualified (1) ");print(id);print("\n");
         env = cacheGetEnv2(path2,path,CACHETREE(id2,env2,children2));
       then env;
     
   // for qualified name, try next.
   /*
   case (Absyn.QUALIFIED(id, path2), path, CACHETREE(id2, env2, _ :: children))
     equation
       env = cacheGetEnv2(Absyn.QUALIFIED(id, path2), path, CACHETREE(id2, env2, children));
     then env;*/
  end matchcontinue;
end cacheGetEnv2;

protected function cacheGetEnv3 "Help function to cacheGetEnv2, searches down in tree for env."
  input Absyn.Path path;
  input list<CacheTree> children;
  output Env env;
algorithm
  env := match (path,children)
    local
      Ident id1, id2;
      Absyn.Path path1,path2;
      list<CacheTree> children1,children2;
      Boolean b;
    
		// found matching simple name
    case (Absyn.IDENT(id1),CACHETREE(id2,env,_)::children)
      then Debug.bcallret2(not stringEq(id1, id2), cacheGetEnv3, path, children, env);
    
    // found matching qualified name
    case (path2 as Absyn.QUALIFIED(id1,path1),CACHETREE(id2,_,children1)::children2)
      equation
        b = stringEq(id1, id2);
        path = Util.if_(b,path1,path2);
        children = Util.if_(b,children1,children2);
      then cacheGetEnv3(path,children);
  end match;
end cacheGetEnv3;

public function cacheAddEnv "Add an environment to the cache"
  input Absyn.Path fullpath "Fully qualified path to the environment";
  input CacheTree tree ;
  input Env env "environment";
  output CacheTree outTree;
algorithm
  outTree := matchcontinue(fullpath,tree,env)
    local
      Ident id1,globalID,id2;
      Absyn.Path path;
      Env globalEnv,oldEnv;
      list<CacheTree> children,children2;
      CacheTree child;

    // simple names already added
    case (Absyn.IDENT(id1),(tree as CACHETREE(globalID,globalEnv,CACHETREE(id2,oldEnv,children)::children2)),env)
      equation
        // print(id);print(" already added\n");
        true = stringEq(id1, id2);
        // shouldn't we replace it?
        // Debug.fprintln("env", ">>>> Env.cacheAdd - already in cache: " +& printEnvPathStr(env));
      then tree;

    // simple names try next
    case (Absyn.IDENT(id1),tree as CACHETREE(globalID,globalEnv,child::children),env)
      equation
        CACHETREE(globalID,globalEnv,children) = cacheAddEnv(Absyn.IDENT(id1),CACHETREE(globalID,globalEnv,children),env);
      then CACHETREE(globalID,globalEnv,child::children);

    // Simple names, not found
    case (Absyn.IDENT(id1),CACHETREE(globalID,globalEnv,{}),env)
      equation
        // Debug.fprintln("env", ">>>> Env.cacheAdd - add to cache: " +& printEnvPathStr(env));
      then CACHETREE(globalID,globalEnv,{CACHETREE(id1,env,{})});

    // Qualified names.
    case (path as Absyn.QUALIFIED(_,_),CACHETREE(globalID,globalEnv,children),env)
      equation
        children=cacheAddEnv2(path,children,env);
      then CACHETREE(globalID,globalEnv,children);

    // failure
    case (path,_,_)
      equation
        print("cacheAddEnv path=");print(Absyn.pathString(path));print(" failed\n");
      then fail();
  end matchcontinue;
end cacheAddEnv;

protected function cacheAddEnv2
  input Absyn.Path path;
  input list<CacheTree> inChildren;
  input Env env;
  output list<CacheTree> outChildren;
algorithm
  outChildren := matchcontinue(path,inChildren,env)
    local
      Ident id1,id2;
      list<CacheTree> children,children2;
      CacheTree child;
      Env env2;

    // qualified name, found matching
    case(Absyn.QUALIFIED(id1,path),CACHETREE(id2,env2,children2)::children,env)
      equation
        true = stringEq(id1, id2);
        children2 = cacheAddEnv2(path,children2,env);
      then CACHETREE(id2,env2,children2)::children;

		// simple name, found matching
    case (Absyn.IDENT(id1),CACHETREE(id2,env2,children2)::children,env)
      equation
        true = stringEq(id1, id2);
        // Debug.fprintln("env", ">>>> Env.cacheAdd - already in cache: " +& printEnvPathStr(env));
        //print("single name, found matching\n");
      then CACHETREE(id2,env2,children2)::children;

    // try next
    case(path,child::children,env)
      equation
        //print("try next\n");
        children = cacheAddEnv2(path,children,env);
      then child::children;
    
    // qualified name no child found, create one.
    case (Absyn.QUALIFIED(id1,path),{},env)
      equation
        children = cacheAddEnv2(path,{},env);
        // Debug.fprintln("env", ">>>> Env.cacheAdd - add to cache: " +& printEnvPathStr(env));
        //print("qualified name no child found, create one.\n");
      then {CACHETREE(id1,emptyEnv,children)};
    
    // simple name no child found, create one.
    case (Absyn.IDENT(id1),{},env)
      equation
        // print("simple name no child found, create one.\n");
        // Debug.fprintln("env", ">>>> Env.cacheAdd - add to cache: " +& printEnvPathStr(env));
      then {CACHETREE(id1,env,{})};
    
    case (_,_,_) equation print("cacheAddEnv2 failed\n"); then fail();
  end matchcontinue;
end cacheAddEnv2;

public function printCacheStr
  input Cache cache;
  output String str;
algorithm
  str := matchcontinue(cache)
    local 
      CacheTree tree;
      array<Option<EnvCache>> arr;
      array<DAE.FunctionTree> ef;
      String s,s2;
    
    // some cache present
    case CACHE(arr,_,ef)
      equation
        SOME(ENVCACHE(tree)) = arr[1];
        s = printCacheTreeStr(tree,1);
        str = stringAppendList({"Cache:\n",s,"\n"});
        s2 = DAEDump.dumpFunctionNamesStr(arrayGet(ef,1));
        str = str +& "\nInstantiated funcs: " +& s2 +&"\n";
      then str;
    // empty cache
    case CACHE(_,_,_) then "EMPTY CACHE\n";
  end matchcontinue;
end printCacheStr;

protected function printCacheTreeStr
	input CacheTree tree;
	input Integer indent;
  output String str;
algorithm
  str:= matchcontinue(tree,indent)
    local 
      Ident id;
      list<CacheTree> children;
      String s,s1;
    
    case (CACHETREE(id,_,children),indent)
      equation
        s = Util.stringDelimitList(Util.listMap1(children,printCacheTreeStr,indent+1),"\n");
        s1 = stringAppendList(Util.listFill(" ",indent));
        str = stringAppendList({s1,id,"\n",s});
	    then str;
	end matchcontinue;
end printCacheTreeStr;

protected function dummyDump "
  Author: BZ, 2009-05
  Debug function, print subscripts."
  input list<DAE.Subscript> subs;
  output String str;
algorithm 
  str := matchcontinue(subs)
    local DAE.Subscript s;
    case(subs)
      equation
        str = " subs: " +& Util.stringDelimitList(Util.listMap(subs,ExpressionDump.printSubscriptStr),", ") +& "\n";
        print(str);
      then
        str;
  end matchcontinue;
end dummyDump;

protected function integer2Subscript "
@author adrpo
 given an integer transform it into an DAE.Subscript"
  input  Integer       index;
  output DAE.Subscript subscript;
algorithm
 subscript := DAE.INDEX(DAE.ICONST(index));
end integer2Subscript;

/* AVL impementation */
public
type AvlKey = String ;
public
type AvlValue = Item;

public function keyStr "prints a key to a string"
input AvlKey k;
output String str;
algorithm
  str := k;
end keyStr;

public function valueStr "prints a Value to a string"
input AvlValue v;
output String str;
algorithm
  str := matchcontinue(v)
    local 
      String name; DAE.Type tp; Absyn.Import imp;
      Absyn.TypeSpec tsp;
      Boolean flowPrefix "flow";
      Boolean streamPrefix "stream";
      SCode.Accessibility accessibility "accessibility";
      SCode.Variability parameter_ "parameter";
      Absyn.Direction direction "direction";
      Absyn.InnerOuter innerOuter "inner, outer,  inner outer or unspecified";      
      
    case(VAR(instantiated=DAE.TYPES_VAR(name=name,attributes=DAE.ATTR(flowPrefix, streamPrefix, accessibility, parameter_, direction, innerOuter),type_=tp))) 
      equation
        str = "var:    " +& name +& " " +& Types.unparseType(tp) +& "("
        +& Types.printTypeStr(tp) +& ")" +& " attr: " +& 
        Util.if_(flowPrefix,"flow", "") +& ", " +&
        Util.if_(streamPrefix,"stream", "") +& ", " +&
        SCode.accessibilityString(accessibility) +& ", " +&
        SCode.variabilityString(parameter_) +& ", " +&
        SCode.innerouterString(innerOuter);
      then str;
    
    case(VAR(declaration = SOME((SCode.COMPONENT(component=name,typeSpec=tsp,innerOuter=innerOuter,attributes=SCode.ATTR(_, flowPrefix, streamPrefix, accessibility, parameter_, direction)), _)))) 
      equation
        str = "var:    " +& name +& " " +& Dump.unparseTypeSpec(tsp) +& " attr: " +& 
        Util.if_(flowPrefix,"flow", "") +& ", " +&
        Util.if_(streamPrefix,"stream", "") +& ", " +&
        SCode.accessibilityString(accessibility) +& ", " +&
        SCode.variabilityString(parameter_) +& ", " +&
        SCode.innerouterString(innerOuter);            
      then str;
    
    case(CLASS(class_=SCode.CLASS(name=name))) 
      equation
        str = "class:  " +& name;
      then str;
    
    case(TYPE(tp::_)) 
      equation
        str = "type:   " +& Types.unparseType(tp);
      then str;
    
    case(IMPORT(imp)) 
      equation
        str = "import: " +& Dump.unparseImportStr(imp);
      then str;
  end matchcontinue;
end valueStr;

/* Generic Code below */
public
uniontype AvlTree "The binary tree data structure
 "
  record AVLTREENODE
    Option<AvlTreeValue> value "Value" ;
    Integer height "heigth of tree, used for balancing";
    Option<AvlTree> left "left subtree" ;
    Option<AvlTree> right "right subtree" ;
  end AVLTREENODE;

end AvlTree;

public
uniontype AvlTreeValue "Each node in the binary tree can have a value associated with it."
  record AVLTREEVALUE
    AvlKey key "Key" ;
    AvlValue value "Value" ;
  end AVLTREEVALUE;

end AvlTreeValue;

public function avlTreeNew "Return an empty tree"
  output AvlTree tree;
algorithm
  tree := AVLTREENODE(NONE(),0,NONE(),NONE());
end avlTreeNew;

public function avlTreeAdd
  "Help function to avlTreeAdd."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match (inAvlTree,inKey,inValue)
    local
      AvlKey key,rkey;
      AvlValue value;
      Option<AvlTree> right;
      Integer h;
      AvlTree bt;
    
    // empty tree
    case (AVLTREENODE(value = NONE(),left = NONE(),right = NONE()),key,value)
    	then AVLTREENODE(SOME(AVLTREEVALUE(key,value)),1,NONE(),NONE());
    
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(key=rkey))),key,value)
      then balance(avlTreeAdd2(inAvlTree,stringCompare(key,rkey),key,value));
    
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Env.avlTreeAdd failed"});
      then fail();
  end match;
end avlTreeAdd;

public function avlTreeAdd2
  "Help function to avlTreeAdd."
  input AvlTree inAvlTree;
  input Integer keyComp "0=get value from current node, 1=search right subtree, -1=search left subtree";
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match (inAvlTree,keyComp,inKey,inValue)
    local
      AvlKey key,rkey;
      AvlValue value;
      Option<AvlTree> left,right;
      Integer h;
      AvlTree t_1,t;
      Option<AvlTreeValue> oval;
    
		// replace this node
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(key=rkey)),height=h,left = left,right = right),0,key,value)
      equation
        // inactive for now, but we should check if we don't replace a class with a var or vice-versa!
        // checkValueReplacementCompatible(rval, value);
      then AVLTREENODE(SOME(AVLTREEVALUE(rkey,value)),h,left,right);
     
    // insert to right
    case (AVLTREENODE(value = oval,height=h,left = left,right = right),1,key,value)
      equation
        t = createEmptyAvlIfNone(right);
        t_1 = avlTreeAdd(t, key, value);
      then AVLTREENODE(oval,h,left,SOME(t_1));
        
    // insert to left subtree
    case (AVLTREENODE(value = oval,height=h,left = left ,right = right),-1,key,value)
      equation
        t = createEmptyAvlIfNone(left);
        t_1 = avlTreeAdd(t, key, value);
      then AVLTREENODE(oval,h,SOME(t_1),right);
  end match;
end avlTreeAdd2;

protected function checkValueReplacementCompatible
"@author: adrpo 2010-10-07
  This function checks if what we replace in the environment 
  is compatible with the value we want to replace with.
  VAR<->VAR OK
  CLASS<->CLASS OK
  TYPE<->TYPE OK
  IMPORT<->IMPORT OK
  All the other replacements will output a warning!"
  input AvlValue val1;
  input AvlValue val2;
algorithm
  _ := match(val1, val2)
    local
      Option<Absyn.Info> aInfo;
      String n1, n2;

    // var can replace var
    case (VAR(instantiated = _), VAR(instantiated = _)) then ();
    // class can replace class
    case (CLASS(class_ = _),     CLASS(class_ = _)) then ();
    // type can replace type
    case (TYPE(list_ = _),       TYPE(list_ = _)) then ();
    // import can replace import
    case (IMPORT(import_ = _),   IMPORT(import_ = _)) then ();
    // anything else is an error!
    case (val1, val2)
      equation
        (n1, n2, aInfo) = getNamesAndInfoFromVal(val1, val2); 
        Error.addMessageOrSourceMessage(Error.COMPONENT_NAME_SAME_AS_TYPE_NAME, {n1,n2}, aInfo);
      then 
        ();
  end match;
end checkValueReplacementCompatible;

protected function getNamesAndInfoFromVal
  input AvlValue val1;
  input AvlValue val2;
  output String name1;
  output String name2;
  output Option<Absyn.Info> info;
algorithm
  (name1, name2, info) := matchcontinue(val1, val2)
    local
      Option<Absyn.Info> aInfo;
      String n1, n2, n;
      Env env;
    
    // var should not be replaced by class!
    case (VAR(declaration = SOME((SCode.COMPONENT(component = n1, info = aInfo), _))), 
          CLASS(class_ = SCode.CLASS(name = n2, info = _), env = env))
      equation
         n = printEnvPathStr(env);
         n2 = n +& "." +& n2;
      then 
        (n1, n2, aInfo);
    
    // class should not be replaced by var!
    case (CLASS(class_ = _), VAR(instantiated = _))
      equation
        // call ourselfs reversed
        (n1, n2, aInfo) = getNamesAndInfoFromVal(val2, val1); 
      then 
        (n1, n2, aInfo);
    
    // anything else that might happen??
    case (val1, val2)
      equation
        n1 = valueStr(val1);
        n2 = valueStr(val2);
      then 
        (n1, n2, NONE());
  end matchcontinue;
end getNamesAndInfoFromVal;

protected function createEmptyAvlIfNone "Help function to AvlTreeAdd2"
  input Option<AvlTree> t;
  output AvlTree outT;
algorithm
  outT := match (t)
    case(NONE()) then AVLTREENODE(NONE(),0,NONE(),NONE());
    case(SOME(outT)) then outT;
  end match;
end createEmptyAvlIfNone;

protected function nodeValue "return the node value"
  input AvlTree bt;
  output AvlValue v;
algorithm
  v := match (bt)
    case(AVLTREENODE(value=SOME(AVLTREEVALUE(_,v)))) then v;
  end match;
end nodeValue;

protected function balance "Balances a AvlTree"
  input AvlTree bt;
  output AvlTree outBt;
algorithm
  outBt := match (bt)
  local Integer d;
    case (bt)
      equation
        d = differenceInHeight(bt);
        bt = doBalance(d,bt);
      then bt;
  end match;
end balance;

protected function doBalance "perform balance if difference is > 1 or < -1"
  input Integer difference;
  input AvlTree bt;
  output AvlTree outBt;
algorithm
  outBt := match (difference,bt)
    case(-1,bt) then computeHeight(bt);
    case(0,bt) then computeHeight(bt);
    case(1,bt) then computeHeight(bt);
      /* d < -1 or d > 1 */
    case(difference,bt)
      equation
        bt = doBalance2(difference < 0,bt);
      then bt;
  end match;
end doBalance;

protected function doBalance2 "help function to doBalance"
  input Boolean differenceIsNegative;
  input AvlTree bt;
  output AvlTree outBt;
algorithm
  outBt := match (differenceIsNegative,bt)
    case (true,bt)
      equation
        bt = doBalance3(bt);
        bt = rotateLeft(bt);
      then bt;
    case (false,bt)
      equation
        bt = doBalance4(bt);
        bt = rotateRight(bt);
      then bt;
  end match;
end doBalance2;

protected function doBalance3 "help function to doBalance2"
  input AvlTree bt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(bt)
    local
      AvlTree rr;
    case(bt)
      equation
        true = differenceInHeight(getOption(rightNode(bt))) > 0;
        rr = rotateRight(getOption(rightNode(bt)));
        bt = setRight(bt,SOME(rr));
      then bt;
    else bt;
  end matchcontinue;
end doBalance3;

protected function doBalance4 "help function to doBalance2"
  input AvlTree bt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(bt)
    local
      AvlTree rl;
    case (bt)
      equation
        true = differenceInHeight(getOption(leftNode(bt))) < 0;
        rl = rotateLeft(getOption(leftNode(bt)));
        bt = setLeft(bt,SOME(rl));
      then bt;
    else bt;
  end matchcontinue;
end doBalance4;

protected function setRight "set right treenode"
  input AvlTree node;
  input Option<AvlTree> right;
  output AvlTree outNode;
algorithm
  outNode := match (node,right)
   local Option<AvlTreeValue> value;
    Option<AvlTree> l,r;
    Integer height;
    case(AVLTREENODE(value,height,l,r),right) then AVLTREENODE(value,height,l,right);
  end match;
end setRight;

protected function setLeft "set left treenode"
  input AvlTree node;
  input Option<AvlTree> left;
  output AvlTree outNode;
algorithm
  outNode := match (node,left)
  local Option<AvlTreeValue> value;
    Option<AvlTree> l,r;
    Integer height;
    case(AVLTREENODE(value,height,l,r),left) then AVLTREENODE(value,height,left,r);
  end match;
end setLeft;


protected function leftNode "Retrieve the left subnode"
  input AvlTree node;
  output Option<AvlTree> subNode;
algorithm
  subNode := match(node)
    case(AVLTREENODE(left = subNode)) then subNode;
  end match;
end leftNode;

protected function rightNode "Retrieve the right subnode"
  input AvlTree node;
  output Option<AvlTree> subNode;
algorithm
  subNode := match(node)
    case(AVLTREENODE(right = subNode)) then subNode;
  end match;
end rightNode;

protected function exchangeLeft "help function to balance"
  input AvlTree node;
  input AvlTree parent;
  output AvlTree outParent "updated parent";
algorithm
  outParent := match(node,parent)
    local
      Option<AvlTreeValue> value;
      Integer height ;
      AvlTree bt;

    case(node,parent) equation
      parent = setRight(parent,leftNode(node));
      parent = balance(parent);
      node = setLeft(node,SOME(parent));
      bt = balance(node);
    then bt;
  end match;
end exchangeLeft;

protected function exchangeRight "help function to balance"
input AvlTree node;
input AvlTree parent;
output AvlTree outParent "updated parent";
algorithm
  outParent := match(node,parent)
  local AvlTree bt;
    case(node,parent) equation
      parent = setLeft(parent,rightNode(node));
      parent = balance(parent);
      node = setRight(node,SOME(parent));
      bt = balance(node);
    then bt;
  end match;
end exchangeRight;

protected function rotateLeft "help function to balance"
input AvlTree node;
output AvlTree outNode "updated node";
algorithm
  outNode := exchangeLeft(getOption(rightNode(node)),node);
end rotateLeft;

protected function getOption "Retrieve the value of an option"
  replaceable type T subtypeof Any;
  input Option<T> opt;
  output T val;
algorithm
  val := match(opt)
    case(SOME(val)) then val;
  end match;
end getOption;

protected function rotateRight "help function to balance"
input AvlTree node;
output AvlTree outNode "updated node";
algorithm
  outNode := exchangeRight(getOption(leftNode(node)),node);
end rotateRight;

protected function differenceInHeight "help function to balance, calculates the difference in height
between left and right child"
  input AvlTree node;
  output Integer diff;
algorithm
  diff := match (node)
    local
      Integer lh,rh;
      Option<AvlTree> l,r;
    case(AVLTREENODE(left=l,right=r))
      equation
        lh = getHeight(l);
        rh = getHeight(r);
      then lh - rh;
  end match;
end differenceInHeight;

public function avlTreeGet
  "Get a value from the binary tree given a key."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  output AvlValue outValue;
algorithm
  outValue := match (inAvlTree,inKey)
    local
      AvlKey rkey,key;
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(key=rkey))),key)
      then avlTreeGet2(inAvlTree,stringCompare(key,rkey),key);
  end match;
end avlTreeGet;

protected function avlTreeGet2
  "Get a value from the binary tree given a key."
  input AvlTree inAvlTree;
  input Integer keyComp "0=get value from current node, 1=search right subtree, -1=search left subtree";
  input AvlKey inKey;
  output AvlValue outValue;
algorithm
  outValue := match (inAvlTree,keyComp,inKey)
    local
      AvlKey key;
      AvlValue rval;
      AvlTree left,right;
    
    // hash func Search to the right
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(value=rval))),0,key)
      then rval;
    
    // search to the right
    case (AVLTREENODE(right = SOME(right)),1,key)
      then avlTreeGet(right, key);

    // search to the left
    case (AVLTREENODE(left = SOME(left)),-1,key)
      then avlTreeGet(left, key);
  end match;
end avlTreeGet2;

protected function getOptionStr "function getOptionStr
  Retrieve the string from a string option.
  If NONE() return empty string."
  input Option<Type_a> inTypeAOption;
  input FuncTypeType_aToString inFuncTypeTypeAToString;
  output String outString;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToString
    input Type_a inTypeA;
    output String outString;
  end FuncTypeType_aToString;
algorithm
  outString:=
  match (inTypeAOption,inFuncTypeTypeAToString)
    local
      String str;
      Type_a a;
      FuncTypeType_aToString r;
    case (SOME(a),r)
      equation
        str = r(a);
      then
        str;
    case (NONE(),_) then "";
  end match;
end getOptionStr;

protected function printAvlTreeStr "
  Prints the avl tree to a string"
  input AvlTree inAvlTree;
  output String outString;
algorithm
  outString:=
  match (inAvlTree)
    local
      AvlKey rkey;
      String s2,s3,res;
      AvlValue rval;
      Option<AvlTree> l,r;
      Integer h;

    case (AVLTREENODE(value = SOME(AVLTREEVALUE(rkey,rval)),height = h,left = l,right = r))
      equation
        s2 = getOptionStr(l, printAvlTreeStr);
        s3 = getOptionStr(r, printAvlTreeStr);
        res = "\n" +& valueStr(rval) +& ",  " +& s2 +&",  " +& s3;
      then
        res;
    case (AVLTREENODE(value = NONE(),left = l,right = r))
      equation
        s2 = getOptionStr(l, printAvlTreeStr);
        s3 = getOptionStr(r, printAvlTreeStr);
        res = s2 +& ", "+& s3;
      then
        res;
  end match;
end printAvlTreeStr;

protected function computeHeight "compute the heigth of the AvlTree and store in the node info"
  input AvlTree bt;
  output AvlTree outBt;
algorithm
  outBt := match(bt)
    local
      Option<AvlTree> l,r;
      Option<AvlTreeValue> v;
      AvlValue val;
      Integer hl,hr,height;
    case(AVLTREENODE(value=v as SOME(_),left=l,right=r))
      equation
        hl = getHeight(l);
        hr = getHeight(r);
        height = intMax(hl,hr) + 1;
      then AVLTREENODE(v,height,l,r);
  end match;
end computeHeight;

protected function getHeight "Retrieve the height of a node"
  input Option<AvlTree> bt;
  output Integer height;
algorithm
  height := match (bt)
    case(NONE()) then 0;
    case(SOME(AVLTREENODE(height = height))) then height;
  end match;
end getHeight;

public function isTopScope "Returns true if we are in the top-most scope"
  input Env env;
  output Boolean isTop;
algorithm
  isTop := matchcontinue env
    case {FRAME(optName = NONE())} then true;
    case _ then false;
  end matchcontinue;
end isTopScope;

public function getVariablesFromEnv 
"@author: adrpo
  returns the a list with all the variables in the given environment"
  input Env inEnv;
  output list<String> variables;
algorithm
  variables := match (inEnv)
    local
      list<Ident> lst1;
      Frame fr;
      Env frs;
    // empty case
    case {} then {};
    // some environment
    case (fr :: frs)
      equation
        lst1 = getVariablesFromFrame(fr);
        // adrpo: TODO! FIXME! CHECK if we really don't need this!
        // lst2 = getVariablesFromEnv(frs);
        // lst = listAppend(lst1, lst2);
      then
        lst1;
  end match;
end getVariablesFromEnv;

protected function getVariablesFromFrame 
"@author: adrpo
  returns all variables in the frame as a list of strings."
  input Frame inFrame;
  output list<String> variables;
algorithm
  variables := match (inFrame)
    local
      list<Ident> lst;
      AvlTree ht;

    case FRAME(clsAndVars = ht)
      equation
        lst = getVariablesFromAvlTree(ht);
      then
        lst;
  end match;
end getVariablesFromFrame;

protected function getVariablesFromAvlTree 
"@author: adrpo
  returns variables from the avl tree as a list of strings"
  input AvlTree inAvlTree;
  output list<String> variables;
algorithm
  variables := match (inAvlTree)
    local
      AvlKey rkey;
      list<String> lst0, lst1, lst2, lst;
      AvlValue rval;
      Option<AvlTree> l,r;
      Integer h;

    case (AVLTREENODE(value = SOME(AVLTREEVALUE(rkey,rval)),height = h,left = l,right = r))
      equation
        lst0 = getVariablesFromAvlValue(rval);
        lst1 = getVariablesFromOptionAvlTree(l);
        lst2 = getVariablesFromOptionAvlTree(r);
        lst = listAppend(lst1, lst2);
        lst = listAppend(lst0, lst);
      then
        lst;
        
    case (AVLTREENODE(value = NONE(),left = l,right = r))
      equation
        lst1 = getVariablesFromOptionAvlTree(l);
        lst2 = getVariablesFromOptionAvlTree(r);
        lst = listAppend(lst1, lst2);
      then
        lst;
  end match;
end getVariablesFromAvlTree;

protected function getVariablesFromOptionAvlTree
"@author: adrpo
  returns the variables from the given optional tree as a list of strings.
  if the tree is none then the function returns an empty list"
  input Option<AvlTree> inAvlTreeOpt;
  output list<String> variables;
algorithm
  variables := match (inAvlTreeOpt)
    local
      list<String>   lst;
      AvlTree avl;
    // handle nothingness
    case (NONE()) then {};
    // we have some value
    case (SOME(avl)) then getVariablesFromAvlTree(avl);
  end match;
end getVariablesFromOptionAvlTree;

public function getVariablesFromAvlValue 
"@author:adrpo
  returns a list with one variable or an empty list"
  input AvlValue v;
  output list<String> variables;
algorithm
  variables := matchcontinue(v)
    local 
      String name; 
    case(VAR(instantiated=DAE.TYPES_VAR(name=name))) then {name};
    case(_) then {};
  end matchcontinue;
end getVariablesFromAvlValue;

public function inFunctionScope
  input Env inEnv;
  output Boolean inFunction;
algorithm
  inFunction := matchcontinue(inEnv)
    local
      DAE.ComponentRef cr;
      list<Frame> fl;
    case ({}) then false;
    case (FRAME(optType = SOME(FUNCTION_SCOPE())) :: _) then true;
    case (FRAME(optType = SOME(CLASS_SCOPE())) :: _) then false;
    case (_ :: fl) then inFunctionScope(fl);
  end matchcontinue;
end inFunctionScope;

public function classInfToScopeType
  input ClassInf.State inState;
  output Option<ScopeType> outType;
algorithm
  outType := matchcontinue(inState)
    case ClassInf.FUNCTION(path = _) then SOME(FUNCTION_SCOPE());
    case _ then SOME(CLASS_SCOPE());
  end matchcontinue;
end classInfToScopeType;

public function restrictionToScopeType
  input SCode.Restriction inRestriction;
  output Option<ScopeType> outType;
algorithm
  outType := matchcontinue(inRestriction)
    case SCode.R_FUNCTION() then SOME(FUNCTION_SCOPE());
    case _ then SOME(CLASS_SCOPE());
  end matchcontinue;
end restrictionToScopeType;

public function getFunctionTree
"Selector function"
  input Cache cache;
  output DAE.FunctionTree ft;
protected
  array<DAE.FunctionTree> ef;
algorithm
  CACHE(functions = ef) := cache;
  ft := arrayGet(ef, 1);
end getFunctionTree;

public function addCachedInstFuncGuard
"adds the FQ path to the set of instantiated functions as NONE().
This guards against recursive functions."
  input Cache cache;
  input Absyn.Path func "fully qualified function name";
  output Cache outCache;
algorithm
  outCache := matchcontinue(cache,func)
    local
    	array<Option<EnvCache>> envCache;
    	array<DAE.FunctionTree> ef;
    	Absyn.ComponentRef cr;
    	Option<Env> ienv;

      /* Don't overwrite SOME() with NONE() */
    case (cache, func)
      equation
        checkCachedInstFuncGuard(cache, func);
      then cache;

    case (CACHE(envCache,ienv,ef),func as Absyn.FULLYQUALIFIED(_))
      equation
        ef = arrayUpdate(ef,1,DAEUtil.avlTreeAdd(arrayGet(ef, 1),func,NONE()));
      then CACHE(envCache,ienv,ef);
    // Non-FQ paths mean aliased functions; do not add these to the cache
    case (cache,_) then (cache);
  end matchcontinue;
end addCachedInstFuncGuard;

public function addDaeFunction
"adds the list<DAE.Function> to the set of instantiated functions"
  input Cache inCache;
  input list<DAE.Function> funcs "fully qualified function name";
  output Cache outCache;
algorithm
  outCache := match(inCache,funcs)
    local
    	array<Option<EnvCache>> envCache;
    	array<DAE.FunctionTree> ef;
    	Option<Env> ienv;
    case (CACHE(envCache,ienv,ef),funcs)
      equation
        ef = arrayUpdate(ef,1,DAEUtil.addDaeFunction(funcs, arrayGet(ef, 1)));
      then CACHE(envCache,ienv,ef);
  end match;
end addDaeFunction;

public function addDaeExtFunction
"adds the external functions in list<DAE.Function> to the set of instantiated functions"
  input Cache inCache;
  input list<DAE.Function> funcs "fully qualified function name";
  output Cache outCache;
algorithm
  outCache := match(inCache,funcs)
    local
    	array<Option<EnvCache>> envCache;
    	array<DAE.FunctionTree> ef;
    	Option<Env> ienv;
    case (CACHE(envCache,ienv,ef),funcs)
      equation
        ef = arrayUpdate(ef,1,DAEUtil.addDaeExtFunction(funcs, arrayGet(ef,1)));
      then CACHE(envCache,ienv,ef);
  end match;
end addDaeExtFunction;

public function getCachedInstFunc
"returns the function in the set"
  input Cache inCache;
  input Absyn.Path path;
  output DAE.Function func;
algorithm
  func := match(inCache,path)
    local
      array<DAE.FunctionTree> ef;
    case(CACHE(functions=ef),path)
      equation
        SOME(func) = DAEUtil.avlTreeGet(arrayGet(ef,1),path);
      then func;
  end match;
end getCachedInstFunc;

public function checkCachedInstFuncGuard
"succeeds if the FQ function is in the set of functions"
  input Cache inCache;
  input Absyn.Path path;
algorithm
  _ := match(inCache,path)
    local
      array<DAE.FunctionTree> ef;
    case(CACHE(functions=ef),path) equation
      _ = DAEUtil.avlTreeGet(arrayGet(ef,1),path);
    then ();
  end match;
end checkCachedInstFuncGuard;

end Env;

