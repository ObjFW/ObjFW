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

#import "OFMutex.h"
#import "OFString.h"

#import "OFInitializationFailedException.h"
#import "OFLockFailedException.h"
#import "OFStillLockedException.h"
#import "OFUnlockFailedException.h"

#import "macros.h"

@implementation OFMutex
+ (instancetype)mutex
{
	return [[[self alloc] init] autorelease];
}

- init
{
	self = [super init];

	if (!of_mutex_new(&mutex)) {
		Class c = [self class];
		[self release];
		@throw [OFInitializationFailedException exceptionWithClass: c];
	}

	initialized = YES;

	return self;
}

- (void)lock
{
	if (!of_mutex_lock(&mutex))
		@throw [OFLockFailedException exceptionWithClass: [self class]
							    lock: self];
}

- (BOOL)tryLock
{
	return of_mutex_trylock(&mutex);
}

- (void)unlock
{
	if (!of_mutex_unlock(&mutex))
		@throw [OFUnlockFailedException exceptionWithClass: [self class]
							      lock: self];
}

- (void)setName: (OFString*)name_
{
	OF_SETTER(name, name_, YES, YES)
}

- (OFString*)name
{
	OF_GETTER(name, YES)
}

- (OFString*)description
{
	if (name == nil)
		return [super description];

	return [OFString stringWithFormat: @"<%@: %@>", [self className], name];
}

- (void)dealloc
{
	if (initialized)
		if (!of_mutex_free(&mutex))
			@throw [OFStillLockedException
			    exceptionWithClass: [self class]
					  lock: self];

	[name release];

	[super dealloc];
}
@end
