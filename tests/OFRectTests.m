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

@interface OFRectTests: OTTestCase
@end

@implementation OFRectTests
- (void)testIntersectionRect
{
	OFRect rect1, rect2, rect;

	rect1 = OFMakeRect(0.0f, 0.0f, 3.0f, 3.0f);
	rect2 = OFMakeRect(1.0f, 1.0f, 1.0f, 1.0f);
	rect = OFMakeRect(1.0f, 1.0f, 1.0f, 1.0f);
	OTAssert(OFEqualRects(OFIntersectionRect(rect1, rect2), rect));

	rect1 = OFMakeRect(0.0f, 0.0f, 1.0f, 1.0f);
	rect2 = OFMakeRect(0.0f, 1.0f, 1.0f, 1.0f);
	rect = OFMakeRect(0.0f, 0.0f, 0.0f, 0.0f);
	OTAssert(OFEqualRects(OFIntersectionRect(rect1, rect2), rect));

	rect1 = OFMakeRect(0.0f, 0.0f, 3.0f, 3.0f);
	rect2 = OFMakeRect(1.0f, 1.0f, 4.0f, 5.0f);
	rect = OFMakeRect(1.0f, 1.0f, 2.0f, 2.0f);
	OTAssert(OFEqualRects(OFIntersectionRect(rect1, rect2), rect));

	rect1 = OFMakeRect(2.0f, 2.0f, 3.0f, 3.0f);
	rect2 = OFMakeRect(1.0f, 1.0f, 5.0f, 2.0f);
	rect = OFMakeRect(2.0f, 2.0f, 3.0f, 1.0f);
	OTAssert(OFEqualRects(OFIntersectionRect(rect1, rect2), rect));
}
@end
