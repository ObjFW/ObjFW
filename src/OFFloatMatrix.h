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

@class OFFloatVector;

/**
 * \brief A class for storing and manipulating matrices of floats.
 */
@interface OFFloatMatrix: OFObject <OFCopying>
{
	size_t rows, columns;
	float *data;
}

/**
 * \brief Creates a new matrix with the specified dimension.
 *
 * If the number of rows and columns is equal, the matrix is initialized to be
 * the identity.
 *
 * \param rows The number of rows for the matrix
 * \param columns The number of colums for the matrix
 * \return A new autoreleased OFFloatMatrix
 */
+ matrixWithRows: (size_t)rows
	 columns: (size_t)columns;

/**
 * \brief Creates a new matrix with the specified dimension and data.
 *
 * \param rows The number of rows for the matrix
 * \param columns The number of colums for the matrix
 * \return A new autoreleased OFFloatMatrix
 */
+ matrixWithRows: (size_t)rows
  columnsAndData: (size_t)columns, ...;

/**
 * \brief Initializes the matrix with the specified dimension.
 *
 * If the number of rows and columns is equal, the matrix is initialized to be
 * the identity.
 *
 * \param rows The number of rows for the matrix
 * \param columns The number of colums for the matrix
 * \return An initialized OFFloatMatrix
 */
- initWithRows: (size_t)rows
       columns: (size_t)columns;

/**
 * \brief Initializes the matrix with the specified dimension and data.
 *
 * \param rows The number of rows for the matrix
 * \param columns The number of colums for the matrix
 * \return An initialized OFFloatMatrix
 */
-   initWithRows: (size_t)rows
  columnsAndData: (size_t)columns, ...;

/**
 * \brief Initializes the matrix with the specified dimension and arguments.
 *
 * \param rows The number of rows for the matrix
 * \param columns The number of colums for the matrix
 * \param arguments A va_list with data for the matrix
 * \return An initialized OFFloatMatrix
 */
- initWithRows: (size_t)rows
       columns: (size_t)columns
     arguments: (va_list)arguments;

/**
 * \brief Sets the value for the specified row and colmn.
 *
 * \param value The value
 * \param row The row for the value
 * \param column The column for the value
 */
- (void)setValue: (float)value
	  forRow: (size_t)row
	  column: (size_t)column;

/**
 * \brief Returns the value for the specified row and column.
 *
 * \param row The row for which the value should be returned
 * \param column The column for which the value should be returned
 * \return The value for the specified row and column
 */
- (float)valueForRow: (size_t)row
	      column: (size_t)column;

/**
 * \brief Returns the number of rows of the matrix.
 *
 * \return The number of rows of the matrix
 */
- (size_t)rows;

/**
 * \brief Returns the number of columns of the matrix.
 *
 * \return The number of columns of the matrix
 */
- (size_t)columns;

/**
 * \brief Returns an array of floats with the contents of the matrix.
 *
 * The returned array is in the format columns-rows.
 * Modifying the returned array directly is allowed and will change the matrix.
 *
 * \brief An array of floats with the contents of the vector
 */
- (float*)cArray;

/**
 * \brief Adds the specified matrix to the receiver.
 *
 * \param matrix The matrix to add
 */
- (void)addMatrix: (OFFloatMatrix*)matrix;

/**
 * \brief Subtracts the specified matrix from the receiver.
 *
 * \param matrix The matrix to subtract
 */
- (void)subtractMatrix: (OFFloatMatrix*)matrix;

/**
 * \brief Multiplies the receiver with the specified scalar.
 *
 * \param scalar The scalar to multiply with
 */
- (void)multiplyWithScalar: (float)scalar;

/**
 * \brief Divides the receiver by the specified scalar.
 *
 * \param scalar The scalar to divide by
 */
- (void)divideByScalar: (float)scalar;

/**
 * \brief Multiplies the receiver with the specified matrix on the left side and
 * 	  the receiver on the right.
 *
 * \param matrix The matrix to multiply the receiver with
 */
- (void)multiplyWithMatrix: (OFFloatMatrix*)matrix;

/**
 * \brief Transposes the receiver.
 */
- (void)transpose;

/**
 * \brief Translates the nxn matrix of the receiver with an n-1 vector.
 *
 * \param vector The vector to translate with
 */
- (void)translateWithVector: (OFFloatVector*)vector;

/**
 * \brief Scales the nxn matrix of the receiver with an n-1 vector.
 *
 * \param scale The vector to scale with
 */
- (void)scaleWithVector: (OFFloatVector*)vector;
@end
