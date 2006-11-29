/*
Copyright (c) 1998-2006, Link�pings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

* Neither the name of Link�pings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/* File: simulation_runtime.h
 *
 * Description: This file is a C++ header file for the simulation runtime.
 * It contains solver functions and other simulation runtime specific functions
 */

#ifndef _SIMULATION_EVENTS_H
#define _SIMULATION_EVENTS_H

int initializeEventData();
void deinitializeEventData();

int checkForDiscreteVarChanges();
void calcEnabledZeroCrossings();
void CheckForNewEvents(double *t);
void CheckForInitialEvents(double *t);
void checkForInitialZeroCrossings(long*jroot);
void StartEventIteration(double *t);
void StateEventHandler(long jroot[], double *t);
void AddEvent(long);

void saveall();
void save(double & var);
double pre(double & var);
bool edge(double& var);
bool change(double& var);

double Sample(double t, double start ,double interval);
double sample(double start ,double interval);

double Less(double a,double b);
double LessEq(double a,double b);
double Greater(double a,double b);
double GreaterEq(double a,double b);
#define ZEROCROSSING(ind,exp) gout[ind] = (zeroCrossingEnabled[ind])?double(zeroCrossingEnabled[ind])*exp:1.0
#define noEvent(arg) arg
#define initial() localData->init

int 
function_zeroCrossing(long *neqm, double *t, double *x, long *ng, double *gout, double *rpar, long* ipar);

int
handleZeroCrossing(long index);

int
function_when(int i);

extern long* zeroCrossingEnabled;

#endif
