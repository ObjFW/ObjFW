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

bool
of_condition_new(of_condition_t *condition)
{
	condition->count = 0;

	if ((condition->event = CreateEvent(NULL, FALSE, 0, NULL)) == NULL) {
		errno = EAGAIN;
		return false;
	}

	return true;
}

bool
of_condition_signal(of_condition_t *condition)
{
	if (!SetEvent(condition->event)) {
		switch (GetLastError()) {
		case ERROR_INVALID_HANDLE:
			errno = EINVAL;
			return false;
		default:
			OF_ENSURE(0);
		}
	}

	return true;
}

bool
of_condition_broadcast(of_condition_t *condition)
{
	int count = condition->count;

	for (int i = 0; i < count; i++) {
		if (!SetEvent(condition->event)) {
			switch (GetLastError()) {
			case ERROR_INVALID_HANDLE:
				errno = EINVAL;
				return false;
			default:
				OF_ENSURE(0);
			}
		}
	}

	return true;
}

bool
of_condition_wait(of_condition_t *condition, of_mutex_t *mutex)
{
	DWORD status;

	if (!of_mutex_unlock(mutex))
		return false;

	of_atomic_int_inc(&condition->count);
	status = WaitForSingleObject(condition->event, INFINITE);
	of_atomic_int_dec(&condition->count);

	switch (status) {
	case WAIT_OBJECT_0:
		return of_mutex_lock(mutex);
	case WAIT_FAILED:
		switch (GetLastError()) {
		case ERROR_INVALID_HANDLE:
			errno = EINVAL;
			return false;
		default:
			OF_ENSURE(0);
		}
	default:
		OF_ENSURE(0);
	}
}

bool
of_condition_timed_wait(of_condition_t *condition, of_mutex_t *mutex,
    of_time_interval_t timeout)
{
	DWORD status;

	if (!of_mutex_unlock(mutex))
		return false;

	of_atomic_int_inc(&condition->count);
	status = WaitForSingleObject(condition->event, timeout * 1000);
	of_atomic_int_dec(&condition->count);

	switch (status) {
	case WAIT_OBJECT_0:
		return of_mutex_lock(mutex);
	case WAIT_TIMEOUT:
		errno = ETIMEDOUT;
		return false;
	case WAIT_FAILED:
		switch (GetLastError()) {
		case ERROR_INVALID_HANDLE:
			errno = EINVAL;
			return false;
		default:
			OF_ENSURE(0);
		}
	default:
		OF_ENSURE(0);
	}
}

bool
of_condition_free(of_condition_t *condition)
{
	if (condition->count != 0) {
		errno = EBUSY;
		return false;
	}

	return CloseHandle(condition->event);
}
