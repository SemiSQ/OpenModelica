#ifndef REAL_ARRAY_H_
#define REAL_ARRAY_H_

#include "integer_array.h"
#include "index_spec.h"
#include "memory_pool.h"

typedef double modelica_real;

struct real_array_s
{
  int ndims;
  int* dim_size;
  modelica_real* data;
};

typedef struct real_array_s real_array_t;


/* Allocation of a vector */
void simple_alloc_1d_real_array(real_array_t* dest, int n);

/* Allocation of a matrix */
void simple_alloc_2d_real_array(real_array_t*, int r, int c);

void alloc_real_array(real_array_t* dest,int ndims,...);

/* Allocation of real data */
void alloc_real_array_data(real_array_t*);

/* Frees memory*/
void free_real_array_data(real_array_t*);

/* Clones data*/
void clone_real_array_spec(real_array_t* source, real_array_t* dest);

/* Copy real data*/
void copy_real_array_data(real_array_t* source, real_array_t* dest);

void put_real_element(real value,int i1,real_array_t* dest);
void put_matrix_element(real value, int r, int c, real_array_t* dest);

void print_real_matrix(real_array_t* source);
void print_real_array(real_array_t* source);
/*

 a[1:3] := b;

*/
void indexed_assign_real_array(real_array_t* source, 
			       real_array_t* dest,

			       index_spec_t* spec);
void simple_indexed_assign_real_array1(real_array_t* source, 
				       int, 
				       real_array_t* dest);
void simple_indexed_assign_real_array2(real_array_t* source, 
				       int, int, 
				       real_array_t* dest);

/*

 a := b[1:3];

*/
void index_real_array(real_array_t* source, 
			       index_spec_t* spec, 
			       real_array_t*);
void simple_index_real_array1(real_array_t* source, 
				       int, 
				       real_array_t* dest);
void simple_index_real_array2(real_array_t* source, 
				       int, int, 
				       real_array_t* dest);

void modelica_builtin_cat_real_array(int k, real_array_t* A, real_array_t* B);

void add_real_array(real_array_t* a, real_array_t* b, real_array_t* dest);
void sub_real_array(real_array_t* a, real_array_t* b, real_array_t* dest);

void mul_scalar_real_array(modelica_real a,real_array_t* b,real_array_t* dest);
void mul_real_array_scalar(real_array_t* a,modelica_real b,real_array_t* dest);
double mul_real_scalar_product(real_array_t* a, real_array_t* b);
void mul_real_matrix_product(real_array_t*a,real_array_t*b,real_array_t*dest);
void mul_real_matrix_vector(real_array_t* a, real_array_t* b,real_array_t* dest);
void mul_real_vector_matrix(real_array_t* a, real_array_t* b,real_array_t* dest);

void div_real_array_scalar(real_array_t* a,modelica_real b,real_array_t* dest);

void exp_real_array(real_array_t* a, modelica_integer b, real_array_t* dest);

void promote_real_array(real_array_t* a, int n,real_array_t* dest);
void promote_real_scalar(double s,int n,real_array_t* dest);

int ndims_real_array(real_array_t* a);
int size_of_dimension_real_array(real_array_t* a, int i);
void size_real_array(real_array_t* a,real_array_t* dest);
double scalar_real_array(real_array_t* a);
void vector_real_array(real_array_t* a, real_array_t* dest);
void vector_real_scalar(double a,real_array_t* dest);
void matrix_real_array(real_array_t* a, real_array_t* dest);
void matrix_real_scalar(double a,real_array_t* dest);
void transpose_real_array(real_array_t* a, real_array_t* dest);
void outer_product_real_array(real_array_t* v1,real_array_t* v2,real_array_t* dest);
void identity_real_array(int n, real_array_t* dest);
void diagonal_real_array(real_array_t* v,real_array_t* dest);
void fill_real_array(real_array_t* dest,modelica_real s);
void linspace_real_array(double x1,double x2,int n,real_array_t* dest);
double min_real_array(real_array_t* a);
double max_real_array(real_array_t* a);
double sum_real_array(real_array_t* a);
double product_real_array(real_array_t* a);
void symmetric_real_array(real_array_t* a,real_array_t* dest);
void cross_real_array(real_array_t* x,real_array_t* y, real_array_t* dest);
void skew_real_array(real_array_t* x,real_array_t* dest);

#endif
