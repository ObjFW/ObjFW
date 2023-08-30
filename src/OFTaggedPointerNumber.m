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

#import "OFTaggedPointerNumber.h"

#import "OFInvalidFormatException.h"

#ifdef OF_OBJFW_RUNTIME
enum Tag {
	tagChar,
	tagShort,
	tagInt,
	tagLong,
	tagLongLong,
	tagUnsignedChar,
	tagUnsignedShort,
	tagUnsignedInt,
	tagUnsignedLong,
	tagUnsignedLongLong,
};
static const uintptr_t tagMask = (1 << OFTaggedPointerNumberTagBits) - 1;
static int numberTag;

@implementation OFTaggedPointerNumber
+ (void)initialize
{
	if (self == [OFTaggedPointerNumber class])
		numberTag = objc_registerTaggedPointerClass(self);
}

+ (OFTaggedPointerNumber *)numberWithChar: (signed char)value
{
	return objc_createTaggedPointer(numberTag,
	    ((uintptr_t)(unsigned char)value << OFTaggedPointerNumberTagBits) |
	    tagChar);
}

+ (OFTaggedPointerNumber *)numberWithShort: (short)value
{
	return objc_createTaggedPointer(numberTag,
	    ((uintptr_t)(unsigned short)value << OFTaggedPointerNumberTagBits) |
	    tagShort);
}

+ (OFTaggedPointerNumber *)numberWithInt: (int)value
{
	return objc_createTaggedPointer(numberTag,
	    ((uintptr_t)(unsigned int)value << OFTaggedPointerNumberTagBits) |
	    tagInt);
}

+ (OFTaggedPointerNumber *)numberWithLong: (long)value
{
	return objc_createTaggedPointer(numberTag,
	    ((uintptr_t)(unsigned long)value << OFTaggedPointerNumberTagBits) |
	    tagLong);
}

+ (OFTaggedPointerNumber *)numberWithLongLong: (long long)value
{
	return objc_createTaggedPointer(numberTag,
	    ((uintptr_t)(unsigned long long)value <<
	    OFTaggedPointerNumberTagBits) | tagLongLong);
}

+ (OFTaggedPointerNumber *)numberWithUnsignedChar: (unsigned char)value
{
	return objc_createTaggedPointer(numberTag,
	    ((uintptr_t)value << OFTaggedPointerNumberTagBits) |
	    tagUnsignedChar);
}

+ (OFTaggedPointerNumber *)numberWithUnsignedShort: (unsigned short)value
{
	return objc_createTaggedPointer(numberTag,
	    ((uintptr_t)value << OFTaggedPointerNumberTagBits) |
	    tagUnsignedShort);
}

+ (OFTaggedPointerNumber *)numberWithUnsignedInt: (unsigned int)value
{
	return objc_createTaggedPointer(numberTag,
	    ((uintptr_t)value << OFTaggedPointerNumberTagBits) |
	    tagUnsignedInt);
}

+ (OFTaggedPointerNumber *)numberWithUnsignedLong: (unsigned long)value
{
	return objc_createTaggedPointer(numberTag,
	    ((uintptr_t)value << OFTaggedPointerNumberTagBits) |
	    tagUnsignedLong);
}

+ (OFTaggedPointerNumber *)numberWithUnsignedLongLong: (unsigned long long)value
{
	return objc_createTaggedPointer(numberTag,
	    ((uintptr_t)value << OFTaggedPointerNumberTagBits) |
	    tagUnsignedLongLong);
}

- (const char *)objCType
{
	uintptr_t value = object_getTaggedPointerValue(self);

	switch (value & tagMask) {
	case tagChar:
		return @encode(signed char);
	case tagShort:
		return @encode(short);
	case tagInt:
		return @encode(int);
	case tagLong:
		return @encode(long);
	case tagLongLong:
		return @encode(long long);
	case tagUnsignedChar:
		return @encode(unsigned char);
	case tagUnsignedShort:
		return @encode(unsigned short);
	case tagUnsignedInt:
		return @encode(unsigned int);
	case tagUnsignedLong:
		return @encode(unsigned long);
	case tagUnsignedLongLong:
		return @encode(unsigned long long);
	default:
		@throw [OFInvalidFormatException exception];
	}
}

# define RETURN_VALUE						\
	uintptr_t value = object_getTaggedPointerValue(self);	\
								\
	switch (value & tagMask) {				\
	case tagChar:						\
		return (signed char)(unsigned char)		\
		    (value >> OFTaggedPointerNumberTagBits);	\
	case tagShort:						\
		return (short)(unsigned short)			\
		    (value >> OFTaggedPointerNumberTagBits);	\
	case tagInt:						\
		return (int)(unsigned int)			\
		    (value >> OFTaggedPointerNumberTagBits);	\
	case tagLong:						\
		return (long)(unsigned long)			\
		    (value >> OFTaggedPointerNumberTagBits);	\
	case tagLongLong:					\
		return (long long)(unsigned long long)		\
		    (value >> OFTaggedPointerNumberTagBits);	\
	case tagUnsignedChar:					\
		return (unsigned char)				\
		    (value >> OFTaggedPointerNumberTagBits);	\
	case tagUnsignedShort:					\
		return (unsigned short)				\
		    (value >> OFTaggedPointerNumberTagBits);	\
	case tagUnsignedInt:					\
		return (unsigned int)				\
		    (value >> OFTaggedPointerNumberTagBits);	\
	case tagUnsignedLong:					\
		return (unsigned long)				\
		    (value >> OFTaggedPointerNumberTagBits);	\
	case tagUnsignedLongLong:				\
		return (unsigned long long)			\
		    (value >> OFTaggedPointerNumberTagBits);	\
	default:						\
		@throw [OFInvalidFormatException exception];	\
	}
- (long long)longLongValue
{
	RETURN_VALUE
}

- (unsigned long long)unsignedLongLongValue
{
	RETURN_VALUE
}

- (double)doubleValue
{
	RETURN_VALUE
}
# undef RETURN_VALUE

OF_SINGLETON_METHODS
@end
#endif
