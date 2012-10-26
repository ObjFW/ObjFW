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

#import "OFTLSKey.h"

#import "OFInitializationFailedException.h"

static OFList *TLSKeys;

@implementation OFTLSKey
+ (void)initialize
{
	if (self == [OFTLSKey class])
		TLSKeys = [[OFList alloc] init];
}

+ (instancetype)TLSKey
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)TLSKeyWithDestructor: (void(*)(id))destructor
{
	return [[[self alloc] initWithDestructor: destructor] autorelease];
}

+ (void)OF_callAllDestructors
{
	of_list_object_t *iter;

	@synchronized (TLSKeys) {
		for (iter = [TLSKeys firstListObject]; iter != NULL;
		    iter = iter->next) {
			OFTLSKey *key = (OFTLSKey*)iter->object;

			if (key->destructor != NULL)
				key->destructor(iter->object);
		}
	}
}

- init
{
	self = [super init];

	@try {
		if (!of_tlskey_new(&key))
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];

		initialized = YES;

		@synchronized (TLSKeys) {
			listObject = [TLSKeys appendObject: self];
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithDestructor: (void(*)(id))destructor_
{
	self = [self init];

	destructor = destructor_;

	return self;
}

- (void)dealloc
{
	if (destructor != NULL)
		destructor(self);

	if (initialized)
		of_tlskey_free(key);

	/* In case we called [self release] in init */
	if (listObject != NULL) {
		@synchronized (TLSKeys) {
			[TLSKeys removeListObject: listObject];
		}
	}

	[super dealloc];
}
@end
