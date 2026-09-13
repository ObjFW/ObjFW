/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFImage.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFMutableImage OFMutableImage.h ObjFW/ObjFW.h
 *
 * @brief A class representing a mutable image.
 */
@interface OFMutableImage: OFImage
{
	OF_RESERVE_IVARS(OFMutableImage, 4)
}

/**
 * @brief The raw pixels using the @ref pixelFormat.
 */
@property (readonly, nonatomic) void *mutablePixels OF_RETURNS_INNER_POINTER;

/**
 * @brief The color space of the image.
 *
 * Setting this property does not convert the image, but changes how the image
 * is interpreted.
 */
@property (readwrite, retain, nonatomic) OFColorSpace *colorSpace;

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
 * @brief Creates a new image with the specified size and pixel format in the
 *	  specified color space.
 *
 * @param size The size for the new image in pixels
 * @param pixelFormat The pixel format for the new image
 * @param colorSpace The color space of the image
 * @return A new autoreleased image
 * @throw OFInvalidArgumentException The specified size is not integral
 */
+ (instancetype)imageWithSize: (OFSize)size
		  pixelFormat: (OFPixelFormat)pixelFormat
		   colorSpace: (OFColorSpace *)colorSpace;

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
 * @brief Initializes an already allocated image with the specified size and
 *	  pixel format in the specified color space.
 *
 * @param size The size for the new image in pixels
 * @param pixelFormat The pixel format for the new image
 * @param colorSpace The color space of the image
 * @return An initialized image
 * @throw OFInvalidArgumentException The specified size is not integral
 */
- (instancetype)initWithSize: (OFSize)size
		 pixelFormat: (OFPixelFormat)pixelFormat
		  colorSpace: (OFColorSpace *)colorSpace;

/**
 * @brief Sets the color at the specified point.
 *
 * @warning This method is expensive! You should use @ref pixels instead to get
 *	    a buffer and use that instead.
 *
 * @param point The point whose color to set
 * @param color The color for the specified point
 * @throw OFOutOfRangeException The specified point is outside of the image's
 *				bounds or the specified color is outside the
 *				range supported by the image's format
 * @throw OFInvalidArgumentException The specified point is not integral
 */
- (void)setColor: (OFColor *)color atPoint: (OFPoint)point;

/**
 * @brief Converts the mutable image to an immutable image.
 */
- (void)makeImmutable;
@end

OF_ASSUME_NONNULL_END
