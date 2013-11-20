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

#import "OFConditionBroadcastFailedException.h"
#import "OFString.h"
#import "OFCondition.h"

@implementation OFConditionBroadcastFailedException
+ (instancetype)exceptionWithCondition: (OFCondition*)condition
{
	return [[[self alloc] initWithCondition: condition] autorelease];
}

- init
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	abort();
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
	    @"Broadcasting a condition of type %@ failed!", [_condition class]];
}

- (OFCondition*)condition
{
	OF_GETTER(_condition, true)
}
@end
