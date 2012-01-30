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
 * This file implements the new MetaModelica Garbage Collector
 * which is a mark-and-sweep collector. See more information
 * in gc.h file.
 *
 * RCS: $Id: generational.c 8047 2011-03-01 10:19:49Z perost $
 *
 */


/* generational.c
 * A simple 2-generational copying compacting garbage collector for MMC.
 *
 * There are two main memory areas:
 * -  The young region, where objects are initially allocated.
 * -  The older region, to which young objects are promoted if
 *  they survive a minor collection.
 *  The older region is split in two halves, current and reserve, and
 *  behaves roughly as in a conventional two-space copying collector.
 *  The size of any of these regions must be a multiple (2 or higher)
 *   of MMC_YOUNG_SIZE, in order to guarantee that a minor collection of the
 *  young region cannot overflow the current region.
 *  If, after a minor collection, the available space in the current
 *  region is less than MMC_YOUNG_SIZE, a major collection is performed to
 *  copy the live parts of the current region to the reserve region;
 *  then the current and reserve regions are swapped. Should less than
 *  MMC_YOUNG_SIZE space be available after the major collection, then the
 *  objects are copied to new and larger older regions, and the original
 *  older regions are deallocated.
 *
 * The MMC trail is used to register locations in the older region that may
 * refer to objects in the young region. The entire trail is always scanned.
 * (Eventually, the Uppsala Prolog collector [see PLILP'94], may be used.)

 2005-01-10 added by Adrian Pop, adrpo@ida.liu.se
 * The MMC aray_trail is used to register locations in the older region that
 * may refer to objects in the young region. The entire arrays present in the
 * trail are scanned for the pointers into younger region.
 */
#include "modelica.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>  /* strerror() */
#include <errno.h>
#include <stdarg.h>
#include <assert.h>
#include <time.h>

#define MMC_CLOCKS_PER_SEC	1000	/* milliseconds */

unsigned long mmc_prim_clock(void)
{
  double scale = (double)MMC_CLOCKS_PER_SEC / (double)CLOCKS_PER_SEC;
  return (unsigned long)((double)clock() * scale);
}


extern void **mmc_young_region;
extern void* mmc_minor_collection();
extern void **mmc_older_alloc(mmc_uint_t nwords);

/* the young region */
unsigned long   mmc_young_size;
void          **mmc_young_region;

/* the older region */
unsigned long   mmc_older_size;
void          **mmc_current_region;
void          **mmc_current_next;
void          **mmc_reserve_region;

/* deal with external C heap */
mmc_c_heap_region_t *mmc_c_heap;
unsigned long mmc_c_heap_region_total_size;
mmc_uint_t mmc_c_heap_collect_flag = 0;
unsigned long mmc_c_heap_collect_count;
char mmc_allocated_in_older = 0;

/*
 * A string cache for implementing string sharing
 * adrpo 2009-03-05
 */
void* mmc_string_cache[MMC_STRING_CACHE_MAX];
unsigned long mmc_string_cache_index = 0;
unsigned long mmc_total_shared_strings = 0;
unsigned long mmc_total_shared_strings_words = 0;

/* 
 * if the second argument is != 0 the function will not 
 * exit even if it fails to allocate the desired memory
 */
static void **mmc_alloc_core(mmc_uint_t nslots, mmc_uint_t do_not_exit) {
  unsigned long nbytes = nslots * sizeof(void*);
  void **p = NULL;
  p = malloc(nbytes);
  /* 
   * we should not exit if do_not_exit is set as 
   * we still might have a chance if we allocate 
   * less memory, but still enough.
   */
  if ( !p && !do_not_exit) 
  {
    fprintf(stderr, "malloc(%lu) failed!\n", nbytes); fflush(stderr);
    return NULL;
  }
  return p;
}

static void mmc_free_core(void **p, size_t nslots_unused) {
  free(p);
}

/* the roots */
#if  !defined(MMC_ARRAY_TRAIL_SIZE)
#define MMC_ARRAY_TRAIL_SIZE  (1024*1024)
#endif
unsigned long mmc_array_trail_size = 0;
/* stores the pointers from older to young (write barrier) */
void *mmc_array_trail[MMC_ARRAY_TRAIL_SIZE];

#if  !defined(MMC_SHARE_TRAIL_SIZE)
#define MMC_SHARE_TRAIL_SIZE  (1024*1024)
#endif
unsigned long mmc_share_trail_size = 0;
/* stores references that can be shared because values they point to are semantically equal */
void *mmc_share_trail[MMC_SHARE_TRAIL_SIZE][2];


/* misc */
char mmc_flag_bench;
char mmc_flag_gclog = 1;
unsigned long mmc_clock_start;
unsigned long mmc_gc_start_clock;
unsigned long mmc_gc_end_clock;
double mmc_gc_total_time;
char mmc_flag_log;
unsigned long mmc_minorgc_count;
unsigned long mmc_majorgc_count;
unsigned long mmc_call_count;
/* adrpo added 2004-11-10 */
unsigned long mmc_allocated_from_c;
/* adrpo added 2004-11-02 */
unsigned long mmc_heap_expansions_count;
unsigned long mmc_heap_shrinkings_count;

#if defined(__GNUC__)
#define INLINE __inline__
#elif defined(_MSC_VER)
/* Visual C++ */
# ifndef INLINE
#  define INLINE __inline
# endif
#else
#define INLINE /*empty*/
#endif

/*
 * function to check if this pointer is allocated
 * in the managed C heap
 */
static INLINE int mmc_is_allocated_on_c_heap(void** p) {
  mmc_c_heap_region_t* current = mmc_c_heap;
  while (current != NULL) {
    if (p >= current->region && p <= current->next) {
      /* bingo, we have a hit */
      return 1;
    }
    current = current->next_region;
  }
  return 0;
}

static INLINE int mmc_is_allocated_on_young(void** p) {
  if (p >= (void**)mmc_young_region && p <= (void**)mmc_GC_gen_state_young_limit) 
  {
      /* bingo, we have a hit */
      return 1;
  }
  return 0;
}


/*
 * function to allocate the managed C heap
 */
mmc_c_heap_region_t* mmc_alloc_c_heap_region(mmc_uint_t nslots) {
  mmc_c_heap_region_t *tmp = NULL;
  tmp = (mmc_c_heap_region_t*)malloc(sizeof(mmc_c_heap_region_t));
  tmp->region = mmc_alloc_core(nslots, MMC_EXIT_ON_FAILURE);
  tmp->size = nslots;
  tmp->limit = tmp->region + nslots;
  tmp->next = tmp->region;
  tmp->next_region = NULL;
  return tmp;
}

/*
 * function to free the managed C heap
 */
void mmc_free_c_heap_region() {
  mmc_c_heap_region_t* current = mmc_c_heap, *tmp = NULL;
  /* if we haven't use it at all, don't free it */
  if (mmc_c_heap->region == mmc_c_heap->next)
    return;
  ++mmc_c_heap_collect_count;
  while (current != NULL) {
    mmc_free_core(current->region, current->size);
    // set it to start again.
    //current->next = current->region;
    tmp = current;
    current = current->next_region;
    free(tmp);
  }
  /* allocate a new C managed heap for the next round */
  mmc_c_heap = mmc_alloc_c_heap_region(MMC_C_HEAP_REGION_SIZE);
  mmc_c_heap_region_total_size = 0;
  mmc_string_cache_index = 0;
}

/*
 * function to init the garbage collector
 */
void mmc_gcinit(void) {
  if (mmc_flag_gclog)
    mmc_gc_start_clock = mmc_prim_clock();

  mmc_gc_total_time = 0;
  memset(&mmc_GC_state->gen, 0, sizeof(mmc_GC_gen_state_type));
  mmc_array_trail_size = MMC_ARRAY_TRAIL_SIZE;


  mmc_GC_state->gen.ATP = &mmc_array_trail[MMC_ARRAY_TRAIL_SIZE]; /* ATP */
  mmc_GC_state->gen.STP = &mmc_share_trail[MMC_SHARE_TRAIL_SIZE][2]; /* STP */
  mmc_GC_state->gen.array_trail = &mmc_array_trail[0];
  mmc_GC_state->gen.array_trail_size = mmc_array_trail_size;

  if (mmc_young_size == 0)
    mmc_young_size = MMC_YOUNG_SIZE;
  mmc_young_region = mmc_alloc_core(mmc_young_size, MMC_EXIT_ON_FAILURE);
  mmc_GC_gen_state_young_next = mmc_young_region;
  mmc_GC_gen_state_young_limit = mmc_young_region + mmc_young_size;
  mmc_older_size = 4*mmc_young_size;
  mmc_current_region = mmc_alloc_core(mmc_older_size, MMC_EXIT_ON_FAILURE);
  mmc_current_next = mmc_current_region;
  mmc_reserve_region = NULL;
  /* deal with C allocated data */
  mmc_c_heap_collect_count = 0;
  mmc_allocated_from_c = 0;
  mmc_c_heap = mmc_alloc_c_heap_region(MMC_C_HEAP_REGION_SIZE);
  mmc_c_heap_region_total_size = 0;

  if (mmc_flag_gclog)
  {
    mmc_gc_end_clock = mmc_prim_clock();
    mmc_gc_total_time += (double)(mmc_gc_end_clock - mmc_gc_start_clock) / (double)MMC_CLOCKS_PER_SEC;
  }
}

void mmc_exit(int status) {
  if (mmc_flag_log) {
    fprintf(
        stderr,
        "[HEAP:\t%lu minor collections, %lu major collections, %lu words currently in use]\n",
        mmc_minorgc_count, mmc_majorgc_count,
        (unsigned long)(mmc_GC_gen_state_young_next - mmc_young_region)
            + (unsigned long)(mmc_current_next - mmc_current_region)
            + (unsigned long)mmc_c_heap_region_total_size);
    fprintf(
        stderr,
        "[HEAP:\t%lu words allocated to young, %lu words allocated to current, %lu/%lu heap expansions/shrinkings performed]\n",
        (unsigned long)mmc_young_size, /* MMC_YOUNG_SIZE, */
        (unsigned long)mmc_older_size,
        (unsigned long)(mmc_heap_expansions_count),
    (unsigned long)(mmc_heap_shrinkings_count));
    fprintf(
        stderr,
        "[HEAP: \t%lu words allocated into managed C heap (from mk_* functions), collected %lu times, remaining uncollected %lu words]\n",
        mmc_allocated_from_c, mmc_c_heap_collect_count,
        mmc_c_heap_region_total_size);
    fprintf(stderr, "[HEAP: \t%lu strings totaling %lu words where shared]\n",
        mmc_total_shared_strings, mmc_total_shared_strings_words);
    fprintf(stderr, "[HEAP:\t%#.2f seconds wasted while doing GC]\n",
        mmc_gc_total_time);
    fprintf(stderr,
        "[ARRAY:\t%lu words currently in use in the array trail]\n",
        (unsigned long)(&mmc_array_trail[MMC_ARRAY_TRAIL_SIZE] - mmc_GC_gen_state_ATP));
    fprintf(stderr, "[MOTOR:\t%lu tailcalls performed]\n", mmc_call_count);
  }
  if (mmc_flag_bench) {
    unsigned long mmc_clock_end = mmc_prim_clock();
    double secs = (double)(mmc_clock_end - mmc_clock_start)
        / (double)MMC_CLOCKS_PER_SEC;
    fprintf(
        stderr,
        "[%s:\t%#.2f seconds total from which %#.2f seconds GC, %lu minor collections, %lu major collections]\n",
        status ? "FAIL" : "BENCH", secs, mmc_gc_total_time, mmc_minorgc_count,
        mmc_majorgc_count);
  }
  exit(status);
}

int mmc_isYoungOrOlder(void *p)
{
  return 
      (((char*)mmc_young_region <= (char*)p && (char*)mmc_young_region + mmc_young_size >= (char*)p) /* p in young */ ||
       ((char*)mmc_current_region <= (char*)p && (char*)mmc_current_region + mmc_older_size >= (char*)p) /* p in older */);
}

/* Forward the vector scan[0..nwords-1] of values using next as the allocation
 * pointer. Return the updated allocation pointer.
 * Objects located outside of [region_low,region_low+region_nbytes] remain in place.
 */
static INLINE void **mmc_forward_vec(void **scan, mmc_uint_t nwords, void **next, char *region_low, mmc_uint_t region_nbytes) 
{
  for (; nwords > 0; ++scan, --nwords) {
    /* Forward the value pointed to by `*scan' to the next region.
     * Update `*scan' with the new address.
     * Leave forwarding address behind in `**scan'.
     * Update the allocation pointer `next'.
     */
    void **old;
    mmc_uint_t hdr, save = 0, ctor = 0, slots = 0;

    /* If the value is immediate, do nothing. */
    old = (void**)*scan;

    if (!old || MMC_IS_IMMEDIATE(old))
      continue;

    /* If not allocated in this region, do nothing. */
    if ( (mmc_uint_t)((char*)old - region_low) >= region_nbytes ) 
    {
      /* If is not allocated in the C heap, do not forward it! */
      if (mmc_c_heap_collect_flag && mmc_is_allocated_on_c_heap((void**)MMC_UNTAGPTR(old)))
      {
        // collect to next region
      } 
      else 
      {
        continue;
      }
    }

    /* If already moved, replace `*scan' with the forwarding address. */
    hdr = MMC_GETHDR(old);
    if (MMC_HDR_IS_FORWARD(hdr)) {
      *scan = (void*)hdr;
      continue;
    }
    save = hdr;
    ctor = MMC_HDRCTOR(save);
    slots = MMC_HDRSLOTS(hdr);
    //assert(ctor != 155);

    /* Copy node to next region.
     * Update `*scan' with new address.
     * Leave forwarding address behind in old node.
     */
    *scan = MMC_TAGPTR(next);
    old = (void**)MMC_UNTAGPTR(old);
    *old++ = MMC_TAGPTR(next);
    *next++ = (void*)hdr;
    for (hdr = MMC_HDRSLOTS(hdr); hdr > 0; --hdr)
        *next++ = *old++;
  }
  return next;
}

/* walk all the objects from the given region scan[0..nwords-1] 
 * and if they contain pointes pointing in interval [region_low,region_low+region_nbytes]
 * forward the pointers to the address pointed by next.
 */
static INLINE void **mmc_forward_back_links(void **scan, mmc_uint_t nwords, void **next, char *region_low, mmc_uint_t region_nbytes) 
{
  mmc_uint_t slots = 0, ctor = 0, i = 0, start = 0;
  mmc_sint_t n = nwords;
  for (; n > 0;) {
    /* forward all pointer from object pointed by `*scan' to the next region.
     * update the pointer with the new address.
     * leave forwarding address behind in `**scan'.
     * update the allocation pointer `next'.
     */
    void **old = NULL, **pp = NULL;
    mmc_uint_t hdr = 0;

    // we have the header DIRECTLY at *scan!
    old = (void**)MMC_TAGPTR(scan);
    /* if the value is immediate, do nothing. */
    if (MMC_IS_IMMEDIATE(old))
    {
      scan++;
      n--;
      assert(n >= 0);
      continue;
    }

    //printAny(old); fprintf(stderr, "\n"); fflush(stderr);

    /* if already moved, replace `*scan' with the forwarding address. */
    hdr = MMC_GETHDR(old);
    if (MMC_HDR_IS_FORWARD(hdr)) 
    {
      /* fetch the slots from the forward address */
      void* p = (*(void**)(*scan));
      //fprintf(stderr, "already forwarded:"); printAny(p); fprintf(stderr, "\n"); fflush(stderr);
      if (MMC_IS_IMMEDIATE(p))
      {
        slots = 0;
      }
      else
      {
        slots = MMC_HDRSLOTS(MMC_GETHDR(p));
      }
      scan += slots+1;
      n    -= slots+1;
      assert(n >= 0);
      continue;
    }

    slots = MMC_HDRSLOTS(hdr);
    
    /* if it doens't have pointers, skip it! */
    if (!MMC_HDRHASPTRS(hdr)) {
      //fprintf(stderr, "skipping link:"); printAny(old); fprintf(stderr, "\n"); fflush(stderr);
      scan += slots+1;
      n    -= slots+1;
      assert(n >= 0);
      continue;
    }

    //fprintf(stderr, "checking for links:"); printAny(old); fprintf(stderr, "\n"); fflush(stderr);
    ctor  = MMC_HDRCTOR(hdr);
    if (slots > 0 && ctor != MMC_ARRAY_TAG && ctor > 1) /* RECORD */
    {
      start = 1; /* ignore the fields slot! */
    }
    else
      start = 0; /* do NOT ignore the fields slot! */
    assert(slots <= MMC_MAX_SLOTS);
    pp = MMC_STRUCTDATA(old);
    /* 
     * scan the object for pointers into [region_low,  region_low+region_nbytes].
     */
    //for (i = start; i < slots; i++)
    {
      next = mmc_forward_vec(pp+start, slots-start, next, region_low, region_nbytes);
    }
    scan += slots+1;
    n    -= slots+1;
    assert(n >= 0);
  }
  return next;
}

/* Forward all roots. Return updated allocation pointer.
 * Objects located outside of [region_low,region_low+region_nbytes] remain in place.
 */
static void **mmc_forward_all(void **next, char *region_low, mmc_uint_t region_nbytes)
{
  mmc_c_heap_region_t *cr;
  size_t index = 0;

  // forward the back-links first!
  if (mmc_allocated_in_older)
  {
    // search for pointers from older to young and forward those too! 
    next = mmc_forward_back_links(mmc_current_region, mmc_current_next-mmc_current_region, next, region_low, region_nbytes);

    /* forward heap c, if there is any! */
    cr = mmc_c_heap;
    if (cr->region < cr->next && (cr->region != cr->next))
    {
      while(cr != NULL)
      {
        // search for pointers from external heap to young and forward those too! 
        next = mmc_forward_back_links(cr->region, cr->next - cr->region, next, region_low, region_nbytes);
        cr = cr->next_region;
      }
    }
    mmc_allocated_in_older = 0;
  }

  /* forward roots */
  for(index = 0; index < mmc_GC_state->roots.current; index++)
  {
    //fprintf(stderr, "forwarding root:"); printAny(mmc_GC_state->roots.start[index]); fprintf(stderr, "\n"); fflush(stderr);
    next = mmc_forward_vec((void**)(mmc_GC_state->roots.start[index].start), mmc_GC_state->roots.start[index].count, next, region_low, region_nbytes);
  }

  /* forwarding of array_setnth/array_update elements */
  {
    void **ATP= mmc_GC_gen_state_ATP;
    mmc_sint_t cnt = &mmc_array_trail[MMC_ARRAY_TRAIL_SIZE] - ATP;
    next = mmc_forward_vec(ATP, (mmc_uint_t)cnt, next, region_low, region_nbytes);
    /* take all the arrays present in the trail and scan them for pointers into
     * the younger generation
     */
    for (; --cnt >= 0; ++ATP) {
      void *array_node = *ATP; /* known to be an array node */
      mmc_uint_t i;
      mmc_uint_t nrelements= MMC_GETHDR(array_node);
      if ( MMC_HDR_IS_FORWARD(nrelements)) {
        continue;
      }
      nrelements = MMC_HDRSLOTS(nrelements);
      for (i = 0; i < nrelements; i++) {
        next = mmc_forward_vec(&(MMC_STRUCTDATA(array_node)[i]), 1, next, region_low, region_nbytes);
      }
    }
    mmc_GC_gen_state_ATP = &mmc_array_trail[MMC_ARRAY_TRAIL_SIZE];
  }
  
  /* forward global roots from roots.c */
  next = mmc_forward_vec(mmc_GC_state->global_roots, MMC_GC_GLOBAL_ROOTS_SIZE, next, region_low, region_nbytes);

  return next;
}

static void **mmc_collect(void **scan, char *region_low, mmc_uint_t region_nbytes)
{
  /* void **scan_old = scan; */
  void **next;

  /* forward all roots */
  next = mmc_forward_all(scan, region_low, region_nbytes);

  /* compute the transitive closure of the copied roots */
  while (scan < next) {
    mmc_uint_t hdr   = *(mmc_uint_t*)scan;
    mmc_uint_t slots = MMC_HDRSLOTS(hdr);
    mmc_uint_t ctor = MMC_HDRCTOR(hdr);
    mmc_uint_t start = 0;
    // we should NOT have forward here!
    assert(!MMC_HDR_IS_FORWARD(hdr));
    ++scan; /* since slots doesn't include the header itself */
    if (MMC_HDRHASPTRS(hdr))
    {
      if (slots == 2 && ctor == 1 && hdr == 2052 && mmc_minorgc_count == 9)
      {
        //fprintf(stderr, "transitive forward:"); printAny(*scan); fprintf(stderr, "\n"); fflush(stderr);
        int i;
        i = 1;
      }
      if (slots > 0 && ctor != MMC_ARRAY_TAG && ctor > 1) /* RECORD */
      {
        start = 1; /* ignore the fields slot! */
      }
      else
        start = 0; /* do NOT ignore the fields slot! */

      next = mmc_forward_vec(scan+start, slots-start, next, region_low, region_nbytes);
    }
    scan += slots;
  }
  /* return final allocation pointer */
  return next;
}

/* Do a major collection. */

static void* mmc_major_collection(mmc_uint_t nwords)
{
  void **next =0, **scan = 0, **rr = 0; 
  long current_inuse = 0;
  long used_before = (long)(mmc_current_next - mmc_current_region);

  ++mmc_majorgc_count;
  if (mmc_flag_gclog && !mmc_flag_bench)
  {
    fprintf(stderr, "\n[major collection: time: %10.3g N: %ld, F: %ld, O: %ld Y: %ld, O/Y: %ld, W: %ld, C: %ld]",
      mmc_gc_total_time,
      (long)(mmc_c_heap_region_total_size + nwords + mmc_young_size),
      (long)(mmc_older_size - (mmc_current_next - mmc_current_region)),
      (long)mmc_older_size,
      (long)mmc_young_size,
      (long)(mmc_older_size/mmc_young_size),
      (long)nwords,
      (long)mmc_c_heap_region_total_size
      ); 
    fprintf(stderr, "\n[major collection #%lu..", mmc_majorgc_count);
    fflush(stderr);
  }

  /* allocate the reserve region */
  if (!mmc_reserve_region)
  {
    /* 
   * see if we have enough space to add 
   * external C heap data + the young gen + what we need to allocate now (nwords)
   */
    if (((long)mmc_c_heap_region_total_size + (long)nwords + (long)mmc_young_size)
        < ((long)mmc_older_size - ((long)mmc_current_next - (long)mmc_current_region)))
    {
      /* we have enough space */
      if (mmc_flag_gclog && !mmc_flag_bench)
      {
        mmc_heap_expansions_count++;
        fprintf(stderr, " keep heap size ..."); fflush(stderr);
      }
      rr = mmc_alloc_core(mmc_older_size, MMC_EXIT_ON_FAILURE);
      if (rr == NULL) 
      {
        fprintf(stderr, "returning NULL (not enough memory) from mmc_major_collection!\n");
        fflush(stderr);
        return NULL;
      }
      mmc_reserve_region = rr;
    }
    else 
    {
      /* we DON'T have enough space , do a heap expansion directly */
      if (mmc_flag_gclog && !mmc_flag_bench)
      {
        mmc_heap_expansions_count++;
        fprintf(stderr, " expanding heap (A) ..."); fflush(stderr);
      }
      mmc_older_size += mmc_c_heap_region_total_size + nwords + mmc_young_size;
      rr = mmc_alloc_core(mmc_older_size, MMC_EXIT_ON_FAILURE);
      if (rr == NULL) 
      {
        fprintf(stderr, "returning NULL (not enough memory) from mmc_major_collection!\n");
        fflush(stderr);
        return NULL;
      }
      mmc_reserve_region = rr;
    }
  }
  if (mmc_c_heap_region_total_size != 0) {
    mmc_c_heap_collect_flag = 1;
  }
  /* collect the current region, forwarding to the reserve region */
  next = mmc_collect(mmc_reserve_region, (char*)mmc_current_region, (char*)mmc_current_next - (char*)mmc_current_region);
  assert((unsigned long)(next-mmc_reserve_region) < mmc_older_size);
  /* free our mmc_c_heap! */
  if (mmc_c_heap_collect_flag) {
    mmc_c_heap_collect_flag = 0;
    mmc_free_c_heap_region();
  }

  /* update the older region state variables */
  /* switch reserve with current */
  mmc_current_next = next;
  scan = mmc_reserve_region;
  next = mmc_current_region;
  mmc_current_region = scan;
  mmc_reserve_region = next;

  current_inuse = mmc_current_next - mmc_current_region;

  if (mmc_flag_gclog && !mmc_flag_bench)
  {
     mmc_heap_expansions_count++;
     fprintf(stderr, " AC O/U: %.3g CO: %ld O/Y: %.3g U/Y: %.3g", 
       (double)mmc_older_size/(double)current_inuse,
       (long)(used_before-current_inuse),
       (double)mmc_older_size/(double)mmc_young_size,
       (double)current_inuse/(double)mmc_young_size
       );
     fflush(stderr);
  }

  /* 
   * Check if the older region should be expanded.
   * Expansion is triggered if more than 90% is in use.
   * The new size is chosen to make the heap at least 
   * 50% free or as much as free memory goes and is 
   * still enough.
   */
  current_inuse += nwords + mmc_c_heap_region_total_size;

  /* do a heap expansion if needed */
  if ( (100.0*((double)current_inuse)/(double)mmc_older_size) > 90.0 ) /* current_inuse > 90/100 * mmc_older_size */
  {
    mmc_uint_t new_size = 0;

    if (mmc_flag_gclog && !mmc_flag_bench) {
      mmc_heap_expansions_count++;
      fprintf(stderr, " expanding heap (B) [used: %.3g%%] ...", (((double)current_inuse*100.0)/(double)mmc_older_size));
      fflush(stderr);
    }

    new_size = (2 * current_inuse) + mmc_young_size;
    
    /* expand the older region */
    mmc_free_core(mmc_reserve_region, mmc_older_size);
    rr = mmc_alloc_core(new_size, MMC_NO_EXIT_ON_FAILURE);
    if (rr == NULL) 
    {
      fprintf(stderr, "returning NULL (not enough memory) from mmc_major_collection!\n");
      fflush(stderr);
      return NULL;
    }
    mmc_reserve_region = rr;

    if ( !mmc_reserve_region ) /* we couldn't allocate that much, try again, with less memory */
    {
      if (mmc_flag_gclog && !mmc_flag_bench) {
        fprintf(stderr, " (LESS %%50) "); fflush(stderr);
      }
      new_size = current_inuse + mmc_young_size; /* try to allocate less */
      rr = mmc_alloc_core(new_size, MMC_EXIT_ON_FAILURE);
      if (rr == NULL) 
      {
        fprintf(stderr, "returning NULL (not enough memory) from mmc_major_collection!\n");
        fflush(stderr);
        return NULL;
      }
      mmc_reserve_region = rr;
    }
    else
    {
      if (mmc_flag_gclog && !mmc_flag_bench) {
          fprintf(stderr, " (MORE 50%%) "); fflush(stderr);
      }
    }
    
    if (mmc_c_heap_region_total_size != 0) {
       mmc_c_heap_collect_flag = 1;
    }

    next = mmc_collect(mmc_reserve_region, (char*)mmc_current_region, (char*)mmc_current_next - (char*)mmc_current_region);
    assert(next-mmc_reserve_region < new_size);
    /* free our mmc_c_heap! */
    if (mmc_c_heap_collect_flag) {
       mmc_c_heap_collect_flag = 0;
       mmc_free_c_heap_region();
    }

    mmc_current_next = next;
    mmc_free_core(mmc_current_region, mmc_older_size);
    mmc_current_region = mmc_reserve_region;
    mmc_older_size = new_size;
    mmc_reserve_region = NULL;

    current_inuse = mmc_current_next - mmc_current_region;
  } 
  else if ( /* do a heap shrink if only 15% is used and it was an expansion */
           100.0*((double)current_inuse/(double)mmc_older_size) <= 20.0 && /* less than 20% used */
           (double)mmc_young_size * 4.0 < (double)mmc_older_size  /* older is at least 4 times the young */
          )
  {
    mmc_uint_t new_size = 0;
    mmc_uint_t ratio = 0;

    ratio = (current_inuse/mmc_young_size) + 2 /* we need to have at least young free */;
    if (ratio < 4) 
      ratio = 4;
    else 
      if (ratio % 2) /* not even */
        ratio++; /* make it even */
        
    new_size = ratio * mmc_young_size;

    if (mmc_flag_gclog && !mmc_flag_bench) {
      mmc_heap_shrinkings_count++;
      fprintf(stderr, " shrinking heap [ratio: %ld, before: %.3g%%, after: %.3g%%] ...", 
        (long)ratio,
        100.0*((double)current_inuse/(double)mmc_older_size),
        100.0*((double)current_inuse/(double)new_size)
        ); 
      fflush(stderr);
    }

    /* shrink the older region */

    /* free the reserve */
    mmc_free_core(mmc_reserve_region, mmc_older_size);
    /* allocate the reserve */
    rr = mmc_alloc_core(new_size, MMC_EXIT_ON_FAILURE);
    if (rr == NULL) 
    {
      fprintf(stderr, "returning NULL (not enough memory) from mmc_major_collection!\n");
      fflush(stderr);
      return NULL;
    }
    mmc_reserve_region = rr;

    /* collect */
    next = mmc_collect(mmc_reserve_region, (char*)mmc_current_region, (char*)mmc_current_next - (char*)mmc_current_region);
    assert(next-mmc_reserve_region < new_size);
    /* set the next */
    mmc_current_next = next;
    /* free the current */
    mmc_free_core(mmc_current_region, mmc_older_size);
    /* switch regions reserve becomes next */
    mmc_current_region = mmc_reserve_region;
    /* set the new size */
    mmc_older_size = new_size;
    /* nullize the reserve */
    mmc_reserve_region = NULL;

    current_inuse = mmc_current_next - mmc_current_region;
  } 
  else 
  {
    mmc_free_core(mmc_reserve_region, mmc_older_size);
    mmc_reserve_region = NULL;
  }
  /* done with the major collection */
  if (mmc_flag_gclog && !mmc_flag_bench)
  {
    fprintf(stderr, " used: %.3g%%]", 100.0*((double)current_inuse/(double)mmc_older_size));
    fflush(stderr);
  }

  return mmc_current_next;
}

/* Do a minor collection. */

void* mmc_minor_collection() {
  void **next;
  mmc_uint_t current_nfree = mmc_older_size - (mmc_current_next - mmc_current_region);
  
  if (mmc_flag_gclog)
    mmc_gc_start_clock = mmc_prim_clock();

  /* increase the minor collections */
  ++mmc_minorgc_count;

  if (mmc_flag_gclog && !mmc_flag_bench) {
    fprintf(stderr, "\nbefore minor collection #%ld c heap: %p %p",
      (long)mmc_minorgc_count,
      mmc_c_heap->region,
      mmc_c_heap->next
      );
    fflush(stderr);
  }

  /*
   * do we have enough space in the current region
   * to also forward the mmc_c_heap?
   */
  if (mmc_c_heap_region_total_size &&
      (mmc_older_size - (mmc_current_next - mmc_current_region) >
      (mmc_young_size + mmc_c_heap_region_total_size))) {
    /* we have enough space, signal to go on with the forwarding */
    mmc_c_heap_collect_flag = 1;
  }
  /* collect the young region, forwarding to the current region */
  next = mmc_collect(mmc_current_next, (char*)mmc_young_region,  (mmc_GC_gen_state_young_next-mmc_young_region) * sizeof(void*));
  assert(next-mmc_current_next < mmc_older_size);

  /* free our mmc_c_heap and set the flag on nothing */
  if (mmc_c_heap_collect_flag) {
    mmc_c_heap_collect_flag = 0;
    mmc_free_c_heap_region();
  }

  if (mmc_flag_gclog && !mmc_flag_bench) {
    fprintf(stderr, "\nminor collection #%ld collected: %ld c heap: %p %p",
      (long)mmc_minorgc_count,
      (long)(current_nfree - (mmc_older_size - (next - mmc_current_region))),
      mmc_c_heap->region,
      mmc_c_heap->next
      );
    fflush(stderr);
  }

  /* update the older region state variables */
  mmc_current_next = next;
  current_nfree = mmc_older_size - (next - mmc_current_region);

  /* check if a major collection should be done */
  if (mmc_c_heap_region_total_size || (current_nfree < mmc_young_size))
    if (mmc_major_collection(0) == NULL)
    {
      fprintf(stderr, "returning NULL (not enough memory) from mmc_minor_collection!\n");
      fflush(stderr);
      return NULL;
    }
  mmc_GC_gen_state_young_next = mmc_young_region;
  if (mmc_flag_gclog)
  {
    mmc_gc_end_clock = mmc_prim_clock();
    mmc_gc_total_time += (double)(mmc_gc_end_clock - mmc_gc_start_clock) / (double)MMC_CLOCKS_PER_SEC;
  }
  return mmc_current_next;
}

/* If a minor collection doesn't give us enough memory,
 * try to allocate in the current older region.
 */
void **mmc_older_alloc(mmc_uint_t nwords) {
  void **next = mmc_current_next;
  mmc_uint_t nfree = mmc_older_size - (next - mmc_current_region);
  if (!mmc_c_heap_region_total_size && nfree >= nwords + mmc_young_size)
  {
    mmc_current_next = next + nwords;
    return next;
  } else {
    if (mmc_major_collection(nwords) == NULL)
    {
      fprintf(stderr, "returning NULL (not enough memory) from mmc_older_alloc!\n");
      fflush(stderr);
      return NULL;
    }

    next = mmc_current_next;
    nfree = mmc_older_size - (next - mmc_current_region);
    if (nfree >= nwords + mmc_young_size) /* MMC_YOUNG_SIZE ) */
    {
      mmc_current_next = next + nwords;
      return next;
    }
    fprintf(stderr, "returning NULL (not enough memory) from mmc_older_alloc!\n");
    fflush(stderr);
    return NULL;
  }
}


#if 0
void shareEqual(void)
{
  void *p, *q;
  void **pp, **qq;
  mmc_uint_t slotsIdx;
#if  defined(MMC_STATE_APTR) || defined(MMC_STATE_LPTR)
  struct mmc_state *mmcState = &mmc_state;
#endif  /*MMC_STATE_APTR || MMC_STATE_LPTR*/
  if (*pp != *qq) /* if pointers are different */
  {
    /* check to see if pointers are in young or older */
    if (mmc_isYoungOrOlder((void**)MMC_UNTAGPTR(pp)) &&
      mmc_isYoungOrOlder((void**)MMC_UNTAGPTR(qq)))
    {
      mmc_uint_t idx = 0;
      /* point *pp to *qq to have sharing. */
      fprintf(stderr, "Sharing %d %p <-> %p\n", slotsIdx, *pp, *qq); fflush(stderr);
      if (*pp > *qq) /* store qq in pp as pp is > than qq */
      {
        MMC_STRUCTDATA(p)[slotsIdx] = *qq;
        if (!MMC_ISIMM(*qq))
        {
          /* also check here if the array is not already in the trail */
          for (idx = mmc_array_trail_size; &mmc_array_trail[idx] >= mmcATP; idx--)
            if (mmc_array_trail[idx] == *qq) /* if found, do not add again */
            {
              break;
            }
            /* add the address of the array into the roots to be
            taken into consideration at the garbage collection time */
            if( mmcATP == &mmc_array_trail[0] )
            {
              (void)fprintf(stderr, "Array Trail Overflow!\n"); fflush(stderr);
              mmc_exit(1);
            }

            if (!idx) /* we didn't already find it */
              *--mmcATP = p;
        }
      }
      else /* store pp in qq as qq is > than pp */
      {
        MMC_STRUCTDATA(q)[slotsIdx] = *pp;
        if (!MMC_ISIMM(*pp))
        {
          /* also check here if the array is not already in the trail */
          for (idx = mmc_array_trail_size; &mmc_array_trail[idx] >= mmcATP; idx--)
            if (mmc_array_trail[idx] == *pp) /* if found, do not add again */
            {
              break;
            }
            /* add the address of the array into the roots to be
            taken into consideration at the garbage collection time */
            if( mmcATP == &mmc_array_trail[0] )
            {
              (void)fprintf(stderr, "Array Trail Overflow!\n"); fflush(stderr);
              mmc_exit(1);
            }

            if (!idx) /* we didn't already find it */
              *--mmcATP = q;
        }
      }
    } 
  }
}
#endif


/******************************************/
/* functions previously part of yacclib.c */
/******************************************/

/*
 * functions to print externally allocated values
 */
extern void print_icon(FILE*, void*);
extern void print_rcon(FILE*, void*);
extern void print_scon(FILE*, void*);

void *mmc_gen_alloc_words(unsigned nwords) {
  void* p = NULL;
  mmc_c_heap_region_t* current = mmc_c_heap;
  if (mmc_flag_gclog)
    mmc_gc_start_clock = mmc_prim_clock();
  
  /* try to allocate in young or in older if possible! */
  if (!((void**)(mmc_GC_gen_state_young_next)+(nwords) >= (mmc_GC_gen_state_young_limit)))
  {
    p = (void*)mmc_GC_gen_state_young_next;
    mmc_GC_gen_state_young_next = (void**)(p)+(nwords);
    if (mmc_flag_gclog) {
      mmc_gc_end_clock = mmc_prim_clock();
      mmc_gc_total_time += (double)(mmc_gc_end_clock - mmc_gc_start_clock) / (double)MMC_CLOCKS_PER_SEC;
    }
    return p;
  }
  else
  {
    // no place in young, try in older! 
    void **next = mmc_current_next;
    mmc_uint_t nfree = mmc_older_size - (next - mmc_current_region);
    if (nfree >= nwords + mmc_young_size)
    {
      mmc_uint_t idx;
      mmc_current_next = next + nwords;
      p = next;
      mmc_allocated_in_older = 1;
      if (mmc_flag_gclog) {
        mmc_gc_end_clock = mmc_prim_clock();
        mmc_gc_total_time += (double)(mmc_gc_end_clock - mmc_gc_start_clock) / (double)MMC_CLOCKS_PER_SEC;
      }
      return p;
    }
  }
  
  /* try to find a big enough place in the existing regions */
  do {
    p = (void*)current->next;
    if ((current->next_region == NULL) && (void**)(p)+(nwords) < current->limit) {
      /* found our zone, update the next */
      current->next = (void**)(p)+(nwords);
      assert(current->next < current->limit);
      /* update total count */
      mmc_c_heap_region_total_size += nwords;
      mmc_allocated_from_c += nwords;

      if (mmc_flag_gclog) {
        mmc_gc_end_clock = mmc_prim_clock();
        mmc_gc_total_time += (double)(mmc_gc_end_clock - mmc_gc_start_clock) / (double)MMC_CLOCKS_PER_SEC;
      }
      /* return the pointer to available region */
      return p;
    }
    /* else, search the next zone */
    if (current->next_region == NULL)
      break;
    else
      current = current->next_region;
  } while (1);
  /* here we haven't found a big enough zone, create one */
  if (nwords > MMC_C_HEAP_REGION_SIZE)
    current->next_region = mmc_alloc_c_heap_region(nwords+1024);
  else
    current->next_region = mmc_alloc_c_heap_region(MMC_C_HEAP_REGION_SIZE+1024);
  /* we allocated our region, use it now */
  current = current->next_region;
  p = (void*)current->next;
  /* update the next */
  current->next = (void**)(p)+(nwords);
  assert(current->next < current->limit);
  /* update total count */
  mmc_c_heap_region_total_size += nwords;
  mmc_allocated_from_c += nwords;

  if (mmc_flag_gclog) {
    mmc_gc_end_clock = mmc_prim_clock();
    mmc_gc_total_time += (double)(mmc_gc_end_clock - mmc_gc_start_clock) / (double)MMC_CLOCKS_PER_SEC;
  }
  /* return the pointer to available region */
  return p;
}


//void *mk_rcon(double d) {
//  struct mmc_real *p = (struct mmc_real*)alloc_words(sizeof(struct mmc_real)/MMC_SIZE_INT);
//  p->header = MMC_REALHDR;
//  p->data = d;
//  return MMC_TAGPTR(p);
//}
//
//void *mk_scon_string_sharing(const char *s) {
//  mmc_uint_t nbytes = strlen(s);
//  mmc_uint_t header= MMC_STRINGHDR(nbytes);
//  mmc_uint_t nwords= MMC_HDRSLOTS(header) + 1;
//  if (!mmc_string_cache_index) /* no string in the cache */
//  {
//    struct mmc_string *p = alloc_words(nwords);
//    p->header = header;
//    memcpy(p->data, s, nbytes+1); /* including terminating '\0' */
//    if (mmc_string_cache_index < MMC_STRING_CACHE_MAX &&
//        nbytes < MMC_SHARED_STRING_MAX) /* add to sharing only if less than MMC_SHARED_STRING_MAX */
//      mmc_string_cache[mmc_string_cache_index++] = p;
//    return MMC_TAGPTR(p);
//  }
//  /* else, try to find if we already have the same string in the heap */
//  {
//    unsigned int i;
//    struct mmc_string *p;
//    for (i = 0; i < mmc_string_cache_index; i++)
//    {
//      p = mmc_string_cache[i];
//      if (strcmp(p->data,s) == 0)
//      {
//        mmc_total_shared_strings++;
//        mmc_total_shared_strings_words += nwords;
//        return MMC_TAGPTR(p);
//      }
//    }
//    /* no string found in cache */
//    {
//      struct mmc_string *p = alloc_words(nwords);
//      p->header = header;
//      memcpy(p->data, s, nbytes+1); /* including terminating '\0' */
//      if (mmc_string_cache_index < MMC_STRING_CACHE_MAX &&
//          nbytes < MMC_SHARED_STRING_MAX) /* add to sharing only if less than MMC_SHARED_STRING_MAX */
//        mmc_string_cache[mmc_string_cache_index++] = p;
//      return MMC_TAGPTR(p);
//    }
//  }
//}
//
//void *mk_scon_no_string_sharing(const char *s) {
//  mmc_uint_t nbytes = strlen(s);
//  mmc_uint_t header= MMC_STRINGHDR(nbytes);
//  mmc_uint_t nwords= MMC_HDRSLOTS(header) + 1;
//  struct mmc_string *p = alloc_words(nwords);
//  p->header = header;
//  memcpy(p->data, s, nbytes+1); /* including terminating '\0' */
//  return MMC_TAGPTR(p);
//}
//
//void *mk_scon(const char *s) {
//  return mmc_GC_state->settings.string_sharing ?
//       mk_scon_string_sharing(s) : mk_scon_no_string_sharing(s);
//}
//
//void *mk_box0(unsigned ctor) {
//  struct mmc_struct *p = alloc_words(1);
//  p->header = MMC_STRUCTHDR(0, ctor);
//  return MMC_TAGPTR(p);
//}
//
//void *mk_box1(unsigned ctor, void *x0) {
//  struct mmc_struct *p = alloc_words(2);
//  p->header = MMC_STRUCTHDR(1, ctor);
//  p->data[0] = x0;
//  return MMC_TAGPTR(p);
//}
//
//void *mk_box2(unsigned ctor, void *x0, void *x1) {
//  struct mmc_struct *p = alloc_words(3);
//  p->header = MMC_STRUCTHDR(2, ctor);
//  p->data[0] = x0;
//  p->data[1] = x1;
//  return MMC_TAGPTR(p);
//}
//
//void *mk_box3(unsigned ctor, void *x0, void *x1, void *x2) {
//  struct mmc_struct *p = alloc_words(4);
//  p->header = MMC_STRUCTHDR(3, ctor);
//  p->data[0] = x0;
//  p->data[1] = x1;
//  p->data[2] = x2;
//  return MMC_TAGPTR(p);
//}
//
//void *mk_box4(unsigned ctor, void *x0, void *x1, void *x2, void *x3) {
//  struct mmc_struct *p = alloc_words(5);
//  p->header = MMC_STRUCTHDR(4, ctor);
//  p->data[0] = x0;
//  p->data[1] = x1;
//  p->data[2] = x2;
//  p->data[3] = x3;
//  return MMC_TAGPTR(p);
//}
//
//void *mk_box5(unsigned ctor, void *x0, void *x1, void *x2, void *x3, void *x4) {
//  struct mmc_struct *p = alloc_words(6);
//  p->header = MMC_STRUCTHDR(5, ctor);
//  p->data[0] = x0;
//  p->data[1] = x1;
//  p->data[2] = x2;
//  p->data[3] = x3;
//  p->data[4] = x4;
//  return MMC_TAGPTR(p);
//}
//
//void *mk_box6(unsigned ctor, void *x0, void *x1, void *x2, void *x3, void *x4,
//    void *x5) {
//  struct mmc_struct *p = alloc_words(7);
//  p->header = MMC_STRUCTHDR(6, ctor);
//  p->data[0] = x0;
//  p->data[1] = x1;
//  p->data[2] = x2;
//  p->data[3] = x3;
//  p->data[4] = x4;
//  p->data[5] = x5;
//  return MMC_TAGPTR(p);
//}
//
//void *mk_box7(unsigned ctor, void *x0, void *x1, void *x2, void *x3, void *x4,
//    void *x5, void *x6) {
//  struct mmc_struct *p = alloc_words(8);
//  p->header = MMC_STRUCTHDR(7, ctor);
//  p->data[0] = x0;
//  p->data[1] = x1;
//  p->data[2] = x2;
//  p->data[3] = x3;
//  p->data[4] = x4;
//  p->data[5] = x5;
//  p->data[6] = x6;
//  return MMC_TAGPTR(p);
//}
//
//void *mk_box8(unsigned ctor, void *x0, void *x1, void *x2, void *x3, void *x4,
//    void *x5, void *x6, void *x7) {
//  struct mmc_struct *p = alloc_words(9);
//  p->header = MMC_STRUCTHDR(8, ctor);
//  p->data[0] = x0;
//  p->data[1] = x1;
//  p->data[2] = x2;
//  p->data[3] = x3;
//  p->data[4] = x4;
//  p->data[5] = x5;
//  p->data[6] = x6;
//  p->data[7] = x7;
//  return MMC_TAGPTR(p);
//}
//
//void *mk_box9(unsigned ctor, void *x0, void *x1, void *x2, void *x3, void *x4,
//    void *x5, void *x6, void *x7, void *x8) {
//  struct mmc_struct *p = alloc_words(10);
//  p->header = MMC_STRUCTHDR(9, ctor);
//  p->data[0] = x0;
//  p->data[1] = x1;
//  p->data[2] = x2;
//  p->data[3] = x3;
//  p->data[4] = x4;
//  p->data[5] = x5;
//  p->data[6] = x6;
//  p->data[7] = x7;
//  p->data[8] = x8;
//  return MMC_TAGPTR(p);
//}


void *mmc_prim_gcalloc(mmc_uint_t nwords) {
  void **p;
  if (mmc_minor_collection() == NULL)
  {
    fprintf(stderr, "returning NULL (not enough memory) from mmc_prim_gcalloc!\n");
    fflush(stderr);
    return NULL;
  }

  if (nwords > mmc_young_size)
  {
    if ( (p = mmc_older_alloc(nwords)) != 0) {
      mmc_GC_gen_state_young_next = mmc_young_region;
    } else {
      fprintf(stderr, "mmc_prim_gcalloc failed to get %lu words\n", (unsigned long)nwords);
      fprintf(stderr, "returning NULL (not enough memory) from mmc_prim_gcalloc!\n");
      fflush(stderr);
      return NULL; /* mmc_exit(1); */
    }
  } else {
    p = mmc_young_region;
    mmc_GC_gen_state_young_next = p + nwords;
  }
  return (void*)p;
}

void *mmc_prim_alloc(mmc_uint_t nwords)
{
  void **p= mmc_GC_gen_state_young_next;
  if ( (mmc_GC_gen_state_young_next = p + nwords) >= mmc_GC_gen_state_young_limit)
    p = mmc_prim_gcalloc(nwords);
  return p;
}



