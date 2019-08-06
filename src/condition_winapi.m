/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

bool
of_condition_new(of_condition_t *condition)
{
	condition->count = 0;

	if ((condition->event = CreateEvent(NULL, FALSE, 0, NULL)) == NULL)
		return false;

	return true;
}

bool
of_condition_signal(of_condition_t *condition)
{
	return SetEvent(condition->event);
}

bool
of_condition_broadcast(of_condition_t *condition)
{
	int count = condition->count;

	for (int i = 0; i < count; i++)
		if (!SetEvent(condition->event))
			return false;

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

	if (!of_mutex_lock(mutex))
		return false;

	return (status == WAIT_OBJECT_0);
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

	if (!of_mutex_lock(mutex))
		return false;

	return (status == WAIT_OBJECT_0);
}

bool
of_condition_free(of_condition_t *condition)
{
	if (condition->count != 0)
		return false;

	return CloseHandle(condition->event);
}
