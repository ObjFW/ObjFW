/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

#import "OFInitializationFailedException.h"
#import "OFString.h"

@implementation OFInitializationFailedException
@synthesize inClass = _inClass;

+ (instancetype)exceptionWithClass: (Class)class
{
	return [[[self alloc] initWithClass: class] autorelease];
}

- (instancetype)init
{
	return [self initWithClass: Nil];
}

- (instancetype)initWithClass: (Class)class
{
	self = [super init];

	_inClass = class;

	return self;
}

- (OFString *)description
{
	if (_inClass != Nil)
		return [OFString stringWithFormat:
		    @"Initialization failed for or in class %@!", _inClass];
	else
		return @"Initialization failed!";
}
@end
