/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#define OF_SEEKABLE_STREAM_M

#include "config.h"

#include <stdlib.h>
#include <stdio.h>

#import "OFSeekableStream.h"

@implementation OFSeekableStream
- (instancetype)init
{
	if ([self isMemberOfClass: [OFSeekableStream class]]) {
		@try {
			[self doesNotRecognizeSelector: _cmd];
			abort();
		} @catch (id e) {
			[self release];
			@throw e;
		}
	}

	return [super init];
}

- (OFStreamOffset)lowlevelSeekToOffset: (OFStreamOffset)offset
				whence: (OFSeekWhence)whence
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFStreamOffset)seekToOffset: (OFStreamOffset)offset
			whence: (OFSeekWhence)whence
{
	if (whence == OFSeekCurrent)
		offset -= _readBufferLength;

	offset = [self lowlevelSeekToOffset: offset whence: whence];

	OFFreeMemory(_readBufferMemory);
	_readBuffer = _readBufferMemory = NULL;
	_readBufferLength = 0;

	return offset;
}
@end
