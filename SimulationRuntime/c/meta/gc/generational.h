/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Link�ping University,
 * Department of Computer and Information Science,
 * SE-58183 Link�ping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Link�ping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */


/*
 * Adrian Pop [Adrian.Pop@liu.se]
 * This file implements the MetaModelica generational garbage collector
 * See more information in gc.h file.
 *
 * RCS: $Id: generational.h 8047 2011-03-01 10:19:49Z perost $
 *
 */

#ifndef META_MODELICA_GC_GENERATIONAL_H_
#define META_MODELICA_GC_GENERATIONAL_H_

#if defined(__cplusplus)
extern "C" {
#endif

#include "modelica.h"

/* the allocated from C region */
typedef struct mmc_c_heap_region
{
  void **region;
  void **next;
  void **limit;
  unsigned long size;
  struct mmc_c_heap_region* next_region;
} mmc_c_heap_region_t;

struct mmc_GC_gen_state_type {
  void **young_next, **young_limit;
  void **ATP;
  void **STP;

  /* the young region */
  void        **young_region;
  unsigned long young_size;

  /* the older region */
  void        **current_region;
  void        **current_next;
  void        **reserve_region;
  unsigned long older_size;

  /* the allocated from C region */
  mmc_c_heap_region_t *c_heap;
  unsigned long c_heap_region_total_size;

  /* the roots pointing from older to younger */
  void         **array_trail;
  unsigned long array_trail_size;

  void         **share_trail[2];
  unsigned long share_trail_size;
};
typedef struct mmc_GC_gen_state_type mmc_GC_gen_state_type;

#define mmc_GC_gen_state_ATP           (mmc_GC_state->gen.ATP)
#define mmc_GC_gen_state_STP           (mmc_GC_state->gen.STP)
#define mmc_GC_gen_state_young_next    (mmc_GC_state->gen.young_next)
#define mmc_GC_gen_state_young_limit   (mmc_GC_state->gen.young_limit)
#define mmc_GC_gen_state_c_heap        (mmc_GC_state->gen.c_heap)

#define MMC_ALLOC(VAR,NWORDS) \
  do{\
    (VAR) = (void*)mmc_young_next; \
    if((mmc_young_next = (void**)(VAR)+(NWORDS)) >= mmc_young_limit) \
      (VAR) = mmc_prim_gcalloc((NWORDS)); \
  } while(0)

extern void mmc_gcinit(void);
extern void* mmc_minor_collection(void);
extern void *mmc_gen_alloc_words(unsigned nwords);
extern void mmc_exit(int status);

#if defined(__cplusplus)
}
#endif

#endif /* META_MODELICA_GC_GENERATIONAL_H_ */

