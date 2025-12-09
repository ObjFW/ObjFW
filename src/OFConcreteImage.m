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

#include "config.h"

#import "OFConcreteImage.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

@implementation OFConcreteImage
- (instancetype)initWithWidth: (size_t)width
		       height: (size_t)height
		  pixelFormat: (OFPixelFormat)pixelFormat
{
	self = [super init];

	@try {
		unsigned int bitsPerPixel;
		size_t size;

		_width = width;
		_height = height;
		_pixelFormat = pixelFormat;

		bitsPerPixel = self.bitsPerPixel;
		if (bitsPerPixel % CHAR_BIT != 0)
			@throw [OFInvalidArgumentException exception];

		if (SIZE_MAX / _width < _height)
			@throw [OFOutOfRangeException exception];

		size = _width * _height;
		if (SIZE_MAX / size < bitsPerPixel / CHAR_BIT)
			@throw [OFOutOfRangeException exception];

		size *= bitsPerPixel / CHAR_BIT;

		_pixels = OFAllocZeroedMemory(1, size);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	OFFreeMemory(_pixels);

	[super dealloc];
}

- (size_t)width
{
	return _width;
}

- (size_t)height
{
	return _height;
}

- (OFPixelFormat)pixelFormat
{
	return _pixelFormat;
}

- (void *)pixels
{
	return _pixels;
}
@end
