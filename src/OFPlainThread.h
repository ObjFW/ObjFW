/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#include "objfw-defs.h"

#include "platform.h"

#if !defined(OF_HAVE_THREADS) || \
    (!defined(OF_HAVE_PTHREADS) && !defined(OF_WINDOWS) && !defined(OF_AMIGAOS))
# error No threads available!
#endif

#import "OFObject.h"

#if defined(OF_HAVE_PTHREADS)
# include <pthread.h>
typedef pthread_t OFPlainThread;
#elif defined(OF_WINDOWS)
# include <windows.h>
typedef HANDLE OFPlainThread;
#elif defined(OF_AMIGAOS)
# include <exec/tasks.h>
# include <exec/semaphores.h>
typedef struct {
	struct Task *task;
	void (*function)(id);
	id object;
	struct SignalSemaphore semaphore;
	struct Task *joinTask;
	unsigned char joinSigBit;
	bool detached, done;
} *OFPlainThread;
#endif

typedef struct {
	float priority;
	size_t stackSize;
} OFPlainThreadAttributes;

#if defined(OF_HAVE_PTHREADS)
static OF_INLINE OFPlainThread
OFCurrentPlainThread(void)
{
	return pthread_self();
}

static OF_INLINE bool
OFPlainThreadIsCurrent(OFPlainThread thread)
{
	return pthread_equal(thread, pthread_self());
}
#elif defined(OF_WINDOWS)
static OF_INLINE OFPlainThread
OFCurrentPlainThread(void)
{
	return GetCurrentThread();
}

static OF_INLINE bool
OFPlainThreadIsCurrent(OFPlainThread thread)
{
	return (thread == GetCurrentThread());
}
#elif defined(OF_AMIGAOS)
extern OFPlainThread OFCurrentPlainThread(void);
extern bool OFPlainThreadIsCurrent(OFPlainThread);
#endif

#ifdef __cplusplus
extern "C" {
#endif
extern int OFPlainThreadAttributesInit(OFPlainThreadAttributes *attr);
extern int OFPlainThreadNew(OFPlainThread *thread, const char *name,
    void (*function)(id), id object, const OFPlainThreadAttributes *attr);
extern void OFSetThreadName(const char *name);
extern int OFPlainThreadJoin(OFPlainThread thread);
extern int OFPlainThreadDetach(OFPlainThread thread);
#ifdef __cplusplus
}
#endif
