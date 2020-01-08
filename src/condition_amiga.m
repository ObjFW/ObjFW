/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

#include <errno.h>

#include <proto/exec.h>
#include <devices/timer.h>
#ifndef OF_AMIGAOS4
# include <clib/alib_protos.h>
#endif

bool
of_condition_new(of_condition_t *condition)
{
	condition->waitingTasks = NULL;

	return true;
}

bool
of_condition_signal(of_condition_t *condition)
{
	Forbid();
	@try {
		if (condition->waitingTasks == NULL)
			return true;

		Signal(condition->waitingTasks->task,
		    (1ul << condition->waitingTasks->sigBit));

		condition->waitingTasks = condition->waitingTasks->next;
	} @finally {
		Permit();
	}

	return true;
}

bool
of_condition_broadcast(of_condition_t *condition)
{
	Forbid();
	@try {
		if (condition->waitingTasks == NULL)
			return true;

		while (condition->waitingTasks != NULL) {
			Signal(condition->waitingTasks->task,
			    (1ul << condition->waitingTasks->sigBit));

			condition->waitingTasks = condition->waitingTasks->next;
		}
	} @finally {
		Permit();
	}

	return true;
}

bool
of_condition_wait(of_condition_t *condition, of_mutex_t *mutex)
{
	ULONG signalMask = 0;

	return of_condition_wait_or_signal(condition, mutex, &signalMask);
}

bool
of_condition_wait_or_signal(of_condition_t *condition, of_mutex_t *mutex,
    ULONG *signalMask)
{
	struct of_condition_waiting_task waitingTask = {
		.task = FindTask(NULL),
		.sigBit = AllocSignal(-1)
	};
	bool ret;
	ULONG mask;

	if (waitingTask.sigBit == -1) {
		errno = EAGAIN;
		return false;
	}

	Forbid();

	if (!of_mutex_unlock(mutex)) {
		FreeSignal(waitingTask.sigBit);
		return false;
	}

	waitingTask.next = condition->waitingTasks;
	condition->waitingTasks = &waitingTask;

	mask = Wait((1ul << waitingTask.sigBit) | *signalMask);
	if (mask & (1ul << waitingTask.sigBit) || (*signalMask &= mask))
		ret = of_mutex_lock(mutex);
	else {
		/*
		 * This should not happen - it means something interrupted the
		 * Wait(), so the best we can do is return EINTR.
		 */
		ret = false;
		errno = EINTR;
	}

	FreeSignal(waitingTask.sigBit);

	Permit();

	return ret;
}

bool
of_condition_timed_wait(of_condition_t *condition, of_mutex_t *mutex,
    of_time_interval_t timeout)
{
	ULONG signalMask = 0;

	return of_condition_timed_wait_or_signal(condition, mutex, timeout,
	    &signalMask);
}

bool
of_condition_timed_wait_or_signal(of_condition_t *condition, of_mutex_t *mutex,
    of_time_interval_t timeout, ULONG *signalMask)
{
	struct of_condition_waiting_task waitingTask = {
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
	ULONG mask;
	bool ret;

	NewList(&port.mp_MsgList);

	if (waitingTask.sigBit == -1 || port.mp_SigBit == -1) {
		errno = EAGAIN;
		goto fail;
	}

	if (OpenDevice("timer.device", UNIT_MICROHZ,
	    (struct IORequest *)&request, 0) != 0) {
		errno = EAGAIN;
		goto fail;
	}

	Forbid();

	if (!of_mutex_unlock(mutex)) {
		Permit();
		goto fail;
	}

	waitingTask.next = condition->waitingTasks;
	condition->waitingTasks = &waitingTask;

	SendIO((struct IORequest *)&request);

	mask = Wait((1ul << waitingTask.sigBit) | (1ul << port.mp_SigBit) |
	    *signalMask);
	if (mask & (1ul << waitingTask.sigBit) || (*signalMask &= mask))
		ret = of_mutex_lock(mutex);
	else if (mask & (1ul << port.mp_SigBit)) {
		ret = false;
		errno = ETIMEDOUT;
	} else {
		/*
		 * This should not happen - it means something interrupted the
		 * Wait(), so the best we can do is return EINTR.
		 */
		ret = false;
		errno = EINTR;
	}

	condition->waitingTasks = waitingTask.next;

	if (!CheckIO((struct IORequest *)&request)) {
		AbortIO((struct IORequest *)&request);
		WaitIO((struct IORequest *)&request);
	}
	CloseDevice((struct IORequest *)&request);

	Permit();

	FreeSignal(waitingTask.sigBit);
	FreeSignal(port.mp_SigBit);

	return ret;

fail:
	if (waitingTask.sigBit != -1)
		FreeSignal(waitingTask.sigBit);
	if (port.mp_SigBit != -1)
		FreeSignal(port.mp_SigBit);

	return false;
}

bool
of_condition_free(of_condition_t *condition)
{
	Forbid();
	@try {
		if (condition->waitingTasks != NULL) {
			errno = EBUSY;
			return false;
		}
	} @finally {
		Permit();
	}

	return true;
}
