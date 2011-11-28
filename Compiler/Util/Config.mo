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

encapsulated package Config
" file:        Config.mo
  package:     Config
  description: Functions for configurating the compiler.

  RCS: $Id$

  This module contains functions which are mostly just wrappers for the Flags
  module, which makes it easier to manipulate the configuration of the compiler."

public import Flags;
protected import Debug;
protected import Error;
protected import System;

public uniontype LanguageStandard
  "Defines the various modelica language versions that OMC can use. DO NOT add
  anything in these records, because the external functions that use these might
  break if the records are not empty due to some RML weirdness."
  record MODELICA_1_X end MODELICA_1_X;
  record MODELICA_2_X end MODELICA_2_X;
  record MODELICA_3_0 end MODELICA_3_0;
  record MODELICA_3_1 end MODELICA_3_1;
  record MODELICA_3_2 end MODELICA_3_2;
  record MODELICA_3_3 end MODELICA_3_3;
  record MODELICA_LATEST end MODELICA_LATEST;
end LanguageStandard;

public function typeinfo "+t"
  output Boolean outBoolean;
algorithm
  outBoolean := Flags.getConfigBool(Flags.TYPE_INFO);
end typeinfo;

public function splitArrays
  output Boolean outBoolean;
algorithm
  outBoolean := not Flags.getConfigBool(Flags.KEEP_ARRAYS);
end splitArrays;

public function paramsStruct
  output Boolean outBoolean;
algorithm
  outBoolean := Flags.getConfigBool(Flags.PARAMS_STRUCT);
end paramsStruct;

public function modelicaOutput
  output Boolean outBoolean;
algorithm
  outBoolean := Flags.getConfigBool(Flags.MODELICA_OUTPUT);
end modelicaOutput;

public function noProc
  output Integer outInteger;
algorithm
  outInteger := Flags.getConfigInt(Flags.NUM_PROC);
end noProc;

public function latency
  output Real outReal;
algorithm
  outReal := Flags.getConfigReal(Flags.LATENCY);
end latency;

public function bandwidth
  output Real outReal;
algorithm
  outReal := Flags.getConfigReal(Flags.BANDWIDTH);
end bandwidth;

public function simulationCg
  output Boolean outBoolean;
algorithm
  outBoolean := Flags.getConfigBool(Flags.SIMULATION_CG);
end simulationCg;

public function simulationCodeTarget
"@author: adrpo
 returns: 'gcc' or 'msvc'
 usage: omc [+target=gcc|msvc], default to 'gcc'."
  output String outCodeTarget;
algorithm
  outCodeTarget := Flags.getConfigString(Flags.TARGET);
end simulationCodeTarget;

public function classToInstantiate
  output String modelName;
algorithm
  modelName := Flags.getConfigString(Flags.INST_CLASS);
end classToInstantiate;

public function silent
  output Boolean outBoolean;
algorithm
  outBoolean := Flags.getConfigBool(Flags.SILENT);
end silent;

public function versionRequest
  output Boolean outBoolean;
algorithm
  outBoolean := Flags.getConfigBool(Flags.SHOW_VERSION);
end versionRequest;

public function helpRequest
  output Boolean outBoolean;
algorithm
  outBoolean := Flags.getConfigBool(Flags.HELP);
end helpRequest;

public function acceptedGrammar
"@author: mahge 2011-11-28
 returns: the flag number representing the accepted grammer. Instead of using 
 booleans. This way more extensions can be added easily.
 usage: omc [+g=Modelica|MetaModelica|ParModelica] = [1|2|3], default to 'Modelica'."
  output Integer outGrammer;
algorithm
  outGrammer := Flags.getConfigEnum(Flags.GRAMMAR);
end acceptedGrammar;

public function acceptMetaModelicaGrammar
"@author: adrpo 2007-06-11
 returns: true if MetaModelica grammar is accepted or false otherwise
 usage: omc [+g=Modelica|MetaModelica|ParModelica], default to 'Modelica'."
  output Boolean outBoolean;
algorithm
  outBoolean := intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.METAMODELICA);
end acceptMetaModelicaGrammar;

public function acceptParModelicaGrammar
"@author: mahge 2011-11-28
 returns: true if ParModelica grammar is accepted or false otherwise
 usage: omc [+g=Modelica|MetaModelica|ParModelica], default to 'Modelica'."
  output Boolean outBoolean;
algorithm
  outBoolean := intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.PARMODELICA);
end acceptParModelicaGrammar;

public function getAnnotationVersion
"@author: adrpo 2008-11-28
   returns what flag was given at start
     omc [+annotationVersion=3.x]
   or via the API
     setAnnotationVersion(\"3.x\");
   for annotations: 1.x or 2.x or 3.x"
  output String annotationVersion;
algorithm
  annotationVersion := Flags.getConfigString(Flags.ANNOTATION_VERSION);
end getAnnotationVersion;

public function setAnnotationVersion
"@author: adrpo 2008-11-28
   setAnnotationVersion(\"3.x\");
   for annotations: 1.x or 2.x or 3.x"
  input String annotationVersion;
algorithm
  Flags.setConfigString(Flags.ANNOTATION_VERSION, annotationVersion);
end setAnnotationVersion;

public function getNoSimplify
"@author: adrpo 2008-12-13
   returns what flag was given at start
     omc [+noSimplify]
   or via the API
     setNoSimplify(true|false);"
  output Boolean noSimplify;
algorithm
  noSimplify := Flags.getConfigBool(Flags.NO_SIMPLIFY);
end getNoSimplify;

public function setNoSimplify
  input Boolean noSimplify;
algorithm
  Flags.setConfigBool(Flags.NO_SIMPLIFY, noSimplify);
end setNoSimplify;

public function vectorizationLimit
  "Returns the vectorization limit that is used to determine how large an array
  can be before it no longer is expanded by Static.crefVectorize."
  output Integer limit;
algorithm
  limit := Flags.getConfigInt(Flags.VECTORIZATION_LIMIT);
end vectorizationLimit;

public function setVectorizationLimit
  "Sets the vectorization limit, see vectorizationLimit above."
  input Integer limit;
algorithm
  Flags.setConfigInt(Flags.VECTORIZATION_LIMIT, limit);
end setVectorizationLimit;

public function showAnnotations
  output Boolean show;
algorithm
  show := Flags.getConfigBool(Flags.SHOW_ANNOTATIONS);
end showAnnotations;

public function setShowAnnotations
  input Boolean show;
algorithm
  Flags.setConfigBool(Flags.SHOW_ANNOTATIONS, show);
end setShowAnnotations;

public function getRunningTestsuite
  output Boolean runningTestsuite;
algorithm
  runningTestsuite := Flags.getConfigBool(Flags.RUNNING_TESTSUITE);
end getRunningTestsuite;

public function getEvaluateParametersInAnnotations
"@author: adrpo
  flag to tell us if we should evaluate parameters in annotations"
  output Boolean shouldEvaluate;
algorithm
  shouldEvaluate := Flags.getConfigBool(Flags.EVAL_PARAMS_IN_ANNOTATIONS);
end getEvaluateParametersInAnnotations;

public function setEvaluateParametersInAnnotations
"@author: adrpo
  flag to tell us if we should evaluate parameters in annotations"
  input Boolean shouldEvaluate;
algorithm
  Flags.setConfigBool(Flags.EVAL_PARAMS_IN_ANNOTATIONS, shouldEvaluate);
end setEvaluateParametersInAnnotations;

public function orderConnections
  output Boolean show;
algorithm
  show := Flags.getConfigBool(Flags.ORDER_CONNECTIONS);
end orderConnections;

public function setOrderConnections
  input Boolean show;
algorithm
  Flags.setConfigBool(Flags.ORDER_CONNECTIONS, show);
end setOrderConnections;

public function getPreOptModules
  output list<String> outStringLst;
algorithm
  outStringLst := Flags.getConfigStringList(Flags.PRE_OPT_MODULES);
end getPreOptModules;

public function getPastOptModules
  output list<String> outStringLst;
algorithm
  outStringLst := Flags.getConfigStringList(Flags.POST_OPT_MODULES);
end getPastOptModules;

public function setPreOptModules
  input list<String> inStringLst;
algorithm
  Flags.setConfigStringList(Flags.PRE_OPT_MODULES, inStringLst);
end setPreOptModules;

public function setPastOptModules
  input list<String> inStringLst;
algorithm
  Flags.setConfigStringList(Flags.POST_OPT_MODULES, inStringLst);
end setPastOptModules;

public function getIndexReductionMethod
  output String outString;
algorithm
  outString := Flags.getConfigString(Flags.INDEX_REDUCTION_METHOD);
end getIndexReductionMethod;

public function setIndexReductionMethod
  input String inString;
algorithm
  Flags.setConfigString(Flags.INDEX_REDUCTION_METHOD, inString);
end setIndexReductionMethod;

public function simCodeTarget "Default is set by +simCodeTarget=C"
  output String target;
algorithm
  target := Flags.getConfigString(Flags.SIMCODE_TARGET);
end simCodeTarget;

public function getLanguageStandard
  output LanguageStandard outStandard;
algorithm
  outStandard := intLanguageStandard(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD));
end getLanguageStandard;

public function setLanguageStandard
  input LanguageStandard inStandard;
algorithm
  Flags.setConfigEnum(Flags.LANGUAGE_STANDARD, languageStandardInt(inStandard));
end setLanguageStandard;

public function languageStandardAtLeast
  input LanguageStandard inStandard;
  output Boolean outRes;
protected
  LanguageStandard std;
algorithm
  std := getLanguageStandard();
  outRes := intGe(languageStandardInt(std), languageStandardInt(inStandard));
end languageStandardAtLeast;

public function languageStandardAtMost
  input LanguageStandard inStandard;
  output Boolean outRes;
protected
  LanguageStandard std;
algorithm
  std := getLanguageStandard();
  outRes := intLe(languageStandardInt(std), languageStandardInt(inStandard));
end languageStandardAtMost;

protected function languageStandardInt
  input LanguageStandard inStandard;
  output Integer outValue;
algorithm
  outValue := match(inStandard)
    case MODELICA_1_X() then 10;
    case MODELICA_2_X() then 20;
    case MODELICA_3_0() then 30;
    case MODELICA_3_1() then 31;
    case MODELICA_3_2() then 32;
    case MODELICA_3_3() then 33;
    case MODELICA_LATEST() then 1000;
  end match;
end languageStandardInt;

protected function intLanguageStandard
  input Integer inValue;
  output LanguageStandard outStandard;
algorithm
  outStandard := match(inValue)
    case 10 then MODELICA_1_X();
    case 20 then MODELICA_2_X();
    case 30 then MODELICA_3_0();
    case 31 then MODELICA_3_1();
    case 32 then MODELICA_3_2();
    case 33 then MODELICA_3_3();
    case 1000 then MODELICA_LATEST();
  end match;
end intLanguageStandard;

public function languageStandardString
  input LanguageStandard inStandard;
  output String outString;
algorithm
  outString := match(inStandard)
    case MODELICA_1_X() then "1.x";
    case MODELICA_2_X() then "2.x";
    case MODELICA_3_0() then "3.0";
    case MODELICA_3_1() then "3.1";
    case MODELICA_3_2() then "3.2";
    case MODELICA_3_3() then "3.3";
    // Change this to latest version if you add more version!
    case MODELICA_LATEST() then "3.3";
  end match;
end languageStandardString;

public function setLanguageStandardFromMSL
  input String inLibraryName;
algorithm
  _ := matchcontinue(inLibraryName)
    local
      String version, new_std_str;
      LanguageStandard new_std, current_std;
      Boolean show_warning;

    case _
      equation
        {"Modelica", version} = System.strtok(inLibraryName, " ");
        new_std = versionStringToStd(version);
        current_std = getLanguageStandard();
        false = valueEq(new_std, current_std);
        setLanguageStandard(new_std);
        show_warning = languageStandardAtMost(MODELICA_3_0());
        new_std_str = languageStandardString(new_std);
        Debug.bcall2(show_warning, Error.addMessage, Error.CHANGED_STD_VERSION,
          {new_std_str, version});
      then
        ();

    else ();
  end matchcontinue;
end setLanguageStandardFromMSL;

protected function versionStringToStd
  input String inVersion;
  output LanguageStandard outStandard;
protected
  list<String> version;
algorithm
  version := System.strtok(inVersion, ".");
  outStandard := versionStringToStd2(version);
end versionStringToStd;

protected function versionStringToStd2
  input list<String> inVersion;
  output LanguageStandard outStandard;
algorithm
  outStandard := match(inVersion)
    case "1" :: _ then MODELICA_1_X();
    case "2" :: _ then MODELICA_2_X();
    case "3" :: "0" :: _ then MODELICA_3_0();
    case "3" :: "1" :: _ then MODELICA_3_1();
    case "3" :: "2" :: _ then MODELICA_3_2();
    case "3" :: "3" :: _ then MODELICA_3_3();
    case "3" :: _ then MODELICA_LATEST();
  end match;
end versionStringToStd2;

public function showErrorMessages
  output Boolean outShowErrorMessages;
algorithm
  outShowErrorMessages := Flags.getConfigBool(Flags.SHOW_ERROR_MESSAGES);
end showErrorMessages;

end Config;

