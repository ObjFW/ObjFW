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

#include <errno.h>

#import "OFPlainCondition.h"

#define Class IntuitionClass
#include <proto/exec.h>
#include <devices/timer.h>
#ifndef OF_AMIGAOS4
# include <clib/alib_protos.h>
#endif
#undef Class

extern struct Device *TimerBase;
extern struct Unit *MicroHZUnit;

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
	struct _OFPlainConditionWaitingTask waitingTask = {
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
	error = OFPlainMutexLock(mutex);

	if (!(mask & (1ul << waitingTask.sigBit)) && !(*signalMask &= mask))
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
	struct _OFPlainConditionWaitingTask waitingTask = {
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
			.io_Device = TimerBase,
			.io_Unit = MicroHZUnit,
			.io_Command = TR_ADDREQUEST
		},
#ifdef OF_AMIGAOS4
		.Time = {
			.Seconds = (ULONG)timeout,
			.Microseconds =
			    (timeout - request.Time.Seconds) * 1000000
#else
		.tr_time = {
			.tv_secs = (ULONG)timeout,
			.tv_micro =
			    (timeout - request.tr_time.tv_secs) * 1000000
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
	error = OFPlainMutexLock(mutex);

	if (!(mask & (1ul << waitingTask.sigBit)) && !(*signalMask &= mask)) {
		if (mask & (1ul << port.mp_SigBit))
			error = ETIMEDOUT;
		else
			/*
			 * This should not happen - it means something
			 * interrupted the Wait(), so the best we can do is
			 * return EINTR.
			 */
			error = EINTR;
	}

	condition->waitingTasks = waitingTask.next;

	if (!CheckIO((struct IORequest *)&request)) {
		AbortIO((struct IORequest *)&request);
		WaitIO((struct IORequest *)&request);
	}

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
