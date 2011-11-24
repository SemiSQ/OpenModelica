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

#include <stdio.h>
#include "corbaimpl.cpp"

extern "C" {

#include "meta_modelica.h"

extern void Corba_setSessionName(const char* _inSessionName)
{
  CorbaImpl__setSessionName(_inSessionName);
}

extern const char* Corba_waitForCommand()
{
  return strdup(CorbaImpl__waitForCommand());
}

extern void Corba_initialize()
{
  if (CorbaImpl__initialize()) MMC_THROW();
}

extern void Corba_close()
{
  CorbaImpl__close();
}

extern void Corba_sendreply(const char* _inString)
{
  CorbaImpl__sendreply(_inString);
}

}
