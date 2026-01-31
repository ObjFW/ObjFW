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

#import "OFMutableImage.h"
#import "OFColor.h"
#import "OFColorSpace.h"
#import "OFImage+Private.h"

#import "OFInvalidArgumentException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfRangeException.h"

@implementation OFMutableImage
@dynamic colorSpace, dotsPerInch;

+ (instancetype)imageWithSize: (OFSize)size
		  pixelFormat: (OFPixelFormat)pixelFormat
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithSize: size
			   pixelFormat: pixelFormat]);
}

+ (instancetype)imageWithSize: (OFSize)size
		  pixelFormat: (OFPixelFormat)pixelFormat
		   colorSpace: (OFColorSpace *)colorSpace
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithSize: size
			   pixelFormat: pixelFormat
			    colorSpace: colorSpace]);
}

- (instancetype)initWithSize: (OFSize)size
		 pixelFormat: (OFPixelFormat)pixelFormat
{
	return [self initWithSize: size
		      pixelFormat: pixelFormat
		       colorSpace: [OFColorSpace sRGBColorSpace]];
}

- (instancetype)initWithSize: (OFSize)size
		 pixelFormat: (OFPixelFormat)pixelFormat
		  colorSpace: (OFColorSpace *)colorSpace
{
	self = [self of_init];

	@try {
		unsigned int bitsPerPixel;
		size_t width, height;

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

		_pixels = OFAllocZeroedMemory(width * height,
		    bitsPerPixel / CHAR_BIT);
		_freeWhenDone = true;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void *)mutablePixels
{
	return _pixels;
}

- (void)setColorSpace: (OFColorSpace *)colorSpace
{
	OFColorSpace *old = _colorSpace;
	_colorSpace = objc_retain(colorSpace);
	objc_release(old);
}

- (void)setDotsPerInch: (OFSize)dotsPerInch
{
	if (dotsPerInch.width < 0 || dotsPerInch.height < 0)
		@throw [OFInvalidArgumentException exception];

	_dotsPerInch = dotsPerInch;
}

- (void)setColor: (OFColor *)color atPoint: (OFPoint)point
{
	float red, green, blue, alpha;

	color = [color colorUsingColorSpace: _colorSpace];

	if OF_UNLIKELY (point.x < 0 || point.y < 0 ||
	    point.x >= _size.width || point.y >= _size.height)
		@throw [OFOutOfRangeException exception];

	if OF_UNLIKELY (point.x != (size_t)point.x ||
	    point.y != (size_t)point.y)
		@throw [OFInvalidArgumentException exception];

	[color getRed: &red green: &green blue: &blue alpha: &alpha];

	if OF_UNLIKELY (!_OFWritePixel(_pixels, _pixelFormat, point.x, point.y,
	    _size.width, red, green, blue, alpha))
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];
}

- (id)copy
{
	return [[OFImage alloc] initWithPixels: _pixels
				   pixelFormat: _pixelFormat
					  size: _size
				    colorSpace: _colorSpace];
}

- (void)makeImmutable
{
	object_setClass(self, [OFImage class]);
}
@end
