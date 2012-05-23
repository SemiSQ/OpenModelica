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

/*! \file initialization_data.h
 */

#ifndef _INITIALIZATION_DATA_H_
#define _INITIALIZATION_DATA_H_

#include "simulation_data.h"

#include "omc_error.h"

typedef struct INIT_DATA
{
  /* vars */
  long nz;
  long nStates;
  long nParameters;
  double* z;            /* unscaled */
  double* zScaled;      /* scaled */
  double* start;
  double* min;
  double* max;
  double* nominal;
  char** name;

  /* equations */
  long nInitResiduals;
  long nStartValueResiduals;
  double *initialResiduals;
  double *residualScalingCoefficients;
  double *startValueResidualScalingCoefficients;
}INIT_DATA;

#ifdef __cplusplus
#include <cstdlib>
extern "C"
{
#endif

extern INIT_DATA *initializeInitData(DATA *data);
extern void freeInitData(INIT_DATA *initData);

extern void computeInitialResidualScalingCoefficients(DATA *data, INIT_DATA *initData);

extern void updateZ(INIT_DATA *data);
extern void updateZScaled(INIT_DATA *data);

extern void setZ(INIT_DATA *data, double *z);
extern void setZScaled(INIT_DATA *data,  double *zScaled);

#ifdef __cplusplus
}
#endif

#endif
