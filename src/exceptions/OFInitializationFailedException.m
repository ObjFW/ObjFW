/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#import "OFInitializationFailedException.h"
#import "OFString.h"

#import "common.h"
#import "macros.h"

@implementation OFInitializationFailedException
+ (instancetype)exceptionWithClass: (Class)class
{
	return [[[self alloc] initWithClass: class] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithClass: (Class)class
{
	self = [super init];

	_inClass = class;

	return self;
}

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"Initialization failed for or in class %@!", _inClass];
}

- (Class)inClass
{
	return _inClass;
}
@end
