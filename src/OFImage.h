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

#import "OFObject.h"
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

@class OFColor;
@class OFColorSpace;
@class OFDictionary OF_GENERIC(KeyType, ObjectType);
@class OFMutableImage;
@class OFSeekableStream;

/**
 * @brief A pixel format.
 *
 * All pixel formats are in native endianness unless otherwise specified.
 */
typedef enum {
	/* Private */
	_OFPixelFormatInt8  = 0x10000,
	_OFPixelFormatInt16 = 0x20000,
	_OFPixelFormatInt32 = 0x30000,
	_OFPixelFormatFP16  = 0x50000,
	_OFPixelFormatFP32  = 0x60000,

	/** Unknown pixel format. */
	OFPixelFormatUnknown = 0,
	/** RGB with 8 bits per channel as 3 consecutive bytes. */
	OFPixelFormatRGB888 = _OFPixelFormatInt8,
	/** BGR with 8 bits per channel as 3 consecutive bytes. */
	OFPixelFormatBGR888,
	/** RGBA with 8 bits per channel in 32 bit integers. */
	OFPixelFormatRGBA8888 = _OFPixelFormatInt32,
	/** ARGB with 8 bits per channel in 32 bit integers. */
	OFPixelFormatARGB8888,
	/** ABGR with 8 bits per channel in 32 bit integers. */
	OFPixelFormatABGR8888,
	/** BGRA with 8 bits per channel in 32 bit integers. */
	OFPixelFormatBGRA8888,
	/**
	 * RGBA with 16 bit per channel as 4 consecutive 16 bit floating point
	 * numbers.
	 */
	OFPixelFormatRGBA16161616FP = _OFPixelFormatFP16 + 2,
	/**
	 * RGBA with 32 bit per channel as 4 consecutive 32 bit floating point
	 * numbers.
	 */
	OFPixelFormatRGBA32323232FP = _OFPixelFormatFP32 + 2
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
	void *_pixels;
	OFPixelFormat _pixelFormat;
	OFSize _size;
	OFColorSpace *_colorSpace;
	bool _freeWhenDone;
	OFSize _dotsPerInch;
	OF_RESERVE_IVARS(OFImage, 4)
}

/**
 * @brief The raw pixels using the @ref pixelFormat.
 */
@property (readonly, nonatomic) const void *pixels OF_RETURNS_INNER_POINTER;

/**
 * @brief The pixel format used by the image.
 */
@property (readonly, nonatomic) OFPixelFormat pixelFormat;

/**
 * @brief The size of the image in pixels.
 */
@property (readonly, nonatomic) OFSize size;

/**
 * @brief The color space of the image.
 *
 * Setting this property does not convert the image, but changes how the image
 * is interpreted.
 */
@property (readonly, retain, nonatomic) OFColorSpace *colorSpace;

/**
 * @brief The bits per pixel.
 */
@property (readonly, nonatomic) unsigned int bitsPerPixel;

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
 *	  format and the specified size in the specified color space.
 *
 * @param pixels The pixels for the new image
 * @param pixelFormat The pixel format of the pixels for the new image
 * @param size The size for the new image in pixels
 * @param colorSpace The color space of the image
 * @return A new image
 * @throw OFInvalidArgumentException The specified size is not integral
 */
+ (instancetype)imageWithPixels: (const void *)pixels
		    pixelFormat: (OFPixelFormat)pixelFormat
			   size: (OFSize)size
		     colorSpace: (OFColorSpace *)colorSpace;

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
 * @brief Creates a new image with the specified pixels in the specified pixel
 *	  format and the specified size by taking over ownership of the
 *	  specified pixels pointer in the specified color space.
 *
 * @param pixels The pixels for the new image
 * @param pixelFormat The pixel format of the pixels for the new image
 * @param size The size for the new image in pixels
 * @param colorSpace The color space of the image
 * @param freeWhenDone Whether to free the pointer when it is no onger needed
 *		       by the OFImage
 * @return A new image
 * @throw OFInvalidArgumentException The specified size is not integral
 */
+ (instancetype)imageWithPixelsNoCopy: (const void *)pixels
			  pixelFormat: (OFPixelFormat)pixelFormat
				 size: (OFSize)size
			   colorSpace: (OFColorSpace *)colorSpace
			 freeWhenDone: (bool)freeWhenDone;

- (instancetype)init OF_UNAVAILABLE;

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
 *	  the specified pixel format and the specified size in the specified
 *	  color space.
 *
 * @param pixels The pixels for the new image
 * @param pixelFormat The pixel format of the pixels for the new image
 * @param size The size for the new image in pixels
 * @param colorSpace The color space of the image
 * @return An initialized image
 * @throw OFInvalidArgumentException The specified size is not integral
 */
- (instancetype)initWithPixels: (const void *)pixels
		   pixelFormat: (OFPixelFormat)pixelFormat
			  size: (OFSize)size
		    colorSpace: (OFColorSpace *)colorSpace;

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
 * @brief Initializes an already allocated image with the specified pixels in
 *	  the specified pixel format and the specified size by taking over
 *	  ownership of the specified pixels pointer in the specified color
 *	  space.
 *
 * @param pixels The pixels for the new image
 * @param pixelFormat The pixel format of the pixels for the new image
 * @param size The size for the new image in pixels
 * @param colorSpace The color space of the image
 * @param freeWhenDone Whether to free the pointer when it is no onger needed
 *		       by the OFImage
 * @return An initialized image
 * @throw OFInvalidArgumentException The specified size is not integral
 */
- (instancetype)initWithPixelsNoCopy: (const void *)pixels
			 pixelFormat: (OFPixelFormat)pixelFormat
				size: (OFSize)size
			  colorSpace: (OFColorSpace *)colorSpace
			freeWhenDone: (bool)freeWhenDone;

/**
 * @brief Returns the color at the specified point.
 *
 * If the point is non-integral, the weighted average of the neighboring pixels
 * is returned.
 *
 * @warning This method is expensive! You should use @ref pixels instead to get
 *	    a buffer and use that instead.
 *
 * @param point The point whose color to return
 * @return The color for the specified point
 * @throw OFOutOfRangeException The specified point is outside of the image's
 *				bounds
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
