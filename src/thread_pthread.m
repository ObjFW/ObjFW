/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#ifdef HAVE_PTHREAD_NP_H
# include <pthread_np.h>
#endif

#ifdef OF_HAIKU
# include <kernel/OS.h>
#endif

#import "macros.h"

static int minPrio = 0, maxPrio = 0, normalPrio = 0;

struct thread_ctx {
	void (*function)(id object);
	id object;
};

/*
 * This is done here to make sure this is done as early as possible in the main
 * thread.
 */
OF_CONSTRUCTOR()
{
	pthread_attr_t pattr;

	if (pthread_attr_init(&pattr) == 0) {
#ifdef HAVE_PTHREAD_ATTR_GETSCHEDPOLICY
		int policy;
#endif
		struct sched_param param;

#ifdef HAVE_PTHREAD_ATTR_GETSCHEDPOLICY
		if (pthread_attr_getschedpolicy(&pattr, &policy) == 0) {
			minPrio = sched_get_priority_min(policy);
			maxPrio = sched_get_priority_max(policy);

			if (minPrio == -1 || maxPrio == -1)
				minPrio = maxPrio = 0;
		}

		if (pthread_attr_getschedparam(&pattr, &param) != 0)
			normalPrio = param.sched_priority;
		else
			minPrio = maxPrio = 0;

		pthread_attr_destroy(&pattr);
#endif
	}
}

static void *
functionWrapper(void *data)
{
	struct thread_ctx *ctx = data;

	pthread_cleanup_push(free, data);

	ctx->function(ctx->object);

	pthread_cleanup_pop(1);
	return NULL;
}

bool
of_thread_attr_init(of_thread_attr_t *attr)
{
	pthread_attr_t pattr;

	if (pthread_attr_init(&pattr) != 0)
		return false;

	@try {
		attr->priority = 0;

		if (pthread_attr_getstacksize(&pattr, &attr->stackSize) != 0)
			return false;
	} @finally {
		pthread_attr_destroy(&pattr);
	}

	return true;
}

bool
of_thread_new(of_thread_t *thread, void (*function)(id), id object,
    const of_thread_attr_t *attr)
{
	bool ret;
	pthread_attr_t pattr;

	if (pthread_attr_init(&pattr) != 0)
		return false;

	@try {
		struct thread_ctx *ctx;

		if (attr != NULL) {
			struct sched_param param;

			if (attr->priority < -1 || attr->priority > 1)
				return false;

#ifdef HAVE_PTHREAD_ATTR_SETINHERITSCHED
			if (pthread_attr_setinheritsched(&pattr,
			    PTHREAD_EXPLICIT_SCHED) != 0)
				return false;
#endif

			if (attr->priority < 0) {
				param.sched_priority = minPrio +
				    (1.0f + attr->priority) *
				    (normalPrio - minPrio);
			} else
				param.sched_priority = normalPrio +
				    attr->priority * (maxPrio - normalPrio);

			if (pthread_attr_setschedparam(&pattr, &param) != 0)
				return false;

			if (attr->stackSize > 0) {
				if (pthread_attr_setstacksize(&pattr,
				    attr->stackSize) != 0)
					return false;
			}
		}

		if ((ctx = malloc(sizeof(*ctx))) == NULL)
			return false;

		ctx->function = function;
		ctx->object = object;

		ret = (pthread_create(thread, &pattr,
		    functionWrapper, ctx) == 0);
	} @finally {
		pthread_attr_destroy(&pattr);
	}

	return ret;
}

bool
of_thread_join(of_thread_t thread)
{
	void *ret;

	if (pthread_join(thread, &ret) != 0)
		return false;

#ifdef PTHREAD_CANCELED
	return (ret != PTHREAD_CANCELED);
#else
	return true;
#endif
}

bool
of_thread_detach(of_thread_t thread)
{
	return (pthread_detach(thread) == 0);
}

void
of_thread_set_name(const char *name)
{
#if defined(OF_HAIKU)
	rename_thread(find_thread(NULL), name);
#elif defined(HAVE_PTHREAD_SET_NAME_NP)
	pthread_set_name_np(pthread_self(), name);
#elif defined(HAVE_PTHREAD_SETNAME_NP)
# if defined(OF_MACOS) || defined(OF_IOS)
	pthread_setname_np(name);
# elif defined(__GLIBC__)
	char buffer[16];

	strncpy(buffer, name, 15);
	buffer[15] = 0;

	pthread_setname_np(pthread_self(), buffer);
# endif
#endif
}
