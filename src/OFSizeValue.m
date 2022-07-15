/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#import "OFSizeValue.h"
#import "OFMethodSignature.h"
#import "OFString.h"

#import "OFOutOfRangeException.h"

@implementation OFSizeValue
@synthesize sizeValue = _size;

- (instancetype)initWithSize: (OFSize)size
{
	self = [super init];

	_size = size;

	return self;
}

- (const char *)objCType
{
	return @encode(OFSize);
}

- (void)getValue: (void *)value size: (size_t)size
{
	if (size != sizeof(_size))
		@throw [OFOutOfRangeException exception];

	memcpy(value, &_size, sizeof(_size));
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<OFValue: OFSize { %f, %f }>", _size.width, _size.height];
}
@end
