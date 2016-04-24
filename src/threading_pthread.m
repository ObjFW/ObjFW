/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

#ifdef HAVE_PTHREAD_NP_H
# include <pthread_np.h>
#endif

#import "macros.h"

#ifdef OF_HAIKU
# include <kernel/OS.h>
#endif

static int minPrio, maxPrio, normalPrio;

struct thread_ctx {
	void (*function)(id object);
	id object;
};

/*
 * This is done here to make sure this is done as early as possible in the main
 * thread.
 */
static void __attribute__((constructor))
init(void)
{
	pthread_attr_t pattr;
	int policy;
	struct sched_param param;

	OF_ENSURE(pthread_attr_init(&pattr) == 0);
	OF_ENSURE(pthread_attr_getschedpolicy(&pattr, &policy) == 0);
	OF_ENSURE((minPrio = sched_get_priority_min(policy)) != -1);
	OF_ENSURE((maxPrio = sched_get_priority_max(policy)) != -1);
	OF_ENSURE(pthread_attr_getschedparam(&pattr, &param) == 0);

	normalPrio = param.sched_priority;

	pthread_attr_destroy(&pattr);
}

static void*
function_wrapper(void *data)
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
				    (1.0 + attr->priority) *
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
		    function_wrapper, ctx) == 0);
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

void OF_NO_RETURN_FUNC
of_thread_exit(void)
{
	pthread_exit(NULL);

	OF_UNREACHABLE
}

void
of_thread_set_name(of_thread_t thread, const char *name)
{
#if defined(OF_HAIKU)
	rename_thread(get_pthread_thread_id(thread), name);
#elif defined(HAVE_PTHREAD_SET_NAME_NP)
	pthread_set_name_np(pthread_self(), name);
#elif defined(HAVE_PTHREAD_SETNAME_NP)
# if defined(OF_MAC_OS_X) || defined(OF_IOS)
	pthread_setname_np(name);
# elif defined(__GLIBC__)
	char buffer[16];

	strncpy(buffer, name, 15);
	buffer[15] = 0;

	pthread_setname_np(pthread_self(), buffer);
# endif
#endif
}

void
of_once(of_once_t *control, void (*func)(void))
{
	pthread_once(control, func);
}

bool
of_tlskey_new(of_tlskey_t *key)
{
	return (pthread_key_create(key, NULL) == 0);
}

bool
of_tlskey_free(of_tlskey_t key)
{
	return (pthread_key_delete(key) == 0);
}

bool
of_mutex_new(of_mutex_t *mutex)
{
	return (pthread_mutex_init(mutex, NULL) == 0);
}

bool
of_mutex_lock(of_mutex_t *mutex)
{
	return (pthread_mutex_lock(mutex) == 0);
}

bool
of_mutex_trylock(of_mutex_t *mutex)
{
	return (pthread_mutex_trylock(mutex) == 0);
}

bool
of_mutex_unlock(of_mutex_t *mutex)
{
	return (pthread_mutex_unlock(mutex) == 0);
}

bool
of_mutex_free(of_mutex_t *mutex)
{
	return (pthread_mutex_destroy(mutex) == 0);
}

#ifdef OF_HAVE_RECURSIVE_PTHREAD_MUTEXES
bool
of_rmutex_new(of_rmutex_t *rmutex)
{
	pthread_mutexattr_t attr;

	if (pthread_mutexattr_init(&attr) != 0)
		return false;

	if (pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE) != 0)
		return false;

	if (pthread_mutex_init(rmutex, &attr) != 0)
		return false;

	if (pthread_mutexattr_destroy(&attr) != 0)
		return false;

	return true;
}

bool
of_rmutex_lock(of_rmutex_t *rmutex)
{
	return of_mutex_lock(rmutex);
}

bool
of_rmutex_trylock(of_rmutex_t *rmutex)
{
	return of_mutex_trylock(rmutex);
}

bool
of_rmutex_unlock(of_rmutex_t *rmutex)
{
	return of_mutex_unlock(rmutex);
}

bool
of_rmutex_free(of_rmutex_t *rmutex)
{
	return of_mutex_free(rmutex);
}
#endif

bool
of_condition_new(of_condition_t *condition)
{
	return (pthread_cond_init(condition, NULL) == 0);
}

bool
of_condition_signal(of_condition_t *condition)
{
	return (pthread_cond_signal(condition) == 0);
}

bool
of_condition_broadcast(of_condition_t *condition)
{
	return (pthread_cond_broadcast(condition) == 0);
}

bool
of_condition_wait(of_condition_t *condition, of_mutex_t *mutex)
{
	return (pthread_cond_wait(condition, mutex) == 0);
}

bool
of_condition_timed_wait(of_condition_t *condition, of_mutex_t *mutex,
    of_time_interval_t timeout)
{
	struct timespec ts;

	ts.tv_sec = (time_t)timeout;
	ts.tv_nsec = lrint((timeout - ts.tv_sec) * 1000000000);

	return (pthread_cond_timedwait(condition, mutex, &ts) == 0);
}

bool
of_condition_free(of_condition_t *condition)
{
	return (pthread_cond_destroy(condition) == 0);
}
