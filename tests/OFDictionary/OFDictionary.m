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

#import "config.h"

#include <stdio.h>
#include <string.h>

#import "OFAutoreleasePool.h"
#import "OFDictionary.h"
#import "OFIterator.h"
#import "OFConstString.h"
#import "OFString.h"
#import "OFExceptions.h"

int
main()
{
	BOOL caught;

	OFDictionary *dict = [OFDictionary dictionaryWithHashSize: 16];
	OFIterator *iter = [dict iterator];

	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFString *key1 = [OFString stringWithCString: "key1"];
	OFString *key2 = [OFString stringWithCString: "key2"];
	OFString *value1 = [OFString stringWithCString: "value1"];
	OFString *value2 = [OFString stringWithCString: "value2"];

	[dict set: key1
	       to: value1];
	[dict set: key2
	       to: value2];
	[pool release];

	if (strcmp([[dict get: @"key1"] cString], "value1")) {
		puts("\033[K\033[1;31mTest 1/8 failed!\033[m");
		return 1;
	}

	if (strcmp([[dict get: key2] cString], "value2")) {
		puts("\033[K\033[1;31mTest 2/8 failed!\033[m");
		return 1;
	}

	if (![[iter nextObject] isEqual: @"key2"] ||
	    ![[iter nextObject] isEqual: @"value2"] ||
	    ![[iter nextObject] isEqual: @"key1"] ||
	    ![[iter nextObject] isEqual: @"value1"]) {
		puts("\033[K\033[1;31mTest 3/8 failed!\033[m");
		return 1;
	}

	[dict changeHashSize: 8];
	iter = [dict iterator];
	if (![[iter nextObject] isEqual: @"key1"] ||
	    ![[iter nextObject] isEqual: @"value1"] ||
	    ![[iter nextObject] isEqual: @"key2"] ||
	    ![[iter nextObject] isEqual: @"value2"]) {
		puts("\033[K\033[1;31mTest 4/8 failed!\033[m");
		return 1;
	}

	if ([dict averageItemsPerBucket] != 1.0) {
		puts("\033[K\033[1;31mTest 5/8 failed!\033[m");
		return 1;
	}

	caught = NO;
	@try {
		[iter nextObject];
	} @catch (OFNotInSetException *e) {
		caught = YES;
	}
	if (!caught) {
		puts("\033[K\033[1;31mTest 6/8 failed!\033[m");
		return 1;
	}

	caught = NO;
	@try {
		[dict get: @"key3"];
	} @catch (OFNotInSetException *e) {
		caught = YES;
	}
	if (!caught) {
		puts("\033[K\033[1;31mTest 7/8 failed!\033[m");
		return 1;
	}

	[dict remove: @"key2"];
	caught = NO;
	@try {
		[dict remove: @"key2"];
	} @catch (OFNotInSetException *e) {
		caught = YES;
	}
	if (!caught) {
		puts("\033[K\033[1;31mTest 8/8 failed!\033[m");
		return 1;
	}

	puts("\033[1;32mTests successful: 8/8\033[0m");

	return 0;
}
