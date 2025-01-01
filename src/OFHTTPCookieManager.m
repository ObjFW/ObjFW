/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#import "OFHTTPCookieManager.h"
#import "OFArray.h"
#import "OFDate.h"
#import "OFHTTPCookie.h"
#import "OFIRI.h"

@implementation OFHTTPCookieManager
+ (instancetype)manager
{
	return [[[self alloc] init] autorelease];
}

- (instancetype)init
{
	self = [super init];

	@try {
		_cookies = [[OFMutableArray alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_cookies release];

	[super dealloc];
}

- (OFArray OF_GENERIC(OFHTTPCookie *) *)cookies
{
	return [[_cookies copy] autorelease];
}

- (void)addCookie: (OFHTTPCookie *)cookie forIRI: (OFIRI *)IRI
{
	void *pool = objc_autoreleasePoolPush();
	OFString *cookieDomain, *IRIHost;
	size_t i;

	IRI = IRI.IRIByAddingPercentEncodingForUnicodeCharacters;

	if (![cookie.path hasPrefix: @"/"])
		cookie.path = @"/";

	if (cookie.secure &&
	    [IRI.scheme caseInsensitiveCompare: @"https"] != OFOrderedSame) {
		objc_autoreleasePoolPop(pool);
		return;
	}

	cookieDomain = cookie.domain.lowercaseString;
	cookie.domain = cookieDomain;

	IRIHost = IRI.host.lowercaseString;
	if (![cookieDomain isEqual: IRIHost]) {
		IRIHost = [@"." stringByAppendingString: IRIHost];

		if (![cookieDomain hasSuffix: IRIHost]) {
			objc_autoreleasePoolPop(pool);
			return;
		}
	}

	i = 0;
	for (OFHTTPCookie *iter in _cookies) {
		if ([iter.name isEqual: cookie.name] &&
		    [iter.domain isEqual: cookie.domain] &&
		    [iter.path isEqual: cookie.path]) {
			[_cookies replaceObjectAtIndex: i withObject: cookie];
			objc_autoreleasePoolPop(pool);
			return;
		}

		i++;
	}

	[_cookies addObject: cookie];

	objc_autoreleasePoolPop(pool);
}

- (void)addCookies: (OFArray OF_GENERIC(OFHTTPCookie *) *)cookies
	    forIRI: (OFIRI *)IRI
{
	for (OFHTTPCookie *cookie in cookies)
		[self addCookie: cookie forIRI: IRI];
}

- (OFArray OF_GENERIC(OFHTTPCookie *) *)cookiesForIRI: (OFIRI *)IRI
{
	OFMutableArray *ret = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();

	IRI = IRI.IRIByAddingPercentEncodingForUnicodeCharacters;

	for (OFHTTPCookie *cookie in _cookies) {
		void *pool2;
		OFDate *expires;
		OFString *cookieDomain, *IRIHost, *cookiePath, *IRIPath;
		bool match;

		expires = cookie.expires;
		if (expires != nil && expires.timeIntervalSinceNow <= 0)
			continue;

		if (cookie.secure && [IRI.scheme caseInsensitiveCompare:
		    @"https"] != OFOrderedSame)
			continue;

		pool2 = objc_autoreleasePoolPush();

		cookieDomain = cookie.domain.lowercaseString;
		IRIHost = IRI.host.lowercaseString;
		if ([cookieDomain hasPrefix: @"."]) {
			if ([IRIHost hasSuffix: cookieDomain])
				match = true;
			else {
				cookieDomain =
				    [cookieDomain substringFromIndex: 1];

				match = [cookieDomain isEqual: IRIHost];
			}
		} else
			match = [cookieDomain isEqual: IRIHost];

		if (!match) {
			objc_autoreleasePoolPop(pool2);
			continue;
		}

		cookiePath = cookie.path;
		IRIPath = IRI.path;
		if (![cookiePath isEqual: @"/"]) {
			if ([cookiePath isEqual: IRIPath])
				match = true;
			else {
				if (![cookiePath hasSuffix: @"/"])
					cookiePath = [cookiePath
					    stringByAppendingString: @"/"];

				match = [IRIPath hasPrefix: cookiePath];
			}

			if (!match) {
				objc_autoreleasePoolPop(pool2);
				continue;
			}
		}

		[ret addObject: cookie];
	}

	[ret makeImmutable];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (void)purgeExpiredCookies
{
	for (size_t i = 0, count = _cookies.count; i < count; i++) {
		OFDate *expires = [[_cookies objectAtIndex: i] expires];

		if (expires != nil && expires.timeIntervalSinceNow <= 0) {
			[_cookies removeObjectAtIndex: i];

			i--;
			count--;
			continue;
		}
	}
}
@end
