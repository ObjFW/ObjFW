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

@class OFString;
@class OFArray;
@class OFMutableString;
@class OFMutableArray;
@class OFMutableDictionary;
@class OFXMLAttribute;

/**
 * \brief A class which stores an XML element.
 */
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
 * Parses the string and returns an OFXMLElement for it.
 *
 * \param str The string to parse
 * \return A new autoreleased OFXMLElement with the contents of the string
 */
+ elementWithString: (OFString*)str;

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
 * Parses the string and initializes an already allocated OFXMLElement with it.
 *
 * \param str The string to parse
 * \return An initialized OFXMLElement with the contents of the string
 */
- initWithString: (OFString*)str;

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
- (OFString*)stringValue;

/**
 * Adds the specified attribute.
 *
 * If an attribute with the same name and namespace already exists, it is not
 * added.
 *
 * \param attr The attribute to add
 */
- (void)addAttribute: (OFXMLAttribute*)attr;

/**
 * Adds the specified attribute with the specified value.
 *
 * If an attribute with the same name and namespace already exists, it is not
 * added.
 *
 * \param name The name of the attribute
 * \param value The value of the attribute
 */
- (void)addAttributeWithName: (OFString*)name
		 stringValue: (OFString*)value;

/**
 * Adds the specified attribute with the specified namespace and value.
 *
 * If an attribute with the same name and namespace already exists, it is not
 * added.
 *
 * \param name The name of the attribute
 * \param ns The namespace of the attribute
 * \param value The value of the attribute
 */
- (void)addAttributeWithName: (OFString*)name
		   namespace: (OFString*)ns
		 stringValue: (OFString*)value;

/**
 * \param attrname The name of the attribute
 * \return The attribute with the specified name
 */
- (OFXMLAttribute*)attributeForName: (OFString*)attrname;

/**
 * \param attrname The name of the attribute
 * \param attrns The namespace of the attribute
 * \return The attribute with the specified name and namespace
 */
- (OFXMLAttribute*)attributeForName: (OFString*)attrname
			  namespace: (OFString*)attrns;

/**
 * Removes the attribute with the specified name.
 *
 * \param attrname The name of the attribute
 */
- (void)removeAttributeForName: (OFString*)attrname;

/**
 * Removes the attribute with the specified name and namespace.
 *
 * \param attrname The name of the attribute
 * \param attrns The namespace of the attribute
 */
- (void)removeAttributeForName: (OFString*)attrname
		     namespace: (OFString*)attrns;

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

/**
 * \param elemname The name of the element
 * \return The first child element with the specified name
 */
- (OFXMLElement*)elementForName: (OFString*)elemname;

/**
 * \param elemname The name of the elements
 * \return The child elements with the specified name
 */
- (OFArray*)elementsForName: (OFString*)elemname;

/**
 * \param elemname The name of the element
 * \param elemns The namespace of the element
 * \return The first child element with the specified name and namespace
 */
- (OFXMLElement*)elementForName: (OFString*)elemname
		      namespace: (OFString*)elemns;

/**
 * \param elemname The name of the elements
 * \param elemns The namespace of the elements
 * \return The child elements with the specified name and namespace
 */
- (OFArray*)elementsForName: (OFString*)elemname
		  namespace: (OFString*)elemns;
@end
