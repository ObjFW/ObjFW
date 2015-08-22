/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
 *   Jonathan Schleifer <js@webkeks.org>
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

#include <fcntl.h>
#include <unistd.h>

#ifdef __wii__
# define BOOL OGC_BOOL
# include <fat.h>
# undef BOOL
#endif

#ifdef OF_NINTENDO_DS
# include <filesystem.h>
#endif

#import "OFFile.h"
#import "OFString.h"
#import "OFSystemInfo.h"

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFOpenItemFailedException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFSeekFailedException.h"
#import "OFWriteFailedException.h"

#ifdef _WIN32
# include <windows.h>
#endif

#ifndef O_BINARY
# define O_BINARY 0
#endif
#ifndef O_CLOEXEC
# define O_CLOEXEC 0
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

@implementation OFFile
+ (void)initialize
{
	if (self != [OFFile class])
		return;

#ifdef __wii__
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

+ (instancetype)fileWithPath: (OFString*)path
			mode: (OFString*)mode
{
	return [[[self alloc] initWithPath: path
				      mode: mode] autorelease];
}

+ (instancetype)fileWithFileDescriptor: (int)filedescriptor
{
	return [[[self alloc]
	    initWithFileDescriptor: filedescriptor] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithPath: (OFString*)path
	  mode: (OFString*)mode
{
	self = [super init];

	@try {
		int flags;

		if ((flags = parseMode([mode UTF8String])) == -1)
			@throw [OFInvalidArgumentException exception];

		flags |= O_CLOEXEC;

#if defined(_WIN32)
		if ((_fd = _wopen([path UTF16String], flags,
		    DEFAULT_MODE)) == -1)
#elif defined(OF_HAVE_OFF64_T)
		if ((_fd = open64([path cStringWithEncoding: [OFSystemInfo
		    native8BitEncoding]], flags, DEFAULT_MODE)) == -1)
#else
		if ((_fd = open([path cStringWithEncoding: [OFSystemInfo
		    native8BitEncoding]], flags, DEFAULT_MODE)) == -1)
#endif
			@throw [OFOpenItemFailedException
			    exceptionWithPath: path
					 mode: mode
					errNo: errno];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithFileDescriptor: (int)fd
{
	self = [super init];

	_fd = fd;

	return self;
}

- (bool)lowlevelIsAtEndOfStream
{
	if (_fd == -1)
		return true;

	return _atEndOfStream;
}

- (size_t)lowlevelReadIntoBuffer: (void*)buffer
			  length: (size_t)length
{
	ssize_t ret;

	if (_fd == -1 || _atEndOfStream)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length];

#ifndef _WIN32
	if ((ret = read(_fd, buffer, length)) < 0)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length
							    errNo: errno];
#else
	if (length > UINT_MAX)
		@throw [OFOutOfRangeException exception];

	if ((ret = read(_fd, buffer, (unsigned int)length)) < 0)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length
							    errNo: errno];
#endif

	if (ret == 0)
		_atEndOfStream = true;

	return ret;
}

- (void)lowlevelWriteBuffer: (const void*)buffer
		     length: (size_t)length
{
	if (_fd == -1 || _atEndOfStream)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length];

#ifndef _WIN32
	if (write(_fd, buffer, length) < length)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
							     errNo: errno];
#else
	if (length > UINT_MAX)
		@throw [OFOutOfRangeException exception];

	if (write(_fd, buffer, (unsigned int)length) < length)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
							     errNo: errno];
#endif
}

- (of_offset_t)lowlevelSeekToOffset: (of_offset_t)offset
			     whence: (int)whence
{
#if defined(_WIN32)
	of_offset_t ret = _lseeki64(_fd, offset, whence);
#elif defined(OF_HAVE_OFF64_T)
	of_offset_t ret = lseek64(_fd, offset, whence);
#else
	of_offset_t ret = lseek(_fd, offset, whence);
#endif

	if (ret == -1)
		@throw [OFSeekFailedException exceptionWithStream: self
							   offset: offset
							   whence: whence
							    errNo: errno];

	_atEndOfStream = false;

	return ret;
}

- (int)fileDescriptorForReading
{
	return _fd;
}

- (int)fileDescriptorForWriting
{
	return _fd;
}

- (void)close
{
	if (_fd != -1)
		close(_fd);

	_fd = -1;
}

- (void)dealloc
{
	if (_fd != -1)
		close(_fd);

	[super dealloc];
}
@end
