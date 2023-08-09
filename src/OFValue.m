/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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
#import "OFConcreteValue.h"
#import "OFMethodSignature.h"
#import "OFString.h"

#import "OFOutOfMemoryException.h"

static struct {
	Class isa;
} placeholder;

@interface OFPlaceholderValue: OFValue
@end

@implementation OFPlaceholderValue
#ifdef __clang__
/* We intentionally don't call into super, so silence the warning. */
# pragma clang diagnostic push
# pragma clang diagnostic ignored "-Wunknown-pragmas"
# pragma clang diagnostic ignored "-Wobjc-designated-initializers"
#endif
- (instancetype)initWithBytes: (const void *)bytes
		     objCType: (const char *)objCType
{
	return (id)[[OFConcreteValue alloc] initWithBytes: bytes
						 objCType: objCType];
}
#ifdef __clang__
# pragma clang diagnostic pop
#endif

OF_SINGLETON_METHODS
@end

@implementation OFValue
+ (void)initialize
{
	if (self == [OFValue class])
		object_setClass((id)&placeholder, [OFPlaceholderValue class]);
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
	return [[[OFValue alloc] initWithBytes: bytes
				      objCType: objCType] autorelease];
}

+ (instancetype)valueWithPointer: (const void *)pointer
{
	return [[[OFValue alloc]
	    initWithBytes: &pointer
		 objCType: @encode(const void *)] autorelease];
}

+ (instancetype)valueWithNonretainedObject: (id)object
{
	return [[[OFValue alloc] initWithBytes: &object
				      objCType: @encode(id)] autorelease];
}

+ (instancetype)valueWithRange: (OFRange)range
{
	return [[[OFValue alloc] initWithBytes: &range
				      objCType: @encode(OFRange)] autorelease];
}

+ (instancetype)valueWithPoint: (OFPoint)point
{
	return [[[OFValue alloc] initWithBytes: &point
				      objCType: @encode(OFPoint)] autorelease];
}

+ (instancetype)valueWithSize: (OFSize)size
{
	return [[[OFValue alloc] initWithBytes: &size
				      objCType: @encode(OFSize)] autorelease];
}

+ (instancetype)valueWithRect: (OFRect)rect
{
	return [[[OFValue alloc] initWithBytes: &rect
				      objCType: @encode(OFRect)] autorelease];
}

- (instancetype)initWithBytes: (const void *)bytes
		     objCType: (const char *)objCType
{
	if ([self isMemberOfClass: [OFValue class]]) {
		@try {
			[self doesNotRecognizeSelector: _cmd];
		} @catch (id e) {
			[self release];
			@throw e;
		}

		abort();
	}

	return [super init];
}

- (instancetype)init
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
	const char *objCType = self.objCType;
	OFMutableString *ret;
	size_t size;
	unsigned char *value;

	if (strcmp(objCType, @encode(OFRange)) == 0 ||
	    strcmp(objCType, @encode(const OFRange)) == 0) {
		OFRange rangeValue;
		[self getValue: &rangeValue size: sizeof(rangeValue)];
		return [OFString stringWithFormat:
		    @"<OFValue: OFRange { %zd, %zd }>",
		    rangeValue.location, rangeValue.length];
	} else if (strcmp(objCType, @encode(OFPoint)) == 0 ||
	    strcmp(objCType, @encode(const OFPoint)) == 0) {
		OFPoint pointValue;
		[self getValue: &pointValue size: sizeof(pointValue)];
		return [OFString stringWithFormat:
		    @"<OFValue: OFPoint { %g, %g }>",
		    pointValue.x, pointValue.y];
	} else if (strcmp(objCType, @encode(OFSize)) == 0 ||
	    strcmp(objCType, @encode(const OFSize)) == 0) {
		OFSize sizeValue;
		[self getValue: &sizeValue size: sizeof(sizeValue)];
		return [OFString stringWithFormat:
		    @"<OFValue: OFSize { %g, %g }>",
		    sizeValue.width, sizeValue.height];
	} else if (strcmp(objCType, @encode(OFRect)) == 0 ||
	    strcmp(objCType, @encode(const OFRect)) == 0) {
		OFRect rectValue;
		[self getValue: &rectValue size: sizeof(rectValue)];
		return [OFString stringWithFormat:
		    @"<OFValue: OFRect { %g, %g, %g, %g }>",
		    rectValue.origin.x, rectValue.origin.y,
		    rectValue.size.width, rectValue.size.height];
	}

	ret = [OFMutableString stringWithString: @"<OFValue: "];
	size = OFSizeOfTypeEncoding(objCType);
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
