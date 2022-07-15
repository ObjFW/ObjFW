/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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
#import "OFColor.h"
#import "OFDate.h"
#import "OFApplication.h"
#ifdef OF_WINDOWS
# include "OFWin32ConsoleStdIOStream.h"
#endif

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFNotOpenException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFWriteFailedException.h"

#ifdef OF_IOS
# undef HAVE_ISATTY
#endif

#ifdef OF_AMIGAOS
# include <proto/exec.h>
# include <proto/dos.h>
# undef HAVE_ISATTY
#endif

/* References for static linking */
#ifdef OF_WINDOWS
void
_reference_to_OFWin32ConsoleStdIOStream(void)
{
	[OFWin32ConsoleStdIOStream class];
}
#endif

OFStdIOStream *OFStdIn = nil;
OFStdIOStream *OFStdOut = nil;
OFStdIOStream *OFStdErr = nil;

#ifdef OF_AMIGAOS
OF_DESTRUCTOR()
{
	[OFStdIn dealloc];
	[OFStdOut dealloc];
	[OFStdErr dealloc];
}
#endif

void
OFLog(OFConstantString *format, ...)
{
	va_list arguments;

	va_start(arguments, format);
	OFLogV(format, arguments);
	va_end(arguments);
}

void
OFLogV(OFConstantString *format, va_list arguments)
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *date;
	OFString *dateString, *me, *msg;

	date = [OFDate date];
	dateString = [date localDateStringWithFormat: @"%Y-%m-%d %H:%M:%S"];
#ifdef OF_HAVE_FILES
	me = [OFApplication programName].lastPathComponent;
#else
	me = [OFApplication programName];
#endif

	msg = [[[OFString alloc] initWithFormat: format
				      arguments: arguments] autorelease];

	[OFStdErr writeFormat: @"[%@.%03d %@(%d)] %@\n", dateString,
			       date.microsecond / 1000, me, getpid(), msg];

	objc_autoreleasePoolPop(pool);
}

#ifdef HAVE_ISATTY
static int
colorToANSI(OFColor *color)
{
	if ([color isEqual: [OFColor black]])
		return 30;
	if ([color isEqual: [OFColor maroon]])
		return 31;
	if ([color isEqual: [OFColor green]])
		return 32;
	if ([color isEqual: [OFColor olive]])
		return 33;
	if ([color isEqual: [OFColor navy]])
		return 34;
	if ([color isEqual: [OFColor purple]])
		return 35;
	if ([color isEqual: [OFColor teal]])
		return 36;
	if ([color isEqual: [OFColor silver]])
		return 37;
	if ([color isEqual: [OFColor grey]])
		return 90;
	if ([color isEqual: [OFColor red]])
		return 91;
	if ([color isEqual: [OFColor lime]])
		return 92;
	if ([color isEqual: [OFColor yellow]])
		return 93;
	if ([color isEqual: [OFColor blue]])
		return 94;
	if ([color isEqual: [OFColor fuchsia]])
		return 95;
	if ([color isEqual: [OFColor aqua]])
		return 96;
	if ([color isEqual: [OFColor white]])
		return 97;

	return -1;
}
#endif

@implementation OFStdIOStream
#ifndef OF_WINDOWS
+ (void)load
{
	if (self != [OFStdIOStream class])
		return;

# ifndef OF_AMIGAOS
	int fd;

	if ((fd = fileno(stdin)) >= 0)
		OFStdIn = [[OFStdIOStream alloc] of_initWithFileDescriptor: fd];
	if ((fd = fileno(stdout)) >= 0)
		OFStdOut = [[OFStdIOStream alloc]
		    of_initWithFileDescriptor: fd];
	if ((fd = fileno(stderr)) >= 0)
		OFStdErr = [[OFStdIOStream alloc]
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

	OFStdIn = [[OFStdIOStream alloc] of_initWithHandle: input
						  closable: inputClosable];
	OFStdOut = [[OFStdIOStream alloc] of_initWithHandle: output
						   closable: outputClosable];
	OFStdErr = [[OFStdIOStream alloc] of_initWithHandle: error
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
- (instancetype)of_initWithHandle: (BPTR)handle closable: (bool)closable
{
	self = [super init];

	_handle = handle;
	_closable = closable;

	return self;
}
#endif

- (void)dealloc
{
#ifndef OF_AMIGAOS
	if (_fd != -1)
#else
	if (_handle != 0)
#endif
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

- (size_t)lowlevelReadIntoBuffer: (void *)buffer length: (size_t)length
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

- (size_t)lowlevelWriteBuffer: (const void *)buffer length: (size_t)length
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
	if (_fd == -1)
		@throw [OFNotOpenException exceptionWithObject: self];

	close(_fd);
	_fd = -1;
#else
	if (_handle == 0)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_closable)
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
	return OFMaxRetainCount;
}

- (bool)hasTerminal
{
#ifdef HAVE_ISATTY
	return isatty(_fd);
#else
	return false;
#endif
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

- (void)setForegroundColor: (OFColor *)color
{
#ifdef HAVE_ISATTY
	int code;

	if (!isatty(_fd))
		return;

	if ((code = colorToANSI(color)) == -1)
		return;

	[self writeFormat: @"\033[%um", code];
#endif
}

- (void)setBackgroundColor: (OFColor *)color
{
#ifdef HAVE_ISATTY
	int code;

	if (!isatty(_fd))
		return;

	if ((code = colorToANSI(color)) == -1)
		return;

	[self writeFormat: @"\033[%um", code + 10];
#endif
}

- (void)reset
{
#ifdef HAVE_ISATTY
	if (!isatty(_fd))
		return;

	[self writeString: @"\033[0m"];
#endif
}

- (void)clear
{
#ifdef HAVE_ISATTY
	if (!isatty(_fd))
		return;

	[self writeString: @"\033[2J"];
#endif
}

- (void)eraseLine
{
#ifdef HAVE_ISATTY
	if (!isatty(_fd))
		return;

	[self writeString: @"\033[2K"];
#endif
}

- (void)setCursorColumn: (unsigned int)column
{
#ifdef HAVE_ISATTY
	if (!isatty(_fd))
		return;

	[self writeFormat: @"\033[%uG", column + 1];
#endif
}

- (void)setCursorPosition: (OFPoint)position
{
	if (position.x < 0 || position.y < 0)
		@throw [OFInvalidArgumentException exception];

#ifdef HAVE_ISATTY
	if (!isatty(_fd))
		return;

	[self writeFormat: @"\033[%u;%uH",
			   (unsigned)position.y + 1, (unsigned)position.x + 1];
#endif
}

- (void)setRelativeCursorPosition: (OFPoint)position
{
#ifdef HAVE_ISATTY
	if (!isatty(_fd))
		return;

	if (position.x > 0)
		[self writeFormat: @"\033[%uC", (unsigned)position.x];
	else if (position.x < 0)
		[self writeFormat: @"\033[%uD", (unsigned)-position.x];

	if (position.y > 0)
		[self writeFormat: @"\033[%uB", (unsigned)position.y];
	else if (position.y < 0)
		[self writeFormat: @"\033[%uA", (unsigned)-position.y];
#endif
}
@end
