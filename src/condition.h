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

#include "objfw-defs.h"

#include "platform.h"

#if !defined(OF_HAVE_THREADS) || \
    (!defined(OF_HAVE_PTHREADS) && !defined(OF_WINDOWS) && !defined(OF_AMIGAOS))
# error No conditions available!
#endif

/* For of_time_interval_t */
#import "OFObject.h"

#import "mutex.h"

#if defined(OF_HAVE_PTHREADS)
# include <pthread.h>
typedef pthread_cond_t of_condition_t;
#elif defined(OF_WINDOWS)
# include <windows.h>
typedef struct {
	HANDLE event;
	volatile int count;
} of_condition_t;
#elif defined(OF_AMIGAOS)
# include <exec/tasks.h>
typedef struct {
	struct of_condition_waiting_task {
		struct Task *task;
		uint8_t sigBit;
		struct of_condition_waiting_task *next;
	} *waitingTasks;
} of_condition_t;
#endif

#ifdef __cplusplus
extern "C" {
#endif
extern bool of_condition_new(of_condition_t *condition);
extern bool of_condition_signal(of_condition_t *condition);
extern bool of_condition_broadcast(of_condition_t *condition);
extern bool of_condition_wait(of_condition_t *condition, of_mutex_t *mutex);
extern bool of_condition_timed_wait(of_condition_t *condition,
    of_mutex_t *mutex, of_time_interval_t timeout);
extern bool of_condition_free(of_condition_t *condition);
#ifdef __cplusplus
}
#endif
