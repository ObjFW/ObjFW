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

	_image = [[OFMutableImage alloc] initWithSize: OFMakeSize(4.0f, 3.0f)
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
	static const uint32_t pixels[] = {
		0x000000FF, 0x000000FF, 0x000000FF, 0x000000FF,
		0x000000FF, 0x204080FF, 0x204080FF, 0x000000FF,
		0x000000FF, 0x204080FF, 0x204080FF, 0x000000FF
	};
	OFImage *reference = [OFImage
	    imageWithPixelsNoCopy: pixels
		      pixelFormat: OFPixelFormatRGBA8888
			     size: OFMakeSize(4.0f, 3.0f)
		     freeWhenDone: false];

	[_canvas clearRect: OFMakeRect(0.0f, 0.0f, 4.0f, 3.0f)];
	_canvas.backgroundColor = [OFColor colorWithRed: 32.0f / 255.0f
						  green: 64.0f / 255.0f
						   blue: 128.0f / 255.0f
						  alpha: 1.0f];
	[_canvas clearRect: OFMakeRect(1.0f, 1.0f, 2.0f, 3.0f)];

	OTAssertEqualObjects(_image, reference);
}

- (void)testDrawImageSourceRectDestinationRect
{
	static const uint32_t pixels[] = {
		0x000000FF, 0x000000FF, 0x000000FF, 0x000000FF,
		0x000000FF, 0xFFFFFFFF, 0xFF0000FF, 0x000000FF,
		0x000000FF, 0x00FF00FF, 0x0000FFFF, 0x000000FF
	};
	OFImage *image = [OFImage imageWithPixelsNoCopy: pixels
					    pixelFormat: OFPixelFormatRGBA8888
						   size: OFMakeSize(4.0f, 3.0f)
					   freeWhenDone: false];

	[_canvas clearRect: OFMakeRect(0.0f, 0.0f, 4.0f, 3.0f)];
	[_canvas drawImage: image
		sourceRect: OFMakeRect(1.0f, 1.0f, 2.0f, 2.0f)
	   destinationRect: OFMakeRect(1.0f, 0.0f, 3.0f, 3.0f)];

	/*
	 * This test checks every pixel individually instead of checking
	 * against a test image see what exactly failed, if anything.
	 */

	/* Check the non-interpolated pixels are exact. */
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(1.0f, 0.0f)],
	    [OFColor white]);
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(3.0f, 0.0f)],
	    [OFColor red]);
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(1.0f, 2.0f)],
	    [OFColor lime]);
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(3.0f, 2.0f)],
	    [OFColor blue]);

	/* Check left row is unchanged. */
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(0.0f, 0.0f)],
	    [OFColor black]);
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(0.0f, 1.0f)],
	    [OFColor black]);
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(0.0f, 2.0f)],
	    [OFColor black]);

	/* Check interpolated pixels. */
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(2.0f, 0.0f)],
	    [OFColor colorWithRed: 1.0f
			    green: 85.0f / 255.0f
			     blue: 85.0f / 255.0f
			    alpha: 1.0f]);
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(1.0f, 1.0f)],
	    [OFColor colorWithRed: 85.0f / 255.0f
			    green: 1.0f
			     blue: 85.0f / 255.0f
			    alpha: 1.0f]);
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(2.0f, 1.0f)],
	    [OFColor colorWithRed: 85.0f / 255.0f
			    green: 85.0f / 255.0f
			     blue: 142.0f / 255.0f
			    alpha: 1.0f]);
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(3.0f, 1.0f)],
	    [OFColor colorWithRed: 85.0f / 255.0f
			    green: 0.0f
			     blue: 170.0f / 255.0f
			    alpha: 1.0f]);
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(2.0f, 2.0f)],
	    [OFColor colorWithRed: 0.0f
			    green: 85.0f / 255.0f
			     blue: 170.0f / 255.0f
			    alpha: 1.0f]);
}
@end
