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

encapsulated package ModUtil
" file:         ModUtil.mo
  package:     ModUtil
  description: Miscellanous modelica related utilities (The horror, THE HORROR)

  RCS: $Id$

  This module contains various utilities. For example
  converting a path to a string and comparing two paths.
  It is used pretty much everywhere. The difference between this
  module and the Util module is that ModUtil contains modelica
  related utilities. The Util module only contains \"low-level\"
  mmc utilities, for example finding elements in lists."


public import Absyn;
public import DAE;
public import SCode;
protected import ComponentReference;
protected import RTOpts;
protected import Debug;
protected import Util;
protected import Algorithm;
protected import System;
protected import Expression;

public function makeSubscript "Creates a Subscript from and Exp"
  input Absyn.Exp e;
  output Absyn.Subscript s;
algorithm
  s := Absyn.SUBSCRIPT(e);
end makeSubscript;

protected function stringPrefixComponentRefs ""
  input String inString;
  input FuncTypeExp_ComponentRefType_bTo inFuncTypeExpComponentRefTypeBTo;
  input Type_b inTypeB;
  input list<DAE.Exp> inExpExpLst;
  output list<DAE.Exp> outExpExpLst;
  partial function FuncTypeExp_ComponentRefType_bTo
    input DAE.ComponentRef inComponentRef;
    input Type_b inTypeB;
    replaceable type Type_b subtypeof Any;
  end FuncTypeExp_ComponentRefType_bTo;
  replaceable type Type_b subtypeof Any;
algorithm
  outExpExpLst:=
  matchcontinue (inString,inFuncTypeExpComponentRefTypeBTo,inTypeB,inExpExpLst)
    local
      list<DAE.Exp> res,rest;
      DAE.Exp e_1,e;
      String str;
      FuncTypeExp_ComponentRefType_bTo r;
      Type_b rarg;
    case (_,_,_,{}) then {};
    case (str,r,rarg,(e :: rest))
      equation
        res = stringPrefixComponentRefs(str, r, rarg, rest);
        e_1 = stringPrefixComponentRef(str, r, rarg, e);
      then
        (e_1 :: res);
  end matchcontinue;
end stringPrefixComponentRefs;

protected function stringPrefixComponentRef
  input String inString;
  input FuncTypeExp_ComponentRefType_bTo inFuncTypeExpComponentRefTypeBTo;
  input Type_b inTypeB;
  input DAE.Exp inExp;
  output DAE.Exp outExp;
  partial function FuncTypeExp_ComponentRefType_bTo
    input DAE.ComponentRef inComponentRef;
    input Type_b inTypeB;
    replaceable type Type_b subtypeof Any;
  end FuncTypeExp_ComponentRefType_bTo;
  replaceable type Type_b subtypeof Any;
algorithm
  outExp:=
  matchcontinue (inString,inFuncTypeExpComponentRefTypeBTo,inTypeB,inExp)
    local
      DAE.ComponentRef cr_1,cr;
      String str;
      FuncTypeExp_ComponentRefType_bTo r;
      Type_b rarg;
      DAE.ExpType t,ty;
      DAE.Exp e1_1,e2_1,e1,e2,e3_1,e3,e;
      DAE.Operator op;
      list<DAE.Exp> el_1,el;
      Absyn.Path p;
      Boolean b,bi;
      DAE.InlineType inl;
      list<list<Boolean>> bl;
      list<list<tuple<DAE.Exp, Boolean>>> ell_1,ell;
      Integer i,a;
      list<list<DAE.Exp>> es,es_1;
      DAE.ExpType tp;
      Integer index_;
      Option<tuple<DAE.Exp,Integer,Integer>> isExpisASUB;
      
    case (str,r,rarg,DAE.CREF(componentRef = cr,ty = t))
      equation
        r(cr, rarg);
        cr_1 = stringPrefixCref(str, cr);
        e = Expression.makeCrefExp(cr_1,t);
      then
        e;
    
    // keel it the same on failure
    case (_,r,rarg,e as DAE.CREF(componentRef = cr,ty = t))
      equation
        failure(r(cr, rarg));
      then
        e;
    
    case (str,r,rarg,DAE.BINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
        e1_1 = stringPrefixComponentRef(str, r, rarg, e1);
        e2_1 = stringPrefixComponentRef(str, r, rarg, e2);
      then
        DAE.BINARY(e1_1,op,e2_1);
    
    case (str,r,rarg,DAE.UNARY(operator = op,exp = e1))
      equation
        e1_1 = stringPrefixComponentRef(str, r, rarg, e1);
      then
        DAE.UNARY(op,e1_1);
    
    case (str,r,rarg,DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
        e1_1 = stringPrefixComponentRef(str, r, rarg, e1);
        e2_1 = stringPrefixComponentRef(str, r, rarg, e2);
      then
        DAE.LBINARY(e1_1,op,e2_1);
    
    case (str,r,rarg,DAE.LUNARY(operator = op,exp = e1))
      equation
        e1_1 = stringPrefixComponentRef(str, r, rarg, e1);
      then
        DAE.LUNARY(op,e1_1);
    
    case (str,r,rarg,DAE.RELATION(exp1 = e1,operator = op,exp2 = e2, index=index_, optionExpisASUB= isExpisASUB))
      equation
        e1_1 = stringPrefixComponentRef(str, r, rarg, e1);
        e2_1 = stringPrefixComponentRef(str, r, rarg, e2);
      then
        DAE.RELATION(e1_1,op,e2_1,index_,isExpisASUB);
    
    case (str,r,rarg,DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation
        e1_1 = stringPrefixComponentRef(str, r, rarg, e1);
        e2_1 = stringPrefixComponentRef(str, r, rarg, e2);
        e3_1 = stringPrefixComponentRef(str, r, rarg, e3);
      then
        DAE.IFEXP(e1_1,e2_1,e3_1);
    
    case (str,r,rarg,DAE.CALL(path = p,expLst = el,tuple_ = b,builtin = bi,ty = tp,inlineType = inl))
      equation
        el_1 = stringPrefixComponentRefs(str, r, rarg, el);
      then
        DAE.CALL(p,el_1,b,bi,tp,inl);
    
    case (str,r,rarg,DAE.ARRAY(ty = t,scalar = b,array = el))
      equation
        el_1 = stringPrefixComponentRefs(str, r, rarg, el);
      then
        DAE.ARRAY(t,b,el_1);
    
    case (str,r,rarg,DAE.MATRIX(ty = t,integer = a,scalar = ell))
      equation
        es = Util.listListMap(ell, Util.tuple21);
        bl = Util.listListMap(ell, Util.tuple22);
        es_1 = stringPrefixComponentRefsList(str, r, rarg, es);
        ell_1 = Util.listListThreadTuple(es_1, bl);
      then
        DAE.MATRIX(t,a,ell_1);
    
    case (str,r,rarg,DAE.RANGE(ty = t,exp = e1,expOption = NONE(),range = e2))
      equation
        e1_1 = stringPrefixComponentRef(str, r, rarg, e1);
        e2_1 = stringPrefixComponentRef(str, r, rarg, e2);
      then
        DAE.RANGE(t,e1_1,NONE(),e2_1);
    
    case (str,r,rarg,DAE.RANGE(ty = t,exp = e1,expOption = SOME(e2),range = e3))
      equation
        e1_1 = stringPrefixComponentRef(str, r, rarg, e1);
        e2_1 = stringPrefixComponentRef(str, r, rarg, e2);
        e3_1 = stringPrefixComponentRef(str, r, rarg, e3);
      then
        DAE.RANGE(t,e1_1,SOME(e2_1),e3_1);
    
    case (str,r,rarg,DAE.TUPLE(PR = el))
      equation
        el_1 = stringPrefixComponentRefs(str, r, rarg, el);
      then
        DAE.TUPLE(el_1);
    
    case (str,r,rarg,DAE.CAST(ty = ty,exp = e1))
      equation
        e1_1 = stringPrefixComponentRef(str, r, rarg, e1);
      then
        DAE.CAST(ty,e1_1);
    
    case (str,r,rarg,DAE.ASUB(exp = e1,sub = el))
      equation
        e1_1 = stringPrefixComponentRef(str, r, rarg, e1);
      then
        Expression.makeASUB(e1_1,el);
    case (str,r,rarg,e) then e;
  end matchcontinue;
end stringPrefixComponentRef;

protected function stringPrefixComponentRefsList
  input String inString;
  input FuncTypeExp_ComponentRefType_bTo inFuncTypeExpComponentRefTypeBTo;
  input Type_b inTypeB;
  input list<list<DAE.Exp>> inExpExpLstLst;
  output list<list<DAE.Exp>> outExpExpLstLst;
  partial function FuncTypeExp_ComponentRefType_bTo
    input DAE.ComponentRef inComponentRef;
    input Type_b inTypeB;
    replaceable type Type_b subtypeof Any;
  end FuncTypeExp_ComponentRefType_bTo;
  replaceable type Type_b subtypeof Any;
algorithm
  outExpExpLstLst := matchcontinue (inString,inFuncTypeExpComponentRefTypeBTo,inTypeB,inExpExpLstLst)
    local
      list<DAE.Exp> el_1,el;
      list<list<DAE.Exp>> res,rest;
      String str;
      FuncTypeExp_ComponentRefType_bTo r;
      Type_b rarg;
    case (_,_,_,{}) then {};
    case (str,r,rarg,(el :: rest))
      equation
        el_1 = stringPrefixComponentRefs(str, r, rarg, el);
        res = stringPrefixComponentRefsList(str, r, rarg, rest);
      then
        (el_1 :: res);
  end matchcontinue;
end stringPrefixComponentRefsList;

protected function stringPrefixCref
  input String inString;
  input DAE.ComponentRef inComponentRef;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef := matchcontinue (inString,inComponentRef)
    local
      String s_1,str,s;
      list<DAE.Subscript> si;
      DAE.ComponentRef cr;
      DAE.ExpType ty2;
    case (str,DAE.CREF_IDENT(ident = s,subscriptLst = si, identType = ty2))
      equation
        s_1 = stringAppend(str, s);
      then
        ComponentReference.makeCrefIdent(s_1,ty2,si);
    case (str,DAE.CREF_QUAL(ident = s,subscriptLst = si,componentRef = cr, identType = ty2))
      equation
        s_1 = stringAppend(str, s);
      then
        ComponentReference.makeCrefQual(s_1,ty2, si,cr);
  end matchcontinue;
end stringPrefixCref;

protected function stringPrefixElements
  input String inString1;
  input list<DAE.Element> inDAEElementLst2;
  input list<DAE.Element> inDAEElementLst3;
  output list<DAE.Element> outDAEElementLst;
algorithm
  outDAEElementLst := matchcontinue (inString1,inDAEElementLst2,inDAEElementLst3)
    local
      DAE.Element el_1,el;
      list<DAE.Element> res,dae,rest;
      String str;
    case (_,_,{}) then {};
    case (str,dae,(el :: rest))
      equation
        el_1 = stringPrefixElement(str, dae, el);
        res = stringPrefixElements(str, dae, rest);
      then
        (el_1 :: res);
  end matchcontinue;
end stringPrefixElements;

protected function stringPrefixElement
  input String inString;
  input list<DAE.Element> inDAEElementLst;
  input DAE.Element inElement;
  output DAE.Element outElement;
algorithm
  outElement := matchcontinue (inString,inDAEElementLst,inElement)
    local
      DAE.Exp exp_1,exp,exp1_1,exp2_1,exp1,exp2; String str,n;
      list<DAE.Element> dae,dae_1,dae1; DAE.ComponentRef cr;
      DAE.VarKind vk; DAE.VarDirection vd; DAE.Type ty;
      list<DAE.Subscript> inst_dims; Option<DAE.Exp> start;
      DAE.Flow flowPrefix; DAE.Stream streamPrefix;
      list<Absyn.Path> cl; Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment; Algorithm.Algorithm alg;
      DAE.ExternalDecl decl; DAE.Element e; Absyn.InnerOuter io;
      DAE.Type ftp; DAE.VarProtection prot; list<DAE.FunctionDefinition> funcDer;
      Boolean partialPrefix; DAE.ElementSource source "the origin of the element";
      list<DAE.Element> daeLst;
    // variables with binding
    case (str,dae,DAE.VAR(componentRef = cr,
                          kind = vk,
                          direction = vd,
                          protection=prot,
                          ty = ty,
                          binding = SOME(exp),
                          dims = inst_dims,
                          flowPrefix = flowPrefix,
                          streamPrefix = streamPrefix,
                          source = source,
                          variableAttributesOption = dae_var_attr,
                          absynCommentOption = comment,
                          innerOuter=io))
      equation
        exp_1 = stringPrefixComponentRef(str, isParameterDaelist, dae, exp);
      then
        DAE.VAR(cr,vk,vd,prot,ty,SOME(exp_1),inst_dims,flowPrefix,streamPrefix,source,dae_var_attr,comment,io);

    case (str,dae,DAE.DEFINE(componentRef = cr,exp = exp,source = source))
      equation
        exp_1 = stringPrefixComponentRef(str, isParameterDaelist, dae, exp);
      then
        DAE.DEFINE(cr,exp_1,source);

    case (str,dae,DAE.EQUATION(exp = exp1,scalar = exp2,source = source))
      equation
        exp1_1 = stringPrefixComponentRef(str, isParameterDaelist, dae, exp1);
        exp2_1 = stringPrefixComponentRef(str, isParameterDaelist, dae, exp2);
      then
        DAE.EQUATION(exp1_1,exp2_1,source);

    case (str,dae,DAE.ALGORITHM(algorithm_ = alg,source = source)) then DAE.ALGORITHM(alg,source);

    case (str,dae1,DAE.COMP(ident = n,dAElist = daeLst,source = source,comment = comment))
      /* What happens if a variable is not found among dae, should we check dae1,
    i.e. where the COMP and FUNCTION was found? */
      equation
        daeLst = stringPrefixElements(str, daeLst, daeLst);
      then
        DAE.COMP(n,daeLst,source,comment);

/* TODO: FIXME: adrpo: Are these needed?
    case (str,dae1,
      DAE.FUNCTION(path = n,
      functions = (DAE.FUNCTION_DEF(body = daeLst)::funcDer),
      type_ = ty,partialPrefix = partialPrefix,inlineType=inlineType,source = source))
      local
        Absyn.Path n;
        tuple<DAE.TType, Option<Absyn.Path>> ty;
        DAE.InlineType inlineType;
      equation
        daeLst = stringPrefixElements(str, daeLst, daeLst);
      then
        DAE.FUNCTION(n,DAE.FUNCTION_DEF(daeLst)::funcDer,ty,partialPrefix,inlineType,source);

    case (str,dae1,
      DAE.FUNCTION(path = n,
      partialPrefix = partialPrefix,functions = (DAE.FUNCTION_EXT(daeLst,decl)::funcDer),
      type_ = ty,source = source))
      local
        Absyn.Path n;
        tuple<DAE.TType, Option<Absyn.Path>> ty;
      equation
        daeLst = stringPrefixElements(str, daeLst, daeLst);
      then
         DAE.FUNCTION(n,DAE.FUNCTION_EXT(daeLst,decl)::funcDer,ty,partialPrefix,DAE.NO_INLINE(),source);
*/

    case (str,dae,e) then e;
  end matchcontinue;
end stringPrefixElement;

protected function isParameterDaelist
  input DAE.ComponentRef inComponentRef;
  input list<DAE.Element> inDAEElementLst;
algorithm
  _ := matchcontinue (inComponentRef,inDAEElementLst)
    local
      DAE.ComponentRef cr,crv;
      DAE.VarDirection vd;
      Option<DAE.Exp> e;
      list<DAE.Element> rest;
      DAE.VarKind vk;
      DAE.Element el;
    case (cr,(DAE.VAR(componentRef = crv,
                      kind = DAE.PARAM(),
                      direction = vd,
                      binding = e) :: rest))
      equation
        true = ComponentReference.crefEqual(cr, crv);
      then
        ();
    case (cr,(DAE.VAR(componentRef = crv,
                      kind = vk,
                      direction = vd,
                      binding = e) :: rest))
      equation
        true = ComponentReference.crefEqual(cr, crv);
      then
        fail();
    case (cr,(el :: rest))
      equation
        isParameterDaelist(cr, rest);
      then
        ();
  end matchcontinue;
end isParameterDaelist;

public function isOuter "Returns true if InnerOuter specification is outer or innerouter"
  input Absyn.InnerOuter io;
  output Boolean res;
  algorithm
    res := matchcontinue(io)
      case(Absyn.OUTER()) then true;
      case(Absyn.INNEROUTER()) then true;
      case(_) then false;
    end matchcontinue;
end isOuter;

public function isPureOuter "
Check if the INNER/OUTER attribute is a sole outer, Absyn.OUTER() 
"
  input Absyn.InnerOuter io;
  output Boolean res;
algorithm res := matchcontinue(io)
  case(Absyn.OUTER()) then true;
  case(_) then false;
end matchcontinue;
end isPureOuter;

public function isInner "Returns true if InnerOuter specification is inner or innerouter"
  input Absyn.InnerOuter io;
  output Boolean res;
  algorithm
    res := matchcontinue(io)
      case(Absyn.INNER()) then true;
       case(Absyn.INNEROUTER()) then true;
      case(_) then false;
    end matchcontinue;
end isInner;

public function isUnspecified "Returns true if InnerOuter specification is unspecified,
i.e. neither inner, outer or inner outer"
  input Absyn.InnerOuter io;
  output Boolean res;
  algorithm
    res := matchcontinue(io)
      case(Absyn.UNSPECIFIED()) then true;
      case(_) then false;
    end matchcontinue;
end isUnspecified;

public function innerOuterEqual "Returns true if two InnerOuter's are equal"
  input Absyn.InnerOuter io1;
  input Absyn.InnerOuter io2;
  output Boolean res;
algorithm
  res := matchcontinue(io1,io2)
    case(Absyn.INNER(),Absyn.INNER()) then true;
    case(Absyn.OUTER(),Absyn.OUTER()) then true;
    case(Absyn.INNEROUTER(),Absyn.INNEROUTER()) then true;
    case(Absyn.UNSPECIFIED(),Absyn.UNSPECIFIED()) then true;
    case(_,_) then false;
  end matchcontinue;
end innerOuterEqual;

public function stringPrefixParams
  input DAE.DAElist inDAElist;
  output DAE.DAElist outDAElist;
algorithm
  outDAElist:=
  matchcontinue (inDAElist)
    local list<DAE.Element> daeLst_1,daeLst;
      DAE.FunctionTree funcs;
    case DAE.DAE(daeLst)
      equation
        daeLst_1 = stringPrefixElements("params->", daeLst, daeLst);
      then
        DAE.DAE(daeLst_1);
  end matchcontinue;
end stringPrefixParams;

public function optPathString "function: optPathString

  Prints a Path option to a string.
"
  input Option<Absyn.Path> inAbsynPathOption;
  output String outString;
algorithm
  outString:=
  matchcontinue (inAbsynPathOption)
    local
      String str;
      Absyn.Path p;
    case (NONE()) then "";
    case (SOME(p))
      equation
        str = pathString(p);
      then
        str;
  end matchcontinue;
end optPathString;

public function pathString "function: pathString

  Prints a Path to a string.
"
  input Absyn.Path inPath;
  output String outString;
algorithm
  outString:=
  matchcontinue (inPath)
    local
      String s;
      Absyn.Path path;
    case path
      equation
        true = RTOpts.modelicaOutput();
        s = pathString2(path, "__");
      then
        s;
    case path
      equation
        false = RTOpts.modelicaOutput();
        s = pathString2(path, ".");
      then
        s;
  end matchcontinue;
end pathString;

public function pathString2
"function: pathString2
  Helper function to path_string."
  input Absyn.Path inPath;
  input String inString;
  output String outString;
algorithm
  outString:=
  match (inPath,inString)
    local
      String s,ns,s1,ss,str;
      Absyn.Path n;
    case (Absyn.IDENT(name = s),_) then s;
    case(Absyn.FULLYQUALIFIED(n),str) then pathString2(n,str);
    case (Absyn.QUALIFIED(name = s,path = n),str)
      equation
        ns = pathString2(n, str);
        s1 = stringAppend(s, str);
        ss = stringAppend(s1, ns);
      then
        ss;
  end match;
end pathString2;

public function pathEqual "function: pathEqual
  Returns true if two paths are equal."
  input Absyn.Path inPath1;
  input Absyn.Path inPath2;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inPath1, inPath2)
    local
      String id1,id2;
      Boolean res;
      Absyn.Path path1,path2;
    // fully qual vs. path
    case (Absyn.FULLYQUALIFIED(path1),path2) then pathEqual(path1,path2);
    // path vs. fully qual
    case (path1,Absyn.FULLYQUALIFIED(path2)) then pathEqual(path1,path2);
    // ident vs. ident 
    case (Absyn.IDENT(id1),Absyn.IDENT(id2))
      then stringEq(id1, id2);
    // qual ident vs. qual ident 
    case (Absyn.QUALIFIED(id1, path1),Absyn.QUALIFIED(id2, path2))
      equation
        res = Debug.bcallret2(stringEq(id1, id2), pathEqual, path1, path2, false);
      then res;
    // other return false
    else false;
  end match;
end pathEqual;

public function typeSpecEqual "function: typeSpecEqual
  Returns true if two type specifications are equal."
  input Absyn.TypeSpec inTySpec1;
  input Absyn.TypeSpec inTySpec2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inTySpec1,inTySpec2)
    local
      Absyn.TypeSpec tySpec1, tySpec2;
    case (tySpec1, tySpec2)
      equation
        equality(tySpec1 = tySpec1);
      then
        true;
    case (tySpec1, tySpec2)
      equation
        failure(equality(tySpec1 = tySpec2));
      then
        false;
    case (_,_) then false;
  end matchcontinue;
end typeSpecEqual;

public function pathStringReplaceDot "function: pathStringReplaceDot
  Helper function to pathString."
  input Absyn.Path inPath;
  input String inString;
  output String outString;
algorithm
  outString:=
  match (inPath,inString)
    local
      String s,ns,s1,ss,str,dstr,safe_s;
      Absyn.Path n;
    case (Absyn.IDENT(name = s),str)
      equation
        dstr = stringAppend(str, str);
        safe_s = System.stringReplace(s, str, dstr);
      then
        safe_s;
    case(Absyn.FULLYQUALIFIED(n),str) then pathStringReplaceDot(n,str);
    case (Absyn.QUALIFIED(name = s,path = n),str)
      equation
        ns = pathStringReplaceDot(n, str);
        dstr = stringAppend(str, str);
        safe_s = System.stringReplace(s, str, dstr);
        s1 = stringAppend(safe_s, str);
        ss = stringAppend(s1, ns);
      then
        ss;
  end match;
end pathStringReplaceDot;

end ModUtil;

