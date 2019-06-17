/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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
#import "OFArray.h"
#import "OFNumber.h"
#import "OFString.h"
#import "OFXMLElement.h"

#ifdef OF_HAVE_FILES
# import "OFFileManager.h"
# import "OFFileURLHandler.h"
#endif

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"

static OFCharacterSet *URLAllowedCharacterSet = nil;
static OFCharacterSet *URLSchemeAllowedCharacterSet = nil;
static OFCharacterSet *URLPathAllowedCharacterSet = nil;
static OFCharacterSet *URLQueryOrFragmentAllowedCharacterSet = nil;

@interface OFURLAllowedCharacterSetBase: OFCharacterSet
- (instancetype)of_init OF_METHOD_FAMILY(init);
@end

@interface OFURLAllowedCharacterSet: OFURLAllowedCharacterSetBase
+ (OFCharacterSet *)URLAllowedCharacterSet;
@end

@interface OFURLSchemeAllowedCharacterSet: OFURLAllowedCharacterSetBase
+ (OFCharacterSet *)URLSchemeAllowedCharacterSet;
@end

@interface OFURLPathAllowedCharacterSet: OFURLAllowedCharacterSetBase
+ (OFCharacterSet *)URLPathAllowedCharacterSet;
@end

@interface OFURLQueryOrFragmentAllowedCharacterSet: OFURLAllowedCharacterSetBase
+ (OFCharacterSet *)URLQueryOrFragmentAllowedCharacterSet;
@end

#ifdef OF_HAVE_FILES
static OFString *
pathToURLPath(OFString *path)
{
# if defined(OF_WINDOWS) || defined(OF_MSDOS)
	path = [path stringByReplacingOccurrencesOfString: @"\\"
					       withString: @"/"];
	path = [path stringByPrependingString: @"/"];

	return path;
# elif defined(OF_AMIGAOS)
	OFArray OF_GENERIC(OFString *) *components = path.pathComponents;
	OFMutableString *ret = [OFMutableString string];

	for (OFString *component in components) {
		if (component.length == 0)
			continue;

		if ([component isEqual: @"/"])
			[ret appendString: @"/.."];
		else {
			[ret appendString: @"/"];
			[ret appendString: component];
		}
	}

	[ret makeImmutable];

	return ret;
# elif defined(OF_NINTENDO_3DS) || defined(OF_WII)
	return [path stringByPrependingString: @"/"];
# else
	return path;
# endif
}

static OFString *
URLPathToPath(OFString *path)
{
# if defined(OF_WINDOWS) || defined(OF_MSDOS)
	path = [path substringWithRange: of_range(1, path.length - 1)];
	path = [path stringByReplacingOccurrencesOfString: @"/"
					       withString: @"\\"];

	return path;
# elif defined(OF_AMIGAOS)
	OFMutableArray OF_GENERIC(OFString *) *components;
	size_t count;

	path = [path substringWithRange: of_range(1, path.length - 1)];
	components = [[[path
	    componentsSeparatedByString: @"/"] mutableCopy] autorelease];
	count = components.count;

	for (size_t i = 0; i < count; i++) {
		OFString *component = [components objectAtIndex: i];

		if ([component isEqual: @"."]) {
			[components removeObjectAtIndex: i];
			count--;

			i--;
			continue;
		}

		if ([component isEqual: @".."])
			[components replaceObjectAtIndex: i
					      withObject: @"/"];
	}

	return [OFString pathWithComponents: components];
# elif defined(OF_NINTENDO_3DS) || defined(OF_WII)
	return [path substringWithRange: of_range(1, path.length - 1)];
# else
	return path;
# endif
}
#endif

@interface OFInvertedCharacterSetWithoutPercent: OFCharacterSet
{
	OFCharacterSet *_characterSet;
	bool (*_characterIsMember)(id, SEL, of_unichar_t);
}

- (instancetype)of_initWithCharacterSet: (OFCharacterSet *)characterSet
    OF_METHOD_FAMILY(init);
@end

@implementation OFURLAllowedCharacterSetBase
- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_init
{
	return [super init];
}

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
	return OF_RETAIN_COUNT_MAX;
}
@end

@implementation OFURLAllowedCharacterSet
+ (void)initialize
{
	if (self != [OFURLAllowedCharacterSet class])
		return;

	URLAllowedCharacterSet = [[OFURLAllowedCharacterSet alloc] of_init];
}

+ (OFCharacterSet *)URLAllowedCharacterSet
{
	return URLAllowedCharacterSet;
}

- (bool)characterIsMember: (of_unichar_t)character
{
	if (character < CHAR_MAX && of_ascii_isalnum(character))
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

@implementation OFURLSchemeAllowedCharacterSet
+ (void)initialize
{
	if (self != [OFURLSchemeAllowedCharacterSet class])
		return;

	URLSchemeAllowedCharacterSet =
	    [[OFURLSchemeAllowedCharacterSet alloc] of_init];
}

+ (OFCharacterSet *)URLSchemeAllowedCharacterSet
{
	return URLSchemeAllowedCharacterSet;
}

- (bool)characterIsMember: (of_unichar_t)character
{
	if (character < CHAR_MAX && of_ascii_isalnum(character))
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

@implementation OFURLPathAllowedCharacterSet
+ (void)initialize
{
	if (self != [OFURLPathAllowedCharacterSet class])
		return;

	URLPathAllowedCharacterSet =
	    [[OFURLPathAllowedCharacterSet alloc] of_init];
}

+ (OFCharacterSet *)URLPathAllowedCharacterSet
{
	return URLPathAllowedCharacterSet;
}

- (bool)characterIsMember: (of_unichar_t)character
{
	if (character < CHAR_MAX && of_ascii_isalnum(character))
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

@implementation OFURLQueryOrFragmentAllowedCharacterSet
+ (void)initialize
{
	if (self != [OFURLQueryOrFragmentAllowedCharacterSet class])
		return;

	URLQueryOrFragmentAllowedCharacterSet =
	    [[OFURLQueryOrFragmentAllowedCharacterSet alloc] of_init];
}

+ (OFCharacterSet *)URLQueryOrFragmentAllowedCharacterSet
{
	return URLQueryOrFragmentAllowedCharacterSet;
}

- (bool)characterIsMember: (of_unichar_t)character
{
	if (character < CHAR_MAX && of_ascii_isalnum(character))
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
- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_initWithCharacterSet: (OFCharacterSet *)characterSet
{
	self = [super init];

	_characterSet = [characterSet retain];
	_characterIsMember = (bool (*)(id, SEL, of_unichar_t))
	    [_characterSet methodForSelector: @selector(characterIsMember:)];

	return self;
}

- (void)dealloc
{
	[_characterSet release];

	[super dealloc];
}

- (bool)characterIsMember: (of_unichar_t)character
{
	return (character != '%' && !_characterIsMember(_characterSet,
	    @selector(characterIsMember:), character));
}
@end

void
of_url_verify_escaped(OFString *string, OFCharacterSet *characterSet)
{
	void *pool = objc_autoreleasePoolPush();

	characterSet = [[[OFInvertedCharacterSetWithoutPercent alloc]
	    of_initWithCharacterSet: characterSet] autorelease];

	if ([string indexOfCharacterFromSet: characterSet] != OF_NOT_FOUND)
		@throw [OFInvalidFormatException exception];

	objc_autoreleasePoolPop(pool);
}

@implementation OFCharacterSet (URLCharacterSets)
+ (OFCharacterSet *)URLSchemeAllowedCharacterSet
{
	return [OFURLSchemeAllowedCharacterSet URLSchemeAllowedCharacterSet];
}

+ (OFCharacterSet *)URLHostAllowedCharacterSet
{
	return [OFURLAllowedCharacterSet URLAllowedCharacterSet];
}

+ (OFCharacterSet *)URLUserAllowedCharacterSet
{
	return [OFURLAllowedCharacterSet URLAllowedCharacterSet];
}

+ (OFCharacterSet *)URLPasswordAllowedCharacterSet
{
	return [OFURLAllowedCharacterSet URLAllowedCharacterSet];
}

+ (OFCharacterSet *)URLPathAllowedCharacterSet
{
	return [OFURLPathAllowedCharacterSet URLPathAllowedCharacterSet];
}

+ (OFCharacterSet *)URLQueryAllowedCharacterSet
{
	return [OFURLQueryOrFragmentAllowedCharacterSet
	    URLQueryOrFragmentAllowedCharacterSet];
}

+ (OFCharacterSet *)URLFragmentAllowedCharacterSet
{
	return [OFURLQueryOrFragmentAllowedCharacterSet
	    URLQueryOrFragmentAllowedCharacterSet];
}
@end

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

- (instancetype)initWithString: (OFString *)string
{
	char *UTF8String, *UTF8String2 = NULL;

	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		char *tmp, *tmp2;

		if ((UTF8String2 = of_strdup(string.UTF8String)) == NULL)
			@throw [OFOutOfMemoryException
			     exceptionWithRequestedSize:
			     string.UTF8StringLength];

		UTF8String = UTF8String2;

		if ((tmp = strchr(UTF8String, ':')) == NULL)
			@throw [OFInvalidFormatException exception];

		if (strncmp(tmp, "://", 3) != 0)
			@throw [OFInvalidFormatException exception];

		for (tmp2 = UTF8String; tmp2 < tmp; tmp2++)
			*tmp2 = of_ascii_tolower(*tmp2);

		_URLEncodedScheme = [[OFString alloc]
		    initWithUTF8String: UTF8String
				length: tmp - UTF8String];

		of_url_verify_escaped(_URLEncodedScheme,
		    [OFCharacterSet URLSchemeAllowedCharacterSet]);

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

				_URLEncodedUser = [[OFString alloc]
				    initWithUTF8String: UTF8String];
				_URLEncodedPassword = [[OFString alloc]
				    initWithUTF8String: tmp3];

				of_url_verify_escaped(_URLEncodedPassword,
				    [OFCharacterSet
				    URLPasswordAllowedCharacterSet]);
			} else
				_URLEncodedUser = [[OFString alloc]
				    initWithUTF8String: UTF8String];

			of_url_verify_escaped(_URLEncodedUser,
			    [OFCharacterSet URLUserAllowedCharacterSet]);

			UTF8String = tmp2;
		}

		if ((tmp2 = strchr(UTF8String, ':')) != NULL) {
			OFString *portString;

			*tmp2 = '\0';
			tmp2++;

			_URLEncodedHost = [[OFString alloc]
			    initWithUTF8String: UTF8String];

			portString = [OFString stringWithUTF8String: tmp2];

			if (portString.decimalValue > 65535)
				@throw [OFInvalidFormatException exception];

			_port = [[OFNumber alloc] initWithUInt16:
			    (uint16_t)portString.decimalValue];
		} else
			_URLEncodedHost = [[OFString alloc]
			    initWithUTF8String: UTF8String];

		of_url_verify_escaped(_URLEncodedHost,
		    [OFCharacterSet URLHostAllowedCharacterSet]);

		if ((UTF8String = tmp) != NULL) {
			if ((tmp = strchr(UTF8String, '#')) != NULL) {
				*tmp = '\0';

				_URLEncodedFragment = [[OFString alloc]
				    initWithUTF8String: tmp + 1];

				of_url_verify_escaped(_URLEncodedFragment,
				    [OFCharacterSet
				    URLFragmentAllowedCharacterSet]);
			}

			if ((tmp = strchr(UTF8String, '?')) != NULL) {
				*tmp = '\0';

				_URLEncodedQuery = [[OFString alloc]
				    initWithUTF8String: tmp + 1];

				of_url_verify_escaped(_URLEncodedQuery,
				    [OFCharacterSet
				    URLQueryAllowedCharacterSet]);
			}

			UTF8String--;
			*UTF8String = '/';

			_URLEncodedPath = [[OFString alloc]
			    initWithUTF8String: UTF8String];

			of_url_verify_escaped(_URLEncodedPath,
			    [OFCharacterSet URLPathAllowedCharacterSet]);
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

		_URLEncodedScheme = [URL->_URLEncodedScheme copy];
		_URLEncodedHost = [URL->_URLEncodedHost copy];
		_port = [URL->_port copy];
		_URLEncodedUser = [URL->_URLEncodedUser copy];
		_URLEncodedPassword = [URL->_URLEncodedPassword copy];

		if ((UTF8String2 = of_strdup(string.UTF8String)) == NULL)
			@throw [OFOutOfMemoryException
			     exceptionWithRequestedSize:
			     string.UTF8StringLength];

		UTF8String = UTF8String2;

		if ((tmp = strchr(UTF8String, '#')) != NULL) {
			*tmp = '\0';
			_URLEncodedFragment = [[OFString alloc]
			    initWithUTF8String: tmp + 1];

			of_url_verify_escaped(_URLEncodedFragment,
			    [OFCharacterSet URLFragmentAllowedCharacterSet]);
		}

		if ((tmp = strchr(UTF8String, '?')) != NULL) {
			*tmp = '\0';
			_URLEncodedQuery = [[OFString alloc]
			    initWithUTF8String: tmp + 1];

			of_url_verify_escaped(_URLEncodedQuery,
			    [OFCharacterSet URLQueryAllowedCharacterSet]);
		}

		if (*UTF8String == '/')
			_URLEncodedPath = [[OFString alloc]
			    initWithUTF8String: UTF8String];
		else {
			OFString *relativePath =
			    [OFString stringWithUTF8String: UTF8String];

			if ([URL->_URLEncodedPath hasSuffix: @"/"])
				_URLEncodedPath = [[URL->_URLEncodedPath
				    stringByAppendingString: relativePath]
				    copy];
			else {
				OFMutableString *path = [OFMutableString
				    stringWithString:
				    (URL->_URLEncodedPath != nil
				    ? URL->_URLEncodedPath
				    : @"/")];
				of_range_t range = [path
				    rangeOfString: @"/"
					  options: OF_STRING_SEARCH_BACKWARDS];

				if (range.location == OF_NOT_FOUND)
					@throw [OFInvalidFormatException
					    exception];

				range.location++;
				range.length = path.length - range.location;

				[path replaceCharactersInRange: range
						    withString: relativePath];
				[path makeImmutable];

				_URLEncodedPath = [path copy];
			}
		}

		of_url_verify_escaped(_URLEncodedPath,
		    [OFCharacterSet URLPathAllowedCharacterSet]);

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
	bool isDirectory;

	@try {
		void *pool = objc_autoreleasePoolPush();

#if defined(OF_WINDOWS) || defined(OF_MSDOS)
		isDirectory = ([path hasSuffix: @"\\"] ||
		    [path hasSuffix: @"/"] ||
		    [OFFileURLHandler of_directoryExistsAtPath: path]);
#elif defined(OF_AMIGAOS)
		isDirectory = ([path hasSuffix: @"/"] ||
		    [path hasSuffix: @":"] ||
		    [OFFileURLHandler of_directoryExistsAtPath: path]);
#else
		isDirectory = ([path hasSuffix: @"/"] ||
		    [OFFileURLHandler of_directoryExistsAtPath: path]);
#endif

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	self = [self initFileURLWithPath: path
			     isDirectory: isDirectory];

	return self;
}

- (instancetype)initFileURLWithPath: (OFString *)path
			isDirectory: (bool)isDirectory
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		if (!path.absolutePath) {
			OFString *currentDirectoryPath = [OFFileManager
			    defaultManager].currentDirectoryPath;

			path = [currentDirectoryPath
			    stringByAppendingPathComponent: path];
			path = path.stringByStandardizingPath;
		}

#ifdef OF_WINDOWS
		if ([path hasPrefix: @"\\\\"]) {
			OFArray *components = path.pathComponents;

			if (components.count < 2)
				@throw [OFInvalidFormatException exception];

			_URLEncodedHost = [[[components objectAtIndex: 1]
			    stringByURLEncodingWithAllowedCharacters:
			    [OFCharacterSet URLHostAllowedCharacterSet]] copy];
			path = [OFString pathWithComponents:
			    [components objectsInRange:
			    of_range(2, components.count - 2)]];
		}
#endif

		path = pathToURLPath(path);

		if (isDirectory && ![path hasSuffix: @"/"])
			path = [path stringByAppendingString: @"/"];

		_URLEncodedScheme = @"file";
		_URLEncodedPath = [[path
		    stringByURLEncodingWithAllowedCharacters:
		    [OFCharacterSet URLPathAllowedCharacterSet]] copy];

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
		    ![element.namespace isEqual: OF_SERIALIZATION_NS])
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
	[_URLEncodedScheme release];
	[_URLEncodedHost release];
	[_port release];
	[_URLEncodedUser release];
	[_URLEncodedPassword release];
	[_URLEncodedPath release];
	[_URLEncodedQuery release];
	[_URLEncodedFragment release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFURL *URL;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFURL class]])
		return false;

	URL = object;

	if (URL->_URLEncodedScheme != _URLEncodedScheme &&
	    ![URL->_URLEncodedScheme isEqual: _URLEncodedScheme])
		return false;
	if (URL->_URLEncodedHost != _URLEncodedHost &&
	    ![URL->_URLEncodedHost isEqual: _URLEncodedHost])
		return false;
	if (URL->_port != _port && ![URL->_port isEqual: _port])
		return false;
	if (URL->_URLEncodedUser != _URLEncodedUser &&
	    ![URL->_URLEncodedUser isEqual: _URLEncodedUser])
		return false;
	if (URL->_URLEncodedPassword != _URLEncodedPassword &&
	    ![URL->_URLEncodedPassword isEqual: _URLEncodedPassword])
		return false;
	if (URL->_URLEncodedPath != _URLEncodedPath &&
	    ![URL->_URLEncodedPath isEqual: _URLEncodedPath])
		return false;
	if (URL->_URLEncodedQuery != _URLEncodedQuery &&
	    ![URL->_URLEncodedQuery isEqual: _URLEncodedQuery])
		return false;
	if (URL->_URLEncodedFragment != _URLEncodedFragment &&
	    ![URL->_URLEncodedFragment isEqual: _URLEncodedFragment])
		return false;

	return true;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, _URLEncodedScheme.hash);
	OF_HASH_ADD_HASH(hash, _URLEncodedHost.hash);
	OF_HASH_ADD_HASH(hash, _port.hash);
	OF_HASH_ADD_HASH(hash, _URLEncodedUser.hash);
	OF_HASH_ADD_HASH(hash, _URLEncodedPassword.hash);
	OF_HASH_ADD_HASH(hash, _URLEncodedPath.hash);
	OF_HASH_ADD_HASH(hash, _URLEncodedQuery.hash);
	OF_HASH_ADD_HASH(hash, _URLEncodedFragment.hash);

	OF_HASH_FINALIZE(hash);

	return hash;
}

- (OFString *)scheme
{
	return _URLEncodedScheme.stringByURLDecoding;
}

- (OFString *)URLEncodedScheme
{
	return _URLEncodedScheme;
}

- (OFString *)host
{
	return _URLEncodedHost.stringByURLDecoding;
}

- (OFString *)URLEncodedHost
{
	return _URLEncodedHost;
}

- (OFNumber *)port
{
	return _port;
}

- (OFString *)user
{
	return _URLEncodedUser.stringByURLDecoding;
}

- (OFString *)URLEncodedUser
{
	return _URLEncodedUser;
}

- (OFString *)password
{
	return _URLEncodedPassword.stringByURLDecoding;
}

- (OFString *)URLEncodedPassword
{
	return _URLEncodedPassword;
}

- (OFString *)path
{
	return _URLEncodedPath.stringByURLDecoding;
}

- (OFString *)URLEncodedPath
{
	return _URLEncodedPath;
}

- (OFArray *)pathComponents
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableArray *ret;
	size_t count;

#if defined(OF_WINDOWS) || defined(OF_MSDOS)
	if ([_URLEncodedScheme isEqual: @"file"]) {
		OFString *path = [_URLEncodedPath substringWithRange:
		    of_range(1, _URLEncodedPath.length - 1)];
		path = [path stringByReplacingOccurrencesOfString: @"/"
						       withString: @"\\"];
		ret = [[path.pathComponents mutableCopy] autorelease];
		[ret insertObject: @"/"
			  atIndex: 0];
	} else
#endif
		ret = [[[_URLEncodedPath componentsSeparatedByString: @"/"]
		    mutableCopy] autorelease];

	count = ret.count;

	if (count > 0 && [ret.firstObject length] == 0)
		[ret replaceObjectAtIndex: 0
			       withObject: @"/"];

	for (size_t i = 0; i < count; i++) {
		OFString *component = [ret objectAtIndex: i];
#if defined(OF_WINDOWS) || defined(OF_MSDOS)
		component = [component
		    stringByReplacingOccurrencesOfString: @"\\"
					      withString: @"/"];
#endif
		[ret replaceObjectAtIndex: i
			       withObject: component.stringByURLDecoding];
	}

	[ret makeImmutable];
	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (OFString *)lastPathComponent
{
	void *pool = objc_autoreleasePoolPush();
	OFString *path = _URLEncodedPath;
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
		path = [path substringWithRange: of_range(0, path.length - 1)];

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
	ret = [ret.stringByURLDecoding retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (OFString *)query
{
	return _URLEncodedQuery.stringByURLDecoding;
}

- (OFString *)URLEncodedQuery
{
	return _URLEncodedQuery;
}

- (OFString *)fragment
{
	return _URLEncodedFragment.stringByURLDecoding;
}

- (OFString *)URLEncodedFragment
{
	return _URLEncodedFragment;
}

- (id)copy
{
	return [self retain];
}

- (id)mutableCopy
{
	OFURL *copy = [[OFMutableURL alloc] init];

	@try {
		copy->_URLEncodedScheme = [_URLEncodedScheme copy];
		copy->_URLEncodedHost = [_URLEncodedHost copy];
		copy->_port = [_port copy];
		copy->_URLEncodedUser = [_URLEncodedUser copy];
		copy->_URLEncodedPassword = [_URLEncodedPassword copy];
		copy->_URLEncodedPath = [_URLEncodedPath copy];
		copy->_URLEncodedQuery = [_URLEncodedQuery copy];
		copy->_URLEncodedFragment = [_URLEncodedFragment copy];
	} @catch (id e) {
		[copy release];
		@throw e;
	}

	return copy;
}

- (OFString *)string
{
	OFMutableString *ret = [OFMutableString string];

	[ret appendFormat: @"%@://", _URLEncodedScheme];

	if (_URLEncodedUser != nil && _URLEncodedPassword != nil)
		[ret appendFormat: @"%@:%@@",
				   _URLEncodedUser, _URLEncodedPassword];
	else if (_URLEncodedUser != nil)
		[ret appendFormat: @"%@@", _URLEncodedUser];

	if (_URLEncodedHost != nil)
		[ret appendString: _URLEncodedHost];
	if (_port != nil)
		[ret appendFormat: @":%@", _port];

	if (_URLEncodedPath != nil) {
		if (![_URLEncodedPath hasPrefix: @"/"])
			@throw [OFInvalidFormatException exception];

		[ret appendString: _URLEncodedPath];
	}

	if (_URLEncodedQuery != nil)
		[ret appendFormat: @"?%@", _URLEncodedQuery];

	if (_URLEncodedFragment != nil)
		[ret appendFormat: @"#%@", _URLEncodedFragment];

	[ret makeImmutable];

	return ret;
}

#ifdef OF_HAVE_FILES
- (OFString *)fileSystemRepresentation
{
	void *pool = objc_autoreleasePoolPush();
	OFString *path;

	if (![_URLEncodedScheme isEqual: @"file"])
		@throw [OFInvalidArgumentException exception];

	if (![_URLEncodedPath hasPrefix: @"/"])
		@throw [OFInvalidFormatException exception];

	path = self.path;

#if !defined(OF_WINDOWS) && !defined(OF_MSDOS)
	if (path.length > 1 && [path hasSuffix: @"/"])
#else
	if (path.length > 1 && [path hasSuffix: @"/"] &&
	    ![path hasSuffix: @":/"])
#endif
		path = [path substringWithRange: of_range(0, path.length - 1)];

	path = URLPathToPath(path);

#ifdef OF_WINDOWS
	if (_URLEncodedHost != nil) {
		if (path.length == 0)
			path = [OFString stringWithFormat: @"\\\\%@",
							   self.host];
		else
			path = [OFString stringWithFormat: @"\\\\%@\\%@",
							   self.host, path];
	}
#endif

	[path retain];

	objc_autoreleasePoolPop(pool);

	return [path autorelease];
}
#endif

- (OFURL *)URLByAppendingPathComponent: (OFString *)component
{
	OFMutableURL *URL = [[self mutableCopy] autorelease];

	[URL appendPathComponent: component];
	[URL makeImmutable];

	return URL;
}

- (OFURL *)URLByAppendingPathComponent: (OFString *)component
			   isDirectory: (bool)isDirectory
{
	OFMutableURL *URL = [[self mutableCopy] autorelease];

	[URL appendPathComponent: component
		     isDirectory: isDirectory];
	[URL makeImmutable];

	return URL;
}

- (OFURL *)URLByStandardizingPath
{
	OFMutableURL *URL = [[self mutableCopy] autorelease];

	[URL standardizePath];
	[URL makeImmutable];

	return URL;
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
				      namespace: OF_SERIALIZATION_NS
				    stringValue: self.string];

	[element retain];

	objc_autoreleasePoolPop(pool);

	return [element autorelease];
}
@end
