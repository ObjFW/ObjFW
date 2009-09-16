/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <stdlib.h>

#ifndef _WIN32
#include <pthread.h>
#else
#include <windows.h>
#endif

#import "OFAutoreleasePool.h"
#import "OFList.h"
#import "OFThread.h"
#import "OFExceptions.h"

/*
 * Pay special attention to NULL and nil in this file, they might be different!
 * Use NULL for TLS values and nil for instance variables.
 */

#ifndef _WIN32
static pthread_key_t first_key, last_key;
#else
static DWORD first_key, last_key;
#endif

static void
release_all(void *list)
{
#ifndef _WIN32
	void *first = pthread_getspecific(first_key);
#else
	void *first = TlsGetValue(first_key);
#endif

	if (first != NULL)
		[(OFAutoreleasePool*)first release];
}

@implementation OFAutoreleasePool
+ (void)initialize
{
	if (self != [OFAutoreleasePool class])
		return;

#ifndef _WIN32
	if (pthread_key_create(&first_key, release_all) ||
	    pthread_key_create(&last_key, NULL))
#else
	/* FIXME: Call destructor */
	if ((first_key = TlsAlloc()) == TLS_OUT_OF_INDEXES ||
	    (last_key = TlsAlloc()) == TLS_OUT_OF_INDEXES)
#endif
		@throw [OFInitializationFailedException newWithClass: self];
}

+ (void)addObjectToTopmostPool: (OFObject*)obj
{
#ifndef _WIN32
	void *last = pthread_getspecific(last_key);
#else
	void *last = TlsGetValue(last_key);
#endif

	if (last == NULL) {
		@try {
			[[self alloc] init];
		} @catch (OFException *e) {
			[obj release];
			@throw e;
		}

#ifndef _WIN32
		last = pthread_getspecific(last_key);
#else
		last = TlsGetValue(last_key);
#endif
	}

	if (last == NULL) {
		[obj release];
		@throw [OFInitializationFailedException newWithClass: self];
	}

	@try {
		[(OFAutoreleasePool*)last addObject: obj];
	} @catch (OFException *e) {
		[obj release];
		@throw e;
	}
}

- init
{
	self = [super init];

#ifndef _WIN32
	void *first = pthread_getspecific(first_key);
	void *last = pthread_getspecific(last_key);
#else
	void *first = TlsGetValue(first_key);
	void *last = TlsGetValue(last_key);
#endif

#ifndef _WIN32
	if (pthread_setspecific(last_key, self)) {
#else
	if (!TlsSetValue(last_key, self)) {
#endif
		Class c = isa;
		[super dealloc];
		@throw [OFInitializationFailedException newWithClass: c];
	}

	if (first == NULL) {
#ifndef _WIN32
		if (pthread_setspecific(first_key, self)) {
#else
		if (!TlsSetValue(first_key, self)) {
#endif
			Class c = isa;

#ifndef _WIN32
			pthread_setspecific(last_key, last);
#else
			TlsSetValue(last_key, last);
#endif

			[super dealloc];
			@throw [OFInitializationFailedException
			    newWithClass: c];
		}
	}

	if (last != NULL) {
		prev = (OFAutoreleasePool*)last;
		prev->next = self;
	}

	return self;
}

- (void)dealloc
{
	[next dealloc];

	if (prev != nil)
		prev->next = nil;
#ifndef _WIN32
	pthread_setspecific(last_key, (prev != nil ? prev : NULL));
	if (pthread_getspecific(first_key) == self)
		pthread_setspecific(first_key, NULL);
#else
	TlsSetValue(last_key, (prev != nil ? prev : NULL));
	if (TlsGetValue(first_key) == self)
		TlsSetValue(first_key, NULL);
#endif

	[objects release];

	[super dealloc];
}

- addObject: (OFObject*)obj
{
	if (objects == nil)
		objects = [[OFMutableArray alloc] init];

	[objects addObject: obj];
	[obj release];

	return self;
}

- releaseObjects
{
	[next releaseObjects];

	if (objects == nil)
		return self;

	[objects release];
	objects = nil;

	return self;
}

- retain
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- autorelease
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}
@end
