/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Link�pings University,
 * Department of Computer and Information Science,
 * SE-58183 Link�ping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Link�pings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include <stdio.h>
#include <stdlib.h>


extern "C" {

#include "meta_modelica.h"
#include "rml_compatibility.h"
#include "OpenModelicaBootstrappingHeader.h"

#include "SimulationResults.c"

static SimulationResult_Globals simresglob = {UNKNOWN_PLOT,NULL,{NULL,NULL,0,NULL,0,NULL,0,0,0,NULL},NULL,NULL};

void* SimulationResults_readVariables(const char *filename, const char *visvars)
{
  return SimulationResultsImpl__readVars(filename,&simresglob);
}

extern void* _ValuesUtil_reverseMatrix(void*);
void* SimulationResults_readDataset(const char *filename, void *vars, int datasize)
{
  void *res = SimulationResultsImpl__readDataset(filename,vars,datasize,&simresglob);
  if (res == NULL) MMC_THROW();
  return res;
}

int SimulationResults_readSimulationResultSize(const char *filename)
{
  return SimulationResultsImpl__readSimulationResultSize(filename,&simresglob);
}

double SimulationResults_val(const char *filename, const char *varname, double timeStamp)
{
  return SimulationResultsImpl__val(filename,varname,timeStamp,&simresglob);
}

}
