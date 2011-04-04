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

#include "simulation_init.h"
#include "simulation_runtime.h"
#include <math.h>

/*
 * This function calculates the residual value as the sum of squared residual equations.
 */

void leastSquare(long *nz, double *z, double *funcValue)
{
  int ind, indAct, indz;
  int startIndPar = 2*globalData->nStates+globalData->nAlgebraic+globalData->intVariables.nAlgebraic+globalData->boolVariables.nAlgebraic;
  for (ind=0, indAct=0, indz=0; ind<globalData->nStates; ind++)
    if (globalData->initFixed[indAct++]==0)
          globalData->states[ind] = z[indz++];
  // for real parameters 
  for (ind=0,indAct=startIndPar; ind<globalData->nParameters; ind++)
    if (globalData->initFixed[indAct++]==0)
      globalData->parameters[ind] = z[indz++];

  // for int parameters
  for (ind=0,indAct=startIndPar+globalData->nParameters; ind<globalData->intVariables.nParameters; ind++) {
    if (globalData->initFixed[indAct++]==0)
      globalData->intVariables.parameters[ind] = (modelica_integer)z[indz++];
  }

  // for bool parameters
  for (ind=0,indAct=startIndPar+globalData->nParameters+globalData->intVariables.nParameters; ind<globalData->boolVariables.nParameters; ind++) {
    if (globalData->initFixed[indAct++]==0)
      globalData->boolVariables.parameters[ind] = (modelica_boolean)z[indz++];
  }

  functionODE();
  functionAlgebraics();

/*  for (ind=0,indy=0,indAct=2*globalData->nStates; ind<globalData->nAlgebraic; ind++)
    if (globalData->initFixed[indAct++]==1)
      globalData->algebraics [ind] = static_y[indy++];

      Comment from Bernhard: Even though algebraic variables are "fixed", they are calculated from
      the states, so they should be allowed to change when states vary,
      and NOT be replaced by their initial values as above.
*/
  initial_residual();

  for (ind=0, *funcValue=0; ind<globalData->nInitialResiduals; ind++)
    *funcValue += globalData->initialResiduals[ind]*globalData->initialResiduals[ind];

  if (sim_verbose >= LOG_INIT) {
    cout << "initial residual: " << *funcValue << endl;
  }
}

/** function reportResidualValue
 **
 ** Returns -1 if residual is non-zero and prints appropriate error message.
 **/

int reportResidualValue(double funcValue)
{
  int i;
  if (funcValue > 1e-5) {
    std::cerr << "Error in initialization. System of initial equations are not consistent." << std::endl;
    std::cerr << "(Least Square function value is " << funcValue << ")" << std::endl;
    for (i=0; i<globalData->nInitialResiduals; i++) {
      if (fabs(globalData->initialResiduals[i]) > 1e-6) {
        cout << "residual[" << i << "] = " << globalData->initialResiduals[i] << endl;
      }
    }
    return 0 /*-1*/;
  }
  return 0;
}

/** function: newuoa_initialization
 **
 ** This function performs initialization using the newuoa function, which is
 ** a trust region method that forms quadratic models by interpolation.
 **/

int newuoa_initialization(long& nz,double *z)
{
  long IPRINT = sim_verbose >= LOG_INIT? 2 : 0;
  long MAXFUN=50000;
  double RHOEND=1.0e-6;
  double RHOBEG=10; // This should be about one tenth of the greatest
        // expected value of a variable. Perhaps the nominal
        // value can be used for this.
  long NPT = 2*nz+1;
  double *W = new double[(NPT+13)*(NPT+nz)+3*nz*(nz+3)/2];
  NEWUOA(&nz,&NPT,z,&RHOBEG,&RHOEND,&IPRINT,&MAXFUN,W,leastSquare);

  // Calculate the residual to verify that equations are consistent.
  double funcValue;
  leastSquare(&nz,z,&funcValue);


  delete [] W;
  return reportResidualValue(funcValue);
}

/** function: simplex_initialization.
 **
 ** This function performs initialization by using the simplex algorithm.
 ** This does not require a jacobian for the residuals.
 **/

int simplex_initialization(long& nz,double *z)
{
  int ind;
  double funcValue;
  double *STEP=(double*) malloc(nz*sizeof(double));
  double *VAR=(double*) malloc(nz*sizeof(double));

  /* Start with stepping .5 in each direction. */
  for (ind=0;ind<nz;ind++)
  {
    STEP[ind] = 0.5;
    VAR[ind]  = 0.0;
  }

   double STOPCR,SIMP;
   long IPRINT, NLOOP,IQUAD,IFAULT,MAXF;
//C  Set max. no. of function evaluations = 5000, print every 100.

      MAXF = 20 * nz;
      IPRINT = sim_verbose >= LOG_INIT ? 100 : -1;

//C  Set value for stopping criterion.   Stopping occurs when the
//C  standard deviation of the values of the objective function at
//C  the points of the current simplex < stopcr.

      STOPCR = 1.e-3;
      NLOOP = 2*MAXF;//2*nz;

//C  Fit a quadratic surface to be sure a minimum has been found.

      IQUAD = 0;

//C  As function value is being evaluated in DOUBLE PRECISION, it
//C  should be accurate to about 15 decimals.   If we set simp = 1.d-6,
//C  we should get about 9 dec. digits accuracy in fitting the surface.

      SIMP = 1.e-12;
//C  Now call NELMEAD to do the work.
  
  leastSquare(&nz,z,&funcValue);

  if ( fabs(funcValue) != 0){
      NELMEAD(z,STEP,&nz,&funcValue,&MAXF,&IPRINT,&STOPCR,
           &NLOOP,&IQUAD,&SIMP,VAR,leastSquare,&IFAULT);
  }else{
      if (sim_verbose >= LOG_INIT){
          printf("Result of leastSquare method = %g. The initial guess fits to the system\n",funcValue);
      }
  }

  if (IFAULT == 1) {
    leastSquare(&nz,z,&funcValue);
	if (funcValue > SIMP) {
      printf("Error in initialization. Solver iterated %d times without finding a solution\n",(int)MAXF);
	  return -1; 
	}
  } else if(IFAULT == 2 ) {
    printf("Error in initialization. Inconsistent initial conditions.\n");
    return -1;
  } else if (IFAULT == 3) {
    printf("Error in initialization. Number of initial values to calculate < 1\n");
    return -1;
  } else if (IFAULT == 4) {
    printf("Error in initialization. Internal error, NLOOP < 1.\n");
    return -1;
  }
  return reportResidualValue(funcValue);
}

/* function: initialize
 *
 * Perform initialization of the problem. It reads the global variable
 * globalData->initFixed to find out which variables are fixed.
 * It uses the generated function initial_residual, which calcualtes the
 * residual of all equations (both continuous time eqns and initial eqns).
 */

int initialize(const std::string*method)
{
  long nz;
  int ind, indAct, indz;
  std::string init_method;

  if (method == NULL) {
   // init_method = std::string("newuoa");
    init_method = std::string("simplex");
  } else {
    init_method = *method;
  }

  for (ind=0, nz=0; ind<globalData->nStates; ind++){
    if (globalData->initFixed[ind]==0){
        if (sim_verbose >= LOG_INIT)
            printf("Variable %s is unfixed.\n",globalData->statesNames[ind].name);

        nz++;
    }

  }

  int startIndPar = 2*globalData->nStates+globalData->nAlgebraic+globalData->intVariables.nAlgebraic+globalData->boolVariables.nAlgebraic;
  int endIndPar = startIndPar+globalData->nParameters+globalData->intVariables.nParameters+globalData->boolVariables.nParameters;
  for (ind=startIndPar;ind<endIndPar; ind++){
    if (globalData->initFixed[ind]==0){
        if (sim_verbose >= LOG_INIT)
          printf("Variable %s is unfixed.\n",globalData->statesNames[ind].name);

        nz++;
    }
  }

  if (sim_verbose >= LOG_INIT) {
    cout << "Initialization by method: " << init_method << endl;
    cout << "fixed attribute for states:" << endl;
    for(int i=0;i<globalData->nStates; i++) {
      cout << globalData->statesNames[i].name << "(fixed=" << (globalData->initFixed[i]?"true":"false") << ")"
      << endl;
    }
    cout << "number of non-fixed variables: " << nz << endl;
  }

  // No initial values to calculate.
  if (nz ==  0) {
    if (sim_verbose >= LOG_INIT) {
      cout << "No initial values to calculate" << endl;
    }
    return 0;
  }

  double *z= new double[nz];
  if(z == NULL) {return -1;}
  /* Fill z with the non-fixed variables from x and p*/
  for (ind=0, indAct=0, indz=0; ind<globalData->nStates; ind++){
    if (globalData->initFixed[indAct++]==0)
      z[indz++] = globalData->states[ind];
  }
  // for real parameters
  for (ind=0,indAct=startIndPar; ind<globalData->nParameters; ind++) {
    if (globalData->initFixed[indAct++]==0)
      z[indz++] =  globalData->parameters[ind];
  }

  // for int parameters
  for (ind=0,indAct=startIndPar+globalData->nParameters; ind<globalData->intVariables.nParameters; ind++) {
    if (globalData->initFixed[indAct++]==0)
      z[indz++] =  globalData->intVariables.parameters[ind];
  }

  // for bool parameters
  for (ind=0,indAct=startIndPar+globalData->nParameters+globalData->intVariables.nParameters; ind<globalData->boolVariables.nParameters; ind++) {
    if (globalData->initFixed[indAct++]==0)
      z[indz++] =  globalData->boolVariables.parameters[ind];
  }

  int retVal=0;
  if (init_method == std::string("simplex")) {
    retVal = simplex_initialization(nz,z);
  } else if (init_method == std::string("newuoa")) { // Better name ?
    retVal = newuoa_initialization(nz,z);
  } else {
    std::cerr << "unrecognized option -im " << init_method << std::endl;
    std::cerr << "current options are: simplex or newuoa" << std::endl;
    retVal= -1;
  }
  delete [] z;
  return retVal;
}

