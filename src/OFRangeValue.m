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

#import "OFRangeValue.h"
#import "OFMethodSignature.h"
#import "OFString.h"

#import "OFOutOfRangeException.h"

@implementation OFRangeValue
@synthesize rangeValue = _range;

- (instancetype)initWithRange: (of_range_t)range
{
	self = [super init];

	_range = range;

	return self;
}

- (const char *)objCType
{
	return @encode(of_range_t);
}

- (void)getValue: (void *)value
	    size: (size_t)size
{
	if (size != sizeof(_range))
		@throw [OFOutOfRangeException exception];

	memcpy(value, &_range, sizeof(_range));
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<OFValue: of_range_t { %zu, %zu }>",
	    _range.location, _range.length];
}
@end
