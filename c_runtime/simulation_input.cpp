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

#include "simulation_input.h"
#include "simulation_runtime.h"
#include "options.h"

#include <fstream>
#include <iomanip>
#include <string.h>

using namespace std;

void read_commented_value(ifstream &f, double *res);
void read_commented_value(ifstream &f, modelica_integer *res);
void read_commented_value(ifstream &f, string *str);
void read_commented_value(ifstream &f, const char **str);
void read_commented_value(ifstream &f, signed char *str);


/* \brief
 *  Reads initial values from a text file.
 *
 *  The textfile should be given as argument to the main function using
 *  the -f file flag.
 */
 void read_input(int argc, char **argv,
 				DATA *simData,
                double *start, double *stop,
                double *stepSize, long *outputSteps,
                double *tolerance, string* method, string* outputFormat)
{

  string *filename=(string*)getFlagValue("f",argc,argv);
  if (filename == NULL) {
    filename = new string(string(simData->modelName)+"_init.txt");  // model_name defined in generated code for model.
  }

  ifstream file(filename->c_str());
  if (!file) {
    cerr << "Error, can not read file " << *filename << " as indata to simulation." << endl;
    EXIT(-1);
  }
  //  cerr << "opened file" << endl;
  read_commented_value(file,start);
  if (sim_verbose) { cout << "read start = " << *start << " from init file." << endl; }
  read_commented_value(file,stop);
  if (sim_verbose) { cout << "read stop = " << *stop << " from init file." << endl; }
  read_commented_value(file,stepSize);
  if (sim_verbose) { cout << "read stepSize = " << *stepSize << " from init file." << endl; }
  globalData->current_stepsize = *stepSize;
  if (stepSize < 0) { // stepSize < 0 => Automatic number of outputs
  	*outputSteps = -1;
  } else {
  	// Calculate outputSteps from stepSize, start and stop
    *outputSteps = (long)(int(*stop-*start) /(*stepSize));
  }
  read_commented_value(file,tolerance);
  if (sim_verbose) { cout << "read tolerance = " << *tolerance << " from init file." << endl; }
  read_commented_value(file,method);
  if (sim_verbose) { cout << "read method = " << *method << " from init file." << endl; }
  read_commented_value(file,outputFormat);
  if (sim_verbose) { cout << "read outputFormat = " << *outputFormat << " from init file." << endl; }
  modelica_integer nxchk,nychk,npchk;
  modelica_integer nyintchk,npintchk;
  modelica_integer nyboolchk,npboolchk;
  modelica_integer nystrchk,npstrchk;
  read_commented_value(file,&nxchk);
  read_commented_value(file,&nychk);
  read_commented_value(file,&npchk);
  read_commented_value(file,&npintchk);
  read_commented_value(file,&nyintchk);
  read_commented_value(file,&npboolchk);
  read_commented_value(file,&nyboolchk);
  read_commented_value(file,&npstrchk);
  read_commented_value(file,&nystrchk);

  if (nxchk != simData->nStates || nychk != simData->nAlgebraic || npchk != simData->nParameters
  		|| npintchk != simData->intVariables.nParameters || nyintchk != simData->intVariables.nAlgebraic
  		|| npboolchk != simData->boolVariables.nParameters || nyboolchk != simData->boolVariables.nAlgebraic
  		|| npstrchk != simData->stringVariables.nParameters || nystrchk != simData->stringVariables.nAlgebraic) {
    cerr << "Error, input data file does not match model." << endl;
    cerr << "nx in initfile: " << nxchk << " from model code :" << simData->nStates << endl;
    cerr << "ny in initfile: " << nychk << " from model code :" << simData->nAlgebraic << endl;
    cerr << "np in initfile: " << npchk << " from model code :" << simData->nParameters << endl;
    cerr << "npint in initfile: " << npintchk << " from model code: " << simData->intVariables.nParameters << endl;
    cerr << "nyint in initfile: " << nyintchk << " from model code: " << simData->intVariables.nAlgebraic <<  endl;
    cerr << "npbool in initfile: " << npboolchk << " from model code: " << simData->boolVariables.nParameters << endl;
    cerr << "nybool in initfile: " << nyboolchk << " from model code: " << simData->boolVariables.nAlgebraic <<  endl;
    cerr << "npstr in initfile: " << npstrchk << " from model code: " << simData->stringVariables.nParameters << endl;
    cerr << "nystr in initfile: " << nystrchk << " from model code: " << simData->stringVariables.nAlgebraic <<  endl;
    EXIT(-1);
  }
  for(int i = 0; i < simData->nStates; i++) { // Read x initial values
    read_commented_value(file,&simData->states[i]);
    if (sim_verbose) {
    cout << "read " << getName(&simData->states[i]) << " = "
    	<< simData->states[i] << " from init file." << endl;
    }
  }
  for(int i = 0; i < simData->nStates; i++) { // Read der(x) initial values
    read_commented_value(file,&simData->statesDerivatives[i]);
    if (sim_verbose) {
    cout << "read " << getName(&simData->statesDerivatives[i]) << " = "
    	<< simData->statesDerivatives[i] << " from init file." << endl;
    }
  }
  for(int i = 0; i < simData->nAlgebraic; i++) { // Read y initial values
    read_commented_value(file,&simData->algebraics[i]);
    if (sim_verbose) {
    cout << "read " << getName(&simData->algebraics[i]) << " = "
    	<< simData->algebraics[i] << " from init file." << endl;
    }
  }
  for(int i = 0; i < simData->nParameters; i++) { // Read parameter values
    read_commented_value(file,&simData->parameters[i]);
    if (sim_verbose) {
    cout << "read " << getName(&simData->parameters[i]) << " = "
    << simData->parameters[i] << " from init file." << endl;
    }
  }

  for(int i = 0; i < simData->intVariables.nParameters; i++) { // Read parameter values
    read_commented_value(file,&simData->intVariables.parameters[i]);
    if (sim_verbose) {
    cout << "read " << getName(&simData->intVariables.parameters[i]) << " = "
    << simData->intVariables.parameters[i] << " from init file." << endl;
    }
  }

  for(int i = 0; i < simData->intVariables.nAlgebraic; i++) { // Read parameter values
    read_commented_value(file,&simData->intVariables.algebraics[i]);
    if (sim_verbose) {
    cout << "read " << getName(&simData->intVariables.algebraics[i]) << " = "
    << simData->intVariables.algebraics[i] << " from init file." << endl;
    }
  }

  for(int i = 0; i < simData->boolVariables.nParameters; i++) { // Read parameter values
    read_commented_value(file,&simData->boolVariables.parameters[i]);
    if (sim_verbose) {
    cout << "read " << getName(&simData->boolVariables.parameters[i]) << " = "
    << (bool)simData->boolVariables.parameters[i] << " from init file." << endl;
    }
  }

  for(int i = 0; i < simData->boolVariables.nAlgebraic; i++) { // Read parameter values
    read_commented_value(file,&simData->boolVariables.algebraics[i]);
    if (sim_verbose) {
    cout << "read " << getName(&simData->boolVariables.algebraics[i]) << " = "
    << (bool)simData->boolVariables.algebraics[i] << " from init file." << endl;
    }
  }

  for(int i=0; i < simData->stringVariables.nParameters; i++) { // Read string parameter values
    read_commented_value(file,&(simData->stringVariables.parameters[i]));
    if (sim_verbose) {
    cout << "read " << getName((double*)&simData->stringVariables.parameters[i]) << " = \"" << simData->stringVariables.parameters[i] << "\" from init file." << endl;
    }
  }
  for(int i=0; i < simData->stringVariables.nAlgebraic; i++) { // Read string algebraic values
    read_commented_value(file,&simData->stringVariables.algebraics[i]);
    if (sim_verbose) {
    cout << "read " << simData->stringVariables.algebraics[i] << " from init file." << endl;
    }
  }
  file.close();
  if (sim_verbose) {
    cout << "Read parameter data from file " << *filename << endl;
  }
  delete filename;
}

inline void read_commented_value(ifstream &f, string *str)
{

	string line;
	char c[160];
  	f.getline(c,160);
  	line = c;
  	int pos;
	if (line.find("\"") != line.npos) {
		pos = line.rfind("\""); // find end of string
		*str = string(line.substr(1,pos-1));	// Remove " at beginning and end
	}
}

inline void read_commented_value(ifstream &f, const char **str)
{
	if (str == NULL) {
		cerr << "error read_commented_value, no data allocated for storing string" << endl;
		return;
	}
	string line;
	read_commented_value(f,&line);
	*str = strdup(line.c_str());
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

inline void read_commented_value( ifstream &f, signed char *res)
{
  string line;
//  f >> *res;
  char c[160];
  f.getline(c,160);
  line = c;

  if (line.find("true") != line.npos) {
	  *res = 1;
  }
  else if (line.find("false") != line.npos) {
	  *res = 0;
  }
  else {
	*res = 0;
    //*res = atof(c);
  }
}

inline void read_commented_value( ifstream &f, modelica_integer *res)
{
  f >> *res;
  char c[160];
  f.getline(c,160);
}



