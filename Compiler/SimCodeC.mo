package SimCodeC

protected constant Tpl.Text emptyTxt = Tpl.MEM_TEXT({}, {});

public import Tpl;

public import SimCode;
public import DAELow;
public import System;
public import Absyn;
public import DAE;
public import ClassInf;
public import Util;
public import Exp;
public import RTOpts;
public import Settings;

protected function fun_12
  input Tpl.Text in_txt;
  input Option<SimCode.SimulationSettings> in_i_simulationSettingsOpt;
  input String in_i_fileNamePrefix;
  input SimCode.SimCode in_i_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simulationSettingsOpt, in_i_fileNamePrefix, in_i_simCode)
    local
      Tpl.Text txt;
      String i_fileNamePrefix;
      SimCode.SimCode i_simCode;

    case ( txt,
           NONE,
           _,
           _ )
      then txt;

    case ( txt,
           _,
           i_fileNamePrefix,
           i_simCode )
      local
        Tpl.Text txt_1;
        Tpl.Text txt_0;
      equation
        txt_0 = simulationInitFile(emptyTxt, i_simCode);
        txt_1 = Tpl.writeStr(emptyTxt, i_fileNamePrefix);
        txt_1 = Tpl.writeTok(txt_1, Tpl.ST_STRING("_init.txt"));
        Tpl.textFile(txt_0, Tpl.textString(txt_1));
      then txt;
  end matchcontinue;
end fun_12;

public function translateModel
  input Tpl.Text in_txt;
  input SimCode.SimCode in_i_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simCode)
    local
      Tpl.Text txt;

    case ( txt,
           (i_simCode as SimCode.SIMCODE(fileNamePrefix = i_fileNamePrefix, functions = i_functions, externalFunctionIncludes = i_externalFunctionIncludes, simulationSettingsOpt = i_simulationSettingsOpt)) )
      local
        Option<SimCode.SimulationSettings> i_simulationSettingsOpt;
        list<String> i_externalFunctionIncludes;
        list<SimCode.Function> i_functions;
        String i_fileNamePrefix;
        SimCode.SimCode i_simCode;
        Tpl.Text txt_5;
        Tpl.Text txt_4;
        Tpl.Text txt_3;
        Tpl.Text txt_2;
        Tpl.Text txt_1;
        Tpl.Text txt_0;
      equation
        txt_0 = simulationFile(emptyTxt, i_simCode);
        txt_1 = Tpl.writeStr(emptyTxt, i_fileNamePrefix);
        txt_1 = Tpl.writeTok(txt_1, Tpl.ST_STRING(".cpp"));
        Tpl.textFile(txt_0, Tpl.textString(txt_1));
        txt_2 = simulationFunctionsFile(emptyTxt, i_functions, i_externalFunctionIncludes);
        txt_3 = Tpl.writeStr(emptyTxt, i_fileNamePrefix);
        txt_3 = Tpl.writeTok(txt_3, Tpl.ST_STRING("_functions.cpp"));
        Tpl.textFile(txt_2, Tpl.textString(txt_3));
        txt_4 = simulationMakefile(emptyTxt, i_simCode);
        txt_5 = Tpl.writeStr(emptyTxt, i_fileNamePrefix);
        txt_5 = Tpl.writeTok(txt_5, Tpl.ST_STRING(".makefile"));
        Tpl.textFile(txt_4, Tpl.textString(txt_5));
        txt = fun_12(txt, i_simulationSettingsOpt, i_fileNamePrefix, i_simCode);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end translateModel;

public function translateFunctions
  input Tpl.Text in_txt;
  input SimCode.FunctionCode in_i_functionCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_functionCode)
    local
      Tpl.Text txt;

    case ( txt,
           (i_functionCode as SimCode.FUNCTIONCODE(name = i_name, mainFunction = i_mainFunction, functions = i_functions, extraRecordDecls = i_extraRecordDecls, externalFunctionIncludes = i_externalFunctionIncludes)) )
      local
        list<String> i_externalFunctionIncludes;
        list<SimCode.RecordDeclaration> i_extraRecordDecls;
        list<SimCode.Function> i_functions;
        SimCode.Function i_mainFunction;
        String i_name;
        SimCode.FunctionCode i_functionCode;
        Tpl.Text txt_4;
        Tpl.Text txt_3;
        Tpl.Text txt_2;
        Tpl.Text txt_1;
        Tpl.Text i_filePrefix;
      equation
        i_filePrefix = Tpl.writeStr(emptyTxt, i_name);
        txt_1 = functionsFile(emptyTxt, i_mainFunction, i_functions, i_extraRecordDecls, i_externalFunctionIncludes);
        txt_2 = Tpl.writeText(emptyTxt, i_filePrefix);
        txt_2 = Tpl.writeTok(txt_2, Tpl.ST_STRING(".c"));
        Tpl.textFile(txt_1, Tpl.textString(txt_2));
        txt_3 = functionsMakefile(emptyTxt, i_functionCode);
        txt_4 = Tpl.writeText(emptyTxt, i_filePrefix);
        txt_4 = Tpl.writeTok(txt_4, Tpl.ST_STRING(".makefile"));
        Tpl.textFile(txt_3, Tpl.textString(txt_4));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end translateFunctions;

public function simulationFile
  input Tpl.Text in_txt;
  input SimCode.SimCode in_i_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simCode)
    local
      Tpl.Text txt;

    case ( txt,
           (i_simCode as SimCode.SIMCODE(modelInfo = i_modelInfo, extObjInfo = i_extObjInfo, allEquations = i_allEquations, nonStateContEquations = i_nonStateContEquations, removedEquations = i_removedEquations, algorithmAndEquationAsserts = i_algorithmAndEquationAsserts, nonStateDiscEquations = i_nonStateDiscEquations, zeroCrossings = i_zeroCrossings, zeroCrossingsNeedSave = i_zeroCrossingsNeedSave, helpVarInfo = i_helpVarInfo, allEquationsPlusWhen = i_allEquationsPlusWhen, whenClauses = i_whenClauses, discreteModelVars = i_discreteModelVars, delayedExps = i_delayedExps, stateContEquations = i_stateContEquations, initialEquations = i_initialEquations, residualEquations = i_residualEquations, parameterEquations = i_parameterEquations, JacobianMatrixes = i_JacobianMatrixes)) )
      local
        list<SimCode.JacobianMatrix> i_JacobianMatrixes;
        list<SimCode.SimEqSystem> i_parameterEquations;
        list<SimCode.SimEqSystem> i_residualEquations;
        list<SimCode.SimEqSystem> i_initialEquations;
        list<SimCode.SimEqSystem> i_stateContEquations;
        SimCode.DelayedExpression i_delayedExps;
        list<DAE.ComponentRef> i_discreteModelVars;
        list<SimCode.SimWhenClause> i_whenClauses;
        list<SimCode.SimEqSystem> i_allEquationsPlusWhen;
        list<SimCode.HelpVarInfo> i_helpVarInfo;
        list<list<SimCode.SimVar>> i_zeroCrossingsNeedSave;
        list<DAELow.ZeroCrossing> i_zeroCrossings;
        list<SimCode.SimEqSystem> i_nonStateDiscEquations;
        list<DAE.Statement> i_algorithmAndEquationAsserts;
        list<SimCode.SimEqSystem> i_removedEquations;
        list<SimCode.SimEqSystem> i_nonStateContEquations;
        list<SimCode.SimEqSystem> i_allEquations;
        SimCode.ExtObjInfo i_extObjInfo;
        SimCode.ModelInfo i_modelInfo;
        SimCode.SimCode i_simCode;
      equation
        txt = simulationFileHeader(txt, i_simCode);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = globalData(txt, i_modelInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionGetName(txt, i_modelInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionDivisionError(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionSetLocalData(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionInitializeDataStruc(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionCallExternalObjectConstructors(txt, i_extObjInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionDeInitializeDataStruc(txt, i_extObjInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionExtraResiduals(txt, i_allEquations);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionDaeOutput(txt, i_nonStateContEquations, i_removedEquations, i_algorithmAndEquationAsserts);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionDaeOutput2(txt, i_nonStateDiscEquations, i_removedEquations);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionInput(txt, i_modelInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionOutput(txt, i_modelInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionDaeRes(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionZeroCrossing(txt, i_zeroCrossings);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionHandleZeroCrossing(txt, i_zeroCrossingsNeedSave);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionInitSample(txt, i_zeroCrossings);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionUpdateDependents(txt, i_allEquations, i_helpVarInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionUpdateDepend(txt, i_allEquationsPlusWhen, i_whenClauses, i_helpVarInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionUpdateHelpVars(txt, i_helpVarInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionOnlyZeroCrossing(txt, i_zeroCrossings);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionCheckForDiscreteChanges(txt, i_discreteModelVars);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionStoreDelayed(txt, i_delayedExps);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionWhen(txt, i_whenClauses);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionOde(txt, i_stateContEquations);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionInitial(txt, i_initialEquations);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionInitialResidual(txt, i_residualEquations);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionBoundParameters(txt, i_parameterEquations);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionCheckForDiscreteVarChanges(txt, i_helpVarInfo, i_discreteModelVars);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = generateLinearMatrixes(txt, i_JacobianMatrixes);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionlinearmodel(txt, i_modelInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end simulationFile;

public function simulationFileHeader
  input Tpl.Text in_txt;
  input SimCode.SimCode in_i_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simCode)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMCODE(modelInfo = SimCode.MODELINFO(name = i_modelInfo_name), extObjInfo = SimCode.EXTOBJINFO(includes = _), fileNamePrefix = i_fileNamePrefix) )
      local
        String i_fileNamePrefix;
        Absyn.Path i_modelInfo_name;
        String ret_0;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("// Simulation code for "));
        txt = dotPath(txt, i_modelInfo_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" generated by the OpenModelica Compiler "));
        ret_0 = Settings.getVersionNr();
        txt = Tpl.writeStr(txt, ret_0);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ".\n",
                                    "\n",
                                    "#include \"modelica.h\"\n",
                                    "#include \"assert.h\"\n",
                                    "#include \"string.h\"\n",
                                    "#include \"simulation_runtime.h\"\n",
                                    "\n",
                                    "#if defined(_MSC_VER) && !defined(_SIMULATION_RUNTIME_H)\n",
                                    "  #define DLLExport   __declspec( dllexport )\n",
                                    "#else\n",
                                    "  #define DLLExport /* nothing */\n",
                                    "#endif\n",
                                    "\n",
                                    "#include \""
                                }, false));
        txt = Tpl.writeStr(txt, i_fileNamePrefix);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "_functions.cpp\"\n",
                                    "\n"
                                }, true));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end simulationFileHeader;

protected function lm_17
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = globalDataVarDefine(txt, i_var, "states");
        txt = Tpl.nextIter(txt);
        txt = lm_17(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_17(txt, rest);
      then txt;
  end matchcontinue;
end lm_17;

protected function lm_18
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = globalDataVarDefine(txt, i_var, "statesDerivatives");
        txt = Tpl.nextIter(txt);
        txt = lm_18(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_18(txt, rest);
      then txt;
  end matchcontinue;
end lm_18;

protected function lm_19
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = globalDataVarDefine(txt, i_var, "algebraics");
        txt = Tpl.nextIter(txt);
        txt = lm_19(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_19(txt, rest);
      then txt;
  end matchcontinue;
end lm_19;

protected function lm_20
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = globalDataVarDefine(txt, i_var, "parameters");
        txt = Tpl.nextIter(txt);
        txt = lm_20(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_20(txt, rest);
      then txt;
  end matchcontinue;
end lm_20;

protected function lm_21
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = globalDataVarDefine(txt, i_var, "extObjs");
        txt = Tpl.nextIter(txt);
        txt = lm_21(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_21(txt, rest);
      then txt;
  end matchcontinue;
end lm_21;

protected function lm_22
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = globalDataVarDefine(txt, i_var, "intVariables.algebraics");
        txt = Tpl.nextIter(txt);
        txt = lm_22(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_22(txt, rest);
      then txt;
  end matchcontinue;
end lm_22;

protected function lm_23
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = globalDataVarDefine(txt, i_var, "intVariables.parameters");
        txt = Tpl.nextIter(txt);
        txt = lm_23(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_23(txt, rest);
      then txt;
  end matchcontinue;
end lm_23;

protected function lm_24
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = globalDataVarDefine(txt, i_var, "boolVariables.algebraics");
        txt = Tpl.nextIter(txt);
        txt = lm_24(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_24(txt, rest);
      then txt;
  end matchcontinue;
end lm_24;

protected function lm_25
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = globalDataVarDefine(txt, i_var, "boolVariables.parameters");
        txt = Tpl.nextIter(txt);
        txt = lm_25(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_25(txt, rest);
      then txt;
  end matchcontinue;
end lm_25;

protected function lm_26
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = globalDataVarDefine(txt, i_var, "stringVariables.algebraics");
        txt = Tpl.nextIter(txt);
        txt = lm_26(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_26(txt, rest);
      then txt;
  end matchcontinue;
end lm_26;

protected function lm_27
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = globalDataVarDefine(txt, i_var, "stringVariables.parameters");
        txt = Tpl.nextIter(txt);
        txt = lm_27(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_27(txt, rest);
      then txt;
  end matchcontinue;
end lm_27;

protected function lm_28
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(isFixed = i_isFixed, name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Boolean i_isFixed;
      equation
        txt = globalDataFixedInt(txt, i_isFixed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_28(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_28(txt, rest);
      then txt;
  end matchcontinue;
end lm_28;

protected function lm_29
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(isFixed = i_isFixed, name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Boolean i_isFixed;
      equation
        txt = globalDataFixedInt(txt, i_isFixed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_29(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_29(txt, rest);
      then txt;
  end matchcontinue;
end lm_29;

protected function lm_30
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(isFixed = i_isFixed, name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Boolean i_isFixed;
      equation
        txt = globalDataFixedInt(txt, i_isFixed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_30(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_30(txt, rest);
      then txt;
  end matchcontinue;
end lm_30;

protected function lm_31
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(isFixed = i_isFixed, name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Boolean i_isFixed;
      equation
        txt = globalDataFixedInt(txt, i_isFixed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_31(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_31(txt, rest);
      then txt;
  end matchcontinue;
end lm_31;

protected function lm_32
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(isFixed = i_isFixed, name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Boolean i_isFixed;
      equation
        txt = globalDataFixedInt(txt, i_isFixed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_32(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_32(txt, rest);
      then txt;
  end matchcontinue;
end lm_32;

protected function lm_33
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(isFixed = i_isFixed, name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Boolean i_isFixed;
      equation
        txt = globalDataFixedInt(txt, i_isFixed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_33(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_33(txt, rest);
      then txt;
  end matchcontinue;
end lm_33;

protected function lm_34
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(isFixed = i_isFixed, name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Boolean i_isFixed;
      equation
        txt = globalDataFixedInt(txt, i_isFixed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_34(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_34(txt, rest);
      then txt;
  end matchcontinue;
end lm_34;

protected function lm_35
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(isFixed = i_isFixed, name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Boolean i_isFixed;
      equation
        txt = globalDataFixedInt(txt, i_isFixed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_35(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_35(txt, rest);
      then txt;
  end matchcontinue;
end lm_35;

protected function smf_36
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_36;

protected function smf_37
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_37;

protected function smf_38
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_38;

protected function smf_39
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_39;

protected function smf_40
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_40;

protected function smf_41
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_41;

protected function smf_42
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_42;

protected function smf_43
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_43;

protected function lm_44
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(type_ = i_type__, isDiscrete = i_isDiscrete, name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Boolean i_isDiscrete;
        DAE.ExpType i_type__;
      equation
        txt = globalDataAttrInt(txt, i_type__);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("+"));
        txt = globalDataDiscAttrInt(txt, i_isDiscrete);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_44(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_44(txt, rest);
      then txt;
  end matchcontinue;
end lm_44;

protected function lm_45
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(type_ = i_type__, isDiscrete = i_isDiscrete, name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Boolean i_isDiscrete;
        DAE.ExpType i_type__;
      equation
        txt = globalDataAttrInt(txt, i_type__);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("+"));
        txt = globalDataDiscAttrInt(txt, i_isDiscrete);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_45(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_45(txt, rest);
      then txt;
  end matchcontinue;
end lm_45;

protected function lm_46
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(type_ = i_type__, isDiscrete = i_isDiscrete, name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Boolean i_isDiscrete;
        DAE.ExpType i_type__;
      equation
        txt = globalDataAttrInt(txt, i_type__);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("+"));
        txt = globalDataDiscAttrInt(txt, i_isDiscrete);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_46(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_46(txt, rest);
      then txt;
  end matchcontinue;
end lm_46;

protected function lm_47
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(type_ = i_type__, isDiscrete = i_isDiscrete, name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Boolean i_isDiscrete;
        DAE.ExpType i_type__;
      equation
        txt = globalDataAttrInt(txt, i_type__);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("+"));
        txt = globalDataDiscAttrInt(txt, i_isDiscrete);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_47(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_47(txt, rest);
      then txt;
  end matchcontinue;
end lm_47;

protected function lm_48
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(type_ = i_type__, isDiscrete = i_isDiscrete, name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Boolean i_isDiscrete;
        DAE.ExpType i_type__;
      equation
        txt = globalDataAttrInt(txt, i_type__);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("+"));
        txt = globalDataDiscAttrInt(txt, i_isDiscrete);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_48(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_48(txt, rest);
      then txt;
  end matchcontinue;
end lm_48;

protected function lm_49
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(type_ = i_type__, isDiscrete = i_isDiscrete, name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Boolean i_isDiscrete;
        DAE.ExpType i_type__;
      equation
        txt = globalDataAttrInt(txt, i_type__);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("+"));
        txt = globalDataDiscAttrInt(txt, i_isDiscrete);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_49(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_49(txt, rest);
      then txt;
  end matchcontinue;
end lm_49;

protected function lm_50
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(type_ = i_type__, isDiscrete = i_isDiscrete, name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Boolean i_isDiscrete;
        DAE.ExpType i_type__;
      equation
        txt = globalDataAttrInt(txt, i_type__);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("+"));
        txt = globalDataDiscAttrInt(txt, i_isDiscrete);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_50(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_50(txt, rest);
      then txt;
  end matchcontinue;
end lm_50;

protected function lm_51
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(type_ = i_type__, isDiscrete = i_isDiscrete, name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Boolean i_isDiscrete;
        DAE.ExpType i_type__;
      equation
        txt = globalDataAttrInt(txt, i_type__);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("+"));
        txt = globalDataDiscAttrInt(txt, i_isDiscrete);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_51(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_51(txt, rest);
      then txt;
  end matchcontinue;
end lm_51;

protected function lm_52
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(type_ = i_type__, isDiscrete = i_isDiscrete, name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Boolean i_isDiscrete;
        DAE.ExpType i_type__;
      equation
        txt = globalDataAttrInt(txt, i_type__);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("+"));
        txt = globalDataDiscAttrInt(txt, i_isDiscrete);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_52(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_52(txt, rest);
      then txt;
  end matchcontinue;
end lm_52;

protected function smf_53
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_53;

protected function smf_54
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_54;

protected function smf_55
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_55;

protected function smf_56
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_56;

protected function smf_57
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_57;

protected function smf_58
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_58;

protected function smf_59
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_59;

protected function smf_60
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_60;

protected function smf_61
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_61;

public function globalData
  input Tpl.Text in_txt;
  input SimCode.ModelInfo in_i_modelInfo;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_modelInfo)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.MODELINFO(varInfo = SimCode.VARINFO(numHelpVars = i_varInfo_numHelpVars, numZeroCrossings = i_varInfo_numZeroCrossings, numTimeEvents = i_varInfo_numTimeEvents, numStateVars = i_varInfo_numStateVars, numAlgVars = i_varInfo_numAlgVars, numParams = i_varInfo_numParams, numOutVars = i_varInfo_numOutVars, numInVars = i_varInfo_numInVars, numResiduals = i_varInfo_numResiduals, numExternalObjects = i_varInfo_numExternalObjects, numStringAlgVars = i_varInfo_numStringAlgVars, numStringParamVars = i_varInfo_numStringParamVars, numIntAlgVars = i_varInfo_numIntAlgVars, numIntParams = i_varInfo_numIntParams, numBoolAlgVars = i_varInfo_numBoolAlgVars, numBoolParams = i_varInfo_numBoolParams), vars = SimCode.SIMVARS(stateVars = i_vars_stateVars, derivativeVars = i_vars_derivativeVars, algVars = i_vars_algVars, inputVars = i_vars_inputVars, outputVars = i_vars_outputVars, paramVars = i_vars_paramVars, intAlgVars = i_vars_intAlgVars, intParamVars = i_vars_intParamVars, boolAlgVars = i_vars_boolAlgVars, boolParamVars = i_vars_boolParamVars, stringAlgVars = i_vars_stringAlgVars, stringParamVars = i_vars_stringParamVars, extObjVars = i_vars_extObjVars), name = i_name, directory = i_directory) )
      local
        String i_directory;
        Absyn.Path i_name;
        list<SimCode.SimVar> i_vars_extObjVars;
        list<SimCode.SimVar> i_vars_stringParamVars;
        list<SimCode.SimVar> i_vars_stringAlgVars;
        list<SimCode.SimVar> i_vars_boolParamVars;
        list<SimCode.SimVar> i_vars_boolAlgVars;
        list<SimCode.SimVar> i_vars_intParamVars;
        list<SimCode.SimVar> i_vars_intAlgVars;
        list<SimCode.SimVar> i_vars_paramVars;
        list<SimCode.SimVar> i_vars_outputVars;
        list<SimCode.SimVar> i_vars_inputVars;
        list<SimCode.SimVar> i_vars_algVars;
        list<SimCode.SimVar> i_vars_derivativeVars;
        list<SimCode.SimVar> i_vars_stateVars;
        Integer i_varInfo_numBoolParams;
        Integer i_varInfo_numBoolAlgVars;
        Integer i_varInfo_numIntParams;
        Integer i_varInfo_numIntAlgVars;
        Integer i_varInfo_numStringParamVars;
        Integer i_varInfo_numStringAlgVars;
        Integer i_varInfo_numExternalObjects;
        Integer i_varInfo_numResiduals;
        Integer i_varInfo_numInVars;
        Integer i_varInfo_numOutVars;
        Integer i_varInfo_numParams;
        Integer i_varInfo_numAlgVars;
        Integer i_varInfo_numStateVars;
        Integer i_varInfo_numTimeEvents;
        Integer i_varInfo_numZeroCrossings;
        Integer i_varInfo_numHelpVars;
        Tpl.Text txt_16;
        Tpl.Text txt_15;
        Tpl.Text txt_14;
        Tpl.Text txt_13;
        Tpl.Text txt_12;
        Tpl.Text txt_11;
        Tpl.Text txt_10;
        Tpl.Text txt_9;
        Tpl.Text txt_8;
        Tpl.Text txt_7;
        Tpl.Text txt_6;
        Tpl.Text txt_5;
        Tpl.Text txt_4;
        Tpl.Text txt_3;
        Tpl.Text txt_2;
        Tpl.Text txt_1;
        Tpl.Text txt_0;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define NHELP "));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numHelpVars));
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define NG "));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numZeroCrossings));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // number of zero crossings\n",
                                    "#define NG_SAM "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numTimeEvents));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // number of zero crossings that are samples\n",
                                    "#define NX "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numStateVars));
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define NY "));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numAlgVars));
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define NP "));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numParams));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // number of parameters\n",
                                    "#define NO "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numOutVars));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // number of outputvar on topmodel\n",
                                    "#define NI "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numInVars));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // number of inputvar on topmodel\n",
                                    "#define NR "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numResiduals));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // number of residuals for initialialization function\n",
                                    "#define NEXT "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numExternalObjects));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // number of external objects\n",
                                    "#define MAXORD 5\n",
                                    "#define NYSTR "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numStringAlgVars));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // number of alg. string variables\n",
                                    "#define NPSTR "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numStringParamVars));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // number of alg. string variables\n",
                                    "#define NYINT "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numIntAlgVars));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // number of alg. int variables\n",
                                    "#define NPINT "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numIntParams));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // number of alg. int variables\n",
                                    "#define NYBOOL "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numBoolAlgVars));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // number of alg. bool variables\n",
                                    "#define NPBOOL "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numBoolParams));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // number of alg. bool variables\n",
                                    "\n",
                                    "static DATA* localData = 0;\n",
                                    "#define time localData->timeValue\n",
                                    "#define $P$old$Ptime localData->oldTime\n",
                                    "#define $P$current_step_size globalData->current_stepsize\n",
                                    "\n",
                                    "extern \"C\" { // adrpo: this is needed for Visual C++ compilation to work!\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("const char *model_name=\""));
        txt = dotPath(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\";\n",
                                    "const char *model_dir=\""
                                }, false));
        txt = Tpl.writeStr(txt, i_directory);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("\";\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "\n",
                                    "// we need to access the inline define that we compiled the simulation with\n",
                                    "// from the simulation runtime.\n",
                                    "const char *_omc_force_solver=_OMC_FORCE_SOLVER;\n",
                                    "const int inline_work_states_ndims=_OMC_SOLVER_WORK_STATES_NDIMS;\n",
                                    "\n"
                                }, true));
        txt = globalDataVarNamesArray(txt, "state_names", i_vars_stateVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarNamesArray(txt, "derivative_names", i_vars_derivativeVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarNamesArray(txt, "algvars_names", i_vars_algVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarNamesArray(txt, "input_names", i_vars_inputVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarNamesArray(txt, "output_names", i_vars_outputVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarNamesArray(txt, "param_names", i_vars_paramVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarNamesArray(txt, "int_alg_names", i_vars_intAlgVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarNamesArray(txt, "int_param_names", i_vars_intParamVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarNamesArray(txt, "bool_alg_names", i_vars_boolAlgVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarNamesArray(txt, "bool_param_names", i_vars_boolParamVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarNamesArray(txt, "string_alg_names", i_vars_stringAlgVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarNamesArray(txt, "string_param_names", i_vars_stringParamVars);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = globalDataVarCommentsArray(txt, "state_comments", i_vars_stateVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarCommentsArray(txt, "derivative_comments", i_vars_derivativeVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarCommentsArray(txt, "algvars_comments", i_vars_algVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarCommentsArray(txt, "input_comments", i_vars_inputVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarCommentsArray(txt, "output_comments", i_vars_outputVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarCommentsArray(txt, "param_comments", i_vars_paramVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarCommentsArray(txt, "int_alg_comments", i_vars_intAlgVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarCommentsArray(txt, "int_param_comments", i_vars_intParamVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarCommentsArray(txt, "bool_alg_comments", i_vars_boolAlgVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarCommentsArray(txt, "bool_param_comments", i_vars_boolParamVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarCommentsArray(txt, "string_alg_comments", i_vars_stringAlgVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarCommentsArray(txt, "string_param_comments", i_vars_stringParamVars);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_17(txt, i_vars_stateVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_18(txt, i_vars_derivativeVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_19(txt, i_vars_algVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_20(txt, i_vars_paramVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_21(txt, i_vars_extObjVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_22(txt, i_vars_intAlgVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_23(txt, i_vars_intParamVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_24(txt, i_vars_boolAlgVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_25(txt, i_vars_boolParamVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_26(txt, i_vars_stringAlgVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_27(txt, i_vars_stringParamVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "static char init_fixed[NX+NX+NY+NYINT+NYBOOL+NYSTR+NP+NPINT+NPBOOL+NPSTR] = {\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt_0 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_0 = lm_28(txt_0, i_vars_stateVars);
        txt_0 = Tpl.popIter(txt_0);
        txt_1 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_1 = lm_29(txt_1, i_vars_derivativeVars);
        txt_1 = Tpl.popIter(txt_1);
        txt_2 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_2 = lm_30(txt_2, i_vars_algVars);
        txt_2 = Tpl.popIter(txt_2);
        txt_3 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_3 = lm_31(txt_3, i_vars_intAlgVars);
        txt_3 = Tpl.popIter(txt_3);
        txt_4 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_4 = lm_32(txt_4, i_vars_boolAlgVars);
        txt_4 = Tpl.popIter(txt_4);
        txt_5 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_5 = lm_33(txt_5, i_vars_paramVars);
        txt_5 = Tpl.popIter(txt_5);
        txt_6 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_6 = lm_34(txt_6, i_vars_intParamVars);
        txt_6 = Tpl.popIter(txt_6);
        txt_7 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_7 = lm_35(txt_7, i_vars_boolParamVars);
        txt_7 = Tpl.popIter(txt_7);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = smf_36(txt, txt_0);
        txt = smf_37(txt, txt_1);
        txt = smf_38(txt, txt_2);
        txt = smf_39(txt, txt_3);
        txt = smf_40(txt, txt_4);
        txt = smf_41(txt, txt_5);
        txt = smf_42(txt, txt_6);
        txt = smf_43(txt, txt_7);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "};\n",
                                    "\n",
                                    "char var_attr[NX+NY+NYINT+NYBOOL+NYSTR+NP+NPINT+NPBOOL+NPSTR] = {\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt_8 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_8 = lm_44(txt_8, i_vars_stateVars);
        txt_8 = Tpl.popIter(txt_8);
        txt_9 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_9 = lm_45(txt_9, i_vars_algVars);
        txt_9 = Tpl.popIter(txt_9);
        txt_10 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_10 = lm_46(txt_10, i_vars_intAlgVars);
        txt_10 = Tpl.popIter(txt_10);
        txt_11 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_11 = lm_47(txt_11, i_vars_boolAlgVars);
        txt_11 = Tpl.popIter(txt_11);
        txt_12 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_12 = lm_48(txt_12, i_vars_stringAlgVars);
        txt_12 = Tpl.popIter(txt_12);
        txt_13 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_13 = lm_49(txt_13, i_vars_paramVars);
        txt_13 = Tpl.popIter(txt_13);
        txt_14 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_14 = lm_50(txt_14, i_vars_intParamVars);
        txt_14 = Tpl.popIter(txt_14);
        txt_15 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_15 = lm_51(txt_15, i_vars_boolParamVars);
        txt_15 = Tpl.popIter(txt_15);
        txt_16 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_16 = lm_52(txt_16, i_vars_stringParamVars);
        txt_16 = Tpl.popIter(txt_16);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = smf_53(txt, txt_8);
        txt = smf_54(txt, txt_9);
        txt = smf_55(txt, txt_10);
        txt = smf_56(txt, txt_11);
        txt = smf_57(txt, txt_12);
        txt = smf_58(txt, txt_13);
        txt = smf_59(txt, txt_14);
        txt = smf_60(txt, txt_15);
        txt = smf_61(txt, txt_16);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("};"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end globalData;

protected function lm_63
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = Tpl.nextIter(txt);
        txt = lm_63(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_63(txt, rest);
      then txt;
  end matchcontinue;
end lm_63;

protected function fun_64
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_i_items;
  input String in_i_name;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_items, in_i_name)
    local
      Tpl.Text txt;
      String i_name;

    case ( txt,
           {},
           i_name )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("const char* "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("[1] = {\"\"};"));
      then txt;

    case ( txt,
           i_items,
           i_name )
      local
        list<SimCode.SimVar> i_items;
        Integer ret_1;
        Tpl.Text i_itemsStr;
      equation
        i_itemsStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        i_itemsStr = lm_63(i_itemsStr, i_items);
        i_itemsStr = Tpl.popIter(i_itemsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("const char* "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        ret_1 = listLength(i_items);
        txt = Tpl.writeStr(txt, intString(ret_1));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = {"));
        txt = Tpl.writeText(txt, i_itemsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("};"));
      then txt;
  end matchcontinue;
end fun_64;

public function globalDataVarNamesArray
  input Tpl.Text txt;
  input String i_name;
  input list<SimCode.SimVar> i_items;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_64(txt, i_items, i_name);
end globalDataVarNamesArray;

protected function lm_66
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(comment = i_comment) :: rest )
      local
        list<SimCode.SimVar> rest;
        String i_comment;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = Tpl.writeStr(txt, i_comment);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = Tpl.nextIter(txt);
        txt = lm_66(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_66(txt, rest);
      then txt;
  end matchcontinue;
end lm_66;

protected function fun_67
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_i_items;
  input String in_i_name;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_items, in_i_name)
    local
      Tpl.Text txt;
      String i_name;

    case ( txt,
           {},
           i_name )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("const char* "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("[1] = {\"\"};"));
      then txt;

    case ( txt,
           i_items,
           i_name )
      local
        list<SimCode.SimVar> i_items;
        Integer ret_1;
        Tpl.Text i_itemsStr;
      equation
        i_itemsStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        i_itemsStr = lm_66(i_itemsStr, i_items);
        i_itemsStr = Tpl.popIter(i_itemsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("const char* "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        ret_1 = listLength(i_items);
        txt = Tpl.writeStr(txt, intString(ret_1));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = {"));
        txt = Tpl.writeText(txt, i_itemsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("};"));
      then txt;
  end matchcontinue;
end fun_67;

public function globalDataVarCommentsArray
  input Tpl.Text txt;
  input String i_name;
  input list<SimCode.SimVar> i_items;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_67(txt, i_items, i_name);
end globalDataVarCommentsArray;

public function globalDataVarDefine
  input Tpl.Text in_txt;
  input SimCode.SimVar in_i_simVar;
  input String in_i_arrayName;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simVar, in_i_arrayName)
    local
      Tpl.Text txt;
      String i_arrayName;

    case ( txt,
           SimCode.SIMVAR(arrayCref = SOME(i_c), index = i_index, name = i_name),
           i_arrayName )
      local
        DAE.ComponentRef i_name;
        Integer i_index;
        DAE.ComponentRef i_c;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define "));
        txt = cref(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" localData->"));
        txt = Tpl.writeStr(txt, i_arrayName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "]\n",
                                    "#define "
                                }, false));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" localData->"));
        txt = Tpl.writeStr(txt, i_arrayName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "]\n",
                                    "#define $P$old"
                                }, false));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" localData->old_"));
        txt = Tpl.writeStr(txt, i_arrayName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "]\n",
                                    "#define $P$old2"
                                }, false));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" localData->old_"));
        txt = Tpl.writeStr(txt, i_arrayName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("]"));
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name, index = i_index),
           i_arrayName )
      local
        Integer i_index;
        DAE.ComponentRef i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define "));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" localData->"));
        txt = Tpl.writeStr(txt, i_arrayName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "]\n",
                                    "#define $P$old"
                                }, false));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" localData->old_"));
        txt = Tpl.writeStr(txt, i_arrayName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "]\n",
                                    "#define $P$old2"
                                }, false));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" localData->old_"));
        txt = Tpl.writeStr(txt, i_arrayName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("]"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end globalDataVarDefine;

public function globalDataFixedInt
  input Tpl.Text in_txt;
  input Boolean in_i_isFixed;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_isFixed)
    local
      Tpl.Text txt;

    case ( txt,
           true )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("1"));
      then txt;

    case ( txt,
           false )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("0"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end globalDataFixedInt;

public function globalDataAttrInt
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_REAL() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("1"));
      then txt;

    case ( txt,
           DAE.ET_STRING() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("2"));
      then txt;

    case ( txt,
           DAE.ET_INT() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("4"));
      then txt;

    case ( txt,
           DAE.ET_BOOL() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("8"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end globalDataAttrInt;

public function globalDataDiscAttrInt
  input Tpl.Text in_txt;
  input Boolean in_i_isDiscrete;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_isDiscrete)
    local
      Tpl.Text txt;

    case ( txt,
           true )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("16"));
      then txt;

    case ( txt,
           false )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("0"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end globalDataDiscAttrInt;

protected function lm_73
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name, index = i_index) :: rest )
      local
        list<SimCode.SimVar> rest;
        Integer i_index;
        DAE.ComponentRef i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (&"));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == ptr) return state_names["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];"));
        txt = Tpl.nextIter(txt);
        txt = lm_73(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_73(txt, rest);
      then txt;
  end matchcontinue;
end lm_73;

protected function lm_74
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name, index = i_index) :: rest )
      local
        list<SimCode.SimVar> rest;
        Integer i_index;
        DAE.ComponentRef i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (&"));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == ptr) return derivative_names["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];"));
        txt = Tpl.nextIter(txt);
        txt = lm_74(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_74(txt, rest);
      then txt;
  end matchcontinue;
end lm_74;

protected function lm_75
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name, index = i_index) :: rest )
      local
        list<SimCode.SimVar> rest;
        Integer i_index;
        DAE.ComponentRef i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (&"));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == ptr) return algvars_names["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];"));
        txt = Tpl.nextIter(txt);
        txt = lm_75(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_75(txt, rest);
      then txt;
  end matchcontinue;
end lm_75;

protected function lm_76
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name, index = i_index) :: rest )
      local
        list<SimCode.SimVar> rest;
        Integer i_index;
        DAE.ComponentRef i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (&"));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == ptr) return param_names["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];"));
        txt = Tpl.nextIter(txt);
        txt = lm_76(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_76(txt, rest);
      then txt;
  end matchcontinue;
end lm_76;

protected function lm_77
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name, index = i_index) :: rest )
      local
        list<SimCode.SimVar> rest;
        Integer i_index;
        DAE.ComponentRef i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (&"));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == ptr) return int_alg_names["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];"));
        txt = Tpl.nextIter(txt);
        txt = lm_77(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_77(txt, rest);
      then txt;
  end matchcontinue;
end lm_77;

protected function lm_78
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name, index = i_index) :: rest )
      local
        list<SimCode.SimVar> rest;
        Integer i_index;
        DAE.ComponentRef i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (&"));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == ptr) return int_param_names["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];"));
        txt = Tpl.nextIter(txt);
        txt = lm_78(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_78(txt, rest);
      then txt;
  end matchcontinue;
end lm_78;

protected function lm_79
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name, index = i_index) :: rest )
      local
        list<SimCode.SimVar> rest;
        Integer i_index;
        DAE.ComponentRef i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (&"));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == ptr) return bool_alg_names["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];"));
        txt = Tpl.nextIter(txt);
        txt = lm_79(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_79(txt, rest);
      then txt;
  end matchcontinue;
end lm_79;

protected function lm_80
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name, index = i_index) :: rest )
      local
        list<SimCode.SimVar> rest;
        Integer i_index;
        DAE.ComponentRef i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (&"));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == ptr) return bool_param_names["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];"));
        txt = Tpl.nextIter(txt);
        txt = lm_80(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_80(txt, rest);
      then txt;
  end matchcontinue;
end lm_80;

public function functionGetName
  input Tpl.Text in_txt;
  input SimCode.ModelInfo in_i_modelInfo;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_modelInfo)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.MODELINFO(vars = SimCode.SIMVARS(stateVars = i_vars_stateVars, derivativeVars = i_vars_derivativeVars, algVars = i_vars_algVars, paramVars = i_vars_paramVars, intAlgVars = i_vars_intAlgVars, intParamVars = i_vars_intParamVars, boolAlgVars = i_vars_boolAlgVars, boolParamVars = i_vars_boolParamVars)) )
      local
        list<SimCode.SimVar> i_vars_boolParamVars;
        list<SimCode.SimVar> i_vars_boolAlgVars;
        list<SimCode.SimVar> i_vars_intParamVars;
        list<SimCode.SimVar> i_vars_intAlgVars;
        list<SimCode.SimVar> i_vars_paramVars;
        list<SimCode.SimVar> i_vars_algVars;
        list<SimCode.SimVar> i_vars_derivativeVars;
        list<SimCode.SimVar> i_vars_stateVars;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "const char* getName(double* ptr)\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_73(txt, i_vars_stateVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_74(txt, i_vars_derivativeVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_75(txt, i_vars_algVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_76(txt, i_vars_paramVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("return \"\";\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "\n",
                                    "const char* getName(modelica_integer* ptr)\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_77(txt, i_vars_intAlgVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_78(txt, i_vars_intParamVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("return \"\";\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "\n",
                                    "const char* getName(modelica_boolean* ptr)\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_79(txt, i_vars_boolAlgVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_80(txt, i_vars_boolParamVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("return \"\";\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "\n"
                                }, true));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end functionGetName;

public function functionDivisionError
  input Tpl.Text txt;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "/* Commented out by Frenkel TUD because there is a new implementation of\n",
                                   "   division by zero problem. */\n",
                                   "/*\n",
                                   "#define DIVISION(a,b,c) ((b != 0) ? a / b : a / division_error(b,c))\n",
                                   "\n",
                                   "int encounteredDivisionByZero = 0;\n",
                                   "\n",
                                   "double division_error(double b, const char* division_str)\n",
                                   "{\n",
                                   "  if(!encounteredDivisionByZero) {\n",
                                   "    fprintf(stderr, \"ERROR: Division by zero in partial equation: %s.\\n\",division_str);\n",
                                   "    encounteredDivisionByZero = 1;\n",
                                   "  }\n",
                                   "  return b;\n",
                                   "}\n",
                                   "*/"
                               }, false));
end functionDivisionError;

public function functionSetLocalData
  input Tpl.Text txt;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "void setLocalData(DATA* data)\n",
                                   "{\n",
                                   "  localData = data;\n",
                                   "}"
                               }, false));
end functionSetLocalData;

public function functionInitializeDataStruc
  input Tpl.Text txt;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "DATA* initializeDataStruc(DATA_FLAGS flags)\n",
                                   "{\n",
                                   "  DATA* returnData = (DATA*)malloc(sizeof(DATA));\n",
                                   "\n",
                                   "  if(!returnData) //error check\n",
                                   "    return 0;\n",
                                   "\n",
                                   "  memset(returnData,0,sizeof(DATA));\n",
                                   "  returnData->nStates = NX;\n",
                                   "  returnData->nAlgebraic = NY;\n",
                                   "  returnData->nParameters = NP;\n",
                                   "  returnData->nInputVars = NI;\n",
                                   "  returnData->nOutputVars = NO;\n",
                                   "  returnData->nZeroCrossing = NG;\n",
                                   "  returnData->nRawSamples = NG_SAM;\n",
                                   "  returnData->nInitialResiduals = NR;\n",
                                   "  returnData->nHelpVars = NHELP;\n",
                                   "  returnData->stringVariables.nParameters = NPSTR;\n",
                                   "  returnData->stringVariables.nAlgebraic = NYSTR;\n",
                                   "  returnData->intVariables.nParameters = NPINT;\n",
                                   "  returnData->intVariables.nAlgebraic = NYINT;\n",
                                   "  returnData->boolVariables.nParameters = NPBOOL;\n",
                                   "  returnData->boolVariables.nAlgebraic = NYBOOL;\n",
                                   "\n",
                                   "  if(flags & STATES && returnData->nStates) {\n",
                                   "    returnData->states = (double*) malloc(sizeof(double)*returnData->nStates);\n",
                                   "    returnData->old_states = (double*) malloc(sizeof(double)*returnData->nStates);\n",
                                   "    returnData->old_states2 = (double*) malloc(sizeof(double)*returnData->nStates);\n",
                                   "    assert(returnData->states&&returnData->old_states&&returnData->old_states2);\n",
                                   "    memset(returnData->states,0,sizeof(double)*returnData->nStates);\n",
                                   "    memset(returnData->old_states,0,sizeof(double)*returnData->nStates);\n",
                                   "    memset(returnData->old_states2,0,sizeof(double)*returnData->nStates);\n",
                                   "  } else {\n",
                                   "    returnData->states = 0;\n",
                                   "    returnData->old_states = 0;\n",
                                   "    returnData->old_states2 = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & STATESDERIVATIVES && returnData->nStates) {\n",
                                   "    returnData->statesDerivatives = (double*) malloc(sizeof(double)*returnData->nStates);\n",
                                   "    returnData->old_statesDerivatives = (double*) malloc(sizeof(double)*returnData->nStates);\n",
                                   "    returnData->old_statesDerivatives2 = (double*) malloc(sizeof(double)*returnData->nStates);\n",
                                   "    assert(returnData->statesDerivatives&&returnData->old_statesDerivatives&&returnData->old_statesDerivatives2);\n",
                                   "    memset(returnData->statesDerivatives,0,sizeof(double)*returnData->nStates);\n",
                                   "    memset(returnData->old_statesDerivatives,0,sizeof(double)*returnData->nStates);\n",
                                   "    memset(returnData->old_statesDerivatives2,0,sizeof(double)*returnData->nStates);\n",
                                   "  } else {\n",
                                   "    returnData->statesDerivatives = 0;\n",
                                   "    returnData->old_statesDerivatives = 0;\n",
                                   "    returnData->old_statesDerivatives2 = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & HELPVARS && returnData->nHelpVars) {\n",
                                   "    returnData->helpVars = (double*) malloc(sizeof(double)*returnData->nHelpVars);\n",
                                   "    assert(returnData->helpVars);\n",
                                   "    memset(returnData->helpVars,0,sizeof(double)*returnData->nHelpVars);\n",
                                   "  } else {\n",
                                   "    returnData->helpVars = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & ALGEBRAICS && returnData->nAlgebraic) {\n",
                                   "    returnData->algebraics = (double*) malloc(sizeof(double)*returnData->nAlgebraic);\n",
                                   "    returnData->old_algebraics = (double*) malloc(sizeof(double)*returnData->nAlgebraic);\n",
                                   "    returnData->old_algebraics2 = (double*) malloc(sizeof(double)*returnData->nAlgebraic);\n",
                                   "    assert(returnData->algebraics&&returnData->old_algebraics&&returnData->old_algebraics2);\n",
                                   "    memset(returnData->algebraics,0,sizeof(double)*returnData->nAlgebraic);\n",
                                   "    memset(returnData->old_algebraics,0,sizeof(double)*returnData->nAlgebraic);\n",
                                   "    memset(returnData->old_algebraics2,0,sizeof(double)*returnData->nAlgebraic);\n",
                                   "  } else {\n",
                                   "    returnData->algebraics = 0;\n",
                                   "    returnData->old_algebraics = 0;\n",
                                   "    returnData->old_algebraics2 = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if (flags & ALGEBRAICS && returnData->stringVariables.nAlgebraic) {\n",
                                   "    returnData->stringVariables.algebraics = (char**)malloc(sizeof(char*)*returnData->stringVariables.nAlgebraic);\n",
                                   "    assert(returnData->stringVariables.algebraics);\n",
                                   "    memset(returnData->stringVariables.algebraics,0,sizeof(char*)*returnData->stringVariables.nAlgebraic);\n",
                                   "  } else {\n",
                                   "    returnData->stringVariables.algebraics=0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if (flags & ALGEBRAICS && returnData->intVariables.nAlgebraic) {\n",
                                   "    returnData->intVariables.algebraics = (modelica_integer*)malloc(sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);\n",
                                   "    returnData->intVariables.old_algebraics = (modelica_integer*)malloc(sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);\n",
                                   "    returnData->intVariables.old_algebraics2 = (modelica_integer*)malloc(sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);\n",
                                   "    assert(returnData->intVariables.algebraics&&returnData->intVariables.old_algebraics&&returnData->intVariables.old_algebraics2);\n",
                                   "    memset(returnData->intVariables.algebraics,0,sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);\n",
                                   "    memset(returnData->intVariables.old_algebraics,0,sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);\n",
                                   "    memset(returnData->intVariables.old_algebraics2,0,sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);\n",
                                   "  } else {\n",
                                   "    returnData->intVariables.algebraics=0;\n",
                                   "    returnData->intVariables.old_algebraics = 0;\n",
                                   "    returnData->intVariables.old_algebraics2 = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if (flags & ALGEBRAICS && returnData->boolVariables.nAlgebraic) {\n",
                                   "    returnData->boolVariables.algebraics = (modelica_boolean*)malloc(sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);\n",
                                   "    returnData->boolVariables.old_algebraics = (signed char*)malloc(sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);\n",
                                   "    returnData->boolVariables.old_algebraics2 = (signed char*)malloc(sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);\n",
                                   "    assert(returnData->boolVariables.algebraics&&returnData->boolVariables.old_algebraics&&returnData->boolVariables.old_algebraics2);\n",
                                   "    memset(returnData->boolVariables.algebraics,0,sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);\n",
                                   "    memset(returnData->boolVariables.old_algebraics,0,sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);\n",
                                   "    memset(returnData->boolVariables.old_algebraics2,0,sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);\n",
                                   "  } else {\n",
                                   "    returnData->boolVariables.algebraics=0;\n",
                                   "    returnData->boolVariables.old_algebraics = 0;\n",
                                   "    returnData->boolVariables.old_algebraics2 = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & PARAMETERS && returnData->nParameters) {\n",
                                   "    returnData->parameters = (double*) malloc(sizeof(double)*returnData->nParameters);\n",
                                   "    assert(returnData->parameters);\n",
                                   "    memset(returnData->parameters,0,sizeof(double)*returnData->nParameters);\n",
                                   "  } else {\n",
                                   "    returnData->parameters = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if (flags & PARAMETERS && returnData->stringVariables.nParameters) {\n",
                                   "      returnData->stringVariables.parameters = (char**)malloc(sizeof(char*)*returnData->stringVariables.nParameters);\n",
                                   "      assert(returnData->stringVariables.parameters);\n",
                                   "      memset(returnData->stringVariables.parameters,0,sizeof(char*)*returnData->stringVariables.nParameters);\n",
                                   "  } else {\n",
                                   "      returnData->stringVariables.parameters=0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if (flags & PARAMETERS && returnData->intVariables.nParameters) {\n",
                                   "      returnData->intVariables.parameters = (modelica_integer*)malloc(sizeof(modelica_integer)*returnData->intVariables.nParameters);\n",
                                   "      assert(returnData->intVariables.parameters);\n",
                                   "      memset(returnData->intVariables.parameters,0,sizeof(modelica_integer)*returnData->intVariables.nParameters);\n",
                                   "  } else {\n",
                                   "      returnData->intVariables.parameters=0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if (flags & PARAMETERS && returnData->boolVariables.nParameters) {\n",
                                   "      returnData->boolVariables.parameters = (modelica_boolean*)malloc(sizeof(modelica_boolean)*returnData->boolVariables.nParameters);\n",
                                   "      assert(returnData->boolVariables.parameters);\n",
                                   "      memset(returnData->boolVariables.parameters,0,sizeof(modelica_boolean)*returnData->boolVariables.nParameters);\n",
                                   "  } else {\n",
                                   "      returnData->boolVariables.parameters=0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & OUTPUTVARS && returnData->nOutputVars) {\n",
                                   "    returnData->outputVars = (double*) malloc(sizeof(double)*returnData->nOutputVars);\n",
                                   "    assert(returnData->outputVars);\n",
                                   "    memset(returnData->outputVars,0,sizeof(double)*returnData->nOutputVars);\n",
                                   "  } else {\n",
                                   "    returnData->outputVars = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & INPUTVARS && returnData->nInputVars) {\n",
                                   "    returnData->inputVars = (double*) malloc(sizeof(double)*returnData->nInputVars);\n",
                                   "    assert(returnData->inputVars);\n",
                                   "    memset(returnData->inputVars,0,sizeof(double)*returnData->nInputVars);\n",
                                   "  } else {\n",
                                   "    returnData->inputVars = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & INITIALRESIDUALS && returnData->nInitialResiduals) {\n",
                                   "    returnData->initialResiduals = (double*) malloc(sizeof(double)*returnData->nInitialResiduals);\n",
                                   "    assert(returnData->initialResiduals);\n",
                                   "    memset(returnData->initialResiduals,0,sizeof(double)*returnData->nInitialResiduals);\n",
                                   "  } else {\n",
                                   "    returnData->initialResiduals = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & INITFIXED) {\n",
                                   "    returnData->initFixed = init_fixed;\n",
                                   "  } else {\n",
                                   "    returnData->initFixed = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  /*   names   */\n",
                                   "  if(flags & MODELNAME) {\n",
                                   "    returnData->modelName = model_name;\n",
                                   "  } else {\n",
                                   "    returnData->modelName = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & STATESNAMES) {\n",
                                   "    returnData->statesNames = state_names;\n",
                                   "  } else {\n",
                                   "    returnData->statesNames = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & STATESDERIVATIVESNAMES) {\n",
                                   "    returnData->stateDerivativesNames = derivative_names;\n",
                                   "  } else {\n",
                                   "    returnData->stateDerivativesNames = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & ALGEBRAICSNAMES) {\n",
                                   "    returnData->algebraicsNames = algvars_names;\n",
                                   "  } else {\n",
                                   "    returnData->algebraicsNames = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & ALGEBRAICSNAMES) {\n",
                                   "    returnData->int_alg_names = int_alg_names;\n",
                                   "  } else {\n",
                                   "    returnData->int_alg_names = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & ALGEBRAICSNAMES) {\n",
                                   "    returnData->bool_alg_names = bool_alg_names;\n",
                                   "  } else {\n",
                                   "    returnData->bool_alg_names = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & PARAMETERSNAMES) {\n",
                                   "    returnData->parametersNames = param_names;\n",
                                   "  } else {\n",
                                   "    returnData->parametersNames = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & PARAMETERSNAMES) {\n",
                                   "    returnData->int_param_names = int_param_names;\n",
                                   "  } else {\n",
                                   "    returnData->int_param_names = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & PARAMETERSNAMES) {\n",
                                   "    returnData->bool_param_names = bool_param_names;\n",
                                   "  } else {\n",
                                   "    returnData->bool_param_names = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & INPUTNAMES) {\n",
                                   "    returnData->inputNames = input_names;\n",
                                   "  } else {\n",
                                   "    returnData->inputNames = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & OUTPUTNAMES) {\n",
                                   "    returnData->outputNames = output_names;\n",
                                   "  } else {\n",
                                   "    returnData->outputNames = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  /*   comments  */\n",
                                   "  if(flags & STATESCOMMENTS) {\n",
                                   "    returnData->statesComments = state_comments;\n",
                                   "  } else {\n",
                                   "    returnData->statesComments = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & STATESDERIVATIVESCOMMENTS) {\n",
                                   "    returnData->stateDerivativesComments = derivative_comments;\n",
                                   "  } else {\n",
                                   "    returnData->stateDerivativesComments = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & ALGEBRAICSCOMMENTS) {\n",
                                   "    returnData->algebraicsComments = algvars_comments;\n",
                                   "  } else {\n",
                                   "    returnData->algebraicsComments = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & ALGEBRAICSCOMMENTS) {\n",
                                   "    returnData->int_alg_comments = int_alg_comments;\n",
                                   "  } else {\n",
                                   "    returnData->int_alg_comments = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & ALGEBRAICSCOMMENTS) {\n",
                                   "    returnData->bool_alg_comments = bool_alg_comments;\n",
                                   "  } else {\n",
                                   "    returnData->bool_alg_comments = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & PARAMETERSCOMMENTS) {\n",
                                   "    returnData->parametersComments = param_comments;\n",
                                   "  } else {\n",
                                   "    returnData->parametersComments = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & PARAMETERSCOMMENTS) {\n",
                                   "    returnData->int_param_comments = int_param_comments;\n",
                                   "  } else {\n",
                                   "    returnData->int_param_comments = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & PARAMETERSCOMMENTS) {\n",
                                   "    returnData->bool_param_comments = bool_param_comments;\n",
                                   "  } else {\n",
                                   "    returnData->bool_param_comments = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & INPUTCOMMENTS) {\n",
                                   "    returnData->inputComments = input_comments;\n",
                                   "  } else {\n",
                                   "    returnData->inputComments = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & OUTPUTCOMMENTS) {\n",
                                   "    returnData->outputComments = output_comments;\n",
                                   "  } else {\n",
                                   "    returnData->outputComments = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & RAWSAMPLES && returnData->nRawSamples) {\n",
                                   "    returnData->rawSampleExps = (sample_raw_time*) malloc(sizeof(sample_raw_time)*returnData->nRawSamples);\n",
                                   "    assert(returnData->rawSampleExps);\n",
                                   "    memset(returnData->rawSampleExps,0,sizeof(sample_raw_time)*returnData->nRawSamples);\n",
                                   "  } else {\n",
                                   "    returnData->rawSampleExps = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if (flags & EXTERNALVARS) {\n",
                                   "    returnData->extObjs = (void**)malloc(sizeof(void*)*NEXT);\n",
                                   "    if (!returnData->extObjs) {\n",
                                   "      printf(\"error allocating external objects\\n\");\n",
                                   "      exit(-2);\n",
                                   "    }\n",
                                   "    memset(returnData->extObjs,0,sizeof(void*)*NEXT);\n",
                                   "  }\n",
                                   "  return returnData;\n",
                                   "}\n",
                                   "\n"
                               }, true));
end functionInitializeDataStruc;

protected function lm_85
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;

    case ( txt,
           {},
           i_varDecls,
           i_preExp )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_arg :: rest,
           i_varDecls,
           i_preExp )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_arg;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_arg, SimCode.contextOther, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_85(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_85(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_85;

protected function lm_86
  input Tpl.Text in_txt;
  input list<SimCode.ExtConstructor> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;

    case ( txt,
           {},
           i_varDecls,
           i_preExp )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           (i_var, i_fnName, i_args) :: rest,
           i_varDecls,
           i_preExp )
      local
        list<SimCode.ExtConstructor> rest;
        list<DAE.Exp> i_args;
        String i_fnName;
        DAE.ComponentRef i_var;
        Tpl.Text i_argsStr;
      equation
        i_argsStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_argsStr, i_varDecls, i_preExp) = lm_85(i_argsStr, i_args, i_varDecls, i_preExp);
        i_argsStr = Tpl.popIter(i_argsStr);
        txt = cref(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeStr(txt, i_fnName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_argsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_86(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp )
      local
        list<SimCode.ExtConstructor> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_86(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_86;

protected function lm_87
  input Tpl.Text in_txt;
  input list<SimCode.ExtAlias> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_var1, i_var2) :: rest )
      local
        list<SimCode.ExtAlias> rest;
        DAE.ComponentRef i_var2;
        DAE.ComponentRef i_var1;
      equation
        txt = cref(txt, i_var1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = cref(txt, i_var2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_87(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.ExtAlias> rest;
      equation
        txt = lm_87(txt, rest);
      then txt;
  end matchcontinue;
end lm_87;

public function functionCallExternalObjectConstructors
  input Tpl.Text in_txt;
  input SimCode.ExtObjInfo in_i_extObjInfo;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_extObjInfo)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.EXTOBJINFO(constructors = i_constructors, aliases = i_aliases) )
      local
        list<SimCode.ExtAlias> i_aliases;
        list<SimCode.ExtConstructor> i_constructors;
        Tpl.Text i_ctorCalls;
        Tpl.Text i_preExp;
        Tpl.Text i_varDecls;
      equation
        i_varDecls = emptyTxt;
        i_preExp = emptyTxt;
        i_ctorCalls = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_ctorCalls, i_varDecls, i_preExp) = lm_86(i_ctorCalls, i_constructors, i_varDecls, i_preExp);
        i_ctorCalls = Tpl.popIter(i_ctorCalls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "/* Has to be performed after _init.txt file has been read */\n",
                                    "void callExternalObjectConstructors(DATA* localData) {\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_ctorCalls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_87(txt, i_aliases);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "\n"
                                }, true));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end functionCallExternalObjectConstructors;

protected function lm_89
  input Tpl.Text in_txt;
  input list<SimCode.ExtDestructor> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_fnName, i_var) :: rest )
      local
        list<SimCode.ExtDestructor> rest;
        DAE.ComponentRef i_var;
        String i_fnName;
      equation
        txt = Tpl.writeStr(txt, i_fnName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = cref(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.nextIter(txt);
        txt = lm_89(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.ExtDestructor> rest;
      equation
        txt = lm_89(txt, rest);
      then txt;
  end matchcontinue;
end lm_89;

public function functionDeInitializeDataStruc
  input Tpl.Text in_txt;
  input SimCode.ExtObjInfo in_i_extObjInfo;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_extObjInfo)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.EXTOBJINFO(destructors = i_destructors) )
      local
        list<SimCode.ExtDestructor> i_destructors;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "void deInitializeDataStruc(DATA* data, DATA_FLAGS flags)\n",
                                    "{\n",
                                    "  if(!data)\n",
                                    "    return;\n",
                                    "\n",
                                    "  if(flags & STATES && data->states) {\n",
                                    "    free(data->states);\n",
                                    "    data->states = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & STATES && data->old_states) {\n",
                                    "    free(data->old_states);\n",
                                    "    data->old_states = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & STATES && data->old_states2) {\n",
                                    "    free(data->old_states2);\n",
                                    "    data->old_states2 = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & STATESDERIVATIVES && data->statesDerivatives) {\n",
                                    "    free(data->statesDerivatives);\n",
                                    "    data->statesDerivatives = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & STATESDERIVATIVES && data->old_statesDerivatives) {\n",
                                    "    free(data->old_statesDerivatives);\n",
                                    "    data->old_statesDerivatives = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & STATESDERIVATIVES && data->old_statesDerivatives2) {\n",
                                    "    free(data->old_statesDerivatives2);\n",
                                    "    data->old_statesDerivatives2 = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & ALGEBRAICS && data->algebraics) {\n",
                                    "    free(data->algebraics);\n",
                                    "    data->algebraics = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & ALGEBRAICS && data->old_algebraics) {\n",
                                    "    free(data->old_algebraics);\n",
                                    "    data->old_algebraics = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & ALGEBRAICS && data->old_algebraics2) {\n",
                                    "    free(data->old_algebraics2);\n",
                                    "    data->old_algebraics2 = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & PARAMETERS && data->parameters) {\n",
                                    "    free(data->parameters);\n",
                                    "    data->parameters = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & OUTPUTVARS && data->inputVars) {\n",
                                    "    free(data->inputVars);\n",
                                    "    data->inputVars = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & INPUTVARS && data->outputVars) {\n",
                                    "    free(data->outputVars);\n",
                                    "    data->outputVars = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & INITIALRESIDUALS && data->initialResiduals){\n",
                                    "    free(data->initialResiduals);\n",
                                    "    data->initialResiduals = 0;\n",
                                    "  }\n",
                                    "  if (flags & EXTERNALVARS && data->extObjs) {\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(4));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_89(txt, i_destructors);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "free(data->extObjs);\n",
                                    "data->extObjs = 0;\n"
                                }, true));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "  }\n",
                                    "  if(flags & RAWSAMPLES && data->rawSampleExps) {\n",
                                    "    free(data->rawSampleExps);\n",
                                    "    data->rawSampleExps = 0;\n",
                                    "  }\n",
                                    "  if(flags & RAWSAMPLES && data->sampleTimes) {\n",
                                    "    free(data->sampleTimes);\n",
                                    "    data->sampleTimes = 0;\n",
                                    "  }\n",
                                    "}"
                                }, false));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end functionDeInitializeDataStruc;

protected function lm_91
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_eq :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        SimCode.SimEqSystem i_eq;
      equation
        (txt, i_varDecls) = equation_(txt, i_eq, SimCode.contextSimulationNonDiscrete, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_91(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_91(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_91;

protected function lm_92
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDecls) = algStatement(txt, i_stmt, SimCode.contextSimulationNonDiscrete, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_92(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDecls) = lm_92(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_92;

protected function lm_93
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_eq :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        SimCode.SimEqSystem i_eq;
      equation
        (txt, i_varDecls) = equation_(txt, i_eq, SimCode.contextSimulationNonDiscrete, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_93(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_93(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_93;

public function functionDaeOutput
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> i_nonStateContEquations;
  input list<SimCode.SimEqSystem> i_removedEquations;
  input list<DAE.Statement> i_algorithmAndEquationAsserts;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_removedPart;
  Tpl.Text i_algAndEqAssertsPart;
  Tpl.Text i_nonStateContPart;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  i_nonStateContPart := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_nonStateContPart, i_varDecls) := lm_91(i_nonStateContPart, i_nonStateContEquations, i_varDecls);
  i_nonStateContPart := Tpl.popIter(i_nonStateContPart);
  i_algAndEqAssertsPart := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_algAndEqAssertsPart, i_varDecls) := lm_92(i_algAndEqAssertsPart, i_algorithmAndEquationAsserts, i_varDecls);
  i_algAndEqAssertsPart := Tpl.popIter(i_algAndEqAssertsPart);
  i_removedPart := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_removedPart, i_varDecls) := lm_93(i_removedPart, i_removedEquations, i_varDecls);
  i_removedPart := Tpl.popIter(i_removedPart);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "/* for continuous time variables */\n",
                                   "int functionDAE_output()\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, i_nonStateContPart);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, i_algAndEqAssertsPart);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, i_removedPart);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionDaeOutput;

protected function lm_95
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_eq :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        SimCode.SimEqSystem i_eq;
      equation
        (txt, i_varDecls) = equation_(txt, i_eq, SimCode.contextSimulationDiscrete, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_95(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_95(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_95;

protected function lm_96
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_eq :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        SimCode.SimEqSystem i_eq;
      equation
        (txt, i_varDecls) = equation_(txt, i_eq, SimCode.contextSimulationDiscrete, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_96(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_96(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_96;

public function functionDaeOutput2
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> i_nonStateDiscEquations;
  input list<SimCode.SimEqSystem> i_removedEquations;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_removedPart;
  Tpl.Text i_nonSateDiscPart;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  i_nonSateDiscPart := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_nonSateDiscPart, i_varDecls) := lm_95(i_nonSateDiscPart, i_nonStateDiscEquations, i_varDecls);
  i_nonSateDiscPart := Tpl.popIter(i_nonSateDiscPart);
  i_removedPart := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_removedPart, i_varDecls) := lm_96(i_removedPart, i_removedEquations, i_varDecls);
  i_removedPart := Tpl.popIter(i_removedPart);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "/* for discrete time variables */\n",
                                   "int functionDAE_output2()\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, i_nonSateDiscPart);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, i_removedPart);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionDaeOutput2;

protected function lm_98
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Integer i_i0;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = localData->inputVars["));
        txt = Tpl.writeStr(txt, intString(i_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];"));
        txt = Tpl.nextIter(txt);
        txt = lm_98(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_98(txt, rest);
      then txt;
  end matchcontinue;
end lm_98;

public function functionInput
  input Tpl.Text in_txt;
  input SimCode.ModelInfo in_i_modelInfo;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_modelInfo)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.MODELINFO(vars = SimCode.SIMVARS(inputVars = i_vars_inputVars)) )
      local
        list<SimCode.SimVar> i_vars_inputVars;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "int input_function()\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_98(txt, i_vars_inputVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("return 0;\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end functionInput;

protected function lm_100
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Integer i_i0;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("localData->outputVars["));
        txt = Tpl.writeStr(txt, intString(i_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = "));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_100(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_100(txt, rest);
      then txt;
  end matchcontinue;
end lm_100;

public function functionOutput
  input Tpl.Text in_txt;
  input SimCode.ModelInfo in_i_modelInfo;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_modelInfo)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.MODELINFO(vars = SimCode.SIMVARS(outputVars = i_vars_outputVars)) )
      local
        list<SimCode.SimVar> i_vars_outputVars;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "int output_function()\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_100(txt, i_vars_outputVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("return 0;\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end functionOutput;

public function functionDaeRes
  input Tpl.Text txt;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int functionDAE_res(double *t, double *x, double *xd, double *delta,\n",
                                   "                    fortran_integer *ires, double *rpar, fortran_integer *ipar)\n",
                                   "{\n",
                                   "  int i;\n",
                                   "  double temp_xd[NX];\n",
                                   "  double temp_alg[NY];\n",
                                   "  double* statesBackup;\n",
                                   "  double* statesDerivativesBackup;\n",
                                   "  double* algebraicsBackup;\n",
                                   "  double timeBackup;\n",
                                   "\n",
                                   "  statesBackup = localData->states;\n",
                                   "  statesDerivativesBackup = localData->statesDerivatives;\n",
                                   "  algebraicsBackup = localData->algebraics;\n",
                                   "  timeBackup = localData->timeValue;\n",
                                   "  localData->states = x;\n",
                                   "\n",
                                   "  localData->statesDerivatives = temp_xd;\n",
                                   "  localData->algebraics = temp_alg;\n",
                                   "  localData->timeValue = *t;\n",
                                   "\n",
                                   "  memcpy(localData->statesDerivatives, statesDerivativesBackup, localData->nStates*sizeof(double));\n",
                                   "  memcpy(localData->algebraics, algebraicsBackup, localData->nAlgebraic*sizeof(double));\n",
                                   "\n",
                                   "  functionODE();\n",
                                   "\n",
                                   "  /* get the difference between the temp_xd(=localData->statesDerivatives)\n",
                                   "     and xd(=statesDerivativesBackup) */\n",
                                   "  for (i=0; i < localData->nStates; i++) {\n",
                                   "    delta[i] = localData->statesDerivatives[i] - statesDerivativesBackup[i];\n",
                                   "  }\n",
                                   "\n",
                                   "  localData->states = statesBackup;\n",
                                   "  localData->statesDerivatives = statesDerivativesBackup;\n",
                                   "  localData->algebraics = algebraicsBackup;\n",
                                   "  localData->timeValue = timeBackup;\n",
                                   "\n",
                                   "  if (modelErrorCode) {\n",
                                   "    if (ires) {\n",
                                   "      *ires = -1;\n",
                                   "    }\n",
                                   "    modelErrorCode =0;\n",
                                   "  }\n",
                                   "\n",
                                   "  return 0;\n",
                                   "}"
                               }, false));
end functionDaeRes;

public function functionZeroCrossing
  input Tpl.Text txt;
  input list<DAELow.ZeroCrossing> i_zeroCrossings;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_zeroCrossingsCode;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  (i_zeroCrossingsCode, i_varDecls) := zeroCrossingsTpl(emptyTxt, i_zeroCrossings, i_varDecls);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int function_zeroCrossing(fortran_integer *neqm, double *t, double *x, fortran_integer *ng,\n",
                                   "                          double *gout, double *rpar, fortran_integer* ipar)\n",
                                   "{\n",
                                   "  double timeBackup;\n",
                                   "  state mem_state;\n",
                                   "\n",
                                   "  mem_state = get_memory_state();\n",
                                   "\n",
                                   "  timeBackup = localData->timeValue;\n",
                                   "  localData->timeValue = *t;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "functionODE();\n",
                                       "functionDAE_output();\n",
                                       "\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, i_zeroCrossingsCode);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "restore_memory_state(mem_state);\n",
                                       "localData->timeValue = timeBackup;\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionZeroCrossing;

protected function lm_104
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("save("));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.nextIter(txt);
        txt = lm_104(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_104(txt, rest);
      then txt;
  end matchcontinue;
end lm_104;

protected function lm_105
  input Tpl.Text in_txt;
  input list<list<SimCode.SimVar>> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_vars :: rest )
      local
        list<list<SimCode.SimVar>> rest;
        list<SimCode.SimVar> i_vars;
        Integer i_i0;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("case "));
        txt = Tpl.writeStr(txt, intString(i_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(":\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_104(txt, i_vars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("break;"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.nextIter(txt);
        txt = lm_105(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<list<SimCode.SimVar>> rest;
      equation
        txt = lm_105(txt, rest);
      then txt;
  end matchcontinue;
end lm_105;

public function functionHandleZeroCrossing
  input Tpl.Text txt;
  input list<list<SimCode.SimVar>> i_zeroCrossingsNeedSave;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "/* This function should only save in cases. The rest is done in\n",
                                   "   function_updateDependents. */\n",
                                   "int handleZeroCrossing(long index)\n",
                                   "{\n",
                                   "  state mem_state;\n",
                                   "\n",
                                   "  mem_state = get_memory_state();\n",
                                   "\n",
                                   "  switch(index) {\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(4));
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_105(out_txt, i_zeroCrossingsNeedSave);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "default:\n",
                                       "  break;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "  }\n",
                                       "\n",
                                       "  restore_memory_state(mem_state);\n",
                                       "\n",
                                       "  return 0;\n",
                                       "}"
                                   }, false));
end functionHandleZeroCrossing;

public function functionInitSample
  input Tpl.Text txt;
  input list<DAELow.ZeroCrossing> i_zeroCrossings;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_timeEventCode;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  (i_timeEventCode, i_varDecls) := timeEventsTpl(emptyTxt, i_zeroCrossings, i_varDecls);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "/* Initializes the raw time events of the simulation using the now\n",
                                   "   calcualted parameters. */\n",
                                   "void function_sampleInit()\n",
                                   "{\n",
                                   "  int i = 0; // Current index\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_timeEventCode);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionInitSample;

protected function lm_108
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_eq :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        SimCode.SimEqSystem i_eq;
      equation
        (txt, i_varDecls) = equation_(txt, i_eq, SimCode.contextSimulationDiscrete, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_108(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_108(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_108;

protected function lm_109
  input Tpl.Text in_txt;
  input list<SimCode.HelpVarInfo> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           (i_hindex, i_exp, _) :: rest,
           i_varDecls )
      local
        list<SimCode.HelpVarInfo> rest;
        DAE.Exp i_exp;
        Integer i_hindex;
        Tpl.Text i_expPart;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, SimCode.contextSimulationDiscrete, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("localData->helpVars["));
        txt = Tpl.writeStr(txt, intString(i_hindex));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = "));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_109(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.HelpVarInfo> rest;
      equation
        (txt, i_varDecls) = lm_109(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_109;

public function functionUpdateDependents
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> i_allEquations;
  input list<SimCode.HelpVarInfo> i_helpVarInfo;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_hvars;
  Tpl.Text i_eqs;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  i_eqs := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_eqs, i_varDecls) := lm_108(i_eqs, i_allEquations, i_varDecls);
  i_eqs := Tpl.popIter(i_eqs);
  i_hvars := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_hvars, i_varDecls) := lm_109(i_hvars, i_helpVarInfo, i_varDecls);
  i_hvars := Tpl.popIter(i_hvars);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int function_updateDependents()\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "inUpdate=initial()?0:1;\n",
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, i_eqs);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, i_hvars);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "inUpdate=0;\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionUpdateDependents;

protected function lm_111
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_eq :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        SimCode.SimEqSystem i_eq;
      equation
        (txt, i_varDecls) = equation_(txt, i_eq, SimCode.contextSimulationDiscrete, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_111(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_111(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_111;

protected function lm_112
  input Tpl.Text in_txt;
  input list<SimCode.SimWhenClause> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_when :: rest,
           i_varDecls )
      local
        list<SimCode.SimWhenClause> rest;
        SimCode.SimWhenClause i_when;
        Integer i_i0;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        (txt, i_varDecls) = genreinits(txt, i_when, i_varDecls, i_i0);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_112(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimWhenClause> rest;
      equation
        (txt, i_varDecls) = lm_112(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_112;

public function functionUpdateDepend
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> i_allEquationsPlusWhen;
  input list<SimCode.SimWhenClause> i_whenClauses;
  input list<SimCode.HelpVarInfo> i_helpVarInfo;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_reinit;
  Tpl.Text i_eqs;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  i_eqs := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_eqs, i_varDecls) := lm_111(i_eqs, i_allEquationsPlusWhen, i_varDecls);
  i_eqs := Tpl.popIter(i_eqs);
  i_reinit := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_reinit, i_varDecls) := lm_112(i_reinit, i_whenClauses, i_varDecls);
  i_reinit := Tpl.popIter(i_reinit);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int function_updateDepend(int &needToIterate)\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "needToIterate = 0;\n",
                                       "inUpdate=initial()?0:1;\n",
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, i_eqs);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, i_reinit);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "inUpdate=0;\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionUpdateDepend;

public function functionOnlyZeroCrossing
  input Tpl.Text txt;
  input list<DAELow.ZeroCrossing> i_zeroCrossings;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_zeroCrossingsCode;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  (i_zeroCrossingsCode, i_varDecls) := zeroCrossingsTpl(emptyTxt, i_zeroCrossings, i_varDecls);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int function_onlyZeroCrossings(double *gout,double *t)\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, i_zeroCrossingsCode);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionOnlyZeroCrossing;

protected function lm_115
  input Tpl.Text in_txt;
  input list<SimCode.HelpVarInfo> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           (i_hindex, i_exp, _) :: rest,
           i_varDecls )
      local
        list<SimCode.HelpVarInfo> rest;
        DAE.Exp i_exp;
        Integer i_hindex;
        Tpl.Text i_expPart;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, SimCode.contextSimulationDiscrete, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("localData->helpVars["));
        txt = Tpl.writeStr(txt, intString(i_hindex));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = "));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_115(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.HelpVarInfo> rest;
      equation
        (txt, i_varDecls) = lm_115(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_115;

public function functionUpdateHelpVars
  input Tpl.Text txt;
  input list<SimCode.HelpVarInfo> i_helpVarInfo;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_hvars;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  i_hvars := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_hvars, i_varDecls) := lm_115(i_hvars, i_helpVarInfo, i_varDecls);
  i_hvars := Tpl.popIter(i_hvars);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int function_updatehelpvars()\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, i_hvars);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionUpdateHelpVars;

protected function lm_117
  input Tpl.Text in_txt;
  input list<DAE.ComponentRef> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<DAE.ComponentRef> rest;
        DAE.ComponentRef i_var;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (change("));
        txt = cref(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")) { needToIterate=1; }"));
        txt = Tpl.nextIter(txt);
        txt = lm_117(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<DAE.ComponentRef> rest;
      equation
        txt = lm_117(txt, rest);
      then txt;
  end matchcontinue;
end lm_117;

public function functionCheckForDiscreteChanges
  input Tpl.Text txt;
  input list<DAE.ComponentRef> i_discreteModelVars;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int checkForDiscreteChanges()\n",
                                   "{\n",
                                   "  int needToIterate = 0;\n",
                                   "\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_117(out_txt, i_discreteModelVars);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "return needToIterate;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionCheckForDiscreteChanges;

protected function lm_119
  input Tpl.Text in_txt;
  input list<tuple<Integer, DAE.Exp>> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           (i_id, i_e) :: rest,
           i_varDecls )
      local
        list<tuple<Integer, DAE.Exp>> rest;
        DAE.Exp i_e;
        Integer i_id;
        Tpl.Text i_eRes;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_eRes, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e, SimCode.contextSimulationNonDiscrete, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("storeDelayedExpression("));
        txt = Tpl.writeStr(txt, intString(i_id));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_eRes);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        (txt, i_varDecls) = lm_119(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<tuple<Integer, DAE.Exp>> rest;
      equation
        (txt, i_varDecls) = lm_119(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_119;

protected function fun_120
  input Tpl.Text in_txt;
  input SimCode.DelayedExpression in_i_delayed;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_delayed, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.DELAYED_EXPRESSIONS(delayedExps = i_delayedExps),
           i_varDecls )
      local
        list<tuple<Integer, DAE.Exp>> i_delayedExps;
      equation
        (txt, i_varDecls) = lm_119(txt, i_delayedExps, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end fun_120;

protected function fun_121
  input Tpl.Text in_txt;
  input SimCode.DelayedExpression in_i_delayed;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_delayed)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.DELAYED_EXPRESSIONS(maxDelayedIndex = i_maxDelayedIndex) )
      local
        Integer i_maxDelayedIndex;
      equation
        txt = Tpl.writeStr(txt, intString(i_maxDelayedIndex));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_121;

public function functionStoreDelayed
  input Tpl.Text txt;
  input SimCode.DelayedExpression i_delayed;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_storePart;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  (i_storePart, i_varDecls) := fun_120(emptyTxt, i_delayed, i_varDecls);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("extern int const numDelayExpressionIndex = "));
  out_txt := fun_121(out_txt, i_delayed);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       ";\n",
                                       "int function_storeDelayed()\n",
                                       "{\n",
                                       "  state mem_state;\n"
                                   }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, i_storePart);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionStoreDelayed;

protected function lm_123
  input Tpl.Text in_txt;
  input list<DAELow.ReinitStatement> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_reinit :: rest,
           i_varDecls )
      local
        list<DAELow.ReinitStatement> rest;
        DAELow.ReinitStatement i_reinit;
        Tpl.Text i_body;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_body, i_preExp, i_varDecls) = functionWhenReinitStatement(emptyTxt, i_reinit, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_body);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_123(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<DAELow.ReinitStatement> rest;
      equation
        (txt, i_varDecls) = lm_123(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_123;

protected function lm_124
  input Tpl.Text in_txt;
  input list<SimCode.SimWhenClause> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           SimCode.SIM_WHEN_CLAUSE(whenEq = i_whenEq, reinits = i_reinits) :: rest,
           i_varDecls )
      local
        list<SimCode.SimWhenClause> rest;
        list<DAELow.ReinitStatement> i_reinits;
        Option<DAELow.WhenEquation> i_whenEq;
        Integer i_i0;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("case "));
        txt = Tpl.writeStr(txt, intString(i_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(":\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        (txt, i_varDecls) = functionWhenCaseEquation(txt, i_whenEq, i_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls) = lm_123(txt, i_reinits, i_varDecls);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("break;"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.popBlock(txt);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_124(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimWhenClause> rest;
      equation
        (txt, i_varDecls) = lm_124(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_124;

public function functionWhen
  input Tpl.Text txt;
  input list<SimCode.SimWhenClause> i_whenClauses;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_cases;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  i_cases := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, NONE, 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_cases, i_varDecls) := lm_124(i_cases, i_whenClauses, i_varDecls);
  i_cases := Tpl.popIter(i_cases);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int function_when(int i)\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n",
                                       "\n",
                                       "switch(i) {\n"
                                   }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_cases);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "default:\n",
                                       "  break;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "}\n",
                                       "\n",
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionWhen;

public function functionWhenCaseEquation
  input Tpl.Text in_txt;
  input Option<DAELow.WhenEquation> in_i_when;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_when, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           SOME((i_weq as DAELow.WHEN_EQ(right = i_weq_right, left = i_weq_left))),
           i_varDecls )
      local
        DAE.ComponentRef i_weq_left;
        DAE.Exp i_weq_right;
        DAELow.WhenEquation i_weq;
        Tpl.Text i_expPart;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_weq_right, SimCode.contextSimulationDiscrete, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("save("));
        txt = cref(txt, i_weq_left);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\n",
                                    "\n"
                                }, true));
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = cref(txt, i_weq_left);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end functionWhenCaseEquation;

public function functionWhenReinitStatement
  input Tpl.Text in_txt;
  input DAELow.ReinitStatement in_i_reinit;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_reinit, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAELow.REINIT(value = i_value, stateVar = i_stateVar),
           i_preExp,
           i_varDecls )
      local
        DAE.ComponentRef i_stateVar;
        DAE.Exp i_value;
        Tpl.Text i_val;
      equation
        (i_val, i_preExp, i_varDecls) = daeExp(emptyTxt, i_value, SimCode.contextSimulationDiscrete, i_preExp, i_varDecls);
        txt = cref(txt, i_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, i_val);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end functionWhenReinitStatement;

protected function lm_128
  input Tpl.Text in_txt;
  input list<tuple<DAE.Exp, Integer>> in_items;
  input Tpl.Text in_i_helpInits;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_helpInits;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_helpInits, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_helpInits, in_i_varDecls, in_i_preExp)
    local
      Tpl.Text txt;
      Tpl.Text i_helpInits;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;

    case ( txt,
           {},
           i_helpInits,
           i_varDecls,
           i_preExp )
      then (txt, i_helpInits, i_varDecls, i_preExp);

    case ( txt,
           (i_e, i_hidx) :: rest,
           i_helpInits,
           i_varDecls,
           i_preExp )
      local
        list<tuple<DAE.Exp, Integer>> rest;
        Integer i_hidx;
        DAE.Exp i_e;
        Tpl.Text i_helpInit;
      equation
        (i_helpInit, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e, SimCode.contextSimulationDiscrete, i_preExp, i_varDecls);
        i_helpInits = Tpl.writeTok(i_helpInits, Tpl.ST_STRING("localData->helpVars["));
        i_helpInits = Tpl.writeStr(i_helpInits, intString(i_hidx));
        i_helpInits = Tpl.writeTok(i_helpInits, Tpl.ST_STRING("] = "));
        i_helpInits = Tpl.writeText(i_helpInits, i_helpInit);
        i_helpInits = Tpl.writeTok(i_helpInits, Tpl.ST_STRING(";"));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("edge(localData->helpVars["));
        txt = Tpl.writeStr(txt, intString(i_hidx));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("])"));
        txt = Tpl.nextIter(txt);
        (txt, i_helpInits, i_varDecls, i_preExp) = lm_128(txt, rest, i_helpInits, i_varDecls, i_preExp);
      then (txt, i_helpInits, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_helpInits,
           i_varDecls,
           i_preExp )
      local
        list<tuple<DAE.Exp, Integer>> rest;
      equation
        (txt, i_helpInits, i_varDecls, i_preExp) = lm_128(txt, rest, i_helpInits, i_varDecls, i_preExp);
      then (txt, i_helpInits, i_varDecls, i_preExp);
  end matchcontinue;
end lm_128;

protected function fun_129
  input Tpl.Text in_txt;
  input list<DAELow.ReinitStatement> in_i_reinits;
  input Tpl.Text in_i_ifthen;
  input Tpl.Text in_i_helpIf;
  input Tpl.Text in_i_helpInits;
  input Tpl.Text in_i_preExp;
  input Integer in_i_int;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_reinits, in_i_ifthen, in_i_helpIf, in_i_helpInits, in_i_preExp, in_i_int)
    local
      Tpl.Text txt;
      Tpl.Text i_ifthen;
      Tpl.Text i_helpIf;
      Tpl.Text i_helpInits;
      Tpl.Text i_preExp;
      Integer i_int;

    case ( txt,
           {},
           _,
           _,
           _,
           _,
           _ )
      then txt;

    case ( txt,
           _,
           i_ifthen,
           i_helpIf,
           i_helpInits,
           i_preExp,
           i_int )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("//For whenclause index: "));
        txt = Tpl.writeStr(txt, intString(i_int));
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_helpInits);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if ("));
        txt = Tpl.writeText(txt, i_helpIf);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_ifthen);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" needToIterate = 1;\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
        txt = Tpl.popBlock(txt);
      then txt;
  end matchcontinue;
end fun_129;

public function genreinits
  input Tpl.Text in_txt;
  input SimCode.SimWhenClause in_i_whenClauses;
  input Tpl.Text in_i_varDecls;
  input Integer in_i_int;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_whenClauses, in_i_varDecls, in_i_int)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Integer i_int;

    case ( txt,
           SimCode.SIM_WHEN_CLAUSE(conditions = i_conditions, reinits = i_reinits),
           i_varDecls,
           i_int )
      local
        list<DAELow.ReinitStatement> i_reinits;
        list<tuple<DAE.Exp, Integer>> i_conditions;
        Tpl.Text i_ifthen;
        Tpl.Text i_helpIf;
        Tpl.Text i_helpInits;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        i_helpInits = emptyTxt;
        i_helpIf = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(" || ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_helpIf, i_helpInits, i_varDecls, i_preExp) = lm_128(i_helpIf, i_conditions, i_helpInits, i_varDecls, i_preExp);
        i_helpIf = Tpl.popIter(i_helpIf);
        (i_ifthen, i_preExp, i_varDecls) = functionWhenReinitStatementThen(emptyTxt, i_reinits, i_preExp, i_varDecls);
        txt = fun_129(txt, i_reinits, i_ifthen, i_helpIf, i_helpInits, i_preExp, i_int);
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls,
           _ )
      then (txt, i_varDecls);
  end matchcontinue;
end genreinits;

protected function fun_131
  input Tpl.Text in_txt;
  input DAELow.ReinitStatement in_i_reinit;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_i_reinit, in_i_varDecls, in_i_preExp)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;

    case ( txt,
           DAELow.REINIT(value = i_value, stateVar = i_stateVar),
           i_varDecls,
           i_preExp )
      local
        DAE.ComponentRef i_stateVar;
        DAE.Exp i_value;
        Tpl.Text i_val;
      equation
        (i_val, i_preExp, i_varDecls) = daeExp(emptyTxt, i_value, SimCode.contextSimulationDiscrete, i_preExp, i_varDecls);
        txt = cref(txt, i_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, i_val);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _,
           i_varDecls,
           i_preExp )
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_131;

protected function lm_132
  input Tpl.Text in_txt;
  input list<DAELow.ReinitStatement> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;

    case ( txt,
           {},
           i_varDecls,
           i_preExp )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_reinit :: rest,
           i_varDecls,
           i_preExp )
      local
        list<DAELow.ReinitStatement> rest;
        DAELow.ReinitStatement i_reinit;
      equation
        (txt, i_varDecls, i_preExp) = fun_131(txt, i_reinit, i_varDecls, i_preExp);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_132(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp )
      local
        list<DAELow.ReinitStatement> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_132(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_132;

public function functionWhenReinitStatementThen
  input Tpl.Text txt;
  input list<DAELow.ReinitStatement> i_reinits;
  input Tpl.Text i_preExp;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
protected
  Tpl.Text i_body;
algorithm
  i_body := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_body, out_i_varDecls, out_i_preExp) := lm_132(i_body, i_reinits, i_varDecls, i_preExp);
  i_body := Tpl.popIter(i_body);
  out_txt := Tpl.pushBlock(txt, Tpl.BT_INDENT(1));
  out_txt := Tpl.writeText(out_txt, i_body);
  out_txt := Tpl.popBlock(out_txt);
end functionWhenReinitStatementThen;

protected function fun_134
  input Tpl.Text in_txt;
  input DAELow.ReinitStatement in_i_reinit;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_i_reinit, in_i_varDecls, in_i_preExp)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;

    case ( txt,
           DAELow.REINIT(value = i_value, stateVar = i_stateVar),
           i_varDecls,
           i_preExp )
      local
        DAE.ComponentRef i_stateVar;
        DAE.Exp i_value;
        Tpl.Text i_val;
      equation
        (i_val, i_preExp, i_varDecls) = daeExp(emptyTxt, i_value, SimCode.contextSimulationDiscrete, i_preExp, i_varDecls);
        txt = cref(txt, i_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = pre("));
        txt = cref(txt, i_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _,
           i_varDecls,
           i_preExp )
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_134;

protected function lm_135
  input Tpl.Text in_txt;
  input list<DAELow.ReinitStatement> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;

    case ( txt,
           {},
           i_varDecls,
           i_preExp )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_reinit :: rest,
           i_varDecls,
           i_preExp )
      local
        list<DAELow.ReinitStatement> rest;
        DAELow.ReinitStatement i_reinit;
      equation
        (txt, i_varDecls, i_preExp) = fun_134(txt, i_reinit, i_varDecls, i_preExp);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_135(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp )
      local
        list<DAELow.ReinitStatement> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_135(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_135;

public function functionWhenReinitStatementElse
  input Tpl.Text txt;
  input list<DAELow.ReinitStatement> i_reinits;
  input Tpl.Text i_preExp;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
protected
  Tpl.Text i_body;
algorithm
  i_body := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_body, out_i_varDecls, out_i_preExp) := lm_135(i_body, i_reinits, i_varDecls, i_preExp);
  i_body := Tpl.popIter(i_body);
  out_txt := Tpl.pushBlock(txt, Tpl.BT_INDENT(1));
  out_txt := Tpl.writeText(out_txt, i_body);
  out_txt := Tpl.popBlock(out_txt);
end functionWhenReinitStatementElse;

protected function lm_137
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_eq :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        SimCode.SimEqSystem i_eq;
      equation
        (txt, i_varDecls) = equation_(txt, i_eq, SimCode.contextSimulationNonDiscrete, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_137(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_137(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_137;

protected function lm_138
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls2;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls2;
algorithm
  (out_txt, out_i_varDecls2) :=
  matchcontinue(in_txt, in_items, in_i_varDecls2)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls2;

    case ( txt,
           {},
           i_varDecls2 )
      then (txt, i_varDecls2);

    case ( txt,
           i_eq :: rest,
           i_varDecls2 )
      local
        list<SimCode.SimEqSystem> rest;
        SimCode.SimEqSystem i_eq;
      equation
        (txt, i_varDecls2) = equation_(txt, i_eq, SimCode.contextInlineSolver, i_varDecls2);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls2) = lm_138(txt, rest, i_varDecls2);
      then (txt, i_varDecls2);

    case ( txt,
           _ :: rest,
           i_varDecls2 )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls2) = lm_138(txt, rest, i_varDecls2);
      then (txt, i_varDecls2);
  end matchcontinue;
end lm_138;

public function functionOde
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> i_stateContEquations;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_stateContPartInline;
  Tpl.Text i_varDecls2;
  Tpl.Text i_stateContPart;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  i_stateContPart := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_stateContPart, i_varDecls) := lm_137(i_stateContPart, i_stateContEquations, i_varDecls);
  i_stateContPart := Tpl.popIter(i_stateContPart);
  i_varDecls2 := emptyTxt;
  i_stateContPartInline := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_stateContPartInline, i_varDecls2) := lm_138(i_stateContPartInline, i_stateContEquations, i_varDecls2);
  i_stateContPartInline := Tpl.popIter(i_stateContPartInline);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int functionODE()\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, i_stateContPart);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "}\n",
                                       "\n",
                                       "#if defined(_OMC_ENABLE_INLINE)\n",
                                       "int functionODE_inline()\n",
                                       "{\n",
                                       "  state mem_state;\n"
                                   }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls2);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n",
                                       "begin_inline();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, i_stateContPartInline);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "end_inline();\n",
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "}\n",
                                       "#else\n",
                                       "int functionODE_inline()\n",
                                       "{\n",
                                       "  return 0;\n",
                                       "}\n",
                                       "#endif"
                                   }, false));
end functionOde;

protected function lm_140
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_eq :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        SimCode.SimEqSystem i_eq;
      equation
        (txt, i_varDecls) = equation_(txt, i_eq, SimCode.contextSimulationNonDiscrete, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_140(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_140(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_140;

protected function lm_141
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = defvars(txt, i_var);
        txt = lm_141(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_141(txt, rest);
      then txt;
  end matchcontinue;
end lm_141;

protected function lm_142
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = writejac(txt, i_var);
        txt = lm_142(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_142(txt, rest);
      then txt;
  end matchcontinue;
end lm_142;

public function functionJac
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> i_JacEquations;
  input list<SimCode.SimVar> i_JacVars;
  input String i_MatrixName;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_writeJac__;
  Tpl.Text i_Vars__;
  Tpl.Text i_Equations__;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  i_Equations__ := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_Equations__, i_varDecls) := lm_140(i_Equations__, i_JacEquations, i_varDecls);
  i_Equations__ := Tpl.popIter(i_Equations__);
  i_Vars__ := lm_141(emptyTxt, i_JacVars);
  i_writeJac__ := lm_142(emptyTxt, i_JacVars);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("int functionJac"));
  out_txt := Tpl.writeStr(out_txt, i_MatrixName);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "(double *t, double *x, double *xd, double *jac)\n",
                                       "{\n",
                                       "    state mem_state;\n",
                                       "\n",
                                       "    double* statesBackup;\n",
                                       "    double* statesDerivativesBackup;\n",
                                       "    double timeBackup;\n",
                                       "\n",
                                       "    timeBackup = localData->timeValue;\n",
                                       "    statesBackup = localData->states;\n",
                                       "    statesDerivativesBackup = localData->statesDerivatives;\n",
                                       "    localData->timeValue = *t;\n",
                                       "    localData->states = x;\n",
                                       "    localData->statesDerivatives = xd;\n",
                                       "\n"
                                   }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_Vars__);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, i_Equations__);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, i_writeJac__);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "localData->states = statesBackup;\n",
                                       "  localData->statesDerivatives = statesDerivativesBackup;\n",
                                       "  localData->timeValue = timeBackup;\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "}\n",
                                       "\n"
                                   }, true));
end functionJac;

public function defvars
  input Tpl.Text in_txt;
  input SimCode.SimVar in_i_item;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_item)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name) )
      local
        DAE.ComponentRef i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("double "));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end defvars;

protected function fun_145
  input Tpl.Text in_txt;
  input Integer in_i_index;
  input DAE.ComponentRef in_i_name;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_index, in_i_name)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_name;

    case ( txt,
           -1,
           _ )
      then txt;

    case ( txt,
           i_index,
           i_name )
      local
        Integer i_index;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("jac["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = "));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ";\n",
                                    "\n"
                                }, true));
      then txt;
  end matchcontinue;
end fun_145;

public function writejac
  input Tpl.Text in_txt;
  input SimCode.SimVar in_i_item;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_item)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name, index = i_index) )
      local
        Integer i_index;
        DAE.ComponentRef i_name;
      equation
        txt = fun_145(txt, i_index, i_name);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end writejac;

public function functionlinearmodel
  input Tpl.Text in_txt;
  input SimCode.ModelInfo in_i_modelInfo;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_modelInfo)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.MODELINFO(varInfo = SimCode.VARINFO(numStateVars = i_varInfo_numStateVars, numInVars = i_varInfo_numInVars, numOutVars = i_varInfo_numOutVars), vars = SimCode.SIMVARS(stateVars = i_vars_stateVars, inputVars = i_vars_inputVars, outputVars = i_vars_outputVars), name = i_name) )
      local
        Absyn.Path i_name;
        list<SimCode.SimVar> i_vars_outputVars;
        list<SimCode.SimVar> i_vars_inputVars;
        list<SimCode.SimVar> i_vars_stateVars;
        Integer i_varInfo_numOutVars;
        Integer i_varInfo_numInVars;
        Integer i_varInfo_numStateVars;
        Tpl.Text i_vectorY;
        Tpl.Text i_vectorU;
        Tpl.Text i_vectorX;
        Tpl.Text i_matrixD;
        Tpl.Text i_matrixC;
        Tpl.Text i_matrixB;
        Tpl.Text i_matrixA;
      equation
        i_matrixA = genMatrix(emptyTxt, "A", i_varInfo_numStateVars, i_varInfo_numStateVars);
        i_matrixB = genMatrix(emptyTxt, "B", i_varInfo_numStateVars, i_varInfo_numInVars);
        i_matrixC = genMatrix(emptyTxt, "C", i_varInfo_numOutVars, i_varInfo_numStateVars);
        i_matrixD = genMatrix(emptyTxt, "D", i_varInfo_numOutVars, i_varInfo_numInVars);
        i_vectorX = genVector(emptyTxt, "x", i_varInfo_numStateVars, 0);
        i_vectorU = genVector(emptyTxt, "u", i_varInfo_numInVars, 1);
        i_vectorY = genVector(emptyTxt, "y", i_varInfo_numOutVars, 2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "int linear_model_frame(string &out, string A, string B, string C, string D, string x_startvalues, string u_startvalues)\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("string def_head(\"model linear_"));
        txt = dotPath(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\\n  parameter Integer n = "));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numStateVars));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("; // states \\n  parameter Integer k = "));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numInVars));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("; // top-level inputs \\n  parameter Integer l = "));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numOutVars));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "; // top-level outputs \\n\");\n",
                                    "\n",
                                    "string def_init_states(\"  parameter Real x0["
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numStateVars));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "] = {\");\n",
                                    "string def_init_states_end(\"};\\n\");\n",
                                    "\n",
                                    "string def_init_inputs(\"  parameter Real u0["
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numInVars));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "] = {\");\n",
                                    "string def_init_inputs_end(\"};\\n\");\n",
                                    "\n"
                                }, true));
        txt = Tpl.writeText(txt, i_vectorX);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_vectorU);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_vectorY);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_matrixA);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_matrixB);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_matrixC);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_matrixD);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "string def_Variable(\"\\n  "
                                }, false));
        txt = getVarName(txt, i_vars_stateVars, "x", i_varInfo_numStateVars);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("  "));
        txt = getVarName(txt, i_vars_inputVars, "u", i_varInfo_numInVars);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("  "));
        txt = getVarName(txt, i_vars_outputVars, "y", i_varInfo_numOutVars);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\\n\");\n",
                                    "\n",
                                    "string def_tail(\"equation\\n  der(x) = A * x + B * u;\\n  y = C * x + D * u;\\nend linear_"
                                }, false));
        txt = dotPath(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ";\\n\");\n",
                                    "\n",
                                    "out += def_head.data();\n",
                                    "out += def_init_states.data();\n",
                                    "out += x_startvalues.data();\n",
                                    "out += def_init_states_end.data();\n",
                                    "out += def_init_inputs.data();\n",
                                    "out += u_startvalues.data();\n",
                                    "out += def_init_inputs_end.data();\n",
                                    "out += def_matrixA_start.data();\n",
                                    "out += A.data();\n",
                                    "out += def_matrixA_end.data();\n",
                                    "out += def_matrixB_start.data();\n",
                                    "out += B.data();\n",
                                    "out += def_matrixB_end.data();\n",
                                    "out += def_matrixC_start.data();\n",
                                    "out += C.data();\n",
                                    "out += def_matrixC_end.data();\n",
                                    "out += def_matrixD_start.data();\n",
                                    "out += D.data();\n",
                                    "out += def_matrixD_end.data();\n",
                                    "out += def_vectorx.data();\n",
                                    "out += def_vectoru.data();\n",
                                    "out += def_vectory.data();\n",
                                    "out += def_Variable.data();\n",
                                    "out += def_tail.data();\n",
                                    "return 0;\n"
                                }, true));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "\n"
                                }, true));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end functionlinearmodel;

protected function lm_148
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = Tpl.nextIter(txt);
        txt = lm_148(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_148(txt, rest);
      then txt;
  end matchcontinue;
end lm_148;

public function getVarsName
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_i_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\"\""));
      then txt;

    case ( txt,
           i_items )
      local
        list<SimCode.SimVar> i_items;
        Tpl.Text i_itemsStr;
      equation
        i_itemsStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        i_itemsStr = lm_148(i_itemsStr, i_items);
        i_itemsStr = Tpl.popIter(i_itemsStr);
        txt = Tpl.writeText(txt, i_itemsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then txt;
  end matchcontinue;
end getVarsName;

protected function fun_150
  input Tpl.Text in_txt;
  input SimCode.SimVar in_i_var;
  input Tpl.Text in_i_rest;
  input Tpl.Text in_i_arrindex;
  input String in_i_arrayName;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_var, in_i_rest, in_i_arrindex, in_i_arrayName)
    local
      Tpl.Text txt;
      Tpl.Text i_rest;
      Tpl.Text i_arrindex;
      String i_arrayName;

    case ( txt,
           SimCode.SIMVAR(name = i_name),
           i_rest,
           i_arrindex,
           i_arrayName )
      local
        DAE.ComponentRef i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("Real "));
        txt = Tpl.writeStr(txt, i_arrayName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeStr(txt, i_arrayName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeText(txt, i_arrindex);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];\\n  "));
        txt = Tpl.writeText(txt, i_rest);
      then txt;

    case ( txt,
           _,
           _,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_150;

public function getVarName
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_i_simVars;
  input String in_i_arrayName;
  input Integer in_i_arraySize;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simVars, in_i_arrayName, in_i_arraySize)
    local
      Tpl.Text txt;
      String i_arrayName;
      Integer i_arraySize;

    case ( txt,
           {},
           _,
           _ )
      then txt;

    case ( txt,
           i_var :: i_restVars,
           i_arrayName,
           i_arraySize )
      local
        list<SimCode.SimVar> i_restVars;
        SimCode.SimVar i_var;
        Integer ret_3;
        Integer ret_2;
        Tpl.Text i_arrindex;
        Tpl.Text i_rest;
      equation
        i_rest = getVarName(emptyTxt, i_restVars, i_arrayName, i_arraySize);
        ret_2 = listLength(i_restVars);
        ret_3 = SimCode.decrementInt(i_arraySize, ret_2);
        i_arrindex = Tpl.writeStr(emptyTxt, intString(ret_3));
        txt = fun_150(txt, i_var, i_rest, i_arrindex, i_arrayName);
      then txt;

    case ( txt,
           _,
           _,
           _ )
      then txt;
  end matchcontinue;
end getVarName;

protected function fun_152
  input Tpl.Text in_txt;
  input Integer in_i_col;
  input Integer in_i_row;
  input String in_i_name;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_col, in_i_row, in_i_name)
    local
      Tpl.Text txt;
      Integer i_row;
      String i_name;

    case ( txt,
           (i_col as 0),
           i_row,
           i_name )
      local
        Integer i_col;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("string def_matrix"));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_start(\"  parameter Real "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_row));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeStr(txt, intString(i_col));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = zeros("));
        txt = Tpl.writeStr(txt, intString(i_row));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeStr(txt, intString(i_col));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\\n\");\n",
                                    "string def_matrix"
                                }, false));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_end(\"\");"));
      then txt;

    case ( txt,
           i_col,
           i_row,
           i_name )
      local
        Integer i_col;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("string def_matrix"));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_start(\"  parameter Real "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_row));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeStr(txt, intString(i_col));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "] = [\");\n",
                                    "string def_matrix"
                                }, false));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_end(\"];\\n\");"));
      then txt;
  end matchcontinue;
end fun_152;

protected function fun_153
  input Tpl.Text in_txt;
  input Integer in_i_row;
  input String in_i_name;
  input Integer in_i_col;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_row, in_i_name, in_i_col)
    local
      Tpl.Text txt;
      String i_name;
      Integer i_col;

    case ( txt,
           (i_row as 0),
           i_name,
           i_col )
      local
        Integer i_row;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("string def_matrix"));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_start(\"  parameter Real "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_row));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeStr(txt, intString(i_col));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = zeros("));
        txt = Tpl.writeStr(txt, intString(i_row));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeStr(txt, intString(i_col));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\\n\");\n",
                                    "string def_matrix"
                                }, false));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_end(\"\");"));
      then txt;

    case ( txt,
           i_row,
           i_name,
           i_col )
      local
        Integer i_row;
      equation
        txt = fun_152(txt, i_col, i_row, i_name);
      then txt;
  end matchcontinue;
end fun_153;

public function genMatrix
  input Tpl.Text txt;
  input String i_name;
  input Integer i_row;
  input Integer i_col;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_153(txt, i_row, i_name, i_col);
end genMatrix;

protected function fun_155
  input Tpl.Text in_txt;
  input Integer in_i_numIn;
  input String in_i_name;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_numIn, in_i_name)
    local
      Tpl.Text txt;
      String i_name;

    case ( txt,
           (i_numIn as 0),
           i_name )
      local
        Integer i_numIn;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("string def_vector"));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(\"  Real "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_numIn));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];\\n\");"));
      then txt;

    case ( txt,
           i_numIn,
           i_name )
      local
        Integer i_numIn;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("string def_vector"));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(\"  Real "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_numIn));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("](start="));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("0);\\n\");"));
      then txt;
  end matchcontinue;
end fun_155;

protected function fun_156
  input Tpl.Text in_txt;
  input Integer in_i_numIn;
  input String in_i_name;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_numIn, in_i_name)
    local
      Tpl.Text txt;
      String i_name;

    case ( txt,
           (i_numIn as 0),
           i_name )
      local
        Integer i_numIn;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("string def_vector"));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(\"  input Real "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_numIn));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];\\n\");"));
      then txt;

    case ( txt,
           i_numIn,
           i_name )
      local
        Integer i_numIn;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("string def_vector"));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(\"  input Real "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_numIn));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("](start= "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("0);\\n\");"));
      then txt;
  end matchcontinue;
end fun_156;

protected function fun_157
  input Tpl.Text in_txt;
  input Integer in_i_numIn;
  input String in_i_name;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_numIn, in_i_name)
    local
      Tpl.Text txt;
      String i_name;

    case ( txt,
           (i_numIn as 0),
           i_name )
      local
        Integer i_numIn;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("string def_vector"));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(\"  output Real "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_numIn));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];\\n\");"));
      then txt;

    case ( txt,
           i_numIn,
           i_name )
      local
        Integer i_numIn;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("string def_vector"));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(\"  output Real "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_numIn));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];\\n\");"));
      then txt;
  end matchcontinue;
end fun_157;

protected function fun_158
  input Tpl.Text in_txt;
  input Integer in_i_flag;
  input String in_i_name;
  input Integer in_i_numIn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_flag, in_i_name, in_i_numIn)
    local
      Tpl.Text txt;
      String i_name;
      Integer i_numIn;

    case ( txt,
           0,
           i_name,
           i_numIn )
      equation
        txt = fun_155(txt, i_numIn, i_name);
      then txt;

    case ( txt,
           1,
           i_name,
           i_numIn )
      equation
        txt = fun_156(txt, i_numIn, i_name);
      then txt;

    case ( txt,
           2,
           i_name,
           i_numIn )
      equation
        txt = fun_157(txt, i_numIn, i_name);
      then txt;

    case ( txt,
           _,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_158;

public function genVector
  input Tpl.Text txt;
  input String i_name;
  input Integer i_numIn;
  input Integer i_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_158(txt, i_flag, i_name, i_numIn);
end genVector;

protected function lm_160
  input Tpl.Text in_txt;
  input list<SimCode.JacobianMatrix> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_eqs, i_vars, i_name) :: rest )
      local
        list<SimCode.JacobianMatrix> rest;
        String i_name;
        list<SimCode.SimVar> i_vars;
        list<SimCode.SimEqSystem> i_eqs;
      equation
        txt = functionJac(txt, i_eqs, i_vars, i_name);
        txt = lm_160(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.JacobianMatrix> rest;
      equation
        txt = lm_160(txt, rest);
      then txt;
  end matchcontinue;
end lm_160;

public function generateLinearMatrixes
  input Tpl.Text txt;
  input list<SimCode.JacobianMatrix> i_JacobianMatrixes;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_jacMats;
algorithm
  i_jacMats := lm_160(emptyTxt, i_JacobianMatrixes);
  out_txt := Tpl.writeText(txt, i_jacMats);
end generateLinearMatrixes;

protected function lm_162
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           (i_eq as SimCode.SES_SIMPLE_ASSIGN(cref = _)) :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        SimCode.SimEqSystem i_eq;
      equation
        (txt, i_varDecls) = equation_(txt, i_eq, SimCode.contextOther, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_162(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_162(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_162;

protected function lm_163
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SES_SIMPLE_ASSIGN(cref = i_cref) :: rest )
      local
        list<SimCode.SimEqSystem> rest;
        DAE.ComponentRef i_cref;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (sim_verbose) { printf(\"Setting variable start value: %s(start=%f)\\n\", \""));
        txt = cref(txt, i_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\", "));
        txt = cref(txt, i_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("); }"));
        txt = Tpl.nextIter(txt);
        txt = lm_163(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        txt = lm_163(txt, rest);
      then txt;
  end matchcontinue;
end lm_163;

public function functionInitial
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> i_initialEquations;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_eqPart;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  i_eqPart := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_eqPart, i_varDecls) := lm_162(i_eqPart, i_initialEquations, i_varDecls);
  i_eqPart := Tpl.popIter(i_eqPart);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int initial_function()\n",
                                   "{\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_NEW_LINE());
  out_txt := Tpl.writeText(out_txt, i_eqPart);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_NEW_LINE());
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_163(out_txt, i_initialEquations);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionInitial;

protected function fun_165
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.SCONST(string = _),
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("localData->initialResiduals[i++] = 0;"));
      then (txt, i_varDecls);

    case ( txt,
           i_exp,
           i_varDecls )
      local
        DAE.Exp i_exp;
        Tpl.Text i_expPart;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, SimCode.contextOther, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("localData->initialResiduals[i++] = "));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, i_varDecls);
  end matchcontinue;
end fun_165;

protected function lm_166
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           SimCode.SES_RESIDUAL(exp = i_exp) :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        DAE.Exp i_exp;
      equation
        (txt, i_varDecls) = fun_165(txt, i_exp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_166(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_166(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_166;

public function functionInitialResidual
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> i_residualEquations;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_body;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  i_body := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_body, i_varDecls) := lm_166(i_body, i_residualEquations, i_varDecls);
  i_body := Tpl.popIter(i_body);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int initial_residual()\n",
                                   "{\n",
                                   "  int i = 0;\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, i_body);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionInitialResidual;

protected function lm_168
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           (i_eq2 as SimCode.SES_SIMPLE_ASSIGN(cref = _)) :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        SimCode.SimEqSystem i_eq2;
      equation
        (txt, i_varDecls) = equation_(txt, i_eq2, SimCode.contextOther, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_168(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_168(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_168;

protected function lm_169
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           (i_eq2 as SimCode.SES_RESIDUAL(exp = i_eq2_exp)) :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        DAE.Exp i_eq2_exp;
        SimCode.SimEqSystem i_eq2;
        Integer i_i0;
        Tpl.Text i_expPart;
        Tpl.Text i_preExp;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        i_preExp = emptyTxt;
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_eq2_exp, SimCode.contextSimulationDiscrete, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("res["));
        txt = Tpl.writeStr(txt, intString(i_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = "));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_169(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_169(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_169;

protected function lm_170
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_eq as SimCode.SES_NONLINEAR(eqs = i_eq_eqs, index = i_index)) :: rest )
      local
        list<SimCode.SimEqSystem> rest;
        Integer i_index;
        list<SimCode.SimEqSystem> i_eq_eqs;
        SimCode.SimEqSystem i_eq;
        Tpl.Text i_body;
        Tpl.Text i_prebody;
        Tpl.Text i_varDecls;
      equation
        i_varDecls = emptyTxt;
        i_prebody = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_prebody, i_varDecls) = lm_168(i_prebody, i_eq_eqs, i_varDecls);
        i_prebody = Tpl.popIter(i_prebody);
        i_body = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_body, i_varDecls) = lm_169(i_body, i_eq_eqs, i_varDecls);
        i_body = Tpl.popIter(i_body);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void residualFunc"));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "(int *n, double* xloc, double* res, int* iflag)\n",
                                    "{\n",
                                    "  state mem_state;\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("mem_state = get_memory_state();\n"));
        txt = Tpl.writeText(txt, i_prebody);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_body);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("restore_memory_state(mem_state);\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
        txt = Tpl.nextIter(txt);
        txt = lm_170(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        txt = lm_170(txt, rest);
      then txt;
  end matchcontinue;
end lm_170;

public function functionExtraResiduals
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> i_allEquations;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING_LIST({
                                                                  "\n",
                                                                  "\n"
                                                              }, true)), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_170(out_txt, i_allEquations);
  out_txt := Tpl.popIter(out_txt);
end functionExtraResiduals;

protected function lm_172
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           (i_eq as SimCode.SES_SIMPLE_ASSIGN(cref = _)) :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        SimCode.SimEqSystem i_eq;
      equation
        (txt, i_varDecls) = equation_(txt, i_eq, SimCode.contextOther, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_172(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_172(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_172;

protected function lm_173
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           (i_eq as SimCode.SES_ALGORITHM(statements = _)) :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        SimCode.SimEqSystem i_eq;
      equation
        (txt, i_varDecls) = equation_(txt, i_eq, SimCode.contextOther, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_173(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_173(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_173;

public function functionBoundParameters
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> i_parameterEquations;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_divbody;
  Tpl.Text i_body;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  i_body := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_body, i_varDecls) := lm_172(i_body, i_parameterEquations, i_varDecls);
  i_body := Tpl.popIter(i_body);
  i_divbody := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_divbody, i_varDecls) := lm_173(i_divbody, i_parameterEquations, i_varDecls);
  i_divbody := Tpl.popIter(i_divbody);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int bound_parameters()\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, i_body);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, i_divbody);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionBoundParameters;

protected function fun_175
  input Tpl.Text in_txt;
  input Integer in_i_windex;
  input Integer in_i_hindex;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_windex, in_i_hindex)
    local
      Tpl.Text txt;
      Integer i_hindex;

    case ( txt,
           -1,
           _ )
      then txt;

    case ( txt,
           i_windex,
           i_hindex )
      local
        Integer i_windex;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (edge(localData->helpVars["));
        txt = Tpl.writeStr(txt, intString(i_hindex));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("])) AddEvent("));
        txt = Tpl.writeStr(txt, intString(i_windex));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" + localData->nZeroCrossing);"));
      then txt;
  end matchcontinue;
end fun_175;

protected function lm_176
  input Tpl.Text in_txt;
  input list<SimCode.HelpVarInfo> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_hindex, i_exp, i_windex) :: rest )
      local
        list<SimCode.HelpVarInfo> rest;
        Integer i_windex;
        DAE.Exp i_exp;
        Integer i_hindex;
      equation
        txt = fun_175(txt, i_windex, i_hindex);
        txt = Tpl.nextIter(txt);
        txt = lm_176(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.HelpVarInfo> rest;
      equation
        txt = lm_176(txt, rest);
      then txt;
  end matchcontinue;
end lm_176;

protected function lm_177
  input Tpl.Text in_txt;
  input list<DAE.ComponentRef> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<DAE.ComponentRef> rest;
        DAE.ComponentRef i_var;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (change("));
        txt = cref(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")) { needToIterate=1; }"));
        txt = Tpl.nextIter(txt);
        txt = lm_177(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<DAE.ComponentRef> rest;
      equation
        txt = lm_177(txt, rest);
      then txt;
  end matchcontinue;
end lm_177;

public function functionCheckForDiscreteVarChanges
  input Tpl.Text txt;
  input list<SimCode.HelpVarInfo> i_helpVarInfo;
  input list<DAE.ComponentRef> i_discreteModelVars;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int checkForDiscreteVarChanges()\n",
                                   "{\n",
                                   "  int needToIterate = 0;\n",
                                   "\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_176(out_txt, i_helpVarInfo);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_NEW_LINE());
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_177(out_txt, i_discreteModelVars);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "for (long i = 0; i < localData->nHelpVars; i++) {\n",
                                       "  if (change(localData->helpVars[i])) {\n",
                                       "    needToIterate=1;\n",
                                       "  }\n",
                                       "}\n",
                                       "\n",
                                       "return needToIterate;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionCheckForDiscreteVarChanges;

protected function lm_179
  input Tpl.Text in_txt;
  input list<DAELow.ZeroCrossing> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           DAELow.ZERO_CROSSING(relation_ = i_relation__) :: rest,
           i_varDecls )
      local
        list<DAELow.ZeroCrossing> rest;
        DAE.Exp i_relation__;
        Integer i_i0;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        (txt, i_varDecls) = zeroCrossingTpl(txt, i_i0, i_relation__, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_179(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<DAELow.ZeroCrossing> rest;
      equation
        (txt, i_varDecls) = lm_179(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_179;

public function zeroCrossingsTpl
  input Tpl.Text txt;
  input list<DAELow.ZeroCrossing> i_zeroCrossings;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (out_txt, out_i_varDecls) := lm_179(out_txt, i_zeroCrossings, i_varDecls);
  out_txt := Tpl.popIter(out_txt);
end zeroCrossingsTpl;

protected function fun_181
  input Tpl.Text in_txt;
  input DAE.Exp in_i_relation;
  input Integer in_i_index;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_relation, in_i_index, in_i_varDecls)
    local
      Tpl.Text txt;
      Integer i_index;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.RELATION(exp1 = i_exp1, operator = i_operator, exp2 = i_exp2),
           i_index,
           i_varDecls )
      local
        DAE.Exp i_exp2;
        DAE.Operator i_operator;
        DAE.Exp i_exp1;
        Tpl.Text i_e2;
        Tpl.Text i_op;
        Tpl.Text i_e1;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_e1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp1, SimCode.contextOther, i_preExp, i_varDecls);
        i_op = zeroCrossingOpFunc(emptyTxt, i_operator);
        (i_e2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp2, SimCode.contextOther, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("ZEROCROSSING("));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_op);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("));"));
      then (txt, i_varDecls);

    case ( txt,
           DAE.CALL(path = Absyn.IDENT(name = "sample"), expLst = {i_start, i_interval}),
           i_index,
           i_varDecls )
      local
        DAE.Exp i_interval;
        DAE.Exp i_start;
        Tpl.Text i_e2;
        Tpl.Text i_e1;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_e1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_start, SimCode.contextOther, i_preExp, i_varDecls);
        (i_e2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_interval, SimCode.contextOther, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("ZEROCROSSING("));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(",Sample(*t,"));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("));"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("ZERO CROSSING ERROR"));
      then (txt, i_varDecls);
  end matchcontinue;
end fun_181;

public function zeroCrossingTpl
  input Tpl.Text txt;
  input Integer i_index;
  input DAE.Exp i_relation;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) := fun_181(txt, i_relation, i_index, i_varDecls);
end zeroCrossingTpl;

protected function lm_183
  input Tpl.Text in_txt;
  input list<DAELow.ZeroCrossing> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           DAELow.ZERO_CROSSING(relation_ = i_relation__) :: rest,
           i_varDecls )
      local
        list<DAELow.ZeroCrossing> rest;
        DAE.Exp i_relation__;
        Integer i_i0;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        (txt, i_varDecls) = timeEventTpl(txt, i_i0, i_relation__, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_183(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<DAELow.ZeroCrossing> rest;
      equation
        (txt, i_varDecls) = lm_183(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_183;

public function timeEventsTpl
  input Tpl.Text txt;
  input list<DAELow.ZeroCrossing> i_zeroCrossings;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (out_txt, out_i_varDecls) := lm_183(out_txt, i_zeroCrossings, i_varDecls);
  out_txt := Tpl.popIter(out_txt);
end timeEventsTpl;

protected function fun_185
  input Tpl.Text in_txt;
  input DAE.Exp in_i_relation;
  input Integer in_i_index;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_relation, in_i_index, in_i_varDecls)
    local
      Tpl.Text txt;
      Integer i_index;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.RELATION(exp1 = _),
           i_index,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("/* "));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" Not a time event */"));
      then (txt, i_varDecls);

    case ( txt,
           DAE.CALL(path = Absyn.IDENT(name = "sample"), expLst = {i_start, i_interval}),
           i_index,
           i_varDecls )
      local
        DAE.Exp i_interval;
        DAE.Exp i_start;
        Tpl.Text i_e2;
        Tpl.Text i_e1;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_e1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_start, SimCode.contextOther, i_preExp, i_varDecls);
        (i_e2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_interval, SimCode.contextOther, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("localData->rawSampleExps[i].start = "));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ";\n",
                                    "localData->rawSampleExps[i].interval = "
                                }, false));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ";\n",
                                    "localData->rawSampleExps[i++].zc_index = "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("ZERO CROSSING ERROR"));
      then (txt, i_varDecls);
  end matchcontinue;
end fun_185;

public function timeEventTpl
  input Tpl.Text txt;
  input Integer i_index;
  input DAE.Exp i_relation;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) := fun_185(txt, i_relation, i_index, i_varDecls);
end timeEventTpl;

public function zeroCrossingOpFunc
  input Tpl.Text in_txt;
  input DAE.Operator in_i_op;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_op)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.LESS(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("Less"));
      then txt;

    case ( txt,
           DAE.GREATER(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("Greater"));
      then txt;

    case ( txt,
           DAE.LESSEQ(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("LessEq"));
      then txt;

    case ( txt,
           DAE.GREATEREQ(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("GreaterEq"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end zeroCrossingOpFunc;

public function equation_
  input Tpl.Text in_txt;
  input SimCode.SimEqSystem in_i_eq;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_eq, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_e as SimCode.SES_SIMPLE_ASSIGN(cref = _)),
           i_context,
           i_varDecls )
      local
        SimCode.SimEqSystem i_e;
      equation
        (txt, i_varDecls) = equationSimpleAssign(txt, i_e, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_e as SimCode.SES_ARRAY_CALL_ASSIGN(componentRef = _)),
           i_context,
           i_varDecls )
      local
        SimCode.SimEqSystem i_e;
      equation
        (txt, i_varDecls) = equationArrayCallAssign(txt, i_e, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_e as SimCode.SES_ALGORITHM(statements = _)),
           i_context,
           i_varDecls )
      local
        SimCode.SimEqSystem i_e;
      equation
        (txt, i_varDecls) = equationAlgorithm(txt, i_e, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_e as SimCode.SES_LINEAR(partOfMixed = _)),
           i_context,
           i_varDecls )
      local
        SimCode.SimEqSystem i_e;
      equation
        (txt, i_varDecls) = equationLinear(txt, i_e, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_e as SimCode.SES_MIXED(cont = _)),
           i_context,
           i_varDecls )
      local
        SimCode.SimEqSystem i_e;
      equation
        (txt, i_varDecls) = equationMixed(txt, i_e, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_e as SimCode.SES_NONLINEAR(index = _)),
           i_context,
           i_varDecls )
      local
        SimCode.SimEqSystem i_e;
      equation
        (txt, i_varDecls) = equationNonlinear(txt, i_e, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_e as SimCode.SES_WHEN(left = _)),
           i_context,
           i_varDecls )
      local
        SimCode.SimEqSystem i_e;
      equation
        (txt, i_varDecls) = equationWhen(txt, i_e, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("NOT IMPLEMENTED EQUATION"));
      then (txt, i_varDecls);
  end matchcontinue;
end equation_;

protected function fun_189
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_i_c;
  input String in_i_arr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_c, in_i_arr)
    local
      Tpl.Text txt;
      String i_arr;

    case ( txt,
           (i_c as DAE.CREF_QUAL(ident = "$DER")),
           i_arr )
      local
        DAE.ComponentRef i_c;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "inline_integrate_array(size_of_dimension_real_array("
                                }, false));
        txt = Tpl.writeStr(txt, i_arr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(",1),"));
        txt = cref(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_189;

public function inlineArray
  input Tpl.Text in_txt;
  input SimCode.Context in_i_context;
  input String in_i_arr;
  input DAE.ComponentRef in_i_c;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_context, in_i_arr, in_i_c)
    local
      Tpl.Text txt;
      String i_arr;
      DAE.ComponentRef i_c;

    case ( txt,
           SimCode.INLINE_CONTEXT(),
           i_arr,
           i_c )
      equation
        txt = fun_189(txt, i_c, i_arr);
      then txt;

    case ( txt,
           _,
           _,
           _ )
      then txt;
  end matchcontinue;
end inlineArray;

protected function fun_191
  input Tpl.Text in_txt;
  input SimCode.SimVar in_i_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_var)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMVAR(name = (i_cr as DAE.CREF_QUAL(ident = "$DER"))) )
      local
        DAE.ComponentRef i_cr;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("inline_integrate("));
        txt = cref(txt, i_cr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_191;

protected function lm_192
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = fun_191(txt, i_var);
        txt = Tpl.nextIter(txt);
        txt = lm_192(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_192(txt, rest);
      then txt;
  end matchcontinue;
end lm_192;

protected function fun_193
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_i_simvars;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simvars)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_simvars )
      local
        list<SimCode.SimVar> i_simvars;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_192(txt, i_simvars);
        txt = Tpl.popIter(txt);
      then txt;
  end matchcontinue;
end fun_193;

public function inlineVars
  input Tpl.Text in_txt;
  input SimCode.Context in_i_context;
  input list<SimCode.SimVar> in_i_simvars;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_context, in_i_simvars)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> i_simvars;

    case ( txt,
           SimCode.INLINE_CONTEXT(),
           i_simvars )
      equation
        txt = fun_193(txt, i_simvars);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end inlineVars;

protected function fun_195
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_i_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_cr)
    local
      Tpl.Text txt;

    case ( txt,
           (i_cr as DAE.CREF_QUAL(ident = "$DER")) )
      local
        DAE.ComponentRef i_cr;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("inline_integrate("));
        txt = cref(txt, i_cr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_195;

protected function lm_196
  input Tpl.Text in_txt;
  input list<DAE.ComponentRef> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_cr :: rest )
      local
        list<DAE.ComponentRef> rest;
        DAE.ComponentRef i_cr;
      equation
        txt = fun_195(txt, i_cr);
        txt = Tpl.nextIter(txt);
        txt = lm_196(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<DAE.ComponentRef> rest;
      equation
        txt = lm_196(txt, rest);
      then txt;
  end matchcontinue;
end lm_196;

protected function fun_197
  input Tpl.Text in_txt;
  input list<DAE.ComponentRef> in_i_crefs;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_crefs)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_crefs )
      local
        list<DAE.ComponentRef> i_crefs;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_196(txt, i_crefs);
        txt = Tpl.popIter(txt);
      then txt;
  end matchcontinue;
end fun_197;

public function inlineCrefs
  input Tpl.Text in_txt;
  input SimCode.Context in_i_context;
  input list<DAE.ComponentRef> in_i_crefs;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_context, in_i_crefs)
    local
      Tpl.Text txt;
      list<DAE.ComponentRef> i_crefs;

    case ( txt,
           SimCode.INLINE_CONTEXT(),
           i_crefs )
      equation
        txt = fun_197(txt, i_crefs);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end inlineCrefs;

protected function fun_199
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_i_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_cr)
    local
      Tpl.Text txt;

    case ( txt,
           (i_cr as DAE.CREF_QUAL(ident = "$DER")) )
      local
        DAE.ComponentRef i_cr;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "inline_integrate("
                                }, false));
        txt = cref(txt, i_cr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_199;

public function inlineCref
  input Tpl.Text in_txt;
  input SimCode.Context in_i_context;
  input DAE.ComponentRef in_i_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_context, in_i_cr)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_cr;

    case ( txt,
           SimCode.INLINE_CONTEXT(),
           i_cr )
      equation
        txt = fun_199(txt, i_cr);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end inlineCref;

public function equationSimpleAssign
  input Tpl.Text in_txt;
  input SimCode.SimEqSystem in_i_eq;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_eq, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.SES_SIMPLE_ASSIGN(exp = i_exp, cref = i_cref),
           i_context,
           i_varDecls )
      local
        DAE.ComponentRef i_cref;
        DAE.Exp i_exp;
        Tpl.Text i_expPart;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = cref(txt, i_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = inlineCref(txt, i_context, i_cref);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end equationSimpleAssign;

protected function fun_202
  input Tpl.Text in_txt;
  input String in_it;
  input SimCode.Context in_i_context;
  input DAE.ComponentRef in_i_eqn_componentRef;
  input Tpl.Text in_i_expPart;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_it, in_i_context, in_i_eqn_componentRef, in_i_expPart, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      DAE.ComponentRef i_eqn_componentRef;
      Tpl.Text i_expPart;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           "boolean",
           i_context,
           i_eqn_componentRef,
           i_expPart,
           i_preExp,
           i_varDecls )
      local
        Tpl.Text i_tvar;
      equation
        (i_tvar, i_varDecls) = tempDecl(emptyTxt, "boolean_array", i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("copy_boolean_array_data_mem(&"));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = cref(txt, i_eqn_componentRef);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = inlineArray(txt, i_context, Tpl.textString(i_tvar), i_eqn_componentRef);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           "integer",
           i_context,
           i_eqn_componentRef,
           i_expPart,
           i_preExp,
           i_varDecls )
      local
        Tpl.Text i_tvar;
      equation
        (i_tvar, i_varDecls) = tempDecl(emptyTxt, "integer_array", i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("cast_integer_array_to_real(&"));
        i_preExp = Tpl.writeText(i_preExp, i_expPart);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_tvar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("copy_integer_array_data_mem(&"));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = cref(txt, i_eqn_componentRef);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = inlineArray(txt, i_context, Tpl.textString(i_tvar), i_eqn_componentRef);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           "real",
           i_context,
           i_eqn_componentRef,
           i_expPart,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("copy_real_array_data_mem(&"));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = cref(txt, i_eqn_componentRef);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = inlineArray(txt, i_context, Tpl.textString(i_expPart), i_eqn_componentRef);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#error \"No runtime support for this sort of array call\""));
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end fun_202;

public function equationArrayCallAssign
  input Tpl.Text in_txt;
  input SimCode.SimEqSystem in_i_eq;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_eq, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_eqn as SimCode.SES_ARRAY_CALL_ASSIGN(exp = (i_eqn_exp as i_exp), componentRef = i_eqn_componentRef)),
           i_context,
           i_varDecls )
      local
        DAE.ComponentRef i_eqn_componentRef;
        DAE.Exp i_exp;
        DAE.Exp i_eqn_exp;
        SimCode.SimEqSystem i_eqn;
        String str_3;
        Tpl.Text txt_2;
        Tpl.Text i_expPart;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        txt_2 = expTypeFromExpShort(emptyTxt, i_eqn_exp);
        str_3 = Tpl.textString(txt_2);
        (txt, i_preExp, i_varDecls) = fun_202(txt, str_3, i_context, i_eqn_componentRef, i_expPart, i_preExp, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end equationArrayCallAssign;

protected function lm_204
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDecls;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDecls) = algStatement(txt, i_stmt, i_context, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_204(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDecls) = lm_204(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_204;

public function equationAlgorithm
  input Tpl.Text in_txt;
  input SimCode.SimEqSystem in_i_eq;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_eq, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.SES_ALGORITHM(statements = i_statements),
           i_context,
           i_varDecls )
      local
        list<DAE.Statement> i_statements;
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls) = lm_204(txt, i_statements, i_varDecls, i_context);
        txt = Tpl.popIter(txt);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end equationAlgorithm;

protected function fun_206
  input Tpl.Text in_txt;
  input Boolean in_i_partOfMixed;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_partOfMixed)
    local
      Tpl.Text txt;

    case ( txt,
           false )
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_mixed"));
      then txt;
  end matchcontinue;
end fun_206;

protected function lm_207
  input Tpl.Text in_txt;
  input list<tuple<Integer, Integer, SimCode.SimEqSystem>> in_items;
  input Tpl.Text in_i_size;
  input Tpl.Text in_i_aname;
  input Tpl.Text in_i_varDecls;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_size, in_i_aname, in_i_varDecls, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_size;
      Tpl.Text i_aname;
      Tpl.Text i_varDecls;
      SimCode.Context i_context;

    case ( txt,
           {},
           _,
           _,
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           (i_row, i_col, (i_eq as SimCode.SES_RESIDUAL(exp = i_eq_exp))) :: rest,
           i_size,
           i_aname,
           i_varDecls,
           i_context )
      local
        list<tuple<Integer, Integer, SimCode.SimEqSystem>> rest;
        DAE.Exp i_eq_exp;
        SimCode.SimEqSystem i_eq;
        Integer i_col;
        Integer i_row;
        Tpl.Text i_expPart;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_eq_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("set_matrix_elt("));
        txt = Tpl.writeText(txt, i_aname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeStr(txt, intString(i_row));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeStr(txt, intString(i_col));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_size);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_207(txt, rest, i_size, i_aname, i_varDecls, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_size,
           i_aname,
           i_varDecls,
           i_context )
      local
        list<tuple<Integer, Integer, SimCode.SimEqSystem>> rest;
      equation
        (txt, i_varDecls) = lm_207(txt, rest, i_size, i_aname, i_varDecls, i_context);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_207;

protected function lm_208
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_bname;
  input Tpl.Text in_i_varDecls;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_bname, in_i_varDecls, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_bname;
      Tpl.Text i_varDecls;
      SimCode.Context i_context;

    case ( txt,
           {},
           _,
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           i_exp :: rest,
           i_bname,
           i_varDecls,
           i_context )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_exp;
        Integer i_i0;
        Tpl.Text i_expPart;
        Tpl.Text i_preExp;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        i_preExp = emptyTxt;
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("set_vector_elt("));
        txt = Tpl.writeText(txt, i_bname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeStr(txt, intString(i_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_208(txt, rest, i_bname, i_varDecls, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_bname,
           i_varDecls,
           i_context )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls) = lm_208(txt, rest, i_bname, i_varDecls, i_context);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_208;

protected function lm_209
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;
  input Tpl.Text in_i_bname;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items, in_i_bname)
    local
      Tpl.Text txt;
      Tpl.Text i_bname;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name) :: rest,
           i_bname )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Integer i_i0;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = get_vector_elt("));
        txt = Tpl.writeText(txt, i_bname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeStr(txt, intString(i_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.nextIter(txt);
        txt = lm_209(txt, rest, i_bname);
      then txt;

    case ( txt,
           _ :: rest,
           i_bname )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_209(txt, rest, i_bname);
      then txt;
  end matchcontinue;
end lm_209;

public function equationLinear
  input Tpl.Text in_txt;
  input SimCode.SimEqSystem in_i_eq;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_eq, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.SES_LINEAR(vars = i_vars, partOfMixed = i_partOfMixed, simJac = i_simJac, beqs = i_beqs),
           i_context,
           i_varDecls )
      local
        list<DAE.Exp> i_beqs;
        list<tuple<Integer, Integer, SimCode.SimEqSystem>> i_simJac;
        Boolean i_partOfMixed;
        list<SimCode.SimVar> i_vars;
        Tpl.Text i_mixedPostfix;
        Tpl.Text i_bname;
        Tpl.Text i_aname;
        Integer ret_3;
        Tpl.Text i_size;
        Integer ret_1;
        Tpl.Text i_uid;
      equation
        ret_1 = System.tmpTick();
        i_uid = Tpl.writeStr(emptyTxt, intString(ret_1));
        ret_3 = listLength(i_vars);
        i_size = Tpl.writeStr(emptyTxt, intString(ret_3));
        i_aname = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("A"));
        i_aname = Tpl.writeText(i_aname, i_uid);
        i_bname = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("b"));
        i_bname = Tpl.writeText(i_bname, i_uid);
        i_mixedPostfix = fun_206(emptyTxt, i_partOfMixed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("declare_matrix("));
        txt = Tpl.writeText(txt, i_aname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_size);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_size);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\n",
                                    "declare_vector("
                                }, false));
        txt = Tpl.writeText(txt, i_bname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_size);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls) = lm_207(txt, i_simJac, i_size, i_aname, i_varDecls, i_context);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls) = lm_208(txt, i_beqs, i_bname, i_varDecls, i_context);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("solve_linear_equation_system"));
        txt = Tpl.writeText(txt, i_mixedPostfix);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_aname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_bname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_size);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_uid);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_209(txt, i_vars, i_bname);
        txt = Tpl.popIter(txt);
        txt = inlineVars(txt, i_context, i_vars);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end equationLinear;

protected function lm_211
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preDisc;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preDisc;
algorithm
  (out_txt, out_i_varDecls, out_i_preDisc) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preDisc, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preDisc;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           i_preDisc,
           _ )
      then (txt, i_varDecls, i_preDisc);

    case ( txt,
           SimCode.SES_SIMPLE_ASSIGN(exp = i_exp, cref = i_cref) :: rest,
           i_varDecls,
           i_preDisc,
           i_context )
      local
        list<SimCode.SimEqSystem> rest;
        DAE.ComponentRef i_cref;
        DAE.Exp i_exp;
        Integer i_i0;
        Tpl.Text i_expPart;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        (i_expPart, i_preDisc, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preDisc, i_varDecls);
        txt = cref(txt, i_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ";\n",
                                    "discrete_loc2["
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = "));
        txt = cref(txt, i_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preDisc) = lm_211(txt, rest, i_varDecls, i_preDisc, i_context);
      then (txt, i_varDecls, i_preDisc);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preDisc,
           i_context )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls, i_preDisc) = lm_211(txt, rest, i_varDecls, i_preDisc, i_context);
      then (txt, i_varDecls, i_preDisc);
  end matchcontinue;
end lm_211;

protected function lm_212
  input Tpl.Text in_txt;
  input list<String> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_it :: rest )
      local
        list<String> rest;
        String i_it;
      equation
        txt = Tpl.writeStr(txt, i_it);
        txt = Tpl.nextIter(txt);
        txt = lm_212(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<String> rest;
      equation
        txt = lm_212(txt, rest);
      then txt;
  end matchcontinue;
end lm_212;

protected function lm_213
  input Tpl.Text in_txt;
  input list<Integer> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_it :: rest )
      local
        list<Integer> rest;
        Integer i_it;
      equation
        txt = Tpl.writeStr(txt, intString(i_it));
        txt = Tpl.nextIter(txt);
        txt = lm_213(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<Integer> rest;
      equation
        txt = lm_213(txt, rest);
      then txt;
  end matchcontinue;
end lm_213;

protected function lm_214
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Integer i_i0;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("discrete_loc["));
        txt = Tpl.writeStr(txt, intString(i_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = "));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_214(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_214(txt, rest);
      then txt;
  end matchcontinue;
end lm_214;

protected function lm_215
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(double*)&"));
        txt = cref(txt, i_name);
        txt = Tpl.nextIter(txt);
        txt = lm_215(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_215(txt, rest);
      then txt;
  end matchcontinue;
end lm_215;

public function equationMixed
  input Tpl.Text in_txt;
  input SimCode.SimEqSystem in_i_eq;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_eq, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.SES_MIXED(cont = i_cont, discVars = i_discVars, values = i_values, discEqs = i_discEqs, value_dims = i_value__dims),
           i_context,
           i_varDecls )
      local
        list<Integer> i_value__dims;
        list<SimCode.SimEqSystem> i_discEqs;
        list<String> i_values;
        list<SimCode.SimVar> i_discVars;
        SimCode.SimEqSystem i_cont;
        Tpl.Text i_discLoc2;
        Tpl.Text i_preDisc;
        Integer ret_4;
        Tpl.Text i_valuesLenStr;
        Integer ret_2;
        Tpl.Text i_numDiscVarsStr;
        Tpl.Text i_contEqs;
      equation
        (i_contEqs, i_varDecls) = equation_(emptyTxt, i_cont, i_context, i_varDecls);
        ret_2 = listLength(i_discVars);
        i_numDiscVarsStr = Tpl.writeStr(emptyTxt, intString(ret_2));
        ret_4 = listLength(i_values);
        i_valuesLenStr = Tpl.writeStr(emptyTxt, intString(ret_4));
        i_preDisc = emptyTxt;
        i_discLoc2 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_discLoc2, i_varDecls, i_preDisc) = lm_211(i_discLoc2, i_discEqs, i_varDecls, i_preDisc, i_context);
        i_discLoc2 = Tpl.popIter(i_discLoc2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mixed_equation_system("));
        txt = Tpl.writeText(txt, i_numDiscVarsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\n",
                                    "double values["
                                }, false));
        txt = Tpl.writeText(txt, i_valuesLenStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = {"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_212(txt, i_values);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "};\n",
                                    "int value_dims["
                                }, false));
        txt = Tpl.writeText(txt, i_numDiscVarsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = {"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_213(txt, i_value__dims);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("};\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_214(txt, i_discVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("{\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_contEqs);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("}\n"));
        txt = Tpl.writeText(txt, i_preDisc);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_discLoc2);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("{\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("double *loc_ptrs["));
        txt = Tpl.writeText(txt, i_numDiscVarsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = {"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_215(txt, i_discVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "};\n",
                                    "check_discrete_values("
                                }, false));
        txt = Tpl.writeText(txt, i_numDiscVarsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_valuesLenStr);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "mixed_equation_system_end("
                                }, false));
        txt = Tpl.writeText(txt, i_numDiscVarsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end equationMixed;

protected function lm_217
  input Tpl.Text in_txt;
  input list<DAE.ComponentRef> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_name :: rest )
      local
        list<DAE.ComponentRef> rest;
        DAE.ComponentRef i_name;
        Integer i_i0;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("nls_x["));
        txt = Tpl.writeStr(txt, intString(i_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = extraPolate("));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\n",
                                    "nls_xold["
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = $P$old"));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_217(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<DAE.ComponentRef> rest;
      equation
        txt = lm_217(txt, rest);
      then txt;
  end matchcontinue;
end lm_217;

protected function lm_218
  input Tpl.Text in_txt;
  input list<DAE.ComponentRef> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_name :: rest )
      local
        list<DAE.ComponentRef> rest;
        DAE.ComponentRef i_name;
        Integer i_i0;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = nls_x["));
        txt = Tpl.writeStr(txt, intString(i_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];"));
        txt = Tpl.nextIter(txt);
        txt = lm_218(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<DAE.ComponentRef> rest;
      equation
        txt = lm_218(txt, rest);
      then txt;
  end matchcontinue;
end lm_218;

protected function fun_219
  input Tpl.Text in_txt;
  input SimCode.SimEqSystem in_i_eq;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_eq, in_i_context)
    local
      Tpl.Text txt;
      SimCode.Context i_context;

    case ( txt,
           SimCode.SES_NONLINEAR(crefs = i_crefs, index = i_index),
           i_context )
      local
        Integer i_index;
        list<DAE.ComponentRef> i_crefs;
        Integer ret_1;
        Tpl.Text i_size;
      equation
        ret_1 = listLength(i_crefs);
        i_size = Tpl.writeStr(emptyTxt, intString(ret_1));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("start_nonlinear_system("));
        txt = Tpl.writeText(txt, i_size);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_217(txt, i_crefs);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("solve_nonlinear_system(residualFunc"));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_218(txt, i_crefs);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("end_nonlinear_system();"));
        txt = inlineCrefs(txt, i_context, i_crefs);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_219;

public function equationNonlinear
  input Tpl.Text txt;
  input SimCode.SimEqSystem i_eq;
  input SimCode.Context i_context;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  out_txt := fun_219(txt, i_eq, i_context);
  out_i_varDecls := i_varDecls;
end equationNonlinear;

protected function lm_221
  input Tpl.Text in_txt;
  input list<tuple<DAE.Exp, Integer>> in_items;
  input Tpl.Text in_i_helpInits;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_helpInits;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_helpInits, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_helpInits, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_helpInits;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_helpInits,
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_helpInits, i_varDecls, i_preExp);

    case ( txt,
           (i_e, i_hidx) :: rest,
           i_helpInits,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<tuple<DAE.Exp, Integer>> rest;
        Integer i_hidx;
        DAE.Exp i_e;
        Tpl.Text i_helpInit;
      equation
        (i_helpInit, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
        i_helpInits = Tpl.writeTok(i_helpInits, Tpl.ST_STRING("localData->helpVars["));
        i_helpInits = Tpl.writeStr(i_helpInits, intString(i_hidx));
        i_helpInits = Tpl.writeTok(i_helpInits, Tpl.ST_STRING("] = "));
        i_helpInits = Tpl.writeText(i_helpInits, i_helpInit);
        i_helpInits = Tpl.writeTok(i_helpInits, Tpl.ST_STRING(";"));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("edge(localData->helpVars["));
        txt = Tpl.writeStr(txt, intString(i_hidx));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("])"));
        txt = Tpl.nextIter(txt);
        (txt, i_helpInits, i_varDecls, i_preExp) = lm_221(txt, rest, i_helpInits, i_varDecls, i_preExp, i_context);
      then (txt, i_helpInits, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_helpInits,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<tuple<DAE.Exp, Integer>> rest;
      equation
        (txt, i_helpInits, i_varDecls, i_preExp) = lm_221(txt, rest, i_helpInits, i_varDecls, i_preExp, i_context);
      then (txt, i_helpInits, i_varDecls, i_preExp);
  end matchcontinue;
end lm_221;

public function equationWhen
  input Tpl.Text in_txt;
  input SimCode.SimEqSystem in_i_eq;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_eq, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.SES_WHEN(conditions = i_conditions, right = i_right, left = i_left),
           i_context,
           i_varDecls )
      local
        DAE.ComponentRef i_left;
        DAE.Exp i_right;
        list<tuple<DAE.Exp, Integer>> i_conditions;
        Tpl.Text i_exp;
        Tpl.Text i_preExp2;
        Tpl.Text i_helpIf;
        Tpl.Text i_helpInits;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        i_helpInits = emptyTxt;
        i_helpIf = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(" || ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_helpIf, i_helpInits, i_varDecls, i_preExp) = lm_221(i_helpIf, i_conditions, i_helpInits, i_varDecls, i_preExp, i_context);
        i_helpIf = Tpl.popIter(i_helpIf);
        i_preExp2 = emptyTxt;
        (i_exp, i_preExp2, i_varDecls) = daeExp(emptyTxt, i_right, i_context, i_preExp2, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_helpInits);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if ("));
        txt = Tpl.writeText(txt, i_helpIf);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_preExp2);
        txt = Tpl.softNewLine(txt);
        txt = cref(txt, i_left);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, i_exp);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("} else {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = cref(txt, i_left);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = pre("));
        txt = cref(txt, i_left);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end equationWhen;

public function simulationFunctionsFile
  input Tpl.Text txt;
  input list<SimCode.Function> i_functions;
  input list<String> i_includes;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "#ifdef __cplusplus\n",
                                   "extern \"C\" {\n",
                                   "#endif\n",
                                   "\n",
                                   "/* Header */\n"
                               }, true));
  out_txt := externalFunctionIncludes(out_txt, i_includes);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := functionHeaders(out_txt, i_functions);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "/* End Header */\n",
                                       "\n",
                                       "/* Body */\n"
                                   }, true));
  out_txt := functionBodies(out_txt, i_functions);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "/* End Body */\n",
                                       "\n",
                                       "#ifdef __cplusplus\n",
                                       "}\n",
                                       "#endif\n",
                                       "\n"
                                   }, true));
end simulationFunctionsFile;

protected function fun_224
  input Tpl.Text in_txt;
  input String in_i_modelInfo_directory;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_modelInfo_directory)
    local
      Tpl.Text txt;

    case ( txt,
           "" )
      then txt;

    case ( txt,
           i_modelInfo_directory )
      local
        String i_modelInfo_directory;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("-L\""));
        txt = Tpl.writeStr(txt, i_modelInfo_directory);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
      then txt;
  end matchcontinue;
end fun_224;

protected function lm_225
  input Tpl.Text in_txt;
  input list<String> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_lib :: rest )
      local
        list<String> rest;
        String i_lib;
      equation
        txt = Tpl.writeStr(txt, i_lib);
        txt = Tpl.nextIter(txt);
        txt = lm_225(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<String> rest;
      equation
        txt = lm_225(txt, rest);
      then txt;
  end matchcontinue;
end lm_225;

protected function fun_226
  input Tpl.Text in_txt;
  input String in_it;
  input Tpl.Text in_i_libsStr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it, in_i_libsStr)
    local
      Tpl.Text txt;
      Tpl.Text i_libsStr;

    case ( txt,
           "",
           i_libsStr )
      equation
        txt = Tpl.writeText(txt, i_libsStr);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_226;

protected function fun_227
  input Tpl.Text in_txt;
  input String in_it;
  input Tpl.Text in_i_libsStr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it, in_i_libsStr)
    local
      Tpl.Text txt;
      Tpl.Text i_libsStr;

    case ( txt,
           "",
           _ )
      then txt;

    case ( txt,
           _,
           i_libsStr )
      equation
        txt = Tpl.writeText(txt, i_libsStr);
      then txt;
  end matchcontinue;
end fun_227;

public function simulationMakefile
  input Tpl.Text in_txt;
  input SimCode.SimCode in_i_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simCode)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMCODE(modelInfo = SimCode.MODELINFO(directory = i_modelInfo_directory), makefileParams = SimCode.MAKEFILE_PARAMS(libs = i_makefileParams_libs, ccompiler = i_makefileParams_ccompiler, cxxcompiler = i_makefileParams_cxxcompiler, linker = i_makefileParams_linker, exeext = i_makefileParams_exeext, dllext = i_makefileParams_dllext, omhome = i_makefileParams_omhome, cflags = i_makefileParams_cflags, ldflags = i_makefileParams_ldflags, senddatalibs = i_makefileParams_senddatalibs), fileNamePrefix = i_fileNamePrefix) )
      local
        String i_fileNamePrefix;
        String i_makefileParams_senddatalibs;
        String i_makefileParams_ldflags;
        String i_makefileParams_cflags;
        String i_makefileParams_omhome;
        String i_makefileParams_dllext;
        String i_makefileParams_exeext;
        String i_makefileParams_linker;
        String i_makefileParams_cxxcompiler;
        String i_makefileParams_ccompiler;
        list<String> i_makefileParams_libs;
        String i_modelInfo_directory;
        String str_5;
        Tpl.Text i_libsPos2;
        String str_3;
        Tpl.Text i_libsPos1;
        Tpl.Text i_libsStr;
        Tpl.Text i_dirExtra;
      equation
        i_dirExtra = fun_224(emptyTxt, i_modelInfo_directory);
        i_libsStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(" ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        i_libsStr = lm_225(i_libsStr, i_makefileParams_libs);
        i_libsStr = Tpl.popIter(i_libsStr);
        str_3 = Tpl.textString(i_dirExtra);
        i_libsPos1 = fun_226(emptyTxt, str_3, i_libsStr);
        str_5 = Tpl.textString(i_dirExtra);
        i_libsPos2 = fun_227(emptyTxt, str_5, i_libsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "# Makefile generated by OpenModelica\n",
                                    "\n",
                                    "CC="
                                }, false));
        txt = Tpl.writeStr(txt, i_makefileParams_ccompiler);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("CXX="));
        txt = Tpl.writeStr(txt, i_makefileParams_cxxcompiler);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("LINK="));
        txt = Tpl.writeStr(txt, i_makefileParams_linker);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("EXEEXT="));
        txt = Tpl.writeStr(txt, i_makefileParams_exeext);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("DLLEXT="));
        txt = Tpl.writeStr(txt, i_makefileParams_dllext);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("CFLAGS=-I\""));
        txt = Tpl.writeStr(txt, i_makefileParams_omhome);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("/include/omc\" "));
        txt = Tpl.writeStr(txt, i_makefileParams_cflags);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("LDFLAGS=-L\""));
        txt = Tpl.writeStr(txt, i_makefileParams_omhome);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("/lib/omc\" "));
        txt = Tpl.writeStr(txt, i_makefileParams_ldflags);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("SENDDATALIBS="));
        txt = Tpl.writeStr(txt, i_makefileParams_senddatalibs);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    ".PHONY: "
                                }, false));
        txt = Tpl.writeStr(txt, i_fileNamePrefix);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeStr(txt, i_fileNamePrefix);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(": "));
        txt = Tpl.writeStr(txt, i_fileNamePrefix);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(".cpp\n"));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\t"));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" $(CXX) $(CFLAGS) -I. -o "));
        txt = Tpl.writeStr(txt, i_fileNamePrefix);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$(EXEEXT) "));
        txt = Tpl.writeStr(txt, i_fileNamePrefix);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(".cpp "));
        txt = Tpl.writeText(txt, i_dirExtra);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = Tpl.writeText(txt, i_libsPos1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" -lsim $(LDFLAGS) -lf2c -linteractive $(SENDDATALIBS) "));
        txt = Tpl.writeText(txt, i_libsPos2);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end simulationMakefile;

public function simulationInitFile
  input Tpl.Text in_txt;
  input SimCode.SimCode in_i_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simCode)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMCODE(modelInfo = SimCode.MODELINFO(varInfo = (i_vi as SimCode.VARINFO(numStateVars = i_vi_numStateVars, numAlgVars = i_vi_numAlgVars, numParams = i_vi_numParams, numIntParams = i_vi_numIntParams, numIntAlgVars = i_vi_numIntAlgVars, numBoolParams = i_vi_numBoolParams, numBoolAlgVars = i_vi_numBoolAlgVars, numStringParamVars = i_vi_numStringParamVars, numStringAlgVars = i_vi_numStringAlgVars)), vars = (i_vars as SimCode.SIMVARS(stateVars = i_vars_stateVars, derivativeVars = i_vars_derivativeVars, algVars = i_vars_algVars, paramVars = i_vars_paramVars, intParamVars = i_vars_intParamVars, intAlgVars = i_vars_intAlgVars, boolParamVars = i_vars_boolParamVars, boolAlgVars = i_vars_boolAlgVars, stringParamVars = i_vars_stringParamVars, stringAlgVars = i_vars_stringAlgVars))), simulationSettingsOpt = SOME((i_s as SimCode.SIMULATION_SETTINGS(startTime = i_s_startTime, stopTime = i_s_stopTime, stepSize = i_s_stepSize, tolerance = i_s_tolerance, method = i_s_method, outputFormat = i_s_outputFormat)))) )
      local
        String i_s_outputFormat;
        String i_s_method;
        Real i_s_tolerance;
        Real i_s_stepSize;
        Real i_s_stopTime;
        Real i_s_startTime;
        SimCode.SimulationSettings i_s;
        list<SimCode.SimVar> i_vars_stringAlgVars;
        list<SimCode.SimVar> i_vars_stringParamVars;
        list<SimCode.SimVar> i_vars_boolAlgVars;
        list<SimCode.SimVar> i_vars_boolParamVars;
        list<SimCode.SimVar> i_vars_intAlgVars;
        list<SimCode.SimVar> i_vars_intParamVars;
        list<SimCode.SimVar> i_vars_paramVars;
        list<SimCode.SimVar> i_vars_algVars;
        list<SimCode.SimVar> i_vars_derivativeVars;
        list<SimCode.SimVar> i_vars_stateVars;
        SimCode.SimVars i_vars;
        Integer i_vi_numStringAlgVars;
        Integer i_vi_numStringParamVars;
        Integer i_vi_numBoolAlgVars;
        Integer i_vi_numBoolParams;
        Integer i_vi_numIntAlgVars;
        Integer i_vi_numIntParams;
        Integer i_vi_numParams;
        Integer i_vi_numAlgVars;
        Integer i_vi_numStateVars;
        SimCode.VarInfo i_vi;
      equation
        txt = Tpl.writeStr(txt, realString(i_s_startTime));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" // start value\n"));
        txt = Tpl.writeStr(txt, realString(i_s_stopTime));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" // stop value\n"));
        txt = Tpl.writeStr(txt, realString(i_s_stepSize));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" // step value\n"));
        txt = Tpl.writeStr(txt, realString(i_s_tolerance));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // tolerance\n",
                                    "\""
                                }, false));
        txt = Tpl.writeStr(txt, i_s_method);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\" // method\n",
                                    "\""
                                }, false));
        txt = Tpl.writeStr(txt, i_s_outputFormat);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("\" // outputFormat\n"));
        txt = Tpl.writeStr(txt, intString(i_vi_numStateVars));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" // n states\n"));
        txt = Tpl.writeStr(txt, intString(i_vi_numAlgVars));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" // n alg vars\n"));
        txt = Tpl.writeStr(txt, intString(i_vi_numParams));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" //n parameters\n"));
        txt = Tpl.writeStr(txt, intString(i_vi_numIntParams));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" // n int parameters\n"));
        txt = Tpl.writeStr(txt, intString(i_vi_numIntAlgVars));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" // n int variables\n"));
        txt = Tpl.writeStr(txt, intString(i_vi_numBoolParams));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" // n bool parameters\n"));
        txt = Tpl.writeStr(txt, intString(i_vi_numBoolAlgVars));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" // n bool variables\n"));
        txt = Tpl.writeStr(txt, intString(i_vi_numStringParamVars));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" // n string-parameters\n"));
        txt = Tpl.writeStr(txt, intString(i_vi_numStringAlgVars));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" // n string variables\n"));
        txt = initVals(txt, i_vars_stateVars);
        txt = Tpl.softNewLine(txt);
        txt = initVals(txt, i_vars_derivativeVars);
        txt = Tpl.softNewLine(txt);
        txt = initVals(txt, i_vars_algVars);
        txt = Tpl.softNewLine(txt);
        txt = initVals(txt, i_vars_paramVars);
        txt = Tpl.softNewLine(txt);
        txt = initVals(txt, i_vars_intParamVars);
        txt = Tpl.softNewLine(txt);
        txt = initVals(txt, i_vars_intAlgVars);
        txt = Tpl.softNewLine(txt);
        txt = initVals(txt, i_vars_boolParamVars);
        txt = Tpl.softNewLine(txt);
        txt = initVals(txt, i_vars_boolAlgVars);
        txt = Tpl.softNewLine(txt);
        txt = initVals(txt, i_vars_stringParamVars);
        txt = Tpl.softNewLine(txt);
        txt = initVals(txt, i_vars_stringAlgVars);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end simulationInitFile;

protected function fun_230
  input Tpl.Text in_txt;
  input Boolean in_i_bool;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_bool)
    local
      Tpl.Text txt;

    case ( txt,
           false )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("false"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("true"));
      then txt;
  end matchcontinue;
end fun_230;

protected function fun_231
  input Tpl.Text in_txt;
  input DAE.Exp in_i_v;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_v)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ICONST(integer = i_integer) )
      local
        Integer i_integer;
      equation
        txt = Tpl.writeStr(txt, intString(i_integer));
      then txt;

    case ( txt,
           DAE.RCONST(real = i_real) )
      local
        Real i_real;
      equation
        txt = Tpl.writeStr(txt, realString(i_real));
      then txt;

    case ( txt,
           DAE.SCONST(string = i_string) )
      local
        String i_string;
        String ret_0;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        ret_0 = Util.escapeModelicaStringToCString(i_string);
        txt = Tpl.writeStr(txt, ret_0);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
      then txt;

    case ( txt,
           DAE.BCONST(bool = i_bool) )
      local
        Boolean i_bool;
      equation
        txt = fun_230(txt, i_bool);
      then txt;

    case ( txt,
           DAE.ENUM_LITERAL(index = i_index, name = i_name) )
      local
        Absyn.Path i_name;
        Integer i_index;
      equation
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("/*ENUM:"));
        txt = dotPath(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("*/"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("*ERROR* initial value of unknown type"));
      then txt;
  end matchcontinue;
end fun_231;

protected function fun_232
  input Tpl.Text in_txt;
  input Option<DAE.Exp> in_i_initialValue;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_initialValue)
    local
      Tpl.Text txt;

    case ( txt,
           SOME(i_v) )
      local
        DAE.Exp i_v;
      equation
        txt = fun_231(txt, i_v);
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("0.0 //default"));
      then txt;
  end matchcontinue;
end fun_232;

protected function lm_233
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(initialValue = i_initialValue, name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Option<DAE.Exp> i_initialValue;
      equation
        txt = fun_232(txt, i_initialValue);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" //"));
        txt = crefStr(txt, i_name);
        txt = Tpl.nextIter(txt);
        txt = lm_233(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_233(txt, rest);
      then txt;
  end matchcontinue;
end lm_233;

public function initVals
  input Tpl.Text txt;
  input list<SimCode.SimVar> i_varsLst;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_233(out_txt, i_varsLst);
  out_txt := Tpl.popIter(out_txt);
end initVals;

protected function lm_235
  input Tpl.Text in_txt;
  input list<SimCode.RecordDeclaration> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_rd :: rest )
      local
        list<SimCode.RecordDeclaration> rest;
        SimCode.RecordDeclaration i_rd;
      equation
        txt = recordDeclaration(txt, i_rd);
        txt = Tpl.nextIter(txt);
        txt = lm_235(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.RecordDeclaration> rest;
      equation
        txt = lm_235(txt, rest);
      then txt;
  end matchcontinue;
end lm_235;

public function functionsFile
  input Tpl.Text txt;
  input SimCode.Function i_mainFunction;
  input list<SimCode.Function> i_functions;
  input list<SimCode.RecordDeclaration> i_extraRecordDecls;
  input list<String> i_includes;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "#include \"modelica.h\"\n",
                                   "#include <algorithm>\n",
                                   "#include <stdio.h>\n",
                                   "#include <stdlib.h>\n",
                                   "#include <errno.h>\n",
                                   "\n",
                                   "#if defined(_MSC_VER)\n",
                                   "  #define DLLExport   __declspec( dllexport )\n",
                                   "#else\n",
                                   "  #define DLLExport /* nothing */\n",
                                   "#endif\n",
                                   "\n",
                                   "#if !defined(MODELICA_ASSERT)\n",
                                   "  #define MODELICA_ASSERT(cond,msg) { if (!(cond)) fprintf(stderr,\"Modelica Assert: %s!\\n\", msg); }\n",
                                   "#endif\n",
                                   "#if !defined(MODELICA_TERMINATE)\n",
                                   "  #define MODELICA_TERMINATE(msg) { fprintf(stderr,\"Modelica Terminate: %s!\\n\", msg); fflush(stderr); }\n",
                                   "#endif\n",
                                   "\n",
                                   "#ifdef __cplusplus\n",
                                   "extern \"C\" {\n",
                                   "#endif\n",
                                   "\n",
                                   "/* Header */\n"
                               }, true));
  out_txt := externalFunctionIncludes(out_txt, i_includes);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := functionHeader(out_txt, i_mainFunction, true);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := functionHeaders(out_txt, i_functions);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_235(out_txt, i_extraRecordDecls);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "/* End Header */\n",
                                       "\n",
                                       "/* Body */\n"
                                   }, true));
  out_txt := functionBody(out_txt, i_mainFunction, true);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := functionBodies(out_txt, i_functions);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "/* End Body */\n",
                                       "\n",
                                       "#ifdef __cplusplus\n",
                                       "}\n",
                                       "#endif"
                                   }, false));
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_NEW_LINE());
end functionsFile;

protected function lm_237
  input Tpl.Text in_txt;
  input list<String> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_it :: rest )
      local
        list<String> rest;
        String i_it;
      equation
        txt = Tpl.writeStr(txt, i_it);
        txt = Tpl.nextIter(txt);
        txt = lm_237(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<String> rest;
      equation
        txt = lm_237(txt, rest);
      then txt;
  end matchcontinue;
end lm_237;

public function functionsMakefile
  input Tpl.Text in_txt;
  input SimCode.FunctionCode in_i_fnCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_fnCode)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.FUNCTIONCODE(makefileParams = SimCode.MAKEFILE_PARAMS(libs = i_makefileParams_libs, ccompiler = i_makefileParams_ccompiler, cxxcompiler = i_makefileParams_cxxcompiler, linker = i_makefileParams_linker, exeext = i_makefileParams_exeext, dllext = i_makefileParams_dllext, omhome = i_makefileParams_omhome, cflags = i_makefileParams_cflags, ldflags = i_makefileParams_ldflags), name = i_name) )
      local
        String i_name;
        String i_makefileParams_ldflags;
        String i_makefileParams_cflags;
        String i_makefileParams_omhome;
        String i_makefileParams_dllext;
        String i_makefileParams_exeext;
        String i_makefileParams_linker;
        String i_makefileParams_cxxcompiler;
        String i_makefileParams_ccompiler;
        list<String> i_makefileParams_libs;
        Tpl.Text i_libsStr;
      equation
        i_libsStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(" ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        i_libsStr = lm_237(i_libsStr, i_makefileParams_libs);
        i_libsStr = Tpl.popIter(i_libsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "# Makefile generated by OpenModelica\n",
                                    "\n",
                                    "CC="
                                }, false));
        txt = Tpl.writeStr(txt, i_makefileParams_ccompiler);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("CXX="));
        txt = Tpl.writeStr(txt, i_makefileParams_cxxcompiler);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("LINK="));
        txt = Tpl.writeStr(txt, i_makefileParams_linker);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("EXEEXT="));
        txt = Tpl.writeStr(txt, i_makefileParams_exeext);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("DLLEXT="));
        txt = Tpl.writeStr(txt, i_makefileParams_dllext);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("CFLAGS= -I\""));
        txt = Tpl.writeStr(txt, i_makefileParams_omhome);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("/include/omc\" "));
        txt = Tpl.writeStr(txt, i_makefileParams_cflags);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("LDFLAGS= -L\""));
        txt = Tpl.writeStr(txt, i_makefileParams_omhome);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("/lib/omc\" "));
        txt = Tpl.writeStr(txt, i_makefileParams_ldflags);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    ".PHONY: "
                                }, false));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(": "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(".c\n"));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\t"));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" $(LINK) $(CFLAGS) -o "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$(DLLEXT) "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(".c "));
        txt = Tpl.writeText(txt, i_libsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" $(LDFLAGS) -lm"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end functionsMakefile;

protected function fun_239
  input Tpl.Text in_txt;
  input SimCode.Context in_i_context;
  input DAE.ComponentRef in_i_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_context, in_i_cr)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_cr;

    case ( txt,
           SimCode.FUNCTION_CONTEXT(),
           i_cr )
      equation
        txt = crefStr(txt, i_cr);
      then txt;

    case ( txt,
           _,
           i_cr )
      equation
        txt = cref(txt, i_cr);
      then txt;
  end matchcontinue;
end fun_239;

public function contextCref
  input Tpl.Text txt;
  input DAE.ComponentRef i_cr;
  input SimCode.Context i_context;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_239(txt, i_context, i_cr);
end contextCref;

protected function fun_241
  input Tpl.Text in_txt;
  input SimCode.Context in_i_context;
  input Absyn.Ident in_i_name;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_context, in_i_name)
    local
      Tpl.Text txt;
      Absyn.Ident i_name;

    case ( txt,
           SimCode.FUNCTION_CONTEXT(),
           i_name )
      equation
        txt = Tpl.writeStr(txt, i_name);
      then txt;

    case ( txt,
           _,
           i_name )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$P"));
        txt = Tpl.writeStr(txt, i_name);
      then txt;
  end matchcontinue;
end fun_241;

public function contextIteratorName
  input Tpl.Text txt;
  input Absyn.Ident i_name;
  input SimCode.Context i_context;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_241(txt, i_context, i_name);
end contextIteratorName;

public function cref
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_i_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_cr)
    local
      Tpl.Text txt;

    case ( txt,
           (i_cr as DAE.CREF_IDENT(ident = "xloc")) )
      local
        DAE.ComponentRef i_cr;
      equation
        txt = crefStr(txt, i_cr);
      then txt;

    case ( txt,
           DAE.CREF_IDENT(ident = "time") )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("time"));
      then txt;

    case ( txt,
           i_cr )
      local
        DAE.ComponentRef i_cr;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$P"));
        txt = crefToCStr(txt, i_cr);
      then txt;
  end matchcontinue;
end cref;

public function crefToCStr
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_i_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_cr)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.CREF_IDENT(ident = i_ident, subscriptLst = i_subscriptLst) )
      local
        list<DAE.Subscript> i_subscriptLst;
        DAE.Ident i_ident;
      equation
        txt = Tpl.writeStr(txt, i_ident);
        txt = subscriptsToCStr(txt, i_subscriptLst);
      then txt;

    case ( txt,
           DAE.CREF_QUAL(ident = i_ident, subscriptLst = i_subscriptLst, componentRef = i_componentRef) )
      local
        DAE.ComponentRef i_componentRef;
        list<DAE.Subscript> i_subscriptLst;
        DAE.Ident i_ident;
      equation
        txt = Tpl.writeStr(txt, i_ident);
        txt = subscriptsToCStr(txt, i_subscriptLst);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$P"));
        txt = crefToCStr(txt, i_componentRef);
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("CREF_NOT_IDENT_OR_QUAL"));
      then txt;
  end matchcontinue;
end crefToCStr;

protected function lm_245
  input Tpl.Text in_txt;
  input list<DAE.Subscript> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_s :: rest )
      local
        list<DAE.Subscript> rest;
        DAE.Subscript i_s;
      equation
        txt = subscriptToCStr(txt, i_s);
        txt = Tpl.nextIter(txt);
        txt = lm_245(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<DAE.Subscript> rest;
      equation
        txt = lm_245(txt, rest);
      then txt;
  end matchcontinue;
end lm_245;

public function subscriptsToCStr
  input Tpl.Text in_txt;
  input list<DAE.Subscript> in_i_subscripts;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_subscripts)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_subscripts )
      local
        list<DAE.Subscript> i_subscripts;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$lB"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING("$c")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_245(txt, i_subscripts);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$rB"));
      then txt;
  end matchcontinue;
end subscriptsToCStr;

protected function fun_247
  input Tpl.Text in_txt;
  input DAE.Subscript in_i_subscript;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_i_subscript, in_i_varDecls, in_i_preExp)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;

    case ( txt,
           DAE.INDEX(exp = i_exp),
           i_varDecls,
           i_preExp )
      local
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_exp, SimCode.contextSimulationNonDiscrete, i_preExp, i_varDecls);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           DAE.SLICE(exp = i_exp),
           i_varDecls,
           i_preExp )
      local
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_exp, SimCode.contextSimulationNonDiscrete, i_preExp, i_varDecls);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           DAE.WHOLEDIM(),
           i_varDecls,
           i_preExp )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("WHOLEDIM"));
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _,
           i_varDecls,
           i_preExp )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("UNKNOWN_SUBSCRIPT"));
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_247;

public function subscriptToCStr
  input Tpl.Text txt;
  input DAE.Subscript i_subscript;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_varDecls;
  Tpl.Text i_preExp;
algorithm
  i_preExp := emptyTxt;
  i_varDecls := emptyTxt;
  (out_txt, i_varDecls, i_preExp) := fun_247(txt, i_subscript, i_varDecls, i_preExp);
end subscriptToCStr;

public function crefStr
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_i_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_cr)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.CREF_IDENT(ident = i_ident, subscriptLst = i_subscriptLst) )
      local
        list<DAE.Subscript> i_subscriptLst;
        DAE.Ident i_ident;
      equation
        txt = Tpl.writeStr(txt, i_ident);
        txt = subscriptsStr(txt, i_subscriptLst);
      then txt;

    case ( txt,
           DAE.CREF_QUAL(ident = "$DER", componentRef = i_componentRef) )
      local
        DAE.ComponentRef i_componentRef;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("der("));
        txt = crefStr(txt, i_componentRef);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.CREF_QUAL(ident = i_ident, subscriptLst = i_subscriptLst, componentRef = i_componentRef) )
      local
        DAE.ComponentRef i_componentRef;
        list<DAE.Subscript> i_subscriptLst;
        DAE.Ident i_ident;
      equation
        txt = Tpl.writeStr(txt, i_ident);
        txt = subscriptsStr(txt, i_subscriptLst);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = crefStr(txt, i_componentRef);
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("CREF_NOT_IDENT_OR_QUAL"));
      then txt;
  end matchcontinue;
end crefStr;

protected function fun_250
  input Tpl.Text in_txt;
  input SimCode.Context in_i_context;
  input DAE.ComponentRef in_i_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_context, in_i_cr)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_cr;

    case ( txt,
           SimCode.FUNCTION_CONTEXT(),
           i_cr )
      equation
        txt = arrayCrefStr(txt, i_cr);
      then txt;

    case ( txt,
           _,
           i_cr )
      equation
        txt = arrayCrefCStr(txt, i_cr);
      then txt;
  end matchcontinue;
end fun_250;

public function contextArrayCref
  input Tpl.Text txt;
  input DAE.ComponentRef i_cr;
  input SimCode.Context i_context;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_250(txt, i_context, i_cr);
end contextArrayCref;

public function arrayCrefCStr
  input Tpl.Text txt;
  input DAE.ComponentRef i_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("$P"));
  out_txt := arrayCrefCStr2(out_txt, i_cr);
end arrayCrefCStr;

public function arrayCrefCStr2
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_i_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_cr)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.CREF_IDENT(ident = i_ident) )
      local
        DAE.Ident i_ident;
      equation
        txt = Tpl.writeStr(txt, i_ident);
      then txt;

    case ( txt,
           DAE.CREF_QUAL(ident = i_ident, componentRef = i_componentRef) )
      local
        DAE.ComponentRef i_componentRef;
        DAE.Ident i_ident;
      equation
        txt = Tpl.writeStr(txt, i_ident);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$P"));
        txt = arrayCrefCStr2(txt, i_componentRef);
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("CREF_NOT_IDENT_OR_QUAL"));
      then txt;
  end matchcontinue;
end arrayCrefCStr2;

public function arrayCrefStr
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_i_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_cr)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.CREF_IDENT(ident = i_ident) )
      local
        DAE.Ident i_ident;
      equation
        txt = Tpl.writeStr(txt, i_ident);
      then txt;

    case ( txt,
           DAE.CREF_QUAL(ident = i_ident, componentRef = i_componentRef) )
      local
        DAE.ComponentRef i_componentRef;
        DAE.Ident i_ident;
      equation
        txt = Tpl.writeStr(txt, i_ident);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = arrayCrefStr(txt, i_componentRef);
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("CREF_NOT_IDENT_OR_QUAL"));
      then txt;
  end matchcontinue;
end arrayCrefStr;

protected function lm_255
  input Tpl.Text in_txt;
  input list<DAE.Subscript> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_s :: rest )
      local
        list<DAE.Subscript> rest;
        DAE.Subscript i_s;
      equation
        txt = subscriptStr(txt, i_s);
        txt = Tpl.nextIter(txt);
        txt = lm_255(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<DAE.Subscript> rest;
      equation
        txt = lm_255(txt, rest);
      then txt;
  end matchcontinue;
end lm_255;

public function subscriptsStr
  input Tpl.Text in_txt;
  input list<DAE.Subscript> in_i_subscripts;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_subscripts)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_subscripts )
      local
        list<DAE.Subscript> i_subscripts;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(",")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_255(txt, i_subscripts);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("]"));
      then txt;
  end matchcontinue;
end subscriptsStr;

protected function fun_257
  input Tpl.Text in_txt;
  input DAE.Subscript in_i_subscript;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_i_subscript, in_i_varDecls, in_i_preExp)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;

    case ( txt,
           DAE.INDEX(exp = i_exp),
           i_varDecls,
           i_preExp )
      local
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_exp, SimCode.contextFunction, i_preExp, i_varDecls);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           DAE.SLICE(exp = i_exp),
           i_varDecls,
           i_preExp )
      local
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_exp, SimCode.contextFunction, i_preExp, i_varDecls);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           DAE.WHOLEDIM(),
           i_varDecls,
           i_preExp )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("WHOLEDIM"));
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _,
           i_varDecls,
           i_preExp )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("UNKNOWN_SUBSCRIPT"));
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_257;

public function subscriptStr
  input Tpl.Text txt;
  input DAE.Subscript i_subscript;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_varDecls;
  Tpl.Text i_preExp;
algorithm
  i_preExp := emptyTxt;
  i_varDecls := emptyTxt;
  (out_txt, i_varDecls, i_preExp) := fun_257(txt, i_subscript, i_varDecls, i_preExp);
end subscriptStr;

public function expCref
  input Tpl.Text in_txt;
  input DAE.Exp in_i_ecr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ecr)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.CREF(componentRef = i_componentRef) )
      local
        DAE.ComponentRef i_componentRef;
      equation
        txt = cref(txt, i_componentRef);
      then txt;

    case ( txt,
           DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {(i_arg as DAE.CREF(componentRef = i_arg_componentRef))}) )
      local
        DAE.ComponentRef i_arg_componentRef;
        DAE.Exp i_arg;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$P$DER"));
        txt = cref(txt, i_arg_componentRef);
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("ERROR_NOT_A_CREF"));
      then txt;
  end matchcontinue;
end expCref;

public function functionName
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_i_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_cr)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.CREF_IDENT(ident = i_ident) )
      local
        DAE.Ident i_ident;
        String ret_0;
      equation
        ret_0 = System.stringReplace(i_ident, "_", "__");
        txt = Tpl.writeStr(txt, ret_0);
      then txt;

    case ( txt,
           DAE.CREF_QUAL(ident = i_ident, componentRef = i_componentRef) )
      local
        DAE.ComponentRef i_componentRef;
        DAE.Ident i_ident;
        String ret_0;
      equation
        ret_0 = System.stringReplace(i_ident, "_", "__");
        txt = Tpl.writeStr(txt, ret_0);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = functionName(txt, i_componentRef);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end functionName;

public function dotPath
  input Tpl.Text in_txt;
  input Absyn.Path in_i_path;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_path)
    local
      Tpl.Text txt;

    case ( txt,
           Absyn.QUALIFIED(name = i_name, path = i_path) )
      local
        Absyn.Path i_path;
        Absyn.Ident i_name;
      equation
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = dotPath(txt, i_path);
      then txt;

    case ( txt,
           Absyn.IDENT(name = i_name) )
      local
        Absyn.Ident i_name;
      equation
        txt = Tpl.writeStr(txt, i_name);
      then txt;

    case ( txt,
           Absyn.FULLYQUALIFIED(path = i_path) )
      local
        Absyn.Path i_path;
      equation
        txt = dotPath(txt, i_path);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end dotPath;

public function replaceDotAndUnderscore
  input Tpl.Text in_txt;
  input String in_i_str;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_str)
    local
      Tpl.Text txt;

    case ( txt,
           i_name )
      local
        String i_name;
        String ret_3;
        Tpl.Text i_str__underscores;
        String ret_1;
        Tpl.Text i_str__dots;
      equation
        ret_1 = System.stringReplace(i_name, ".", "_");
        i_str__dots = Tpl.writeStr(emptyTxt, ret_1);
        ret_3 = System.stringReplace(Tpl.textString(i_str__dots), "_", "__");
        i_str__underscores = Tpl.writeStr(emptyTxt, ret_3);
        txt = Tpl.writeText(txt, i_str__underscores);
      then txt;
  end matchcontinue;
end replaceDotAndUnderscore;

public function underscorePath
  input Tpl.Text in_txt;
  input Absyn.Path in_i_path;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_path)
    local
      Tpl.Text txt;

    case ( txt,
           Absyn.QUALIFIED(name = i_name, path = i_path) )
      local
        Absyn.Path i_path;
        Absyn.Ident i_name;
      equation
        txt = replaceDotAndUnderscore(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = underscorePath(txt, i_path);
      then txt;

    case ( txt,
           Absyn.IDENT(name = i_name) )
      local
        Absyn.Ident i_name;
      equation
        txt = replaceDotAndUnderscore(txt, i_name);
      then txt;

    case ( txt,
           Absyn.FULLYQUALIFIED(path = i_path) )
      local
        Absyn.Path i_path;
      equation
        txt = underscorePath(txt, i_path);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end underscorePath;

protected function lm_264
  input Tpl.Text in_txt;
  input list<String> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_it :: rest )
      local
        list<String> rest;
        String i_it;
      equation
        txt = Tpl.writeStr(txt, i_it);
        txt = Tpl.nextIter(txt);
        txt = lm_264(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<String> rest;
      equation
        txt = lm_264(txt, rest);
      then txt;
  end matchcontinue;
end lm_264;

public function externalFunctionIncludes
  input Tpl.Text in_txt;
  input list<String> in_i_includes;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_includes)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_includes )
      local
        list<String> i_includes;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "#ifdef __cplusplus\n",
                                    "extern \"C\" {\n",
                                    "#endif\n"
                                }, true));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_264(txt, i_includes);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "#ifdef __cplusplus\n",
                                    "}\n",
                                    "#endif"
                                }, false));
      then txt;
  end matchcontinue;
end externalFunctionIncludes;

protected function lm_266
  input Tpl.Text in_txt;
  input list<SimCode.Function> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_fn :: rest )
      local
        list<SimCode.Function> rest;
        SimCode.Function i_fn;
      equation
        txt = functionHeader(txt, i_fn, false);
        txt = Tpl.nextIter(txt);
        txt = lm_266(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Function> rest;
      equation
        txt = lm_266(txt, rest);
      then txt;
  end matchcontinue;
end lm_266;

public function functionHeaders
  input Tpl.Text txt;
  input list<SimCode.Function> i_functions;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_266(out_txt, i_functions);
  out_txt := Tpl.popIter(out_txt);
end functionHeaders;

protected function lm_268
  input Tpl.Text in_txt;
  input list<SimCode.RecordDeclaration> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_rd :: rest )
      local
        list<SimCode.RecordDeclaration> rest;
        SimCode.RecordDeclaration i_rd;
      equation
        txt = recordDeclaration(txt, i_rd);
        txt = Tpl.nextIter(txt);
        txt = lm_268(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.RecordDeclaration> rest;
      equation
        txt = lm_268(txt, rest);
      then txt;
  end matchcontinue;
end lm_268;

protected function lm_269
  input Tpl.Text in_txt;
  input list<SimCode.RecordDeclaration> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_rd :: rest )
      local
        list<SimCode.RecordDeclaration> rest;
        SimCode.RecordDeclaration i_rd;
      equation
        txt = recordDeclaration(txt, i_rd);
        txt = Tpl.nextIter(txt);
        txt = lm_269(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.RecordDeclaration> rest;
      equation
        txt = lm_269(txt, rest);
      then txt;
  end matchcontinue;
end lm_269;

protected function lm_270
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_var as SimCode.VARIABLE(name = i_name)) :: rest )
      local
        list<SimCode.Variable> rest;
        DAE.ComponentRef i_name;
        SimCode.Variable i_var;
      equation
        txt = varType(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = crefStr(txt, i_name);
        txt = Tpl.nextIter(txt);
        txt = lm_270(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_270(txt, rest);
      then txt;
  end matchcontinue;
end lm_270;

protected function lm_271
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
      equation
        txt = funArgBoxedDefinition(txt, i_var);
        txt = Tpl.nextIter(txt);
        txt = lm_271(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_271(txt, rest);
      then txt;
  end matchcontinue;
end lm_271;

protected function fun_272
  input Tpl.Text in_txt;
  input Boolean in_it;
  input list<SimCode.Variable> in_i_funArgs;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it, in_i_funArgs)
    local
      Tpl.Text txt;
      list<SimCode.Variable> i_funArgs;

    case ( txt,
           false,
           _ )
      then txt;

    case ( txt,
           _,
           i_funArgs )
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_271(txt, i_funArgs);
        txt = Tpl.popIter(txt);
      then txt;
  end matchcontinue;
end fun_272;

protected function fun_273
  input Tpl.Text in_txt;
  input Boolean in_it;
  input Tpl.Text in_i_funArgsBoxedStr;
  input Tpl.Text in_i_fname;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it, in_i_funArgsBoxedStr, in_i_fname)
    local
      Tpl.Text txt;
      Tpl.Text i_funArgsBoxedStr;
      Tpl.Text i_fname;

    case ( txt,
           false,
           _,
           _ )
      then txt;

    case ( txt,
           _,
           i_funArgsBoxedStr,
           i_fname )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define "));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "_rettypeboxed_1 targ1\n",
                                    "typedef struct "
                                }, false));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "_rettypeboxed_s {\n",
                                    "  modelica_metatype targ1;\n",
                                    "} "
                                }, false));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "_rettypeboxed;\n",
                                    "\n",
                                    "DLLExport\n"
                                }, true));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_rettypeboxed boxptr_"));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_funArgsBoxedStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;
  end matchcontinue;
end fun_273;

protected function lm_274
  input Tpl.Text in_txt;
  input list<SimCode.RecordDeclaration> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_rd :: rest )
      local
        list<SimCode.RecordDeclaration> rest;
        SimCode.RecordDeclaration i_rd;
      equation
        txt = recordDeclaration(txt, i_rd);
        txt = Tpl.nextIter(txt);
        txt = lm_274(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.RecordDeclaration> rest;
      equation
        txt = lm_274(txt, rest);
      then txt;
  end matchcontinue;
end lm_274;

public function functionHeader
  input Tpl.Text in_txt;
  input SimCode.Function in_i_fn;
  input Boolean in_i_inFunc;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_fn, in_i_inFunc)
    local
      Tpl.Text txt;
      Boolean i_inFunc;

    case ( txt,
           SimCode.FUNCTION(recordDecls = i_recordDecls, name = i_name, functionArguments = i_functionArguments, outVars = i_outVars),
           i_inFunc )
      local
        list<SimCode.Variable> i_outVars;
        list<SimCode.Variable> i_functionArguments;
        Absyn.Path i_name;
        list<SimCode.RecordDeclaration> i_recordDecls;
        Tpl.Text txt_1;
        Tpl.Text txt_0;
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_268(txt, i_recordDecls);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt_0 = underscorePath(emptyTxt, i_name);
        txt = functionHeaderNormal(txt, Tpl.textString(txt_0), i_functionArguments, i_outVars, i_inFunc);
        txt = Tpl.softNewLine(txt);
        txt_1 = underscorePath(emptyTxt, i_name);
        txt = functionHeaderBoxed(txt, Tpl.textString(txt_1), i_functionArguments, i_outVars);
      then txt;

    case ( txt,
           (i_fn as SimCode.EXTERNAL_FUNCTION(recordDecls = i_recordDecls, name = i_name, funArgs = i_funArgs, outVars = i_outVars)),
           i_inFunc )
      local
        list<SimCode.Variable> i_outVars;
        list<SimCode.Variable> i_funArgs;
        Absyn.Path i_name;
        list<SimCode.RecordDeclaration> i_recordDecls;
        SimCode.Function i_fn;
        Tpl.Text txt_1;
        Tpl.Text txt_0;
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_269(txt, i_recordDecls);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt_0 = underscorePath(emptyTxt, i_name);
        txt = functionHeaderNormal(txt, Tpl.textString(txt_0), i_funArgs, i_outVars, i_inFunc);
        txt = Tpl.softNewLine(txt);
        txt_1 = underscorePath(emptyTxt, i_name);
        txt = functionHeaderBoxed(txt, Tpl.textString(txt_1), i_funArgs, i_outVars);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = extFunDef(txt, i_fn);
      then txt;

    case ( txt,
           SimCode.RECORD_CONSTRUCTOR(name = i_name, funArgs = i_funArgs, recordDecls = i_recordDecls),
           _ )
      local
        list<SimCode.RecordDeclaration> i_recordDecls;
        list<SimCode.Variable> i_funArgs;
        Absyn.Path i_name;
        Boolean ret_5;
        Tpl.Text i_boxedHeader;
        Boolean ret_3;
        Tpl.Text i_funArgsBoxedStr;
        Tpl.Text i_funArgsStr;
        Tpl.Text i_fname;
      equation
        i_fname = underscorePath(emptyTxt, i_name);
        i_funArgsStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        i_funArgsStr = lm_270(i_funArgsStr, i_funArgs);
        i_funArgsStr = Tpl.popIter(i_funArgsStr);
        ret_3 = RTOpts.acceptMetaModelicaGrammar();
        i_funArgsBoxedStr = fun_272(emptyTxt, ret_3, i_funArgs);
        ret_5 = RTOpts.acceptMetaModelicaGrammar();
        i_boxedHeader = fun_273(emptyTxt, ret_5, i_funArgsBoxedStr, i_fname);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_274(txt, i_recordDecls);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define "));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "_rettype_1 targ1\n",
                                    "typedef struct "
                                }, false));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("_rettype_s {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("struct "));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" targ1;\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("} "));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "_rettype;\n",
                                    "\n",
                                    "DLLExport\n"
                                }, true));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_rettype _"));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_funArgsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\n",
                                    "\n"
                                }, true));
        txt = Tpl.writeText(txt, i_boxedHeader);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end functionHeader;

protected function lm_276
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_var as SimCode.VARIABLE(name = i_var_name)) :: rest )
      local
        list<SimCode.Variable> rest;
        DAE.ComponentRef i_var_name;
        SimCode.Variable i_var;
      equation
        txt = varType(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = crefStr(txt, i_var_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_276(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_276(txt, rest);
      then txt;
  end matchcontinue;
end lm_276;

protected function lm_277
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.VARIABLE(name = i_name) :: rest )
      local
        list<SimCode.Variable> rest;
        DAE.ComponentRef i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = Tpl.nextIter(txt);
        txt = lm_277(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_277(txt, rest);
      then txt;
  end matchcontinue;
end lm_277;

protected function lm_278
  input Tpl.Text in_txt;
  input list<String> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_name :: rest )
      local
        list<String> rest;
        String i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = Tpl.nextIter(txt);
        txt = lm_278(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<String> rest;
      equation
        txt = lm_278(txt, rest);
      then txt;
  end matchcontinue;
end lm_278;

public function recordDeclaration
  input Tpl.Text in_txt;
  input SimCode.RecordDeclaration in_i_recDecl;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_recDecl)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.RECORD_DECL_FULL(name = i_name, variables = i_variables, defPath = i_defPath) )
      local
        Absyn.Path i_defPath;
        list<SimCode.Variable> i_variables;
        String i_name;
        Tpl.Text txt_2;
        Tpl.Text txt_1;
        Tpl.Text txt_0;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("struct "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_276(txt, i_variables);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("};\n"));
        txt_0 = dotPath(emptyTxt, i_defPath);
        txt_1 = underscorePath(emptyTxt, i_defPath);
        txt_2 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(",")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_2 = lm_277(txt_2, i_variables);
        txt_2 = Tpl.popIter(txt_2);
        txt = recordDefinition(txt, Tpl.textString(txt_0), Tpl.textString(txt_1), Tpl.textString(txt_2));
      then txt;

    case ( txt,
           SimCode.RECORD_DECL_DEF(path = i_path, fieldNames = i_fieldNames) )
      local
        list<String> i_fieldNames;
        Absyn.Path i_path;
        Tpl.Text txt_2;
        Tpl.Text txt_1;
        Tpl.Text txt_0;
      equation
        txt_0 = dotPath(emptyTxt, i_path);
        txt_1 = underscorePath(emptyTxt, i_path);
        txt_2 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(",")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_2 = lm_278(txt_2, i_fieldNames);
        txt_2 = Tpl.popIter(txt_2);
        txt = recordDefinition(txt, Tpl.textString(txt_0), Tpl.textString(txt_1), Tpl.textString(txt_2));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end recordDeclaration;

public function recordDefinition
  input Tpl.Text txt;
  input String i_origName;
  input String i_encName;
  input String i_fieldNames;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("const char* "));
  out_txt := Tpl.writeStr(out_txt, i_encName);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("__desc__fields[] = {"));
  out_txt := Tpl.writeStr(out_txt, i_fieldNames);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "};\n",
                                       "struct record_description "
                                   }, false));
  out_txt := Tpl.writeStr(out_txt, i_encName);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE("__desc = {\n"));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("\""));
  out_txt := Tpl.writeStr(out_txt, i_encName);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\", /* package_record__X */\n",
                                       "\""
                                   }, false));
  out_txt := Tpl.writeStr(out_txt, i_origName);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE("\", /* package.record_X */\n"));
  out_txt := Tpl.writeStr(out_txt, i_encName);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE("__desc__fields\n"));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("};"));
end recordDefinition;

public function functionHeaderNormal
  input Tpl.Text txt;
  input String i_fname;
  input list<SimCode.Variable> i_fargs;
  input list<SimCode.Variable> i_outVars;
  input Boolean i_inFunc;

  output Tpl.Text out_txt;
algorithm
  out_txt := functionHeaderImpl(txt, i_fname, i_fargs, i_outVars, i_inFunc, false);
end functionHeaderNormal;

protected function fun_282
  input Tpl.Text in_txt;
  input Boolean in_it;
  input String in_i_fname;
  input list<SimCode.Variable> in_i_fargs;
  input list<SimCode.Variable> in_i_outVars;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it, in_i_fname, in_i_fargs, in_i_outVars)
    local
      Tpl.Text txt;
      String i_fname;
      list<SimCode.Variable> i_fargs;
      list<SimCode.Variable> i_outVars;

    case ( txt,
           false,
           _,
           _,
           _ )
      then txt;

    case ( txt,
           _,
           i_fname,
           i_fargs,
           i_outVars )
      equation
        txt = functionHeaderImpl(txt, i_fname, i_fargs, i_outVars, false, true);
      then txt;
  end matchcontinue;
end fun_282;

public function functionHeaderBoxed
  input Tpl.Text txt;
  input String i_fname;
  input list<SimCode.Variable> i_fargs;
  input list<SimCode.Variable> i_outVars;

  output Tpl.Text out_txt;
protected
  Boolean ret_0;
algorithm
  ret_0 := RTOpts.acceptMetaModelicaGrammar();
  out_txt := fun_282(txt, ret_0, i_fname, i_fargs, i_outVars);
end functionHeaderBoxed;

protected function lm_284
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
      equation
        txt = funArgDefinition(txt, i_var);
        txt = Tpl.nextIter(txt);
        txt = lm_284(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_284(txt, rest);
      then txt;
  end matchcontinue;
end lm_284;

protected function lm_285
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
      equation
        txt = funArgBoxedDefinition(txt, i_var);
        txt = Tpl.nextIter(txt);
        txt = lm_285(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_285(txt, rest);
      then txt;
  end matchcontinue;
end lm_285;

protected function fun_286
  input Tpl.Text in_txt;
  input Boolean in_i_boxed;
  input list<SimCode.Variable> in_i_fargs;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_boxed, in_i_fargs)
    local
      Tpl.Text txt;
      list<SimCode.Variable> i_fargs;

    case ( txt,
           false,
           i_fargs )
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_284(txt, i_fargs);
        txt = Tpl.popIter(txt);
      then txt;

    case ( txt,
           _,
           i_fargs )
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_285(txt, i_fargs);
        txt = Tpl.popIter(txt);
      then txt;
  end matchcontinue;
end fun_286;

protected function fun_287
  input Tpl.Text in_txt;
  input Boolean in_i_boxed;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_boxed)
    local
      Tpl.Text txt;

    case ( txt,
           false )
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("boxed"));
      then txt;
  end matchcontinue;
end fun_287;

protected function fun_288
  input Tpl.Text in_txt;
  input Boolean in_i_boxed;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_boxed)
    local
      Tpl.Text txt;

    case ( txt,
           false )
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("boxptr"));
      then txt;
  end matchcontinue;
end fun_288;

protected function fun_289
  input Tpl.Text in_txt;
  input Boolean in_i_inFunc;
  input String in_i_fname;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_inFunc, in_i_fname)
    local
      Tpl.Text txt;
      String i_fname;

    case ( txt,
           false,
           _ )
      then txt;

    case ( txt,
           _,
           i_fname )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "DLLExport\n",
                                    "int in_"
                                }, false));
        txt = Tpl.writeStr(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(type_description * inArgs, type_description * outVar);"));
      then txt;
  end matchcontinue;
end fun_289;

protected function fun_290
  input Tpl.Text in_txt;
  input Boolean in_i_boxed;
  input String in_i_fname;
  input Boolean in_i_inFunc;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_boxed, in_i_fname, in_i_inFunc)
    local
      Tpl.Text txt;
      String i_fname;
      Boolean i_inFunc;

    case ( txt,
           false,
           i_fname,
           i_inFunc )
      equation
        txt = fun_289(txt, i_inFunc, i_fname);
      then txt;

    case ( txt,
           _,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_290;

protected function lm_291
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_i_boxStr;
  input String in_i_fname;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items, in_i_boxStr, in_i_fname)
    local
      Tpl.Text txt;
      Tpl.Text i_boxStr;
      String i_fname;

    case ( txt,
           {},
           _,
           _ )
      then txt;

    case ( txt,
           SimCode.VARIABLE(name = _) :: rest,
           i_boxStr,
           i_fname )
      local
        list<SimCode.Variable> rest;
        Integer i_i1;
      equation
        i_i1 = Tpl.getIteri_i1(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define "));
        txt = Tpl.writeStr(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_rettype"));
        txt = Tpl.writeText(txt, i_boxStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = Tpl.writeStr(txt, intString(i_i1));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" targ"));
        txt = Tpl.writeStr(txt, intString(i_i1));
        txt = Tpl.nextIter(txt);
        txt = lm_291(txt, rest, i_boxStr, i_fname);
      then txt;

    case ( txt,
           _ :: rest,
           i_boxStr,
           i_fname )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_291(txt, rest, i_boxStr, i_fname);
      then txt;
  end matchcontinue;
end lm_291;

protected function lm_292
  input Tpl.Text in_txt;
  input list<DAE.Dimension> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_dim :: rest )
      local
        list<DAE.Dimension> rest;
        DAE.Dimension i_dim;
      equation
        txt = dimension(txt, i_dim);
        txt = Tpl.nextIter(txt);
        txt = lm_292(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<DAE.Dimension> rest;
      equation
        txt = lm_292(txt, rest);
      then txt;
  end matchcontinue;
end lm_292;

protected function fun_293
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(arrayDimensions = i_arrayDimensions) )
      local
        list<DAE.Dimension> i_arrayDimensions;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_292(txt, i_arrayDimensions);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("]"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_293;

protected function fun_294
  input Tpl.Text in_txt;
  input Boolean in_i_boxed;
  input SimCode.Variable in_i_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_boxed, in_i_var)
    local
      Tpl.Text txt;
      SimCode.Variable i_var;

    case ( txt,
           false,
           i_var )
      equation
        txt = varType(txt, i_var);
      then txt;

    case ( txt,
           _,
           i_var )
      equation
        txt = varTypeBoxed(txt, i_var);
      then txt;
  end matchcontinue;
end fun_294;

protected function lm_295
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Boolean in_i_boxed;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items, in_i_boxed)
    local
      Tpl.Text txt;
      Boolean i_boxed;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           (i_var as SimCode.VARIABLE(ty = i_ty, name = i_name)) :: rest,
           i_boxed )
      local
        list<SimCode.Variable> rest;
        DAE.ComponentRef i_name;
        DAE.ExpType i_ty;
        SimCode.Variable i_var;
        Integer i_i1;
        Tpl.Text i_typeStr;
        Tpl.Text i_dimStr;
      equation
        i_i1 = Tpl.getIteri_i1(txt);
        i_dimStr = fun_293(emptyTxt, i_ty);
        i_typeStr = fun_294(emptyTxt, i_boxed, i_var);
        txt = Tpl.writeText(txt, i_typeStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" targ"));
        txt = Tpl.writeStr(txt, intString(i_i1));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("; /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeText(txt, i_dimStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_295(txt, rest, i_boxed);
      then txt;

    case ( txt,
           _ :: rest,
           i_boxed )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_295(txt, rest, i_boxed);
      then txt;
  end matchcontinue;
end lm_295;

protected function fun_296
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_i_outVars;
  input Tpl.Text in_i_inFnStr;
  input Boolean in_i_boxed;
  input Tpl.Text in_i_boxStr;
  input Tpl.Text in_i_fargsStr;
  input String in_i_fname;
  input Tpl.Text in_i_boxPtrStr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_outVars, in_i_inFnStr, in_i_boxed, in_i_boxStr, in_i_fargsStr, in_i_fname, in_i_boxPtrStr)
    local
      Tpl.Text txt;
      Tpl.Text i_inFnStr;
      Boolean i_boxed;
      Tpl.Text i_boxStr;
      Tpl.Text i_fargsStr;
      String i_fname;
      Tpl.Text i_boxPtrStr;

    case ( txt,
           {},
           _,
           _,
           _,
           i_fargsStr,
           i_fname,
           i_boxPtrStr )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "DLLExport\n",
                                    "void "
                                }, false));
        txt = Tpl.writeText(txt, i_boxPtrStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = Tpl.writeStr(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_fargsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           i_outVars,
           i_inFnStr,
           i_boxed,
           i_boxStr,
           i_fargsStr,
           i_fname,
           i_boxPtrStr )
      local
        list<SimCode.Variable> i_outVars;
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_291(txt, i_outVars, i_boxStr, i_fname);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("typedef struct "));
        txt = Tpl.writeStr(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_rettype"));
        txt = Tpl.writeText(txt, i_boxStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "_s\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_295(txt, i_outVars, i_boxed);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("} "));
        txt = Tpl.writeStr(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_rettype"));
        txt = Tpl.writeText(txt, i_boxStr);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        txt = Tpl.writeText(txt, i_inFnStr);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "DLLExport\n"
                                }, true));
        txt = Tpl.writeStr(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_rettype"));
        txt = Tpl.writeText(txt, i_boxStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = Tpl.writeText(txt, i_boxPtrStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = Tpl.writeStr(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_fargsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;
  end matchcontinue;
end fun_296;

public function functionHeaderImpl
  input Tpl.Text txt;
  input String i_fname;
  input list<SimCode.Variable> i_fargs;
  input list<SimCode.Variable> i_outVars;
  input Boolean i_inFunc;
  input Boolean i_boxed;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_inFnStr;
  Tpl.Text i_boxPtrStr;
  Tpl.Text i_boxStr;
  Tpl.Text i_fargsStr;
algorithm
  i_fargsStr := fun_286(emptyTxt, i_boxed, i_fargs);
  i_boxStr := fun_287(emptyTxt, i_boxed);
  i_boxPtrStr := fun_288(emptyTxt, i_boxed);
  i_inFnStr := fun_290(emptyTxt, i_boxed, i_fname, i_inFunc);
  out_txt := fun_296(txt, i_outVars, i_inFnStr, i_boxed, i_boxStr, i_fargsStr, i_fname, i_boxPtrStr);
end functionHeaderImpl;

public function funArgName
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_var)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.VARIABLE(name = i_name) )
      local
        DAE.ComponentRef i_name;
      equation
        txt = crefStr(txt, i_name);
      then txt;

    case ( txt,
           SimCode.FUNCTION_PTR(name = i_name) )
      local
        String i_name;
      equation
        txt = Tpl.writeStr(txt, i_name);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end funArgName;

public function funArgDefinition
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_var)
    local
      Tpl.Text txt;

    case ( txt,
           (i_var as SimCode.VARIABLE(name = i_name)) )
      local
        DAE.ComponentRef i_name;
        SimCode.Variable i_var;
      equation
        txt = varType(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = crefStr(txt, i_name);
      then txt;

    case ( txt,
           SimCode.FUNCTION_PTR(name = i_name) )
      local
        String i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_fnptr "));
        txt = Tpl.writeStr(txt, i_name);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end funArgDefinition;

public function funArgBoxedDefinition
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_var)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.VARIABLE(name = i_name) )
      local
        DAE.ComponentRef i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_metatype "));
        txt = crefStr(txt, i_name);
      then txt;

    case ( txt,
           SimCode.FUNCTION_PTR(name = i_name) )
      local
        String i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_fnptr "));
        txt = Tpl.writeStr(txt, i_name);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end funArgBoxedDefinition;

public function extFunDef
  input Tpl.Text in_txt;
  input SimCode.Function in_i_fn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_fn)
    local
      Tpl.Text txt;

    case ( txt,
           (i_func as SimCode.EXTERNAL_FUNCTION(extName = i_extName, language = i_language, extArgs = i_extArgs, extReturn = i_extReturn)) )
      local
        SimCode.SimExtArg i_extReturn;
        list<SimCode.SimExtArg> i_extArgs;
        String i_language;
        String i_extName;
        SimCode.Function i_func;
        Tpl.Text i_fargsStr;
        Tpl.Text i_fn__name;
      equation
        i_fn__name = extFunctionName(emptyTxt, i_extName, i_language);
        i_fargsStr = extFunDefArgs(emptyTxt, i_extArgs, i_language);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("extern "));
        txt = extReturnType(txt, i_extReturn);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = Tpl.writeText(txt, i_fn__name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_fargsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end extFunDef;

protected function fun_302
  input Tpl.Text in_txt;
  input String in_i_language;
  input String in_i_name;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_language, in_i_name)
    local
      Tpl.Text txt;
      String i_name;

    case ( txt,
           "C",
           i_name )
      equation
        txt = Tpl.writeStr(txt, i_name);
      then txt;

    case ( txt,
           "FORTRAN 77",
           i_name )
      equation
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
      then txt;

    case ( txt,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("UNSUPPORTED_LANGUAGE"));
      then txt;
  end matchcontinue;
end fun_302;

public function extFunctionName
  input Tpl.Text txt;
  input String i_name;
  input String i_language;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_302(txt, i_language, i_name);
end extFunctionName;

protected function lm_304
  input Tpl.Text in_txt;
  input list<SimCode.SimExtArg> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_arg :: rest )
      local
        list<SimCode.SimExtArg> rest;
        SimCode.SimExtArg i_arg;
      equation
        txt = extFunDefArg(txt, i_arg);
        txt = Tpl.nextIter(txt);
        txt = lm_304(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimExtArg> rest;
      equation
        txt = lm_304(txt, rest);
      then txt;
  end matchcontinue;
end lm_304;

protected function lm_305
  input Tpl.Text in_txt;
  input list<SimCode.SimExtArg> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_arg :: rest )
      local
        list<SimCode.SimExtArg> rest;
        SimCode.SimExtArg i_arg;
      equation
        txt = extFunDefArgF77(txt, i_arg);
        txt = Tpl.nextIter(txt);
        txt = lm_305(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimExtArg> rest;
      equation
        txt = lm_305(txt, rest);
      then txt;
  end matchcontinue;
end lm_305;

protected function fun_306
  input Tpl.Text in_txt;
  input String in_i_language;
  input list<SimCode.SimExtArg> in_i_args;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_language, in_i_args)
    local
      Tpl.Text txt;
      list<SimCode.SimExtArg> i_args;

    case ( txt,
           "C",
           i_args )
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_304(txt, i_args);
        txt = Tpl.popIter(txt);
      then txt;

    case ( txt,
           "FORTRAN 77",
           i_args )
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_305(txt, i_args);
        txt = Tpl.popIter(txt);
      then txt;

    case ( txt,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("UNSUPPORTED_LANGUAGE"));
      then txt;
  end matchcontinue;
end fun_306;

public function extFunDefArgs
  input Tpl.Text txt;
  input list<SimCode.SimExtArg> i_args;
  input String i_language;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_306(txt, i_language, i_args);
end extFunDefArgs;

public function extReturnType
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_extArg;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_extArg)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMEXTARG(type_ = i_type__) )
      local
        DAE.ExpType i_type__;
      equation
        txt = extType(txt, i_type__);
      then txt;

    case ( txt,
           SimCode.SIMNOEXTARG() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end extReturnType;

public function extType
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_INT() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("int"));
      then txt;

    case ( txt,
           DAE.ET_REAL() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("double"));
      then txt;

    case ( txt,
           DAE.ET_STRING() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("const char*"));
      then txt;

    case ( txt,
           DAE.ET_BOOL() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("int"));
      then txt;

    case ( txt,
           DAE.ET_ARRAY(ty = i_ty) )
      local
        DAE.ExpType i_ty;
      equation
        txt = extType(txt, i_ty);
      then txt;

    case ( txt,
           DAE.ET_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path = _)) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void *"));
      then txt;

    case ( txt,
           DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(path = i_rname)) )
      local
        Absyn.Path i_rname;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("struct "));
        txt = underscorePath(txt, i_rname);
      then txt;

    case ( txt,
           DAE.ET_METAOPTION(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void*"));
      then txt;

    case ( txt,
           DAE.ET_LIST(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void*"));
      then txt;

    case ( txt,
           DAE.ET_METATUPLE(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void*"));
      then txt;

    case ( txt,
           DAE.ET_UNIONTYPE() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void*"));
      then txt;

    case ( txt,
           DAE.ET_POLYMORPHIC() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void*"));
      then txt;

    case ( txt,
           DAE.ET_META_ARRAY(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void*"));
      then txt;

    case ( txt,
           DAE.ET_BOXED(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void*"));
      then txt;

    case ( txt,
           DAE.ET_ENUMERATION(path = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("int"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("OTHER_EXT_TYPE"));
      then txt;
  end matchcontinue;
end extType;

protected function fun_310
  input Tpl.Text in_txt;
  input String in_it;
  input DAE.ExpType in_i_t;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it, in_i_t)
    local
      Tpl.Text txt;
      DAE.ExpType i_t;

    case ( txt,
           "const char*",
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("const char* const *"));
      then txt;

    case ( txt,
           _,
           i_t )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("const "));
        txt = extType(txt, i_t);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" *"));
      then txt;
  end matchcontinue;
end fun_310;

protected function fun_311
  input Tpl.Text in_txt;
  input Boolean in_i_ia;
  input DAE.ExpType in_i_t;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ia, in_i_t)
    local
      Tpl.Text txt;
      DAE.ExpType i_t;

    case ( txt,
           false,
           i_t )
      equation
        txt = extType(txt, i_t);
      then txt;

    case ( txt,
           _,
           i_t )
      local
        String str_1;
        Tpl.Text txt_0;
      equation
        txt_0 = extType(emptyTxt, i_t);
        str_1 = Tpl.textString(txt_0);
        txt = fun_310(txt, str_1, i_t);
      then txt;
  end matchcontinue;
end fun_311;

protected function fun_312
  input Tpl.Text in_txt;
  input Boolean in_i_ii;
  input Boolean in_i_ia;
  input DAE.ExpType in_i_t;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ii, in_i_ia, in_i_t)
    local
      Tpl.Text txt;
      Boolean i_ia;
      DAE.ExpType i_t;

    case ( txt,
           false,
           _,
           i_t )
      equation
        txt = extType(txt, i_t);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("*"));
      then txt;

    case ( txt,
           _,
           i_ia,
           i_t )
      equation
        txt = fun_311(txt, i_ia, i_t);
      then txt;
  end matchcontinue;
end fun_312;

public function extFunDefArg
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_extArg;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_extArg)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMEXTARG(cref = i_c, isInput = i_ii, isArray = i_ia, type_ = i_t) )
      local
        DAE.ExpType i_t;
        Boolean i_ia;
        Boolean i_ii;
        DAE.ComponentRef i_c;
        Tpl.Text i_typeStr;
        Tpl.Text i_name;
      equation
        i_name = crefStr(emptyTxt, i_c);
        i_typeStr = fun_312(emptyTxt, i_ii, i_ia, i_t);
        txt = Tpl.writeText(txt, i_typeStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = Tpl.writeText(txt, i_name);
      then txt;

    case ( txt,
           SimCode.SIMEXTARGEXP(type_ = i_type__) )
      local
        DAE.ExpType i_type__;
        Tpl.Text i_typeStr;
      equation
        i_typeStr = extType(emptyTxt, i_type__);
        txt = Tpl.writeText(txt, i_typeStr);
      then txt;

    case ( txt,
           SimCode.SIMEXTARGSIZE(cref = i_c, exp = i_exp) )
      local
        DAE.Exp i_exp;
        DAE.ComponentRef i_c;
        Tpl.Text i_eStr;
        Tpl.Text i_name;
      equation
        i_name = crefStr(emptyTxt, i_c);
        i_eStr = daeExpToString(emptyTxt, i_exp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("size_t "));
        txt = Tpl.writeText(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = Tpl.writeText(txt, i_eStr);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end extFunDefArg;

public function extFunDefArgF77
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_extArg;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_extArg)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMEXTARG(cref = i_c, isInput = true, type_ = i_t) )
      local
        DAE.ExpType i_t;
        DAE.ComponentRef i_c;
        Tpl.Text i_typeStr;
        Tpl.Text i_name;
      equation
        i_name = crefStr(emptyTxt, i_c);
        i_typeStr = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("const "));
        i_typeStr = extType(i_typeStr, i_t);
        i_typeStr = Tpl.writeTok(i_typeStr, Tpl.ST_STRING(" *"));
        txt = Tpl.writeText(txt, i_typeStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = Tpl.writeText(txt, i_name);
      then txt;

    case ( txt,
           (i_extArg as SimCode.SIMEXTARG(cref = _)) )
      local
        SimCode.SimExtArg i_extArg;
      equation
        txt = extFunDefArg(txt, i_extArg);
      then txt;

    case ( txt,
           (i_extArg as SimCode.SIMEXTARGEXP(exp = _)) )
      local
        SimCode.SimExtArg i_extArg;
      equation
        txt = extFunDefArg(txt, i_extArg);
      then txt;

    case ( txt,
           SimCode.SIMEXTARGSIZE(cref = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("int const *"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end extFunDefArgF77;

public function daeExpToString
  input Tpl.Text txt;
  input DAE.Exp i_exp;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_varDecls;
  Tpl.Text i_preExp;
algorithm
  i_preExp := emptyTxt;
  i_varDecls := emptyTxt;
  (out_txt, i_preExp, i_varDecls) := daeExp(txt, i_exp, SimCode.contextFunction, i_preExp, i_varDecls);
end daeExpToString;

protected function lm_316
  input Tpl.Text in_txt;
  input list<SimCode.Function> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_fn :: rest )
      local
        list<SimCode.Function> rest;
        SimCode.Function i_fn;
      equation
        txt = functionBody(txt, i_fn, false);
        txt = Tpl.nextIter(txt);
        txt = lm_316(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Function> rest;
      equation
        txt = lm_316(txt, rest);
      then txt;
  end matchcontinue;
end lm_316;

public function functionBodies
  input Tpl.Text txt;
  input list<SimCode.Function> i_functions;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_316(out_txt, i_functions);
  out_txt := Tpl.popIter(out_txt);
end functionBodies;

public function functionBody
  input Tpl.Text in_txt;
  input SimCode.Function in_i_fn;
  input Boolean in_i_inFunc;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_fn, in_i_inFunc)
    local
      Tpl.Text txt;
      Boolean i_inFunc;

    case ( txt,
           (i_fn as SimCode.FUNCTION(name = _)),
           i_inFunc )
      local
        SimCode.Function i_fn;
      equation
        txt = functionBodyRegularFunction(txt, i_fn, i_inFunc);
      then txt;

    case ( txt,
           (i_fn as SimCode.EXTERNAL_FUNCTION(name = _)),
           i_inFunc )
      local
        SimCode.Function i_fn;
      equation
        txt = functionBodyExternalFunction(txt, i_fn, i_inFunc);
      then txt;

    case ( txt,
           (i_fn as SimCode.RECORD_CONSTRUCTOR(name = _)),
           _ )
      local
        SimCode.Function i_fn;
      equation
        txt = functionBodyRecordConstructor(txt, i_fn);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end functionBody;

protected function fun_319
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_i_outVars;
  input Tpl.Text in_i_fname;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_outVars, in_i_fname)
    local
      Tpl.Text txt;
      Tpl.Text i_fname;

    case ( txt,
           {},
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void"));
      then txt;

    case ( txt,
           _,
           i_fname )
      equation
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_rettype"));
      then txt;
  end matchcontinue;
end fun_319;

protected function fun_320
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_i_outVars;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_retType;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_outVars, in_i_varDecls, in_i_retType)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_retType;

    case ( txt,
           {},
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls,
           i_retType )
      equation
        (txt, i_varDecls) = tempDecl(txt, Tpl.textString(i_retType), i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end fun_320;

protected function lm_321
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_i_varInits;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varInits;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varInits, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varInits, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varInits;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varInits,
           i_varDecls )
      then (txt, i_varInits, i_varDecls);

    case ( txt,
           i_var :: rest,
           i_varInits,
           i_varDecls )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
        Integer i_i1;
      equation
        i_i1 = Tpl.getIteri_i1(txt);
        (txt, i_varDecls, i_varInits) = varInit(txt, i_var, "", i_i1, i_varDecls, i_varInits);
        txt = Tpl.nextIter(txt);
        (txt, i_varInits, i_varDecls) = lm_321(txt, rest, i_varInits, i_varDecls);
      then (txt, i_varInits, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varInits,
           i_varDecls )
      local
        list<SimCode.Variable> rest;
      equation
        (txt, i_varInits, i_varDecls) = lm_321(txt, rest, i_varInits, i_varDecls);
      then (txt, i_varInits, i_varDecls);
  end matchcontinue;
end lm_321;

protected function lm_322
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_i_varInits;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varInits;
algorithm
  (out_txt, out_i_varInits) :=
  matchcontinue(in_txt, in_items, in_i_varInits)
    local
      Tpl.Text txt;
      Tpl.Text i_varInits;

    case ( txt,
           {},
           i_varInits )
      then (txt, i_varInits);

    case ( txt,
           i_var :: rest,
           i_varInits )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
      equation
        (txt, i_varInits) = functionArg(txt, i_var, i_varInits);
        txt = Tpl.nextIter(txt);
        (txt, i_varInits) = lm_322(txt, rest, i_varInits);
      then (txt, i_varInits);

    case ( txt,
           _ :: rest,
           i_varInits )
      local
        list<SimCode.Variable> rest;
      equation
        (txt, i_varInits) = lm_322(txt, rest, i_varInits);
      then (txt, i_varInits);
  end matchcontinue;
end lm_322;

protected function lm_323
  input Tpl.Text in_txt;
  input list<SimCode.Statement> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls )
      local
        list<SimCode.Statement> rest;
        SimCode.Statement i_stmt;
      equation
        (txt, i_varDecls) = funStatement(txt, i_stmt, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_323(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.Statement> rest;
      equation
        (txt, i_varDecls) = lm_323(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_323;

protected function lm_324
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_i_outVarInits;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_retVar;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_outVarInits;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_outVarInits, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_outVarInits, in_i_varDecls, in_i_retVar)
    local
      Tpl.Text txt;
      Tpl.Text i_outVarInits;
      Tpl.Text i_varDecls;
      Tpl.Text i_retVar;

    case ( txt,
           {},
           i_outVarInits,
           i_varDecls,
           _ )
      then (txt, i_outVarInits, i_varDecls);

    case ( txt,
           i_var :: rest,
           i_outVarInits,
           i_varDecls,
           i_retVar )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
        Integer i_i1;
      equation
        i_i1 = Tpl.getIteri_i1(txt);
        (txt, i_varDecls, i_outVarInits) = varOutput(txt, i_var, Tpl.textString(i_retVar), i_i1, i_varDecls, i_outVarInits);
        txt = Tpl.nextIter(txt);
        (txt, i_outVarInits, i_varDecls) = lm_324(txt, rest, i_outVarInits, i_varDecls, i_retVar);
      then (txt, i_outVarInits, i_varDecls);

    case ( txt,
           _ :: rest,
           i_outVarInits,
           i_varDecls,
           i_retVar )
      local
        list<SimCode.Variable> rest;
      equation
        (txt, i_outVarInits, i_varDecls) = lm_324(txt, rest, i_outVarInits, i_varDecls, i_retVar);
      then (txt, i_outVarInits, i_varDecls);
  end matchcontinue;
end lm_324;

protected function fun_325
  input Tpl.Text in_txt;
  input Boolean in_it;
  input SimCode.Function in_i_fn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it, in_i_fn)
    local
      Tpl.Text txt;
      SimCode.Function i_fn;

    case ( txt,
           false,
           _ )
      then txt;

    case ( txt,
           _,
           i_fn )
      equation
        txt = functionBodyBoxed(txt, i_fn);
      then txt;
  end matchcontinue;
end fun_325;

protected function lm_326
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
      equation
        txt = funArgDefinition(txt, i_var);
        txt = Tpl.nextIter(txt);
        txt = lm_326(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_326(txt, rest);
      then txt;
  end matchcontinue;
end lm_326;

protected function fun_327
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_i_outVars;
  input Tpl.Text in_i_retVar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_outVars, in_i_retVar)
    local
      Tpl.Text txt;
      Tpl.Text i_retVar;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           _,
           i_retVar )
      equation
        txt = Tpl.writeText(txt, i_retVar);
      then txt;
  end matchcontinue;
end fun_327;

protected function lm_328
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
      equation
        txt = funArgDefinition(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_328(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_328(txt, rest);
      then txt;
  end matchcontinue;
end lm_328;

protected function fun_329
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_i_outVars;
  input Tpl.Text in_i_retType;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_outVars, in_i_retType)
    local
      Tpl.Text txt;
      Tpl.Text i_retType;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           _,
           i_retType )
      equation
        txt = Tpl.writeText(txt, i_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" out;"));
      then txt;
  end matchcontinue;
end fun_329;

protected function lm_330
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_arg :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_arg;
      equation
        txt = readInVar(txt, i_arg);
        txt = Tpl.nextIter(txt);
        txt = lm_330(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_330(txt, rest);
      then txt;
  end matchcontinue;
end lm_330;

protected function fun_331
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_i_outVars;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_outVars)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("out = "));
      then txt;
  end matchcontinue;
end fun_331;

protected function lm_332
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
      equation
        txt = funArgName(txt, i_var);
        txt = Tpl.nextIter(txt);
        txt = lm_332(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_332(txt, rest);
      then txt;
  end matchcontinue;
end lm_332;

protected function lm_333
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
        Integer i_i1;
      equation
        i_i1 = Tpl.getIteri_i1(txt);
        txt = writeOutVar(txt, i_var, i_i1);
        txt = Tpl.nextIter(txt);
        txt = lm_333(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_333(txt, rest);
      then txt;
  end matchcontinue;
end lm_333;

protected function fun_334
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_i_outVars;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_outVars)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("write_noretcall(outVar);"));
      then txt;

    case ( txt,
           i_outVars )
      local
        list<SimCode.Variable> i_outVars;
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_333(txt, i_outVars);
        txt = Tpl.popIter(txt);
      then txt;
  end matchcontinue;
end fun_334;

protected function fun_335
  input Tpl.Text in_txt;
  input Boolean in_i_inFunc;
  input Tpl.Text in_i_retType;
  input list<SimCode.Variable> in_i_outVars;
  input list<SimCode.Variable> in_i_functionArguments;
  input Tpl.Text in_i_fname;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_inFunc, in_i_retType, in_i_outVars, in_i_functionArguments, in_i_fname)
    local
      Tpl.Text txt;
      Tpl.Text i_retType;
      list<SimCode.Variable> i_outVars;
      list<SimCode.Variable> i_functionArguments;
      Tpl.Text i_fname;

    case ( txt,
           false,
           _,
           _,
           _,
           _ )
      then txt;

    case ( txt,
           _,
           i_retType,
           i_outVars,
           i_functionArguments,
           i_fname )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("int in_"));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "(type_description * inArgs, type_description * outVar)\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_328(txt, i_functionArguments);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = fun_329(txt, i_outVars, i_retType);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_330(txt, i_functionArguments);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = fun_331(txt, i_outVars);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_332(txt, i_functionArguments);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = fun_334(txt, i_outVars);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("return 0;\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then txt;
  end matchcontinue;
end fun_335;

public function functionBodyRegularFunction
  input Tpl.Text in_txt;
  input SimCode.Function in_i_fn;
  input Boolean in_i_inFunc;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_fn, in_i_inFunc)
    local
      Tpl.Text txt;
      Boolean i_inFunc;

    case ( txt,
           (i_fn as SimCode.FUNCTION(name = i_name, outVars = i_outVars, variableDeclarations = i_variableDeclarations, functionArguments = i_functionArguments, body = i_body)),
           i_inFunc )
      local
        list<SimCode.Statement> i_body;
        list<SimCode.Variable> i_functionArguments;
        list<SimCode.Variable> i_variableDeclarations;
        list<SimCode.Variable> i_outVars;
        Absyn.Path i_name;
        SimCode.Function i_fn;
        Boolean ret_12;
        Tpl.Text i_boxedFn;
        Tpl.Text i_outVarsStr;
        Tpl.Text i_outVarInits;
        Tpl.Text i_bodyPart;
        Tpl.Text i_funArgs;
        Tpl.Text i_0__;
        Tpl.Text i_stateVar;
        Tpl.Text i_retVar;
        Tpl.Text i_varInits;
        Tpl.Text i_varDecls;
        Tpl.Text i_retType;
        Tpl.Text i_fname;
      equation
        System.tmpTickReset(1);
        i_fname = underscorePath(emptyTxt, i_name);
        i_retType = fun_319(emptyTxt, i_outVars, i_fname);
        i_varDecls = emptyTxt;
        i_varInits = emptyTxt;
        (i_retVar, i_varDecls) = fun_320(emptyTxt, i_outVars, i_varDecls, i_retType);
        (i_stateVar, i_varDecls) = tempDecl(emptyTxt, "state", i_varDecls);
        i_0__ = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, NONE, 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_0__, i_varInits, i_varDecls) = lm_321(i_0__, i_variableDeclarations, i_varInits, i_varDecls);
        i_0__ = Tpl.popIter(i_0__);
        i_funArgs = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_funArgs, i_varInits) = lm_322(i_funArgs, i_functionArguments, i_varInits);
        i_funArgs = Tpl.popIter(i_funArgs);
        i_bodyPart = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_bodyPart, i_varDecls) = lm_323(i_bodyPart, i_body, i_varDecls);
        i_bodyPart = Tpl.popIter(i_bodyPart);
        i_outVarInits = emptyTxt;
        i_outVarsStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_outVarsStr, i_outVarInits, i_varDecls) = lm_324(i_outVarsStr, i_outVars, i_outVarInits, i_varDecls, i_retVar);
        i_outVarsStr = Tpl.popIter(i_outVarsStr);
        ret_12 = RTOpts.acceptMetaModelicaGrammar();
        i_boxedFn = fun_325(emptyTxt, ret_12, i_fn);
        txt = Tpl.writeText(txt, i_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" _"));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_326(txt, i_functionArguments);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ")\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_funArgs);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_outVarInits);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " = get_memory_state();\n",
                                    "\n"
                                }, true));
        txt = Tpl.writeText(txt, i_varInits);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_bodyPart);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "_return:\n"
                                }, true));
        txt = Tpl.writeText(txt, i_outVarsStr);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("restore_memory_state("));
        txt = Tpl.writeText(txt, i_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\n",
                                    "return "
                                }, false));
        txt = fun_327(txt, i_outVars, i_retVar);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "\n"
                                }, true));
        txt = fun_335(txt, i_inFunc, i_retType, i_outVars, i_functionArguments, i_fname);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_boxedFn);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end functionBodyRegularFunction;

protected function fun_337
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_i_outVars;
  input Tpl.Text in_i_fname;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_outVars, in_i_fname)
    local
      Tpl.Text txt;
      Tpl.Text i_fname;

    case ( txt,
           {},
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void"));
      then txt;

    case ( txt,
           _,
           i_fname )
      equation
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_rettype"));
      then txt;
  end matchcontinue;
end fun_337;

protected function fun_338
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_i_outVars;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_retType;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_outVars, in_i_varDecls, in_i_retType)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_retType;

    case ( txt,
           {},
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls,
           i_retType )
      equation
        (txt, i_varDecls) = outDecl(txt, Tpl.textString(i_retType), i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end fun_338;

protected function lm_339
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_i_outputAlloc;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_retVar;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_outputAlloc;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_outputAlloc, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_outputAlloc, in_i_varDecls, in_i_retVar)
    local
      Tpl.Text txt;
      Tpl.Text i_outputAlloc;
      Tpl.Text i_varDecls;
      Tpl.Text i_retVar;

    case ( txt,
           {},
           i_outputAlloc,
           i_varDecls,
           _ )
      then (txt, i_outputAlloc, i_varDecls);

    case ( txt,
           i_var :: rest,
           i_outputAlloc,
           i_varDecls,
           i_retVar )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
        Integer i_i1;
      equation
        i_i1 = Tpl.getIteri_i1(txt);
        (txt, i_varDecls, i_outputAlloc) = varInit(txt, i_var, Tpl.textString(i_retVar), i_i1, i_varDecls, i_outputAlloc);
        txt = Tpl.nextIter(txt);
        (txt, i_outputAlloc, i_varDecls) = lm_339(txt, rest, i_outputAlloc, i_varDecls, i_retVar);
      then (txt, i_outputAlloc, i_varDecls);

    case ( txt,
           _ :: rest,
           i_outputAlloc,
           i_varDecls,
           i_retVar )
      local
        list<SimCode.Variable> rest;
      equation
        (txt, i_outputAlloc, i_varDecls) = lm_339(txt, rest, i_outputAlloc, i_varDecls, i_retVar);
      then (txt, i_outputAlloc, i_varDecls);
  end matchcontinue;
end lm_339;

protected function fun_340
  input Tpl.Text in_txt;
  input Boolean in_it;
  input SimCode.Function in_i_fn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it, in_i_fn)
    local
      Tpl.Text txt;
      SimCode.Function i_fn;

    case ( txt,
           false,
           _ )
      then txt;

    case ( txt,
           _,
           i_fn )
      equation
        txt = functionBodyBoxed(txt, i_fn);
      then txt;
  end matchcontinue;
end fun_340;

protected function lm_341
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.VARIABLE(ty = i_ty, name = i_name) :: rest )
      local
        list<SimCode.Variable> rest;
        DAE.ComponentRef i_name;
        DAE.ExpType i_ty;
      equation
        txt = expTypeArrayIf(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = crefStr(txt, i_name);
        txt = Tpl.nextIter(txt);
        txt = lm_341(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_341(txt, rest);
      then txt;
  end matchcontinue;
end lm_341;

protected function fun_342
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_i_outVars;
  input Tpl.Text in_i_retVar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_outVars, in_i_retVar)
    local
      Tpl.Text txt;
      Tpl.Text i_retVar;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           _,
           i_retVar )
      equation
        txt = Tpl.writeText(txt, i_retVar);
      then txt;
  end matchcontinue;
end fun_342;

protected function lm_343
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.VARIABLE(ty = i_ty, name = i_name) :: rest )
      local
        list<SimCode.Variable> rest;
        DAE.ComponentRef i_name;
        DAE.ExpType i_ty;
      equation
        txt = expTypeArrayIf(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_343(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_343(txt, rest);
      then txt;
  end matchcontinue;
end lm_343;

protected function lm_344
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_arg as SimCode.VARIABLE(name = _)) :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_arg;
      equation
        txt = readInVar(txt, i_arg);
        txt = Tpl.nextIter(txt);
        txt = lm_344(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_344(txt, rest);
      then txt;
  end matchcontinue;
end lm_344;

protected function lm_345
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.VARIABLE(name = i_name) :: rest )
      local
        list<SimCode.Variable> rest;
        DAE.ComponentRef i_name;
      equation
        txt = crefStr(txt, i_name);
        txt = Tpl.nextIter(txt);
        txt = lm_345(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_345(txt, rest);
      then txt;
  end matchcontinue;
end lm_345;

protected function lm_346
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_var as SimCode.VARIABLE(name = _)) :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
        Integer i_i1;
      equation
        i_i1 = Tpl.getIteri_i1(txt);
        txt = writeOutVar(txt, i_var, i_i1);
        txt = Tpl.nextIter(txt);
        txt = lm_346(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_346(txt, rest);
      then txt;
  end matchcontinue;
end lm_346;

protected function fun_347
  input Tpl.Text in_txt;
  input Boolean in_i_inFunc;
  input list<SimCode.Variable> in_i_outVars;
  input Tpl.Text in_i_retType;
  input list<SimCode.Variable> in_i_funArgs;
  input Tpl.Text in_i_fname;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_inFunc, in_i_outVars, in_i_retType, in_i_funArgs, in_i_fname)
    local
      Tpl.Text txt;
      list<SimCode.Variable> i_outVars;
      Tpl.Text i_retType;
      list<SimCode.Variable> i_funArgs;
      Tpl.Text i_fname;

    case ( txt,
           false,
           _,
           _,
           _,
           _ )
      then txt;

    case ( txt,
           _,
           i_outVars,
           i_retType,
           i_funArgs,
           i_fname )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("int in_"));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "(type_description * inArgs, type_description * outVar)\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_343(txt, i_funArgs);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" out;\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_344(txt, i_funArgs);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("out = _"));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_345(txt, i_funArgs);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_346(txt, i_outVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("return 0;\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then txt;
  end matchcontinue;
end fun_347;

public function functionBodyExternalFunction
  input Tpl.Text in_txt;
  input SimCode.Function in_i_fn;
  input Boolean in_i_inFunc;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_fn, in_i_inFunc)
    local
      Tpl.Text txt;
      Boolean i_inFunc;

    case ( txt,
           (i_fn as SimCode.EXTERNAL_FUNCTION(name = i_name, outVars = i_outVars, funArgs = i_funArgs)),
           i_inFunc )
      local
        list<SimCode.Variable> i_funArgs;
        list<SimCode.Variable> i_outVars;
        Absyn.Path i_name;
        SimCode.Function i_fn;
        Boolean ret_10;
        Tpl.Text i_boxedFn;
        Tpl.Text i_0__;
        Tpl.Text i_callPart;
        Tpl.Text i_stateVar;
        Tpl.Text i_outputAlloc;
        Tpl.Text i_retVar;
        Tpl.Text i_varDecls;
        Tpl.Text i_preExp;
        Tpl.Text i_retType;
        Tpl.Text i_fname;
      equation
        System.tmpTickReset(1);
        i_fname = underscorePath(emptyTxt, i_name);
        i_retType = fun_337(emptyTxt, i_outVars, i_fname);
        i_preExp = emptyTxt;
        i_varDecls = emptyTxt;
        (i_retVar, i_varDecls) = fun_338(emptyTxt, i_outVars, i_varDecls, i_retType);
        i_outputAlloc = emptyTxt;
        (i_stateVar, i_varDecls) = tempDecl(emptyTxt, "state", i_varDecls);
        (i_callPart, i_preExp, i_varDecls) = extFunCall(emptyTxt, i_fn, i_preExp, i_varDecls);
        i_0__ = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, NONE, 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_0__, i_outputAlloc, i_varDecls) = lm_339(i_0__, i_outVars, i_outputAlloc, i_varDecls, i_retVar);
        i_0__ = Tpl.popIter(i_0__);
        ret_10 = RTOpts.acceptMetaModelicaGrammar();
        i_boxedFn = fun_340(emptyTxt, ret_10, i_fn);
        txt = Tpl.writeText(txt, i_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" _"));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_341(txt, i_funArgs);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ")\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" = get_memory_state();\n"));
        txt = Tpl.writeText(txt, i_outputAlloc);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_callPart);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("restore_memory_state("));
        txt = Tpl.writeText(txt, i_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\n",
                                    "return "
                                }, false));
        txt = fun_342(txt, i_outVars, i_retVar);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "\n"
                                }, true));
        txt = fun_347(txt, i_inFunc, i_outVars, i_retType, i_funArgs, i_fname);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_boxedFn);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end functionBodyExternalFunction;

protected function fun_349
  input Tpl.Text in_txt;
  input Boolean in_it;
  input SimCode.Function in_i_fn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it, in_i_fn)
    local
      Tpl.Text txt;
      SimCode.Function i_fn;

    case ( txt,
           false,
           _ )
      then txt;

    case ( txt,
           _,
           i_fn )
      equation
        txt = functionBodyBoxed(txt, i_fn);
      then txt;
  end matchcontinue;
end fun_349;

protected function lm_350
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.VARIABLE(ty = i_ty, name = i_name) :: rest )
      local
        list<SimCode.Variable> rest;
        DAE.ComponentRef i_name;
        DAE.ExpType i_ty;
      equation
        txt = expTypeArrayIf(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = crefStr(txt, i_name);
        txt = Tpl.nextIter(txt);
        txt = lm_350(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_350(txt, rest);
      then txt;
  end matchcontinue;
end lm_350;

protected function lm_351
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_i_structVar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items, in_i_structVar)
    local
      Tpl.Text txt;
      Tpl.Text i_structVar;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           SimCode.VARIABLE(name = i_name) :: rest,
           i_structVar )
      local
        list<SimCode.Variable> rest;
        DAE.ComponentRef i_name;
      equation
        txt = Tpl.writeText(txt, i_structVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_351(txt, rest, i_structVar);
      then txt;

    case ( txt,
           _ :: rest,
           i_structVar )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_351(txt, rest, i_structVar);
      then txt;
  end matchcontinue;
end lm_351;

public function functionBodyRecordConstructor
  input Tpl.Text in_txt;
  input SimCode.Function in_i_fn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_fn)
    local
      Tpl.Text txt;

    case ( txt,
           (i_fn as SimCode.RECORD_CONSTRUCTOR(name = i_name, funArgs = i_funArgs)) )
      local
        list<SimCode.Variable> i_funArgs;
        Absyn.Path i_name;
        SimCode.Function i_fn;
        Boolean ret_7;
        Tpl.Text i_boxedFn;
        Tpl.Text i_structVar;
        Tpl.Text i_structType;
        Tpl.Text i_retVar;
        Tpl.Text i_retType;
        Tpl.Text i_fname;
        Tpl.Text i_varDecls;
      equation
        System.tmpTickReset(1);
        i_varDecls = emptyTxt;
        i_fname = underscorePath(emptyTxt, i_name);
        i_retType = Tpl.writeText(emptyTxt, i_fname);
        i_retType = Tpl.writeTok(i_retType, Tpl.ST_STRING("_rettype"));
        (i_retVar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_retType), i_varDecls);
        i_structType = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("struct "));
        i_structType = Tpl.writeText(i_structType, i_fname);
        (i_structVar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_structType), i_varDecls);
        ret_7 = RTOpts.acceptMetaModelicaGrammar();
        i_boxedFn = fun_349(emptyTxt, ret_7, i_fn);
        txt = Tpl.writeText(txt, i_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" _"));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_350(txt, i_funArgs);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ")\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_351(txt, i_funArgs, i_structVar);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_retVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(".targ1 = "));
        txt = Tpl.writeText(txt, i_structVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ";\n",
                                    "return "
                                }, false));
        txt = Tpl.writeText(txt, i_retVar);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "\n"
                                }, true));
        txt = Tpl.writeText(txt, i_boxedFn);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end functionBodyRecordConstructor;

public function functionBodyBoxed
  input Tpl.Text in_txt;
  input SimCode.Function in_i_fn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_fn)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.FUNCTION(name = i_name, functionArguments = i_functionArguments, outVars = i_outVars) )
      local
        list<SimCode.Variable> i_outVars;
        list<SimCode.Variable> i_functionArguments;
        Absyn.Path i_name;
      equation
        txt = functionBodyBoxedImpl(txt, i_name, i_functionArguments, i_outVars);
      then txt;

    case ( txt,
           SimCode.EXTERNAL_FUNCTION(name = i_name, funArgs = i_funArgs, outVars = i_outVars) )
      local
        list<SimCode.Variable> i_outVars;
        list<SimCode.Variable> i_funArgs;
        Absyn.Path i_name;
      equation
        txt = functionBodyBoxedImpl(txt, i_name, i_funArgs, i_outVars);
      then txt;

    case ( txt,
           (i_fn as SimCode.RECORD_CONSTRUCTOR(name = _)) )
      local
        SimCode.Function i_fn;
      equation
        txt = boxRecordConstructor(txt, i_fn);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end functionBodyBoxed;

protected function fun_354
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_i_outvars;
  input Tpl.Text in_i_fname;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_outvars, in_i_fname)
    local
      Tpl.Text txt;
      Tpl.Text i_fname;

    case ( txt,
           {},
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void"));
      then txt;

    case ( txt,
           _,
           i_fname )
      equation
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_rettype"));
      then txt;
  end matchcontinue;
end fun_354;

protected function fun_355
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_i_outvars;
  input Tpl.Text in_i_retType;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_outvars, in_i_retType)
    local
      Tpl.Text txt;
      Tpl.Text i_retType;

    case ( txt,
           {},
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void"));
      then txt;

    case ( txt,
           _,
           i_retType )
      equation
        txt = Tpl.writeText(txt, i_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("boxed"));
      then txt;
  end matchcontinue;
end fun_355;

protected function fun_356
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_i_outvars;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_retTypeBoxed;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_outvars, in_i_varDecls, in_i_retTypeBoxed)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_retTypeBoxed;

    case ( txt,
           {},
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls,
           i_retTypeBoxed )
      equation
        (txt, i_varDecls) = tempDecl(txt, Tpl.textString(i_retTypeBoxed), i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end fun_356;

protected function fun_357
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_i_outvars;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_retType;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_outvars, in_i_varDecls, in_i_retType)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_retType;

    case ( txt,
           {},
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls,
           i_retType )
      equation
        (txt, i_varDecls) = tempDecl(txt, Tpl.textString(i_retType), i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end fun_357;

protected function lm_358
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_i_varBox;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varBox;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varBox, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varBox, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varBox;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varBox,
           i_varDecls )
      then (txt, i_varBox, i_varDecls);

    case ( txt,
           i_arg :: rest,
           i_varBox,
           i_varDecls )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_arg;
      equation
        (txt, i_varDecls, i_varBox) = funArgUnbox(txt, i_arg, i_varDecls, i_varBox);
        txt = Tpl.nextIter(txt);
        (txt, i_varBox, i_varDecls) = lm_358(txt, rest, i_varBox, i_varDecls);
      then (txt, i_varBox, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varBox,
           i_varDecls )
      local
        list<SimCode.Variable> rest;
      equation
        (txt, i_varBox, i_varDecls) = lm_358(txt, rest, i_varBox, i_varDecls);
      then (txt, i_varBox, i_varDecls);
  end matchcontinue;
end lm_358;

protected function lm_359
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_varUnbox;
  input Tpl.Text in_i_retTypeBoxed;
  input Tpl.Text in_i_retVar;
  input Tpl.Text in_i_retType;
  input Tpl.Text in_i_funRetVar;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_varUnbox;
algorithm
  (out_txt, out_i_varDecls, out_i_varUnbox) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_varUnbox, in_i_retTypeBoxed, in_i_retVar, in_i_retType, in_i_funRetVar)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_varUnbox;
      Tpl.Text i_retTypeBoxed;
      Tpl.Text i_retVar;
      Tpl.Text i_retType;
      Tpl.Text i_funRetVar;

    case ( txt,
           {},
           i_varDecls,
           i_varUnbox,
           _,
           _,
           _,
           _ )
      then (txt, i_varDecls, i_varUnbox);

    case ( txt,
           (i_var as SimCode.VARIABLE(ty = i_ty)) :: rest,
           i_varDecls,
           i_varUnbox,
           i_retTypeBoxed,
           i_retVar,
           i_retType,
           i_funRetVar )
      local
        list<SimCode.Variable> rest;
        DAE.ExpType i_ty;
        SimCode.Variable i_var;
        Integer i_i1;
        Tpl.Text i_arg;
      equation
        i_i1 = Tpl.getIteri_i1(txt);
        i_arg = Tpl.writeText(emptyTxt, i_funRetVar);
        i_arg = Tpl.writeTok(i_arg, Tpl.ST_STRING("."));
        i_arg = Tpl.writeText(i_arg, i_retType);
        i_arg = Tpl.writeTok(i_arg, Tpl.ST_STRING("_"));
        i_arg = Tpl.writeStr(i_arg, intString(i_i1));
        txt = Tpl.writeText(txt, i_retVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = Tpl.writeText(txt, i_retTypeBoxed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = Tpl.writeStr(txt, intString(i_i1));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        (txt, i_varUnbox, i_varDecls) = funArgBox(txt, Tpl.textString(i_arg), i_ty, i_varUnbox, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_varUnbox) = lm_359(txt, rest, i_varDecls, i_varUnbox, i_retTypeBoxed, i_retVar, i_retType, i_funRetVar);
      then (txt, i_varDecls, i_varUnbox);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_varUnbox,
           i_retTypeBoxed,
           i_retVar,
           i_retType,
           i_funRetVar )
      local
        list<SimCode.Variable> rest;
      equation
        (txt, i_varDecls, i_varUnbox) = lm_359(txt, rest, i_varDecls, i_varUnbox, i_retTypeBoxed, i_retVar, i_retType, i_funRetVar);
      then (txt, i_varDecls, i_varUnbox);
  end matchcontinue;
end lm_359;

protected function lm_360
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
      equation
        txt = funArgBoxedDefinition(txt, i_var);
        txt = Tpl.nextIter(txt);
        txt = lm_360(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_360(txt, rest);
      then txt;
  end matchcontinue;
end lm_360;

protected function fun_361
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_i_outvars;
  input Tpl.Text in_i_funRetVar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_outvars, in_i_funRetVar)
    local
      Tpl.Text txt;
      Tpl.Text i_funRetVar;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           _,
           i_funRetVar )
      equation
        txt = Tpl.writeText(txt, i_funRetVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
      then txt;
  end matchcontinue;
end fun_361;

public function functionBodyBoxedImpl
  input Tpl.Text txt;
  input Absyn.Path i_name;
  input list<SimCode.Variable> i_funargs;
  input list<SimCode.Variable> i_outvars;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_retStr;
  Tpl.Text i_args;
  Tpl.Text i_varUnbox;
  Tpl.Text i_varBox;
  Tpl.Text i_stateVar;
  Tpl.Text i_funRetVar;
  Tpl.Text i_retVar;
  Tpl.Text i_varDecls;
  Tpl.Text i_retTypeBoxed;
  Tpl.Text i_retType;
  Tpl.Text i_fname;
algorithm
  System.tmpTickReset(1);
  i_fname := underscorePath(emptyTxt, i_name);
  i_retType := fun_354(emptyTxt, i_outvars, i_fname);
  i_retTypeBoxed := fun_355(emptyTxt, i_outvars, i_retType);
  i_varDecls := emptyTxt;
  (i_retVar, i_varDecls) := fun_356(emptyTxt, i_outvars, i_varDecls, i_retTypeBoxed);
  (i_funRetVar, i_varDecls) := fun_357(emptyTxt, i_outvars, i_varDecls, i_retType);
  (i_stateVar, i_varDecls) := tempDecl(emptyTxt, "state", i_varDecls);
  i_varBox := emptyTxt;
  i_varUnbox := emptyTxt;
  i_args := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_args, i_varBox, i_varDecls) := lm_358(i_args, i_funargs, i_varBox, i_varDecls);
  i_args := Tpl.popIter(i_args);
  i_retStr := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_retStr, i_varDecls, i_varUnbox) := lm_359(i_retStr, i_outvars, i_varDecls, i_varUnbox, i_retTypeBoxed, i_retVar, i_retType, i_funRetVar);
  i_retStr := Tpl.popIter(i_retStr);
  out_txt := Tpl.writeText(txt, i_retTypeBoxed);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(" boxptr_"));
  out_txt := Tpl.writeText(out_txt, i_fname);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("("));
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_360(out_txt, i_funargs);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       ")\n",
                                       "{\n"
                                   }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, i_stateVar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE(" = get_memory_state();\n"));
  out_txt := Tpl.writeText(out_txt, i_varBox);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := fun_361(out_txt, i_outvars, i_funRetVar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("_"));
  out_txt := Tpl.writeText(out_txt, i_fname);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("("));
  out_txt := Tpl.writeText(out_txt, i_args);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE(");\n"));
  out_txt := Tpl.writeText(out_txt, i_varUnbox);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, i_retStr);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("restore_memory_state("));
  out_txt := Tpl.writeText(out_txt, i_stateVar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       ");\n",
                                       "return "
                                   }, false));
  out_txt := Tpl.writeText(out_txt, i_retVar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE(";\n"));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionBodyBoxedImpl;

protected function lm_363
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_var as SimCode.VARIABLE(name = i_name)) :: rest )
      local
        list<SimCode.Variable> rest;
        DAE.ComponentRef i_name;
        SimCode.Variable i_var;
      equation
        txt = crefStr(txt, i_name);
        txt = Tpl.nextIter(txt);
        txt = lm_363(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_363(txt, rest);
      then txt;
  end matchcontinue;
end lm_363;

protected function lm_364
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
      equation
        txt = funArgBoxedDefinition(txt, i_var);
        txt = Tpl.nextIter(txt);
        txt = lm_364(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_364(txt, rest);
      then txt;
  end matchcontinue;
end lm_364;

public function boxRecordConstructor
  input Tpl.Text in_txt;
  input SimCode.Function in_i_fn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_fn)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.RECORD_CONSTRUCTOR(name = i_name, funArgs = i_funArgs) )
      local
        list<SimCode.Variable> i_funArgs;
        Absyn.Path i_name;
        Integer ret_10;
        Integer ret_9;
        Tpl.Text i_funArgCount;
        Tpl.Text i_boxRetVar;
        Tpl.Text i_funArgsStr;
        Tpl.Text i_retVar;
        Tpl.Text i_retType;
        Tpl.Text i_fname;
        Tpl.Text i_stateVar;
        Tpl.Text i_preExp;
        Tpl.Text i_varDecls;
      equation
        System.tmpTickReset(1);
        i_varDecls = emptyTxt;
        i_preExp = emptyTxt;
        (i_stateVar, i_varDecls) = tempDecl(emptyTxt, "state", i_varDecls);
        i_fname = underscorePath(emptyTxt, i_name);
        i_retType = Tpl.writeText(emptyTxt, i_fname);
        i_retType = Tpl.writeTok(i_retType, Tpl.ST_STRING("_rettypeboxed"));
        (i_retVar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_retType), i_varDecls);
        i_funArgsStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        i_funArgsStr = lm_363(i_funArgsStr, i_funArgs);
        i_funArgsStr = Tpl.popIter(i_funArgsStr);
        (i_boxRetVar, i_varDecls) = tempDecl(emptyTxt, "modelica_metatype", i_varDecls);
        ret_9 = listLength(i_funArgs);
        ret_10 = SimCode.incrementInt(ret_9, 1);
        i_funArgCount = Tpl.writeStr(emptyTxt, intString(ret_10));
        txt = Tpl.writeText(txt, i_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" boxptr_"));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_364(txt, i_funArgs);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ")\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " = get_memory_state();\n",
                                    "\n"
                                }, true));
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_boxRetVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = mmc_mk_box"));
        txt = Tpl.writeText(txt, i_funArgCount);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(3, &"));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("__desc, "));
        txt = Tpl.writeText(txt, i_funArgsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.writeText(txt, i_retVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = Tpl.writeText(txt, i_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_1 = "));
        txt = Tpl.writeText(txt, i_boxRetVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ";\n",
                                    "\n",
                                    "restore_memory_state("
                                }, false));
        txt = Tpl.writeText(txt, i_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\n",
                                    "return "
                                }, false));
        txt = Tpl.writeText(txt, i_retVar);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end boxRecordConstructor;

public function funArgUnbox
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_varBox;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_varBox;
algorithm
  (out_txt, out_i_varDecls, out_i_varBox) :=
  matchcontinue(in_txt, in_i_var, in_i_varDecls, in_i_varBox)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_varBox;

    case ( txt,
           SimCode.VARIABLE(name = i_name, ty = i_ty),
           i_varDecls,
           i_varBox )
      local
        DAE.ExpType i_ty;
        DAE.ComponentRef i_name;
        Tpl.Text i_varName;
      equation
        i_varName = crefStr(emptyTxt, i_name);
        (txt, i_varBox, i_varDecls) = unboxVariable(txt, Tpl.textString(i_varName), i_ty, i_varBox, i_varDecls);
      then (txt, i_varDecls, i_varBox);

    case ( txt,
           SimCode.FUNCTION_PTR(name = i_name),
           i_varDecls,
           i_varBox )
      local
        String i_name;
      equation
        txt = Tpl.writeStr(txt, i_name);
      then (txt, i_varDecls, i_varBox);

    case ( txt,
           _,
           i_varDecls,
           i_varBox )
      then (txt, i_varDecls, i_varBox);
  end matchcontinue;
end funArgUnbox;

protected function fun_367
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_varType;
  input String in_i_varName;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_varType, in_i_varName, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      String i_varName;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.ET_LIST(ty = _),
           i_varName,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeStr(txt, i_varName);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_METATUPLE(ty = _),
           i_varName,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeStr(txt, i_varName);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_METAOPTION(ty = _),
           i_varName,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeStr(txt, i_varName);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_UNIONTYPE(),
           i_varName,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeStr(txt, i_varName);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_POLYMORPHIC(),
           i_varName,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeStr(txt, i_varName);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_META_ARRAY(ty = _),
           i_varName,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeStr(txt, i_varName);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_BOXED(ty = _),
           i_varName,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeStr(txt, i_varName);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_varType as DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(path = _))),
           i_varName,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_varType;
      equation
        (txt, i_preExp, i_varDecls) = unboxRecord(txt, i_varName, i_varType, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           i_varType,
           i_varName,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_varType;
        Tpl.Text txt_3;
        Tpl.Text i_tmpVar;
        Tpl.Text i_type;
        Tpl.Text i_shortType;
      equation
        i_shortType = mmcExpTypeShort(emptyTxt, i_varType);
        i_type = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("mmc__unbox__"));
        i_type = Tpl.writeText(i_type, i_shortType);
        i_type = Tpl.writeTok(i_type, Tpl.ST_STRING("_rettype"));
        txt_3 = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("mmc__unbox__"));
        txt_3 = Tpl.writeText(txt_3, i_shortType);
        txt_3 = Tpl.writeTok(txt_3, Tpl.ST_STRING("_rettype"));
        (i_tmpVar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(txt_3), i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_tmpVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = mmc__unbox__"));
        i_preExp = Tpl.writeText(i_preExp, i_shortType);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("("));
        i_preExp = Tpl.writeStr(i_preExp, i_varName);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tmpVar);
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end fun_367;

public function unboxVariable
  input Tpl.Text txt;
  input String i_varName;
  input DAE.ExpType i_varType;
  input Tpl.Text i_preExp;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) := fun_367(txt, i_varType, i_varName, i_preExp, i_varDecls);
end unboxVariable;

protected function lm_369
  input Tpl.Text in_txt;
  input list<DAE.ExpVar> in_items;
  input Tpl.Text in_i_tmpVar;
  input String in_i_recordVar;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_tmpVar, in_i_recordVar, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_tmpVar;
      String i_recordVar;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           DAE.COMPLEX_VAR(name = i_compname, tp = i_tp) :: rest,
           i_tmpVar,
           i_recordVar,
           i_varDecls )
      local
        list<DAE.ExpVar> rest;
        DAE.ExpType i_tp;
        String i_compname;
        Integer i_i1;
        Tpl.Text i_unboxStr;
        Tpl.Text i_unboxBuf;
        Integer ret_3;
        Tpl.Text i_offsetStr;
        Tpl.Text i_untagTmp;
        Tpl.Text i_varType;
      equation
        i_i1 = Tpl.getIteri_i1(txt);
        i_varType = mmcExpTypeShort(emptyTxt, i_tp);
        (i_untagTmp, i_varDecls) = tempDecl(emptyTxt, "modelica_metatype", i_varDecls);
        ret_3 = SimCode.incrementInt(i_i1, 1);
        i_offsetStr = Tpl.writeStr(emptyTxt, intString(ret_3));
        i_unboxBuf = emptyTxt;
        (i_unboxStr, i_unboxBuf, i_varDecls) = unboxVariable(emptyTxt, Tpl.textString(i_untagTmp), i_tp, i_unboxBuf, i_varDecls);
        txt = Tpl.writeText(txt, i_untagTmp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR("));
        txt = Tpl.writeStr(txt, i_recordVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("), "));
        txt = Tpl.writeText(txt, i_offsetStr);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(")));\n"));
        txt = Tpl.writeText(txt, i_unboxBuf);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_tmpVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = Tpl.writeStr(txt, i_compname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, i_unboxStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_369(txt, rest, i_tmpVar, i_recordVar, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_tmpVar,
           i_recordVar,
           i_varDecls )
      local
        list<DAE.ExpVar> rest;
      equation
        (txt, i_varDecls) = lm_369(txt, rest, i_tmpVar, i_recordVar, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_369;

protected function fun_370
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;
  input String in_i_recordVar;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_ty, in_i_recordVar, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      String i_recordVar;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(path = i_path), varLst = i_vars),
           i_recordVar,
           i_preExp,
           i_varDecls )
      local
        list<DAE.ExpVar> i_vars;
        Absyn.Path i_path;
        Tpl.Text txt_1;
        Tpl.Text i_tmpVar;
      equation
        txt_1 = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("struct "));
        txt_1 = underscorePath(txt_1, i_path);
        (i_tmpVar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(txt_1), i_varDecls);
        i_preExp = Tpl.pushIter(i_preExp, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_preExp, i_varDecls) = lm_369(i_preExp, i_vars, i_tmpVar, i_recordVar, i_varDecls);
        i_preExp = Tpl.popIter(i_preExp);
        txt = Tpl.writeText(txt, i_tmpVar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end fun_370;

public function unboxRecord
  input Tpl.Text txt;
  input String i_recordVar;
  input DAE.ExpType i_ty;
  input Tpl.Text i_preExp;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) := fun_370(txt, i_ty, i_recordVar, i_preExp, i_varDecls);
end unboxRecord;

protected function fun_372
  input Tpl.Text in_txt;
  input String in_it;
  input Tpl.Text in_i_constructorType;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_varUnbox;
  input DAE.ExpType in_i_ty;
  input String in_i_varName;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_varUnbox;
algorithm
  (out_txt, out_i_varDecls, out_i_varUnbox) :=
  matchcontinue(in_txt, in_it, in_i_constructorType, in_i_varDecls, in_i_varUnbox, in_i_ty, in_i_varName)
    local
      Tpl.Text txt;
      Tpl.Text i_constructorType;
      Tpl.Text i_varDecls;
      Tpl.Text i_varUnbox;
      DAE.ExpType i_ty;
      String i_varName;

    case ( txt,
           "",
           _,
           i_varDecls,
           i_varUnbox,
           _,
           i_varName )
      equation
        txt = Tpl.writeStr(txt, i_varName);
      then (txt, i_varDecls, i_varUnbox);

    case ( txt,
           _,
           i_constructorType,
           i_varDecls,
           i_varUnbox,
           i_ty,
           i_varName )
      local
        Tpl.Text i_tmpVar;
        Tpl.Text i_constructor;
      equation
        (i_constructor, i_varUnbox, i_varDecls) = mmcConstructor(emptyTxt, i_ty, i_varName, i_varUnbox, i_varDecls);
        (i_tmpVar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_constructorType), i_varDecls);
        i_varUnbox = Tpl.writeText(i_varUnbox, i_tmpVar);
        i_varUnbox = Tpl.writeTok(i_varUnbox, Tpl.ST_STRING(" = "));
        i_varUnbox = Tpl.writeText(i_varUnbox, i_constructor);
        i_varUnbox = Tpl.writeTok(i_varUnbox, Tpl.ST_STRING(";"));
        i_varUnbox = Tpl.writeTok(i_varUnbox, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tmpVar);
      then (txt, i_varDecls, i_varUnbox);
  end matchcontinue;
end fun_372;

public function funArgBox
  input Tpl.Text txt;
  input String i_varName;
  input DAE.ExpType i_ty;
  input Tpl.Text i_varUnbox;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varUnbox;
  output Tpl.Text out_i_varDecls;
protected
  String str_1;
  Tpl.Text i_constructorType;
algorithm
  i_constructorType := mmcConstructorType(emptyTxt, i_ty);
  str_1 := Tpl.textString(i_constructorType);
  (out_txt, out_i_varDecls, out_i_varUnbox) := fun_372(txt, str_1, i_constructorType, i_varDecls, i_varUnbox, i_ty, i_varName);
end funArgBox;

public function mmcConstructorType
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_INT() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_icon_rettype"));
      then txt;

    case ( txt,
           DAE.ET_BOOL() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_icon_rettype"));
      then txt;

    case ( txt,
           DAE.ET_REAL() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_rcon_rettype"));
      then txt;

    case ( txt,
           DAE.ET_STRING() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_scon_rettype"));
      then txt;

    case ( txt,
           DAE.ET_ARRAY(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_acon_rettype"));
      then txt;

    case ( txt,
           DAE.ET_COMPLEX(name = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_metatype"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end mmcConstructorType;

protected function lm_375
  input Tpl.Text in_txt;
  input list<DAE.ExpVar> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input String in_i_varName;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp, in_i_varName)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      String i_varName;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           (i_var as DAE.COMPLEX_VAR(name = i_name, tp = i_tp)) :: rest,
           i_varDecls,
           i_preExp,
           i_varName )
      local
        list<DAE.ExpVar> rest;
        DAE.ExpType i_tp;
        String i_name;
        DAE.ExpVar i_var;
        Tpl.Text i_varname;
      equation
        i_varname = Tpl.writeStr(emptyTxt, i_varName);
        i_varname = Tpl.writeTok(i_varname, Tpl.ST_STRING("."));
        i_varname = Tpl.writeStr(i_varname, i_name);
        (txt, i_preExp, i_varDecls) = funArgBox(txt, Tpl.textString(i_varname), i_tp, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_375(txt, rest, i_varDecls, i_preExp, i_varName);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp,
           i_varName )
      local
        list<DAE.ExpVar> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_375(txt, rest, i_varDecls, i_preExp, i_varName);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_375;

public function mmcConstructor
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_type;
  input String in_i_varName;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_type, in_i_varName, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      String i_varName;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.ET_INT(),
           i_varName,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_icon("));
        txt = Tpl.writeStr(txt, i_varName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_BOOL(),
           i_varName,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_icon("));
        txt = Tpl.writeStr(txt, i_varName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_REAL(),
           i_varName,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_rcon("));
        txt = Tpl.writeStr(txt, i_varName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_STRING(),
           i_varName,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_scon("));
        txt = Tpl.writeStr(txt, i_varName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_ARRAY(ty = _),
           i_varName,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_acon("));
        txt = Tpl.writeStr(txt, i_varName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(path = i_path), varLst = i_vars),
           i_varName,
           i_preExp,
           i_varDecls )
      local
        list<DAE.ExpVar> i_vars;
        Absyn.Path i_path;
        Tpl.Text i_varsStr;
        Integer ret_2;
        Integer ret_1;
        Tpl.Text i_varCount;
      equation
        ret_1 = listLength(i_vars);
        ret_2 = SimCode.incrementInt(ret_1, 1);
        i_varCount = Tpl.writeStr(emptyTxt, intString(ret_2));
        i_varsStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_varsStr, i_varDecls, i_preExp) = lm_375(i_varsStr, i_vars, i_varDecls, i_preExp, i_varName);
        i_varsStr = Tpl.popIter(i_varsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_box"));
        txt = Tpl.writeText(txt, i_varCount);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(3, &"));
        txt = underscorePath(txt, i_path);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("__desc, "));
        txt = Tpl.writeText(txt, i_varsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_COMPLEX(name = _),
           i_varName,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_box("));
        txt = Tpl.writeStr(txt, i_varName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end mmcConstructor;

public function readInVar
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_var)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.VARIABLE(name = i_cr, ty = (i_ty as DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(path = _)))) )
      local
        DAE.ExpType i_ty;
        DAE.ComponentRef i_cr;
        Tpl.Text txt_0;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (read_modelica_record(&inArgs, "));
        txt_0 = crefStr(emptyTxt, i_cr);
        txt = readInVarRecordMembers(txt, i_ty, Tpl.textString(txt_0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")) return 1;"));
      then txt;

    case ( txt,
           SimCode.VARIABLE(ty = i_ty, name = i_name) )
      local
        DAE.ComponentRef i_name;
        DAE.ExpType i_ty;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (read_"));
        txt = expTypeArrayIf(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(&inArgs, &"));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")) return 1;"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end readInVar;

protected function fun_378
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_tp;
  input String in_i_subvar_name;
  input String in_i_prefix;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_tp, in_i_subvar_name, in_i_prefix)
    local
      Tpl.Text txt;
      String i_subvar_name;
      String i_prefix;

    case ( txt,
           (i_tp as DAE.ET_COMPLEX(name = _)),
           i_subvar_name,
           i_prefix )
      local
        DAE.ExpType i_tp;
        Tpl.Text i_newPrefix;
      equation
        i_newPrefix = Tpl.writeStr(emptyTxt, i_prefix);
        i_newPrefix = Tpl.writeTok(i_newPrefix, Tpl.ST_STRING("."));
        i_newPrefix = Tpl.writeStr(i_newPrefix, i_subvar_name);
        txt = readInVarRecordMembers(txt, i_tp, Tpl.textString(i_newPrefix));
      then txt;

    case ( txt,
           _,
           i_subvar_name,
           i_prefix )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("&("));
        txt = Tpl.writeStr(txt, i_prefix);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = Tpl.writeStr(txt, i_subvar_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;
  end matchcontinue;
end fun_378;

protected function lm_379
  input Tpl.Text in_txt;
  input list<DAE.ExpVar> in_items;
  input String in_i_prefix;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items, in_i_prefix)
    local
      Tpl.Text txt;
      String i_prefix;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           (i_subvar as DAE.COMPLEX_VAR(tp = i_tp, name = i_subvar_name)) :: rest,
           i_prefix )
      local
        list<DAE.ExpVar> rest;
        String i_subvar_name;
        DAE.ExpType i_tp;
        DAE.ExpVar i_subvar;
      equation
        txt = fun_378(txt, i_tp, i_subvar_name, i_prefix);
        txt = Tpl.nextIter(txt);
        txt = lm_379(txt, rest, i_prefix);
      then txt;

    case ( txt,
           _ :: rest,
           i_prefix )
      local
        list<DAE.ExpVar> rest;
      equation
        txt = lm_379(txt, rest, i_prefix);
      then txt;
  end matchcontinue;
end lm_379;

public function readInVarRecordMembers
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_type;
  input String in_i_prefix;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type, in_i_prefix)
    local
      Tpl.Text txt;
      String i_prefix;

    case ( txt,
           DAE.ET_COMPLEX(varLst = i_vl),
           i_prefix )
      local
        list<DAE.ExpVar> i_vl;
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_379(txt, i_vl, i_prefix);
        txt = Tpl.popIter(txt);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end readInVarRecordMembers;

public function writeOutVar
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;
  input Integer in_i_index;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_var, in_i_index)
    local
      Tpl.Text txt;
      Integer i_index;

    case ( txt,
           SimCode.VARIABLE(ty = (i_ty as DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(path = _)))),
           i_index )
      local
        DAE.ExpType i_ty;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("write_modelica_record(outVar, "));
        txt = writeOutVarRecordMembers(txt, i_ty, i_index, "");
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           (i_var as SimCode.VARIABLE(name = _)),
           i_index )
      local
        SimCode.Variable i_var;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("write_"));
        txt = varType(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(outVar, &out.targ"));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end writeOutVar;

protected function fun_382
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_tp;
  input Integer in_i_index;
  input String in_i_subvar_name;
  input String in_i_prefix;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_tp, in_i_index, in_i_subvar_name, in_i_prefix)
    local
      Tpl.Text txt;
      Integer i_index;
      String i_subvar_name;
      String i_prefix;

    case ( txt,
           (i_tp as DAE.ET_COMPLEX(name = _)),
           i_index,
           i_subvar_name,
           i_prefix )
      local
        DAE.ExpType i_tp;
        Tpl.Text i_newPrefix;
      equation
        i_newPrefix = Tpl.writeStr(emptyTxt, i_prefix);
        i_newPrefix = Tpl.writeTok(i_newPrefix, Tpl.ST_STRING("."));
        i_newPrefix = Tpl.writeStr(i_newPrefix, i_subvar_name);
        txt = expTypeRW(txt, i_tp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = writeOutVarRecordMembers(txt, i_tp, i_index, Tpl.textString(i_newPrefix));
      then txt;

    case ( txt,
           i_tp,
           i_index,
           i_subvar_name,
           i_prefix )
      local
        DAE.ExpType i_tp;
      equation
        txt = expTypeRW(txt, i_tp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &(out.targ"));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeStr(txt, i_prefix);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = Tpl.writeStr(txt, i_subvar_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;
  end matchcontinue;
end fun_382;

protected function lm_383
  input Tpl.Text in_txt;
  input list<DAE.ExpVar> in_items;
  input Integer in_i_index;
  input String in_i_prefix;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items, in_i_index, in_i_prefix)
    local
      Tpl.Text txt;
      Integer i_index;
      String i_prefix;

    case ( txt,
           {},
           _,
           _ )
      then txt;

    case ( txt,
           (i_subvar as DAE.COMPLEX_VAR(tp = i_tp, name = i_subvar_name)) :: rest,
           i_index,
           i_prefix )
      local
        list<DAE.ExpVar> rest;
        String i_subvar_name;
        DAE.ExpType i_tp;
        DAE.ExpVar i_subvar;
      equation
        txt = fun_382(txt, i_tp, i_index, i_subvar_name, i_prefix);
        txt = Tpl.nextIter(txt);
        txt = lm_383(txt, rest, i_index, i_prefix);
      then txt;

    case ( txt,
           _ :: rest,
           i_index,
           i_prefix )
      local
        list<DAE.ExpVar> rest;
      equation
        txt = lm_383(txt, rest, i_index, i_prefix);
      then txt;
  end matchcontinue;
end lm_383;

protected function fun_384
  input Tpl.Text in_txt;
  input String in_it;
  input Tpl.Text in_i_args;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it, in_i_args)
    local
      Tpl.Text txt;
      Tpl.Text i_args;

    case ( txt,
           "",
           _ )
      then txt;

    case ( txt,
           _,
           i_args )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_args);
      then txt;
  end matchcontinue;
end fun_384;

public function writeOutVarRecordMembers
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_type;
  input Integer in_i_index;
  input String in_i_prefix;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type, in_i_index, in_i_prefix)
    local
      Tpl.Text txt;
      Integer i_index;
      String i_prefix;

    case ( txt,
           DAE.ET_COMPLEX(varLst = i_vl, name = i_n),
           i_index,
           i_prefix )
      local
        Absyn.Path i_n;
        list<DAE.ExpVar> i_vl;
        String str_2;
        Tpl.Text i_args;
        Tpl.Text i_basename;
      equation
        i_basename = underscorePath(emptyTxt, i_n);
        i_args = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        i_args = lm_383(i_args, i_vl, i_index, i_prefix);
        i_args = Tpl.popIter(i_args);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("&"));
        txt = Tpl.writeText(txt, i_basename);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("__desc"));
        str_2 = Tpl.textString(i_args);
        txt = fun_384(txt, str_2, i_args);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", TYPE_DESC_NONE"));
      then txt;

    case ( txt,
           _,
           _,
           _ )
      then txt;
  end matchcontinue;
end writeOutVarRecordMembers;

protected function fun_386
  input Tpl.Text in_txt;
  input String in_i_outStruct;
  input DAE.ComponentRef in_i_var_name;
  input SimCode.Variable in_i_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_outStruct, in_i_var_name, in_i_var)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_var_name;
      SimCode.Variable i_var;

    case ( txt,
           "",
           i_var_name,
           i_var )
      equation
        txt = varType(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = crefStr(txt, i_var_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then txt;

    case ( txt,
           _,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_386;

protected function fun_387
  input Tpl.Text in_txt;
  input String in_i_outStruct;
  input Integer in_i_i;
  input DAE.ComponentRef in_i_var_name;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_outStruct, in_i_i, in_i_var_name)
    local
      Tpl.Text txt;
      Integer i_i;
      DAE.ComponentRef i_var_name;

    case ( txt,
           "",
           _,
           i_var_name )
      equation
        txt = crefStr(txt, i_var_name);
      then txt;

    case ( txt,
           i_outStruct,
           i_i,
           _ )
      local
        String i_outStruct;
      equation
        txt = Tpl.writeStr(txt, i_outStruct);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(".targ"));
        txt = Tpl.writeStr(txt, intString(i_i));
      then txt;
  end matchcontinue;
end fun_387;

protected function lm_388
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_varInits;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_varInits;
algorithm
  (out_txt, out_i_varDecls, out_i_varInits) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_varInits)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_varInits;

    case ( txt,
           {},
           i_varDecls,
           i_varInits )
      then (txt, i_varDecls, i_varInits);

    case ( txt,
           i_exp :: rest,
           i_varDecls,
           i_varInits )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_exp;
      equation
        (txt, i_varInits, i_varDecls) = daeExp(txt, i_exp, SimCode.contextFunction, i_varInits, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_varInits) = lm_388(txt, rest, i_varDecls, i_varInits);
      then (txt, i_varDecls, i_varInits);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_varInits )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls, i_varInits) = lm_388(txt, rest, i_varDecls, i_varInits);
      then (txt, i_varDecls, i_varInits);
  end matchcontinue;
end lm_388;

protected function fun_389
  input Tpl.Text in_txt;
  input Option<DAE.Exp> in_i_var_value;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_varInits;
  input DAE.ComponentRef in_i_var_name;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_varInits;
algorithm
  (out_txt, out_i_varDecls, out_i_varInits) :=
  matchcontinue(in_txt, in_i_var_value, in_i_varDecls, in_i_varInits, in_i_var_name)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_varInits;
      DAE.ComponentRef i_var_name;

    case ( txt,
           SOME(i_exp),
           i_varDecls,
           i_varInits,
           i_var_name )
      local
        DAE.Exp i_exp;
        Tpl.Text i_defaultValue;
      equation
        i_defaultValue = crefStr(emptyTxt, i_var_name);
        i_defaultValue = Tpl.writeTok(i_defaultValue, Tpl.ST_STRING(" = "));
        (i_defaultValue, i_varInits, i_varDecls) = daeExp(i_defaultValue, i_exp, SimCode.contextFunction, i_varInits, i_varDecls);
        i_defaultValue = Tpl.writeTok(i_defaultValue, Tpl.ST_STRING(";"));
        i_defaultValue = Tpl.writeTok(i_defaultValue, Tpl.ST_NEW_LINE());
        i_varInits = Tpl.writeText(i_varInits, i_defaultValue);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
      then (txt, i_varDecls, i_varInits);

    case ( txt,
           _,
           i_varDecls,
           i_varInits,
           _ )
      then (txt, i_varDecls, i_varInits);
  end matchcontinue;
end fun_389;

protected function fun_390
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_i_instDims;
  input Integer in_i_i;
  input String in_i_outStruct;
  input SimCode.Variable in_i_var;
  input Tpl.Text in_i_instDimsInit;
  input Tpl.Text in_i_varName;
  input DAE.ExpType in_i_var_ty;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_varInits;
  input DAE.ComponentRef in_i_var_name;
  input Option<DAE.Exp> in_i_var_value;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_varInits;
algorithm
  (out_txt, out_i_varDecls, out_i_varInits) :=
  matchcontinue(in_txt, in_i_instDims, in_i_i, in_i_outStruct, in_i_var, in_i_instDimsInit, in_i_varName, in_i_var_ty, in_i_varDecls, in_i_varInits, in_i_var_name, in_i_var_value)
    local
      Tpl.Text txt;
      Integer i_i;
      String i_outStruct;
      SimCode.Variable i_var;
      Tpl.Text i_instDimsInit;
      Tpl.Text i_varName;
      DAE.ExpType i_var_ty;
      Tpl.Text i_varDecls;
      Tpl.Text i_varInits;
      DAE.ComponentRef i_var_name;
      Option<DAE.Exp> i_var_value;

    case ( txt,
           {},
           _,
           _,
           _,
           _,
           _,
           _,
           i_varDecls,
           i_varInits,
           i_var_name,
           i_var_value )
      equation
        (txt, i_varDecls, i_varInits) = fun_389(txt, i_var_value, i_varDecls, i_varInits, i_var_name);
      then (txt, i_varDecls, i_varInits);

    case ( txt,
           i_instDims,
           i_i,
           i_outStruct,
           i_var,
           i_instDimsInit,
           i_varName,
           i_var_ty,
           i_varDecls,
           i_varInits,
           _,
           _ )
      local
        list<DAE.Exp> i_instDims;
        Tpl.Text i_defaultValue;
        Integer ret_0;
      equation
        i_varInits = Tpl.writeTok(i_varInits, Tpl.ST_STRING("alloc_"));
        i_varInits = expTypeShort(i_varInits, i_var_ty);
        i_varInits = Tpl.writeTok(i_varInits, Tpl.ST_STRING("_array(&"));
        i_varInits = Tpl.writeText(i_varInits, i_varName);
        i_varInits = Tpl.writeTok(i_varInits, Tpl.ST_STRING(", "));
        ret_0 = listLength(i_instDims);
        i_varInits = Tpl.writeStr(i_varInits, intString(ret_0));
        i_varInits = Tpl.writeTok(i_varInits, Tpl.ST_STRING(", "));
        i_varInits = Tpl.writeText(i_varInits, i_instDimsInit);
        i_varInits = Tpl.writeTok(i_varInits, Tpl.ST_STRING(");"));
        i_varInits = Tpl.writeTok(i_varInits, Tpl.ST_NEW_LINE());
        (i_defaultValue, i_varDecls, i_varInits) = varDefaultValue(emptyTxt, i_var, i_outStruct, i_i, Tpl.textString(i_varName), i_varDecls, i_varInits);
        i_varInits = Tpl.writeText(i_varInits, i_defaultValue);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
      then (txt, i_varDecls, i_varInits);
  end matchcontinue;
end fun_390;

public function varInit
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;
  input String in_i_outStruct;
  input Integer in_i_i;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_varInits;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_varInits;
algorithm
  (out_txt, out_i_varDecls, out_i_varInits) :=
  matchcontinue(in_txt, in_i_var, in_i_outStruct, in_i_i, in_i_varDecls, in_i_varInits)
    local
      Tpl.Text txt;
      String i_outStruct;
      Integer i_i;
      Tpl.Text i_varDecls;
      Tpl.Text i_varInits;

    case ( txt,
           (i_var as SimCode.VARIABLE(name = i_var_name, instDims = i_instDims, value = i_var_value, ty = i_var_ty)),
           i_outStruct,
           i_i,
           i_varDecls,
           i_varInits )
      local
        DAE.ExpType i_var_ty;
        Option<DAE.Exp> i_var_value;
        list<DAE.Exp> i_instDims;
        DAE.ComponentRef i_var_name;
        SimCode.Variable i_var;
        Tpl.Text i_instDimsInit;
        Tpl.Text i_varName;
      equation
        i_varDecls = fun_386(i_varDecls, i_outStruct, i_var_name, i_var);
        i_varName = fun_387(emptyTxt, i_outStruct, i_i, i_var_name);
        i_instDimsInit = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_instDimsInit, i_varDecls, i_varInits) = lm_388(i_instDimsInit, i_instDims, i_varDecls, i_varInits);
        i_instDimsInit = Tpl.popIter(i_instDimsInit);
        (txt, i_varDecls, i_varInits) = fun_390(txt, i_instDims, i_i, i_outStruct, i_var, i_instDimsInit, i_varName, i_var_ty, i_varDecls, i_varInits, i_var_name, i_var_value);
      then (txt, i_varDecls, i_varInits);

    case ( txt,
           _,
           _,
           _,
           i_varDecls,
           i_varInits )
      then (txt, i_varDecls, i_varInits);
  end matchcontinue;
end varInit;

protected function fun_392
  input Tpl.Text in_txt;
  input Option<DAE.Exp> in_i_value;
  input String in_i_lhsVarName;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_varInits;
  input Integer in_i_i;
  input String in_i_outStruct;
  input DAE.ExpType in_i_var_ty;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_varInits;
algorithm
  (out_txt, out_i_varDecls, out_i_varInits) :=
  matchcontinue(in_txt, in_i_value, in_i_lhsVarName, in_i_varDecls, in_i_varInits, in_i_i, in_i_outStruct, in_i_var_ty)
    local
      Tpl.Text txt;
      String i_lhsVarName;
      Tpl.Text i_varDecls;
      Tpl.Text i_varInits;
      Integer i_i;
      String i_outStruct;
      DAE.ExpType i_var_ty;

    case ( txt,
           SOME(DAE.CREF(componentRef = i_cr)),
           _,
           i_varDecls,
           i_varInits,
           i_i,
           i_outStruct,
           i_var_ty )
      local
        DAE.ComponentRef i_cr;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("copy_"));
        txt = expTypeShort(txt, i_var_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array_data(&"));
        txt = crefStr(txt, i_cr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeStr(txt, i_outStruct);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(".targ"));
        txt = Tpl.writeStr(txt, intString(i_i));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then (txt, i_varDecls, i_varInits);

    case ( txt,
           SOME((i_arr as DAE.ARRAY(ty = _))),
           i_lhsVarName,
           i_varDecls,
           i_varInits,
           _,
           _,
           i_var_ty )
      local
        DAE.Exp i_arr;
        Tpl.Text i_arrayExp;
      equation
        (i_arrayExp, i_varInits, i_varDecls) = daeExp(emptyTxt, i_arr, SimCode.contextFunction, i_varInits, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("copy_"));
        txt = expTypeShort(txt, i_var_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array_data(&"));
        txt = Tpl.writeText(txt, i_arrayExp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeStr(txt, i_lhsVarName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then (txt, i_varDecls, i_varInits);

    case ( txt,
           _,
           _,
           i_varDecls,
           i_varInits,
           _,
           _,
           _ )
      then (txt, i_varDecls, i_varInits);
  end matchcontinue;
end fun_392;

public function varDefaultValue
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;
  input String in_i_outStruct;
  input Integer in_i_i;
  input String in_i_lhsVarName;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_varInits;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_varInits;
algorithm
  (out_txt, out_i_varDecls, out_i_varInits) :=
  matchcontinue(in_txt, in_i_var, in_i_outStruct, in_i_i, in_i_lhsVarName, in_i_varDecls, in_i_varInits)
    local
      Tpl.Text txt;
      String i_outStruct;
      Integer i_i;
      String i_lhsVarName;
      Tpl.Text i_varDecls;
      Tpl.Text i_varInits;

    case ( txt,
           (i_var as SimCode.VARIABLE(value = i_value, ty = i_var_ty)),
           i_outStruct,
           i_i,
           i_lhsVarName,
           i_varDecls,
           i_varInits )
      local
        DAE.ExpType i_var_ty;
        Option<DAE.Exp> i_value;
        SimCode.Variable i_var;
      equation
        (txt, i_varDecls, i_varInits) = fun_392(txt, i_value, i_lhsVarName, i_varDecls, i_varInits, i_i, i_outStruct, i_var_ty);
      then (txt, i_varDecls, i_varInits);

    case ( txt,
           _,
           _,
           _,
           _,
           i_varDecls,
           i_varInits )
      then (txt, i_varDecls, i_varInits);
  end matchcontinue;
end varDefaultValue;

protected function lm_394
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_arg :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_arg;
      equation
        txt = mmcVarType(txt, i_arg);
        txt = Tpl.nextIter(txt);
        txt = lm_394(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_394(txt, rest);
      then txt;
  end matchcontinue;
end lm_394;

protected function lm_395
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_arg :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_arg;
        Integer i_i1;
      equation
        i_i1 = Tpl.getIteri_i1(txt);
        txt = mmcVarType(txt, i_arg);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" targ"));
        txt = Tpl.writeStr(txt, intString(i_i1));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_395(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_395(txt, rest);
      then txt;
  end matchcontinue;
end lm_395;

protected function fun_396
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;
  input list<SimCode.Variable> in_i_args;
  input Tpl.Text in_i_rettype;
  input Tpl.Text in_i_typelist;
  input String in_i_name;
  input Tpl.Text in_i_varInit;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varInit;
algorithm
  (out_txt, out_i_varInit) :=
  matchcontinue(in_txt, in_i_ty, in_i_args, in_i_rettype, in_i_typelist, in_i_name, in_i_varInit)
    local
      Tpl.Text txt;
      list<SimCode.Variable> i_args;
      Tpl.Text i_rettype;
      Tpl.Text i_typelist;
      String i_name;
      Tpl.Text i_varInit;

    case ( txt,
           DAE.ET_NORETCALL(),
           _,
           _,
           i_typelist,
           i_name,
           i_varInit )
      equation
        i_varInit = Tpl.writeTok(i_varInit, Tpl.ST_STRING("_"));
        i_varInit = Tpl.writeStr(i_varInit, i_name);
        i_varInit = Tpl.writeTok(i_varInit, Tpl.ST_STRING(" = (void(*)("));
        i_varInit = Tpl.writeText(i_varInit, i_typelist);
        i_varInit = Tpl.writeTok(i_varInit, Tpl.ST_STRING(")) "));
        i_varInit = Tpl.writeStr(i_varInit, i_name);
        i_varInit = Tpl.writeTok(i_varInit, Tpl.ST_STRING(";"));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void(*_"));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")("));
        txt = Tpl.writeText(txt, i_typelist);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then (txt, i_varInit);

    case ( txt,
           _,
           i_args,
           i_rettype,
           i_typelist,
           i_name,
           i_varInit )
      equation
        i_varInit = Tpl.writeTok(i_varInit, Tpl.ST_STRING("_"));
        i_varInit = Tpl.writeStr(i_varInit, i_name);
        i_varInit = Tpl.writeTok(i_varInit, Tpl.ST_STRING(" = ("));
        i_varInit = Tpl.writeText(i_varInit, i_rettype);
        i_varInit = Tpl.writeTok(i_varInit, Tpl.ST_STRING("(*)("));
        i_varInit = Tpl.writeText(i_varInit, i_typelist);
        i_varInit = Tpl.writeTok(i_varInit, Tpl.ST_STRING(")) "));
        i_varInit = Tpl.writeStr(i_varInit, i_name);
        i_varInit = Tpl.writeTok(i_varInit, Tpl.ST_STRING(";"));
        i_varInit = Tpl.writeTok(i_varInit, Tpl.ST_NEW_LINE());
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define "));
        txt = Tpl.writeText(txt, i_rettype);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "_1 targ1\n",
                                    "typedef struct "
                                }, false));
        txt = Tpl.writeText(txt, i_rettype);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "_s\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_395(txt, i_args);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("} "));
        txt = Tpl.writeText(txt, i_rettype);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        txt = Tpl.writeText(txt, i_rettype);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(*_"));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")("));
        txt = Tpl.writeText(txt, i_typelist);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then (txt, i_varInit);
  end matchcontinue;
end fun_396;

public function functionArg
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;
  input Tpl.Text in_i_varInit;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varInit;
algorithm
  (out_txt, out_i_varInit) :=
  matchcontinue(in_txt, in_i_var, in_i_varInit)
    local
      Tpl.Text txt;
      Tpl.Text i_varInit;

    case ( txt,
           (i_var as SimCode.FUNCTION_PTR(args = i_args, name = i_name, ty = i_ty)),
           i_varInit )
      local
        DAE.ExpType i_ty;
        String i_name;
        list<SimCode.Variable> i_args;
        SimCode.Variable i_var;
        Tpl.Text i_rettype;
        Tpl.Text i_typelist;
      equation
        i_typelist = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        i_typelist = lm_394(i_typelist, i_args);
        i_typelist = Tpl.popIter(i_typelist);
        i_rettype = Tpl.writeStr(emptyTxt, i_name);
        i_rettype = Tpl.writeTok(i_rettype, Tpl.ST_STRING("_rettype"));
        (txt, i_varInit) = fun_396(txt, i_ty, i_args, i_rettype, i_typelist, i_name, i_varInit);
      then (txt, i_varInit);

    case ( txt,
           _,
           i_varInit )
      then (txt, i_varInit);
  end matchcontinue;
end functionArg;

protected function lm_398
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_varInits;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_varInits;
algorithm
  (out_txt, out_i_varDecls, out_i_varInits) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_varInits)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_varInits;

    case ( txt,
           {},
           i_varDecls,
           i_varInits )
      then (txt, i_varDecls, i_varInits);

    case ( txt,
           i_exp :: rest,
           i_varDecls,
           i_varInits )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_exp;
      equation
        (txt, i_varInits, i_varDecls) = daeExp(txt, i_exp, SimCode.contextFunction, i_varInits, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_varInits) = lm_398(txt, rest, i_varDecls, i_varInits);
      then (txt, i_varDecls, i_varInits);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_varInits )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls, i_varInits) = lm_398(txt, rest, i_varDecls, i_varInits);
      then (txt, i_varDecls, i_varInits);
  end matchcontinue;
end lm_398;

protected function fun_399
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_i_instDims;
  input Tpl.Text in_i_instDimsInit;
  input DAE.ExpType in_i_var_ty;
  input DAE.ComponentRef in_i_var_name;
  input Integer in_i_i;
  input String in_i_dest;
  input SimCode.Variable in_i_var;
  input Tpl.Text in_i_varInits;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varInits;
algorithm
  (out_txt, out_i_varInits) :=
  matchcontinue(in_txt, in_i_instDims, in_i_instDimsInit, in_i_var_ty, in_i_var_name, in_i_i, in_i_dest, in_i_var, in_i_varInits)
    local
      Tpl.Text txt;
      Tpl.Text i_instDimsInit;
      DAE.ExpType i_var_ty;
      DAE.ComponentRef i_var_name;
      Integer i_i;
      String i_dest;
      SimCode.Variable i_var;
      Tpl.Text i_varInits;

    case ( txt,
           {},
           _,
           _,
           i_var_name,
           i_i,
           i_dest,
           i_var,
           i_varInits )
      equation
        i_varInits = initRecordMembers(i_varInits, i_var);
        txt = Tpl.writeStr(txt, i_dest);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(".targ"));
        txt = Tpl.writeStr(txt, intString(i_i));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = crefStr(txt, i_var_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, i_varInits);

    case ( txt,
           i_instDims,
           i_instDimsInit,
           i_var_ty,
           i_var_name,
           i_i,
           i_dest,
           _,
           i_varInits )
      local
        list<DAE.Exp> i_instDims;
        Integer ret_0;
      equation
        i_varInits = Tpl.writeTok(i_varInits, Tpl.ST_STRING("alloc_"));
        i_varInits = expTypeShort(i_varInits, i_var_ty);
        i_varInits = Tpl.writeTok(i_varInits, Tpl.ST_STRING("_array(&"));
        i_varInits = Tpl.writeStr(i_varInits, i_dest);
        i_varInits = Tpl.writeTok(i_varInits, Tpl.ST_STRING(".targ"));
        i_varInits = Tpl.writeStr(i_varInits, intString(i_i));
        i_varInits = Tpl.writeTok(i_varInits, Tpl.ST_STRING(", "));
        ret_0 = listLength(i_instDims);
        i_varInits = Tpl.writeStr(i_varInits, intString(ret_0));
        i_varInits = Tpl.writeTok(i_varInits, Tpl.ST_STRING(", "));
        i_varInits = Tpl.writeText(i_varInits, i_instDimsInit);
        i_varInits = Tpl.writeTok(i_varInits, Tpl.ST_STRING(");"));
        i_varInits = Tpl.writeTok(i_varInits, Tpl.ST_NEW_LINE());
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("copy_"));
        txt = expTypeShort(txt, i_var_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array_data(&"));
        txt = crefStr(txt, i_var_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeStr(txt, i_dest);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(".targ"));
        txt = Tpl.writeStr(txt, intString(i_i));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then (txt, i_varInits);
  end matchcontinue;
end fun_399;

public function varOutput
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;
  input String in_i_dest;
  input Integer in_i_i;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_varInits;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_varInits;
algorithm
  (out_txt, out_i_varDecls, out_i_varInits) :=
  matchcontinue(in_txt, in_i_var, in_i_dest, in_i_i, in_i_varDecls, in_i_varInits)
    local
      Tpl.Text txt;
      String i_dest;
      Integer i_i;
      Tpl.Text i_varDecls;
      Tpl.Text i_varInits;

    case ( txt,
           (i_var as SimCode.VARIABLE(instDims = i_instDims, name = i_var_name, ty = i_var_ty)),
           i_dest,
           i_i,
           i_varDecls,
           i_varInits )
      local
        DAE.ExpType i_var_ty;
        DAE.ComponentRef i_var_name;
        list<DAE.Exp> i_instDims;
        SimCode.Variable i_var;
        Tpl.Text i_instDimsInit;
      equation
        i_instDimsInit = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_instDimsInit, i_varDecls, i_varInits) = lm_398(i_instDimsInit, i_instDims, i_varDecls, i_varInits);
        i_instDimsInit = Tpl.popIter(i_instDimsInit);
        (txt, i_varInits) = fun_399(txt, i_instDims, i_instDimsInit, i_var_ty, i_var_name, i_i, i_dest, i_var, i_varInits);
      then (txt, i_varDecls, i_varInits);

    case ( txt,
           _,
           _,
           _,
           i_varDecls,
           i_varInits )
      then (txt, i_varDecls, i_varInits);
  end matchcontinue;
end varOutput;

protected function lm_401
  input Tpl.Text in_txt;
  input list<DAE.ExpVar> in_items;
  input Tpl.Text in_i_varName;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varName;
algorithm
  (out_txt, out_i_varName) :=
  matchcontinue(in_txt, in_items, in_i_varName)
    local
      Tpl.Text txt;
      Tpl.Text i_varName;

    case ( txt,
           {},
           i_varName )
      then (txt, i_varName);

    case ( txt,
           i_v :: rest,
           i_varName )
      local
        list<DAE.ExpVar> rest;
        DAE.ExpVar i_v;
      equation
        (txt, i_varName) = recordMemberInit(txt, i_v, i_varName);
        txt = Tpl.nextIter(txt);
        (txt, i_varName) = lm_401(txt, rest, i_varName);
      then (txt, i_varName);

    case ( txt,
           _ :: rest,
           i_varName )
      local
        list<DAE.ExpVar> rest;
      equation
        (txt, i_varName) = lm_401(txt, rest, i_varName);
      then (txt, i_varName);
  end matchcontinue;
end lm_401;

public function initRecordMembers
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_var)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.VARIABLE(ty = DAE.ET_COMPLEX(complexClassType = i_RECORD, varLst = i_ty_varLst), name = i_name) )
      local
        DAE.ComponentRef i_name;
        list<DAE.ExpVar> i_ty_varLst;
        ClassInf.State i_RECORD;
        Tpl.Text i_varName;
      equation
        i_varName = crefStr(emptyTxt, i_name);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varName) = lm_401(txt, i_ty_varLst, i_varName);
        txt = Tpl.popIter(txt);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end initRecordMembers;

protected function lm_403
  input Tpl.Text in_txt;
  input list<DAE.Dimension> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_dim :: rest )
      local
        list<DAE.Dimension> rest;
        DAE.Dimension i_dim;
      equation
        txt = dimension(txt, i_dim);
        txt = Tpl.nextIter(txt);
        txt = lm_403(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<DAE.Dimension> rest;
      equation
        txt = lm_403(txt, rest);
      then txt;
  end matchcontinue;
end lm_403;

protected function fun_404
  input Tpl.Text in_txt;
  input DAE.ExpVar in_i_v;
  input Tpl.Text in_i_varName;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_v, in_i_varName)
    local
      Tpl.Text txt;
      Tpl.Text i_varName;

    case ( txt,
           DAE.COMPLEX_VAR(tp = (i_tp as DAE.ET_ARRAY(arrayDimensions = i_tp_arrayDimensions)), name = i_name),
           i_varName )
      local
        String i_name;
        list<DAE.Dimension> i_tp_arrayDimensions;
        DAE.ExpType i_tp;
        Integer ret_2;
        Tpl.Text i_dims;
        Tpl.Text i_arrayType;
      equation
        i_arrayType = expType(emptyTxt, i_tp, true);
        i_dims = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        i_dims = lm_403(i_dims, i_tp_arrayDimensions);
        i_dims = Tpl.popIter(i_dims);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("alloc_"));
        txt = Tpl.writeText(txt, i_arrayType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(&"));
        txt = Tpl.writeText(txt, i_varName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_2 = listLength(i_tp_arrayDimensions);
        txt = Tpl.writeStr(txt, intString(ret_2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_dims);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_404;

public function recordMemberInit
  input Tpl.Text txt;
  input DAE.ExpVar i_v;
  input Tpl.Text i_varName;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varName;
algorithm
  out_txt := fun_404(txt, i_v, i_varName);
  out_i_varName := i_varName;
end recordMemberInit;

public function extVarName
  input Tpl.Text txt;
  input DAE.ComponentRef i_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt := crefStr(txt, i_cr);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("_ext"));
end extVarName;

protected function fun_407
  input Tpl.Text in_txt;
  input String in_i_language;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Function in_i_fun;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_i_language, in_i_varDecls, in_i_preExp, in_i_fun)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Function i_fun;

    case ( txt,
           "C",
           i_varDecls,
           i_preExp,
           i_fun )
      equation
        (txt, i_preExp, i_varDecls) = extFunCallC(txt, i_fun, i_preExp, i_varDecls);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           "FORTRAN 77",
           i_varDecls,
           i_preExp,
           i_fun )
      equation
        (txt, i_preExp, i_varDecls) = extFunCallF77(txt, i_fun, i_preExp, i_varDecls);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _,
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_407;

public function extFunCall
  input Tpl.Text in_txt;
  input SimCode.Function in_i_fun;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_fun, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_fun as SimCode.EXTERNAL_FUNCTION(language = i_language)),
           i_preExp,
           i_varDecls )
      local
        String i_language;
        SimCode.Function i_fun;
      equation
        (txt, i_varDecls, i_preExp) = fun_407(txt, i_language, i_varDecls, i_preExp, i_fun);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end extFunCall;

protected function lm_409
  input Tpl.Text in_txt;
  input list<SimCode.SimExtArg> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;

    case ( txt,
           {},
           i_varDecls,
           i_preExp )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_arg :: rest,
           i_varDecls,
           i_preExp )
      local
        list<SimCode.SimExtArg> rest;
        SimCode.SimExtArg i_arg;
      equation
        (txt, i_preExp, i_varDecls) = extArg(txt, i_arg, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_409(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp )
      local
        list<SimCode.SimExtArg> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_409(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_409;

protected function fun_410
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_extReturn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_extReturn)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMEXTARG(cref = i_c) )
      local
        DAE.ComponentRef i_c;
      equation
        txt = extVarName(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_410;

protected function lm_411
  input Tpl.Text in_txt;
  input list<SimCode.SimExtArg> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_arg :: rest,
           i_varDecls )
      local
        list<SimCode.SimExtArg> rest;
        SimCode.SimExtArg i_arg;
      equation
        (txt, i_varDecls) = extFunCallVardecl(txt, i_arg, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_411(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimExtArg> rest;
      equation
        (txt, i_varDecls) = lm_411(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_411;

protected function fun_412
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_extReturn;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_extReturn, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_extReturn as SimCode.SIMEXTARG(cref = _)),
           i_varDecls )
      local
        SimCode.SimExtArg i_extReturn;
      equation
        (txt, i_varDecls) = extFunCallVardecl(txt, i_extReturn, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end fun_412;

protected function lm_413
  input Tpl.Text in_txt;
  input list<SimCode.SimExtArg> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_arg :: rest )
      local
        list<SimCode.SimExtArg> rest;
        SimCode.SimExtArg i_arg;
      equation
        txt = extFunCallVarcopy(txt, i_arg);
        txt = Tpl.nextIter(txt);
        txt = lm_413(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimExtArg> rest;
      equation
        txt = lm_413(txt, rest);
      then txt;
  end matchcontinue;
end lm_413;

protected function fun_414
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_extReturn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_extReturn)
    local
      Tpl.Text txt;

    case ( txt,
           (i_extReturn as SimCode.SIMEXTARG(cref = _)) )
      local
        SimCode.SimExtArg i_extReturn;
      equation
        txt = extFunCallVarcopy(txt, i_extReturn);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_414;

public function extFunCallC
  input Tpl.Text in_txt;
  input SimCode.Function in_i_fun;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_fun, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.EXTERNAL_FUNCTION(extArgs = i_extArgs, extReturn = i_extReturn, extName = i_extName),
           i_preExp,
           i_varDecls )
      local
        String i_extName;
        SimCode.SimExtArg i_extReturn;
        list<SimCode.SimExtArg> i_extArgs;
        Tpl.Text i_returnAssign;
        Tpl.Text i_args;
      equation
        i_args = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_args, i_varDecls, i_preExp) = lm_409(i_args, i_extArgs, i_varDecls, i_preExp);
        i_args = Tpl.popIter(i_args);
        i_returnAssign = fun_410(emptyTxt, i_extReturn);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls) = lm_411(txt, i_extArgs, i_varDecls);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        (txt, i_varDecls) = fun_412(txt, i_extReturn, i_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_returnAssign);
        txt = Tpl.writeStr(txt, i_extName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_args);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_413(txt, i_extArgs);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = fun_414(txt, i_extReturn);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end extFunCallC;

protected function lm_416
  input Tpl.Text in_txt;
  input list<SimCode.SimExtArg> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;

    case ( txt,
           {},
           i_varDecls,
           i_preExp )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_arg :: rest,
           i_varDecls,
           i_preExp )
      local
        list<SimCode.SimExtArg> rest;
        SimCode.SimExtArg i_arg;
      equation
        (txt, i_preExp, i_varDecls) = extArgF77(txt, i_arg, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_416(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp )
      local
        list<SimCode.SimExtArg> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_416(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_416;

protected function fun_417
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_extReturn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_extReturn)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMEXTARG(cref = i_c) )
      local
        DAE.ComponentRef i_c;
      equation
        txt = extVarName(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_417;

protected function lm_418
  input Tpl.Text in_txt;
  input list<SimCode.SimExtArg> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_arg :: rest,
           i_varDecls )
      local
        list<SimCode.SimExtArg> rest;
        SimCode.SimExtArg i_arg;
      equation
        (txt, i_varDecls) = extFunCallVardeclF77(txt, i_arg, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_418(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimExtArg> rest;
      equation
        (txt, i_varDecls) = lm_418(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_418;

protected function fun_419
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_extReturn;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_extReturn, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_extReturn as SimCode.SIMEXTARG(cref = _)),
           i_varDecls )
      local
        SimCode.SimExtArg i_extReturn;
      equation
        (txt, i_varDecls) = extFunCallVardeclF77(txt, i_extReturn, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end fun_419;

protected function lm_420
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;

    case ( txt,
           {},
           i_varDecls,
           i_preExp )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_arg :: rest,
           i_varDecls,
           i_preExp )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_arg;
      equation
        (txt, i_preExp, i_varDecls) = extFunCallBiVarF77(txt, i_arg, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_420(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp )
      local
        list<SimCode.Variable> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_420(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_420;

protected function lm_421
  input Tpl.Text in_txt;
  input list<SimCode.SimExtArg> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_arg :: rest )
      local
        list<SimCode.SimExtArg> rest;
        SimCode.SimExtArg i_arg;
      equation
        txt = extFunCallVarcopyF77(txt, i_arg);
        txt = Tpl.nextIter(txt);
        txt = lm_421(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimExtArg> rest;
      equation
        txt = lm_421(txt, rest);
      then txt;
  end matchcontinue;
end lm_421;

protected function fun_422
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_extReturn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_extReturn)
    local
      Tpl.Text txt;

    case ( txt,
           (i_extReturn as SimCode.SIMEXTARG(cref = _)) )
      local
        SimCode.SimExtArg i_extReturn;
      equation
        txt = extFunCallVarcopyF77(txt, i_extReturn);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_422;

public function extFunCallF77
  input Tpl.Text in_txt;
  input SimCode.Function in_i_fun;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_fun, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.EXTERNAL_FUNCTION(extArgs = i_extArgs, extReturn = i_extReturn, biVars = i_biVars, extName = i_extName),
           i_preExp,
           i_varDecls )
      local
        String i_extName;
        list<SimCode.Variable> i_biVars;
        SimCode.SimExtArg i_extReturn;
        list<SimCode.SimExtArg> i_extArgs;
        Tpl.Text i_returnAssign;
        Tpl.Text i_args;
      equation
        i_args = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_args, i_varDecls, i_preExp) = lm_416(i_args, i_extArgs, i_varDecls, i_preExp);
        i_args = Tpl.popIter(i_args);
        i_returnAssign = fun_417(emptyTxt, i_extReturn);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls) = lm_418(txt, i_extArgs, i_varDecls);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        (txt, i_varDecls) = fun_419(txt, i_extReturn, i_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls, i_preExp) = lm_420(txt, i_biVars, i_varDecls, i_preExp);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_returnAssign);
        txt = Tpl.writeStr(txt, i_extName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_("));
        txt = Tpl.writeText(txt, i_args);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_421(txt, i_extArgs);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = fun_422(txt, i_extReturn);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end extFunCallF77;

protected function fun_424
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;
  input DAE.ComponentRef in_i_c;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_ty, in_i_c, in_i_varDecls)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_c;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.ET_STRING(),
           _,
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_ty,
           i_c,
           i_varDecls )
      local
        DAE.ExpType i_ty;
      equation
        i_varDecls = extType(i_varDecls, i_ty);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING(" "));
        i_varDecls = crefStr(i_varDecls, i_c);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING("_ext;"));
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_NEW_LINE());
        txt = crefStr(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_ext = ("));
        txt = extType(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
        txt = crefStr(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, i_varDecls);
  end matchcontinue;
end fun_424;

protected function fun_425
  input Tpl.Text in_txt;
  input Integer in_i_oi;
  input DAE.ComponentRef in_i_c;
  input DAE.ExpType in_i_ty;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_oi, in_i_c, in_i_ty, in_i_varDecls)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_c;
      DAE.ExpType i_ty;
      Tpl.Text i_varDecls;

    case ( txt,
           0,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_c,
           i_ty,
           i_varDecls )
      equation
        i_varDecls = extType(i_varDecls, i_ty);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING(" "));
        i_varDecls = extVarName(i_varDecls, i_c);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING(";"));
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_NEW_LINE());
      then (txt, i_varDecls);
  end matchcontinue;
end fun_425;

public function extFunCallVardecl
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_arg;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_arg, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.SIMEXTARG(isInput = true, isArray = false, type_ = i_ty, cref = i_c),
           i_varDecls )
      local
        DAE.ComponentRef i_c;
        DAE.ExpType i_ty;
      equation
        (txt, i_varDecls) = fun_424(txt, i_ty, i_c, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           SimCode.SIMEXTARG(outputIndex = i_oi, isArray = false, type_ = i_ty, cref = i_c),
           i_varDecls )
      local
        DAE.ComponentRef i_c;
        DAE.ExpType i_ty;
        Integer i_oi;
      equation
        (txt, i_varDecls) = fun_425(txt, i_oi, i_c, i_ty, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end extFunCallVardecl;

protected function fun_427
  input Tpl.Text in_txt;
  input Boolean in_i_ia;
  input DAE.ComponentRef in_i_c;
  input Integer in_i_oi;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ia, in_i_c, in_i_oi, in_i_ty)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_c;
      Integer i_oi;
      DAE.ExpType i_ty;

    case ( txt,
           false,
           _,
           _,
           _ )
      then txt;

    case ( txt,
           _,
           i_c,
           i_oi,
           i_ty )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("convert_alloc_"));
        txt = expTypeArray(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_to_f77(&out.targ"));
        txt = Tpl.writeStr(txt, intString(i_oi));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = extVarName(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;
  end matchcontinue;
end fun_427;

protected function fun_428
  input Tpl.Text in_txt;
  input Integer in_i_oi;
  input Boolean in_i_ia;
  input DAE.ComponentRef in_i_c;
  input DAE.ExpType in_i_ty;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_oi, in_i_ia, in_i_c, in_i_ty, in_i_varDecls)
    local
      Tpl.Text txt;
      Boolean i_ia;
      DAE.ComponentRef i_c;
      DAE.ExpType i_ty;
      Tpl.Text i_varDecls;

    case ( txt,
           0,
           _,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_oi,
           i_ia,
           i_c,
           i_ty,
           i_varDecls )
      local
        Integer i_oi;
      equation
        i_varDecls = expTypeArrayIf(i_varDecls, i_ty);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING(" "));
        i_varDecls = extVarName(i_varDecls, i_c);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING(";"));
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_NEW_LINE());
        txt = fun_427(txt, i_ia, i_c, i_oi, i_ty);
      then (txt, i_varDecls);
  end matchcontinue;
end fun_428;

public function extFunCallVardeclF77
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_arg;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_arg, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.SIMEXTARG(isInput = true, isArray = true, type_ = i_ty, cref = i_c),
           i_varDecls )
      local
        DAE.ComponentRef i_c;
        DAE.ExpType i_ty;
      equation
        i_varDecls = expTypeArrayIf(i_varDecls, i_ty);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING(" "));
        i_varDecls = extVarName(i_varDecls, i_c);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING(";"));
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_NEW_LINE());
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("convert_alloc_"));
        txt = expTypeArray(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_to_f77(&"));
        txt = crefStr(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = extVarName(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then (txt, i_varDecls);

    case ( txt,
           SimCode.SIMEXTARG(outputIndex = i_oi, isArray = i_ia, type_ = i_ty, cref = i_c),
           i_varDecls )
      local
        DAE.ComponentRef i_c;
        DAE.ExpType i_ty;
        Boolean i_ia;
        Integer i_oi;
      equation
        (txt, i_varDecls) = fun_428(txt, i_oi, i_ia, i_c, i_ty, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           SimCode.SIMEXTARG(type_ = i_ty, cref = i_c),
           i_varDecls )
      local
        DAE.ComponentRef i_c;
        DAE.ExpType i_ty;
      equation
        i_varDecls = expTypeArrayIf(i_varDecls, i_ty);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING(" "));
        i_varDecls = extVarName(i_varDecls, i_c);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING(";"));
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_NEW_LINE());
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end extFunCallVardeclF77;

protected function fun_430
  input Tpl.Text in_txt;
  input Option<DAE.Exp> in_i_value;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_var__name;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_i_value, in_i_varDecls, in_i_preExp, in_i_var__name)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      Tpl.Text i_var__name;

    case ( txt,
           SOME(i_v),
           i_varDecls,
           i_preExp,
           i_var__name )
      local
        DAE.Exp i_v;
      equation
        txt = Tpl.writeText(txt, i_var__name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_v, SimCode.contextFunction, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _,
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_430;

protected function lm_431
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;

    case ( txt,
           {},
           i_varDecls,
           i_preExp )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_exp :: rest,
           i_varDecls,
           i_preExp )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_exp, SimCode.contextFunction, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_431(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_431(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_431;

protected function fun_432
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_i_instDims;
  input DAE.ComponentRef in_i_name;
  input Tpl.Text in_i_instDimsInit;
  input Tpl.Text in_i_var__name;
  input Tpl.Text in_i_preExp;
  input DAE.ExpType in_i_var_ty;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_preExp) :=
  matchcontinue(in_txt, in_i_instDims, in_i_name, in_i_instDimsInit, in_i_var__name, in_i_preExp, in_i_var_ty)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_name;
      Tpl.Text i_instDimsInit;
      Tpl.Text i_var__name;
      Tpl.Text i_preExp;
      DAE.ExpType i_var_ty;

    case ( txt,
           {},
           _,
           _,
           _,
           i_preExp,
           _ )
      then (txt, i_preExp);

    case ( txt,
           i_instDims,
           i_name,
           i_instDimsInit,
           i_var__name,
           i_preExp,
           i_var_ty )
      local
        list<DAE.Exp> i_instDims;
        Integer ret_1;
        Tpl.Text i_type;
      equation
        i_type = expTypeArray(emptyTxt, i_var_ty);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_type);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(&"));
        i_preExp = Tpl.writeText(i_preExp, i_var__name);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        ret_1 = listLength(i_instDims);
        i_preExp = Tpl.writeStr(i_preExp, intString(ret_1));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_instDimsInit);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("convert_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_type);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("_to_f77(&"));
        i_preExp = Tpl.writeText(i_preExp, i_var__name);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = extVarName(i_preExp, i_name);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
      then (txt, i_preExp);
  end matchcontinue;
end fun_432;

public function extFunCallBiVarF77
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_var, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_var as SimCode.VARIABLE(name = i_name, value = i_value, instDims = i_instDims, ty = i_var_ty)),
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_var_ty;
        list<DAE.Exp> i_instDims;
        Option<DAE.Exp> i_value;
        DAE.ComponentRef i_name;
        SimCode.Variable i_var;
        Tpl.Text i_instDimsInit;
        Tpl.Text i_defaultValue;
        Tpl.Text i_var__name;
      equation
        i_var__name = crefStr(emptyTxt, i_name);
        i_varDecls = varType(i_varDecls, i_var);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING(" "));
        i_varDecls = Tpl.writeText(i_varDecls, i_var__name);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING(";"));
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_NEW_LINE());
        i_varDecls = varType(i_varDecls, i_var);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING(" "));
        i_varDecls = extVarName(i_varDecls, i_name);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING(";"));
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_NEW_LINE());
        (i_defaultValue, i_varDecls, i_preExp) = fun_430(emptyTxt, i_value, i_varDecls, i_preExp, i_var__name);
        i_preExp = Tpl.writeText(i_preExp, i_defaultValue);
        i_instDimsInit = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_instDimsInit, i_varDecls, i_preExp) = lm_431(i_instDimsInit, i_instDims, i_varDecls, i_preExp);
        i_instDimsInit = Tpl.popIter(i_instDimsInit);
        (txt, i_preExp) = fun_432(txt, i_instDims, i_name, i_instDimsInit, i_var__name, i_preExp, i_var_ty);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end extFunCallBiVarF77;

protected function fun_434
  input Tpl.Text in_txt;
  input Integer in_i_oi;
  input DAE.ComponentRef in_i_c;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_oi, in_i_c, in_i_ty)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_c;
      DAE.ExpType i_ty;

    case ( txt,
           0,
           _,
           _ )
      then txt;

    case ( txt,
           i_oi,
           i_c,
           i_ty )
      local
        Integer i_oi;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("out.targ"));
        txt = Tpl.writeStr(txt, intString(i_oi));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = ("));
        txt = expTypeModelica(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
        txt = crefStr(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_ext;"));
      then txt;
  end matchcontinue;
end fun_434;

public function extFunCallVarcopy
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_arg;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_arg)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMEXTARG(outputIndex = i_oi, isArray = false, type_ = i_ty, cref = i_c) )
      local
        DAE.ComponentRef i_c;
        DAE.ExpType i_ty;
        Integer i_oi;
      equation
        txt = fun_434(txt, i_oi, i_c, i_ty);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end extFunCallVarcopy;

protected function fun_436
  input Tpl.Text in_txt;
  input Boolean in_i_ai;
  input Tpl.Text in_i_ext__name;
  input DAE.ExpType in_i_ty;
  input Tpl.Text in_i_outarg;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ai, in_i_ext__name, in_i_ty, in_i_outarg)
    local
      Tpl.Text txt;
      Tpl.Text i_ext__name;
      DAE.ExpType i_ty;
      Tpl.Text i_outarg;

    case ( txt,
           false,
           i_ext__name,
           i_ty,
           i_outarg )
      equation
        txt = Tpl.writeText(txt, i_outarg);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = ("));
        txt = expTypeModelica(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
        txt = Tpl.writeText(txt, i_ext__name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then txt;

    case ( txt,
           true,
           i_ext__name,
           i_ty,
           i_outarg )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("convert_alloc_"));
        txt = expTypeArray(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_from_f77(&"));
        txt = Tpl.writeText(txt, i_ext__name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeText(txt, i_outarg);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _,
           _,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_436;

protected function fun_437
  input Tpl.Text in_txt;
  input Integer in_i_oi;
  input DAE.ExpType in_i_ty;
  input Boolean in_i_ai;
  input DAE.ComponentRef in_i_c;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_oi, in_i_ty, in_i_ai, in_i_c)
    local
      Tpl.Text txt;
      DAE.ExpType i_ty;
      Boolean i_ai;
      DAE.ComponentRef i_c;

    case ( txt,
           0,
           _,
           _,
           _ )
      then txt;

    case ( txt,
           i_oi,
           i_ty,
           i_ai,
           i_c )
      local
        Integer i_oi;
        Tpl.Text i_ext__name;
        Tpl.Text i_outarg;
      equation
        i_outarg = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("out.targ"));
        i_outarg = Tpl.writeStr(i_outarg, intString(i_oi));
        i_ext__name = crefStr(emptyTxt, i_c);
        i_ext__name = Tpl.writeTok(i_ext__name, Tpl.ST_STRING("_ext"));
        txt = fun_436(txt, i_ai, i_ext__name, i_ty, i_outarg);
      then txt;
  end matchcontinue;
end fun_437;

public function extFunCallVarcopyF77
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_arg;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_arg)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMEXTARG(outputIndex = i_oi, isArray = i_ai, type_ = i_ty, cref = i_c) )
      local
        DAE.ComponentRef i_c;
        DAE.ExpType i_ty;
        Boolean i_ai;
        Integer i_oi;
      equation
        txt = fun_437(txt, i_oi, i_ty, i_ai, i_c);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end extFunCallVarcopyF77;

protected function fun_439
  input Tpl.Text in_txt;
  input Integer in_i_oi;
  input DAE.ComponentRef in_i_c;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_oi, in_i_c)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_c;

    case ( txt,
           0,
           i_c )
      equation
        txt = crefStr(txt, i_c);
      then txt;

    case ( txt,
           i_oi,
           _ )
      local
        Integer i_oi;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("out.targ"));
        txt = Tpl.writeStr(txt, intString(i_oi));
      then txt;
  end matchcontinue;
end fun_439;

protected function fun_440
  input Tpl.Text in_txt;
  input Integer in_i_oi;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_oi)
    local
      Tpl.Text txt;

    case ( txt,
           0 )
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("&"));
      then txt;
  end matchcontinue;
end fun_440;

protected function fun_441
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_t;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_t)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_STRING() )
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_ext"));
      then txt;
  end matchcontinue;
end fun_441;

protected function fun_442
  input Tpl.Text in_txt;
  input Integer in_i_oi;
  input DAE.ExpType in_i_t;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_oi, in_i_t)
    local
      Tpl.Text txt;
      DAE.ExpType i_t;

    case ( txt,
           0,
           i_t )
      equation
        txt = fun_441(txt, i_t);
      then txt;

    case ( txt,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_ext"));
      then txt;
  end matchcontinue;
end fun_442;

protected function fun_443
  input Tpl.Text in_txt;
  input Integer in_i_outputIndex;
  input DAE.ComponentRef in_i_c;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_outputIndex, in_i_c)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_c;

    case ( txt,
           0,
           i_c )
      equation
        txt = crefStr(txt, i_c);
      then txt;

    case ( txt,
           i_outputIndex,
           _ )
      local
        Integer i_outputIndex;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("out.targ"));
        txt = Tpl.writeStr(txt, intString(i_outputIndex));
      then txt;
  end matchcontinue;
end fun_443;

public function extArg
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_extArg;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_extArg, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.SIMEXTARG(cref = i_c, outputIndex = i_oi, isArray = true, type_ = i_t),
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_t;
        Integer i_oi;
        DAE.ComponentRef i_c;
        Tpl.Text i_shortTypeStr;
        Tpl.Text i_name;
      equation
        i_name = fun_439(emptyTxt, i_oi, i_c);
        i_shortTypeStr = expTypeShort(emptyTxt, i_t);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("data_of_"));
        txt = Tpl.writeText(txt, i_shortTypeStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array(&("));
        txt = Tpl.writeText(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("))"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           SimCode.SIMEXTARG(cref = i_c, isInput = i_ii, outputIndex = i_oi, type_ = i_t),
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_t;
        Integer i_oi;
        Boolean i_ii;
        DAE.ComponentRef i_c;
        Tpl.Text i_suffix;
        Tpl.Text i_prefix;
      equation
        i_prefix = fun_440(emptyTxt, i_oi);
        i_suffix = fun_442(emptyTxt, i_oi, i_t);
        txt = Tpl.writeText(txt, i_prefix);
        txt = crefStr(txt, i_c);
        txt = Tpl.writeText(txt, i_suffix);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           SimCode.SIMEXTARGEXP(exp = i_exp),
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_exp, SimCode.contextFunction, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           SimCode.SIMEXTARGSIZE(cref = i_c, type_ = i_type__, outputIndex = i_outputIndex, exp = i_exp),
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_exp;
        Integer i_outputIndex;
        DAE.ExpType i_type__;
        DAE.ComponentRef i_c;
        Tpl.Text i_dim;
        Tpl.Text i_name;
        Tpl.Text i_typeStr;
      equation
        i_typeStr = expTypeShort(emptyTxt, i_type__);
        i_name = fun_443(emptyTxt, i_outputIndex, i_c);
        (i_dim, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, SimCode.contextFunction, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("size_of_dimension_"));
        txt = Tpl.writeText(txt, i_typeStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array("));
        txt = Tpl.writeText(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_dim);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end extArg;

protected function fun_445
  input Tpl.Text in_txt;
  input Boolean in_i_ia;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ia)
    local
      Tpl.Text txt;

    case ( txt,
           true )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_ext"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_445;

protected function fun_446
  input Tpl.Text in_txt;
  input Integer in_i_oi;
  input Boolean in_i_ia;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_oi, in_i_ia)
    local
      Tpl.Text txt;
      Boolean i_ia;

    case ( txt,
           0,
           i_ia )
      equation
        txt = fun_445(txt, i_ia);
      then txt;

    case ( txt,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_ext"));
      then txt;
  end matchcontinue;
end fun_446;

public function extArgF77
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_extArg;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_extArg, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.SIMEXTARG(cref = i_c, isArray = true, type_ = i_t),
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_t;
        DAE.ComponentRef i_c;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("data_of_"));
        txt = expTypeShort(txt, i_t);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array(&("));
        txt = extVarName(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("))"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           SimCode.SIMEXTARG(cref = i_c, isArray = i_ia, outputIndex = i_oi, type_ = i_t),
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_t;
        Integer i_oi;
        Boolean i_ia;
        DAE.ComponentRef i_c;
        Tpl.Text i_suffix;
      equation
        i_suffix = fun_446(emptyTxt, i_oi, i_ia);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("&"));
        txt = crefStr(txt, i_c);
        txt = Tpl.writeText(txt, i_suffix);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           SimCode.SIMEXTARGEXP(exp = i_exp),
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_exp, SimCode.contextFunction, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           SimCode.SIMEXTARGSIZE(cref = i_c, exp = i_exp, type_ = i_type__),
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_type__;
        DAE.Exp i_exp;
        DAE.ComponentRef i_c;
        Tpl.Text i_size__call;
        Tpl.Text i_dim;
        Tpl.Text i_sizeVar;
        Tpl.Text i_sizeVarName;
      equation
        i_sizeVarName = tempSizeVarName(emptyTxt, i_c, i_exp);
        (i_sizeVar, i_varDecls) = tempDecl(emptyTxt, "int", i_varDecls);
        (i_dim, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, SimCode.contextFunction, i_preExp, i_varDecls);
        i_size__call = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("size_of_dimension_"));
        i_size__call = expTypeShort(i_size__call, i_type__);
        i_size__call = Tpl.writeTok(i_size__call, Tpl.ST_STRING("_array"));
        i_preExp = Tpl.writeText(i_preExp, i_sizeVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = "));
        i_preExp = Tpl.writeText(i_preExp, i_size__call);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("("));
        i_preExp = crefStr(i_preExp, i_c);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_dim);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("&"));
        txt = Tpl.writeText(txt, i_sizeVar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end extArgF77;

protected function fun_448
  input Tpl.Text in_txt;
  input DAE.Exp in_i_indices;
  input DAE.ComponentRef in_i_c;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_indices, in_i_c)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_c;

    case ( txt,
           DAE.ICONST(integer = i_integer),
           i_c )
      local
        Integer i_integer;
      equation
        txt = crefStr(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_size_"));
        txt = Tpl.writeStr(txt, intString(i_integer));
      then txt;

    case ( txt,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("tempSizeVarName:UNHANDLED_EXPRESSION"));
      then txt;
  end matchcontinue;
end fun_448;

public function tempSizeVarName
  input Tpl.Text txt;
  input DAE.ComponentRef i_c;
  input DAE.Exp i_indices;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_448(txt, i_indices, i_c);
end tempSizeVarName;

protected function lm_450
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDecls) = algStatement(txt, i_stmt, SimCode.contextFunction, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_450(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDecls) = lm_450(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_450;

public function funStatement
  input Tpl.Text in_txt;
  input SimCode.Statement in_i_stmt;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.ALGORITHM(statementLst = i_statementLst),
           i_varDecls )
      local
        list<DAE.Statement> i_statementLst;
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls) = lm_450(txt, i_statementLst, i_varDecls);
        txt = Tpl.popIter(txt);
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("NOT IMPLEMENTED FUN STATEMENT"));
      then (txt, i_varDecls);
  end matchcontinue;
end funStatement;

public function algStatement
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_s as DAE.STMT_ASSIGN(type_ = _)),
           i_context,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtAssign(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_ASSIGN_ARR(type_ = _)),
           i_context,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtAssignArr(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_TUPLE_ASSIGN(type_ = _)),
           i_context,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtTupleAssign(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_IF(exp = _)),
           i_context,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtIf(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_FOR(type_ = _)),
           i_context,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtFor(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_WHILE(exp = _)),
           i_context,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtWhile(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_ASSERT(cond = _)),
           i_context,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtAssert(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_WHEN(exp = _)),
           i_context,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtWhen(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_MATCHCASES(matchType = _)),
           i_context,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtMatchcases(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_BREAK(source = _)),
           _,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("break;"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_TRY(tryBody = _)),
           i_context,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtTry(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_CATCH(catchBody = _)),
           i_context,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtCatch(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_THROW(source = _)),
           _,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("throw 1;"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_RETURN(source = _)),
           _,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("goto _return;"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_NORETCALL(exp = _)),
           i_context,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtNoretcall(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("NOT IMPLEMENTED ALG STATEMENT"));
      then (txt, i_varDecls);
  end matchcontinue;
end algStatement;

public function algStmtAssign
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.STMT_ASSIGN(exp1 = DAE.CREF(componentRef = DAE.WILD()), exp = i_e),
           i_context,
           i_varDecls )
      local
        DAE.Exp i_e;
        Tpl.Text i_expPart;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
      then (txt, i_varDecls);

    case ( txt,
           DAE.STMT_ASSIGN(exp1 = (i_exp1 as DAE.CREF(componentRef = _)), exp = i_exp),
           i_context,
           i_varDecls )
      local
        DAE.Exp i_exp;
        DAE.Exp i_exp1;
        Tpl.Text i_expPart;
        Tpl.Text i_varPart;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_varPart, i_preExp, i_varDecls) = scalarLhsCref(emptyTxt, i_exp1, i_context, i_preExp, i_varDecls);
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_varPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, i_varDecls);

    case ( txt,
           DAE.STMT_ASSIGN(exp1 = i_exp1, exp = i_exp),
           i_context,
           i_varDecls )
      local
        DAE.Exp i_exp;
        DAE.Exp i_exp1;
        Tpl.Text i_expPart2;
        Tpl.Text i_expPart1;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_expPart1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp1, i_context, i_preExp, i_varDecls);
        (i_expPart2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_expPart1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, i_expPart2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStmtAssign;

protected function fun_454
  input Tpl.Text in_txt;
  input String in_it;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_ispec;
  input SimCode.Context in_i_context;
  input DAE.ComponentRef in_i_cr;
  input Tpl.Text in_i_expPart;
  input DAE.ExpType in_i_t;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_it, in_i_varDecls, in_i_ispec, in_i_context, in_i_cr, in_i_expPart, in_i_t, in_i_preExp)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_ispec;
      SimCode.Context i_context;
      DAE.ComponentRef i_cr;
      Tpl.Text i_expPart;
      DAE.ExpType i_t;
      Tpl.Text i_preExp;

    case ( txt,
           "",
           i_varDecls,
           _,
           i_context,
           i_cr,
           i_expPart,
           i_t,
           i_preExp )
      equation
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = copyArrayData(txt, i_t, Tpl.textString(i_expPart), i_cr, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls,
           i_ispec,
           i_context,
           i_cr,
           i_expPart,
           i_t,
           i_preExp )
      equation
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        (txt, i_varDecls) = indexedAssign(txt, i_t, Tpl.textString(i_expPart), i_cr, Tpl.textString(i_ispec), i_context, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end fun_454;

public function algStmtAssignArr
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.STMT_ASSIGN_ARR(exp = i_e, componentRef = i_cr, type_ = i_t),
           i_context,
           i_varDecls )
      local
        DAE.ExpType i_t;
        DAE.ComponentRef i_cr;
        DAE.Exp i_e;
        String str_3;
        Tpl.Text i_ispec;
        Tpl.Text i_expPart;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
        (i_ispec, i_preExp, i_varDecls) = indexSpecFromCref(emptyTxt, i_cr, i_context, i_preExp, i_varDecls);
        str_3 = Tpl.textString(i_ispec);
        (txt, i_varDecls) = fun_454(txt, str_3, i_varDecls, i_ispec, i_context, i_cr, i_expPart, i_t, i_preExp);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStmtAssignArr;

protected function fun_456
  input Tpl.Text in_txt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;
  input String in_i_ispec;
  input Tpl.Text in_i_cref;
  input String in_i_exp;
  input Tpl.Text in_i_type;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_context, in_i_varDecls, in_i_ispec, in_i_cref, in_i_exp, in_i_type)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      String i_ispec;
      Tpl.Text i_cref;
      String i_exp;
      Tpl.Text i_type;

    case ( txt,
           SimCode.FUNCTION_CONTEXT(),
           i_varDecls,
           i_ispec,
           i_cref,
           i_exp,
           i_type )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("indexed_assign_"));
        txt = Tpl.writeText(txt, i_type);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(&"));
        txt = Tpl.writeStr(txt, i_exp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeText(txt, i_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeStr(txt, i_ispec);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls,
           i_ispec,
           i_cref,
           i_exp,
           i_type )
      local
        Tpl.Text i_tmp;
      equation
        (i_tmp, i_varDecls) = tempDecl(emptyTxt, "real_array", i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("indexed_assign_"));
        txt = Tpl.writeText(txt, i_type);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(&"));
        txt = Tpl.writeStr(txt, i_exp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeText(txt, i_tmp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeStr(txt, i_ispec);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\n",
                                    "copy_"
                                }, false));
        txt = Tpl.writeText(txt, i_type);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_data_mem(&"));
        txt = Tpl.writeText(txt, i_tmp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeText(txt, i_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then (txt, i_varDecls);
  end matchcontinue;
end fun_456;

public function indexedAssign
  input Tpl.Text txt;
  input DAE.ExpType i_ty;
  input String i_exp;
  input DAE.ComponentRef i_cr;
  input String i_ispec;
  input SimCode.Context i_context;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
protected
  Tpl.Text i_cref;
  Tpl.Text i_type;
algorithm
  i_type := expTypeArray(emptyTxt, i_ty);
  i_cref := contextArrayCref(emptyTxt, i_cr, i_context);
  (out_txt, out_i_varDecls) := fun_456(txt, i_context, i_varDecls, i_ispec, i_cref, i_exp, i_type);
end indexedAssign;

protected function fun_458
  input Tpl.Text in_txt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_cref;
  input String in_i_exp;
  input Tpl.Text in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_context, in_i_cref, in_i_exp, in_i_type)
    local
      Tpl.Text txt;
      Tpl.Text i_cref;
      String i_exp;
      Tpl.Text i_type;

    case ( txt,
           SimCode.FUNCTION_CONTEXT(),
           i_cref,
           i_exp,
           i_type )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("copy_"));
        txt = Tpl.writeText(txt, i_type);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_data(&"));
        txt = Tpl.writeStr(txt, i_exp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeText(txt, i_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _,
           i_cref,
           i_exp,
           i_type )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("copy_"));
        txt = Tpl.writeText(txt, i_type);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_data_mem(&"));
        txt = Tpl.writeStr(txt, i_exp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeText(txt, i_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;
  end matchcontinue;
end fun_458;

public function copyArrayData
  input Tpl.Text txt;
  input DAE.ExpType i_ty;
  input String i_exp;
  input DAE.ComponentRef i_cr;
  input SimCode.Context i_context;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_cref;
  Tpl.Text i_type;
algorithm
  i_type := expTypeArray(emptyTxt, i_ty);
  i_cref := contextArrayCref(emptyTxt, i_cr, i_context);
  out_txt := fun_458(txt, i_context, i_cref, i_exp, i_type);
end copyArrayData;

protected function lm_460
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_retStruct;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp, in_i_context, in_i_retStruct)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;
      Tpl.Text i_retStruct;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_cr :: rest,
           i_varDecls,
           i_preExp,
           i_context,
           i_retStruct )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_cr;
        Integer i_i1;
        Tpl.Text i_rhsStr;
      equation
        i_i1 = Tpl.getIteri_i1(txt);
        i_rhsStr = Tpl.writeText(emptyTxt, i_retStruct);
        i_rhsStr = Tpl.writeTok(i_rhsStr, Tpl.ST_STRING(".targ"));
        i_rhsStr = Tpl.writeStr(i_rhsStr, intString(i_i1));
        (txt, i_preExp, i_varDecls) = writeLhsCref(txt, i_cr, Tpl.textString(i_rhsStr), i_context, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_460(txt, rest, i_varDecls, i_preExp, i_context, i_retStruct);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp,
           i_context,
           i_retStruct )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_460(txt, rest, i_varDecls, i_preExp, i_context, i_retStruct);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_460;

public function algStmtTupleAssign
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.STMT_TUPLE_ASSIGN(exp = (i_exp as DAE.CALL(path = _)), expExpLst = i_expExpLst),
           i_context,
           i_varDecls )
      local
        list<DAE.Exp> i_expExpLst;
        DAE.Exp i_exp;
        Tpl.Text i_retStruct;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_retStruct, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls, i_preExp) = lm_460(txt, i_expExpLst, i_varDecls, i_preExp, i_context, i_retStruct);
        txt = Tpl.popIter(txt);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStmtTupleAssign;

protected function fun_462
  input Tpl.Text in_txt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_lhsStr;
  input String in_i_rhsStr;
  input DAE.ExpType in_i_t;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_context, in_i_lhsStr, in_i_rhsStr, in_i_t)
    local
      Tpl.Text txt;
      Tpl.Text i_lhsStr;
      String i_rhsStr;
      DAE.ExpType i_t;

    case ( txt,
           SimCode.SIMULATION(genDiscrete = _),
           i_lhsStr,
           i_rhsStr,
           i_t )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("copy_"));
        txt = expTypeShort(txt, i_t);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array_data_mem(&"));
        txt = Tpl.writeStr(txt, i_rhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeText(txt, i_lhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _,
           i_lhsStr,
           i_rhsStr,
           _ )
      equation
        txt = Tpl.writeText(txt, i_lhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeStr(txt, i_rhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then txt;
  end matchcontinue;
end fun_462;

protected function fun_463
  input Tpl.Text in_txt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_lhsStr;
  input String in_i_rhsStr;
  input DAE.ExpType in_i_t;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_context, in_i_lhsStr, in_i_rhsStr, in_i_t)
    local
      Tpl.Text txt;
      Tpl.Text i_lhsStr;
      String i_rhsStr;
      DAE.ExpType i_t;

    case ( txt,
           SimCode.SIMULATION(genDiscrete = _),
           i_lhsStr,
           i_rhsStr,
           i_t )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("usub_"));
        txt = expTypeShort(txt, i_t);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array(&"));
        txt = Tpl.writeStr(txt, i_rhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "copy_"
                                }, false));
        txt = expTypeShort(txt, i_t);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array_data_mem(&"));
        txt = Tpl.writeStr(txt, i_rhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeText(txt, i_lhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _,
           i_lhsStr,
           i_rhsStr,
           _ )
      equation
        txt = Tpl.writeText(txt, i_lhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = -"));
        txt = Tpl.writeStr(txt, i_rhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then txt;
  end matchcontinue;
end fun_463;

public function writeLhsCref
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input String in_i_rhsStr;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_rhsStr, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      String i_rhsStr;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_exp as DAE.CREF(ty = (i_t as DAE.ET_ARRAY(ty = _)))),
           i_rhsStr,
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_t;
        DAE.Exp i_exp;
        Tpl.Text i_lhsStr;
      equation
        (i_lhsStr, i_preExp, i_varDecls) = scalarLhsCref(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        txt = fun_462(txt, i_context, i_lhsStr, i_rhsStr, i_t);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.UNARY(exp = (i_e as DAE.CREF(ty = (i_t as DAE.ET_ARRAY(ty = _))))),
           i_rhsStr,
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_t;
        DAE.Exp i_e;
        Tpl.Text i_lhsStr;
      equation
        (i_lhsStr, i_preExp, i_varDecls) = scalarLhsCref(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
        txt = fun_463(txt, i_context, i_lhsStr, i_rhsStr, i_t);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_exp as DAE.CREF(componentRef = _)),
           i_rhsStr,
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_exp;
        Tpl.Text i_lhsStr;
      equation
        (i_lhsStr, i_preExp, i_varDecls) = scalarLhsCref(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_lhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeStr(txt, i_rhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.UNARY(exp = (i_e as DAE.CREF(componentRef = _))),
           i_rhsStr,
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
        Tpl.Text i_lhsStr;
      equation
        (i_lhsStr, i_preExp, i_varDecls) = scalarLhsCref(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_lhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = -"));
        txt = Tpl.writeStr(txt, i_rhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end writeLhsCref;

protected function lm_465
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDecls;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDecls) = algStatement(txt, i_stmt, i_context, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_465(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDecls) = lm_465(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_465;

public function algStmtIf
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.STMT_IF(exp = i_exp, statementLst = i_statementLst, else_ = i_else__),
           i_context,
           i_varDecls )
      local
        DAE.Else i_else__;
        list<DAE.Statement> i_statementLst;
        DAE.Exp i_exp;
        Tpl.Text i_condExp;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_condExp, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if ("));
        txt = Tpl.writeText(txt, i_condExp);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls) = lm_465(txt, i_statementLst, i_varDecls, i_context);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("}\n"));
        (txt, i_varDecls) = elseExpr(txt, i_else__, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStmtIf;

public function algStmtFor
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_s as DAE.STMT_FOR(exp = (i_rng as DAE.RANGE(ty = _)))),
           i_context,
           i_varDecls )
      local
        DAE.Exp i_rng;
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtForRange(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_FOR(type_ = _)),
           i_context,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtForGeneric(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStmtFor;

protected function lm_468
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDecls;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDecls) = algStatement(txt, i_stmt, i_context, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_468(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDecls) = lm_468(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_468;

public function algStmtForRange
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.STMT_FOR(exp = (i_rng as DAE.RANGE(ty = _)), type_ = i_type__, iterIsArray = i_iterIsArray, statementLst = i_statementLst, ident = i_ident),
           i_context,
           i_varDecls )
      local
        DAE.Ident i_ident;
        list<DAE.Statement> i_statementLst;
        Boolean i_iterIsArray;
        DAE.ExpType i_type__;
        DAE.Exp i_rng;
        Tpl.Text i_stmtStr;
        Tpl.Text i_identTypeShort;
        Tpl.Text i_identType;
      equation
        i_identType = expType(emptyTxt, i_type__, i_iterIsArray);
        i_identTypeShort = expTypeShort(emptyTxt, i_type__);
        i_stmtStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_stmtStr, i_varDecls) = lm_468(i_stmtStr, i_statementLst, i_varDecls, i_context);
        i_stmtStr = Tpl.popIter(i_stmtStr);
        (txt, i_stmtStr, i_varDecls) = algStmtForRange_impl(txt, i_rng, i_ident, Tpl.textString(i_identType), Tpl.textString(i_identTypeShort), i_stmtStr, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStmtForRange;

protected function fun_470
  input Tpl.Text in_txt;
  input Option<DAE.Exp> in_i_expOption;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_i_expOption, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           SOME(i_eo),
           i_varDecls,
           i_preExp,
           i_context )
      local
        DAE.Exp i_eo;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_eo, i_context, i_preExp, i_varDecls);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _,
           i_varDecls,
           i_preExp,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(1)"));
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_470;

protected function fun_471
  input Tpl.Text in_txt;
  input DAE.Exp in_i_range;
  input Absyn.Ident in_i_iterator;
  input String in_i_type;
  input String in_i_shortType;
  input Tpl.Text in_i_body;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_range, in_i_iterator, in_i_type, in_i_shortType, in_i_body, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      Absyn.Ident i_iterator;
      String i_type;
      String i_shortType;
      Tpl.Text i_body;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.RANGE(exp = i_exp, expOption = i_expOption, range = i_range),
           i_iterator,
           i_type,
           i_shortType,
           i_body,
           i_context,
           i_varDecls )
      local
        DAE.Exp i_range;
        Option<DAE.Exp> i_expOption;
        DAE.Exp i_exp;
        Tpl.Text i_stopValue;
        Tpl.Text i_stepValue;
        Tpl.Text i_startValue;
        Tpl.Text i_preExp;
        Tpl.Text i_stopVar;
        Tpl.Text i_stepVar;
        Tpl.Text i_startVar;
        Tpl.Text i_stateVar;
        Tpl.Text i_iterName;
      equation
        i_iterName = contextIteratorName(emptyTxt, i_iterator, i_context);
        (i_stateVar, i_varDecls) = tempDecl(emptyTxt, "state", i_varDecls);
        (i_startVar, i_varDecls) = tempDecl(emptyTxt, i_type, i_varDecls);
        (i_stepVar, i_varDecls) = tempDecl(emptyTxt, i_type, i_varDecls);
        (i_stopVar, i_varDecls) = tempDecl(emptyTxt, i_type, i_varDecls);
        i_preExp = emptyTxt;
        (i_startValue, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        (i_stepValue, i_varDecls, i_preExp) = fun_470(emptyTxt, i_expOption, i_varDecls, i_preExp, i_context);
        (i_stopValue, i_preExp, i_varDecls) = daeExp(emptyTxt, i_range, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_startVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, i_startValue);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("; "));
        txt = Tpl.writeText(txt, i_stepVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, i_stepValue);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("; "));
        txt = Tpl.writeText(txt, i_stopVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, i_stopValue);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ";\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("for("));
        txt = Tpl.writeStr(txt, i_type);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = Tpl.writeText(txt, i_iterName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, i_startValue);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("; in_range_"));
        txt = Tpl.writeStr(txt, i_shortType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_iterName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_startVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_stopVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("); "));
        txt = Tpl.writeText(txt, i_iterName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" += "));
        txt = Tpl.writeText(txt, i_stepVar);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" = get_memory_state();\n"));
        txt = Tpl.writeText(txt, i_body);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("restore_memory_state("));
        txt = Tpl.writeText(txt, i_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("}\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           _,
           _,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end fun_471;

public function algStmtForRange_impl
  input Tpl.Text txt;
  input DAE.Exp i_range;
  input Absyn.Ident i_iterator;
  input String i_type;
  input String i_shortType;
  input Tpl.Text i_body;
  input SimCode.Context i_context;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_body;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) := fun_471(txt, i_range, i_iterator, i_type, i_shortType, i_body, i_context, i_varDecls);
  out_i_body := i_body;
end algStmtForRange_impl;

protected function lm_473
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDecls;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDecls) = algStatement(txt, i_stmt, i_context, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_473(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDecls) = lm_473(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_473;

public function algStmtForGeneric
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.STMT_FOR(type_ = i_type__, iterIsArray = i_iterIsArray, statementLst = i_statementLst, exp = i_exp, ident = i_ident),
           i_context,
           i_varDecls )
      local
        DAE.Ident i_ident;
        DAE.Exp i_exp;
        list<DAE.Statement> i_statementLst;
        Boolean i_iterIsArray;
        DAE.ExpType i_type__;
        Tpl.Text i_stmtStr;
        Tpl.Text i_arrayType;
        Tpl.Text i_iterType;
      equation
        i_iterType = expType(emptyTxt, i_type__, i_iterIsArray);
        i_arrayType = expTypeArray(emptyTxt, i_type__);
        i_stmtStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_stmtStr, i_varDecls) = lm_473(i_stmtStr, i_statementLst, i_varDecls, i_context);
        i_stmtStr = Tpl.popIter(i_stmtStr);
        (txt, i_stmtStr, i_varDecls) = algStmtForGeneric_impl(txt, i_exp, i_ident, Tpl.textString(i_iterType), Tpl.textString(i_arrayType), i_iterIsArray, i_stmtStr, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStmtForGeneric;

protected function fun_475
  input Tpl.Text in_txt;
  input Boolean in_i_iterIsArray;
  input Tpl.Text in_i_ivar;
  input String in_i_type;
  input Tpl.Text in_i_tvar;
  input Tpl.Text in_i_evar;
  input String in_i_arrayType;
  input Tpl.Text in_i_iterName;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_iterIsArray, in_i_ivar, in_i_type, in_i_tvar, in_i_evar, in_i_arrayType, in_i_iterName)
    local
      Tpl.Text txt;
      Tpl.Text i_ivar;
      String i_type;
      Tpl.Text i_tvar;
      Tpl.Text i_evar;
      String i_arrayType;
      Tpl.Text i_iterName;

    case ( txt,
           false,
           _,
           _,
           i_tvar,
           i_evar,
           i_arrayType,
           i_iterName )
      equation
        txt = Tpl.writeText(txt, i_iterName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = *("));
        txt = Tpl.writeStr(txt, i_arrayType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_element_addr1(&"));
        txt = Tpl.writeText(txt, i_evar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", 1, "));
        txt = Tpl.writeText(txt, i_tvar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("));"));
      then txt;

    case ( txt,
           _,
           i_ivar,
           i_type,
           i_tvar,
           i_evar,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("simple_index_alloc_"));
        txt = Tpl.writeStr(txt, i_type);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("1(&"));
        txt = Tpl.writeText(txt, i_evar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_tvar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeText(txt, i_ivar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;
  end matchcontinue;
end fun_475;

public function algStmtForGeneric_impl
  input Tpl.Text txt;
  input DAE.Exp i_exp;
  input Absyn.Ident i_iterator;
  input String i_type;
  input String i_arrayType;
  input Boolean i_iterIsArray;
  input Tpl.Text i_body;
  input SimCode.Context i_context;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_body;
  output Tpl.Text out_i_varDecls;
protected
  Tpl.Text i_stmtStuff;
  Tpl.Text i_evar;
  Tpl.Text i_preExp;
  Tpl.Text i_ivar;
  Tpl.Text i_tvar;
  Tpl.Text i_stateVar;
  Tpl.Text i_iterName;
algorithm
  i_iterName := contextIteratorName(emptyTxt, i_iterator, i_context);
  (i_stateVar, out_i_varDecls) := tempDecl(emptyTxt, "state", i_varDecls);
  (i_tvar, out_i_varDecls) := tempDecl(emptyTxt, "int", out_i_varDecls);
  (i_ivar, out_i_varDecls) := tempDecl(emptyTxt, i_type, out_i_varDecls);
  i_preExp := emptyTxt;
  (i_evar, i_preExp, out_i_varDecls) := daeExp(emptyTxt, i_exp, i_context, i_preExp, out_i_varDecls);
  i_stmtStuff := fun_475(emptyTxt, i_iterIsArray, i_ivar, i_type, i_tvar, i_evar, i_arrayType, i_iterName);
  out_txt := Tpl.writeText(txt, i_preExp);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE("{\n"));
  out_txt := Tpl.writeStr(out_txt, i_type);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(" "));
  out_txt := Tpl.writeText(out_txt, i_iterName);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       ";\n",
                                       "\n"
                                   }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("for("));
  out_txt := Tpl.writeText(out_txt, i_tvar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(" = 1; "));
  out_txt := Tpl.writeText(out_txt, i_tvar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(" <= size_of_dimension_"));
  out_txt := Tpl.writeStr(out_txt, i_arrayType);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("("));
  out_txt := Tpl.writeText(out_txt, i_evar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(", 1); ++"));
  out_txt := Tpl.writeText(out_txt, i_tvar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE(") {\n"));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_stateVar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE(" = get_memory_state();\n"));
  out_txt := Tpl.writeText(out_txt, i_stmtStuff);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, i_body);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("restore_memory_state("));
  out_txt := Tpl.writeText(out_txt, i_stateVar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE(");\n"));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE("}\n"));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
  out_i_body := i_body;
end algStmtForGeneric_impl;

protected function lm_477
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDecls;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDecls) = algStatement(txt, i_stmt, i_context, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_477(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDecls) = lm_477(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_477;

public function algStmtWhile
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.STMT_WHILE(exp = i_exp, statementLst = i_statementLst),
           i_context,
           i_varDecls )
      local
        list<DAE.Statement> i_statementLst;
        DAE.Exp i_exp;
        Tpl.Text i_var;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_var, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("while (1) {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (!"));
        txt = Tpl.writeText(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") break;\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls) = lm_477(txt, i_statementLst, i_varDecls, i_context);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStmtWhile;

public function algStmtAssert
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.STMT_ASSERT(cond = i_cond, msg = i_msg),
           i_context,
           i_varDecls )
      local
        DAE.Exp i_msg;
        DAE.Exp i_cond;
        Tpl.Text i_msgVar;
        Tpl.Text i_condVar;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_condVar, i_preExp, i_varDecls) = daeExp(emptyTxt, i_cond, i_context, i_preExp, i_varDecls);
        (i_msgVar, i_preExp, i_varDecls) = daeExp(emptyTxt, i_msg, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("MODELICA_ASSERT("));
        txt = Tpl.writeText(txt, i_condVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_msgVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStmtAssert;

protected function fun_480
  input Tpl.Text in_txt;
  input Absyn.MatchType in_i_matchType;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_matchType)
    local
      Tpl.Text txt;

    case ( txt,
           Absyn.MATCHCONTINUE() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("try { /* matchcontinue */"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("{"));
      then txt;
  end matchcontinue;
end fun_480;

protected function lm_481
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_doneVar;
  input Tpl.Text in_i_varDecls;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_doneVar, in_i_varDecls, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_doneVar;
      Tpl.Text i_varDecls;
      SimCode.Context i_context;

    case ( txt,
           {},
           _,
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           i_e :: rest,
           i_doneVar,
           i_varDecls,
           i_context )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_e;
        Integer i_i0;
        Tpl.Text i_0__;
        Tpl.Text i_preExp;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        i_preExp = emptyTxt;
        (i_0__, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("case "));
        txt = Tpl.writeStr(txt, intString(i_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(": {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_doneVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " = 1;\n",
                                    "break;\n"
                                }, true));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("};"));
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_481(txt, rest, i_doneVar, i_varDecls, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_doneVar,
           i_varDecls,
           i_context )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls) = lm_481(txt, rest, i_doneVar, i_varDecls, i_context);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_481;

protected function fun_482
  input Tpl.Text in_txt;
  input Absyn.MatchType in_i_matchType;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_matchType)
    local
      Tpl.Text txt;

    case ( txt,
           Absyn.MATCHCONTINUE() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "} catch (int i) { /* matchcontinue */\n",
                                    "}"
                                }, false));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then txt;
  end matchcontinue;
end fun_482;

public function algStmtMatchcases
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.STMT_MATCHCASES(caseStmt = i_caseStmt, matchType = i_matchType),
           i_context,
           i_varDecls )
      local
        Absyn.MatchType i_matchType;
        list<DAE.Exp> i_caseStmt;
        Integer ret_3;
        Tpl.Text i_numCases;
        Tpl.Text i_doneVar;
        Tpl.Text i_loopVar;
      equation
        (i_loopVar, i_varDecls) = tempDecl(emptyTxt, "modelica_integer", i_varDecls);
        (i_doneVar, i_varDecls) = tempDecl(emptyTxt, "modelica_integer", i_varDecls);
        ret_3 = listLength(i_caseStmt);
        i_numCases = Tpl.writeStr(emptyTxt, intString(ret_3));
        txt = Tpl.writeText(txt, i_doneVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " = 0;\n",
                                    "for ("
                                }, false));
        txt = Tpl.writeText(txt, i_loopVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("=0; 0=="));
        txt = Tpl.writeText(txt, i_doneVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" && "));
        txt = Tpl.writeText(txt, i_loopVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("<"));
        txt = Tpl.writeText(txt, i_numCases);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("; "));
        txt = Tpl.writeText(txt, i_loopVar);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("++) {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = fun_480(txt, i_matchType);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("switch ("));
        txt = Tpl.writeText(txt, i_loopVar);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls) = lm_481(txt, i_caseStmt, i_doneVar, i_varDecls, i_context);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("} /* end match switch */\n"));
        txt = Tpl.popBlock(txt);
        txt = fun_482(txt, i_matchType);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "} /* end match for */\n",
                                    "if (0 == "
                                }, false));
        txt = Tpl.writeText(txt, i_doneVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(") throw 1; /* Didn\'t end in a valid state */"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStmtMatchcases;

protected function lm_484
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDecls;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDecls) = algStatement(txt, i_stmt, i_context, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_484(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDecls) = lm_484(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_484;

public function algStmtTry
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.STMT_TRY(tryBody = i_tryBody),
           i_context,
           i_varDecls )
      local
        list<DAE.Statement> i_tryBody;
        Tpl.Text i_body;
      equation
        i_body = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_body, i_varDecls) = lm_484(i_body, i_tryBody, i_varDecls, i_context);
        i_body = Tpl.popIter(i_body);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("try {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_body);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStmtTry;

protected function lm_486
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDecls;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDecls) = algStatement(txt, i_stmt, i_context, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_486(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDecls) = lm_486(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_486;

public function algStmtCatch
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.STMT_CATCH(catchBody = i_catchBody),
           i_context,
           i_varDecls )
      local
        list<DAE.Statement> i_catchBody;
        Tpl.Text i_body;
      equation
        i_body = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_body, i_varDecls) = lm_486(i_body, i_catchBody, i_varDecls, i_context);
        i_body = Tpl.popIter(i_body);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("catch (int i) {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_body);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStmtCatch;

public function algStmtNoretcall
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.STMT_NORETCALL(exp = i_exp),
           i_context,
           i_varDecls )
      local
        DAE.Exp i_exp;
        Tpl.Text i_expPart;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStmtNoretcall;

protected function lm_489
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDecls;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDecls) = algStatement(txt, i_stmt, i_context, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_489(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDecls) = lm_489(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_489;

protected function lm_490
  input Tpl.Text in_txt;
  input list<Integer> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_idx :: rest )
      local
        list<Integer> rest;
        Integer i_idx;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("edge(localData->helpVars["));
        txt = Tpl.writeStr(txt, intString(i_idx));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("])"));
        txt = Tpl.nextIter(txt);
        txt = lm_490(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<Integer> rest;
      equation
        txt = lm_490(txt, rest);
      then txt;
  end matchcontinue;
end lm_490;

protected function fun_491
  input Tpl.Text in_txt;
  input DAE.Statement in_i_when;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_when, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_when as DAE.STMT_WHEN(statementLst = i_statementLst, elseWhen = i_elseWhen, helpVarIndices = i_helpVarIndices)),
           i_context,
           i_varDecls )
      local
        list<Integer> i_helpVarIndices;
        Option<DAE.Statement> i_elseWhen;
        list<DAE.Statement> i_statementLst;
        DAE.Statement i_when;
        Tpl.Text i_else;
        Tpl.Text i_statements;
        Tpl.Text i_preIf;
      equation
        (i_preIf, i_varDecls) = algStatementWhenPre(emptyTxt, i_when, i_varDecls);
        i_statements = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_statements, i_varDecls) = lm_489(i_statements, i_statementLst, i_varDecls, i_context);
        i_statements = Tpl.popIter(i_statements);
        (i_else, i_varDecls) = algStatementWhenElse(emptyTxt, i_elseWhen, i_varDecls);
        txt = Tpl.writeText(txt, i_preIf);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if ("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(" || ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_490(txt, i_helpVarIndices);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_statements);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("}\n"));
        txt = Tpl.writeText(txt, i_else);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end fun_491;

protected function fun_492
  input Tpl.Text in_txt;
  input SimCode.Context in_i_context;
  input DAE.Statement in_i_when;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_context, in_i_when, in_i_varDecls)
    local
      Tpl.Text txt;
      DAE.Statement i_when;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_context as SimCode.SIMULATION(genDiscrete = true)),
           i_when,
           i_varDecls )
      local
        SimCode.Context i_context;
      equation
        (txt, i_varDecls) = fun_491(txt, i_when, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end fun_492;

public function algStmtWhen
  input Tpl.Text txt;
  input DAE.Statement i_when;
  input SimCode.Context i_context;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) := fun_492(txt, i_context, i_when, i_varDecls);
end algStmtWhen;

protected function fun_494
  input Tpl.Text in_txt;
  input Option<DAE.Statement> in_i_elseWhen;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_elseWhen, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           SOME(i_ew),
           i_varDecls )
      local
        DAE.Statement i_ew;
      equation
        (txt, i_varDecls) = algStatementWhenPre(txt, i_ew, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end fun_494;

protected function fun_495
  input Tpl.Text in_txt;
  input Option<DAE.Statement> in_i_when_elseWhen;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_when_elseWhen, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           SOME(i_ew),
           i_varDecls )
      local
        DAE.Statement i_ew;
      equation
        (txt, i_varDecls) = algStatementWhenPre(txt, i_ew, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end fun_495;

protected function fun_496
  input Tpl.Text in_txt;
  input list<Integer> in_i_helpVarIndices;
  input DAE.Exp in_i_when_exp;
  input Tpl.Text in_i_varDecls;
  input Option<DAE.Statement> in_i_when_elseWhen;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_helpVarIndices, in_i_when_exp, in_i_varDecls, in_i_when_elseWhen)
    local
      Tpl.Text txt;
      DAE.Exp i_when_exp;
      Tpl.Text i_varDecls;
      Option<DAE.Statement> i_when_elseWhen;

    case ( txt,
           {i_i},
           i_when_exp,
           i_varDecls,
           i_when_elseWhen )
      local
        Integer i_i;
        Tpl.Text i_res;
        Tpl.Text i_preExp;
        Tpl.Text i_restPre;
      equation
        (i_restPre, i_varDecls) = fun_495(emptyTxt, i_when_elseWhen, i_varDecls);
        i_preExp = emptyTxt;
        (i_res, i_preExp, i_varDecls) = daeExp(emptyTxt, i_when_exp, SimCode.contextSimulationDiscrete, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("localData->helpVars["));
        txt = Tpl.writeStr(txt, intString(i_i));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = "));
        txt = Tpl.writeText(txt, i_res);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        txt = Tpl.writeText(txt, i_restPre);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls,
           _ )
      then (txt, i_varDecls);
  end matchcontinue;
end fun_496;

public function algStatementWhenPre
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.STMT_WHEN(exp = DAE.ARRAY(array = i_el), elseWhen = i_elseWhen, helpVarIndices = i_helpVarIndices),
           i_varDecls )
      local
        list<Integer> i_helpVarIndices;
        Option<DAE.Statement> i_elseWhen;
        list<DAE.Exp> i_el;
        Tpl.Text i_assignments;
        Tpl.Text i_preExp;
        Tpl.Text i_restPre;
      equation
        (i_restPre, i_varDecls) = fun_494(emptyTxt, i_elseWhen, i_varDecls);
        i_preExp = emptyTxt;
        (i_assignments, i_preExp, i_varDecls) = algStatementWhenPreAssigns(emptyTxt, i_el, i_helpVarIndices, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_assignments);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_restPre);
      then (txt, i_varDecls);

    case ( txt,
           (i_when as DAE.STMT_WHEN(helpVarIndices = i_helpVarIndices, elseWhen = i_when_elseWhen, exp = i_when_exp)),
           i_varDecls )
      local
        DAE.Exp i_when_exp;
        Option<DAE.Statement> i_when_elseWhen;
        list<Integer> i_helpVarIndices;
        DAE.Statement i_when;
      equation
        (txt, i_varDecls) = fun_496(txt, i_helpVarIndices, i_when_exp, i_varDecls, i_when_elseWhen);
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStatementWhenPre;

protected function lm_498
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDecls) = algStatement(txt, i_stmt, SimCode.contextSimulationDiscrete, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_498(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDecls) = lm_498(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_498;

protected function lm_499
  input Tpl.Text in_txt;
  input list<Integer> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_idx :: rest )
      local
        list<Integer> rest;
        Integer i_idx;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("edge(localData->helpVars["));
        txt = Tpl.writeStr(txt, intString(i_idx));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("])"));
        txt = Tpl.nextIter(txt);
        txt = lm_499(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<Integer> rest;
      equation
        txt = lm_499(txt, rest);
      then txt;
  end matchcontinue;
end lm_499;

public function algStatementWhenElse
  input Tpl.Text in_txt;
  input Option<DAE.Statement> in_i_stmt;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           SOME((i_when as DAE.STMT_WHEN(statementLst = i_when_statementLst, elseWhen = i_when_elseWhen, helpVarIndices = i_when_helpVarIndices))),
           i_varDecls )
      local
        list<Integer> i_when_helpVarIndices;
        Option<DAE.Statement> i_when_elseWhen;
        list<DAE.Statement> i_when_statementLst;
        DAE.Statement i_when;
        Tpl.Text i_elseCondStr;
        Tpl.Text i_else;
        Tpl.Text i_statements;
      equation
        i_statements = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_statements, i_varDecls) = lm_498(i_statements, i_when_statementLst, i_varDecls);
        i_statements = Tpl.popIter(i_statements);
        (i_else, i_varDecls) = algStatementWhenElse(emptyTxt, i_when_elseWhen, i_varDecls);
        i_elseCondStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(" || ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        i_elseCondStr = lm_499(i_elseCondStr, i_when_helpVarIndices);
        i_elseCondStr = Tpl.popIter(i_elseCondStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("else if ("));
        txt = Tpl.writeText(txt, i_elseCondStr);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_statements);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("}\n"));
        txt = Tpl.writeText(txt, i_else);
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStatementWhenElse;

protected function fun_501
  input Tpl.Text in_txt;
  input list<Integer> in_i_ints;
  input DAE.Exp in_i_firstExp;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input list<DAE.Exp> in_i_restExps;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_i_ints, in_i_firstExp, in_i_varDecls, in_i_preExp, in_i_restExps)
    local
      Tpl.Text txt;
      DAE.Exp i_firstExp;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      list<DAE.Exp> i_restExps;

    case ( txt,
           i_firstInt :: i_restInts,
           i_firstExp,
           i_varDecls,
           i_preExp,
           i_restExps )
      local
        list<Integer> i_restInts;
        Integer i_firstInt;
        Tpl.Text i_firstExpPart;
        Tpl.Text i_rest;
      equation
        (i_rest, i_preExp, i_varDecls) = algStatementWhenPreAssigns(emptyTxt, i_restExps, i_restInts, i_preExp, i_varDecls);
        (i_firstExpPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_firstExp, SimCode.contextSimulationDiscrete, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("localData->helpVars["));
        txt = Tpl.writeStr(txt, intString(i_firstInt));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = "));
        txt = Tpl.writeText(txt, i_firstExpPart);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        txt = Tpl.writeText(txt, i_rest);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _,
           _,
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_501;

public function algStatementWhenPreAssigns
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_i_exps;
  input list<Integer> in_i_ints;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exps, in_i_ints, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      list<Integer> i_ints;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           i_firstExp :: i_restExps,
           i_ints,
           i_preExp,
           i_varDecls )
      local
        list<DAE.Exp> i_restExps;
        DAE.Exp i_firstExp;
      equation
        (txt, i_varDecls, i_preExp) = fun_501(txt, i_ints, i_firstExp, i_varDecls, i_preExp, i_restExps);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end algStatementWhenPreAssigns;

public function indexSpecFromCref
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_i_cr;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_cr, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.CREF_IDENT(subscriptLst = (i_subs as _ :: _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        list<DAE.Subscript> i_subs;
      equation
        (txt, i_preExp, i_varDecls) = daeExpCrefRhsIndexSpec(txt, i_subs, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end indexSpecFromCref;

protected function lm_504
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDecls;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDecls) = algStatement(txt, i_stmt, i_context, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_504(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDecls) = lm_504(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_504;

protected function lm_505
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDecls;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDecls) = algStatement(txt, i_stmt, i_context, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_505(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDecls) = lm_505(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_505;

public function elseExpr
  input Tpl.Text in_txt;
  input DAE.Else in_i_else__;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_else__, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.NOELSE(),
           _,
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           DAE.ELSEIF(exp = i_exp, statementLst = i_statementLst, else_ = i_else__),
           i_context,
           i_varDecls )
      local
        DAE.Else i_else__;
        list<DAE.Statement> i_statementLst;
        DAE.Exp i_exp;
        Tpl.Text i_condExp;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_condExp, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("else {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if ("));
        txt = Tpl.writeText(txt, i_condExp);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls) = lm_504(txt, i_statementLst, i_varDecls, i_context);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("}\n"));
        (txt, i_varDecls) = elseExpr(txt, i_else__, i_context, i_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then (txt, i_varDecls);

    case ( txt,
           DAE.ELSE(statementLst = i_statementLst),
           i_context,
           i_varDecls )
      local
        list<DAE.Statement> i_statementLst;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("else {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls) = lm_505(txt, i_statementLst, i_varDecls, i_context);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end elseExpr;

protected function fun_507
  input Tpl.Text in_txt;
  input Boolean in_it;
  input DAE.ComponentRef in_i_ecr_componentRef;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;
  input DAE.Exp in_i_ecr;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_it, in_i_ecr_componentRef, in_i_varDecls, in_i_preExp, in_i_context, in_i_ecr)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_ecr_componentRef;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;
      DAE.Exp i_ecr;

    case ( txt,
           false,
           _,
           i_varDecls,
           i_preExp,
           i_context,
           i_ecr )
      equation
        (txt, i_preExp, i_varDecls) = daeExpCrefRhs(txt, i_ecr, i_context, i_preExp, i_varDecls);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _,
           i_ecr_componentRef,
           i_varDecls,
           i_preExp,
           i_context,
           _ )
      equation
        txt = contextCref(txt, i_ecr_componentRef, i_context);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_507;

public function scalarLhsCref
  input Tpl.Text in_txt;
  input DAE.Exp in_i_ecr;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_ecr, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.CREF(componentRef = i_cr, ty = DAE.ET_FUNCTION_REFERENCE_VAR()),
           _,
           i_preExp,
           i_varDecls )
      local
        DAE.ComponentRef i_cr;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("*((modelica_fnptr*)&_"));
        txt = functionName(txt, i_cr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_ecr as DAE.CREF(componentRef = (i_ecr_componentRef as DAE.CREF_IDENT(ident = _)))),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.ComponentRef i_ecr_componentRef;
        DAE.Exp i_ecr;
        Boolean ret_0;
      equation
        ret_0 = SimCode.crefNoSub(i_ecr_componentRef);
        (txt, i_varDecls, i_preExp) = fun_507(txt, ret_0, i_ecr_componentRef, i_varDecls, i_preExp, i_context, i_ecr);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_ecr as DAE.CREF(componentRef = (i_ecr_componentRef as DAE.CREF_QUAL(ident = _)))),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.ComponentRef i_ecr_componentRef;
        DAE.Exp i_ecr;
      equation
        txt = contextCref(txt, i_ecr_componentRef, i_context);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("ONLY_IDENT_OR_QUAL_CREF_SUPPORTED_SLHS"));
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end scalarLhsCref;

public function rhsCref
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_i_cr;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_cr, in_i_ty)
    local
      Tpl.Text txt;
      DAE.ExpType i_ty;

    case ( txt,
           DAE.CREF_IDENT(ident = i_ident),
           i_ty )
      local
        DAE.Ident i_ident;
      equation
        txt = rhsCrefType(txt, i_ty);
        txt = Tpl.writeStr(txt, i_ident);
      then txt;

    case ( txt,
           DAE.CREF_QUAL(ident = i_ident, componentRef = i_componentRef),
           i_ty )
      local
        DAE.ComponentRef i_componentRef;
        DAE.Ident i_ident;
      equation
        txt = rhsCrefType(txt, i_ty);
        txt = Tpl.writeStr(txt, i_ident);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = rhsCref(txt, i_componentRef, i_ty);
      then txt;

    case ( txt,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("rhsCref:ERROR"));
      then txt;
  end matchcontinue;
end rhsCref;

public function rhsCrefType
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_INT() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(modelica_integer)"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end rhsCrefType;

protected function fun_511
  input Tpl.Text in_txt;
  input Boolean in_i_bool;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_bool)
    local
      Tpl.Text txt;

    case ( txt,
           false )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(0)"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(1)"));
      then txt;
  end matchcontinue;
end fun_511;

public function daeExp
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_e as DAE.ICONST(integer = i_integer)),
           _,
           i_preExp,
           i_varDecls )
      local
        Integer i_integer;
        DAE.Exp i_e;
      equation
        txt = Tpl.writeStr(txt, intString(i_integer));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.RCONST(real = i_real)),
           _,
           i_preExp,
           i_varDecls )
      local
        Real i_real;
        DAE.Exp i_e;
      equation
        txt = Tpl.writeStr(txt, realString(i_real));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.SCONST(string = i_string)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        String i_string;
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpSconst(txt, i_string, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.BCONST(bool = i_bool)),
           _,
           i_preExp,
           i_varDecls )
      local
        Boolean i_bool;
        DAE.Exp i_e;
      equation
        txt = fun_511(txt, i_bool);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.ENUM_LITERAL(index = i_index)),
           _,
           i_preExp,
           i_varDecls )
      local
        Integer i_index;
        DAE.Exp i_e;
      equation
        txt = Tpl.writeStr(txt, intString(i_index));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.CREF(componentRef = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpCrefRhs(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.BINARY(exp1 = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpBinary(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.UNARY(operator = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpUnary(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.LBINARY(exp1 = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpLbinary(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.LUNARY(operator = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpLunary(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.RELATION(exp1 = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpRelation(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.IFEXP(expCond = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpIf(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.CALL(path = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpCall(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.ARRAY(ty = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpArray(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.MATRIX(ty = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpMatrix(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.CAST(ty = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpCast(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.ASUB(exp = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpAsub(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.SIZE(exp = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpSize(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.REDUCTION(path = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpReduction(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.VALUEBLOCK(ty = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpValueblock(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.LIST(ty = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpList(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.CONS(ty = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpCons(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.META_TUPLE(listExp = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpMetaTuple(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.META_OPTION(exp = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpMetaOption(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.METARECORDCALL(path = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpMetarecordcall(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("UNKNOWN_EXP"));
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExp;

public function daeExpSconst
  input Tpl.Text txt;
  input String i_string;
  input SimCode.Context i_context;
  input Tpl.Text i_preExp;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
protected
  Tpl.Text i_strVar;
  String ret_1;
  Tpl.Text i_escapedStr;
algorithm
  i_escapedStr := Tpl.writeTok(emptyTxt, Tpl.ST_STRING("\""));
  ret_1 := Util.escapeModelicaStringToCString(i_string);
  i_escapedStr := Tpl.writeStr(i_escapedStr, ret_1);
  i_escapedStr := Tpl.writeTok(i_escapedStr, Tpl.ST_STRING("\""));
  (i_strVar, out_i_varDecls) := tempDecl(emptyTxt, "modelica_string", i_varDecls);
  out_i_preExp := Tpl.writeTok(i_preExp, Tpl.ST_STRING("init_modelica_string(&"));
  out_i_preExp := Tpl.writeText(out_i_preExp, i_strVar);
  out_i_preExp := Tpl.writeTok(out_i_preExp, Tpl.ST_STRING(","));
  out_i_preExp := Tpl.writeText(out_i_preExp, i_escapedStr);
  out_i_preExp := Tpl.writeTok(out_i_preExp, Tpl.ST_STRING(");"));
  out_i_preExp := Tpl.writeTok(out_i_preExp, Tpl.ST_NEW_LINE());
  out_txt := Tpl.writeText(txt, i_strVar);
end daeExpSconst;

protected function fun_514
  input Tpl.Text in_txt;
  input SimCode.Context in_i_context;
  input DAE.ComponentRef in_i_cr;
  input DAE.ExpType in_i_t;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input DAE.Exp in_i_exp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_i_context, in_i_cr, in_i_t, in_i_varDecls, in_i_preExp, in_i_exp)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_cr;
      DAE.ExpType i_t;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      DAE.Exp i_exp;

    case ( txt,
           (i_context as SimCode.FUNCTION_CONTEXT()),
           _,
           _,
           i_varDecls,
           i_preExp,
           i_exp )
      local
        SimCode.Context i_context;
      equation
        (txt, i_preExp, i_varDecls) = daeExpCrefRhs2(txt, i_exp, i_context, i_preExp, i_varDecls);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_context,
           i_cr,
           i_t,
           i_varDecls,
           i_preExp,
           _ )
      local
        SimCode.Context i_context;
      equation
        (txt, i_preExp, i_varDecls) = daeExpRecordCrefRhs(txt, i_t, i_cr, i_context, i_preExp, i_varDecls);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_514;

public function daeExpCrefRhs
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_exp as DAE.CREF(componentRef = i_cr, ty = (i_t as DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(path = _))))),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_t;
        DAE.ComponentRef i_cr;
        DAE.Exp i_exp;
      equation
        (txt, i_varDecls, i_preExp) = fun_514(txt, i_context, i_cr, i_t, i_varDecls, i_preExp, i_exp);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CREF(componentRef = i_cr, ty = DAE.ET_FUNCTION_REFERENCE_FUNC(builtin = _)),
           _,
           i_preExp,
           i_varDecls )
      local
        DAE.ComponentRef i_cr;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(modelica_fnptr)boxptr_"));
        txt = functionName(txt, i_cr);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CREF(componentRef = i_cr, ty = DAE.ET_FUNCTION_REFERENCE_VAR()),
           _,
           i_preExp,
           i_varDecls )
      local
        DAE.ComponentRef i_cr;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(modelica_fnptr) _"));
        txt = functionName(txt, i_cr);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           i_exp,
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExpCrefRhs2(txt, i_exp, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpCrefRhs;

protected function lm_516
  input Tpl.Text in_txt;
  input list<DAE.Subscript> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           DAE.INDEX(exp = i_exp) :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Subscript> rest;
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_516(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Subscript> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_516(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_516;

protected function fun_517
  input Tpl.Text in_txt;
  input Boolean in_it;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;
  input DAE.ExpType in_i_ty;
  input SimCode.Context in_i_context;
  input DAE.ComponentRef in_i_cr;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_it, in_i_preExp, in_i_varDecls, in_i_ty, in_i_context, in_i_cr)
    local
      Tpl.Text txt;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;
      DAE.ExpType i_ty;
      SimCode.Context i_context;
      DAE.ComponentRef i_cr;

    case ( txt,
           false,
           i_preExp,
           i_varDecls,
           i_ty,
           i_context,
           i_cr )
      local
        list<DAE.Subscript> ret_4;
        Tpl.Text i_spec1;
        Tpl.Text i_tmp;
        Tpl.Text i_arrayType;
        Tpl.Text i_arrName;
      equation
        i_arrName = contextArrayCref(emptyTxt, i_cr, i_context);
        i_arrayType = expTypeArray(emptyTxt, i_ty);
        (i_tmp, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_arrayType), i_varDecls);
        ret_4 = SimCode.crefSubs(i_cr);
        (i_spec1, i_preExp, i_varDecls) = daeExpCrefRhsIndexSpec(emptyTxt, ret_4, i_context, i_preExp, i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("index_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_arrayType);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(&"));
        i_preExp = Tpl.writeText(i_preExp, i_arrName);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_spec1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_tmp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tmp);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_preExp,
           i_varDecls,
           i_ty,
           i_context,
           i_cr )
      local
        list<DAE.Subscript> ret_7;
        Tpl.Text i_dimsValuesStr;
        Integer ret_5;
        list<DAE.Subscript> ret_4;
        Tpl.Text i_dimsLenStr;
        Tpl.Text i_arrayType;
        DAE.ComponentRef ret_1;
        Tpl.Text i_arrName;
      equation
        ret_1 = Exp.crefStripLastSubs(i_cr);
        i_arrName = contextCref(emptyTxt, ret_1, i_context);
        i_arrayType = expTypeArray(emptyTxt, i_ty);
        ret_4 = SimCode.crefSubs(i_cr);
        ret_5 = listLength(ret_4);
        i_dimsLenStr = Tpl.writeStr(emptyTxt, intString(ret_5));
        ret_7 = SimCode.crefSubs(i_cr);
        i_dimsValuesStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_dimsValuesStr, i_varDecls, i_preExp) = lm_516(i_dimsValuesStr, ret_7, i_varDecls, i_preExp, i_context);
        i_dimsValuesStr = Tpl.popIter(i_dimsValuesStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(*"));
        txt = Tpl.writeText(txt, i_arrayType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_element_addr(&"));
        txt = Tpl.writeText(txt, i_arrName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_dimsLenStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_dimsValuesStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("))"));
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end fun_517;

protected function fun_518
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_INT() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(modelica_integer)"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_518;

protected function fun_519
  input Tpl.Text in_txt;
  input Boolean in_it;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;
  input DAE.ExpType in_i_ty;
  input SimCode.Context in_i_context;
  input DAE.ComponentRef in_i_cr;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_it, in_i_preExp, in_i_varDecls, in_i_ty, in_i_context, in_i_cr)
    local
      Tpl.Text txt;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;
      DAE.ExpType i_ty;
      SimCode.Context i_context;
      DAE.ComponentRef i_cr;

    case ( txt,
           false,
           i_preExp,
           i_varDecls,
           i_ty,
           i_context,
           i_cr )
      local
        Boolean ret_0;
      equation
        ret_0 = SimCode.crefSubIsScalar(i_cr);
        (txt, i_preExp, i_varDecls) = fun_517(txt, ret_0, i_preExp, i_varDecls, i_ty, i_context, i_cr);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_preExp,
           i_varDecls,
           i_ty,
           i_context,
           i_cr )
      local
        Tpl.Text i_cast;
      equation
        i_cast = fun_518(emptyTxt, i_ty);
        txt = Tpl.writeText(txt, i_cast);
        txt = contextCref(txt, i_cr, i_context);
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end fun_519;

protected function fun_520
  input Tpl.Text in_txt;
  input String in_it;
  input Tpl.Text in_i_box;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;
  input DAE.ExpType in_i_ty;
  input SimCode.Context in_i_context;
  input DAE.ComponentRef in_i_cr;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_it, in_i_box, in_i_preExp, in_i_varDecls, in_i_ty, in_i_context, in_i_cr)
    local
      Tpl.Text txt;
      Tpl.Text i_box;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;
      DAE.ExpType i_ty;
      SimCode.Context i_context;
      DAE.ComponentRef i_cr;

    case ( txt,
           "",
           _,
           i_preExp,
           i_varDecls,
           i_ty,
           i_context,
           i_cr )
      local
        Boolean ret_0;
      equation
        ret_0 = SimCode.crefIsScalar(i_cr, i_context);
        (txt, i_preExp, i_varDecls) = fun_519(txt, ret_0, i_preExp, i_varDecls, i_ty, i_context, i_cr);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_box,
           i_preExp,
           i_varDecls,
           _,
           _,
           _ )
      equation
        txt = Tpl.writeText(txt, i_box);
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end fun_520;

public function daeExpCrefRhs2
  input Tpl.Text in_txt;
  input DAE.Exp in_i_ecr;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_ecr, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_ecr as DAE.CREF(componentRef = i_cr, ty = i_ty)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_ty;
        DAE.ComponentRef i_cr;
        DAE.Exp i_ecr;
        String str_1;
        Tpl.Text i_box;
      equation
        (i_box, i_preExp, i_varDecls) = daeExpCrefRhsArrayBox(emptyTxt, i_ecr, i_context, i_preExp, i_varDecls);
        str_1 = Tpl.textString(i_box);
        (txt, i_preExp, i_varDecls) = fun_520(txt, str_1, i_box, i_preExp, i_varDecls, i_ty, i_context, i_cr);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpCrefRhs2;

protected function fun_522
  input Tpl.Text in_txt;
  input DAE.Subscript in_i_sub;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_i_sub, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           DAE.INDEX(exp = i_exp),
           i_varDecls,
           i_preExp,
           i_context )
      local
        DAE.Exp i_exp;
        Tpl.Text i_expPart;
      equation
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(0), make_index_array(1, "));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("), \'S\'"));
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           DAE.WHOLEDIM(),
           i_varDecls,
           i_preExp,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(1), (int*)0, \'W\'"));
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           DAE.SLICE(exp = i_exp),
           i_varDecls,
           i_preExp,
           i_context )
      local
        DAE.Exp i_exp;
        Tpl.Text i_tmp;
        Tpl.Text i_expPart;
      equation
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        (i_tmp, i_varDecls) = tempDecl(emptyTxt, "modelica_integer", i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_tmp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = size_of_dimension_integer_array("));
        i_preExp = Tpl.writeText(i_preExp, i_expPart);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", 1);"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tmp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", integer_array_make_index_array(&"));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("), \'A\'"));
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _,
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_522;

protected function lm_523
  input Tpl.Text in_txt;
  input list<DAE.Subscript> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_sub :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Subscript> rest;
        DAE.Subscript i_sub;
      equation
        (txt, i_varDecls, i_preExp) = fun_522(txt, i_sub, i_varDecls, i_preExp, i_context);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_523(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Subscript> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_523(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_523;

public function daeExpCrefRhsIndexSpec
  input Tpl.Text txt;
  input list<DAE.Subscript> i_subs;
  input SimCode.Context i_context;
  input Tpl.Text i_preExp;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
protected
  Tpl.Text i_tmp;
  Tpl.Text i_idx__str;
  Integer ret_1;
  Tpl.Text i_nridx__str;
algorithm
  ret_1 := listLength(i_subs);
  i_nridx__str := Tpl.writeStr(emptyTxt, intString(ret_1));
  i_idx__str := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_idx__str, out_i_varDecls, out_i_preExp) := lm_523(i_idx__str, i_subs, i_varDecls, i_preExp, i_context);
  i_idx__str := Tpl.popIter(i_idx__str);
  (i_tmp, out_i_varDecls) := tempDecl(emptyTxt, "index_spec_t", out_i_varDecls);
  out_i_preExp := Tpl.writeTok(out_i_preExp, Tpl.ST_STRING("create_index_spec(&"));
  out_i_preExp := Tpl.writeText(out_i_preExp, i_tmp);
  out_i_preExp := Tpl.writeTok(out_i_preExp, Tpl.ST_STRING(", "));
  out_i_preExp := Tpl.writeText(out_i_preExp, i_nridx__str);
  out_i_preExp := Tpl.writeTok(out_i_preExp, Tpl.ST_STRING(", "));
  out_i_preExp := Tpl.writeText(out_i_preExp, i_idx__str);
  out_i_preExp := Tpl.writeTok(out_i_preExp, Tpl.ST_STRING(");"));
  out_i_preExp := Tpl.writeTok(out_i_preExp, Tpl.ST_NEW_LINE());
  out_txt := Tpl.writeText(txt, i_tmp);
end daeExpCrefRhsIndexSpec;

protected function lm_525
  input Tpl.Text in_txt;
  input list<DAE.Dimension> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_dim :: rest )
      local
        list<DAE.Dimension> rest;
        DAE.Dimension i_dim;
      equation
        txt = dimension(txt, i_dim);
        txt = Tpl.nextIter(txt);
        txt = lm_525(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<DAE.Dimension> rest;
      equation
        txt = lm_525(txt, rest);
      then txt;
  end matchcontinue;
end lm_525;

protected function fun_526
  input Tpl.Text in_txt;
  input SimCode.Context in_i_context;
  input DAE.ComponentRef in_i_ecr_componentRef;
  input Tpl.Text in_i_preExp;
  input list<DAE.Dimension> in_i_dims;
  input Tpl.Text in_i_varDecls;
  input DAE.ExpType in_i_aty;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_context, in_i_ecr_componentRef, in_i_preExp, in_i_dims, in_i_varDecls, in_i_aty)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_ecr_componentRef;
      Tpl.Text i_preExp;
      list<DAE.Dimension> i_dims;
      Tpl.Text i_varDecls;
      DAE.ExpType i_aty;

    case ( txt,
           SimCode.FUNCTION_CONTEXT(),
           _,
           i_preExp,
           _,
           i_varDecls,
           _ )
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_ecr_componentRef,
           i_preExp,
           i_dims,
           i_varDecls,
           i_aty )
      local
        Tpl.Text i_dimsValuesStr;
        Integer ret_3;
        Tpl.Text i_dimsLenStr;
        Tpl.Text txt_1;
        Tpl.Text i_tmpArr;
      equation
        txt_1 = expTypeArray(emptyTxt, i_aty);
        (i_tmpArr, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(txt_1), i_varDecls);
        ret_3 = listLength(i_dims);
        i_dimsLenStr = Tpl.writeStr(emptyTxt, intString(ret_3));
        i_dimsValuesStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        i_dimsValuesStr = lm_525(i_dimsValuesStr, i_dims);
        i_dimsValuesStr = Tpl.popIter(i_dimsValuesStr);
        i_preExp = expTypeShort(i_preExp, i_aty);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("_array_create(&"));
        i_preExp = Tpl.writeText(i_preExp, i_tmpArr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = arrayCrefCStr(i_preExp, i_ecr_componentRef);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_dimsLenStr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_dimsValuesStr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tmpArr);
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end fun_526;

public function daeExpCrefRhsArrayBox
  input Tpl.Text in_txt;
  input DAE.Exp in_i_ecr;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_ecr, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_ecr as DAE.CREF(ty = DAE.ET_ARRAY(ty = i_aty, arrayDimensions = i_dims), componentRef = i_ecr_componentRef)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.ComponentRef i_ecr_componentRef;
        list<DAE.Dimension> i_dims;
        DAE.ExpType i_aty;
        DAE.Exp i_ecr;
      equation
        (txt, i_preExp, i_varDecls) = fun_526(txt, i_context, i_ecr_componentRef, i_preExp, i_dims, i_varDecls, i_aty);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpCrefRhsArrayBox;

protected function lm_528
  input Tpl.Text in_txt;
  input list<DAE.ExpVar> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;
  input DAE.ComponentRef in_i_cr;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp, in_i_context, in_i_cr)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;
      DAE.ComponentRef i_cr;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_v :: rest,
           i_varDecls,
           i_preExp,
           i_context,
           i_cr )
      local
        list<DAE.ExpVar> rest;
        DAE.ExpVar i_v;
        DAE.Exp ret_0;
      equation
        ret_0 = SimCode.makeCrefRecordExp(i_cr, i_v);
        (txt, i_preExp, i_varDecls) = daeExp(txt, ret_0, i_context, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_528(txt, rest, i_varDecls, i_preExp, i_context, i_cr);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp,
           i_context,
           i_cr )
      local
        list<DAE.ExpVar> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_528(txt, rest, i_varDecls, i_preExp, i_context, i_cr);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_528;

public function daeExpRecordCrefRhs
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;
  input DAE.ComponentRef in_i_cr;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_ty, in_i_cr, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_cr;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.ET_COMPLEX(name = i_record__path, varLst = i_var__lst),
           i_cr,
           i_context,
           i_preExp,
           i_varDecls )
      local
        list<DAE.ExpVar> i_var__lst;
        Absyn.Path i_record__path;
        Tpl.Text i_ret__var;
        Tpl.Text i_ret__type;
        Tpl.Text i_record__type__name;
        Tpl.Text i_vars;
      equation
        i_vars = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_vars, i_varDecls, i_preExp) = lm_528(i_vars, i_var__lst, i_varDecls, i_preExp, i_context, i_cr);
        i_vars = Tpl.popIter(i_vars);
        i_record__type__name = underscorePath(emptyTxt, i_record__path);
        i_ret__type = Tpl.writeText(emptyTxt, i_record__type__name);
        i_ret__type = Tpl.writeTok(i_ret__type, Tpl.ST_STRING("_rettype"));
        (i_ret__var, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_ret__type), i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_ret__var);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = _"));
        i_preExp = Tpl.writeText(i_preExp, i_record__type__name);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("("));
        i_preExp = Tpl.writeText(i_preExp, i_vars);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_ret__var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = Tpl.writeText(txt, i_ret__type);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_1"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpRecordCrefRhs;

protected function fun_530
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_INT()) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_array"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real_array"));
      then txt;
  end matchcontinue;
end fun_530;

protected function fun_531
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_INT()) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_array"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real_array"));
      then txt;
  end matchcontinue;
end fun_531;

protected function fun_532
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_INT()) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_array"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real_array"));
      then txt;
  end matchcontinue;
end fun_532;

protected function fun_533
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_INT()) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_array"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real_array"));
      then txt;
  end matchcontinue;
end fun_533;

protected function fun_534
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_INT()) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_scalar"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real_scalar"));
      then txt;
  end matchcontinue;
end fun_534;

protected function fun_535
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_INT()) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real"));
      then txt;
  end matchcontinue;
end fun_535;

protected function fun_536
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_INT()) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_array"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real_array"));
      then txt;
  end matchcontinue;
end fun_536;

protected function fun_537
  input Tpl.Text in_txt;
  input DAE.Operator in_i_operator;
  input SimCode.Context in_i_context;
  input DAE.Exp in_i_exp;
  input Tpl.Text in_i_e2;
  input Tpl.Text in_i_e1;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_operator, in_i_context, in_i_exp, in_i_e2, in_i_e1, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      DAE.Exp i_exp;
      Tpl.Text i_e2;
      Tpl.Text i_e1;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.ADD(ty = DAE.ET_STRING()),
           _,
           _,
           i_e2,
           i_e1,
           i_preExp,
           i_varDecls )
      local
        Tpl.Text i_tmpStr;
      equation
        (i_tmpStr, i_varDecls) = tempDecl(emptyTxt, "modelica_string", i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("cat_modelica_string(&"));
        i_preExp = Tpl.writeText(i_preExp, i_tmpStr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(","));
        i_preExp = Tpl.writeText(i_preExp, i_e1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(","));
        i_preExp = Tpl.writeText(i_preExp, i_e2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tmpStr);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ADD(ty = _),
           _,
           _,
           i_e2,
           i_e1,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" + "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.SUB(ty = _),
           _,
           _,
           i_e2,
           i_e1,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" - "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.MUL(ty = _),
           _,
           _,
           i_e2,
           i_e1,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" * "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.DIV(ty = _),
           _,
           _,
           i_e2,
           i_e1,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" / "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.POW(ty = _),
           _,
           _,
           i_e2,
           i_e1,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("pow((modelica_real)"));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", (modelica_real)"));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.UMINUS(ty = _),
           i_context,
           i_exp,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        (txt, i_preExp, i_varDecls) = daeExpUnary(txt, i_exp, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ADD_ARR(ty = i_ty),
           _,
           _,
           i_e2,
           i_e1,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_ty;
        Tpl.Text i_var;
        Tpl.Text i_type;
      equation
        i_type = fun_530(emptyTxt, i_ty);
        (i_var, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_type), i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("add_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_type);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(&"));
        i_preExp = Tpl.writeText(i_preExp, i_e1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_e2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_var);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_var);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.SUB_ARR(ty = i_ty),
           _,
           _,
           i_e2,
           i_e1,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_ty;
        Tpl.Text i_var;
        Tpl.Text i_type;
      equation
        i_type = fun_531(emptyTxt, i_ty);
        (i_var, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_type), i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("sub_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_type);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(&"));
        i_preExp = Tpl.writeText(i_preExp, i_e1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_e2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_var);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_var);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.MUL_ARR(ty = _),
           _,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for MUL_ARR"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.DIV_ARR(ty = _),
           _,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for DIV_ARR"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.MUL_SCALAR_ARRAY(ty = i_ty),
           _,
           _,
           i_e2,
           i_e1,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_ty;
        Tpl.Text i_var;
        Tpl.Text i_type;
      equation
        i_type = fun_532(emptyTxt, i_ty);
        (i_var, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_type), i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("mul_alloc_scalar_"));
        i_preExp = Tpl.writeText(i_preExp, i_type);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("("));
        i_preExp = Tpl.writeText(i_preExp, i_e1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_e2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_var);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_var);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.MUL_ARRAY_SCALAR(ty = i_ty),
           _,
           _,
           i_e2,
           i_e1,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_ty;
        Tpl.Text i_var;
        Tpl.Text i_type;
      equation
        i_type = fun_533(emptyTxt, i_ty);
        (i_var, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_type), i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("mul_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_type);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("_scalar(&"));
        i_preExp = Tpl.writeText(i_preExp, i_e1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_e2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_var);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_var);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ADD_SCALAR_ARRAY(ty = _),
           _,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for ADD_SCALAR_ARRAY"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ADD_ARRAY_SCALAR(ty = _),
           _,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for ADD_ARRAY_SCALAR"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.SUB_SCALAR_ARRAY(ty = _),
           _,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for SUB_SCALAR_ARRAY"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.SUB_ARRAY_SCALAR(ty = _),
           _,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for SUB_ARRAY_SCALAR"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.MUL_SCALAR_PRODUCT(ty = i_ty),
           _,
           _,
           i_e2,
           i_e1,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_ty;
        Tpl.Text i_type;
      equation
        i_type = fun_534(emptyTxt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mul_"));
        txt = Tpl.writeText(txt, i_type);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_product(&"));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.MUL_MATRIX_PRODUCT(ty = i_ty),
           _,
           _,
           i_e2,
           i_e1,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_ty;
        Tpl.Text i_var;
        Tpl.Text i_type;
        Tpl.Text i_typeShort;
      equation
        i_typeShort = fun_535(emptyTxt, i_ty);
        i_type = Tpl.writeText(emptyTxt, i_typeShort);
        i_type = Tpl.writeTok(i_type, Tpl.ST_STRING("_array"));
        (i_var, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_type), i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("mul_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_typeShort);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("_matrix_product_smart(&"));
        i_preExp = Tpl.writeText(i_preExp, i_e1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_e2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_var);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_var);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.DIV_ARRAY_SCALAR(ty = i_ty),
           _,
           _,
           i_e2,
           i_e1,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_ty;
        Tpl.Text i_var;
        Tpl.Text i_type;
      equation
        i_type = fun_536(emptyTxt, i_ty);
        (i_var, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_type), i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("div_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_type);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("_scalar(&"));
        i_preExp = Tpl.writeText(i_preExp, i_e1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_e2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_var);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_var);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.DIV_SCALAR_ARRAY(ty = _),
           _,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for DIV_SCALAR_ARRAY"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.POW_ARRAY_SCALAR(ty = _),
           _,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for POW_ARRAY_SCALAR"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.POW_SCALAR_ARRAY(ty = _),
           _,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for POW_SCALAR_ARRAY"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.POW_ARR(ty = _),
           _,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for POW_ARR"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.POW_ARR2(ty = _),
           _,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for POW_ARR2"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR"));
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end fun_537;

public function daeExpBinary
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_exp as DAE.BINARY(exp1 = i_exp1, exp2 = i_exp2, operator = i_operator)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Operator i_operator;
        DAE.Exp i_exp2;
        DAE.Exp i_exp1;
        DAE.Exp i_exp;
        Tpl.Text i_e2;
        Tpl.Text i_e1;
      equation
        (i_e1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp1, i_context, i_preExp, i_varDecls);
        (i_e2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp2, i_context, i_preExp, i_varDecls);
        (txt, i_preExp, i_varDecls) = fun_537(txt, i_operator, i_context, i_exp, i_e2, i_e1, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpBinary;

protected function fun_539
  input Tpl.Text in_txt;
  input DAE.Operator in_i_operator;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_e;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_preExp) :=
  matchcontinue(in_txt, in_i_operator, in_i_preExp, in_i_e)
    local
      Tpl.Text txt;
      Tpl.Text i_preExp;
      Tpl.Text i_e;

    case ( txt,
           DAE.UMINUS(ty = _),
           i_preExp,
           i_e )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(-"));
        txt = Tpl.writeText(txt, i_e);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp);

    case ( txt,
           DAE.UPLUS(ty = _),
           i_preExp,
           i_e )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp);

    case ( txt,
           DAE.UMINUS_ARR(ty = DAE.ET_ARRAY(ty = DAE.ET_REAL())),
           i_preExp,
           i_e )
      equation
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("usub_real_array(&"));
        i_preExp = Tpl.writeText(i_preExp, i_e);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_e);
      then (txt, i_preExp);

    case ( txt,
           DAE.UMINUS_ARR(ty = _),
           i_preExp,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("unary minus for non-real arrays not implemented"));
      then (txt, i_preExp);

    case ( txt,
           DAE.UPLUS_ARR(ty = _),
           i_preExp,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("UPLUS_ARR_NOT_IMPLEMENTED"));
      then (txt, i_preExp);

    case ( txt,
           _,
           i_preExp,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpUnary:ERR"));
      then (txt, i_preExp);
  end matchcontinue;
end fun_539;

public function daeExpUnary
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.UNARY(exp = i_exp, operator = i_operator),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Operator i_operator;
        DAE.Exp i_exp;
        Tpl.Text i_e;
      equation
        (i_e, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        (txt, i_preExp) = fun_539(txt, i_operator, i_preExp, i_e);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpUnary;

protected function fun_541
  input Tpl.Text in_txt;
  input DAE.Operator in_i_operator;
  input Tpl.Text in_i_e2;
  input Tpl.Text in_i_e1;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_operator, in_i_e2, in_i_e1)
    local
      Tpl.Text txt;
      Tpl.Text i_e2;
      Tpl.Text i_e1;

    case ( txt,
           DAE.AND(),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" && "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.OR(),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" || "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           _,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpLbinary:ERR"));
      then txt;
  end matchcontinue;
end fun_541;

public function daeExpLbinary
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.LBINARY(exp1 = i_exp1, exp2 = i_exp2, operator = i_operator),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Operator i_operator;
        DAE.Exp i_exp2;
        DAE.Exp i_exp1;
        Tpl.Text i_e2;
        Tpl.Text i_e1;
      equation
        (i_e1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp1, i_context, i_preExp, i_varDecls);
        (i_e2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp2, i_context, i_preExp, i_varDecls);
        txt = fun_541(txt, i_operator, i_e2, i_e1);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpLbinary;

protected function fun_543
  input Tpl.Text in_txt;
  input DAE.Operator in_i_operator;
  input Tpl.Text in_i_e;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_operator, in_i_e)
    local
      Tpl.Text txt;
      Tpl.Text i_e;

    case ( txt,
           DAE.NOT(),
           i_e )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(!"));
        txt = Tpl.writeText(txt, i_e);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_543;

public function daeExpLunary
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.LUNARY(exp = i_exp, operator = i_operator),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Operator i_operator;
        DAE.Exp i_exp;
        Tpl.Text i_e;
      equation
        (i_e, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        txt = fun_543(txt, i_operator, i_e);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpLunary;

protected function fun_545
  input Tpl.Text in_txt;
  input DAE.Operator in_i_rel_operator;
  input Tpl.Text in_i_e2;
  input Tpl.Text in_i_e1;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_rel_operator, in_i_e2, in_i_e1)
    local
      Tpl.Text txt;
      Tpl.Text i_e2;
      Tpl.Text i_e1;

    case ( txt,
           DAE.LESS(ty = DAE.ET_BOOL()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(!"));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" && "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.LESS(ty = DAE.ET_STRING()),
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("# string comparison not supported\n"));
      then txt;

    case ( txt,
           DAE.LESS(ty = DAE.ET_INT()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" < "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.LESS(ty = DAE.ET_REAL()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" < "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.GREATER(ty = DAE.ET_BOOL()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" && !"));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.GREATER(ty = DAE.ET_STRING()),
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("# string comparison not supported\n"));
      then txt;

    case ( txt,
           DAE.GREATER(ty = DAE.ET_INT()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" > "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.GREATER(ty = DAE.ET_REAL()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" > "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.LESSEQ(ty = DAE.ET_BOOL()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(!"));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" || "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.LESSEQ(ty = DAE.ET_STRING()),
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("# string comparison not supported\n"));
      then txt;

    case ( txt,
           DAE.LESSEQ(ty = DAE.ET_INT()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" <= "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.LESSEQ(ty = DAE.ET_REAL()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" <= "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.GREATEREQ(ty = DAE.ET_BOOL()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" || !"));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.GREATEREQ(ty = DAE.ET_STRING()),
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("# string comparison not supported\n"));
      then txt;

    case ( txt,
           DAE.GREATEREQ(ty = DAE.ET_INT()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" >= "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.GREATEREQ(ty = DAE.ET_REAL()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" >= "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.EQUAL(ty = DAE.ET_BOOL()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("((!"));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" && !"));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(") || ("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" && "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("))"));
      then txt;

    case ( txt,
           DAE.EQUAL(ty = DAE.ET_STRING()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(!strcmp("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("))"));
      then txt;

    case ( txt,
           DAE.EQUAL(ty = DAE.ET_INT()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.EQUAL(ty = DAE.ET_REAL()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.EQUAL(ty = DAE.ET_ENUMERATION(path = _)),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.NEQUAL(ty = DAE.ET_BOOL()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("((!"));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" && "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(") || ("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" && !"));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("))"));
      then txt;

    case ( txt,
           DAE.NEQUAL(ty = DAE.ET_STRING()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(strcmp("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("))"));
      then txt;

    case ( txt,
           DAE.NEQUAL(ty = DAE.ET_INT()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" != "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.NEQUAL(ty = DAE.ET_REAL()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" != "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           _,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpRelation:ERR"));
      then txt;
  end matchcontinue;
end fun_545;

protected function fun_546
  input Tpl.Text in_txt;
  input String in_it;
  input Tpl.Text in_i_simRel;
  input DAE.Operator in_i_rel_operator;
  input DAE.Exp in_i_rel_exp2;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;
  input DAE.Exp in_i_rel_exp1;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_it, in_i_simRel, in_i_rel_operator, in_i_rel_exp2, in_i_varDecls, in_i_preExp, in_i_context, in_i_rel_exp1)
    local
      Tpl.Text txt;
      Tpl.Text i_simRel;
      DAE.Operator i_rel_operator;
      DAE.Exp i_rel_exp2;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;
      DAE.Exp i_rel_exp1;

    case ( txt,
           "",
           _,
           i_rel_operator,
           i_rel_exp2,
           i_varDecls,
           i_preExp,
           i_context,
           i_rel_exp1 )
      local
        Tpl.Text i_e2;
        Tpl.Text i_e1;
      equation
        (i_e1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_rel_exp1, i_context, i_preExp, i_varDecls);
        (i_e2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_rel_exp2, i_context, i_preExp, i_varDecls);
        txt = fun_545(txt, i_rel_operator, i_e2, i_e1);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _,
           i_simRel,
           _,
           _,
           i_varDecls,
           i_preExp,
           _,
           _ )
      equation
        txt = Tpl.writeText(txt, i_simRel);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_546;

public function daeExpRelation
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_rel as DAE.RELATION(exp1 = i_rel_exp1, exp2 = i_rel_exp2, operator = i_rel_operator)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Operator i_rel_operator;
        DAE.Exp i_rel_exp2;
        DAE.Exp i_rel_exp1;
        DAE.Exp i_rel;
        String str_1;
        Tpl.Text i_simRel;
      equation
        (i_simRel, i_preExp, i_varDecls) = daeExpRelationSim(emptyTxt, i_rel, i_context, i_preExp, i_varDecls);
        str_1 = Tpl.textString(i_simRel);
        (txt, i_varDecls, i_preExp) = fun_546(txt, str_1, i_simRel, i_rel_operator, i_rel_exp2, i_varDecls, i_preExp, i_context, i_rel_exp1);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpRelation;

protected function fun_548
  input Tpl.Text in_txt;
  input DAE.Operator in_i_rel_operator;
  input Tpl.Text in_i_e2;
  input Tpl.Text in_i_e1;
  input Tpl.Text in_i_res;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_preExp) :=
  matchcontinue(in_txt, in_i_rel_operator, in_i_e2, in_i_e1, in_i_res, in_i_preExp)
    local
      Tpl.Text txt;
      Tpl.Text i_e2;
      Tpl.Text i_e1;
      Tpl.Text i_res;
      Tpl.Text i_preExp;

    case ( txt,
           DAE.LESS(ty = _),
           i_e2,
           i_e1,
           i_res,
           i_preExp )
      equation
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("RELATIONLESS("));
        i_preExp = Tpl.writeText(i_preExp, i_res);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_e1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_e2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_res);
      then (txt, i_preExp);

    case ( txt,
           DAE.LESSEQ(ty = _),
           i_e2,
           i_e1,
           i_res,
           i_preExp )
      equation
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("RELATIONLESSEQ("));
        i_preExp = Tpl.writeText(i_preExp, i_res);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_e1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_e2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_res);
      then (txt, i_preExp);

    case ( txt,
           DAE.GREATER(ty = _),
           i_e2,
           i_e1,
           i_res,
           i_preExp )
      equation
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("RELATIONGREATER("));
        i_preExp = Tpl.writeText(i_preExp, i_res);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_e1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_e2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_res);
      then (txt, i_preExp);

    case ( txt,
           DAE.GREATEREQ(ty = _),
           i_e2,
           i_e1,
           i_res,
           i_preExp )
      equation
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("RELATIONGREATEREQ("));
        i_preExp = Tpl.writeText(i_preExp, i_res);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_e1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_e2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_res);
      then (txt, i_preExp);

    case ( txt,
           _,
           _,
           _,
           _,
           i_preExp )
      then (txt, i_preExp);
  end matchcontinue;
end fun_548;

protected function fun_549
  input Tpl.Text in_txt;
  input SimCode.Context in_i_context;
  input DAE.Operator in_i_rel_operator;
  input DAE.Exp in_i_rel_exp2;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input DAE.Exp in_i_rel_exp1;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_i_context, in_i_rel_operator, in_i_rel_exp2, in_i_varDecls, in_i_preExp, in_i_rel_exp1)
    local
      Tpl.Text txt;
      DAE.Operator i_rel_operator;
      DAE.Exp i_rel_exp2;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      DAE.Exp i_rel_exp1;

    case ( txt,
           (i_context as SimCode.SIMULATION(genDiscrete = _)),
           i_rel_operator,
           i_rel_exp2,
           i_varDecls,
           i_preExp,
           i_rel_exp1 )
      local
        SimCode.Context i_context;
        Tpl.Text i_res;
        Tpl.Text i_e2;
        Tpl.Text i_e1;
      equation
        (i_e1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_rel_exp1, i_context, i_preExp, i_varDecls);
        (i_e2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_rel_exp2, i_context, i_preExp, i_varDecls);
        (i_res, i_varDecls) = tempDecl(emptyTxt, "modelica_boolean", i_varDecls);
        (txt, i_preExp) = fun_548(txt, i_rel_operator, i_e2, i_e1, i_res, i_preExp);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _,
           _,
           _,
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_549;

public function daeExpRelationSim
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_rel as DAE.RELATION(exp1 = i_rel_exp1, exp2 = i_rel_exp2, operator = i_rel_operator)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Operator i_rel_operator;
        DAE.Exp i_rel_exp2;
        DAE.Exp i_rel_exp1;
        DAE.Exp i_rel;
      equation
        (txt, i_varDecls, i_preExp) = fun_549(txt, i_context, i_rel_operator, i_rel_exp2, i_varDecls, i_preExp, i_rel_exp1);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpRelationSim;

public function daeExpIf
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.IFEXP(expCond = i_expCond, expThen = i_expThen, expElse = i_expElse),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_expElse;
        DAE.Exp i_expThen;
        DAE.Exp i_expCond;
        Tpl.Text i_eElse;
        Tpl.Text i_preExpElse;
        Tpl.Text i_eThen;
        Tpl.Text i_preExpThen;
        Tpl.Text i_resVar;
        Tpl.Text i_resVarType;
        Tpl.Text i_condVar;
        Tpl.Text i_condExp;
      equation
        (i_condExp, i_preExp, i_varDecls) = daeExp(emptyTxt, i_expCond, i_context, i_preExp, i_varDecls);
        (i_condVar, i_varDecls) = tempDecl(emptyTxt, "modelica_boolean", i_varDecls);
        i_resVarType = expTypeFromExpArrayIf(emptyTxt, i_expThen);
        (i_resVar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_resVarType), i_varDecls);
        i_preExpThen = emptyTxt;
        (i_eThen, i_preExpThen, i_varDecls) = daeExp(emptyTxt, i_expThen, i_context, i_preExpThen, i_varDecls);
        i_preExpElse = emptyTxt;
        (i_eElse, i_preExpElse, i_varDecls) = daeExp(emptyTxt, i_expElse, i_context, i_preExpElse, i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_condVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = (modelica_boolean)"));
        i_preExp = Tpl.writeText(i_preExp, i_condExp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING_LIST({
                                              ";\n",
                                              "if ("
                                          }, false));
        i_preExp = Tpl.writeText(i_preExp, i_condVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_LINE(") {\n"));
        i_preExp = Tpl.pushBlock(i_preExp, Tpl.BT_INDENT(2));
        i_preExp = Tpl.writeText(i_preExp, i_preExpThen);
        i_preExp = Tpl.softNewLine(i_preExp);
        i_preExp = Tpl.writeText(i_preExp, i_resVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = "));
        i_preExp = Tpl.writeText(i_preExp, i_eThen);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_LINE(";\n"));
        i_preExp = Tpl.popBlock(i_preExp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_LINE("} else {\n"));
        i_preExp = Tpl.pushBlock(i_preExp, Tpl.BT_INDENT(2));
        i_preExp = Tpl.writeText(i_preExp, i_preExpElse);
        i_preExp = Tpl.softNewLine(i_preExp);
        i_preExp = Tpl.writeText(i_preExp, i_resVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = "));
        i_preExp = Tpl.writeText(i_preExp, i_eElse);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_LINE(";\n"));
        i_preExp = Tpl.popBlock(i_preExp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("}"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_resVar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpIf;

protected function fun_552
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_INT()) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_array"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real_array"));
      then txt;
  end matchcontinue;
end fun_552;

protected function fun_553
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_arg_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_arg_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_INT() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(modelica_integer)"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_553;

protected function lm_554
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_exp :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_554(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_554(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_554;

protected function lm_555
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_exp :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_555(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_555(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_555;

protected function fun_556
  input Tpl.Text in_txt;
  input Boolean in_i_builtin;
  input Tpl.Text in_i_retType;
  input Tpl.Text in_i_retVar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_builtin, in_i_retType, in_i_retVar)
    local
      Tpl.Text txt;
      Tpl.Text i_retType;
      Tpl.Text i_retVar;

    case ( txt,
           false,
           i_retType,
           i_retVar )
      equation
        txt = Tpl.writeText(txt, i_retVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = Tpl.writeText(txt, i_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_1"));
      then txt;

    case ( txt,
           _,
           _,
           i_retVar )
      equation
        txt = Tpl.writeText(txt, i_retVar);
      then txt;
  end matchcontinue;
end fun_556;

protected function lm_557
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_exp :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_557(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_557(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_557;

public function daeExpCall
  input Tpl.Text in_txt;
  input DAE.Exp in_i_call;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_call, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "DIVISION"), expLst = {i_e1, i_e2, DAE.SCONST(string = i_string)}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        String i_string;
        DAE.Exp i_e2;
        DAE.Exp i_e1;
        String ret_3;
        Tpl.Text i_var3;
        Tpl.Text i_var2;
        Tpl.Text i_var1;
      equation
        (i_var1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e1, i_context, i_preExp, i_varDecls);
        (i_var2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e2, i_context, i_preExp, i_varDecls);
        ret_3 = Util.escapeModelicaStringToCString(i_string);
        i_var3 = Tpl.writeStr(emptyTxt, ret_3);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("DIVISION("));
        txt = Tpl.writeText(txt, i_var1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeText(txt, i_var2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(",\""));
        txt = Tpl.writeText(txt, i_var3);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, ty = i_ty, path = Absyn.IDENT(name = "DIVISION_ARRAY_SCALAR"), expLst = {i_e1, i_e2, DAE.SCONST(string = i_string)}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        String i_string;
        DAE.Exp i_e2;
        DAE.Exp i_e1;
        DAE.ExpType i_ty;
        String ret_5;
        Tpl.Text i_var3;
        Tpl.Text i_var2;
        Tpl.Text i_var1;
        Tpl.Text i_var;
        Tpl.Text i_type;
      equation
        i_type = fun_552(emptyTxt, i_ty);
        (i_var, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_type), i_varDecls);
        (i_var1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e1, i_context, i_preExp, i_varDecls);
        (i_var2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e2, i_context, i_preExp, i_varDecls);
        ret_5 = Util.escapeModelicaStringToCString(i_string);
        i_var3 = Tpl.writeStr(emptyTxt, ret_5);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("division_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_type);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("_scalar(&"));
        i_preExp = Tpl.writeText(i_preExp, i_var1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_var2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_var);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(",\""));
        i_preExp = Tpl.writeText(i_preExp, i_var3);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("\");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_var);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "der"), expLst = {(i_arg as DAE.CREF(componentRef = i_arg_componentRef))}),
           _,
           i_preExp,
           i_varDecls )
      local
        DAE.ComponentRef i_arg_componentRef;
        DAE.Exp i_arg;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$P$DER"));
        txt = cref(txt, i_arg_componentRef);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "pre"), expLst = {(i_arg as DAE.CREF(ty = i_arg_ty, componentRef = i_arg_componentRef))}),
           _,
           i_preExp,
           i_varDecls )
      local
        DAE.ComponentRef i_arg_componentRef;
        DAE.ExpType i_arg_ty;
        DAE.Exp i_arg;
        Tpl.Text i_cast;
        Tpl.Text i_retVar;
        Tpl.Text i_retType;
      equation
        i_retType = expTypeArrayIf(emptyTxt, i_arg_ty);
        (i_retVar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_retType), i_varDecls);
        i_cast = fun_553(emptyTxt, i_arg_ty);
        i_preExp = Tpl.writeText(i_preExp, i_retVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = "));
        i_preExp = Tpl.writeText(i_preExp, i_cast);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("pre("));
        i_preExp = cref(i_preExp, i_arg_componentRef);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_retVar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "max"), expLst = {i_e1, i_e2}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e2;
        DAE.Exp i_e1;
        Tpl.Text i_var2;
        Tpl.Text i_var1;
      equation
        (i_var1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e1, i_context, i_preExp, i_varDecls);
        (i_var2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e2, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("std::max("));
        txt = Tpl.writeText(txt, i_var1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeText(txt, i_var2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "min"), expLst = {i_e1, i_e2}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e2;
        DAE.Exp i_e1;
        Tpl.Text i_var2;
        Tpl.Text i_var1;
      equation
        (i_var1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e1, i_context, i_preExp, i_varDecls);
        (i_var2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e2, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("std::min("));
        txt = Tpl.writeText(txt, i_var1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeText(txt, i_var2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "abs"), expLst = {i_e1}, ty = DAE.ET_INT()),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e1;
        Tpl.Text i_var1;
      equation
        (i_var1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e1, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("std::abs("));
        txt = Tpl.writeText(txt, i_var1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "abs"), expLst = {i_e1}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e1;
        Tpl.Text i_var1;
      equation
        (i_var1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e1, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("fabs("));
        txt = Tpl.writeText(txt, i_var1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "max"), expLst = {i_array}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_array;
        Tpl.Text txt_3;
        Tpl.Text i_tvar;
        Tpl.Text i_arr__tp__str;
        Tpl.Text i_expVar;
      equation
        (i_expVar, i_preExp, i_varDecls) = daeExp(emptyTxt, i_array, i_context, i_preExp, i_varDecls);
        i_arr__tp__str = expTypeFromExpArray(emptyTxt, i_array);
        txt_3 = expTypeFromExpModelica(emptyTxt, i_array);
        (i_tvar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(txt_3), i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_tvar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = max_"));
        i_preExp = Tpl.writeText(i_preExp, i_arr__tp__str);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(&"));
        i_preExp = Tpl.writeText(i_preExp, i_expVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tvar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "min"), expLst = {i_array}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_array;
        Tpl.Text txt_3;
        Tpl.Text i_tvar;
        Tpl.Text i_arr__tp__str;
        Tpl.Text i_expVar;
      equation
        (i_expVar, i_preExp, i_varDecls) = daeExp(emptyTxt, i_array, i_context, i_preExp, i_varDecls);
        i_arr__tp__str = expTypeFromExpArray(emptyTxt, i_array);
        txt_3 = expTypeFromExpModelica(emptyTxt, i_array);
        (i_tvar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(txt_3), i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_tvar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = min_"));
        i_preExp = Tpl.writeText(i_preExp, i_arr__tp__str);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(&"));
        i_preExp = Tpl.writeText(i_preExp, i_expVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tvar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "promote"), expLst = {i_A, i_n}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_n;
        DAE.Exp i_A;
        Tpl.Text i_tvar;
        Tpl.Text i_arr__tp__str;
        Tpl.Text i_var2;
        Tpl.Text i_var1;
      equation
        (i_var1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_A, i_context, i_preExp, i_varDecls);
        (i_var2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_n, i_context, i_preExp, i_varDecls);
        i_arr__tp__str = expTypeFromExpArray(emptyTxt, i_A);
        (i_tvar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_arr__tp__str), i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("promote_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_arr__tp__str);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(&"));
        i_preExp = Tpl.writeText(i_preExp, i_var1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_var2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_tvar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tvar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "transpose"), expLst = {i_A}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_A;
        Tpl.Text i_tvar;
        Tpl.Text i_arr__tp__str;
        Tpl.Text i_var1;
      equation
        (i_var1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_A, i_context, i_preExp, i_varDecls);
        i_arr__tp__str = expTypeFromExpArray(emptyTxt, i_A);
        (i_tvar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_arr__tp__str), i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("transpose_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_arr__tp__str);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(&"));
        i_preExp = Tpl.writeText(i_preExp, i_var1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_tvar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tvar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "cross"), expLst = {i_v1, i_v2}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_v2;
        DAE.Exp i_v1;
        Tpl.Text i_tvar;
        Tpl.Text i_arr__tp__str;
        Tpl.Text i_var2;
        Tpl.Text i_var1;
      equation
        (i_var1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_v1, i_context, i_preExp, i_varDecls);
        (i_var2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_v2, i_context, i_preExp, i_varDecls);
        i_arr__tp__str = expTypeFromExpArray(emptyTxt, i_v1);
        (i_tvar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_arr__tp__str), i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("cross_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_arr__tp__str);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(&"));
        i_preExp = Tpl.writeText(i_preExp, i_var1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_var2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_tvar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tvar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "identity"), expLst = {i_A}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_A;
        Tpl.Text i_tvar;
        Tpl.Text i_arr__tp__str;
        Tpl.Text i_var1;
      equation
        (i_var1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_A, i_context, i_preExp, i_varDecls);
        i_arr__tp__str = expTypeFromExpArray(emptyTxt, i_A);
        (i_tvar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_arr__tp__str), i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("identity_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_arr__tp__str);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("("));
        i_preExp = Tpl.writeText(i_preExp, i_var1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_tvar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tvar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "rem"), expLst = {i_e1, i_e2}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e2;
        DAE.Exp i_e1;
        Tpl.Text i_typeStr;
        Tpl.Text i_var2;
        Tpl.Text i_var1;
      equation
        (i_var1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e1, i_context, i_preExp, i_varDecls);
        (i_var2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e2, i_context, i_preExp, i_varDecls);
        i_typeStr = expTypeFromExpShort(emptyTxt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mod_"));
        txt = Tpl.writeText(txt, i_typeStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_var1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeText(txt, i_var2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "String"), expLst = {i_s, i_format}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_format;
        DAE.Exp i_s;
        Tpl.Text i_typeStr;
        Tpl.Text i_formatExp;
        Tpl.Text i_sExp;
        Tpl.Text i_tvar;
      equation
        (i_tvar, i_varDecls) = tempDecl(emptyTxt, "modelica_string", i_varDecls);
        (i_sExp, i_preExp, i_varDecls) = daeExp(emptyTxt, i_s, i_context, i_preExp, i_varDecls);
        (i_formatExp, i_preExp, i_varDecls) = daeExp(emptyTxt, i_format, i_context, i_preExp, i_varDecls);
        i_typeStr = expTypeFromExpModelica(emptyTxt, i_s);
        i_preExp = Tpl.writeText(i_preExp, i_typeStr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("_to_modelica_string_format(&"));
        i_preExp = Tpl.writeText(i_preExp, i_tvar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_sExp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_formatExp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tvar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "String"), expLst = {i_s, i_minlen, i_leftjust}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_leftjust;
        DAE.Exp i_minlen;
        DAE.Exp i_s;
        Tpl.Text i_typeStr;
        Tpl.Text i_leftjustExp;
        Tpl.Text i_minlenExp;
        Tpl.Text i_sExp;
        Tpl.Text i_tvar;
      equation
        (i_tvar, i_varDecls) = tempDecl(emptyTxt, "modelica_string", i_varDecls);
        (i_sExp, i_preExp, i_varDecls) = daeExp(emptyTxt, i_s, i_context, i_preExp, i_varDecls);
        (i_minlenExp, i_preExp, i_varDecls) = daeExp(emptyTxt, i_minlen, i_context, i_preExp, i_varDecls);
        (i_leftjustExp, i_preExp, i_varDecls) = daeExp(emptyTxt, i_leftjust, i_context, i_preExp, i_varDecls);
        i_typeStr = expTypeFromExpModelica(emptyTxt, i_s);
        i_preExp = Tpl.writeText(i_preExp, i_typeStr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("_to_modelica_string(&"));
        i_preExp = Tpl.writeText(i_preExp, i_tvar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_sExp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_minlenExp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_leftjustExp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tvar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "String"), expLst = {i_s, i_minlen, i_leftjust, i_signdig}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_signdig;
        DAE.Exp i_leftjust;
        DAE.Exp i_minlen;
        DAE.Exp i_s;
        Tpl.Text i_signdigExp;
        Tpl.Text i_leftjustExp;
        Tpl.Text i_minlenExp;
        Tpl.Text i_sExp;
        Tpl.Text i_tvar;
      equation
        (i_tvar, i_varDecls) = tempDecl(emptyTxt, "modelica_string", i_varDecls);
        (i_sExp, i_preExp, i_varDecls) = daeExp(emptyTxt, i_s, i_context, i_preExp, i_varDecls);
        (i_minlenExp, i_preExp, i_varDecls) = daeExp(emptyTxt, i_minlen, i_context, i_preExp, i_varDecls);
        (i_leftjustExp, i_preExp, i_varDecls) = daeExp(emptyTxt, i_leftjust, i_context, i_preExp, i_varDecls);
        (i_signdigExp, i_preExp, i_varDecls) = daeExp(emptyTxt, i_signdig, i_context, i_preExp, i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("modelica_real_to_modelica_string(&"));
        i_preExp = Tpl.writeText(i_preExp, i_tvar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_sExp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_minlenExp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_leftjustExp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_signdigExp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tvar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "delay"), expLst = {DAE.ICONST(integer = i_index), i_e, i_d, i_delayMax}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_delayMax;
        DAE.Exp i_d;
        DAE.Exp i_e;
        Integer i_index;
        Tpl.Text i_var3;
        Tpl.Text i_var2;
        Tpl.Text i_var1;
        Tpl.Text i_tvar;
      equation
        (i_tvar, i_varDecls) = tempDecl(emptyTxt, "modelica_real", i_varDecls);
        (i_var1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
        (i_var2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_d, i_context, i_preExp, i_varDecls);
        (i_var3, i_preExp, i_varDecls) = daeExp(emptyTxt, i_delayMax, i_context, i_preExp, i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_tvar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = delayImpl("));
        i_preExp = Tpl.writeStr(i_preExp, intString(i_index));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_var1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", time, "));
        i_preExp = Tpl.writeText(i_preExp, i_var2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_var3);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tvar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "mmc_get_field"), expLst = {i_s1, DAE.ICONST(integer = i_i)}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        Integer i_i;
        DAE.Exp i_s1;
        Tpl.Text i_expPart;
        Tpl.Text i_tvar;
      equation
        (i_tvar, i_varDecls) = tempDecl(emptyTxt, "modelica_metatype", i_varDecls);
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_s1, i_context, i_preExp, i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_tvar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR("));
        i_preExp = Tpl.writeText(i_preExp, i_expPart);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("), "));
        i_preExp = Tpl.writeStr(i_preExp, intString(i_i));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("));"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tvar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "mmc_unbox_record"), expLst = {i_s1}, ty = i_ty),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_ty;
        DAE.Exp i_s1;
        Tpl.Text i_argStr;
      equation
        (i_argStr, i_preExp, i_varDecls) = daeExp(emptyTxt, i_s1, i_context, i_preExp, i_varDecls);
        (txt, i_preExp, i_varDecls) = unboxRecord(txt, Tpl.textString(i_argStr), i_ty, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(ty = DAE.ET_NORETCALL(), expLst = i_expLst, path = i_path, builtin = i_builtin),
           i_context,
           i_preExp,
           i_varDecls )
      local
        Boolean i_builtin;
        Absyn.Path i_path;
        list<DAE.Exp> i_expLst;
        Tpl.Text i_funName;
        Tpl.Text i_argStr;
      equation
        i_argStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_argStr, i_varDecls, i_preExp) = lm_554(i_argStr, i_expLst, i_varDecls, i_preExp, i_context);
        i_argStr = Tpl.popIter(i_argStr);
        i_funName = underscorePath(emptyTxt, i_path);
        i_preExp = daeExpCallBuiltinPrefix(i_preExp, i_builtin);
        i_preExp = Tpl.writeText(i_preExp, i_funName);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("("));
        i_preExp = Tpl.writeText(i_preExp, i_argStr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("/* NORETCALL */"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, expLst = i_expLst, path = i_path, builtin = i_builtin),
           i_context,
           i_preExp,
           i_varDecls )
      local
        Boolean i_builtin;
        Absyn.Path i_path;
        list<DAE.Exp> i_expLst;
        Tpl.Text i_retVar;
        Tpl.Text i_retType;
        Tpl.Text i_funName;
        Tpl.Text i_argStr;
      equation
        i_argStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_argStr, i_varDecls, i_preExp) = lm_555(i_argStr, i_expLst, i_varDecls, i_preExp, i_context);
        i_argStr = Tpl.popIter(i_argStr);
        i_funName = underscorePath(emptyTxt, i_path);
        i_retType = Tpl.writeText(emptyTxt, i_funName);
        i_retType = Tpl.writeTok(i_retType, Tpl.ST_STRING("_rettype"));
        (i_retVar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_retType), i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_retVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = "));
        i_preExp = daeExpCallBuiltinPrefix(i_preExp, i_builtin);
        i_preExp = Tpl.writeText(i_preExp, i_funName);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("("));
        i_preExp = Tpl.writeText(i_preExp, i_argStr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = fun_556(txt, i_builtin, i_retType, i_retVar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = true, expLst = i_expLst, path = i_path, builtin = i_builtin),
           i_context,
           i_preExp,
           i_varDecls )
      local
        Boolean i_builtin;
        Absyn.Path i_path;
        list<DAE.Exp> i_expLst;
        Tpl.Text i_retVar;
        Tpl.Text i_retType;
        Tpl.Text i_funName;
        Tpl.Text i_argStr;
      equation
        i_argStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_argStr, i_varDecls, i_preExp) = lm_557(i_argStr, i_expLst, i_varDecls, i_preExp, i_context);
        i_argStr = Tpl.popIter(i_argStr);
        i_funName = underscorePath(emptyTxt, i_path);
        i_retType = Tpl.writeText(emptyTxt, i_funName);
        i_retType = Tpl.writeTok(i_retType, Tpl.ST_STRING("_rettype"));
        (i_retVar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_retType), i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_retVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = "));
        i_preExp = daeExpCallBuiltinPrefix(i_preExp, i_builtin);
        i_preExp = Tpl.writeText(i_preExp, i_funName);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("("));
        i_preExp = Tpl.writeText(i_preExp, i_argStr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_retVar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpCall;

public function daeExpCallBuiltinPrefix
  input Tpl.Text in_txt;
  input Boolean in_i_builtin;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_builtin)
    local
      Tpl.Text txt;

    case ( txt,
           true )
      then txt;

    case ( txt,
           false )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end daeExpCallBuiltinPrefix;

protected function fun_560
  input Tpl.Text in_txt;
  input Boolean in_i_scalar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_scalar)
    local
      Tpl.Text txt;

    case ( txt,
           false )
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("scalar_"));
      then txt;
  end matchcontinue;
end fun_560;

protected function fun_561
  input Tpl.Text in_txt;
  input Boolean in_i_scalar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_scalar)
    local
      Tpl.Text txt;

    case ( txt,
           false )
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("&"));
      then txt;
  end matchcontinue;
end fun_561;

protected function fun_562
  input Tpl.Text in_txt;
  input Boolean in_i_scalar;
  input DAE.Exp in_i_e;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_scalar, in_i_e)
    local
      Tpl.Text txt;
      DAE.Exp i_e;

    case ( txt,
           false,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("&"));
      then txt;

    case ( txt,
           _,
           i_e )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = expTypeFromExpModelica(txt, i_e);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;
  end matchcontinue;
end fun_562;

protected function lm_563
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;
  input Boolean in_i_scalar;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp, in_i_context, in_i_scalar)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;
      Boolean i_scalar;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_e :: rest,
           i_varDecls,
           i_preExp,
           i_context,
           i_scalar )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_e;
        Tpl.Text i_prefix;
      equation
        i_prefix = fun_562(emptyTxt, i_scalar, i_e);
        txt = Tpl.writeText(txt, i_prefix);
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_e, i_context, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_563(txt, rest, i_varDecls, i_preExp, i_context, i_scalar);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp,
           i_context,
           i_scalar )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_563(txt, rest, i_varDecls, i_preExp, i_context, i_scalar);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_563;

public function daeExpArray
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.ARRAY(ty = i_ty, scalar = i_scalar, array = i_array),
           i_context,
           i_preExp,
           i_varDecls )
      local
        list<DAE.Exp> i_array;
        Boolean i_scalar;
        DAE.ExpType i_ty;
        Integer ret_5;
        Tpl.Text i_params;
        Tpl.Text i_scalarRef;
        Tpl.Text i_scalarPrefix;
        Tpl.Text i_arrayVar;
        Tpl.Text i_arrayTypeStr;
      equation
        i_arrayTypeStr = expTypeArray(emptyTxt, i_ty);
        (i_arrayVar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_arrayTypeStr), i_varDecls);
        i_scalarPrefix = fun_560(emptyTxt, i_scalar);
        i_scalarRef = fun_561(emptyTxt, i_scalar);
        i_params = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_params, i_varDecls, i_preExp) = lm_563(i_params, i_array, i_varDecls, i_preExp, i_context, i_scalar);
        i_params = Tpl.popIter(i_params);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("array_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_scalarPrefix);
        i_preExp = Tpl.writeText(i_preExp, i_arrayTypeStr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(&"));
        i_preExp = Tpl.writeText(i_preExp, i_arrayVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        ret_5 = listLength(i_array);
        i_preExp = Tpl.writeStr(i_preExp, intString(ret_5));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_params);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_arrayVar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpArray;

protected function lm_565
  input Tpl.Text in_txt;
  input list<list<tuple<DAE.Exp, Boolean>>> in_items;
  input Tpl.Text in_i_vars2;
  input Tpl.Text in_i_promote;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_arrayTypeStr;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_vars2;
  output Tpl.Text out_i_promote;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_vars2, out_i_promote, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_vars2, in_i_promote, in_i_context, in_i_varDecls, in_i_arrayTypeStr)
    local
      Tpl.Text txt;
      Tpl.Text i_vars2;
      Tpl.Text i_promote;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;
      Tpl.Text i_arrayTypeStr;

    case ( txt,
           {},
           i_vars2,
           i_promote,
           _,
           i_varDecls,
           _ )
      then (txt, i_vars2, i_promote, i_varDecls);

    case ( txt,
           i_row :: rest,
           i_vars2,
           i_promote,
           i_context,
           i_varDecls,
           i_arrayTypeStr )
      local
        list<list<tuple<DAE.Exp, Boolean>>> rest;
        list<tuple<DAE.Exp, Boolean>> i_row;
        Integer ret_2;
        Tpl.Text i_vars;
        Tpl.Text i_tmp;
      equation
        (i_tmp, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_arrayTypeStr), i_varDecls);
        (i_vars, i_promote, i_varDecls) = daeExpMatrixRow(emptyTxt, i_row, Tpl.textString(i_arrayTypeStr), i_context, i_promote, i_varDecls);
        i_vars2 = Tpl.writeTok(i_vars2, Tpl.ST_STRING(", &"));
        i_vars2 = Tpl.writeText(i_vars2, i_tmp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("cat_alloc_"));
        txt = Tpl.writeText(txt, i_arrayTypeStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(2, &"));
        txt = Tpl.writeText(txt, i_tmp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_2 = listLength(i_row);
        txt = Tpl.writeStr(txt, intString(ret_2));
        txt = Tpl.writeText(txt, i_vars);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.nextIter(txt);
        (txt, i_vars2, i_promote, i_varDecls) = lm_565(txt, rest, i_vars2, i_promote, i_context, i_varDecls, i_arrayTypeStr);
      then (txt, i_vars2, i_promote, i_varDecls);

    case ( txt,
           _ :: rest,
           i_vars2,
           i_promote,
           i_context,
           i_varDecls,
           i_arrayTypeStr )
      local
        list<list<tuple<DAE.Exp, Boolean>>> rest;
      equation
        (txt, i_vars2, i_promote, i_varDecls) = lm_565(txt, rest, i_vars2, i_promote, i_context, i_varDecls, i_arrayTypeStr);
      then (txt, i_vars2, i_promote, i_varDecls);
  end matchcontinue;
end lm_565;

public function daeExpMatrix
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.MATRIX(scalar = {{}}, ty = i_ty),
           _,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_ty;
        Tpl.Text i_tmp;
        Tpl.Text i_arrayTypeStr;
      equation
        i_arrayTypeStr = expTypeArray(emptyTxt, i_ty);
        (i_tmp, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_arrayTypeStr), i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_arrayTypeStr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(&"));
        i_preExp = Tpl.writeText(i_preExp, i_tmp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", 2, 0, 1);"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tmp);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.MATRIX(scalar = {}, ty = i_ty),
           _,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_ty;
        Tpl.Text i_tmp;
        Tpl.Text i_arrayTypeStr;
      equation
        i_arrayTypeStr = expTypeArray(emptyTxt, i_ty);
        (i_tmp, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_arrayTypeStr), i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_arrayTypeStr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(&"));
        i_preExp = Tpl.writeText(i_preExp, i_tmp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", 2, 0, 1);"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tmp);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_m as DAE.MATRIX(ty = i_m_ty, scalar = i_m_scalar)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        list<list<tuple<DAE.Exp, Boolean>>> i_m_scalar;
        DAE.ExpType i_m_ty;
        DAE.Exp i_m;
        Integer ret_5;
        Tpl.Text i_tmp;
        Tpl.Text i_catAlloc;
        Tpl.Text i_promote;
        Tpl.Text i_vars2;
        Tpl.Text i_arrayTypeStr;
      equation
        i_arrayTypeStr = expTypeArray(emptyTxt, i_m_ty);
        i_vars2 = emptyTxt;
        i_promote = emptyTxt;
        i_catAlloc = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_catAlloc, i_vars2, i_promote, i_varDecls) = lm_565(i_catAlloc, i_m_scalar, i_vars2, i_promote, i_context, i_varDecls, i_arrayTypeStr);
        i_catAlloc = Tpl.popIter(i_catAlloc);
        i_preExp = Tpl.writeText(i_preExp, i_promote);
        i_preExp = Tpl.writeText(i_preExp, i_catAlloc);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        (i_tmp, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_arrayTypeStr), i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("cat_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_arrayTypeStr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(1, &"));
        i_preExp = Tpl.writeText(i_preExp, i_tmp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        ret_5 = listLength(i_m_scalar);
        i_preExp = Tpl.writeStr(i_preExp, intString(ret_5));
        i_preExp = Tpl.writeText(i_preExp, i_vars2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tmp);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpMatrix;

protected function fun_567
  input Tpl.Text in_txt;
  input Boolean in_i_b;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_b)
    local
      Tpl.Text txt;

    case ( txt,
           false )
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("scalar_"));
      then txt;
  end matchcontinue;
end fun_567;

protected function fun_568
  input Tpl.Text in_txt;
  input Boolean in_i_b;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_b)
    local
      Tpl.Text txt;

    case ( txt,
           false )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("&"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_568;

protected function lm_569
  input Tpl.Text in_txt;
  input list<tuple<DAE.Exp, Boolean>> in_items;
  input Tpl.Text in_i_varLstStr;
  input String in_i_arrayTypeStr;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varLstStr;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varLstStr, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varLstStr, in_i_arrayTypeStr, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varLstStr;
      String i_arrayTypeStr;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varLstStr,
           _,
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varLstStr, i_varDecls, i_preExp);

    case ( txt,
           (i_col as (i_e, i_b)) :: rest,
           i_varLstStr,
           i_arrayTypeStr,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<tuple<DAE.Exp, Boolean>> rest;
        Boolean i_b;
        DAE.Exp i_e;
        tuple<DAE.Exp, Boolean> i_col;
        Tpl.Text i_tmp;
        Tpl.Text i_expVar;
        Tpl.Text i_scalarRefStr;
        Tpl.Text i_scalarStr;
      equation
        i_scalarStr = fun_567(emptyTxt, i_b);
        i_scalarRefStr = fun_568(emptyTxt, i_b);
        (i_expVar, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
        (i_tmp, i_varDecls) = tempDecl(emptyTxt, i_arrayTypeStr, i_varDecls);
        i_varLstStr = Tpl.writeTok(i_varLstStr, Tpl.ST_STRING(", &"));
        i_varLstStr = Tpl.writeText(i_varLstStr, i_tmp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("promote_"));
        txt = Tpl.writeText(txt, i_scalarStr);
        txt = Tpl.writeStr(txt, i_arrayTypeStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_scalarRefStr);
        txt = Tpl.writeText(txt, i_expVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", 2, &"));
        txt = Tpl.writeText(txt, i_tmp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.nextIter(txt);
        (txt, i_varLstStr, i_varDecls, i_preExp) = lm_569(txt, rest, i_varLstStr, i_arrayTypeStr, i_varDecls, i_preExp, i_context);
      then (txt, i_varLstStr, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varLstStr,
           i_arrayTypeStr,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<tuple<DAE.Exp, Boolean>> rest;
      equation
        (txt, i_varLstStr, i_varDecls, i_preExp) = lm_569(txt, rest, i_varLstStr, i_arrayTypeStr, i_varDecls, i_preExp, i_context);
      then (txt, i_varLstStr, i_varDecls, i_preExp);
  end matchcontinue;
end lm_569;

public function daeExpMatrixRow
  input Tpl.Text txt;
  input list<tuple<DAE.Exp, Boolean>> i_row;
  input String i_arrayTypeStr;
  input SimCode.Context i_context;
  input Tpl.Text i_preExp;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
protected
  Tpl.Text i_preExp2;
  Tpl.Text i_varLstStr;
algorithm
  i_varLstStr := emptyTxt;
  i_preExp2 := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_preExp2, i_varLstStr, out_i_varDecls, out_i_preExp) := lm_569(i_preExp2, i_row, i_varLstStr, i_arrayTypeStr, i_varDecls, i_preExp, i_context);
  i_preExp2 := Tpl.popIter(i_preExp2);
  i_preExp2 := Tpl.writeTok(i_preExp2, Tpl.ST_NEW_LINE());
  out_i_preExp := Tpl.writeText(out_i_preExp, i_preExp2);
  out_txt := Tpl.writeText(txt, i_varLstStr);
end daeExpMatrixRow;

protected function fun_571
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;
  input Tpl.Text in_i_preExp;
  input DAE.Exp in_i_exp;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_expVar;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_ty, in_i_preExp, in_i_exp, in_i_varDecls, in_i_expVar)
    local
      Tpl.Text txt;
      Tpl.Text i_preExp;
      DAE.Exp i_exp;
      Tpl.Text i_varDecls;
      Tpl.Text i_expVar;

    case ( txt,
           DAE.ET_INT(),
           i_preExp,
           _,
           i_varDecls,
           i_expVar )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("((modelica_integer)"));
        txt = Tpl.writeText(txt, i_expVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_REAL(),
           i_preExp,
           _,
           i_varDecls,
           i_expVar )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("((modelica_real)"));
        txt = Tpl.writeText(txt, i_expVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_ARRAY(ty = i_ty),
           i_preExp,
           i_exp,
           i_varDecls,
           i_expVar )
      local
        DAE.ExpType i_ty;
        Tpl.Text i_from;
        Tpl.Text i_to;
        Tpl.Text i_tvar;
        Tpl.Text i_arrayTypeStr;
      equation
        i_arrayTypeStr = expTypeArray(emptyTxt, i_ty);
        (i_tvar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_arrayTypeStr), i_varDecls);
        i_to = expTypeShort(emptyTxt, i_ty);
        i_from = expTypeFromExpShort(emptyTxt, i_exp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("cast_"));
        i_preExp = Tpl.writeText(i_preExp, i_from);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("_array_to_"));
        i_preExp = Tpl.writeText(i_preExp, i_to);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(&"));
        i_preExp = Tpl.writeText(i_preExp, i_expVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_tvar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tvar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_preExp,
           _,
           i_varDecls,
           _ )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end fun_571;

public function daeExpCast
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.CAST(exp = i_exp, ty = i_ty),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_ty;
        DAE.Exp i_exp;
        Tpl.Text i_expVar;
      equation
        (i_expVar, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        (txt, i_preExp, i_varDecls) = fun_571(txt, i_ty, i_preExp, i_exp, i_varDecls, i_expVar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpCast;

protected function fun_573
  input Tpl.Text in_txt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input list<DAE.Exp> in_i_subs;
  input DAE.ExpType in_i_ecr_ty;
  input Tpl.Text in_i_arrName;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_i_context, in_i_varDecls, in_i_preExp, in_i_subs, in_i_ecr_ty, in_i_arrName)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      list<DAE.Exp> i_subs;
      DAE.ExpType i_ecr_ty;
      Tpl.Text i_arrName;

    case ( txt,
           SimCode.FUNCTION_CONTEXT(),
           i_varDecls,
           i_preExp,
           _,
           _,
           i_arrName )
      equation
        txt = Tpl.writeText(txt, i_arrName);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_context,
           i_varDecls,
           i_preExp,
           i_subs,
           i_ecr_ty,
           i_arrName )
      local
        SimCode.Context i_context;
      equation
        (txt, i_preExp, i_varDecls) = arrayScalarRhs(txt, i_ecr_ty, i_subs, Tpl.textString(i_arrName), i_context, i_preExp, i_varDecls);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_573;

public function daeExpAsub
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.ASUB(exp = DAE.RANGE(ty = i_t), sub = {i_idx}),
           _,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_idx;
        DAE.ExpType i_t;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("ASUB_EASY_CASE"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ASUB(exp = DAE.ASUB(exp = DAE.ASUB(exp = DAE.ASUB(exp = i_e, sub = {DAE.ICONST(integer = i_i)}), sub = {DAE.ICONST(integer = i_j)}), sub = {DAE.ICONST(integer = i_k)}), sub = {DAE.ICONST(integer = i_l)}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        Integer i_l;
        Integer i_k;
        Integer i_j;
        Integer i_i;
        DAE.Exp i_e;
        Integer ret_5;
        Integer ret_4;
        Integer ret_3;
        Integer ret_2;
        Tpl.Text i_typeShort;
        Tpl.Text i_e1;
      equation
        (i_e1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
        i_typeShort = expTypeFromExpShort(emptyTxt, i_e);
        txt = Tpl.writeText(txt, i_typeShort);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_get_4D(&"));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_2 = SimCode.incrementInt(i_i, -1);
        txt = Tpl.writeStr(txt, intString(ret_2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_3 = SimCode.incrementInt(i_j, -1);
        txt = Tpl.writeStr(txt, intString(ret_3));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_4 = SimCode.incrementInt(i_k, -1);
        txt = Tpl.writeStr(txt, intString(ret_4));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_5 = SimCode.incrementInt(i_l, -1);
        txt = Tpl.writeStr(txt, intString(ret_5));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ASUB(exp = DAE.ASUB(exp = DAE.ASUB(exp = i_e, sub = {DAE.ICONST(integer = i_i)}), sub = {DAE.ICONST(integer = i_j)}), sub = {DAE.ICONST(integer = i_k)}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        Integer i_k;
        Integer i_j;
        Integer i_i;
        DAE.Exp i_e;
        Integer ret_4;
        Integer ret_3;
        Integer ret_2;
        Tpl.Text i_typeShort;
        Tpl.Text i_e1;
      equation
        (i_e1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
        i_typeShort = expTypeFromExpShort(emptyTxt, i_e);
        txt = Tpl.writeText(txt, i_typeShort);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_get_3D(&"));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_2 = SimCode.incrementInt(i_i, -1);
        txt = Tpl.writeStr(txt, intString(ret_2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_3 = SimCode.incrementInt(i_j, -1);
        txt = Tpl.writeStr(txt, intString(ret_3));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_4 = SimCode.incrementInt(i_k, -1);
        txt = Tpl.writeStr(txt, intString(ret_4));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ASUB(exp = DAE.ASUB(exp = i_e, sub = {DAE.ICONST(integer = i_i)}), sub = {DAE.ICONST(integer = i_j)}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        Integer i_j;
        Integer i_i;
        DAE.Exp i_e;
        Integer ret_3;
        Integer ret_2;
        Tpl.Text i_typeShort;
        Tpl.Text i_e1;
      equation
        (i_e1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
        i_typeShort = expTypeFromExpShort(emptyTxt, i_e);
        txt = Tpl.writeText(txt, i_typeShort);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_get_2D(&"));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_2 = SimCode.incrementInt(i_i, -1);
        txt = Tpl.writeStr(txt, intString(ret_2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_3 = SimCode.incrementInt(i_j, -1);
        txt = Tpl.writeStr(txt, intString(ret_3));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ASUB(exp = i_e, sub = {DAE.ICONST(integer = i_i)}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        Integer i_i;
        DAE.Exp i_e;
        Integer ret_2;
        Tpl.Text i_typeShort;
        Tpl.Text i_e1;
      equation
        (i_e1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
        i_typeShort = expTypeFromExpShort(emptyTxt, i_e);
        txt = Tpl.writeText(txt, i_typeShort);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_get(&"));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_2 = SimCode.incrementInt(i_i, -1);
        txt = Tpl.writeStr(txt, intString(ret_2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ASUB(exp = (i_ecr as DAE.CREF(ty = i_ecr_ty)), sub = i_subs),
           i_context,
           i_preExp,
           i_varDecls )
      local
        list<DAE.Exp> i_subs;
        DAE.ExpType i_ecr_ty;
        DAE.Exp i_ecr;
        DAE.Exp ret_1;
        Tpl.Text i_arrName;
      equation
        ret_1 = SimCode.buildCrefExpFromAsub(i_ecr, i_subs);
        (i_arrName, i_preExp, i_varDecls) = daeExpCrefRhs(emptyTxt, ret_1, i_context, i_preExp, i_varDecls);
        (txt, i_varDecls, i_preExp) = fun_573(txt, i_context, i_varDecls, i_preExp, i_subs, i_ecr_ty, i_arrName);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("OTHER_ASUB"));
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpAsub;

public function daeExpSize
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.SIZE(exp = (i_exp as DAE.CREF(ty = i_exp_ty)), sz = SOME(i_dim)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_dim;
        DAE.ExpType i_exp_ty;
        DAE.Exp i_exp;
        Tpl.Text i_typeStr;
        Tpl.Text i_resVar;
        Tpl.Text i_dimPart;
        Tpl.Text i_expPart;
      equation
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        (i_dimPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_dim, i_context, i_preExp, i_varDecls);
        (i_resVar, i_varDecls) = tempDecl(emptyTxt, "modelica_integer", i_varDecls);
        i_typeStr = expTypeArray(emptyTxt, i_exp_ty);
        i_preExp = Tpl.writeText(i_preExp, i_resVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = size_of_dimension_"));
        i_preExp = Tpl.writeText(i_preExp, i_typeStr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("("));
        i_preExp = Tpl.writeText(i_preExp, i_expPart);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_dimPart);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_resVar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("size(X) not implemented"));
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpSize;

protected function fun_576
  input Tpl.Text in_txt;
  input String in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           "max" )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(modelica_real)"));
      then txt;

    case ( txt,
           "min" )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(modelica_real)"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_576;

public function daeExpReduction
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_exp as DAE.REDUCTION(path = Absyn.IDENT(name = i_op), expr = i_expr)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_expr;
        Absyn.Ident i_op;
        DAE.Exp i_exp;
        Tpl.Text i_body;
        String str_7;
        Tpl.Text i_cast;
        Tpl.Text i_tmpExpVar;
        Tpl.Text i_tmpExpPre;
        Tpl.Text i_res;
        Tpl.Text i_startValue;
        Tpl.Text i_accFun;
        Tpl.Text i_identType;
      equation
        i_identType = expTypeFromExpModelica(emptyTxt, i_expr);
        i_accFun = daeExpReductionFnName(emptyTxt, i_op, Tpl.textString(i_identType));
        i_startValue = daeExpReductionStartValue(emptyTxt, i_op, Tpl.textString(i_identType));
        (i_res, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_identType), i_varDecls);
        i_tmpExpPre = emptyTxt;
        (i_tmpExpVar, i_tmpExpPre, i_varDecls) = daeExp(emptyTxt, i_expr, i_context, i_tmpExpPre, i_varDecls);
        str_7 = Tpl.textString(i_accFun);
        i_cast = fun_576(emptyTxt, str_7);
        i_body = Tpl.writeText(emptyTxt, i_tmpExpPre);
        i_body = Tpl.softNewLine(i_body);
        i_body = Tpl.writeText(i_body, i_res);
        i_body = Tpl.writeTok(i_body, Tpl.ST_STRING(" = "));
        i_body = Tpl.writeText(i_body, i_accFun);
        i_body = Tpl.writeTok(i_body, Tpl.ST_STRING("("));
        i_body = Tpl.writeText(i_body, i_cast);
        i_body = Tpl.writeTok(i_body, Tpl.ST_STRING("("));
        i_body = Tpl.writeText(i_body, i_res);
        i_body = Tpl.writeTok(i_body, Tpl.ST_STRING("), "));
        i_body = Tpl.writeText(i_body, i_cast);
        i_body = Tpl.writeTok(i_body, Tpl.ST_STRING("("));
        i_body = Tpl.writeText(i_body, i_tmpExpVar);
        i_body = Tpl.writeTok(i_body, Tpl.ST_STRING("));"));
        i_preExp = Tpl.writeText(i_preExp, i_res);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = "));
        i_preExp = Tpl.writeText(i_preExp, i_startValue);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_LINE(";\n"));
        (i_preExp, i_body, i_varDecls) = daeExpReductionLoop(i_preExp, i_exp, i_body, i_context, i_varDecls);
        txt = Tpl.writeText(txt, i_res);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpReduction;

public function daeExpReductionLoop
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input Tpl.Text in_i_body;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_body;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_body, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_body, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_body;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.REDUCTION(range = (i_range as DAE.RANGE(ty = i_range_ty)), expr = i_expr, ident = i_ident),
           i_body,
           i_context,
           i_varDecls )
      local
        DAE.Ident i_ident;
        DAE.Exp i_expr;
        DAE.ExpType i_range_ty;
        DAE.Exp i_range;
        Tpl.Text i_identTypeShort;
        Tpl.Text i_identType;
      equation
        i_identType = expTypeModelica(emptyTxt, i_range_ty);
        i_identTypeShort = expTypeFromExpShort(emptyTxt, i_expr);
        (txt, i_body, i_varDecls) = algStmtForRange_impl(txt, i_range, i_ident, Tpl.textString(i_identType), Tpl.textString(i_identTypeShort), i_body, i_context, i_varDecls);
      then (txt, i_body, i_varDecls);

    case ( txt,
           DAE.REDUCTION(range = i_range, expr = i_expr, ident = i_ident),
           i_body,
           i_context,
           i_varDecls )
      local
        DAE.Ident i_ident;
        DAE.Exp i_expr;
        DAE.Exp i_range;
        Tpl.Text i_arrayType;
        Tpl.Text i_identType;
      equation
        i_identType = expTypeFromExpModelica(emptyTxt, i_expr);
        i_arrayType = expTypeFromExpArray(emptyTxt, i_expr);
        (txt, i_body, i_varDecls) = algStmtForGeneric_impl(txt, i_range, i_ident, Tpl.textString(i_identType), Tpl.textString(i_arrayType), false, i_body, i_context, i_varDecls);
      then (txt, i_body, i_varDecls);

    case ( txt,
           _,
           i_body,
           _,
           i_varDecls )
      then (txt, i_body, i_varDecls);
  end matchcontinue;
end daeExpReductionLoop;

protected function fun_579
  input Tpl.Text in_txt;
  input String in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type)
    local
      Tpl.Text txt;

    case ( txt,
           "modelica_integer" )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("intAdd"));
      then txt;

    case ( txt,
           "modelica_real" )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("realAdd"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("INVALID_TYPE"));
      then txt;
  end matchcontinue;
end fun_579;

protected function fun_580
  input Tpl.Text in_txt;
  input String in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type)
    local
      Tpl.Text txt;

    case ( txt,
           "modelica_integer" )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("intMul"));
      then txt;

    case ( txt,
           "modelica_real" )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("realMul"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("INVALID_TYPE"));
      then txt;
  end matchcontinue;
end fun_580;

public function daeExpReductionFnName
  input Tpl.Text in_txt;
  input String in_i_reduction__op;
  input String in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_reduction__op, in_i_type)
    local
      Tpl.Text txt;
      String i_type;

    case ( txt,
           "sum",
           i_type )
      equation
        txt = fun_579(txt, i_type);
      then txt;

    case ( txt,
           "product",
           i_type )
      equation
        txt = fun_580(txt, i_type);
      then txt;

    case ( txt,
           i_reduction__op,
           _ )
      local
        String i_reduction__op;
      equation
        txt = Tpl.writeStr(txt, i_reduction__op);
      then txt;
  end matchcontinue;
end daeExpReductionFnName;

protected function fun_582
  input Tpl.Text in_txt;
  input String in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type)
    local
      Tpl.Text txt;

    case ( txt,
           "modelica_integer" )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("1073741823"));
      then txt;

    case ( txt,
           "modelica_real" )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("1.e60"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("INVALID_TYPE"));
      then txt;
  end matchcontinue;
end fun_582;

protected function fun_583
  input Tpl.Text in_txt;
  input String in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type)
    local
      Tpl.Text txt;

    case ( txt,
           "modelica_integer" )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("-1073741823"));
      then txt;

    case ( txt,
           "modelica_real" )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("-1.e60"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("INVALID_TYPE"));
      then txt;
  end matchcontinue;
end fun_583;

public function daeExpReductionStartValue
  input Tpl.Text in_txt;
  input String in_i_reduction__op;
  input String in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_reduction__op, in_i_type)
    local
      Tpl.Text txt;
      String i_type;

    case ( txt,
           "min",
           i_type )
      equation
        txt = fun_582(txt, i_type);
      then txt;

    case ( txt,
           "max",
           i_type )
      equation
        txt = fun_583(txt, i_type);
      then txt;

    case ( txt,
           "sum",
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("0"));
      then txt;

    case ( txt,
           "product",
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("1"));
      then txt;

    case ( txt,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("UNKNOWN_REDUCTION"));
      then txt;
  end matchcontinue;
end daeExpReductionStartValue;

protected function lm_585
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_i_preExpInner;
  input Tpl.Text in_i_varDeclsInner;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExpInner;
  output Tpl.Text out_i_varDeclsInner;
algorithm
  (out_txt, out_i_preExpInner, out_i_varDeclsInner) :=
  matchcontinue(in_txt, in_items, in_i_preExpInner, in_i_varDeclsInner)
    local
      Tpl.Text txt;
      Tpl.Text i_preExpInner;
      Tpl.Text i_varDeclsInner;

    case ( txt,
           {},
           i_preExpInner,
           i_varDeclsInner )
      then (txt, i_preExpInner, i_varDeclsInner);

    case ( txt,
           i_var :: rest,
           i_preExpInner,
           i_varDeclsInner )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
      equation
        (txt, i_varDeclsInner, i_preExpInner) = varInit(txt, i_var, "", 0, i_varDeclsInner, i_preExpInner);
        (txt, i_preExpInner, i_varDeclsInner) = lm_585(txt, rest, i_preExpInner, i_varDeclsInner);
      then (txt, i_preExpInner, i_varDeclsInner);

    case ( txt,
           _ :: rest,
           i_preExpInner,
           i_varDeclsInner )
      local
        list<SimCode.Variable> rest;
      equation
        (txt, i_preExpInner, i_varDeclsInner) = lm_585(txt, rest, i_preExpInner, i_varDeclsInner);
      then (txt, i_preExpInner, i_varDeclsInner);
  end matchcontinue;
end lm_585;

protected function lm_586
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_i_ignore;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_ignore;
algorithm
  (out_txt, out_i_ignore) :=
  matchcontinue(in_txt, in_items, in_i_ignore)
    local
      Tpl.Text txt;
      Tpl.Text i_ignore;

    case ( txt,
           {},
           i_ignore )
      then (txt, i_ignore);

    case ( txt,
           i_var :: rest,
           i_ignore )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
      equation
        (txt, i_ignore) = functionArg(txt, i_var, i_ignore);
        txt = Tpl.nextIter(txt);
        (txt, i_ignore) = lm_586(txt, rest, i_ignore);
      then (txt, i_ignore);

    case ( txt,
           _ :: rest,
           i_ignore )
      local
        list<SimCode.Variable> rest;
      equation
        (txt, i_ignore) = lm_586(txt, rest, i_ignore);
      then (txt, i_ignore);
  end matchcontinue;
end lm_586;

protected function lm_587
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDeclsInner;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDeclsInner;
algorithm
  (out_txt, out_i_varDeclsInner) :=
  matchcontinue(in_txt, in_items, in_i_varDeclsInner, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDeclsInner;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDeclsInner,
           _ )
      then (txt, i_varDeclsInner);

    case ( txt,
           i_stmt :: rest,
           i_varDeclsInner,
           i_context )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDeclsInner) = algStatement(txt, i_stmt, i_context, i_varDeclsInner);
        txt = Tpl.nextIter(txt);
        (txt, i_varDeclsInner) = lm_587(txt, rest, i_varDeclsInner, i_context);
      then (txt, i_varDeclsInner);

    case ( txt,
           _ :: rest,
           i_varDeclsInner,
           i_context )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDeclsInner) = lm_587(txt, rest, i_varDeclsInner, i_context);
      then (txt, i_varDeclsInner);
  end matchcontinue;
end lm_587;

protected function fun_588
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_preExp) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;

    case ( txt,
           (i_exp as DAE.VALUEBLOCK(ty = i_ty, body = i_body, result = i_result)),
           i_context,
           i_preExp )
      local
        DAE.Exp i_result;
        list<DAE.Statement> i_body;
        DAE.ExpType i_ty;
        DAE.Exp i_exp;
        Tpl.Text i_expPart;
        Tpl.Text i_stmts;
        Tpl.Text txt_10;
        Tpl.Text i_res;
        Tpl.Text i_resType;
        list<SimCode.Variable> ret_7;
        Tpl.Text i_funArgs;
        list<SimCode.Variable> ret_5;
        Tpl.Text i_0__;
        Tpl.Text i_ignore;
        Tpl.Text i_varDeclsInner;
        Tpl.Text i_preExpRes;
        Tpl.Text i_preExpInner;
      equation
        i_preExpInner = emptyTxt;
        i_preExpRes = emptyTxt;
        i_varDeclsInner = emptyTxt;
        i_ignore = emptyTxt;
        ret_5 = SimCode.valueblockVars(i_exp);
        (i_0__, i_preExpInner, i_varDeclsInner) = lm_585(emptyTxt, ret_5, i_preExpInner, i_varDeclsInner);
        ret_7 = SimCode.valueblockVars(i_exp);
        i_funArgs = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_funArgs, i_ignore) = lm_586(i_funArgs, ret_7, i_ignore);
        i_funArgs = Tpl.popIter(i_funArgs);
        i_resType = expTypeModelica(emptyTxt, i_ty);
        txt_10 = expTypeModelica(emptyTxt, i_ty);
        (i_res, i_preExp) = tempDecl(emptyTxt, Tpl.textString(txt_10), i_preExp);
        i_stmts = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_stmts, i_varDeclsInner) = lm_587(i_stmts, i_body, i_varDeclsInner, i_context);
        i_stmts = Tpl.popIter(i_stmts);
        (i_expPart, i_preExpRes, i_varDeclsInner) = daeExp(emptyTxt, i_result, i_context, i_preExpRes, i_varDeclsInner);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_LINE("{\n"));
        i_preExp = Tpl.pushBlock(i_preExp, Tpl.BT_INDENT(2));
        i_preExp = Tpl.writeText(i_preExp, i_varDeclsInner);
        i_preExp = Tpl.softNewLine(i_preExp);
        i_preExp = Tpl.writeText(i_preExp, i_funArgs);
        i_preExp = Tpl.softNewLine(i_preExp);
        i_preExp = Tpl.writeText(i_preExp, i_preExpInner);
        i_preExp = Tpl.softNewLine(i_preExp);
        i_preExp = Tpl.writeText(i_preExp, i_stmts);
        i_preExp = Tpl.softNewLine(i_preExp);
        i_preExp = Tpl.writeText(i_preExp, i_preExpRes);
        i_preExp = Tpl.softNewLine(i_preExp);
        i_preExp = Tpl.writeText(i_preExp, i_res);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = "));
        i_preExp = Tpl.writeText(i_preExp, i_expPart);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_LINE(";\n"));
        i_preExp = Tpl.popBlock(i_preExp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("}"));
        txt = Tpl.writeText(txt, i_res);
      then (txt, i_preExp);

    case ( txt,
           _,
           _,
           i_preExp )
      then (txt, i_preExp);
  end matchcontinue;
end fun_588;

public function daeExpValueblock
  input Tpl.Text txt;
  input DAE.Exp i_exp;
  input SimCode.Context i_context;
  input Tpl.Text i_preExp;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp) := fun_588(txt, i_exp, i_context, i_preExp);
  out_i_varDecls := i_varDecls;
end daeExpValueblock;

protected function lm_590
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_exp :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_590(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_590(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_590;

public function arrayScalarRhs
  input Tpl.Text txt;
  input DAE.ExpType i_ty;
  input list<DAE.Exp> i_subs;
  input String i_arrName;
  input SimCode.Context i_context;
  input Tpl.Text i_preExp;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
protected
  Tpl.Text i_dimsValuesStr;
  Integer ret_2;
  Tpl.Text i_dimsLenStr;
  Tpl.Text i_arrayType;
algorithm
  i_arrayType := expTypeArray(emptyTxt, i_ty);
  ret_2 := listLength(i_subs);
  i_dimsLenStr := Tpl.writeStr(emptyTxt, intString(ret_2));
  i_dimsValuesStr := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_dimsValuesStr, out_i_varDecls, out_i_preExp) := lm_590(i_dimsValuesStr, i_subs, i_varDecls, i_preExp, i_context);
  i_dimsValuesStr := Tpl.popIter(i_dimsValuesStr);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("(*"));
  out_txt := Tpl.writeText(out_txt, i_arrayType);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("_element_addr(&"));
  out_txt := Tpl.writeStr(out_txt, i_arrName);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(", "));
  out_txt := Tpl.writeText(out_txt, i_dimsLenStr);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(", "));
  out_txt := Tpl.writeText(out_txt, i_dimsValuesStr);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("))"));
end arrayScalarRhs;

public function daeExpList
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.LIST(valList = i_valList),
           i_context,
           i_preExp,
           i_varDecls )
      local
        list<DAE.Exp> i_valList;
        Tpl.Text i_expPart;
        Tpl.Text i_tmp;
      equation
        (i_tmp, i_varDecls) = tempDecl(emptyTxt, "modelica_metatype", i_varDecls);
        (i_expPart, i_preExp, i_varDecls) = daeExpListToCons(emptyTxt, i_valList, i_context, i_preExp, i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_tmp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = "));
        i_preExp = Tpl.writeText(i_preExp, i_expPart);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(";"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tmp);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpList;

public function daeExpListToCons
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_i_listItems;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_listItems, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_nil()"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           i_e :: i_rest,
           i_context,
           i_preExp,
           i_varDecls )
      local
        list<DAE.Exp> i_rest;
        DAE.Exp i_e;
        Tpl.Text i_restList;
        Tpl.Text i_expPart;
      equation
        (i_expPart, i_preExp, i_varDecls) = daeExpMetaHelperConstant(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
        (i_restList, i_preExp, i_varDecls) = daeExpListToCons(emptyTxt, i_rest, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_cons("));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_restList);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpListToCons;

public function daeExpCons
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.CONS(car = i_car, cdr = i_cdr),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_cdr;
        DAE.Exp i_car;
        Tpl.Text i_cdrExp;
        Tpl.Text i_carExp;
        Tpl.Text i_tmp;
      equation
        (i_tmp, i_varDecls) = tempDecl(emptyTxt, "modelica_metatype", i_varDecls);
        (i_carExp, i_preExp, i_varDecls) = daeExpMetaHelperConstant(emptyTxt, i_car, i_context, i_preExp, i_varDecls);
        (i_cdrExp, i_preExp, i_varDecls) = daeExp(emptyTxt, i_cdr, i_context, i_preExp, i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_tmp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = mmc_mk_cons("));
        i_preExp = Tpl.writeText(i_preExp, i_carExp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_cdrExp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tmp);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpCons;

protected function lm_595
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_e :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpMetaHelperConstant(txt, i_e, i_context, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_595(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_595(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_595;

public function daeExpMetaTuple
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.META_TUPLE(listExp = i_listExp),
           i_context,
           i_preExp,
           i_varDecls )
      local
        list<DAE.Exp> i_listExp;
        Tpl.Text i_tmp;
        Tpl.Text i_args;
        Integer ret_1;
        Tpl.Text i_start;
      equation
        ret_1 = listLength(i_listExp);
        i_start = daeExpMetaHelperBoxStart(emptyTxt, ret_1);
        i_args = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_args, i_varDecls, i_preExp) = lm_595(i_args, i_listExp, i_varDecls, i_preExp, i_context);
        i_args = Tpl.popIter(i_args);
        (i_tmp, i_varDecls) = tempDecl(emptyTxt, "modelica_metatype", i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_tmp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = mmc_mk_box"));
        i_preExp = Tpl.writeText(i_preExp, i_start);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("0, "));
        i_preExp = Tpl.writeText(i_preExp, i_args);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tmp);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpMetaTuple;

public function daeExpMetaOption
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.META_OPTION(exp = NONE),
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_none()"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.META_OPTION(exp = SOME(i_e)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
        Tpl.Text i_expPart;
      equation
        (i_expPart, i_preExp, i_varDecls) = daeExpMetaHelperConstant(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_some("));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpMetaOption;

protected function lm_598
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_exp :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExpMetaHelperConstant(txt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_598(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_598(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_598;

protected function fun_599
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_i_args;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_i_args, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_args,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> i_args;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls, i_preExp) = lm_598(txt, i_args, i_varDecls, i_preExp, i_context);
        txt = Tpl.popIter(txt);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_599;

public function daeExpMetarecordcall
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.METARECORDCALL(index = i_index, args = i_args, path = i_path),
           i_context,
           i_preExp,
           i_varDecls )
      local
        Absyn.Path i_path;
        list<DAE.Exp> i_args;
        Integer i_index;
        Tpl.Text i_tmp;
        Integer ret_5;
        Integer ret_4;
        Tpl.Text i_box;
        Tpl.Text i_argsStr;
        Integer ret_1;
        Tpl.Text i_newIndex;
      equation
        ret_1 = SimCode.incrementInt(i_index, 3);
        i_newIndex = Tpl.writeStr(emptyTxt, intString(ret_1));
        (i_argsStr, i_varDecls, i_preExp) = fun_599(emptyTxt, i_args, i_varDecls, i_preExp, i_context);
        i_box = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("mmc_mk_box"));
        ret_4 = listLength(i_args);
        ret_5 = SimCode.incrementInt(ret_4, 1);
        i_box = daeExpMetaHelperBoxStart(i_box, ret_5);
        i_box = Tpl.writeText(i_box, i_newIndex);
        i_box = Tpl.writeTok(i_box, Tpl.ST_STRING(", &"));
        i_box = underscorePath(i_box, i_path);
        i_box = Tpl.writeTok(i_box, Tpl.ST_STRING("__desc"));
        i_box = Tpl.writeText(i_box, i_argsStr);
        i_box = Tpl.writeTok(i_box, Tpl.ST_STRING(")"));
        (i_tmp, i_varDecls) = tempDecl(emptyTxt, "modelica_metatype", i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_tmp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = "));
        i_preExp = Tpl.writeText(i_preExp, i_box);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(";"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tmp);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpMetarecordcall;

public function daeExpMetaHelperConstant
  input Tpl.Text txt;
  input DAE.Exp i_e;
  input SimCode.Context i_context;
  input Tpl.Text i_preExp;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
protected
  DAE.ExpType ret_1;
  Tpl.Text i_expPart;
algorithm
  (i_expPart, out_i_preExp, out_i_varDecls) := daeExp(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
  ret_1 := Exp.typeof(i_e);
  (out_txt, i_expPart, out_i_preExp, out_i_varDecls) := daeExpMetaHelperConstantNameType(txt, i_expPart, ret_1, out_i_preExp, out_i_varDecls);
end daeExpMetaHelperConstant;

protected function lm_602
  input Tpl.Text in_txt;
  input list<DAE.ExpVar> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varname;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp, in_i_varname)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      Tpl.Text i_varname;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           (i_v as DAE.COMPLEX_VAR(name = i_cvname, tp = i_tp)) :: rest,
           i_varDecls,
           i_preExp,
           i_varname )
      local
        list<DAE.ExpVar> rest;
        DAE.ExpType i_tp;
        String i_cvname;
        DAE.ExpVar i_v;
        Tpl.Text i_nameText;
      equation
        i_nameText = Tpl.writeText(emptyTxt, i_varname);
        i_nameText = Tpl.writeTok(i_nameText, Tpl.ST_STRING("."));
        i_nameText = Tpl.writeStr(i_nameText, i_cvname);
        (txt, i_nameText, i_preExp, i_varDecls) = daeExpMetaHelperConstantNameType(txt, i_nameText, i_tp, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_602(txt, rest, i_varDecls, i_preExp, i_varname);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp,
           i_varname )
      local
        list<DAE.ExpVar> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_602(txt, rest, i_varDecls, i_preExp, i_varname);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_602;

protected function fun_603
  input Tpl.Text in_txt;
  input list<DAE.ExpVar> in_i_varLst;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varname;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_i_varLst, in_i_varDecls, in_i_preExp, in_i_varname)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      Tpl.Text i_varname;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_varLst,
           i_varDecls,
           i_preExp,
           i_varname )
      local
        list<DAE.ExpVar> i_varLst;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls, i_preExp) = lm_602(txt, i_varLst, i_varDecls, i_preExp, i_varname);
        txt = Tpl.popIter(txt);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_603;

protected function fun_604
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_type;
  input Tpl.Text in_i_varname;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_type, in_i_varname, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varname;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.ET_INT(),
           i_varname,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_icon("));
        txt = Tpl.writeText(txt, i_varname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_BOOL(),
           i_varname,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_icon("));
        txt = Tpl.writeText(txt, i_varname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_REAL(),
           i_varname,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_rcon("));
        txt = Tpl.writeText(txt, i_varname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_STRING(),
           i_varname,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_scon("));
        txt = Tpl.writeText(txt, i_varname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_COMPLEX(name = i_cname, varLst = i_varLst),
           i_varname,
           i_preExp,
           i_varDecls )
      local
        list<DAE.ExpVar> i_varLst;
        Absyn.Path i_cname;
        Tpl.Text i_args;
        Integer ret_2;
        Integer ret_1;
        Tpl.Text i_start;
      equation
        ret_1 = listLength(i_varLst);
        ret_2 = SimCode.incrementInt(ret_1, 1);
        i_start = daeExpMetaHelperBoxStart(emptyTxt, ret_2);
        (i_args, i_varDecls, i_preExp) = fun_603(emptyTxt, i_varLst, i_varDecls, i_preExp, i_varname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_box"));
        txt = Tpl.writeText(txt, i_start);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("2, &"));
        txt = underscorePath(txt, i_cname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("__desc"));
        txt = Tpl.writeText(txt, i_args);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_varname,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeText(txt, i_varname);
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end fun_604;

public function daeExpMetaHelperConstantNameType
  input Tpl.Text txt;
  input Tpl.Text i_varname;
  input DAE.ExpType i_type;
  input Tpl.Text i_preExp;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varname;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) := fun_604(txt, i_type, i_varname, i_preExp, i_varDecls);
  out_i_varname := i_varname;
end daeExpMetaHelperConstantNameType;

public function daeExpMetaHelperBoxStart
  input Tpl.Text in_txt;
  input Integer in_i_numVariables;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_numVariables)
    local
      Tpl.Text txt;

    case ( txt,
           (i_numVariables as 0) )
      local
        Integer i_numVariables;
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 1) )
      local
        Integer i_numVariables;
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 2) )
      local
        Integer i_numVariables;
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 3) )
      local
        Integer i_numVariables;
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 4) )
      local
        Integer i_numVariables;
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 5) )
      local
        Integer i_numVariables;
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 6) )
      local
        Integer i_numVariables;
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 7) )
      local
        Integer i_numVariables;
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 8) )
      local
        Integer i_numVariables;
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 9) )
      local
        Integer i_numVariables;
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           i_numVariables )
      local
        Integer i_numVariables;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
      then txt;
  end matchcontinue;
end daeExpMetaHelperBoxStart;

public function outDecl
  input Tpl.Text txt;
  input String i_ty;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
protected
  Tpl.Text i_newVar;
algorithm
  i_newVar := Tpl.writeTok(emptyTxt, Tpl.ST_STRING("out"));
  out_i_varDecls := Tpl.writeStr(i_varDecls, i_ty);
  out_i_varDecls := Tpl.writeTok(out_i_varDecls, Tpl.ST_STRING(" "));
  out_i_varDecls := Tpl.writeText(out_i_varDecls, i_newVar);
  out_i_varDecls := Tpl.writeTok(out_i_varDecls, Tpl.ST_STRING(";"));
  out_i_varDecls := Tpl.writeTok(out_i_varDecls, Tpl.ST_NEW_LINE());
  out_txt := Tpl.writeText(txt, i_newVar);
end outDecl;

public function tempDecl
  input Tpl.Text txt;
  input String i_ty;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
protected
  Integer ret_1;
  Tpl.Text i_newVar;
algorithm
  i_newVar := Tpl.writeTok(emptyTxt, Tpl.ST_STRING("tmp"));
  ret_1 := System.tmpTick();
  i_newVar := Tpl.writeStr(i_newVar, intString(ret_1));
  out_i_varDecls := Tpl.writeStr(i_varDecls, i_ty);
  out_i_varDecls := Tpl.writeTok(out_i_varDecls, Tpl.ST_STRING(" "));
  out_i_varDecls := Tpl.writeText(out_i_varDecls, i_newVar);
  out_i_varDecls := Tpl.writeTok(out_i_varDecls, Tpl.ST_STRING(";"));
  out_i_varDecls := Tpl.writeTok(out_i_varDecls, Tpl.ST_NEW_LINE());
  out_txt := Tpl.writeText(txt, i_newVar);
end tempDecl;

public function tempDeclConst
  input Tpl.Text txt;
  input String i_ty;
  input String i_val;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
protected
  Integer ret_1;
  Tpl.Text i_newVar;
algorithm
  i_newVar := Tpl.writeTok(emptyTxt, Tpl.ST_STRING("tmp"));
  ret_1 := System.tmpTick();
  i_newVar := Tpl.writeStr(i_newVar, intString(ret_1));
  out_i_varDecls := Tpl.writeStr(i_varDecls, i_ty);
  out_i_varDecls := Tpl.writeTok(out_i_varDecls, Tpl.ST_STRING(" "));
  out_i_varDecls := Tpl.writeText(out_i_varDecls, i_newVar);
  out_i_varDecls := Tpl.writeTok(out_i_varDecls, Tpl.ST_STRING(" = "));
  out_i_varDecls := Tpl.writeStr(out_i_varDecls, i_val);
  out_i_varDecls := Tpl.writeTok(out_i_varDecls, Tpl.ST_STRING(";"));
  out_i_varDecls := Tpl.writeTok(out_i_varDecls, Tpl.ST_NEW_LINE());
  out_txt := Tpl.writeText(txt, i_newVar);
end tempDeclConst;

protected function fun_610
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_i_instDims;
  input DAE.ExpType in_i_var_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_instDims, in_i_var_ty)
    local
      Tpl.Text txt;
      DAE.ExpType i_var_ty;

    case ( txt,
           {},
           i_var_ty )
      equation
        txt = expTypeArrayIf(txt, i_var_ty);
      then txt;

    case ( txt,
           _,
           i_var_ty )
      equation
        txt = expTypeArray(txt, i_var_ty);
      then txt;
  end matchcontinue;
end fun_610;

public function varType
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_var)
    local
      Tpl.Text txt;

    case ( txt,
           (i_var as SimCode.VARIABLE(instDims = i_instDims, ty = i_var_ty)) )
      local
        DAE.ExpType i_var_ty;
        list<DAE.Exp> i_instDims;
        SimCode.Variable i_var;
      equation
        txt = fun_610(txt, i_instDims, i_var_ty);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end varType;

public function varTypeBoxed
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_var)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.VARIABLE(name = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_metatype"));
      then txt;

    case ( txt,
           SimCode.FUNCTION_PTR(name = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_fnptr"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end varTypeBoxed;

public function expTypeRW
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_INT() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("TYPE_DESC_INT"));
      then txt;

    case ( txt,
           DAE.ET_REAL() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("TYPE_DESC_REAL"));
      then txt;

    case ( txt,
           DAE.ET_STRING() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("TYPE_DESC_STRING"));
      then txt;

    case ( txt,
           DAE.ET_BOOL() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("TYPE_DESC_BOOL"));
      then txt;

    case ( txt,
           DAE.ET_ARRAY(ty = i_ty) )
      local
        DAE.ExpType i_ty;
      equation
        txt = expTypeRW(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_ARRAY"));
      then txt;

    case ( txt,
           DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(path = _)) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("TYPE_DESC_RECORD"));
      then txt;

    case ( txt,
           DAE.ET_METAOPTION(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("TYPE_DESC_MMC"));
      then txt;

    case ( txt,
           DAE.ET_LIST(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("TYPE_DESC_MMC"));
      then txt;

    case ( txt,
           DAE.ET_METATUPLE(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("TYPE_DESC_MMC"));
      then txt;

    case ( txt,
           DAE.ET_UNIONTYPE() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("TYPE_DESC_MMC"));
      then txt;

    case ( txt,
           DAE.ET_POLYMORPHIC() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("TYPE_DESC_MMC"));
      then txt;

    case ( txt,
           DAE.ET_META_ARRAY(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("TYPE_DESC_MMC"));
      then txt;

    case ( txt,
           DAE.ET_BOXED(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("TYPE_DESC_MMC"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end expTypeRW;

public function expTypeShort
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_INT() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer"));
      then txt;

    case ( txt,
           DAE.ET_REAL() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real"));
      then txt;

    case ( txt,
           DAE.ET_STRING() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("string"));
      then txt;

    case ( txt,
           DAE.ET_BOOL() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("boolean"));
      then txt;

    case ( txt,
           DAE.ET_ENUMERATION(path = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer"));
      then txt;

    case ( txt,
           DAE.ET_OTHER() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("complex"));
      then txt;

    case ( txt,
           DAE.ET_ARRAY(ty = i_ty) )
      local
        DAE.ExpType i_ty;
      equation
        txt = expTypeShort(txt, i_ty);
      then txt;

    case ( txt,
           DAE.ET_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path = _)) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("complex"));
      then txt;

    case ( txt,
           DAE.ET_COMPLEX(name = i_name) )
      local
        Absyn.Path i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("struct "));
        txt = underscorePath(txt, i_name);
      then txt;

    case ( txt,
           DAE.ET_LIST(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("metatype"));
      then txt;

    case ( txt,
           DAE.ET_METATUPLE(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("metatype"));
      then txt;

    case ( txt,
           DAE.ET_METAOPTION(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("metatype"));
      then txt;

    case ( txt,
           DAE.ET_UNIONTYPE() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("metatype"));
      then txt;

    case ( txt,
           DAE.ET_POLYMORPHIC() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("metatype"));
      then txt;

    case ( txt,
           DAE.ET_META_ARRAY(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("metatype"));
      then txt;

    case ( txt,
           DAE.ET_BOXED(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("metatype"));
      then txt;

    case ( txt,
           DAE.ET_FUNCTION_REFERENCE_VAR() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("fnptr"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("expTypeShort:ERROR"));
      then txt;
  end matchcontinue;
end expTypeShort;

public function mmcVarType
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_var)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.VARIABLE(ty = i_ty) )
      local
        DAE.ExpType i_ty;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_"));
        txt = mmcExpTypeShort(txt, i_ty);
      then txt;

    case ( txt,
           SimCode.FUNCTION_PTR(name = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_fnptr"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end mmcVarType;

public function mmcExpTypeShort
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_INT() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer"));
      then txt;

    case ( txt,
           DAE.ET_REAL() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real"));
      then txt;

    case ( txt,
           DAE.ET_STRING() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("string"));
      then txt;

    case ( txt,
           DAE.ET_BOOL() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer"));
      then txt;

    case ( txt,
           DAE.ET_ARRAY(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("array"));
      then txt;

    case ( txt,
           DAE.ET_LIST(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("metatype"));
      then txt;

    case ( txt,
           DAE.ET_METATUPLE(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("metatype"));
      then txt;

    case ( txt,
           DAE.ET_METAOPTION(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("metatype"));
      then txt;

    case ( txt,
           DAE.ET_UNIONTYPE() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("metatype"));
      then txt;

    case ( txt,
           DAE.ET_POLYMORPHIC() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("metatype"));
      then txt;

    case ( txt,
           DAE.ET_META_ARRAY(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("metatype"));
      then txt;

    case ( txt,
           DAE.ET_BOXED(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("metatype"));
      then txt;

    case ( txt,
           DAE.ET_FUNCTION_REFERENCE_VAR() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("fnptr"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmcExpTypeShort:ERROR"));
      then txt;
  end matchcontinue;
end mmcExpTypeShort;

protected function fun_617
  input Tpl.Text in_txt;
  input Boolean in_i_array;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_array, in_i_ty)
    local
      Tpl.Text txt;
      DAE.ExpType i_ty;

    case ( txt,
           true,
           i_ty )
      equation
        txt = expTypeArray(txt, i_ty);
      then txt;

    case ( txt,
           false,
           i_ty )
      equation
        txt = expTypeModelica(txt, i_ty);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_617;

public function expType
  input Tpl.Text txt;
  input DAE.ExpType i_ty;
  input Boolean i_array;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_617(txt, i_array, i_ty);
end expType;

public function expTypeModelica
  input Tpl.Text txt;
  input DAE.ExpType i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt := expTypeFlag(txt, i_ty, 2);
end expTypeModelica;

public function expTypeArray
  input Tpl.Text txt;
  input DAE.ExpType i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt := expTypeFlag(txt, i_ty, 3);
end expTypeArray;

public function expTypeArrayIf
  input Tpl.Text txt;
  input DAE.ExpType i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt := expTypeFlag(txt, i_ty, 4);
end expTypeArrayIf;

public function expTypeFromExpShort
  input Tpl.Text txt;
  input DAE.Exp i_exp;

  output Tpl.Text out_txt;
algorithm
  out_txt := expTypeFromExpFlag(txt, i_exp, 1);
end expTypeFromExpShort;

public function expTypeFromExpModelica
  input Tpl.Text txt;
  input DAE.Exp i_exp;

  output Tpl.Text out_txt;
algorithm
  out_txt := expTypeFromExpFlag(txt, i_exp, 2);
end expTypeFromExpModelica;

public function expTypeFromExpArray
  input Tpl.Text txt;
  input DAE.Exp i_exp;

  output Tpl.Text out_txt;
algorithm
  out_txt := expTypeFromExpFlag(txt, i_exp, 3);
end expTypeFromExpArray;

public function expTypeFromExpArrayIf
  input Tpl.Text txt;
  input DAE.Exp i_exp;

  output Tpl.Text out_txt;
algorithm
  out_txt := expTypeFromExpFlag(txt, i_exp, 4);
end expTypeFromExpArrayIf;

protected function fun_626
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_COMPLEX(name = i_name) )
      local
        Absyn.Path i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("struct "));
        txt = underscorePath(txt, i_name);
      then txt;

    case ( txt,
           i_ty )
      local
        DAE.ExpType i_ty;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_"));
        txt = expTypeShort(txt, i_ty);
      then txt;
  end matchcontinue;
end fun_626;

protected function fun_627
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ty)
    local
      Tpl.Text txt;

    case ( txt,
           (i_ty as DAE.ET_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path = _))) )
      local
        DAE.ExpType i_ty;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_"));
        txt = expTypeShort(txt, i_ty);
      then txt;

    case ( txt,
           i_ty )
      local
        DAE.ExpType i_ty;
      equation
        txt = fun_626(txt, i_ty);
      then txt;
  end matchcontinue;
end fun_627;

protected function fun_628
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(ty = i_ty) )
      local
        DAE.ExpType i_ty;
      equation
        txt = expTypeShort(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array"));
      then txt;

    case ( txt,
           i_ty )
      local
        DAE.ExpType i_ty;
      equation
        txt = expTypeFlag(txt, i_ty, 2);
      then txt;
  end matchcontinue;
end fun_628;

protected function fun_629
  input Tpl.Text in_txt;
  input Integer in_i_flag;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_flag, in_i_ty)
    local
      Tpl.Text txt;
      DAE.ExpType i_ty;

    case ( txt,
           1,
           i_ty )
      equation
        txt = expTypeShort(txt, i_ty);
      then txt;

    case ( txt,
           2,
           i_ty )
      equation
        txt = fun_627(txt, i_ty);
      then txt;

    case ( txt,
           3,
           i_ty )
      equation
        txt = expTypeShort(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array"));
      then txt;

    case ( txt,
           4,
           i_ty )
      equation
        txt = fun_628(txt, i_ty);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_629;

public function expTypeFlag
  input Tpl.Text txt;
  input DAE.ExpType i_ty;
  input Integer i_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_629(txt, i_flag, i_ty);
end expTypeFlag;

protected function fun_631
  input Tpl.Text in_txt;
  input Integer in_i_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_flag)
    local
      Tpl.Text txt;

    case ( txt,
           1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_integer"));
      then txt;
  end matchcontinue;
end fun_631;

protected function fun_632
  input Tpl.Text in_txt;
  input Integer in_i_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_flag)
    local
      Tpl.Text txt;

    case ( txt,
           1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_real"));
      then txt;
  end matchcontinue;
end fun_632;

protected function fun_633
  input Tpl.Text in_txt;
  input Integer in_i_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_flag)
    local
      Tpl.Text txt;

    case ( txt,
           1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("string"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_string"));
      then txt;
  end matchcontinue;
end fun_633;

protected function fun_634
  input Tpl.Text in_txt;
  input Integer in_i_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_flag)
    local
      Tpl.Text txt;

    case ( txt,
           1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("boolean"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_boolean"));
      then txt;
  end matchcontinue;
end fun_634;

public function expTypeFromExpFlag
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input Integer in_i_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_exp, in_i_flag)
    local
      Tpl.Text txt;
      Integer i_flag;

    case ( txt,
           DAE.ICONST(integer = _),
           i_flag )
      equation
        txt = fun_631(txt, i_flag);
      then txt;

    case ( txt,
           DAE.RCONST(real = _),
           i_flag )
      equation
        txt = fun_632(txt, i_flag);
      then txt;

    case ( txt,
           DAE.SCONST(string = _),
           i_flag )
      equation
        txt = fun_633(txt, i_flag);
      then txt;

    case ( txt,
           DAE.BCONST(bool = _),
           i_flag )
      equation
        txt = fun_634(txt, i_flag);
      then txt;

    case ( txt,
           (i_e as DAE.BINARY(operator = i_e_operator)),
           i_flag )
      local
        DAE.Operator i_e_operator;
        DAE.Exp i_e;
      equation
        txt = expTypeFromOpFlag(txt, i_e_operator, i_flag);
      then txt;

    case ( txt,
           (i_e as DAE.UNARY(operator = i_e_operator)),
           i_flag )
      local
        DAE.Operator i_e_operator;
        DAE.Exp i_e;
      equation
        txt = expTypeFromOpFlag(txt, i_e_operator, i_flag);
      then txt;

    case ( txt,
           (i_e as DAE.LBINARY(operator = i_e_operator)),
           i_flag )
      local
        DAE.Operator i_e_operator;
        DAE.Exp i_e;
      equation
        txt = expTypeFromOpFlag(txt, i_e_operator, i_flag);
      then txt;

    case ( txt,
           (i_e as DAE.LUNARY(operator = i_e_operator)),
           i_flag )
      local
        DAE.Operator i_e_operator;
        DAE.Exp i_e;
      equation
        txt = expTypeFromOpFlag(txt, i_e_operator, i_flag);
      then txt;

    case ( txt,
           (i_e as DAE.RELATION(operator = i_e_operator)),
           i_flag )
      local
        DAE.Operator i_e_operator;
        DAE.Exp i_e;
      equation
        txt = expTypeFromOpFlag(txt, i_e_operator, i_flag);
      then txt;

    case ( txt,
           DAE.IFEXP(expThen = i_expThen),
           i_flag )
      local
        DAE.Exp i_expThen;
      equation
        txt = expTypeFromExpFlag(txt, i_expThen, i_flag);
      then txt;

    case ( txt,
           DAE.CALL(ty = i_ty),
           i_flag )
      local
        DAE.ExpType i_ty;
      equation
        txt = expTypeFlag(txt, i_ty, i_flag);
      then txt;

    case ( txt,
           (i_c as DAE.ARRAY(ty = i_c_ty)),
           i_flag )
      local
        DAE.ExpType i_c_ty;
        DAE.Exp i_c;
      equation
        txt = expTypeFlag(txt, i_c_ty, i_flag);
      then txt;

    case ( txt,
           (i_c as DAE.MATRIX(ty = i_c_ty)),
           i_flag )
      local
        DAE.ExpType i_c_ty;
        DAE.Exp i_c;
      equation
        txt = expTypeFlag(txt, i_c_ty, i_flag);
      then txt;

    case ( txt,
           (i_c as DAE.RANGE(ty = i_c_ty)),
           i_flag )
      local
        DAE.ExpType i_c_ty;
        DAE.Exp i_c;
      equation
        txt = expTypeFlag(txt, i_c_ty, i_flag);
      then txt;

    case ( txt,
           (i_c as DAE.CAST(ty = i_c_ty)),
           i_flag )
      local
        DAE.ExpType i_c_ty;
        DAE.Exp i_c;
      equation
        txt = expTypeFlag(txt, i_c_ty, i_flag);
      then txt;

    case ( txt,
           (i_c as DAE.CREF(ty = i_c_ty)),
           i_flag )
      local
        DAE.ExpType i_c_ty;
        DAE.Exp i_c;
      equation
        txt = expTypeFlag(txt, i_c_ty, i_flag);
      then txt;

    case ( txt,
           (i_c as DAE.CODE(ty = i_c_ty)),
           i_flag )
      local
        DAE.ExpType i_c_ty;
        DAE.Exp i_c;
      equation
        txt = expTypeFlag(txt, i_c_ty, i_flag);
      then txt;

    case ( txt,
           DAE.ASUB(exp = i_exp),
           i_flag )
      local
        DAE.Exp i_exp;
      equation
        txt = expTypeFromExpFlag(txt, i_exp, i_flag);
      then txt;

    case ( txt,
           DAE.REDUCTION(expr = i_expr),
           i_flag )
      local
        DAE.Exp i_expr;
      equation
        txt = expTypeFromExpFlag(txt, i_expr, i_flag);
      then txt;

    case ( txt,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("expTypeFromExpFlag:ERROR"));
      then txt;
  end matchcontinue;
end expTypeFromExpFlag;

protected function fun_636
  input Tpl.Text in_txt;
  input Integer in_i_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_flag)
    local
      Tpl.Text txt;

    case ( txt,
           1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("boolean"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_boolean"));
      then txt;
  end matchcontinue;
end fun_636;

protected function fun_637
  input Tpl.Text in_txt;
  input Integer in_i_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_flag)
    local
      Tpl.Text txt;

    case ( txt,
           1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("boolean"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_boolean"));
      then txt;
  end matchcontinue;
end fun_637;

protected function fun_638
  input Tpl.Text in_txt;
  input Integer in_i_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_flag)
    local
      Tpl.Text txt;

    case ( txt,
           1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("boolean"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_boolean"));
      then txt;
  end matchcontinue;
end fun_638;

public function expTypeFromOpFlag
  input Tpl.Text in_txt;
  input DAE.Operator in_i_op;
  input Integer in_i_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_op, in_i_flag)
    local
      Tpl.Text txt;
      Integer i_flag;

    case ( txt,
           (i_o as DAE.ADD(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.SUB(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.MUL(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.DIV(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.POW(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.UMINUS(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.UPLUS(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.UMINUS_ARR(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.UPLUS_ARR(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.ADD_ARR(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.SUB_ARR(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.MUL_ARR(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.DIV_ARR(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.MUL_SCALAR_ARRAY(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.MUL_ARRAY_SCALAR(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.ADD_SCALAR_ARRAY(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.ADD_ARRAY_SCALAR(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.SUB_SCALAR_ARRAY(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.SUB_ARRAY_SCALAR(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.MUL_SCALAR_PRODUCT(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.MUL_MATRIX_PRODUCT(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.DIV_ARRAY_SCALAR(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.DIV_SCALAR_ARRAY(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.POW_ARRAY_SCALAR(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.POW_SCALAR_ARRAY(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.POW_ARR(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.POW_ARR2(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.LESS(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.LESSEQ(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.GREATER(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.GREATEREQ(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.EQUAL(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.NEQUAL(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.AND()),
           i_flag )
      local
        DAE.Operator i_o;
      equation
        txt = fun_636(txt, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.OR()),
           i_flag )
      local
        DAE.Operator i_o;
      equation
        txt = fun_637(txt, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.NOT()),
           i_flag )
      local
        DAE.Operator i_o;
      equation
        txt = fun_638(txt, i_flag);
      then txt;

    case ( txt,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("expTypeFromOpFlag:ERROR"));
      then txt;
  end matchcontinue;
end expTypeFromOpFlag;

public function dimension
  input Tpl.Text in_txt;
  input DAE.Dimension in_i_d;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_d)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.DIM_INTEGER(integer = i_integer) )
      local
        Integer i_integer;
      equation
        txt = Tpl.writeStr(txt, intString(i_integer));
      then txt;

    case ( txt,
           DAE.DIM_ENUM(size = i_size) )
      local
        Integer i_size;
      equation
        txt = Tpl.writeStr(txt, intString(i_size));
      then txt;

    case ( txt,
           DAE.DIM_UNKNOWN() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(":"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("INVALID_DIMENSION"));
      then txt;
  end matchcontinue;
end dimension;

end SimCodeC;