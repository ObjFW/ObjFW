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

#include "objfw-defs.h"

#include "platform.h"

#if !defined(OF_HAVE_THREADS) || \
    (!defined(OF_HAVE_PTHREADS) && !defined(OF_WINDOWS))
# error No threads available!
#endif

#import "macros.h"

#if defined(OF_HAVE_PTHREADS)
# include <pthread.h>
typedef pthread_t of_thread_t;
#elif defined(OF_WINDOWS)
# include <windows.h>
typedef HANDLE of_thread_t;
#endif

typedef struct of_thread_attr_t {
	float priority;
	size_t stackSize;
} of_thread_attr_t;

#if defined(OF_HAVE_PTHREADS)
# define of_thread_is_current(t) pthread_equal(t, pthread_self())
# define of_thread_current pthread_self
#elif defined(OF_WINDOWS)
# define of_thread_is_current(t) (t == GetCurrentThread())
# define of_thread_current GetCurrentThread
#endif

#ifdef __cplusplus
extern "C" {
#endif
extern bool of_thread_attr_init(of_thread_attr_t *attr);
extern bool of_thread_new(of_thread_t *thread, void (*function)(id), id object,
    const of_thread_attr_t *attr);
extern void of_thread_set_name(const char *name);
extern bool of_thread_join(of_thread_t thread);
extern bool of_thread_detach(of_thread_t thread);
#ifdef __cplusplus
}
#endif
