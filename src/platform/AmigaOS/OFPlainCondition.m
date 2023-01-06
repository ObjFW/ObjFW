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

#include "config.h"

#include <errno.h>

#import "OFPlainCondition.h"

#include <proto/exec.h>
#include <devices/timer.h>
#ifndef OF_AMIGAOS4
# include <clib/alib_protos.h>
#endif

int
OFPlainConditionNew(OFPlainCondition *condition)
{
	condition->waitingTasks = NULL;

	return 0;
}

int
OFPlainConditionSignal(OFPlainCondition *condition)
{
	Forbid();
	@try {
		if (condition->waitingTasks == NULL)
			return 0;

		Signal(condition->waitingTasks->task,
		    (1ul << condition->waitingTasks->sigBit));

		condition->waitingTasks = condition->waitingTasks->next;
	} @finally {
		Permit();
	}

	return 0;
}

int
OFPlainConditionBroadcast(OFPlainCondition *condition)
{
	Forbid();
	@try {
		if (condition->waitingTasks == NULL)
			return 0;

		while (condition->waitingTasks != NULL) {
			Signal(condition->waitingTasks->task,
			    (1ul << condition->waitingTasks->sigBit));

			condition->waitingTasks = condition->waitingTasks->next;
		}
	} @finally {
		Permit();
	}

	return 0;
}

int
OFPlainConditionWait(OFPlainCondition *condition, OFPlainMutex *mutex)
{
	ULONG signalMask = 0;

	return OFPlainConditionWaitOrExecSignal(condition, mutex, &signalMask);
}

int
OFPlainConditionWaitOrExecSignal(OFPlainCondition *condition,
    OFPlainMutex *mutex, ULONG *signalMask)
{
	struct OFPlainConditionWaitingTask waitingTask = {
		.task = FindTask(NULL),
		.sigBit = AllocSignal(-1)
	};
	int error = 0;
	ULONG mask;

	if (waitingTask.sigBit == -1)
		return EAGAIN;

	Forbid();

	if ((error = OFPlainMutexUnlock(mutex)) != 0) {
		FreeSignal(waitingTask.sigBit);
		return error;
	}

	waitingTask.next = condition->waitingTasks;
	condition->waitingTasks = &waitingTask;

	mask = Wait((1ul << waitingTask.sigBit) | *signalMask);
	if (mask & (1ul << waitingTask.sigBit) || (*signalMask &= mask))
		error = OFPlainMutexLock(mutex);
	else
		/*
		 * This should not happen - it means something interrupted the
		 * Wait(), so the best we can do is return EINTR.
		 */
		error = EINTR;

	FreeSignal(waitingTask.sigBit);

	Permit();

	return error;
}

int
OFPlainConditionTimedWait(OFPlainCondition *condition, OFPlainMutex *mutex,
    OFTimeInterval timeout)
{
	ULONG signalMask = 0;

	return OFPlainConditionTimedWaitOrExecSignal(condition, mutex, timeout,
	    &signalMask);
}

int
OFPlainConditionTimedWaitOrExecSignal(OFPlainCondition *condition,
    OFPlainMutex *mutex, OFTimeInterval timeout, ULONG *signalMask)
{
	struct OFPlainConditionWaitingTask waitingTask = {
		.task = FindTask(NULL),
		.sigBit = AllocSignal(-1)
	};
	struct MsgPort port = {
		.mp_Node = {
			.ln_Type = NT_MSGPORT
		},
		.mp_Flags = PA_SIGNAL,
		.mp_SigTask = waitingTask.task,
		.mp_SigBit = AllocSignal(-1)
	};
#ifdef OF_AMIGAOS4
	struct TimeRequest request = {
		.Request = {
#else
	struct timerequest request = {
		.tr_node = {
#endif
			.io_Message = {
				.mn_Node = {
					.ln_Type = NT_MESSAGE
				},
				.mn_ReplyPort = &port,
				.mn_Length = sizeof(request)
			},
			.io_Command = TR_ADDREQUEST
		},
#ifdef OF_AMIGAOS4
		.Time = {
			.Seconds = (ULONG)timeout,
			.Microseconds =
			    (timeout - request.Time.Seconds) * 1000000
#else
		.tr_time = {
			.tv_sec = (ULONG)timeout,
			.tv_micro = (timeout - request.tr_time.tv_sec) * 1000000
#endif
		}
	};
	int error = 0;
	ULONG mask;

	NewList(&port.mp_MsgList);

	if (waitingTask.sigBit == -1 || port.mp_SigBit == -1) {
		error = EAGAIN;
		goto fail;
	}

	if (OpenDevice("timer.device", UNIT_MICROHZ,
	    (struct IORequest *)&request, 0) != 0) {
		error = EAGAIN;
		goto fail;
	}

	Forbid();

	if ((error = OFPlainMutexUnlock(mutex)) != 0) {
		Permit();
		goto fail;
	}

	waitingTask.next = condition->waitingTasks;
	condition->waitingTasks = &waitingTask;

	SendIO((struct IORequest *)&request);

	mask = Wait((1ul << waitingTask.sigBit) | (1ul << port.mp_SigBit) |
	    *signalMask);
	if (mask & (1ul << waitingTask.sigBit) || (*signalMask &= mask))
		error = OFPlainMutexLock(mutex);
	else if (mask & (1ul << port.mp_SigBit))
		error = ETIMEDOUT;
	else
		/*
		 * This should not happen - it means something interrupted the
		 * Wait(), so the best we can do is return EINTR.
		 */
		error = EINTR;

	condition->waitingTasks = waitingTask.next;

	if (!CheckIO((struct IORequest *)&request)) {
		AbortIO((struct IORequest *)&request);
		WaitIO((struct IORequest *)&request);
	}
	CloseDevice((struct IORequest *)&request);

	Permit();

fail:
	if (waitingTask.sigBit != -1)
		FreeSignal(waitingTask.sigBit);
	if (port.mp_SigBit != -1)
		FreeSignal(port.mp_SigBit);

	return error;
}

int
OFPlainConditionFree(OFPlainCondition *condition)
{
	Forbid();
	@try {
		if (condition->waitingTasks != NULL)
			return EBUSY;
	} @finally {
		Permit();
	}

	return 0;
}
