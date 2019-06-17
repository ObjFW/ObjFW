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

#import "OFPointerValue.h"
#import "OFMethodSignature.h"

#import "OFOutOfRangeException.h"

@implementation OFPointerValue
@synthesize pointerValue = _pointer;

- (instancetype)initWithPointer: (const void *)pointer
{
	self = [super init];

	_pointer = (void *)pointer;

	return self;
}

- (const char *)objCType
{
	return @encode(void *);
}

- (void)getValue: (void *)value
	    size: (size_t)size
{
	if (size != sizeof(_pointer))
		@throw [OFOutOfRangeException exception];

	memcpy(value, &_pointer, sizeof(_pointer));
}

- (id)nonretainedObjectValue
{
	return _pointer;
}
@end
