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

#import "OFMutableSetTests.h"

#import "OFConcreteMutableSet.h"

@interface OFConcreteMutableSetTests: OFMutableSetTests
@end

@implementation OFConcreteMutableSetTests
- (Class)setClass
{
	return [OFConcreteMutableSet class];
}

- (void)testDetectMutationDuringEnumeration
{
	OFEnumerator *enumerator = [_mutableSet objectEnumerator];

	[_mutableSet removeObject: @"foo"];

	OTAssertThrowsSpecific([enumerator nextObject],
	    OFEnumerationMutationException);
}

- (void)testDetectMutationDuringFastEnumeration
{
	bool detected = false;

	@try {
		for (OFString *object in _mutableSet)
			[_mutableSet removeObject: object];
	} @catch (OFEnumerationMutationException *e) {
		detected = true;
	}

	OTAssertTrue(detected);
}

#ifdef OF_HAVE_BLOCKS
- (void)testDetectMutationDuringEnumerateObjectsUsingBlock
{
	OTAssertThrowsSpecific(
	    [_mutableSet enumerateObjectsUsingBlock: ^ (id object, bool *stop) {
		[_mutableSet removeObject: object];
	    }],
	    OFEnumerationMutationException);
}
#endif
@end
