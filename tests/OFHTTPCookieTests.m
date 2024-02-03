/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

static OFString *const module = @"OFHTTPCookie";

@implementation TestsAppDelegate (OFHTTPCookieTests)
- (void)HTTPCookieTests
{
	void *pool = objc_autoreleasePoolPush();
	OFIRI *IRI = [OFIRI IRIWithString: @"http://nil.im"];
	OFHTTPCookie *cookie1, *cookie2;
	OFArray OF_GENERIC(OFHTTPCookie *) *cookies;

	cookie1 = [OFHTTPCookie cookieWithName: @"foo"
					 value: @"bar"
					domain: @"nil.im"];
	TEST(@"+[cookiesWithResponseHeaderFields:forIRI:] #1",
	    [[OFHTTPCookie cookiesWithResponseHeaderFields: [OFDictionary
	    dictionaryWithObject: @"foo=bar"
	    forKey: @"Set-Cookie"] forIRI: IRI]
	    isEqual: [OFArray arrayWithObject: cookie1]])

	cookie2 = [OFHTTPCookie cookieWithName: @"qux"
					 value: @"cookie"
					domain: @"nil.im"];
	TEST(@"+[cookiesWithResponseHeaderFields:forIRI:] #2",
	    [[OFHTTPCookie cookiesWithResponseHeaderFields: [OFDictionary
	    dictionaryWithObject: @"foo=bar,qux=cookie"
	    forKey: @"Set-Cookie"] forIRI: IRI]
	    isEqual: [OFArray arrayWithObjects: cookie1, cookie2, nil]])

	cookie1.expires = [OFDate dateWithTimeIntervalSince1970: 1234567890];
	cookie2.expires = [OFDate dateWithTimeIntervalSince1970: 1234567890];
	cookie1.path = @"/x";
	cookie2.domain = @"webkeks.org";
	cookie2.path = @"/objfw";
	cookie2.secure = true;
	cookie2.HTTPOnly = true;
	[cookie2.extensions addObject: @"foo"];
	[cookie2.extensions addObject: @"bar"];
	TEST(@"+[cookiesWithResponseHeaderFields:forIRI:] #3",
	    [(cookies = [OFHTTPCookie cookiesWithResponseHeaderFields:
	    [OFDictionary dictionaryWithObject:
	    @"foo=bar; Expires=Fri, 13 Feb 2009 23:31:30 GMT; Path=/x,"
	    @"qux=cookie; Expires=Fri, 13 Feb 2009 23:31:30 GMT; "
	    @"Domain=webkeks.org; Path=/objfw; Secure; HTTPOnly; foo; bar"
	    forKey: @"Set-Cookie"] forIRI: IRI]) isEqual:
	    [OFArray arrayWithObjects: cookie1, cookie2, nil]])

	TEST(@"+[requestHeaderFieldsWithCookies:]",
	    [[OFHTTPCookie requestHeaderFieldsWithCookies: cookies] isEqual:
	    [OFDictionary dictionaryWithObject: @"foo=bar; qux=cookie"
					forKey: @"Cookie"]])

	objc_autoreleasePoolPop(pool);
}
@end
