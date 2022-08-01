/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

static OFString *const module = @"OFSerialization";

@implementation TestsAppDelegate (OFSerializationTests)
- (void)serializationTests
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableDictionary *dict = [OFMutableDictionary dictionary];
	OFMutableArray *array = [OFMutableArray array];
	OFList *list = [OFList list];
	OFData *data;
	OFString *string;
	OFUUID *UUID;

	[array addObject: @"Qu\"xbar\ntest"];
	[array addObject: [OFNumber numberWithInt: 1234]];
	[array addObject: [OFNumber numberWithDouble: 1234.5678]];
	[array addObject: [OFMutableString stringWithString: @"asd"]];
	[array addObject: [OFDate dateWithTimeIntervalSince1970: 1234.5678]];

	[dict setObject: @"Hello" forKey: array];
	[dict setObject: @"B\"la" forKey: @"Blub"];

	[list appendObject: @"Hello"];
	[list appendObject: @"Wo\rld!\nHow are you?"];
	[list appendObject: [OFURL URLWithString: @"https://objfw.nil.im/"]];
	[list appendObject:
	    [OFXMLElement elementWithXMLString: @"<x><y/><![CDATA[<]]></x>"]];
	[list appendObject:
	    [OFSet setWithObjects: @"foo", @"foo", @"bar", nil]];
	[list appendObject:
	    [OFCountedSet setWithObjects: @"foo", @"foo", @"bar", nil]];

	[dict setObject: @"list" forKey: list];

	data = [OFData dataWithItems: "0123456789:;<ABCDEFGHJIKLMNOPQRSTUVWXYZ"
			       count: 39];
	[dict setObject: @"data" forKey: data];

	UUID = [OFUUID
	    UUIDWithUUIDString: @"01234567-89AB-CDEF-FEDC-BA9876543210"];
	[dict setObject: @"uuid" forKey: UUID];

	TEST(@"-[stringBySerializing]",
	    (string = dict.stringBySerializing) && [string isEqual:
	    [OFString stringWithContentsOfURL: [OFURL URLWithString:
	    @"objfw-embedded:///serialization.xml"]]])

	TEST(@"-[objectByDeserializing]",
	    [string.objectByDeserializing isEqual: dict])

	objc_autoreleasePoolPop(pool);
}
@end
