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

#import "OFDimensionValue.h"
#import "OFMethodSignature.h"
#import "OFString.h"

#import "OFOutOfRangeException.h"

@implementation OFDimensionValue
@synthesize dimensionValue = _dimension;

- (instancetype)initWithDimension: (of_dimension_t)dimension
{
	self = [super init];

	_dimension = dimension;

	return self;
}

- (const char *)objCType
{
	return @encode(of_dimension_t);
}

- (void)getValue: (void *)value size: (size_t)size
{
	if (size != sizeof(_dimension))
		@throw [OFOutOfRangeException exception];

	memcpy(value, &_dimension, sizeof(_dimension));
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<OFValue: of_dimension_t { %f, %f }>",
	    _dimension.width, _dimension.height];
}
@end
