/*
This file is part of OpenModelica.

Copyright (c) 1998-2006, Link�pings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

* Neither the name of Link�pings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/*
 * adrpo 2007-05-09
 * UNCOMMENT THIS ONLY IF YOU COMPILE OMC IN DEBUG MODE!!!!!
 * #define RML_DEBUG
 */ 

// windows and mingw32
#if defined(__MINGW32__) || defined(_MSC_VER)

#include <stdlib.h>
#include <direct.h>
#include <assert.h>
#include <string.h>
#include <time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include "read_write.h"
#include "rml.h"
#include "../Values.h"
#include "../absyn_builder/yacclib.h"

#define MAXPATHLEN MAX_PATH

char * cc=NULL;
char * cflags=NULL;

void * read_ptolemy_dataset(char*filename, int size,char**vars,int datasize);
int read_ptolemy_dataset_size(char*filename);
void * generate_array(char,int,type_description *,void *data);
double next_realelt(double*);
int next_intelt(int*);

void set_cc(char *str)
{
  if (cc != NULL) {
    free(cc);
  }
  cc = (char*)malloc(strlen(str)+1);
  assert(cc != NULL);
  memcpy(cc,str,strlen(str)+1);
}

void set_cflags(char *str)
{
  if (cflags != NULL) {
    free(cflags);
  }
  cflags = (char*)malloc(strlen(str)+1);
  assert(cflags != NULL);
  memcpy(cflags,str,strlen(str)+1);
}

/*
* Description:
*   Find and replace text within a string.
*
* Parameters:
*   source_src  (in) - pointer to source string
*   search_str (in) - pointer to search text
*   replace_str   (in) - pointer to replacement text
*
* Returns:
*   Returns a pointer to dynamically-allocated memory containing string
*   with occurences of the text pointed to by 'search_str' replaced by with the
*   text pointed to by 'replace_str'.
*/

char* _replace(char* source_str,char* search_str,char* replace_str)
{
  char *ostr, *nstr = NULL, *pdest = "";
  int length, nlen;
  unsigned int nstr_allocated;
  unsigned int ostr_allocated;
  
  if(!source_str || !search_str || !replace_str){
    printf("Not enough arguments\n");
    return NULL;
  }
  ostr_allocated = sizeof(char) * (strlen(source_str)+1);
  ostr = malloc( sizeof(char) * (strlen(source_str)+1));
  if(!ostr){
    printf("Insufficient memory available\n");
    return NULL;
  }
  strcpy(ostr, source_str);

  while(pdest)
    {
      pdest = strstr( ostr, search_str );
      length = (int)(pdest - ostr);

      if ( pdest != NULL )
        {
          ostr[length]='\0';
          nlen = strlen(ostr)+strlen(replace_str)+strlen( strchr(ostr,0)+strlen(search_str) )+1;
          if( !nstr || /* _msize( nstr ) */ nstr_allocated < sizeof(char) * nlen){
            nstr_allocated = sizeof(char) * nlen;
            nstr = malloc( sizeof(char) * nlen );
          }
          if(!nstr){
            printf("Insufficient memory available\n");
            return NULL;
          }

          strcpy(nstr, ostr);
          strcat(nstr, replace_str);
          strcat(nstr, strchr(ostr,0)+strlen(search_str));

          if( /* _msize(ostr) */ ostr_allocated < sizeof(char)*strlen(nstr)+1 ){
            ostr_allocated = sizeof(char)*strlen(nstr)+1;
            ostr = malloc(sizeof(char)*strlen(nstr)+1 );
          }
          if(!ostr){
            printf("Insufficient memory available\n");
            return NULL;
          }
          strcpy(ostr, nstr);
        }
    }
  if(nstr)
    free(nstr);
  return ostr;
}

 

void System_5finit(void)
{
	char* path;
	char* newPath;
	char* omhome;
	char* mingwpath;
	set_cc("gcc");
	set_cflags("-I%OPENMODELICAHOME%\\include -L%OPENMODELICAHOME%\\lib -lc_runtime %MODELICAUSERCFLAGS%");
	path = getenv("PATH");
	omhome = getenv("OPENMODELICAHOME");
	if (omhome) {
		mingwpath = malloc(2*strlen(omhome)+25);
		sprintf(mingwpath,"%s\\mingw\\bin;%s\\lib", omhome, omhome); 
		if (strncmp(mingwpath,path,strlen(mingwpath))!=0) {
			newPath = malloc(strlen(path)+strlen(mingwpath)+10);
			sprintf(newPath,"PATH=%s;%s",mingwpath,path);
			_putenv(newPath);
			free(newPath);
		}
		free(mingwpath);
	}
}


RML_BEGIN_LABEL(System__strtok)
{
  char *s;
  char *delimit = RML_STRINGDATA(rmlA1);
  char *str = strdup(RML_STRINGDATA(rmlA0));

  void * res = (void*)mk_nil();
  s=strtok(str,delimit);
  if (s == NULL) 
  {
	  /* adrpo added 2004-10-27 */
	  free(str);	  
	  rmlA0=res; RML_TAILCALLK(rmlFC); 
  }
  res = (void*)mk_cons(mk_scon(s),res);
  while (s=strtok(NULL,delimit)) 
  {
    res = (void*)mk_cons(mk_scon(s),res);
  }
  rmlA0=res;

  /* adrpo added 2004-10-27 */
  free(str);	  

  /* adrpo changed 2004-10-29 
  rml_prim_once(RML__list_5freverse);
  RML_TAILCALLK(rmlSC);
  */
  RML_TAILCALLQ(RML__list_5freverse,1);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__toupper)
{
  char *str = strdup(RML_STRINGDATA(rmlA0));
  char *res=str;
  while (*str!= '\0') 
  {
    *str=toupper(*str++);
  }
  rmlA0 = (void*) mk_scon(res);

  /* adrpo added 2004-10-29 */
  free(res);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__removeFirstAndLastChar)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *res = "";
  int length=strlen(str);
  int i;
  if(length > 1)
    {
      res=malloc(length-1);
      strncpy(res,str + 1,length-2);

      res[length-1] = '\0';  
    }
  rmlA0 = (void*) mk_scon(res);
  /* adrpo added 2004-10-29 */
  free(res); 
  
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

int str_contain_char( const char* chars, const char chr)
{
  int length_of_chars = strlen(chars);
  int i;
  for(i = 0; i < length_of_chars; i++)
    {
      if(chr == chars[i])
        return 1;
    }
  return 0;
}
 

/*  this removes chars in second from the beginning and end of the first
    string and returns it */
RML_BEGIN_LABEL(System__trim)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *chars_to_be_removed = RML_STRINGDATA(rmlA1);
  int length=strlen(str);
  char *res = malloc(length+1);
  int i;
  int start_pos = 0;
  int end_pos = length - 1;
  if(length > 1)
    {
      strncpy(res,str,length);
      for(i=0; i < length; i++ )
        {

          if(str_contain_char(chars_to_be_removed,res[start_pos]))
            start_pos++;
          if(str_contain_char(chars_to_be_removed,res[end_pos]))
            end_pos--;
        }


      res[length] = '\0';  
    }
  if(start_pos < end_pos)
    {
      res[end_pos+1] = '\0';
      rmlA0 = (void*) mk_scon(&res[start_pos]);
    } else {
      rmlA0 = (void*) mk_scon("");
    }      

  free(res); 


  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__trimChar)
{
  char* str = RML_STRINGDATA(rmlA0);
  char  char_to_be_trimmed = RML_STRINGDATA(rmlA1)[0];
  int length=strlen(str);
  int start_pos = 0;
  int end_pos = length - 1;
  char* res;
  while(start_pos < end_pos){
    if(str[start_pos] == char_to_be_trimmed)
      start_pos++;
    if(str[end_pos] == char_to_be_trimmed)
      end_pos--;
    if(str[start_pos] != char_to_be_trimmed && str[end_pos] != char_to_be_trimmed)
      break;
  }
  if(end_pos > start_pos){
    res= (char*)malloc(end_pos - start_pos +1);
    strncpy(res,&str[start_pos],end_pos - start_pos + 1);
    res[end_pos - start_pos + 1] = '\0';
    rmlA0 = (void*) mk_scon(res);
    free(res);
    RML_TAILCALLK(rmlSC);
    
  }else{
    rmlA0 = (void*) mk_scon("");
    RML_TAILCALLK(rmlSC);
  }
}
RML_END_LABEL



RML_BEGIN_LABEL(System__strcmp)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *str2 = RML_STRINGDATA(rmlA1);
  int res= strcmp(str,str2);

  rmlA0 = (void*) mk_icon(res);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__stringFind)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *searchStr = RML_STRINGDATA(rmlA1);
  int strLen = strlen(str);
  int strSearchLen = strlen(searchStr);
  int i,retVal=-1;
  
  for (i=0; i< strLen - strSearchLen+1; i++) {
  	if (strncmp(&str[i],searchStr,strSearchLen) == 0) { 
  		retVal = i; 
  		break;
  	}
  }
  rmlA0 = (void*) mk_icon(retVal);	
  RML_TAILCALLK(rmlSC);  
}
RML_END_LABEL

RML_BEGIN_LABEL(System__strncmp)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *str2 = RML_STRINGDATA(rmlA1);
  rml_sint_t len = RML_UNTAGFIXNUM(rmlA2);
  int res= strncmp(str,str2,len);

  rmlA0 = (void*) mk_icon(res);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__stringReplace)
{
  char *str = /* strdup( */RML_STRINGDATA(rmlA0)/* ) */;
  char *source = /* strdup( */RML_STRINGDATA(rmlA1)/* ) */;
  char *target =/*  strdup( */RML_STRINGDATA(rmlA2)/* ) */;
  char * res=0;
/*   printf("in '%s' replace '%s' with '%s'\n",str,source,target); */

  /* adrpo 2006-05-15 
   * if source and target are the same this function
   * cycles, get rid of that here
   */
   if (!strcmp(source, target)) 
   	RML_TAILCALLK(rmlSC);
  /* end adrpo */

  res = _replace(str,source,target);
  if (res == NULL) 
  {
/*      printf("res == NULL\n");  */
    RML_TAILCALLK(rmlFC);
  }
  rmlA0 = (void*) mk_scon(res);
/*   printf("Replace result: '%s'\n",res); */
  free(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__compileCFile)
{
  char* str = RML_STRINGDATA(rmlA0);
  char command[255];
  char exename[255];
  char *tmp;

  assert(strlen(str) < 255);
  if (strlen(str) >= 255) {
    RML_TAILCALLK(rmlFC);    
  }
  if (cc == NULL||cflags == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  memcpy(exename,str,strlen(str)-2);
  exename[strlen(str)-2]='\0';

  sprintf(command,"%s %s -o %s %s > compilelog.txt 2>&1",cc,str,exename,cflags);
  //printf("compile using: %s\n",command);
  _putenv("GCC_EXEC_PREFIX="); 
  tmp = getenv("MODELICAUSERCFLAGS");
  if (tmp == NULL || tmp[0] == '\0'  ) {
	  _putenv("MODELICAUSERCFLAGS=  ");
  }
  if (system(command) != 0) {
    RML_TAILCALLK(rmlFC);
  }
       
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL 

RML_BEGIN_LABEL(System__setCCompiler)
{
  char* str = RML_STRINGDATA(rmlA0);
  set_cc(str);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__setCFlags)
{
  char* str = RML_STRINGDATA(rmlA0);
  set_cflags(str);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__executeFunction)
{
  char* str = RML_STRINGDATA(rmlA0);
  char command[255];
  int ret_val;
  sprintf(command,".\\%s %s_in.txt %s_out.txt",str,str,str);
  ret_val = system(command);
  
  if (ret_val != 0) {
    RML_TAILCALLK(rmlFC);
  }

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__systemCall)
{
	int ret_val;
	char* str = RML_STRINGDATA(rmlA0);
	ret_val	= system(str);
	rmlA0 = (void*) mk_icon(ret_val);

	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__pathDelimiter)
{
  rmlA0 = (void*) mk_scon("/");

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__groupDelimiter)
{
  rmlA0 = (void*) mk_scon(";");

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
  char* buf2;
  LPTSTR bufPtr=buf;
  DWORD bufLen = MAXPATHLEN;
  GetCurrentDirectory(bufLen,bufPtr);
  
  /* Make sure windows paths use fronslash and not backslash */
  buf2=_replace(buf,"\\","/");
  
  rmlA0 = (void*) mk_scon(buf2);
  free(buf2);	
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__writeFile)
{
  char* data = RML_STRINGDATA(rmlA1);
  char* filename = RML_STRINGDATA(rmlA0);
  FILE * file=NULL;
  file = fopen(filename,"w");
  if (file == NULL) { 
    char *c_tokens[1]={filename};
    c_add_message(21, /* WRITING_FILE_ERROR */
		  "SCRIPTING",
		  "ERROR",
		  "Error writing to file %s.",
		  c_tokens,
		  1);
    RML_TAILCALLK(rmlFC);
  } 
  /* adrpo changed 2006-10-06 
   * fprintf(file,"%s",data);
   */
  fwrite(RML_STRINGDATA(rmlA1), RML_HDRSTRLEN(RML_GETHDR(rmlA1)), 1, file);
  fflush(file);
  fclose(file);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__readFile)
{
  char* filename = RML_STRINGDATA(rmlA0);
  char* buf;
  int res;
  FILE * file = NULL;
  struct stat statstr;
  res = stat(filename, &statstr);

  if(res!=0)
  {
    char *c_tokens[1]={filename};
    c_add_message(85, /* ERROR_OPENING_FILE */
		  "SCRIPTING",
		  "ERROR",
		  "Error opening file %s.",
		  c_tokens,
		  1);
    rmlA0 = (void*) mk_scon("No such file");
    RML_TAILCALLK(rmlSC);
  }

  file = fopen(filename,"rb");
  buf = malloc(statstr.st_size+1);
 
  if( (res = fread(buf, sizeof(char), statstr.st_size, file)) != statstr.st_size)
  {
	/* adrpo added 2004-10-26 */
	free(buf);
    rmlA0 = (void*) mk_scon("Failed while reading file");
    RML_TAILCALLK(rmlSC);
  }
  buf[statstr.st_size] = '\0';
  fclose(file);
  rmlA0 = (void*) mk_scon(buf);

  /* adrpo added 2004-10-26 */
  free(buf);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

/* RML_BEGIN_LABEL(System__modelicapath) */
/* { */
/*   char *path = getenv("OPENMODELICALIBRARY"); */
/*   if (path == NULL)  */
/*       RML_TAILCALLK(rmlFC); */
  
/*   rmlA0 = (void*) mk_scon(path); */
/*   RML_TAILCALLK(rmlSC); */
/* } */
/* RML_END_LABEL */

RML_BEGIN_LABEL(System__readEnv)
{
  char* envname = RML_STRINGDATA(rmlA0);
  char *envvalue;
  envvalue = getenv(envname);
  if (envvalue == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  rmlA0 = (void*) mk_scon(envvalue);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

/* adrpo@ida added 2005-11-24 */
RML_BEGIN_LABEL(System__setEnv)
{
  char* envname = RML_STRINGDATA(rmlA0);
  char* envvalue = RML_STRINGDATA(rmlA1);
  rml_sint_t overwrite = RML_UNTAGFIXNUM(rmlA2);
  int setenv_result = 0;
  char *temp = (char*)malloc(strlen(envname)+strlen(envvalue)+2);
  sprintf(temp,"%s=%s", envname, envvalue);
  setenv_result = _putenv(temp); 
  rmlA0 = (void*) mk_icon(setenv_result);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL



RML_BEGIN_LABEL(System__subDirectories)
{
	void *res;
	WIN32_FIND_DATA FileData;
	BOOL more = TRUE;
	char* directory = RML_STRINGDATA(rmlA0);
	char pattern[1024];
	HANDLE sh;
	if (directory == NULL)
		RML_TAILCALLK(rmlFC);


	sprintf(pattern, "%s\\*.*", directory);

	res = (void*)mk_nil();
	sh = FindFirstFile(pattern, &FileData);
	if (sh != INVALID_HANDLE_VALUE) {
		while(more) {
			if (strcmp(FileData.cFileName,"..") != 0 && 
				strcmp(FileData.cFileName,".") != 0 &&
				(FileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0) 
			{
			    res = (void*)mk_cons(mk_scon(FileData.cFileName),res);
			}
			more = FindNextFile(sh, &FileData);
		}
		CloseHandle(sh);
	}
	rmlA0 = (void*)res;
	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__moFiles)
{
	void *res;
	WIN32_FIND_DATA FileData;
	BOOL more = TRUE;
	char* directory = RML_STRINGDATA(rmlA0);
	char pattern[1024];
	HANDLE sh;
	if (directory == NULL)
		RML_TAILCALLK(rmlFC);


	sprintf(pattern, "%s\\*.mo", directory);

	res = (void*)mk_nil();
	sh = FindFirstFile(pattern, &FileData);
	if (sh != INVALID_HANDLE_VALUE) {
		while(more) {
			if (strcmp(FileData.cFileName,"package.mo") != 0)
			{
			    res = (void*)mk_cons(mk_scon(FileData.cFileName),res);
			}
			more = FindNextFile(sh, &FileData);
		}
		CloseHandle(sh);
	}
	rmlA0 = (void*)res;
	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

void* read_one_value_from_file(FILE* file, type_description* desc)
{
  void *res=NULL;
  int ival;
  double rval;
  double *rval_arr;
  int *ival_arr;
  int size;
  if (desc->ndims == 0) /* Scalar value */ 
  {
    if (desc->type == 'i') {
      fscanf(file,"%d",&ival);
      res =(void*) Values__INTEGER(mk_icon(ival));
    } else if (desc->type == 'r') {
      fscanf(file,"%le",&rval);
      res = (void*) Values__REAL(mk_rcon(rval));
    }
  } else if (desc->ndims == 1 && desc->type == 's') { /* Scalar String */   
    int i;
    char* tmp;
    tmp = malloc(sizeof(char)*(desc->dim_size[0]+1));
    if (!tmp) return NULL;
    for(i=0;i<desc->dim_size[0];i++) {
      tmp[i] = fgetc(file);
      if (tmp[i] == EOF) {
	return NULL;
      }
    }
    tmp[i]='\0';
    res = (void*) Values__STRING(mk_scon(tmp));
  }
  else  /* Array value */
    {
      int currdim,el,i;
      if (desc->type == 'r') {
	/* Create array to hold inserted values, max dimension as size */
	size = 1;
	for (currdim=0;currdim < desc->ndims; currdim++) {
	  size *= desc->dim_size[currdim];
	}
	rval_arr = (double*)malloc(sizeof(double)*size);
	if(rval_arr == NULL) {
	  return NULL;
	}
	/* Fill the array in reversed order */
	for(i=size-1;i>=0;i--) {
	  fscanf(file,"%le",&rval_arr[i]);
	}
	
	next_realelt(NULL);
	/* 1 is current dimension (start value) */
	res =(void*) Values__ARRAY(generate_array('r',1,desc,(void*)rval_arr)); 
      }
      
      if (desc->type == 'i') {
	int currdim,el,i;
	/* Create array to hold inserted values, mult of dimensions as size */
	size = 1;
	for (currdim=0;currdim < desc->ndims; currdim++) {
	  size *= desc->dim_size[currdim];
	}
	ival_arr = (int*)malloc(sizeof(int)*size);
	if(rval_arr==NULL) {
	  return NULL;
	}
	/* Fill the array in reversed order */
	for(i=size-1;i>=0;i--) {
	  fscanf(file,"%f",&ival_arr[i]);
	}
	next_intelt(NULL);
	res = (void*) Values__ARRAY(generate_array('i',1,desc,(void*)ival_arr));	
      }  
      if (desc->type == 's') {
	printf("Error, array of strings not impl. yet.\n");
      }
    }
  return res;
}

RML_BEGIN_LABEL(System__readValuesFromFile)
{
  int stat=0;
  int varcount=0;
  type_description desc;
  void *lst = (void*)mk_nil();
  void *res = NULL;
  char* filename = RML_STRINGDATA(rmlA0);
  FILE * file=NULL;
  file = fopen(filename,"r");
  if (file == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  
  /* Read the first value */
  stat = read_type_description(file,&desc);
  if (stat != 0) {
    printf("Error reading values from file\n");
    RML_TAILCALLK(rmlFC);
  }

  while (stat == 0) { /* Loop for tuples. At the end of while, we try to read another description */
    res = read_one_value_from_file(file, &desc);
    if (res == NULL) {
      printf("Error reading values from file2\n");
      RML_TAILCALLK(rmlFC);
    }
    lst = (void*)mk_cons(res, lst);
    varcount++;
    read_to_eol(file);
    stat = read_type_description(file,&desc);
    /*
    printf("varcount is : %d\n", varcount);
    printf("stat is : %d\n", stat);
    */
  }
  if (varcount > 1) { /* if tuple */
    rmlA0 = lst;
    rml_prim_once(RML__list_5freverse);
    rmlA0 = (void*) Values__TUPLE(rmlA0);
  }
  else {
    rmlA0 = (void*)res;
  }
  RML_TAILCALLK(rmlSC);
}   
RML_END_LABEL

RML_BEGIN_LABEL(System__readPtolemyplotDataset)
{
  rml_sint_t i,size;
  char **vars;
  char* filename = RML_STRINGDATA(rmlA0);
  void *lst = rmlA1;
  rml_sint_t datasize = RML_UNTAGFIXNUM(rmlA2);
  void* p;
  rmlA0 = lst;
  rml_prim_once(RML__list_5flength);
  size = RML_UNTAGFIXNUM(rmlA0);
  
  vars = (char**)malloc(sizeof(char*)*size);
  for (i=0,p=lst;i<size;i++) {
    vars[i]=RML_STRINGDATA(RML_CAR(p));
    p=RML_CDR(p);
  }
  rmlA0 = (void*)read_ptolemy_dataset(filename,size,vars,datasize);
  if (rmlA0 == NULL) {
    RML_TAILCALLK(rmlFC);
  }

  rml_prim_once(Values__reverseMatrix);

  RML_TAILCALLK(rmlSC);
}   
RML_END_LABEL

RML_BEGIN_LABEL(System__readPtolemyplotDatasetSize)
{
  int size;
  char* filename = RML_STRINGDATA(rmlA0);
  void* p;

  size=read_ptolemy_dataset_size(filename);
  
  rmlA0 = (void*)Values__INTEGER(mk_icon(size));
  if (rmlA0 == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  RML_TAILCALLK(rmlSC);
}   
RML_END_LABEL

RML_BEGIN_LABEL(System__writePtolemyplotDataset)
{
  char *filename = RML_STRINGDATA(rmlA0);
  void *value = rmlA1;
  

  RML_TAILCALLK(rmlSC);
}   
RML_END_LABEL


RML_BEGIN_LABEL(System__time)
{
  double _time;
  clock_t cl;
  
  cl=clock();
  
  _time = (double)cl / (double)CLOCKS_PER_SEC;
  /*  printf("clock : %d\n",cl); */
  /* printf("returning time: %f\n",time);  */
  rmlA0 = (void*) mk_rcon(_time);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__hash)
{
  char *str = RML_STRINGDATA(rmlA0);
  int res=0,i=0;
  while( str[i]&& i<4)
    res+=(int)str[i++];

  rmlA0 = RML_IMMEDIATE(RML_TAGFIXNUM(res)); //(void*) mk_icon(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__directoryExists)
{
	char* str = RML_STRINGDATA(rmlA0);
	int ret_val;
	void *res;
	WIN32_FIND_DATA FileData;
	HANDLE sh;

	if (str == NULL)
		RML_TAILCALLK(rmlFC);

	sh = FindFirstFile(str, &FileData);
	if (sh == INVALID_HANDLE_VALUE) {
		ret_val = 1;
	}
	else {
		if ((FileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == 0) {
			ret_val = 1;
		}
		else {
			ret_val = 0;
		}
		FindClose(sh);
	}

	rmlA0 = (void*) mk_icon(ret_val);

	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__regularFileExists)
{
	char* str = RML_STRINGDATA(rmlA0);
	int ret_val;
	void *res;
	WIN32_FIND_DATA FileData;
	HANDLE sh;

	if (str == NULL)
		RML_TAILCALLK(rmlFC);

	sh = FindFirstFile(str, &FileData);
	if (sh == INVALID_HANDLE_VALUE) {
		ret_val = 1;
	}
	else {
		if ((FileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
			ret_val = 1;
		}
		else {
			ret_val = 0;
		}
		FindClose(sh);
	}

	rmlA0 = (void*) mk_icon(ret_val);

	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

#ifdef WIN32
RML_BEGIN_LABEL(System__platform)
{
  rmlA0 = (void*) mk_scon("WIN32");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
#elif CYGWIN
RML_BEGIN_LABEL(System__platform)
{
  rmlA0 = (void*) mk_scon("CYGWIN");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
#else

RML_BEGIN_LABEL(System__platform)
{
  rmlA0 = (void*) mk_scon("");
  RML_TAILCALLK(rmlSC);
}
#endif

RML_BEGIN_LABEL(System__asin)
{
  rmlA0 = rml_prim_mkreal(asin(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__acos)
{
  rmlA0 = rml_prim_mkreal(acos(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__atan)
{
  rmlA0 = rml_prim_mkreal(atan(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__atan2)
{
  rmlA0 = rml_prim_mkreal(atan2(rml_prim_get_real(rmlA0),
				rml_prim_get_real(rmlA1)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__cosh)
{
  rmlA0 = rml_prim_mkreal(cosh(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__log)
{
  rmlA0 = rml_prim_mkreal(log(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__log10)
{
  rmlA0 = rml_prim_mkreal(log10(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__sinh)
{
  rmlA0 = rml_prim_mkreal(sinh(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__tanh)
{
  rmlA0 = rml_prim_mkreal(tanh(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

double next_realelt(double *arr)
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
    return 0;
  }
  else return arr[curpos++];
}

void * generate_array(char type, int curdim, type_description *desc, void *data)

{
  void *lst;
  double rval;
  int ival;
  int i;
  lst = (void*)mk_nil();
  if (curdim == desc->ndims) {
    for (i=0; i< desc->dim_size[curdim-1]; i++) {
      if (type == 'r') {
	rval = next_realelt((double*)data);
	lst = (void*)mk_cons(Values__REAL(mk_rcon(rval)),lst);
	
      } else if (type == 'i') {
	ival = next_intelt((int*)data);
	lst = (void*)mk_cons(Values__INTEGER(mk_icon(ival)),lst);
      }
    }
  } else {
    for (i=0; i< desc->dim_size[curdim-1]; i++) {
      lst = (void*)mk_cons(Values__ARRAY(generate_array(type,curdim+1,desc,data)),lst);
    }
  }
  return lst;
}

char* class_names_for_simulation = NULL;
RML_BEGIN_LABEL(System__getClassnamesForSimulation)
{
  if(class_names_for_simulation)
    rmlA0 = (void*) mk_scon(strdup(class_names_for_simulation));
  else
    rmlA0 = (void*) mk_scon("{}");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__setClassnamesForSimulation)
{
  char* class_names = RML_STRINGDATA(rmlA0);
  if(class_names_for_simulation)
    free(class_names_for_simulation);

  class_names_for_simulation = strdup(class_names);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__getVariableValue)
{
  double timeStamp 	= rml_prim_get_real(rmlA0);
  void *timeValues 	= rmlA1;  
  void *varValues 	= rmlA2;
  
  // values to find the correct range
  double preValue 	= 0.0;
  double preTime 	= 0.0;
  double nowValue 	= 0.0;
  double nowTime 	= 0.0;
  
  // linjear interpolation data
  double timedif 			= 0.0;
  double valuedif			= 0.0;
  double valueSlope			= 0.0;
  double timeDifTimeStamp	= 0.0;
  
  // break loop and return value
  int valueFound = 0;
  double returnValue = 0.0;

for(; RML_GETHDR(timeValues) == RML_CONSHDR && valueFound == 0; timeValues = RML_CDR(timeValues), varValues = RML_CDR(varValues)) {
  
  
    nowValue 	= rml_prim_get_real(RML_CAR(varValues));
  	nowTime 	=  rml_prim_get_real(RML_CAR(timeValues));


	if(timeStamp == nowTime){
    	valueFound 	= 1;
    	returnValue = nowValue;
    	
    } else if (timeStamp >= preTime && timeStamp <= nowTime) { // need to do interpolation
    	valueFound 			= 1;
    	timedif 			= nowTime - preTime;
    	valuedif			= nowValue - preValue;
    	valueSlope 			= valuedif / timedif;
    	timeDifTimeStamp 	= timeStamp - preTime;
    	returnValue 		= preValue + (valueSlope*timeDifTimeStamp);
    	/*
    	printf("\t ### Interpolation ###");
    	printf("nowTime: %f", nowTime);
    	printf("\n");
    	printf("preTime: %f", preTime);
    	printf("\n");
    	printf("nowValue: %f", nowValue);
    	printf("\n");
    	printf("preValue: %f", preValue);
    	printf("\n");
    	
		printf("timedif: %f", timedif);
    	printf("\n");
    	printf("valuedif: %f", valuedif);
    	printf("\n");
    	printf("valueSlope: %f", valueSlope);
    	printf("\n");
    	printf("timeDifTimeStamp: %f", timeDifTimeStamp);
    	printf("\n");
    	printf("returnValue: %f", returnValue);
    	printf("\n");
		*/
	} else {
		preValue 	= nowValue;
  		preTime 	= nowTime;
		
	}

  }
  if(valueFound == 0){
		// value could not be found in the dataset, what do we do?
		printf("\n WARNING: timestamp outside simulation timeline \n");
		RML_TAILCALLK(rmlFC);
	} else {
  
  		rmlA0 = (void*)mk_rcon(returnValue);
  		RML_TAILCALLK(rmlSC);
  }
}
RML_END_LABEL

RML_BEGIN_LABEL(System__sendData)
{
 

 

  	
  char* data = RML_STRINGDATA(rmlA0);
  char* interpolation = RML_STRINGDATA(rmlA1);
 char* title = RML_STRINGDATA(rmlA2);
 int legend = RML_UNTAGFIXNUM(rmlA3); //RML_STRINGDATA(rmlA3);
 int grid = RML_UNTAGFIXNUM(rmlA4); //RML_STRINGDATA(rmlA4); 
 int logX = RML_UNTAGFIXNUM(rmlA5); //RML_STRINGDATA(rmlA5);	
 int logY = RML_UNTAGFIXNUM(rmlA6); //RML_STRINGDATA(rmlA6);	 
 char* xLabel = RML_STRINGDATA(rmlA7);
 char* yLabel = RML_STRINGDATA(rmlA8);
 int points = RML_UNTAGFIXNUM(rmlA9);
  char* range = RML_STRINGDATA(rmlA10);
 //char* yRange = RML_STRINGDATA(rmlA11);
//  emulateStreamData(data, 7778);

//  emulateStreamData(data, 7778, "Plot by OpenModelica", "time", "", 1, 1, 0, 0, 0, 0, 0, 0, "linear", 1);
///  emulateStreamData(data, 7778, "Plot by OpenModelica", "time", "", 1, 1, 0, 0, 0, 0, 0, 0, interpolation, 1);

//  emulateStreamData(data, 7778, title, "time", "", legend, grid, 0, 0, 0, 0, logX, logY, interpolation, 1);
  emulateStreamData(data, 7778, title, xLabel, yLabel , interpolation, legend, grid, 0, 0, 0, 0, logX, logY, points, range);
  
//	emulateStreamData(data, 7778, "Plot by OpenModelica", "time", "", 1, 1, 0, 0, 0, 0, 0, 0, "linear");
       
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getFileModificationTime)
{
  char* fileName = RML_STRINGDATA(rmlA0);
  struct _stat attrib;			  // create a file attribute structure
  double elapsedTime;             // the time elapsed as double
  int result;					  // the result of the function call
  
  result = _stat( fileName, &attrib );
  
  if( result != 0 )
  {
  	rmlA0 = mk_none();     // we couldn't get the time, return NONE
  }  
  else
  {
    rmlA0 = mk_some(mk_rcon(difftime(attrib.st_mtime, 0))); // the file modification time 
  }  
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getCurrentTime)
{
  time_t t;
  double elapsedTime;             // the time elapsed as double
  time( &t );
  rmlA0 = mk_rcon(difftime(t, 0)); // the file modification time  
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

/* 
 * @author adrpo
 * this function sets the depth of variable showing in Eclipse.
 * it has no effect if is called within source not compiled in debug mode
 */
RML_BEGIN_LABEL(System__setDebugShowDepth)
{
#ifdef RML_DEBUG   
  rmldb_depth_of_variable_print = RML_UNTAGFIXNUM(rmlA0);
#endif  
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


#else /********************************* LINUX PART!!! *************************************/

#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <sys/param.h> /* MAXPATHLEN */

/* MacOS malloc.h is in sys */
#ifndef __APPLE_CC__
#include <malloc.h>
#else
#define HAVE_SCANDIR
#include <sys/malloc.h>
#endif

#include "read_write.h"
#include "rml.h"
#include "../Values.h"
#include "../absyn_builder/yacclib.h"

#ifndef _IFDIR
# ifdef S_IFDIR
#  define _IFDIR S_IFDIR
# else
#  error "Neither _IFDIR nor S_IFDIR is defined."
# endif
#endif

#ifndef HAVE_SCANDIR

typedef int _file_select_func_type(const struct dirent *);
typedef int _file_compar_func_type(const struct dirent **, const struct dirent **);




void reallocdirents(struct dirent ***entries, 
		    unsigned int oldsize, 
		    unsigned int newsize) {
  struct dirent **newentries;
  if (newsize<=oldsize)
    return;
  newentries = (struct dirent**)malloc(newsize * sizeof(struct dirent *));
  if (*entries != NULL) {
    int i;
    for (i=0; i<oldsize; i++)
      newentries[i] = (*entries)[i];
    for(; i<newsize; i++)
      newentries[i] = NULL;
    if (oldsize > 0)
      free(*entries);
  }
  *entries = newentries;
}


/* 
 * compar function is ignored
 */
int scandir(const char* dirname, 
	    struct dirent ***entries, 
	    _file_select_func_type select, 
	    _file_compar_func_type compar)
{
  DIR *dir = opendir(dirname);
  struct dirent *entry;
  unsigned int count = 0;
  unsigned int maxents = 100;
  *entries = NULL;
  reallocdirents(entries,0,maxents);
  do {
    entry = readdir(dir);
    if (entry == NULL)
      break;
    if (select == NULL || select(entry)) {
      struct dirent *entcopy = (struct dirent*)malloc(sizeof(struct dirent));
      if (count >= maxents) {
	unsigned int oldmaxents = maxents;
	maxents = maxents * 2;
	reallocdirents(entries, oldmaxents, maxents);
      }	
      (*entries)[count] = entcopy;
      count++;
    }
  } while (count < maxents); /* shouldn't be needed */
  /* 
     write code for calling qsort using compar for sorting the
     entries.
  */
  closedir(dir);
  return count;
}

#endif /* 0 */

char * cc=NULL;
char * cflags=NULL;

void * read_ptolemy_dataset(char*filename, int size,char**vars,int datasize);
int read_ptolemy_dataset_size(char*filename);
void * generate_array(char,int,type_description *,void *data);
double next_realelt(double*);
int next_intelt(int*);

int set_cc(char *str)
{
  if (cc != NULL) {
    free(cc);
  }
  cc = (char*)malloc(strlen(str)+1);
  if (cc == NULL) return -1;
  memcpy(cc,str,strlen(str)+1);
  return 0;
}

int set_cflags(char *str)
{
  if (cflags != NULL) {
    free(cflags);
  }
  cflags = (char*)malloc(strlen(str)+1);
  if (cflags == NULL) { return -1; }
  memcpy(cflags,str,strlen(str)+1);
  return 0;
}


#include <stdio.h>
#include <stdlib.h>
#include <string.h>


/*
* Description:
*   Find and replace text within a string.
*
* Parameters:
*   source_src  (in) - pointer to source string
*   search_str (in) - pointer to search text
*   replace_str   (in) - pointer to replacement text
*
* Returns:
*   Returns a pointer to dynamically-allocated memory containing string
*   with occurences of the text pointed to by 'search_str' replaced by with the
*   text pointed to by 'replace_str'.
*/


char* _replace(char* source_str,char* search_str,char* replace_str)
{
  char *ostr, *nstr = NULL, *pdest = "";
  int length, nlen;
  unsigned int nstr_allocated;
  unsigned int ostr_allocated;
  
  if(!source_str || !search_str || !replace_str){
    printf("Not enough arguments\n");
    return NULL;
  }
  ostr_allocated = sizeof(char) * (strlen(source_str)+1);
  ostr = malloc( sizeof(char) * (strlen(source_str)+1));
  if(!ostr){
    printf("Insufficient memory available\n");
    return NULL;
  }
  strcpy(ostr, source_str);

  while(pdest)
    {
      pdest = strstr( ostr, search_str );
      length = (int)(pdest - ostr);

      if ( pdest != NULL )
        {
          ostr[length]='\0';
          nlen = strlen(ostr)+strlen(replace_str)+strlen( strchr(ostr,0)+strlen(search_str) )+1;
          if( !nstr || /* _msize( nstr ) */ nstr_allocated < sizeof(char) * nlen){
            nstr_allocated = sizeof(char) * nlen;
            nstr = malloc( sizeof(char) * nlen );
          }
          if(!nstr){
            printf("Insufficient memory available\n");
            return NULL;
          }

          strcpy(nstr, ostr);
          strcat(nstr, replace_str);
          strcat(nstr, strchr(ostr,0)+strlen(search_str));

          if( /* _msize(ostr) */ ostr_allocated < sizeof(char)*strlen(nstr)+1 ){
            ostr_allocated = sizeof(char)*strlen(nstr)+1;
            ostr = malloc(sizeof(char)*strlen(nstr)+1 );
          }
          if(!ostr){
            printf("Insufficient memory available\n");
            return NULL;
          }
          strcpy(ostr, nstr);
        }
    }
  if(nstr)
    free(nstr);
  return ostr;
}

 
void System_5finit(void)
{
  set_cc("gcc");
    
  set_cflags("-I$OPENMODELICAHOME/include -L$OPENMODELICAHOME/lib -lc_runtime -lm $MODELICAUSERCFLAGS");
  
  
}

RML_BEGIN_LABEL(System__strtok)
{
  char *s;
  char *delimit = RML_STRINGDATA(rmlA1);
  char *str = strdup(RML_STRINGDATA(rmlA0));

  void * res = (void*)mk_nil();
  s=strtok(str,delimit);
  if (s == NULL) 
  {
	  /* adrpo added 2004-10-27 */
	  free(str);	  
	  rmlA0=res; RML_TAILCALLK(rmlFC); 
  }
  res = (void*)mk_cons(mk_scon(s),res);
  while (s=strtok(NULL,delimit)) 
  {
    res = (void*)mk_cons(mk_scon(s),res);
  }
  rmlA0=res;

  /* adrpo added 2004-10-27 */
  free(str);	  

  /* adrpo changed 2004-10-29 
  rml_prim_once(RML__list_5freverse);
  RML_TAILCALLK(rmlSC);
  */
  RML_TAILCALLQ(RML__list_5freverse,1);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__toupper)
{
  char *str = strdup(RML_STRINGDATA(rmlA0));
  char *res=str;
  while (*str!= '\0') 
  {
    *str=toupper(*str++);
  }
  rmlA0 = (void*) mk_scon(res);

  /* adrpo added 2004-10-29 */
  free(res);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__removeFirstAndLastChar)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *res = "";
  int length=strlen(str);
  int i;
  if(length > 1)
    {
      res=malloc(length-1);
      strncpy(res,str + 1,length-2);

      res[length-1] = '\0';  
    }
  rmlA0 = (void*) mk_scon(res);
  /* adrpo added 2004-10-29 */
  free(res); 
  
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

int str_contain_char( const char* chars, const char chr)
{
  int length_of_chars = strlen(chars);
  int i;
  for(i = 0; i < length_of_chars; i++)
    {
      if(chr == chars[i])
        return 1;
    }
  return 0;
}
 

/*  this removes chars in second from the beginning and end of the first
    string and returns it */
RML_BEGIN_LABEL(System__trim)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *chars_to_be_removed = RML_STRINGDATA(rmlA1);
  int length=strlen(str);
  char *res = malloc(length+1);
  int i;
  int start_pos = 0;
  int end_pos = length - 1;
  if(length > 1)
    {
      strncpy(res,str,length);
      for(i=0; i < length; i++ )
        {

          if(str_contain_char(chars_to_be_removed,res[start_pos]))
            start_pos++;
          if(str_contain_char(chars_to_be_removed,res[end_pos]))
            end_pos--;
        }


      res[length] = '\0';  
    }
  if(start_pos < end_pos)
    {
      res[end_pos+1] = '\0';
      rmlA0 = (void*) mk_scon(&res[start_pos]);
    } else {
      rmlA0 = (void*) mk_scon("");
    }      

  free(res); 


  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__trimChar)
{
  char* str = RML_STRINGDATA(rmlA0);
  char  char_to_be_trimmed = (char)RML_STRINGDATA(rmlA1)[0];
  int length=strlen(str);
  int start_pos = 0;
  int end_pos = length - 1;
  char* res;
  while(start_pos < end_pos){
    if(str[start_pos] == char_to_be_trimmed)
      start_pos++;
    if(str[end_pos] == char_to_be_trimmed)
      end_pos--;
    if(str[start_pos] != char_to_be_trimmed && str[end_pos] != char_to_be_trimmed)
      break;
  }
  if(end_pos > start_pos){
    res= (char*)malloc(end_pos - start_pos +1);
    strncpy(res,&str[start_pos],end_pos - start_pos + 1);
    res[end_pos - start_pos + 1] = '\0';
    rmlA0 = (void*) mk_scon(res);
    free(res);
    RML_TAILCALLK(rmlSC);
    
  }else{
    rmlA0 = (void*) mk_scon("");
    RML_TAILCALLK(rmlSC);
  }
}
RML_END_LABEL


RML_BEGIN_LABEL(System__strcmp)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *str2 = RML_STRINGDATA(rmlA1);
  int res= strcmp(str,str2);

  rmlA0 = (void*) mk_icon(res);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__stringFind)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *searchStr = RML_STRINGDATA(rmlA1);
  int strLen = strlen(str);
  int strSearchLen = strlen(searchStr);
  int i,retVal=-1;
  
  for (i=0; i< strLen - strSearchLen+1; i++) {
    if (strncmp(&str[i],searchStr,strSearchLen) == 0) { 
        retVal = i; 
        break;
    }
  }
  rmlA0 = (void*) mk_icon(retVal);  
  RML_TAILCALLK(rmlSC);  
}
RML_END_LABEL

RML_BEGIN_LABEL(System__strncmp)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *str2 = RML_STRINGDATA(rmlA1);
  rml_sint_t len = RML_UNTAGFIXNUM(rmlA2);
  int res= strncmp(str,str2,len);

  rmlA0 = (void*) mk_icon(res);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__stringReplace)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *source = RML_STRINGDATA(rmlA1);
  char *target = RML_STRINGDATA(rmlA2);
  char * res=0;

  /* adrpo 2006-05-15 
   * if source and target are the same this function
   * cycles, get rid of that here
   */
   if (!strcmp(source, target)) 
   	RML_TAILCALLK(rmlSC);
  /* end adrpo */
  
  res = _replace(str,source,target);

  if (res == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  rmlA0 = (void*) mk_scon(res);
  free(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__compileCFile)
{
  char* str = RML_STRINGDATA(rmlA0);
  char command[255];
  char exename[255];
  char *tmp;

  if (strlen(str) >= 255) {
    RML_TAILCALLK(rmlFC);    
  }
  if (cc == NULL||cflags == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  memcpy(exename,str,strlen(str)-2);
  exename[strlen(str)-2]='\0';

  sprintf(command,"%s %s -o %s %s",cc,str,exename,cflags);
  /* printf("compiled using: %s\n",command); */
  
#ifndef __APPLE_CC__  /* seems that we need to disable this on MacOS */
  /* putenv("GCC_EXEC_PREFIX="); */
#endif
  tmp = getenv("MODELICAUSERCFLAGS");
  if (tmp == NULL || tmp[0] == '\0'  ) {
	  putenv("MODELICAUSERCFLAGS=  ");
  }
  if (system(command) != 0) {
    RML_TAILCALLK(rmlFC);
  }
       
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL 

RML_BEGIN_LABEL(System__setCCompiler)
{
  char* str = RML_STRINGDATA(rmlA0);
  if(set_cc(str))  { 
    RML_TAILCALLK(rmlFC); 
  }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__setCFlags)
{
  char* str = RML_STRINGDATA(rmlA0);
  if (set_cflags(str)) {
    RML_TAILCALLK(rmlFC);
  }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__executeFunction)
{
  char* str = RML_STRINGDATA(rmlA0);
  char command[255];
  int ret_val;
  sprintf(command,"./%s %s_in.txt %s_out.txt",str,str,str);
  ret_val = system(command);  
  if (ret_val != 0) {
    RML_TAILCALLK(rmlFC);
  }

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__systemCall)
{
  int ret_val;
  char* str = RML_STRINGDATA(rmlA0);
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

RML_BEGIN_LABEL(System__writeFile)
{
  char* data = RML_STRINGDATA(rmlA1);
  char* filename = RML_STRINGDATA(rmlA0);
  FILE * file=NULL;
  file = fopen(filename,"w");
  if (file == NULL) {
    char *c_tokens[1]={filename};
    c_add_message(21, /* WRITING_FILE_ERROR */
		  "SCRIPTING",
		  "ERROR",
		  "Error writing to file %s.",
		  c_tokens,
		  1);
    RML_TAILCALLK(rmlFC);
  }
  /* adrpo changed 2006-10-06 
   * fprintf(file,"%s",data);
   */
  fwrite(RML_STRINGDATA(rmlA1), RML_HDRSTRLEN(RML_GETHDR(rmlA1)), 1, file);
  fflush(file);
  fclose(file);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__readFile)
{
  char* filename = RML_STRINGDATA(rmlA0);
  char* buf;
  int res;
  FILE * file = NULL;
  struct stat statstr;
  res = stat(filename, &statstr);

  if(res!=0)
  {
    char *c_tokens[1]={filename};
    c_add_message(85, /* ERROR_OPENING_FILE */
		  "SCRIPTING",
		  "ERROR",
		  "Error opening file %s.",
		  c_tokens,
		  1);
    rmlA0 = (void*) mk_scon("No such file");
    RML_TAILCALLK(rmlSC);
  }

  file = fopen(filename,"rb");
  buf = malloc(statstr.st_size+1);
 
  if( (res = fread(buf, sizeof(char), statstr.st_size, file)) != statstr.st_size)
  {
	/* adrpo added 2004-10-26 */
	free(buf);
    rmlA0 = (void*) mk_scon("Failed while reading file");
    RML_TAILCALLK(rmlSC);
  }
  buf[statstr.st_size] = '\0';
  fclose(file);
  rmlA0 = (void*) mk_scon(buf);

  /* adrpo added 2004-10-26 */
  free(buf);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

/* RML_BEGIN_LABEL(System__modelicapath) */
/* { */
/*   char *path = getenv("OPENMODELICALIBRARY"); */
/*   if (path == NULL)  */
/*       RML_TAILCALLK(rmlFC); */
  
/*   rmlA0 = (void*) mk_scon(path); */

/*   RML_TAILCALLK(rmlSC); */
/* } */
/* RML_END_LABEL */

RML_BEGIN_LABEL(System__readEnv)
{
  char* envname = RML_STRINGDATA(rmlA0);
  char *envvalue = getenv(envname);
  if (envvalue == NULL) 
  {
    RML_TAILCALLK(rmlFC);
  }
  rmlA0 = (void*) mk_scon(envvalue);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

/* adrpo@ida added 2005-11-24 */
RML_BEGIN_LABEL(System__setEnv)
{
  char* envname = RML_STRINGDATA(rmlA0);
  char* envvalue = RML_STRINGDATA(rmlA1);
  rml_sint_t overwrite = RML_UNTAGFIXNUM(rmlA2);
  int setenv_result = 0;
  setenv_result = setenv(envname, envvalue, (int)overwrite);
  rmlA0 = (void*) mk_icon(setenv_result);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


char *select_from_dir;

int file_select_directories(const struct dirent *entry)
{
  char fileName[MAXPATHLEN];
  int res;
  struct stat fileStatus;
  if ((strcmp(entry->d_name, ".") == 0) ||
      (strcmp(entry->d_name, "..") == 0)) {
    return (0);
  } else {
    sprintf(fileName,"%s/%s",select_from_dir,entry->d_name);
    res = stat(fileName,&fileStatus);
    if (res!=0) return 0;
    if ((fileStatus.st_mode & _IFDIR))
      return (1);
    else
      return (0);
  }
}


RML_BEGIN_LABEL(System__subDirectories)
{
  int i,count;
  void *res;
  char* directory = RML_STRINGDATA(rmlA0);
  struct dirent **files;
  if (directory == NULL)
    RML_TAILCALLK(rmlFC);
  select_from_dir = directory;
  count = scandir(directory, &files, file_select_directories, NULL);
  res = (void*)mk_nil();
  for (i=0; i<count; i++) 
  {
    res = (void*)mk_cons(mk_scon(files[i]->d_name),res);
    /* adrpo added 2004-10-28 */
    //free(files[i]->d_name);
	free(files[i]);
  }
  rmlA0 = (void*) res;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

int file_select_mo(const struct dirent *entry)
{
  char fileName[MAXPATHLEN];
  int res; char* ptr;
  struct stat fileStatus;
  if ((strcmp(entry->d_name, ".") == 0) ||
      (strcmp(entry->d_name, "..") == 0) ||
      (strcmp(entry->d_name, "package.mo") == 0)) {
    return (0);
  } else {
    ptr = (char*)rindex(entry->d_name, '.');
    if ((ptr != NULL) &&
	((strcmp(ptr, ".mo") == 0))) {
      return (1);
    } else {
      return (0);
    }
  }
}

RML_BEGIN_LABEL(System__moFiles)
{
  int i,count;
  void *res;
  char* directory = RML_STRINGDATA(rmlA0);
  struct dirent **files;
  if (directory == NULL)
    RML_TAILCALLK(rmlFC);
  select_from_dir = directory;
  count = scandir(directory, &files, file_select_mo, NULL);
  res = (void*)mk_nil();
  for (i=0; i<count; i++) 
  {
    res = (void*)mk_cons(mk_scon(files[i]->d_name),res);
    /* adrpo added 2004-10-28 */
    //free(files[i]->d_name);
	free(files[i]);
  }
  rmlA0 = (void*) res;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

void* read_one_value_from_file(FILE* file, type_description* desc)
{
  void *res=NULL;
  int ival;
  double rval;
  double *rval_arr;
  int *ival_arr;
  int size;
  if (desc->ndims == 0) /* Scalar value */ 
  {
    if (desc->type == 'i') {
      fscanf(file,"%d",&ival);
      res =(void*) Values__INTEGER(mk_icon(ival));
    } else if (desc->type == 'r') {
      fscanf(file,"%le",&rval);
      res = (void*) Values__REAL(mk_rcon(rval));
    }
  } else if (desc->ndims == 1 && desc->type == 's') { /* Scalar String */   
    int i;
    char* tmp;
    tmp = malloc(sizeof(char)*(desc->dim_size[0]+1));
    if (!tmp) return NULL;
    for(i=0;i<desc->dim_size[0];i++) {
      tmp[i] = fgetc(file);
      if (tmp[i] == EOF) {
	return NULL;
      }
    }
    tmp[i]='\0';
    res = (void*) Values__STRING(mk_scon(tmp));
  }
  else  /* Array value */
    {
      int currdim,el,i;
      if (desc->type == 'r') {
	/* Create array to hold inserted values, max dimension as size */
	size = 1;
	for (currdim=0;currdim < desc->ndims; currdim++) {
	  size *= desc->dim_size[currdim];
	}
	rval_arr = (double*)malloc(sizeof(double)*size);
	if(rval_arr == NULL) {
	  return NULL;
	}
	/* Fill the array in reversed order */
	for(i=size-1;i>=0;i--) {
	  fscanf(file,"%le",&rval_arr[i]);
	}
	
	next_realelt(NULL);
	/* 1 is current dimension (start value) */
	res =(void*) Values__ARRAY(generate_array('r',1,desc,(void*)rval_arr)); 
      }
      
      if (desc->type == 'i') {
	int currdim,el,i;
	/* Create array to hold inserted values, mult of dimensions as size */
	size = 1;
	for (currdim=0;currdim < desc->ndims; currdim++) {
	  size *= desc->dim_size[currdim];
	}
	ival_arr = (int*)malloc(sizeof(int)*size);
	if(rval_arr==NULL) {
	  return NULL;
	}
	/* Fill the array in reversed order */
	for(i=size-1;i>=0;i--) {
	  fscanf(file,"%f",&ival_arr[i]);
	}
	next_intelt(NULL);
	res = (void*) Values__ARRAY(generate_array('i',1,desc,(void*)ival_arr));	
      }  
      if (desc->type == 's') {
	printf("Error, array of strings not impl. yet.\n");
      }
    }
  return res;
}

RML_BEGIN_LABEL(System__readValuesFromFile)
{
  int stat=0;
  int varcount=0;
  type_description desc;
  void *lst = (void*)mk_nil();
  void *res = NULL;
  char* filename = RML_STRINGDATA(rmlA0);
  FILE * file=NULL;
  file = fopen(filename,"r");
  if (file == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  
  /* Read the first value */
  stat = read_type_description(file,&desc);
  if (stat != 0) {
    printf("Error reading values from file\n");
    RML_TAILCALLK(rmlFC);
  }

  while (stat == 0) { /* Loop for tuples. At the end of while, we try to read another description */
    res = read_one_value_from_file(file, &desc);
    if (res == NULL) {
      printf("Error reading values from file2\n");
      RML_TAILCALLK(rmlFC);
    }
    lst = (void*)mk_cons(res, lst);
    varcount++;
    read_to_eol(file);
    stat = read_type_description(file,&desc);
    /*
    printf("varcount is : %d\n", varcount);
    printf("stat is : %d\n", stat);
    */
  }
  if (varcount > 1) { /* if tuple */
    rmlA0 = lst;
    rml_prim_once(RML__list_5freverse);
    rmlA0 = (void*) Values__TUPLE(rmlA0);
  }
  else {
    rmlA0 = (void*)res;
  }
  RML_TAILCALLK(rmlSC);
}   
RML_END_LABEL

RML_BEGIN_LABEL(System__readPtolemyplotDataset)
{
  rml_sint_t i,size;
  char **vars;
  char* filename = RML_STRINGDATA(rmlA0);
  void *lst = rmlA1;
  rml_sint_t datasize = RML_UNTAGFIXNUM(rmlA2);
  void* p = NULL;
  rmlA0 = lst;
  rml_prim_once(RML__list_5flength);
  size = RML_UNTAGFIXNUM(rmlA0);
  
  vars = (char**)malloc(sizeof(char*)*size);
  for (i=0,p=lst;i<size;i++) {
    vars[i]=RML_STRINGDATA(RML_CAR(p));
    p=RML_CDR(p);
  }
  rmlA0 = (void*)read_ptolemy_dataset(filename,size,vars,datasize);
  if (rmlA0 == NULL) {
    RML_TAILCALLK(rmlFC);
  }

  rml_prim_once(Values__reverseMatrix);

  RML_TAILCALLK(rmlSC);
}   
RML_END_LABEL

RML_BEGIN_LABEL(System__readPtolemyplotDatasetSize)
{
  int size;
  char* filename = RML_STRINGDATA(rmlA0);
  void* p;

  size=read_ptolemy_dataset_size(filename);
  
  rmlA0 = (void*)Values__INTEGER(mk_icon(size));
  if (rmlA0 == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  RML_TAILCALLK(rmlSC);
}   
RML_END_LABEL

RML_BEGIN_LABEL(System__writePtolemyplotDataset)
{
  char *filename = RML_STRINGDATA(rmlA0);
  void *value = rmlA1;
  

  RML_TAILCALLK(rmlSC);
}   
RML_END_LABEL


RML_BEGIN_LABEL(System__time)
{
  double time;
  clock_t cl;
  
  cl=clock();
  
  time = (double)cl / (double)CLOCKS_PER_SEC;
  /*  printf("clock : %d\n",cl); */
  /* printf("returning time: %f\n",time);  */
  rmlA0 = (void*) mk_rcon(time);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__hash)
{
  char *str = RML_STRINGDATA(rmlA0);
  rml_sint_t res=0,i=0;
  while( str[i]&& i<4)
    res+=(rml_sint_t)str[i++];

  rmlA0 = RML_IMMEDIATE(RML_TAGFIXNUM(res));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__pathDelimiter)
{
  rmlA0 = (void*) mk_scon("/");

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__groupDelimiter)
{
  rmlA0 = (void*) mk_scon(":");

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__directoryExists)
{
  char* str = RML_STRINGDATA(rmlA0);
  int ret_val;
  struct stat buf;
  
  if (str == NULL)
  	RML_TAILCALLK(rmlFC);
		  
  ret_val = stat(str, &buf);
  if (ret_val != 0 ) {
    rmlA0 = (void*) mk_icon(1);
  }
  else {
    if (buf.st_mode & S_IFDIR) {
      rmlA0 = (void*) mk_icon(0);
    }
    else {
      rmlA0 = (void*) mk_icon(1);
    }
  }
  RML_TAILCALLK(rmlSC);

}
RML_END_LABEL

RML_BEGIN_LABEL(System__regularFileExists)
{
  char* str = RML_STRINGDATA(rmlA0);
  int ret_val;
  struct stat buf;
  ret_val = stat(str, &buf);
  if (ret_val != 0 ) {
    rmlA0 = (void*) mk_icon(1);
  }
  else {
    if (buf.st_mode & S_IFREG ) {
      rmlA0 = (void*) mk_icon(0);
    }
    else {
      rmlA0 = (void*) mk_icon(1);
    }
  }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

#ifdef WIN32
RML_BEGIN_LABEL(System__platform)
{
  rmlA0 = (void*) mk_scon("WIN32");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL 
#elif defined CYGWIN 
RML_BEGIN_LABEL(System__platform)
{
  rmlA0 = (void*) mk_scon("CYGWIN");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
#else
RML_BEGIN_LABEL(System__platform)
{
  rmlA0 = (void*) mk_scon("");
  RML_TAILCALLK(rmlSC);
}
#endif

RML_BEGIN_LABEL(System__asin)
{
  rmlA0 = rml_prim_mkreal(asin(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__acos)
{
  rmlA0 = rml_prim_mkreal(acos(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__atan)
{
  rmlA0 = rml_prim_mkreal(atan(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__atan2)
{
  rmlA0 = rml_prim_mkreal(atan2(rml_prim_get_real(rmlA0),
				rml_prim_get_real(rmlA1)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__cosh)
{
  rmlA0 = rml_prim_mkreal(cosh(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__log)
{
  rmlA0 = rml_prim_mkreal(log(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__log10)
{
  rmlA0 = rml_prim_mkreal(log10(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__sinh)
{
  rmlA0 = rml_prim_mkreal(sinh(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__tanh)
{
  rmlA0 = rml_prim_mkreal(tanh(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

double next_realelt(double *arr)
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
    return 0;
  }
  else return arr[curpos++];
}

void * generate_array(char type, int curdim, type_description *desc, void *data)

{
  void *lst;
  double rval;
  int ival;
  int i;
  lst = (void*)mk_nil();
  if (curdim == desc->ndims) {
    for (i=0; i< desc->dim_size[curdim-1]; i++) {
      if (type == 'r') {
	rval = next_realelt((double*)data);
	lst = (void*)mk_cons(Values__REAL(mk_rcon(rval)),lst);
	
      } else if (type == 'i') {
	ival = next_intelt((int*)data);
	lst = (void*)mk_cons(Values__INTEGER(mk_icon(ival)),lst);
      }
    }
  } else {
    for (i=0; i< desc->dim_size[curdim-1]; i++) {
      lst = (void*)mk_cons(Values__ARRAY(generate_array(type,curdim+1,desc,data)),lst);
    }
  }
  return lst;
}

char* class_names_for_simulation = NULL;
RML_BEGIN_LABEL(System__getClassnamesForSimulation)
{
  if(class_names_for_simulation)
    rmlA0 = (void*) mk_scon(strdup(class_names_for_simulation));
  else
    rmlA0 = (void*) mk_scon("{}");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__setClassnamesForSimulation)
{
  char* class_names = RML_STRINGDATA(rmlA0);
  if(class_names_for_simulation)
    free(class_names_for_simulation);

  class_names_for_simulation = strdup(class_names);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

char* compile_command = NULL;

RML_BEGIN_LABEL(System__getVariableValue)
{
  double timeStamp 	= rml_prim_get_real(rmlA0);
  void *timeValues 	= rmlA1;  
  void *varValues 	= rmlA2;
  
  // values to find the correct range
  double preValue 	= 0.0;
  double preTime 	= 0.0;
  double nowValue 	= 0.0;
  double nowTime 	= 0.0;
  
  // linjear interpolation data
  double timedif 			= 0.0;
  double valuedif			= 0.0;
  double valueSlope			= 0.0;
  double timeDifTimeStamp	= 0.0;
  
  // break loop and return value
  int valueFound = 0;
  double returnValue = 0.0;

for(; RML_GETHDR(timeValues) == RML_CONSHDR && valueFound == 0; timeValues = RML_CDR(timeValues), varValues = RML_CDR(varValues)) {
  
  
    nowValue 	= rml_prim_get_real(RML_CAR(varValues));
  	nowTime 	=  rml_prim_get_real(RML_CAR(timeValues));


	if(timeStamp == nowTime){
    	valueFound 	= 1;
    	returnValue = nowValue;
    	
    } else if (timeStamp >= preTime && timeStamp <= nowTime) { // need to do interpolation
    	valueFound 			= 1;
    	timedif 			= nowTime - preTime;
    	valuedif			= nowValue - preValue;
    	valueSlope 			= valuedif / timedif;
    	timeDifTimeStamp 	= timeStamp - preTime;
    	returnValue 		= preValue + (valueSlope*timeDifTimeStamp);
    	/*
    	printf("\t ### Interpolation ###");
    	printf("nowTime: %f", nowTime);
    	printf("\n");
    	printf("preTime: %f", preTime);
    	printf("\n");
    	printf("nowValue: %f", nowValue);
    	printf("\n");
    	printf("preValue: %f", preValue);
    	printf("\n");
    	
		printf("timedif: %f", timedif);
    	printf("\n");
    	printf("valuedif: %f", valuedif);
    	printf("\n");
    	printf("valueSlope: %f", valueSlope);
    	printf("\n");
    	printf("timeDifTimeStamp: %f", timeDifTimeStamp);
    	printf("\n");
    	printf("returnValue: %f", returnValue);
    	printf("\n");
		*/
	} else {
		preValue 	= nowValue;
  		preTime 	= nowTime;
		
	}

  }
  if(valueFound == 0){
		// value could not be found in the dataset, what do we do?
		printf("\n WARNING: timestamp outside simulation timeline \n");
		RML_TAILCALLK(rmlFC);
	} else {
  
  		rmlA0 = (void*)mk_rcon(returnValue);
  		RML_TAILCALLK(rmlSC);
  }
}
RML_END_LABEL

RML_BEGIN_LABEL(System__sendData)
{
 

 

  	
  char* data = RML_STRINGDATA(rmlA0);
  char* interpolation = RML_STRINGDATA(rmlA1);
 char* title = RML_STRINGDATA(rmlA2);
 int legend = RML_UNTAGFIXNUM(rmlA3); //RML_STRINGDATA(rmlA3);
 int grid = RML_UNTAGFIXNUM(rmlA4); //RML_STRINGDATA(rmlA4); 
 int logX = RML_UNTAGFIXNUM(rmlA5); //RML_STRINGDATA(rmlA5);	
 int logY = RML_UNTAGFIXNUM(rmlA6); //RML_STRINGDATA(rmlA6);	 
 char* xLabel = RML_STRINGDATA(rmlA7);
 char* yLabel = RML_STRINGDATA(rmlA8);
 int points = (RML_UNTAGFIXNUM(rmlA9);
 char* range = RML_STRINGDATA(rmlA10);
// char* yRange = RML_STRINGDATA(rmlA11);
//  emulateStreamData(data, 7778);

//  emulateStreamData(data, 7778, "Plot by OpenModelica", "time", "", 1, 1, 0, 0, 0, 0, 0, 0, "linear", 1);
///  emulateStreamData(data, 7778, "Plot by OpenModelica", "time", "", 1, 1, 0, 0, 0, 0, 0, 0, interpolation, 1);

//  emulateStreamData(data, 7778, title, "time", "", legend, grid, 0, 0, 0, 0, logX, logY, interpolation, 1);
  emulateStreamData(data, 7778, title, xLabel, yLabel , interpolation, legend, grid, 0, 0, 0, 0, logX, logY, points, range);
  
//	emulateStreamData(data, 7778, "Plot by OpenModelica", "time", "", 1, 1, 0, 0, 0, 0, 0, 0, "linear");
       
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__getFileModificationTime)
{
  char* fileName = RML_STRINGDATA(rmlA0);
  struct stat attrib;			      // create a file attribute structure
  double elapsedTime;                 // the time elapsed as double
  int result;					      // the result of the function call
  
  result =   stat(fileName, &attrib); // get the attributes of the file
  
  if( result != 0 )
  {
  	rmlA0 = mk_none();     // we couldn't get the time, return NONE
  }  
  else
  {
    rmlA0 = mk_some(mk_rcon(difftime(attrib.st_mtime, 0))); // the file modification time 
  }  
  
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getCurrentTime)
{
  time_t t;
  double elapsedTime;             // the time elapsed as double
  time( &t );
  rmlA0 = mk_rcon(difftime(t, 0)); // the file modification time  
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

/* 
 * @author adrpo
 * this function sets the depth of variable showing in Eclipse.
 * it has no effect if is called within source not compiled in debug mode
 */
RML_BEGIN_LABEL(System__setDebugShowDepth)
{
#ifdef RML_DEBUG   
  rmldb_depth_of_variable_print = RML_UNTAGFIXNUM(rmlA0);
#endif  
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

#endif /* MINGW32 */

