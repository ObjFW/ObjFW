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

#import "OFQOIImageFormatHandler.h"
#import "OFImage+Private.h"
#import "OFSeekableStream.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfRangeException.h"

@implementation OFQOIImageFormatHandler
static OF_INLINE uint8_t
hashPixel(uint8_t pixel[4])
{
	return (pixel[0] * 3 + pixel[1] * 5 + pixel[2] * 7 +
	    pixel[3] * 11) % 64;
}

- (OFMutableImage *)readImageFromStream: (OFSeekableStream *)stream
{
	char magic[4];
	uint32_t width, height;
	OFSize size;
	OFPixelFormat format;
	OFMutableImage *image;
	uint8_t *pixels;
	uint8_t pixel[4] = { 0, 0, 0, 255 }, dict[256] = { 0 };
	char endMarker[8];

	[stream readIntoBuffer: magic exactLength: 4];
	if (memcmp(magic, "qoif", 4) != 0)
		@throw [OFInvalidFormatException exception];

	width = [stream readBigEndianInt32];
	height = [stream readBigEndianInt32];

	size.width = width;
	size.height = height;

	if (size.width != width || size.height != height)
		@throw [OFOutOfRangeException exception];

	switch ([stream readInt8]) {
	case 3:
	case 4:
#ifdef OF_BIG_ENDIAN
		format = OFPixelFormatRGBA8888;
#else
		format = OFPixelFormatABGR8888;
#endif
		break;
	default:
		@throw [OFInvalidFormatException exception];
	}

	/* colorspace = */ [stream readInt8];

	image = [OFMutableImage imageWithSize: size pixelFormat: format];
	pixels = image.mutablePixels;

	for (size_t pixelsRead = 0; pixelsRead < width * height; pixelsRead++) {
		uint8_t byte = [stream readInt8];

		/* QOI_OP_RGB */
		if (byte == 0xFE)
			[stream readIntoBuffer: pixel exactLength: 3];
		/* QOI_OP_RGBA */
		else if (byte == 0xFF)
			[stream readIntoBuffer: pixel exactLength: 4];
		/* QOI_OP_INDEX */
		else if ((byte & 0xC0) == 0)
			memcpy(pixel, dict + (byte & 0x3F) * 4, 4);
		/* QOI_OP_DIFF */
		else if ((byte & 0xC0) == 0x40) {
			pixel[0] += ((byte & 0x30) >> 4) - 2;
			pixel[1] += ((byte & 0x0C) >> 2) - 2;
			pixel[2] += (byte & 0x03) - 2;
		/* QOI_OP_LUMA */
		} else if ((byte & 0xC0) == 0x80) {
			uint8_t greenDiff = (byte & 0x3F) - 32;
			uint8_t byte2 = [stream readInt8];
			pixel[0] += greenDiff + ((byte2 & 0xF0) >> 4) - 8;
			pixel[1] += greenDiff;
			pixel[2] += greenDiff + (byte2 & 0x0F) - 8;
		/* QOI_OP_RUN */
		} else if ((byte & 0xC0) == 0xC0) {
			if (pixelsRead + (byte & 0x3F) >= width * height)
				@throw [OFOutOfRangeException exception];

			for (uint_fast8_t i = 0; i < (byte & 0x3F); i++)
				memcpy(pixels + pixelsRead++ * 4, pixel, 4);
		}

		memcpy(pixels + pixelsRead * 4, pixel, 4);
		memcpy(dict + hashPixel(pixel) * 4, pixel, 4);
	}

	[stream readIntoBuffer: endMarker exactLength: 8];
	if (memcmp(endMarker, "\0\0\0\0\0\0\0\x01", 8) != 0)
		@throw [OFInvalidFormatException exception];

	return image;
}

static OF_INLINE void
writeRunLength(OFStream *stream, size_t runLength)
{
	while (runLength > 0) {
		size_t len = (runLength <= 62 ? runLength : 62);
		[stream writeInt8: 0xC0 | (len - 1)];
		runLength -= len;
	}
}

static OF_INLINE bool
calcDiff(uint8_t pixel[4], uint8_t previousPixel[4], uint8_t *diff)
{
	uint8_t redDiff, greenDiff, blueDiff;

	if (pixel[3] != previousPixel[3])
		return false;

	redDiff = pixel[0] - previousPixel[0] + 2;
	greenDiff = pixel[1] - previousPixel[1] + 2;
	blueDiff = pixel[2] - previousPixel[2] + 2;

	if (redDiff > 3 || greenDiff > 3 || blueDiff > 3)
		return false;

	*diff = 0x40 | redDiff << 4 | greenDiff << 2 | blueDiff;
	return true;
}

static OF_INLINE bool
calcLuma(uint8_t pixel[4], uint8_t previousPixel[4], uint8_t luma[2])
{
	uint8_t redDiff, greenDiff, blueDiff, greenRedDiff, greenBlueDiff;

	if (pixel[3] != previousPixel[3])
		return false;

	/* Do the calculation unsigned so that we have defined wrap around. */
	redDiff = pixel[0] - previousPixel[0] + 32;
	greenDiff = pixel[1] - previousPixel[1] + 32;
	blueDiff = pixel[2] - previousPixel[2] + 32;

	if (greenDiff > 63)
		return false;

	greenRedDiff = redDiff - greenDiff + 8;
	greenBlueDiff = blueDiff - greenDiff + 8;

	if (greenRedDiff > 15 || greenBlueDiff > 15)
		return false;

	luma[0] = 0x80 | greenDiff;
	luma[1] = greenRedDiff << 4 | greenBlueDiff;
	return true;
}

- (void)writeImage: (OFImage *)image
	  toStream: (OFSeekableStream *)stream
	   options: (OFDictionary OF_GENERIC(OFString *, id) *)options
{
	OFSize size = image.size;
	uint32_t width = size.width, height = size.height;
	const void *pixels;
	OFPixelFormat format;
	uint8_t previousPixel[4] = { 0, 0, 0, 255 }, dict[256] = { 0 };
	size_t runLength = 0;

	if (width != size.width || height != size.height)
		@throw [OFInvalidArgumentException exception];

	[stream writeString: @"qoif"];
	[stream writeBigEndianInt32: width];
	[stream writeBigEndianInt32: height];

	pixels = image.pixels;
	format = image.pixelFormat;

	switch (format) {
	case OFPixelFormatRGB888:
	case OFPixelFormatBGR888:
		[stream writeInt8: 3];
		break;
	default:
		[stream writeInt8: 4];
		break;
	}

	[stream writeInt8: 0]; /* colorspace */

	for (size_t y = 0; y < height; y++) {
		for (size_t x = 0; x < width; x++) {
			uint8_t pixel[4], hash, diff, luma[2];

			if OF_UNLIKELY (!_OFReadPixelInt8(pixels, format, x, y,
			    width, &pixel[0], &pixel[1], &pixel[2], &pixel[3]))
				@throw [OFNotImplementedException
				    exceptionWithSelector: _cmd
						   object: self];

			if (memcmp(pixel, previousPixel, 4) == 0) {
				runLength++;
				continue;
			}

			writeRunLength(stream, runLength);
			runLength = 0;

			hash = hashPixel(pixel);
			if (memcmp(dict + hash * 4, pixel, 4) == 0)
				[stream writeInt8: hash];
			else if (calcDiff(pixel, previousPixel, &diff))
				[stream writeInt8: diff];
			else if (calcLuma(pixel, previousPixel, luma))
				[stream writeBuffer: luma length: 2];
			else if (pixel[3] == previousPixel[3]) {
				[stream writeInt8: 0xFE];
				[stream writeBuffer: pixel length: 3];
			} else {
				[stream writeInt8: 0xFF];
				[stream writeBuffer: pixel length: 4];
			}

			memcpy(dict + hash * 4, pixel, 4);
			memcpy(previousPixel, pixel, 4);
		}
	}
	writeRunLength(stream, runLength);

	[stream writeBuffer: "\0\0\0\0\0\0\0\x01" length: 8];
}
@end
