/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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
	struct OFPlainConditionWaitingTask {
		struct Task *task;
		unsigned char sigBit;
		struct OFPlainConditionWaitingTask *next;
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
#ifdef OF_AMIGAOS
extern int OFPlainConditionWaitOrExecSignal(OFPlainCondition *condition,
    OFPlainMutex *mutex, ULONG *signalMask);
extern int OFPlainConditionTimedWaitOrExecSignal(OFPlainCondition *condition,
    OFPlainMutex *mutex, OFTimeInterval timeout, ULONG *signalMask);
#endif
extern int OFPlainConditionFree(OFPlainCondition *condition);
#ifdef __cplusplus
}
#endif
