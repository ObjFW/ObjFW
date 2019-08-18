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

#include "config.h"

#include <stdbool.h>

#import "once.h"

#ifdef OF_AMIGAOS
# include <proto/exec.h>
#endif

#if defined(OF_HAVE_THREADS) && defined(OF_HAVE_ATOMIC_OPS)
# import "atomic.h"
# import "mutex.h"
#endif

void
of_once(of_once_t *control, void (*func)(void))
{
#if !defined(OF_HAVE_THREADS)
	if (*control == 0) {
		func();
		*control = 1;
	}
#elif defined(OF_HAVE_PTHREADS)
	pthread_once(control, func);
#elif defined(OF_HAVE_ATOMIC_OPS)
	/* Avoid atomic operations in case it's already done. */
	if (*control == 2)
		return;

	if (of_atomic_int_cmpswap(control, 0, 1)) {
		func();

		of_memory_barrier();

		of_atomic_int_inc(control);
	} else
		while (*control == 1)
			of_thread_yield();
#elif defined(OF_AMIGAOS)
	bool run = false;

	/* Avoid Forbid() in case it's already done. */
	if (*control == 2)
		return;

	Forbid();

	switch (*control) {
	case 0:
		*control = 1;
		run = true;
		break;
	case 1:
		while (*control == 1) {
			Permit();
			Forbid();
		}
	}

	Permit();

	if (run) {
		func();
		*control = 2;
	}
#else
# error No of_once available
#endif
}
