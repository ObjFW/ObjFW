/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

@interface OFColorTests: OTTestCase
{
	OFColor *_color;
}
@end

@implementation OFColorTests
- (void)setUp
{
	[super setUp];

	_color = [[OFColor alloc] initWithRed: 63.f / 255
					green: 127.f / 255
					 blue: 1
					alpha: 1];
}

- (void)dealloc
{
	[_color release];

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
	OTAssertEqual(red, 63.f / 255);
	OTAssertEqual(green, 127.f / 255);
	OTAssertEqual(blue, 1);
	OTAssertEqual(alpha, 1);
}
@end
