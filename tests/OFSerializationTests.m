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

#import "OFSerialization.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFList.h"
#import "OFNumber.h"
#import "OFDate.h"
#import "OFURL.h"
#import "OFAutoreleasePool.h"
#import "OFXMLElement.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFSerialization";
static const OFString *expected = @"<?xml version='1.0' encoding='UTF-8'?>\n"
    @"<serialization xmlns='https://webkeks.org/objfw/serialization'>"
    @"<object class='OFMutableDictionary'><pair><key><object class='OFArray'>"
    @"<object class='OFString'>Qu&quot;xbar\ntest</object>"
    @"<object class='OFNumber' type='signed'>1234</object>"
    @"<object class='OFMutableString'>asd</object>"
    @"<object class='OFDate'><seconds>1234</seconds>"
    @"<microseconds>5678</microseconds></object></object></key><value>"
    @"<object class='OFString'>Hello</object></value></pair><pair><key>"
    @"<object class='OFString'>Blub</object></key><value>"
    @"<object class='OFString'>B&quot;la</object></value></pair><pair><key>"
    @"<object class='OFList'><object class='OFString'>Hello</object>"
    @"<object class='OFString'>Wo&#xD;ld!\nHow are you?</object>"
    @"<object class='OFURL'>https://webkeks.org/</object>"
    @"<object class='OFXMLElement'><name>x</name><namespaces>"
    @"<object class='OFMutableDictionary'><pair><key>"
    @"<object class='OFString'>http://www.w3.org/2000/xmlns/</object></key>"
    @"<value><object class='OFString'>xmlns</object></value></pair><pair><key>"
    @"<object class='OFString'>http://www.w3.org/XML/1998/namespace</object>"
    @"</key><value><object class='OFString'>xml</object></value></pair>"
    @"</object></namespaces><children><object class='OFMutableArray'>"
    @"<object class='OFXMLElement'><name>y</name><namespaces>"
    @"<object class='OFMutableDictionary'><pair><key><object class='OFString'>"
    @"http://www.w3.org/2000/xmlns/</object></key><value>"
    @"<object class='OFString'>xmlns</object></value></pair><pair><key>"
    @"<object class='OFString'>http://www.w3.org/XML/1998/namespace</object>"
    @"</key><value><object class='OFString'>xml</object></value></pair>"
    @"</object></namespaces></object></object></children></object></object>"
    @"</key><value><object class='OFString'>list</object></value></pair>"
    @"</object></serialization>";

@implementation TestsAppDelegate (SerializationTests)
- (void)serializationTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFMutableDictionary *d = [OFMutableDictionary dictionary];
	OFMutableArray *a = [OFMutableArray array];
	OFList *l = [OFList list];
	OFString *s;

	[a addObject: @"Qu\"xbar\ntest"];
	[a addObject: [OFNumber numberWithInt: 1234]];
	[a addObject: [OFMutableString stringWithString: @"asd"]];
	[a addObject: [OFDate dateWithTimeIntervalSince1970: 1234
					       microseconds: 5678]];

	[d setObject: @"Hello"
	      forKey: a];
	[d setObject: @"B\"la"
	      forKey: @"Blub"];

	[l appendObject: @"Hello"];
	[l appendObject: @"Wo\rld!\nHow are you?"];
	[l appendObject: [OFURL URLWithString: @"https://webkeks.org/"]];
	[l appendObject: [OFXMLElement elementWithXMLString: @"<x><y/></x>"]];

	[d setObject: @"list"
	      forKey: l];

	TEST(@"Serialization",
	    (s = [OFSerialization stringBySerializingObject: d]) &&
	    [s isEqual: expected])

	TEST(@"Deserialization",
	    [[OFSerialization objectByDeserializingString: s] isEqual: d])

	[pool drain];
}
@end
