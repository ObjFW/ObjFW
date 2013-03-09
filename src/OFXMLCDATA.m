/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
 *   Jonathan Schleifer <js@webkeks.org>
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
#import "OFString.h"
#import "OFXMLElement.h"

#import "OFInvalidArgumentException.h"

#import "autorelease.h"

@implementation OFXMLCDATA
+ (instancetype)CDATAWithString: (OFString*)string
{
	return [[[self alloc] initWithString: string] autorelease];
}

- initWithString: (OFString*)string
{
	self = [super init];

	@try {
		_CDATA = [string copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithSerialization: (OFXMLElement*)element
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		if (![[element name] isEqual: [self className]] ||
		    ![[element namespace] isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException
			    exceptionWithClass: [self class]
				      selector: _cmd];

		_CDATA = [[element stringValue] copy];

		objc_autoreleasePoolPop(pool);
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

	if (![object isKindOfClass: [OFXMLCDATA class]])
		return false;

	CDATA = object;

	return ([CDATA->_CDATA isEqual: _CDATA]);
}

- (uint32_t)hash
{
	return [_CDATA hash];
}

- (OFString*)stringValue
{
	return [[_CDATA copy] autorelease];
}

- (OFString*)XMLString
{
	/* FIXME: What to do about ]]>? */
	return [OFString stringWithFormat: @"<![CDATA[%@]]>", _CDATA];
}

- (OFString*)XMLStringWithIndentation: (unsigned int)indentation
{
	return [self XMLString];
}

- (OFString*)XMLStringWithIndentation: (unsigned int)indentation
				level: (unsigned int)level
{
	return [self XMLString];
}

- (OFString*)description
{
	return [self XMLString];
}

- (OFXMLElement*)XMLElementBySerializing
{
	OFXMLElement *element =
	    [OFXMLElement elementWithName: [self className]
				namespace: OF_SERIALIZATION_NS];
	[element addChild: self];

	return element;
}
@end
