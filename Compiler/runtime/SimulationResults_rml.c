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

#include <stdlib.h>
#include "rml.h"
#include "Values.h"
#include "ValuesUtil.h"

#include "SimulationResults.c"

void SimulationResults_5finit(void)
{
}

RML_BEGIN_LABEL(SimulationResults__readVariables)
{
  rml_sint_t i,size;
  char* filename = RML_STRINGDATA(rmlA0);

  rmlA0 = SimulationResultsImpl__readVars(filename);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(SimulationResults__readDataset)
{
  rmlA0 = (void*)SimulationResultsImpl__readDataset(RML_STRINGDATA(rmlA0),rmlA1,RML_UNTAGFIXNUM(rmlA2));
  
  if (rmlA0 == NULL) {
    RML_TAILCALLK(rmlFC);
  }

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(SimulationResults__readSimulationResultSize)
{
  char* filename = RML_STRINGDATA(rmlA0);
  rmlA0 = mk_icon(SimulationResultsImpl__readSimulationResultSize(filename));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(SimulationResults__val)
{
  rmlA0 = mk_rcon(SimulationResultsImpl__val(RML_STRINGDATA(rmlA0),RML_STRINGDATA(rmlA1),rml_prim_get_real(rmlA2)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(SimulationResults__close)
{
  SimulationResultsImpl__close();
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

