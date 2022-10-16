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

#include "config.h"

#import "OFValue.h"
#import "OFBytesValue.h"
#import "OFMethodSignature.h"
#import "OFNonretainedObjectValue.h"
#import "OFPointValue.h"
#import "OFPointerValue.h"
#import "OFRangeValue.h"
#import "OFRectValue.h"
#import "OFSizeValue.h"
#import "OFString.h"

#import "OFOutOfMemoryException.h"

@implementation OFValue
+ (instancetype)alloc
{
	if (self == [OFValue class])
		return [OFBytesValue alloc];

	return [super alloc];
}

+ (instancetype)valueWithBytes: (const void *)bytes
		      objCType: (const char *)objCType
{
	return [[[OFBytesValue alloc] initWithBytes: bytes
					   objCType: objCType] autorelease];
}

+ (instancetype)valueWithPointer: (const void *)pointer
{
	return [[[OFPointerValue alloc] initWithPointer: pointer] autorelease];
}

+ (instancetype)valueWithNonretainedObject: (id)object
{
	return [[[OFNonretainedObjectValue alloc]
	    initWithNonretainedObject: object] autorelease];
}

+ (instancetype)valueWithRange: (OFRange)range
{
	return [[[OFRangeValue alloc] initWithRange: range] autorelease];
}

+ (instancetype)valueWithPoint: (OFPoint)point
{
	return [[[OFPointValue alloc] initWithPoint: point] autorelease];
}

+ (instancetype)valueWithSize: (OFSize)size
{
	return [[[OFSizeValue alloc] initWithSize: size] autorelease];
}

+ (instancetype)valueWithRect: (OFRect)rect
{
	return [[[OFRectValue alloc] initWithRect: rect] autorelease];
}

- (instancetype)initWithBytes: (const void *)bytes
		     objCType: (const char *)objCType
{
	OF_INVALID_INIT_METHOD
}

- (bool)isEqual: (id)object
{
	const char *objCType;
	size_t size;
	void *value, *otherValue;
	bool ret;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFValue class]])
		return false;

	objCType = self.objCType;

	if (strcmp([object objCType], objCType) != 0)
		return false;

	size = OFSizeOfTypeEncoding(objCType);

	value = OFAllocMemory(1, size);
	@try {
		otherValue = OFAllocMemory(1, size);
	} @catch (id e) {
		OFFreeMemory(value);
		@throw e;
	}

	@try {
		[self getValue: value size: size];
		[object getValue: otherValue size: size];
		ret = (memcmp(value, otherValue, size) == 0);
	} @finally {
		OFFreeMemory(value);
		OFFreeMemory(otherValue);
	}

	return ret;
}

- (unsigned long)hash
{
	size_t size = OFSizeOfTypeEncoding(self.objCType);
	unsigned char *value;
	unsigned long hash;

	value = OFAllocMemory(1, size);
	@try {
		[self getValue: value size: size];

		OFHashInit(&hash);

		for (size_t i = 0; i < size; i++)
			OFHashAddByte(&hash, value[i]);

		OFHashFinalize(&hash);
	} @finally {
		OFFreeMemory(value);
	}

	return hash;
}

- (id)copy
{
	return [self retain];
}

- (const char *)objCType
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)getValue: (void *)value size: (size_t)size
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void *)pointerValue
{
	void *ret;
	[self getValue: &ret size: sizeof(ret)];
	return ret;
}

- (id)nonretainedObjectValue
{
	id ret;
	[self getValue: &ret size: sizeof(ret)];
	return ret;
}

- (OFRange)rangeValue
{
	OFRange ret;
	[self getValue: &ret size: sizeof(ret)];
	return ret;
}

- (OFPoint)pointValue
{
	OFPoint ret;
	[self getValue: &ret size: sizeof(ret)];
	return ret;
}

- (OFSize)sizeValue
{
	OFSize ret;
	[self getValue: &ret size: sizeof(ret)];
	return ret;
}

- (OFRect)rectValue
{
	OFRect ret;
	[self getValue: &ret size: sizeof(ret)];
	return ret;
}

- (OFString *)description
{
	OFMutableString *ret =
	    [OFMutableString stringWithString: @"<OFValue: "];
	size_t size = OFSizeOfTypeEncoding(self.objCType);
	unsigned char *value;

	value = OFAllocMemory(1, size);
	@try {
		[self getValue: value size: size];

		for (size_t i = 0; i < size; i++) {
			if (i > 0)
				[ret appendString: @" "];

			[ret appendFormat: @"%02x", value[i]];
		}
	} @finally {
		OFFreeMemory(value);
	}

	[ret appendString: @">"];

	[ret makeImmutable];
	return ret;
}
@end
