/* 
 * This file is part of OpenModelica.
 * 
 * Copyright (c) 1998-2008, Link�pings University,
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

#ifndef BOOLEAN_ARRAY_H_
#define BOOLEAN_ARRAY_H_

#include "index_spec.h"
#include "memory_pool.h"
#include <stdio.h>
#include <stdarg.h>
#include <math.h>

typedef signed char modelica_boolean;

struct boolean_array_s
{
  int ndims;
  int* dim_size;
  modelica_boolean* data;
};

typedef struct boolean_array_s boolean_array_t;

size_t boolean_array_nr_of_elements(boolean_array_t* a);

void alloc_boolean_array_data(boolean_array_t* a);
void array_alloc_scalar_boolean_array(boolean_array_t* dest,int n,modelica_boolean first,...);
void simple_alloc_1d_boolean_array(boolean_array_t* dest, int n);
void put_boolean_element(modelica_boolean value,int i1,boolean_array_t* dest);

m_boolean* calc_boolean_index_va(boolean_array_t* source,int ndims,va_list ap);

m_boolean* boolean_array_element_addr(boolean_array_t* source,int ndims,...);
m_boolean* boolean_array_element_addr1(boolean_array_t* source,int ndims,int dim1);
m_boolean* boolean_array_element_addr2(boolean_array_t* source,int ndims,int dim1,int dim2);

int size_of_dimension_boolean_array(boolean_array_t a, int i);

/*Frees memory*/
void free_boolean_array_data(boolean_array_t*);

void clone_boolean_array_spec(boolean_array_t* source, boolean_array_t* dest);

#endif
