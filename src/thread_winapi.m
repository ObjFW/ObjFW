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

#import "macros.h"

bool
of_thread_attr_init(of_thread_attr_t *attr)
{
	attr->priority = 0;
	attr->stackSize = 0;

	return true;
}

bool
of_thread_new(of_thread_t *thread, void (*function)(id), id object,
    const of_thread_attr_t *attr)
{
	*thread = CreateThread(NULL, (attr != NULL ? attr->stackSize : 0),
	    (LPTHREAD_START_ROUTINE)function, (void *)object, 0, NULL);

	if (thread == NULL)
		return false;

	if (attr != NULL && attr->priority != 0) {
		DWORD priority;

		if (attr->priority < -1 || attr->priority > 1)
			return false;

		if (attr->priority < 0)
			priority = THREAD_PRIORITY_LOWEST +
			    (1.0 + attr->priority) *
			    (THREAD_PRIORITY_NORMAL - THREAD_PRIORITY_LOWEST);
		else
			priority = THREAD_PRIORITY_NORMAL +
			    attr->priority *
			    (THREAD_PRIORITY_HIGHEST - THREAD_PRIORITY_NORMAL);

		if (!SetThreadPriority(*thread, priority))
			return false;
	}

	return true;
}

bool
of_thread_join(of_thread_t thread)
{
	if (WaitForSingleObject(thread, INFINITE))
		return false;

	CloseHandle(thread);

	return true;
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
