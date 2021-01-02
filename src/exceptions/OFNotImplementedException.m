/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#import "OFNotImplementedException.h"
#import "OFString.h"

@implementation OFNotImplementedException
@synthesize selector = _selector, object = _object;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithSelector: (SEL)selector
			       object: (id)object
{
	return [[[self alloc] initWithSelector: selector
					object: object] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithSelector: (SEL)selector
			  object: (id)object
{
	self = [super init];

	_selector = selector;
	_object = [object retain];

	return self;
}

- (void)dealloc
{
	[_object release];

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
