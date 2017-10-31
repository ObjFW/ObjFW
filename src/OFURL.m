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

#include <stdlib.h>
#include <string.h>

#import "OFURL.h"
#import "OFURL+Private.h"
#import "OFArray.h"
#ifdef OF_HAVE_FILES
# import "OFFileManager.h"
#endif
#import "OFNumber.h"
#import "OFString.h"
#import "OFXMLElement.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"

@implementation OFURL
+ (instancetype)URL
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)URLWithString: (OFString *)string
{
	return [[[self alloc] initWithString: string] autorelease];
}

+ (instancetype)URLWithString: (OFString *)string
		relativeToURL: (OFURL *)URL
{
	return [[[self alloc] initWithString: string
			       relativeToURL: URL] autorelease];
}

#ifdef OF_HAVE_FILES
+ (instancetype)fileURLWithPath: (OFString *)path
{
	return [[[self alloc] initFileURLWithPath: path] autorelease];
}

+ (instancetype)fileURLWithPath: (OFString *)path
		    isDirectory: (bool)isDirectory
{
	return [[[self alloc] initFileURLWithPath: path
				      isDirectory: isDirectory] autorelease];
}
#endif

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_init
{
	return [super init];
}

- (instancetype)initWithString: (OFString *)string
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

		if ((tmp = strchr(UTF8String, ':')) == NULL)
			@throw [OFInvalidFormatException exception];

		if (strncmp(tmp, "://", 3) != 0)
			@throw [OFInvalidFormatException exception];

		for (tmp2 = UTF8String; tmp2 < tmp; tmp2++)
			*tmp2 = of_ascii_tolower(*tmp2);

		_scheme = [[[OFString stringWithUTF8String: UTF8String
						    length: tmp - UTF8String]
		    stringByURLDecoding] copy];

		UTF8String = tmp + 3;

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
			void *pool2;
			OFString *portString;

			*tmp2 = '\0';
			tmp2++;

			_host = [[[OFString stringWithUTF8String: UTF8String]
			    stringByURLDecoding] copy];

			pool2 = objc_autoreleasePoolPush();
			portString = [OFString stringWithUTF8String: tmp2];

			if ([portString decimalValue] > 65535)
				@throw [OFInvalidFormatException exception];

			_port = [[OFNumber alloc] initWithUInt16:
			    (uint16_t)[portString decimalValue]];

			objc_autoreleasePoolPop(pool2);
		} else
			_host = [[[OFString stringWithUTF8String: UTF8String]
			    stringByURLDecoding] copy];

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

			UTF8String--;
			*UTF8String = '/';

			_path = [[[OFString stringWithUTF8String: UTF8String]
			    stringByURLDecoding] copy];
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

- (instancetype)initWithString: (OFString *)string
		 relativeToURL: (OFURL *)URL
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
		_port = [URL->_port copy];
		_user = [URL->_user copy];
		_password = [URL->_password copy];

		if ((UTF8String2 = of_strdup([string UTF8String])) == NULL)
			@throw [OFOutOfMemoryException
			     exceptionWithRequestedSize:
			     [string UTF8StringLength]];

		UTF8String = UTF8String2;

		if ((tmp = strchr(UTF8String, '#')) != NULL) {
			*tmp = '\0';
			_fragment = [[[OFString stringWithUTF8String: tmp + 1]
			    stringByURLDecoding] copy];
		}

		if ((tmp = strchr(UTF8String, '?')) != NULL) {
			*tmp = '\0';
			_query = [[[OFString stringWithUTF8String: tmp + 1]
			    stringByURLDecoding] copy];
		}

		if (*UTF8String == '/')
			_path = [[[OFString stringWithUTF8String: UTF8String]
			    stringByURLDecoding] copy];
		else {
			OFString *path, *s;

			path = [[OFString stringWithUTF8String: UTF8String]
			    stringByURLDecoding];

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

#ifdef OF_HAVE_FILES
- (instancetype)initFileURLWithPath: (OFString *)path
{
	@try {
		void *pool = objc_autoreleasePoolPush();
		OFFileManager *fileManager = [OFFileManager defaultManager];
		bool isDirectory;

		isDirectory = ([path hasSuffix: OF_PATH_DELIMITER_STRING] ||
		    [fileManager directoryExistsAtPath: path]);
		self = [self initFileURLWithPath: path
				     isDirectory: isDirectory];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initFileURLWithPath: (OFString *)path
			isDirectory: (bool)isDirectory
{
	@try {
		void *pool = objc_autoreleasePoolPush();
		OFURL *currentDirectoryURL;

# if OF_PATH_DELIMITER != '/'
		path = [[path pathComponents] componentsJoinedByString: @"/"];
# endif

		if (isDirectory && ![path hasSuffix: OF_PATH_DELIMITER_STRING])
			path = [path stringByAppendingString: @"/"];

		currentDirectoryURL =
		    [[OFFileManager defaultManager] currentDirectoryURL];

		self = [self initWithString: path
			      relativeToURL: currentDirectoryURL];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}
#endif

- (instancetype)initWithSerialization: (OFXMLElement *)element
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
	[_port release];
	[_user release];
	[_password release];
	[_path release];
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

	if (URL->_scheme != _scheme && ![URL->_scheme isEqual: _scheme])
		return false;
	if (URL->_host != _host && ![URL->_host isEqual: _host])
		return false;
	if (URL->_port != _port && ![URL->_port isEqual: _port])
		return false;
	if (URL->_user != _user && ![URL->_user isEqual: _user])
		return false;
	if (URL->_password != _password && ![URL->_password isEqual: _password])
		return false;
	if (URL->_path != _path && ![URL->_path isEqual: _path])
		return false;
	if (URL->_query != _query && ![URL->_query isEqual: _query])
		return false;
	if (URL->_fragment != _fragment && ![URL->_fragment isEqual: _fragment])
		return false;

	return true;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, [_scheme hash]);
	OF_HASH_ADD_HASH(hash, [_host hash]);
	OF_HASH_ADD_HASH(hash, [_port hash]);
	OF_HASH_ADD_HASH(hash, [_user hash]);
	OF_HASH_ADD_HASH(hash, [_password hash]);
	OF_HASH_ADD_HASH(hash, [_path hash]);
	OF_HASH_ADD_HASH(hash, [_query hash]);
	OF_HASH_ADD_HASH(hash, [_fragment hash]);

	OF_HASH_FINALIZE(hash);

	return hash;
}

- (OFString *)scheme
{
	return _scheme;
}

- (OFString *)host
{
	return _host;
}

- (OFNumber *)port
{
	return _port;
}

- (OFString *)user
{
	return _user;
}

- (OFString *)password
{
	return _password;
}

- (OFString *)path
{
	return _path;
}

- (OFArray *)pathComponents
{
	return [_path componentsSeparatedByString: @"/"];
}

- (OFString *)lastPathComponent
{
	void *pool;
	OFString *path;
	const char *UTF8String, *lastComponent;
	size_t length;
	OFString *ret;

	if (_path == nil)
		return nil;

	if ([_path isEqual: @"/"])
		return @"";

	pool = objc_autoreleasePoolPush();
	path = _path;

	if ([path hasSuffix: @"/"])
		path = [path substringWithRange:
		    of_range(0, [path length] - 1)];

	UTF8String = lastComponent = [path UTF8String];
	length = [path UTF8StringLength];

	for (size_t i = 1; i <= length; i++) {
		if (UTF8String[length - i] == '/') {
			lastComponent = UTF8String + (length - i) + 1;
			break;
		}
	}

	ret = [[OFString alloc]
	    initWithUTF8String: lastComponent
			length: length - (lastComponent - UTF8String)];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (OFString *)query
{
	return _query;
}

- (OFString *)fragment
{
	return _fragment;
}

- (id)copy
{
	return [self retain];
}

- (id)mutableCopy
{
	OFMutableURL *copy = [[OFMutableURL alloc] init];

	@try {
		[copy setScheme: _scheme];
		[copy setHost: _host];
		[copy setPort: _port];
		[copy setUser: _user];
		[copy setPassword: _password];
		[copy setPath: _path];
		[copy setQuery: _query];
		[copy setFragment: _fragment];
	} @catch (id e) {
		[copy release];
		@throw e;
	}

	return copy;
}

- (OFString *)string
{
	OFMutableString *ret = [OFMutableString string];
	void *pool = objc_autoreleasePoolPush();

	[ret appendFormat: @"%@://", [_scheme stringByURLEncoding]];

	if (_user != nil && _password != nil)
		[ret appendFormat: @"%@:%@@",
				   [_user stringByURLEncoding],
				   [_password stringByURLEncoding]];
	else if (_user != nil)
		[ret appendFormat: @"%@@", [_user stringByURLEncoding]];

	if (_host != nil)
		[ret appendString: [_host stringByURLEncoding]];
	if (_port != nil)
		[ret appendFormat: @":%@", _port];

	if (_path != nil) {
		if (![_path hasPrefix: @"/"])
			@throw [OFInvalidFormatException exception];

		[ret appendString: [_path
		    stringByURLEncodingWithAllowedCharacters:
		    "-._~!$&'()*+,;=:@/"]];
	}

	if (_query != nil)
		[ret appendFormat: @"?%@",
		    [_query stringByURLEncodingWithAllowedCharacters:
		    "-._~!$&'()*+,;=:@/?"]];

	if (_fragment != nil)
		[ret appendFormat: @"#%@",
		    [_fragment stringByURLEncodingWithAllowedCharacters:
		    "-._~!$&'()*+,;=:@/?"]];

	objc_autoreleasePoolPop(pool);

	[ret makeImmutable];

	return ret;
}

- (OFString *)fileSystemRepresentation
{
	void *pool = objc_autoreleasePoolPush();
	OFString *path;

	if (![_scheme isEqual: @"file"])
		@throw [OFInvalidArgumentException exception];

	if (![_path hasPrefix: @"/"])
		@throw [OFInvalidFormatException exception];

	path = _path;

	if ([path hasSuffix: @"/"])
		path = [path substringWithRange:
		    of_range(0, [path length] - 1)];

#ifndef OF_PATH_STARTS_WITH_SLASH
	path = [path substringWithRange: of_range(1, [path length] - 1)];
#endif

#if OF_PATH_DELIMITER != '/'
	path = [OFString pathWithComponents:
	    [path componentsSeparatedByString: @"/"]];
#endif

	[path retain];

	objc_autoreleasePoolPop(pool);

	return [path autorelease];
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<%@: %@>",
					   [self class], [self string]];
}

- (OFXMLElement *)XMLElementBySerializing
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
