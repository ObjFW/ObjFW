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
_OFReadRGBA8888Pixel(const uint32_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue, uint8_t *alpha)
{
	uint32_t value = pixels[x + y * width];

#ifdef OF_BIG_ENDIAN
	*red   = (value & 0xFF000000) >> 24;
	*green = (value & 0x00FF0000) >> 16;
	*blue  = (value & 0x0000FF00) >>  8;
	*alpha = (value & 0x000000FF);
#else
	*red   = (value & 0x000000FF);
	*green = (value & 0x0000FF00) >>  8;
	*blue  = (value & 0x00FF0000) >> 16;
	*alpha = (value & 0xFF000000) >> 24;
#endif
}

static OF_INLINE void
_OFReadARGB8888Pixel(const uint32_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue, uint8_t *alpha)
{
	uint32_t value = pixels[x + y * width];

#ifdef OF_BIG_ENDIAN
	*alpha = (value & 0xFF000000) >> 24;
	*red   = (value & 0x00FF0000) >> 16;
	*green = (value & 0x0000FF00) >>  8;
	*blue  = (value & 0x000000FF);
#else
	*alpha = (value & 0x000000FF);
	*red   = (value & 0x0000FF00) >>  8;
	*green = (value & 0x00FF0000) >> 16;
	*blue  = (value & 0xFF000000) >> 24;
#endif
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
_OFReadABGR8888Pixel(const uint32_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue, uint8_t *alpha)
{
	uint32_t value = pixels[x + y * width];

#ifdef OF_BIG_ENDIAN
	*alpha = (value & 0xFF000000) >> 24;
	*blue  = (value & 0x00FF0000) >> 16;
	*green = (value & 0x0000FF00) >>  8;
	*red   = (value & 0x000000FF);
#else
	*alpha = (value & 0x000000FF);
	*blue  = (value & 0x0000FF00) >>  8;
	*green = (value & 0x00FF0000) >> 16;
	*red   = (value & 0xFF000000) >> 24;
#endif
}

static OF_INLINE void
_OFReadBGRA8888Pixel(const uint32_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue, uint8_t *alpha)
{
	uint32_t value = pixels[x + y * width];

#ifdef OF_BIG_ENDIAN
	*blue  = (value & 0xFF000000) >> 24;
	*green = (value & 0x00FF0000) >> 16;
	*red   = (value & 0x0000FF00) >>  8;
	*alpha = (value & 0x000000FF);
#else
	*blue  = (value & 0x000000FF);
	*green = (value & 0x0000FF00) >>  8;
	*red   = (value & 0x00FF0000) >> 16;
	*alpha = (value & 0xFF000000) >> 24;
#endif
}

static OF_INLINE bool
_OFReadPixelInt(const void *pixels, OFPixelFormat format, size_t x, size_t y,
    size_t width, uint8_t *red, uint8_t *green, uint8_t *blue, uint8_t *alpha)
{
	switch (format) {
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
	uint8_t redInt = 0, greenInt = 0, blueInt = 0, alphaInt = 0;

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
_OFWriteRGBA8888Pixel(uint32_t *pixels, size_t x, size_t y, size_t width,
    uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
#ifdef OF_BIG_ENDIAN
	pixels[x + y * width] = red << 24 | green << 16 | blue << 8 | alpha;
#else
	pixels[x + y * width] = red | green << 8 | blue << 16 | alpha << 24;
#endif
}

static OF_INLINE void
_OFWriteARGB8888Pixel(uint32_t *pixels, size_t x, size_t y, size_t width,
    uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
#ifdef OF_BIG_ENDIAN
	pixels[x + y * width] = alpha << 24 | red << 16 | green << 8 | blue;
#else
	pixels[x + y * width] = alpha | red << 8 | green << 16 | blue << 24;
#endif
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
_OFWriteABGR8888Pixel(uint32_t *pixels, size_t x, size_t y, size_t width,
    uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
#ifdef OF_BIG_ENDIAN
	pixels[x + y * width] = alpha << 24 | blue << 16 | green << 8 | red;
#else
	pixels[x + y * width] = alpha | blue << 8 | green << 16 | red << 24;
#endif
}

static OF_INLINE void
_OFWriteBGRA8888Pixel(uint32_t *pixels, size_t x, size_t y, size_t width,
    uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
#ifdef OF_BIG_ENDIAN
	pixels[x + y * width] = blue << 24 | green << 16 | red << 8 | alpha;
#else
	pixels[x + y * width] = blue | green << 8 | red << 16 | alpha << 24;
#endif
}

static OF_INLINE bool
_OFWritePixel(void *pixels, OFPixelFormat format, size_t x, size_t y,
    size_t width, uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
	switch (format) {
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
