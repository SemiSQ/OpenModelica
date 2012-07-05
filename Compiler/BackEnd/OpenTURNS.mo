/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC)
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

encapsulated package OpenTURNS "
  file:        OpenTURNS.mo
  package:     OpenTURNS
  description: Connection to OpenTURNS, software for uncertainty propagation. The connection consists of two parts
  1. Generation of python script as input to OPENTURNS
  2. Generation and compilation of wrapper that calls the standard OpenModelica simulator and retrieves the final values 
  (after simulation has stopped at endTime) 

  RCS: $Id: OpenTURNS.mo 10958 2012-01-25 01:12:35Z wbraun $
  "

public 
import BackendDAE;
import DAE;
import Absyn;
import Env;

protected
import CevalScript;
import SimCode;
import Interactive;
import System;
import Settings;
//import BackendDump;
import BackendDAEUtil;
import List;
import BackendVariable;
import ExpressionDump;
import ComponentReference;
import BackendDAEOptimize;
import Expression;
import Util;

// important constants!
constant String cStrSharePath               = "share/omc/scripts/OpenTurns/";
constant String cStrWrapperSuffix           = "_wrapper";
constant String cStrCWrapperTemplate        = "wrapper_template.c";
constant String cStrMakefileWrapperTemplate = "wrapper_template.makefile";
constant String cStrWrapperCompileCmd       = "wrapper_template.compile.cmd";
constant String cStrInvokeOpenTurnsCmd      = "invoke.cmd";

public function generateOpenTURNSInterface "generates the dll and the python script for connections with OpenTURNS"
  input Env.Cache cache;
  input Env.Env env;
  input BackendDAE.BackendDAE inDaelow;
  input DAE.FunctionTree inFunctionTree;
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input DAE.DAElist inDAElist;
  input String templateFile "the filename to the template file (python script)";
  output String scriptFile "the name of the generated file";
  
  protected
  String cname_str,fileNamePrefix,fileDir,cname_last_str;
  list<String> libs;
  BackendDAE.BackendDAE dae,strippedDae;  
  SimCode.SimulationSettings simSettings;
algorithm
  cname_str := Absyn.pathString(inPath);
  cname_last_str := Absyn.pathLastIdent(inPath);
  fileNamePrefix := cname_str;
      
  simSettings := CevalScript.convertSimulationOptionsToSimCode(
    CevalScript.buildSimulationOptionsFromModelExperimentAnnotation(
      Interactive.setSymbolTableAST(Interactive.emptySymboltable,inProgram),inPath,fileNamePrefix)
  );
  // correlation matrix form (vector of records) currently not supported by OpenModelica backend, remove it .
  //print("enter dae:");
  //BackendDump.dump(inDaelow);
  dae := BackendDAEOptimize.removeParameters(inDaelow);
  //print("generating python script\n");  
 
 scriptFile := generatePythonScript(inPath,templateFile,dae,inDaelow);
 
 // Strip correlation vector from dae to be able to compile (bug in OpenModelica with vectors of records )
  strippedDae := stripCorrelationFromDae(inDaelow);
  
  strippedDae := BackendDAEUtil.getSolvedSystem(strippedDae, NONE(), NONE(), NONE(),NONE());
  
  //print("strippedDae :");
  //BackendDump.dump(strippedDae);
  (_,libs,fileDir,_,_,_) := SimCode.generateModelCode(strippedDae,inProgram,inDAElist,inPath,cname_str,SOME(simSettings),Absyn.FUNCTIONARGS({},{}));
  
  //print("..compiling, fileNamePrefix = "+&fileNamePrefix+&"\n");  
  CevalScript.compileModel(fileNamePrefix , libs, fileDir, "", "");
  
  generateXMLFile(cname_last_str,strippedDae);
  generateWrapperLibrary(cname_str,cname_last_str);
end generateOpenTURNSInterface; 

protected function generateWrapperLibrary
"@author:adrpo
 generates the helpers for the OpenTURNS wrapper:
 replace #define MODELNAMESTR \"Full.ModelName\" in wrapper_template.c
 replace #define WRAPPERNAME ModelName_wrapper in wrapper_template.c
 replace WRAPPERNAME = ModelName_wrapper in wrapper_template.makefile
 replace ModelName_wrapper in wrapper_template.command
 generates files: 
   ModelName_wrapper.makefile from wrapper_template.makefile
   ModelName_wrapper.c from wrapper_template.c
 then compiles the wrapper using the specific wrapper_template.command!"
 input String fullClassName;
 input String lastClassName;
protected
  String strCWrapperContents;
  String strWrapperNameDefine;
  String strMakefileContents;
  String compileWrapperCommand;
algorithm
  // read the wrapper_template.c template, replace the extension points
  strCWrapperContents := System.readFile(getFullShareFileName(cStrCWrapperTemplate));
  strCWrapperContents := System.stringReplace(strCWrapperContents,"<%fullModelName%>", fullClassName);
  strCWrapperContents := System.stringReplace(strCWrapperContents,"<%wrapperName%>", lastClassName +& cStrWrapperSuffix);
  // dump the result into ModelName_wrapper.c  
  System.writeFile(lastClassName +& cStrWrapperSuffix +& ".c", strCWrapperContents);
  
  // read the wrapper_template.makefile template, replace the extension points
  strMakefileContents := System.readFile(getFullShareFileName(cStrMakefileWrapperTemplate));
  strMakefileContents := System.stringReplace(strMakefileContents,"<%fullModelName%>", fullClassName);
  strMakefileContents := System.stringReplace(strMakefileContents,"<%wrapperName%>", lastClassName +& cStrWrapperSuffix);
  // dump the result into ModelName_wrapper.makefile
  System.writeFile(lastClassName +& cStrWrapperSuffix +& ".makefile",strMakefileContents);
  
  // we should check if it works fine!
  compileWrapperCommand := System.readFile(getFullShareFileName(cStrWrapperCompileCmd));
  compileWrapperCommand := System.stringReplace(compileWrapperCommand,"<%wrapperName%>", lastClassName +& cStrWrapperSuffix);
  compileWrapperCommand := System.stringReplace(compileWrapperCommand,"<%currentDirectory%>", System.pwd());
  compileWrapperCommand := compileWrapperCommand +& " > " +& lastClassName +& cStrWrapperSuffix +& ".log" +& " 2>&1";  
  runCommand(compileWrapperCommand);
end generateWrapperLibrary;

protected function generateXMLFile "generates the xml file for the OpenTURNS wrapper"
  input String className;
  input BackendDAE.BackendDAE dae;
protected
  String xmlFileContent;
algorithm
  xmlFileContent := generateXMLFileContent(className,dae);
  System.writeFile(className +& cStrWrapperSuffix +& ".xml", xmlFileContent);
end generateXMLFile;

protected function generateXMLFileContent "help function"
  input String className;
  input BackendDAE.BackendDAE dae;
  output String content;  
algorithm
  content := generateXMLHeader(className) +& "<wrapper>\n" +& generateXMLLibrary(className,dae)+&"\n"+&generateXMLExternalCode(className,dae)+& "\n</wrapper>"; 
end generateXMLFileContent;

protected function generateXMLHeader "help function"
  input String className;
  output String header;
algorithm
  header := "<?xml version=\"1.0\" encoding=\"iso-8859-1\"?>\n<!--\n"+&className+&".xml\n-->\n"+&
  "<!DOCTYPE wrapper SYSTEM \"wrapper.dtd\">\n";
end generateXMLHeader;

protected function generateXMLExternalCode "help function"
  input String className;
  input BackendDAE.BackendDAE dae;
  output String content;
algorithm
  content :=stringDelimitList({
    "<external-code>",
    "  <!-- Those data are external to the platform (input files, etc.)-->",
    "  <data></data>",
    "",
    "  <wrap-mode type=\"static-link\" >",
    "    <in-data-transfer mode=\"arguments\" />",
    "    <out-data-transfer mode=\"arguments\" />",
    "  </wrap-mode>",
    "",
    "  <command># no command</command>",
  "</external-code>"},"\n");
end generateXMLExternalCode;

protected function generateXMLLibrary "help function"
  input String className;
  input BackendDAE.BackendDAE dae;
  output String content;
protected
  list<BackendDAE.Var> varLst;
  String inputs,outputs,funcStr,dllStr;
algorithm
  varLst := BackendDAEUtil.getAllVarLst(dae);
  varLst := List.select(varLst,BackendVariable.varHasUncertaintyAttribute);
  inputs := stringDelimitList(generateXMLLibraryInputs(varLst),"\n");
  outputs := stringDelimitList(generateXMLLibraryOutputs(varLst),"\n");
  dllStr := " <path>" +& className +& cStrWrapperSuffix +& System.getDllExt() +& "</path>";
  funcStr := "   <function provided=\"yes\">" +& className +& cStrWrapperSuffix +& "</function>";
  
  content :=stringDelimitList({
   "<library>",
   "",
   " <!-- The path of the shared object -->",
   dllStr,
   "",
   " <!-- This section describes all exchanges data between the wrapper and the platform -->",
   " <description>",
   "",
   "   <!-- Those variables are substituted in the files above -->",
   "   <!-- The order of variables is the order of the arguments of the function -->",
   "   <variable-list>",
   inputs,outputs,
   "   </variable-list>",
   "",
   "    <!-- The function that we try to execute through the wrapper -->",
   funcStr,
   "   <!-- the gradient is  defined  -->",
   "   <gradient provided=\"no\"></gradient>",
   "   <!--  the hessian is  defined  -->",
   "   <hessian provided=\"no\"></hessian>",
   " </description>",
   "",
   "</library>"},"\n");
end generateXMLLibrary;

protected function generateXMLLibraryInputs "help function"
  input list<BackendDAE.Var> varLst;
  output list<String> strLst;
algorithm
  strLst := matchcontinue (varLst) 
  local 
    String varName,varStr;
    BackendDAE.Var v;
    list<BackendDAE.Var> rest;
    
    case ({}) then {};
    case (v::rest)
      equation
        DAE.GIVEN() = BackendVariable.varUncertainty(v);
       varName = ComponentReference.crefModelicaStr(BackendVariable.varCref(v));
       varStr =  "    <variable id=\""+&varName+&"\" type=\"in\" />";
       strLst = generateXMLLibraryInputs(rest);    
      then varStr::strLst;
    case (_::rest)
      equation
        strLst = generateXMLLibraryInputs(rest);
      then strLst;
  end matchcontinue;
end generateXMLLibraryInputs;
  
protected function generateXMLLibraryOutputs "help function"
  input list<BackendDAE.Var> varLst;
  output list<String> strLst;
algorithm
  strLst := matchcontinue(varLst) 
  local
    String varName,varStr;
    BackendDAE.Var v;
    list<BackendDAE.Var> rest;
  case({}) then {};  
  case(v::rest) equation
     DAE.SOUGHT() = BackendVariable.varUncertainty(v);
     varName = ComponentReference.crefModelicaStr(BackendVariable.varCref(v));
     varStr =  "    <variable id=\""+&varName+&"\" type=\"out\" />";
     strLst = generateXMLLibraryOutputs(rest);    
    then varStr::strLst;
    case(_::rest) equation
     strLst = generateXMLLibraryOutputs(rest);
    then strLst;  
  end matchcontinue;
end generateXMLLibraryOutputs;

protected function generatePythonScript "generates the python script as input to OpenTURNS, given a template file name"
  input Absyn.Path inModelPath;
  input String templateFile;
  input BackendDAE.BackendDAE dae;
  input BackendDAE.BackendDAE inDaelow;
  output String pythonFileName;
  protected
  String templateFileContent,modelName,modelLastName;
  String distributions,correlationMatrix;
  String collectionDistributions,inputDescriptions;
  String pythonFileContent;
  list<tuple<String,String>> distributionVarLst;
algorithm
  modelName := Absyn.pathString(inModelPath);
  modelLastName := Absyn.pathLastIdent(inModelPath);
  templateFileContent := System.readFile(templateFile);
  //generate the different parts of the python file 
  (distributions,distributionVarLst) := generateDistributions(inDaelow);
  (correlationMatrix) := generateCorrelationMatrix(inDaelow,listLength(distributionVarLst),List.map(distributionVarLst,Util.tuple21));
  collectionDistributions := generateCollectionDistributions(inDaelow,distributionVarLst);
  inputDescriptions := stringDelimitList(List.map(distributionVarLst, getName), ", "); //generateInputDescriptions(inDaelow); 
  
  pythonFileName    := System.stringReplace(templateFile,"template",modelName);

  // Replace template markers
  pythonFileContent := System.stringReplace(templateFileContent,"<%distributions%>",distributions);
  pythonFileContent := System.stringReplace(pythonFileContent,"<%correlationMatrix%>",correlationMatrix);
  pythonFileContent := System.stringReplace(pythonFileContent,"<%collectionDistributions%>",collectionDistributions);
  pythonFileContent := System.stringReplace(pythonFileContent,"<%inputDescriptions%>",inputDescriptions);
  pythonFileContent := System.stringReplace(pythonFileContent,"<%wrapperName%>",modelLastName +& cStrWrapperSuffix);

  //Write file
  //print("writing python script to file "+&pythonFileName+&"\n");
  System.writeFile(pythonFileName,pythonFileContent);    
end generatePythonScript;

protected function generateDistributions "generates distibution code for the python script.
Goes throuh all variables and collects a set of unique distributions, then generates python code.

Example of python code.
distributionE = Beta(0.93, 3.2, 2.8e7, 4.8e7)
distributionF = LogNormal(30000, 9000, 15000, LogNormal.MUSIGMA)
distributionL = Uniform(250, 260)
distributionI = Beta(2.5, 4.0, 3.1e2, 4.5e2)
LogNormal_u = LogNormal(30000, 9000, 15000, LogNormal.MUSIGMA)
Corresponding Modelica model.

model A
  parameter Distribution distributionE = Beta(0.93, 3.2, 2.8e7, 4.8e7);
  parameter Distribution distributionF = LogNormal(30000, 9000, 15000, LogNormal.MUSIGMA);
  parameter Distribution distributionL = Uniform(250, 260);
  parameter Distribution distributionI = Beta(2.5, 4.0, 3.1e2, 4.5e2);
  Real u(distribution = LogNormal(30000, 9000, 15000, LogNormal.MUSIGMA)); // distribution name becomes <instancename>+\"_\"+<distribution name> 
end A;

"
  input BackendDAE.BackendDAE dae;
  output String distributions;
  output list<tuple<String,String>> distributionVarLst;
  
protected
  list<BackendDAE.Var> varLst;
  list<DAE.Distribution> dists;  
  list<String> sLst;
  String header;
  BackendDAE.BackendDAE dae2;
algorithm
    //print("enter, dae:");
  //BackendDump.dump(dae);
  dae2 := BackendDAEOptimize.removeParameters(dae);
  //print("removed parameters, dae2:");
  //BackendDump.dump(dae2);
  
  varLst := BackendDAEUtil.getAllVarLst(dae2); 
  varLst := List.select(varLst,BackendVariable.varHasDistributionAttribute);
  dists := List.map(varLst,BackendVariable.varDistribution);
  (sLst,distributionVarLst) := List.map1_2(List.threadTuple(dists,List.map(varLst,BackendVariable.varCref)),generateDistributionVariable,dae2);

  // reverse to get them in the proper order
  distributionVarLst := listReverse(distributionVarLst);
  sLst := listReverse(sLst);
  
  header := "# "+&intString(listLength(sLst))+&" distributions from Modelica model\n";
  distributions := stringDelimitList(header::sLst,"\n");
end generateDistributions;

protected function generateDistributionVariable " generates a distribution variable for the python script "
   input tuple<DAE.Distribution,DAE.ComponentRef> tpl;
   input BackendDAE.BackendDAE dae;
   output String str;
   output tuple<String,String> distributionVar "the name of the python variable for the distribution and the description (Modelica variable name), used later for generating the collection"; 
algorithm
  (str,distributionVar) := matchcontinue(tpl,dae)
  local 
    String name,args,varName,distVar;
    DAE.Exp arr,sarr,e1,e2,e3,e2_1,e3_1;
    DAE.ComponentRef cr;
    list<DAE.Exp> expl1,expl2;
    
    case((DAE.DISTRIBUTION(DAE.SCONST(name as "LogNormal"),DAE.ARRAY(array=expl1),DAE.ARRAY(array=expl2)),cr),dae) equation
      // e.g. distributionL = Beta(0.93, 3.2, 2.8e7, 4.8e7)
      // TODO:  make sure that the arguments are in correct order by looking at the expl2 list containing strings of argument names
      args = stringDelimitList(List.map(expl1,ExpressionDump.printExpStr),",");
      varName = ComponentReference.crefModelicaStr(cr);
      distVar ="distribution"+&varName; 
      // add LogNormal.MUSIGMA!
      str = distVar+& " = " +& name +& "(" +& args+& ", " +& "LogNormal.MUSIGMA)\n";
    then (str,(varName,distVar));    
    
    case((DAE.DISTRIBUTION(DAE.SCONST(name),DAE.ARRAY(array=expl1),DAE.ARRAY(array=expl2)),cr),dae) equation
      // e.g. distributionL = Beta(0.93, 3.2, 2.8e7, 4.8e7)
      // TODO:  make sure that the arguments are in correct order by looking at the expl2 list containing strings of argument names
      args = stringDelimitList(List.map(expl1,ExpressionDump.printExpStr),",");
      varName = ComponentReference.crefModelicaStr(cr);
      distVar ="distribution"+&varName; 
      str = distVar+& " = " +& name +& "("+&args+&")\n";
    then (str,(varName,distVar));
    case((DAE.DISTRIBUTION(e1,e2,e3),cr),dae) equation
      ((e2_1,_)) = BackendDAEUtil.extendArrExp((e2,(NONE(),false)));
      ((e3_1,_)) = BackendDAEUtil.extendArrExp((e3,(NONE(),false)));
      false = Expression.expEqual(e2,e2_1); // Prevent infinte recursion
      false = Expression.expEqual(e3,e3_1);
      //print("extended arr="+&ExpressionDump.printExpStr(e2_1)+&"\n");
      //print("extended sarr="+&ExpressionDump.printExpStr(e3_1)+&"\n");
      (str,distributionVar) = generateDistributionVariable((DAE.DISTRIBUTION(e1,e2_1,e3_1),cr),dae);
    then (str,distributionVar);
  end matchcontinue;
end generateDistributionVariable;

protected function generateCorrelationMatrix "
"
  input BackendDAE.BackendDAE dae;
  input Integer numDists "number of distributions == number of uncertain variables == size of correlation matrix";
  input list<String> uncertainVars;
  output String correlationMatrix;
protected
  array<DAE.Algorithm> algs; 
  DAE.Algorithm correlationAlg;
  String header;
algorithm 
  algs := BackendDAEUtil.getAlgorithms(dae);
  header := "RS = CorrelationMatrix("+&intString(numDists)+&")\n";
  SOME(correlationAlg) := Util.arrayFindFirstOnTrue(algs,hasCorrelationStatement);
  correlationMatrix := header +& generateCorrelationMatrix2(correlationAlg,uncertainVars);
end generateCorrelationMatrix;

protected function stripCorrelationFromDae "removes the correlation vector and it's corresponding algorithm section from the DAE.
This means that it must remove from two places, the variables and the equations"
  input BackendDAE.BackendDAE dae; 
  output BackendDAE.BackendDAE strippedDae;
protected
  BackendDAE.EqSystems eqs;
  BackendDAE.Shared shared;
algorithm
  BackendDAE.DAE(eqs,shared) := dae;
  eqs := List.map(eqs,stripCorrelationVarsAndEqns);
  eqs := List.select(eqs,eqnSystemNotZero);
  strippedDae := BackendDAE.DAE(eqs,shared);
end stripCorrelationFromDae;

protected function eqnSystemNotZero "returns true if system contains variables and equations"
   input BackendDAE.EqSystem eqs; 
   output Boolean notZero;
protected
  BackendDAE.EquationArray eqns;
  BackendDAE.Variables vars;
 algorithm
   BackendDAE.EQSYSTEM(orderedVars = vars,orderedEqs=eqns) := eqs;
   notZero := BackendVariable.varsSize(vars) > 0 and BackendDAEUtil.equationArraySize(eqns) > 0;
 end eqnSystemNotZero;

protected function stripCorrelationVarsAndEqns " help function "
  input BackendDAE.EqSystem eqsys;
  output BackendDAE.EqSystem outEqsys;
protected
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs = eqns)  := eqsys;
  vars := stripCorrelationVars(vars);
  eqns := stripCorrelationEqns(eqns); 
  outEqsys := BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING());
end stripCorrelationVarsAndEqns;

protected function stripCorrelationEqns "help function "
  input BackendDAE.EquationArray eqns;
  output BackendDAE.EquationArray outEqns;
protected
  list<BackendDAE.Equation> eqnLst;
algorithm
  (_,eqnLst) := List.splitOnTrue(BackendDAEUtil.equationList(eqns),equationIsCorrelationBinding);
  outEqns := BackendDAEUtil.listEquation(eqnLst);
end stripCorrelationEqns;

protected function equationIsCorrelationBinding "help function"
  input BackendDAE.Equation eqn;
  output Boolean res;
algorithm
  res := matchcontinue(eqn)
  local 
    list<DAE.ComponentRef> crs;
    DAE.Algorithm alg;

    case(BackendDAE.ALGORITHM(alg=alg))
       then 
         hasCorrelationStatement(alg);
    case(_) then false;
  end matchcontinue;
end equationIsCorrelationBinding;

protected function stripCorrelationVars " help function  "
  input BackendDAE.Variables vars;
  output BackendDAE.Variables outVars;
protected
  list<BackendDAE.Var> varLst;
algorithm
  (_,varLst) := List.splitOnTrue(BackendDAEUtil.varList(vars),isCorrelationVar);
  outVars := BackendDAEUtil.listVar(varLst); 
end stripCorrelationVars;

protected function isCorrelationVar "help function"
  input BackendDAE.Var var;
  output Boolean res;
algorithm
  res := matchcontinue(var)
  local 
    DAE.ComponentRef cr;
    
    case(var) equation
      cr = BackendVariable.varCref(var);
      true = isCorrelationVarCref(cr);      
    then true;
    case(_) then false;
  end matchcontinue;  
end isCorrelationVar;

protected function isCorrelationVarCref "help function"
 input DAE.ComponentRef cr;
 output Boolean res;
algorithm
  res := 0 == System.strcmp(ComponentReference.crefFirstIdent(cr),"correlation");  
end isCorrelationVarCref;
  
protected function hasCorrelationStatement " help function "
  input DAE.Algorithm alg;
  output Boolean res;
algorithm
  res := matchcontinue(alg)
  local 
    list<DAE.Statement> stmts;
    
    case(DAE.ALGORITHM_STMTS({})) then false;
    case(DAE.ALGORITHM_STMTS(DAE.STMT_ASSIGN_ARR(_,DAE.CREF_IDENT(ident="correlation"),_,_)::_)) then true;
    case(DAE.ALGORITHM_STMTS(_::stmts)) then hasCorrelationStatement(DAE.ALGORITHM_STMTS(stmts));
  end matchcontinue;
end hasCorrelationStatement;

protected function getCorrelationExp " help function "
  input DAE.Algorithm alg;
  output DAE.Exp res;
algorithm
  res := matchcontinue(alg)
  local 
    list<DAE.Statement> stmts;
    
    case(DAE.ALGORITHM_STMTS(DAE.STMT_ASSIGN_ARR(_,DAE.CREF_IDENT(ident="correlation"),res,_)::_)) then res;
    case(DAE.ALGORITHM_STMTS(_::stmts)) then getCorrelationExp(DAE.ALGORITHM_STMTS(stmts));
  end matchcontinue;
end getCorrelationExp;

protected function generateCorrelationMatrix2 "help function"
  input DAE.Algorithm correlationAlg;
  input list<String> uncertainVars;
  output String str;
protected 
  DAE.Exp exp;
  list<DAE.Exp> expl;
algorithm
  DAE.ARRAY(array=expl):= getCorrelationExp(correlationAlg);
  str := stringDelimitList(List.map1(expl,generateCorrelationMatrix3,uncertainVars),"\n");
end generateCorrelationMatrix2;

protected function generateCorrelationMatrix3 "help function"
  input DAE.Exp exp;
  input list<String> uncertainVars;
  output String str;
protected
  DAE.ComponentRef cr1,cr2;
  DAE.Exp val;
  String valStr;
  Integer p1,p2,plow,phigh;

algorithm
  DAE.CALL(path = Absyn.IDENT("Correlation"),expLst = {DAE.CREF(cr1,_),DAE.CREF(cr2,_),val}) := exp;
  valStr := ExpressionDump.printExpStr(val);
  p1 := List.position(ComponentReference.crefModelicaStr(cr1),uncertainVars);
  p2 := List.position(ComponentReference.crefModelicaStr(cr2),uncertainVars);
  plow := intMin(p1,p2);
  phigh := intMax(p1,p2);
  str := "RS["+&intString(plow)+&","+&intString(phigh)+&"] = "+&valStr;
end generateCorrelationMatrix3;   
  
protected function generateCollectionDistributions "
"
  input BackendDAE.BackendDAE dae;
  input list<tuple<String,String>> distributionVarLst;
  output String collectionDistributions;
protected
  String collectionVarName;
algorithm
  collectionVarName := "collectionMarginals";
  collectionDistributions := "# Initialization of the distribution collection:\n"
  +& collectionVarName+&" = DistributionCollection()\n"
  +& stringDelimitList(List.map1(distributionVarLst,generateCollectionDistributions2,(collectionVarName,dae)),"\n");   
end generateCollectionDistributions;

protected function getName "help function"
  input tuple<String,String> distVarTpl;
  output String outStr;
algorithm
 outStr := "\"" +& Util.tuple21(distVarTpl) +& "\"";
end getName;

protected function generateCollectionDistributions2 "help function"
  input tuple<String,String> distVarTpl;
  input tuple<String,BackendDAE.BackendDAE> tpl;
  output String str;
algorithm
  str := Util.tuple21(tpl)+& ".add(Distribution(" +& Util.tuple22(distVarTpl) +& ",\"" +&Util.tuple21(distVarTpl)+&"\"))";  
end generateCollectionDistributions2;

protected function generateInputDescriptions "
"
  input BackendDAE.BackendDAE dae;
  output String inputDescriptions;
algorithm
  inputDescriptions := "# input descriptions currently not used, set above";   

end generateInputDescriptions;

public function getFullSharePath
"@author: adrpo
 returns $OPENMODELICAHOME/share/omc/scripts/OpenTurns/"
 output String strFullSharePath;
algorithm
 strFullSharePath := 
   Settings.getInstallationDirectoryPath() +& 
   System.pathDelimiter() +& 
   cStrSharePath +& 
   System.pathDelimiter();  
end getFullSharePath;

public function getFullShareFileName
"@author: adrpo
 returns $OPENMODELICAHOME/share/omc/scripts/OpenTurns/FILE_NAME
 where FILE_NAME is given as input."
 input String strFileName;
 output String strFullShareFileName;
algorithm
 strFullShareFileName := getFullSharePath() +& strFileName;  
end getFullShareFileName;

public function runPythonScript
"@author: adrpo
 generates inStrPythonScriptFile.bat and calls it
 runs the OpenTurns python handler with the given script"
 input String inStrPythonScriptFile;
 output String outStrLogFile;
algorithm
  outStrLogFile := matchcontinue(inStrPythonScriptFile)
    local
      String cmdContents, logFile, cmdFile;
    case (inStrPythonScriptFile)
      equation
        cmdContents = System.readFile(getFullShareFileName(cStrInvokeOpenTurnsCmd));
        cmdContents = System.stringReplace(cmdContents, "<%pythonScriptOpenModelica%>", inStrPythonScriptFile);
        cmdFile = inStrPythonScriptFile +& ".bat";
        System.writeFile(cmdFile, cmdContents);
        logFile = inStrPythonScriptFile +& ".log";
        runCommand(cmdFile +& " > " +& logFile +& " 2>&1"); 
      then
        logFile;
  end matchcontinue;
end runPythonScript;

protected function runCommand
  input String cmd;
algorithm
  _ := matchcontinue(cmd)
    case (cmd)
      equation
        print("running: " +& cmd +& "\n");
        0 = System.systemCall(cmd);
      then
        ();
    case (cmd)
      equation
        print("running: " +& cmd +& "\n\tfailed!\nCheck the log file!\n");
      then
        ();
  end matchcontinue;      
end runCommand;

end OpenTURNS;
