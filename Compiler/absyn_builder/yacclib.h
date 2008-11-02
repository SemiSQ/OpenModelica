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
/* yacclib.h */

extern void *alloc_bytes(unsigned nbytes);
extern void *alloc_words(unsigned nwords);

extern void print_icon(FILE*, void*);
extern void print_rcon(FILE*, void*);
extern void print_scon(FILE*, void*);

extern void *mk_icon(int);
extern void *mk_rcon(double);
extern void *mk_scon(char*);
extern void *mk_nil(void);
extern void *mk_cons(void*, void*);
extern void *mk_none(void);
extern void *mk_some(void*);
extern void *mk_box0(unsigned ctor);
extern void *mk_box1(unsigned ctor, void*);
extern void *mk_box2(unsigned ctor, void*, void*);
extern void *mk_box3(unsigned ctor, void*, void*, void*);
extern void *mk_box4(unsigned ctor, void*, void*, void*, void*);
extern void *mk_box5(unsigned ctor, void*, void*, void*, void*, void*);
extern void *mk_box6(unsigned ctor, void*, void*, void*, void*, void*, void*);
extern void *mk_box7(unsigned ctor, void*, void*, void*, void*, void *,
		     void*, void*);
extern void *mk_box8(unsigned ctor, void*, void*, void*, void*, void *,
		     void*, void*, void*);
extern void *mk_box9(unsigned ctor, void*, void*, void*, void*, void *,
		     void*, void*, void*, void*);
