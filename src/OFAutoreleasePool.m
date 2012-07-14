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

#import "OFAutoreleasePool.h"
#import "OFArray.h"

#import "OFNotImplementedException.h"

extern id _objc_rootAutorelease(id);
extern void* objc_autoreleasePoolPush(void);
extern void objc_autoreleasePoolPop(void*);

static __thread void *first = NULL;

@implementation OFAutoreleasePool
+ (id)addObject: (id)object
{
	if (first == NULL)
		[[OFAutoreleasePool alloc] init];

	return _objc_rootAutorelease(object);
}

+ (void)_releaseAll
{
	objc_autoreleasePoolPop(first);
}

- init
{
	self = [super init];

	@try {
		pool = objc_autoreleasePoolPush();

		if (first == NULL)
			first = pool;

		_objc_rootAutorelease(self);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)releaseObjects
{
	ignoreRelease = YES;

	objc_autoreleasePoolPop(pool);
	pool = objc_autoreleasePoolPush();

	_objc_rootAutorelease(self);

	ignoreRelease = NO;
}

- (void)release
{
	[self dealloc];
}

- (void)drain
{
	[self dealloc];
}

- (void)dealloc
{
	if (ignoreRelease)
		return;

	ignoreRelease = YES;

	if (first == pool)
		first = NULL;

	objc_autoreleasePoolPop(pool);

	[super dealloc];
}

- retain
{
	@throw [OFNotImplementedException exceptionWithClass: [self class]
						    selector: _cmd];
}

- autorelease
{
	@throw [OFNotImplementedException exceptionWithClass: [self class]
						    selector: _cmd];
}
@end
