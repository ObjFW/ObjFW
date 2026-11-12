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

#ifndef _LARGEFILE64_SOURCE
# define _LARGEFILE64_SOURCE 1
#endif

#include <errno.h>

#ifdef HAVE_FCNTL_H
# include <fcntl.h>
#endif
#include "unistd_wrapper.h"

#ifdef HAVE_SYS_STAT_H
# include <sys/stat.h>
#endif

#import "OFFile.h"
#import "OFLocale.h"
#import "OFString.h"
#import "OFSystemInfo.h"

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFNotOpenException.h"
#import "OFOpenItemFailedException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFSeekFailedException.h"
#import "OFWriteFailedException.h"

#ifdef OF_WINDOWS
# include <windows.h>
#endif

#ifdef OF_AMIGAOS
# define Class IntuitionClass
# include <proto/exec.h>
# include <proto/dos.h>
# undef Class
#endif

#ifdef OF_WII
# include <fat.h>
#endif

#ifdef OF_NINTENDO_DS
# include <stdbool.h>
# include <filesystem.h>
#endif

#ifdef OF_NINTENDO_SWITCH
# define id nx_id
# include <switch.h>
# undef id
#endif

#ifndef O_BINARY
# define O_BINARY 0
#endif
#ifndef O_CLOEXEC
# define O_CLOEXEC 0
#endif
#ifndef O_EXCL
# define O_EXCL 0
#endif
#ifndef O_EXLOCK
# define O_EXLOCK 0
#endif

#if defined(OF_WINDOWS)
struct _OFFileHandle {
	HANDLE handle;
	bool append;
};

static void
closeHandle(OFFileHandle handle)
{
	CloseHandle(handle->handle);
	OFFreeMemory(handle);
}
#elif defined(OF_AMIGAOS)
static struct _OFFileHandle {
	struct _OFFileHandle *previous, *next;
	BPTR handle;
	bool append;
} *firstHandle = NULL;

static void
closeHandle(OFFileHandle handle)
{
	Close(handle->handle);

	Forbid();

	if (handle->previous != NULL)
		handle->previous->next = handle->next;
	if (handle->next != NULL)
		handle->next->previous = handle->previous;

	if (firstHandle == handle)
		firstHandle = handle->next;

	Permit();

	OFFreeMemory(handle);
}

OF_DESTRUCTOR()
{
	for (OFFileHandle iter = firstHandle; iter != NULL;
	    iter = iter->next)
		Close(iter->handle);
}
#else
# define closeHandle(h) close(h)
#endif

#if defined(OF_WINDOWS)
static bool
parseMode(const char *mode, DWORD *access, DWORD *create, bool *append)
{
	*access = 0;
	*create = 0;
	*append = false;

	switch (*mode) {
	case 'r':
		*access = GENERIC_READ;
		*create = OPEN_EXISTING;
		break;
	case 'w':
		*access = GENERIC_WRITE;
		*create = CREATE_ALWAYS;
		break;
	case 'a':
		*access = GENERIC_WRITE;
		*create = OPEN_ALWAYS;
		*append = true;
		break;
	default:
		return false;
	}

	for (mode++; *mode != '\0'; mode++) {
		switch (*mode) {
		case '+':
			*access = GENERIC_READ | GENERIC_WRITE;
			break;
		case 'x':
			*create = CREATE_NEW;
			break;
		default:
			return false;
		}
	}

	return true;
}

static int
errorToErrNo()
{
	switch (GetLastError()) {
	case ERROR_INVALID_HANDLE:
		return EBADF;
	case ERROR_FILE_NOT_FOUND:
	case ERROR_PATH_NOT_FOUND:
	case ERROR_INVALID_DRIVE:
		return ENOENT;
	case ERROR_FILE_EXISTS:
	case ERROR_ALREADY_EXISTS:
		return EEXIST;
	case ERROR_ACCESS_DENIED:
		return EACCES;
	case ERROR_INVALID_NAME:
		return EILSEQ;
	case ERROR_FILENAME_EXCED_RANGE:
		return ENAMETOOLONG;
	case ERROR_TOO_MANY_OPEN_FILES:
		return ENFILE;
	case ERROR_NOT_ENOUGH_MEMORY:
		return ENOMEM;
	case ERROR_WRITE_PROTECT:
		return EROFS;
	case ERROR_DISK_FULL:
		return ENOSPC;
	case ERROR_INVALID_PARAMETER:
	case ERROR_SEEK:
	case ERROR_NEGATIVE_SEEK:
		return EINVAL;
	case ERROR_NOACCESS:
	case ERROR_INVALID_ADDRESS:
		return EFAULT;
	default:
		return EIO;
	}
}
#elif defined(OF_AMIGAOS)
static int
parseMode(const char *mode, bool *truncate, bool *failIfExists, bool *append)
{
	int ret = 0;
	*truncate = false;
	*failIfExists = false;
	*append = false;

	switch (*mode) {
	case 'r':
		ret |= MODE_OLDFILE;
		break;
	case 'w':
		ret |= MODE_READWRITE;
		*truncate = true;
		break;
	case 'a':
		ret |= MODE_READWRITE;
		*append = true;
		break;
	default:
		return -1;
	}

	for (mode++; *mode != '\0'; mode++) {
		switch (*mode) {
		case '+':
			break;
		case 'x':
			*failIfExists = true;
			break;
		default:
			return -1;
		}
	}

	return ret;
}

static int
ioErrToErrNo()
{
	switch (IoErr()) {
	case ERROR_OBJECT_IN_USE:
	case ERROR_DISK_NOT_VALIDATED:
		return EBUSY;
	case ERROR_OBJECT_NOT_FOUND:
		return ENOENT;
	case ERROR_DISK_WRITE_PROTECTED:
		return EROFS;
	case ERROR_WRITE_PROTECTED:
	case ERROR_READ_PROTECTED:
		return EACCES;
	default:
		return EIO;
	}
}
#else
static int
parseMode(const char *mode)
{
	int ret = 0;

	switch (*mode) {
	case 'r':
		ret |= O_RDONLY;
		break;
	case 'w':
		ret |= O_WRONLY | O_CREAT | O_TRUNC;
		break;
	case 'a':
		ret |= O_WRONLY | O_CREAT | O_APPEND;
		break;
	default:
		return -1;
	}

	for (mode++; *mode != '\0'; mode++) {
		switch (*mode) {
		case '+':
			ret &= ~(O_RDONLY | O_WRONLY);
			ret |= O_RDWR;
			break;
		case 'x':
			ret &= ~O_TRUNC;
			ret |= O_EXCL;
			break;
		default:
			return -1;
		}
	}

	return ret;
}
#endif

@implementation OFFile
+ (void)initialize
{
	if (self != [OFFile class])
		return;

#ifdef OF_WII
	if (!fatInitDefault())
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
#endif

#ifdef OF_NINTENDO_DS
	if (!nitroFSInit(NULL))
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
#endif

#ifdef OF_NINTENDO_SWITCH
	if (R_SUCCEEDED(romfsInit()))
		/*
		 * Errors are intentionally ignored, as it's possible we just
		 * have no romfs.
		 */
		atexit((void (*)(void))romfsExit);
#endif
}

+ (instancetype)fileWithPath: (OFString *)path mode: (OFString *)mode
{
	return objc_autoreleaseReturnValue([[self alloc] initWithPath: path
								 mode: mode]);
}

+ (instancetype)fileWithHandle: (OFFileHandle)handle
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithHandle: handle]);
}

- (instancetype)initWithPath: (OFString *)path mode: (OFString *)mode
{
	OFFileHandle handle;

	@try {
		void *pool = objc_autoreleasePoolPush();

#if defined(OF_WINDOWS)
		handle = OFAllocMemory(1, sizeof(*handle));
		@try {
			DWORD access, create;

			if (!parseMode(mode.UTF8String, &access, &create,
			    &handle->append))
				@throw [OFInvalidArgumentException exception];

			if ([OFSystemInfo isWindowsNT])
				handle->handle = CreateFileW(path.UTF16String,
				    access, FILE_SHARE_READ | FILE_SHARE_WRITE,
				    NULL, create, FILE_ATTRIBUTE_NORMAL, NULL);
			else
				handle->handle = CreateFileA([path
				    cStringWithEncoding: [OFLocale encoding]],
				    access, FILE_SHARE_READ | FILE_SHARE_WRITE,
				    NULL, create, FILE_ATTRIBUTE_NORMAL, NULL);

			if (handle->handle == INVALID_HANDLE_VALUE)
				@throw [OFOpenItemFailedException
				    exceptionWithPath: path
						 mode: mode
						errNo: errorToErrNo()];

			if (handle->append) {
				LONG high = 0;
				if (SetFilePointer(handle->handle, 0, &high,
				    FILE_END) == INVALID_SET_FILE_POINTER &&
				    GetLastError() != NO_ERROR) {
					CloseHandle(handle->handle);
					@throw [OFOpenItemFailedException
					    exceptionWithPath: path
							 mode: mode
							errNo: errorToErrNo()];
				}
			}
		} @catch (id e) {
			OFFreeMemory(handle);
			@throw e;
		}

#elif defined(OF_AMIGAOS)
		handle = OFAllocMemory(1, sizeof(*handle));
		@try {
			bool truncate, failIfExists;
			const char *pathCStr = [path cStringWithEncoding:
			    [OFLocale encoding]];

			int flags;
			if ((flags = parseMode(mode.UTF8String, &truncate,
			    &failIfExists, &handle->append)) == -1)
				@throw [OFInvalidArgumentException exception];

			if (failIfExists) {
				BPTR lock = Lock(pathCStr, SHARED_LOCK);

				if (lock != 0) {
					UnLock(lock);
					@throw [OFOpenItemFailedException
					    exceptionWithPath: path
							 mode: mode
							errNo: EEXIST];
				}
			}

			if ((handle->handle = Open(pathCStr, flags)) == 0)
				@throw [OFOpenItemFailedException
				    exceptionWithPath: path
						 mode: mode
						errNo: ioErrToErrNo()];

			if (truncate)
# ifdef OF_AMIGAOS4
				if (!ChangeFileSize(handle->handle, 0,
				    OFFSET_BEGINNING))
# else
				if (SetFileSize(handle->handle, 0,
				    OFFSET_BEGINNING) == -1)
# endif
					@throw [OFOpenItemFailedException
					    exceptionWithPath: path
							 mode: mode
							errNo: ioErrToErrNo()];

			if (handle->append) {
# if defined(OF_MORPHOS)
				if (Seek64(handle->handle, 0,
				    OFFSET_END) == -1) {
# elif defined(OF_AMIGAOS4)
				if (!ChangeFilePosition(handle->handle, 0,
				    OFFSET_END)) {
# else
				if (Seek(handle->handle, 0, OFFSET_END) == -1) {
# endif
					Close(handle->handle);
					@throw [OFOpenItemFailedException
					    exceptionWithPath: path
							 mode: mode
							errNo: ioErrToErrNo()];
				}
			}

			Forbid();

			handle->previous = NULL;
			handle->next = firstHandle;

			if (firstHandle != NULL)
				firstHandle->previous = handle;

			firstHandle = handle;

			Permit();
		} @catch (id e) {
			OFFreeMemory(handle);
			@throw e;
		}
#else
		int flags;
		if ((flags = parseMode(mode.UTF8String)) == -1)
			@throw [OFInvalidArgumentException exception];

		flags |= O_BINARY | O_CLOEXEC;

# ifdef HAVE_OPEN64
		handle = open64([path cStringWithEncoding: [OFLocale encoding]],
		    flags, 0666);
# else
		handle = open([path cStringWithEncoding: [OFLocale encoding]],
		    flags, 0666);
# endif

		if (handle == -1)
			@throw [OFOpenItemFailedException
			    exceptionWithPath: path
					 mode: mode
					errNo: errno];
#endif

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	@try {
		self = [self initWithHandle: handle];
	} @catch (id e) {
		closeHandle(handle);
		@throw e;
	}

	return self;
}

- (instancetype)initWithHandle: (OFFileHandle)handle
{
	self = [super init];

	_handle = handle;
	_initialized = true;

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (bool)lowlevelIsAtEndOfStream
{
	if (_handle == OFInvalidFileHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

	return _atEndOfStream;
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer length: (size_t)length
{
	if (_handle == OFInvalidFileHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

#if defined(OF_WINDOWS)
	if (length > MAXDWORD || length > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	DWORD ret;
	if (!ReadFile(_handle->handle, buffer, (DWORD)length, &ret, NULL))
		@throw [OFReadFailedException
		    exceptionWithObject: self
			requestedLength: length
				  errNo: errorToErrNo()];
#elif defined(OF_AMIGAOS)
	if (length > LONG_MAX)
		@throw [OFOutOfRangeException exception];

	ssize_t ret;
	if ((ret = Read(_handle->handle, buffer, length)) < 0)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length
							    errNo: EIO];
#else
	ssize_t ret;
	if ((ret = read(_handle, buffer, length)) < 0)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length
							    errNo: errno];
#endif

	if (ret == 0)
		_atEndOfStream = true;

	return ret;
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer length: (size_t)length
{
	if (_handle == OFInvalidFileHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

#if defined(OF_WINDOWS)
	if (length > MAXDWORD)
		@throw [OFOutOfRangeException exception];

	if (_handle->append) {
		LONG high = 0;
		if (SetFilePointer(_handle->handle, 0, &high, FILE_END) ==
		    INVALID_SET_FILE_POINTER && GetLastError() != NO_ERROR)
			@throw [OFWriteFailedException
			    exceptionWithObject: self
				requestedLength: length
				   bytesWritten: 0
					  errNo: errorToErrNo()];
	}

	DWORD bytesWritten;
	if (!WriteFile(_handle->handle, buffer, (DWORD)length, &bytesWritten,
	    NULL)) {
		if (bytesWritten == 0)
			@throw [OFWriteFailedException
			    exceptionWithObject: self
				requestedLength: length
				   bytesWritten: 0
					  errNo: errorToErrNo()];
	}
#elif defined(OF_AMIGAOS)
	if (length > LONG_MAX)
		@throw [OFOutOfRangeException exception];

	if (_handle->append) {
# if defined(OF_MORPHOS)
		if (Seek64(_handle->handle, 0, OFFSET_END) == -1)
# elif defined(OF_AMIGAOS4)
		if (ChangeFilePosition(_handle->handle, 0, OFFSET_END) == -1)
# else
		if (Seek(_handle->handle, 0, OFFSET_END) == -1)
# endif
			@throw [OFWriteFailedException
			    exceptionWithObject: self
				requestedLength: length
				   bytesWritten: 0
					  errNo: ioErrToErrNo()];
	}

	LONG bytesWritten;
	if ((bytesWritten = Write(_handle->handle, (void *)buffer, length)) < 0)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
						      bytesWritten: 0
							     errNo: EIO];
#else
	ssize_t bytesWritten;

	if (length > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	if ((bytesWritten = write(_handle, buffer, length)) < 0)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
						      bytesWritten: 0
							     errNo: errno];
#endif

	return (size_t)bytesWritten;
}

- (OFStreamOffset)lowlevelSeekToOffset: (OFStreamOffset)offset
				whence: (OFSeekWhence)whence
{
	OFStreamOffset ret;

	if (_handle == OFInvalidFileHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

#if defined(OF_WINDOWS)
	DWORD translatedWhence;
	switch (whence) {
	case OFSeekSet:
		translatedWhence = FILE_BEGIN;
		break;
	case OFSeekCurrent:
		translatedWhence = FILE_CURRENT;
		break;
	case OFSeekEnd:
		translatedWhence = FILE_END;
		break;
	default:
		@throw [OFSeekFailedException exceptionWithStream: self
							   offset: offset
							   whence: whence
							    errNo: EINVAL];
	}

	union {
		OFStreamOffset offset;
		struct {
			LONG low, high;
		} pair;
	} u;
	OFZeroMemory(&u, sizeof(u));
	u.offset = offset;

	u.pair.low = SetFilePointer(_handle->handle, u.pair.low, &u.pair.high,
	    translatedWhence);
	if (u.pair.low == (LONG)INVALID_SET_FILE_POINTER &&
	    GetLastError() != NO_ERROR)
		@throw [OFSeekFailedException
		    exceptionWithStream: self
				 offset: offset
				 whence: whence
				  errNo: errorToErrNo()];

	ret = u.offset;
#elif defined(OF_AMIGAOS)
	LONG translatedWhence;
	switch (whence) {
	case OFSeekSet:
		translatedWhence = OFFSET_BEGINNING;
		break;
	case OFSeekCurrent:
		translatedWhence = OFFSET_CURRENT;
		break;
	case OFSeekEnd:
		translatedWhence = OFFSET_END;
		break;
	default:
		@throw [OFSeekFailedException exceptionWithStream: self
							   offset: offset
							   whence: whence
							    errNo: EINVAL];
	}

# if defined(OF_MORPHOS)
	if ((ret = Seek64(_handle->handle, offset, translatedWhence)) == -1)
# elif defined(OF_AMIGAOS4)
	if ((ret = ChangeFilePosition(_handle->handle, offset,
	    translatedWhence)) == -1)
# else
	if ((ret = Seek(_handle->handle, offset, translatedWhence)) == -1)
# endif
		@throw [OFSeekFailedException exceptionWithStream: self
							   offset: offset
							   whence: whence
							    errNo: EINVAL];
#else
	int translatedWhence;
	switch (whence) {
	case OFSeekSet:
		translatedWhence = SEEK_SET;
		break;
	case OFSeekCurrent:
		translatedWhence = SEEK_CUR;
		break;
	case OFSeekEnd:
		translatedWhence = SEEK_END;
		break;
	default:
		@throw [OFSeekFailedException exceptionWithStream: self
							   offset: offset
							   whence: whence
							    errNo: EINVAL];
	}

# if defined(HAVE_LSEEK64)
	ret = lseek64(_handle, offset, translatedWhence);
# else
	ret = lseek(_handle, offset, translatedWhence);
# endif

	if (ret == -1)
		@throw [OFSeekFailedException exceptionWithStream: self
							   offset: offset
							   whence: whence
							    errNo: errno];
#endif

	_atEndOfStream = false;

	return ret;
}

#ifdef OF_FILE_HANDLE_IS_FD
- (int)fileDescriptorForReading
{
	return _handle;
}

- (int)fileDescriptorForWriting
{
	return _handle;
}
#endif

- (void)close
{
	if (_handle == OFInvalidFileHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

	closeHandle(_handle);
	_handle = OFInvalidFileHandle;

	[super close];
}

- (void)dealloc
{
	if (_initialized && _handle != OFInvalidFileHandle)
		[self close];

	[super dealloc];
}
@end
