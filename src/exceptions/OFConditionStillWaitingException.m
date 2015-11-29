/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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

#import "OFConditionStillWaitingException.h"
#import "OFString.h"
#import "OFCondition.h"

@implementation OFConditionStillWaitingException
@synthesize condition = _condition;

+ (instancetype)exceptionWithCondition: (OFCondition*)condition
{
	return [[[self alloc] initWithCondition: condition] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithCondition: (OFCondition*)condition
{
	self = [super init];

	_condition = [condition retain];

	return self;
}

- (void)dealloc
{
	[_condition release];

	[super dealloc];
}

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"Deallocation of a condition of type %@ was tried, even though a "
	    @"thread was still waiting for it!", [_condition class]];
}
@end
