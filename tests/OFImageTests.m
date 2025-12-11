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

#import "ObjFW.h"
#import "ObjFWTest.h"

@interface OFImageTests: OTTestCase
@end

@implementation OFImageTests
- (void)testImageWithPixels
{
	const uint8_t pixels[] = {
		64, 128, 255, 224,
		32, 64, 128, 112,
		16, 32, 64, 56,
		8, 16, 32, 28
	};
	OFImage *image = [OFImage imageWithPixels: pixels
				      pixelFormat: OFPixelFormatRGBA8888
					     size: OFMakeSize(2, 2)];

	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 0)],
	    [OFColor colorWithRed: 64 / 255.0f
			    green: 128 / 255.0f
			     blue: 255 / 255.0f
			    alpha: 224 / 255.0f]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 0)],
	    [OFColor colorWithRed: 32 / 255.0f
			    green: 64 / 255.0f
			     blue: 128 / 255.0f
			    alpha: 112 / 255.0f]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 1)],
	    [OFColor colorWithRed: 16 / 255.0f
			    green: 32 / 255.0f
			     blue: 64 / 255.0f
			    alpha: 56 / 255.0f]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 1)],
	    [OFColor colorWithRed: 8 / 255.0f
			    green: 16 / 255.0f
			     blue: 32 / 255.0f
			    alpha: 28 / 255.0f]);
}

- (void)testImageWithPixelsNoCopy
{
	const uint8_t pixels[] = {
		64, 128, 255,
		32, 64, 128,
		16, 32, 64,
		8, 16, 32
	};
	OFImage *image = [OFImage imageWithPixelsNoCopy: pixels
					    pixelFormat: OFPixelFormatRGB888
						   size: OFMakeSize(2, 2)
					   freeWhenDone: false];

	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 0)],
	    [OFColor colorWithRed: 64 / 255.0f
			    green: 128 / 255.0f
			     blue: 255 / 255.0f
			    alpha: 1.0f]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 0)],
	    [OFColor colorWithRed: 32 / 255.0f
			    green: 64 / 255.0f
			     blue: 128 / 255.0f
			    alpha: 1.0f]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 1)],
	    [OFColor colorWithRed: 16 / 255.0f
			    green: 32 / 255.0f
			     blue: 64 / 255.0f
			    alpha: 1.0f]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 1)],
	    [OFColor colorWithRed: 8 / 255.0f
			    green: 16 / 255.0f
			     blue: 32 / 255.0f
			    alpha: 1.0f]);
}

- (void)testImageWithPixelsWithNonIntegralSizeThrows
{
	OTAssertThrowsSpecific(
	    [OFImage imageWithPixels: ""
			 pixelFormat: OFPixelFormatGrayscale8
				size: OFMakeSize(0.0f, 0.5f)],
	    OFInvalidArgumentException);

	OTAssertThrowsSpecific(
	    [OFImage imageWithPixels: ""
			 pixelFormat: OFPixelFormatGrayscale8
				size: OFMakeSize(0.5f, 0.0f)],
	    OFInvalidArgumentException);

	OTAssertThrowsSpecific(
	    [OFImage imageWithPixels: ""
			 pixelFormat: OFPixelFormatGrayscale8
				size: OFMakeSize(0.5f, 0.5f)],
	    OFInvalidArgumentException);
}

- (void)testImageWithPixelsNoCopyWithNonIntegralSizeThrows
{
	OTAssertThrowsSpecific(
	    [OFImage imageWithPixelsNoCopy: ""
			       pixelFormat: OFPixelFormatGrayscale8
				      size: OFMakeSize(0.0f, 0.5f)
			      freeWhenDone: false],
	    OFInvalidArgumentException);

	OTAssertThrowsSpecific(
	    [OFImage imageWithPixelsNoCopy: ""
			       pixelFormat: OFPixelFormatGrayscale8
				      size: OFMakeSize(0.5f, 0.0f)
			      freeWhenDone: false],
	    OFInvalidArgumentException);

	OTAssertThrowsSpecific(
	    [OFImage imageWithPixelsNoCopy: ""
			       pixelFormat: OFPixelFormatGrayscale8
				      size: OFMakeSize(0.5f, 0.5f)
			      freeWhenDone: false],
	    OFInvalidArgumentException);
}

- (void)testReadOutOfBoundsThrows
{
	const uint8_t pixels[] = { 0, 0, 0, 0, 0, 0 };
	OFImage *image = [OFMutableImage
	    imageWithPixelsNoCopy: pixels
		      pixelFormat: OFPixelFormatGrayscale8
			     size: OFMakeSize(2, 3)
		     freeWhenDone: false];

	OTAssertThrowsSpecific(
	    [image colorForPixelAtPosition: OFMakePoint(0, 3)],
	    OFOutOfRangeException);

	OTAssertThrowsSpecific(
	    [image colorForPixelAtPosition: OFMakePoint(2, 0)],
	    OFOutOfRangeException);

	OTAssertThrowsSpecific(
	    [image colorForPixelAtPosition: OFMakePoint(2, 3)],
	    OFOutOfRangeException);
}

- (void)testReadNonIntegralPositionThrows
{
	const uint8_t pixels[] = { 0, 0, 0, 0, 0, 0 };
	OFImage *image = [OFMutableImage
	    imageWithPixelsNoCopy: pixels
		      pixelFormat: OFPixelFormatGrayscale8
			     size: OFMakeSize(2, 3)
		     freeWhenDone: false];

	OTAssertThrowsSpecific(
	    [image colorForPixelAtPosition: OFMakePoint(0.0f, 0.5f)],
	    OFInvalidArgumentException);

	OTAssertThrowsSpecific(
	    [image colorForPixelAtPosition: OFMakePoint(0.5f, 0.0f)],
	    OFInvalidArgumentException);

	OTAssertThrowsSpecific(
	    [image colorForPixelAtPosition: OFMakePoint(0.5f, 0.5f)],
	    OFInvalidArgumentException);
}
@end
