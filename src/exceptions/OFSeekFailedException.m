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

#include <stdlib.h>

#import "OFSeekFailedException.h"
#import "OFString.h"
#import "OFSeekableStream.h"

#import "common.h"

@implementation OFSeekFailedException
+ (instancetype)exceptionWithClass: (Class)class
			    stream: (OFSeekableStream*)stream
			    offset: (off_t)offset
			    whence: (int)whence
{
	return [[[self alloc] initWithClass: class
				     stream: stream
				     offset: offset
				     whence: whence] autorelease];
}

- initWithClass: (Class)class
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	abort();
}

- initWithClass: (Class)class
	 stream: (OFSeekableStream*)stream
	 offset: (off_t)offset
	 whence: (int)whence
{
	self = [super initWithClass: class];

	_stream = [stream retain];
	_offset = offset;
	_whence = whence;
	_errNo = GET_ERRNO;

	return self;
}

- (void)dealloc
{
	[_stream release];

	[super dealloc];
}

- (OFString*)description
{
	if (_description != nil)
		return _description;

	_description = [[OFString alloc] initWithFormat:
	    @"Seeking failed in class %@! " ERRFMT, _inClass, ERRPARAM];

	return _description;
}

- (OFSeekableStream*)stream
{
	OF_GETTER(_stream, NO)
}

- (off_t)offset
{
	return _offset;
}

- (int)whence
{
	return _whence;
}

- (int)errNo
{
	return _errNo;
}
@end
