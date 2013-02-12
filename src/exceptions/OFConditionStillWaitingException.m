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

#include <stdlib.h>

#import "OFConditionStillWaitingException.h"
#import "OFString.h"
#import "OFCondition.h"

@implementation OFConditionStillWaitingException
+ (instancetype)exceptionWithClass: (Class)class
			 condition: (OFCondition*)condition
{
	return [[[self alloc] initWithClass: class
				  condition: condition] autorelease];
}

- initWithClass: (Class)class
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	abort();
}

- initWithClass: (Class)class
      condition: (OFCondition*)condition
{
	self = [super initWithClass: class];

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
	if (_description != nil)
		return _description;

	_description = [[OFString alloc] initWithFormat:
	    @"Deallocation of a condition of type %@ was tried, even though a "
	    @"thread was still waiting for it!", _inClass];

	return _description;
}

- (OFCondition*)condition
{
	OF_GETTER(_condition, NO)
}
@end
