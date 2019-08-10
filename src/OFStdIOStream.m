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

#include "config.h"

#include <errno.h>

#include "unistd_wrapper.h"

#ifdef HAVE_SYS_IOCTL_H
# include <sys/ioctl.h>
#endif
#ifdef HAVE_SYS_TTYCOM_H
# include <sys/ttycom.h>
#endif

#import "OFStdIOStream.h"
#import "OFStdIOStream+Private.h"
#import "OFDate.h"
#import "OFApplication.h"
#ifdef OF_WINDOWS
# include "OFWin32ConsoleStdIOStream.h"
#endif

#import "OFInitializationFailedException.h"
#import "OFNotOpenException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFWriteFailedException.h"

#ifdef OF_AMIGAOS
# include <proto/exec.h>
# include <proto/dos.h>
#endif

/* References for static linking */
#ifdef OF_WINDOWS
void
_reference_to_OFWin32ConsoleStdIOStream(void)
{
	[OFWin32ConsoleStdIOStream class];
}
#endif

OFStdIOStream *of_stdin = nil;
OFStdIOStream *of_stdout = nil;
OFStdIOStream *of_stderr = nil;

#ifdef OF_AMIGAOS
OF_DESTRUCTOR()
{
	[of_stdin dealloc];
	[of_stdout dealloc];
	[of_stderr dealloc];
}
#endif

void
of_log(OFConstantString *format, ...)
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *date;
	OFString *dateString, *me, *msg;
	va_list arguments;

	date = [OFDate date];
	dateString = [date localDateStringWithFormat: @"%Y-%m-%d %H:%M:%S"];
#ifdef OF_HAVE_FILES
	me = [OFApplication programName].lastPathComponent;
#else
	me = [OFApplication programName];
#endif

	va_start(arguments, format);
	msg = [[[OFString alloc] initWithFormat: format
				      arguments: arguments] autorelease];
	va_end(arguments);

	[of_stderr writeFormat: @"[%@.%03d %@(%d)] %@\n", dateString,
				date.microsecond / 1000, me, getpid(), msg];

	objc_autoreleasePoolPop(pool);
}

@implementation OFStdIOStream
#ifndef OF_WINDOWS
+ (void)load
{
	if (self != [OFStdIOStream class])
		return;

# ifndef OF_AMIGAOS
	int fd;

	if ((fd = fileno(stdin)) >= 0)
		of_stdin = [[OFStdIOStream alloc]
		    of_initWithFileDescriptor: fd];
	if ((fd = fileno(stdout)) >= 0)
		of_stdout = [[OFStdIOStream alloc]
		    of_initWithFileDescriptor: fd];
	if ((fd = fileno(stderr)) >= 0)
		of_stderr = [[OFStdIOStream alloc]
		    of_initWithFileDescriptor: fd];
# else
	BPTR input, output, error;
	bool inputClosable = false, outputClosable = false,
	    errorClosable = false;

	input = Input();
	output = Output();
	error = ((struct Process *)FindTask(NULL))->pr_CES;

	if (input == 0) {
		input = Open("*", MODE_OLDFILE);
		inputClosable = true;
	}

	if (output == 0) {
		output = Open("*", MODE_OLDFILE);
		outputClosable = true;
	}

	if (error == 0) {
		error = Open("*", MODE_OLDFILE);
		errorClosable = true;
	}

	of_stdin = [[OFStdIOStream alloc] of_initWithHandle: input
						   closable: inputClosable];
	of_stdout = [[OFStdIOStream alloc] of_initWithHandle: output
						    closable: outputClosable];
	of_stderr = [[OFStdIOStream alloc] of_initWithHandle: error
						    closable: errorClosable];
# endif
}
#endif

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

#ifndef OF_AMIGAOS
- (instancetype)of_initWithFileDescriptor: (int)fd
{
	self = [super init];

	_fd = fd;

	return self;
}
#else
- (instancetype)of_initWithHandle: (BPTR)handle
			 closable: (bool)closable
{
	self = [super init];

	_handle = handle;
	_closable = closable;

	return self;
}
#endif

- (void)dealloc
{
	[self close];

	[super dealloc];
}

- (bool)lowlevelIsAtEndOfStream
{
#ifndef OF_AMIGAOS
	if (_fd == -1)
#else
	if (_handle == 0)
#endif
		@throw [OFNotOpenException exceptionWithObject: self];

	return _atEndOfStream;
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer
			  length: (size_t)length
{
	ssize_t ret;

#ifndef OF_AMIGAOS
	if (_fd == -1)
		@throw [OFNotOpenException exceptionWithObject: self];

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
	if (_handle == 0)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (length > LONG_MAX)
		@throw [OFOutOfRangeException exception];

	if ((ret = Read(_handle, buffer, length)) < 0)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length
							    errNo: EIO];
#endif

	if (ret == 0)
		_atEndOfStream = true;

	return ret;
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer
		       length: (size_t)length
{
#ifndef OF_AMIGAOS
	if (_fd == -1)
		@throw [OFNotOpenException exceptionWithObject: self];

# ifndef OF_WINDOWS
	ssize_t bytesWritten;

	if (length > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	if ((bytesWritten = write(_fd, buffer, length)) < 0)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
						      bytesWritten: 0
							     errNo: errno];
# else
	int bytesWritten;

	if (length > INT_MAX)
		@throw [OFOutOfRangeException exception];

	if ((bytesWritten = write(_fd, buffer, (int)length)) < 0)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
						      bytesWritten: 0
							     errNo: errno];
# endif
#else
	LONG bytesWritten;

	if (_handle == 0)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (length > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	if ((bytesWritten = Write(_handle, (void *)buffer, length)) < 0)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
						      bytesWritten: 0
							     errNo: EIO];
#endif

	return (size_t)bytesWritten;
}

#if !defined(OF_WINDOWS) && !defined(OF_AMIGAOS)
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
#ifndef OF_AMIGAOS
	if (_fd != -1)
		close(_fd);

	_fd = -1;
#else
	if (_closable && _handle != 0)
		Close(_handle);

	_handle = 0;
#endif

	[super close];
}

- (instancetype)autorelease
{
	return self;
}

- (instancetype)retain
{
	return self;
}

- (void)release
{
}

- (unsigned int)retainCount
{
	return OF_RETAIN_COUNT_MAX;
}

- (int)columns
{
#if defined(HAVE_SYS_IOCTL_H) && defined(TIOCGWINSZ) && !defined(OF_AMIGAOS)
	struct winsize ws;

	if (ioctl(_fd, TIOCGWINSZ, &ws) != 0)
		return -1;

	return ws.ws_col;
#else
	return -1;
#endif
}

- (int)rows
{
#if defined(HAVE_SYS_IOCTL_H) && defined(TIOCGWINSZ) && !defined(OF_AMIGAOS)
	struct winsize ws;

	if (ioctl(_fd, TIOCGWINSZ, &ws) != 0)
		return -1;

	return ws.ws_row;
#else
	return -1;
#endif
}
@end
