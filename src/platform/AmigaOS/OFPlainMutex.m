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

#import "OFPlainMutex.h"

#define Class IntuitionClass
#include <proto/exec.h>
#undef Class

int
OFPlainMutexNew(OFPlainMutex *mutex)
{
	InitSemaphore(mutex);

	return 0;
}

int
OFPlainMutexLock(OFPlainMutex *mutex)
{
	ObtainSemaphore(mutex);

	return 0;
}

int
OFPlainMutexTryLock(OFPlainMutex *mutex)
{
	if (!AttemptSemaphore(mutex))
		return EBUSY;

	return 0;
}

int
OFPlainMutexUnlock(OFPlainMutex *mutex)
{
	ReleaseSemaphore(mutex);

	return 0;
}

int
OFPlainMutexFree(OFPlainMutex *mutex)
{
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
