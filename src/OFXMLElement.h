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
@class OFArray;
@class OFMutableString;
@class OFMutableArray;
@class OFMutableDictionary;
@class OFXMLAttribute;

@interface OFXMLElement: OFObject
{
	OFString *name;
	OFString *ns;
	OFString *defaultNamespace;
	OFMutableArray *attributes;
	OFMutableDictionary *namespaces;
	OFMutableArray *children;
	OFString *characters;
	OFString *cdata;
	OFMutableString *comment;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, copy) OFString *name;
@property (readonly, copy, getter=namespace) OFString *ns;
@property (copy) OFString *defaultNamespace;
@property (readonly, copy) OFArray *attributes;
@property (readonly, copy) OFArray *children;
#endif

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
 * Creates a new element, only consisting of the specified characters.
 *
 * \param chars The characters the element represents
 * \return A new autoreleased OFXMLElement consisting of the specified
 *	   characters
 */
+ elementWithCharacters: (OFString*)chars;

/**
 * Creates a new element, only consisting of the specified CDATA.
 *
 * \param cdata The CDATA the element represents
 * \return A new autoreleased OFXMLElement consisting of the specified CDATA
 */
+ elementWithCDATA: (OFString*)cdata;

/**
 * Creates a new element, only consisting of the specified comment.
 *
 * \param comment The comment the element represents
 * \return A new autoreleased OFXMLElement consisting of the specified comment
 */
+ elementWithComment: (OFString*)comment;

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
 * specified characters.
 *
 * \param chars The characters the element represents
 * \return An initialized OFXMLElement consisting of the specified characters
 */
- initWithCharacters: (OFString*)chars;

/**
 * Initializes an already allocated OFXMLElement so that it only consists of the
 * specified CDATA.
 *
 * \param cdata The CDATA the element represents
 * \return An initialized OFXMLElement consisting of the specified CDATA
 */
- initWithCDATA: (OFString*)cdata;

/**
 * Initializes an already allocated OFXMLElement so that it only consists of the
 * specified comment.
 *
 * \param comment The comment the element represents
 * \return An initialized OFXMLElement consisting of the specified comment
 */
- initWithComment: (OFString*)comment;

/**
 * \return The name of the element
 */
- (OFString*)name;

/**
 * \return The namespace of the element
 */
- (OFString*)namespace;

/**
 * \return An OFArray with the attributes of the element
 */
- (OFArray*)attributes;

/**
 * \return An array with all children of the element
 */
- (OFArray*)children;

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
 * Binds a prefix for a namespace.
 *
 * \param prefix The prefix for the namespace
 * \param ns The namespace for which the prefix is bound
 */
- (void)bindPrefix: (OFString*)prefix
      forNamespace: (OFString*)ns;

/**
 * Sets the default namespace for the element.
 *
 * \param ns The default namespace for the element
 */
- (void)setDefaultNamespace: (OFString*)ns;

/**
 * Binds the default namespace for the element.
 *
 * \param ns The default namespace for the element
 */
- (void)bindDefaultNamespace: (OFString*)ns;

/**
 * Adds a child to the OFXMLElement.
 *
 * \param child Another OFXMLElement which is added as a child
 */
- (void)addChild: (OFXMLElement*)child;
@end
