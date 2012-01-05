/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
 *   Jonathan Schleifer <js@webkeks.org>
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

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include <sys/types.h>

#ifdef OF_OBJFW_RUNTIME
# import <objfw-rt.h>
#else
# import <objc/objc.h>
#endif

#import "threading.h"

struct lock_s {
	id		 object;
	size_t		 count;
	size_t		 recursion;
	of_thread_t	 thread;
	of_mutex_t	 mutex;
};

static of_mutex_t mutex;
static struct lock_s *locks = NULL;
static ssize_t numLocks = 0;

#define SYNC_ERR(f)							\
	{								\
		fprintf(stderr, "WARNING: %s failed in line %d!\n"	\
		    "WARNING: This might result in a race "		\
		    "condition!\n", f, __LINE__);			\
		return 1;						\
	}

BOOL
objc_sync_init(void)
{
	return of_mutex_new(&mutex);
}

int
objc_sync_enter(id object)
{
	ssize_t i;

	if (object == nil)
		return 0;

	if (!of_mutex_lock(&mutex))
		SYNC_ERR("of_mutex_lock(&mutex)");

	for (i = numLocks - 1; i >= 0; i--) {
		if (locks[i].object == object) {
			if (of_thread_is_current(locks[i].thread))
				locks[i].recursion++;
			else {
				/* Make sure objc_sync_exit doesn't free it */
				locks[i].count++;

				/* Unlock so objc_sync_exit can return */
				if (!of_mutex_unlock(&mutex))
					SYNC_ERR("of_mutex_unlock(&mutex)");

				if (!of_mutex_lock(&locks[i].mutex)) {
					of_mutex_unlock(&mutex);
					SYNC_ERR(
					    "of_mutex_lock(&locks[i].mutex");
				}

				if (!of_mutex_lock(&mutex))
					SYNC_ERR("of_mutex_lock(&mutex)");

				assert(locks[i].recursion == 0);

				/* Update lock's active thread */
				locks[i].thread = of_thread_current();
			}

			if (!of_mutex_unlock(&mutex))
				SYNC_ERR("of_mutex_unlock(&mutex)");

			return 0;
		}
	}

	if (locks == NULL) {
		if ((locks = malloc(sizeof(struct lock_s))) == NULL) {
			of_mutex_unlock(&mutex);
			SYNC_ERR("malloc(...)");
		}
	} else {
		struct lock_s *new_locks;

		if ((new_locks = realloc(locks, (numLocks + 1) *
		    sizeof(struct lock_s))) == NULL) {
			of_mutex_unlock(&mutex);
			SYNC_ERR("realloc(...)");
		}

		locks = new_locks;
	}

	locks[numLocks].object = object;
	locks[numLocks].count = 1;
	locks[numLocks].recursion = 0;
	locks[numLocks].thread = of_thread_current();

	if (!of_mutex_new(&locks[numLocks].mutex)) {
		of_mutex_unlock(&mutex);
		SYNC_ERR("of_mutex_new(&locks[numLocks].mutex");
	}

	if (!of_mutex_lock(&locks[numLocks].mutex)) {
		of_mutex_unlock(&mutex);
		SYNC_ERR("of_mutex_lock(&locks[numLocks].mutex");
	}

	numLocks++;

	if (!of_mutex_unlock(&mutex))
		SYNC_ERR("of_mutex_unlock(&mutex)");

	return 0;
}

int
objc_sync_exit(id object)
{
	ssize_t i;

	if (object == nil)
		return 0;

	if (!of_mutex_lock(&mutex))
		SYNC_ERR("of_mutex_lock(&mutex)");

	for (i = numLocks - 1; i >= 0; i--) {
		if (locks[i].object == object) {
			if (locks[i].recursion > 0 &&
			    of_thread_is_current(locks[i].thread)) {
				locks[i].recursion--;

				if (!of_mutex_unlock(&mutex))
					SYNC_ERR("of_mutex_unlock(&mutex)");

				return 0;
			}

			if (!of_mutex_unlock(&locks[i].mutex)) {
				of_mutex_unlock(&mutex);
				SYNC_ERR("of_mutex_unlock(&locks[i].mutex)");
			}

			locks[i].count--;

			if (locks[i].count == 0) {
				struct lock_s *new_locks = NULL;

				if (!of_mutex_free(&locks[i].mutex)) {
					of_mutex_unlock(&mutex);
					SYNC_ERR(
					    "of_mutex_free(&locks[i].mutex");
				}

				numLocks--;
				locks[i] = locks[numLocks];

				if (numLocks == 0) {
					free(locks);
					new_locks = NULL;
				} else if ((new_locks = realloc(locks,
				    numLocks * sizeof(struct lock_s))) ==
				    NULL) {
					of_mutex_unlock(&mutex);
					SYNC_ERR("realloc(...)");
				}

				locks = new_locks;
			}

			if (!of_mutex_unlock(&mutex))
				SYNC_ERR("of_mutex_unlock(&mutex)");

			return 0;
		}
	}

	of_mutex_unlock(&mutex);
	SYNC_ERR("objc_sync_exit()");
}
