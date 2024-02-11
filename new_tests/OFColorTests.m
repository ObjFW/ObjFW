/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE.QPL included in
 * the packaging of this file.
 *
 * Alternatively, it may be distributed under the terms of the GNU General
 * Public License, either version 2 or 3, which can be found in the file
 * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the packaging of this
 * file.
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
