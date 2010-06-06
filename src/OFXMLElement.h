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

@class OFMutableArray;
@class OFMutableDictionary;

extern int _OFXMLElement_reference;

/**
 * \brief A representation of an attribute of an XML element as an object.
 */
@interface OFXMLAttribute: OFObject
{
	OFString *name;
	OFString *namespace;
	OFString *stringValue;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, retain) OFString *name;
@property (readonly, retain) OFString *namespace;
@property (readonly, retain) OFString *stringValue;
#endif

/**
 * \param name The name of the attribute
 * \param ns The namespace of the attribute
 * \param value The string value of the attribute
 * \return A new autoreleased OFXMLAttribute with the specified parameters
 */
+ attributeWithName: (OFString*)name
	  namespace: (OFString*)ns
	stringValue: (OFString*)value;

/**
 * Initializes an already allocated OFXMLAttribute.
 *
 * \param name The name of the attribute
 * \param ns The namespace of the attribute
 * \param value The string value of the attribute
 * \return An initialized OFXMLAttribute with the specified parameters
 */
- initWithName: (OFString*)name
     namespace: (OFString*)ns
   stringValue: (OFString*)value;

/**
 * \return The name of the attribute as an autoreleased OFString
 */
- (OFString*)name;

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
	OFString *namespace;
	OFString *defaultNamespace;
	OFMutableArray *attributes;
	OFString *stringValue;
	OFMutableDictionary *namespaces;
	OFMutableArray *children;
}

/**
 * \param name The name for the element
 * \return A new autoreleased OFXMLElement with the specified element name
 */
+ elementWithName: (OFString*)name;

/**
 * \param name The name for the element
 * \param stringval The value for the element
 * \return A new autoreleased OFXMLElement with the specified element name and
 *	   value
 */
+ elementWithName: (OFString*)name
      stringValue: (OFString*)stringval;

/**
 * \param name The name for the element
 * \param ns The namespace for the element
 * \return A new autoreleased OFXMLElement with the specified element name and
 *	   namespace
 */
+ elementWithName: (OFString*)name
	namespace: (OFString*)ns;

/**
 * \param name The name for the element
 * \param ns The namespace for the element
 * \param stringval The value for the element
 * \return A new autoreleased OFXMLElement with the specified element name,
 *	   namespace and value
 */
+ elementWithName: (OFString*)name
	namespace: (OFString*)ns
      stringValue: (OFString*)stringval;

/**
 * Initializes an already allocated OFXMLElement with the specified element
 * name.
 *
 * \param name The name for the element
 * \return An initialized OFXMLElement with the specified element name
 */
- initWithName: (OFString*)name;

/**
 * Initializes an already allocated OFXMLElement with the specified element
 * name and value.
 *
 * \param name The name for the element
 * \param stringval The value for the element
 * \return An initialized OFXMLElement with the specified element name and
 *	   value
 */
- initWithName: (OFString*)name
   stringValue: (OFString*)stringval;

/**
 * Initializes an already allocated OFXMLElement with the specified element
 * name and namespace.
 *
 * \param name The name for the element
 * \param ns The namespace for the element
 * \return An initialized OFXMLElement with the specified element name and
 *	   namespace
 */
- initWithName: (OFString*)name
     namespace: (OFString*)ns;

/**
 * Initializes an already allocated OFXMLElement with the specified element
 * name, namespace and value.
 *
 * \param name The name for the element
 * \param ns The namespace for the element
 * \param stringval The value for the element
 * \return An initialized OFXMLElement with the specified element name,
 *	   namespace and value
 */
- initWithName: (OFString*)name
     namespace: (OFString*)ns
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
- (void)addAttribute: (OFXMLAttribute*)attr;

/**
 * Adds the specified attribute with the specified value.
 *
 * \param name The name of the attribute
 * \param value The value of the attribute
 */
- (void)addAttributeWithName: (OFString*)name
		 stringValue: (OFString*)value;

/**
 * Adds the specified attribute with the specified namespace and value.
 *
 * \param name The name of the attribute
 * \param ns The namespace of the attribute
 * \param value The value of the attribute
 */
- (void)addAttributeWithName: (OFString*)name
		   namespace: (OFString*)ns
		 stringValue: (OFString*)value;

/**
 * Sets a prefix for a namespace.
 *
 * \param prefix The prefix for the namespace
 * \param ns The namespace for which the prefix is set
 */
- (void)setPrefix: (OFString*)prefix
     forNamespace: (OFString*)ns;

/**
 * Sets the default namespace for the element.
 *
 * \param ns The default namespace for the element
 */
- (void)setDefaultNamespace: (OFString*)ns;

/**
 * Adds a child to the OFXMLElement.
 *
 * \param child Another OFXMLElement which is added as a child
 */
- (void)addChild: (OFXMLElement*)child;
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
- (OFString*)stringByXMLEscaping;
@end
