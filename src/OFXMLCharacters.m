/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
#import "OFXMLNode+Private.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"

@implementation OFXMLCharacters
+ (instancetype)charactersWithString: (OFString *)string
{
	return [[[self alloc] initWithString: string] autorelease];
}

- (instancetype)initWithString: (OFString *)string
{
	self = [super of_init];

	@try {
		_characters = [string copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_characters release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFXMLCharacters *characters;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFXMLCharacters class]])
		return false;

	characters = object;

	return ([characters->_characters isEqual: _characters]);
}

- (unsigned long)hash
{
	return _characters.hash;
}

- (OFString *)stringValue
{
	return [[_characters copy] autorelease];
}

- (void)setStringValue: (OFString *)stringValue
{
	OFString *old = _characters;
	_characters = [stringValue copy];
	[old release];
}

- (OFString *)XMLString
{
	return _characters.stringByXMLEscaping;
}

- (OFString *)description
{
	return self.XMLString;
}
@end
