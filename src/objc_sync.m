/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <stddef.h>
#include <stdlib.h>

#ifndef _WIN32
#include <pthread.h>
#endif

#import <objc/objc.h>

#ifdef _WIN32
#include <windows.h>
#endif

#import "OFMacros.h"

struct locks_s {
	id		obj;
	size_t		count;
	size_t		recursion;
#ifndef _WIN32
	pthread_t	thread;
	pthread_mutex_t	mutex;
#else
	HANDLE		thread;
	HANDLE		mutex;
#endif
};

#ifndef _WIN32
static pthread_mutex_t mutex;
#else
static HANDLE mutex;
#endif
static struct locks_s *locks = NULL;
static size_t num_locks = 0;

#ifndef _WIN32
static OF_INLINE BOOL
mutex_new(pthread_mutex_t *m)
{
	return (pthread_mutex_init(m, NULL) ? NO : YES);
}

static OF_INLINE BOOL
mutex_free(pthread_mutex_t *m)
{
	return (pthread_mutex_destroy(m) ? NO : YES);
}

static OF_INLINE BOOL
mutex_lock(pthread_mutex_t *m)
{
	return (pthread_mutex_lock(m) ? NO : YES);
}

static OF_INLINE BOOL
mutex_unlock(pthread_mutex_t *m)
{
	return (pthread_mutex_unlock(m) ? NO : YES);
}

static OF_INLINE BOOL
thread_is_current(pthread_t t)
{
	return (pthread_equal(t, pthread_self()) ? YES : NO);
}

static OF_INLINE pthread_t
thread_current()
{
	return pthread_self();
}
#else
static OF_INLINE BOOL
mutex_new(HANDLE *m)
{
	return (((*m = CreateMutex(NULL, FALSE, NULL)) != NULL) ? YES : NO);
}

static OF_INLINE BOOL
mutex_free(HANDLE *m)
{
	return (CloseHandle(*m) ? YES : NO);
}

static OF_INLINE BOOL
mutex_lock(HANDLE *m)
{
	return (WaitForSingleObject(*m, INFINITE) == WAIT_OBJECT_0 ? YES : NO);
}

static OF_INLINE BOOL
mutex_unlock(HANDLE *m)
{
	return (ReleaseMutex(*m) ? YES : NO);
}

static OF_INLINE BOOL
thread_is_current(HANDLE t)
{
	return (t == GetCurrentThread() ? YES : NO);
}

static OF_INLINE HANDLE
thread_current()
{
	return GetCurrentThread();
}
#endif

BOOL
objc_sync_init()
{
	return (mutex_new(&mutex) ? YES : NO);
}

int
objc_sync_enter(id obj)
{
	size_t i;

	if (obj == nil)
		return 0;

	if (!mutex_lock(&mutex))
		return 1;

	for (i = 0; i < num_locks; i++) {
		if (locks[i].obj == obj) {
			if (thread_is_current(locks[i].thread))
				locks[i].recursion++;
			else
				if (!mutex_lock(&locks[i].mutex)) {
					mutex_unlock(&mutex);
					return 1;
				}

			locks[i].count++;

			if (!mutex_unlock(&mutex))
				return 1;

			return 0;
		}
	}

	if (locks == NULL) {
		if ((locks = malloc(sizeof(struct locks_s))) == NULL) {
			mutex_unlock(&mutex);
			return 1;
		}
	} else {
		struct locks_s *new_locks;

		if ((new_locks = realloc(locks, (num_locks + 1) *
		    sizeof(struct locks_s))) == NULL) {
			mutex_unlock(&mutex);
			return 1;
		}

		locks = new_locks;
	}

	locks[num_locks].obj = obj;
	locks[num_locks].count = 1;
	locks[num_locks].recursion = 0;
	locks[num_locks].thread = thread_current();

	if (!mutex_new(&locks[num_locks].mutex)) {
		mutex_unlock(&mutex);
		return 1;
	}

	if (!mutex_lock(&locks[num_locks].mutex)) {
		mutex_unlock(&mutex);
		return 1;
	}

	num_locks++;

	if (!mutex_unlock(&mutex))
		return 1;

	return 0;
}

int
objc_sync_exit(id obj)
{
	size_t i;

	if (obj == nil)
		return 0;

	if (!mutex_lock(&mutex))
		return 1;

	for (i = 0; i < num_locks; i++) {
		if (locks[i].obj == obj) {
			if (locks[i].recursion > 0 &&
			    thread_is_current(locks[i].thread)) {
				locks[i].recursion--;

				if (!mutex_unlock(&mutex))
					return 1;

				return 0;
			}

			if (!mutex_unlock(&locks[i].mutex)) {
				mutex_unlock(&mutex);
				return 1;
			}

			locks[i].count--;

			if (locks[i].count == 0) {
				struct locks_s *new_locks;

				if (!mutex_free(&locks[i].mutex)) {
					mutex_unlock(&mutex);
					return 1;
				}

				num_locks--;
				locks[i] = locks[num_locks];

				if ((new_locks = realloc(locks, (num_locks) *
				    sizeof(struct locks_s))) == NULL) {
					mutex_unlock(&mutex);
					return 1;
				}

				locks = new_locks;
			}

			if (!mutex_unlock(&mutex))
				return 1;

			return 0;
		}
	}

	mutex_unlock(&mutex);
	return 1;
}
