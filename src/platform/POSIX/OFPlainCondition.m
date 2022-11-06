/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

	ts.tv_sec = (time_t)timeout;
	ts.tv_nsec = (long)((timeout - ts.tv_sec) * 1000000000);

	return pthread_cond_timedwait(condition, mutex, &ts);
}

int
OFPlainConditionFree(OFPlainCondition *condition)
{
	return pthread_cond_destroy(condition);
}
