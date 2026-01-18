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
#import "OFColorSpace.h"
#import "OFImageFormatHandler.h"

#import "OFInvalidArgumentException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfRangeException.h"

#include "OFImageConstants.inc"

@implementation OFImage
+ (instancetype)imageWithPixels: (const void *)pixels
		    pixelFormat: (OFPixelFormat)pixelFormat
			   size: (OFSize)size
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithPixels: pixels
			     pixelFormat: pixelFormat
				    size: size]);
}

+ (instancetype)imageWithPixels: (const void *)pixels
		    pixelFormat: (OFPixelFormat)pixelFormat
			   size: (OFSize)size
		     colorSpace: (OFColorSpace *)colorSpace
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithPixels: pixels
			     pixelFormat: pixelFormat
				    size: size
			      colorSpace: colorSpace]);
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

+ (instancetype)imageWithPixelsNoCopy: (const void *)pixels
			  pixelFormat: (OFPixelFormat)pixelFormat
				 size: (OFSize)size
			   colorSpace: (OFColorSpace *)colorSpace
			 freeWhenDone: (bool)freeWhenDone
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithPixelsNoCopy: pixels
				   pixelFormat: pixelFormat
					  size: size
				    colorSpace: colorSpace
				  freeWhenDone: freeWhenDone]);
}

+ (OFMutableImage *)imageWithStream: (OFSeekableStream *)stream
			imageFormat: (OFImageFormat)format
{
	return [[OFImageFormatHandler handlerForImageFormat: format]
	    readImageFromStream: stream];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_init
{
	return [super init];
}

- (instancetype)initWithPixels: (const void *)pixels
		   pixelFormat: (OFPixelFormat)pixelFormat
			  size: (OFSize)size
{
	return [self initWithPixels: pixels
			pixelFormat: pixelFormat
			       size: size
			 colorSpace: [OFColorSpace sRGBColorSpace]];
}

- (instancetype)initWithPixels: (const void *)pixels
		   pixelFormat: (OFPixelFormat)pixelFormat
			  size: (OFSize)size
		    colorSpace: (OFColorSpace *)colorSpace
{
	self = [super init];

	@try {
		unsigned int bitsPerPixel;
		size_t width, height, count;

		width = size.width;
		height = size.height;

		if (width != size.width || height != size.height)
			@throw [OFInvalidArgumentException exception];

		if (SIZE_MAX / width < height)
			@throw [OFOutOfRangeException exception];

		_size = size;
		_pixelFormat = pixelFormat;
		_colorSpace = objc_retain(colorSpace);

		bitsPerPixel = self.bitsPerPixel;
		if (bitsPerPixel % CHAR_BIT != 0)
			@throw [OFInvalidArgumentException exception];

		count = width * height;

		_pixels = OFAllocZeroedMemory(count, bitsPerPixel / CHAR_BIT);
		_freeWhenDone = true;

		memcpy(_pixels, pixels, count * (bitsPerPixel / CHAR_BIT));
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)initWithPixelsNoCopy: (const void *)pixels
			 pixelFormat: (OFPixelFormat)pixelFormat
				size: (OFSize)size
			freeWhenDone: (bool)freeWhenDone
{
	return [self initWithPixelsNoCopy: pixels
			      pixelFormat: pixelFormat
				     size: size
			       colorSpace: [OFColorSpace sRGBColorSpace]
			     freeWhenDone: freeWhenDone];
}

- (instancetype)initWithPixelsNoCopy: (const void *)pixels
			 pixelFormat: (OFPixelFormat)pixelFormat
				size: (OFSize)size
			  colorSpace: (OFColorSpace *)colorSpace
			freeWhenDone: (bool)freeWhenDone
{
	self = [super init];

	@try {
		if (size.width != (size_t)size.width ||
		    size.height != (size_t)size.height)
			@throw [OFInvalidArgumentException exception];

		if (SIZE_MAX / (size_t)size.width < (size_t)size.height)
			@throw [OFOutOfRangeException exception];

		_pixels = (void *)pixels;
		_pixelFormat = pixelFormat;
		_size = size;
		_colorSpace = objc_retain(colorSpace);
		_freeWhenDone = freeWhenDone;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_colorSpace);

	if (_freeWhenDone)
		OFFreeMemory(_pixels);

	[super dealloc];
}

- (const void *)pixels
{
	return _pixels;
}

- (OFPixelFormat)pixelFormat
{
	return _pixelFormat;
}

- (OFSize)size
{
	return _size;
}

- (OFColorSpace *)colorSpace
{
	return _colorSpace;
}

- (unsigned int)bitsPerPixel
{
	switch (_pixelFormat) {
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

- (OFSize)dotsPerInch
{
	return _dotsPerInch;
}

- (OFColor *)colorAtPoint: (OFPoint)point
{
	float red = 0.0f, green = 0.0f, blue = 0.0f, alpha = 0.0f;

	if OF_UNLIKELY (point.x < 0 || point.y < 0 ||
	    point.x >= _size.width || point.y >= _size.height)
		@throw [OFOutOfRangeException exception];

	if OF_UNLIKELY (!_OFReadAveragedPixel(self.pixels, self.pixelFormat,
	    point.x, point.y, _size.width, _size.width, _size.height,
	    &red, &green, &blue, &alpha))
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	return [OFColor colorWithRed: red
			       green: green
				blue: blue
			       alpha: alpha
			  colorSpace: _colorSpace];
}

- (bool)isEqual: (id)otherObject
{
	OFImage *otherImage;
	OFSize otherSize;
	size_t width, height;
	const void *otherPixels;
	OFPixelFormat otherFormat;

	if (otherObject == self)
		return true;

	if (![otherObject isKindOfClass: [OFImage class]])
		return false;

	otherImage = otherObject;
	otherSize = otherImage.size;

	if (!OFEqualSizes(_size, otherSize))
		return false;

	width = _size.width;
	height = _size.height;

	if (![otherImage.colorSpace isEqual: _colorSpace])
		return false;

	otherPixels = otherImage.pixels;
	otherFormat = otherImage.pixelFormat;

	if (otherFormat == _pixelFormat) {
		size_t length = width * height * (self.bitsPerPixel / CHAR_BIT);

		return (memcmp(_pixels, otherPixels, length) == 0);
	}

	for (size_t y = 0; y < height; y++) {
		for (size_t x = 0; x < width; x++) {
			float red = 0.0f, green = 0.0f, blue = 0.0f;
			float alpha = 0.0f, otherRed = 0.0f, otherGreen = 0.0f;
			float otherBlue = 0.0f, otherAlpha = 0.0f;

			if OF_UNLIKELY (!_OFReadPixel(_pixels, _pixelFormat,
			    x, y, width, &red, &green, &blue, &alpha))
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
	size_t width = _size.width, height = _size.height;
	unsigned long hash;

	OFHashInit(&hash);

	for (size_t y = 0; y < height; y++) {
		for (size_t x = 0; x < width; x++) {
			float red = 0.0f, green = 0.0f, blue = 0.0f;
			float alpha = 0.0f, tmp;

			if OF_UNLIKELY (!_OFReadPixel(_pixels, _pixelFormat,
			    x, y, width, &red, &green, &blue, &alpha))
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
	return [[OFMutableImage alloc] initWithPixels: _pixels
					  pixelFormat: _pixelFormat
						 size: _size
					   colorSpace: _colorSpace];
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
