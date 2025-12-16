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
					     size: OFMakeSize(2, 2)];

	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 0)],
	    [OFColor colorWithRed: 64 / 255.0f
			    green: 128 / 255.0f
			     blue: 255 / 255.0f
			    alpha: 224 / 255.0f]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 0)],
	    [OFColor colorWithRed: 32 / 255.0f
			    green: 64 / 255.0f
			     blue: 128 / 255.0f
			    alpha: 112 / 255.0f]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 1)],
	    [OFColor colorWithRed: 16 / 255.0f
			    green: 32 / 255.0f
			     blue: 64 / 255.0f
			    alpha: 56 / 255.0f]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 1)],
	    [OFColor colorWithRed: 8 / 255.0f
			    green: 16 / 255.0f
			     blue: 32 / 255.0f
			    alpha: 28 / 255.0f]);
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
						   size: OFMakeSize(2, 2)
					   freeWhenDone: false];

	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 0)],
	    [OFColor colorWithRed: 64 / 255.0f
			    green: 128 / 255.0f
			     blue: 255 / 255.0f
			    alpha: 1.0f]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 0)],
	    [OFColor colorWithRed: 32 / 255.0f
			    green: 64 / 255.0f
			     blue: 128 / 255.0f
			    alpha: 1.0f]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 1)],
	    [OFColor colorWithRed: 16 / 255.0f
			    green: 32 / 255.0f
			     blue: 64 / 255.0f
			    alpha: 1.0f]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 1)],
	    [OFColor colorWithRed: 8 / 255.0f
			    green: 16 / 255.0f
			     blue: 32 / 255.0f
			    alpha: 1.0f]);
}

- (void)testImageWithPixelsWithNonIntegralSizeThrows
{
	OTAssertThrowsSpecific(
	    [OFImage imageWithPixels: "\0\0\0"
			 pixelFormat: OFPixelFormatRGB888
				size: OFMakeSize(0.0f, 0.5f)],
	    OFInvalidArgumentException);

	OTAssertThrowsSpecific(
	    [OFImage imageWithPixels: "\0\0\0"
			 pixelFormat: OFPixelFormatRGB888
				size: OFMakeSize(0.5f, 0.0f)],
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
				      size: OFMakeSize(0.0f, 0.5f)
			      freeWhenDone: false],
	    OFInvalidArgumentException);

	OTAssertThrowsSpecific(
	    [OFImage imageWithPixelsNoCopy: "\0\0\0"
			       pixelFormat: OFPixelFormatRGB888
				      size: OFMakeSize(0.5f, 0.0f)
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
					      size: OFMakeSize(2, 2)];
	OFImage *image2 = [OFImage imageWithPixels: pixels2
				       pixelFormat: OFPixelFormatRGB888
					      size: OFMakeSize(2, 2)];
	OFImage *image3 = [OFImage imageWithPixels: pixels1
				       pixelFormat: OFPixelFormatARGB8888
					      size: OFMakeSize(2, 2)];
	OFImage *image4 = [OFImage imageWithPixels: pixels1
				       pixelFormat: OFPixelFormatARGB8888
					      size: OFMakeSize(2, 2)];

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
					      size: OFMakeSize(2, 2)];
	OFImage *image2 = [OFImage imageWithPixels: pixels2
				       pixelFormat: OFPixelFormatRGB888
					      size: OFMakeSize(2, 2)];
	OFImage *image3 = [OFImage imageWithPixels: pixels1
				       pixelFormat: OFPixelFormatARGB8888
					      size: OFMakeSize(2, 2)];

	OTAssertEqual(image1.hash, image2.hash);
	OTAssertNotEqual(image1.hash, image3.hash);
}

- (void)testReadOutOfBoundsThrows
{
	static const uint32_t pixels[] = { 0, 0, 0, 0, 0, 0 };
	OFImage *image = [OFMutableImage
	    imageWithPixelsNoCopy: pixels
		      pixelFormat: OFPixelFormatRGBA8888
			     size: OFMakeSize(2, 3)
		     freeWhenDone: false];

	OTAssertThrowsSpecific([image colorAtPoint: OFMakePoint(0, 3)],
	    OFOutOfRangeException);

	OTAssertThrowsSpecific([image colorAtPoint: OFMakePoint(2, 0)],
	    OFOutOfRangeException);

	OTAssertThrowsSpecific([image colorAtPoint: OFMakePoint(2, 3)],
	    OFOutOfRangeException);
}

- (void)testReadNonIntegralPointThrows
{
	static const uint32_t pixels[] = { 0, 0, 0, 0, 0, 0 };
	OFImage *image = [OFMutableImage
	    imageWithPixelsNoCopy: pixels
		      pixelFormat: OFPixelFormatRGBA8888
			     size: OFMakeSize(2, 3)
		     freeWhenDone: false];

	OTAssertThrowsSpecific([image colorAtPoint: OFMakePoint(0.0f, 0.5f)],
	    OFInvalidArgumentException);

	OTAssertThrowsSpecific([image colorAtPoint: OFMakePoint(0.5f, 0.0f)],
	    OFInvalidArgumentException);

	OTAssertThrowsSpecific([image colorAtPoint: OFMakePoint(0.5f, 0.5f)],
	    OFInvalidArgumentException);
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
					     size: OFMakeSize(2, 2)];
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
					     size: OFMakeSize(2, 2)];
	OFMutableImage *copy = objc_autorelease([image mutableCopy]);

	OTAssertNotEqual(image, copy);
	OTAssertEqualObjects(image, copy);

	[copy setColor: [OFColor black] atPoint: OFMakePoint(0, 0)];
	OTAssertNotEqualObjects(image, copy);
}

- (void)testReadFromStreamWithImageFormatBMP
{
	OFIRI *IRI = [OFIRI IRIWithString: @"embedded:testfile.bmp"];
	OFSeekableStream *stream = [OFIRIHandler openItemAtIRI: IRI mode: @"r"];
	OFImage *image = [OFImage readFromStream: stream
				     imageFormat: OFImageFormatBMP];

	OFAssert(OFEqualSizes(image.size, OFMakeSize(3, 2)));
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 0)],
	    [OFColor colorWithRed: 237 / 255.0f
			    green: 28 / 255.0f
			     blue: 36 / 255.0f
			    alpha: 1.0f]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(2, 0)],
	    [OFColor colorWithRed: 34 / 255.0f
			    green: 177 / 255.0f
			     blue: 76 / 255.0f
			    alpha: 1.0f]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 1)],
	    [OFColor white]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 1)],
	    [OFColor colorWithRed: 255 / 255.0f
			    green: 242 / 255.0f
			     blue: 0 / 255.0f
			    alpha: 1.0f]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(2, 1)],
	    [OFColor white]);

	OTAssertLessThan(fabsf(image.dotsPerInch.width - 72), 0.01);
	OTAssertLessThan(fabsf(image.dotsPerInch.height - 72), 0.01);
}

- (void)testWriteToStreamWithImageFormatBMP
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(3, 2)
	      pixelFormat: OFPixelFormatRGBA8888];
	OFImage *image2;
	uint8_t memory[78];
	OFMemoryStream *stream;

	[image setColor: [OFColor red] atPoint: OFMakePoint(0, 0)];
	[image setColor: [OFColor green] atPoint: OFMakePoint(1, 0)];
	[image setColor: [OFColor blue] atPoint: OFMakePoint(2, 0)];
	[image setColor: [OFColor black] atPoint: OFMakePoint(0, 1)];
	[image setColor: [OFColor purple] atPoint: OFMakePoint(1, 1)];
	[image setColor: [OFColor olive] atPoint: OFMakePoint(2, 1)];

	stream = [OFMemoryStream streamWithMemoryAddress: memory
						    size: sizeof(memory)
						writable: true];
	[image writeToStream: stream
		 imageFormat: OFImageFormatBMP
		     options: nil];

	[stream seekToOffset: 0 whence: OFSeekSet];
	image2 = [OFImage readFromStream: stream imageFormat: OFImageFormatBMP];

	OTAssertEqualObjects(image, image2);
}

- (void)testReadFromStreamWithImageFormatQOI
{
	OFIRI *IRI = [OFIRI IRIWithString: @"embedded:testfile.qoi"];
	OFSeekableStream *stream = [OFIRIHandler openItemAtIRI: IRI mode: @"r"];
	OFImage *image = [OFImage readFromStream: stream
				     imageFormat: OFImageFormatQOI];

	OFAssert(OFEqualSizes(image.size, OFMakeSize(3, 2)));
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 0)],
	    [OFColor colorWithRed: 237 / 255.0f
			    green: 28 / 255.0f
			     blue: 36 / 255.0f
			    alpha: 1.0f]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(2, 0)],
	    [OFColor colorWithRed: 34 / 255.0f
			    green: 177 / 255.0f
			     blue: 76 / 255.0f
			    alpha: 1.0f]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 1)],
	    [OFColor white]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 1)],
	    [OFColor colorWithRed: 255 / 255.0f
			    green: 242 / 255.0f
			     blue: 0 / 255.0f
			    alpha: 1.0f]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(2, 1)],
	    [OFColor white]);
}
@end
