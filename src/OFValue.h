/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFValue OFValue.h ObjFW/ObjFW.h
 *
 * @brief A class for storing arbitrary values in an object.
 */
@interface OFValue: OFObject <OFCopying>
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
 * @brief The value as an OFRect.
 *
 * @throw OFOutOfRangeException The value is not OFRect-sized
 */
@property (readonly, nonatomic) OFRect rectValue;

/**
 * @brief The value as an OFVector3D.
 *
 * @throw OFOutOfRangeException The value is not OFVector3D-sized
 */
@property (readonly, nonatomic) OFVector3D vector3DValue;

/**
 * @brief The value as an OFVector4D.
 *
 * @throw OFOutOfRangeException The value is not OFVector4D-sized
 */
@property (readonly, nonatomic) OFVector4D vector4DValue;

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
 * @brief Creates a new, autoreleased OFValue containing the specified
 *	  3D vector.
 *
 * @param vector3D The 3D vector the OFValue should contain
 * @return A new, autoreleased OFValue
 */
+ (instancetype)valueWithVector3D: (OFVector3D)vector3D;

/**
 * @brief Creates a new, autoreleased OFValue containing the specified
 *	  4D vector.
 *
 * @param vector4D The 4D vector the OFValue should contain
 * @return A new, autoreleased OFValue
 */
+ (instancetype)valueWithVector4D: (OFVector4D)vector4D;

/**
 * @brief Initializes an already allocated OFValue with the specified bytes of
 *	  the specified type.
 *
 * @param bytes The bytes containing the value
 * @param objCType The ObjC type encoding for the value
 * @return An initialized OFValue
 */
- (instancetype)initWithBytes: (const void *)bytes
		     objCType: (const char *)objCType OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;

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

#ifndef NSINTEGER_DEFINED
/* Required for array literals to work */
@compatibility_alias NSValue OFValue;
#endif
