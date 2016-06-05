/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

#import "OFDictionary.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFNumber.h"
#import "OFAutoreleasePool.h"

#import "OFEnumerationMutationException.h"
#import "OFUndefinedKeyException.h"

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
	OFMutableDictionary *dict = [OFMutableDictionary dictionary];
	OFDictionary *idict;
	OFEnumerator *key_enum, *obj_enum;
	OFArray *akeys, *avalues;

	[dict setObject: values[0]
		 forKey: keys[0]];
	[dict setValue: values[1]
		forKey: keys[1]];

	TEST(@"-[objectForKey:]",
	    [[dict objectForKey: keys[0]] isEqual: values[0]] &&
	    [[dict objectForKey: keys[1]] isEqual: values[1]] &&
	    [dict objectForKey: @"key3"] == nil)

	TEST(@"-[valueForKey:]",
	    [[dict valueForKey: keys[0]] isEqual: values[0]] &&
	    [[dict valueForKey: @"@count"] isEqual:
	    [OFNumber numberWithSize: 2]])

	EXPECT_EXCEPTION(@"Catching -[setValue:forKey:] on immutable "
	    @"dictionary", OFUndefinedKeyException, [dict setValue: @"x"
							    forKey: @"x"])

	TEST(@"-[containsObject:]",
	    [dict containsObject: values[0]] &&
	    ![dict containsObject: @"nonexistant"])

	TEST(@"-[containsObjectIdenticalTo:]",
	    [dict containsObjectIdenticalTo: values[0]] &&
	    ![dict containsObjectIdenticalTo:
	    [OFString stringWithString: values[0]]])

	TEST(@"-[description]",
	    [[dict description] isEqual:
	    @"{\n\tkey1 = value1;\n\tkey2 = value2;\n}"])

	TEST(@"-[allKeys]",
	    [[dict allKeys] isEqual: [OFArray arrayWithObjects: keys[0],
	    keys[1], nil]])

	TEST(@"-[allObjects]",
	    [[dict allObjects] isEqual: [OFArray arrayWithObjects: values[0],
	    values[1], nil]])

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

	size_t i = 0;
	bool ok = true;

	for (OFString *key in dict) {
		if (i > 1 || ![key isEqual: keys[i]]) {
			ok = false;
			break;
		}

		[dict setObject: [dict objectForKey: key]
			 forKey: key];
		i++;
	}

	TEST(@"Fast Enumeration", ok)

	ok = false;
	@try {
		for (OFString *key in dict) {
			(void)key;

			[dict setObject: @""
				 forKey: @""];
		}
	} @catch (OFEnumerationMutationException *e) {
		ok = true;
	}

	TEST(@"Detection of mutation during Fast Enumeration", ok)

	[dict removeObjectForKey: @""];

#ifdef OF_HAVE_BLOCKS
	{
		__block size_t i = 0;
		__block bool ok = true;

		[dict enumerateKeysAndObjectsUsingBlock:
		    ^ (id key, id obj, bool *stop) {
			if (i > 1 || ![key isEqual: keys[i]]) {
				ok = false;
				*stop = true;
				return;
			}

			[dict setObject: [dict objectForKey: key]
				 forKey: key];
			i++;
		}];

		TEST(@"Enumeration using blocks", ok)

		ok = false;
		@try {
			[dict enumerateKeysAndObjectsUsingBlock:
			    ^ (id key, id obj, bool *stop) {
				[dict setObject: @""
					 forKey: @""];
			}];
		} @catch (OFEnumerationMutationException *e) {
			ok = true;
		}

		TEST(@"Detection of mutation during enumeration using blocks",
		    ok)

		[dict removeObjectForKey: @""];
	}

	TEST(@"-[replaceObjectsUsingBlock:]",
	    R([dict replaceObjectsUsingBlock: ^ id (id key, id obj) {
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
	    [[[dict filteredDictionaryUsingBlock: ^ bool (id key, id obj) {
		return [key isEqual: keys[0]];
	    }] description] isEqual: @"{\n\tkey1 = value_1;\n}"])
#endif

	TEST(@"-[count]", [dict count] == 2)

	TEST(@"+[dictionaryWithKeysAndObjects:]",
	    (idict = [OFDictionary dictionaryWithKeysAndObjects: @"foo", @"bar",
								 @"baz", @"qux",
								 nil]) &&
	    [[idict objectForKey: @"foo"] isEqual: @"bar"] &&
	    [[idict objectForKey: @"baz"] isEqual: @"qux"])

	TEST(@"+[dictionaryWithObject:forKey:]",
	    (idict = [OFDictionary dictionaryWithObject: @"bar"
						 forKey: @"foo"]) &&
	    [[idict objectForKey: @"foo"] isEqual: @"bar"])

	akeys = [OFArray arrayWithObjects: keys[0], keys[1], nil];
	avalues = [OFArray arrayWithObjects: values[0], values[1], nil];
	TEST(@"+[dictionaryWithObjects:forKeys:]",
	    (idict = [OFDictionary dictionaryWithObjects: avalues
						 forKeys: akeys]) &&
	    [[idict objectForKey: keys[0]] isEqual: values[0]] &&
	    [[idict objectForKey: keys[1]] isEqual: values[1]])

	TEST(@"-[copy]",
	    (idict = [[idict copy] autorelease]) &&
	    [[idict objectForKey: keys[0]] isEqual: values[0]] &&
	    [[idict objectForKey: keys[1]] isEqual: values[1]])

	TEST(@"-[mutableCopy]",
	    (dict = [[idict mutableCopy] autorelease]) &&
	    [dict count] == [idict count] &&
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
	TEST(@"-[isEqual:]", ![dict isEqual: idict] &&
	    R([dict removeObjectForKey: @"key3"]) &&
	    ![dict isEqual: idict] &&
	    R([dict setObject: values[0]
		       forKey: keys[0]]) &&
	    [dict isEqual: idict])

	[pool drain];
}
@end
