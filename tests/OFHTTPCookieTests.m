/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
 *   Jonathan Schleifer <js@heap.zone>
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

#import "OFHTTPCookie.h"
#import "OFAutoreleasePool.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFHTTPCookie";

@implementation TestsAppDelegate (OFHTTPCookieTests)
- (void)HTTPCookieTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFHTTPCookie *cookie[2];

	cookie[0] = [OFHTTPCookie cookieWithName: @"foo"
					   value: @"bar"];
	TEST(@"+[cookiesForString:] #1",
	    [[OFHTTPCookie cookiesForString: @"foo=bar"] isEqual:
	    [OFArray arrayWithObject: cookie[0]]])

	cookie[1] = [OFHTTPCookie cookieWithName: @"qux"
					   value: @"cookie"];
	TEST(@"+[cookiesForString:] #2",
	    [[OFHTTPCookie cookiesForString: @"foo=bar,qux=cookie"] isEqual:
	    [OFArray arrayWithObjects: cookie[0], cookie[1], nil]])

	[cookie[0] setExpires:
	    [OFDate dateWithTimeIntervalSince1970: 1234567890]];
	[cookie[1] setExpires:
	    [OFDate dateWithTimeIntervalSince1970: 1234567890]];
	[cookie[0] setPath: @"/x"];
	[cookie[1] setDomain: @"heap.zone"];
	[cookie[1] setPath: @"/objfw"];
	[cookie[1] setSecure: true];
	[cookie[1] setHTTPOnly: true];
	[[cookie[1] extensions] addObject: @"foo"];
	[[cookie[1] extensions] addObject: @"bar"];
	TEST(@"+[cookiesForString:] #3",
	    [[OFHTTPCookie cookiesForString:
	    @"foo=bar; Expires=Fri, 13 Feb 2009 23:31:30 GMT; Path=/x,"
	    @"qux=cookie; Expires=Fri, 13 Feb 2009 23:31:30 GMT; "
	    @"Domain=heap.zone; Path=/objfw; Secure; HTTPOnly; foo; bar"]
	    isEqual: [OFArray arrayWithObjects: cookie[0], cookie[1], nil]])

	[pool drain];
}
@end
