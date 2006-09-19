package Prefix "
This file is part of OpenModelica.

Copyright (c) 1998-2005, Link�pings universitet, Department of
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

  
  file:	 Prefix.rml
  module:      Prefix
  description: Prefix management
 
  RCS: $Id$
 
  When instantiating an expression, there is a prefix that 
  has to be added to each variable name to be able to use it in the 
  flattened equation set.
  
  A prefix for a variable x could be for example a.b.c so that the 
  fully qualified name is a.b.c.x. 
 
"

public import OpenModelica.Compiler.Absyn;

public import OpenModelica.Compiler.Exp;

public import OpenModelica.Compiler.Env;

public import OpenModelica.Compiler.Lookup;

public 
uniontype Prefix "A \'Prefix\' has a name an a list of constant valued subscripts."
  record NOPRE end NOPRE;

  record PRE
    String prefix "prefix name" ;
    list<Integer> subscripts "subscripts" ;
    Prefix next "next prefix" ;
  end PRE;

end Prefix;

protected import OpenModelica.Compiler.Util;

protected import OpenModelica.Compiler.Print;

protected import OpenModelica.Compiler.Debug;

public function printPrefixStr "function: printPrefixStr
  
  Prints a Prefix to a string.
"
  input Prefix inPrefix;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inPrefix)
    local
      String str,s,rest_1,s_1,s_2;
      Prefix rest;
    case NOPRE() then "<NOPRE>"; 
    case PRE(prefix = str,subscripts = {},next = NOPRE()) then str; 
    case PRE(prefix = str,next = NOPRE())
      equation 
        s = stringAppend(str, "[]");
      then
        s;
    case PRE(prefix = str,subscripts = {},next = rest)
      equation 
        rest_1 = printPrefixStr(rest);
        s = stringAppend(rest_1, ".");
        s_1 = stringAppend(s, str);
      then
        s_1;
    case PRE(prefix = str,next = rest)
      equation 
        rest_1 = printPrefixStr(rest);
        s = stringAppend(rest_1, ".");
        s_1 = stringAppend(s, str);
        s_2 = stringAppend(s_1, "[]");
      then
        s_2;
  end matchcontinue;
end printPrefixStr;

public function printPrefix "function: printPrefix
 
  Prints a prefix to the Print buffer.
"
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
  normal order used when displaying them.
"
  input Exp.Ident inIdent;
  input list<Integer> inIntegerLst;
  input Prefix inPrefix;
  output Prefix outPrefix;
algorithm 
  outPrefix:=
  matchcontinue (inIdent,inIntegerLst,inPrefix)
    local
      String i;
      list<Integer> s;
      Prefix p;
    case (i,s,p) then PRE(i,s,p); 
  end matchcontinue;
end prefixAdd;

public function prefixFirst
  input Prefix inPrefix;
  output Prefix outPrefix;
algorithm 
  outPrefix:=
  matchcontinue (inPrefix)
    local
      String a;
      list<Integer> b;
      Prefix c;
    case (PRE(prefix = a,subscripts = b,next = c)) then PRE(a,b,NOPRE()); 
  end matchcontinue;
end prefixFirst;

public function prefixLast "function: prefixLast
 
  Returns the last NONPRE Prefix of a prefix
"
  input Prefix inPrefix;
  output Prefix outPrefix;
algorithm 
  outPrefix:=
  matchcontinue (inPrefix)
    local Prefix p,res;
    case ((p as PRE(next = NOPRE()))) then p; 
    case (PRE(next = p))
      equation 
        res = prefixLast(p);
      then
        res;
  end matchcontinue;
end prefixLast;

public function prefixPath "function: prefixPath
 
  Prefix a `Path\' variable by adding the supplied prefix to it and
  returning a new `Path\'.
"
  input Absyn.Path inPath;
  input Prefix inPrefix;
  output Absyn.Path outPath;
algorithm 
  outPath:=
  matchcontinue (inPath,inPrefix)
    local
      Absyn.Path p,p_1;
      String s;
      Prefix ss;
    case (p,NOPRE()) then p; 
    case (p,PRE(prefix = s,next = ss))
      equation 
        p_1 = prefixPath(Absyn.QUALIFIED(s,p), ss);
      then
        p_1;
  end matchcontinue;
end prefixPath;

public function prefixToPath "function: prefixToPath
 
  Convert a Prefix to a `Path\'
"
  input Prefix inPrefix;
  output Absyn.Path outPath;
algorithm 
  outPath:=
  matchcontinue (inPrefix)
    local
      String s;
      Absyn.Path p;
      Prefix ss;
    case NOPRE()
      equation 
        Print.printBuf("#-- Error: Cannot convert empty prefix to a path\n");
      then
        fail();
    case PRE(prefix = s,next = NOPRE()) then Absyn.IDENT(s); 
    case PRE(prefix = s,next = ss)
      equation 
        p = prefixToPath(ss);
      then
        Absyn.QUALIFIED(s,p);
  end matchcontinue;
end prefixToPath;

public function prefixCref "function: prefixCref
 
  Prefix a `ComponentRef\' variable by adding the supplied prefix to
  it and returning a new `ComponentRef\'.
 
  LS: Changed to call prefix_to_cref which is more general now
"
  input Prefix pre;
  input Exp.ComponentRef cref;
  output Exp.ComponentRef cref_1;
  Exp.ComponentRef cref_1;
algorithm 
  cref_1 := prefixToCref2(pre, SOME(cref));
end prefixCref;

public function prefixToCref "function: prefixToCref
 
  Convert a prefix to a component reference.
"
  input Prefix pre;
  output Exp.ComponentRef cref_1;
  Exp.ComponentRef cref_1;
algorithm 
  cref_1 := prefixToCref2(pre, NONE);
end prefixToCref;

protected function prefixToCref2 "function: prefixToCref2
 
  Convert a prefix to a component reference. Converting NOPRE with no
  component reference is an error because a component reference cannot be
  empty
"
  input Prefix inPrefix;
  input Option<Exp.ComponentRef> inExpComponentRefOption;
  output Exp.ComponentRef outComponentRef;
algorithm 
  outComponentRef:=
  matchcontinue (inPrefix,inExpComponentRefOption)
    local
      Exp.ComponentRef cref,cref_1;
      list<Exp.Subscript> s_1;
      String i;
      list<Integer> s;
      Prefix xs;
    case (NOPRE(),NONE)
      equation 
        Print.printBuf("#-- Cannot convert empty prefix to component reference\n");
      then
        fail();
    case (NOPRE(),SOME(cref)) then cref; 
    case (PRE(prefix = i,subscripts = s,next = xs),NONE)
      equation 
        s_1 = Exp.intSubscripts(s);
        cref_1 = prefixToCref2(xs, SOME(Exp.CREF_IDENT(i,s_1)));
      then
        cref_1;
    case (PRE(prefix = i,subscripts = s,next = xs),SOME(cref))
      equation 
        s_1 = Exp.intSubscripts(s);
        cref_1 = prefixToCref2(xs, SOME(Exp.CREF_QUAL(i,s_1,cref)));
      then
        cref_1;
  end matchcontinue;
end prefixToCref2;

public function prefixExp "function: prefixExp
 
  Add the supplied prefix to all component references in an
  expression.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.Exp inExp;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output Exp.Exp outExp;
algorithm 
  (outCache,outExp) :=
  matchcontinue (inCache,inEnv,inExp,inPrefix)
    local
      Exp.Exp e,e1_1,e2_1,e1,e2,e3_1,e3,cref_1,dim_1,cref,dim,start_1,stop_1,start,stop,step_1,step,e_1,exp_1,iterexp_1,exp,iterexp;
      Exp.ComponentRef p_1,p;
      list<Env.Frame> env;
      Exp.Type t;
      Prefix pre;
      Exp.Operator o;
      list<Exp.Exp> es_1,es,el,el_1;
      Absyn.Path f,fcn;
      Boolean b,bi,a;
      list<Boolean> bl;
      list<tuple<Exp.Exp, Boolean>> x_1,x;
      list<list<tuple<Exp.Exp, Boolean>>> xs_1,xs;
      String id,s;
      Env.Cache cache;
    case (cache,_,(e as Exp.ICONST(integer = _)),_) then (cache,e); 
    case (cache,_,(e as Exp.RCONST(real = _)),_) then (cache,e); 
    case (cache,_,(e as Exp.SCONST(string = _)),_) then (cache,e); 
    case (cache,_,(e as Exp.BCONST(bool = _)),_) then (cache,e); 
    case (cache,env,Exp.CREF(componentRef = p,ty = t),pre)
      equation 
        (cache,_,_,_) = Lookup.lookupVarLocal(cache,env, p);
        p_1 = prefixCref(pre, p);
      then
        (cache,Exp.CREF(p_1,t));
    case (cache,env,(e as Exp.CREF(componentRef = p)),pre)
      equation 
        failure((_,_,_,_) = Lookup.lookupVarLocal(cache,env, p));
      then
        (cache,e);
    case (cache,env,Exp.BINARY(exp1 = e1,operator = o,exp2 = e2),p)
      local Prefix p;
      equation 
        (cache,e1_1) = prefixExp(cache,env, e1, p);
        (cache,e2_1) = prefixExp(cache,env, e2, p);
      then
        (cache,Exp.BINARY(e1_1,o,e2_1));
    case (cache,env,Exp.UNARY(operator = o,exp = e1),p)
      local Prefix p;
      equation 
        (cache,e1_1) = prefixExp(cache,env, e1, p);
      then
        (cache,Exp.UNARY(o,e1_1));
    case (cache,env,Exp.LBINARY(exp1 = e1,operator = o,exp2 = e2),p)
      local Prefix p;
      equation 
        (cache,e1_1) = prefixExp(cache,env, e1, p);
        (cache,e2_1) = prefixExp(cache,env, e2, p);
      then
        (cache,Exp.LBINARY(e1_1,o,e2_1));
    case (cache,env,Exp.LUNARY(operator = o,exp = e1),p)
      local Prefix p;
      equation 
        (cache,e1_1) = prefixExp(cache,env, e1, p);
      then
        (cache,Exp.LUNARY(o,e1_1));
    case (cache,env,Exp.RELATION(exp1 = e1,operator = o,exp2 = e2),p)
      local Prefix p;
      equation 
        (cache,e1_1) = prefixExp(cache,env, e1, p);
        (cache,e2_1) = prefixExp(cache,env, e2, p);
      then
        (cache,Exp.RELATION(e1_1,o,e2_1));
    case (cache,env,Exp.IFEXP(expCond = e1,expThen = e2,expElse = e3),p)
      local Prefix p;
      equation 
        (cache,e1_1) = prefixExp(cache,env, e1, p);
        (cache,e2_1) = prefixExp(cache,env, e2, p);
        (cache,e3_1) = prefixExp(cache,env, e3, p);
      then
        (cache,Exp.IFEXP(e1_1,e2_1,e3_1));
    case (cache,env,Exp.SIZE(exp = cref,sz = SOME(dim)),p)
      local Prefix p;
      equation 
        (cache,cref_1) = prefixExp(cache,env, cref, p);
        (cache,dim_1) = prefixExp(cache,env, dim, p);
      then
        (cache,Exp.SIZE(cref_1,SOME(dim_1)));
    case (cache,env,Exp.SIZE(exp = cref,sz = NONE),p)
      local Prefix p;
      equation 
        (cache,cref_1) = prefixExp(cache,env, cref, p);
      then
        (cache,Exp.SIZE(cref_1,NONE));
    case (cache,env,Exp.CALL(path = f,expLst = es,tuple_ = b,builtin = bi,ty = tp),p)
      local Prefix p; Exp.Type tp;
      equation 
        (cache,es_1) = prefixExpList(cache,env, es, p);
      then
        (cache,Exp.CALL(f,es_1,b,bi,tp)); 
    case (cache,env,Exp.ARRAY(ty = t,scalar = a,array = {}),p)
      local Prefix p;
      then
        (cache,Exp.ARRAY(t,a,{}));
    case (cache,env,Exp.ARRAY(ty = t,scalar = a,array = es),p)
      local Prefix p;
      equation 
        (cache,es_1) = prefixExpList(cache,env, es, p);
      then
        (cache,Exp.ARRAY(t,a,es_1));
    case (cache,env,Exp.TUPLE(PR = es),p)
      local Prefix p;
      equation 
        (cache,es_1) = prefixExpList(cache,env, es, p);
      then
        (cache,Exp.TUPLE(es_1));
    case (cache,env,Exp.MATRIX(ty = t,integer = a,scalar = {}),p)
      local
        Integer a;
        Prefix p;
      then
        (cache,Exp.MATRIX(t,a,{}));
    case (cache,env,Exp.MATRIX(ty = t,integer = a,scalar = (x :: xs)),p)
      local
        Integer b,a;
        Prefix p;
      equation 
        el = Util.listMap(x, Util.tuple21);
        bl = Util.listMap(x, Util.tuple22);
        (cache,el_1) = prefixExpList(cache,env, el, p);
        x_1 = Util.listThreadTuple(el_1, bl);
        (cache,Exp.MATRIX(t,b,xs_1)) = prefixExp(cache,env, Exp.MATRIX(t,a,xs), p);
      then
        (cache,Exp.MATRIX(t,a,(x_1 :: xs_1)));
    case (cache,env,Exp.RANGE(ty = t,exp = start,expOption = NONE,range = stop),p)
      local Prefix p;
      equation 
        (cache,start_1) = prefixExp(cache,env, start, p);
        (cache,stop_1) = prefixExp(cache,env, stop, p);
      then
        (cache,Exp.RANGE(t,start_1,NONE,stop_1));
    case (cache,env,Exp.RANGE(ty = t,exp = start,expOption = SOME(step),range = stop),p)
      local Prefix p;
      equation 
        (cache,start_1) = prefixExp(cache,env, start, p);
        (cache,step_1) = prefixExp(cache,env, step, p);
        (cache,stop_1) = prefixExp(cache,env, stop, p);
      then
        (cache,Exp.RANGE(t,start_1,SOME(step_1),stop_1));
    case (cache,env,Exp.CAST(ty = Exp.REAL(),exp = e),p)
      local Prefix p;
      equation 
        (cache,e_1) = prefixExp(cache,env, e, p);
      then
        (cache,Exp.CAST(Exp.REAL(),e_1));
    case (cache,env,Exp.REDUCTION(path = fcn,expr = exp,ident = id,range = iterexp),p)
      local Prefix p;
      equation 
        (cache,exp_1) = prefixExp(cache,env, exp, p);
        (cache,iterexp_1) = prefixExp(cache,env, iterexp, p);
      then
        (cache,Exp.REDUCTION(fcn,exp_1,id,iterexp_1));
    case (_,_,e,_)
      equation 
        Debug.fprint("failtrace", "-prefix_exp failed on exp:");
        s = Exp.printExpStr(e);
        Debug.fprint("failtrace", s);
        Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end prefixExp;

public function prefixExpList "function: prefixExpList
  
  This function prefixes a list of expressions using the
  `prefix_exp\' function.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  (outCache,outExpExpLst) :=
  matchcontinue (inCache,inEnv,inExpExpLst,inPrefix)
    local
      Exp.Exp e_1,e;
      list<Exp.Exp> es_1,es;
      list<Env.Frame> env;
      Prefix p;
      Env.Cache cache;
    case (cache,_,{},_) then (cache,{}); 
    case (cache,env,(e :: es),p)
      equation 
        (cache,e_1) = prefixExp(cache,env, e, p);
        (cache,es_1) = prefixExpList(cache,env, es, p);
      then
        (cache,e_1 :: es_1);
  end matchcontinue;
end prefixExpList;

public function prefixCrefList "function: prefixCrefList
  
  This function prefixes a list of component references using the
  `prefix_cref function.
"
  input Prefix inPrefix;
  input list<Exp.ComponentRef> inExpComponentRefLst;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inPrefix,inExpComponentRefLst)
    local
      Exp.ComponentRef cr_1,cr;
      list<Exp.ComponentRef> crlist_1,crlist;
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
end Prefix;

