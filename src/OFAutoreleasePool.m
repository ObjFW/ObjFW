/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import <stdlib.h>

#ifndef _WIN32
#import <pthread.h>
#endif

#import "OFAutoreleasePool.h"
#import "OFExceptions.h"

#ifdef _WIN32
#import <windows.h>
#endif

#ifndef _WIN32
static pthread_key_t pool_stack_key;
static pthread_key_t pool_index_key;
#else
static DWORD pool_stack_key;
static DWORD pool_index_key;
#endif

#ifndef _WIN32
static void
free_each(void *ptr)
{
	OFAutoreleasePool **p;
	OFObject **o;

	for (p = (OFAutoreleasePool**)ptr; *p != nil; p++) {
		for (o = [*p objects]; *o != nil; o++)
			[*o release];
		[*p free];
	}
}
#endif

@implementation OFAutoreleasePool
+ (void)initialize
{
#ifndef _WIN32
	if (pthread_key_create(&pool_stack_key, free_each))
		@throw [OFInitializationFailedException newWithClass: self];
	if (pthread_key_create(&pool_index_key, free)) {
		pthread_key_delete(pool_stack_key);
		@throw [OFInitializationFailedException newWithClass: self];
	}
#else
	/* FIXME: Free stuff when thread is terminated! */
	if ((pool_stack_key = TlsAlloc()) == TLS_OUT_OF_INDEXES)
		@throw [OFInitializationFailedException newWithClass: self];
	if ((pool_index_key = TlsAlloc()) == TLS_OUT_OF_INDEXES) {
		TlsFree(pool_stack_key);
		@throw [OFInitializationFailedException newWithClass: self];
	}

#endif
}

+ (void)addToPool: (OFObject*)obj
{
	OFAutoreleasePool **pool_stack;
	int *pool_index;

#ifndef _WIN32
	pool_stack = pthread_getspecific(pool_stack_key);
	pool_index = pthread_getspecific(pool_index_key);
#else
	pool_stack = TlsGetValue(pool_stack_key);
	pool_index = TlsGetValue(pool_index_key);
#endif

	if (pool_stack == NULL || pool_index == NULL) {
		[[self alloc] init];

#ifndef _WIN32
		pool_stack = pthread_getspecific(pool_stack_key);
		pool_index = pthread_getspecific(pool_index_key);
#else
		pool_stack = TlsGetValue(pool_stack_key);
		pool_index = TlsGetValue(pool_index_key);
#endif
	}

	if (*pool_stack == nil || *pool_index == -1)
		@throw [OFInitializationFailedException newWithClass: self];

	[pool_stack[*pool_index] addToPool: obj];
}

- init
{
	OFAutoreleasePool **pool_stack, **pool_stack2;
	int *pool_index;
	Class c;

	if ((self = [super init])) {
		objects = NULL;
		size = 0;

#ifndef _WIN32
		pool_stack = pthread_getspecific(pool_stack_key);
		pool_index = pthread_getspecific(pool_index_key);
#else
		pool_stack = TlsGetValue(pool_stack_key);
		pool_index = TlsGetValue(pool_index_key);
#endif

		if (pool_index == NULL) {
			if ((pool_index = malloc(sizeof(int))) == NULL) {
				c = [self class];
				[super free];
				@throw [OFNoMemException newWithClass: c];
			}

			*pool_index = -1;
#ifndef _WIN32
			pthread_setspecific(pool_index_key, pool_index);
#else
			TlsSetValue(pool_index_key, pool_index);
#endif
		}

		if ((pool_stack2 = realloc(pool_stack,
		    (*pool_index + 3) * sizeof(OFAutoreleasePool*))) == NULL) {
			c = [self class];
			[super free];
			@throw [OFNoMemException newWithClass: c];
		}
		pool_stack = pool_stack2;
#ifndef _WIN32
		pthread_setspecific(pool_stack_key, pool_stack);
#else
		TlsSetValue(pool_stack_key, pool_stack);
#endif
		(*pool_index)++;

		pool_stack[*pool_index] = self;
		pool_stack[*pool_index + 1] = nil;
	}

	return self;
}

- free
{
	[self release];

	return [super free];
}

- addToPool: (OFObject*)obj
{
	OFObject **objects2;
	size_t size2;

	size2 = size + 1;

	if (SIZE_MAX - size < 1 || size2 > SIZE_MAX / sizeof(OFObject*))
		@throw [OFOutOfRangeException newWithClass: [self class]];

	if ((objects2 = realloc(objects, size2 * sizeof(OFObject*))) == NULL)
		@throw [OFNoMemException newWithClass: [self class]
					      andSize: size2];

	objects = objects2;
	objects[size] = obj;
	size = size2;

	return self;
}

- release
{
	size_t i;

	if (objects != NULL) {
		for (i = 0; size < i; i++)
			[objects[i] release];

		free(objects);
	}

	objects = NULL;
	size = 0;

	return self;
}

- (OFObject**)objects
{
	return objects;
}
@end
