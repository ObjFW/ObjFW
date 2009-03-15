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

#import <stdio.h>

#import "OFAutoreleasePool.h"
#import "OFDictionary.h"
#import "OFConstString.h"
#import "OFString.h"

int
main()
{
	OFDictionary *dict = [OFDictionary dictionaryWithHashSize: 16];

	OFAutoreleasePool *pool = [OFAutoreleasePool new];
	OFString *key1 = [OFString stringWithCString: "key1"];
	OFString *key2 = [OFString stringWithCString: "key2"];
	OFString *value1 = [OFString stringWithCString: "value1"];
	OFString *value2 = [OFString stringWithCString: "value2"];

	[dict set: key1
	       to: value1];
	[dict set: key2
	       to: value2];
	[pool release];

	puts([[dict get: @"key1"] cString]);
	puts([[dict get: key2] cString]);

	return 0;
}
