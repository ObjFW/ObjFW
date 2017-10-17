/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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
#import "OFURL+Private.h"
#import "OFString.h"

@implementation OFMutableURL
@dynamic scheme, host, port, user, password, path, parameters, query, fragment;

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
	OFString *old = _scheme;
	_scheme = [scheme copy];
	[old release];
}

- (void)setHost: (OFString *)host
{
	OFString *old = _host;
	_host = [host copy];
	[old release];
}

- (void)setPort: (uint16_t)port
{
	_port = port;
}

- (void)setUser: (OFString *)user
{
	OFString *old = _user;
	_user = [user copy];
	[old release];
}

- (void)setPassword: (OFString *)password
{
	OFString *old = _password;
	_password = [password copy];
	[old release];
}

- (void)setPath: (OFString *)path
{
	OFString *old = _path;
	_path = [path copy];
	[old release];
}

- (void)setParameters: (OFString *)parameters
{
	OFString *old = _parameters;
	_parameters = [parameters copy];
	[old release];
}

- (void)setQuery: (OFString *)query
{
	OFString *old = _query;
	_query = [query copy];
	[old release];
}

- (void)setFragment: (OFString *)fragment
{
	OFString *old = _fragment;
	_fragment = [fragment copy];
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
