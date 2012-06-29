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
#include "simulation_data.h"

// array of value references of states
#if NUMBER_OF_STATES>0
fmiValueReference vrStates[NUMBER_OF_STATES] = STATES;
fmiValueReference vrStatesDerivatives[NUMBER_OF_STATES] = STATESDERIVATIVES;
#endif


static fmiBoolean invalidNumber(ModelInstance* comp, const char* f, const char* arg, int n, int nExpected){
  if (n != nExpected) {
    comp->state = modelError;
    comp->functions.logger(comp, comp->instanceName, fmiError, "error",
        "%s: Invalid argument %s = %d. Expected %d.", f, arg, n, nExpected);
    return fmiTrue;
  }
  return fmiFalse;
}

static fmiBoolean invalidState(ModelInstance* comp, const char* f, int statesExpected){
  if (!comp)
    return fmiTrue;
  if (!(comp->state & statesExpected)) {
    comp->state = modelError;
    comp->functions.logger(comp, comp->instanceName, fmiError, "error",
        "%s: Illegal call sequence. Expected State: %d.", f, statesExpected);
    return fmiTrue;
  }
  return fmiFalse;
}

static fmiBoolean nullPointer(ModelInstance* comp, const char* f, const char* arg, const void* p){
  if (!p) {
    comp->state = modelError;
    comp->functions.logger(comp, comp->instanceName, fmiError, "error",
        "%s: Invalid argument %s = NULL.", f, arg);
    return fmiTrue;
  }
  return fmiFalse;
}

static fmiBoolean vrOutOfRange(ModelInstance* comp, const char* f, fmiValueReference vr, unsigned int end) {
  if (vr >= end) {
    comp->functions.logger(comp, comp->instanceName, fmiError, "error",
        "%s: Illegal value reference %u.", f, vr);
    comp->state = modelError;
    return fmiTrue;
  }
  return fmiFalse;
}

// ---------------------------------------------------------------------------
// FMI functions: class methods not depending of a specific model instance
// ---------------------------------------------------------------------------

const char* fmiGetModelTypesPlatform() {
  return fmiModelTypesPlatform;
}

const char* fmiGetVersion() {
  return fmiVersion;
}

fmiComponent fmiInstantiateModel(fmiString instanceName, fmiString GUID,
    fmiCallbackFunctions functions, fmiBoolean loggingOn) {
  size_t i;
  ModelInstance* comp;
  if (!functions.logger)
    return NULL;
  if (!functions.allocateMemory || !functions.freeMemory){
    functions.logger(NULL, instanceName, fmiError, "error",
        "fmiInstantiateModel: Missing callback function.");
    return NULL;
  }
  if (!instanceName || strlen(instanceName)==0) {
    functions.logger(NULL, instanceName, fmiWarning, "Warning",
        "fmiInstantiateModel: Missing instance name.");
  }
  if (strcmp(GUID, MODEL_GUID)) {
    functions.logger(NULL, instanceName, fmiError, "error",
        "fmiInstantiateModel: Wrong GUID %s. Expected %s.", GUID, MODEL_GUID);
    return NULL;
  }
  comp = (ModelInstance *)functions.allocateMemory(1, sizeof(ModelInstance));
  if (comp) {
    DATA* fmudata = (DATA *)functions.allocateMemory(1, sizeof(DATA));
    comp->fmuData = fmudata;
    if (!comp->fmuData) {
      functions.logger(NULL, instanceName, fmiError, "error",
          "fmiInstantiateModel: Error: Could not initialize the global data structure file.");
      return NULL;
    }
  }else{
    functions.logger(NULL, instanceName, fmiError, "error",
        "fmiInstantiateModel: Out of memory.");
    return NULL;
  }
  if (comp->loggingOn) comp->functions.logger(NULL, instanceName, fmiOK, "log",
      "fmiInstantiateModel: GUID=%s", GUID);
  /* intialize modelData */
  setupDataStruc(comp->fmuData);
  initializeDataStruc(comp->fmuData);
  setupDataStruc2(comp->fmuData);

  /* setup model data with default start data */
  setDefaultStartValues(comp);
  setAllVarsToStart(comp->fmuData);
  setAllParamsToStart(comp->fmuData);

  comp->instanceName = instanceName;
  comp->GUID = GUID;
  comp->functions = functions;
  comp->loggingOn = loggingOn;
  comp->state = modelInstantiated;
  comp->eventInfo.iterationConverged = fmiTrue;
  comp->eventInfo.stateValueReferencesChanged = fmiTrue;
  comp->eventInfo.stateValuesChanged = fmiTrue;
  comp->eventInfo.terminateSimulation = fmiFalse;
  comp->eventInfo.upcomingTimeEvent = fmiFalse;
  comp->eventInfo.nextEventTime = 0;


  comp->initialisation.initMethod = (fmiString)functions.allocateMemory(100, sizeof(fmiString));
  comp->initialisation.optiMethod = (fmiString)functions.allocateMemory(100, sizeof(fmiString));
  comp->initialisation.initFile = (fmiString)functions.allocateMemory(255, sizeof(fmiString));
  strcpy(comp->initialisation.initMethod,"state");
  strcpy(comp->initialisation.optiMethod,"nelder_mead_ex");
  strcpy(comp->initialisation.initFile,"");

  return comp;
}

fmiStatus fmiSetDebugLogging(fmiComponent c, fmiBoolean loggingOn) {
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiSetDebugLogging", not_modelError))
    return fmiError;
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiSetDebugLogging: loggingOn=%d", loggingOn);
  comp->loggingOn = loggingOn;
  return fmiOK;
}

void fmiFreeModelInstance(fmiComponent c) {
  ModelInstance* comp = (ModelInstance *)c;
  if (!comp) return;
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiFreeModelInstance");

  DeinitializeDataStruc(comp->fmuData);
  comp->functions.freeMemory(comp);
}

// ---------------------------------------------------------------------------
// FMI functions: set variable values in the FMU
// ---------------------------------------------------------------------------

fmiStatus fmiSetReal(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiReal value[]){
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiSetReal", modelInstantiated|modelInitialized))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiSetReal", "vr[]", vr))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiSetReal", "value[]", value))
    return fmiError;
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiSetReal: nvr = %d", nvr);
  // no check wether setting the value is allowed in the current state
  for (i=0; i<nvr; i++) {
    if (vrOutOfRange(comp, "fmiSetReal", vr[i], NUMBER_OF_REALS+NUMBER_OF_STATES))
      return fmiError;
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiSetReal: #r%d# = %.16g", vr[i], value[i]);
    if (setReal(comp, vr[i],value[i]) != fmiOK) // to be implemented by the includer of this file
      return fmiError;
  }

  return fmiOK;
}

fmiStatus fmiSetInteger(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiInteger value[]){
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiSetInteger", modelInstantiated|modelInitialized))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiSetInteger", "vr[]", vr))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiSetInteger", "value[]", value))
    return fmiError;
  if (comp->loggingOn)
    comp->functions.logger(c, comp->instanceName, fmiOK, "log", "fmiSetInteger: nvr = %d",  nvr);
  for (i=0; i<nvr; i++) {
    if (vrOutOfRange(comp, "fmiSetInteger", vr[i], NUMBER_OF_INTEGERS))
      return fmiError;
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiSetInteger: #i%d# = %d", vr[i], value[i]);
    if (setInteger(comp, vr[i],value[i]) != fmiOK) // to be implemented by the includer of this file
      return fmiError;
  }

  return fmiOK;
}

fmiStatus fmiSetBoolean(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiBoolean value[]){
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiSetBoolean", modelInstantiated|modelInitialized))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiSetBoolean", "vr[]", vr))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiSetBoolean", "value[]", value))
    return fmiError;
  if (comp->loggingOn)
    comp->functions.logger(c, comp->instanceName, fmiOK, "log", "fmiSetBoolean: nvr = %d",  nvr);
  for (i=0; i<nvr; i++) {
    if (vrOutOfRange(comp, "fmiSetBoolean", vr[i], NUMBER_OF_BOOLEANS))
      return fmiError;
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiSetBoolean: #b%d# = %s", vr[i], value[i] ? "true" : "false");
    if (setBoolean(comp, vr[i],value[i]) != fmiOK) // to be implemented by the includer of this file
      return fmiError;
  }

  return fmiOK;
}

fmiStatus fmiSetString(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiString value[]){
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiSetString", modelInstantiated|modelInitialized))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiSetString", "vr[]", vr))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiSetString", "value[]", value))
    return fmiError;
  if (comp->loggingOn)
    comp->functions.logger(c, comp->instanceName, fmiOK, "log", "fmiSetString: nvr = %d",  nvr);
  for (i=0; i<nvr; i++) {
    char* string = (char*)comp->fmuData->localData[0]->stringVars[vr[i]];
    if (vrOutOfRange(comp, "fmiSetString", vr[i], NUMBER_OF_STRINGS))
      return fmiError;
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiSetString: #s%d# = '%s'", vr[i], value[i]);
    if (nullPointer(comp, "fmiSetString", "value[i]", value[i]))
      return fmiError;
    if (string==NULL || strlen(string) < strlen(value[i])) {
      if (string) comp->functions.freeMemory(string);
      comp->fmuData->localData[0]->stringVars[vr[i]] = *(fmiString*)comp->functions.allocateMemory(1+strlen(value[i]), sizeof(char));
      if (!comp->fmuData->localData[0]->stringVars[vr[i]]) {
        comp->state = modelError;
        comp->functions.logger(NULL, comp->instanceName, fmiError, "error", "fmiSetString: Out of memory.");
        return fmiError;
      }
    }
    strcpy((char*)comp->fmuData->localData[0]->stringVars[vr[i]], (char*)value[i]);
  }
  return fmiOK;
}

fmiStatus fmiSetTime(fmiComponent c, fmiReal time) {
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiSetTime", modelInstantiated|modelInitialized))
    return fmiError;
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiSetTime: time=%.16g", time);
  comp->fmuData->localData[0]->timeValue = time;
  return fmiOK;
}

fmiStatus fmiSetContinuousStates(fmiComponent c, const fmiReal x[], size_t nx){
  ModelInstance* comp = (ModelInstance *)c;
  unsigned int i=0;
  if (invalidState(comp, "fmiSetContinuousStates", modelInitialized))
    return fmiError;
  if (invalidNumber(comp, "fmiSetContinuousStates", "nx", nx, NUMBER_OF_STATES))
    return fmiError;
  rotateRingBuffer(comp->fmuData->simulationData, 1, (void**) comp->fmuData->localData);
#if NUMBER_OF_STATES>0
  if (nullPointer(comp, "fmiSetContinuousStates", "x[]", x))
    return fmiError;
  for (i=0; i<nx; i++) {
    fmiValueReference vr = vrStates[i];
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiSetContinuousStates: #r%d#=%.16g", vr, x[i]);
    assert(vr>=0 && vr<NUMBER_OF_REALS);
    if (setReal(comp, vr, x[i]) != fmiOK) // to be implemented by the includer of this file
      return fmiError;
  }
#endif
  return fmiOK;
}

// ---------------------------------------------------------------------------
// FMI functions: get variable values from the FMU
// ---------------------------------------------------------------------------

fmiStatus fmiGetReal(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiReal value[]) {
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetReal", not_modelError))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiGetReal", "vr[]", vr))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiGetReal", "value[]", value))
    return fmiError;
#if NUMBER_OF_REALS>0
  for (i=0; i<nvr; i++) {
    if (vrOutOfRange(comp, "fmiGetReal", vr[i], NUMBER_OF_REALS+NUMBER_OF_STATES))
      return fmiError;
    value[i] = getReal(comp, vr[i]);
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiGetReal: #r%u# = %.16g", vr[i], value[i]);
  }
  return fmiOK;
#else
  return fmiOK;
#endif
}

fmiStatus fmiGetInteger(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiInteger value[]) {
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetInteger", not_modelError))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiGetInteger", "vr[]", vr))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiGetInteger", "value[]", value))
    return fmiError;
#if NUMBER_OF_INTEGERS>0
  for (i=0; i<nvr; i++) {
    if (vrOutOfRange(comp, "fmiGetInteger", vr[i], NUMBER_OF_INTEGERS))
      return fmiError;
    value[i] = getInteger(comp, vr[i]); // to be implemented by the includer of this file
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiGetInteger: #i%u# = %d", vr[i], value[i]);
  }
  return fmiOK;
#else
  return fmiOK;
#endif
}

fmiStatus fmiGetBoolean(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiBoolean value[]) {
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetBoolean", not_modelError))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiGetBoolean", "vr[]", vr))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiGetBoolean", "value[]", value))
    return fmiError;
#if NUMBER_OF_BOOLEANS>0
  for (i=0; i<nvr; i++) {
    if (vrOutOfRange(comp, "fmiGetBoolean", vr[i], NUMBER_OF_BOOLEANS))
      return fmiError;
    value[i] = getBoolean(comp, vr[i]); // to be implemented by the includer of this file
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiGetBoolean: #b%u# = %s", vr[i], value[i]? "true" : "false");
  }
  return fmiOK;
#else
  return fmiOK;
#endif
}

fmiStatus fmiGetString(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiString  value[]) {
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetString", not_modelError))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiGetString", "vr[]", vr))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiGetString", "value[]", value))
    return fmiError;
#if NUMBER_OF_STRINGS>0
  for (i=0; i<nvr; i++) {
    if (vrOutOfRange(comp, "fmiGetString", vr[i], NUMBER_OF_STRINGS))
      return fmiError;
    value[i] = getString(comp, vr[i]); // to be implemented by the includer of this file
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiGetString: #s%u# = '%s'", vr[i], value[i]);
  }
  return fmiOK;
#else
  return fmiOK;
#endif
}

fmiStatus fmiGetStateValueReferences(fmiComponent c, fmiValueReference vrx[], size_t nx){
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetStateValueReferences", not_modelError))
    return fmiError;
  if (invalidNumber(comp, "fmiGetStateValueReferences", "nx", nx, NUMBER_OF_STATES))
    return fmiError;
  if (nullPointer(comp, "fmiGetStateValueReferences", "vrx[]", vrx))
    return fmiError;
#if NUMBER_OF_STATES>0
  for (i=0; i<nx; i++) {
    vrx[i] = vrStates[i];
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiGetStateValueReferences: vrx[%d] = %d", i, vrx[i]);
  }
#endif
  return fmiOK;
}

fmiStatus fmiGetContinuousStates(fmiComponent c, fmiReal states[], size_t nx){
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetContinuousStates", not_modelError))
    return fmiError;
  if (invalidNumber(comp, "fmiGetContinuousStates", "nx", nx, NUMBER_OF_STATES))
    return fmiError;
  if (nullPointer(comp, "fmiGetContinuousStates", "states[]", states))
    return fmiError;
#if NUMBER_OF_STATES>0
  for (i=0; i<nx; i++) {
    fmiValueReference vr = vrStates[i];
    states[i] = getReal(comp, vr); // to be implemented by the includer of this file
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiGetContinuousStates: #r%u# = %.16g", vr, states[i]);
  }
#endif
  return fmiOK;
}

fmiStatus fmiGetNominalContinuousStates(fmiComponent c, fmiReal x_nominal[], size_t nx){
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetNominalContinuousStates", not_modelError))
    return fmiError;
  if (invalidNumber(comp, "fmiGetNominalContinuousStates", "nx", nx, NUMBER_OF_STATES))
    return fmiError;
  if (nullPointer(comp, "fmiGetNominalContinuousStates", "x_nominal[]", x_nominal))
    return fmiError;
  x_nominal[0] = 1;
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiGetNominalContinuousStates: x_nominal[0..%d] = 1.0", nx-1);
  for (i=0; i<nx; i++)
    x_nominal[i] = 1;
  return fmiOK;
}

fmiStatus fmiGetDerivatives(fmiComponent c, fmiReal derivatives[], size_t nx) {
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetDerivatives", not_modelError))
    return fmiError;
  if (invalidNumber(comp, "fmiGetDerivatives", "nx", nx, NUMBER_OF_STATES))
    return fmiError;
  if (nullPointer(comp, "fmiGetDerivatives", "derivatives[]", derivatives))
    return fmiError;
  functionODE(comp->fmuData);
#if (NUMBER_OF_STATES>0)
  for (i=0; i<nx; i++) {
    fmiValueReference vr = vrStatesDerivatives[i];
    derivatives[i] = getReal(comp, vr); // to be implemented by the includer of this file
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiGetDerivatives: #r%d# = %.16g", vr, derivatives[i]);
  }
#endif
  return fmiOK;
}

fmiStatus fmiGetEventIndicators(fmiComponent c, fmiReal eventIndicators[], size_t ni) {
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetEventIndicators", not_modelError))
    return fmiError;
  if (invalidNumber(comp, "fmiGetEventIndicators", "ni", ni, NUMBER_OF_EVENT_INDICATORS))
    return fmiError;
#if NUMBER_OF_EVENT_INDICATORS>0
  function_onlyZeroCrossings(comp->fmuData,NULL,&(comp->fmuData->localData[0]->timeValue));
  for (i=0; i<ni; i++) {
    /* retVal = getEventIndicator(comp, i, eventIndicators[i]); // to be implemented by the includer of this file
     * getEventIndicator(comp, eventIndicators); // to be implemented by the includer of this file */
    eventIndicators[i] = comp->fmuData->simulationInfo.zeroCrossings[i];
    if (comp->loggingOn){
        comp->functions.logger(c, comp->instanceName, fmiOK, "log",
            "fmiGetEventIndicators: z%d = %.16g", i, eventIndicators[i]);
    }
  }
#endif
  return fmiOK;
}

// ---------------------------------------------------------------------------
// FMI functions: initialization, event handling, stepping and termination
// ---------------------------------------------------------------------------

fmiStatus fmiSetInitMethod(fmiComponent c, fmiString initMethod)
{
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiSetInitMethod", modelInstantiated))
    return fmiError;
  if (strlen(initMethod) > 100) {
	  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiError, "log",
	      "fmiSetInitMethod: sorry strings larger than 100 characters are not supported.");
    return fmiError;
  }
  strcpy(comp->initialisation.initMethod,initMethod);
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiSetInitMethod: %c", comp->initialisation.initMethod);
  return fmiOK;
}

fmiStatus fmiSetOptiMethod(fmiComponent c, fmiString optiMethod)
{
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiSetOptiMethod", modelInstantiated))
    return fmiError;
  if (strlen(optiMethod) > 100) {
	  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiError, "log",
	      "fmiSetOptiMethod: sorry strings larger than 100 characters are not supported.");
    return fmiError;
  }
  strcpy(comp->initialisation.optiMethod,optiMethod);
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiSetOptiMethod: %c", comp->initialisation.optiMethod);
  return fmiOK;
}

fmiStatus fmiSetInitFile(fmiComponent c, fmiString initFile)
{
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiSetInitFile", modelInstantiated))
    return fmiError;
  if (strlen(initFile) > 255) {
	  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiError, "log",
	      "fmiSetInitFile: sorry strings larger than 255 characters are not supported.");
    return fmiError;
  }
  strcpy(comp->initialisation.initFile,initFile);
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiSetInitFile: %c", comp->initialisation.initFile);
  return fmiOK;
}

fmiStatus fmiInitialize(fmiComponent c, fmiBoolean toleranceControlled, fmiReal relativeTolerance,
    fmiEventInfo* eventInfo) {
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiInitialize", modelInstantiated))
    return fmiError;
  if (nullPointer(comp, "fmiInitialize", "eventInfo", eventInfo))
    return fmiError;
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiInitialize: toleranceControlled=%d relativeTolerance=%g",
      toleranceControlled, relativeTolerance);
  *eventInfo  = comp->eventInfo;

  setStartValues(comp);
  copyStartValuestoInitValues(comp->fmuData);
  /* read input vars */
  //input_function(comp->fmuData);
  /* initial sample and delay before initial the system */
  callExternalObjectConstructors(comp->fmuData);
  /*TODO: Simulation stop time is need to calculate in before hand all sample events
          We shouldn't generate them all in beforehand */
  initSample(comp->fmuData, comp->fmuData->localData[0]->timeValue,  100 /*should be stopTime*/);
  initDelay(comp->fmuData, comp->fmuData->localData[0]->timeValue);

  if (initialization(comp->fmuData, comp->initialisation.initMethod, comp->initialisation.optiMethod,comp->initialisation.initFile,0)){
    comp->state = modelError;
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiInitialization: failed");
  } else {
    comp->state = modelInitialized;
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiInitialization: succeed");
  }
  /* due to an event overwrite old values */
  overwriteOldSimulationData(comp->fmuData);
  resetAllHelpVars(comp->fmuData);

  return fmiOK;
}

fmiStatus fmiEventUpdate(fmiComponent c, fmiBoolean intermediateResults, fmiEventInfo* eventInfo) {
  int needtoiterate=0;
  double nextSampleEvent=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiEventUpdate", modelInitialized))
    return fmiError;
  if (nullPointer(comp, "fmiEventUpdate", "eventInfo", eventInfo))
    return fmiError;

  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiEventUpdate: Start Event Update! Next Sample Event %g",eventInfo->nextEventTime);


  storePreValues(comp->fmuData);
  functionDAE(comp->fmuData, &needtoiterate);

  /*
  if (comp->loggingOn){
    int i, n = comp->fmuData->modelData.nHelpVars;
    for(i=0;i < n; i++ ){
      comp->functions.logger(c, comp->instanceName, fmiOK, "log",
              "after: %d. simulationInfo.helpVars = %c\t simulationInfo.helpVarsPre= %c",
              i,  comp->fmuData->simulationInfo.helpVars[i]?'T':'F',
              comp->fmuData->simulationInfo.helpVarsPre[i]?'T':'F');
  }
  }
   */

  //Activate sample and evaluate again
  if (activateSampleEvents(comp->fmuData)){
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiEventUpdate: Sample Event!");
    storePreValues(comp->fmuData);
    functionDAE(comp->fmuData, &needtoiterate);
    deactivateSampleEventsandEquations(comp->fmuData);
  }
  if(checkForDiscreteChanges(comp->fmuData) || needtoiterate){
    intermediateResults = fmiTrue;
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiEventUpdate: Need to iterate(discrete changes)!");
    eventInfo->iterationConverged  = fmiFalse;
    eventInfo->stateValueReferencesChanged = fmiFalse;
    eventInfo->stateValuesChanged  = fmiTrue;
    eventInfo->terminateSimulation = fmiFalse;
  }else{
    intermediateResults = fmiFalse;
    eventInfo->iterationConverged  = fmiFalse;
    eventInfo->stateValueReferencesChanged = fmiFalse;
    eventInfo->stateValuesChanged  = fmiFalse;
    eventInfo->terminateSimulation = fmiFalse;
  }

  /* due to an event overwrite old values */
  overwriteOldSimulationData(comp->fmuData);

  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiEventUpdate: intermediateResults = %d", intermediateResults);

  //Get Next Event TIme
  nextSampleEvent = getNextSampleTimeFMU(comp->fmuData);
  if (nextSampleEvent == -1){
    eventInfo->upcomingTimeEvent = fmiFalse;
  }else{
    eventInfo->upcomingTimeEvent = fmiTrue;
    eventInfo->nextEventTime = nextSampleEvent;
  }
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiEventUpdate: Checked for Sample Events! Next Sample Event %g",eventInfo->nextEventTime);

  return fmiOK;
}

fmiStatus fmiCompletedIntegratorStep(fmiComponent c, fmiBoolean* callEventUpdate){
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiCompletedIntegratorStep", modelInitialized))
    return fmiError;
  if (nullPointer(comp, "fmiCompletedIntegratorStep", "callEventUpdate", callEventUpdate))
    return fmiError;
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiCompletedIntegratorStep");
  functionAlgebraics(comp->fmuData);
  function_storeDelayed(comp->fmuData);
  return fmiOK;
}

fmiStatus fmiTerminate(fmiComponent c){
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiTerminate", modelInitialized))
    return fmiError;
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiTerminate");

  /* deinitDelay(comp->fmuData); */
  callExternalObjectDestructors(comp->fmuData);
  DeinitializeDataStruc(comp->fmuData);
  free(comp->fmuData);

  comp->state = modelTerminated;
  return fmiOK;
}

// ---------------------------------------------------------------------------
// FMI functions: set external functions
// ---------------------------------------------------------------------------

fmiStatus fmiSetExternalFunction(fmiComponent c, fmiValueReference vr[], size_t nvr, const void* value[])
{
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiTerminate", modelInstantiated))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiSetExternalFunction", "vr[]", vr))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiSetExternalFunction", "value[]", value))
    return fmiError;
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiSetExternalFunction");
  // no check wether setting the value is allowed in the current state
  for (i=0; i<nvr; i++) {
    if (vrOutOfRange(comp, "fmiSetExternalFunction", vr[i], NUMBER_OF_EXTERNALFUNCTIONS))
      return fmiError;
    if (setExternalFunction(comp, vr[i],value[i]) != fmiOK) // to be implemented by the includer of this file
      return fmiError;
  }
  return fmiOK;
}

// relation functions used in zero crossing detection
fmiReal
FmiLess(fmiReal a, fmiReal b)
{
  return a - b;
}

fmiReal
FmiLessEq(fmiReal a, fmiReal b)
{
  return a - b;
}

fmiReal
FmiGreater(fmiReal a, fmiReal b)
{
  return b - a;
}

fmiReal
FmiGreaterEq(fmiReal a, fmiReal b)
{
  return b - a;
}
