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

@interface OFHTTPCookieManagerTests: OTTestCase
@end

@implementation OFHTTPCookieManagerTests
- (void)testCookieManager
{
	OFHTTPCookieManager *manager = [OFHTTPCookieManager manager];
	OFIRI *IRI1, *IRI2, *IRI3, *IRI4;
	OFHTTPCookie *cookie1, *cookie2, *cookie3, *cookie4, *cookie5;

	IRI1 = [OFIRI IRIWithString: @"http://nil.im/foo"];
	IRI2 = [OFIRI IRIWithString: @"https://nil.im/foo/bar"];
	IRI3 = [OFIRI IRIWithString: @"https://test.nil.im/foo/bar"];
	IRI4 = [OFIRI IRIWithString: @"http://webkeks.org/foo/bar"];

	cookie1 = [OFHTTPCookie cookieWithName: @"test"
					 value: @"1"
					domain: @"nil.im"];
	[manager addCookie: cookie1 forIRI: IRI1];
	OTAssertEqualObjects([manager cookiesForIRI: IRI1],
	    [OFArray arrayWithObject: cookie1]);

	cookie2 = [OFHTTPCookie cookieWithName: @"test"
					 value: @"2"
					domain: @"webkeks.org"];
	[manager addCookie: cookie2 forIRI: IRI1];
	OTAssertEqualObjects([manager cookiesForIRI: IRI1],
	    [OFArray arrayWithObject: cookie1]);
	OTAssertEqualObjects([manager cookiesForIRI: IRI4], [OFArray array]);

	cookie3 = [OFHTTPCookie cookieWithName: @"test"
					 value: @"3"
					domain: @"nil.im"];
	cookie3.secure = true;
	[manager addCookie: cookie3 forIRI: IRI2];
	OTAssertEqualObjects([manager cookiesForIRI: IRI2],
	    [OFArray arrayWithObject: cookie3]);
	OTAssertEqualObjects([manager cookiesForIRI: IRI1], [OFArray array]);

	cookie3.expires = [OFDate dateWithTimeIntervalSinceNow: -1];
	cookie4 = [OFHTTPCookie cookieWithName: @"test"
					 value: @"4"
					domain: @"nil.im"];
	cookie4.domain = @".nil.im";
	[manager addCookie: cookie4 forIRI: IRI2];
	OTAssertEqualObjects([manager cookiesForIRI: IRI2],
	    [OFArray arrayWithObject: cookie4]);
	OTAssertEqualObjects([manager cookiesForIRI: IRI3],
	    [OFArray arrayWithObject: cookie4]);

	cookie5 = [OFHTTPCookie cookieWithName: @"bar"
					 value: @"5"
					domain: @"test.nil.im"];
	[manager addCookie: cookie5 forIRI: IRI1];
	OTAssertEqualObjects([manager cookiesForIRI: IRI1],
	    [OFArray arrayWithObject: cookie4]);
	OTAssertEqualObjects([manager cookiesForIRI: IRI3],
	    ([OFArray arrayWithObjects: cookie4, cookie5, nil]));

	OTAssertEqualObjects(manager.cookies,
	    ([OFArray arrayWithObjects: cookie3, cookie4, cookie5, nil]));
	[manager purgeExpiredCookies];
	OTAssertEqualObjects(manager.cookies,
	    ([OFArray arrayWithObjects: cookie4, cookie5, nil]));
}
@end
