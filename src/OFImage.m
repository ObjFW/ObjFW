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
    uint8_t *red, uint8_t *green, uint8_t *blue)
{
	*red = *green = *blue = pixels[x + y * width];
}

static OF_INLINE void
readRGB565BEPixel(const uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue)
{
	uint16_t value;

	pixels += (x + y * width) * 2;
	value = (pixels[0] << 8 | pixels[1]);

	*red = (value & 0xF800) >> 8;
	*green = (value & 0x7E0) >> 3;
	*blue = (value & 0x1F) << 3;
}

static OF_INLINE void
readRGB565LEPixel(const uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue)
{
	uint16_t value;

	pixels += (x + y * width) * 2;
	value = (pixels[1] << 8 | pixels[0]);

	*red = (value & 0xF800) >> 8;
	*green = (value & 0x7E0) >> 3;
	*blue = (value & 0x1F) << 3;
}

static OF_INLINE void
readRGB888Pixel(const uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue)
{
	pixels += (x + y * width) * 3;

	*red = pixels[0];
	*green = pixels[1];
	*blue = pixels[2];
}

static OF_INLINE void
readRGBA8888Pixel(const uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue, uint8_t *alpha)
{
	pixels += (x + y * width) * 4;

	*red = pixels[0];
	*green = pixels[1];
	*blue = pixels[2];
	*alpha = pixels[3];
}

static OF_INLINE void
readARGB8888Pixel(const uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue, uint8_t *alpha)
{
	pixels += (x + y * width) * 4;

	*alpha = pixels[0];
	*red = pixels[1];
	*green = pixels[2];
	*blue = pixels[3];
}

static OF_INLINE void
readBGR565BEPixel(const uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue)
{
	uint16_t value;

	pixels += (x + y * width) * 2;
	value = (pixels[0] << 8 | pixels[1]);

	*blue = (value & 0xF800) >> 8;
	*green = (value & 0x7E0) >> 3;
	*red = (value & 0x1F) << 3;
}

static OF_INLINE void
readBGR565LEPixel(const uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue)
{
	uint16_t value;

	pixels += (x + y * width) * 2;
	value = (pixels[1] << 8 | pixels[0]);

	*blue = (value & 0xF800) >> 8;
	*green = (value & 0x7E0) >> 3;
	*red = (value & 0x1F) << 3;
}

static OF_INLINE void
readBGR888Pixel(const uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue)
{
	pixels += (x + y * width) * 3;

	*blue = pixels[0];
	*green = pixels[1];
	*red = pixels[2];
}

static OF_INLINE void
readABGR8888Pixel(const uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue, uint8_t *alpha)
{
	pixels += (x + y * width) * 4;

	*alpha = pixels[0];
	*blue = pixels[1];
	*green = pixels[2];
	*red = pixels[3];
}

static OF_INLINE void
readBGRA8888Pixel(const uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue, uint8_t *alpha)
{
	pixels += (x + y * width) * 4;

	*blue = pixels[0];
	*green = pixels[1];
	*red = pixels[2];
	*alpha = pixels[3];
}

static OF_INLINE bool
readPixel(const uint8_t *pixels, OFPixelFormat format, size_t x, size_t y,
    size_t width, uint8_t *red, uint8_t *green, uint8_t *blue, uint8_t *alpha)
{
	switch (format) {
	case OFPixelFormatGrayscale8:
		readGrayscale8Pixel(pixels, x, y, width, red, green, blue);
		return true;
	case OFPixelFormatRGB565BE:
		readRGB565BEPixel(pixels, x, y, width, red, green, blue);
		return true;
	case OFPixelFormatRGB565LE:
		readRGB565LEPixel(pixels, x, y, width, red, green, blue);
		return true;
	case OFPixelFormatRGB888:
		readRGB888Pixel(pixels, x, y, width, red, green, blue);
		return true;
	case OFPixelFormatRGBA8888:
		readRGBA8888Pixel(pixels, x, y, width, red, green, blue, alpha);
		return true;
	case OFPixelFormatARGB8888:
		readARGB8888Pixel(pixels, x, y, width, red, green, blue, alpha);
		return true;
	case OFPixelFormatBGR565BE:
		readBGR565BEPixel(pixels, x, y, width, red, green, blue);
		return true;
	case OFPixelFormatBGR565LE:
		readBGR565LEPixel(pixels, x, y, width, red, green, blue);
		return true;
	case OFPixelFormatBGR888:
		readBGR888Pixel(pixels, x, y, width, red, green, blue);
		return true;
	case OFPixelFormatABGR8888:
		readABGR8888Pixel(pixels, x, y, width, red, green, blue, alpha);
		return true;
	case OFPixelFormatBGRA8888:
		readBGRA8888Pixel(pixels, x, y, width, red, green, blue, alpha);
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

- (instancetype)initWithPixels: (const void *)pixels
		   pixelFormat: (OFPixelFormat)pixelFormat
			  size: (OFSize)size
{
	return (id)[[OFConcreteImage alloc] initWithPixels: pixels
					       pixelFormat: pixelFormat
						      size: size];
}

- (instancetype)initWithPixelsNoCopy: (const void *)pixels
			 pixelFormat: (OFPixelFormat)pixelFormat
				size: (OFSize)size
			freeWhenDone: (bool)freeWhenDone
{
	return (id)[[OFConcreteImage alloc] initWithPixelsNoCopy: pixels
						     pixelFormat: pixelFormat
							    size: size
						    freeWhenDone: freeWhenDone];
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

+ (instancetype)imageWithPixels: (const void *)pixels
		    pixelFormat: (OFPixelFormat)pixelFormat
			   size: (OFSize)size
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithPixels: pixels
			     pixelFormat: pixelFormat
				    size: size]);
}

+ (instancetype)imageWithPixelsNoCopy: (const void *)pixels
			  pixelFormat: (OFPixelFormat)pixelFormat
				 size: (OFSize)size
			 freeWhenDone: (bool)freeWhenDone
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithPixelsNoCopy: pixels
				   pixelFormat: pixelFormat
					  size: size
				  freeWhenDone: freeWhenDone]);
}

- (instancetype)init
{
	if ([self isMemberOfClass: [OFImage class]] ||
	    [self isMemberOfClass: [OFMutableImage class]]) {
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

- (instancetype)initWithPixels: (const void *)pixels
		   pixelFormat: (OFPixelFormat)pixelFormat
			  size: (OFSize)size
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithPixelsNoCopy: (const void *)pixels
			 pixelFormat: (OFPixelFormat)pixelFormat
				size: (OFSize)size
			freeWhenDone: (bool)freeWhenDone
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
	case OFPixelFormatRGB565BE:
	case OFPixelFormatRGB565LE:
	case OFPixelFormatBGR565BE:
	case OFPixelFormatBGR565LE:
		return 16;
	case OFPixelFormatRGB888:
	case OFPixelFormatBGR888:
		return 24;
	case OFPixelFormatRGBA8888:
	case OFPixelFormatARGB8888:
	case OFPixelFormatABGR8888:
	case OFPixelFormatBGRA8888:
		return 32;
	default:
		@throw [OFInvalidArgumentException exception];
	}
}

- (OFPixelFormat)pixelFormat
{
	OF_UNRECOGNIZED_SELECTOR
}

- (const void *)pixels
{
	OF_UNRECOGNIZED_SELECTOR
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
	uint8_t red, green, blue, alpha = 255;

	if (x != position.x || y != position.y ||
	    width != size.width || height != size.height)
		@throw [OFInvalidArgumentException exception];

	if (x >= width || y >= height)
		@throw [OFOutOfRangeException exception];

	if (!readPixel(self.pixels, self.pixelFormat, x, y, width, &red,
	    &green, &blue, &alpha))
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	return [OFColor colorWithRed: red / 255.0f
			       green: green / 255.0f
				blue: blue / 255.0f
			       alpha: alpha / 255.0f];
}
@end
