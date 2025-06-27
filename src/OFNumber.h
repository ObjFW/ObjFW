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

#ifndef __STDC_LIMIT_MACROS
# define __STDC_LIMIT_MACROS
#endif
#ifndef __STDC_CONSTANT_MACROS
# define __STDC_CONSTANT_MACROS
#endif

#include "objfw-defs.h"

#ifdef OF_HAVE_SYS_TYPES_H
# include <sys/types.h>
#endif

#import "OFASN1DERRepresentation.h"
#import "OFJSONRepresentation.h"
#import "OFMessagePackRepresentation.h"
#import "OFValue.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

/**
 * @class OFNumber OFNumber.h ObjFW/ObjFW.h
 *
 * @brief Provides a way to store a number in an object.
 */
@interface OFNumber: OFValue <OFComparing, OFASN1DERRepresentation,
    OFJSONRepresentation, OFMessagePackRepresentation>
/**
 * @brief The OFNumber as a `bool`.
 */
@property (readonly, nonatomic) bool boolValue;

/**
 * @brief The OFNumber as a `signed char`.
 *
 * @throw OFOutOfRangeException The value is too big or too small to fit into a
 *				`signed char`
 */
@property (readonly, nonatomic) signed char charValue;

/**
 * @brief The OFNumber as a `short`.
 *
 * @throw OFOutOfRangeException The value is too big or too small to fit into a
 *				`short`
 */
@property (readonly, nonatomic) short shortValue;

/**
 * @brief The OFNumber as an `int`.
 *
 * @throw OFOutOfRangeException The value is too big or too small to fit into an
 *				`int`
 */
@property (readonly, nonatomic) int intValue;

/**
 * @brief The OFNumber as a `long`.
 *
 * @throw OFOutOfRangeException The value is too big or too small to fit into a
 *				`long`
 */
@property (readonly, nonatomic) long longValue;

/**
 * @brief The OFNumber as a `long long`.
 *
 * @throw OFOutOfRangeException The value is too big or too small to fit into a
 *				`long long`
 */
@property (readonly, nonatomic) long long longLongValue;

/**
 * @brief The OFNumber as an `unsigned char`.
 *
 * @throw OFOutOfRangeException The value is too big or too small to fit into an
 *				`unsigned char`
 */
@property (readonly, nonatomic) unsigned char unsignedCharValue;

/**
 * @brief The OFNumber as an `unsigned short`.
 *
 * @throw OFOutOfRangeException The value is too big or too small to fit into an
 *				`unsigned short`
 */
@property (readonly, nonatomic) unsigned short unsignedShortValue;

/**
 * @brief The OFNumber as an `unsigned int`.
 *
 * @throw OFOutOfRangeException The value is too big or too small to fit into an
 *				`unsigned int`
 */
@property (readonly, nonatomic) unsigned int unsignedIntValue;

/**
 * @brief The OFNumber as an `unsigned long`.
 *
 * @throw OFOutOfRangeException The value is too big or too small to fit into an
 *				`unsigned long`
 */
@property (readonly, nonatomic) unsigned long unsignedLongValue;

/**
 * @brief The OFNumber as an `unsigned long long`.
 *
 * @throw OFOutOfRangeException The value is too big or too small to fit into an
 *				`unsigned long long`
 */
@property (readonly, nonatomic) unsigned long long unsignedLongLongValue;

/**
 * @brief The OFNumber as a `float`.
 */
@property (readonly, nonatomic) float floatValue;

/**
 * @brief The OFNumber as a `double`.
 */
@property (readonly, nonatomic) double doubleValue;

/**
 * @brief The OFNumber as a string.
 */
@property (readonly, nonatomic) OFString *stringValue;

+ (instancetype)valueWithPointer: (const void *)pointer OF_UNAVAILABLE;
+ (instancetype)valueWithNonretainedObject: (id)object OF_UNAVAILABLE;
+ (instancetype)valueWithRange: (OFRange)range OF_UNAVAILABLE;
+ (instancetype)valueWithPoint: (OFPoint)point OF_UNAVAILABLE;
+ (instancetype)valueWithSize: (OFSize)size OF_UNAVAILABLE;
+ (instancetype)valueWithRect: (OFRect)rect OF_UNAVAILABLE;

/**
 * @brief Creates a new OFNumber with the specified `bool`.
 *
 * @param value The `bool` value which the OFNumber should contain
 * @return A new autoreleased OFNumber
 */
+ (instancetype)numberWithBool: (bool)value;

/**
 * @brief Creates a new OFNumber with the specified `signed char`.
 *
 * @param value The `signed char` value which the OFNumber should contain
 * @return A new autoreleased OFNumber
 */
+ (instancetype)numberWithChar: (signed char)value;

/**
 * @brief Creates a new OFNumber with the specified `short`.
 *
 * @param value The `short` value which the OFNumber should contain
 * @return A new autoreleased OFNumber
 */
+ (instancetype)numberWithShort: (short)value;

/**
 * @brief Creates a new OFNumber with the specified `int`.
 *
 * @param value The `int` value which the OFNumber should contain
 * @return A new autoreleased OFNumber
 */
+ (instancetype)numberWithInt: (int)value;

/**
 * @brief Creates a new OFNumber with the specified `long`.
 *
 * @param value The `long` value which the OFNumber should contain
 * @return A new autoreleased OFNumber
 */
+ (instancetype)numberWithLong: (long)value;

/**
 * @brief Creates a new OFNumber with the specified `long long`.
 *
 * @param value The `long long` value which the OFNumber should contain
 * @return A new autoreleased OFNumber
 */
+ (instancetype)numberWithLongLong: (long long)value;

/**
 * @brief Creates a new OFNumber with the specified `unsigned char`.
 *
 * @param value The `unsigned char` value which the OFNumber should contain
 * @return A new autoreleased OFNumber
 */
+ (instancetype)numberWithUnsignedChar: (unsigned char)value;

/**
 * @brief Creates a new OFNumber with the specified `unsigned short`.
 *
 * @param value The `unsigned short` value which the OFNumber should contain
 * @return A new autoreleased OFNumber
 */
+ (instancetype)numberWithUnsignedShort: (unsigned short)value;

/**
 * @brief Creates a new OFNumber with the specified `unsigned int`.
 *
 * @param value The `unsigned int` value which the OFNumber should contain
 * @return A new autoreleased OFNumber
 */
+ (instancetype)numberWithUnsignedInt: (unsigned int)value;

/**
 * @brief Creates a new OFNumber with the specified `unsigned long`.
 *
 * @param value The `unsigned long` value which the OFNumber should contain
 * @return A new autoreleased OFNumber
 */
+ (instancetype)numberWithUnsignedLong: (unsigned long)value;

/**
 * @brief Creates a new OFNumber with the specified `unsigned long long`.
 *
 * @param value The `unsigned long long` value which the OFNumber should contain
 * @return A new autoreleased OFNumber
 */
+ (instancetype)numberWithUnsignedLongLong: (unsigned long long)value;

/**
 * @brief Creates a new OFNumber with the specified `float`.
 *
 * @param value The `float` value which the OFNumber should contain
 * @return A new autoreleased OFNumber
 */
+ (instancetype)numberWithFloat: (float)value;

/**
 * @brief Creates a new OFNumber with the specified `double`.
 *
 * @param value The `double` value which the OFNumber should contain
 * @return A new autoreleased OFNumber
 */
+ (instancetype)numberWithDouble: (double)value;

/**
 * @brief Initializes an already allocated OFNumber with the specified `bool`.
 *
 * @param value The `bool` value which the OFNumber should contain
 * @return An initialized OFNumber
 */
- (instancetype)initWithBool: (bool)value;

/**
 * @brief Initializes an already allocated OFNumber with the specified
 *	  `signed char`.
 *
 * @param value The `signed char` value which the OFNumber should contain
 * @return An initialized OFNumber
 */
- (instancetype)initWithChar: (signed char)value;

/**
 * @brief Initializes an already allocated OFNumber with the specified `short`.
 *
 * @param value The `short` value which the OFNumber should contain
 * @return An initialized OFNumber
 */
- (instancetype)initWithShort: (short)value;

/**
 * @brief Initializes an already allocated OFNumber with the specified `int`.
 *
 * @param value The `int` value which the OFNumber should contain
 * @return An initialized OFNumber
 */
- (instancetype)initWithInt: (int)value;

/**
 * @brief Initializes an already allocated OFNumber with the specified `long`.
 *
 * @param value The `long` value which the OFNumber should contain
 * @return An initialized OFNumber
 */
- (instancetype)initWithLong: (long)value;

/**
 * @brief Initializes an already allocated OFNumber with the specified
 *	  `long long`.
 *
 * @param value The `long long` value which the OFNumber should contain
 * @return An initialized OFNumber
 */
- (instancetype)initWithLongLong: (long long)value;

/**
 * @brief Initializes an already allocated OFNumber with the specified
 *	  `unsigned char`.
 *
 * @param value The `unsigned char` value which the OFNumber should contain
 * @return An initialized OFNumber
 */
- (instancetype)initWithUnsignedChar: (unsigned char)value;

/**
 * @brief Initializes an already allocated OFNumber with the specified
 *	  `unsigned short`.
 *
 * @param value The `unsigned short` value which the OFNumber should contain
 * @return An initialized OFNumber
 */
- (instancetype)initWithUnsignedShort: (unsigned short)value;

/**
 * @brief Initializes an already allocated OFNumber with the specified
 *	  `unsigned int`.
 *
 * @param value The `unsigned int` value which the OFNumber should contain
 * @return An initialized OFNumber
 */
- (instancetype)initWithUnsignedInt: (unsigned int)value;

/**
 * @brief Initializes an already allocated OFNumber with the specified
 *	  `unsigned long`.
 *
 * @param value The `unsigned long` value which the OFNumber should contain
 * @return An initialized OFNumber
 */
- (instancetype)initWithUnsignedLong: (unsigned long)value;

/**
 * @brief Initializes an already allocated OFNumber with the specified
 *	  `unsigned long long`.
 *
 * @param value The `unsigned long long` value which the OFNumber should contain
 * @return An initialized OFNumber
 */
- (instancetype)initWithUnsignedLongLong: (unsigned long long)value;

/**
 * @brief Initializes an already allocated OFNumber with the specified `float`.
 *
 * @param value The `float` value which the OFNumber should contain
 * @return An initialized OFNumber
 */
- (instancetype)initWithFloat: (float)value;

/**
 * @brief Initializes an already allocated OFNumber with the specified `double`.
 *
 * @param value The `double` value which the OFNumber should contain
 * @return An initialized OFNumber
 */
- (instancetype)initWithDouble: (double)value;

/**
 * @brief Compares the number to another number.
 *
 * @param number The number to compare the number to
 * @return The result of the comparison
 */
- (OFComparisonResult)compare: (OFNumber *)number;
@end

OF_ASSUME_NONNULL_END

#if !defined(NSINTEGER_DEFINED) && !__has_feature(modules)
/* Required for number literals to work */
@compatibility_alias NSNumber OFNumber;
#endif
