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

#if defined(OF_HAVE_PTHREADS)
# include <pthread.h>
typedef pthread_once_t of_once_t;
# define OF_ONCE_INIT PTHREAD_ONCE_INIT
#elif defined(OF_HAVE_ATOMIC_OPS)
typedef volatile int of_once_t;
# define OF_ONCE_INIT 0
#elif defined(OF_AMIGAOS) || !defined(OF_HAVE_THREADS)
typedef int of_once_t;
# define OF_ONCE_INIT 0
#endif

#ifdef __cplusplus
extern "C" {
#endif
extern void of_once(of_once_t *control, void (*func)(void));
#ifdef __cplusplus
}
#endif
