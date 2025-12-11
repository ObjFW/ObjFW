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
			      pixelFormat: OFPixelFormatGrayscale8],
	    OFInvalidArgumentException);

	OTAssertThrowsSpecific(
	    [OFMutableImage imageWithSize: OFMakeSize(0.5, 0.0f)
			      pixelFormat: OFPixelFormatGrayscale8],
	    OFInvalidArgumentException);

	OTAssertThrowsSpecific(
	    [OFMutableImage imageWithSize: OFMakeSize(0.5f, 0.5f)
			      pixelFormat: OFPixelFormatGrayscale8],
	    OFInvalidArgumentException);
}

- (void)testGrayscale8WriteAndRead
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(2, 3)
	      pixelFormat: OFPixelFormatGrayscale8];
	OFColor *color;

	/* Everything is initialized with 0. */
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 2)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 2)],
	    [OFColor black]);

	/* Set one pixel. */
	color = [OFColor colorWithRed: 133 / 255.0f
				green: 133 / 255.0f
				 blue: 133 / 255.0f
				alpha: 1.0f];
	[image setColor: color forPixelAtPosition: OFMakePoint(1, 1)];
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 1)],
	    color);

	/* Others must be unchanged. */
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 2)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 2)],
	    [OFColor black]);
}

- (void)testRGB565BEWriteAndRead
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(2, 3)
	      pixelFormat: OFPixelFormatRGB565BE];
	OFColor *color;

	/* Everything is initialized with 0. */
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 2)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 2)],
	    [OFColor black]);

	/* Set one pixel. */
	color = [OFColor colorWithRed: 16 / 255.0f
				green: 88 / 255.0f
				 blue: 144 / 255.0f
				alpha: 1.0f];
	[image setColor: color forPixelAtPosition: OFMakePoint(1, 1)];
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 1)],
	    color);

	/* Others must be unchanged. */
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 2)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 2)],
	    [OFColor black]);
}

- (void)testRGB565LEWriteAndRead
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(2, 3)
	      pixelFormat: OFPixelFormatRGB565BE];
	OFColor *color;

	/* Everything is initialized with 0. */
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 2)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 2)],
	    [OFColor black]);

	/* Set one pixel. */
	color = [OFColor colorWithRed: 16 / 255.0f
				green: 88 / 255.0f
				 blue: 144 / 255.0f
				alpha: 1.0f];
	[image setColor: color forPixelAtPosition: OFMakePoint(1, 1)];
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 1)],
	    color);

	/* Others must be unchanged. */
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 2)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 2)],
	    [OFColor black]);
}

- (void)testRGB888WriteAndRead
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(2, 3)
	      pixelFormat: OFPixelFormatRGB888];
	OFColor *color;

	/* Everything is initialized with 0. */
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 2)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 2)],
	    [OFColor black]);

	/* Set one pixel. */
	color = [OFColor colorWithRed: 12 / 255.0f
				green: 85 / 255.0f
				 blue: 143 / 255.0f
				alpha: 1.0f];
	[image setColor: color forPixelAtPosition: OFMakePoint(1, 1)];
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 1)],
	    color);

	/* Others must be unchanged. */
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 2)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 2)],
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
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 1)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 2)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 1)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 2)],
	    transparentBlack);

	/* Set one pixel. */
	color = [OFColor colorWithRed: 12 / 255.0f
				green: 85 / 255.0f
				 blue: 143 / 255.0f
				alpha: 53 / 255.0f];
	[image setColor: color forPixelAtPosition: OFMakePoint(1, 1)];
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 1)],
	    color);

	/* Others must be unchanged. */
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 1)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 2)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 2)],
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
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 1)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 2)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 1)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 2)],
	    transparentBlack);

	/* Set one pixel. */
	color = [OFColor colorWithRed: 12 / 255.0f
				green: 85 / 255.0f
				 blue: 143 / 255.0f
				alpha: 53 / 255.0f];
	[image setColor: color forPixelAtPosition: OFMakePoint(1, 1)];
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 1)],
	    color);

	/* Others must be unchanged. */
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 1)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 2)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 2)],
	    transparentBlack);
}

- (void)testBGR565BEWriteAndRead
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(2, 3)
	      pixelFormat: OFPixelFormatBGR565BE];
	OFColor *color;

	/* Everything is initialized with 0. */
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 2)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 2)],
	    [OFColor black]);

	/* Set one pixel. */
	color = [OFColor colorWithRed: 16 / 255.0f
				green: 88 / 255.0f
				 blue: 144 / 255.0f
				alpha: 1.0f];
	[image setColor: color forPixelAtPosition: OFMakePoint(1, 1)];
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 1)],
	    color);

	/* Others must be unchanged. */
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 2)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 2)],
	    [OFColor black]);
}

- (void)testBGR565LEWriteAndRead
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(2, 3)
	      pixelFormat: OFPixelFormatBGR565LE];
	OFColor *color;

	/* Everything is initialized with 0. */
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 2)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 2)],
	    [OFColor black]);

	/* Set one pixel. */
	color = [OFColor colorWithRed: 16 / 255.0f
				green: 88 / 255.0f
				 blue: 144 / 255.0f
				alpha: 1.0f];
	[image setColor: color forPixelAtPosition: OFMakePoint(1, 1)];
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 1)],
	    color);

	/* Others must be unchanged. */
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 2)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 2)],
	    [OFColor black]);
}

- (void)testBGR888WriteAndRead
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(2, 3)
	      pixelFormat: OFPixelFormatBGR888];
	OFColor *color;

	/* Everything is initialized with 0. */
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 2)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 2)],
	    [OFColor black]);

	/* Set one pixel. */
	color = [OFColor colorWithRed: 12 / 255.0f
				green: 85 / 255.0f
				 blue: 143 / 255.0f
				alpha: 1.0f];
	[image setColor: color forPixelAtPosition: OFMakePoint(1, 1)];
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 1)],
	    color);

	/* Others must be unchanged. */
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 1)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 2)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 0)],
	    [OFColor black]);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 2)],
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
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 1)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 2)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 1)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 2)],
	    transparentBlack);

	/* Set one pixel. */
	color = [OFColor colorWithRed: 12 / 255.0f
				green: 85 / 255.0f
				 blue: 143 / 255.0f
				alpha: 53 / 255.0f];
	[image setColor: color forPixelAtPosition: OFMakePoint(1, 1)];
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 1)],
	    color);

	/* Others must be unchanged. */
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 1)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 2)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 2)],
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
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 1)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 2)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 1)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 2)],
	    transparentBlack);

	/* Set one pixel. */
	color = [OFColor colorWithRed: 12 / 255.0f
				green: 85 / 255.0f
				 blue: 143 / 255.0f
				alpha: 53 / 255.0f];
	[image setColor: color forPixelAtPosition: OFMakePoint(1, 1)];
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 1)],
	    color);

	/* Others must be unchanged. */
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 1)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(0, 2)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 0)],
	    transparentBlack);
	OTAssertEqualObjects([image colorForPixelAtPosition: OFMakePoint(1, 2)],
	    transparentBlack);
}

- (void)testWriteOutOfBoundsThrows
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(2, 3)
	      pixelFormat: OFPixelFormatRGBA8888];
	OFColor *color = [OFColor black];

	OTAssertThrowsSpecific(
	    [image setColor: color forPixelAtPosition: OFMakePoint(0, 3)],
	    OFOutOfRangeException);

	OTAssertThrowsSpecific(
	    [image setColor: color forPixelAtPosition: OFMakePoint(2, 0)],
	    OFOutOfRangeException);

	OTAssertThrowsSpecific(
	    [image setColor: color forPixelAtPosition: OFMakePoint(2, 3)],
	    OFOutOfRangeException);
}

- (void)testWriteNonIntegralPositionThrows
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(2, 3)
	      pixelFormat: OFPixelFormatRGBA8888];
	OFColor *color = [OFColor black];

	OTAssertThrowsSpecific(
	    [image setColor: color forPixelAtPosition: OFMakePoint(0.0f, 0.5f)],
	    OFInvalidArgumentException);

	OTAssertThrowsSpecific(
	    [image setColor: color forPixelAtPosition: OFMakePoint(0.5f, 0.0f)],
	    OFInvalidArgumentException);

	OTAssertThrowsSpecific(
	    [image setColor: color forPixelAtPosition: OFMakePoint(0.5f, 0.5f)],
	    OFInvalidArgumentException);
}

- (void)testGrayscale8WriteOutOfRangeColorThrows
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(1, 1)
	      pixelFormat: OFPixelFormatGrayscale8];
	OFColor *color = [OFColor colorWithRed: 1.1f
					 green: 1.1f
					  blue: 1.1f
					 alpha: 1.0f];

	OTAssertThrowsSpecific(
	    [image setColor: color forPixelAtPosition: OFMakePoint(0, 0)],
	    OFOutOfRangeException);
}

- (void)testRGB565BEWriteOutOfRangeColorThrows
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(1, 1)
	      pixelFormat: OFPixelFormatRGB565BE];
	OFColor *color = [OFColor colorWithRed: 1.1f
					 green: 1.1f
					  blue: 1.1f
					 alpha: 1.0f];

	OTAssertThrowsSpecific(
	    [image setColor: color forPixelAtPosition: OFMakePoint(0, 0)],
	    OFOutOfRangeException);
}

- (void)testRGB565LEWriteOutOfRangeColorThrows
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(1, 1)
	      pixelFormat: OFPixelFormatRGB565LE];
	OFColor *color = [OFColor colorWithRed: 1.1f
					 green: 1.1f
					  blue: 1.1f
					 alpha: 1.0f];

	OTAssertThrowsSpecific(
	    [image setColor: color forPixelAtPosition: OFMakePoint(0, 0)],
	    OFOutOfRangeException);
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
	    [image setColor: color forPixelAtPosition: OFMakePoint(0, 0)],
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
	    [image setColor: color forPixelAtPosition: OFMakePoint(0, 0)],
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
	    [image setColor: color forPixelAtPosition: OFMakePoint(0, 0)],
	    OFOutOfRangeException);
}

- (void)testBGR565BEWriteOutOfRangeColorThrows
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(1, 1)
	      pixelFormat: OFPixelFormatBGR565BE];
	OFColor *color = [OFColor colorWithRed: 1.1f
					 green: 1.1f
					  blue: 1.1f
					 alpha: 1.0f];

	OTAssertThrowsSpecific(
	    [image setColor: color forPixelAtPosition: OFMakePoint(0, 0)],
	    OFOutOfRangeException);
}

- (void)testBGR565LEWriteOutOfRangeColorThrows
{
	OFMutableImage *image = [OFMutableImage
	    imageWithSize: OFMakeSize(1, 1)
	      pixelFormat: OFPixelFormatBGR565LE];
	OFColor *color = [OFColor colorWithRed: 1.1f
					 green: 1.1f
					  blue: 1.1f
					 alpha: 1.0f];

	OTAssertThrowsSpecific(
	    [image setColor: color forPixelAtPosition: OFMakePoint(0, 0)],
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
	    [image setColor: color forPixelAtPosition: OFMakePoint(0, 0)],
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
	    [image setColor: color forPixelAtPosition: OFMakePoint(0, 0)],
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
	    [image setColor: color forPixelAtPosition: OFMakePoint(0, 0)],
	    OFOutOfRangeException);
}
@end
