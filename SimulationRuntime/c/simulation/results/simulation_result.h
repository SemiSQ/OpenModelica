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

/*
 * File: simulation_runtime.h
 *
 * Description: This file is a C++ header file for the simulation runtime.
 * It contains a prototype for the simulation result interface.
 *
 */

#ifndef _SIMULATION_RESULT_H
#define _SIMULATION_RESULT_H

class SimulationResultBaseException {};
class SimulationResultFileOpenException : SimulationResultBaseException {};
class SimulationResultFileCloseException : SimulationResultBaseException {};
class SimulationResultMallocException : SimulationResultBaseException {};
class SimulationResultReallocException : SimulationResultBaseException {};

/*
 * numpoints, maximum number of points that can be stored.
 * nx number of states
 * ny number of variables
 * np number of parameters  (not used in this impl.)
 */
class simulation_result { 
protected:
  const char* filename;
  const long numpoints;
public:

  simulation_result(const char* filename, long numpoints) : filename(filename), numpoints(numpoints) {};
  virtual ~simulation_result() {};
  virtual void emit() =0;
  virtual const char* result_type() = 0;

};

#endif
