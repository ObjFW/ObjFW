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
	[_mutableDictionary release];

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
	OFMutableDictionary *copy = [[_dictionary mutableCopy] autorelease];

	OTAssertEqualObjects(copy, _dictionary);
	OTAssertNotEqual(copy, _dictionary);
}

#ifdef OF_HAVE_BLOCKS
- (void)testReplaceObjectsUsingBlock
{
	OFMutableDictionary *mutableDictionary =
	    [[_dictionary mutableCopy] autorelease];

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
		[self release];
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
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_dictionary release];

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
