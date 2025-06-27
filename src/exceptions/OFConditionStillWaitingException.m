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

#import "OFConditionStillWaitingException.h"
#import "OFString.h"
#import "OFCondition.h"

@implementation OFConditionStillWaitingException
@synthesize condition = _condition;

+ (instancetype)exceptionWithCondition: (OFCondition *)condition
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithCondition: condition]);
}

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

- (instancetype)initWithCondition: (OFCondition *)condition
{
	self = [super init];

	_condition = objc_retain(condition);

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	objc_release(_condition);

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Deallocation of a condition of type %@ was tried, even though "
	    "a thread was still waiting for it!",
	    _condition.class];
}
@end
