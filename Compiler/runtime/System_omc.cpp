/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Link�pings University,
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

#include "systemimpl.c"

extern "C" {

extern int System_regularFileExists(const char* str)
{
  return SystemImpl__regularFileExists(str)!=0;
}

extern void writeFile(const char* filename, const char* data)
{
  if (SystemImpl__writeFile(filename, data))
    throw 1;
}

extern char* System_readFile(const char* filename)
{
  return SystemImpl__readFile(filename);
}

extern const char* System_stringReplace(const char* str, const char* source, const char* target)
{
  char* res = _replace(str,source,target);
  if (res == NULL)
    throw 1;
  return res;
}

extern int System_stringFind(const char* str, const char* searchStr)
{
  return SystemImpl__stringFind(str, searchStr);
}

extern int System_refEqual(void* a, void* b)
{
  return a == b;
}

extern int System_hash(unsigned char* str)
{
  return djb2_hash(str);
}

/* Old RML impl.
void         *rml_external_roots_trail[1024] = {0};
rml_uint_t    rml_external_roots_trail_size = 1024;
rml_uint_t    rml_external_roots_trail_index_max = 0;

// forward my external roots
void rml_user_gc(struct rml_xgcstate *state)
{
  rml_user_gc_callback(state, rml_external_roots_trail, rml_external_roots_trail_index_max*sizeof(void*));
}

RML_BEGIN_LABEL(System__addToRoots)
{
    rml_uint_t i = RML_UNTAGFIXNUM(rmlA0);

    if (rml_trace_enabled)
    {
      fprintf(stderr, "System__addToRoots\n"); fflush(stderr);
    }

    if (i >= rml_external_roots_trail_size)
      RML_TAILCALLK(rmlFC);

    rml_external_roots_trail[i] = rmlA1;

    // remember the max
    rml_external_roots_trail_index_max = max(rml_external_roots_trail_index_max, i+1);

    RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getFromRoots)
{
    rml_uint_t i = RML_UNTAGFIXNUM(rmlA0);

    if (rml_trace_enabled)
    {
      fprintf(stderr, "System__getFromRoots\n"); fflush(stderr);
    }

    if (i > rml_external_roots_trail_index_max || i >= rml_external_roots_trail_size)
      RML_TAILCALLK(rmlFC);

    rmlA0 = rml_external_roots_trail[i];

    RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
*/

}
