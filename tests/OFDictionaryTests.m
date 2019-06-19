/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

#import "TestsAppDelegate.h"

static OFString *module = nil;
static OFString *keys[] = {
	@"key1",
	@"key2"
};
static OFString *values[] = {
	@"value1",
	@"value2"
};

@interface SimpleDictionary: OFDictionary
{
	OFMutableDictionary *_dictionary;
}
@end

@interface SimpleMutableDictionary: OFMutableDictionary
{
	OFMutableDictionary *_dictionary;
	unsigned long _mutations;
}
@end

@implementation SimpleDictionary
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

- (instancetype)initWithKey: (id)key
		  arguments: (va_list)arguments
{
	self = [super init];

	@try {
		_dictionary = [[OFMutableDictionary alloc]
		    initWithKey: key
		      arguments: arguments];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithObjects: (const id *)objects
			forKeys: (const id *)keys_
			  count: (size_t)count
{
	self = [super init];

	@try {
		_dictionary = [[OFMutableDictionary alloc]
		    initWithObjects: objects
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
	return [_dictionary count];
}

- (OFEnumerator *)keyEnumerator
{
	return [_dictionary keyEnumerator];
}
@end

@implementation SimpleMutableDictionary
+ (void)initialize
{
	if (self == [SimpleMutableDictionary class])
		[self inheritMethodsFromClass: [SimpleDictionary class]];
}

- (void)setObject: (id)object
	   forKey: (id)key
{
	bool existed = ([_dictionary objectForKey: key] == nil);

	[_dictionary setObject: object
			forKey: key];

	if (existed)
		_mutations++;
}

- (void)removeObjectForKey: (id)key
{
	bool existed = ([_dictionary objectForKey: key] == nil);

	[_dictionary removeObjectForKey: key];

	if (existed)
		_mutations++;
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t *)state
			   objects: (id *)objects
			     count: (int)count
{
	int ret = [super countByEnumeratingWithState: state
					     objects: objects
					       count: count];

	state->mutationsPtr = &_mutations;

	return ret;
}
@end

@implementation TestsAppDelegate (OFDictionaryTests)
- (void)dictionaryTestsWithClass: (Class)dictionaryClass
		    mutableClass: (Class)mutableDictionaryClass
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFMutableDictionary *mutDict = [mutableDictionaryClass dictionary];
	OFDictionary *dict;
	OFEnumerator *keyEnumerator, *objectEnumerator;
	OFArray *keysArray, *valuesArray;

	[mutDict setObject: values[0]
		    forKey: keys[0]];
	[mutDict setValue: values[1]
		   forKey: keys[1]];

	TEST(@"-[objectForKey:]",
	    [[mutDict objectForKey: keys[0]] isEqual: values[0]] &&
	    [[mutDict objectForKey: keys[1]] isEqual: values[1]] &&
	    [mutDict objectForKey: @"key3"] == nil)

	TEST(@"-[valueForKey:]",
	    [[mutDict valueForKey: keys[0]] isEqual: values[0]] &&
	    [[mutDict valueForKey: @"@count"] isEqual:
	    [OFNumber numberWithSize: 2]])

	EXPECT_EXCEPTION(@"Catching -[setValue:forKey:] on immutable "
	    @"dictionary", OFUndefinedKeyException,
	    [[dictionaryClass dictionary] setValue: @"x"
					    forKey: @"x"])

	TEST(@"-[containsObject:]",
	    [mutDict containsObject: values[0]] &&
	    ![mutDict containsObject: @"nonexistent"])

	TEST(@"-[containsObjectIdenticalTo:]",
	    [mutDict containsObjectIdenticalTo: values[0]] &&
	    ![mutDict containsObjectIdenticalTo:
	    [OFString stringWithString: values[0]]])

	TEST(@"-[description]",
	    [[mutDict description] isEqual:
	    @"{\n\tkey1 = value1;\n\tkey2 = value2;\n}"])

	TEST(@"-[allKeys]",
	    [[mutDict allKeys] isEqual: [OFArray arrayWithObjects: keys[0],
	    keys[1], nil]])

	TEST(@"-[allObjects]",
	    [[mutDict allObjects] isEqual: [OFArray arrayWithObjects: values[0],
	    values[1], nil]])

	TEST(@"-[keyEnumerator]", (keyEnumerator = [mutDict keyEnumerator]))
	TEST(@"-[objectEnumerator]",
	    (objectEnumerator = [mutDict objectEnumerator]))

	TEST(@"OFEnumerator's -[nextObject]",
	    [[keyEnumerator nextObject] isEqual: keys[0]] &&
	    [[objectEnumerator nextObject] isEqual: values[0]] &&
	    [[keyEnumerator nextObject] isEqual: keys[1]] &&
	    [[objectEnumerator nextObject] isEqual: values[1]] &&
	    [keyEnumerator nextObject] == nil &&
	    [objectEnumerator nextObject] == nil)

	[mutDict removeObjectForKey: keys[0]];

	EXPECT_EXCEPTION(@"Detection of mutation during enumeration",
	    OFEnumerationMutationException, [keyEnumerator nextObject]);

	[mutDict setObject: values[0]
		    forKey: keys[0]];

	size_t i = 0;
	bool ok = true;

	for (OFString *key in mutDict) {
		if (i > 1 || ![key isEqual: keys[i]]) {
			ok = false;
			break;
		}

		[mutDict setObject: [mutDict objectForKey: key]
			    forKey: key];
		i++;
	}

	TEST(@"Fast Enumeration", ok)

	ok = false;
	@try {
		for (OFString *key in mutDict) {
			(void)key;

			[mutDict setObject: @""
				    forKey: @""];
		}
	} @catch (OFEnumerationMutationException *e) {
		ok = true;
	}

	TEST(@"Detection of mutation during Fast Enumeration", ok)

	[mutDict removeObjectForKey: @""];

	TEST(@"-[stringByURLEncoding]",
	    [[[OFDictionary dictionaryWithKeysAndObjects: @"foo", @"bar",
							  @"q&x", @"q=x", nil]
	    stringByURLEncoding] isEqual: @"q%26x=q%3Dx&foo=bar"])

#ifdef OF_HAVE_BLOCKS
	{
		__block size_t j = 0;
		__block bool blockOk = true;

		[mutDict enumerateKeysAndObjectsUsingBlock:
		    ^ (id key, id object, bool *stop) {
			if (j > 1 || ![key isEqual: keys[j]]) {
				blockOk = false;
				*stop = true;
				return;
			}

			[mutDict setObject: [mutDict objectForKey: key]
				    forKey: key];
			j++;
		}];

		TEST(@"Enumeration using blocks", blockOk)

		blockOk = false;
		@try {
			[mutDict enumerateKeysAndObjectsUsingBlock:
			    ^ (id key, id object, bool *stop) {
				[mutDict setObject: @""
					    forKey: @""];
			}];
		} @catch (OFEnumerationMutationException *e) {
			blockOk = true;
		}

		TEST(@"Detection of mutation during enumeration using blocks",
		    blockOk)

		[mutDict removeObjectForKey: @""];
	}

	TEST(@"-[replaceObjectsUsingBlock:]",
	    R([mutDict replaceObjectsUsingBlock: ^ id (id key, id object) {
		if ([key isEqual: keys[0]])
			return @"value_1";
		if ([key isEqual: keys[1]])
			return @"value_2";

		return nil;
	    }]) && [[mutDict objectForKey: keys[0]] isEqual: @"value_1"] &&
	    [[mutDict objectForKey: keys[1]] isEqual: @"value_2"])

	TEST(@"-[mappedDictionaryUsingBlock:]",
	    [[[mutDict mappedDictionaryUsingBlock: ^ id (id key, id object) {
		if ([key isEqual: keys[0]])
			return @"val1";
		if ([key isEqual: keys[1]])
			return @"val2";

		return nil;
	    }] description] isEqual: @"{\n\tkey1 = val1;\n\tkey2 = val2;\n}"])

	TEST(@"-[filteredDictionaryUsingBlock:]",
	    [[[mutDict filteredDictionaryUsingBlock:
	    ^ bool (id key, id object) {
		return [key isEqual: keys[0]];
	    }] description] isEqual: @"{\n\tkey1 = value_1;\n}"])
#endif

	TEST(@"-[count]", mutDict.count == 2)

	TEST(@"+[dictionaryWithKeysAndObjects:]",
	    (dict = [dictionaryClass dictionaryWithKeysAndObjects:
	    @"foo", @"bar", @"baz", @"qux", nil]) &&
	    [[dict objectForKey: @"foo"] isEqual: @"bar"] &&
	    [[dict objectForKey: @"baz"] isEqual: @"qux"])

	TEST(@"+[dictionaryWithObject:forKey:]",
	    (dict = [dictionaryClass dictionaryWithObject: @"bar"
						   forKey: @"foo"]) &&
	    [[dict objectForKey: @"foo"] isEqual: @"bar"])

	keysArray = [OFArray arrayWithObjects: keys[0], keys[1], nil];
	valuesArray = [OFArray arrayWithObjects: values[0], values[1], nil];
	TEST(@"+[dictionaryWithObjects:forKeys:]",
	    (dict = [dictionaryClass dictionaryWithObjects: valuesArray
						   forKeys: keysArray]) &&
	    [[dict objectForKey: keys[0]] isEqual: values[0]] &&
	    [[dict objectForKey: keys[1]] isEqual: values[1]])

	TEST(@"-[copy]",
	    (dict = [[dict copy] autorelease]) &&
	    [[dict objectForKey: keys[0]] isEqual: values[0]] &&
	    [[dict objectForKey: keys[1]] isEqual: values[1]])

	TEST(@"-[mutableCopy]",
	    (mutDict = [[dict mutableCopy] autorelease]) &&
	    mutDict.count == dict.count &&
	    [[mutDict objectForKey: keys[0]] isEqual: values[0]] &&
	    [[mutDict objectForKey: keys[1]] isEqual: values[1]] &&
	    R([mutDict setObject: @"value3"
			  forKey: @"key3"]) &&
	    [[mutDict objectForKey: @"key3"] isEqual: @"value3"] &&
	    [[mutDict objectForKey: keys[0]] isEqual: values[0]] &&
	    R([mutDict setObject: @"foo"
			  forKey: keys[0]]) &&
	    [[mutDict objectForKey: keys[0]] isEqual: @"foo"])

	TEST(@"-[removeObjectForKey:]",
	    R([mutDict removeObjectForKey: keys[0]]) &&
	    [mutDict objectForKey: keys[0]] == nil)

	[mutDict setObject: @"foo"
		    forKey: keys[0]];
	TEST(@"-[isEqual:]", ![mutDict isEqual: dict] &&
	    R([mutDict removeObjectForKey: @"key3"]) &&
	    ![mutDict isEqual: dict] &&
	    R([mutDict setObject: values[0]
			  forKey: keys[0]]) &&
	    [mutDict isEqual: dict])

	[pool drain];
}

- (void)dictionaryTests
{
	module = @"OFDictionary";
	[self dictionaryTestsWithClass: [SimpleDictionary class]
			  mutableClass: [SimpleMutableDictionary class]];

	module = @"OFDictionary_hashtable";
	[self dictionaryTestsWithClass: [OFDictionary class]
			  mutableClass: [OFMutableDictionary class]];
}
@end
