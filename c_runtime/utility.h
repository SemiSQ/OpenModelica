/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Link�ping University,
 * Department of Computer and Information Science,
 * SE-58183 Link�ping, Sweden.
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
 * from Link�ping University, either from the above address,
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


#ifndef UTILITY_H
#define UTILITY_H

#include "modelica.h"

int in_range_integer(modelica_integer i,
  	     modelica_integer start,
  	     modelica_integer stop);

int in_range_real(modelica_real i,
  	  modelica_real start,
  	  modelica_real stop);

/* div is already defined in stdlib, so it's redefined here to modelica_div */
modelica_real modelica_div(modelica_real x, modelica_real y);
/* fmod in math.h does not work in the same way as mod defined by modelica, so
 * we need to define our own mod. */
modelica_real modelica_mod_real(modelica_real x, modelica_real y);
modelica_integer modelica_mod_integer(modelica_integer x, modelica_integer y);

modelica_real modelica_rem_real(modelica_real x, modelica_real y);
modelica_integer modelica_rem_integer(modelica_integer x, modelica_integer y);

#endif
