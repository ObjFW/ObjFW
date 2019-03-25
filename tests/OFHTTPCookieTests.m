/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#import "TestsAppDelegate.h"

static OFString *module = @"OFHTTPCookie";

@implementation TestsAppDelegate (OFHTTPCookieTests)
- (void)HTTPCookieTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFURL *URL = [OFURL URLWithString: @"http://heap.zone"];
	OFHTTPCookie *cookie[2];
	OFArray OF_GENERIC(OFHTTPCookie *) *cookies;

	cookie[0] = [OFHTTPCookie cookieWithName: @"foo"
					   value: @"bar"
					  domain: @"heap.zone"];
	TEST(@"+[cookiesWithResponseHeaderFields:forURL:] #1",
	    [[OFHTTPCookie cookiesWithResponseHeaderFields: [OFDictionary
	    dictionaryWithObject: @"foo=bar"
	    forKey: @"Set-Cookie"] forURL: URL]
	    isEqual: [OFArray arrayWithObject: cookie[0]]])

	cookie[1] = [OFHTTPCookie cookieWithName: @"qux"
					   value: @"cookie"
					  domain: @"heap.zone"];
	TEST(@"+[cookiesWithResponseHeaderFields:forURL:] #2",
	    [[OFHTTPCookie cookiesWithResponseHeaderFields: [OFDictionary
	    dictionaryWithObject: @"foo=bar,qux=cookie"
	    forKey: @"Set-Cookie"] forURL: URL]
	    isEqual: [OFArray arrayWithObjects: cookie[0], cookie[1], nil]])

	cookie[0].expires = [OFDate dateWithTimeIntervalSince1970: 1234567890];
	cookie[1].expires = [OFDate dateWithTimeIntervalSince1970: 1234567890];
	cookie[0].path = @"/x";
	cookie[1].domain = @"webkeks.org";
	cookie[1].path = @"/objfw";
	cookie[1].secure = true;
	cookie[1].HTTPOnly = true;
	[cookie[1].extensions addObject: @"foo"];
	[cookie[1].extensions addObject: @"bar"];
	TEST(@"+[cookiesWithResponseHeaderFields:forURL:] #3",
	    [(cookies = [OFHTTPCookie cookiesWithResponseHeaderFields:
	    [OFDictionary dictionaryWithObject:
	    @"foo=bar; Expires=Fri, 13 Feb 2009 23:31:30 GMT; Path=/x,"
	    @"qux=cookie; Expires=Fri, 13 Feb 2009 23:31:30 GMT; "
	    @"Domain=webkeks.org; Path=/objfw; Secure; HTTPOnly; foo; bar"
	    forKey: @"Set-Cookie"] forURL: URL]) isEqual:
	    [OFArray arrayWithObjects: cookie[0], cookie[1], nil]])

	TEST(@"+[requestHeaderFieldsWithCookies:]",
	    [[OFHTTPCookie requestHeaderFieldsWithCookies: cookies] isEqual:
	    [OFDictionary dictionaryWithObject: @"foo=bar; qux=cookie"
					forKey: @"Cookie"]])

	[pool drain];
}
@end
