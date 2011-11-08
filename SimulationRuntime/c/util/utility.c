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


#include "utility.h"

int in_range_integer(modelica_integer i,
         modelica_integer start,
         modelica_integer stop)
{
  if (start <= stop) if ((i >= start) && (i <= stop)) return 1;
  if (start > stop) if ((i >= stop) && (i <= start)) return 1;
  return 0;
}

int in_range_real(modelica_real i,
      modelica_real start,
      modelica_real stop)
{
  if (start <= stop) if ((i >= start) && (i <= stop)) return 1;
  if (start > stop) if ((i >= stop) && (i <= start)) return 1;
  return 0;
}

modelica_real modelica_div(modelica_real x, modelica_real y)
{
  return (modelica_real)((modelica_integer)(x/y));
}

modelica_real modelica_mod_real(modelica_real x, modelica_real y)
{
  return (x - floor(x/y) * y);
}

modelica_integer modelica_mod_integer(modelica_integer x, modelica_integer y)
{
  return x % y;
}

modelica_real modelica_rem_real(modelica_real x, modelica_real y)
{
  return x - y*(modelica_div(x,y));
}

modelica_integer modelica_rem_integer(modelica_integer x, modelica_integer y)
{
  return x - y*((x/y));
}

modelica_integer modelica_integer_min(modelica_integer x,modelica_integer y)
{
  return x<y ? x : y;
}

modelica_integer modelica_integer_max(modelica_integer x,modelica_integer y)
{
  return x>y ? x : y;
}

modelica_real real_int_pow(modelica_real base, modelica_integer n)
{
  modelica_real result = 1.0;
  modelica_integer m = n<0;
  if (m) n = -n;
  while (n) {
    if (n%2) {
      result *= base;
      n--;
    }
    base *= base;
    n /= 2;
  }
  return m ? 1/result : result;
}
