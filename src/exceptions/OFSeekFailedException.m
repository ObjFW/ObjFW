/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
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
