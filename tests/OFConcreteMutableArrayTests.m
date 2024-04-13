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

#import "OFMutableArrayTests.h"

#import "OFConcreteMutableArray.h"

@interface OFConcreteMutableArrayTests: OFMutableArrayTests
@end

static OFString *const cArray[] = {
	@"Foo",
	@"Bar",
	@"Baz"
};

@implementation OFConcreteMutableArrayTests
- (Class)arrayClass
{
	return [OFConcreteMutableArray class];
}

- (void)testDetectMutationDuringEnumeration
{
	OFEnumerator *enumerator = [_mutableArray objectEnumerator];
	OFString *object;
	size_t i;

	i = 0;
	while ((object = [enumerator nextObject]) != nil) {
		OTAssertEqualObjects(object, cArray[i]);

		[_mutableArray replaceObjectAtIndex: i withObject: @""];
		i++;
	}
	OTAssertEqual(i, _mutableArray.count);

	[_mutableArray removeObjectAtIndex: 0];
	OTAssertThrowsSpecific([enumerator nextObject],
	    OFEnumerationMutationException);
}

- (void)testDetectMutationDuringFastEnumeration
{
	bool detected = false;
	size_t i;

	i = 0;
	for (OFString *object in _mutableArray) {
		OTAssertEqualObjects(object, cArray[i]);

		[_mutableArray replaceObjectAtIndex: i withObject: @""];
		i++;
	}
	OTAssertEqual(i, _mutableArray.count);

	@try {
		for (OFString *object in _mutableArray) {
			(void)object;
			[_mutableArray removeObjectAtIndex: 0];
		}
	} @catch (OFEnumerationMutationException *e) {
		detected = true;
	}
	OTAssertTrue(detected);
}

#ifdef OF_HAVE_BLOCKS
- (void)testDetectMutationDuringEnumerateObjectsUsingBlock
{
	__block size_t i;

	i = 0;
	[_mutableArray enumerateObjectsUsingBlock:
	    ^ (id object, size_t idx, bool *stop) {
		OTAssertEqualObjects(object, cArray[idx]);

		[_mutableArray replaceObjectAtIndex: idx withObject: @""];
		i++;
	}];
	OTAssertEqual(i, _mutableArray.count);

	OTAssertThrowsSpecific(
	    [_mutableArray enumerateObjectsUsingBlock:
	    ^ (id object, size_t idx, bool *stop) {
		[_mutableArray removeObjectAtIndex: 0];
	    }],
	    OFEnumerationMutationException);
}
#endif
@end
