/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
 *   Jonathan Schleifer <js@heap.zone>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE.QPL included in
 * the packaging of this file.
 *
 * Alternatively, it may be distributed under the terms of the GNU General
 * Public License, either version 2 or 3, which can be found in the file
 * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the packaging of this
 * file.
 */

#include "config.h"

#import "runtime-private.h"

#ifdef OF_HAVE_THREADS
# import "threading.h"
#endif

/* All globals used by the runtime */
struct objc_globals {
	/* arc.m */
	struct objc_hashtable *weak_refs;
#ifdef OF_HAVE_THREADS
	of_spinlock_t weak_refs_lock;
#endif

	/* category.m */
	struct objc_hashtable *categories;

	/* class.m */
	struct objc_hashtable *classes;
	unsigned classes_cnt;
	Class *load_queue;
	size_t load_queue_cnt;
	struct objc_dtable *empty_dtable;
	unsigned lookups_till_fast_path;
	struct objc_sparsearray *fast_path;

	/* dtable.m */
	struct objc_dtable_level2 *empty_dtable_level2;
#ifdef OF_SELUID24
	struct objc_dtable_level3 *empty_dtable_level3;
#endif

	/* lookup.m */
	IMP forward_handler;
	IMP forward_handler_stret;

	/* misc.m */
	objc_enumeration_mutation_handler enumeration_mutation_handler;

	/* property.m */
#ifdef OF_HAVE_THREADS
# define NUM_PROPERTY_LOCKS 8	/* needs to be a power of 2 */
	of_spinlock_t property_locks[NUM_PROPERTY_LOCKS];
#endif

	/* selector.m */
	struct objc_hashtable *selectors;
	uint32_t selectors_cnt;
	struct objc_sparsearray *selector_names;
	void **ptrs_to_free;
	size_t ptrs_to_free_cnt;

	/* static-instances.m */
	struct objc_abi_static_instances **static_instances;
	size_t static_instances_cnt;

	/* synchronized.m */
#ifdef OF_HAVE_THREADS
	struct synchronized_lock {
		id object;
		int count;
		of_rmutex_t rmutex;
		struct synchronized_lock *next;
	} *synchronized_locks;
	of_mutex_t synchronized_locks_lock;
#endif

	/* threading.m */
#ifdef OF_HAVE_THREADS
	of_rmutex_t global_mutex;
	of_once_t global_once_control;
#endif
};

extern struct objc_globals objc_globals;
