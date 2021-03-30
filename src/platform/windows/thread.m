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

#import "thread.h"
#import "macros.h"

#include <windows.h>

struct thread_context {
	void (*function)(id);
	id object;
};

static WINAPI void
functionWrapper(struct thread_context *context)
{
	context->function(context->object);

	free(context);
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
	DWORD priority = THREAD_PRIORITY_NORMAL;
	struct thread_context *context;
	DWORD threadID;

	if (attr != NULL && attr->priority != 0) {
		if (attr->priority < -1 || attr->priority > 1)
			return EINVAL;

		if (attr->priority < 0)
			priority = THREAD_PRIORITY_LOWEST +
			    (1.0 + attr->priority) *
			    (THREAD_PRIORITY_NORMAL - THREAD_PRIORITY_LOWEST);
		else
			priority = THREAD_PRIORITY_NORMAL +
			    attr->priority *
			    (THREAD_PRIORITY_HIGHEST - THREAD_PRIORITY_NORMAL);
	}

	if ((context = malloc(sizeof(*context))) == NULL)
		return ENOMEM;

	context->function = function;
	context->object = object;

	*thread = CreateThread(NULL, (attr != NULL ? attr->stackSize : 0),
	    (LPTHREAD_START_ROUTINE)functionWrapper, context, 0, &threadID);

	if (thread == NULL) {
		int error;

		switch (GetLastError()) {
		case ERROR_NOT_ENOUGH_MEMORY:
			error = ENOMEM;
			break;
		case ERROR_ACCESS_DENIED:
			error = EACCES;
			break;
		default:
			OF_ENSURE(0);
		}

		free(context);
		return error;
	}

	if (attr != NULL && attr->priority != 0)
		OF_ENSURE(!SetThreadPriority(*thread, priority));

	return 0;
}

int
of_thread_join(of_thread_t thread)
{
	switch (WaitForSingleObject(thread, INFINITE)) {
	case WAIT_OBJECT_0:
		CloseHandle(thread);
		return 0;
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
of_thread_detach(of_thread_t thread)
{
	CloseHandle(thread);

	return 0;
}

void
of_thread_set_name(const char *name)
{
}
