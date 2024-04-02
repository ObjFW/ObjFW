/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
	OF_ALIGN(16) float _values[4][4];
}

#ifdef OF_HAVE_CLASS_PROPERTIES
@property (readonly, class) OFMatrix4x4 *identityMatrix;
#endif

/**
 * @brief A 2D array of the 4x4 floats of the matrix in row-major format.
 *
 * These may be modified directly.
 */
@property (readonly, nonatomic) float (*values)[4];

/**
 * @brief Returns the 4x4 identity matrix.
 */
+ (OFMatrix4x4 *)identityMatrix;

/**
 * @brief Creates a new 4x4 matrix with the specified values.
 *
 * @param values A 2D array of 4x4 floats in row-major format
 * @return A new, autoreleased OFMatrix4x4
 */
+ (instancetype)matrixWithValues: (const float [_Nonnull 4][4])values;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated 4x4 matrix with the specified values.
 *
 * @param values A 2D array of 4x4 floats in row-major format
 * @return An initialized OFMatrix4x4
 */
- (instancetype)initWithValues: (const float [_Nonnull 4][4])values
    OF_DESIGNATED_INITIALIZER;

/**
 * @brief Multiplies the receiver with the specified matrix on the left side
 *	  and the receiver on the right side.
 *
 * @param matrix The matrix to multiply the receiver with
 */
- (void)multiplyWithMatrix: (OFMatrix4x4 *)matrix;

/**
 * @brief Translates the matrix with the specified vector.
 *
 * @param vector The vector to translate the matrix with
 */
- (void)translateWithVector: (OFVector3D)vector;

/**
 * @brief Scales the matrix with the specified vector.
 *
 * @param vector The vector to scale the matrix with
 */
- (void)scaleWithVector: (OFVector3D)vector;

/**
 * @brief Transforms the specified vector according to the matrix.
 *
 * @param vector The vector to transform
 * @return The transformed vector
 */
- (OFVector4D)transformedVector: (OFVector4D)vector;

/**
 * @brief Transforms the specified vectors in-place according to the matrix.
 *
 * @warning Please note that the vectors must be 16 byte aligned! This is
 *	    required to allow SIMD optimizations. Passing a pointer to vectors
 *	    that are not 16 byte aligned will crash if SIMD optimizations are
 *	    enabled.
 *
 * @param vectors The vectors to transform
 * @param count The count of the specified vectors
 */
- (void)transformVectors: (OFVector4D *)vectors count: (size_t)count;
@end

OF_ASSUME_NONNULL_END
