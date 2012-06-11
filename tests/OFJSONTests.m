/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#import "OFString.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFNumber.h"
#import "OFNull.h"
#import "OFAutoreleasePool.h"

#import "OFInvalidJSONException.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFJSON";

@implementation TestsAppDelegate (JSONTests)
- (void)JSONTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFString *s = @"{\"foo\"\t:'ba\\r', \"x\":/*foo*/ [.5\r,0xF,null//bar\n"
	    @",\"foo\",false]}";
	OFDictionary *d = [OFDictionary dictionaryWithKeysAndObjects:
	    @"foo", @"ba\r",
	    @"x", [OFArray arrayWithObjects:
		[OFNumber numberWithFloat: .5f],
		[OFNumber numberWithInt: 0xF],
		[OFNull null],
		@"foo",
		[OFNumber numberWithBool: NO],
		nil],
	    nil];

	TEST(@"-[JSONValue #1]", [[s JSONValue] isEqual: d])

	TEST(@"-[JSONRepresentation]", [[d JSONRepresentation] isEqual:
	    @"{\"foo\":\"ba\\r\",\"x\":[0.5,15,null,\"foo\",false]}"])

	EXPECT_EXCEPTION(@"-[JSONValue #2]", OFInvalidJSONException,
	    [@"{" JSONValue])
	EXPECT_EXCEPTION(@"-[JSONValue #3]", OFInvalidJSONException,
	    [@"]" JSONValue])
	EXPECT_EXCEPTION(@"-[JSONValue #4]", OFInvalidJSONException,
	    [@"bar" JSONValue])
	EXPECT_EXCEPTION(@"-[JSONValue #5]", OFInvalidJSONException,
	    [@"[\"a\" \"b\"]" JSONValue])

	[pool drain];
}
@end
