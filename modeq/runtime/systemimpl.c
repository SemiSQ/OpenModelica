#include "rml.h"
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <sys/unistd.h>
#include <sys/stat.h>
#include "read_write.h"
#include "../values.h"

char * cc="/usr/bin/gcc";
char * cflags="-I$MOSHHOME/../c_runtime -L$MOSHHOME/../c_runtime -lc_runtime -lm";

void * generate_array(char,int,type_description *,void *data);
float next_realelt(float*);
int next_intelt(int*);

void System_5finit(void)
{

}

RML_BEGIN_LABEL(System__compile_5fc_5ffile)
{
  char* str = RML_STRINGDATA(rmlA0);
  char command[255];
  char exename[255];
  assert(strlen(str) < 255);
  if (cc == NULL||cflags == NULL) {
    /* RMLFAIL */
  }
  memcpy(exename,str,strlen(str)-2);
  exename[strlen(str)-2]='\0';

  sprintf(command,"%s %s -o %s %s",cc,str,exename,cflags);
  printf("compile using: %s\n",command);
 if (system(command) != 0) {
    /* RMLFAIL */
  }
       
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__set_5fc_5fcompiler)
{
  char* str = RML_STRINGDATA(rmlA0);
  if (cc != NULL) {
    free(cc);
  }
  cc = (char*)malloc(strlen(str)+1);
  assert(cc != NULL);
  memcpy(cc,str,strlen(str)+1);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__set_5fc_5fflags)
{
  char* str = RML_STRINGDATA(rmlA0);
  if (cflags != NULL) {
    free(cflags);
  }
  cflags = (char*)malloc(strlen(str)+1);
  assert(cflags != NULL);
  memcpy(cflags,str,strlen(str)+1);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__execute_5ffunction)
{
  char* str = RML_STRINGDATA(rmlA0);
  char command[255];
  int ret_val;
  sprintf(command,"./%s %s_in.txt %s_out.txt",str,str,str);
  ret_val = system(command);
  
  assert(ret_val == 0);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__system_5fcall)
{
  char* str = RML_STRINGDATA(rmlA0);
  int ret_val;
  ret_val = system(str);

  rmlA0 = (void*) mk_icon(ret_val);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__cd)
{
  char* str = RML_STRINGDATA(rmlA0);
  int ret_val;
  ret_val = chdir(str);

  rmlA0 = (void*) mk_icon(ret_val);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__pwd)
{
  char buf[MAXPATHLEN];
  getcwd(buf,MAXPATHLEN);
  rmlA0 = (void*) mk_scon(buf);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__write_5ffile)
{
  char* data = RML_STRINGDATA(rmlA1);
  char* filename = RML_STRINGDATA(rmlA0);
  FILE * file=NULL;
  file = fopen(filename,"w");
  assert(file != NULL);
  fprintf(file,"%s",data);
  fclose(file);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__read_5ffile)
{
  char* filename = RML_STRINGDATA(rmlA0);
  char* buf;
  int res;
  FILE * file = NULL;
  struct stat statstr;
  res = stat(filename, &statstr);

  if(res!=0){
    rmlA0 = (void*) mk_scon("No such file");
    RML_TAILCALLK(rmlSC);
  }

  file = fopen(filename,"rb");
  buf = malloc(statstr.st_size+1);
 
 if( (res = fread(buf, sizeof(char), statstr.st_size, file)) != statstr.st_size){
    rmlA0 = (void*) mk_scon("Failed while reading file");
    RML_TAILCALLK(rmlSC);
  }

  fclose(file);
  rmlA0 = (void*) mk_scon(buf);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL



RML_BEGIN_LABEL(System__read_5fvalues_5ffrom_5ffile)
{
  type_description desc;
  void * res, *res2;
  int ival;
  float rval;
  float *rval_arr;
  int *ival_arr;
  int size;

  char* filename = RML_STRINGDATA(rmlA0);
  FILE * file=NULL;
  file = fopen(filename,"r");
  assert(file != NULL);
  
  read_type_description(file,&desc);
  
  if (desc.ndims == 0) /* Scalar value */ 
    {
      if (desc.type == 'i') {
	fscanf(file,"%d",&ival);
	res =(void*) Values__INTEGER(mk_icon(ival));
      } else if (desc.type == 'r') {
	fscanf(file,"%e",&rval);
	res = (void*) Values__REAL(mk_rcon(rval));
      } 
    } 
  else  /* Array value */
    {
      int currdim,el,i;
      if (desc.type == 'r') {
	/* Create array to hold inserted values, max dimension as size */
	size = 1;
	for (currdim=0;currdim < desc.ndims; currdim++) {
	  size *= desc.dim_size[currdim];
	}
	rval_arr = (float*)malloc(sizeof(float)*size);
	assert(rval_arr);
	/* Fill the array in reversed order */
	for(i=size-1;i>=0;i--) {
	  fscanf(file,"%e",&rval_arr[i]);
	}

	next_realelt(NULL);
	/* 1 is current dimension (start value) */
	res =(void*) Values__ARRAY(generate_array('r',1,&desc,(void*)rval_arr)); 
      }
	
      if (desc.type == 'i') {
	int currdim,el,i;
	/* Create array to hold inserted values, mult of dimensions as size */
	size = 1;
	for (currdim=0;currdim < desc.ndims; currdim++) {
	  size *= desc.dim_size[currdim];
	}
	ival_arr = (int*)malloc(sizeof(int)*size);
	assert(rval_arr);
	/* Fill the array in reversed order */
	for(i=size-1;i>=0;i--) {
	  fscanf(file,"%f",&ival_arr[i]);
	}
	next_intelt(NULL);
	res = (void*) Values__ARRAY(generate_array('i',1,&desc,(void*)ival_arr));
	
      }      
    }
  rmlA0 = (void*)res;
  RML_TAILCALLK(rmlSC);
}   
RML_END_LABEL

float next_realelt(float *arr)
{
  static int curpos;
  
  if(arr == NULL) {
    curpos = 0;
    return 0.0;
  }
  else {
    return arr[curpos++];
  }
}

int next_intelt(int *arr)
{
  static int curpos;
  
  if(arr == NULL) {
    curpos = 0;
    return 0.0;
  }
  else return arr[curpos++];
}

void * generate_array(char type, int curdim, type_description *desc,void *data)

{
  void *lst;
  float rval;
  int ival;
  int i;
  lst = (void*)mk_nil();
  if (curdim == desc->ndims) {
    for (i=0; i< desc->dim_size[curdim-1]; i++) {
      if (type == 'r') {
	rval = next_realelt((float*)data);
	lst = (void*)mk_cons(Values__REAL(mk_rcon(rval)),lst);
	
      } else if (type == 'i') {
	ival = next_intelt((int*)data);
	lst = (void*)mk_cons(Values__INTEGER(mk_icon(ival)),lst);
      }
    }
  } else {
    for (i=0; i< desc->dim_size[curdim-1]; i++) {
      lst = mk_cons(Values__ARRAY(generate_array(type,curdim+1,desc,data)),lst);
    }
  }
  return lst;
}
