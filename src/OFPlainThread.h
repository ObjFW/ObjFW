/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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
    (!defined(OF_HAVE_PTHREADS) && !defined(OF_WINDOWS) && !defined(OF_AMIGAOS))
# error No threads available!
#endif

#import "macros.h"

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

static OF_INLINE bool
OFPlainThreadIsCurrent(OFPlainThread thread)
{
	return (thread->thread == FindTask(NULL));
}
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
