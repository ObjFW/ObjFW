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

#import "OFConcreteMutableImage.h"
#import "OFConcreteImage.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

@implementation OFConcreteMutableImage
+ (void)initialize
{
	if (self == [OFConcreteMutableImage class])
		[self inheritMethodsFromClass: [OFConcreteImage class]];
}

- (instancetype)initWithSize: (OFSize)size
		 pixelFormat: (OFPixelFormat)pixelFormat
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

- (void)makeImmutable
{
	object_setClass(self, [OFConcreteImage class]);
}
@end
