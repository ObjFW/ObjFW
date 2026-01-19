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
#import "OFOutOfRangeException.h"

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
			if OF_UNLIKELY (!_OFWritePixel(_pixels, _pixelFormat,
			    j, i, _width, red, green, blue, alpha))
				@throw [OFNotImplementedException
				    exceptionWithSelector: _cmd
						   object: self];
}

- (void)drawImage: (OFImage *)image
       sourceRect: (OFRect)sourceRect
  destinationRect: (OFRect)destinationRect
{
	const void *imagePixels = image.pixels;
	OFPixelFormat imagePixelFormat = image.pixelFormat;
	OFSize imageSize = image.size;
	size_t imageWidth = imageSize.width;
	size_t srcClampX, srcClampY;
	OFColorSpace *srcColorSpace;
	OFColorSpaceTransferFunction srcEOTF = NULL, srcOETF = NULL;
	float xScale, yScale;
	size_t destX, destY, destWidth, destHeight;
	OFColorSpace *destColorSpace;
	OFColorSpaceTransferFunction destEOTF = NULL, destOETF = NULL;

	if (sourceRect.origin.x < 0 || sourceRect.origin.y < 0 ||
	    sourceRect.size.width < 0 || sourceRect.size.height < 0)
		@throw [OFInvalidArgumentException exception];

	if (sourceRect.origin.x + sourceRect.size.width > imageSize.width ||
	    sourceRect.origin.y + sourceRect.size.height > imageSize.height)
		@throw [OFOutOfRangeException exception];

	srcClampX = sourceRect.origin.x + sourceRect.size.width;
	srcClampY = sourceRect.origin.y + sourceRect.size.height;

	if (srcClampX != sourceRect.origin.x + sourceRect.size.width ||
	    srcClampY != sourceRect.origin.y + sourceRect.size.height)
		@throw [OFInvalidArgumentException exception];

	srcColorSpace = image.colorSpace;
	if (!srcColorSpace.linear) {
		srcEOTF = srcColorSpace.EOTF;
		srcOETF = srcColorSpace.OETF;
	}

	/*
	 * Scale needs to be calculated before clamping destination to canvas.
	 */
	xScale = sourceRect.size.width / destinationRect.size.width;
	yScale = sourceRect.size.height / destinationRect.size.height;

	destinationRect = OFIntersectionRect(_rect, destinationRect);
	destX = destinationRect.origin.x;
	destY = destinationRect.origin.y;
	destWidth = destinationRect.size.width;
	destHeight = destinationRect.size.height;

	if (destX != destinationRect.origin.x ||
	    destY != destinationRect.origin.y ||
	    destWidth != destinationRect.size.width ||
	    destHeight != destinationRect.size.height)
		@throw [OFInvalidArgumentException exception];

	destColorSpace = _destinationImage.colorSpace;
	if (!destColorSpace.linear) {
		destEOTF = destColorSpace.EOTF;
		destOETF = destColorSpace.OETF;
	}

	for (size_t i = destY; i < destY + destHeight; i++) {
		for (size_t j = destX; j < destX + destWidth; j++) {
			OF_ALIGN(16) OFVector4D vec[2];

			if OF_UNLIKELY (!_OFReadAveragedPixel(imagePixels,
			    imagePixelFormat,
			    sourceRect.origin.x + (j - destX) * xScale,
			    sourceRect.origin.y + (i - destY) * yScale,
			    imageWidth, srcClampX, srcClampY, srcEOTF, srcOETF,
			    &vec[0].x, &vec[0].y, &vec[0].z, &vec[0].w))
				@throw [OFNotImplementedException
				    exceptionWithSelector: _cmd
						   object: self];

			if OF_UNLIKELY (vec[0].w != 1.0f) {
				if OF_UNLIKELY (!_OFReadPixel(_pixels,
				    _pixelFormat, j, i, _width,
				    &vec[1].x, &vec[1].y, &vec[1].z, &vec[1].w))
					@throw [OFNotImplementedException
					    exceptionWithSelector: _cmd
							   object: self];

				if (destEOTF != NULL)
					destEOTF(vec, 2);

				vec[0].x *= vec[0].w;
				vec[0].y *= vec[0].w;
				vec[0].z *= vec[0].w;

				vec[0] = OFAddVectors4D(vec[0],
				    OFMultiplyVector4D(
				    vec[1], 1.0f - vec[0].w));

				if (destOETF != NULL)
					destOETF(vec, 1);
			}

			if OF_UNLIKELY (!_OFWritePixel(_pixels, _pixelFormat,
			    j, i, _width, vec[0].x, vec[0].y, vec[0].z,
			    vec[0].w))
				@throw [OFNotImplementedException
				    exceptionWithSelector: _cmd
						   object: self];
		}
	}
}
@end
