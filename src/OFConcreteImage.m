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

#import "OFConcreteImage.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

@implementation OFConcreteImage
- (instancetype)initWithPixels: (const void *)pixels
		   pixelFormat: (OFPixelFormat)pixelFormat
			  size: (OFSize)size
{
	self = [super init];

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
	self = [super init];

	@try {
		if (size.width != (size_t)size.width ||
		    size.height != (size_t)size.height)
			@throw [OFInvalidArgumentException exception];

		_pixels = (void *)pixels;
		_pixelFormat = pixelFormat;
		_size = size;
		_freeWhenDone = freeWhenDone;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_freeWhenDone)
		OFFreeMemory(_pixels);

	[super dealloc];
}

- (OFSize)size
{
	return _size;
}

- (OFPixelFormat)pixelFormat
{
	return _pixelFormat;
}

- (const void *)pixels
{
	return _pixels;
}
@end
