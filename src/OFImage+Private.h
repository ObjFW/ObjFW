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

#import "OFImage.h"

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

	*red   = (value & 0xFF000000) >> 24;
	*green = (value & 0x00FF0000) >> 16;
	*blue  = (value & 0x0000FF00) >>  8;
	*alpha = (value & 0x000000FF);
}

static OF_INLINE void
_OFReadARGB8888Pixel(const uint32_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue, uint8_t *alpha)
{
	uint32_t value = pixels[x + y * width];

	*red   = (value & 0x00FF0000) >> 16;
	*green = (value & 0x0000FF00) >>  8;
	*blue  = (value & 0x000000FF);
	*alpha = (value & 0xFF000000) >> 24;
}

static OF_INLINE void
_OFReadBGR888Pixel(const uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue, uint8_t *alpha)
{
	pixels += (x + y * width) * 3;

	*red = pixels[2];
	*green = pixels[1];
	*blue = pixels[0];
	*alpha = 255;
}

static OF_INLINE void
_OFReadABGR8888Pixel(const uint32_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue, uint8_t *alpha)
{
	uint32_t value = pixels[x + y * width];

	*red   = (value & 0x000000FF);
	*green = (value & 0x0000FF00) >>  8;
	*blue  = (value & 0x00FF0000) >> 16;
	*alpha = (value & 0xFF000000) >> 24;
}

static OF_INLINE void
_OFReadBGRA8888Pixel(const uint32_t *pixels, size_t x, size_t y, size_t width,
    uint8_t *red, uint8_t *green, uint8_t *blue, uint8_t *alpha)
{
	uint32_t value = pixels[x + y * width];

	*red   = (value & 0x0000FF00) >>  8;
	*green = (value & 0x00FF0000) >> 16;
	*blue  = (value & 0xFF000000) >> 24;
	*alpha = (value & 0x000000FF);
}

static OF_INLINE bool
_OFReadPixelInt8(const void *pixels, OFPixelFormat format, size_t x, size_t y,
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
_OFReadPixel(const void *pixels, OFPixelFormat format, size_t x, size_t y,
    size_t width, float *red, float *green, float *blue, float *alpha)
{
	uint8_t redInt8 = 0, greenInt8 = 0, blueInt8 = 0, alphaInt8 = 0;

	if OF_UNLIKELY (!_OFReadPixelInt8(pixels, format, x, y, width,
	    &redInt8, &greenInt8, &blueInt8, &alphaInt8))
		return false;

	*red = redInt8 / 255.0f;
	*green = greenInt8 / 255.0f;
	*blue = blueInt8 / 255.0f;
	*alpha = alphaInt8 / 255.0f;

	return true;
}

static OF_INLINE bool
_OFReadAveragedPixel(const void *pixels, OFPixelFormat format, float x, float y,
    size_t width, size_t clampX, size_t clampY, float *red, float *green,
    float *blue, float *alpha)
{
	size_t xInt = x, yInt = y, nextXInt = xInt + 1, nextYInt = yInt + 1;
	float reds[4], greens[4], blues[4], alphas[4];
	float scales[4];

	if (x == xInt && y == yInt)
		return _OFReadPixel(pixels, format, xInt, yInt, width,
		    red, green, blue, alpha);

	if (nextXInt >= clampX || x == xInt)
		nextXInt = xInt;
	if (nextYInt >= clampY || y == yInt)
		nextYInt = yInt;

	if (!_OFReadPixel(pixels, format, xInt, yInt, width,
	    &reds[0], &greens[0], &blues[0], &alphas[0]))
		return false;

	if (!_OFReadPixel(pixels, format, nextXInt, yInt, width,
	    &reds[1], &greens[1], &blues[1], &alphas[1]))
		return false;

	if (!_OFReadPixel(pixels, format, xInt, nextYInt, width,
	    &reds[2], &greens[2], &blues[2], &alphas[2]))
		return false;

	if (!_OFReadPixel(pixels, format, nextXInt, nextYInt, width,
	    &reds[3], &greens[3], &blues[3], &alphas[3]))
		return false;

	scales[0] = (1.0f - (x - xInt)) * (1.0f - (y - yInt));
	scales[1] = (x - xInt) * (1.0f - (y - yInt));
	scales[2] = (1.0f - (x - xInt)) * (y - yInt);
	scales[3] = (x - xInt) * (y - yInt);

	*red = *green = *blue = *alpha = 0.0f;
	for (uint_fast8_t i = 0; i < 4; i++) {
		*red += scales[i] * reds[i];
		*green += scales[i] * greens[i];
		*blue += scales[i] * blues[i];
		*alpha += scales[i] * alphas[i];
	}

	return true;
}

static OF_INLINE void
_OFWriteRGB888Pixel(uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
	pixels += (x + y * width) * 3;

	pixels[0] = red;
	pixels[1] = green;
	pixels[2] = blue;
}

static OF_INLINE void
_OFWriteRGBA8888Pixel(uint32_t *pixels, size_t x, size_t y, size_t width,
    uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
	pixels[x + y * width] = red << 24 | green << 16 | blue << 8 | alpha;
}

static OF_INLINE void
_OFWriteARGB8888Pixel(uint32_t *pixels, size_t x, size_t y, size_t width,
    uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
	pixels[x + y * width] = alpha << 24 | red << 16 | green << 8 | blue;
}

static OF_INLINE void
_OFWriteBGR888Pixel(uint8_t *pixels, size_t x, size_t y, size_t width,
    uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
	pixels += (x + y * width) * 3;

	pixels[0] = blue;
	pixels[1] = green;
	pixels[2] = red;
}

static OF_INLINE void
_OFWriteABGR8888Pixel(uint32_t *pixels, size_t x, size_t y, size_t width,
    uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
	pixels[x + y * width] = alpha << 24 | blue << 16 | green << 8 | red;
}

static OF_INLINE void
_OFWriteBGRA8888Pixel(uint32_t *pixels, size_t x, size_t y, size_t width,
    uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
	pixels[x + y * width] = blue << 24 | green << 16 | red << 8 | alpha;
}

static OF_INLINE bool
_OFWritePixelInt8(void *pixels, OFPixelFormat format, size_t x, size_t y,
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

static OF_INLINE bool
_OFWritePixel(void *pixels, OFPixelFormat format, size_t x, size_t y,
    size_t width, float red, float green, float blue, float alpha)
{
	/* All currently supported formats only allow 0.0 to 1.0 */
	if OF_UNLIKELY (red > 1.0f)
		red = 1.0f;
	else if OF_UNLIKELY (red < 0.0f)
		red = 0.0f;
	if OF_UNLIKELY (green > 1.0f)
		green = 1.0f;
	else if OF_UNLIKELY (green < 0.0f)
		green = 0.0f;
	if OF_UNLIKELY (blue > 1.0f)
		blue = 1.0f;
	else if OF_UNLIKELY (blue < 0.0f)
		blue = 0.0f;
	if OF_UNLIKELY (alpha > 1.0f)
		alpha = 1.0f;
	else if OF_UNLIKELY (alpha < 0.0f)
		alpha = 0.0f;

	return _OFWritePixelInt8(pixels, format, x, y, width,
	    roundf(red * 255.0f), roundf(green * 255.0f), roundf(blue * 255.0f),
	    roundf(alpha * 255.0f));
}
