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

#import "OFRectangleValue.h"
#import "OFMethodSignature.h"
#import "OFString.h"

#import "OFOutOfRangeException.h"

@implementation OFRectangleValue
@synthesize rectangleValue = _rectangle;

- (instancetype)initWithRectangle: (of_rectangle_t)rectangle
{
	self = [super init];

	_rectangle = rectangle;

	return self;
}

- (const char *)objCType
{
	return @encode(of_rectangle_t);
}

- (void)getValue: (void *)value
	    size: (size_t)size
{
	if (size != sizeof(_rectangle))
		@throw [OFOutOfRangeException exception];

	memcpy(value, &_rectangle, sizeof(_rectangle));
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<OFValue: of_rectangle_t { %f, %f, %f, %f }>",
	    _rectangle.origin.x, _rectangle.origin.y,
	    _rectangle.size.width, _rectangle.size.height];
}
@end
