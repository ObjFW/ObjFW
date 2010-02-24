/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFObject.h"
#import "OFString.h"

@class OFDictionary;
@class OFMutableArray;

extern int _OFXMLElement_reference;

/**
 * \brief A representation of an attribute of an XML element as an object.
 */
@interface OFXMLAttribute: OFObject
{
	OFString *prefix;
	OFString *name;
	OFString *ns;
	OFString *value;
}

/**
 * \param name The name of the attribute
 * \param prefix The prefix of the attribute
 * \param ns The namespace of the attribute
 * \param value The string value of the attribute
 * \return A new autoreleased OFXMLAttribute with the specified parameters
 */
+ attributeWithName: (OFString*)name
	     prefix: (OFString*)prefix
	  namespace: (OFString*)ns
	stringValue: (OFString*)value;

/**
 * Initializes an already allocated OFXMLAttribute.
 *
 * \param name The name of the attribute
 * \param prefix The prefix of the attribute
 * \param ns The namespace of the attribute
 * \param value The string value of the attribute
 * \return An initialized OFXMLAttribute with the specified parameters
 */
- initWithName: (OFString*)name
	prefix: (OFString*)prefix
     namespace: (OFString*)ns
   stringValue: (OFString*)value;

/**
 * \return The name of the attribute as an autoreleased OFString
 */
- (OFString*)name;

/**
 * \return The prefix of the attribute as an autoreleased OFString
 */
- (OFString*)prefix;

/**
 * \return The namespace of the attribute as an autoreleased OFString
 */
- (OFString*)namespace;

/**
 * \return The string value of the attribute as an autoreleased OFString
 */
- (OFString*)stringValue;
@end

/**
 * \brief A representation of an XML element as an object.
 *
 * The OFXMLElement represents an XML element as an object which can be
 * modified and converted back to XML again.
 */
@interface OFXMLElement: OFObject
{
	OFString *name;
	OFMutableArray *attrs;
	OFString *stringval;
	OFMutableArray *children;
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
 * Adds the specified attribute.
 *
 * \param attr The attribute to add
 */
- addAttribute: (OFXMLAttribute*)attr;

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
 * \brief A category to escape strings for use in an XML document.
 */
@interface OFString (OFXMLEscaping)
/**
 * Escapes a string for use in an XML document.
 *
 * \return A new autoreleased string
 */
- stringByXMLEscaping;
@end
