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

#ifndef OF_AMIGAOS
# define closeHandle(h) close(h)
#else
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
#endif

#ifndef OF_AMIGAOS
static int
parseMode(const char *mode)
{
	if (strcmp(mode, "r") == 0)
		return O_RDONLY;
	if (strcmp(mode, "r+") == 0)
		return O_RDWR;
	if (strcmp(mode, "w") == 0)
		return O_WRONLY | O_CREAT | O_TRUNC;
	if (strcmp(mode, "wx") == 0)
		return O_WRONLY | O_CREAT | O_EXCL | O_EXLOCK;
	if (strcmp(mode, "w+") == 0)
		return O_RDWR | O_CREAT | O_TRUNC;
	if (strcmp(mode, "w+x") == 0)
		return O_RDWR | O_CREAT | O_EXCL | O_EXLOCK;
	if (strcmp(mode, "a") == 0)
		return O_WRONLY | O_CREAT | O_APPEND;
	if (strcmp(mode, "a+") == 0)
		return O_RDWR | O_CREAT | O_APPEND;

	return -1;
}
#else
static int
parseMode(const char *mode, bool *append)
{
	*append = false;

	if (strcmp(mode, "r") == 0)
		return MODE_OLDFILE;
	if (strcmp(mode, "r+") == 0)
		return MODE_OLDFILE;
	if (strcmp(mode, "w") == 0)
		return MODE_NEWFILE;
	if (strcmp(mode, "wx") == 0)
		return MODE_NEWFILE;
	if (strcmp(mode, "w+") == 0)
		return MODE_NEWFILE;
	if (strcmp(mode, "w+x") == 0)
		return MODE_NEWFILE;
	if (strcmp(mode, "a") == 0) {
		*append = true;
		return MODE_READWRITE;
	}
	if (strcmp(mode, "a+") == 0) {
		*append = true;
		return MODE_READWRITE;
	}

	return -1;
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
	return [[[self alloc] initWithPath: path mode: mode] autorelease];
}

+ (instancetype)fileWithHandle: (OFFileHandle)handle
{
	return [[[self alloc] initWithHandle: handle] autorelease];
}

- (instancetype)initWithPath: (OFString *)path mode: (OFString *)mode
{
	OFFileHandle handle;

	@try {
		void *pool = objc_autoreleasePoolPush();
		int flags;

#ifndef OF_AMIGAOS
		if ((flags = parseMode(mode.UTF8String)) == -1)
			@throw [OFInvalidArgumentException exception];

		flags |= O_BINARY | O_CLOEXEC;

# ifdef OF_WINDOWS
		if ([OFSystemInfo isWindowsNT])
			handle = _wopen(path.UTF16String, flags,
			    _S_IREAD | _S_IWRITE);
		else
# endif
# ifdef HAVE_OPEN64
			handle = open64(
			    [path cStringWithEncoding: [OFLocale encoding]],
			    flags, 0666);
# else
			handle = open(
			    [path cStringWithEncoding: [OFLocale encoding]],
			    flags, 0666);
# endif

		if (handle == -1)
			@throw [OFOpenItemFailedException
			    exceptionWithPath: path
					 mode: mode
					errNo: errno];
#else
		handle = OFAllocMemory(1, sizeof(*handle));
		@try {
			if ((flags = parseMode(mode.UTF8String,
			    &handle->append)) == -1)
				@throw [OFInvalidArgumentException exception];

			if ((handle->handle = Open([path cStringWithEncoding:
			    [OFLocale encoding]], flags)) == 0) {
				int errNo;

				switch (IoErr()) {
				case ERROR_OBJECT_IN_USE:
				case ERROR_DISK_NOT_VALIDATED:
					errNo = EBUSY;
					break;
				case ERROR_OBJECT_NOT_FOUND:
					errNo = ENOENT;
					break;
				case ERROR_DISK_WRITE_PROTECTED:
					errNo = EROFS;
					break;
				case ERROR_WRITE_PROTECTED:
				case ERROR_READ_PROTECTED:
					errNo = EACCES;
					break;
				default:
					errNo = 0;
					break;
				}

				@throw [OFOpenItemFailedException
				    exceptionWithPath: path
						 mode: mode
						errNo: errNo];
			}

			if (handle->append) {
# if defined(OF_MORPHOS)
				if (Seek64(handle->handle, 0,
				    OFFSET_END) == -1) {
# elif defined(OF_AMIGAOS4)
				if (ChangeFilePosition(handle->handle, 0,
				    OFFSET_END) == -1) {
# else
				if (Seek(handle->handle, 0, OFFSET_END) == -1) {
# endif
					Close(handle->handle);
					@throw [OFOpenItemFailedException
					    exceptionWithPath: path
							 mode: mode
							errNo: EIO];
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
#endif

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
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
	ssize_t ret;

	if (_handle == OFInvalidFileHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

#if defined(OF_WINDOWS)
	if (length > UINT_MAX)
		@throw [OFOutOfRangeException exception];

	if ((ret = read(_handle, buffer, (unsigned int)length)) < 0)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length
							    errNo: errno];
#elif defined(OF_AMIGAOS)
	if (length > LONG_MAX)
		@throw [OFOutOfRangeException exception];

	if ((ret = Read(_handle->handle, buffer, length)) < 0)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length
							    errNo: EIO];
#else
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
	int bytesWritten;

	if (length > INT_MAX)
		@throw [OFOutOfRangeException exception];

	if ((bytesWritten = write(_handle, buffer, (int)length)) < 0)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
						      bytesWritten: 0
							     errNo: errno];
#elif defined(OF_AMIGAOS)
	LONG bytesWritten;

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
					  errNo: EIO];
	}

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

#ifndef OF_AMIGAOS
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
# if defined(OF_WINDOWS)
	ret = _lseeki64(_handle, offset, translatedWhence);
# elif defined(HAVE_LSEEK64)
	ret = lseek64(_handle, offset, translatedWhence);
# else
	ret = lseek(_handle, offset, translatedWhence);
# endif

	if (ret == -1)
		@throw [OFSeekFailedException exceptionWithStream: self
							   offset: offset
							   whence: whence
							    errNo: errno];
#else
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
	if ((ret = Seek64(_handle->handle, offset, translatedWhence)) == 1)
# elif defined(OF_AMIGAOS4)
	if ((ret = ChangeFilePosition(_handle->handle, offset,
	    translatedWhence)) == 1)
# else
	if ((ret = Seek(_handle->handle, offset, translatedWhence)) == 1)
# endif
		@throw [OFSeekFailedException exceptionWithStream: self
							   offset: offset
							   whence: whence
							    errNo: EINVAL];
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
