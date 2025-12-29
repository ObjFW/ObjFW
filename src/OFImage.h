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

#import "OFObject.h"
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

@class OFColor;
@class OFDictionary OF_GENERIC(KeyType, ObjectType);
@class OFMutableImage;
@class OFSeekableStream;

/**
 * @brief A pixel format.
 */
typedef enum {
	/** Unknown pixel format. */
	OFPixelFormatUnknown,
	/** RGB with 8 bits per channel. */
	OFPixelFormatRGB888,
	/** RGBA (in big endian) with 8 bits per channel, 4 byte aligned. */
	OFPixelFormatRGBA8888,
	/** ARGB (in big endian) with 8 bits per channel, 4 byte aligned. */
	OFPixelFormatARGB8888,
	/** BGR with 8 bits per channel. */
	OFPixelFormatBGR888,
	/** ABGR (in big endian) with 8 bits per channel, 4 byte aligned. */
	OFPixelFormatABGR8888,
	/** BGRA (in big endian) with 8 bits per channel, 4 byte aligned. */
	OFPixelFormatBGRA8888,
} OFPixelFormat;

/**
 * @brief An identifier for an image format.
 *
 * Possible values are:
 *
 *   * @ref OFImageFormatBMP
 *   * @ref OFImageFormatGIF
 *   * @ref OFImageFormatJPEG
 *   * @ref OFImageFormatPNG
 *   * @ref OFImageFormatQOI
 */
typedef OFConstantString *OFImageFormat;

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief The BMP image format.
 */
extern const OFImageFormat OFImageFormatBMP;

/**
 * @brief The GIF image format.
 */
extern const OFImageFormat OFImageFormatGIF;

/**
 * @brief The JPEG image format.
 */
extern const OFImageFormat OFImageFormatJPEG;

/**
 * @brief The PNG image format.
 */
extern const OFImageFormat OFImageFormatPNG;

/**
 * @brief The Quite Okay Image Format.
 */
extern const OFImageFormat OFImageFormatQOI;
#ifdef __cplusplus
}
#endif

/**
 * @class OFImage OFImage.h ObjFW/ObjFW.h
 *
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
@property (readonly, nonatomic) const void *pixels OF_RETURNS_INNER_POINTER;

/**
 * @brief The dots per inch of the image or (0, 0) if unknown.
 */
@property (readonly, nonatomic) OFSize dotsPerInch;

/**
 * @brief Creates a new mutable image from the specified stream.
 *
 * @param stream The stream to create the image from
 * @param format The image format of the stream
 * @return A new image
 * @throw OFInvalidFormatExcepetion The stream's format was invalid
 * @throw OFTruncatedDataException The stream ended before all required data
 *				   was read
 * @throw OFOutOfRangeException The image read from the stream is too big for
 *				an OFImage
 * @throw OFReadFailedException Reading from the stream failed
 * @throw OFSeekFailedException Seeking the stream failed
 * @throw OFNotImplementedException There is no implementation for the
 *				    specified format
 */
+ (OFMutableImage *)imageWithStream: (OFSeekableStream *)stream
			imageFormat: (OFImageFormat)format;

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

/**
 * @brief Writes the image to the specified stream in the specified format.
 *
 * @param stream The stream to write the image to
 * @param format The image format to use to write the image to the stream
 * @param options Additional format-specific options to write the image to
 *		  the stream
 * @throw OFWriteFailedException Writing to the stream failed
 * @throw OFSeekFailedException Seeking the stream failed
 * @throw OFNotImplementedException There is no implementation for the
 *				    specified format
 */
- (void)
    writeToStream: (OFSeekableStream *)stream
      imageFormat: (OFImageFormat)format
	  options: (nullable OFDictionary OF_GENERIC(OFString *, id) *)options;
@end

OF_ASSUME_NONNULL_END

#import "OFMutableImage.h"
