/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

/** @file */

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

#if defined(OF_HAVE_PTHREADS) || defined(DOXYGEN)
/**
 * @brief Returns the current plain thread.
 *
 * @return The current plain thread
 */
static OF_INLINE OFPlainThread
OFCurrentPlainThread(void)
{
	return pthread_self();
}

/**
 * @brief Returns whether the specified plain thread is the current thread.
 *
 * @param thread The thread to check
 * @return Whether the specified plain thread is the current thread
 */
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
/**
 * @brief Initializes the specified thread attributes.
 *
 * @param attr A pointer to the thread attributes to initialize
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
extern int OFPlainThreadAttributesInit(OFPlainThreadAttributes *attr);

/**
 * @brief Creates a new plain thread.
 *
 * A plain thread is similar to @ref OFThread, but does not use exceptions and
 * is just a lightweight wrapper around the system's thread implementation.
 *
 * @param thread A pointer to the thread to create
 * @param name A name for the thread
 * @param function The function the thread should execute
 * @param object The object to pass to the thread as an argument
 * @param attr Thread attributes
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
extern int OFPlainThreadNew(OFPlainThread *thread, const char *name,
    void (*function)(id), id object, const OFPlainThreadAttributes *attr);

/**
 * @brief Sets the name of the current thread.
 *
 * @param name The name for the current thread
 */
extern void OFSetThreadName(const char *name);

/**
 * @brief Joins the specified thread.
 *
 * @param thread The thread to join
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
extern int OFPlainThreadJoin(OFPlainThread thread);

/**
 * @brief Detaches the specified thread.
 *
 * @param thread The thread to detach
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
extern int OFPlainThreadDetach(OFPlainThread thread);
#ifdef __cplusplus
}
#endif
