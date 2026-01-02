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

#import "OFCanvas.h"
#import "OFColor.h"
#import "OFImage.h"
#import "OFImage+Private.h"

#import "OFInvalidArgumentException.h"
#import "OFNotImplementedException.h"

@implementation OFCanvas
@synthesize backgroundColor = _backgroundColor;

+ (instancetype)canvasWithDestinationImage: (OFMutableImage *)image
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithDestinationImage: image]);
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithDestinationImage: (OFMutableImage *)image
{
	self = [super init];

	@try {
		OFSize size;
		size_t height;

		_destinationImage = objc_retain(image);

		size = _destinationImage.size;
		_width = size.width;
		height = size.height;

		if (_width != size.width || height != size.height)
			@throw [OFInvalidArgumentException exception];

		_rect = OFMakeRect(0, 0, size.width, size.height);

		_pixels = _destinationImage.mutablePixels;
		_pixelFormat = _destinationImage.pixelFormat;

		_backgroundColor = objc_retain([OFColor black]);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_destinationImage);
	objc_release(_backgroundColor);

	[super dealloc];
}

- (void)clearRect: (OFRect)rect
{
	size_t x, y, width, height;
	float red, green, blue, alpha;

	rect = OFIntersectionRect(_rect, rect);
	x = rect.origin.x;
	y = rect.origin.y;
	width = rect.size.width;
	height = rect.size.height;

	if (x != rect.origin.x || y != rect.origin.y ||
	    width != rect.size.width || height != rect.size.height)
		@throw [OFInvalidArgumentException exception];

	[_backgroundColor getRed: &red green: &green blue: &blue alpha: &alpha];

	for (size_t i = y; i < y + height; i++)
		for (size_t j = x; j < x + width; j++)
			if (!_OFWritePixel(_pixels, _pixelFormat, j, i, _width,
			    red, green, blue, alpha))
				@throw [OFNotImplementedException
				    exceptionWithSelector: _cmd
						   object: self];
}
@end
