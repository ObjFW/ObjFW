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

#import "OFBMPImageFormatHandler.h"
#import "OFColorSpace.h"
#import "OFImage+Private.h"
#import "OFSeekableStream.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"
#import "OFUnsupportedVersionException.h"

@implementation OFBMPImageFormatHandler
- (OFMutableImage *)readImageFromStream: (OFSeekableStream *)stream
{
	char magic[2];
	uint32_t dataStart, headerSize, compressionMethod;
	int32_t tmp32, horizPixelPerMeter, vertPixelPerMeter;
	size_t width, height, lineLength, linePadding = 0;
	bool flipped = false;
	OFSize size;
	uint16_t bitsPerPixel;
	OFPixelFormat format;
	OFMutableImage *image;
	uint8_t *pixels;

	/* File header */

	[stream readIntoBuffer: magic exactLength: 2];
	if (memcmp(magic, "BM", 2) != 0)
		@throw [OFInvalidFormatException exception];

	/* size = */ [stream readLittleEndianInt32];
	/* reserved1 = */ [stream readLittleEndianInt16];
	/* reserved2 = */ [stream readLittleEndianInt16];
	dataStart = [stream readLittleEndianInt32];

	/* DIB header */

	headerSize = [stream readLittleEndianInt32];
	if (headerSize != 40 && headerSize != 108 && headerSize != 124) {
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
	if (lineLength % 4 != 0)
		linePadding = 4 - (lineLength % 4);

	compressionMethod = [stream readLittleEndianInt32];
	if (compressionMethod != 0 &&
	    (headerSize < 108 || compressionMethod != 3)) {
		OFString *version = [OFString stringWithFormat:
		    @"\"compression method %u\"", compressionMethod];
		@throw [OFUnsupportedVersionException
		    exceptionWithVersion: version];
	}

	/* dataSize = */ [stream readLittleEndianInt32];
	horizPixelPerMeter = [stream readLittleEndianInt32];
	vertPixelPerMeter = [stream readLittleEndianInt32];

	/* Number of colors in palette */
	if ([stream readLittleEndianInt32] != 0)
		@throw [OFInvalidFormatException exception];

	/* Number of important colors = */ [stream readLittleEndianInt32];

	switch (bitsPerPixel) {
	case 24:
		format = OFPixelFormatBGR888;
		break;
	case 32:
		if (headerSize >= 108 && compressionMethod == 3)
			break;
		/* Fall through */
	default:;
		OFString *version = [OFString stringWithFormat:
		    @"\"%u bits per pixel\"", bitsPerPixel];
		@throw [OFUnsupportedVersionException
		    exceptionWithVersion: version];
	}

	if (headerSize >= 108 && compressionMethod == 3) {
		struct {
			uint32_t red, green, blue, alpha;
		} masks;
		char colorSpace[4];

		[stream readIntoBuffer: &masks exactLength: 16];

		if (masks.red == 0xFF000000 && masks.green == 0x00FF0000 &&
		    masks.blue == 0x0000FF00 && masks.alpha == 0x000000FF)
			format = OFPixelFormatRGBA8888;
		else if (masks.red == 0x00FF0000 && masks.green == 0x0000FF00 &&
		    masks.blue == 0x000000FF && masks.alpha == 0xFF000000)
			format = OFPixelFormatARGB8888;
		else if (masks.red == 0x000000FF && masks.green == 0x0000FF00 &&
		    masks.blue == 0x00FF0000 && masks.alpha == 0xFF000000)
			format = OFPixelFormatABGR8888;
		else if (masks.red == 0x0000FF00 && masks.green == 0x00FF0000 &&
		    masks.blue == 0xFF000000 && masks.alpha == 0x000000FF)
			format = OFPixelFormatBGRA8888;
		else
			@throw [OFUnsupportedVersionException
			    exceptionWithVersion: @"\"bit fields\""];

		[stream readIntoBuffer: &colorSpace exactLength: 4];

		if (memcmp(colorSpace, "BGRs", 4) != 0)
			@throw [OFUnsupportedVersionException
			    exceptionWithVersion: @"\"color space\""];
	}

	[stream seekToOffset: dataStart whence: OFSeekSet];

	image = [OFMutableImage imageWithSize: size pixelFormat: format];
	pixels = image.mutablePixels;

	if (flipped) {
		pixels += lineLength * height;

		for (size_t i = 0; i < height; i++) {
			pixels -= lineLength;

			[stream readIntoBuffer: pixels exactLength: lineLength];
			if (linePadding > 0) {
				char padding[3];
				[stream readIntoBuffer: padding
					   exactLength: linePadding];
			}
		}
	} else {
		for (size_t i = 0; i < height; i++) {
			[stream readIntoBuffer: pixels exactLength: lineLength];
			if (linePadding > 0) {
				char padding[3];
				[stream readIntoBuffer: padding
					   exactLength: linePadding];
			}

			pixels += lineLength;
		}
	}

	image.dotsPerInch = OFMakeSize(horizPixelPerMeter * 0.0254f,
	    vertPixelPerMeter * 0.0254f);

	return image;
}

- (void)writeImage: (OFImage *)image
	  toStream: (OFSeekableStream *)stream
	   options: (OFDictionary OF_GENERIC(OFString *, id) *)options
{
	OFSize size = image.size;
	uint32_t width = size.width, height = size.height;
	uint32_t headerSize, lineLength, linePadding = 0;
	const void *pixels;
	OFPixelFormat format;
	uint16_t bitsPerPixel;

	if (width != size.width || height != size.height ||
	    (int32_t)width < 0 || (int32_t)height < 0)
		@throw [OFInvalidArgumentException exception];

	pixels = image.pixels;
	format = image.pixelFormat;

	switch (format) {
	case OFPixelFormatRGB888:
	case OFPixelFormatBGR888:
		headerSize = 40;
		bitsPerPixel = 24;
		break;
	default:
		headerSize = 108;
		bitsPerPixel = 32;
		break;
	}

	if (UINT32_MAX / width < bitsPerPixel / CHAR_BIT)
		@throw [OFOutOfRangeException exception];

	lineLength = width * (bitsPerPixel / CHAR_BIT);
	if (lineLength % 4 != 0)
		linePadding = 4 - (lineLength % 4);

	if (UINT32_MAX - lineLength < linePadding ||
	    UINT32_MAX / (lineLength + linePadding) < height)
		@throw [OFOutOfRangeException exception];

	if (UINT32_MAX - height * (lineLength + linePadding) < 14 + headerSize)
		@throw [OFOutOfRangeException exception];

	if (![image.colorSpace isEqual: [OFColorSpace sRGBColorSpace]])
		@throw [OFInvalidArgumentException exception];

	/* File header */
	[stream writeString: @"BM"];
	[stream writeLittleEndianInt32:
	    14 + headerSize + height * (lineLength + linePadding)];
	[stream writeLittleEndianInt16: 0]; /* reserved1 */
	[stream writeLittleEndianInt16: 0]; /* reserved2 */
	[stream writeLittleEndianInt32: headerSize + 14] /* dataStart */;

	/* DIB header */
	[stream writeLittleEndianInt32: headerSize];
	[stream writeLittleEndianInt32: width];
	[stream writeLittleEndianInt32: height];
	[stream writeLittleEndianInt16: 1]; /* Number of color planes */
	[stream writeLittleEndianInt16: bitsPerPixel];
	[stream writeLittleEndianInt32:
	    (bitsPerPixel == 24 ? 0 : 3)]; /* compressionMethod */
	[stream writeLittleEndianInt32:
	    height * (lineLength + linePadding)]; /* dataSize */
	[stream writeLittleEndianInt32: image.dotsPerInch.width / 0.0254f];
	[stream writeLittleEndianInt32: image.dotsPerInch.height / 0.0254f];
	[stream writeLittleEndianInt32: 0]; /* Number of colors in palette */
	[stream writeLittleEndianInt32: 0]; /* Number of important colors */
	if (headerSize == 108) {
		static const uint8_t colorspaceEndpoints[36] = { 0 };
		[stream writeLittleEndianInt32: 0xFF000000]; /* Red mask */
		[stream writeLittleEndianInt32: 0x00FF0000]; /* Green mask */
		[stream writeLittleEndianInt32: 0x0000FF00]; /* Blue mask */
		[stream writeLittleEndianInt32: 0x000000FF]; /* Alpha mask */
		[stream writeString: @"BGRs"]; /* Color space */
		[stream writeBuffer: colorspaceEndpoints length: 36];
		[stream writeLittleEndianInt32: 0]; /* Red gamma */
		[stream writeLittleEndianInt32: 0]; /* Green gamma */
		[stream writeLittleEndianInt32: 0]; /* Blue gamma */
	}

	for (uint32_t i = height; i > 0; i--) {
		uint32_t y = i - 1;

		for (uint32_t x = 0; x < width; x++) {
			uint8_t buffer[4];

			if OF_UNLIKELY (!_OFReadPixelInt8(pixels, format, x, y,
			    width, &buffer[3], &buffer[2], &buffer[1],
			    &buffer[0]))
				@throw [OFNotImplementedException
				    exceptionWithSelector: _cmd
						   object: self];

			if (bitsPerPixel == 24) {
				if OF_UNLIKELY (buffer[0] != 255)
					@throw [OFInvalidArgumentException
					    exception];

				[stream writeBuffer: buffer + 1 length: 3];
			} else
				[stream writeBuffer: buffer length: 4];
		}

		if (linePadding > 0) {
			static const uint8_t padding[3] = { 0 };
			[stream writeBuffer: padding length: linePadding];
		}
	}
}
@end
