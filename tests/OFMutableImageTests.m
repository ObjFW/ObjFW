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
	    imageWithSize: OFMakeSize(2.0f, 3.0f)
	      pixelFormat: OFPixelFormatRGB888];
	OFColor *color;

	/* Everything is initialized with 0. */
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 0.0f)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 1.0f)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 2.0f)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 0.0f)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 1.0f)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 2.0f)],
	    [OFColor black]);

	/* Set one pixel. */
	color = [OFColor colorWithRed: 12.0f / 255.0f
				green: 85.0f / 255.0f
				 blue: 143.0f / 255.0f
				alpha: 1.0f];
	[image setColor: color atPoint: OFMakePoint(1.0f, 1.0f)];
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 1.0f)],
	    color);

	/* Others must be unchanged. */
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 0.0f)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 1.0f)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 2.0f)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 0.0f)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 2.0f)],
	    [OFColor black]);
}

- (void)testRGBA8888WriteAndRead
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(2.0f, 3.0f)
	      pixelFormat: OFPixelFormatRGBA8888];
	OFColor *transparentBlack = [OFColor colorWithRed: 0.0f
						    green: 0.0f
						     blue: 0.0f
						    alpha: 0.0f];
	OFColor *color;

	/* Everything is initialized with 0. */
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 0.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 1.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 2.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 0.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 1.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 2.0f)],
	    transparentBlack);

	/* Set one pixel. */
	color = [OFColor colorWithRed: 12.0f / 255.0f
				green: 85.0f / 255.0f
				 blue: 143.0f / 255.0f
				alpha: 53.0f / 255.0f];
	[image setColor: color atPoint: OFMakePoint(1.0f, 1.0f)];
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 1.0f)],
	    color);

	/* Others must be unchanged. */
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 0.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 1.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 2.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 0.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 2.0f)],
	    transparentBlack);
}

- (void)testARGB8888WriteAndRead
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(2.0f, 3.0f)
	      pixelFormat: OFPixelFormatARGB8888];
	OFColor *transparentBlack = [OFColor colorWithRed: 0.0f
						    green: 0.0f
						     blue: 0.0f
						    alpha: 0.0f];
	OFColor *color;

	/* Everything is initialized with 0. */
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 0.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 1.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 2.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 0.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 1.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 2.0f)],
	    transparentBlack);

	/* Set one pixel. */
	color = [OFColor colorWithRed: 12.0f / 255.0f
				green: 85.0f / 255.0f
				 blue: 143.0f / 255.0f
				alpha: 53.0f / 255.0f];
	[image setColor: color atPoint: OFMakePoint(1.0f, 1.0f)];
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 1.0f)],
	    color);

	/* Others must be unchanged. */
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 0.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 1.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 2.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 0.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 2.0f)],
	    transparentBlack);
}

- (void)testBGR888WriteAndRead
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(2.0f, 3.0f)
	      pixelFormat: OFPixelFormatBGR888];
	OFColor *color;

	/* Everything is initialized with 0. */
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 0.0f)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 1.0f)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 2.0f)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 0.0f)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 1.0f)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 2.0f)],
	    [OFColor black]);

	/* Set one pixel. */
	color = [OFColor colorWithRed: 12.0f / 255.0f
				green: 85.0f / 255.0f
				 blue: 143.0f / 255.0f
				alpha: 1.0f];
	[image setColor: color atPoint: OFMakePoint(1.0f, 1.0f)];
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 1.0f)],
	    color);

	/* Others must be unchanged. */
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 0.0f)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 1.0f)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 2.0f)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 0.0f)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 2.0f)],
	    [OFColor black]);
}

- (void)testABGR8888WriteAndRead
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(2.0f, 3.0f)
	      pixelFormat: OFPixelFormatABGR8888];
	OFColor *transparentBlack = [OFColor colorWithRed: 0.0f
						    green: 0.0f
						     blue: 0.0f
						    alpha: 0.0f];
	OFColor *color;

	/* Everything is initialized with 0. */
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 0.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 1.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 2.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 0.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 1.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 2.0f)],
	    transparentBlack);

	/* Set one pixel. */
	color = [OFColor colorWithRed: 12.0f / 255.0f
				green: 85.0f / 255.0f
				 blue: 143.0f / 255.0f
				alpha: 53.0f / 255.0f];
	[image setColor: color atPoint: OFMakePoint(1.0f, 1.0f)];
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 1.0f)],
	    color);

	/* Others must be unchanged. */
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 0.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 1.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 2.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 0.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 2.0f)],
	    transparentBlack);
}

- (void)testBGRA8888WriteAndRead
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(2.0f, 3.0f)
	      pixelFormat: OFPixelFormatBGRA8888];
	OFColor *transparentBlack = [OFColor colorWithRed: 0.0f
						    green: 0.0f
						     blue: 0.0f
						    alpha: 0.0f];
	OFColor *color;

	/* Everything is initialized with 0. */
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 0.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 1.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 2.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 0.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 1.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 2.0f)],
	    transparentBlack);

	/* Set one pixel. */
	color = [OFColor colorWithRed: 12.0f / 255.0f
				green: 85.0f / 255.0f
				 blue: 143.0f / 255.0f
				alpha: 53.0f / 255.0f];
	[image setColor: color atPoint: OFMakePoint(1.0f, 1.0f)];
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 1.0f)],
	    color);

	/* Others must be unchanged. */
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 0.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 1.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 2.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 0.0f)],
	    transparentBlack);
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(1.0f, 2.0f)],
	    transparentBlack);
}

- (void)testWriteOutOfBoundsThrows
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(2.0f, 3.0f)
	      pixelFormat: OFPixelFormatRGBA8888];
	OFColor *color = [OFColor black];

	OTAssertThrowsSpecific(
	    [image setColor: color atPoint: OFMakePoint(0.0f, 3.0f)],
	    OFOutOfRangeException);

	OTAssertThrowsSpecific(
	    [image setColor: color atPoint: OFMakePoint(2.0f, 0.0f)],
	    OFOutOfRangeException);

	OTAssertThrowsSpecific(
	    [image setColor: color atPoint: OFMakePoint(2.0f, 3.0f)],
	    OFOutOfRangeException);
}

- (void)testWriteNonIntegralPointThrows
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(2.0f, 3.0f)
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

- (void)testRGB888WriteClampsOutOfRangeColor
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(1.0f, 1.0f)
	      pixelFormat: OFPixelFormatRGB888];
	OFColor *color = [OFColor colorWithRed: 1.1f
					 green: 1.1f
					  blue: 1.1f
					 alpha: 1.1f];

	[image setColor: color atPoint: OFMakePoint(0.0f, 0.0f)];
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 0.0f)],
	    [OFColor colorWithRed: 1.0f
			    green: 1.0f
			     blue: 1.0f
			    alpha: 1.0f]);
}

- (void)testRGBA8888WriteClampsOutOfRangeColor
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(1.0f, 1.0f)
	      pixelFormat: OFPixelFormatRGBA8888];
	OFColor *color = [OFColor colorWithRed: 1.1f
					 green: 1.1f
					  blue: 1.1f
					 alpha: 1.1f];

	[image setColor: color atPoint: OFMakePoint(0.0f, 0.0f)];
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 0.0f)],
	    [OFColor colorWithRed: 1.0f
			    green: 1.0f
			     blue: 1.0f
			    alpha: 1.0f]);
}

- (void)testARGB8888WriteClampsOutOfRangeColor
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(1.0f, 1.0f)
	      pixelFormat: OFPixelFormatARGB8888];
	OFColor *color = [OFColor colorWithRed: 1.1f
					 green: 1.1f
					  blue: 1.1f
					 alpha: 1.1f];

	[image setColor: color atPoint: OFMakePoint(0.0f, 0.0f)];
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 0.0f)],
	    [OFColor colorWithRed: 1.0f
			    green: 1.0f
			     blue: 1.0f
			    alpha: 1.0f]);
}

- (void)testBGR888WriteClampsOutOfRangeColor
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(1.0f, 1.0f)
	      pixelFormat: OFPixelFormatBGR888];
	OFColor *color = [OFColor colorWithRed: 1.1f
					 green: 1.1f
					  blue: 1.1f
					 alpha: 1.1f];

	[image setColor: color atPoint: OFMakePoint(0.0f, 0.0f)];
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 0.0f)],
	    [OFColor colorWithRed: 1.0f
			    green: 1.0f
			     blue: 1.0f
			    alpha: 1.0f]);
}

- (void)testABGR8888WriteClampsOutOfRangeColor
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(1.0f, 1.0f)
	      pixelFormat: OFPixelFormatABGR8888];
	OFColor *color = [OFColor colorWithRed: 1.1f
					 green: 1.1f
					  blue: 1.1f
					 alpha: 1.1f];

	[image setColor: color atPoint: OFMakePoint(0.0f, 0.0f)];
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 0.0f)],
	    [OFColor colorWithRed: 1.0f
			    green: 1.0f
			     blue: 1.0f
			    alpha: 1.0f]);
}

- (void)testBGRA888WriteClampsOutOfRangeColor
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(1.0f, 1.0f)
	      pixelFormat: OFPixelFormatBGRA8888];
	OFColor *color = [OFColor colorWithRed: 1.1f
					 green: 1.1f
					  blue: 1.1f
					 alpha: 1.1f];

	[image setColor: color atPoint: OFMakePoint(0.0f, 0.0f)];
	OTAssertEqualObjects([image colorAtPoint: OFMakePoint(0.0f, 0.0f)],
	    [OFColor colorWithRed: 1.0f
			    green: 1.0f
			     blue: 1.0f
			    alpha: 1.0f]);
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
		       size: OFMakeSize(2.0f, 2.0f)];
	OFImage *copy = objc_autorelease([image copy]);

	OTAssertNotEqual(image, copy);
	OTAssertEqualObjects(image, copy);
}
@end
