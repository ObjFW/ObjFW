/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFSeekableStream.h"
#import "OFExceptions.h"

@implementation OFSeekableStream
- _seekToOffset: (off_t)offset
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (off_t)_seekForwardWithOffset: (off_t)offset
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (off_t)_seekToOffsetRelativeToEnd: (off_t)offset
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- seekToOffset: (off_t)offset
{
	[self flushWriteBuffer];
	[self _seekToOffset: offset];

	[self freeMemory: cache];
	cache = NULL;
	cache_len = 0;

	return self;
}

- (off_t)seekForwardWithOffset: (off_t)offset
{
	off_t ret;

	[self flushWriteBuffer];
	ret = [self _seekForwardWithOffset: offset - cache_len];

	[self freeMemory: cache];
	cache = NULL;
	cache_len = 0;

	return ret;
}

- (off_t)seekToOffsetRelativeToEnd: (off_t)offset
{
	off_t ret;

	[self flushWriteBuffer];
	ret = [self _seekToOffsetRelativeToEnd: offset];

	[self freeMemory: cache];
	cache = NULL;
	cache_len = 0;

	return ret;
}
@end
