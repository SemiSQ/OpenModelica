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

#include "simulation_events.h"
#include "simulation_runtime.h"
#include "simulation_result.h"
//#include "utility.h" // ppriv 2010-06-23 - removed "utility.h" due to clash of abs() macro from "f2c.h" with <math.h> in MSVC (abs is intrinsic function instead macro) and no usage here
#include <math.h>
#include <string.h> // adrpo - 2006-12-05 -> for memset
#include <list>
using namespace std;

// vectors with saved values used by pre(v)
double* h_saved = 0;
double* x_saved = 0;
double* xd_saved = 0;
double* y_saved = 0;
modelica_integer*  int_saved = 0;
modelica_boolean*  bool_saved = 0;
const char** str_saved = 0;

double* gout = 0;
double* gout_old = 0;
long* zeroCrossingEnabled = 0;
long inUpdate = 0;
long inSample = 0;
int dideventstep = 0;

static list<long> EventQueue;

/* \brief allocate global data structures for event handling
 *
 * \return zero if successful.
 */
int initializeEventData() {
  /*
	 * Re-Initialization is important because the variables are global and used in every solving step
	 */
	h_saved = 0;
	x_saved = 0;
	xd_saved = 0;
	y_saved = 0;
	int_saved = 0;
	bool_saved = 0;

	gout = 0;
	gout_old = 0;
	zeroCrossingEnabled = 0;
	inUpdate = 0;
	inSample = 0;

  // load default initial values.
  gout = new double[globalData->nZeroCrossing];
  gout_old = new double[globalData->nZeroCrossing];
  h_saved = new double[globalData->nHelpVars];
  x_saved = new double[globalData->nStates];
  xd_saved = new double[globalData->nStates];
  y_saved = new double[globalData->nAlgebraic];
  int_saved = new modelica_integer[globalData->intVariables.nAlgebraic];
  bool_saved = new modelica_boolean[globalData->boolVariables.nAlgebraic];
  str_saved = new const char*[globalData->stringVariables.nAlgebraic];
  zeroCrossingEnabled = new long[globalData->nZeroCrossing];
  if (!y_saved || !gout || !h_saved || !x_saved || !xd_saved
		  || !int_saved || !bool_saved || !str_saved || !zeroCrossingEnabled) {
    cerr << "Could not allocate memory for global event data structures"
        << endl;
    return -1;
  }
  // adrpo 2006-11-30 -> init the damn structures!
  memset(gout, 0, sizeof(double) * globalData->nZeroCrossing);
  memset(gout_old, 0, sizeof(double) * globalData->nZeroCrossing);
  memset(h_saved, 0, sizeof(double) * globalData->nHelpVars);
  memset(x_saved, 0, sizeof(double) * globalData->nStates);
  memset(xd_saved, 0, sizeof(double) * globalData->nStates);
  memset(y_saved, 0, sizeof(double) * globalData->nAlgebraic);
  memset(int_saved, 0, sizeof(modelica_integer) * globalData->intVariables.nAlgebraic);
  memset(bool_saved, 0, sizeof(modelica_boolean) * globalData->boolVariables.nAlgebraic);
  memset(str_saved, 0, sizeof(char*) * globalData->stringVariables.nAlgebraic);
  memset(zeroCrossingEnabled, 0, sizeof(long) * globalData->nZeroCrossing);
  return 0;
}

/* \brief deallocate global data for event handling.
 *
 */
void deinitializeEventData() {
  delete[] h_saved;
  delete[] x_saved;
  delete[] xd_saved;
  delete[] y_saved;
  delete[] int_saved;
  delete[] bool_saved;
  delete[] gout;
  delete[] gout_old;
  delete[] zeroCrossingEnabled;
  delete[] str_saved;
}

/* \brief
 *
 * Checks for events during initialization.
 *
 * Some solvers(e.g. DASSRT )can not handle events at exaclty the start time.
 * For instance der(x)=1, b = x>0 simulated from 0 .. x will miss the event.
 * The zeroCrossingEnabled vector is used to prevent DASSRT from checking the event above since it occur
 * at start time for the solver.
 *
 * This function checks such initial events and calls the event handling for this. The function is called after the first
 * step is taken by DASSRT (a small tiny step just to check these events)
 * */
void checkForInitialZeroCrossings(fortran_integer* jroot) {
  int i;
  if (sim_verbose) {
    cout << "checkForIntialZeroCrossings" << endl;
  }
  // enable only those that were disabled at init time.
  for (i = 0; i < globalData->nZeroCrossing; i++) {
    if (zeroCrossingEnabled[i] == 0) {
      zeroCrossingEnabled[i] = 1;
    } else {
      zeroCrossingEnabled[i] = 0;
    }
  }
  function_zeroCrossing(&globalData->nStates, &globalData->timeValue,
      globalData->states, &globalData->nZeroCrossing, gout, 0, 0);

  for (i = 0; i < globalData->nZeroCrossing; i++) {
    if (zeroCrossingEnabled[i] && gout[i]) {
      handleZeroCrossing(i);
      function_updateDependents();
      functionDAE_output();
    }
  }
  sim_result->emit();
  CheckForNewEvents(&globalData->timeValue);
  StartEventIteration(&globalData->timeValue);

  saveall();
  calcEnabledZeroCrossings();
  if (sim_verbose) {
    cout << "checkForIntialZeroCrossings done." << endl;
  }
}

/* This function is similar to CheckForNewEvents except that is called during initialization.
 *
 */

void CheckForInitialEvents(double *t) {
  // Check for changes in discrete variables
  globalData->timeValue = *t;
  if (sim_verbose) {
    cout << "Check for initial events." << endl;
  }
  // if discrete variable not in when equation has changed, saveall and  solve equations again.
  while (checkForDiscreteVarChanges()) {
    saveall();
    function_updateDependents();
  }
  function_zeroCrossing(&globalData->nStates, &globalData->timeValue,
      globalData->states, &globalData->nZeroCrossing, gout, 0, 0);
  for (long i = 0; i < globalData->nZeroCrossing; i++) {
    if (sim_verbose)
      printf("gout[%ld]=%f\n", i, gout[i]);
    if (gout[i] < 0 || zeroCrossingEnabled[i] == 0) { // check also zero crossings that are on zero.
      if (sim_verbose) {
        cout << "adding event " << i << " at initialization" << endl;
      }
      AddEvent(i);
    }
  }
}

void CheckForNewEvents(double *t) {
  //	int discVarChange=0;
  // Check for changes in discrete variables
  globalData->timeValue = *t;
  // if discrete variable not in when equation has changed, saveall and solve equations again.
  /*
   while(checkForDiscreteVarChanges()) {
   discVarChange=1;
   saveall();
   function_updateDependents();
   }

   if(!discVarChange) function_updateDependents();
   */

  if (checkForDiscreteVarChanges()) {
    AddEvent(-1);
  }

  function_zeroCrossing(&globalData->nStates, &globalData->timeValue,
      globalData->states, &globalData->nZeroCrossing, gout, 0, 0);
  for (long i = 0; i < globalData->nZeroCrossing; i++) {
    if (gout[i] < 0) {
      AddEvent(i);
    }
  }
}

void AddEvent(long index) {
  list<long>::iterator i;
  for (i = EventQueue.begin(); i != EventQueue.end(); i++) {
    if (*i == index)
      return;
  }
  EventQueue.push_back(index);
  //cout << "Adding Event:" << index << " queue length:" << EventQueue.size() << endl;
}

bool ExecuteNextEvent(double *t) {
  if (sim_verbose) {
    cout << "Events in the queue:";
    for (list<long>::const_iterator it = EventQueue.begin(); it
        != EventQueue.end(); ++it) {
      cout << *it << ", ";
    }
    cout << endl;
  }
  if (EventQueue.begin() != EventQueue.end()) {
    long nextEvent = EventQueue.front();
    if (sim_verbose) {
      printf("Executing event id:%ld\n", nextEvent);
    }
    if (nextEvent >= globalData->nZeroCrossing) {
      globalData->timeValue = *t;
      function_when(nextEvent - globalData->nZeroCrossing);
    } else if (nextEvent >= 0) {
      globalData->timeValue = *t;
      handleZeroCrossing(nextEvent);
      function_updateDependents();
      functionDAE_output();
    }
    function_updateDependents();
    //emit();
    EventQueue.pop_front();
    return true;
  }
  return false;
}

void StartEventIteration(double *t) {
  while (EventQueue.begin() != EventQueue.end()) {
    calcEnabledZeroCrossings();
    while (ExecuteNextEvent(t)) {
    }
    inSample = 0;
    //    for (long i = 0; i < globalData->nHelpVars; i++) save(globalData->helpVars[i]);
    saveall();
    globalData->timeValue = *t;
    function_updateDependents();
    CheckForNewEvents(t);
  }
  for (long i = 0; i < globalData->nHelpVars; i++) {
    //  	globalData->helpVars[i] = 0;
    //  	save(globalData->helpVars[i]);
  }
  //  cout << "EventIteration done" << endl;
}

void StateEventHandler(fortran_integer* jroot, double *t) {
  inSample = 1;
  for (int i = 0; i < globalData->nZeroCrossing; i++) {
    if (jroot[i]) {
      handleZeroCrossing(i);
      function_updateDependents();
      functionDAE_output();
    }
  }
  //  emit();
}

#if defined(__GNUC__) // for GNUC
// adrpo - 2006-12-05
// for GNUC the inline is a bit more involved
// read here:
// http://gcc.gnu.org/onlinedocs/gcc-3.2.3/gcc/Inline.html
#else /* for other compilers */
inline
#endif
void calcEnabledZeroCrossings() {
  int i;
  for (i = 0; i < globalData->nZeroCrossing; i++) {
    zeroCrossingEnabled[i] = 1;
  }
  function_zeroCrossing(&globalData->nStates, &globalData->timeValue,
      globalData->states, &globalData->nZeroCrossing, gout, 0, 0);
  for (i = 0; i < globalData->nZeroCrossing; i++) {
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

// relation functions used in zero crossing detection
double Less(double a, double b) {
  return a - b;
}

double LessEq(double a, double b) {
  return a - b;
}

double Greater(double a, double b) {
  return b - a;
}

double GreaterEq(double a, double b) {
  return b - a;
}

double Sample(double t, double start, double interval) {
  double pipi = atan(1.0) * 8.0;
  if (t < (start - interval * .25))
    return -1.0;
  return sin(pipi * (t - start) / interval);
}

/*
 * Returns true and triggers time events at time instants
 * start + i*interval (i=0,1,...).
 * During continuous integration the operator returns always false.
 * The starting time start and the sample interval interval need to
 * be parameter expressions and need to be a subtype of Real or Integer.
 */
double sample(double start, double interval) {
  // double sloop = 4.0/interval;
  // adrpo: if we test for inSample == 0 no event is generated when start + 0*interval!
  // if (inSample == 0) return 0;
  double tmp = ((globalData->timeValue - start) / interval);
  tmp -= floor(tmp);
  /* adrpo - 2008-01-15
   * comparison was tmp >= 0 fails sometimes on x86 due to extended precision in registers
   * TODO - fix the simulation runtime so that the sample event is generated at EXACTLY that time.
   * below should be: if (tmp >= -0.0001 && tmp < 0.0001) but needs more testing as some models from
   * testsuite fail.
   */
  static const double eps = 0.0001;
  /*
   * sjoelund - do not sample before the start value !
   */
  if (globalData->timeValue >= start-eps && tmp >= -eps && tmp < eps) {
    if (sim_verbose)
      cout << "Calling sample(" << start << ", " << interval << ")\n"
          << "+generating an event at time:" << globalData->timeValue
          << " tmp: " << tmp << endl;
    return 1;
  } else {
    if (sim_verbose)
      cout << "Calling sample(" << start << ", " << interval << ")\n"
          << "-NO an event at time:" << globalData->timeValue << " tmp: "
          << tmp << endl;
    return 0;
  }
}

int compdbl(const void* a, const void* b) {
  const double *v1 = (const double *) a;
  const double *v2 = (const double *) b;
  const double diff = *v1 - *v2;
  const double epsilon = 0.00000000000001;

  if (diff < epsilon && diff > -epsilon)
    return 0;
  return (*v1 > *v2 ? 1 : -1);
}

int unique(void *base, size_t nmemb, size_t size, int(*compar)(const void *, const void *)) {
  size_t nuniq = 0;
  size_t i;
  void *a, *b, *c;
  a = base;
  for (i=1; i<nmemb; i++) {
    b = ((char*)base)+i*size;
    if (0 == compar(a,b)) {
      nuniq++;
    } else {
      a = b;
      c = ((char*)base)+(i-nuniq)*size;
      memcpy(c, b, size);
    }
  }
  return nmemb-nuniq;
}

// Array does not need to be sorted
int filter_all_lesser(void *base, void *a, size_t nmemb, size_t size, int(*compar)(const void *, const void *)) {
  size_t nuniq = 0;
  size_t i;
  void *b, *c;
  for (i=0; i<nmemb; i++) {
    b = ((char*)base)+i*size;
    if (compar(a,b) > 0) {
      nuniq++;
    } else {
      c = ((char*)base)+(i-nuniq)*size;
      memcpy(c, b, size);
    }
  }
  return nmemb-nuniq;
}

void initSample(double start) {
  /* not used yet
   * long measure_start_time = clock();
   */

  if (sim_verbose) printf("Notice: Calculated time of sample events is not yet used!\n");
  function_sampleInit();
  /* This code will generate an array of time values when sample generates events.
   * The only problem is our backend does not generate this array.
   * Sample() and sample() also need to be changed, but this should be easy to fix. */

  int i;
  double stop = 1.0;
  double d;
  double* events;
  int num_samples = globalData->nRawSamples;
  int max_events = 0;
  int ix = 0;
  int nuniq;

  for (i=0; i<num_samples; i++) {
    if (stop >= globalData->rawSampleExps[i].start)
      max_events += (int)((stop - globalData->rawSampleExps[i].start)/globalData->rawSampleExps[i].interval+1);
  }
  events = (double*) malloc(max_events * sizeof(double) + 1);
  for (i=0; i<num_samples; i++) {
    if (sim_verbose) printf("Generate times for sample(%f,%f)\n",globalData->rawSampleExps[i].start,globalData->rawSampleExps[i].interval);
    for (d=globalData->rawSampleExps[i].start; ix<max_events && d<stop; d+= globalData->rawSampleExps[i].interval) {
      events[ix++] = d;
    }
  }
  // Sort, filter out values before start, filter out unique values
  max_events = filter_all_lesser(events,&start,max_events,sizeof(double),compdbl);
  qsort(events,max_events,sizeof(double),compdbl);
  nuniq = unique(events,max_events,sizeof(double),compdbl);
  if (sim_verbose) {
    printf("Number of sorted, unique sample events: %d\n", nuniq);
    //for (i=0; i<nuniq; i++) printf("%f\n", i, events[i]);
  }
  globalData->sampleTimes = events;
  globalData->curSampleTimeIx = 0;
  globalData->nSampleTimes = nuniq;

}

void saveall() {
  int i;
  for (i = 0; i < globalData->nStates; i++) {
    x_saved[i] = globalData->states[i];
    xd_saved[i] = globalData->statesDerivatives[i];
  }
  for (i = 0; i < globalData->nAlgebraic; i++) {
    y_saved[i] = globalData->algebraics[i];
  }
  for (i = 0; i < globalData->intVariables.nAlgebraic; i++) {
    int_saved[i] = globalData->intVariables.algebraics[i];
  }
  for (i = 0; i < globalData->boolVariables.nAlgebraic; i++) {
    bool_saved[i] = globalData->boolVariables.algebraics[i];
  }
  for (i = 0; i < globalData->nHelpVars; i++) {
    h_saved[i] = globalData->helpVars[i];
  }
  for (i = 0; i < globalData->stringVariables.nAlgebraic; i++) {
    str_saved[i] = globalData->stringVariables.algebraics[i];
  }
}

/* save(v) saves the previous value of a discrete variable v, which can be accessed
 * using pre(v) in Modelica.
 */

void save(double & var) {
  double* pvar = &var;
  long ind;
  if (sim_verbose) {
    printf("save %s = %f\n", getName(&var), var);
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

void save(modelica_integer & var) {
  modelica_integer* pvar = &var;
  long ind;
  if (sim_verbose) {
    printf("save %s = %d\n", getName(&var), var);
  }
  ind = long(pvar - globalData->intVariables.algebraics);
  if (ind >= 0 && ind < globalData->intVariables.nAlgebraic) {
    int_saved[ind] = var;
    return;
  }
  return;
}

void save(modelica_boolean & var) {
  modelica_boolean* pvar = &var;
  long ind;
  if (sim_verbose) {
    printf("save %s = %o\n", getName(&var), var);
  }
  ind = long(pvar - globalData->boolVariables.algebraics);
  if (ind >= 0 && ind < globalData->boolVariables.nAlgebraic) {
    bool_saved[ind] = var;
    return;
  }
  return;
}


void save(const char* & var) {
  const char** pvar = &var;
  long ind;
  if (sim_verbose) {
    printf("save %s = %s\n", getName((double*)pvar), var);
  }
  ind = long(pvar - globalData->stringVariables.nAlgebraic);
  if (ind >= 0 && ind < globalData->stringVariables.nAlgebraic) {
    str_saved[ind] = var;
    return;
  }
  return;
}

double pre(double & var) {
  double* pvar = &var;
  long ind;

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
  if (ind >= 0 && ind < globalData->nHelpVars) {
    return h_saved[ind];
  }
  return var;
}

modelica_integer pre(modelica_integer & var) {
  modelica_integer* pvar = &var;
  long ind;

  ind = long(pvar - globalData->intVariables.algebraics);
  if (ind >= 0 && ind < globalData->intVariables.nAlgebraic) {
    return int_saved[ind];
  }
  return var;
}

modelica_boolean pre(signed char & var) {
  modelica_boolean* pvar = &var;
  long ind;

  ind = long(pvar - globalData->boolVariables.algebraics);
  if (ind >= 0 && ind < globalData->boolVariables.nAlgebraic) {
    return bool_saved[ind];
  }
  return var;
}

const char* pre(const char* & var) {
  const char** pvar = &var;
  long ind;

  ind = long(pvar - globalData->stringVariables.nAlgebraic);
  if (ind >= 0 && ind < globalData->stringVariables.nAlgebraic) {
    return str_saved[ind];
  }
  return var;
}



bool edge(double& var) {
  return var && !pre(var);
}

bool edge(modelica_integer& var) {
  return var && !pre(var);
}

bool edge(modelica_boolean& var) {
  return var && !pre(var);
}


bool change(double& var) {
  return (var != pre(var));
}

bool change(modelica_integer& var) {
  return (var != pre(var));
}

bool change(const char*& var) {
  return (var != pre(var));
}

bool change(modelica_boolean& var) {
  /*
   signed char * pvar = &var;
   cout << "varname : " <<  getName(pvar) << endl;
   cout << "value : " << (bool)var << " pre(value) : " << (bool)pre(var) << endl;
  */
  return (var != pre(var));
}

void checkTermination(){
  if (terminationAssert) {
    if (warningLevelAssert) { // terminated from assert, etc.
       cout << "Simulation call assert() at time " << globalData->timeValue << endl;
       cout << "Level : warning" << endl;
       cout << "Message : " << TermMsg << endl;
     }else{
       cout << "Simulation call assert() at time " << globalData->timeValue << endl;
       cout << "Level : error" << endl;
       cout << "Message : " << TermMsg << endl;
       throw TerminateSimulationException(globalData->timeValue);
     }
  }
  if (terminationTerminate){
    cout << "Simulation call terminate() at time " << globalData->timeValue << endl;
    cout << "Message : " << TermMsg << endl;
    throw TerminateSimulationException(globalData->timeValue);
  }
}




/*
 * All event functions from here, are till now only used in Euler
 *
*/

//
// This function checks for Events in Interval=[oldTime,timeValue]
// If a ZeroCrossing Function cause a sign change, root finding
// process will start
//
int CheckForNewEvent(int flag) {
	if (flag != INTERVAL){
		int needToIterate=0;
		int IterationNum=0;
		while(checkForDiscreteChanges() || needToIterate) {
			if (sim_verbose) {
				cout << "Discrete Variable changed -> event iteration." << endl;
				sim_result->emit();
			}
			saveall();
			functionDAE(needToIterate);
			IterationNum++;
			if (IterationNum>IterationMax) {
				throw TerminateSimulationException(globalData->timeValue,
						string("ERROR: Too many Iteration. System is not consistent!\n"));
			}
	  }
	}
	else{
		std::copy(gout, gout + globalData->nZeroCrossing, gout_old);
		function_onlyZeroCrossings(gout,&globalData->timeValue);
		if (sim_verbose){ cout << "Check for events ..." << endl;
					  }
		for (long i = 0; i < globalData->nZeroCrossing; i++) {
			//if (sim_verbose){ cout << "check gout_old[" << i << "] = " << gout_old[i] << "\t" <<
			//				"check gout[" << i << "] = " << gout[i] << endl;
			//}
			if ( (gout[i] < 0 and gout_old[i] > 0) ||
				 (gout[i] > 0 and gout_old[i] < 0)	) {
				if (sim_verbose) {
					cout << "adding event " << i << " at time: "
					<< globalData->timeValue << endl;
				}
				AddEvent(i);
			}
		}
		if (!EventQueue.empty() && flag == INTERVAL){
			FindRoot();
			EventHandle();
      
      if (sim_verbose) { cout << "Event Handling done!" << endl;} 
      // save the ZeroCrossings
	    function_onlyZeroCrossings(gout,&globalData->timeValue);
	    std::copy(gout, gout + globalData->nZeroCrossing, gout_old);
	
			return 1;
		}
	}
	return 0;
}

//
// This function handle events and change all
// needed variables for an event
//
void EventHandle(){

	while(!EventQueue.empty()){

		long event_id;
		event_id = EventQueue.front();

		if (sim_verbose) cout << "Handle Event caused by ZeroCrossing: " << event_id << endl;

		//determined complete system
		int needToIterate=0;
		int IterationNum=0;
		functionDAE(needToIterate);
		if (sim_verbose) { sim_result->emit();}
		while (needToIterate){
			if (sim_verbose) cout << "reinit Iteration needed!" << endl;
			saveall();
			functionDAE(needToIterate);
			if (sim_verbose) { sim_result->emit();}
			IterationNum++;
			if (IterationNum>IterationMax) {
				//break;
				throw TerminateSimulationException(globalData->timeValue,
					string("ERROR: Too many Iteration. System is not consistent!\n"));
			}

		}
		EventQueue.pop_front();
	}
	CheckForNewEvent(NOINTERVAL);

}

//
// This function perform a root finding for
// Intervall=[oldTime,timeValue]
//
void FindRoot(){
	double EventTime = 0;

	//Empty EventQueue, because we search only for one event
	while (!EventQueue.empty())
	{
	    if (sim_verbose){
	    	//cout << "--------------------------------------------" << endl;
	    	cout << "Search for current event. Events in queue:  " << EventQueue.front() << endl;

	    }
	    EventQueue.pop_front();
	}

	long int event_id =0;

	double *states_right = new double[globalData->nStates];
	double *states_left = new double[globalData->nStates];

	double time_left = globalData->oldTime;
	double time_right = globalData->timeValue;

	//write states to work arrays
	for(int i=0;i<globalData->nStates;i++){
		states_left[i] = globalData->states_old[i];
		states_right[i] = globalData->states[i];
	}

	// Search for event time and event_id with Bisection method
	EventTime = BiSection(&time_left,&time_right, states_left, states_right, &event_id);


	if (sim_verbose) {
		cout.precision(10);
		cout << "Found event " << event_id << " at time: "<< EventTime << endl;
		cout << "Time at Point left: " << time_left << endl;
		cout << "Time at Point right: " << time_right << endl;
	}
	AddEvent(event_id);

	//determined system at t_e - epsilon
	globalData->timeValue = time_left;
	for(int i=0;i<globalData->nStates;i++){
		globalData->states[i] = states_left[i];
	}
	//determined continuous system
	functionODE_new();
	functionAlgebraics();
	functionAliasEquations();
	saveall();
	sim_result->emit();


	//determined system at t_e + epsilon
	globalData->timeValue = time_right;
	for(int i=0;i<globalData->nStates;i++){
		globalData->states[i] = states_right[i];
	}
    
	delete[] states_left;
	delete[] states_right;

	EventHandle();
}

//
// Method to find root in Intervall[oldTime,timeValue]
//
double BiSection(double* a, double* b, double* states_a, double* states_b,long int* event_id )
{

	//double TTOL =  DBL_EPSILON*fabs(2*b-a)*100;
	double TTOL = 1e-06;
	double c;

	if (sim_verbose){
			cout << "Check interval [" << *a << "," << *b << "]" << endl;
			cout << "TTOL is set to: " << TTOL << endl;
	}

	while ( fabs(*b-*a) > TTOL){

		c = (*a+*b)/2.0;
		globalData->timeValue = c;

		//if (sim_verbose){
		//		cout << "Split interval at point : " << c << endl;
		//}

		//calculates states at time c
		for(int i=0;i<globalData->nStates;i++){
			globalData->states[i] = (states_a[i] + states_b[i]) / 2.0;
		}

		//calculates Values dependents on new states
		functionODE_new();
		functionAlgebraics();

		if ( CheckZeroCrossings(event_id)){ //If Zerocrossing in left Section

			for(int i=0;i<globalData->nStates;i++){
				states_b[i] = globalData->states[i];
			}
			*b = c;
			/*if (sim_verbose){
				cout << "Found ZeroCrossing in the left section. " << endl;
				for(int i=0;i<globalData->nStates;i++){
					cout << "states at b : " << states_b[i]  << endl;
				}
			}*/

		}else{   //else Zerocrossing in right Section

			for(int i=0;i<globalData->nStates;i++){
				states_a[i] = globalData->states[i];
			}
			*a = c;
			/*if (sim_verbose){
				cout << "ZeroCrossing is in the right section. " << endl;
				for(int i=0;i<globalData->nStates;i++){
					cout << "states at a : " << states_a[i]  << endl;
				}
			}*/
		}
	}

	c = (*a+*b)/2.0;
	return c;
}


//
// Check if at least one zerocrossing has change sign
// is used in BiSection
//
int CheckZeroCrossings(long int *eventid) {

  double *backup_gout = new double[globalData->nZeroCrossing];
  for(int i=0;i<globalData->nZeroCrossing;i++){
	backup_gout[i] = gout[i];
  }

  function_onlyZeroCrossings(gout,&globalData->timeValue);
  for (long i = 0; i < globalData->nZeroCrossing; i++) {
	  //if (sim_verbose){ cout << "check gout_old[" << i << "] = " << gout_old[i] << "\t" <<
	  //	  	  	  	    "check gout[" << i << "] = " << gout[i] << endl;
	  //}
	  //Found event in left section
	  if ((gout[i] < 0 and gout_old[i] > 0) ||
		  (gout[i] > 0 and gout_old[i] < 0)) {
		  *eventid = i;
		  return 1;
	  }
  }
  // Else event in right section
  for(int i=0;i<globalData->nZeroCrossing;i++){
	gout_old[i] = gout[i];
	gout[i] = backup_gout[i];
  }
  delete[] backup_gout;
  return 0;
}

void InitialZeroCrossings() {

  if (sim_verbose) {
    cout << "checkForIntialZeroCrossings" << endl;
  }
  std::copy(gout, gout + globalData->nZeroCrossing, gout_old);
  function_onlyZeroCrossings(gout,&globalData->timeValue);


  /*
    for (int i = 0; i < globalData->nZeroCrossing; i++) {
    if (gout[i] < 0) {
      zeroCrossingEnabled[i] = -1;
      if (sim_verbose) { cout << "Zero-Crossing [" << i << "] = " << gout[i] << " so it's set to 1" << endl;}
    } else if (gout[i] > 0) {
      zeroCrossingEnabled[i] = 1;
      if (sim_verbose) { cout << "Zero-Crossing [" << i << "] = " << gout[i] << " so it's set to -1" << endl;}
    } else {
      if (sim_verbose) { cout << "Could not initialize all Zero-Crossing!" << endl;}
    }
    //if gout[i] == 0 then ZC[i] will step in next step
    // TODO: check where ZC will move to handle correct
  }*/

  if (sim_verbose) {
    cout << "checkForIntialZeroCrossings done." << endl;
  }
}
