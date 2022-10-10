/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#import "OFURI.h"
#import "OFArray.h"
#import "OFDictionary.h"
#ifdef OF_HAVE_FILES
# import "OFFileManager.h"
# import "OFFileURIHandler.h"
#endif
#import "OFNumber.h"
#import "OFOnce.h"
#import "OFPair.h"
#import "OFString.h"
#import "OFXMLElement.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"

@interface OFURIAllowedCharacterSetBase: OFCharacterSet
@end

@interface OFURIAllowedCharacterSet: OFURIAllowedCharacterSetBase
@end

@interface OFURISchemeAllowedCharacterSet: OFURIAllowedCharacterSetBase
@end

@interface OFURIPathAllowedCharacterSet: OFURIAllowedCharacterSetBase
@end

@interface OFURIQueryOrFragmentAllowedCharacterSet: OFURIAllowedCharacterSetBase
@end

@interface OFURIQueryKeyValueAllowedCharacterSet: OFURIAllowedCharacterSetBase
@end

OF_DIRECT_MEMBERS
@interface OFInvertedCharacterSetWithoutPercent: OFCharacterSet
{
	OFCharacterSet *_characterSet;
	bool (*_characterIsMember)(id, SEL, OFUnichar);
}

- (instancetype)initWithCharacterSet: (OFCharacterSet *)characterSet;
@end

static OFCharacterSet *URIAllowedCharacterSet = nil;
static OFCharacterSet *URISchemeAllowedCharacterSet = nil;
static OFCharacterSet *URIPathAllowedCharacterSet = nil;
static OFCharacterSet *URIQueryOrFragmentAllowedCharacterSet = nil;
static OFCharacterSet *URIQueryKeyValueAllowedCharacterSet = nil;

static OFOnceControl URIAllowedCharacterSetOnce = OFOnceControlInitValue;
static OFOnceControl URIQueryOrFragmentAllowedCharacterSetOnce =
    OFOnceControlInitValue;

static void
initURIAllowedCharacterSet(void)
{
	URIAllowedCharacterSet = [[OFURIAllowedCharacterSet alloc] init];
}

static void
initURISchemeAllowedCharacterSet(void)
{
	URISchemeAllowedCharacterSet =
	    [[OFURISchemeAllowedCharacterSet alloc] init];
}

static void
initURIPathAllowedCharacterSet(void)
{
	URIPathAllowedCharacterSet =
	    [[OFURIPathAllowedCharacterSet alloc] init];
}

static void
initURIQueryOrFragmentAllowedCharacterSet(void)
{
	URIQueryOrFragmentAllowedCharacterSet =
	    [[OFURIQueryOrFragmentAllowedCharacterSet alloc] init];
}

static void
initURIQueryKeyValueAllowedCharacterSet(void)
{
	URIQueryKeyValueAllowedCharacterSet =
	    [[OFURIQueryKeyValueAllowedCharacterSet alloc] init];
}

bool
OFURIIsIPv6Host(OFString *host)
{
	const char *UTF8String = host.UTF8String;
	bool hasColon = false;

	while (*UTF8String != '\0') {
		if (!OFASCIIIsDigit(*UTF8String) && *UTF8String != ':' &&
		    (*UTF8String < 'a' || *UTF8String > 'f') &&
		    (*UTF8String < 'A' || *UTF8String > 'F'))
			return false;

		if (*UTF8String == ':')
			hasColon = true;

		UTF8String++;
	}

	return hasColon;
}

@implementation OFURIAllowedCharacterSetBase
- (instancetype)autorelease
{
	return self;
}

- (instancetype)retain
{
	return self;
}

- (void)release
{
}

- (unsigned int)retainCount
{
	return OFMaxRetainCount;
}
@end

@implementation OFURIAllowedCharacterSet
- (bool)characterIsMember: (OFUnichar)character
{
	if (character < CHAR_MAX && OFASCIIIsAlnum(character))
		return true;

	switch (character) {
	case '-':
	case '.':
	case '_':
	case '~':
	case '!':
	case '$':
	case '&':
	case '\'':
	case '(':
	case ')':
	case '*':
	case '+':
	case ',':
	case ';':
	case '=':
		return true;
	default:
		return false;
	}
}
@end

@implementation OFURISchemeAllowedCharacterSet
- (bool)characterIsMember: (OFUnichar)character
{
	if (character < CHAR_MAX && OFASCIIIsAlnum(character))
		return true;

	switch (character) {
	case '+':
	case '-':
	case '.':
		return true;
	default:
		return false;
	}
}
@end

@implementation OFURIPathAllowedCharacterSet
- (bool)characterIsMember: (OFUnichar)character
{
	if (character < CHAR_MAX && OFASCIIIsAlnum(character))
		return true;

	switch (character) {
	case '-':
	case '.':
	case '_':
	case '~':
	case '!':
	case '$':
	case '&':
	case '\'':
	case '(':
	case ')':
	case '*':
	case '+':
	case ',':
	case ';':
	case '=':
	case ':':
	case '@':
	case '/':
		return true;
	default:
		return false;
	}
}
@end

@implementation OFURIQueryOrFragmentAllowedCharacterSet
- (bool)characterIsMember: (OFUnichar)character
{
	if (character < CHAR_MAX && OFASCIIIsAlnum(character))
		return true;

	switch (character) {
	case '-':
	case '.':
	case '_':
	case '~':
	case '!':
	case '$':
	case '&':
	case '\'':
	case '(':
	case ')':
	case '*':
	case '+':
	case ',':
	case ';':
	case '=':
	case ':':
	case '@':
	case '/':
	case '?':
		return true;
	default:
		return false;
	}
}
@end

@implementation OFURIQueryKeyValueAllowedCharacterSet
- (bool)characterIsMember: (OFUnichar)character
{
	if (character < CHAR_MAX && OFASCIIIsAlnum(character))
		return true;

	switch (character) {
	case '-':
	case '.':
	case '_':
	case '~':
	case '!':
	case '$':
	case '\'':
	case '(':
	case ')':
	case '*':
	case '+':
	case ',':
	case ';':
	case ':':
	case '@':
	case '/':
	case '?':
		return true;
	default:
		return false;
	}
}
@end

@implementation OFInvertedCharacterSetWithoutPercent
- (instancetype)initWithCharacterSet: (OFCharacterSet *)characterSet
{
	self = [super init];

	@try {
		_characterSet = [characterSet retain];
		_characterIsMember = (bool (*)(id, SEL, OFUnichar))
		    [_characterSet methodForSelector:
		    @selector(characterIsMember:)];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_characterSet release];

	[super dealloc];
}

- (bool)characterIsMember: (OFUnichar)character
{
	return (character != '%' && !_characterIsMember(_characterSet,
	    @selector(characterIsMember:), character));
}
@end

void
OFURIVerifyIsEscaped(OFString *string, OFCharacterSet *characterSet)
{
	void *pool = objc_autoreleasePoolPush();

	characterSet = [[[OFInvertedCharacterSetWithoutPercent alloc]
	    initWithCharacterSet: characterSet] autorelease];

	if ([string indexOfCharacterFromSet: characterSet] != OFNotFound)
		@throw [OFInvalidFormatException exception];

	objc_autoreleasePoolPop(pool);
}

@implementation OFCharacterSet (URICharacterSets)
+ (OFCharacterSet *)URISchemeAllowedCharacterSet
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, initURISchemeAllowedCharacterSet);

	return URISchemeAllowedCharacterSet;
}

+ (OFCharacterSet *)URIHostAllowedCharacterSet
{
	OFOnce(&URIAllowedCharacterSetOnce, initURIAllowedCharacterSet);

	return URIAllowedCharacterSet;
}

+ (OFCharacterSet *)URIUserAllowedCharacterSet
{
	OFOnce(&URIAllowedCharacterSetOnce, initURIAllowedCharacterSet);

	return URIAllowedCharacterSet;
}

+ (OFCharacterSet *)URIPasswordAllowedCharacterSet
{
	OFOnce(&URIAllowedCharacterSetOnce, initURIAllowedCharacterSet);

	return URIAllowedCharacterSet;
}

+ (OFCharacterSet *)URIPathAllowedCharacterSet
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, initURIPathAllowedCharacterSet);

	return URIPathAllowedCharacterSet;
}

+ (OFCharacterSet *)URIQueryAllowedCharacterSet
{
	OFOnce(&URIQueryOrFragmentAllowedCharacterSetOnce,
	    initURIQueryOrFragmentAllowedCharacterSet);

	return URIQueryOrFragmentAllowedCharacterSet;
}

+ (OFCharacterSet *)URIQueryKeyValueAllowedCharacterSet
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, initURIQueryKeyValueAllowedCharacterSet);

	return URIQueryKeyValueAllowedCharacterSet;
}

+ (OFCharacterSet *)URIFragmentAllowedCharacterSet
{
	OFOnce(&URIQueryOrFragmentAllowedCharacterSetOnce,
	    initURIQueryOrFragmentAllowedCharacterSet);

	return URIQueryOrFragmentAllowedCharacterSet;
}
@end

@implementation OFURI
+ (instancetype)URI
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)URIWithString: (OFString *)string
{
	return [[[self alloc] initWithString: string] autorelease];
}

+ (instancetype)URIWithString: (OFString *)string
		relativeToURI: (OFURI *)URI
{
	return [[[self alloc] initWithString: string
			       relativeToURI: URI] autorelease];
}

#ifdef OF_HAVE_FILES
+ (instancetype)fileURIWithPath: (OFString *)path
{
	return [[[self alloc] initFileURIWithPath: path] autorelease];
}

+ (instancetype)fileURIWithPath: (OFString *)path
		    isDirectory: (bool)isDirectory
{
	return [[[self alloc] initFileURIWithPath: path
				      isDirectory: isDirectory] autorelease];
}
#endif

static void
parseUserInfo(OFURI *self, const char *UTF8String, size_t length)
{
	const char *colon;

	if ((colon = memchr(UTF8String, ':', length)) != NULL) {
		self->_percentEncodedUser = [[OFString alloc]
		    initWithUTF8String: UTF8String
				length: colon - UTF8String];
		self->_percentEncodedPassword = [[OFString alloc]
		    initWithUTF8String: colon + 1
				length: length - (colon - UTF8String) - 1];

		OFURIVerifyIsEscaped(self->_percentEncodedPassword,
		    [OFCharacterSet URIPasswordAllowedCharacterSet]);
	} else
		self->_percentEncodedUser = [[OFString alloc]
		    initWithUTF8String: UTF8String
				length: length];

	OFURIVerifyIsEscaped(self->_percentEncodedUser,
	    [OFCharacterSet URIUserAllowedCharacterSet]);
}

static void
parseHostPort(OFURI *self, const char *UTF8String, size_t length)
{
	OFString *portString;

	if (*UTF8String == '[') {
		const char *end = memchr(UTF8String, ']', length);

		if (end == NULL)
			@throw [OFInvalidFormatException exception];

		for (const char *iter = UTF8String + 1; iter < end; iter++)
			if (!OFASCIIIsDigit(*iter) && *iter != ':' &&
			    (*iter < 'a' || *iter > 'f') &&
			    (*iter < 'A' || *iter > 'F'))
				@throw [OFInvalidFormatException exception];

		self->_percentEncodedHost = [[OFString alloc]
		    initWithUTF8String: UTF8String
				length: end - UTF8String + 1];

		length -= (end - UTF8String) + 1;
		UTF8String = end + 1;
	} else {
		const char *colon = memchr(UTF8String, ':', length);

		if (colon != NULL) {
			self->_percentEncodedHost = [[OFString alloc]
			    initWithUTF8String: UTF8String
					length: colon - UTF8String];

			length -= colon - UTF8String;
			UTF8String = colon;
		} else {
			self->_percentEncodedHost = [[OFString alloc]
			    initWithUTF8String: UTF8String
					length: length];

			UTF8String += length;
			length = 0;
		}

		OFURIVerifyIsEscaped(self->_percentEncodedHost,
		    [OFCharacterSet URIHostAllowedCharacterSet]);
	}

	if (length == 0)
		return;

	if (length <= 1 || *UTF8String != ':')
		@throw [OFInvalidFormatException exception];

	UTF8String++;
	length--;

	for (size_t i = 0; i < length; i++)
		if (!OFASCIIIsDigit(UTF8String[i]))
			@throw [OFInvalidFormatException exception];

	portString = [OFString stringWithUTF8String: UTF8String length: length];

	if (portString.unsignedLongLongValue > 65535)
		@throw [OFInvalidFormatException exception];

	self->_port = [[OFNumber alloc] initWithUnsignedShort:
	    (unsigned short)portString.unsignedLongLongValue];
}

static size_t
parseAuthority(OFURI *self, const char *UTF8String, size_t length)
{
	size_t ret;
	const char *slash, *at;

	if ((slash = memchr(UTF8String, '/', length)) != NULL)
		length = slash - UTF8String;

	ret = length;

	if ((at = memchr(UTF8String, '@', length)) != NULL) {
		parseUserInfo(self, UTF8String, at - UTF8String);

		length -= at - UTF8String + 1;
		UTF8String = at + 1;
	}

	parseHostPort(self, UTF8String, length);

	return ret;
}

static void
parsePathQueryFragment(OFURI *self, const char *UTF8String, size_t length)
{
	const char *fragment, *query;

	if ((fragment = memchr(UTF8String, '#', length)) != NULL) {
		self->_percentEncodedFragment = [[OFString alloc]
		    initWithUTF8String: fragment + 1
				length: length - (fragment - UTF8String) - 1];

		OFURIVerifyIsEscaped(self->_percentEncodedFragment,
		    [OFCharacterSet URIQueryAllowedCharacterSet]);

		length = fragment - UTF8String;
	}

	if ((query = memchr(UTF8String, '?', length)) != NULL) {
		self->_percentEncodedQuery = [[OFString alloc]
		    initWithUTF8String: query + 1
				length: length - (query - UTF8String) - 1];

		OFURIVerifyIsEscaped(self->_percentEncodedQuery,
		    [OFCharacterSet URIFragmentAllowedCharacterSet]);

		length = query - UTF8String;
	}

	self->_percentEncodedPath = [[OFString alloc]
	    initWithUTF8String: UTF8String
			length: length];

	OFURIVerifyIsEscaped(self->_percentEncodedPath,
	    [OFCharacterSet URIQueryAllowedCharacterSet]);
}

- (instancetype)initWithString: (OFString *)string
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		const char *UTF8String = string.UTF8String;
		size_t length = string.UTF8StringLength;
		const char *colon;

		if ((colon = strchr(UTF8String, ':')) == NULL ||
		    colon - UTF8String < 1 || !OFASCIIIsAlpha(UTF8String[0]))
			@throw [OFInvalidFormatException exception];

		_percentEncodedScheme = [[[OFString
		    stringWithUTF8String: UTF8String
				  length: colon - UTF8String] lowercaseString]
		    copy];

		OFURIVerifyIsEscaped(_percentEncodedScheme,
		    [OFCharacterSet URISchemeAllowedCharacterSet]);

		length -= colon - UTF8String + 1;
		UTF8String = colon + 1;

		if (length >= 2 && UTF8String[0] == '/' &&
		    UTF8String[1] == '/') {
			size_t authorityLength;

			UTF8String += 2;
			length -= 2;

			authorityLength = parseAuthority(self,
			    UTF8String, length);

			UTF8String += authorityLength;
			length -= authorityLength;

			if (length > 0)
				OFEnsure(UTF8String[0] == '/');
		}

		parsePathQueryFragment(self, UTF8String, length);

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithString: (OFString *)string relativeToURI: (OFURI *)URI
{
	char *UTF8String, *UTF8String2 = NULL;

	if ([string containsString: @"://"])
		return [self initWithString: string];

	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		char *tmp;

		_percentEncodedScheme = [URI->_percentEncodedScheme copy];
		_percentEncodedHost = [URI->_percentEncodedHost copy];
		_port = [URI->_port copy];
		_percentEncodedUser = [URI->_percentEncodedUser copy];
		_percentEncodedPassword = [URI->_percentEncodedPassword copy];

		UTF8String = UTF8String2 = OFStrDup(string.UTF8String);

		if ((tmp = strchr(UTF8String, '#')) != NULL) {
			*tmp = '\0';
			_percentEncodedFragment = [[OFString alloc]
			    initWithUTF8String: tmp + 1];

			OFURIVerifyIsEscaped(_percentEncodedFragment,
			    [OFCharacterSet URIFragmentAllowedCharacterSet]);
		}

		if ((tmp = strchr(UTF8String, '?')) != NULL) {
			*tmp = '\0';
			_percentEncodedQuery = [[OFString alloc]
			    initWithUTF8String: tmp + 1];

			OFURIVerifyIsEscaped(_percentEncodedQuery,
			    [OFCharacterSet URIQueryAllowedCharacterSet]);
		}

		if (*UTF8String == '/')
			_percentEncodedPath = [[OFString alloc]
			    initWithUTF8String: UTF8String];
		else {
			OFString *relativePath =
			    [OFString stringWithUTF8String: UTF8String];

			if ([URI->_percentEncodedPath hasSuffix: @"/"])
				_percentEncodedPath = [[URI->_percentEncodedPath
				    stringByAppendingString: relativePath]
				    copy];
			else {
				OFMutableString *path = [OFMutableString
				    stringWithString:
				    (URI->_percentEncodedPath.length > 0
				    ? URI->_percentEncodedPath
				    : @"/")];
				OFRange range = [path
				    rangeOfString: @"/"
					  options: OFStringSearchBackwards];

				if (range.location == OFNotFound)
					@throw [OFInvalidFormatException
					    exception];

				range.location++;
				range.length = path.length - range.location;

				[path replaceCharactersInRange: range
						    withString: relativePath];
				[path makeImmutable];

				_percentEncodedPath = [path copy];
			}
		}

		OFURIVerifyIsEscaped(_percentEncodedPath,
		    [OFCharacterSet URIPathAllowedCharacterSet]);

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	} @finally {
		OFFreeMemory(UTF8String2);
	}

	return self;
}

#ifdef OF_HAVE_FILES
- (instancetype)initFileURIWithPath: (OFString *)path
{
	bool isDirectory;

	@try {
		void *pool = objc_autoreleasePoolPush();
		isDirectory = [path of_isDirectoryPath];
		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	self = [self initFileURIWithPath: path isDirectory: isDirectory];

	return self;
}

- (instancetype)initFileURIWithPath: (OFString *)path
			isDirectory: (bool)isDirectory
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFString *percentEncodedHost = nil;

		if (!path.absolutePath) {
			OFString *currentDirectoryPath = [OFFileManager
			    defaultManager].currentDirectoryPath;

			path = [currentDirectoryPath
			    stringByAppendingPathComponent: path];
			path = path.stringByStandardizingPath;
		}

		path = [path of_pathToURIPathWithPercentEncodedHost:
		    &percentEncodedHost];
		_percentEncodedHost = [percentEncodedHost copy];

		if (isDirectory && ![path hasSuffix: @"/"])
			path = [path stringByAppendingString: @"/"];

		_percentEncodedScheme = @"file";
		_percentEncodedPath = [[path
		    stringByAddingPercentEncodingWithAllowedCharacters:
		    [OFCharacterSet URIPathAllowedCharacterSet]] copy];

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
	void *pool = objc_autoreleasePoolPush();
	OFString *stringValue;

	@try {
		if (![element.name isEqual: self.className] ||
		    ![element.namespace isEqual: OFSerializationNS])
			@throw [OFInvalidArgumentException exception];

		stringValue = element.stringValue;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	self = [self initWithString: stringValue];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (void)dealloc
{
	[_percentEncodedScheme release];
	[_percentEncodedHost release];
	[_port release];
	[_percentEncodedUser release];
	[_percentEncodedPassword release];
	[_percentEncodedPath release];
	[_percentEncodedQuery release];
	[_percentEncodedFragment release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFURI *URI;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFURI class]])
		return false;

	URI = object;

	if (URI->_percentEncodedScheme != _percentEncodedScheme &&
	    ![URI->_percentEncodedScheme isEqual: _percentEncodedScheme])
		return false;
	if (URI->_percentEncodedHost != _percentEncodedHost &&
	    ![URI->_percentEncodedHost isEqual: _percentEncodedHost])
		return false;
	if (URI->_port != _port && ![URI->_port isEqual: _port])
		return false;
	if (URI->_percentEncodedUser != _percentEncodedUser &&
	    ![URI->_percentEncodedUser isEqual: _percentEncodedUser])
		return false;
	if (URI->_percentEncodedPassword != _percentEncodedPassword &&
	    ![URI->_percentEncodedPassword isEqual: _percentEncodedPassword])
		return false;
	if (URI->_percentEncodedPath != _percentEncodedPath &&
	    ![URI->_percentEncodedPath isEqual: _percentEncodedPath])
		return false;
	if (URI->_percentEncodedQuery != _percentEncodedQuery &&
	    ![URI->_percentEncodedQuery isEqual: _percentEncodedQuery])
		return false;
	if (URI->_percentEncodedFragment != _percentEncodedFragment &&
	    ![URI->_percentEncodedFragment isEqual: _percentEncodedFragment])
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddHash(&hash, _percentEncodedScheme.hash);
	OFHashAddHash(&hash, _percentEncodedHost.hash);
	OFHashAddHash(&hash, _port.hash);
	OFHashAddHash(&hash, _percentEncodedUser.hash);
	OFHashAddHash(&hash, _percentEncodedPassword.hash);
	OFHashAddHash(&hash, _percentEncodedPath.hash);
	OFHashAddHash(&hash, _percentEncodedQuery.hash);
	OFHashAddHash(&hash, _percentEncodedFragment.hash);

	OFHashFinalize(&hash);

	return hash;
}

- (OFString *)scheme
{
	return _percentEncodedScheme.stringByRemovingPercentEncoding;
}

- (OFString *)percentEncodedScheme
{
	return _percentEncodedScheme;
}

- (OFString *)host
{
	if ([_percentEncodedHost hasPrefix: @"["] &&
	    [_percentEncodedHost hasSuffix: @"]"]) {
		OFString *host = [_percentEncodedHost substringWithRange:
		    OFMakeRange(1, _percentEncodedHost.length - 2)];

		if (!OFURIIsIPv6Host(host))
			@throw [OFInvalidArgumentException exception];

		return host;
	}

	return _percentEncodedHost.stringByRemovingPercentEncoding;
}

- (OFString *)percentEncodedHost
{
	return _percentEncodedHost;
}

- (OFNumber *)port
{
	return _port;
}

- (OFString *)user
{
	return _percentEncodedUser.stringByRemovingPercentEncoding;
}

- (OFString *)percentEncodedUser
{
	return _percentEncodedUser;
}

- (OFString *)password
{
	return _percentEncodedPassword.stringByRemovingPercentEncoding;
}

- (OFString *)percentEncodedPassword
{
	return _percentEncodedPassword;
}

- (OFString *)path
{
	return _percentEncodedPath.stringByRemovingPercentEncoding;
}

- (OFString *)percentEncodedPath
{
	return _percentEncodedPath;
}

- (OFArray *)pathComponents
{
	void *pool = objc_autoreleasePoolPush();
#ifdef OF_HAVE_FILES
	bool isFile = [_percentEncodedScheme isEqual: @"file"];
#endif
	OFMutableArray *ret;
	size_t count;

#ifdef OF_HAVE_FILES
	if (isFile) {
		OFString *path = [_percentEncodedPath
		    of_URIPathToPathWithPercentEncodedHost: nil];
		ret = [[path.pathComponents mutableCopy] autorelease];

		if (![ret.firstObject isEqual: @"/"])
			[ret insertObject: @"/" atIndex: 0];
	} else
#endif
		ret = [[[_percentEncodedPath componentsSeparatedByString: @"/"]
		    mutableCopy] autorelease];

	count = ret.count;

	if (count > 0 && [ret.firstObject length] == 0)
		[ret replaceObjectAtIndex: 0 withObject: @"/"];

	for (size_t i = 0; i < count; i++) {
		OFString *component = [ret objectAtIndex: i];

#ifdef OF_HAVE_FILES
		if (isFile)
			component =
			    [component of_pathComponentToURIPathComponent];
#endif

		component = component.stringByRemovingPercentEncoding;
		[ret replaceObjectAtIndex: i withObject: component];
	}

	[ret makeImmutable];
	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (OFString *)lastPathComponent
{
	void *pool = objc_autoreleasePoolPush();
	OFString *path = _percentEncodedPath;
	const char *UTF8String, *lastComponent;
	size_t length;
	OFString *ret;

	if (path == nil) {
		objc_autoreleasePoolPop(pool);
		return nil;
	}

	if ([path isEqual: @"/"]) {
		objc_autoreleasePoolPop(pool);
		return @"/";
	}

	if ([path hasSuffix: @"/"])
		path = [path substringToIndex: path.length - 1];

	UTF8String = lastComponent = path.UTF8String;
	length = path.UTF8StringLength;

	for (size_t i = 1; i <= length; i++) {
		if (UTF8String[length - i] == '/') {
			lastComponent = UTF8String + (length - i) + 1;
			break;
		}
	}

	ret = [OFString
	    stringWithUTF8String: lastComponent
			  length: length - (lastComponent - UTF8String)];
	ret = [ret.stringByRemovingPercentEncoding retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (OFString *)query
{
	return _percentEncodedQuery.stringByRemovingPercentEncoding;
}

- (OFString *)percentEncodedQuery
{
	return _percentEncodedQuery;
}

- (OFArray OF_GENERIC(OFPair OF_GENERIC(OFString *, OFString *) *) *)queryItems
{
	void *pool;
	OFArray OF_GENERIC(OFString *) *pairs;
	OFMutableArray OF_GENERIC(OFPair OF_GENERIC(OFString *, OFString *) *)
	    *ret;

	if (_percentEncodedQuery == nil)
		return nil;

	pool = objc_autoreleasePoolPush();
	pairs = [_percentEncodedQuery componentsSeparatedByString: @"&"];
	ret = [OFMutableArray arrayWithCapacity: pairs.count];

	for (OFString *pair in pairs) {
		OFArray *parts = [pair componentsSeparatedByString: @"="];
		OFString *name, *value;

		if (parts.count != 2)
			@throw [OFInvalidFormatException exception];

		name = [[parts objectAtIndex: 0]
		    stringByRemovingPercentEncoding];
		value = [[parts objectAtIndex: 1]
		    stringByRemovingPercentEncoding];

		[ret addObject: [OFPair pairWithFirstObject: name
					       secondObject: value]];
	}

	[ret makeImmutable];
	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (OFString *)fragment
{
	return _percentEncodedFragment.stringByRemovingPercentEncoding;
}

- (OFString *)percentEncodedFragment
{
	return _percentEncodedFragment;
}

- (id)copy
{
	return [self retain];
}

- (id)mutableCopy
{
	OFURI *copy = [[OFMutableURI alloc] init];

	@try {
		copy->_percentEncodedScheme = [_percentEncodedScheme copy];
		copy->_percentEncodedHost = [_percentEncodedHost copy];
		copy->_port = [_port copy];
		copy->_percentEncodedUser = [_percentEncodedUser copy];
		copy->_percentEncodedPassword = [_percentEncodedPassword copy];
		copy->_percentEncodedPath = [_percentEncodedPath copy];
		copy->_percentEncodedQuery = [_percentEncodedQuery copy];
		copy->_percentEncodedFragment = [_percentEncodedFragment copy];
	} @catch (id e) {
		[copy release];
		@throw e;
	}

	return copy;
}

- (OFString *)string
{
	OFMutableString *ret = [OFMutableString string];

	[ret appendFormat: @"%@:", _percentEncodedScheme];

	if (_percentEncodedHost != nil || _port != nil ||
	    _percentEncodedUser != nil || _percentEncodedPassword != nil)
		[ret appendString: @"//"];

	if (_percentEncodedUser != nil && _percentEncodedPassword != nil)
		[ret appendFormat: @"%@:%@@",
				   _percentEncodedUser,
				   _percentEncodedPassword];
	else if (_percentEncodedUser != nil)
		[ret appendFormat: @"%@@", _percentEncodedUser];

	if (_percentEncodedHost != nil)
		[ret appendString: _percentEncodedHost];
	if (_port != nil)
		[ret appendFormat: @":%@", _port];

	if (_percentEncodedPath != nil)
		[ret appendString: _percentEncodedPath];

	if (_percentEncodedQuery != nil)
		[ret appendFormat: @"?%@", _percentEncodedQuery];

	if (_percentEncodedFragment != nil)
		[ret appendFormat: @"#%@", _percentEncodedFragment];

	[ret makeImmutable];

	return ret;
}

#ifdef OF_HAVE_FILES
- (OFString *)fileSystemRepresentation
{
	void *pool = objc_autoreleasePoolPush();
	OFString *path;

	if (![_percentEncodedScheme isEqual: @"file"])
		@throw [OFInvalidArgumentException exception];

	if (![_percentEncodedPath hasPrefix: @"/"])
		@throw [OFInvalidFormatException exception];

	path = [self.path
	    of_URIPathToPathWithPercentEncodedHost: _percentEncodedHost];

	[path retain];

	objc_autoreleasePoolPop(pool);

	return [path autorelease];
}
#endif

- (OFURI *)URIByAppendingPathComponent: (OFString *)component
{
	OFMutableURI *URI = [[self mutableCopy] autorelease];
	[URI appendPathComponent: component];
	[URI makeImmutable];
	return URI;
}

- (OFURI *)URIByAppendingPathComponent: (OFString *)component
			   isDirectory: (bool)isDirectory
{
	OFMutableURI *URI = [[self mutableCopy] autorelease];
	[URI appendPathComponent: component isDirectory: isDirectory];
	[URI makeImmutable];
	return URI;
}

- (OFURI *)URIByStandardizingPath
{
	OFMutableURI *URI = [[self mutableCopy] autorelease];
	[URI standardizePath];
	[URI makeImmutable];
	return URI;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<%@: %@>",
					   self.class, self.string];
}

- (OFXMLElement *)XMLElementBySerializing
{
	void *pool = objc_autoreleasePoolPush();
	OFXMLElement *element;

	element = [OFXMLElement elementWithName: self.className
				      namespace: OFSerializationNS
				    stringValue: self.string];

	[element retain];

	objc_autoreleasePoolPop(pool);

	return [element autorelease];
}
@end
