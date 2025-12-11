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

#include "OFImage.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @brief A class representing a mutable image.
 */
@interface OFMutableImage: OFImage
/**
 * @brief The raw pixels using the @ref pixelFormat.
 */
@property (readonly, nonatomic) void *mutablePixels;

/**
 * @brief The dots per inch of the image or (0, 0) if unknown.
 */
@property (readwrite, nonatomic) OFSize dotsPerInch;

/**
 * @brief Creates a new image with the specified size and pixel format.
 *
 * @param size The size for the new image in pixels
 * @param pixelFormat The pixel format for the new image
 * @return A new autoreleased image
 * @throw OFInvalidArgumentException The specified size is not integral
 */
+ (instancetype)imageWithSize: (OFSize)size
		  pixelFormat: (OFPixelFormat)pixelFormat;

/**
 * @brief Initializes an already allocated image with the specified size and
 *	  pixel format.
 *
 * @param size The size for the new image in pixels
 * @param pixelFormat The pixel format for the new image
 * @return An initialized image
 * @throw OFInvalidArgumentException The specified size is not integral
 */
- (instancetype)initWithSize: (OFSize)size
		 pixelFormat: (OFPixelFormat)pixelFormat;

/**
 * @brief Sets the color for the pixel at the specified position.
 *
 * @warning This method is expensive! You should use @ref pixels instead to get
 *	    a buffer and use that instead.
 *
 * @param position The position of the pixel whose color to set
 * @param color The color for the pixel at the specified position
 * @throw OFOutOfRangeException The specified position is outside of the
 *				image's bounds or the specified color is outside
 *				the range supported by the image's format
 * @throw OFInvalidArgumentException The specified position is not integral
 */
- (void)setColor: (OFColor *)color forPixelAtPosition: (OFPoint)position;

/**
 * @brief Converts the mutable image to an immutable image.
 */
- (void)makeImmutable;
@end

OF_ASSUME_NONNULL_END
