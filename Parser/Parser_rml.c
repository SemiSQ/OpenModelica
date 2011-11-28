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

void ParserExt_5finit(void)
{
}

RML_BEGIN_LABEL(ParserExt__parse)
{
  int flags = PARSE_MODELICA;
  if(RML_UNTAGFIXNUM(rmlA1) == 2) flags |= PARSE_META_MODELICA;
  else if(RML_UNTAGFIXNUM(rmlA1) == 3) flags |= PARSE_PAR_MODELICA;
  
  rmlA0 = parseFile(RML_STRINGDATA(rmlA0),flags,RML_UNTAGFIXNUM(rmlA2));
  if (rmlA0)
    RML_TAILCALLK(rmlSC);
  else
    RML_TAILCALLK(rmlFC);
}
RML_END_LABEL


RML_BEGIN_LABEL(ParserExt__parseexp)
{
  int flags = PARSE_EXPRESSION;
  if(RML_UNTAGFIXNUM(rmlA1) == 2) flags |= PARSE_META_MODELICA;
  else if(RML_UNTAGFIXNUM(rmlA1) == 3) flags |= PARSE_PAR_MODELICA;
  
  rmlA0 = parseFile(RML_STRINGDATA(rmlA0),flags,RML_UNTAGFIXNUM(rmlA2));
  if (rmlA0)
    RML_TAILCALLK(rmlSC);
  else
    RML_TAILCALLK(rmlFC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ParserExt__parsestring)
{
  int flags = PARSE_MODELICA;
  if(RML_UNTAGFIXNUM(rmlA2) == 2) flags |= PARSE_META_MODELICA;
  else if(RML_UNTAGFIXNUM(rmlA2) == 3) flags |= PARSE_PAR_MODELICA;
  
  rmlA0 = parseString(RML_STRINGDATA(rmlA0),RML_STRINGDATA(rmlA1),flags,RML_UNTAGFIXNUM(rmlA3));
  if (rmlA0) {
    RML_TAILCALLK(rmlSC);
  } else {
    RML_TAILCALLK(rmlFC);
  }
}
RML_END_LABEL


RML_BEGIN_LABEL(ParserExt__parsestringexp)
{
  int flags = PARSE_EXPRESSION;
  if(RML_UNTAGFIXNUM(rmlA2) == 2) flags |= PARSE_META_MODELICA;
  else if(RML_UNTAGFIXNUM(rmlA2) == 3) flags |= PARSE_PAR_MODELICA;
  
  rmlA0 = parseString(RML_STRINGDATA(rmlA0),RML_STRINGDATA(rmlA1),flags,RML_UNTAGFIXNUM(rmlA3));
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
