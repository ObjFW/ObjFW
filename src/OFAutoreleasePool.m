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

#import "macros.h"
#ifndef OF_COMPILER_TLS
# import "threading.h"

# import "OFInitializationFailedException.h"
#endif

extern id _objc_rootAutorelease(id);
extern void* objc_autoreleasePoolPush(void);
extern void objc_autoreleasePoolPop(void*);

#ifdef OF_COMPILER_TLS
static __thread void *first = NULL;
#else
static of_tlskey_t firstKey;
#endif

@implementation OFAutoreleasePool
#ifndef OF_COMPILER_TLS
+ (void)initialize
{
	if (self != [OFAutoreleasePool class])
		return;

	if (!of_tlskey_new(&firstKey))
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}
#endif

+ (id)addObject: (id)object
{
#ifndef OF_COMPILER_TLS
	void *first = of_tlskey_get(firstKey);
#endif

	if (first == NULL)
		[[OFAutoreleasePool alloc] init];

	return _objc_rootAutorelease(object);
}

+ (void)_releaseAll
{
#ifndef OF_COMPILER_TLS
	void *first = of_tlskey_get(firstKey);
#endif

	objc_autoreleasePoolPop(first);
}

- init
{
	self = [super init];

	@try {
#ifndef OF_COMPILER_TLS
		void *first = of_tlskey_get(firstKey);
#endif

		pool = objc_autoreleasePoolPush();

		if (first == NULL)
#ifdef OF_COMPILER_TLS
			first = pool;
#else
			OF_ENSURE(of_tlskey_set(firstKey, pool));
#endif

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

#ifdef OF_COMPILER_TLS
	if (first == pool)
		first = NULL;
#else
	if (of_tlskey_get(firstKey) == pool)
		OF_ENSURE(of_tlskey_set(firstKey, NULL));
#endif

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
