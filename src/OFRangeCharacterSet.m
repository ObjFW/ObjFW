/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

#import "OFRangeCharacterSet.h"
#import "OFString.h"

#import "OFOutOfRangeException.h"

@implementation OFRangeCharacterSet
- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithRange: (of_range_t)range
{
	self = [super init];

	@try {
		if (SIZE_MAX - range.location < range.length)
			@throw [OFOutOfRangeException exception];

		_range = range;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (bool)characterIsMember: (of_unichar_t)character
{
	return (character >= _range.location &&
	    character < _range.location + _range.length);
}
@end
