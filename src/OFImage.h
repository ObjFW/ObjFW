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

#include "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

@class OFColor;

/**
 * @brief A pixel format.
 */
typedef enum {
	/** Unknown pixel format. */
	OFPixelFormatUnknown,
	/** 8-bit grayscale. */
	OFPixelFormatGrayscale8,
	/**
	 * RGB with 5 bits for red, 6 bits for green and 5 bits for blue in big
	 * endian.
	 */
	OFPixelFormatRGB565BE,
	/**
	 * RGB with 5 bits for red, 6 bits for green and 5 bits for blue in
	 * little endian.
	 */
	OFPixelFormatRGB565LE,
	/** RGB with 8 bits per channel. */
	OFPixelFormatRGB888,
	/** RGBA with 8 bits per channel. */
	OFPixelFormatRGBA8888,
	/** ARGB with 8 bits per channel. */
	OFPixelFormatARGB8888,
	/**
	 * BGR with 5 bits for red, 6 bits for green and 5 bits for blue in big
	 * endian.
	 */
	OFPixelFormatBGR565BE,
	/**
	 * BGR with 5 bits for red, 6 bits for green and 5 bits for blue in
	 * little endian.
	 */
	OFPixelFormatBGR565LE,
	/** BGR with 8 bits per channel. */
	OFPixelFormatBGR888,
	/** ABGR with 8 bits per channel. */
	OFPixelFormatABGR8888,
	/** BGRA with 8 bits per channel. */
	OFPixelFormatBGRA8888,
} OFPixelFormat;

/**
 * @brief A class representing an image.
 */
@interface OFImage: OFObject <OFCopying, OFMutableCopying>
{
	OFSize _dotsPerInch;
	OF_RESERVE_IVARS(OFImage, 4)
}

/**
 * @brief The size of the image in pixels.
 */
@property (readonly, nonatomic) OFSize size;

/**
 * @brief The bits per pixel.
 */
@property (readonly, nonatomic) unsigned int bitsPerPixel;

/**
 * @brief The pixel format used by the image.
 */
@property (readonly, nonatomic) OFPixelFormat pixelFormat;

/**
 * @brief The raw pixels using the @ref pixelFormat.
 */
@property (readonly, nonatomic) const void *pixels;

/**
 * @brief The dots per inch of the image or (0, 0) if unknown.
 */
@property (readonly, nonatomic) OFSize dotsPerInch;

/**
 * @brief Creates a new image with the specified pixels in the specified pixel
 *	  format and the specified size.
 *
 * @param pixels The pixels for the new image
 * @param pixelFormat The pixel format of the pixels for the new image
 * @param size The size for the new image in pixels
 * @return A new image
 * @throw OFInvalidArgumentException The specified size is not integral
 */
+ (instancetype)imageWithPixels: (const void *)pixels
		    pixelFormat: (OFPixelFormat)pixelFormat
			   size: (OFSize)size;

/**
 * @brief Creates a new image with the specified pixels in the specified pixel
 *	  format and the specified size by taking over ownership of the
 *	  specified pixels pointer.
 *
 * @param pixels The pixels for the new image
 * @param pixelFormat The pixel format of the pixels for the new image
 * @param size The size for the new image in pixels
 * @param freeWhenDone Whether to free the pointer when it is no onger needed
 *		       by the OFImage
 * @return A new image
 * @throw OFInvalidArgumentException The specified size is not integral
 */
+ (instancetype)imageWithPixelsNoCopy: (const void *)pixels
			  pixelFormat: (OFPixelFormat)pixelFormat
				 size: (OFSize)size
			 freeWhenDone: (bool)freeWhenDone;

/**
 * @brief Initializes an already allocated image with the specified pixels in
 *	  the specified pixel format and the specified size.
 *
 * @param pixels The pixels for the new image
 * @param pixelFormat The pixel format of the pixels for the new image
 * @param size The size for the new image in pixels
 * @return An initialized image
 * @throw OFInvalidArgumentException The specified size is not integral
 */
- (instancetype)initWithPixels: (const void *)pixels
		   pixelFormat: (OFPixelFormat)pixelFormat
			  size: (OFSize)size;

/**
 * @brief Initializes an already allocated image with the specified pixels in
 *	  the specified pixel format and the specified size by taking over
 *	  ownership of the specified pixels pointer.
 *
 * @param pixels The pixels for the new image
 * @param pixelFormat The pixel format of the pixels for the new image
 * @param size The size for the new image in pixels
 * @param freeWhenDone Whether to free the pointer when it is no onger needed
 *		       by the OFImage
 * @return An initialized image
 * @throw OFInvalidArgumentException The specified size is not integral
 */
- (instancetype)initWithPixelsNoCopy: (const void *)pixels
			 pixelFormat: (OFPixelFormat)pixelFormat
				size: (OFSize)size
			freeWhenDone: (bool)freeWhenDone;

/**
 * @brief Returns the color at the specified point.
 *
 * @warning This method is expensive! You should use @ref pixels instead to get
 *	    a buffer and use that instead.
 *
 * @param point The point whose color to return
 * @return The color for the specified point
 * @throw OFOutOfRangeException The specified point is outside of the image's
 *				bounds
 * @throw OFInvalidArgumentException The specified point is not integral
 */
- (OFColor *)colorAtPoint: (OFPoint)point;
@end

OF_ASSUME_NONNULL_END

#import "OFMutableImage.h"
