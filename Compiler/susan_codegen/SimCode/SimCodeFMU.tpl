// This file defines templates for transforming Modelica/MetaModelica code to FMU 
// code. They are used in the code generator phase of the compiler to write
// target code.
//
// There are one root template intended to be called from the code generator:
// translateModel. These template do not return any
// result but instead write the result to files. All other templates return
// text and are used by the root templates (most of them indirectly).
//
// To future maintainers of this file:
//
// - A line like this
//     # var = "" /*BUFD*/
//   declares a text buffer that you can later append text to. It can also be
//   passed to other templates that in turn can append text to it. In the new
//   version of Susan it should be written like this instead:
//     let &var = buffer ""
//
// - A line like this
//     ..., Text var /*BUFP*/, ...
//   declares that a template takes a text buffer as input parameter. In the
//   new version of Susan it should be written like this instead:
//     ..., Text &var, ...
//
// - A line like this:
//     ..., var /*BUFC*/, ...
//   passes a text buffer to a template. In the new version of Susan it should
//   be written like this instead:
//     ..., &var, ...
//
// - Style guidelines:
//
//   - Try (hard) to limit each row to 80 characters
//
//   - Code for a template should be indented with 2 spaces
//
//     - Exception to this rule is if you have only a single case, then that
//       single case can be written using no indentation
//
//       This single case can be seen as a clarification of the input to the
//       template
//
//   - Code after a case should be indented with 2 spaces if not written on the
//     same line

package SimCodeFMU

import interface SimCodeTV;
import SimCodeC.*; //unqualified import, no need the SimCodeC is optional when calling a template; or mandatory when the same named template exists in this package (name hiding) 


template translateModel(SimCode simCode) 
 "Generates C code and Makefile for compiling a FMU of a
  Modelica model."
::=
match simCode
case SIMCODE(__) then
  let guid = getUUIDStr()
  let()= textFile(fmuModelDescriptionFile(simCode,guid), 'modelDescription.xml')
  let()= textFile(fmumodel_identifierFile(simCode,guid), '<%fileNamePrefix%>_FMU.cpp')
  let()= textFile(fmuMakefile(simCode), '<%fileNamePrefix%>_FMU.makefile')
  "" // Return empty result since result written to files directly
end translateModel;


template fmuModelDescriptionFile(SimCode simCode, String guid)
 "Generates code for ModelDescription file for FMU target."
::=
match simCode
case SIMCODE(__) then
  <<
  <?xml version="1.0" encoding="UTF-8"?>
  <%fmiModelDescription(simCode,guid)%>
  
  >>
end fmuModelDescriptionFile;

template fmiModelDescription(SimCode simCode, String guid)
 "Generates code for ModelDescription file for FMU target."
::=
//  <%UnitDefinitions(simCode)%>
//  <%TypeDefinitions(simCode)%>
//  <%VendorAnnotations(simCode)%>
match simCode
case SIMCODE(__) then
  <<
  <fmiModelDescription 
    <%fmiModelDescriptionAttributes(simCode,guid)%>>
    <%DefaultExperiment(simulationSettingsOpt)%>
    <%ModelVariables(modelInfo)%>  
  </fmiModelDescription>  
  >>
end fmiModelDescription;

template fmiModelDescriptionAttributes(SimCode simCode, String guid)
 "Generates code for ModelDescription file for FMU target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__))) then
  let fmiVersion = '1.0' 
  let modelName = dotPath(modelInfo.name)
  let modelIdentifier = fileNamePrefix
  let description = ''
  let author = ''
  let version= '' 
  let generationTool= 'OpenModelica Compiler <%getVersionNr()%>'
  let generationDateAndTime = xsdateTime(getCurrentDateTime())
  let variableNamingConvention= 'structured'
  let numberOfContinuousStates = vi.numStateVars //the same as modelInfo.varInfo.numStateVars without the vi binding; but longer
  let numberOfEventIndicators = vi.numZeroCrossings 
//  description="<%description%>" 
//    author="<%author%>" 
//    version="<%version%>" 
  << 
  fmiVersion="<%fmiVersion%>" 
  modelName="<%modelName%>"
  modelIdentifier="<%modelIdentifier%>" 
  guid="{<%guid%>}" 
  generationTool="<%generationTool%>" 
  generationDateAndTime="<%generationDateAndTime%>"
  variableNamingConvention="<%variableNamingConvention%>" 
  numberOfContinuousStates="<%numberOfContinuousStates%>" 
  numberOfEventIndicators="<%numberOfEventIndicators%>" 
  >>
end fmiModelDescriptionAttributes;

template xsdateTime(DateTime dt)
 "YYYY-MM-DDThh:mm:ssZ"
::=
  match dt
  case DATETIME(__) then '<%year%>-<%mon%>-<%mday%>T<%hour%>:<%min%>:<%sec%>Z'
end xsdateTime;


template UnitDefinitions(SimCode simCode)
 "Generates code for UnitDefinitions file for FMU target."
::=
match simCode
case SIMCODE(__) then
  <<
  <UnitDefinitions>
  </UnitDefinitions>  
  >>
end UnitDefinitions;

template TypeDefinitions(SimCode simCode)
 "Generates code for TypeDefinitions file for FMU target."
::=
match simCode
case SIMCODE(__) then
  <<
  <TypeDefinitions>
  </TypeDefinitions>  
  >>
end TypeDefinitions;

template DefaultExperiment(Option<SimulationSettings> simulationSettingsOpt)
 "Generates code for DefaultExperiment file for FMU target."
::=
match simulationSettingsOpt
  case SOME(v) then 
	<<
	<DefaultExperiment <%DefaultExperimentAttribute(v)%>/>
  	>>
end DefaultExperiment;

template DefaultExperimentAttribute(SimulationSettings simulationSettings)
 "Generates code for DefaultExperiment Attribute file for FMU target."
::=
match simulationSettings
  case SIMULATION_SETTINGS(__) then 
	<<
	startTime="<%startTime%>" stopTime="<%stopTime%>" tolerance="<%tolerance%>"
  	>>
end DefaultExperimentAttribute;

template VendorAnnotations(SimCode simCode)
 "Generates code for VendorAnnotations file for FMU target."
::=
match simCode
case SIMCODE(__) then
  <<
  <VendorAnnotations>
  </VendorAnnotations>  
  >>
end VendorAnnotations;

template ModelVariables(ModelInfo modelInfo)
 "Generates code for ModelVariables file for FMU target."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  <ModelVariables>
  <%vars.stateVars |> var =>
    ScalarVariable(var,"internal",1)
  ;separator="\n"%>  
  <%vars.derivativeVars |> var =>
    ScalarVariable(var,"internal",2)
  ;separator="\n"%>
  <%vars.algVars |> var =>
    ScalarVariable(var,"internal",3)
  ;separator="\n"%>
  <%vars.paramVars |> var =>
    ScalarVariable(var,"internal",4)
  ;separator="\n"%>
  <%vars.intAlgVars |> var =>
	ScalarVariable(var,"internal",1)
  ;separator="\n"%>
  <%vars.intParamVars |> var =>
    ScalarVariable(var,"internal",2)
  ;separator="\n"%>
  <%vars.boolAlgVars |> var =>
    ScalarVariable(var,"internal",1)
  ;separator="\n"%>
  <%vars.boolParamVars |> var =>
    ScalarVariable(var,"internal",2)
  ;separator="\n"%>  
  <%vars.stringAlgVars |> var =>
    ScalarVariable(var,"internal",1)
  ;separator="\n"%>
  <%vars.stringParamVars |> var =>
    ScalarVariable(var,"internal",2)
  ;separator="\n"%> 
  </ModelVariables>  
  >>
end ModelVariables;

template ScalarVariable(SimVar simVar, String causality, String offset)
 "Generates code for ScalarVariable file for FMU target."
::=
match simVar
case SIMVAR(__) then
  <<
  <ScalarVariable 
    <%ScalarVariableAttribute(simVar,causality,offset)%>>
    <%ScalarVariableType(type_,unit,displayUnit,initialValue,isFixed)%>
  </ScalarVariable>  
  >>
end ScalarVariable;

template ScalarVariableAttribute(SimVar simVar, String causality, String offset)
 "Generates code for ScalarVariable Attribute file for FMU target."
::=
match simVar
  case SIMVAR(__) then
  let valueReference = '<%offset%><%index%>'
  let variability = getVariablity(varKind)
  let description = if comment then 'description="<%comment%>"' 
  let alias = 'noAlias'  //TODO get the right information about alias {noAlias,alias,negatedAlias}
  <<
  name="<%crefStr(name)%>" 
  valueReference="<%valueReference%>" 
  <%description%>
  variability="<%variability%>" 
  causality="<%causality%>" 
  alias="<%alias%>"
  >>  
end ScalarVariableAttribute;

template getVariablity(VarKind varKind)
 "Returns the variablity Attribute of ScalarVariable."
::=
match varKind
  case DISCRETE(__) then "discrete"
  case PARAM(__) then "parameter"
  case CONST(__) then "constant"
  else "continuous"
end getVariablity;

template ScalarVariableType(DAE.ExpType type_, String unit, String displayUnit, Option<DAE.Exp> initialValue, Boolean isFixed)
 "Generates code for ScalarVariable Type file for FMU target."
::=
match type_
  case ET_INT(__) then '<Integer/>' 
  case ET_REAL(__) then '<Real <%ScalarVariableTypeCommonAttribute(initialValue,isFixed)%> <%ScalarVariableTypeRealAttribute(unit,displayUnit)%>/>' 
  case ET_BOOL(__) then '<Boolean/>' 
  case ET_STRING(__) then '<String/>' 
  case ET_ENUMERATION(__) then '<Enumeration/>' 
  else 'UNKOWN_TYPE'
end ScalarVariableType;

template ScalarVariableTypeCommonAttribute(Option<DAE.Exp> initialValue, Boolean isFixed)
 "Generates code for ScalarVariable Type file for FMU target."
::=
match initialValue
  case SOME(exp) then 'start="<%SimCodeC.initVal(exp)%>" fixed="<%isFixed%>"'
end ScalarVariableTypeCommonAttribute;

template ScalarVariableTypeRealAttribute(String unit, String displayUnit)
 "Generates code for ScalarVariable Type Real file for FMU target."
::=
  let unit_ = if unit then 'unit="<%unit%>"'   
  let displayUnit_ = if displayUnit then 'displayUnit="<%displayUnit%>"'   
  <<
  <%unit_%> <%displayUnit_%>
  >>
end ScalarVariableTypeRealAttribute;


template fmumodel_identifierFile(SimCode simCode, String guid)
 "Generates code for ModelDescription file for FMU target."
::=
match simCode
case SIMCODE(__) then
  <<
  
  // define class name and unique id
  #define MODEL_IDENTIFIER <%fileNamePrefix%>
  #define MODEL_GUID "<%guid%>"
  
  // include fmu header files, typedefs and macros
  #include "fmiModelFunctions.h"
  
  // implementation of the Model Exchange functions
  #include "fmu_model_interface.c"
  
  <%ModelDefineData(modelInfo)%>
  <%setStartValues(simCode)%>
  <%initializeFunction(simCode)%>
  <%eventUpdateFunction(simCode)%>
  
  >>
end fmumodel_identifierFile;

template ModelDefineData(ModelInfo modelInfo)
 "Generates global data in simulation file."
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__), vars=SIMVARS(__)) then
let numberOfReals = intAdd(varInfo.numStateVars,intAdd(varInfo.numAlgVars,varInfo.numParams))
let numberOfIntegers = intAdd(varInfo.numIntAlgVars,varInfo.numIntParams)
let numberOfStrings = intAdd(varInfo.numStringAlgVars,varInfo.numStringParamVars)
let numberOfBooleans = intAdd(varInfo.numBoolAlgVars,varInfo.numBoolParams)
  <<
  // define model size
  #define NUMBER_OF_STATES <%varInfo.numStateVars%>
  #define NUMBER_OF_EVENT_INDICATORS <%varInfo.numZeroCrossings%>
  #define NUMBER_OF_REALS <%numberOfReals%>
  #define NUMBER_OF_INTEGERS <%numberOfIntegers%>
  #define NUMBER_OF_STRINGS <%numberOfStrings%>
  #define NUMBER_OF_BOOLEANS <%numberOfBooleans%>
  
  // define variable data for model
  <%vars.stateVars |> var => DefineStateVariables(var) ;separator="\n"%>
  <%vars.inputVars |> var => DefineVariables(var) ;separator="\n"%>
  <%vars.outputVars |> var => DefineVariables(var) ;separator="\n"%>
  <%vars.algVars |> var => DefineVariables(var) ;separator="\n"%>
  <%vars.paramVars |> var => DefineVariables(var) ;separator="\n"%>
  <%vars.intAlgVars |> var => DefineVariables(var) ;separator="\n"%>
  <%vars.intParamVars |> var => DefineVariables(var) ;separator="\n"%>
  <%vars.boolAlgVars |> var => DefineVariables(var) ;separator="\n"%>
  <%vars.boolParamVars |> var => DefineVariables(var) ;separator="\n"%>
  <%vars.stringAlgVars |> var => DefineVariables(var) ;separator="\n"%>
  <%vars.stringParamVars |> var => DefineVariables(var) ;separator="\n"%>
  
  // define initial state vector as vector of value references
  #define STATES { <%vars.stateVars |> SIMVAR(__) => '<%crefStr(name)%>_'  ;separator=", "%> }
  
  >>
end ModelDefineData;

template DefineStateVariables(SimVar simVar)
 "Generates code for defining variables in c file for FMU target.  "
::=
match simVar
  case SIMVAR(__) then
  <<
  #define <%crefStr(name)%>_
  #define der_<%crefStr(name)%>_
  >>
end DefineStateVariables;

template DefineVariables(SimVar simVar)
 "Generates code for defining variables in c file for FMU target. "
::=
match simVar
  case SIMVAR(__) then
  <<
  #define <%crefStr(name)%>_ 
  >>
end DefineVariables;

template setStartValues(SimCode simCode)
 "Generates code in c file for function setStartValues() which will set start values for all variables." 
::=
match simCode
case SIMCODE(__) then
  <<
  // Set values for all variables that define a start value
  void setStartValues(ModelInstance *comp) {
  }
  
  >>
end setStartValues;

template initializeFunction(SimCode simCode)
 "Generates initialize function for c file."
::= 
match simCode
case SIMCODE(__) then
  <<
  // Used to set the first time event, if any.
  void initialize(ModelInstance* comp, fmiEventInfo* eventInfo) { 
  }
  
  >>
end initializeFunction;

template eventUpdateFunction(SimCode simCode)
 "Generates eventupdate function for c file."
::=
match simCode
case SIMCODE(__) then
  <<
  // Used to set the next time event, if any.
  void eventUpdate(ModelInstance* comp, fmiEventInfo* eventInfo) {
  }
  
  >>
end eventUpdateFunction;

template fmuMakefile(SimCode simCode)
 "Generates the contents of the makefile for the simulation case."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__)) then
  let dirExtra = if modelInfo.directory then '-L"<%modelInfo.directory%>"' //else ""
  let libsStr = (makefileParams.libs |> lib => lib ;separator=" ")
  let libsPos1 = if not dirExtra then libsStr //else ""
  let libsPos2 = if dirExtra then libsStr // else ""
  <<
  # Makefile generated by OpenModelica
  
  CC=<%makefileParams.ccompiler%>
  CXX=<%makefileParams.cxxcompiler%>
  LINK=<%makefileParams.linker%>
  EXEEXT=<%makefileParams.exeext%>
  DLLEXT=<%makefileParams.dllext%>
  CFLAGS=-I"<%makefileParams.omhome%>/include/omc" <%makefileParams.cflags%>
  LDFLAGS=-L"<%makefileParams.omhome%>/lib/omc" <%makefileParams.ldflags%>
  SENDDATALIBS=<%makefileParams.senddatalibs%>
  
  .PHONY: <%fileNamePrefix%>
  <%fileNamePrefix%>: <%fileNamePrefix%>.cpp
  <%\t%> $(CXX) $(CFLAGS) -I. -o <%fileNamePrefix%>$(DLLEXT) <%fileNamePrefix%>.cpp <%dirExtra%> <%libsPos1%> -lsim $(LDFLAGS) -lf2c -linteractive $(SENDDATALIBS) <%libsPos2%>
  >>
end fmuMakefile;

end SimCodeFMU;

// vim: filetype=susan sw=2 sts=2
