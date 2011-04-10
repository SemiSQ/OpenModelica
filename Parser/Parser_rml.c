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

#ifdef __cplusplus
extern "C" {
#endif  
#include "rml.h"
#ifdef __cplusplus
}
#endif  

#include "parse.c"

#ifdef __cplusplusend
extern "C" {
#endif

void Parser_5finit(void)
{
}

RML_BEGIN_LABEL(Parser__parse)
{
  rmlA0 = parseFile(RML_STRINGDATA(rmlA0),PARSE_MODELICA);
  if (rmlA0)
    RML_TAILCALLK(rmlSC);
  else
    RML_TAILCALLK(rmlFC);
}
RML_END_LABEL


RML_BEGIN_LABEL(Parser__parseexp)
{
  rmlA0 = parseFile(RML_STRINGDATA(rmlA0),PARSE_EXPRESSION);
  if (rmlA0)
    RML_TAILCALLK(rmlSC);
  else
    RML_TAILCALLK(rmlFC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Parser__parsestring)
{
  rmlA0 = parseString(RML_STRINGDATA(rmlA0),RML_STRINGDATA(rmlA1),PARSE_MODELICA);
  if (rmlA0) {
    RML_TAILCALLK(rmlSC);
  } else {
    RML_TAILCALLK(rmlFC);
  }
}
RML_END_LABEL


RML_BEGIN_LABEL(Parser__parsestringexp)
{
  rmlA0 = parseString(RML_STRINGDATA(rmlA0),RML_STRINGDATA(rmlA1),PARSE_EXPRESSION);
  if (rmlA0) {
    RML_TAILCALLK(rmlSC);
  } else {
    RML_TAILCALLK(rmlFC);
  }
}
RML_END_LABEL

#ifdef __cplusplusend
}
#endif
