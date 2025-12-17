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

#import "OFQOIImageFormatHandler.h"
#import "OFImage+Private.h"
#import "OFSeekableStream.h"

#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

@implementation OFQOIImageFormatHandler
- (OFImage *)readImageFromStream: (OFSeekableStream *)stream
{
	char magic[4];
	uint32_t width, height;
	OFSize size;
	OFPixelFormat format;
	OFMutableImage *image;
	uint8_t *pixels;
	uint8_t pixel[4] = { 0, 0, 0, 0xFF }, dict[256] = { 0 };
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
		format = OFPixelFormatRGBA8888;
		break;
	default:
		@throw [OFInvalidFormatException exception];
	}

	/* colorspace = */ [stream readInt8];

	image = [OFMutableImage imageWithSize: size pixelFormat: format];
	pixels = image.mutablePixels;

	for (size_t pixelsRead = 0; pixelsRead < width * height; pixelsRead++) {
		uint8_t byte = [stream readInt8], hash;

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
		hash = (pixel[0] * 3 + pixel[1] * 5 + pixel[2] * 7 +
		    pixel[3] * 11) % 64;
		memcpy(dict + hash * 4, pixel, 4);
	}

	[stream readIntoBuffer: endMarker exactLength: 8];
	if (memcmp(endMarker, "\0\0\0\0\0\0\0\x01", 8) != 0)
		@throw [OFInvalidFormatException exception];

	return image;
}
@end
