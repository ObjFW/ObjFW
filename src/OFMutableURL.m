/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#import "OFMutableURL.h"
#import "OFArray.h"
#import "OFNumber.h"
#import "OFString.h"
#import "OFURL+Private.h"

#import "OFInvalidFormatException.h"

extern void of_url_verify_escaped(OFString *, OFCharacterSet *);

@implementation OFMutableURL
@dynamic scheme, URLEncodedScheme, host, URLEncodedHost, port, user;
@dynamic URLEncodedUser, password, URLEncodedPassword, path, URLEncodedPath;
@dynamic pathComponents, query, URLEncodedQuery, fragment, URLEncodedFragment;

+ (instancetype)URL
{
	return [[[self alloc] init] autorelease];
}

- (instancetype)init
{
	return [super of_init];
}

- (void)setScheme: (OFString *)scheme
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _URLEncodedScheme;

	_URLEncodedScheme = [[scheme stringByURLEncodingWithAllowedCharacters:
	    [OFCharacterSet URLSchemeAllowedCharacterSet]] copy];

	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)setURLEncodedScheme: (OFString *)URLEncodedScheme
{
	OFString *old;

	if (URLEncodedScheme != nil)
		of_url_verify_escaped(URLEncodedScheme,
		    [OFCharacterSet URLSchemeAllowedCharacterSet]);

	old = _URLEncodedScheme;
	_URLEncodedScheme = [URLEncodedScheme copy];
	[old release];
}

- (void)setHost: (OFString *)host
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _URLEncodedHost;

	_URLEncodedHost = [[host stringByURLEncodingWithAllowedCharacters:
	    [OFCharacterSet URLHostAllowedCharacterSet]] copy];

	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)setURLEncodedHost: (OFString *)URLEncodedHost
{
	OFString *old;

	if (URLEncodedHost != nil)
		of_url_verify_escaped(URLEncodedHost,
		    [OFCharacterSet URLHostAllowedCharacterSet]);

	old = _URLEncodedHost;
	_URLEncodedHost = [URLEncodedHost copy];
	[old release];
}

- (void)setPort: (OFNumber *)port
{
	OFNumber *old = _port;
	_port = [port copy];
	[old release];
}

- (void)setUser: (OFString *)user
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _URLEncodedUser;

	_URLEncodedUser = [[user stringByURLEncodingWithAllowedCharacters:
	    [OFCharacterSet URLUserAllowedCharacterSet]] copy];

	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)setURLEncodedUser: (OFString *)URLEncodedUser
{
	OFString *old;

	if (URLEncodedUser != nil)
		of_url_verify_escaped(URLEncodedUser,
		    [OFCharacterSet URLUserAllowedCharacterSet]);

	old = _URLEncodedUser;
	_URLEncodedUser = [URLEncodedUser copy];
	[old release];
}

- (void)setPassword: (OFString *)password
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _URLEncodedPassword;

	_URLEncodedPassword = [[password
	    stringByURLEncodingWithAllowedCharacters:
	    [OFCharacterSet URLPasswordAllowedCharacterSet]] copy];

	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)setURLEncodedPassword: (OFString *)URLEncodedPassword
{
	OFString *old;

	if (URLEncodedPassword != nil)
		of_url_verify_escaped(URLEncodedPassword,
		    [OFCharacterSet URLPasswordAllowedCharacterSet]);

	old = _URLEncodedPassword;
	_URLEncodedPassword = [URLEncodedPassword copy];
	[old release];
}

- (void)setPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _URLEncodedPath;

	_URLEncodedPath = [[path stringByURLEncodingWithAllowedCharacters:
	    [OFCharacterSet URLPathAllowedCharacterSet]] copy];

	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)setURLEncodedPath: (OFString *)URLEncodedPath
{
	OFString *old;

	if (URLEncodedPath != nil)
		of_url_verify_escaped(URLEncodedPath,
		    [OFCharacterSet URLPathAllowedCharacterSet]);

	old = _URLEncodedPath;
	_URLEncodedPath = [URLEncodedPath copy];
	[old release];
}

- (void)setPathComponents: (OFArray *)components
{
	void *pool = objc_autoreleasePoolPush();

	if (components == nil) {
		[self setPath: nil];
		return;
	}

	if ([components count] == 0)
		@throw [OFInvalidFormatException exception];

	if ([[components firstObject] length] != 0)
		@throw [OFInvalidFormatException exception];

	[self setPath: [components componentsJoinedByString: @"/"]];

	objc_autoreleasePoolPop(pool);
}

- (void)setQuery: (OFString *)query
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _URLEncodedQuery;

	_URLEncodedQuery = [[query stringByURLEncodingWithAllowedCharacters:
	    [OFCharacterSet URLQueryAllowedCharacterSet]] copy];

	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)setURLEncodedQuery: (OFString *)URLEncodedQuery
{
	OFString *old;

	if (URLEncodedQuery != nil)
		of_url_verify_escaped(URLEncodedQuery,
		    [OFCharacterSet URLQueryAllowedCharacterSet]);

	old = _URLEncodedQuery;
	_URLEncodedQuery = [URLEncodedQuery copy];
	[old release];
}

- (void)setFragment: (OFString *)fragment
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _URLEncodedFragment;

	_URLEncodedFragment = [[fragment
	    stringByURLEncodingWithAllowedCharacters:
	    [OFCharacterSet URLFragmentAllowedCharacterSet]] copy];

	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)setURLEncodedFragment: (OFString *)URLEncodedFragment
{
	OFString *old;

	if (URLEncodedFragment != nil)
		of_url_verify_escaped(URLEncodedFragment,
		    [OFCharacterSet URLFragmentAllowedCharacterSet]);

	old = _URLEncodedFragment;
	_URLEncodedFragment = [URLEncodedFragment copy];
	[old release];
}

- (id)copy
{
	OFMutableURL *copy = [self mutableCopy];

	[copy makeImmutable];

	return copy;
}

- (void)makeImmutable
{
	object_setClass(self, [OFURL class]);
}
@end
