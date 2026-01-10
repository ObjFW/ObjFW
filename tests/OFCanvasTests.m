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

@interface OFCanvasTests: OTTestCase
{
	OFMutableImage *_image;
	OFCanvas *_canvas;
}
@end

@implementation OFCanvasTests
- (void)setUp
{
	[super setUp];

	_image = [[OFMutableImage alloc] initWithSize: OFMakeSize(4.f, 3.f)
					  pixelFormat: OFPixelFormatRGBA8888];
	_canvas = [[OFCanvas alloc] initWithDestinationImage: _image];
}

- (void)dealloc
{
	objc_release(_image);
	objc_release(_canvas);

	[super dealloc];
}

- (void)testClearRect
{
	static const uint8_t pixels[] = {
		0, 0, 0, 255,
		0, 0, 0, 255,
		0, 0, 0, 255,
		0, 0, 0, 255,

		0, 0, 0, 255,
		32, 64, 128, 255,
		32, 64, 128, 255,
		0, 0, 0, 255,

		0, 0, 0, 255,
		32, 64, 128, 255,
		32, 64, 128, 255,
		0, 0, 0, 255
	};
	OFImage *reference = [OFImage
	    imageWithPixelsNoCopy: pixels
		      pixelFormat: OFPixelFormatRGBA8888
			     size: OFMakeSize(4.f, 3.f)
		     freeWhenDone: false];

	[_canvas clearRect: OFMakeRect(0.f, 0.f, 4.f, 3.f)];
	_canvas.backgroundColor = [OFColor colorWithRed: 32.f / 255.f
						  green: 64.f / 255.f
						   blue: 128.f / 255.f
						  alpha: 1.f];
	[_canvas clearRect: OFMakeRect(1.f, 1.f, 2.f, 3.f)];

	OTAssertEqualObjects(_image, reference);
}

- (void)testDrawImageSourceRectDestinationRect
{
	static const uint8_t pixels[] = {
		0, 0, 0, 255,
		0, 0, 0, 255,
		0, 0, 0, 255,
		0, 0, 0, 255,

		0, 0, 0, 255,
		255, 255, 255, 255,
		255, 0, 0, 255,
		0, 0, 0, 255,

		0, 0, 0, 255,
		0, 255, 0, 255,
		0, 0, 255, 255,
		0, 0, 0, 255
	};
	OFImage *image = [OFImage imageWithPixelsNoCopy: pixels
					    pixelFormat: OFPixelFormatRGBA8888
						   size: OFMakeSize(4.f, 3.f)
					   freeWhenDone: false];

	[_canvas clearRect: OFMakeRect(0.f, 0.f, 4.f, 3.f)];
	[_canvas drawImage: image
		sourceRect: OFMakeRect(1.f, 1.f, 2.f, 2.f)
	   destinationRect: OFMakeRect(1.f, 0.f, 3.f, 3.f)];

	/*
	 * This test checks every pixel individually instead of checking
	 * against a test image see what exactly failed, if anything.
	 */

	/* Check the non-interpolated pixels are exact. */
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(1.f, 0.f)],
	    [OFColor white]);
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(3.f, 0.f)],
	    [OFColor red]);
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(1.f, 2.f)],
	    [OFColor lime]);
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(3.f, 2.f)],
	    [OFColor blue]);

	/* Check left row is unchanged. */
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(0.f, 0.f)],
	    [OFColor black]);
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(0.f, 1.f)],
	    [OFColor black]);
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(0.f, 2.f)],
	    [OFColor black]);

	/* Check interpolated pixels. */
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(2.f, 0.f)],
	    [OFColor colorWithRed: 1.f
			    green: 85.f / 255.f
			     blue: 85.f / 255.f
			    alpha: 1.f]);
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(1.f, 1.f)],
	    [OFColor colorWithRed: 85.f / 255.f
			    green: 1.f
			     blue: 85.f / 255.f
			    alpha: 1.f]);
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(2.f, 1.f)],
	    [OFColor colorWithRed: 85.f / 255.f
			    green: 85.f / 255.f
			     blue: 142.f / 255.f
			    alpha: 1.f]);
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(3.f, 1.f)],
	    [OFColor colorWithRed: 85.f / 255.f
			    green: 0.f
			     blue: 170.f / 255.f
			    alpha: 1.f]);
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(2.f, 2.f)],
	    [OFColor colorWithRed: 0.f
			    green: 85.f / 255.f
			     blue: 170.f / 255.f
			    alpha: 1.f]);
}
@end
