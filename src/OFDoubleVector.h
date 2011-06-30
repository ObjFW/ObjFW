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

#include <stdarg.h>

#import "OFObject.h"

@class OFDoubleMatrix;

/**
 * \brief A class for storing and manipulating vectors of doubles.
 */
@interface OFDoubleVector: OFObject <OFCopying>
{
@public
	size_t dimension;
	double *data;
}

/**
 * \brief Creates a new vector with the specified dimension.
 *
 * \param dimension The dimension for the vector
 * \return A new autoreleased OFDoubleVector
 */
+ vectorWithDimension: (size_t)dimension;

/**
 * \brief Creates a new vector with the specified dimension and data.
 *
 * \param dimension The dimension for the vector
 * \param data The first double of the data for the vector
 * \return A new autoreleased OFDoubleVector
 */
+ vectorWithDimension: (size_t)dimension
		 data: (double)data, ...;

/**
 * \brief Initializes the vector with the specified dimension.
 *
 * \param dimension The dimension for the vector
 * \return An initialized OFDoubleVector
 */
- initWithDimension: (size_t)dimension;

/**
 * \brief Initializes the vector with the specified dimension and data.
 *
 * \param dimension The dimension for the vector
 * \param data The first double of the data for the vector
 * \return An initialized OFDoubleVector
 */
- initWithDimension: (size_t)dimension
	       data: (double)data, ...;

/**
 * \brief Initializes the vector with the specified dimension and data.
 *
 * \param dimension The dimension for the vector
 * \param The first double of the data for the vector
 * \param arguments A va_list with data for the vector
 * \return An initialized OFDoubleVector
 */
- initWithDimension: (size_t)dimension
	       data: (double)data
	  arguments: (va_list)arguments;

/**
 * \brief Sets the value for the specified index.
 *
 * \param value The value
 * \param index The index for the value
 */
- (void)setValue: (double)value
	 atIndex: (size_t)index;

/**
 * \brief Returns the value for the specified index.
 *
 * \param index The index for which the value should be returned
 * \return The value for the specified index
 */
- (double)valueAtIndex: (size_t)index;

/**
 * \brief Returns the dimension of the vector.
 *
 * \return The dimension of the vector
 */
- (size_t)dimension;

/**
 * \brief Changes the dimension of the vector.
 *
 * If the new dimension is smaller, elements will be cut off.
 * If the new dimension is bigger, new elements will be filled with zeros.
 *
 * \param dimension The new dimension for the vector
 */
- (void)setDimension: (size_t)dimension;

/**
 * \brief Returns an array of doubles with the contents of the vector.
 *
 * Modifying the returned array directly is allowed and will change the vector.
 *
 * \return An array of doubles with the contents of the vector
 */
- (double*)cArray;

/**
 * \brief Returns the magnitude or length of the vector.
 *
 * \return The magnitude or length of the vector
 */
- (double)magnitude;

/**
 * \brief Normalizes the vector.
 */
- (void)normalize;

/**
 * \brief Adds the specified vector to the receiver.
 *
 * \param vector The vector to add
 */
- (void)addVector: (OFDoubleVector*)vector;

/**
 * \brief Subtracts the specified vector from the receiver.
 *
 * \param vector The vector to subtract
 */
- (void)subtractVector: (OFDoubleVector*)vector;

/**
 * \brief Multiplies the receiver with the specified scalar.
 *
 * \param scalar The scalar to multiply with
 */
- (void)multiplyWithScalar: (double)scalar;

/**
 * \brief Divides the receiver by the specified scalar.
 *
 * \param scalar The scalar to divide by
 */
- (void)divideByScalar: (double)scalar;

/**
 * \brief Multiplies the components of the receiver with the components of the
 *	  specified vector.
 *
 * \param vector The vector to multiply the receiver with
 */
- (void)multiplyWithComponentsOfVector: (OFDoubleVector*)vector;

/**
 * \brief Divides the components of the receiver by the components of the
 *	  specified vector.
 *
 * \param vector The vector to divide the receiver by
 */
- (void)divideByComponentsOfVector: (OFDoubleVector*)vector;

/**
 * \brief Returns the dot product of the receiver and the specified vector.
 *
 * \return The dot product of the receiver and the specified vector
 */
- (double)dotProductWithVector: (OFDoubleVector*)vector;

/**
 * \brief Returns the cross product of the receiver and the specified vector.
 *
 * This currently only works for 3D vectors.
 *
 * \return The cross product of the receiver and the specified vector
 */
- (OFDoubleVector*)crossProductWithVector: (OFDoubleVector*)vector;

/**
 * \brief Multiplies the receiver with the specified matrix on the left side and
 *	  the receiver on the right side.
 *
 * \param matrix The matrix to multiply the receiver with
 */
- (void)multiplyWithMatrix: (OFDoubleMatrix*)matrix;
@end
