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

encapsulated package Main
" file:        Main.mo
  package:     Main
  description: Modelica main program

  RCS: $Id$

  This is the main program in the Modelica specification.
  It either translates a file given as a command line argument
  or starts a server loop communicating through CORBA or sockets
  (The Win32 implementation only implements CORBA)"

protected import Absyn;
protected import AbsynDep;
protected import BackendDAE;
protected import BackendDAECreate;
protected import BackendDAEUtil;
protected import CevalScript;
protected import ClassLoader;
protected import Config;
protected import Corba;
protected import DAE;
protected import DAEDump;
protected import DAEUtil;
protected import Database;
protected import Debug;
protected import Dependency;
protected import Dump;
protected import DumpGraphviz;
protected import Env;
protected import Error;
protected import ErrorExt;
protected import Flags;
protected import InnerOuter;
protected import Inst;
protected import Interactive;
protected import List;
protected import Parser;
protected import Print;
protected import SCode;
protected import SCodeUtil;
protected import Settings;
protected import SimCode;
protected import Socket;
protected import System;
protected import TaskGraph;
protected import TaskGraphExt;
protected import TplMain;
protected import Util;

protected function serverLoop
"function: serverLoop
  This function is the main loop of the server listening
  to a port which recieves modelica expressions."
  input Integer inInteger;
  input Interactive.SymbolTable inInteractiveSymbolTable;
  output Interactive.SymbolTable outInteractiveSymbolTable;
algorithm
  outInteractiveSymbolTable := matchcontinue (inInteger,inInteractiveSymbolTable)
    local
      String str,replystr;
      Interactive.SymbolTable newsymb,ressymb,isymb;
      Integer shandle;
    case (shandle,isymb)
      equation
        str = Socket.handlerequest(shandle);
        Debug.fprint(Flags.INTERACTIVE_DUMP, "------- Recieved Data from client -----\n");
        Debug.fprint(Flags.INTERACTIVE_DUMP, str);
        Debug.fprint(Flags.INTERACTIVE_DUMP, "------- End recieved Data-----\n");
        Print.clearBuf();
        (true,replystr,newsymb) = handleCommand(str, isymb) "Print.clearErrorBuf &" ;
        Socket.sendreply(shandle, replystr);
        ressymb = serverLoop(shandle, newsymb);
      then
        ressymb;
    case (shandle,isymb)
      equation
        str = Socket.handlerequest(shandle) "2004-11-27 - adrpo added this part to make the loop deterministic" ;
        Debug.fprint(Flags.INTERACTIVE_DUMP, "------- Recieved Data from client -----\n");
        Debug.fprint(Flags.INTERACTIVE_DUMP, str);
        Debug.fprint(Flags.INTERACTIVE_DUMP, "------- End recieved Data-----\n");
        Print.clearBuf() "Print.clearErrorBuf &" ;
        (false,replystr,newsymb) = handleCommand(str, isymb);
        Print.printBuf("Exiting\n") "2004-11-27 - adrpo added part ends here" ;
        Socket.sendreply(shandle, "quit requested, shutting server down\n");
        Socket.close(shandle);
        Socket.cleanup();
      then
        isymb;
  end matchcontinue;
end serverLoop;

protected function checkClassdef
  input String inString;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inString)
    local
      list<String> clst,clst_1;
      String str_1,str;
      Boolean res;
    case (str) /* Need to check for a whitespace after as well to get the keyword,
  e.g typeOf function would be taken as a type definition otherwise */
      equation
        true = Util.strncmp(" ", str, 1);
        clst = stringListStringChar(str);
        clst_1 = listDelete(clst, 0);
        str_1 = stringCharListString(clst_1);
        res = checkClassdef(str_1);
      then
        res;
    case str /* Need to check for a whitespace after as well to get the keyword,
  e.g typeOf function would be taken as a type definition otherwise */
      equation
        false = Util.strncmp("end ", str, 4);
        false = Util.strncmp("type ", str, 5);
        false = Util.strncmp("class ", str, 6);
        false = Util.strncmp("model ", str, 6);
        false = Util.strncmp("block ", str, 6);
        false = Util.strncmp("within ", str, 7);
        false = Util.strncmp("record ", str, 7);
        false = Util.strncmp("package ", str, 8);
        false = Util.strncmp("partial ", str, 8);
        false = Util.strncmp("function ", str, 9);
        false = Util.strncmp("connector ", str, 10);
        false = Util.strncmp("encapsulated ", str, 13);
        false = Util.strncmp("optimization ", str, 13);
      then
        false;
    case _ then true;
  end matchcontinue;
end checkClassdef;

protected function makeDebugResult
  input Flags.DebugFlag inFlag;
  input String res;
  output String res_1;
algorithm
  res_1 := matchcontinue (inFlag,res)
    local
      String debugstr,res_with_debug,flagstr;
    case (Flags.DEBUG_FLAG(name = flagstr),res)
      equation
        true = Flags.isSet(inFlag);
        debugstr = Print.getString();
        res_with_debug = stringAppendList({res,"\n---DEBUG(",flagstr,")---\n",debugstr,"\n---/DEBUG(",flagstr,")---\n"});
      then res_with_debug;
    case (_,res) then res;
  end matchcontinue;
end makeDebugResult;

protected function handleCommand
"function handleCommand
  This function handles the commands in form of strings send to the server
  If the command is quit, the function returns false, otherwise it sends
  the string to the parse function and returns true."
  input String inString;
  input Interactive.SymbolTable inInteractiveSymbolTable;
  output Boolean outBoolean;
  output String outString;
  output Interactive.SymbolTable outInteractiveSymbolTable;
algorithm
  (outBoolean,outString,outInteractiveSymbolTable) := matchcontinue (inString,inInteractiveSymbolTable)
    local
      String str,msg,res_1,res,evalstr,expmsg,debugstr;
      Interactive.SymbolTable isymb,newisymb;
      Absyn.Program p,p_1,newprog,iprog;
      AbsynDep.Depends aDep;
      list<Interactive.Variable> vars_1,vars;
      list<Interactive.CompiledCFunction> cf_1,cf;
      list<SCode.Element> a;
      list<Interactive.InstantiatedClass> b;
      Interactive.Statements exp;
      list<Interactive.LoadedFile> lf;
    case (str,isymb)
      equation
        true = Util.strncmp("quit()", str, 6);
      then
        (false,"Ok\n",isymb);
    case (str,isymb) /* Interactively evaluate an algorithm statement or expression */
      equation
        ErrorExt.setCheckpoint("parsestring");
        //debug_print("Command: don't typeCheck", str);
        Debug.fcall0(Flags.DUMP, Print.clearBuf);
        Debug.fcall0(Flags.DUMP_GRAPHVIZ, Print.clearBuf);
        Debug.fprint(Flags.DUMP,
          "\nNot a class definition, trying expresion parser\n");
        exp = Parser.parsestringexp(str,"<interactive>");
        (evalstr,newisymb) = Interactive.evaluate(exp, isymb, false);
        Debug.fprint(Flags.DUMP, "\n--------------- Parsed expression ---------------\n");
        Debug.fcall(Flags.DUMP, Dump.dumpIstmt, exp);
        res_1 = makeDebugResult(Flags.DUMP, evalstr);
        res = makeDebugResult(Flags.DUMP_GRAPHVIZ, res_1);
        ErrorExt.delCheckpoint("parsestring");
      then
        (true,res,newisymb);
    /* Add a class or function to the interactive symbol table.
     * If it is a function, type check it.
     */
    case (str,
    (isymb as Interactive.SYMBOLTABLE(
      ast = iprog,depends=aDep,instClsLst = b,
      lstVarVal = vars,compiledFunctions = cf,
      loadedFiles = lf)))
      equation
        ErrorExt.rollBack("parsestring");
        //debug_print("Command: typeCheck", str);
        Debug.fcall0(Flags.DUMP, Print.clearBuf);
        Debug.fcall0(Flags.DUMP_GRAPHVIZ, Print.clearBuf);
        Debug.fprint(Flags.DUMP, "\nTrying to parse class definition...\n");
        p = Parser.parsestring(str,"<interactive>");
        p_1 = Interactive.addScope(p, vars);
        vars_1 = Interactive.updateScope(p, vars);
        newprog = Interactive.updateProgram(p_1, iprog);
        // not needed. the functions will be remove by examining
        // build times and files!
        cf_1 = cf; // cf_1 = Interactive.removeCompiledFunctions(p, cf);
        Debug.fprint(Flags.DUMP, "\n--------------- Parsed program ---------------\n");
        Debug.fcall(Flags.DUMP_GRAPHVIZ, DumpGraphviz.dump, newprog);
        Debug.fcall(Flags.DUMP, Dump.dump, newprog);
        res_1 = makeClassDefResult(p_1) "return vector of toplevel classnames";
        res_1 = makeDebugResult(Flags.DUMP, res_1);
        res = makeDebugResult(Flags.DUMP_GRAPHVIZ, res_1);
        isymb = Interactive.SYMBOLTABLE(newprog,aDep,NONE(),b,vars_1,cf_1,lf);
        // Interactive.typeCheckFunction(p, isymb); // You need the new environment before you can check the added functions
      then
        (true,res,isymb);
    case (_,isymb)
      equation
        Print.printBuf("Error occured building AST\n");
        debugstr = Print.getString();
        str = stringAppend(debugstr, "Syntax Error\n");
        str = stringAppend(str, Error.printMessagesStr());
      then
        (true,str,isymb);
    case (str,isymb)
      equation
        _ = setStackOverflowSignal(false);

        Error.addMessage(Error.STACK_OVERFLOW,{str});
      then
        (true,"",isymb);
  end matchcontinue;
end handleCommand;

protected function makeClassDefResult "creates a list of classes of the program to be returned from evaluate"
  input Absyn.Program p;
  output String res;
algorithm
  res := match(p)
    local 
      list<Absyn.Path> names;
      Absyn.Path scope;
      list<Absyn.Class> cls;
    
    case(Absyn.PROGRAM(classes=cls,within_=Absyn.WITHIN(scope))) 
      equation
        names = List.map(cls,Absyn.className);
        names = List.map1(names,Absyn.joinPaths,scope);
        res = "{" +& stringDelimitList(List.map(names,Absyn.pathString),",") +& "}";
      then res;
    
    case(Absyn.PROGRAM(classes=cls,within_=Absyn.TOP())) 
      equation
        names = List.map(cls,Absyn.className);
        res = "{" +& stringDelimitList(List.map(names,Absyn.pathString),",") +& "}";
      then res;
  end match;
end makeClassDefResult;

protected function isModelicaFile
"function: isModelicaFile
  Succeeds if filename ends with .mo or .mof"
  input String inString;
algorithm
  _ := matchcontinue (inString)
    local
      list<String> lst;
      String last,filename;
    
    case (filename)
      equation
        lst = System.strtok(filename, ".");
        last :: _ = listReverse(lst);
        true = stringEq(last, "mo");
      then
        ();
    
    case (filename)
      equation
        lst = System.strtok(filename, ".");
        last :: _ = listReverse(lst);
        true = stringEq(last, "mof");
      then
        ();
  end matchcontinue;
end isModelicaFile;

protected function isFlatModelicaFile
"function: isFlatModelicaFile
  Succeeds if filename ends with .mof"
  input String filename;
protected
  list<String> lst;
  String last;
algorithm
  lst := System.strtok(filename, ".");
  last :: _ := listReverse(lst);
  true := stringEq(last, "mof");
end isFlatModelicaFile;

protected function isModelicaScriptFile
"function: isModelicaScriptFile
  Succeeds if filname end with .mos"
  input String filename;
protected
  list<String> lst;
  String last;
algorithm
  true := System.regularFileExists(filename);
  lst := System.strtok(filename, ".");
  last :: _ := listReverse(lst);
  true := stringEq(last, "mos");
end isModelicaScriptFile;

protected function isCodegenTemplateFile
"function: isCodegenTemplateFile
  Succeeds if filname end with .tpl"
  input String filename;
protected
  list<String> lst;
  String last;
algorithm
  lst := System.strtok(filename, ".");
  last :: _ := listReverse(lst);
  true := stringEq(last, "tpl");
end isCodegenTemplateFile;

protected function showErrors
  input String errorString;
  input String errorMessages;
algorithm
  _ := matchcontinue(errorString, errorMessages)
    case("", "") then ();
    case(errorString, "")
      equation
        print(errorString); print("\n");
      then ();
    case("", errorMessages)
      equation
        print(errorMessages); print("\n");
      then ();
    case(errorString, errorMessages)
      equation
        print(errorString); print("\n");
        print(errorMessages); print("\n");
      then ();
 end matchcontinue;
end showErrors;

protected function createPathFromStringList
 input list<String> inStringLst;
 output Absyn.Path path;
algorithm
 path := matchcontinue(inStringLst)
   local
     String strID;
     list<String> rest;
     Absyn.Path p, pDepth;

   // we cannot have an empty list!
   case ({}) then fail();

   // last element in the list
   case ({strID}) then Absyn.IDENT(strID);

   // we have some more elements
   case (strID::rest)
     equation
       pDepth = createPathFromStringList(rest);
       p = Absyn.QUALIFIED(strID, pDepth);
     then
       p;
  end matchcontinue;
end createPathFromStringList;

protected function parsePathFromString
 input String inString;
 output Absyn.Path path;
algorithm
 path := matchcontinue(inString)
   local
     String str;
     list<String> strLst;
     Absyn.Path p;

   case (str)
     equation
        strLst = Util.stringSplitAtChar(str, ".");
        p = createPathFromStringList(strLst);
     then p;

   case (str)
     equation
       failure(strLst = Util.stringSplitAtChar(str, "."));
       // no "." present in the string, say is a path!
     then
       Absyn.IDENT(str);
  end matchcontinue;
end parsePathFromString;

protected function loadLibs
 input list<String> inLibs;
 input Interactive.SymbolTable inSymTab;
 output Interactive.SymbolTable outSymTab;
algorithm
 outSymTab := matchcontinue(inLibs, inSymTab)
   local
     String lib, mp, f;
     list<String> rest;
     Absyn.Program pnew, p;
     list<Interactive.InstantiatedClass> ic;
     list<Interactive.Variable> iv;
     list<Interactive.CompiledCFunction> cf;
     list<SCode.Element> sp;
     list<Interactive.LoadedFile> lf;
     AbsynDep.Depends aDep;
     Interactive.SymbolTable st, newst;
     Absyn.Path path;

   // no libs or end, return!
   case ({}, st) then st;

   // A .mo-file.
   case (f :: rest, st as Interactive.SYMBOLTABLE(p, aDep, _, ic, iv, cf, lf))
     equation
       isModelicaFile(f);
       pnew = Parser.parse(f,"UTF-8");
       pnew = Interactive.updateProgram(pnew, p);
       newst = Interactive.SYMBOLTABLE(pnew, aDep, NONE(), ic, iv, cf, lf);
       newst = loadLibs(rest, newst);
     then
      newst;

   // some libs present
   case (lib::rest, st as Interactive.SYMBOLTABLE(p,aDep,_,ic,iv,cf,lf))
     equation
       path = parsePathFromString(lib);
       mp = Settings.getModelicaPath();
       pnew = ClassLoader.loadClass(path, {"default"}, mp);
       pnew = Interactive.updateProgram(pnew, p);
       newst = Interactive.SYMBOLTABLE(pnew,aDep,NONE(),ic,iv,cf,lf);
       newst = loadLibs(rest, newst); // load the remaining
     then
       newst;
   // problem with the libs, ignore!
   case (lib::rest, st)
     equation
       Print.printErrorBuf("Failed to load library: " +& lib +& " ... ignoring!\n");
       newst = loadLibs(rest, st); // load the remaining
     then
       newst;
  end matchcontinue;
end loadLibs;

protected function translateFile
"function: translateFile
  This function invokes the translator on a source file.  The argument should be
  a list with a single file name, with the rest of the list being an optional
  list of libraries and .mo-files if the file is a .mo-file"
  input list<String> inStringLst;
algorithm
  _ := matchcontinue (inStringLst)
    local
      Absyn.Program p, pLibs;
      list<SCode.Element> scode;
      DAE.DAElist d_1,d;
      String s,str,f;
      list<String>  libs;
      Absyn.Path cname;
      Boolean silent,notsilent;
      Interactive.Statements stmts;
      Interactive.SymbolTable newst, st;
      Env.Cache cache;
      Env.Env env;
      DAE.FunctionTree funcs;
      list<Absyn.Class> cls;

      /* Version requested using --version*/
    case (_) // try first to see if we had a version request among flags.
      equation
        true = Config.versionRequest();
        print(Settings.getVersionNr());
        print("\n");
      then ();

    case (_)
      equation
        true = Config.helpRequest();
      then
        ();

    // A .mo-file, followed by an optional list of extra .mo-files and libraries.
    // The last class in the first file will be instantiated.
    case (f :: libs)
      equation
        //print("Class to instantiate: " +& Config.classToInstantiate() +& "\n");
        System.realtimeTick(CevalScript.RT_CLOCK_EXECSTAT_MAIN);
        Debug.execStat("Enter Main",CevalScript.RT_CLOCK_EXECSTAT_MAIN);
        // Check that it's a .mo-file.
        isModelicaFile(f);
        // Parse the first file.
        (p as Absyn.PROGRAM(classes = cls)) = Parser.parse(f,"UTF-8");
        // Parse libraries and extra mo-files that might have been given at the command line.
        Interactive.SYMBOLTABLE(ast = pLibs) = loadLibs(libs, Interactive.emptySymboltable);
        // Show any errors that occured during parsing.
        showErrors(Print.getErrorString(), ErrorExt.printMessagesStr());

        // Merge our program with the possible libs and models from extra .mo-files.
        p = Interactive.updateProgram(pLibs, p);

        Debug.fprint(Flags.DUMP, "\n--------------- Parsed program ---------------\n");
        Debug.fcall(Flags.DUMP_GRAPHVIZ, DumpGraphviz.dump, p);
        Debug.fcall(Flags.DUMP, Dump.dump, p);
        s = Debug.fcallret0(Flags.DUMP, Print.getString, "");
        Debug.fcall(Flags.DUMP,print,s);

        p = transformFlatProgram(p,f);

        Debug.fprint(Flags.INFO, "\n------------------------------------------------------------ \n");
        Debug.fprint(Flags.INFO, "---elaborating\n");
        Debug.fprint(Flags.INFO, "\n------------------------------------------------------------ \n");
        Debug.fprint(Flags.INFO, "---instantiating\n");
        Debug.execStat("Parsed file",CevalScript.RT_CLOCK_EXECSTAT_MAIN);

        // Instantiate the program.
        (cache, env, d_1, cname) = instantiate(p);

        Debug.fprint(Flags.BEFORE_FIX_MOD_OUT, "Explicit part:\n");
        Debug.fcall(Flags.BEFORE_FIX_MOD_OUT, DAEDump.dumpDebug, d_1);

        d = fixModelicaOutput(d_1);

        d = Debug.bcallret2(Flags.isSet(Flags.TRANSFORMS_BEFORE_DUMP),DAEUtil.transformationsBeforeBackend,cache,d,d);

        funcs = Env.getFunctionTree(cache);

        Print.clearBuf();
        Debug.fprint(Flags.INFO, "---dumping\n");
        Debug.execStat("Transformations before Dump",CevalScript.RT_CLOCK_EXECSTAT_MAIN);
        s = Debug.fcallret2(Flags.FLAT_MODELICA, DAEDump.dumpStr, d, funcs, "");
        Debug.fcall(Flags.FLAT_MODELICA, Print.printBuf, s);
        Debug.execStat("Dump done",CevalScript.RT_CLOCK_EXECSTAT_MAIN);
        s = DAEDump.dumpStr(d, funcs);
        Debug.execStat("DAEDump done",CevalScript.RT_CLOCK_EXECSTAT_MAIN);
        Print.printBuf(s);
        Debug.fcall2(Flags.DAE_DUMP, DAEDump.dump, d, funcs);
        Debug.fcall(Flags.DAE_DUMP2, DAEDump.dump2, d);
        Debug.fcall(Flags.DAE_DUMP_DEBUG, DAEDump.dumpDebug, d);
        Debug.fcall(Flags.DAE_DUMP_GRAPHV, DAEDump.dumpGraphviz, d);
        Debug.execStat("Misc Dump",CevalScript.RT_CLOCK_EXECSTAT_MAIN);

        // Do any transformations required before going into code generation, e.g. if-equations to expressions.
        d = Debug.bcallret2(boolNot(Flags.isSet(Flags.TRANSFORMS_BEFORE_DUMP)),DAEUtil.transformationsBeforeBackend,cache,d,d);
        
        str = Print.getString();
        silent = Config.silent();
        notsilent = boolNot(silent);
        Debug.bcall(notsilent, print, str);
        Debug.execStat("Transformations before backend",CevalScript.RT_CLOCK_EXECSTAT_MAIN);

        // Run the backend.
        optimizeDae(cache, env, d, p, cname);
        // Show any errors or warnings if there are any!
        showErrors(Print.getErrorString(), ErrorExt.printMessagesStr());
      then ();

    /* Modelica script file .mos */
    case (f::libs)
      equation
        isModelicaScriptFile(f);
        // loading possible libraries given at the command line
        st = loadLibs(libs, Interactive.emptySymboltable);
        
        //System.startTimer();
        //print("\nParseExp");
        // parse our algorithm given in the script        
        stmts = Parser.parseexp(f);
        //System.stopTimer();
        //print("\nParseExp: " +& realString(System.getTimerIntervalTime()));
        
        // are there any errors?
        // show errors if there are any
        showErrors(Print.getErrorString(), ErrorExt.printMessagesStr());
        // evaluate statements and print the result to stdout directly
        newst = Interactive.evaluateToStdOut(stmts, st, true);
      then
        ();
    case {f} /* A template file .tpl (in the Susan language)*/
      equation
        isCodegenTemplateFile(f);
        TplMain.main(f);
      then
        ();

    // deal with problems
    case (f::_)
      equation
        false = System.regularFileExists(f);
        print("File does not exist: "); print(f); print("\n");
        // show errors if there are any
        showErrors(Print.getErrorString(), ErrorExt.printMessagesStr());
      then
        fail();

    case (f::_)
      equation
        true = System.regularFileExists(f);
        print("Error processing file: "); print(f); print("\n");
        // show errors if there are any
        showErrors(Print.getErrorString(), ErrorExt.printMessagesStr());
      then
        fail();
  end matchcontinue;
end translateFile;

protected function transformFlatProgram
"Transforms the variables in equations to have the same format as for variables,
i.e. a.b[3].c[2] becomes CREF_IDENT(\"a.b[3].c\",[INDEX(ICONST(2))])"
input Absyn.Program p;
input String filename;
output Absyn.Program outP;
algorithm
  outP := matchcontinue(p,filename)
    case(p,filename) equation
      isFlatModelicaFile(filename);
      outP = Interactive.transformFlatProgram(p);
      then outP;
    case(p,filename) then p;
  end matchcontinue;
end transformFlatProgram;

protected function instantiate
  "Translates the Absyn.Program to SCode and instantiates either a given class
   specified by the +i flag on the command line, or the last class in the
   program if no class was specified."
  input Absyn.Program program;
  output Env.Cache cache;
  output Env.Env env;
  output DAE.DAElist dae;
  output Absyn.Path cname;
algorithm
  (cache, env, dae, cname) := matchcontinue(program)
    local
      Env.Cache c;
      Env.Env e;
      DAE.DAElist d;
      Absyn.Program p;
      list<SCode.Element> s;
      Absyn.Path class_path;
      String class_to_instantiate;
      Interactive.SymbolTable st;
    case (_)
      equation
        // If no class was explicitly specified, instantiate the last class in
        // the program.
        class_to_instantiate = Config.classToInstantiate();
        true = stringEq(class_to_instantiate,"");
        class_path = Absyn.lastClassname(program);
        st = Interactive.setSymbolTableAST(Interactive.emptySymboltable,program);
        (c, e, d, _) = CevalScript.runFrontEnd(Env.emptyCache(),Env.emptyEnv,class_path,st,true);
      then
        (c, e, d, class_path);
    
    case (_)
      equation
        // If a class to instantiate was given on the command line, instantiate
        // that class.
        class_to_instantiate = Config.classToInstantiate();
        false = stringEq(class_to_instantiate,"");
        class_path = Absyn.stringPath(class_to_instantiate);
        st = Interactive.setSymbolTableAST(Interactive.emptySymboltable,program);
        (c, e, d, _) = CevalScript.runFrontEnd(Env.emptyCache(),Env.emptyEnv,class_path,st,true);
      then
        (c, e, d, class_path);
  end matchcontinue;
end instantiate;

protected function runBackendQ
"function: runBackendQ
  Determine if backend, i.e. BLT etc. should be run.
  It should be run if either \"blt\" flag is set or if
  parallelization is enabled by giving flag -n=<no proc.>"
  output Boolean res_1;
protected
  Boolean bltflag,sim_cg,par,res;
  Integer n;
algorithm
  bltflag := Flags.isSet(Flags.BLT);
  sim_cg := Config.simulationCg();
  n := Config.noProc();
  par := (n > 0);
  res := boolOr(bltflag, par);
  res_1 := boolOr(res, sim_cg);
end runBackendQ;

protected function optimizeDae
"function: optimizeDae
  Run the backend. Used for both parallization and for normal execution."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.DAElist dae;
  input Absyn.Program ap;
  input Absyn.Path inPath5;
algorithm
  _:=
  matchcontinue (inCache,inEnv,dae,ap,inPath5)
    local
      BackendDAE.BackendDAE dlow,dlow_1;
      array<list<Integer>> m,mT;
      array<Integer> v1,v2;
      BackendDAE.StrongComponents comps;
      Absyn.Path classname;
      Env.Cache cache;
      Env.Env env;
      DAE.FunctionTree funcs,funcs_1;
      String str;

    case (cache,env,dae,ap,classname)
      equation
        true = runBackendQ();
        funcs = Env.getFunctionTree(cache);
        dlow = BackendDAECreate.lower(dae,funcs,true);
        (dlow_1,funcs_1) = BackendDAEUtil.getSolvedSystem(cache,env,dlow,funcs,NONE(),NONE(),NONE(),NONE());
        modpar(dlow_1);
        Debug.execStat("Lowering Done",CevalScript.RT_CLOCK_EXECSTAT_MAIN);
        simcodegen(dlow_1,funcs_1,classname,ap,dae);
      then
        ();
    else
      equation
        false = runBackendQ() "so main can print error messages" ;
      then ();
  end matchcontinue;
end optimizeDae;

protected function modpar
"function: modpar
  The automatic paralellzation module."
  input BackendDAE.BackendDAE inBackendDAE;
algorithm
  _ := matchcontinue inBackendDAE
    local
      Integer n,nx,ny,np;
      BackendDAE.BackendDAE dae;
      Real l,b,t1,t2,time;
      String timestr,nps;
      BackendDAE.StrongComponents comps;
    case _
      equation
        true = 0==Config.noProc() or Flags.isSet(Flags.OPENMP) "If modpar not enabled, nproc = 0, return" ;
      then
        ();
    case (dae as BackendDAE.DAE(eqs={BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps))}))
      equation
        TaskGraph.buildTaskgraph(dae, comps);
        TaskGraphExt.dumpGraph("model.viz");
        l = Config.latency();
        b = Config.bandwidth();
        t1 = clock();
        TaskGraphExt.mergeTasks(l, b);
        t2 = clock();
        time = t2 -. t1;
        timestr = realString(time);
        print("task merging took ");
        print(timestr);
        print(" seconds\n");
        TaskGraphExt.dumpMergedGraph("merged_model.viz");
        n = Config.noProc();
        TaskGraphExt.schedule(n);
        (nx,ny,np,_,_,_,_,_,_,_,_,_) = BackendDAEUtil.calculateSizes(dae);
        nps = intString(np);
        print("=======\nnp =");
        print(nps);
        print("=======\n");
        TaskGraphExt.generateCode(nx, ny, np);
        print("done\n");
      then
        ();
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "-modpar failed\n");
      then
        fail();
  end matchcontinue;
end modpar;

protected function simcodegen
"function simcodegen
  Genereates simulation code using the SimCode module"
  input BackendDAE.BackendDAE inBackendDAE5;
  input DAE.FunctionTree inFunctionTree;
  input Absyn.Path inPath;
  input Absyn.Program inProgram3;
  input DAE.DAElist inDAElist4;
algorithm
  _:=
  matchcontinue (inBackendDAE5,inFunctionTree,inPath,inProgram3,inDAElist4)
    local
      BackendDAE.BackendDAE dlow;
      DAE.FunctionTree functionTree;
      String cname_str,file_dir;
      Absyn.ComponentRef a_cref;
      Absyn.Path classname;
      list<SCode.Element> p;
      Absyn.Program ap;
      DAE.DAElist dae;
      array<Integer> ass1,ass2;
      array<list<Integer>> m,mt;
      BackendDAE.StrongComponents comps;
      SimCode.SimulationSettings simSettings;
      String methodbyflag;
      Boolean methodflag;

    case (dlow,functionTree,classname,ap,dae) /* classname ass1 ass2 blocks */
      equation
        true = Config.simulationCg();
        Print.clearErrorBuf();
        Print.clearBuf();
        cname_str = Absyn.pathString(classname);
        simSettings = SimCode.createSimulationSettings(0.0, 1.0, 500, 1e-6,"dassl","","mat",".*",false,"");
        (_,_,_,_,_,_,_) = SimCode.generateModelCode(dlow,functionTree,ap,dae,classname,cname_str,SOME(simSettings),Absyn.FUNCTIONARGS({},{}));
        Debug.execStat("Codegen Done",CevalScript.RT_CLOCK_EXECSTAT_MAIN);
      then
        ();
    /* If not generating simulation code: Succeed so no error messages are printed */
    else
      equation
        false = Config.simulationCg();
      then
        ();
  end matchcontinue;
end simcodegen;

protected function runModparQ
"function: runModparQ
  Returns true if parallelization should be run."
  output Boolean res;
  Integer n;
algorithm
  n := Config.noProc();
  res := (n > 0);
end runModparQ;

protected function fixModelicaOutput
"function: fixModelicaOutput
  Transform the dae, replacing dots with underscore in variables and
  equations."
  input DAE.DAElist inDAElist;
  output DAE.DAElist outDAElist;
algorithm
  outDAElist:=
  matchcontinue (inDAElist)
    local
      list<DAE.Element> dae;
      DAE.DAElist d;
    case d
      equation
        true = Config.modelicaOutput();
        print("DEPRECATED: modelicaOutput option no longer needed\n");
      then
        d;
    case ((d as DAE.DAE(elementLst = dae)))
      equation
        false = Config.modelicaOutput();
      then
        d;
  end matchcontinue;
end fixModelicaOutput;

protected function interactivemode
"function: interactivemode
  Initiate the interactive mode using socket communication."
  input Interactive.SymbolTable symbolTable;
algorithm
  print("Opening a socket on port " +& intString(29500) +& "\n");
  _ := serverLoop(Socket.waitforconnect(29500), symbolTable);
end interactivemode;

protected function interactivemodeCorba
"function: interactivemodeCorba
  Initiate the interactive mode using corba communication."
  input Interactive.SymbolTable inInteractiveSymbolTable;
algorithm
  _:=
  matchcontinue inInteractiveSymbolTable
   local
     Interactive.SymbolTable symbolTable;
    case symbolTable
      equation
        Corba.initialize();
        _ = serverLoopCorba(symbolTable);
      then
        ();
    case symbolTable
      equation
        failure(Corba.initialize());
        Print.printBuf("Failed to initialize Corba! Is another OMC already running?\n");
        Print.printBuf("Exiting!\n");
      then
        ();
  end matchcontinue;
end interactivemodeCorba;


protected function serverLoopCorba
"function: serverLoopCorba
  This function is the main loop of the server for a CORBA impl."
  input Interactive.SymbolTable inInteractiveSymbolTable;
  output Interactive.SymbolTable outInteractiveSymbolTable;
algorithm
  outInteractiveSymbolTable:=
  matchcontinue (inInteractiveSymbolTable)
    local
      String str,replystr;
      Interactive.SymbolTable newsymb,ressymb,isymb;
    case (isymb)
      equation
        str = Corba.waitForCommand();
        Print.clearBuf();
        (true,replystr,newsymb) = handleCommand(str, isymb);
        Corba.sendreply(replystr);
        ressymb = serverLoopCorba(newsymb);
      then
        ressymb;
    case (isymb)
      equation
        str = Corba.waitForCommand() "start - 2005-06-12 - adrpo added this part to make the loop deterministic" ;
        Print.clearBuf();
        (false,replystr,newsymb) = handleCommand(str, isymb);
        Print.printBuf("Exiting\n") "end - 2005-06-12 -" ;
        Corba.sendreply("quit requested, shutting server down\n");
        Corba.close();
      then
        isymb;
  end matchcontinue;
end serverLoopCorba;


protected function readSettings
"function: readSettings
 author: x02lucpo
 Checks if 'settings.mos' exist and uses handleCommand with runScript(...) to execute it.
 Checks if '-s <file>.mos' has been
 returns Interactive.SymbolTable which is used in the rest of the loop"
  input list<String> inStringLst;
  output Interactive.SymbolTable outInteractiveSymbolTable;
algorithm
  outInteractiveSymbolTable:=
  matchcontinue (inStringLst)
    local
      list<String> args;
      String str;
      Interactive.SymbolTable outSymbolTable;
    case (args)
      equation
        outSymbolTable = Interactive.emptySymboltable;
         "" = Util.flagValue("-s",args);
//         this is out-commented because automatically reading settings.mos
//         can make a system bad
//         outSymbolTable = readSettingsFile("settings.mos", Interactive.emptySymboltable);
      then
       outSymbolTable;
    case (args)
      equation
        str = Util.flagValue("-s",args);
        str = System.trim(str," \"");
        outSymbolTable = readSettingsFile(str, Interactive.emptySymboltable);
      then
       outSymbolTable;
  end matchcontinue;
end readSettings;


protected function readSettingsFile
 input String filePath;
  input Interactive.SymbolTable inInteractiveSymbolTable;
  output Interactive.SymbolTable outInteractiveSymbolTable;
algorithm
 outInteractiveSymbolTable :=
  matchcontinue (filePath,inInteractiveSymbolTable)
    local
      String file;
      Interactive.SymbolTable inSymbolTable, outSymbolTable;
      String str;
    case (file,inSymbolTable)
      equation
        true = System.regularFileExists(file);
        str = stringAppendList({"runScript(\"",file,"\")"});
        (_,_,outSymbolTable) = handleCommand(str,inSymbolTable);
      then
        outSymbolTable;
    case (file,inSymbolTable)
      equation
        false = System.regularFileExists(file);
      then
        inSymbolTable;
    case (_,inSymbolTable)
      equation
        print("-readSettingsFile another error\n");
      then
        inSymbolTable;
  end matchcontinue;
end readSettingsFile;

public function main
"function: main
  This is the main function that the MetaModelica Compiler (MMC) runtime system calls to
  start the translation."
  input list<String> inStringLst;
algorithm
  _ := matchcontinue (inStringLst)
    local
      String errstr;
      list<String> args_1,args;
      Boolean ismode,icmode,imode,imode_1;
      String omhome,oldpath,newpath;
      Interactive.SymbolTable symbolTable;
      list<tuple<String, String>> dbResult;
      
      // Setup mingw path only once.
    case _
      equation
        omhome = Settings.getInstallationDirectoryPath();
        _ = System.setEnv("OPENMODELICAHOME",omhome,true) "sendData work-around";
        // print("OMHOME:" +& omhome +& "|");
        true = "Windows_NT" ==& System.os();
        oldpath = System.readEnv("PATH");
        newpath = stringAppendList({omhome,"\\mingw\\bin;",omhome,"\\lib;",oldpath});
        _ = System.setEnv("PATH",newpath,true);
        
        // setup an file database (for in-memory use :memory: as name)
        //Database.open(0, "omc.db");
        //_ = Database.query(0, "create table if not exists Inst(id string not null, value real not null)");
        //_ = Database.query(0, "begin transaction;");
      then 
        fail();
    
    case args as _::_
      equation
        args_1 = Flags.new(args);
       
        true = not System.userIsRoot() or Config.getRunningTestsuite();
        _ = Settings.getInstallationDirectoryPath();
        
        // debug_show_depth(2);
        
        // reset the timer used to calculate 
        // cummulative time of some functions
        // search for System.startTimer/System.stopTimer/System.getTimerIntervalTimer
        // System.resetTimer();

        //setGlobalRoot(Global.crefIndex,  ComponentReference.createEmptyCrefMemory());
        //Env.globalCache = fill(Env.emptyCache,1);
        symbolTable = readSettings(args_1);
        ismode = Flags.isSet(Flags.INTERACTIVE);
        icmode = Flags.isSet(Flags.INTERACTIVE_CORBA);
        imode = boolOr(ismode, icmode);
        imode_1 = boolNot(imode);
        // see if the interactive Socket mode is active
        Debug.bcall1(ismode, interactivemode, symbolTable);
        // see if the interactive Corba mode is active
        Debug.bcall1(icmode, interactivemodeCorba, symbolTable);
        // non of the interactive mode was set, flatten the file
        Debug.bcall(imode_1, translateFile, args_1);
        /*
        errstr = Print.getErrorString();
        Debug.fcall(Flags.ERRORBUF, print, errstr);
        */
        //print("Total time for timer: " +& realString(System.getTimerCummulatedTime()) +& "\n");
        //dbResult = Database.query(0, "end transaction;");
        //dbResult = Database.query(0, "select * from Inst");
      then
        ();
    
    case _
      equation
        true = System.userIsRoot();
        print("You are trying to run OpenModelica as root.\n");
        print("This is a very bad idea. Why you ask?\n");
        print("* The socket interface does not authenticate the user.\n");
        print("* OpenModelica allows execution of arbitrary commands.\n");
        print("* The good news is there is no reason to run OpenModelica as root.\n");
      then fail();
    
    case {}
      equation
        false = System.userIsRoot();
        Flags.printUsage();
      then ();
    
    case _
      equation
        true = not System.userIsRoot() or Config.getRunningTestsuite();
        _ = Settings.getInstallationDirectoryPath();
        print("# Error encountered! Exiting...\n");
        print("# Please check the error message and the flags.\n");
        errstr = Print.getErrorString();
        Print.printBuf("\n\n----\n\nError buffer:\n\n");
        print(errstr);
        print(ErrorExt.printMessagesStr()); print("\n");
      then
        fail();

    case _
      equation
        true = not System.userIsRoot() or Config.getRunningTestsuite();
        failure(_ = Settings.getInstallationDirectoryPath());
        print("Error: OPENMODELICAHOME was not set.\n");
        print("  Read the documentation for instructions on how to set it properly.\n");
        print("  Most OpenModelica release distributions have scripts that set OPENMODELICAHOME for you.\n\n");
        
        // Functions used by external code that needs to be included for linking
        _ = Absyn.isDerCref;
      then fail();
  end matchcontinue;
end main;

end Main;

