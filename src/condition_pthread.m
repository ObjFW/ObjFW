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

#include <math.h>

bool
of_condition_new(of_condition_t *condition)
{
	return (pthread_cond_init(condition, NULL) == 0);
}

bool
of_condition_signal(of_condition_t *condition)
{
	return (pthread_cond_signal(condition) == 0);
}

bool
of_condition_broadcast(of_condition_t *condition)
{
	return (pthread_cond_broadcast(condition) == 0);
}

bool
of_condition_wait(of_condition_t *condition, of_mutex_t *mutex)
{
	return (pthread_cond_wait(condition, mutex) == 0);
}

bool
of_condition_timed_wait(of_condition_t *condition, of_mutex_t *mutex,
    of_time_interval_t timeout)
{
	struct timespec ts;

	ts.tv_sec = (time_t)timeout;
	ts.tv_nsec = lrint((timeout - ts.tv_sec) * 1000000000);

	return (pthread_cond_timedwait(condition, mutex, &ts) == 0);
}

bool
of_condition_free(of_condition_t *condition)
{
	return (pthread_cond_destroy(condition) == 0);
}
