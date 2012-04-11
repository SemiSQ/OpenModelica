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

encapsulated package Interactive
" file:        Interactive.mo
  package:     Interactive
  description: This module contain functionality for model management,
               expression evaluation, etc. in the interactive environment.

  $Id$
  
  This module contain functionality for model management, expression evaluation, etc.
  in the interactive environment.
  The module defines a symboltable used in the interactive environment containing:
  - Modelica models (described using Absyn AST)
  - Variable bindings
  - Compiled functions (so they do not need to be recompiled)
  - Instantiated classes (that can be reused, not impl. yet)
  - Modelica models in SCode form (to speed up instantiation. not impl. yet)"

//public imports
public import Absyn;
public import AbsynDep;
public import ConnectionGraph;
public import DAE;
public import Env;
public import SCode;
public import SCodeUtil;
public import Settings;
public import Values;

// protected imports
protected import Builtin;
protected import Ceval;
protected import CevalScript;
protected import ClassInf;
protected import ComponentReference;
protected import Config;
protected import Connect;
protected import Constants;
protected import DAEUtil;
protected import Debug;
protected import Dependency;
protected import Dump;
protected import Error;
protected import ErrorExt;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import InnerOuter;
protected import Inst;
protected import List;
protected import Lookup;
protected import MetaUtil;
protected import Mod;
protected import Parser;
protected import Prefix;
protected import Print;
protected import Refactor;
protected import SCodeFlatten;
protected import SimCode;
protected import Static;
protected import System;
protected import Types;
protected import UnitAbsyn;
protected import Util;
protected import ValuesUtil;


/*
** CompiledCFunction
** Absyn.Path = ie object path in class hierarcy
** DAE.Type = The type of the return value
** Integer = functionHandler
*/
//type CompiledCFunction = tuple<Absyn.Path, DAE.Type, Integer>;

public
uniontype CompiledCFunction
  record CFunction
    Absyn.Path path;
    DAE.Type retType;
    Integer funcHandle;
    Real buildTime "the build time for this function";
    String loadedFromFile "the file we loaded this function from";
  end CFunction;
end CompiledCFunction;

public
uniontype Statement
"An Statement given in the interactive environment can either be
 an Algorithm statement or an expression.
 - Interactive Statement"
  record IALG
    Absyn.AlgorithmItem algItem "algItem" ;
  end IALG;

  record IEXP
    Absyn.Exp exp "exp" ;
  end IEXP;

end Statement;

public
uniontype Statements
  "Several interactive statements are used in Modelica scripts.
  - Interactive Statements"
  record ISTMTS
    list<Statement> interactiveStmtLst "interactiveStmtLst" ;
    Boolean semicolon "semicolon; true = statement ending with a semicolon. The result will not be shown in the interactive environment." ;
  end ISTMTS;

end Statements;

public
uniontype InstantiatedClass "- Instantiated Class"
  record INSTCLASS
    Absyn.Path qualName "qualName ;  The F.Q.name of the inst:ed class" ;
    DAE.DAElist daeElementLst "daeElementLst ; The list of DAE elements" ;
    Env.Env env "env ; The env of the inst:ed class" ;
  end INSTCLASS;

end InstantiatedClass;

public
uniontype Variable "- Interactive Variable"
  record IVAR
    Absyn.Ident varIdent "varIdent ; The variable identifier" ;
    Values.Value value "value ; The value" ;
    DAE.Type type_ "type ; The type of the expression" ;
  end IVAR;

end Variable;

public
uniontype LoadedFile
  "@author adrpo
   A file entry holder, needed to cache the file information
   so files are not loaded if not really necessary"
  record FILE
    String                  fileName            "The path of the file";
    Real                    loadTime            "The time the file was loaded";
    list<Absyn.Path>        classNamesQualified "The names of the classes from the file";
  end FILE;
end LoadedFile;

public
uniontype SymbolTable "- Interactive Symbol Table"
  record SYMBOLTABLE
    Absyn.Program ast "ast ; The ast" ;
    AbsynDep.Depends depends "the dependency information";
    Option<SCode.Program> explodedAst "the explodedAst is invalidated every time the program is updated";
    list<InstantiatedClass> instClsLst "instClsLst ;  List of instantiated classes" ;
    list<Variable> lstVarVal "lstVarVal ; List of variables with values" ;
    list<CompiledCFunction> compiledFunctions "compiledFunctions ; List of compiled functions, F.Q name + type + functionhandler" ;
    list<LoadedFile> loadedFiles "The list of the loaded files with their load time." ;
  end SYMBOLTABLE;

end SymbolTable;

public
uniontype Component "- a component in a class
  this is used in extracting all the components in all the classes"
  record COMPONENTITEM
    Absyn.Path the1 "the class where the component is" ;
    Absyn.Path the2 "the type of the component" ;
    Absyn.ComponentRef the3 "the name of the component" ;
  end COMPONENTITEM;

  record EXTENDSITEM
    Absyn.Path the1 "the class which is extended" ;
    Absyn.Path the2 "the class which is the extension" ;
  end EXTENDSITEM;

end Component;

public
uniontype Components
  record COMPONENTS
    list<Component> componentLst;
    Integer the "the number of components in list. used to optimize the get_dependency_on_class" ;
  end COMPONENTS;

end Components;

public
uniontype ComponentReplacement
  record COMPONENTREPLACEMENT
    Absyn.Path which1 "which class contain the old cref" ;
    Absyn.ComponentRef the2 "the old cref" ;
    Absyn.ComponentRef the3 "the new cref" ;
  end COMPONENTREPLACEMENT;

end ComponentReplacement;

public
uniontype ComponentReplacementRules
  record COMPONENTREPLACEMENTRULES
    list<ComponentReplacement> componentReplacementLst;
    Integer the "the number of rules" ;
  end COMPONENTREPLACEMENTRULES;

end ComponentReplacementRules;

protected uniontype AnnotationType
  record ICON_ANNOTATION end ICON_ANNOTATION;
  record DIAGRAM_ANNOTATION end DIAGRAM_ANNOTATION;
end AnnotationType;

public constant SymbolTable emptySymboltable =
     SYMBOLTABLE(Absyn.PROGRAM({},Absyn.TOP(),Absyn.dummyTimeStamp),
                 AbsynDep.DEPENDS(AbsynDep.AVLTREENODE(NONE(),0,NONE(),NONE()),AbsynDep.AVLTREENODE(NONE(),0,NONE(),NONE())),
                 NONE(),
                 {},
                 {},
                 {},
                 {}) "Empty Interactive Symbol Table" ;

public function evaluate
"function: evaluate
  This function evaluates expressions or statements feed interactively to the compiler.
  inputs:   (Statements, SymbolTable, bool /* verbose */)
  outputs:   string:
                     The resulting string after evaluation. If an error has occurred, this string
                     will be empty. The error messages can be retrieved by calling print_messages_str()
                     in Error.mo.
             SymbolTable"
  input Statements inStatements;
  input SymbolTable inSymbolTable;
  input Boolean inBoolean;
  output String outString;
  output SymbolTable outSymbolTable;
algorithm
  (outString,outSymbolTable) := matchcontinue (inStatements,inSymbolTable,inBoolean)
    local
      String res,res_1,res2,res_2;
      SymbolTable newst,st,newst_1;
      Boolean echo,semicolon,verbose;
      Statement x;
      list<Statement> xs;

    case (ISTMTS(interactiveStmtLst = {x},semicolon = semicolon),st,verbose)
      equation
        showStatement(x, semicolon); 
        (res,newst) = evaluate2(ISTMTS({x},verbose), st);
        echo = getEcho();
        res_1 = selectResultstr(res, semicolon, verbose, echo);
      then
        (res_1,newst);

    case (ISTMTS(interactiveStmtLst = (x :: xs),semicolon = semicolon),st,verbose)
      equation
        showStatement(x, semicolon);
        (res,newst) = evaluate2(ISTMTS({x},semicolon), st);
        echo = getEcho();
        res_1 = selectResultstr(res, semicolon, verbose, echo);
        (res2,newst_1) = evaluate(ISTMTS(xs,semicolon), newst, verbose);
        res_2 = stringAppendList({res_1,res2});
      then
        (res_2,newst_1);
  end matchcontinue;
end evaluate;

public function evaluateToStdOut
"function: evaluateToStdOut
  This function evaluates expressions or statements feed interactively to the compiler.
  The resulting string after evaluation is printed. 
  If an error has occurred, this string will be empty. 
  The error messages can be retrieved by calling print_messages_str() in Error.mo."
  input Statements inStatements;
  input SymbolTable inSymbolTable;
  input Boolean inBoolean;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable := matchcontinue (inStatements,inSymbolTable,inBoolean)
    local
      String res,res_1;
      SymbolTable newst,st,newst_1;
      Boolean echo,semicolon,verbose;
      Statement x;
      Statements new;
      list<Statement> xs;

    case (ISTMTS(interactiveStmtLst = {x},semicolon = semicolon),st,verbose)
      equation 
        showStatement(x,semicolon);
        new = ISTMTS({x},verbose);
        (res,newst) = evaluate2(new, st);
                
        echo = getEcho();
        res_1 = selectResultstr(res, semicolon, verbose, echo);
        print(res_1);
      then
        newst;

    case (ISTMTS(interactiveStmtLst = (x :: xs),semicolon = semicolon),st,verbose)
      equation
        showStatement(x,semicolon);
        new = ISTMTS({x},semicolon);
        (res,newst) = evaluate2(new, st);
        echo = getEcho();
        res_1 = selectResultstr(res, semicolon, verbose, echo);
        print(res_1);
        newst_1 = evaluateToStdOut(ISTMTS(xs,semicolon), newst, verbose);
      then
        newst_1;
  end matchcontinue;
end evaluateToStdOut;

protected function showStatement
  input Statement s;
  input Boolean semicolon;
algorithm
  _:= matchcontinue(s, semicolon)
    case (s, semicolon)
      equation
        true = Flags.isSet(Flags.SHOW_STATEMENT);
        print("Evaluating: " +& Dump.printIstmtStr(ISTMTS({s}, semicolon)) +& "\n");        
      then 
        ();
    
    else ();
  end matchcontinue;
end showStatement;

protected function selectResultstr
"function: selectResultstr
  Returns result string depending on three boolean variables
  - semicolon
  - verbose
  - echo"
  input String inString1;
  input Boolean inBoolean2 "semicolon";
  input Boolean inBoolean3 "verbose";
  input Boolean inBoolean4 "echo";
  output String outString;
algorithm
  outString:=
  matchcontinue (inString1,inBoolean2,inBoolean3,inBoolean4)
    local String str;
    case (str,_,_,false) then "";  /* echo off allways empty string */
    case (str,_,true,_) then str;  /* .. verbose on allways return str */
    case (str,true,_,_) then "";  /* ... semicolon, no resultstr */
    case (str,false,_,_) then str;
  end matchcontinue;
end selectResultstr;

protected function getEcho
"function: getEcho
  Return echo variable, which determines
  if result should be printed or not."
  output Boolean outBoolean;
algorithm
  outBoolean := 0 <> Settings.getEcho();
end getEcho;

public function typeCheckFunction
"function: typeCheckFunction
  Type check a function.
  The function will fail iff a function has illegally typed.
  Errors are handled using side effects in Error.mo
Note: This does not work for recursive functions, so don't use it!"
  input Absyn.Program inProgram;
  input SymbolTable inSymbolTable;
algorithm
  _ := matchcontinue (inProgram,inSymbolTable)
    local
      Absyn.Restriction restriction;
      SymbolTable st;
      list<Env.Frame> env,env_1;
      SCode.Element scode_class;
      Absyn.Class absyn_class,cls;
      Integer len;
      list<Absyn.Class> class_list,morecls;
      Absyn.Within w;
      Absyn.TimeStamp ts;

    /* Do not typecheck the following */
    /* adrpo: these are not needed!
    case (Absyn.BEGIN_DEFINITION(path = _),_) then ();
    case (Absyn.END_DEFINITION(name = _),_) then ();
    case (Absyn.COMP_DEFINITION(element = _),_) then ();
    case (Absyn.IMPORT_DEFINITION(importElementFor = _),_) then ();
    */
    // If it is not a function, return succeess
    case (Absyn.PROGRAM(classes = {Absyn.CLASS(restriction = restriction)}),st)
      equation
        false = Absyn.isFunctionRestriction(restriction);
      then
        ();
    case (Absyn.PROGRAM(classes = {Absyn.CLASS(partialPrefix = true)}),st) then ();
    // Type check the function
    case (Absyn.PROGRAM(classes = {absyn_class}),st)
      equation
        (env,st) = buildEnvFromSymboltable(st);
        scode_class = SCodeUtil.translateClass(absyn_class);
        scode_class = SCodeFlatten.flattenClass(scode_class);

        (_,env_1,_) = Inst.implicitFunctionInstantiation(Env.emptyCache(),env,InnerOuter.emptyInstHierarchy,
          DAE.NOMOD(), Prefix.NOPRE(), scode_class, {});
      then
        ();
    // Recursively go through all classes
    case (Absyn.PROGRAM(classes = (class_list as (cls :: morecls)), within_ = w, globalBuildTimes=ts),st)
      equation
        len = listLength(class_list);
        false = intEq(len, 1) "avoid recurs forever";
        typeCheckFunction(Absyn.PROGRAM({cls},w,ts), st);
        typeCheckFunction(Absyn.PROGRAM(morecls,w,ts), st);
      then
        ();
  end matchcontinue;
end typeCheckFunction;

public function evaluate2
"function: evaluate2
  Helper function to evaluate."
  input Statements inStatements;
  input SymbolTable inSymbolTable;
  output String outString;
  output SymbolTable outSymbolTable;
algorithm
  (outString,outSymbolTable) := matchcontinue (inStatements,inSymbolTable)
    local
      String varsStr,str,str_1;
      SymbolTable st,newst,st_1;
      Statements stmts;
      Absyn.AlgorithmItem algitem;
      Boolean outres;
      Absyn.Exp exp;
      list<Variable> vars;
      Boolean partialInst;

    // evaluate graphical API
    case ((stmts as ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = _))})),st)
      equation
        // adrpo: always evaluate the graphicalAPI with these options so instantiation is faster!
        partialInst = System.getPartialInstantiation();
        System.setPartialInstantiation(true);
        (str,newst) = evaluateGraphicalApi(stmts, st, partialInst);
        
        str_1 = stringAppend(str, "\n");
      then
        (str_1,newst);
        
    // Evaluate algorithm statements in  evaluateAlgStmt()
    case (ISTMTS(interactiveStmtLst = {IALG(algItem = (algitem as Absyn.ALGORITHMITEM(algorithm_ = _)))}, semicolon = outres),st) 
      equation
        (str,st_1) = evaluateAlgStmt(algitem, st);
        str_1 = stringAppend(str, "\n");
      then
        (str_1,st_1);
    
    // Evaluate expressions in evaluate_exprToStr()
    case ((stmts as ISTMTS(interactiveStmtLst = {IEXP(exp = exp)})),st) 
      equation
        (str,st_1) = evaluateExprToStr(exp, st, Absyn.dummyInfo);
        str_1 = stringAppend(str, "\n");
      then
        (str_1,st_1);
  end matchcontinue;
end evaluate2;

protected function evaluateAlgStmt "function: evaluateAlgStmt

   This function takes an \'AlgorithmItem\', i.e. a statement located in an
   algorithm section, and a symboltable as input arguments. The statements
   are recursivly evalutated and a new interactive symbol table is returned.
"
  input Absyn.AlgorithmItem inAlgorithmItem;
  input SymbolTable inSymbolTable;
  output String outString;
  output SymbolTable outSymbolTable;
algorithm
  (outString,outSymbolTable) := matchcontinue (inAlgorithmItem,inSymbolTable)
    local
      list<Env.Frame> env;
      DAE.Exp econd,msg_1,sexp,srexp;
      DAE.Properties prop,rprop;
      SymbolTable st_1,st_2,st_3,st_4,st,newst;
      Absyn.Exp cond,msg,exp,rexp;
      Absyn.Program p;
      String str,ident;
      DAE.Type t;
      Values.Value value;
      list<DAE.Type> types;
      list<String> idents;
      list<Values.Value> values,valList;
      list<Absyn.Exp> crefexps;
      tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> cond1;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> cond2,cond3,elseifexpitemlist;
      list<Absyn.AlgorithmItem> algitemlist,elseitemlist;
      list<Variable> vars;
      String iter,estr;
      list<Absyn.AlgorithmItem> algItemList;
      Values.Value startv, stepv, stopv;
      Absyn.Exp starte, stepe, stope;
      Absyn.ComponentRef cr;
      Env.Cache cache;
      Absyn.Info info;
      Absyn.FunctionArgs fargs;

    case (Absyn.ALGORITHMITEM(info=info,
          algorithm_ = Absyn.ALG_NORETCALL(functionCall = Absyn.CREF_IDENT(name = "assert"),
          functionArgs = Absyn.FUNCTIONARGS(args = {cond,msg}))),
          (st as SYMBOLTABLE(ast = p)))
      equation
        (env,st) = buildEnvFromSymboltable(st);
        (cache,econd,prop,SOME(st_1)) = Static.elabExp(Env.emptyCache(),env, cond, true, SOME(st),true,Prefix.NOPRE(),info);
        (_,Values.BOOL(true),SOME(st_2)) = Ceval.ceval(cache,env, econd, true,SOME(st_1),Ceval.MSG(info));
      then
        ("",st_2);

    case (Absyn.ALGORITHMITEM(info=info,algorithm_ = Absyn.ALG_NORETCALL(functionCall = Absyn.CREF_IDENT(name = "assert"),
          functionArgs = Absyn.FUNCTIONARGS(args = {cond,msg}))),
          (st as SYMBOLTABLE(ast = p)))
      equation
        (env,st) = buildEnvFromSymboltable(st);
        (cache,msg_1,prop,SOME(st_1)) = Static.elabExp(Env.emptyCache(),env, msg, true, SOME(st),true,Prefix.NOPRE(),info);
        (_,Values.STRING(str),SOME(st_2)) = Ceval.ceval(cache,env, msg_1, true,SOME(st_1),Ceval.MSG(info));
      then
        (str,st_2);

    case (Absyn.ALGORITHMITEM(info=info,algorithm_ = Absyn.ALG_NORETCALL(functionCall = cr,functionArgs = fargs)),st)
      equation
        (env,st) = buildEnvFromSymboltable(st);
        exp = Absyn.CALL(cr,fargs);
        (cache,sexp,prop,SOME(st_1)) = Static.elabExp(Env.emptyCache(), env, exp, true, SOME(st),true,Prefix.NOPRE(),info);
        (_,_,SOME(st_2)) = Ceval.ceval(cache, env, sexp, true,SOME(st_1),Ceval.MSG(info));
      then
        ("",st_2);

    case /* Special case to lookup fields of records.
          * SimulationResult, etc are not in the environment, but it's nice to be able to script them anyway */
      (Absyn.ALGORITHMITEM(info=info,algorithm_ =
        Absyn.ALG_ASSIGN(assignComponent =
        Absyn.CREF(Absyn.CREF_IDENT(name = ident,subscripts = {})),value = Absyn.CREF(cr))),
        (st as SYMBOLTABLE(lstVarVal = vars)))
      equation
        value = getVariableValueLst(Absyn.pathToStringList(Absyn.crefToPath(cr)), vars);
        str = ValuesUtil.valString(value);
        t = Types.typeOfValue(value);
        newst = addVarToSymboltable(ident, value, t, st);
      then (str,newst);

    case
      (Absyn.ALGORITHMITEM(info=info,algorithm_ =
        Absyn.ALG_ASSIGN(assignComponent =
        Absyn.CREF(Absyn.CREF_IDENT(name = ident,subscripts = {})),value = exp)),
        (st as SYMBOLTABLE(ast = p)))
      equation
        (env,st) = buildEnvFromSymboltable(st);
        (cache,sexp,DAE.PROP(_,_),SOME(st_1)) = Static.elabExp(Env.emptyCache(),env, exp, true, SOME(st),true,Prefix.NOPRE(),info);
        (_,value,SOME(st_2)) = Ceval.ceval(cache,env, sexp, true,SOME(st_1),Ceval.MSG(info));
        t = Types.typeOfValue(value) "This type can be more specific than the elaborated type; if the dimensions are unknown...";
        str = ValuesUtil.valString(value);
        newst = addVarToSymboltable(ident, value, t, st_2);
      then
        (str,newst);

    case
      (Absyn.ALGORITHMITEM(info=info,algorithm_ =
        Absyn.ALG_ASSIGN(assignComponent =
        Absyn.TUPLE(expressions = crefexps),value = rexp)),
        (st as SYMBOLTABLE(ast = p))) /* Since expressions cannot be tuples an empty string is returned */
      equation
        (env,st) = buildEnvFromSymboltable(st);
        (cache,srexp,rprop,SOME(st_1)) = Static.elabExp(Env.emptyCache(),env, rexp, true, SOME(st),true,Prefix.NOPRE(),info);
        DAE.T_TUPLE(tupleType = types) = Types.getPropType(rprop);
        idents = List.map(crefexps, getIdentFromTupleCrefexp);
        (_,Values.TUPLE(values),SOME(st_2)) = Ceval.ceval(cache, env, srexp, true, SOME(st_1), Ceval.MSG(info));
        newst = addVarsToSymboltable(idents, values, types, st_2);
      then
        ("",newst);

    case
      (Absyn.ALGORITHMITEM(info=info,algorithm_ =
        Absyn.ALG_IF(
        ifExp = exp,
        trueBranch = algitemlist,
        elseIfAlgorithmBranch = elseifexpitemlist,
        elseBranch = elseitemlist)),st) /* IF-statement */
      equation
        cond1 = (exp,algitemlist);
        cond2 = (cond1 :: elseifexpitemlist);
        cond3 = listAppend(cond2, {(Absyn.BOOL(true),elseitemlist)});
        st_1 = evaluateIfStatementLst(cond3,st,info);
      then
        ("",st_1);

     /* while-statement */
    case (Absyn.ALGORITHMITEM(info=info,algorithm_ = Absyn.ALG_WHILE(boolExpr = exp,whileBody = algitemlist)),st)
      equation
        (value,st_1) = evaluateExpr(exp, st,info);
        st_2 = evaluateWhileStmt(value, exp, algitemlist, st_1,info);
      then
        ("",st_2);

    /* for-statement, optimized case, e.g.: for i in 1:1000 loop */
    case (Absyn.ALGORITHMITEM(info=info,algorithm_ =
        Absyn.ALG_FOR(iterators = {Absyn.ITERATOR(iter, NONE(), SOME(Absyn.RANGE(start=starte,step=NONE(), stop=stope)))},
        forBody = algItemList)),st)
      equation
        (startv,st_1) = evaluateExpr(starte, st,info);
        (stopv,st_2) = evaluateExpr(stope, st_1,info);
        st_3 = evaluateForStmtRangeOpt(iter, startv, Values.INTEGER(1), stopv, algItemList, st_2);
     then
        ("",st_3);

    /* for-statement, optimized case, e.g.: for i in 7.3:0.4:1000.3 loop */
    case (Absyn.ALGORITHMITEM(info=info,algorithm_ =
        Absyn.ALG_FOR(iterators = {Absyn.ITERATOR(iter, NONE(), SOME(Absyn.RANGE(start=starte, step=SOME(stepe), stop=stope)))},
        forBody = algItemList)),st)
      equation
        (startv,st_1) = evaluateExpr(starte, st,info);
        (stepv,st_2) = evaluateExpr(stepe, st_1,info);
        (stopv,st_3) = evaluateExpr(stope, st_2,info);
        st_4 = evaluateForStmtRangeOpt(iter, startv, stepv, stopv, algItemList, st_3);
      then
        ("",st_4);

    /* for-statement, general case */
    case (Absyn.ALGORITHMITEM(info=info,algorithm_ =
        Absyn.ALG_FOR(iterators = {Absyn.ITERATOR(iter, NONE(), SOME(exp))},forBody = algItemList)),st)
      equation
        (Values.ARRAY(valueLst = valList),st_1) = evaluateExpr(exp, st,info);
        st_2 = evaluateForStmt(iter, valList, algItemList, st_1);
      then
        ("",st_2);

    /* for-statement - not an array type */
    case (Absyn.ALGORITHMITEM(info=info,algorithm_ = Absyn.ALG_FOR(iterators = {Absyn.ITERATOR(range = SOME(exp))})),st)
      equation
        (estr,_) = stringRepresOfExpr(exp, st);
        Error.addSourceMessage(Error.NOT_ARRAY_TYPE_IN_FOR_STATEMENT, {estr}, info);
      then
        fail();
  end matchcontinue;
end evaluateAlgStmt;

protected function evaluateForStmt
"evaluates a for-statement in an algorithm section"
  input String iter "The iterator variable which will be assigned different values";
  input list<Values.Value> valList "List of values that the iterator later will be assigned to";
  input list<Absyn.AlgorithmItem> algItemList;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable:=
  match (iter,valList,algItemList, inSymbolTable)
    local
      Values.Value val;
      list<Values.Value> vallst;
      list<Absyn.AlgorithmItem> algItems;
      SymbolTable st1,st2,st3,st4,st5;
      String str;
    case (iter, val::vallst, algItems, st1)
    equation
      st2 = appendVarToSymboltable(iter, val, Types.typeOfValue(val), st1);
      str = Dump.unparseAlgorithmStrLst(2,algItems,"\n");
      st3 = evaluateAlgStmtLst(algItems, st2);
      st4 = deleteVarFromSymboltable(iter, st3);
      st5 = evaluateForStmt(iter, vallst, algItems, st4);
    then
      st5;
    case (_, {}, _, st1)
    then
      st1;
  end match;
end evaluateForStmt;

protected function evaluateForStmtRangeOpt
  "Optimized version of for statement. In this case, we do not create a large array if
  a range expression is given. E.g. for i in 1:10000 loop"
  input String iter "The iterator variable which will be assigned different values";
  input Values.Value startVal;
  input Values.Value stepVal;
  input Values.Value stopVal;
  input list<Absyn.AlgorithmItem> algItemList;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable := matchcontinue (iter, startVal, stepVal, stopVal, algItemList, inSymbolTable)
    local
      Values.Value startv, stepv, stopv, nextv;
      list<Absyn.AlgorithmItem> algItems;
      SymbolTable st1,st2,st3,st4,st5;
    
    case (iter, startv, stepv, stopv, algItems, st1)
      equation
        true = ValuesUtil.safeLessEq(startv, stopv);
        st2 = appendVarToSymboltable(iter, startv, Types.typeOfValue(startv), st1);
        st3 = evaluateAlgStmtLst(algItems, st2);
        st4 = deleteVarFromSymboltable(iter, st3);
        nextv = ValuesUtil.safeIntRealOp(startv, stepv, Values.ADDOP());
        st5 = evaluateForStmtRangeOpt(iter, nextv, stepv, stopv, algItems, st4);
      then
        st5;
    case (_,_,_,_,_,st1)
      then
        st1;
  end matchcontinue;
end evaluateForStmtRangeOpt;


protected function evaluateWhileStmt
"function: evaluateWhileStmt
  Recursively evaluates the while statement.
  Note that it is tail-recursive, so we should result
  in a iterative implementation."
  input Values.Value inValue;
  input Absyn.Exp inExp;
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  input SymbolTable inSymbolTable;
  input Absyn.Info info;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable:=
  matchcontinue (inValue,inExp,inAbsynAlgorithmItemLst,inSymbolTable,info)
    local
      SymbolTable st,st_1,st_2,st_3;
      Values.Value value;
      Absyn.Exp exp;
      list<Absyn.AlgorithmItem> algitemlst;
      String estr,tstr;
      DAE.Type vtype;
    case (Values.BOOL(boolean = false),_,_,st,info) then st;
    case (Values.BOOL(boolean = true),exp,algitemlst,st,info)
      equation
        st_1 = evaluateAlgStmtLst(algitemlst, st);
        (value,st_2) = evaluateExpr(exp, st_1,info);
        st_3 = evaluateWhileStmt(value, exp, algitemlst, st_2,info); /* Tail recursive */
      then
        st_3;
    case (Values.BOOL(_), _,_,st,info) // An error occured when evaluating the algorithm items
      then
        st;
    case (value,exp,_,st,info) // The condition value was not a boolean
      equation
        (estr,_) = stringRepresOfExpr(exp, st);
        vtype = Types.typeOfValue(value);
        tstr = Types.unparseType(vtype);
        Error.addSourceMessage(Error.WHILE_CONDITION_TYPE_ERROR, {estr,tstr},info);
      then
        fail();
  end matchcontinue;
end evaluateWhileStmt;

protected function evaluatePartOfIfStatement
"function: evaluatePartOfIfStatement
  Evaluates one part of a if statement, i.e. one \"case\". If the condition is true, the algorithm items
  associated with this condition are evaluated. The first argument returned is set to true if the
  condition was evaluated to true. Fails if the value is not a boolean.
  Note that we are sending the expression as an value, so that it does not need to be evaluated twice."
  input Values.Value inValue;
  input Absyn.Exp inExp;
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  input list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> inTplAbsynExpAbsynAlgorithmItemLstLst;
  input SymbolTable inSymbolTable;
  input Absyn.Info info;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable:=
  matchcontinue (inValue,inExp,inAbsynAlgorithmItemLst,inTplAbsynExpAbsynAlgorithmItemLstLst,inSymbolTable,info)
    local
      SymbolTable st_1,st;
      list<Absyn.AlgorithmItem> algitemlst;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> algrest;
      String estr,tstr;
      DAE.Type vtype;
      Values.Value value;
      Absyn.Exp exp;
    case (Values.BOOL(boolean = true),_,algitemlst,_,st,info)
      equation
        st_1 = evaluateAlgStmtLst(algitemlst, st);
      then
        st_1;
    case (Values.BOOL(boolean = false),_,algitemlst,algrest,st,info)
      equation
        st_1 = evaluateIfStatementLst(algrest, st, info);
      then
        st_1;
    case (value,exp,_,_,st,info) /* Report type error */
      equation
        (estr,_) = stringRepresOfExpr(exp, st);
        vtype = Types.typeOfValue(value);
        tstr = Types.unparseType(vtype);
        Error.addSourceMessage(Error.IF_CONDITION_TYPE_ERROR, {estr,tstr}, info);
      then
        fail();
  end matchcontinue;
end evaluatePartOfIfStatement;

protected function evaluateIfStatementLst
"function: evaluateIfStatementLst
  Evaluates all parts of a if statement
  (i.e. a list of exp  statements)"
  input list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> inTplAbsynExpAbsynAlgorithmItemLstLst;
  input SymbolTable inSymbolTable;
  input Absyn.Info info;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable:=
  match (inTplAbsynExpAbsynAlgorithmItemLstLst,inSymbolTable,info)
    local
      SymbolTable st,st_1,st_2;
      Values.Value value;
      Absyn.Exp exp;
      list<Absyn.AlgorithmItem> algitemlst;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> algrest;
    case ({},st,info) then st;
    case (((exp,algitemlst) :: algrest),st,info)
      equation
        (value,st_1) = evaluateExpr(exp, st, info);
        st_2 = evaluatePartOfIfStatement(value, exp, algitemlst, algrest, st_1, info);
      then
        st_2;
  end match;
end evaluateIfStatementLst;

protected function evaluateAlgStmtLst
"function: evaluateAlgStmtLst
   Evaluates a list of algorithm statements"
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable:=
  match (inAbsynAlgorithmItemLst,inSymbolTable)
    local
      SymbolTable st,st_1,st_2;
      Absyn.AlgorithmItem algitem;
      list<Absyn.AlgorithmItem> algrest;
    case ({},st) then st;
    case ((algitem :: algrest),st)
      equation
        (_,st_1) = evaluateAlgStmt(algitem, st);
        st_2 = evaluateAlgStmtLst(algrest, st_1);
      then
        st_2;
  end match;
end evaluateAlgStmtLst;

protected function evaluateExpr
"function: evaluateExpr
   Evaluates an expression and returns its value.
   We need to return the symbol table, since the command loadFile()
   reads in data to the interactive environment.
   Note that this function may fail.

   Input:  Absyn.Exp - Expression to be evaluated
           SymbolTable - The symbol table
   Output: Values.Value - Resulting value of the expression"
  input Absyn.Exp inExp;
  input SymbolTable inSymbolTable;
  input Absyn.Info info;
  output Values.Value outValue;
  output SymbolTable outSymbolTable;
algorithm
  (outValue,outSymbolTable):=
  matchcontinue (inExp,inSymbolTable,info)
    local
      list<Env.Frame> env;
      DAE.Exp sexp;
      DAE.Properties prop;
      SymbolTable st_1,st_2,st;
      Values.Value value;
      Absyn.Exp exp;
      Absyn.Program p;
      Env.Cache cache;
      list<Variable> vars;
      Absyn.ComponentRef cr;

      /* Special case to lookup fields of records.
       * SimulationResult, etc are not in the environment, but it's nice to be able to script them anyway */
    case (Absyn.CREF(cr),(st as SYMBOLTABLE(lstVarVal = vars)),info)
      equation
        value = getVariableValueLst(Absyn.pathToStringList(Absyn.crefToPath(cr)), vars);
      then (value,st);

    case (exp,(st as SYMBOLTABLE(ast = p)),info)
      equation
        (env,st) = buildEnvFromSymboltable(st);
        (cache,sexp,prop,SOME(st_1)) = Static.elabExp(Env.emptyCache(), env, exp, true, SOME(st),true,Prefix.NOPRE(),info);
        (_,value,SOME(st_2)) = Ceval.ceval(cache,env, sexp, true,
            SOME(st_1),Ceval.MSG(info));
      then
        (value,st_2);
  end matchcontinue;
end evaluateExpr;

protected function stringRepresOfExpr
"function: stringRepresOfExpr
   This function returns a string representation of an expression. For example expression
   33+22 will result in \"55\" and expression: \"my\" + \"string\" will result in  \"\"my\"+\"string\"\". "
  input Absyn.Exp exp;
  input SymbolTable ist;
  output String estr;
  output SymbolTable st;
protected
  list<Env.Frame> env;
  DAE.Exp sexp;
  DAE.Properties prop;
  SymbolTable st_1;
algorithm
  (env,st) := buildEnvFromSymboltable(ist);
  (_,sexp,prop,SOME(st_1)) := Static.elabExp(Env.emptyCache(),env, exp, true, SOME(st),true,Prefix.NOPRE(),Absyn.dummyInfo);
  (_, sexp, prop) := Ceval.cevalIfConstant(Env.emptyCache(), env, sexp, prop, true, Absyn.dummyInfo);
  estr := ExpressionDump.printExpStr(sexp);
end stringRepresOfExpr;

protected function evaluateExprToStr
"function: evaluateExprToStr
   This function is similar to evaluateExpr, with the difference that it returns a string
   and that it never fails. If the expression contain errors, an empty string will be returned
   and the errors will be stated using Error.mo

   Input:  Absyn.Exp - Expression to be evaluated
           SymbolTable - The symbol table
   Output: string - The resulting value represented as a string"
  input Absyn.Exp inExp;
  input SymbolTable inSymbolTable;
  input Absyn.Info info;
  output String outString;
  output SymbolTable outSymbolTable;
algorithm
  (outString,outSymbolTable):=
  matchcontinue (inExp,inSymbolTable,info)
    local
      Values.Value value;
      SymbolTable st_1,st;
      String str;
      Absyn.Exp exp;
    case (exp,st,info)
      equation
        (value,st_1) = evaluateExpr(exp, st, info);
        str = ValuesUtil.valString(value);
      then
        (str,st_1);
    case (_,st,_) then ("",st);
  end matchcontinue;
end evaluateExprToStr;

protected function getIdentFromTupleCrefexp
"function: getIdentFromTupleCrefexp
  Return the (first) identifier of a Component Reference in an expression."
  input Absyn.Exp inExp;
  output Absyn.Ident outIdent;
algorithm
  outIdent:=
  matchcontinue (inExp)
    local
      String id,str;
      Absyn.Exp exp;
    case Absyn.CREF(componentRef = Absyn.CREF_IDENT(name = id)) then id;
    case exp
      equation
        str = Dump.printExpStr(exp);
        Error.addMessage(Error.INVALID_TUPLE_CONTENT, {str});
      then
        fail();
  end matchcontinue;
end getIdentFromTupleCrefexp;

public function getTypeOfVariable
"function: getTypeOfVariables
  Return the type of an interactive variable,
  given a list of variables and a variable identifier."
  input Absyn.Ident inIdent;
  input list<Variable> inVariableLst;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (inIdent,inVariableLst)
    local
      String id,varid;
      DAE.Type tp;
      list<Variable> rest;
    
    case (id,{}) then fail();
    case (varid,(IVAR(varIdent = id,type_ = tp) :: rest))
      equation
        true = stringEq(varid, id);
      then
        tp;
    case (varid,(IVAR(varIdent = id) :: rest))
      equation
        false = stringEq(varid, id);
        tp = getTypeOfVariable(varid, rest);
      then
        tp;
  end matchcontinue;
end getTypeOfVariable;

protected function addVarsToSymboltable
"function: addVarsToSymboltable
  Add a list of variables to the interactive
  symboltable given names, values and types."
  input list<Absyn.Ident> inAbsynIdentLst;
  input list<Values.Value> inValuesValueLst;
  input list<DAE.Type> inTypesTypeLst;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable:=
  match (inAbsynIdentLst,inValuesValueLst,inTypesTypeLst,inSymbolTable)
    local
      SymbolTable st,st_1,st_2;
      String id;
      list<String> idrest;
      Values.Value v;
      list<Values.Value> vrest;
      DAE.Type t;
      list<DAE.Type> trest;
    case ({},_,_,st) then st;
    case ((id :: idrest),(v :: vrest),(t :: trest),st)
      equation
        st_1 = addVarToSymboltable(id, v, t, st);
        st_2 = addVarsToSymboltable(idrest, vrest, trest, st_1);
      then
        st_2;
  end match;
end addVarsToSymboltable;

public function addVarToSymboltable
"function: addVarToSymboltable
  Helper function to addVarsToSymboltable."
  input Absyn.Ident inIdent;
  input Values.Value inValue;
  input DAE.Type inType;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable:=
  match (inIdent,inValue,inType,inSymbolTable)
    local
      list<Variable> vars_1,vars;
      String ident;
      Values.Value v;
      DAE.Type t;
      Absyn.Program p;
      Option<list<SCode.Element>> sp;
      list<InstantiatedClass> id;
      list<CompiledCFunction> cf;
      list<LoadedFile> lf;
      AbsynDep.Depends aDep;

    case (ident,v,t,
      SYMBOLTABLE(
      ast = p,
      depends = aDep,
      explodedAst = sp,
      instClsLst = id,
      lstVarVal = vars,
      compiledFunctions = cf,
      loadedFiles = lf))
      equation
        vars_1 = addVarToVarlist(ident, v, t, vars);
      then
        SYMBOLTABLE(p,aDep,sp,id,vars_1,cf,lf);
  end match;
end addVarToSymboltable;

public function appendVarToSymboltable
"Appends a variable to the interactive symbol table.
 Compared to addVarToSymboltable, this function does
 not search for the identifier, it adds the variable
 to the beginning of the list.
 Used in for example iterators in for statements."
  input Absyn.Ident inIdent;
  input Values.Value inValue;
  input DAE.Type inType;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable:=
  match (inIdent,inValue,inType,inSymbolTable)
    local
      list<Variable> vars_1,vars;
      String ident;
      Values.Value v;
      DAE.Type t;
      Absyn.Program p;
      Option<list<SCode.Element>> sp;
      list<InstantiatedClass> id;
      list<CompiledCFunction> cf;
      list<LoadedFile> lf;
      AbsynDep.Depends aDep;

    case (ident,v,t,
      SYMBOLTABLE(
      ast = p,
      depends = aDep,
      explodedAst = sp,
      instClsLst = id,
      lstVarVal = vars,
      compiledFunctions = cf,
      loadedFiles = lf))
      equation
        vars_1 = (IVAR(ident,v,t))::vars;
      then
        SYMBOLTABLE(p,aDep,sp,id,vars_1,cf,lf);
  end match;
end appendVarToSymboltable;

public function deleteVarFromSymboltable
  input Absyn.Ident inIdent;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable:=
  match (inIdent,inSymbolTable)
    local
      list<Variable> vars_1,vars;
      String ident;
      Absyn.Program p;
      Option<list<SCode.Element>> sp;
      list<InstantiatedClass> id;
      list<CompiledCFunction> cf;
      list<LoadedFile> lf;
      AbsynDep.Depends aDep;

    case (ident,
      SYMBOLTABLE(
      ast = p,
      depends = aDep,
      explodedAst = sp,
      instClsLst = id,
      lstVarVal = vars,
      compiledFunctions = cf,
      loadedFiles = lf))
      equation
        vars_1 = deleteVarFromVarlist(ident, vars);
      then
        SYMBOLTABLE(p,aDep,sp,id,vars_1,cf,lf);
  end match;
end deleteVarFromSymboltable;

protected function deleteVarFromVarlist
"deletes the first variable found"
  input Absyn.Ident inIdent;
  input list<Variable> inVariableLst;
  output list<Variable> outVariableLst;
algorithm
  outVariableLst := matchcontinue (inIdent,inVariableLst)
    local
      String ident,id2;
      list<Variable> rest, rest2;
      Variable var;

    case (ident,{})
      then {};

    case (ident,(IVAR(varIdent = id2) :: rest))
      equation
        true = stringEq(ident, id2);
      then
        rest;
    
    case (ident,var::rest)
      equation
        rest2 = deleteVarFromVarlist(ident, rest);
      then
        var::rest2;
  end matchcontinue;
end deleteVarFromVarlist;

protected function addVarToVarlist
"Assignes a value to a variable with a specific identifier."
  input Absyn.Ident inIdent;
  input Values.Value inValue;
  input DAE.Type inType;
  input list<Variable> inVariableLst;
  output list<Variable> outVariableLst;
algorithm
  outVariableLst := matchcontinue (inIdent,inValue,inType,inVariableLst)
    local
      String ident,id2;
      Values.Value v,val2;
      DAE.Type t,t2;
      list<Variable> rest,rest_1;
    case (ident,v,t,(IVAR(varIdent = id2) :: rest))
      equation
        true = stringEq(ident, id2);
      then
        (IVAR(ident,v,t) :: rest);
    case (ident,v,t,(IVAR(varIdent = id2,value = val2,type_ = t2) :: rest))
      equation
        false = stringEq(ident, id2);
        rest_1 = addVarToVarlist(ident, v, t, rest);
      then
        (IVAR(id2,val2,t2) :: rest_1);
    case (ident,v,t,{}) then {IVAR(ident,v,t)};
  end matchcontinue;
end addVarToVarlist;

public function buildEnvFromSymboltable
"function: buildEnvFromSymboltable
   author: PA
   Builds an environment from a symboltable by adding all
   interactive variables and their bindings to the environment."
  input SymbolTable inSymbolTable;
  output Env.Env outEnv;
  output SymbolTable st;
algorithm
  (outEnv,st) := match (inSymbolTable)
    local
      list<SCode.Element> p_1,sp;
      list<Env.Frame> env,env_1;
      Absyn.Program p;
      list<InstantiatedClass> ic;
      list<Variable> vars;
      list<CompiledCFunction> cf;
      list<LoadedFile> loadedFiles;
      AbsynDep.Depends depends;
    case (st as SYMBOLTABLE(lstVarVal = vars))
      equation
        (p_1,st) = symbolTableToSCode(st);
        (_,env) = Inst.makeEnvFromProgram(Env.emptyCache(),p_1, Absyn.IDENT(""));
        env_1 = addVarsToEnv(vars, env);
      then
        (env_1,st);
  end match;
end buildEnvFromSymboltable;

protected function addVarsToEnv
"function: addVarsToEnv
  Helper function to buildEnvFromSymboltable."
  input list<Variable> inVariableLst;
  input Env.Env inEnv;
  output Env.Env outEnv;
algorithm
  outEnv:=
  matchcontinue (inVariableLst,inEnv)
    local
      list<Env.Frame> env_1,env_2,env;
      String id;
      Values.Value v;
      DAE.Type tp;
      list<Variable> rest;
    case ((IVAR(varIdent = id,value = v,type_ = tp) :: rest),env)
      equation
        (_,_,_,_,_,_,_,_,_) = Lookup.lookupVar(Env.emptyCache(),env, ComponentReference.makeCrefIdent(id,DAE.T_UNKNOWN_DEFAULT,{}));
        env_1 = Env.updateFrameV(env,
          DAE.TYPES_VAR(id,DAE.ATTR(SCode.NOT_FLOW(),SCode.NOT_STREAM(),SCode.NON_PARALLEL(),SCode.VAR(),Absyn.BIDIR(),Absyn.NOT_INNER_OUTER()),
          SCode.PUBLIC(),tp,DAE.VALBOUND(v,DAE.BINDING_FROM_DEFAULT_VALUE()),NONE()), Env.VAR_TYPED(), {});
        env_2 = addVarsToEnv(rest, env_1);
      then
        env_2;
    case ((IVAR(varIdent = id,value = v,type_ = tp) :: rest),env)
      equation
        failure((_,_,_,_,_,_,_,_,_) = Lookup.lookupVar(Env.emptyCache(),env, ComponentReference.makeCrefIdent(id,DAE.T_UNKNOWN_DEFAULT,{})));
        env_1 = Env.extendFrameV(env,
          DAE.TYPES_VAR(id,DAE.ATTR(SCode.NOT_FLOW(),SCode.NOT_STREAM(),SCode.NON_PARALLEL(),SCode.VAR(),Absyn.BIDIR(),Absyn.NOT_INNER_OUTER()),
          SCode.PUBLIC(),tp,DAE.VALBOUND(v,DAE.BINDING_FROM_DEFAULT_VALUE()),NONE()),NONE(), Env.VAR_UNTYPED(), {});
        env_2 = addVarsToEnv(rest, env_1);
      then
        env_2;
    case ({},env) then env;
  end matchcontinue;
end addVarsToEnv;

protected function matchApiFunction
  "Checks if the interactive statement list contains a function with the given name."
  input Statements inStmts;
  input String inFunctionName;
algorithm
  _ := match(inStmts, inFunctionName)
    local String fn;
    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ =
        Absyn.CREF_IDENT(name = fn)))}), _)
      equation
        true = stringEq(inFunctionName, fn);
      then
        ();
  end match;
end matchApiFunction;

protected function getApiFunctionArgs
  "Returns a list of arguments to the function in the interactive statement list."
  input Statements inStmts;
  output list<Absyn.Exp> outArgs;
algorithm
  outArgs := match(inStmts)
    local list<Absyn.Exp> args;
    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(functionArgs =
      Absyn.FUNCTIONARGS(args = args)))})) then args;
  end match;
end getApiFunctionArgs;

protected function getApiFunctionNamedArgs
  "Returns a list of named arguments to the function in the interactive statement list."
  input Statements inStmts;
  output list<Absyn.NamedArg> outArgs;
algorithm
  outArgs := match(inStmts)
    local list<Absyn.NamedArg> args;
    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(functionArgs =
      Absyn.FUNCTIONARGS(argNames = args)))})) then args;
  end match;
end getApiFunctionNamedArgs;

protected function evaluateGraphicalApi
"function: evaluateGraphicalApi
  Evaluating graphical api.
  NOTE: the graphical API is always evaluated with checkModel ON and +d=nogen,noevalfunc ON"
  input Statements inStatements;
  input SymbolTable inSymbolTable;
  input Boolean isPartialInst;
  output String outString;
  output SymbolTable outSymbolTable;
algorithm
  (outString,outSymbolTable) := matchcontinue (inStatements,inSymbolTable,isPartialInst)
    
    case (inStatements, inSymbolTable, isPartialInst)
      equation
        (outString,outSymbolTable) = evaluateGraphicalApi_dispatch(inStatements,inSymbolTable);
        // reset the flags!
        System.setPartialInstantiation(isPartialInst);
      then
        (outString,outSymbolTable);
    
    case (inStatements, inSymbolTable, isPartialInst)
      equation
        // reset the flags!
        System.setPartialInstantiation(isPartialInst);        
      then
        fail();
        
  end matchcontinue;
end evaluateGraphicalApi;

protected function evaluateGraphicalApi_dispatch
"function: evaluateGraphicalApi
  This function evaluates all primitives in the graphical api."
  input Statements inStatements;
  input SymbolTable inSymbolTable;
  output String outString;
  output SymbolTable outSymbolTable;
algorithm
  (outString,outSymbolTable) := matchcontinue (inStatements,inSymbolTable)
    local
      Absyn.Program p_1,p,newp,p1;
      list<Absyn.Class> aclasses;
      String resstr,name,top_names_str,str,cmt,s1,res_str,omhome,omlib,omcpath,os,platform,usercflags,senddata,res,workdir,gcc,confcmd,touch_file,uname,causality,parallelism,variability,filenameprefix,file_dir,method,reductionMethod;
      Absyn.ComponentRef class_,ident,subident,cr,tp,model_,cr1,cr2,c1,c2,old_cname,new_cname,cname,from_ident,to_ident,crident;
      Absyn.Exp exp;
      SymbolTable st,newst;
      list<SCode.Element> s,s_1;
      Absyn.Modification mod;
      Absyn.Path path_1,path,wpath;
      Integer count,n;
      list<Absyn.NamedArg> nargs;
      Boolean b1,b2,b,omcfound,gcc_res,touch_res,rm_res,uname_res,dref1,dref2,finalPrefix,flowPrefix,streamPrefix,repl,protected_,addFunctions;
      list<LoadedFile> lf;
      AbsynDep.Depends aDep;
      Statements istmts;
      Absyn.Path modelpath;
      list<String> vars,libs;
      list<Values.Value> vals;
      Absyn.Class cls,refactoredClass;
      list<DAE.Exp> simOptions;
      Absyn.ClassDef cdef;
      Env.Env env;
      list<Absyn.Exp> exp_list,exp_list2;
      Env.Cache cache;

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "setComponentModifierValue");
        {Absyn.CREF(componentRef = class_), 
         Absyn.CREF(componentRef = (ident as Absyn.CREF_IDENT(name = _))),
         Absyn.CODE(code = Absyn.C_MODIFICATION(modification = Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=exp))))} =
          getApiFunctionArgs(istmts);
        (p_1,resstr) = setParameterValue(class_, ident, exp, p) "expressions" ;
        st = setSymbolTableAST(st, p_1);
      then
        (resstr, st);

    //special case for clearing modifier simple name.
    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "setComponentModifierValue");
        {Absyn.CREF(componentRef = class_),
         Absyn.CREF(componentRef = (ident as Absyn.CREF_IDENT(name = _))),
         Absyn.CODE(code = Absyn.C_MODIFICATION(modification =
           (mod as Absyn.CLASSMOD(elementArgLst = {},eqMod = Absyn.NOMOD()))))} =
          getApiFunctionArgs(istmts);
        (p_1,resstr) = setComponentModifier(class_, ident, Absyn.CREF_IDENT("",{}),mod, p)  ;
        st = setSymbolTableAST(st, p_1);
      then
        (resstr, st);


    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "setComponentModifierValue");
        {Absyn.CREF(componentRef = class_),
         Absyn.CREF(componentRef = Absyn.CREF_QUAL(name = str,componentRef = subident)),
         Absyn.CODE(code = Absyn.C_MODIFICATION(modification = mod))} = getApiFunctionArgs(istmts);
        (p_1,resstr) = setComponentModifier(class_, Absyn.CREF_IDENT(str,{}), subident, mod, p);
        st = setSymbolTableAST(st, p_1);
      then
        (resstr, st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getParameterValue");
        {Absyn.CREF(componentRef = class_), Absyn.CREF(componentRef = ident)} = getApiFunctionArgs(istmts);
        resstr = getComponentBinding(class_, ident, p);
      then
        (resstr, st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "setParameterValue");
        {Absyn.CREF(componentRef = class_), Absyn.CREF(componentRef = ident),exp} = getApiFunctionArgs(istmts);
        (p_1,resstr) = setParameterValue(class_, ident, exp, p);
        st = setSymbolTableAST(st, p_1);
      then
        (resstr, st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getParameterNames");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        resstr = getParameterNames(cr, p);
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "createModel");
        {Absyn.CREF(componentRef = Absyn.CREF_IDENT(name = name))} =
          getApiFunctionArgs(istmts);
        newp = updateProgram(
          Absyn.PROGRAM({Absyn.CLASS(name,false,false,false,Absyn.R_MODEL(),
                         Absyn.PARTS({},{Absyn.PUBLIC({})},NONE()),Absyn.INFO("",false,0,0,0,0,Absyn.dummyTimeStamp))},
                         Absyn.TOP(),Absyn.dummyTimeStamp), p);
        newst = setSymbolTableAST(st, newp);
      then
        ("true",newst);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "createModel");
        {Absyn.CREF(componentRef = (cr as Absyn.CREF_QUAL(name = _)))} =
          getApiFunctionArgs(istmts);
        path_1 = Absyn.crefToPath(cr);
        name = Absyn.pathLastIdent(path_1);
        wpath = Absyn.stripLast(path_1);
        newp = updateProgram(
          Absyn.PROGRAM({
          Absyn.CLASS(name,false,false,false,Absyn.R_MODEL(),
                      Absyn.PARTS({},{Absyn.PUBLIC({})},NONE()),Absyn.INFO("",false,0,0,0,0,Absyn.dummyTimeStamp))},
                      Absyn.WITHIN(wpath),Absyn.dummyTimeStamp), p);
        newst = setSymbolTableAST(st, newp);
      then
        ("true",newst);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "newModel");
        {Absyn.CREF(componentRef = Absyn.CREF_IDENT(name = name)),
         Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        path_1 = Absyn.crefToPath(cr);
        newp = updateProgram(
          Absyn.PROGRAM({
          Absyn.CLASS(name,false,false,false,Absyn.R_MODEL(),
                      Absyn.PARTS({},{Absyn.PUBLIC({})},NONE()),Absyn.INFO("",false,0,0,0,0,Absyn.dummyTimeStamp))},
                      Absyn.WITHIN(path_1),Absyn.dummyTimeStamp), p);
        newst = setSymbolTableAST(st, newp);
        resstr = stringAppend(name, "\n");
      then
        ("true",newst);

    // Not moving this yet as it could break things...
    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "deleteClass");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        (resstr,newp) = deleteClass(cr, p);
        st = setSymbolTableAST(st, newp);
      then
        (resstr, st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "addComponent");
        {Absyn.CREF(componentRef = Absyn.CREF_IDENT(name = name)),
         Absyn.CREF(componentRef = tp),
         Absyn.CREF(componentRef = model_)} = getApiFunctionArgs(istmts);
        nargs = getApiFunctionNamedArgs(istmts);
        (newp,resstr) = addComponent(name, tp, model_, nargs, p);
        str = Print.getString();
        //resstr_1 = stringAppend(resstr, str);
        st = setSymbolTableAST(st, newp);
      then
        ("true", st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "updateComponent");
        {Absyn.CREF(componentRef = Absyn.CREF_IDENT(name = name)),
         Absyn.CREF(componentRef = tp),
         Absyn.CREF(componentRef = model_)} = getApiFunctionArgs(istmts);
        nargs = getApiFunctionNamedArgs(istmts);
        (newp,res) = updateComponent(name, tp, model_, nargs, p);
        st = setSymbolTableAST(st, newp);
      then
        (res, st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "deleteComponent");
        {Absyn.CREF(componentRef = Absyn.CREF_IDENT(name = name)),
         Absyn.CREF(componentRef = model_)} = getApiFunctionArgs(istmts);
        nargs = getApiFunctionNamedArgs(istmts);
        (newp,resstr) = deleteComponent(name, model_, p);
        str = Print.getString();
        //resstr_1 = stringAppend(resstr, str);
        st = setSymbolTableAST(st, newp);
      then
        ("true", st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "addClassAnnotation");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        nargs = getApiFunctionNamedArgs(istmts);
        newp = addClassAnnotation(cr, nargs, p);
        newst = setSymbolTableAST(st, newp);
      then
        ("true",newst);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getComponentCount");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        count = getComponentCount(cr, p);
        resstr = intString(count);
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getNthComponent");
        {Absyn.CREF(componentRef = cr),Absyn.INTEGER(value = n)} =
          getApiFunctionArgs(istmts);
        resstr = getNthComponent(cr, p, n);
      then
        (resstr,st);

    case (istmts, st)
      equation
        matchApiFunction(istmts, "getComponents");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        nargs = getApiFunctionNamedArgs(istmts);
        b1 = useQuotes(nargs);
        (resstr,st) = getComponents(cr, b1, st);
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getComponentAnnotations");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        ErrorExt.setCheckpoint("getComponentAnnotations");
        Config.setEvaluateParametersInAnnotations(true);
        resstr = getComponentAnnotations(cr, p);
        Config.setEvaluateParametersInAnnotations(false);
        ErrorExt.rollBack("getComponentAnnotations");
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getNthComponentAnnotation");
        {Absyn.CREF(componentRef = cr),Absyn.INTEGER(value = n)} = getApiFunctionArgs(istmts);
        ErrorExt.setCheckpoint("getNthComponentAnnotation");
        Config.setEvaluateParametersInAnnotations(true);
        resstr = getNthComponentAnnotation(cr, p, n);
        Config.setEvaluateParametersInAnnotations(false);
        ErrorExt.rollBack("getNthComponentAnnotation");
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getNthComponentModification");
        {Absyn.CREF(componentRef = cr),Absyn.INTEGER(value = n)} = getApiFunctionArgs(istmts);
        resstr = getNthComponentModification(cr, p, n);
      then
        (resstr,st);
        
    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getNthComponentCondition");
        {Absyn.CREF(componentRef = cr),Absyn.INTEGER(value = n)} = getApiFunctionArgs(istmts);
        resstr = getNthComponentCondition(cr, p, n);
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getInheritanceCount");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        count = getInheritanceCount(cr, p);
        resstr = intString(count);
      then
        (resstr,st);

    case (istmts, st)
      equation
        matchApiFunction(istmts, "getNthInheritedClass");
        {Absyn.CREF(componentRef = cr),Absyn.INTEGER(value = n)} = 
          getApiFunctionArgs(istmts);
        (resstr,st) = getNthInheritedClass(cr, n, st);
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getConnectionCount");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        resstr = getConnectionCount(cr, p);
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getNthConnection");
        {Absyn.CREF(componentRef = cr),Absyn.INTEGER(value = n)} = 
          getApiFunctionArgs(istmts);
        resstr = getNthConnection(cr, p, n);
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "setConnectionComment");
        {Absyn.CREF(componentRef = cr),
         Absyn.CREF(componentRef = cr1),
         Absyn.CREF(componentRef = cr2),
         Absyn.STRING(value = cmt)} = getApiFunctionArgs(istmts);
        (newp,resstr) = setConnectionComment(cr, cr1, cr2, cmt, p);
        st = setSymbolTableAST(st, newp);
      then
        (resstr, st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "addConnection");
        {Absyn.CREF(componentRef = c1),
         Absyn.CREF(componentRef = c2),
         Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        nargs = getApiFunctionNamedArgs(istmts);
        (resstr,newp) = addConnection(cr, c1, c2, nargs, p);
        st = setSymbolTableAST(st, newp);
      then
        (resstr, st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "deleteConnection");
        {Absyn.CREF(componentRef = c1),
         Absyn.CREF(componentRef = c2),
         Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        (resstr,newp) = deleteConnection(cr, c1, c2, p);
        st = setSymbolTableAST(st, newp);
      then
        (resstr, st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "updateConnection");
        {Absyn.CREF(componentRef = c1),
         Absyn.CREF(componentRef = c2),
         Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        nargs = getApiFunctionNamedArgs(istmts);
        (s1,newp) = deleteConnection(cr, c1, c2, p);
        (resstr,newp) = addConnection(cr, c1, c2, nargs, newp);
        st = setSymbolTableAST(st, newp);
      then
        (resstr, st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getNthConnectionAnnotation");
        {Absyn.CREF(componentRef = cr),Absyn.INTEGER(value = n)} = getApiFunctionArgs(istmts);
        ErrorExt.setCheckpoint("getNthConnectionAnnotation");
        modelpath = Absyn.crefToPath(cr);
        Config.setEvaluateParametersInAnnotations(true);
        resstr = getNthConnectionAnnotation(modelpath, p, n);
        Config.setEvaluateParametersInAnnotations(false);
        ErrorExt.rollBack("getNthConnectionAnnotation");
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getConnectorCount");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        resstr = getConnectorCount(cr, p);
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getNthConnector");
        {Absyn.CREF(componentRef = cr),Absyn.INTEGER(value = n)} = getApiFunctionArgs(istmts);
        modelpath = Absyn.crefToPath(cr);
        resstr = getNthConnector(modelpath, p, n);
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      
      equation
        matchApiFunction(istmts, "getNthConnectorIconAnnotation");
        {Absyn.CREF(componentRef = cr),Absyn.INTEGER(value = n)} = getApiFunctionArgs(istmts);
        ErrorExt.setCheckpoint("getNthConnectorIconAnnotation");
        modelpath = Absyn.crefToPath(cr);
        Config.setEvaluateParametersInAnnotations(true);
        resstr = getNthConnectorIconAnnotation(modelpath, p, n);
        Config.setEvaluateParametersInAnnotations(false);
        ErrorExt.rollBack("getNthConnectorIconAnnotation");
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getIconAnnotation");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        modelpath = Absyn.crefToPath(cr);
        ErrorExt.setCheckpoint("getIconAnnotation");
        Config.setEvaluateParametersInAnnotations(true);
        resstr = getIconAnnotation(modelpath, p);
        Config.setEvaluateParametersInAnnotations(false);
        ErrorExt.rollBack("getIconAnnotation");
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getDiagramAnnotation");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        modelpath = Absyn.crefToPath(cr);
        ErrorExt.setCheckpoint("getDiagramAnnotation");
        Config.setEvaluateParametersInAnnotations(true);
        resstr = getDiagramAnnotation(modelpath, p);
        Config.setEvaluateParametersInAnnotations(false);
        ErrorExt.rollBack("getDiagramAnnotation");
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getNthInheritedClassIconMapAnnotation");
        {Absyn.CREF(componentRef = cr),Absyn.INTEGER(value = n)} = getApiFunctionArgs(istmts);
        ErrorExt.setCheckpoint("getNthInheritedClassIconMapAnnotation");
        modelpath = Absyn.crefToPath(cr);
        Config.setEvaluateParametersInAnnotations(true);
        resstr = getNthInheritedClassMapAnnotation(modelpath, n, p, "IconMap");
        Config.setEvaluateParametersInAnnotations(false);
        ErrorExt.rollBack("getNthInheritedClassIconMapAnnotation");
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getNthInheritedClassDiagramMapAnnotation");
        {Absyn.CREF(componentRef = cr),Absyn.INTEGER(value = n)} = getApiFunctionArgs(istmts);
        ErrorExt.setCheckpoint("getNthInheritedClassDiagramMapAnnotation");
        modelpath = Absyn.crefToPath(cr);
        Config.setEvaluateParametersInAnnotations(true);
        resstr = getNthInheritedClassMapAnnotation(modelpath, n, p, "DiagramMap");
        Config.setEvaluateParametersInAnnotations(false);
        ErrorExt.rollBack("getNthInheritedClassDiagramMapAnnotation");
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getExperimentAnnotation");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        modelpath = Absyn.crefToPath(cr);
        ErrorExt.setCheckpoint("getExperimentAnnotation");
        resstr = getNamedAnnotation(modelpath, p, "experiment", SOME("{}"), getExperimentAnnotationString);
        ErrorExt.rollBack("getExperimentAnnotation");
      then
        (resstr,st);
        
    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getSimulationOptions");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        modelpath = Absyn.crefToPath(cr);
        ErrorExt.setCheckpoint("getSimulationOptions");
        // ignore the name of the model
        (_, _::simOptions) = Static.getSimulationArguments(Env.emptyCache(), {},{Absyn.CREF(cr)},{},false,SOME(st),Prefix.NOPRE(),Absyn.dummyInfo);
        resstr = 
          "{" +& 
          ExpressionDump.printExpListStr(simOptions) +& 
          "} /* startTime, stopTime, numberOfIntervals, tolerance, method, fileNamePrefix, storeInTemp, noClean, options, outputFormat */";
        ErrorExt.rollBack("getSimulationOptions");
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getNamedAnnotation");
        {Absyn.CREF(componentRef = cr), Absyn.CREF(componentRef = Absyn.CREF_IDENT(str, {}))} = 
        getApiFunctionArgs(istmts);
        modelpath = Absyn.crefToPath(cr);
        ErrorExt.setCheckpoint("getNamedAnnotation");
        Config.setEvaluateParametersInAnnotations(true);
        resstr = getNamedAnnotation(modelpath, p, str, SOME("{}"), getAnnotationValue);
        Config.setEvaluateParametersInAnnotations(false);
        ErrorExt.rollBack("getNamedAnnotation");
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "refactorClass");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        path = Absyn.crefToPath(cr);
        cls = getPathedClassInProgram(path, p);
        refactoredClass = Refactor.refactorGraphicalAnnotation(p, cls);
        p = updateProgram(Absyn.PROGRAM({refactoredClass}, Absyn.TOP(), Absyn.dummyTimeStamp), p);
         resstr = Dump.unparseStr(Absyn.PROGRAM({refactoredClass},Absyn.TOP(),Absyn.dummyTimeStamp),false);
        st = setSymbolTableAST(st, p);
      then
        (resstr, st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "refactorClass");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        s1 = Dump.printComponentRefStr(cr);
        resstr = stringAppendList({"Failed in translating", s1, " to Modelica v2.0 graphicall annotations"});
        st = setSymbolTableAST(st, p);
      then
        (resstr, st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "refactorIconAnnotation");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        path = Absyn.crefToPath(cr);
        cls = getPathedClassInProgram(path, p);

        refactoredClass = Refactor.refactorGraphicalAnnotation(p, cls);

        resstr = getAnnotationInClass(refactoredClass, ICON_ANNOTATION(), p, path);
        st = setSymbolTableAST(st, p);
      then
        (resstr, st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "refactorDiagramAnnotation");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        path = Absyn.crefToPath(cr);
        cls = getPathedClassInProgram(path, p);

        refactoredClass = Refactor.refactorGraphicalAnnotation(p, cls);

        resstr = getAnnotationInClass(refactoredClass, DIAGRAM_ANNOTATION(), p, path);
        st = setSymbolTableAST(st, p);
      then
        (resstr, st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getClassInformation");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        resstr = getClassInformation(cr, p);
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getClassInformation");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        failure(resstr = getClassInformation(cr, p));
      then
        ("error",st);
    
    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getClassRestriction");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        resstr = getClassRestriction(cr, p);
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "isPrimitive");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        b1 = isPrimitive(cr, p);
        resstr = boolString(b1);
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "isType");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        b1 = isType(cr, p);
        resstr = boolString(b1);
      then
        (resstr,st);

   case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "isConnector");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        b1 = isConnector(cr, p);
        resstr = boolString(b1);
      then
        (resstr,st);

   case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "isModel");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        path = Absyn.crefToPath(cr);
        b1 = isModel(path, p);
        resstr = boolString(b1);
      then
        (resstr,st);

   case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "isRecord");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        b1 = isRecord(cr, p);
        resstr = boolString(b1);
      then
        (resstr,st);

   case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "isBlock");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        b1 = isBlock(cr, p);
        resstr = boolString(b1);
      then
        (resstr,st);

   case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "isFunction");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        b1 = isFunction(cr, p);
        resstr = boolString(b1);
      then
        (resstr,st);

   case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "isClass");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        b1 = isClass(cr, p);
        resstr = boolString(b1);
      then
        (resstr,st);

   case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "isParameter");
        {Absyn.CREF(componentRef = cr), Absyn.CREF(componentRef = class_)} = 
          getApiFunctionArgs(istmts);
        b1 = isParameter(cr, class_, p);
        resstr = boolString(b1);
      then
        (resstr,st);

   case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "isProtected");
        {Absyn.CREF(componentRef = cr), Absyn.CREF(componentRef = class_)} = 
          getApiFunctionArgs(istmts);
        b1 = isProtected(cr, class_, p);
        resstr = boolString(b1);
      then
        (resstr,st);

   case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "isConstant");
        {Absyn.CREF(componentRef = cr), Absyn.CREF(componentRef = class_)} = 
          getApiFunctionArgs(istmts);
        b1 = isConstant(cr, class_, p);
        resstr = boolString(b1);
      then
        (resstr,st);
        
   case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "isEnumeration");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        path = Absyn.crefToPath(cr);
        cls = getPathedClassInProgram(path, p);
        b1 = isEnumeration(cls);
        resstr = boolString(b1);
      then
        (resstr,st);
        
   case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "isReplaceable");
        {Absyn.CREF(componentRef = class_), Absyn.STRING(value = name)} = getApiFunctionArgs(istmts);
        b1 = isReplaceable(class_, name, p);
        resstr = boolString(b1);
      then
        (resstr,st);
   
   case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getEnumerationLiterals");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        path = Absyn.crefToPath(cr);
        cls = getPathedClassInProgram(path, p);
        resstr = getEnumLiterals(cls);
      then
        (resstr,st);

   case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "existClass");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        b1 = existClass(cr, p);
        resstr = boolString(b1);
      then
        (resstr,st);

   case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "existModel");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        path = Absyn.crefToPath(cr);
        b1 = existClass(cr, p);
        b2 = isModel(path, p);
        b = boolAnd(b1, b2);
        resstr = boolString(b);
      then
        (resstr,st);

   case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "existPackage");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        b1 = existClass(cr, p);
        b2 = isPackage(Absyn.crefToPath(cr), p);
        b = boolAnd(b1, b2);
        resstr = boolString(b);
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p, depends = aDep, loadedFiles = lf))
      equation
        matchApiFunction(istmts, "renameClass");
        {Absyn.CREF(componentRef = old_cname), Absyn.CREF(componentRef = new_cname)} =
          getApiFunctionArgs(istmts);
        (res,p_1) = renameClass(p, old_cname, new_cname) "For now, renaming a class clears all caches... Substantial analysis required to find out what to keep in cache
     and what must be thrown out" ;
        s_1 = SCodeUtil.translateAbsyn2SCode(p_1);
      then
        (res,SYMBOLTABLE(p_1,aDep,SOME(s_1),{},{},{},lf));

    case (istmts, st as SYMBOLTABLE(ast = p, depends = aDep, loadedFiles = lf))
      equation
        matchApiFunction(istmts, "renameComponent");
        {Absyn.CREF(componentRef = cname),
         Absyn.CREF(componentRef = from_ident),
         Absyn.CREF(componentRef = to_ident)} = getApiFunctionArgs(istmts);
        (res_str,p_1) = renameComponent(p, cname, from_ident, to_ident);
      then
        (res_str,SYMBOLTABLE(p_1,aDep,NONE(),{},{},{},lf));

    case (istmts, st as SYMBOLTABLE(ast = p, depends = aDep, loadedFiles = lf))
      equation
        matchApiFunction(istmts, "renameComponentInClass");
        {Absyn.CREF(componentRef = cname),
         Absyn.CREF(componentRef = from_ident),
         Absyn.CREF(componentRef = to_ident)} = getApiFunctionArgs(istmts);
        (res_str,p_1) = renameComponentOnlyInClass(p, cname, from_ident, to_ident);
      then
        (res_str,SYMBOLTABLE(p_1,aDep,NONE(),{},{},{},lf));

    case (istmts, st as SYMBOLTABLE(ast = p)) /* adrpo added 2005-11-03 */
      equation
        matchApiFunction(istmts, "getCrefInfo");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        resstr = getCrefInfo(cr, p);
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p)) /* added by adrpo, 2006-02-24 */
      equation
        matchApiFunction(istmts, "getClassAttributes");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        resstr = getClassAttributes(cr, p);
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "setOption");
        {Absyn.CREF(componentRef = Absyn.CREF_IDENT(str, _)), Absyn.BOOL(value = b1)} =
          getApiFunctionArgs(istmts);
        str = "--" +& str;
        _ = Flags.readArgs({str});
      then
        ("true",st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "setExtendsModifierValue");
        {Absyn.CREF(componentRef = class_), 
         Absyn.CREF(componentRef = crident),
         Absyn.CREF(componentRef = subident), 
         Absyn.CODE(code = Absyn.C_MODIFICATION(modification = mod))} = 
           getApiFunctionArgs(istmts);
        (newp,resstr) = setExtendsModifierValue(class_, crident, subident, mod, p);
        st = setSymbolTableAST(st, newp);
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getExtendsModifierNames");
        {Absyn.CREF(componentRef = class_), Absyn.CREF(componentRef = cr)} = 
          getApiFunctionArgs(istmts);
        resstr = getExtendsModifierNames(class_, cr, p);
      then
        (resstr, st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getExtendsModifierValue");
        {Absyn.CREF(componentRef = class_),
         Absyn.CREF(componentRef = crident),
         Absyn.CREF(componentRef = subident)} = getApiFunctionArgs(istmts);
        resstr = getExtendsModifierValue(class_, crident, subident, p);
      then
        (resstr, st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getComponentModifierNames");
        {Absyn.CREF(componentRef = class_), Absyn.CREF(componentRef = cr)} =
          getApiFunctionArgs(istmts);
        resstr = getComponentModifierNames(class_, cr, p);
      then
        (resstr, st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getDefaultComponentName");
        {Absyn.CREF(componentRef = class_)} = getApiFunctionArgs(istmts);
        resstr = getDefaultComponentName(Absyn.crefToPath(class_), p);
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getDefaultComponentPrefixes");
        {Absyn.CREF(componentRef = class_)} = getApiFunctionArgs(istmts);
        resstr = getDefaultComponentPrefixes(Absyn.crefToPath(class_), p);
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getComponentModifierValue");
        {Absyn.CREF(componentRef = class_),
         Absyn.CREF(componentRef = Absyn.CREF_QUAL(name = name, componentRef = subident))} = 
          getApiFunctionArgs(istmts);
        resstr = getComponentModifierValue(class_, Absyn.CREF_IDENT(name,{}), subident, p);
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getComponentModifierValue");
        {Absyn.CREF(componentRef = class_),
         Absyn.CREF(componentRef = Absyn.CREF_IDENT(name = name))} =
          getApiFunctionArgs(istmts);
        resstr = getComponentBinding(class_, Absyn.CREF_IDENT(name,{}), p);
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getComponentComment");
        {Absyn.CREF(componentRef = class_),Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        resstr = getComponentComment(class_, cr, p);
        resstr = stringAppendList({"\"", resstr, "\""});
      then
        (resstr,st);
    
    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "setComponentComment");
        {Absyn.CREF(componentRef = class_), 
         Absyn.CREF(componentRef = cr), 
         Absyn.STRING(value = cmt)} =
          getApiFunctionArgs(istmts);
        (resstr,newp) = setComponentComment(class_, cr, cmt, p);
        st = setSymbolTableAST(st, newp);
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "setComponentProperties");
        {Absyn.CREF(componentRef = class_),
         Absyn.CREF(componentRef = cr),Absyn.ARRAY(arrayExp =
         {Absyn.BOOL(value = finalPrefix),
          Absyn.BOOL(value = flowPrefix),
          Absyn.BOOL(value = streamPrefix),
          Absyn.BOOL(value = protected_),
          Absyn.BOOL(value = repl)}),
          // Absyn.ARRAY(arrayExp = {Absyn.STRING(value = parallelism)}),
          Absyn.ARRAY(arrayExp = {Absyn.STRING(value = variability)}),
          Absyn.ARRAY(arrayExp = {Absyn.BOOL(value = dref1),Absyn.BOOL(value = dref2)}),
          Absyn.ARRAY(arrayExp = {Absyn.STRING(value = causality)})} =
          getApiFunctionArgs(istmts);
        (resstr,p_1) = setComponentProperties(Absyn.crefToPath(class_), cr, finalPrefix, flowPrefix, streamPrefix, protected_, repl, /*parallelism,*/ variability, {dref1,dref2}, causality, p);
        st = setSymbolTableAST(st, p_1);
      then
        (resstr,st);

    /* old version of setComponentProperties, without stream */
    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "setComponentProperties");
        {Absyn.CREF(componentRef = class_),
         Absyn.CREF(componentRef = cr),
         Absyn.ARRAY(arrayExp = {
           Absyn.BOOL(value = finalPrefix),
           Absyn.BOOL(value = flowPrefix),
           Absyn.BOOL(value = protected_),
           Absyn.BOOL(value = repl)}),
         // Absyn.ARRAY(arrayExp = {Absyn.STRING(value = parallelism)}),
         Absyn.ARRAY(arrayExp = {Absyn.STRING(value = variability)}),
         Absyn.ARRAY(arrayExp = {Absyn.BOOL(value = dref1),Absyn.BOOL(value = dref2)}),
         Absyn.ARRAY(arrayExp = {Absyn.STRING(value = causality)})} =
          getApiFunctionArgs(istmts);
        (resstr,p_1) = setComponentProperties(Absyn.crefToPath(class_), cr, finalPrefix, flowPrefix, false, protected_, repl, /*parallelism,*/ variability, {dref1,dref2}, causality, p);
        st = setSymbolTableAST(st, p_1);
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getElementsInfo");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        resstr = getElementsInfo(cr, p);
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getElementsOfVisType");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        (_,resstr) = getElementsOfVisType(Absyn.crefToPath(cr), p);
      then
        (resstr,st);

    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getDefinitions");
        {Absyn.BOOL(addFunctions)} = getApiFunctionArgs(istmts);
        (top_names_str) = getDefinitions(p, addFunctions);
      then
        (top_names_str, st);
        
    case (istmts, st as SYMBOLTABLE(ast = p))
      equation
        matchApiFunction(istmts, "getLocalVariables");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);
        nargs = getApiFunctionNamedArgs(istmts);
        b1 = useQuotes(nargs);
        path = Absyn.crefToPath(cr);
        cls = getPathedClassInProgram(path, p);
        (env,st) = buildEnvFromSymboltable(st);
        resstr = getLocalVariables(cls, b1, env);
      then
        (resstr,st);

    /* adrpo added 2006-10-16
     * - i think this function is needed here!
     */
    case (istmts, st)
      equation
        matchApiFunction(istmts, "getErrorString");
        {} = getApiFunctionArgs(istmts);
        resstr = Error.printMessagesStr();
        resstr = stringAppendList({"\"", resstr, "\""});
      then
        (resstr,st);
        
    //builds model and writes results to buffer
    case (istmts, st)
      equation
        matchApiFunction(istmts, "writeToBuffer");
        {Absyn.CREF(componentRef = cr)} = getApiFunctionArgs(istmts);      
        _=Flags.enableDebug(Flags.WRITE_TO_BUFFER); 
        (cache,simOptions) = Static.getSimulationArguments(Env.emptyCache(),{},{Absyn.CREF(cr)},{},false,SOME(st),Prefix.NOPRE(),Absyn.dummyInfo); 
        (_,_,_) = Ceval.ceval(cache,{},DAE.CALL(Absyn.IDENT("buildModel"),simOptions,DAE.callAttrBuiltinOther),true,SOME(st),Ceval.NO_MSG());        
      then
        ("true",st); 
      
     //starts label DAE algorithm        
    case (istmts, st)
      equation
        matchApiFunction(istmts, "generateLabeledSimCode");
        {Absyn.CREF(componentRef = cr),Absyn.STRING(value = reductionMethod), Absyn.ARRAY(arrayExp = exp_list)} = getApiFunctionArgs(istmts);      
        Flags.setConfigBool(Flags.GENERATE_LABELED_SIMCODE,true);
        Flags.setConfigString(Flags.REDUCTION_METHOD,reductionMethod); 
        /*(cache,simOptions) = Static.getSimulationArguments(Env.emptyCache(),{},{Absyn.CREF(cr)},{},false,SOME(st),Prefix.NOPRE(),Absyn.dummyInfo); 
        (_,_,_) = Ceval.ceval(cache,{},DAE.CALL(Absyn.IDENT("buildModel"),simOptions,DAE.callAttrBuiltinOther),true,SOME(st),Ceval.NO_MSG()); */
        modelpath = Absyn.crefToPath(cr);
        filenameprefix = Absyn.pathLastIdent(modelpath);
        (env,st) = buildEnvFromSymboltable(st);  
        (_,{_,_,_,_,_,DAE.SCONST(method),_,_,_,_,_,_,_,_}) = Static.getSimulationArguments(Env.emptyCache(),{},{Absyn.CREF(cr)},{},false,SOME(st),Prefix.NOPRE(),Absyn.dummyInfo); 
        (_,_,_,_,libs,file_dir,_) = SimCode.translateModel(Env.emptyCache(),env,modelpath,st,filenameprefix,true,NONE(),
        Absyn.FUNCTIONARGS({Absyn.CREF(cr), Absyn.ARRAY(exp_list)},{}));
        CevalScript.compileModel(filenameprefix,libs, file_dir,"",method);        
      then
        ("true",st);
    case (istmts, st)
      equation
        matchApiFunction(istmts, "generateLabeledSimCode");        
      then
        ("No such reduction method!",st);        
     //starts remove terms from DAE algorithm        
    case (istmts, st as SYMBOLTABLE(ast = p))
      equation         
        matchApiFunction(istmts, "reduceTerms");
        {Absyn.CREF(componentRef = cr), Absyn.ARRAY(arrayExp = exp_list),Absyn.ARRAY(arrayExp = exp_list2)} = getApiFunctionArgs(istmts);
        modelpath = Absyn.crefToPath(cr);
        filenameprefix = Absyn.pathLastIdent(modelpath);
        (env,st) = buildEnvFromSymboltable(st);
        Flags.setConfigBool(Flags.REDUCE_TERMS,true);
        Flags.setConfigBool(Flags.GENERATE_LABELED_SIMCODE,false);
        _=Flags.disableDebug(Flags.WRITE_TO_BUFFER); 
        (_,{_,_,_,_,_,DAE.SCONST(method),_,_,_,_,_,_,_,_}) = Static.getSimulationArguments(Env.emptyCache(),{},{Absyn.CREF(cr)},{},false,SOME(st),Prefix.NOPRE(),Absyn.dummyInfo); 
        (_,_,_,_,libs,file_dir,_) = SimCode.translateModel(Env.emptyCache(),env,modelpath,st,filenameprefix,true,NONE(),
        Absyn.FUNCTIONARGS({Absyn.CREF(cr), Absyn.ARRAY(exp_list),Absyn.ARRAY(exp_list2)},{}));
        CevalScript.compileModel(filenameprefix,libs, file_dir,"",method);   
      then
        ("true",st); 
   
  end matchcontinue;
end evaluateGraphicalApi_dispatch;

protected function listClass
"Unparse a class definition and return it in a String"
  input Absyn.ComponentRef cr "Class name as a ComponentRef";
  input Absyn.Program p "AST - Program";
  output String classStr "Class defintition";
protected
  Absyn.Path path;
  Absyn.Class cl;
algorithm
   path := Absyn.crefToPath(cr);
   cl := getPathedClassInProgram(path, p);
   classStr := Dump.unparseStr(Absyn.PROGRAM({cl},Absyn.TOP(),Absyn.dummyTimeStamp),false);
end listClass;

protected function extractAllComponentreplacements
"function extractAllComponentreplacements
  author: x02lucpo
  extracts all the componentreplacementrules from program.
  This is done by extracting all the components and then
  extracting the rules"
  input Absyn.Program p;
  input Absyn.ComponentRef class_;
  input Absyn.ComponentRef cref1;
  input Absyn.ComponentRef cref2;
  output ComponentReplacementRules comp_reps;
algorithm
  comp_reps := matchcontinue(p,class_,cref1,cref2)
    local
      Components comps;
      Absyn.Path class_path;
      ComponentReplacementRules comp_repsrules;
    
    case(p,class_,cref1,cref2)
      equation
        ErrorExt.setCheckpoint("Interactive.extractAllComponentreplacements");
        comps = extractAllComponents(p, Absyn.crefToPath(class_)) "class in package" ;
        // rollback errors if we succeed
        ErrorExt.rollBack("Interactive.extractAllComponentreplacements");
        false = isClassReadOnly(getPathedClassInProgram(Absyn.crefToPath(class_),p));
        class_path = Absyn.crefToPath(class_);
        comp_repsrules = COMPONENTREPLACEMENTRULES({COMPONENTREPLACEMENT(class_path,cref1,cref2)},1);
        comp_reps = getComponentreplacementsrules(comps, comp_repsrules, 0);
      then comp_reps;
    
    case(p,class_,cref1,cref2)
      equation
        // keep errors if we fail!
        ErrorExt.delCheckpoint("Interactive.extractAllComponentreplacements");
      then
        fail();        
  end matchcontinue;
end extractAllComponentreplacements;

protected function isClassReadOnly
"Returns the readonly attribute of a class."
input Absyn.Class cl;
output Boolean readOnly;
algorithm
  readOnly := match(cl)
    case(Absyn.CLASS(info = Absyn.INFO(isReadOnly=readOnly))) then readOnly;
  end match;
end isClassReadOnly;

protected function renameComponent
"function: renameComponent
  author: x02lucpo
  This function renames a component in a class
  inputs:  (Absyn.Program,
              Absyn.ComponentRef, /* old class as qualified name */
              Absyn.ComponentRef) /* new class, as identifier */
  outputs:  Absyn.Program"
  input Absyn.Program inProgram1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input Absyn.ComponentRef inComponentRef4;
  output String outString;
  output Absyn.Program outProgram;
algorithm
  (outString,outProgram) := matchcontinue (inProgram1,inComponentRef2,inComponentRef3,inComponentRef4)
    local
      Absyn.Path class_path;
      ComponentReplacementRules comp_reps;
      Absyn.Program p_1,p;
      list<String> paths;
      String paths_1,paths_2;
      Absyn.ComponentRef class_,old_comp,new_comp;
      Absyn.Path model_path;
      String str;
      
    case (p,class_,old_comp,new_comp)
      equation
        model_path = Absyn.crefToPath(class_);
        true = isClassReadOnly(getPathedClassInProgram(model_path,p));
        str = Absyn.pathString(model_path);
        str = "Error: class: " +& str +& " is in a read only file!";
      then
        (str, p);
            
    case (p,class_,old_comp,new_comp)
      equation
        class_path = Absyn.crefToPath(class_) "class in package" ;
        comp_reps = extractAllComponentreplacements(p, class_, old_comp, new_comp);
        p_1 = renameComponentFromComponentreplacements(p, comp_reps);
        paths = extractRenamedClassesAsStringList(comp_reps);
        paths_1 = stringDelimitList(paths, ",");
        paths_2 = stringAppendList({"{",paths_1,"}"});
      then
        (paths_2,p_1);
    
    case (p,_,_,_)
      equation
        Debug.fprint(Flags.FAILTRACE, "rename_component failed\n");
      then
        ("Error",p);
  end matchcontinue;
end renameComponent;

protected function renameComponentOnlyInClass
"@author: adrpo
  This function renames a component ONLY in the given class"
  input Absyn.Program inProgram1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input Absyn.ComponentRef inComponentRef4;
  output String outString;
  output Absyn.Program outProgram;
algorithm
  (outString,outProgram) := matchcontinue (inProgram1,inComponentRef2,inComponentRef3,inComponentRef4)
    local
      Absyn.Program p;
      String paths_2;
      Absyn.ComponentRef class_,old_comp,new_comp;
      Absyn.Class cl;
      Absyn.Path model_path;
      String str;
      Absyn.Within w;
      
    case (p,class_,old_comp,new_comp)
      equation
        model_path = Absyn.crefToPath(class_);
        true = isClassReadOnly(getPathedClassInProgram(model_path,p));
        str = Absyn.pathString(model_path);
        str = "Error: class: " +& str +& " is in a read only file!";
      then
        (str, p);
            
    case (p,class_,old_comp,new_comp)
      equation
        model_path = Absyn.crefToPath(class_) "class in package" ;
        cl = getPathedClassInProgram(model_path, p);
        cl = renameComponentInClass(cl, old_comp, new_comp);
        w = buildWithin(Absyn.FULLYQUALIFIED(model_path));
        p = updateProgram(Absyn.PROGRAM({cl}, w, Absyn.dummyTimeStamp), p);
        str = Absyn.pathString(model_path);
        paths_2 = stringAppendList({"{",str,"}"});
      then
        (paths_2,p);
    
    case (p,_,_,_)
      equation
        Debug.fprint(Flags.FAILTRACE, "renameComponentOnlyInClass failed\n");
      then
        ("Error",p);
  end matchcontinue;
end renameComponentOnlyInClass;

protected function extractRenamedClassesAsStringList
"function extractRenamedClassesAsStringList
  author: x02lucpo
  this iterates through the Componentreplacementrules and
  returns the string list with all the changed classes"
  input ComponentReplacementRules inComponentReplacementRules;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inComponentReplacementRules)
    local
      ComponentReplacementRules comp_reps,res;
      Absyn.Path path;
      String path_str;
      list<String> res_1,res_2;
    case (comp_reps)
      equation
        true = emptyComponentReplacementRules(comp_reps);
      then
        {};
    case (comp_reps)
      equation
        COMPONENTREPLACEMENT(path,_,_) = firstComponentReplacement(comp_reps);
        path_str = Absyn.pathString(path);
        res = restComponentReplacementRules(comp_reps);
        res_1 = extractRenamedClassesAsStringList(res);
        res_2 = List.union({path_str}, res_1);
      then
        res_2;
    case (_)
      equation
        print("-extract_renamed_classes_as_string_list failed\n");
      then
        fail();
  end matchcontinue;
end extractRenamedClassesAsStringList;

protected function renameComponentFromComponentreplacements
"function renameComponentFromComponentreplacements
  author: x02lucpo
  this iterates through the Componentreplacementrules and
  renames the componentes by traversing all the classes"
  input Absyn.Program inProgram;
  input ComponentReplacementRules inComponentReplacementRules;
  output Absyn.Program outProgram;
algorithm
  outProgram:=
  matchcontinue (inProgram,inComponentReplacementRules)
    local
      Absyn.Program p,p_1,p_2;
      ComponentReplacementRules comp_reps,res;
      ComponentReplacement comp_rep;
    case (p,comp_reps)
      equation
        true = emptyComponentReplacementRules(comp_reps);
      then
        p;
    case (p,comp_reps)
      equation
        comp_rep = firstComponentReplacement(comp_reps);
        ((p_1,_,_)) = traverseClasses(p,NONE(), renameComponentVisitor, comp_rep, true) "traverse protected" ;
        res = restComponentReplacementRules(comp_reps);
        p_2 = renameComponentFromComponentreplacements(p_1, res);
      then
        p_2;
    case (_,_)
      equation
        print("-rename_component_from_componentreplacements failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentFromComponentreplacements;

protected function renameComponentVisitor
"function renameComponentVisitor
  author: x02lucpo
  this is a visitor for traverse class in rename components"
  input tuple<Absyn.Class, Option<Absyn.Path>, ComponentReplacement> inTplAbsynClassAbsynPathOptionComponentReplacement;
  output tuple<Absyn.Class, Option<Absyn.Path>, ComponentReplacement> outTplAbsynClassAbsynPathOptionComponentReplacement;
algorithm
  outTplAbsynClassAbsynPathOptionComponentReplacement:=
  matchcontinue (inTplAbsynClassAbsynPathOptionComponentReplacement)
    local
      Absyn.Path path_1,pa,class_id;
      Absyn.Class class_1,class_;
      String id;
      Boolean a,b,c;
      Absyn.Restriction d;
      Absyn.ClassDef e;
      Absyn.Info file_info;
      Absyn.ComponentRef old_comp,new_comp;
      ComponentReplacement args;
      Option<Absyn.Path> opath;
    case (((class_ as Absyn.CLASS(name = id,partialPrefix = a,finalPrefix = b,encapsulatedPrefix = c,restriction = d,body = e,info = file_info)),SOME(pa),COMPONENTREPLACEMENT(which1 = class_id,the2 = old_comp,the3 = new_comp)))
      equation
        path_1 = Absyn.joinPaths(pa, Absyn.IDENT(id));
        true = Absyn.pathEqual(class_id, path_1);
        class_1 = renameComponentInClass(class_, old_comp, new_comp);
      then
        ((class_1,SOME(pa),
          COMPONENTREPLACEMENT(class_id,old_comp,new_comp)));
    case (((class_ as Absyn.CLASS(name = id,partialPrefix = a,finalPrefix = b,encapsulatedPrefix = c,restriction = d,body = e,info = file_info)),NONE(),COMPONENTREPLACEMENT(which1 = class_id,the2 = old_comp,the3 = new_comp)))
      equation
        path_1 = Absyn.IDENT(id);
        true = Absyn.pathEqual(class_id, path_1);
        class_1 = renameComponentInClass(class_, old_comp, new_comp);
      then
        ((class_1,NONE(),
          COMPONENTREPLACEMENT(class_id,old_comp,new_comp)));
    case ((class_,opath,args)) then ((class_,opath,args));
  end matchcontinue;
end renameComponentVisitor;

protected function renameComponentInClass
"author: x02lucpo
  helper function to renameComponentVisitor"
  input Absyn.Class inClass1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.Class outClass;
algorithm
  outClass:=
  matchcontinue (inClass1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.ClassPart> parts_1,parts;
      String name,baseClassName;
      Boolean partialPrefix,finalPrefix,encapsulatedPrefix;
      Absyn.Restriction restriction;
      Option<String> a,c;
      Absyn.Info file_info;
      Absyn.ComponentRef old_comp,new_comp;
      list<Absyn.ElementArg> b;
      Absyn.Class class_;
      list<String> typeVars;

    /* the class with the component the old name for the component */
    case (Absyn.CLASS(name = name,partialPrefix = partialPrefix,finalPrefix = finalPrefix,encapsulatedPrefix = encapsulatedPrefix,restriction = restriction,
          body = Absyn.PARTS(typeVars = typeVars,classParts = parts,comment = a),info = file_info),old_comp,new_comp)
      equation
        parts_1 = renameComponentInParts(parts, old_comp, new_comp);
      then
        Absyn.CLASS(name,partialPrefix,finalPrefix,encapsulatedPrefix,restriction,Absyn.PARTS(typeVars,parts_1,a),file_info);

    /* the class with the component the old name for the component for model extends X end X; */
    case (Absyn.CLASS(name = name,partialPrefix = partialPrefix,finalPrefix = finalPrefix,encapsulatedPrefix = encapsulatedPrefix,restriction = restriction,
                      body = Absyn.CLASS_EXTENDS(baseClassName = baseClassName,modifications = b,comment = c,parts = parts),
                      info = file_info),old_comp,new_comp)
      equation
        parts_1 = renameComponentInParts(parts, old_comp, new_comp);
      then
        Absyn.CLASS(name,partialPrefix,finalPrefix,encapsulatedPrefix,restriction, Absyn.CLASS_EXTENDS(baseClassName,b,c,parts_1),file_info);

    case (class_,old_comp,new_comp) then class_;
  end matchcontinue;
end renameComponentInClass;

protected function renameComponentInParts
"author: x02lucpo
  helper function to renameComponentVisitor"
  input list<Absyn.ClassPart> inAbsynClassPartLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.ClassPart> res_1,res;
      list<Absyn.ElementItem> elements_1,elements;
      Absyn.ComponentRef old_comp,new_comp;
      list<Absyn.EquationItem> equations_1,equations;
      list<Absyn.AlgorithmItem> algorithms_1,algorithms;
      Absyn.ExternalDecl external_decl_1,external_decl;
      Option<Absyn.Annotation> ano;
      Absyn.ClassPart a;
    case ({},_,_) then {};  /* the old name for the component */
    case ((Absyn.PUBLIC(contents = elements) :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInParts(res, old_comp, new_comp);
        elements_1 = renameComponentInElements(elements, old_comp, new_comp);
      then
        (Absyn.PUBLIC(elements_1) :: res_1);
    case ((Absyn.PROTECTED(contents = elements) :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInParts(res, old_comp, new_comp);
        elements_1 = renameComponentInElements(elements, old_comp, new_comp);
      then
        (Absyn.PROTECTED(elements_1) :: res_1);
    case ((Absyn.EQUATIONS(contents = equations) :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInParts(res, old_comp, new_comp);
        equations_1 = renameComponentInEquationList(equations, old_comp, new_comp);
      then
        (Absyn.EQUATIONS(equations_1) :: res_1);
    case ((Absyn.INITIALEQUATIONS(contents = equations) :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInParts(res, old_comp, new_comp);
        equations_1 = renameComponentInEquationList(equations, old_comp, new_comp);
      then
        (Absyn.INITIALEQUATIONS(equations_1) :: res_1);
    case ((Absyn.ALGORITHMS(contents = algorithms) :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInParts(res, old_comp, new_comp);
        algorithms_1 = renameComponentInAlgorithms(algorithms, old_comp, new_comp);
      then
        (Absyn.ALGORITHMS(algorithms_1) :: res_1);
    case ((Absyn.INITIALALGORITHMS(contents = algorithms) :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInParts(res, old_comp, new_comp);
        algorithms_1 = renameComponentInAlgorithms(algorithms, old_comp, new_comp);
      then
        (Absyn.INITIALALGORITHMS(algorithms_1) :: res_1);
    case ((Absyn.EXTERNAL(externalDecl = external_decl,annotation_ = ano) :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInParts(res, old_comp, new_comp);
        external_decl_1 = renameComponentInExternalDecl(external_decl, old_comp, new_comp);
      then
        (Absyn.EXTERNAL(external_decl_1,ano) :: res_1);
    case ((a :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInParts(res, old_comp, new_comp);
      then
        (a :: res_1);
  end matchcontinue;
end renameComponentInParts;

protected function renameComponentInElements
"author: x02lucpo
  helper function to renameComponentVisitor"
  input list<Absyn.ElementItem> inAbsynElementItemLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm
  outAbsynElementItemLst := matchcontinue (inAbsynElementItemLst1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.ElementItem> res_1,res;
      Absyn.ElementSpec elementspec_1,elementspec;
      Absyn.ElementItem element_1,element;
      Boolean finalPrefix;
      Option<Absyn.RedeclareKeywords> redeclare_;
      Absyn.InnerOuter inner_outer;
      String name;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constrainClass;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};  /* the old name for the component */
    case (((element as Absyn.ELEMENTITEM(element =
      Absyn.ELEMENT(finalPrefix = finalPrefix,redeclareKeywords = redeclare_,innerOuter = inner_outer,name = name,
                    specification = elementspec,info = info,constrainClass = constrainClass))) :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInElements(res, old_comp, new_comp);
        elementspec_1 = renameComponentInElementSpec(elementspec, old_comp, new_comp);
        element_1 = Absyn.ELEMENTITEM(
          Absyn.ELEMENT(finalPrefix,redeclare_,inner_outer,name,elementspec_1,info,
          constrainClass));
      then
        (element_1 :: res_1);
    case ((element :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInElements(res, old_comp, new_comp);
        element_1 = element;
      then
        (element_1 :: res_1);
  end matchcontinue;
end renameComponentInElements;

protected function renameComponentInElementSpec
"author: x02lucpo
  helper function to renameComponentVisitor"
  input Absyn.ElementSpec inElementSpec1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.ElementSpec outElementSpec;
algorithm
  outElementSpec := matchcontinue (inElementSpec1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.ComponentItem> comps_1,comps;
      Absyn.ElementAttributes attr;
      Absyn.TypeSpec path;
      Absyn.ComponentRef old_comp,new_comp;
      Absyn.ElementSpec elementspec;
    case (Absyn.COMPONENTS(attributes = attr,typeSpec = path,components = comps),old_comp,new_comp) /* the old name for the component */
      equation
        comps_1 = renameComponentInComponentitems(comps, old_comp, new_comp);
      then
        Absyn.COMPONENTS(attr,path,comps_1);
    case (elementspec,old_comp,new_comp) then elementspec;
  end matchcontinue;
end renameComponentInElementSpec;

protected function renameComponentInComponentitems
"author: x02lucpo
  helper function to renameComponentVisitor"
  input list<Absyn.ComponentItem> inAbsynComponentItemLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.ComponentItem> outAbsynComponentItemLst;
algorithm
  outAbsynComponentItemLst := matchcontinue (inAbsynComponentItemLst1,inComponentRef2,inComponentRef3)
    local
      Absyn.Path old_comp_path,new_comp_path;
      String old_comp_string,new_comp_string,name;
      list<Absyn.ComponentItem> res_1,res;
      Absyn.ComponentItem comp_1,comp;
      list<Absyn.Subscript> arrayDim;
      Option<Absyn.Modification> mod;
      Option<Absyn.Exp> cond;
      Option<Absyn.Comment> comment;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};  /* the old name for the component */
    case (((comp as Absyn.COMPONENTITEM(component =
      Absyn.COMPONENT(name = name,arrayDim = arrayDim,modification = mod),condition = cond,comment = comment)) :: res),old_comp,new_comp)
      equation
        old_comp_path = Absyn.crefToPath(old_comp);
        old_comp_string = Absyn.pathString(old_comp_path);
        true = stringEq(name, old_comp_string);
        new_comp_path = Absyn.crefToPath(new_comp);
        new_comp_string = Absyn.pathString(new_comp_path);
        res_1 = renameComponentInComponentitems(res, old_comp, new_comp);
        comp_1 = Absyn.COMPONENTITEM(Absyn.COMPONENT(new_comp_string,arrayDim,mod),cond,comment);
      then
        (comp_1 :: res_1);
    case (((comp as Absyn.COMPONENTITEM(component =
      Absyn.COMPONENT(name = name,arrayDim = arrayDim,modification = mod),condition = cond,comment = comment)) :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInComponentitems(res, old_comp, new_comp);
      then
        (comp :: res_1);
    case (_,_,_)
      equation
        print("-Interactive.renameComponentInComponentitems failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInComponentitems;

protected function renameComponentInEquationList
"author: x02lucpo
  helper function to renameComponentVisitor"
  input list<Absyn.EquationItem> inAbsynEquationItemLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.EquationItem> outAbsynEquationItemLst;
algorithm
  outAbsynEquationItemLst := matchcontinue (inAbsynEquationItemLst1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.EquationItem> res_1,res;
      Absyn.Equation equation_1,equation_;
      Option<Absyn.Comment> cmt;
      Absyn.Info info;
      Absyn.ComponentRef old_comp,new_comp;
      Absyn.EquationItem equation_item;
    case ({},_,_) then {};  /* the old name for the component */
    case ((Absyn.EQUATIONITEM(equation_ = equation_,comment = cmt,info=info) :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInEquationList(res, old_comp, new_comp);
        equation_1 = renameComponentInEquation(equation_, old_comp, new_comp);
      then
        (Absyn.EQUATIONITEM(equation_1,cmt,info) :: res_1);
    case ((equation_item :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInEquationList(res, old_comp, new_comp);
      then
        (equation_item :: res_1);
  end matchcontinue;
end renameComponentInEquationList;

protected function renameComponentInExpEquationitemList
"author: x02lucpo
  helper function to renameComponentVisitor"
  input list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> inTplAbsynExpAbsynEquationItemLstLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> outTplAbsynExpAbsynEquationItemLstLst;
algorithm
  outTplAbsynExpAbsynEquationItemLstLst := matchcontinue (inTplAbsynExpAbsynEquationItemLstLst1,inComponentRef2,inComponentRef3)
    local
      Absyn.Exp exp1_1,exp1;
      list<Absyn.EquationItem> eqn_item_1,eqn_item;
      list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> res_1,res;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};
    case (((exp1,eqn_item) :: res),old_comp,new_comp)
      equation
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        eqn_item_1 = renameComponentInEquationList(eqn_item, old_comp, new_comp);
        res_1 = renameComponentInExpEquationitemList(res, old_comp, new_comp);
      then
        ((exp1_1,eqn_item_1) :: res_1);
    case (_,_,_)
      equation
        print("-rename_component_in_exp_equationitem_list failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInExpEquationitemList;

protected function renameComponentInEquation
"author: x02lucpo
  helper function to renameComponentVisitor"
  input Absyn.Equation inEquation1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.Equation outEquation;
algorithm
  outEquation := matchcontinue (inEquation1,inComponentRef2,inComponentRef3)
    local
      Absyn.Exp exp_1,exp,exp1_1,exp2_1,exp1,exp2;
      list<Absyn.EquationItem> true_items_1,elses_1,true_items,elses,equations_1,equations;
      list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> exp_elseifs_1,exp_elseifs,exp_equations_1,exp_equations;
      Absyn.ComponentRef old_comp,new_comp,cref1_1,cref2_1,cref1,cref2,cref;
      String ident;
      Absyn.FunctionArgs function_args;
    /* the old name for the component */
    case (Absyn.EQ_IF(ifExp = exp,equationTrueItems = true_items,elseIfBranches = exp_elseifs,equationElseItems = elses),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        true_items_1 = renameComponentInEquationList(true_items, old_comp, new_comp);
        exp_elseifs_1 = renameComponentInExpEquationitemList(exp_elseifs, old_comp, new_comp);
        elses_1 = renameComponentInEquationList(elses, old_comp, new_comp);
      then
        Absyn.EQ_IF(exp_1,true_items_1,exp_elseifs_1,elses_1);
    case (Absyn.EQ_EQUALS(leftSide = exp1,rightSide = exp2),old_comp,new_comp)
      equation
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp2_1 = renameComponentInExp(exp2, old_comp, new_comp);
      then
        Absyn.EQ_EQUALS(exp1_1,exp2_1);
    case (Absyn.EQ_CONNECT(connector1 = cref1,connector2 = cref2),old_comp,new_comp)
      equation
        cref1_1 = replaceStartInComponentRef(cref1, old_comp, new_comp);
        cref2_1 = replaceStartInComponentRef(cref2, old_comp, new_comp) "print \"-rename_component_in_equation EQ_CONNECT not implemented yet\\n\"" ;
      then
        Absyn.EQ_CONNECT(cref1_1,cref2_1);
    case (Absyn.EQ_FOR(iterators = {Absyn.ITERATOR(ident,NONE(),SOME(exp))},forEquations = equations),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        equations_1 = renameComponentInEquationList(equations, old_comp, new_comp);
      then
        Absyn.EQ_FOR({Absyn.ITERATOR(ident,NONE(),SOME(exp_1))},equations_1);
    case (Absyn.EQ_WHEN_E(whenExp = exp,whenEquations = equations,elseWhenEquations = exp_equations),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        equations_1 = renameComponentInEquationList(equations, old_comp, new_comp);
        exp_equations_1 = renameComponentInExpEquationitemList(exp_equations, old_comp, new_comp);
      then
        Absyn.EQ_WHEN_E(exp_1,equations_1,exp_equations_1);
    case (Absyn.EQ_NORETCALL(functionName = cref,functionArgs = function_args),old_comp,new_comp)
      equation
        print("-rename_component_in_equation EQ_NORETCALL not implemented yet\n");
      then
        Absyn.EQ_NORETCALL(cref,function_args);
    case (_,old_comp,new_comp)
      equation
        print("-rename_component_in_equation failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInEquation;

protected function renameComponentInExpList
"author: x02lucpo
  helper function to renameComponentVisitor"
  input list<Absyn.Exp> inAbsynExpLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.Exp> outAbsynExpLst;
algorithm
  outAbsynExpLst := matchcontinue (inAbsynExpLst1,inComponentRef2,inComponentRef3)
    local
      Absyn.Exp exp_1,exp;
      list<Absyn.Exp> res_1,res;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};  /* the old name for the component */
    case ((exp :: res),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        res_1 = renameComponentInExpList(res, old_comp, new_comp);
      then
        (exp_1 :: res_1);
    case (_,_,_)
      equation
        print("-rename_component_in_exp_list failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInExpList;

protected function renameComponentInExpListList
"author: x02lucpo
  helper function to renameComponentVisitor"
  input list<list<Absyn.Exp>> inAbsynExpLstLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<list<Absyn.Exp>> outAbsynExpLstLst;
algorithm
  outAbsynExpLstLst := matchcontinue (inAbsynExpLstLst1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.Exp> exp_1,exp;
      list<list<Absyn.Exp>> res_1,res;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};  /* the old name for the component */
    case ((exp :: res),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExpList(exp, old_comp, new_comp);
        res_1 = renameComponentInExpListList(res, old_comp, new_comp);
      then
        (exp_1 :: res_1);
    case (_,_,_)
      equation
        print("-rename_component_in_exp_list_list failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInExpListList;

protected function renameComponentInExpTupleList
"author: x02lucpo
  helper function to renameComponentVisitor"
  input list<tuple<Absyn.Exp, Absyn.Exp>> inTplAbsynExpAbsynExpLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<tuple<Absyn.Exp, Absyn.Exp>> outTplAbsynExpAbsynExpLst;
algorithm
  outTplAbsynExpAbsynExpLst := matchcontinue (inTplAbsynExpAbsynExpLst1,inComponentRef2,inComponentRef3)
    local
      Absyn.Exp exp1_1,exp2_1,exp1,exp2;
      list<tuple<Absyn.Exp, Absyn.Exp>> res_1,res;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};
    case (((exp1,exp2) :: res),old_comp,new_comp)
      equation
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp2_1 = renameComponentInExp(exp2, old_comp, new_comp);
        res_1 = renameComponentInExpTupleList(res, old_comp, new_comp);
      then
        ((exp1_1,exp2_1) :: res_1);
    case (_,_,_)
      equation
        print("-rename_component_in_exp_tuple_list failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInExpTupleList;

protected function renameComponentInElementArgList
"author: x02lucpo
  helper function to renameComponentVisitor"
  input list<Absyn.ElementArg> inAbsynElementArgLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.ElementArg> outAbsynElementArgLst;
algorithm
  outAbsynElementArgLst := matchcontinue (inAbsynElementArgLst1,inComponentRef2,inComponentRef3)
    local
      Absyn.ElementArg element_arg_1,element_arg;
      list<Absyn.ElementArg> res_1,res;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};  /* the old name for the component */
    case ((element_arg :: res),old_comp,new_comp)
      equation
        element_arg_1 = renameComponentInElementArg(element_arg, old_comp, new_comp);
        res_1 = renameComponentInElementArgList(res, old_comp, new_comp);
      then
        (element_arg_1 :: res_1);
    case (_,_,_)
      equation
        print("-rename_component_in_element_arg_list failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInElementArgList;

protected function renameComponentInElementArg
"author: x02lucpo
  helper function to renameComponentVisitor"
  input Absyn.ElementArg inElementArg1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.ElementArg outElementArg;
algorithm
  outElementArg := match (inElementArg1,inComponentRef2,inComponentRef3)
    local
      Absyn.ComponentRef cr_1,cr,old_comp,new_comp;
      Absyn.Exp exp_1,exp;
      list<Absyn.ElementArg> element_args_1,element_args;
      Boolean b;
      Absyn.Each each_;
      Option<String> str;
      Absyn.ElementSpec element_spec_1,element_spec2_1,element_spec,element_spec2;
      Absyn.RedeclareKeywords redecl;
      Option<Absyn.Comment> c;
      Absyn.Info info, mod_info;
    /* the old name for the component */
    case (Absyn.MODIFICATION(finalPrefix = b,eachPrefix = each_,componentRef = cr,modification = SOME(Absyn.CLASSMOD(element_args,Absyn.EQMOD(exp,info))),comment = str,info = mod_info),old_comp,new_comp)
      equation
        cr_1 = replaceStartInComponentRef(cr, old_comp, new_comp);
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        element_args_1 = renameComponentInElementArgList(element_args, old_comp, new_comp);
      then
        Absyn.MODIFICATION(b,each_,cr_1,
          SOME(Absyn.CLASSMOD(element_args_1,Absyn.EQMOD(exp_1,info))),str,mod_info);
    case (Absyn.MODIFICATION(finalPrefix = b,eachPrefix = each_,componentRef = cr,modification = SOME(Absyn.CLASSMOD(element_args,Absyn.NOMOD())),comment = str, info = mod_info),old_comp,new_comp)
      equation
        cr_1 = replaceStartInComponentRef(cr, old_comp, new_comp);
        element_args_1 = renameComponentInElementArgList(element_args, old_comp, new_comp);
      then
        Absyn.MODIFICATION(b,each_,cr_1,SOME(Absyn.CLASSMOD(element_args_1,Absyn.NOMOD())),str,mod_info);
    case (Absyn.MODIFICATION(finalPrefix = b,eachPrefix = each_,componentRef = cr,modification = NONE(),comment = str, info = mod_info),old_comp,new_comp)
      equation
        cr_1 = replaceStartInComponentRef(cr, old_comp, new_comp);
      then
        Absyn.MODIFICATION(b,each_,cr_1,NONE(),str,mod_info);
    case (Absyn.REDECLARATION(finalPrefix = b,redeclareKeywords = redecl,eachPrefix = each_,elementSpec = element_spec,constrainClass = SOME(Absyn.CONSTRAINCLASS(element_spec2,c)),info = info),old_comp,new_comp)
      equation
        element_spec_1 = renameComponentInElementSpec(element_spec, old_comp, new_comp);
        element_spec2_1 = renameComponentInElementSpec(element_spec2, old_comp, new_comp);
      then
        Absyn.REDECLARATION(b,redecl,each_,element_spec_1,
          SOME(Absyn.CONSTRAINCLASS(element_spec2_1,c)),info);
    case (Absyn.REDECLARATION(finalPrefix = b,redeclareKeywords = redecl,eachPrefix = each_,elementSpec = element_spec,constrainClass = NONE(),info=info),old_comp,new_comp)
      equation
        element_spec_1 = renameComponentInElementSpec(element_spec, old_comp, new_comp);
      then
        Absyn.REDECLARATION(b,redecl,each_,element_spec_1,NONE(),info);
  end match;
end renameComponentInElementArg;

protected function renameComponentInCode
"author: x02lucpo
  helper function to renameComponentVisitor"
  input Absyn.CodeNode inCode1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.CodeNode outCode;
algorithm
  outCode := match (inCode1,inComponentRef2,inComponentRef3)
    local
      Absyn.Path path;
      Absyn.ComponentRef old_comp,new_comp,cr_1,cr;
      list<Absyn.EquationItem> eqn_items_1,eqn_items;
      Boolean b,finalPrefix;
      list<Absyn.AlgorithmItem> algs_1,algs;
      Absyn.ElementSpec elementspec_1,elementspec;
      Option<Absyn.RedeclareKeywords> redeclare_;
      Absyn.InnerOuter inner_outer;
      String name;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constrainClass;
      Absyn.Exp exp_1,exp;
      list<Absyn.ElementArg> element_args_1,element_args;
    case (Absyn.C_TYPENAME(path = path),old_comp,new_comp) then Absyn.C_TYPENAME(path);  /* the old name for the component */
    case (Absyn.C_VARIABLENAME(componentRef = cr),old_comp,new_comp)
      equation
        cr_1 = replaceStartInComponentRef(cr, old_comp, new_comp);
      then
        Absyn.C_VARIABLENAME(cr_1);
    case (Absyn.C_EQUATIONSECTION(boolean = b,equationItemLst = eqn_items),old_comp,new_comp)
      equation
        eqn_items_1 = renameComponentInEquationList(eqn_items, old_comp, new_comp);
      then
        Absyn.C_EQUATIONSECTION(b,eqn_items_1);
    case (Absyn.C_ALGORITHMSECTION(boolean = b,algorithmItemLst = algs),old_comp,new_comp)
      equation
        algs_1 = renameComponentInAlgorithms(algs, old_comp, new_comp);
      then
        Absyn.C_ALGORITHMSECTION(b,algs_1);
    case (Absyn.C_ELEMENT(element = Absyn.ELEMENT(finalPrefix = finalPrefix,redeclareKeywords = redeclare_,innerOuter = inner_outer,name = name,specification = elementspec,info = info,constrainClass = constrainClass)),old_comp,new_comp)
      equation
        elementspec_1 = renameComponentInElementSpec(elementspec, old_comp, new_comp);
      then
        Absyn.C_ELEMENT(
          Absyn.ELEMENT(finalPrefix,redeclare_,inner_outer,name,elementspec_1,info,
          constrainClass));
    case (Absyn.C_EXPRESSION(exp = exp),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
      then
        Absyn.C_EXPRESSION(exp_1);
    case (Absyn.C_MODIFICATION(modification = Absyn.CLASSMOD(elementArgLst = element_args,eqMod = Absyn.EQMOD(exp,info))),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        element_args_1 = renameComponentInElementArgList(element_args, old_comp, new_comp);
      then
        Absyn.C_MODIFICATION(Absyn.CLASSMOD(element_args_1,Absyn.EQMOD(exp_1,info)));
    case (Absyn.C_MODIFICATION(modification = Absyn.CLASSMOD(elementArgLst = element_args,eqMod = Absyn.NOMOD())),old_comp,new_comp)
      equation
        element_args_1 = renameComponentInElementArgList(element_args, old_comp, new_comp);
      then
        Absyn.C_MODIFICATION(Absyn.CLASSMOD(element_args_1,Absyn.NOMOD()));
  end match;
end renameComponentInCode;

protected function renameComponentInExp
"author: x02lucpo
  helper function to renameComponentVisitor"
  input Absyn.Exp inExp1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp1,inComponentRef2,inComponentRef3)
    local
      Integer i;
      Real r;
      String s;
      Boolean b;
      Absyn.ComponentRef old_comp,new_comp,cr_1,cr,cref;
      Absyn.Exp exp1_1,exp2_1,exp1,exp2,exp_1,exp,exp3_1,exp3;
      Absyn.Operator op;
      list<tuple<Absyn.Exp, Absyn.Exp>> exp_tuple_list_1,exp_tuple_list;
      Absyn.FunctionArgs func_args;
      list<Absyn.Exp> exp_list_1,exp_list;
      list<list<Absyn.Exp>> exp_list_list_1,exp_list_list;
      Absyn.CodeNode code_1,code;
    case (Absyn.INTEGER(value = i),old_comp,new_comp) then Absyn.INTEGER(i);
    case (Absyn.REAL(value = r),old_comp,new_comp) then Absyn.REAL(r);
    case (Absyn.CREF(componentRef = cr),old_comp,new_comp)
      equation
        cr_1 = replaceStartInComponentRef(cr, old_comp, new_comp);
      then
        Absyn.CREF(cr_1);
    case (Absyn.STRING(value = s),old_comp,new_comp) then Absyn.STRING(s);
    case (Absyn.BOOL(value = b),old_comp,new_comp) then Absyn.BOOL(b);
    case (Absyn.BINARY(exp1 = exp1,op = op,exp2 = exp2),old_comp,new_comp)
      equation
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp2_1 = renameComponentInExp(exp2, old_comp, new_comp);
      then
        Absyn.BINARY(exp1_1,op,exp2_1);
    case (Absyn.UNARY(op = op,exp = exp),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
      then
        Absyn.UNARY(op,exp);
    case (Absyn.LBINARY(exp1 = exp1,op = op,exp2 = exp2),old_comp,new_comp)
      equation
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp2_1 = renameComponentInExp(exp2, old_comp, new_comp);
      then
        Absyn.LBINARY(exp1_1,op,exp2_1);
    case (Absyn.LUNARY(op = op,exp = exp),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
      then
        Absyn.LUNARY(op,exp);
    case (Absyn.RELATION(exp1 = exp1,op = op,exp2 = exp2),old_comp,new_comp)
      equation
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp2_1 = renameComponentInExp(exp2, old_comp, new_comp);
      then
        Absyn.RELATION(exp1_1,op,exp2_1);
    case (Absyn.IFEXP(ifExp = exp1,trueBranch = exp2,elseBranch = exp3,elseIfBranch = exp_tuple_list),old_comp,new_comp)
      equation
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp2_1 = renameComponentInExp(exp2, old_comp, new_comp);
        exp3_1 = renameComponentInExp(exp3, old_comp, new_comp);
        exp_tuple_list_1 = renameComponentInExpTupleList(exp_tuple_list, old_comp, new_comp);
      then
        Absyn.IFEXP(exp1_1,exp2_1,exp3_1,exp_tuple_list_1);
    case (Absyn.CALL(function_ = cref,functionArgs = func_args),old_comp,new_comp)
      equation
        print(
          "-rename_component_in_exp for Absyn.CALL not implemented yet\n");
      then
        Absyn.CALL(cref,func_args);
    case (Absyn.ARRAY(arrayExp = exp_list),old_comp,new_comp)
      equation
        exp_list_1 = renameComponentInExpList(exp_list, old_comp, new_comp);
      then
        Absyn.ARRAY(exp_list_1);
    case (Absyn.MATRIX(matrix = exp_list_list),old_comp,new_comp)
      equation
        exp_list_list_1 = renameComponentInExpListList(exp_list_list, old_comp, new_comp);
      then
        Absyn.MATRIX(exp_list_list_1);
    case (Absyn.RANGE(start = exp1,step = SOME(exp2),stop = exp3),old_comp,new_comp)
      equation
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp2_1 = renameComponentInExp(exp2, old_comp, new_comp);
        exp3_1 = renameComponentInExp(exp3, old_comp, new_comp);
      then
        Absyn.RANGE(exp1_1,SOME(exp2_1),exp3_1);
    case (Absyn.RANGE(start = exp1,step = NONE(),stop = exp3),old_comp,new_comp)
      equation
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp3_1 = renameComponentInExp(exp3, old_comp, new_comp);
      then
        Absyn.RANGE(exp1_1,NONE(),exp3_1);
    case (Absyn.TUPLE(expressions = exp_list),old_comp,new_comp)
      equation
        exp_list_1 = renameComponentInExpList(exp_list, old_comp, new_comp);
      then
        Absyn.TUPLE(exp_list_1);
    case (Absyn.END(),old_comp,new_comp) then Absyn.END();
    case (Absyn.CODE(code = code),old_comp,new_comp)
      equation
        code_1 = renameComponentInCode(code, old_comp, new_comp);
      then
        Absyn.CODE(code_1);
    case (_,old_comp,new_comp)
      equation
        print("-rename_component_in_exp failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInExp;

protected function renameComponentInAlgorithms
"author: x02lucpo
  helper function to renameComponentVisitor"
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.AlgorithmItem> outAbsynAlgorithmItemLst;
algorithm
  outAbsynAlgorithmItemLst:=
  match (inAbsynAlgorithmItemLst1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.AlgorithmItem> res_1,res;
      Absyn.AlgorithmItem algorithm_1,algorithm_;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};  /* the old name for the component */
    case ((algorithm_ :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInAlgorithms(res, old_comp, new_comp);
        algorithm_1 = algorithm_;
      then
        (algorithm_1 :: res_1);
  end match;
end renameComponentInAlgorithms;

protected function renameComponentInAlgorithm
"author: x02lucpo
  helper function to renameComponentVisitor"
  input Absyn.Algorithm inAlgorithm1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.Algorithm outAlgorithm;
algorithm
  outAlgorithm:=
  matchcontinue (inAlgorithm1,inComponentRef2,inComponentRef3)
    local
      Absyn.ComponentRef cr_1,cr,old_comp,new_comp;
      Absyn.Exp exp_1,exp,exp1_1,exp2_1,exp1,exp2;
      list<Absyn.AlgorithmItem> algs1_1,algs2_1,algs1,algs2,algs_1,algs;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> exp_algs_list_1,exp_algs_list;
      String id;
      Absyn.FunctionArgs func_args_1,func_args;
    case (Absyn.ALG_ASSIGN(assignComponent = Absyn.CREF(cr),value = exp),old_comp,new_comp) /* the old name for the component */
      equation
        cr_1 = replaceStartInComponentRef(cr, old_comp, new_comp);
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
      then
        Absyn.ALG_ASSIGN(Absyn.CREF(cr_1),exp_1);
    case (Absyn.ALG_ASSIGN(assignComponent = exp1 as Absyn.TUPLE(_),value = exp2),old_comp,new_comp)
      equation
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp2_1 = renameComponentInExp(exp2, old_comp, new_comp);
      then
        Absyn.ALG_ASSIGN(exp1_1, exp2_1);
    case (Absyn.ALG_IF(ifExp = exp,trueBranch = algs1,elseIfAlgorithmBranch = exp_algs_list,elseBranch = algs2),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        algs1_1 = renameComponentInAlgorithms(algs1, old_comp, new_comp);
        exp_algs_list_1 = renameComponentInExpAlgoritmsList(exp_algs_list, old_comp, new_comp);
        algs2_1 = renameComponentInAlgorithms(algs2, old_comp, new_comp);
      then
        Absyn.ALG_IF(exp_1,algs1_1,exp_algs_list_1,algs2_1);
    case (Absyn.ALG_FOR(iterators = {Absyn.ITERATOR(id,NONE(),SOME(exp))},forBody = algs),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        algs_1 = renameComponentInAlgorithms(algs, old_comp, new_comp);
      then
        Absyn.ALG_FOR({Absyn.ITERATOR(id,NONE(),SOME(exp_1))},algs_1);
    case (Absyn.ALG_WHILE(boolExpr = exp,whileBody = algs),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        algs_1 = renameComponentInAlgorithms(algs, old_comp, new_comp);
      then
        Absyn.ALG_WHILE(exp_1,algs_1);
    case (Absyn.ALG_WHEN_A(boolExpr = exp,whenBody = algs,elseWhenAlgorithmBranch = exp_algs_list),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        algs_1 = renameComponentInAlgorithms(algs, old_comp, new_comp);
        exp_algs_list_1 = renameComponentInExpAlgoritmsList(exp_algs_list, old_comp, new_comp);
      then
        Absyn.ALG_WHEN_A(exp_1,algs_1,exp_algs_list_1);
    case (Absyn.ALG_NORETCALL(functionCall = cr,functionArgs = func_args),old_comp,new_comp)
      equation
        cr_1 = replaceStartInComponentRef(cr, old_comp, new_comp);
        func_args_1 = renameComponentInFunctionArgs(func_args, old_comp, new_comp);
      then
        Absyn.ALG_NORETCALL(cr_1,func_args_1);
  end matchcontinue;
end renameComponentInAlgorithm;

protected function renameComponentInExpAlgoritmsList
"author: x02lucpo
  helper function to renameComponentVisitor"
  input list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> inTplAbsynExpAbsynAlgorithmItemLstLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> outTplAbsynExpAbsynAlgorithmItemLstLst;
algorithm
  outTplAbsynExpAbsynAlgorithmItemLstLst:=
  matchcontinue (inTplAbsynExpAbsynAlgorithmItemLstLst1,inComponentRef2,inComponentRef3)
    local
      Absyn.Exp exp_1,exp;
      list<Absyn.AlgorithmItem> algs_1,algs;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> res_1,res;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};
    case (((exp,algs) :: res),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        algs_1 = renameComponentInAlgorithms(algs, old_comp, new_comp);
        res_1 = renameComponentInExpAlgoritmsList(res, old_comp, new_comp);
      then
        ((exp_1,algs_1) :: res_1);
    case (_,_,_)
      equation
        print("-rename_component_in_exp_algoritms_list failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInExpAlgoritmsList;

protected function renameComponentInFunctionArgs
"author: x02lucpo
  helper function to renameComponentVisitor"
  input Absyn.FunctionArgs inFunctionArgs1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.FunctionArgs outFunctionArgs;
algorithm
  outFunctionArgs:=
  matchcontinue (inFunctionArgs1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.Exp> exps_1,exps;
      list<Absyn.NamedArg> namedArg_1,namedArg;
      Absyn.ComponentRef old_comp,new_comp;
      Absyn.Exp exp1_1,exp2_1,exp1,exp2, exp;
      String id;
      Absyn.ForIterators iterators, iteratorsRenamed;
    case (Absyn.FUNCTIONARGS(args = exps,argNames = namedArg),old_comp,new_comp) /* the old name for the component */
      equation
        exps_1 = renameComponentInExpList(exps, old_comp, new_comp);
        namedArg_1 = renameComponentInNamedArgs(namedArg, old_comp, new_comp);
      then
        Absyn.FUNCTIONARGS(exps_1,namedArg_1);
    case (Absyn.FOR_ITER_FARG(exp = exp, iterators=iterators),old_comp,new_comp)
      equation
        exp1_1 = renameComponentInExp(exp, old_comp, new_comp);
        iteratorsRenamed = renameComponentInIterators(iterators, old_comp, new_comp);
      then
        Absyn.FOR_ITER_FARG(exp1_1, iteratorsRenamed);
    case (_,_,_)
      equation
        print("-rename_component_in_function_args failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInFunctionArgs;

protected function renameComponentInIterators
"@author adrpo
 renames the components from expression present in iterators:
 i in exp1, j in exp2, etc"
  input Absyn.ForIterators iterators;
  input Absyn.ComponentRef oldComp;
  input Absyn.ComponentRef newComp;
  output Absyn.ForIterators iteratorsRenamed;
algorithm
  iteratorsRenamed := matchcontinue(iterators, oldComp, newComp)
  local
    Absyn.ForIterators rest, restNew;
    Absyn.Exp exp, expNew; String i;
    case ({}, _, _) then {};
    case (Absyn.ITERATOR(i, NONE(), SOME(exp))::rest, oldComp, newComp)
      equation
        expNew = renameComponentInExp(exp, oldComp, newComp);
        restNew = renameComponentInIterators(rest, oldComp, newComp);
      then Absyn.ITERATOR(i, NONE(), SOME(expNew))::restNew;
    case (Absyn.ITERATOR(i, NONE(), NONE())::rest, oldComp, newComp)
      equation
        restNew = renameComponentInIterators(rest, oldComp, newComp);
      then Absyn.ITERATOR(i, NONE(), NONE())::restNew;
  end matchcontinue;
end renameComponentInIterators;

protected function renameComponentInNamedArgs
"author: x02lucpo
  helper function to renameComponentVisitor"
  input list<Absyn.NamedArg> inAbsynNamedArgLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.NamedArg> outAbsynNamedArgLst;
algorithm
  outAbsynNamedArgLst:=
  matchcontinue (inAbsynNamedArgLst1,inComponentRef2,inComponentRef3)
    local
      Absyn.Exp exp_1,exp;
      list<Absyn.NamedArg> res_1,res;
      String id;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};  /* the old name for the component */
    case ((Absyn.NAMEDARG(argName = id,argValue = exp) :: res),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        res_1 = renameComponentInNamedArgs(res, old_comp, new_comp);
      then
        (Absyn.NAMEDARG(id,exp_1) :: res_1);
    case (_,_,_)
      equation
        print("-rename_component_in_namedArgs failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInNamedArgs;

protected function renameComponentInExternalDecl
"author: x02lucpo
  helper function to renameComponentVisitor"
  input Absyn.ExternalDecl external_;
  input Absyn.ComponentRef old_comp;
  input Absyn.ComponentRef new_comp;
  output Absyn.ExternalDecl external_1;
algorithm
  print("-rename_component_in_external_decl not implemented yet\n");
  external_1 := external_;
end renameComponentInExternalDecl;

protected function replaceStartInComponentRef
"function replaceStartInComponentRef
  author x02lucpo
  this replace the start of a ComponentRef with another
  ie: (a.b.c.d, a.b, c.f) => c.f.c.d
     (a.b.c.d, d.c, c.f) => a.b.c.d
     WARNING! WARNING! WARNING! WARNING! WARNING! WARNING!
     WARNING! WARNING! WARNING! WARNING! WARNING! WARNING!
     (a.b.c.d, a.b, c.f.r) => a.b.c.d
     WARNING! WARNING! WARNING! WARNING! WARNING! WARNING!
     WARNING! WARNING! WARNING! WARNING! WARNING! WARNING!"
  input Absyn.ComponentRef cr1;
  input Absyn.ComponentRef cr2;
  input Absyn.ComponentRef cr3;
  output Absyn.ComponentRef res;
algorithm
  res := replaceStartInComponentRef2(cr1, cr2, cr3)
  "Dump.print_component_ref_str(cr1) => cref_str_tmp &
  print \" \" & print cref_str_tmp &
  Dump.print_component_ref_str(cr2) => cref_str_tmp &
  print \" \" & print cref_str_tmp &
  Dump.print_component_ref_str(cr3) => cref_str_tmp &
  print \" \" & print cref_str_tmp &
  Dump.print_component_ref_str(res) => cref_str_tmp &
  print \" res \" & print cref_str_tmp & print \"\\n\"" ;
end replaceStartInComponentRef;

protected function replaceStartInComponentRef2
"function replaceStartInComponentRef2
  author x02lucpo
  this replace the start of a ComponentRef with another
  ie: (a.b.c.d, a.b, c.f) => c.f.c.d
     (a.b.c.d, d.c, c.f) => a.b.c.d
     WARNING! WARNING! WARNING! WARNING! WARNING! WARNING!
     WARNING! WARNING! WARNING! WARNING! WARNING! WARNING!
     (a.b.c.d, a.b, c.f.r) => a.b.c.d
     WARNING! WARNING! WARNING! WARNING! WARNING! WARNING!
     WARNING! WARNING! WARNING! WARNING! WARNING! WARNING!"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inComponentRef1,inComponentRef2,inComponentRef3)
    local
      String id,id2,id3;
      Absyn.ComponentRef res,cr1,cr,cr2,cr3,orig_cr;
      list<Absyn.Subscript> a;
    case (Absyn.CREF_IDENT(name = id),Absyn.CREF_IDENT(name = id2),(res as Absyn.CREF_IDENT(name = id3)))
      equation
        true = stringEq(id, id2);
      then
        res;
    case (Absyn.CREF_QUAL(name = id,subscripts = a,componentRef = cr1),Absyn.CREF_IDENT(name = id2),Absyn.CREF_IDENT(name = id3))
      equation
        true = stringEq(id, id2);
      then
        Absyn.CREF_QUAL(id3,a,cr1);
    case (Absyn.CREF_QUAL(name = id,subscripts = a,componentRef = cr1),Absyn.CREF_QUAL(name = id2,componentRef = cr2),Absyn.CREF_QUAL(name = id3,componentRef = cr3))
      equation
        true = stringEq(id, id2);
        cr = replaceStartInComponentRef2(cr1, cr2, cr3);
      then
        Absyn.CREF_QUAL(id3,a,cr);
    case (orig_cr,_,_) then orig_cr;
  end matchcontinue;
end replaceStartInComponentRef2;

protected function getComponentreplacementsrules
"function getComponentreplacementsrules
  author: x02lucpo
  this extracts all the componentreplacementrules by
  searching for new rules until the list-size does not
  grow any more"
  input Components inComponents;
  input ComponentReplacementRules inComponentReplacementRules;
  input Integer inInteger;
  output ComponentReplacementRules outComponentReplacementRules;
algorithm
  outComponentReplacementRules := matchcontinue (inComponents,inComponentReplacementRules,inInteger)
    local
      Integer len,old_len;
      Components comps;
      ComponentReplacementRules comp_reps,comp_reps_1,comp_reps_2,comp_reps_res;
    case (comps,comp_reps,old_len)
      equation
        len = lengthComponentReplacementRules(comp_reps);
        (len == old_len) = true;
      then
        comp_reps;
    case (comps,comp_reps,len)
      equation
        old_len = lengthComponentReplacementRules(comp_reps);
        comp_reps_1 = getNewComponentreplacementsrulesForEachRule(comps, comp_reps);
        comp_reps_2 = joinComponentReplacementRules(comp_reps_1, comp_reps);
        comp_reps_res = getComponentreplacementsrules(comps, comp_reps_2, old_len);
      then
        comp_reps_res;
    case (comps,comp_reps,_)
      equation
        print("-get_componentreplacementsrules failed\n");
      then
        fail();
  end matchcontinue;
end getComponentreplacementsrules;

protected function getNewComponentreplacementsrulesForEachRule
"function getNewComponentreplacementsrulesForEachRule
  author: x02lucpo
 extracts the replacement rules from the components:
 {COMP(path_1,path_2,cr1),COMP(path_3,path_2,cr2)},{REP_RULE(path_2,cr_1a,cr_1b)}
           => {REP_RULE(path_1,cr1.cr_1a,cr1.cr_1b),REP_RULE(path_3,cr2.cr_1a,cr2.cr_1b)}"
  input Components inComponents;
  input ComponentReplacementRules inComponentReplacementRules;
  output ComponentReplacementRules outComponentReplacementRules;
algorithm
  outComponentReplacementRules:=
  matchcontinue (inComponents,inComponentReplacementRules)
    local
      Components comps,comps_1;
      ComponentReplacementRules comp_reps,comp_reps_1,res,comp_reps_2,comp_reps_3;
      Absyn.Path path;
      Absyn.ComponentRef cr1,cr2;
    case (comps,comp_reps)
      equation
        true = emptyComponentReplacementRules(comp_reps);
      then
        comp_reps;
    case (comps,comp_reps)
      equation
        COMPONENTREPLACEMENT(path,cr1,cr2) = firstComponentReplacement(comp_reps);
        comps_1 = getComponentsWithType(comps, path);
        comp_reps_1 = makeComponentsReplacementRulesFromComponents(comps_1, cr1, cr2);
        res = restComponentReplacementRules(comp_reps);
        comp_reps_2 = getNewComponentreplacementsrulesForEachRule(comps, res);
        comp_reps_3 = joinComponentReplacementRules(comp_reps_1, comp_reps_2);
      then
        comp_reps_3;
    case (_,_)
      equation
        print(
          "-get_new_componentreplacementsrules_for_each_rule failed\n");
      then
        fail();
  end matchcontinue;
end getNewComponentreplacementsrulesForEachRule;

protected function makeComponentsReplacementRulesFromComponents
"function makeComponentsReplacementRulesFromComponents
  author: x02lucpo

  this makes the replacementrules from each component in the first parameter:
  {COMP(path_1,path_2,cr1),COMP(path_3,path_2,cr2)},cr_1a,cr_1b
            => {REP_RULE(path_1,cr1.cr_1a,cr1.cr_1b),REP_RULE(path_3,cr2.cr_1a,cr2.cr_1b)}"
  input Components inComponents1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output ComponentReplacementRules outComponentReplacementRules;
algorithm
  outComponentReplacementRules:=
  matchcontinue (inComponents1,inComponentRef2,inComponentRef3)
    local
      Components comps,res;
      Absyn.ComponentRef cr_from,cr_to,cr,cr_from_1,cr_to_1;
      Absyn.Path path_class,path_type;
      ComponentReplacement comp_rep;
      ComponentReplacementRules comps_1,comp_reps_res;
    case (comps,cr_from,cr_to)
      equation
        true = emptyComponents(comps);
      then
        COMPONENTREPLACEMENTRULES({},0);
    case (comps,cr_from,cr_to)
      equation
        COMPONENTITEM(path_class,path_type,cr) = firstComponent(comps);
        cr_from_1 = Absyn.joinCrefs(cr, cr_from);
        cr_to_1 = Absyn.joinCrefs(cr, cr_to);
        comp_rep = COMPONENTREPLACEMENT(path_class,cr_from_1,cr_to_1);
        res = restComponents(comps);
        comps_1 = makeComponentsReplacementRulesFromComponents(res, cr_from, cr_to);
        comp_reps_res = joinComponentReplacementRules(comps_1, COMPONENTREPLACEMENTRULES({comp_rep},1));
      then
        comp_reps_res;
    case (comps,cr_from,cr_to)
      equation
        EXTENDSITEM(path_class,path_type) = firstComponent(comps);
        comp_rep = COMPONENTREPLACEMENT(path_class,cr_from,cr_to);
        res = restComponents(comps);
        comps_1 = makeComponentsReplacementRulesFromComponents(res, cr_from, cr_to);
        comp_reps_res = joinComponentReplacementRules(comps_1, COMPONENTREPLACEMENTRULES({comp_rep},1));
      then
        comp_reps_res;
    case (_,_,_)
      equation
        print("-make_componentsReplacementRules_from_components failed\n");
      then
        fail();
  end matchcontinue;
end makeComponentsReplacementRulesFromComponents;

protected function emptyComponentReplacementRules
"function emptyComponentReplacementRules
  author: x02lucpo
  returns true if the componentReplacementRules are empty"
  input ComponentReplacementRules inComponentReplacementRules;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inComponentReplacementRules)
    case (COMPONENTREPLACEMENTRULES(componentReplacementLst = {})) then true;
    case (_) then false;
  end matchcontinue;
end emptyComponentReplacementRules;

protected function joinComponentReplacementRules
"function joinComponentReplacementRules
 author: x02lucpo
 joins two componentReplacementRules lists by union"
  input ComponentReplacementRules inComponentReplacementRules1;
  input ComponentReplacementRules inComponentReplacementRules2;
  output ComponentReplacementRules outComponentReplacementRules;
algorithm
  outComponentReplacementRules:=
  match (inComponentReplacementRules1,inComponentReplacementRules2)
    local
      list<ComponentReplacement> comps,comps1,comps2;
      Integer len,len1,len2;
    case (COMPONENTREPLACEMENTRULES(componentReplacementLst = comps1,the = len1),COMPONENTREPLACEMENTRULES(componentReplacementLst = comps2,the = len2))
      equation
        comps = List.union(comps1, comps2);
        len = listLength(comps);
      then
        COMPONENTREPLACEMENTRULES(comps,len);
  end match;
end joinComponentReplacementRules;

protected function lengthComponentReplacementRules
"function lengthComponentReplacementRules
  author: x02lucpo
  return the number of the componentReplacementRules"
  input ComponentReplacementRules inComponentReplacementRules;
  output Integer outInteger;
algorithm
  outInteger:=
  match (inComponentReplacementRules)
    local Integer len;
    case (COMPONENTREPLACEMENTRULES(the = len)) then len;
  end match;
end lengthComponentReplacementRules;

protected function firstComponentReplacement
"author: x02lucpo
 extract the first componentReplacement in
 the componentReplacementReplacementRules"
  input ComponentReplacementRules inComponentReplacementRules;
  output ComponentReplacement outComponentReplacement;
algorithm
  outComponentReplacement:=
  match (inComponentReplacementRules)
    local
      ComponentReplacement comp;
      list<ComponentReplacement> res;
    case (COMPONENTREPLACEMENTRULES(componentReplacementLst = {}))
      equation
        print("-first_componentReplacement failed: no componentReplacementReplacementRules\n");
      then
        fail();
    case (COMPONENTREPLACEMENTRULES(componentReplacementLst = (comp :: res))) then comp;
  end match;
end firstComponentReplacement;

protected function restComponentReplacementRules
"author: x02lucpo
 extract the rest componentReplacementRules from the components"
  input ComponentReplacementRules inComponentReplacementRules;
  output ComponentReplacementRules outComponentReplacementRules;
algorithm
  outComponentReplacementRules:=
  match (inComponentReplacementRules)
    local
      Integer len_1,len;
      ComponentReplacement comp;
      list<ComponentReplacement> res;
    case (COMPONENTREPLACEMENTRULES(componentReplacementLst = {})) then COMPONENTREPLACEMENTRULES({},0);
    case (COMPONENTREPLACEMENTRULES(componentReplacementLst = (comp :: res),the = len))
      equation
        len_1 = len - 1;
      then
        COMPONENTREPLACEMENTRULES(res,len_1);
  end match;
end restComponentReplacementRules;

protected function getDependencyOnClass
"author:x02lucpo
 returns _all_ the Components that the class depends on. It can be components or extends
  i.e if a class b has a component of type a and this is called with (<components>,\"a\")
  the it will also return b"
  input Components inComponents;
  input Absyn.Path inPath;
  output Components outComponents;
algorithm
  outComponents:=
  matchcontinue (inComponents,inPath)
    local
      Components comps_types,comps_types2,comps2,comps;
      String str;
      Absyn.Path path;
    case (comps,path)
      equation
        comps_types = getComponentsFromClass(comps, path);
        comps_types2 = getDependencyWithType(comps, comps_types, 0);
        str = dumpComponentsToString(comps_types);
        print("---------comps_types----------\n");
        print(str);
        print("===================\n");
        str = dumpComponentsToString(comps_types2);
        print("---------DEPENDENCIES----------\n");
        print(str);
        print("===================\n");
        comps2 = joinComponents(comps_types, comps_types2);
      then
        comps2;
    case (_,_)
      equation
        print("-get_dependency_on_class failed\n");
      then
        fail();
  end matchcontinue;
end getDependencyOnClass;

protected function getDependencyWithType
"author: x02lucpo
 helper function to get_dependency_on_class
 extracts all the components that have the
 dependency on type"
  input Components inComponents1;
  input Components inComponents2;
  input Integer inInteger3;
  output Components outComponents;
algorithm
  outComponents:=
  matchcontinue (inComponents1,inComponents2,inInteger3)
    local
      Integer len,old_len;
      Components comps,in_comps,in_comps_1,comps_1,out_comps;
    case (comps,in_comps,old_len) /* rule  dump_components_to_string(comps) => str & print \"---------comps----------\\n\" & print str & print \"===================\\n\" & dump_components_to_string(in_comps) => str & print \"---------in_comps----------\\n\" & print str & print \"===================\\n\" & int_eq(1,2) => true --------------------------- get_dependency_with_type(comps, in_comps, old_len) => in_comps */
      equation
        len = lengthComponents(in_comps);
        (old_len == len) = true;
      then
        in_comps;
    case (comps,in_comps,old_len)
      equation
        len = lengthComponents(in_comps);
        in_comps_1 = getComponentsWithComponentsClass(comps, in_comps) "get_components_with_components_type(comps,in_comps) => in_comps\' &" ;
        comps_1 = joinComponents(in_comps_1, in_comps);
        out_comps = getDependencyWithType(comps, comps_1, len);
      then
        out_comps;
    case (_,_,_)
      equation
        print("-get_dependency_with_type failed\n");
      then
        fail();
  end matchcontinue;
end getDependencyWithType;

protected function getComponentsWithComponentsClass
"author x02lucpo
  extracts all the components with class == the class
  of the components in the second list from first list
  of Components "
  input Components inComponents1;
  input Components inComponents2;
  output Components outComponents;
algorithm
  outComponents:=
  matchcontinue (inComponents1,inComponents2)
    local
      Components comps,in_comps,in_comps_1,comp1,comps_1,comps_2;
      Component comp;
      Absyn.Path comp_path;
    case (comps,in_comps)
      equation
        true = emptyComponents(in_comps);
      then
        COMPONENTS({},0);
    case (comps,in_comps)
      equation
        ((comp as COMPONENTITEM(comp_path,_,_))) = firstComponent(in_comps);
        in_comps_1 = restComponents(in_comps);
        comp1 = getComponentsWithType(comps, comp_path);
        comps_1 = getComponentsWithComponentsClass(comps, in_comps_1);
        comps_2 = joinComponents(comp1, comps_1);
      then
        comps_2;
    case (comps,in_comps)
      equation
        ((comp as EXTENDSITEM(comp_path,_))) = firstComponent(in_comps);
        in_comps_1 = restComponents(in_comps);
        comp1 = getComponentsWithType(comps, comp_path);
        comps_1 = getComponentsWithComponentsClass(comps, in_comps_1);
        comps_2 = joinComponents(comp1, comps_1);
      then
        comps_2;
    case (_,_)
      equation
        print("-get_components_with_components_class failed\n");
      then
        fail();
  end matchcontinue;
end getComponentsWithComponentsClass;

protected function getComponentsWithComponentsType
"author x02lucpo
 extracts all the components with class == the type
 of the components in the second list from first list
 of Components"
  input Components inComponents1;
  input Components inComponents2;
  output Components outComponents;
algorithm
  outComponents:=
  matchcontinue (inComponents1,inComponents2)
    local
      Components comps,in_comps,in_comps_1,comp1,comps_1,comps_2;
      Component comp;
      Absyn.Path comp_path;
    case (comps,in_comps)
      equation
        true = emptyComponents(in_comps);
      then
        COMPONENTS({},0);
    case (comps,in_comps)
      equation
        ((comp as COMPONENTITEM(_,comp_path,_))) = firstComponent(in_comps);
        in_comps_1 = restComponents(in_comps);
        comp1 = getComponentsWithType(comps, comp_path);
        comps_1 = getComponentsWithComponentsType(comps, in_comps_1);
        comps_2 = joinComponents(comp1, comps_1);
      then
        comps_2;
    case (comps,in_comps)
      equation
        ((comp as EXTENDSITEM(_,comp_path))) = firstComponent(in_comps);
        in_comps_1 = restComponents(in_comps);
        comp1 = getComponentsWithType(comps, comp_path);
        comps_1 = getComponentsWithComponentsType(comps, in_comps_1);
        comps_2 = joinComponents(comp1, comps_1);
      then
        comps_2;
    case (_,_)
      equation
        print("-get_components_with_components_type failed\n");
      then
        fail();
  end matchcontinue;
end getComponentsWithComponentsType;

protected function getComponentsFromClass
"author: x02lucpo
 extracts all the components that are in the class"
  input Components inComponents;
  input Absyn.Path inPath;
  output Components outComponents;
algorithm
  outComponents:=
  matchcontinue (inComponents,inPath)
    local
      Components comps,res,comps_1,comps_2;
      Component comp;
      Absyn.Path comp_path,path;
    case (comps,_) /* rule  Absyn.path_string(path) => comp_path & print \"extracting comps for: \" & print comp_path & print \"\\n\" & int_eq(1,2) => true --------------------------- get_components_from_class(comps,path) => comps */
      equation
        true = emptyComponents(comps);
      then
        COMPONENTS({},0);
    case (comps,path)
      equation
        ((comp as COMPONENTITEM(comp_path,_,_))) = firstComponent(comps);
        true = Absyn.pathEqual(comp_path, path);
        res = restComponents(comps);
        comps_1 = getComponentsFromClass(res, path);
        comps_2 = addComponentToComponents(comp, comps_1);
      then
        comps_2;
    case (comps,path)
      equation
        ((comp as EXTENDSITEM(comp_path,_))) = firstComponent(comps);
        true = Absyn.pathEqual(comp_path, path);
        res = restComponents(comps);
        comps_1 = getComponentsFromClass(res, path);
        comps_2 = addComponentToComponents(comp, comps_1);
      then
        comps_2;
    case (comps,path)
      equation
        res = restComponents(comps);
        comps_1 = getComponentsFromClass(res, path);
      then
        comps_1;
    case (_,_)
      equation
        print("-get_components_from_class failed\n");
      then
        COMPONENTS({},0);
  end matchcontinue;
end getComponentsFromClass;

protected function getComponentsWithType
"author: x02lucpo
 extracts all the components that have the type"
  input Components inComponents;
  input Absyn.Path inPath;
  output Components outComponents;
algorithm
  outComponents:=
  matchcontinue (inComponents,inPath)
    local
      Components comps,res,comps_1,comps_2;
      Component comp;
      Absyn.Path comp_path,path;
    case (comps,_) /* rule  Absyn.path_string(path) => comp_path & print \"extracting comps for: \" & print comp_path & print \"\\n\" & int_eq(1,2) => true --------------------------- get_components_with_type(comps,path) => comps */
      equation
        true = emptyComponents(comps);
      then
        COMPONENTS({},0);
    case (comps,path)
      equation
        ((comp as COMPONENTITEM(_,comp_path,_))) = firstComponent(comps);
        true = Absyn.pathEqual(comp_path, path);
        res = restComponents(comps);
        comps_1 = getComponentsWithType(res, path);
        comps_2 = addComponentToComponents(comp, comps_1);
      then
        comps_2;
    case (comps,path)
      equation
        ((comp as EXTENDSITEM(_,comp_path))) = firstComponent(comps);
        true = Absyn.pathEqual(comp_path, path);
        res = restComponents(comps);
        comps_1 = getComponentsWithType(res, path);
        comps_2 = addComponentToComponents(comp, comps_1);
      then
        comps_2;
    case (comps,path)
      equation
        res = restComponents(comps);
        comps_1 = getComponentsWithType(res, path);
      then
        comps_1;
    case (_,_)
      equation
        print("-get_components_with_type failed\n");
      then
        COMPONENTS({},0);
  end matchcontinue;
end getComponentsWithType;

protected function extractAllComponents
"author: x02lucpo
 this traverse all the classes and
 extracts all the components and \"extends\""
  input Absyn.Program p;
  input Absyn.Path path;
  output Components comps;
algorithm
  comps := match(p, path)
    local
        SCode.Program p_1;
        list<Env.Frame> env;
    
    /*
    // if we have a top level class, a modification into it doesn't affect any other!
    case (p, path as Absyn.IDENT(_))
      equation
        p = Dependency.getTotalProgramFromPath(path, p);
        p_1 = SCodeUtil.translateAbsyn2SCode(p);
        (_,env) = Inst.makeEnvFromProgram(Env.emptyCache(),p_1, Absyn.IDENT(""));
        ((_,_,(comps,_,_))) = traverseClasses(p, NONE(), extractAllComponentsVisitor,(COMPONENTS({},0),p,env), true) "traverse protected";
      then
        comps;
    */    
    // if we have a qualified class, a modification into it can affect any other
    case (p, path /*as Absyn.QUALIFIED(name=_)*/)
      equation
        p_1 = SCodeUtil.translateAbsyn2SCode(p);
        (_,env) = Inst.makeEnvFromProgram(Env.emptyCache(),p_1, Absyn.IDENT(""));
        ((_,_,(comps,_,_))) = traverseClasses(p, NONE(), extractAllComponentsVisitor,(COMPONENTS({},0),p,env), true) "traverse protected";
      then
        comps;
  end match;
end extractAllComponents;

protected function extractAllComponentsVisitor
"function extractAllComponentsVisitor
  author: x02lucpo
  the visitor for traverse-classes that extracts all
  the components and extends from all classes"
  input tuple<Absyn.Class, Option<Absyn.Path>, tuple<Components, Absyn.Program, Env.Env>> inTplAbsynClassAbsynPathOptionTplComponentsAbsynProgramEnvEnv;
  output tuple<Absyn.Class, Option<Absyn.Path>, tuple<Components, Absyn.Program, Env.Env>> outTplAbsynClassAbsynPathOptionTplComponentsAbsynProgramEnvEnv;
algorithm
  outTplAbsynClassAbsynPathOptionTplComponentsAbsynProgramEnvEnv:=
  matchcontinue (inTplAbsynClassAbsynPathOptionTplComponentsAbsynProgramEnvEnv)
    local
      Absyn.Path path_1,pa_1,pa;
      Option<Absyn.Path> paOpt;
      list<Env.Frame> cenv,env;
      Components comps_1,comps;
      Absyn.Class class_;
      String id;
      Boolean a,b,c;
      Absyn.Restriction d;
      Absyn.ClassDef e;
      Absyn.Info file_info;
      Absyn.Program p;
    case (((class_ as Absyn.CLASS(name = id,partialPrefix = a,finalPrefix = b,encapsulatedPrefix = c,restriction = d,body = e,info = file_info)),SOME(pa),(comps,p,env)))
      equation
        false = isReadOnly(file_info);
        path_1 = Absyn.joinPaths(pa, Absyn.IDENT(id));
        cenv = Dependency.getClassEnvNoElaboration(p, path_1, env);
        (_,pa_1) = Inst.makeFullyQualified(Env.emptyCache(), cenv, path_1);
        comps_1 = extractComponentsFromClass(class_, pa_1, comps, cenv);
      then
        ((class_,SOME(pa),(comps_1,p,env)));
    case (((class_ as Absyn.CLASS(name = id,partialPrefix = a,finalPrefix = b,encapsulatedPrefix = c,restriction = d,body = e,info = file_info)),NONE(),(comps,p,env)))
      equation
        false = isReadOnly(file_info);
        path_1 = Absyn.IDENT(id);

        cenv = Dependency.getClassEnvNoElaboration(p, path_1, env);
        (_,pa_1) = Inst.makeFullyQualified(Env.emptyCache(),cenv, path_1);
        comps_1 = extractComponentsFromClass(class_, pa_1, comps, cenv);
      then
        ((class_,NONE(),(comps_1,p,env)));
    case ((class_ ,paOpt,(comps,p,env))) then   ((class_,paOpt,(comps,p,env)));
  end matchcontinue;
end extractAllComponentsVisitor;

protected function isReadOnly
  input Absyn.Info file_info;
  output Boolean res;
algorithm
  res := match(file_info)
    case(Absyn.INFO(isReadOnly = res)) then res;
  end match;
end isReadOnly;

protected function extractComponentsFromClass
"author: x02lucpo
  help function to extractAllComponentsVisitor"
  input Absyn.Class inClass;
  input Absyn.Path inPath;
  input Components inComponents;
  input Env.Env inEnv;
  output Components outComponents;
algorithm
  outComponents:=
  matchcontinue (inClass,inPath,inComponents,inEnv)
    local
      Components comps_1,comps;
      String id;
      Absyn.ClassDef classdef;
      Absyn.Info info;
      Absyn.Path pa;
      list<Env.Frame> env;
    case (Absyn.CLASS(name = id,body = classdef,info = info),pa,comps,env) /* the QUALIFIED path */
      equation
        comps_1 = extractComponentsFromClassdef(pa, classdef, comps, env);
      then
        comps_1;
    case (_,_,comps,env)
      equation
        print("-extract_components_from_class failed\n");
      then
        fail();
  end matchcontinue;
end extractComponentsFromClass;

protected function extractComponentsFromClassdef
"author: x02lucpo
  help function to extractAllComponentsVisitor"
  input Absyn.Path inPath;
  input Absyn.ClassDef inClassDef;
  input Components inComponents;
  input Env.Env inEnv;
  output Components outComponents;
algorithm
  outComponents:= matchcontinue (inPath,inClassDef,inComponents,inEnv)
    local
      Components comps_1,comps;
      Absyn.Path pa,path;
      list<Absyn.ClassPart> parts;
      list<Env.Frame> env;
      list<Absyn.ElementArg> elementargs,elementarg;
      String id_ex;
    case (pa,Absyn.PARTS(classParts = parts),comps,env) /* the QUALIFIED path for the class */
      equation
        comps_1 = extractComponentsFromClassparts(pa, parts, comps, env);
      then
        comps_1;
    case (pa,Absyn.DERIVED(typeSpec=Absyn.TPATH(path,_),arguments = elementargs),comps,env)
      equation
        comps_1 = extractComponentsFromElementargs(pa, elementargs, comps, env)
        "& print \"extract_components_from_classdef for DERIVED not implemented yet\\n\"" ;
      then
        comps_1;
    case (pa,Absyn.CLASS_EXTENDS(baseClassName = id_ex,modifications = elementarg,parts = parts),comps,env)
      equation
        comps_1 = extractComponentsFromClassparts(pa, parts, comps, env);
      then
        comps_1;
    case (pa,_,comps,env) then comps;
  end matchcontinue;
end extractComponentsFromClassdef;

protected function extractComponentsFromClassparts
"author: x02lucpo
  help function to extractAllComponentsVisitor"
  input Absyn.Path inPath;
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Components inComponents;
  input Env.Env inEnv;
  output Components outComponents;
algorithm
  outComponents:= matchcontinue (inPath,inAbsynClassPartLst,inComponents,inEnv)
    local
      Components comps,comps_1,comps_2;
      list<Env.Frame> env;
      Absyn.Path pa;
      list<Absyn.ElementItem> elements;
      list<Absyn.ClassPart> res;
    case (_,{},comps,env) then comps;  /* the QUALIFIED path for the class */
    case (pa,(Absyn.PUBLIC(contents = elements) :: res),comps,env)
      equation
        comps_1 = extractComponentsFromClassparts(pa, res, comps, env);
        comps_2 = extractComponentsFromElements(pa, elements, comps_1, env);
      then
        comps_2;
    case (pa,(Absyn.PROTECTED(contents = elements) :: res),comps,env)
      equation
        comps_1 = extractComponentsFromClassparts(pa, res, comps, env);
        comps_2 = extractComponentsFromElements(pa, elements, comps_1, env);
      then
        comps_2;
    case (_,_,comps,env) then comps;
  end matchcontinue;
end extractComponentsFromClassparts;

protected function extractComponentsFromElements
"author: x02lucpo
  help function to extractAllComponentsVisitor"
  input Absyn.Path inPath;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Components inComponents;
  input Env.Env inEnv;
  output Components outComponents;
algorithm
  outComponents:=
  matchcontinue (inPath,inAbsynElementItemLst,inComponents,inEnv)
    local
      Components comps,comps_1,comps_2;
      list<Env.Frame> env;
      Absyn.Path pa;
      Absyn.ElementSpec elementspec;
      list<Absyn.ElementItem> res;
      Absyn.ElementItem element;
    case (_,{},comps,env) then comps;  /* the QUALIFIED path for the class */
    case (pa,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = elementspec)) :: res),comps,env)
      equation
        comps_1 = extractComponentsFromElements(pa, res, comps, env);
        comps_2 = extractComponentsFromElementspec(pa, elementspec, comps_1, env);
      then
        comps_2;
    case (pa,(element :: res),comps,env)
      equation
        comps_1 = extractComponentsFromElements(pa, res, comps, env);
      then
        comps;
  end matchcontinue;
end extractComponentsFromElements;

protected function extractComponentsFromElementspec
"author: x02lucpo
  help function to extractAllComponentsVisitor"
  input Absyn.Path inPath;
  input Absyn.ElementSpec inElementSpec;
  input Components inComponents;
  input Env.Env inEnv;
  output Components outComponents;
algorithm
  outComponents:=
  matchcontinue (inPath,inElementSpec,inComponents,inEnv)
    local
      String id;
      list<Env.Frame> cenv,env;
      Absyn.Path path_1,path,pa;
      Components comps_1,comps,comps_2;
      list<Absyn.ComponentItem> comp_items;
      Component comp;
      list<Absyn.ElementArg> elementargs;
      Env.Cache cache;

    case (pa,Absyn.COMPONENTS(typeSpec = Absyn.TPATH(path_1,_),components = comp_items),comps,env) /* the QUALIFIED path for the class */
      equation
        (cache,SCode.CLASS(name=id),cenv) = Lookup.lookupClass(Env.emptyCache(),env, path_1, false);
        path_1 = Absyn.IDENT(id);
        (cache,path) = Inst.makeFullyQualified(cache, cenv, path_1);
        comps_1 = extractComponentsFromComponentitems(pa, path, comp_items, comps, env);
      then
        comps_1;
    case (pa,Absyn.EXTENDS(path = path_1,elementArg = elementargs),comps,env)
      equation
        (cache,_,cenv) = Lookup.lookupClass(Env.emptyCache(),env, path_1, false)
        "print \"extract_components_from_elementspec Absyn.EXTENDS(path,_) not implemented yet\"" ;
        (_,path) = Inst.makeFullyQualified(cache,cenv, path_1);
        comp = EXTENDSITEM(pa,path);
        comps_1 = addComponentToComponents(comp, comps);
        comps_2 = extractComponentsFromElementargs(pa, elementargs, comps_1, env);
      then
        comps_2;
    case (_,_,comps,env) then comps;
      /* rule  extract_components_from_class(class,pa,comps,env) => comps\'
         -------------------------------
         extract_components_from_elementspec(pa,Absyn.CLASSDEF(_,class), comps,env) => comps\' */
  end matchcontinue;
end extractComponentsFromElementspec;

protected function extractComponentsFromComponentitems
"author: x02lucpo
  help function to extractAllComponentsVisitor"
  input Absyn.Path inPath1;
  input Absyn.Path inPath2;
  input list<Absyn.ComponentItem> inAbsynComponentItemLst3;
  input Components inComponents4;
  input Env.Env inEnv5;
  output Components outComponents;
algorithm
  outComponents:=
  matchcontinue (inPath1,inPath2,inAbsynComponentItemLst3,inComponents4,inEnv5)
    local
      Components comps,comps_1,comps_2,comps_3;
      list<Env.Frame> env;
      Absyn.ComponentRef comp;
      Absyn.Path pa,path;
      String id;
      Option<Absyn.Modification> mod_opt;
      list<Absyn.ComponentItem> res;
    case (_,_,{},comps,env) then comps;  /* the QUALIFIED path for the class the fully qualifired path for the type of the component */
    case (pa,path,(Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,modification = mod_opt)) :: res),comps,env)
      equation
        comps_1 = extractComponentsFromComponentitems(pa, path, res, comps, env);
        comp = Absyn.CREF_IDENT(id,{});
        comps_2 = addComponentToComponents(COMPONENTITEM(pa,path,comp), comps_1);
        comps_3 = extractComponentsFromModificationOption(pa, mod_opt, comps_2, env);
      then
        comps_3;
    case (_,_,_,_,env)
      equation
        print("-extract_components_from_componentitems failed\n");
      then
        fail();
  end matchcontinue;
end extractComponentsFromComponentitems;

protected function extractComponentsFromElementargs
  input Absyn.Path inPath;
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input Components inComponents;
  input Env.Env inEnv;
  output Components outComponents;
algorithm
  outComponents:=
  matchcontinue (inPath,inAbsynElementArgLst,inComponents,inEnv)
    local
      Absyn.Path pa;
      Components comps,comps_1,comps_2,comps_3;
      list<Env.Frame> env;
      Absyn.ElementSpec elementspec,elementspec2;
      list<Absyn.ElementArg> res;
      Absyn.ConstrainClass constrainclass;
      Option<Absyn.Modification> mod_opt;
      Absyn.ElementArg a;
    case (pa,{},comps,env) then comps;  /* the QUALIFIED path for the class */
    case (pa,(Absyn.REDECLARATION(elementSpec = elementspec,constrainClass = SOME(Absyn.CONSTRAINCLASS(elementspec2,_))) :: res),comps,env)
      equation
        comps_1 = extractComponentsFromElementspec(pa, elementspec, comps, env);
        comps_2 = extractComponentsFromElementspec(pa, elementspec2, comps_1, env);
        comps_3 = extractComponentsFromElementargs(pa, res, comps_2, env);
      then
        comps_3;
    case (pa,(Absyn.REDECLARATION(elementSpec = elementspec,constrainClass = SOME(constrainclass)) :: res),comps,env)
      equation
        comps_1 = extractComponentsFromElementspec(pa, elementspec, comps, env);
        comps_2 = extractComponentsFromElementargs(pa, res, comps_1, env);
      then
        comps_2;
    case (pa,(Absyn.MODIFICATION(modification = mod_opt) :: res),comps,env)
      equation
        comps_1 = extractComponentsFromModificationOption(pa, mod_opt, comps, env);
        comps_2 = extractComponentsFromElementargs(pa, res, comps_1, env);
      then
        comps_2;
    case (pa,(a :: res),comps,env)
      equation
        comps_1 = extractComponentsFromElementargs(pa, res, comps, env);
      then
        comps_1;
  end matchcontinue;
end extractComponentsFromElementargs;

protected function extractComponentsFromModificationOption
  input Absyn.Path inPath;
  input Option<Absyn.Modification> inAbsynModificationOption;
  input Components inComponents;
  input Env.Env inEnv;
  output Components outComponents;
algorithm
  outComponents:=
  match (inPath,inAbsynModificationOption,inComponents,inEnv)
    local
      Absyn.Path pa;
      Components comps,comps_1;
      list<Env.Frame> env;
      list<Absyn.ElementArg> elementargs;
    case (pa,NONE(),comps,env) then comps;  /* the QUALIFIED path for the class */
    case (pa,SOME(Absyn.CLASSMOD(elementargs,_)),comps,env)
      equation
        comps_1 = extractComponentsFromElementargs(pa, elementargs, comps, env);
      then
        comps_1;
  end match;
end extractComponentsFromModificationOption;

protected function joinComponents
"author: x02lucpo
 joins two components lists by union"
  input Components inComponents1;
  input Components inComponents2;
  output Components outComponents;
algorithm
  outComponents:=
  matchcontinue (inComponents1,inComponents2)
    local
      list<Component> comps,comps1,comps2;
      Integer len,len1,len2;
    case (COMPONENTS(componentLst = comps1,the = len1),COMPONENTS(componentLst = comps2,the = len2))
      equation
        comps = List.union(comps1, comps2);
        len = listLength(comps);
      then
        COMPONENTS(comps,len);
  end matchcontinue;
end joinComponents;

protected function existsComponentInComponents
"author: x02lucpo
 checks if a component exists in the components"
  input Components inComponents;
  input Component inComponent;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inComponents,inComponent)
    local
      Component comp;
      Absyn.Path a,b,ap,bp;
      Absyn.ComponentRef c,cr;
      Components comps;
      Boolean res;
    case (COMPONENTS(componentLst = {}),comp) then false;
    case (comps,COMPONENTITEM(the1 = ap,the2 = bp,the3 = cr))
      equation
        COMPONENTITEM(a,b,c) = firstComponent(comps);
        true = Absyn.pathEqual(a, ap);
        true = Absyn.pathEqual(b, bp);
        true = Absyn.crefEqual(c, cr);
      then
        true;
    case (comps,EXTENDSITEM(the1 = ap,the2 = bp))
      equation
        EXTENDSITEM(a,b) = firstComponent(comps);
        true = Absyn.pathEqual(a, ap);
        true = Absyn.pathEqual(b, bp);
      then
        true;
    case (comps,comp)
      equation
        res = existsComponentInComponents(comps, comp);
      then
        res;
  end matchcontinue;
end existsComponentInComponents;

protected function emptyComponents
"author: x02lucpo
  returns true if the components are empty"
  input Components inComponents;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inComponents)
    case (COMPONENTS(componentLst = {})) then true;
    case (_) then false;
  end matchcontinue;
end emptyComponents;

protected function firstComponent
"author: x02lucpo
 extract the first component in the components"
  input Components inComponents;
  output Component outComponent;
algorithm
  outComponent:=
  match (inComponents)
    local
      Component comp;
      list<Component> res;
    case (COMPONENTS(componentLst = {}))
      equation
        print("-first_component failed: no components\n");
      then
        fail();
    case (COMPONENTS(componentLst = (comp :: res))) then comp;
  end match;
end firstComponent;

protected function restComponents
"author: x02lucpo
 extract the rest components from the compoents"
  input Components inComponents;
  output Components outComponents;
algorithm
  outComponents:=
  match (inComponents)
    local
      Integer len_1,len;
      Component comp;
      list<Component> res;
    case (COMPONENTS(componentLst = {})) then COMPONENTS({},0);
    case (COMPONENTS(componentLst = (comp :: res),the = len))
      equation
        len_1 = len - 1;
      then
        COMPONENTS(res,len_1);
  end match;
end restComponents;

protected function lengthComponents
"author: x02lucpo
  return the number of the components"
  input Components inComponents;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inComponents)
    local Integer len;
    case (COMPONENTS(the = len)) then len;
  end matchcontinue;
end lengthComponents;

protected function addComponentToComponents
"author: x02lucpo
  add a component to components"
  input Component inComponent;
  input Components inComponents;
  output Components outComponents;
algorithm
  outComponents:=
  match (inComponent,inComponents)
    local
      Integer len_1,len;
      Component comp;
      list<Component> comps;
    case (comp,COMPONENTS(componentLst = comps,the = len))
      equation
        len_1 = len + 1;
      then
        COMPONENTS((comp :: comps),len_1);
  end match;
end addComponentToComponents;

protected function dumpComponentsToString
"author: x02lucpo
  dumps all the components to string"
  input Components inComponents;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponents)
    local
      Components res,comps;
      String s1,pa_str,path_str,cr_str,res_str;
      Absyn.Path cr_pa,pa,path;
      Absyn.ComponentRef cr;
    case (COMPONENTS(componentLst = {})) then "";
    case ((comps as COMPONENTS(componentLst = (COMPONENTITEM(the1 = pa,the2 = path,the3 = cr) :: _))))
      equation
        res = restComponents(comps);
        s1 = dumpComponentsToString(res);
        pa_str = Absyn.pathString(pa);
        path_str = Absyn.pathString(path);
        cr_pa = Absyn.crefToPath(cr);
        cr_str = Absyn.pathString(cr_pa);
        res_str = stringAppendList({s1,"cl: ",pa_str,"\t type: ",path_str,"\t\t name: ",cr_str,"\n"});
      then
        res_str;
    case ((comps as COMPONENTS(componentLst = (EXTENDSITEM(the1 = pa,the2 = path) :: _))))
      equation
        res = restComponents(comps);
        s1 = dumpComponentsToString(res);
        pa_str = Absyn.pathString(pa);
        path_str = Absyn.pathString(path);
        res_str = stringAppendList({s1,"ex: ",pa_str,"\t exte: ",path_str,"\n"});
      then
        res_str;
  end matchcontinue;
end dumpComponentsToString;

protected function isParameterElement
"function: isParameterElement
   Returns true if Element is a component of
   variability parameter, false otherwise."
  input Absyn.Element inElement;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inElement)
    case (Absyn.ELEMENT(specification = Absyn.COMPONENTS(attributes = Absyn.ATTR(variability = Absyn.PARAM())))) then true;
    case (_) then false;
  end matchcontinue;
end isParameterElement;

protected function getParameterNames
"function: getParameterNames
   Retrieves the names of all parameters in the class
   inputs:  (Absyn.ComponentRef, /* class */
               Absyn.Program)
   outputs:  string"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path p_class;
      Absyn.Class cdef;
      list<Absyn.Element> comps,comps_1;
      list<list<Absyn.ComponentItem>> compelts;
      list<Absyn.ComponentItem> compelts_1;
      list<String> names;
      String res,res_1;
      Absyn.ComponentRef class_;
      Absyn.Program p;
    case (class_,p)
      equation
        p_class = Absyn.crefToPath(class_);
        cdef = getPathedClassInProgram(p_class, p);
        comps = getComponentsInClass(cdef);
        comps_1 = List.select(comps, isParameterElement);
        compelts = List.map(comps_1, getComponentitemsInElement);
        compelts_1 = List.flatten(compelts);
        names = List.map(compelts_1, getComponentitemName);
        res = stringDelimitList(names, ", ");
        res_1 = stringAppendList({"{",res,"}"});
      then
        res_1;
    case (_,_) then "Error";
  end matchcontinue;
end getParameterNames;

public function getClassEnv
"function: getClassEnv
   Retrieves the environment of the class,
   including the frame of the class itself
   by partially instantiating it."
  input Absyn.Program p;
  input Absyn.Path p_class;
  output Env.Env env_2;
protected
  list<SCode.Element> p_1;
  list<Env.Frame> env,env_1,env2;
  SCode.Element cl;
  String id;
  SCode.Encapsulated encflag;
  SCode.Restriction restr;
  ClassInf.State ci_state;
  Env.Cache cache;
algorithm
  env_2 := matchcontinue (p,p_class)
    local
      Absyn.Path tp;
    case (p,p_class) // Special case for derived classes. When instantiating a derived class, the environment
                     // of the derived class is returned, which can be a totally different scope.
      equation
        p_1 = SCodeUtil.translateAbsyn2SCode(p);
        (cache,env) = Inst.makeEnvFromProgram(Env.emptyCache(),p_1, Absyn.IDENT(""));
        (cache,(cl as SCode.CLASS(name=id,encapsulatedPrefix=encflag,restriction=restr,classDef=SCode.DERIVED(typeSpec=Absyn.TPATH(tp,_)))),env_1) =
        Lookup.lookupClass(cache,env, p_class, false);
      then env_1;

    case (p,p_class)
      equation
        p_1 = SCodeUtil.translateAbsyn2SCode(p);
        (cache,env) = Inst.makeEnvFromProgram(Env.emptyCache(),p_1, Absyn.IDENT(""));
        (cache,(cl as SCode.CLASS(name=id,encapsulatedPrefix=encflag,restriction=restr)),env_1) = Lookup.lookupClass(cache,env, p_class, false);
        env2 = Env.openScope(env_1, encflag, SOME(id), Env.restrictionToScopeType(restr));
        ci_state = ClassInf.start(restr, Env.getEnvName(env2));
        (_,env_2,_,_) =
          Inst.partialInstClassIn(cache,env2,InnerOuter.emptyInstHierarchy,
            DAE.NOMOD(), Prefix.NOPRE(), ci_state, cl, SCode.PUBLIC(), {});
      then env_2;
    case (p,p_class) then {};
  end matchcontinue;
end getClassEnv;

protected function setComponentProperties
"function: setComponentProperties
  Sets the following \"properties\" of a component.
  - final
  - flow
  - stream
  - protected(true) or public(false)
  - replaceable
  - variablity: \"constant\" or \"discrete\" or \"parameter\" or \"\"
  - dynamic_ref: {inner, outer} - two boolean values.
  - causality: \"input\" or \"output\" or \"\"

  inputs:  (Absyn.Path, /* class */
            Absyn.ComponentRef, /* component_ref */
            bool, /* final = true */
            bool, /* flow = true */
            bool, /* stream = true */
            bool, /* protected = true, public=false */
            bool,  /* replaceable = true */
            string, /* parallelism */
            string, /* variability */
            bool list, /* dynamic_ref, two booleans */
            string, /* causality */
            Absyn.Program)
  outputs: (string, Absyn.Program)"
  input Absyn.Path inPath1;
  input Absyn.ComponentRef inComponentRef2;
  input Boolean inFinal;
  input Boolean inFlow;
  input Boolean inStream;
  input Boolean inProtected;
  input Boolean inReplaceable;
  // input String inString6;  //parallelism removed for now
  input String inString7;
  input list<Boolean> inBooleanLst8;
  input String inString9;
  input Absyn.Program inProgram10;
  output String outString;
  output Absyn.Program outProgram;
algorithm
  (outString,outProgram):=
  matchcontinue (inPath1,inComponentRef2,inFinal,inFlow,inStream,inProtected,inReplaceable,/*inString6,*/inString7,inBooleanLst8,inString9,inProgram10)
    local
      Absyn.Within within_;
      Absyn.Class cdef,cdef_1;
      Absyn.Program newp,p;
      Absyn.Path p_class;
      String varname,parallelism,variability,causality;
      Boolean finalPrefix,flowPrefix,streamPrefix,prot,repl;
      list<Boolean> dyn_ref;
      Absyn.TimeStamp ts;
    case (p_class,Absyn.CREF_IDENT(name = varname),finalPrefix,flowPrefix,streamPrefix,prot,repl, /*parallelism,*/ variability,dyn_ref,causality,p as Absyn.PROGRAM(globalBuildTimes=ts))
      equation
        within_ = buildWithin(p_class);
        cdef = getPathedClassInProgram(p_class, p);
        cdef_1 = setComponentPropertiesInClass(cdef, varname, finalPrefix, flowPrefix, streamPrefix, prot, repl, "" /*parallelism*/, variability, dyn_ref, causality);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},within_,ts), p);
      then
        ("Ok",newp);
    case (_,_,_,_,_,_,_,/*_,*/_,_,_,p) then ("Error",p);
  end matchcontinue;
end setComponentProperties;

protected function setComponentPropertiesInClass
"function: setComponentPropertiesInClass
  Helper function to setComponentProperties.
  inputs:  (Absyn.Class,
              string, /* comp_name */
              bool, /* final */
              bool, /* flow */
              bool, /* stream */
              bool, /* prot */
              bool, /* repl */
              string, /* parallelism */
              string, /* variability */
              bool list, /* dynamic_ref, two booleans */
              string) /* causality */
  outputs: Absyn.Class "
  input Absyn.Class inClass1;
  input String inString2;
  input Boolean inFinal;
  input Boolean inFlow;
  input Boolean inStream;
  input Boolean inProtected;
  input Boolean inReplaceable;
  input String inString6;
  input String inString7;
  input list<Boolean> inBooleanLst8;
  input String inString9;
  output Absyn.Class outClass;
algorithm
  outClass:=
  match (inClass1,inString2,inFinal,inFlow,inStream,inProtected,inReplaceable,inString6,inString7,inBooleanLst8,inString9)
    local
      list<Absyn.ClassPart> parts_1,parts;
      String id,varname,parallelism,variability,causality,bcname;
      Boolean p,f,e,finalPrefix,flowPrefix,streamPrefix,prot,repl;
      Absyn.Restriction r;
      Option<String> cmt;
      Absyn.Info file_info;
      list<Boolean> dyn_ref;
      list<Absyn.ElementArg> mod;
      list<String> typeVars;

    /* a class with parts! */
    case (Absyn.CLASS(name = id,
                      partialPrefix = p,
                      finalPrefix = f,
                      encapsulatedPrefix = e,
                      restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars,classParts = parts,comment = cmt),
                      info = file_info),varname,finalPrefix,flowPrefix,streamPrefix, prot,repl,parallelism,variability,dyn_ref,causality)
      equation
        parts_1 = setComponentPropertiesInClassparts(parts, varname, finalPrefix, flowPrefix, streamPrefix, prot, repl, parallelism, variability, dyn_ref, causality);
      then
        Absyn.CLASS(id,p,f,e,r,Absyn.PARTS(typeVars,parts_1,cmt),file_info);

    /* adrpo: handle also an extended class with parts! */
    case (Absyn.CLASS(name = id,
                      partialPrefix = p,
                      finalPrefix = f,
                      encapsulatedPrefix = e,
                      restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName=bcname, modifications=mod, parts = parts,comment = cmt),
                      info = file_info),varname,finalPrefix,flowPrefix,streamPrefix, prot,repl,parallelism,variability,dyn_ref,causality)
      equation
        parts_1 = setComponentPropertiesInClassparts(parts, varname, finalPrefix, flowPrefix, streamPrefix, prot, repl, parallelism, variability, dyn_ref, causality);
      then
        Absyn.CLASS(id,p,f,e,r,Absyn.CLASS_EXTENDS(bcname,mod,cmt,parts_1),file_info);

  end match;
end setComponentPropertiesInClass;

protected function setComponentPropertiesInClassparts
"function: setComponentPropertiesInClassparts
   Helper function to setComponentPropertiesInClass.
   inputs: (Absyn.ClassPart list,
              Absyn.Ident, /* comp_name */
              bool, /* final */
              bool, /* flow */
              bool, /* stream */
              bool, /* prot */
              bool, /* repl */
              string, /* parallelism */
              string, /* variability */
              bool list, /* dynamic_ref, two booleans */
              string) /* causality */
   outputs: Absyn.ClassPart list"
  input list<Absyn.ClassPart> inAbsynClassPartLst1;
  input Absyn.Ident inIdent2;
  input Boolean inFinal;
  input Boolean inFlow;
  input Boolean inStream;
  input Boolean inProtected;
  input Boolean inReplaceable;
  input String inString6;
  input String inString7;
  input list<Boolean> inBooleanLst8;
  input String inString9;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst1,inIdent2,inFinal,inFlow,inStream,inProtected,inReplaceable,inString6,inString7,inBooleanLst8,inString9)
    local
      list<Absyn.ElementItem> publst,publst_1,protlst,protlst_1,elts_1,elts;
      Absyn.Element elt,elt_1;
      list<Absyn.ClassPart> parts_1,parts_2,parts,rest,rest_1;
      String cr,parallelism,variability,causality;
      Boolean finalPrefix,flowPrefix,streamPrefix,repl,prot;
      list<Boolean> dyn_ref;
      Absyn.ClassPart part;

    case ({},_,_,_,_,_,_,_,_,_,_) then {};
    case (parts,cr,finalPrefix,flowPrefix,streamPrefix,true,repl,parallelism,variability,dyn_ref,causality) /* public moved to protected protected moved to public */
      equation
        publst = getPublicList(parts);
        Absyn.ELEMENTITEM(elt) = getElementitemContainsName(Absyn.CREF_IDENT(cr,{}), publst);
        elt_1 = setComponentPropertiesInElement(elt, cr, finalPrefix, flowPrefix, streamPrefix, repl, parallelism, variability, dyn_ref, causality);
        publst_1 = deleteComponentFromElementitems(cr, publst);
        protlst = getProtectedList(parts);
        protlst_1 = listAppend(protlst, {Absyn.ELEMENTITEM(elt_1)});
        parts_1 = replaceProtectedList(parts, protlst_1);
        parts_2 = replacePublicList(parts_1, publst_1);
      then
        parts_2;

    case (parts,cr,finalPrefix,flowPrefix,streamPrefix,false,repl,parallelism,variability,dyn_ref,causality) /* protected moved to public protected attr not changed. */
      equation
        protlst = getProtectedList(parts);
        Absyn.ELEMENTITEM(elt) = getElementitemContainsName(Absyn.CREF_IDENT(cr,{}), protlst);
        elt_1 = setComponentPropertiesInElement(elt, cr, finalPrefix, flowPrefix, streamPrefix, repl, parallelism, variability, dyn_ref, causality);
        protlst_1 = deleteComponentFromElementitems(cr, protlst);
        publst = getPublicList(parts);
        publst_1 = listAppend(publst, {Absyn.ELEMENTITEM(elt_1)});
        parts_1 = replacePublicList(parts, publst_1);
        parts_2 = replaceProtectedList(parts_1, protlst_1);
      then
        parts_2;

    case ((Absyn.PUBLIC(contents = elts) :: rest),cr,finalPrefix,flowPrefix,streamPrefix,prot,repl,parallelism,variability,dyn_ref,causality) /* protected attr not changed. protected attr not changed, 2. */
      equation
        rest = setComponentPropertiesInClassparts(rest, cr, finalPrefix, flowPrefix, streamPrefix, prot, repl, parallelism, variability, dyn_ref, causality);
        elts_1 = setComponentPropertiesInElementitems(elts, cr, finalPrefix, flowPrefix, streamPrefix, repl, parallelism, variability, dyn_ref, causality);
      then
        (Absyn.PUBLIC(elts_1) :: rest);

    case ((Absyn.PROTECTED(contents = elts) :: rest),cr,finalPrefix,flowPrefix,streamPrefix, prot,repl,parallelism,variability,dyn_ref,causality) /* protected attr not changed, 2. */
      equation
        rest = setComponentPropertiesInClassparts(rest, cr, finalPrefix, flowPrefix, streamPrefix, prot, repl, parallelism, variability, dyn_ref, causality);
        elts_1 = setComponentPropertiesInElementitems(elts, cr, finalPrefix, flowPrefix, streamPrefix, repl, parallelism, variability, dyn_ref, causality);
      then
        (Absyn.PROTECTED(elts_1) :: rest);

    case ((part :: rest),cr,finalPrefix,flowPrefix,streamPrefix, prot,repl,parallelism,variability,dyn_ref,causality) /* protected attr not changed, 3. */
      equation
        rest_1 = setComponentPropertiesInClassparts(rest, cr, finalPrefix, flowPrefix, streamPrefix, prot, repl, parallelism, variability, dyn_ref, causality);
      then
        (part :: rest_1);

  end matchcontinue;
end setComponentPropertiesInClassparts;

protected function setComponentPropertiesInElementitems
"function: setComponentPropertiesInElementitems
  Helper function to setComponentPropertiesInClassparts.
  inputs:  (Absyn.ElementItem list,
              Absyn.Ident, /* comp_name */
              bool, /* final */
              bool, /* flow */
              bool, /* stream */
              bool, /* repl */
              string, /* parallelism */
              string, /* variability */
              bool list, /* dynamic_ref, two booleans */
              string) /* causality */
  outputs:  Absyn.ElementItem list"
  input list<Absyn.ElementItem> inAbsynElementItemLst1;
  input Absyn.Ident inIdent2;
  input Boolean inFinal;
  input Boolean inFlow;
  input Boolean inStream;
  input Boolean inReplaceable;
  input String inString5;
  input String inString6;
  input list<Boolean> inBooleanLst7;
  input String inString8;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm
  outAbsynElementItemLst:=
  matchcontinue (inAbsynElementItemLst1,inIdent2,inFinal,inFlow,inStream,inReplaceable,inString5,inString6,inBooleanLst7,inString8)
    local
      list<Absyn.ElementItem> res,rest;
      Absyn.Element elt_1,elt;
      String cr,prl,va,cau;
      Boolean finalPrefix,flowPrefix,streamPrefix,repl;
      list<Boolean> dr;
      Absyn.ElementItem elitem;

    case ({},_,_,_,_,_,_,_,_,_) then {};
    case ((Absyn.ELEMENTITEM(element = elt) :: rest),cr,finalPrefix,flowPrefix,streamPrefix, repl,prl,va,dr,cau)
      equation
        res = setComponentPropertiesInElementitems(rest, cr, finalPrefix, flowPrefix, streamPrefix, repl, prl, va, dr, cau);
        elt_1 = setComponentPropertiesInElement(elt, cr, finalPrefix, flowPrefix, streamPrefix, repl, prl, va, dr, cau);
      then
        (Absyn.ELEMENTITEM(elt_1) :: res);

    case ((elitem :: rest),cr,finalPrefix,flowPrefix,streamPrefix,repl,prl,va,dr,cau)
      equation
        res = setComponentPropertiesInElementitems(rest, cr, finalPrefix, flowPrefix, streamPrefix, repl, prl, va, dr, cau);
      then
        (elitem :: res);
  end matchcontinue;
end setComponentPropertiesInElementitems;

protected function setComponentPropertiesInElement
"function: setComponentPropertiesInElement
  Helper function to e.g. setComponentPropertiesInElementitems.
  inputs:  (Absyn.Element,
              Absyn.Ident,
              bool, /* final */
              bool, /* flow */
              bool, /* stream */
              bool, /* repl */
              string, /* parallelism */
              string, /* variability */
              bool list, /* dynamic_ref, two booleans */
              string) /* causality */
  outputs: Absyn.Element"
  input Absyn.Element inElement1;
  input Absyn.Ident inIdent2;
  input Boolean inFinal;
  input Boolean inFlow;
  input Boolean inStream;
  input Boolean inReplaceable;
  input String inString5;
  input String inString6;
  input list<Boolean> inBooleanLst7;
  input String inString8;
  output Absyn.Element outElement;
algorithm
  outElement:=
  matchcontinue (inElement1,inIdent2,inFinal,inFlow,inStream,inReplaceable,inString5,inString6,inBooleanLst7,inString8)
    local
      Option<Absyn.RedeclareKeywords> redeclkw_1,redeclkw;
      Absyn.InnerOuter inout_1,inout;
      Absyn.ElementSpec spec_1,spec;
      String id,cr,va,cau,prl;
      list<Absyn.ComponentItem> ellst;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constr;
      Boolean finalPrefix,flowPrefix,streamPrefix,repl;
      list<Boolean> dr;
      Absyn.Element elt;
    case (Absyn.ELEMENT(redeclareKeywords = redeclkw,innerOuter = inout,name = id,
          specification = (spec as Absyn.COMPONENTS(components = ellst)),info = info,constrainClass = constr),
          cr,finalPrefix,flowPrefix,streamPrefix,repl,prl,va,dr,cau)
      equation
        _ = getCompitemNamed(Absyn.CREF_IDENT(cr,{}), ellst);
        redeclkw_1 = setReplaceableKeywordAttributes(redeclkw, repl);
        inout_1 = setInnerOuterAttributes(dr);
        spec_1 = setComponentPropertiesInElementspec(spec, cr, flowPrefix, streamPrefix, prl, va, cau);
      then
        Absyn.ELEMENT(finalPrefix,redeclkw_1,inout_1,id,spec_1,info,constr);
    case (elt,cr,_,_,_,_,_,_,_,_) then elt;
  end matchcontinue;
end setComponentPropertiesInElement;

protected function setReplaceableKeywordAttributes
"function: setReplaceableKeywordAttributes
  Sets The RedeclareKeywords of an Element given a boolean \'replaceable\'.
  inputs:  (Absyn.RedeclareKeywords option,
              bool /* repl */)
  outputs: Absyn.RedeclareKeywords option ="
  input Option<Absyn.RedeclareKeywords> inAbsynRedeclareKeywordsOption;
  input Boolean inBoolean;
  output Option<Absyn.RedeclareKeywords> outAbsynRedeclareKeywordsOption;
algorithm
  outAbsynRedeclareKeywordsOption:=
  match (inAbsynRedeclareKeywordsOption,inBoolean)
    case (NONE(),false) then NONE();  /* false */
    case (SOME(Absyn.REPLACEABLE()),false) then NONE();
    case (SOME(Absyn.REDECLARE_REPLACEABLE()),false) then SOME(Absyn.REDECLARE());
    case (SOME(Absyn.REDECLARE()),false) then SOME(Absyn.REDECLARE());
    case (NONE(),true) then SOME(Absyn.REPLACEABLE());  /* true */
    case (SOME(Absyn.REDECLARE()),true) then SOME(Absyn.REDECLARE_REPLACEABLE());
    case (SOME(Absyn.REPLACEABLE()),true) then SOME(Absyn.REPLACEABLE());
    case (SOME(Absyn.REDECLARE_REPLACEABLE()),true) then SOME(Absyn.REDECLARE_REPLACEABLE());
  end match;
end setReplaceableKeywordAttributes;

protected function setInnerOuterAttributes
"function: setInnerOuterAttributes
  Sets InnerOuter according to a list of two booleans, {inner, outer}."
  input list<Boolean> inBooleanLst;
  output Absyn.InnerOuter outInnerOuter;
algorithm
  outInnerOuter:=
  match (inBooleanLst)
    case ({false,false}) then Absyn.NOT_INNER_OUTER();
    case ({true,false}) then Absyn.INNER();
    case ({false,true}) then Absyn.OUTER();
    case ({true,true}) then Absyn.INNER_OUTER();
  end match;
end setInnerOuterAttributes;

protected function setComponentPropertiesInElementspec
"function: setComponentPropertiesInElementspec
  Sets component attributes on an elements spec if identifier matches.
  inputs:  (Absyn.ElementSpec,
              Absyn.Ident,
              bool, /* flow */
              bool, /* stream */
              string, /* parallelism */
              string, /* variability */
              string) /* causality */
  outputs:  Absyn.ElementSpec"
  input Absyn.ElementSpec inElementSpec1;
  input Absyn.Ident inIdent2;
  input Boolean inFlow;
  input Boolean inStream;
  input String inString3;
  input String inString4;
  input String inString5;
  output Absyn.ElementSpec outElementSpec;
algorithm
  outElementSpec:=
  matchcontinue (inElementSpec1,inIdent2,inFlow,inStream,inString3,inString4,inString5)
    local
      Absyn.ElementAttributes attr_1,attr;
      Absyn.TypeSpec path;
      list<Absyn.ComponentItem> items;
      String cr,va,cau,prl;
      Boolean flowPrefix,streamPrefix;
      Absyn.ElementSpec spec;
    case (Absyn.COMPONENTS(attributes = attr,typeSpec = path,components = items),cr,flowPrefix,streamPrefix,prl,va,cau)
      equation
        itemsContainCompname(items, cr);
        attr_1 = setElementAttributes(attr, flowPrefix, streamPrefix, prl, va, cau);
      then
        Absyn.COMPONENTS(attr_1,path,items);

    case (spec,_,_,_,_,_,_) then spec;
  end matchcontinue;
end setComponentPropertiesInElementspec;

protected function itemsContainCompname
"function: itemsContainCompname
  Checks if a list of ElementItems contain a component named \'cr\'."
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Absyn.Ident inIdent;
algorithm
  _:=
  matchcontinue (inAbsynComponentItemLst,inIdent)
    local
      String cr1,cr2,cr;
      list<Absyn.ComponentItem> rest;
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = cr1)) :: _),cr2)
      equation
        true = stringEq(cr1, cr2);
      then
        ();
    case ((_ :: rest),cr)
      equation
        itemsContainCompname(rest, cr);
      then
        ();
  end matchcontinue;
end itemsContainCompname;

protected function setElementAttributes
"function: setElementAttributes
  Sets  attributes associated with ElementAttribues.
  inputs: (Absyn.ElementAttributes,
             bool, /* flow */
             bool, /* stream */
             string, /* parallelism */
             string, /* variability */
             string) /*causality */
  outputs: Absyn.ElementAttributes"
  input Absyn.ElementAttributes inElementAttributes1;
  input Boolean inFlow;
  input Boolean inStream;
  input String inString2;
  input String inString3;
  input String inString4;
  output Absyn.ElementAttributes outElementAttributes;
algorithm
  outElementAttributes:=
  match (inElementAttributes1,inFlow,inStream,inString2,inString3,inString4)
    local
      Absyn.Parallelism pa_1;
      Absyn.Variability va_1;
      Absyn.Direction cau_1;
      list<Absyn.Subscript> dim;
      Boolean flowPrefix,streamPrefix;
      String va,cau,prl;
    case (Absyn.ATTR(arrayDim = dim),flowPrefix,streamPrefix,prl,va,cau)
      equation
        pa_1 = setElementParallelism(prl);
        va_1 = setElementVariability(va);
        cau_1 = setElementCausality(cau);
      then
        Absyn.ATTR(flowPrefix,streamPrefix,pa_1,va_1,cau_1,dim);
  end match;
end setElementAttributes;

protected function setElementParallelism
"function setElementParallelism
  Sets Parallelism according to string value."
  input String inString;
  output Absyn.Parallelism outParallelism;
algorithm
  outParallelism:=
  match (inString)
    case ("") then Absyn.NON_PARALLEL();
    case ("parglobal") then Absyn.PARGLOBAL();
    case ("parlocal") then Absyn.PARLOCAL();
  end match;
end setElementParallelism;

protected function setElementVariability
"function setElementVariability
  Sets Variability according to string value."
  input String inString;
  output Absyn.Variability outVariability;
algorithm
  outVariability:=
  match (inString)
    case ("") then Absyn.VAR();
    case ("discrete") then Absyn.DISCRETE();
    case ("parameter") then Absyn.PARAM();
    case ("constant") then Absyn.CONST();
  end match;
end setElementVariability;

protected function setElementCausality
"function setElementCausality
  Sets Direction (causality) according to string value."
  input String inString;
  output Absyn.Direction outDirection;
algorithm
  outDirection:=
  match (inString)
    case ("") then Absyn.BIDIR();
    case ("input") then Absyn.INPUT();
    case ("output") then Absyn.OUTPUT();
  end match;
end setElementCausality;

protected function selectString
"function: selectString
   author: adrpo@ida
   date  : 2006-02-05
   if bool is true select first string, otherwise the second one"
  input Boolean inBoolean1;
  input String inString2;
  input String inString3;
  output String outString;
algorithm
  outString:=
  match (inBoolean1,inString2,inString3)
    local String s1,s2;
    case (true,s1,_) then s1;
    case (false,_,s2) then s2;
  end match;
end selectString;

protected function getCrefInfo
"function: getCrefInfo
   author: adrpo@ida
   date  : 2005-11-03, changed 2006-02-05 to match new Absyn.INFO
   Retrieves the Info attribute of a Class.
   When parsing classes, the source:
   file name + isReadOnly + start lineno + start columnno + end lineno + end columnno is added to the Class
   definition and to all Elements, see Absyn.Info. This function retrieves the
   Info contents.
   inputs:   (Absyn.ComponentRef, /* class */
                Absyn.Program)
   outputs:   string"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path p_class;
      Absyn.Class cdef;
      String id,filename,str_sline,str_scol,str_eline,str_ecol,s,str_readonly;
      Boolean isReadOnly;
      Integer sline,scol,eline,ecol;
      Absyn.ComponentRef class_;
      Absyn.Program p;
    case (class_,p)
      equation
        p_class = Absyn.crefToPath(class_);
        cdef = getPathedClassInProgram(p_class, p);
        Absyn.CLASS(name = id,info = Absyn.INFO(fileName = filename,isReadOnly = isReadOnly,lineNumberStart = sline,columnNumberStart = scol,lineNumberEnd = eline,columnNumberEnd = ecol)) = cdef;
        str_sline = intString(sline);
        str_scol = intString(scol);
        str_eline = intString(eline);
        str_ecol = intString(ecol);
        str_readonly = selectString(isReadOnly, "readonly", "writable");
        s = stringAppendList({
               "{",
               filename, ",", 
               str_readonly, ",", 
               str_sline, ",", 
               str_scol, ",", 
               str_eline, ",", 
               str_ecol, 
               "}"});
      then
        s;
    case (_,_) then "Error";
  end matchcontinue;
end getCrefInfo;

protected function getImportString
"function: getImportString
   author: adrpo@ida
   date  : 2005-11-11
   helperfunction to getElementType "
  input Absyn.Import inImport;
  output String outString;
algorithm
  outString:=
  match (inImport)
    local
      String path_str,str,id;
      Absyn.Path path;
    case (Absyn.NAMED_IMPORT(name = id,path = path))
      equation
        path_str = Absyn.pathString(path);
        str = stringAppendList({"kind=named, id=",id,", path=",path_str});
      then
        str;
    case (Absyn.QUAL_IMPORT(path = path))
      equation
        path_str = Absyn.pathString(path);
        str = stringAppendList({"kind=qualified, path=",path_str});
      then
        str;
    case (Absyn.UNQUAL_IMPORT(path = path))
      equation
        path_str = Absyn.pathString(path);
        str = stringAppendList({"kind=unqualified, path=",path_str});
      then
        str;
  end match;
end getImportString;

protected function getElementType
"function: getElementType
   author: adrpo@ida
   date  : 2005-11-11
   helperfunction to getElementInfo"
  input Absyn.ElementSpec inElementSpec;
  output String outString;
algorithm
  outString:=
  match (inElementSpec)
    local
      String path_str,str,import_str,typename,flowPrefixstr,streamPrefixstr,variability_str,dir_str,names_str;
      Absyn.Path path;
      Absyn.TypeSpec typeSpec;
      Absyn.Import import_;
      list<String> names;
      Absyn.ElementAttributes attr;
      list<Absyn.ComponentItem> lst;
    case (Absyn.EXTENDS(path = path))
      equation
        path_str = Absyn.pathString(path);
        str = stringAppendList({"elementtype=extends, path=",path_str});
      then
        str;
    case (Absyn.IMPORT(import_ = import_))
      equation
        import_str = getImportString(import_);
        str = stringAppendList({"elementtype=import, ",import_str});
      then
        str;
    case (Absyn.COMPONENTS(attributes = attr,typeSpec = typeSpec,components = lst))
      equation
        typename = Dump.unparseTypeSpec(typeSpec);
        names = getComponentitemsName(lst,false);
        flowPrefixstr = attrFlowStr(attr);
        streamPrefixstr = attrStreamStr(attr);
        variability_str = attrVariabilityStr(attr);
        dir_str = attrDirectionStr(attr);
        names_str = stringDelimitList(names, ", ");
        str = stringAppendList({"elementtype=component, typename=",typename,", names={", names_str,"}, flow=",flowPrefixstr,
        ", stream=",streamPrefixstr,", variability=",variability_str,", direction=", dir_str});
      then
        str;
  end match;
end getElementType;

protected function getElementInfo
"function: getElementInfo
   author: adrpo@ida
   date  : 2005-11-11
   helperfunction to constructElementInfo & getElementsInfo"
  input Absyn.ElementItem inElementItem;
  output String outString;
algorithm
  outString:=
  matchcontinue (inElementItem)
    local
      String finalPrefix,repl,inout_str,str_restriction,element_str,sline_str,scol_str,eline_str,ecol_str,readonly_str,str,id,file;
      Boolean r_1,f,p,fi,e,isReadOnly;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter inout;
      Absyn.Restriction restr;
      Integer sline,scol,eline,ecol;
      Absyn.ElementSpec elementSpec;
      Absyn.Info info;
    case (Absyn.ELEMENTITEM(element = Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = inout,specification = Absyn.CLASSDEF(class_ = Absyn.CLASS(name = id,partialPrefix = p,finalPrefix = fi,encapsulatedPrefix = e,restriction = restr,info = Absyn.INFO(fileName = file,isReadOnly = isReadOnly,lineNumberStart = sline,columnNumberStart = scol,lineNumberEnd = eline,columnNumberEnd = ecol)))))) /* ok, first see if is a classdef if is not a classdef, just follow the normal stuff */
      equation
        finalPrefix = boolString(f);
        r_1 = keywordReplaceable(r);
        repl = boolString(r_1);
        inout_str = innerOuterStr(inout);
        str_restriction = Absyn.restrString(restr) "compile the classdef string" ;
        element_str = stringAppendList(
          {"elementtype=classdef, classname=",id,
          ", classrestriction=",str_restriction});
        sline_str = intString(sline);
        scol_str = intString(scol);
        eline_str = intString(eline);
        ecol_str = intString(ecol);
        readonly_str = selectString(isReadOnly, "readonly", "writable");
        str = stringAppendList(
          {"elementfile=\"",file,"\", elementreadonly=\"",
          readonly_str,"\", elementStartLine=",sline_str,", elementStartColumn=",scol_str,
          ", elementEndLine=",eline_str,", elementEndColumn=",ecol_str,", final=",finalPrefix,
          ", replaceable=",repl,", inout=",inout_str,", ",element_str});
      then
        str;
    case (Absyn.ELEMENTITEM(element = Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = inout,name = id,specification = elementSpec,info = (info as Absyn.INFO(fileName = file,isReadOnly = isReadOnly,lineNumberStart = sline,columnNumberStart = scol,lineNumberEnd = eline,columnNumberEnd = ecol))))) /* if is not a classdef, just follow the normal stuff */
      equation
        finalPrefix = boolString(f);
        r_1 = keywordReplaceable(r);
        repl = boolString(r_1);
        inout_str = innerOuterStr(inout);
        element_str = getElementType(elementSpec);
        sline_str = intString(sline);
        scol_str = intString(scol);
        eline_str = intString(eline);
        ecol_str = intString(ecol);
        readonly_str = selectString(isReadOnly, "readonly", "writable");
        str = stringAppendList(
          {"elementfile=\"",file,"\", elementreadonly=\"",
          readonly_str,"\", elementStartLine=",sline_str,", elementStartColumn=",scol_str,
          ", elementEndLine=",eline_str,", elementEndColumn=",ecol_str,", final=",finalPrefix,
          ", replaceable=",repl,", inout=",inout_str,", ",element_str});
      then
        str;
    case (Absyn.LEXER_COMMENT(comment=_)) then "elementtype=comment";
    case (_) then "elementtype=annotation";  /* for annotations we don\'t care */
  end matchcontinue;
end getElementInfo;

protected function constructElementsInfo
"function: constructElementsInfo
   author: adrpo@ida
   date  : 2005-11-11
   helperfunction to getElementsInfo
   inputs:  (string /* \"public\" or \"protected\" */, Absyn.ElementItem list)
   outputs:  string"
  input String inString;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inString,inAbsynElementItemLst)
    local
      String visibility_str,s1,element_str,res,s2;
      Absyn.ElementItem current;
      list<Absyn.ElementItem> rest;
    case (visibility_str,{}) then "";
    case (visibility_str,(current :: {})) /* deal with the last element */
      equation
        s1 = getElementInfo(current);
        element_str = stringAppendList({"{ rec(elementvisibility=",visibility_str,", ",s1,") }"});
        res = stringAppendList({element_str,"\n"});
      then
        res;
    case (visibility_str,(current :: rest))
      equation
        s1 = getElementInfo(current);
        element_str = stringAppendList({"{ rec(elementvisibility=",visibility_str,", ",s1,") }"});
        s2 = constructElementsInfo(visibility_str, rest);
        res = stringAppendList({element_str,",\n",s2});
      then
        res;
  end matchcontinue;
end constructElementsInfo;

protected function appendNonEmptyStrings
"function: appendNonEmptyStrings
   author: adrpo@ida
   date  : 2005-11-11
   helper to get_elements_info
   input: \"\", \"\", \",\" => \"\"
          \"some\", \"\", \",\" => \"some\"
          \"some\", \"some\", \",\" => \"some, some\""
  input String inString1;
  input String inString2;
  input String inString3;
  output String outString;
algorithm
  outString:=
  matchcontinue (inString1,inString2,inString3)
    local String s1,s2,str,delimiter;
    case ("","",_) then "";
    case (s1,"",_) then s1;
    case ("",s2,_) then s2;
    case (s1,s2,delimiter)
      equation
        str = stringAppendList({s1,delimiter,s2});
      then
        str;
  end matchcontinue;
end appendNonEmptyStrings;

protected function getElementsInfo
"function: getElementsInfo
   author: adrpo@ida
   date  : 2005-11-11, changed 2006-02-06 to mirror the new Absyn.INFO
   Retrieves the Info attribute of an element.
   When parsing elements of the class composition, the source:
    -> file name + readonly + start lineno + start columnno + end lineno + end columnno is added to the Element
   and to the Class definition, see Absyn.Info.
   This function retrieves the Info contents of the elements of a class."
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path modelpath;
      String i,public_str,protected_str,elements_str,str;
      Boolean f,e;
      Absyn.Restriction r;
      list<Absyn.ClassPart> parts;
      list<Absyn.ElementItem> public_elementitem_list,protected_elementitem_list;
      Absyn.ComponentRef model_;
      Absyn.Program p;
    /* a class with parts */
    case (model_,p)
      equation
        modelpath = Absyn.crefToPath(model_);
        Absyn.CLASS(i,_,f,e,r,Absyn.PARTS(classParts=parts),_) = getPathedClassInProgram(modelpath, p);
        public_elementitem_list = getPublicList(parts);
        protected_elementitem_list = getProtectedList(parts);
        public_str = constructElementsInfo("public", public_elementitem_list);
        protected_str = constructElementsInfo("protected", protected_elementitem_list);
        elements_str = appendNonEmptyStrings(public_str, protected_str, ", ");
        str = stringAppendList({"{ ",elements_str," }"});
      then
        str;
    /* an extended class with parts: model extends M end M; */
    case (model_,p)
      equation
        modelpath = Absyn.crefToPath(model_);
        Absyn.CLASS(i,_,f,e,r,Absyn.CLASS_EXTENDS(parts=parts),_) = getPathedClassInProgram(modelpath, p);
        public_elementitem_list = getPublicList(parts);
        protected_elementitem_list = getProtectedList(parts);
        public_str = constructElementsInfo("public", public_elementitem_list);
        protected_str = constructElementsInfo("protected", protected_elementitem_list);
        elements_str = appendNonEmptyStrings(public_str, protected_str, ", ");
        str = stringAppendList({"{ ",elements_str," }"});
      then
        str;
    /* otherwise */
    case (model_,p)
      equation
        modelpath = Absyn.crefToPath(model_);
        Absyn.CLASS(i,_,f,e,r,_,_) = getPathedClassInProgram(modelpath, p) "there are no elements in DERIVED, ENUMERATION, OVERLOAD, CLASS_EXTENDS and PDER
        maybe later we can give info about that also" ;
      then
        "{ }";
    case (_,_) then "Error";
  end matchcontinue;
end getElementsInfo;

public function getSourceFile
"function: getSourceFile
   author: PA
   Retrieves the Source file attribute of a Class.
   When parsing classes, the source file name is added to the Class
   definition and to all Elements, see Absyn. This function retrieves the
   source file of the Class.
   inputs:  (Absyn.ComponentRef, /* class */
               Absyn.Program)
   outputs: string"
  input Absyn.Path p_class;
  input Absyn.Program inProgram;
  output String outString;
algorithm
  outString:=
  matchcontinue (p_class,inProgram)
    local
      Absyn.Class cdef;
      String filename;
      Absyn.ComponentRef class_;
      Absyn.Program p;
    case (p_class,p) /* class */
      equation
        cdef = getPathedClassInProgram(p_class, p);
        filename = Absyn.classFilename(cdef);
      then filename;
    else "";
  end matchcontinue;
end getSourceFile;

public function setSourceFile
"function: setSourceFile
   author: PA
   Sets the source file of a Class. Is for instance used
   when adding a new class to an aldready stored package.
   The class should then have the same file as the package.
   inputs:   (Absyn.ComponentRef, /* class */
                string, /* filename */
                Absyn.Program)
   outputs: (string, Absyn.Program)"
  input Absyn.Path path;
  input String inString;
  input Absyn.Program inProgram;
  output Boolean success;
  output Absyn.Program outProgram;
algorithm
  (success,outProgram):=
  matchcontinue (path,inString,inProgram)
    local
      Absyn.Path p_class;
      Absyn.Class cdef,cdef_1;
      Absyn.Within within_;
      Absyn.Program newp,p;
      Absyn.ComponentRef class_;
      String filename;
      Absyn.TimeStamp ts;

    case (path,filename,p as Absyn.PROGRAM(globalBuildTimes=ts))
      equation
        cdef = getPathedClassInProgram(path, p);
        within_ = buildWithin(path);
        cdef_1 = Absyn.setClassFilename(cdef, filename, ts);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},within_,ts), p);
      then
        (true,newp);
    case (_,_,p) then (false,p);
  end matchcontinue;
end setSourceFile;

protected function setExtendsModifierValue
"function: setExtendsModifierValue
   This function sets the submodifier value of an
   extends clause in a Class. For instance,
   model test extends A(p1=3,p2(z=3));end test;
   setExtendsModifierValue(test,A,p1,Code(=4)) => OK
   => model test extends A(p1=4,p2(z=3));end test;
   inputs:   (Absyn.ComponentRef, /* class */
                Absyn.ComponentRef, /* inherit class */
                Absyn.ComponentRef, /* subident */
                Absyn.Modification,
                Absyn.Program)
   outputs:  (Absyn.Program,string)"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input Absyn.Modification inModification4;
  input Absyn.Program inProgram5;
  output Absyn.Program outProgram;
  output String outString;
algorithm
  (outProgram,outString) := matchcontinue (inComponentRef1,inComponentRef2,inComponentRef3,inModification4,inProgram5)
    local
      Absyn.Path p_class,inherit_class;
      Absyn.Within within_;
      Absyn.Class cdef,cdef_1;
      list<Env.Frame> env;
      Absyn.Program newp,p;
      Absyn.ComponentRef class_,inheritclass,subident;
      Absyn.Modification mod;
      Absyn.TimeStamp ts;

    case (class_,inheritclass,subident,mod,p as Absyn.PROGRAM(globalBuildTimes=ts))
      equation
        p_class = Absyn.crefToPath(class_);
        inherit_class = Absyn.crefToPath(inheritclass);
        within_ = buildWithin(p_class);
        cdef = getPathedClassInProgram(p_class, p);
        env = getClassEnv(p, p_class);
        cdef_1 = setExtendsSubmodifierInClass(cdef, inherit_class, subident, mod, env);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},within_,ts), p);
      then
        (newp,"Ok");
    case (_,_,_,_,p) then (p,"Error");
  end matchcontinue;
end setExtendsModifierValue;

protected function setExtendsSubmodifierInClass
"function: setExtendsSubmodifierInClass
   author: PA
   Sets a modifier of an extends clause for a given subcomponent.
   For instance,
   extends A(b=4); // b is subcomponent
   inputs:  (Absyn.Class,
               Absyn.Path, /* inherit_name */
               Absyn.ComponentRef, /* submodifier */
               Absyn.Modification,
               Env.Env)
   outputs: Absyn.Class"
  input Absyn.Class inClass;
  input Absyn.Path inPath;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Modification inModification;
  input Env.Env inEnv;
  output Absyn.Class outClass;
algorithm
  outClass:=
  match (inClass,inPath,inComponentRef,inModification,inEnv)
    local
      list<Absyn.ClassPart> parts_1,parts;
      String id,bcname;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      Absyn.Info file_info;
      Absyn.Path inherit_name;
      Absyn.ComponentRef submod;
      Absyn.Modification mod;
      list<Env.Frame> env;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
    /* a class with parts */
    case (Absyn.CLASS(name = id,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars,classParts = parts,comment = cmt),info = file_info),
          inherit_name,submod,mod,env)
      equation
        parts_1 = setExtendsSubmodifierInClassparts(parts, inherit_name, submod, mod, env);
      then
        Absyn.CLASS(id,p,f,e,r,Absyn.PARTS(typeVars,parts_1,cmt),file_info);
    /* adrpo: handle also model extends M end M; */
    case (Absyn.CLASS(name = id,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName=bcname,parts = parts,modifications=modif,comment = cmt),info = file_info),
          inherit_name,submod,mod,env)
      equation
        parts_1 = setExtendsSubmodifierInClassparts(parts, inherit_name, submod, mod, env);
      then
        Absyn.CLASS(id,p,f,e,r,Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts_1),file_info);
  end match;
end setExtendsSubmodifierInClass;

protected function setExtendsSubmodifierInClassparts
"function: setExtendsSubmodifierInClassparts
   Helper function to setExtendsSubmodifierInClass
   inputs:   (Absyn.ClassPart list,
                Absyn.Path, /* inherit_name */
                Absyn.ComponentRef, /* submodifier */
                Absyn.Modification,
                Env.Env)
   outputs:  Absyn.ClassPart list"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Absyn.Path inPath;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Modification inModification;
  input Env.Env inEnv;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst,inPath,inComponentRef,inModification,inEnv)
    local
      list<Absyn.ClassPart> res,rest;
      list<Absyn.ElementItem> elts_1,elts;
      Absyn.Path inherit;
      Absyn.ComponentRef submod;
      Absyn.Modification mod;
      list<Env.Frame> env;
      Absyn.ClassPart elt;
    case ({},_,_,_,_) then {};
    case ((Absyn.PUBLIC(contents = elts) :: rest),inherit,submod,mod,env)
      equation
        res = setExtendsSubmodifierInClassparts(rest, inherit, submod, mod, env);
        elts_1 = setExtendsSubmodifierInElementitems(elts, inherit, submod, mod, env);
      then
        (Absyn.PUBLIC(elts_1) :: res);
    case ((Absyn.PROTECTED(contents = elts) :: rest),inherit,submod,mod,env)
      equation
        res = setExtendsSubmodifierInClassparts(rest, inherit, submod, mod, env);
        elts_1 = setExtendsSubmodifierInElementitems(elts, inherit, submod, mod, env);
      then
        (Absyn.PROTECTED(elts_1) :: res);
    case ((elt :: rest),inherit,submod,mod,env)
      equation
        res = setExtendsSubmodifierInClassparts(rest, inherit, submod, mod, env);
      then
        (elt :: res);
  end matchcontinue;
end setExtendsSubmodifierInClassparts;

protected function setExtendsSubmodifierInElementitems
"function: setExtendsSubmodifierInElementitems
   Helper function to setExtendsSubmodifierInClassparts
   inputs:  (Absyn.ElementItem list,
               Absyn.Path, /* inherit_name */
               Absyn.ComponentRef, /* submodifier */
               Absyn.Modification,
               Env.Env)
   outputs:  Absyn.ElementItem list"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Path inPath;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Modification inModification;
  input Env.Env inEnv;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm
  outAbsynElementItemLst:=
  matchcontinue (inAbsynElementItemLst,inPath,inComponentRef,inModification,inEnv)
    local
      list<Absyn.ElementItem> res,rest;
      Absyn.Element elt_1,elt;
      Absyn.Path inherit;
      Absyn.ComponentRef submod;
      Absyn.Modification mod;
      list<Env.Frame> env;
      Absyn.ElementItem elitem;
    case ({},_,_,_,_) then {};
    case ((Absyn.ELEMENTITEM(element = elt) :: rest),inherit,submod,mod,env)
      equation
        res = setExtendsSubmodifierInElementitems(rest, inherit, submod, mod, env);
        elt_1 = setExtendsSubmodifierInElement(elt, inherit, submod, mod, env);
      then
        (Absyn.ELEMENTITEM(elt_1) :: res);
    case ((elitem :: rest),inherit,submod,mod,env)
      equation
        res = setExtendsSubmodifierInElementitems(rest, inherit, submod, mod, env);
      then
        (elitem :: res);
  end matchcontinue;
end setExtendsSubmodifierInElementitems;

protected function setExtendsSubmodifierInElement
"function: setExtendsSubmodifierInElement
   Helper function to setExtendsSubmodifierInElementitems
   inputs: (Absyn.Element,
              Absyn.Path, /* inherit_name */
              Absyn.ComponentRef, /* submodifier */
              Absyn.Modification,
              Env.Env)
   outputs:  Absyn.Element"
  input Absyn.Element inElement;
  input Absyn.Path inPath;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Modification inModification;
  input Env.Env inEnv;
  output Absyn.Element outElement;
algorithm
  outElement:=
  matchcontinue (inElement,inPath,inComponentRef,inModification,inEnv)
    local
      Boolean f;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter i;
      String n;
      Absyn.Path path,inherit,path_1;
      list<Absyn.ElementArg> eargs,eargs_1;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constr;
      Absyn.ComponentRef submod;
      list<Env.Frame> env;
      Absyn.Modification mod;
      Absyn.Element elt;
      Option<Absyn.Annotation> annOpt;
      /* special case for clearing modifications */
   /* case (Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = i,name = n,
      specification = Absyn.EXTENDS(path = path,elementArg = eargs),info = info,constrainClass = constr),
      inherit,submod,Absyn.CLASSMOD(elementArgLst = {},expOption = NONE()),env)

      then Absyn.ELEMENT(f,r,i,n,Absyn.EXTENDS(path,{}),info,constr); */

    case (Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = i,name = n,
      specification = Absyn.EXTENDS(path = path,elementArg = eargs,annotationOpt=annOpt),info = info,constrainClass = constr),
      inherit,submod,mod,env)
      equation
        (_,path_1) = Inst.makeFullyQualified(Env.emptyCache(),env, path);
        true = Absyn.pathEqual(inherit, path_1);
        eargs_1 = setSubmodifierInElementargs(eargs, submod, mod);
      then
        Absyn.ELEMENT(f,r,i,n,Absyn.EXTENDS(path,eargs_1,annOpt),info,constr);
    case (elt,_,_,_,_) then elt;
  end matchcontinue;
end setExtendsSubmodifierInElement;

protected function getExtendsModifierValue
"function: getExtendsModifierValue
   Return the submodifier value of an extends clause
   for instance,
   model test extends A(p1=3,p2(z=3));end test;
   getExtendsModifierValue(test,A,p1) => =3
   inputs:  (Absyn.ComponentRef, /* class */
               Absyn.ComponentRef, /* ident */
               Absyn.ComponentRef, /* subident */
               Absyn.Program)
   outputs:  string"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input Absyn.Program inProgram4;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef1,inComponentRef2,inComponentRef3,inProgram4)
    local
      Absyn.Path p_class,name,extpath;
      Absyn.Class cdef;
      list<Env.Frame> env;
      list<Absyn.ElementSpec> exts,exts_1;
      list<Absyn.ElementArg> extmod;
      Absyn.Modification mod;
      String res;
      Absyn.ComponentRef class_,inherit_name,subident;
      Absyn.Program p;
    case (class_,inherit_name,subident,p)
      equation
        p_class = Absyn.crefToPath(class_);
        name = Absyn.crefToPath(inherit_name);
        cdef = getPathedClassInProgram(p_class, p);
        env = getClassEnv(p, p_class);
        exts = getExtendsElementspecInClass(cdef);
        exts_1 = List.map1(exts, makeExtendsFullyQualified, env);
        {Absyn.EXTENDS(extpath,extmod,_)} = List.select1(exts_1, extendsElementspecNamed, name);
        mod = getModificationValue(extmod, subident);
        res = Dump.unparseModificationStr(mod);
      then
        res;
    case (_,_,_,_) then "Error";
  end matchcontinue;
end getExtendsModifierValue;

protected function makeExtendsFullyQualified
"function: makeExtendsFullyQualified
   Makes an EXTENDS ElementSpec having a
   fully qualified extends path."
  input Absyn.ElementSpec inElementSpec;
  input Env.Env inEnv;
  output Absyn.ElementSpec outElementSpec;
algorithm
  outElementSpec:=
  match (inElementSpec,inEnv)
    local
      Absyn.Path path_1,path;
      list<Absyn.ElementArg> earg;
      list<Env.Frame> env;
      Option<Absyn.Annotation> annOpt;

    case (Absyn.EXTENDS(path = path,elementArg = earg,annotationOpt=annOpt),env)
      equation
        (_,path_1) = Inst.makeFullyQualified(Env.emptyCache(),env, path);
      then
        Absyn.EXTENDS(path_1,earg,annOpt);
  end match;
end makeExtendsFullyQualified;

protected function getExtendsModifierNames
"function: getExtendsModifierNames
   Return the modifier names of a
   modification on an extends clause.
   For instance,
     model test extends A(p1=3,p2(z=3));end test;
     getExtendsModifierNames(test,A) => {p1,p2}
   inputs:  (Absyn.ComponentRef, /* class */
               Absyn.ComponentRef, /* inherited class */
               Absyn.Program)
   outputs: (string)"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.Program inProgram3;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef1,inComponentRef2,inProgram3)
    local
      Absyn.Path p_class,name,extpath;
      Absyn.Class cdef;
      list<Absyn.ElementSpec> exts,exts_1;
      list<Env.Frame> env;
      list<Absyn.ElementArg> extmod;
      list<String> res;
      String res_1,res_2;
      Absyn.ComponentRef class_,inherit_name;
      Absyn.Program p;
    case (class_,inherit_name,p)
      equation
        p_class = Absyn.crefToPath(class_);
        name = Absyn.crefToPath(inherit_name);
        cdef = getPathedClassInProgram(p_class, p);
        exts = getExtendsElementspecInClass(cdef);
        env = getClassEnv(p, p_class);
        exts_1 = List.map1(exts, makeExtendsFullyQualified, env);
        {Absyn.EXTENDS(extpath,extmod,_)} = List.select1(exts_1, extendsElementspecNamed, name);
        res = getModificationNames(extmod);
        res_1 = stringDelimitList(res, ", ");
        res_2 = stringAppendList({"{",res_1,"}"});
      then
        res_2;
    case (_,_,_) then "Error";
  end matchcontinue;
end getExtendsModifierNames;

protected function extendsElementspecNamed
"function extends_elementspec_name
  Returns true if elementspec of EXTENDS has
  the name given as path, false otherwise."
  input Absyn.ElementSpec inElementSpec;
  input Absyn.Path inPath;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  match (inElementSpec,inPath)
    local
      Boolean res;
      Absyn.Path extpath,path;
    case (Absyn.EXTENDS(path = extpath),path)
      equation
        res = Absyn.pathEqual(path, extpath);
      then
        res;
  end match;
end extendsElementspecNamed;

protected function extendsName
"function extendsName
  Return the class name of an EXTENDS element spec."
  input Absyn.ElementSpec inElementSpec;
  output Absyn.Path outPath;
algorithm
  outPath:=
  matchcontinue (inElementSpec)
    local Absyn.Path path;
    case (Absyn.EXTENDS(path = path)) then path;
  end matchcontinue;
end extendsName;

protected function getExtendsElementspecInClass
"function: getExtendsElementspecInClass
  Retrieve all ElementSpec of a class that are EXTENDS."
  input Absyn.Class inClass;
  output list<Absyn.ElementSpec> outAbsynElementSpecLst;
algorithm
  outAbsynElementSpecLst:=
  matchcontinue (inClass)
    local
      list<Absyn.ElementSpec> ext;
      list<Absyn.ClassPart> parts;
      list<Absyn.ElementArg> eltArg;
      Absyn.Path tp;
    /* a class with parts */
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)))
      equation
        ext = getExtendsElementspecInClassparts(parts);
      then
        ext;
    /* adrpo: handle also model extends M end M; */
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)))
      equation
        ext = getExtendsElementspecInClassparts(parts);
      then
        ext;
    /* a derived class */
    case (Absyn.CLASS(body = Absyn.DERIVED(typeSpec=Absyn.TPATH(tp,_), arguments=eltArg)))
      then
        {Absyn.EXTENDS(tp,eltArg,NONE())};
        // Note: the array dimensions of DERIVED are lost. They must be
        // queried by another api-function
    case (_) then {};
  end matchcontinue;
end getExtendsElementspecInClass;

protected function getExtendsElementspecInClassparts
"function: getExtendsElementspecInClassparts
  Helper function to getExtendsElementspecInClass."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ElementSpec> outAbsynElementSpecLst;
algorithm
  outAbsynElementSpecLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.ElementSpec> lst1,lst2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> rest;
      Absyn.ClassPart elt;
    case ({}) then {};
    case ((Absyn.PUBLIC(contents = elts) :: rest))
      equation
        lst1 = getExtendsElementspecInClassparts(rest);
        lst2 = getExtendsElementspecInElementitems(elts);
        res = listAppend(lst1, lst2);
      then
        res;
    case ((Absyn.PROTECTED(contents = elts) :: rest))
      equation
        lst1 = getExtendsElementspecInClassparts(rest);
        lst2 = getExtendsElementspecInElementitems(elts);
        res = listAppend(lst1, lst2);
      then
        res;
    case ((elt :: rest))
      equation
        res = getExtendsElementspecInClassparts(rest);
      then
        res;
  end matchcontinue;
end getExtendsElementspecInClassparts;

protected function getExtendsElementspecInElementitems
"function: getExtendsElementspecInElementitems
  Helper function to getExtendsElementspecInClassparts."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.ElementSpec> outAbsynElementSpecLst;
algorithm
  outAbsynElementSpecLst:=
  matchcontinue (inAbsynElementItemLst)
    local
      Absyn.Element el;
      Absyn.ElementSpec elt;
      list<Absyn.ElementSpec> res;
      list<Absyn.ElementItem> rest;
    case ({}) then {};
    case ((Absyn.ELEMENTITEM(element = el) :: rest))
      equation
        elt = getExtendsElementspecInElement(el) "Bug in MetaModelica Compiler (MMC). If the two premisses below are in swapped order
    the compiler enters infinite loop (but no stack overflow)" ;
        res = getExtendsElementspecInElementitems(rest);
      then
        (elt :: res);
    case ((_ :: rest))
      equation
        res = getExtendsElementspecInElementitems(rest);
      then
        res;
  end matchcontinue;
end getExtendsElementspecInElementitems;

protected function getExtendsElementspecInElement
"function: getExtendsElementspecInElement
  Helper function to getExtendsElementspecInElementitems."
  input Absyn.Element inElement;
  output Absyn.ElementSpec outElementSpec;
algorithm
  outElementSpec:=
  match (inElement)
    local Absyn.ElementSpec ext;
    case (Absyn.ELEMENT(specification = (ext as Absyn.EXTENDS(path = _)))) then ext;
  end match;
end getExtendsElementspecInElement;

protected function setComponentModifier
"function: setComponentModifier
   Sets a submodifier of a component.
   inputs:   (Absyn.ComponentRef, /* class */
                Absyn.ComponentRef, /* variable name */
                Absyn.ComponentRef, /* submodifier name */
                Absyn.Modification,
                Absyn.Program)
   outputs: (Absyn.Program, string)"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input Absyn.Modification inModification4;
  input Absyn.Program inProgram5;
  output Absyn.Program outProgram;
  output String outString;
algorithm
  (outProgram,outString):=
  matchcontinue (inComponentRef1,inComponentRef2,inComponentRef3,inModification4,inProgram5)
    local
      Absyn.Path p_class;
      Absyn.Within within_;
      Absyn.Class cdef,cdef_1;
      Absyn.Program newp,p;
      Absyn.ComponentRef class_,subident;
      String varname;
      Absyn.Modification mod;
      Absyn.TimeStamp ts;

    case (class_,Absyn.CREF_IDENT(name = varname),subident,mod,p as Absyn.PROGRAM(globalBuildTimes=ts))
      equation
        p_class = Absyn.crefToPath(class_);
        within_ = buildWithin(p_class);
        cdef = getPathedClassInProgram(p_class, p);
        cdef_1 = setComponentSubmodifierInClass(cdef, varname, subident, mod);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},within_,ts), p);
      then
        (newp,"Ok");
    case (_,_,_,_,p) then (p,"Error");
  end matchcontinue;
end setComponentModifier;

protected function setComponentSubmodifierInClass
"function: setComponentSubmodifierInClass
   Sets a sub modifier on a component in a class.
   inputs: (Absyn.Class,
              Absyn.Ident, /* component name */
              Absyn.ComponentRef, /* subvariable path */
              Absyn.Modification)
   outputs: Absyn.Class"
  input Absyn.Class inClass;
  input Absyn.Ident inIdent;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Modification inModification;
  output Absyn.Class outClass;
algorithm
  outClass:=
  match (inClass,inIdent,inComponentRef,inModification)
    local
      list<Absyn.ClassPart> parts_1,parts;
      String id,varname,bcname;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      Absyn.Info file_info;
      Absyn.ComponentRef submodident;
      Absyn.Modification mod;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
    /* a class with parts */
    case (Absyn.CLASS(name = id,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars,classParts = parts,comment = cmt),info = file_info),
          varname,submodident,mod)
      equation
        parts_1 = setComponentSubmodifierInClassparts(parts, varname, submodident, mod);
      then
        Absyn.CLASS(id,p,f,e,r,Absyn.PARTS(typeVars,parts_1,cmt),file_info);
    /* adrpo: handle also model extends M end M; */
    case (Absyn.CLASS(name = id,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName=bcname,modifications=modif,parts = parts,comment = cmt),info = file_info),
          varname,submodident,mod)
      equation
        parts_1 = setComponentSubmodifierInClassparts(parts, varname, submodident, mod);
      then
        Absyn.CLASS(id,p,f,e,r,Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts_1),file_info);
  end match;
end setComponentSubmodifierInClass;

protected function setComponentSubmodifierInClassparts
"function: setComponentSubmodifierInClassparts
   Helper function to setComponentSubmodifierInClass
   inputs:  (Absyn.ClassPart list,
               Absyn.Ident, /* component name */
               Absyn.ComponentRef, /* subvariable path */
               Absyn.Modification)
   outputs:  Absyn.ClassPart list"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Absyn.Ident inIdent;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Modification inModification;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst,inIdent,inComponentRef,inModification)
    local
      list<Absyn.ClassPart> res,rest;
      list<Absyn.ElementItem> elts_1,elts;
      String varname;
      Absyn.ComponentRef submodident;
      Absyn.Modification mod;
      Absyn.ClassPart elt;
    case ({},_,_,_) then {};
    case ((Absyn.PUBLIC(contents = elts) :: rest),varname,submodident,mod)
      equation
        res = setComponentSubmodifierInClassparts(rest, varname, submodident, mod);
        elts_1 = setComponentSubmodifierInElementitems(elts, varname, submodident, mod);
      then
        (Absyn.PUBLIC(elts_1) :: res);
    case ((Absyn.PROTECTED(contents = elts) :: rest),varname,submodident,mod)
      equation
        res = setComponentSubmodifierInClassparts(rest, varname, submodident, mod);
        elts_1 = setComponentSubmodifierInElementitems(elts, varname, submodident, mod);
      then
        (Absyn.PROTECTED(elts_1) :: res);
    case ((elt :: rest),varname,submodident,mod)
      equation
        res = setComponentSubmodifierInClassparts(rest, varname, submodident, mod);
      then
        (elt :: res);
  end matchcontinue;
end setComponentSubmodifierInClassparts;

protected function setComponentSubmodifierInElementitems
"function: setComponentSubmodifierInElementitems
   Helper function to setComponentSubmodifierInClassparts
   inputs: (Absyn.ElementItem list,
              Absyn.Ident, /* component name */
              Absyn.ComponentRef, /* subvariable path */
              Absyn.Modification)
   outputs: Absyn.ElementItem list"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Ident inIdent;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Modification inModification;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm
  outAbsynElementItemLst:=
  matchcontinue (inAbsynElementItemLst,inIdent,inComponentRef,inModification)
    local
      list<Absyn.ElementItem> res,rest;
      Absyn.Element elt_1,elt;
      String varname;
      Absyn.ComponentRef submodident;
      Absyn.Modification mod;
      Absyn.ElementItem elitem;
    case ({},_,_,_) then {};
    case ((Absyn.ELEMENTITEM(element = elt) :: rest),varname,submodident,mod)
      equation
        res = setComponentSubmodifierInElementitems(rest, varname, submodident, mod);
        elt_1 = setComponentSubmodifierInElement(elt, varname, submodident, mod);
      then
        (Absyn.ELEMENTITEM(elt_1) :: res);
    case ((elitem :: rest),varname,submodident,mod)
      equation
        res = setComponentSubmodifierInElementitems(rest, varname, submodident, mod);
      then
        (elitem :: res);
  end matchcontinue;
end setComponentSubmodifierInElementitems;

protected function setComponentSubmodifierInElement
"function: setComponentSubmodifierInElement
   Helper function to setComponentSubmodifierInElementitems
   inputs: (Absyn.Element,
              Absyn.Ident, /* component name */
              Absyn.ComponentRef, /* submodifier path */
              Absyn.Modification)
   outputs: Absyn.Element"
  input Absyn.Element inElement;
  input Absyn.Ident inIdent;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Modification inModification;
  output Absyn.Element outElement;
algorithm
  outElement:=
  matchcontinue (inElement,inIdent,inComponentRef,inModification)
    local
      list<Absyn.ComponentItem> compitems_1,compitems;
      Boolean f;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter i;
      String n,varname;
      Absyn.ElementAttributes attr;
      Absyn.TypeSpec tp;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constr;
      Absyn.ComponentRef submodident;
      Absyn.Modification mod;
      Absyn.Element elt;
    case (Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = i,name = n,
      specification = Absyn.COMPONENTS(attributes = attr,typeSpec = tp,components = compitems),
      info = info,constrainClass = constr),varname,submodident,mod)
      equation
        compitems_1 = setComponentSubmodifierInCompitems(compitems, varname, submodident, mod);
      then
        Absyn.ELEMENT(f,r,i,n,Absyn.COMPONENTS(attr,tp,compitems_1),info,constr);
    case (elt,_,_,_) then elt;
  end matchcontinue;
end setComponentSubmodifierInElement;

protected function setComponentSubmodifierInCompitems
"function: setComponentSubmodifierInCompitems
   Helper function to setComponentSubmodifierInElement
   inputs:  (Absyn.ComponentItem list,
               Absyn.Ident, /* component name */
               Absyn.ComponentRef, /* submodifier path */
               Absyn.Modification)
   outputs: (Absyn.ComponentItem list)"
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Absyn.Ident inIdent;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Modification inModification;
  output list<Absyn.ComponentItem> outAbsynComponentItemLst;
algorithm
  outAbsynComponentItemLst := matchcontinue (inAbsynComponentItemLst,inIdent,inComponentRef,inModification)
    local
      list<Absyn.ElementArg> args_1,args;
      Option<Absyn.Modification> optmod;
      String id,varname;
      list<Absyn.Subscript> dim;
      Option<Absyn.Exp> expopt,cond;
      Option<Absyn.Comment> cmt;
      list<Absyn.ComponentItem> rest,res;
      Absyn.ComponentRef submodpath,submod,submodident;
      Absyn.Modification mod;
      Absyn.ComponentItem comp;
      Absyn.EqMod eqMod;
    
    case ({},_,_,_) then {};
    
    // remove modifier.
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = dim,modification = SOME(Absyn.CLASSMOD(args,_))),condition = cond,comment = cmt) :: rest),varname,Absyn.CREF_IDENT("",{}),mod)
      equation
        true = stringEq(varname, id);
        optmod = createOptModificationFromEltargs(args,Absyn.NOMOD());
      then
        (Absyn.COMPONENTITEM(Absyn.COMPONENT(id,dim,optmod),cond,cmt) :: rest);
    
    // remove modifier.
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = dim,modification = NONE()),condition = cond,comment = cmt) :: rest),varname,Absyn.CREF_IDENT("",{}),mod)
      equation
        true = stringEq(varname, id);
      then
        (Absyn.COMPONENTITEM(Absyn.COMPONENT(id,dim,NONE()),cond,cmt) :: rest);
    
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = dim,modification = SOME(Absyn.CLASSMOD(args,eqMod))),condition = cond,comment = cmt) :: rest),varname,submodpath,mod)
      equation
        true = stringEq(varname, id);
        args_1 = setSubmodifierInElementargs(args, submodpath, mod);
        optmod = createOptModificationFromEltargs(args_1,eqMod);
      then
        (Absyn.COMPONENTITEM(Absyn.COMPONENT(id,dim,optmod),cond,cmt) :: rest);

    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = dim,modification = NONE()),condition = cond,comment = cmt) :: rest),varname,submod,Absyn.CLASSMOD({},Absyn.NOMOD()))
      equation
        true = stringEq(varname, id);
      then
        (Absyn.COMPONENTITEM(Absyn.COMPONENT(id,dim,NONE()),cond,cmt) :: rest);


    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = dim,modification = NONE()),condition = cond,comment = cmt) :: rest),varname,submod,mod)
      equation
        true = stringEq(varname, id);
      then
        (Absyn.COMPONENTITEM(
          Absyn.COMPONENT(id,dim,
          SOME(
          Absyn.CLASSMOD(
          {
          Absyn.MODIFICATION(false,Absyn.NON_EACH(),submod,SOME(mod),NONE(),Absyn.dummyInfo)},Absyn.NOMOD()))),cond,cmt) :: rest);
    
    case ((comp :: rest),varname,submodident,mod)
      equation
        res = setComponentSubmodifierInCompitems(rest, varname, submodident, mod);
      then
        (comp :: res);
    
    case (_,_,_,_)
      equation
        print("-set_component_submodifier_in_compitems failed\n");
      then
        fail();
  end matchcontinue;
end setComponentSubmodifierInCompitems;

protected function createOptModificationFromEltargs
"function: createOptModificationFromEltargs
  Creates an Modification option from an ElementArg
  list. If list is empty, NONE() is created."
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input Absyn.EqMod eqMod;
  output Option<Absyn.Modification> outAbsynModificationOption;
algorithm
  outAbsynModificationOption:=
  matchcontinue (inAbsynElementArgLst,eqMod)
    local
      list<Absyn.ElementArg> args;
      Option<Absyn.Exp> expOpt;
      Absyn.Exp e;
    case({},eqMod as Absyn.EQMOD(exp=_)) then SOME(Absyn.CLASSMOD({},eqMod));
    case ({},_) then NONE();
    case (args,eqMod) then SOME(Absyn.CLASSMOD(args,eqMod));
  end matchcontinue;
end createOptModificationFromEltargs;

protected function setSubmodifierInElementargs
"function: setSubmodifierInElementargs
   Helper function to setComponentSubmodifierInCompitems
   inputs:  (Absyn.ElementArg list,
               Absyn.ComponentRef, /* subcomponent name */
               Absyn.Modification)
   outputs:  Absyn.ElementArg list"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Modification inModification;
  output list<Absyn.ElementArg> outAbsynElementArgLst;
algorithm
  outAbsynElementArgLst:=
  matchcontinue (inAbsynElementArgLst,inComponentRef,inModification)
    local
      Absyn.ComponentRef cref,cr1,cr2,cr;
      Absyn.Modification mod;
      Option<Absyn.Modification> mod2;
      Boolean f;
      Absyn.Each each_;
      String name,submodident,name1,name2;
      list<Absyn.Subscript> idx;
      Option<String> cmt;
      list<Absyn.ElementArg> rest,args_1,args,res,submods;
      Option<Absyn.Exp> exp;
      Absyn.Exp e;
      Absyn.ElementArg m;
      Absyn.EqMod eqMod;
      Absyn.Info info;
    
    case ({},cref,Absyn.CLASSMOD({},Absyn.NOMOD())) then {}; // Empty modification.
    case ({},cref,mod) then {Absyn.MODIFICATION(false,Absyn.NON_EACH(),cref,SOME(mod),NONE(),Absyn.dummyInfo)};
    
    // Clear modification m(...)
    case ((Absyn.MODIFICATION(finalPrefix = f,eachPrefix = each_,componentRef = (cr as Absyn.CREF_IDENT(name = name,subscripts = idx)),comment = cmt,modification=SOME(Absyn.CLASSMOD((submods as _::_),_)), info = info) :: rest),Absyn.CREF_IDENT(name = submodident),(mod as Absyn.CLASSMOD( {},Absyn.NOMOD())))
      equation
        true = stringEq(name, submodident);
      then
        Absyn.MODIFICATION(f,each_,cr,SOME(Absyn.CLASSMOD(submods,Absyn.NOMOD())),cmt,info)::rest;
    
    // Clear modification, m with no submodifiers
    case ((Absyn.MODIFICATION(finalPrefix = f,eachPrefix = each_,componentRef = Absyn.CREF_IDENT(name = name,subscripts = idx),comment = cmt,modification=SOME(Absyn.CLASSMOD({},_)), info = info) :: rest),Absyn.CREF_IDENT(name = submodident),(mod as Absyn.CLASSMOD( {},Absyn.NOMOD())))
      equation
        true = stringEq(name, submodident);
      then
        rest;
    
    // modfication, m=e
    case ((Absyn.MODIFICATION(finalPrefix = f,eachPrefix = each_,componentRef = Absyn.CREF_IDENT(name = name,subscripts = idx),modification=SOME(Absyn.CLASSMOD(submods,_)),comment = cmt, info = info) :: rest),Absyn.CREF_IDENT(name = submodident),(mod as Absyn.CLASSMOD({},eqMod as Absyn.EQMOD(exp=_)))) /* update modification */
      equation
        true = stringEq(name, submodident);
      then
        (Absyn.MODIFICATION(f,each_,Absyn.CREF_IDENT(name,idx),SOME(Absyn.CLASSMOD(submods,eqMod)),cmt,info) :: rest);
    
    // modfication, m(...)=e
    case ((Absyn.MODIFICATION(finalPrefix = f,eachPrefix = each_,componentRef = Absyn.CREF_IDENT(name = name,subscripts = idx),modification=mod2,comment = cmt, info = info) :: rest),Absyn.CREF_IDENT(name = submodident),mod) /* update modification */
      equation
        true = stringEq(name, submodident);
      then
        (Absyn.MODIFICATION(f,each_,Absyn.CREF_IDENT(name,idx),SOME(mod),cmt,info) :: rest);
    
    // Clear modification, m.n
     case ((Absyn.MODIFICATION(finalPrefix = f,eachPrefix = each_,componentRef = (cr1 as Absyn.CREF_QUAL(name = _)),comment = cmt) :: rest),cr2,Absyn.CLASSMOD({},Absyn.NOMOD()))
      equation
        true = Absyn.crefEqual(cr1, cr2);
      then
        (rest);
    
    // Clear modification m.n first part matches. Check that m is not present in rest of list.
    case ((Absyn.MODIFICATION(finalPrefix = f,eachPrefix = each_,componentRef = Absyn.CREF_QUAL(name = name1),comment = cmt) :: rest),cr as Absyn.CREF_IDENT(name = name2,subscripts = idx),Absyn.CLASSMOD({},Absyn.NOMOD()))
      equation
        true = stringEq(name1, name2);
        false = findCrefModification(cr,rest);
      then
        (rest);
   
    // Clear modification m(...)
    case ((Absyn.MODIFICATION(finalPrefix = f,eachPrefix = each_,componentRef = (cr as Absyn.CREF_IDENT(name = name2)),modification = SOME(Absyn.CLASSMOD(args,Absyn.NOMOD())),comment = cmt, info = info) :: rest),Absyn.CREF_QUAL(name = name1,componentRef = cr1),Absyn.CLASSMOD({},Absyn.NOMOD()))
      equation
        true = stringEq(name1, name2);
        {} = setSubmodifierInElementargs(args, cr1, Absyn.CLASSMOD({},Absyn.NOMOD()));
      then
        (Absyn.MODIFICATION(f,each_,cr,NONE(),cmt,info) :: rest);

   // Clear modification m(...)=expr
   case ((Absyn.MODIFICATION(finalPrefix = f,eachPrefix = each_,componentRef = (cr as Absyn.CREF_IDENT(name = name2)),modification = SOME(Absyn.CLASSMOD(args,eqMod as Absyn.EQMOD(exp=_))),comment = cmt,info = info) :: rest),Absyn.CREF_QUAL(name = name1,componentRef = cr1),Absyn.CLASSMOD({},Absyn.NOMOD()))
      equation
        true = stringEq(name1, name2);
        {} = setSubmodifierInElementargs(args, cr1, Absyn.CLASSMOD({},Absyn.NOMOD()));
      then
        (Absyn.MODIFICATION(f,each_,cr,SOME(Absyn.CLASSMOD({},eqMod)),cmt,info) :: rest);

   // modification, m for m.n
   case ((Absyn.MODIFICATION(finalPrefix = f,eachPrefix = each_,componentRef = (cr as Absyn.CREF_IDENT(name = name2)),modification = SOME(Absyn.CLASSMOD(args,eqMod)),comment = cmt,info = info) :: rest),Absyn.CREF_QUAL(name = name1,componentRef = cr1),mod)
      equation
        true = stringEq(name1, name2);
        args_1 = setSubmodifierInElementargs(args, cr1, mod);
      then
        (Absyn.MODIFICATION(f,each_,cr,SOME(Absyn.CLASSMOD(args_1,eqMod)),cmt,info) :: rest);
   
   // modification, m.n for m.n
   case ((Absyn.MODIFICATION(finalPrefix = f,eachPrefix = each_,componentRef = cr1,modification = SOME(Absyn.CLASSMOD(eqMod=_)),comment = cmt,info = info) :: rest),cr2,mod)
      equation
        true = Absyn.crefEqual(cr1,cr2);
      then
        (Absyn.MODIFICATION(f,each_,cr1,SOME(mod),cmt,info) :: rest);
    
    // next element
    case ((m :: rest),cr,mod)
      equation
        res = setSubmodifierInElementargs(rest, cr, mod);
      then
        (m :: res);
    
    case (_,_,_)
      equation
        print("-set_submodifier_in_elementargs failed\n");
      then
        fail();
  end matchcontinue;
end setSubmodifierInElementargs;

protected function findCrefModification
  input Absyn.ComponentRef cr;
  input list<Absyn.ElementArg> lst;
  output Boolean found;
algorithm
  found := matchcontinue(cr,lst)
    local Absyn.ComponentRef cr2; list<Absyn.ElementArg> rest;
    case (cr,Absyn.MODIFICATION(componentRef = cr2)::_)
      equation
        true = Absyn.crefEqual(cr,cr2);
      then true;
    case (cr,_::rest) then findCrefModification(cr,rest);
    case (cr,{}) then false;
  end matchcontinue;
end findCrefModification;

protected function getComponentModifierValue
"function: getComponentModifierValue(class,ident,subident,p) => resstr
   Returns the modifier value of component ident for modifier subident.
   For instance,
     model A
      B b1(a1(p1=0,p2=0));
     end A;
     getComponentModifierValues(A,b1,a1) => Code((p1=0,p2=0))
   inputs:  (Absyn.ComponentRef, /* class */
               Absyn.ComponentRef, /* variable name */
               Absyn.ComponentRef, /* submodifier name */
               Absyn.Program)
   outputs: string"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input Absyn.Program inProgram4;
  output String outString;
algorithm
  outString := matchcontinue (inComponentRef1,inComponentRef2,inComponentRef3,inProgram4)
    local
      Absyn.Path p_class;
      String name,res;
      Absyn.Class cdef;
      list<Absyn.Element> comps;
      list<list<Absyn.ComponentItem>> compelts;
      list<Absyn.ComponentItem> compelts_1;
      Absyn.Modification mod;
      Absyn.ComponentRef class_,ident,subident;
      Absyn.Program p;
      list<Absyn.ElementArg> elementArgLst;
    
    case (class_,ident,subident,p)
      equation
        p_class = Absyn.crefToPath(class_);
        Absyn.IDENT(name) = Absyn.crefToPath(ident);
        cdef = getPathedClassInProgram(p_class, p);
        comps = getComponentsInClass(cdef);
        compelts = List.map(comps, getComponentitemsInElement);
        compelts_1 = List.flatten(compelts);
        {Absyn.COMPONENTITEM(component=Absyn.COMPONENT(modification=SOME(Absyn.CLASSMOD(elementArgLst=elementArgLst))))} = List.select1(compelts_1, componentitemNamed, name);
        mod = getModificationValue(elementArgLst, subident);
        res = Dump.unparseModificationStr(mod);
      then
        res;
    case (_,_,_,_) then "Error";
  end matchcontinue;
end getComponentModifierValue;

public function getModificationValue
"function: getModificationValue
   Helper function to getComponentModifierValue
   Investigates modifications to find submodifier."
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input Absyn.ComponentRef inComponentRef;
  output Absyn.Modification outModification;
algorithm
  outModification:=
  matchcontinue (inAbsynElementArgLst,inComponentRef)
    local
      Boolean f;
      Absyn.Each each_;
      Absyn.ComponentRef cr1,cr2,name;
      Absyn.Modification mod,res;
      Option<String> cmt;
      list<Absyn.ElementArg> rest,args;
      String name1,name2;
      Option<Absyn.Exp> exp;
    case ((Absyn.MODIFICATION(finalPrefix = f,eachPrefix = each_,componentRef = cr1,modification = SOME(mod),comment = cmt) :: rest),cr2)
      equation
        true = Absyn.crefEqual(cr1, cr2);
      then
        mod;
    case ((Absyn.MODIFICATION(finalPrefix = f,eachPrefix = each_,componentRef = Absyn.CREF_IDENT(name = name1),modification = SOME(Absyn.CLASSMOD(elementArgLst=args)),comment = cmt) :: rest),Absyn.CREF_QUAL(name = name2,componentRef = cr2))
      equation
        true = stringEq(name1, name2);
        res = getModificationValue(args, cr2);
      then
        res;
    case ((_ :: rest),name)
      equation
        mod = getModificationValue(rest, name);
      then
        mod;
  end matchcontinue;
end getModificationValue;

protected function getComponentModifierNames
"function: getComponentModifierNames
   Return the modifiernames of a component, i.e. Foo f( )
   inputs:  (Absyn.ComponentRef, /* class */
               Absyn.ComponentRef, /* variable name */
               Absyn.Program)
   outputs:  string"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.Program inProgram3;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef1,inComponentRef2,inProgram3)
    local
      Absyn.Path p_class;
      String name,res_1,res_2;
      Absyn.Class cdef;
      list<Absyn.Element> comps;
      list<list<Absyn.ComponentItem>> compelts;
      list<Absyn.ComponentItem> compelts_1;
      list<Absyn.ElementArg> mod;
      list<String> res;
      Absyn.ComponentRef class_,ident;
      Absyn.Program p;
    case (class_,ident,p)
      equation
        p_class = Absyn.crefToPath(class_);
        Absyn.IDENT(name) = Absyn.crefToPath(ident);
        cdef = getPathedClassInProgram(p_class, p);
        comps = getComponentsInClass(cdef);
        compelts = List.map(comps, getComponentitemsInElement);
        compelts_1 = List.flatten(compelts);
        {Absyn.COMPONENTITEM(Absyn.COMPONENT(_,_,SOME(Absyn.CLASSMOD(mod,_))),_,_)} = List.select1(compelts_1, componentitemNamed, name);
        res = getModificationNames(mod);
        res_1 = stringDelimitList(res, ", ");
        res_2 = stringAppendList({"{",res_1,"}"});
      then
        res_2;
    case (_,_,_) then "{}";
  end matchcontinue;
end getComponentModifierNames;

protected function getModificationNames
"function: getModificationNames
  Helper function to getComponentModifierNames"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inAbsynElementArgLst)
    local
      list<String> names,names2,names2_1,names2_2,res;
      Boolean f;
      Absyn.Each each_;
      String name;
      Option<String> cmt;
      list<Absyn.ElementArg> rest,args;
      Absyn.ComponentRef cr;
    case ({}) then {};
    case ((Absyn.MODIFICATION(finalPrefix = f,eachPrefix = each_,componentRef = Absyn.CREF_IDENT(name = name),modification = NONE(),comment = cmt) :: rest))
      equation
        names = getModificationNames(rest);
      then
        (name :: names);
    case ((Absyn.MODIFICATION(finalPrefix = f,eachPrefix = each_,componentRef = cr,modification = SOME(Absyn.CLASSMOD({},_)),comment = cmt) :: rest))
      equation
        name = Dump.printComponentRefStr(cr);
        names = getModificationNames(rest);
      then
        (name :: names);
        // modifier with submodifiers -and- binding, e.g. m(...)=2, add also m to list
    case ((Absyn.MODIFICATION(finalPrefix = f,eachPrefix = each_,componentRef = cr,modification = SOME(Absyn.CLASSMOD(args,Absyn.EQMOD(exp=_))),comment = cmt) :: rest))
      equation
        name = Dump.printComponentRefStr(cr);
        names2 = getModificationNames(args);
        names2_1 = List.map1r(names2, stringAppend, ".");
        names2_2 = List.map1r(names2_1, stringAppend, name);
        names = getModificationNames(rest);
        res = listAppend(names2_2, names);
      then
        name::res;
      // modifier with submodifiers, e.g. m(...)
    case ((Absyn.MODIFICATION(finalPrefix = f,eachPrefix = each_,componentRef = cr,modification = SOME(Absyn.CLASSMOD(args,_)),comment = cmt) :: rest))
      equation
        name = Dump.printComponentRefStr(cr);
        names2 = getModificationNames(args);
        names2_1 = List.map1r(names2, stringAppend, ".");
        names2_2 = List.map1r(names2_1, stringAppend, name);
        names = getModificationNames(rest);
        res = listAppend(names2_2, names);
      then
        res;
    case ((_ :: rest))
      equation
        names = getModificationNames(rest);
      then
        names;
  end matchcontinue;
end getModificationNames;

protected function getComponentBinding
"function: getComponentBinding
   Returns the value of a component in a class.
   For example, the component
     Real x=1;
     returns 1.
   This can be used for both parameters, constants and variables.
   inputs: (Absyn.ComponentRef, /* class */
              Absyn.ComponentRef, /* variable name */
              Absyn.Program)
   outputs: string"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.Program inProgram3;
  output String outString;
algorithm
  outString := matchcontinue (inComponentRef1,inComponentRef2,inProgram3)
    local
      Absyn.Path p_class;
      String name,res;
      Absyn.Class cdef;
      list<Absyn.Element> comps;
      list<list<Absyn.ComponentItem>> compelts;
      list<Absyn.ComponentItem> compelts_1;
      Absyn.ComponentItem compitem;
      Absyn.Exp exp;
      Absyn.ComponentRef class_,crname;
      Absyn.Program p;
    
    case (class_,crname,p)
      equation
        p_class = Absyn.crefToPath(class_);
        Absyn.IDENT(name) = Absyn.crefToPath(crname);
        cdef = getPathedClassInProgram(p_class, p);
        comps = getComponentsInClass(cdef);
        compelts = List.map(comps, getComponentitemsInElement);
        compelts_1 = List.flatten(compelts);
        {compitem} = List.select1(compelts_1, componentitemNamed, name);
        exp = getVariableBindingInComponentitem(compitem);
        res = Dump.printExpStr(exp);
      then
        res;
    
    case (class_,crname,p)
      equation
        p_class = Absyn.crefToPath(class_);
        Absyn.IDENT(name) = Absyn.crefToPath(crname);
        cdef = getPathedClassInProgram(p_class, p);
        comps = getComponentsInClass(cdef);
        compelts = List.map(comps, getComponentitemsInElement);
        compelts_1 = List.flatten(compelts);
        {compitem} = List.select1(compelts_1, componentitemNamed, name);
        failure(_ = getVariableBindingInComponentitem(compitem));
      then 
        "";
    
    case (_,_,_) 
      then 
        "Error";
  end matchcontinue;
end getComponentBinding;

protected function getVariableBindingInComponentitem
"function: getVariableBindingInComponentitem
   Retrieve the variable binding from an ComponentItem"
  input Absyn.ComponentItem inComponentItem;
  output Absyn.Exp outExp;
algorithm
  outExp := match (inComponentItem)
    local Absyn.Exp e;
    case (Absyn.COMPONENTITEM(component = Absyn.COMPONENT(modification = SOME(Absyn.CLASSMOD(eqMod=Absyn.EQMOD(exp=e)))))) then e;
  end match;
end getVariableBindingInComponentitem;

protected function setParameterValue
"function: setParameterValue
   Sets the parameter value of a class and returns the updated program.
   inputs:  (Absyn.ComponentRef, /* class */
               Absyn.ComponentRef, /* ident */
               Absyn.Exp,          /* exp */
               Absyn.Program)
   outputs: (Absyn.Program,string)"
  input Absyn.ComponentRef inComponentRefClass;
  input Absyn.ComponentRef inComponentRefComponentName;
  input Absyn.Exp inBindingExp;
  input Absyn.Program inFullProgram;
  output Absyn.Program outProgram;
  output String outString;
algorithm
  (outProgram,outString) := matchcontinue (inComponentRefClass,inComponentRefComponentName,inBindingExp,inFullProgram)
    local
      Absyn.Path p_class;
      String varname, str;
      Absyn.Within within_;
      Absyn.Class cdef,cdef_1;
      Absyn.Program newp,p;
      Absyn.ComponentRef class_,name;
      Absyn.Exp exp;
      Absyn.TimeStamp ts;
      Boolean b;

    case (class_,name,exp,p as Absyn.PROGRAM(globalBuildTimes=ts))
      equation
        p_class = Absyn.crefToPath(class_);
        Absyn.IDENT(varname) = Absyn.crefToPath(name);
        within_ = buildWithin(p_class);
        cdef = getPathedClassInProgram(p_class, p);
        (cdef_1, b) = setVariableBindingInClass(cdef, varname, exp);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},within_,ts), p);
        str = Util.if_(b, "Ok", "Error: component with name: " +& varname +& " in class: " +& Absyn.pathString(p_class) +& " not found.");
      then
        (newp,str);
    
    case (class_,name,exp,p as Absyn.PROGRAM(globalBuildTimes=ts))
      equation
        p_class = Absyn.crefToPath(class_);
        Absyn.IDENT(varname) = Absyn.crefToPath(name);
        within_ = buildWithin(p_class);
        failure(_ = getPathedClassInProgram(p_class, p));
        str = "Error: class: " +& Absyn.pathString(p_class) +& " not found.";
      then
        (p,str);
    
    case (_,_,_,p) 
      then 
        (p,"Error");
  end matchcontinue;
end setParameterValue;

protected function setVariableBindingInClass
"function: setVariableBindingInClass
   Takes a class and an identifier and value an
   sets the variable binding to the passed expression."
  input Absyn.Class inClass;
  input Absyn.Ident inIdent;
  input Absyn.Exp inExp;
  output Absyn.Class outClass;
  output Boolean outChangeMade;
algorithm
  (outClass, outChangeMade) := match (inClass,inIdent,inExp)
    local
      list<Absyn.ClassPart> parts_1,parts;
      String id,id2,bcname;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      Absyn.Info file_info;
      Absyn.Exp exp;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
      Boolean b;
    
    // a class with parts
    case (Absyn.CLASS(name = id,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars,classParts = parts,comment = cmt),info = file_info),
          id2,exp)
      equation
        (parts_1, b) = setVariableBindingInClassparts(parts, id2, exp);
      then
        (Absyn.CLASS(id,p,f,e,r,Absyn.PARTS(typeVars,parts_1,cmt),file_info), b);
    
    // adrpo: handle also model extends M end M; 
    case (Absyn.CLASS(name = id,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName=bcname,modifications=modif,parts = parts,comment = cmt),info = file_info),
          id2,exp)
      equation
        (parts_1,b) = setVariableBindingInClassparts(parts, id2, exp);
      then
        (Absyn.CLASS(id,p,f,e,r,Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts_1),file_info), b);
  end match;
end setVariableBindingInClass;

protected function setVariableBindingInClassparts
"function: setVariableBindingInClassparts
   Sets a binding of a variable in a ClassPart
   list, named by the passed argument."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Absyn.Ident inIdent;
  input Absyn.Exp inExp;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
  output Boolean outChangeMade;
algorithm
  (outAbsynClassPartLst, outChangeMade) := matchcontinue (inAbsynClassPartLst,inIdent,inExp)
    local
      list<Absyn.ClassPart> res,rest;
      list<Absyn.ElementItem> elts_1,elts;
      String id;
      Absyn.Exp exp;
      Absyn.ClassPart elt;
      Boolean b1, b2, b;
      
    case ({},_,_) then ({}, false);
    
    case ((Absyn.PUBLIC(contents = elts) :: rest),id,exp)
      equation
        (res, b1) = setVariableBindingInClassparts(rest, id, exp);
        (elts_1, b2) = setVariableBindingInElementitems(elts, id, exp);
        b = boolOr(b1, b2);
      then
        (Absyn.PUBLIC(elts_1) :: res, b);
    
    case ((Absyn.PROTECTED(contents = elts) :: rest),id,exp)
      equation
        (res, b1) = setVariableBindingInClassparts(rest, id, exp);
        (elts_1, b2) = setVariableBindingInElementitems(elts, id, exp);
        b = boolOr(b1, b2);
      then
        (Absyn.PROTECTED(elts_1) :: res, b);
    
    case ((elt :: rest),id,exp)
      equation
        (res, b) = setVariableBindingInClassparts(rest, id, exp);
      then
        (elt :: res, b);
  end matchcontinue;
end setVariableBindingInClassparts;

protected function setVariableBindingInElementitems
"function: setVariableBindingInElementitems
   Sets a variable binding in a list of ElementItems"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Ident inIdent;
  input Absyn.Exp inExp;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
  output Boolean outChangeMade;
algorithm
  (outAbsynElementItemLst, outChangeMade) :=
  matchcontinue (inAbsynElementItemLst,inIdent,inExp)
    local
      list<Absyn.ElementItem> res,rest;
      Absyn.Element elt_1,elt;
      String id;
      Absyn.Exp exp;
      Absyn.ElementItem elitem;
      Boolean b1, b2, b;
    
    case ({},_,_) then ({}, false);
    
    case ((Absyn.ELEMENTITEM(element = elt) :: rest),id,exp)
      equation
        (res, b1) = setVariableBindingInElementitems(rest, id, exp);
        (elt_1, b2) = setVariableBindingInElement(elt, id, exp);
        b = boolOr(b1, b2);
      then
        (Absyn.ELEMENTITEM(elt_1) :: res, b);
    
    case ((elitem :: rest),id,exp)
      equation
        (res, b) = setVariableBindingInElementitems(rest, id, exp);
      then
        (elitem :: res, b);
  end matchcontinue;
end setVariableBindingInElementitems;

protected function setVariableBindingInElement
"function: setVariableBindingInElement
   Sets a variable binding in an Element."
  input Absyn.Element inElement;
  input Absyn.Ident inIdent;
  input Absyn.Exp inExp;
  output Absyn.Element outElement;
  output Boolean outChangeMade;
algorithm
  (outElement, outChangeMade) :=
  matchcontinue (inElement,inIdent,inExp)
    local
      list<Absyn.ComponentItem> compitems_1,compitems;
      Boolean f,b;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter i;
      String n,id;
      Absyn.ElementAttributes attr;
      Absyn.TypeSpec tp;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constr;
      Absyn.Exp exp;
      Absyn.Element elt;

    case (Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = i,name = n,specification = Absyn.COMPONENTS(attributes = attr,typeSpec = tp,components = compitems),info = info,constrainClass = constr),id,exp)
      equation
        (compitems_1, b) = setVariableBindingInCompitems(compitems, id, exp);
      then
        (Absyn.ELEMENT(f,r,i,n,Absyn.COMPONENTS(attr,tp,compitems_1),info,constr), b);
    
    case (elt,id,exp) then (elt, false);
  end matchcontinue;
end setVariableBindingInElement;

protected function setVariableBindingInCompitems
"function: setVariableBindingInCompitems
   Sets a variable binding in a ComponentItem list
   and returns true if it found it"
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Absyn.Ident inIdent;
  input Absyn.Exp inExp;
  output list<Absyn.ComponentItem> outAbsynComponentItemLst;
  output Boolean outChangeMade;
algorithm
  (outAbsynComponentItemLst,outChangeMade) := matchcontinue (inAbsynComponentItemLst,inIdent,inExp)
    local
      String id,id2;
      list<Absyn.Subscript> dim;
      list<Absyn.ElementArg> arg;
      Option<Absyn.Exp> cond;
      Option<Absyn.Comment> cmt;
      list<Absyn.ComponentItem> rest,res;
      Absyn.Exp exp;
      Absyn.ComponentItem item;
      Boolean b;
    
    case ({},_,_) then ({}, false);
    
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = dim,modification = SOME(Absyn.CLASSMOD(arg,_))),condition = cond,comment = cmt) :: rest),id2,exp)
      equation
        true = stringEq(id, id2);
      then
        ((Absyn.COMPONENTITEM(Absyn.COMPONENT(id,dim,SOME(Absyn.CLASSMOD(arg,Absyn.EQMOD(exp,Absyn.dummyInfo)))),cond,cmt) :: rest), true);
    
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = dim,modification = NONE()),condition = cond,comment = cmt) :: rest),id2,exp)
      equation
        true = stringEq(id, id2);
      then
        ((Absyn.COMPONENTITEM(Absyn.COMPONENT(id,dim,SOME(Absyn.CLASSMOD({},Absyn.EQMOD(exp,Absyn.dummyInfo)))),cond,cmt) :: rest), true);
    
    case (item :: rest,id,exp)
      equation
        (res, b) = setVariableBindingInCompitems(rest, id, exp);
      then
        (item :: res, b);
  end matchcontinue;
end setVariableBindingInCompitems;

public function buildWithin
"function: buildWithin
   From a fully qualified model name, build a suitable within clause"
  input Absyn.Path inPath;
  output Absyn.Within outWithin;
algorithm
  outWithin := matchcontinue (inPath)
    local Absyn.Path w_path,path;
    case (Absyn.IDENT(name = _)) then Absyn.TOP();
    case (Absyn.FULLYQUALIFIED(path)) // handle fully qual also!
      then
        buildWithin(path);
    case (path)
      equation
        w_path = Absyn.stripLast(path);
      then
        Absyn.WITHIN(w_path);
  end matchcontinue;
end buildWithin;

protected function componentitemNamed
"function: componentitemNamed
   Returns true if the component item has
   the name matching the second argument."
  input Absyn.ComponentItem inComponentItem;
  input Absyn.Ident inIdent;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inComponentItem,inIdent)
    local String id1,id2;
    case (Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id1)),id2)
      equation
        true = stringEq(id1, id2);
      then
        true;
    case (_,_) then false;
  end matchcontinue;
end componentitemNamed;

protected function getComponentitemName
"function: getComponentitemName
   Returns the name of a ComponentItem"
  input Absyn.ComponentItem inComponentItem;
  output Absyn.Ident outIdent;
algorithm
  outIdent := match (inComponentItem)
    local String id;
    case (Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id))) then id;
  end match;
end getComponentitemName;

protected function getComponentitemsInElement
"function: getComponentitemsInElement
   Retrieves the ComponentItems of a component Element.
   If Element is not a component, empty list is returned."
  input Absyn.Element inElement;
  output list<Absyn.ComponentItem> outAbsynComponentItemLst;
algorithm
  outAbsynComponentItemLst := matchcontinue (inElement)
    local list<Absyn.ComponentItem> l;
    case (Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = l))) then l;
    case (_) then {};
  end matchcontinue;
end getComponentitemsInElement;

protected function renameClass
"function: renameClass
   This function renames a class (given as a qualified path name) to a
   new name -in the same scope-. All references to the class name in the
   program is updated to the new name. Thefunction does not allow a
   renaming that will move the class to antoher package. To do this, the
   class must be copied.
   inputs:  (Absyn.Program,
               Absyn.ComponentRef, /* old class as qualified name A.B.C */
               Absyn.ComponentRef) /* new class, as identifier D */
   outputs:  Absyn.Program"
  input Absyn.Program inProgram1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output String outString;
  output Absyn.Program outProgram;
algorithm
  (outString,outProgram) := matchcontinue (inProgram1,inComponentRef2,inComponentRef3)
    local
      Absyn.Path new_path,old_path,new_path_1,old_path_no_last;
      String tmp_str,path_str_lst_no_empty,res;
      Absyn.Program p,p_1;
      Absyn.ComponentRef old_class,new_name;
      list<SCode.Element> pa_1;
      list<Env.Frame> env;
      list<String> path_str_lst;
    case (p,old_class,(new_name as Absyn.CREF_QUAL(name = _)))
      equation
        new_path = Absyn.crefToPath(new_name) "class in package" ;
        tmp_str = Absyn.pathString(new_path);
        print(tmp_str);
        print("\n") "the path is qualified so it cannot be renamed" ;
      then
        ("error",p);
    case (p,(old_class as Absyn.CREF_IDENT(name = _)),new_name)
      equation
        old_path = Absyn.crefToPath(old_class) "class in package" ;
        new_path = Absyn.crefToPath(new_name);
        pa_1 = SCodeUtil.translateAbsyn2SCode(p);
        (_,env) = Inst.makeEnvFromProgram(Env.emptyCache(),pa_1, Absyn.IDENT(""));
        ((p_1,_,(_,_,_,path_str_lst,_))) = traverseClasses(p, NONE(), renameClassVisitor, (old_path,new_path,p,{},env),
          true) "traverse protected" ;
        path_str_lst_no_empty = Util.stringDelimitListNonEmptyElts(path_str_lst, ",");
        res = stringAppendList({"{",path_str_lst_no_empty,"}"});
      then
        (res,p_1);
    case (p,(old_class as Absyn.CREF_QUAL(name = _)),new_name)
      equation
        old_path = Absyn.crefToPath(old_class) "class in package" ;
        new_path_1 = Absyn.crefToPath(new_name);
        old_path_no_last = Absyn.stripLast(old_path);
        new_path = Absyn.joinPaths(old_path_no_last, new_path_1);
        pa_1 = SCodeUtil.translateAbsyn2SCode(p);
        (_,env) = Inst.makeEnvFromProgram(Env.emptyCache(),pa_1, Absyn.IDENT(""));
        ((p_1,_,(_,_,_,path_str_lst,_))) = traverseClasses(p,NONE(), renameClassVisitor, (old_path,new_path,p,{},env),
          true) "traverse protected" ;
        path_str_lst_no_empty = Util.stringDelimitListNonEmptyElts(path_str_lst, ",");
        res = stringAppendList({"{",path_str_lst_no_empty,"}"});
      then
        (res,p_1);
  end matchcontinue;
end renameClass;

protected function renameClassVisitor
"function: renameClassVisitor
   This visitor renames a class given a new name.
   It returns a list of strings of renamed classes.
   The 'traversal-tuple' is therefore
   tuple<oldname, newname, program, string list, env>."
  input tuple<Absyn.Class, Option<Absyn.Path>, tuple<Absyn.Path, Absyn.Path, Absyn.Program, list<String>, Env.Env>> inTplAbsynClassAbsynPathOptionTplAbsynPathAbsynPathAbsynProgramStringLstEnvEnv;
  output tuple<Absyn.Class, Option<Absyn.Path>, tuple<Absyn.Path, Absyn.Path, Absyn.Program, list<String>, Env.Env>> outTplAbsynClassAbsynPathOptionTplAbsynPathAbsynPathAbsynProgramStringLstEnvEnv;
algorithm
  outTplAbsynClassAbsynPathOptionTplAbsynPathAbsynPathAbsynProgramStringLstEnvEnv:=
  matchcontinue (inTplAbsynClassAbsynPathOptionTplAbsynPathAbsynPathAbsynProgramStringLstEnvEnv)
    local
      Absyn.Path path_1,pa,old_class_path,new_class_path;
      String new_name,path_str,id,path_str_1;
      Boolean a,b,c,changed;
      Absyn.Restriction d;
      Absyn.ClassDef e;
      Absyn.Info file_info;
      Absyn.Program p;
      list<String> path_str_lst;
      list<Env.Frame> env,cenv;
      Absyn.Class class_1,class_;
      tuple<Absyn.Path, Absyn.Path, Absyn.Program, list<String>, list<Env.Frame>> args;
      Option<Absyn.Path> opath;

    // Skip readonly classes.
    case ((class_ as Absyn.CLASS(name = id,partialPrefix = a,finalPrefix = b,encapsulatedPrefix = c,restriction = d,body = e,info = file_info),opath,args))
      equation
        true = isReadOnly(file_info);
      then
        ((class_,opath,args));

    case ((Absyn.CLASS(name = id,partialPrefix = a,finalPrefix = b,encapsulatedPrefix = c,restriction = d,body = e,info = file_info),SOME(pa),(old_class_path,new_class_path,p,path_str_lst,env)))
      equation
        path_1 = Absyn.joinPaths(pa, Absyn.IDENT(id));
        true = Absyn.pathEqual(old_class_path, path_1);
        new_name = Absyn.pathLastIdent(new_class_path);
        path_str = Absyn.pathString(new_class_path);
      then
        ((Absyn.CLASS(new_name,a,b,c,d,e,file_info),SOME(pa),
          (old_class_path,new_class_path,p,(path_str :: path_str_lst),
          env)));
    
    case ((Absyn.CLASS(name = id,partialPrefix = a,finalPrefix = b,encapsulatedPrefix = c,restriction = d,body = e,info = file_info),NONE(),(old_class_path,new_class_path,p,path_str_lst,env)))
      equation
        path_1 = Absyn.IDENT(id);
        true = Absyn.pathEqual(old_class_path, path_1);
        new_name = Absyn.pathLastIdent(new_class_path);
        path_str = Absyn.pathString(new_class_path);
      then
        ((Absyn.CLASS(new_name,a,b,c,d,e,file_info),NONE(),
          (old_class_path,new_class_path,p,(path_str :: path_str_lst),
          env)));
    
    case (((class_ as Absyn.CLASS(name = id,partialPrefix = a,finalPrefix = b,encapsulatedPrefix = c,restriction = d,body = e,info = file_info)),SOME(pa),(old_class_path,new_class_path,p,path_str_lst,env)))
      equation
        path_1 = Absyn.joinPaths(pa, Absyn.IDENT(id));
        cenv = Dependency.getClassEnvNoElaboration(p, path_1, env) "get_class_env(p,path\') => cenv &" ;
        (class_1,changed) = renameClassInClass(class_, old_class_path, new_class_path, cenv);
        path_str_1 = Absyn.pathString(path_1);
        path_str = Util.if_(changed, path_str_1, "");
      then
        ((class_1,SOME(pa),
          (old_class_path,new_class_path,p,(path_str :: path_str_lst),
          env)));
    
    case (((class_ as Absyn.CLASS(name = id,partialPrefix = a,finalPrefix = b,encapsulatedPrefix = c,restriction = d,body = e,info = file_info)),NONE(),(old_class_path,new_class_path,p,path_str_lst,env)))
      equation
        path_1 = Absyn.IDENT(id);
        cenv = Dependency.getClassEnvNoElaboration(p, path_1, env) "get_class_env(p,path\') => cenv &" ;
        (class_1,changed) = renameClassInClass(class_, old_class_path, new_class_path, cenv);
        path_str_1 = Absyn.pathString(path_1);
        path_str = Util.if_(changed, path_str_1, "");
      then
        ((class_1,NONE(),
          (old_class_path,new_class_path,p,(path_str :: path_str_lst),
          env)));
    
    case ((class_,opath,args))
      then
        ((class_,opath,args));
  end matchcontinue;
end renameClassVisitor;

protected function renameClassInClass
"author: x02lucpo
  helper function to renameClassVisitor
  renames all the references to a class to another"
  input Absyn.Class inClass1;
  input Absyn.Path inPath2;
  input Absyn.Path inPath3;
  input Env.Env inEnv4;
  output Absyn.Class outClass;
  output Boolean outBoolean;
algorithm
  (outClass,outBoolean):=
  matchcontinue (inClass1,inPath2,inPath3,inEnv4)
    local
      list<Absyn.ClassPart> parts_1,parts;
      Boolean changed,partialPrefix,finalPrefix,encapsulatedPrefix;
      String name, baseClassName;
      Absyn.Restriction restriction;
      Option<String> comment;
      Absyn.Info file_info;
      Absyn.Path old_comp,new_comp,path_1,path,new_path;
      list<Env.Frame> env,cenv;
      list<Absyn.ElementArg> modifications,elementarg;
      Option<Absyn.Comment> co;
      Absyn.Class class_;
      Option<list<Absyn.Subscript>> subscripts;
      Absyn.ElementAttributes attrs;
      Env.Cache cache;
      list<String> typeVars;

    /* the class with the component the old name for the component signal if something in class have been changed */
    case (Absyn.CLASS(name = name,partialPrefix = partialPrefix,finalPrefix = finalPrefix,encapsulatedPrefix = encapsulatedPrefix,restriction = restriction,
                      body = Absyn.PARTS(typeVars = typeVars,classParts = parts,comment = comment),info = file_info),old_comp,new_comp,env)
      equation
        (parts_1,changed) = renameClassInParts(parts, old_comp, new_comp, env);
      then
        (Absyn.CLASS(name,partialPrefix,finalPrefix,encapsulatedPrefix,restriction,Absyn.PARTS(typeVars,parts_1,comment),file_info),changed);
    /* model extends M end M; */
    case (Absyn.CLASS(name = name,partialPrefix = partialPrefix,finalPrefix = finalPrefix,encapsulatedPrefix = encapsulatedPrefix,restriction = restriction,
                      body = Absyn.CLASS_EXTENDS(baseClassName = baseClassName,modifications = modifications,comment = comment,parts = parts),
                      info = file_info),old_comp,new_comp,env)
      equation
        (parts_1,changed) = renameClassInParts(parts, old_comp, new_comp, env);
      then
        (Absyn.CLASS(name,partialPrefix,finalPrefix,encapsulatedPrefix,restriction,Absyn.CLASS_EXTENDS(baseClassName,modifications,comment,parts_1),file_info),changed);
    /* a derived class */
    case (Absyn.CLASS(name = name,partialPrefix = partialPrefix,finalPrefix = finalPrefix,encapsulatedPrefix = encapsulatedPrefix,restriction = restriction,
                      body = Absyn.DERIVED(typeSpec=Absyn.TPATH(path_1,subscripts),attributes = attrs,arguments = elementarg,comment = co),
                      info = file_info),old_comp,new_comp,env)
      equation
        (cache,SCode.CLASS(name=name),cenv) = Lookup.lookupClass(Env.emptyCache(), env, path_1, false);
        path_1 = Absyn.IDENT(name);
        (_,path) = Inst.makeFullyQualified(cache, cenv, path_1);
        true = Absyn.pathEqual(path, old_comp);
        new_path = changeLastIdent(path_1, new_comp);
      then
        (Absyn.CLASS(name,partialPrefix,finalPrefix,encapsulatedPrefix,restriction,Absyn.DERIVED(Absyn.TPATH(new_path,subscripts),attrs,elementarg,co),file_info),true);
    /* otherwise */
    case (class_,old_comp,new_comp,env) then (class_,false);

  end matchcontinue;
end renameClassInClass;

protected function renameClassInParts
"author: x02lucpo
  helper function to renameClassVisitor"
  input list<Absyn.ClassPart> inAbsynClassPartLst1;
  input Absyn.Path inPath2;
  input Absyn.Path inPath3;
  input Env.Env inEnv4;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
  output Boolean outBoolean;
algorithm
  (outAbsynClassPartLst,outBoolean):=
  matchcontinue (inAbsynClassPartLst1,inPath2,inPath3,inEnv4)
    local
      list<Env.Frame> env;
      list<Absyn.ClassPart> res_1,res;
      Boolean changed1,changed2,changed;
      list<Absyn.ElementItem> elements_1,elements;
      Absyn.Path old_comp,new_comp;
      Absyn.ClassPart a;
    case ({},_,_,env) then ({},false);  /* the old name for the component signal if something in class have been changed rule */
    case ((Absyn.PUBLIC(contents = elements) :: res),old_comp,new_comp,env)
      equation
        (res_1,changed1) = renameClassInParts(res, old_comp, new_comp, env);
        (elements_1,changed2) = renameClassInElements(elements, old_comp, new_comp, env);
        changed = Util.boolOrList({changed1,changed2});
      then
        ((Absyn.PUBLIC(elements_1) :: res_1),changed);
    case ((Absyn.PROTECTED(contents = elements) :: res),old_comp,new_comp,env)
      equation
        (res_1,changed1) = renameClassInParts(res, old_comp, new_comp, env);
        (elements_1,changed2) = renameClassInElements(elements, old_comp, new_comp, env);
        changed = Util.boolOrList({changed1,changed2});
      then
        ((Absyn.PROTECTED(elements_1) :: res_1),changed);
    case ((a :: res),old_comp,new_comp,env)
      equation
        (res_1,changed) = renameClassInParts(res, old_comp, new_comp, env);
      then
        ((a :: res_1),changed);
  end matchcontinue;
end renameClassInParts;

protected function renameClassInElements
"author: x02lucpo
  helper function to renameClassVisitor"
  input list<Absyn.ElementItem> inAbsynElementItemLst1;
  input Absyn.Path inPath2;
  input Absyn.Path inPath3;
  input Env.Env inEnv4;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
  output Boolean outBoolean;
algorithm
  (outAbsynElementItemLst,outBoolean):=
  matchcontinue (inAbsynElementItemLst1,inPath2,inPath3,inEnv4)
    local
      list<Absyn.ElementItem> res_1,res;
      Boolean changed1,changed2,changed,finalPrefix;
      Absyn.ElementSpec elementspec_1,elementspec;
      Absyn.ElementItem element_1,element;
      Option<Absyn.RedeclareKeywords> redeclare_;
      Absyn.InnerOuter inner_outer;
      String name;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constrainClass;
      Absyn.Path old_comp,new_comp;
      list<Env.Frame> env;
    case ({},_,_,_) then ({},false);  /* the old name for the component signal if something in class have been changed */
    case (((element as Absyn.ELEMENTITEM(element = Absyn.ELEMENT(finalPrefix = finalPrefix,redeclareKeywords = redeclare_,innerOuter = inner_outer,name = name,specification = elementspec,info = info,constrainClass = constrainClass))) :: res),old_comp,new_comp,env)
      equation
        (res_1,changed1) = renameClassInElements(res, old_comp, new_comp, env);
        (elementspec_1,changed2) = renameClassInElementSpec(elementspec, old_comp, new_comp, env);
        element_1 = Absyn.ELEMENTITEM(
          Absyn.ELEMENT(finalPrefix,redeclare_,inner_outer,name,elementspec_1,info,
          constrainClass));
        changed = Util.boolOrList({changed1,changed2});
      then
        ((element_1 :: res_1),changed);
    case ((element :: res),old_comp,new_comp,env)
      equation
        (res_1,changed) = renameClassInElements(res, old_comp, new_comp, env);
        element_1 = element;
      then
        ((element_1 :: res_1),changed);
  end matchcontinue;
end renameClassInElements;

protected function renameClassInElementSpec
"author: x02lucpo
  helper function to renameClassVisitor"
  input Absyn.ElementSpec inElementSpec1;
  input Absyn.Path inPath2;
  input Absyn.Path inPath3;
  input Env.Env inEnv4;
  output Absyn.ElementSpec outElementSpec;
  output Boolean outBoolean;
algorithm
  (outElementSpec,outBoolean):=
  matchcontinue (inElementSpec1,inPath2,inPath3,inEnv4)
    local
      String id;
      list<Env.Frame> cenv,env;
      Absyn.Path path_1,path,new_path,old_comp,new_comp,comps;
      Absyn.ElementAttributes a;
      list<Absyn.ComponentItem> comp_items;
      Absyn.Import import_1,import_;
      Boolean changed;
      Option<Absyn.ArrayDim> x;
      Option<Absyn.Annotation> annOpt;
      Env.Cache cache;
      Absyn.ElementSpec spec;
      Option<Absyn.Comment> cmt;
      list<Absyn.ElementArg> elargs;
      Absyn.Info info;

    case (Absyn.COMPONENTS(attributes = a,typeSpec = Absyn.TPATH(path_1,x),components = comp_items),old_comp,new_comp,env) /* the old name for the component signal if something in class have been changed rule */
      equation
        (cache,SCode.CLASS(name=id),cenv) = Lookup.lookupClass(Env.emptyCache(),env, path_1, false);
        path_1 = Absyn.IDENT(id);
        (_,path) = Inst.makeFullyQualified(cache, cenv, path_1);
        true = Absyn.pathEqual(path, old_comp);
        new_path = changeLastIdent(path, new_comp);
      then
        (Absyn.COMPONENTS(a,Absyn.TPATH(new_path,x),comp_items),true);
    case (Absyn.EXTENDS(path = path_1,elementArg = elargs, annotationOpt=annOpt),old_comp,new_comp,env)
      equation
        (cache,_,cenv) = Lookup.lookupClass(Env.emptyCache(),env, path_1, false) "print \"rename_class_in_element_spec Absyn.EXTENDS(path,_) not implemented yet\"" ;
        (_,path) = Inst.makeFullyQualified(cache,cenv, path_1);
        true = Absyn.pathEqual(path, old_comp);
        new_path = changeLastIdent(path_1, new_comp);
      then
        (Absyn.EXTENDS(new_path,elargs,annOpt),true);
    case (Absyn.IMPORT(import_ = import_,comment = cmt, info = info),old_comp,new_comp,env)
      equation
        (import_1,changed) = renameClassInImport(import_, old_comp, new_comp, env);
      then
        (Absyn.IMPORT(import_1,cmt,info),changed);
    case (spec,_,comps,env) then (spec,false);
  end matchcontinue;
end renameClassInElementSpec;

protected function renameClassInImport
"author: x02lucpo
  helper function to renameClassVisitor"
  input Absyn.Import inImport1;
  input Absyn.Path inPath2;
  input Absyn.Path inPath3;
  input Env.Env inEnv4;
  output Absyn.Import outImport;
  output Boolean outBoolean;
algorithm
  (outImport,outBoolean):=
  matchcontinue (inImport1,inPath2,inPath3,inEnv4)
    local
      list<Env.Frame> cenv,env;
      Absyn.Path path,new_path,path_1,old_comp,new_comp;
      String id;
      Absyn.Import import_;
      Env.Cache cache;

    case (Absyn.NAMED_IMPORT(name = id,path = path_1),old_comp,new_comp,env) /* the old name for the component signal if something in class have been changed */
      equation
        (cache,_,cenv) = Lookup.lookupClass(Env.emptyCache(),env, path_1, false);
        (_,path) = Inst.makeFullyQualified(cache,cenv, path_1);
        true = Absyn.pathEqual(path, old_comp);
        new_path = changeLastIdent(path_1, new_comp);
      then
        (Absyn.NAMED_IMPORT(id,new_path),true);
    case (Absyn.QUAL_IMPORT(path = path_1),old_comp,new_comp,env)
      equation
        (cache,_,cenv) = Lookup.lookupClass(Env.emptyCache(),env, path_1, false);
        (_,path) = Inst.makeFullyQualified(cache,cenv, path_1);
        true = Absyn.pathEqual(path, old_comp);
        new_path = changeLastIdent(path_1, new_comp);
      then
        (Absyn.QUAL_IMPORT(new_path),true);
    case (Absyn.NAMED_IMPORT(name = id,path = path_1),old_comp,new_comp,env)
      equation
        (cache,_,cenv) = Lookup.lookupClass(Env.emptyCache(),env, path_1, false);
        (_,path) = Inst.makeFullyQualified(cache,cenv, path_1);
        true = Absyn.pathEqual(path, old_comp);
        new_path = changeLastIdent(path_1, new_comp);
      then
        (Absyn.UNQUAL_IMPORT(new_path),true);
    case (import_,old_comp,new_comp,env) then (import_,false);
  end matchcontinue;
end renameClassInImport;

protected function changeLastIdent
"function changeLastIdent
  author: x02lucpo
  chages the last ident of the first path to the last path ident ie:
  (A.B.CC,C.DD) => (A.B.DD)"
  input Absyn.Path inPath1;
  input Absyn.Path inPath2;
  output Absyn.Path outPath;
algorithm
  outPath:=
  match (inPath1,inPath2)
    local
      String a,b,b_1;
      Absyn.Path a_1,res,p1,p2;
    case (Absyn.IDENT(name = a),Absyn.IDENT(name = b)) then Absyn.IDENT(b);
    case ((Absyn.IDENT(name = _)),(p2 as Absyn.QUALIFIED(name = _)))
      equation
        b_1 = Absyn.pathLastIdent(p2);
      then
        Absyn.IDENT(b_1);
    case ((p1 as Absyn.QUALIFIED(name = _)),(p2 as Absyn.IDENT(name = _)))
      equation
        a_1 = Absyn.stripLast(p1);
        res = Absyn.joinPaths(a_1, p2);
      then
        res;
    case ((p1 as Absyn.QUALIFIED(name = _)),(p2 as Absyn.QUALIFIED(name = _)))
      equation
        a_1 = Absyn.stripLast(p1);
        b_1 = Absyn.pathLastIdent(p2);
        res = Absyn.joinPaths(a_1, Absyn.IDENT(b_1));
      then
        res;
  end match;
end changeLastIdent;

public function traverseClasses
"function: traverseClasses
   This function traverses all classes of a program and applies a function
   to each class. The function takes the Absyn.Class, Absyn.Path option
   and an additional argument and returns an updated class and the
   additional values. The Absyn.Path option contains the path to the class
   that is traversed.
   inputs:  (Absyn.Program,
               Absyn.Path option,
               ((Absyn.Class  Absyn.Path option  \'a) => (Absyn.Class  Absyn.Path option  \'a)),  /* rel-ation to apply */
            \'a, /* extra value passed to re-lation */
            bool) /* true = traverse protected elements */
   outputs: (Absyn.Program   Absyn.Path option  \'a)"
  input Absyn.Program inProgram;
  input Option<Absyn.Path> inAbsynPathOption;
  input FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a inFuncTypeTplAbsynClassAbsynPathOptionTypeAToTplAbsynClassAbsynPathOptionTypeA;
  input Type_a inTypeA;
  input Boolean inBoolean;
  output tuple<Absyn.Program, Option<Absyn.Path>, Type_a> outTplAbsynProgramAbsynPathOptionTypeA;
  partial function FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a
    input tuple<Absyn.Class, Option<Absyn.Path>, Type_a> inTplAbsynClassAbsynPathOptionTypeA;
    output tuple<Absyn.Class, Option<Absyn.Path>, Type_a> outTplAbsynClassAbsynPathOptionTypeA;
    replaceable type Type_a subtypeof Any;
  end FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a;
  replaceable type Type_a subtypeof Any;
algorithm
  outTplAbsynProgramAbsynPathOptionTypeA:=
  match (inProgram,inAbsynPathOption,inFuncTypeTplAbsynClassAbsynPathOptionTypeAToTplAbsynClassAbsynPathOptionTypeA,inTypeA,inBoolean)
    local
      list<Absyn.Class> lst_1,lst;
      Option<Absyn.Path> pa_1,pa;
      Type_a args_1,args;
      Absyn.Within within_;
      FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a visitor;
      Boolean traverse_prot;
      Absyn.TimeStamp ts;

    case (Absyn.PROGRAM(classes = lst,within_ = within_,globalBuildTimes=ts),pa,visitor,args,traverse_prot)
      equation
        ((lst_1,pa_1,args_1)) = traverseClasses2(lst, pa, visitor, args, traverse_prot);
      then
        ((Absyn.PROGRAM(lst_1,within_,ts),pa_1,args_1));
  end match;
end traverseClasses;

protected function traverseClasses2
"function: traverseClasses2
   Helperfunction to traverseClasses."
  input list<Absyn.Class> inAbsynClassLst;
  input Option<Absyn.Path> inAbsynPathOption;
  input FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a inFuncTypeTplAbsynClassAbsynPathOptionTypeAToTplAbsynClassAbsynPathOptionTypeA;
  input Type_a inTypeA "extra argument";
  input Boolean inBoolean "visit protected elements";
  output tuple<list<Absyn.Class>, Option<Absyn.Path>, Type_a> outTplAbsynClassLstAbsynPathOptionTypeA;
  partial function FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a
    input tuple<Absyn.Class, Option<Absyn.Path>, Type_a> inTplAbsynClassAbsynPathOptionTypeA;
    output tuple<Absyn.Class, Option<Absyn.Path>, Type_a> outTplAbsynClassAbsynPathOptionTypeA;
    replaceable type Type_a subtypeof Any;
  end FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a;
  replaceable type Type_a subtypeof Any;
algorithm
  outTplAbsynClassLstAbsynPathOptionTypeA:=
  matchcontinue (inAbsynClassLst,inAbsynPathOption,inFuncTypeTplAbsynClassAbsynPathOptionTypeAToTplAbsynClassAbsynPathOptionTypeA,inTypeA,inBoolean)
    local
      Option<Absyn.Path> pa,pa_1,pa_2,pa_3;
      FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a visitor;
      Type_a args,args_1,args_2,args_3;
      Absyn.Class class_1,class_2,class_;
      list<Absyn.Class> classes_1,classes;
      Boolean traverse_prot;
    case ({},pa,visitor,args,_) then (({},pa,args));
    case ((class_ :: classes),pa,visitor,args,traverse_prot)
      equation
        ((class_1,pa_1,args_1)) = visitor((class_,pa,args));
        ((class_2,pa_2,args_2)) = traverseInnerClass(class_1, pa, visitor, args_1, traverse_prot);
        ((classes_1,pa_3,args_3)) = traverseClasses2(classes, pa, visitor, args_2, traverse_prot);
      then
        (((class_2 :: classes_1),pa_3,args_3));

    /* Visitor failed, but class contains inner classes after traversal, i.e. those inner classes didn't fail, and thus
    the class must be included also */
      case ((class_ :: classes),pa,visitor,args,traverse_prot)
      equation
        ((class_2,pa_2,args_2)) = traverseInnerClass(class_, pa, visitor, args, traverse_prot);
        true = classHasLocalClasses(class_2);
        ((classes_1,pa_3,args_3)) = traverseClasses2(classes, pa, visitor, args_2, traverse_prot);
      then
        (((class_2 :: classes_1),pa_3,args_3));

    /* Visitor failed, remove class */
    case ((class_ :: classes),pa,visitor,args,traverse_prot)
      equation
        ((classes_1,pa_3,args_3)) = traverseClasses2(classes, pa, visitor, args, traverse_prot);
      then
        ((classes_1,pa_3,args_3));
    case ((class_ :: classes),_,_,_,_)
      equation
        print("-traverse_classes2 failed on class:");
        print(Absyn.pathString(Absyn.className(class_)));
        print("\n");
      then
        fail();
  end matchcontinue;
end traverseClasses2;

protected function classHasLocalClasses
"Returns true if class contains a local class"
  input Absyn.Class cl;
  output Boolean res;
algorithm
  res := match(cl)
  local list<Absyn.ClassPart> parts;
    /* a class with parts */
    case(Absyn.CLASS(body= Absyn.PARTS(classParts = parts))) equation
      res = partsHasLocalClass(parts);
    then res;
    /* an extended class with parts: model extends M end M; */
    case(Absyn.CLASS(body= Absyn.CLASS_EXTENDS(parts = parts))) equation
      res = partsHasLocalClass(parts);
    then res;
  end match;
end classHasLocalClasses;

protected function partsHasLocalClass
"Help function to classHasLocalClass"
  input list<Absyn.ClassPart> inParts;
  output Boolean res;
algorithm
  res := matchcontinue(inParts)
  local list<Absyn.ElementItem> elts; list<Absyn.ClassPart> parts; 
    case(Absyn.PUBLIC(elts)::parts) equation
      true = eltsHasLocalClass(elts);
    then true;
    case(Absyn.PROTECTED(elts)::parts) equation
      true = eltsHasLocalClass(elts);
    then true;
    case(_::parts) then partsHasLocalClass(parts);
    case(_) then false;
  end matchcontinue;
end partsHasLocalClass;

protected function eltsHasLocalClass
"help function to partsHasLocalClass"
  input list<Absyn.ElementItem> inElts;
  output Boolean res;
algorithm
  res := matchcontinue(inElts) 
    local list<Absyn.ElementItem> elts;
    case(Absyn.ELEMENTITEM(Absyn.ELEMENT(specification=Absyn.CLASSDEF(class_=_)))::elts) then true;
    case(_::elts) then eltsHasLocalClass(elts);
    case(_) then false;
  end matchcontinue;
end eltsHasLocalClass;

protected function traverseInnerClass
"function: traverseInnerClass
   Helperfunction to traverseClasses2. This function traverses all inner classes of a class."
  input Absyn.Class inClass;
  input Option<Absyn.Path> inAbsynPathOption;
  input FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a inFuncTypeTplAbsynClassAbsynPathOptionTypeAToTplAbsynClassAbsynPathOptionTypeA;
  input Type_a inTypeA "extra value";
  input Boolean inBoolean "if true, traverse protected elts";
  output tuple<Absyn.Class, Option<Absyn.Path>, Type_a> outTplAbsynClassAbsynPathOptionTypeA;
  partial function FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a
    input tuple<Absyn.Class, Option<Absyn.Path>, Type_a> inTplAbsynClassAbsynPathOptionTypeA;
    output tuple<Absyn.Class, Option<Absyn.Path>, Type_a> outTplAbsynClassAbsynPathOptionTypeA;
    replaceable type Type_a subtypeof Any;
  end FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a;
  replaceable type Type_a subtypeof Any;
algorithm
  outTplAbsynClassAbsynPathOptionTypeA:=
  matchcontinue (inClass,inAbsynPathOption,inFuncTypeTplAbsynClassAbsynPathOptionTypeAToTplAbsynClassAbsynPathOptionTypeA,inTypeA,inBoolean)
    local
      Absyn.Path tmp_pa,pa;
      list<Absyn.ClassPart> parts_1,parts;
      Option<Absyn.Path> pa_1;
      Type_a args_1,args;
      String name,bcname;
      Boolean p,f,e,visit_prot;
      Absyn.Restriction r;
      Option<String> str_opt;
      Absyn.Info file_info;
      FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a visitor;
      Absyn.Class cl;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;

    /* a class with parts */
    case (Absyn.CLASS(name = name,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars, classParts = parts,comment = str_opt),info = file_info),
          SOME(pa),visitor,args,visit_prot)
      equation
        tmp_pa = Absyn.joinPaths(pa, Absyn.IDENT(name));
        ((parts_1,pa_1,args_1)) = traverseInnerClassParts(parts, SOME(tmp_pa), visitor, args, visit_prot);
      then
        ((Absyn.CLASS(name,p,f,e,r,Absyn.PARTS(typeVars,parts_1,str_opt),file_info),pa_1,args_1));

    case (Absyn.CLASS(name = name,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars, classParts = parts,comment = str_opt),info = file_info),
          NONE(),visitor,args,visit_prot)
      equation
        ((parts_1,pa_1,args_1)) = traverseInnerClassParts(parts, SOME(Absyn.IDENT(name)), visitor, args, visit_prot);
      then
        ((Absyn.CLASS(name,p,f,e,r,Absyn.PARTS(typeVars, parts_1,str_opt),file_info),pa_1,args_1));

    case (Absyn.CLASS(name = name,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars, classParts = parts,comment = str_opt),info = file_info),
          pa_1,visitor,args,visit_prot)
      equation
        ((parts_1,pa_1,args_1)) = traverseInnerClassParts(parts, pa_1, visitor, args, visit_prot);
      then
        ((Absyn.CLASS(name,p,f,e,r,Absyn.PARTS(typeVars,parts_1,str_opt),file_info),pa_1,args_1));

    /* adrpo: handle also an extended class with parts: model extends M end M; */
    case (Absyn.CLASS(name = name,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName=bcname,modifications=modif,parts = parts,comment = str_opt),info = file_info),
          SOME(pa),visitor,args,visit_prot)
      equation
        tmp_pa = Absyn.joinPaths(pa, Absyn.IDENT(name));
        ((parts_1,pa_1,args_1)) = traverseInnerClassParts(parts, SOME(tmp_pa), visitor, args, visit_prot);
      then
        ((Absyn.CLASS(name,p,f,e,r,Absyn.CLASS_EXTENDS(bcname,modif,str_opt,parts_1),file_info),pa_1,args_1));

    case (Absyn.CLASS(name = name,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName=bcname,modifications=modif,parts = parts,comment = str_opt),info = file_info),
          NONE(),visitor,args,visit_prot)
      equation
        ((parts_1,pa_1,args_1)) = traverseInnerClassParts(parts, SOME(Absyn.IDENT(name)), visitor, args, visit_prot);
      then
        ((Absyn.CLASS(name,p,f,e,r,Absyn.CLASS_EXTENDS(bcname,modif,str_opt,parts_1),file_info),pa_1,args_1));

    case (Absyn.CLASS(name = name,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName=bcname,modifications=modif,parts = parts,comment = str_opt),info = file_info),
          pa_1,visitor,args,visit_prot)
      equation
        ((parts_1,pa_1,args_1)) = traverseInnerClassParts(parts, pa_1, visitor, args, visit_prot);
      then
        ((Absyn.CLASS(name,p,f,e,r,Absyn.CLASS_EXTENDS(bcname,modif,str_opt,parts_1),file_info),pa_1,args_1));

    /* otherwise */
    case (cl,pa_1,_,args,_) then ((cl,pa_1,args));
  end matchcontinue;
end traverseInnerClass;

protected function traverseInnerClassParts
"function: traverseInnerClassParts
   Helper function to traverseInnerClass"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Option<Absyn.Path> inAbsynPathOption;
  input FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a inFuncTypeTplAbsynClassAbsynPathOptionTypeAToTplAbsynClassAbsynPathOptionTypeA;
  input Type_a inTypeA "extra argument";
  input Boolean inBoolean "visist protected elts";
  output tuple<list<Absyn.ClassPart>, Option<Absyn.Path>, Type_a> outTplAbsynClassPartLstAbsynPathOptionTypeA;
  partial function FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a
    input tuple<Absyn.Class, Option<Absyn.Path>, Type_a> inTplAbsynClassAbsynPathOptionTypeA;
    output tuple<Absyn.Class, Option<Absyn.Path>, Type_a> outTplAbsynClassAbsynPathOptionTypeA;
    replaceable type Type_a subtypeof Any;
  end FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a;
  replaceable type Type_a subtypeof Any;
algorithm
  outTplAbsynClassPartLstAbsynPathOptionTypeA:=
  matchcontinue (inAbsynClassPartLst,inAbsynPathOption,inFuncTypeTplAbsynClassAbsynPathOptionTypeAToTplAbsynClassAbsynPathOptionTypeA,inTypeA,inBoolean)
    local
      Option<Absyn.Path> pa,pa_1,pa_2;
      Type_a args,args_1,args_2;
      list<Absyn.ElementItem> elts_1,elts;
      list<Absyn.ClassPart> parts_1,parts;
      FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a visitor;
      Boolean visit_prot;
      Absyn.ClassPart part;
    case ({},pa,_,args,_) then (({},pa,args));
    case ((Absyn.PUBLIC(contents = elts) :: parts),pa,visitor,args,visit_prot)
      equation
        ((elts_1,pa_1,args_1)) = traverseInnerClassElements(elts, pa, visitor, args, visit_prot);
        ((parts_1,pa_2,args_2)) = traverseInnerClassParts(parts, pa, visitor, args_1, visit_prot);
      then
        (((Absyn.PUBLIC(elts_1) :: parts_1),pa_2,args_2));
    case ((Absyn.PROTECTED(contents = elts) :: parts),pa,visitor,args,true)
      equation
        ((elts_1,pa_1,args_1)) = traverseInnerClassElements(elts, pa, visitor, args, true);
        ((parts_1,pa_2,args_2)) = traverseInnerClassParts(parts, pa, visitor, args_1, true);
      then
        (((Absyn.PROTECTED(elts_1) :: parts_1),pa_2,args_2));
    case ((part :: parts),pa,visitor,args,true)
      equation
        ((parts_1,pa_1,args_1)) = traverseInnerClassParts(parts, pa, visitor, args, true);
      then
        (((part :: parts_1),pa_1,args_1));
  end matchcontinue;
end traverseInnerClassParts;

protected function traverseInnerClassElements
"function traverseInnerClassElements
   Helper function to traverseInnerClassParts"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Option<Absyn.Path> inAbsynPathOption;
  input FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a inFuncTypeTplAbsynClassAbsynPathOptionTypeAToTplAbsynClassAbsynPathOptionTypeA;
  input Type_a inTypeA;
  input Boolean inBoolean "visit protected elts";
  output tuple<list<Absyn.ElementItem>, Option<Absyn.Path>, Type_a> outTplAbsynElementItemLstAbsynPathOptionTypeA;
  partial function FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a
    input tuple<Absyn.Class, Option<Absyn.Path>, Type_a> inTplAbsynClassAbsynPathOptionTypeA;
    output tuple<Absyn.Class, Option<Absyn.Path>, Type_a> outTplAbsynClassAbsynPathOptionTypeA;
    replaceable type Type_a subtypeof Any;
  end FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a;
  replaceable type Type_a subtypeof Any;
algorithm
  outTplAbsynElementItemLstAbsynPathOptionTypeA:=
  matchcontinue (inAbsynElementItemLst,inAbsynPathOption,inFuncTypeTplAbsynClassAbsynPathOptionTypeAToTplAbsynClassAbsynPathOptionTypeA,inTypeA,inBoolean)
    local
      Option<Absyn.Path> pa,pa_1,pa_2;
      Type_a args,args_1,args_2;
      Absyn.ElementSpec elt_spec_1,elt_spec;
      list<Absyn.ElementItem> elts_1,elts;
      Boolean f,visit_prot;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter io;
      String n;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constr;
      FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a visitor;
      Absyn.ElementItem elt;
      Boolean repl;
      Absyn.Class cl;
    case ({},pa,_,args,_) then (({},pa,args));
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = io,name = n,specification = elt_spec,info = info,constrainClass = constr)) :: elts),pa,visitor,args,visit_prot)
      equation
        ((elt_spec_1,pa_1,args_1)) = traverseInnerClassElementspec(elt_spec, pa, visitor, args, visit_prot);
        ((elts_1,pa_2,args_2)) = traverseInnerClassElements(elts, pa, visitor, args_1, visit_prot);
      then
        ((
          (Absyn.ELEMENTITEM(Absyn.ELEMENT(f,r,io,n,elt_spec_1,info,constr)) :: elts_1),pa_2,args_2));

   /* Visitor failed in elementspec, but inner classes succeeded, include class */
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = io,name = n,specification = Absyn.CLASSDEF(repl,cl),info = info,constrainClass = constr)) :: elts),pa,visitor,args,visit_prot)
      equation
         ((cl,pa_1,args_1)) = traverseInnerClass(cl, pa, visitor, args, visit_prot);
        true  = classHasLocalClasses(cl);
        ((elts_1,pa_2,args_2)) = traverseInnerClassElements(elts, pa, visitor, args_1, visit_prot);
      then
        ((
          (Absyn.ELEMENTITEM(Absyn.ELEMENT(f,r,io,n,Absyn.CLASSDEF(repl,cl),info,constr))::elts_1),pa_2,args_2));

   /* Visitor failed in elementspec, remove class */
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = io,name = n,specification = elt_spec,info = info,constrainClass = constr)) :: elts),pa,visitor,args,visit_prot)
      equation
        ((elts_1,pa_2,args_2)) = traverseInnerClassElements(elts, pa, visitor, args, visit_prot);
      then
        ((
          elts_1,pa_2,args_2));

    case ((elt :: elts),pa,visitor,args,visit_prot)
      equation
        ((elts_1,pa_1,args_1)) = traverseInnerClassElements(elts, pa, visitor, args, visit_prot);
      then
        (((elt :: elts_1),pa_1,args_1));
  end matchcontinue;
end traverseInnerClassElements;

protected function traverseInnerClassElementspec
"function: traverseInnerClassElementspec
   Helperfunction to traverseInnerClassElements"
  input Absyn.ElementSpec inElementSpec;
  input Option<Absyn.Path> inAbsynPathOption;
  input FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a inFuncTypeTplAbsynClassAbsynPathOptionTypeAToTplAbsynClassAbsynPathOptionTypeA;
  input Type_a inTypeA;
  input Boolean inBoolean "visit protected elts";
  output tuple<Absyn.ElementSpec, Option<Absyn.Path>, Type_a> outTplAbsynElementSpecAbsynPathOptionTypeA;
  partial function FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a
    input tuple<Absyn.Class, Option<Absyn.Path>, Type_a> inTplAbsynClassAbsynPathOptionTypeA;
    output tuple<Absyn.Class, Option<Absyn.Path>, Type_a> outTplAbsynClassAbsynPathOptionTypeA;
    replaceable type Type_a subtypeof Any;
  end FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a;
  replaceable type Type_a subtypeof Any;
algorithm
  outTplAbsynElementSpecAbsynPathOptionTypeA:=
  match (inElementSpec,inAbsynPathOption,inFuncTypeTplAbsynClassAbsynPathOptionTypeAToTplAbsynClassAbsynPathOptionTypeA,inTypeA,inBoolean)
    local
      Absyn.Class class_1,class_2,class_;
      Option<Absyn.Path> pa_1,pa_2,pa;
      Type_a args_1,args_2,args;
      Boolean repl,visit_prot;
      FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a visitor;
      Absyn.ElementSpec elt_spec;
    case (Absyn.CLASSDEF(replaceable_ = repl,class_ = class_),pa,visitor,args,visit_prot)
      equation
        ((class_1,pa_1,args_1)) = visitor((class_,pa,args));
        ((class_2,pa_2,args_2)) = traverseInnerClass(class_1, pa, visitor, args_1, visit_prot);
      then
        ((Absyn.CLASSDEF(repl,class_2),pa_2,args_2));
    case (elt_spec as Absyn.EXTENDS(path=_),pa,_,args,_) then ((elt_spec,pa,args));
    case (elt_spec as Absyn.IMPORT(import_=_),pa,_,args,_) then ((elt_spec,pa,args));
    case (elt_spec as Absyn.COMPONENTS(attributes=_),pa,_,args,_) then ((elt_spec,pa,args));
  end match;
end traverseInnerClassElementspec;

public function isPrimitive
"function: isPrimitive
  Thisfunction takes a component reference and a program.
  It returns the true if the refrenced type is a primitive
  type, otherwise it returns false."
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path path;
      Absyn.Class class_;
      Boolean res;
      Absyn.ComponentRef cr;
      Absyn.Program p;
    case (cr,p)
      equation
        path = Absyn.crefToPath(cr);
        class_ = getPathedClassInProgram(path, p);
        res = isPrimitiveClass(class_, p);
      then
        res;
    case (Absyn.CREF_IDENT(name = "Real"),_) then true;  /* Instead of elaborating and lookup these in env, we optimize a bit and just return true for these */
    case (Absyn.CREF_IDENT(name = "Integer"),_) then true;
    case (Absyn.CREF_IDENT(name = "String"),_) then true;
    case (Absyn.CREF_IDENT(name = "Boolean"),_) then true;
    case (_,_) then false;
  end matchcontinue;
end isPrimitive;

protected function deleteClass
"function: deleteClass
   This function takes a component reference and a program.
   It deletes the class specified by the component reference from the
   given program."
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output String outString;
  output Absyn.Program outProgram;
algorithm
  (outString,outProgram) := matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path cpath,parentcpath,parentparentcpath;
      Absyn.Class cdef,parentcdef,parentcdef_1;
      Absyn.Program newp,p;
      Absyn.ComponentRef class_;
      list<Absyn.Class> clist,clist_1;
      Absyn.Within w;
      Absyn.TimeStamp ts;

    case (class_,(p as Absyn.PROGRAM(classes = clist,within_ = w,globalBuildTimes=ts)))
      equation
        cpath = Absyn.crefToPath(class_) "Class inside another class, inside another class" ;
        parentcpath = Absyn.stripLast(cpath);
        parentparentcpath = Absyn.stripLast(parentcpath);
        cdef = getPathedClassInProgram(cpath, p);
        parentcdef = getPathedClassInProgram(parentcpath, p);
        parentcdef_1 = removeInnerClass(cdef, parentcdef);
        newp = updateProgram(Absyn.PROGRAM({parentcdef_1},Absyn.WITHIN(parentparentcpath),ts), p);
      then
        ("true",newp);
    case (class_,(p as Absyn.PROGRAM(classes = clist,within_ = w,globalBuildTimes=ts)))
      equation
        cpath = Absyn.crefToPath(class_) "Class inside other class" ;
        parentcpath = Absyn.stripLast(cpath);
        cdef = getPathedClassInProgram(cpath, p);
        parentcdef = getPathedClassInProgram(parentcpath, p);
        parentcdef_1 = removeInnerClass(cdef, parentcdef);
        newp = updateProgram(Absyn.PROGRAM({parentcdef_1},Absyn.TOP(),ts), p);
      then
        ("true",newp);
    case (class_,(p as Absyn.PROGRAM(classes = clist,within_ = w,globalBuildTimes=ts)))
      equation
        cpath = Absyn.crefToPath(class_) "Top level class" ;
        cdef = getPathedClassInProgram(cpath, p);
        clist_1 = deleteClassFromList(cdef, clist);
      then
        ("true",Absyn.PROGRAM(clist_1,w,ts));
    case (_,p)
      then ("false",p);
  end matchcontinue;
end deleteClass;

protected function deleteClassFromList
"function: deleteClassFromList
  Helper function to deleteClass."
  input Absyn.Class inClass;
  input list<Absyn.Class> inAbsynClassLst;
  output list<Absyn.Class> outAbsynClassLst;
algorithm
  outAbsynClassLst := matchcontinue (inClass,inAbsynClassLst)
    local
      String name1,name2;
      list<Absyn.Class> xs,res;
      Absyn.Class cdef,x;
    
    case (_,{}) then {};  /* Empty list */
    
    case (Absyn.CLASS(name = name1),(Absyn.CLASS(name = name2) :: xs))
      equation
        true = stringEq(name1, name2);
      then
        xs;
    
    case ((cdef as Absyn.CLASS(name = name1)),((x as Absyn.CLASS(name = name2)) :: xs))
      equation
        false = stringEq(name1, name2);
        res = deleteClassFromList(cdef, xs);
      then
        (x :: res);
    
    case ((cdef as Absyn.CLASS(name = name1)),(x :: xs))
      equation
        res = deleteClassFromList(cdef, xs);
      then
        (x :: res);
  end matchcontinue;
end deleteClassFromList;

public function setClassComment
"function: setClassComment
  author: PA
  Sets the class comment."
  input Absyn.Path path;
  input String inString;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
  output Boolean success;
algorithm
  (outProgram,success) := matchcontinue (path,inString,inProgram)
    local
      Absyn.Path p_class;
      Absyn.Within within_;
      Absyn.Class cdef,cdef_1;
      Absyn.Program newp,p;
      Absyn.ComponentRef class_;
      String str;
      Absyn.TimeStamp ts;

    case (p_class,str,p as Absyn.PROGRAM(globalBuildTimes=ts))
      equation
        within_ = buildWithin(p_class);
        cdef = getPathedClassInProgram(p_class, p);
        cdef_1 = setClassCommentInClass(cdef, str);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},within_,ts), p);
      then
        (newp,true);
    
    case (_,_,p) then (p,false);
  end matchcontinue;
end setClassComment;

protected function setClassCommentInClass
"function: setClassCommentInClass
  author: PA
  Helper function to setClassComment"
  input Absyn.Class inClass;
  input String inString;
  output Absyn.Class outClass;
algorithm
  outClass := match (inClass,inString)
    local
      Absyn.ClassDef cdef_1,cdef;
      String id,cmt;
      Boolean p,f,e;
      Absyn.Restriction r;
      Absyn.Info info;
    
    case (Absyn.CLASS(name = id,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,body = cdef,info = info),cmt)
      equation
        cdef_1 = setClassCommentInClassdef(cdef, cmt);
      then
        Absyn.CLASS(id,p,f,e,r,cdef_1,info);
  end match;
end setClassCommentInClass;

protected function setClassCommentInClassdef
"function: setClassCommentInClassdef
  author: PA
  Helper function to setClassCommentInClass"
  input Absyn.ClassDef inClassDef;
  input String inString;
  output Absyn.ClassDef outClassDef;
algorithm
  outClassDef:=
  matchcontinue (inClassDef,inString)
    local
      list<Absyn.ClassPart> p;
      String strcmt,id;
      Option<Absyn.Comment> cmt_1;
      Option<list<Absyn.Subscript>> ad;
      Absyn.ElementAttributes attr;
      list<Absyn.ElementArg> arg,args;
      Absyn.EnumDef edef;
      list<Absyn.Path> plst;
      Absyn.ClassDef c;
      Absyn.Path path;
      Option<Absyn.Comment> cmt;
      list<String> typeVars;
    case (Absyn.PARTS(typeVars=typeVars,classParts = p),"") then Absyn.PARTS(typeVars,p,NONE());
    case (Absyn.PARTS(typeVars=typeVars,classParts = p),strcmt) then Absyn.PARTS(typeVars,p,SOME(strcmt));
    case (Absyn.DERIVED(typeSpec = Absyn.TPATH(path,ad),attributes = attr,arguments = arg,comment = cmt),strcmt)
      equation
        cmt_1 = setClassCommentInCommentOpt(cmt, strcmt);
      then
        Absyn.DERIVED(Absyn.TPATH(path,ad),attr,arg,cmt_1);
    case (Absyn.ENUMERATION(enumLiterals = edef,comment = cmt),strcmt)
      equation
        cmt_1 = setClassCommentInCommentOpt(cmt, strcmt);
      then
        Absyn.ENUMERATION(edef,cmt_1);
    case (Absyn.OVERLOAD(functionNames = plst,comment = cmt),strcmt)
      equation
        cmt_1 = setClassCommentInCommentOpt(cmt, strcmt);
      then
        Absyn.OVERLOAD(plst,cmt_1);
    case (Absyn.CLASS_EXTENDS(baseClassName = id,modifications = args,parts = p),"") then Absyn.CLASS_EXTENDS(id,args,NONE(),p);
    case (Absyn.CLASS_EXTENDS(baseClassName = id,modifications = args,parts = p),strcmt) then Absyn.CLASS_EXTENDS(id,args,SOME(strcmt),p);
    case (c,_) then c;
  end matchcontinue;
end setClassCommentInClassdef;

protected function setClassCommentInCommentOpt
"function: setClassCommentInCommentOpt
  author: PA
  Sets the string comment in an Comment option."
  input Option<Absyn.Comment> inAbsynCommentOption;
  input String inString;
  output Option<Absyn.Comment> outAbsynCommentOption;
algorithm
  outAbsynCommentOption:=
  matchcontinue (inAbsynCommentOption,inString)
    local
      Option<Absyn.Annotation> ann;
      String cmt;
    case (SOME(Absyn.COMMENT(ann,_)),"") then SOME(Absyn.COMMENT(ann,NONE()));
    case (SOME(Absyn.COMMENT(ann,_)),cmt) then SOME(Absyn.COMMENT(ann,SOME(cmt)));
    case (NONE(),cmt) then SOME(Absyn.COMMENT(NONE(),SOME(cmt)));
  end matchcontinue;
end setClassCommentInCommentOpt;

protected function getClassInformation
"function: getClassInformation
  author: PA
  Returns all the possible class information.
  changed by adrpo 2006-02-24 (latest 2006-03-14) to return more info and in a different format:
  {\"restriction\",\"comment\",\"filename.mo\",{bool,bool,bool},{\"readonly|writable\",int,int,int,int}}
  if you like more named attributes, use getClassAttributes API which uses get_class_attributes function"
  input Absyn.ComponentRef cr;
  input Absyn.Program p;
  output String res_1;
protected
  Absyn.Path path;
  String name,file,strPartial,strFinal,strEncapsulated,res,cmt,str_readonly,str_sline,str_scol,str_eline,str_ecol;
  String dim_str;
  Boolean partialPrefix,finalPrefix,encapsulatedPrefix,isReadOnly;
  Absyn.Restriction restr;
  Absyn.ClassDef cdef;
  Integer sl,sc,el,ec;
algorithm
  path := Absyn.crefToPath(cr);
  Absyn.CLASS(name,partialPrefix,finalPrefix,encapsulatedPrefix,restr,cdef,Absyn.INFO(file,isReadOnly,sl,sc,el,ec,_)) := getPathedClassInProgram(path, p);
  strPartial := boolString(partialPrefix) "handling boolean attributes of the class" ;
  strFinal := boolString(finalPrefix);
  strEncapsulated := boolString(encapsulatedPrefix);
  res := Dump.unparseRestrictionStr(restr) "handling restriction" ;
  cmt := getClassComment(cdef) "handling class comment from the definition" ;
  str_readonly := selectString(isReadOnly, "readonly", "writable") "handling positional information" ;
  str_sline := intString(sl);
  str_scol := intString(sc);
  str_eline := intString(el);
  str_ecol := intString(ec);
  dim_str := getClassDimensions(cdef);
  res_1 := stringAppendList(
          {"{\"",res,"\",\"",cmt,"\",\"",file,"\",{",strPartial,",",
          strFinal,",",strEncapsulated,"},{\"",str_readonly,"\",",str_sline,",",
          str_scol,",",str_eline,",",str_ecol,"},",dim_str,"}"}) "composing the final returned string" ;
end getClassInformation;

protected function getClassDimensions
"return the dimensions of a class
 as vector of dimension sizes in a string.
 Note: A class can only have dimensions if it is a short class definition."
  input Absyn.ClassDef cdef;
  output String str;
algorithm
  str := matchcontinue(cdef)
  local Absyn.ArrayDim ad;
    case(Absyn.DERIVED(typeSpec=Absyn.TPATH(arrayDim=SOME(ad)))) equation
      str = "{"+& stringDelimitList(List.map(ad,Dump.printSubscriptStr),",")
      +& "}";
    then str;
    case(_) then "{}";
  end matchcontinue;
end getClassDimensions;

protected function getClassAttributes
"function: getClassAttributes
  author: Adrian Pop, 2006-02-24
  Returns all the possible class information in this format:
  { name=\"Ident\", partial=(true|false), final=(true|false),
    encapsulated=(true|false), restriction=\"PACKAGE|CLASS|..\",
    comment=\"comment\", file=\"filename.mo\",  readonly=\"(readonly|writable)\",
    startLine=number,  startColumn=number,
    endLine=number, endColumn=number }"
  input Absyn.ComponentRef cr;
  input Absyn.Program p;
  output String res_1;
protected
  Absyn.Path path;
  String name,file,strPartial,strFinal,strEncapsulated,res,cmt,str_readonly,str_sline,str_scol,str_eline,str_ecol;
  Boolean partialPrefix,finalPrefix,encapsulatedPrefix,isReadOnly;
  Absyn.Restriction restr;
  Absyn.ClassDef cdef;
  Integer sl,sc,el,ec;
algorithm
  path := Absyn.crefToPath(cr);
  Absyn.CLASS(name,partialPrefix,finalPrefix,encapsulatedPrefix,restr,cdef,Absyn.INFO(file,isReadOnly,sl,sc,el,ec,_)) := getPathedClassInProgram(path, p);
  strPartial := boolString(partialPrefix) "handling boolean attributes of the class" ;
  strFinal := boolString(finalPrefix);
  strEncapsulated := boolString(encapsulatedPrefix);
  res := Absyn.restrString(restr) "handling restriction" ;
  cmt := getClassComment(cdef) "handling class comment from the definition" ;
  str_readonly := selectString(isReadOnly, "readonly", "writable") "handling positional information" ;
  str_sline := intString(sl);
  str_scol := intString(sc);
  str_eline := intString(el);
  str_ecol := intString(ec);
  res_1 := stringAppendList(
          {"{ rec(name=\"",name,"\", partial=",strPartial,", final=",
          strFinal,", encapsulated=",strEncapsulated,", restriction=",res,", comment=\"",
          cmt,"\", file=\"",file,"\", readonly=\"",str_readonly,"\", startLine=",
          str_sline,", startColumn=",str_scol,", endLine=",str_eline,", endColumn=",
          str_ecol,") }"}) "composing the final returned string" ;
end getClassAttributes;

public function getClassComment
"function: getClassComment
  author: PA
  Returns the class comment of a Absyn.ClassDef"
  input Absyn.ClassDef cdef;
  output String res;
protected
  String s;
algorithm
  s := getClassComment2(cdef);
  res := System.unescapedString(s);
end getClassComment;

protected function getClassComment2
"function: getClassComment2
  Helper function to getClassComment."
  input Absyn.ClassDef inClassDef;
  output String outString;
algorithm
  outString:=
  matchcontinue (inClassDef)
    local
      String str,res;
      Option<Absyn.Comment> cmt;
    case (Absyn.PARTS(comment = SOME(str))) then str;
    case (Absyn.DERIVED(comment = cmt))
      equation
        res = getStringComment2(cmt);
      then
        res;
    case (Absyn.ENUMERATION(comment = cmt))
      equation
        res = getStringComment2(cmt);
      then
        res;
    case (Absyn.ENUMERATION(comment = cmt))
      equation
        res = getStringComment2(cmt);
      then
        res;
    case (Absyn.OVERLOAD(comment = cmt))
      equation
        res = getStringComment2(cmt);
      then
        res;
    case (Absyn.CLASS_EXTENDS(comment = SOME(str))) then str;
    case (_) then "";
  end matchcontinue;
end getClassComment2;

public function getClassRestriction
"function: getClassRestriction
  author: PA
  Returns the class restriction of a class as a string."
  input Absyn.ComponentRef cr;
  input Absyn.Program p;
  output String res_1;
protected
  Absyn.Path path;
  Absyn.Restriction restr;
  String res;
algorithm
  path := Absyn.crefToPath(cr);
  Absyn.CLASS(_,_,_,_,restr,_,_) := getPathedClassInProgram(path, p);
  res := Dump.unparseRestrictionStr(restr);
  res_1 := stringAppendList({"\"",res,"\""});
end getClassRestriction;

public function isType
"function: isType
  This function takes a component reference and a program.
  It returns true if the refrenced class has the restriction
  \"type\", otherwise it returns false."
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path path;
      Absyn.ComponentRef cr;
      Absyn.Program p;
    case (cr,p)
      equation
        path = Absyn.crefToPath(cr);
        Absyn.CLASS(_,_,_,_,Absyn.R_TYPE(),_,_) = getPathedClassInProgram(path, p);
      then
        true;
    case (cr,p) then false;
  end matchcontinue;
end isType;

protected function isConnector
"function: isConnector
   This function takes a component reference and a program.
   It returns true if the refrenced class has the restriction
   \"connector\", otherwise it returns false."
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path path;
      Absyn.ComponentRef cr;
      Absyn.Program p;
    case (cr,p)
      equation
        path = Absyn.crefToPath(cr);
        Absyn.CLASS(_,_,_,_,Absyn.R_CONNECTOR(),_,_) = getPathedClassInProgram(path, p);
      then
        true;
    case (cr,p)
      equation
        path = Absyn.crefToPath(cr);
        Absyn.CLASS(_,_,_,_,Absyn.R_EXP_CONNECTOR(),_,_) = getPathedClassInProgram(path, p);
      then
        true;
    case (cr,p) then false;
  end matchcontinue;
end isConnector;

public function isModel
"function: isModel
   This function takes a component reference and a program.
   It returns true if the refrenced class has the restriction
   \"model\", otherwise it returns false."
  input Absyn.Path path;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (path,inProgram)
    local
      Absyn.Program p;
    case (path,p)
      equation
        Absyn.CLASS(_,_,_,_,Absyn.R_MODEL(),_,_) = getPathedClassInProgram(path, p);
      then true;
    else false;
  end matchcontinue;
end isModel;

protected function isRecord
"function: isRecord
   This function takes a component reference and a program.
   It returns true if the refrenced class has the restriction
   \"record\", otherwise it returns false."
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path path;
      Absyn.ComponentRef cr;
      Absyn.Program p;
    case (cr,p)
      equation
        path = Absyn.crefToPath(cr);
        Absyn.CLASS(_,_,_,_,Absyn.R_RECORD(),_,_) = getPathedClassInProgram(path, p);
      then
        true;
    case (cr,p) then false;
  end matchcontinue;
end isRecord;

protected function isBlock
"function: isBlock
   This function takes a component reference and a program.
   It returns true if the refrenced class has the restriction
   \"block\", otherwise it returns false."
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path path;
      Absyn.ComponentRef cr;
      Absyn.Program p;
    case (cr,p)
      equation
        path = Absyn.crefToPath(cr);
        Absyn.CLASS(_,_,_,_,Absyn.R_BLOCK(),_,_) = getPathedClassInProgram(path, p);
      then
        true;
    case (cr,p) then false;
  end matchcontinue;
end isBlock;

public function isFunction
"function: isFunction
   This function takes a component reference and a program.
   It returns true if the refrenced class has the restriction
   \"function\", otherwise it returns false."
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path path;
      Absyn.ComponentRef cr;
      Absyn.Program p;
    case (cr,p)
      equation
        path = Absyn.crefToPath(cr);
        Absyn.CLASS(_,_,_,_,Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION()),_,_) = getPathedClassInProgram(path, p);
      then
        true;
    case (cr,p) then false;
  end matchcontinue;
end isFunction;

public function isPackage
"function: isPackage
   This function takes a component reference and a program.
   It returns true if the refrenced class has the restriction
   \"package\", otherwise it returns false."
  input Absyn.Path path;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (path,inProgram)
    local
      Absyn.ComponentRef cr;
      Absyn.Program p;
    case (path,p)
      equation
        Absyn.CLASS(_,_,_,_,Absyn.R_PACKAGE(),_,_) = getPathedClassInProgram(path, p);
      then
        true;
    else false;
  end matchcontinue;
end isPackage;

protected function isClass
"function: isClass
   This function takes a component reference and a program.
   It returns true if the refrenced class has the restriction
   \"class\", otherwise it returns false."
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path path;
      Absyn.ComponentRef cr;
      Absyn.Program p;
    case (cr,p)
      equation
        path = Absyn.crefToPath(cr);
        Absyn.CLASS(_,_,_,_,Absyn.R_CLASS(),_,_) = getPathedClassInProgram(path, p);
      then
        true;
    case (cr,p) then false;
  end matchcontinue;
end isClass;

public function isPartial
"function: isClass
   This function takes a component reference and a program.
   It returns true if the refrenced class has the restriction
   \"class\", otherwise it returns false."
  input Absyn.Path p;
  input Absyn.Program prog;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (p,prog)
    case (p,prog)
      equation
        Absyn.CLASS(partialPrefix=true) = getPathedClassInProgram(p, prog);
      then true;
    else false;
  end matchcontinue;
end isPartial;

protected function isParameter
"function: isParameter
   This function takes a class and a component reference and a program
   and returns true if the component referenced is a parameter."
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.Program p;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inComponentRef1,inComponentRef2,p)
    local
      Absyn.Path path;
      String i;
      Boolean f,e;
      Absyn.Restriction r;
      list<Absyn.ClassPart> parts;
      list<Absyn.ElementItem> publst;
      Absyn.ComponentRef cr,classname;
   /* a class with parts */
    case (cr,classname,p)
      equation
        path = Absyn.crefToPath(classname);
        Absyn.CLASS(i,_,f,e,r,Absyn.PARTS(classParts=parts),_) = getPathedClassInProgram(path, p);
        publst = getPublicList(parts);
        Absyn.COMPONENTS(Absyn.ATTR(_,_,_,Absyn.PARAM(),_,_),_,_) = getComponentsContainsName(cr, publst);
      then
        true;
    /* an extended class: model extends M end M; */
    case (cr,classname,p)
      equation
        path = Absyn.crefToPath(classname);
        Absyn.CLASS(i,_,f,e,r,Absyn.CLASS_EXTENDS(_,_,_,parts),_) = getPathedClassInProgram(path, p);
        publst = getPublicList(parts);
        Absyn.COMPONENTS(Absyn.ATTR(_,_,_,Absyn.PARAM(),_,_),_,_) = getComponentsContainsName(cr, publst);
      then
        true;
    /* otherwise */
    case (_,_,_) then false;
  end matchcontinue;
end isParameter;

protected function isProtected
"function: isProtected
   This function takes a class and a component reference and a program
   and returns true if the component referenced is in a protected section."
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.Program p;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inComponentRef1,inComponentRef2,p)
    local
      Absyn.Path path;
      list<Absyn.ClassPart> parts;
      list<Absyn.ElementItem> publst,protlst;
      Absyn.ComponentRef cr,classname;
    /* a class with parts */
    case (cr,classname,p)
      equation
        path = Absyn.crefToPath(classname);
        Absyn.CLASS(body = Absyn.PARTS(classParts=parts)) = getPathedClassInProgram(path, p);
        publst = getPublicList(parts);
        _ = getComponentsContainsName(cr, publst);
      then
        false;
    case (cr,classname,p)
      equation
        path = Absyn.crefToPath(classname);
        Absyn.CLASS(body = Absyn.PARTS(classParts=parts)) = getPathedClassInProgram(path, p);
        protlst = getProtectedList(parts);
        _ = getComponentsContainsName(cr, protlst);
      then
        true;
    /* an extended class with parts: model extends M end M; */
    case (cr,classname,p)
      equation
        path = Absyn.crefToPath(classname);
        Absyn.CLASS(body = Absyn.CLASS_EXTENDS(_,_,_,parts)) = getPathedClassInProgram(path, p);
        publst = getPublicList(parts);
        _ = getComponentsContainsName(cr, publst);
      then
        false;
    case (cr,classname,p)
      equation
        path = Absyn.crefToPath(classname);
        Absyn.CLASS(body = Absyn.CLASS_EXTENDS(_,_,_,parts)) = getPathedClassInProgram(path, p);
        protlst = getProtectedList(parts);
        _ = getComponentsContainsName(cr, protlst);
      then
        true;
    /* otherwise return false */
    case (_,_,_) then false;
  end matchcontinue;
end isProtected;

protected function isConstant
"function: isConstant
   This function takes a class and a component reference and a program
   and returns true if the component referenced is a constant."
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.Program p;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inComponentRef1,inComponentRef2,p)
    local
      Absyn.Path path;
      list<Absyn.ClassPart> parts;
      list<Absyn.ElementItem> publst;
      Absyn.ComponentRef cr,classname;
    /* a class with parts */
    case (cr,classname,p)
      equation
        path = Absyn.crefToPath(classname);
        Absyn.CLASS(body = Absyn.PARTS(classParts=parts)) = getPathedClassInProgram(path, p);
        publst = getPublicList(parts);
        Absyn.COMPONENTS(Absyn.ATTR(_,_,_,Absyn.CONST(),_,_),_,_) = getComponentsContainsName(cr, publst);
      then
        true;
    /* an extended class with parts: model extends M end M; */
    case (cr,classname,p)
      equation
        path = Absyn.crefToPath(classname);
        Absyn.CLASS(body = Absyn.CLASS_EXTENDS(_,_,_,parts)) = getPathedClassInProgram(path, p);
        publst = getPublicList(parts);
        Absyn.COMPONENTS(Absyn.ATTR(_,_,_,Absyn.CONST(),_,_),_,_) = getComponentsContainsName(cr, publst);
      then
        true;
    /* otherwise return false */
    case (_,_,_) then false;
  end matchcontinue;
end isConstant;

protected function isEnumeration
"function: isEnumeration
   It returns true if the refrenced class has the restriction
   \"type\" and is an \"Enumeration\", otherwise it returns false."
  input Absyn.Class inClass;
  output Boolean outBoolean;
algorithm
  outBoolean:= match (inClass)
    local
    case (Absyn.CLASS(restriction = Absyn.R_TYPE(), body = Absyn.ENUMERATION(_,_)))
      then
        true;
    case (_) then false;
  end match;
end isEnumeration;

protected function isReplaceable
"function: isReplaceable
  Returns true if the class referenced by inString within inComponentRef1 is replaceable.
  Only look to Element Items of inComponentRef1 for components use getComponents."
  input Absyn.ComponentRef inComponentRef1;
  input String inString;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inComponentRef1,inString,inProgram)
    local
      Absyn.Path modelpath;
      Boolean res, public_res, protected_res;
      String element_name,str;
      list<Absyn.ClassPart> parts;
      list<Absyn.ElementItem> public_elementitem_list, protected_elementitem_list;
      Absyn.ComponentRef model_;
      Absyn.Program p;
    /* a class with parts - public elements */
    case (model_,str,p)
      equation
        modelpath = Absyn.crefToPath(model_);
        Absyn.CLASS(_,_,_,_,_,Absyn.PARTS(classParts=parts),_) = getPathedClassInProgram(modelpath, p);
        public_elementitem_list = getPublicList(parts);
        public_res = isReplaceableInElements(public_elementitem_list, str);
        res = Util.if_(public_res, true, false);
      then
        res;
    /* a class with parts - protected elements */
    case (model_,str,p)
      equation
        modelpath = Absyn.crefToPath(model_);
        Absyn.CLASS(_,_,_,_,_,Absyn.PARTS(classParts=parts),_) = getPathedClassInProgram(modelpath, p);
        protected_elementitem_list = getProtectedList(parts);
        protected_res = isReplaceableInElements(protected_elementitem_list, str);
        res = Util.if_(protected_res, true, false);
      then
        res;
    /* an extended class with parts: model extends M end M; public elements */
    case (model_,str,p)
      equation
        modelpath = Absyn.crefToPath(model_);
        Absyn.CLASS(_,_,_,_,_,Absyn.CLASS_EXTENDS(_,_,_,parts),_) = getPathedClassInProgram(modelpath, p);
        public_elementitem_list = getPublicList(parts);
        public_res = isReplaceableInElements(public_elementitem_list, str);
        res = Util.if_(public_res, true, false);
      then
        res;
    /* an extended class with parts: model extends M end M; protected elements */
    case (model_,str,p)
      equation
        modelpath = Absyn.crefToPath(model_);
        Absyn.CLASS(_,_,_,_,_,Absyn.CLASS_EXTENDS(_,_,_,parts),_) = getPathedClassInProgram(modelpath, p);
        protected_elementitem_list = getProtectedList(parts);
        protected_res = isReplaceableInElements(protected_elementitem_list, str);
        res = Util.if_(protected_res, true, false);
      then
        res;
    case (_,_,_) then false;
  end matchcontinue;
end isReplaceable;

protected function isReplaceableInElements
"function: isReplaceableInElements
  Helper function to isReplaceable."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input String inString;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inAbsynElementItemLst, inString)
    local
      String str, id;
      Boolean res;
      Absyn.ElementItem current;
      list<Absyn.ElementItem> rest;
      Option<Absyn.RedeclareKeywords> r;
    case ({}, _) then false;
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(redeclareKeywords = r,specification = Absyn.CLASSDEF(class_ = Absyn.CLASS(name = id)))) :: rest), str) /* ok, first see if is a classdef if is not a classdef, just follow the normal stuff */
      equation
        true = stringEq(id,str);
        res = keywordReplaceable(r);
      then
        res;
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(redeclareKeywords = r,name = id)) :: rest), str)
      equation
        true = stringEq(id,str);
        res = keywordReplaceable(r);
      then
        res;
    case ((_ :: rest), str)
      equation
        res = isReplaceableInElements(rest, str);
      then
        res;
  end matchcontinue;
end isReplaceableInElements;

protected function getEnumLiterals
"function: getEnumLiterals
  Returns the enum literals as a list of string."
  input Absyn.Class inClass;
  output String outString;
algorithm
  outString:= match (inClass)
    local
      list<Absyn.EnumLiteral> literals;
      String str;
      list<String> enumList;
    case (Absyn.CLASS(restriction = Absyn.R_TYPE(), body = Absyn.ENUMERATION(enumLiterals = Absyn.ENUMLITERALS(enumLiterals = literals))))
      equation
        enumList = List.map(literals, getEnumerationLiterals);
        str = stringDelimitList(enumList, ",");
        str = stringAppendList({"{",str,"}"});
      then
        str;
    case (_) then "{}";
  end match;
end getEnumLiterals;

protected function getElementitemContainsName
"function: getElementitemContainsName
  Returns the element that has the component name given as argument."
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output Absyn.ElementItem outElementItem;
algorithm
  outElementItem:=
  matchcontinue (inComponentRef,inAbsynElementItemLst)
    local
      Absyn.ComponentRef cr;
      Absyn.ElementItem elt,res;
      list<Absyn.ElementItem> rest;
    case (cr,(elt :: _))
      equation
        _ = getComponentsContainsName(cr, {elt});
      then
        elt;
    case (cr,(_ :: rest))
      equation
        res = getElementitemContainsName(cr, rest);
      then
        res;
  end matchcontinue;
end getElementitemContainsName;

protected function getComponentsContainsName
"function: getComponentsContainsName
  Return the ElementSpec containing the name
  given as argument from a list of ElementItems"
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output Absyn.ElementSpec outElementSpec;
algorithm
  outElementSpec:=
  matchcontinue (inComponentRef,inAbsynElementItemLst)
    local
      Absyn.ComponentRef cr;
      Absyn.ElementSpec res;
      list<Absyn.ComponentItem> ellst;
      list<Absyn.ElementItem> xs;
      Absyn.ElementItem x;
    case (cr,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = (res as Absyn.COMPONENTS(components = ellst)))) :: xs))
      equation
        _ = getCompitemNamed(cr, ellst);
      then
        res;
    case (cr,(x :: xs))
      equation
        res = getComponentsContainsName(cr, xs);
      then
        res;
  end matchcontinue;
end getComponentsContainsName;

protected function getElementContainsName
"function: getElementContainsName
  Return the Element containing the component name
  given as argument from a list of ElementItems."
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output Absyn.Element outElement;
algorithm
  outElement:=
  matchcontinue (inComponentRef,inAbsynElementItemLst)
    local
      Absyn.ComponentRef cr;
      Absyn.Element res;
      list<Absyn.ComponentItem> ellst;
      list<Absyn.ElementItem> xs;
      Absyn.ElementItem x;
    case (cr,(Absyn.ELEMENTITEM(element = (res as Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = ellst)))) :: xs))
      equation
        _ = getCompitemNamed(cr, ellst);
      then
        res;
    case (cr,(x :: xs))
      equation
        res = getElementContainsName(cr, xs);
      then
        res;
  end matchcontinue;
end getElementContainsName;

protected function getCompitemNamed
"function: getCompitemNamed
  Helper function to getComponentsContainsName."
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  output Absyn.ComponentItem outComponentItem;
algorithm
  outComponentItem := matchcontinue (inComponentRef,inAbsynComponentItemLst)
    local
      String id1,id2;
      Absyn.ComponentItem x,res;
      list<Absyn.ComponentItem> xs;
      Absyn.ComponentRef cr;
    
    case (Absyn.CREF_IDENT(name = id1),((x as Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id2))) :: xs))
      equation
        true = stringEq(id1, id2);
      then
        x;
    
    case (cr,(x :: xs))
      equation
        res = getCompitemNamed(cr, xs);
      then
        res;
  end matchcontinue;
end getCompitemNamed;

public function existClass
"function: existClass
   This function takes a component reference and a program.
   It returns true if the refrenced class exists in the
   symbol table, otherwise it returns false."
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path path;
      Absyn.ComponentRef cr;
      Absyn.Program p;
    
    case (cr,p)
      equation
        path = Absyn.crefToPath(cr);
        _ = getPathedClassInProgram(path, p);
      then
        true;
    
    case (cr,p) then false;
  end matchcontinue;
end existClass;

public function isPrimitiveClass
"function: isPrimitiveClass
  Return true of a class is a primitive class, i.e. one of the builtin
  classes or the \'type\' restricted class. It also checks derived classes
  using short class definition."
  input Absyn.Class inClass;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  match (inClass,inProgram)
    local
      Absyn.Path inmodel,path;
      Absyn.Class cdef;
      Boolean res;
      String cname;
      Absyn.Program p;
    case (Absyn.CLASS(restriction = Absyn.R_PREDEFINED_INTEGER()),_) then true;
    case (Absyn.CLASS(restriction = Absyn.R_PREDEFINED_REAL()),_) then true;
    case (Absyn.CLASS(restriction = Absyn.R_PREDEFINED_STRING()),_) then true;
    case (Absyn.CLASS(restriction = Absyn.R_PREDEFINED_BOOLEAN()),_) then true;
    case (Absyn.CLASS(restriction = Absyn.R_TYPE()),_) then true;
    case (Absyn.CLASS(name = cname,restriction = Absyn.R_CLASS(),body = Absyn.DERIVED(typeSpec = Absyn.TPATH(path,_))),p)
      equation
        inmodel = Absyn.crefToPath(Absyn.CREF_IDENT(cname,{}));
        (cdef,_) = lookupClassdef(path, inmodel, p);
        res = isPrimitiveClass(cdef, p);
      then
        res;
  end match;
end isPrimitiveClass;

public function removeCompiledFunctions
"function: removeCompiledFunctions
   A Compiled function should be removed if its definition is updated."
  input Absyn.Program inProgram;
  input list<CompiledCFunction> inTplAbsynPathTypesTypeLst;
  output list<CompiledCFunction> outTplAbsynPathTypesTypeLst;
algorithm
  outTplAbsynPathTypesTypeLst := matchcontinue (inProgram,inTplAbsynPathTypesTypeLst)
    local
      list<CompiledCFunction> cfs_1,cfs;
      String id;
    case (Absyn.PROGRAM(classes = {Absyn.CLASS(name = id,restriction = Absyn.R_FUNCTION(_))}),cfs)
      equation
        cfs_1 = removeCf(cfs, Absyn.IDENT(id));
      then
        cfs_1;
    case (_,cfs) then cfs;
  end matchcontinue;
end removeCompiledFunctions;

protected function removeAnySubFunctions
"function: removeAnySubFunctions
  Will remove any functions contain within the class from cflist."
  input Absyn.Path inPath;
  input Absyn.Class inClass;
  input list<CompiledCFunction> inCompiledFunctions;
  output list<CompiledCFunction> outCompiledFunctions;
algorithm
  outCompiledFunctions:=
  matchcontinue (inPath,inClass,inCompiledFunctions)
    local
      list<CompiledCFunction> cf, newCF;
      Absyn.Path p;
      list<Absyn.ClassPart> parts;
    case (p, Absyn.CLASS(restriction = Absyn.R_FUNCTION(_)), cf)
      equation
        newCF = removeCf(cf, p);
      then
        newCF;
    /* a classs with parts */
    case (p, Absyn.CLASS(body = Absyn.PARTS(classParts = parts)), cf)
      equation
        newCF = removeAnyPartsFunctions(p, parts, cf);
      then
        newCF;
    /* an extended class with parts: model extends M end M; */
    case (p, Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)), cf)
      equation
        newCF = removeAnyPartsFunctions(p, parts, cf);
      then
        newCF;
    case (_, _, cf) then cf;
  end matchcontinue;
end removeAnySubFunctions;

protected function removeAnyPartsFunctions
"function: removeAnyPartsFunctions
  Helper function to removeAnyBodyFunctions."
  input Absyn.Path inPath;
  input list<Absyn.ClassPart> inParts;
  input list<CompiledCFunction> inCompiledFunctions;
  output list<CompiledCFunction> outCompiledFunctions;
algorithm
 outCompiledFunctions:=
 matchcontinue (inPath,inParts,inCompiledFunctions)
   local
     list<Absyn.ClassPart> rest;
     list<Absyn.ElementItem> elts;
     list<CompiledCFunction> cf, newCF, newCF_1;
     Absyn.Path p,p1;
     String id;
   case (_,{},cf) then cf;
   case (p, (Absyn.PUBLIC(contents = elts) :: rest), cf)
     equation
       newCF = removeAnyPartsFunctions(p, rest, cf);
       newCF_1 = removeAnyEltsFunctions(p, elts, newCF);
     then
       newCF_1;
   case (p, (Absyn.PROTECTED(contents = elts) :: rest), cf)
     equation
       newCF = removeAnyPartsFunctions(p, rest, cf);
       newCF_1 = removeAnyEltsFunctions(p, elts, newCF);
     then
       newCF_1;
   case (p,Absyn.EXTERNAL(externalDecl = Absyn.EXTERNALDECL(funcName = SOME(id))) :: rest, cf)
     equation
       p1 = Absyn.joinPaths(p, Absyn.IDENT(id));
       newCF = removeCf(cf, p1);
       newCF_1 = removeAnyPartsFunctions(p, rest, newCF);
     then
       newCF_1;
   case (p, (_ :: rest), cf)
     equation
        newCF = removeAnyPartsFunctions(p, rest, cf);
     then
       newCF;
 end matchcontinue;
end removeAnyPartsFunctions;

function removeAnyEltsFunctions
"function: removeAnyEltsFunctions
  Helper function to removeAnyPartsFunctions."
  input Absyn.Path inPath;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input list<CompiledCFunction> inCompiledFunctions;
  output list<CompiledCFunction> outCompiledFunctions;
algorithm
  outCompiledFunctions:=
  matchcontinue (inPath, inAbsynElementItemLst, inCompiledFunctions)
    local
      list<CompiledCFunction> cf, newCF, newCF_1;
      Absyn.Class class_;
      list<Absyn.ElementItem> rest;
      Absyn.Path p,p1;
      Absyn.Ident id;
    case (_,{},cf) then cf;
    case (p,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = (class_ as Absyn.CLASS(name = id))),constrainClass = NONE())) :: rest), cf)
      equation
        p1 = Absyn.joinPaths(p, Absyn.IDENT(id));
        newCF = removeAnySubFunctions(p1, class_, cf);
        newCF_1 = removeAnyEltsFunctions(p, rest, newCF);
      then
        newCF_1;
    case (p,(_ :: rest),cf)
      equation
        newCF = removeAnyEltsFunctions(p, rest, cf);
      then
        newCF;
  end matchcontinue;
end removeAnyEltsFunctions;

public function removeCfAndDependencies
"function: removeCf
  Helper function to removeCompiledFunctions and removeAnySubFunctions."
  input list<CompiledCFunction> inCompiledFunctions;
  input list<Absyn.Path> functionAndDependencies "the main function path plus all dependencies!";
  output list<CompiledCFunction> outCompiledFunctions;
algorithm
  outCompiledFunctions := matchcontinue (inCompiledFunctions, functionAndDependencies)
    local
      list<CompiledCFunction> cf;
      Absyn.Path functionName;
      list<Absyn.Path> functionNames;
      DAE.Type t;
      Integer funcHandle;
      String tmp;
      CompiledCFunction item;
    
    case ({}, _) then {};
      
    case (cf, {}) then cf;
    
    case (cf, functionName::functionNames)
      equation
        cf = removeCf(cf, functionName);
        cf = removeCfAndDependencies(cf, functionNames);
      then
        cf;
    
  end matchcontinue;
end removeCfAndDependencies;

public function removeCf
"function: removeCf
  Helper function to removeCompiledFunctions and removeAnySubFunctions."
  input list<CompiledCFunction> inCompiledFunctions;
  input Absyn.Path functionName "the main function path";
  output list<CompiledCFunction> outCompiledFunctions;
algorithm
  outCompiledFunctions := matchcontinue (inCompiledFunctions, functionName)
    local
      list<CompiledCFunction> res,rest;
      Absyn.Path functionInCf;
      DAE.Type t;
      Integer funcHandle;
      String tmp;
      CompiledCFunction item;
    
    case ({}, _) then {};
    
    case (CFunction(functionInCf,t,funcHandle,_,_) :: rest, _)
      equation
        true = Absyn.pathEqual(functionInCf, functionName);
        tmp = Absyn.pathStringReplaceDot(functionName, "_");
        System.freeFunction(funcHandle, Flags.isSet(Flags.DYN_LOAD));
        res = removeCf(rest, functionName);
      then
        res;
    
    case (item :: rest, _)
      equation
        res = removeCf(rest, functionName);
      then
        item :: res;
  end matchcontinue;
end removeCf;

public function updateProgram
"function: updateProgram
   This function takes an old program (second argument), i.e. the old
   symboltable, and a new program (first argument), i.e. a new set of
   classes and updates the old program with the definitions in the new one.
   It also takes in the current symboltable and returns a new one with any
   replaced functions cache cleared."
  input Absyn.Program inProgram1;
  input Absyn.Program inProgram2;
  output Absyn.Program outProgram;
algorithm
  outProgram := matchcontinue (inProgram1,inProgram2)
    local
      Absyn.Program prg,newp,p2,newp_1,a,b, p1;
      Absyn.Class c1;
      String name;
      Absyn.Path path;
      list<Absyn.Class> c2,c3;
      Absyn.Within w,w2;
      Absyn.TimeStamp ts1,ts2;

    case (Absyn.PROGRAM(classes = {}),prg)
      then prg;

    case (p1 as Absyn.PROGRAM(classes = ((c1 as Absyn.CLASS(name = name)) :: c2),within_ = (w as Absyn.TOP()),globalBuildTimes=ts1),
         (p2 as Absyn.PROGRAM(classes = c3,within_ = w2,globalBuildTimes=ts2)))
      equation
        //debug_print("name", name);
        //Dump.dump(p1);
        false = classInProgram(name, p2);
        newp = updateProgram(Absyn.PROGRAM(c2,w,ts1), Absyn.PROGRAM((c1 :: c3),w2,ts2));
      then
        newp;

    case (p1 as Absyn.PROGRAM(classes = ((c1 as Absyn.CLASS(name = name)) :: c2),within_ = (w as Absyn.TOP()),globalBuildTimes=ts1),
          p2)
      equation
        //debug_print("name", name);
        //Dump.dump(p1);
        true = classInProgram(name, p2);
        newp = updateProgram(Absyn.PROGRAM(c2,w,ts1), p2);
        newp_1 = replaceClassInProgram(c1, newp);
      then
        newp_1;

    case (Absyn.PROGRAM(classes = (c1 :: c2),within_ = (w as Absyn.WITHIN(path = path)),globalBuildTimes=ts1),
          p2)
      equation
        newp = insertClassInProgram(c1, w, p2);
        newp_1 = updateProgram(Absyn.PROGRAM(c2,w,ts1), newp);
      then
        newp_1;

  end matchcontinue;
end updateProgram;

public function addScope
"function: addScope
   This function adds the scope of the scope variable to
   the program, so it can be inserted at the correct place.
   It also adds the scope to BEGIN_DEFINITION, COMP_DEFINITION
   and IMPORT_DEFINITION so an empty class definition can be
   inserted at the correct place."
  input Absyn.Program inProgram;
  input list<Variable> inVariableLst;
  output Absyn.Program outProgram;
algorithm
  outProgram:=
  matchcontinue (inProgram,inVariableLst)
    local
      Absyn.Path path,newpath,path2;
      list<Absyn.Class> cls;
      list<Variable> vars;
      Absyn.Within w;
      Absyn.TimeStamp ts;
      Absyn.Program p;

    case (Absyn.PROGRAM(classes = cls,within_ = Absyn.TOP(),globalBuildTimes=ts),vars)
      equation
        Values.CODE(Absyn.C_TYPENAME(path)) = getVariableValue("scope", vars);
      then
        Absyn.PROGRAM(cls,Absyn.WITHIN(path),ts);

    case (Absyn.PROGRAM(classes = cls,within_ = w,globalBuildTimes=ts),vars)
      equation
        failure(_ = getVariableValue("scope", vars));
      then
        Absyn.PROGRAM(cls,w,ts);
    case (Absyn.PROGRAM(classes = cls,within_ = Absyn.WITHIN(path = path2),globalBuildTimes=ts),vars)
      equation
        Values.CODE(Absyn.C_TYPENAME(path)) = getVariableValue("scope", vars) "This should probably be forbidden." ;
        newpath = Absyn.joinPaths(path, path2);
      then
        Absyn.PROGRAM(cls,Absyn.WITHIN(newpath),ts);
    case (p,_) then p;
  end matchcontinue;
end addScope;

public function updateScope
"function: updateScope
   This function takes a PROGRAM and updates the variable scope to according
   to the value of program:
   1. BEGIN_DEFINITION ident appends ident to scope
   2.END_DEFINITION ident removes ident from scope"
  input Absyn.Program inProgram;
  input list<Variable> inVariableLst;
  output list<Variable> outVariableLst;
algorithm
  outVariableLst := match (inProgram,inVariableLst)
    local
      list<Variable> vars;

    case (_,vars) then vars;
  end match;
end updateScope;

protected function removeVarFromVarlist
"function: removeVarFromVarlist
  Helper function to updateScope."
  input Absyn.Ident inIdent;
  input list<Variable> inVariableLst;
  output list<Variable> outVariableLst;
algorithm
  outVariableLst := matchcontinue (inIdent,inVariableLst)
    local
      String id1,id2;
      list<Variable> rest,rest_1;
      Variable v;
    
    case (_,{}) then {};
    
    case (id1,(IVAR(varIdent = id2) :: rest))
      equation
        true = stringEq(id1, id2);
      then
        rest;
    
    case (id1,((v as IVAR(varIdent = id2)) :: rest))
      equation
        false = stringEq(id1, id2);
        rest_1 = removeVarFromVarlist(id1, rest);
      then
        (v :: rest_1);
  end matchcontinue;
end removeVarFromVarlist;

protected function getVariableValue
"function: getVariableValue
  Return the value of an interactive variable
  from a list of Variable."
  input Absyn.Ident inIdent;
  input list<Variable> inVariableLst;
  output Values.Value outValue;
algorithm
  outValue := matchcontinue (inIdent,inVariableLst)
    local
      String id1,id2;
      Values.Value v;
      list<Variable> rest;
    
    case (id1,(IVAR(varIdent = id2,value = v) :: _))
      equation
        true = stringEq(id1, id2);
      then
        v;
    
    case (id1,(IVAR(varIdent = id2,value = v) :: rest))
      equation
        false = stringEq(id1, id2);
        v = getVariableValue(id1, rest);
      then
        v;
  end matchcontinue;
end getVariableValue;

protected function getVariableValueLst
"function: getVariableValue
  Return the value of an interactive variable
  from a list of Variable."
  input list<String> ids;
  input list<Variable> vars;
  output Values.Value val;
algorithm
  val := matchcontinue (ids,vars)
    local
      Integer ix;
      String id1,id2,id3;
      Values.Value v;
      list<Variable> rest;
      list<String> comp,srest;
      list<Values.Value> vals;
      DAE.Type t;
    
    case (id1::_, (IVAR(varIdent = id2) :: rest))
      equation
        false = stringEq(id1, id2);
        v = getVariableValueLst(ids, rest);
      then
        v;

    case (id1::id2::srest, (IVAR(varIdent = id3,value = Values.RECORD(orderd = vals, comp = comp),type_ = t) :: _))
      equation
        true = stringEq(id1, id3);
        ix = List.positionOnTrue(id2, comp, stringEq);
        v = listNth(vals, ix);
        v = getVariableValueLst(id2::srest, {IVAR(id2,v,DAE.T_UNKNOWN_DEFAULT)});
      then
        v;
    
    case ({id1}, (IVAR(varIdent = id2,value = v,type_ = t) :: _))
      equation
        true = stringEq(id1, id2);
      then
        v;
    
  end matchcontinue;
end getVariableValueLst;

protected function lookupClassdef
"function: lookupClassdef
   This function takes a Path of a class to lookup and a Path
   as a starting point for the lookup rules and a Program.
   It returns the Class definition and the complete Path to the class."
  input Absyn.Path inPath1;
  input Absyn.Path inPath2;
  input Absyn.Program inProgram3;
  output Absyn.Class outClass;
  output Absyn.Path outPath;
algorithm
  (outClass,outPath) := matchcontinue (inPath1,inPath2,inProgram3)
    local
      Absyn.Class inmodeldef,cdef;
      Absyn.Path newpath,path,inmodel,innewpath,respath;
      Absyn.Program p;
      String s1,s2;
      Absyn.TimeStamp ts;
    
    case (path,inmodel,p as Absyn.PROGRAM(globalBuildTimes=ts))
      equation
        //Debug.fprintln(Flags.INTER, "Interactive.lookupClassdef 1 Looking for: " +& Absyn.pathString(path) +& " in: " +& Absyn.pathString(inmodel));
        // remove self reference, otherwise we go into an infinite loop!
        path = Inst.removeSelfReference(Absyn.pathLastIdent(inmodel),path);
        inmodeldef = getPathedClassInProgram(inmodel, p) "Look first inside \'inmodel\'" ;
        cdef = getPathedClassInProgram(path, Absyn.PROGRAM({inmodeldef},Absyn.TOP(),ts));
        newpath = Absyn.joinPaths(inmodel, path);
      then
        (cdef,newpath);
    
    case (path,inmodel,p) /* Then look inside next level */
      equation
        //Debug.fprintln(Flags.INTER, "Interactive.lookupClassdef 2 Looking for: " +& Absyn.pathString(path) +& " in: " +& Absyn.pathString(inmodel));
        innewpath = Absyn.stripLast(inmodel);
        (cdef,respath) = lookupClassdef(path, innewpath, p);
      then
        (cdef,respath);
    
    case (path,inmodel,p)
      equation
        //Debug.fprintln(Flags.INTER, "Interactive.lookupClassdef 3 Looking for: " +& Absyn.pathString(path) +& " in: " +& Absyn.pathString(inmodel));
        cdef = getPathedClassInProgram(path, p) "Finally look in top level" ;
      then
        (cdef,path);
    
    case (Absyn.IDENT(name = "Real"),_,_) then (Absyn.CLASS("Real",false,false,false,Absyn.R_PREDEFINED_REAL(),
          Absyn.PARTS({},{},NONE()),Absyn.dummyInfo),Absyn.IDENT("Real"));
    
    case (Absyn.IDENT(name = "Integer"),_,_) then (Absyn.CLASS("Integer",false,false,false,Absyn.R_PREDEFINED_INTEGER(),
          Absyn.PARTS({},{},NONE()),Absyn.dummyInfo),Absyn.IDENT("Integer"));
    
    case (Absyn.IDENT(name = "String"),_,_) then (Absyn.CLASS("String",false,false,false,Absyn.R_PREDEFINED_STRING(),
          Absyn.PARTS({},{},NONE()),Absyn.dummyInfo),Absyn.IDENT("String"));
    
    case (Absyn.IDENT(name = "Boolean"),_,_) then (Absyn.CLASS("Boolean",false,false,false,Absyn.R_PREDEFINED_BOOLEAN(),
          Absyn.PARTS({},{},NONE()),Absyn.dummyInfo),Absyn.IDENT("Boolean"));
    
    case (path,inmodel,_)
      equation
        //Debug.fprintln(Flags.INTER, "Interactive.lookupClassdef 8 Looking for: " +& Absyn.pathString(path) +& " in: " +& Absyn.pathString(inmodel));
        s1 = Absyn.pathString(path);
        s2 = Absyn.pathString(inmodel);
        Error.addMessage(Error.LOOKUP_ERROR, {s1,s2});
      then
        fail();
  end matchcontinue;
end lookupClassdef;

protected function deleteComponent
"function: deleteComponent
   This function deletes a component from a class given the name of the
   component instance, the model in which the component is instantiated in,
   and the Program. Both public and protected lists are searched."
  input String inString;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
  output String outString;
algorithm
  (outProgram,outString):=
  matchcontinue (inString,inComponentRef,inProgram)
    local
      Absyn.Path modelpath,modelwithin;
      String name;
      Absyn.ComponentRef model_;
      Absyn.Program p,newp;
      Absyn.Class cdef,newcdef;
      Absyn.Within w;
      Absyn.TimeStamp ts;

    case (name,model_,p)
      equation
        modelpath = Absyn.crefToPath(model_);
        failure(_ = getPathedClassInProgram(modelpath, p));
      then
        (p,"false\n");
    case (name,(model_ as Absyn.CREF_QUAL(name = _)),(p as Absyn.PROGRAM(within_ = w,globalBuildTimes=ts)))
      equation
        modelpath = Absyn.crefToPath(model_);
        modelwithin = Absyn.stripLast(modelpath);
        cdef = getPathedClassInProgram(modelpath, p);
        newcdef = deleteComponentFromClass(name, cdef);
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(modelwithin),ts), p);
      then
        (newp,"true\n");
    case (name,(model_ as Absyn.CREF_IDENT(name = _)),(p as Absyn.PROGRAM(within_ = w,globalBuildTimes=ts)))
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        newcdef = deleteComponentFromClass(name, cdef);
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.TOP(),ts), p);
      then
        (newp,"true\n");
    case (_,_,p) then (p,"false\n");
  end matchcontinue;
end deleteComponent;

protected function deleteComponentFromClass
"function: deleteComponentFromClass
   This function deletes a component from a class given
   the name of the component instance, and a \'Class\'.
   Both public and protected lists are searched."
  input String inString;
  input Absyn.Class inClass;
  output Absyn.Class outClass;
algorithm
  outClass := matchcontinue (inString,inClass)
    local
      list<Absyn.ElementItem> publst,publst2,protlst,protlst2;
      Integer l2,l1,l1_1;
      list<Absyn.ClassPart> parts2,parts;
      String name,i;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      Absyn.Info file_info;
      Absyn.Ident bcpath;
      list<Absyn.ElementArg> mod;
      list<String> typeVars;

     /* Search in public list */
    case (name,Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                           body = Absyn.PARTS(typeVars = typeVars,classParts = parts,comment = cmt),
                           info = file_info))
      equation
        publst = getPublicList(parts);
        publst2 = deleteComponentFromElementitems(name, publst);
        l2 = listLength(publst2);
        l1 = listLength(publst);
        l1_1 = l1 - 1;
        true = intEq(l1_1, l2);
        parts2 = replacePublicList(parts, publst2);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(typeVars,parts2,cmt),file_info);

    /* Search in protected list */
    case (name,Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                           body = Absyn.PARTS(typeVars = typeVars,classParts = parts,comment = cmt),
                           info = file_info))
      equation
        protlst = getProtectedList(parts);
        protlst2 = deleteComponentFromElementitems(name, protlst);
        l2 = listLength(protlst2);
        l1 = listLength(protlst);
        l1_1 = l1 - 1;
        true = intEq(l1_1, l2);
        parts2 = replaceProtectedList(parts, protlst2);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(typeVars,parts2,cmt),file_info);

     /* adrpo search also in model extends X end X */
    case (name,Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                           body = Absyn.CLASS_EXTENDS(baseClassName=bcpath, modifications=mod, parts = parts,comment = cmt),
                           info = file_info))
      equation
        publst = getPublicList(parts);
        publst2 = deleteComponentFromElementitems(name, publst);
        l2 = listLength(publst2);
        l1 = listLength(publst);
        l1_1 = l1 - 1;
        true = intEq(l1_1, l2);
        parts2 = replacePublicList(parts, publst2);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.CLASS_EXTENDS(bcpath,mod,cmt,parts2),file_info);

    /* adrpo search also in model extends X end X */
    case (name,Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                           body = Absyn.CLASS_EXTENDS(baseClassName=bcpath, modifications=mod, parts = parts,comment = cmt),
                           info = file_info))
      equation
        protlst = getProtectedList(parts);
        protlst2 = deleteComponentFromElementitems(name, protlst);
        l2 = listLength(protlst2);
        l1 = listLength(protlst);
        l1_1 = l1 - 1;
        true = intEq(l1_1, l2);
        parts2 = replaceProtectedList(parts, protlst2);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.CLASS_EXTENDS(bcpath,mod,cmt,parts2),file_info);

  end matchcontinue;
end deleteComponentFromClass;

protected function deleteComponentFromElementitems
"function: deleteComponentFromElementitems
  Helper function to deleteComponentFromClass."
  input String inString;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm
  outAbsynElementItemLst:=
  matchcontinue (inString,inAbsynElementItemLst)
    local
      String name,name2;
      list<Absyn.ElementItem> xs,res;
      Absyn.ElementItem x;
    case (_,{}) then {};
    case (name,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = {Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = name2))}))) :: xs))
      equation
        true = stringEq(name, name2);
      then
        xs;
    case (name,((x as Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = {Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = name2))})))) :: xs))
      equation
        false = stringEq(name, name2);
        res = deleteComponentFromElementitems(name, xs);
      then
        (x :: res);
    case (name,(x :: xs))
      equation
        res = deleteComponentFromElementitems(name, xs);
      then
        (x :: res);
  end matchcontinue;
end deleteComponentFromElementitems;

public function addComponent "function addComponent

   This function takes:
   arg1 - string giving the instancename,
   arg2 - `ComponentRef\' giving the component type
   arg3 - ComponentRef giving the model to instantiate the component within,
   arg4 - `NamedArg\' list of annotations
   arg5 - a Program.
   The result is an updated program with the component and its annotations
   inserted, and a string \"OK\" for success. If the insertion fails, a
   suitable error string is given along with the input Program.
"
  input String inString1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input list<Absyn.NamedArg> inAbsynNamedArgLst4;
  input Absyn.Program inProgram5;
  output Absyn.Program outProgram;
  output String outString;
algorithm
  (outProgram,outString):=
  matchcontinue (inString1,inComponentRef2,inComponentRef3,inAbsynNamedArgLst4,inProgram5)
    local
      Absyn.Path modelpath,modelwithin,tppath;
      String name;
      Absyn.ComponentRef tp,model_;
      list<Absyn.NamedArg> nargs;
      Absyn.Program p,newp;
      Absyn.Class cdef,newcdef;
      Option<Absyn.Comment> annotation_;
      Option<Absyn.Modification> modification;
      Absyn.Within w;
      Absyn.InnerOuter io;
      Option<Absyn.RedeclareKeywords> redecl;
      Absyn.ElementAttributes attr;
      Absyn.TimeStamp ts;
    /* class cannot be found */
    case (name,tp,model_,nargs,p)
      equation
        modelpath = Absyn.crefToPath(model_);
        failure(_ = getPathedClassInProgram(modelpath, p));
      then
        (p,"false\n");

    /* Adding component to model that resides inside package */
    case (name,tp,(model_ as Absyn.CREF_QUAL(name = _)),nargs,(p as Absyn.PROGRAM(within_ = w,globalBuildTimes=ts)))
      equation
        modelpath = Absyn.crefToPath(model_);
        modelwithin = Absyn.stripLast(modelpath);
        cdef = getPathedClassInProgram(modelpath, p);
        tppath = Absyn.crefToPath(tp);
        annotation_ = annotationListToAbsynComment(nargs,NONE());
        modification = modificationToAbsyn(nargs,NONE());
        (io,redecl,attr) = getDefaultPrefixes(p,tppath);
        newcdef = addToPublic(cdef,
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,redecl,io,"",
          Absyn.COMPONENTS(attr,Absyn.TPATH(tppath,NONE()),{
          Absyn.COMPONENTITEM(Absyn.COMPONENT(name,{},modification),NONE(),annotation_)}),
          Absyn.INFO("",false,0,0,0,0,ts),NONE())));
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(modelwithin),ts), p);
      then
        (newp,"Ok\n");

     /* Adding component to model that resides on top level */
    case (name,tp,(model_ as Absyn.CREF_IDENT(name = _)),nargs,(p as Absyn.PROGRAM(within_ = w,globalBuildTimes=ts)))
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        tppath = Absyn.crefToPath(tp);
        annotation_ = annotationListToAbsynComment(nargs,NONE());
        modification = modificationToAbsyn(nargs,NONE());
        (io,redecl,attr) = getDefaultPrefixes(p,tppath);
        newcdef = addToPublic(cdef,
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,redecl,io,"",
          Absyn.COMPONENTS(attr,Absyn.TPATH(tppath,NONE()),{
          Absyn.COMPONENTITEM(Absyn.COMPONENT(name,{},modification),NONE(),annotation_)}),
          Absyn.INFO("",false,0,0,0,0,ts),NONE())));
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.TOP(),ts), p);
      then
        (newp,"Ok\n");
    case (_,_,_,_,p) then (p,"Error");
  end matchcontinue;
end addComponent;

protected function getDefaultPrefixes "Retrieves default prefixes by looking at the defaultComponentPrefixes annotation"
  input Absyn.Program p;
  input Absyn.Path className;
  output Absyn.InnerOuter io;
  output Option<Absyn.RedeclareKeywords> redecl;
  output Absyn.ElementAttributes attr;
algorithm
  (io,redecl,attr) := match(p,className)
  local String str;
    case(p,className) equation
      str = getNamedAnnotation(className,p,"defaultComponentPrefixes",SOME("{}"),getDefaultComponentPrefixesModStr);
      io = getDefaultInnerOuter(str);
      redecl = getDefaultReplaceable(str);
      attr = getDefaultAttr(str);
    then(io,redecl,attr);
  end match;
end getDefaultPrefixes;

protected function getDefaultInnerOuter "helper function to getDefaultPrefixes"
  input String str;
  output Absyn.InnerOuter io;
algorithm
    io := matchcontinue(str)
      case(str) equation
        -1 = System.stringFind(str,"inner");
       -1 = System.stringFind(str,"outer");
      then Absyn.NOT_INNER_OUTER();

      case(str) equation
       -1 = System.stringFind(str,"outer");
      then Absyn.INNER();

      case(str) equation
       -1 = System.stringFind(str,"inner");
      then Absyn.OUTER();
      end matchcontinue;
end getDefaultInnerOuter;

protected function getDefaultReplaceable "helper function to getDefaultPrefixes"
  input String str;
  output Option<Absyn.RedeclareKeywords> repl;
algorithm
    repl := matchcontinue(str)
      case(str) equation
        -1 = System.stringFind(str,"replaceable");
      then NONE();
      case(str) equation
       failure(-1 = System.stringFind(str,"replaceable"));
      then SOME(Absyn.REPLACEABLE());
      end matchcontinue;
end getDefaultReplaceable;

protected function getDefaultAttr "helper function to getDefaultPrefixes"
  input String str;
  output Absyn.ElementAttributes attr;
algorithm
    attr := matchcontinue(str)
      case(str) equation
        failure(-1 = System.stringFind(str,"parameter"));
      then Absyn.ATTR(false,false,Absyn.NON_PARALLEL(),Absyn.PARAM(),Absyn.BIDIR(),{});

      case(str) equation
        failure(-1 = System.stringFind(str,"constant"));
      then Absyn.ATTR(false,false,Absyn.NON_PARALLEL(),Absyn.CONST(),Absyn.BIDIR(),{});

      case(str) equation
        failure(-1 = System.stringFind(str,"discrete"));
      then Absyn.ATTR(false,false,Absyn.NON_PARALLEL(),Absyn.DISCRETE(),Absyn.BIDIR(),{});
      case(str) then Absyn.ATTR(false,false,Absyn.NON_PARALLEL(),Absyn.VAR(),Absyn.BIDIR(),{});
  end matchcontinue;
end getDefaultAttr;

protected function getDefaultComponentPrefixesModStr "Extractor function for defaultComponentPrefixes modifier"
  input Option<Absyn.Modification> mod;
  output String docStr;
algorithm
  docStr := matchcontinue(mod)
    local Absyn.Exp e;
    case(SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=e)))) equation
      docStr = Dump.printExpStr(e);
    then docStr;
    case(mod) then "";
  end matchcontinue;
end getDefaultComponentPrefixesModStr;

protected function updateComponent
"function: updateComponent
   This function updates a component in a class. The reason for having
   thisfunction is that a deletion followed by an addition would mean that
   all optional arguments must be present to the add_componentfunction
   in order to get the same component attributes,etc. as previous."
  input String inString1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input list<Absyn.NamedArg> inAbsynNamedArgLst4;
  input Absyn.Program inProgram5;
  output Absyn.Program outProgram;
  output String outString;
algorithm
  (outProgram,outString) := matchcontinue (inString1,inComponentRef2,inComponentRef3,inAbsynNamedArgLst4,inProgram5)
    local
      Absyn.ComponentRef tp;
      Absyn.Path modelpath,modelwithin,tppath;
      Option<Absyn.ArrayDim> x;
      Absyn.Program p_1,newp,p;
      list<Absyn.ClassPart> parts;
      Absyn.Class cdef,newcdef;
      list<Absyn.ElementItem> publst,protlst;
      Boolean finalPrefix;
      Option<Absyn.RedeclareKeywords> repl;
      Absyn.InnerOuter inout;
      String id,name;
      Absyn.ElementAttributes attr;
      list<Absyn.ComponentItem> items;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constr;
      Option<Absyn.Modification> mod,modification;
      Option<Absyn.Exp> cond;
      Option<Absyn.Comment> ann,annotation_;
      Absyn.ComponentRef model_;
      list<Absyn.NamedArg> nargs;
      Absyn.Within w;
      Absyn.TimeStamp ts;
    /* Updating a public component to model that resides inside package */
    case (name,_,(model_ as Absyn.CREF_QUAL(name = _)),nargs,(p as Absyn.PROGRAM(within_ = w,globalBuildTimes=ts)))
      equation
        modelpath = Absyn.crefToPath(model_);
        modelwithin = Absyn.stripLast(modelpath);
        (p_1,_) = deleteComponent(name, model_, p);
        Absyn.CLASS(body = Absyn.PARTS(classParts = parts)) = getPathedClassInProgram(modelpath, p);
        cdef = getPathedClassInProgram(modelpath, p_1);
        publst = getPublicList(parts);
        Absyn.ELEMENT(finalPrefix,repl,inout,id,Absyn.COMPONENTS(attr,Absyn.TPATH(tppath,x),items),info,constr) = getElementContainsName(Absyn.CREF_IDENT(name,{}), publst);
        Absyn.COMPONENTITEM(Absyn.COMPONENT(_,_,mod),cond,ann) = getCompitemNamed(Absyn.CREF_IDENT(name,{}), items);
        annotation_ = annotationListToAbsynComment(nargs, ann);
        modification = modificationToAbsyn(nargs, mod);
        newcdef = addToPublic(cdef,
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(finalPrefix,repl,inout,id,
          Absyn.COMPONENTS(attr,Absyn.TPATH(tppath,x),
            {Absyn.COMPONENTITEM(Absyn.COMPONENT(name,{},modification),cond,annotation_)}),info,constr)));
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(modelwithin),ts), p);
      then
        (newp,"true");
    /* Updating a protected component to model that resides inside package */
    case (name,_,(model_ as Absyn.CREF_QUAL(name = _)),nargs,(p as Absyn.PROGRAM(within_ = w,globalBuildTimes=ts)))
      equation
        modelpath = Absyn.crefToPath(model_);
        modelwithin = Absyn.stripLast(modelpath);
        (p_1,_) = deleteComponent(name, model_, p);
        Absyn.CLASS(body=Absyn.PARTS(classParts=parts)) = getPathedClassInProgram(modelpath, p);
        cdef = getPathedClassInProgram(modelpath, p_1);
        protlst = getProtectedList(parts);
        Absyn.ELEMENT(finalPrefix,repl,inout,id,Absyn.COMPONENTS(attr,Absyn.TPATH(tppath,x),items),info,constr) = getElementContainsName(Absyn.CREF_IDENT(name,{}), protlst);
        Absyn.COMPONENTITEM(Absyn.COMPONENT(_,_,mod),cond,ann) = getCompitemNamed(Absyn.CREF_IDENT(name,{}), items);
        annotation_ = annotationListToAbsynComment(nargs, ann);
        modification = modificationToAbsyn(nargs, mod);
        newcdef = addToProtected(cdef,
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(finalPrefix,repl,inout,id,
          Absyn.COMPONENTS(attr,Absyn.TPATH(tppath,x),{
          Absyn.COMPONENTITEM(Absyn.COMPONENT(name,{},modification),cond,annotation_)}),info,constr)));
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(modelwithin),ts), p);
      then
        (newp,"true");
    /* Updating a public component to model that resides on top level */
    case (name,tp,(model_ as Absyn.CREF_IDENT(name = _)),nargs,(p as Absyn.PROGRAM(within_ = w,globalBuildTimes=ts)))
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        tppath = Absyn.crefToPath(tp);
        (p_1,_) = deleteComponent(name, model_, p);
        cdef = getPathedClassInProgram(modelpath, p_1);
        Absyn.CLASS(body=Absyn.PARTS(classParts=parts)) = getPathedClassInProgram(modelpath, p);
        publst = getPublicList(parts);
        Absyn.ELEMENT(finalPrefix,repl,inout,id,Absyn.COMPONENTS(attr,Absyn.TPATH(_,x),items),info,constr) = getElementContainsName(Absyn.CREF_IDENT(name,{}), publst);
        Absyn.COMPONENTITEM(Absyn.COMPONENT(_,_,mod),cond,ann) = getCompitemNamed(Absyn.CREF_IDENT(name,{}), items);
        annotation_ = annotationListToAbsynComment(nargs, ann);
        modification = modificationToAbsyn(nargs, mod);
        newcdef = addToPublic(cdef,
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(finalPrefix,repl,inout,id,
          Absyn.COMPONENTS(attr,Absyn.TPATH(tppath,x),{
          Absyn.COMPONENTITEM(Absyn.COMPONENT(name,{},modification),cond,annotation_)}),info,constr)));
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.TOP(),ts), p);
      then
        (newp,"true");
    /* Updating a protected component to model that resides on top level */
    case (name,tp,(model_ as Absyn.CREF_IDENT(name = _)),nargs,(p as Absyn.PROGRAM(within_ = w,globalBuildTimes=ts)))
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        tppath = Absyn.crefToPath(tp);
        (p_1,_) = deleteComponent(name, model_, p);
        cdef = getPathedClassInProgram(modelpath, p_1);
        Absyn.CLASS(body=Absyn.PARTS(classParts=parts)) = getPathedClassInProgram(modelpath, p);
        protlst = getProtectedList(parts);
        Absyn.ELEMENT(finalPrefix,repl,inout,id,Absyn.COMPONENTS(attr,Absyn.TPATH(_,x),items),info,constr) = getElementContainsName(Absyn.CREF_IDENT(name,{}), protlst);
        Absyn.COMPONENTITEM(Absyn.COMPONENT(_,_,mod),cond,ann) = getCompitemNamed(Absyn.CREF_IDENT(name,{}), items);
        annotation_ = annotationListToAbsynComment(nargs, ann);
        modification = modificationToAbsyn(nargs, mod);
        newcdef = addToProtected(cdef,
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(finalPrefix,repl,inout,id,
          Absyn.COMPONENTS(attr,Absyn.TPATH(tppath,x),{
          Absyn.COMPONENTITEM(Absyn.COMPONENT(name,{},modification),cond,annotation_)}),info,constr)));
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.TOP(),ts), p);
      then
        (newp,"true");
    
    // failure
    case (name,tp,model_,nargs,p)
      equation
      then
        (p,"false");
    /* adrpo: TODO!: handle also model extends M end M; i.e. CLASS_EXTENDS */
  end matchcontinue;
end updateComponent;

protected function addClassAnnotation
"function:addClassAnnotation
   This function takes a `ComponentRef\' and an `Exp\' expression and a
   `Program\' and adds the expression as a annotation to the specified
   model in the program, returning the updated program."
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
algorithm
  (outProgram) := match (inComponentRef,inAbsynNamedArgLst,inProgram)
    local
      Absyn.Path modelpath,modelwithin;
      Absyn.Class cdef,cdef_1;
      Absyn.Program newp,p;
      Absyn.ComponentRef model_;
      list<Absyn.NamedArg> nargs;
      Absyn.TimeStamp ts;
    case ((model_ as Absyn.CREF_QUAL(name = _)),nargs, p as Absyn.PROGRAM(globalBuildTimes=ts))
      equation
        modelpath = Absyn.crefToPath(model_) "Class inside other class" ;
        modelwithin = Absyn.stripLast(modelpath);
        cdef = getPathedClassInProgram(modelpath, p);
        cdef_1 = addClassAnnotationToClass(cdef, nargs);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},Absyn.WITHIN(modelwithin),ts), p);
      then
        newp;
    case ((model_ as Absyn.CREF_IDENT(name = _)),nargs,p as Absyn.PROGRAM(globalBuildTimes=ts))
      equation
        modelpath = Absyn.crefToPath(model_) "Class on top level" ;
        cdef = getPathedClassInProgram(modelpath, p);
        cdef_1 = addClassAnnotationToClass(cdef, nargs);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},Absyn.TOP(),ts), p);
      then
        newp;
  end match;
end addClassAnnotation;

protected function addClassAnnotationToClass
"function: addClassAnnotationToClass
   This function adds an annotation on element level to a `Class´."
  input Absyn.Class inClass;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  output Absyn.Class outClass;
algorithm
  outClass := matchcontinue (inClass,inAbsynNamedArgLst)
    local
      list<Absyn.ElementItem> publst,publst2;
      Absyn.Annotation annotation_,oldann,newann,newann_1;
      Absyn.Class cdef_1,cdef;
      list<Absyn.ClassPart> parts,parts2;
      list<Absyn.NamedArg> nargs;
      String i,bcname;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      Absyn.Info file_info;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
    /* a class with parts */
    case ((cdef as Absyn.CLASS(body = Absyn.PARTS(classParts = parts))),nargs)
      equation
        publst = getPublicList(parts) "No annotation element found in class" ;
        failure(_ = getElementAnnotationInElements(publst));
        annotation_ = annotationListToAbsyn(nargs);
        cdef_1 = addToPublic(cdef, Absyn.ANNOTATIONITEM(annotation_));
      then
        cdef_1;
    case ((cdef as Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                               body = Absyn.PARTS(typeVars = typeVars,classParts = parts,comment = cmt),
                               info = file_info)),nargs)
      equation
        publst = getPublicList(parts);
        Absyn.ANNOTATIONITEM(oldann) = getElementAnnotationInElements(publst);
        newann = annotationListToAbsyn(nargs);
        newann_1 = mergeAnnotations(oldann, newann);
        publst2 = replaceElementAnnotationInElements(publst, newann_1);
        parts2 = replacePublicList(parts, publst2);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(typeVars,parts2,cmt),file_info);
    /* an extended class with parts: model extends M end M; */
    case ((cdef as Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts))),nargs)
      equation
        publst = getPublicList(parts) "No annotation element found in class" ;
        failure(_ = getElementAnnotationInElements(publst));
        annotation_ = annotationListToAbsyn(nargs);
        cdef_1 = addToPublic(cdef, Absyn.ANNOTATIONITEM(annotation_));
      then
        cdef_1;
    case ((cdef as Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                               body = Absyn.CLASS_EXTENDS(baseClassName=bcname,modifications=modif,parts = parts,comment = cmt),
                               info = file_info)),nargs)
      equation
        publst = getPublicList(parts);
        Absyn.ANNOTATIONITEM(oldann) = getElementAnnotationInElements(publst);
        newann = annotationListToAbsyn(nargs);
        newann_1 = mergeAnnotations(oldann, newann);
        publst2 = replaceElementAnnotationInElements(publst, newann_1);
        parts2 = replacePublicList(parts, publst2);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts2),file_info);
  end matchcontinue;
end addClassAnnotationToClass;

protected function replaceElementAnnotationInElements
"function: replaceElementAnnotationInElements
   This function takes an element list and replaces the
   first annotation with the one given as argument."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Annotation inAnnotation;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm
  outAbsynElementItemLst:=
  matchcontinue (inAbsynElementItemLst,inAnnotation)
    local
      list<Absyn.ElementItem> xs,res;
      Absyn.Annotation a,a2;
      Absyn.ElementItem el;
    case ((Absyn.ANNOTATIONITEM(annotation_ = _) :: xs),a) then (Absyn.ANNOTATIONITEM(a) :: xs);
    case ((el :: xs),a2)
      equation
        res = replaceElementAnnotationInElements(xs, a2);
      then
        (el :: res);
    case ({},_) then {};
  end matchcontinue;
end replaceElementAnnotationInElements;

protected function getElementAnnotationInElements
"function: getElementAnnotationInElements
   This function retrieves the first Annotation
   among the elements taken as argument"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output Absyn.ElementItem outElementItem;
algorithm
  outElementItem:=
  matchcontinue (inAbsynElementItemLst)
    local
      Absyn.ElementItem a;
      list<Absyn.ElementItem> xs;
    case (((a as Absyn.ANNOTATIONITEM(annotation_ = _)) :: xs)) then a;
    case ((_ :: xs))
      equation
        a = getElementAnnotationInElements(xs);
      then
        a;
  end matchcontinue;
end getElementAnnotationInElements;

protected function mergeAnnotations
"function: mergeAnnotations
   This function takes an old annotation as first argument and a new
   annotation as  second argument and merges the two.
   Annotation \"parts\" that exist in both the old and the new annotation
   will be changed according to the new definition. For instance,
   merge_annotations(annotation(x=1,y=2),annotation(x=3))
   => annotation(x=3,y=2)"
  input Absyn.Annotation inAnnotation1;
  input Absyn.Annotation inAnnotation2;
  output Absyn.Annotation outAnnotation;
algorithm
  outAnnotation:=
  matchcontinue (inAnnotation1,inAnnotation2)
    local
      list<Absyn.ElementArg> neweltargs,oldrest,eltargs,eltargs_1;
      Absyn.ElementArg mod;
      Absyn.ComponentRef cr;
      Absyn.Annotation a;
    case (Absyn.ANNOTATION(elementArgs = ((mod as Absyn.MODIFICATION(componentRef = cr)) :: oldrest)),Absyn.ANNOTATION(elementArgs = eltargs))
      equation
        failure(_ = removeModificationInElementargs(eltargs, cr));
        Absyn.ANNOTATION(neweltargs) = mergeAnnotations(Absyn.ANNOTATION(oldrest), Absyn.ANNOTATION(eltargs));
      then
        Absyn.ANNOTATION((mod :: neweltargs));
    case (Absyn.ANNOTATION(elementArgs = ((mod as Absyn.MODIFICATION(componentRef = cr)) :: oldrest)),Absyn.ANNOTATION(elementArgs = eltargs))
      equation
        eltargs_1 = removeModificationInElementargs(eltargs, cr);
        Absyn.ANNOTATION(neweltargs) = mergeAnnotations(Absyn.ANNOTATION(oldrest), Absyn.ANNOTATION(eltargs));
      then
        Absyn.ANNOTATION(neweltargs);
    case (Absyn.ANNOTATION(elementArgs = {}),a) then a;
  end matchcontinue;
end mergeAnnotations;

protected function removeModificationInElementargs
"function: removeModificationInElementargs
   This function removes the class modification named by the second argument.
   If no such class modification is found thefunction fails.
   Currently, only identifiers are allowed as class modifiers,
   i.e. a(...) and not a.b(...)"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input Absyn.ComponentRef inComponentRef;
  output list<Absyn.ElementArg> outAbsynElementArgLst;
algorithm
  outAbsynElementArgLst := matchcontinue (inAbsynElementArgLst,inComponentRef)
    local
      String id1,id2;
      Absyn.ComponentRef cr;
      Absyn.ElementArg m;
      list<Absyn.ElementArg> res,xs;
    
    case ({Absyn.MODIFICATION(componentRef = Absyn.CREF_IDENT(name = id1))},(cr as Absyn.CREF_IDENT(name = id2)))
      equation
        true = stringEq(id1, id2);
      then
        {};
    
    case ({(m as Absyn.MODIFICATION(componentRef = Absyn.CREF_IDENT(name = id1)))},(cr as Absyn.CREF_IDENT(name = id2)))
      equation
        false = stringEq(id1, id2);
      then
        fail();
    
    case ((Absyn.MODIFICATION(componentRef = Absyn.CREF_IDENT(name = id1)) :: xs),(cr as Absyn.CREF_IDENT(name = id2)))
      equation
        true = stringEq(id1, id2);
        res = removeModificationInElementargs(xs, cr);
      then
        res;
    
    case (((m as Absyn.MODIFICATION(componentRef = Absyn.CREF_IDENT(name = id1))) :: xs),(cr as Absyn.CREF_IDENT(name = id2)))
      equation
        false = stringEq(id1, id2);
        res = removeModificationInElementargs(xs, cr);
      then
        (m :: res);
    
    case (((m as Absyn.MODIFICATION(componentRef = Absyn.CREF_IDENT(name = id1))) :: xs),(cr as Absyn.CREF_IDENT(name = id2)))
      equation
        res = removeModificationInElementargs(xs, cr);
      then
        (m :: res);
  end matchcontinue;
end removeModificationInElementargs;

protected function getInheritanceCount
"function: getInheritanceCount
  This function takes a ComponentRef and a Program and
  returns the number of inherited classes in the class
  referenced by the ComponentRef."
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      Integer count;
      Absyn.ComponentRef model_;
      Absyn.Program p;
    case (model_,p)
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        count = countBaseClasses(cdef);
      then
        count;
    case (_,_) then 0;
  end matchcontinue;
end getInheritanceCount;

protected function getNthInheritedClass
"function: getNthInheritedClass
  This function takes a ComponentRef, an integer and a Program and returns
  the nth inherited class in the class referenced by the ComponentRef."
  input Absyn.ComponentRef inComponentRef;
  input Integer inInteger;
  input SymbolTable ist;
  output String outString;
  output SymbolTable outSt;
algorithm
  (outString,outSt) := matchcontinue (inComponentRef,inInteger,ist)
    local
      Absyn.Path modelpath,path;
      Absyn.Class cdef;
      list<SCode.Element> p_1;
      list<Env.Frame> env,env_1;
      SCode.Element c;
      String id,str,s;
      SCode.Encapsulated encflag;
      SCode.Restriction restr;
      Absyn.ComponentRef model_;
      Integer n,n_1;
      Absyn.Program p;
      list<Absyn.ElementSpec> extends_;
      Env.Cache cache;
      SymbolTable st;

    case (model_,n,st as SYMBOLTABLE(ast=p))
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        (p_1,st) = symbolTableToSCode(st);
        (cache,env) = Inst.makeEnvFromProgram(Env.emptyCache(),p_1, Absyn.IDENT(""));
        (_,(c as SCode.CLASS(name=id,encapsulatedPrefix=encflag,restriction=restr)),env_1) = Lookup.lookupClass(cache,env, modelpath, false);
        str = getNthInheritedClass2(c, cdef, n, env_1);
      then
        (str,st);
    case (model_,n,st as SYMBOLTABLE(ast=p)) /* if above fails, baseclass not defined. return its name */
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        extends_ = getExtendsInClass(cdef);
        n_1 = n - 1;
        Absyn.EXTENDS(path,_,_) = listNth(extends_, n_1);
        s = Absyn.pathString(path);
      then
        (s,st);
    else ("Error",ist);
  end matchcontinue;
end getNthInheritedClass;

protected function getNthInheritedClassAnnotationOpt
"function: getNthInheritedClassAnnotation
  This function takes a ComponentRef, an integer and a Program and returns
  the ANNOTATION on the extends of the nth inherited class in the class referenced by the modelpath."
  input Absyn.Path inModelPath;
  input Integer inInteger;
  input Absyn.Class inClass;
  input Absyn.Program inProgram;
  output String outString;
  output Option<Absyn.Annotation> annotationOpt;
algorithm
  (outString, annotationOpt) := matchcontinue (inModelPath,inInteger,inClass,inProgram)
    local
      Absyn.Path modelpath,path;
      Absyn.Class cdef;
      String s;
      Integer n,n_1;
      Absyn.Program p;
      list<Absyn.ElementSpec> extends_;
      Option<Absyn.Annotation> annOpt;

    /* adrpo: fixme, handle this case too!
    case (modelpath,n,inClass,p)
      equation
        cdef = inClass;
        p_1 = SCodeUtil.translateAbsyn2SCode(p);
        (cache,env) = Inst.makeEnvFromProgram(Env.emptyCache(),p_1, Absyn.IDENT(""));
        (_,(c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = Lookup.lookupClass(cache, env, modelpath, false);
        str = getNthInheritedClass2(c, cdef, n, env_1);
      then
        (str, annOpt);
    */

    case (modelpath,n,inClass,p) /* if above fails, baseclass not defined. return its name */
      equation
        cdef = inClass;
        extends_ = getExtendsInClass(cdef);
        n_1 = n - 1;
        Absyn.EXTENDS(path,_,annOpt) = listNth(extends_, n_1);
        s = Absyn.pathString(path);
      then
        (s, annOpt);

    case (_,_,_,_) then ("Error", NONE());
  end matchcontinue;
end getNthInheritedClassAnnotationOpt;

protected function getMapAnnotationStr
"function: getMapAnnotationStr"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input String inMapType "IconMap or DiagramMap";
  input Absyn.Class inClass;
  input Absyn.Program inFullProgram;
  input Absyn.Path inModelPath;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynElementArgLst, inMapType, inClass, inFullProgram, inModelPath)
    local
      String str;
      Absyn.ElementArg ann;
      Option<Absyn.Modification> mod;
      list<Absyn.ElementArg> xs;
      String mapType;

    case ({}, _, inClass, inFullProgram, inModelPath) then "{}";

    case ((ann as Absyn.MODIFICATION(componentRef = Absyn.CREF_IDENT(name = mapType),modification = mod)) :: _,inMapType,
          inClass, inFullProgram, inModelPath)
      equation
        // make sure is the given type: IconMap or DiagramMap
        true = stringEqual(mapType, inMapType);
        str = getAnnotationString(Absyn.ANNOTATION({ann}), inClass, inFullProgram, inModelPath);
      then
        str;

    case (_ :: xs, inMapType, inClass, inFullProgram, inModelPath)
      equation
        str = getMapAnnotationStr(xs, inMapType, inClass, inFullProgram, inModelPath);
      then
        str;
  end matchcontinue;
end getMapAnnotationStr;

protected function getNthInheritedClassMapAnnotation
"function: getNthInheritedClassIconMapAnnotation
  This function takes a ComponentRef, an integer and a Program and returns
  the ANNOTATION on the extends of the nth inherited class in the class referenced by the ComponentRef."
  input Absyn.Path inModelPath;
  input Integer inInteger;
  input Absyn.Program inProgram;
  input String inMapType "IconMap or DiagramMap";
  output String outString;
algorithm
  outString := matchcontinue (inModelPath,inInteger,inProgram,inMapType)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      String s,annStr;
      Integer n;
      Absyn.Program p;
      list<Absyn.ElementArg> elArgs;

    case (modelpath,n,p,inMapType)
      equation
        cdef = getPathedClassInProgram(modelpath, p);
        (s, SOME(Absyn.ANNOTATION(elArgs))) = getNthInheritedClassAnnotationOpt(modelpath, n, cdef, p);
        annStr = getMapAnnotationStr(elArgs,inMapType, cdef, p, modelpath);
        s = "{" +& s +& ", " +& annStr +& "}";
      then
        s;
    case (modelpath,n,p,inMapType)
      equation
        cdef = getPathedClassInProgram(modelpath, p);
        (s, NONE()) = getNthInheritedClassAnnotationOpt(modelpath, n, cdef, p);
        s = "{" +& s +& ",{}}";
      then
        s;
    case (_,_,_,_) then "Error";
  end matchcontinue;
end getNthInheritedClassMapAnnotation;

protected function getExtendsInClass
"function: getExtendsInClass
  Returns all ElementSpec of EXTENDS in a class."
  input Absyn.Class inClass;
  output list<Absyn.ElementSpec> outAbsynElementSpecLst;
algorithm
  outAbsynElementSpecLst := match (inClass)
    local
      list<Absyn.ElementSpec> res;
      String n;
      Boolean p,f,e;
      Absyn.Restriction r;
      list<Absyn.ClassPart> parts;
    /* a class with parts */
    case (Absyn.CLASS(name = n,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(classParts = parts)))
      equation
        res = getExtendsInParts(parts);
      then
        res;
    /* an extended class with parts: model extends M end M; */
    case (Absyn.CLASS(name = n,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(parts = parts)))
      equation
        res = getExtendsInParts(parts);
      then
        res;
    /* adrpo: TODO! how about model extends M(modifications) end M??
                    should we report EXTENDS(IDENT(M), modifications)? */
  end match;
end getExtendsInClass;

protected function getExtendsInParts
"function: getExtendsInParts
  author: PA
  Helper function to getExtendsInElass."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ElementSpec> outAbsynElementSpecLst;
algorithm
  outAbsynElementSpecLst := matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.ElementSpec> l1,l2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> parts;
    case {} then {};
    case ((Absyn.PUBLIC(contents = elts) :: parts))
      equation
        l1 = getExtendsInParts(parts);
        l2 = getExtendsInElementitems(elts);
        res = listAppend(l1, l2);
      then
        res;
    case ((Absyn.PROTECTED(contents = elts) :: parts))
      equation
        l1 = getExtendsInParts(parts);
        l2 = getExtendsInElementitems(elts);
        res = listAppend(l1, l2);
      then
        res;
    case ((_ :: parts))
      equation
        res = getExtendsInParts(parts);
      then
        res;
  end matchcontinue;
end getExtendsInParts;

protected function getExtendsInElementitems
"function: getExtendsInElementitems
  author: PA
  Helper function to getExtendsInParts."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.ElementSpec> outAbsynElementSpecLst;
algorithm
  outAbsynElementSpecLst:=
  matchcontinue (inAbsynElementItemLst)
    local
      list<Absyn.ElementSpec> res;
      Absyn.ElementSpec e;
      list<Absyn.ElementItem> es;
    case ({}) then {};
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = (e as Absyn.EXTENDS(path = _)))) :: es))
      equation
        res = getExtendsInElementitems(es);
      then
        (e :: res);
    case ((_ :: es))
      equation
        res = getExtendsInElementitems(es);
      then
        res;
  end matchcontinue;
end getExtendsInElementitems;

protected function getNthInheritedClass2
"function: getNthInheritedClass2
  Helper function to getNthInheritedClass."
  input SCode.Element inClass1;
  input Absyn.Class inClass2;
  input Integer inInteger3;
  input Env.Env inEnv4;
  output String outString;
algorithm
  outString := matchcontinue (inClass1,inClass2,inInteger3,inEnv4)
    local
      list<Absyn.ComponentRef> lst;
      Integer n_1,n;
      Absyn.ComponentRef cref;
      Absyn.Path path;
      String str,id;
      SCode.Element c;
      Absyn.Class cdef;
      list<Env.Frame> env,env2,env_2;
      ClassInf.State ci_state;
      SCode.Encapsulated encflag;
      SCode.Restriction restr;
    /* First try without instantiating, if class is in parents */
    case ((c as SCode.CLASS(name = _)),cdef,n,env)
      equation
        lst = getBaseClasses(cdef, env);
        n_1 = n - 1;
        cref = listNth(lst, n_1);
        path = Absyn.crefToPath(cref);
        str = Absyn.pathString(path);
      then
        str;
    /* If that fails, instantiate, which takes more time */
    case ((c as SCode.CLASS(name = id,encapsulatedPrefix = encflag,restriction = restr)),cdef,n,env)
      equation
        env2 = Env.openScope(env, encflag, SOME(id), Env.restrictionToScopeType(restr));
        ci_state = ClassInf.start(restr, Env.getEnvName(env2));
        (_,env_2,_,_) =
          Inst.partialInstClassIn(Env.emptyCache(),env2,InnerOuter.emptyInstHierarchy,
            DAE.NOMOD(), Prefix.NOPRE(), ci_state, c, SCode.PUBLIC(), {});
        lst = getBaseClasses(cdef, env_2);
        n_1 = n - 1;
        cref = listNth(lst, n_1);
        path = Absyn.crefToPath(cref);
        str = Absyn.pathString(path);
      then
        str;
  end matchcontinue;
end getNthInheritedClass2;

public function getComponentCount
"function: getComponentCount
   This function takes a ComponentRef and a Program and returns the
   number of public components in the class referenced by the ComponentRef."
  input Absyn.ComponentRef model_;
  input Absyn.Program p;
  output Integer count;
protected
  Absyn.Path modelpath;
  Absyn.Class cdef;
algorithm
  modelpath := Absyn.crefToPath(model_);
  cdef := getPathedClassInProgram(modelpath, p);
  count := countComponents(cdef);
end getComponentCount;

protected function countComponents
"function: countComponents
   This function takes a Class and returns the
   number of components in that class"
  input Absyn.Class inClass;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inClass)
    local
      Integer c1,c2,res;
      String a;
      Boolean b,c,d;
      Absyn.Restriction e;
      list<Absyn.ElementItem> elt;
      list<Absyn.ClassPart> lst;
      Option<String> cmt;
      Absyn.Info file_info;

    /* a class with parts */
    case Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                     body = Absyn.PARTS(classParts = (Absyn.PUBLIC(contents = elt) :: lst),comment = cmt),info = file_info)
      equation
        c1 = countComponents(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info));
        c2 = countComponentsInElts(elt);
      then
        c1 + c2;
    case Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                     body = Absyn.PARTS(classParts = (Absyn.PROTECTED(contents = elt) :: lst),comment = cmt),info = file_info)
      equation
        c1 = countComponents(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info));
        c2 = countComponentsInElts(elt);
      then
        c1 + c2;
    case Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                     body = Absyn.PARTS(classParts = (_ :: lst),comment = cmt),info = file_info)
      equation
        res = countComponents(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info));
      then
        res;
    case Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,
                     restriction = e,body = Absyn.PARTS(classParts = {})) then 0;

    /* adrpo: handle also an extended class with parts: model extends M end M; */
    case Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                     body = Absyn.CLASS_EXTENDS(parts = (Absyn.PUBLIC(contents = elt) :: lst),comment = cmt),info = file_info)
      equation
        c1 = countComponents(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info));
        c2 = countComponentsInElts(elt);
      then
        c1 + c2;
    case Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                     body = Absyn.CLASS_EXTENDS(parts = (Absyn.PROTECTED(contents = elt) :: lst),comment = cmt),info = file_info)
      equation
        c1 = countComponents(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info));
        c2 = countComponentsInElts(elt);
      then
        c1 + c2;
    case Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                     body = Absyn.CLASS_EXTENDS(parts = (_ :: lst),comment = cmt),info = file_info)
      equation
        res = countComponents(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info));
      then
        res;
    case Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,
                     restriction = e,body = Absyn.CLASS_EXTENDS(parts = {})) then 0;

    /* a derived class */
    case Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                     body = Absyn.DERIVED(typeSpec = _)) then -1;
    /* adrpo: TODO! we should also handle CLASS_EXTENDS(parts), model extends M end M; */
  end matchcontinue;
end countComponents;

protected function countComponentsInElts
"function: countComponentsInElts
  Helper function to countComponents"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inAbsynElementItemLst)
    local
      Integer c1,ncomps,res;
      list<Absyn.ComponentItem> complst;
      list<Absyn.ElementItem> lst;
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = complst),constrainClass = NONE())) :: lst))
      equation
        c1 = countComponentsInElts(lst);
        ncomps = listLength(complst);
      then
        c1 + ncomps;
    case ((_ :: lst))
      equation
        res = countComponentsInElts(lst);
      then
        res;
    case ({}) then 0;
  end matchcontinue;
end countComponentsInElts;

protected function getNthComponent "function: getNthComponent

   This function takes a `ComponentRef\', a `Program\' and an int and
   returns a comma separated string of names containing the name, type
   and comment of that component.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  input Integer inInteger;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef,inProgram,inInteger)
    local
      Absyn.Path modelpath;
      list<SCode.Element> p_1;
      list<Env.Frame> env,env_1;
      SCode.Element c;
      String id,str;
      SCode.Encapsulated encflag;
      SCode.Restriction restr;
      Absyn.Class cdef;
      Absyn.ComponentRef model_;
      Absyn.Program p;
      Integer n;
      Env.Cache cache;

    case (model_,p,n)
      equation
        modelpath = Absyn.crefToPath(model_);
        p_1 = SCodeUtil.translateAbsyn2SCode(p);
        (cache,env) = Inst.makeEnvFromProgram(Env.emptyCache(),p_1, Absyn.IDENT(""));
        (_,(c as SCode.CLASS(name=id,encapsulatedPrefix=encflag,restriction=restr)),env_1) = Lookup.lookupClass(cache,env, modelpath, false);
        cdef = getPathedClassInProgram(modelpath, p);
        str = getNthComponent2(c, cdef, n, env_1);
      then
        str;
    case (_,_,_) then "Error";
  end matchcontinue;
end getNthComponent;

protected function getNthComponent2
"function: getNthComponent2
  Helper function to get_nth_component."
  input SCode.Element inClass1;
  input Absyn.Class inClass2;
  input Integer inInteger3;
  input Env.Env inEnv4;
  output String outString;
algorithm
  outString:=
  matchcontinue (inClass1,inClass2,inInteger3,inEnv4)
    local
      list<Env.Frame> env2,env_2,env;
      ClassInf.State ci_state;
      Absyn.Element comp;
      String s1,str,id;
      SCode.Element c;
      SCode.Encapsulated encflag;
      SCode.Restriction restr;
      Absyn.Class cdef;
      Integer n;
      
    case ((c as SCode.CLASS(name = id,encapsulatedPrefix = encflag,restriction = restr)),cdef,n,env)
      equation
        env2 = Env.openScope(env, encflag, SOME(id), Env.restrictionToScopeType(restr));
        ci_state = ClassInf.start(restr, Env.getEnvName(env2));
        (_,env_2,_,_) =
          Inst.partialInstClassIn(Env.emptyCache(),env2,InnerOuter.emptyInstHierarchy,
            DAE.NOMOD(), Prefix.NOPRE(), ci_state, c, SCode.PUBLIC(), {});
        comp = getNthComponentInClass(cdef, n);
        {s1} = getComponentInfoOld(comp, env_2);
        str = stringAppendList({"{", s1, "}"});
      then
        str;
    case (_,_,_,_)
      equation
        print("Interactive.getNthComponent2 failed\n");
      then
        fail();
  end matchcontinue;
end getNthComponent2;

protected function useQuotes
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inAbsynNamedArgLst)
    local
      Absyn.NamedArg a;
      list<Absyn.NamedArg> al;
      Boolean b,res;
    case ({}) then false;
    case ((Absyn.NAMEDARG(argName = "useQuotes",argValue = Absyn.BOOL(value = b)) :: _)) then b;
    case ((a :: al))
      equation
        res = useQuotes(al);
      then
        res;
  end matchcontinue;
end useQuotes;

public function getComponents
"function: getComponents
   This function takes a `ComponentRef\', a `Program\' and an int and  returns
   a list of all components, as returned by get_nth_component."
  input Absyn.ComponentRef cr;
  input Boolean inBoolean;
  input SymbolTable st;
  output String outString;
  output SymbolTable outSt;
algorithm
  (outString,outSt) := getComponents2(cr,inBoolean,st);
end getComponents;

protected function getComponents2
"function: getComponents
   This function takes a `ComponentRef\', a `Program\' and an int and  returns
   a list of all components, as returned by get_nth_component."
  input Absyn.ComponentRef inComponentRef;
  input Boolean inBoolean;
  input SymbolTable ist;
  output String outString;
  output SymbolTable outSt;
algorithm
  (outString,outSt) := matchcontinue (inComponentRef,inBoolean,ist)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      list<SCode.Element> p_1;
      list<Env.Frame> env,env_1,env2,env_2;
      SCode.Element c;
      String id,s1,s2,str,res;
      SCode.Encapsulated encflag;
      SCode.Restriction restr;
      ClassInf.State ci_state;
      list<Absyn.Element> comps1,comps2;
      Absyn.ComponentRef model_;
      Absyn.Program p;
      Env.Cache cache;
      Boolean b;
      SymbolTable st;

    case (model_,b,st as SYMBOLTABLE(ast=p))
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        (p_1,st) = symbolTableToSCode(st);
        (cache,env) = Inst.makeEnvFromProgram(Env.emptyCache(),p_1, Absyn.IDENT(""));
        (cache,(c as SCode.CLASS(name=id,encapsulatedPrefix=encflag,restriction=restr)),env_1) = Lookup.lookupClass(cache,env, modelpath, false);
        env2 = Env.openScope(env_1, encflag, SOME(id), Env.restrictionToScopeType(restr));
        ci_state = ClassInf.start(restr, Env.getEnvName(env2));
        (_,env_2,_,_) =
          Inst.partialInstClassIn(cache, env2, InnerOuter.emptyInstHierarchy, DAE.NOMOD(),
            Prefix.NOPRE(), ci_state, c, SCode.PUBLIC(), {});
        comps1 = getPublicComponentsInClass(cdef);
        s1 = getComponentsInfo(comps1, b, "\"public\"", env_2);
        comps2 = getProtectedComponentsInClass(cdef);
        s2 = getComponentsInfo(comps2, b, "\"protected\"", env_2);
        str = Util.stringDelimitListNonEmptyElts({s1,s2}, ",");
        res = stringAppendList({"{",str,"}"});
      then
        (res,st);
    case (_,_,st) then ("Error",st);
  end matchcontinue;
end getComponents2;

protected function getComponentAnnotations "function: getComponentAnnotations
   This function takes a `ComponentRef\', a `Program\' and
   returns a list of all component annotations, as returned by
   get_nth_component_annotation.
   Both public and protected components are returned, but they need to
   be in the same order as get_componentsfunctions, i.e. first public
   components then protected ones."
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output String outString;
algorithm
  outString := matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      list<Absyn.Element> comps1,comps2,comps;
      String s1,str;
      Absyn.ComponentRef model_;
      Absyn.Program p;

    case (model_,p)
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        comps1 = getPublicComponentsInClass(cdef);
        comps2 = getProtectedComponentsInClass(cdef);
        comps = listAppend(comps1, comps2);
        s1 = getComponentAnnotationsFromElts(comps, cdef, p, modelpath);
        str = stringAppendList({"{", s1, "}"});
      then
        str;
    case (_,_) then "Error";
  end matchcontinue;
end getComponentAnnotations;

protected function getNthComponentAnnotation "function: getNthComponentAnnotation

   This function takes a `ComponentRef\', a `Program\' and an int and
   returns a comma separated string of values corresponding to the flat
   record for component annotations.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inComponentRef,inProgram,inInteger)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      Absyn.Element comp;
      String s1,str;
      Absyn.ComponentRef model_;
      Absyn.Program p;
      Integer n;
    case (model_,p,n)
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        comp = getNthComponentInClass(cdef, n);
        s1 = getComponentAnnotation(comp, cdef, p, modelpath);
        str = stringAppendList({"{", s1, "}"});
      then
        str;
    case (_,_,_) then "Error";
  end matchcontinue;
end getNthComponentAnnotation;

protected function getNthComponentModification "function: getNthComponentModification

  This function takes a `ComponentRef\', a `Program\' and an int and
  returns a comma separated string of values corresponding to the
  flat record for component annotations.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  input Integer inInteger;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef,inProgram,inInteger)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      Absyn.Element comp;
      String str,str_1;
      Absyn.ComponentRef model_;
      Absyn.Program p;
      Integer n;
    case (model_,p,n)
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        comp = getNthComponentInClass(cdef, n);
        str = getComponentModification(comp);
        str_1 = stringAppendList({"{",str,"}"});
      then
        str_1;
    case (_,_,_) then "Error";
  end matchcontinue;
end getNthComponentModification;

protected function getNthComponentCondition
"function: getNthComponentCondition
  This function takes a `ComponentRef\', a `Program\' and an int and
  returns a component condition."
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  input Integer inInteger;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef,inProgram,inInteger)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      Absyn.Element comp;
      String str,str_1;
      Absyn.ComponentRef model_;
      Absyn.Program p;
      Integer n;
    case (model_,p,n)
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        comp = getNthComponentInClass(cdef, n);
        str = getComponentCondition(comp);
        str = System.trim(str, " ");
        str_1 = stringAppendList({"\"",str,"\""});
      then
        str_1;
    case (_,_,_) then "Error";
  end matchcontinue;
end getNthComponentCondition;

protected function getComponentCondition
"function: getComponentCondition
   Helper function to getNthComponentCondition."
  input Absyn.Element inElement;
  output String outString;
algorithm
  outString:=
  matchcontinue (inElement)
    local
      String str;
      list<Absyn.ComponentItem> lst;
    case (Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = lst),constrainClass = NONE()))
      equation
        str = getComponentitemsCondition(lst);
      then
        str;
    case _ then "";
  end matchcontinue;
end getComponentCondition;

protected function getComponentitemsCondition
"function: getComponentitemsCondition
  Helper function to getNthComponentCondition."
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inAbsynComponentItemLst)
    local
      String s1,s2,res,str;
      Option<Absyn.ComponentCondition> cond;
      list<Absyn.ComponentItem> rest;
    case ({(Absyn.COMPONENTITEM(condition = cond))})
      equation
        res = Dump.unparseComponentCondition(cond);
      then
        res;
  end matchcontinue;
end getComponentitemsCondition;

protected function getConnectionCount "function: getConnectionCount

  This function takes a `ComponentRef\' and a `Program\' and returns a
  string containing the number of connections in the model identified by
  the `ComponentRef\'.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      Integer numconn;
      String res;
      Absyn.ComponentRef model_;
      Absyn.Program p;
    case (model_,p)
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        numconn = countConnections(cdef);
        res = intString(numconn);
      then
        res;
    case (_,_) then "Error";
  end matchcontinue;
end getConnectionCount;

protected function getNthConnection "function: getNthConnection

  This function takes a `ComponentRef\' and a `Program\' and an int and
  returns a comma separated string for the nth connection, e.g. \"R1.n,C.p\".
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  input Integer inInteger;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef,inProgram,inInteger)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      Absyn.Equation eq;
      Option<Absyn.Comment> cmt;
      String str2,str,res;
      Absyn.ComponentRef model_;
      Absyn.Program p;
      Integer n;
    case (model_,p,n)
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        Absyn.EQUATIONITEM(equation_ = eq, comment = cmt) = getNthConnectionitemInClass(cdef, n);
        str2 = getStringComment(cmt);
        str = getConnectionStr(eq);
        res = stringAppendList({"{",str,", ",str2,"}"});
      then
        res;
    case (_,_,_) then "Error";
  end matchcontinue;
end getNthConnection;

protected function getStringComment "function: getStringComment

  Returns the string comment or empty string from a Comment option.
"
  input Option<Absyn.Comment> cmt;
  output String res;
protected
  String s;
algorithm
  s := getStringComment2(cmt);
  res := stringAppendList({"\"",s,"\""});
end getStringComment;

protected function getStringComment2
  input Option<Absyn.Comment> inAbsynCommentOption;
  output String outString;
algorithm
  outString:=
  matchcontinue (inAbsynCommentOption)
    local String str;
    case (SOME(Absyn.COMMENT(_,SOME(str)))) then str;
    case (_) then "";
  end matchcontinue;
end getStringComment2;

protected function addConnection "function: addConnection

  Adds a connect equation to the model, i..e connect(c1,c2)

  inputs: (Absyn.ComponentRef, /* model name */
             Absyn.ComponentRef, /* c1 */
             Absyn.ComponentRef, /* c2 */
             Absyn.NamedArg list, /* annotations */
             Absyn.Program) =>
  outputs: (string, Absyn.Program)
"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input list<Absyn.NamedArg> inAbsynNamedArgLst4;
  input Absyn.Program inProgram5;
  output String outString;
  output Absyn.Program outProgram;
algorithm
  (outString,outProgram):=
  matchcontinue (inComponentRef1,inComponentRef2,inComponentRef3,inAbsynNamedArgLst4,inProgram5)
    local
      Absyn.Path modelpath,package_;
      Absyn.Class cdef,newcdef;
      Absyn.Program newp,p;
      Absyn.ComponentRef model_,c1,c2;
      Absyn.Within w;
      Option<Absyn.Comment> cmt;
      list<Absyn.NamedArg> nargs;
      Absyn.TimeStamp ts;

    case ((model_ as Absyn.CREF_IDENT(name = _)),c1,c2,{},(p as Absyn.PROGRAM(within_ = w,globalBuildTimes=ts)))
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        newcdef = addToEquation(cdef, Absyn.EQUATIONITEM(Absyn.EQ_CONNECT(c1,c2),NONE(),Absyn.dummyInfo));
        newp = updateProgram(Absyn.PROGRAM({newcdef},w,ts), p);
      then
        ("Ok",newp);

    case ((model_ as Absyn.CREF_QUAL(name = _)),c1,c2,{},(p as Absyn.PROGRAM(within_ = w,globalBuildTimes=ts)))
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        package_ = Absyn.stripLast(modelpath);
        newcdef = addToEquation(cdef, Absyn.EQUATIONITEM(Absyn.EQ_CONNECT(c1,c2),NONE(),Absyn.dummyInfo));
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(package_),ts), p);
      then
        ("Ok",newp);
    case ((model_ as Absyn.CREF_IDENT(name = _)),c1,c2,nargs,(p as Absyn.PROGRAM(within_ = w,globalBuildTimes=ts)))
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        cmt = annotationListToAbsynComment(nargs,NONE());
        newcdef = addToEquation(cdef, Absyn.EQUATIONITEM(Absyn.EQ_CONNECT(c1,c2),cmt,Absyn.dummyInfo));
        newp = updateProgram(Absyn.PROGRAM({newcdef},w,ts), p);
      then
        ("Ok",newp);
    case ((model_ as Absyn.CREF_QUAL(name = _)),c1,c2,nargs,(p as Absyn.PROGRAM(within_ = w,globalBuildTimes=ts)))
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        package_ = Absyn.stripLast(modelpath);
        cmt = annotationListToAbsynComment(nargs,NONE());
        newcdef = addToEquation(cdef, Absyn.EQUATIONITEM(Absyn.EQ_CONNECT(c1,c2),cmt,Absyn.dummyInfo));
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(package_),ts), p);
      then
        ("Ok",newp);
  end matchcontinue;
end addConnection;

protected function deleteConnection "function: deleteConnection

  Delete the connection connect(c1,c2) from a model.

  inputs:  (Absyn.ComponentRef, /* model name */
              Absyn.ComponentRef, /* c1 */
              Absyn.ComponentRef, /* c2 */
              Absyn.Program)
  outputs:  (string,Absyn.Program)
"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input Absyn.Program inProgram4;
  output String outString;
  output Absyn.Program outProgram;
algorithm
  (outString,outProgram):=
  matchcontinue (inComponentRef1,inComponentRef2,inComponentRef3,inProgram4)
    local
      Absyn.Path modelpath,modelwithin;
      Absyn.Class cdef,newcdef;
      Absyn.Program newp,p;
      Absyn.ComponentRef model_,c1,c2;
      Absyn.Within w;
      Absyn.TimeStamp ts;

    case (model_,c1,c2,(p as Absyn.PROGRAM(within_ = w,globalBuildTimes=ts)))
      equation
        modelpath = Absyn.crefToPath(model_);
        modelwithin = Absyn.stripLast(modelpath);
        cdef = getPathedClassInProgram(modelpath, p);
        newcdef = deleteEquationInClass(cdef, c1, c2);
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(modelwithin),ts), p);
      then
        ("Ok",newp);
    case (model_,c1,c2,(p as Absyn.PROGRAM(within_ = w,globalBuildTimes=ts)))
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        newcdef = deleteEquationInClass(cdef, c1, c2);
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.TOP(),ts), p);
      then
        ("Ok",newp);
    case (model_,c1,c2,(p as Absyn.PROGRAM(within_ = w,globalBuildTimes=ts))) then ("Error",p);
  end matchcontinue;
end deleteConnection;

protected function deleteEquationInClass
"function: deleteEquationInClass
  Helper function to deleteConnection."
  input Absyn.Class inClass1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.Class outClass;
algorithm
  outClass:=
  match (inClass1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.EquationItem> eqlst,eqlst_1;
      list<Absyn.ClassPart> parts2,parts;
      String i, bcname;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      Absyn.Info file_info;
      Absyn.ComponentRef c1,c2;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
    /* a class with parts */
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars,classParts = parts,comment = cmt),info = file_info),c1,c2)
      equation
        eqlst = getEquationList(parts);
        eqlst_1 = deleteEquationInEqlist(eqlst, c1, c2);
        parts2 = replaceEquationList(parts, eqlst_1);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(typeVars,parts2,cmt),file_info);
    /* an extended class with parts: model extends M end M;  */
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName = bcname,modifications=modif,parts = parts,comment = cmt),info = file_info),c1,c2)
      equation
        eqlst = getEquationList(parts);
        eqlst_1 = deleteEquationInEqlist(eqlst, c1, c2);
        parts2 = replaceEquationList(parts, eqlst_1);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts2),file_info);
  end match;
end deleteEquationInClass;

protected function deleteEquationInEqlist
"function: deleteEquationInEqlist
  Helper function to deleteConnection."
  input list<Absyn.EquationItem> inAbsynEquationItemLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.EquationItem> outAbsynEquationItemLst;
algorithm
  outAbsynEquationItemLst := matchcontinue (inAbsynEquationItemLst1,inComponentRef2,inComponentRef3)
    local
      Absyn.Path p1,p2,pn1,pn2;
      String s1,s2,sn1,sn2;
      list<Absyn.EquationItem> res,xs;
      Absyn.ComponentRef cn1,cn2,c1,c2;
      Absyn.EquationItem x;
    
    case ({},_,_) then {};
    case ((Absyn.EQUATIONITEM(equation_ = Absyn.EQ_CONNECT(connector1 = cn1,connector2 = cn2)) :: xs),c1,c2)
      equation
        true = Absyn.crefEqual(c1,cn1);
        true = Absyn.crefEqual(c2,cn2);
        res = deleteEquationInEqlist(xs, c1, c2);
      then
        res;
    case ((x :: xs),c1,c2)
      equation
        res = deleteEquationInEqlist(xs, c1, c2);
      then
        (x :: res);
  end matchcontinue;
end deleteEquationInEqlist;

protected function getComponentComment
"function: getComponentComment
  Get the component commment."
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.Program inProgram4;
  output String outString;
algorithm
  (outString) :=  match (inComponentRef1,inComponentRef2,inProgram4)
    local
      Absyn.Path p_class;
      Absyn.Class cdef;
      Absyn.Program p;
      Absyn.ComponentRef class_,cr1;
      String cmt;
      Absyn.TimeStamp ts;
    case (class_,cr1,p as Absyn.PROGRAM(globalBuildTimes=ts))
      equation
        p_class = Absyn.crefToPath(class_);
        cdef = getPathedClassInProgram(p_class, p);
        cmt = getComponentCommentInClass(cdef, cr1);
      then
        cmt;
  end match;
end getComponentComment;

protected function getComponentCommentInClass
"function: getComponentCommentInClass
  Helper function to getComponentComment."
  input Absyn.Class inClass;
  input Absyn.ComponentRef inComponentRef;
  output String outString;
algorithm
  outString := match (inClass,inComponentRef)
    local
      list<Absyn.ClassPart> parts;
      String cmt;
      Absyn.ComponentRef cr1;
    /* a class with parts */      
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),cr1)
      equation
        cmt = getComponentCommentInParts(parts, cr1);      
      then
        cmt;
    /* an extended class with parts: model extends M end M; */
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)),cr1)
      equation
        cmt = getComponentCommentInParts(parts, cr1);
      then
        cmt;
  end match;
end getComponentCommentInClass;

protected function getComponentCommentInParts
"function: getComponentCommentInParts
  Helper function to getComponentComment."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Absyn.ComponentRef inComponentRef;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynClassPartLst,inComponentRef)
    local
      list<Absyn.ElementItem> elts,e;
      list<Absyn.ClassPart> xs;
      Absyn.ComponentRef cr1;
      String cmt;
      Absyn.ClassPart p;
    case ((Absyn.PUBLIC(contents = elts) :: xs),cr1)
      equation
        cmt = getComponentCommentInElementitems(elts, cr1);
      then
        cmt;
    case ((Absyn.PUBLIC(contents = e) :: xs),cr1) /* rule above failed */
      equation
        cmt = getComponentCommentInParts(xs, cr1);
      then
        cmt;
    case ((Absyn.PROTECTED(contents = elts) :: xs),cr1)
      equation
        cmt = getComponentCommentInElementitems(elts, cr1);
      then
        cmt;
    case ((Absyn.PROTECTED(contents = e) :: xs),cr1) /* rule above failed */
      equation
        cmt = getComponentCommentInParts(xs, cr1);
      then
        cmt;
    case ((p :: xs),cr1)
      equation
        cmt = getComponentCommentInParts(xs, cr1);
      then
        cmt;
  end matchcontinue;
end getComponentCommentInParts;

protected function getComponentCommentInElementitems
"function: getComponentCommentInElementitems
  Helper function to getComponentComment."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.ComponentRef inComponentRef;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynElementItemLst,inComponentRef)
    local
      Absyn.ElementSpec spec_1,spec;
      Boolean f;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter inout;
      String n,cmt;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constr;
      list<Absyn.ElementItem> es,es_1;
      Absyn.ComponentRef cr1;
      Absyn.ElementItem e;
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = inout,name = n,specification = spec,info = info,constrainClass = constr)) :: es),cr1)
      equation
        cmt = getComponentCommentInElementspec(spec, cr1);
      then
        cmt;
    case ((e :: es),cr1)
      equation
        cmt = getComponentCommentInElementitems(es, cr1);
      then
        cmt;
  end matchcontinue;
end getComponentCommentInElementitems;

protected function getComponentCommentInElementspec
"function: getComponentCommentInElementspec
  Helper function to getComponentComment."
  input Absyn.ElementSpec inElementSpec;
  input Absyn.ComponentRef inComponentRef;
  output String outString;
algorithm
  outString := match (inElementSpec,inComponentRef)
    local
      list<Absyn.ComponentItem> citems_1,citems;
      Absyn.ElementAttributes attr;
      Absyn.TypeSpec tp;
      Absyn.ComponentRef cr;
      String cmt;
    case (Absyn.COMPONENTS(attributes = attr,typeSpec=tp,components = citems),cr)
      equation
        cmt = getComponentCommentInCompitems(citems, cr);
      then
        cmt;
  end match;
end getComponentCommentInElementspec;

protected function getComponentCommentInCompitems
"function: getComponentCommentInCompitems
  Helper function to getComponentComment."
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Absyn.ComponentRef inComponentRef;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynComponentItemLst,inComponentRef)
    local
      Option<Absyn.Comment> compcmt_1,compcmt;
      String id,cmt;
      list<Absyn.Subscript> ad;
      Option<Absyn.Modification> mod;
      Option<Absyn.Exp> cond;
      list<Absyn.ComponentItem> cs,cs_1;
      Absyn.ComponentRef cr;
      Absyn.ComponentItem c;
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = ad,modification = mod),condition = cond,comment = compcmt) :: cs),cr)
      equation
        true = Absyn.crefEqual(Absyn.CREF_IDENT(id,ad), cr);
        cmt = getClassCommentInCommentOpt(compcmt);
      then
        cmt;
    case ((c :: cs),cr)
      equation
        cmt = getComponentCommentInCompitems(cs, cr);
      then
        cmt;
  end matchcontinue;
end getComponentCommentInCompitems;

protected function getClassCommentInCommentOpt
"function: getClassCommentInCommentOpt
  Helper function to getComponentComment."
  input Option<Absyn.Comment> inAbsynCommentOption;
  output String outString;
algorithm
  outString := match (inAbsynCommentOption)
    local
      Option<Absyn.Annotation> ann;
      String cmt;
    case (SOME(Absyn.COMMENT(_,SOME(cmt)))) then cmt;
    case (SOME(Absyn.COMMENT(_,_))) then "";
  end match;
end getClassCommentInCommentOpt;

protected function setComponentComment
"function: setComponentComment
  author :PA
  Sets the component commment given by class name and ComponentRef."
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input String inString3;
  input Absyn.Program inProgram4;
  output String outString;
  output Absyn.Program outProgram;
algorithm
  (outString,outProgram):=
  matchcontinue (inComponentRef1,inComponentRef2,inString3,inProgram4)
    local
      Absyn.Path p_class;
      Absyn.Within within_;
      Absyn.Class cdef,cdef_1;
      Absyn.Program newp,p;
      Absyn.ComponentRef class_,cr1;
      String cmt;
      Absyn.TimeStamp ts;

    case (class_,cr1,cmt,p as Absyn.PROGRAM(globalBuildTimes=ts))
      equation
        p_class = Absyn.crefToPath(class_);
        within_ = buildWithin(p_class);
        cdef = getPathedClassInProgram(p_class, p);
        cdef_1 = setComponentCommentInClass(cdef, cr1, cmt);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},within_,ts), p);
      then
        ("Ok",newp);
    
    case (class_,cr1,cmt,p) 
      then 
        ("Error",p);
  end matchcontinue;
end setComponentComment;

protected function setComponentCommentInClass
"function: setComponentCommentInClass
  author: PA
  Helper function to setComponentComment."
  input Absyn.Class inClass;
  input Absyn.ComponentRef inComponentRef;
  input String inString;
  output Absyn.Class outClass;
algorithm
  outClass := match (inClass,inComponentRef,inString)
    local
      list<Absyn.ClassPart> parts_1,parts;
      String name,cmt,bcname;
      Boolean p,f,e;
      Absyn.Restriction restr;
      Option<String> pcmt;
      Absyn.Info info;
      Absyn.ComponentRef cr1;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
    /* a class with parts */
    case (Absyn.CLASS(name = name,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = restr,
                      body = Absyn.PARTS(typeVars = typeVars,classParts = parts,comment = pcmt),info = info),cr1,cmt)
      equation
        parts_1 = setComponentCommentInParts(parts, cr1, cmt);
      then
        Absyn.CLASS(name,p,f,e,restr,Absyn.PARTS(typeVars,parts_1,pcmt),info);
    /* an extended class with parts: model extends M end M; */
    case (Absyn.CLASS(name = name,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = restr,
                      body = Absyn.CLASS_EXTENDS(baseClassName=bcname,modifications=modif,parts = parts,comment = pcmt),info = info),cr1,cmt)
      equation
        parts_1 = setComponentCommentInParts(parts, cr1, cmt);
      then
        Absyn.CLASS(name,p,f,e,restr,Absyn.CLASS_EXTENDS(bcname,modif,pcmt,parts_1),info);
  end match;
end setComponentCommentInClass;

protected function setComponentCommentInParts
"function: setComponentCommentInParts
  author: PA
  Helper function to setComponentCommentInClass."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Absyn.ComponentRef inComponentRef;
  input String inString;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst,inComponentRef,inString)
    local
      list<Absyn.ElementItem> elts_1,elts,e;
      list<Absyn.ClassPart> xs,xs_1;
      Absyn.ComponentRef cr1;
      String cmt;
      Absyn.ClassPart p;
    case ((Absyn.PUBLIC(contents = elts) :: xs),cr1,cmt)
      equation
        elts_1 = setComponentCommentInElementitems(elts, cr1, cmt);
      then
        (Absyn.PUBLIC(elts_1) :: xs);
    case ((Absyn.PUBLIC(contents = e) :: xs),cr1,cmt) /* rule above failed */
      equation
        xs_1 = setComponentCommentInParts(xs, cr1, cmt);
      then
        (Absyn.PUBLIC(e) :: xs_1);
    case ((Absyn.PROTECTED(contents = elts) :: xs),cr1,cmt)
      equation
        elts_1 = setComponentCommentInElementitems(elts, cr1, cmt);
      then
        (Absyn.PROTECTED(elts_1) :: xs);
    case ((Absyn.PROTECTED(contents = e) :: xs),cr1,cmt) /* rule above failed */
      equation
        xs_1 = setComponentCommentInParts(xs, cr1, cmt);
      then
        (Absyn.PROTECTED(e) :: xs_1);
    case ((p :: xs),cr1,cmt)
      equation
        xs_1 = setComponentCommentInParts(xs, cr1, cmt);
      then
        (p :: xs_1);
  end matchcontinue;
end setComponentCommentInParts;

protected function setComponentCommentInElementitems
"function: setComponentCommentInElementitems
  author: PA
  Helper function to setComponentParts. "
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.ComponentRef inComponentRef;
  input String inString;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm
  outAbsynElementItemLst:=
  matchcontinue (inAbsynElementItemLst,inComponentRef,inString)
    local
      Absyn.ElementSpec spec_1,spec;
      Boolean f;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter inout;
      String n,cmt;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constr;
      list<Absyn.ElementItem> es,es_1;
      Absyn.ComponentRef cr1;
      Absyn.ElementItem e;
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = inout,name = n,specification = spec,info = info,constrainClass = constr)) :: es),cr1,cmt)
      equation
        spec_1 = setComponentCommentInElementspec(spec, cr1, cmt);
      then
        (Absyn.ELEMENTITEM(Absyn.ELEMENT(f,r,inout,n,spec_1,info,constr)) :: es);
    case ((e :: es),cr1,cmt)
      equation
        es_1 = setComponentCommentInElementitems(es, cr1, cmt);
      then
        (e :: es_1);
  end matchcontinue;
end setComponentCommentInElementitems;

protected function setComponentCommentInElementspec
"function: setComponentCommentInElementspec
  author: PA
  Helper function to setComponentElementitems."
  input Absyn.ElementSpec inElementSpec;
  input Absyn.ComponentRef inComponentRef;
  input String inString;
  output Absyn.ElementSpec outElementSpec;
algorithm
  outElementSpec:=
  match (inElementSpec,inComponentRef,inString)
    local
      list<Absyn.ComponentItem> citems_1,citems;
      Absyn.ElementAttributes attr;
      Absyn.TypeSpec tp;
      Absyn.ComponentRef cr;
      String cmt;
    case (Absyn.COMPONENTS(attributes = attr,typeSpec=tp,components = citems),cr,cmt)
      equation
        citems_1 = setComponentCommentInCompitems(citems, cr, cmt);
      then
        Absyn.COMPONENTS(attr,tp,citems_1);
  end match;
end setComponentCommentInElementspec;

protected function setComponentCommentInCompitems
"function: setComponentCommentInCompitems
  author: PA
  Helper function to set_component_elementspec."
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Absyn.ComponentRef inComponentRef;
  input String inString;
  output list<Absyn.ComponentItem> outAbsynComponentItemLst;
algorithm
  outAbsynComponentItemLst:=
  matchcontinue (inAbsynComponentItemLst,inComponentRef,inString)
    local
      Option<Absyn.Comment> compcmt_1,compcmt;
      String id,cmt;
      list<Absyn.Subscript> ad;
      Option<Absyn.Modification> mod;
      Option<Absyn.Exp> cond;
      list<Absyn.ComponentItem> cs,cs_1;
      Absyn.ComponentRef cr;
      Absyn.ComponentItem c;
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = ad,modification = mod),condition = cond,comment = compcmt) :: cs),cr,cmt)
      equation
        true = Absyn.crefEqual(Absyn.CREF_IDENT(id,ad), cr);
        compcmt_1 = setClassCommentInCommentOpt(compcmt, cmt);
      then
        (Absyn.COMPONENTITEM(Absyn.COMPONENT(id,ad,mod),cond,compcmt_1) :: cs);
    case ((c :: cs),cr,cmt)
      equation
        cs_1 = setComponentCommentInCompitems(cs, cr, cmt);
      then
        (c :: cs_1);
  end matchcontinue;
end setComponentCommentInCompitems;

protected function setConnectionComment
"function: setConnectionComment
  author: PA
  Sets the nth connection comment."
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input String inString4;
  input Absyn.Program inProgram5;
  output Absyn.Program outProgram;
  output String outString;
algorithm
  (outProgram,outString):=
  matchcontinue (inComponentRef1,inComponentRef2,inComponentRef3,inString4,inProgram5)
    local
      Absyn.Path p_class;
      Absyn.Within within_;
      Absyn.Class cdef,cdef_1;
      Absyn.Program newp,p;
      Absyn.ComponentRef class_,cr1,cr2;
      String cmt;
      Absyn.TimeStamp ts;
    case (class_,cr1,cr2,cmt,p as Absyn.PROGRAM(globalBuildTimes=ts))
      equation
        p_class = Absyn.crefToPath(class_);
        within_ = buildWithin(p_class);
        cdef = getPathedClassInProgram(p_class, p);
        cdef_1 = setConnectionCommentInClass(cdef, cr1, cr2, cmt);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},within_,ts), p);
      then
        (newp,"Ok");
    case (_,_,_,_,p) then (p,"Error");
  end matchcontinue;
end setConnectionComment;

protected function setConnectionCommentInClass
"function: setConnectionCommentInClass
  author: PA
  Sets a connection comment in a Absyn.Class given two Absyn,ComponentRef"
  input Absyn.Class inClass1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input String inString4;
  output Absyn.Class outClass;
algorithm
  outClass:=
  match (inClass1,inComponentRef2,inComponentRef3,inString4)
    local
      list<Absyn.ClassPart> parts_1,parts;
      String name,cmt,bcname;
      Boolean p,f,e;
      Absyn.Restriction restr;
      Option<String> pcmt;
      Absyn.Info info;
      Absyn.ComponentRef cr1,cr2;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
    /* a class with parts */
    case (Absyn.CLASS(name = name,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = restr,
                      body = Absyn.PARTS(typeVars = typeVars,classParts = parts,comment = pcmt),info = info),cr1,cr2,cmt)
      equation
        parts_1 = setConnectionCommentInParts(parts, cr1, cr2, cmt);
      then
        Absyn.CLASS(name,p,f,e,restr,Absyn.PARTS(typeVars,parts_1,pcmt),info);
    /* an extended class with parts: model extends M end M; */
    case (Absyn.CLASS(name = name,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = restr,
                      body = Absyn.CLASS_EXTENDS(baseClassName=bcname,modifications=modif,parts = parts,comment = pcmt),info = info),cr1,cr2,cmt)
      equation
        parts_1 = setConnectionCommentInParts(parts, cr1, cr2, cmt);
      then
        Absyn.CLASS(name,p,f,e,restr,Absyn.CLASS_EXTENDS(bcname,modif,pcmt,parts_1),info);
  end match;
end setConnectionCommentInClass;

protected function setConnectionCommentInParts
"function: setConnectionCommentInParts
  author: PA
  Helper function to setConnectionCommentInClass."
  input list<Absyn.ClassPart> inAbsynClassPartLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input String inString4;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst1,inComponentRef2,inComponentRef3,inString4)
    local
      list<Absyn.EquationItem> e_1,e;
      list<Absyn.ClassPart> xs,xs_1;
      Absyn.ComponentRef cr1,cr2;
      String cmt;
      Absyn.ClassPart p;
    case ((Absyn.EQUATIONS(contents = e) :: xs),cr1,cr2,cmt)
      equation
        e_1 = setConnectionCommentInEquations(e, cr1, cr2, cmt);
      then
        (Absyn.EQUATIONS(e_1) :: xs);
    case ((Absyn.EQUATIONS(contents = e) :: xs),cr1,cr2,cmt) /* rule above failed */
      equation
        xs_1 = setConnectionCommentInParts(xs, cr1, cr2, cmt);
      then
        (Absyn.EQUATIONS(e) :: xs_1);
    case ((p :: xs),cr1,cr2,cmt)
      equation
        xs_1 = setConnectionCommentInParts(xs, cr1, cr2, cmt);
      then
        (p :: xs_1);
  end matchcontinue;
end setConnectionCommentInParts;

protected function setConnectionCommentInEquations
"function: setConnectionCommentInEquations
  author: PA
  Helper function to setConnectionCommentInParts"
  input list<Absyn.EquationItem> inAbsynEquationItemLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input String inString4;
  output list<Absyn.EquationItem> outAbsynEquationItemLst;
algorithm
  outAbsynEquationItemLst:=
  matchcontinue (inAbsynEquationItemLst1,inComponentRef2,inComponentRef3,inString4)
    local
      Option<Absyn.Comment> eqcmt_1,eqcmt;
      Absyn.ComponentRef c1,c2,cr1,cr2;
      list<Absyn.EquationItem> es,es_1;
      String cmt;
      Absyn.EquationItem e;
      Absyn.Info info;
    case ((Absyn.EQUATIONITEM(equation_ = Absyn.EQ_CONNECT(connector1 = c1,connector2 = c2),comment = eqcmt, info = info) :: es),cr1,cr2,cmt)
      equation
        true = Absyn.crefEqual(cr1, c1);
        true = Absyn.crefEqual(cr2, c2);
        eqcmt_1 = setClassCommentInCommentOpt(eqcmt, cmt);
      then
        (Absyn.EQUATIONITEM(Absyn.EQ_CONNECT(c1,c2),eqcmt_1,info) :: es);
    case ((e :: es),cr1,cr2,cmt)
      equation
        es_1 = setConnectionCommentInEquations(es, cr1, cr2, cmt);
      then
        (e :: es_1);
  end matchcontinue;
end setConnectionCommentInEquations;

protected function getNthConnectionAnnotation
"function: getNthConnectionAnnotation
  This function takes a ComponentRef and a Program and an int and
  returns a comma separated string  of values for the annotation of
  the nth connection."
  input Absyn.Path inModelPath;
  input Absyn.Program inProgram;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inModelPath,inProgram,inInteger)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      Absyn.EquationItem citem;
      String s1,str;
      Absyn.Program p;
      Integer n;
    case (modelpath,p,n)
      equation
        cdef = getPathedClassInProgram(modelpath, p);
        citem = getNthConnectionitemInClass(cdef, n);
        s1 = getConnectionAnnotationStr(citem, cdef, p, modelpath);
        str = stringAppendList({"{", s1, "}"});
      then
        str;
    case (_,_,_) then "{}";
  end matchcontinue;
end getNthConnectionAnnotation;

protected function getConnectorCount
"function: getConnectorCount
  This function takes a ComponentRef and a Program and returns the number
  of connector components in the class given by the classname in the
  ComponentRef. A partial instantiation of the inheritance structure is
  performed in order to find all connectors of the class.
  inputs:  (Absyn.ComponentRef, Absyn.Program)
  outputs: string"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      Integer count;
      String countstr;
      Absyn.ComponentRef model_;
      Absyn.Program p;
    case (model_,p)
      equation
        modelpath = Absyn.crefToPath(model_) "A complete instantiation is far too expensive. Instead we only
    look through the components of the class for types declared using
    the \"connector\" restricted class keyword. We also look in
    base classes  (recursively)
  " ;
        cdef = getPathedClassInProgram(modelpath, p);
        count = countPublicConnectors(modelpath, p, cdef);
        countstr = intString(count);
      then
        countstr;
    case (_,_) then "Error";
  end matchcontinue;
end getConnectorCount;

protected function getNthConnector
"function: getNthConnector
  This function takes a ComponentRef and a Program and an int and returns
  a string with the name of the nth
  connector component in the class given by ComponentRef in the Program."
  input Absyn.Path inModelPath;
  input Absyn.Program inProgram;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inModelPath,inProgram,inInteger)
    local
      Absyn.Path modelpath,tp;
      Absyn.Class cdef;
      String str,tpstr,resstr;
      Absyn.Program p;
      Integer n;
    
    case (modelpath,p,n)
      equation
        cdef = getPathedClassInProgram(modelpath, p);
        (str,tp) = getNthPublicConnectorStr(modelpath, cdef, p, n);
        tpstr = Absyn.pathString(tp);
        resstr = stringAppendList({str, ",", tpstr});
      then
        resstr;
    case (_,_,_) then "Error";
  end matchcontinue;
end getNthConnector;

protected function getNthConnectorIconAnnotation
"function: getNthConnectorIconAnnotation
   This function takes a ComponentRef and a Program and an int and returns
   a string with the name of the nth connectors icon annotation in the
   class given by ComponentRef in the Program."
  input Absyn.Path inModelPath;
  input Absyn.Program inProgram;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inModelPath,inProgram,inInteger)
    local
      Absyn.Path modelpath,tp;
      Absyn.Class cdef;
      String resstr;
      Absyn.Program p;
      Integer n;
    case (modelpath,p,n)
      equation
        cdef = getPathedClassInProgram(modelpath, p);
        (resstr,tp) = getNthPublicConnectorStr(modelpath, cdef, p, n);
        resstr = getIconAnnotation(tp, p);
      then
        resstr;
    case (_,_,_) then "Error";
  end matchcontinue;
end getNthConnectorIconAnnotation;

protected function getDiagramAnnotation
"function: getDiagramAnnotation
  This function takes a Path and a Program and returns a comma separated
  string of values for the diagram annotation for the class named by the
  first argument."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  output String outString;
algorithm
  outString := matchcontinue (inPath,inProgram)
    local
      Absyn.Class cdef;
      String str;
      Absyn.Path modelpath;
      Absyn.Program p;
    case (modelpath,p)
      equation
        cdef = getPathedClassInProgram(modelpath, p);
        str = getAnnotationInClass(cdef, DIAGRAM_ANNOTATION(), p, modelpath);
      then
        str;
    case (_,_) 
      then 
        "{}";
  end matchcontinue;
end getDiagramAnnotation;

public function getNamedAnnotation
"function: getNamedAnnotation
  This function takes a Path and a Program and returns a comma separated
  string of values for the Documentation annotation for the class named by the
  first argument."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Absyn.Ident id;
  input Option<T> default;
  input ModFunc f;
  partial function ModFunc
    input Option<Absyn.Modification> mod;
    output T docStr;
  end ModFunc;
  output T outString;
  replaceable type T subtypeof Any;
algorithm
  outString := matchcontinue (inPath,inProgram,id,default,f)
    local
      Absyn.Class cdef;
      T str;
      Absyn.Path modelpath;
      Absyn.Program p;
    
    case (modelpath,p,id,_,f)
      equation
        cdef = getPathedClassInProgram(modelpath, p);
        SOME(str) = getNamedAnnotationInClass(cdef,id,f);
      then
        str;
    
    case (_,_,_,SOME(str),_) then str;
  end matchcontinue;
end getNamedAnnotation;

public function getUsesAnnotation
"function: getNamedAnnotation
  This function takes a Path and a Program and returns a comma separated
  string of values for the Documentation annotation for the class named by the
  first argument."
  input Absyn.Program p;
  output list<tuple<Absyn.Path,list<String>>> usesStr;
algorithm
  usesStr := matchcontinue (p)
    local
      Absyn.Class cdef;
    
    case (Absyn.PROGRAM(classes={cdef}))
      equation
        SOME(usesStr) = getNamedAnnotationInClass(cdef,"uses",getUsesAnnotationString);
      then
        usesStr;
    
    else {};
  end matchcontinue;
end getUsesAnnotation;

public function getUsesAnnotationOrDefault
"function: getUsesAnnotationOrDefault
  This function takes a Path and a Program and returns a comma separated
  string of values for the Documentation annotation for the class named by the
  first argument."
  input Absyn.Program p;
  output list<tuple<Absyn.Path,list<String>>> usesStr;
protected
  list<Absyn.Path> paths;
  list<list<String>> strs;
algorithm
  usesStr := getUsesAnnotation(p);
  paths := List.map(usesStr,Util.tuple21);
  strs := List.map(usesStr,Util.tuple22);
  strs := List.map1(strs,listAppend,{"default"});
  usesStr := List.threadTuple(paths,strs);
end getUsesAnnotationOrDefault;

protected function getUsesAnnotationString
  input Option<Absyn.Modification> mod;
  output list<tuple<Absyn.Path,list<String>>> usesStr;
algorithm
  usesStr := match (mod)
    local 
      list<Absyn.ElementArg> arglst;
      list<String> strs;
      String s;

    case (SOME(Absyn.CLASSMOD(elementArgLst = arglst)))
      then getUsesAnnotationString2(arglst);    
  end match;
end getUsesAnnotationString;

protected function getUsesAnnotationString2
  input list<Absyn.ElementArg> eltArgs;
  output list<tuple<Absyn.Path,list<String>>> strs;
algorithm
  strs := matchcontinue (eltArgs)
    local
      Absyn.Exp exp;
      list<Absyn.ElementArg> xs;
      String name, s, version;
      list<tuple<Absyn.Path,list<String>>> ss;

    case ({}) then {};

    case (Absyn.MODIFICATION(componentRef = Absyn.CREF_IDENT(name = name),
      modification=SOME(Absyn.CLASSMOD(elementArgLst={
        Absyn.MODIFICATION(componentRef = Absyn.CREF_IDENT(name="version"),modification = SOME(Absyn.CLASSMOD(eqMod=Absyn.EQMOD(exp=Absyn.STRING(version)))))
      })))::xs)
      equation
        ss = getUsesAnnotationString2(xs);
      then (Absyn.IDENT(name),{version})::ss;
    
    case (_::xs)
      equation
        ss = getUsesAnnotationString2(xs);
      then ss;

    end matchcontinue;
end getUsesAnnotationString2;

protected function getIconAnnotation
"function: getIconAnnotation
  This function takes a Path and a Program and returns a comma separated
  string of values for the icon annotation for the class named by the
  first argument."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  output String outString;
algorithm
  outString := matchcontinue (inPath,inProgram)
    local
      Absyn.Class cdef;
      String str;
      Absyn.Path modelpath;
      Absyn.Program p;
    case (modelpath,p)
      equation
        cdef = getPathedClassInProgram(modelpath, p);
        str = getAnnotationInClass(cdef, ICON_ANNOTATION(), p, modelpath);
      then
        str;
    case (_,_) 
      then 
        "{}";
  end matchcontinue;
end getIconAnnotation;

public function getPackagesInPath
"function: getPackagesInPath
   This function takes a Path and a Program and returns a list of the
   names of the packages found in the Path."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  output list<Absyn.Path> paths;
algorithm
  paths := matchcontinue (inPath,inProgram)
    local
      Absyn.Class cdef;
      String str,res;
      Absyn.Path modelpath;
      Absyn.Program p;
    case (modelpath,p)
      equation
        cdef = getPathedClassInProgram(modelpath, p);
      then getPackagesInClass(modelpath, p, cdef);
    else {};
  end matchcontinue;
end getPackagesInPath;

public function getTopPackages
"function: getTopPackages
   This function takes a Path and a Program and returns a list of the
   names of the packages found in the Path."
  input Absyn.Program p;
  output list<Absyn.Path> paths;
algorithm
  paths := List.map(getTopPackagesInProgram(p),Absyn.makeIdentPathFromString);
end getTopPackages;

protected function getTopPackagesInProgram
"function: getTopPackagesInProgram
  Helper function to getTopPackages."
  input Absyn.Program inProgram;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inProgram)
    local
      list<String> res;
      String id;
      list<Absyn.Class> rest;
      Absyn.Within w;
      Absyn.TimeStamp ts;

    case Absyn.PROGRAM(classes = {}) then {};
    case (Absyn.PROGRAM(classes = (Absyn.CLASS(name = id,restriction = Absyn.R_PACKAGE()) :: rest),within_ = w,globalBuildTimes=ts))
      equation
        res = getTopPackagesInProgram(Absyn.PROGRAM(rest,w,ts));
      then
        (id :: res);
    case (Absyn.PROGRAM(classes = (_ :: rest),within_ = w,globalBuildTimes=ts))
      equation
        res = getTopPackagesInProgram(Absyn.PROGRAM(rest,w,ts));
      then
        res;
  end matchcontinue;
end getTopPackagesInProgram;

protected function getPackagesInClass
"function: getPackagesInClass
   This function takes a Class definition and a Path identifying
   the class. It returns a string containing comma separated package
   names found in the class definition."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Absyn.Class inClass;
  output list<Absyn.Path> outString;
algorithm
  outString:=
  match (inPath,inProgram,inClass)
    local
      list<String> strlist;
      String res;
      list<Absyn.ClassPart> parts;
      Option<String> cmt;
      Absyn.Path inmodel,path;
      Absyn.Program p;
    /* a class with parts */
    case (_,_,Absyn.CLASS(body = Absyn.PARTS(classParts = parts,comment = cmt)))
      equation
        strlist = getPackagesInParts(parts);
      then List.map(strlist,Absyn.makeIdentPathFromString);
    /* an extended class with parts: model extends M end M; */
    case (_,_,Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)))
      equation
        strlist = getPackagesInParts(parts);
      then List.map(strlist,Absyn.makeIdentPathFromString);
     /* a derived class */
    case (inmodel,p,Absyn.CLASS(body = Absyn.DERIVED(typeSpec=Absyn.TPATH(path,_))))
      equation
        /* adrpo: 2009-10-27 we shouldn't look into derived!
        (cdef,newpath) = lookupClassdef(path, inmodel, p);
        res = getPackagesInClass(newpath, p, cdef);
        */
      then {};
  end match;
end getPackagesInClass;

protected function getPackagesInParts
"function: getPackagesInParts
  Helper function to getPackagesInClass."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<String> l1,l2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> rest;
    case {} then {};
    case ((Absyn.PUBLIC(contents = elts) :: rest))
      equation
        l1 = getPackagesInElts(elts);
        l2 = getPackagesInParts(rest);
        res = listAppend(l1, l2);
      then
        res;
    case ((_ :: rest))
      equation
        res = getPackagesInParts(rest);
      then
        res;
  end matchcontinue;
end getPackagesInParts;

protected function getPackagesInElts
"function: getPackagesInElts
  Helper function to getPackagesInParts."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inAbsynElementItemLst)
    local
      list<String> res;
      String id;
      list<Absyn.ElementItem> rest;
    case {} then {};
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = Absyn.CLASS(name = id,restriction = Absyn.R_PACKAGE())),constrainClass = NONE())) :: rest))
      equation
        res = getPackagesInElts(rest);
      then
        (id :: res);
    case ((_ :: rest))
      equation
        res = getPackagesInElts(rest);
      then
        res;
  end matchcontinue;
end getPackagesInElts;

public function getClassnamesInPath
"function: getClassnamesInPath
  Return a comma separated list of classes in a given Path."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Boolean inShowProtected;
  output list<Absyn.Path> paths;
algorithm
  paths :=
  matchcontinue (inPath,inProgram,inShowProtected)
    local
      Absyn.Class cdef;
      String str,res;
      Absyn.Path modelpath;
      Absyn.Program p;
      Boolean b;
    case (modelpath,p,b)
      equation
        cdef = getPathedClassInProgram(modelpath, p);
      then getClassnamesInClass(modelpath, p, cdef, b);
    else {};
  end matchcontinue;
end getClassnamesInPath;

public function getTopClassnames
"function: getTopClassnames
   This function takes a Path and a Program and returns a list of
   the names of the packages found at the top scope."
  input Absyn.Program p;
  output list<Absyn.Path> paths;
algorithm
  paths := List.map(getTopClassnamesInProgram(p),Absyn.makeIdentPathFromString);
end getTopClassnames;

public function getTopClassnamesInProgram
"function: getTopClassnamesInProgram
  Helper function to getTopClassnames."
  input Absyn.Program inProgram;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inProgram)
    local
      list<String> res;
      String id;
      list<Absyn.Class> rest;
      Absyn.Within w;
      Absyn.TimeStamp ts;

    case Absyn.PROGRAM(classes = {}) then {};
    case (Absyn.PROGRAM(classes = (Absyn.CLASS(name = id) :: rest),within_ = w,globalBuildTimes=ts))
      equation
        res = getTopClassnamesInProgram(Absyn.PROGRAM(rest,w,ts));
      then
        (id :: res);
    case (Absyn.PROGRAM(classes = (_ :: rest),within_ = w,globalBuildTimes=ts))
      equation
        res = getTopClassnamesInProgram(Absyn.PROGRAM(rest,w,ts));
      then
        res;
  end matchcontinue;
end getTopClassnamesInProgram;

protected function getTopQualifiedClassnames
 "Takes a Program and returns a list of the fully top_qualified
 names of the packages found at the top scope.
 Example:
  within X.Y class Z -> X.Y.Z;"
  input Absyn.Program inProgram;
  output list<Absyn.Path> outStringLst;
algorithm
  outStringLst := matchcontinue (inProgram)
    local
      String str_path,id;
      list<Absyn.Path> res,result;
      list<Absyn.Class> rest;
      Absyn.Within w;
      Absyn.TimeStamp ts;
      Absyn.Path p;

    case Absyn.PROGRAM(classes = {}) then {};
    case (Absyn.PROGRAM(classes = (Absyn.CLASS(name = id) :: rest),within_ = w, globalBuildTimes=ts))
      equation
        p = Absyn.joinWithinPath(w, Absyn.IDENT(id));
        res = getTopQualifiedClassnames(Absyn.PROGRAM(rest,w,ts));
      then p::res;
    case (Absyn.PROGRAM(classes = (_ :: rest),within_ = w, globalBuildTimes=ts))
      equation
        res = getTopQualifiedClassnames(Absyn.PROGRAM(rest,w,ts));
      then
        res;
  end matchcontinue;
end getTopQualifiedClassnames;

protected function getClassnamesInClass
"function: getClassnamesInClass
   This function takes a `Class\' definition and a Path identifying the
   class.
   It returns a string containing comma separated package names found
   in the class definition.
   The list also contains proctected classes if inShowProtected is true."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Absyn.Class inClass;
  input Boolean inShowProtected;
  output list<Absyn.Path> paths;
algorithm
  paths := match (inPath,inProgram,inClass,inShowProtected)
    local
      list<String> strlist;
      String res;
      list<Absyn.ClassPart> parts;
      Absyn.Path inmodel,path;
      Absyn.Program p;
      Boolean b;
    /* a class with parts */
    case (_,_,Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),b)
      equation
        strlist = getClassnamesInParts(parts,b);
      then List.map(strlist,Absyn.makeIdentPathFromString);
    /* an extended class with parts: model extends M end M; */
    case (_,_,Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)),b)
      equation
        strlist = getClassnamesInParts(parts,b);
      then List.map(strlist,Absyn.makeIdentPathFromString);
    /* a derived class */
    case (inmodel,p,Absyn.CLASS(body = Absyn.DERIVED(typeSpec=Absyn.TPATH(path, _))),b)
      equation
        /* adrpo 2009-10-27: we sholdn't dive into derived classes!
        (cdef,newpath) = lookupClassdef(path, inmodel, p);
        res = getClassnamesInClass(newpath, p, cdef);
        */
      then {};
  end match;
end getClassnamesInClass;

public function getClassnamesInParts
"function: getClassnamesInParts
  Helper function to getClassnamesInClass."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Boolean inShowProtected;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inAbsynClassPartLst,inShowProtected)
    local
      list<String> l1,l2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> rest;
      Boolean b;
    case ({},b) then {};
    case ((Absyn.PUBLIC(contents = elts) :: rest),b)
      equation
        l1 = getClassnamesInElts(elts);
        l2 = getClassnamesInParts(rest,b);
        res = listAppend(l1, l2);
      then
        res;
    /* adeas31 2012-01-25: Also check the protected sections. */
    case ((Absyn.PROTECTED(contents = elts) :: rest), true)
      equation
        l1 = getClassnamesInElts(elts);
        l2 = getClassnamesInParts(rest,true);
        res = listAppend(l1, l2);
      then
        res;
    case ((_ :: rest),b)
      equation
        res = getClassnamesInParts(rest,b);
      then
        res;
  end matchcontinue;
end getClassnamesInParts;

public function getClassnamesInElts
"function: getClassnamesInElts
  Helper function to getClassnamesInParts."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inAbsynElementItemLst)
    local
      list<String> res;
      String id;
      list<Absyn.ElementItem> rest;

    case {} then {};

    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ =
                 Absyn.CLASS(body = Absyn.CLASS_EXTENDS(baseClassName = id))),constrainClass = NONE())) :: rest))
      equation
        res = getClassnamesInElts(rest);
      then
        (id :: res);

    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ =
                 Absyn.CLASS(name = id)),constrainClass = NONE())) :: rest))
      equation
        res = getClassnamesInElts(rest);
      then
        (id :: res);

    case ((_ :: rest))
      equation
        res = getClassnamesInElts(rest);
      then
        res;
  end matchcontinue;
end getClassnamesInElts;

protected function getBaseClasses
"function: getBaseClasses
   This function gets all base classes of a class, NOT Recursive.
   It uses the environment to get the fully qualified names of the classes."
  input Absyn.Class inClass;
  input Env.Env inEnv;
  output list<Absyn.ComponentRef> outAbsynComponentRefLst;
algorithm
  outAbsynComponentRefLst := matchcontinue (inClass,inEnv)
    local
      list<Absyn.ComponentRef> res;
      list<Absyn.ClassPart> parts;
      list<Env.Frame> env;
      Absyn.Path tp;
      String baseClassName;
      Option<String> comment;
      list<Absyn.ElementArg> modifications;
      Env.Env cenv;
      Absyn.Path envpath,p1;
      String tpname,str;
      Absyn.ComponentRef cref;
      SCode.Element c;
      Env.Cache cache;

    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),env)
      equation
        res = getBaseClassesFromParts(parts, env);
      then
        res;

    // adrpo: handle the case for model extends baseClassName end baseClassName;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(baseClassName, modifications, comment, parts = parts)),env)
      equation
        (cache,c,cenv) = Lookup.lookupClass(Env.emptyCache(), env, Absyn.IDENT(baseClassName), true);
        SOME(envpath) = Env.getEnvPath(cenv);
        p1 = Absyn.joinPaths(envpath, Absyn.IDENT(baseClassName));
        cref = Absyn.pathToCref(p1);
        str = Absyn.pathString(p1);
        res = getBaseClassesFromParts(parts, env);
      then cref::res;

    case (Absyn.CLASS(body = Absyn.DERIVED(typeSpec = Absyn.TPATH(tp,_))),env)
      equation
        (cache,c,cenv) = Lookup.lookupClass(Env.emptyCache(), env, tp, true);
        SOME(envpath) = Env.getEnvPath(cenv);
        tpname = Absyn.pathLastIdent(tp);
        p1 = Absyn.joinPaths(envpath, Absyn.IDENT(tpname));
        cref = Absyn.pathToCref(p1);
        // str = Absyn.pathString(p1);
      then {cref};

    case (Absyn.CLASS(body = Absyn.DERIVED(typeSpec=Absyn.TPATH(tp,_))),env)
      equation
        (cache,c,cenv) = Lookup.lookupClass(Env.emptyCache(), env, tp, true);
        NONE() = Env.getEnvPath(cenv);
        cref = Absyn.pathToCref(tp);
        then {cref};

    case (_,_) then {};

  end matchcontinue;
end getBaseClasses;

protected function getBaseClassesFromParts
"function: getBaseClassesFromParts
  Helper function to getBaseClasses."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Env.Env inEnv;
  output list<Absyn.ComponentRef> outAbsynComponentRefLst;
algorithm
  outAbsynComponentRefLst := matchcontinue (inAbsynClassPartLst,inEnv)
    local
      list<Absyn.ComponentRef> c1,c2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> rest;
      list<Env.Frame> env;
    
    case ((Absyn.PUBLIC(contents = elts) :: rest),env)
      equation
        c1 = getBaseClassesFromElts(elts, env);
        c2 = getBaseClassesFromParts(rest, env);
        res = listAppend(c1, c2);
      then
        res;
    
    case ((_ :: rest),env)
      equation
        res = getBaseClassesFromParts(rest, env);
      then
        res;
    
    case ({},env) then {};

  end matchcontinue;
end getBaseClassesFromParts;

protected function getBaseClassesFromElts
"function: getBaseClassesFromElts
  Helper function to getBaseClassesFromParts."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Env.Env inEnv;
  output list<Absyn.ComponentRef> outAbsynComponentRefLst;
algorithm
  outAbsynComponentRefLst := matchcontinue (inAbsynElementItemLst,inEnv)
    local
      list<Env.Frame> env,env_1;
      list<Absyn.ComponentRef> cl;
      SCode.Element c;
      Absyn.Path envpath,p_1,path;
      String tpname;
      Absyn.ComponentRef cref;
      list<Absyn.ElementItem> rest;

    case ({},env) then {};

    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.EXTENDS(path = path))) :: rest),env)
      equation
        cl = getBaseClassesFromElts(rest, env) "Inherited class is defined inside package" ;
        (_,c,env_1) = Lookup.lookupClass(Env.emptyCache(),env, path, true);
        SOME(envpath) = Env.getEnvPath(env_1);
        tpname = Absyn.pathLastIdent(path);
        p_1 = Absyn.joinPaths(envpath, Absyn.IDENT(tpname));
        cref = Absyn.pathToCref(p_1);
      then
        (cref :: cl);

    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.EXTENDS(path = path))) :: rest),env)
      equation
        cl = getBaseClassesFromElts(rest, env) "Inherited class defined on top level scope" ;
        (_,c,env_1) = Lookup.lookupClass(Env.emptyCache(),env, path, true);
        NONE() = Env.getEnvPath(env_1);
        cref = Absyn.pathToCref(path);
      then
        (cref :: cl);

    case ((_ :: rest),env)
      equation
        cl = getBaseClassesFromElts(rest, env);
      then
        cl;

  end matchcontinue;
end getBaseClassesFromElts;

protected function countBaseClasses
"function: countBaseClasses
   This function counts the number of base classes of a class"
  input Absyn.Class inClass;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inClass)
    local
      Integer res;
      list<Absyn.ClassPart> parts;

    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)))
      equation
        res = countBaseClassesFromParts(parts);
      then
        res;

    // adrpo: add the case for model extends baseClassName extends SomeElseClass; end baseClassName;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(baseClassName = _, parts = parts)))
      equation
        res = countBaseClassesFromParts(parts);
      then
        res + 1;

    case (Absyn.CLASS(body = Absyn.DERIVED(typeSpec=_))) then 1;
    
    case (_) then 0;

  end matchcontinue;
end countBaseClasses;

protected function countBaseClassesFromParts
"function: countBaseClassesFromParts
  Helper function to countBaseClasses."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inAbsynClassPartLst)
    local
      Integer c1,c2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> rest;
    
    case ((Absyn.PUBLIC(contents = elts) :: rest))
      equation
        c1 = countBaseClassesFromElts(elts);
        c2 = countBaseClassesFromParts(rest);
      then
        c1 + c2;
    
    case ((_ :: rest))
      equation
        res = countBaseClassesFromParts(rest);
      then
        res;
    
    case ({}) then 0;

  end matchcontinue;
end countBaseClassesFromParts;

protected function countBaseClassesFromElts
"function: countBaseClassesFromElts
  Helper function to countBaseClassesFromParts."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inAbsynElementItemLst)
    local
      Integer cl;
      Absyn.Path path;
      list<Absyn.ElementItem> rest;

    case ({}) then 0;

    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.EXTENDS(path = path))) :: rest))
      equation
        cl = countBaseClassesFromElts(rest) "Inherited class" ;
      then
        cl + 1;

    case ((_ :: rest))
      equation
        cl = countBaseClassesFromElts(rest);
      then
        cl;

  end matchcontinue;
end countBaseClassesFromElts;

protected function getAnnotationInClass
  "Helper function to getIconAnnotation."
  input Absyn.Class inClass;
  input AnnotationType annotationType;
  input Absyn.Program inProgram;
  input Absyn.Path inModelPath;
  output String annotationStr;
algorithm
  annotationStr := match(inClass, annotationType, inProgram, inModelPath)
    local
      list<Absyn.ElementArg> annlst;
      String s1,  str;
      list<Absyn.ClassPart> parts;
      Absyn.Program p;
      Absyn.Path path;
    
    // normal class definitions made of parts
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)), _, p, path)
      equation
        annlst = getAnnotationFromParts(parts, annotationType);
        s1 = getAnnotationStr(annlst, annotationType, inClass, p, path);
        str = stringAppendList({"{", s1, "}"});
      then
        str;
    
    // adrpo: add the case for model extends name annotation ... end name;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)), _, p, path)
      equation
        annlst = getAnnotationFromParts(parts, annotationType);
        s1 = getAnnotationStr(annlst, annotationType, inClass, p, path);
        str = stringAppendList({"{", s1, "}"});
      then
        str;
    
    // short class definition
    case (Absyn.CLASS(body = Absyn.DERIVED(comment = SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION(annlst)),_)))), _, p, path) 
      equation
        s1 = getAnnotationStr(annlst, annotationType, inClass, p, path);
        str = stringAppendList({"{", s1, "}"});
      then
        str;
  end match;
end getAnnotationInClass;

protected function getAnnotationFromParts
"function: getAnnotationFromParts
  Helper function to getAnnotationInClass."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input AnnotationType annotationType;
  output list<Absyn.ElementArg> outAbsynElementArgLst;
algorithm
  outAbsynElementArgLst := matchcontinue (inAbsynClassPartLst, annotationType)
    local
      list<Absyn.ElementArg> res1, res2, res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> rest;
      list<Absyn.EquationItem> eqns;
      list<Absyn.AlgorithmItem> algs;
    
    case ({}, _) then {};
    
    case (Absyn.PUBLIC(contents = elts) :: rest, annotationType) 
      equation 
        res1 = getAnnotationFromElts(elts, annotationType);
        res2 = getAnnotationFromParts(rest, annotationType);
        res = listAppend(res1, res2);
      then 
        res;
    
    case (Absyn.PROTECTED(contents = elts) :: rest, annotationType) 
      equation 
        res1 = getAnnotationFromElts(elts, annotationType);
        res2 = getAnnotationFromParts(rest, annotationType);
        res = listAppend(res1, res2);
      then 
        res;
    
    case (Absyn.EQUATIONS(contents = eqns) :: rest, annotationType) 
      equation 
        res1 = getAnnotationFromEqns(eqns, annotationType);
        res2 = getAnnotationFromParts(rest, annotationType);
        res = listAppend(res1, res2);
      then 
        res;
    
    case (Absyn.INITIALEQUATIONS(contents = eqns) :: rest, annotationType) 
      equation 
        res1 = getAnnotationFromEqns(eqns, annotationType);
        res2 = getAnnotationFromParts(rest, annotationType);
        res = listAppend(res1, res2);
      then 
        res;
    
    case (Absyn.ALGORITHMS(contents = algs) :: rest, annotationType) 
      equation 
        res1 = getAnnotationFromAlgs(algs, annotationType);
        res2 = getAnnotationFromParts(rest, annotationType);
        res = listAppend(res1, res2);
      then 
        res;
    
    case (Absyn.INITIALALGORITHMS(contents = algs) :: rest, _) 
      equation
        res1 = getAnnotationFromAlgs(algs, annotationType);
        res2 = getAnnotationFromParts(rest, annotationType);
        res = listAppend(res1, res2);
      then
        res;
    
    case (_ :: rest, _) 
      equation 
        res = getAnnotationFromParts(rest, annotationType);
      then 
        res;
  end matchcontinue;
end getAnnotationFromParts;

protected function getAnnotationFromElts
"function: getAnnotationFromElts
  Helper function to getAnnotationFromParts."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input AnnotationType annotationType;
  output list<Absyn.ElementArg> outAbsynElementArgLst;
algorithm
  outAbsynElementArgLst := matchcontinue (inAbsynElementItemLst, annotationType)
    local
      list<Absyn.ElementArg> lst,res;
      list<Absyn.ElementItem> rest;
    
    // handle empty
    case ({}, _) then {};
    
    case (Absyn.ANNOTATIONITEM(annotation_ = Absyn.ANNOTATION(elementArgs = lst)) :: rest, _)
      equation 
        containAnnotation(lst, annotationType);
      then 
        lst;
    
    case (_ :: rest, _)
      equation 
        res = getAnnotationFromElts(rest, annotationType);
      then 
        res;
  end matchcontinue;
end getAnnotationFromElts;

protected function isAnnotationType
  "Checks if the name of an annotation matches the annotation type given."
  input String annotationStr;
  input AnnotationType annotationType;
algorithm
  _ := match(annotationStr, annotationType)
    case ("Icon", ICON_ANNOTATION()) then ();
    case ("Diagram", DIAGRAM_ANNOTATION()) then ();
  end match;
end isAnnotationType;

protected function containAnnotation
"function: containAnnotation
  Helper function to getAnnotationFromElts."
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input AnnotationType annotationType;
algorithm
  _ := matchcontinue (inAbsynElementArgLst, annotationType)
    local 
      list<Absyn.ElementArg> lst;
      String ann_name;
    
    case ((Absyn.MODIFICATION(componentRef = Absyn.CREF_IDENT(name = ann_name)) :: _), _) 
      equation
        isAnnotationType(ann_name, annotationType);
      then 
        ();
    
    case ((_ :: lst), _)
      equation
        containAnnotation(lst, annotationType);
      then
        ();
  end matchcontinue;
end containAnnotation;

protected function getAnnotationFromEqns
"function: getAnnotationFromEqns
  Helper function to getAnnotationFromParts."
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  input AnnotationType annotationType;
  output list<Absyn.ElementArg> outAbsynElementArgLst;
algorithm
  outAbsynElementArgLst := matchcontinue (inAbsynEquationItemLst, annotationType)
    local
      list<Absyn.ElementArg> lst,res;
      list<Absyn.EquationItem> rest;
    
    case ({}, _) then {};
    
    case ((Absyn.EQUATIONITEMANN(annotation_ = Absyn.ANNOTATION(elementArgs = lst)) :: rest), _)
      equation
        containAnnotation(lst, annotationType);
      then
        lst;
    
    case ((_ :: rest), _)
      equation
        res = getAnnotationFromEqns(rest, annotationType);
      then
        res;
  end matchcontinue;
end getAnnotationFromEqns;

protected function getAnnotationFromAlgs
"function: getIconAnnotationFromAlgs
  Helper function to getIconAnnotationFromParts"
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  input AnnotationType annotationType;
  output list<Absyn.ElementArg> outAbsynElementArgLst;
algorithm
  outAbsynElementArgLst := matchcontinue (inAbsynAlgorithmItemLst, annotationType)
    local
      list<Absyn.ElementArg> lst,res;
      list<Absyn.AlgorithmItem> rest;
    
    case ({}, _) then {};
    
    case ((Absyn.ALGORITHMITEMANN(annotation_ = Absyn.ANNOTATION(elementArgs = lst)) :: rest), _)
      equation
        containAnnotation(lst, annotationType);
      then
        lst;
    
    case ((_ :: rest), _)
      equation
        res = getAnnotationFromAlgs(rest, annotationType);
      then
        res;
  end matchcontinue;
end getAnnotationFromAlgs;

protected function getAnnotationStr
"function: getIconAnnotationStr
  Helper function to getIconAnnotationInClass."
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input AnnotationType annotationType;
  input Absyn.Class inClass;
  input Absyn.Program inProgram;
  input Absyn.Path inModelPath;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynElementArgLst, annotationType, inClass, inProgram, inModelPath)
    local
      String str, ann_name;
      Absyn.ElementArg ann;
      Option<Absyn.Modification> mod;
      list<Absyn.ElementArg> xs;
      Absyn.Program fullProgram;
      Absyn.Class c;
      Absyn.Path p;
    
    case (((ann as Absyn.MODIFICATION(componentRef = Absyn.CREF_IDENT(name = ann_name),modification = mod)) :: _), _, c, fullProgram, p)
      equation
        isAnnotationType(ann_name, annotationType);
        str = getAnnotationString(Absyn.ANNOTATION({ann}), c, fullProgram, p);
      then
        str;
    
    case ((_ :: xs), _, c, fullProgram, p)
      equation
        str = getAnnotationStr(xs, annotationType, c, fullProgram, p);
      then
        str;
  
  end matchcontinue;
end getAnnotationStr;

public function getNamedAnnotationInClass
"function: getNamedAnnotationInClass
  Retrieve the documentation annotation as a
  string from the class passed as argument."
  input Absyn.Class inClass;
  input Absyn.Ident id;
  input ModFunc f;
  output Option<TypeA> outString;
  replaceable type TypeA subtypeof Any;
  partial function ModFunc
    input Option<Absyn.Modification> mod;
    output TypeA docStr;
  end ModFunc;
algorithm
  outString := matchcontinue (inClass,id,f)
    local
      TypeA str,res;
      list<Absyn.ClassPart> parts;
      list<Absyn.ElementArg> annlst;

    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),id,f)
      equation
        SOME(str) = getNamedAnnotationInParts(parts,id,f);
      then
        SOME(str);

    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)),id,f)
      equation
        SOME(str) = getNamedAnnotationInParts(parts,id,f);
      then
        SOME(str);

    case (Absyn.CLASS(body = Absyn.DERIVED(comment = SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION(annlst)),_)))),id,f)
      equation
        SOME(res) = getNamedAnnotationStr(annlst,id,f);
      then
        SOME(res);

    case (Absyn.CLASS(body = Absyn.ENUMERATION(comment = SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION(annlst)),_)))),id,f)
      equation
        SOME(res) = getNamedAnnotationStr(annlst,id,f);
      then
        SOME(res);

    case (Absyn.CLASS(body = Absyn.OVERLOAD(comment = SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION(annlst)),_)))),id,f)
      equation
        SOME(res) = getNamedAnnotationStr(annlst,id,f);
      then
        SOME(res);

    else NONE();

  end matchcontinue;
end getNamedAnnotationInClass;

protected function getNamedAnnotationInParts
"function: getNamedAnnotationInParts
  Retrieve the into annotation from class parts list passed as argument."
  input list<Absyn.ClassPart> inAbsynClassPartsLst;
  input Absyn.Ident id;
  input ModFunc f;
  output Option<TypeA> outString;
  replaceable type TypeA subtypeof Any;
  partial function ModFunc
    input Option<Absyn.Modification> mod;
    output TypeA docStr;
  end ModFunc;
algorithm
  outString := matchcontinue (inAbsynClassPartsLst,id,f)
    local
      TypeA str;
      list<Absyn.ElementItem> contents;
      list<Absyn.ClassPart> rest;
      list<Absyn.EquationItem> eqItems;
      list<Absyn.AlgorithmItem> alItems;
      list<Absyn.ElementArg> elArgs;
    
    case ({},_,_) then NONE();
    
    // search in public
    case (Absyn.PUBLIC(contents)::rest, id, f)
      equation
        SOME(str) = getNamedAnnotationInElItems(contents,id,f);
      then
        SOME(str);
    
    // search in protected
    case (Absyn.PROTECTED(contents)::rest, id, f)
      equation
        SOME(str) = getNamedAnnotationInElItems(contents,id,f);
      then
        SOME(str);

    // search in equations
    case (Absyn.EQUATIONS(eqItems)::rest, id, f)
      equation
        SOME(str) = getNamedAnnotationInEquItems(eqItems,id,f);
      then
        SOME(str);
    
    // search in intial equations
    case (Absyn.INITIALEQUATIONS(eqItems)::rest, id, f)
      equation
        SOME(str) = getNamedAnnotationInEquItems(eqItems,id,f);
      then
        SOME(str);

    // search in algorithms
    case (Absyn.ALGORITHMS(alItems)::rest, id, f)
      equation
        SOME(str) = getNamedAnnotationInAlgItems(alItems,id,f);
      then
        SOME(str);
    
    // search in initial algorithms
    case (Absyn.INITIALALGORITHMS(alItems)::rest, id, f)
      equation
        SOME(str) = getNamedAnnotationInAlgItems(alItems,id,f);
      then
        SOME(str);
    
    // search in exernal declarations
    case (Absyn.EXTERNAL(annotation_ = SOME(Absyn.ANNOTATION(elArgs)))::rest, id, f)
      equation
        SOME(str) = getNamedAnnotationStr(elArgs,id,f);
      then
        SOME(str);

    // try next
    case (_ :: rest,id,f) then getNamedAnnotationInParts(rest,id,f);
  end matchcontinue;
end getNamedAnnotationInParts;


protected function getNamedAnnotationInElItems
"function: getNamedAnnotationInElItems
  Retrieve the into annotation from an
  element item list passed as argument."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Ident id;
  input ModFunc f;
  output Option<TypeA> outString;
  replaceable type TypeA subtypeof Any;
  partial function ModFunc
    input Option<Absyn.Modification> mod;
    output TypeA docStr;
  end ModFunc;
algorithm
  outString := matchcontinue (inAbsynElementItemLst,id,f)
    local
      TypeA s1,str;
      list<Absyn.ElementArg> annlst;
      list<Absyn.ElementItem> xs;
    
    case ({},_,_) then NONE();
    
    case ((Absyn.ANNOTATIONITEM(annotation_ = Absyn.ANNOTATION(elementArgs = annlst)) :: _),id,f)
      equation
        SOME(s1) = getNamedAnnotationStr(annlst,id,f);
      then
        SOME(s1);
    
    case ((_ :: xs),id,f) then getNamedAnnotationInElItems(xs,id,f);
  end matchcontinue;
end getNamedAnnotationInElItems;

protected function getNamedAnnotationInEquItems
"@author: adrpo
  Retrieve the into annotation from an
  equation item list passed as argument."
  input list<Absyn.EquationItem> inAbsynEquItemLst;
  input Absyn.Ident id;
  input ModFunc f;
  output Option<TypeA> outString;
  replaceable type TypeA subtypeof Any;
  partial function ModFunc
    input Option<Absyn.Modification> mod;
    output TypeA docStr;
  end ModFunc;
algorithm
  outString := matchcontinue (inAbsynEquItemLst,id,f)
    local
      TypeA s1,str;
      list<Absyn.ElementArg> annlst;
      list<Absyn.EquationItem> xs;
    
    case ({},_,_) then NONE();
    
    case (Absyn.EQUATIONITEMANN(annotation_ = Absyn.ANNOTATION(elementArgs = annlst)) :: _, id, f)
      equation
        SOME(s1) = getNamedAnnotationStr(annlst,id,f);
      then
        SOME(s1);
    
    case ((_ :: xs),id,f) then getNamedAnnotationInEquItems(xs,id,f);
  end matchcontinue;
end getNamedAnnotationInEquItems;

protected function getNamedAnnotationInAlgItems
"@author: adrpo
  Retrieve the into annotation from an
  algorithm item list passed as argument."
  input list<Absyn.AlgorithmItem> inAbsynAlgItemLst;
  input Absyn.Ident id;
  input ModFunc f;
  output Option<TypeA> outString;
  replaceable type TypeA subtypeof Any;
  partial function ModFunc
    input Option<Absyn.Modification> mod;
    output TypeA docStr;
  end ModFunc;
algorithm
  outString := matchcontinue (inAbsynAlgItemLst,id,f)
    local
      TypeA s1,str;
      list<Absyn.ElementArg> annlst;
      list<Absyn.AlgorithmItem> xs;
    
    case ({},_,_) then NONE();
    
    case (Absyn.ALGORITHMITEMANN(annotation_ = Absyn.ANNOTATION(elementArgs = annlst)) :: _, id, f)
      equation
        SOME(s1) = getNamedAnnotationStr(annlst,id,f);
      then
        SOME(s1);
    
    case ((_ :: xs),id,f) then getNamedAnnotationInAlgItems(xs,id,f);
  end matchcontinue;
end getNamedAnnotationInAlgItems;

protected function getDefaultComponentName
"function getDefaultComponentName
  Returns the default component name of a class.
  This is annotated with the annotation:
  annotation(defaultComponentName=\"name\"); in the class definition"
  input Absyn.Path className;
  input Absyn.Program p;
  output String compName;
algorithm
  compName := match(className,p)
    case(className,p) 
      equation
        compName = getNamedAnnotation(className,p,"defaultComponentName",SOME("{}"),getDefaultComponentNameModStr);
      then 
        compName;
  end match;
end getDefaultComponentName;

protected function getDefaultComponentNameModStr
"function getDefaultComponentNameModStr
  Extractor function for defaultComponentName modifier"
  input Option<Absyn.Modification> mod;
  output String docStr;
algorithm
  docStr := matchcontinue(mod)
    local Absyn.Exp e;
    
    case(SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=e)))) 
      equation
        docStr = Dump.printExpStr(e);
      then 
        docStr;
    
    case(mod) then "";

  end matchcontinue;
end getDefaultComponentNameModStr;

protected function getDefaultComponentPrefixes
"function getDefaultComponentPrefixes
  Returns the default component prefixes of a class.
  This is annotated with the annotation
    annotation(defaultComponentPrefixes=\"<prefixes>\");
  in the class definition"
  input Absyn.Path className;
  input Absyn.Program p;
  output String compName;
algorithm
  compName := match(className,p)
    case(className,p) 
      equation
        compName = getNamedAnnotation(className,p,"defaultComponentPrefixes",SOME("{}"),getDefaultComponentPrefixesModStr);
      then 
        compName;
  end match;
end getDefaultComponentPrefixes;

protected function getNamedAnnotationStr
"function: getNamedAnnotationStr
  Helper function to getNamedAnnotationInElementitemlist."
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input Absyn.Ident id;
  input ModFunc f;
  output Option<TypeA> outString;
  replaceable type TypeA subtypeof Any;
  partial function ModFunc
    input Option<Absyn.Modification> mod;
    output TypeA docStr;
  end ModFunc;
algorithm
  outString := matchcontinue (inAbsynElementArgLst,id,f)
    local
      TypeA str;
      Absyn.ElementArg ann;
      Option<Absyn.Modification> mod;
      list<Absyn.ElementArg> xs;
      Absyn.Ident id1,id2;
    
    case (((ann as Absyn.MODIFICATION(componentRef = Absyn.CREF_IDENT(name = id1),modification = mod)) :: _),id2,f)
      equation
        true = stringEq(id1, id2);
        str = f(mod);
      then
        SOME(str);
    
    case ((_ :: xs),id,f) then getNamedAnnotationStr(xs,id,f);
  end matchcontinue;
end getNamedAnnotationStr;

public function getAnnotationValue
  input Option<Absyn.Modification> mod;
  output String str;
algorithm
  str := matchcontinue (mod)
    local 
      String s;
      Absyn.Exp exp;

    case (SOME(Absyn.CLASSMOD(elementArgLst = {}, eqMod=Absyn.EQMOD(exp=exp))))
      equation
        s = Dump.printExpStr(exp);
        s = stringAppendList({"{", s, "}"});
      then
        s;
    
    // adrpo: empty if no value
    case (_) then "{}";
  end matchcontinue;
end getAnnotationValue;

public function getAnnotationExp
  input Option<Absyn.Modification> mod;
  output Absyn.Exp exp;
algorithm
  SOME(Absyn.CLASSMOD(elementArgLst = {}, eqMod=Absyn.EQMOD(exp=exp))) := mod;
end getAnnotationExp;

public function getAnnotationStringValueOrFail
  input Option<Absyn.Modification> mod;
  output String str;
algorithm
  str := match (mod)
    local 
      String s;

    case (SOME(Absyn.CLASSMOD(elementArgLst = {}, eqMod=Absyn.EQMOD(exp=Absyn.STRING(s))))) then s;
  end match;
end getAnnotationStringValueOrFail;

public function getExperimentAnnotationString
"@author: adrpo
 gets the experiment annotation values"
  input Option<Absyn.Modification> mod;
  output String experimentStr;
algorithm
  experimentStr := match (mod)
    local 
      list<Absyn.ElementArg> arglst;
      list<String> strs;
      String s;

    case (SOME(Absyn.CLASSMOD(elementArgLst = arglst)))
      equation
        strs = getExperimentAnnotationString2(arglst);
        s = stringDelimitList(strs,",");
        s = stringAppendList({"{", s, "}"});
      then 
        s;
    
  end match;
end getExperimentAnnotationString;

protected function getExperimentAnnotationString2
"function getExperimentAnnotationString2
  Helper function to getExperimentAnnotationString"
  input list<Absyn.ElementArg> eltArgs;
  output list<String> strs;
algorithm
  strs := matchcontinue (eltArgs)
    local
      Absyn.Exp exp;
      list<Absyn.ElementArg> xs;
      String name, s;
      list<String> ss;

    case ({}) then {};

    case (Absyn.MODIFICATION(componentRef = Absyn.CREF_IDENT(name = name),
          modification=SOME(Absyn.CLASSMOD(eqMod=Absyn.EQMOD(exp=exp))))::xs)
      equation
          s =  name +& "=" +& Dump.printExpStr(exp);
          ss = getExperimentAnnotationString2(xs);
      then s::ss;
    
    case (_::xs)
      equation
          ss = getExperimentAnnotationString2(xs);
      then ss;

    end matchcontinue;
end getExperimentAnnotationString2;

public function getDocumentationAnnotationString
  input Option<Absyn.Modification> mod;
  output tuple<String,String> docStr;
algorithm
  docStr := match (mod)
    local 
      list<Absyn.ElementArg> arglst;
      String info, revisions;
      String s;
      Boolean partialInst;
    case (SOME(Absyn.CLASSMOD(elementArgLst = arglst)))
      equation
        partialInst = System.getPartialInstantiation();
        System.setPartialInstantiation(true);
        info = getDocumentationAnnotationInfo(arglst);
        revisions = getDocumentationAnnotationRevision(arglst);
        System.setPartialInstantiation(partialInst);
      then ((info,revisions));
  end match;
end getDocumentationAnnotationString;

protected function getDocumentationAnnotationInfo
"function getDocumentationAnnotationInfo
  Helper function to getDocumentationAnnotationString"
  input list<Absyn.ElementArg> eltArgs;
  output String str;
algorithm
  str := matchcontinue (eltArgs)
    local
      Absyn.Exp exp;
      DAE.Exp dexp;
      list<Absyn.ElementArg> xs;
      String s;
      String ss;
    case ({}) then "";
    case (Absyn.MODIFICATION(componentRef = Absyn.CREF_IDENT(name = "info"),
          modification=SOME(Absyn.CLASSMOD(eqMod=Absyn.EQMOD(exp=exp))))::xs)
      equation
        (_,dexp,_) = Static.elabGraphicsExp(Env.emptyCache(), Env.emptyEnv, exp, true, Prefix.NOPRE(), Absyn.dummyInfo);
        (DAE.SCONST(s),_) = ExpressionSimplify.simplify(dexp);
        // ss = getDocumentationAnnotationInfo(xs);
      then s;
    case (_::xs)
      equation
        ss = getDocumentationAnnotationInfo(xs);
      then ss;
    end matchcontinue;
end getDocumentationAnnotationInfo;

protected function getDocumentationAnnotationRevision
"function getDocumentationAnnotationRevision
  Helper function to getDocumentationAnnotationString"
  input list<Absyn.ElementArg> eltArgs;
  output String str;
algorithm
  str := matchcontinue (eltArgs)
    local
      Absyn.Exp exp;
      list<Absyn.ElementArg> xs;
      String s;
      String ss;
      DAE.Exp dexp;
    case ({}) then "";
    case (Absyn.MODIFICATION(componentRef = Absyn.CREF_IDENT(name = "revisions"),
          modification=SOME(Absyn.CLASSMOD(eqMod=Absyn.EQMOD(exp=exp))))::xs)
      equation
        (_,dexp,_) = Static.elabGraphicsExp(Env.emptyCache(), Env.emptyEnv, exp, true, Prefix.NOPRE(), Absyn.dummyInfo);
        (DAE.SCONST(s),_) = ExpressionSimplify.simplify(dexp);
      then s;
    case (_::xs)
      equation
        ss = getDocumentationAnnotationRevision(xs);
      then ss;
    end matchcontinue;
end getDocumentationAnnotationRevision;

protected function getNthPublicConnectorStr
"function: getNthPublicConnectorStr
  Helper function to getNthConnector."
  input Absyn.Path inPath;
  input Absyn.Class inClass;
  input Absyn.Program inProgram;
  input Integer inInteger;
  output String outString;
  output Absyn.Path outPath;
algorithm
  (outString,outPath) := matchcontinue (inPath,inClass,inProgram,inInteger)
    local
      String str,a;
      Absyn.Path tp,modelpath;
      Boolean b,c,d;
      Absyn.Restriction e;
      list<Absyn.ElementItem> elt;
      list<Absyn.ClassPart> lst;
      Absyn.Program p;
      Integer n,c1,c2;
      Option<String> cmt;
      Absyn.Info file_info;

    case (modelpath,
      Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                  body = Absyn.PARTS(classParts = (Absyn.PUBLIC(contents = elt) :: lst))),p,n)
      equation
        (str,tp) = getNthConnectorStr(p, modelpath, elt, n);
      then
        (str,tp);

    /*
     * The rule above failed, count the number of connectors in the first
     * public list, subtract the number and try the rest of the list
     */
    case (modelpath,
      Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                  body = Absyn.PARTS(classParts = (Absyn.PUBLIC(contents = elt) :: lst),comment = cmt),info = file_info),p,n)
      equation
        c1 = countPublicConnectors(modelpath, p, Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},{Absyn.PUBLIC(elt)},cmt),file_info));
        c2 = n - c1;
        (str,tp) = getNthPublicConnectorStr(modelpath, Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info), p, c2);
      then
        (str,tp);

    case (modelpath,
      Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                  body = Absyn.PARTS(classParts = (_ :: lst),comment = cmt),info = file_info),p,n)
      equation
        (str,tp) = getNthPublicConnectorStr(modelpath, Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info), p, n);
      then
        (str,tp);

    /***********   adrpo: handle also the case of model extends name end name; **********/
    case (modelpath,
      Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                  body = Absyn.CLASS_EXTENDS(parts = (Absyn.PUBLIC(contents = elt) :: lst))),p,n)
      equation
        (str,tp) = getNthConnectorStr(p, modelpath, elt, n);
      then
        (str,tp);

    /*
     * The rule above failed, count the number of connectors in the first
     * public list, subtract the number and try the rest of the list
     */
    case (modelpath,
      Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                  body = Absyn.CLASS_EXTENDS(parts = (Absyn.PUBLIC(contents = elt) :: lst),comment = cmt),info = file_info),p,n)
      equation
        c1 = countPublicConnectors(modelpath, p, Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},{Absyn.PUBLIC(elt)},cmt),file_info));
        c2 = n - c1;
        (str,tp) = getNthPublicConnectorStr(modelpath, Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info), p, c2);
      then
        (str,tp);

    case (modelpath,
      Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                  body = Absyn.CLASS_EXTENDS(parts = (_ :: lst),comment = cmt),info = file_info),p,n)
      equation
        (str,tp) = getNthPublicConnectorStr(modelpath, Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info), p, n);
      then
        (str,tp);

  end matchcontinue;
end getNthPublicConnectorStr;

protected function getNthConnectorStr
"function: getNthConnectorStr
   This function takes an ElementItem list and an int and
   returns the name of the nth connector component in that list."
  input Absyn.Program inProgram;
  input Absyn.Path inPath;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Integer inInteger;
  output String outString;
  output Absyn.Path outPath;
algorithm
  (outString,outPath) := matchcontinue (inProgram,inPath,inAbsynElementItemLst,inInteger)
    local
      Absyn.Class cdef;
      Absyn.Path newmodelpath,tp,modelpath;
      String str;
      Absyn.Program p;
      list<Absyn.ElementItem> lst;
      Integer n,c1,c2,newn;
      list<Absyn.ComponentItem> complst;
    case (p,modelpath,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.EXTENDS(path = tp),constrainClass = NONE())) :: lst),n)
      equation
        (cdef,newmodelpath) = lookupClassdef(tp, modelpath, p);
        (str,tp) = getNthPublicConnectorStr(newmodelpath, cdef, p, n);
      then
        (str,tp);
    case (p,modelpath,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.EXTENDS(path = tp),constrainClass = NONE())) :: lst),n)
      equation
        (cdef,newmodelpath) = lookupClassdef(tp, modelpath, p);
        c1 = countPublicConnectors(newmodelpath, p, cdef);
        c2 = n - c1;
        (str,tp) = getNthConnectorStr(p, modelpath, lst, c2);
      then
        (str,tp);
    case (p,modelpath,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(typeSpec = Absyn.TPATH(tp,_),components = complst),constrainClass = NONE())) :: lst),n)
      equation
        (Absyn.CLASS(_,_,_,_,Absyn.R_CONNECTOR(),_,_),newmodelpath) = lookupClassdef(tp, modelpath, p);
        str = getNthCompname(complst, n);
      then
        (str,tp);
    case (p,modelpath,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(typeSpec = Absyn.TPATH(tp,_),components = complst),constrainClass = NONE())) :: lst),n)
      equation
        (Absyn.CLASS(_,_,_,_,Absyn.R_CONNECTOR(),_,_),newmodelpath) = lookupClassdef(tp, modelpath, p)
        "Not so fast, since we lookup and instantiate two times just because this was not the connector we were looking for." ;
        c1 = listLength(complst);
        newn = n - c1;
        (str,tp) = getNthConnectorStr(p, modelpath, lst, newn);
      then
        (str,tp);
    case (p,modelpath,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(typeSpec = Absyn.TPATH(tp,_),components = complst),constrainClass = NONE())) :: lst),n)
      equation
        (Absyn.CLASS(_,_,_,_,Absyn.R_EXP_CONNECTOR(),_,_),newmodelpath) = lookupClassdef(tp, modelpath, p);
        str = getNthCompname(complst, n);
      then
        (str,tp);
    case (p,modelpath,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(typeSpec = Absyn.TPATH(tp,_),components = complst),constrainClass = NONE())) :: lst),n)
      equation
        (Absyn.CLASS(_,_,_,_,Absyn.R_EXP_CONNECTOR(),_,_),newmodelpath) = lookupClassdef(tp, modelpath, p)
        "Not so fast, since we lookup and instantiate two times just because this was not the connector we were looking for." ;
        c1 = listLength(complst);
        newn = n - c1;
        (str,tp) = getNthConnectorStr(p, modelpath, lst, newn);
      then
        (str,tp);
    case (p,modelpath,(_ :: lst),n)
      equation
        (str,tp) = getNthConnectorStr(p, modelpath, lst, n);
      then
        (str,tp);
    case (p,modelpath,{},n) then fail();
  end matchcontinue;
end getNthConnectorStr;

protected function getNthCompname
"function: getNthCompname
  Returns the nth component name from a list of ComponentItems.
  Index is from 1..n."
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynComponentItemLst,inInteger)
    local
      String id,res;
      list<Absyn.ComponentItem> lst,xs;
      Integer n1,n;
    
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id)) :: lst),1) then id;
    
    case ((_ :: xs),n)
      equation
        n1 = n - 1;
        res = getNthCompname(xs, n1);
      then
        res;
    
    case ({},_) then fail();

  end matchcontinue;
end getNthCompname;

protected function countPublicConnectors
"function: countPublicConnectors
  This function takes a Class and counts the number of connector
  components in the class. This also includes counting in inherited classes."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Absyn.Class inClass;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inPath,inProgram,inClass)
    local
      Integer c1,c2,res;
      Absyn.Path modelpath,newmodelpath,cname;
      Absyn.Program p;
      String a;
      Boolean b,c,d;
      Absyn.Restriction e;
      list<Absyn.ElementItem> elt;
      list<Absyn.ClassPart> lst;
      Option<String> cmt;
      Absyn.Info file_info;
      Absyn.Class cdef;

    case (modelpath,p,
      Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                  body = Absyn.PARTS(classParts = (Absyn.PUBLIC(contents = elt) :: lst),comment = cmt),
                  info = file_info))
      equation
        c1 = countPublicConnectors(modelpath, p, Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info));
        c2 = countConnectors(modelpath, p, elt);
      then
        c1 + c2;

    case (modelpath,p,
      Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                  body = Absyn.PARTS(classParts = (_ :: lst),comment = cmt),
                  info = file_info))
      equation
        res = countPublicConnectors(modelpath, p, Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info));
      then
        res;

    case (modelpath,p,
      Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                  body = Absyn.PARTS(classParts = {},comment = cmt),
                  info = file_info))
    then 0;

    // adrpo: handle also the case of model extends name end name;
    case (modelpath,p,
      Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                  body = Absyn.CLASS_EXTENDS(parts = (Absyn.PUBLIC(contents = elt) :: lst),comment = cmt),
                  info = file_info))
      equation
        c1 = countPublicConnectors(modelpath, p, Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info));
        c2 = countConnectors(modelpath, p, elt);
      then
        c1 + c2;

    // adrpo: handle also the case of model extends name end name;
    case (modelpath,p,
      Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                  body = Absyn.CLASS_EXTENDS(parts = (_ :: lst),comment = cmt),
                  info = file_info))
      equation
        res = countPublicConnectors(modelpath, p, Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info));
      then
        res;

    // adrpo: handle also the case of model extends name end name;
    case (modelpath,p,
      Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                  body = Absyn.CLASS_EXTENDS(parts = {},comment = cmt),info = file_info))
    then 0;
    
    // the case model name = OtherName;
    case (modelpath,p,
      Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                  body = Absyn.DERIVED(typeSpec = Absyn.TPATH(cname, _))))
      equation
        (cdef,newmodelpath) = lookupClassdef(cname, modelpath, p);
        res = countPublicConnectors(newmodelpath, p, cdef);
      then
        res;

  end matchcontinue;
end countPublicConnectors;

protected function countConnectors
"function: countConnectors
  This function takes a Path to the current model and a ElementItem
  list and returns the number of connector components in that list."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inPath,inProgram,inAbsynElementItemLst)
    local
      Absyn.Class cdef;
      Absyn.Path newmodelpath,modelpath,tp;
      Integer c1,c2,res;
      Absyn.Program p;
      list<Absyn.ElementItem> lst;
      list<Absyn.ComponentItem> complst;

    case (modelpath,p,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.EXTENDS(path = tp),constrainClass = NONE())) :: lst))
      equation
        (cdef,newmodelpath) = lookupClassdef(tp, modelpath, p);
        c1 = countPublicConnectors(newmodelpath, p, cdef);
        c2 = countConnectors(modelpath, p, lst);
      then
        c1 + c2;

    case (modelpath,p,(Absyn.ELEMENTITEM(element =
      Absyn.ELEMENT(specification = Absyn.COMPONENTS(typeSpec = Absyn.TPATH(tp, _),components = complst),
      constrainClass = NONE())) :: lst))
      equation
        (Absyn.CLASS(_,_,_,_,Absyn.R_CONNECTOR(),_,_),newmodelpath) = lookupClassdef(tp, modelpath, p);
        c1 = listLength(complst);
        c2 = countConnectors(modelpath, p, lst);
      then
        c1 + c2;

    case (modelpath,p,(Absyn.ELEMENTITEM(element =
      Absyn.ELEMENT(specification = Absyn.COMPONENTS(typeSpec = Absyn.TPATH(tp, _),components = complst),
      constrainClass = NONE())) :: lst))
      equation
        (Absyn.CLASS(_,_,_,_,Absyn.R_EXP_CONNECTOR(),_,_),newmodelpath) = lookupClassdef(tp, modelpath, p);
        c1 = listLength(complst);
        c2 = countConnectors(modelpath, p, lst);
      then
        c1 + c2;

    case (modelpath,p,(_ :: lst)) /* Rule above didn\'t match => element not connector components, try rest of list */
      equation
        res = countConnectors(modelpath, p, lst);
      then
        res;

    case (_,_,{}) then 0;

  end matchcontinue;
end countConnectors;

protected function getConnectionAnnotationStrElArgs
  input list<Absyn.ElementArg> inElArgLst;
  input Absyn.Info info;
  input Absyn.Class inClass;
  input Absyn.Program inFullProgram;
  input Absyn.Path inModelPath;
  output list<String> outStringLst;
algorithm
  outStringLst := matchcontinue (inElArgLst,info,inClass,inFullProgram,inModelPath)
    local      
      Absyn.FunctionArgs fargs;
      list<SCode.Element> p_1;
      list<Env.Frame> env;
      DAE.Exp newexp;
      String gexpstr, gexpstr_1, annName;
      list<String> res;
      list<Absyn.ElementArg> elts, mod, rest;
      Env.Cache cache;
      DAE.Properties prop;
      Absyn.Program lineProgram;

    // handle empty
    case ({},info,inClass,inFullProgram,inModelPath) then {};
    
    case (Absyn.MODIFICATION(componentRef = Absyn.CREF_IDENT(annName,_), modification = SOME(Absyn.CLASSMOD(mod,_))) :: rest,info,inClass, inFullProgram, inModelPath)
      equation
        lineProgram = modelicaAnnotationProgram(Config.getAnnotationVersion());
        fargs = createFuncargsFromElementargs(mod);
        p_1 = SCodeUtil.translateAbsyn2SCode(lineProgram);
        (cache,env) = Inst.makeEnvFromProgram(Env.emptyCache(),p_1, Absyn.IDENT(""));
        (_,newexp,prop) = Static.elabGraphicsExp(cache,env, Absyn.CALL(Absyn.CREF_IDENT(annName,{}),fargs), false,Prefix.NOPRE(), info) "impl" ;
        (cache, newexp, prop) = Ceval.cevalIfConstant(cache, env, newexp, prop, false, info);
        Print.clearErrorBuf() "this is to clear the error-msg generated by the annotations." ;
        gexpstr = ExpressionDump.printExpStr(newexp);
        res = getConnectionAnnotationStrElArgs(rest, info, inClass, inFullProgram, inModelPath);
      then
        (gexpstr :: res);
    case (Absyn.MODIFICATION(componentRef = Absyn.CREF_IDENT(annName,_), modification = SOME(Absyn.CLASSMOD(mod,Absyn.NOMOD()))) :: rest,info,inClass,inFullProgram,inModelPath)
      equation
        gexpstr_1 = stringAppendList({annName,"(error)"});
        res = getConnectionAnnotationStrElArgs(rest, info, inClass, inFullProgram, inModelPath);
      then
        (gexpstr_1 :: res);
  end matchcontinue;
end getConnectionAnnotationStrElArgs;

protected function getConnectionAnnotationStr
"function: getConnectionAnnotationStr
   This function takes an `EquationItem\' and returns a comma separated
   string of values  from the flat record of a connection annotation that
   is found in the `EquationItem\'."
  input Absyn.EquationItem inEquationItem;
  input Absyn.Class inClass;
  input Absyn.Program inFullProgram;
  input Absyn.Path inModelPath;
  output String outString;
algorithm
  outString := match (inEquationItem, inClass, inFullProgram, inModelPath)
    local
      Absyn.FunctionArgs fargs;
      list<SCode.Element> p_1;
      list<Env.Frame> env;
      DAE.Exp newexp;
      String gexpstr;
      list<String> res;
      list<Absyn.ElementArg> elts, annotations;
      Env.Cache cache;
      DAE.Properties prop;
      Absyn.Info info;
      Absyn.Program lineProgram;

    case (Absyn.EQUATIONITEM(info=info, equation_ = Absyn.EQ_CONNECT(connector1 = _),
      comment = SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION(annotations)),_))),
      inClass, inFullProgram, inModelPath)
    equation
        res = getConnectionAnnotationStrElArgs(annotations, info, inClass, inFullProgram, inModelPath);
        gexpstr = stringDelimitList(res, ", ");
    then
      gexpstr;
    case (Absyn.EQUATIONITEM(equation_ = Absyn.EQ_CONNECT(connector1 = _),comment = NONE()),
          inClass, inFullProgram, inModelPath) 
      then 
        fail();
  end match;
end getConnectionAnnotationStr;

protected function createFuncargsFromElementargs
"function: create_functionargs_from_elementargs
  Trasform an ElementArg list to function argments. This is used when
  translating a graphical annotation to a record constructor."
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  output Absyn.FunctionArgs outFunctionArgs;
algorithm
  outFunctionArgs := matchcontinue (inAbsynElementArgLst)
    local
      list<Absyn.Exp> expl;
      list<Absyn.NamedArg> narg;
      String id;
      Absyn.Exp exp;
      list<Absyn.ElementArg> xs;
    
    case ({}) then Absyn.FUNCTIONARGS({},{});
    
    case ((Absyn.MODIFICATION(componentRef = Absyn.CREF_IDENT(name = id),modification = SOME(Absyn.CLASSMOD(eqMod=Absyn.EQMOD(exp=exp)))) :: xs))
      equation
        Absyn.FUNCTIONARGS(expl,narg) = createFuncargsFromElementargs(xs);
      then
        Absyn.FUNCTIONARGS(expl,(Absyn.NAMEDARG(id,exp) :: narg));
    
    case ((_ :: xs))
      equation
        Absyn.FUNCTIONARGS(expl,narg) = createFuncargsFromElementargs(xs);
      then
        Absyn.FUNCTIONARGS(expl,narg);
  end matchcontinue;
end createFuncargsFromElementargs;

protected function getNthConnectionitemInClass
"function: getNthConnectionitemInClass
   This function takes a Class and  an int ane returns the nth
   `EquationItem\' containing a connect statement in that class."
  input Absyn.Class inClass;
  input Integer inInteger;
  output Absyn.EquationItem outEquationItem;
algorithm
  outEquationItem := match (inClass,inInteger)
    local
      Absyn.EquationItem eq;
      list<Absyn.ClassPart> parts;
      Integer n;
    
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),n)
      equation
        eq = getNthConnectionitemInClassparts(parts, n);
      then
        eq;
    
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)),n)
      equation
        eq = getNthConnectionitemInClassparts(parts, n);
      then
        eq;
  end match;
end getNthConnectionitemInClass;

protected function getNthConnectionitemInClassparts
"function: getNthConnectionitemInClassparts
  This function takes a `ClassPart\' list and an int and returns
  the nth connections as an `EquationItem\'."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Integer inInteger;
  output Absyn.EquationItem outEquationItem;
algorithm
  outEquationItem := matchcontinue (inAbsynClassPartLst,inInteger)
    local
      Absyn.EquationItem eq;
      list<Absyn.EquationItem> e;
      list<Absyn.ClassPart> xs;
      Integer n,c1,newn;
    
    case ((Absyn.EQUATIONS(contents = e) :: xs),n)
      equation
        eq = getNthConnectionitemInEquations(e, n);
      then
        eq;
    
    case ((Absyn.EQUATIONS(contents = e) :: xs),n) /* The rule above failed, subtract the number of connections in the first equation section and try with the rest of the classparts */
      equation
        c1 = countConnectionsInEquations(e);
        newn = n - c1;
        eq = getNthConnectionitemInClassparts(xs, newn);
      then
        eq;
    
    case ((_ :: xs),n)
      equation
        eq = getNthConnectionitemInClassparts(xs, n);
      then
        eq;
  end matchcontinue;
end getNthConnectionitemInClassparts;

protected function getNthConnectionitemInEquations
"function: getNthConnectionitemInEquations
   This function takes  an Equation list and an int
   and returns the nth connection as an Equation.
   If the number is larger than the number of connections
   in the list, the function fails."
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  input Integer inInteger;
  output Absyn.EquationItem outEquationItem;
algorithm
  outEquationItem := matchcontinue (inAbsynEquationItemLst,inInteger)
    local
      Absyn.EquationItem eq;
      list<Absyn.EquationItem> xs;
      Integer newn,n;
    
    case (((eq as Absyn.EQUATIONITEM(equation_ = Absyn.EQ_CONNECT(connector1 = _))) :: xs),1) then eq;
    
    case ((Absyn.EQUATIONITEM(equation_ = Absyn.EQ_CONNECT(connector1 = _)) :: xs),n)
      equation
        newn = n - 1;
        eq = getNthConnectionitemInEquations(xs, newn);
      then
        eq;
    
    case ((_ :: xs),n)
      equation
        eq = getNthConnectionitemInEquations(xs, n);
      then
        eq;
    
    case ({},_) then fail();

  end matchcontinue;
end getNthConnectionitemInEquations;

protected function getConnectionStr
"function: getConnectionStr
   This function takes an Equation assumed to contain a connection and
   returns a comma separated string of componentreferences, e.g \"R1.n,C.p\"
   for  connect(R1.n,C.p)."
  input Absyn.Equation inEquation;
  output String outString;
algorithm
  outString := match (inEquation)
    local
      String s1,s2,str;
      Absyn.ComponentRef cr1,cr2;
    
    case Absyn.EQ_CONNECT(connector1 = cr1,connector2 = cr2)
      equation
        s1 = Dump.printComponentRefStr(cr1);
        s2 = Dump.printComponentRefStr(cr2);
        str = stringAppendList({s1,",",s2});
      then
        str;
  end match;
end getConnectionStr;

protected function countConnections
"function: countConnections
  This function takes a Class and returns an int
  with the number of connections in the Class."
  input Absyn.Class inClass;
  output Integer outInteger;
algorithm
  outInteger := match (inClass)
    local
      Integer count;
      list<Absyn.ClassPart> parts;
    
    case Absyn.CLASS(body = Absyn.PARTS(classParts = parts))
      equation
        count = countConnectionsInClassparts(parts);
      then
        count;
    
    // adrpo: handle also the case model extends X end X;
    case Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts))
      equation
        count = countConnectionsInClassparts(parts);
      then
        count;
    
    case Absyn.CLASS(body = Absyn.DERIVED(typeSpec = _)) then 0;

  end match;
end countConnections;

protected function countConnectionsInClassparts
"function: countConnectionsInClassparts
   This function takes a ClassPart list and returns
   an int with the number of connections in that list."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inAbsynClassPartLst)
    local
      Integer r1,r2,res;
      list<Absyn.EquationItem> eqlist;
      list<Absyn.ClassPart> xs;
    
    case ((Absyn.EQUATIONS(contents = eqlist) :: xs))
      equation
        r1 = countConnectionsInEquations(eqlist);
        r2 = countConnectionsInClassparts(xs);
      then
        r1 + r2;
    
    case ((_ :: xs))
      equation
        res = countConnectionsInClassparts(xs);
      then
        res;
    
    case ({}) then 0;

  end matchcontinue;
end countConnectionsInClassparts;

protected function countConnectionsInEquations
"function: countConnectionsInEquations
   This function takes an Equation list and returns an int
   with the number of connect statements in that list."
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inAbsynEquationItemLst)
    local
      Integer r1,res;
      list<Absyn.EquationItem> xs;
    
    case ((Absyn.EQUATIONITEM(equation_ = Absyn.EQ_CONNECT(connector1 = _)) :: xs))
      equation
        r1 = countConnectionsInEquations(xs);
      then
        r1 + 1;
    
    case ((_ :: xs))
      equation
        res = countConnectionsInEquations(xs);
      then
        res;
    
    case ({}) 
      then 
        0;

  end matchcontinue;
end countConnectionsInEquations;

protected function getComponentAnnotationsFromElts
"function: getComponentAnnotationsFromElts
  Helper function to getComponentAnnotations."
  input list<Absyn.Element> comps;
  input Absyn.Class inClass;
  input Absyn.Program inFullProgram;
  input Absyn.Path inModelPath;
  output String resStr;
protected
  list<SCode.Element> graphicProgramSCode;
  list<Env.Frame> env;
  list<String> res;
  Absyn.Program placementProgram;
algorithm
  placementProgram := modelicaAnnotationProgram(Config.getAnnotationVersion());
  graphicProgramSCode := SCodeUtil.translateAbsyn2SCode(placementProgram);
  (_,env) := Inst.makeEnvFromProgram(Env.emptyCache(), graphicProgramSCode, Absyn.IDENT(""));
  res := getComponentitemsAnnotations(comps, env, inClass, inFullProgram, inModelPath);
  resStr := stringDelimitList(res, ",");
end getComponentAnnotationsFromElts;

protected function getComponentitemsAnnotations
"function: getComponentitemsAnnotations
  Helper function to getComponentAnnotationsFromElts"
  input list<Absyn.Element> inAbsynElementLst;
  input Env.Env inEnv;
  input Absyn.Class inClass;
  input Absyn.Program inFullProgram;
  input Absyn.Path inModelPath;
  output list<String> outStringLst;
algorithm
  outStringLst := matchcontinue (inAbsynElementLst,inEnv,inClass,inFullProgram,inModelPath)
    local
      list<String> res1,res2,res;
      list<Absyn.ComponentItem> items;
      list<Absyn.Element> rest;
      list<Env.Frame> env;
    
    case ({},_,_,_,_) then {};
    
    case ((Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = items)) :: rest),env,inClass,inFullProgram,inModelPath)
      equation
        res1 = getComponentitemsAnnotationsFromItems(items, env, inClass,inFullProgram,inModelPath);
        res2 = getComponentitemsAnnotations(rest, env, inClass,inFullProgram,inModelPath);
        res = listAppend(res1, res2);
      then
        res;
    
    case ((Absyn.ELEMENT(specification = Absyn.COMPONENTS(attributes = _)) :: rest),env,inClass,inFullProgram,inModelPath)
      equation
        res2 = getComponentitemsAnnotations(rest, env,inClass,inFullProgram,inModelPath);
        res = "{}"::res2;
      then
        res;
    
    case ((_ :: rest),env,inClass,inFullProgram,inModelPath)
      equation
        res = getComponentitemsAnnotations(rest, env,inClass,inFullProgram,inModelPath);
      then
        res;
  end matchcontinue;
end getComponentitemsAnnotations;

protected function getComponentitemsAnnotationsElArgs
"function: getComponentitemsAnnotationsElArgs
  Helper function to getComponentitemsAnnotationsFromItems."
  input list<Absyn.ElementArg> inElArgLst;
  input Env.Env inEnv;
  input Absyn.Class inClass;
  input Absyn.Program inFullProgram;
  input Absyn.Path inModelPath;
  output list<String> outStringLst;
algorithm
  outStringLst := matchcontinue (inElArgLst,inEnv,inClass,inFullProgram,inModelPath)
    local
      list<Env.Frame> env,env_1;
      SCode.Element c,c_1;
      SCode.Mod mod_1;
      DAE.Mod mod_2;
      DAE.DAElist dae;
      Connect.Sets cs;
      DAE.Type t;
      ClassInf.State state;
      String gexpstr,gexpstr_1,annName;
      list<String> res;
      list<Absyn.ElementArg> mod, rest;
      Env.Cache cache;
      Absyn.Info info;

    // handle empty
    case ({},env,inClass,inFullProgram,inModelPath) then {};
    
    case (Absyn.MODIFICATION(componentRef = Absyn.CREF_IDENT(annName,_),
        modification = SOME(Absyn.CLASSMOD(mod,Absyn.NOMOD())), info = info) :: rest,env,inClass,inFullProgram,inModelPath)
      equation
        
        (cache,c,env_1) = Lookup.lookupClass(Env.emptyCache(),env, Absyn.IDENT(annName), false);
        mod_1 = SCodeUtil.translateMod(SOME(Absyn.CLASSMOD(mod,Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH(), info);
        (cache,mod_2) = Mod.elabMod(cache, env_1, InnerOuter.emptyInstHierarchy, Prefix.NOPRE(), mod_1, false, Absyn.dummyInfo);
        c_1 = SCode.classSetPartial(c, SCode.NOT_PARTIAL());
        (_,_,_,_,dae,cs,t,state,_,_) =
          Inst.instClass(cache, env_1,InnerOuter.emptyInstHierarchy,
            UnitAbsyn.noStore, mod_2, Prefix.NOPRE(), c_1, {}, false,
            Inst.TOP_CALL(), ConnectionGraph.EMPTY, Connect.emptySet);
        gexpstr = DAEUtil.getVariableBindingsStr(DAEUtil.daeElements(dae));
        
        gexpstr_1 = stringAppendList({annName,"(",gexpstr,")"});
        res = getComponentitemsAnnotationsElArgs(rest, env, inClass,inFullProgram,inModelPath);
      then
        (gexpstr_1 :: res);

    case (Absyn.MODIFICATION(componentRef = Absyn.CREF_IDENT(annName,_),
        modification = SOME(Absyn.CLASSMOD(mod,Absyn.NOMOD()))) :: rest,env,inClass,inFullProgram,inModelPath)
      equation
        gexpstr_1 = stringAppendList({annName,"(error)"});
        res = getComponentitemsAnnotationsElArgs(rest, env, inClass,inFullProgram,inModelPath);
      then
        (gexpstr_1 :: res);    

  end matchcontinue;
end getComponentitemsAnnotationsElArgs;

protected function getComponentitemsAnnotationsFromItems
"function: getComponentitemsAnnotationsFromItems
  Helper function to getComponentitemsAnnotations."
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Env.Env inEnv;
  input Absyn.Class inClass;
  input Absyn.Program inFullProgram;
  input Absyn.Path inModelPath;
  output list<String> outStringLst;
algorithm
  outStringLst := matchcontinue (inAbsynComponentItemLst,inEnv,inClass,inFullProgram,inModelPath)
    local
      list<Env.Frame> env,env_1;
      SCode.Element c,c_1;
      SCode.Mod mod_1;
      DAE.Mod mod_2;
      DAE.DAElist dae;
      Connect.Sets cs;
      DAE.Type t;
      ClassInf.State state;
      String gexpstr,gexpstr_1,annName;
      list<String> res;
      list<Absyn.ElementArg> mod, annotations;
      list<Absyn.ComponentItem> rest;
      Env.Cache cache;

    // handle empty
    case ({},env,inClass,inFullProgram,inModelPath) then {};
    
    case ((Absyn.COMPONENTITEM(comment = SOME(
      Absyn.COMMENT(
            SOME(Absyn.ANNOTATION(annotations)),
            _))) :: rest),env,inClass,inFullProgram,inModelPath)
      equation
        
        res = getComponentitemsAnnotationsElArgs(annotations,env,inClass,inFullProgram,inModelPath);
        gexpstr = stringDelimitList(res, ", ");
        
        gexpstr_1 = stringAppendList({"{",gexpstr,"}"});
        res = getComponentitemsAnnotationsFromItems(rest, env, inClass,inFullProgram,inModelPath);
      then
        (gexpstr_1 :: res);

    case ((Absyn.COMPONENTITEM(comment = NONE()) :: (rest as (_ :: _))),env, inClass,inFullProgram,inModelPath)
      equation
        res = getComponentitemsAnnotationsFromItems(rest, env, inClass,inFullProgram,inModelPath);
      then
        ("{}" :: res);
    
    case ({Absyn.COMPONENTITEM(comment = NONE())},env,inClass,inFullProgram,inModelPath) 
      then 
        {"{}"};

  end matchcontinue;
end getComponentitemsAnnotationsFromItems;

protected function getComponentAnnotation
"function: getComponentAnnotation
  This function takes an Element and returns a comma separated string
  of values corresponding to the flat record for a component annotation.
  If several components are declared within the eleement, a list of values
  is given for each of them."
  input Absyn.Element inElement;
  input Absyn.Class inClass;
  input Absyn.Program inFullProgram;
  input Absyn.Path inModelPath;
  output String outString;
algorithm
  outString := matchcontinue (inElement,inClass,inFullProgram,inModelPath)
    local
      String str;
      list<Absyn.ComponentItem> lst;
    
    case (Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = lst),constrainClass = NONE()),
          inClass,inFullProgram,inModelPath)
      equation
        str = getComponentitemsAnnotation(lst, inClass,inFullProgram,inModelPath);
      then
        str;
    
    case (_,inClass,inFullProgram,inModelPath) then "";
  end matchcontinue;
end getComponentAnnotation;

protected function modelicaAnnotationProgram
   input String annotationVersion "1.x or 2.x or 3.x";
   output Absyn.Program annotationProgram;
algorithm
  annotationProgram := match(annotationVersion)
    local
      Absyn.Program annProg;
      String resultParse;
    
    case ("1.x")
      equation
        annProg = Parser.parsestring(Constants.annotationsModelica_1_x, "<1.x annotations>");
      then annProg;

    case ("2.x")
      equation
        annProg = Parser.parsestring(Constants.annotationsModelica_2_x, "<2.x annotations>");
      then annProg;

    case ("3.x")
      equation
        annProg = Parser.parsestring(Constants.annotationsModelica_3_x, "<3.x annotations>");
      then annProg;
  end match;
end modelicaAnnotationProgram;

protected function getComponentitemsAnnotation
"function: getComponentitemsAnnotation
  Helper function to get_component_annotation."
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Absyn.Class inClass;
  input Absyn.Program inFullProgram;
  input Absyn.Path inModelPath;
  output String outString;
algorithm
  outString := match (inAbsynComponentItemLst,inClass,inFullProgram,inModelPath)
    local
      String s1,str,res;
      list<Absyn.ElementArg> mod;
      list<Absyn.ComponentItem> rest;
    
    case ((Absyn.COMPONENTITEM(comment = SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION((mod as (Absyn.MODIFICATION(componentRef = Absyn.CREF_IDENT("Placement",_)) :: _)))),_))) ::
      (rest as (_ :: _))),
      inClass,inFullProgram,inModelPath)
      equation
        s1 = getAnnotationString(Absyn.ANNOTATION(mod), inClass, inFullProgram, inModelPath);
        str = getComponentitemsAnnotation(rest, inClass, inFullProgram, inModelPath);
        res = stringAppendList({"{", s1, "},", str});
      then
        res;
    case ({Absyn.COMPONENTITEM(comment = SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION((mod as (Absyn.MODIFICATION(componentRef = Absyn.CREF_IDENT("Placement",_)) :: _)))),_)))},
      inClass,inFullProgram,inModelPath)
      equation
        s1 = getAnnotationString(Absyn.ANNOTATION(mod),inClass,inFullProgram,inModelPath);
        res = stringAppendList({"{", s1, "}"});
      then
        res;
    case ((Absyn.COMPONENTITEM(comment = SOME(Absyn.COMMENT(NONE(),_))) :: (rest as (_ :: _))),
      inClass,inFullProgram,inModelPath)
      equation
        str = getComponentitemsAnnotation(rest,inClass,inFullProgram,inModelPath);
        res = stringAppend("{nada},", str);
      then
        res;
    case ((Absyn.COMPONENTITEM(comment = NONE()) :: (rest as (_ :: _))),
      inClass,inFullProgram,inModelPath)
      equation
        str = getComponentitemsAnnotation(rest,inClass,inFullProgram,inModelPath);
        res = stringAppend("{},", str);
      then
        res;
    case ({Absyn.COMPONENTITEM(comment = NONE())},inClass,inFullProgram,inModelPath)
      equation
        res = "{}";
      then
        res;
  end match;
end getComponentitemsAnnotation;

public function getComponentModification
"function: getComponentModification
   This function takes an Element and returns a comma separated
   list of Code expression for the modification of the component."
  input Absyn.Element inElement;
  output String outString;
algorithm
  outString:=
  matchcontinue (inElement)
    local
      String str;
      list<Absyn.ComponentItem> lst;
    case (Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = lst),constrainClass = NONE()))
      equation
        str = getComponentitemsModification(lst);
      then
        str;
    case _ then "";
  end matchcontinue;
end getComponentModification;

protected function getComponentitemsModification
"function: getComponentitemsModification
  Helper function to get_component_modification."
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inAbsynComponentItemLst)
    local
      String s1,s2,res,str;
      Absyn.Modification mod;
      list<Absyn.ComponentItem> rest;
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(modification = SOME(mod))) :: (rest as (_ :: _))))
      equation
        s1 = Dump.printExpStr(Absyn.CODE(Absyn.C_MODIFICATION(mod)));
        s2 = getComponentitemsModification(rest);
        res = stringAppendList({s1,",",s2});
      then
        res;
    case ({Absyn.COMPONENTITEM(component = Absyn.COMPONENT(modification = SOME(mod)))})
      equation
        res = Dump.printExpStr(Absyn.CODE(Absyn.C_MODIFICATION(mod)));
      then
        res;
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(modification = NONE())) :: (rest as (_ :: _))))
      equation
        str = getComponentitemsModification(rest);
        res = stringAppend("Code(),", str);
      then
        res;
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(modification = NONE())) :: (rest as (_ :: _))))
      equation
        str = getComponentitemsModification(rest);
        res = stringAppend("Code(),", str);
      then
        res;
    case ({Absyn.COMPONENTITEM(comment = NONE())})
      equation
        res = "Code()";
      then
        res;
  end matchcontinue;
end getComponentitemsModification;

protected function buildEnvForGraphicProgram
"@author: adrpo
  if the annotation modification contains anything but *literals*
  we need to instantiate the class to be able to populate the
  modifiers inside the annotation!"
  input Absyn.Program inFullProgram "the full modelica program";
  input Absyn.Path inModelPath "the path to the class where the annotation is";
  input list<Absyn.ElementArg> inAnnotationMod "the annotation modification";
  input String inAnnotationClass "the annotation class i.e. Line, Icon, etc";
  output Env.Cache outCache;
  output Env.Env outEnv;
  output Absyn.Program outGraphicProgram;
algorithm
  (outCache, outEnv, outGraphicProgram) := 
  matchcontinue(inFullProgram, inModelPath, inAnnotationMod, inAnnotationClass)
    local
      Env.Cache cache;
      Env.Env env;
      list<SCode.Element> graphicProgramSCode;
      Absyn.Program graphicProgram;
      Boolean b1, b2;
      
    // the annotation contains references to the model, do full instantiation of the class!
    case (inFullProgram, inModelPath, inAnnotationMod, inAnnotationClass)
      equation
        false = Absyn.onlyLiteralsInAnnotationMod(inAnnotationMod);
        graphicProgram = modelicaAnnotationProgram(Config.getAnnotationVersion());
        graphicProgram = updateProgram(graphicProgram, inFullProgram);
        graphicProgramSCode = SCodeUtil.translateAbsyn2SCode(graphicProgram);
        
        // debugging
        // print("Get annotation via full instantiation of: " +& Absyn.pathString(inModelPath) +& "\n");
        // print("Annotation to get: (" +& stringDelimitList(List.map(inAnnotationMod, Dump.unparseElementArgStr), ", ") +& ")\n");
        // print("Annotation class: " +& inAnnotationClass +& "\n");
        
        // fully instantiate the class that contains the annotation!
        // set check model on so that partial classes can be instantiated!                
        b1 = Flags.getConfigBool(Flags.CHECK_MODEL);
        b2 = Config.getEvaluateParametersInAnnotations();
        Flags.setConfigBool(Flags.CHECK_MODEL, true);
        Config.setEvaluateParametersInAnnotations(true); // set to evaluate the parameters!
        (cache,env,_,_) = Inst.instantiateClass(Env.emptyCache(),InnerOuter.emptyInstHierarchy,graphicProgramSCode,inModelPath);
        Config.setEvaluateParametersInAnnotations(b2);
        Flags.setConfigBool(Flags.CHECK_MODEL, b1);
      then
        (cache, env, graphicProgram);
    
    // the annotation contains only literals, so we don't need to instantiate the class
    case (inFullProgram, inModelPath, inAnnotationMod, inAnnotationClass)
      equation
        true = Absyn.onlyLiteralsInAnnotationMod(inAnnotationMod);

        // debugging
        // print("Get annotation via small instantiation of: " +& Absyn.pathString(inModelPath) +& "\n");
        // print("Annotation to get: (" +& stringDelimitList(List.map(inAnnotationMod, Dump.unparseElementArgStr), ", ") +& ")\n");
        // print("Annotation class: " +& inAnnotationClass +& "\n");

        graphicProgram = modelicaAnnotationProgram(Config.getAnnotationVersion());
        graphicProgramSCode = SCodeUtil.translateAbsyn2SCode(graphicProgram);
        (cache,env) = Inst.makeSimpleEnvFromProgram(Env.emptyCache(), graphicProgramSCode, Absyn.IDENT(inAnnotationClass));
      then
        (cache, env, graphicProgram);
        
  end matchcontinue;
end buildEnvForGraphicProgram;

protected function getAnnotationString
"function getAnnotationString
  This function takes an annotation and returns a comma separates string
  of values representing the flat record of the specific annotation.
  The function as two special rules for handling of Icon and Diagram
  annotations since these two contain graphic primitives, which must be
  handled specially because Modelica does not have the possibility to store
  polymorphic values (e.g. different record classes with the same baseclass)
  in for instance an array."
  input Absyn.Annotation inAnnotation;
  input Absyn.Class inClass;
  input Absyn.Program inFullProgram;
  input Absyn.Path inModelPath;
  output String outString;
algorithm
  outString := matchcontinue (inAnnotation,inClass,inFullProgram,inModelPath)
    local
      list<Absyn.ElementArg> stripmod,mod,gxmods;
      Absyn.Exp graphicexp;
      SCode.Mod mod_1;
      list<Env.Frame> env;
      Absyn.Class placementc;
      SCode.Element placementclass;
      DAE.Mod mod_2;
      DAE.DAElist dae;
      Connect.Sets cs;
      DAE.Type t;
      ClassInf.State state;
      String str,gexpstr,totstr,anncname;
      DAE.Exp graphicexp2;
      DAE.Properties prop;
      Absyn.Program graphicProgram;
      Env.Cache cache;
      Absyn.Info info;

    case (Absyn.ANNOTATION(elementArgs = {Absyn.MODIFICATION(componentRef = Absyn.CREF_IDENT(name = "Icon"),modification = SOME(Absyn.CLASSMOD(mod,_)), info = info)}),
          inClass,
          inFullProgram,
          inModelPath)
      equation
        // print(Dump.unparseStr(graphicProgram, false));
        // print("Annotation(Icon) 1: " +& Dump.unparseMod1Str(mod) +& "\n");
        (stripmod,{Absyn.MODIFICATION(modification = SOME(Absyn.CLASSMOD(eqMod=Absyn.EQMOD(exp=graphicexp))))}) = stripGraphicsAndInteractionModification(mod);
        
        // print("Annotation(Icon) 1: " +& Dump.unparseMod1Str(stripmod) +& "\n");
        
        mod_1 = SCodeUtil.translateMod(SOME(Absyn.CLASSMOD(stripmod,Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH(), info);
        
        (cache, env, graphicProgram) = buildEnvForGraphicProgram(inFullProgram, inModelPath, mod, "Icon");
        
        placementc = getClassInProgram("Icon", graphicProgram);
        placementclass = SCodeUtil.translateClass(placementc);
                
        (cache,mod_2) = Mod.elabMod(cache, env, InnerOuter.emptyInstHierarchy, Prefix.NOPRE(), mod_1, false, Absyn.dummyInfo); // TODO: FIXME: Someone forgot to add Absyn.Info to this function's input
        (cache,_,_,_,dae,cs,t,state,_,_) =
          Inst.instClass(cache, env, InnerOuter.emptyInstHierarchy, UnitAbsyn.noStore, mod_2, Prefix.NOPRE(),
            placementclass, {}, false, Inst.TOP_CALL(), ConnectionGraph.EMPTY, Connect.emptySet);
        
        str = DAEUtil.getVariableBindingsStr(DAEUtil.daeElements(dae));
        
        // print("Env: " +& Env.printEnvStr(env) +& "\n");
        
        (_,graphicexp2,prop) = Static.elabGraphicsExp(cache, env, graphicexp, false, Prefix.NOPRE(), Absyn.dummyInfo); // TODO: FIXME: Someone forgot to add Absyn.Info to this function's input
        (cache, graphicexp2, prop) = Ceval.cevalIfConstant(cache, env, graphicexp2, prop, false, Absyn.dummyInfo);
        (graphicexp2,_) = ExpressionSimplify.simplify1(graphicexp2);
        Print.clearErrorBuf() "this is to clear the error-msg generated by the annotations.";
        gexpstr = ExpressionDump.printExpStr(graphicexp2);
        totstr = stringAppendList({str, ",", gexpstr});
      then
        totstr;

    // First line in the first rule above fails if return value from stripGraphicsAndInteractionModification doesn't match the lhs
    case (Absyn.ANNOTATION(elementArgs = {Absyn.MODIFICATION(componentRef = Absyn.CREF_IDENT(name = "Icon"),modification = SOME(Absyn.CLASSMOD(mod,_)), info = info)}),
          inClass,
          inFullProgram,
          inModelPath)
      equation
        // print(Dump.unparseStr(p, false));
        // print("Annotation(Icon): " +& Dump.unparseMod1Str(mod) +& "\n");
        (stripmod,gxmods) = stripGraphicsAndInteractionModification(mod);
        mod_1 = SCodeUtil.translateMod(SOME(Absyn.CLASSMOD(stripmod,Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH(), info);
        
        // print("Annotation(Icon) 2: " +& Dump.unparseMod1Str(stripmod) +& "\n");
        
        (cache, env, graphicProgram) = buildEnvForGraphicProgram(inFullProgram, inModelPath, mod, "Icon");
        
        placementc = getClassInProgram("Icon", graphicProgram);
        placementclass = SCodeUtil.translateClass(placementc);
        (cache,mod_2) = Mod.elabMod(cache, env, InnerOuter.emptyInstHierarchy, Prefix.NOPRE(), mod_1, true, Absyn.dummyInfo);
        (cache,_,_,_,dae,cs,t,state,_,_) =
          Inst.instClass(cache, env, InnerOuter.emptyInstHierarchy, UnitAbsyn.noStore,
            mod_2, Prefix.NOPRE(), placementclass, {}, false, Inst.TOP_CALL(),
            ConnectionGraph.EMPTY, Connect.emptySet); 
        str = DAEUtil.getVariableBindingsStr(DAEUtil.daeElements(dae));
        Print.clearErrorBuf() "this is to clear the error-msg generated by the annotations." ;
      then
        str;

    case (Absyn.ANNOTATION(elementArgs = {Absyn.MODIFICATION(componentRef = Absyn.CREF_IDENT(name = "Diagram"),modification = SOME(Absyn.CLASSMOD(mod,_)),info = info)}),
          inClass,
          inFullProgram,
          inModelPath)
      equation
        // print(Dump.unparseStr(p, false));
        // print("Annotation(Diagram): " +& Dump.unparseMod1Str(mod) +& "\n");
        (stripmod,{Absyn.MODIFICATION(modification=SOME(Absyn.CLASSMOD(eqMod=Absyn.EQMOD(exp=graphicexp))))}) = stripGraphicsAndInteractionModification(mod);
        mod_1 = SCodeUtil.translateMod(SOME(Absyn.CLASSMOD(stripmod,Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH(), info);
        
        // print("Annotation(Diagram) 1: " +& Dump.unparseMod1Str(stripmod) +& "\n");

        (cache, env, graphicProgram) = buildEnvForGraphicProgram(inFullProgram, inModelPath, mod, "Diagram");

        placementc = getClassInProgram("Diagram", graphicProgram);
        placementclass = SCodeUtil.translateClass(placementc);
        (cache,mod_2) = Mod.elabMod(cache, env, InnerOuter.emptyInstHierarchy, Prefix.NOPRE(), mod_1, false, Absyn.dummyInfo);
        (cache,_,_,_,dae,cs,t,state,_,_) =
          Inst.instClass(cache, env, InnerOuter.emptyInstHierarchy,
            UnitAbsyn.noStore, mod_2, Prefix.NOPRE(), placementclass, {}, false,
            Inst.TOP_CALL(), ConnectionGraph.EMPTY, Connect.emptySet);
        str = DAEUtil.getVariableBindingsStr(DAEUtil.daeElements(dae));
        
        // print("Env: " +& Env.printEnvStr(env) +& "\n");
        
        (_,graphicexp2,prop) = Static.elabGraphicsExp(cache, env, graphicexp, false,Prefix.NOPRE(), Absyn.dummyInfo); // TODO: FIXME: Someone forgot to add Absyn.Info to this function's input
        Print.clearErrorBuf() "this is to clear the error-msg generated by the annotations." ;
        gexpstr = ExpressionDump.printExpStr(graphicexp2);
        totstr = stringAppendList({str, ",", gexpstr});
      then
        totstr;

    // First line in the first rule above fails if return value from stripGraphicsAndInteractionModification doesn't match the lhs
    case (Absyn.ANNOTATION(elementArgs = {Absyn.MODIFICATION(componentRef = Absyn.CREF_IDENT(name = "Diagram"),modification = SOME(Absyn.CLASSMOD(mod,_)), info = info)}),
          inClass,
          inFullProgram,
          inModelPath)
      equation
        // print(Dump.unparseStr(p, false));
        // print("Annotation(Icon): " +& Dump.unparseMod1Str(mod) +& "\n");
        (stripmod,gxmods) = stripGraphicsAndInteractionModification(mod);
        mod_1 = SCodeUtil.translateMod(SOME(Absyn.CLASSMOD(stripmod,Absyn.NOMOD())),
        SCode.NOT_FINAL(), SCode.NOT_EACH(), info);
        
        // print("Annotation(Diagram) 2: " +& Dump.unparseMod1Str(stripmod) +& "\n");
        
        (cache, env, graphicProgram) = buildEnvForGraphicProgram(inFullProgram, inModelPath, mod, "Diagram");
        
        placementc = getClassInProgram("Icon", graphicProgram);
        placementclass = SCodeUtil.translateClass(placementc);
        (cache,mod_2) = Mod.elabMod(cache, env, InnerOuter.emptyInstHierarchy, Prefix.NOPRE(), mod_1, true, Absyn.dummyInfo);
        (cache,_,_,_,dae,cs,t,state,_,_) =
          Inst.instClass(cache, env, InnerOuter.emptyInstHierarchy, UnitAbsyn.noStore,
            mod_2, Prefix.NOPRE(), placementclass, {}, false, Inst.TOP_CALL(),
            ConnectionGraph.EMPTY, Connect.emptySet); 
        str = DAEUtil.getVariableBindingsStr(DAEUtil.daeElements(dae));
        Print.clearErrorBuf() "this is to clear the error-msg generated by the annotations." ;
      then
        str;

    case (Absyn.ANNOTATION(elementArgs = {Absyn.MODIFICATION(componentRef = Absyn.CREF_IDENT(name = anncname),modification = SOME(Absyn.CLASSMOD(mod,_)), info = info)}),
          inClass,
          inFullProgram,
          inModelPath)
      equation
        // print(Dump.unparseStr(p, false));
        // print("Annotation(" +& anncname +& "): " +& Dump.unparseMod1Str(mod) +& "\n");
        (stripmod,gxmods) = stripGraphicsAndInteractionModification(mod);
        mod_1 = SCodeUtil.translateMod(SOME(Absyn.CLASSMOD(stripmod,Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH(), info);
        
        // print("ANY Annotation(" +& anncname +& ") : " +& Dump.unparseMod1Str(mod) +& "\n");

        (cache, env, graphicProgram) = buildEnvForGraphicProgram(inFullProgram, inModelPath, mod, anncname);

        placementc = getClassInProgram(anncname, graphicProgram);
        placementclass = SCodeUtil.translateClass(placementc);
        (cache,mod_2) = Mod.elabMod(cache, env, InnerOuter.emptyInstHierarchy, Prefix.NOPRE(), mod_1, false, Absyn.dummyInfo);
        (cache,_,_,_,dae,cs,t,state,_,_) =
          Inst.instClass(cache, env, InnerOuter.emptyInstHierarchy, UnitAbsyn.noStore,
            mod_2, Prefix.NOPRE(), placementclass, {},
            false, Inst.TOP_CALL(), ConnectionGraph.EMPTY, Connect.emptySet);
        str = DAEUtil.getVariableBindingsStr(DAEUtil.daeElements(dae));
        Print.clearErrorBuf() "this is to clear the error-msg generated by the annotations." ;
      then
        str;

    // if we fail, just return the annotation as it is
    case (inAnnotation, inClass, inFullProgram, inModelPath)
      equation
        str = Dump.unparseAnnotationOption(0, SOME(inAnnotation)) +& " ";
      then
        str;

    case (inAnnotation, inClass, inFullProgram, inModelPath)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprintln(Flags.FAILTRACE, 
          "- Interactive.getAnnotationString failed on annotation: " +& 
          Dump.unparseAnnotationOption(0, SOME(inAnnotation)));
      then
        fail();
  end matchcontinue;
end getAnnotationString;

protected function stripGraphicsAndInteractionModification
"function: stripGraphicsAndInteractionModification
   This function strips out the `graphics\' modification from an ElementArg
   list and return two lists, one with the other modifications and the
   second with the `graphics\' modification"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  output list<Absyn.ElementArg> outAbsynElementArgLst1;
  output list<Absyn.ElementArg> outAbsynElementArgLst2;
algorithm
  (outAbsynElementArgLst1,outAbsynElementArgLst2) := matchcontinue (inAbsynElementArgLst)
    local
      Absyn.ElementArg mod;
      list<Absyn.ElementArg> rest,l1,l2;
    
    // handle empty
    case ({}) then ({},{});
    
    // adrpo: remove interaction annotations as we don't handle them currently
    case (((mod as Absyn.MODIFICATION(modification = _, componentRef = Absyn.CREF_IDENT(name = "interaction"))) :: rest))
      equation
         (l1,l2) = stripGraphicsAndInteractionModification(rest);
      then 
        (l1,l2);
    
    // adrpo: remove empty annotations, to handle bad Dymola annotations, for example: Diagram(graphics)
    case (((mod as Absyn.MODIFICATION(modification = NONE(), componentRef = Absyn.CREF_IDENT(name = "graphics"))) :: rest))
      equation
         (l1,l2) = stripGraphicsAndInteractionModification(rest);
      then 
        (l1,l2);
    
    // add graphics to the second tuple
    case (((mod as Absyn.MODIFICATION(modification = SOME(_), componentRef = Absyn.CREF_IDENT(name = "graphics"))) :: rest))
      equation
        (l1,l2) = stripGraphicsAndInteractionModification(rest);
      then 
        (l1,mod::l2);
    
    // collect in the first tuple
    case (((mod as Absyn.MODIFICATION(finalPrefix = _)) :: rest))
      equation
        (l1,l2) = stripGraphicsAndInteractionModification(rest);
      then
        ((mod :: l1),l2);

  end matchcontinue;
end stripGraphicsAndInteractionModification;

public function getComponentsInClass
"function: getComponentsInClass
   Both public and protected lists are searched."
  input Absyn.Class inClass;
  output list<Absyn.Element> outAbsynElementLst;
algorithm
  outAbsynElementLst:=
  matchcontinue (inClass)
    local
      String a;
      Boolean b,c,d;
      Absyn.Restriction e;
      Option<String> cmt;
      list<Absyn.Element> lst1,lst2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> lst;
      Absyn.Info file_info;

    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.PARTS(classParts = {},comment = cmt))) then {};
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.PARTS(classParts = (Absyn.PUBLIC(contents = elts) :: lst),comment = cmt),info = file_info)) /* Search in public list */
      equation
        lst1 = getComponentsInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info));
        lst2 = getComponentsInElementitems(elts);
        res = listAppend(lst2, lst1);
      then
        res;
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.PARTS(classParts = (Absyn.PROTECTED(contents = elts) :: lst),comment = cmt),info = file_info)) /* Search in protected list */
      equation
        lst1 = getComponentsInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info));
        lst2 = getComponentsInElementitems(elts);
        res = listAppend(lst2, lst1);
      then
        res;

    /* adrpo: handle also the case model extends X end X; */
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.CLASS_EXTENDS(parts = {},comment = cmt))) then {};
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.CLASS_EXTENDS(parts = (Absyn.PUBLIC(contents = elts) :: lst),comment = cmt),info = file_info)) /* Search in public list */
      equation
        lst1 = getComponentsInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info));
        lst2 = getComponentsInElementitems(elts);
        res = listAppend(lst2, lst1);
      then
        res;
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.CLASS_EXTENDS(parts = (Absyn.PROTECTED(contents = elts) :: lst),comment = cmt),info = file_info)) /* Search in protected list */
      equation
        lst1 = getComponentsInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info));
        lst2 = getComponentsInElementitems(elts);
        res = listAppend(lst2, lst1);
      then
        res;

    case (_) then {};

  end matchcontinue;
end getComponentsInClass;

protected function getPublicComponentsInClass
"function: getPublicComponentsInClass
   Public lists are searched."
  input Absyn.Class inClass;
  output list<Absyn.Element> outAbsynElementLst;
algorithm
  outAbsynElementLst:=
  matchcontinue (inClass)
    local
      String a;
      Boolean b,c,d;
      Absyn.Restriction e;
      Option<String> cmt;
      list<Absyn.Element> lst1,lst2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> lst;
      Absyn.Info file_info;
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.PARTS(classParts = {},comment = cmt))) then {};
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.PARTS(classParts = (Absyn.PUBLIC(contents = elts) :: lst),comment = cmt),
                      info = file_info)) /* Search in public list */
      equation
        lst1 = getPublicComponentsInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info));
        lst2 = getComponentsInElementitems(elts);
        res = listAppend(lst2, lst1);
      then
        res;
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.PARTS(classParts = (_ :: lst),comment = cmt),
                      info = file_info))
      equation
        res = getPublicComponentsInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info));
      then
        res;

    /* adrpo: handle also the case model extends X end X; */
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.CLASS_EXTENDS(parts = {},comment = cmt))) then {};
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.CLASS_EXTENDS(parts = (Absyn.PUBLIC(contents = elts) :: lst),comment = cmt),
                      info = file_info)) /* Search in public list */
      equation
        lst1 = getPublicComponentsInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info));
        lst2 = getComponentsInElementitems(elts);
        res = listAppend(lst2, lst1);
      then
        res;
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.CLASS_EXTENDS(parts = (_ :: lst),comment = cmt),
                      info = file_info))
      equation
        res = getPublicComponentsInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info));
      then
        res;

    case (_) then {};
  end matchcontinue;
end getPublicComponentsInClass;

protected function getProtectedComponentsInClass
"function: getProtectedComponentsInClass
   Protected lists are searched."
  input Absyn.Class inClass;
  output list<Absyn.Element> outAbsynElementLst;
algorithm
  outAbsynElementLst:=
  matchcontinue (inClass)
    local
      String a;
      Boolean b,c,d;
      Absyn.Restriction e;
      Option<String> cmt;
      list<Absyn.Element> lst1,lst2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> lst;
      Absyn.Info file_info;

    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.PARTS(classParts = {},comment = cmt))) then {};
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.PARTS(classParts = (Absyn.PROTECTED(contents = elts) :: lst),comment = cmt),
                      info = file_info)) /* Search in protected list */
      equation
        lst1 = getProtectedComponentsInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info));
        lst2 = getComponentsInElementitems(elts);
        res = listAppend(lst2, lst1);
      then
        res;
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.PARTS(classParts = (_ :: lst),comment = cmt),
                      info = file_info))
      equation
        res = getProtectedComponentsInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info));
      then
        res;

    /* adrpo: handle also the case model extends X end X; */
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.CLASS_EXTENDS(parts = {},comment = cmt))) then {};
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.CLASS_EXTENDS(parts = (Absyn.PROTECTED(contents = elts) :: lst),comment = cmt),
                      info = file_info)) /* Search in protected list */
      equation
        lst1 = getProtectedComponentsInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info));
        lst2 = getComponentsInElementitems(elts);
        res = listAppend(lst2, lst1);
      then
        res;
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.CLASS_EXTENDS(parts = (_ :: lst),comment = cmt),
                      info = file_info))
      equation
        res = getProtectedComponentsInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info));
      then
        res;

    case (_) then {};
  end matchcontinue;
end getProtectedComponentsInClass;

protected function getComponentsInElementitems
"function: getComponentsInElementitems
  Helper function to getComponentsInClass."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.Element> outAbsynElementLst;
algorithm
  outAbsynElementLst:=
  matchcontinue (inAbsynElementItemLst)
    local
      list<Absyn.Element> res;
      Absyn.Element elt;
      list<Absyn.ElementItem> rest;
    case ({}) then {};
    case ((Absyn.ELEMENTITEM(element = elt) :: rest))
      equation
        res = getComponentsInElementitems(rest);
      then
        (elt :: res);
    case ((_ :: rest))
      equation
        res = getComponentsInElementitems(rest);
      then
        res;
  end matchcontinue;
end getComponentsInElementitems;

protected function getNthComponentInClass
"function: getNthComponentInClass
  Returns the nth Component of a class. Indexed from 1..n."
  input Absyn.Class inClass;
  input Integer inInteger;
  output Absyn.Element outElement;
algorithm
  outElement:=
  matchcontinue (inClass,inInteger)
    local
      Integer count,n,c1,newn;
      Absyn.Element res;
      String a,newnstr;
      Boolean b,c,d;
      Absyn.Restriction e;
      list<Absyn.ElementItem> elt;
      list<Absyn.ClassPart> lst,rest;
      Option<String> cmt;
      Absyn.Info file_info;

    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.PARTS(classParts = (Absyn.PUBLIC(contents = elt) :: lst),comment = cmt),
                      info = file_info),n)
      equation
        count = countComponentsInElts(elt);
        (n <= count) = true;
        res = getNthComponentInElementitems(elt, n);
      then
        res;

    /* The rule above failed, i.e the nth number is larger than # elements in first public list subtract and try next public list */
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.PARTS(classParts = (Absyn.PUBLIC(contents = elt) :: rest),comment = cmt),
                      info = file_info),n)
      equation
        c1 = countComponentsInElts(elt);
        newn = n - c1;
        newnstr = intString(newn);
        (newn > 0) = true;
        res = getNthComponentInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},rest,cmt),file_info),
          newn);
      then
        res;

    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.PARTS(classParts = (Absyn.PROTECTED(contents = elt) :: lst),comment = cmt),
                      info = file_info),n)
      equation
        res = getNthComponentInElementitems(elt, n);
      then
        res;

    /* The rule above failed, i.e the nth number is larger than # elements in first public list subtract and try next public list */
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.PARTS(classParts = (Absyn.PROTECTED(contents = elt) :: rest),comment = cmt),
                      info = file_info),n)
      equation
        c1 = countComponentsInElts(elt);
        newn = n - c1;
        (newn > 0) = true;
        res = getNthComponentInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},rest,cmt),file_info), newn);
      then
        res;

    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.PARTS(classParts = (_ :: lst),comment = cmt),
                      info = file_info),n)
      equation
        res = getNthComponentInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info), n);
      then
        res;

    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.PARTS(classParts = {},comment = cmt),info = file_info),_)
      then fail();

    /* adrpo: handle also the case model extends X end X; */
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.CLASS_EXTENDS(parts = (Absyn.PUBLIC(contents = elt) :: lst),comment = cmt),
                      info = file_info),n)
      equation
        count = countComponentsInElts(elt);
        (n <= count) = true;
        res = getNthComponentInElementitems(elt, n);
      then
        res;

    /* adrpo: handle also the case model extends X end X; */
    /* The rule above failed, i.e the nth number is larger than # elements in first public list subtract and try next public list */
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.CLASS_EXTENDS(parts = (Absyn.PUBLIC(contents = elt) :: rest),comment = cmt),
                      info = file_info),n)
      equation
        c1 = countComponentsInElts(elt);
        newn = n - c1;
        newnstr = intString(newn);
        (newn > 0) = true;
        res = getNthComponentInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},rest,cmt),file_info),
          newn);
      then
        res;

    /* adrpo: handle also the case model extends X end X; */
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.CLASS_EXTENDS(parts = (Absyn.PROTECTED(contents = elt) :: lst),comment = cmt),
                      info = file_info),n)
      equation
        res = getNthComponentInElementitems(elt, n);
      then
        res;

    /* adrpo: handle also the case model extends X end X; */
    /* The rule above failed, i.e the nth number is larger than # elements in first public list subtract and try next public list */
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.CLASS_EXTENDS(parts = (Absyn.PROTECTED(contents = elt) :: rest),comment = cmt),
                      info = file_info),n)
      equation
        c1 = countComponentsInElts(elt);
        newn = n - c1;
        (newn > 0) = true;
        res = getNthComponentInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},rest,cmt),file_info), newn);
      then
        res;

    /* adrpo: handle also the case model extends X end X; */
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.CLASS_EXTENDS(parts = (_ :: lst),comment = cmt),
                      info = file_info),n)
      equation
        res = getNthComponentInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info), n);
      then
        res;

    /* adrpo: handle also the case model extends X end X; */
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.CLASS_EXTENDS(parts = {},comment = cmt),info = file_info),_)
      then fail();


    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.DERIVED(typeSpec = _),info = file_info),_)
      then fail();
  end matchcontinue;
end getNthComponentInClass;

public function getDefineunitsInElements "retrives defineunit definitions in elements"
  input list<Absyn.ElementItem> elts;
  output list<Absyn.Element> outElts;
algorithm
  outElts := matchcontinue(elts)
  local Absyn.Element e;
    case({}) then {};
    case(Absyn.ELEMENTITEM(e as Absyn.DEFINEUNIT(name=_))::elts) equation
      outElts = getDefineunitsInElements(elts);
    then e::outElts;
    case(_::elts) equation
      outElts = getDefineunitsInElements(elts);
    then outElts;
  end matchcontinue;
end getDefineunitsInElements;

public function getElementitemsInClass
"function: getElementitemsInClass
   Both public and protected lists are searched."
  input Absyn.Class inClass;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm
  outAbsynElementItemLst:=
  matchcontinue (inClass)
    local
      String a;
      Boolean b,c,d;
      Absyn.Restriction e;
      Option<String> cmt;
      list<Absyn.ElementItem> lst1,elts;
      list<Absyn.ClassPart> lst;
      Absyn.Info file_info;

    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.PARTS(classParts = {},comment = cmt)))
       then {};
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.PARTS(classParts = (Absyn.PUBLIC(contents = elts) :: lst),comment = cmt),
                      info = file_info)) /* Search in public list */
      equation
        lst1 = getElementitemsInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info));
        lst1 = listAppend(elts, lst1);
      then
        lst1;
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.PARTS(classParts = (Absyn.PROTECTED(contents = elts) :: lst),comment = cmt),
                      info = file_info)) /* Search in protected list */
      equation
        lst1 = getElementitemsInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info));
        lst1 = listAppend(elts, lst1);
      then
        lst1;

    /* adrpo: handle also the case model extends X end X; */
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.CLASS_EXTENDS(parts = {},comment = cmt)))
       then {};
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.CLASS_EXTENDS(parts = (Absyn.PUBLIC(contents = elts) :: lst),comment = cmt),
                      info = file_info)) /* Search in public list */
      equation
        lst1 = getElementitemsInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info));
        lst1 = listAppend(elts, lst1);
      then
        lst1;
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.CLASS_EXTENDS(parts = (Absyn.PROTECTED(contents = elts) :: lst),comment = cmt),
                      info = file_info)) /* Search in protected list */
      equation
        lst1 = getElementitemsInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},lst,cmt),file_info));
        lst1 = listAppend(elts, lst1);
      then
        lst1;

    case (_) then {};
  end matchcontinue;
end getElementitemsInClass;

protected function getNthComponentInElementitems
"function: getNthComponentInElementitems
   This function takes an ElementItem list and and integer
   and returns the nth component in the list, indexed from 1..n."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Integer inInteger;
  output Absyn.Element outElement;
algorithm
  outElement:=
  matchcontinue (inAbsynElementItemLst,inInteger)
    local
      Boolean a;
      Option<Absyn.RedeclareKeywords> b;
      Absyn.InnerOuter c;
      String d;
      Absyn.ElementAttributes e;
      Absyn.TypeSpec f;
      Absyn.ComponentItem item;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> i;
      Integer numcomps,newn,n,n_1;
      Absyn.Element res;
      list<Absyn.ComponentItem> lst;
      list<Absyn.ElementItem> rest;

    case ((Absyn.ELEMENTITEM(element =
      Absyn.ELEMENT(finalPrefix = a,redeclareKeywords = b,innerOuter = c,name = d,
                    specification = Absyn.COMPONENTS(attributes = e,typeSpec = f,components = (item::_)),
                    info = info,constrainClass = i)) :: _),1)
      then
        Absyn.ELEMENT(a,b,c,d,Absyn.COMPONENTS(e,f,{item}),info,i);

    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = lst))) :: rest),n)
      equation
        numcomps = listLength(lst);
        (n > numcomps) = true;
        newn = n - numcomps;
        res = getNthComponentInElementitems(rest, newn);
      then
        res;

    case ((Absyn.ELEMENTITEM(element =
      (Absyn.ELEMENT(finalPrefix = a,redeclareKeywords = b,innerOuter = c,name = d,
                     specification = Absyn.COMPONENTS(attributes = e,typeSpec = f,components = lst),
                     info = info,constrainClass = i))) :: rest),n)
      equation
        numcomps = listLength(lst);
        (n <= numcomps) = true;
        n_1 = n - 1;
        item = listNth(lst, n_1);
      then
        Absyn.ELEMENT(a,b,c,d,Absyn.COMPONENTS(e,f,{item}),info,i);

    case ((_ :: rest),n)
      equation
        res = getNthComponentInElementitems(rest, n);
      then
        res;

    case ({},_) then fail();

  end matchcontinue;
end getNthComponentInElementitems;

protected function getComponentInfo
"function: getComponentInfo
   This function takes an Element and returns a list of strings
   of comma separated values of the type and name and comment,
   and attributes of  of the component, If Element is not a
   component, the empty string is returned.
   inputs: (Absyn.Element, string, /* public or protected */, Env.Env)
   outputs: string list"
  input Absyn.Element inElement;
  input Boolean inBoolean;
  input String inString;
  input Env.Env inEnv;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inElement,inBoolean,inString,inEnv)
    local
      SCode.Element c;
      list<Env.Frame> env_1,env;
      Absyn.Path envpath,p_1,p;
      String tpname,typename,finalPrefix,repl,inout_str,flowPrefixstr,streamPrefixstr,variability_str,parallelism_str,dir_str,str,access;
      String typeAdStr;
      list<Absyn.ComponentItem> lst;
      list<String> names,lst_1,dims,strLst;
      Boolean r_1,f,b;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter inout;
      Absyn.ElementAttributes attr;
      Option<Absyn.ArrayDim> typeAd;

    case (Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = inout,
                        specification = Absyn.COMPONENTS(attributes = attr,typeSpec = Absyn.TPATH(p, typeAd),components = lst)),
          b,access,env)
      equation
        (_,c,env_1) = Lookup.lookupClass(Env.emptyCache(),env, p, false);
        SOME(envpath) = Env.getEnvPath(env_1);
        tpname = Absyn.pathLastIdent(p);
        p_1 = Absyn.joinPaths(envpath, Absyn.IDENT(tpname));
        typename = Absyn.pathString(p_1);
        typename = Util.if_(b,stringAppendList({"\"",typename,"\""}),typename);
        names = getComponentitemsName(lst,b);
        dims = getComponentitemsDimension(lst);
        strLst = prefixTypename(typename, names);
        finalPrefix = boolString(f);
        finalPrefix = Util.if_(b,stringAppendList({"\"",finalPrefix,"\""}),finalPrefix);
        r_1 = keywordReplaceable(r);
        repl = boolString(r_1);
        repl = Util.if_(b,stringAppendList({"\"",repl,"\""}),repl);
        inout_str = innerOuterStr(inout);
        flowPrefixstr = attrFlowStr(attr);
        flowPrefixstr = Util.if_(b,stringAppendList({"\"",flowPrefixstr,"\""}),flowPrefixstr);
        streamPrefixstr = attrStreamStr(attr);
        streamPrefixstr = Util.if_(b,stringAppendList({"\"",streamPrefixstr,"\""}),streamPrefixstr);
        // parallelism_str = attrParallelismStr(attr);
        variability_str = attrVariabilityStr(attr);
        dir_str = attrDirectionStr(attr);
        typeAdStr = arrayDimensionStr(typeAd);
        typeAdStr =  attrDimensionStr(attr);
        str = stringDelimitList({access,finalPrefix,flowPrefixstr,streamPrefixstr,repl,/*parallelism_str,*/variability_str,inout_str,dir_str}, ", ");
        lst_1 = suffixInfos(strLst,dims,typeAdStr,str,b);
      then
        lst_1;

    case (Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = inout,
                        specification = Absyn.COMPONENTS(attributes = attr,typeSpec = Absyn.TPATH(p, typeAd),components = lst)),
          b,access,env)
      equation
        typename = Absyn.pathString(p);
        typename = Util.if_(b,stringAppendList({"\"",typename,"\""}),typename);
        names = getComponentitemsName(lst,b);
        dims = getComponentitemsDimension(lst);
        strLst = prefixTypename(typename, names);
        finalPrefix = boolString(f);
        finalPrefix = Util.if_(b,stringAppendList({"\"",finalPrefix,"\""}),finalPrefix);
        r_1 = keywordReplaceable(r);
        repl = boolString(r_1);
        repl = Util.if_(b,stringAppendList({"\"",repl,"\""}),repl);
        inout_str = innerOuterStr(inout);
        flowPrefixstr = attrFlowStr(attr);
        flowPrefixstr = Util.if_(b,stringAppendList({"\"",flowPrefixstr,"\""}),flowPrefixstr);
        streamPrefixstr = attrStreamStr(attr);
        streamPrefixstr = Util.if_(b,stringAppendList({"\"",streamPrefixstr,"\""}),streamPrefixstr);
        //parallelism_str = attrParallelismStr(attr);
        variability_str = attrVariabilityStr(attr);
        dir_str = attrDirectionStr(attr);
        str = stringDelimitList({access,finalPrefix,flowPrefixstr,streamPrefixstr,repl,/*parallelism_str,*/variability_str,inout_str,dir_str}, ", ");
        typeAdStr =  attrDimensionStr(attr);
        lst_1 = suffixInfos(strLst,dims,typeAdStr,str,b);
      then
        lst_1;

    case (_,_,_,env) then {};

    case (_,_,_,_)
      equation
        print("Interactive.getComponentInfo failed\n");
      then
        fail();
  end matchcontinue;
end getComponentInfo;

protected function arrayDimensionStr
"function arrayDimensionStr
  prints array dimensions to a string"
  input Option<Absyn.ArrayDim> ad;
  output String str;
algorithm
  str:=matchcontinue(ad)
  local Absyn.ArrayDim adim;
    case(SOME(adim)) equation
      str = stringDelimitList(List.map(adim,Dump.printSubscriptStr),",");
    then str;
    case(_) then "";
  end matchcontinue;
end arrayDimensionStr;


protected function getComponentsInfo
"function: getComponentsInfo
  Helper function to get_components.
  Return all the info as a comma separated list of values.
  get_component_info => {{name, type, comment, access, final, flow, stream, replaceable, variability,innerouter,vardirection},..}
  where access is one of: \"public\", \"protected\"
  where final is one of: true, false
  where flow is one of: true, false
  where flow is one of: true, false
  where stream is one of: true, false
  where replaceable is one of: true, false
  where parallelism is one of: \"parglobal\", \"parlocal\", \"unspecified\"
  where variability is one of: \"constant\", \"parameter\", \"discrete\" or \"unspecified\"
  where innerouter is one of: \"inner\", \"outer\", (\"innerouter\") or \"none\"
  where vardirection is one of: \"input\", \"output\" or \"unspecified\".
  inputs:  (Absyn.Element list, string /* \"public\" or \"protected\" */, Env.Env)
  outputs:  string"
  input list<Absyn.Element> inAbsynElementLst;
  input Boolean inBoolean;
  input String inString;
  input Env.Env inEnv;
  output String outString;
algorithm
  outString:=
  matchcontinue (inAbsynElementLst,inBoolean,inString,inEnv)
    local
      list<String> lst;
      String lst_1,res,access;
      list<Absyn.Element> elts;
      list<Env.Frame> env;
      Boolean b;
    case (elts,b,access,env)
      equation
        ((lst as (_ :: _))) = getComponentsInfo2(elts, inBoolean, access, env);
        lst_1 = stringDelimitList(lst, "},{");
        res = stringAppendList({"{",lst_1,"}"});
      then
        res;
    case (_,_,_,_) then "";
  end matchcontinue;
end getComponentsInfo;

protected function getComponentsInfo2
"function: getComponentsInfo2
  Helper function to getComponentsInfo
  inputs: (Absyn.Element list, string /* \"public\" or \"protected\" */, Env.Env)
  outputs: string list"
  input list<Absyn.Element> inAbsynElementLst;
  input Boolean inBoolean;
  input String inString;
  input Env.Env inEnv;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  match (inAbsynElementLst,inBoolean,inString,inEnv)
    local
      list<String> lst1,lst2,res;
      Absyn.Element elt;
      list<Absyn.Element> rest;
      String access;
      list<Env.Frame> env;
      Boolean b;
    case ({},_,_,_) then {};
    case ((elt :: rest),b,access,env)
      equation
        lst1 = getComponentInfo(elt, b, access, env);
        lst2 = getComponentsInfo2(rest, b, access, env);
        res = listAppend(lst1, lst2);
      then
        res;
  end match;
end getComponentsInfo2;

protected function keywordReplaceable
"function: keywordReplaceable
  Returns true if RedeclareKeywords contains replaceable."
  input Option<Absyn.RedeclareKeywords> inAbsynRedeclareKeywordsOption;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inAbsynRedeclareKeywordsOption)
    case (SOME(Absyn.REPLACEABLE())) then true;
    case (SOME(Absyn.REDECLARE_REPLACEABLE())) then true;
    case (_) then false;
  end matchcontinue;
end keywordReplaceable;

protected function getComponentInfoOld
"function: getComponentInfoOld
   This function takes an `Element\' and returns a list of strings
   of comma separated values of the type and name and comment of
   the component, e.g. \'Resistor,R1, \"comment\"\'
   or \'Resistor,R1,\"comment1\",R2,\"comment2\"\'
   If Element is not a component, the empty string is returned"
  input Absyn.Element inElement;
  input Env.Env inEnv;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inElement,inEnv)
    local
      SCode.Element c;
      list<Env.Frame> env_1,env;
      Absyn.Path envpath,p_1,p;
      String tpname,typename;
      list<Absyn.ComponentItem> lst;
      list<String> names,strList;
      Boolean f;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter inout;
      Absyn.ElementAttributes attr;

    case (Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = inout,
                        specification = Absyn.COMPONENTS(attributes = attr,typeSpec = Absyn.TPATH(p, _),components = lst)),
          env)
      equation
        (_,c,env_1) = Lookup.lookupClass(Env.emptyCache(),env, p, true);
        SOME(envpath) = Env.getEnvPath(env_1);
        tpname = Absyn.pathLastIdent(p);
        p_1 = Absyn.joinPaths(envpath, Absyn.IDENT(tpname));
        typename = Absyn.pathString(p_1);
        names = getComponentitemsName(lst,false);
        strList = prefixTypename(typename, names);
      then
        strList;

    case (Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = inout,
                        specification = Absyn.COMPONENTS(attributes = attr,typeSpec = Absyn.TPATH(p, _),components = lst)),
          env)
      equation
        typename = Absyn.pathString(p);
        names = getComponentitemsName(lst,false);
        strList = prefixTypename(typename, names);
      then
        strList;

    case (_,env) then {};

    case (_,_)
      equation
        print("Interactive.getComponentInfoOld failed\n");
      then
        fail();
  end matchcontinue;
end getComponentInfoOld;

protected function innerOuterStr
"function: innerOuterStr
  Helper function to getComponentInfo, retrieve the inner outer string."
  input Absyn.InnerOuter inInnerOuter;
  output String outString;
algorithm
  outString:=
  match (inInnerOuter)
    case (Absyn.INNER()) then "\"inner\"";
    case (Absyn.OUTER()) then "\"outer\"";
    case (Absyn.NOT_INNER_OUTER()) then "\"none\"";
    case (Absyn.INNER_OUTER()) then "\"innerouter\"";
  end match;
end innerOuterStr;

protected function attrFlowStr
"function: attrFlowStr
  Helper function to get_component_info,
  retrieve flow attribite as bool string."
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm
  outString:=
  match (inElementAttributes)
    local
      String res;
      Boolean f;
    case (Absyn.ATTR(flowPrefix = f))
      equation
        res = boolString(f);
      then
        res;
  end match;
end attrFlowStr;

protected function attrStreamStr
"function: attrStreamStr
  Helper function to get_component_info,
  retrieve stream attribute as bool string."
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm
  outString:=
  match (inElementAttributes)
    local
      String res;
      Boolean s;
    case (Absyn.ATTR(streamPrefix = s))
      equation
        res = boolString(s);
      then
        res;
  end match;
end attrStreamStr;

protected function attrParallelismStr
"function: attrParallelismStr
  Helper function to get_component_info,
  retrieve parallelism as a string."
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm
  outString:=
  match (inElementAttributes)
    case (Absyn.ATTR(parallelism = Absyn.PARGLOBAL())) then "\"parglobal\"";
    case (Absyn.ATTR(parallelism = Absyn.PARLOCAL())) then "\"parlocal\"";
    case (Absyn.ATTR(parallelism = Absyn.NON_PARALLEL())) then "";
  end match;
end attrParallelismStr;

protected function attrVariabilityStr
"function: attrVariabilityStr
  Helper function to get_component_info,
  retrieve variability as a string."
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm
  outString:=
  match (inElementAttributes)
    case (Absyn.ATTR(variability = Absyn.VAR())) then "\"unspecified\"";
    case (Absyn.ATTR(variability = Absyn.DISCRETE())) then "\"discrete\"";
    case (Absyn.ATTR(variability = Absyn.PARAM())) then "\"parameter\"";
    case (Absyn.ATTR(variability = Absyn.CONST())) then "\"constant\"";
  end match;
end attrVariabilityStr;

protected function attrDimensionStr
"function attrDimensionStr
  Helper function to getComponentInfo,
  retrieve dimension as a string."
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm
  outString:=
  match (inElementAttributes)
      local Absyn.ArrayDim ad;
    case (Absyn.ATTR(arrayDim = ad)) then arrayDimensionStr(SOME(ad));
  end match;
end attrDimensionStr;

protected function attrDirectionStr
"function: attrDirectionStr
  Helper function to get_component_info,
  retrieve direction as a string."
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm
  outString:=
  match (inElementAttributes)
    case (Absyn.ATTR(direction = Absyn.INPUT())) then "\"input\"";
    case (Absyn.ATTR(direction = Absyn.OUTPUT())) then "\"output\"";
    case (Absyn.ATTR(direction = Absyn.BIDIR())) then "\"unspecified\"";
  end match;
end attrDirectionStr;

protected function getComponentitemsDimension
"function getComponentitemsDimension
  helper function to getComponentInfo
  Retrieves the dimensions of a list of components as a list of strings."
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inAbsynComponentItemLst)
    local
      String str;
      list<String> lst,res;
      Absyn.ComponentItem c2;
      list<Absyn.ComponentItem> rest;
      Absyn.ArrayDim ad;
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(arrayDim=ad))) :: (c2 :: rest))
      equation
        lst = getComponentitemsName((c2 :: rest),false);
        str = stringDelimitList(List.map(ad,Dump.printSubscriptStr),",");
      then (str :: lst);
    case ((_ :: rest))
      equation
        res = getComponentitemsName(rest,false);
      then
        res;
    case ({Absyn.COMPONENTITEM(component = Absyn.COMPONENT(arrayDim = ad))})
      equation
        str = stringDelimitList(List.map(ad,Dump.printSubscriptStr),",");
      then
        {str};
    case ({_}) then {};
  end matchcontinue;
end getComponentitemsDimension;

protected function suffixInfos
"function: suffixInfos
  Helper function to getComponentInfo.
  Add suffix info (from each component) to element names, dimensions, etc."
  input list<String> eltInfo;
  input list<String> idims;
  input String typeAd;
  input String suffix;
  input Boolean inBoolean;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  match (eltInfo,idims,typeAd,suffix,inBoolean)
    local
      list<String> res,rest,dims;
      String str_1,str;
      String dim,s1;
      Boolean b;
    case ({},{},_,_,_) then {};
    case ((str :: rest),dim::dims,typeAd,suffix,b)
      equation
        res = suffixInfos(rest, dims,typeAd,suffix,b);
        s1 = Util.stringDelimitListNonEmptyElts({dim,typeAd},",");
        str_1 = Util.if_(b,stringAppendList({str,", ",suffix,",\"{",s1,"}\""}),stringAppendList({str,", ",suffix,",{",s1,"}"}));
      then
        (str_1 :: res);
  end match;
end suffixInfos;

protected function prefixTypename
"function: prefixTypename
  Helper function to getComponentInfo. Add a prefix typename to each string in the list."
  input String inString;
  input list<String> inStringLst;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  match (inString,inStringLst)
    local
      list<String> res,rest;
      String str_1,tp,str;
    case (_,{}) then {};
    case (tp,(str :: rest))
      equation
        res = prefixTypename(tp, rest);
        str_1 = stringAppendList({tp,",",str});
      then
        (str_1 :: res);
  end match;
end prefixTypename;

public function getComponentitemsName
"function getComponentitemsName
   This function takes a ComponentItems list and returns a comma
   separated list of all component names and comments (if any)."
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Boolean inBoolean;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inAbsynComponentItemLst,inBoolean)
    local
      String str,c1,s2;
      list<String> lst,res;
      Absyn.ComponentItem c2;
      list<Absyn.ComponentItem> rest;
      Boolean b;
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = c1),comment = SOME(Absyn.COMMENT(_,SOME(s2)))) :: (c2 :: rest)),b)
      equation
        lst = getComponentitemsName((c2 :: rest),b);
        str = Util.if_(b,stringAppendList({"\"", c1, "\"", ",", "\"", s2, "\""}),stringAppendList({c1, ",", "\"", s2, "\""}));
      then
        (str :: lst);
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = c1),comment = NONE()) :: (c2 :: rest)),b)
      equation
        lst = getComponentitemsName((c2 :: rest),b);
        str = Util.if_(b,stringAppendList({"\"", c1, "\"", ",", "\"\""}),stringAppendList({c1, ",", "\"\""}));
      then
        (str :: lst);
    case ((_ :: rest),b)
      equation
        res = getComponentitemsName(rest,b);
      then
        res;
    case ({Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = c1),comment = SOME(Absyn.COMMENT(_,SOME(s2))))},b)
      equation
        str = Util.if_(b,stringAppendList({"\"", c1, "\"", ",", "\"", s2, "\""}),stringAppendList({c1, ",", "\"", s2, "\""}));
      then
        {str};
    case ({Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = c1))},b)
      equation
        str = Util.if_(b,stringAppendList({"\"", c1, "\"", ",", "\"\""}),stringAppendList({c1, ",", "\"\""}));
      then
        {str};
    case ({_},_) then {};
  end matchcontinue;
end getComponentitemsName;

public function addToPublic
"function: addToPublic
   This function takes a Class definition and adds an
   ElementItem to the first public list in the class.
   If no public list is available in the class one is created."
  input Absyn.Class inClass;
  input Absyn.ElementItem inElementItem;
  output Absyn.Class outClass;
algorithm
  outClass:=
  matchcontinue (inClass,inElementItem)
    local
      list<Absyn.ElementItem> publst,publst2;
      list<Absyn.ClassPart> parts2,parts;
      String i, baseClassName;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      Absyn.Info file_info;
      Absyn.ElementItem eitem;
      list<Absyn.ElementArg> modifications;
      list<String> typeVars;
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars,classParts = parts,comment = cmt),
                      info = file_info),eitem)
      equation
        publst = getPublicList(parts);
        publst2 = listAppend(publst, {eitem});
        parts2 = replacePublicList(parts, publst2);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(typeVars,parts2,cmt),file_info);
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars,classParts = parts,comment = cmt),
                      info = file_info),eitem)
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(typeVars,(Absyn.PUBLIC({eitem}) :: parts),cmt),file_info);
    /* adrpo: handle also the case model extends X end X; */
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName = baseClassName,
                                                 modifications = modifications,
                                                 comment = cmt,
                                                 parts = parts),
                      info = file_info),eitem)
      equation
        publst = getPublicList(parts);
        publst2 = listAppend(publst, {eitem});
        parts2 = replacePublicList(parts, publst2);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.CLASS_EXTENDS(baseClassName,modifications,cmt,parts2),file_info);
    /* adrpo: handle also the case model extends X end X; */
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName = baseClassName,
                                                 modifications = modifications,
                                                 comment = cmt,
                                                 parts = parts),
                      info = file_info),eitem)
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.CLASS_EXTENDS(baseClassName,modifications,cmt,(Absyn.PUBLIC({eitem}) :: parts)),file_info);
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.DERIVED(typeSpec = _),info = file_info),eitem)
      then fail();
  end matchcontinue;
end addToPublic;

protected function addToProtected
"function: addToProtected
   This function takes a Class definition and adds an
   ElementItem to the first protected list in the class.
   If no protected list is available in the class one is created."
  input Absyn.Class inClass;
  input Absyn.ElementItem inElementItem;
  output Absyn.Class outClass;
algorithm
  outClass:=
  matchcontinue (inClass,inElementItem)
    local
      list<Absyn.ElementItem> protlst,protlst2;
      list<Absyn.ClassPart> parts2,parts;
      String i, baseClassName;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      Absyn.Info file_info;
      Absyn.ElementItem eitem;
      list<Absyn.ElementArg> modifications;
      list<String> typeVars;

    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars, classParts = parts,comment = cmt),
                      info = file_info),eitem)
      equation
        protlst = getProtectedList(parts);
        protlst2 = listAppend(protlst, {eitem});
        parts2 = replaceProtectedList(parts, protlst2);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(typeVars,parts2,cmt),file_info);

    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars,classParts = parts,comment = cmt),
                      info = file_info),eitem)
      then Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(typeVars,(Absyn.PROTECTED({eitem}) :: parts),cmt),file_info);

    /* adrpo: handle also the case model extends X end X; */
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName = baseClassName,
                                                 modifications = modifications,
                                                 comment = cmt,
                                                 parts = parts),
                      info = file_info),eitem)
      equation
        protlst = getProtectedList(parts);
        protlst2 = listAppend(protlst, {eitem});
        parts2 = replaceProtectedList(parts, protlst2);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.CLASS_EXTENDS(baseClassName,modifications,cmt,parts2),file_info);

    /* adrpo: handle also the case model extends X end X; */
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName = baseClassName,
                                                 modifications = modifications,
                                                 comment = cmt,
                                                 parts = parts),
                      info = file_info),eitem)
      then Absyn.CLASS(i,p,f,e,r,Absyn.CLASS_EXTENDS(baseClassName,modifications,cmt,(Absyn.PROTECTED({eitem}) :: parts)),file_info);

    /* handle the model X = Y case */
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.DERIVED(typeSpec = _),info =
                      file_info),eitem)
      then fail();
  end matchcontinue;
end addToProtected;

protected function addToEquation
"function: addToEquation
   This function takes a Class definition and adds an
   EquationItem to the first equation list in the class.
   If no public list is available in the class one is created."
  input Absyn.Class inClass;
  input Absyn.EquationItem inEquationItem;
  output Absyn.Class outClass;
algorithm
  outClass:=
  matchcontinue (inClass,inEquationItem)
    local
      list<Absyn.EquationItem> eqlst,eqlst2;
      list<Absyn.ClassPart> parts2,parts,newparts;
      String i, baseClassName;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      Absyn.Info file_info;
      Absyn.EquationItem eitem;
      list<Absyn.ElementArg> modifications;
      list<String> typeVars;

    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars, classParts = parts,comment = cmt),
                      info = file_info),eitem)
      equation
        eqlst = getEquationList(parts);
        eqlst2 = (eitem :: eqlst);
        parts2 = replaceEquationList(parts, eqlst2);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(typeVars,parts2,cmt),file_info);

    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars, classParts = parts,comment = cmt),
                      info = file_info),eitem)
      equation
        newparts = listAppend(parts, {Absyn.EQUATIONS({eitem})}) "Add the equations last, to make nicer output if public section present" ;
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(typeVars,newparts,cmt),file_info);

    /* adrpo: handle also the case model extends X end X; */
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName = baseClassName,
                                                 modifications = modifications,
                                                 comment = cmt,
                                                 parts = parts),
                      info = file_info),eitem)
      equation
        eqlst = getEquationList(parts);
        eqlst2 = (eitem :: eqlst);
        parts2 = replaceEquationList(parts, eqlst2);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.CLASS_EXTENDS(baseClassName,modifications,cmt,parts2),file_info);

    /* adrpo: handle also the case model extends X end X; */
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName = baseClassName,
                                                 modifications = modifications,
                                                 comment = cmt,
                                                 parts = parts),
                      info = file_info),eitem)
      equation
        newparts = listAppend(parts, {Absyn.EQUATIONS({eitem})}) "Add the equations last, to make nicer output if public section present" ;
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.CLASS_EXTENDS(baseClassName,modifications,cmt,newparts),file_info);

    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.DERIVED(typeSpec = _),info = file_info),eitem)
      then fail();

  end matchcontinue;
end addToEquation;

protected function buildPath
"function: buildPath
  Helper function to replaceClassInProgram.
  Takes a programs 'within' and a ident, and creates a path out of it."
  input Absyn.Within inWithin;
  input Absyn.Path inPath;
  output Absyn.Path outPath;
algorithm
  outPath :=
  match (inWithin,inPath)
    local Absyn.Path p, p1, p2;
    case (Absyn.TOP(), p) then p;
    case (Absyn.WITHIN(path = p),p1) equation p2 = Absyn.joinPaths(p, p1); then p2;
  end match;
end buildPath;

protected function replaceClassInProgram
"function: replaceClassInProgram
   This function takes a Class and a Program and replaces the class
   definition at the top level in the program by the class definition of
   the Class. It also updates the functionlist for the symboltable if needed."
  input Absyn.Class inClass;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
algorithm
  outProgram := matchcontinue (inClass,inProgram)
    local
      Absyn.Class c,c1;
      Absyn.Within w;
      String name1,name2;
      list<Absyn.Class> clst,newclst;
      Absyn.Program p;
      Absyn.Path cp;
      Absyn.TimeStamp ts, newTs;

    case (c,Absyn.PROGRAM(classes = {},within_ = w,globalBuildTimes=ts)) then Absyn.PROGRAM({c},w,ts);
    case ((c as Absyn.CLASS(name = name1)),Absyn.PROGRAM(classes = ((c1 as Absyn.CLASS(name = name2)) :: clst),within_ = w,globalBuildTimes=ts))
      equation
        true = stringEq(name1, name2);
        cp = buildPath(w, Absyn.IDENT(name2));
      then
        Absyn.PROGRAM((c :: clst),w,ts);
    case ((c as Absyn.CLASS(name = name1)),Absyn.PROGRAM(classes = ((c1 as Absyn.CLASS(name = name2)) :: clst),within_ = w,globalBuildTimes=ts))
      equation
        false = stringEq(name1, name2);
        Absyn.PROGRAM(newclst,w,newTs) = replaceClassInProgram(c, Absyn.PROGRAM(clst,w,ts));
      then
        Absyn.PROGRAM((c1 :: newclst),w,newTs);
    case (c,p as Absyn.PROGRAM(globalBuildTimes=ts))
      equation
        true = Flags.isSet(Flags.DUMP);
        Print.printBuf("Interactive.replaceClassInProgram failed \n class:");
        Dump.dump(Absyn.PROGRAM({c}, Absyn.TOP(), ts));
        Print.printBuf("\nprogram: \n");
        Dump.dump(p);
      then
        fail();
  end matchcontinue;
end replaceClassInProgram;

protected function insertClassInProgram
"function: insertClassInProgram
   This function inserts the class into the Program at the scope given by
   the within argument. If the class referenced by the within argument is
   not defined, the function prints an error message and fails."
  input Absyn.Class inClass;
  input Absyn.Within inWithin;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
algorithm
  outProgram := matchcontinue (inClass,inWithin,inProgram)
    local
      Absyn.Class c2,c3,c1;
      Absyn.Program pnew,p;
      Absyn.Within w;
      String n1,s1,s2,name;
      Absyn.TimeStamp ts;
      list<Absyn.Path> paths;

    case (c1,(w as Absyn.WITHIN(path = Absyn.QUALIFIED(name = n1))),p as Absyn.PROGRAM(globalBuildTimes=ts))
      equation
        c2 = getClassInProgram(n1, p);
        c3 = insertClassInClass(c1, w, c2);
        pnew = updateProgram(Absyn.PROGRAM({c3},Absyn.TOP(),ts), p);
      then
        pnew;
    case (c1,(w as Absyn.WITHIN(path = Absyn.IDENT(name = n1))),p as Absyn.PROGRAM(globalBuildTimes=ts))
      equation
        c2 = getClassInProgram(n1, p);
        c3 = insertClassInClass(c1, w, c2);
        pnew = updateProgram(Absyn.PROGRAM({c3},Absyn.TOP(),ts), p);
      then
        pnew;
    case ((c1 as Absyn.CLASS(name = name)),w,p)
      equation
        s1 = Dump.unparseWithin(0, w);
        /* adeas31 2012-01-25: false indicates that the classnamesrecursive doesn't look into protected sections */
        (_,paths) = getClassNamesRecursive(NONE(), p, false, {});
        s2 = stringAppendList(List.map1r(List.map(paths,Absyn.pathString),stringAppend,"\n  "));
        Error.addMessage(Error.INSERT_CLASS, {name,s1,s2});
      then
        fail();
  end matchcontinue;
end insertClassInProgram;

protected function insertClassInClass "function: insertClassInClass

   This function takes a class to update (the first argument)  and an inner
   class (which is either replacing
   an earlier class or is a new inner definition) and a within statement
   pointing inside the class (including the class itself in the reference),
   and updates the class with the inner class.
"
  input Absyn.Class inClass1;
  input Absyn.Within inWithin2;
  input Absyn.Class inClass3;
  output Absyn.Class outClass;
algorithm
  outClass:=
  matchcontinue (inClass1,inWithin2,inClass3)
    local
      Absyn.Class cnew,c1,c2,cinner,cnew_1;
      String name,name2;
      Absyn.Path path;
    case (c1,Absyn.WITHIN(path = Absyn.IDENT(name = name)),c2)
      equation
        cnew = replaceInnerClass(c1, c2);
      then
        cnew;
    case (c1,Absyn.WITHIN(path = Absyn.QUALIFIED(name = name,path = path)),c2)
      equation
        name2 = getFirstIdentFromPath(path);
        cinner = getInnerClass(c2, name2);
        cnew = insertClassInClass(c1, Absyn.WITHIN(path), cinner);
        cnew_1 = replaceInnerClass(cnew, c2);
      then
        cnew_1;
    case (_,_,_)
      equation
        Print.printBuf("insert_class_in_class failed\n");
      then
        fail();
  end matchcontinue;
end insertClassInClass;

protected function getFirstIdentFromPath "function: getFirstIdentFromPath

   This function takes a `Path` as argument and returns the first `Ident\'
   of the path.
"
  input Absyn.Path inPath;
  output Absyn.Ident outIdent;
algorithm
  outIdent:=
  match (inPath)
    local
      String name;
      Absyn.Path path;
    case (Absyn.IDENT(name = name)) then name;
    case (Absyn.QUALIFIED(name = name,path = path)) then name;
  end match;
end getFirstIdentFromPath;

protected function removeInnerClass "function: removeInnerClass

   This function takes two class definitions. The first one is the local
   class that should be removed from the second one.
"
  input Absyn.Class inClass1;
  input Absyn.Class inClass2;
  output Absyn.Class outClass;
algorithm
  outClass:=
  matchcontinue (inClass1,inClass2)
    local
      list<Absyn.ElementItem> publst,publst2;
      list<Absyn.ClassPart> parts2,parts;
      Absyn.Class c1;
      String a,bcname;
      Boolean b,c,d;
      Absyn.Restriction e;
      Option<String> cmt;
      Absyn.Info file_info;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
    /* a class with parts */
    case (c1,Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                         body = Absyn.PARTS(typeVars = typeVars, classParts = parts,comment = cmt),info = file_info))
      equation
        publst = getPublicList(parts);
        publst2 = removeClassInElementitemlist(publst, c1);
        parts2 = replacePublicList(parts, publst2);
      then
        Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(typeVars,parts2,cmt),file_info);
    /* an extended class with parts: model extends M end M; */
    case (c1,Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                         body = Absyn.CLASS_EXTENDS(baseClassName=bcname,modifications=modif,parts = parts,comment = cmt),info = file_info))
      equation
        publst = getPublicList(parts);
        publst2 = removeClassInElementitemlist(publst, c1);
        parts2 = replacePublicList(parts, publst2);
      then
        Absyn.CLASS(a,b,c,d,e,Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts2),file_info);
    /* otherwise */
    case (_,_)
      equation
        Print.printBuf("Failed in removeInnerClass\n");
      then
        fail();
  end matchcontinue;
end removeInnerClass;

protected function removeClassInElementitemlist
"function: removeClassInElementitemlist
   This function takes an Element list and a Class and returns a modified
   element list where the class definition of the class is removed."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Class inClass;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm
  outAbsynElementItemLst := matchcontinue (inAbsynElementItemLst,inClass)
    local
      list<Absyn.ElementItem> res,xs;
      Absyn.ElementItem a1,e1;
      Absyn.Class c,c1,c2;
      String name1,name;
    case (((a1 as Absyn.ANNOTATIONITEM(annotation_ = _)) :: xs),c)
      equation
        res = removeClassInElementitemlist(xs, c);
      then
        (a1 :: res);
    case (((e1 as Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = (c1 as Absyn.CLASS(name = name1))),constrainClass = NONE()))) :: xs),(c as Absyn.CLASS(name = name)))
      equation
        false = stringEq(name1, name);
        res = removeClassInElementitemlist(xs, c);
      then
        (e1 :: res);
    case (((e1 as Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = Absyn.CLASS(name = name1))))) :: xs),(c2 as Absyn.CLASS(name = name)))
      equation
        true = stringEq(name1, name);
      then
        xs;
    case ((a1 :: xs),c)
      equation
        res = removeClassInElementitemlist(xs, c);
      then
        (a1 :: res);
    case ({},c) then {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE(),Absyn.NOT_INNER_OUTER(),"",Absyn.CLASSDEF(false,c),
          Absyn.INFO("",false,0,0,0,0,Absyn.dummyTimeStamp),NONE()))};
  end matchcontinue;
end removeClassInElementitemlist;

protected function replaceInnerClass
"function: replaceInnerClass
  This function takes two class definitions. The first one is
  inserted/replaced as a local class inside the second one."
  input Absyn.Class inClass1;
  input Absyn.Class inClass2;
  output Absyn.Class outClass;
algorithm
  outClass:=
  matchcontinue (inClass1,inClass2)
    local
      list<Absyn.ElementItem> publst,publst2;
      list<Absyn.ClassPart> parts2,parts;
      Absyn.Class c1;
      String a,bcname;
      Boolean b,c,d;
      Absyn.Restriction e;
      Option<String> cmt;
      Absyn.Info file_info;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
    /* a class with parts */
    case (c1,Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                         body = Absyn.PARTS(typeVars = typeVars, classParts = parts,comment = cmt),info = file_info))
      equation
        publst = getPublicList(parts);
        publst2 = replaceClassInElementitemlist(publst, c1);
        parts2 = replacePublicList(parts, publst2);
      then
        Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(typeVars,parts2,cmt),file_info);
    /* an extended class with parts: model extends M end M; */
    case (c1,Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                         body = Absyn.CLASS_EXTENDS(baseClassName = bcname,modifications = modif,parts = parts,comment = cmt),info = file_info))
      equation
        publst = getPublicList(parts);
        publst2 = replaceClassInElementitemlist(publst, c1);
        parts2 = replacePublicList(parts, publst2);
      then
        Absyn.CLASS(a,b,c,d,e,Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts2),file_info);
    case (_,_)
      equation
        Print.printBuf("Failed in replaceInnerClass\n");
      then
        fail();
  end matchcontinue;
end replaceInnerClass;

protected function replaceClassInElementitemlist
"function: replaceClassInElementitemlist
  This function takes an Element list and a Class and returns a modified
  element list where the class definition of the class is updated or added."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Class inClass;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm
  outAbsynElementItemLst := matchcontinue (inAbsynElementItemLst,inClass)
    local
      list<Absyn.ElementItem> res,xs;
      Absyn.ElementItem a1,e1;
      Absyn.Class c,c1,c2;
      String name1,name,d;
      Boolean a,e;
      Option<Absyn.RedeclareKeywords> b;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> h;
      Absyn.InnerOuter io;
    case (((a1 as Absyn.ANNOTATIONITEM(annotation_ = _)) :: xs),c)
      equation
        res = replaceClassInElementitemlist(xs, c);
      then
        (a1 :: res);
    case (((e1 as Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = (c1 as Absyn.CLASS(name = name1))),constrainClass = NONE()))) :: xs),(c as Absyn.CLASS(name = name)))
      equation
        false = stringEq(name1, name);
        res = replaceClassInElementitemlist(xs, c);
      then
        (e1 :: res);
    case (((e1 as Absyn.ELEMENTITEM(element = Absyn.ELEMENT(finalPrefix = a,redeclareKeywords = b,innerOuter = io,name = d,specification = Absyn.CLASSDEF(replaceable_ = e,class_ = Absyn.CLASS(name = name1)),info = info,constrainClass = h))) :: xs),(c2 as Absyn.CLASS(name = name)))
      equation
        true = stringEq(name1, name);
      then
        (Absyn.ELEMENTITEM(Absyn.ELEMENT(a,b,io,d,Absyn.CLASSDEF(e,c2),info,h)) :: xs);
    case ((e1 :: xs),c)
      equation
        res = replaceClassInElementitemlist(xs, c);
      then
        (e1 :: res);
    case ({},c) then {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE(),Absyn.NOT_INNER_OUTER(),"",Absyn.CLASSDEF(false,c),
          Absyn.dummyInfo,NONE()))};
  end matchcontinue;
end replaceClassInElementitemlist;

protected function getInnerClass
"function: getInnerClass
  This function takes a class name and a class and
  returns the inner class definition having that name."
  input Absyn.Class inClass;
  input Absyn.Ident inIdent;
  output Absyn.Class outClass;
algorithm
  outClass:=
  matchcontinue (inClass,inIdent)
    local
      list<Absyn.ElementItem> publst;
      Absyn.Class c1,c;
      list<Absyn.ClassPart> parts;
      String name,str,s1;
      Absyn.TimeStamp ts;
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),name)
      equation
        publst = getPublicList(parts);
        c1 = getClassFromElementitemlist(publst, name);
      then
        c1;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)),name)
      equation
        publst = getPublicList(parts);
        c1 = getClassFromElementitemlist(publst, name);
      then
        c1;
    case (c as Absyn.CLASS(info = Absyn.INFO(buildTimes = ts)),name)
      equation
        str = Print.getString();
        Print.clearBuf();
        Print.printBuf("Interactive.getInnerClass failed, c:");
        Dump.dump(Absyn.PROGRAM({c},Absyn.TOP(), ts));
        Print.printBuf("name :");
        Print.printBuf(name);
        s1 = Print.getString();
        Print.clearBuf() "print s1 &" ;
        Print.printBuf(str);
      then
        fail();
  end matchcontinue;
end getInnerClass;

protected function replacePublicList
"function: replacePublicList
   This function replaces the ElementItem list in
   the ClassPart list, and returns the updated list.
   If no public list is available, one is created."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst,inAbsynElementItemLst)
    local
      list<Absyn.ClassPart> rest_1,rest,ys,xs;
      Absyn.ClassPart lst,x;
      list<Absyn.ElementItem> newpublst,new,newpublist;
    case (((lst as Absyn.PUBLIC(contents = _)) :: rest),newpublst)
      equation
        rest_1 = deletePublicList(rest);
      then
        (Absyn.PUBLIC(newpublst) :: rest_1);
    case ((x :: xs),new)
      equation
        ys = replacePublicList(xs, new);
      then
        (x :: ys);
    case ({},newpublist) then {Absyn.PUBLIC(newpublist)};
  end matchcontinue;
end replacePublicList;

protected function replaceProtectedList "function: replaceProtectedList

  This function replaces the `ElementItem\' list in the `ClassPart\' list,
  and returns the updated list.
  If no protected list is available, one is created.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst,inAbsynElementItemLst)
    local
      list<Absyn.ClassPart> rest_1,rest,ys,xs;
      Absyn.ClassPart lst,x;
      list<Absyn.ElementItem> newprotlist,new;
    case (((lst as Absyn.PROTECTED(contents = _)) :: rest),newprotlist)
      equation
        rest_1 = deleteProtectedList(rest);
      then
        (Absyn.PROTECTED(newprotlist) :: rest_1);
    case ((x :: xs),new)
      equation
        ys = replaceProtectedList(xs, new);
      then
        (x :: ys);
    case ({},newprotlist) then {Absyn.PROTECTED(newprotlist)};
  end matchcontinue;
end replaceProtectedList;

protected function deletePublicList "function: deletePublicList

  Deletes all PULIC classparts from the list.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.ClassPart> res,xs;
      Absyn.ClassPart x;
    case ({}) then {};
    case ((Absyn.PUBLIC(contents = _) :: xs))
      equation
        res = deletePublicList(xs);
      then
        res;
    case ((x :: xs))
      equation
        res = deletePublicList(xs);
      then
        (x :: res);
  end matchcontinue;
end deletePublicList;

protected function deleteProtectedList "function: deleteProtectedList

  Deletes all PROTECTED classparts from the list.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.ClassPart> res,xs;
      Absyn.ClassPart x;
    case ({}) then {};
    case ((Absyn.PROTECTED(contents = _) :: xs))
      equation
        res = deleteProtectedList(xs);
      then
        res;
    case ((x :: xs))
      equation
        res = deleteProtectedList(xs);
      then
        (x :: res);
  end matchcontinue;
end deleteProtectedList;

protected function replaceEquationList "function: replaceEquationList

   This function replaces the `EquationItem\' list in the `ClassPart\' list,
   and returns the updated list.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst,inAbsynEquationItemLst)
    local
      Absyn.ClassPart lst,x;
      list<Absyn.ClassPart> rest,ys,xs;
      list<Absyn.EquationItem> newpublst,new;
    case (((lst as Absyn.EQUATIONS(contents = _)) :: rest),newpublst) then (Absyn.EQUATIONS(newpublst) :: rest);
    case ((x :: xs),new)
      equation
        ys = replaceEquationList(xs, new);
      then
        (x :: ys);
    case ({},_) then {};
  end matchcontinue;
end replaceEquationList;

protected function getPublicList "function: getPublicList

  This function takes a ClassPart List and returns an appended list of
  all public lists.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm
  outAbsynElementItemLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.ElementItem> res2,res,res1,ys;
      list<Absyn.ClassPart> rest,xs;
      Absyn.ClassPart x;
    case ({}) then {};
    case (Absyn.PUBLIC(contents = res1) :: rest)
      equation
        res2 = getPublicList(rest);
        res = listAppend(res1, res2);
      then
        res;
    case ((x :: xs))
      equation
        ys = getPublicList(xs);
      then
        ys;
  end matchcontinue;
end getPublicList;

protected function getProtectedList "function: getProtectedList
   This function takes a ClassPart List and returns an appended list of
   all protected lists.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm
  outAbsynElementItemLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.ElementItem> res2,res,res1,ys;
      list<Absyn.ClassPart> rest,xs;
      Absyn.ClassPart x;
    case ({}) then {};
    case (Absyn.PROTECTED(contents = res1) :: rest)
      equation
        res2 = getProtectedList(rest);
        res = listAppend(res1, res2);
      then
        res;
    case ((x :: xs))
      equation
        ys = getProtectedList(xs);
      then
        ys;
  end matchcontinue;
end getProtectedList;

protected function getEquationList "function: getEquationList
  This function takes a ClassPart List and returns the first EquationItem
  list of the class."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.EquationItem> outAbsynEquationItemLst;
algorithm
  outAbsynEquationItemLst := matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.EquationItem> lst,ys;
      list<Absyn.ClassPart> rest,xs;
      Absyn.ClassPart x;
    case (Absyn.EQUATIONS(contents = lst) :: rest) then lst;
    case ((x :: xs))
      equation
        ys = getEquationList(xs);
      then
        ys;
    case (_) then fail();
  end matchcontinue;
end getEquationList;

protected function getClassFromElementitemlist "function: getClassFromElementitemlist

  This function takes an ElementItem list and an Ident and returns the
  class definition among the element list having that identifier.
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Ident inIdent;
  output Absyn.Class outClass;
algorithm
  outClass:=
  matchcontinue (inAbsynElementItemLst,inIdent)
    local
      Absyn.Class res,c1;
      list<Absyn.ElementItem> xs;
      String name,name1,name2;
    case ((Absyn.ANNOTATIONITEM(annotation_ = _) :: xs),name)
      equation
        res = getClassFromElementitemlist(xs, name);
      then
        res;
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = (c1 as Absyn.CLASS(name = name1))),constrainClass = NONE())) :: xs),name2)
      equation
        true = stringEq(name1, name2);
      then
        c1;
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = (c1 as Absyn.CLASS(name = name1))),constrainClass = NONE())) :: xs),name)
      equation
        false = stringEq(name1, name);
        res = getClassFromElementitemlist(xs, name);
      then
        res;
    case ((_ :: xs),name)
      equation
        res = getClassFromElementitemlist(xs, name);
      then
        res;
    case ({},_) then fail();
  end matchcontinue;
end getClassFromElementitemlist;

protected function classInProgram
"function: classInProgram
  This function takes a name and a Program and returns
  true if the name exists as a top class in the program."
  input String inString;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inString,inProgram)
    local
      String str,c1;
      Boolean res;
      list<Absyn.Class> p;
      Absyn.Within w;
      Absyn.TimeStamp ts;
    
    case (str,Absyn.PROGRAM(classes = {}, globalBuildTimes=ts)) then false;
    case (str,Absyn.PROGRAM(classes = (Absyn.CLASS(name = c1) :: p),within_ = w,globalBuildTimes=ts))
      equation
        false = stringEq(str, c1);
        res = classInProgram(str, Absyn.PROGRAM(p,w,ts));
      then
        res;
    case (_,_) then true;
  end matchcontinue;
end classInProgram;

public function getPathedClassInProgram
"function: getPathedClassInProgram
  This function takes a Path and a Program and retrieves the
  class definition referenced by the Path from the Program."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  output Absyn.Class outClass;
algorithm
  outClass := matchcontinue (inPath,inProgram)
    local
      Absyn.Program p;
      Absyn.Path path;

    case (path,p) then getPathedClassInProgramWork(path, p);
    case (path,p) then getPathedClassInProgramWork(path,Builtin.getInitialFunctions());

  end matchcontinue;
end getPathedClassInProgram;

public function getPathedClassInProgramWork
"function: getPathedClassInProgramWork
  This function takes a Path and a Program and retrieves the
  class definition referenced by the Path from the Program."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  output Absyn.Class outClass;
algorithm
  outClass := match (inPath,inProgram)
    local
      Absyn.Class c1,c1def,res;
      String str;
      Absyn.Program p;
      list<Absyn.Class> classes;
      Absyn.Path path,prest;
      Absyn.Within w;
      Absyn.TimeStamp ts;

    case (Absyn.IDENT(name = str),p)
      equation
        c1 = getClassInProgram(str, p);
      then
        c1;
    case (Absyn.FULLYQUALIFIED(path),(p))
      equation
        res = getPathedClassInProgram(path,p);
      then
        res;
    case ((path as Absyn.QUALIFIED(name = str,path = prest)),(p as Absyn.PROGRAM(within_ = w,globalBuildTimes=ts)))
      equation
        c1def = getClassInProgram(str, p);
        classes = getClassesInClass(Absyn.IDENT(str), p, c1def);
        res = getPathedClassInProgramWork(prest, Absyn.PROGRAM(classes,w,ts));
      then
        res;
  end match;
end getPathedClassInProgramWork;

protected function getClassesInClass
"function: getClassesInClass
  This function takes a Class definition and returns
  a list of local Class definitions of that class."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Absyn.Class inClass;
  output list<Absyn.Class> outAbsynClassLst;
algorithm
  outAbsynClassLst := match (inPath,inProgram,inClass)
    local
      list<Absyn.Class> res;
      Absyn.Path modelpath,path;
      Absyn.Program p;
      list<Absyn.ClassPart> parts;
    case (modelpath,p,Absyn.CLASS(body = Absyn.PARTS(classParts = parts)))
      equation
        res = getClassesInParts(parts);
      then
        res;
    case (modelpath,p,Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)))
      equation
        res = getClassesInParts(parts);
      then
        res;
    case (modelpath,p,Absyn.CLASS(body = Absyn.DERIVED(typeSpec = Absyn.TPATH(path,_))))
      equation
        // print("Looking up -> lookupClassdef(" +& Absyn.pathString(path) +& ", " +& Absyn.pathString(modelpath) +& ")\n");
        /* adrpo 2009-10-27: do not dive into derived classes!
        (cdef,newpath) = lookupClassdef(path, modelpath, p);
        res = getClassesInClass(newpath, p, cdef);
        */
        res = {};
      then
        res;
  end match;
end getClassesInClass;

protected function getClassesInParts
"function: getClassesInParts
  Helper function to getClassesInClass."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.Class> outAbsynClassLst;
algorithm
  outAbsynClassLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.Class> l1,l2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> rest;
    case {} then {};
    case ((Absyn.PUBLIC(contents = elts) :: rest))
      equation
        l1 = getClassesInParts(rest);
        l2 = getClassesInElts(elts);
        res = listAppend(l1, l2);
      then
        res;
    case ((Absyn.PROTECTED(contents = elts) :: rest))
      equation
        l1 = getClassesInParts(rest);
        l2 = getClassesInElts(elts);
        res = listAppend(l1, l2);
      then
        res;
    case ((_ :: rest))
      equation
        res = getClassesInParts(rest);
      then
        res;
  end matchcontinue;
end getClassesInParts;

protected function getClassesInElts
"function: getClassesInElts
  Helper function to getClassesInParts."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.Class> outAbsynClassLst;
algorithm
  outAbsynClassLst:=
  matchcontinue (inAbsynElementItemLst)
    local
      list<Absyn.Class> res;
      Absyn.Class class_;
      list<Absyn.ElementItem> rest;
    case {} then {};
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = class_),constrainClass = NONE())) :: rest))
      equation
        res = getClassesInElts(rest);
      then
        (class_ :: res);
    case ((_ :: rest))
      equation
        res = getClassesInElts(rest);
      then
        res;
  end matchcontinue;
end getClassesInElts;

protected function getClassInProgram
"function: getClassInProgram
   This function takes a Path and a Program
   and returns the class with the name Path.
   If that class does not exist, the function fails"
  input String inString;
  input Absyn.Program inProgram;
  output Absyn.Class outClass;
algorithm
  outClass:=
  matchcontinue (inString,inProgram)
    local
      String str,c1,c1name;
      Absyn.Class res,cl;
      list<Absyn.Class> p;
      Absyn.Within w;
      Absyn.TimeStamp ts;

    case (str,Absyn.PROGRAM(classes = {})) then fail();
    /* adrpo: handle also the case: model extends X end X; */
    case (str,Absyn.PROGRAM(classes = (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(baseClassName = c1)) :: p),within_ = w, globalBuildTimes=ts))
      equation
        false = stringEq(str, c1);
        res = getClassInProgram(str, Absyn.PROGRAM(p,w,ts));
      then
        res;
    /* adrpo: handle also the case: model extends X end X; */
    case (str,Absyn.PROGRAM(classes = ((cl as Absyn.CLASS(body = Absyn.CLASS_EXTENDS(baseClassName = c1name))) :: p),within_ = w,globalBuildTimes=ts))
      equation
        true = stringEq(str, c1name);
      then
        cl;
    case (str,Absyn.PROGRAM(classes = (Absyn.CLASS(name = c1) :: p),within_ = w,globalBuildTimes=ts))
      equation
        false = stringEq(str, c1);
        res = getClassInProgram(str, Absyn.PROGRAM(p,w,ts));
      then
        res;
    case (str,Absyn.PROGRAM(classes = ((cl as Absyn.CLASS(name = c1name)) :: p),within_ = w, globalBuildTimes=ts))
      equation
        true = stringEq(str, c1name);
      then
        cl;
  end matchcontinue;
end getClassInProgram;

protected function modificationToAbsyn
"function: modificationToAbsyn
   This function takes a list of NamedArg and returns an Absyn.Modification option.
   It collects binding equation from the named argument binding=<expr> and creates
   corresponding Modification option Absyn node.
   Future extension: add general modifiers. Problem: how to express this using named
   arguments. This is not possible. Instead we need a new data type for storing AST,
   and a constructor function for AST,
   e.g. AST x = ASTModification(redeclare R2 r, x=4.2); // new datatype AST
             // new constructor operator ASTModification"
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Option<Absyn.Modification> inAbsynModificationOption;
  output Option<Absyn.Modification> outAbsynModificationOption;
algorithm
  outAbsynModificationOption:=
  matchcontinue (inAbsynNamedArgLst,inAbsynModificationOption)
    local
      Absyn.Modification mod;
      list<Absyn.NamedArg> nargs;
      Option<Absyn.Modification> oldmod;
    case (nargs,oldmod)
      equation
        SOME(mod) = modificationToAbsyn2(nargs);
      then
        SOME(mod);
    case (nargs,oldmod) then oldmod;
  end matchcontinue;
end modificationToAbsyn;

protected function modificationToAbsyn2
"function: modificationToAbsyn2
  Helper function to modificationToAbsyn."
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  output Option<Absyn.Modification> outAbsynModificationOption;
algorithm
  outAbsynModificationOption:=
  matchcontinue (inAbsynNamedArgLst)
    local
      Absyn.Exp exp;
      list<Absyn.NamedArg> xs;
      Absyn.Modification mod;
      Option<Absyn.Modification> res;
      Absyn.NamedArg x;
    case ({}) then NONE();
    case ((Absyn.NAMEDARG(argName = "binding",argValue = exp) :: xs)) then SOME(Absyn.CLASSMOD({},Absyn.EQMOD(exp,Absyn.dummyInfo)));
    case ((Absyn.NAMEDARG(argName = "modification",argValue = Absyn.CODE(code = Absyn.C_MODIFICATION(modification = mod))) :: xs)) then SOME(mod);
    case ((x :: xs)) equation res = modificationToAbsyn2(xs); then res;
  end matchcontinue;
end modificationToAbsyn2;

protected function selectAnnotation
"@author: adrpo
  Selects either the new annotation if is SOME or the old one"
  input Option<Absyn.Annotation> newAnn;
  input Option<Absyn.Annotation> oldAnn;
  output Option<Absyn.Annotation> outAnn;
algorithm
  outAnn := match(newAnn, oldAnn)
    case(newAnn as SOME(_), _) then newAnn;
    case(newAnn as NONE(), oldAnn) then oldAnn;
  end match;
end selectAnnotation;

protected function annotationListToAbsynComment
"function: annotationListToAbsynComment
   This function takes a list of NamedArg and returns an absyn Comment.
   for instance {annotation = Placement( ...), comment=\"stringcomment\" }
   is converted to SOME(COMMENT(ANNOTATION(Placement(...), SOME(\"stringcomment\"))))"
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Option<Absyn.Comment> inAbsynCommentOption;
  output Option<Absyn.Comment> outAbsynCommentOption;
algorithm
  outAbsynCommentOption := matchcontinue (inAbsynNamedArgLst,inAbsynCommentOption)
    local
      Absyn.Comment ann;
      list<Absyn.NamedArg> nargs;
      Option<Absyn.Comment> oldann;
      String oldcmt,newcmt;
      Option<String> cmtOpt;
      Option<Absyn.Annotation> annOptOld, annOptNew, annOpt;
    
    // old annotation is NONE! take the new one.
    case (nargs,oldann as NONE())
      equation
        SOME(ann) = annotationListToAbsynComment2(nargs);
      then
        SOME(ann);
    
    // old annotation comment is NONE! take the new one.
    case (nargs,oldann as SOME(Absyn.COMMENT(annOptOld, NONE())))
      equation
        SOME(ann as Absyn.COMMENT(annOptNew, cmtOpt)) = annotationListToAbsynComment2(nargs);
        annOpt = selectAnnotation(annOptNew, annOptOld);
      then
        SOME(Absyn.COMMENT(annOpt, cmtOpt));
    
    // old annotation comment is SOME and new is NONE! take the old one.
    case (nargs,oldann as SOME(Absyn.COMMENT(annOptOld, SOME(oldcmt))))
      equation
        SOME(ann as Absyn.COMMENT(annOptNew, NONE())) = annotationListToAbsynComment2(nargs);
        annOpt = selectAnnotation(annOptNew, annOptOld);
      then
        SOME(Absyn.COMMENT(annOpt, SOME(oldcmt)));
    
    // old annotation comment is SOME and new is SOME! take the new one.
    case (nargs,oldann as SOME(Absyn.COMMENT(annOptOld, SOME(oldcmt))))
      equation
        SOME(ann as Absyn.COMMENT(annOptNew, SOME(newcmt))) = annotationListToAbsynComment2(nargs);
        annOpt = selectAnnotation(annOptNew, annOptOld);
      then
        SOME(Absyn.COMMENT(annOpt, SOME(newcmt)));
    
    // no annotations from nargs
    case (nargs,oldann) 
      then 
        oldann;
  end matchcontinue;
end annotationListToAbsynComment;

protected function annotationListToAbsynComment2
"function: annotationListToAbsynComment2
  Helper function to annotationListToAbsynComment2."
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  output Option<Absyn.Comment> outAbsynCommentOption;
algorithm
  outAbsynCommentOption:=
  matchcontinue (inAbsynNamedArgLst)
    local
      list<Absyn.NamedArg> nargs;
      String strcmt;
      Absyn.Annotation annotation_;
      Option<String> ostrcmt;
    case (nargs)
      equation
        Absyn.ANNOTATION({}) = annotationListToAbsyn(nargs) "special case for empty string" ;
        SOME("") = commentToAbsyn(nargs);
      then
        NONE();
    case (nargs)
      equation
        Absyn.ANNOTATION({}) = annotationListToAbsyn(nargs);
        SOME(strcmt) = commentToAbsyn(nargs);
      then
        SOME(Absyn.COMMENT(NONE(),SOME(strcmt)));
    case (nargs)
      equation
        Absyn.ANNOTATION({}) = annotationListToAbsyn(nargs);
        NONE() = commentToAbsyn(nargs);
      then
        NONE();
    case (nargs)
      equation
        annotation_ = annotationListToAbsyn(nargs);
        ostrcmt = commentToAbsyn(nargs);
      then
        SOME(Absyn.COMMENT(SOME(annotation_),ostrcmt));
    case (_) then NONE();
  end matchcontinue;
end annotationListToAbsynComment2;

protected function commentToAbsyn
"function: commentToAbsyn
  Helper function to annotationListToAbsynComment2."
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  output Option<String> outStringOption;
algorithm
  outStringOption:=
  matchcontinue (inAbsynNamedArgLst)
    local
      String str;
      Option<String> res;
      list<Absyn.NamedArg> rest;
    case ((Absyn.NAMEDARG(argName = "comment",argValue = Absyn.STRING(value = str)) :: _))
      equation
        false = stringEq(str, "");
      then
        SOME(str);
    case ((_ :: rest))
      equation
        res = commentToAbsyn(rest);
      then
        res;
    case (_) then NONE();
  end matchcontinue;
end commentToAbsyn;

protected function annotationListToAbsyn
"function: annotationListToAbsyn
  This function takes a list of NamedArg and returns an Absyn.Annotation.
  for instance {annotation = Placement( ...) } is converted to ANNOTATION(Placement(...))"
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  output Absyn.Annotation outAnnotation;
algorithm
  outAnnotation := matchcontinue (inAbsynNamedArgLst)
    local
      Absyn.ElementArg eltarg;
      Absyn.Exp e;
      Absyn.Annotation annres;
      Absyn.NamedArg a;
      list<Absyn.NamedArg> al;
    case ({}) then Absyn.ANNOTATION({});
    case ((Absyn.NAMEDARG(argName = "annotate",argValue = e) :: _))
      equation
        eltarg = recordConstructorToModification(e);
      then
        Absyn.ANNOTATION({eltarg});
    case ((a :: al))
      equation
        annres = annotationListToAbsyn(al);
      then
        annres;
  end matchcontinue;
end annotationListToAbsyn;

protected function recordConstructorToModification
"function: recordConstructorToModification
   This function takes a record constructor expression and translates
   it into a ElementArg. Since modifications must be named, only named
   arguments are treated in the record constructor."
  input Absyn.Exp inExp;
  output Absyn.ElementArg outElementArg;
algorithm
  outElementArg:=
  matchcontinue (inExp)
    local
      list<Absyn.ElementArg> eltarglst;
      Absyn.ElementArg res,emod;
      Absyn.ComponentRef cr;
      list<Absyn.NamedArg> nargs;
      Absyn.Exp e;
    
    /* Covers the case annotate=Diagram(1) */
    case (Absyn.CALL(function_ = cr,functionArgs = Absyn.FUNCTIONARGS(args = {e}, argNames = {})))
      equation
        res = Absyn.MODIFICATION(false,Absyn.NON_EACH(),cr,SOME(Absyn.CLASSMOD({},Absyn.EQMOD(e,Absyn.dummyInfo))),NONE(),Absyn.dummyInfo);
      then
        res;
    /* Covers the case annotate=Diagram(x=1,y=2) */
    case (Absyn.CALL(function_ = cr,functionArgs = Absyn.FUNCTIONARGS(args = {},argNames = nargs)))
      equation
        eltarglst = List.map(nargs, namedargToModification);
        res = Absyn.MODIFICATION(false,Absyn.NON_EACH(),cr,SOME(Absyn.CLASSMOD(eltarglst,Absyn.NOMOD())),NONE(),Absyn.dummyInfo);
      then
        res;
    /* Covers the case annotate=Diagram(SOMETHING(x=1,y=2)) */
    case (Absyn.CALL(function_ = cr,functionArgs = Absyn.FUNCTIONARGS(args = {(e as Absyn.CALL(function_ = _))},argNames = nargs)))
      equation
        eltarglst = List.map(nargs, namedargToModification);
        emod = recordConstructorToModification(e);
        res = Absyn.MODIFICATION(false,Absyn.NON_EACH(),cr,SOME(Absyn.CLASSMOD((emod :: eltarglst),Absyn.NOMOD())),NONE(),Absyn.dummyInfo);
      then
        res;
    case (e)
      equation
        Print.printBuf("Interactive.recordConstructorToModification failed, exp=");
        Dump.printExp(e);
        Print.printBuf("\n");
      then
        fail();
  end matchcontinue;
end recordConstructorToModification;

protected function namedargToModification
"function: namedargToModification
  This function takes a NamedArg and translates it into a ElementArg."
  input Absyn.NamedArg inNamedArg;
  output Absyn.ElementArg outElementArg;
algorithm
  outElementArg:=
  matchcontinue (inNamedArg)
    local
      list<Absyn.ElementArg> elts;
      Absyn.ComponentRef cr_1,cr;
      Absyn.ElementArg res;
      String id;
      Absyn.Exp c,e;
      list<Absyn.NamedArg> nargs;
    case (Absyn.NAMEDARG(argName = id,argValue = (c as Absyn.CALL(function_ = cr,functionArgs = Absyn.FUNCTIONARGS(args = {},argNames = nargs)))))
      equation
        Absyn.MODIFICATION(modification = SOME(Absyn.CLASSMOD(elts,_)), comment = NONE()) = recordConstructorToModification(c);
        cr_1 = Absyn.CREF_IDENT(id,{});
        res = Absyn.MODIFICATION(false,Absyn.NON_EACH(),cr_1,SOME(Absyn.CLASSMOD(elts,Absyn.NOMOD())),NONE(),Absyn.dummyInfo);
      then
        res;
    case (Absyn.NAMEDARG(argName = id,argValue = e))
      equation
        res = Absyn.MODIFICATION(false,Absyn.NON_EACH(),Absyn.CREF_IDENT(id,{}),SOME(Absyn.CLASSMOD({},Absyn.EQMOD(e,Absyn.dummyInfo /*Bad*/))),NONE(),Absyn.dummyInfo);
      then
        res;
    case (_)
      equation
        Print.printBuf("- Interactive.namedargToModification failed\n");
      then
        fail();
  end matchcontinue;
end namedargToModification;

public function addInstantiatedClass
"function: addInstantiatedClass
   This function adds an instantiated class to the list of instantiated
   classes. If the class path already exists, the class is replaced."
  input list<InstantiatedClass> inInstantiatedClassLst;
  input InstantiatedClass inInstantiatedClass;
  output list<InstantiatedClass> outInstantiatedClassLst;
algorithm
  outInstantiatedClassLst:=
  matchcontinue (inInstantiatedClassLst,inInstantiatedClass)
    local
      InstantiatedClass cl,newc,x;
      Absyn.Path path,path2;
      DAE.DAElist dae,dae_1;
      list<Env.Frame> env,env_1;
      list<InstantiatedClass> xs,res;
    case ({},cl) then {cl};
    case ((INSTCLASS(qualName = path,daeElementLst = dae,env = env) :: xs),(newc as INSTCLASS(qualName = path2,daeElementLst = dae_1,env = env_1)))
      equation
        true = Absyn.pathEqual(path, path2);
      then
        (newc :: xs);
    case (((x as INSTCLASS(qualName = path)) :: xs),(newc as INSTCLASS(qualName = path2)))
      equation
        false = Absyn.pathEqual(path, path2);
        res = addInstantiatedClass(xs, newc);
      then
        (x :: res);
  end matchcontinue;
end addInstantiatedClass;

public function getInstantiatedClass
"function: getInstantiatedClass
  This function get an instantiated class
  from the list of instantiated classes."
  input list<InstantiatedClass> inInstantiatedClassLst;
  input Absyn.Path inPath;
  output InstantiatedClass outInstantiatedClass;
algorithm
  outInstantiatedClass:=
  matchcontinue (inInstantiatedClassLst,inPath)
    local
      InstantiatedClass x,res;
      Absyn.Path path,path2;
      DAE.DAElist dae;
      list<Env.Frame> env;
      list<InstantiatedClass> xs;
    case (((x as INSTCLASS(qualName = path,daeElementLst = dae,env = env)) :: xs),path2)
      equation
        true = Absyn.pathEqual(path, path2);
      then
        x;
    case (((x as INSTCLASS(qualName = path)) :: xs),path2)
      equation
        false = Absyn.pathEqual(path, path2);
        res = getInstantiatedClass(xs, path2);
      then
        res;
  end matchcontinue;
end getInstantiatedClass;

public function getContainedClassAndFile
"function: getContainedClassAndFile
   author: PA
   Returns the package or class in which the model is saved and the file
   name it is saved in. This is used to save a model in a package when the
   whole package is saved in a file.
   inputs:   (Absyn.Path, Absyn.Program)
   outputs:  (Absyn.Program, string /* filename */)"
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
  output String outString;
algorithm
  (outProgram,outString):=
  match (inPath,inProgram)
    local
      Absyn.Class cdef;
      String filename;
      Absyn.Program p_1,p_2,p;
      Absyn.Path classname;
    case (classname,p)
      equation
        cdef = getPathedClassInProgram(classname, p);
        filename = Absyn.classFilename(cdef);
        p_1 = getSurroundingPackage(classname, p);
        p_2 = removeInnerDiffFiledClasses(p_1);
      then
        (p_2,filename);
  end match;
end getContainedClassAndFile;

protected function removeInnerDiffFiledClasses
"function removeInnerDiffFiledClasses
   author: PA
   Removes all inner classes that have different file name than the class
   itself. The filename of the class is passed as argument.
   inputs: (Absyn.Program /* package as program. */)
   outputs: Absyn.Program"
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
algorithm
  outProgram:=
  match (inProgram)
    local
      list<Absyn.Class> classlst_1,classlst;
      Absyn.Within within_;
      Absyn.TimeStamp ts;
    case (Absyn.PROGRAM(classes = classlst,within_ = within_,globalBuildTimes=ts))
      equation
        classlst_1 = List.map(classlst, removeInnerDiffFiledClass);
      then
        Absyn.PROGRAM(classlst_1,within_,ts);
  end match;
end removeInnerDiffFiledClasses;

protected function removeInnerDiffFiledClass
"function: removeInnerDiffFiledClass
   author: PA
   Helper function to removeInnerDiffFiledClasses, removes all local
   classes in class that does not have the same filename as the class
   iteself."
  input Absyn.Class inClass;
  output Absyn.Class outClass;
algorithm
  outClass:=
  match (inClass)
    local
      list<Absyn.ElementItem> publst,publst2;
      list<Absyn.ClassPart> parts2,parts;
      String a,file,baseClassName;
      Boolean b,c,d;
      Absyn.Restriction e;
      Option<String> cmt;
      Absyn.Info file_info;
      list<Absyn.ElementArg> modifications;
      list<String> typeVars;

    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.PARTS(typeVars = typeVars, classParts = parts,comment = cmt),
                      info = (file_info as Absyn.INFO(fileName = file))))
      equation
        publst = getPublicList(parts);
        publst2 = removeClassDiffFiledInElementitemlist(publst, file);
        parts2 = replacePublicList(parts, publst2);
      then
        Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(typeVars,parts2,cmt),file_info);

    /* adrpo: handle also the case model extends X end X; */
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.CLASS_EXTENDS(baseClassName=baseClassName,
                                                 modifications = modifications,
                                                 parts = parts,
                                                 comment = cmt),
                      info = (file_info as Absyn.INFO(fileName = file))))
      equation
        publst = getPublicList(parts);
        publst2 = removeClassDiffFiledInElementitemlist(publst, file);
        parts2 = replacePublicList(parts, publst2);
      then
        Absyn.CLASS(a,b,c,d,e,Absyn.CLASS_EXTENDS(baseClassName,modifications,cmt,parts2),file_info);
  end match;
end removeInnerDiffFiledClass;

protected function removeClassDiffFiledInElementitemlist
"function: removeClassDiffFiledInElementitemlist
  author: PA
  This function takes an Element list and a filename
  and returns a modified element list where the elements
  not stored in filename are removed.
  inputs: (Absyn.ElementItem list, string /* filename */)
  outputs: Absyn.ElementItem list"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input String inString;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm
  outAbsynElementItemLst:=
  matchcontinue (inAbsynElementItemLst,inString)
    local
      list<Absyn.ElementItem> res,xs;
      Absyn.ElementItem a1,e1,c1;
      String c,filename2,filename1,filename;

    case (((a1 as Absyn.ANNOTATIONITEM(annotation_ = _)) :: xs),c)
      equation
        res = removeClassDiffFiledInElementitemlist(xs, c) "annotations are kept" ;
      then
        (a1 :: res);

    case (((e1 as Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ =
      Absyn.CLASS(info = Absyn.INFO(fileName = filename2)))))) :: xs),filename1)
      equation
        false = stringEq(filename1, filename2);
        res = removeClassDiffFiledInElementitemlist(xs, filename1);
      then
        res;

    case (((e1 as Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ =
      Absyn.CLASS(info = Absyn.INFO(fileName = filename2)))))) :: xs),filename1)
      equation
        true = stringEq(filename1, filename2);
        res = removeClassDiffFiledInElementitemlist(xs, filename1);
      then
        (e1 :: res);

    case ((c1 :: xs),filename)
      equation
        res = removeClassDiffFiledInElementitemlist(xs, filename);
      then
        (c1 :: res);

    case ({},filename) then {};
  end matchcontinue;
end removeClassDiffFiledInElementitemlist;

protected function getSurroundingPackage
"function: getSurroundingPackage
   author: PA
   This function investigates the surrounding packages and returns
   the outermost package that has the same filename as the class"
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
algorithm
  outProgram:=
  matchcontinue (inPath,inProgram)
    local
      Absyn.Class cdef,pdef;
      String filename1,filename2;
      Absyn.Path ppath,classpath;
      Absyn.Program res,p;
      Absyn.Within within_;
      Absyn.TimeStamp ts;

    case (classpath,p)
      equation
        cdef = getPathedClassInProgram(classpath, p);
        filename1 = Absyn.classFilename(cdef);
        ppath = Absyn.stripLast(classpath);
        pdef = getPathedClassInProgram(ppath, p);
        filename2 = Absyn.classFilename(pdef);
        true = stringEq(filename1, filename2);
        res = getSurroundingPackage(ppath, p);
      then
        res;

    /* No package with same filename */
    case (classpath,p as Absyn.PROGRAM(globalBuildTimes=ts))
      equation
        cdef = getPathedClassInProgram(classpath, p) ;
        within_ = buildWithin(classpath);
      then
        Absyn.PROGRAM({cdef},within_,ts);
  end matchcontinue;
end getSurroundingPackage;

public function transformFlatProgram
"function transformFlatProgram
  Transforms component references in a Absyn.PROGRAM
  to same format as the variables of the flat program.
  i.e. a.b[3].c[2] becomes CREF_IDENT(\"a.b[3].c\",[INDEX(ICONST(2))])"
input Absyn.Program p;
output Absyn.Program newP;
algorithm
  newP := match(p)
    case(p) equation
      ((newP,_,_)) = traverseClasses(p,NONE(), transformFlatClass, 0, true) "traverse protected" ;
      then newP;
  end match;
end transformFlatProgram;

protected function transformFlatClass
"function transformFlatClass
  This is the visitor function for traversing a class in transformFlatProgram."
  input tuple<Absyn.Class, Option<Absyn.Path>,Integer > inTuple;
  output tuple<Absyn.Class, Option<Absyn.Path>, Integer> outTuple;
algorithm
  outTuple:= matchcontinue (inTuple)
    local
      Absyn.Ident id;
      Option<Absyn.Path> pa;
      Boolean a,b,c;
      Absyn.Restriction d;
      Absyn.Info file_info;
      Absyn.ClassDef cdef,cdef1;
      Integer i;

    case((Absyn.CLASS(id, a,b,c,d,cdef,file_info),pa,i))
      equation
        cdef1 = transformFlatClassDef(cdef);
      then ((Absyn.CLASS(id,a,b,c,d,cdef1,file_info),pa,i));

    case((_,_,_))
      equation
        print("Interactive.transformFlatClass failed\n");
      then fail();
  end matchcontinue;
end transformFlatClass;

protected function transformFlatClassDef
"function transformFlatClassDef
  Help function to transformFlatClass."
  input Absyn.ClassDef cdef;
  output Absyn.ClassDef outCdef;
algorithm
  outCdef := matchcontinue(cdef)
    local
      list<Absyn.ClassPart> parts,partsTransformed;
      String baseClassName;
      list<Absyn.ElementArg> modifications;
      Option<String> cmt;
      list<String> typeVars;
    case(cdef as Absyn.DERIVED(typeSpec=_)) then cdef;
    case(cdef as Absyn.ENUMERATION(enumLiterals = _)) then cdef;
    case(cdef as Absyn.OVERLOAD(functionNames =_)) then cdef;
    case(cdef as Absyn.PDER(functionName=_)) then cdef;
    case(Absyn.PARTS(typeVars,parts,cmt))
      equation
        partsTransformed = List.map(parts,transformFlatPart);
      then
        Absyn.PARTS(typeVars,partsTransformed,cmt);
    /*
     * adrpo: TODO! are we sure we shouldn't handle also the parts in model extends X parts end X; ??!!
                    how about the modifications also??
     *        before it was: case (cdef as Absyn.CLASS_EXTENDS(baseClassName = _) then cdef;
     */
    case(cdef as Absyn.CLASS_EXTENDS(baseClassName = baseClassName,
                                     modifications = modifications,
                                     comment = cmt,
                                     parts = parts))
      equation
        partsTransformed = List.map(parts,transformFlatPart);
      then
        Absyn.CLASS_EXTENDS(baseClassName, modifications, cmt, partsTransformed);
    case(_) equation print("Interactive.transformFlatClassDef failed\n");
      then fail();
  end matchcontinue;
end transformFlatClassDef;

public function transformFlatPart
"function transformFlatPart
  Help function to transformFlatClassDef."
  input Absyn.ClassPart part;
  output Absyn.ClassPart outPart;
algorithm
  outPart := matchcontinue(part)
    local
      list<Absyn.ElementItem> eitems, eitems1;
      list<Absyn.EquationItem> eqnitems, eqnitems1;
      list<Absyn.AlgorithmItem> algitems,algitems1;
    case(Absyn.PUBLIC(eitems))
      equation
        eitems1 = List.map(eitems,transformFlatElementItem);
      then Absyn.PUBLIC(eitems1);
    case(Absyn.PROTECTED(eitems))
      equation
        eitems1 = List.map(eitems,transformFlatElementItem);
      then Absyn.PROTECTED(eitems1);
    case(Absyn.EQUATIONS(eqnitems))
      equation
        eqnitems1 = List.map(eqnitems,transformFlatEquationItem);
      then Absyn.EQUATIONS(eqnitems1);
    case(Absyn.INITIALEQUATIONS(eqnitems))
      equation
        eqnitems1 = List.map(eqnitems,transformFlatEquationItem);
      then Absyn.INITIALEQUATIONS(eqnitems1);
    case(Absyn.ALGORITHMS(algitems))
      equation
        algitems1 = List.map(algitems,transformFlatAlgorithmItem);
      then Absyn.ALGORITHMS(algitems1);
    case(Absyn.INITIALALGORITHMS(algitems))
      equation
        algitems1 = List.map(algitems,transformFlatAlgorithmItem);
      then Absyn.INITIALALGORITHMS(algitems1);
    case(part as Absyn.EXTERNAL(_,_)) then part;
    case(_)
      equation print("Interactive.transformFlatPart failed\n");
      then fail();
  end matchcontinue;
end transformFlatPart;

protected function transformFlatElementItem
"function transformFlatElementItem
  Help function to transformFlatParts"
  input Absyn.ElementItem eitem;
  output Absyn.ElementItem outEitem;
algorithm
  outEitem := match(eitem)
  local Absyn.Element elt,elt1;
    case(Absyn.ELEMENTITEM(elt)) equation elt1 = transformFlatElement(elt); then (Absyn.ELEMENTITEM(elt1));
    case(eitem as Absyn.ANNOTATIONITEM(_)) then eitem;
  end match;
end transformFlatElementItem;

protected function transformFlatElement
"function transformFlatElement
  Help function to transformFlatElementItem"
  input Absyn.Element elt;
  output Absyn.Element outElt;
algorithm
  outElt := match(elt)
    local
      Boolean f;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter io;
      Absyn.Ident name ;
      Absyn.ElementSpec spec,spec1;
      Absyn.Info info ;
      Option<Absyn.ConstrainClass> constr;
    case (elt as Absyn.TEXT(optName=_)) then elt;
    case(Absyn.ELEMENT(f,r,io,name,spec,info,constr))
      equation
        spec1=transformFlatElementSpec(spec);
        //TODO: constr clause might need transformation too.
      then
        Absyn.ELEMENT(f,r,io,name,spec1,info,constr);
  end match;
end transformFlatElement;

protected function transformFlatElementSpec
"function transformFlatElementSpec
  Helper to transformFlatElement"
  input Absyn.ElementSpec eltSpec;
  output Absyn.ElementSpec outEltSpec;
algorithm
  outEltSpec := match(eltSpec)
    local
      Boolean r;
      Absyn.Class cl,cl1;
      Absyn.Path path;
      Absyn.TypeSpec tp;
      list<Absyn.ElementArg> eargs,eargs1;
      Absyn.ElementAttributes attr;
      list<Absyn.ComponentItem> comps,comps1;
      Option<Absyn.Annotation> annOpt;

    case(Absyn.CLASSDEF(r,cl))
      equation
        ((cl1,_,_)) = transformFlatClass((cl,NONE(),0));
      then Absyn.CLASSDEF(r,cl1);

    case(Absyn.EXTENDS(path,eargs,annOpt))
      equation
        eargs1 = List.map(eargs,transformFlatElementArg);
      then Absyn.EXTENDS(path,eargs1,annOpt);

    case(eltSpec as Absyn.IMPORT(import_ = _)) then eltSpec;

    case(Absyn.COMPONENTS(attr,tp,comps))
      equation
        comps1 = List.map(comps,transformFlatComponentItem);
      then Absyn.COMPONENTS(attr,tp,comps1);

  end match;
end transformFlatElementSpec;

protected function transformFlatComponentItem
"function transformFlatComponentItem
  Help function to transformFlatElementSpec"
  input Absyn.ComponentItem compitem;
  output Absyn.ComponentItem outCompitem;
algorithm
  outCompitem := match(compitem)
    local
      Option<Absyn.ComponentCondition> cond;
      Option<Absyn.Comment> cmt;
      Absyn.Component comp,compTransformed;
    case(Absyn.COMPONENTITEM(comp,cond,cmt))
      equation
        compTransformed = transformFlatComponent(comp);
      then
        Absyn.COMPONENTITEM(compTransformed,cond,cmt);
  end match;
end transformFlatComponentItem;

protected function transformFlatComponent
"function transformFlatComponent
  Help function to transformFlatComponentItem"
  input Absyn.Component comp;
  output Absyn.Component outComp;
algorithm
  outComp := match(comp)
    local
      Absyn.ArrayDim arraydim,arraydimTransformed;
      Option<Absyn.Modification> mod,modTransformed;
      Absyn.Ident id;
    case(Absyn.COMPONENT(id,arraydim,mod))
      equation
        modTransformed = transformFlatModificationOption(mod);
        arraydimTransformed = transformFlatArrayDim(arraydim);
    then
      Absyn.COMPONENT(id,arraydimTransformed,modTransformed);
  end match;
end transformFlatComponent;

protected function transformFlatArrayDim
"function transformFlatArrayDim
  Help function to transformFlatComponent"
  input Absyn.ArrayDim ad;
  output  Absyn.ArrayDim outAd;
algorithm
  outAd := match(ad)
    local Absyn.ArrayDim adTransformed;
    case(ad)
      equation
        adTransformed = List.map(ad,transformFlatSubscript);
      then adTransformed;
  end match;
end transformFlatArrayDim;

protected function transformFlatSubscript
"function transformFlatSubscript
  Help function to TransformFlatArrayDim"
  input Absyn.Subscript s;
  output Absyn.Subscript outS;
algorithm
  outS := match(s)
    local Absyn.Exp e,e1;
    case(Absyn.NOSUB()) then Absyn.NOSUB();
    case(Absyn.SUBSCRIPT(e))
      equation
        ((e1,_)) = Absyn.traverseExp(e,transformFlatExp,0);
      then
        Absyn.SUBSCRIPT(e1);
  end match;
end transformFlatSubscript;

protected function transformFlatElementArg
"function transformFlatElementArg
  Helper function to e.g. transformFlatElementSpec"
  input Absyn.ElementArg eltArg;
  output Absyn.ElementArg outEltArg;
algorithm
  outEltArg := match(eltArg)
    local
      Boolean f;
      Absyn.Each e;
      Absyn.ComponentRef cr,cr1;
      Option<Absyn.Modification> mod,mod1;
      Option<String> cmt;
      Absyn.Info info;

    case(Absyn.MODIFICATION(f,e,cr,mod,cmt,info))
      equation
        mod1 = transformFlatModificationOption(mod);
        cr1 = transformFlatComponentRef(cr);
      then
        Absyn.MODIFICATION(f,e,cr1,mod1,cmt,info);
    // redeclarations not in flat Modelica
    case(eltArg as Absyn.REDECLARATION(finalPrefix = _))
      then eltArg;
  end match;
end transformFlatElementArg;

protected function transformFlatModificationOption
"function transformFlatModificationOption
  Help function to transformFlatElementArg"
  input Option<Absyn.Modification> mod;
  output Option<Absyn.Modification> outMod;
algorithm
  outMod := match(mod)
    local
      Absyn.Info info;
      Absyn.Exp e,e1;
      list<Absyn.ElementArg> eltArgs,eltArgs1;
    case (SOME(Absyn.CLASSMOD(eltArgs,Absyn.EQMOD(e,info))))
      equation
        eltArgs1=List.map(eltArgs,transformFlatElementArg);
        ((e1,_)) = Absyn.traverseExp(e,transformFlatExp,0);
      then SOME(Absyn.CLASSMOD(eltArgs1,Absyn.EQMOD(e1,info)));
    case (SOME(Absyn.CLASSMOD(eltArgs,Absyn.NOMOD())))
      equation
        eltArgs1=List.map(eltArgs,transformFlatElementArg);
      then SOME(Absyn.CLASSMOD(eltArgs1,Absyn.NOMOD()));
    case(NONE()) then NONE();
  end match;
end transformFlatModificationOption;

protected function transformFlatComponentRef
"function transformFlatComponentRef
  Help function to e.g. transformFlatElementArg and transformFlatExp"
  input Absyn.ComponentRef cr;
  output Absyn.ComponentRef outCr;
algorithm
  outCr := match(cr)
  local Absyn.ComponentRef cr1;
    list<Absyn.Subscript> ss;
    String s;
    case (cr) equation
      ss = Absyn.crefLastSubs(cr);
      cr1 = Absyn.crefStripLastSubs(cr);
      s = Dump.printComponentRefStr(cr1);
    then Absyn.CREF_IDENT(s,ss);
  end match;
end transformFlatComponentRef;

protected function transformFlatEquationItem
"function transformFlatEquationItem
  Help function to transformFlatParts"
  input Absyn.EquationItem eqnitem;
  output Absyn.EquationItem outEqnitem;
algorithm
  outEqnitem := match(eqnitem)
    local
      Option<Absyn.Comment> cmt;
      Absyn.Equation eqn,eqn1;
      Absyn.Info info;
    case(Absyn.EQUATIONITEM(eqn,cmt,info))
      equation
        eqn1 = transformFlatEquation(eqn);
      then Absyn.EQUATIONITEM(eqn1,cmt,info);
    case(eqnitem as Absyn.EQUATIONITEMANN(annotation_=_))
    then eqnitem;
  end match;
end transformFlatEquationItem;

protected function transformFlatEquation
"function transformFlatEquation
  Help function to transformFlatEquationItem"
  input Absyn.Equation eqn;
  output Absyn.Equation outEqn;
algorithm
  outEqn := match(eqn)
    local
      Absyn.Exp e1,e2,e11,e21;
      Absyn.Ident id;
      Absyn.ComponentRef name;
      list<Absyn.EquationItem> thenpart,thenpart1,elsepart,elsepart1,forEqns,forEqns1,whenEqns,whenEqns1;
      list<tuple<Absyn.Exp,list<Absyn.EquationItem>>> elseifpart,elseifpart1,elseWhenEqns,elseWhenEqns1;
      Absyn.ComponentRef cr1,cr2,cr11,cr21;
      Absyn.FunctionArgs fargs,fargs1;

    case(Absyn.EQ_IF(e1,thenpart,elseifpart,elsepart))
      equation
        ((e11,_)) = Absyn.traverseExp(e1,transformFlatExp,0);
        thenpart1 = List.map(thenpart,transformFlatEquationItem);
        elsepart1 = List.map(elsepart,transformFlatEquationItem);
        elseifpart1 = List.map(elseifpart,transformFlatElseIfPart);
      then
        Absyn.EQ_IF(e11,thenpart1,elseifpart1,elsepart1);

    case(Absyn.EQ_EQUALS(e1,e2))
      equation
        ((e11,_)) = Absyn.traverseExp(e1,transformFlatExp,0);
        ((e21,_)) = Absyn.traverseExp(e2,transformFlatExp,0);
      then
        Absyn.EQ_EQUALS(e11,e21);

    case(Absyn.EQ_CONNECT(cr1,cr2))
      equation
        cr11 = transformFlatComponentRef(cr1);
        cr21 = transformFlatComponentRef(cr2);
      then
        Absyn.EQ_CONNECT(cr11,cr21);

    case(Absyn.EQ_FOR({Absyn.ITERATOR(id,NONE(),SOME(e1))},forEqns))
      equation
        ((e11,_)) = Absyn.traverseExp(e1,transformFlatExp,0);
        forEqns1 = List.map(forEqns,transformFlatEquationItem);
      then
        Absyn.EQ_FOR({Absyn.ITERATOR(id,NONE(),SOME(e11))},forEqns1);

    case(Absyn.EQ_WHEN_E(e1,whenEqns,elseWhenEqns))
      equation
        ((e11,_)) = Absyn.traverseExp(e1,transformFlatExp,0);
        elseWhenEqns1 = List.map(elseWhenEqns,transformFlatElseIfPart);
        whenEqns1 = List.map(whenEqns,transformFlatEquationItem);
      then
        Absyn.EQ_WHEN_E(e11,whenEqns1,elseWhenEqns1);

    case(Absyn.EQ_NORETCALL(name,fargs))
      equation
        fargs1 = transformFlatFunctionArgs(fargs);
      then
        Absyn.EQ_NORETCALL(name,fargs1);
  end match;
end transformFlatEquation;

protected function transformFlatElseIfPart
"function transformFlatElseIfPart
  Help function to transformFlatEquation"
  input tuple<Absyn.Exp, list<Absyn.EquationItem>> elseIfPart;
  output tuple<Absyn.Exp, list<Absyn.EquationItem>> outElseIfPart;
algorithm
  outElseIfPart := match(elseIfPart)
    local
      Absyn.Exp e1,e11;
      list<Absyn.EquationItem> eqnitems,eqnitems1;
    case((e1,eqnitems))
      equation
        ((e11,_)) = Absyn.traverseExp(e1,transformFlatExp,0);
        eqnitems1 = List.map(eqnitems,transformFlatEquationItem);
      then
        ((e11,eqnitems1));
  end match;
end transformFlatElseIfPart;

protected function transformFlatFunctionArgs
"function transformFlatFunctionArgs
  Help function to e.g. transformFlatEquation"
  input Absyn.FunctionArgs fargs;
  output Absyn.FunctionArgs outFargs;
algorithm
  outFargs := match(fargs)
    local
      list<Absyn.Exp> expl,expl1;
      list<Absyn.NamedArg> namedArgs,namedArgs1;
    case( Absyn.FUNCTIONARGS(expl,namedArgs))
      equation
        (expl1,_) = List.mapFoldTuple(expl, transformFlatExpTrav, 0);
        namedArgs1 = List.map(namedArgs,transformFlatNamedArg);
      then
        Absyn.FUNCTIONARGS(expl1,namedArgs1);
    case(fargs as Absyn.FOR_ITER_FARG(exp = _))
      then fargs;
  end match;
end transformFlatFunctionArgs;

protected function transformFlatNamedArg
"function transformFlatNamedArg
  Helper functin to e.g. transformFlatFunctionArgs"
  input Absyn.NamedArg namedArg;
  output Absyn.NamedArg outNamedArg;
algorithm
  outNamedArg := match(namedArg)
    local Absyn.Exp e1,e11; Absyn.Ident id;
    case(Absyn.NAMEDARG(id,e1))
      equation
        ((e11,_)) = Absyn.traverseExp(e1,transformFlatExp,0);
      then Absyn.NAMEDARG(id,e11);
  end match;
end transformFlatNamedArg;

protected function transformFlatExpTrav
"function transformFlatExpTrav
  Transforms a flat expression by calling traverseExp"
  input tuple<Absyn.Exp,Integer> inExp;
  output tuple<Absyn.Exp,Integer> outExp;
algorithm
  outExp := match(inExp)
    local
      Absyn.Exp e,e1;
      Integer i;
    case( (e,i))
      equation
        ((e1,i)) = Absyn.traverseExp(e,transformFlatExp,0);
      then ((e1,i));
  end match;
end transformFlatExpTrav;

protected function transformFlatExp
  input tuple<Absyn.Exp,Integer> inExp;
  output tuple<Absyn.Exp,Integer> outExp;
algorithm
  outExp := matchcontinue(inExp)
    local
      Absyn.ComponentRef cr,cr1;
      Absyn.Exp e; Integer i;
    case( (Absyn.CREF(cr),i))
      equation
        cr1 = transformFlatComponentRef(cr);
      then ((Absyn.CREF(cr1),i));
    case((e,i)) then ((e,i));
  end matchcontinue;
end transformFlatExp;

protected function transformFlatAlgorithmItem
  input Absyn.AlgorithmItem algitem;
  output Absyn.AlgorithmItem outAlgitem;
algorithm
  outAlgitem := match(algitem)
    local
      Option<Absyn.Comment> cmt;
      Absyn.Algorithm alg,alg1;
      Absyn.Info info;
    case(Absyn.ALGORITHMITEM(alg,cmt,info))
      equation
        alg1 = transformFlatAlgorithm(alg);
      then Absyn.ALGORITHMITEM(alg1,cmt,info);
    case(algitem as Absyn.ALGORITHMITEMANN(_)) then algitem;
  end match;
end transformFlatAlgorithmItem;

protected function transformFlatAlgorithm
"function transformFlatAlgorithm
  Help function to transformFlatAlgorithmItem"
  input Absyn.Algorithm alg;
  output Absyn.Algorithm outAlg;
algorithm
  outAlg := match(alg)
    local Absyn.Exp e1,e11,e2,e21;
      Absyn.ComponentRef cr,cr1;
      list<Absyn.AlgorithmItem> body,body1,thenPart,thenPart1,elsePart,elsePart1;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> elseIfPart,elseIfPart1,whenBranch,whenBranch1;
      Absyn.Ident id;
      Absyn.FunctionArgs fargs,fargs1;
    case (Absyn.ALG_ASSIGN(Absyn.CREF(cr),e1))
      equation
        ((e11,_)) = Absyn.traverseExp(e1,transformFlatExp,0);
        cr1 = transformFlatComponentRef(cr);
      then
        Absyn.ALG_ASSIGN(Absyn.CREF(cr1),e1);
    case (Absyn.ALG_ASSIGN(e1 as Absyn.TUPLE(_),e2))
      equation
        ((e11,_)) = Absyn.traverseExp(e1,transformFlatExp,0);
        ((e21,_)) = Absyn.traverseExp(e2,transformFlatExp,0);
      then
        Absyn.ALG_ASSIGN(e11,e21);
    case (Absyn.ALG_IF(e1,thenPart,elseIfPart,elsePart))
      equation
        thenPart1 = List.map(thenPart,transformFlatAlgorithmItem);
        elseIfPart1 =  List.map(elseIfPart,transformFlatElseIfAlgorithm);
        elsePart1 = List.map(elsePart,transformFlatAlgorithmItem);
        ((e11,_)) = Absyn.traverseExp(e1,transformFlatExp,0);
    then
      Absyn.ALG_IF(e11,thenPart1,elseIfPart1,elsePart1);
    case (Absyn.ALG_FOR({Absyn.ITERATOR(id,NONE(),SOME(e1))},body))
      equation
        ((e11,_)) = Absyn.traverseExp(e1,transformFlatExp,0);
        body1 = List.map(body,transformFlatAlgorithmItem);
      then
        Absyn.ALG_FOR({Absyn.ITERATOR(id,NONE(),SOME(e11))},body1);
    case(Absyn.ALG_WHILE(e1,body))
      equation
        ((e11,_)) = Absyn.traverseExp(e1,transformFlatExp,0);
        body1 = List.map(body,transformFlatAlgorithmItem);
    then
      Absyn.ALG_WHILE(e11,body1);
    case (Absyn.ALG_WHEN_A(e1,body,whenBranch))
      equation
       ((e11,_)) = Absyn.traverseExp(e1,transformFlatExp,0);
        body1 = List.map(body,transformFlatAlgorithmItem);
        whenBranch1 =  List.map(whenBranch,transformFlatElseIfAlgorithm);
    then
      Absyn.ALG_WHEN_A(e11,body1,whenBranch1);
    case (Absyn.ALG_NORETCALL(cr,fargs))
      equation
        cr1 = transformFlatComponentRef(cr);
        fargs1 = transformFlatFunctionArgs(fargs);
    then
      Absyn.ALG_NORETCALL(cr1,fargs1);
    case (Absyn.ALG_BREAK()) then Absyn.ALG_BREAK();
    case (Absyn.ALG_RETURN()) then Absyn.ALG_RETURN();

  end match;
end transformFlatAlgorithm;

protected function transformFlatElseIfAlgorithm
  input tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> elseIfbranch;
  output tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> outElseIfbranch;
algorithm
  outElseIfbranch := match(elseIfbranch)
    local
      Absyn.Exp e1,e11;
      list<Absyn.AlgorithmItem> algitems,algitems1;
    case((e1,algitems))
      equation
        ((e11,_)) = Absyn.traverseExp(e1,transformFlatExp,0);
        algitems1 = List.map(algitems,transformFlatAlgorithmItem);
      then ((e11,algitems1));
  end match;
end transformFlatElseIfAlgorithm;

protected function expandUnionTypes
"@auhtor adrpo
 adds records from uniontypes to the upper level class/package "
  input  Absyn.Program inProgram;
  output Absyn.Program outProgram;
algorithm
  outProgram := matchcontinue(inProgram)
    local
      Absyn.Class c1, c1_fixed;
      list<Absyn.Class> rest, rest_fixed;
      Absyn.Program prog;
      Absyn.Within w;
      Absyn.TimeStamp ts;
    case (Absyn.PROGRAM(classes = (c1 :: rest), within_ = w, globalBuildTimes=ts))
      equation
        c1_fixed = expandUnionTypesInClass(c1);
        rest_fixed = List.map(rest, expandUnionTypesInClass);
      then Absyn.PROGRAM(c1_fixed::rest_fixed, w, ts);
    case (prog) then prog;
  end matchcontinue;
end expandUnionTypes;

protected function expandUnionTypesInClass
"@author adrpo
 adds records from uniontypes to the upper level class/package "
  input  Absyn.Class inClass;
  output Absyn.Class outClass;
algorithm
  outClass := matchcontinue(inClass)
    local
      Absyn.Class x;
      Absyn.Restriction restriction;
      Boolean partialPrefix, finalPrefix, encapsulatedPrefix;
      Absyn.Info info;
      Absyn.ClassDef body;
      list<Absyn.ClassPart> parts, new_parts, recordParts;
      Option<String> comment;
      String name;
      list<String> typeVars;
    case (Absyn.CLASS(name, partialPrefix, finalPrefix,encapsulatedPrefix,restriction,
                      body as Absyn.PARTS(typeVars, parts, comment),info))
      equation
        recordParts = getRecordsFromUnionTypes(parts);
        new_parts = listAppend(parts, recordParts);
      then Absyn.CLASS(name,partialPrefix,finalPrefix,encapsulatedPrefix,restriction,
                       Absyn.PARTS(typeVars, new_parts, comment),info);
    case (x) then x;
  end matchcontinue;
end expandUnionTypesInClass;

function getRecordsFromUnionTypes
"@author adrpo
 returns the records from uniontypes "
  input  list<Absyn.ClassPart> inClassParts;
  output list<Absyn.ClassPart> outClassParts;
algorithm
  outClassParts := matchcontinue(inClassParts)
    local
      list<Absyn.ClassPart> parts, returns;
      list<Absyn.ElementItem>
        uniontypesPublic, uniontypesProtected,
        publicElements, protectedElements,
        recordElementsPublic, recordElementsProtected;
    case ({}) then {};
    case (parts)
      equation
        publicElements    = getPublicList(parts);
        protectedElements = getProtectedList(parts);
        uniontypesPublic    = filterUnionTypeElementItems(publicElements);
        uniontypesProtected = filterUnionTypeElementItems(protectedElements);
        recordElementsPublic    = getRecordElementItems(uniontypesPublic);
        recordElementsProtected = getRecordElementItems(uniontypesProtected);
        returns = makeRecordsClassParts(recordElementsPublic, recordElementsProtected);
      then
        returns;
  end matchcontinue;
end getRecordsFromUnionTypes;

function makeRecordsClassParts
"@author adrpo
 constructs the list if any of the input is not nil "
  input  list<Absyn.ElementItem> inPublicElItems;
  input  list<Absyn.ElementItem> inProtectedElItems;
  output list<Absyn.ClassPart> outElementItems;
algorithm
  outElementItems := matchcontinue(inPublicElItems, inProtectedElItems)
    local list<Absyn.ElementItem> publicElements, protectedElements;
    case ({}, {}) then {};
    case ({}, protectedElements) then {Absyn.PROTECTED(protectedElements)};
    case (publicElements, {})    then {Absyn.PUBLIC(publicElements)};
    case (publicElements, protectedElements)
    then Absyn.PUBLIC(publicElements)::{Absyn.PROTECTED(protectedElements)};
  end matchcontinue;
end makeRecordsClassParts;

function filterUnionTypeElementItems
"@author adrpo
 gets the elementitems contained in uniontypes "
  input  list<Absyn.ElementItem> inElementItems;
  output list<Absyn.ElementItem> outElementItems;
algorithm
  outElementItems := matchcontinue(inElementItems)
    local
      list<Absyn.ElementItem> items, unionItems, unionElementItems;
      Absyn.ElementItem x;
      list<Absyn.ClassPart> parts;
      list<Absyn.ElementItem> publicElements, protectedElements;
    case {} then {};
    case ((x as
      Absyn.ELEMENTITEM(
        Absyn.ELEMENT(
          specification =
          Absyn.CLASSDEF(class_ =
            Absyn.CLASS(restriction = Absyn.R_UNIONTYPE(),
            body = Absyn.PARTS(classParts = parts))))))::items)
      equation
        publicElements    = getPublicList(parts);
        protectedElements = getProtectedList(parts);
        unionElementItems = listAppend(publicElements, protectedElements);
        unionItems = filterUnionTypeElementItems(items);
        unionItems = listAppend(unionElementItems, unionItems);
      then
        unionItems;
    case (_::items)
      equation
        unionItems = filterUnionTypeElementItems(items);
      then
        unionItems;
    end matchcontinue;
end filterUnionTypeElementItems;

function getRecordElementItems
"@author adrpo
 filters the elementitems containing records "
  input  list<Absyn.ElementItem> inElementItems;
  output list<Absyn.ElementItem> outElementItems;
algorithm
  outElementItems := matchcontinue(inElementItems)
    local
      list<Absyn.ElementItem> items, recordItems;
      Absyn.ElementItem x;
    case {} then {};
    case ((x as
      Absyn.ELEMENTITEM(
        Absyn.ELEMENT(
          specification = Absyn.CLASSDEF(_, Absyn.CLASS(restriction = Absyn.R_RECORD())))))::items)
      equation
        recordItems = getRecordElementItems(items);
      then
        x :: recordItems;
    case (_::items)
      equation
        recordItems = getRecordElementItems(items);
      then
        recordItems;
    end matchcontinue;
end getRecordElementItems;

protected function updateLoadedFiles
"@author adrpo
 This function updates the loaded files cache.
 It works like this: move from loadedFiles to tempList all
 the elements that do not need update. Then put the new update
 in front of the tempList and return the list"
  input String fileName                      "Filename to load";
  input list<LoadedFile> loadedFiles         "The already loaded files";
  input list<Absyn.Path> qualifiedClasses              "The qualified classes";
  input list<LoadedFile> tempList            "A temp list to build the new one";
  output list<LoadedFile> updatedLoadedFiles "Update file info cache";
algorithm
  updatedLoadedFiles := matchcontinue (fileName, loadedFiles, qualifiedClasses, tempList)
    local
      String f,f1;
      list<LoadedFile> rest, tmp, newTemp;
      list<Absyn.Path> qc;
      LoadedFile x;
      Real now;
    case (f, {}, qc, tmp) // we reached the end, put the updated element in front.
      equation
        now = System.getCurrentTime();
      then // put it as the first in the list
        FILE(f,now,qc)::tmp;
    case (f, FILE(f1,_,_)::rest, qc, tmp) // found it, and ignore it
      equation
        true = stringEq(f, f1);
        newTemp = updateLoadedFiles(f, rest, qc, tmp);
      then
        newTemp;
    case (f, x::rest, qc, tmp) // not an interesting element, just add it to the tmp
      equation
        newTemp = updateLoadedFiles(f, rest, qc, x::tmp);
      then
        newTemp; // report none so that it gets loaded
  end matchcontinue;
end updateLoadedFiles;

protected function getLoadedFileInfo
"@author adrpo
 This function checks if the file is already
 loaded and if the one on the disk is not newer.
 - if YES take the info from cache and return SOME(info)
 - if NOT report that as NONE"
  input String fileName                   "Filename to load";
  input list<LoadedFile> loadedFiles      "The already loaded files";
  output Option<list<Absyn.Path>> qualifiedClasses  "The qualified classes";
algorithm
  (qualifiedClasses) := matchcontinue (fileName, loadedFiles)
    local
      String f,f1;
      list<LoadedFile> rest;
      list<Absyn.Path> info;
      Real loadTime, modificationTime;
      Option<list<Absyn.Path>> optInfo;
    case (f, {}) // we did not find it
      then
        NONE();
    case (f, FILE(f1,loadTime,info)::rest) // found it
      equation
        true = stringEq(f,f1);
        SOME(modificationTime) = System.getFileModificationTime(f);
        // The file is loaded and is not changed since the last load
        true = realGt(loadTime, modificationTime);
      then
        SOME(info);
    case (f, FILE(f1,loadTime,info)::rest) // found it
      equation
        true = stringEq(f,f1);
        // we could not get the modification time
        NONE() = System.getFileModificationTime(f);
      then
        NONE(); // report none so that it gets loaded
    case (f, _::rest) // searching in the rest
      equation
        optInfo = getLoadedFileInfo(f, rest);
      then
        optInfo; // loading
  end matchcontinue;
end getLoadedFileInfo;

protected function checkLoadedFiles
"@author adrpo
 This function checks if the file is already loaded:
 - if loaded then take the info from cache
 - if not, load it, add the info to cache"
  input String fileName                   "Filename to load";
  input String encoding;
  input list<LoadedFile> loadedFiles      "The already loaded files";
  input Absyn.Program ast                 "The program from the symboltable";
  input Boolean shouldUpdateProgram       "Should the program be pushed into the AST?";
  output list<Absyn.Path> topClassNamesQualified    "The names of the classes from file, qualified!";
  output list<LoadedFile> newLoadedFiles  "The new loaded files";
  output Absyn.Program newAst             "The new program to put it in the symboltable";
algorithm
  (topClassNamesQualified, newLoadedFiles, newAst) :=
  matchcontinue (fileName, encoding, loadedFiles, ast, shouldUpdateProgram)
    local
      String f;
      list<Absyn.Path> topNamesStr;
      Absyn.Program pAst,newP,parsed;
      list<LoadedFile> lf, newLF;
    case (f, encoding, lf, pAst, _)
      equation
        // did the file was loaded since it was last saved?
        SOME(topNamesStr) = getLoadedFileInfo(f, lf);
      then
        (topNamesStr, lf, pAst); // not worth loading
    case (f, encoding, lf, pAst, true)
      equation
        // it seems the file was not loaded yet or the one on the disk is newer
        NONE() = getLoadedFileInfo(f, lf);
        // fall back to basis :)
        parsed = Parser.parse(f,encoding);
        parsed = expandUnionTypes(parsed);
        newP = updateProgram(parsed, pAst);
        topNamesStr = getTopQualifiedClassnames(parsed);
        // fix the modification and topNames in the list<LoadedFile> cache
        newLF = updateLoadedFiles(f, lf, topNamesStr, {});
      then
        (topNamesStr, newLF, newP); // loading
    case (f, encoding, lf, pAst, false)
      equation
        // it seems the file was not loaded yet or the one on the disk is newer
        NONE() = getLoadedFileInfo(f, lf);
        // fall back to basis :)
        parsed = Parser.parse(f,encoding);
        parsed = expandUnionTypes(parsed);
        topNamesStr = getTopQualifiedClassnames(parsed);
        // fix the modification and topNames in the list<LoadedFile> cache
        newLF = updateLoadedFiles(f, lf, topNamesStr, {});
      then
        (topNamesStr, newLF, pAst); // loading
    case (f, encoding, lf, pAst, _)
      equation
        failure(_ = Parser.parse(f,encoding)); // failed to parse!
      then ({},lf,pAst); // return error
  end matchcontinue;
end checkLoadedFiles;

public function loadFileInteractiveQualified
"@author adrpo
 This function loads a file ONLY if the
 file is newer than the one already loaded."
  input  String fileName               "Filename to load";
  input  String encoding;
  input  SymbolTable st     "The symboltable where to load the file";
  output list<Absyn.Path> topClassNamesQualified "The names of the classes from file, qualified!";
  output SymbolTable newst  "The new interactive symboltable";
algorithm
  (topClassNamesQualified, newst) := matchcontinue (fileName, encoding, st)
    local
      String file               "Filename to load";
      SymbolTable s  "The symboltable where to load the file";
      list<Absyn.Path> topNamesStr;
      Absyn.Program pAst,newP;
      list<SCode.Element> eAst;
      list<InstantiatedClass> ic;
      list<Variable> iv;
      list<LoadedFile> lf, newLF;
      list<CompiledCFunction> cf;
      AbsynDep.Depends aDep;

    // See that the file exists
    case (file, encoding, s as SYMBOLTABLE(ast = _))
      equation
        false = System.regularFileExists(file);
      then ({},s);
    // check if we have the stuff in the loadedFiles!
    case (file, encoding, s as SYMBOLTABLE(pAst,aDep,_,ic,iv,cf,lf))
      equation
        (topNamesStr,newLF,newP) = checkLoadedFiles(file, encoding, lf, pAst, true);
      then
        (topNamesStr, SYMBOLTABLE(newP,aDep,NONE(),ic,iv,cf,lf));
  end matchcontinue;
end loadFileInteractiveQualified;

/* Start getDefinitions */

protected function getDefinitions
"This function dumps the defined packages, classes and functions to a string.
 The function is used by org.openmodelica.corba.parser.DefinitionsCreator."
  input  Absyn.Program ast "The AST to dump";
  input  Boolean addFunctions;
  output String res "An easily parsed string containing all definitions";
algorithm
  res := match (ast,addFunctions)
  local
    list<Absyn.Class> classes;
    String old;
    list<String> toPrint;
    case (ast,addFunctions)
      equation
        Absyn.PROGRAM(classes = classes) = MetaUtil.createMetaClassesInProgram(ast);
        old = Print.getString();
        Print.clearBuf();
        Print.printBuf("\"(\n");
        toPrint = getDefinitions2(classes,addFunctions);
        List.map_0(toPrint, printWithNewline);
        Print.printBuf("\n)\"");
        res = Print.getString();
        Print.clearBuf();
        Print.printBuf(old);
      then res;
  end match;
end getDefinitions;

protected function getLocalVariables
"function: getLocalVariables
  Returns the string list of local varibales defined with in the algorithm."
  input Absyn.Class inClass;
  input Boolean inBoolean;
  input Env.Env inEnv;
  output String outList;
algorithm 
  outList := match(inClass, inBoolean, inEnv)
    local
      String strList;
      Env.Env env;
      Boolean b;
      list<Absyn.ClassPart> parts;
      case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)), b, env)
      equation
        strList = getLocalVariablesInClassParts(parts, b, env);
      then
        strList;
    // check also the case model extends X end X;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)), b, env)
      equation
        strList = getLocalVariablesInClassParts(parts, b, env);
      then
        strList;
  end match;
end getLocalVariables;

protected function getLocalVariablesInClassParts
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Boolean inBoolean;
  input Env.Env inEnv;
  output String outList;
algorithm
  outList := matchcontinue (inAbsynClassPartLst, inBoolean, inEnv)
    local
      Env.Env env;
      Boolean b;
      list<Absyn.AlgorithmItem> algs;
      list<Absyn.ClassPart> xs;
      String strList, strList1, strList2;
    case (Absyn.ALGORITHMS(contents = algs) :: xs, b, env)
      equation
        strList1 = getLocalVariablesInAlgorithmsItems(algs, b, env);
        strList = getLocalVariablesInClassParts(xs, b, env);
        strList2 = Util.if_(strList ==& "", strList1, stringAppendList({strList1, ",", strList}));
      then
        strList2;
    case ((_ :: xs), b, env)
      equation
        strList = getLocalVariablesInClassParts(xs, b, env);
      then
        strList;
    case ({}, b, env) then "";
  end matchcontinue;
end getLocalVariablesInClassParts;

protected function getLocalVariablesInAlgorithmsItems
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  input Boolean inBoolean;
  input Env.Env inEnv;
  output String outList;
algorithm
  outList := matchcontinue (inAbsynAlgorithmItemLst, inBoolean, inEnv)
    local
      Env.Env env;
      Boolean b;
      String strList;
      list<Absyn.AlgorithmItem> xs;
      Absyn.Algorithm alg;
    case (Absyn.ALGORITHMITEM(algorithm_ = alg) :: xs, b, env)
      equation
        strList = getLocalVariablesInAlgorithmItem(alg, b, env);
      then
        strList;
    case ((_ :: xs), b, env)
      equation
        strList = getLocalVariablesInAlgorithmsItems(xs, b, env);
      then
        strList;
    case ({}, b, env) then "";
  end matchcontinue;
end getLocalVariablesInAlgorithmsItems;

protected function getLocalVariablesInAlgorithmItem
  input Absyn.Algorithm inAbsynAlgorithmItem;
  input Boolean inBoolean;
  input Env.Env inEnv;
  output String outList;
algorithm
  outList := match (inAbsynAlgorithmItem, inBoolean, inEnv)
    local
      Env.Env env;
      Boolean b;
      String strList;
      list<Absyn.ElementItem> elsItems;
      list<Absyn.Element> els;
    case (Absyn.ALG_ASSIGN(value = Absyn.MATCHEXP(localDecls = elsItems)), b, env)
      equation
        els = getComponentsInElementitems(elsItems);
        strList = getComponentsInfo(els, b, "public", env);
      then
        strList;
    case (_, b, env) then "";
  end match;
end getLocalVariablesInAlgorithmItem;

protected function printWithNewline
  input String s;
algorithm
  Print.printBuf(s);
  Print.printBuf("\n");
end printWithNewline;

protected function getDefinitions2
  input  list<Absyn.Class> classes;
  input  Boolean addFunctions;
  output list<String> res;
algorithm
  res := match (classes,addFunctions)
    local
      list<Absyn.Class> rest;
      Absyn.Class class_;
      String str;
    case ({},_) then {};
    case (class_::rest,addFunctions) equation
      str = getDefinitionsClass(class_, addFunctions);
      res = getDefinitions2(rest, addFunctions);
    then str::res;
  end match;
end getDefinitions2;

protected function getDefinitionsClass
  input Absyn.Class class_;
  input Boolean addFunctions;
  output String res;
algorithm
  res := matchcontinue (class_,addFunctions)
    local
      list<Absyn.ClassPart> parts;
      String ident,  tyStr;
      list<String> strs;
      Absyn.TypeSpec ts;
      Absyn.ElementAttributes attr;
      Integer numDim;
      Integer index;
      Absyn.Path path;
      String indexArg, pathArg;
    case (Absyn.CLASS(name = ident, body = Absyn.PARTS(classParts = parts), restriction = Absyn.R_PACKAGE()),addFunctions)
      equation
        ident = "(package " +& ident;
        strs = getDefinitionParts(parts, addFunctions);
        strs = ident :: strs;
      then stringDelimitList(strs, "\n");
    case (Absyn.CLASS(partialPrefix = true, name = ident, body = Absyn.PARTS(classParts = parts), restriction = Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION())),_)
      equation
        strs = {"(partial function", ident, ")"};
      then stringDelimitList(strs, " ");
    case (Absyn.CLASS(partialPrefix = false, name = ident, body = Absyn.PARTS(classParts = parts), restriction = Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION())),true)
      equation
        strs = getDefinitionParts(parts, true);
        strs = "(function" :: ident :: strs;
      then stringDelimitList(strs, " ");
    case (Absyn.CLASS(partialPrefix = false, name = ident, body = Absyn.PARTS(classParts = parts), restriction = Absyn.R_FUNCTION(Absyn.FR_OPERATOR_FUNCTION())),true)
      equation
        strs = getDefinitionParts(parts, true);
        strs = "(operator function" :: ident :: strs;
      then stringDelimitList(strs, " ");
    case (Absyn.CLASS(name = ident, body = Absyn.PARTS(classParts = parts), restriction = Absyn.R_UNIONTYPE()),_)
      equation
        strs = {"(uniontype", ident, ")"};
      then stringDelimitList(strs, " ");
    case (Absyn.CLASS(name = ident, body = Absyn.PARTS(classParts = parts), restriction = Absyn.R_RECORD()),_)
      equation
        strs = getDefinitionParts(parts, false);
        strs = "(record" :: ident :: strs;
      then stringDelimitList(strs, " ");
    case (Absyn.CLASS(name = ident, body = Absyn.PARTS(classParts = parts), restriction = Absyn.R_METARECORD(name = path, index = index)),_)
      equation
        indexArg = intString(index);
        pathArg = Absyn.pathLastIdent(path);
        strs = getDefinitionParts(parts, false);
        strs = "(metarecord" :: ident :: indexArg :: pathArg :: strs;
      then stringDelimitList(strs, " ");
    case (Absyn.CLASS(name = ident, body = Absyn.DERIVED(typeSpec = ts, attributes = attr)),_)
      equation
        numDim = getDefinitionDimensions(ts,attr);
        tyStr = Util.if_(numDim == 0, "", "[" +& intString(numDim)) +& getDefinitionTypeSpecPathString(ts);
        strs = {"(type", ident, tyStr, ")"};
      then stringDelimitList(strs, " ");
    // Do enumerations really work properly in OMC?
    //case Absyn.CLASS(name = ident, body = Absyn.ENUMERATION(enumLiterals = Absyn.ENUMLITERALS(el))) equation
    //  enumList = List.map(el, getEnumerationLiterals);
    //then "enumeration " +& ident +& "(" +& stringDelimitList(enumList, ",") +& ")";
    case (_,_) then "";
  end matchcontinue;
end getDefinitionsClass;

protected function getDefinitionsReplaceableClass
  input Absyn.Class class_;
  output String res;
algorithm
  res := match (class_)
  local
    String ident;
    case Absyn.CLASS(name = ident, body = Absyn.DERIVED(typeSpec = Absyn.TCOMPLEX(Absyn.IDENT("polymorphic"),{Absyn.TPATH(Absyn.IDENT("Any"),NONE())},NONE())), restriction = Absyn.R_TYPE())
    then "(replaceable type " +& ident +& ")";
  end match;
end getDefinitionsReplaceableClass;

protected function getEnumerationLiterals
  input Absyn.EnumLiteral el;
  output String out;
algorithm
  out := matchcontinue el
  local
    String out;
    case Absyn.ENUMLITERAL(literal = out)
      equation
        out = stringAppendList({"\"",out,"\""});
      then
        out;
  end matchcontinue;
end getEnumerationLiterals;

protected function getDefinitionPathString
  input Absyn.Path path;
  output String out;
algorithm
  out := match (path)
    // Doesn't work because we only know the AST after parsing... case (Absyn.FULLYQUALIFIED(path)) then "#" +& Absyn.pathString(path);
    // Thus, scope/lookup is done by the application recieving this information
    case path then Absyn.pathString(path);
  end match;
end getDefinitionPathString;

public function getDefinitionTypeSpecPathString
  input Absyn.TypeSpec tp;
  output String s;
algorithm s := matchcontinue(tp)
  local
    Absyn.Path p;
    list<Absyn.TypeSpec> tspecs;
    list<String> tspecsStr;
  case(Absyn.TCOMPLEX(path = p, typeSpecs = {})) equation
  then getDefinitionPathString(p);
  case(Absyn.TCOMPLEX(path = p, typeSpecs = tspecs)) equation
    tspecsStr = List.map(tspecs, getDefinitionTypeSpecPathString);
  then getDefinitionPathString(p) +& "<" +& stringDelimitList(tspecsStr,",") +& ">";
  case(Absyn.TPATH(path = p)) then getDefinitionPathString(p);
end matchcontinue;
end getDefinitionTypeSpecPathString;

protected function getDefinitionDimensions
  input Absyn.TypeSpec ts;
  input Absyn.ElementAttributes attr;
  output Integer out;
algorithm
  out := matchcontinue(ts,attr)
  local
    list<Absyn.Subscript> l1,l2;
    case (Absyn.TPATH(arrayDim = SOME(l1)), Absyn.ATTR(arrayDim = l2)) then listLength(l1)+listLength(l2);
    case (Absyn.TCOMPLEX(arrayDim = SOME(l1)), Absyn.ATTR(arrayDim = l2)) then listLength(l1)+listLength(l2);
    case (Absyn.TPATH(arrayDim = NONE()), Absyn.ATTR(arrayDim = l2)) then listLength(l2);
    case (Absyn.TCOMPLEX(arrayDim = NONE()), Absyn.ATTR(arrayDim = l2)) then listLength(l2);
    case (_, _) then 0;
  end matchcontinue;
end getDefinitionDimensions;

protected function getDefinitionParts
  input  list<Absyn.ClassPart> parts;
  input  Boolean isFunction;
  output list<String> res;
algorithm
  res := matchcontinue (parts, isFunction)
  local
    list<Absyn.ClassPart> rest;
    list<Absyn.ElementItem> contents;
    case ({},_) then {")"};
    case (Absyn.PUBLIC(contents)::rest,isFunction)
    then listAppend(getDefinitionContent(contents,isFunction,true), getDefinitionParts(rest,isFunction));
    case (Absyn.PROTECTED(contents)::rest,isFunction)
    then listAppend(getDefinitionContent(contents,isFunction,false), getDefinitionParts(rest,isFunction));
    case (_::rest,isFunction) then getDefinitionParts(rest,isFunction);
  end matchcontinue;
end getDefinitionParts;

protected function getDefinitionContent
  input list<Absyn.ElementItem> contents;
  input Boolean addFunctions;
  input Boolean isPublic;
  output list<String> res;
algorithm
  res := matchcontinue (contents,addFunctions,isPublic)
  local
    list<Absyn.ElementItem> rest;
    String ident, typeStr, dirStr,  str;
    Absyn.Class class_;
    Absyn.Path path;
    list<Absyn.ComponentItem> components;
    Absyn.Direction direction;
    Absyn.TypeSpec ts;
    Absyn.Variability variability;
    Absyn.ElementAttributes attr;
    list<String> res2;

    case ({},_,_) then {};
    case (Absyn.ELEMENTITEM(Absyn.ELEMENT(specification = Absyn.CLASSDEF(replaceable_ = false, class_ = class_)))::rest,addFunctions,isPublic)
      equation
        res = getDefinitionContent(rest,addFunctions,isPublic);
        str = getDefinitionsClass(class_,addFunctions);
      then str::res;
    case (Absyn.ELEMENTITEM(Absyn.ELEMENT(specification = Absyn.CLASSDEF(replaceable_ = true, class_ = class_)))::rest,addFunctions,isPublic)
      equation
        res = getDefinitionContent(rest,addFunctions,isPublic);
        ident = getDefinitionsReplaceableClass(class_);
      then ident :: res;
    case (Absyn.ELEMENTITEM(Absyn.ELEMENT(specification = Absyn.COMPONENTS(typeSpec = ts,components = components, attributes = (attr as Absyn.ATTR(direction = direction, variability = variability)))))::rest,addFunctions,true)
      equation
        typeStr = getDefinitionTypeSpecPathString(ts);
        dirStr = getDefinitionDirString(direction, variability, addFunctions);
        res = getDefinitionComponents(typeStr, dirStr, getDefinitionDimensions(ts,attr), components);
        res2 = getDefinitionContent(rest,addFunctions,isPublic);
      then listAppend(res,res2);
    case (Absyn.ELEMENTITEM(Absyn.ELEMENT(specification = Absyn.EXTENDS(path = path)))::rest,false,true)
      equation
        typeStr = "(extends " +& getDefinitionPathString(path) +& ")";
        res = getDefinitionContent(rest,addFunctions,isPublic);
      then typeStr :: res;
    case (_::rest,addFunctions,isPublic)
      then getDefinitionContent(rest,addFunctions,isPublic);
  end matchcontinue;
end getDefinitionContent;

protected function getDefinitionDirString
  input Absyn.Direction dir;
  input Absyn.Variability variability;
  input Boolean isFunction;
  output String res;
algorithm
  res := match (dir, variability, isFunction)
    case (Absyn.INPUT(),_,true) then "input ";
    case (Absyn.OUTPUT(),_,true) then "output ";
    case (_, variability,false)
      equation
        failure(Absyn.CONST() = variability);
      then "";
  end match;
end getDefinitionDirString;

protected function getDefinitionComponents
  input String typeStr;
  input String dirStr;
  input Integer numDim;
  input list<Absyn.ComponentItem> components;
  output list<String> res;
algorithm
  res := matchcontinue (typeStr,dirStr,numDim,components)
  local
    list<Absyn.ComponentItem> rest;
    String ident;
    list<Absyn.Subscript> l;
    Integer sumDim;

    case (_,_,_,{}) then {};
    case (typeStr,dirStr,numDim,Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = ident, arrayDim = l))::rest) equation
      sumDim = numDim + listLength(l);
      ident = (dirStr +& Util.if_(numDim == 0, "", "[" +& intString(sumDim)) +& typeStr +& " " +& ident);
      ident = "(" +& ident +& ")";
      res = getDefinitionComponents(typeStr,dirStr,numDim,rest);
    then ident :: res;
    case (typeStr,dirStr,numDim,_::rest) then getDefinitionComponents(typeStr,dirStr,numDim,rest);
  end matchcontinue;
end getDefinitionComponents;

/* End getDefinitions */

public function parseFile
"@author adrpo
 This function just parses a file and report contents ONLY if the
 file is newer than the one already loaded."
  input  String fileName               "Filename to load";
  input String encoding;
  input  SymbolTable st     "The symboltable where to load the file";
  output list<Absyn.Path> topClassNamesQualified "The names of the classes from file, qualified!";
  output SymbolTable newst  "The new interactive symboltable";
algorithm
  (topClassNamesQualified, newst) := matchcontinue (fileName, encoding, st)
    local
      String file               "Filename to load";
      SymbolTable s  "The symboltable where to load the file";
      list<Absyn.Path> topNamesStr;
      Absyn.Program pAst,newP;
      list<InstantiatedClass> ic;
      list<Variable> iv;
      list<LoadedFile> lf, newLF;
      list<CompiledCFunction> cf;
      AbsynDep.Depends aDep;
    // See that the file exists
    case (file, _, s as SYMBOLTABLE(ast = _))
      equation
        false = System.regularFileExists(file);
      then ({},s);
    // check if we have the stuff in the loadedFiles!
    case (file, encoding, s as SYMBOLTABLE(pAst,aDep,_,ic,iv,cf,lf))
      equation
        (topNamesStr,newLF,newP) = checkLoadedFiles(file, encoding, lf, pAst, false);
      then
        /* shouldn't newLF be used here? no; we only parse the files; not loading them */
        (topNamesStr, SYMBOLTABLE(newP,aDep,NONE(),ic,iv,cf,lf));
  end matchcontinue;
end parseFile;

//he-mag begin
protected function getElementName
"returns the element name"
  input Absyn.ElementSpec inElementSpec;
  output String outString;
algorithm
  outString := match (inElementSpec)
    local
      String str;
      Absyn.TypeSpec typeSpec;
      list<String> names;
      Absyn.ElementAttributes attr;
      list<Absyn.ComponentItem> lst;
 /*   case (Absyn.EXTENDS(path = path))
      equation
        path_str = Absyn.pathString(path);
        str = stringAppendList({"elementtype=extends, path=",path_str});
      then
        str;
    case (Absyn.IMPORT(import_ = import_))
      equation
        import_str = getImportString(import_);
        str = stringAppendList({"elementtype=import, ",import_str});
      then
        str;*/
    case (Absyn.COMPONENTS(attributes = attr,typeSpec = typeSpec,components = lst))
      equation
//        str = Dump.unparseTypeSpec(typeSpec);
        names = getComponentitemsName(lst,false);
        str = stringDelimitList(names, ", ");
        //print("names: " +& str +& "\n");
      then
        str;
  end match;
end getElementName;

protected function getElementTypeName
"get the name of the type of the element"
  input Absyn.ElementSpec inElementSpec;
  output String outString;
algorithm
  outString:=
  match (inElementSpec)
    local
      String str;
      Absyn.TypeSpec typeSpec;
      Absyn.ElementAttributes attr;
      list<Absyn.ComponentItem> lst;
 /*   case (Absyn.EXTENDS(path = path))
      equation
        path_str = Absyn.pathString(path);
        str = stringAppendList({"elementtype=extends, path=",path_str});
      then
        str;
    case (Absyn.IMPORT(import_ = import_))
      equation
        import_str = getImportString(import_);
        str = stringAppendList({"elementtype=import, ",import_str});
      then
        str;*/
    case (Absyn.COMPONENTS(attributes = attr,typeSpec = typeSpec,components = lst))
      equation
        str = Dump.unparseTypeSpec(typeSpec);
//        names = getComponentitemsName(lst);
      then
        str;
  end match;
end getElementTypeName;

public function getElementVisString ""
  input Absyn.ElementItem inElement;
  input Absyn.Program inProgram;
  output String outString;
algorithm
  outString:= match (inElement,inProgram)
    local
      String desc;
      Absyn.Element el;
      list<Absyn.ComponentItem> comps;
      Boolean f;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter inout;
      Absyn.Ident id;
      Absyn.ElementSpec elementSpec;
      Absyn.Info inf;
      Option<Absyn.ConstrainClass> c;
      Absyn.Program p;
    case (Absyn.ELEMENTITEM(element = el),p)
      equation
        Absyn.ELEMENT(finalPrefix = f, redeclareKeywords = r, innerOuter = inout, name = id, specification = elementSpec, info = inf, constrainClass = c) = el;
        //p_class = Absyn.crefToPath(id);
//        Absyn.IDENT(name) = Absyn.crefToPath(ident);
        //cl = getPathedClassInProgram(p_class, p);
        //comps = getComponentsInClass(cl);
        Absyn.COMPONENTS(components = comps) = elementSpec;
//        Absyn.CLASSDEF(class_ = cl) = elementSpec;
        //comps = getComponentsInClass(cl);
        desc = getElementName(elementSpec);
        desc = desc +& ":" +& getElementTypeName(elementSpec);//getElementInfo(elitem);
      then
        desc;
  end match;
end getElementVisString;

protected function getDescIfVis ""
  input String in_type;
  input Absyn.ElementItem inElement;
  input Absyn.Program inProgram;
  //output Absyn.ElementItem outElement;
  output String outString;
algorithm
  outString:=
  match (in_type, inElement, inProgram)
    local
      Absyn.ElementItem tmp;
      Absyn.Program p;
      String res;
    case ("SimpleVisual.Position", tmp, p)
      equation
        res = getElementVisString(tmp, p);
      then
        res;
    case ("SimpleVisual.PositionSize", tmp, p)
      equation
        res = getElementVisString(tmp, p);
      then
        res;
    case ("SimpleVisual.PositionRotation", tmp,p)
      equation
        res = getElementVisString(tmp,p);
      then
        res;
    case ("SimpleVisual.PositionRotationSize", tmp,p)
      equation
        res = getElementVisString(tmp,p);
      then
        res;
    case ("SimpleVisual.PositionRotationSizeOffset", tmp,p)
      equation
        res = getElementVisString(tmp,p);
      then
        res;
/*
    case ("SimpleVisual.Cube", tmp,p)
      equation
        res = getElementVisString(tmp,p);
      then
        res;
    case ("SimpleVisual.Sphere", tmp,p)
      equation
        res = getElementVisString(tmp,p);
      then
        res;
*/
  end match;
end getDescIfVis;

protected function getNameFromElementIfVisType
""
  input Absyn.ElementItem inElementItem;
  input Absyn.Program inProgram;
  output String outString;
algorithm
  outString:= matchcontinue (inElementItem, inProgram)
    local
      String str,id,file,typename_str,varname_str;
      Boolean f,p,fi,e,isReadOnly;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter inout;
      Absyn.Restriction restr;
      Integer sline,scol,eline,ecol;
      Absyn.ElementSpec elementSpec;
      Absyn.Info info;
      list<String> tmp;
      Absyn.Program prog;
    case (Absyn.ELEMENTITEM(element = Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = inout,specification = Absyn.CLASSDEF(class_ = Absyn.CLASS(name = id,partialPrefix = p,finalPrefix = fi,encapsulatedPrefix = e,restriction = restr,info = Absyn.INFO(fileName = file,isReadOnly = isReadOnly,lineNumberStart = sline,columnNumberStart = scol,lineNumberEnd = eline,columnNumberEnd = ecol))))),prog) /* ok, first see if is a classdef if is not a classdef, just follow the normal stuff */
      then
       "";
    case (Absyn.ELEMENTITEM(element = Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = inout,name = id,specification = elementSpec,info = (info as Absyn.INFO(fileName = file,isReadOnly = isReadOnly,lineNumberStart = sline,columnNumberStart = scol,lineNumberEnd = eline,columnNumberEnd = ecol)))),prog) /* if is not a classdef, just follow the normal stuff */
      equation
        typename_str = getElementTypeName(elementSpec);
        varname_str = getElementName(elementSpec);
        tmp = Util.stringSplitAtChar(varname_str, ",");
        varname_str = List.first(tmp);
        str = getDescIfVis(typename_str, inElementItem,prog);
      then
        str;
    case (_,prog) then "";  /* for annotations we don\'t care */
  end matchcontinue;
end getNameFromElementIfVisType;

protected function constructVisTypesList
"visualization /he-mag"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Program inProgram;
  output list<String> outList;
algorithm
  outList:=
  matchcontinue (inAbsynElementItemLst, inProgram)
    local
      String  s1;
      list<String> res_list, list2;
      Absyn.ElementItem current;
      list<Absyn.ElementItem> rest;//, res_list, list2;
      Absyn.Program p;
    case ({}, p)
      equation
        s1 = "";
        res_list = List.create(s1);
      then
        {};
    case ((current :: {}),p) /* deal with the last element */
      equation
        s1 = getNameFromElementIfVisType(current,p);
        res_list = List.create(s1);//, res_list);
      then
        res_list;
    case ((current :: rest),p)
      equation
        s1 = getNameFromElementIfVisType(current,p);
        res_list = List.create(s1);
        list2 = constructVisTypesList(rest,p);
        res_list = List.union(list2, res_list);
      then
        res_list;
  end matchcontinue;
end constructVisTypesList;

public function getElementsOfVisType
"For visualization! /he-mag"
  //input Absyn.ComponentRef inComponentRef;
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  output list<String> names;
  output String res;
algorithm
  (names,res) := match (inPath,inProgram)
    local
//      Absyn.Path modelpath;
      String i,str;
      Boolean p,f,e;
      Absyn.Restriction r;
      list<Absyn.ClassPart> parts;
      list<Absyn.ElementItem> public_elementitem_list,protected_elementitem_list;
      Absyn.Path modelPath_;
      list<String> public_list, protected_list;
      list<String>  all_list, acc;
      Absyn.Program prog;
    case (modelPath_,prog)
      equation
//        modelpath = Absyn.crefToPath(model_);
//        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(parts,_),_) = getPathedClassInProgram(modelpath, p);
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(classParts=parts),_) = getPathedClassInProgram(modelPath_, prog);
        public_elementitem_list = getPublicList(parts);
        protected_elementitem_list = getProtectedList(parts);
        public_list = constructVisTypesList(public_elementitem_list, prog);
        protected_list = constructVisTypesList(protected_elementitem_list, prog);
        all_list = List.union(listAppend(public_list, protected_list), {});
      then (List.map(all_list, getVisElementNameFromStr),stringDelimitList(all_list,"\n"));

  end match;
end getElementsOfVisType;

protected function getVisElementNameFromStr
  input String str;
  output String outStr;
protected
  list<String> strs;
algorithm
  (_,strs as (_::outStr::_)) := System.regex(str,"([A-Za-z0-9().]*),",3,true,false);
end getVisElementNameFromStr;

protected function getComponentBindingMapable
"function: getComponentBindingMapable
  Returns the value of a component in a class.
  For example, the component
   Real x=1; returns 1.
  This can be used for both parameters, constants and variables.
   inputs: (Absyn.ComponentRef /* variable name */, Absyn.ComponentRef /* class name */, Absyn.Program)
   outputs: string"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.Program inProgram3;
  output String outString;
algorithm
  outString:= matchcontinue (inComponentRef1,inComponentRef2,inProgram3)
    local
      Absyn.Path p_class;
      String name,res;
      Absyn.Class cdef;
      list<Absyn.Element> comps,comps_1;
      list<list<Absyn.ComponentItem>> compelts;
      list<Absyn.ComponentItem> compelts_1;
      Absyn.ComponentItem compitem;
      Absyn.Exp exp;
      Absyn.ComponentRef cr,class_;
      Absyn.Program p;
    case (cr,class_,p)
      equation
        p_class = Absyn.crefToPath(class_);
        Absyn.IDENT(name) = Absyn.crefToPath(cr);
        cdef = getPathedClassInProgram(p_class, p);
        comps = getComponentsInClass(cdef);
        compelts = List.map(comps, getComponentitemsInElement);
        compelts_1 = List.flatten(compelts);
        {compitem} = List.select1(compelts_1, componentitemNamed, name);
        exp = getVariableBindingInComponentitem(compitem);
        res = Dump.printExpStr(exp);
      then
        res;
    case (cr,class_,p)
      equation
        p_class = Absyn.crefToPath(class_);
        Absyn.IDENT(name) = Absyn.crefToPath(cr);
        cdef = getPathedClassInProgram(p_class, p);
        comps = getComponentsInClass(cdef);
        compelts = List.map(comps, getComponentitemsInElement);
        compelts_1 = List.flatten(compelts);
        {compitem} = List.select1(compelts_1, componentitemNamed, name);
        failure(_ = getVariableBindingInComponentitem(compitem));
      then "";
    case (_,_,_) then "Error";
  end matchcontinue;
end getComponentBindingMapable;

protected function getClassnamesInClassList
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Absyn.Class inClass;
  input Boolean inShowProtected;
  output list<String> outString;
algorithm
  outString:=
  match (inPath,inProgram,inClass,inShowProtected)
    local
      list<String> strlist;
      list<Absyn.ClassPart> parts;
      Absyn.Path inmodel,path;
      Absyn.Program p;
      Boolean b;
    case (_,_,Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),b)
      equation
        strlist = getClassnamesInParts(parts,b);
      then
        strlist;
    case (inmodel,p,Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)),b)
      equation
        strlist = getClassnamesInParts(parts,b);
      then strlist;
    case (inmodel,p,Absyn.CLASS(body = Absyn.DERIVED(typeSpec=Absyn.TPATH(path = path))),b)
      equation
        //(cdef,newpath) = lookupClassdef(path, inmodel, p);
        //res = getClassnamesInClassList(newpath, p, cdef);
      then
        {};//res;
    case (inmodel,p,Absyn.CLASS(body = Absyn.OVERLOAD(functionNames = _)),b)
      equation
      then {};
    case (inmodel,p,Absyn.CLASS(body = Absyn.ENUMERATION(enumLiterals = _)),b)
      equation
      then {};
    case (inmodel,p,Absyn.CLASS(body = Absyn.PDER(functionName = _)),b)
      equation
      then {};
  end match;
end getClassnamesInClassList;

protected function joinPaths
  input String child;
  input Absyn.Path parent;
  output Absyn.Path outPath;
algorithm
  outPath := match (child, parent)
    local
      Absyn.Path r, res;
      String c;
    case (c, r)
      equation
        res = Absyn.joinPaths(r, Absyn.IDENT(c));
      then res;
  end match;
end joinPaths;

public function getClassNamesRecursive
"function: getClassNamesRecursive
  Returns a string with all the classes for a given path."
  input Option<Absyn.Path> inPath;
  input Absyn.Program inProgram;
  input Boolean inShowProtected;
  input list<Absyn.Path> inAcc;
  output Option<Absyn.Path> opath;
  output list<Absyn.Path> paths;
algorithm
  (opath,paths) := matchcontinue (inPath,inProgram,inShowProtected,inAcc)
    local
      Absyn.Class cdef;
      String s1,res, parent_string, result;
      list<String> strlst;
      Absyn.Path pp;
      Absyn.Program p;
      list<Absyn.Class> classes;
      list<Option<Absyn.Path>> result_path_lst;
      list<Absyn.Path> acc;
      Boolean b;
      
    case (SOME(pp),p,b,acc)
      equation
        acc = pp::acc;
        cdef = getPathedClassInProgram(pp, p);
        strlst = getClassnamesInClassList(pp, p, cdef,b);
        result_path_lst = List.map(List.map1(strlst, joinPaths, pp),Util.makeOption);
        (_,acc) = List.map2Fold(result_path_lst, getClassNamesRecursive, p, b, acc);
      then (inPath,acc);
    case (NONE(),p as Absyn.PROGRAM(classes=classes),b,acc)
      equation
        strlst = List.map(classes, Absyn.getClassName);
        result_path_lst = List.mapMap(strlst, Absyn.makeIdentPathFromString, Util.makeOption);
        (_,acc) = List.map2Fold(result_path_lst, getClassNamesRecursive, p, b, acc);
      then (inPath,acc);
    case (SOME(pp),_,b,_)
      equation
        s1 = Absyn.pathString(pp);
        Error.addMessage(Error.LOOKUP_ERROR, {s1,"<TOP>"});
      then (inPath,{});
  end matchcontinue;
end getClassNamesRecursive;

public function getPathedComponentElementInProgram "Returns a component given a path and a program. See also getPathedClassInProgram"
  input Absyn.Path path;
  input Absyn.Program prg;
  output Absyn.ElementSpec comp;
algorithm
  comp := match(path,prg)
  local Absyn.Class cl;
    case(path,prg) equation
      cl = getPathedClassInProgram(Absyn.stripLast(path),prg);
      comp = getComponentInClass(cl,Absyn.pathLastIdent(path));
    then comp;
  end match;
end getPathedComponentElementInProgram;

protected function getComponentInClass
  input Absyn.Class cl;
  input Absyn.Ident compName;
  output Absyn.ElementSpec comp;
algorithm
 comp := match(cl,compName)
   local
     list<Absyn.ClassPart> parts;
     list<Absyn.ElementItem> publst;
   /* a class with parts */
   case(Absyn.CLASS(body=Absyn.PARTS(classParts=parts)), compName) equation
     publst = getPublicList(parts);
     comp = getComponentsContainsName(Absyn.CREF_IDENT(compName,{}), publst);
   then comp;
   /* an extended class with parts: model extends M end M; */
   case(Absyn.CLASS(body=Absyn.CLASS_EXTENDS(parts=parts)), compName) equation
     publst = getPublicList(parts);
     comp = getComponentsContainsName(Absyn.CREF_IDENT(compName,{}), publst);
   then comp;
 end match;
end getComponentInClass;

public function setSymbolTableAST
  input SymbolTable inSymTab;
  input Absyn.Program inAST;
  output SymbolTable outSymTab;
algorithm
  outSymTab := match(inSymTab, inAST)
    local
      AbsynDep.Depends d;
      list<InstantiatedClass> i;
      list<Variable> v;
      list<CompiledCFunction> c;
      list<LoadedFile> l;
    case (SYMBOLTABLE(depends = d, instClsLst = i, 
                      lstVarVal = v, compiledFunctions = c, loadedFiles = l), _)
      then SYMBOLTABLE(inAST, d, NONE(), i, v, c, l);
  end match;
end setSymbolTableAST;

public function getSymbolTableAST
  input SymbolTable inSymTab;
  output Absyn.Program outAST;
algorithm
  outAST := match(inSymTab)    
    case (SYMBOLTABLE(ast = outAST)) then outAST;
  end match;
end getSymbolTableAST;

public function getFunctionsInProgram
  input Absyn.Program prog;
  output list<Absyn.Class> funcs;
protected
  list<Absyn.Class> classes;
  list<list<Absyn.Class>> classesList;
algorithm
  Absyn.PROGRAM(classes = classes) := prog;
  classesList := List.map(classes, getAllClassesInClass);
  funcs := List.fold(classes::classesList, getFunctionsInClasses, {});
end getFunctionsInProgram;

protected function getFunctionsInClasses
  input list<Absyn.Class> classes;
  input list<Absyn.Class> acc;
  output list<Absyn.Class> funcs;
algorithm
  funcs := matchcontinue (classes,acc)
    local
      Absyn.Class cl;
      list<Absyn.Class> rest;
      
    case ({},acc) then acc;
    case ((cl as Absyn.CLASS(restriction = Absyn.R_FUNCTION(_)))::rest,acc)
      equation
        funcs = getFunctionsInClasses(rest,cl::acc);
      then funcs;
    case (_::rest,acc) then getFunctionsInClasses(rest,acc);
  end matchcontinue;
end getFunctionsInClasses;

protected function getAllClassesInClass
  input Absyn.Class class_;
  output list<Absyn.Class> outClasses;
algorithm
  outClasses := matchcontinue class_
    local
      list<Absyn.ClassPart> classParts;
    case Absyn.CLASS(body = Absyn.PARTS(classParts = classParts))
      then getClassesInParts(classParts);
    case (_) then {};
  end matchcontinue;
end getAllClassesInClass;

public function symbolTableToSCode
"Similar to SCodeUtil.translateAbsyn2SCode
  But this updates the symboltable to cache the translation."
  input SymbolTable st;
  output SCode.Program program;
  output SymbolTable outSt;
algorithm
  (program,outSt) := match st
    local
      Absyn.Program ast;
      AbsynDep.Depends depends;
      Option<SCode.Program> explodedAst;
      list<InstantiatedClass> instClsLst;
      list<Variable> lstVarVal;
      list<CompiledCFunction> compiledFunctions;
      list<LoadedFile> loadedFiles;
      
    case SYMBOLTABLE(explodedAst=SOME(program)) then (program,st);
    case SYMBOLTABLE(ast,depends,_,instClsLst,lstVarVal,compiledFunctions,loadedFiles)
      equation
        program = SCodeUtil.translateAbsyn2SCode(ast);
      then (program,SYMBOLTABLE(ast,depends,SOME(program),instClsLst,lstVarVal,compiledFunctions,loadedFiles));
  end match;
end symbolTableToSCode;

public function getCompiledFunctions
"function: getCompiledFunctions"
  input SymbolTable inSymTab;
  output list<CompiledCFunction> compiledFunctions;
algorithm
  SYMBOLTABLE(compiledFunctions = compiledFunctions) := inSymTab;
end getCompiledFunctions;

public function dumpCompiledFunctions
"function: dumpCompiledFunctions"
  input SymbolTable inSymTab;
  output String compiledFunctionsStr;
protected
  list<CompiledCFunction> compiledFunctions;
algorithm
  compiledFunctions := getCompiledFunctions(inSymTab);
  compiledFunctionsStr := "Functions:\n\t" +& stringDelimitList(List.map(compiledFunctions, dumpCompiledFunction), "\n\t");
end dumpCompiledFunctions;

public function dumpCompiledFunction
"function: dumpCompiledFunctions"
  input CompiledCFunction inCompiledFunction;
  output String compiledFunctionStr;
protected
  Absyn.Path path;
  DAE.Type retType;
  Integer funcHandle;
  Real buildTime "the build time for this function";
  String loadedFromFile "the file we loaded this function from";  
algorithm
  CFunction(path, retType, funcHandle, buildTime, loadedFromFile) := inCompiledFunction;
  compiledFunctionStr := Absyn.pathString(path) +& 
                         " ty[" +& Types.printTypeStr(retType) +&
                         "] hndl[" +& intString(funcHandle) +& 
                         "] build[" +& realString(buildTime) +&
                         "] file[" +& loadedFromFile +& "]";
end dumpCompiledFunction;

end Interactive;
