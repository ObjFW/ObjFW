/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#ifndef __STDC_LIMIT_MACROS
# define __STDC_LIMIT_MACROS
#endif
#ifndef __STDC_CONSTANT_MACROS
# define __STDC_CONSTANT_MACROS
#endif

#include <sys/types.h>

#import "OFObject.h"
#import "OFSerialization.h"
#import "OFJSONRepresentation.h"

/**
 * \brief The type of a number.
 */
typedef enum of_number_type_t {
	OF_NUMBER_BOOL		= 0x01,
	OF_NUMBER_UCHAR		= 0x02,
	OF_NUMBER_USHORT	= 0x03,
	OF_NUMBER_UINT		= 0x04,
	OF_NUMBER_ULONG		= 0x05,
	OF_NUMBER_SIZE		= 0x06,
	OF_NUMBER_UINT8		= 0x07,
	OF_NUMBER_UINT16	= 0x08,
	OF_NUMBER_UINT32	= 0x09,
	OF_NUMBER_UINT64	= 0x0A,
	OF_NUMBER_UINTPTR	= 0x0B,
	OF_NUMBER_UINTMAX	= 0x0C,
	OF_NUMBER_SIGNED	= 0x10,
	OF_NUMBER_CHAR		= OF_NUMBER_UCHAR | OF_NUMBER_SIGNED,
	OF_NUMBER_SHORT		= OF_NUMBER_USHORT | OF_NUMBER_SIGNED,
	OF_NUMBER_INT		= OF_NUMBER_UINT | OF_NUMBER_SIGNED,
	OF_NUMBER_LONG		= OF_NUMBER_ULONG | OF_NUMBER_SIGNED,
	OF_NUMBER_INT8		= OF_NUMBER_UINT8 | OF_NUMBER_SIGNED,
	OF_NUMBER_INT16		= OF_NUMBER_UINT16 | OF_NUMBER_SIGNED,
	OF_NUMBER_INT32		= OF_NUMBER_UINT32 | OF_NUMBER_SIGNED,
	OF_NUMBER_INT64		= OF_NUMBER_UINT64 | OF_NUMBER_SIGNED,
	OF_NUMBER_SSIZE		= OF_NUMBER_SIZE | OF_NUMBER_SIGNED,
	OF_NUMBER_INTMAX	= OF_NUMBER_UINTMAX | OF_NUMBER_SIGNED,
	OF_NUMBER_PTRDIFF	= 0x0D | OF_NUMBER_SIGNED,
	OF_NUMBER_INTPTR	= 0x0E | OF_NUMBER_SIGNED,
	OF_NUMBER_FLOAT		= 0x20,
	OF_NUMBER_DOUBLE	= 0x40 | OF_NUMBER_FLOAT,
} of_number_type_t;

/**
 * \brief Provides a way to store a number in an object.
 */
@interface OFNumber: OFObject <OFCopying, OFComparing, OFSerialization,
    OFJSONRepresentation>
{
	union of_number_value {
		BOOL	       bool_;
		signed char    char_;
		signed short   short_;
		signed int     int_;
		signed long    long_;
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

#ifdef OF_HAVE_PROPERTIES
@property (readonly) of_number_type_t type;
#endif

/**
 * \brief Creates a new OFNumber with the specified BOOL.
 *
 * \param bool_ A BOOL which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithBool: (BOOL)bool_;

/**
 * \brief Creates a new OFNumber with the specified signed char.
 *
 * \param char_ A signed char which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithChar: (signed char)char_;

/**
 * \brief Creates a new OFNumber with the specified signed short.
 *
 * \param short_ A signed short which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithShort: (signed short)short_;

/**
 * \brief Creates a new OFNumber with the specified signed int.
 *
 * \param int_ A signed int which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithInt: (signed int)int_;

/**
 * \brief Creates a new OFNumber with the specified signed long.
 *
 * \param long_ A signed long which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithLong: (signed long)long_;

/**
 * \brief Creates a new OFNumber with the specified unsigned char.
 *
 * \param uchar An unsigned char which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithUnsignedChar: (unsigned char)uchar;

/**
 * \brief Creates a new OFNumber with the specified unsigned short.
 *
 * \param ushort An unsigned short which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithUnsignedShort: (unsigned short)ushort;

/**
 * \brief Creates a new OFNumber with the specified unsigned int.
 *
 * \param uint An unsigned int which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithUnsignedInt: (unsigned int)uint;

/**
 * \brief Creates a new OFNumber with the specified unsigned long.
 *
 * \param ulong An unsigned long which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithUnsignedLong: (unsigned long)ulong;

/**
 * \brief Creates a new OFNumber with the specified int8_t.
 *
 * \param int8 An int8_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithInt8: (int8_t)int8;

/**
 * \brief Creates a new OFNumber with the specified int16_t.
 *
 * \param int16 An int16_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithInt16: (int16_t)int16;

/**
 * \brief Creates a new OFNumber with the specified int32_t.
 *
 * \param int32 An int32_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithInt32: (int32_t)int32;

/**
 * \brief Creates a new OFNumber with the specified int64_t.
 *
 * \param int64 An int64_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithInt64: (int64_t)int64;

/**
 * \brief Creates a new OFNumber with the specified uint8_t.
 *
 * \param uint8 A uint8_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithUInt8: (uint8_t)uint8;

/**
 * \brief Creates a new OFNumber with the specified uint16_t.
 *
 * \param uint16 A uint16_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithUInt16: (uint16_t)uint16;

/**
 * \brief Creates a new OFNumber with the specified uint32_t.
 *
 * \param uint32 A uint32_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithUInt32: (uint32_t)uint32;

/**
 * \brief Creates a new OFNumber with the specified uint64_t.
 *
 * \param uint64 A uint64_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithUInt64: (uint64_t)uint64;

/**
 * \brief Creates a new OFNumber with the specified size_t.
 *
 * \param size A size_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithSize: (size_t)size;

/**
 * \brief Creates a new OFNumber with the specified ssize_t.
 *
 * \param ssize An ssize_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithSSize: (ssize_t)ssize;

/**
 * \brief Creates a new OFNumber with the specified intmax_t.
 *
 * \param intmax An intmax_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithIntMax: (intmax_t)intmax;

/**
 * \brief Creates a new OFNumber with the specified uintmax_t.
 *
 * \param uintmax A uintmax_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithUIntMax: (uintmax_t)uintmax;

/**
 * \brief Creates a new OFNumber with the specified ptrdiff_t.
 *
 * \param ptrdiff A ptrdiff_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithPtrDiff: (ptrdiff_t)ptrdiff;

/**
 * \brief Creates a new OFNumber with the specified intptr_t.
 *
 * \param intptr An intptr_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithIntPtr: (intptr_t)intptr;

/**
 * \brief Creates a new OFNumber with the specified uintptr_t.
 *
 * \param uintptr A uintptr_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithUIntPtr: (uintptr_t)uintptr;

/**
 * \brief Creates a new OFNumber with the specified float.
 *
 * \param float_ A float which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithFloat: (float)float_;

/**
 * \brief Creates a new OFNumber with the specified double.
 *
 * \param double_ A double which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithDouble: (double)double_;

/**
 * \brief Initializes an already allocated OFNumber with the specified BOOL.
 *
 * \param bool_ A BOOL which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithBool: (BOOL)bool_;

/**
 * \brief Initializes an already allocated OFNumber with the specified signed
 *	  char.
 *
 * \param char_ A signed char which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithChar: (signed char)char_;

/**
 * \brief Initializes an already allocated OFNumber with the specified signed
 *	  short.
 *
 * \param short_ A signed short which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithShort: (signed short)short_;

/**
 * \brief Initializes an already allocated OFNumber with the specified signed
 *	  int.
 *
 * \param int_ A signed int which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithInt: (signed int)int_;

/**
 * \brief Initializes an already allocated OFNumber with the specified signed
 *	  long.
 *
 * \param long_ A signed long which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithLong: (signed long)long_;

/**
 * \brief Initializes an already allocated OFNumber with the specified unsigned
 *	  char.
 *
 * \param uchar An unsigned char which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithUnsignedChar: (unsigned char)uchar;

/**
 * \brief Initializes an already allocated OFNumber with the specified unsigned
 *	  short.
 *
 * \param ushort An unsigned short which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithUnsignedShort: (unsigned short)ushort;

/**
 * \brief Initializes an already allocated OFNumber with the specified unsigned
 *	  int.
 *
 * \param uint An unsigned int which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithUnsignedInt: (unsigned int)uint;

/**
 * \brief Initializes an already allocated OFNumber with the specified unsigned
 *	  long.
 *
 * \param ulong An unsigned long which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithUnsignedLong: (unsigned long)ulong;

/**
 * \brief Initializes an already allocated OFNumber with the specified int8_t.
 *
 * \param int8 An int8_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithInt8: (int8_t)int8;

/**
 * \brief Initializes an already allocated OFNumber with the specified int16_t.
 *
 * \param int16 An int16_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithInt16: (int16_t)int16;

/**
 * \brief Initializes an already allocated OFNumber with the specified int32_t.
 *
 * \param int32 An int32_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithInt32: (int32_t)int32;

/**
 * \brief Initializes an already allocated OFNumber with the specified int64_t.
 *
 * \param int64 An int64_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithInt64: (int64_t)int64;

/**
 * \brief Initializes an already allocated OFNumber with the specified uint8_t.
 *
 * \param uint8 A uint8_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithUInt8: (uint8_t)uint8;

/**
 * \brief Initializes an already allocated OFNumber with the specified uint16_t.
 *
 * \param uint16 A uint16_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithUInt16: (uint16_t)uint16;

/**
 * \brief Initializes an already allocated OFNumber with the specified uint32_t.
 *
 * \param uint32 A uint32_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithUInt32: (uint32_t)uint32;

/**
 * \brief Initializes an already allocated OFNumber with the specified uint64_t.
 *
 * \param uint64 A uint64_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithUInt64: (uint64_t)uint64;

/**
 * \brief Initializes an already allocated OFNumber with the specified size_t.
 *
 * \param size A size_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithSize: (size_t)size;

/**
 * \brief Initializes an already allocated OFNumber with the specified ssize_t.
 *
 * \param ssize An ssize_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithSSize: (ssize_t)ssize;

/**
 * \brief Initializes an already allocated OFNumber with the specified intmax_t.
 *
 * \param intmax An intmax_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithIntMax: (intmax_t)intmax;

/**
 * \brief Initializes an already allocated OFNumber with the specified
 *	  uintmax_t.
 *
 * \param uintmax A uintmax_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithUIntMax: (uintmax_t)uintmax;

/**
 * \brief Initializes an already allocated OFNumber with the specified
 *	  ptrdiff_t.
 *
 * \param ptrdiff A ptrdiff_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithPtrDiff: (ptrdiff_t)ptrdiff;

/**
 * \brief Initializes an already allocated OFNumber with the specified intptr_t.
 *
 * \param intptr An intptr_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithIntPtr: (intptr_t)intptr;

/**
 * \brief Initializes an already allocated OFNumber with the specified
 *	  uintptr_t.
 *
 * \param uintptr A uintptr_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithUIntPtr: (uintptr_t)uintptr;

/**
 * \brief Initializes an already allocated OFNumber with the specified float.
 *
 * \param float_ A float which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithFloat: (float)float_;

/**
 * \brief Initializes an already allocated OFNumber with the specified double.
 *
 * \param double_ A double which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithDouble: (double)double_;

/**
 * \brief Returns the type of the number.
 *
 * \return An of_number_type_t indicating the type of the number
 */
- (of_number_type_t)type;

/**
 * \brief Returns the OFNumber as a BOOL.
 *
 * \return The OFNumber as a BOOL
 */
- (BOOL)boolValue;

/**
 * \brief Returns the OFNumber as a signed char.
 *
 * \return The OFNumber as a signed char
 */
- (signed char)charValue;

/**
 * \brief Returns the OFNumber as a signed short.
 *
 * \return The OFNumber as a short
 */
- (signed short)shortValue;

/**
 * \brief Returns the OFNumber as a signed int.
 *
 * \return The OFNumber as an int
 */
- (signed int)intValue;

/**
 * \brief Returns the OFNumber as a signed long.
 *
 * \return The OFNumber as a long
 */
- (signed long)longValue;

/**
 * \brief Returns the OFNumber as an unsigned char.
 *
 * \return The OFNumber as an unsigned char
 */
- (unsigned char)unsignedCharValue;

/**
 * \brief Returns the OFNumber as an unsigned short.
 *
 * \return The OFNumber as an unsigned short
 */
- (unsigned short)unsignedShortValue;

/**
 * \brief Returns the OFNumber as an unsigned int.
 *
 * \return The OFNumber as an unsigned int
 */
- (unsigned int)unsignedIntValue;

/**
 * \brief Returns the OFNumber as an unsigned long.
 *
 * \return The OFNumber as an unsigned long
 */
- (unsigned long)unsignedLongValue;

/**
 * \brief Returns the OFNumber as an int8_t.
 *
 * \return The OFNumber as an int8_t
 */
- (int8_t)int8Value;

/**
 * \brief Returns the OFNumber as an int16_t.
 *
 * \return The OFNumber as an int16_t
 */
- (int16_t)int16Value;

/**
 * \brief Returns the OFNumber as an int32_t.
 *
 * \return The OFNumber as an int32_t
 */
- (int32_t)int32Value;

/**
 * \brief Returns the OFNumber as an int64_t.
 *
 * \return The OFNumber as an int64_t
 */
- (int64_t)int64Value;

/**
 * \brief Returns the OFNumber as a uint8_t.
 *
 * \return The OFNumber as a uint8_t
 */
- (uint8_t)uInt8Value;

/**
 * \brief Returns the OFNumber as a uint16_t.
 *
 * \return The OFNumber as a uint16_t
 */
- (uint16_t)uInt16Value;

/**
 * \brief Returns the OFNumber as a uint32_t.
 *
 * \return The OFNumber as a uint32_t
 */
- (uint32_t)uInt32Value;

/**
 * \brief Returns the OFNumber as a uint64_t.
 *
 * \return The OFNumber as a uint64_t
 */
- (uint64_t)uInt64Value;

/**
 * \brief Returns the OFNumber as a size_t.
 *
 * \return The OFNumber as a size_t
 */
- (size_t)sizeValue;

/**
 * \brief Returns the OFNumber as an ssize_t.
 *
 * \return The OFNumber as an ssize_t
 */
- (ssize_t)sSizeValue;

/**
 * \brief Returns the OFNumber as an intmax_t.
 *
 * \return The OFNumber as an intmax_t
 */
- (intmax_t)intMaxValue;

/**
 * \brief Returns the OFNumber as a uintmax_t.
 *
 * \return The OFNumber as a uintmax_t
 */
- (uintmax_t)uIntMaxValue;

/**
 * \brief Returns the OFNumber as a ptrdiff_t.
 *
 * \return The OFNumber as a ptrdiff_t
 */
- (ptrdiff_t)ptrDiffValue;

/**
 * \brief Returns the OFNumber as an intptr_t.
 *
 * \return The OFNumber as an intptr_t
 */
- (intptr_t)intPtrValue;

/**
 * \brief Returns the OFNumber as a uintptr_t.
 *
 * \return The OFNumber as a uintptr_t
 */
- (uintptr_t)uIntPtrValue;

/**
 * \brief Returns the OFNumber as a float.
 *
 * \return The OFNumber as a float
 */
- (float)floatValue;

/**
 * \brief Returns the OFNumber as a double.
 *
 * \return The OFNumber as a double
 */
- (double)doubleValue;

/**
 * \brief Creates a new OFNumber by adding the specified number.
 *
 * \param num The OFNumber to add
 * \return A new autoreleased OFNumber added with the specified OFNumber
 */
- (OFNumber*)numberByAddingNumber: (OFNumber*)num;

/**
 * \brief Creates a new OFNumber by subtracting the specified number.
 *
 * \param num The OFNumber to substract
 * \return A new autoreleased OFNumber subtracted by the specified OFNumber
 */
- (OFNumber*)numberBySubtractingNumber: (OFNumber*)num;

/**
 * \brief Creates a new OFNumber by multiplying with the specified number.
 *
 * \param num The OFNumber to multiply with
 * \return A new autoreleased OFNumber multiplied with the specified OFNumber
 */
- (OFNumber*)numberByMultiplyingWithNumber: (OFNumber*)num;

/**
 * \brief Creates a new OFNumber by dividing with with the specified number.
 *
 * \param num The OFNumber to divide by
 * \return A new autoreleased OFNumber devided by the specified OFNumber
 */
- (OFNumber*)numberByDividingWithNumber: (OFNumber*)num;

/**
 * \brief Creates a new OFNumber by ANDing with the specified number.
 *
 * Does not work with floating point types!
 *
 * \param num The number to AND with.
 * \return A new autoreleased OFNumber ANDed with the specified OFNumber
 */
- (OFNumber*)numberByANDingWithNumber: (OFNumber*)num;

/**
 * \brief Creates a new OFNumber by ORing with the specified number.
 *
 * Does not work with floating point types!
 *
 * \param num The number to OR with.
 * \return A new autoreleased OFNumber ORed with the specified OFNumber
 */
- (OFNumber*)numberByORingWithNumber: (OFNumber*)num;

/**
 * \brief Creates a new OFNumber by XORing with the specified number.
 *
 * Does not work with floating point types!
 *
 * \param num The number to XOR with.
 * \return A new autoreleased OFNumber XORed with the specified OFNumber
 */
- (OFNumber*)numberByXORingWithNumber: (OFNumber*)num;

/**
 * \brief Creates a new OFNumber by shifting to the left by the specified number
 *	  of bits.
 *
 * Does not work with floating point types!
 *
 * \param num The number of bits to shift to the left
 * \return A new autoreleased OFNumber bitshifted to the left with the
 *	   specified OFNumber
 */
- (OFNumber*)numberByShiftingLeftWithNumber: (OFNumber*)num;

/**
 * \brief Creates a new OFNumber by shifting to the right by the specified
 *	  number of bits.
 *
 * Does not work with floating point types!
 *
 * \param num The number of bits to shift to the right
 * \return A new autoreleased OFNumber bitshifted to the right with the
 *	   specified OFNumber
 */
- (OFNumber*)numberByShiftingRightWithNumber: (OFNumber*)num;

/**
 * \brief Creates a new OFNumber by with the same value increased by one.
 *
 * \return A new autoreleased OFNumber with the value increased by one.
 */
- (OFNumber*)numberByIncreasing;

/**
 * \brief Creates a new OFNumber by with the same value decreased by one.
 *
 * \return A new autoreleased OFNumber with the value decreased by one.
 */
- (OFNumber*)numberByDecreasing;

/**
 * \brief Creates a new OFNumber with the remainder of a division with the
 *	  specified number.
 *
 * \param num The number to divide by
 * \return The remainder of a division by the specified number
 */
- (OFNumber*)remainderOfDivisionWithNumber: (OFNumber*)num;
@end

#ifndef NSINTEGER_DEFINED
/* Required for number literals to work */
@compatibility_alias NSNumber OFNumber;
#endif
