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

static const float allowedImprecision = 0.0000001f;

@interface OFColorTests: OTTestCase
{
	OFColor *_color;
}
@end

@implementation OFColorTests
- (void)setUp
{
	[super setUp];

	_color = [[OFColor alloc] initWithRed: 63.0f / 255.0f
					green: 127.0f / 255.0f
					 blue: 1.0f
					alpha: 1.0f];
}

- (void)dealloc
{
	objc_release(_color);

	[super dealloc];
}

#ifdef OF_OBJFW_RUNTIME
- (void)testReturnsTaggedPointer
{
	OTAssertTrue(object_isTaggedPointer(_color));
}
#endif

- (void)testGetRedGreenBlueAlpha
{
	float red, green, blue, alpha;

	[_color getRed: &red green: &green blue: &blue alpha: &alpha];
	OTAssertEqual(red, 63.0f / 255);
	OTAssertEqual(green, 127.0f / 255);
	OTAssertEqual(blue, 1.0f);
	OTAssertEqual(alpha, 1.0f);
}

- (void)testColorUsingColorSpace
{
	OFColor *color;
	float red, green, blue, alpha;

	color = [OFColor colorWithRed: 0.5f
				green: 0.5f
				 blue: 0.5f
				alpha: 1.0f];
	color = [color colorUsingColorSpace:
	    [OFColorSpace linearSRGBColorSpace]];
	[color getRed: &red green: &green blue: &blue alpha: &alpha];

	OTAssertLessThan(fabs(red - 0.21404114f), allowedImprecision);
	OTAssertLessThan(fabs(green - 0.21404114f), allowedImprecision);
	OTAssertLessThan(fabs(blue - 0.21404114f), allowedImprecision);
	OTAssertLessThan(fabs(alpha - 1.0f), allowedImprecision);

	color = [OFColor colorWithRed: 0.2f
				green: 0.5f
				 blue: 0.1f
				alpha: 1.0f];
	color = [color colorUsingColorSpace:
	    [OFColorSpace displayP3ColorSpace]];
	[color getRed: &red green: &green blue: &blue alpha: &alpha];

	OTAssertLessThan(fabs(red - 0.2832721f), allowedImprecision);
	OTAssertLessThan(fabs(green - 0.4934571f), allowedImprecision);
	OTAssertLessThan(fabs(blue - 0.1725515f), allowedImprecision);
	OTAssertLessThan(fabs(alpha - 1.0f), allowedImprecision);
}
@end
