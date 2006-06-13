package Lookup "
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

  
  file:	 Lookup.rml
  module:      Lookup
  description: Scoping rules
 
  RCS: $Id$
 

  This module is responsible for the lookup mechanism in Modelica.
  It is responsible for looking up classes, variables, etc. in the
  environment \'Env\' by following the lookup rules.
  The most important functions are:
  lookup_class - to find a class 
  lookup_type - to find types (e.g. functions, types, etc.)
  lookup_var - to find a variable in the instance hierarchy.
"

public import OpenModelica.Compiler.ClassInf;

public import OpenModelica.Compiler.Types;

public import OpenModelica.Compiler.Absyn;

public import OpenModelica.Compiler.Exp;

public import OpenModelica.Compiler.Env;

public import OpenModelica.Compiler.SCode;

protected import OpenModelica.Compiler.Debug;

protected import OpenModelica.Compiler.Inst;

protected import OpenModelica.Compiler.Mod;

protected import OpenModelica.Compiler.Prefix;

protected import OpenModelica.Compiler.Builtin;

protected import OpenModelica.Compiler.ModUtil;

protected import OpenModelica.Compiler.Static;

protected import OpenModelica.Compiler.Connect;

protected import OpenModelica.Compiler.Error;

protected import OpenModelica.Compiler.Values;

public function lookupType "adrpo -- not used
with \"Util.rml\"
with \"Print.rml\"
with \"Parser.rml\"
with \"Dump.rml\"

  
  - Lookup functions
 
  These functions look up class and variable names in the environment.
  The names are supplied as a path, and if the path is qualified, a
  variable named as the first part of the path is searched for, and the
  name is looked for in it.
 
  function: lookupType
  
  This function finds a specified type in the environment. 
  If it finds a function instead, this will be implicitly instantiated 
  and lookup will start over. 
 
  Arg1: Env.Env is the environment which to perform the lookup in
  Arg2: Absyn.Path is the type to look for
"
  input Env.Cache inCache;
  input Env.Env inEnv "environment to search in";
  input Absyn.Path inPath "type to look for";
  input Boolean inBoolean "Messaage flag, true outputs lookup error messages";
  output Env.Cache outCache;
  output Types.Type outType "the found type";
  output Env.Env outEnv "The environment the type was found in";
algorithm 
  (outCache,outType,outEnv):=
  matchcontinue (inCache,inEnv,inPath,inBoolean)
    local
      tuple<Types.TType, Option<Absyn.Path>> t,c_1;
      list<Env.Frame> env_1,env,env_2,env3,env2,env_3;
      Absyn.Path path,p;
      Boolean msg,encflag;
      SCode.Class c;
      String id,pack,classname,scope;
      SCode.Restriction restr;
      ClassInf.State ci_state,cistate1;
      Env.Cache cache;
      
      /*For simple names */
    case (cache,env,(path as Absyn.IDENT(name = _)),msg) /* msg flag Lookup of simple names */ 
      equation 
        (cache,t,env_1) = lookupTypeInEnv(cache,env, path);
      then
        (cache,t,env_1);
      /*If we find a class definition 
	   that is a function with the same name then we implicitly instantiate that
	  function, look up the type. */  
    case (cache,env,(path as Absyn.IDENT(name = _)),msg) local String s;
      equation 
        (cache,(c as SCode.CLASS(id,_,encflag,SCode.R_FUNCTION(),_)),env_1) = lookupClass(cache,env, path, false);
        (cache,env_2) = Inst.implicitFunctionTypeInstantiation(cache,env_1, c);
        (cache,t,env3) = lookupTypeInEnv(cache,env_2, path);
      then
        (cache,t,env3);
      /* Same for external functions */  
    case (cache,env,(path as Absyn.IDENT(name = _)),msg)
      equation 
        (cache,(c as SCode.CLASS(id,_,encflag,SCode.R_EXT_FUNCTION(),_)),env_1) = lookupClass(cache,env, path, msg);
        (cache,env_2) = Inst.implicitFunctionTypeInstantiation(cache,env_1, c);
        (cache,t,env3) = lookupTypeInEnv(cache,env_2, path);
      then
        (cache,t,env3);

	/* Classes that are external objects. Implicityly instantiate to get type */
 case (cache,env,(path as Absyn.IDENT(name = _)),msg) local String s;
      equation 
        (cache,c ,env_1) = lookupClass(cache,env, path, false);
        true = Inst.classIsExternalObject(c);
       (cache,_,env_1,_,_,_) = Inst.instClass(cache,env_1, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c, 
          {}, false, Inst.TOP_CALL());
	   		//s = Env.printEnvStr(env_1);
        //print("instantiated external object2, env:");
        //print(s);
        //print("\n");
        (cache,t,env_2) = lookupTypeInEnv(cache,env_1, path);
      then
        (cache,t,env_2);

         /* Lookup of qualified name when first part of name is not a package.*/ 
    case (cache,env,Absyn.QUALIFIED(name = pack,path = path),msg) 
      equation 
        (cache,(c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClass(cache,env, Absyn.IDENT(pack), false);        
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
         (cache,env_2,cistate1) = Inst.partialInstClassIn(cache,env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {});
   
        failure(ClassInf.valid(cistate1, SCode.R_PACKAGE()));
        (cache,t,env_3) = lookupTypeInClass(cache,env_2, c, path, true) "Has to do additional check for encapsulated classes, see rule below" ;
      then
        (cache,t,env_3);
   
   	/* Same as above but first part of name is a package. */
    case (cache,env,(p as Absyn.QUALIFIED(name = pack,path = path)),msg)
      equation 
        (cache,(c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClass(cache,env, Absyn.IDENT(pack), msg);
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
         (cache,env_2,cistate1) = Inst.partialInstClassIn(cache,env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {});
        ClassInf.valid(cistate1, SCode.R_PACKAGE());
        (cache,c_1,env_3) = lookupTypeInClass(cache,env_2, c, path, false) "Has NOT to do additional check for encapsulated classes, see rule above" ;
      then
        (cache,c_1,env_3);

   	/* Error for class not found */
    case (cache,env,path,true)
      equation 
        classname = Absyn.pathString(path);
        scope = Env.printEnvPathStr(env);
        Error.addMessage(Error.LOOKUP_ERROR, {classname,scope});
      then
        fail();
  end matchcontinue;
end lookupType;

protected function isPrimitive "function: isPrimitive
  author: PA
 
  Returns true if classname is any of the builtin classes:
  Real, Integer, String, Boolean
"
  input Absyn.Path inPath;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "Integer")) then true; 
    case (Absyn.IDENT(name = "Real")) then true; 
    case (Absyn.IDENT(name = "Boolean")) then true; 
    case (Absyn.IDENT(name = "String")) then true; 
    case (_) then false; 
  end matchcontinue;
end isPrimitive;

public function lookupClass "function: lookupClass
  
  Tries to find a specified class in an environment
  
  Arg1: The enviroment where to look
  Arg2: The path for the class
  Arg3: A Bool to control the output of error-messages. If it is true
        then it outputs a error message if the class is not found.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm 
  (inCache,outClass,outEnv):=
  matchcontinue (inCache,inEnv,inPath,inBoolean)
    local
      Env.Frame f;
      Env.Cache cache;
      SCode.Class c,c_1;
      list<Env.Frame> env,env_1,env2,env_2,env_3,env1,env4,env5,fs;
      Absyn.Path path,ep,packp,p,scope;
      String id,s,name,pack;
      Boolean msg,encflag,msgflag;
      SCode.Restriction restr;
      ClassInf.State ci_state,cistate1;
    
    	/* First look in cache for environment. If found look up class in that environment*/
   case (cache,env,path,msg)
      equation
        SOME(scope) = Env.getEnvPath(env);
        f::fs = Env.cacheGet(scope,path,cache);
        id = Absyn.pathLastIdent(path);        
        (cache,c,env) = lookupClassInEnv(cache,fs,Absyn.IDENT(id),msg);
    then
      (cache,c,env);

      /* Builtin classes Integer, Real, String, Boolean can not be overridden
       search top environment directly. */   
    case (cache,env,(path as Absyn.IDENT(name = id)),msg) 
      equation 
        true = isPrimitive(path);
        f = Env.topFrame(env);
        (cache,c,env) = lookupClassInFrame(cache,f, {f}, id, msg);
      then
        (cache,c,env);
    case (cache,env,path,msg)
      equation 
        true = isPrimitive(path);
        print("ERROR, primitive class not found on top env: ");
        s = Env.printEnvStr(env);
        print(s);
      then
        fail();
    case (cache,env,(path as Absyn.IDENT(name = name)),msgflag)
      equation 
        (cache,(c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClassInEnv(cache,env, path, msgflag) "print \"lookup_class \" & print name  & print \"\\nenv:\" & Env.print_env_str env => s & print s & print \"\\n\" &" ;
      then
        (cache,c,env_1);
    case (cache,env,(p as Absyn.QUALIFIED(name = _)),msgflag)
      equation 
        SOME(ep) = Env.getEnvPath(env) "If we search for A1.A2....An.x while in scope A1.A2...An
	 , just search for x. Must do like this to ensure finite recursion" ;
        packp = Absyn.stripLast(p);
        true = ModUtil.pathEqual(ep, packp);
        id = Absyn.pathLastIdent(p);
        (cache,c,env_1) = lookupClass(cache,env, Absyn.IDENT(id), msgflag);
      then
        (cache,c,env_1);
    case (cache,env,(p as Absyn.QUALIFIED(name = pack,path = path)),msgflag) /* Qualified name in non package */ 
      equation 
        (cache,(c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClass(cache,env, Absyn.IDENT(pack), msgflag);
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
        
        (cache,env_2,cistate1) = Inst.partialInstClassIn(cache,env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {});
          /*(_,env_2,_,cistate1,_,_) = Inst.instClassIn(env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet,
           ci_state, c, false/*FIXME:prot*/, {}, false, false);*/
        failure(ClassInf.valid(cistate1, SCode.R_PACKAGE()));
        (cache,c_1,env_3) = lookupClass(cache,env_2, path, msgflag) "Has to do additional check for encapsulated classes, see rule below" ;
      then
        (cache,c_1,env_3);
    case (cache,env,(p as Absyn.QUALIFIED(name = pack,path = path)),msgflag) /* Qualified names in package */ 
      equation 
        (cache,(c as SCode.CLASS(id,_,encflag,restr,_)),env1) = lookupClass(cache,env, Absyn.IDENT(pack), msgflag);
        env2 = Env.openScope(env1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id); 
        
        (_,env4,cistate1) = Inst.partialInstClassIn(cache,env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {});
          /*(_,env4,_,cistate1,_,_) = Inst.instClassIn(env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet,
           ci_state, c, false/*FIXME:prot*/, {}, false, false);*/
        ClassInf.valid(cistate1, SCode.R_PACKAGE());
        (cache,c_1,env5) = lookupClass(cache,env4, path, msgflag) "Has NOT to do additional check for encapsulated classes, see rule above" ;
      then
        (cache,c_1,env5);
    case (cache,env,path,true)
      equation 
        s = Absyn.pathString(path) "print \"-lookup_class failed \" &" ;
        Debug.fprint("failtrace", "- lookup_class failed\n  - looked for ") "print s & print \"\\n\" & 	Env.print_env_str env => s & print s & print \"\\n\" & 	Env.print_env env & 	Print.get_string => str & print \"Env: \" & print str & print \"\\n\" & 	Print.print_buf \"#Error, class \" & Print.print_buf s & 	Print.print_buf \" not found.\\n\" &" ;
        //print("lookup class ");print(s);print("failed\n");
        Debug.fprint("failtrace", s);
        Debug.fprint("failtrace", "\n env:");
        s = Env.printEnvStr(env);
        //print("env:");print(s);
        Debug.fprint("failtrace", s);
        Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end lookupClass;


protected function lookupQualifiedImportedVarInFrame "function: lookupQualifiedImportedVarInFrame
  author: PA
  
  Looking up variables (constants) imported using qualified imports, 
  i.e. import Modelica.Constants.PI;
"
	input Env.Cache inCache;
  input list<Env.Item> inEnvItemLst;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output Types.Attributes outAttributes;
  output Types.Type outType;
  output Types.Binding outBinding;
algorithm 
  (outCache,outAttributes,outType,outBinding):=
  matchcontinue (inCache,inEnvItemLst,inEnv,inIdent)
    local
      Env.Frame fr;
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Types.Binding bind;
      String id,ident,str;
      list<Env.Item> fs;
      list<Env.Frame> env;
      Exp.ComponentRef cref;
      Absyn.Path strippath,path;
      SCode.Class c2;
      Env.Cache cache;
    case (cache,(Env.IMPORT(import_ = Absyn.QUAL_IMPORT(path = Absyn.IDENT(name = id))) :: fs),env,ident) /* For imported simple name, e.g. A, not possible to assert 
	    sub-path package */ 
      equation 
        equality(id = ident);
        fr = Env.topFrame(env);
        (cache,attr,ty,bind) = lookupVar(cache,{fr}, Exp.CREF_IDENT(ident,{}));
      then
        (cache,attr,ty,bind);
    case (cache,(Env.IMPORT(import_ = Absyn.QUAL_IMPORT(path = path)) :: fs),env,ident) /* For imported qualified name, e.g. A.B.C, assert A.B is package */ 
      equation 
        id = Absyn.pathLastIdent(path);
        equality(id = ident);
        fr = Env.topFrame(env);
        cref = Exp.pathToCref(path);
        (cache,attr,ty,bind) = lookupVarInPackages(cache,{fr}, cref);
        strippath = Absyn.stripLast(path);
        (cache,c2,_) = lookupClass(cache,{fr}, strippath, true);
        assertPackage(c2);
      then
        (cache,attr,ty,bind);
    case (cache,(Env.IMPORT(import_ = Absyn.QUAL_IMPORT(path = path)) :: fs),env,ident) /* importing qualified name, If not package, error */ 
      equation 
        id = Absyn.pathLastIdent(path);
        equality(id = ident);
        fr = Env.topFrame(env);
        cref = Exp.pathToCref(path);
        (cache,attr,ty,bind) = lookupVarInPackages(cache,{fr}, cref);
        strippath = Absyn.stripLast(path);
        (cache,c2,_) = lookupClass(cache,{fr}, strippath, true);
        failure(assertPackage(c2));
        str = Absyn.pathString(strippath);
        Error.addMessage(Error.IMPORT_PACKAGES_ONLY, {str});
      then
        fail();
    case (cache,(Env.IMPORT(import_ = Absyn.NAMED_IMPORT(name = id,path = path)) :: fs),env,ident) /* Named imports */ 
      equation 
        equality(id = ident);
        fr = Env.topFrame(env);
        cref = Exp.pathToCref(path);
        (cache,attr,ty,bind) = lookupVarInPackages(cache,{fr}, cref);
        strippath = Absyn.stripLast(path);
        (cache,c2,_) = lookupClass(cache,{fr}, strippath, true);
        assertPackage(c2);
      then
        (cache,attr,ty,bind);
    case (cache,(Env.IMPORT(import_ = Absyn.NAMED_IMPORT(name = id,path = path)) :: fs),env,ident) /* Assert package for Named imports */ 
      equation 
        equality(id = ident);
        fr = Env.topFrame(env);
        cref = Exp.pathToCref(path);
        (cache,attr,ty,bind) = lookupVarInPackages(cache,{fr}, cref);
        strippath = Absyn.stripLast(path);
        (cache,c2,_) = lookupClass(cache,{fr}, strippath, true);
        failure(assertPackage(c2));
        str = Absyn.pathString(strippath);
        Error.addMessage(Error.IMPORT_PACKAGES_ONLY, {str});
      then
        fail();
    case (cache,(_ :: fs),env,ident) /* Check next frame. */ 
      equation 
        (cache,attr,ty,bind) = lookupQualifiedImportedVarInFrame(cache,fs, env, ident);
      then
        (cache,attr,ty,bind);
  end matchcontinue;
end lookupQualifiedImportedVarInFrame;

protected function moreLookupUnqualifiedImportedVarInFrame "function: moreLookupUnqualifiedImportedVarInFrame
  
  Helper function for lookup_unqualified_imported_var_in_frame. Returns 
  true if there are unqualified imports that matches a sought constant.
"
	input Env.Cache inCache;
  input list<Env.Item> inEnvItemLst;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output Boolean outBoolean;
algorithm 
  (outCache,outBoolean) :=
  matchcontinue (inCache,inEnvItemLst,inEnv,inIdent)
    local
      Env.Frame fr,f;
      SCode.Class c;
      String id,ident;
      Boolean encflag,res;
      SCode.Restriction restr;
      list<Env.Frame> env_1,env2,env;
      ClassInf.State ci_state;
      Absyn.Path path;
      list<Env.Item> fs;
      Env.Cache cache;
    case (cache,(Env.IMPORT(import_ = Absyn.UNQUAL_IMPORT(path = path)) :: fs),env,ident)
      equation 
        fr = Env.topFrame(env);
        (cache,(c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClass(cache,{fr}, path, false);
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
        (cache,(f :: _),_) = Inst.partialInstClassIn(cache,env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {});
        (cache,_,_,_) = lookupVarInPackages(cache,{f}, Exp.CREF_IDENT(ident,{}));
      then
        (cache,true);
    case (cache,(_ :: fs),env,ident)
      equation 
        (cache,res) = moreLookupUnqualifiedImportedVarInFrame(cache,fs, env, ident);
      then
        (cache,res);
    case (cache,{},_,_) then (cache,false); 
  end matchcontinue;
end moreLookupUnqualifiedImportedVarInFrame;

protected function lookupUnqualifiedImportedVarInFrame "function: lookupUnqualifiedImportedVarInFrame
  
  Find a variable from an unqualified import locally in a frame
"
	input Env.Cache inCache;
  input list<Env.Item> inEnvItemLst;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output Types.Attributes outAttributes;
  output Types.Type outType;
  output Types.Binding outBinding;
  output Boolean outBoolean;
algorithm 
  (outCache,outAttributes,outType,outBinding,outBoolean):=
  matchcontinue (inCache,inEnvItemLst,inEnv,inIdent)
    local
      Env.Frame fr,f;
      Exp.ComponentRef cref;
      SCode.Class c;
      String id,ident;
      Boolean encflag,more,unique;
      SCode.Restriction restr;
      list<Env.Frame> env_1,env2,env;
      ClassInf.State ci_state;
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Types.Binding bind;
      Absyn.Path path;
      list<Env.Item> fs;
      Env.Cache cache;
    case (cache,(Env.IMPORT(import_ = Absyn.UNQUAL_IMPORT(path = path)) :: fs),env,ident) /* unique */ 
      equation 
        fr = Env.topFrame(env);
        cref = Exp.pathToCref(path);
        (cache,(c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClass(cache,{fr}, path, false);
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
        (cache,_,(f :: _),_,_,_,_) = Inst.instClassIn(cache,env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {}, false);
        (cache,attr,ty,bind) = lookupVarInPackages(cache,{f}, Exp.CREF_IDENT(ident,{}));
        (cache,more) = moreLookupUnqualifiedImportedVarInFrame(cache,fs, env, ident);
        unique = boolNot(more);
      then
        (cache,attr,ty,bind,unique);
    case (cache,(_ :: fs),env,ident)
      equation 
        (cache,attr,ty,bind,unique) = lookupUnqualifiedImportedVarInFrame(cache,fs, env, ident);
      then
        (cache,attr,ty,bind,unique);
  end matchcontinue;
end lookupUnqualifiedImportedVarInFrame;

protected function lookupQualifiedImportedClassInFrame "function: lookupQualifiedImportedClassInFrame
  
  Helper function to lookup_qualified_imported_class_in_env.
"
	input Env.Cache inCache;
  input list<Env.Item> inEnvItemLst;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm 
  (outCache,outClass,outEnv):=
  matchcontinue (inCache,inEnvItemLst,inEnv,inIdent)
    local
      Env.Frame fr;
      SCode.Class c,c2;
      list<Env.Frame> env_1,env;
      String id,ident,str;
      list<Env.Item> fs;
      Absyn.Path strippath,path;
      Env.Cache cache;
    case (cache,(Env.IMPORT(import_ = Absyn.QUAL_IMPORT(path = Absyn.IDENT(name = id))) :: fs),env,ident)
      equation 
        equality(id = ident) "For imported paths A, not possible to assert sub-path package" ;
        fr = Env.topFrame(env);
        (cache,c,env_1) = lookupClass(cache,{fr}, Absyn.IDENT(id), true);
      then
        (cache,c,env_1);
    case (cache,(Env.IMPORT(import_ = Absyn.QUAL_IMPORT(path = path)) :: fs),env,ident)
      equation 
        id = Absyn.pathLastIdent(path) "For imported path A.B.C, assert A.B is package" ;
        equality(id = ident);
        fr = Env.topFrame(env);
        (cache,c,env_1) = lookupClass(cache,{fr}, path, true);
        strippath = Absyn.stripLast(path);
        (cache,c2,_) = lookupClass(cache,{fr}, strippath, true);
        assertPackage(c2);
      then
        (cache,c,env_1);
    case (cache,(Env.IMPORT(import_ = Absyn.QUAL_IMPORT(path = path)) :: fs),env,ident)
      equation 
        id = Absyn.pathLastIdent(path) "If not package, error" ;
        equality(id = ident);
        fr = Env.topFrame(env);
        (cache,c,env_1) = lookupClass(cache,{fr}, path, true);
        strippath = Absyn.stripLast(path);
        (cache,c2,_) = lookupClass(cache,{fr}, strippath, true);
        failure(assertPackage(c2));
        str = Absyn.pathString(strippath);
        Error.addMessage(Error.IMPORT_PACKAGES_ONLY, {str});
      then
        fail();
    case (cache,(Env.IMPORT(import_ = Absyn.NAMED_IMPORT(name = id,path = path)) :: fs),env,ident)
      equation 
        equality(id = ident) "Named imports" ;
        fr = Env.topFrame(env);
        (cache,c,env_1) = lookupClass(cache,{fr}, path, true) "	Print.print_buf \"NAMED IMPORT, top frame:\" & 
	Env.print_env {fr} &" ;
        strippath = Absyn.stripLast(path);
        (cache,c2,_) = lookupClass(cache,{fr}, strippath, true);
        assertPackage(c2);
      then
        (cache,c,env_1);
    case (cache,(Env.IMPORT(import_ = Absyn.NAMED_IMPORT(name = id,path = path)) :: fs),env,ident)
      equation 
        equality(id = ident) "Assert package for Named imports" ;
        fr = Env.topFrame(env);
        (cache,c,env_1) = lookupClass(cache,{fr}, path, true);
        strippath = Absyn.stripLast(path);
        (cache,c2,_) = lookupClass(cache,{fr}, strippath, true);
        failure(assertPackage(c2));
        str = Absyn.pathString(strippath);
        Error.addMessage(Error.IMPORT_PACKAGES_ONLY, {str});
      then
        fail();
    case (cache,(_ :: fs),env,ident)
      equation 
        (cache,c,env_1) = lookupQualifiedImportedClassInFrame(cache,fs, env, ident);
      then
        (cache,c,env_1);
  end matchcontinue;
end lookupQualifiedImportedClassInFrame;

protected function moreLookupUnqualifiedImportedClassInFrame "function: moreLookupUnqualifiedImportedClassInFrame
  
  Helper function for lookup_unqualified_imported_class_in_frame
"
 	input Env.Cache inCache;
  input list<Env.Item> inEnvItemLst;
  input Env.Env inEnv;
  input SCode.Ident inIdent;  
	output Env.Cache outCache;
  output Boolean outBoolean;
algorithm 
  (outCache,outBoolean) :=
  matchcontinue (inCache,inEnvItemLst,inEnv,inIdent)
    local
      Env.Frame fr,f;
      SCode.Class c;
      String id,ident;
      Boolean encflag,res;
      SCode.Restriction restr;
      list<Env.Frame> env_1,env2,env;
      ClassInf.State ci_state;
      Absyn.Path path;
      list<Env.Item> fs;
      Env.Cache cache;
    case (cache,(Env.IMPORT(import_ = Absyn.UNQUAL_IMPORT(path = path)) :: fs),env,ident)
      equation 
        fr = Env.topFrame(env);
        (cache,(c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClass(cache,{fr}, path, false);
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
        (cache,(f :: _),_) = Inst.partialInstClassIn(cache,env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {});
        (cache,_,_) = lookupClass(cache,{f}, Absyn.IDENT(ident), false);
      then
        (cache,true);
    case (cache,(_ :: fs),env,ident)
      equation 
        (cache,res) = moreLookupUnqualifiedImportedClassInFrame(cache,fs, env, ident);
      then
        (cache,res);
    case (cache,{},_,_) then (cache,false); 
  end matchcontinue;
end moreLookupUnqualifiedImportedClassInFrame;

protected function lookupUnqualifiedImportedClassInFrame "function: lookupUnqualifiedImportedClassInFrame
  
  Finds a class from an unqualified import locally in a frame
"
	input Env.Cache inCache;
  input list<Env.Item> inEnvItemLst;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output SCode.Class outClass;
  output Env.Env outEnv;
  output Boolean outBoolean;
algorithm 
  (outCache,outClass,outEnv,outBoolean):=
  matchcontinue (inCache,inEnvItemLst,inEnv,inIdent)
    local
      Env.Frame fr,f,f_1;
      SCode.Class c,c_1;
      String id,ident;
      Boolean encflag,more,unique;
      SCode.Restriction restr;
      list<Env.Frame> env_1,env2,fs_1,env;
      ClassInf.State ci_state,cistate1;
      Absyn.Path path;
      list<Env.Item> fs;
      Env.Cache cache;
    case (cache,(Env.IMPORT(import_ = Absyn.UNQUAL_IMPORT(path = path)) :: fs),env,ident) /* unique */ 
      equation 
        fr = Env.topFrame(env);
        (cache,(c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClass(cache,{fr}, path, false);
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
        (cache,(f :: fs_1),cistate1) = Inst.partialInstClassIn(cache,env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {});
        (cache,c_1,(f_1 :: _)) = lookupClass(cache,{f}, Absyn.IDENT(ident), false) "Restrict import to the imported scope only, not its parents..." ;
        (cache,more) = moreLookupUnqualifiedImportedClassInFrame(cache,fs, env, ident);
        unique = boolNot(more);
      then
        (cache,c_1,(f_1 :: fs_1),unique);
    case (cache,(_ :: fs),env,ident)
      equation 
        (cache,c,env_1,unique) = lookupUnqualifiedImportedClassInFrame(cache,fs, env, ident);
      then
        (cache,c,env_1,unique);
  end matchcontinue;
end lookupUnqualifiedImportedClassInFrame;

public function lookupRecordConstructorClass "function: lookupRecordConstructorClass
  
  Searches for a record constructor implicitly 
  defined by a record class.
"
  input Env.Env inEnv;
  input Absyn.Path inPath;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm 
  (outClass,outEnv):=
  matchcontinue (inEnv,inPath)
    local
      SCode.Class c;
      list<Env.Frame> env_1,env;
      Absyn.Path path;
    case (env,path)
      equation 
        (c,env_1) = lookupRecconstInEnv(env, path);
      then
        (c,env_1);
  end matchcontinue;
end lookupRecordConstructorClass;



public function lookupVar "LS: when looking up qualified component reference, lookupVar only
checks variables when looking for the prefix, i.e. for Constants.PI
where Constants is a package and is implicitly instantiated, PI is not
found since Constants is not a variable (it is a type and/or class).

1) One option is to make it a variable and put it in the global frame.
2) Another option is to add a lookup rule that also looks in types.

Now implicitly instantiated packages exists both as a class and as a
type (see implicit_instantiation in Inst.rml). Is this correct?

lookup_var is modified to implement 2. Is this correct?

old lookup_var is changed to lookup_var_internal and a new lookup_var
is written, that first tests the old lookup_var, and if not found
looks in the types

  function: lookupVar
 
  This function tries to finds a variable in the environment
  
  Arg1: The environment to search in
  Arg2: The variable to search for
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.ComponentRef inComponentRef;
  output Env.Cache outCache;
  output Types.Attributes outAttributes;
  output Types.Type outType;
  output Types.Binding outBinding;
algorithm 
  (outCache,outAttributes,outType,outBinding):=
  matchcontinue (inCache,inEnv,inComponentRef)
    local
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Types.Binding binding;
      list<Env.Frame> env;
      Exp.ComponentRef cref;
      Env.Cache cache;
    case (cache,env,cref) /* try the old lookup_var */ 
      equation 
        (cache,attr,ty,binding) = lookupVarInternal(cache,env, cref);
      then
        (cache,attr,ty,binding);
    case (cache,env,cref) /* then look in classes (implicitly instantiated packages) */ 
      equation 
        //print("calling lookupVarInPackages env:");print(Env.printEnvStr(env)); print("END ENV\n");
        (cache,attr,ty,binding) = lookupVarInPackages(cache,env, cref);
      then
        (cache,attr,ty,binding);
    case (_,env,cref) equation
      /* Debug.fprint(\"failtrace\",  \"- lookup_var failed\\n\") */  then fail(); 
  end matchcontinue;
end lookupVar;

protected function lookupVarInternal "function: lookupVarInternal
 
  Helper function to lookup_var. Searches the frames for variables.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.ComponentRef inComponentRef;
	output Env.Cache outCache;
  output Types.Attributes outAttributes;
  output Types.Type outType;
  output Types.Binding outBinding;
algorithm 
  (outCache,outAttributes,outType,outBinding):=
  matchcontinue (inCache,inEnv,inComponentRef)
    local
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Types.Binding binding;
      Option<String> sid;
      Env.BinTree ht;
      list<Env.Item> imps;
      list<Env.Frame> fs;
      Env.Frame frame;
      Exp.ComponentRef ref;
      Env.Cache cache;
    case (cache,((frame as Env.FRAME(class_1 = sid,list_2 = ht,list_4 = imps)) :: fs),ref)
      equation 
        //print("lookup var in frame:");print(Env.printEnvStr({frame}));print("end lookupVar frame\n");
        (cache,attr,ty,binding) = lookupVarF(cache,ht, ref);
      then
        (cache,attr,ty,binding);
    case (cache,(_ :: fs),ref)
      equation 
        (cache,attr,ty,binding) = lookupVarInternal(cache,fs, ref);
      then
        (cache,attr,ty,binding);
  end matchcontinue;
end lookupVarInternal;

protected function lookupVarInPackages "function: lookupVarInPackages
 
  This function is called when a lookup of a variable with qualified names
  does not have the first element as a component, e.g. A.B.C is looked up 
  where A is not a component. This implies that A is a class, and this 
  class should be temporary instantiated, and the lookup should 
  be performed within that class. I.e. the function performs lookup of 
  variables in the class hierarchy.
 
  Arg1: The environment to search in
  Arg2: The variable to search for
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.ComponentRef inComponentRef;
  output Env.Cache outCache;
  output Types.Attributes outAttributes;
  output Types.Type outType;
  output Types.Binding outBinding;
algorithm 
  (outCache,outAttributes,outType,outBinding):=
  matchcontinue (inCache,inEnv,inComponentRef)
    local
      SCode.Class c;
      String n,id1,id;
      Boolean encflag;
      SCode.Restriction r;
      list<Env.Frame> env2,env3,env5,env,fs,bcframes;
      ClassInf.State ci_state;
      list<Types.Var> types;
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Types.Binding bind;
      Exp.ComponentRef id2,cref,cr;
      list<Exp.Subscript> sb;
      Option<String> sid;
      list<Env.Item> items;
      Env.Frame f;
      Env.Cache cache;
      // Lookup of enumeration variables
    case (cache,env,Exp.CREF_QUAL(ident = id1,subscriptLst = {},componentRef = (id2 as Exp.CREF_IDENT(ident = _))))
      equation 
        (cache,(c as SCode.CLASS(n,_,encflag,(r as SCode.R_ENUMERATION()),_)),env2) 
        	= lookupClass(cache,env, Absyn.IDENT(id1), false) "Special case for looking up enumerations" ;
        env3 = Env.openScope(env2, encflag, SOME(n));
        ci_state = ClassInf.start(r, n);
        (cache,_,env5,_,_,types,_) = Inst.instClassIn(cache,env3, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {}, false);
        (cache,attr,ty,bind) = lookupVarInPackages(cache,env5, id2);
      then
        (cache,attr,ty,bind);

      // lookup of constants on form A.B in packages. First look in cache.
    case (cache,env,cr as Exp.CREF_QUAL(ident = id,subscriptLst = {},componentRef = cref)) /* First part of name is a class. */ 
      local 
        Exp.ComponentRef cr;
        Absyn.Path path,scope;
      equation 
        SOME(scope) = Env.getEnvPath(env);
        path = Exp.crefToPath(cr);
        id = Absyn.pathLastIdent(path);
        path = Absyn.stripLast(path);
        f::fs = Env.cacheGet(scope,path,cache);
        (cache,attr,ty,bind) = lookupVarLocal(cache,f::fs, Exp.CREF_IDENT(id,{}));
      then
        (cache,attr,ty,bind);

      // lookup of constants on form A.B in packages. instantiate package and look inside.
    case (cache,env,Exp.CREF_QUAL(ident = id,subscriptLst = {},componentRef = cref)) /* First part of name is a class. */ 
      equation 
        (cache,(c as SCode.CLASS(n,_,encflag,r,_)),env2) = lookupClass(cache,env, Absyn.IDENT(id), false);
        env3 = Env.openScope(env2, encflag, SOME(n));
        ci_state = ClassInf.start(r, n);
        (cache,_,env5,_,_,types,_) = Inst.instClassIn(cache,env3, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {}, true);
        (cache,attr,ty,bind) = lookupVarInPackages(cache,env5, cref);
      then
        (cache,attr,ty,bind);
    case (cache,env,(cr as Exp.CREF_IDENT(ident = id,subscriptLst = sb))) local String str;
      equation 
        (cache,attr,ty,bind) = lookupVarLocal(cache,env, cr);
      then
        (cache,attr,ty,bind);
        
        /* Search base classes */
    case (cache,Env.FRAME(list_5 = (bcframes as (_ :: _)))::fs,cref) 
      equation 
        (cache,attr,ty,bind) = lookupVar(cache,bcframes, cref);
      then
        (cache,attr,ty,bind);

    case (cache,(env as (Env.FRAME(class_1 = sid,list_4 = items) :: _)),(cr as Exp.CREF_IDENT(ident = id,subscriptLst = sb)))
      equation 
        (cache,attr,ty,bind) = lookupQualifiedImportedVarInFrame(cache,items, env, id);
      then
        (cache,attr,ty,bind);
    case (cache,(env as (Env.FRAME(class_1 = sid,list_4 = items) :: _)),(cr as Exp.CREF_IDENT(ident = id,subscriptLst = sb)))
      equation 
        (cache,attr,ty,bind,true) = lookupUnqualifiedImportedVarInFrame(cache,items, env, id);
      then
        (cache,attr,ty,bind);
    case (cache,(env as (Env.FRAME(class_1 = sid,list_4 = items) :: _)),(cr as Exp.CREF_IDENT(ident = id,subscriptLst = sb)))
      equation 
        (cache,attr,ty,bind,false) = lookupUnqualifiedImportedVarInFrame(cache,items, env, id);
        Error.addMessage(Error.IMPORT_SEVERAL_NAMES, {id});
      then
        fail();
    case (cache,(f :: fs),cr) /* Search parent scopes */ 
      equation 
         (cache,attr,ty,bind) = lookupVarInPackages(cache,fs, cr);
      then
        (cache,attr,ty,bind);
    case (cache,env,cr) /* Debug.fprint(\"failtrace\",  \"lookup_var_in_packages failed\\n exp:\" ) &
	Debug.fcall(\"failtrace\", Exp.print_component_ref, cr) &
	Debug.fprint(\"failtrace\", \"\\n\") */  then fail(); 
  end matchcontinue;
end lookupVarInPackages;

public function lookupVarLocal "function: lookupVarLocal
  
  This function is very similar to `lookup_var\', but it only looks
  in the topmost environment frame, which means that it only finds
  names defined in the local scope.
 
  ----EXCEPTION---: When the topmost scope is the scope of a for loop, the lookup
  continues on the next scope. This to allow variables in the local scope to 
  also be found even if inside a for scope.
 
  Arg1: The environment to search in
  Arg2: The variable to search for
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.ComponentRef inComponentRef;
  output Env.Cache outCache;
  output Types.Attributes outAttributes;
  output Types.Type outType;
  output Types.Binding outBinding;
algorithm 
  (outCache,outAttributes,outType,outBinding):=
  matchcontinue (inCache,inEnv,inComponentRef)
    local
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Types.Binding binding;
      Option<String> sid;
      Env.BinTree ht;
      list<Env.Frame> fs,env,bcframes;
      Exp.ComponentRef cref;
      Env.Cache cache;
      /* Lookup in frame */
    case (cache,(Env.FRAME(class_1 = sid,list_2 = ht) :: fs),cref)
      equation 
        (cache,attr,ty,binding) = lookupVarF(cache,ht, cref);
      then
        (cache,attr,ty,binding);
        
    case (cache,(Env.FRAME(class_1 = SOME("$for loop scope$")) :: env),cref)
      equation 
        (cache,attr,ty,binding) = lookupVarLocal(cache,env, cref) "Exception, when in for loop scope allow search of next scope" ;
      then
        (cache,attr,ty,binding);
  end matchcontinue;
end lookupVarLocal;

public function lookupIdentLocal "function: lookupIdentLocal
 
  Searches for a variable in the local scope.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output Types.Var outVar;
  output Option<tuple<SCode.Element, Types.Mod>> outTplSCodeElementTypesModOption;
  output Boolean outBoolean;
  output Env.Env outEnv;
algorithm 
  (outCache,outVar,outTplSCodeElementTypesModOption,outBoolean,outEnv):=
  matchcontinue (inCache,inEnv,inIdent)
    local
      Types.Var fv;
      Option<tuple<SCode.Element, Types.Mod>> c;
      Boolean i;
      list<Env.Frame> env;
      Option<String> sid;
      Env.BinTree ht;
      String id;
      Env.Cache cache;
    case (cache,(Env.FRAME(class_1 = sid,list_2 = ht) :: _),id) /* component environment */ 
      equation 
        (cache,fv,c,i,env) = lookupVar2(cache,ht, id);
      then
        (cache,fv,c,i,env);
  end matchcontinue;
end lookupIdentLocal;

public function lookupIdent "function: lookupIdent
 
  Same as lookup_ident_local, except check all frames 
 
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output Types.Var outVar;
  output Option<tuple<SCode.Element, Types.Mod>> outTplSCodeElementTypesModOption;
  output Boolean outBoolean;
algorithm 
  (outCache,outVar,outTplSCodeElementTypesModOption,outBoolean):=
  matchcontinue (outCache,inEnv,inIdent)
    local
      Types.Var fv;
      Option<tuple<SCode.Element, Types.Mod>> c;
      Boolean i;
      Option<String> sid;
      Env.BinTree ht;
      String id;
      list<Env.Frame> rest;
      Env.Cache cache;
    case (cache,(Env.FRAME(class_1 = sid,list_2 = ht) :: _),id)
      equation 
        (cache,fv,c,i,_) = lookupVar2(cache,ht, id);
      then
        (cache,fv,c,i);
    case (cache,(_ :: rest),id)
      equation 
        (cache,fv,c,i) = lookupIdent(cache,rest, id);
      then
        (cache,fv,c,i);
  end matchcontinue;
end lookupIdent;

public function lookupFunctionsInEnv "Function lookup
  function: lookupFunctionsInEnv
 
  Returns a list of types that the function has. 
 
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  output Env.Cache outCache;
  output list<Types.Type> outTypesTypeLst;
algorithm 
  (outCache,outTypesTypeLst) :=
  matchcontinue (inCache,inEnv,inPath)
    local
      Absyn.Path id,iid,path;
      Option<String> sid;
      Env.BinTree ht,httypes;
      list<tuple<Types.TType, Option<Absyn.Path>>> reslist,c1,c2,res;
      list<Env.Frame> env,fs,env_1,env2,env_2;
      String pack;
      SCode.Class c;
      Boolean encflag;
      SCode.Restriction restr;
      ClassInf.State ci_state,cistate1;
      Env.Frame f;
      Env.Cache cache;
    case (cache,{},id) then (cache,{}); 
    case (cache,env,(iid as Absyn.IDENT(name = id)))
      local String id;
      equation 
        _ = Static.elabBuiltinHandler(id) "Check for builtin operators" ;
        Env.FRAME(sid,ht,httypes,_,_,_,_) = Env.topFrame(env);
        (cache,reslist) = lookupFunctionsInFrame(cache,ht, httypes, env, id);
      then
        (cache,reslist);
        
        /*Check for special builtin operators that can not be represented
	  in environment like for instance cardinality.*/
    case (cache,env,(iid as Absyn.IDENT(name = id)))
      local String id;
      equation 
        _ = Static.elabBuiltinHandlerGeneric(id)  ;
        reslist = createGenericBuiltinFunctions(env, id);
      then
        (cache,reslist);
    case (cache,(env as (Env.FRAME(class_1 = sid,list_2 = ht,list_3 = httypes) :: fs)),(iid as Absyn.IDENT(name = id)))
      local String id,s;
      equation 
        (cache,c1)= lookupFunctionsInFrame(cache,ht, httypes, env, id);
        (cache,c2)= lookupFunctionsInEnv(cache,fs, iid);
        reslist = listAppend(c1, c2);
      then
        (cache,reslist);
    case (cache,(env as (Env.FRAME(class_1 = sid,list_2 = ht,list_3 = httypes) :: fs)),(iid as Absyn.QUALIFIED(name = pack,path = path)))
      local String id,s;
      equation 
        (cache,(c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClass(cache,env, Absyn.IDENT(pack), false) "For qualified function names, e.g. Modelica.Math.sin" ;
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
       (cache,env_2,cistate1) = Inst.partialInstClassIn(cache,env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {});
        (cache,reslist) = lookupFunctionsInEnv(cache,env_2, path);
      then 
        (cache,reslist);
   
    case (cache,(f :: fs),id) /* Did not match. Continue */ 
      local list<tuple<Types.TType, Option<Absyn.Path>>> c;
      equation 
        (cache,c) = lookupFunctionsInEnv(cache,fs, id);
      then
        (cache,c);
    case (_,_,_)
      equation 
        Debug.fprintln("failtrace", "lookup_functions_in_env failed");
      then
        fail();
  end matchcontinue;
end lookupFunctionsInEnv;

protected function createGenericBuiltinFunctions "function: createGenericBuiltinFunctions
  author: PA
 
  This function creates function types on-the-fly for special builtin 
  operators/functions which can not be represented in the builtin 
  environment.
"
  input Env.Env inEnv;
  input String inString;
  output list<Types.Type> outTypesTypeLst;
algorithm 
  outTypesTypeLst:=
  matchcontinue (inEnv,inString)
    local list<Env.Frame> env;
    case (env,"cardinality") then {
          (
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_COMPLEX(ClassInf.CONNECTOR("$$"),{},NONE),NONE))},(Types.T_INTEGER({}),NONE)),NONE)};  /* function_name cardinality */ 
  end matchcontinue;
end createGenericBuiltinFunctions; 

protected function lookupTypeInEnv "- Internal functions
  Type lookup
  function: lookupTypeInEnv
  
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  output Env.Cache outCache;
  output Types.Type outType;
  output Env.Env outEnv;
algorithm 
  (outCache,outType,outEnv):=
  matchcontinue (inCache,inEnv,inPath)
    local
      tuple<Types.TType, Option<Absyn.Path>> c;
      list<Env.Frame> env_1,env,fs;
      Option<String> sid;
      Env.BinTree ht,httypes;
      String id;
      Env.Frame f;
      Env.Cache cache;
    case (cache,(env as (Env.FRAME(class_1 = sid,list_2 = ht,list_3 = httypes) :: fs)),Absyn.IDENT(name = id))
      equation 
        (cache,c,env_1) = lookupTypeInFrame(cache,ht, httypes, env, id);
      then
        (cache,c,env_1);
    case (cache,(f :: fs),id)
      local Absyn.Path id;
      equation 
        (cache,c,env_1) = lookupTypeInEnv(cache,fs, id);
      then
        (cache,c,(f :: env_1));
  end matchcontinue;
end lookupTypeInEnv;

protected function lookupTypeInFrame "function: lookupTypeInFrame
  
  Searches a frame for a type.
"
  input Env.Cache inCache;
  input Env.BinTree inBinTree1;
  input Env.BinTree inBinTree2;
  input Env.Env inEnv3;
  input SCode.Ident inIdent4;
  output Env.Cache outCache;
  output Types.Type outType;
  output Env.Env outEnv;
algorithm 
  (outCache,outType,outEnv):=
  matchcontinue (inCache,inBinTree1,inBinTree2,inEnv3,inIdent4)
    local
      tuple<Types.TType, Option<Absyn.Path>> t,ftype,ty;
      Env.BinTree ht,httypes;
      list<Env.Frame> env,cenv,env_1,env_2;
      String id,n;
      SCode.Class cdef;
      Absyn.Path fpath;
      list<Types.Var> varlst;
      Env.Cache cache;
    case (cache,ht,httypes,env,id) /* Classes and vars types */ 
      equation 
        Env.TYPE((t :: _)) = Env.treeGet(httypes, id, Env.myhash);
      then
        (cache,t,env);
    case (cache,ht,httypes,env,id)
      equation 
        Env.VAR(_,_,_,_) = Env.treeGet(ht, id, Env.myhash);
        Error.addMessage(Error.LOOKUP_TYPE_FOUND_COMP, {id});
      then
        fail();
        /* Record constructor function*/
    case (cache,ht,httypes,env,id)
      equation 
        Env.CLASS((cdef as SCode.CLASS(n,_,_,SCode.R_RECORD(),_)),_) = Env.treeGet(ht, id, Env.myhash) "Each time a record constructor function is looked up, this rule will create the function. An improvement (perhaps needing lot of code) is to add the function to the environment, which is returned from this function." ;
        (_,fpath) = Inst.makeFullyQualified(cache,env, Absyn.IDENT(n));
        (cache,varlst) = buildRecordConstructorVarlst(cache,cdef, env);
        ftype = Types.makeFunctionType(fpath, varlst);
      then
        (cache,ftype,env);
        /* Found function, instantiate to get type */
    case (cache,ht,httypes,env,id)
      equation 
        Env.CLASS((cdef as SCode.CLASS(_,_,_,SCode.R_FUNCTION(),_)),cenv) = Env.treeGet(ht, id, Env.myhash);
        (cache,env_1,_) = Inst.implicitFunctionInstantiation(cache,cenv, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          cdef, {});
        (cache,ty,env_2) = lookupTypeInEnv(cache,env_1, Absyn.IDENT(id));
      then
        (cache,ty,env_2);
        
        /* Found external function, instantiate to get type */
    case (cache,ht,httypes,env,id)
      equation 
        Env.CLASS((cdef as SCode.CLASS(_,_,_,SCode.R_EXT_FUNCTION(),_)),cenv) = Env.treeGet(ht, id, Env.myhash) "If we found class that is external function" ;
        (cache,env_1) = Inst.implicitFunctionTypeInstantiation(cache,cenv, cdef);
        (cache,ty,env_2) = lookupTypeInEnv(cache,env_1, Absyn.IDENT(id));
      then
        (cache,ty,env_2);
  end matchcontinue;
end lookupTypeInFrame;

protected function lookupFunctionsInFrame "function: lookupFunctionsInFrame
  
  This actually only looks up the function name and find all
  corresponding types that have this function name.
  
"
  input Env.Cache inCache;
  input Env.BinTree inBinTree1;
  input Env.BinTree inBinTree2;
  input Env.Env inEnv3;
  input SCode.Ident inIdent4;
  output Env.Cache outCache;
  output list<Types.Type> outTypesTypeLst;
algorithm 
  (outCache,outTypesTypeLst):=
  matchcontinue (inCache,inBinTree1,inBinTree2,inEnv3,inIdent4)
    local
      list<tuple<Types.TType, Option<Absyn.Path>>> tps;
      Env.BinTree ht,httypes;
      list<Env.Frame> env,cenv,env_1;
      String id,n;
      SCode.Class cdef;
      list<Types.Var> varlst;
      Absyn.Path fpath;
      tuple<Types.TType, Option<Absyn.Path>> ftype,t;
      Env.Cache cache;
    case (cache,ht,httypes,env,id) /* Classes and vars Types */ 
      equation 
        Env.TYPE(tps) = Env.treeGet(httypes, id, Env.myhash);
      then
        (cache,tps);
    case (cache,ht,httypes,env,id)
      equation 
        Env.VAR(_,_,_,_) = Env.treeGet(ht, id, Env.myhash);
        Error.addMessage(Error.LOOKUP_TYPE_FOUND_COMP, {id});
      then
        fail();
        
        /* Records, create record constructor function*/
    case (cache,ht,httypes,env,id) 
      equation 
        Env.CLASS((cdef as SCode.CLASS(n,_,_,SCode.R_RECORD(),_)),cenv) = Env.treeGet(ht, id, Env.myhash);
        (cache,varlst) = buildRecordConstructorVarlst(cache,cdef, env);
        (_,fpath) = Inst.makeFullyQualified(cache,cenv, Absyn.IDENT(n));
        ftype = Types.makeFunctionType(fpath, varlst);
      then
        (cache,{ftype});
        
        /* Found class that is function, instantiate to get type*/
    case (cache,ht,httypes,env,id) local String s;
      equation 
        Env.CLASS((cdef as SCode.CLASS(_,_,_,SCode.R_FUNCTION(),_)),cenv) = Env.treeGet(ht, id, Env.myhash) "If found class that is function." ;
        (cache,env_1) = Inst.implicitFunctionTypeInstantiation(cache,cenv, cdef);
        (cache,tps) = lookupFunctionsInEnv(cache,env_1, Absyn.IDENT(id)); 
      then
        (cache,tps);
        
        /* Found class that is external function, instantiate to get type */
    case (cache,ht,httypes,env,id)
      equation 
        Env.CLASS((cdef as SCode.CLASS(_,_,_,SCode.R_EXT_FUNCTION(),_)),cenv) = Env.treeGet(ht, id, Env.myhash) "If found class that is external function." ;
        (cache,env_1) = Inst.implicitFunctionTypeInstantiation(cache,cenv, cdef);
        (cache,tps) = lookupFunctionsInEnv(cache,env_1, Absyn.IDENT(id));
      then
        (cache,tps);
        
     /* Found class that is is external object*/
     case (cache,ht,httypes,env,id)  
        local String s;
        equation
          Env.CLASS(cdef,cenv) = Env.treeGet(ht, id, Env.myhash);
	        true = Inst.classIsExternalObject(cdef);
	        (cache,_,env_1,_,t,_) = Inst.instClass(cache,cenv, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, cdef, 
         	 {}, false, Inst.TOP_CALL());
          (cache,t,_) = lookupTypeInEnv(cache,env_1, Absyn.IDENT(id));
           //s = Types.unparseType(t);
         	 //print("type :");print(s);print("\n");
       then
        (cache,{t});  
  end matchcontinue;
end lookupFunctionsInFrame;

protected function lookupRecconstInEnv "function: lookupRecconstInEnv
  
  Helper function to lookup_record_constructor_class. Searches
  The environment for record constructors.
  
"
  input Env.Env inEnv;
  input Absyn.Path inPath;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm 
  (outClass,outEnv):=
  matchcontinue (inEnv,inPath)
    local
      SCode.Class c;
      list<Env.Frame> env,fs;
      Option<String> sid;
      Env.BinTree ht;
      list<Env.Item> imps;
      String id;
      Env.Frame f;
    case ((env as (Env.FRAME(class_1 = sid,list_2 = ht,list_4 = imps) :: fs)),Absyn.IDENT(name = id))
      equation 
        (c,_) = lookupRecconstInFrame(ht, env, id);
      then
        (c,env);
    case ((f :: fs),id)
      local Absyn.Path id;
      equation 
        (c,_) = lookupRecconstInEnv(fs, id);
      then
        (c,(f :: fs));
  end matchcontinue;
end lookupRecconstInEnv;

protected function lookupRecconstInFrame "function: lookupRecconstInFrame
 
  This function lookups the implicit record constructor class (function) 
  of a record in a frame
"
  input Env.BinTree inBinTree;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm 
  (outClass,outEnv):=
  matchcontinue (inBinTree,inEnv,inIdent)
    local
      Env.BinTree ht;
      list<Env.Frame> env;
      String id;
      SCode.Class cdef;
    case (ht,env,id)
      equation 
        Env.VAR(_,_,_,_) = Env.treeGet(ht, id, Env.myhash);
        Error.addMessage(Error.LOOKUP_TYPE_FOUND_COMP, {id});
      then
        fail();
    case (ht,env,id)
      equation 
        Env.CLASS((cdef as SCode.CLASS(_,_,_,SCode.R_RECORD(),_)),_) = Env.treeGet(ht, id, Env.myhash);
        cdef = buildRecordConstructorClass(cdef, env);
      then
        (cdef,env);
  end matchcontinue;
end lookupRecconstInFrame;

protected function buildRecordConstructorClass "function: buildRecordConstructorClass
  
  Creates the record constructor class, i.e. a function, from the record
  class given as argument.
"
  input SCode.Class inClass;
  input Env.Env inEnv;
  output SCode.Class outClass;
algorithm 
  outClass:=
  matchcontinue (inClass,inEnv)
    local
      list<SCode.Element> funcelts,elts;
      SCode.Element reselt;
      SCode.Class cl;
      String id;
      SCode.Restriction restr;
      list<Env.Frame> env;
    case ((cl as SCode.CLASS(name = id,restricion = restr,parts = SCode.PARTS(elementLst = elts))),env) /* record class function class */ 
      equation 
        funcelts = buildRecordConstructorElts(elts, env);
        reselt = buildRecordConstructorResultElt(elts, id, env);
      then
        SCode.CLASS(id,false,false,SCode.R_FUNCTION(),
          SCode.PARTS((reselt :: funcelts),{},{},{},{},NONE));
  end matchcontinue;
end buildRecordConstructorClass;

protected function buildRecordConstructorElts "function: buildRecordConstructorElts
  
  Helper function to build_record_constructor_class. Creates the elements
  of the function class.
"
  input list<SCode.Element> inSCodeElementLst;
  input Env.Env inEnv;
  output list<SCode.Element> outSCodeElementLst;
algorithm 
  outSCodeElementLst:=
  matchcontinue (inSCodeElementLst,inEnv)
    local
      list<SCode.Element> res,rest;
      SCode.Element comp;
      String id;
      Boolean fl,repl,prot,f;
      list<Absyn.Subscript> d;
      SCode.Accessibility ac;
      SCode.Variability var;
      Absyn.Direction dir;
      Absyn.Path tp;
      SCode.Mod mod;
      Option<Absyn.Path> bc;
      Option<Absyn.Comment> comment;
      list<Env.Frame> env;
    case (((comp as SCode.COMPONENT(component = id,final_ = fl,replaceable_ = repl,protected_ = prot,attributes = SCode.ATTR(arrayDim = d,flow_ = f,RW = ac,parameter_ = var,input_ = dir),type_ = tp,mod = mod,baseclass = bc,this = comment)) :: rest),env)
      equation 
        res = buildRecordConstructorElts(rest, env);
      then
        (SCode.COMPONENT(id,fl,repl,prot,SCode.ATTR(d,f,ac,var,Absyn.INPUT()),tp,
          mod,bc,comment) :: res);
    case ({},_) then {}; 
  end matchcontinue;
end buildRecordConstructorElts;

protected function buildRecordConstructorResultElt "function: buildRecordConstructorResultElt
  
  This function builds the result element of a record constructor function, 
  i.e. the returned variable
  
"
  input list<SCode.Element> elts;
  input SCode.Ident id;
  input Env.Env env;
  output SCode.Element outElement;
  list<SCode.SubMod> submodlst;
algorithm 
  submodlst := buildRecordConstructorResultMod(elts);
  outElement := SCode.COMPONENT("result",false,false,false,
          SCode.ATTR({},false,SCode.RW(),SCode.VAR(),Absyn.OUTPUT()),Absyn.IDENT(id),SCode.MOD(false,Absyn.NON_EACH(),submodlst,NONE),
          NONE,NONE);
end buildRecordConstructorResultElt;

protected function buildRecordConstructorResultMod "function: buildRecordConstructorResultMod
 
  This function builds up the modification list for the output element of a record constructor.
  Example: 
    record foo
       Real x;
       String y;
       end foo;
   => modifier list become \'result.x=x, result.y=y\'
"
  input list<SCode.Element> inSCodeElementLst;
  output list<SCode.SubMod> outSCodeSubModLst;
algorithm 
  outSCodeSubModLst:=
  matchcontinue (inSCodeElementLst)
    local
      list<SCode.SubMod> restmod;
      String id;
      list<SCode.Element> rest;
    case ((SCode.COMPONENT(component = id) :: rest))
      equation 
        restmod = buildRecordConstructorResultMod(rest);
      then
        (SCode.NAMEMOD("result",
          SCode.MOD(false,Absyn.NON_EACH(),
          {
          SCode.NAMEMOD(id,
          SCode.MOD(false,Absyn.NON_EACH(),{},
          SOME(Absyn.CREF(Absyn.CREF_IDENT(id,{})))))},NONE)) :: restmod);
    case ({}) then {}; 
  end matchcontinue;
end buildRecordConstructorResultMod;

protected function buildRecordConstructorVarlst "function: buildRecordConstructorVarlst
 
  This function takes a class  (`SCode.Class\') which holds a definition 
  of a record and builds a list of variables of the record used for 
  constructing a record constructor function.
"
	input Env.Cache inCache;
  input SCode.Class inClass;
  input Env.Env inEnv;
  output Env.Cache outCache;
  output list<Types.Var> outTypesVarLst;
algorithm 
  (outCache,outTypesVarLst) :=
  matchcontinue (inCache,inClass,inEnv)
    local
      list<Types.Var> inputvarlst;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      SCode.Class cl;
      list<SCode.Element> elts;
      list<Env.Frame> env;
      Env.Cache cache;
    case (cache,(cl as SCode.CLASS(parts = SCode.PARTS(elementLst = elts))),env)
      equation 
        (cache,inputvarlst) = buildVarlstFromElts(cache,elts, env);
        (cache,_,_,_,ty,_) = Inst.instClass(cache,env, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, cl, 
          {}, true, Inst.TOP_CALL()) "FIXME: impl" ;
      then
        (cache,Types.VAR("result",
          Types.ATTR(false,SCode.RW(),SCode.VAR(),Absyn.OUTPUT()),false,ty,Types.UNBOUND()) :: inputvarlst);
    case (_,_,_)
      equation 
        Debug.fprint("failtrace", "build_record_constructor_varlst failed\n");
      then
        fail();
  end matchcontinue;
end buildRecordConstructorVarlst;

protected function buildVarlstFromElts "function: buildVarlstFromElts
  
  Helper function to build_record_constructor_varlst
"
	input Env.Cache inCache;
  input list<SCode.Element> inSCodeElementLst;
  input Env.Env inEnv;
  output Env.Cache outCache;
  output list<Types.Var> outTypesVarLst;
algorithm 
  (outCache,outTypesVarLst) :=
  matchcontinue (inCache,inSCodeElementLst,inEnv)
    local
      list<Types.Var> vars;
      Types.Var var;
      SCode.Element comp;
      list<SCode.Element> rest;
      list<Env.Frame> env;
      Env.Cache cache;
    case (cache,((comp as SCode.COMPONENT(component = _)) :: rest),env)
      equation 
        (cache,vars) = buildVarlstFromElts(cache,rest, env);
        (cache,var) = Inst.instRecordConstructorElt(cache,env, comp, true) "P.A Here we need to do a lookup of the type. Therefore we need the env passed along from lookup_xxxx function. FIXME: impl" ;
      then
        (cache,var :: vars);
    case (cache,{},_) then (cache,{}); 
    case (_,_,_) /* Debug.fprint(\"failtrace\", \"- build_varlst_from_elts failed!\\n\") */  then fail(); 
  end matchcontinue;
end buildVarlstFromElts;

public function isInBuiltinEnv "Class lookup
  function: isInBuiltinEnv
 
  Returns true if function can be found in the builtin environment.
"
	input Env.Cache inCache;
  input Absyn.Path inPath;
  output Env.Cache outCache;
  output Boolean outBoolean;
algorithm 
  (outCache,outBoolean):=
  matchcontinue (inCache,inPath)
    local
      list<Env.Frame> i_env;
      Absyn.Path path;
      Env.Cache cache;
    case (cache,path)
      equation 
        (cache,i_env) = Builtin.initialEnv(cache);
        (cache,{}) = lookupFunctionsInEnv(cache,i_env, path);
      then
        (cache,false);
    case (cache,path)
      equation 
        (cache,i_env) = Builtin.initialEnv(cache);
        (cache,_) = lookupFunctionsInEnv(cache,i_env, path);
      then
        (cache,true);
    case (cache,path)
      equation 
        Debug.fprintln("failtrace", "is_in_builtin_env failed");
      then
        fail();
  end matchcontinue;
end isInBuiltinEnv;

protected function lookupClassInEnv "function: lookupClassInEnv
  
  Helper function to lookup_class. Searches the environment for the class.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm 
  (outCache,outClass,outEnv):=
  matchcontinue (inCache,inEnv,inPath,inBoolean)
    local
      SCode.Class c;
      list<Env.Frame> env_1,env,fs,i_env;
      Env.Frame frame,f;
      String id,sid,scope;
      Boolean msg,msgflag;
      Absyn.Path aid;
      Env.Cache cache;
    case (cache,(env as (frame :: fs)),Absyn.IDENT(name = id),msg) /* msg */ 
      equation 
        (cache,c,env_1) = lookupClassInFrame(cache,frame, (frame :: fs), id, msg) "print \"looking in env for \" & print id & print \"\\n\" &" ;
      then
        (cache,c,env_1);
    case (cache,(env as (Env.FRAME(class_1 = SOME(sid),encapsulated_7 = true) :: fs)),(aid as Absyn.IDENT(name = id)),_)
      equation 
        equality(id = sid) "Special case if looking up the class that -is- encapsulated. That must be allowed." ;
        (cache,c,env) = lookupClassInEnv(cache,fs, aid, true);
      then
        (cache,c,env);
    case (cache,(env as (Env.FRAME(class_1 = SOME(sid),encapsulated_7 = true) :: fs)),(aid as Absyn.IDENT(name = id)),true) /* lookup stops at encapsulated classes except for builtin
	    scope, if not found in builtin scope, error */ 
      equation 
        (cache,i_env) = Builtin.initialEnv(cache);
        failure((_,_,_) = lookupClassInEnv(cache,i_env, aid, false));
        scope = Env.printEnvPathStr(env);
        Error.addMessage(Error.LOOKUP_ERROR, {id,scope});
      then
        fail();
    case (cache,(Env.FRAME(class_1 = sid,encapsulated_7 = true) :: fs),(aid as Absyn.IDENT(name = id)),false) /* no error msg if msg = false */ 
      local Option<String> sid;
      equation 
        (cache,i_env) = Builtin.initialEnv(cache);
        failure((_,_,_) = lookupClassInEnv(cache,i_env, aid, false));
      then
        fail();
    case (cache,(Env.FRAME(class_1 = sid,encapsulated_7 = true) :: fs),(aid as Absyn.IDENT(name = id)),msgflag) /* lookup stops at encapsulated classes, except for builtin scope */ 
      local Option<String> sid;
      equation 
        (cache,i_env) = Builtin.initialEnv(cache);
        (cache,c,env_1) = lookupClassInEnv(cache,i_env, aid, msgflag);
      then
        (cache,c,env_1);
    case (cache,((f as Env.FRAME(class_1 = sid,encapsulated_7 = false)) :: fs),id,msgflag) /* if not found and not encapsulated, look in next enclosing scope */ 
      local
        Option<String> sid;
        Absyn.Path id;
      equation 
        (cache,c,env_1) = lookupClassInEnv(cache,fs, id, msgflag);
      then
        (cache,c,env_1);
  end matchcontinue;
end lookupClassInEnv;

protected function lookupTypeInClass "function: lookupTypeInClass
 
  This function looks up an type inside a class. The outer class can be 
  a package. Environment is passed along in case it needs to be modified.
  bool determines whether we restrict lookup for encapsulated class (true).
   
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input SCode.Class inClass;
  input Absyn.Path inPath;
  input Boolean inBoolean;
	output Env.Cache outCache;
  output Types.Type outType;
  output Env.Env outEnv;
algorithm 
  (outCache,outType,outEnv):=
  matchcontinue (inCache,inEnv,inClass,inPath,inBoolean)
    local
      tuple<Types.TType, Option<Absyn.Path>> tp,t;
      list<Env.Frame> env_1,env,env_2,env3,env2,env5,env1,env4;
      SCode.Class cdef,c;
      Absyn.Path classname,p1,path;
      String id,c1,str,cname;
      Boolean encflag;
      SCode.Restriction restr;
      ClassInf.State ci_state;
      Env.Cache cache;
    case (cache,env,cdef,(classname as Absyn.IDENT(name = _)),_)
      equation 
        (cache,tp,env_1) = lookupTypeInEnv(cache,env, classname) ", true" ;
         /* , true encapsulated does not matter, _ */ 
      then
        (cache,tp,env_1);
    case (cache,env,cdef,(classname as Absyn.IDENT(name = _)),_) local String s;
      equation 
        (cache,(c as SCode.CLASS(_,_,_,SCode.R_FUNCTION(),_)),env_1) = lookupClassInEnv(cache,env, classname, false) "If not found, look for classdef that is function and instantiate." ;
        (cache,env_2) = Inst.implicitFunctionTypeInstantiation(cache,env_1, c);
        //s = Env.printEnvStr(env_2);
        //print("env=");print(s);print("\n");
        (cache,t,env3) = lookupTypeInEnv(cache,env_2, classname);
        
      then
        (cache,t,env3);
    case (cache,env,cdef,(classname as Absyn.IDENT(name = _)),_)
      equation 
        (cache,(c as SCode.CLASS(_,_,_,SCode.R_EXT_FUNCTION(),_)),env_1) = lookupClassInEnv(cache,env, classname, false) "If not found, look for classdef that is external function and instantiate." ;
        (cache,env_2) = Inst.implicitFunctionTypeInstantiation(cache,env_1, c);
        (cache,t,env3) = lookupTypeInEnv(cache,env_2, classname);
       then
        (cache,t,env3);
        
     /* Classes that are external objects. Implicityly instantiate to get type */
    case (cache,env,cdef,(classname as Absyn.IDENT(name = _)),_)
      equation 
        (cache,c ,env_1) = lookupClassInEnv(cache,env, classname, false);
        true = Inst.classIsExternalObject(c);
        (cache,_,env_1,_,_,_) = Inst.instClass(cache,env_1, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c, 
          {}, false, Inst.TOP_CALL());
        (cache,t,env_2) = lookupTypeInEnv(cache,env_1, classname);
      then
        (cache,t,env_2);   
    case (cache,env,cdef,Absyn.QUALIFIED(name = c1,path = p1),true /* true means here encapsulated */)
      equation 
        (cache,(c as SCode.CLASS(id,_,(encflag as true),restr,_)),env) = lookupClassInEnv(cache,env, Absyn.IDENT(c1), false) "Restrict lookup to encapsulated elements only" ;
        env2 = Env.openScope(env, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
        (cache,_,env3,_,_,_,_) = Inst.instClassIn(cache,env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {}, true);
        (cache,t,env5) = lookupTypeInClass(cache,env3, c, p1, false);
      then
        (cache,t,env5);
    case (cache,env,cdef,(path as Absyn.QUALIFIED(name = c1,path = p1)),true)
      equation 
        (cache,(c as SCode.CLASS(id,_,(encflag as false),restr,_)),env) = lookupClassInEnv(cache,env, Absyn.IDENT(c1), false) "Restrict lookup to encapsulated elements only" ;
        str = Absyn.pathString(path);
        Error.addMessage(Error.LOOKUP_ENCAPSULATED_RESTRICTION_VIOLATION, {str});
      then
        fail();
    case (cache,env,cdef,Absyn.QUALIFIED(name = c1,path = p1),false)
      equation 
        (cache,(c as SCode.CLASS(id,_,encflag,restr,_)),env1) = lookupClassInEnv(cache,env, Absyn.IDENT(c1), false) "Lookup not restricted to encapsulated elts. only" ;
        env2 = Env.openScope(env1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
        (cache,_,env4,_,_,_,_) = Inst.instClassIn(cache,env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {}, true) ;
        (cache,t,env5) = lookupTypeInClass(cache,env4, c, p1, false);
      then
        (cache,t,env5);
    case (_,_,SCode.CLASS(name = cname),path,_) /* Debug.fprint(\"failtrace\",cname) &
	Debug.fprint(\"failtrace\", \"\\n  - looked for: \") & Absyn.path_string path => s & 
	Debug.fprint(\"failtrace\", s) & 
	Debug.fprint(\"failtrace\", \"\\n\") */  then fail(); 
  end matchcontinue;
end lookupTypeInClass;

protected function lookupClassInFrame "function: lookupClassInFrame
  
  Search for a class within one frame. 
"
  input Env.Cache inCache;
  input Env.Frame inFrame;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm 
  (outCache,outClass,outEnv):=
  matchcontinue (inCache,inFrame,inEnv,inIdent,inBoolean)
    local
      SCode.Class c;
      list<Env.Frame> env,totenv,bcframes,env_1;
      Option<String> sid;
      Env.BinTree ht;
      String id,name;
      list<Env.Item> items;
      Env.Cache cache;
    case (cache,Env.FRAME(class_1 = sid,list_2 = ht),totenv,id,_)
      equation 
        Env.CLASS(c,env) = Env.treeGet(ht, id, Env.myhash) "print \"looking for class \" & print id & print \" in frame\\n\" & 	& print \"found \" & print id & print \"\\n\"" ;
      then
        (cache,c,totenv);
    case (cache,Env.FRAME(class_1 = sid,list_2 = ht),_,id,true)
      equation 
        Env.VAR(_,_,_,_) = Env.treeGet(ht, id, Env.myhash);
        Error.addMessage(Error.LOOKUP_TYPE_FOUND_COMP, {id});
      then
        fail();
    case (cache,Env.FRAME(list_5 = (bcframes as (_ :: _))),totenv,name,_) /* Search base classes */ 
      equation 
        (cache,c,env) = lookupClass(cache,bcframes, Absyn.IDENT(name), false) "print \"Searching baseclasses for \" & print name & print \"\\n\" & 
	Env.print_env_str bcframes => s & print \"env:\" & print s & print \"\\n\" &" ;
      then
        (cache,c,env);
    case (cache,Env.FRAME(class_1 = sid,list_4 = items),totenv,name,_)
      equation 
        (cache,c,env_1) = lookupQualifiedImportedClassInFrame(cache,items, totenv, name);
      then
        (cache,c,env_1);
    case (cache,Env.FRAME(class_1 = sid,list_4 = items),totenv,name,_)
      equation 
        (cache,c,env_1,true) = lookupUnqualifiedImportedClassInFrame(cache,items, totenv, name) "unique" ;
      then
        (cache,c,env_1);
    case (cache,Env.FRAME(class_1 = sid,list_4 = items),totenv,name,_)
      equation 
        (cache,c,env_1,false) = lookupUnqualifiedImportedClassInFrame(cache,items, totenv, name) "unique" ;
        Error.addMessage(Error.IMPORT_SEVERAL_NAMES, {name});
      then
        fail();
  end matchcontinue;
end lookupClassInFrame;

protected function lookupVar2 "function: lookupVar2
  
  Helper function to lookup_var_f and lookup_ident.
  
"
	input Env.Cache inCache;
  input Env.BinTree inBinTree;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output Types.Var outVar;
  output Option<tuple<SCode.Element, Types.Mod>> outTplSCodeElementTypesModOption;
  output Boolean outBoolean;
  output Env.Env outEnv;
algorithm 
  (outCache,outVar,outTplSCodeElementTypesModOption,outBoolean,outEnv):=
  matchcontinue (inCache,inBinTree,inIdent)
    local
      Types.Var fv;
      Option<tuple<SCode.Element, Types.Mod>> c;
      Boolean i;
      list<Env.Frame> env;
      Env.BinTree ht;
      String id;
      Env.Cache cache;
    case (cache,ht,id)
      equation 
        Env.VAR(fv,c,i,env) = Env.treeGet(ht, id, Env.myhash);
      then
        (cache,fv,c,i,env);
  end matchcontinue;
end lookupVar2;

protected function checkSubscripts "function: checkSubscripts
 
  This function checks a list of subscripts agains type, and removes
  dimensions from the type according to the subscripting.
"
  input Types.Type inType;
  input list<Exp.Subscript> inExpSubscriptLst;
  output Types.Type outType;
algorithm 
  outType:=
  matchcontinue (inType,inExpSubscriptLst)
    local
      tuple<Types.TType, Option<Absyn.Path>> t,t_1;
      Types.ArrayDim dim;
      Option<Absyn.Path> p;
      list<Exp.Subscript> ys,s;
      Integer sz,ind;
      list<Exp.Exp> se;
    case (t,{}) then t; 
    case ((Types.T_ARRAY(arrayDim = dim,arrayType = t),p),(Exp.WHOLEDIM() :: ys))
      equation 
        t_1 = checkSubscripts(t, ys);
      then
        ((Types.T_ARRAY(dim,t_1),p));
    case ((Types.T_ARRAY(arrayDim = Types.DIM(integerOption = SOME(sz)),arrayType = t),p),(Exp.SLICE(exp = Exp.ARRAY(array = se)) :: ys))
      local Integer dim;
      equation 
        t_1 = checkSubscripts(t, ys);
        dim = listLength(se) "FIXME: Check range" ;
      then
        ((Types.T_ARRAY(Types.DIM(SOME(dim)),t_1),p));
    case ((Types.T_ARRAY(arrayDim = Types.DIM(integerOption = SOME(sz)),arrayType = t),_),(Exp.INDEX(exp = Exp.ICONST(integer = ind)) :: ys))
      equation 
        (ind > 0) = true;
        (ind <= sz) = true;
        t_1 = checkSubscripts(t, ys);
      then
        t_1;
    case ((Types.T_ARRAY(arrayDim = Types.DIM(integerOption = SOME(sz)),arrayType = t),_),(Exp.INDEX(exp = _) :: ys)) /* HJ: Subscrits needn\'t be constant. No range-checking can
	       be done */ 
      equation 
        t_1 = checkSubscripts(t, ys);
      then
        t_1;
    case ((Types.T_ARRAY(arrayDim = Types.DIM(integerOption = NONE),arrayType = t),_),(Exp.INDEX(exp = _) :: ys))
      equation 
        t_1 = checkSubscripts(t, ys);
      then
        t_1;
    case ((Types.T_ARRAY(arrayDim = Types.DIM(integerOption = SOME(sz)),arrayType = t),_),(Exp.WHOLEDIM() :: ys))
      equation 
        t_1 = checkSubscripts(t, ys);
      then
        t_1;
    case ((Types.T_ARRAY(arrayDim = Types.DIM(integerOption = NONE),arrayType = t),_),(Exp.WHOLEDIM() :: ys))
      equation 
        t_1 = checkSubscripts(t, ys);
      then
        t_1;
    case ((Types.T_ARRAY(arrayDim = Types.DIM(integerOption = SOME(sz)),arrayType = t),_),(Exp.SLICE(exp = _) :: ys))
      equation 
        t_1 = checkSubscripts(t, ys);
      then
        t_1;
    case ((Types.T_ARRAY(arrayDim = Types.DIM(integerOption = NONE),arrayType = t),_),(Exp.SLICE(exp = _) :: ys))
      equation 
        t_1 = checkSubscripts(t, ys);
      then
        t_1;
    case (t,s)
      equation 
        Debug.fprint("failtrace", "- check_subscripts failed ( ");
        Debug.fcall("failtrace", Types.printType, t);
        Debug.fprint("failtrace", ")\n");
      then
        fail();
  end matchcontinue;
end checkSubscripts;

protected function lookupVarF "function: lookupVarF
 
  This function looks in a frame to find a declared variable.  If
  the name being looked up is qualified, the first part of the name
  is looked up, and `lookup_in_var\' is used to for further lookup in
  the result of that lookup.
"
	input Env.Cache inCache;
  input Env.BinTree inBinTree;
  input Exp.ComponentRef inComponentRef;
  output Env.Cache outCache;
  output Types.Attributes outAttributes;
  output Types.Type outType;
  output Types.Binding outBinding;
algorithm 
  (outCache,outAttributes,outType,outBinding):=
  matchcontinue (inCache,inBinTree,inComponentRef)
    local
      String n,id;
      Boolean f;
      SCode.Accessibility acc;
      SCode.Variability vt;
      Absyn.Direction di;
      tuple<Types.TType, Option<Absyn.Path>> ty,ty_1;
      Types.Binding bind,binding,binding2;
      Env.BinTree ht;
      list<Exp.Subscript> ss;
      list<Env.Frame> compenv;
      Types.Attributes attr;
      Exp.ComponentRef ids;
      Env.Cache cache;
    case (cache,ht,Exp.CREF_IDENT(ident = id,subscriptLst = ss))
      equation 
        (cache,Types.VAR(n,Types.ATTR(f,acc,vt,di),_,ty,bind),_,_,_) = lookupVar2(cache,ht, id);
        ty_1 = checkSubscripts(ty, ss);
      then
        (cache,Types.ATTR(f,acc,vt,di),ty_1,bind);
    case (cache,ht,Exp.CREF_QUAL(ident = id,subscriptLst = ss,componentRef = ids)) /* Qualified variables looked up through component environment. */ 
      equation 
        (cache,Types.VAR(n,Types.ATTR(f,acc,vt,di),_,ty,bind),_,_,compenv) = lookupVar2(cache,ht, id);
        (cache,attr,ty,binding) = lookupVar(cache,compenv, ids);
      then
        (cache,attr,ty,binding);
  end matchcontinue;
end lookupVarF;

protected function assertPackage "function: assertPackage
  
  This function checks that a class definition is a package.  This
  breaks the everything-can-be-generalized-to-class principle, since
  it requires that the keyword `package\' is used in the package file.
"
  input SCode.Class inClass;
algorithm 
  _:=
  matchcontinue (inClass)
    case SCode.CLASS(restricion = SCode.R_PACKAGE()) then ();  /* Break the generalize-to-class rule */ 
  end matchcontinue;
end assertPackage;
end Lookup;

