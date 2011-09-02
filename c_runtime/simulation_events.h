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

/* File: simulation_runtime.h
 *
 * Description: This file is a C++ header file for the simulation runtime.
 * It contains solver functions and other simulation runtime specific functions
 */

#ifndef _SIMULATION_EVENTS_H
#define _SIMULATION_EVENTS_H

#include "integer_array.h"
#include "boolean_array.h"
#include "fortran_types.h"

#ifdef __cplusplus
#include <list>
using namespace std;

double
BiSection(double*, double*, double*, double*, list<int> *);

int
CheckZeroCrossings(list<int>*);

extern "C" {

#endif

int
initializeEventData();
void
deinitializeEventData();

void
saveall();
void
restoreHelpVars();

double
Sample(double t, double start, double interval);
double
sample(double start, double interval, int hindex);
void
initSample(double start, double stop);

double
Less(double a, double b);
double
LessEq(double a, double b);
double
Greater(double a, double b);
double
GreaterEq(double a, double b);

void
checkTermination();
int
checkForSampleEvent();

double
getNextSampleTimeFMU();

extern long inUpdate;
static const int IterationMax = 200;

#define ZEROCROSSING(ind,exp) { \
        gout[ind] = exp; \
}

#define RELATIONTOZC(res,exp1,exp2,index,op_w,op) { \
    if (index == -1){ \
        res = (exp1) op (exp2); \
    }else{ \
        res = backuprelations[index];} \
}
#define SAVEZEROCROSS(res,exp1,exp2,index,op_w,op) { \
    if (index == -1){ \
        res = ((exp1) op (exp2)); \
    } else{ \
        res = ((exp1) op (exp2)); \
        backuprelations[index] = ((exp1) op (exp2)); \
    }\
}

#define initial() localData->init

extern long* zeroCrossingEnabled;

int
function_onlyZeroCrossings(double* gout, double* t);

int
CheckForNewEvent(int *sampleactived);

int
EventHandle(int);

void
FindRoot(double*);

int
checkForDiscreteChanges();

void
SaveZeroCrossings();

void
initializeZeroCrossings();

int
activateSampleEvents();

int
function_updateSample();

#define INTERVAL 1
#define NOINTERVAL 0

extern double TOL;

void
debugPrintHelpVars();
void
deactivateSampleEvent();
void
deactivateSampleEventsandEquations();
void
debugSampleEvents();

#ifdef __cplusplus
}
#endif

#endif
