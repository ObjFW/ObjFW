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

#import "OFNotImplementedException.h"
#import "OFString.h"

#import "common.h"

@implementation OFNotImplementedException
+ (instancetype)exceptionWithClass: (Class)class
			  selector: (SEL)selector
{
	return [[[self alloc] initWithClass: class
				   selector: selector] autorelease];
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
       selector: (SEL)selector
{
	self = [super initWithClass: class];

	_selector = selector;

	return self;
}

- (OFString*)description
{
	if (_description != nil)
		return _description;

	_description = [[OFString alloc] initWithFormat:
	    @"The selector %s is not understood by class %@ or not (fully) "
	    @"implemented!", sel_getName(_selector), _inClass];

	return _description;
}

- (SEL)selector
{
	return _selector;
}
@end
