/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#import "OFSeekableStream.h"

@implementation OFSeekableStream
- (void)lowlevelSeekToOffset: (off_t)offset
		      whence: (int)whence
{
	[self doesNotRecognizeSelector: _cmd];
	abort();
}

- (void)seekToOffset: (off_t)offset
	      whence: (int)whence
{
	[self lowlevelSeekToOffset: offset
			    whence: whence];

	[self freeMemory: cache];
	cache = NULL;
	cacheLength = 0;
}
@end
