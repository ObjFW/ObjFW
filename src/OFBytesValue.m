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

#import "OFBytesValue.h"
#import "OFMethodSignature.h"

#import "OFOutOfRangeException.h"

@implementation OFBytesValue
@synthesize objCType = _objCType;

- (instancetype)initWithBytes: (const void *)bytes
		     objCType: (const char *)objCType
{
	self = [super init];

	@try {
		_size = of_sizeof_type_encoding(objCType);
		_objCType = objCType;
		_bytes = [self allocMemoryWithSize: _size];

		memcpy(_bytes, bytes, _size);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)getValue: (void *)value
	    size: (size_t)size
{
	if (size != _size)
		@throw [OFOutOfRangeException exception];

	memcpy(value, _bytes, _size);
}
@end
