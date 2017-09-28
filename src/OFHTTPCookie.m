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

#import "OFHTTPCookie.h"
#import "OFArray.h"
#import "OFDate.h"
#import "OFDictionary.h"
#import "OFURL.h"

#import "OFInvalidFormatException.h"

static void
handleAttribute(OFHTTPCookie *cookie, OFString *name, OFString *value)
{
	OFString *lowerName = [name lowercaseString];

	if (value != nil) {
		if ([lowerName isEqual: @"expires"]) {
			OFDate *date = [OFDate
			    dateWithDateString: value
					format: @"%a, %d %b %Y %H:%M:%S %z"];
			[cookie setExpires: date];
		} else if ([lowerName isEqual: @"max-age"]) {
			OFDate *date = [OFDate dateWithTimeIntervalSinceNow:
			    [value decimalValue]];
			[cookie setExpires: date];
		} else if ([lowerName isEqual: @"domain"])
			[cookie setDomain: value];
		else if ([lowerName isEqual: @"path"])
			[cookie setPath: value];
		else
			[[cookie extensions] addObject:
			    [OFString stringWithFormat: @"%@=%@", name, value]];
	} else {
		if ([lowerName isEqual: @"secure"])
			[cookie setSecure: true];
		else if ([lowerName isEqual: @"httponly"])
			[cookie setHTTPOnly: true];
		else if ([name length] > 0)
			[[cookie extensions] addObject: name];
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
	OFString *domain = [URL host];
	const of_unichar_t *characters = [string characters];
	size_t length = [string length], last = 0;
	enum {
		STATE_PRE_NAME,
		STATE_NAME,
		STATE_EXPECT_VALUE,
		STATE_VALUE,
		STATE_QUOTED_VALUE,
		STATE_POST_QUOTED_VALUE,
		STATE_PRE_ATTR_NAME,
		STATE_ATTR_NAME,
		STATE_ATTR_VALUE
	} state = STATE_PRE_NAME;
	OFString *name = nil, *value = nil;

	for (size_t i = 0; i < length; i++) {
		switch (state) {
		case STATE_PRE_NAME:
			if (characters[i] != ' ') {
				state = STATE_NAME;
				last = i;
				i--;
			}
			break;
		case STATE_NAME:
			if (characters[i] == '=') {
				name = [string substringWithRange:
				    of_range(last, i - last)];
				state = STATE_EXPECT_VALUE;
			}
			break;
		case STATE_EXPECT_VALUE:
			if (characters[i] == '"') {
				state = STATE_QUOTED_VALUE;
				last = i + 1;
			} else {
				state = STATE_VALUE;
				last = i;
			}

			i--;
			break;
		case STATE_VALUE:
			if (characters[i] == ';' || characters[i] == ',') {
				value = [string substringWithRange:
				    of_range(last, i - last)];

				[ret addObject:
				    [OFHTTPCookie cookieWithName: name
							   value: value
							  domain: domain]];

				state = (characters[i] == ';'
				    ? STATE_PRE_ATTR_NAME : STATE_PRE_NAME);
			}
			break;
		case STATE_QUOTED_VALUE:
			if (characters[i] == '"') {
				value = [string substringWithRange:
				    of_range(last, i - last)];
				[ret addObject:
				    [OFHTTPCookie cookieWithName: name
							   value: value
							  domain: domain]];

				state = STATE_POST_QUOTED_VALUE;
			}
			break;
		case STATE_POST_QUOTED_VALUE:
			if (characters[i] == ';')
				state = STATE_PRE_ATTR_NAME;
			else if (characters[i] == ',')
				state = STATE_PRE_NAME;
			else
				@throw [OFInvalidFormatException exception];

			break;
		case STATE_PRE_ATTR_NAME:
			if (characters[i] != ' ') {
				state = STATE_ATTR_NAME;
				last = i;
				i--;
			}
			break;
		case STATE_ATTR_NAME:
			if (characters[i] == '=') {
				name = [string substringWithRange:
				    of_range(last, i - last)];

				state = STATE_ATTR_VALUE;
				last = i + 1;
			} else if (characters[i] == ';' ||
			    characters[i] == ',') {
				name = [string substringWithRange:
				    of_range(last, i - last)];

				handleAttribute([ret lastObject], name, nil);

				state = (characters[i] == ';'
				    ? STATE_PRE_ATTR_NAME : STATE_PRE_NAME);
			}

			break;
		case STATE_ATTR_VALUE:
			if (characters[i] == ';' || characters[i] == ',') {
				value = [string substringWithRange:
				    of_range(last, i - last)];

				/*
				 * Expires often contains a comma, even though
				 * the comma is used as a separator for
				 * concatenating headers as per RFC 2616,
				 * meaning RFC 6265 contradicts RFC 2616.
				 * Solve this by special casing this.
				 */
				if (characters[i] == ',' &&
				    [name caseInsensitiveCompare: @"expires"] ==
				    OF_ORDERED_SAME && [value length] == 3 &&
				    ([value isEqual: @"Mon"] ||
				    [value isEqual: @"Tue"] ||
				    [value isEqual: @"Wed"] ||
				    [value isEqual: @"Thu"] ||
				    [value isEqual: @"Fri"] ||
				    [value isEqual: @"Sat"] ||
				    [value isEqual: @"Sun"]))
					break;

				handleAttribute([ret lastObject], name, value);

				state = (characters[i] == ';'
				    ? STATE_PRE_ATTR_NAME : STATE_PRE_NAME);
			}
			break;
		}
	}

	switch (state) {
	case STATE_PRE_NAME:
	case STATE_POST_QUOTED_VALUE:
	case STATE_PRE_ATTR_NAME:
		break;
	case STATE_NAME:
	case STATE_QUOTED_VALUE:
		@throw [OFInvalidFormatException exception];
		break;
	case STATE_VALUE:
		value = [string substringWithRange:
		    of_range(last, length - last)];
		[ret addObject: [OFHTTPCookie cookieWithName: name
						       value: value
						      domain: domain]];
		break;
	/* We end up here if the cookie is just foo= */
	case STATE_EXPECT_VALUE:
		[ret addObject: [OFHTTPCookie cookieWithName: name
						       value: @""
						      domain: domain]];
		break;
	case STATE_ATTR_NAME:
		if (last != length) {
			name = [string substringWithRange:
			    of_range(last, length - last)];

			handleAttribute([ret lastObject], name, nil);
		}
		break;
	case STATE_ATTR_VALUE:
		value = [string substringWithRange:
		    of_range(last, length - last)];

		handleAttribute([ret lastObject], name, value);

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

	if ([cookies count] == 0)
		return [OFDictionary dictionary];

	pool = objc_autoreleasePoolPush();
	cookieString = [OFMutableString string];

	for (OFHTTPCookie *cookie in cookies) {
		if OF_UNLIKELY (first)
			first = false;
		else
			[cookieString appendString: @"; "];

		[cookieString appendString: [cookie name]];
		[cookieString appendString: @"="];
		[cookieString appendString: [cookie value]];
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

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithName: (OFString *)name
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

- (bool)isEqual: (id)otherObject
{
	OFHTTPCookie *other;

	if (![otherObject isKindOfClass: [OFHTTPCookie class]])
		return false;

	other = otherObject;

	if (![_name isEqual: other->_name])
		return false;
	if (![_value isEqual: other->_value])
		return false;
	if (_domain != other->_domain && ![_domain isEqual: other->_domain])
		return false;
	if (_path != other->_path && ![_path isEqual: other->_path])
		return false;
	if (_expires != other->_expires && ![_expires isEqual: other->_expires])
		return false;
	if (_secure != other->_secure)
		return false;
	if (_HTTPOnly != other->_HTTPOnly)
		return false;
	if (_extensions != other->_extensions &&
	    ![_extensions isEqual: other->_extensions])
		return false;

	return true;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);
	OF_HASH_ADD_HASH(hash, [_name hash]);
	OF_HASH_ADD_HASH(hash, [_value hash]);
	OF_HASH_ADD_HASH(hash, [_domain hash]);
	OF_HASH_ADD_HASH(hash, [_path hash]);
	OF_HASH_ADD_HASH(hash, [_expires hash]);
	OF_HASH_ADD(hash, _secure);
	OF_HASH_ADD(hash, _HTTPOnly);
	OF_HASH_ADD_HASH(hash, [_extensions hash]);
	OF_HASH_FINALIZE(hash);

	return hash;
}

- copy
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
		[ret appendString: [(OFDate *)_expires
		    dateStringWithFormat: @"; Expires=%a, %d %b %Y "
					  @"%H:%M:%S +0000"]];

	if (_secure)
		[ret appendString: @"; Secure"];

	if (_HTTPOnly)
		[ret appendString: @"; HTTPOnly"];

	if ([_extensions count] > 0)
		[ret appendFormat:
		    @"; %@", [_extensions componentsJoinedByString: @"; "]];

	objc_autoreleasePoolPop(pool);

	[ret makeImmutable];

	return ret;
}
@end
