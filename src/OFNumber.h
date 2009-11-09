/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include <unistd.h>

#import "OFObject.h"

enum of_number_type {
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
	OF_NUMBER_FLOAT,
	OF_NUMBER_DOUBLE,
};

/**
 * The OFNumber class provides a way to store a number in an object and to
 * manipulate it.
 */
@interface OFNumber: OFObject
{
	union {
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
		float	       float_;
		double	       double_;
	} value;
	enum of_number_type type;
}

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
+ numberWithUChar: (unsigned char)uchar;

/**
 * \param ushort An unsigned short which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithUShort: (unsigned short)ushort;

/**
 * \param uint An unsigned int which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithUInt: (unsigned int)uint;

/**
 * \param ulong An unsigned long which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithULong: (unsigned long)ulong;

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
 * \param uint8 An uint8_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithUInt8: (uint8_t)uint8;

/**
 * \param uint16 An uint16_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithUInt16: (uint16_t)uint16;

/**
 * \param uint32 An uint32_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithUInt32: (uint32_t)uint32;

/**
 * \param uint64 An uint64_t which the OFNumber should contain
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
 * \param uintmax An uintmax_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithUIntMax: (uintmax_t)uintmax;

/**
 * \param ptrdifff A ptrdiff_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithPtrDiff: (ptrdiff_t)ptrdiff;

/**
 * \param intptr An intptr_t which the OFNumber should contain
 * \return A new autoreleased OFNumber
 */
+ numberWithIntPtr: (intptr_t)intptr;

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
- initWithUChar: (unsigned char)uchar;

/**
 * Initializes an already allocated OFNumber with the specified unsigned short.
 *
 * \param ushort An unsigned short which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithUShort: (unsigned short)ushort;

/**
 * Initializes an already allocated OFNumber with the specified unsigned int .
 *
 * \param uint An unsigned int which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithUInt: (unsigned int)uint;

/**
 * Initializes an already allocated OFNumber with the specified unsigned long.
 *
 * \param ulong An unsigned long which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithULong: (unsigned long)ulong;

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
 * \param uint8 An uint8_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithUInt8: (uint8_t)uint8;

/**
 * Initializes an already allocated OFNumber with the specified uint16_t.
 *
 * \param uint16 An uint16_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithUInt16: (uint16_t)uint16;

/**
 * Initializes an already allocated OFNumber with the specified uint32_t.
 *
 * \param uint32 An uint32_t which the OFNumber should contain
 * \return An initialized OFNumber
 */
- initWithUInt32: (uint32_t)uint32;

/**
 * Initializes an already allocated OFNumber with the specified uint64_t.
 *
 * \param uint64 An uint64_t which the OFNumber should contain
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
 * \param uintmax An uintmax_t which the OFNumber should contain
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
 * \return An enum of type of_number_type indicating the type of contained
 *	   number of the OFNumber
 */
- (enum of_number_type)type;

/**
 * \return The OFNumber as a char
 */
- (char)asChar;

/**
 * \return The OFNumber as a short
 */
- (short)asShort;

/**
 * \return The OFNumber as an int
 */
- (int)asInt;

/**
 * \return The OFNumber as a long
 */
- (long)asLong;

/**
 * \return The OFNumber as an unsigned char
 */
- (unsigned char)asUChar;

/**
 * \return The OFNumber as an unsigned short
 */
- (unsigned short)asUShort;

/**
 * \return The OFNumber as an unsigned int
 */
- (unsigned int)asUInt;

/**
 * \return The OFNumber as an unsigned long
 */
- (unsigned long)asULong;

/**
 * \return The OFNumber as an int8_t
 */
- (int8_t)asInt8;

/**
 * \return The OFNumber as an int16_t
 */
- (int16_t)asInt16;

/**
 * \return The OFNumber as an int32_t
 */
- (int32_t)asInt32;

/**
 * \return The OFNumber as an int64_t
 */
- (int64_t)asInt64;

/**
 * \return The OFNumber as an uint8_t
 */
- (uint8_t)asUInt8;

/**
 * \return The OFNumber as an uint16_t
 */
- (uint16_t)asUInt16;

/**
 * \return The OFNumber as an uint32_t
 */
- (uint32_t)asUInt32;

/**
 * \return The OFNumber as an uint64_t
 */
- (uint64_t)asUInt64;

/**
 * \return The OFNumber as a size_t
 */
- (size_t)asSize;

/**
 * \return The OFNumber as an ssize_t
 */
- (ssize_t)asSSize;

/**
 * \return The OFNumber as an intmax_t
 */
- (intmax_t)asIntMax;

/**
 * \return The OFNumber as an uintmax_t
 */
- (uintmax_t)asUIntMax;

/**
 * \return The OFNumber as a ptrdiff_t
 */
- (ptrdiff_t)asPtrDiff;

/**
 * \return The OFNumber as an intptr_t
 */
- (intptr_t)asIntPtr;

/**
 * \return The OFNumber as a float
 */
- (float)asFloat;

/**
 * \return The OFNumber as a double
 */
- (double)asDouble;

/**
 * Adds the specified OFNumber to the OFNumber.
 *
 * \param num The OFNumber to add
 */
- add: (OFNumber*)num;

/**
 * Subtracts the specified OFNumber from the OFNumber.
 *
 * \param num The OFNumber to substract
 */
- subtract: (OFNumber*)num;

/**
 * Multiplies the OFNumber with the specified OFNumber.
 *
 * \param num The OFNumber to multiply with
 */
- multiplyWith: (OFNumber*)num;

/**
 * Divides the OFNumber by the specified OFNumber.
 *
 * \param num The OFNumber to divide by
 */
- divideBy: (OFNumber*)num;

/**
 * Increases the OFNumber by 1.
 */
- increase;

/**
 * Decreases the OFNumber by 1.
 */
- decrease;
@end
