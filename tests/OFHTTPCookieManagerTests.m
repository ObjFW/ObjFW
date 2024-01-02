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

static OFString *const module = @"OFHTTPCookieManager";

@implementation TestsAppDelegate (OFHTTPCookieManagerTests)
- (void)HTTPCookieManagerTests
{
	void *pool = objc_autoreleasePoolPush();
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
	TEST(@"-[addCookie:forIRI:] #1",
	    R([manager addCookie: cookie1 forIRI: IRI1]))

	TEST(@"-[cookiesForIRI:] #1",
	    [[manager cookiesForIRI: IRI1] isEqual:
	    [OFArray arrayWithObject: cookie1]])

	cookie2 = [OFHTTPCookie cookieWithName: @"test"
					 value: @"2"
					domain: @"webkeks.org"];
	TEST(@"-[addCookie:forIRI:] #2",
	    R([manager addCookie: cookie2 forIRI: IRI1]))

	TEST(@"-[cookiesForIRI:] #2",
	    [[manager cookiesForIRI: IRI1] isEqual:
	    [OFArray arrayWithObject: cookie1]] &&
	    [[manager cookiesForIRI: IRI4] isEqual: [OFArray array]])

	cookie3 = [OFHTTPCookie cookieWithName: @"test"
					 value: @"3"
					domain: @"nil.im"];
	cookie3.secure = true;
	TEST(@"-[addCookie:forIRI:] #3",
	    R([manager addCookie: cookie3 forIRI: IRI2]))

	TEST(@"-[cookiesForIRI:] #3",
	    [[manager cookiesForIRI: IRI2] isEqual:
	    [OFArray arrayWithObject: cookie3]] &&
	    [[manager cookiesForIRI: IRI1] isEqual: [OFArray array]])

	cookie3.expires = [OFDate dateWithTimeIntervalSinceNow: -1];
	cookie4 = [OFHTTPCookie cookieWithName: @"test"
					 value: @"4"
					domain: @"nil.im"];
	cookie4.domain = @".nil.im";
	TEST(@"-[addCookie:forIRI:] #4",
	    R([manager addCookie: cookie4 forIRI: IRI2]))

	TEST(@"-[cookiesForIRI:] #4",
	    [[manager cookiesForIRI: IRI2] isEqual:
	    [OFArray arrayWithObject: cookie4]] &&
	    [[manager cookiesForIRI: IRI3] isEqual:
	    [OFArray arrayWithObject: cookie4]])

	cookie5 = [OFHTTPCookie cookieWithName: @"bar"
					 value: @"5"
					domain: @"test.nil.im"];
	TEST(@"-[addCookie:forIRI:] #5",
	    R([manager addCookie: cookie5 forIRI: IRI1]))

	TEST(@"-[cookiesForIRI:] #5",
	    [[manager cookiesForIRI: IRI1] isEqual:
	    [OFArray arrayWithObject: cookie4]] &&
	    [[manager cookiesForIRI: IRI3] isEqual:
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
