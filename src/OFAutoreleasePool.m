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

#include <stdlib.h>

#ifndef _WIN32
#include <pthread.h>
#endif

#import "OFAutoreleasePool.h"
#import "OFExceptions.h"
#import "OFList.h"

#ifdef _WIN32
#include <windows.h>
#endif

#ifndef _WIN32
#define get_tls(t) pthread_getspecific(pool_list_key)
#define set_tls(t, v) pthread_setspecific(t, v)
static pthread_key_t pool_list_key;
#else
#define get_tls(t) TlsGetValue(t)
#define set_tls(t, v) TlsSetValue(t, v)
static DWORD pool_list_key;
#endif

#ifndef _WIN32
static void
release_list(void *list)
{
	of_list_object_t *first, *iter;
	IMP release;

	if ((first = [(OFList*)list first]) != NULL)
		release = [first->object methodFor: @selector(release)];

	for (iter = first; iter != NULL; iter = iter->next)
		release(iter->object, @selector(release));

	[(OFList*)list release];
}
#endif

@implementation OFAutoreleasePool
+ (void)initialize
{
#ifndef _WIN32
	if (pthread_key_create(&pool_list_key, release_list))
		@throw [OFInitializationFailedException newWithClass: self];
#else
	/* FIXME: Free stuff when thread is terminated! */
	if ((pool_list_key = TlsAlloc()) == TLS_OUT_OF_INDEXES)
		@throw [OFInitializationFailedException newWithClass: self];
#endif
}

+ (void)addToPool: (OFObject*)obj
{
	OFList *pool_list = get_tls(pool_list_key);

	if (pool_list == nil || [pool_list last] == NULL) {
		[[self alloc] init];
		pool_list = get_tls(pool_list_key);
	}

	if (pool_list == nil || [pool_list last] == NULL)
		@throw [OFInitializationFailedException newWithClass: self];

	[[pool_list last]->object addToPool: obj];
}

- init
{
	OFList *pool_list;

	if ((self = [super init])) {
		objects = nil;

		pool_list = get_tls(pool_list_key);

		if (pool_list == nil) {
			pool_list = [[OFList alloc]
			    initWithRetainAndReleaseEnabled: NO];
			set_tls(pool_list_key, pool_list);
		}

		listobj = [pool_list append: self];
	}

	return self;
}

- free
{
	[(OFList*)get_tls(pool_list_key) remove: listobj];

	return [super free];
}

- addToPool: (OFObject*)obj
{
	if (objects == nil)
		objects = [[OFArray alloc] initWithItemSize: sizeof(char*)];

	[objects add: &obj];

	return self;
}

- release
{
	[self releaseObjects];

	return [super release];
}

- releaseObjects
{
	size_t i, size;
	IMP get_item;

	if (objects == nil)
		return self;

	size = [objects items];
	get_item = [objects methodFor: @selector(item:)];

	for (i = 0; i < size; i++)
		[*((OFObject**)get_item(objects, @selector(item:), i)) release];

	[objects release];
	objects = nil;

	return self;
}
@end
