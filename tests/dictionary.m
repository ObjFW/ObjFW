/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#import "OFDictionary.h"
#import "OFAutoreleasePool.h"
#import "OFString.h"
#import "OFExceptions.h"

#import "main.h"

static OFString *module = @"OFDictionary";
static OFString *keys[] = {
	@"key1",
	@"key2"
};
static OFString *values[] = {
	@"value1",
	@"value2"
};

void
dictionary_tests()
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFDictionary *dict = [OFMutableDictionary dictionary];
	OFIterator *iter;
	of_iterator_pair_t pair[3];
	OFArray *akeys, *avalues;

	[dict setObject: values[0]
		 forKey: keys[0]];
	[dict setObject: values[1]
		 forKey: keys[1]];

	TEST(@"-[objectForKey:]",
	    [[dict objectForKey: keys[0]] isEqual: values[0]] &&
	    [[dict objectForKey: keys[1]] isEqual: values[1]] &&
	    [dict objectForKey: @"key3"] == nil)

	TEST(@"-[iterator]", (iter = [dict iterator]))

	pair[0] = [iter nextKeyObjectPair];
	pair[1] = [iter nextKeyObjectPair];
	pair[2] = [iter nextKeyObjectPair];
	TEST(@"OFIterator's -[nextKeyObjectPair]",
	    [pair[0].key isEqual: keys[0]] &&
	    [pair[0].object isEqual: values[0]] &&
	    [pair[1].key isEqual: keys[1]] &&
	    [pair[1].object isEqual: values[1]] &&
	    pair[2].key == nil && pair[2].object == nil)

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

	TEST(@"-[mutableCopy]",
	    (dict = [[dict mutableCopy] autorelease]) &&
	    [[dict objectForKey: keys[0]] isEqual: values[0]] &&
	    [[dict objectForKey: keys[1]] isEqual: values[1]] &&
	    [dict setObject: @"value3"
		     forKey: @"key3"] &&
	    [[dict objectForKey: @"key3"] isEqual: @"value3"] &&
	    [dict setObject: @"foo"
		     forKey: keys[0]] &&
	    [[dict objectForKey: keys[0]] isEqual: @"foo"])

	TEST(@"-[removeObjectForKey:]",
	    [dict removeObjectForKey: keys[0]] &&
	    [dict objectForKey: keys[0]] == nil)

	[pool release];
}
