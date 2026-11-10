/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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
#import "OFOnce.h"

#include <windows.h>

static OFOnceControl onceControl = OFOnceControlInitValue;
static WINAPI BOOLEAN (*TryEnterCriticalSectionFuncPtr)(LPCRITICAL_SECTION);

static void
initIsNT()
{
	if (!(GetVersion() & 0x80000000)) {
		HMODULE kernel32;
		if ((kernel32 = GetModuleHandleA("kernel32.dll")) != NULL)
			TryEnterCriticalSectionFuncPtr =
			    (WINAPI BOOLEAN (*)(LPCRITICAL_SECTION))
			    GetProcAddress(kernel32, "TryEnterCriticalSection");
	}
}

int
OFPlainMutexNew(OFPlainMutex *mutex)
{
	OFOnce(&onceControl, initIsNT);

	if (TryEnterCriticalSectionFuncPtr != NULL) {
		InitializeCriticalSection(mutex);
		return 0;
	} else {
		if ((*(HANDLE *)mutex = CreateMutex(NULL, FALSE, NULL)) == NULL)
			return ENOMEM;

		return 0;
	}
}

int
OFPlainMutexLock(OFPlainMutex *mutex)
{
	if (TryEnterCriticalSectionFuncPtr != NULL) {
		EnterCriticalSection(mutex);
		return 0;
	} else {
		switch (WaitForSingleObject(*(HANDLE *)mutex, INFINITE)) {
		case WAIT_OBJECT_0:
		case WAIT_ABANDONED:
			return 0;
		default:
			return EINVAL;
		}
	}
}

int
OFPlainMutexTryLock(OFPlainMutex *mutex)
{
	if (TryEnterCriticalSectionFuncPtr != NULL) {
		if (!TryEnterCriticalSectionFuncPtr(mutex))
			return EBUSY;

		return 0;
	} else {
		switch (WaitForSingleObject(*(HANDLE *)mutex, 0)) {
		case WAIT_OBJECT_0:
		case WAIT_ABANDONED:
			return 0;
		case WAIT_TIMEOUT:
			return EBUSY;
		default:
			return EINVAL;
		}
	}
}

int
OFPlainMutexUnlock(OFPlainMutex *mutex)
{
	if (TryEnterCriticalSectionFuncPtr != NULL) {
		LeaveCriticalSection(mutex);
		return 0;
	} else {
		if (!ReleaseMutex(*(HANDLE *)mutex))
			return EINVAL;

		return 0;
	}
}

int
OFPlainMutexFree(OFPlainMutex *mutex)
{
	if (TryEnterCriticalSectionFuncPtr != NULL) {
		DeleteCriticalSection(mutex);
		return 0;
	} else {
		if (!CloseHandle(*(HANDLE *)mutex))
			return EINVAL;

		return 0;
	}
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
