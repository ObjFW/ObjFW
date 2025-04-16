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

@interface CustomMutableDictionary: OFMutableDictionary
{
	OFMutableDictionary *_dictionary;
}
@end

@implementation OFMutableDictionaryTests
- (Class)dictionaryClass
{
	return [CustomMutableDictionary class];
}

- (void)setUp
{
	[super setUp];

	_mutableDictionary = [[self.dictionaryClass alloc] init];
}

- (void)dealloc
{
	objc_release(_mutableDictionary);

	[super dealloc];
}

- (void)testSetObjectForKey
{
	[_mutableDictionary setObject: @"bar" forKey: @"foo"];
	OTAssertEqualObjects([_mutableDictionary objectForKey: @"foo"], @"bar");

	[_mutableDictionary setObject: @"qux" forKey: @"baz"];
	OTAssertEqualObjects(_mutableDictionary,
	    ([OFDictionary dictionaryWithKeysAndObjects:
	    @"foo", @"bar", @"baz", @"qux", nil]));
}

- (void)testSetValueForKey
{
	[_mutableDictionary setValue: @"bar" forKey: @"foo"];
	OTAssertEqualObjects([_mutableDictionary objectForKey: @"foo"], @"bar");

	[_mutableDictionary setValue: @"qux" forKey: @"baz"];
	OTAssertEqualObjects(_mutableDictionary,
	    ([OFDictionary dictionaryWithKeysAndObjects:
	    @"foo", @"bar", @"baz", @"qux", nil]));
}

- (void)testRemoveObjectForKey
{
	[_mutableDictionary addEntriesFromDictionary: _dictionary];
	OTAssertEqual(_mutableDictionary.count, 2);

	[_mutableDictionary removeObjectForKey: @"key2"];
	OTAssertEqual(_mutableDictionary.count, 1);
	OTAssertEqualObjects(_mutableDictionary,
	    [OFDictionary dictionaryWithObject: @"value1" forKey: @"key1"]);
}

- (void)testMutableCopy
{
	OFMutableDictionary *copy = objc_autorelease([_dictionary mutableCopy]);

	OTAssertEqualObjects(copy, _dictionary);
	OTAssertNotEqual(copy, _dictionary);
}

#ifdef OF_HAVE_BLOCKS
- (void)testReplaceObjectsUsingBlock
{
	OFMutableDictionary *mutableDictionary =
	    objc_autorelease([_dictionary mutableCopy]);

	[mutableDictionary replaceObjectsUsingBlock: ^ id (id key, id object) {
		if ([key isEqual: @"key1"])
			return @"value_1";
		if ([key isEqual: @"key2"])
			return @"value_2";

		return nil;
	}];

	OTAssertEqualObjects(mutableDictionary,
	    ([OFDictionary dictionaryWithKeysAndObjects:
	    @"key1", @"value_1", @"key2", @"value_2", nil]));
}
#endif
@end

@implementation CustomMutableDictionary
- (instancetype)init
{
	self = [super init];

	@try {
		_dictionary = [[OFMutableDictionary alloc] init];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)initWithObjects: (const id *)objects_
			forKeys: (const id *)keys_
			  count: (size_t)count
{
	self = [super init];

	@try {
		_dictionary = [[OFMutableDictionary alloc]
		    initWithObjects: objects_
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

- (void)setObject: (id)object forKey: (id)key
{
	[_dictionary setObject: object forKey: key];
}

- (void)removeObjectForKey: (id)key
{
	[_dictionary removeObjectForKey: key];
}
@end
