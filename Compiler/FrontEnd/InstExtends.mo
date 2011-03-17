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

encapsulated package InstExtends
" file:        InstExtends.mo
  package:     InstExtends
  description: Model instantiation

  RCS: $Id$

  This module is responsible for instantiation of the extends and
  class extends constructs in Modelica models.
  
"

// public imports
public import Absyn;
public import ClassInf;
public import DAE;
public import Env;
public import HashTableStringToPath;
public import InnerOuter;
public import SCode;
public import Prefix;

// protected imports
protected import BaseHashTable;
protected import Builtin;
protected import ComponentReference;
protected import Debug;
protected import Dump;
protected import Error;
protected import Inst;
protected import Lookup;
protected import Mod;
protected import RTOpts;
protected import Types;
protected import Util;

public type InstanceHierarchy = InnerOuter.InstHierarchy "an instance hierarchy";

protected function instExtendsList "
  author: PA
  This function flattens out the inheritance structure of a class.
  It takes an SCode.Element list and flattens out the extends nodes
  of that list. The result is a list of components and lists of equations
  and algorithms."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input list<SCode.Element> inSCodeElementLst;
  input ClassInf.State inState;
  input String inClassName; // the class name whose elements are getting instantiated.
  input Boolean inBoolean;
  input Boolean isPartialInst;
  output Env.Cache outCache;
  output Env.Env outEnv1;
  output InstanceHierarchy outIH;
  output DAE.Mod outMod2;
  output list<tuple<SCode.Element, DAE.Mod, Boolean>> outTplSCodeElementModLst3;
  output list<SCode.Equation> outSCodeEquationLst4;
  output list<SCode.Equation> outSCodeEquationLst5;
  output list<SCode.AlgorithmSection> outSCodeAlgorithmLst6;
  output list<SCode.AlgorithmSection> outSCodeAlgorithmLst7;
algorithm
  (outCache,outEnv1,outIH,outMod2,outTplSCodeElementModLst3,outSCodeEquationLst4,outSCodeEquationLst5,outSCodeAlgorithmLst6,outSCodeAlgorithmLst7):=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSCodeElementLst,inState,inClassName,inBoolean,isPartialInst)
    local
      SCode.Class c;
      String cn,s,scope_str,className;
      Boolean encf,impl,notConst;
      SCode.Restriction r;
      list<Env.Frame> cenv,cenv1,cenv3,env2,env,env_1;
      DAE.Mod outermod,mods,mods_1,emod_1,mod;
      list<SCode.Element> importelts,els,els_1,rest,cdefelts,classextendselts;
      list<SCode.Equation> eq1,ieq1,eq1_1,ieq1_1,eq2,ieq2,eq3,ieq3,eq,ieq,initeq2;
      list<SCode.AlgorithmSection> alg1,ialg1,alg1_1,ialg1_1,alg2,ialg2,alg3,ialg3,alg,ialg;
      Absyn.Path tp_1,tp;
      ClassInf.State new_ci_state,ci_state;
      list<tuple<SCode.Element, DAE.Mod, Boolean>> compelts1,compelts2,compelts,compelts3;
      SCode.Mod emod;
      SCode.Element elt;
      Env.Cache cache;
      InstanceHierarchy ih;
      HashTableStringToPath.HashTable ht;
      SCode.Variability var;
      Prefix.Prefix pre;
      SCode.Mod scodeMod;
      Boolean finalPrefix;
      Absyn.Info info;

    /* no further elements to instantiate */
    case (cache,env,ih,mod,pre,{},ci_state,className,impl,_) then (cache,env,ih,mod,{},{},{},{},{});
      
    /* instantiate a base class */
    case (cache,env,ih,mod,pre,(SCode.EXTENDS(info = info, baseClassPath = tp,modifications = emod) :: rest),ci_state,className,impl,isPartialInst)
      equation
        // adrpo - here we need to check if we don't have recursive extends of the form:
        // package Icons
        //   extends Icons.BaseLibrary;
        //        model BaseLibrary "Icon for base library"
        //        end BaseLibrary;
        // end Icons;
        // if we don't check that, then the compiler enters an infinite loop!
        // what we do is removing Icons from extends Icons.BaseLibrary;
        tp = Inst.removeSelfReference(className, tp);
        // print(className +& "\n");
        // print("Type: " +& Absyn.pathString(tp) +& "\n");
        (cache,(c as SCode.CLASS(name=cn,encapsulatedPrefix=encf,restriction=r)),cenv) = Lookup.lookupClass(cache,env, tp, false);
        // print("Found " +& cn +& "\n");

        outermod = Mod.lookupModificationP(mod, Absyn.IDENT(cn));
        
        (cache,cenv1,ih,els,eq1,ieq1,alg1,ialg1) = instDerivedClasses(cache,cenv,ih,outermod,c,impl,info);
        
        (cache,tp_1) = Inst.makeFullyQualified(cache,/* adrpo: cenv1?? FIXME */env, tp);
        
        eq1_1 = Util.if_(isPartialInst, {}, eq1);
        ieq1_1 = Util.if_(isPartialInst, {}, ieq1);
        alg1_1 = Util.if_(isPartialInst, {}, alg1);
        ialg1_1 = Util.if_(isPartialInst, {}, ialg1);

        cenv3 = Env.openScope(cenv1, encf, SOME(cn), Env.classInfToScopeType(ci_state));
        new_ci_state = ClassInf.start(r, Env.getEnvName(cenv3));
        /* Add classdefs and imports to env, so e.g. imports from baseclasses found, see Extends5.mo */
        (importelts,cdefelts,classextendselts,els_1) = Inst.splitEltsNoComponents(els);
        (cenv3,ih) = Inst.addClassdefsToEnv(cenv3,ih,pre,importelts,impl,NONE());
        (cenv3,ih) = Inst.addClassdefsToEnv(cenv3,ih,pre,cdefelts,impl,NONE());

        (cache,_,ih,mods,compelts1,eq2,ieq2,alg2,ialg2) = instExtendsAndClassExtendsList2(cache,cenv3,ih,outermod,pre,els_1,classextendselts,ci_state,className,impl,isPartialInst)
        "recurse to fully flatten extends elements env";

        ht = getLocalIdentList(compelts1,HashTableStringToPath.emptyHashTable(),getLocalIdentElementTpl);
        ht = getLocalIdentList(cdefelts,ht,getLocalIdentElement);
        ht = getLocalIdentList(importelts,ht,getLocalIdentElement);
        
        //tmp = tick(); Debug.traceln("try fix local idents " +& intString(tmp));
        (cache,compelts1) = fixLocalIdents(cache,cenv1,compelts1,ht);
        (cache,eq1_1) = fixList(cache,cenv1,eq1_1,ht,fixEquation);
        (cache,ieq1_1) = fixList(cache,cenv1,ieq1_1,ht,fixEquation);
        (cache,alg1_1) = fixList(cache,cenv1,alg1_1,ht,fixAlgorithm);
        (cache,ialg1_1) = fixList(cache,cenv1,ialg1_1,ht,fixAlgorithm);
        //Debug.traceln("fixed local idents " +& intString(tmp));

        (cache,env2,ih,mods_1,compelts2,eq3,ieq3,alg3,ialg3) = instExtendsList(cache,env,ih,mod,pre,rest,ci_state,className,impl,isPartialInst)
        "continue with next element in list" ;
        /*
        corresponding elements. But emod is Absyn.Mod and can not Must merge(mod,emod)
        here and then apply the bindings to the be elaborated, because for instance extends
        A(x=y) can reference a variable y defined in A and will thus not be found.
        On the other hand: A(n=4), n might be a structural parameter that must be set
        to instantiate A. How could this be solved? Solution: made new function elab_untyped_mod
        which transforms to a Mod, but set the type information to unknown. We can then perform the
        merge, and update untyped modifications later (using update_mod), when we are instantiating
        the components."
        */
        emod_1 = Mod.elabUntypedMod(emod, env2, Prefix.NOPRE());
        mods_1 = Mod.merge(mod, mods_1, env2, Prefix.NOPRE());
        mods_1 = Mod.merge(mods_1, emod_1, env2, Prefix.NOPRE());

        compelts = listAppend(compelts1, compelts2);

        (compelts3,mods_1) = updateComponentsAndClassdefs(compelts, mods_1, env2) "update components with new merged modifiers";
        eq = Util.listlistFunc(eq1_1,{eq2,eq3},Util.listUnionOnTrue,Util.equal);
        ieq = Util.listlistFunc(ieq1_1,{ieq2,ieq3},Util.listUnionOnTrue,Util.equal);
        alg = Util.listlistFunc(alg1_1,{alg2,alg3},Util.listUnionOnTrue,Util.equal);
        ialg = Util.listlistFunc(ialg1_1,{ialg2,ialg3},Util.listUnionOnTrue,Util.equal);
      then
        (cache,env2,ih,mods_1,compelts3,eq,ieq,alg,ialg);

    /* base class was not found */
    case (cache,env,ih,mod,pre,(SCode.EXTENDS(info = info, baseClassPath = tp,modifications = emod) :: rest),ci_state,className,impl,_)
      equation
        failure((_,c,cenv) = Lookup.lookupClass(cache,env, tp, false));
        s = Absyn.pathString(tp);
        scope_str = Env.printEnvPathStr(env);
        Error.addSourceMessage(Error.LOOKUP_BASECLASS_ERROR, {s,scope_str}, info);
      then
        fail();

    /* Extending a component means copying it. 
    case (cache,env,ih,mod,pre,(elt as SCode.COMPONENT(component = s, attributes = SCode.ATTR(variability = var), modifications = scodeMod, finalPrefix=finalPrefix)) :: rest,ci_state,className,impl,isPartialInst)
      equation
        (cache,env_1,ih,mods,compelts2,eq2,initeq2,alg2,ialg2) =
        instExtendsList(cache, env, ih, mod, pre, rest, ci_state, className, impl, isPartialInst);
        // make sure you add final to the modifier!
        scodeMod = Inst.traverseModAddFinal(scodeMod, finalPrefix); 
        innerMod = Mod.elabUntypedMod(scodeMod, env_1, Prefix.NOPRE());
        // Filter out non-constants if partial inst
        notConst = not SCode.isConstant(var);
        compelts2 = Util.if_(notConst and isPartialInst,compelts2,(elt,innerMod,false)::compelts2);
      then
        (cache,env_1,ih,mods,compelts2,eq2,initeq2,alg2,ialg2);*/

    /* Extending a component means copying it. It might fail above, try again*/
    case (cache,env,ih,mod,pre,(elt as SCode.COMPONENT(component = s, attributes = SCode.ATTR(variability = var), modifications = scodeMod, finalPrefix=finalPrefix)) :: rest,ci_state,className,impl,isPartialInst)
      equation
        (cache,env_1,ih,mods,compelts2,eq2,initeq2,alg2,ialg2) =
        instExtendsList(cache, env, ih, mod, pre, rest, ci_state, className, impl, isPartialInst);
        /* Filter out non-constants if partial inst */
        notConst = not SCode.isConstant(var);
        compelts2 = Util.if_(notConst and isPartialInst,compelts2,(elt,DAE.NOMOD(),false)::compelts2);
      then
        (cache,env_1,ih,mods,compelts2,eq2,initeq2,alg2,ialg2);        

    /* Classdefs */
    case (cache,env,ih,mod,pre,(elt as SCode.CLASSDEF(name = cn)) :: rest,ci_state,className,impl,isPartialInst)
      equation
        (cache,env_1,ih,mods,compelts2,eq2,initeq2,alg2,ialg2) =
        instExtendsList(cache, env, ih, mod, pre, rest, ci_state, className, impl, isPartialInst);
      then
        (cache,env_1,ih,mods,((elt,DAE.NOMOD(),false) :: compelts2),eq2,initeq2,alg2,ialg2);

    /* instantiate elements that are not extends */
    case (cache,env,ih,mod,pre,(elt as SCode.IMPORT(imp = _)) :: rest,ci_state,className,impl,isPartialInst)
      equation
        (cache,env_1,ih,mods,compelts2,eq2,initeq2,alg2,ialg2) =
        instExtendsList(cache,env,ih, mod, pre, rest, ci_state, className, impl, isPartialInst);
      then
        (cache,env_1,ih,mods,((elt,DAE.NOMOD(),false) :: compelts2),eq2,initeq2,alg2,ialg2);

    /* instantiation failed */
    case (cache,env,ih,mod,pre,rest,ci_state,className,_,_)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- Inst.instExtendsList failed on:\n\t" +&
          "className: " +&  className +& "\n\t" +&
          "env:       " +&  Env.printEnvPathStr(env) +& "\n\t" +&
          "mods:      " +&  Mod.printModStr(mod) +& "\n\t" +&
          "elems:     " +&  Util.stringDelimitList(Util.listMap(rest, SCode.printElementStr), ", ")
          );
      then
        fail();
  end matchcontinue;
end instExtendsList;

public function instExtendsAndClassExtendsList "
  This function flattens out the inheritance structure of a class.
  It takes an SCode.Element list and flattens out the extends nodes and
  class extends nodes of that list. The result is a list of components and
  lists of equations and algorithms."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input list<SCode.Element> inExtendsElementLst;
  input list<SCode.Element> inClassExtendsElementLst;
  input ClassInf.State inState;
  input String inClassName; // the class name whose elements are getting instantiated.
  input Boolean inImpl;
  input Boolean isPartialInst;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.Mod outMod;
  output list<tuple<SCode.Element, DAE.Mod>> outTplSCodeElementModLst;
  output list<SCode.Equation> outSCodeNormalEquationLst;
  output list<SCode.Equation> outSCodeInitialEquationLst;
  output list<SCode.AlgorithmSection> outSCodeNormalAlgorithmLst;
  output list<SCode.AlgorithmSection> outSCodeInitialAlgorithmLst;
protected
  list<tuple<SCode.Element, DAE.Mod, Boolean>> outTplSCodeElementModLstTpl3;
  list<SCode.Element> cdefelts,tmpelts;
algorithm
  //Debug.fprintln("debug","instExtendsAndClassExtendsList: " +& inClassName);
  (outCache,outEnv,outIH,outMod,outTplSCodeElementModLstTpl3,outSCodeNormalEquationLst,outSCodeInitialEquationLst,outSCodeNormalAlgorithmLst,outSCodeInitialAlgorithmLst):=
  instExtendsAndClassExtendsList2(inCache,inEnv,inIH,inMod,inPrefix,inExtendsElementLst,inClassExtendsElementLst,inState,inClassName,inImpl,isPartialInst);
  // Filter out the last boolean in the tuple
  outTplSCodeElementModLst := Util.listMap(outTplSCodeElementModLstTpl3, Util.tuple312);
  // Create a list of the class definitions, since these can't be properly added in the recursive call 
  tmpelts := Util.listMap(outTplSCodeElementModLst,Util.tuple21);
  (_,cdefelts,_,_) := Inst.splitEltsNoComponents(tmpelts);
  // Add the class definitions to the environment
  (outEnv,outIH) := Inst.addClassdefsToEnv(outEnv,outIH,inPrefix,cdefelts,inImpl,NONE());
  //Debug.fprintln("debug","instExtendsAndClassExtendsList: " +& inClassName +& " done");
end instExtendsAndClassExtendsList;

protected function instExtendsAndClassExtendsList2 "
  This function flattens out the inheritance structure of a class.
  It takes an SCode.Element list and flattens out the extends nodes and
  class extends nodes of that list. The result is a list of components and
  lists of equations and algorithms."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input list<SCode.Element> inExtendsElementLst;
  input list<SCode.Element> inClassExtendsElementLst;
  input ClassInf.State inState;
  input String inClassName; // the class name whose elements are getting instantiated.
  input Boolean inImpl;
  input Boolean isPartialInst;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.Mod outMod;
  output list<tuple<SCode.Element, DAE.Mod, Boolean>> outTplSCodeElementModLst;
  output list<SCode.Equation> outSCodeNormalEquationLst;
  output list<SCode.Equation> outSCodeInitialEquationLst;
  output list<SCode.AlgorithmSection> outSCodeNormalAlgorithmLst;
  output list<SCode.AlgorithmSection> outSCodeInitialAlgorithmLst;
algorithm
  (outCache,outEnv,outIH,outMod,outTplSCodeElementModLst,outSCodeNormalEquationLst,outSCodeInitialEquationLst,outSCodeNormalAlgorithmLst,outSCodeInitialAlgorithmLst):=
  instExtendsList(inCache,inEnv,inIH,inMod,inPrefix,inExtendsElementLst,inState,inClassName,inImpl,isPartialInst);
  (outMod,outTplSCodeElementModLst):=instClassExtendsList(inEnv,outMod,inClassExtendsElementLst,outTplSCodeElementModLst);
end instExtendsAndClassExtendsList2;

protected function instClassExtendsList
"Instantiate element nodes of type SCode.CLASS_EXTENDS. This is done by walking
the extended classes and performing the modifications in-place. The old class
will no longer be accessible."
  input Env.Env inEnv;
  input DAE.Mod inMod;
  input list<SCode.Element> inClassExtendsList;
  input list<tuple<SCode.Element, DAE.Mod, Boolean>> inTplSCodeElementModLst;
  output DAE.Mod outMod;
  output list<tuple<SCode.Element, DAE.Mod, Boolean>> outTplSCodeElementModLst;
algorithm
  (outMod,outTplSCodeElementModLst) := matchcontinue (inEnv,inMod,inClassExtendsList,inTplSCodeElementModLst)
    local
      SCode.Element first;
      list<SCode.Element> rest;
      String name;
      list<SCode.Element> els;
      list<tuple<SCode.Element, DAE.Mod, Boolean>> compelts;
      DAE.Mod emod;
      list<String> names;
    case (_,emod,{},compelts) then (emod,compelts);
    case (_,emod,(first as SCode.CLASSDEF(name=name))::rest,compelts)
      equation
        (emod,compelts) = instClassExtendsList2(inEnv,emod,name,first,compelts);
        (emod,compelts) = instClassExtendsList(inEnv,emod,rest,compelts);
      then (emod,compelts);
    case (_,_,SCode.CLASSDEF(name=name)::rest,compelts)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- Inst.instClassExtendsList failed " +& name);
        Debug.traceln("  Candidate classes: ");
        els = Util.listMap(compelts, Util.tuple31);
        names = Util.listMap(els, SCode.elementName);
        Debug.traceln(Util.stringDelimitList(names, ","));
      then fail();
  end matchcontinue;
end instClassExtendsList;

protected function instClassExtendsList2
  input Env.Env inEnv;
  input DAE.Mod inMod;
  input String inName;
  input SCode.Element inClassExtendsElt;
  input list<tuple<SCode.Element, DAE.Mod, Boolean>> inTplSCodeElementModLst;
  output DAE.Mod outMod;
  output list<tuple<SCode.Element, DAE.Mod, Boolean>> outTplSCodeElementModLst;
algorithm
  (outMod,outTplSCodeElementModLst) := matchcontinue (inEnv,inMod,inName,inClassExtendsElt,inTplSCodeElementModLst)
    local
      SCode.Element elt,compelt,classExtendsElt;
      SCode.Class cl,classExtendsClass;
      SCode.ClassDef classDef,classExtendsCdef;
      Boolean partialPrefix1,encapsulatedPrefix1,finalPrefix1,replaceablePrefix1,redecl1;
      Boolean partialPrefix2,encapsulatedPrefix2,finalPrefix2,replaceablePrefix2,redecl2;
      SCode.Restriction restriction1,restriction2;
      String name1,name2,env_path;
      Option<Absyn.ExternalDecl> externalDecl;
      list<SCode.Annotation> annotationLst1,annotationLst2;
      Option<SCode.Comment> comment1,comment2;
      list<SCode.Element> els1,els2;
      list<SCode.Equation> nEqn1,nEqn2,inEqn1,inEqn2;
      list<SCode.AlgorithmSection> nAlg1,nAlg2,inAlg1,inAlg2;
      list<tuple<SCode.Element, DAE.Mod, Boolean>> rest;
      tuple<SCode.Element, DAE.Mod, Boolean> first;
      SCode.Mod mods;
      DAE.Mod mod1,emod;
      Option<Absyn.ConstrainClass> cc1,cc2;
      Absyn.Info info1, info2;
      Boolean b;

    case (_,emod,name1,classExtendsElt,(SCode.CLASSDEF(name2,finalPrefix2,replaceablePrefix2,redecl2,cl,cc2),mod1,b)::rest)
      equation
        true = name1 ==& name2; // Compare the name before pattern-matching to speed this up

        env_path = Absyn.pathString(Env.getEnvName(inEnv));
        name2 = env_path +& "." +& name2 +& "$parent";
        SCode.CLASS(_,partialPrefix2,encapsulatedPrefix2,restriction2,SCode.PARTS(els2,nEqn2,inEqn2,nAlg2,inAlg2,externalDecl,annotationLst2,comment2),info2) = cl;

        SCode.CLASSDEF(_, finalPrefix1, replaceablePrefix1, redecl1, classExtendsClass, cc1) = classExtendsElt;
        SCode.CLASS(_, partialPrefix1, encapsulatedPrefix1, restriction1, classExtendsCdef, info1) = classExtendsClass;
        SCode.CLASS_EXTENDS(_,mods,els1,nEqn1,inEqn1,nAlg1,inAlg1,annotationLst1,comment1) = classExtendsCdef;

        classDef = SCode.PARTS(els2,nEqn2,inEqn2,nAlg2,inAlg2,externalDecl,annotationLst2,comment2);
        cl = SCode.CLASS(name2,partialPrefix2,encapsulatedPrefix2,restriction2,classDef,info2);
        compelt = SCode.CLASSDEF(name2, finalPrefix2, replaceablePrefix2, redecl2, cl, cc2);

        elt = SCode.EXTENDS(Absyn.IDENT(name2),mods,NONE(),info1);
        classDef = SCode.PARTS(elt::els1,nEqn1,inEqn1,nAlg1,inAlg1,NONE(),annotationLst1,comment1);
        cl = SCode.CLASS(name1,partialPrefix1,encapsulatedPrefix1,restriction1,classDef, info1);
        elt = SCode.CLASSDEF(name1, finalPrefix1, replaceablePrefix1, redecl1, cl, cc1);
        emod = Mod.renameTopLevelNamedSubMod(emod,name1,name2);
        // Debug.traceln("class extends: " +& SCode.printElementStr(compelt) +& "  " +& SCode.printElementStr(elt));
      then (emod,(compelt,mod1,b)::(elt,DAE.NOMOD(),true)::rest);
    case (_,emod,name1,classExtendsElt,first::rest)
      equation
        (emod,rest) = instClassExtendsList2(inEnv,emod,name1,classExtendsElt,rest);
      then (emod,first::rest);
    case (_,_,_,_,{})
      equation
        Debug.traceln("TODO: Make a proper Error message here - Inst.instClassExtendsList2 couldn't find the class to extend");
      then fail();
  end matchcontinue;
end instClassExtendsList2;

public function instDerivedClasses
"function: instDerivedClasses
  author: PA
  This function takes a class definition and returns the
  elements and equations and algorithms of the class.
  If the class is derived, the class is looked up and the
  derived class parts are fetched."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input DAE.Mod inMod;
  input SCode.Class inClass;
  input Boolean inBoolean;
  input Absyn.Info info "File information of the extends element";
  output Env.Cache outCache;
  output Env.Env outEnv1;
  output InstanceHierarchy outIH;
  output list<SCode.Element> outSCodeElementLst2;
  output list<SCode.Equation> outSCodeEquationLst3;
  output list<SCode.Equation> outSCodeEquationLst4;
  output list<SCode.AlgorithmSection> outSCodeAlgorithmLst5;
  output list<SCode.AlgorithmSection> outSCodeAlgorithmLst6;
algorithm
  (outCache,outEnv1,outIH,outSCodeElementLst2,outSCodeEquationLst3,outSCodeEquationLst4,outSCodeAlgorithmLst5,outSCodeAlgorithmLst6):=
  matchcontinue (inCache,inEnv,inIH,inMod,inClass,inBoolean,info)
    local
      list<SCode.Element> elt;
      list<Env.Frame> env,cenv;
      DAE.Mod mod;
      list<SCode.Equation> eq,ieq;
      list<SCode.AlgorithmSection> alg,ialg;
      SCode.Class c;
      Absyn.Path tp;
      SCode.Mod dmod;
      Boolean impl;
      Env.Cache cache;
      InstanceHierarchy ih;
      Option<SCode.Comment> cmt;
      list<SCode.Enum> enumLst;
      String n,name;
      Option<Absyn.ExternalDecl> extdecl;
      Absyn.Info info;

    case (cache,env,ih,mod,SCode.CLASS(name = name, classDef =
          SCode.PARTS(elementLst = elt,
                      normalEquationLst = eq,initialEquationLst = ieq,
                      normalAlgorithmLst = alg,initialAlgorithmLst = ialg,
                      externalDecl = extdecl)),_,info)
      equation
        /* elt_1 = noImportElements(elt); */
        Error.assertionOrAddSourceMessage(Util.isNone(extdecl), Error.EXTENDS_EXTERNAL, {name}, info);
      then
        (cache,env,ih,elt,eq,ieq,alg,ialg);

    case (cache,env,ih,mod,SCode.CLASS(info = info, classDef = SCode.DERIVED(typeSpec = Absyn.TPATH(tp, _),modifications = dmod)),impl,_)
      equation
        (cache,c,cenv) = Lookup.lookupClass(cache,env, tp, true);
        (cache,env,ih,elt,eq,ieq,alg,ialg) = instDerivedClasses(cache,cenv,ih, mod, c, impl, info)
        "Mod.lookup_modification_p(mod, c) => innermod & We have to merge and apply modifications as well!" ;
      then
        (cache,env,ih,elt,eq,ieq,alg,ialg);

    case (cache,env,ih,mod,SCode.CLASS(name=n, classDef = SCode.ENUMERATION(enumLst,cmt), info = info),impl,_)
      equation
        c = Inst.instEnumeration(n, enumLst, cmt, info);
        (cache,env,ih,elt,eq,ieq,alg,ialg) = instDerivedClasses(cache,env,ih, mod, c, impl,info);
      then
        (cache,env,ih,elt,eq,ieq,alg,ialg);

    else
      equation
        Debug.fprint("failtrace", "- Inst.instDerivedClasses failed\n");
      then
        fail();
  end matchcontinue;
end instDerivedClasses;

protected function noImportElements
"function: noImportElements
  Returns all elements except imports, i.e. filter out import elements."
  input list<SCode.Element> inSCodeElementLst;
  output list<SCode.Element> outSCodeElementLst;
algorithm
  outSCodeElementLst := matchcontinue (inSCodeElementLst)
    local
      list<SCode.Element> elt,rest;
      SCode.Element e;
    case {} then {};
    case (SCode.IMPORT(imp = _) :: rest)
      equation
        elt = noImportElements(rest);
      then
        elt;
    case (e :: rest)
      equation
        elt = noImportElements(rest);
      then
        (e :: elt);
  end matchcontinue;
end noImportElements;

protected function updateComponentsAndClassdefs
  "This function takes a list of components and a Mod and returns a list of
  components  with the modifiers updated.  The function is used when flattening
  the inheritance structure, resulting in a list of components to insert into
  the class definition. For instance
  model A
    extends B(modifiers)
  end A;
  will result in a list of components
  from B for which modifiers should be applied to."
  input list<tuple<SCode.Element, DAE.Mod, Boolean>> inComponents;
  input DAE.Mod inMod;
  input Env.Env inEnv;
  output list<tuple<SCode.Element, DAE.Mod, Boolean>> outComponents;
  output DAE.Mod outRestMod;
algorithm
  (outComponents, outRestMod) := Util.listMapAndFold1(inComponents, 
    updateComponentsAndClassdefs2, inMod, inEnv);
end updateComponentsAndClassdefs;

protected function updateComponentsAndClassdefs2
  input tuple<SCode.Element, DAE.Mod, Boolean> inComponent;
  input DAE.Mod inMod;
  input Env.Env inEnv;
  output tuple<SCode.Element, DAE.Mod, Boolean> outComponent;
  output DAE.Mod outRestMod;
algorithm
  (outComponent, outRestMod) := matchcontinue(inComponent, inMod, inEnv)
    local
      SCode.Element comp;
      DAE.Mod cmod, cmod2, mod_rest;
      String id, el_str, mod_str1, mod_str2;
      Boolean b;
 
    case ((comp as SCode.COMPONENT(component = id), cmod, b), _, _)
      equation
        // Debug.traceln(" comp: " +& id +& " " +& Mod.printModStr(mod));
        // take ONLY the modification from the equation if is typed
        cmod2 = Mod.lookupCompModificationFromEqu(inMod, id);
        // Debug.traceln("\tSpecific mods on comp: " +&  Mod.printModStr(cmod2));
        cmod = Mod.merge(cmod2, cmod, inEnv, Prefix.NOPRE());
        mod_rest = Types.removeMod(inMod, id);
      then
        ((comp, cmod, b), mod_rest);

    case ((SCode.EXTENDS(baseClassPath = _), _, _), _, _) 
      then (inComponent, inMod);

    case ((comp as SCode.IMPORT(imp = _), _, b), _ , _)
      then ((comp, DAE.NOMOD(), b), inMod);

    case ((comp as SCode.CLASSDEF(replaceablePrefix = true, name = id), _, b), _, _)
      equation
        DAE.REDECL(_, {(comp, cmod)}) = Mod.lookupCompModification(inMod, id);
        mod_rest = Types.removeMod(inMod, id);
      then
        ((comp, cmod, b), mod_rest);

    case ((comp as SCode.CLASSDEF(name = id), cmod, b), _, _)
      equation
        DAE.NOMOD() = Mod.lookupCompModification(inMod, id);
      then
        ((comp, cmod, b), inMod);

    case ((comp as SCode.CLASSDEF(name = id), _, b), _, _)
      equation
        cmod = Mod.lookupCompModification(inMod, id);
      then
        ((comp, cmod, b), inMod);

    case ((comp, cmod, _), _, _)
      equation
        true = RTOpts.debugFlag("failtrace");
        el_str = SCode.printElementStr(comp);
        mod_str1 = Mod.printModStr(cmod);
        mod_str2 = Mod.printModStr(inMod);
        Debug.traceln("- InstExtends.updateComponentsAndClassdefs failed for component " 
          +& el_str +& ".\n\tOld modifier: " +& mod_str1 +& 
                        "\n\tNew modifier: " +& mod_str2);
      then
        fail();
  end matchcontinue;
end updateComponentsAndClassdefs2;

protected function getLocalIdentList
" Analyzes the elements of a class and fetches a list of components and classdefs,
  as well as aliases from imports to paths.
"
  input list<Type_A> elts;
  input HashTableStringToPath.HashTable ht;
  input getIdentFn getIdent;
  output HashTableStringToPath.HashTable outHt;
  
  replaceable type Type_A subtypeof Any;
  partial function getIdentFn
    input Type_A inA;
    input HashTableStringToPath.HashTable ht;
    output HashTableStringToPath.HashTable outHt;
  end getIdentFn;
algorithm
  (outHt) := match (elts,ht,getIdent)
    local
      Type_A elt;
    case ({},ht,getIdent) then ht;
    case (elt::elts,ht,getIdent)
      equation
        ht = getIdent(elt,ht);
        ht = getLocalIdentList(elts,ht,getIdent);
      then ht;
  end match;
end getLocalIdentList;

protected function getLocalIdentElementTpl
" Analyzes the elements of a class and fetches a list of components and classdefs,
  as well as aliases from imports to paths.
"
  input tuple<SCode.Element,DAE.Mod,Boolean> eltTpl;
  input HashTableStringToPath.HashTable ht;
  output HashTableStringToPath.HashTable outHt;
algorithm
  (outHt) := match (eltTpl,ht)
    local
      SCode.Element elt;
    case ((elt,_,_),ht) then getLocalIdentElement(elt,ht);
  end match;
end getLocalIdentElementTpl;

protected function getLocalIdentElement
" Analyzes an element of a class and fetches a list of components and classdefs,
  as well as aliases from imports to paths.
"
  input SCode.Element elt;
  input HashTableStringToPath.HashTable ht;
  output HashTableStringToPath.HashTable outHt;
algorithm
  (outHt) := match (elt,ht)
    local
      String id;
      Absyn.Path p;
    case (SCode.COMPONENT(component = id),ht)
      equation
        ht = BaseHashTable.add((id,Absyn.IDENT(id)), ht);
      then ht;
    case (SCode.CLASSDEF(name = id),ht)
      equation        
        ht = BaseHashTable.add((id,Absyn.IDENT(id)), ht);
      then ht;
    case (SCode.IMPORT(imp = Absyn.NAMED_IMPORT(name = id, path = p)),ht)
      equation
        failure(_ = BaseHashTable.get(id, ht));
        ht = BaseHashTable.add((id,p), ht);
      then ht;
    case (SCode.IMPORT(imp = Absyn.QUAL_IMPORT(path = p)),ht)
      equation
        id = Absyn.pathLastIdent(p);
        failure(_ = BaseHashTable.get(id, ht));
        ht = BaseHashTable.add((id,p), ht);
      then ht;
    // adrpo: 2010-10-07 handle unqualified imports!!! TODO! FIXME! should we just ignore them??
    //                   this fixes bug: #1234 https://openmodelica.org:8443/cb/issue/1234
    case (SCode.IMPORT(imp = Absyn.UNQUAL_IMPORT(path = p)),ht)
      equation
        id = Absyn.pathLastIdent(p);
        failure(_ = BaseHashTable.get(id, ht));
        ht = BaseHashTable.add((id,p), ht);
      then ht;        
  end match;
end getLocalIdentElement;

protected function fixLocalIdents
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache cache;
  input Env.Env env;
  input list<tuple<SCode.Element,DAE.Mod,Boolean>> elts;
  input HashTableStringToPath.HashTable ht;
  output Env.Cache outCache;
  output list<tuple<SCode.Element,DAE.Mod,Boolean>> outElts;
algorithm
  (outCache,outElts) := matchcontinue (cache,env,elts,ht)
    local
      SCode.Element elt;
      DAE.Mod mod;
    case (cache,env,{},ht) then (cache,{});
    case (cache,env,(elt,mod,false)::elts,ht)
      equation
        (cache,elt) = fixElement(cache,env,elt,ht);
        (cache,elts) = fixLocalIdents(cache,env,elts,ht);
      then (cache,(elt,mod,true)::elts);
    case (cache,env,(elt,mod,true)::elts,ht)
      equation
        (cache,elts) = fixLocalIdents(cache,env,elts,ht);
      then (cache,(elt,mod,true)::elts);
    case (_,_,_,_)
      equation
        Debug.traceln("fixLocalIdents failed");
      then fail();
  end matchcontinue;
end fixLocalIdents;

protected function fixElement
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache cache;
  input Env.Env env;
  input SCode.Element elt;
  input HashTableStringToPath.HashTable ht;
  output Env.Cache outCache;
  output SCode.Element outElts;
algorithm
  (outCache,outElts) := matchcontinue (cache,env,elt,ht)
    local
      String id,name,component;
      Absyn.InnerOuter innerOuter;
      Boolean finalPrefix,replaceablePrefix,protectedPrefix,partialPrefix,redeclarePrefix;
      SCode.Attributes attributes;
      Absyn.TypeSpec typeSpec;
      SCode.Mod modifications;
      Option<SCode.Comment> comment;
      Option<Absyn.Exp> condition;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> cc;
      SCode.ClassDef classDef;
      SCode.Restriction restriction;
      Option<SCode.Annotation> optAnnotation;
      Absyn.Path extendsPath;
    
    case (cache,env,SCode.COMPONENT(component, innerOuter, finalPrefix, replaceablePrefix, protectedPrefix, redeclarePrefix, attributes, typeSpec, modifications, comment, condition, info, cc),ht)
      equation
        //Debug.fprintln("debug","fix comp " +& SCode.printElementStr(elt));
        (cache,modifications) = fixModifications(cache,env,modifications,ht);
        (cache,typeSpec) = fixTypeSpec(cache,env,typeSpec,ht);
      then (cache,SCode.COMPONENT(component, innerOuter, finalPrefix, replaceablePrefix, protectedPrefix, redeclarePrefix, attributes, typeSpec, modifications, comment, condition, info, cc));
    case (cache,env,SCode.CLASSDEF(id,finalPrefix,replaceablePrefix,redeclarePrefix,SCode.CLASS(name,partialPrefix,true,restriction,classDef,info),cc),ht)
      equation
        //Debug.fprintln("debug","fixClassdef " +& id);
        (cache,env) = Builtin.initialEnv(cache);
        (cache,classDef) = fixClassdef(cache,env,classDef,ht);
      then (cache,SCode.CLASSDEF(id,finalPrefix,replaceablePrefix,redeclarePrefix,SCode.CLASS(name,partialPrefix,true,restriction,classDef,info),cc));
    case (cache,env,SCode.CLASSDEF(id,finalPrefix,replaceablePrefix,redeclarePrefix,SCode.CLASS(name,partialPrefix,false,restriction,classDef,info),cc),ht)
      equation
        //Debug.fprintln("debug","fixClassdef " +& id);
        (cache,classDef) = fixClassdef(cache,env,classDef,ht);
      then (cache,SCode.CLASSDEF(id,finalPrefix,replaceablePrefix,redeclarePrefix,SCode.CLASS(name,partialPrefix,false,restriction,classDef,info),cc));
    case (cache,env,SCode.EXTENDS(extendsPath,modifications,optAnnotation,info),ht)
      equation
        //Debug.fprintln("debug","fix extends " +& SCode.printElementStr(elt));
        (cache,modifications) = fixModifications(cache,env,modifications,ht);
      then (cache,SCode.EXTENDS(extendsPath,modifications,optAnnotation,info));
    case (cache,env,SCode.IMPORT(imp = _),ht) then (cache,elt);

    case (cache,env,elt,ht)
      equation
        Debug.fprintln("failtrace", "InstExtends.fixElement failed: " +& SCode.printElementStr(elt));
      then fail();
  end matchcontinue;
end fixElement;

protected function fixClassdef
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache cache;
  input Env.Env env;
  input SCode.ClassDef cd;
  input HashTableStringToPath.HashTable ht;
  output Env.Cache outCache;
  output SCode.ClassDef outCd;
algorithm
  (outCache,outCd) := match (cache,env,cd,ht)
    local
      list<SCode.Element> elts;
      list<SCode.Equation> ne,ie;
      list<SCode.AlgorithmSection> na,ia;
      Option<Absyn.ExternalDecl> ed;
      list<SCode.Annotation> ann;
      Option<SCode.Comment> c;
      Absyn.TypeSpec ts;
      Absyn.ElementAttributes attr;
      String name;
      SCode.Mod mod;
    case (cache,env,SCode.PARTS(elts,ne,ie,na,ia,ed,ann,c),ht)
      equation
        (cache,elts) = fixList(cache,env,elts,ht,fixElement);
        (cache,ne) = fixList(cache,env,ne,ht,fixEquation);
        (cache,ie) = fixList(cache,env,ie,ht,fixEquation);
        (cache,na) = fixList(cache,env,na,ht,fixAlgorithm);
        (cache,ia) = fixList(cache,env,ia,ht,fixAlgorithm);
      then (cache,SCode.PARTS(elts,ne,ie,na,ia,ed,ann,c));
        
    case (cache,env,SCode.CLASS_EXTENDS(name,mod,elts,ne,ie,na,ia,ann,c),ht)
      equation
        (cache,mod) = fixModifications(cache,env,mod,ht);
        (cache,elts) = fixList(cache,env,elts,ht,fixElement);
        (cache,ne) = fixList(cache,env,ne,ht,fixEquation);
        (cache,ie) = fixList(cache,env,ie,ht,fixEquation);
        (cache,na) = fixList(cache,env,na,ht,fixAlgorithm);
        (cache,ia) = fixList(cache,env,ia,ht,fixAlgorithm);
      then (cache,SCode.CLASS_EXTENDS(name,mod,elts,ne,ie,na,ia,ann,c));

    case (cache,env,SCode.DERIVED(ts,mod,attr,c),ht)
      equation
        (cache,ts) = fixTypeSpec(cache,env,ts,ht);
        (cache,mod) = fixModifications(cache,env,mod,ht);
      then (cache,SCode.DERIVED(ts,mod,attr,c));

    case (cache,env,SCode.ENUMERATION(comment = _),ht) then (cache,cd);
    case (cache,env,SCode.OVERLOAD(comment = _),ht) then (cache,cd);
    case (cache,env,SCode.PDER(comment = _),ht) then (cache,cd);

  end match;
end fixClassdef;

protected function fixEquation
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache cache;
  input Env.Env env;
  input SCode.Equation eq;
  input HashTableStringToPath.HashTable ht;
  output Env.Cache outCache;
  output SCode.Equation outEq;
algorithm
  (outCache,outEq) := match (cache,env,eq,ht)
    local
      SCode.EEquation eeq;
    case (cache,env,SCode.EQUATION(eeq),ht)
      equation
        (cache,eeq) = fixEEquation(cache,env,eeq,ht);
      then (cache,SCode.EQUATION(eeq));
  end match;
end fixEquation;

protected function fixEEquation
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache cache;
  input Env.Env env;
  input SCode.EEquation eeq;
  input HashTableStringToPath.HashTable ht;
  output Env.Cache outCache;
  output SCode.EEquation outEeq;
algorithm
  (outCache,outEeq) := match (cache,env,eeq,ht)
    local
      String id;
      Absyn.ComponentRef cref,cref1,cref2;
      Absyn.Exp exp,exp1,exp2;
      list<Absyn.Exp> expl;
      list<SCode.EEquation> eql;
      list<list<SCode.EEquation>> eqll;
      list<tuple<Absyn.Exp, list<SCode.EEquation>>> whenlst;
      Option<SCode.Comment> comment;
      Absyn.FunctionArgs fargs;
      Absyn.Info info;
    case (cache,env,SCode.EQ_IF(expl,eqll,eql,comment,info),ht)
      equation
        (cache,expl) = fixList(cache,env,expl,ht,fixExp);
        (cache,eqll) = fixListList(cache,env,eqll,ht,fixEEquation);
        (cache,eql) = fixList(cache,env,eql,ht,fixEEquation);
      then (cache,SCode.EQ_IF(expl,eqll,eql,comment,info));
    case (cache,env,SCode.EQ_EQUALS(exp1,exp2,comment,info),ht)
      equation
        (cache,exp1) = fixExp(cache,env,exp1,ht);
        (cache,exp2) = fixExp(cache,env,exp2,ht);
      then (cache,SCode.EQ_EQUALS(exp1,exp2,comment,info));
    case (cache,env,SCode.EQ_CONNECT(cref1,cref2,comment,info),ht)
      equation
        (cache,cref1) = fixCref(cache,env,cref1,ht);
        (cache,cref2) = fixCref(cache,env,cref2,ht);
      then (cache,SCode.EQ_CONNECT(cref1,cref2,comment,info));
    case (cache,env,SCode.EQ_FOR(id,exp,eql,comment,info),ht)
      equation
        (cache,exp) = fixExp(cache,env,exp,ht);
        (cache,eql) = fixList(cache,env,eql,ht,fixEEquation);
      then (cache,SCode.EQ_FOR(id,exp,eql,comment,info));
    case (cache,env,SCode.EQ_WHEN(exp,eql,whenlst,comment,info),ht)
      equation
        (cache,exp) = fixExp(cache,env,exp,ht);
        (cache,eql) = fixList(cache,env,eql,ht,fixEEquation);
        (cache,whenlst) = fixListTuple2(cache,env,whenlst,ht,fixExp,fixListEEquation);
      then (cache,SCode.EQ_WHEN(exp,eql,whenlst,comment,info));
    case (cache,env,SCode.EQ_ASSERT(exp1,exp2,comment,info),ht)
      equation
        (cache,exp1) = fixExp(cache,env,exp1,ht);
        (cache,exp2) = fixExp(cache,env,exp2,ht);
      then (cache,SCode.EQ_ASSERT(exp1,exp2,comment,info));
    case (cache,env,SCode.EQ_TERMINATE(exp,comment,info),ht)
      equation
        (cache,exp) = fixExp(cache,env,exp,ht);
      then (cache,SCode.EQ_TERMINATE(exp,comment,info));
    case (cache,env,SCode.EQ_REINIT(cref,exp,comment,info),ht)
      equation
        (cache,cref) = fixCref(cache,env,cref,ht);
        (cache,exp) = fixExp(cache,env,exp,ht);
      then (cache,SCode.EQ_REINIT(cref,exp,comment,info));
    case (cache,env,SCode.EQ_NORETCALL(cref,fargs,comment,info),ht)
      equation
        (cache,fargs) = fixFarg(cache,env,fargs,ht);
        (cache,cref) = fixCref(cache,env,cref,ht);
      then (cache,SCode.EQ_NORETCALL(cref,fargs,comment,info));
  end match;
end fixEEquation;

protected function fixListEEquation
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache cache;
  input Env.Env env;
  input list<SCode.EEquation> eeq;
  input HashTableStringToPath.HashTable ht;
  output Env.Cache outCache;
  output list<SCode.EEquation> outEeq;
algorithm
  (outCache,outEeq) := fixList(cache,env,eeq,ht,fixEEquation);
end fixListEEquation;

protected function fixAlgorithm
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache cache;
  input Env.Env env;
  input SCode.AlgorithmSection alg;
  input HashTableStringToPath.HashTable ht;
  output Env.Cache outCache;
  output SCode.AlgorithmSection outAlg;
algorithm
  (outCache,outAlg) := match (cache,env,alg,ht)
    local
      list<SCode.Statement> stmts;
    case (cache,env,SCode.ALGORITHM(stmts),ht)
      equation
        (cache,stmts) = fixList(cache,env,stmts,ht,fixStatement);
      then (cache,SCode.ALGORITHM(stmts));
  end match;
end fixAlgorithm;

protected function fixListAlgorithmItem
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache cache;
  input Env.Env env;
  input list<SCode.Statement> alg;
  input HashTableStringToPath.HashTable ht;
  output Env.Cache outCache;
  output list<SCode.Statement> outAlg;
algorithm
  (outCache,outAlg) := fixList(cache,env,alg,ht,fixStatement);
end fixListAlgorithmItem;

protected function fixStatement
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache cache;
  input Env.Env env;
  input SCode.Statement stmt;
  input HashTableStringToPath.HashTable ht;
  output Env.Cache outCache;
  output SCode.Statement outStmt;
algorithm
  (outCache,outStmt) := matchcontinue (cache,env,stmt,ht)
    local
      Absyn.Exp exp,exp1,exp2;
      Absyn.ComponentRef cref;
      Absyn.FunctionArgs fargs;
      list<tuple<Absyn.Exp, list<SCode.Statement>>> elseifbranch,whenlst;
      list<SCode.Statement> truebranch,elsebranch,forbody;
      Absyn.ForIterators iterators;
      Option<SCode.Comment> comment;
      Absyn.Info info;
    case (cache,env,SCode.ALG_ASSIGN(exp1,exp2,comment,info),ht)
      equation
        (cache,exp1) = fixExp(cache,env,exp1,ht);
        (cache,exp2) = fixExp(cache,env,exp2,ht);
      then (cache,SCode.ALG_ASSIGN(exp1,exp2,comment,info));
    case (cache,env,SCode.ALG_IF(exp,truebranch,elseifbranch,elsebranch,comment,info),ht)
      equation
        (cache,exp) = fixExp(cache,env,exp,ht);
        (cache,truebranch) = fixList(cache,env,truebranch,ht,fixStatement);
        (cache,elseifbranch) = fixListTuple2(cache,env,elseifbranch,ht,fixExp,fixListAlgorithmItem);
        (cache,elsebranch) = fixList(cache,env,elsebranch,ht,fixStatement);
      then (cache,SCode.ALG_IF(exp,truebranch,elseifbranch,elsebranch,comment,info));
    case (cache,env,SCode.ALG_FOR(iterators,forbody,comment,info),ht)
      equation
        (cache,iterators) = fixList(cache,env,iterators,ht,fixForIterator);
        (cache,forbody) = fixList(cache,env,forbody,ht,fixStatement);
      then (cache,SCode.ALG_FOR(iterators,forbody,comment,info));
    case (cache,env,SCode.ALG_WHEN_A(whenlst,comment,info),ht)
      equation
        (cache,whenlst) = fixListTuple2(cache,env,whenlst,ht,fixExp,fixListAlgorithmItem);
      then (cache,SCode.ALG_WHEN_A(whenlst,comment,info));
    case (cache,env,SCode.ALG_NORETCALL(cref,fargs,comment,info),ht)
      equation
        (cache,fargs) = fixFarg(cache,env,fargs,ht);
        (cache,cref) = fixCref(cache,env,cref,ht);
      then (cache,SCode.ALG_NORETCALL(cref,fargs,comment,info));
    case (cache,env,SCode.ALG_RETURN(comment,info),ht) then (cache,SCode.ALG_RETURN(comment,info));
    case (cache,env,SCode.ALG_BREAK(comment,info),ht) then (cache,SCode.ALG_BREAK(comment,info));
    case (cache,env,stmt,ht)
      equation
        Debug.fprintln("failtrace", "- Inst.fixStatement failed: " +& Dump.unparseAlgorithmStr(4,SCode.statementToAlgorithmItem(stmt)));
      then fail();
  end matchcontinue;
end fixStatement;

protected function fixArrayDim
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache cache;
  input Env.Env env;
  input Option<Absyn.ArrayDim> ad;
  input HashTableStringToPath.HashTable ht;
  output Env.Cache outCache;
  output Option<Absyn.ArrayDim> outAd;
algorithm
  (outCache,outAd) := match (cache,env,ad,ht)
    local
      list<Absyn.Subscript> ads;
    case (cache,env,NONE(),ht) then (cache,NONE());
    case (cache,env,SOME(ads),ht)
      equation
        (cache,ads) = fixList(cache,env,ads,ht,fixSubscript);
      then (cache,SOME(ads));
  end match;
end fixArrayDim;

protected function fixSubscript
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache cache;
  input Env.Env env;
  input Absyn.Subscript sub;
  input HashTableStringToPath.HashTable ht;
  output Env.Cache outCache;
  output Absyn.Subscript outSub;
algorithm
  (outCache,outSub) := match (cache,env,sub,ht)
    local
      Absyn.Exp exp;
    case (cache,env,Absyn.NOSUB(),ht) then (cache,Absyn.NOSUB());
    case (cache,env,Absyn.SUBSCRIPT(exp),ht)
      equation
        (cache,exp) = fixExp(cache, env, exp, ht);
      then (cache,Absyn.SUBSCRIPT(exp));
  end match;
end fixSubscript;

protected function fixTypeSpec
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache cache;
  input Env.Env env;
  input Absyn.TypeSpec ts;
  input HashTableStringToPath.HashTable ht;
  output Env.Cache outCache;
  output Absyn.TypeSpec outTs;
algorithm
  (outCache,outTs) := match (cache,env,ts,ht)
    local
      Absyn.Path path;
      Option<Absyn.ArrayDim> arrayDim;
      list<Absyn.TypeSpec> typeSpecs;
    case (cache,env,Absyn.TPATH(path,arrayDim),ht)
      equation
        (cache,arrayDim) = fixArrayDim(cache,env,arrayDim,ht);
        (cache,path) = fixPath(cache,env,path,ht);
      then (cache,Absyn.TPATH(path,arrayDim));
    case (cache,env,Absyn.TCOMPLEX(path,typeSpecs,arrayDim),ht)
      equation
        (cache,arrayDim) = fixArrayDim(cache,env,arrayDim,ht);
        (cache,path) = fixPath(cache,env,path,ht);
        (cache,typeSpecs) = fixList(cache,env,typeSpecs,ht,fixTypeSpec);
      then (cache,Absyn.TCOMPLEX(path,typeSpecs,arrayDim));
  end match;
end fixTypeSpec;

protected function fixPath
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache cache;
  input Env.Env env;
  input Absyn.Path path;
  input HashTableStringToPath.HashTable ht;
  output Env.Cache outCache;
  output Absyn.Path outPath;
algorithm
  (outCache,outPath) := matchcontinue (cache,env,path,ht)
    local
      String id;
      Absyn.Path path1,path2;
    case (cache,env,path1 as Absyn.FULLYQUALIFIED(_),ht) then (cache,path1); 
    case (cache,env,path1,ht)
      equation
        id = Absyn.pathFirstIdent(path1);
        path2 = BaseHashTable.get(id,ht);
        path2 = Absyn.pathReplaceFirstIdent(path1,path2);
        //Debug.fprintln("debug","Replacing: " +& Absyn.pathString(path1) +& " with " +& Absyn.pathString(path2) +& " s:" +& Env.printEnvPathStr(env));
      then (cache,path2);
    case (cache,env,path,ht)
      equation
        (cache,path) = Inst.makeFullyQualified(cache,env,path);
      then (cache,path);
    case (cache,env,path,_) then (cache,path);
  end matchcontinue;
end fixPath;

protected function fixCref
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache cache;
  input Env.Env env;
  input Absyn.ComponentRef cref;
  input HashTableStringToPath.HashTable ht;
  output Env.Cache outCache;
  output Absyn.ComponentRef outCref;
algorithm
  (outCache,outCref) := matchcontinue (cache,env,cref,ht)
    local
      String id;
      Absyn.Path path;
      DAE.ComponentRef cref_;
    case (cache,env,cref,ht)
      equation
        id = Absyn.crefFirstIdent(cref);
        //Debug.traceln("Try ht lookup " +& id);
        path = BaseHashTable.get(id,ht);
        //Debug.traceln("Got path " +& Absyn.pathString(path));
      then (cache,Absyn.crefReplaceFirstIdent(cref,path));
    case (cache,env,cref,ht)
      equation
        id = Absyn.crefFirstIdent(cref);
        cref_ = ComponentReference.makeCrefIdent(id,DAE.ET_OTHER(),{});
        //Debug.fprintln("debug","Try lookupV " +& id);
        (_,_,_,_,_,_,env,_,id) = Lookup.lookupVar(cache,env,cref_);
        //Debug.fprintln("debug","Got env " +& intString(listLength(env)));
        env = Env.openScope(env,true,SOME(id),NONE());
      then (cache,Absyn.crefReplaceFirstIdent(cref,Env.getEnvName(env)));
    case (cache,env,cref,ht)
      equation
        id = Absyn.crefFirstIdent(cref);
        //Debug.fprintln("debug","Try lookupC " +& id);
        (_,_,env) = Lookup.lookupClass(cache,env,Absyn.IDENT(id),false);
        //Debug.fprintln("debug","Got env " +& intString(listLength(env)));
        env = Env.openScope(env,true,SOME(id),NONE());
      then (cache,Absyn.crefReplaceFirstIdent(cref,Env.getEnvName(env)));
    case (cache,env,cref,_) then (cache,cref);
  end matchcontinue;
end fixCref;

protected function fixModifications
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache cache;
  input Env.Env env;
  input SCode.Mod mod;
  input HashTableStringToPath.HashTable ht;
  output Env.Cache outCache;
  output SCode.Mod outMod;
algorithm
  (outCache,outMod) := matchcontinue (cache,env,mod,ht)
    local
      Boolean finalPrefix "final" ;
      Absyn.Each eachPrefix;
      list<SCode.SubMod> subModLst;
      Absyn.Exp exp;
      Boolean b;
    case (cache,env,SCode.NOMOD(),ht) then (cache,SCode.NOMOD());
    case (cache,env,SCode.MOD(finalPrefix,eachPrefix,subModLst,SOME((exp,b))),ht)
      equation
        (cache,exp) = fixExp(cache,env,exp,ht);
      then (cache,SCode.MOD(finalPrefix,eachPrefix,subModLst,SOME((exp,b))));
    case (cache,env,SCode.MOD(finalPrefix,eachPrefix,subModLst,NONE()),ht)
      equation
        (cache, subModLst) = fixSubModList(cache, env, subModLst, ht);
      then (cache,SCode.MOD(finalPrefix,eachPrefix,subModLst,NONE()));
    case (cache,env,SCode.MOD(finalPrefix,eachPrefix,subModLst,NONE()),ht) then (cache,SCode.MOD(finalPrefix,eachPrefix,subModLst,NONE()));
  end matchcontinue;
end fixModifications;

protected function fixSubModList
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache cache;
  input Env.Env env;
  input list<SCode.SubMod> inSubMods;
  input HashTableStringToPath.HashTable ht;
  output Env.Cache outCache;
  output list<SCode.SubMod> outSubMods;
algorithm
  (outCache, outSubMods) := match (cache, env, inSubMods, ht)
    local
      SCode.Mod mod;
      list<SCode.SubMod> rest_mods;
      Absyn.Ident ident;
      list<SCode.Subscript> subs;
    case (_, _, {}, _) then (cache, {});
    case (_, _, SCode.NAMEMOD(ident = ident, A = mod) :: rest_mods, _)
      equation
        (cache, mod) = fixModifications(cache, env, mod, ht);
        (cache, rest_mods) = fixSubModList(cache, env, rest_mods, ht);
      then
        (cache, SCode.NAMEMOD(ident, mod) :: rest_mods);
    case (_, _, SCode.IDXMOD(subscriptLst = subs, an = mod) :: rest_mods, _)
      equation
        (cache, mod) = fixModifications(cache, env, mod, ht);
        (cache, rest_mods) = fixSubModList(cache, env, rest_mods, ht);
      then
        (cache, SCode.IDXMOD(subs, mod) :: rest_mods);
  end match;
end fixSubModList;
           
protected function fixExp
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache cache;
  input Env.Env env;
  input Absyn.Exp exp;
  input HashTableStringToPath.HashTable ht;
  output Env.Cache outCache;
  output Absyn.Exp outExp;
algorithm
  (outCache,outExp) := matchcontinue (cache,env,exp,ht)
    local
      Absyn.ComponentRef cref;
      Absyn.FunctionArgs fargs;
      Absyn.Exp exp1,exp2,ifexp,truebranch,elsebranch;
      list<Absyn.Exp> expl;
      Option<Absyn.Exp> optExp;
      list<list<Absyn.Exp>> expll;
      list<tuple<Absyn.Exp,Absyn.Exp>> elseifbranches;
      Absyn.Operator op;
    case (cache,env,Absyn.CREF(cref),ht)
      equation
        (cache,cref) = fixCref(cache,env,cref,ht);
      then (cache,Absyn.CREF(cref));
    case (cache,env,Absyn.CALL(cref,fargs),ht)
      equation
        (cache,fargs) = fixFarg(cache,env,fargs,ht);
        (cache,cref) = fixCref(cache,env,cref,ht);
      then (cache,Absyn.CALL(cref,fargs));
    case (cache,env,Absyn.BINARY(exp1,op,exp2),ht)
      equation
        (cache,exp1) = fixExp(cache,env,exp1,ht);
        (cache,exp2) = fixExp(cache,env,exp2,ht);
      then (cache,Absyn.BINARY(exp1,op,exp2));
    case (cache,env,Absyn.UNARY(op,exp),ht)
      equation
        (cache,exp) = fixExp(cache,env,exp,ht);
      then (cache,Absyn.UNARY(op,exp));
    case (cache,env,Absyn.LBINARY(exp1,op,exp2),ht)
      equation
        (cache,exp1) = fixExp(cache,env,exp1,ht);
        (cache,exp2) = fixExp(cache,env,exp2,ht);
      then (cache,Absyn.LBINARY(exp1,op,exp2));
    case (cache,env,Absyn.LUNARY(op,exp),ht)
      equation
        (cache,exp) = fixExp(cache,env,exp,ht);
      then (cache,Absyn.LUNARY(op,exp));
    case (cache,env,Absyn.RELATION(exp1,op,exp2),ht)
      equation
        (cache,exp1) = fixExp(cache,env,exp1,ht);
        (cache,exp2) = fixExp(cache,env,exp2,ht);
      then (cache,Absyn.RELATION(exp1,op,exp2));
    case (cache,env,Absyn.IFEXP(ifexp,truebranch,elsebranch,elseifbranches),ht)
      equation
        (cache,ifexp) = fixExp(cache,env,ifexp,ht);
        (cache,truebranch) = fixExp(cache,env,truebranch,ht);
        (cache,elsebranch) = fixExp(cache,env,elsebranch,ht);
        (cache,elseifbranches) = fixListTuple2(cache,env,elseifbranches,ht,fixExp,fixExp);
      then (cache,Absyn.IFEXP(ifexp,truebranch,elsebranch,elseifbranches));
    case (cache,env,Absyn.ARRAY(expl),ht)
      equation
        (cache,expl) = fixList(cache,env,expl,ht,fixExp);
      then (cache,Absyn.ARRAY(expl));
    case (cache,env,Absyn.MATRIX(expll),ht)
      equation
        (cache,expll) = fixListList(cache,env,expll,ht,fixExp);
      then (cache,Absyn.MATRIX(expll));
    case (cache,env,Absyn.RANGE(exp1,optExp,exp2),ht)
      equation
        (cache,exp1) = fixExp(cache,env,exp1,ht);
        (cache,exp2) = fixExp(cache,env,exp2,ht);
        (cache,optExp) = fixOption(cache,env,optExp,ht,fixExp);
      then (cache,Absyn.RANGE(exp1,optExp,exp2));
    case (cache,env,Absyn.TUPLE(expl),ht)
      equation
        (cache,expl) = fixList(cache,env,expl,ht,fixExp);
      then (cache,Absyn.TUPLE(expl));
    case (cache,env,Absyn.INTEGER(_),ht) then (cache,exp);
    case (cache,env,Absyn.REAL(_),ht) then (cache,exp);
    case (cache,env,Absyn.STRING(_),ht) then (cache,exp);
    case (cache,env,Absyn.BOOL(_),ht) then (cache,exp);
    case (cache,env,exp,ht)
      equation
        Debug.fprintln("failtrace","InstExtends.fixExp failed: " +& Dump.printExpStr(exp));
      then fail();
  end matchcontinue;
end fixExp;

protected function fixFarg
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache cache;
  input Env.Env env;
  input Absyn.FunctionArgs fargs;
  input HashTableStringToPath.HashTable ht;
  output Env.Cache outCache;
  output Absyn.FunctionArgs outFarg;
algorithm
  (outCache,outFarg) := match (cache,env,fargs,ht)
    local
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> argNames;
      Absyn.ForIterators iterators;
      Absyn.Exp exp;
    case (cache,env,Absyn.FUNCTIONARGS(args,argNames),ht)
      equation
        (cache,args) = fixList(cache,env,args,ht,fixExp);
        (cache,argNames) = fixList(cache,env,argNames,ht,fixNamedArg);
      then (cache,Absyn.FUNCTIONARGS(args,argNames));
    case (cache,env,Absyn.FOR_ITER_FARG(exp,iterators),ht)
      equation
        (cache,exp) = fixExp(cache,env,exp,ht);
        (cache,iterators) = fixList(cache,env,iterators,ht,fixForIterator);
      then (cache,Absyn.FOR_ITER_FARG(exp,iterators));
  end match;
end fixFarg;

protected function fixForIterator
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache cache;
  input Env.Env env;
  input Absyn.ForIterator iter;
  input HashTableStringToPath.HashTable ht;
  output Env.Cache outCache;
  output Absyn.ForIterator outIter;
algorithm
  (outCache,outIter) := match (cache,env,iter,ht)
    local
      String id;
      Absyn.Exp exp;
      Option<Absyn.Exp> guardExp;
    case (cache,env,Absyn.ITERATOR(id,guardExp,SOME(exp)),ht)
      equation
        (cache,exp) = fixExp(cache,env,exp,ht);
        (cache,guardExp) = fixOption(cache,env,guardExp,ht,fixExp);
      then (cache,Absyn.ITERATOR(id,guardExp,SOME(exp)));
    case (cache,env,iter,ht) then (cache,iter);
  end match;
end fixForIterator;

protected function fixNamedArg
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache cache;
  input Env.Env env;
  input Absyn.NamedArg narg;
  input HashTableStringToPath.HashTable ht;
  output Env.Cache outCache;
  output Absyn.NamedArg outNarg;
algorithm
  (outCache,outNarg) := match (cache,env,narg,ht)
    local
      String id;
      Absyn.Exp exp;
    case (cache,env,Absyn.NAMEDARG(id,exp),ht)
      equation
        (cache,exp) = fixExp(cache,env,exp,ht);
      then (cache,Absyn.NAMEDARG(id,exp));
  end match;
end fixNamedArg;

protected function fixOption
" Generic function to fix an optional element."
  input Env.Cache cache;
  input Env.Env env;
  input Option<Type_A> inA;
  input HashTableStringToPath.HashTable ht;
  input FixAFn fixA;
  output Env.Cache outCache;
  output Option<Type_A> outA;
  
  replaceable type Type_A subtypeof Any;
  partial function FixAFn
    input Env.Cache cache;
    input Env.Env env;
    input Type_A inA;
    input HashTableStringToPath.HashTable ht;
    output Env.Cache outCache;
    output Type_A outTypeA;
  end FixAFn;
algorithm
  (outCache,outA) := match (cache,env,inA,ht,fixA)
    local
      Type_A A;
    case (cache,env,NONE(),ht,fixA) then (cache,NONE());
    case (cache,env,SOME(A),ht,fixA)
      equation
        (cache,A) = fixA(cache,env,A,ht);
      then (cache,SOME(A));
  end match;
end fixOption;

protected function fixList
" Generic function to fix a list of elements."
  input Env.Cache cache;
  input Env.Env env;
  input list<Type_A> inA;
  input HashTableStringToPath.HashTable ht;
  input FixAFn fixA;
  output Env.Cache outCache;
  output list<Type_A> outA;
  
  replaceable type Type_A subtypeof Any;
  partial function FixAFn
    input Env.Cache cache;
    input Env.Env env;
    input Type_A inA;
    input HashTableStringToPath.HashTable ht;
    output Env.Cache outCache;
    output Type_A outTypeA;
  end FixAFn;
algorithm
  (outCache,outA) := match (cache,env,inA,ht,fixA)
    local
      Type_A A;
    case (cache,env,{},ht,fixA) then (cache,{});
    case (cache,env,A::inA,ht,fixA)
      equation
        (cache,A) = fixA(cache,env,A,ht);
        (cache,inA) = fixList(cache,env,inA,ht,fixA);
      then (cache,A::inA);
  end match;
end fixList;

protected function fixListList
" Generic function to fix a list of elements."
  input Env.Cache cache;
  input Env.Env env;
  input list<list<Type_A>> inA;
  input HashTableStringToPath.HashTable ht;
  input FixAFn fixA;
  output Env.Cache outCache;
  output list<list<Type_A>> outA;
  
  replaceable type Type_A subtypeof Any;
  partial function FixAFn
    input Env.Cache cache;
    input Env.Env env;
    input Type_A inA;
    input HashTableStringToPath.HashTable ht;
    output Env.Cache outCache;
    output Type_A outTypeA;
  end FixAFn;
algorithm
  (outCache,outA) := match (cache,env,inA,ht,fixA)
    local
      list<Type_A> A;
    case (cache,env,{},ht,fixA) then (cache,{});
    case (cache,env,A::inA,ht,fixA)
      equation
        (cache,A) = fixList(cache,env,A,ht,fixA);
        (cache,inA) = fixListList(cache,env,inA,ht,fixA);
      then (cache,A::inA);
  end match;
end fixListList;

protected function fixListTuple2
" Generic function to fix a list of elements."
  input Env.Cache cache;
  input Env.Env env;
  input list<tuple<Type_A,Type_B>> rest;
  input HashTableStringToPath.HashTable ht;
  input FixAFn fixA;
  input FixBFn fixB;
  output Env.Cache outCache;
  output list<tuple<Type_A,Type_B>> outA;
  
  replaceable type Type_A subtypeof Any;
  replaceable type Type_B subtypeof Any;
  partial function FixAFn
    input Env.Cache cache;
    input Env.Env env;
    input Type_A inA;
    input HashTableStringToPath.HashTable ht;
    output Env.Cache outCache;
    output Type_A outLst;
  end FixAFn;
  partial function FixBFn
    input Env.Cache cache;
    input Env.Env env;
    input Type_B inA;
    input HashTableStringToPath.HashTable ht;
    output Env.Cache outCache;
    output Type_B outTypeA;
  end FixBFn;
algorithm
  (outCache,outA) := match (cache,env,rest,ht,fixA,fixB)
    local
      Type_A a;
      Type_B b;
    case (cache,env,{},ht,fixA,fixB) then (cache,{});
    case (cache,env,(a,b)::rest,ht,fixA,fixB)
      equation
        (cache,a) = fixA(cache,env,a,ht);
        (cache,b) = fixB(cache,env,b,ht);
        (cache,rest) = fixListTuple2(cache,env,rest,ht,fixA,fixB); 
      then (cache,(a,b)::rest);
  end match;
end fixListTuple2;

end InstExtends;
