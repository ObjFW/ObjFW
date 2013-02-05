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

#import "OFConditionWaitFailedException.h"
#import "OFString.h"
#import "OFCondition.h"

@implementation OFConditionWaitFailedException
+ (instancetype)exceptionWithClass: (Class)class_
			 condition: (OFCondition*)condition
{
	return [[[self alloc] initWithClass: class_
				  condition: condition] autorelease];
}

- initWithClass: (Class)class_
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	abort();
}

- initWithClass: (Class)class_
      condition: (OFCondition*)condition_
{
	self = [super initWithClass: class_];

	condition = [condition_ retain];

	return self;
}

- (void)dealloc
{
	[condition release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Waiting for a condition of type %@ failed!", inClass];

	return description;
}

- (OFCondition*)condition
{
	OF_GETTER(condition, NO)
}
@end
