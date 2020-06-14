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

bool
of_thread_attr_init(of_thread_attr_t *attr)
{
	attr->priority = 0;
	attr->stackSize = 0;

	return true;
}

bool
of_thread_new(of_thread_t *thread, const char *name, void (*function)(id),
    id object, const of_thread_attr_t *attr)
{
	DWORD priority = THREAD_PRIORITY_NORMAL;
	struct thread_context *context;
	DWORD threadID;

	if (attr != NULL && attr->priority != 0) {
		if (attr->priority < -1 || attr->priority > 1) {
			errno = EINVAL;
			return false;
		}

		if (attr->priority < 0)
			priority = THREAD_PRIORITY_LOWEST +
			    (1.0 + attr->priority) *
			    (THREAD_PRIORITY_NORMAL - THREAD_PRIORITY_LOWEST);
		else
			priority = THREAD_PRIORITY_NORMAL +
			    attr->priority *
			    (THREAD_PRIORITY_HIGHEST - THREAD_PRIORITY_NORMAL);
	}

	if ((context = malloc(sizeof(*context))) == NULL) {
		errno = ENOMEM;
		return false;
	}

	context->function = function;
	context->object = object;

	*thread = CreateThread(NULL, (attr != NULL ? attr->stackSize : 0),
	    (LPTHREAD_START_ROUTINE)functionWrapper, context, 0, &threadID);

	if (thread == NULL) {
		int errNo;

		switch (GetLastError()) {
		case ERROR_NOT_ENOUGH_MEMORY:
			errNo = ENOMEM;
			break;
		case ERROR_ACCESS_DENIED:
			errNo = EACCES;
			break;
		default:
			OF_ENSURE(0);
		}

		free(context);
		errno = errNo;
		return false;
	}

	if (attr != NULL && attr->priority != 0)
		OF_ENSURE(!SetThreadPriority(*thread, priority));

	return true;
}

bool
of_thread_join(of_thread_t thread)
{
	switch (WaitForSingleObject(thread, INFINITE)) {
	case WAIT_OBJECT_0:
		CloseHandle(thread);
		return true;
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
of_thread_detach(of_thread_t thread)
{
	CloseHandle(thread);

	return true;
}

void
of_thread_set_name(const char *name)
{
}
