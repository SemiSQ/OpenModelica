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

/*
 * File: solver_main.h
 *
 * Description: This file is a C header file for the main solver function.
 * It contains integration method for simulation.
 *
 */

#ifndef _SOLVER_MAIN_H
#define _SOLVER_MAIN_H

#include "openmodelica.h"
#include "simulation_data.h"


typedef struct SOLVER_INFO
{
  double currentTime;
  double currentStepSize;
  double laststep;
  double offset;

  modelica_boolean didEventStep;
  modelica_boolean sampleEventActivated;

  /* stats */
  unsigned int stateEvents;
  unsigned int sampleEvents;
  unsigned int stepNo;
  unsigned int callsODE;
  unsigned int callsDAE;

  void* solverData;
}SOLVER_INFO;


#ifdef __cplusplus
extern "C" {
#endif

extern int solver_main(DATA* simData, double start, double stop, double step,
    long outputSteps, double tolerance, const char* init_initMethod,
    const char* init_optiMethod, const char* init_file, double init_time,
    int flag,const char* outputVariablesAtEnd);

#ifdef __cplusplus
}
#endif

#endif
