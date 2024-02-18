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

#import "ObjFW.h"
#import "ObjFWTest.h"

@interface OFHTTPCookieTests: OTTestCase
@end

@implementation OFHTTPCookieTests
- (void)testCookiesWithResponseHeaderFieldsForIRI
{
	OFIRI *IRI = [OFIRI IRIWithString: @"http://nil.im"];
	OFHTTPCookie *cookie1 = [OFHTTPCookie cookieWithName: @"foo"
						       value: @"bar"
						      domain: @"nil.im"];
	OFHTTPCookie *cookie2 = [OFHTTPCookie cookieWithName: @"qux"
						       value: @"cookie"
						      domain: @"nil.im"];
	OFDictionary *headers;

	headers = [OFDictionary dictionaryWithObject: @"foo=bar"
					      forKey: @"Set-Cookie"];
	OTAssertEqualObjects(
	    [OFHTTPCookie cookiesWithResponseHeaderFields: headers forIRI: IRI],
	    [OFArray arrayWithObject: cookie1]);

	headers = [OFDictionary dictionaryWithObject: @"foo=bar,qux=cookie"
					      forKey: @"Set-Cookie"];
	OTAssertEqualObjects(
	    [OFHTTPCookie cookiesWithResponseHeaderFields: headers forIRI: IRI],
	    ([OFArray arrayWithObjects: cookie1, cookie2, nil]));

	cookie1.expires = [OFDate dateWithTimeIntervalSince1970: 1234567890];
	cookie2.expires = [OFDate dateWithTimeIntervalSince1970: 1234567890];
	cookie1.path = @"/x";
	cookie2.domain = @"webkeks.org";
	cookie2.path = @"/objfw";
	cookie2.secure = true;
	cookie2.HTTPOnly = true;
	[cookie2.extensions addObject: @"foo"];
	[cookie2.extensions addObject: @"bar"];

	headers = [OFDictionary
	    dictionaryWithObject: @"foo=bar; "
				  @"Expires=Fri, 13 Feb 2009 23:31:30 GMT; "
				  @"Path=/x,"
				  @"qux=cookie; "
				  @"Expires=Fri, 13 Feb 2009 23:31:30 GMT; "
				  @"Domain=webkeks.org; "
				  @"Path=/objfw; "
				  @"Secure; "
				  @"HTTPOnly; "
				  @"foo; "
				  @"bar"
			  forKey: @"Set-Cookie"];
	OTAssertEqualObjects(
	    [OFHTTPCookie cookiesWithResponseHeaderFields: headers forIRI: IRI],
	    ([OFArray arrayWithObjects: cookie1, cookie2, nil]));
}

- (void)testRequestHeaderFieldsWithCookies
{
	OFHTTPCookie *cookie1 = [OFHTTPCookie cookieWithName: @"foo"
						       value: @"bar"
						      domain: @"nil.im"];
	OFHTTPCookie *cookie2 = [OFHTTPCookie cookieWithName: @"qux"
						       value: @"cookie"
						      domain: @"nil.im"];

	OTAssertEqualObjects([OFHTTPCookie requestHeaderFieldsWithCookies:
	    ([OFArray arrayWithObjects: cookie1, cookie2, nil])],
	    [OFDictionary dictionaryWithObject: @"foo=bar; qux=cookie"
					forKey: @"Cookie"]);
}
@end
