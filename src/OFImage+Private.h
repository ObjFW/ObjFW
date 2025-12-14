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

#import "OFImage.h"

#import "OFOutOfRangeException.h"

static OF_INLINE void
_OFReadGrayscale8Pixel(const uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue, uint8_t *alpha)
{
	*red = *green = *blue = pixels[x + y * width];
	*alpha = 255;
}

static OF_INLINE void
_OFReadRGB565BEPixel(const uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue, uint8_t *alpha)
{
	uint16_t value;

	pixels += (x + y * width) * 2;
	value = (pixels[0] << 8 | pixels[1]);

	*red = (value & 0xF800) >> 8;
	*green = (value & 0x7E0) >> 3;
	*blue = (value & 0x1F) << 3;
	*alpha = 255;
}

static OF_INLINE void
_OFReadRGB565LEPixel(const uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue, uint8_t *alpha)
{
	uint16_t value;

	pixels += (x + y * width) * 2;
	value = (pixels[1] << 8 | pixels[0]);

	*red = (value & 0xF800) >> 8;
	*green = (value & 0x7E0) >> 3;
	*blue = (value & 0x1F) << 3;
	*alpha = 255;
}

static OF_INLINE void
_OFReadRGB888Pixel(const uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue, uint8_t *alpha)
{
	pixels += (x + y * width) * 3;

	*red = pixels[0];
	*green = pixels[1];
	*blue = pixels[2];
	*alpha = 255;
}

static OF_INLINE void
_OFReadRGBA8888Pixel(const uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue, uint8_t *alpha)
{
	pixels += (x + y * width) * 4;

	*red = pixels[0];
	*green = pixels[1];
	*blue = pixels[2];
	*alpha = pixels[3];
}

static OF_INLINE void
_OFReadARGB8888Pixel(const uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue, uint8_t *alpha)
{
	pixels += (x + y * width) * 4;

	*red = pixels[1];
	*green = pixels[2];
	*blue = pixels[3];
	*alpha = pixels[0];
}

static OF_INLINE void
_OFReadBGR565BEPixel(const uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue, uint8_t *alpha)
{
	uint16_t value;

	pixels += (x + y * width) * 2;
	value = (pixels[0] << 8 | pixels[1]);

	*red = (value & 0x1F) << 3;
	*green = (value & 0x7E0) >> 3;
	*blue = (value & 0xF800) >> 8;
	*alpha = 255;
}

static OF_INLINE void
_OFReadBGR565LEPixel(const uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue, uint8_t *alpha)
{
	uint16_t value;

	pixels += (x + y * width) * 2;
	value = (pixels[1] << 8 | pixels[0]);

	*red = (value & 0x1F) << 3;
	*green = (value & 0x7E0) >> 3;
	*blue = (value & 0xF800) >> 8;
	*alpha = 255;
}

static OF_INLINE void
_OFReadBGR888Pixel(const uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue, uint8_t *alpha)
{
	pixels += (x + y * width) * 3;

	*blue = pixels[0];
	*green = pixels[1];
	*red = pixels[2];
	*alpha = 255;
}

static OF_INLINE void
_OFReadABGR8888Pixel(const uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue, uint8_t *alpha)
{
	pixels += (x + y * width) * 4;

	*red = pixels[3];
	*green = pixels[2];
	*blue = pixels[1];
	*alpha = pixels[0];
}

static OF_INLINE void
_OFReadBGRA8888Pixel(const uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue, uint8_t *alpha)
{
	pixels += (x + y * width) * 4;

	*red = pixels[2];
	*green = pixels[1];
	*blue = pixels[0];
	*alpha = pixels[3];
}

static OF_INLINE bool
_OFReadPixelInt(const uint8_t *pixels, OFPixelFormat format, size_t x, size_t y,
    size_t width, uint8_t *red, uint8_t *green, uint8_t *blue, uint8_t *alpha)
{
	switch (format) {
	case OFPixelFormatGrayscale8:
		_OFReadGrayscale8Pixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatRGB565BE:
		_OFReadRGB565BEPixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatRGB565LE:
		_OFReadRGB565LEPixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatRGB888:
		_OFReadRGB888Pixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatRGBA8888:
		_OFReadRGBA8888Pixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatARGB8888:
		_OFReadARGB8888Pixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatBGR565BE:
		_OFReadBGR565BEPixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatBGR565LE:
		_OFReadBGR565LEPixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatBGR888:
		_OFReadBGR888Pixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatABGR8888:
		_OFReadABGR8888Pixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatBGRA8888:
		_OFReadBGRA8888Pixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	default:
		return false;
	}
}

static OF_INLINE bool
_OFReadPixel(const uint8_t *pixels, OFPixelFormat format, size_t x, size_t y,
    size_t width, float *red, float *green, float *blue, float *alpha)
{
	uint8_t redInt, greenInt, blueInt, alphaInt;

	if OF_UNLIKELY (!_OFReadPixelInt(pixels, format, x, y, width,
	    &redInt, &greenInt, &blueInt, &alphaInt))
		return false;

	*red = redInt / 255.0f;
	*green = greenInt / 255.0f;
	*blue = blueInt / 255.0f;
	*alpha = alphaInt / 255.0f;

	return true;
}

static OF_INLINE void
_OFWriteGrayscale8Pixel(uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
	if OF_UNLIKELY (red != green || red != blue || alpha != 255)
		@throw [OFOutOfRangeException exception];

	pixels[x + y * width] = red;
}

static OF_INLINE void
_OFWriteRGB565BEPixel(uint8_t *pixels, size_t x, size_t y, size_t width,
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
_OFWriteRGB565LEPixel(uint8_t *pixels, size_t x, size_t y, size_t width,
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
_OFWriteRGB888Pixel(uint8_t *pixels, size_t x, size_t y, size_t width,
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
_OFWriteRGBA8888Pixel(uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
	pixels += (x + y * width) * 4;

	pixels[0] = red;
	pixels[1] = green;
	pixels[2] = blue;
	pixels[3] = alpha;
}

static OF_INLINE void
_OFWriteARGB8888Pixel(uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
	pixels += (x + y * width) * 4;

	pixels[0] = alpha;
	pixels[1] = red;
	pixels[2] = green;
	pixels[3] = blue;
}

static OF_INLINE void
_OFWriteBGR565BEPixel(uint8_t *pixels, size_t x, size_t y, size_t width,
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
_OFWriteBGR565LEPixel(uint8_t *pixels, size_t x, size_t y, size_t width,
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
_OFWriteBGR888Pixel(uint8_t *pixels, size_t x, size_t y, size_t width,
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
_OFWriteABGR8888Pixel(uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
	pixels += (x + y * width) * 4;

	pixels[0] = alpha;
	pixels[1] = blue;
	pixels[2] = green;
	pixels[3] = red;
}

static OF_INLINE void
_OFWriteBGRA8888Pixel(uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
	pixels += (x + y * width) * 4;

	pixels[0] = blue;
	pixels[1] = green;
	pixels[2] = red;
	pixels[3] = alpha;
}

static OF_INLINE bool
_OFWritePixel(uint8_t *pixels, OFPixelFormat format, size_t x, size_t y,
    size_t width, uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
	switch (format) {
	case OFPixelFormatGrayscale8:
		_OFWriteGrayscale8Pixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatRGB565BE:
		_OFWriteRGB565BEPixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatRGB565LE:
		_OFWriteRGB565LEPixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatRGB888:
		_OFWriteRGB888Pixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatRGBA8888:
		_OFWriteRGBA8888Pixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatARGB8888:
		_OFWriteARGB8888Pixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatBGR565BE:
		_OFWriteBGR565BEPixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatBGR565LE:
		_OFWriteBGR565LEPixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatBGR888:
		_OFWriteBGR888Pixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatABGR8888:
		_OFWriteABGR8888Pixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	case OFPixelFormatBGRA8888:
		_OFWriteBGRA8888Pixel(pixels, x, y, width, red, green, blue,
		    alpha);
		return true;
	default:
		return false;
	}
}
