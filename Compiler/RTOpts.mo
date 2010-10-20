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

package RTOpts
" file:	       RTOpts.mo
  package:     RTOpts
  description: Runtime options

  RCS: $Id$

  This module takes care of command line options. It is possible to
  ask it what flags are set, what arguments were given etc.

  This module is used pretty much everywhere where debug calls are made."


public function args
  input list<String> inStringLst;
  output list<String> outStringLst;

  external "C" outStringLst=RTOpts_args(inStringLst);
end args;

public function typeinfo
  output Boolean outBoolean;

  external "C" outBoolean = RTOpts_typeinfo();
end typeinfo;

public function splitArrays
  output Boolean outBoolean;

  external "C" splitArrays = RTOpts_splitArrays();
end splitArrays;

public function paramsStruct
  output Boolean outBoolean;

  external "C" outBoolean = RTOpts_paramsStruct();
end paramsStruct;

public function modelicaOutput
  output Boolean outBoolean;

  external "C" outBoolean = RTOpts_modelicaOutput();
end modelicaOutput;

public function debugFlag
  input String inString;
  output Boolean outBoolean;

  external "C" outBoolean=RTOpts_debugFlag(inString);
end debugFlag;

public function setDebugFlag
  input String inString;
  input Integer value;
  output Boolean str;

  external "C" str = RTOpts_setDebugFlag(inString,value);
end setDebugFlag;

public function noProc
  output Integer outInteger;

  external "C" noProc = RTOpts_noProc();
end noProc;

public function setEliminationLevel
  input Integer level;

  external "C" ;
end setEliminationLevel;

public function eliminationLevel
  output Integer level;

  external "C" level = RTOpts_level();
end eliminationLevel;

public function latency
  output Real outReal;

  external "C" outReal = RTOpts_latency();
end latency;

public function bandwidth
  output Real outReal;

  external "C" outReal = RTOpts_bandwidth();
end bandwidth;

public function simulationCg
  output Boolean outBoolean;

  external "C" outBoolean = RTOpts_simulationCg();
end simulationCg;

public function simulationCodeTarget
"@author: adrpo
 returns: 'gcc' or 'msvc'
 usage: omc [+target=gcc|msvc], default to 'gcc'."
  output String outCodeTarget;

  external "C" outCodeTarget = RTOpts_simulationCodeTarget();
end simulationCodeTarget;

public function classToInstantiate
  output String modelName;

  external "C" modelName = RTOpts_classToInstantiate();
end classToInstantiate;

public function silent
  output Boolean outBoolean;

  external "C" outBoolean = RTOpts_silent();
end silent;

public function versionRequest
  output Boolean outBoolean;

  external "C" outBoolean = RTOpts_versionRequest();
end versionRequest;

public function acceptMetaModelicaGrammar
"@author: adrpo 2007-06-11
 returns: true if MetaModelica grammar is accepted or false otherwise
 usage: omc [+g=Modelica|MetaModelica], default to 'Modelica'."
  output Boolean outBoolean;

  external "C" outBoolean = RTOpts_acceptMetaModelicaGrammar();
end acceptMetaModelicaGrammar;

public function getAnnotationVersion
"@author: adrpo 2008-11-28
   returns what flag was given at start
     omc [+annotationVersion=3.x]
   or via the API
     setAnnotationVersion(\"3.x\");
   for annotations: 1.x or 2.x or 3.x"
  output String annotationVersion;
  external "C" annotationVersion = RTOpts_getAnnotationVersion();
end getAnnotationVersion;

public function setAnnotationVersion
"@author: adrpo 2008-11-28
   setAnnotationVersion(\"3.x\");
   for annotations: 1.x or 2.x or 3.x"
  input String annotationVersion;
  external "C";
end setAnnotationVersion;

public function getNoSimplify
"@author: adrpo 2008-12-13
   returns what flag was given at start
     omc [+noSimplify]
   or via the API
     setNoSimplify(true|false);"
  output Boolean noSimplify;
  external "C" noSimplify = RTOpts_getNoSimplify();
end getNoSimplify;

public function setNoSimplify
"@author: adrpo 2008-12-13
   setAnnotationVersion(\"3.x\");
   for annotations: 1.x or 2.x or 3.x"
  input Boolean noSimplify;
  external "C";
end setNoSimplify;

public function vectorizationLimit
  "Returns the vectorization limit that is used to determine how large an array
  can be before it no longer is expanded by Static.crefVectorize."
  output Integer limit;
  external "C" limit = RTOpts_vectorizationLimit();
end vectorizationLimit;

public function setVectorizationLimit
  "Sets the vectorization limit, see vectorizationLimit above."
  input Integer limit;
  external "C";
end setVectorizationLimit;

public function showAnnotations
  output Boolean show;
  external "C" show = RTOpts_showAnnotations();
end showAnnotations;

public function setShowAnnotations
  input Boolean show;
  external "C";
end setShowAnnotations;

public function getRunningTestsuite
  output Boolean runningTestsuite;
  external "C" runningTestsuite = RTOpts_getRunningTestsuite();
end getRunningTestsuite;

end RTOpts;

