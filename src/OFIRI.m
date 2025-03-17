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

#include <stdlib.h>
#include <string.h>

#import "OFIRI.h"
#import "OFIRI+Private.h"
#import "OFArray.h"
#import "OFDictionary.h"
#ifdef OF_HAVE_FILES
# import "OFFileManager.h"
# import "OFFileIRIHandler.h"
#endif
#import "OFNumber.h"
#import "OFOnce.h"
#import "OFPair.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

@interface OFIRIAllowedCharacterSetBase: OFCharacterSet
@end

@interface OFIRIAllowedCharacterSet: OFIRIAllowedCharacterSetBase
@end

@interface OFIRISchemeAllowedCharacterSet: OFIRIAllowedCharacterSetBase
@end

@interface OFIRIPathAllowedCharacterSet: OFIRIAllowedCharacterSetBase
@end

@interface OFIRIQueryAllowedCharacterSet: OFIRIAllowedCharacterSetBase
@end

@interface OFIRIQueryKeyValueAllowedCharacterSet: OFIRIAllowedCharacterSetBase
@end

@interface OFIRIFragmentAllowedCharacterSet: OFIRIAllowedCharacterSetBase
@end

OF_DIRECT_MEMBERS
@interface OFInvertedCharacterSetWithoutPercent: OFCharacterSet
{
	OFCharacterSet *_characterSet;
	bool (*_characterIsMember)(id, SEL, OFUnichar);
}

- (instancetype)initWithCharacterSet: (OFCharacterSet *)characterSet;
@end

static OFCharacterSet *IRIAllowedCharacterSet = nil;
static OFCharacterSet *IRISchemeAllowedCharacterSet = nil;
static OFCharacterSet *IRIPathAllowedCharacterSet = nil;
static OFCharacterSet *IRIQueryAllowedCharacterSet = nil;
static OFCharacterSet *IRIQueryKeyValueAllowedCharacterSet = nil;
static OFCharacterSet *IRIFragmentAllowedCharacterSet = nil;

static OFOnceControl IRIAllowedCharacterSetOnce = OFOnceControlInitValue;

static void
initIRIAllowedCharacterSet(void)
{
	IRIAllowedCharacterSet = [[OFIRIAllowedCharacterSet alloc] init];
}

static void
initIRISchemeAllowedCharacterSet(void)
{
	IRISchemeAllowedCharacterSet =
	    [[OFIRISchemeAllowedCharacterSet alloc] init];
}

static void
initIRIPathAllowedCharacterSet(void)
{
	IRIPathAllowedCharacterSet =
	    [[OFIRIPathAllowedCharacterSet alloc] init];
}

static void
initIRIQueryAllowedCharacterSet(void)
{
	IRIQueryAllowedCharacterSet =
	    [[OFIRIQueryAllowedCharacterSet alloc] init];
}

static void
initIRIQueryKeyValueAllowedCharacterSet(void)
{
	IRIQueryKeyValueAllowedCharacterSet =
	    [[OFIRIQueryKeyValueAllowedCharacterSet alloc] init];
}

static void
initIRIFragmentAllowedCharacterSet(void)
{
	IRIFragmentAllowedCharacterSet =
	    [[OFIRIFragmentAllowedCharacterSet alloc] init];
}

bool
_OFIRIIsIPv6Host(OFString *host)
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

static bool
isUnicode(OFUnichar character)
{
	if (character >= 0xA0 && character <= 0xD7FF)
		return true;
	if (character >= 0xF900 && character <= 0xFDCF)
		return true;
	if (character >= 0xFDF0 && character <= 0xFFEF)
		return true;
	if (character >= 0x10000 && character <= 0x1FFFD)
		return true;
	if (character >= 0x20000 && character <= 0x2FFFD)
		return true;
	if (character >= 0x30000 && character <= 0x3FFFD)
		return true;
	if (character >= 0x40000 && character <= 0x4FFFD)
		return true;
	if (character >= 0x50000 && character <= 0x5FFFD)
		return true;
	if (character >= 0x60000 && character <= 0x6FFFD)
		return true;
	if (character >= 0x70000 && character <= 0x7FFFD)
		return true;
	if (character >= 0x80000 && character <= 0x8FFFD)
		return true;
	if (character >= 0x90000 && character <= 0x9FFFD)
		return true;
	if (character >= 0xA0000 && character <= 0xAFFFD)
		return true;
	if (character >= 0xB0000 && character <= 0xBFFFD)
		return true;
	if (character >= 0xC0000 && character <= 0xCFFFD)
		return true;
	if (character >= 0xD0000 && character <= 0xDFFFD)
		return true;
	if (character >= 0xE0000 && character <= 0xEFFFD)
		return true;

	return false;
}

static bool
isUnicodePrivate(OFUnichar character)
{
	if (character >= 0xE00 && character <= 0xF8FF)
		return true;
	if (character >= 0xF0000 && character <= 0xFFFFD)
		return true;
	if (character >= 0x100000 && character <= 0x10FFFD)
		return true;

	return false;
}

@implementation OFIRIAllowedCharacterSetBase
OF_SINGLETON_METHODS
@end

@implementation OFIRIAllowedCharacterSet
- (bool)characterIsMember: (OFUnichar)character
{
	if (character < CHAR_MAX && OFASCIIIsAlnum(character))
		return true;

	if (isUnicode(character))
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

@implementation OFIRISchemeAllowedCharacterSet
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

@implementation OFIRIPathAllowedCharacterSet
- (bool)characterIsMember: (OFUnichar)character
{
	if (character < CHAR_MAX && OFASCIIIsAlnum(character))
		return true;

	if (isUnicode(character))
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

@implementation OFIRIQueryAllowedCharacterSet
- (bool)characterIsMember: (OFUnichar)character
{
	if (character < CHAR_MAX && OFASCIIIsAlnum(character))
		return true;

	if (isUnicode(character) || isUnicodePrivate(character))
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

@implementation OFIRIQueryKeyValueAllowedCharacterSet
- (bool)characterIsMember: (OFUnichar)character
{
	if (character < CHAR_MAX && OFASCIIIsAlnum(character))
		return true;

	if (isUnicode(character) || isUnicodePrivate(character))
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

@implementation OFIRIFragmentAllowedCharacterSet
- (bool)characterIsMember: (OFUnichar)character
{
	if (character < CHAR_MAX && OFASCIIIsAlnum(character))
		return true;

	if (isUnicode(character))
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
_OFIRIVerifyIsEscaped(OFString *string, OFCharacterSet *characterSet,
    bool allowPercent)
{
	void *pool = objc_autoreleasePoolPush();

	if (allowPercent)
		characterSet = [[[OFInvertedCharacterSetWithoutPercent alloc]
		    initWithCharacterSet: characterSet] autorelease];
	else
		characterSet = characterSet.invertedSet;

	if ([string rangeOfCharacterFromSet: characterSet].location !=
	    OFNotFound)
		@throw [OFInvalidFormatException exception];

	objc_autoreleasePoolPop(pool);
}

@implementation OFCharacterSet (IRICharacterSets)
+ (OFCharacterSet *)IRISchemeAllowedCharacterSet
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, initIRISchemeAllowedCharacterSet);

	return IRISchemeAllowedCharacterSet;
}

+ (OFCharacterSet *)IRIHostAllowedCharacterSet
{
	OFOnce(&IRIAllowedCharacterSetOnce, initIRIAllowedCharacterSet);

	return IRIAllowedCharacterSet;
}

+ (OFCharacterSet *)IRIUserAllowedCharacterSet
{
	OFOnce(&IRIAllowedCharacterSetOnce, initIRIAllowedCharacterSet);

	return IRIAllowedCharacterSet;
}

+ (OFCharacterSet *)IRIPasswordAllowedCharacterSet
{
	OFOnce(&IRIAllowedCharacterSetOnce, initIRIAllowedCharacterSet);

	return IRIAllowedCharacterSet;
}

+ (OFCharacterSet *)IRIPathAllowedCharacterSet
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, initIRIPathAllowedCharacterSet);

	return IRIPathAllowedCharacterSet;
}

+ (OFCharacterSet *)IRIQueryAllowedCharacterSet
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, initIRIQueryAllowedCharacterSet);

	return IRIQueryAllowedCharacterSet;
}

+ (OFCharacterSet *)IRIQueryKeyValueAllowedCharacterSet
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, initIRIQueryKeyValueAllowedCharacterSet);

	return IRIQueryKeyValueAllowedCharacterSet;
}

+ (OFCharacterSet *)IRIFragmentAllowedCharacterSet
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, initIRIFragmentAllowedCharacterSet);

	return IRIFragmentAllowedCharacterSet;
}
@end

@implementation OFIRI
+ (instancetype)IRI
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)IRIWithString: (OFString *)string
{
	return [[[self alloc] initWithString: string] autorelease];
}

+ (instancetype)IRIWithString: (OFString *)string relativeToIRI: (OFIRI *)IRI
{
	return [[[self alloc] initWithString: string
			       relativeToIRI: IRI] autorelease];
}

#ifdef OF_HAVE_FILES
+ (instancetype)fileIRIWithPath: (OFString *)path
{
	return [[[self alloc] initFileIRIWithPath: path] autorelease];
}

+ (instancetype)fileIRIWithPath: (OFString *)path isDirectory: (bool)isDirectory
{
	return [[[self alloc] initFileIRIWithPath: path
				      isDirectory: isDirectory] autorelease];
}
#endif

static void
parseUserInfo(OFIRI *self, const char *UTF8String, size_t length)
{
	const char *colon;

	if ((colon = memchr(UTF8String, ':', length)) != NULL) {
		self->_percentEncodedUser = [[OFString alloc]
		    initWithUTF8String: UTF8String
				length: colon - UTF8String];
		self->_percentEncodedPassword = [[OFString alloc]
		    initWithUTF8String: colon + 1
				length: length - (colon - UTF8String) - 1];

		_OFIRIVerifyIsEscaped(self->_percentEncodedPassword,
		    [OFCharacterSet IRIPasswordAllowedCharacterSet], true);
	} else
		self->_percentEncodedUser = [[OFString alloc]
		    initWithUTF8String: UTF8String
				length: length];

	_OFIRIVerifyIsEscaped(self->_percentEncodedUser,
	    [OFCharacterSet IRIUserAllowedCharacterSet], true);
}

static void
parseHostPort(OFIRI *self, const char *UTF8String, size_t length)
{
	OFString *portString;
	unsigned short port;

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

		_OFIRIVerifyIsEscaped(self->_percentEncodedHost,
		    [OFCharacterSet IRIHostAllowedCharacterSet], true);
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
	@try {
		port = portString.unsignedShortValue;
	} @catch (OFOutOfRangeException *e) {
		@throw [OFInvalidFormatException exception];
	}

#if USHRT_MAX != 65535
	if (port > 65535)
		@throw [OFInvalidFormatException exception];
#endif

	self->_port = [[OFNumber alloc] initWithUnsignedShort: port];
}

static size_t
parseAuthority(OFIRI *self, const char *UTF8String, size_t length)
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
parsePathQueryFragment(const char *UTF8String, size_t length,
    OFString **pathString, OFString **queryString, OFString **fragmentString)
{
	const char *fragment, *query;

	if ((fragment = memchr(UTF8String, '#', length)) != NULL) {
		*fragmentString = [OFString
		    stringWithUTF8String: fragment + 1
				  length: length - (fragment - UTF8String) - 1];

		_OFIRIVerifyIsEscaped(*fragmentString,
		    [OFCharacterSet IRIQueryAllowedCharacterSet], true);

		length = fragment - UTF8String;
	}

	if ((query = memchr(UTF8String, '?', length)) != NULL) {
		*queryString = [OFString
		    stringWithUTF8String: query + 1
				  length: length - (query - UTF8String) - 1];

		_OFIRIVerifyIsEscaped(*queryString,
		    [OFCharacterSet IRIFragmentAllowedCharacterSet], true);

		length = query - UTF8String;
	}

	*pathString = [OFString stringWithUTF8String: UTF8String
					      length: length];

	_OFIRIVerifyIsEscaped(*pathString,
	    [OFCharacterSet IRIPathAllowedCharacterSet], true);
}

- (instancetype)initWithString: (OFString *)string
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		const char *UTF8String = string.UTF8String;
		size_t length = string.UTF8StringLength;
		const char *colon;
		OFString *path, *query = nil, *fragment = nil;

		if ((colon = strchr(UTF8String, ':')) == NULL ||
		    colon - UTF8String < 1 || !OFASCIIIsAlpha(UTF8String[0]))
			@throw [OFInvalidFormatException exception];

		_scheme = [[[OFString stringWithUTF8String: UTF8String
						    length: colon - UTF8String]
		    lowercaseString] copy];

		_OFIRIVerifyIsEscaped(_scheme,
		    [OFCharacterSet IRISchemeAllowedCharacterSet], false);

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

		parsePathQueryFragment(UTF8String, length,
		    &path, &query, &fragment);
		_percentEncodedPath = [path copy];
		_percentEncodedQuery = [query copy];
		_percentEncodedFragment = [fragment copy];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

static bool
isAbsolute(OFString *string)
{
	void *pool = objc_autoreleasePoolPush();

	@try {
		const char *UTF8String = string.UTF8String;
		size_t length = string.UTF8StringLength;

		if (length < 1)
			return false;

		if (!OFASCIIIsAlpha(UTF8String[0]))
			return false;

		for (size_t i = 1; i < length; i++) {
			if (UTF8String[i] == ':')
				return true;

			if (!OFASCIIIsAlnum(UTF8String[i]) &&
			    UTF8String[i] != '+' && UTF8String[i] != '-' &&
			    UTF8String[i] != '.')
				return false;
		}
	} @finally {
		objc_autoreleasePoolPop(pool);
	}

	return false;
}

static OFString *
merge(OFString *base, OFString *path)
{
	OFMutableArray *components;

	if (base.length == 0)
		base = @"/";

	components = [[[base componentsSeparatedByString: @"/"]
	    mutableCopy] autorelease];

	if (components.count == 1)
		[components addObject: path];
	else
		[components replaceObjectAtIndex: components.count - 1
				      withObject: path];

	return [components componentsJoinedByString: @"/"];
}

- (instancetype)initWithString: (OFString *)string relativeToIRI: (OFIRI *)IRI
{
	bool absolute;

	@try {
		absolute = isAbsolute(string);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	if (absolute)
		return [self initWithString: string];

	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		const char *UTF8String = string.UTF8String;
		size_t length = string.UTF8StringLength;
		bool hasAuthority = false;
		OFString *path, *query = nil, *fragment = nil;

		_scheme = [IRI->_scheme copy];

		if (length >= 2 && UTF8String[0] == '/' &&
		    UTF8String[1] == '/') {
			size_t authorityLength;

			hasAuthority = true;

			UTF8String += 2;
			length -= 2;

			authorityLength = parseAuthority(self,
			    UTF8String, length);

			UTF8String += authorityLength;
			length -= authorityLength;

			if (length > 0)
				OFEnsure(UTF8String[0] == '/');
		} else {
			_percentEncodedHost = [IRI->_percentEncodedHost copy];
			_port = [IRI->_port copy];
			_percentEncodedUser = [IRI->_percentEncodedUser copy];
			_percentEncodedPassword =
			    [IRI->_percentEncodedPassword copy];
		}

		parsePathQueryFragment(UTF8String, length,
		    &path, &query, &fragment);
		_percentEncodedFragment = [fragment copy];

		if (hasAuthority) {
			_percentEncodedPath = [path copy];
			_percentEncodedQuery = [query copy];
		} else {
			if (path.length == 0) {
				_percentEncodedPath =
				    [IRI->_percentEncodedPath copy];
				_percentEncodedQuery = (query != nil
				    ? [query copy]
				    : [IRI->_percentEncodedQuery copy]);
			} else {
				if ([path hasPrefix: @"/"])
					_percentEncodedPath = [path copy];
				else
					_percentEncodedPath = [merge(
					    IRI->_percentEncodedPath, path)
					    copy];

				_percentEncodedQuery = [query copy];
			}
		}

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

#ifdef OF_HAVE_FILES
- (instancetype)initFileIRIWithPath: (OFString *)path
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

	self = [self initFileIRIWithPath: path isDirectory: isDirectory];

	return self;
}

- (instancetype)initFileIRIWithPath: (OFString *)path
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

		path = [path of_pathToIRIPathWithPercentEncodedHost:
		    &percentEncodedHost];
		_percentEncodedHost = [percentEncodedHost copy];

		if (isDirectory && ![path hasSuffix: @"/"])
			path = [path stringByAppendingString: @"/"];

		_scheme = @"file";
		_percentEncodedPath = [[path
		    stringByAddingPercentEncodingWithAllowedCharacters:
		    [OFCharacterSet IRIPathAllowedCharacterSet]] copy];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
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

- (void)dealloc
{
	[_scheme release];
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
	OFIRI *IRI;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFIRI class]])
		return false;

	IRI = object;

	if (![IRI->_scheme isEqual: _scheme])
		return false;
	if (IRI->_percentEncodedHost != _percentEncodedHost &&
	    ![IRI->_percentEncodedHost isEqual: _percentEncodedHost])
		return false;
	if (IRI->_port != _port && ![IRI->_port isEqual: _port])
		return false;
	if (IRI->_percentEncodedUser != _percentEncodedUser &&
	    ![IRI->_percentEncodedUser isEqual: _percentEncodedUser])
		return false;
	if (IRI->_percentEncodedPassword != _percentEncodedPassword &&
	    ![IRI->_percentEncodedPassword isEqual: _percentEncodedPassword])
		return false;
	if (![IRI->_percentEncodedPath isEqual: _percentEncodedPath])
		return false;
	if (IRI->_percentEncodedQuery != _percentEncodedQuery &&
	    ![IRI->_percentEncodedQuery isEqual: _percentEncodedQuery])
		return false;
	if (IRI->_percentEncodedFragment != _percentEncodedFragment &&
	    ![IRI->_percentEncodedFragment isEqual: _percentEncodedFragment])
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddHash(&hash, _scheme.hash);
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
	return _scheme;
}

- (OFString *)host
{
	if ([_percentEncodedHost hasPrefix: @"["] &&
	    [_percentEncodedHost hasSuffix: @"]"]) {
		OFString *host = [_percentEncodedHost substringWithRange:
		    OFMakeRange(1, _percentEncodedHost.length - 2)];

		if (!_OFIRIIsIPv6Host(host))
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
	bool isFile = [_scheme isEqual: @"file"];
#endif
	OFMutableArray *ret;
	size_t count;

#ifdef OF_HAVE_FILES
	if (isFile) {
		OFString *path = [_percentEncodedPath
		    of_IRIPathToPathWithPercentEncodedHost: nil];
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
			    [component of_pathComponentToIRIPathComponent];
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

- (OFString *)pathExtension
{
	void *pool = objc_autoreleasePoolPush();
	OFString *ret, *fileName;
	size_t pos;

	fileName = self.lastPathComponent;
	pos = [fileName rangeOfString: @"."
			      options: OFStringSearchBackwards].location;
	if (pos == OFNotFound || pos == 0) {
		objc_autoreleasePoolPop(pool);
		return @"";
	}

	ret = [fileName substringFromIndex: pos + 1];

	[ret retain];
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
	OFIRI *copy = [[OFMutableIRI alloc] initWithScheme: _scheme];

	@try {
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

	[ret appendFormat: @"%@:", _scheme];

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

	if (![_scheme isEqual: @"file"])
		@throw [OFInvalidArgumentException exception];

	if (![_percentEncodedPath hasPrefix: @"/"])
		@throw [OFInvalidFormatException exception];

	path = [self.path
	    of_IRIPathToPathWithPercentEncodedHost: _percentEncodedHost];

	[path retain];

	objc_autoreleasePoolPop(pool);

	return [path autorelease];
}
#endif

- (OFIRI *)IRIByAppendingPathComponent: (OFString *)component
{
	OFMutableIRI *IRI = [[self mutableCopy] autorelease];
	[IRI appendPathComponent: component];
	[IRI makeImmutable];
	return IRI;
}

- (OFIRI *)IRIByAppendingPathComponent: (OFString *)component
			   isDirectory: (bool)isDirectory
{
	OFMutableIRI *IRI = [[self mutableCopy] autorelease];
	[IRI appendPathComponent: component isDirectory: isDirectory];
	[IRI makeImmutable];
	return IRI;
}

- (OFIRI *)IRIByDeletingLastPathComponent
{
	OFMutableIRI *IRI = [[self mutableCopy] autorelease];
	[IRI deleteLastPathComponent];
	[IRI makeImmutable];
	return IRI;
}

- (OFIRI *)IRIByAppendingPathExtension: (OFString *)extension
{
	OFMutableIRI *IRI = [[self mutableCopy] autorelease];
	[IRI appendPathExtension: extension];
	[IRI makeImmutable];
	return IRI;
}

- (OFIRI *)IRIByDeletingPathExtension
{
	OFMutableIRI *IRI = [[self mutableCopy] autorelease];
	[IRI deletePathExtension];
	[IRI makeImmutable];
	return IRI;
}

- (OFIRI *)IRIByStandardizingPath
{
	OFMutableIRI *IRI = [[self mutableCopy] autorelease];
	[IRI standardizePath];
	[IRI makeImmutable];
	return IRI;
}

- (OFIRI *)IRIByAddingPercentEncodingForUnicodeCharacters
{
	OFMutableIRI *IRI = [[self mutableCopy] autorelease];
	void *pool = objc_autoreleasePoolPush();
	OFCharacterSet *ASCII =
	    [OFCharacterSet characterSetWithRange: OFMakeRange(0, 0x80)];

	IRI.percentEncodedHost = [_percentEncodedHost
	    stringByAddingPercentEncodingWithAllowedCharacters: ASCII];
	IRI.percentEncodedUser = [_percentEncodedUser
	    stringByAddingPercentEncodingWithAllowedCharacters: ASCII];
	IRI.percentEncodedPassword = [_percentEncodedPassword
	    stringByAddingPercentEncodingWithAllowedCharacters: ASCII];
	IRI.percentEncodedPath = [_percentEncodedPath
	    stringByAddingPercentEncodingWithAllowedCharacters: ASCII];
	IRI.percentEncodedQuery = [_percentEncodedQuery
	    stringByAddingPercentEncodingWithAllowedCharacters: ASCII];
	IRI.percentEncodedFragment = [_percentEncodedFragment
	    stringByAddingPercentEncodingWithAllowedCharacters: ASCII];

	[IRI makeImmutable];

	objc_autoreleasePoolPop(pool);

	return IRI;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<%@: %@>",
					   self.class, self.string];
}
@end
