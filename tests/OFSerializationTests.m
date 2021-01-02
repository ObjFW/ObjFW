/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

static OFString *module = @"OFSerialization";

@implementation TestsAppDelegate (OFSerializationTests)
- (void)serializationTests
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableDictionary *d = [OFMutableDictionary dictionary];
	OFMutableArray *a = [OFMutableArray array];
	OFList *l = [OFList list];
	OFData *data;
	OFString *s;

	[a addObject: @"Qu\"xbar\ntest"];
	[a addObject: [OFNumber numberWithInt: 1234]];
	[a addObject: [OFNumber numberWithDouble: 1234.5678]];
	[a addObject: [OFMutableString stringWithString: @"asd"]];
	[a addObject: [OFDate dateWithTimeIntervalSince1970: 1234.5678]];

	[d setObject: @"Hello"
	      forKey: a];
	[d setObject: @"B\"la"
	      forKey: @"Blub"];

	[l appendObject: @"Hello"];
	[l appendObject: @"Wo\rld!\nHow are you?"];
	[l appendObject: [OFURL URLWithString: @"https://objfw.nil.im/"]];
	[l appendObject:
	    [OFXMLElement elementWithXMLString: @"<x><y/><![CDATA[<]]></x>"]];
	[l appendObject: [OFSet setWithObjects: @"foo", @"foo", @"bar", nil]];
	[l appendObject:
	    [OFCountedSet setWithObjects: @"foo", @"foo", @"bar", nil]];

	[d setObject: @"list"
	      forKey: l];

	data = [OFData dataWithItems: "0123456789:;<ABCDEFGHJIKLMNOPQRSTUVWXYZ"
			       count: 39];
	[d setObject: @"data"
	      forKey: data];

	TEST(@"-[stringBySerializing]",
	    (s = d.stringBySerializing) && [s isEqual:
	    [OFString stringWithContentsOfFile: @"serialization.xml"]])

	TEST(@"-[objectByDeserializing]", [s.objectByDeserializing isEqual: d])

	objc_autoreleasePoolPop(pool);
}
@end
