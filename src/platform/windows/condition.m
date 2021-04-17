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

#include "config.h"

#include <errno.h>

#import "condition.h"

#include <windows.h>

int
OFPlainConditionNew(OFPlainCondition *condition)
{
	condition->count = 0;

	if ((condition->event = CreateEvent(NULL, FALSE, 0, NULL)) == NULL)
		return EAGAIN;

	return 0;
}

int
OFPlainConditionSignal(OFPlainCondition *condition)
{
	if (!SetEvent(condition->event)) {
		switch (GetLastError()) {
		case ERROR_INVALID_HANDLE:
			return EINVAL;
		default:
			OF_ENSURE(0);
		}
	}

	return 0;
}

int
OFPlainConditionBroadcast(OFPlainCondition *condition)
{
	int count = condition->count;

	for (int i = 0; i < count; i++) {
		if (!SetEvent(condition->event)) {
			switch (GetLastError()) {
			case ERROR_INVALID_HANDLE:
				return EINVAL;
			default:
				OF_ENSURE(0);
			}
		}
	}

	return 0;
}

int
OFPlainConditionWait(OFPlainCondition *condition, OFPlainMutex *mutex)
{
	int error;
	DWORD status;

	if ((error = OFPlainMutexUnlock(mutex)) != 0)
		return error;

	of_atomic_int_inc(&condition->count);
	status = WaitForSingleObject(condition->event, INFINITE);
	of_atomic_int_dec(&condition->count);

	switch (status) {
	case WAIT_OBJECT_0:
		return OFPlainMutexLock(mutex);
	case WAIT_FAILED:
		switch (GetLastError()) {
		case ERROR_INVALID_HANDLE:
			return EINVAL;
		default:
			OF_ENSURE(0);
		}
	default:
		OF_ENSURE(0);
	}
}

int
OFPlainConditionTimedWait(OFPlainCondition *condition, OFPlainMutex *mutex,
    OFTimeInterval timeout)
{
	int error;
	DWORD status;

	if ((error = OFPlainMutexUnlock(mutex)) != 0)
		return error;

	of_atomic_int_inc(&condition->count);
	status = WaitForSingleObject(condition->event, timeout * 1000);
	of_atomic_int_dec(&condition->count);

	switch (status) {
	case WAIT_OBJECT_0:
		return OFPlainMutexLock(mutex);
	case WAIT_TIMEOUT:
		return ETIMEDOUT;
	case WAIT_FAILED:
		switch (GetLastError()) {
		case ERROR_INVALID_HANDLE:
			return EINVAL;
		default:
			OF_ENSURE(0);
		}
	default:
		OF_ENSURE(0);
	}
}

int
OFPlainConditionFree(OFPlainCondition *condition)
{
	if (condition->count != 0)
		return EBUSY;

	return (CloseHandle(condition->event) ? 0 : EINVAL);
}
