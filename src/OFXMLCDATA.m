/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

#import "OFXMLCDATA.h"
#import "OFXMLNode+Private.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"

@implementation OFXMLCDATA
+ (instancetype)CDATAWithString: (OFString *)string
{
	return [[[self alloc] initWithString: string] autorelease];
}

- (instancetype)initWithString: (OFString *)string
{
	self = [super of_init];

	@try {
		_CDATA = [string copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_CDATA release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFXMLCDATA *CDATA;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFXMLCDATA class]])
		return false;

	CDATA = object;

	return ([CDATA->_CDATA isEqual: _CDATA]);
}

- (unsigned long)hash
{
	return _CDATA.hash;
}

- (OFString *)stringValue
{
	return [[_CDATA copy] autorelease];
}

- (void)setStringValue: (OFString *)stringValue
{
	OFString *old = _CDATA;
	_CDATA = [stringValue copy];
	[old release];
}

- (OFString *)XMLString
{
	void *pool = objc_autoreleasePoolPush();
	OFString *tmp = [_CDATA
	    stringByReplacingOccurrencesOfString: @"]]>"
				      withString: @"]]>]]&gt;<![CDATA["];
	OFString *ret = [OFString stringWithFormat: @"<![CDATA[%@]]>", tmp];

	[ret retain];
	objc_autoreleasePoolPop(pool);
	return [ret autorelease];
}

- (OFString *)description
{
	return self.XMLString;
}
@end
