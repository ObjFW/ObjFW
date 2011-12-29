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

#import "TestsAppDelegate.h"

static OFString *module = @"OFJSON";

@implementation TestsAppDelegate (JSONTests)
- (void)JSONTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFString *s = @"{\"foo\"\t:\"bar\", \"x\": [7.5\r,null,\"foo\",false]}";
	OFDictionary *d = [OFDictionary dictionaryWithKeysAndObjects:
	    @"foo", @"bar",
	    @"x", [OFArray arrayWithObjects:
		[OFNumber numberWithFloat: 7.5],
		[OFNull null],
		@"foo",
		[OFNumber numberWithBool: NO],
		nil],
	    nil];

	TEST(@"-[JSONValue]", [[s JSONValue] isEqual: d])

	TEST(@"-[JSONRepresentation]", [[d JSONRepresentation] isEqual:
	    @"{\"foo\":\"bar\",\"x\":[7.5,null,\"foo\",false]}"])

	[pool drain];
}
@end
