/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#include <stdbool.h>

#import "OFOnce.h"
#if defined(OF_HAVE_THREADS) && defined(OF_HAVE_ATOMIC_OPS)
# import "OFAtomic.h"
# import "OFPlainMutex.h"
#endif

#ifdef OF_AMIGAOS
# define Class IntuitionClass
# include <proto/exec.h>
# undef Class
#endif

void
OFOnce(OFOnceControl *control, void (*function)(void))
{
#if !defined(OF_HAVE_THREADS)
	if (*control == 0) {
		function();
		*control = 1;
	}
#elif defined(OF_HAVE_PTHREADS)
	pthread_once(control, function);
#elif defined(OF_HAVE_ATOMIC_OPS)
	/* Avoid atomic operations in case it's already done. */
	if (*control == 2)
		return;

	if (OFAtomicIntCompareAndSwap(control, 0, 1)) {
		OFAcquireMemoryBarrier();

		function();
		OFAtomicIntIncrease(control);

		OFReleaseMemoryBarrier();
	} else
		while (*control == 1)
			OFYieldThread();
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
		function();
		*control = 2;
	}
#else
# error No OFOnce available
#endif
}
