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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFValue OFValue.h ObjFW/OFValue.h
 *
 * @brief A class for storing arbitrary values in an object.
 */
@interface OFValue: OFObject <OFCopying>
{
	OF_RESERVE_IVARS(OFValue, 4)
}

/**
 * @brief The ObjC type encoding of the value.
 */
@property (readonly, nonatomic) const char *objCType;

/**
 * @brief The value as a pointer to void.
 *
 * @throw OFOutOfRangeException The value is not pointer-sized
 */
@property (readonly, nonatomic) void *pointerValue;

/**
 * @brief The value as a non-retained object.
 *
 * @throw OFOutOfRangeException The value is not pointer-sized
 */
@property (readonly, nonatomic) id nonretainedObjectValue;

/**
 * @brief The value as an OFRange.
 *
 * @throw OFOutOfRangeException The value is not OFRange-sized
 */
@property (readonly, nonatomic) OFRange rangeValue;

/**
 * @brief The value as an OFPoint.
 *
 * @throw OFOutOfRangeException The value is not OFPoint-sized
 */
@property (readonly, nonatomic) OFPoint pointValue;

/**
 * @brief The value as an OFSize.
 *
 * @throw OFOutOfRangeException The value is not OFSize-sized
 */
@property (readonly, nonatomic) OFSize sizeValue;

/**
 * @brief The value as a OFRect.
 *
 * @throw OFOutOfRangeException The value is not OFRect-sized
 */
@property (readonly, nonatomic) OFRect rectValue;

/**
 * @brief Creates a new, autorelease OFValue with the specified bytes of the
 *	  specified type.
 *
 * @param bytes The bytes containing the value
 * @param objCType The ObjC type encoding for the value
 * @return A new, autoreleased OFValue
 */
+ (instancetype)valueWithBytes: (const void *)bytes
		      objCType: (const char *)objCType;

/**
 * @brief Creates a new, autoreleased OFValue containing the specified pointer.
 *
 * Only the raw value of the pointer is stored and no data will be copied.
 *
 * @param pointer The pointer the OFValue should contain
 * @return A new, autoreleased OFValue
 */
+ (instancetype)valueWithPointer: (const void *)pointer;

/**
 * @brief Creates a new, autoreleased OFValue containing the specified
 *	  non-retained object.
 *
 * The object is not retained, which makes this useful for storing objects in
 * collections without retaining them.
 *
 * @param object The object the OFValue should contain without retaining it
 * @return A new, autoreleased OFValue
 */
+ (instancetype)valueWithNonretainedObject: (id)object;

/**
 * @brief Creates a new, autoreleased OFValue containing the specified range.
 *
 * @param range The range the OFValue should contain
 * @return A new, autoreleased OFValue
 */
+ (instancetype)valueWithRange: (OFRange)range;

/**
 * @brief Creates a new, autoreleased OFValue containing the specified point.
 *
 * @param point The point the OFValue should contain
 * @return A new, autoreleased OFValue
 */
+ (instancetype)valueWithPoint: (OFPoint)point;

/**
 * @brief Creates a new, autoreleased OFValue containing the specified size.
 *
 * @param size The size the OFValue should contain
 * @return A new, autoreleased OFValue
 */
+ (instancetype)valueWithSize: (OFSize)size;

/**
 * @brief Creates a new, autoreleased OFValue containing the specified
 *	  rectangle.
 *
 * @param rect The rectangle the OFValue should contain
 * @return A new, autoreleased OFValue
 */
+ (instancetype)valueWithRect: (OFRect)rect;

/**
 * @brief Initializes an already allocated OFValue with the specified bytes of
 *	  the specified type.
 *
 * @param bytes The bytes containing the value
 * @param objCType The ObjC type encoding for the value
 * @return An initialized OFValue
 */
- (instancetype)initWithBytes: (const void *)bytes
		     objCType: (const char *)objCType;

/**
 * @brief Gets the value.
 *
 * @param value The buffer to copy the value into
 * @param size The size of the value
 * @throw OFOutOfRangeException The specified size does not match the value
 */
- (void)getValue: (void *)value size: (size_t)size;
@end

OF_ASSUME_NONNULL_END

#if !defined(NSINTEGER_DEFINED) && !__has_feature(modules)
/* Required for array literals to work */
@compatibility_alias NSValue OFValue;
#endif
