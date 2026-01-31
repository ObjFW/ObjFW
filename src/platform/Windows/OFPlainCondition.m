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

#include "config.h"

#include <errno.h>

#import "OFPlainCondition.h"
#import "OFConstantString.h"

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
			OFEnsure(0);
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
				OFEnsure(0);
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

	OFAtomicIntIncrease(&condition->count);
	status = WaitForSingleObject(condition->event, INFINITE);
	OFAtomicIntDecrease(&condition->count);

	switch (status) {
	case WAIT_OBJECT_0:
		return OFPlainMutexLock(mutex);
	case WAIT_FAILED:
		switch (GetLastError()) {
		case ERROR_INVALID_HANDLE:
			return EINVAL;
		default:
			OFEnsure(0);
		}
	default:
		OFEnsure(0);
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

	OFAtomicIntIncrease(&condition->count);
	status = WaitForSingleObject(condition->event, timeout * 1000);
	OFAtomicIntDecrease(&condition->count);

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
			OFEnsure(0);
		}
	default:
		OFEnsure(0);
	}
}

int
OFPlainConditionFree(OFPlainCondition *condition)
{
	if (condition->count != 0)
		return EBUSY;

	return (CloseHandle(condition->event) ? 0 : EINVAL);
}
