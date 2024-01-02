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

#import "OFSeekFailedException.h"
#import "OFString.h"
#import "OFSeekableStream.h"

@implementation OFSeekFailedException
@synthesize stream = _stream, offset = _offset, whence = _whence;
@synthesize errNo = _errNo;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithStream: (OFSeekableStream *)stream
			     offset: (OFStreamOffset)offset
			     whence: (OFSeekWhence)whence
			      errNo: (int)errNo
{
	return [[[self alloc] initWithStream: stream
				      offset: offset
				      whence: whence
				       errNo: errNo] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithStream: (OFSeekableStream *)stream
			offset: (OFStreamOffset)offset
			whence: (OFSeekWhence)whence
			 errNo: (int)errNo
{
	self = [super init];

	_stream = [stream retain];
	_offset = offset;
	_whence = whence;
	_errNo = errNo;

	return self;
}

- (void)dealloc
{
	[_stream release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Seeking failed in stream of type %@: %@",
	    _stream.class, OFStrError(_errNo)];
}
@end
