/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#import "OFHTTPCookie.h"
#import "OFArray.h"
#import "OFDate.h"
#import "OFDictionary.h"
#import "OFURL.h"

#import "OFInvalidFormatException.h"

static void
handleAttribute(OFHTTPCookie *cookie, OFString *name, OFString *value)
{
	OFString *lowercaseName = name.lowercaseString;

	if (value != nil) {
		if ([lowercaseName isEqual: @"expires"]) {
			OFDate *date = [OFDate
			    dateWithDateString: value
					format: @"%a, %d %b %Y %H:%M:%S %z"];
			cookie.expires = date;
		} else if ([lowercaseName isEqual: @"max-age"]) {
			OFDate *date = [OFDate dateWithTimeIntervalSinceNow:
			    value.unsignedLongLongValue];
			cookie.expires = date;
		} else if ([lowercaseName isEqual: @"domain"])
			cookie.domain = value;
		else if ([lowercaseName isEqual: @"path"])
			cookie.path = value;
		else
			[cookie.extensions addObject:
			    [OFString stringWithFormat: @"%@=%@", name, value]];
	} else {
		if ([lowercaseName isEqual: @"secure"])
			cookie.secure = true;
		else if ([lowercaseName isEqual: @"httponly"])
			cookie.HTTPOnly = true;
		else if (name.length > 0)
			[cookie.extensions addObject: name];
	}
}

@implementation OFHTTPCookie
@synthesize name = _name, value = _value, domain = _domain, path = _path;
@synthesize expires = _expires, secure = _secure, HTTPOnly = _HTTPOnly;
@synthesize extensions = _extensions;

+ (OFArray OF_GENERIC(OFHTTPCookie *) *)cookiesWithResponseHeaderFields:
    (OFDictionary OF_GENERIC(OFString *, OFString *) *)headerFields
    forURL: (OFURL *)URL
{
	OFMutableArray OF_GENERIC(OFHTTPCookie *) *ret = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();
	OFString *string = [headerFields objectForKey: @"Set-Cookie"];
	OFString *domain = URL.host;
	const OFUnichar *characters = string.characters;
	size_t length = string.length, last = 0;
	enum {
		StatePreName,
		StateName,
		StateExpectValue,
		StateValue,
		StateQuotedValue,
		StatePostQuotedValue,
		StatePreAttrName,
		StateAttrName,
		StateAttrValue
	} state = StatePreName;
	OFString *name = nil, *value = nil;

	for (size_t i = 0; i < length; i++) {
		switch (state) {
		case StatePreName:
			if (characters[i] != ' ') {
				state = StateName;
				last = i;
				i--;
			}
			break;
		case StateName:
			if (characters[i] == '=') {
				name = [string substringWithRange:
				    OFRangeMake(last, i - last)];
				state = StateExpectValue;
			}
			break;
		case StateExpectValue:
			if (characters[i] == '"') {
				state = StateQuotedValue;
				last = i + 1;
			} else {
				state = StateValue;
				last = i;
			}

			i--;
			break;
		case StateValue:
			if (characters[i] == ';' || characters[i] == ',') {
				value = [string substringWithRange:
				    OFRangeMake(last, i - last)];

				[ret addObject:
				    [OFHTTPCookie cookieWithName: name
							   value: value
							  domain: domain]];

				state = (characters[i] == ';'
				    ? StatePreAttrName : StatePreName);
			}
			break;
		case StateQuotedValue:
			if (characters[i] == '"') {
				value = [string substringWithRange:
				    OFRangeMake(last, i - last)];
				[ret addObject:
				    [OFHTTPCookie cookieWithName: name
							   value: value
							  domain: domain]];

				state = StatePostQuotedValue;
			}
			break;
		case StatePostQuotedValue:
			if (characters[i] == ';')
				state = StatePreAttrName;
			else if (characters[i] == ',')
				state = StatePreName;
			else
				@throw [OFInvalidFormatException exception];

			break;
		case StatePreAttrName:
			if (characters[i] != ' ') {
				state = StateAttrName;
				last = i;
				i--;
			}
			break;
		case StateAttrName:
			if (characters[i] == '=') {
				name = [string substringWithRange:
				    OFRangeMake(last, i - last)];

				state = StateAttrValue;
				last = i + 1;
			} else if (characters[i] == ';' ||
			    characters[i] == ',') {
				name = [string substringWithRange:
				    OFRangeMake(last, i - last)];

				handleAttribute(ret.lastObject, name, nil);

				state = (characters[i] == ';'
				    ? StatePreAttrName : StatePreName);
			}

			break;
		case StateAttrValue:
			if (characters[i] == ';' || characters[i] == ',') {
				value = [string substringWithRange:
				    OFRangeMake(last, i - last)];

				/*
				 * Expires often contains a comma, even though
				 * the comma is used as a separator for
				 * concatenating headers as per RFC 2616,
				 * meaning RFC 6265 contradicts RFC 2616.
				 * Solve this by special casing this.
				 */
				if (characters[i] == ',' &&
				    [name caseInsensitiveCompare: @"expires"] ==
				    OFOrderedSame && value.length == 3 &&
				    ([value isEqual: @"Mon"] ||
				    [value isEqual: @"Tue"] ||
				    [value isEqual: @"Wed"] ||
				    [value isEqual: @"Thu"] ||
				    [value isEqual: @"Fri"] ||
				    [value isEqual: @"Sat"] ||
				    [value isEqual: @"Sun"]))
					break;

				handleAttribute(ret.lastObject, name, value);

				state = (characters[i] == ';'
				    ? StatePreAttrName : StatePreName);
			}
			break;
		}
	}

	switch (state) {
	case StatePreName:
	case StatePostQuotedValue:
	case StatePreAttrName:
		break;
	case StateName:
	case StateQuotedValue:
		@throw [OFInvalidFormatException exception];
		break;
	case StateValue:
		value = [string substringWithRange:
		    OFRangeMake(last, length - last)];
		[ret addObject: [OFHTTPCookie cookieWithName: name
						       value: value
						      domain: domain]];
		break;
	/* We end up here if the cookie is just foo= */
	case StateExpectValue:
		[ret addObject: [OFHTTPCookie cookieWithName: name
						       value: @""
						      domain: domain]];
		break;
	case StateAttrName:
		if (last != length) {
			name = [string substringWithRange:
			    OFRangeMake(last, length - last)];

			handleAttribute(ret.lastObject, name, nil);
		}
		break;
	case StateAttrValue:
		value = [string substringWithRange:
		    OFRangeMake(last, length - last)];

		handleAttribute(ret.lastObject, name, value);

		break;
	}

	objc_autoreleasePoolPop(pool);

	return ret;
}

+ (OFDictionary *)requestHeaderFieldsWithCookies:
    (OFArray OF_GENERIC(OFHTTPCookie *) *)cookies
{
	OFDictionary OF_GENERIC(OFString *, OFString *) *ret;
	void *pool;
	OFMutableString *cookieString;
	bool first = true;

	if (cookies.count == 0)
		return [OFDictionary dictionary];

	pool = objc_autoreleasePoolPush();
	cookieString = [OFMutableString string];

	for (OFHTTPCookie *cookie in cookies) {
		if OF_UNLIKELY (first)
			first = false;
		else
			[cookieString appendString: @"; "];

		[cookieString appendString: cookie.name];
		[cookieString appendString: @"="];
		[cookieString appendString: cookie.value];
	}

	ret = [[OFDictionary alloc] initWithObject: cookieString
					    forKey: @"Cookie"];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

+ (instancetype)cookieWithName: (OFString *)name
			 value: (OFString *)value
			domain: (OFString *)domain
{
	return [[[self alloc] initWithName: name
				     value: value
				    domain: domain] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		       value: (OFString *)value
		      domain: (OFString *)domain
{
	self = [super init];

	@try {
		_name = [name copy];
		_value = [value copy];
		_domain = [domain copy];
		_path = @"/";
		_extensions = [[OFMutableArray alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_name release];
	[_value release];
	[_domain release];
	[_path release];
	[_expires release];
	[_extensions release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFHTTPCookie *cookie;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFHTTPCookie class]])
		return false;

	cookie = object;

	if (![cookie->_name isEqual: _name])
		return false;
	if (![cookie->_value isEqual: _value])
		return false;
	if (cookie->_domain != _domain && ![cookie->_domain isEqual: _domain])
		return false;
	if (cookie->_path != _path && ![cookie->_path isEqual: _path])
		return false;
	if (cookie->_expires != _expires &&
	    ![cookie->_expires isEqual: _expires])
		return false;
	if (cookie->_secure != _secure)
		return false;
	if (cookie->_HTTPOnly != _HTTPOnly)
		return false;
	if (cookie->_extensions != _extensions &&
	    ![cookie->_extensions isEqual: _extensions])
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);
	OFHashAddHash(&hash, _name.hash);
	OFHashAddHash(&hash, _value.hash);
	OFHashAddHash(&hash, _domain.hash);
	OFHashAddHash(&hash, _path.hash);
	OFHashAddHash(&hash, _expires.hash);
	OFHashAdd(&hash, _secure);
	OFHashAdd(&hash, _HTTPOnly);
	OFHashAddHash(&hash, _extensions.hash);
	OFHashFinalize(&hash);

	return hash;
}

- (id)copy
{
	OFHTTPCookie *copy = [[OFHTTPCookie alloc] initWithName: _name
							  value: _value
							 domain: _domain];

	@try {
		copy->_path = [_path copy];
		copy->_expires = [_expires copy];
		copy->_secure = _secure;
		copy->_HTTPOnly = _HTTPOnly;
		[copy->_extensions addObjectsFromArray: _extensions];
	} @catch (id e) {
		[copy release];
		@throw e;
	}

	return copy;
}

- (OFString *)description
{
	OFMutableString *ret = [OFMutableString
	    stringWithFormat: @"%@=%@", _name, _value];
	void *pool = objc_autoreleasePoolPush();

	[ret appendFormat: @"; Domain=%@; Path=%@", _domain, _path];

	if (_expires != nil)
		[ret appendString:
		    [_expires dateStringWithFormat: @"; Expires=%a, %d %b %Y "
						    @"%H:%M:%S +0000"]];

	if (_secure)
		[ret appendString: @"; Secure"];

	if (_HTTPOnly)
		[ret appendString: @"; HTTPOnly"];

	if (_extensions.count > 0)
		[ret appendFormat:
		    @"; %@", [_extensions componentsJoinedByString: @"; "]];

	objc_autoreleasePoolPop(pool);

	[ret makeImmutable];

	return ret;
}
@end
