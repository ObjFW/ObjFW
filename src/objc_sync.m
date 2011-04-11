/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#ifdef OF_OBJFW_RUNTIME
# import <objfw-rt.h>
#else
# import <objc/objc.h>
#endif

#import "threading.h"

struct locks_s {
	id		 obj;
	size_t		 count;
	size_t		 recursion;
	of_thread_t	 thread;
	of_mutex_t	 mutex;
};

static of_mutex_t mutex;
static struct locks_s *locks = NULL;
static ssize_t num_locks = 0;

#define SYNC_ERR(f)							\
	{								\
		fprintf(stderr, "WARNING: %s failed in line %d!\n"	\
		    "WARNING: This might result in a race "		\
		    "condition!\n", f, __LINE__);			\
		return 1;						\
	}

BOOL
objc_sync_init()
{
	return of_mutex_new(&mutex);
}

int
objc_sync_enter(id obj)
{
	ssize_t i;

	if (obj == nil)
		return 0;

	if (!of_mutex_lock(&mutex))
		SYNC_ERR("of_mutex_lock(&mutex)");

	for (i = num_locks - 1; i >= 0; i--) {
		if (locks[i].obj == obj) {
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
		if ((locks = malloc(sizeof(struct locks_s))) == NULL) {
			of_mutex_unlock(&mutex);
			SYNC_ERR("malloc(...)");
		}
	} else {
		struct locks_s *new_locks;

		if ((new_locks = realloc(locks, (num_locks + 1) *
		    sizeof(struct locks_s))) == NULL) {
			of_mutex_unlock(&mutex);
			SYNC_ERR("realloc(...)");
		}

		locks = new_locks;
	}

	locks[num_locks].obj = obj;
	locks[num_locks].count = 1;
	locks[num_locks].recursion = 0;
	locks[num_locks].thread = of_thread_current();

	if (!of_mutex_new(&locks[num_locks].mutex)) {
		of_mutex_unlock(&mutex);
		SYNC_ERR("of_mutex_new(&locks[num_locks].mutex");
	}

	if (!of_mutex_lock(&locks[num_locks].mutex)) {
		of_mutex_unlock(&mutex);
		SYNC_ERR("of_mutex_lock(&locks[num_locks].mutex");
	}

	num_locks++;

	if (!of_mutex_unlock(&mutex))
		SYNC_ERR("of_mutex_unlock(&mutex)");

	return 0;
}

int
objc_sync_exit(id obj)
{
	ssize_t i;

	if (obj == nil)
		return 0;

	if (!of_mutex_lock(&mutex))
		SYNC_ERR("of_mutex_lock(&mutex)");

	for (i = num_locks - 1; i >= 0; i--) {
		if (locks[i].obj == obj) {
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
				struct locks_s *new_locks = NULL;

				if (!of_mutex_free(&locks[i].mutex)) {
					of_mutex_unlock(&mutex);
					SYNC_ERR(
					    "of_mutex_free(&locks[i].mutex");
				}

				num_locks--;
				locks[i] = locks[num_locks];

				if (num_locks == 0) {
					free(locks);
					new_locks = NULL;
				} else if ((new_locks = realloc(locks,
				    num_locks * sizeof(struct locks_s))) ==
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
