/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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
@interface OF4x4Matrix: OFObject
{
	float _values[16];
}

#ifdef OF_HAVE_CLASS_PROPERTIES
@property (readonly, class) OF4x4Matrix *identity;
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
+ (OF4x4Matrix *)identity;

/**
 * @brief Creates a new 4x4 matrix with the specified values.
 *
 * @param values An array of 16 floats in column-major format
 * @return A new, autoreleased OF4x4Matrix
 */
+ (instancetype)matrixWithValues: (const float [_Nonnull 16])values;

/**
 * @brief Initializes an already allocated 4x4 matrix with the specified values.
 *
 * @param values An array of 16 floats in column-major format
 * @return An initialized OF4x4Matrix
 */
- (instancetype)initWithValues: (const float [_Nonnull 16])values;

/**
 * @brief Transposes the matrix.
 */
- (void)transpose;
@end

OF_ASSUME_NONNULL_END
