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

#import "OFXMLCharacters.h"
#import "OFString.h"
#import "OFXMLElement.h"

#import "OFInvalidArgumentException.h"

#import "autorelease.h"

@implementation OFXMLCharacters
+ (instancetype)charactersWithString: (OFString*)string
{
	return [[[self alloc] initWithString: string] autorelease];
}

- initWithString: (OFString*)string
{
	self = [super init];

	@try {
		_characters = [string copy];
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

		_characters = [[element stringValue] copy];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (BOOL)isEqual: (id)object
{
	OFXMLCharacters *characters;

	if (![object isKindOfClass: [OFXMLCharacters class]])
		return NO;

	characters = object;

	return ([characters->_characters isEqual: _characters]);
}

- (uint32_t)hash
{
	return [_characters hash];
}

- (OFString*)stringValue
{
	return [[_characters copy] autorelease];
}

- (OFString*)XMLString
{
	return [_characters stringByXMLEscaping];
}

- (OFString*)XMLStringWithIndentation: (unsigned int)indentation
{
	return [_characters stringByXMLEscaping];
}

- (OFString*)XMLStringWithIndentation: (unsigned int)indentation
				level: (unsigned int)level
{
	return [_characters stringByXMLEscaping];
}

- (OFString*)description
{
	return [_characters stringByXMLEscaping];
}

- (OFXMLElement*)XMLElementBySerializing
{
	return [OFXMLElement elementWithName: [self className]
				   namespace: OF_SERIALIZATION_NS
				 stringValue: _characters];
}
@end
