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

#include <errno.h>

#import "OFPlainThread.h"
#import "OFData.h"
#import "OFString.h"
#import "OFTLSKey.h"

#define Class IntuitionClass
#include <dos/dostags.h>
#include <proto/dos.h>
#include <proto/exec.h>
#undef Class

#ifndef OF_MORPHOS
extern void OFTLSKeyThreadExited(void);
#endif
static OFTLSKey threadKey;

OF_CONSTRUCTOR()
{
	OFEnsure(OFTLSKeyNew(&threadKey) == 0);
}

static void
functionWrapper(void)
{
	bool detached = false;
	OFPlainThread thread =
	    (OFPlainThread)((struct Process *)FindTask(NULL))->pr_ExitData;
	OFEnsure(OFTLSKeySet(threadKey, thread) == 0);

	thread->function(thread->object);

	ObtainSemaphore(&thread->semaphore);
	@try {
		thread->done = true;

#ifndef OF_MORPHOS
		OFTLSKeyThreadExited();
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
OFPlainThreadAttributesInit(OFPlainThreadAttributes *attr)
{
	attr->priority = 0;
	attr->stackSize = 0;

	return 0;
}

int
OFPlainThreadNew(OFPlainThread *thread, const char *name, void (*function)(id),
    id object, const OFPlainThreadAttributes *attr)
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

		ADD_TAG(TAG_END, 0)
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
		objc_release(tags);
	}

	return 0;
}

OFPlainThread
OFCurrentPlainThread(void)
{
	return OFTLSKeyGet(threadKey);
}

bool
OFPlainThreadIsCurrent(OFPlainThread thread)
{
	return (thread->task == FindTask(NULL));
}

int
OFPlainThreadJoin(OFPlainThread thread)
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

	OFAssert(thread->done);
	free(thread);

	return 0;
}

int
OFPlainThreadDetach(OFPlainThread thread)
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
OFSetThreadName(const char *name)
{
}
