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

#import "OFDictionaryTests.h"

static OFString *keys[] = {
	@"key1",
	@"key2"
};
static OFString *objects[] = {
	@"value1",
	@"value2"
};

@interface CustomDictionary: OFDictionary
{
	OFDictionary *_dictionary;
}
@end

@implementation OFDictionaryTests
- (Class)dictionaryClass
{
	return [CustomDictionary class];
}

- (void)setUp
{
	[super setUp];

	_dictionary = [[self.dictionaryClass alloc] initWithObjects: objects
							    forKeys: keys
							      count: 2];
}

- (void)dealloc
{
	objc_release(_dictionary);

	[super dealloc];
}

- (void)testObjectForKey
{
	OTAssertEqualObjects([_dictionary objectForKey: keys[0]], objects[0]);
	OTAssertEqualObjects([_dictionary objectForKey: keys[1]], objects[1]);
}

- (void)testCount
{
	OTAssertEqual(_dictionary.count, 2);
}

- (void)testIsEqual
{
	OTAssertEqualObjects(_dictionary,
	    [OFDictionary dictionaryWithObjects: objects
					forKeys: keys
					  count: 2]);
	OTAssertNotEqualObjects(_dictionary,
	    [OFDictionary dictionaryWithObjects: keys
					forKeys: objects
					  count: 2]);
}

- (void)testHash
{
	OTAssertEqual(_dictionary.hash,
	    [[OFDictionary dictionaryWithObjects: objects
					 forKeys: keys
					   count: 2] hash]);
	OTAssertNotEqual(_dictionary.hash,
	    [[OFDictionary dictionaryWithObject: objects[0]
					 forKey: keys[0]] hash]);
}

- (void)testCopy
{
	OTAssertEqualObjects(objc_autorelease([_dictionary copy]), _dictionary);
}

- (void)testMutableCopy
{
	OTAssertEqualObjects(
	    objc_autorelease([_dictionary mutableCopy]), _dictionary);
}

- (void)testValueForKey
{
	OTAssertEqualObjects([_dictionary valueForKey: keys[0]], objects[0]);
	OTAssertEqualObjects([_dictionary valueForKey: keys[1]], objects[1]);
	OTAssertEqualObjects(
	    [_dictionary valueForKey: @"@count"], [OFNumber numberWithInt: 2]);
}

- (void)testSetValueForKey
{
	OTAssertThrowsSpecific([_dictionary setValue: @"x" forKey: @"x"],
	    OFUndefinedKeyException);
}

- (void)testContainsObject
{
	OTAssertTrue([_dictionary containsObject: objects[0]]);
	OTAssertFalse([_dictionary containsObject: @"nonexistent"]);
}

- (void)testContainsObjectIdenticalTo
{
	OTAssertTrue([_dictionary containsObjectIdenticalTo: objects[0]]);
	OTAssertFalse([_dictionary containsObjectIdenticalTo:
	    objc_autorelease([objects[0] mutableCopy])]);
}

- (void)testDescription
{
	OTAssert(
	    [_dictionary.description isEqual:
	    @"{\n\tkey1 = value1;\n\tkey2 = value2;\n}"] ||
	    [_dictionary.description isEqual:
	    @"{\n\tkey2 = value2;\n\tkey1 = value1;\n}"]);
}

- (void)testAllKeys
{
	OTAssert(
	    [_dictionary.allKeys isEqual:
	    ([OFArray arrayWithObjects: keys[0], keys[1], nil])] ||
	    [_dictionary.allKeys isEqual:
	    ([OFArray arrayWithObjects: keys[1], keys[0], nil])]);
}

- (void)testAllObjects
{
	OTAssert(
	    [_dictionary.allObjects isEqual:
	    ([OFArray arrayWithObjects: objects[0], objects[1], nil])] ||
	    [_dictionary.allObjects isEqual:
	    ([OFArray arrayWithObjects: objects[1], objects[0], nil])]);
}

- (void)testKeyEnumerator
{
	OFEnumerator *enumerator = [_dictionary keyEnumerator];
	OFString *first, *second;

	first = [enumerator nextObject];
	second = [enumerator nextObject];
	OTAssertNil([enumerator nextObject]);

	OTAssert(
	    ([first isEqual: keys[0]] && [second isEqual: keys[1]]) ||
	    ([first isEqual: keys[1]] && [second isEqual: keys[0]]));
}

- (void)testObjectEnumerator
{
	OFEnumerator *enumerator = [_dictionary objectEnumerator];
	OFString *first, *second;

	first = [enumerator nextObject];
	second = [enumerator nextObject];
	OTAssertNil([enumerator nextObject]);

	OTAssert(
	    ([first isEqual: objects[0]] && [second isEqual: objects[1]]) ||
	    ([first isEqual: objects[1]] && [second isEqual: objects[0]]));
}

- (void)testFastEnumeration
{
	size_t i = 0;
	OFString *first = nil, *second = nil;

	for (OFString *key in _dictionary) {
		OTAssertLessThan(i, 2);

		switch (i++) {
		case 0:
			first = key;
			break;
		case 1:
			second = key;
			break;
		}
	}

	OTAssertEqual(i, 2);
	OTAssert(
	    ([first isEqual: keys[0]] && [second isEqual: keys[1]]) ||
	    ([first isEqual: keys[1]] && [second isEqual: keys[0]]));
}

#ifdef OF_HAVE_BLOCKS
- (void)testEnumerateKeysAndObjectsUsingBlock
{
	__block size_t i = 0;
	__block OFString *first = nil, *second = nil;

	[_dictionary enumerateKeysAndObjectsUsingBlock:
	    ^ (id key, id object, bool *stop) {
		OTAssertLessThan(i, 2);

		switch (i++) {
		case 0:
			first = key;
			break;
		case 1:
			second = key;
			break;
		}
	}];

	OTAssertEqual(i, 2);
	OTAssert(
	    ([first isEqual: keys[0]] && [second isEqual: keys[1]]) ||
	    ([first isEqual: keys[1]] && [second isEqual: keys[0]]));
}

- (void)testMappedDictionaryUsingBlock
{
	OTAssertEqualObjects([_dictionary mappedDictionaryUsingBlock:
	    ^ id (id key, id object) {
		if ([key isEqual: keys[0]])
			return @"val1";
		if ([key isEqual: keys[1]])
			return @"val2";

		return nil;
	    }],
	    ([OFDictionary dictionaryWithKeysAndObjects:
	    @"key1", @"val1", @"key2", @"val2", nil]));
}

- (void)testFilteredDictionaryUsingBlock
{
	OTAssertEqualObjects([_dictionary filteredDictionaryUsingBlock:
	    ^ bool (id key, id object) {
		return [key isEqual: keys[0]];
	    }],
	    [OFDictionary dictionaryWithObject: objects[0]
					forKey: keys[0]]);
}
#endif
@end

@implementation CustomDictionary
- (instancetype)initWithObjects: (const id *)objects_
			forKeys: (const id *)keys_
			  count: (size_t)count
{
	self = [super init];

	@try {
		_dictionary = [[OFDictionary alloc] initWithObjects: objects_
							    forKeys: keys_
							      count: count];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_dictionary);

	[super dealloc];
}

- (id)objectForKey: (id)key
{
	return [_dictionary objectForKey: key];
}

- (size_t)count
{
	return _dictionary.count;
}

- (OFEnumerator *)keyEnumerator
{
	return [_dictionary keyEnumerator];
}
@end
