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
#else
#include <windows.h>
#endif

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

static int initialized = 0;
#ifndef _WIN32
static pthread_mutex_t mutex;
#else
static HANDLE mutex;
#endif
static struct locks_s *locks = NULL;
static size_t num_locks = 0;

int
objc_sync_enter(id obj)
{
	size_t i;

	/*
	 * FIXME:
	 * Theoretically, it's possible to encounter a race condition during
	 * initialization.
	 */
	if (!initialized) {
#ifndef _WIN32
		if (pthread_mutex_init(&mutex, NULL))
#else
		if ((mutex = CreateMutex(NULL, FALSE, NULL)) == NULL)
#endif
			return 1;

		initialized = 1;
	}

#ifndef _WIN32
	if (pthread_mutex_lock(&mutex))
#else
	if (WaitForSingleObject(mutex, INFINITE) != WAIT_OBJECT_0)
		return 1;
#endif

	for (i = 0; i < num_locks; i++) {
		if (locks[i].obj == obj) {
#ifndef _WIN32
			if (pthread_equal(pthread_self(), locks[i].thread))
#else
			if (locks[i].thread == GetCurrentThread())
#endif
				locks[i].recursion++;
			else
#ifndef _WIN32
				if (pthread_mutex_lock(&locks[i].mutex)) {
					pthread_mutex_unlock(&mutex);
					return 1;
				}
#else
				if (WaitForSingleObject(locks[i].mutex,
				    INFINITE) != WAIT_OBJECT_0) {
					ReleaseMutex(mutex);
					return 1;
				}
#endif

			locks[i].count++;

#ifndef _WIN32
			if (pthread_mutex_unlock(&locks[i].mutex))
#else
			if (!ReleaseMutex(mutex))
#endif
				return 1;

			return 0;
		}
	}

	if (locks == NULL) {
		if ((locks = malloc(sizeof(struct locks_s))) == NULL) {
#ifndef _WIN32
			pthread_mutex_unlock(&mutex);
#else
			ReleaseMutex(mutex);
#endif
			return 1;
		}
	} else {
		struct locks_s *new_locks;

		if ((new_locks = realloc(locks, (num_locks + 1) *
		    sizeof(struct locks_s))) == NULL) {
#ifndef _WIN32
			pthread_mutex_unlock(&mutex);
#else
			ReleaseMutex(mutex);
#endif
			return 1;
		}

		locks = new_locks;
	}

	locks[num_locks].obj = obj;
	locks[num_locks].count = 1;
	locks[num_locks].recursion = 0;

#ifndef _WIN32
	locks[num_locks].thread = pthread_self();

	if (pthread_mutex_init(&locks[num_locks].mutex, NULL)) {
		pthread_mutex_unlock(&mutex);
		return 1;
	}

	if (pthread_mutex_lock(&locks[num_locks].mutex)) {
		pthread_mutex_unlock(&mutex);
		return 1;
	}
#else
	locks[num_locks].thread = GetCurrentThread();

	if ((locks[num_locks].mutex = CreateMutex(NULL, TRUE, NULL)) == NULL) {
		ReleaseMutex(mutex);
		return 1;
	}
#endif

	num_locks++;

#ifndef _WIN32
	if (pthread_mutex_unlock(&mutex))
#else
	if (!ReleaseMutex(mutex))
#endif
		return 1;

	return 0;
}

int
objc_sync_exit(id obj)
{
	size_t i;

#ifndef _WIN32
	if (pthread_mutex_lock(&mutex))
#else
	if (WaitForSingleObject(mutex, INFINITE) != WAIT_OBJECT_0)
		return 1;
#endif

	for (i = 0; i < num_locks; i++) {
		if (locks[i].obj == obj) {
#ifndef _WIN32
			if (pthread_equal(pthread_self(), locks[i].thread) &&
			    locks[i].recursion) {
				locks[i].recursion--;

				if (pthread_mutex_unlock(&mutex))
					return 1;

				return 0;
			}
#else
			if (locks[i].thread == GetCurrentThread() &&
			    locks[i].recursion) {
				locks[i].recursion--;

				if (!ReleaseMutex(mutex))
					return 1;

				return 0;
			}
#endif

#ifndef _WIN32
			if (pthread_mutex_unlock(&locks[i].mutex)) {
				pthread_mutex_unlock(&mutex);
				return 1;
			}
#else
			if (!ReleaseMutex(locks[i].mutex)) {
				ReleaseMutex(mutex);
				return 1;
			}
#endif

			locks[i].count--;

			if (locks[i].count == 0) {
				struct locks_s *new_locks;

#ifndef _WIN32
				if (pthread_mutex_destroy(&locks[i].mutex)) {
					pthread_mutex_unlock(&mutex);
					return 1;
				}
#else
				if (!CloseHandle(locks[i].mutex)) {
					ReleaseMutex(mutex);
					return 1;
				}
#endif

				num_locks--;
				locks[i] = locks[num_locks];

				if ((new_locks = realloc(locks, (num_locks) *
				    sizeof(struct locks_s))) == NULL) {
#ifndef _WIN32
					pthread_mutex_unlock(&mutex);
#else
					ReleaseMutex(mutex);
#endif
					return 1;
				}

				locks = new_locks;
			}

#ifndef _WIN32
			if (pthread_mutex_unlock(&mutex))
#else
			if (!ReleaseMutex(mutex))
#endif
				return 1;

			return 0;
		}
	}

#ifndef _WIN32
	pthread_mutex_unlock(&mutex);
#else
	ReleaseMutex(mutex);
#endif

	return 1;
}
