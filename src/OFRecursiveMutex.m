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

#import "OFRecursiveMutex.h"

#import "OFInitializationFailedException.h"
#import "OFMutexLockFailedException.h"
#import "OFMutexStillLockedException.h"
#import "OFMutexUnlockFailedException.h"

@implementation OFRecursiveMutex
- init
{
	self = [super OF_initWithoutCreatingMutex];

	if (!of_rmutex_new(&rmutex)) {
		Class c = [self class];
		[self release];
		@throw [OFInitializationFailedException exceptionWithClass: c];
	}

	initialized = YES;

	return self;
}

- (void)lock
{
	if (!of_rmutex_lock(&rmutex))
		@throw [OFMutexLockFailedException
		    exceptionWithClass: [self class]
				 mutex: self];
}

- (BOOL)tryLock
{
	return of_rmutex_trylock(&rmutex);
}

- (void)unlock
{
	if (!of_rmutex_unlock(&rmutex))
		@throw [OFMutexUnlockFailedException
		    exceptionWithClass: [self class]
				 mutex: self];
}

- (void)dealloc
{
	if (initialized)
		if (!of_rmutex_free(&rmutex))
			@throw [OFMutexStillLockedException
			    exceptionWithClass: [self class]
					 mutex: self];

	[super dealloc];
}
@end
