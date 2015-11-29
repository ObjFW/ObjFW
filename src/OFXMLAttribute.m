/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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

#import "OFXMLAttribute.h"
#import "OFString.h"
#import "OFDictionary.h"
#import "OFXMLElement.h"

#import "OFInvalidArgumentException.h"

@implementation OFXMLAttribute
@synthesize name = _name, namespace = _namespace;

+ (instancetype)attributeWithName: (OFString*)name
			namespace: (OFString*)namespace
		      stringValue: (OFString*)stringValue
{
	return [[[self alloc] initWithName: name
				 namespace: namespace
			       stringValue: stringValue] autorelease];
}

+ (instancetype)attributeWithName: (OFString*)name
		      stringValue: (OFString*)stringValue
{
	return [[[self alloc] initWithName: name
			       stringValue: stringValue] autorelease];
}

- initWithName: (OFString*)name
   stringValue: (OFString*)stringValue
{
	return [self initWithName: name
			namespace: nil
		      stringValue: stringValue];
}

- initWithName: (OFString*)name
     namespace: (OFString*)namespace
   stringValue: (OFString*)stringValue
{
	self = [super init];

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

- initWithSerialization: (OFXMLElement*)element
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		if (![[element name] isEqual: [self className]] ||
		    ![[element namespace] isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException exception];

		_name = [[[element attributeForName: @"name"]
		    stringValue] copy];
		_namespace = [[[element attributeForName: @"namespace"]
		    stringValue] copy];
		_stringValue = [[[element attributeForName: @"stringValue"]
		    stringValue] copy];

		objc_autoreleasePoolPop(pool);
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

- (OFString*)stringValue
{
	return [[_stringValue copy] autorelease];
}

- (void)setStringValue: (OFString*)stringValue
{
	OFString *old = _stringValue;
	_stringValue = [stringValue copy];
	[old release];
}

- (bool)isEqual: (id)object
{
	OFXMLAttribute *attribute;

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

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, [_name hash]);
	OF_HASH_ADD_HASH(hash, [_namespace hash]);
	OF_HASH_ADD_HASH(hash, [_stringValue hash]);

	OF_HASH_FINALIZE(hash);

	return hash;
}

- (OFXMLElement*)XMLElementBySerializing
{
	void *pool = objc_autoreleasePoolPush();
	OFXMLElement *element;

	element = [OFXMLElement elementWithName: [self className]
				      namespace: OF_SERIALIZATION_NS];

	[element addAttributeWithName: @"name"
			  stringValue: _name];

	if (_namespace != nil)
		[element addAttributeWithName: @"namespace"
				  stringValue: _namespace];

	[element addAttributeWithName: @"stringValue"
			  stringValue: _stringValue];

	[element retain];

	objc_autoreleasePoolPop(pool);

	return [element autorelease];
}

- (OFString*)description
{
	return [OFString stringWithFormat: @"<OFXMLAttribute: name=%@, "
					   @"namespace=%@, stringValue=%@>",
					   _name, _namespace, _stringValue];
}
@end
