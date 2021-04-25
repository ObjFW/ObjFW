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

#include <stdio.h>
#include <stdlib.h>

#import "ObjFWRT.h"
#import "private.h"

#import "OFOnce.h"
#import "OFPlainMutex.h"

static OFPlainRecursiveMutex globalMutex;

static void
init(void)
{
	if (OFPlainRecursiveMutexNew(&globalMutex) != 0)
		OBJC_ERROR("Failed to create global mutex!");
}

void
objc_global_mutex_lock(void)
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, init);

	if (OFPlainRecursiveMutexLock(&globalMutex) != 0)
		OBJC_ERROR("Failed to lock global mutex!");
}

void
objc_global_mutex_unlock(void)
{
	if (OFPlainRecursiveMutexUnlock(&globalMutex) != 0)
		OBJC_ERROR("Failed to unlock global mutex!");
}
