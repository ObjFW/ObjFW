/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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
#import "OFString.h"

#import "OFInitializationFailedException.h"
#import "OFLockFailedException.h"
#import "OFStillLockedException.h"
#import "OFUnlockFailedException.h"

@implementation OFRecursiveMutex
+ (instancetype)mutex
{
	return [[[self alloc] init] autorelease];
}

- init
{
	self = [super init];

	if (!of_rmutex_new(&_rmutex)) {
		Class c = [self class];
		[self release];
		@throw [OFInitializationFailedException exceptionWithClass: c];
	}

	_initialized = true;

	return self;
}

- (void)lock
{
	if (!of_rmutex_lock(&_rmutex))
		@throw [OFLockFailedException exceptionWithLock: self];
}

- (bool)tryLock
{
	return of_rmutex_trylock(&_rmutex);
}

- (void)unlock
{
	if (!of_rmutex_unlock(&_rmutex))
		@throw [OFUnlockFailedException exceptionWithLock: self];
}

- (void)setName: (OFString*)name
{
	OF_SETTER(_name, name, true, 1)
}

- (OFString*)name
{
	OF_GETTER(_name, true)
}

- (OFString*)description
{
	if (_name == nil)
		return [super description];

	return [OFString stringWithFormat: @"<%@: %@>",
					   [self className], _name];
}

- (void)dealloc
{
	if (_initialized)
		if (!of_rmutex_free(&_rmutex))
			@throw [OFStillLockedException exceptionWithLock: self];

	[_name release];

	[super dealloc];
}
@end
