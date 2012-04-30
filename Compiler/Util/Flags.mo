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

encapsulated package Flags
" file:        Flags.mo
  package:     Flags
  description: Tools for using compiler flags.

  RCS: $Id$

  This package contains function for using compiler flags. There are two types
  of flags, debug flag and configuration flags. The flags are stored and
  retrieved with set/getGlobalRoot so that they can be accessed everywhere in
  the compiler.
  
  Configuration flags are flags such as +std which affects the behaviour of the
  compiler. These flags can have different types, see the FlagData uniontype
  below, and they also have a default value. There is also another package,
  Config, which acts as a wrapper for many of these flags.
    
  Debug flags are boolean flags specified with +d, which can be used together
  with the Debug package. They are typically used to enable printing of extra
  information that helps debugging, such as the failtrace flag. All debug flags
  are initialised to disabled, unlike configuration flags which have a specified
  default value.

  To add a new flag, simply add a new constant of either DebugFlag or ConfigFlag
  type below, and then add it to either the allDebugFlags or allConfigFlags list
  depending on which type it is.
  "

protected import Corba;
protected import Debug;
protected import Error;
protected import ErrorExt;
protected import Global; 
protected import List;
protected import Settings;
protected import System;
protected import Util;

public uniontype DebugFlag
  record DEBUG_FLAG
    Integer index "Unique index.";
    String name "The name of the flag used by +d";
    String description "A description of the flag.";
  end DEBUG_FLAG;
end DebugFlag;

public uniontype ConfigFlag
  record CONFIG_FLAG
    Integer index "Unique index.";
    String name "The whole name of the flag.";
    Option<String> shortname "A short name one-character name for the flag.";
    FlagVisibility visibility "Whether the flag is visible to the user or not.";
    FlagData defaultValue "The default value of the flag.";
    Option<ValidOptions> validOptions "The valid options for the flag.";
    String description "A description of the flag.";
  end CONFIG_FLAG;
end ConfigFlag;

public uniontype FlagData
  "This uniontype is used to store the values of configuration flags."

  record EMPTY_FLAG 
    "Only used to initialize the flag array."
  end EMPTY_FLAG;

  record BOOL_FLAG
    "Value of a boolean flag."
    Boolean data;
  end BOOL_FLAG;

  record INT_FLAG
    "Value of an integer flag."
    Integer data;
  end INT_FLAG;

  record REAL_FLAG
    "Value of a real flag."
    Real data;
  end REAL_FLAG;

  record STRING_FLAG
    "Value of a string flag."
    String data;
  end STRING_FLAG;

  record STRING_LIST_FLAG
    "Values of a string flag that can have multiple values."
    list<String> data;
  end STRING_LIST_FLAG;

  record ENUM_FLAG
    "Value of an enumeration flag."
    Integer data;
    list<tuple<String, Integer>> validValues "The valid values of the enum.";
  end ENUM_FLAG; 
end FlagData;

public uniontype FlagVisibility
  "This uniontype is used to specify the visibility of a configuration flag."
  record INTERNAL "An internal flag that is hidden to the user." end INTERNAL;
  record EXTERNAL "An external flag that is visible to the user." end EXTERNAL;
end FlagVisibility;

public uniontype Flags
  "The structure which stores the flags."
  record FLAGS
    array<Boolean> debugFlags;
    array<FlagData> configFlags;
  end FLAGS;
end Flags;

public uniontype ValidOptions
  "Specifies valid options for a flag."

  record STRING_OPTION
    "Options for a string flag."
    list<String> options;
  end STRING_OPTION;

  record STRING_DESC_OPTION
    "Options for a string flag, with a description for each option."
    list<tuple<String, String>> options;
  end STRING_DESC_OPTION;
end ValidOptions;

// Change this to a proper enum when we have support for them.
public constant Integer MODELICA = 1;
public constant Integer METAMODELICA = 2;
public constant Integer PARMODELICA = 3;

// DEBUG FLAGS
public
constant DebugFlag FAILTRACE = DEBUG_FLAG(1, "failtrace",
  "Sets whether to print a failtrace or not.");
constant DebugFlag CEVAL = DEBUG_FLAG(2, "ceval",
  "Prints extra information from Ceval.");
constant DebugFlag LINEARIZATION = DEBUG_FLAG(3, "linearization",
  "");
constant DebugFlag JACOBIAN = DEBUG_FLAG(4, "jacobian", 
  "");
constant DebugFlag CHECK_BACKEND_DAE = DEBUG_FLAG(5, "checkBackendDae",
  "");
constant DebugFlag DUMP_INIT = DEBUG_FLAG(6, "dumpInit",
  "");
constant DebugFlag OPENMP = DEBUG_FLAG(7, "openmp",
  "");
constant DebugFlag PTHREADS = DEBUG_FLAG(8, "pthreads",
  "");
constant DebugFlag TEARING = DEBUG_FLAG(9, "tearing",
  "");
constant DebugFlag RELAXATION = DEBUG_FLAG(10, "relaxation",
  "");
constant DebugFlag NO_EVENTS = DEBUG_FLAG(11, "noevents",
  "");
constant DebugFlag EVAL_FUNC = DEBUG_FLAG(12, "evalfunc",
  "Prints extra failtrace from CevalFunction.");
constant DebugFlag NO_EVAL_FUNC = DEBUG_FLAG(13, "noevalfunc",
  "Turns off function evaluation and uses dynamic loading instead.");
constant DebugFlag NO_GEN = DEBUG_FLAG(14, "nogen",
  "Turns off dynamic loading of functions.");
constant DebugFlag DYN_LOAD = DEBUG_FLAG(15, "dynload",
  "Display debug information about dynamic loading of compiled functions.");
constant DebugFlag GENERATE_CODE_CHEAT = DEBUG_FLAG(16, "generateCodeCheat",
  "");
constant DebugFlag CGRAPH_GRAPHVIZ_FILE = DEBUG_FLAG(17, "cgraphGraphVizFile",
  "Generates a graphviz file of the connection graph.");
constant DebugFlag CGRAPH_GRAPHVIZ_SHOW = DEBUG_FLAG(18, "cgraphGraphVizShow",
  "Displays the connection graph with the GraphViz lefty tool");
constant DebugFlag FRONTEND_INLINE_EULER = DEBUG_FLAG(19, "frontend-inline-euler",
  "");
constant DebugFlag USEDEP = DEBUG_FLAG(20, "usedep",
  "");
constant DebugFlag ENV = DEBUG_FLAG(21, "env",
  "");
constant DebugFlag CHECK_DAE_CREF_TYPE = DEBUG_FLAG(22, "checkDAECrefType",
  "");
constant DebugFlag CHECK_ASUB = DEBUG_FLAG(23, "checkASUB",
  "Prints out a warning if an ASUB is created from a CREF expression.");
constant DebugFlag INSTANCE = DEBUG_FLAG(24, "instance",
  "Prints extra failtrace from InstanceHierarchy.");
constant DebugFlag NO_CACHE = DEBUG_FLAG(25, "noCache",
  "Turns off the instantiation cache.");
constant DebugFlag RML = DEBUG_FLAG(26, "rml",
  "Turns on extra RML checks.");
constant DebugFlag TAIL = DEBUG_FLAG(27, "tail",
  "Prints out a notification if tail recursion optimization has been applied.");
constant DebugFlag LOOKUP = DEBUG_FLAG(28, "lookup",
  "Print extra failtrace from lookup.");
constant DebugFlag PATTERNM_SKIP_FILTER_UNUSED_AS_BINDINGS = DEBUG_FLAG(29,
  "patternmSkipFilterUnusedBindings", "");
constant DebugFlag PATTERNM_ALL_INFO = DEBUG_FLAG(30, "patternmAllInfo",
  "");
constant DebugFlag PATTERNM_SKIP_MCDCE = DEBUG_FLAG(31, "patternmSkipMCDCE",
  "");
constant DebugFlag PATTERNM_SKIP_MOVE_LAST_EXP = DEBUG_FLAG(32, 
  "patternmSkipMoveLastExp", "");
constant DebugFlag SCODE_FLATTEN = DEBUG_FLAG(33, "scodeFlatten",
  "");
constant DebugFlag EXPERIMENTAL_REDUCTIONS = DEBUG_FLAG(34, "experimentalReductions",
  "Turns on custom reduction functions (OpenModelica extension).");
constant DebugFlag EVAL_PARAM = DEBUG_FLAG(35, "evalparam",
  "");
constant DebugFlag TYPES = DEBUG_FLAG(36, "types",
  "Prints extra failtrace from Types.");
constant DebugFlag SHOW_STATEMENT = DEBUG_FLAG(37, "showStatement",
  "Shows the statement that is currently being evaluated when evaluating a script.");
constant DebugFlag INFO = DEBUG_FLAG(38, "info",
  "");
constant DebugFlag DUMP = DEBUG_FLAG(39, "dump",
  "");
constant DebugFlag DUMP_GRAPHVIZ = DEBUG_FLAG(40, "graphviz",
  "");
constant DebugFlag EXEC_STAT = DEBUG_FLAG(41, "execstat",
  "Prints out execution statistics for the compiler.");
constant DebugFlag TRANSFORMS_BEFORE_DUMP = DEBUG_FLAG(42, "transformsbeforedump",
  "");
constant DebugFlag BEFORE_FIX_MOD_OUT = DEBUG_FLAG(43, "beforefixmodout",
  "");
constant DebugFlag FLAT_MODELICA = DEBUG_FLAG(44, "flatmodelica",
  "");
constant DebugFlag DAE_DUMP = DEBUG_FLAG(45, "daedump",
  "");
constant DebugFlag DAE_DUMP2 = DEBUG_FLAG(46, "daedump2",
  "");
constant DebugFlag DAE_DUMP_DEBUG = DEBUG_FLAG(47, "daedumpdebug",
  "");
constant DebugFlag DAE_DUMP_GRAPHV = DEBUG_FLAG(48, "daedumpgraphv",
  "");
constant DebugFlag BLT = DEBUG_FLAG(49, "blt",
  "");
constant DebugFlag INTERACTIVE = DEBUG_FLAG(50, "interactive",
  "Starts omc as a server listening on the socket interface.");
constant DebugFlag INTERACTIVE_CORBA = DEBUG_FLAG(51, "interactiveCorba",
  "Starts omc as a server listening on the Corba interface.");
constant DebugFlag INTERACTIVE_DUMP = DEBUG_FLAG(52, "interactivedump",
  "Prints out debug information for the interactive server.");
constant DebugFlag RELIDX = DEBUG_FLAG(53, "relidx",
  "");
constant DebugFlag DUMP_REPL = DEBUG_FLAG(54, "dumprepl",
  "dump the found replacments for remove simple equation");
constant DebugFlag DUMP_FP_REPL = DEBUG_FLAG(55, "dumpFPrepl",
  "dump the found replacements for final parameters");
constant DebugFlag DUMP_PARAM_REPL = DEBUG_FLAG(56, "dumpParamrepl",
  "dump the found replacements for remove parameters");
constant DebugFlag DUMP_PP_REPL = DEBUG_FLAG(57, "dumpPPrepl",
  "dump the found replacements for protected parameters");
constant DebugFlag DEBUG_ALIAS = DEBUG_FLAG(58, "debugAlias",
  "dump the found alias variables");
constant DebugFlag TEARING_DUMP = DEBUG_FLAG(59, "tearingdump",
  "Dumps tearing information.");
constant DebugFlag JAC_DUMP = DEBUG_FLAG(60, "jacdump",
  "");
constant DebugFlag JAC_DUMP2 = DEBUG_FLAG(61, "jacdump2",
  "");
constant DebugFlag JAC_DUMP_EQN = DEBUG_FLAG(62, "jacdumpeqn",
  "");
constant DebugFlag FAILTRACE_JAC = DEBUG_FLAG(63, "failtraceJac",
  "");
constant DebugFlag VAR_INDEX = DEBUG_FLAG(64, "varIndex",
  "");
constant DebugFlag VAR_INDEX2 = DEBUG_FLAG(65, "varIndex2",
  "");
constant DebugFlag BLT_DUMP = DEBUG_FLAG(66, "bltdump",
  "Dumps information from index reduction.");
constant DebugFlag DUMMY_SELECT = DEBUG_FLAG(67, "dummyselect",
  "");
constant DebugFlag DUMP_DAE_LOW = DEBUG_FLAG(68, "dumpdaelow",
  "Dumps the equation system at the beginning of the back end.");
constant DebugFlag DUMP_INDX_DAE = DEBUG_FLAG(69, "dumpindxdae",
  "Dumps the equation system after index reduction and optimisation.");
constant DebugFlag OPT_DAE_DUMP = DEBUG_FLAG(70, "optdaedump",
  "Dumps information from the optimisation modules.");
constant DebugFlag EXEC_HASH = DEBUG_FLAG(71, "execHash",
  "");
constant DebugFlag EXEC_FILES = DEBUG_FLAG(72, "execFiles",
  "");
constant DebugFlag PARAM_DLOW_DUMP = DEBUG_FLAG(73, "paramdlowdump",
  "");
constant DebugFlag CPP = DEBUG_FLAG(74, "cpp",
  "");
constant DebugFlag CPP_VAR = DEBUG_FLAG(75, "cppvar",
  "");
constant DebugFlag CPP_VAR_INDEX = DEBUG_FLAG(76, "cppvarindex",
  "");
constant DebugFlag CPP_SIM1 = DEBUG_FLAG(77, "cppsim1",
  "");
constant DebugFlag TCVT = DEBUG_FLAG(78, "tcvt",
  "");
constant DebugFlag CGRAPH = DEBUG_FLAG(79, "cgraph",
  "Prints out connection graph information.");
constant DebugFlag DUMPTR = DEBUG_FLAG(80, "dumptr",
  "");
constant DebugFlag DUMPIH = DEBUG_FLAG(81, "dumpIH",
  "");
constant DebugFlag REC_CONST = DEBUG_FLAG(82, "recconst",
  "");
constant DebugFlag UPDMOD = DEBUG_FLAG(83, "updmod",
  "Prints information about modification updates.");
constant DebugFlag SEI = DEBUG_FLAG(84, "sei",
  "");
constant DebugFlag STATIC = DEBUG_FLAG(85, "static",
  "");
constant DebugFlag PERF_TIMES = DEBUG_FLAG(86, "perfTimes",
  "");
constant DebugFlag CHECK_SIMPLIFY = DEBUG_FLAG(87, "checkSimplify",
  "Enables checks for expression simplification and prints a notification whenever an undesirable transformation has been performed.");
constant DebugFlag SCODE_INST = DEBUG_FLAG(88, "scodeInst",
  "Enables experimental SCode instantiation phase.");
constant DebugFlag DELAY_BREAK_LOOP = DEBUG_FLAG(89, "delayBreakLoop",
  "Enables (very) experimental code to break algebraic loops using the delay() operator. Probably messes with initialization.");
constant DebugFlag WRITE_TO_BUFFER = DEBUG_FLAG(90, "writeToBuffer",
  "Enables writing simulation results to buffer.");
constant DebugFlag DUMP_BACKENDDAE_INFO = DEBUG_FLAG(91, "backenddaeinfo",
  "Enables dumping of backend information about system (Number of equations before backend,...).");
constant DebugFlag GEN_DEBUG_SYMBOLS = DEBUG_FLAG(92, "gendebugsymbols",
  "Generate code with debugging symbols.");
constant DebugFlag DUMP_STATESELECTION_INFO = DEBUG_FLAG(93, "stateselection",
  "Enables dumping of selected states. Works only in combination with backenddaeinfo.");
constant DebugFlag DUMP_DERREPL = DEBUG_FLAG(94, "dumpderrepl",
  "Enables dumping of selected states. Works only in combination with backenddaeinfo.");
constant DebugFlag DUMP_EQNINORDER = DEBUG_FLAG(95, "dumpeqninorder",
  "Enables dumping of the equations in the order they are calculated");


// This is a list of all debug flags, to keep track of which flags are used. A
// flag can not be used unless it's in this list, and the list is checked at
// initialisation so that all flags are sorted by index (and thus have unique
// indices).
constant list<DebugFlag> allDebugFlags = {
  FAILTRACE,
  CEVAL,
  LINEARIZATION,
  JACOBIAN,
  CHECK_BACKEND_DAE,
  DUMP_INIT,
  OPENMP,
  PTHREADS,
  TEARING,
  RELAXATION,
  NO_EVENTS,
  EVAL_FUNC,
  NO_EVAL_FUNC,
  NO_GEN,
  DYN_LOAD,
  GENERATE_CODE_CHEAT,
  CGRAPH_GRAPHVIZ_FILE,
  CGRAPH_GRAPHVIZ_SHOW,
  FRONTEND_INLINE_EULER,
  USEDEP,
  ENV,
  CHECK_DAE_CREF_TYPE,
  CHECK_ASUB,
  INSTANCE,
  NO_CACHE,
  RML,
  TAIL,
  LOOKUP,
  PATTERNM_SKIP_FILTER_UNUSED_AS_BINDINGS,
  PATTERNM_ALL_INFO,
  PATTERNM_SKIP_MCDCE,
  PATTERNM_SKIP_MOVE_LAST_EXP,
  SCODE_FLATTEN,
  EXPERIMENTAL_REDUCTIONS,
  EVAL_PARAM,
  TYPES,
  SHOW_STATEMENT,
  INFO,
  DUMP,
  DUMP_GRAPHVIZ,
  EXEC_STAT,
  TRANSFORMS_BEFORE_DUMP,
  BEFORE_FIX_MOD_OUT,
  FLAT_MODELICA,
  DAE_DUMP,
  DAE_DUMP2,
  DAE_DUMP_DEBUG,
  DAE_DUMP_GRAPHV,
  BLT,
  INTERACTIVE,
  INTERACTIVE_CORBA,
  INTERACTIVE_DUMP,
  RELIDX,
  DUMP_REPL,
  DUMP_FP_REPL,
  DUMP_PARAM_REPL,
  DUMP_PP_REPL,
  DEBUG_ALIAS,
  TEARING_DUMP,
  JAC_DUMP,
  JAC_DUMP2,
  JAC_DUMP_EQN,
  FAILTRACE_JAC,
  VAR_INDEX,
  VAR_INDEX2,
  BLT_DUMP,
  DUMMY_SELECT,
  DUMP_DAE_LOW,
  DUMP_INDX_DAE,
  OPT_DAE_DUMP,
  EXEC_HASH,
  EXEC_FILES,
  PARAM_DLOW_DUMP,
  CPP,
  CPP_VAR,
  CPP_VAR_INDEX,
  CPP_SIM1,
  TCVT,
  CGRAPH,
  DUMPTR,
  DUMPIH,
  REC_CONST,
  UPDMOD,
  SEI,
  STATIC,
  PERF_TIMES,
  CHECK_SIMPLIFY,
  SCODE_INST,
  DELAY_BREAK_LOOP,
  WRITE_TO_BUFFER,
  DUMP_BACKENDDAE_INFO,
  GEN_DEBUG_SYMBOLS,
  DUMP_STATESELECTION_INFO,
  DUMP_DERREPL,
  DUMP_EQNINORDER
};

// CONFIGURATION FLAGS
constant ConfigFlag DEBUG = CONFIG_FLAG(1, "debug",
  SOME("d"), EXTERNAL(), STRING_FLAG(""), NONE(),
  "Sets debug flags. Use +help=debug to see available flags.");
constant ConfigFlag HELP = CONFIG_FLAG(2, "help",
  NONE(), EXTERNAL(), BOOL_FLAG(false), 
  SOME(STRING_OPTION({"debug", "optmodules"})),
  "Displays the help text.");
constant ConfigFlag RUNNING_TESTSUITE = CONFIG_FLAG(3, "running-testsuite",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Used when running the testsuite.");
constant ConfigFlag SHOW_VERSION = CONFIG_FLAG(4, "version",
  SOME("+v"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Print the version and exit.");
constant ConfigFlag TARGET = CONFIG_FLAG(5, "target", NONE(), EXTERNAL(),
  STRING_FLAG("gcc"), SOME(STRING_OPTION({"gcc, msvc"})),
  "Sets the target compiler to use.");
constant ConfigFlag GRAMMAR = CONFIG_FLAG(6, "grammar", SOME("g"), EXTERNAL(),
  ENUM_FLAG(MODELICA, {("Modelica", MODELICA), ("MetaModelica", METAMODELICA), ("ParModelica", PARMODELICA)}), 
  SOME(STRING_OPTION({"Modelica", "MetaModelica", "ParModelica"})),
  "Sets the grammar and semantics to accept.");
constant ConfigFlag ANNOTATION_VERSION = CONFIG_FLAG(7, "annotationVersion",
  NONE(), EXTERNAL(), STRING_FLAG("3.x"), SOME(STRING_OPTION({"1.x", "2.x", "3.x"})),
  "Sets the annotation version that should be used.");
constant ConfigFlag LANGUAGE_STANDARD = CONFIG_FLAG(8, "std", NONE(), EXTERNAL(),
  ENUM_FLAG(1000, 
    {("1.x", 10), ("2.x", 20), ("3.0", 30), ("3.1", 31), ("3.2", 32), ("3.3", 33)}),
  SOME(STRING_OPTION({"1.x", "2.x", "3.1", "3.2", "3.3"})),
  "Sets the language standard that should be used.");
constant ConfigFlag SHOW_ERROR_MESSAGES = CONFIG_FLAG(9, "showErrorMessages",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Show error messages immediately when they happen.");
constant ConfigFlag SHOW_ANNOTATIONS = CONFIG_FLAG(10, "showAnnotations",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Show annotations in the flattened code.");
constant ConfigFlag NO_SIMPLIFY = CONFIG_FLAG(11, "noSimplify",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Do not simplify expressions if set.");
protected constant String removeSimpleEquationDesc = "Performs alias elimination and removes constant variables from the DAE, replacing all occurrences of the old variable reference with the new value (constants) or variable reference (alias elimination).";
public constant ConfigFlag PRE_OPT_MODULES = CONFIG_FLAG(12, "preOptModules",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({
    "removeFinalParameters", 
    "removeEqualFunctionCalls",
    "partitionIndependentBlocks", 
    "expandDerOperator", 
    "removeSimpleEquationsFast"}),
  SOME(STRING_DESC_OPTION({
    ("removeSimpleEquationsFast", removeSimpleEquationDesc),
    ("removeSimpleEquations", removeSimpleEquationDesc),
    ("inlineArrayEqn", "DESCRIBE ME"),
    ("removeFinalParameters", "Structural parameters and parameters declared as final are removed and replaced with their value. They may no longer be changed in the init file."),
    ("removeEqualFunctionCalls", "DESCRIBE ME"),
    ("removeProtectedParameters", "replace all parameters with protected=true in the system"),
    ("removeUnusedParameter", "strips all parameter not present int the equations from the system"),
    ("removeUnusedVariables", "strips all variables not present int the equations from the system"),
    ("partitionIndependentBlocks", "Partitions the equation system into independent equation systems (which can then be simulated in parallel or used to speed up subsequent optimizations)"),
    ("collapseIndependentBlocks", "Collapses all equation systems back into one big system again (undo partitionIndependentBlocks)"),
    ("expandDerOperator", "DESCRIBE ME"),
    ("residualForm", "Transforms simple equations x=y to zero-sum equations 0=y-x")})),
  "Sets the pre optimisation modules to use in the back end. See +help=optmodules for more info.");
constant ConfigFlag MATCHING_ALGORITHM = CONFIG_FLAG(13, "matchingAlgorithm",
  NONE(), EXTERNAL(), STRING_FLAG("omc"),
  SOME(STRING_DESC_OPTION({
    ("omc", "Depth First Search based Algorithm with simple Look Ahead Feature")})),
    "Sets the matching algorithm to use.");  
constant ConfigFlag INDEX_REDUCTION_METHOD = CONFIG_FLAG(14, "indexReductionMethod",
  NONE(), EXTERNAL(), STRING_FLAG("dummyDerivative"),
  SOME(STRING_DESC_OPTION({
    ("dummyDerivative", "simple index reduction method, select dummy states based on heuristics"),
    ("DynamicStateSelection", "index reduction method based on analysation of the jacobian.")})),
    "Sets the index reduction method to use.");
constant ConfigFlag POST_OPT_MODULES = CONFIG_FLAG(15, "postOptModules",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({
    "lateInline",
    "inlineArrayEqn",
    "constantLinearSystem",
    "removeSimpleEquations",
    "removeUnusedFunctions"
  }),
  SOME(STRING_DESC_OPTION({
    ("lateInline", "perform function inlining for function with annotation LateInline=true"),
    ("removeSimpleEquationsFast", removeSimpleEquationDesc),
    ("removeSimpleEquations", removeSimpleEquationDesc),
    ("removeEqualFunctionCalls", "DESCRIBE ME"),
    ("inlineArrayEqn", "DESCRIBE ME"),
    ("removeUnusedParameter", "strips all parameter not present int the equations from the system"),
    ("constantLinearSystem", "Evaluates constant linear systems (a*x+b*y=c; d*x+e*y=f; a,b,c,d,e,f are constants) at compile-time"),
    ("dumpComponentsGraphStr", "DESCRIBE ME"),
    ("removeUnusedFunctions", "removed all unused functions from functionTree")})),
  "Sets the post optimisation modules to use in the back end. See +help=optmodules for more info.");
constant ConfigFlag SIMCODE_TARGET = CONFIG_FLAG(16, "simCodeTarget",
  NONE(), EXTERNAL(), STRING_FLAG("C"), 
  SOME(STRING_OPTION({"CSharp", "Cpp", "Adevs", "QSS", "C", "c", "Dump"})),
  "Sets the target language for the code generation");
constant ConfigFlag ORDER_CONNECTIONS = CONFIG_FLAG(17, "orderConnections", 
  NONE(), EXTERNAL(), BOOL_FLAG(true), NONE(),
  "Orders connect equations alphabetically if set.");
constant ConfigFlag TYPE_INFO = CONFIG_FLAG(18, "typeinfo",
  SOME("t"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Prints out extra type information if set.");
constant ConfigFlag KEEP_ARRAYS = CONFIG_FLAG(19, "keepArrays",
  SOME("a"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Sets whether to split arrays or not.");
constant ConfigFlag MODELICA_OUTPUT = CONFIG_FLAG(20, "modelicaOutput",
  SOME("m"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "");
constant ConfigFlag PARAMS_STRUCT = CONFIG_FLAG(21, "paramsStruct",
  SOME("p"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "");
constant ConfigFlag SILENT = CONFIG_FLAG(22, "silent",
  SOME("q"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Turns on silent mode.");
constant ConfigFlag CORBA_SESSION = CONFIG_FLAG(23, "corbaSessionName",
  SOME("c"), EXTERNAL(), STRING_FLAG(""), NONE(),
  "Sets the name of the corba session if +d=interactiveCorba is used.");
constant ConfigFlag NUM_PROC = CONFIG_FLAG(24, "numProcs",
  SOME("n"), EXTERNAL(), INT_FLAG(0), NONE(),
  "Sets the number of processors to use.");
constant ConfigFlag LATENCY = CONFIG_FLAG(25, "latency",
  SOME("l"), EXTERNAL(), INT_FLAG(0), NONE(),
  "Sets the latency for parallel execution.");
constant ConfigFlag BANDWIDTH = CONFIG_FLAG(26, "bandwidth",
  SOME("b"), EXTERNAL(), INT_FLAG(0), NONE(),
  "Sets the bandwidth for parallel execution.");
constant ConfigFlag INST_CLASS = CONFIG_FLAG(27, "instClass",
  SOME("i"), EXTERNAL(), STRING_FLAG(""), NONE(),
  "Instantiate the class given by the fully qualified path.");
constant ConfigFlag VECTORIZATION_LIMIT = CONFIG_FLAG(28, "vectorizationLimit",
  SOME("v"), EXTERNAL(), INT_FLAG(0), NONE(),
  "Sets the vectorization limit, arrays and matrices larger than this will not be vectorized.");
constant ConfigFlag SIMULATION_CG = CONFIG_FLAG(29, "simulationCg",
  SOME("s"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Turns on simulation code generation.");
constant ConfigFlag EVAL_PARAMS_IN_ANNOTATIONS = CONFIG_FLAG(30,
  "evalAnnotationParams", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Sets whether to evaluate parameters in annotations or not.");
constant ConfigFlag CHECK_MODEL = CONFIG_FLAG(31,
  "checkModel", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  "Set when checkModel is used to turn on specific features for checking.");
constant ConfigFlag CEVAL_EQUATION = CONFIG_FLAG(32,
  "cevalEquation", NONE(), INTERNAL(), BOOL_FLAG(true), NONE(),
  "");
constant ConfigFlag UNIT_CHECKING = CONFIG_FLAG(33,
  "unitChecking", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  "");
constant ConfigFlag TRANSLATE_DAE_STRING = CONFIG_FLAG(34,
  "translateDAEString", NONE(), INTERNAL(), BOOL_FLAG(true), NONE(),
  "");
constant ConfigFlag ENV_CACHE = CONFIG_FLAG(35,
  "envCache", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  "");
constant ConfigFlag GENERATE_LABELED_SIMCODE = CONFIG_FLAG(36,
  "generateLabeledSimCode", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Turns on labeled SimCode generation for reduction algorithms.");
constant ConfigFlag REDUCE_TERMS = CONFIG_FLAG(37,
  "reduceTerms", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Turns on reducing terms for reduction algorithms.");
constant ConfigFlag REDUCTION_METHOD = CONFIG_FLAG(38, "reductionMethod",
  NONE(), EXTERNAL(), STRING_FLAG("deletion"),
  SOME(STRING_OPTION({"deletion","substitution","linearization"})),
    "Sets the reduction method to be used.");
constant ConfigFlag PLOT_SILENT = CONFIG_FLAG(39, "plotSilent", 
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Defines whether plot commands should open OMPlot or just output results.");

// This is a list of all configuration flags. A flag can not be used unless it's
// in this list, and the list is checked at initialisation so that all flags are
// sorted by index (and thus have unique indices).
constant list<ConfigFlag> allConfigFlags = {
  DEBUG,
  HELP,
  RUNNING_TESTSUITE,
  SHOW_VERSION,
  TARGET,
  GRAMMAR,
  ANNOTATION_VERSION,
  LANGUAGE_STANDARD,
  SHOW_ERROR_MESSAGES,
  SHOW_ANNOTATIONS,
  NO_SIMPLIFY,
  PRE_OPT_MODULES,
  MATCHING_ALGORITHM,
  INDEX_REDUCTION_METHOD,
  POST_OPT_MODULES,
  SIMCODE_TARGET,
  ORDER_CONNECTIONS,
  TYPE_INFO,
  KEEP_ARRAYS,
  MODELICA_OUTPUT,
  PARAMS_STRUCT,
  SILENT,
  CORBA_SESSION,
  NUM_PROC,
  LATENCY,
  BANDWIDTH,
  INST_CLASS,
  VECTORIZATION_LIMIT,
  SIMULATION_CG,
  EVAL_PARAMS_IN_ANNOTATIONS,
  CHECK_MODEL,
  CEVAL_EQUATION,
  UNIT_CHECKING,
  TRANSLATE_DAE_STRING,
  ENV_CACHE,
  GENERATE_LABELED_SIMCODE,
  REDUCE_TERMS,
  REDUCTION_METHOD,
  PLOT_SILENT
};

public function new
  "Create a new flags structure and read the given arguments."
  input list<String> inArgs;
  output list<String> outArgs;
algorithm
  _ := loadFlags();
  outArgs := readArgs(inArgs);
end new;

protected function saveFlags
  "Saves the flags with setGlobalRoot."
  input Flags inFlags;
algorithm
  setGlobalRoot(Global.flagsIndex, inFlags);
end saveFlags;

protected function loadFlags
  "Loads the flags with getGlobalRoot. Creates a new flags structure if it
   hasn't been created yet."
  output Flags outFlags;
algorithm
  outFlags := matchcontinue()
    local
      array<Boolean> debug_flags;
      array<FlagData> config_flags;
      Flags flags;
      Integer debug_count, config_count;

    case () 
      equation
        outFlags = getGlobalRoot(Global.flagsIndex);
      then
        outFlags;

    else
      equation
        debug_count = List.fold(allDebugFlags, checkDebugFlag, 1) - 1;
        config_count = listLength(allConfigFlags);
        debug_flags = arrayCreate(debug_count, false);
        config_flags = arrayCreate(config_count, EMPTY_FLAG());
        _ = List.fold1(allConfigFlags, setDefaultConfig, config_flags, 1);
        flags = FLAGS(debug_flags, config_flags);
        saveFlags(flags);
      then
        flags;
        
  end matchcontinue;
end loadFlags;

public function clearDebugFlags
  "Sets all the debug flags to false."
protected
  array<Boolean> debug_flags;
  array<FlagData> config_flags;
  Flags flags;
algorithm
  debug_flags := arrayCreate(listLength(allDebugFlags), false);
  FLAGS(configFlags = config_flags) := loadFlags();
  saveFlags(FLAGS(debug_flags, config_flags));
end clearDebugFlags;

protected function checkDebugFlag
  "Used when creating a new flags structure (in loadFlags) to check that a debug
   flag has a valid index."
  input DebugFlag inDebugFlag;
  input Integer inFlagIndex;
  output Integer outNextFlagIndex;
algorithm
  outNextFlagIndex := matchcontinue(inDebugFlag, inFlagIndex)
    local
      Integer index;
      String name, index_str, err_str;

    case (DEBUG_FLAG(index = index), _)
      equation
        true = intEq(index, inFlagIndex);
      then
        inFlagIndex + 1;

    case (DEBUG_FLAG(index = index, name = name), _)
      equation
        index_str = intString(index);
        err_str = "Invalid flag " +& name +& " with index " +& index_str +& 
          " in Flags.allDebugFlags. Make sure that all flags are present and ordered correctly.";
        Error.addMessage(Error.INTERNAL_ERROR, {err_str});
      then
        fail();
  end matchcontinue;
end checkDebugFlag;

protected function setDefaultConfig
  "Used when creating a new flags structure (in loadFlags) to set the default
   value of a configuration flag, and also to check that it has a valid index."
  input ConfigFlag inConfigFlag;
  input array<FlagData> inConfigData;
  input Integer inFlagIndex;
  output Integer outFlagIndex;
algorithm
  outFlagIndex := matchcontinue(inConfigFlag, inConfigData, inFlagIndex)
    local
      Integer index;
      FlagData default_value;
      String name, index_str, err_str;

    case (CONFIG_FLAG(index = index, defaultValue = default_value), _, _)
      equation
        true = intEq(index, inFlagIndex);
        _ = arrayUpdate(inConfigData, index, default_value);
      then
        inFlagIndex + 1;

    case (CONFIG_FLAG(index = index, name = name), _, _)
      equation
        index_str = intString(index);
        err_str = "Invalid flag " +& name +& " with index " +& index_str +& 
          " in Flags.allConfigFlags. Make sure that all flags are present and ordered correctly.";
        Error.addMessage(Error.INTERNAL_ERROR, {err_str});
      then
        fail();
  end matchcontinue;
end setDefaultConfig;

public function set
  "Sets the value of a debug flag, and returns the old value."
  input DebugFlag inFlag;
  input Boolean inValue;
  output Boolean outOldValue;
protected
  array<Boolean> debug_flags;
  array<FlagData> config_flags;
  Flags flags;
algorithm
  FLAGS(debug_flags, config_flags) := loadFlags();
  (debug_flags, outOldValue) := updateDebugFlagArray(debug_flags, inValue, inFlag);
  saveFlags(FLAGS(debug_flags, config_flags));
end set;

public function isSet
  "Checks if a debug flag is set."
  input DebugFlag inFlag;
  output Boolean outValue;
protected
  array<Boolean> debug_flags;
  Flags flags;
  Integer index;
algorithm
  DEBUG_FLAG(index = index) := inFlag;
  flags := loadFlags();
  FLAGS(debugFlags = debug_flags) := flags;
  outValue := arrayGet(debug_flags, index);
end isSet;

public function enableDebug
  "Enables a debug flag."
  input DebugFlag inFlag;
  output Boolean outOldValue;
algorithm
  outOldValue := set(inFlag, true);
end enableDebug;

public function disableDebug
  "Disables a debug flag."
  input DebugFlag inFlag;
  output Boolean outOldValue;
algorithm
  outOldValue := set(inFlag, false);
end disableDebug;

protected function updateDebugFlagArray
  "Updates the value of a debug flag in the debug flag array."
  input array<Boolean> inFlags;
  input Boolean inValue;
  input DebugFlag inFlag;
  output array<Boolean> outFlags;
  output Boolean outOldValue;
protected
  Integer index;
algorithm
  DEBUG_FLAG(index = index) := inFlag;
  outOldValue := arrayGet(inFlags, index);
  outFlags := arrayUpdate(inFlags, index, inValue);
end updateDebugFlagArray;

protected function updateConfigFlagArray
  "Updates the value of a configuration flag in the configuration flag array."
  input array<FlagData> inFlags;
  input FlagData inValue;
  input ConfigFlag inFlag;
  output array<FlagData> outFlags;
protected
  Integer index;
algorithm
  CONFIG_FLAG(index = index) := inFlag;
  outFlags := arrayUpdate(inFlags, index, inValue);
  applySideEffects(inFlag, inValue);
end updateConfigFlagArray;

public function readArgs
  "Reads the command line arguments to the compiler and sets the flags
  accordingly. Returns a list of arguments that were not consumed, such as the
  model filename."
  input list<String> inArgs;
  output list<String> outArgs;
protected
  Flags flags;
algorithm
  flags := loadFlags();
  outArgs := List.filter1OnTrue(inArgs, readArg, flags);
  saveFlags(flags);
end readArgs;

protected function readArg
  "Reads a single command line argument. Returns true if the argument was not
  consumed, otherwise false."
  input String inArg;
  input Flags inFlags;
  output Boolean outNotConsumed;
algorithm
  outNotConsumed := matchcontinue(inArg, inFlags)
    local
      Integer matches, len;
      String flag;
      list<String> values;

    // Ignore flags that don't start with + or -.
    case (_, _)
      equation
        flag = stringGetStringChar(inArg, 1);
        false = stringEq(flag, "+") or stringEq(flag, "-");
      then
        true;

    // Flags that start with --.
    case (_, _)
      equation
        true = stringEq(System.substring(inArg, 1, 2), "--");
        len = stringLength(inArg);
        // Don't allow short names with --, like --a.
        true = len > 3;
        flag = System.substring(inArg, 3, len);
        parseFlag(flag, inFlags);
      then
        false;

    // Flags beginning with - are consumed by the RML runtime, until -- is
    // encountered. The bootstrapped compiler gets all flags though, so this
    // case is to make sure that -- is consumed and not treated as a flag.
    case ("--", _) then false;

    // Flags that start with +.
    else
      equation
        true = stringEq(stringGetStringChar(inArg, 1), "+");
        flag = System.substring(inArg, 2, stringLength(inArg));
        parseFlag(flag, inFlags);
      then
        false;
  end matchcontinue;
end readArg;

protected function parseFlag
  "Parses a single flag."
  input String inFlag;
  input Flags inFlags;
protected
  String flag;
  list<String> values;
algorithm
  flag :: values := System.strtok(inFlag, "=");
  values := List.flatten(List.map1(values, System.strtok, ","));
  parseFlag2(flag, values, inFlags);
end parseFlag;

protected function parseFlag2
  "Helper function to parseFlag, parses a flag."
  input String inFlag;
  input list<String> inValues;
  input Flags inFlags;
algorithm
  _ := match(inFlag, inValues, inFlags)
    local
      array<Boolean> debug_flags;
      array<FlagData> config_flags;
      list<String> values;

    // Special case for +d, set the given debug flags.
    case ("d", _, FLAGS(debugFlags = debug_flags))
      equation
        List.map1_0(inValues, setDebugFlag, debug_flags);
      then
        ();
        
    // Special case for +help, show help text.
    case ("help", _, _)
      equation
        values = List.map(inValues, System.tolower);
        printHelp(values);
        setConfigBool(HELP, true);
      then
        ();

    // All other configuration flags.
    case (_, _, FLAGS(configFlags = config_flags))
      equation
        parseConfigFlag(inFlag, inValues, config_flags);
      then
        ();

  end match;
end parseFlag2;

protected function parseConfigFlag
  "Tries to look up the flag with the given name, and set it to the given value."
  input String inFlag;
  input list<String> inValues;
  input array<FlagData> inFlags;
algorithm
  _ := matchcontinue(inFlag, inValues, inFlags)
    local
      ConfigFlag config_flag;

    case (_, _, _)
      equation
        config_flag = List.getMemberOnTrue(inFlag, allConfigFlags, matchConfigFlag);
        setConfigFlag(config_flag, inFlags, inValues);
      then
        ();

    else
      equation
        Error.addMessage(Error.UNKNOWN_OPTION, {inFlag});
      then
        fail();

  end matchcontinue;
end parseConfigFlag;
      
protected function setDebugFlag
  "Enables a debug flag given as a string, or disables it if it's prefixed with -."
  input String inFlag;
  input array<Boolean> inFlags;
protected
  Boolean negated;
  String flag_str;
algorithm
  negated := stringEq(stringGetStringChar(inFlag, 1), "-");
  flag_str := Debug.bcallret1(negated, Util.stringRest, inFlag, inFlag);
  setDebugFlag2(flag_str, not negated, inFlags);
end setDebugFlag;

protected function setDebugFlag2
  input String inFlag;
  input Boolean inValue;
  input array<Boolean> inFlags;
algorithm
  _ := matchcontinue(inFlag, inValue, inFlags)
    local
      DebugFlag flag;

    case (_, _, _)
      equation
        flag = List.getMemberOnTrue(inFlag, allDebugFlags, matchDebugFlag);
        (_, _) = updateDebugFlagArray(inFlags, inValue, flag);
      then
        ();
         
    else
      equation
        Error.addMessage(Error.UNKNOWN_DEBUG_FLAG, {inFlag});
      then
        fail();

  end matchcontinue;      
end setDebugFlag2;

protected function matchDebugFlag
  "Returns true if the given flag has the given name, otherwise false."
  input String inFlagName;
  input DebugFlag inFlag;
  output Boolean outMatches;
protected
  String name;
algorithm
  DEBUG_FLAG(name = name) := inFlag;
  outMatches := stringEq(inFlagName, name);
end matchDebugFlag;

protected function matchConfigFlag
  "Returns true if the given flag has the given name, otherwise false."
  input String inFlagName;
  input ConfigFlag inFlag;
  output Boolean outMatches;
protected
  Option<String> opt_shortname;
  String name, shortname;
algorithm
  // A configuration flag may have two names, one long and one short.
  CONFIG_FLAG(name = name, shortname = opt_shortname) := inFlag;
  shortname := Util.getOptionOrDefault(opt_shortname, "");
  outMatches := stringEq(inFlagName, shortname) or
                stringEq(System.tolower(inFlagName), System.tolower(name));
end matchConfigFlag;

protected function setConfigFlag
  "Sets the value of a configuration flag, where the value is given as a list of
  strings."
  input ConfigFlag inFlag;
  input array<FlagData> inConfigData;
  input list<String> inValues;
protected
  FlagData data, default_value;
  String name;
algorithm
  CONFIG_FLAG(name = name, defaultValue = default_value) := inFlag;
  data := stringFlagData(inValues, default_value, name);
  _ := updateConfigFlagArray(inConfigData, data, inFlag);
end setConfigFlag;

protected function stringFlagData
  "Converts a list of strings into a FlagData value. The expected type is also
   given so that the value can be typechecked."
  input list<String> inValues;
  input FlagData inExpectedType;
  input String inName;
  output FlagData outValue;
algorithm
  outValue := matchcontinue(inValues, inExpectedType, inName)
    local
      Boolean b;
      Integer i;
      Real r;
      String s, et, at;
      list<tuple<String, Integer>> enums;

    // A boolean value.
    case ({s}, BOOL_FLAG(data = _), _) 
      equation
        b = Util.stringBool(s);
      then
        BOOL_FLAG(b);

    // No value, but a boolean flag => enable the flag.
    case ({}, BOOL_FLAG(data = _), _) then BOOL_FLAG(true);

    // An integer value.
    case ({s}, INT_FLAG(data = _), _) 
      equation
        i = stringInt(s);
        true = stringEq(intString(i), s);
      then
        INT_FLAG(i);

    // A real value.
    case ({s}, REAL_FLAG(data = _), _)
      equation
        //r = stringReal(s);
        Error.addMessage(Error.INTERNAL_ERROR,
          {"Flags.stringFlagData: RML doesn't have stringReal, enable this for the bootstrapped compiler"});
      then
        fail();
        //REAL_FLAG(r);

    // A string value.
    case ({s}, STRING_FLAG(data = _), _) then STRING_FLAG(s);

    // A multiple-string value.
    case (_, STRING_LIST_FLAG(data = _), _) then STRING_LIST_FLAG(inValues);

    // An enumeration value.
    case ({s}, ENUM_FLAG(validValues = enums), _)
      equation
        i = Util.assoc(s, enums);
      then
        ENUM_FLAG(i, enums);

    // Type mismatch, print error.
    else
      equation
        et = printExpectedTypeStr(inExpectedType);
        at = printActualTypeStr(inValues);
        Error.addMessage(Error.INVALID_FLAG_TYPE, {inName, et, at});
      then
        fail();
        
  end matchcontinue;
end stringFlagData;

protected function printExpectedTypeStr
  "Prints the expected type as a string."
  input FlagData inType;
  output String outTypeStr;
algorithm
  outTypeStr := matchcontinue(inType)
    local
      list<tuple<String, Integer>> enums;
      list<String> enum_strs;

    case BOOL_FLAG(data = _) then "a boolean value";
    case INT_FLAG(data = _) then "an integer value";
    case REAL_FLAG(data = _) then "a floating-point value";
    case STRING_FLAG(data = _) then "a string";
    case STRING_LIST_FLAG(data = _) then "a comma-separated list of strings";
    case ENUM_FLAG(validValues = enums)
      equation
        enum_strs = List.map(enums, Util.tuple21);
      then
        "one of the values {" +& stringDelimitList(enum_strs, ", ") +& "}";
  end matchcontinue;
end printExpectedTypeStr;

protected function printActualTypeStr
  "Prints the actual type as a string."
  input list<String> inType;
  output String outTypeStr;
algorithm
  outTypeStr := matchcontinue(inType)
    local
      String s;
      Integer i;

    case {} then "nothing";
    case {s} equation _ = Util.stringBool(s); then "the boolean value " +& s;
    case {s} 
      equation 
        i = stringInt(s);
        // intString returns 0 on failure, so this is to make sure that it
        // actually succeeded.
        true = stringEq(intString(i), s);
      then 
        "the number " +& intString(i);
    //case {s}
    //  equation
    //    _ = stringReal(s);
    //  then
    //    "the number " +& intString(i);
    case {s} then "the string \"" +& s +& "\""; 
    case _ then "a list of values.";
  end matchcontinue;
end printActualTypeStr;

protected function configFlagsIsEqualIndex
  "Checks if two config flags have the same index."
  input ConfigFlag inFlag1;
  input ConfigFlag inFlag2;
  output Boolean outEqualIndex;
protected
  Integer index1, index2;
algorithm
  CONFIG_FLAG(index = index1) := inFlag1;
  CONFIG_FLAG(index = index2) := inFlag2;
  outEqualIndex := intEq(index1, index2);
end configFlagsIsEqualIndex;

protected function applySideEffects
  "Some flags have side effects, which are handled by this function."
  input ConfigFlag inFlag;
  input FlagData inValue;
algorithm
  _ := matchcontinue(inFlag, inValue)
    local
      Boolean value;
      String corba_name;

    // +showErrorMessages needs to be sent to the C runtime.
    case (_, _)
      equation
        true = configFlagsIsEqualIndex(inFlag, SHOW_ERROR_MESSAGES);
        BOOL_FLAG(data = value) = inValue;
        ErrorExt.setShowErrorMessages(value);
      then
        ();

    // The corba session name needs to be sent to the C runtime, and if the name
    // is mdt it also enables the MetaModelica grammar.
    case (_, _)
      equation
        true = configFlagsIsEqualIndex(inFlag, CORBA_SESSION);
        STRING_FLAG(data = corba_name) = inValue;
        Corba.setSessionName(corba_name);
        value = stringEqual(corba_name, "mdt");
        Debug.bcall2(value, setConfigEnum, GRAMMAR, METAMODELICA);
      then
        ();

    else ();
  end matchcontinue;
end applySideEffects;
        
public function setConfigValue
  "Sets the value of a configuration flag."
  input ConfigFlag inFlag;
  input FlagData inValue;
protected
  array<Boolean> debug_flags;
  array<FlagData> config_flags;
  Flags flags;
algorithm
  flags := loadFlags();
  FLAGS(debug_flags, config_flags) := flags;
  config_flags := updateConfigFlagArray(config_flags, inValue, inFlag);
  saveFlags(FLAGS(debug_flags, config_flags));
end setConfigValue;

public function setConfigBool
  "Sets the value of a boolean configuration flag."
  input ConfigFlag inFlag;
  input Boolean inValue;
algorithm
  setConfigValue(inFlag, BOOL_FLAG(inValue));
end setConfigBool;

public function setConfigInt
  "Sets the value of an integer configuration flag."
  input ConfigFlag inFlag;
  input Integer inValue;
algorithm
  setConfigValue(inFlag, INT_FLAG(inValue));
end setConfigInt;

public function setConfigReal
  "Sets the value of a real configuration flag."
  input ConfigFlag inFlag;
  input Real inValue;
algorithm
  setConfigValue(inFlag, REAL_FLAG(inValue));
end setConfigReal;

public function setConfigString
  "Sets the value of a string configuration flag."
  input ConfigFlag inFlag;
  input String inValue;
algorithm
  setConfigValue(inFlag, STRING_FLAG(inValue));
end setConfigString;

public function setConfigStringList
  "Sets the value of a multiple-string configuration flag."
  input ConfigFlag inFlag;
  input list<String> inValue;
algorithm
  setConfigValue(inFlag, STRING_LIST_FLAG(inValue));
end setConfigStringList;

public function setConfigEnum
  "Sets the value of an enumeration configuration flag."
  input ConfigFlag inFlag;
  input Integer inValue;
protected
  list<tuple<String, Integer>> valid_values;
algorithm
  CONFIG_FLAG(defaultValue = ENUM_FLAG(validValues = valid_values)) := inFlag;
  setConfigValue(inFlag, ENUM_FLAG(inValue, valid_values));
end setConfigEnum;

public function getConfigValue
  "Returns the value of a configuration flag."
  input ConfigFlag inFlag;
  output FlagData outValue;
protected
  array<FlagData> config_flags;
  Integer index;
  Flags flags;
  String name;
algorithm
  CONFIG_FLAG(name = name, index = index) := inFlag;
  flags := loadFlags();
  FLAGS(configFlags = config_flags) := flags;
  outValue := arrayGet(config_flags, index);
end getConfigValue;

public function getConfigBool
  "Returns the value of a boolean configuration flag."
  input ConfigFlag inFlag;
  output Boolean outValue;
algorithm
  BOOL_FLAG(data = outValue) := getConfigValue(inFlag);
end getConfigBool;

public function getConfigInt
  "Returns the value of an integer configuration flag."
  input ConfigFlag inFlag;
  output Integer outValue;
algorithm
  INT_FLAG(data = outValue) := getConfigValue(inFlag);
end getConfigInt;

public function getConfigReal
  "Returns the value of a real configuration flag."
  input ConfigFlag inFlag;
  output Real outValue;
algorithm
  REAL_FLAG(data = outValue) := getConfigValue(inFlag);
end getConfigReal;

public function getConfigString
  "Returns the value of a string configuration flag."
  input ConfigFlag inFlag;
  output String outValue;
algorithm
  STRING_FLAG(data = outValue) := getConfigValue(inFlag);
end getConfigString;

public function getConfigStringList
  "Returns the value of a multiple-string configuration flag."
  input ConfigFlag inFlag;
  output list<String> outValue;
algorithm
  STRING_LIST_FLAG(data = outValue) := getConfigValue(inFlag);
end getConfigStringList;

public function getConfigEnum
  "Returns the value of an enumeration configuration flag."
  input ConfigFlag inFlag;
  output Integer outValue;
algorithm
  ENUM_FLAG(data = outValue) := getConfigValue(inFlag);
end getConfigEnum;

// Used by the print functions below to indent descriptions.
protected constant String descriptionIndent = "                            ";

protected function printHelp
  "Prints out help for the given list of topics."
  input list<String> inTopics;
algorithm
  _ := matchcontinue (inTopics)
    local
      list<String> debug_flags, rest_topics;
      list<tuple<String, String>> options;
      String str,name;
      ConfigFlag config_flag;

    case {}
      equation
        printUsage();
      then
        ();

    case {"debug"}
      equation
        print("The debug flag takes a comma-separated list of flags which are used by the\n");
        print("compiler for debugging. Flags prefixed with - will be disabled.\n");
        print("The available flags are:\n\n");
        debug_flags = List.map(allDebugFlags, printDebugFlag);
        str = stringAppendList(debug_flags);
        print(str);
      then
        ();

    case {"optmodules"}
      equation
        print("The +preOptModules flag sets the optimisation modules which are used before the\n");
        print("matching and index reduction in the back end. These modules are specified as a\n");
        print("comma-separated list, where the valid modules are:\n\n");
        print(printFlagValidOptionsDesc(PRE_OPT_MODULES));
        print("\nThe +matchingAlgorithm sets the method that is used for the matching algorithm,\n");
        print("after the pre optimisation modules. Valid options are:\n\n");
        print(printFlagValidOptionsDesc(MATCHING_ALGORITHM));
        print("\nThe +indexReductionMethod sets the method that is used for the index reduction,\n");
        print("after the pre optimisation modules. Valid options are:\n\n");
        print(printFlagValidOptionsDesc(INDEX_REDUCTION_METHOD));
        print("\nThe +postOptModules then sets the optimisation modules which are used after the\n");
        print("index reduction, specified as a comma-separated list. The valid modules are:\n\n");
        print(printFlagValidOptionsDesc(POST_OPT_MODULES));
        print("\n");
      then
        ();

    case {str}
      equation
        (config_flag as CONFIG_FLAG(name=name,description=str)) = List.getMemberOnTrue(str, allConfigFlags, matchConfigFlag);
        str = "    +" +& name +& " " +& str +& "\n";
        str = stringAppendList(Util.stringWrap(str, 80, descriptionIndent));
        print(str);
        print("\n");
        print(printFlagValidOptionsDesc(config_flag));
      then ();

    case {str}
      equation
        print("I'm sorry, I don't know what " +& str +& " is.\n");
      then
        fail();

    case (str :: (rest_topics as _::_))
      equation
        printHelp({str});
        print("\n");
        printHelp(rest_topics);
      then
        ();

  end matchcontinue;
end printHelp;

public function printUsage
  "Prints out the usage text for the compiler."
algorithm
  print("OpenModelica Compiler "); print(Settings.getVersionNr());
  print(" Copyright Linkoping University 1997-2011\n");
  print("Distributed under OMSC-PL and GPL, see www.openmodelica.org\n\n");
  //print("Please check the System Guide for full information about flags.\n");
  print("Usage: omc [-runtimeOptions +omcOptions] (Model.mo | Script.mos) [Libraries | .mo-files] \n");
  print("* Libraries: Fully qualified names of libraries to load before processing Model or Script.\n");
  print("*            The libraries should be separated by spaces: Lib1 Lib2 ... LibN.\n");
  print("* runtimeOptions: call omc -help to see runtime options\n");
  print("* omcOptions:\n");
  print(printAllConfigFlags());
  print("\n");
  print("* Examples:\n");
  print("\tomc Model.mo             will produce flattened Model on standard output\n");
  print("\tomc +s Model.mo          will produce simulation code for the model:\n");
  print("\t                          * Model.c           the model C code\n");
  print("\t                          * Model_functions.c the model functions C code\n");
  print("\t                          * Model.makefile    the makefile to compile the model.\n");
  print("\t                          * Model_init.xml    the initial values\n");
  //print("\tomc Model.mof            will produce flattened Model on standard output\n");
  print("\tomc Script.mos           will run the commands from Script.mos\n");
  print("\tomc Model.mo Modelica    will first load the Modelica library and then produce \n");
  print("\t                         flattened Model on standard output\n");
  print("\tomc Model1.mo Model2.mo  will load both Model1.mo and Model2.mo, and produce \n");
  print("\t                         flattened Model1 on standard output\n");
  print("\t*.mo (Modelica files) \n");
  //print("\t*.mof (Flat Modelica files) \n");
  print("\t*.mos (Modelica Script files) \n");
end printUsage;

public function printAllConfigFlags
  "Prints all configuration flags to a string."
  output String outString;
algorithm
  outString := stringAppendList(List.map(allConfigFlags, printConfigFlag));
end printAllConfigFlags;

protected function printConfigFlag
  "Prints a configuration flag to a string."
  input ConfigFlag inFlag;
  output String outString;
algorithm
  outString := match(inFlag)
    local
      String name, desc, flag_str, delim_str, opt_str;
      list<String> wrapped_str;

    case CONFIG_FLAG(visibility = INTERNAL()) then "";

    case CONFIG_FLAG(description = desc)
      equation
        name = Util.stringPadRight(printConfigFlagName(inFlag), 28, " ");
        flag_str = stringAppendList({name, " ", desc});
        delim_str = descriptionIndent +& "  ";
        wrapped_str = Util.stringWrap(flag_str, 80, delim_str);
        opt_str = printValidOptions(inFlag);
        flag_str = stringDelimitList(wrapped_str, "\n") +& opt_str +& "\n";
      then
        flag_str;

  end match;
end printConfigFlag;

protected function printConfigFlagName
  "Prints out the name of a configuration flag, formatted for use by
   printConfigFlag."
  input ConfigFlag inFlag;
  output String outString;
algorithm
  outString := match(inFlag)
    local
      String name, shortname;

    case CONFIG_FLAG(name = name, shortname = SOME(shortname))
      equation
        shortname = Util.stringPadLeft("+" +& shortname, 4, " ");
      then stringAppendList({shortname, ", +", name});

    case CONFIG_FLAG(name = name, shortname = NONE())
      then "      +" +& name;

  end match;
end printConfigFlagName;

protected function printValidOptions
  "Prints out the valid options of a configuration flag to a string."
  input ConfigFlag inFlag;
  output String outString;
algorithm
  outString := match(inFlag)
    local
      list<String> strl;
      list<DebugFlag> flags;
      String opt_str;
      list<tuple<String, String>> descl;

    case CONFIG_FLAG(validOptions = NONE()) then "";
    case CONFIG_FLAG(validOptions = SOME(STRING_OPTION(options = strl)))
      equation
        opt_str = "\n" +& descriptionIndent +& "   Valid options: " +& 
          stringDelimitList(strl, ", ");
      then
        opt_str;
    case CONFIG_FLAG(validOptions = SOME(STRING_DESC_OPTION(options = descl)))
      equation
        opt_str = "\n" +& descriptionIndent +& "   Valid options:\n" +& 
          stringAppendList(List.map(descl, printFlagOptionDescShort));
      then 
        opt_str;
  end match;
end printValidOptions;

protected function printFlagOptionDescShort
  "Prints out the name of a flag option."
  input tuple<String, String> inOption;
  output String outString;
protected
  String name;
algorithm
  (name, _) := inOption;
  outString := descriptionIndent +& "    * " +& name +& "\n";
end printFlagOptionDescShort;

protected function printFlagValidOptionsDesc
  "Prints out the names and descriptions of the valid options for a
   configuration flag."
  input ConfigFlag inFlag;
  output String outString;
protected
  list<tuple<String, String>> options;
algorithm
  CONFIG_FLAG(validOptions = SOME(STRING_DESC_OPTION(options = options))) := inFlag;
  outString := stringAppendList(List.map(options, printFlagOptionDesc));
end printFlagValidOptionsDesc;

protected function printFlagOptionDesc
  "Helper function to printFlagValidOptionsDesc."
  input tuple<String, String> inOption;
  output String outString;
protected
  String name, desc, str;
algorithm
  (name, desc) := inOption;
  str := Util.stringPadRight(" * " +& name +& " ", 30, " ") +& desc;
  outString := stringDelimitList(
    Util.stringWrap(str, 80, descriptionIndent +& "    "), "\n") +& "\n";
end printFlagOptionDesc;

protected function printDebugFlag
  "Prints out name and description of a debug flag."
  input DebugFlag inFlag;
  output String outString;
protected
  String name, desc;
algorithm
  DEBUG_FLAG(name = name, description = desc) := inFlag;
  outString := Util.stringPadRight(" * " +& name +& " ", 26, " ") +& desc;
  outString := stringDelimitList(Util.stringWrap(outString, 80,
    descriptionIndent), "\n") +& "\n";
end printDebugFlag;

end Flags;
