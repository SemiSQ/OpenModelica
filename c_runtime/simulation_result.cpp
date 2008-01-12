/* 
 * This file is part of OpenModelica.
 * 
 * Copyright (c) 1998-2008, Link�pings University,
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

/* 
 * This file contains functions for storing the result of a simulation to a file.
 * 
 * The solver should call three functions in this file.
 * 1. Call initializeResult before starting simulation, telling maximum number of data points.
 * 2. Call emit() to store data points at given time (taken from globalData structure)
 * 3. Call deinitializeResult with actual number of points produced to store data to file.
 * 
 */

 #include <stdio.h>
 #include <errno.h>
 #include <string.h>
 #include <limits> /* adrpo - for std::numeric_limits in MSVC */
 #include "simulation_result.h"
 #include "simulation_runtime.h"
 #include "sendData/sendData.h"
 #include <sstream>
 
 double* simulationResultData=0; 
 long currentPos=0;
 long actualPoints=0; // the number of actual points saved
 int maxPoints;
 
 void add_result(double *data, long *actualPoints);
 
/* \brief
 * 
 * Emits data to result.
 * 
 * \return zero on sucess, non-zero otherwise
 */ 
int emit()
{	
  storeExtrapolationData();
  if (actualPoints < maxPoints) {
    add_result(simulationResultData,&actualPoints);
    return 0;
  }
  else {
    cout << "Too many points: " << actualPoints << " max points: " << maxPoints << endl;
    return -1;
  }
}
 
 /* \brief
 * add the values of one step for all variables to the data
 * array to be able to later store this on file.
 */
void add_result(double *data, long *actualPoints)
{
  //save time first
  //cerr << "adding result for time: " << time;
  //cerr.flush();
  if(Static::enabled())
  {
  std::ostringstream ss;
  ss << "time" << endl;
  ss << (data[currentPos++] = globalData->timeValue) << endl;
  // .. then states..
  for (int i = 0; i < globalData->nStates; i++, currentPos++) {
 	ss << globalData->statesNames[i] << endl;
    ss << (data[currentPos] = globalData->states[i]) << endl;
  }
  // ..followed by derivatives..
  for (int i = 0; i < globalData->nStates; i++, currentPos++) {
  	ss << globalData->stateDerivativesNames[i] << endl;
    ss << (data[currentPos] = globalData->statesDerivatives[i]) << endl;
  }
  // .. and last alg. vars.
  for (int i = 0; i < globalData->nAlgebraic; i++, currentPos++) {
  	ss << globalData->algebraicsNames[i] << endl;
    ss << (data[currentPos] = globalData->algebraics[i]) << endl;
  }
  
  sendPacket(ss.str().c_str());
  }
  else
  {

  (data[currentPos++] = globalData->timeValue);
  // .. then states..
  for (int i = 0; i < globalData->nStates; i++, currentPos++) {
 	(data[currentPos] = globalData->states[i]);
  }
  // ..followed by derivatives..
  for (int i = 0; i < globalData->nStates; i++, currentPos++) {
    (data[currentPos] = globalData->statesDerivatives[i]);
  }
  // .. and last alg. vars.
  for (int i = 0; i < globalData->nAlgebraic; i++, currentPos++) {
    (data[currentPos] = globalData->algebraics[i]);
  }
  	
  }
  
  //cerr << "  ... done" << endl;
  (*actualPoints)++;
}

/* \brief initialize result data structures
 * 
 * \param numpoints, maximum number of points that can be stored.
 * \param nx number of states
 * \param ny number of variables
 * \param np number of parameters  (not used in this impl.)
 */

int initializeResult(long numpoints,long nx, long ny, long np)

{
  maxPoints = numpoints;
  
  if (numpoints < 0 ) { // Automatic number of output steps
  	cerr << "Warning automatic output steps not supported in OpenModelica yet." << endl;
  	cerr << "Attempt to solve this by allocating large amount of result data." << endl;
	numpoints = abs(numpoints);
	maxPoints = abs(numpoints);   	
  }
  
  simulationResultData = new double[numpoints*(nx*2+ny+1)];
  if (!simulationResultData) {
    cerr << "Error allocating simulation result data of size " << numpoints *(nx*2+ny)
	      << endl;
    return -1;
  }
  currentPos = 0;
  char* enabled = getenv("enableSendData");
  if(enabled != NULL)
  {
  	Static::enabled_ = !strcmp(enabled, "1");
  }
  if(Static::enabled)
  	initSendData(globalData->nStates, globalData->nAlgebraic, globalData->statesNames, globalData->stateDerivativesNames, globalData->algebraicsNames);
  
  return 0;
}


/* \brief
* stores the result of all variables for all timesteps on a file
* suitable for plotting, etc.
*/

int deinitializeResult(const char * filename)
{
  ofstream f(filename);
  if (!f)
  {
    cerr << "Error, couldn't create output file: [" << filename << "] because" << strerror(errno) << "." << endl;
    return -1;
  }

  // Rather ugly numbers than unneccessary rounding.
  f.precision(std::numeric_limits<double>::digits10 + 1);
  f << "#Ptolemy Plot file, generated by OpenModelica" << endl;
  f << "#IntervalSize=" << actualPoints << endl;
  f << "TitleText: OpenModelica simulation plot" << endl;
  f << "XLabel: t" << endl << endl;

  int num_vars = 1+globalData->nStates*2+globalData->nAlgebraic;
  
  // time variable.
  f << "DataSet: time"  << endl;
  for(int i = 0; i < actualPoints; ++i)
    f << simulationResultData[i*num_vars] << ", " << simulationResultData[i*num_vars]<< endl;
  f << endl;

  for(int var = 0; var < globalData->nStates; ++var)
  {
    f << "DataSet: " << globalData->statesNames[var] << endl;
    for(int i = 0; i < actualPoints; ++i)
      f << simulationResultData[i*num_vars] << ", " << simulationResultData[i*num_vars + 1+var] << endl;
    f << endl;
  }
  
  for(int var = 0; var < globalData->nStates; ++var)
  {
    f << "DataSet: " << globalData->stateDerivativesNames[var]  << endl;
    for(int i = 0; i < actualPoints; ++i)
      f << simulationResultData[i*num_vars] << ", " << simulationResultData[i*num_vars + 1+globalData->nStates+var] << endl;
    f << endl;
  }
  
  for(int var = 0; var < globalData->nAlgebraic; ++var)
  {
    f << "DataSet: " << globalData->algebraicsNames[var] << endl;
    for(int i = 0; i < actualPoints; ++i)
      f << simulationResultData[i*num_vars] << ", " << simulationResultData[i*num_vars + 1+2*globalData->nStates+var] << endl;
    f << endl;
  }

  f.close();
  if (!f)
  {
    cerr << "Error, couldn't write to output file " << filename << endl;
    return -1;
  }
  
  if(Static::enabled())
  	closeSendData();
  return 0;
}
