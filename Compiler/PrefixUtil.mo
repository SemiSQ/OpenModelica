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

package PrefixUtil
" file:	       PrefixUtil.mo
  package:     PrefixUtil
  description: PrefixUtil management

  RCS: $Id: PrefixUtil.mo 4847 2010-01-21 22:45:09Z adrpo $

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
public import RTOpts;
public import Prefix;
public import InnerOuter;

type Prefix = Prefix.Prefix;
type InstanceHierarchy = InnerOuter.InstHierarchy "an instance hierarchy";

protected import ClassInf;
protected import Debug;
protected import Exp;
protected import Print;
protected import Util;
protected import System;

public function printPrefixStr "function: printPrefixStr
  Prints a Prefix to a string."
  input Prefix inPrefix;
  output String outString;
algorithm
  outString :=  matchcontinue (inPrefix)
    local
      String str,s,rest_1,s_1,s_2;
      Prefix.ComponentPrefix rest;
      Prefix.ClassPrefix cp;
      list<Integer> ss;
      
    case Prefix.NOPRE() then "<Prefix.NOPRE()>";
    case Prefix.PREFIX(Prefix.NOCOMPPRE(),_) then "<Prefix.PREFIX(Prefix.NOCOMPPRE())>";      
    case Prefix.PREFIX(Prefix.PRE(str,{},Prefix.NOCOMPPRE()),_) then str;
    case Prefix.PREFIX(Prefix.PRE(str,ss,Prefix.NOCOMPPRE()),_)
      equation
        s = stringAppend(str, "[" +& Util.stringDelimitList(Util.listMap(ss, intString), ", ") +& "]");
      then
        s;
    case Prefix.PREFIX(Prefix.PRE(str,{},rest),cp)
      equation
        rest_1 = printPrefixStr(Prefix.PREFIX(rest,cp));
        s = stringAppend(rest_1, ".");
        s_1 = stringAppend(s, str);
      then
        s_1;
    case Prefix.PREFIX(Prefix.PRE(str,ss,rest),cp)
      equation
        rest_1 = printPrefixStr(Prefix.PREFIX(rest,cp));
        s = stringAppend(rest_1, ".");
        s_1 = stringAppend(s, str);
        s_2 = stringAppend(s_1, "[" +& Util.stringDelimitList(Util.listMap(ss, intString), ", ") +& "]");
      then
        s_2;
  end matchcontinue;
end printPrefixStr;

public function printPrefixStr2 "function: printPrefixStr2
  Prints a Prefix to a string. Designed to be used in Error messages"
  input Prefix inPrefix;
  output String outString;
algorithm
  outString :=  matchcontinue (inPrefix)
  local 
    Prefix p;
  case Prefix.NOPRE() then "";
  case Prefix.PREFIX(Prefix.NOCOMPPRE(),_) then "";
  case p then printPrefixStr(p)+&".";        
  end matchcontinue;
end printPrefixStr2;

public function printPrefix "function: printPrefix
  Prints a prefix to the Print buffer."
  input Prefix p;
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
  input list<Integer> inIntegerLst;
  input Prefix inPrefix;
  input SCode.Variability vt;
  output Prefix outPrefix;
algorithm
  outPrefix := matchcontinue (inIdent,inIntegerLst,inPrefix,vt)
    local
      String i;
      list<Integer> s;
      Prefix.ComponentPrefix p;
      
    case (i,s,Prefix.PREFIX(p,_),vt) 
      then Prefix.PREFIX(Prefix.PRE(i,s,p),Prefix.CLASSPRE(vt));
    
    case(i,s,Prefix.NOPRE(),vt) 
      then Prefix.PREFIX(Prefix.PRE(i,s,Prefix.NOCOMPPRE()),Prefix.CLASSPRE(vt));
  end matchcontinue;
end prefixAdd;

public function prefixFirst
  input Prefix inPrefix;
  output Prefix outPrefix;
algorithm
  outPrefix := matchcontinue (inPrefix)
    local
      String a;
      list<Integer> b;
      Prefix.ClassPrefix cp;
      Prefix.ComponentPrefix c;
    case (Prefix.PREFIX(Prefix.PRE(prefix = a,subscripts = b,next = c),cp)) 
      then Prefix.PREFIX(Prefix.PRE(a,b,Prefix.NOCOMPPRE()),cp);
  end matchcontinue;
end prefixFirst;

public function prefixLast "function: prefixLast
  Returns the last NONPRE Prefix of a prefix"
  input Prefix inPrefix;
  output Prefix outPrefix;
algorithm
  outPrefix := matchcontinue (inPrefix)
    local 
      Prefix.ComponentPrefix p;
      Prefix res;
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
  input Prefix inPrefix;
  output Prefix outPrefix;
algorithm
  outPrefix := matchcontinue (inPrefix)
    local
      Prefix.ClassPrefix cp;
      Prefix.ComponentPrefix compPre;
      Prefix.ComponentPrefixOpt iop;
    // we can't remove what it isn't there!
    case (Prefix.NOPRE()) then Prefix.NOPRE();
    // if there isn't any next prefix, return Prefix.NOPRE!
    case (Prefix.PREFIX(compPre,cp))
      equation
         compPre = compPreStripLast(compPre);
      then Prefix.PREFIX(compPre,cp);
  end matchcontinue;
end prefixStripLast;

protected function compPreStripLast
"@author: adrpo
 remove the last prefix from the component prefix"
  input Prefix.ComponentPrefix inCompPrefix;
  output Prefix.ComponentPrefix outCompPrefix;
algorithm
  outCompPrefix := matchcontinue(inCompPrefix)
    local
      String p;
      list<Integer> subs;
      Prefix.ComponentPrefix next;

    // nothing to remove!
    case Prefix.NOCOMPPRE() then Prefix.NOCOMPPRE();
    // we have something
    case Prefix.PRE(next = next) then next;
   end matchcontinue;
end compPreStripLast;

public function prefixPath "function: prefixPath
  Prefix a Path variable by adding the supplied 
  prefix to it and returning a new Path."
  input Absyn.Path inPath;
  input Prefix inPrefix;
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
  input Prefix inPrefix;
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
  input Prefix pre;
  input DAE.ComponentRef cref;
  output DAE.ComponentRef cref_1;
  DAE.ComponentRef cref_1;
algorithm
  cref_1 := prefixToCref2(pre, SOME(cref));
end prefixCref;

public function prefixToCref "function: prefixToCref
  Convert a prefix to a component reference."
  input Prefix pre;
  output DAE.ComponentRef cref_1;
  DAE.ComponentRef cref_1;
algorithm
  cref_1 := prefixToCref2(pre, NONE());
end prefixToCref;

protected function prefixToCref2 "function: prefixToCref2
  Convert a prefix to a component reference. Converting Prefix.NOPRE with no
  component reference is an error because a component reference cannot be
  empty"
  input Prefix inPrefix;
  input Option<DAE.ComponentRef> inExpComponentRefOption;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef := matchcontinue (inPrefix,inExpComponentRefOption)
    local
      DAE.ComponentRef cref,cref_1;
      list<DAE.Subscript> s_1;
      String i;
      list<Integer> s;
      Prefix.ComponentPrefix xs;
      Prefix.ClassPrefix cp;
    
    case (Prefix.NOPRE(),NONE) then fail();
    case (Prefix.NOPRE(),SOME(cref)) then cref;
    case (Prefix.PREFIX(Prefix.NOCOMPPRE(),_),SOME(cref)) then cref;
    case (Prefix.PREFIX(Prefix.PRE(prefix = i,subscripts = s,next = xs),cp),NONE)
      equation
        s_1 = Exp.intSubscripts(s);
        cref_1 = prefixToCref2(Prefix.PREFIX(xs,cp), SOME(DAE.CREF_IDENT(i,DAE.ET_COMPLEX(Absyn.IDENT(""),{},ClassInf.UNKNOWN(Absyn.IDENT(""))),s_1)));
      then
        cref_1;
    case (Prefix.PREFIX(Prefix.PRE(prefix = i,subscripts = s,next = xs),cp),SOME(cref))
      equation
        s_1 = Exp.intSubscripts(s);
        cref_1 = prefixToCref2(Prefix.PREFIX(xs,cp), SOME(DAE.CREF_QUAL(i,DAE.ET_COMPLEX(Absyn.IDENT(""),{},ClassInf.UNKNOWN(Absyn.IDENT(""))),s_1,cref)));
      then
        cref_1;
  end matchcontinue;
end prefixToCref2;

public function prefixToCrefOpt "function: prefixToCref
  Convert a prefix to an optional component reference."
  input Prefix pre;
  output Option<DAE.ComponentRef> cref_1;
  Option<DAE.ComponentRef> cref_1;
algorithm
  cref_1 := prefixToCrefOpt2(pre, NONE());
end prefixToCrefOpt;

public function prefixToCrefOpt2 "function: prefixToCrefOpt2
  Convert a prefix to a component reference. Converting Prefix.NOPRE with no
  component reference gives a NONE"
  input Prefix inPrefix;
  input Option<DAE.ComponentRef> inExpComponentRefOption;
  output Option<DAE.ComponentRef> outComponentRefOpt;
algorithm
  outComponentRefOpt := matchcontinue (inPrefix,inExpComponentRefOption)
    local
      Option<DAE.ComponentRef> cref_1;
      DAE.ComponentRef cref;
      list<DAE.Subscript> s_1;
      String i;
      list<Integer> s;
      Prefix.ComponentPrefix xs;
      Prefix.ClassPrefix cp;

    case (Prefix.NOPRE(),NONE()) then NONE();
    case (Prefix.NOPRE(),SOME(cref)) then SOME(cref);
    case (Prefix.PREFIX(Prefix.NOCOMPPRE(),_),SOME(cref)) then SOME(cref);
    case (Prefix.PREFIX(Prefix.PRE(prefix = i,subscripts = s,next = xs),cp),NONE())
      equation
        s_1 = Exp.intSubscripts(s);
        cref_1 = prefixToCrefOpt2(Prefix.PREFIX(xs,cp), SOME(DAE.CREF_IDENT(i,DAE.ET_COMPLEX(Absyn.IDENT(""),{},ClassInf.UNKNOWN(Absyn.IDENT(""))),s_1)));
      then
        cref_1;
    case (Prefix.PREFIX(Prefix.PRE(prefix = i,subscripts = s,next = xs),cp),SOME(cref))
      equation
        s_1 = Exp.intSubscripts(s);
        cref_1 = prefixToCrefOpt2(Prefix.PREFIX(xs,cp), SOME(DAE.CREF_QUAL(i,DAE.ET_COMPLEX(Absyn.IDENT(""),{},ClassInf.UNKNOWN(Absyn.IDENT(""))),s_1,cref)));
      then
        cref_1;
  end matchcontinue;
end prefixToCrefOpt2;

public function prefixCrefInnerOuter "function: prefixCrefInnerOuter
  Search for the prefix of the inner when the cref is 
  an outer and add that instead of the given prefix! 
  If the cref is an inner, prefix it normally."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input DAE.ComponentRef inCref;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.ComponentRef outCref;
algorithm
  (outCache,outCref) := matchcontinue (inCache,inEnv,inIH,inCref,inPrefix)
    local
      Env.Cache cache;
      Env.Env env;
      Absyn.InnerOuter io;
      InstanceHierarchy ih;
      Prefix innerPrefix, pre;
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
        // Debug.fprintln("innerouter", printPrefixStr(inPrefix) +& "/" +& Exp.printComponentRefStr(cref) +& 
        //   Util.if_(Absyn.isOuter(io), " [outer] ", " ") +& 
        //   Util.if_(Absyn.isInner(io), " [inner] ", " "));
        true = Absyn.isInner(io);
        false = Absyn.isOuter(io);
        // prefix normally
        newCref = prefixCref(pre, cref);
        // Debug.fprintln("innerouter", "INNER normally prefixed: " +& Exp.printComponentRefStr(newCref));
      then
        (cache,newCref);

    // adrpo: prefix with *CORRECT* prefix from inner if we have an outer variable!
    case (cache,env,ih,cref as DAE.CREF_IDENT(ident=_),pre)
      equation
        (cache,DAE.ATTR(innerOuter = io),_,_,_,_) = Lookup.lookupVarLocal(cache, env, cref);
        // Debug.fprintln("innerouter", printPrefixStr(inPrefix) +& "/" +& Exp.printComponentRefStr(cref) +& 
        //   Util.if_(Absyn.isOuter(io), " [outer] ", " ") +& 
        //   Util.if_(Absyn.isInner(io), " [inner] ", " "));
        true = Absyn.isOuter(io);
        n = Exp.crefLastIdent(cref);
        lastCref = Exp.crefIdent(cref);
        // search in the instance hierarchy for the *CORRECT* prefix for this outer variable!
        InnerOuter.INST_INNER(innerPrefix=innerPrefix, instResult=SOME(_)) = 
           InnerOuter.lookupInnerVar(cache, env, ih, pre, n, io);
        // prefix the cref with the prefix of the INNER!
        
        newCref = prefixCref(innerPrefix, lastCref);
        
        // Debug.fprintln("innerouter", "OUTER IDENT prefixed INNER : " +& Exp.printComponentRefStr(newCref));
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
        // Debug.fprintln("innerouter", "OUTER QUAL prefixed INNER: " +& Exp.printComponentRefStr(newCref));
      then
        (cache,newCref);
    */
  end matchcontinue;
end prefixCrefInnerOuter;

public function searchForInnerPrefix "function: searchForInnerPrefix
  Search for the prefix of the inner when the cref is 
  an qualified outer component refence. Some clever 
  handling is needed here as the prefix/cref can look
  like bar2/world.someCrap, so we should search for
    bar2.world/someCrap then
    bar2/someCrap then
    /someCrap
    bar2/world
    /world"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input DAE.ComponentRef inCref;
  input Prefix inPrefix;
  input Absyn.InnerOuter inInnerOuter;
  output Env.Cache outCache;
  output Prefix outInnerPrefix;
algorithm
  (outCache,outInnerPrefix) := matchcontinue (inCache,inEnv,inIH,inCref,inPrefix,inInnerOuter)
    local
      Env.Cache cache;
      Env.Env env;
      InstanceHierarchy ih;
      Prefix innerPrefix, pre;
      Absyn.InnerOuter io;
      DAE.ComponentRef crefPrefix, cref, newCref;
      String n;

    // adrpo: prefix normally if we have an inner outer variable!
    case (cache,env,ih,cref as DAE.CREF_IDENT(ident=n),pre,io)
      equation
        // search in the instance hierarchy for the *CORRECT* prefix for this outer variable!
        InnerOuter.INST_INNER(innerPrefix=innerPrefix, instResult=SOME(_)) = 
           InnerOuter.lookupInnerVar(cache, env, ih, pre, n, io);        
      then
        (cache,innerPrefix);      

    // adrpo: prefix normally if we have an inner outer variable!
    case (cache,env,ih,cref as DAE.CREF_QUAL(ident=_),pre,io)
      equation
        // strip the last one to get the prefix
        crefPrefix = Exp.crefStripLastIdent(cref);
        // get the last one
        n = Exp.crefLastIdent(cref);
        // suffix the prefix with the cref prefix
        pre = prefixAddCref(pre, crefPrefix);
        // search in the instance hierarchy for the *CORRECT* prefix for this outer variable!
        InnerOuter.INST_INNER(innerPrefix=innerPrefix, instResult=SOME(_)) = 
           InnerOuter.lookupInnerVar(cache, env, ih, pre, n, io);
      then
        (cache,innerPrefix);
        
    // adrpo: not found in the case above, strip last and call it recursively!
    case (cache,env,ih,cref as DAE.CREF_QUAL(ident=_),pre,io)
      equation
        // strip the last one
        crefPrefix = Exp.crefStripLastIdent(cref);
        (cache, innerPrefix) = searchForInnerPrefix(cache, env, ih, crefPrefix, pre, io); 
      then
        (cache,innerPrefix);
        
    // failure!
    case (cache,env,ih,cref,pre,io)
      equation
        Debug.fprintln("failtrace", "- PrefixUtil.searchForInnerPrefix failed to find the inner prefix for: " +& 
           printPrefixStr(pre) +& "/" +& Exp.printComponentRefStr(cref));  
      then
        fail();
  end matchcontinue;
end searchForInnerPrefix;

public function prefixExp "function: prefixExp
  Add the supplied prefix to all component references in an expression."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input DAE.Exp inExp;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
algorithm
  (outCache,outExp) := matchcontinue (inCache,inEnv,inIH,inExp,inPrefix)
    local
      DAE.Exp e,e1_1,e2_1,e1,e2,e3_1,e3,cref_1,dim_1,cref,dim,start_1,stop_1,start,stop,step_1,step,e_1,exp_1,iterexp_1,exp,iterexp;
      DAE.ComponentRef p_1,p;
      list<Env.Frame> env;
      DAE.ExpType t;
      Prefix pre;
      DAE.Operator o;
      list<DAE.Exp> es_1,es,el,el_1;
      Absyn.Path f,fcn;
      Boolean b,bi,a;
      DAE.InlineType inl;
      list<Boolean> bl;
      list<tuple<DAE.Exp, Boolean>> x_1,x;
      list<list<tuple<DAE.Exp, Boolean>>> xs_1,xs;
      String id,s,n;
      Env.Cache cache;
      list<DAE.Exp> expl;
      Absyn.InnerOuter io;
      InstanceHierarchy ih;
      Prefix innerPrefix;
      DAE.ComponentRef lastCref;
      
    // no prefix, return the input expression
    case (cache,_,_,e,Prefix.NOPRE()) then (cache,e);
      
    // handle literal constants       
    case (cache,_,_,(e as DAE.ICONST(integer = _)),_) then (cache,e); 
    case (cache,_,_,(e as DAE.RCONST(real = _)),_) then (cache,e); 
    case (cache,_,_,(e as DAE.SCONST(string = _)),_) then (cache,e); 
    case (cache,_,_,(e as DAE.BCONST(bool = _)),_) then (cache,e);

    // adrpo: handle prefixing of inner/outer variables
    case (cache,env,ih,DAE.CREF(componentRef = p,ty = t),pre)
      equation
        true = System.getHasInnerOuterDefinitions();
        p_1 = InnerOuter.prefixOuterCrefWithTheInnerPrefix(ih, p, pre);
      then
        (cache,DAE.CREF(p_1,t));

    case (cache,env,ih,DAE.CREF(componentRef = p,ty = t),pre)
      equation
        // adrpo: ask for NONE() here as if we have SOME(...) it means 
        //        this is a for iterator and WE SHOULD NOT PREFIX IT!
        (cache,_,_,_,NONE(),_,_,_) = Lookup.lookupVarLocal(cache, env, p);
        p_1 = prefixCref(pre, p);
      then
        (cache,DAE.CREF(p_1,t));

    case (cache,env,_,e as DAE.CREF(componentRef = p,ty = t),pre)
      equation
        // adrpo: do NOT prefix if we have a for iterator!
        (cache,_,_,_,SOME(_),_,_,_) = Lookup.lookupVarLocal(cache, env, p);
      then
        (cache,e);

    case (cache,env,_,e as DAE.CREF(componentRef = p),pre)
      equation 
        failure((_,_,_,_,_,_,_,_) = Lookup.lookupVarLocal(cache, env, p));
      then
        (cache,e);
    
    /*/ handle array subscripts 
    case (cache,env,(e as DAE.ASUB(exp = e1 as DAE.CREF(componentRef = p, ty = t), sub = expl)),pre)
      equation
        // adrpo: ask for NONE() here as if we have SOME(...) it means 
        //        this is a for iterator and WE SHOULD NOT PREFIX IT!
        (cache,_,_,_,_) = Lookup.lookupVarLocal(cache, env, p);
        (cache,es_1) = prefixExpList(cache, env, ih, expl, pre);
        p_1 = prefixCref(pre, p);
        e2 = DAE.ASUB(DAE.CREF(p_1,t),es_1);
      then
        (cache,e2);*/ 
      
    case (cache,env,ih,(e as DAE.ASUB(exp = e1, sub = expl)),pre) 
      equation
        (cache,es_1) = prefixExpList(cache, env, ih, expl, pre);
        (cache,e1) = prefixExp(cache, env, ih, e1,pre);
        e2 = DAE.ASUB(e1,es_1);
      then 
        (cache,e2);    
    
    case (cache,env,ih,DAE.BINARY(exp1 = e1,operator = o,exp2 = e2),p)
      local Prefix p;
      equation
        (cache,e1_1) = prefixExp(cache, env, ih, e1, p);
        (cache,e2_1) = prefixExp(cache, env, ih, e2, p);
      then
        (cache,DAE.BINARY(e1_1,o,e2_1));

    case (cache,env,ih,DAE.UNARY(operator = o,exp = e1),p)
      local Prefix p;
      equation
        (cache,e1_1) = prefixExp(cache, env, ih, e1, p);
      then
        (cache,DAE.UNARY(o,e1_1));

    case (cache,env,ih,DAE.LBINARY(exp1 = e1,operator = o,exp2 = e2),p)
      local Prefix p;
      equation
        (cache,e1_1) = prefixExp(cache, env, ih, e1, p);
        (cache,e2_1) = prefixExp(cache, env, ih, e2, p);
      then
        (cache,DAE.LBINARY(e1_1,o,e2_1));

    case (cache,env,ih,DAE.LUNARY(operator = o,exp = e1),p)
      local Prefix p;
      equation
        (cache,e1_1) = prefixExp(cache, env, ih, e1, p);
      then
        (cache,DAE.LUNARY(o,e1_1));

    case (cache,env,ih,DAE.RELATION(exp1 = e1,operator = o,exp2 = e2),p)
      local Prefix p;
      equation
        (cache,e1_1) = prefixExp(cache, env, ih, e1, p);
        (cache,e2_1) = prefixExp(cache, env, ih, e2, p);
      then
        (cache,DAE.RELATION(e1_1,o,e2_1));

    case (cache,env,ih,DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),p)
      local Prefix p;
      equation
        (cache,e1_1) = prefixExp(cache, env, ih, e1, p);
        (cache,e2_1) = prefixExp(cache, env, ih, e2, p);
        (cache,e3_1) = prefixExp(cache, env, ih, e3, p);
      then
        (cache,DAE.IFEXP(e1_1,e2_1,e3_1));

    case (cache,env,ih,DAE.SIZE(exp = cref,sz = SOME(dim)),p)
      local Prefix p;
      equation
        (cache,cref_1) = prefixExp(cache, env, ih, cref, p);
        (cache,dim_1) = prefixExp(cache, env, ih, dim, p);
      then
        (cache,DAE.SIZE(cref_1,SOME(dim_1)));

    case (cache,env,ih,DAE.SIZE(exp = cref,sz = NONE),p)
      local Prefix p;
      equation
        (cache,cref_1) = prefixExp(cache, env, ih, cref, p);
      then
        (cache,DAE.SIZE(cref_1,NONE));

    case (cache,env,ih,DAE.CALL(path = f,expLst = es,tuple_ = b,builtin = bi,ty = tp,inlineType = inl),p)
      local Prefix p; DAE.ExpType tp;
      equation
        (cache,es_1) = prefixExpList(cache, env, ih, es, p);
      then
        (cache,DAE.CALL(f,es_1,b,bi,tp,inl));

    case (cache,env,ih,DAE.ARRAY(ty = t,scalar = a,array = {}),p)
      local Prefix p;
      then
        (cache,DAE.ARRAY(t,a,{}));

    /*case (cache,env,Exp.ARRAY(ty = t,scalar = a,array = es),p as Prefix.PREFIX(Prefix.PRE(_,{i},_),_))
      local Prefix p; Integer i; DAE.Exp e;
      equation
        e = listNth(es, i-1);
        Debug.fprint("prefix", "{v1,v2,v3}[" +& intString(i) +& "] => "  +& Exp.printExp2Str(e) +& "\n");
      then
        (cache,e);    */

    case (cache,env,ih,DAE.ARRAY(ty = t,scalar = a,array = es),p)
      local Prefix p;
      equation
        (cache,es_1) = prefixExpList(cache, env, ih, es, p);
      then
        (cache,DAE.ARRAY(t,a,es_1));

    case (cache,env,ih,DAE.TUPLE(PR = es),p)
      local Prefix p;
      equation
        (cache,es_1) = prefixExpList(cache, env, ih, es, p);
      then
        (cache,DAE.TUPLE(es_1));

    case (cache,env,ih,DAE.MATRIX(ty = t,integer = a,scalar = {}),p)
      local
        Integer a;
        Prefix p;
      then
        (cache,DAE.MATRIX(t,a,{}));

    case (cache,env,ih,DAE.MATRIX(ty = t,integer = a,scalar = (x :: xs)),p)
      local
        Integer b,a;
        Prefix p;
      equation
        el = Util.listMap(x, Util.tuple21);
        bl = Util.listMap(x, Util.tuple22);
        (cache,el_1) = prefixExpList(cache, env, ih, el, p);
        x_1 = Util.listThreadTuple(el_1, bl);
        (cache,DAE.MATRIX(t,b,xs_1)) = prefixExp(cache, env, ih, DAE.MATRIX(t,a,xs), p);
      then
        (cache,DAE.MATRIX(t,a,(x_1 :: xs_1)));

    case (cache,env,ih,DAE.RANGE(ty = t,exp = start,expOption = NONE,range = stop),p)
      local Prefix p;
      equation
        (cache,start_1) = prefixExp(cache, env, ih, start, p);
        (cache,stop_1) = prefixExp(cache, env, ih, stop, p);
      then
        (cache,DAE.RANGE(t,start_1,NONE,stop_1));

    case (cache,env,ih,DAE.RANGE(ty = t,exp = start,expOption = SOME(step),range = stop),p)
      local Prefix p;
      equation
        (cache,start_1) = prefixExp(cache, env, ih, start, p);
        (cache,step_1) = prefixExp(cache, env, ih, step, p);
        (cache,stop_1) = prefixExp(cache, env, ih, stop, p);
      then
        (cache,DAE.RANGE(t,start_1,SOME(step_1),stop_1));

    case (cache,env,ih,DAE.CAST(ty = tp,exp = e),p)
      local Prefix p; DAE.ExpType tp;
      equation
        (cache,e_1) = prefixExp(cache, env, ih, e, p);
      then
        (cache,DAE.CAST(tp,e_1));

    case (cache,env,ih,DAE.REDUCTION(path = fcn,expr = exp,ident = id,range = iterexp),p)
      local Prefix p;
      equation
        (cache,exp_1) = prefixExp(cache, env, ih, exp, p);
        (cache,iterexp_1) = prefixExp(cache, env, ih, iterexp, p);
      then
        (cache,DAE.REDUCTION(fcn,exp_1,id,iterexp_1));

    case (cache,env,ih,DAE.VALUEBLOCK(t,localDecls = lDecls,body = b,result = exp),p)
      local
        list<DAE.Statement> b;
        list<DAE.Element> lDecls;
        Prefix p;
        DAE.ExpType t;
      equation
        (cache,lDecls) = prefixDecls(cache, env, ih, lDecls, {}, p);
        (cache,b) = prefixStatements(cache, env, ih, b, {}, p);
        (cache,exp) = prefixExp(cache, env, ih, exp, p);
      then
        (cache,DAE.VALUEBLOCK(t,lDecls,b,exp));

    // MetaModelica extension. KS
    case (cache,env,ih,DAE.LIST(t,es),p)
      local Prefix p;
        DAE.ExpType t;
      equation
        (cache,es_1) = prefixExpList(cache, env, ih, es, p);
      then (cache,DAE.LIST(t,es_1));

    case (cache,env,ih,DAE.CONS(t,e1,e2),p)
      local Prefix p;
        DAE.ExpType t;
      equation
        (cache,e1) = prefixExp(cache, env, ih, e1, p);
        (cache,e2) = prefixExp(cache, env, ih, e2, p);
      then (cache,DAE.CONS(t,e1,e2));

    case (cache,env,ih,DAE.META_TUPLE(es),p)
      local Prefix p;
      equation
        (cache,es_1) = prefixExpList(cache, env, ih, es, p);
      then (cache,DAE.META_TUPLE(es_1));

    case (cache,env,ih,DAE.META_OPTION(SOME(e1)),p)
      local Prefix p;
      equation
        (cache,e1) = prefixExp(cache, env, ih, e1, p);
      then (cache,DAE.META_OPTION(SOME(e1)));

    case (cache,env,ih,DAE.META_OPTION(NONE()),p)
      local Prefix p;
      equation
      then (cache,DAE.META_OPTION(NONE()));
        // ------------------------

    case (_,_,_,e,_)
      equation
				true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "-prefix_exp failed on exp:");
        s = Exp.printExpStr(e);
        Debug.fprint("failtrace", s);
        Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end prefixExp;

public function prefixExpList "function: prefixExpList
  This function prefixes a list of expressions using the prefixExp function."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input list<DAE.Exp> inExpExpLst;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output list<DAE.Exp> outExpExpLst;
algorithm
  (outCache,outExpExpLst) := matchcontinue (inCache,inEnv,inIH,inExpExpLst,inPrefix)
    local
      DAE.Exp e_1,e;
      list<DAE.Exp> es_1,es;
      list<Env.Frame> env;
      Prefix p;
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
  end matchcontinue;
end prefixExpList;

public function prefixCrefList "function: prefixCrefList
  This function prefixes a list of component 
  references using the prefixCref function."
  input Prefix inPrefix;
  input list<DAE.ComponentRef> inExpComponentRefLst;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst := matchcontinue (inPrefix,inExpComponentRefLst)
    local
      DAE.ComponentRef cr_1,cr;
      list<DAE.ComponentRef> crlist_1,crlist;
      Prefix p;

    case (_,{}) then {}; 
    case (p,(cr :: crlist))
      equation
        cr_1 = prefixCref(p, cr);
        crlist_1 = prefixCrefList(p, crlist);
      then
        (cr_1 :: crlist_1);
  end matchcontinue;
end prefixCrefList;

//--------------------------------------------
//   PART OF THE WORKAROUND FOR VALUEBLOCKS. KS
protected function prefixDecls "function: prefixDecls
  Add the supplied prefix to the DAE elements located in Exp.mo.
  PART OF THE WORKAROUND FOR VALUEBLOCKS"
  input Env.Cache cache;
  input Env.Env env;
  input InstanceHierarchy inIH;  
	input list<DAE.Element> lDecls;
	input list<DAE.Element> accList;
  input Prefix p;
  output Env.Cache outCache;
	output list<DAE.Element> outDecls;
algorithm
  (outCache,outDecls) := matchcontinue (cache,env,inIH,lDecls,accList,p)
    local
      list<DAE.Element> localAccList;
      Prefix pre;
      Env.Cache localCache;
      Env.Env localEnv;
      DAE.ElementSource source "the origin of the element";
      InstanceHierarchy ih;

    case (localCache,_,_,{},localAccList,_) then (localCache,localAccList);
    // variables
    case (localCache,localEnv,ih,DAE.VAR(cRef,v1,v2,prot,ty,binding,dims,
      											flowPrefix,streamPrefix,source,vAttr,com,inOut)
       :: rest,localAccList,pre)
    local
      DAE.ComponentRef cRef;
    	DAE.VarKind v1 "varible kind variable, constant, parameter, etc." ;
    	DAE.VarDirection v2 "input, output or bidir" ;
    	DAE.VarProtection prot "if protected or public";
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
    equation
      cRef = prefixCref(pre,cRef);
      elem = DAE.VAR(cRef,v1,v2,prot,ty,binding,dims,flowPrefix,streamPrefix,source,vAttr,com,inOut);
      localAccList = listAppend(localAccList,Util.listCreate(elem));
      (localCache,temp) = prefixDecls(localCache,localEnv,ih,rest,localAccList,pre);
    then (localCache,temp);

    // equations
    case (localCache,localEnv,ih,DAE.EQUATION(e1,e2,source) :: rest,localAccList,pre)
      local
        DAE.Exp e1,e2;
        list<DAE.Element> rest,temp;
        DAE.Element elem;
      equation
        (localCache,e1) = prefixExp(localCache,localEnv,ih,e1,pre);
        (localCache,e2) = prefixExp(localCache,localEnv,ih,e2,pre);
        elem = DAE.EQUATION(e1,e2,source);
        localAccList = listAppend(localAccList,Util.listCreate(elem));
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
	input Prefix p;
	output Env.Cache outCache;
	output list<DAE.Statement> outStmts;
algorithm
  (outCache,outStmts) :=
  matchcontinue (cache,env,inIH,stmts,accList,p)
    local
      Env.Cache localCache;
      Env.Env localEnv;
      list<DAE.Statement> localAccList,rest;
      Prefix pre;
      InstanceHierarchy ih;
      DAE.ElementSource source;
      
    case (localCache,_,_,{},localAccList,_) then (localCache,localAccList);

    case (localCache,localEnv,ih,DAE.STMT_ASSIGN(t,e1,e,source) :: rest,localAccList,pre)
      local
      	DAE.ExpType t;
    		DAE.Exp e,e1;
    		DAE.Statement elem;
    		list<DAE.Statement> elems;
    	equation
    	  (localCache,e1) = prefixExp(localCache,localEnv,ih,e1,pre);
    	  (localCache,e) = prefixExp(localCache,localEnv,ih,e,pre);
    	  elem = DAE.STMT_ASSIGN(t,e1,e,source);
    	  localAccList = listAppend(localAccList,Util.listCreate(elem));
    	  (localCache,elems) = prefixStatements(localCache,localEnv,ih,rest,localAccList,pre);
    	then (localCache,elems);

  	case (localCache,localEnv,ih,DAE.STMT_TUPLE_ASSIGN(t,eLst,e,source) :: rest,localAccList,pre)
			local
      	DAE.ExpType t;
    		DAE.Exp e;
    		list<DAE.Exp> eLst;
    		DAE.Statement elem;
    		list<DAE.Statement> elems;
    	equation
    	  (localCache,e) = prefixExp(localCache,localEnv,ih,e,pre);
    	  (localCache,eLst) = prefixExpList(localCache,localEnv,ih,eLst,pre);
    	  elem = DAE.STMT_TUPLE_ASSIGN(t,eLst,e,source);
    	  localAccList = listAppend(localAccList,Util.listCreate(elem));
    	  (localCache,elems) = prefixStatements(localCache,localEnv,ih,rest,localAccList,pre);
    	then (localCache,elems);

  	case (localCache,localEnv,ih,DAE.STMT_ASSIGN_ARR(t,cRef,e,source) :: rest,localAccList,pre)
      local
      	DAE.ExpType t;
    		DAE.ComponentRef cRef;
    		DAE.Exp e;
    		DAE.Statement elem;
    		list<DAE.Statement> elems;
    	equation
    	  cRef = prefixCref(pre,cRef);
    	  (localCache,e) = prefixExp(localCache,localEnv,ih,e,pre);
    	  elem = DAE.STMT_ASSIGN_ARR(t,cRef,e,source);
    	  localAccList = listAppend(localAccList,Util.listCreate(elem));
    	  (localCache,elems) = prefixStatements(localCache,localEnv,ih,rest,localAccList,pre);
    	then (localCache,elems);

    case (localCache,localEnv,ih,DAE.STMT_FOR(t,bool,id,e,sList,source) :: rest,localAccList,pre)
      local
      	DAE.ExpType t;
        Boolean bool;
        String id;
        DAE.Exp e;
    		DAE.Statement elem;
    		list<DAE.Statement> elems,sList;
    	equation
    	  (localCache,e) = prefixExp(localCache,localEnv,ih,e,pre);
    	  (localCache,sList) = prefixStatements(localCache,localEnv,ih,sList,{},pre);
    	  elem = DAE.STMT_FOR(t,bool,id,e,sList,source);
    	  localAccList = listAppend(localAccList,Util.listCreate(elem));
    	  (localCache,elems) = prefixStatements(localCache,localEnv,ih,rest,localAccList,pre);
    	then (localCache,elems);

  case (localCache,localEnv,ih,DAE.STMT_IF(e1,sList,elseBranch,source) :: rest,localAccList,pre)
      local
        DAE.Exp e1;
        list<DAE.Statement> sList,elems;
        DAE.Else elseBranch;
        DAE.Statement elem;
      equation
        (localCache,e1) = prefixExp(localCache,localEnv,ih,e1,pre);
        (localCache,sList) = prefixStatements(localCache,localEnv,ih,sList,{},pre);
        (localCache,elseBranch) = prefixElse(localCache,localEnv,ih,elseBranch,pre);
        elem = DAE.STMT_IF(e1,sList,elseBranch,source);
        localAccList = listAppend(localAccList,Util.listCreate(elem));
        (localCache,elems) = prefixStatements(localCache,localEnv,ih,rest,localAccList,pre);
      then (localCache,elems);

    case (localCache,localEnv,ih,DAE.STMT_WHILE(e1,sList,source) :: rest,localAccList,pre)
      local
        DAE.Exp e1;
        list<DAE.Statement> sList,elems;
        DAE.Statement elem;
      equation
        (localCache,e1) = prefixExp(localCache,localEnv,ih,e1,pre);
        (localCache,sList) = prefixStatements(localCache,localEnv,ih,sList,{},pre);
        elem = DAE.STMT_WHILE(e1,sList,source);
        localAccList = listAppend(localAccList,Util.listCreate(elem));
        (localCache,elems) = prefixStatements(localCache,localEnv,ih,rest,localAccList,pre);
      then (localCache,elems);

    case (localCache,localEnv,ih,DAE.STMT_ASSERT(e1,e2,source) :: rest,localAccList,pre)
      local
        DAE.Exp e1,e2;
        list<DAE.Statement> elems;
        DAE.Statement elem;
      equation
        (localCache,e1) = prefixExp(localCache,localEnv,ih,e1,pre);
        (localCache,e2) = prefixExp(localCache,localEnv,ih,e2,pre);
        elem = DAE.STMT_ASSERT(e1,e2,source);
        localAccList = listAppend(localAccList,Util.listCreate(elem));
        (localCache,elems) = prefixStatements(localCache,localEnv,ih,rest,localAccList,pre);
      then (localCache,elems);
  	case (localCache,localEnv,ih,DAE.STMT_TRY(b,source) :: rest,localAccList,pre)
  	  local
  	    list<DAE.Statement> b;
  	    DAE.Statement elem;
    		list<DAE.Statement> elems;
  	  equation
  	    (localCache,b) = prefixStatements(localCache,localEnv,ih,b,{},pre);
  	    elem = DAE.STMT_TRY(b,source);
    	  localAccList = listAppend(localAccList,Util.listCreate(elem));
    	  (localCache,elems) = prefixStatements(localCache,localEnv,ih,rest,localAccList,pre);
    	then (localCache,elems);
  	case (localCache,localEnv,ih,DAE.STMT_CATCH(b,source) :: rest,localAccList,pre)
			local
  	    list<DAE.Statement> b;
  	    DAE.Statement elem;
    		list<DAE.Statement> elems;
  	  equation
  	    (localCache,b) = prefixStatements(localCache,localEnv,ih,b,{},pre);
  	    elem = DAE.STMT_CATCH(b,source);
    	  localAccList = listAppend(localAccList,Util.listCreate(elem));
    	  (localCache,elems) = prefixStatements(localCache,localEnv,ih,rest,localAccList,pre);
    	then (localCache,elems);
  	case (localCache,localEnv,ih,DAE.STMT_THROW(source) :: rest,localAccList,pre)
  	    local
  	    	DAE.Statement elem;
    			list<DAE.Statement> elems;
    		equation
    			elem = DAE.STMT_THROW(source);
    	  	localAccList = listAppend(localAccList,Util.listCreate(elem));
    	  	(localCache,elems) = prefixStatements(localCache,localEnv,ih,rest,localAccList,pre);
    		then (localCache,elems);
  	case (localCache,localEnv,ih,DAE.STMT_RETURN(source) :: rest,localAccList,pre)
  	    local
  	    	DAE.Statement elem;
    			list<DAE.Statement> elems;
    		equation
    			elem = DAE.STMT_RETURN(source);
    	  	localAccList = listAppend(localAccList,Util.listCreate(elem));
    	  	(localCache,elems) = prefixStatements(localCache,localEnv,ih,rest,localAccList,pre);
    		then (localCache,elems);
  	case (localCache,localEnv,ih,DAE.STMT_BREAK(source) :: rest,localAccList,pre)
  	    local
  	    	DAE.Statement elem;
    			list<DAE.Statement> elems;
    		equation
    			elem = DAE.STMT_BREAK(source);
    	  	localAccList = listAppend(localAccList,Util.listCreate(elem));
    	  	(localCache,elems) = prefixStatements(localCache,localEnv,ih,rest,localAccList,pre);
    		then (localCache,elems);
  	case (localCache,localEnv,ih,DAE.STMT_GOTO(s,source) :: rest,localAccList,pre)
  	  local
  	    DAE.Statement elem;
  	    list<DAE.Statement> elems;
  	    String s;
  	  equation
  	    elem = DAE.STMT_GOTO(s,source);
  	    localAccList = listAppend(localAccList,Util.listCreate(elem));
  	    (localCache,elems) = prefixStatements(localCache,localEnv,ih,rest,localAccList,pre);
  	  then (localCache,elems);
  	case (localCache,localEnv,ih,DAE.STMT_LABEL(s,source) :: rest,localAccList,pre)
  	  local
  	    DAE.Statement elem;
  	    list<DAE.Statement> elems;
  	    String s;
  	  equation
  	    elem = DAE.STMT_LABEL(s,source);
  	    localAccList = listAppend(localAccList,Util.listCreate(elem));
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
  input Prefix p;
  output Env.Cache outCache;
  output DAE.Else outElse;
algorithm
  (outCache,outElse) := matchcontinue (cache,env,inIH,elseBranch,p)
    local
      Env.Cache localCache;
      Env.Env localEnv;
      Prefix pre;
      InstanceHierarchy ih;
      
    case (localCache,localEnv,ih,DAE.NOELSE(),pre)
      then (localCache,DAE.NOELSE());

    case (localCache,localEnv,ih,DAE.ELSEIF(e,lStmt,el),pre)
      local
        DAE.Exp e;
        list<DAE.Statement> lStmt;
        DAE.Else el;
        DAE.Else stmt;
      equation
        (localCache,e) = prefixExp(localCache,localEnv,ih,e,pre);
        (localCache,el) = prefixElse(localCache,localEnv,ih,el,pre);
        (localCache,lStmt) = prefixStatements(localCache,localEnv,ih,lStmt,{},pre);
        stmt = DAE.ELSEIF(e,lStmt,el);
      then (localCache,stmt);

    case (localCache,localEnv,ih,DAE.ELSE(lStmt),pre)
      local
        list<DAE.Statement> lStmt;
        DAE.Else stmt;
      equation
       (localCache,lStmt) = prefixStatements(localCache,localEnv,ih,lStmt,{},pre);
        stmt = DAE.ELSE(lStmt);
      then (localCache,stmt);
  end matchcontinue;
end prefixElse;

public function prefixAddCref "function: prefixAddCref
  This function is used to extend a prefix with a given component refence:
  Example: 
    prefix: a.b + cref: c.d => a.b.c.d"
  input Prefix inPrefix;
  input DAE.ComponentRef inCref;
  output Prefix outPrefix;
algorithm
  outPrefix := matchcontinue (inPrefix,inCref)
    local
      Prefix.Prefix pre;
      String id;
      DAE.ComponentRef next;

    case(pre, DAE.CREF_IDENT(ident=id))
      equation
        pre = prefixAdd(id, {}, pre, SCode.VAR());
      then 
        pre;

    case(pre, DAE.CREF_QUAL(ident=id, componentRef=next))
      equation
        pre = prefixAdd(id, {}, pre, SCode.VAR());
        pre = prefixAddCref(pre, next);
      then 
        pre;
  end matchcontinue;
end prefixAddCref;

end PrefixUtil;
