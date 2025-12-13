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

#import "OFBMPImageFormatHandler.h"
#import "OFSeekableStream.h"
#import "OFString.h"

#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"
#import "OFUnsupportedVersionException.h"

@implementation OFBMPImageFormatHandler
- (OFImage *)readImageFromStream: (OFSeekableStream *)stream
{
	uint32_t dataStart, headerSize, compressionMethod;
	int32_t tmp32;
	size_t width, height, lineLength, paddedLineLength;
	bool flipped = false;
	OFSize size;
	uint16_t bitsPerPixel;
	OFPixelFormat format;
	OFMutableImage *image;
	uint8_t *pixels;
	uint8_t *lineBuffer;

	/* File header */

	char magic[2];
	[stream readIntoBuffer: magic exactLength: 2];
	if (memcmp(magic, "BM", 2) != 0)
		@throw [OFInvalidFormatException exception];

	/* size = */ [stream readLittleEndianInt32];
	/* reserved1 = */ [stream readLittleEndianInt16];
	/* reserved2 = */ [stream readLittleEndianInt16];
	dataStart = [stream readLittleEndianInt32];

	/* DIB header */

	headerSize = [stream readLittleEndianInt32];
	if (headerSize != 40) {
		OFString *version = [OFString stringWithFormat:
		    @"\"header size %u\"", headerSize];
		@throw [OFUnsupportedVersionException
		    exceptionWithVersion: version];
	}

	tmp32 = [stream readLittleEndianInt32];
	if (tmp32 < 0)
		@throw [OFInvalidFormatException exception];
	width = tmp32;

	tmp32 = [stream readLittleEndianInt32];
	if (tmp32 < 0)
		height = tmp32 * -1;
	else {
		height = tmp32;
		flipped = true;
	}

	size.width = width;
	size.height = height;

	if (size.width != width || size.height != height)
		@throw [OFOutOfRangeException exception];

	/* Number of color planes */
	if ([stream readLittleEndianInt16] != 1)
		@throw [OFInvalidFormatException exception];

	bitsPerPixel = [stream readLittleEndianInt16];

	if (SIZE_MAX / width < bitsPerPixel / CHAR_BIT)
		@throw [OFOutOfRangeException exception];

	lineLength = width * (bitsPerPixel / CHAR_BIT);
	paddedLineLength = lineLength;
	if (paddedLineLength % 4 != 0) {
		if (SIZE_MAX - paddedLineLength < 4 - (paddedLineLength % 4))
			@throw [OFOutOfRangeException exception];

		paddedLineLength += 4 - (paddedLineLength % 4);
	}

	compressionMethod = [stream readLittleEndianInt32];
	if (compressionMethod != 0) {
		OFString *version = [OFString stringWithFormat:
		    @"\"compression method %u\"", compressionMethod];
		@throw [OFUnsupportedVersionException
		    exceptionWithVersion: version];
	}

	/* dataSize = */ [stream readLittleEndianInt32];
	/* horizPixelPerMeter = */ [stream readLittleEndianInt32];
	/* vertPixelPerMeter = */ [stream readLittleEndianInt32];

	/* Number of colors in palette */
	if ([stream readLittleEndianInt32] != 0)
		@throw [OFInvalidFormatException exception];

	switch (bitsPerPixel) {
	case 24:
		format = OFPixelFormatBGR888;
		break;
	default:;
		OFString *version = [OFString stringWithFormat:
		    @"\"%u bits per pixel\"", bitsPerPixel];
		@throw [OFUnsupportedVersionException
		    exceptionWithVersion: version];
	}

	[stream seekToOffset: dataStart whence: OFSeekSet];

	image = [OFMutableImage imageWithSize: size pixelFormat: format];
	pixels = image.mutablePixels;

	lineBuffer = OFAllocMemory(1, paddedLineLength);
	@try {
		if (flipped) {
			pixels += lineLength * height;

			for (size_t i = 0; i < height; i++) {
				[stream readIntoBuffer: lineBuffer
					   exactLength: paddedLineLength];

				pixels -= lineLength;
				memcpy(pixels, lineBuffer, lineLength);
			}
		} else {
			for (size_t i = 0; i < height; i++) {
				[stream readIntoBuffer: lineBuffer
					   exactLength: paddedLineLength];

				memcpy(pixels, lineBuffer, lineLength);
				pixels += lineLength;
			}
		}
	} @finally {
		OFFreeMemory(lineBuffer);
	}

	return image;
}
@end
