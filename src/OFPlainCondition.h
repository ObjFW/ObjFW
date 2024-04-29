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
# error No conditions available!
#endif

/* For OFTimeInterval */
#import "OFObject.h"
#import "OFPlainMutex.h"

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
extern int OFPlainConditionNew(OFPlainCondition *condition);
extern int OFPlainConditionSignal(OFPlainCondition *condition);
extern int OFPlainConditionBroadcast(OFPlainCondition *condition);
extern int OFPlainConditionWait(OFPlainCondition *condition,
    OFPlainMutex *mutex);
extern int OFPlainConditionTimedWait(OFPlainCondition *condition,
    OFPlainMutex *mutex, OFTimeInterval timeout);
#if defined(OF_AMIGAOS) || defined(DOXYGEN)
extern int OFPlainConditionWaitOrExecSignal(OFPlainCondition *condition,
    OFPlainMutex *mutex, ULONG *signalMask);
extern int OFPlainConditionTimedWaitOrExecSignal(OFPlainCondition *condition,
    OFPlainMutex *mutex, OFTimeInterval timeout, ULONG *signalMask);
#endif
extern int OFPlainConditionFree(OFPlainCondition *condition);
#ifdef __cplusplus
}
#endif
