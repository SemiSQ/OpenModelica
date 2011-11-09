/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Link?ping University,
 * Department of Computer and Information Science,
 * SE-58183 Link?ping, Sweden.
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
 * from Link?ping University, either from the above address,
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

#include "solver_main.h"
#include "simulation_result.h"
#include "simulation_init.h"
#include "simulation_runtime.h"
#include "options.h"
#include <math.h>
#include <string.h>
#include <iostream>
#include <iomanip>
#include <algorithm>
#include <cstdarg>
#include <cfloat>
#include <stdint.h>
#include <errno.h>
#include "rtclock.h"
#include <assert.h>

using namespace std;

/*********************       internal definitions; do not expose        ***********************/
int
init_stepsize(int(*f)());

int
stepsize_control(double &start, double &stop, double &fixStep, int(*f)(),
                 bool &reinit_step, bool &useInterpolation);

int
euler_ex_step(double* step, int(*f)());

int
rungekutta_step(double* step, int(*f)());

int
dopri54(int(*f)(), double* x4, double* x5);

int
dasrt_step(double* step, double &start, double &stop, bool &trigger,
           int* stats);

int
interpolation_control(const int &dideventstep, double &interpolationStep,
                      double &fixStep, double &stop);

/*********************variable declaration and functions for DASSL-solver**********************/
#define MAXORD 5
#define DASSLSTATS 5
#define INFOLEN 15

double reltol;
double abstol;
/* external variables >> these variables mustn't be deleted or changed during the WHOLE integration process,
 *				            >> so they have to be declared outside dasrt_step
 *					          >> exception: solver has to be reset after an event */
fortran_integer info[INFOLEN];
fortran_integer idid = 0;
fortran_integer* ipar = 0;

/* work arrays for DASSL */
fortran_integer liw = 0;
fortran_integer lrw = 0;
double *rwork = NULL;
fortran_integer *iwork = 0;
fortran_integer NG_var = 0; /* ->see ddasrt.c LINE 250 (number of constraint functions) */
fortran_integer *jroot = NULL;

/* Used when calculating residual for its side effects. (alg. var calc) */
double *dummy_delta = NULL;

/* provides a dummy Jacobian to be used with DASSL */
int
dummy_Jacobian(double *t, double *y, double *yprime, double *pd,
               double *cj, double *rpar, fortran_integer* ipar) {
  return 0;
}

/* provides a analytical Jacobian to be used with DASSL */
int
Jacobian(double *t, double *y, double *yprime, double *pd, double *cj,
         double *rpar, fortran_integer* ipar) {
  double* backupStates;
  double backupTime;
  backupStates = globalData->states;
  backupTime = globalData->timeValue;

  globalData->states = y;
  globalData->timeValue = *t;
  functionODE();
  functionJacA(pd);

  /* add cj to the diagonal elements of the matrix */
  for (int i = 0; i < globalData->nStates; i++) {
    pd[i + i * globalData->nStates] -= (double) *cj;
  }
  globalData->states = backupStates;
  globalData->timeValue = backupTime;

  return 0;
}

/* provides a numerical Jacobian to be used with DASSL */
int
JacA_num(double *t, double *y, double *matrixA) {
  double delta_h = 1.e-10;
  double delta_hh;
  double* yprime = new double[globalData->nStates];
  double* yprime_delta_h = new double[globalData->nStates];

  double* backupStates;
  double backupTime;
  backupStates = globalData->states;
  backupTime = globalData->timeValue;

  globalData->states = y;
  globalData->timeValue = *t;

  functionODE();
  memcpy(yprime, globalData->statesDerivatives,
      globalData->nStates * sizeof(double));

  /* matrix A, add cj to diagonal elements and store in pd */
  int l;
  for (int i = 0; i < globalData->nStates; i++) {
    delta_hh = delta_h * (globalData->states[i] > 0 ? globalData->states[i]
                                                                         : -globalData->states[i]);
    delta_hh = ((delta_h > delta_hh) ? delta_h : delta_hh);
    globalData->states[i] += delta_hh;
    functionODE();
    globalData->states[i] -= delta_hh;

    for (int j = 0; j < globalData->nStates; j++) {
      l = j + i * globalData->nStates;
      matrixA[l] = (globalData->statesDerivatives[j] - yprime[j]) / delta_hh;
    }
  }

  globalData->states = backupStates;
  globalData->timeValue = backupTime;
  delete[] yprime;
  delete[] yprime_delta_h;

  return 0;
}

//provides a numerical Jacobian to be used with DASSL
int Jacobian_num(double *t, double *y, double *yprime, double *pd, double *cj,
    double *rpar, fortran_integer* ipar) {

  if (JacA_num(t, y, pd)) {
    cerr << "Error, can not get Matrix A " << endl;
    return 1;
  }

  /* add cj to diagonal elements and store in pd */
  for (int i = 0; i < globalData->nStates; i++) {
    for (int j = 0; j < globalData->nStates; j++) {
      if (i == j) {
        pd[i + j * globalData->nStates] -= (double) *cj;
      }
    }
  }
  return 0;
}

int
dummy_zeroCrossing(fortran_integer *neqm, double *t, double *y,
                   fortran_integer *ng, double *gout, double *rpar, fortran_integer* ipar) {
  return 0;
}

bool
continue_DASRT(fortran_integer* idid, double* atol, double *rtol);

/*********************end of variable declaration and functions for DASSL-solver***************/

double
maxnorm(double* a, double* b) {

  double max_value = 0;
  double* c = new double[globalData->nStates];

  for (int i = 0; i < globalData->nStates; i++) {
    c[i] = fabs(b[i] - a[i]);
    if (c[i] > max_value)
      max_value = c[i];
  }
  delete[] c;
  return max_value;
}

double
euklidnorm(double* a) {

  double erg = 0;

  for (int i = 0; i < globalData->nStates; i++) {
    erg = pow(a[i], 2) + erg;
  }
  return sqrt(erg);
}

/*********************variable declaration for RK4-solver**************************************/
const int rungekutta_s = 4;
const double rungekutta_b[rungekutta_s] = { 1.0 / 6.0, 1.0 / 3.0, 1.0 / 3.0, 1.0 / 6.0 };
const double rungekutta_c[rungekutta_s] = { 0.0, 0.5, 0.5, 1.0 };
/*********************variable declaration for DOPRI5(4)***************************************/
const int dopri5_s = 7;
const int dop5dense_s = 9;
const double dop_bst[dop5dense_s][6] = { { 696.0, -2439.0, 3104.0, -1710.0, 384.0, 384.0 },
                                         { 0.0, 0.0, 0.0, 0.0, 0.0, 1.0 },
                                         { -12000.0, 25500.0, -16000.0, 3000.0, 0.0, 1113.0 },
                                         { -3000.0, 6375.0, -4000.0, 750.0, 0.0, 192.0 },
                                         { 52488.0, -111537.0, 69984.0, -13122.0, 0.0, 6784.0 },
                                         { -264.0, 561.0, -352.0, 66.0, 0.0, 84.0 },
                                         { 32.0, -63.0, 38.0, -7.0, 0.0, 8.0 },
                                         { 0.0, 125.0, -250.0, 125.0, 0.0, 24.0 },
                                         { 48.0, -112.0, 80.0, -16.0, 0.0, 3.0 } };
const double dop_b5[dop5dense_s] = { 5179.0 / 57600.0, 0.0, 7571.0 / 16695.0,
                                     393.0 / 640.0, -92097.0 / 339200.0, 187.0 / 2100.0,
                                     1.0 / 40.0, 0.0, 0.0 }; /* b_i */
const double dop_b4[dop5dense_s] = { 35.0 / 384.0, 0.0, 500.0 / 1113.0,
                                     125.0 / 192.0, -2187.0 / 6784.0, 11.0 / 84.0,
                                     0.0, 0.0, 0.0 }; /* ^b_i */
const double dop_c[dop5dense_s] = { 0.0, 1.0 / 5.0, 3.0 / 10.0, 4.0 / 5.0, 8.0 / 9.0,
                                    1.0, 1.0, 1.0 / 5.0, 1.0 / 2.0 };
const double dop_a[][dop5dense_s] = { { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
                                      { 1.0 / 5.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
                                      { 3.0 / 40.0, 9.0 / 40.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
                                      { 44.0 / 45.0, -56.0 / 15.0, 32.0 / 9.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
                                      { 19372.0 / 6561.0, -25360.0 / 2187.0, 64448.0 / 6561.0, -212.0 / 729.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
                                      { 9017.0 / 3168.0, -355.0 / 33.0, 46732.0 / 5247.0, 49.0 / 176.0, -5103.0 / 18656.0, 0.0, 0.0, 0.0, 0.0 },
                                      { 35.0 / 384.0, 0.0, 500.0 / 1113.0, 125.0 / 192.0, -2187.0 / 6784.0, 11.0 / 84.0, 0.0, 0.0, 0.0 },
                                      { 5207.0 / 48000.0, 0.0, 92.0 / 795.0, -79.0 / 960.0, 53217.0 / 848000.0, -11.0 / 300.0, 4.0 / 125.0, 0.0, 0.0 },
                                      { 613.0 / 6144.0, 0.0, 125.0 / 318.0, -125.0 / 3072.0, 8019.0 / 108544.0, -11.0 / 192.0, 1.0 / 32.0, 0.0, 0.0 } };

/*********************work array for inline implementation*************************************/
double **work_states = NULL;

int reject = 0;

int
solver_main_step(int flag, double &start, double &stop, bool &reset,
                 bool &reinit_step, bool &useInterpolation, double &fixStep, int* stats) {
  switch (flag) {
  case 2:
    return rungekutta_step(&globalData->current_stepsize, functionODE);
  case 3:
    return dasrt_step(&globalData->current_stepsize, start, stop, reset, stats);
  case 4:
    return functionODE_inline();
  case 6:
    return stepsize_control(start, stop, fixStep, functionODE, reinit_step,
                            useInterpolation);
    /* embedded DOPRI5(4) */
  case 1:
  default:
    return euler_ex_step(&globalData->current_stepsize, functionODE);
  }
}

/*	function: update_DAEsystem
 *
 * 	! Function to update the whole system with EventIteration.
 * 	Evaluate the functionDAE() */
void
update_DAEsystem() {
  int needToIterate = 0;
  int IterationNum = 0;

  functionDAE(&needToIterate);
  while (checkForDiscreteChanges() || needToIterate) {
    if (needToIterate) {
      if (sim_verbose >= LOG_EVENTS)
      {
        fprintf(stdout, "| info LOG_EVENTS | reinit call. Iteration needed!\n"); fflush(NULL);
      }
    } else {
      if (sim_verbose >= LOG_EVENTS)
      {
        fprintf(stdout, "| info LOG_EVENTS | discrete Var changed. Iteration needed!\n"); fflush(NULL);
      }
    }
    saveall();
    functionDAE(&needToIterate);
    IterationNum++;
    if (IterationNum > IterationMax) {
      throw TerminateSimulationException(globalData->timeValue, string(
          "ERROR: Too many event iterations. System is inconsistent!\n"));
    }
  }
}

/* The main function for a solver with synchronous event handling
 * flag 1=explicit euler
 * 2=rungekutta
 * 3=dassl
 * 4=inline
 * 5=free
 * 6=dopri5 with stepsize control & dense output */

int
solver_main(int argc, char** argv, double &start, double &stop,
            double &step, long &outputSteps, double &tolerance, int flag) {

  bool useInterpolation = false;
  /* Set user tolerance for solver (DASSL,Dopri5) */
  reltol = tolerance;
  abstol = tolerance;

  /* Setup some variables for statistics */
  int stateEvents = 0;
  int sampleEvents = 0;

  int dasslStats[DASSLSTATS];
  int dasslStatsTmp[DASSLSTATS];
  for (int i = 0; i < DASSLSTATS; i++) {
    dasslStats[i] = 0;
    dasslStatsTmp[i] = 0;
  }

  /* Flags for event handling */
  int dideventstep = 0;
  bool reset = false;
  bool reinit_step = true;

  double laststep = 0;
  double offset = 0;
  globalData->terminal = 0;
  globalData->oldTime = start;
  globalData->timeValue = start;

  if (outputSteps > 0) { /* Use outputSteps if set, otherwise use step size. */
    step = (stop - start) / outputSteps;
  } else {
    if (step == 0) { /* outputsteps not defined and zero step, use default 1e-3 */
      step = 1e-3;
    }
  }
  globalData->current_stepsize = step;
  double interpolationStep; /* this variable is used for output at fixed points */
  interpolationStep = step; /* first interpolation point is the value of the fixed external stepsize */

  int sampleEvent_actived = 0;

  double uround = dlamch_((char*) "P", 1);

  const std::string* init_method = getFlagValue("im", argc, argv);      /* get the old initialization-flag */
  const std::string* init_initMethod = getFlagValue("iim", argc, argv); /* get the initialization method */
  const std::string* init_optiMethod = getFlagValue("iom", argc, argv); /* get the optimization method for the initialization */

  if (init_method) {
    fprintf(stdout,
        "Error: old flag: initialization-method [im] is rejected\n");
    fprintf(stdout,
        "       new flag: init-initialization-method [iim] current options are: state or old\n");
    fprintf(stdout,
        "       new flag: init-optimization-method [iom] current options are: simplex or newuoa\n");
    return -1;
  }

  int retValIntegrator = 0;

  switch (flag) {
  /* Allocate RK work arrays */
  case 2:
    work_states = (double**) malloc((rungekutta_s + 1) * sizeof(double*));
    for (int i = 0; i < rungekutta_s + 1; i++)
      work_states[i] = (double*) calloc(globalData->nStates, sizeof(double));
    break;
    /* Enable inlining solvers */
  case 4:
    work_states = (double**) malloc(inline_work_states_ndims * sizeof(double*));
    for (int i = 0; i < inline_work_states_ndims; i++)
      work_states[i] = (double*) calloc(globalData->nStates, sizeof(double));
    break;
    /* Allocate DOPRI5(4) derivative array and activate dense output */
  case 6:
    useInterpolation = true;
    work_states = (double**) malloc((dop5dense_s + 1) * sizeof(double*));
    for (int i = 0; i < dop5dense_s + 1; i++)
      work_states[i] = (double*) calloc(globalData->nStates, sizeof(double));
    break;
  }

  if (initializeEventData()) {
    fprintf(stdout, "Internal error, allocating event data structures\n"); fflush(NULL);
    return -1;
  }

  if (bound_parameters()) {
    fprintf(stdout, "Error calculating bound parameters\n"); fflush(NULL);
    return -1;
  }
  if (sim_verbose >= LOG_SOLVER) {
    fprintf(stdout, "| info LOG_SOLVER | Calculated bound parameters\n"); fflush(NULL);
  }
  /* Evaluate all constant equations during initialization */
  globalData->init = 1;
  functionAliasEquations();

  /* Calculate initial values from initial_function()
   * saveall() value as pre values */
  if (measure_time_flag) {
    rt_accumulate(SIM_TIMER_PREINIT);
    rt_tick(SIM_TIMER_INIT);
  }
  try {
    if (initialization(init_initMethod ? init_initMethod->c_str() : NULL,
        init_optiMethod ? init_optiMethod->c_str() : NULL)) {
      throw TerminateSimulationException(globalData->timeValue,
            string("Error in initialization. Storing results and exiting.\n"));
    }

    SaveZeroCrossings();
    saveall();
    if (sim_verbose >= LOG_SOLVER) {
      if (sim_result)
        sim_result->emit();
    }

    /* Activate sample and evaluate again */
    if (globalData->curSampleTimeIx < globalData->nSampleTimes) {
      sampleEvent_actived = checkForSampleEvent();
      activateSampleEvents();
    }
    update_DAEsystem();
    if (sampleEvent_actived) {
      deactivateSampleEventsandEquations();
      sampleEvent_actived = 0;
    }
    int tmp = 0;
    saveall();
    CheckForNewEvent(&tmp);
    SaveZeroCrossings();
    saveall();
    if (sim_result)
      sim_result->emit();
    storeExtrapolationDataEvent();
  } catch (TerminateSimulationException &e) {
    cout << e.getMessage() << endl;
    printf("Simulation terminated while the initialization. Could not find suitable initial values."); fflush(NULL);
    return -1;
  }

  /* Initialization complete */
  if (measure_time_flag)
    rt_accumulate( SIM_TIMER_INIT);

  if (globalData->timeValue >= stop) {
    if (sim_verbose >= LOG_SOLVER) {
      fprintf(stdout, "| info LOG_SOLVER | Simulation done!\n"); fflush(NULL);
    }
    globalData->terminal = 1;
    update_DAEsystem();

    if (sim_result)
      sim_result->emit();

    globalData->terminal = 0;
    return 0;
  }

  if (sim_verbose >= LOG_SOLVER) {
    fprintf(stdout, "| info LOG_SOLVER | Performed initial value calculation.\n");
    fprintf(stdout, "| info LOG_SOLVER | Start numerical solver from %g to %g\n",
            globalData->timeValue, stop); fflush(NULL);
  }
  FILE *fmt = NULL;
  uint32_t stepNo = 0;
  if (measure_time_flag) {
    const string filename = string(globalData->modelFilePrefix) + "_prof.data";
    fmt = fopen(filename.c_str(), "wb");
    if (!fmt) {
      fprintf(stderr, "Warning: Time measurements output file %s could not be opened: %s\n",
              filename.c_str(), strerror(errno)); fflush(NULL);
      fclose(fmt);
      fmt = NULL;
    }
  }

  try {
    while (globalData->timeValue < stop) {
      if (measure_time_flag) {
        for (int i = 0; i < globalData->nFunctions + globalData->nProfileBlocks; i++)
          rt_clear(i + SIM_TIMER_FIRST_FUNCTION);
        rt_clear(SIM_TIMER_STEP);
        rt_tick(SIM_TIMER_STEP);
      }

      /* Calculate new step size after an event */
      if (dideventstep == 1) {
        offset = globalData->timeValue - laststep;
        dideventstep = 0;
        if (offset + uround > step)
          offset = 0;
        if (sim_verbose >= LOG_SOLVER)
        {
          fprintf(stdout, "| info LOG_SOLVER | Offset value for the next step: %g\n",
                  offset); fflush(NULL);
        }
      } else {
        offset = 0;
      }

      if (flag != 6) {
        /*!!!!! not for DOPRI5 with stepsize control */
        globalData->current_stepsize = step - offset;

        if (globalData->timeValue + globalData->current_stepsize > stop) {
          globalData->current_stepsize = stop - globalData->timeValue;
        }
      }

      if (globalData->curSampleTimeIx < globalData->nSampleTimes) {
        sampleEvent_actived = checkForSampleEvent();
      }

      if (sim_verbose >= LOG_SOLVER) {
        fprintf(stdout, "| info LOG_SOLVER | Call Solver from %g to %g\n",
                globalData->timeValue, globalData->timeValue
                + globalData->current_stepsize); fflush(NULL);
      }
      /* do one integration step
       *
       * one step means:
       * determine all states by Integration-Method
       * update continuous part with
       * functionODE() and functionAlgebraics(); */

      communicateStatus("Running", (globalData->timeValue-start)/(stop-start));
      retValIntegrator = solver_main_step(flag, start, stop, reset,
                                          reinit_step, useInterpolation, step, dasslStatsTmp);

      functionAlgebraics();
      functionAliasEquations();
      function_storeDelayed();
      SaveZeroCrossings();

      if (reset)
        reset = false;

      /* Check for Events */
      if (measure_time_flag)
        rt_tick(SIM_TIMER_EVENT);

      if (CheckForNewEvent(&sampleEvent_actived)) {
        stateEvents++;
        reset = true;
        dideventstep = 1;
        /* due to an event overwrite old values */
        storeExtrapolationDataEvent();
      } else if (sampleEvent_actived) {
        EventHandle(1);
        sampleEvents++;
        reset = true;
        dideventstep = 1;
        sampleEvent_actived = 0;
        /* due to an event overwrite old values */
        storeExtrapolationDataEvent();
      } else {
        laststep = globalData->timeValue;
      }

      if (measure_time_flag)
        rt_accumulate(SIM_TIMER_EVENT);

      /******** Emit this time step ********/
      saveall();
      if (useInterpolation)
        interpolation_control(dideventstep, interpolationStep, step, stop);

      if (fmt) {
        int flag = 1;
        double tmpdbl;
        uint32_t tmpint;
        rt_tick(SIM_TIMER_OVERHEAD);
        rt_accumulate(SIM_TIMER_STEP);
        /* Disable time measurements if we have trouble writing to the file... */
        flag = flag && 1 == fwrite(&stepNo, sizeof(uint32_t), 1, fmt);
        stepNo++;
        flag = flag && 1 == fwrite(&globalData->timeValue, sizeof(double), 1,
            fmt);
        tmpdbl = rt_accumulated(SIM_TIMER_STEP);
        flag = flag && 1 == fwrite(&tmpdbl, sizeof(double), 1, fmt);
        for (int i = 0; i < globalData->nFunctions + globalData->nProfileBlocks; i++) {
          tmpint = rt_ncall(i + SIM_TIMER_FIRST_FUNCTION);
          flag = flag && 1 == fwrite(&tmpint, sizeof(uint32_t), 1, fmt);
        }
        for (int i = 0; i < globalData->nFunctions + globalData->nProfileBlocks; i++) {
          tmpdbl = rt_accumulated(i + SIM_TIMER_FIRST_FUNCTION);
          flag = flag && 1 == fwrite(&tmpdbl, sizeof(double), 1, fmt);
        }
        rt_accumulate(SIM_TIMER_OVERHEAD);
        if (!flag) {
          fprintf(stderr, "Warning: Disabled time measurements because the output file could not be generated: %s\n",
                  strerror(errno)); fflush(NULL);
          fclose(fmt);
          fmt = NULL;
        }
      }

      SaveZeroCrossings();
      if (!useInterpolation && sim_result)
        sim_result->emit();
      /********* end of Emit this time step *********/

      if (reset == true) {
        /* save dassl stats before reset */
        for (int i = 0; i < DASSLSTATS; i++)
          dasslStats[i] += dasslStatsTmp[i];
      }
      /* Check for termination of terminate() or assert() */
      if (terminationAssert || terminationTerminate || modelErrorCode) {
        terminationAssert = 0;
        terminationTerminate = 0;
        checkForAsserts();
        checkTermination();
        if (modelErrorCode)
          retValIntegrator = 1;
      }

      if (retValIntegrator) {
        throw TerminateSimulationException(globalData->timeValue,
              string("Error in Simulation. Solver exit with error.\n"));
      }

      if (sim_verbose >= LOG_SOLVER) {
        fprintf(stdout, "| info LOG_SOLVER |** Step to  %g Done!\n",
                globalData->timeValue); fflush(NULL);
      }

    }
    /* Last step with terminal()=true */
    if (globalData->timeValue >= stop) {
      globalData->terminal = 1;
      update_DAEsystem();
      if (sim_result)
        sim_result->emit();
      globalData->terminal = 0;
    }
  } catch (TerminateSimulationException &e) {
    globalData->terminal = 1;
    update_DAEsystem();
    globalData->terminal = 0;
    cout << e.getMessage() << endl;
    if (modelTermination) { /* terminated from assert, etc. */
      fprintf(stdout, "| model terminate | Simulation terminated at time %g\n",
              globalData->timeValue); fflush(NULL);
      if (fmt)
        fclose(fmt);
      return -1;
    }
  }

  communicateStatus("Finished", 1);

  if (sim_verbose >= LOG_STATS) {
    /* save dassl stats before print */
    for (int i = 0; i < DASSLSTATS; i++)
      dasslStats[i] += dasslStatsTmp[i];

    rt_accumulate(SIM_TIMER_TOTAL);
    fprintf(stdout, "| info LOG_STATS| ##### Statistics #####\n"); fflush(NULL);
    fprintf(stdout, "| info LOG_STATS| simulation time: %g\n", rt_accumulated(SIM_TIMER_TOTAL)); fflush(NULL);
    fprintf(stdout, "| info LOG_STATS| Events: %d\n", stateEvents + sampleEvents); fflush(NULL);
    fprintf(stdout, "| info LOG_STATS| State Events: %d\n", stateEvents); fflush(NULL);
    fprintf(stdout, "| info LOG_STATS| Sample Events: %d\n", sampleEvents); fflush(NULL);
    fprintf(stdout, "| info LOG_STATS| ##### Solver Statistics #####\n"); fflush(NULL);
    fprintf(stdout, "| info LOG_STATS| The number of steps taken: %d\n", dasslStats[0]); fflush(NULL);
    fprintf(stdout, "| info LOG_STATS| The number of calls to functionODE: %d\n", dasslStats[1]); fflush(NULL);
    fprintf(stdout, "| info LOG_STATS| The evaluations of Jacobian: %d\n", dasslStats[2]); fflush(NULL);
    fprintf(stdout, "| info LOG_STATS| The number of error test failures: %d\n", dasslStats[3]); fflush(NULL);
    fprintf(stdout, "| info LOG_STATS| The number of convergence test failures: %d\n", dasslStats[4]); fflush(NULL);
    if (flag == 6)
    {
        fprintf(stdout, "| info LOG_STATS| DOPRI5: total number of steps rejected: %d\n", reject); fflush(NULL);
    }
  }

  deinitializeEventData();
  if (fmt)
    fclose(fmt);

  return 0;
}

/***************************************		EULER_EXP     *********************************/
int
euler_ex_step(double* step, int(*f)()) {
  globalData->timeValue += *step;
  for (int i = 0; i < globalData->nStates; i++) {
    globalData->states[i] += globalData->statesDerivatives[i] * (*step);
  }
  f();
  return 0;
}

/***************************************		STEPSIZE	***********************************/
int
init_stepsize(int(*f)()) {
  double p = 4.0, d0norm = 0.0, d1norm = 0.0, d2norm = 0.0, h0 = 0.0, h1 = 0.0,
         d, backupTime;
  double* sc = new double[globalData->nStates];
  double* d0 = new double[globalData->nStates];
  double* d1 = new double[globalData->nStates];
  double* temp = new double[globalData->nStates];
  double* x0 = new double[globalData->nStates];
  double* y = new double[globalData->nStates];

  if (sim_verbose >= LOG_SOLVER)
  {
     fprintf(stdout, "Initializing stepsize...\n"); fflush(NULL);
  }

  if (abstol <= 1e-6) {
    abstol = 1e-5;
    reltol = abstol;
    fprintf(stdout, "| warning | DOPRI5: error tolerance too stringent *setting tolerance to 1e-5*\n"); fflush(NULL);
  }

  backupTime = globalData->timeValue;

  for (int i = 0; i < globalData->nStates; i++) {
    x0[i] = globalData->states[i]; /* initial values for solver (used as backup too) */
    y[i] = globalData->statesDerivatives[i]; /* initial values for solver (used as backup too) */
    /* if (sim_verbose >= LOG_SOLVER){ cout << "x0[" << i << "]: " << x0[i] << endl;  fflush(NULL); } for debugging */
  }

  for (int i = 0; i < globalData->nStates; i++) {
    sc[i] = abstol + fabs(globalData->states[i]) * reltol;
    d0[i] = globalData->states[i] / sc[i];
    d1[i] = globalData->statesDerivatives[i];
  }

  d0norm = euklidnorm(d0) / sqrt(globalData->nStates);
  d1norm = euklidnorm(d1) / sqrt(globalData->nStates);

  delete[] d0;
  delete[] d1;

  if (d0norm < 1e-5 || d1norm < 1e-5) {
    h0 = 1e-6;
  } else {
    h0 = 0.01 * d0norm / d1norm;
  }

  for (int i = 0; i < globalData->nStates; i++) {
    globalData->states[i] = x0[i] + h0 * y[i]; /* give new states */
  }
  globalData->timeValue = globalData->timeValue + h0; /* set time */
  f(); /* get new statesDerivatives */

  for (int i = 0; i < globalData->nStates; i++) {
    temp[i] = globalData->statesDerivatives[i] - y[i];
  }

  d2norm = (euklidnorm(temp) / sqrt(globalData->nStates)) / h0;

  d = max(d1norm, d2norm);

  if (d <= 1e-15) {
    h1 = max(1e-6, h0 * 1e-3);
  } else {
    h1 = pow((0.01 / d), (1.0 / (p + 1.0)));
  }

  globalData->current_stepsize = min(abstol * 100 * h0, abstol * h1);

  if (sim_verbose >= LOG_SOLVER)
  {
      fprintf(stdout, "stepsize initialized: step = %g\n",
            globalData->current_stepsize); fflush(NULL);
  }

  for (int i = 0; i < globalData->nStates; i++) {
    globalData->states[i] = x0[i]; /* reset states */
    globalData->statesDerivatives[i] = y[i]; /* reset statesDerivatives */
  }
  globalData->timeValue = backupTime; /* reset time */

  delete[] sc;
  delete[] temp;
  delete[] x0;
  delete[] y;

  return (0);
}

int
stepsize_control(double &start, double &stop, double &fixStep, int(*f)(),
                 bool &reinit_step, bool &useInterpolation) {

  double maxVal = 0, alpha, delta, TTOL, erg;
  double backupTime;
  int retVal;
  bool retry = false;

  backupTime = globalData->timeValue;

  TTOL = abstol * 0.6; /* tolerance * sf */

  if (reinit_step) {
    init_stepsize(functionODE);
    reinit_step = false;
  }

  double* x4 = new double[globalData->nStates];
  double* x5 = new double[globalData->nStates];
  double** k = work_states;

  do {
    retVal = dopri54(functionODE, x4, x5);

    for (int i = 0; i < globalData->nStates; i++) {
      for (int l = 0; l < dopri5_s; l++) {
        erg = fabs((dop_b5[l] - dop_b4[l]) * k[l][i]);
        if (erg > maxVal)
          maxVal = erg;
      }
    }

    delta = globalData->current_stepsize * maxVal; /* error estimate */
    alpha = pow((delta / TTOL), (1.0 / 5.0)); /* step ratio */

    if (sim_verbose >= LOG_SOLVER) {
      /*			for(int i=0;i < globalData->nStates;i++)
       *				cout << "x4[" << i << "]: " << x4[i] << endl;
       *
       *			for(int i=0;i < globalData->nStates;i++)
       *				cout << "x5[" << i << "]: " << x5[i] << endl; for debugging */
      fprintf(stdout, "delta: %g\n", delta);
      fprintf(stdout, "alpha: %g\n", alpha);
      fflush(NULL);
    }

    if (delta < abstol) {
      for (int i = 0; i < globalData->nStates; i++) {
            globalData->states[i] += globalData->current_stepsize * x4[i]; /* give new states */
      }
      f(); /* get new statesDerivatives */
      retry = false;
      globalData->current_stepsize = globalData->current_stepsize / max(alpha, 0.1);
    } else {
      reject = reject + 1;
      retry = true; /* do another step with new stepsize until step is valid */
      globalData->current_stepsize = globalData->current_stepsize / min(alpha, 10.0);

      if (sim_verbose >= LOG_SOLVER)
      {
        fprintf(stdout, "| info | DOPRI5: ***!! step rejected !!***\n"); fflush(NULL);
      }

      globalData->timeValue = backupTime; /* reset time */

      if ((reject > 10e+4) || (globalData->current_stepsize < 1e-10)) /* to avoid infinite loops */
      {
        fprintf(stdout, "| error | DOPRI5: Too many steps rejected (>10e+4) or desired stepsize too small (< 1e-10)!.\n"); fflush(NULL);
        delete[] x4;
        delete[] x5;

        return (1);
      }
    }

    /* do not advance past t_stop */
    if ((globalData->timeValue + globalData->current_stepsize) > stop) {
      globalData->current_stepsize = stop - globalData->timeValue;
      useInterpolation = false;
    }

    if (sim_verbose >= LOG_SOLVER)
    {
      fprintf(stdout, "| info | DOPRI5: stepsize on next step: %g\n",
              globalData->current_stepsize); fflush(NULL);
    }
  } while (retry);

  delete[] x4;
  delete[] x5;

  return (0);
}

/***************************************		RK4  		***********************************/
int
rungekutta_step(double* step, int(*f)()) {
  double* backupstates = work_states[rungekutta_s];
  double** k = work_states;
  double sum;

  /* We calculate k[0] before returning from this function.
   * We only want to calculate f() 4 times per call */
  for (int i = 0; i < globalData->nStates; i++) {
    k[0][i] = globalData->statesDerivatives[i];
    backupstates[i] = globalData->states[i];
  }

  for (int j = 1; j < rungekutta_s; j++) {
    globalData->timeValue = globalData->oldTime + rungekutta_c[j] * (*step);
    for (int i = 0; i < globalData->nStates; i++) {
      globalData->states[i] = backupstates[i] + (*step) * rungekutta_c[j] * k[j - 1][i];
    }
    f();
    for (int i = 0; i < globalData->nStates; i++) {
      k[j][i] = globalData->statesDerivatives[i];
    }
  }

  for (int i = 0; i < globalData->nStates; i++) {
    sum = 0;
    for (int j = 0; j < rungekutta_s; j++) {
      sum = sum + rungekutta_b[j] * k[j][i];
    }
    globalData->states[i] = backupstates[i] + (*step) * sum;
  }
  f();
  return 0;
}

/***************************************		DOPRI54		***********************************/
int
dopri54(int(*f)(), double* x4, double* x5) {
  double** k = work_states;
  double sum;
  int i, j, l;

  double* backupstats = new double[globalData->nStates];
  double* backupderivatives = new double[globalData->nStates];

  memcpy(backupstats, globalData->states, globalData->nStates * sizeof(double));
  memcpy(backupderivatives, globalData->statesDerivatives, globalData->nStates * sizeof(double));

  for (i = 1; i < dop5dense_s; i++) {
    for (j = 0; j < globalData->nStates; j++) {
      k[i][j] = 0;
    }
  }

  for (j = 0; j < globalData->nStates; j++) {
    k[0][j] = globalData->statesDerivatives[j];
  }

  /* calculation of extra f's used by dense output included per step */
  for (j = 1; j < dop5dense_s; j++) {
    /* set proper time to get derivatives */
    globalData->timeValue = globalData->oldTime + dop_c[j] * globalData->current_stepsize;
    for (i = 0; i < globalData->nStates; i++) {
      sum = 0;
      for (l = 0; l < dop5dense_s; l++) {
        sum = sum + dop_a[j][l] * k[l][i];
      }
      globalData->states[i] = backupstats[i] + globalData->current_stepsize * sum;
    }
    f();
    for (i = 0; i < globalData->nStates; i++) {
      k[j][i] = globalData->statesDerivatives[i];
    }
  }

  globalData->timeValue = globalData->oldTime + globalData->current_stepsize; /* next solver step */

  for (i = 0; i < globalData->nStates; i++) {
    sum = 0;
    for (l = 0; l < dopri5_s; l++) {
      sum = sum + dop_b5[l] * k[l][i];
    }
    x5[i] = sum;
    /* if(sim_verbose >= LOG_SOLVER){ cout << "dx5[" << i << "]: " << x5[i] << endl; fflush(NULL); }; for debugging */
  }

  for (i = 0; i < globalData->nStates; i++) {
    sum = 0;
    for (l = 0; l < dopri5_s; l++) {
      sum = sum + dop_b4[l] * k[l][i];
    }
    x4[i] = sum;
    /* if(sim_verbose >= LOG_SOLVER){ cout << "dx4[" << i << "]: " << x4[i] << endl; fflush(NULL); }; for debugging */
  }

  memcpy(globalData->states, backupstats, globalData->nStates * sizeof(double));
  memcpy(globalData->statesDerivatives, backupderivatives, globalData->nStates * sizeof(double));

  delete[] backupstats;
  delete[] backupderivatives;

  return 0;
}

/**********************************************************************************************
 * DASSL with synchronous treating of when equation
 *   - without integrated ZeroCrossing method.
 *   + ZeroCrossing are handled outside DASSL.
 *   + if no event occurs outside DASSL performs a warm-start
 **********************************************************************************************/
int
dasrt_step(double* step, double &start, double &stop, bool &trigger1,
           int* tmpStats) {
  double tout = 0;
  int i = 0;
  double *rpar = NULL;

  if (globalData->timeValue == start) {
    if (sim_verbose >= LOG_SOLVER) {
      fprintf(stdout, "| info LOG_SOLVER | **Initializing DASSL.\n"); fflush(NULL);
    }

    /* work arrays for DASSL */
    liw = 20 + globalData->nStates;
    lrw = 52 + (MAXORD + 4) * globalData->nStates + globalData->nStates
        * globalData->nStates + 3 * globalData->nZeroCrossing;
    rwork = new double[lrw];
    iwork = new fortran_integer[liw];
    jroot = new fortran_integer[globalData->nZeroCrossing];
    /* Used when calculating residual for its side effects. (alg. var calc) */
    dummy_delta = new double[globalData->nStates];
    rpar = new double;
    ipar = new fortran_integer[3];
    ipar[0] = sim_verbose;
    ipar[1] = LOG_JAC;
    ipar[2] = LOG_ENDJAC;

    for (i = 0; i < INFOLEN; i++)
      info[i] = 0;
    for (i = 0; i < liw; i++)
      iwork[i] = 0;
    for (i = 0; i < lrw; i++)
      rwork[i] = 0.0;
    /*********************************************************************
     *info[2] = 1;  //intermediate-output mode
     *********************************************************************
     *info[3] = 1;  //go not past TSTOP
     *rwork[0] = stop;  //TSTOP
     *********************************************************************
     *info[6] = 1;  //prohibit code to decide max. stepsize on its own
     *rwork[1] = *step;  //define max. stepsize
     *********************************************************************/

    if (jac_flag || num_jac_flag)
      info[4] = 1; /* use sub-routine JAC */
  }

  /* If an event is triggered and processed restart dassl. */
  if (trigger1) {
    if (sim_verbose >= LOG_EVENTS) {
      fprintf(stdout, "| info LOG_EVENTS | Event-management forced reset of DDASRT.\n"); fflush(NULL);
    }
    // obtain reset
    info[0] = 0;
  }

  /* Calculate time steps until TOUT is reached
   * (DASSL calculates beyond TOUT unless info[6] is set to 1!) */
  try {
    do {

      tout = globalData->timeValue + *step;
      /* Check that tout is not less than timeValue
       * else will dassl get in trouble. If that is the case we skip the current step. */

      if (globalData->timeValue - tout >= -1e-13) {
        if (sim_verbose >= LOG_SOLVER)
        {
          fprintf(stdout, "| info LOG_SOLVER | **Desired step to small try next one.\n"); fflush(NULL);
        }

        globalData->timeValue = tout;
        return 0;
      }

      if (sim_verbose >= LOG_SOLVER) {
        fprintf(stdout, "| info LOG_SOLVER | **Calling DDASRT from %g to %g .\n",
                globalData->timeValue, tout); fflush(NULL);
      }

      /* Save all statesDerivatives due to avoid this in functionODE_residual */
      memcpy(globalData->statesDerivativesBackup,
             globalData->statesDerivatives, globalData->nStates * sizeof(double));

      if (jac_flag) {
        DDASRT(functionODE_residual, &globalData->nStates,
               &globalData->timeValue, globalData->states,
               globalData->statesDerivativesBackup, &tout, info, &reltol, &abstol,
               &idid, rwork, &lrw, iwork, &liw, globalData->algebraics, ipar,
               Jacobian, dummy_zeroCrossing, &NG_var, jroot);
      } else if (num_jac_flag) {
        DDASRT(functionODE_residual, &globalData->nStates,
               &globalData->timeValue, globalData->states,
               globalData->statesDerivativesBackup, &tout, info, &reltol, &abstol,
               &idid, rwork, &lrw, iwork, &liw, globalData->algebraics, ipar,
               Jacobian_num, dummy_zeroCrossing, &NG_var, jroot);
      } else {
        DDASRT(functionODE_residual, &globalData->nStates,
               &globalData->timeValue, globalData->states,
               globalData->statesDerivativesBackup, &tout, info, &reltol, &abstol,
               &idid, rwork, &lrw, iwork, &liw, globalData->algebraics, ipar,
               dummy_Jacobian, dummy_zeroCrossing, &NG_var, jroot);
      }

      if (sim_verbose >= LOG_SOLVER) {
        fprintf(stdout, "| info LOG_SOLVER | value of idid: %i\n",
                idid); fflush(NULL);
        fprintf(stdout, "| info LOG_SOLVER | current time value: %0.4g\n",
                globalData->timeValue); fflush(NULL);
        fprintf(stdout, "| info LOG_SOLVER | current integration time value: %0.4g\n",
                rwork[3]); fflush(NULL);
        fprintf(stdout, "| info LOG_SOLVER | step size H to be attempted on next step: %0.4g\n",
                rwork[2]); fflush(NULL);
        fprintf(stdout, "| info LOG_SOLVER | stepsize used on last successful step: %0.4g\n",
                rwork[6]); fflush(NULL);
        fprintf(stdout, "| info LOG_SOLVER | number of steps taken so far: %i\n",
                iwork[10]); fflush(NULL);
        fprintf(stdout, "| info LOG_SOLVER | number of calls of functionODE() : %i\n",
                iwork[11]); fflush(NULL);
        fprintf(stdout, "| info LOG_SOLVER | number of calculation of Jacobian : %i\n",
                iwork[12]); fflush(NULL);
        fprintf(stdout, "| info LOG_SOLVER | total number of convergence test failures: %i\n",
                iwork[13]); fflush(NULL);
        fprintf(stdout, "| info LOG_SOLVER | total number of error test failures: %i\n",
                iwork[14]); fflush(NULL);
      }

      /* save dassl stats */
      for (i = 0; i < DASSLSTATS; i++) {
        assert(10 + i < liw);
        tmpStats[i] = iwork[10 + i];
      }

      if (idid < 0) {
        fflush( stderr);
        fflush( stdout);
        if (idid == -1) {
          if (sim_verbose >= LOG_SOLVER)
          {
            fprintf(stdout, "| info LOG_SOLVER | DDASRT will try again...\n"); fflush(NULL);
          }

          info[0] = 1; /* try again */
        }
        if (!continue_DASRT(&idid, &abstol, &reltol))
          throw TerminateSimulationException(globalData->timeValue);
      }

      functionODE();
    } while (idid == -1 && globalData->timeValue <= stop);
  } catch (TerminateSimulationException &e) {

    cout << e.getMessage() << endl;
    return 1;

  }

  if (tout > stop) {
    if (sim_verbose >= LOG_SOLVER)
    {
      fprintf(stdout, "| info LOG_SOLVER | DDASRT finished.\n"); fflush(NULL);
    }
  }
  return 0;
}

bool
continue_DASRT(fortran_integer* idid, double* atol, double *rtol) {
  static int atolZeroIterations = 0;
  bool retValue = true;

  switch (*idid) {
  case 1:
  case 2:
  case 3:
    /* 1-4 means success */
    break;
  case -1:
    fprintf(stderr, "| warning | DDASRT: A large amount of work has been expended.(About 500 steps). Trying to continue ...\n"); fflush(NULL);
    retValue = true; /* adrpo: try to continue */
    break;
  case -2:
    fprintf(stderr, "| error | DDASRT: The error tolerances are too stringent.\n");
    retValue = false;
    break;
  case -3:
    if (atolZeroIterations > 10) {
      fprintf(stderr, "| error | DDASRT: The local error test cannot be satisfied because you specified a zero component in ATOL and the corresponding computed solution component is zero. Thus, a pure relative error test is impossible for this component.\n"); fflush(NULL);
      retValue = false;
      atolZeroIterations++;
    } else {
      *atol = 1e-6;
      retValue = true;
    }
    break;
  case -6:
    fprintf(stderr, "| error | DDASRT: DDASSL had repeated error test failures on the last attempted step.\n"); fflush(NULL);
    retValue = false;
    break;
  case -7:
    fprintf(stderr, "| error | DDASRT: The corrector could not converge.\n"); fflush(NULL);
    retValue = false;
    break;
  case -8:
    fprintf(stderr, "| error | DDASRT: The matrix of partial derivatives is singular.\n"); fflush(NULL);
    retValue = false;
    break;
  case -9:
    fprintf(stderr, "| error | DDASRT: The corrector could not converge. There were repeated error test failures in this step.\n"); fflush(NULL);
    retValue = false;
    break;
  case -10:
    fprintf(stderr, "| error | DDASRT: The corrector could not converge because IRES was equal to minus one.\n"); fflush(NULL);
    retValue = false;
    break;
  case -11:
    fprintf(stderr, "| error | DDASRT: IRES equal to -2 was encountered and control is being returned to the calling program.\n"); fflush(NULL);
    retValue = false;
    break;
  case -12:
    fprintf(stderr, "| error | DDASRT: DDASSL failed to compute the initial YPRIME.\n"); fflush(NULL);
    retValue = false;
    break;
  case -33:
    fprintf(stderr, "| error | DDASRT: The code has encountered trouble from which it cannot recover.\n"); fflush(NULL);
    retValue = false;
    break;
  }
  return retValue;
}

/******************************* interpolation module ************************************************/
int
interpolation_control(const int &dideventstep, double &interpolationStep,
                      double &fixStep, double &stop) {

  if (sim_verbose >= LOG_SOLVER){
    fprintf(stdout, "| info | dense output: $$$$$\t interpolate data at %g\n", interpolationStep); fflush(NULL);
  }
  /* if (sim_verbose >= LOG_SOLVER) {
   * cout << "oldTime,Time,interpolate data at " << globalData->oldTime << ", "
   *     << globalData->timeValue << ", " << interpolationStep << endl; fflush(NULL);
  } for debugging */

  functionAliasEquations();

  if (dideventstep == 1) {
    /* Emit data after an event */
    sim_result->emit();
  }

  if (((interpolationStep > globalData->oldTime) && (interpolationStep < globalData->timeValue)) ||
      ((dideventstep == 1) && (interpolationStep < globalData->timeValue))) {
    double** k = work_states;
    double backupTime = globalData->timeValue;
    double backupTime_old = globalData->oldTime;
    double* backupstats = new double[globalData->nStates];
    double* backupderivatives = new double[globalData->nStates];
    double* backupstats_old = new double[globalData->nStates];
    double bstar[dop5dense_s];
    double numerator = 0, sigma, sh, sum;

    /* save states and derivatives as they're altered by linear interpolation method */
    for (int i = 0; i < globalData->nStates; i++) {
      backupstats[i] = globalData->states[i];
      backupderivatives[i] = globalData->statesDerivatives[i];
      backupstats_old[i] = globalData->states_old[i];
    }

    do {
      if (!(backupTime == backupTime_old)) /* don't interpolate during an event */
      {
        /* calculate dense output interpolation parameter sigma */
        sh = interpolationStep - globalData->timeValue;
        sigma = sh / globalData->current_stepsize;

        for (int i = 0; i < dop5dense_s; i++) {
          /* compute bstar vector components using Horner's scheme */
          numerator = dop_bst[i][4] +
                      sigma * (dop_bst[i][3] +
                      sigma * (dop_bst[i][2] +
                      sigma * (dop_bst[i][1] +
                      sigma * dop_bst[i][0])));
          bstar[i] = numerator / dop_bst[i][5];
        }

        for (int i = 0; i < globalData->nStates; i++) {
          sum = 0;
          for (int l = 0; l < dop5dense_s; l++) {
            sum = sum + bstar[l] * k[l][i];
          }
          globalData->states[i] = globalData->states[i] + sh * sum;
        }

        /* set global time value to interpolated time */
        globalData->timeValue = interpolationStep;

        /* update all dependent variables */
        functionODE();
        functionAlgebraics();
        functionAliasEquations();
        SaveZeroCrossings();

        /* Emit interpolated data at the current time step */
        sim_result->emit();
      }

      interpolationStep = interpolationStep + fixStep;

    } while ((interpolationStep <= stop + fixStep) && (interpolationStep < backupTime));

    /* update old data */
    globalData->oldTime = backupTime;

    /* reset data for next solver step */
    globalData->timeValue = backupTime;
    for (int i = 0; i < globalData->nStates; i++) {
      globalData->states[i] = backupstats[i];
      globalData->statesDerivatives[i] = backupderivatives[i];
    }

    delete[] backupstats;
    delete[] backupderivatives;
    delete[] backupstats_old;
  } else {
    globalData->oldTime = globalData->timeValue;
  }
  return 0;
}

int functionODE_residual(double *t, double *x, double *xd, double *delta,
                    fortran_integer *ires, double *rpar, fortran_integer *ipar)
{
  double timeBackup;
  double* statesBackup;
  int i;

  timeBackup = globalData->timeValue;
  statesBackup = globalData->states;

  globalData->timeValue = *t;
  globalData->states = x;
  functionODE();

  /* get the difference between the temp_xd(=localData->statesDerivatives)
     and xd(=statesDerivativesBackup) */
  for (i=0; i < globalData->nStates; i++) {
    delta[i] = globalData->statesDerivatives[i] - xd[i];
  }
  
  globalData->states = statesBackup;
  globalData->timeValue = timeBackup;

  return 0;
}