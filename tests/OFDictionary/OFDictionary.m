/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <stdio.h>
#include <string.h>

#import "OFAutoreleasePool.h"
#import "OFDictionary.h"
#import "OFString.h"
#import "OFExceptions.h"

#define TESTS 15

int
main()
{
	int i = 0;

	OFDictionary *dict = [OFMutableDictionary dictionaryWithHashSize: 16];
	OFDictionary *dict2;
	OFArray *keys, *objs;
	OFIterator *iter = [dict iterator];
	of_iterator_pair_t pair[2];

	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFString *key1 = [OFString stringWithCString: "key1"];
	OFString *key2 = [OFString stringWithCString: "key2"];
	OFString *value1 = [OFString stringWithCString: "value1"];
	OFString *value2 = [OFString stringWithCString: "value2"];

	[dict setObject: value1
		 forKey: key1];
	[dict setObject: value2
		 forKey: key2];
	[pool release];

	i++;
	if (strcmp([[dict objectForKey: @"key1"] cString], "value1")) {
		printf("\033[K\033[1;31mTest %d/%d failed!\033[m\n", i, TESTS);
		return 1;
	}

	i++;
	if (strcmp([[dict objectForKey: key2] cString], "value2")) {
		printf("\033[K\033[1;31mTest %d/%d failed!\033[m\n", i, TESTS);
		return 1;
	}

	i++;
	pair[0] = [iter nextKeyObjectPair];
	pair[1] = [iter nextKeyObjectPair];
	if (![pair[0].key isEqual: @"key2"] ||
	    ![pair[0].object isEqual: @"value2"] ||
	    ![pair[1].key isEqual: @"key1"] ||
	    ![pair[1].object isEqual: @"value1"]) {
		printf("\033[K\033[1;31mTest %d/%d failed!\033[m\n", i, TESTS);
		return 1;
	}

	i++;
	[dict changeHashSize: 8];
	iter = [dict iterator];
	pair[0] = [iter nextKeyObjectPair];
	pair[1] = [iter nextKeyObjectPair];
	if (![pair[0].key isEqual: @"key1"] ||
	    ![pair[0].object isEqual: @"value1"] ||
	    ![pair[1].key isEqual: @"key2"] ||
	    ![pair[1].object isEqual: @"value2"]) {
		printf("\033[K\033[1;31mTest %d/%d failed!\033[m\n", i, TESTS);
		return 1;
	}

	i++;
	if ([dict averageItemsPerBucket] != 1.0) {
		printf("\033[K\033[1;31mTest %d/%d failed!\033[m\n", i, TESTS);
		return 1;
	}

	i++;
	if ([iter nextKeyObjectPair].object != nil) {
		printf("\033[K\033[1;31mTest %d/%d failed!\033[m\n", i, TESTS);
		return 1;
	}

	i++;
	if ([dict objectForKey: @"key3"] != nil) {
		printf("\033[K\033[1;31mTest %d/%d failed!\033[m\n", i, TESTS);
		return 1;
	}

	i++;
	[dict release];
	dict = [OFDictionary dictionaryWithKeysAndObjects: @"foo", @"bar",
							    @"baz", @"qux",
							    nil];

	if (![[dict objectForKey: @"foo"] isEqual: @"bar"]) {
		printf("\033[K\033[1;31mTest %d/%d failed!\033[m\n", i, TESTS);
		return 1;
	}

	i++;
	if (![[dict objectForKey: @"baz"] isEqual: @"qux"]) {
		printf("\033[K\033[1;31mTest %d/%d failed!\033[m\n", i, TESTS);
		return 1;
	}

	i++;
	[dict release];
	dict = [OFDictionary dictionaryWithObject: @"bar"
					   forKey: @"foo"];
	if (![[dict objectForKey: @"foo"] isEqual: @"bar"]) {
		printf("\033[K\033[1;31mTest %d/%d failed!\033[m\n", i, TESTS);
		return 1;
	}

	i++;
	[dict release];
	keys = [OFArray arrayWithObjects: @"k1", @"k2", nil];
	objs = [OFArray arrayWithObjects: @"o1", @"o2", nil];
	dict = [OFDictionary dictionaryWithObjects: objs
					   forKeys: keys];
	if (![[dict objectForKey: @"k1"] isEqual: @"o1"]) {
		printf("\033[K\033[1;31mTest %d/%d failed!\033[m\n", i, TESTS);
		return 1;
	}

	i++;
	if (![[dict objectForKey: @"k2"] isEqual: @"o2"]) {
		printf("\033[K\033[1;31mTest %d/%d failed!\033[m\n", i, TESTS);
		return 1;
	}

	i++;
	dict2 = [dict copy];
	[dict release];
	if (![[dict2 objectForKey: @"k1"] isEqual: @"o1"] ||
	    ![[dict2 objectForKey: @"k2"] isEqual: @"o2"]) {
		printf("\033[K\033[1;31mTest %d/%d failed!\033[m\n", i, TESTS);
		return 1;
	}

	i++;
	dict = [dict2 mutableCopy];
	[dict2 release];
	if (![[dict objectForKey: @"k1"] isEqual: @"o1"] ||
	    ![[dict objectForKey: @"k2"] isEqual: @"o2"]) {
		printf("\033[k\033[1;31mtest %d/%d failed!\033[m\n", i, TESTS);
		return 1;
	}

	i++;
	[dict setObject: @"o0" forKey: @"k1"];
	[dict setObject: @"o3" forKey: @"k3"];
	if (![[dict objectForKey: @"k1"] isEqual: @"o0"] ||
	    ![[dict objectForKey: @"k2"] isEqual: @"o2"] ||
	    ![[dict objectForKey: @"k3"] isEqual: @"o3"]) {
		printf("\033[k\033[1;31mtest %d/%d failed!\033[m\n", i, TESTS);
		return 1;
	}

	printf("\033[1;32mTests successful: %d/%d\033[0m\n", i, TESTS);

	return 0;
}
