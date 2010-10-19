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
#include <stdlib.h>
extern "C" {

#include "printimpl.c"

extern void printErrorBuf(const char* str)
{
  if (PrintImpl__printErrorBuf(str))
    throw 1;
}

extern void printBuf(const char* str)
{
  if (PrintImpl__printBuf(str))
    throw 1;
}

extern int Print_hasBufNewLineAtEnd(void)
{
  return PrintImpl__hasBufNewLineAtEnd();
}

extern int Print_getBufLength(void)
{
  return PrintImpl__getBufLength();
}

extern const char* Print_getString(void)
{
  const char* res = PrintImpl__getString();
  if (res == NULL)
    throw 1;
  return strdup(res);
}

extern const char* Print_getErrorString(void)
{
  const char* res = PrintImpl__getErrorString();
  if (res == NULL)
    throw 1;
  return strdup(res);
}

extern void clearErrorBuf(void)
{
  PrintImpl__clearErrorBuf();
}

extern void clearBuf(void)
{
  PrintImpl__clearBuf();
}

extern void printBufSpace(int numSpace)
{
  if (PrintImpl__printBufSpace(numSpace))
    throw 1;
}

extern void printBufNewLine(void)
{
  if (PrintImpl__printBufNewLine())
    throw 1;
}

}
