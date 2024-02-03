/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFPlainMutex.h"

#include <windows.h>

int
OFPlainMutexNew(OFPlainMutex *mutex)
{
	InitializeCriticalSection(mutex);

	return 0;
}

int
OFPlainMutexLock(OFPlainMutex *mutex)
{
	EnterCriticalSection(mutex);

	return 0;
}

int
OFPlainMutexTryLock(OFPlainMutex *mutex)
{
	if (!TryEnterCriticalSection(mutex))
		return EBUSY;

	return 0;
}

int
OFPlainMutexUnlock(OFPlainMutex *mutex)
{
	LeaveCriticalSection(mutex);

	return 0;
}

int
OFPlainMutexFree(OFPlainMutex *mutex)
{
	DeleteCriticalSection(mutex);

	return 0;
}

int
OFPlainRecursiveMutexNew(OFPlainRecursiveMutex *rmutex)
{
	return OFPlainMutexNew(rmutex);
}

int
OFPlainRecursiveMutexLock(OFPlainRecursiveMutex *rmutex)
{
	return OFPlainMutexLock(rmutex);
}

int
OFPlainRecursiveMutexTryLock(OFPlainRecursiveMutex *rmutex)
{
	return OFPlainMutexTryLock(rmutex);
}

int
OFPlainRecursiveMutexUnlock(OFPlainRecursiveMutex *rmutex)
{
	return OFPlainMutexUnlock(rmutex);
}

int
OFPlainRecursiveMutexFree(OFPlainRecursiveMutex *rmutex)
{
	return OFPlainMutexFree(rmutex);
}
