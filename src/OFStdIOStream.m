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
# include "OFStdIOStream_Win32Console.h"
#endif

#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFWriteFailedException.h"

#if defined(OF_MORPHOS) && !defined(OF_IXEMUL)
# define BOOL EXEC_BOOL
# include <exec/execbase.h>
# include <proto/dos.h>
# undef BOOL

# define INVALID_FD 0
# define getpid() ((int)SysBase->ThisTask)
# define read(fd, buf, len) Read(fd, buf, len)
# define write(fd, buf, len) Write(fd, buf, len)

extern struct ExecBase *SysBase;
#endif

#ifndef INVALID_FD
# define INVALID_FD -1
#endif

/* References for static linking */
#ifdef OF_WINDOWS
void
_reference_to_OFStdIOStream_Win32Console(void)
{
	[OFStdIOStream_Win32Console class];
}
#endif

OFStdIOStream *of_stdin = nil;
OFStdIOStream *of_stdout = nil;
OFStdIOStream *of_stderr = nil;

#if defined(OF_MORPHOS) && !defined(OF_IXEMUL)
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
	me = [[OFApplication programName] lastPathComponent];

	va_start(arguments, format);
	msg = [[[OFString alloc] initWithFormat: format
				      arguments: arguments] autorelease];
	va_end(arguments);

	[of_stderr writeFormat: @"[%@.%03d %@(%d)] %@\n", dateString,
				[date microsecond] / 1000, me, getpid(), msg];

	objc_autoreleasePoolPop(pool);
}

@implementation OFStdIOStream
#ifndef OF_WINDOWS
+ (void)load
{
# if !defined(OF_MORPHOS) || defined(OF_IXEMUL)
	of_stdin = [[OFStdIOStream alloc] of_initWithFileDescriptor: 0];
	of_stdout = [[OFStdIOStream alloc] of_initWithFileDescriptor: 1];
	of_stderr = [[OFStdIOStream alloc] of_initWithFileDescriptor: 2];
# else
	BPTR input = Input(), output = Output();
	BPTR error = ((struct Process *)SysBase->ThisTask)->pr_CES;
	bool inputClosable = false, outputClosable = false,
	    errorClosable = false;

	if (input == INVALID_FD) {
		input = Open("*", MODE_OLDFILE);
		inputClosable = true;
	}

	if (output == INVALID_FD) {
		output = Open("*", MODE_OLDFILE);
		outputClosable = true;
	}

	if (error == INVALID_FD) {
		error = Open("*", MODE_OLDFILE);
		errorClosable = true;
	}

	of_stdin = [[OFStdIOStream alloc]
	    of_initWithFileDescriptor: input
			     closable: inputClosable];
	of_stdout = [[OFStdIOStream alloc]
	    of_initWithFileDescriptor: output
			     closable: outputClosable];
	of_stderr = [[OFStdIOStream alloc]
	    of_initWithFileDescriptor: error
			     closable: errorClosable];
# endif
}
#endif

- init
{
	OF_INVALID_INIT_METHOD
}

#if !defined(OF_MORPHOS) || defined(OF_IXEMUL)
- (instancetype)of_initWithFileDescriptor: (int)fd
{
	self = [super init];

	_fd = fd;

	return self;
}
#else
- (instancetype)of_initWithFileDescriptor: (long)fd
				 closable: (bool)closable
{
	self = [super init];

	_fd = fd;
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
	if (_fd == INVALID_FD)
		return true;

	return _atEndOfStream;
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer
			  length: (size_t)length
{
	ssize_t ret;

	if (_fd == INVALID_FD || _atEndOfStream)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length];

#ifndef OF_WINDOWS
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

- (void)lowlevelWriteBuffer: (const void *)buffer
		     length: (size_t)length
{
	if (_fd == INVALID_FD || _atEndOfStream)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length];

#ifndef OF_WINDOWS
	if (length > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	if (write(_fd, (void *)buffer, length) != (ssize_t)length)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
							     errNo: errno];
#else
	if (length > INT_MAX)
		@throw [OFOutOfRangeException exception];

	if (write(_fd, buffer, (int)length) != (int)length)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
							     errNo: errno];
#endif
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
	if (_fd != INVALID_FD)
		close(_fd);
#else
	if (_closable && _fd != INVALID_FD)
		Close(_fd);
#endif

	_fd = INVALID_FD;

	[super close];
}

- autorelease
{
	return self;
}

- retain
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
#if defined(HAVE_SYS_IOCTL_H) && defined(TIOCGWINSZ)
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
#if defined(HAVE_SYS_IOCTL_H) && defined(TIOCGWINSZ)
	struct winsize ws;

	if (ioctl(_fd, TIOCGWINSZ, &ws) != 0)
		return -1;

	return ws.ws_row;
#else
	return -1;
#endif
}
@end
