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
#import "OFConcreteMutableImage.h"

#import "OFInvalidArgumentException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfRangeException.h"

@interface OFPlaceholderMutableImage: OFImage
@end

static struct {
	Class isa;
} placeholder;

static OF_INLINE void
writeGrayscale8Pixel(uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
	if OF_UNLIKELY (red != green || red != blue || alpha != 255)
		@throw [OFOutOfRangeException exception];

	pixels[x + y * width] = red;
}

static OF_INLINE void
writeRGB565BEPixel(uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
	uint16_t value;

	if OF_UNLIKELY (alpha != 255)
		@throw [OFOutOfRangeException exception];

	value = ((red & 0xF8) << 8) | ((green & 0xFC) << 3) | (blue >> 3);

	pixels += (x + y * width) * 2;
	pixels[0] = value >> 8;
	pixels[1] = value;
}

static OF_INLINE void
writeRGB565LEPixel(uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
	uint16_t value;

	if OF_UNLIKELY (alpha != 255)
		@throw [OFOutOfRangeException exception];

	value = ((red & 0xF8) << 8) | ((green & 0xFC) << 3) | (blue >> 3);

	pixels += (x + y * width) * 2;
	pixels[0] = value;
	pixels[1] = value >> 8;
}

static OF_INLINE void
writeRGB888Pixel(uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
	if OF_UNLIKELY (alpha != 255)
		@throw [OFOutOfRangeException exception];

	pixels += (x + y * width) * 3;

	pixels[0] = red;
	pixels[1] = green;
	pixels[2] = blue;
}

static OF_INLINE void
writeRGBA8888Pixel(uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
	pixels += (x + y * width) * 4;

	pixels[0] = red;
	pixels[1] = green;
	pixels[2] = blue;
	pixels[3] = alpha;
}

static OF_INLINE void
writeARGB8888Pixel(uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
	pixels += (x + y * width) * 4;

	pixels[0] = alpha;
	pixels[1] = red;
	pixels[2] = green;
	pixels[3] = blue;
}

static OF_INLINE void
writeBGR565BEPixel(uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
	uint16_t value;

	if OF_UNLIKELY (alpha != 255)
		@throw [OFOutOfRangeException exception];

	value = ((blue & 0xF8) << 8) | ((green & 0xFC) << 3) | (red >> 3);

	pixels += (x + y * width) * 2;
	pixels[0] = value >> 8;
	pixels[1] = value;
}

static OF_INLINE void
writeBGR565LEPixel(uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
	uint16_t value;

	if OF_UNLIKELY (alpha != 255)
		@throw [OFOutOfRangeException exception];

	value = ((blue & 0xF8) << 8) | ((green & 0xFC) << 3) | (red >> 3);

	pixels += (x + y * width) * 2;
	pixels[0] = value;
	pixels[1] = value >> 8;
}

static OF_INLINE void
writeBGR888Pixel(uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
	if OF_UNLIKELY (alpha != 255)
		@throw [OFOutOfRangeException exception];

	pixels += (x + y * width) * 3;

	pixels[0] = blue;
	pixels[1] = green;
	pixels[2] = red;
}

static OF_INLINE void
writeABGR8888Pixel(uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
	pixels += (x + y * width) * 4;

	pixels[0] = alpha;
	pixels[1] = blue;
	pixels[2] = green;
	pixels[3] = red;
}

static OF_INLINE void
writeBGRA8888Pixel(uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
	pixels += (x + y * width) * 4;

	pixels[0] = blue;
	pixels[1] = green;
	pixels[2] = red;
	pixels[3] = alpha;
}

static OF_INLINE bool
writePixel(uint8_t *pixels, OFPixelFormat format, size_t x, size_t y,
    size_t width, uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
	switch (format) {
	case OFPixelFormatGrayscale8:
		writeGrayscale8Pixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatRGB565BE:
		writeRGB565BEPixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatRGB565LE:
		writeRGB565LEPixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatRGB888:
		writeRGB888Pixel(pixels, x, y, width, red, green, blue, alpha);
		return true;
	case OFPixelFormatRGBA8888:
		writeRGBA8888Pixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatARGB8888:
		writeARGB8888Pixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatBGR565BE:
		writeBGR565BEPixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatBGR565LE:
		writeBGR565LEPixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatBGR888:
		writeBGR888Pixel(pixels, x, y, width, red, green, blue, alpha);
		return true;
	case OFPixelFormatABGR8888:
		writeABGR8888Pixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatBGRA8888:
		writeBGRA8888Pixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	default:
		return false;
	}
}

@implementation OFPlaceholderMutableImage
- (instancetype)init
{
	return (id)[[OFConcreteMutableImage alloc] init];
}

- (instancetype)initWithPixels: (const void *)pixels
		   pixelFormat: (OFPixelFormat)pixelFormat
			  size: (OFSize)size
{
	return (id)[[OFConcreteMutableImage alloc] initWithPixels: pixels
						      pixelFormat: pixelFormat
							     size: size];
}

- (instancetype)initWithPixelsNoCopy: (const void *)pixels
			 pixelFormat: (OFPixelFormat)pixelFormat
				size: (OFSize)size
			freeWhenDone: (bool)freeWhenDone
{
	return (id)[[OFConcreteMutableImage alloc]
	    initWithPixelsNoCopy: pixels
		     pixelFormat: pixelFormat
			    size: size
		    freeWhenDone: freeWhenDone];
}

- (instancetype)initWithSize: (OFSize)size
		 pixelFormat: (OFPixelFormat)pixelFormat
{
	return (id)[[OFConcreteMutableImage alloc] initWithSize: size
						    pixelFormat: pixelFormat];
}
@end

@implementation OFMutableImage
@dynamic dotsPerInch;

+ (void)initialize
{
	if (self == [OFMutableImage class])
		object_setClass((id)&placeholder,
		    [OFPlaceholderMutableImage class]);
}

+ (instancetype)alloc
{
	if (self == [OFMutableImage class])
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

- (instancetype)initWithSize: (OFSize)size
		 pixelFormat: (OFPixelFormat)pixelFormat
{
	OF_INVALID_INIT_METHOD
}

- (void *)mutablePixels
{
	OF_UNRECOGNIZED_SELECTOR
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
	OFSize size = self.size;
	size_t width = size.width, height = size.height;
	float red, green, blue, alpha;

	if OF_UNLIKELY (x != point.x || y != point.y ||
	    width != size.width || height != size.height)
		@throw [OFInvalidArgumentException exception];

	if OF_UNLIKELY (x >= width || y >= height)
		@throw [OFOutOfRangeException exception];

	[color getRed: &red green: &green blue: &blue alpha: &alpha];

	/* All currently supported formats only allow 0.0 to 1.0 */
	if OF_UNLIKELY (red < 0.0f || red > 1.0f || green < 0.0f ||
	    green > 1.0f || blue < 0.0f || blue > 1.0f || alpha < 0.0f ||
	    alpha > 1.0f)
		@throw [OFOutOfRangeException exception];

	if OF_UNLIKELY (!writePixel(self.mutablePixels, self.pixelFormat, x, y,
	    width, red * 255.0f, green * 255.0f, blue * 255.0f, alpha * 255.0f))
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];
}

- (id)copy
{
	return [[OFImage alloc] initWithPixels: self.pixels
				   pixelFormat: self.pixelFormat
					  size: self.size];
}

- (void)makeImmutable
{
}
@end
