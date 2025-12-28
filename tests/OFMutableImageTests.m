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

@interface OFMutableImageTests: OTTestCase
@end

@implementation OFMutableImageTests
- (void)testImageWithSizeWithNonIntegralSizeThrows
{
	OTAssertThrowsSpecific(
	    [OFMutableImage imageWithSize: OFMakeSize(0.0f, 0.5f)
			      pixelFormat: OFPixelFormatRGB888],
	    OFInvalidArgumentException);

	OTAssertThrowsSpecific(
	    [OFMutableImage imageWithSize: OFMakeSize(0.5f, 0.0f)
			      pixelFormat: OFPixelFormatRGB888],
	    OFInvalidArgumentException);

	OTAssertThrowsSpecific(
	    [OFMutableImage imageWithSize: OFMakeSize(0.5f, 0.5f)
			      pixelFormat: OFPixelFormatRGB888],
	    OFInvalidArgumentException);
}

- (void)testRGB888WriteAndRead
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(2, 3)
	      pixelFormat: OFPixelFormatRGB888];
	OFColor *color;

	/* Everything is initialized with 0. */
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 2)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 2)],
	    [OFColor black]);

	/* Set one pixel. */
	color = [OFColor colorWithRed: 12 / 255.0f
				green: 85 / 255.0f
				 blue: 143 / 255.0f
				alpha: 1.0f];
	[image setColor: color atPoint: OFMakePoint(1, 1)];
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 1)], color);

	/* Others must be unchanged. */
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 2)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 2)],
	    [OFColor black]);
}

- (void)testRGBA8888WriteAndRead
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(2, 3)
	      pixelFormat: OFPixelFormatRGBA8888];
	OFColor *transparentBlack = [OFColor colorWithRed: 0.0f
						    green: 0.0f
						     blue: 0.0f
						    alpha: 0.0f];
	OFColor *color;

	/* Everything is initialized with 0. */
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 1)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 2)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 1)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 2)],
	    transparentBlack);

	/* Set one pixel. */
	color = [OFColor colorWithRed: 12 / 255.0f
				green: 85 / 255.0f
				 blue: 143 / 255.0f
				alpha: 53 / 255.0f];
	[image setColor: color atPoint: OFMakePoint(1, 1)];
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 1)], color);

	/* Others must be unchanged. */
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 1)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 2)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 2)],
	    transparentBlack);
}

- (void)testARGB8888WriteAndRead
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(2, 3)
	      pixelFormat: OFPixelFormatARGB8888];
	OFColor *transparentBlack = [OFColor colorWithRed: 0.0f
						    green: 0.0f
						     blue: 0.0f
						    alpha: 0.0f];
	OFColor *color;

	/* Everything is initialized with 0. */
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 1)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 2)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 1)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 2)],
	    transparentBlack);

	/* Set one pixel. */
	color = [OFColor colorWithRed: 12 / 255.0f
				green: 85 / 255.0f
				 blue: 143 / 255.0f
				alpha: 53 / 255.0f];
	[image setColor: color atPoint: OFMakePoint(1, 1)];
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 1)], color);

	/* Others must be unchanged. */
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 1)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 2)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 2)],
	    transparentBlack);
}

- (void)testBGR888WriteAndRead
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(2, 3)
	      pixelFormat: OFPixelFormatBGR888];
	OFColor *color;

	/* Everything is initialized with 0. */
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 2)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 2)],
	    [OFColor black]);

	/* Set one pixel. */
	color = [OFColor colorWithRed: 12 / 255.0f
				green: 85 / 255.0f
				 blue: 143 / 255.0f
				alpha: 1.0f];
	[image setColor: color atPoint: OFMakePoint(1, 1)];
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 1)], color);

	/* Others must be unchanged. */
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 2)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 2)],
	    [OFColor black]);
}

- (void)testABGR8888WriteAndRead
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(2, 3)
	      pixelFormat: OFPixelFormatABGR8888];
	OFColor *transparentBlack = [OFColor colorWithRed: 0.0f
						    green: 0.0f
						     blue: 0.0f
						    alpha: 0.0f];
	OFColor *color;

	/* Everything is initialized with 0. */
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 1)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 2)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 1)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 2)],
	    transparentBlack);

	/* Set one pixel. */
	color = [OFColor colorWithRed: 12 / 255.0f
				green: 85 / 255.0f
				 blue: 143 / 255.0f
				alpha: 53 / 255.0f];
	[image setColor: color atPoint: OFMakePoint(1, 1)];
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 1)], color);

	/* Others must be unchanged. */
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 1)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 2)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 2)],
	    transparentBlack);
}

- (void)testBGRA8888WriteAndRead
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(2, 3)
	      pixelFormat: OFPixelFormatBGRA8888];
	OFColor *transparentBlack = [OFColor colorWithRed: 0.0f
						    green: 0.0f
						     blue: 0.0f
						    alpha: 0.0f];
	OFColor *color;

	/* Everything is initialized with 0. */
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 1)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 2)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 1)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 2)],
	    transparentBlack);

	/* Set one pixel. */
	color = [OFColor colorWithRed: 12 / 255.0f
				green: 85 / 255.0f
				 blue: 143 / 255.0f
				alpha: 53 / 255.0f];
	[image setColor: color atPoint: OFMakePoint(1, 1)];
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 1)], color);

	/* Others must be unchanged. */
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 1)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0, 2)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1, 2)],
	    transparentBlack);
}

- (void)testWriteOutOfBoundsThrows
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(2, 3)
	      pixelFormat: OFPixelFormatRGBA8888];
	OFColor *color = [OFColor black];

	OTAssertThrowsSpecific(
	    [image setColor: color atPoint: OFMakePoint(0, 3)],
	    OFOutOfRangeException);

	OTAssertThrowsSpecific(
	    [image setColor: color atPoint: OFMakePoint(2, 0)],
	    OFOutOfRangeException);

	OTAssertThrowsSpecific(
	    [image setColor: color atPoint: OFMakePoint(2, 3)],
	    OFOutOfRangeException);
}

- (void)testWriteNonIntegralPointThrows
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(2, 3)
	      pixelFormat: OFPixelFormatRGBA8888];
	OFColor *color = [OFColor black];

	OTAssertThrowsSpecific(
	    [image setColor: color atPoint: OFMakePoint(0.0f, 0.5f)],
	    OFInvalidArgumentException);

	OTAssertThrowsSpecific(
	    [image setColor: color atPoint: OFMakePoint(0.5f, 0.0f)],
	    OFInvalidArgumentException);

	OTAssertThrowsSpecific(
	    [image setColor: color atPoint: OFMakePoint(0.5f, 0.5f)],
	    OFInvalidArgumentException);
}

- (void)testRGB888WriteOutOfRangeColorThrows
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(1, 1)
	      pixelFormat: OFPixelFormatRGB888];
	OFColor *color = [OFColor colorWithRed: 1.1f
					 green: 1.1f
					  blue: 1.1f
					 alpha: 1.0f];

	OTAssertThrowsSpecific(
	    [image setColor: color atPoint: OFMakePoint(0, 0)],
	    OFOutOfRangeException);
}

- (void)testRGBA8888WriteOutOfRangeColorThrows
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(1, 1)
	      pixelFormat: OFPixelFormatRGBA8888];
	OFColor *color = [OFColor colorWithRed: 1.1f
					 green: 1.1f
					  blue: 1.1f
					 alpha: 1.0f];

	OTAssertThrowsSpecific(
	    [image setColor: color atPoint: OFMakePoint(0, 0)],
	    OFOutOfRangeException);
}

- (void)testARGB8888WriteOutOfRangeColorThrows
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(1, 1)
	      pixelFormat: OFPixelFormatARGB8888];
	OFColor *color = [OFColor colorWithRed: 1.1f
					 green: 1.1f
					  blue: 1.1f
					 alpha: 1.0f];

	OTAssertThrowsSpecific(
	    [image setColor: color atPoint: OFMakePoint(0, 0)],
	    OFOutOfRangeException);
}

- (void)testBGR888WriteOutOfRangeColorThrows
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(1, 1)
	      pixelFormat: OFPixelFormatBGR888];
	OFColor *color = [OFColor colorWithRed: 1.1f
					 green: 1.1f
					  blue: 1.1f
					 alpha: 1.0f];

	OTAssertThrowsSpecific(
	    [image setColor: color atPoint: OFMakePoint(0, 0)],
	    OFOutOfRangeException);
}

- (void)testABGR8888WriteOutOfRangeColorThrows
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(1, 1)
	      pixelFormat: OFPixelFormatABGR8888];
	OFColor *color = [OFColor colorWithRed: 1.1f
					 green: 1.1f
					  blue: 1.1f
					 alpha: 1.0f];

	OTAssertThrowsSpecific(
	    [image setColor: color atPoint: OFMakePoint(0, 0)],
	    OFOutOfRangeException);
}

- (void)testBGRA888WriteOutOfRangeColorThrows
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(1, 1)
	      pixelFormat: OFPixelFormatBGRA8888];
	OFColor *color = [OFColor colorWithRed: 1.1f
					 green: 1.1f
					  blue: 1.1f
					 alpha: 1.0f];

	OTAssertThrowsSpecific(
	    [image setColor: color atPoint: OFMakePoint(0, 0)],
	    OFOutOfRangeException);
}

- (void)testCopy
{
	static const uint8_t pixels[] = {
		32, 32, 32,
		64, 64, 64,
		128, 128, 128,
		255, 255, 255
	};
	OFImage *image = [OFMutableImage
	    imageWithPixels: pixels
		pixelFormat: OFPixelFormatRGB888
		       size: OFMakeSize(2, 2)];
	OFImage *copy = objc_autorelease([image copy]);

	OTAssertNotEqual(image, copy);
	OTAssertEqualObjects(image, copy);
}
@end
