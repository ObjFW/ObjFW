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

#include <math.h>

#import "ObjFW.h"
#import "ObjFWTest.h"

@interface OFImageTests: OTTestCase
@end

@implementation OFImageTests
- (void)testImageWithPixels
{
	static const uint8_t pixels[] = {
		64, 128, 255, 224,
		32, 64, 128, 112,
		16, 32, 64, 56,
		8, 16, 32, 28
	};
	OFImage *image = [OFImage imageWithPixels: pixels
				      pixelFormat: OFPixelFormatRGBA8888
					     size: OFMakeSize(2.f, 2.f)];

	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.f, 0.f)],
	    [OFColor colorWithRed: 64.f / 255.f
			    green: 128.f / 255.f
			     blue: 255.f / 255.f
			    alpha: 224.f / 255.f]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.f, 0.f)],
	    [OFColor colorWithRed: 32.f / 255.f
			    green: 64.f / 255.f
			     blue: 128.f / 255.f
			    alpha: 112.f / 255.f]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.f, 1.f)],
	    [OFColor colorWithRed: 16.f / 255.f
			    green: 32.f / 255.f
			     blue: 64.f / 255.f
			    alpha: 56.f / 255.f]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.f, 1.f)],
	    [OFColor colorWithRed: 8.f / 255.f
			    green: 16.f / 255.f
			     blue: 32.f / 255.f
			    alpha: 28.f / 255.f]);
}

- (void)testImageWithPixelsNoCopy
{
	static const uint8_t pixels[] = {
		64, 128, 255,
		32, 64, 128,
		16, 32, 64,
		8, 16, 32
	};
	OFImage *image = [OFImage imageWithPixelsNoCopy: pixels
					    pixelFormat: OFPixelFormatRGB888
						   size: OFMakeSize(2.f, 2.f)
					   freeWhenDone: false];

	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.f, 0.f)],
	    [OFColor colorWithRed: 64.f / 255.f
			    green: 128.f / 255.f
			     blue: 255.f / 255.f
			    alpha: 1.f]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.f, 0.f)],
	    [OFColor colorWithRed: 32.f / 255.f
			    green: 64.f / 255.f
			     blue: 128.f / 255.f
			    alpha: 1.f]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.f, 1.f)],
	    [OFColor colorWithRed: 16.f / 255.f
			    green: 32.f / 255.f
			     blue: 64.f / 255.f
			    alpha: 1.f]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.f, 1.f)],
	    [OFColor colorWithRed: 8.f / 255.f
			    green: 16.f / 255.f
			     blue: 32.f / 255.f
			    alpha: 1.f]);
}

- (void)testImageWithPixelsWithNonIntegralSizeThrows
{
	OTAssertThrowsSpecific(
	    [OFImage imageWithPixels: "\0\0\0"
			 pixelFormat: OFPixelFormatRGB888
				size: OFMakeSize(0.f, 0.5f)],
	    OFInvalidArgumentException);

	OTAssertThrowsSpecific(
	    [OFImage imageWithPixels: "\0\0\0"
			 pixelFormat: OFPixelFormatRGB888
				size: OFMakeSize(0.5f, 0.f)],
	    OFInvalidArgumentException);

	OTAssertThrowsSpecific(
	    [OFImage imageWithPixels: "\0\0\0"
			 pixelFormat: OFPixelFormatRGB888
				size: OFMakeSize(0.5f, 0.5f)],
	    OFInvalidArgumentException);
}

- (void)testImageWithPixelsNoCopyWithNonIntegralSizeThrows
{
	OTAssertThrowsSpecific(
	    [OFImage imageWithPixelsNoCopy: "\0\0\0"
			       pixelFormat: OFPixelFormatRGB888
				      size: OFMakeSize(0.f, 0.5f)
			      freeWhenDone: false],
	    OFInvalidArgumentException);

	OTAssertThrowsSpecific(
	    [OFImage imageWithPixelsNoCopy: "\0\0\0"
			       pixelFormat: OFPixelFormatRGB888
				      size: OFMakeSize(0.5f, 0.f)
			      freeWhenDone: false],
	    OFInvalidArgumentException);

	OTAssertThrowsSpecific(
	    [OFImage imageWithPixelsNoCopy: "\0\0\0"
			       pixelFormat: OFPixelFormatRGB888
				      size: OFMakeSize(0.5f, 0.5f)
			      freeWhenDone: false],
	    OFInvalidArgumentException);
}

- (void)testIsEqual
{
	static const uint32_t pixels1[] = {
		OFToBigEndian32(0x202020FF),
		OFToBigEndian32(0x404040FF),
		OFToBigEndian32(0x808080FF),
		OFToBigEndian32(0xFFFFFFFF)
	};
	static const uint8_t pixels2[] = {
		32, 32, 32,
		64, 64, 64,
		128, 128, 128,
		255, 255, 255
	};
	OFImage *image1 = [OFImage imageWithPixels: pixels1
				       pixelFormat: OFPixelFormatRGBA8888
					      size: OFMakeSize(2.f, 2.f)];
	OFImage *image2 = [OFImage imageWithPixels: pixels2
				       pixelFormat: OFPixelFormatRGB888
					      size: OFMakeSize(2.f, 2.f)];
	OFImage *image3 = [OFImage imageWithPixels: pixels1
				       pixelFormat: OFPixelFormatARGB8888
					      size: OFMakeSize(2.f, 2.f)];
	OFImage *image4 = [OFImage imageWithPixels: pixels1
				       pixelFormat: OFPixelFormatARGB8888
					      size: OFMakeSize(2.f, 2.f)];

	OTAssertEqualObjects(image1, image1);
	OTAssertEqualObjects(image1, image2);
	OTAssertEqualObjects(image2, image1);
	OTAssertEqualObjects(image3, image4);
	OTAssertNotEqualObjects(image1, image3);
	OTAssertNotEqualObjects(image2, image3);
}

- (void)testHash
{
	static const uint32_t pixels1[] = {
		OFToBigEndian32(0x202020FF),
		OFToBigEndian32(0x404040FF),
		OFToBigEndian32(0x808080FF),
		OFToBigEndian32(0xFFFFFFFF)
	};
	static const uint8_t pixels2[] = {
		32, 32, 32,
		64, 64, 64,
		128, 128, 128,
		255, 255, 255
	};
	OFImage *image1 = [OFImage imageWithPixels: pixels1
				       pixelFormat: OFPixelFormatRGBA8888
					      size: OFMakeSize(2.f, 2.f)];
	OFImage *image2 = [OFImage imageWithPixels: pixels2
				       pixelFormat: OFPixelFormatRGB888
					      size: OFMakeSize(2.f, 2.f)];
	OFImage *image3 = [OFImage imageWithPixels: pixels1
				       pixelFormat: OFPixelFormatARGB8888
					      size: OFMakeSize(2.f, 2.f)];

	OTAssertEqual(image1.hash, image2.hash);
	OTAssertNotEqual(image1.hash, image3.hash);
}

- (void)testColorAtPointOutOfBoundsThrows
{
	static const uint32_t pixels[] = { 0, 0, 0, 0, 0, 0 };
	OFImage *image = [OFMutableImage
	    imageWithPixelsNoCopy: pixels
		      pixelFormat: OFPixelFormatRGBA8888
			     size: OFMakeSize(2.f, 3.f)
		     freeWhenDone: false];

	OTAssertThrowsSpecific([image colorAtPoint: OFMakePoint(0.f, 3.f)],
	    OFOutOfRangeException);

	OTAssertThrowsSpecific([image colorAtPoint: OFMakePoint(2.f, 0.f)],
	    OFOutOfRangeException);

	OTAssertThrowsSpecific([image colorAtPoint: OFMakePoint(2.f, 3.f)],
	    OFOutOfRangeException);
}

- (void)testColorAtNonIntegralPoint
{
	static const uint8_t pixels[] = {
		0, 0, 0,
		255, 0, 0,
		0, 255, 0,
		0, 0, 255
	};
	OFImage *image = [OFMutableImage
	    imageWithPixelsNoCopy: pixels
		      pixelFormat: OFPixelFormatRGB888
			     size: OFMakeSize(2.f, 2.f)
		     freeWhenDone: false];

	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.5f, 0.f)],
	    [OFColor colorWithRed: 0.5f
			    green: 0.f
			     blue: 0.f
			    alpha: 1.f]);

	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.f, 0.5f)],
	    [OFColor colorWithRed: 0.f
			    green: 0.5f
			     blue: 0.f
			    alpha: 1.f]);

	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.5f, 0.5f)],
	    [OFColor colorWithRed: 0.25f
			    green: 0.25f
			     blue: 0.25f
			    alpha: 1.f]);
}

- (void)testCopy
{
	static const uint8_t pixels[] = {
		32, 32, 32,
		64, 64, 64,
		128, 128, 128,
		255, 255, 255
	};
	OFImage *image = [OFImage imageWithPixels: pixels
				      pixelFormat: OFPixelFormatRGB888
					     size: OFMakeSize(2.f, 2.f)];
	OFImage *copy = objc_autorelease([image copy]);

	OTAssertEqual(image, copy);
	OTAssertEqualObjects(image, copy);
}

- (void)testMutableCopy
{
	static const uint8_t pixels[] = {
		32, 32, 32,
		64, 64, 64,
		128, 128, 128,
		255, 255, 255
	};
	OFImage *image = [OFImage imageWithPixels: pixels
				      pixelFormat: OFPixelFormatRGB888
					     size: OFMakeSize(2.f, 2.f)];
	OFMutableImage *copy = objc_autorelease([image mutableCopy]);

	OTAssertNotEqual(image, copy);
	OTAssertEqualObjects(image, copy);

	[copy setColor: [OFColor black] atPoint: OFMakePoint(0.f, 0.f)];
	OTAssertNotEqualObjects(image, copy);
}

- (void)testImageWithStreamImageFormatBMP
{
	OFIRI *IRI = [OFIRI IRIWithString: @"embedded:testfile.bmp"];
	OFSeekableStream *stream = [OFIRIHandler openItemAtIRI: IRI mode: @"r"];
	OFImage *image = [OFImage imageWithStream: stream
				      imageFormat: OFImageFormatBMP];

	OFAssert(OFEqualSizes(image.size, OFMakeSize(3.f, 2.f)));
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.f, 0.f)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.f, 0.f)],
	    [OFColor colorWithRed: 237.f / 255.f
			    green: 28.f / 255.f
			     blue: 36.f / 255.f
			    alpha: 1.f]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(2.f, 0.f)],
	    [OFColor colorWithRed: 34.f / 255.f
			    green: 177.f / 255.f
			     blue: 76.f / 255.f
			    alpha: 1.f]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.f, 1.f)],
	    [OFColor white]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.f, 1.f)],
	    [OFColor colorWithRed: 255.f / 255.f
			    green: 242.f / 255.f
			     blue: 0.f
			    alpha: 1.f]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(2.f, 1.f)],
	    [OFColor white]);

	OTAssertLessThan(fabsf(image.dotsPerInch.width - 72.f), 0.01f);
	OTAssertLessThan(fabsf(image.dotsPerInch.height - 72.f), 0.01f);
}

- (void)testWriteToStreamWithImageFormatBMPRGB888
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(3.f, 2.f)
	      pixelFormat: OFPixelFormatRGB888];
	OFImage *image2;
	uint8_t memory[78];
	OFMemoryStream *stream;

	[image setColor: [OFColor red] atPoint: OFMakePoint(0.f, 0.f)];
	[image setColor: [OFColor green] atPoint: OFMakePoint(1.f, 0.f)];
	[image setColor: [OFColor blue] atPoint: OFMakePoint(2.f, 0.f)];
	[image setColor: [OFColor black] atPoint: OFMakePoint(0.f, 1.f)];
	[image setColor: [OFColor purple] atPoint: OFMakePoint(1.f, 1.f)];
	[image setColor: [OFColor olive] atPoint: OFMakePoint(2.f, 1.f)];

	stream = [OFMemoryStream streamWithMemoryAddress: memory
						    size: sizeof(memory)
						writable: true];
	[image writeToStream: stream
		 imageFormat: OFImageFormatBMP
		     options: nil];

	[stream seekToOffset: 0 whence: OFSeekSet];
	image2 = [OFImage imageWithStream: stream
			      imageFormat: OFImageFormatBMP];

	OTAssertEqualObjects(image, image2);
}

- (void)testWriteToStreamWithImageFormatBMPRGBA8888
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(3.f, 2.f)
	      pixelFormat: OFPixelFormatRGBA8888];
	OFImage *image2;
	uint8_t memory[146];
	OFMemoryStream *stream;

	[image setColor: [OFColor red] atPoint: OFMakePoint(0.f, 0.f)];
	[image setColor: [OFColor green] atPoint: OFMakePoint(1.f, 0.f)];
	[image setColor: [OFColor blue] atPoint: OFMakePoint(2.f, 0.f)];
	[image setColor: [OFColor black] atPoint: OFMakePoint(0.f, 1.f)];
	[image setColor: [OFColor purple] atPoint: OFMakePoint(1.f, 1.f)];
	[image setColor: [OFColor olive] atPoint: OFMakePoint(2.f, 1.f)];

	stream = [OFMemoryStream streamWithMemoryAddress: memory
						    size: sizeof(memory)
						writable: true];
	[image writeToStream: stream
		 imageFormat: OFImageFormatBMP
		     options: nil];

	[stream seekToOffset: 0 whence: OFSeekSet];
	image2 = [OFImage imageWithStream: stream
			      imageFormat: OFImageFormatBMP];

	OTAssertEqualObjects(image, image2);
}

- (void)testImageWithStreamImageFormatQOI
{
	OFIRI *IRI = [OFIRI IRIWithString: @"embedded:testfile.qoi"];
	OFSeekableStream *stream = [OFIRIHandler openItemAtIRI: IRI mode: @"r"];
	OFImage *image = [OFImage imageWithStream: stream
				      imageFormat: OFImageFormatQOI];

	OFAssert(OFEqualSizes(image.size, OFMakeSize(3.f, 2.f)));
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.f, 0.f)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.f, 0.f)],
	    [OFColor colorWithRed: 237.f / 255.f
			    green: 28.f / 255.f
			     blue: 36.f / 255.f
			    alpha: 1.f]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(2.f, 0.f)],
	    [OFColor colorWithRed: 34.f / 255.f
			    green: 177.f / 255.f
			     blue: 76.f / 255.f
			    alpha: 1.f]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.f, 1.f)],
	    [OFColor white]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.f, 1.f)],
	    [OFColor colorWithRed: 255.f / 255.f
			    green: 242.f / 255.f
			     blue: 0.f
			    alpha: 1.f]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(2.f, 1.f)],
	    [OFColor white]);
}

- (void)testWriteToStreamWithImageFormatQOI
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(3.f, 2.f)
	      pixelFormat: OFPixelFormatRGB888];
	OFImage *image2;
	uint8_t memory[46];
	OFMemoryStream *stream;

	[image setColor: [OFColor red] atPoint: OFMakePoint(0.f, 0.f)];
	[image setColor: [OFColor green] atPoint: OFMakePoint(1.f, 0.f)];
	[image setColor: [OFColor blue] atPoint: OFMakePoint(2.f, 0.f)];
	[image setColor: [OFColor black] atPoint: OFMakePoint(0.f, 1.f)];
	[image setColor: [OFColor purple] atPoint: OFMakePoint(1.f, 1.f)];
	[image setColor: [OFColor olive] atPoint: OFMakePoint(2.f, 1.f)];

	stream = [OFMemoryStream streamWithMemoryAddress: memory
						    size: sizeof(memory)
						writable: true];
	[image writeToStream: stream
		 imageFormat: OFImageFormatQOI
		     options: nil];

	[stream seekToOffset: 0 whence: OFSeekSet];
	image2 = [OFImage imageWithStream: stream
			      imageFormat: OFImageFormatQOI];

	OTAssertEqualObjects(image, image2);
}
@end
