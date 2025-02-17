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

#import "OFPlainCondition.h"

int
OFPlainConditionNew(OFPlainCondition *condition)
{
	return pthread_cond_init(condition, NULL);
}

int
OFPlainConditionSignal(OFPlainCondition *condition)
{
	return pthread_cond_signal(condition);
}

int
OFPlainConditionBroadcast(OFPlainCondition *condition)
{
	return pthread_cond_broadcast(condition);
}

int
OFPlainConditionWait(OFPlainCondition *condition, OFPlainMutex *mutex)
{
	return pthread_cond_wait(condition, mutex);
}

int
OFPlainConditionTimedWait(OFPlainCondition *condition, OFPlainMutex *mutex,
    OFTimeInterval timeout)
{
	struct timespec ts;

	if (clock_gettime(CLOCK_REALTIME, &ts) == -1)
		return errno;

	timeout += ts.tv_sec + (OFTimeInterval)ts.tv_nsec / 1000000000;

	ts.tv_sec = (time_t)timeout;
	ts.tv_nsec = (long)((timeout - ts.tv_sec) * 1000000000);

	return pthread_cond_timedwait(condition, mutex, &ts);
}

int
OFPlainConditionFree(OFPlainCondition *condition)
{
	return pthread_cond_destroy(condition);
}
