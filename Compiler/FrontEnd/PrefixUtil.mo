/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
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
 * from Linköping University, either from the above address,
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

encapsulated package PrefixUtil
" file:         PrefixUtil.mo
  package:     PrefixUtil
  description: PrefixUtil management

  RCS: $Id$

  When instantiating an expression, there is a prefix that
  has to be added to each variable name to be able to use it in the
  flattened equation set.

  A prefix for a variable x could be for example a.b.c so that the
  fully qualified name is a.b.c.x."


public import Absyn;
public import DAE;
public import Env;
public import Lookup;
public import SCode;
public import Prefix;
public import InnerOuter;
public import ClassInf;
public import Values;

type InstanceHierarchy = InnerOuter.InstHierarchy "an instance hierarchy";

protected import ComponentReference;
protected import Debug;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
protected import List;
protected import Print;
//protected import Util;
protected import System;

public function printPrefixStr "function: printPrefixStr
  Prints a Prefix to a string."
  input Prefix.Prefix inPrefix;
  output String outString;
algorithm
  outString :=  matchcontinue (inPrefix)
    local
      String str,s,rest_1,s_1,s_2;
      Prefix.ComponentPrefix rest;
      Prefix.ClassPrefix cp;
      list<DAE.Subscript> ss;
      
    case Prefix.NOPRE() then "<Prefix.NOPRE()>";
    case Prefix.PREFIX(Prefix.NOCOMPPRE(),_) then "<Prefix.PREFIX(Prefix.NOCOMPPRE())>";
    case Prefix.PREFIX(Prefix.PRE(str,{},Prefix.NOCOMPPRE(),_),_) then str;
    case Prefix.PREFIX(Prefix.PRE(str,ss,Prefix.NOCOMPPRE(),_),_)
      equation
        s = stringAppend(str, "[" +& stringDelimitList(
          List.map(ss, ExpressionDump.subscriptString), ", ") +& "]");
      then
        s;
    case Prefix.PREFIX(Prefix.PRE(str,{},rest,_),cp)
      equation
        rest_1 = printPrefixStr(Prefix.PREFIX(rest,cp));
        s = stringAppend(rest_1, ".");
        s_1 = stringAppend(s, str);
      then
        s_1;
    case Prefix.PREFIX(Prefix.PRE(str,ss,rest,_),cp)
      equation
        rest_1 = printPrefixStr(Prefix.PREFIX(rest,cp));
        s = stringAppend(rest_1, ".");
        s_1 = stringAppend(s, str);
        s_2 = stringAppend(s_1, "[" +& stringDelimitList(
          List.map(ss, ExpressionDump.subscriptString), ", ") +& "]");
      then
        s_2;
  end matchcontinue;
end printPrefixStr;

public function printPrefixStr2 "function: printPrefixStr2
  Prints a Prefix to a string. Designed to be used in Error messages to produce qualified component names"
  input Prefix.Prefix inPrefix;
  output String outString;
algorithm
  outString :=  matchcontinue (inPrefix)
  local 
    Prefix.Prefix p;
  case Prefix.NOPRE() then "";
  case Prefix.PREFIX(Prefix.NOCOMPPRE(),_) then "";
  case p then printPrefixStr(p)+&".";
  end matchcontinue;
end printPrefixStr2;

public function printPrefixStr3 "function: printPrefixStr2
  Prints a Prefix to a string as a component name. Designed to be used in Error messages"
  input Prefix.Prefix inPrefix;
  output String outString;
algorithm
  outString :=  matchcontinue (inPrefix)
  local 
    Prefix.Prefix p;
  case Prefix.NOPRE() then "<NO COMPONENT>";
  case Prefix.PREFIX(Prefix.NOCOMPPRE(),_) then "<NO COMPONENT>";
  case p then printPrefixStr(p);
  end matchcontinue;
end printPrefixStr3;

public function printPrefixStrIgnoreNoPre "function: printPrefixStrIgnoreNoPre
  Prints a Prefix to a string as a component name. Designed to be used in Error messages"
  input Prefix.Prefix inPrefix;
  output String outString;
algorithm
  outString :=  matchcontinue (inPrefix)
  local 
    Prefix.Prefix p;
  case Prefix.NOPRE() then "";
  case Prefix.PREFIX(Prefix.NOCOMPPRE(),_) then "";
  case p then printPrefixStr(p);
  end matchcontinue;
end printPrefixStrIgnoreNoPre;

public function printPrefix "function: printPrefix
  Prints a prefix to the Print buffer."
  input Prefix.Prefix p;
  String s;
algorithm
  s := printPrefixStr(p);
  Print.printBuf(s);
end printPrefix;

public function prefixAdd "function: prefixAdd
  This function is used to extend a prefix with another level.  If
  the prefix `a.b{10}.c\' is extended with `d\' and an empty subscript
  list, the resulting prefix is `a.b{10}.c.d\'.  Remember that
  prefixes components are stored in the opposite order from the
  normal order used when displaying them."
  input String inIdent;
  input list<DAE.Subscript> inIntegerLst;
  input Prefix.Prefix inPrefix;
  input SCode.Variability vt;
  input ClassInf.State ci_state;
  output Prefix.Prefix outPrefix;
algorithm
  outPrefix := match (inIdent,inIntegerLst,inPrefix,vt,ci_state)
    local
      String i;
      list<DAE.Subscript> s;
      Prefix.ComponentPrefix p;
      
    case (i,s,Prefix.PREFIX(p,_),vt,ci_state) 
      then Prefix.PREFIX(Prefix.PRE(i,s,p,ci_state),Prefix.CLASSPRE(vt));
    
    case(i,s,Prefix.NOPRE(),vt,ci_state) 
      then Prefix.PREFIX(Prefix.PRE(i,s,Prefix.NOCOMPPRE(),ci_state),Prefix.CLASSPRE(vt));
  end match;
end prefixAdd;

public function prefixFirst
  input Prefix.Prefix inPrefix;
  output Prefix.Prefix outPrefix;
algorithm
  outPrefix := match (inPrefix)
    local
      String a;
      list<DAE.Subscript> b;
      Prefix.ClassPrefix cp;
      Prefix.ComponentPrefix c;
      ClassInf.State ci_state;
    case (Prefix.PREFIX(Prefix.PRE(prefix = a,subscripts = b,next = c,ci_state=ci_state),cp)) 
      then Prefix.PREFIX(Prefix.PRE(a,b,Prefix.NOCOMPPRE(),ci_state),cp);
  end match;
end prefixFirst;

public function prefixFirstCref
  "Returns the first cref in the prefix."
  input Prefix.Prefix inPrefix;
  output DAE.ComponentRef outCref;
protected
  String name;
  list<DAE.Subscript> subs;
algorithm
  Prefix.PREFIX(compPre = Prefix.PRE(prefix = name, subscripts = subs)) := inPrefix;
  outCref := DAE.CREF_IDENT(name, DAE.T_UNKNOWN_DEFAULT, subs);
end prefixFirstCref;

public function prefixLast "function: prefixLast
  Returns the last NONPRE Prefix of a prefix"
  input Prefix.Prefix inPrefix;
  output Prefix.Prefix outPrefix;
algorithm
  outPrefix := matchcontinue (inPrefix)
    local 
      Prefix.ComponentPrefix p;
      Prefix.Prefix res;
      Prefix.ClassPrefix cp;
    
    case ((res as Prefix.PREFIX(Prefix.PRE(next = Prefix.NOCOMPPRE()),cp))) then res;
    
    case (Prefix.PREFIX(Prefix.PRE(next = p),cp))
      equation
        res = prefixLast(Prefix.PREFIX(p,cp));
      then
        res;
  end matchcontinue;
end prefixLast;

public function prefixStripLast
"@author: adrpo
 remove the last prefix from the component prefix"
  input Prefix.Prefix inPrefix;
  output Prefix.Prefix outPrefix;
algorithm
  outPrefix := match (inPrefix)
    local
      Prefix.ClassPrefix cp;
      Prefix.ComponentPrefix compPre;
    // we can't remove what it isn't there!
    case (Prefix.NOPRE()) then Prefix.NOPRE();
    // if there isn't any next prefix, return Prefix.NOPRE!
    case (Prefix.PREFIX(compPre,cp))
      equation
         compPre = compPreStripLast(compPre);
      then Prefix.PREFIX(compPre,cp);
  end match;
end prefixStripLast;

protected function compPreStripLast
"@author: adrpo
 remove the last prefix from the component prefix"
  input Prefix.ComponentPrefix inCompPrefix;
  output Prefix.ComponentPrefix outCompPrefix;
algorithm
  outCompPrefix := match(inCompPrefix)
    local
      Prefix.ComponentPrefix next;

    // nothing to remove!
    case Prefix.NOCOMPPRE() then Prefix.NOCOMPPRE();
    // we have something
    case Prefix.PRE(next = next) then next;
   end match;
end compPreStripLast;

public function prefixPath "function: prefixPath
  Prefix a Path variable by adding the supplied 
  prefix to it and returning a new Path."
  input Absyn.Path inPath;
  input Prefix.Prefix inPrefix;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue (inPath,inPrefix)
    local
      Absyn.Path p,p_1;
      String s;
      Prefix.ComponentPrefix ss;
      Prefix.ClassPrefix cp;
    
    case (p,Prefix.NOPRE()) then p;
    case (p,Prefix.PREFIX(Prefix.PRE(prefix = s,next = Prefix.NOCOMPPRE()),cp))
      equation
        p_1 = Absyn.QUALIFIED(s,p);
      then
        p_1;
    case (p,Prefix.PREFIX(Prefix.PRE(prefix = s,next = ss),cp))
      equation
        p_1 = prefixPath(Absyn.QUALIFIED(s,p), Prefix.PREFIX(ss,cp));
      then
        p_1;
  end matchcontinue;
end prefixPath;

public function prefixToPath "function: prefixToPath
  Convert a Prefix to a Path"
  input Prefix.Prefix inPrefix;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue (inPrefix)
    local
      String s;
      Absyn.Path p;
      Prefix.ComponentPrefix ss;
      Prefix.ClassPrefix cp;
    
    case Prefix.NOPRE()
      equation
        /*Print.printBuf("#-- Error: Cannot convert empty prefix to a path\n");*/
      then
        fail();
    case Prefix.PREFIX(Prefix.PRE(prefix = s,next = Prefix.NOCOMPPRE()),_) then Absyn.IDENT(s);
    case Prefix.PREFIX(Prefix.PRE(prefix = s,next = ss),cp)
      equation
        p = prefixToPath(Prefix.PREFIX(ss,cp));
      then
        Absyn.QUALIFIED(s,p);
  end matchcontinue;
end prefixToPath;

public function prefixCref "function: prefixCref
  Prefix a ComponentRef variable by adding the supplied prefix to
  it and returning a new ComponentRef.
  LS: Changed to call prefixToCref which is more general now"
  input Env.Cache cache;
  input Env.Env env;
  input InstanceHierarchy inIH;
  input Prefix.Prefix pre;
  input DAE.ComponentRef cref;
  output Env.Cache outCache;
  output DAE.ComponentRef cref_1;
algorithm
  (outCache,cref_1) := prefixToCref2(cache,env,inIH,pre, SOME(cref));
end prefixCref;

public function prefixCrefNoContext "function: prefixCrefNoContext
  Prefix a ComponentRef variable by adding the supplied prefix to
  it and returning a new ComponentRef.
  LS: Changed to call prefixToCref which is more general now"
  input Prefix.Prefix inPre;
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef outCref;
algorithm
  (_, outCref) := prefixToCref2(Env.emptyCache(), {}, InnerOuter.emptyInstHierarchy, inPre, SOME(inCref));
end prefixCrefNoContext;

public function prefixToCref "function: prefixToCref
  Convert a prefix to a component reference."
  input Prefix.Prefix pre;
  output DAE.ComponentRef cref_1;
algorithm
  (_,cref_1) := prefixToCref2(Env.emptyCache(),{},InnerOuter.emptyInstHierarchy,pre, NONE());
end prefixToCref;

protected function prefixToCref2 "function: prefixToCref2
  Convert a prefix to a component reference. Converting Prefix.NOPRE with no
  component reference is an error because a component reference cannot be
  empty"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input Option<DAE.ComponentRef> inExpComponentRefOption;
  output Env.Cache outCache;
  output DAE.ComponentRef outComponentRef;
algorithm
  (outCache,outComponentRef) := match (inCache,inEnv,inIH,inPrefix,inExpComponentRefOption)
    local
      DAE.ComponentRef cref,cref_1,cref_2,cref_;
      String i;
      list<DAE.Subscript> s;
      Prefix.ComponentPrefix xs;
      Prefix.ClassPrefix cp;
      ClassInf.State ci_state;
      Env.Cache cache;
      Env.Env env;
    
    case (cache,env,inIH,Prefix.NOPRE(),NONE()) then fail();
    case (cache,env,inIH,Prefix.PREFIX(Prefix.NOCOMPPRE(),_),NONE()) then fail();
      
    case (cache,env,inIH,Prefix.NOPRE(),SOME(cref)) then (cache,cref);
    case (cache,env,inIH,Prefix.PREFIX(Prefix.NOCOMPPRE(),_),SOME(cref)) then (cache,cref);
    case (cache,env,inIH,Prefix.PREFIX(Prefix.PRE(prefix = i,subscripts = s,next = xs,ci_state=ci_state),cp),NONE())
      equation
        cref_ = ComponentReference.makeCrefIdent(i,DAE.T_COMPLEX(ci_state, {}, NONE(), DAE.emptyTypeSource),s);
        (cache,cref_1) = prefixToCref2(cache,env,inIH,Prefix.PREFIX(xs,cp), SOME(cref_));
      then
        (cache,cref_1);
    case (cache,env,inIH,Prefix.PREFIX(Prefix.PRE(prefix = i,subscripts = s,next = xs,ci_state=ci_state),cp),SOME(cref))
      equation
        (cache,cref) = prefixSubscriptsInCref(cache,env,inIH,inPrefix,cref);
        cref_2 = ComponentReference.makeCrefQual(i,DAE.T_COMPLEX(ci_state, {}, NONE(), DAE.emptyTypeSource),s,cref);
        (cache,cref_1) = prefixToCref2(cache,env,inIH,Prefix.PREFIX(xs,cp), SOME(cref_2));
      then
        (cache,cref_1);
  end match;
end prefixToCref2;

public function prefixToCrefOpt "function: prefixToCref
  Convert a prefix to an optional component reference."
  input Prefix.Prefix pre;
  output Option<DAE.ComponentRef> cref_1;
algorithm
  cref_1 := prefixToCrefOpt2(pre, NONE());
end prefixToCrefOpt;

public function prefixToCrefOpt2 "function: prefixToCrefOpt2
  Convert a prefix to a component reference. Converting Prefix.NOPRE with no
  component reference gives a NONE" 
  input Prefix.Prefix inPrefix;
  input Option<DAE.ComponentRef> inExpComponentRefOption;
  output Option<DAE.ComponentRef> outComponentRefOpt;
algorithm
  outComponentRefOpt := match (inPrefix,inExpComponentRefOption)
    local
      Option<DAE.ComponentRef> cref_1;
      DAE.ComponentRef cref,cref_;
      String i;
      list<DAE.Subscript> s;
      Prefix.ComponentPrefix xs;
      Prefix.ClassPrefix cp;

    case (Prefix.NOPRE(),NONE()) then NONE();
    case (Prefix.NOPRE(),SOME(cref)) then SOME(cref);
    case (Prefix.PREFIX(Prefix.NOCOMPPRE(),_),SOME(cref)) then SOME(cref);
    case (Prefix.PREFIX(Prefix.PRE(prefix = i,subscripts = s,next = xs),cp),NONE())
      equation
        cref_ = ComponentReference.makeCrefIdent(i,DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("")), {}, NONE(), DAE.emptyTypeSource),s);
        cref_1 = prefixToCrefOpt2(Prefix.PREFIX(xs,cp), SOME(cref_));
      then
        cref_1;
    case (inPrefix as Prefix.PREFIX(Prefix.PRE(prefix = i,subscripts = s,next = xs),cp),SOME(cref))
      equation
        cref_ = ComponentReference.makeCrefQual(i,DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("")), {}, NONE(), DAE.emptyTypeSource),s,cref);
        cref_1 = prefixToCrefOpt2(Prefix.PREFIX(xs,cp), SOME(cref_));
      then
        cref_1;
  end match;
end prefixToCrefOpt2;

public function makeCrefFromPrefixNoFail
"@author:adrpo
   Similar to prefixToCref but it doesn't fail for NOPRE or NOCOMPPRE,
   it will just create an empty cref in these cases"
  input Prefix.Prefix pre;
  output DAE.ComponentRef cref;
algorithm
  cref := matchcontinue(pre)
    local
      DAE.ComponentRef c;
    
    case(Prefix.NOPRE())
      equation
        c = ComponentReference.makeCrefIdent("", DAE.T_UNKNOWN_DEFAULT, {});
      then
        c;
        
    case(Prefix.PREFIX(Prefix.NOCOMPPRE(), _))
      equation
        c = ComponentReference.makeCrefIdent("", DAE.T_UNKNOWN_DEFAULT, {});
      then
        c;
    
    case(pre)
      equation
        c = prefixToCref(pre);
      then
        c;
  end matchcontinue;
end makeCrefFromPrefixNoFail;

protected function prefixSubscriptsInCref "help function to prefixToCrefOpt2, deals with prefixing expressions in subscripts"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input Prefix.Prefix pre;
  input DAE.ComponentRef inCr;
  output Env.Cache outCache;
  output DAE.ComponentRef outCr;
algorithm
  (outCache,outCr) := match (inCache,inEnv,inIH,pre,inCr)
  local 
    DAE.Ident id;
    DAE.Type tp;
    list<DAE.Subscript> subs;
    Env.Cache cache;
    Env.Env env;
    DAE.ComponentRef cr;
    
    
    case(cache,env,inIH,pre,DAE.CREF_IDENT(id,tp,subs)) equation
     (cache,subs) = prefixSubscripts(cache,env,inIH,pre,subs);
    then (cache,ComponentReference.makeCrefIdent(id,tp,subs));
    case(cache,env,inIH,pre,DAE.CREF_QUAL(id,tp,subs,cr)) equation
      (cache,cr) = prefixSubscriptsInCref(cache,env,inIH,pre,cr);
      (cache,subs) = prefixSubscripts(cache,env,inIH,pre,subs);
    then (cache,ComponentReference.makeCrefQual(id,tp,subs,cr));
    case(cache,_,_,_,DAE.WILD()) then (cache,DAE.WILD());
  end match;
end prefixSubscriptsInCref;

protected function prefixSubscripts "help function to prefixSubscriptsInCref, adds prefix to subscripts"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input Prefix.Prefix pre;
  input list<DAE.Subscript> inSubs;
  output Env.Cache outCache;
  output list<DAE.Subscript> outSubs;
algorithm
  (outCache,outSubs) := match(inCache,inEnv,inIH,pre,inSubs)
    local 
      DAE.Subscript sub;
      Env.Cache cache;
      Env.Env env;
      list<DAE.Subscript> subs;
  
    case(cache,env,inIH,pre,{}) then (cache,{});
  
    case(cache,env,inIH,pre,sub::subs) equation
    (cache,sub) = prefixSubscript(cache,env,inIH,pre,sub);
    (cache,subs) = prefixSubscripts(cache,env,inIH,pre,subs);
    then (cache,sub::subs);
  end match;
end prefixSubscripts;

protected function prefixSubscript "help function to prefixSubscripts, adds prefix to one subscript, if it is an expression"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input Prefix.Prefix pre;
  input DAE.Subscript sub;
  output Env.Cache outCache;
  output DAE.Subscript outSub;
algorithm
  (outCache,outSub) := match(inCache,inEnv,inIH,pre,sub)
    local 
      DAE.Exp exp;
      Env.Cache cache;
      Env.Env env;
    
    case(cache,env,inIH,pre,DAE.WHOLEDIM()) then (cache,DAE.WHOLEDIM());
    
    case(cache,env,inIH,pre,DAE.SLICE(exp)) equation
      (cache,exp) = prefixExp(cache,env,inIH,exp,pre);
    then (cache,DAE.SLICE(exp));
    
    case(cache,env,inIH,pre,DAE.WHOLE_NONEXP(exp)) equation
      (cache,exp) = prefixExp(cache,env,inIH,exp,pre);
    then (cache,DAE.WHOLE_NONEXP(exp));
    
    case(cache,env,inIH,pre,DAE.INDEX(exp)) equation
      (cache,exp) = prefixExp(cache,env,inIH,exp,pre);
    then (cache,DAE.INDEX(exp));
    
  end match;
end prefixSubscript;

public function prefixCrefInnerOuter "function: prefixCrefInnerOuter
  Search for the prefix of the inner when the cref is 
  an outer and add that instead of the given prefix! 
  If the cref is an inner, prefix it normally."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input DAE.ComponentRef inCref;
  input Prefix.Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.ComponentRef outCref;
algorithm
  (outCache,outCref) := matchcontinue (inCache,inEnv,inIH,inCref,inPrefix)
    local
      Env.Cache cache;
      Env.Env env;
      Absyn.InnerOuter io;
      InstanceHierarchy ih;
      Prefix.Prefix innerPrefix, pre;
      DAE.ComponentRef lastCref, cref, newCref;
      String n;
    

    case (cache,env,ih,cref,pre)
      equation
        newCref = InnerOuter.prefixOuterCrefWithTheInnerPrefix(ih, cref, pre);
      then
        (cache,newCref);
     
    /*
    // adrpo: prefix normally if we have an inner outer variable!
    case (cache,env,ih,cref,pre)
      equation
        (cache,DAE.ATTR(innerOuter = io),_,_,_,_) = Lookup.lookupVarLocal(cache, env, cref);
        // Debug.fprintln(Flags.INNER_OUTER, printPrefixStr(inPrefix) +& "/" +& ComponentReference.printComponentRefStr(cref) +& 
        //   Util.if_(Absyn.isOuter(io), " [outer] ", " ") +& 
        //   Util.if_(Absyn.isInner(io), " [inner] ", " "));
        true = Absyn.isInner(io);
        false = Absyn.isOuter(io);
        // prefix normally
        newCref = prefixCref(pre, cref);
        // Debug.fprintln(Flags.INNER_OUTER, "INNER normally prefixed: " +& ComponentReference.printComponentRefStr(newCref));
      then
        (cache,newCref);

    // adrpo: prefix with *CORRECT* prefix from inner if we have an outer variable!
    case (cache,env,ih,cref as DAE.CREF_IDENT(ident=_),pre)
      equation
        (cache,DAE.ATTR(innerOuter = io),_,_,_,_) = Lookup.lookupVarLocal(cache, env, cref);
        // Debug.fprintln(Flags.INNER_OUTER, printPrefixStr(inPrefix) +& "/" +& ComponentReference.printComponentRefStr(cref) +& 
        //   Util.if_(Absyn.isOuter(io), " [outer] ", " ") +& 
        //   Util.if_(Absyn.isInner(io), " [inner] ", " "));
        true = Absyn.isOuter(io);
        n = ComponentReference.crefLastIdent(cref);
        lastCref = Expression.crefIdent(cref);
        // search in the instance hierarchy for the *CORRECT* prefix for this outer variable!
        InnerOuter.INST_INNER(innerPrefix=innerPrefix, instResult=SOME(_)) = 
           InnerOuter.lookupInnerVar(cache, env, ih, pre, n, io);
        // prefix the cref with the prefix of the INNER!
        
        newCref = prefixCref(innerPrefix, lastCref);
        
        // Debug.fprintln(Flags.INNER_OUTER, "OUTER IDENT prefixed INNER : " +& ComponentReference.printComponentRefStr(newCref));
      then
        (cache,newCref);
    
    // adrpo: we have a qualified cref, search for the prefix!
    // bar2/world.someCrap
    case (cache,env,ih,cref as DAE.CREF_QUAL(ident=_),pre)
      equation
        (cache,DAE.ATTR(innerOuter = io),_,_,_,_) = Lookup.lookupVarLocal(cache, env, cref);
        true = Absyn.isOuter(io);
        (cache,innerPrefix) = searchForInnerPrefix(cache,env,ih,cref,pre,io);
        newCref = prefixCref(innerPrefix, cref);
        // Debug.fprintln(Flags.INNER_OUTER, "OUTER QUAL prefixed INNER: " +& ComponentReference.printComponentRefStr(newCref));
      then
        (cache,newCref);
    */
  end matchcontinue;
end prefixCrefInnerOuter;

public function prefixExp "function: prefixExp
  Add the supplied prefix to all component references in an expression."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input DAE.Exp inExp;
  input Prefix.Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
algorithm
  (outCache,outExp) := matchcontinue (inCache,inEnv,inIH,inExp,inPrefix)
    local
      DAE.Exp e,e1_1,e2_1,e1,e2,e3_1,e3,cref_1,dim_1,cref,dim,start_1,stop_1,start,stop,step_1,step,e_1,exp_1,iterexp_1,exp,iterexp,crefExp;
      DAE.ComponentRef cr,cr_1;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      DAE.Operator o;
      list<DAE.Exp> es_1,es,el,el_1;
      Absyn.Path f,fcn;
      Boolean sc,bi,tup;
      DAE.InlineType inl;
      list<Boolean> bl;
      list<DAE.Exp> x_1,x;
      list<list<DAE.Exp>> xs_1,xs;
      String id,s;
      Env.Cache cache;
      list<DAE.Exp> expl;
      InstanceHierarchy ih;
      Prefix.Prefix p;
      Integer b,a;
      DAE.Type t,tp;
      Integer index_;
      Option<tuple<DAE.Exp,Integer,Integer>> isExpisASUB;
      Option<Values.Value> v;
      Option<DAE.Exp> foldExp;
      DAE.ReductionInfo reductionInfo;
      DAE.ReductionIterators riters;
      DAE.CallAttributes attr;
      
    // no prefix, return the input expression
    case (cache,_,_,e,Prefix.NOPRE()) then (cache,e);
      
    // handle literal constants       
    case (cache,_,_,(e as DAE.ICONST(integer = _)),_) then (cache,e);
    case (cache,_,_,(e as DAE.RCONST(real = _)),_) then (cache,e);
    case (cache,_,_,(e as DAE.SCONST(string = _)),_) then (cache,e);
    case (cache,_,_,(e as DAE.BCONST(bool = _)),_) then (cache,e);
    case (cache,_,_,(e as DAE.ENUM_LITERAL(name = _)), _) then (cache, e);

    // adrpo: handle prefixing of inner/outer variables
    case (cache,env,ih,DAE.CREF(componentRef = cr,ty = t),pre)
      equation
        true = System.getHasInnerOuterDefinitions();
        cr_1 = InnerOuter.prefixOuterCrefWithTheInnerPrefix(ih, cr, pre);
        crefExp = Expression.makeCrefExp(cr_1, t);
      then
        (cache,crefExp);

    case (cache,env,ih,DAE.CREF(componentRef = cr,ty = t),pre)
      equation
        // adrpo: ask for NONE() here as if we have SOME(...) it means 
        //        this is a for iterator and WE SHOULD NOT PREFIX IT!
        (cache,_,_,_,NONE(),_,_,_,_) = Lookup.lookupVarLocal(cache, env, cr);
        (cache,cr_1) = prefixCref(cache,env,ih,pre,cr);
        crefExp = Expression.makeCrefExp(cr_1, t);
      then
        (cache,crefExp);

    case (cache,env,_,e as DAE.CREF(componentRef = cr,ty = t),pre)
      equation
        // adrpo: do NOT prefix if we have a for iterator!
        (cache,_,_,_,SOME(_),_,_,_,_) = Lookup.lookupVarLocal(cache, env, cr);
      then
        (cache,e);

    case (cache,env,ih,e as DAE.CREF(componentRef = cr,ty = t),pre)
      equation 
        failure((_,_,_,_,_,_,_,_,_) = Lookup.lookupVarLocal(cache, env, cr));
        (cache, cr_1) = prefixSubscriptsInCref(cache, env, ih, pre, cr);
        crefExp = Expression.makeCrefExp(cr_1, t);
      then
        (cache,crefExp);
    
    case (cache,env,ih,(e as DAE.ASUB(exp = e1, sub = expl)),pre) 
      equation
        (cache,es_1) = prefixExpList(cache, env, ih, expl, pre);
        (cache,e1) = prefixExp(cache, env, ih, e1,pre);
        e2 = Expression.makeASUB(e1,es_1);
      then 
        (cache,e2);
    
    case (cache,env,ih,DAE.BINARY(exp1 = e1,operator = o,exp2 = e2),p)
      equation
        (cache,e1_1) = prefixExp(cache, env, ih, e1, p);
        (cache,e2_1) = prefixExp(cache, env, ih, e2, p);
      then
        (cache,DAE.BINARY(e1_1,o,e2_1));

    case (cache,env,ih,DAE.UNARY(operator = o,exp = e1),p)
      equation
        (cache,e1_1) = prefixExp(cache, env, ih, e1, p);
      then
        (cache,DAE.UNARY(o,e1_1));

    case (cache,env,ih,DAE.LBINARY(exp1 = e1,operator = o,exp2 = e2),p)
      equation
        (cache,e1_1) = prefixExp(cache, env, ih, e1, p);
        (cache,e2_1) = prefixExp(cache, env, ih, e2, p);
      then
        (cache,DAE.LBINARY(e1_1,o,e2_1));

    case (cache,env,ih,DAE.LUNARY(operator = o,exp = e1),p)
      equation
        (cache,e1_1) = prefixExp(cache, env, ih, e1, p);
      then
        (cache,DAE.LUNARY(o,e1_1));

    case (cache,env,ih,DAE.RELATION(exp1 = e1,operator = o,exp2 = e2, index=index_, optionExpisASUB= isExpisASUB),p)
      equation
        (cache,e1_1) = prefixExp(cache, env, ih, e1, p);
        (cache,e2_1) = prefixExp(cache, env, ih, e2, p);
      then
        (cache,DAE.RELATION(e1_1,o,e2_1,index_,isExpisASUB));

    case (cache,env,ih,DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),p)
      equation
        (cache,e1_1) = prefixExp(cache, env, ih, e1, p);
        (cache,e2_1) = prefixExp(cache, env, ih, e2, p);
        (cache,e3_1) = prefixExp(cache, env, ih, e3, p);
      then
        (cache,DAE.IFEXP(e1_1,e2_1,e3_1));

    case (cache,env,ih,DAE.SIZE(exp = cref,sz = SOME(dim)),p)
      equation
        (cache,cref_1) = prefixExp(cache, env, ih, cref, p);
        (cache,dim_1) = prefixExp(cache, env, ih, dim, p);
      then
        (cache,DAE.SIZE(cref_1,SOME(dim_1)));

    case (cache,env,ih,DAE.SIZE(exp = cref,sz = NONE()),p)
      equation
        (cache,cref_1) = prefixExp(cache, env, ih, cref, p);
      then
        (cache,DAE.SIZE(cref_1,NONE()));

    case (cache,env,ih,DAE.CALL(f,es,attr),p)
      equation
        (cache,es_1) = prefixExpList(cache, env, ih, es, p);
      then
        (cache,DAE.CALL(f,es_1,attr));

    case (cache,env,ih,DAE.ARRAY(ty = t,scalar = sc,array = {}),p)
      then
        (cache,DAE.ARRAY(t,sc,{}));

    case (cache,env,ih,DAE.ARRAY(ty = t,scalar = sc,array = es),p)
      equation
        (cache,es_1) = prefixExpList(cache, env, ih, es, p);
      then
        (cache,DAE.ARRAY(t,sc,es_1));

    case (cache,env,ih,DAE.TUPLE(PR = es),p)
      equation
        (cache,es_1) = prefixExpList(cache, env, ih, es, p);
      then
        (cache,DAE.TUPLE(es_1));

    case (cache,env,ih,DAE.MATRIX(ty = t,integer = a,matrix = {}),p)
      then
        (cache,DAE.MATRIX(t,a,{}));

    case (cache,env,ih,DAE.MATRIX(ty = t,integer = a,matrix = (x :: xs)),p)
      equation
        (cache,x_1) = prefixExpList(cache, env, ih, x, p);
        (cache,DAE.MATRIX(t,b,xs_1)) = prefixExp(cache, env, ih, DAE.MATRIX(t,a,xs), p);
      then
        (cache,DAE.MATRIX(t,a,(x_1 :: xs_1)));

    case (cache,env,ih,DAE.RANGE(ty = t,start = start,step = NONE(),stop = stop),p)
      equation
        (cache,start_1) = prefixExp(cache, env, ih, start, p);
        (cache,stop_1) = prefixExp(cache, env, ih, stop, p);
      then
        (cache,DAE.RANGE(t,start_1,NONE(),stop_1));

    case (cache,env,ih,DAE.RANGE(ty = t,start = start,step = SOME(step),stop = stop),p)
      equation
        (cache,start_1) = prefixExp(cache, env, ih, start, p);
        (cache,step_1) = prefixExp(cache, env, ih, step, p);
        (cache,stop_1) = prefixExp(cache, env, ih, stop, p);
      then
        (cache,DAE.RANGE(t,start_1,SOME(step_1),stop_1));

    case (cache,env,ih,DAE.CAST(ty = tp,exp = e),p)
      equation
        (cache,e_1) = prefixExp(cache, env, ih, e, p);
      then
        (cache,DAE.CAST(tp,e_1));

    case (cache,env,ih,DAE.REDUCTION(reductionInfo = reductionInfo,expr = exp,iterators = riters),p)
      equation
        (cache,exp_1) = prefixExp(cache, env, ih, exp, p);
        (cache,riters) = prefixIterators(cache, env, ih, riters, p);
      then
        (cache,DAE.REDUCTION(reductionInfo,exp_1,riters));

    // MetaModelica extension. KS
    case (cache,env,ih,DAE.LIST(es),p)
      equation
        (cache,es_1) = prefixExpList(cache, env, ih, es, p);
      then (cache,DAE.LIST(es_1));

    case (cache,env,ih,DAE.CONS(e1,e2),p)
      equation
        (cache,e1) = prefixExp(cache, env, ih, e1, p);
        (cache,e2) = prefixExp(cache, env, ih, e2, p);
      then (cache,DAE.CONS(e1,e2));

    case (cache,env,ih,DAE.META_TUPLE(es),p)
      equation
        (cache,es_1) = prefixExpList(cache, env, ih, es, p);
      then (cache,DAE.META_TUPLE(es_1));

    case (cache,env,ih,DAE.META_OPTION(SOME(e1)),p)
      equation
        (cache,e1) = prefixExp(cache, env, ih, e1, p);
      then (cache,DAE.META_OPTION(SOME(e1)));

    case (cache,env,ih,DAE.META_OPTION(NONE()),p)
      equation
      then (cache,DAE.META_OPTION(NONE()));
        // ------------------------

    case (_,_,_,e,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprint(Flags.FAILTRACE, "-prefix_exp failed on exp:");
        s = ExpressionDump.printExpStr(e);
        Debug.fprint(Flags.FAILTRACE, s);
        Debug.fprint(Flags.FAILTRACE, "\n");
      then
        fail();
  end matchcontinue;
end prefixExp;

protected function prefixIterators
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy ih;
  input DAE.ReductionIterators inIters;
  input Prefix.Prefix pre;
  output Env.Cache outCache;
  output DAE.ReductionIterators outIters;
algorithm
  (outCache,outIters) := match (inCache,inEnv,ih,inIters,pre)
    local
      String id;
      DAE.Exp exp,gexp;
      DAE.Type ty;
      DAE.ReductionIterator iter;
      Env.Cache cache;
      Env.Env env;
      DAE.ReductionIterators iters;

    case (cache,env,ih,{},pre) then (cache,{});
    case (cache,env,ih,DAE.REDUCTIONITER(id,exp,SOME(gexp),ty)::iters,pre)
      equation
        (cache,exp) = prefixExp(cache,env,ih,exp,pre);
        (cache,gexp) = prefixExp(cache,env,ih,gexp,pre);
        iter = DAE.REDUCTIONITER(id,exp,SOME(gexp),ty);
        (cache,iters) = prefixIterators(cache,env,ih,iters,pre);
      then (cache,iter::iters);
    case (cache,env,ih,DAE.REDUCTIONITER(id,exp,NONE(),ty)::iters,pre)
      equation
        (cache,exp) = prefixExp(cache,env,ih,exp,pre);
        iter = DAE.REDUCTIONITER(id,exp,NONE(),ty);
        (cache,iters) = prefixIterators(cache,env,ih,iters,pre);
      then (cache,iter::iters);
  end match;
end prefixIterators;

public function prefixExpList "function: prefixExpList
  This function prefixes a list of expressions using the prefixExp function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input list<DAE.Exp> inExpExpLst;
  input Prefix.Prefix inPrefix;
  output Env.Cache outCache;
  output list<DAE.Exp> outExpExpLst;
algorithm
  (outCache,outExpExpLst) := match (inCache,inEnv,inIH,inExpExpLst,inPrefix)
    local
      DAE.Exp e_1,e;
      list<DAE.Exp> es_1,es;
      list<Env.Frame> env;
      Prefix.Prefix p;
      Env.Cache cache;
      InstanceHierarchy ih;

    // handle empty case
    case (cache,_,_,{},_) then (cache,{});

    // yuppie! we have a list of expressions
    case (cache,env,ih,(e :: es),p)
      equation
        (cache,e_1) = prefixExp(cache, env, ih, e, p);
        (cache,es_1) = prefixExpList(cache, env, ih, es, p);
      then
        (cache,e_1 :: es_1);
  end match;
end prefixExpList;

//--------------------------------------------
//   PART OF THE WORKAROUND FOR VALUEBLOCKS. KS
protected function prefixDecls "function: prefixDecls
  Add the supplied prefix to the DAE elements located in Expression.mo.
  PART OF THE WORKAROUND FOR VALUEBLOCKS"
  input Env.Cache cache;
  input Env.Env env;
  input InstanceHierarchy inIH;
  input list<DAE.Element> lDecls;
  input list<DAE.Element> accList;
  input Prefix.Prefix p;
  output Env.Cache outCache;
  output list<DAE.Element> outDecls;
algorithm
  (outCache,outDecls) := matchcontinue (cache,env,inIH,lDecls,accList,p)
    local
      list<DAE.Element> localAccList;
      Prefix.Prefix pre;
      Env.Cache localCache;
      Env.Env localEnv;
      DAE.ElementSource source "the origin of the element";
      InstanceHierarchy ih;
      DAE.ComponentRef cRef;
      DAE.VarKind v1 "varible kind variable, constant, parameter, etc." ;
      DAE.VarParallelism prl;
      DAE.VarDirection v2 "input, output or bidir" ;
      DAE.VarVisibility prot "if protected or public";
      DAE.Type ty "the type" ;
      Option<DAE.Exp> binding "binding" ;
      DAE.InstDims dims "Binding expression e.g. for parameters" ;
      DAE.Flow flowPrefix "Flow of connector variable. Needed for unconnected flow variables" ;
      DAE.Stream streamPrefix "stream or no strem" ;
      list<Absyn.Path> f "the list of classes";
      Option<DAE.VariableAttributes> vAttr;
      Option<SCode.Comment> com "comment";
      Absyn.InnerOuter inOut "inner/outer required to 'change' outer references";
      list<DAE.Element> rest,temp;
      DAE.Element elem;
      DAE.Exp e1,e2;
    
    case (localCache,_,_,{},localAccList,_) then (localCache,localAccList);
    // variables
    case (localCache,localEnv,ih,DAE.VAR(cRef,v1,v2,prl,prot,ty,binding,dims,
                            flowPrefix,streamPrefix,source,vAttr,com,inOut)
       :: rest,localAccList,pre)
    equation
      (localCache,cRef) = prefixCref(localCache,localEnv,ih,pre,cRef);
      elem = DAE.VAR(cRef,v1,v2,prl,prot,ty,binding,dims,flowPrefix,streamPrefix,source,vAttr,com,inOut);
      localAccList = listAppend(localAccList,List.create(elem));
      (localCache,temp) = prefixDecls(localCache,localEnv,ih,rest,localAccList,pre);
    then (localCache,temp);

    // equations
    case (localCache,localEnv,ih,DAE.EQUATION(e1,e2,source) :: rest,localAccList,pre)
      equation
        (localCache,e1) = prefixExp(localCache,localEnv,ih,e1,pre);
        (localCache,e2) = prefixExp(localCache,localEnv,ih,e2,pre);
        elem = DAE.EQUATION(e1,e2,source);
        localAccList = listAppend(localAccList,List.create(elem));
        (localCache,temp) = prefixDecls(localCache,localEnv,ih,rest,localAccList,pre);
      then (localCache,temp);
    // failure
    case (_,_,_,_,_,_)
      equation
        print("Prefix.prefixDecls failed\n");
      then fail();
 end matchcontinue;
end prefixDecls;

protected function prefixStatements "function: prefixStatements
  Prefix statements.
  PART OF THE WORKAROUND FOR VALUEBLOCKS"
  input Env.Cache cache;
  input Env.Env env;
  input InstanceHierarchy inIH;
  input list<DAE.Statement> stmts;
  input list<DAE.Statement> accList;
  input Prefix.Prefix p;
  output Env.Cache outCache;
  output list<DAE.Statement> outStmts;
algorithm
  (outCache,outStmts) := matchcontinue (cache,env,inIH,stmts,accList,p)
    local
      Env.Cache localCache;
      Env.Env localEnv;
      list<DAE.Statement> localAccList,rest;
      Prefix.Prefix pre;
      InstanceHierarchy ih;
      DAE.ElementSource source;
      DAE.Type t;
      DAE.Statement elem;
      list<DAE.Statement> elems,sList,b;
      String s,id;
      DAE.Exp e,e1,e2;
      list<DAE.Exp> eLst;
      DAE.ComponentRef cRef;
      Boolean bool;
      DAE.Else elseBranch;
      Integer ix;

    case (localCache,_,_,{},localAccList,_) then (localCache,localAccList);

    case (localCache,localEnv,ih,DAE.STMT_ASSIGN(t,e1,e,source) :: rest,localAccList,pre)
      equation
        (localCache,e1) = prefixExp(localCache,localEnv,ih,e1,pre);
        (localCache,e) = prefixExp(localCache,localEnv,ih,e,pre);
        elem = DAE.STMT_ASSIGN(t,e1,e,source);
        localAccList = listAppend(localAccList,List.create(elem));
        (localCache,elems) = prefixStatements(localCache,localEnv,ih,rest,localAccList,pre);
      then (localCache,elems);

    case (localCache,localEnv,ih,DAE.STMT_TUPLE_ASSIGN(t,eLst,e,source) :: rest,localAccList,pre)
      equation
        (localCache,e) = prefixExp(localCache,localEnv,ih,e,pre);
        (localCache,eLst) = prefixExpList(localCache,localEnv,ih,eLst,pre);
        elem = DAE.STMT_TUPLE_ASSIGN(t,eLst,e,source);
        localAccList = listAppend(localAccList,List.create(elem));
        (localCache,elems) = prefixStatements(localCache,localEnv,ih,rest,localAccList,pre);
      then (localCache,elems);

    case (localCache,localEnv,ih,DAE.STMT_ASSIGN_ARR(t,cRef,e,source) :: rest,localAccList,pre)
      equation
        (localCache,cRef) = prefixCref(localCache,localEnv,ih,pre,cRef);
        (localCache,e) = prefixExp(localCache,localEnv,ih,e,pre);
        elem = DAE.STMT_ASSIGN_ARR(t,cRef,e,source);
        localAccList = listAppend(localAccList,List.create(elem));
        (localCache,elems) = prefixStatements(localCache,localEnv,ih,rest,localAccList,pre);
      then (localCache,elems);

    case (localCache,localEnv,ih,DAE.STMT_FOR(t,bool,id,ix,e,sList,source) :: rest,localAccList,pre)
      equation
        (localCache,e) = prefixExp(localCache,localEnv,ih,e,pre);
        (localCache,sList) = prefixStatements(localCache,localEnv,ih,sList,{},pre);
        elem = DAE.STMT_FOR(t,bool,id,ix,e,sList,source);
        localAccList = listAppend(localAccList,List.create(elem));
        (localCache,elems) = prefixStatements(localCache,localEnv,ih,rest,localAccList,pre);
      then (localCache,elems);

  case (localCache,localEnv,ih,DAE.STMT_IF(e1,sList,elseBranch,source) :: rest,localAccList,pre)
      equation
        (localCache,e1) = prefixExp(localCache,localEnv,ih,e1,pre);
        (localCache,sList) = prefixStatements(localCache,localEnv,ih,sList,{},pre);
        (localCache,elseBranch) = prefixElse(localCache,localEnv,ih,elseBranch,pre);
        elem = DAE.STMT_IF(e1,sList,elseBranch,source);
        localAccList = listAppend(localAccList,List.create(elem));
        (localCache,elems) = prefixStatements(localCache,localEnv,ih,rest,localAccList,pre);
      then (localCache,elems);

    case (localCache,localEnv,ih,DAE.STMT_WHILE(e1,sList,source) :: rest,localAccList,pre)
      equation
        (localCache,e1) = prefixExp(localCache,localEnv,ih,e1,pre);
        (localCache,sList) = prefixStatements(localCache,localEnv,ih,sList,{},pre);
        elem = DAE.STMT_WHILE(e1,sList,source);
        localAccList = listAppend(localAccList,List.create(elem));
        (localCache,elems) = prefixStatements(localCache,localEnv,ih,rest,localAccList,pre);
      then (localCache,elems);

    case (localCache,localEnv,ih,DAE.STMT_ASSERT(e1,e2,source) :: rest,localAccList,pre)
      equation
        (localCache,e1) = prefixExp(localCache,localEnv,ih,e1,pre);
        (localCache,e2) = prefixExp(localCache,localEnv,ih,e2,pre);
        elem = DAE.STMT_ASSERT(e1,e2,source);
        localAccList = listAppend(localAccList,List.create(elem));
        (localCache,elems) = prefixStatements(localCache,localEnv,ih,rest,localAccList,pre);
      then (localCache,elems);
    case (localCache,localEnv,ih,DAE.STMT_FAILURE(b,source) :: rest,localAccList,pre)
      equation
        (localCache,b) = prefixStatements(localCache,localEnv,ih,b,{},pre);
        elem = DAE.STMT_FAILURE(b,source);
        localAccList = listAppend(localAccList,List.create(elem));
        (localCache,elems) = prefixStatements(localCache,localEnv,ih,rest,localAccList,pre);
      then (localCache,elems);
    case (localCache,localEnv,ih,DAE.STMT_TRY(b,source) :: rest,localAccList,pre)
      equation
        (localCache,b) = prefixStatements(localCache,localEnv,ih,b,{},pre);
        elem = DAE.STMT_TRY(b,source);
        localAccList = listAppend(localAccList,List.create(elem));
        (localCache,elems) = prefixStatements(localCache,localEnv,ih,rest,localAccList,pre);
      then (localCache,elems);
    case (localCache,localEnv,ih,DAE.STMT_CATCH(b,source) :: rest,localAccList,pre)
      equation
        (localCache,b) = prefixStatements(localCache,localEnv,ih,b,{},pre);
        elem = DAE.STMT_CATCH(b,source);
        localAccList = listAppend(localAccList,List.create(elem));
        (localCache,elems) = prefixStatements(localCache,localEnv,ih,rest,localAccList,pre);
      then (localCache,elems);
    case (localCache,localEnv,ih,DAE.STMT_THROW(source) :: rest,localAccList,pre)
        equation
          elem = DAE.STMT_THROW(source);
          localAccList = listAppend(localAccList,List.create(elem));
          (localCache,elems) = prefixStatements(localCache,localEnv,ih,rest,localAccList,pre);
        then (localCache,elems);
    case (localCache,localEnv,ih,DAE.STMT_RETURN(source) :: rest,localAccList,pre)
        equation
          elem = DAE.STMT_RETURN(source);
          localAccList = listAppend(localAccList,List.create(elem));
          (localCache,elems) = prefixStatements(localCache,localEnv,ih,rest,localAccList,pre);
        then (localCache,elems);
    case (localCache,localEnv,ih,DAE.STMT_BREAK(source) :: rest,localAccList,pre)
        equation
          elem = DAE.STMT_BREAK(source);
          localAccList = listAppend(localAccList,List.create(elem));
          (localCache,elems) = prefixStatements(localCache,localEnv,ih,rest,localAccList,pre);
        then (localCache,elems);
  end matchcontinue;
end prefixStatements;

protected function prefixElse "function: prefixElse
  Prefix else statements.
  PART OF THE WORKAROUND FOR VALUEBLOCKS"
  input Env.Cache cache;
  input Env.Env env;
  input InstanceHierarchy inIH;
  input DAE.Else elseBranch;
  input Prefix.Prefix p;
  output Env.Cache outCache;
  output DAE.Else outElse;
algorithm
  (outCache,outElse) := matchcontinue (cache,env,inIH,elseBranch,p)
    local
      Env.Cache localCache;
      Env.Env localEnv;
      Prefix.Prefix pre;
      InstanceHierarchy ih;
      DAE.Exp e;
      list<DAE.Statement> lStmt;
      DAE.Else el,stmt;
      
    case (localCache,localEnv,ih,DAE.NOELSE(),pre)
      then (localCache,DAE.NOELSE());

    case (localCache,localEnv,ih,DAE.ELSEIF(e,lStmt,el),pre)
      equation
        (localCache,e) = prefixExp(localCache,localEnv,ih,e,pre);
        (localCache,el) = prefixElse(localCache,localEnv,ih,el,pre);
        (localCache,lStmt) = prefixStatements(localCache,localEnv,ih,lStmt,{},pre);
        stmt = DAE.ELSEIF(e,lStmt,el);
      then (localCache,stmt);

    case (localCache,localEnv,ih,DAE.ELSE(lStmt),pre)
      equation
       (localCache,lStmt) = prefixStatements(localCache,localEnv,ih,lStmt,{},pre);
        stmt = DAE.ELSE(lStmt);
      then (localCache,stmt);
  end matchcontinue;
end prefixElse;

public function makePrefixString "helper function for Mod.verifySingleMod, pretty output"
  input Prefix.Prefix pre;
  output String str;
algorithm 
  str := matchcontinue(pre)
    case(Prefix.NOPRE()) then "from top scope";
    case(pre)
      equation
        str = "from calling scope: " +& printPrefixStr(pre);
      then str;
  end matchcontinue;
end makePrefixString;

end PrefixUtil;
