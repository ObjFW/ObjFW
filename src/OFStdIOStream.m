/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#include <unistd.h>

#import "OFStdIOStream.h"
#import "OFDate.h"
#import "OFApplication.h"

#import "OFReadFailedException.h"
#import "OFWriteFailedException.h"

#import "autorelease.h"
#import "macros.h"

OFStdIOStream *of_stdin = nil;
OFStdIOStream *of_stdout = nil;
OFStdIOStream *of_stderr = nil;

@interface OFStdIOStream (OF_PRIVATE_CATEGORY)
- (instancetype)OF_initWithFileDescriptor: (int)fd;
@end

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
+ (void)load
{
	of_stdin = [[OFStdIOStream alloc] OF_initWithFileDescriptor: 0];
	of_stdout = [[OFStdIOStream alloc] OF_initWithFileDescriptor: 1];
	of_stderr = [[OFStdIOStream alloc] OF_initWithFileDescriptor: 2];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)OF_initWithFileDescriptor: (int)fd
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

	if (_fd == -1 || _atEndOfStream ||
	    (ret = read(_fd, buffer, length)) < 0)
		@throw [OFReadFailedException exceptionWithStream: self
						  requestedLength: length];

	if (ret == 0)
		_atEndOfStream = true;

	return ret;
}

- (void)lowlevelWriteBuffer: (const void*)buffer
		     length: (size_t)length
{
	if (_fd == -1 || _atEndOfStream || write(_fd, buffer, length) < length)
		@throw [OFWriteFailedException exceptionWithStream: self
						   requestedLength: length];
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

- (void)dealloc
{
	OF_UNRECOGNIZED_SELECTOR

	/* Get rid of stupid warning */
	[super dealloc];
}
@end
