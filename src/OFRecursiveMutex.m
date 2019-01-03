/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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
@synthesize name = _name;

+ (instancetype)mutex
{
	return [[[self alloc] init] autorelease];
}

- (instancetype)init
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

- (void)dealloc
{
	if (_initialized)
		if (!of_rmutex_free(&_rmutex))
			@throw [OFStillLockedException exceptionWithLock: self];

	[_name release];

	[super dealloc];
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

- (OFString *)description
{
	if (_name == nil)
		return [super description];

	return [OFString stringWithFormat: @"<%@: %@>",
					   [self className], _name];
}
@end
