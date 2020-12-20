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

#include "config.h"

#include <assert.h>
#include <errno.h>

#import "OFData.h"

#import "thread.h"
#import "tlskey.h"

#include <dos/dostags.h>
#include <proto/dos.h>
#include <proto/exec.h>

#ifndef OF_MORPHOS
extern void of_tlskey_thread_exited(void);
#endif
static of_tlskey_t threadKey;

OF_CONSTRUCTOR()
{
	OF_ENSURE(of_tlskey_new(&threadKey) == 0);
}

static void
functionWrapper(void)
{
	bool detached = false;
	of_thread_t thread =
	    (of_thread_t)((struct Process *)FindTask(NULL))->pr_ExitData;
	OF_ENSURE(of_tlskey_set(threadKey, thread) == 0);

	thread->function(thread->object);

	ObtainSemaphore(&thread->semaphore);
	@try {
		thread->done = true;

#ifndef OF_MORPHOS
		of_tlskey_thread_exited();
#endif

		if (thread->detached)
			detached = true;
		else if (thread->joinTask != NULL)
			Signal(thread->joinTask, (1ul << thread->joinSigBit));
	} @finally {
		ReleaseSemaphore(&thread->semaphore);
	}

	if (detached)
		free(thread);
}

int
of_thread_attr_init(of_thread_attr_t *attr)
{
	attr->priority = 0;
	attr->stackSize = 0;

	return 0;
}

int
of_thread_new(of_thread_t *thread, const char *name, void (*function)(id),
    id object, const of_thread_attr_t *attr)
{
	OFMutableData *tags = nil;

	if ((*thread = calloc(1, sizeof(**thread))) == NULL)
		return ENOMEM;

	@try {
		(*thread)->function = function;
		(*thread)->object = object;
		InitSemaphore(&(*thread)->semaphore);

		tags = [[OFMutableData alloc]
		    initWithItemSize: sizeof(struct TagItem)
			    capacity: 12];
#define ADD_TAG(tag, data)			\
		{				\
			struct TagItem t = {	\
				.ti_Tag = tag,	\
				.ti_Data = data	\
			};			\
			[tags addItem: &t];	\
		}
		ADD_TAG(NP_Entry, (ULONG)functionWrapper)
		ADD_TAG(NP_ExitData, (ULONG)*thread)
#ifdef OF_AMIGAOS4
		ADD_TAG(NP_Child, TRUE)
#endif
#ifdef OF_MORPHOS
		ADD_TAG(NP_CodeType, CODETYPE_PPC);
#endif
		if (name != NULL)
			ADD_TAG(NP_Name, (ULONG)name);

		ADD_TAG(NP_Input, ((struct Process *)FindTask(NULL))->pr_CIS)
		ADD_TAG(NP_Output, ((struct Process *)FindTask(NULL))->pr_COS)
		ADD_TAG(NP_Error, ((struct Process *)FindTask(NULL))->pr_CES)
		ADD_TAG(NP_CloseInput, FALSE)
		ADD_TAG(NP_CloseOutput, FALSE)
		ADD_TAG(NP_CloseError, FALSE)

		if (attr != NULL && attr->priority != 0) {
			if (attr->priority < 1 || attr->priority > 1)
				return EINVAL;

			/*
			 * -1 should be -128 (lowest possible priority) while
			 * +1 should be +127 (highest possible priority).
			 */
			ADD_TAG(NP_Priority, (attr->priority > 0
			    ? attr->priority * 127 : attr->priority * 128))
		}

		if (attr != NULL && attr->stackSize != 0)
			ADD_TAG(NP_StackSize, attr->stackSize)
		else
			ADD_TAG(NP_StackSize,
			    ((struct Process *)FindTask(NULL))->pr_StackSize)

		ADD_TAG(TAG_DONE, 0)
#undef ADD_TAG

		(*thread)->task = (struct Task *)CreateNewProc(tags.items);
		if ((*thread)->task == NULL) {
			free(*thread);
			return EAGAIN;
		}
	} @catch (id e) {
		free(*thread);
		@throw e;
	} @finally {
		[tags release];
	}

	return 0;
}

of_thread_t
of_thread_current(void)
{
	return of_tlskey_get(threadKey);
}

int
of_thread_join(of_thread_t thread)
{
	ObtainSemaphore(&thread->semaphore);

	if (thread->done) {
		ReleaseSemaphore(&thread->semaphore);

		free(thread);
		return 0;
	}

	@try {
		if (thread->detached || thread->joinTask != NULL)
			return EINVAL;

		if ((thread->joinSigBit = AllocSignal(-1)) == -1)
			return EAGAIN;

		thread->joinTask = FindTask(NULL);
	} @finally {
		ReleaseSemaphore(&thread->semaphore);
	}

	Wait(1ul << thread->joinSigBit);
	FreeSignal(thread->joinSigBit);

	assert(thread->done);
	free(thread);

	return 0;
}

int
of_thread_detach(of_thread_t thread)
{
	ObtainSemaphore(&thread->semaphore);

	if (thread->done)
		free(thread);
	else
		thread->detached = true;

	ReleaseSemaphore(&thread->semaphore);

	return 0;
}

void
of_thread_set_name(const char *name)
{
}
