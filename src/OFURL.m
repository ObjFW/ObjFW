/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
 *   Jonathan Schleifer <js@webkeks.org>
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

#include <stdlib.h>
#include <string.h>
#include <assert.h>

#import "OFURL.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFXMLElement.h"
#import "OFAutoreleasePool.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"

#import "macros.h"

static OF_INLINE OFString*
resolve_relative_path(OFString *path)
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFMutableArray *array;
	OFString *ret;
	BOOL done = NO;

	array = [[[path componentsSeparatedByString: @"/"] mutableCopy]
	    autorelease];

	while (!done) {
		id *objects = [array objects];
		size_t i, length = [array count];

		done = YES;

		for (i = 0; i < length; i++) {
			if ([objects[i] isEqual: @"."]) {
				[array removeObjectAtIndex: i];
				done = NO;

				break;
			}

			if ([objects[i] isEqual: @".."]) {
				[array removeObjectAtIndex: i];

				if (i > 0)
					[array removeObjectAtIndex: i - 1];

				done = NO;

				break;
			}
		}
	}

	ret = [[array componentsJoinedByString: @"/"] retain];

	[pool release];

	return [ret autorelease];
}

@implementation OFURL
+ URLWithString: (OFString*)string
{
	return [[[self alloc] initWithString: string] autorelease];
}

+ URLWithString: (OFString*)string
  relativeToURL: (OFURL*)URL
{
	return [[[self alloc] initWithString: string
			       relativeToURL: URL] autorelease];
}

- initWithString: (OFString*)string
{
	char *UTF8String, *UTF8String2 = NULL;

	self = [super init];

	@try {
		char *tmp, *tmp2;

		if ((UTF8String2 = strdup([string UTF8String])) == NULL)
			@throw [OFOutOfMemoryException
			     exceptionWithClass: isa
				  requestedSize: [string UTF8StringLength]];

		UTF8String = UTF8String2;

		if (!strncmp(UTF8String, "file://", 7)) {
			scheme = @"file";
			path = [[OFString alloc]
			    initWithUTF8String: UTF8String + 7];
			return self;
		} else if (!strncmp(UTF8String, "http://", 7)) {
			scheme = @"http";
			UTF8String += 7;
		} else if (!strncmp(UTF8String, "https://", 8)) {
			scheme = @"https";
			UTF8String += 8;
		} else
			@throw [OFInvalidFormatException
			    exceptionWithClass: isa];

		if ((tmp = strchr(UTF8String, '/')) != NULL) {
			*tmp = '\0';
			tmp++;
		}

		if ((tmp2 = strchr(UTF8String, '@')) != NULL) {
			char *tmp3;

			*tmp2 = '\0';
			tmp2++;

			if ((tmp3 = strchr(UTF8String, ':')) != NULL) {
				*tmp3 = '\0';
				tmp3++;

				user = [[OFString alloc]
				    initWithUTF8String: UTF8String];
				password = [[OFString alloc]
				    initWithUTF8String: tmp3];
			} else
				user = [[OFString alloc]
				    initWithUTF8String: UTF8String];

			UTF8String = tmp2;
		}

		if ((tmp2 = strchr(UTF8String, ':')) != NULL) {
			OFAutoreleasePool *pool;
			OFString *portString;

			*tmp2 = '\0';
			tmp2++;

			host = [[OFString alloc]
			    initWithUTF8String: UTF8String];

			pool = [[OFAutoreleasePool alloc] init];
			portString = [OFString stringWithUTF8String: tmp2];

			if ([portString decimalValue] > 65535)
				@throw [OFInvalidFormatException
				    exceptionWithClass: isa];

			port = [portString decimalValue];

			[pool release];
		} else {
			host = [[OFString alloc]
			    initWithUTF8String: UTF8String];

			if ([scheme isEqual: @"http"])
				port = 80;
			else if ([scheme isEqual: @"https"])
				port = 443;
			else
				assert(0);
		}

		if ((UTF8String = tmp) != NULL) {
			if ((tmp = strchr(UTF8String, '#')) != NULL) {
				*tmp = '\0';

				fragment = [[OFString alloc]
				    initWithUTF8String: tmp + 1];
			}

			if ((tmp = strchr(UTF8String, '?')) != NULL) {
				*tmp = '\0';

				query = [[OFString alloc]
				    initWithUTF8String: tmp + 1];
			}

			if ((tmp = strchr(UTF8String, ';')) != NULL) {
				*tmp = '\0';

				parameters = [[OFString alloc]
				    initWithUTF8String: tmp + 1];
			}

			path = [[OFString alloc] initWithFormat: @"/%s",
								 UTF8String];
		} else
			path = @"";
	} @catch (id e) {
		[self release];
		@throw e;
	} @finally {
		free(UTF8String2);
	}

	return self;
}

- initWithString: (OFString*)string
   relativeToURL: (OFURL*)URL
{
	char *UTF8String, *UTF8String2 = NULL;

	if ([string containsString: @"://"])
		return [self initWithString: string];

	self = [super init];

	@try {
		char *tmp;

		scheme = [URL->scheme copy];
		host = [URL->host copy];
		port = URL->port;
		user = [URL->user copy];
		password = [URL->password copy];

		if ((UTF8String2 = strdup([string UTF8String])) == NULL)
			@throw [OFOutOfMemoryException
			     exceptionWithClass: isa
				  requestedSize: [string UTF8StringLength]];

		UTF8String = UTF8String2;

		if ((tmp = strchr(UTF8String, '#')) != NULL) {
			*tmp = '\0';
			fragment = [[OFString alloc]
			    initWithUTF8String: tmp + 1];
		}

		if ((tmp = strchr(UTF8String, '?')) != NULL) {
			*tmp = '\0';
			query = [[OFString alloc] initWithUTF8String: tmp + 1];
		}

		if ((tmp = strchr(UTF8String, ';')) != NULL) {
			*tmp = '\0';
			parameters = [[OFString alloc]
			    initWithUTF8String: tmp + 1];
		}

		if (*UTF8String == '/')
			path = [[OFString alloc]
			    initWithUTF8String: UTF8String];
		else {
			OFAutoreleasePool *pool;
			OFString *s;

			pool = [[OFAutoreleasePool alloc] init];

			if ([URL->path hasSuffix: @"/"])
				s = [OFString stringWithFormat: @"%@%s",
								URL->path,
								UTF8String];
			else
				s = [OFString stringWithFormat: @"%@/../%s",
								URL->path,
								UTF8String];

			path = [resolve_relative_path(s) copy];

			[pool release];
		}
	} @catch (id e) {
		[self release];
		@throw e;
	} @finally {
		free(UTF8String2);
	}

	return self;
}

- initWithSerialization: (OFXMLElement*)element
{
	@try {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

		if (![[element name] isEqual: [self className]] ||
		    ![[element namespace] isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException
			    exceptionWithClass: isa
				      selector: _cmd];

		self = [self initWithString: [element stringValue]];

		[pool release];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[scheme release];
	[host release];
	[user release];
	[password release];
	[path release];
	[parameters release];
	[query release];
	[fragment release];

	[super dealloc];
}

- (BOOL)isEqual: (id)object
{
	OFURL *otherURL;

	if (![object isKindOfClass: [OFURL class]])
		return NO;

	otherURL = object;

	if (![otherURL->scheme isEqual: scheme])
		return NO;
	if (![otherURL->host isEqual: host])
		return NO;
	if (otherURL->port != port)
		return NO;
	if (otherURL->user != user && ![otherURL->user isEqual: user])
		return NO;
	if (otherURL->password != password &&
	    ![otherURL->password isEqual: password])
		return NO;
	if (![otherURL->path isEqual: path])
		return NO;
	if (otherURL->parameters != parameters &&
	    ![otherURL->parameters isEqual: parameters])
		return NO;
	if (otherURL->query != query &&
	    ![otherURL->query isEqual: query])
		return NO;
	if (otherURL->fragment != fragment &&
	    ![otherURL->fragment isEqual: fragment])
		return NO;

	return YES;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, [scheme hash]);
	OF_HASH_ADD_HASH(hash, [host hash]);
	OF_HASH_ADD(hash, (port & 0xFF00) >> 8);
	OF_HASH_ADD(hash, port & 0xFF);
	OF_HASH_ADD_HASH(hash, [user hash]);
	OF_HASH_ADD_HASH(hash, [password hash]);
	OF_HASH_ADD_HASH(hash, [path hash]);
	OF_HASH_ADD_HASH(hash, [parameters hash]);
	OF_HASH_ADD_HASH(hash, [query hash]);
	OF_HASH_ADD_HASH(hash, [fragment hash]);

	OF_HASH_FINALIZE(hash);

	return hash;
}

- copy
{
	OFURL *copy = [[isa alloc] init];

	@try {
		copy->scheme = [scheme copy];
		copy->host = [host copy];
		copy->port = port;
		copy->user = [user copy];
		copy->password = [password copy];
		copy->path = [path copy];
		copy->parameters = [parameters copy];
		copy->query = [query copy];
		copy->fragment = [fragment copy];
	} @catch (id e) {
		[copy release];
		@throw e;
	}

	return copy;
}

- (OFString*)scheme
{
	OF_GETTER(scheme, YES)
}

- (void)setScheme: (OFString*)scheme_
{
	if (![scheme_ isEqual: @"http"] && ![scheme_ isEqual: @"https"])
		@throw [OFInvalidArgumentException exceptionWithClass: isa
							     selector: _cmd];

	OF_SETTER(scheme, scheme_, YES, YES)
}

- (OFString*)host
{
	OF_GETTER(host, YES)
}

- (void)setHost: (OFString*)host_
{
	OF_SETTER(host, host_, YES, YES)
}

- (uint16_t)port
{
	return port;
}

- (void)setPort: (uint16_t)port_
{
	port = port_;
}

- (OFString*)user
{
	OF_GETTER(user, YES)
}

- (void)setUser: (OFString*)user_
{
	OF_SETTER(user, user_, YES, YES)
}

- (OFString*)password
{
	OF_GETTER(password, YES)
}

- (void)setPassword: (OFString*)password_
{
	OF_SETTER(password, password_, YES, YES)
}

- (OFString*)path
{
	OF_GETTER(path, YES)
}

- (void)setPath: (OFString*)path_
{
	if (([scheme isEqual: @"http"] || [scheme isEqual: @"https"]) &&
	    ![path_ hasPrefix: @"/"])
		@throw [OFInvalidArgumentException exceptionWithClass: isa
							     selector: _cmd];

	OF_SETTER(path, path_, YES, YES)
}

- (OFString*)parameters
{
	OF_GETTER(parameters, YES)
}

- (void)setParameters: (OFString*)parameters_
{
	OF_SETTER(parameters, parameters_, YES, YES)
}

- (OFString*)query
{
	OF_GETTER(query, YES)
}

- (void)setQuery: (OFString*)query_
{
	OF_SETTER(query, query_, YES, YES)
}

- (OFString*)fragment
{
	OF_GETTER(fragment, YES)
}

- (void)setFragment: (OFString*)fragment_
{
	OF_SETTER(fragment, fragment_, YES, YES)
}

- (OFString*)string
{
	OFMutableString *ret = [OFMutableString stringWithFormat: @"%@://",
								  scheme];
	BOOL needPort = YES;

	if ([scheme isEqual: @"file"]) {
		[ret appendString: path];
		return ret;
	}

	if (user != nil && password != nil)
		[ret appendFormat: @"%@:%@@", user, password];
	else if (user != nil)
		[ret appendFormat: @"%@@", user];

	[ret appendString: host];

	if (([scheme isEqual: @"http"] && port == 80) ||
	    ([scheme isEqual: @"https"] && port == 443))
		needPort = NO;

	if (needPort)
		[ret appendFormat: @":%d", port];

	[ret appendString: path];

	if (parameters != nil)
		[ret appendFormat: @";%@", parameters];

	if (query != nil)
		[ret appendFormat: @"?%@", query];

	if (fragment != nil)
		[ret appendFormat: @"#%@", fragment];

	[ret makeImmutable];

	return ret;
}

- (OFString*)description
{
	return [self string];
}

- (OFXMLElement*)XMLElementBySerializing
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFXMLElement *element;

	element = [OFXMLElement elementWithName: [self className]
				      namespace: OF_SERIALIZATION_NS
				    stringValue: [self string]];

	[element retain];
	[pool release];
	[element autorelease];

	return element;
}
@end
