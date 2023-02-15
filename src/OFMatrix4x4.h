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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @brief A 4x4 matrix of floats.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFMatrix4x4: OFObject <OFCopying>
{
	float _values[16];
}

#ifdef OF_HAVE_CLASS_PROPERTIES
@property (readonly, class) OFMatrix4x4 *identityMatrix;
#endif

/**
 * @brief An array of the 16 floats of the 4x4 matrix in column-major format.
 *
 * These may be modified directly.
 */
@property (readonly, nonatomic) float *values;

/**
 * @brief Returns the 4x4 identity matrix.
 */
+ (OFMatrix4x4 *)identityMatrix;

/**
 * @brief Creates a new 4x4 matrix with the specified values.
 *
 * @param values An array of 16 floats in column-major format
 * @return A new, autoreleased OFMatrix4x4
 */
+ (instancetype)matrixWithValues: (const float [_Nonnull 16])values;

/**
 * @brief Initializes an already allocated 4x4 matrix with the specified values.
 *
 * @param values An array of 16 floats in column-major format
 * @return An initialized OFMatrix4x4
 */
- (instancetype)initWithValues: (const float [_Nonnull 16])values;

/**
 * @brief Transposes the matrix.
 */
- (void)transpose;

/**
 * @brief Mulitplies the receiver with the specified matrix on the left side
 *	  and the receiver on the right side.
 *
 * @param matrix The matrix to multiply the receiver with
 */
- (void)multiplyWithMatrix: (OFMatrix4x4 *)matrix;

/**
 * @brief Transforms the specified 3D vector according to the matrix.
 *
 * As multiplying a 4x4 matrix with a 3D vector is not defined, this extends
 * the 3D vector to a 4D vector with its `w` value being set to 0 and just
 * discards the `w` value of the resulting 4D vector for the returned 3D
 * vector. This allows reducing the number number of calculations performed and
 * is mostly useful for 3D graphics.
 *
 * @param vector The 3D vector to transform
 * @return The transformed 3D vector
 */
- (OFVector3D)transformedVector3D: (OFVector3D)vector;
@end

OF_ASSUME_NONNULL_END
