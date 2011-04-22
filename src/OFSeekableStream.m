/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#import "OFSeekableStream.h"

#import "OFNotImplementedException.h"

@implementation OFSeekableStream
- (void)_seekToOffset: (off_t)offset
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

- (void)seekToOffset: (off_t)offset
{
	[self _seekToOffset: offset];

	[self freeMemory: cache];
	cache = NULL;
	cacheLength = 0;
}

- (off_t)seekForwardWithOffset: (off_t)offset
{
	off_t retOffset;

	retOffset = [self _seekForwardWithOffset: offset - cacheLength];

	[self freeMemory: cache];
	cache = NULL;
	cacheLength = 0;

	return retOffset;
}

- (off_t)seekToOffsetRelativeToEnd: (off_t)offset
{
	off_t retOffset;

	retOffset = [self _seekToOffsetRelativeToEnd: offset];

	[self freeMemory: cache];
	cache = NULL;
	cacheLength = 0;

	return retOffset;
}
@end
