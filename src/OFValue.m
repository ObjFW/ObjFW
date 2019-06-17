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

#import "OFValue.h"
#import "OFBytesValue.h"
#import "OFDimensionValue.h"
#import "OFMethodSignature.h"
#import "OFNonretainedObjectValue.h"
#import "OFPointValue.h"
#import "OFPointerValue.h"
#import "OFRangeValue.h"
#import "OFRectangleValue.h"
#import "OFString.h"

#import "OFOutOfMemoryException.h"

static struct {
	Class isa;
} placeholder;

@interface OFValuePlaceholder: OFValue
@end

@implementation OFValuePlaceholder
- (instancetype)initWithBytes: (const void *)bytes
		     objCType: (const char *)objCType
{
	return (id)[[OFBytesValue alloc] initWithBytes: bytes
					      objCType: objCType];
}

- (instancetype)initWithPointer: (const void *)pointer
{
	return (id)[[OFPointerValue alloc] initWithPointer: pointer];
}

- (instancetype)initWithNonretainedObject: (id)object
{
	return (id)[[OFNonretainedObjectValue alloc]
	    initWithNonretainedObject: object];
}

- (instancetype)initWithRange: (of_range_t)range
{
	return (id)[[OFRangeValue alloc] initWithRange: range];
}

- (instancetype)initWithPoint: (of_point_t)point
{
	return (id)[[OFPointValue alloc] initWithPoint: point];
}

- (instancetype)initWithDimension: (of_dimension_t)dimension
{
	return (id)[[OFDimensionValue alloc] initWithDimension: dimension];
}

- (instancetype)initWithRectangle: (of_rectangle_t)rectangle
{
	return (id)[[OFRectangleValue alloc] initWithRectangle: rectangle];
}
@end

@implementation OFValue
+ (void)initialize
{
	if (self == [OFValue class])
		placeholder.isa = [OFValuePlaceholder class];
}

+ (instancetype)alloc
{
	if (self == [OFValue class])
		return (id)&placeholder;

	return [super alloc];
}

+ (instancetype)valueWithBytes: (const void *)bytes
		      objCType: (const char *)objCType
{
	return [[[self alloc] initWithBytes: bytes
				   objCType: objCType] autorelease];
}

+ (instancetype)valueWithPointer: (const void *)pointer
{
	return [[[self alloc] initWithPointer: pointer] autorelease];
}

+ (instancetype)valueWithNonretainedObject: (id)object
{
	return [[[self alloc] initWithNonretainedObject: object] autorelease];
}

+ (instancetype)valueWithRange: (of_range_t)range
{
	return [[[self alloc] initWithRange: range] autorelease];
}

+ (instancetype)valueWithPoint: (of_point_t)point
{
	return [[[self alloc] initWithPoint: point] autorelease];
}

+ (instancetype)valueWithDimension: (of_dimension_t)dimension
{
	return [[[self alloc] initWithDimension: dimension] autorelease];
}

+ (instancetype)valueWithRectangle: (of_rectangle_t)rectangle
{
	return [[[self alloc] initWithRectangle: rectangle] autorelease];
}

- (instancetype)initWithBytes: (const void *)bytes
		     objCType: (const char *)objCType
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithPointer: (const void *)pointer
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithNonretainedObject: (id)object
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithRange: (of_range_t)range
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithPoint: (of_point_t)point
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithDimension: (of_dimension_t)dimension
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithRectangle: (of_rectangle_t)rectangle
{
	OF_INVALID_INIT_METHOD
}

- (bool)isEqual: (id)object
{
	const char *objCType;
	size_t size;
	void *value, *otherValue;

	if (![object isKindOfClass: [OFValue class]])
		return false;

	objCType = self.objCType;

	if (strcmp([object objCType], objCType) != 0)
		return false;

	size = of_sizeof_type_encoding(objCType);

	if ((value = malloc(size)) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: size];

	if ((otherValue = malloc(size)) == NULL) {
		free(value);
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: size];
	}

	@try {
		[self getValue: value
			  size: size];
		[object getValue: otherValue
			    size: size];

		return (memcmp(value, otherValue, size) == 0);
	} @finally {
		free(value);
		free(otherValue);
	}
}

- (uint32_t)hash
{
	size_t size = of_sizeof_type_encoding(self.objCType);
	unsigned char *value;
	uint32_t hash;

	if ((value = malloc(size)) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: size];

	@try {
		[self getValue: value
			  size: size];

		OF_HASH_INIT(hash);

		for (size_t i = 0; i < size; i++)
			OF_HASH_ADD(hash, value[i]);

		OF_HASH_FINALIZE(hash);
	} @finally {
		free(value);
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

- (void)getValue: (void *)value
	    size: (size_t)size
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void *)pointerValue
{
	void *ret;

	[self getValue: &ret
		  size: sizeof(ret)];

	return ret;
}

- (id)nonretainedObjectValue
{
	id ret;

	[self getValue: &ret
		  size: sizeof(ret)];

	return ret;
}

- (of_range_t)rangeValue
{
	of_range_t ret;

	[self getValue: &ret
		  size: sizeof(ret)];

	return ret;
}

- (of_point_t)pointValue
{
	of_point_t ret;

	[self getValue: &ret
		  size: sizeof(ret)];

	return ret;
}

- (of_dimension_t)dimensionValue
{
	of_dimension_t ret;

	[self getValue: &ret
		  size: sizeof(ret)];

	return ret;
}

- (of_rectangle_t)rectangleValue
{
	of_rectangle_t ret;

	[self getValue: &ret
		  size: sizeof(ret)];

	return ret;
}

- (OFString *)description
{
	OFMutableString *ret =
	    [OFMutableString stringWithString: @"<OFValue: "];
	size_t size = of_sizeof_type_encoding(self.objCType);
	unsigned char *value;

	if ((value = malloc(size)) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: size];

	@try {
		[self getValue: value
			  size: size];

		for (size_t i = 0; i < size; i++) {
			if (i > 0)
				[ret appendString: @" "];

			[ret appendFormat: @"%02x", value[i]];
		}
	} @finally {
		free(value);
	}

	[ret appendString: @">"];

	[ret makeImmutable];
	return ret;
}
@end
