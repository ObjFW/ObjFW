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

@class OFString;
@class OFMutableString;
@class OFMutableArray;
@class OFMutableDictionary;
@class OFXMLAttribute;

@interface OFXMLElement: OFObject
{
	OFString *name;
	OFString *namespace;
	OFString *defaultNamespace;
	OFMutableArray *attributes;
	OFMutableDictionary *namespaces;
	OFMutableArray *children;
	OFString *text;
	OFMutableString *comment;
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
 * Creates a new element, only consisting of the specified text.
 *
 * \param text The text the element represents
 * \return A new autoreleased OFXMLElement consisting of the specified text
 */
+ elementWithText: (OFString*)text;

/**
 * Creates a new element, only consisting of the specified comment.
 *
 * \param comment The comment the element represents
 * \return A new autoreleased OFXMLElement consisting of the specified comment
 */
+ elementWithComment: (OFString*)text;

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
 * Initializes an already allocated OFXMLElement so that it only consists of the
 * specified text.
 *
 * \param text The text the element represents
 * \return An initialized OFXMLElement consisting of the specified text
 */
- initWithText: (OFString*)text;

/**
 * Initializes an already allocated OFXMLElement so that it only consists of the
 * specified comment.
 *
 * \param comment The comment the element represents
 * \return An initialized OFXMLElement consisting of the specified comment
 */
- initWithComment: (OFString*)text;

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
