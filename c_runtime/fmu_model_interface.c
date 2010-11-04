// implementation of the Model Exchange functions

/******************************************************************************/
const char* fmiGetModelTypesPlatform()
/******************************************************************************/
{
  return fmiModelTypesPlatform;
};
/******************************************************************************/

/******************************************************************************/
DllExport const char* fmiGetVersion()
/******************************************************************************/
{
  return fmiVersion;
};
/******************************************************************************/


/******************************************************************************/
DllExport fmiComponent fmiInstantiateModel (fmiString            instanceName,
                                            fmiString            GUID,
                                            fmiCallbackFunctions functions,
                                            fmiBoolean           loggingOn)
/******************************************************************************/
{
  // instanceName string must be non-empty
  if (instanceName==NULL) return NULL;

  // test GUID
  if (1) return NULL;
  // store instanceName
	
};
/******************************************************************************/

/******************************************************************************/
DllExport void fmiFreeModelInstance(fmiComponent c)
/******************************************************************************/
{

};
/******************************************************************************/

/******************************************************************************/
DllExport fmiStatus fmiSetDebugLogging(fmiComponent c, fmiBoolean loggingOn)
/******************************************************************************/
{
  return fmiError;
};
/******************************************************************************/


/******************************************************************************/
DllExport fmiStatus fmiSetTime(fmiComponent c, fmiReal time)
/******************************************************************************/
{
  return fmiError;
};
/******************************************************************************/

/******************************************************************************/
DllExport fmiStatus fmiSetContinuousStates(fmiComponent c, const fmiReal x[], size_t nx)
/******************************************************************************/
{
  return fmiError;
};
/******************************************************************************/

/******************************************************************************/
DllExport fmiStatus fmiCompletedIntegratorStep(fmiComponent c, fmiBoolean* callEventUpdate)
/******************************************************************************/
{
  return fmiError;
};
/******************************************************************************/

/******************************************************************************/
DllExport fmiStatus fmiSetReal(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiReal    value[])
/******************************************************************************/
{
	if(checkInvalidState(model, "fmiGetString", modelInstantiated|modelInitialized)
		return fmiError;
};
/******************************************************************************/

/******************************************************************************/
DllExport fmiStatus fmiSetInteger(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiInteger value[])
/******************************************************************************/
{
	if(checkInvalidState(model, "fmiGetString", modelInstantiated|modelInitialized)
		return fmiError;
};
/******************************************************************************/

/******************************************************************************/
DllExport fmiStatus fmiSetBoolean(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiBoolean value[])
/******************************************************************************/
{
	if(checkInvalidState(model, "fmiGetString", modelInstantiated|modelInitialized)
		return fmiError;
};
/******************************************************************************/

/******************************************************************************/
DllExport fmiStatus fmiSetString(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiString  value[])
/******************************************************************************/
{
	if(checkInvalidState(model, "fmiGetString", modelInstantiated|modelInitialized)
		return fmiError;
};
/******************************************************************************/



/******************************************************************************/
DllExport fmiStatus fmiInitialize(fmiComponent c, fmiBoolean toleranceControlled,
                                  fmiReal relativeTolerance, fmiEventInfo* eventInfo)
/******************************************************************************/
{
  return fmiError;
};
/******************************************************************************/


/******************************************************************************/
DllExport fmiStatus fmiGetDerivatives(fmiComponent c, fmiReal derivatives[]    , size_t nx)
/******************************************************************************/
{
  return fmiError;
};
/******************************************************************************/

/******************************************************************************/
DllExport fmiStatus fmiGetEventIndicators(fmiComponent c, fmiReal eventIndicators[], size_t ni)
/******************************************************************************/
{
  return fmiError;
};
/******************************************************************************/


/******************************************************************************/
DllExport fmiStatus fmiGetReal(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiReal    value[])
/******************************************************************************/
{
	if(checkInvalidState(model, "fmiGetString", modelInstantiated|modelInitialized|modelTerminated)
		return fmiError;
};
/******************************************************************************/

/******************************************************************************/
DllExport fmiStatus fmiGetInteger(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiInteger value[])
/******************************************************************************/
{
	if(checkInvalidState(model, "fmiGetString", modelInstantiated|modelInitialized|modelTerminated)
		return fmiError;
};
/******************************************************************************/

/******************************************************************************/
DllExport fmiStatus fmiGetBoolean(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiBoolean value[])
/******************************************************************************/
{
	if(checkInvalidState(model, "fmiGetString", modelInstantiated|modelInitialized|modelTerminated)
		return fmiError;
};
/******************************************************************************/

/******************************************************************************/
DllExport fmiStatus fmiGetString(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiString  value[])
/******************************************************************************/
{
	if(checkInvalidState(model, "fmiGetString", modelInstantiated|modelInitialized|modelTerminated)
		return fmiError;
};
/******************************************************************************/


/******************************************************************************/
DllExport fmiStatus fmiEventUpdate(fmiComponent c, fmiBoolean intermediateResults, fmiEventInfo* eventInfo)
/******************************************************************************/
{
  return fmiError;
};
/******************************************************************************/

/******************************************************************************/
DllExport fmiStatus fmiGetContinuousStates(fmiComponent c, fmiReal states[], size_t nx)
/******************************************************************************/
{
  return fmiError;
};
/******************************************************************************/

/******************************************************************************/
DllExport fmiStatus fmiGetNominalContinuousStates(fmiComponent c, fmiReal x_nominal[], size_t nx)
/******************************************************************************/
{
  return fmiError;
};
/******************************************************************************/

/******************************************************************************/
DllExport fmiStatus fmiGetStateValueReferences(fmiComponent c, fmiValueReference vrx[], size_t nx)
/******************************************************************************/
{
  return fmiError;
};
/******************************************************************************/

/******************************************************************************/
DllExport fmiStatus fmiTerminate(fmiComponent c)
/******************************************************************************/
{
  return fmiError;
};
/******************************************************************************/


fmiBoolean checkInvalidState((ModelData* model, const char* f, int safeStates)
/******************************************************************************/
{
	if(!model)
		return fmiTrue;
	else if(!(model->state & sateStates)
	{
		model->state = modelError;
		return fmiTrue;
	}
	else
		return fmiFalse;
}
/******************************************************************************/
