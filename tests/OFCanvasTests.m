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
	static const uint32_t pixels2[] = {
		0x00000080, 0xFFFFFF80,
		0xFFFFFF40, 0x00000040
	};
	OFImage *image = [OFImage imageWithPixelsNoCopy: pixels
					    pixelFormat: OFPixelFormatRGBA8888
						   size: OFMakeSize(4.0f, 3.0f)
					   freeWhenDone: false];
	OFImage *image2 = [OFImage imageWithPixelsNoCopy: pixels2
					     pixelFormat: OFPixelFormatRGBA8888
						    size: OFMakeSize(2.0f, 2.0f)
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
			    green: 156.0f / 255.0f
			     blue: 156.0f / 255.0f
			    alpha: 1.0f]);
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(1.0f, 1.0f)],
	    [OFColor colorWithRed: 156.0f / 255.0f
			    green: 1.0f
			     blue: 156.0f / 255.0f
			    alpha: 1.0f]);
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(2.0f, 1.0f)],
	    [OFColor colorWithRed: 156.0f / 255.0f
			    green: 156.0f / 255.0f
			     blue: 197.0f / 255.0f
			    alpha: 1.0f]);
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(3.0f, 1.0f)],
	    [OFColor colorWithRed: 156.0f / 255.0f
			    green: 0.0f
			     blue: 213.0f / 255.0f
			    alpha: 1.0f]);
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(2.0f, 2.0f)],
	    [OFColor colorWithRed: 0.0f
			    green: 156.0f / 255.0f
			     blue: 213.0f / 255.0f
			    alpha: 1.0f]);

	/* Test alpha blending. */

#define SET_ALPHA(point, alpha_) \
	{								    \
		OFColor *color = [_image colorAtPoint: point];		    \
		float red, green, blue;					    \
		[color getRed: &red green: &green blue: &blue alpha: NULL]; \
		color = [OFColor colorWithRed: red			    \
					green: green			    \
					 blue: blue			    \
					alpha: alpha_];			    \
		[_image setColor: color atPoint: point];		    \
	}
	SET_ALPHA(OFMakePoint(1.f, 1.f), 0.25f)
	SET_ALPHA(OFMakePoint(2.f, 1.f), 0.50f)
	SET_ALPHA(OFMakePoint(1.f, 2.f), 0.75f)
	SET_ALPHA(OFMakePoint(2.f, 2.f), 1.0f)
#undef SET_ALPHA

	[_canvas drawImage: image2
		sourceRect: OFMakeRect(0.0f, 0.0f, 2.0f, 2.0f)
	   destinationRect: OFMakeRect(1.0f, 1.0f, 2.0f, 2.0f)];

	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(1.0f, 1.0f)],
	    [OFColor colorWithRed: 78.0f / 255.0f
			    green: 127.0f / 255.0f
			     blue: 78.0f / 255.0f
			    alpha: 160.0f / 255.0f]);
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(2.0f, 1.0f)],
	    [OFColor colorWithRed: 206.0f / 255.0f
			    green: 206.0f / 255.0f
			     blue: 226.0f / 255.0f
			    alpha: 192.0f / 255.0f]);
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(1.0f, 2.0f)],
	    [OFColor colorWithRed: 64.0f / 255.0f
			    green: 1.0f
			     blue: 64.0f / 255.0f
			    alpha: 207.0f / 255.0f]);
	OTAssertEqualObjects([_image colorAtPoint: OFMakePoint(2.0f, 2.0f)],
	    [OFColor colorWithRed: 0.0f
			    green: 117.0f / 255.0f
			     blue: 160.0f / 255.0f
			    alpha: 1.0f]);
}
@end
