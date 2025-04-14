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

#import "OFXMLCDATA.h"
#import "OFXMLNode+Private.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"

@implementation OFXMLCDATA
+ (instancetype)CDATAWithString: (OFString *)string
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithString: string]);
}

- (instancetype)initWithString: (OFString *)string
{
	self = [super of_init];

	@try {
		_CDATA = [string copy];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_CDATA);

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
	return objc_autoreleaseReturnValue([_CDATA copy]);
}

- (void)setStringValue: (OFString *)stringValue
{
	OFString *old = _CDATA;
	_CDATA = [stringValue copy];
	objc_release(old);
}

- (OFString *)XMLString
{
	void *pool = objc_autoreleasePoolPush();
	OFString *tmp = [_CDATA
	    stringByReplacingOccurrencesOfString: @"]]>"
				      withString: @"]]>]]&gt;<![CDATA["];
	OFString *ret = [OFString stringWithFormat: @"<![CDATA[%@]]>", tmp];

	objc_retain(ret);
	objc_autoreleasePoolPop(pool);
	return objc_autoreleaseReturnValue(ret);
}

- (OFString *)description
{
	return self.XMLString;
}
@end
