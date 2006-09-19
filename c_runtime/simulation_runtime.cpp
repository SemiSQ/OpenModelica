/*
    Copyright PELAB, Linkoping University

    This file is part of Open Source Modelica (OSM).

    OSM is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    OSM is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with OpenModelica; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/

//#include <iostream>
#include <string>
#include <limits>
#include <list>
#include <math.h>
#include "simulation_runtime.h"
#include "options.h"

using namespace std;

static long current_pos;
static double* data;

static list<long> EventQueue;

long numpoints; // the number of points allocated for in data array
long actual_points=0; // the number of actual points saved
//double t;

int sim_verbose;

// vectors with saved values used by pre(v)
double* h_saved;
double* x_saved;
double* xd_saved;
double* y_saved;

double* gout;
long* zeroCrossingEnabled;


// this is the globalData that is used in all the functions
DATA *globalData = 0;



#define MAXORD 5

// dummy Jacobian
int dummyJacobianDASSL(double *t, double *y, double *yprime, double *pd, long *cj, double *rpar, long* ipar){
  return 0;
  //provides a dummy Jacobian to be used with DASSL
}


inline void dumpresult(double t, double y, long idid, double* rwork, long* iwork)
{
  int i;
  cout << t << "\t" << y << "\t" << idid;
  for (i=0;i<20; i++)
    cout << "\t" << iwork[i];
  for (i=0;i<20; i++)
    cout << "\t" << rwork[i];
  cout << endl;
}

// relation functions used in zero crossing detection
double Less(double a, double b) 
{
    return a-b;
}

double LessEq(double a, double b) 
{
    return a-b;
}

double Greater(double a, double b) 
{
    return b-a;
}

double GreaterEq(double a, double b) 
{
    return b-a;
}

double Sample(double t, double start ,double interval)
{
  double pipi = atan(1.0)*8.0;
  if (t<(start-interval*.25)) return -1.0;
  return sin(pipi*(t-start)/interval);
}

double sample(double start ,double interval)
{
  //  double sloop = 4.0/interval;
  int count = int((globalData->timeValue - start) / interval);
  if (globalData->timeValue < (start-interval*0.25)) return 0;
  if (( globalData->timeValue-start-count*interval) < 0) return 0;
  if (( globalData->timeValue-start-count*interval) > interval*0.5) return 0;
  return 1;
}

static int maxpoints;

inline double * initialize_simdata(long numpoints,long nx, long ny)
{
  maxpoints = numpoints;
  
  double *data = new double[numpoints*(nx*2+ny+1)];
  if (!data) {
    cerr << "Error allocating data of size " << numpoints *(nx*2+ny)
	      << endl;
    exit(-1);
  }
  current_pos = 0;
  return data;
}

inline double newTime(double t, double step)
{
  return (floor( (t+1e-10) / step) + 1.0)*step;
}

inline void calcEnabledZeroCrossings()
{
  int i;
  for (i=0;i<globalData->nZeroCrossing;i++) {
    zeroCrossingEnabled[i] = 1;
  }
  function_zeroCrossing(&globalData->nStates,&globalData->timeValue,
                        globalData->states,&globalData->nZeroCrossing,gout,0,0);
  for (i=0;i<globalData->nZeroCrossing;i++) {
    if (gout[i] > 0)
      zeroCrossingEnabled[i] = 1;
    else if (gout[i] < 0)
      zeroCrossingEnabled[i] = -1;
    else
      zeroCrossingEnabled[i] = 0;
 // cout << "e[" << i << "]=" << zeroCrossingEnabled[i] << " gout[" << i << "]="<< gout[i] 
   //  << " init =" << globalData->init << endl;
  }
}

int emit()
{
  if (actual_points < maxpoints) {
    add_result(data,&actual_points);
    return 0;
  }
  else {
    cout << "Too many points: " << actual_points << " max points: " << maxpoints << endl;
    return -1;
  }
}

int euler_main(int, char **);
int dassl_main(int, char **);

int main(int argc, char**argv) 
{
   int retVal=-1;
  globalData = initializeDataStruc(ALL);
  if( !globalData ){
      std::cerr << "Error: Could not initialize the global data structure file" << std::endl;
  }
  //this sets the static variable that is in the file with the generated-model functions
  setLocalData(globalData);
  if(globalData->nStates == 0 && globalData->nAlgebraic == 0)
    {
      std::cerr << "No variables in the model." << std::endl;
      return 1;
    }
  /* verbose flag is set : -v */
  sim_verbose = (int)flagSet("v",argc,argv);
  
  /* the main method identifies which solver to use and then calls 
     respecive solver main function*/
  if (!getFlagValue("m",argc,argv)) {
    retVal= dassl_main(argc,argv);
  } else  if (*getFlagValue("m",argc,argv) == std::string("euler")) {
    retVal= euler_main(argc,argv);
  }
  else if (*getFlagValue("m",argc,argv) == std::string("dassl")) {
    retVal= dassl_main(argc,argv);
  } else {
    cout << "Unrecognized solver, using dassl." << endl;
    retVal = dassl_main(argc,argv);    
  }
  deInitializeDataStruc(globalData,ALL);
  return retVal;	
}


/* The main function for the explicit euler solver */

int euler_main(int argc,char** argv) {
  double start = 0.0; //default value
  double stop = 5;
  double step = 0.05;
  double sim_time;

  if (argc == 2 && flagSet("?",argc,argv)) {
    cout << "usage: " << argv[0]  << " <-f initfile> <-r result file> -m solver:{dassl, euler}" << endl;
    exit(0);
  }
  
  read_input(argc,argv,
             globalData->states,
             globalData->statesDerivatives,
             globalData->algebraics,
             globalData->parameters,
             globalData->nStates,
             globalData->nAlgebraic,
             globalData->nParameters,
             &start,&stop,&step);            
  
  long numpoints = long((stop-start)/step)+2;
  
  // allocate data for storing results.
  data =  initialize_simdata(numpoints,globalData->nStates,globalData->nAlgebraic);
  
  if (sim_verbose) { cout << "Allocated simulation data storage" << endl; }
  
  // Calculate initial values from (fixed) start attributes 
  globalData->init=1;
  initial_function();
  globalData->init=0; 
  
  if (sim_verbose)  { 
  	cout << "Performed initial value calutation." << endl; 
  	cout << "Starting numerical solver at time "<< start << endl;
  }
  	
  int npts_per_result=int((stop-start)/(step*(numpoints-2)));
  long actual_points =0 ; // the number of actual points saved
  int pt=0;
  for(sim_time=start; sim_time <= stop; sim_time+=step,pt++) {

    //euler(x,xd,y,p,/*data,*/nx,ny,np,&sim_time,&step,functionODE);
    euler(globalData,&step,functionODE);


    /* Calculate the output variables */
    functionDAE_output();

    if (pt % npts_per_result == 0 || sim_time+step > stop) { // store result
      add_result(data,&actual_points);
    }
  } 


  string * result_file =(string*)getFlagValue("r",argc,argv);
  const char * result_file_cstr;
  if (!result_file) {
    result_file_cstr = string(string(globalData->modelName)+string("_res.plt")).c_str();
  } else {
    result_file_cstr = result_file->c_str();
  }
  store_result(result_file_cstr,data,actual_points);

  return 0;
}


void euler (DATA * data,
             double* step,
	     int (*f)() // time
            )
{
  setLocalData(data);
  f(); // calculate equations
  for(int i=0; i < data->nStates; i++) {
    data->states[i]=data->states[i]+data->statesDerivatives[i]*(*step); // Based on that, calculate state variables.
  }
}

/* This function calculates the residual value as the sum of squared residual equations.
 */

void leastSquare(long *nz, double *z, double *funcValue)
{
  int ind, indAct, indz, indy;
  for (ind=0, indAct=0, indz=0; ind<globalData->nStates; ind++)
  	if (globalData->initFixed[indAct++]==0)
          globalData->states[ind] = z[indz++];

  for (ind=0,indAct=2*globalData->nStates+globalData->nAlgebraic; ind<globalData->nParameters; ind++)
    if (globalData->initFixed[indAct++]==0)
      globalData->parameters[ind] = z[indz++];

  functionODE();
  functionDAE_output();

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
    
  if (sim_verbose) {
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
  if (funcValue > 1e-3) {
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
    STEP[ind]=.5;
    
   double STOPCR,SIMP;
   long IPRINT, NLOOP,IQUAD,IFAULT,MAXF;
//C  Set max. no. of function evaluations = 5000, print every 100.
 
      MAXF = 50000;
      IPRINT = sim_verbose? 100 : -1;
 
//C  Set value for stopping criterion.   Stopping occurs when the
//C  standard deviation of the values of the objective function at
//C  the points of the current simplex < stopcr.
 
      STOPCR = 1.e-3;
      NLOOP = 6000;//2*nz;
 
//C  Fit a quadratic surface to be sure a minimum has been found.
 
      IQUAD = 0;
 
//C  As function value is being evaluated in DOUBLE PRECISION, it
//C  should be accurate to about 15 decimals.   If we set simp = 1.d-6,
//C  we should get about 9 dec. digits accuracy in fitting the surface.
 
      SIMP = 1.e-6;
//C  Now call NELMEAD to do the work.
  NELMEAD(z,STEP,&nz,&funcValue,&MAXF,&IPRINT,&STOPCR,
           &NLOOP,&IQUAD,&SIMP,VAR,leastSquare,&IFAULT);
  if (IFAULT == 1) { 
    printf("Error in initialization. Solver iterated %d times without finding a solution\n",(int)MAXF);
    return -1;
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

/** function: newuoa_initialization
 ** 
 ** This function performs initialization using the newuoa function, which is 
 ** a trust region method that forms quadratic models by interpolation.
 **/

int newuoa_initialization(long& nz,double *z)
{
  long IPRINT = sim_verbose? 2 : 0;
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
  int ind, indAct, indz, indy;
  std::string init_method;

  if (method == NULL) { 
    init_method = std::string("newuoa");
  } else {
    init_method = *method;
  }

  for (ind=0, nz=0; ind<globalData->nStates; ind++){
    if (globalData->initFixed[ind]==0)
      nz++;
  }
  for (ind=2*globalData->nStates+globalData->nAlgebraic; 
       ind<2*globalData->nStates+globalData->nAlgebraic+globalData->nParameters; ind++){
    if (globalData->initFixed[ind]==0)
      nz++;
  }
	
	if (sim_verbose) {
		cout << "fixed attribute for states:" << endl;
		for(int i=0;i<globalData->nStates; i++) {
			cout <<	getName(&globalData->states[i]) << "(fixed=" << (globalData->initFixed[i]?"true":"false") << ")"
			<< endl; 
		}
	}

  // No initial values to calculate.
  if (nz ==  0) {
  	if (sim_verbose) {
  		cout << "No initial values to calculate" << endl;
  	}
    return 0;
  } 

  double *z= new double[nz];
  if(z == NULL) {return -1;}
  /* Fill z with the non-fixed variables from x, xd, y and p*/
  for (ind=0, indAct=0, indz=0; ind<globalData->nStates; ind++)
    {
      if (globalData->initFixed[indAct++]==0)
	{
	  z[indz++] = globalData->states[ind];
	}
  }
  
  if (init_method == std::string("simplex")) {
    return simplex_initialization(nz,z);
  } else if (init_method == std::string("newuoa")) { // Better name ?
    return newuoa_initialization(nz,z);
  } else {
    std::cerr << "unrecognized option -im " << init_method << std::endl;
    std::cerr << "current options are: simplex or newuoa" << std::endl;
    return -1;
  }

  return 0;
}
/* DASSRT can not handle events at exaclty the start time.
 * For instance der(x)=1, b = x>0 simulated from 0 .. x will miss the event.
 * The zeroCrossingEnabled vector is used to prevent DASSRT from checking the event above since it occur
 * at start time for the solver.
 * 
 * This function checks such initial events and calls the event handling for this. The function is called after the first 
 * step is taken by DASSRT (a small tiny step just to check these events)
 * */
void checkForInitialZeroCrossings(long*jroot)
{
	int i;
	if (sim_verbose) {
		cout << "checkForIntialZeroCrossings" << endl;
	}
	// enable only those that were disabled at init time.
	for (i=0; i<globalData->nZeroCrossing; i++) {
		if (zeroCrossingEnabled[i]==0) {
			zeroCrossingEnabled[i]=1;
		} else {
			zeroCrossingEnabled[i]=0;
		}
	}
	function_zeroCrossing(&globalData->nStates,&globalData->timeValue,
                        globalData->states,&globalData->nZeroCrossing,gout,0,0);
		
	for(i=0;i<globalData->nZeroCrossing;i++) {
    if (zeroCrossingEnabled[i] && gout[i]) {
      handleZeroCrossing(i);
      function_updateDependents();
      functionDAE_output();
    }
  }
	emit();
    CheckForNewEvents(&globalData->timeValue);
    StartEventIteration(&globalData->timeValue);

    saveall();		
    calcEnabledZeroCrossings();
    if (sim_verbose) {
    	cout << "checkForIntialZeroCrossings done." << endl;
    }
}

/* The main function for the dassl solver*/
int dassl_main( int argc, char**argv)
{
  int status;
  double start = 0.0; //default value
  double stop = 5;
  double step = 0.05;
  
  long info[15];
  status = 0;
  double tout;
  double rtol = 1.0e-5;
  double atol = 1.0e-5;
  long idid = 0;
  const std::string *init_method = getFlagValue("im",argc,argv);

  //double rpar = 0.0;
  long ipar = 0;
  int i;


  long liw = 20+globalData->nStates;
  long lrw = 50+(MAXORD+4)*globalData->nStates+
    globalData->nStates*globalData->nStates+3*globalData->nZeroCrossing;

  long *iwork = new long[liw];
  double *rwork = new double[lrw];
  long *jroot = new long[globalData->nZeroCrossing];
  double *dummy_delta = new double[globalData->nStates];

  for(i=0; i<15; i++) 
    info[i] = 0;
  for(i=0; i<liw; i++) 
    iwork[i] = 0;
  for(i=0; i<lrw; i++) 
    rwork[i] = 0.0;
  for(i=0; i<globalData->nHelpVars; i++)
    globalData->helpVars[i] = 0;
  
  
  if (argc == 2 && flagSet("?",argc,argv)) {
    cout << "usage: " << argv[0]  << " <-f initfile> <-r result file> -m solver:{dassl, euler}" << endl;
    exit(0);
  }

  //read_input(argc,argv,x,xd,y,p,nx,ny,np,&start,&stop,&step);
  read_input(argc,argv,
             globalData->states,
             globalData->statesDerivatives,
             globalData->algebraics,
             globalData->parameters,
             globalData->nStates,
             globalData->nAlgebraic,
             globalData->nParameters,
             &start,&stop,&step);

  // Set starttime for simulation.
  globalData->timeValue=start;	

  numpoints = long((stop-start)/step)+2;
 
  // load default initial values.
  gout = new double[globalData->nZeroCrossing];
  h_saved = new double[globalData->nHelpVars];  
  x_saved = new double[globalData->nStates];
  xd_saved = new double[globalData->nStates];
  y_saved = new double[globalData->nAlgebraic];
  if(!y_saved || !gout || !h_saved || !x_saved || !xd_saved ){
    std::cerr << "Could not allocate memory" << std::endl;
    return -1;
  }

  zeroCrossingEnabled = new long[globalData->nZeroCrossing];
  data =  initialize_simdata(5*numpoints,globalData->nStates,globalData->nAlgebraic);
 
	 if (sim_verbose) { cout << "Allocated simulation data storage" << endl; }	
	 
	  if(bound_parameters()) {
	    printf("Error calculating bound parameters\n");
	    return -1;
	  }
		if (sim_verbose) { cout << "Calculated bound parameters" << endl; }		
  // Calculate initial values from (fixed) start attributes and intial equation
  // sections
  globalData->init=1;
  initial_function(); // calculates e.g. start values depending on e.g parameters.
  
  if (initialize(init_method)) {
    printf("Error in initialization. Storing results and exiting.\n");
    goto exit;
  }
   if (sim_verbose)  { 
  	cout << "Starting numerical solver at time "<< start << endl;
  }
  
  // Calculate initial derivatives
  if(functionODE()) { 
    printf("Error calculating initial derivatives\n");
    goto exit;
  }
  // Calculate initial output values 
  if(functionDAE_output()) {
    printf("Error calculating initial derivatives\n");
    goto exit;
  }
  tout = globalData->timeValue+1e-6; // take tiny step.

  //saveall();
 
  function_updateDependents();

  if (sim_verbose) { cout << "Checking events at initialization (at time "<< globalData->timeValue << ")." << endl; }

  // Need to check for events at init=1 since e.g. initial() generate event at initialization.
  //calcEnabledZeroCrossings();  
  CheckForInitialEvents(&globalData->timeValue);
  StartEventIteration(&globalData->timeValue);

  saveall();


  if(emit()) { printf("Error, not enough space to save data"); return -1; }
  calcEnabledZeroCrossings(); 
    globalData->init = 0; 
  if (sim_verbose) { cout << "calling DDASRT from "<< globalData->timeValue << " to "<<
  	tout << endl; }
  	// Take an initial tiny step and then check for events at startTime
  	// Such events will have zeroCrossingEnable[i] == 0.
  DDASRT(functionDAE_res, &globalData->nStates,   &globalData->timeValue, globalData->states, 
         globalData->statesDerivatives, &tout, 
         info,&rtol, &atol, 
         &idid,rwork,&lrw, iwork, &liw, globalData->algebraics, 
         &ipar, dummyJacobianDASSL, function_zeroCrossing,
         &globalData->nZeroCrossing, jroot);
  checkForInitialZeroCrossings(jroot);
  info[0] = 1;

  functionDAE_res(&globalData->timeValue,globalData->states,globalData->statesDerivatives,
                  dummy_delta,0,0,0); // Since residual function calculates 
					      // alg vars too.
  functionDAE_output();

  tout += step;
  while(globalData->timeValue<stop && idid>0) {
    // TODO: check here if time event has been reached.

    while (idid == 4) {
    	if (sim_verbose) { 
    		cout << "found event at time " << globalData->timeValue << endl;
    	}
      if (emit()) {printf("Too many points\n");
	idid = -99; break;}

	
      saveall();
    // Make a tiny step so we are sure that crossings have really occured.
      info[0]=1;
      tout=globalData->timeValue+1.0e-6;
      {
	long *tmp_jroot = new long[globalData->nZeroCrossing];
	int i;
	for (i=0;i<globalData->nZeroCrossing;i++) {
	  tmp_jroot[i]=jroot[i];
	}
	if (sim_verbose) { cout << "Taking tiny step to time " << tout << " to pass time at event " << globalData->timeValue << endl;
	}
	DDASRT(functionDAE_res, &globalData->nStates,   
               &globalData->timeValue, globalData->states, globalData->statesDerivatives, &tout, 
               info,&rtol, &atol, 
	       &idid,rwork,&lrw, iwork, &liw, globalData->algebraics, &ipar, dummyJacobianDASSL, 
	       function_zeroCrossing, &globalData->nZeroCrossing, jroot);
	for (i=0;i<globalData->nZeroCrossing;i++) {
	  jroot[i]=tmp_jroot[i];
	}
        delete[] tmp_jroot;
      } // end tiny step
      
      if (sim_verbose) { cout << "Checking events at time " << globalData->timeValue << endl; }
      calcEnabledZeroCrossings();
      StateEventHandler(jroot, &globalData->timeValue);
      CheckForNewEvents(&globalData->timeValue);
      StartEventIteration(&globalData->timeValue);
      if (sim_verbose) {
      	cout << "Done checking events at time " << globalData->timeValue << endl; 
      }
      saveall();

      // Restart simulation
      info[0] = 0;
      if (tout-globalData->timeValue < atol) tout = newTime(globalData->timeValue,step);
      calcEnabledZeroCrossings();
      DDASRT(functionDAE_res, 
             &globalData->nStates,   &globalData->timeValue, 
             globalData->states, globalData->statesDerivatives, &tout, 
             info,&rtol, &atol, 
	     &idid,rwork,&lrw, iwork, &liw, globalData->algebraics, 
             &ipar, dummyJacobianDASSL, 
	     function_zeroCrossing, &globalData->nZeroCrossing, jroot);

      //functionDAE_res(&t,x,xd,dummy_delta,0,0,0); // Since residual function calculates 
    
      functionDAE_res(&globalData->timeValue,globalData->states,
                      globalData->statesDerivatives,
                      dummy_delta,0,0,0); // Since residual function calculates 
					      // alg vars too.
      functionDAE_output();

      info[0] = 1;
    }
  
    if(emit()) {
      printf("Error, could not save data. Not enought space.\n"); 
    }
    
    saveall();
    tout = newTime(globalData->timeValue,step); // TODO: check time events here. Maybe dassl should not be allowed to simulate past the scheduled time event.
    calcEnabledZeroCrossings();
    DDASRT(functionDAE_res, 
           &globalData->nStates, &globalData->timeValue, 
           globalData->states, globalData->statesDerivatives, &tout, 
           info,&rtol, &atol, 
           &idid,rwork,&lrw, iwork, &liw, globalData->algebraics, 
           &ipar, dummyJacobianDASSL, 
           function_zeroCrossing, &globalData->nZeroCrossing, jroot);
    functionDAE_res(&globalData->timeValue,globalData->states,globalData->statesDerivatives,dummy_delta,0,0,0); // Since residual function calculates 
					      // alg vars too.
    functionDAE_output();  // descrete variables should probably be seperated so that the can be emited before and after the event.    
  } // end while

  	if (sim_verbose) { cout << "Simulation stoped at time " << globalData->timeValue << endl; }		


 exit:
  if(emit()) {
      printf("Error, could not save data. Not enought space.\n"); 
  }
  if (idid < 0 ) {
    cerr << "Error, simulation stopped at time: " << globalData->timeValue << endl;
    cerr << "Result written to file." << endl;
	status = 1;
  }

  delete [] h_saved;
  delete [] x_saved;
  delete [] xd_saved;
  delete [] y_saved;
  delete [] gout;
  delete [] zeroCrossingEnabled;

  string * result_file =(string*)getFlagValue("r",argc,argv);
  const char * result_file_cstr;
  if (!result_file) {
    result_file_cstr = string(string(globalData->modelName)+string("_res.plt")).c_str();
  } else {
    result_file_cstr = result_file->c_str();
  }
  store_result(result_file_cstr,data,actual_points);

  return status;
}


void saveall()
{
  int i;
  for(i=0;i<globalData->nStates; i++) {
    x_saved[i] = globalData->states[i];
    xd_saved[i] = globalData->statesDerivatives[i];
  }
 for(i=0;i<globalData->nAlgebraic; i++) {
    y_saved[i] = globalData->algebraics[i];
  }
  for(i=0;i<globalData->nHelpVars; i++) {
    h_saved[i] = globalData->helpVars[i];
  }
}




/* save(v) saves the previous value of a discrete variable v, which can be accessed 
 * using pre(v) in Modelica.
 */

void save(double & var) 
{
  double* pvar = &var;
  long ind;
  if (sim_verbose) { printf("save %s = %f\n",getName(&var),var);
  }
  ind = long(pvar - globalData->helpVars);
  if (ind >= 0 && ind < globalData->nHelpVars) {
    h_saved[ind] = var;
    return;
  }
  ind = long(pvar - globalData->states);
  if (ind >= 0 && ind < globalData->nStates) {
    x_saved[ind] = var;
    return;
  }
  ind = long(pvar - globalData->statesDerivatives);
  if (ind >= 0 && ind < globalData->nStates) {   
    xd_saved[ind] = var;
    return;
  }
  ind = long(pvar - globalData->algebraics);
  if (ind >= 0 && ind < globalData->nAlgebraic) {
    y_saved[ind] = var;
    return;
  }
  return;
}

double pre(double & var) 
{
  double* pvar = &var;
  long ind;
  if (globalData->init) { // if during initialization, pre(v) = v
  	return *pvar;
  }
  
  ind = long(pvar - globalData->states);
  if (ind >= 0 && ind < globalData->nStates) {
    return x_saved[ind];
  }
  ind = long(pvar - globalData->statesDerivatives);
  if (ind >= 0 && ind < globalData->nStates) {    
    return xd_saved[ind];
  }
  ind = long(pvar - globalData->algebraics);
  if (ind >= 0 && ind < globalData->nAlgebraic) {
    return y_saved[ind];
  }
  ind = long(pvar - globalData->helpVars);
  return h_saved[ind];
}
bool edge(double& var) 
{
  return var && ! pre(var);
}

bool change(double& var)
{
 return   var && ! pre(var) || !var && pre(var);
}


/* store_result
* stores the result of all variables for all timesteps on a file
* suitable for plotting, etc.
*/

void store_result(const char * filename, double*data,long numpoints)
{
  ofstream f(filename);
  if (!f)
  {
    cerr << "Error, couldn't create output file " << filename << endl;
    exit(-1);
  }

  // Rather ugly numbers than unneccessary rounding.
  f.precision(numeric_limits<double>::digits10 + 1);
  f << "#Ptolemy Plot file, generated by OpenModelica" << endl;
  f << "#IntervalSize=" << numpoints << endl;
  f << "TitleText: OpenModelica simulation plot" << endl;
  f << "XLabel: t" << endl << endl;



  int num_vars = 1+globalData->nStates*2+globalData->nAlgebraic;
  
  // time variable.
  f << "DataSet: time"  << endl;
  for(int i = 0; i < numpoints; ++i)
    f << data[i*num_vars] << ", " << data[i*num_vars]<< endl;
  f << endl;

  for(int var = 0; var < globalData->nStates; ++var)
  {
    f << "DataSet: " << globalData->statesNames[var] << endl;
    for(int i = 0; i < numpoints; ++i)
      f << data[i*num_vars] << ", " << data[i*num_vars + 1+var] << endl;
    f << endl;
  }
  
  for(int var = 0; var < globalData->nStates; ++var)
  {
    f << "DataSet: " << globalData->stateDerivativesNames[var]  << endl;
    for(int i = 0; i < numpoints; ++i)
      f << data[i*num_vars] << ", " << data[i*num_vars + 1+globalData->nStates+var] << endl;
    f << endl;
  }
  
  for(int var = 0; var < globalData->nAlgebraic; ++var)
  {
    f << "DataSet: " << globalData->algebraicsNames[var] << endl;
    for(int i = 0; i < numpoints; ++i)
      f << data[i*num_vars] << ", " << data[i*num_vars + 1+2*globalData->nStates+var] << endl;
    f << endl;
  }

  f.close();
  if (!f)
  {
    cerr << "Error, couldn't write to output file " << filename << endl;
    exit(-1);
  }
}

/* add_result
 * add the values of one step for all variables to the data
 * array to be able to later store this on file.
 */

void add_result(double *data, long *actual_points)
{
  //save time first
  //cerr << "adding result for time: " << time;
  //cerr.flush();
  data[current_pos++] = globalData->timeValue;
  // .. then states..
  for (int i = 0; i < globalData->nStates; i++, current_pos++) {
    data[current_pos] = globalData->states[i];
  }
  // ..followed by derivatives..
  for (int i = 0; i < globalData->nStates; i++, current_pos++) {
    data[current_pos] = globalData->statesDerivatives[i];
  }
  // .. and last alg. vars.
  for (int i = 0; i < globalData->nAlgebraic; i++, current_pos++) {
    data[current_pos] = globalData->algebraics[i];
  }
  //cerr << "  ... done" << endl;
  (*actual_points)++;
}

  /* read_input
     Reads initial values from a text file.
     The textfile should be given as argument to the main function using 
     the -f file flag.
  */
  void read_input(int argc, char **argv,
		  double* x,double*xd,double*y,
		  double *p, int nx,int ny, int np,
		  double *start, double *stop,
		double *step)
{

  string *filename=(string*)getFlagValue("f",argc,argv);
  if (filename == NULL) { 
    filename = new string(string(globalData->modelName)+"_init.txt");  // model_name defined in generated code for model.
  }

  ifstream file(filename->c_str());
  if (!file) { 
    cerr << "Error, can not read file " << filename 
	 << " as indata to simulation." << endl; 
    exit(-1);
  }
  //  cerr << "opened file" << endl;
  read_commented_value(file,start);
  read_commented_value(file,stop);
  read_commented_value(file,step);
  int nxchk,nychk,npchk;
  read_commented_value(file,&nxchk);
  read_commented_value(file,&nychk);
  read_commented_value(file,&npchk);
  if (nxchk != nx || nychk != ny || npchk != np) {
    cerr << "Error, input data file does not match model." << endl;
    cerr << "nx from file: "<<nxchk<<endl;
    cerr << "ny from file: "<<nychk<<endl;
    cerr << "np from file: "<<npchk<<endl;
    exit(-1);
  }
  for(int i = 0; i < nx; i++) { // Read x initial values  	
    read_commented_value(file,&x[i]);
    if (sim_verbose) {
    cout << "read " << getName(&x[i]) << " = " << x[i] << " from init file." << endl;
    }
  }
 for(int i = 0; i < nx; i++) { // Read der(x) initial values
    read_commented_value(file,&xd[i]);
    if (sim_verbose) {
    cout << "read " << getName(&xd[i]) << " = " << xd[i] << " from init file." << endl;
    }
  }
 for(int i = 0; i < ny; i++) { // Read y initial values
    read_commented_value(file,&y[i]);
    if (sim_verbose) {
    cout << "read " << getName(&y[i]) << " = " << y[i] << " from init file." << endl;
    }
  }
 for(int i = 0; i < np; i++) { // Read parameter values
    read_commented_value(file,&p[i]);
    if (sim_verbose) {
    cout << "read" << getName(&p[i]) << " = " << p[i] << " from init file." << endl;
    }
  }
 file.close();
 if (sim_verbose) {
 	cout << "Read parameter data from file " << *filename << endl;
 }
}


inline void read_commented_value( ifstream &f, double *res)
{
  string line;
//  f >> *res;   
  char c[160];
  f.getline(c,160);
  line = c;

  if (line.find("true") != line.npos) {
	  *res = 1.0;
  }
  else if (line.find("false") != line.npos) {
	  *res = 0.0;
  }
  else {
    *res = atof(c);
  }
}

inline void read_commented_value( ifstream &f, int *res)
{
  f >> *res; 
  char c[160];
  f.getline(c,160);
}


void StateEventHandler(long* jroot, double *t) 
{
  for(int i=0;i<globalData->nZeroCrossing;i++) {
    if (jroot[i] ) {
      handleZeroCrossing(i);
      function_updateDependents();
      functionDAE_output();
    }
  }
  emit();
}

int
checkForDiscreteVarChanges(double *t);
void AddEvent(long);

/* This function is similar to CheckForNewEvents except that is called during initialization.
 * 
 */

void CheckForInitialEvents(double *t)
{
  // Check for changes in discrete variables
  globalData->timeValue = *t;

  checkForDiscreteVarChanges();
  if (sim_verbose) { 
  	cout << "Check for initial events." << endl;
  }
  function_zeroCrossing(&globalData->nStates,
                        &globalData->timeValue,
                        globalData->states,
                        &globalData->nZeroCrossing,gout,0,0);
  for (long i=0;i<globalData->nZeroCrossing;i++) {
  	//printf("gout[%d]=%f\n",i,gout[i]);
    if (gout[i] < 0  || zeroCrossingEnabled[i]==0) { // check also zero crossings that are on zero.
    	if (sim_verbose) {
    		cout << "adding event " << i << " at initialization" << endl;
    		}
       AddEvent(i);
    } 
  }
}


void CheckForNewEvents(double *t)
{
  // Check for changes in discrete variables
  globalData->timeValue = *t;
  checkForDiscreteVarChanges();

  function_zeroCrossing(&globalData->nStates,
                        &globalData->timeValue,
                        globalData->states,
                        &globalData->nZeroCrossing,gout,0,0);
  for (long i=0;i<globalData->nZeroCrossing;i++) {
    if (gout[i] < 0) {
       AddEvent(i);
    }
  }
}

void AddEvent(long index)
{
  list<long>::iterator i;
  for (i=EventQueue.begin(); i != EventQueue.end(); i++) {
    if (*i == index)
      return;
  }
  EventQueue.push_back(index);
  //  cout << "Adding Event:" << index << " queue length:" << EventQueue.size() << endl;
}

bool
ExecuteNextEvent(double *t)
{
  if (EventQueue.begin() != EventQueue.end()) {
    long nextEvent = EventQueue.front();
    if (nextEvent >= globalData->nZeroCrossing) {
      globalData->timeValue = *t;
      function_when(nextEvent-globalData->nZeroCrossing);
    }
    else {
      globalData->timeValue = *t;
      handleZeroCrossing(nextEvent);
      function_updateDependents();
      functionDAE_output();
    }
    emit();
    EventQueue.pop_front();
    return true;
  }
  return false;
}

void
StartEventIteration(double *t)
{
  while (EventQueue.begin() != EventQueue.end()) {
    calcEnabledZeroCrossings();
    while (ExecuteNextEvent(t)) {}
    for (long i = 0; i < globalData->nHelpVars; i++) save(globalData->helpVars[i]);
    globalData->timeValue = *t;
    function_updateDependents();
    CheckForNewEvents(t);
  }
  //  cout << "EventIteration done" << endl;
}
