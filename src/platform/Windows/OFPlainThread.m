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
#import "OFConstantString.h"

#include <windows.h>

struct ThreadContext {
	void (*function)(id);
	id object;
};

static WINAPI void
functionWrapper(struct ThreadContext *context)
{
	context->function(context->object);

	free(context);
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
	DWORD priority = THREAD_PRIORITY_NORMAL;
	struct ThreadContext *context;
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
			OFEnsure(0);
		}

		free(context);
		return error;
	}

	if (attr != NULL && attr->priority != 0)
		OFEnsure(!SetThreadPriority(*thread, priority));

	return 0;
}

int
OFPlainThreadJoin(OFPlainThread thread)
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
			OFEnsure(0);
		}
	default:
		OFEnsure(0);
	}
}

int
OFPlainThreadDetach(OFPlainThread thread)
{
	CloseHandle(thread);

	return 0;
}

void
OFSetThreadName(const char *name)
{
}
