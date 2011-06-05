/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#import "OFObject.h"
#import "OFSerialization.h"

@class OFString;
@class OFArray;
@class OFMutableString;
@class OFMutableArray;
@class OFMutableDictionary;
@class OFXMLAttribute;

/**
 * \brief A class which stores an XML element.
 */
@interface OFXMLElement: OFObject <OFSerialization>
{
	OFString *name;
	OFString *ns;
	OFString *defaultNamespace;
	OFMutableArray *attributes;
	OFMutableDictionary *namespaces;
	OFMutableArray *children;
	OFString *characters;
	OFString *CDATA;
	OFString *comment;
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
 * \param stringValue The value for the element
 * \return A new autoreleased OFXMLElement with the specified element name and
 *	   value
 */
+ elementWithName: (OFString*)name
      stringValue: (OFString*)stringValue;

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
 * \param stringValue The value for the element
 * \return A new autoreleased OFXMLElement with the specified element name,
 *	   namespace and value
 */
+ elementWithName: (OFString*)name
	namespace: (OFString*)ns
      stringValue: (OFString*)stringValue;

/**
 * Creates a new element, only consisting of the specified characters.
 *
 * \param characters The characters the element represents
 * \return A new autoreleased OFXMLElement consisting of the specified
 *	   characters
 */
+ elementWithCharacters: (OFString*)characters;

/**
 * Creates a new element, only consisting of the specified CDATA.
 *
 * \param CDATA The CDATA the element represents
 * \return A new autoreleased OFXMLElement consisting of the specified CDATA
 */
+ elementWithCDATA: (OFString*)CDATA;

/**
 * Creates a new element, only consisting of the specified comment.
 *
 * \param comment The comment the element represents
 * \return A new autoreleased OFXMLElement consisting of the specified comment
 */
+ elementWithComment: (OFString*)comment;

/**
 * \param element An OFXMLElement to initialize the OFXMLElement with
 * \return A new autoreleased OFXMLElement with the contents of the specified
 *	   element
 */
+ elementWithElement: (OFXMLElement*)element;

/**
 * Parses the string and returns an OFXMLElement for it.
 *
 * \param string The string to parse
 * \return A new autoreleased OFXMLElement with the contents of the string
 */
+ elementWithXMLString: (OFString*)string;

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
 * \param stringValue The value for the element
 * \return An initialized OFXMLElement with the specified element name and
 *	   value
 */
- initWithName: (OFString*)name
   stringValue: (OFString*)stringValue;

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
 * \param stringValue The value for the element
 * \return An initialized OFXMLElement with the specified element name,
 *	   namespace and value
 */
- initWithName: (OFString*)name
     namespace: (OFString*)ns
   stringValue: (OFString*)stringValue;

/**
 * Initializes an already allocated OFXMLElement so that it only consists of the
 * specified characters.
 *
 * \param characters The characters the element represents
 * \return An initialized OFXMLElement consisting of the specified characters
 */
- initWithCharacters: (OFString*)characters;

/**
 * Initializes an already allocated OFXMLElement so that it only consists of the
 * specified CDATA.
 *
 * \param CDATA The CDATA the element represents
 * \return An initialized OFXMLElement consisting of the specified CDATA
 */
- initWithCDATA: (OFString*)CDATA;

/**
 * Initializes an already allocated OFXMLElement so that it only consists of the
 * specified comment.
 *
 * \param comment The comment the element represents
 * \return An initialized OFXMLElement consisting of the specified comment
 */
- initWithComment: (OFString*)comment;

/**
 * Initializes an already allocated OFXMLElement with the specified
 * OFXMLElement.
 *
 * \param element An OFXMLElement to initialize the OFXMLElement with
 * \return A new autoreleased OFXMLElement with the contents of the specified
 *	   element
 */
- initWithElement: (OFXMLElement*)element;

/**
 * Parses the string and initializes an already allocated OFXMLElement with it.
 *
 * \param string The string to parse
 * \return An initialized OFXMLElement with the contents of the string
 */
- initWithXMLString: (OFString*)string;

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
 * Removes all children and adds the children from the specified array.
 *
 * \param children The new children to add
 */
- (void)setChildren: (OFArray*)children;

/**
 * \return An array with all children of the element
 */
- (OFArray*)children;

/**
 * Removes all children and sets the string value to the specified string.
 *
 * \param stringValue The new string value for the element
 */
- (void)setStringValue: (OFString*)stringValue;

/**
 * \return A string with the string value of all children concatenated
 */
- (OFString*)stringValue;

/**
 * \return A new autoreleased OFString representing the OFXMLElement as an
 * XML string
 */
- (OFString*)XMLString;

/**
 * Adds the specified attribute.
 *
 * If an attribute with the same name and namespace already exists, it is not
 * added.
 *
 * \param attribute The attribute to add
 */
- (void)addAttribute: (OFXMLAttribute*)attribute;

/**
 * Adds the specified attribute with the specified value.
 *
 * If an attribute with the same name and namespace already exists, it is not
 * added.
 *
 * \param name The name of the attribute
 * \param stringValue The value of the attribute
 */
- (void)addAttributeWithName: (OFString*)name
		 stringValue: (OFString*)stringValue;

/**
 * Adds the specified attribute with the specified namespace and value.
 *
 * If an attribute with the same name and namespace already exists, it is not
 * added.
 *
 * \param name The name of the attribute
 * \param ns The namespace of the attribute
 * \param stringValue The value of the attribute
 */
- (void)addAttributeWithName: (OFString*)name
		   namespace: (OFString*)ns
		 stringValue: (OFString*)stringValue;

/**
 * \param attributeName The name of the attribute
 * \return The attribute with the specified name
 */
- (OFXMLAttribute*)attributeForName: (OFString*)attributeName;

/**
 * \param attributeName The name of the attribute
 * \param attributeNS The namespace of the attribute
 * \return The attribute with the specified name and namespace
 */
- (OFXMLAttribute*)attributeForName: (OFString*)attributeName
			  namespace: (OFString*)attributeNS;

/**
 * Removes the attribute with the specified name.
 *
 * \param attribteName The name of the attribute
 */
- (void)removeAttributeForName: (OFString*)attributeName;

/**
 * Removes the attribute with the specified name and namespace.
 *
 * \param attributeName The name of the attribute
 * \param attributeNS The namespace of the attribute
 */
- (void)removeAttributeForName: (OFString*)attributeName
		     namespace: (OFString*)attributeNS;

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
 * Sets the default namespace for the element to be used if there is no parent.
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

/**
 * \param elementName The name of the element
 * \return The first child element with the specified name
 */
- (OFXMLElement*)elementForName: (OFString*)elementName;

/**
 * \param elementName The name of the elements
 * \return The child elements with the specified name
 */
- (OFArray*)elementsForName: (OFString*)elementName;

/**
 * \param elementName The name of the element
 * \param elementNS The namespace of the element
 * \return The first child element with the specified name and namespace
 */
- (OFXMLElement*)elementForName: (OFString*)elementName
		      namespace: (OFString*)elementNS;

/**
 * \param elementName The name of the elements
 * \param elementNS The namespace of the elements
 * \return The child elements with the specified name and namespace
 */
- (OFArray*)elementsForName: (OFString*)elementName
		  namespace: (OFString*)elementNS;
@end

#import "OFXMLElement+Serialization.h"
