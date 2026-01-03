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

#include "config.h"

#import "OFImage.h"
#import "OFImage+Private.h"
#import "OFColor.h"
#import "OFConcreteImage.h"
#import "OFImageFormatHandler.h"

#import "OFInvalidArgumentException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfRangeException.h"

@interface OFPlaceholderImage: OFImage
@end

#include "OFImageConstants.inc"

static struct {
	Class isa;
} placeholder;

@implementation OFPlaceholderImage
- (instancetype)init
{
	return (id)[[OFConcreteImage alloc] init];
}

- (instancetype)initWithPixels: (const void *)pixels
		   pixelFormat: (OFPixelFormat)pixelFormat
			  size: (OFSize)size
{
	return (id)[[OFConcreteImage alloc] initWithPixels: pixels
					       pixelFormat: pixelFormat
						      size: size];
}

- (instancetype)initWithPixelsNoCopy: (const void *)pixels
			 pixelFormat: (OFPixelFormat)pixelFormat
				size: (OFSize)size
			freeWhenDone: (bool)freeWhenDone
{
	return (id)[[OFConcreteImage alloc] initWithPixelsNoCopy: pixels
						     pixelFormat: pixelFormat
							    size: size
						    freeWhenDone: freeWhenDone];
}
@end

@implementation OFImage
+ (void)initialize
{
	if (self == [OFImage class])
		object_setClass((id)&placeholder, [OFPlaceholderImage class]);
}

+ (instancetype)alloc
{
	if (self == [OFImage class])
		return (id)&placeholder;

	return [super alloc];
}

+ (OFMutableImage *)imageWithStream: (OFSeekableStream *)stream
			imageFormat: (OFImageFormat)format
{
	OFImageFormatHandler *handler =
	    [OFImageFormatHandler handlerForImageFormat: format];

	return [handler readImageFromStream: stream];
}

+ (instancetype)imageWithPixels: (const void *)pixels
		    pixelFormat: (OFPixelFormat)pixelFormat
			   size: (OFSize)size
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithPixels: pixels
			     pixelFormat: pixelFormat
				    size: size]);
}

+ (instancetype)imageWithPixelsNoCopy: (const void *)pixels
			  pixelFormat: (OFPixelFormat)pixelFormat
				 size: (OFSize)size
			 freeWhenDone: (bool)freeWhenDone
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithPixelsNoCopy: pixels
				   pixelFormat: pixelFormat
					  size: size
				  freeWhenDone: freeWhenDone]);
}

- (instancetype)init
{
	if ([self isMemberOfClass: [OFImage class]] ||
	    [self isMemberOfClass: [OFMutableImage class]]) {
		@try {
			[self doesNotRecognizeSelector: _cmd];
		} @catch (id e) {
			objc_release(self);
			@throw e;
		}

		abort();
	}

	return [super init];
}

- (instancetype)initWithPixels: (const void *)pixels
		   pixelFormat: (OFPixelFormat)pixelFormat
			  size: (OFSize)size
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithPixelsNoCopy: (const void *)pixels
			 pixelFormat: (OFPixelFormat)pixelFormat
				size: (OFSize)size
			freeWhenDone: (bool)freeWhenDone
{
	OF_INVALID_INIT_METHOD
}

- (OFSize)size
{
	OF_UNRECOGNIZED_SELECTOR
}

- (unsigned int)bitsPerPixel
{
	switch (self.pixelFormat) {
	case OFPixelFormatUnknown:
		return 0;
	case OFPixelFormatRGB888:
	case OFPixelFormatBGR888:
		return 24;
	case OFPixelFormatRGBA8888:
	case OFPixelFormatARGB8888:
	case OFPixelFormatABGR8888:
	case OFPixelFormatBGRA8888:
		return 32;
	default:
		@throw [OFInvalidArgumentException exception];
	}
}

- (OFPixelFormat)pixelFormat
{
	OF_UNRECOGNIZED_SELECTOR
}

- (const void *)pixels
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFSize)dotsPerInch
{
	return _dotsPerInch;
}

- (OFColor *)colorAtPoint: (OFPoint)point
{
	size_t x = point.x, y = point.y;
	OFSize size = self.size;
	size_t width = size.width, height = size.height;
	float red = 0.f, green = 0.f, blue = 0.f, alpha = 0.f;

	if OF_UNLIKELY (width != size.width || height != size.height)
		@throw [OFInvalidArgumentException exception];

	if OF_UNLIKELY (x >= width || y >= height)
		@throw [OFOutOfRangeException exception];

	if OF_UNLIKELY (!_OFReadAveragedPixel(self.pixels, self.pixelFormat,
	    point.x, point.y, width, height, &red, &green, &blue, &alpha))
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	return [OFColor colorWithRed: red green: green blue: blue alpha: alpha];
}

- (bool)isEqual: (id)otherObject
{
	OFImage *otherImage;
	OFSize size, otherSize;
	size_t width, height;
	const void *pixels, *otherPixels;
	OFPixelFormat format, otherFormat;

	if (otherObject == self)
		return true;

	if (![otherObject isKindOfClass: [OFImage class]])
		return false;

	otherImage = otherObject;

	size = self.size;
	otherSize = otherImage.size;

	if (!OFEqualSizes(size, otherSize))
		return false;

	width = size.width;
	height = size.height;

	if (width != size.width || height != size.height ||
	    otherSize.width != (size_t)otherSize.width ||
	    otherSize.height != (size_t)otherSize.height)
		@throw [OFInvalidArgumentException exception];

	pixels = self.pixels;
	otherPixels = otherImage.pixels;
	format = self.pixelFormat;
	otherFormat = otherImage.pixelFormat;

	if (otherFormat == format) {
		size_t length = width * height * (self.bitsPerPixel / CHAR_BIT);

		return (memcmp(pixels, otherPixels, length) == 0);
	}

	for (size_t y = 0; y < height; y++) {
		for (size_t x = 0; x < width; x++) {
			float red = 0.f, green = 0.f, blue = 0.f, alpha = 0.f;
			float otherRed = 0.f, otherGreen = 0.f, otherBlue = 0.f;
			float otherAlpha = 0.f;

			if OF_UNLIKELY (!_OFReadPixel(pixels, format, x, y,
			    width, &red, &green, &blue, &alpha))
				@throw [OFNotImplementedException
				    exceptionWithSelector: _cmd
						   object: self];

			if OF_UNLIKELY (!_OFReadPixel(otherPixels, otherFormat,
			    x, y, width, &otherRed, &otherGreen, &otherBlue,
			    &otherAlpha))
				@throw [OFNotImplementedException
				    exceptionWithSelector: _cmd
						   object: self];

			if OF_UNLIKELY (red != otherRed ||
			    green != otherGreen || blue != otherBlue ||
			    alpha != otherAlpha)
				return false;
		}
	}

	return true;
}

- (unsigned long)hash
{
	OFSize size = self.size;
	size_t width = size.width, height = size.height;
	const void *pixels;
	OFPixelFormat format;
	unsigned long hash;

	if (width != size.width || height != size.height)
		@throw [OFInvalidArgumentException exception];

	pixels = self.pixels;
	format = self.pixelFormat;

	OFHashInit(&hash);

	for (size_t y = 0; y < height; y++) {
		for (size_t x = 0; x < width; x++) {
			float red = 0.f, green = 0.f, blue = 0.f, alpha = 0.f;
			float tmp;

			if OF_UNLIKELY (!_OFReadPixel(pixels, format, x, y,
			    width, &red, &green, &blue, &alpha))
				@throw [OFNotImplementedException
				    exceptionWithSelector: _cmd
						   object: self];

			tmp = OFToLittleEndianFloat(red);
			for (uint_fast8_t i = 0; i < sizeof(float); i++)
				OFHashAddByte(&hash, ((char *)&tmp)[i]);

			tmp = OFToLittleEndianFloat(green);
			for (uint_fast8_t i = 0; i < sizeof(float); i++)
				OFHashAddByte(&hash, ((char *)&tmp)[i]);

			tmp = OFToLittleEndianFloat(blue);
			for (uint_fast8_t i = 0; i < sizeof(float); i++)
				OFHashAddByte(&hash, ((char *)&tmp)[i]);

			tmp = OFToLittleEndianFloat(alpha);
			for (uint_fast8_t i = 0; i < sizeof(float); i++)
				OFHashAddByte(&hash, ((char *)&tmp)[i]);
		}
	}

	OFHashFinalize(&hash);

	return hash;
}

- (id)copy
{
	return objc_retain(self);
}

- (id)mutableCopy
{
	return [[OFMutableImage alloc] initWithPixels: self.pixels
					  pixelFormat: self.pixelFormat
						 size: self.size];
}

- (void)writeToStream: (OFSeekableStream *)stream
	  imageFormat: (OFImageFormat)format
	      options: (OFDictionary OF_GENERIC(OFString *, id) *)options
{
	OFImageFormatHandler *handler =
	    [OFImageFormatHandler handlerForImageFormat: format];

	[handler writeImage: self toStream: stream options: options];
}
@end
