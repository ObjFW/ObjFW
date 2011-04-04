/*
 * Copyright (c) 2008, 2009, 2010, 2011
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "OFDictionary.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFAutoreleasePool.h"

#import "OFEnumerationMutationException.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFDictionary";
static OFString *keys[] = {
	@"key1",
	@"key2"
};
static OFString *values[] = {
	@"value1",
	@"value2"
};

@implementation TestsAppDelegate (OFDictionaryTests)
- (void)dictionaryTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFMutableDictionary *dict = [OFMutableDictionary dictionary], *dict2;
	OFEnumerator *key_enum, *obj_enum;
	OFArray *akeys, *avalues;

	[dict setObject: values[0]
		 forKey: keys[0]];
	[dict setObject: values[1]
		 forKey: keys[1]];

	TEST(@"-[objectForKey:]",
	    [[dict objectForKey: keys[0]] isEqual: values[0]] &&
	    [[dict objectForKey: keys[1]] isEqual: values[1]] &&
	    [dict objectForKey: @"key3"] == nil)

	TEST(@"-[containsObject:]",
	    [dict containsObject: values[0]] == YES &&
	    [dict containsObject: @"nonexistant"] == NO)

	TEST(@"-[containsObjectIdenticalTo:]",
	    [dict containsObjectIdenticalTo: values[0]] == YES &&
	    [dict containsObjectIdenticalTo:
	    [OFString stringWithString: values[0]]] == NO)

	TEST(@"-[description]",
	    [[dict description] isEqual:
	    @"{\n\tkey1 = value1;\n\tkey2 = value2;\n}"])

	TEST(@"-[keyEnumerator]", (key_enum = [dict keyEnumerator]))
	TEST(@"-[objectEnumerator]", (obj_enum = [dict objectEnumerator]))

	TEST(@"OFEnumerator's -[nextObject]",
	    [[key_enum nextObject] isEqual: keys[0]] &&
	    [[obj_enum nextObject] isEqual: values[0]] &&
	    [[key_enum nextObject] isEqual: keys[1]] &&
	    [[obj_enum nextObject] isEqual: values[1]] &&
	    [key_enum nextObject] == nil && [obj_enum nextObject] == nil)

	[key_enum reset];
	[dict removeObjectForKey: keys[0]];

	EXPECT_EXCEPTION(@"Detection of mutation during enumeration",
	    OFEnumerationMutationException, [key_enum nextObject]);

	[dict setObject: values[0]
		 forKey: keys[0]];

#ifdef OF_HAVE_FAST_ENUMERATION
	size_t i = 0;
	BOOL ok = YES;

	for (OFString *key in dict) {
		if (![key isEqual: keys[i]])
			ok = NO;
		[dict setObject: [dict objectForKey: key]
			 forKey: key];
		i++;
	}

	TEST(@"Fast Enumeration", ok)

	ok = NO;
	@try {
		for (OFString *key in dict)
			[dict setObject: @""
				 forKey: @""];
	} @catch (OFEnumerationMutationException *e) {
		ok = YES;
		[e dealloc];
	}

	TEST(@"Detection of mutation during Fast Enumeration", ok)

	[dict removeObjectForKey: @""];
#endif

#ifdef OF_HAVE_BLOCKS
	{
		__block size_t i = 0;
		__block BOOL ok = YES;

		[dict enumerateKeysAndObjectsUsingBlock:
		    ^ (id key, id obj, BOOL *stop) {
			if (![key isEqual: keys[i]])
				ok = NO;
			[dict setObject: [dict objectForKey: key]
				 forKey: key];
			i++;
		}];

		TEST(@"Enumeration using blocks", ok)

		ok = NO;
		@try {
			[dict enumerateKeysAndObjectsUsingBlock:
			    ^ (id key, id obj, BOOL *stop) {
				[dict setObject: @""
					 forKey: @""];
			}];
		} @catch (OFEnumerationMutationException *e) {
			ok = YES;
			[e dealloc];
		}

		TEST(@"Detection of mutation during enumeration using blocks",
		    ok)

		[dict removeObjectForKey: @""];
	}

	TEST(@"-[replaceObjectsUsingBlock:]",
	    R([dict replaceObjectsUsingBlock:
	    ^ id (id key, id obj, BOOL *stop) {
		if ([key isEqual: keys[0]])
			return @"value_1";
		if ([key isEqual: keys[1]])
			return @"value_2";

		return nil;
	    }]) && [[dict objectForKey: keys[0]] isEqual: @"value_1"] &&
	    [[dict objectForKey: keys[1]] isEqual: @"value_2"])

	TEST(@"-[mappedDictionaryUsingBlock:]",
	    [[[dict mappedDictionaryUsingBlock: ^ id (id key, id obj) {
		if ([key isEqual: keys[0]])
			return @"val1";
		if ([key isEqual: keys[1]])
			return @"val2";

		return nil;
	    }] description] isEqual: @"{\n\tkey1 = val1;\n\tkey2 = val2;\n}"])

	TEST(@"-[filteredDictionaryUsingBlock:]",
	    [[[dict filteredDictionaryUsingBlock: ^ BOOL (id key, id obj) {
		return ([key isEqual: keys[0]] ?  YES : NO);
	    }] description] isEqual: @"{\n\tkey1 = value_1;\n}"])
#endif

	TEST(@"-[count]", [dict count] == 2)

	TEST(@"+[dictionaryWithKeysAndObjects:]",
	    (dict = [OFDictionary dictionaryWithKeysAndObjects: @"foo", @"bar",
								@"baz", @"qux",
								nil]) &&
	    [[dict objectForKey: @"foo"] isEqual: @"bar"] &&
	    [[dict objectForKey: @"baz"] isEqual: @"qux"])

	TEST(@"+[dictionaryWithObject:forKey:]",
	    (dict = [OFDictionary dictionaryWithObject: @"bar"
						forKey: @"foo"]) &&
	    [[dict objectForKey: @"foo"] isEqual: @"bar"])

	akeys = [OFArray arrayWithObjects: keys[0], keys[1], nil];
	avalues = [OFArray arrayWithObjects: values[0], values[1], nil];
	TEST(@"+[dictionaryWithObjects:forKeys:]",
	    (dict = [OFDictionary dictionaryWithObjects: avalues
						forKeys: akeys]) &&
	    [[dict objectForKey: keys[0]] isEqual: values[0]] &&
	    [[dict objectForKey: keys[1]] isEqual: values[1]])

	TEST(@"-[copy]",
	    (dict = [[dict copy] autorelease]) &&
	    [[dict objectForKey: keys[0]] isEqual: values[0]] &&
	    [[dict objectForKey: keys[1]] isEqual: values[1]])

	dict2 = dict;
	TEST(@"-[mutableCopy]",
	    (dict = [[dict mutableCopy] autorelease]) &&
	    [dict count] == [dict2 count] &&
	    [[dict objectForKey: keys[0]] isEqual: values[0]] &&
	    [[dict objectForKey: keys[1]] isEqual: values[1]] &&
	    R([dict setObject: @"value3"
		       forKey: @"key3"]) &&
	    [[dict objectForKey: @"key3"] isEqual: @"value3"] &&
	    [[dict objectForKey: keys[0]] isEqual: values[0]] &&
	    R([dict setObject: @"foo"
		       forKey: keys[0]]) &&
	    [[dict objectForKey: keys[0]] isEqual: @"foo"])

	TEST(@"-[removeObjectForKey:]",
	    R([dict removeObjectForKey: keys[0]]) &&
	    [dict objectForKey: keys[0]] == nil)

	[dict setObject: @"foo"
		 forKey: keys[0]];
	TEST(@"-[isEqual:]", ![dict isEqual: dict2] &&
	    R([dict removeObjectForKey: @"key3"]) &&
	    ![dict isEqual: dict2] &&
	    R([dict setObject: values[0]
		       forKey: keys[0]]) &&
	    [dict isEqual: dict2])

	[pool drain];
}
@end
