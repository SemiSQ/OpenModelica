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

#ifndef REAL_ARRAY_H_
#define REAL_ARRAY_H_


#include "openmodelica.h"
#include "base_array.h"
#include "memory_pool.h"
#include "index_spec.h"
#include <stdarg.h>

/* Indexing 1 dimensions */
extern modelica_real real_get(const real_array_t *a, size_t i);
/* Indexing 2 dimensions */
extern modelica_real real_get_2D(const real_array_t *a, size_t i, size_t j);
/* Indexing 3 dimensions */
extern modelica_real real_get_3D(const real_array_t *a, size_t i, size_t j, size_t k);
/* Indexing 4 dimensions */
extern modelica_real real_get_4D(const real_array_t *a, size_t i, size_t j, size_t k, size_t l);

/* Setting the fields of a real_array */
extern void real_array_create(real_array_t *dest, modelica_real *data, int ndims, ...);

/* Allocation of a vector */
extern void simple_alloc_1d_real_array(real_array_t* dest, int n);

/* Allocation of a matrix */
extern void simple_alloc_2d_real_array(real_array_t* dest, int r, int c);

extern void alloc_real_array(real_array_t* dest,int ndims,...);

/* Allocation of real data */
extern void alloc_real_array_data(real_array_t* a);

/* Frees memory*/
extern void free_real_array_data(real_array_t* a);

/* Clones data*/
static inline void clone_real_array_spec(const real_array_t *src, real_array_t* dst)
{ clone_base_array_spec(src, dst); }

/* Copy real data*/
extern void copy_real_array_data(const real_array_t * source, real_array_t* dest);

/* Copy real data given memory ptr*/
extern void copy_real_array_data_mem(const real_array_t * source, modelica_real* dest);

/* Copy real array*/
extern void copy_real_array(const real_array_t * source, real_array_t* dest);

void fill_real_array_from_range(real_array_t *dest, modelica_real start, modelica_real step, 
                                modelica_real stop/*, size_t dim*/);

extern modelica_real* calc_real_index(int ndims, const _index_t* idx_vec, const real_array_t * arr);
extern modelica_real* calc_real_index_va(const real_array_t * source,int ndims,va_list ap);

extern void put_real_element(modelica_real value,int i1,real_array_t* dest);
extern void put_real_matrix_element(modelica_real value, int r, int c, real_array_t* dest);

extern void print_real_matrix(const real_array_t * source);
extern void print_real_array(const real_array_t * source);
/*

 a[1:3] := b;

*/
extern void indexed_assign_real_array(const real_array_t * source,
             real_array_t* dest,
             const index_spec_t* dest_spec);
extern void simple_indexed_assign_real_array1(const real_array_t * source,
               int i1,
               real_array_t* dest);
extern void simple_indexed_assign_real_array2(const real_array_t * source,
               int i1, int i2,
               real_array_t* dest);

/*

 a := b[1:3];

*/
extern void index_real_array(const real_array_t * source,
                      const index_spec_t* source_spec,
                      real_array_t* dest);
extern void index_alloc_real_array(const real_array_t * source,
                            const index_spec_t* source_spec,
                            real_array_t* dest);

extern void simple_index_alloc_real_array1(const real_array_t * source, int i1,
                                    real_array_t* dest);

extern void simple_index_real_array1(const real_array_t * source,
                              int i1,
                              real_array_t* dest);
extern void simple_index_real_array2(const real_array_t * source,
                              int i1, int i2,
                              real_array_t* dest);

/* array(A,B,C) for arrays A,B,C */
extern void array_real_array(real_array_t* dest,int n,real_array_t* first,...);
extern void array_alloc_real_array(real_array_t* dest,int n,real_array_t* first,...);

/* array(s1,s2,s3)  for scalars s1,s2,s3 */
extern void array_scalar_real_array(real_array_t* dest,int n,modelica_real first,...);
extern void array_alloc_scalar_real_array(real_array_t* dest,int n,modelica_real first,...);

extern modelica_real* real_array_element_addr(const real_array_t * source,int ndims,...);
extern modelica_real* real_array_element_addr1(const real_array_t * source,int ndims,int dim1);
extern modelica_real* real_array_element_addr2(const real_array_t * source,int ndims,int dim1,int dim2);

extern void cat_real_array(int k,real_array_t* dest, int n, real_array_t* first,...);
extern void cat_alloc_real_array(int k,real_array_t* dest, int n, real_array_t* first,...);

extern void range_alloc_real_array(modelica_real start,modelica_real stop,modelica_real inc,
                            real_array_t* dest);
extern void range_real_array(modelica_real start,modelica_real stop, modelica_real inc,real_array_t* dest);

extern void add_alloc_real_array(const real_array_t * a, const real_array_t * b,real_array_t* dest);
extern void add_real_array(const real_array_t * a, const real_array_t * b, real_array_t* dest);

/* Unary subtraction */
extern void usub_real_array(real_array_t* a);
extern void sub_real_array(const real_array_t * a, const real_array_t * b, real_array_t* dest);
extern void sub_alloc_real_array(const real_array_t * a, const real_array_t * b, real_array_t* dest);

extern void sub_real_array_data_mem(const real_array_t * a, const real_array_t * b,
                             modelica_real* dest);

extern void mul_scalar_real_array(modelica_real a,const real_array_t * b,real_array_t* dest);
extern void mul_alloc_scalar_real_array(modelica_real a,const real_array_t * b,
                                 real_array_t* dest);

extern void mul_real_array_scalar(const real_array_t * a,modelica_real b,real_array_t* dest);
extern void mul_alloc_real_array_scalar(const real_array_t * a,modelica_real b,
                                 real_array_t* dest);

extern modelica_real mul_real_scalar_product(const real_array_t * a, const real_array_t * b);

extern void mul_real_matrix_product(const real_array_t *a,const real_array_t *b,real_array_t*dest);
extern void mul_real_matrix_vector(const real_array_t * a, const real_array_t * b,
                            real_array_t* dest);
extern void mul_real_vector_matrix(const real_array_t * a, const real_array_t * b,
                            real_array_t* dest);
extern void mul_alloc_real_matrix_product_smart(const real_array_t * a, const real_array_t * b,
                                         real_array_t* dest);

extern void div_real_array_scalar(const real_array_t * a,modelica_real b,real_array_t* dest);
extern void div_alloc_real_array_scalar(const real_array_t * a,modelica_real b,
                                 real_array_t* dest);

extern void division_real_array_scalar(const real_array_t * a,modelica_real b,real_array_t* dest, const char* division_str);
extern void division_alloc_real_array_scalar(const real_array_t * a,modelica_real b,
                                 real_array_t* dest, const char* division_str);

extern void exp_real_array(const real_array_t * a, modelica_integer n, real_array_t* dest);
extern void exp_alloc_real_array(const real_array_t * a, modelica_integer b,
                          real_array_t* dest);

extern void promote_real_array(const real_array_t * a, int n,real_array_t* dest);
extern void promote_scalar_real_array(modelica_real s,int n,real_array_t* dest);
extern void promote_alloc_real_array(const real_array_t * a, int n, real_array_t* dest);

static inline int ndims_real_array(const real_array_t * a)
{ return ndims_base_array(a); }
static inline int size_of_dimension_real_array(real_array_t a, int i)
{ return size_of_dimension_base_array(a, i); }
static inline modelica_real *data_of_real_array(const real_array_t *a)
{ return (modelica_real *) a->data; }

extern void size_real_array(const real_array_t * a,integer_array_t* dest);
extern modelica_real scalar_real_array(const real_array_t * a);
extern void vector_real_array(const real_array_t * a, real_array_t* dest);
extern void vector_real_scalar(modelica_real a,real_array_t* dest);
extern void matrix_real_array(const real_array_t * a, real_array_t* dest);
extern void matrix_real_scalar(modelica_real a,real_array_t* dest);
extern void transpose_alloc_real_array(const real_array_t * a, real_array_t* dest);
extern void transpose_real_array(const real_array_t * a, real_array_t* dest);
extern void outer_product_real_array(const real_array_t * v1,const real_array_t * v2,
                              real_array_t* dest);
extern void identity_real_array(int n, real_array_t* dest);
extern void diagonal_real_array(const real_array_t * v,real_array_t* dest);
extern void fill_real_array(real_array_t* dest,modelica_real s);
extern void linspace_real_array(modelica_real x1,modelica_real x2,int n,
                         real_array_t* dest);
extern modelica_real min_real_array(const real_array_t * a);
extern modelica_real max_real_array(const real_array_t * a);
extern modelica_real sum_real_array(const real_array_t * a);
extern modelica_real product_real_array(const real_array_t * a);
extern void symmetric_real_array(const real_array_t * a,real_array_t* dest);
extern void cross_real_array(const real_array_t * x,const real_array_t * y, real_array_t* dest);
extern void cross_alloc_real_array(const real_array_t * x,const real_array_t * y, real_array_t* dest);
extern void skew_real_array(const real_array_t * x,real_array_t* dest);

static inline size_t real_array_nr_of_elements(const real_array_t *a)
{ return base_array_nr_of_elements(a); }

static inline void clone_reverse_real_array_spec(const real_array_t *source,
                                                 real_array_t *dest)
{ clone_reverse_base_array_spec(source, dest); }
extern void convert_alloc_real_array_to_f77(const real_array_t * a, real_array_t* dest);
extern void convert_alloc_real_array_from_f77(const real_array_t * a, real_array_t* dest);

extern void cast_integer_array_to_real(const integer_array_t * a, real_array_t * dest);
extern void cast_real_array_to_integer(const real_array_t * a, integer_array_t * dest);

extern void fill_alloc_real_array(real_array_t* dest, modelica_real value, int ndims, ...);

extern void identity_alloc_real_array(int n, real_array_t* dest);

#endif
