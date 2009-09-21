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

#import "OFMacros.h"

#ifndef _WIN32
#include <pthread.h>
typedef pthread_t of_thread_t;
typedef pthread_mutex_t of_mutex_t;
typedef pthread_key_t of_tlskey_t;
#else
#include <windows.h>
typedef HANDLE of_thread_t;
typedef CRITICAL_SECTION of_mutex_t;
typedef DWORD of_tlskey_t;
#endif

#ifndef _WIN32
#define of_thread_is_current(t) pthread_equal(t, pthread_self())
#define of_thread_current() pthread_self()
#else
#define of_thread_is_current(t) (t == GetCurrentThread())
#define of_thread_current() GetCurrentThread()
#endif

static OF_INLINE BOOL
of_thread_new(of_thread_t *thread, id (*main)(id), id data)
{
#ifndef _WIN32
	return (pthread_create(thread, NULL, (void*(*)(void*))main,
	    (void*)data) ? NO : YES);
#else
	*thread = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)main,
	    (void*)data, 0, NULL);

	return (thread == NULL ? NO : YES);
#endif
}

static OF_INLINE BOOL
of_thread_join(of_thread_t thread)
{
#ifndef _WIN32
	void *ret;

	if (pthread_join(thread, &ret))
		return NO;

	/* FIXME: Do we need a way to differentiate? */
	return (ret != PTHREAD_CANCELED ? YES : NO);
#else
	if (WaitForSingleObject(thread, INFINITE))
		return NO;

	CloseHandle(thread);

	return YES;
#endif
}

static OF_INLINE BOOL
of_thread_cancel(of_thread_t thread)
{
#ifndef _WIN32
	return (pthread_cancel(thread) ? NO : YES);
#else
	if (thread != INVALID_HANDLE_VALUE) {
		TerminateThread(thread, 1);
		CloseHandle(thread);
	}

	return YES;
#endif
}

static OF_INLINE BOOL
of_mutex_new(of_mutex_t *mutex)
{
#ifndef _WIN32
	return (pthread_mutex_init(mutex, NULL) ? NO : YES);
#else
	InitializeCriticalSection(mutex);
	return YES;
#endif
}

static OF_INLINE BOOL
of_mutex_free(of_mutex_t *mutex)
{
#ifndef _WIN32
	return (pthread_mutex_destroy(mutex) ? NO : YES);
#else
	DeleteCriticalSection(mutex);
	return YES;
#endif
}

static OF_INLINE BOOL
of_mutex_lock(of_mutex_t *mutex)
{
#ifndef _WIN32
	return (pthread_mutex_lock(mutex) ? NO : YES);
#else
	EnterCriticalSection(mutex);
	return YES;
#endif
}

static OF_INLINE BOOL
of_mutex_unlock(of_mutex_t *mutex)
{
#ifndef _WIN32
	return (pthread_mutex_unlock(mutex) ? NO : YES);
#else
	LeaveCriticalSection(mutex);
	return YES;
#endif
}

static OF_INLINE BOOL
of_tlskey_new(of_tlskey_t *key, void (*destructor)(id))
{
#ifndef _WIN32
	return (pthread_key_create(key, (void(*)(void*))destructor) ? NO : YES);
#else
	/* FIXME: Call destructor */
	return ((*key = TlsAlloc()) == TLS_OUT_OF_INDEXES ? NO : YES);
#endif
}

static OF_INLINE id
of_tlskey_get(of_tlskey_t key)
{
#ifndef _WIN32
	void *ret = pthread_getspecific(key);
#else
	void *ret = TlsGetValue(key);
#endif

	/* NULL and nil might be different! */
	if (ret == NULL)
		return nil;

	return (id)ret;
}

static OF_INLINE BOOL
of_tlskey_set(of_tlskey_t key, id obj)
{
	void *p = (obj != nil ? (void*)obj : NULL);

#ifndef _WIN32
	return (pthread_setspecific(key, p) ? NO : YES);
#else
	return (TlsSetValue(key, p) ? YES : NO);
#endif
}
