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

@interface OFRangeTests: OTTestCase
@end

@implementation OFRangeTests
- (void)testMergeRanges
{
	OFRange range1, range2, range;

	range1 = OFMakeRange(1, 2);
	range2 = OFMakeRange(2, 2);
	range = OFMakeRange(1, 3);
	OTAssert(OFEqualRanges(OFMergeRanges(range1, range2), range));
	OTAssert(OFEqualRanges(OFMergeRanges(range2, range1), range));

	range1 = OFMakeRange(1, 2);
	range2 = OFMakeRange(3, 1);
	range = OFMakeRange(1, 3);
	OTAssert(OFEqualRanges(OFMergeRanges(range1, range2), range));
	OTAssert(OFEqualRanges(OFMergeRanges(range2, range1), range));

	range1 = OFMakeRange(1, 1);
	range2 = OFMakeRange(3, 1);
	range = OFMakeRange(OFNotFound, 0);
	OTAssert(OFEqualRanges(OFMergeRanges(range1, range2), range));
	OTAssert(OFEqualRanges(OFMergeRanges(range2, range1), range));
}
@end
