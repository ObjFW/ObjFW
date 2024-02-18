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

#import "OFMutableDictionaryTests.h"

#import "OFConcreteMutableDictionary.h"

@interface OFConcreteMutableDictionaryTests: OFMutableDictionaryTests
@end

@implementation OFConcreteMutableDictionaryTests
- (Class)dictionaryClass
{
	return [OFConcreteMutableDictionary class];
}

- (void)testDetectMutationDuringEnumeration
{
	OFMutableDictionary *mutableDictionary =
	    [[_dictionary mutableCopy] autorelease];
	OFEnumerator *keyEnumerator = [mutableDictionary keyEnumerator];
	OFEnumerator *objectEnumerator = [mutableDictionary objectEnumerator];
	OFString *key;
	size_t i;

	i = 0;
	while ((key = [keyEnumerator nextObject]) != nil) {
		[mutableDictionary setObject: @"test" forKey: key];
		i++;
	}
	OTAssertEqual(i, mutableDictionary.count);

	[mutableDictionary removeObjectForKey: @"key2"];
	OTAssertThrowsSpecific([keyEnumerator nextObject],
	    OFEnumerationMutationException);
	OTAssertThrowsSpecific([objectEnumerator nextObject],
	    OFEnumerationMutationException);
}

- (void)testDetectMutationDuringFastEnumeration
{
	OFMutableDictionary *mutableDictionary =
	    [[_dictionary mutableCopy] autorelease];
	bool detected = false;
	size_t i;

	i = 0;
	for (OFString *key in mutableDictionary) {
		[mutableDictionary setObject: @"test" forKey: key];
		i++;
	}
	OTAssertEqual(i, mutableDictionary.count);

	@try {
		for (OFString *key in mutableDictionary)
			[mutableDictionary removeObjectForKey: key];
	} @catch (OFEnumerationMutationException *e) {
		detected = true;
	}
	OTAssertTrue(detected);
}

#ifdef OF_HAVE_BLOCKS
- (void)testDetectMutationDuringEnumerateObjectsUsingBlock
{
	OFMutableDictionary *mutableDictionary =
	    [[_dictionary mutableCopy] autorelease];
	__block size_t i;

	i = 0;
	[mutableDictionary enumerateKeysAndObjectsUsingBlock:
	    ^ (id key, id object, bool *stop) {
		[mutableDictionary setObject: @"test" forKey: key];
		i++;
	}];
	OTAssertEqual(i, mutableDictionary.count);

	OTAssertThrowsSpecific(
	[mutableDictionary enumerateKeysAndObjectsUsingBlock:
	    ^ (id key, id object, bool *stop) {
		[mutableDictionary removeObjectForKey: key];
	    }],
	    OFEnumerationMutationException);
}
#endif
@end
