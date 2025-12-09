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

#import "OFImage.h"
#import "OFConcreteImage.h"

#import "OFInvalidArgumentException.h"

@interface OFPlaceholderImage: OFImage
@end

static struct {
	Class isa;
} placeholder;

@implementation OFPlaceholderImage
- (instancetype)init
{
	return (id)[[OFConcreteImage alloc] init];
}

- (instancetype)initWithWidth: (size_t)width
		       height: (size_t)height
		  pixelFormat: (OFPixelFormat)pixelFormat
{
	return (id)[[OFConcreteImage alloc] initWithWidth: width
						   height: height
					      pixelFormat: pixelFormat];
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

+ (instancetype)imageWithWidth: (size_t)width
			height: (size_t)height
		   pixelFormat: (OFPixelFormat)pixelFormat
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithWidth: width
				 height: height
			    pixelFormat: pixelFormat]);
}

- (instancetype)init
{
	if ([self isMemberOfClass: [OFImage class]]) {
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

- (instancetype)initWithWidth: (size_t)width
		       height: (size_t)height
		  pixelFormat: (OFPixelFormat)pixelFormat
{
	OF_INVALID_INIT_METHOD
}

- (size_t)width
{
	OF_UNRECOGNIZED_SELECTOR
}

- (size_t)height
{
	OF_UNRECOGNIZED_SELECTOR
}

- (unsigned int)bitsPerPixel
{
	switch (self.pixelFormat) {
	case OFPixelFormatUnknown:
		return 0;
	case OFPixelFormatGrayscale8:
		return 8;
	case OFPixelFormatRGB565:
		return 16;
	case OFPixelFormatRGB888:
		return 24;
	case OFPixelFormatRGBA8888:
		return 32;
	default:
		@throw [OFInvalidArgumentException exception];
	}
}

- (OFPixelFormat)pixelFormat
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void *)pixels
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)setPixelsPerInch: (float)pixelsPerInch
{
	if (pixelsPerInch < 0)
		@throw [OFInvalidArgumentException exception];

	_pixelsPerInch = pixelsPerInch;
}

- (float)pixelsPerInch
{
	return _pixelsPerInch;
}
@end
