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
#import "OFImage+Private.h"

#import "OFInvalidArgumentException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfRangeException.h"

@implementation OFMutableImage
@dynamic dotsPerInch;

+ (instancetype)imageWithSize: (OFSize)size
		  pixelFormat: (OFPixelFormat)pixelFormat
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithSize: size
			   pixelFormat: pixelFormat]);
}

- (instancetype)initWithSize: (OFSize)size
		 pixelFormat: (OFPixelFormat)pixelFormat
{
	self = [self of_init];

	@try {
		unsigned int bitsPerPixel;
		size_t width, height, count;

		width = size.width;
		height = size.height;

		if (width != size.width || height != size.height)
			@throw [OFInvalidArgumentException exception];

		_size = size;
		_pixelFormat = pixelFormat;

		bitsPerPixel = self.bitsPerPixel;
		if (bitsPerPixel % CHAR_BIT != 0)
			@throw [OFInvalidArgumentException exception];

		if (SIZE_MAX / width < height)
			@throw [OFOutOfRangeException exception];

		count = width * height;

		_pixels = OFAllocZeroedMemory(count, bitsPerPixel / CHAR_BIT);
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

- (void)setDotsPerInch: (OFSize)dotsPerInch
{
	if (dotsPerInch.width < 0 || dotsPerInch.height < 0)
		@throw [OFInvalidArgumentException exception];

	_dotsPerInch = dotsPerInch;
}

- (void)setColor: (OFColor *)color atPoint: (OFPoint)point
{
	size_t x = point.x, y = point.y;
	size_t width = _size.width, height = _size.height;
	float red, green, blue, alpha;

	if OF_UNLIKELY (x != point.x || y != point.y ||
	    width != _size.width || height != _size.height)
		@throw [OFInvalidArgumentException exception];

	if OF_UNLIKELY (x >= width || y >= height)
		@throw [OFOutOfRangeException exception];

	[color getRed: &red green: &green blue: &blue alpha: &alpha];

	if OF_UNLIKELY (!_OFWritePixel(_pixels, _pixelFormat, x, y,
	    width, red, green, blue, alpha))
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];
}

- (id)copy
{
	return [[OFImage alloc] initWithPixels: _pixels
				   pixelFormat: _pixelFormat
					  size: _size];
}

- (void)makeImmutable
{
	object_setClass(self, [OFImage class]);
}
@end
