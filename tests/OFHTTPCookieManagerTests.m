/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

static OFString *const module = @"OFHTTPCookieManager";

@implementation TestsAppDelegate (OFHTTPCookieManagerTests)
- (void)HTTPCookieManagerTests
{
	void *pool = objc_autoreleasePoolPush();
	OFHTTPCookieManager *manager = [OFHTTPCookieManager manager];
	OFURL *URL1, *URL2, *URL3, *URL4;
	OFHTTPCookie *cookie1, *cookie2, *cookie3, *cookie4, *cookie5;

	URL1 = [OFURL URLWithString: @"http://nil.im/foo"];
	URL2 = [OFURL URLWithString: @"https://nil.im/foo/bar"];
	URL3 = [OFURL URLWithString: @"https://test.nil.im/foo/bar"];
	URL4 = [OFURL URLWithString: @"http://webkeks.org/foo/bar"];

	cookie1 = [OFHTTPCookie cookieWithName: @"test"
					 value: @"1"
					domain: @"nil.im"];
	TEST(@"-[addCookie:forURL:] #1",
	    R([manager addCookie: cookie1 forURL: URL1]))

	TEST(@"-[cookiesForURL:] #1",
	    [[manager cookiesForURL: URL1] isEqual:
	    [OFArray arrayWithObject: cookie1]])

	cookie2 = [OFHTTPCookie cookieWithName: @"test"
					 value: @"2"
					domain: @"webkeks.org"];
	TEST(@"-[addCookie:forURL:] #2",
	    R([manager addCookie: cookie2 forURL: URL1]))

	TEST(@"-[cookiesForURL:] #2",
	    [[manager cookiesForURL: URL1] isEqual:
	    [OFArray arrayWithObject: cookie1]] &&
	    [[manager cookiesForURL: URL4] isEqual: [OFArray array]])

	cookie3 = [OFHTTPCookie cookieWithName: @"test"
					 value: @"3"
					domain: @"nil.im"];
	cookie3.secure = true;
	TEST(@"-[addCookie:forURL:] #3",
	    R([manager addCookie: cookie3 forURL: URL2]))

	TEST(@"-[cookiesForURL:] #3",
	    [[manager cookiesForURL: URL2] isEqual:
	    [OFArray arrayWithObject: cookie3]] &&
	    [[manager cookiesForURL: URL1] isEqual: [OFArray array]])

	cookie3.expires = [OFDate dateWithTimeIntervalSinceNow: -1];
	cookie4 = [OFHTTPCookie cookieWithName: @"test"
					 value: @"4"
					domain: @"nil.im"];
	cookie4.domain = @".nil.im";
	TEST(@"-[addCookie:forURL:] #4",
	    R([manager addCookie: cookie4 forURL: URL2]))

	TEST(@"-[cookiesForURL:] #4",
	    [[manager cookiesForURL: URL2] isEqual:
	    [OFArray arrayWithObject: cookie4]] &&
	    [[manager cookiesForURL: URL3] isEqual:
	    [OFArray arrayWithObject: cookie4]])

	cookie5 = [OFHTTPCookie cookieWithName: @"bar"
					 value: @"5"
					domain: @"test.nil.im"];
	TEST(@"-[addCookie:forURL:] #5",
	    R([manager addCookie: cookie5 forURL: URL1]))

	TEST(@"-[cookiesForURL:] #5",
	    [[manager cookiesForURL: URL1] isEqual:
	    [OFArray arrayWithObject: cookie4]] &&
	    [[manager cookiesForURL: URL3] isEqual:
	    [OFArray arrayWithObjects: cookie4, cookie5, nil]])

	TEST(@"-[purgeExpiredCookies]",
	    [manager.cookies isEqual:
	    [OFArray arrayWithObjects: cookie3, cookie4, cookie5, nil]] &&
	    R([manager purgeExpiredCookies]) &&
	    [manager.cookies isEqual:
	    [OFArray arrayWithObjects: cookie4, cookie5, nil]])

	objc_autoreleasePoolPop(pool);
}
@end
