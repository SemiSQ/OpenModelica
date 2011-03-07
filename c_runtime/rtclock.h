/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
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
 * from Linköpings University, either from the above address,
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

#ifndef __RTCLOCK__H
#define __RTCLOCK__H

#ifdef __cplusplus
extern "C" {
#endif

#define NUM_RT_CLOCKS 17
#define NUM_USER_RT_CLOCKS 16
#define RT_CLOCK_SPECIAL_STOPWATCH 16 /* The 17th clock */

/* Simulation-specific timing macros */
#define SIM_TIMER_TOTAL          0
#define SIM_TIMER_INIT           1
#define SIM_TIMER_STEP           2
#define SIM_TIMER_OUTPUT         3
#define SIM_TIMER_EVENT          4
#define SIM_TIMER_LINEARIZE      5
#define SIM_TIMER_PREINIT        6
#define SIM_TIMER_OVERHEAD       7
#define SIM_TIMER_FIRST_FUNCTION 8

#define SIM_PROF_TICK_FN(ix) rt_tick(ix+SIM_TIMER_FIRST_FUNCTION)
#define SIM_PROF_ACC_FN(ix) rt_accumulate(ix+SIM_TIMER_FIRST_FUNCTION)

#define SIM_PROF_TICK_EQ(ix) rt_tick(ix+SIM_TIMER_FIRST_FUNCTION+localData->nFunctions)
#define SIM_PROF_ACC_EQ(ix) rt_accumulate(ix+SIM_TIMER_FIRST_FUNCTION+localData->nFunctions)
#define SIM_PROF_ADD_NCALL_EQ(ix,num) rt_add_ncall(ix+SIM_TIMER_FIRST_FUNCTION+localData->nFunctions,num)

void rt_init(int numTimer);

void rt_tick(int ix);
/* tick() ... tock() -> returns the number of seconds since the tick */
double rt_tock(int ix);

/* clear() ... tick() ... accumulate() ... tick() ... accumulate() ... accumuluated()
 * returns the total number of seconds accumulated between the tick() and accumulate() calls */
void rt_clear_total(int ix);
/* clear zeros out the accumulated data, and adds it to the total (we have two levels of accumulation) */
void rt_clear(int ix);
void rt_accumulate(int ix); /* Uses integer addition for maximum accuracy and good speed. */
double rt_accumulated(int ix);
double rt_max_accumulated(int ix);
double rt_total(int ix);
/* Returns the number of times tick() was called since the last clear() */
long rt_ncall(int ix);
long rt_ncall_total(int ix);
void rt_add_ncall(int ix, int n);

#ifdef __cplusplus
}
#endif

#endif
