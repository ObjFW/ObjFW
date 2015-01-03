/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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

#import "OFAutoreleasePool.h"
#import "OFAutoreleasePool+Private.h"

#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
# import "threading.h"
#
# import "OFInitializationFailedException.h"
#endif

#define MAX_CACHE_SIZE 0x20

#if defined(OF_HAVE_COMPILER_TLS)
static thread_local OFAutoreleasePool **cache = NULL;
#elif defined(OF_HAVE_THREADS)
static of_tlskey_t cacheKey;
#else
static OFAutoreleasePool **cache = NULL;
#endif

@implementation OFAutoreleasePool
#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
+ (void)initialize
{
	if (self != [OFAutoreleasePool class])
		return;

	if (!of_tlskey_new(&cacheKey))
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}
#endif

+ alloc
{
#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	OFAutoreleasePool **cache = of_tlskey_get(cacheKey);
#endif

	if (cache != NULL) {
		unsigned i;

		for (i = 0; i < MAX_CACHE_SIZE; i++) {
			if (cache[i] != NULL) {
				OFAutoreleasePool *pool = cache[i];
				cache[i] = NULL;
				return pool;
			}
		}
	}

	return [super alloc];
}

+ (id)addObject: (id)object
{
	return _objc_rootAutorelease(object);
}

+ (void)OF_handleThreadTermination
{
#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	OFAutoreleasePool **cache = of_tlskey_get(cacheKey);
#endif
	size_t i;

	if (cache != NULL) {
		for (i = 0; i < MAX_CACHE_SIZE; i++)
			[cache[i] OF_super_dealloc];

		free(cache);
		cache = NULL;
	}
}

- init
{
	self = [super init];

	@try {
		_pool = objc_autoreleasePoolPush();

		_objc_rootAutorelease(self);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)releaseObjects
{
	_ignoreRelease = true;

	objc_autoreleasePoolPop(_pool);
	_pool = objc_autoreleasePoolPush();

	_objc_rootAutorelease(self);

	_ignoreRelease = false;
}

- (void)release
{
	[self dealloc];
}

- (void)drain
{
	[self dealloc];
}

- (void)OF_super_dealloc
{
	[super dealloc];
}

- (void)dealloc
{
#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	OFAutoreleasePool **cache = of_tlskey_get(cacheKey);
#endif

	if (_ignoreRelease)
		return;

	_ignoreRelease = true;

	objc_autoreleasePoolPop(_pool);

	if (cache == NULL) {
		cache = calloc(sizeof(OFAutoreleasePool*), MAX_CACHE_SIZE);

#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
		if (!of_tlskey_set(cacheKey, cache)) {
			free(cache);
			cache = NULL;
		}
#endif
	}

	if (cache != NULL) {
		unsigned i;

		for (i = 0; i < MAX_CACHE_SIZE; i++) {
			if (cache[i] == NULL) {
				_pool = NULL;
				_ignoreRelease = false;

				cache[i] = self;

				return;
			}
		}
	}

	[super dealloc];
}

- retain
{
	OF_UNRECOGNIZED_SELECTOR
}

- autorelease
{
	OF_UNRECOGNIZED_SELECTOR
}
@end
