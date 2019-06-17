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

#import "OFNonretainedObjectValue.h"
#import "OFMethodSignature.h"

#import "OFOutOfRangeException.h"

@implementation OFNonretainedObjectValue
@synthesize nonretainedObjectValue = _object;

- (instancetype)initWithNonretainedObject: (id)object
{
	self = [super init];

	_object = object;

	return self;
}

- (const char *)objCType
{
	return @encode(id);
}

- (void)getValue: (void *)value
	    size: (size_t)size
{
	if (size != sizeof(_object))
		@throw [OFOutOfRangeException exception];

	memcpy(value, &_object, sizeof(_object));
}

- (void *)pointerValue
{
	return _object;
}
@end
