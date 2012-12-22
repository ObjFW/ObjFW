/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#import "OFInvalidArgumentException.h"
#import "OFString.h"

#import "common.h"

@implementation OFInvalidArgumentException
+ (instancetype)exceptionWithClass: (Class)class_
			  selector: (SEL)selector_
{
	return [[[self alloc] initWithClass: class_
				   selector: selector_] autorelease];
}

- initWithClass: (Class)class_
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
		abort();
	} @catch (id e) {
		[self release];
		@throw e;
	}
}

- initWithClass: (Class)class_
       selector: (SEL)selector_
{
	self = [super initWithClass: class_];

	selector = selector_;

	return self;
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"The argument or receiver for method %s of class %@ is invalid!",
	    sel_getName(selector), inClass];

	return description;
}

- (SEL)selector
{
	return selector;
}
@end
