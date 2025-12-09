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

/**
 * @brief A pixel format.
 */
typedef enum {
	/** Unknown pixel format. */
	OFPixelFormatUnknown,
	/** 8-bit grayscale. */
	OFPixelFormatGrayscale8,
	/** RGB with 5 bits for red, 6 bits for green and 5 bits for blue. */
	OFPixelFormatRGB565,
	/** RGB with 8 bits per channel. */
	OFPixelFormatRGB888,
	/** RGBA with 8 bits per channel. */
	OFPixelFormatRGBA8888,
} OFPixelFormat;

/**
 * @brief A class representing an image.
 */
@interface OFImage: OFObject
{
	float _pixelsPerInch;
	OF_RESERVE_IVARS(OFImage, 4)
}

/**
 * @brief The width of the image in pixels.
 */
@property (readonly, nonatomic) size_t width;

/**
 * @brief The height of the image in pixels.
 */
@property (readonly, nonatomic) size_t height;

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
@property (readonly, nonatomic) void *pixels;

/**
 * @brief The pixels per inch of the image or 0 if unknown.
 */
@property (nonatomic) float pixelsPerInch;

/**
 * @brief Creates a new image with the specified size and pixel format.
 *
 * @param width The width for the new image in pixels
 * @param height The height for the new image in pixels
 * @param pixelFormat The pixel format for the new image
 *
 * @return A new autoreleased image
 */
+ (instancetype)imageWithWidth: (size_t)width
			height: (size_t)height
		   pixelFormat: (OFPixelFormat)pixelFormat;

/**
 * @brief Initializes an already allocated image with the specified size and
 *	  pixel format.
 *
 * @param width The width for the new image in pixels
 * @param height The height for the new image in pixels
 * @param pixelFormat The pixel format for the new image
 *
 * @return An initialized image
 */
- (instancetype)initWithWidth: (size_t)width
		       height: (size_t)height
		  pixelFormat: (OFPixelFormat)pixelFormat;
@end

OF_ASSUME_NONNULL_END
