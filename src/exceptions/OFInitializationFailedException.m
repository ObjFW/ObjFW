/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
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
