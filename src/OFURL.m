/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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
#include <ctype.h>

#import "OFURL.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFXMLElement.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"

@implementation OFURL
+ (instancetype)URL
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)URLWithString: (OFString*)string
{
	return [[[self alloc] initWithString: string] autorelease];
}

+ (instancetype)URLWithString: (OFString*)string
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
		void *pool = objc_autoreleasePoolPush();
		char *tmp, *tmp2;

		if ((UTF8String2 = of_strdup([string UTF8String])) == NULL)
			@throw [OFOutOfMemoryException
			     exceptionWithRequestedSize:
			     [string UTF8StringLength]];

		UTF8String = UTF8String2;

		if ((tmp = strstr(UTF8String, "://")) == NULL)
			@throw [OFInvalidFormatException exception];

		for (tmp2 = UTF8String; tmp2 < tmp; tmp2++)
			*tmp2 = tolower((int)*tmp2);

		_scheme = [[[OFString stringWithUTF8String: UTF8String
						    length: tmp - UTF8String]
		    stringByURLDecoding] copy];

		UTF8String = tmp + 3;

		if ([_scheme isEqual: @"file"]) {
			_path = [[[OFString stringWithUTF8String:
			    UTF8String] stringByURLDecoding] copy];

			objc_autoreleasePoolPop(pool);
			return self;
		}

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

				_user = [[[OFString stringWithUTF8String:
				    UTF8String] stringByURLDecoding] copy];
				_password = [[[OFString stringWithUTF8String:
				    tmp3] stringByURLDecoding] copy];
			} else
				_user = [[[OFString stringWithUTF8String:
				    UTF8String] stringByURLDecoding] copy];

			UTF8String = tmp2;
		}

		if ((tmp2 = strchr(UTF8String, ':')) != NULL) {
			void *pool;
			OFString *portString;

			*tmp2 = '\0';
			tmp2++;

			_host = [[[OFString stringWithUTF8String:
			    UTF8String] stringByURLDecoding] copy];

			pool = objc_autoreleasePoolPush();
			portString = [OFString stringWithUTF8String: tmp2];

			if ([portString decimalValue] > 65535)
				@throw [OFInvalidFormatException exception];

			_port = [portString decimalValue];

			objc_autoreleasePoolPop(pool);
		} else {
			_host = [[[OFString stringWithUTF8String:
			    UTF8String] stringByURLDecoding] copy];

			if ([_scheme isEqual: @"http"])
				_port = 80;
			else if ([_scheme isEqual: @"https"])
				_port = 443;
			else if ([_scheme isEqual: @"ftp"])
				_port = 21;
		}

		if ((UTF8String = tmp) != NULL) {
			if ((tmp = strchr(UTF8String, '#')) != NULL) {
				*tmp = '\0';

				_fragment = [[[OFString stringWithUTF8String:
				    tmp + 1] stringByURLDecoding] copy];
			}

			if ((tmp = strchr(UTF8String, '?')) != NULL) {
				*tmp = '\0';

				_query = [[[OFString stringWithUTF8String:
				    tmp + 1] stringByURLDecoding] copy];
			}

			if ((tmp = strchr(UTF8String, ';')) != NULL) {
				*tmp = '\0';

				_parameters = [[[OFString stringWithUTF8String:
				    tmp + 1] stringByURLDecoding] copy];
			}

			_path = [[[OFString stringWithUTF8String:
			    UTF8String] stringByURLDecoding] copy];
		}

		objc_autoreleasePoolPop(pool);
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
		void *pool = objc_autoreleasePoolPush();
		char *tmp;

		_scheme = [URL->_scheme copy];
		_host = [URL->_host copy];
		_port = URL->_port;
		_user = [URL->_user copy];
		_password = [URL->_password copy];

		if ((UTF8String2 = of_strdup([string UTF8String])) == NULL)
			@throw [OFOutOfMemoryException
			     exceptionWithRequestedSize:
			     [string UTF8StringLength]];

		UTF8String = UTF8String2;

		if ((tmp = strchr(UTF8String, '#')) != NULL) {
			*tmp = '\0';
			_fragment = [[[OFString stringWithUTF8String:
			    tmp + 1] stringByURLDecoding] copy];
		}

		if ((tmp = strchr(UTF8String, '?')) != NULL) {
			*tmp = '\0';
			_query = [[[OFString stringWithUTF8String:
			    tmp + 1] stringByURLDecoding] copy];
		}

		if ((tmp = strchr(UTF8String, ';')) != NULL) {
			*tmp = '\0';
			_parameters = [[[OFString stringWithUTF8String:
			    tmp + 1] stringByURLDecoding] copy];
		}

		if (*UTF8String == '/')
			_path = [[[OFString stringWithUTF8String:
			    UTF8String + 1] stringByURLDecoding] copy];
		else {
			OFString *path, *s;

			path = [[[OFString stringWithUTF8String:
			    UTF8String] stringByURLDecoding] copy];

			if ([URL->_path hasSuffix: @"/"])
				s = [URL->_path stringByAppendingString: path];
			else
				s = [OFString stringWithFormat: @"%@/../%@",
								URL->_path,
								path];

			_path = [[s stringByStandardizingURLPath] copy];
		}

		objc_autoreleasePoolPop(pool);
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
		void *pool = objc_autoreleasePoolPush();

		if (![[element name] isEqual: [self className]] ||
		    ![[element namespace] isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException exception];

		self = [self initWithString: [element stringValue]];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_scheme release];
	[_host release];
	[_user release];
	[_password release];
	[_path release];
	[_parameters release];
	[_query release];
	[_fragment release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFURL *URL;

	if (![object isKindOfClass: [OFURL class]])
		return false;

	URL = object;

	if (![URL->_scheme isEqual: _scheme])
		return false;
	if (![URL->_host isEqual: _host])
		return false;
	if (URL->_port != _port)
		return false;
	if (URL->_user != _user && ![URL->_user isEqual: _user])
		return false;
	if (URL->_password != _password &&
	    ![URL->_password isEqual: _password])
		return false;
	if (![URL->_path isEqual: _path])
		return false;
	if (URL->_parameters != _parameters &&
	    ![URL->_parameters isEqual: _parameters])
		return false;
	if (URL->_query != _query &&
	    ![URL->_query isEqual: _query])
		return false;
	if (URL->_fragment != _fragment &&
	    ![URL->_fragment isEqual: _fragment])
		return false;

	return true;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, [_scheme hash]);
	OF_HASH_ADD_HASH(hash, [_host hash]);
	OF_HASH_ADD(hash, (_port & 0xFF00) >> 8);
	OF_HASH_ADD(hash, _port & 0xFF);
	OF_HASH_ADD_HASH(hash, [_user hash]);
	OF_HASH_ADD_HASH(hash, [_password hash]);
	OF_HASH_ADD_HASH(hash, [_path hash]);
	OF_HASH_ADD_HASH(hash, [_parameters hash]);
	OF_HASH_ADD_HASH(hash, [_query hash]);
	OF_HASH_ADD_HASH(hash, [_fragment hash]);

	OF_HASH_FINALIZE(hash);

	return hash;
}

- copy
{
	OFURL *copy = [[[self class] alloc] init];

	@try {
		copy->_scheme = [_scheme copy];
		copy->_host = [_host copy];
		copy->_port = _port;
		copy->_user = [_user copy];
		copy->_password = [_password copy];
		copy->_path = [_path copy];
		copy->_parameters = [_parameters copy];
		copy->_query = [_query copy];
		copy->_fragment = [_fragment copy];
	} @catch (id e) {
		[copy release];
		@throw e;
	}

	return copy;
}

- (OFString*)scheme
{
	OF_GETTER(_scheme, true)
}

- (void)setScheme: (OFString*)scheme
{
	OF_SETTER(_scheme, scheme, true, 1)
}

- (OFString*)host
{
	OF_GETTER(_host, true)
}

- (void)setHost: (OFString*)host
{
	OF_SETTER(_host, host, true, 1)
}

- (uint16_t)port
{
	return _port;
}

- (void)setPort: (uint16_t)port
{
	_port = port;
}

- (OFString*)user
{
	OF_GETTER(_user, true)
}

- (void)setUser: (OFString*)user
{
	OF_SETTER(_user, user, true, 1)
}

- (OFString*)password
{
	OF_GETTER(_password, true)
}

- (void)setPassword: (OFString*)password
{
	OF_SETTER(_password, password, true, 1)
}

- (OFString*)path
{
	OF_GETTER(_path, true)
}

- (void)setPath: (OFString*)path
{
	OF_SETTER(_path, path, true, 1)
}

- (OFString*)parameters
{
	OF_GETTER(_parameters, true)
}

- (void)setParameters: (OFString*)parameters
{
	OF_SETTER(_parameters, parameters, true, 1)
}

- (OFString*)query
{
	OF_GETTER(_query, true)
}

- (void)setQuery: (OFString*)query
{
	OF_SETTER(_query, query, true, 1)
}

- (OFString*)fragment
{
	OF_GETTER(_fragment, true)
}

- (void)setFragment: (OFString*)fragment
{
	OF_SETTER(_fragment, fragment, true, 1)
}

- (OFString*)string
{
	OFMutableString *ret = [OFMutableString string];
	void *pool = objc_autoreleasePoolPush();

	[ret appendFormat: @"%@://", [_scheme stringByURLEncoding]];

	if ([_scheme isEqual: @"file"]) {
		if (_path != nil)
			[ret appendString: [_path
			    stringByURLEncodingWithIgnoredCharacters: "/"]];

		objc_autoreleasePoolPop(pool);
		return ret;
	}

	if (_user != nil && _password != nil)
		[ret appendFormat: @"%@:%@@",
				   [_user stringByURLEncoding],
				   [_password stringByURLEncoding]];
	else if (_user != nil)
		[ret appendFormat: @"%@@", [_user stringByURLEncoding]];

	if (_host != nil)
		[ret appendString: [_host stringByURLEncoding]];

	if (!(([_scheme isEqual: @"http"] && _port == 80) ||
	    ([_scheme isEqual: @"https"] && _port == 443) ||
	    ([_scheme isEqual: @"ftp"] && _port == 21)))
		[ret appendFormat: @":%u", _port];

	if (_path != nil)
		[ret appendFormat: @"/%@",
		    [_path stringByURLEncodingWithIgnoredCharacters: "/"]];

	if (_parameters != nil)
		[ret appendFormat: @";%@", [_parameters stringByURLEncoding]];

	if (_query != nil)
		[ret appendFormat: @"?%@", [_query stringByURLEncoding]];

	if (_fragment != nil)
		[ret appendFormat: @"#%@", [_fragment stringByURLEncoding]];

	objc_autoreleasePoolPop(pool);

	[ret makeImmutable];

	return ret;
}

- (OFString*)description
{
	return [OFString stringWithFormat: @"<%@: %@>",
					   [self class], [self string]];
}

- (OFXMLElement*)XMLElementBySerializing
{
	void *pool = objc_autoreleasePoolPush();
	OFXMLElement *element;

	element = [OFXMLElement elementWithName: [self className]
				      namespace: OF_SERIALIZATION_NS
				    stringValue: [self string]];

	[element retain];

	objc_autoreleasePoolPop(pool);

	return [element autorelease];
}
@end
