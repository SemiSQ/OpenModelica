/*
// Copyright PELAB, Linkoping University
*/

#include "read_write.h"


void cleanup_description(type_description* desc)
{
  if (desc->ndims > 0)
    {
      free(desc->dim_size);
    }
}

void in_report(const char *str)
{
  fprintf(stderr,"input failed: %s\n",str);
}

void read_to_eol(FILE* file)
{
  int c;
  while (((c = fgetc(file)) != '\n') && (c != EOF));
}

int read_type_description(FILE* file, type_description* desc)
{
  int c;
  int i;
  do 
    {
      if ((c = fgetc(file)) == EOF) return 1;
      if (c != '#') return 1;
      if ((c = fgetc(file)) == EOF) return 1;
      if (c != ' ') return 1;
      if ((c = fgetc(file)) == EOF) return 1;
      switch (c)
	{
	case 'i': /* integer */
	case 'r': /* real */
	case 'b': /* boolean */
	case 's': /* string */
	  desc->type = c;
	  break;
	default:
	  return 1;	  
	}
      if ((c = fgetc(file)) == EOF) return 1;
      if (c == '!') /* scalar */
	{
	  /* Scalar string */
	  if (desc->type == 's') {
	    if (fscanf(file,"%d",&desc->ndims) != 1) return 1;
	    desc->dim_size = (int*)malloc(desc->ndims*sizeof(int));
	    if (!desc->dim_size) return 1;
	    if (fscanf(file,"%d",desc->dim_size) != 1) return 1;
	    break;
	  } 
	  else {
	    /* other scalars. */
	    desc->ndims = 0;
	    desc->dim_size = 0;
	    break;
	  }
	}
      if (c != '[') return 1;
      /* now is an array dim description */
      if (fscanf(file,"%d",&desc->ndims) != 1) return 1;
      if (desc->ndims < 0) return 1;
      if (desc->ndims > 0)
	{
	  desc->dim_size = (int*)malloc(desc->ndims*sizeof(int));
	  if (!desc->dim_size) return 1;
	}
      else
	{
	  desc->dim_size = 0;
	}
      for (i = 0; i < desc->ndims; ++i)
	{
	  if (fscanf(file,"%d",&desc->dim_size[i]) != 1)
	    {
	      free(desc->dim_size);
	      return 1;
	    }	  
	}
      break;
      
    } while (0);

  read_to_eol(file);

  return 0;
}



int read_modelica_real(FILE* file, modelica_real* data)
{
  float f;
  type_description desc;
  if (read_type_description(file,&desc)) { in_report("rs type_desc"); return 1; }
  if ((desc.type != 'r') && (desc.type != 'i')) { cleanup_description(&desc); in_report("rs type"); return 1; }
  if (desc.ndims != 0) { cleanup_description(&desc); in_report("rs dims"); return 1; }
  if (fscanf(file,"%e",&f) != 1) { cleanup_description(&desc); in_report("rs parse"); return 1; }
  *data = f;
  read_to_eol(file);
  cleanup_description(&desc);
  return 0;
}

int read_modelica_integer(FILE* file, modelica_integer* data)
{
  type_description desc;
  if (read_type_description(file,&desc)) { in_report("is type_desc"); return 1; }
  if (desc.type != 'i') { cleanup_description(&desc); in_report("is type"); return 1; }
  if (desc.ndims != 0) { cleanup_description(&desc); in_report("is ndims"); return 1; }
  if (fscanf(file,"%d",data) != 1) { cleanup_description(&desc); in_report("is parse"); return 1; }
  read_to_eol(file);
  cleanup_description(&desc);
  return 0;
}

int read_real_array(FILE* file, real_array_t* arr)
{
  int nr_elements;
  int i;
  float f;
  real_array_t tmp;
  type_description desc;

  if (read_type_description(file,&desc)) { in_report("ra type_desc"); return 1; }
  if ((desc.type != 'r') && (desc.type != 'i')) { in_report("ra type"); return 1; }
  if (desc.ndims <= 0) { in_report("ra ndims"); return 1; }
  
  tmp.ndims = desc.ndims;
  tmp.dim_size = desc.dim_size;
  clone_real_array_spec(&tmp,arr);
  alloc_real_array_data(arr);
  cleanup_description(&desc);

  nr_elements = real_array_nr_of_elements(arr);
  for (i = 0; i < nr_elements; ++i)
    {
      if (fscanf(file,"%e",&f) != 1) { in_report("ra parse"); return 1; }
      arr->data[i] = f;
    }
  read_to_eol(file);
  return 0;
}
/*
void read_integer_array(FILE* file, integer_array_t* arr)
{
  int nr_elements;
  int i;
  nr_elements = integer_array_nr_of_elements(arr);
  for (i = 0; i < nr_elements; ++i)
    {
      fscanf(file,"%d",arr->data + i);
    }
}
*/
int write_modelica_real(FILE* file, modelica_real* data)
{
  fprintf(file,"# r!\n");
  fprintf(file,"%e\n",*data);
  return 0;
}

int write_modelica_integer(FILE* file, modelica_integer* data)
{
  fprintf(file,"# i!\n");
  fprintf(file,"%d\n",*data);
  return 0;
}

int write_real_array(FILE* file, real_array_t* arr)
{
  int nr_elements;
  int i;
  fprintf(file,"# r[ %d",arr->ndims);
  for (i = 0; i < arr->ndims; ++i) fprintf(file," %d",arr->dim_size[i]);
  fprintf(file,"\n");
  nr_elements = real_array_nr_of_elements(arr);
  for (i = 0; i < nr_elements; ++i)
    {
      fprintf(file,"%e\n",arr->data[i]);
    }
  return 0;
}
/*
void write_integer_array(FILE* file, integer_array_t* arr)
{
  int nr_elements;
  int i;
  fprintf(file,"# i[ %d",arr->ndims);
  for (i = 0; i < arr->ndims; ++i) fprintf(file," %d",arr->dim_size[i]);
  fprintf(file,"\n");
  nr_elements = integer_array_nr_of_elements(arr);
  for (i = 0; i < nr_elements; ++i)
    {
      fprintf(file,"%d\n",arr->data[i]);
    }
    return 0;
}
*/

int read_modelica_string(FILE* file, modelica_string_t* str)
{
  int length;
  int i;
  char c;
  type_description desc;
  modelica_string_t tmp;

  if (read_type_description(file,&desc)) { in_report("ms type_desc"); return 1; }
  if (desc.type != 's') { cleanup_description(&desc); in_report("ms type"); return 1; }
  if (desc.ndims != 1) { cleanup_description(&desc); in_report("ms ndims"); return 1; }

  tmp.length = desc.dim_size[0];
  clone_modelica_string_spec(&tmp, str);
  alloc_modelica_string_data(str);
  cleanup_description(&desc);
  
  length = modelica_string_length(str);
  for (i = 0; i< length; ++i) {
    if (fscanf(file,"%c",&c) != 1) { in_report("ms parse"); return 1; }
    str->data[i] = c;
  }
  read_to_eol(file);
  return 0;
}

int write_modelica_string(FILE* file, modelica_string_t* str)
{
  fprintf(file,"# s! %d %d", 1, str->length);
  fprintf(file,"\n");
  fprintf(file,"%s\n",str->data);
  return 0;
}
