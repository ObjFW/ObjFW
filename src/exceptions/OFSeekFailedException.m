/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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

#import "OFSeekFailedException.h"
#import "OFString.h"
#import "OFSeekableStream.h"

#import "common.h"
#import "macros.h"

@implementation OFSeekFailedException
+ (instancetype)exceptionWithStream: (OFSeekableStream*)stream
			     offset: (off_t)offset
			     whence: (int)whence
{
	return [[[self alloc] initWithStream: stream
				      offset: offset
				      whence: whence] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithStream: (OFSeekableStream*)stream
	  offset: (off_t)offset
	  whence: (int)whence
{
	self = [super init];

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
	return [OFString stringWithFormat:
	    @"Seeking failed in stream of type %@! " ERRFMT, [_stream class],
	    ERRPARAM];
}

- (OFSeekableStream*)stream
{
	OF_GETTER(_stream, true)
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
