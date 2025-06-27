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

#import "OTAssertionFailedException.h"

@implementation OTAssertionFailedException
@synthesize condition = _condition, message = _message;

+ (instancetype)exceptionWithCondition: (OFString *)condition
			       message: (OFString *)message
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithCondition: condition
				    message: message]);
}

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

- (instancetype)initWithCondition: (OFString *)condition
			  message: (OFString *)message
{
	self = [super init];

	@try {
		_condition = [condition copy];
		_message = [message copy];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	objc_release(_condition);
	objc_release(_message);

	[super dealloc];
}

- (OFString *)description
{
	if (_message != nil)
		return [OFString stringWithFormat: @"Assertion failed: %@: %@",
						   _condition, _message];
	else
		return [OFString stringWithFormat: @"Assertion failed: %@",
						   _condition];
}
@end
