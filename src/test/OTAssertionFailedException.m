/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OTAssertionFailedException.h"

@implementation OTAssertionFailedException
@synthesize condition = _condition, message = _message;

+ (instancetype)exceptionWithCondition: (OFString *)condition
			       message: (OFString *)message
{
	return [[[self alloc] initWithCondition: condition
					message: message] autorelease];
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
		[self release];
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
	[_condition release];
	[_message release];

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
