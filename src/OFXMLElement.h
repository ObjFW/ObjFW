/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFObject.h"
#import "OFString.h"
#import "OFDictionary.h"
#import "OFArray.h"

extern int _OFXMLElement_reference;

/**
 * The OFXMLElement represents an XML element as an object which can be
 * modified and converted back to XML again.
 */
@interface OFXMLElement: OFObject
{
	OFString *name;
	OFDictionary *attrs;
	OFString *stringval;
	OFArray *children;
}

/**
 * \param name The name for the element
 * \return A new autorelease OFXMLElement with the specified element name
 */
+ elementWithName: (OFString*)name;

/**
 * \param name The name for the element
 * \param stringval The value for the element
 * \return A new autorelease OFXMLElement with the specified element name and
 *	   value
 */
+ elementWithName: (OFString*)name
      stringValue: (OFString*)stringval;

/**
 * Initializes an already allocated OFXMLElement with the specified name.
 *
 * \param name The name for the element
 * \return An initialized OFXMLElement with the specified element name
 */
- initWithName: (OFString*)name;

/**
 * Initializes an already allocated OFXMLElement with the specified name and
 * value.
 *
 * \param name The name for the element
 * \param stringval The value for the element
 * \return An initialized OFXMLElement with the specified element name and
 *	   value
 */
- initWithName: (OFString*)name
   stringValue: (OFString*)stringval;

/**
 * \return A new autoreleased OFString representing the OFXMLElement as an
 * XML string
 */
- (OFString*)string;

/**
 * Adds the specified attribute with the specified value.
 *
 * \param name The name of the attribute
 * \param value The value of the attribute
 */
- addAttributeWithName: (OFString*)name
	   stringValue: (OFString*)value;

/**
 * Adds a child to the OFXMLElement.
 *
 * \param child Another OFXMLElement which is added as a child
 */
- addChild: (OFXMLElement*)child;
@end

/**
 * The OFXMLEscaping category provides an easy way to escape strings for use in
 * an XML document.
 */
@interface OFString (OFXMLEscaping)
/**
 * Escapes a string for use in an XML document.
 *
 * \return A new autoreleased string
 */
- stringByXMLEscaping;
@end
