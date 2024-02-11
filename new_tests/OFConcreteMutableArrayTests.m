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
