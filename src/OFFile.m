/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#include "config.h"

#include <errno.h>

#ifdef HAVE_FCNTL_H
# include <fcntl.h>
#endif
#include "unistd_wrapper.h"

#import "OFFile.h"
#import "OFString.h"
#import "OFLocalization.h"

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFOpenItemFailedException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFSeekFailedException.h"
#import "OFWriteFailedException.h"

#ifdef OF_WINDOWS
# include <windows.h>
#endif

#if defined(OF_MORPHOS) && !defined(OF_IXEMUL)
# define BOOL EXEC_BOOL
# include <proto/dos.h>
# undef BOOL
#endif

#ifdef OF_WII
# define BOOL OGC_BOOL
# include <fat.h>
# undef BOOL
#endif

#ifdef OF_NINTENDO_DS
# include <stdbool.h>
# include <filesystem.h>
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

#ifndef S_IRGRP
# define S_IRGRP 0
#endif
#ifndef S_IROTH
# define S_IROTH 0
#endif
#ifndef S_IWGRP
# define S_IWGRP 0
#endif
#ifndef S_IWOTH
# define S_IWOTH 0
#endif

#define DEFAULT_MODE S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH

#if !defined(OF_MORPHOS) || defined(OF_IXEMUL)
static int
parseMode(const char *mode)
{
	if (strcmp(mode, "r") == 0)
		return O_RDONLY;
	if (strcmp(mode, "w") == 0)
		return O_WRONLY | O_CREAT | O_TRUNC;
	if (strcmp(mode, "wx") == 0)
		return O_WRONLY | O_CREAT | O_EXCL | O_EXLOCK;
	if (strcmp(mode, "a") == 0)
		return O_WRONLY | O_CREAT | O_APPEND;
	if (strcmp(mode, "rb") == 0)
		return O_RDONLY | O_BINARY;
	if (strcmp(mode, "wb") == 0)
		return O_WRONLY | O_CREAT | O_TRUNC | O_BINARY;
	if (strcmp(mode, "wbx") == 0)
		return O_WRONLY | O_CREAT | O_EXCL | O_EXLOCK;
	if (strcmp(mode, "ab") == 0)
		return O_WRONLY | O_CREAT | O_APPEND | O_BINARY;
	if (strcmp(mode, "r+") == 0)
		return O_RDWR;
	if (strcmp(mode, "w+") == 0)
		return O_RDWR | O_CREAT | O_TRUNC;
	if (strcmp(mode, "a+") == 0)
		return O_RDWR | O_CREAT | O_APPEND;
	if (strcmp(mode, "r+b") == 0 || strcmp(mode, "rb+") == 0)
		return O_RDWR | O_BINARY;
	if (strcmp(mode, "w+b") == 0 || strcmp(mode, "wb+") == 0)
		return O_RDWR | O_CREAT | O_TRUNC | O_BINARY;
	if (strcmp(mode, "w+bx") == 0 || strcmp(mode, "wb+x") == 0)
		return O_RDWR | O_CREAT | O_EXCL | O_EXLOCK;
	if (strcmp(mode, "ab+") == 0 || strcmp(mode, "a+b") == 0)
		return O_RDWR | O_CREAT | O_APPEND | O_BINARY;

	return -1;
}
#else
static int
parseMode(const char *mode, bool *append)
{
	if (strcmp(mode, "r") == 0)
		return MODE_OLDFILE;
	if (strcmp(mode, "w") == 0)
		return MODE_NEWFILE;
	if (strcmp(mode, "wx") == 0)
		return MODE_NEWFILE;
	if (strcmp(mode, "a") == 0) {
		*append = true;
		return MODE_READWRITE;
	}
	if (strcmp(mode, "rb") == 0)
		return MODE_OLDFILE;
	if (strcmp(mode, "wb") == 0)
		return MODE_NEWFILE;
	if (strcmp(mode, "wbx") == 0)
		return MODE_NEWFILE;
	if (strcmp(mode, "ab") == 0) {
		*append = true;
		return MODE_READWRITE;
	}
	if (strcmp(mode, "r+") == 0)
		return MODE_OLDFILE;
	if (strcmp(mode, "w+") == 0)
		return MODE_NEWFILE;
	if (strcmp(mode, "a+") == 0) {
		*append = true;
		return MODE_READWRITE;
	}
	if (strcmp(mode, "r+b") == 0 || strcmp(mode, "rb+") == 0)
		return MODE_OLDFILE;
	if (strcmp(mode, "w+b") == 0 || strcmp(mode, "wb+") == 0)
		return MODE_NEWFILE;
	if (strcmp(mode, "w+bx") == 0 || strcmp(mode, "wb+x") == 0)
		return MODE_NEWFILE;
	if (strcmp(mode, "ab+") == 0 || strcmp(mode, "a+b") == 0) {
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
}

+ (instancetype)fileWithPath: (OFString *)path
			mode: (OFString *)mode
{
	return [[[self alloc] initWithPath: path
				      mode: mode] autorelease];
}

#if !defined(OF_MORPHOS) || defined(OF_IXEMUL)
+ (instancetype)fileWithFileDescriptor: (int)fd
{
	return [[[self alloc] initWithFileDescriptor: fd] autorelease];
}
#else
+ (instancetype)fileWithHandle: (BPTR)handle
{
	return [[[self alloc] initWithHandle: handle] autorelease];
}
#endif

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithPath: (OFString *)path
	  mode: (OFString *)mode
{
	self = [super init];

	@try {
		int flags;

#if !defined(OF_MORPHOS) || defined(OF_IXEMUL)
		if ((flags = parseMode([mode UTF8String])) == -1)
			@throw [OFInvalidArgumentException exception];

		flags |= O_CLOEXEC;

# if defined(OF_WINDOWS)
		if ((_fd = _wopen([path UTF16String], flags,
		    DEFAULT_MODE)) == -1)
# elif defined(OF_HAVE_OFF64_T)
		if ((_fd = open64([path cStringWithEncoding:
		    [OFLocalization encoding]], flags, DEFAULT_MODE)) == -1)
# else
		if ((_fd = open([path cStringWithEncoding:
		    [OFLocalization encoding]], flags, DEFAULT_MODE)) == -1)
# endif
			@throw [OFOpenItemFailedException
			    exceptionWithPath: path
					 mode: mode
					errNo: errno];
#else
		if ((flags = parseMode([mode UTF8String], &_append)) == -1)
			@throw [OFInvalidArgumentException exception];

		if ((_handle = Open([path cStringWithEncoding:
		    [OFLocalization encoding]], flags)) == 0)
			@throw [OFOpenItemFailedException
			    exceptionWithPath: path
					 mode: mode];

		if (_append) {
			if (Seek64(_handle, 0, OFFSET_END) == -1)
				@throw [OFOpenItemFailedException
				    exceptionWithPath: path
						 mode: mode];
		}
#endif
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

#if !defined(OF_MORPHOS) || defined(OF_IXEMUL)
- initWithFileDescriptor: (int)fd
{
	self = [super init];

	_fd = fd;

	return self;
}
#else
- initWithHandle: (BPTR)handle
{
	self = [super init];

	_handle = handle;

	return self;
}
#endif

- (bool)lowlevelIsAtEndOfStream
{
#if !defined(OF_MORPHOS) || defined(OF_IXEMUL)
	if (_fd == -1)
		return true;
#else
	if (_handle == 0)
		return true;
#endif

	return _atEndOfStream;
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer
			  length: (size_t)length
{
	ssize_t ret;

#if !defined(OF_MORPHOS) || defined(OF_IXEMUL)
	if (_fd == -1 || _atEndOfStream)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length];

# ifndef OF_WINDOWS
	if ((ret = read(_fd, buffer, length)) < 0)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length
							    errNo: errno];
# else
	if (length > UINT_MAX)
		@throw [OFOutOfRangeException exception];

	if ((ret = read(_fd, buffer, (unsigned int)length)) < 0)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length
							    errNo: errno];
# endif
#else
	if (_handle == 0 || _atEndOfStream)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length];

	if (length > LONG_MAX)
		@throw [OFOutOfRangeException exception];

	if ((ret = Read(_handle, buffer, length)) < 0)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length];
#endif

	if (ret == 0)
		_atEndOfStream = true;

	return ret;
}

- (void)lowlevelWriteBuffer: (const void *)buffer
		     length: (size_t)length
{
#if !defined(OF_MORPHOS) || defined(OF_IXEMUL)
	if (_fd == -1 || _atEndOfStream)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length];
# ifndef OF_WINDOWS
	if (length > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	if (write(_fd, buffer, length) != (ssize_t)length)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
							     errNo: errno];
# else
	if (length > INT_MAX)
		@throw [OFOutOfRangeException exception];

	if (write(_fd, buffer, (int)length) != (int)length)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
							     errNo: errno];
# endif
#else
	if (_handle == 0 || _atEndOfStream)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length];
	if (length > LONG_MAX)
		@throw [OFOutOfRangeException exception];

	if (_append) {
		if (Seek64(_handle, 0, OFFSET_END) == -1)
			@throw [OFWriteFailedException
			    exceptionWithObject: self
				requestedLength: length];
	}

	if (Write(_handle, (void *)buffer, length) != (LONG)length)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length];
#endif
}

- (of_offset_t)lowlevelSeekToOffset: (of_offset_t)offset
			     whence: (int)whence
{
	of_offset_t ret;

#if !defined(OF_MORPHOS) || defined(OF_IXEMUL)
	if (_fd == -1)
		@throw [OFSeekFailedException exceptionWithStream: self
							   offset: offset
							   whence: whence];

# if defined(OF_WINDOWS)
	ret = _lseeki64(_fd, offset, whence);
# elif defined(OF_HAVE_OFF64_T)
	ret = lseek64(_fd, offset, whence);
# else
	ret = lseek(_fd, offset, whence);
# endif

	if (ret == -1)
		@throw [OFSeekFailedException exceptionWithStream: self
							   offset: offset
							   whence: whence
							    errNo: errno];
#else
	if (_handle == 0)
		@throw [OFSeekFailedException exceptionWithStream: self
							   offset: offset
							   whence: whence];

	switch (whence) {
	case SEEK_SET:
		ret = Seek64(_handle, offset, OFFSET_BEGINNING);
		break;
	case SEEK_CUR:
		ret = Seek64(_handle, offset, OFFSET_CURRENT);
		break;
	case SEEK_END:
		ret = Seek64(_handle, offset, OFFSET_END);
		break;
	default:
		ret = -1;
		break;
	}

	if (ret == -1)
		@throw [OFSeekFailedException exceptionWithStream: self
							   offset: offset
							   whence: whence];
#endif

	_atEndOfStream = false;

	return ret;
}

#if !defined(OF_WINDOWS) && (!defined(OF_MORPHOS) || defined(OF_IXEMUL))
- (int)fileDescriptorForReading
{
	return _fd;
}

- (int)fileDescriptorForWriting
{
	return _fd;
}
#endif

- (void)close
{
#if !defined(OF_MORPHOS) || defined(OF_IXEMUL)
	if (_fd != -1)
		close(_fd);

	_fd = -1;
#else
	if (_handle != 0)
		Close(_handle);

	_handle = 0;
#endif

	[super close];
}

- (void)dealloc
{
	[self close];

	[super dealloc];
}
@end
