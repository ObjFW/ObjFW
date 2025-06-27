/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#import "OFHashAlreadyCalculatedException.h"
#import "OFString.h"

@implementation OFHashAlreadyCalculatedException
@synthesize object = _object;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithObject: (id)object
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithObject: object]);
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithObject: (id)object
{
	self = [super init];

	_object = objc_retain(object);

	return self;
}

- (void)dealloc
{
	objc_release(_object);

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"The hash of type %@ has already been calculated and thus no new "
	    @"data can be added!", [_object class]];
}
@end
