/*
 * Copyright (c) 2008, 2009, 2010, 2011
 *   Jonathan Schleifer <js@webkeks.org>
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

#include <unistd.h>

#import "OFObject.h"

/**
 * \brief The type of a number.
 */
typedef enum of_number_type_t {
	OF_NUMBER_BOOL,
	OF_NUMBER_CHAR,
	OF_NUMBER_SHORT,
	OF_NUMBER_INT,
	OF_NUMBER_LONG,
	OF_NUMBER_UCHAR,
	OF_NUMBER_USHORT,
	OF_NUMBER_UINT,
	OF_NUMBER_ULONG,
	OF_NUMBER_INT8,
	OF_NUMBER_INT16,
	OF_NUMBER_INT32,
	OF_NUMBER_INT64,
	OF_NUMBER_UINT8,
	OF_NUMBER_UINT16,
	OF_NUMBER_UINT32,
	OF_NUMBER_UINT64,
	OF_NUMBER_SIZE,
	OF_NUMBER_SSIZE,
	OF_NUMBER_INTMAX,
	OF_NUMBER_UINTMAX,
	OF_NUMBER_PTRDIFF,
	OF_NUMBER_INTPTR,
	OF_NUMBER_UINTPTR,
	OF_NUMBER_FLOAT,
	OF_NUMBER_DOUBLE,
} of_number_type_t;

/**
 * \brief Provides a way to store a number in an object.
 */
@interface OFNumber: OFObject <OFCopying>
{
	union of_number_value {
		BOOL	       bool_;
		char	       char_;
		short	       short_;
		int	       int_;
		long	       long_;
		unsigned char  uchar;
		unsigned short ushort;
		unsigned int   uint;
		unsigned long  ulong;
		int8_t	       int8;
		int16_t	       int16;
		int32_t	       int32;
		int64_t	       int64;
		uint8_t	       uint8;
		uint16_t       uint16;
		uint32_t       uint32;
		uint64_t       uint64;
		size_t	       size;
		ssize_t	       ssize;
		intmax_t       intmax;
		uintmax_t      uintmax;
		ptrdiff_t      ptrdiff;
		intptr_t       intptr;
		uintptr_t      uintptr;
		float	       float_;
		double	       double_;
	} value;
	of_number_type_t type;
}

/**
 * \param bool_ A BOOL which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithBool: (BOOL)bool_;

/**
 * \param char_ A char which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithChar: (char)char_;

/**
 * \param short_ A short which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithShort: (short)short_;

/**
 * \param int_ An int which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithInt: (int)int_;

/**
 * \param long_ A long which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithLong: (long)long_;

/**
 * \param uchar An unsigned char which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithUnsignedChar: (unsigned char)uchar;

/**
 * \param ushort An unsigned short which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithUnsignedShort: (unsigned short)ushort;

/**
 * \param uint An unsigned int which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithUnsignedInt: (unsigned int)uint;

/**
 * \param ulong An unsigned long which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithUnsignedLong: (unsigned long)ulong;

/**
 * \param int8 An int8_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithInt8: (int8_t)int8;

/**
 * \param int16 An int16_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithInt16: (int16_t)int16;

/**
 * \param int32 An int32_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithInt32: (int32_t)int32;

/**
 * \param int64 An int64_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithInt64: (int64_t)int64;

/**
 * \param uint8 A uint8_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithUInt8: (uint8_t)uint8;

/**
 * \param uint16 A uint16_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithUInt16: (uint16_t)uint16;

/**
 * \param uint32 A uint32_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithUInt32: (uint32_t)uint32;

/**
 * \param uint64 A uint64_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithUInt64: (uint64_t)uint64;

/**
 * \param size A size_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithSize: (size_t)size;

/**
 * \param ssize An ssize_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithSSize: (ssize_t)ssize;

/**
 * \param intmax An intmax_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithIntMax: (intmax_t)intmax;

/**
 * \param uintmax A uintmax_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithUIntMax: (uintmax_t)uintmax;

/**
 * \param ptrdiff A ptrdiff_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithPtrDiff: (ptrdiff_t)ptrdiff;

/**
 * \param intptr An intptr_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithIntPtr: (intptr_t)intptr;

/**
 * \param uintptr A uintptr_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithUIntPtr: (uintptr_t)uintptr;

/**
 * \param float_ A float which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithFloat: (float)float_;

/**
 * \param double_ A double which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithDouble: (double)double_;

/**
 * Initializes an already allocated OFNumber with the specified BOOL.
 *
 * \param bool_ A BOOL which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithBool: (BOOL)bool_;

/**
 * Initializes an already allocated OFNumber with the specified char.
 *
 * \param char_ A char which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithChar: (char)char_;

/**
 * Initializes an already allocated OFNumber with the specified short.
 *
 * \param short_ A short which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithShort: (short)short_;

/**
 * Initializes an already allocated OFNumber with the specified int.
 *
 * \param int_ An int which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithInt: (int)int_;

/**
 * Initializes an already allocated OFNumber with the specified long.
 *
 * \param long_ A long which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithLong: (long)long_;

/**
 * Initializes an already allocated OFNumber with the specified unsigned char.
 *
 * \param uchar An unsigned char which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithUnsignedChar: (unsigned char)uchar;

/**
 * Initializes an already allocated OFNumber with the specified unsigned short.
 *
 * \param ushort An unsigned short which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithUnsignedShort: (unsigned short)ushort;

/**
 * Initializes an already allocated OFNumber with the specified unsigned int .
 *
 * \param uint An unsigned int which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithUnsignedInt: (unsigned int)uint;

/**
 * Initializes an already allocated OFNumber with the specified unsigned long.
 *
 * \param ulong An unsigned long which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithUnsignedLong: (unsigned long)ulong;

/**
 * Initializes an already allocated OFNumber with the specified int8_t.
 *
 * \param int8 An int8_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithInt8: (int8_t)int8;

/**
 * Initializes an already allocated OFNumber with the specified int16_t.
 *
 * \param int16 An int16_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithInt16: (int16_t)int16;

/**
 * Initializes an already allocated OFNumber with the specified int32_t.
 *
 * \param int32 An int32_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithInt32: (int32_t)int32;

/**
 * Initializes an already allocated OFNumber with the specified int64_t.
 *
 * \param int64 An int64_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithInt64: (int64_t)int64;

/**
 * Initializes an already allocated OFNumber with the specified uint8_t.
 *
 * \param uint8 A uint8_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithUInt8: (uint8_t)uint8;

/**
 * Initializes an already allocated OFNumber with the specified uint16_t.
 *
 * \param uint16 A uint16_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithUInt16: (uint16_t)uint16;

/**
 * Initializes an already allocated OFNumber with the specified uint32_t.
 *
 * \param uint32 A uint32_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithUInt32: (uint32_t)uint32;

/**
 * Initializes an already allocated OFNumber with the specified uint64_t.
 *
 * \param uint64 A uint64_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithUInt64: (uint64_t)uint64;

/**
 * Initializes an already allocated OFNumber with the specified size_t.
 *
 * \param size A size_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithSize: (size_t)size;

/**
 * Initializes an already allocated OFNumber with the specified ssize_t.
 *
 * \param ssize An ssize_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithSSize: (ssize_t)ssize;

/**
 * Initializes an already allocated OFNumber with the specified intmax_t.
 *
 * \param intmax An intmax_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithIntMax: (intmax_t)intmax;

/**
 * Initializes an already allocated OFNumber with the specified uintmax_t.
 *
 * \param uintmax A uintmax_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithUIntMax: (uintmax_t)uintmax;

/**
 * Initializes an already allocated OFNumber with the specified ptrdiff_t.
 *
 * \param ptrdiff A ptrdiff_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithPtrDiff: (ptrdiff_t)ptrdiff;

/**
 * Initializes an already allocated OFNumber with the specified intptr_t.
 *
 * \param intptr An intptr_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithIntPtr: (intptr_t)intptr;

/**
 * Initializes an already allocated OFNumber with the specified uintptr_t.
 *
 * \param uintptr A uintptr_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithUIntPtr: (uintptr_t)uintptr;

/**
 * Initializes an already allocated OFNumber with the specified float.
 *
 * \param float_ A float which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithFloat: (float)float_;

/**
 * Initializes an already allocated OFNumber with the specified double.
 *
 * \param double_ A double which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithDouble: (double)double_;

/**
 * \return An of_number_type_t indicating the type of the number
 */
- (of_number_type_t)type;

/**
 * \return The OFNumber as a BOOL
 */
- (BOOL)boolValue;

/**
 * \return The OFNumber as a char
 */
- (char)charValue;

/**
 * \return The OFNumber as a short
 */
- (short)shortValue;

/**
 * \return The OFNumber as an int
 */
- (int)intValue;

/**
 * \return The OFNumber as a long
 */
- (long)longValue;

/**
 * \return The OFNumber as an unsigned char
 */
- (unsigned char)unsignedCharValue;

/**
 * \return The OFNumber as an unsigned short
 */
- (unsigned short)unsignedShortValue;

/**
 * \return The OFNumber as an unsigned int
 */
- (unsigned int)unsignedIntValue;

/**
 * \return The OFNumber as an unsigned long
 */
- (unsigned long)unsignedLongValue;

/**
 * \return The OFNumber as an int8_t
 */
- (int8_t)int8Value;

/**
 * \return The OFNumber as an int16_t
 */
- (int16_t)int16Value;

/**
 * \return The OFNumber as an int32_t
 */
- (int32_t)int32Value;

/**
 * \return The OFNumber as an int64_t
 */
- (int64_t)int64Value;

/**
 * \return The OFNumber as a uint8_t
 */
- (uint8_t)uInt8Value;

/**
 * \return The OFNumber as a uint16_t
 */
- (uint16_t)uInt16Value;

/**
 * \return The OFNumber as a uint32_t
 */
- (uint32_t)uInt32Value;

/**
 * \return The OFNumber as a uint64_t
 */
- (uint64_t)uInt64Value;

/**
 * \return The OFNumber as a size_t
 */
- (size_t)sizeValue;

/**
 * \return The OFNumber as an ssize_t
 */
- (ssize_t)sSizeValue;

/**
 * \return The OFNumber as an intmax_t
 */
- (intmax_t)intMaxValue;

/**
 * \return The OFNumber as a uintmax_t
 */
- (uintmax_t)uIntMaxValue;

/**
 * \return The OFNumber as a ptrdiff_t
 */
- (ptrdiff_t)ptrDiffValue;

/**
 * \return The OFNumber as an intptr_t
 */
- (intptr_t)intPtrValue;

/**
 * \return The OFNumber as a uintptr_t
 */
- (uintptr_t)uIntPtrValue;

/**
 * \return The OFNumber as a float
 */
- (float)floatValue;

/**
 * \return The OFNumber as a double
 */
- (double)doubleValue;

/**
 * \param num The OFNumber to add
 * \return A new autoreleased OFNumber added with the specified OFNumber
 */
- (OFNumber*)numberByAddingNumber: (OFNumber*)num;

/**
 * \param num The OFNumber to substract
 * \return A new autoreleased OFNumber subtracted by the specified OFNumber
 */
- (OFNumber*)numberBySubtractingNumber: (OFNumber*)num;

/**
 * \param num The OFNumber to multiply with
 * \return A new autoreleased OFNumber multiplied with the specified OFNumber
 */
- (OFNumber*)numberByMultiplyingWithNumber: (OFNumber*)num;

/**
 * \param num The OFNumber to divide by
 * \return A new autoreleased OFNumber devided by the specified OFNumber
 */
- (OFNumber*)numberByDividingWithNumber: (OFNumber*)num;

/**
 * ANDs two OFNumbers, returning a new one.
 *
 * Does not work with floating point types!
 *
 * \param num The number to AND with.
 * \return A new autoreleased OFNumber ANDed with the specified OFNumber
 */
- (OFNumber*)numberByANDingWithNumber: (OFNumber*)num;

/**
 * ORs two OFNumbers, returning a new one.
 *
 * Does not work with floating point types!
 *
 * \param num The number to OR with.
 * \return A new autoreleased OFNumber ORed with the specified OFNumber
 */
- (OFNumber*)numberByORingWithNumber: (OFNumber*)num;

/**
 * XORs two OFNumbers, returning a new one.
 *
 * Does not work with floating point types!
 *
 * \param num The number to XOR with.
 * \return A new autoreleased OFNumber XORed with the specified OFNumber
 */
- (OFNumber*)numberByXORingWithNumber: (OFNumber*)num;

/**
 * Bitshifts the OFNumber to the left by the specified OFNumber, returning a new
 * one.
 *
 * Does not work with floating point types!
 *
 * \param num The number of bits to shift to the left
 * \return A new autoreleased OFNumber bitshifted to the left with the
 *	   specified OFNumber
 */
- (OFNumber*)numberByShiftingLeftWithNumber: (OFNumber*)num;

/**
 * Bitshifts the OFNumber to the right by the specified OFNumber, returning a
 * new one.
 *
 * Does not work with floating point types!
 *
 * \param num The number of bits to shift to the right
 * \return A new autoreleased OFNumber bitshifted to the right with the
 *	   specified OFNumber
 */
- (OFNumber*)numberByShiftingRightWithNumber: (OFNumber*)num;

/**
 * \return A new autoreleased OFNumber with the value increased by one.
 */
- (OFNumber*)numberByIncreasing;

/**
 * \return A new autoreleased OFNumber with the value decreased by one.
 */
- (OFNumber*)numberByDecreasing;

/**
 * \param num The number to divide by
 * \return The remainder of a division by the specified number
 */
- (OFNumber*)remainderOfDivisionWithNumber: (OFNumber*)num;
@end
