/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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
+ CDATAWithString: (OFString*)string
{
	return [[[self alloc] initWithString: string] autorelease];
}

- initWithString: (OFString*)string
{
	self = [super init];

	@try {
		CDATA = [string copy];
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

		CDATA = [[element stringValue] copy];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (BOOL)isEqual: (id)object
{
	OFXMLCDATA *otherCDATA;

	if (![object isKindOfClass: [OFXMLCDATA class]])
		return NO;

	otherCDATA = object;

	return ([otherCDATA->CDATA isEqual: CDATA]);
}

- (uint32_t)hash
{
	return [CDATA hash];
}

- (OFString*)stringValue
{
	return [[CDATA copy] autorelease];
}

- (OFString*)XMLString
{
	return [OFString stringWithFormat: @"<![CDATA[%@]]>", CDATA];
}

- (OFString*)XMLStringWithIndentation: (unsigned int)indentation
{
	return [OFString stringWithFormat: @"<![CDATA[%@]]>", CDATA];
}

- (OFString*)XMLStringWithIndentation: (unsigned int)indentation
				level: (unsigned int)level
{
	return [OFString stringWithFormat: @"<![CDATA[%@]]>", CDATA];
}

- (OFString*)description
{
	return [OFString stringWithFormat: @"<![CDATA[%@]]>", CDATA];
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
