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

#import "OFString.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFNumber.h"
#import "OFNull.h"
#import "OFAutoreleasePool.h"

#import "OFInvalidEncodingException.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFJSON";

@implementation TestsAppDelegate (JSONTests)
- (void)JSONTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFString *s = @"{\"foo\"\t:\"bar\", \"x\":/*fooo*/ [7.5\r,null//bar\n"
	    @",\"foo\",false]}";
	OFDictionary *d = [OFDictionary dictionaryWithKeysAndObjects:
	    @"foo", @"bar",
	    @"x", [OFArray arrayWithObjects:
		[OFNumber numberWithFloat: 7.5],
		[OFNull null],
		@"foo",
		[OFNumber numberWithBool: NO],
		nil],
	    nil];

	TEST(@"-[JSONValue #1]", [[s JSONValue] isEqual: d])

	TEST(@"-[JSONRepresentation]", [[d JSONRepresentation] isEqual:
	    @"{\"foo\":\"bar\",\"x\":[7.5,null,\"foo\",false]}"])

	EXPECT_EXCEPTION(@"-[JSONValue #2]", OFInvalidEncodingException,
	    [@"{" JSONValue])
	EXPECT_EXCEPTION(@"-[JSONValue #3]", OFInvalidEncodingException,
	    [@"]" JSONValue])
	EXPECT_EXCEPTION(@"-[JSONValue #4]", OFInvalidEncodingException,
	    [@"bar" JSONValue])
	EXPECT_EXCEPTION(@"-[JSONValue #5]", OFInvalidEncodingException,
	    [@"[\"a\" \"b\"]" JSONValue])

	[pool drain];
}
@end
