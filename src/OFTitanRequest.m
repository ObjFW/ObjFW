/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFTitanRequest.h"
#import "OFArray.h"
#import "OFCharacterSet.h"
#import "OFIRI.h"

#import "OFInvalidArgumentException.h"

@interface OFTitanPathAllowedCharacterSet: OFCharacterSet
{
	OFCharacterSet *_characterSet;
	bool (*_characterIsMember)(id, SEL, OFUnichar);
}
@end

static OFCharacterSet *pathAllowedCharacters;

static OFString *
parameterForName(OFString *path, OFString *name)
{
	OFArray *components;
	size_t count;
	OFString *prefix;

	name = [name stringByAddingPercentEncodingWithAllowedCharacters:
	    pathAllowedCharacters];

	components = [path componentsSeparatedByString: @";"];
	count = components.count;
	if (count == 1)
		return nil;

	prefix = [name stringByAppendingString: @"="];
	for (size_t i = 1; i < count; i++) {
		OFString *component = [components objectAtIndex: i];

		if ([component hasPrefix: prefix])
			return [component substringFromIndex: prefix.length]
			    .stringByRemovingPercentEncoding;
	}

	return nil;
}

static OFString *
setParameter(OFString *path, OFString *name, OFString *value)
{
	OFMutableArray *components;
	size_t count;
	OFString *prefix;
	bool found;

	name = [name stringByAddingPercentEncodingWithAllowedCharacters:
	    pathAllowedCharacters];
	value = [value stringByAddingPercentEncodingWithAllowedCharacters:
	    pathAllowedCharacters];

	components = objc_autorelease(
	    [[path componentsSeparatedByString: @";"] mutableCopy]);
	count = components.count;
	if (count == 1)
		return [path stringByAppendingFormat: @";%@=%@", name, value];

	prefix = [name stringByAppendingString: @"="];
	found = false;
	for (size_t i = 1; i < count; i++) {
		OFString *component = [components objectAtIndex: i];

		if (![component hasPrefix: prefix])
			continue;

		if (value != nil) {
			component =
			    [OFString stringWithFormat: @"%@=%@", name, value];
			[components replaceObjectAtIndex: i
					      withObject: component];
		} else
			[components removeObjectAtIndex: i];

		found = true;
		break;
	}

	if (!found && value != nil)
		[components addObject:
		    [OFString stringWithFormat: @"%@=%@", name, value]];

	return [components componentsJoinedByString: @";"];
}

@implementation OFTitanRequest
+ (void)initialize
{
	if (self != [OFTitanRequest class])
		return;

	pathAllowedCharacters = [[OFTitanPathAllowedCharacterSet alloc] init];
}

- (unsigned long long)uploadSize
{
	void *pool = objc_autoreleasePoolPush();
	OFString *uploadSize;
	unsigned long long ret;

	if (![_IRI.scheme isEqual: @"titan"])
		@throw [OFInvalidArgumentException exception];

	uploadSize = parameterForName(_IRI.percentEncodedPath, @"size");
	if (uploadSize == nil)
		@throw [OFInvalidArgumentException exception];

	ret = uploadSize.unsignedLongLongValue;

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (void)setUploadSize: (unsigned long long)uploadSize
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableIRI *IRI;

	if (![_IRI.scheme isEqual: @"titan"])
		@throw [OFInvalidArgumentException exception];

	IRI = objc_autorelease([_IRI mutableCopy]);
	IRI.percentEncodedPath = setParameter(IRI.percentEncodedPath, @"size",
	    [OFString stringWithFormat: @"%llu", uploadSize]);
	[IRI makeImmutable];
	self.IRI = IRI;

	objc_autoreleasePoolPop(pool);
}

- (OFString *)uploadMIMEType
{
	void *pool = objc_autoreleasePoolPush();
	OFString *ret;

	if (![_IRI.scheme isEqual: @"titan"])
		@throw [OFInvalidArgumentException exception];

	ret = objc_retain(parameterForName(_IRI.percentEncodedPath, @"mime"));

	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(ret);
}

- (void)setUploadMIMEType: (OFString *)uploadMIMEType
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableIRI *IRI;

	if (![_IRI.scheme isEqual: @"titan"])
		@throw [OFInvalidArgumentException exception];

	IRI = objc_autorelease([_IRI mutableCopy]);
	IRI.percentEncodedPath = setParameter(IRI.percentEncodedPath, @"mime",
	    uploadMIMEType);
	[IRI makeImmutable];
	self.IRI = IRI;

	objc_autoreleasePoolPop(pool);
}

- (OFString *)uploadToken
{
	void *pool = objc_autoreleasePoolPush();
	OFString *ret;

	if (![_IRI.scheme isEqual: @"titan"])
		@throw [OFInvalidArgumentException exception];

	ret = objc_retain(parameterForName(_IRI.percentEncodedPath, @"token"));

	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(ret);
}

- (void)setUploadToken: (OFString *)uploadToken
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableIRI *IRI;

	if (![_IRI.scheme isEqual: @"titan"])
		@throw [OFInvalidArgumentException exception];

	IRI = objc_autorelease([_IRI mutableCopy]);
	IRI.percentEncodedPath = setParameter(IRI.percentEncodedPath, @"token",
	    uploadToken);
	[IRI makeImmutable];
	self.IRI = IRI;

	objc_autoreleasePoolPop(pool);
}
@end

@implementation OFTitanPathAllowedCharacterSet
- (instancetype)init
{
	self = [super init];

	@try {
		_characterSet = objc_retain(
		    [OFCharacterSet IRIPathAllowedCharacterSet]);
		_characterIsMember = (bool (*)(id, SEL, OFUnichar))
		    [_characterSet methodForSelector:
		    @selector(characterIsMember:)];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_characterSet);

	[super dealloc];
}

- (bool)characterIsMember: (OFUnichar)character
{
	return (character != ';' && _characterIsMember(_characterSet,
	    @selector(characterIsMember:), character));
}
@end
