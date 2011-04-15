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

encapsulated package SimulationResults
" file:         SimulationResults.mo
  package:     SimulationResults
  description: Read simulation results into the Values.Value structure.

  RCS: $Id$

  "

public import Values;

public function val
  input String filename;
  input String varname;
  input Real timeStamp;
  output Real val;
external "C" val=SimulationResults_val(filename,varname,timeStamp);
end val;

public function readVariables
  input String filename;
  output list<String> vars;

  external "C" vars=SimulationResults_readVariables(filename) annotation(Library = "omcruntime");
end readVariables;

public function readDataset
  input String filename;
  input list<String> vars;
  input Integer dimsize;
  output list<list<Real>> outMatrix;

  external "C" outMatrix=SimulationResults_readDataset(filename,vars,dimsize) annotation(Library = "omcruntime");
end readDataset;

public function readSimulationResultSize
  input String filename;
  output Integer size;

  external "C" size=SimulationResults_readSimulationResultSize(filename) annotation(Library = "omcruntime");
end readSimulationResultSize;

public function close
  external "C" SimulationResultsImpl__close() annotation(Library = "omcruntime");
end close;


public function cmpSimulationResults
  input String filename;
  input String reffilename;
  input String logfilename;
  input Real refTol;
  input Real absTol;
  input list<String> vars;
  output list<String> res;
  external "C" res=SimulationResults_cmpSimulationResults(filename,reffilename,logfilename,refTol,absTol,vars) annotation(Library = "omcruntime");
end cmpSimulationResults;


end SimulationResults;

