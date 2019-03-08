/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#import "OFString+PropertyListValue.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFDate.h"
#import "OFDictionary.h"
#import "OFNumber.h"
#import "OFXMLAttribute.h"
#import "OFXMLElement.h"

#import "OFInvalidFormatException.h"
#import "OFUnsupportedVersionException.h"

int _OFString_PropertyListValue_reference;

static id parseElement(OFXMLElement *element);

static OFArray *
parseArrayElement(OFXMLElement *element)
{
	OFMutableArray *ret = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();

	for (OFXMLElement *child in element.elements)
		[ret addObject: parseElement(child)];

	[ret makeImmutable];

	objc_autoreleasePoolPop(pool);

	return ret;
}

static OFDictionary *
parseDictElement(OFXMLElement *element)
{
	OFMutableDictionary *ret = [OFMutableDictionary dictionary];
	void *pool = objc_autoreleasePoolPush();
	OFArray OF_GENERIC(OFXMLElement *) *children = element.elements;
	OFEnumerator OF_GENERIC(OFXMLElement *) *enumerator;
	OFXMLElement *key, *object;

	if (children.count % 2 != 0)
		@throw [OFInvalidFormatException exception];

	enumerator = [children objectEnumerator];
	while ((key = [enumerator nextObject]) &&
	    (object = [enumerator nextObject])) {
		if (key.namespace != nil || key.attributes.count != 0 ||
		    ![key.name isEqual: @"key"])
			@throw [OFInvalidFormatException exception];

		[ret setObject: parseElement(object)
			forKey: key.stringValue];
	}

	[ret makeImmutable];

	objc_autoreleasePoolPop(pool);

	return ret;
}

static OFString *
parseStringElement(OFXMLElement *element)
{
	return element.stringValue;
}

static OFData *
parseDataElement(OFXMLElement *element)
{
	return [OFData dataWithBase64EncodedString: element.stringValue];
}

static OFDate *
parseDateElement(OFXMLElement *element)
{
	return [OFDate dateWithDateString: element.stringValue
				   format: @"%Y-%m-%dT%H:%M:%SZ"];
}

static OFNumber *
parseTrueElement(OFXMLElement *element)
{
	if (element.children.count != 0)
		@throw [OFInvalidFormatException exception];

	return [OFNumber numberWithBool: true];
}

static OFNumber *
parseFalseElement(OFXMLElement *element)
{
	if (element.children.count != 0)
		@throw [OFInvalidFormatException exception];

	return [OFNumber numberWithBool: false];
}

static OFNumber *
parseRealElement(OFXMLElement *element)
{
	return [OFNumber numberWithDouble: element.stringValue.doubleValue];
}

static OFNumber *
parseIntegerElement(OFXMLElement *element)
{
	return [OFNumber numberWithIntMax: element.stringValue.decimalValue];
}

static id
parseElement(OFXMLElement *element)
{
	OFString *elementName;

	if (element.namespace != nil || element.attributes.count != 0)
		@throw [OFInvalidFormatException exception];

	elementName = element.name;

	if ([elementName isEqual: @"array"])
		return parseArrayElement(element);
	else if ([elementName isEqual: @"dict"])
		return parseDictElement(element);
	else if ([elementName isEqual: @"string"])
		return parseStringElement(element);
	else if ([elementName isEqual: @"data"])
		return parseDataElement(element);
	else if ([elementName isEqual: @"date"])
		return parseDateElement(element);
	else if ([elementName isEqual: @"true"])
		return parseTrueElement(element);
	else if ([elementName isEqual: @"false"])
		return parseFalseElement(element);
	else if ([elementName isEqual: @"real"])
		return parseRealElement(element);
	else if ([elementName isEqual: @"integer"])
		return parseIntegerElement(element);
	else
		@throw [OFInvalidFormatException exception];
}

@implementation OFString (PropertyListValue)
- (id)propertyListValue
{
	void *pool = objc_autoreleasePoolPush();
	OFXMLElement *rootElement = [OFXMLElement elementWithXMLString: self];
	OFXMLAttribute *versionAttribute;
	OFArray OF_GENERIC(OFXMLElement *) *elements;
	id ret;

	if (![rootElement.name isEqual: @"plist"] ||
	    rootElement.namespace != nil)
		@throw [OFInvalidFormatException exception];

	versionAttribute = [rootElement attributeForName: @"version"];

	if (versionAttribute == nil)
		@throw [OFInvalidFormatException exception];

	if (![versionAttribute.stringValue isEqual: @"1.0"])
		@throw [OFUnsupportedVersionException
		    exceptionWithVersion: [versionAttribute stringValue]];

	elements = rootElement.elements;

	if (elements.count != 1)
		@throw [OFInvalidFormatException exception];

	ret = parseElement(elements.firstObject);

	[ret retain];
	objc_autoreleasePoolPop(pool);
	return [ret autorelease];
}
@end
