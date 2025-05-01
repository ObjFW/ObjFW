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

#import "OFMutableDictionaryTests.h"

#import "OFConcreteMutableDictionary.h"

@interface OFConcreteMutableDictionaryTests: OFMutableDictionaryTests
@end

#ifdef OF_MORPHOS
void *__objc_class_name_OFConcreteMutableDictionary;
#endif

@implementation OFConcreteMutableDictionaryTests
- (Class)dictionaryClass
{
	return [OFConcreteMutableDictionary class];
}

- (void)testDetectMutationDuringEnumeration
{
	OFMutableDictionary *mutableDictionary =
	    objc_autorelease([_dictionary mutableCopy]);
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
	    objc_autorelease([_dictionary mutableCopy]);
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
	    objc_autorelease([_dictionary mutableCopy]);
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
