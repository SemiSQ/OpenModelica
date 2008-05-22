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

#include "read_write.h"
#include <string.h>

static void in_report(const char *str)
{
  fprintf(stderr, "input failed: %s\n", str);
}

static type_description *add_tuple_item(type_description *desc);

void init_type_description(type_description *desc)
{
  desc->type = TYPE_DESC_NONE;
  desc->retval = 0;
  memset(&(desc->data), 0, sizeof(desc->data));
}

void free_type_description(type_description *desc)
{
  switch (desc->type) {
  case TYPE_DESC_NONE:
    break;
  case TYPE_DESC_REAL:
  case TYPE_DESC_INT:
  case TYPE_DESC_BOOL:
    break;
  case TYPE_DESC_STRING:
    if (desc->retval)
      free(desc->data.string);
    else
      free_modelica_string(&(desc->data.string));
    break;
  case TYPE_DESC_REAL_ARRAY:
    if (desc->retval) {
      free(desc->data.real_array.dim_size);
      free(desc->data.real_array.data);
    } else
      free_real_array_data(&(desc->data.real_array));
    break;
  case TYPE_DESC_INT_ARRAY:
    if (desc->retval) {
      free(desc->data.int_array.dim_size);
      free(desc->data.int_array.data);
    } else
      free_integer_array_data(&(desc->data.int_array));
    break;
  case TYPE_DESC_BOOL_ARRAY:
    if (desc->retval) {
      free(desc->data.bool_array.dim_size);
      free(desc->data.bool_array.data);
    } else
      free_boolean_array_data(&(desc->data.bool_array));
    break;
  case TYPE_DESC_STRING_ARRAY:
    if (desc->retval) {
      size_t i, cnt;
      cnt = string_array_nr_of_elements(&(desc->data.string_array));
      for (i = 0; i < cnt; ++i) {
        modelica_string s = ((modelica_string*)desc->data.string_array.data)[i];
        if (s) free(s);
      }
      free(desc->data.string_array.dim_size);
      free(desc->data.string_array.data);
    } else
      free_string_array_data(&(desc->data.string_array));
    break;
  case TYPE_DESC_TUPLE: {
    size_t i;
    type_description *e = desc->data.tuple.element;
    for (i = 0; i < desc->data.tuple.elements; ++i, ++e)
      free_type_description(e);
    if (desc->data.tuple.elements > 0)
      free(desc->data.tuple.element);
  }; break;
  case TYPE_DESC_COMPLEX:
    break;
  case TYPE_DESC_RECORD: {
    size_t i;
    type_description *e = desc->data.record.element;
    char **n = desc->data.record.name;
    for (i = 0; i < desc->data.record.elements; ++i, ++e, ++n) {
      free(*n);
      free_type_description(e);
    }
    if (desc->data.record.elements > 0) {
      free(desc->data.record.element);
      free(desc->data.record.name);
    }
  }; break;
  }
}

int read_modelica_real(type_description **descptr, modelica_real *data)
{
  type_description *desc = (*descptr)++;
  switch (desc->type) {
  case TYPE_DESC_REAL:
    *data = desc->data.real;
    return 0;
  case TYPE_DESC_INT:
    *data = desc->data.integer;
    return 0;
  default:
    break;
  }

  in_report("rs type");
  return -1;
}

int read_modelica_integer(type_description **descptr, modelica_integer *data)
{
  type_description *desc = (*descptr)++;
  switch (desc->type) {
  case TYPE_DESC_INT:
    *data = desc->data.integer;
    return 0;
  default:
    break;
  }

  in_report("is type");
  return -1;
}

int read_modelica_boolean(type_description **descptr, modelica_boolean *data)
{
  type_description *desc = (*descptr)++;
  switch (desc->type) {
  case TYPE_DESC_BOOL:
    *data = desc->data.boolean;
    return 0;
  default:
    break;
  }

  in_report("bs type");
  return -1;
}

int read_real_array(type_description **descptr, real_array_t *arr)
{
  type_description *desc = (*descptr)++;
  switch (desc->type) {
  case TYPE_DESC_REAL_ARRAY:
    *arr = desc->data.real_array;
    return 0;
  default:
    break;
  }

  in_report("ra type");
  return -1;
}

int read_integer_array(type_description **descptr, integer_array_t *arr)
{
  type_description *desc = (*descptr)++;
  switch (desc->type) {
  case TYPE_DESC_INT_ARRAY:
    *arr = desc->data.int_array;
    return 0;
  case TYPE_DESC_REAL_ARRAY:
    /* Empty arrays automaticly get to be real arrays */
    if (desc->data.real_array.dim_size[desc->data.real_array.ndims - 1] == 0) {
      int dims = desc->data.real_array.ndims;
      int *dim_size = desc->data.real_array.dim_size;
      free_real_array_data(&(desc->data.real_array));
      desc->type = TYPE_DESC_INT_ARRAY;
      desc->data.int_array.ndims = dims;
      desc->data.int_array.dim_size = dim_size;
      alloc_integer_array_data(&(desc->data.int_array));
      *arr = desc->data.int_array;
      return 0;
    }
    break;
  default:
    break;
  }

  in_report("ia type");
  return -1;
}

int read_boolean_array(type_description **descptr, boolean_array_t *arr)
{
  type_description *desc = (*descptr)++;
  switch (desc->type) {
  case TYPE_DESC_BOOL_ARRAY:
    *arr = desc->data.bool_array;
    return 0;
  case TYPE_DESC_REAL_ARRAY:
    /* Empty arrays automaticly get to be real arrays */
    if (desc->data.real_array.dim_size[desc->data.real_array.ndims - 1] == 0) {
      int dims = desc->data.real_array.ndims;
      int *dim_size = desc->data.real_array.dim_size;
      free_real_array_data(&(desc->data.real_array));
      desc->type = TYPE_DESC_BOOL_ARRAY;
      desc->data.bool_array.ndims = dims;
      desc->data.bool_array.dim_size = dim_size;
      alloc_boolean_array_data(&(desc->data.bool_array));
      *arr = desc->data.bool_array;
      return 0;
    }
    break;
  default:
    break;
  }

  in_report("ba type");
  return -1;
}

int read_string_array(type_description **descptr, string_array_t *arr)
{
  type_description *desc = (*descptr)++;
  switch (desc->type) {
  case TYPE_DESC_STRING_ARRAY:
    *arr = desc->data.string_array;
    return 0;
  case TYPE_DESC_REAL_ARRAY:
    /* Empty arrays automaticly get to be real arrays */
    if (desc->data.real_array.dim_size[desc->data.real_array.ndims - 1] == 0) {
      int dims = desc->data.real_array.ndims;
      int *dim_size = desc->data.real_array.dim_size;
      free_real_array_data(&(desc->data.real_array));
      desc->type = TYPE_DESC_STRING_ARRAY;
      desc->data.string_array.ndims = dims;
      desc->data.string_array.dim_size = dim_size;
      alloc_string_array_data(&(desc->data.string_array));
      *arr = desc->data.string_array;
      return 0;
    }
    break;
  default:
    break;
  }

  in_report("sa type");
  return -1;
}

void write_modelica_real(type_description *desc, modelica_real *data)
{
  if (desc->type != TYPE_DESC_NONE)
    desc = add_tuple_item(desc);
  desc->type = TYPE_DESC_REAL;
  desc->data.real = *data;
}

void write_modelica_integer(type_description *desc, modelica_integer *data)
{
  if (desc->type != TYPE_DESC_NONE)
    desc = add_tuple_item(desc);
  desc->type = TYPE_DESC_INT;
  desc->data.integer = *data;
}

void write_modelica_boolean(type_description *desc, modelica_boolean *data)
{
  if (desc->type != TYPE_DESC_NONE)
    desc = add_tuple_item(desc);
  desc->type = TYPE_DESC_BOOL;
  desc->data.boolean = *data;
}

void write_real_array(type_description *desc, real_array_t *arr)
{
  size_t nr_elements = 0;
  if (desc->type != TYPE_DESC_NONE)
    desc = add_tuple_item(desc);
  desc->type = TYPE_DESC_REAL_ARRAY;
  if (desc->retval) {
    /* Can't use memory pool for these */
    desc->data.real_array.ndims = arr->ndims;
    desc->data.real_array.dim_size = malloc(sizeof(*(arr->dim_size))
                                            * arr->ndims);
    memcpy(desc->data.real_array.dim_size, arr->dim_size,
           sizeof(*(arr->dim_size)) * arr->ndims);
    nr_elements = real_array_nr_of_elements(arr);
    desc->data.real_array.data = malloc(sizeof(modelica_real) * nr_elements);
    memcpy(desc->data.real_array.data, arr->data,
           sizeof(modelica_real) * nr_elements);
  } else {
    copy_real_array(arr, &(desc->data.real_array));
  }
}

void write_integer_array(type_description *desc, integer_array_t *arr)
{
  size_t nr_elements = 0;
  if (desc->type != TYPE_DESC_NONE)
    desc = add_tuple_item(desc);
  desc->type = TYPE_DESC_INT_ARRAY;
  if (desc->retval) {
    /* Can't use memory pool for these */
    desc->data.int_array.ndims = arr->ndims;
    desc->data.int_array.dim_size = malloc(sizeof(*(arr->dim_size))
                                           * arr->ndims);
    memcpy(desc->data.int_array.dim_size, arr->dim_size,
           sizeof(*(arr->dim_size)) * arr->ndims);
    nr_elements = integer_array_nr_of_elements(arr);
    desc->data.int_array.data = malloc(sizeof(modelica_integer) * nr_elements);
    memcpy(desc->data.int_array.data, arr->data,
           sizeof(modelica_integer) * nr_elements);
  } else {
    clone_integer_array_spec(arr, &(desc->data.int_array));
    copy_integer_array_data(arr, &(desc->data.int_array));
  }
}

void write_boolean_array(type_description *desc, boolean_array_t *arr)
{
  size_t nr_elements = 0;
  if (desc->type != TYPE_DESC_NONE)
    desc = add_tuple_item(desc);
  desc->type = TYPE_DESC_BOOL_ARRAY;
  if (desc->retval) {
    /* Can't use memory pool for these */
    desc->data.bool_array.ndims = arr->ndims;
    desc->data.bool_array.dim_size = malloc(sizeof(*(arr->dim_size))
                                            * arr->ndims);
    memcpy(desc->data.bool_array.dim_size, arr->dim_size,
           sizeof(*(arr->dim_size)) * arr->ndims);
    nr_elements = boolean_array_nr_of_elements(arr);
    desc->data.bool_array.data = malloc(sizeof(modelica_boolean) * nr_elements);
    memcpy(desc->data.bool_array.data, arr->data,
           sizeof(modelica_boolean) * nr_elements);
  } else {
    copy_boolean_array(arr, &(desc->data.bool_array));
  }
}

void write_string_array(type_description *desc, boolean_array_t *arr)
{
  size_t nr_elements = 0;
  if (desc->type != TYPE_DESC_NONE)
    desc = add_tuple_item(desc);
  desc->type = TYPE_DESC_STRING_ARRAY;
  if (desc->retval) {
    size_t i;
    modelica_string *dst = NULL, *src = NULL;
    desc->data.string_array.ndims = arr->ndims;
    desc->data.string_array.dim_size = malloc(sizeof(*(arr->dim_size))
                                              * arr->ndims);
    memcpy(desc->data.string_array.dim_size, arr->dim_size,
           sizeof(*(arr->dim_size)) * arr->ndims);
    nr_elements = string_array_nr_of_elements(arr);
    desc->data.string_array.data = malloc(sizeof(modelica_string)* nr_elements);
    dst = desc->data.string_array.data;
    src = arr->data;
    for (i = 0; i < nr_elements; ++i) {
      size_t len = modelica_string_length(src);
      *dst = malloc(len + 1);
      memcpy(*dst, *src, len + 1);
      ++src;
      ++dst;
    }
  } else {
    copy_string_array(arr, &(desc->data.string_array));
  }
}

int read_modelica_string(type_description **descptr, modelica_string_t *str)
{
  type_description *desc = (*descptr)++;
  switch (desc->type) {
  case TYPE_DESC_STRING:
    *str = desc->data.string;
    return 0;
  default:
    break;
  }

  in_report("ms type");
  return -1;
}

void write_modelica_string(type_description *desc, modelica_string_t *str)
{
  size_t len = 0;
  if (desc->type != TYPE_DESC_NONE)
    desc = add_tuple_item(desc);
  desc->type = TYPE_DESC_STRING;
  if (desc->retval) {
    /* Can't use memory pool */
    len = modelica_string_length(str);
    desc->data.string = malloc(len + 1);
    memcpy(desc->data.string, *str, len + 1);
  } else {
    copy_modelica_string(str, &(desc->data.string));
  }
}

int read_modelica_complex(type_description **descptr, modelica_complex *data)
{
  type_description *desc = (*descptr)++;
  switch (desc->type) {
  case TYPE_DESC_COMPLEX:
    *data = desc->data.complex;
    return 0;
  default:
    break;
  }

  in_report("mc type");
  return -1;
}

void write_modelica_complex(type_description *desc, modelica_complex *data)
{
  if (desc->type != TYPE_DESC_NONE)
    desc = add_tuple_item(desc);
  desc->type = TYPE_DESC_COMPLEX;
  desc->data.complex = *data;
}

int read_modelica_record(type_description **descptr, ...)
{
  type_description *desc = (*descptr)++;
  type_description *elem = NULL;
  size_t e;
  va_list arg;
  switch (desc->type) {
  case TYPE_DESC_RECORD:
    va_start(arg, descptr);
    elem = desc->data.record.element;
    for (e = 0; e < desc->data.record.elements; ++e) {
      switch (elem->type) {
      case TYPE_DESC_NONE:
        return -1;
      case TYPE_DESC_REAL:
        read_modelica_real(&elem, va_arg(arg, modelica_real *));
        break;
      case TYPE_DESC_REAL_ARRAY:
        read_real_array(&elem, va_arg(arg, real_array_t *));
        break;
      case TYPE_DESC_INT:
        read_modelica_integer(&elem, va_arg(arg, modelica_integer *));
        break;
      case TYPE_DESC_INT_ARRAY:
        read_integer_array(&elem, va_arg(arg, integer_array_t *));
        break;
      case TYPE_DESC_BOOL:
        read_modelica_boolean(&elem, va_arg(arg, modelica_boolean *));
        break;
      case TYPE_DESC_BOOL_ARRAY:
        read_boolean_array(&elem, va_arg(arg, boolean_array_t *));
        break;
      case TYPE_DESC_STRING:
        read_modelica_string(&elem, va_arg(arg, modelica_string_t *));
        break;
      case TYPE_DESC_STRING_ARRAY:
        read_string_array(&elem, va_arg(arg, string_array_t *));
        break;
      case TYPE_DESC_TUPLE:
        in_report("tuple in record is unsupported.");
        return -1;
      case TYPE_DESC_COMPLEX:
        read_modelica_complex(&elem, va_arg(arg, modelica_complex *));
        break;
      case TYPE_DESC_RECORD:
        in_report("record in record is unsupported.");
        return -1;
      }
    }
    va_end(arg);
    return 0;
  default:
    break;
  }

  in_report("mr type");
  return -1;
}

type_description *add_modelica_record_member(type_description *desc,
                                             const char *name, size_t nlen)
{
  type_description *elem;
  assert(desc->type == TYPE_DESC_RECORD);
  desc->data.record.name = realloc(desc->data.record.name, sizeof(char *)
                                   * (desc->data.record.elements + 1));
  desc->data.record.element = realloc(desc->data.record.element,
                                      sizeof(struct type_desc_s)
                                      * (desc->data.record.elements + 1));
  elem = desc->data.record.element + desc->data.record.elements;
  desc->data.record.name[desc->data.record.elements] = malloc(nlen + 1);
  memcpy(desc->data.record.name[desc->data.record.elements], name, nlen + 1);
  ++desc->data.record.elements;
  init_type_description(elem);
  return elem;
}

void write_modelica_record(type_description *desc, const char *name, ...)
{
  va_list arg;
  enum type_desc_e type;
  if (desc->type != TYPE_DESC_NONE)
    desc = add_tuple_item(desc);
  desc->type = TYPE_DESC_RECORD;
  desc->data.record.record_name = name;
  desc->data.record.elements = 0;
  desc->data.record.name = NULL;
  desc->data.record.element = NULL;
  va_start(arg, name);
  /* atleast small enums gets casted to ints */
  while ((type = (enum type_desc_e) va_arg(arg, int)) != TYPE_DESC_NONE) {
    type_description *elem;
    const char *name;
    size_t nlen;
    name = va_arg(arg, const char *);
    nlen = strlen(name);

    elem = add_modelica_record_member(desc, name, nlen);
    elem->retval = desc->retval;

    switch (type) {
    case TYPE_DESC_NONE:
      break;
    case TYPE_DESC_REAL:
      write_modelica_real(elem, va_arg(arg, modelica_real *));
      break;
    case TYPE_DESC_REAL_ARRAY:
      write_real_array(elem, va_arg(arg, real_array_t *));
      break;
    case TYPE_DESC_INT:
      write_modelica_integer(elem, va_arg(arg, modelica_integer *));
      break;
    case TYPE_DESC_INT_ARRAY:
      write_integer_array(elem, va_arg(arg, integer_array_t *));
      break;
    case TYPE_DESC_BOOL:
      write_modelica_boolean(elem, va_arg(arg, modelica_boolean *));
      break;
    case TYPE_DESC_BOOL_ARRAY:
      write_boolean_array(elem, va_arg(arg, boolean_array_t *));
      break;
    case TYPE_DESC_STRING:
      write_modelica_string(elem, va_arg(arg, modelica_string_t *));
      break;
    case TYPE_DESC_STRING_ARRAY:
      write_string_array(elem, va_arg(arg, string_array_t *));
      break;
    case TYPE_DESC_COMPLEX:
      write_modelica_complex(elem, va_arg(arg, modelica_complex *));
      break;
    case TYPE_DESC_TUPLE:
      in_report("tuple in record is unsupported.");
      assert(0);
      return;
    case TYPE_DESC_RECORD:
      in_report("record in record is unsupported.");
      assert(0);
      return;
    }
  }
  va_end(arg);
}

type_description *add_tuple_member(type_description *desc)
{
  type_description *ret = NULL;
  assert(desc->type == TYPE_DESC_TUPLE);
  desc->data.tuple.element = realloc(desc->data.tuple.element,
                                     (desc->data.tuple.elements + 1)
                                     * sizeof(struct type_desc_s));
  ret = desc->data.tuple.element + desc->data.tuple.elements;
  ++(desc->data.tuple.elements);
  init_type_description(ret);
  return ret;
}

type_description *add_tuple_item(type_description *desc)
{
  type_description *ret = NULL;

  if (desc->type == TYPE_DESC_TUPLE) {
    desc->data.tuple.element = realloc(desc->data.tuple.element,
                                       (desc->data.tuple.elements + 1)
                                       * sizeof(struct type_desc_s));
    ret = desc->data.tuple.element + desc->data.tuple.elements;
    ++(desc->data.tuple.elements);
  } else {
    struct type_desc_s tmp;
    memcpy(&tmp, desc, sizeof(tmp));
    desc->type = TYPE_DESC_TUPLE;
    desc->data.tuple.elements = 2;
    desc->data.tuple.element = malloc(2 * sizeof(struct type_desc_s));
    memcpy(desc->data.tuple.element, &tmp, sizeof(tmp));
    ret = desc->data.tuple.element + 1;
  }

  init_type_description(ret);
  ret->retval = desc->retval;
  return ret;
}
