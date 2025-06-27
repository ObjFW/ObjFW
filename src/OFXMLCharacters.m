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

#import "OFXMLCharacters.h"
#import "OFXMLNode+Private.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"

@implementation OFXMLCharacters
+ (instancetype)charactersWithString: (OFString *)string
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithString: string]);
}

- (instancetype)initWithString: (OFString *)string
{
	self = [super of_init];

	@try {
		_characters = [string copy];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_characters);

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
	return objc_autoreleaseReturnValue([_characters copy]);
}

- (void)setStringValue: (OFString *)stringValue
{
	OFString *old = _characters;
	_characters = [stringValue copy];
	objc_release(old);
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
