/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
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
	return objc_autoreleaseReturnValue(
	    [[OFValue alloc] initWithBytes: bytes
				  objCType: objCType]);
}

+ (instancetype)valueWithPointer: (const void *)pointer
{
	return objc_autoreleaseReturnValue(
	    [[OFValue alloc] initWithBytes: &pointer
				  objCType: @encode(const void *)]);
}

+ (instancetype)valueWithNonretainedObject: (id)object
{
	return objc_autoreleaseReturnValue(
	    [[OFValue alloc] initWithBytes: &object
				  objCType: @encode(id)]);
}

+ (instancetype)valueWithRange: (OFRange)range
{
	return objc_autoreleaseReturnValue(
	    [[OFValue alloc] initWithBytes: &range
				  objCType: @encode(OFRange)]);
}

+ (instancetype)valueWithPoint: (OFPoint)point
{
	return objc_autoreleaseReturnValue(
	    [[OFValue alloc] initWithBytes: &point
				  objCType: @encode(OFPoint)]);
}

+ (instancetype)valueWithSize: (OFSize)size
{
	return objc_autoreleaseReturnValue(
	    [[OFValue alloc] initWithBytes: &size
				  objCType: @encode(OFSize)]);
}

+ (instancetype)valueWithRect: (OFRect)rect
{
	return objc_autoreleaseReturnValue(
	    [[OFValue alloc] initWithBytes: &rect
				  objCType: @encode(OFRect)]);
}

+ (instancetype)valueWithVector3D: (OFVector3D)vector3D
{
	return objc_autoreleaseReturnValue(
	    [[OFValue alloc] initWithBytes: &vector3D
				  objCType: @encode(OFVector3D)]);
}

+ (instancetype)valueWithVector4D: (OFVector4D)vector4D
{
	return objc_autoreleaseReturnValue(
	    [[OFValue alloc] initWithBytes: &vector4D
				  objCType: @encode(OFVector4D)]);
}

- (instancetype)initWithBytes: (const void *)bytes
		     objCType: (const char *)objCType
{
	if ([self isMemberOfClass: [OFValue class]]) {
		@try {
			[self doesNotRecognizeSelector: _cmd];
		} @catch (id e) {
			objc_release(self);
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
	return objc_retain(self);
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

- (OFVector3D)vector3DValue
{
	OFVector3D ret;
	[self getValue: &ret size: sizeof(ret)];
	return ret;
}

- (OFVector4D)vector4DValue
{
	OFVector4D ret;
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
	} else if (strcmp(objCType, @encode(OFVector3D)) == 0 ||
	    strcmp(objCType, @encode(const OFVector3D)) == 0) {
		OFVector3D vector3DValue;
		[self getValue: &vector3DValue size: sizeof(vector3DValue)];
		return [OFString stringWithFormat:
		    @"<OFValue: OFVector3D { %g, %g, %g }>",
		    vector3DValue.x, vector3DValue.y, vector3DValue.z];
	} else if (strcmp(objCType, @encode(OFVector4D)) == 0 ||
	    strcmp(objCType, @encode(const OFVector4D)) == 0) {
		OFVector4D vector4DValue;
		[self getValue: &vector4DValue size: sizeof(vector4DValue)];
		return [OFString stringWithFormat:
		    @"<OFValue: OFVector4D { %g, %g, %g, %g }>",
		    vector4DValue.x, vector4DValue.y, vector4DValue.z,
		    vector4DValue.w];
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
