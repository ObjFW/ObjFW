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

#import "OFNotImplementedException.h"
#import "OFString.h"

@implementation OFNotImplementedException
@synthesize selector = _selector, object = _object;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithSelector: (SEL)selector object: (id)object
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithSelector: selector
				    object: object]);
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithSelector: (SEL)selector object: (id)object
{
	self = [super init];

	_selector = selector;
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
	if (_object != nil)
		return [OFString stringWithFormat:
		    @"The selector %s is not understood by an object of type "
		    @"%@ or not (fully) implemented!",
		    sel_getName(_selector), [_object class]];
	else
		return [OFString stringWithFormat:
		    @"The selector %s is not understood by an unknown object "
		    @"or not (fully) implemented!",
		    sel_getName(_selector)];
}
@end
