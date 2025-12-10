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

- (instancetype)initWithSize: (OFSize)size
		 pixelFormat: (OFPixelFormat)pixelFormat
{
	return (id)[[OFConcreteImage alloc] initWithSize: size
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

+ (instancetype)imageWithSize: (OFSize)size
		  pixelFormat: (OFPixelFormat)pixelFormat
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithSize: size
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

- (instancetype)initWithSize: (OFSize)size
		 pixelFormat: (OFPixelFormat)pixelFormat
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

- (void)setDotsPerInch: (OFSize)dotsPerInch
{
	if (dotsPerInch.width < 0 || dotsPerInch.height < 0)
		@throw [OFInvalidArgumentException exception];

	_dotsPerInch = dotsPerInch;
}

- (OFSize)dotsPerInch
{
	return _dotsPerInch;
}
@end
