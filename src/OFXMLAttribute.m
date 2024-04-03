/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFXMLAttribute.h"
#import "OFXMLNode+Private.h"
#import "OFString.h"
#import "OFDictionary.h"

#import "OFInvalidArgumentException.h"

@implementation OFXMLAttribute
@synthesize name = _name, namespace = _namespace;

+ (instancetype)attributeWithName: (OFString *)name
			namespace: (OFString *)namespace
		      stringValue: (OFString *)stringValue
{
	return [[[self alloc] initWithName: name
				 namespace: namespace
			       stringValue: stringValue] autorelease];
}

+ (instancetype)attributeWithName: (OFString *)name
		      stringValue: (OFString *)stringValue
{
	return [[[self alloc] initWithName: name
			       stringValue: stringValue] autorelease];
}

- (instancetype)initWithName: (OFString *)name
		 stringValue: (OFString *)stringValue
{
	return [self initWithName: name
			namespace: nil
		      stringValue: stringValue];
}

- (instancetype)initWithName: (OFString *)name
		   namespace: (OFString *)namespace
		 stringValue: (OFString *)stringValue
{
	self = [super of_init];

	@try {
		_name = [name copy];
		_namespace = [namespace copy];
		_stringValue = [stringValue copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_name release];
	[_namespace release];
	[_stringValue release];

	[super dealloc];
}

- (OFString *)stringValue
{
	return [[_stringValue copy] autorelease];
}

- (void)setStringValue: (OFString *)stringValue
{
	OFString *old = _stringValue;
	_stringValue = [stringValue copy];
	[old release];
}

- (bool)isEqual: (id)object
{
	OFXMLAttribute *attribute;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFXMLAttribute class]])
		return false;

	attribute = object;

	if (![attribute->_name isEqual: _name])
		return false;
	if (attribute->_namespace != _namespace &&
	    ![attribute->_namespace isEqual: _namespace])
		return false;
	if (![attribute->_stringValue isEqual: _stringValue])
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddHash(&hash, _name.hash);
	OFHashAddHash(&hash, _namespace.hash);
	OFHashAddHash(&hash, _stringValue.hash);

	OFHashFinalize(&hash);

	return hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<%@: name=%@, namespace=%@, "
					   @"stringValue=%@>",
					   self.class, _name, _namespace,
					   _stringValue];
}
@end
