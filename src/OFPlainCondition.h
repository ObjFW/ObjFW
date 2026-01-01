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
# error No conditions available!
#endif

/* For OFTimeInterval */
#import "OFObject.h"
#import "OFPlainMutex.h"

/** @file */

#if defined(OF_HAVE_PTHREADS)
# include <pthread.h>
typedef pthread_cond_t OFPlainCondition;
#elif defined(OF_WINDOWS)
# include <windows.h>
typedef struct {
	HANDLE event;
	volatile int count;
} OFPlainCondition;
#elif defined(OF_AMIGAOS)
# include <exec/tasks.h>
typedef struct {
	struct _OFPlainConditionWaitingTask {
		struct Task *task;
		unsigned char sigBit;
		struct _OFPlainConditionWaitingTask *next;
	} *waitingTasks;
} OFPlainCondition;
#endif

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief Creates a new plain condition.
 *
 * A plain condition is similar to an @ref OFCondition, but does not use
 * exceptions and can be used from pure C code.
 *
 * @param condition A pointer to the condition to create
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
extern int OFPlainConditionNew(OFPlainCondition *condition);

/**
 * @brief Signals the specified condition.
 *
 * @param condition A pointer to the condition to signal
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
extern int OFPlainConditionSignal(OFPlainCondition *condition);

/**
 * @brief Broadcasts the specified condition, meaning it will be signaled to
 *	  everyone waiting.
 *
 * @param condition A pointer to the condition to broadcast
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
extern int OFPlainConditionBroadcast(OFPlainCondition *condition);

/**
 * @brief Waits on the specified condition with the specified mutex.
 *
 * @param condition A pointer to the condition to wait on
 * @param mutex The mutex to wait with
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
extern int OFPlainConditionWait(OFPlainCondition *condition,
    OFPlainMutex *mutex);

/**
 * @brief Waits on the specified condition with the specified mutex with a
 *	  timeout.
 *
 * @param condition A pointer to the condition to wait on
 * @param mutex The mutex to wait with
 * @param timeout The timeout after which to give up
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
extern int OFPlainConditionTimedWait(OFPlainCondition *condition,
    OFPlainMutex *mutex, OFTimeInterval timeout);

#if defined(OF_AMIGAOS) || defined(DOXYGEN)
/**
 * @brief Waits on the specified condition with the specified mutex or the
 *	  specified Exec signal.
 *
 * @param condition A pointer to the condition to wait on
 * @param mutex The mutex to wait with
 * @param signalMask The Exec signal mask to wait for
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
extern int OFPlainConditionWaitOrExecSignal(OFPlainCondition *condition,
    OFPlainMutex *mutex, ULONG *signalMask);

/**
 * @brief Waits on the specified condition with the specified mutex or the
 *	  specified Exec signal, up until the timeout is reached.
 *
 * @param condition A pointer to the condition to wait on
 * @param mutex The mutex to wait with
 * @param signalMask The Exec signal mask to wait for
 * @param timeout The timeout after which to give up
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
extern int OFPlainConditionTimedWaitOrExecSignal(OFPlainCondition *condition,
    OFPlainMutex *mutex, OFTimeInterval timeout, ULONG *signalMask);
#endif

/**
 * @brief Destroys the specified plain condition.
 *
 * @param condition A pointer to the condition to destroy
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
extern int OFPlainConditionFree(OFPlainCondition *condition);
#ifdef __cplusplus
}
#endif
