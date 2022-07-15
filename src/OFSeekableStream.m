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

- (OFFileOffset)lowlevelSeekToOffset: (OFFileOffset)offset whence: (int)whence
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFFileOffset)seekToOffset: (OFFileOffset)offset whence: (int)whence
{
	if (whence == SEEK_CUR)
		offset -= _readBufferLength;

	offset = [self lowlevelSeekToOffset: offset whence: whence];

	OFFreeMemory(_readBufferMemory);
	_readBuffer = _readBufferMemory = NULL;
	_readBufferLength = 0;

	return offset;
}
@end
