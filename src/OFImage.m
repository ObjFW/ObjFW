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
#import "OFColor.h"
#import "OFConcreteImage.h"

#import "OFInvalidArgumentException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfRangeException.h"

@interface OFPlaceholderImage: OFImage
@end

static struct {
	Class isa;
} placeholder;

static OF_INLINE void
readGrayscale8Pixel(const uint8_t *pixels, size_t x, size_t y, size_t width,
    float *red, float *green, float *blue)
{
	*red = *green = *blue = pixels[x + y * width] / 255.0f;
}

static OF_INLINE void
readRGB888Pixel(const uint8_t *pixels, size_t x, size_t y, size_t width,
    float *red, float *green, float *blue)
{
	pixels += (x + y * width) * 3;

	*red = pixels[0] / 255.0f;
	*green = pixels[1] / 255.0f;
	*blue = pixels[2] / 255.0f;
}

static OF_INLINE void
readRGBA8888Pixel(const uint8_t *pixels, size_t x, size_t y, size_t width,
    float *red, float *green, float *blue, float *alpha)
{
	pixels += (x + y * width) * 4;

	*red = pixels[0] / 255.0f;
	*green = pixels[1] / 255.0f;
	*blue = pixels[2] / 255.0f;
	*alpha = pixels[3] / 255.0f;
}

static OF_INLINE bool
readPixel(const uint8_t *pixels, OFPixelFormat format, size_t x, size_t y,
    size_t width, float *red, float *green, float *blue, float *alpha)
{
	switch (format) {
	case OFPixelFormatGrayscale8:
		readGrayscale8Pixel(pixels, x, y, width, red, green, blue);
		return true;
	case OFPixelFormatRGB888:
		readRGB888Pixel(pixels, x, y, width, red, green, blue);
		return true;
	case OFPixelFormatRGBA8888:
		readRGBA8888Pixel(pixels, x, y, width, red, green, blue, alpha);
		return true;
	default:
		return false;
	}
}

static OF_INLINE void
writeGrayscale8Pixel(uint8_t *pixels, size_t x, size_t y, size_t width,
    float red, float green, float blue)
{
	pixels[x + y * width] = (uint8_t)(red * 255.0f);
}

static OF_INLINE void
writeRGB888Pixel(uint8_t *pixels, size_t x, size_t y, size_t width,
    float red, float green, float blue)
{
	pixels += (x + y * width) * 3;

	pixels[0] = (uint8_t)(red * 255.0f);
	pixels[1] = (uint8_t)(green * 255.0f);
	pixels[2] = (uint8_t)(blue * 255.0f);
}

static OF_INLINE void
writeRGBA8888Pixel(uint8_t *pixels, size_t x, size_t y, size_t width,
    float red, float green, float blue, float alpha)
{
	pixels += (x + y * width) * 4;

	pixels[0] = (uint8_t)(red * 255.0f);
	pixels[1] = (uint8_t)(green * 255.0f);
	pixels[2] = (uint8_t)(blue * 255.0f);
	pixels[3] = (uint8_t)(alpha * 255.0f);
}

static OF_INLINE bool
writePixel(uint8_t *pixels, OFPixelFormat format, size_t x, size_t y,
    size_t width, float red, float green, float blue, float alpha)
{
	/* All currently supported formats only allow 0.0 to 1.0 */
	if (red < 0.0f || red > 1.0f || green < 0.0f || green > 1.0f ||
	    blue < 0.0f || blue > 1.0f || alpha < 0.0f || alpha > 1.0f)
		@throw [OFOutOfRangeException exception];

	switch (format) {
	case OFPixelFormatGrayscale8:
		if (red != green || red != blue || alpha != 1.0f)
			@throw [OFOutOfRangeException exception];

		writeGrayscale8Pixel(pixels, x, y, width, red, green, blue);
		return true;
	case OFPixelFormatRGB888:
		if (alpha != 1.0f)
			@throw [OFOutOfRangeException exception];

		writeRGB888Pixel(pixels, x, y, width, red, green, blue);
		return true;
	case OFPixelFormatRGBA8888:
		writeRGBA8888Pixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	default:
		return false;
	}
}

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

- (OFColor *)colorForPixelAtPosition: (OFPoint)position
{
	size_t x = position.x, y = position.y;
	OFSize size = self.size;
	size_t width = size.width, height = size.height;
	float red, green, blue, alpha = 1.0f;

	if (x != position.x || y != position.y ||
	    width != size.width || height != size.height)
		@throw [OFInvalidArgumentException exception];

	if (x >= width || y >= height)
		@throw [OFOutOfRangeException exception];

	if (!readPixel(self.pixels, self.pixelFormat, x, y, width, &red,
	    &green, &blue, &alpha))
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	return [OFColor colorWithRed: red green: green blue: blue alpha: alpha];
}

- (void)setColor: (OFColor *)color forPixelAtPosition: (OFPoint)position
{
	size_t x = position.x, y = position.y;
	OFSize size = self.size;
	size_t width = size.width, height = size.height;
	float red, green, blue, alpha;

	if (x != position.x || y != position.y ||
	    width != size.width || height != size.height)
		@throw [OFInvalidArgumentException exception];

	if (x >= width || y >= height)
		@throw [OFOutOfRangeException exception];

	[color getRed: &red green: &green blue: &blue alpha: &alpha];

	if (!writePixel(self.pixels, self.pixelFormat, x, y, width, red,
	    green, blue, alpha))
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];
}
@end
