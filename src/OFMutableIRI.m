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

#import "OFMutableIRI.h"
#import "OFIRI.h"
#import "OFIRI+Private.h"
#import "OFArray.h"
#import "OFDictionary.h"
#ifdef OF_HAVE_FILES
# import "OFFileManager.h"
#endif
#import "OFNumber.h"
#import "OFPair.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

@implementation OFMutableIRI
@dynamic scheme, host, percentEncodedHost, port, user, percentEncodedUser;
@dynamic password, percentEncodedPassword, path, percentEncodedPath;
@dynamic pathComponents, query, percentEncodedQuery, queryItems, fragment;
@dynamic percentEncodedFragment;

+ (instancetype)IRIWithScheme: (OFString *)scheme
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithScheme: scheme]);
}

- (instancetype)initWithScheme: (OFString *)scheme
{
	self = [self of_init];

	@try {
		self.scheme = scheme;
		_percentEncodedPath = @"";
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)setScheme: (OFString *)scheme
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _scheme;

	if (scheme.length < 1 || !OFASCIIIsAlpha(*scheme.UTF8String))
		@throw [OFInvalidFormatException exception];

	_OFIRIVerifyIsEscaped(scheme,
	    [OFCharacterSet IRISchemeAllowedCharacterSet], false);

	_scheme = [scheme.lowercaseString copy];

	objc_release(old);

	objc_autoreleasePoolPop(pool);
}

- (void)setHost: (OFString *)host
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _percentEncodedHost;

	if (_OFIRIIsIPv6Host(host))
		_percentEncodedHost = [[OFString alloc]
		    initWithFormat: @"[%@]", host];
	else
		_percentEncodedHost = [[host
		    stringByAddingPercentEncodingWithAllowedCharacters:
		    [OFCharacterSet IRIHostAllowedCharacterSet]] copy];

	objc_release(old);

	objc_autoreleasePoolPop(pool);
}

- (void)setPercentEncodedHost: (OFString *)percentEncodedHost
{
	OFString *old;

	if ([percentEncodedHost hasPrefix: @"["] &&
	    [percentEncodedHost hasSuffix: @"]"]) {
		if (!_OFIRIIsIPv6Host([percentEncodedHost substringWithRange:
		    OFMakeRange(1, percentEncodedHost.length - 2)]))
			@throw [OFInvalidFormatException exception];
	} else if (percentEncodedHost != nil)
		_OFIRIVerifyIsEscaped(percentEncodedHost,
		    [OFCharacterSet IRIHostAllowedCharacterSet], true);

	old = _percentEncodedHost;
	_percentEncodedHost = [percentEncodedHost copy];
	objc_release(old);
}

- (void)setPort: (OFNumber *)port
{
	OFNumber *old = _port;

	@try {
#if USHRT_MAX == 65535
		/* Range check */
		(void)port.unsignedShortValue;
#else
		if (port.unsignedShortValue > 65535)
			@throw [OFInvalidArgumentException exception];
#endif
	} @catch (OFOutOfRangeException *e) {
		@throw [OFInvalidArgumentException exception];
	}

	_port = [port copy];
	objc_release(old);
}

- (void)setUser: (OFString *)user
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _percentEncodedUser;

	_percentEncodedUser = [[user
	    stringByAddingPercentEncodingWithAllowedCharacters:
	    [OFCharacterSet IRIUserAllowedCharacterSet]] copy];

	objc_release(old);

	objc_autoreleasePoolPop(pool);
}

- (void)setPercentEncodedUser: (OFString *)percentEncodedUser
{
	OFString *old;

	if (percentEncodedUser != nil)
		_OFIRIVerifyIsEscaped(percentEncodedUser,
		    [OFCharacterSet IRIUserAllowedCharacterSet], true);

	old = _percentEncodedUser;
	_percentEncodedUser = [percentEncodedUser copy];
	objc_release(old);
}

- (void)setPassword: (OFString *)password
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _percentEncodedPassword;

	_percentEncodedPassword = [[password
	    stringByAddingPercentEncodingWithAllowedCharacters:
	    [OFCharacterSet IRIPasswordAllowedCharacterSet]] copy];

	objc_release(old);

	objc_autoreleasePoolPop(pool);
}

- (void)setPercentEncodedPassword: (OFString *)percentEncodedPassword
{
	OFString *old;

	if (percentEncodedPassword != nil)
		_OFIRIVerifyIsEscaped(percentEncodedPassword,
		    [OFCharacterSet IRIPasswordAllowedCharacterSet], true);

	old = _percentEncodedPassword;
	_percentEncodedPassword = [percentEncodedPassword copy];
	objc_release(old);
}

- (void)setPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _percentEncodedPath;

	_percentEncodedPath = [[path
	    stringByAddingPercentEncodingWithAllowedCharacters:
	    [OFCharacterSet IRIPathAllowedCharacterSet]] copy];

	objc_release(old);

	objc_autoreleasePoolPop(pool);
}

- (void)setPercentEncodedPath: (OFString *)percentEncodedPath
{
	OFString *old;

	_OFIRIVerifyIsEscaped(percentEncodedPath,
	    [OFCharacterSet IRIPathAllowedCharacterSet], true);

	old = _percentEncodedPath;
	_percentEncodedPath = [percentEncodedPath copy];
	objc_release(old);
}

- (void)setPathComponents: (OFArray *)components
{
	void *pool = objc_autoreleasePoolPush();

	if (components.count == 0)
		@throw [OFInvalidFormatException exception];

	if ([components.firstObject isEqual: @"/"]) {
		OFMutableArray *mutComponents =
		    objc_autorelease([components mutableCopy]);
		[mutComponents replaceObjectAtIndex: 0 withObject: @""];
		components = mutComponents;
	}

	self.path = [components componentsJoinedByString: @"/"];

	objc_autoreleasePoolPop(pool);
}

- (void)setQuery: (OFString *)query
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _percentEncodedQuery;

	_percentEncodedQuery = [[query
	    stringByAddingPercentEncodingWithAllowedCharacters:
	    [OFCharacterSet IRIQueryAllowedCharacterSet]] copy];

	objc_release(old);

	objc_autoreleasePoolPop(pool);
}

- (void)setPercentEncodedQuery: (OFString *)percentEncodedQuery
{
	OFString *old;

	if (percentEncodedQuery != nil)
		_OFIRIVerifyIsEscaped(percentEncodedQuery,
		    [OFCharacterSet IRIQueryAllowedCharacterSet], true);

	old = _percentEncodedQuery;
	_percentEncodedQuery = [percentEncodedQuery copy];
	objc_release(old);
}

- (void)setQueryItems:
    (OFArray OF_GENERIC(OFPair OF_GENERIC(OFString *, OFString *) *) *)
    queryItems
{
	void *pool;
	OFMutableString *percentEncodedQuery;
	OFCharacterSet *characterSet;
	OFString *old;

	if (queryItems == nil) {
		objc_release(_percentEncodedQuery);
		_percentEncodedQuery = nil;
		return;
	}

	pool = objc_autoreleasePoolPush();
	percentEncodedQuery = [OFMutableString string];
	characterSet = [OFCharacterSet IRIQueryKeyValueAllowedCharacterSet];

	for (OFPair OF_GENERIC(OFString *, OFString *) *item in queryItems) {
		OFString *key = [item.firstObject
		    stringByAddingPercentEncodingWithAllowedCharacters:
		    characterSet];
		OFString *value = [item.secondObject
		    stringByAddingPercentEncodingWithAllowedCharacters:
		    characterSet];

		if (percentEncodedQuery.length > 0)
			[percentEncodedQuery appendString: @"&"];

		[percentEncodedQuery appendFormat: @"%@=%@", key, value];
	}

	old = _percentEncodedQuery;
	_percentEncodedQuery = [percentEncodedQuery copy];
	objc_release(old);

	objc_autoreleasePoolPop(pool);
}

- (void)setFragment: (OFString *)fragment
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _percentEncodedFragment;

	_percentEncodedFragment = [[fragment
	    stringByAddingPercentEncodingWithAllowedCharacters:
	    [OFCharacterSet IRIFragmentAllowedCharacterSet]] copy];

	objc_release(old);

	objc_autoreleasePoolPop(pool);
}

- (void)setPercentEncodedFragment: (OFString *)percentEncodedFragment
{
	OFString *old;

	if (percentEncodedFragment != nil)
		_OFIRIVerifyIsEscaped(percentEncodedFragment,
		    [OFCharacterSet IRIFragmentAllowedCharacterSet], true);

	old = _percentEncodedFragment;
	_percentEncodedFragment = [percentEncodedFragment copy];
	objc_release(old);
}

- (id)copy
{
	OFMutableIRI *copy = [self mutableCopy];

	[copy makeImmutable];

	return copy;
}

- (void)appendPathComponent: (OFString *)component
{
	[self appendPathComponent: component isDirectory: false];

#ifdef OF_HAVE_FILES
	if ([_scheme isEqual: @"file"] &&
	    ![_percentEncodedPath hasSuffix: @"/"] &&
	    [[OFFileManager defaultManager] directoryExistsAtIRI: self]) {
		OFString *path = objc_retain(
		    [_percentEncodedPath stringByAppendingString: @"/"]);
		objc_release(_percentEncodedPath);
		_percentEncodedPath = path;
	}
#endif
}

- (void)appendPathComponent: (OFString *)component
		isDirectory: (bool)isDirectory
{
	void *pool;
	OFString *path;

	if ([component isEqual: @"/"] && [_percentEncodedPath hasSuffix: @"/"])
		return;

	pool = objc_autoreleasePoolPush();
	component = [component
	    stringByAddingPercentEncodingWithAllowedCharacters:
	    [OFCharacterSet IRIPathAllowedCharacterSet]];

#if defined(OF_WINDOWS) || defined(OF_MSDOS)
	if ([_percentEncodedPath hasSuffix: @"/"] ||
	    ([_scheme isEqual: @"file"] &&
	    [_percentEncodedPath hasSuffix: @":"]))
#else
	if ([_percentEncodedPath hasSuffix: @"/"])
#endif
		path = [_percentEncodedPath stringByAppendingString: component];
	else
		path = [_percentEncodedPath
		    stringByAppendingFormat: @"/%@", component];

	if (isDirectory && ![path hasSuffix: @"/"])
		path = [path stringByAppendingString: @"/"];

	objc_release(_percentEncodedPath);
	_percentEncodedPath = objc_retain(path);

	objc_autoreleasePoolPop(pool);
}

- (void)appendPathExtension: (OFString *)extension
{
	void *pool;
	OFMutableString *path;
	bool isDirectory = false;

	if (_percentEncodedPath.length == 0)
		return;

	pool = objc_autoreleasePoolPush();
	path = objc_autorelease([_percentEncodedPath mutableCopy]);

	extension = [extension
	    stringByAddingPercentEncodingWithAllowedCharacters:
	    [OFCharacterSet IRIPathAllowedCharacterSet]];

	if ([path hasSuffix: @"/"]) {
		[path deleteCharactersInRange: OFMakeRange(path.length - 1, 1)];
		isDirectory = true;
	}

	[path appendFormat: @".%@", extension];

	if (isDirectory)
		[path appendString: @"/"];

	[path makeImmutable];
	objc_release(_percentEncodedPath);
	_percentEncodedPath = objc_retain(path);

	objc_autoreleasePoolPop(pool);
}

- (void)deleteLastPathComponent
{
	void *pool = objc_autoreleasePoolPush();
	OFString *path = _percentEncodedPath;
	size_t pos;

	if (path.length == 0 || [path isEqual: @"/"]) {
		objc_autoreleasePoolPop(pool);
		return;
	}

	if ([path hasSuffix: @"/"])
		path = [path substringToIndex: path.length - 1];

	pos = [path rangeOfString: @"/"
			  options: OFStringSearchBackwards].location;
	if (pos == OFNotFound) {
		objc_autoreleasePoolPop(pool);
		return;
	}

	path = [path substringToIndex: pos + 1];
	objc_release(_percentEncodedPath);
	_percentEncodedPath = objc_retain(path);

	objc_autoreleasePoolPop(pool);
}

- (void)deletePathExtension
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableString *path =
	    objc_autorelease([_percentEncodedPath mutableCopy]);
	bool isDirectory = false;
	size_t pos;

	if ([path hasSuffix: @"/"]) {
		[path deleteCharactersInRange: OFMakeRange(path.length - 1, 1)];
		isDirectory = true;
	}

	pos = [path rangeOfString: @"."
			  options: OFStringSearchBackwards].location;
	if (pos == OFNotFound) {
		objc_autoreleasePoolPop(pool);
		return;
	}

	[path deleteCharactersInRange: OFMakeRange(pos, path.length - pos)];

	if (isDirectory)
		[path appendString: @"/"];

	[path makeImmutable];
	objc_release(_percentEncodedPath);
	_percentEncodedPath = objc_retain(path);

	objc_autoreleasePoolPop(pool);
}

- (void)standardizePath
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableArray OF_GENERIC(OFString *) *array;
	bool done = false, startsWithEmpty, endsWithEmpty;
	OFString *path;

	array = objc_autorelease([[_percentEncodedPath
	    componentsSeparatedByString: @"/"] mutableCopy]);

	endsWithEmpty = ([array.lastObject length] == 0);
	startsWithEmpty = ([array.firstObject length] == 0);

	while (!done) {
		size_t length = array.count;

		done = true;

		for (size_t i = 0; i < length; i++) {
			OFString *current = [array objectAtIndex: i];
			OFString *parent =
			    (i > 0 ? [array objectAtIndex: i - 1] : nil);

			if ([current isEqual: @"."] || current.length == 0) {
				[array removeObjectAtIndex: i];

				done = false;
				break;
			}

			if ([current isEqual: @".."] && parent != nil &&
			    ![parent isEqual: @".."]) {
				[array removeObjectsInRange:
				    OFMakeRange(i - 1, 2)];

				done = false;
				break;
			}
		}
	}

	if (startsWithEmpty)
		[array insertObject: @"" atIndex: 0];
	if (endsWithEmpty)
		[array addObject: @""];

	path = [array componentsJoinedByString: @"/"];
	if (startsWithEmpty && path.length == 0)
		path = @"/";

	self.percentEncodedPath = path;

	objc_autoreleasePoolPop(pool);
}

- (void)makeImmutable
{
	object_setClass(self, [OFIRI class]);
}
@end
