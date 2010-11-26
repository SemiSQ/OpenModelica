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

package SimulationResults
" file:	       SimulationResults.mo
  package:     SimulationResults
  description: Read simulation results into the Values.Value structure.

  RCS: $Id$

  "

public import Values;
protected import ValuesUtil;

public function readPtolemyplotVariables
  input String inString;
  input String inVisVars;
  output list<String> outStringLst;

  external "C" outStringLst=SimulationResults_readPtolemyplotVariables(inString,inVisVars) annotation(Library = "omcruntime");
end readPtolemyplotVariables;

protected function readPtolemyplotDatasetWork
  input String inString;
  input list<String> inStringLst;
  input Integer inInteger;
  output Values.Value outValue;

  external "C" outValue=SimulationResults_readPtolemyplotDataset(inString,inStringLst,inInteger) annotation(Library = "omcruntime");
end readPtolemyplotDatasetWork;

public function readPtolemyplotDataset
  input String inString;
  input list<String> inStringLst;
  input Integer inInteger;
  output Values.Value outValue;
algorithm
  outValue := ValuesUtil.reverseMatrix(readPtolemyplotDatasetWork(inString,inStringLst,inInteger));
end readPtolemyplotDataset;

public function readPtolemyplotDatasetSize
  input String inString;
  output Values.Value outValue;

  external "C" outValue=SimulationResults_readPtolemyplotDatasetSize(inString) annotation(Library = "omcruntime");
end readPtolemyplotDatasetSize;

end SimulationResults;

