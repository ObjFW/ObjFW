/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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

#import "OFXMLNode.h"

@class OFString;
@class OFArray;
@class OFMutableString;
@class OFMutableArray;
@class OFMutableDictionary;
@class OFXMLAttribute;

/*!
 * @class OFXMLElement OFXMLElement.h ObjFW/OFXMLElement.h
 *
 * @brief A class which stores an XML element.
 */
@interface OFXMLElement: OFXMLNode
{
	OFString *_name, *_namespace, *_defaultNamespace;
	OFMutableArray *_attributes;
	OFMutableDictionary *_namespaces;
	OFMutableArray *_children;
}

#ifdef OF_HAVE_PROPERTIES
@property (copy) OFString *name;
# ifdef __cplusplus
@property (copy, getter=namespace, setter=setNamespace:) OFString *namespace_;
# else
@property (copy) OFString *namespace;
# endif
@property (copy) OFString *defaultNamespace;
@property (readonly, copy) OFArray *attributes;
@property (copy) OFArray *children;
#endif

/*!
 * @brief Creates a new XML element with the specified name.
 *
 * @param name The name for the element
 * @return A new autoreleased OFXMLElement with the specified element name
 */
+ (instancetype)elementWithName: (OFString*)name;

/*!
 * @brief Creates a new XML element with the specified name and string value.
 *
 * @param name The name for the element
 * @param stringValue The value for the element
 * @return A new autoreleased OFXMLElement with the specified element name and
 *	   value
 */
+ (instancetype)elementWithName: (OFString*)name
		    stringValue: (OFString*)stringValue;

/*!
 * @brief Creates a new XML element with the specified name and namespace.
 *
 * @param name The name for the element
 * @param namespace_ The namespace for the element
 * @return A new autoreleased OFXMLElement with the specified element name and
 *	   namespace
 */
+ (instancetype)elementWithName: (OFString*)name
		      namespace: (OFString*)namespace_;

/*!
 * @brief Creates a new XML element with the specified name, namespace and
 * 	  string value.
 *
 * @param name The name for the element
 * @param namespace_ The namespace for the element
 * @param stringValue The value for the element
 * @return A new autoreleased OFXMLElement with the specified element name,
 *	   namespace and value
 */
+ (instancetype)elementWithName: (OFString*)name
		      namespace: (OFString*)namespace_
		    stringValue: (OFString*)stringValue;

/*!
 * @brief Creates a new element with the specified element.
 *
 * @param element An OFXMLElement to initialize the OFXMLElement with
 * @return A new autoreleased OFXMLElement with the contents of the specified
 *	   element
 */
+ (instancetype)elementWithElement: (OFXMLElement*)element;

/*!
 * @brief Parses the string and returns an OFXMLElement for it.
 *
 * @param string The string to parse
 * @return A new autoreleased OFXMLElement with the contents of the string
 */
+ (instancetype)elementWithXMLString: (OFString*)string;

#ifdef OF_HAVE_FILES
/*!
 * @brief Parses the specified file and returns an OFXMLElement for it.
 *
 * @param path The path to the file
 * @return A new autoreleased OFXMLElement with the contents of the specified
 *	   file
 */
+ (instancetype)elementWithFile: (OFString*)path;
#endif

/*!
 * @brief Initializes an already allocated OFXMLElement with the specified name.
 *
 * @param name The name for the element
 * @return An initialized OFXMLElement with the specified element name
 */
- initWithName: (OFString*)name;

/*!
 * @brief Initializes an already allocated OFXMLElement with the specified name
 *	  and string value.
 *
 * @param name The name for the element
 * @param stringValue The value for the element
 * @return An initialized OFXMLElement with the specified element name and
 *	   value
 */
- initWithName: (OFString*)name
   stringValue: (OFString*)stringValue;

/*!
 * @brief Initializes an already allocated OFXMLElement with the specified name
 *	  and namespace.
 *
 * @param name The name for the element
 * @param namespace_ The namespace for the element
 * @return An initialized OFXMLElement with the specified element name and
 *	   namespace
 */
- initWithName: (OFString*)name
     namespace: (OFString*)namespace_;

/*!
 * @brief Initializes an already allocated OFXMLElement with the specified name,
 *	  namespace and value.
 *
 * @param name The name for the element
 * @param namespace_ The namespace for the element
 * @param stringValue The value for the element
 * @return An initialized OFXMLElement with the specified element name,
 *	   namespace and value
 */
- initWithName: (OFString*)name
     namespace: (OFString*)namespace_
   stringValue: (OFString*)stringValue;

/*!
 * @brief Initializes an already allocated OFXMLElement with the specified
 *	  element.
 *
 * @param element An OFXMLElement to initialize the OFXMLElement with
 * @return A new autoreleased OFXMLElement with the contents of the specified
 *	   element
 */
- initWithElement: (OFXMLElement*)element;

/*!
 * @brief Parses the string and initializes an already allocated OFXMLElement
 *	  with it.
 *
 * @param string The string to parse
 * @return An initialized OFXMLElement with the contents of the string
 */
- initWithXMLString: (OFString*)string;

#ifdef OF_HAVE_FILES
/*!
 * @brief Parses the specified file and initializes an already allocated
 *	  OFXMLElement with it.
 *
 * @param path The path to the file
 * @return An initialized OFXMLElement with the contents of the specified file
 */
- initWithFile: (OFString*)path;
#endif

/*!
 * @brief Sets the name of the element.
 *
 * @param name The new name
 */
- (void)setName: (OFString*)name;

/*!
 * @brief Returns the name of the element.
 *
 * @return The name of the element
 */
- (OFString*)name;

/*!
 * @brief Sets the namespace of the element.
 *
 * @param namespace_ The new namespace
 */
- (void)setNamespace: (OFString*)namespace_;

/*!
 * @brief Returns the namespace of the element.
 *
 * @return The namespace of the element
 */
- (OFString*)namespace;

/*!
 * @brief Returns an OFArray with the attributes of the element.
 *
 * @return An OFArray with the attributes of the element
 */
- (OFArray*)attributes;

/*!
 * @brief Removes all children and adds the children from the specified array.
 *
 * @param children The new children to add
 */
- (void)setChildren: (OFArray*)children;

/*!
 * @brief Returns an array of OFXMLNodes with all children of the element.
 *
 * @return An array of OFXMLNodes with all children of the element
 */
- (OFArray*)children;

/*!
 * @brief Removes all children and sets the string value to the specified
 *	  string.
 *
 * @param stringValue The new string value for the element
 */
- (void)setStringValue: (OFString*)stringValue;

/*!
 * @brief Adds the specified attribute.
 *
 * If an attribute with the same name and namespace already exists, it is not
 * added.
 *
 * @param attribute The attribute to add
 */
- (void)addAttribute: (OFXMLAttribute*)attribute;

/*!
 * @brief Adds the specified attribute with the specified string value.
 *
 * If an attribute with the same name and namespace already exists, it is not
 * added.
 *
 * @param name The name of the attribute
 * @param stringValue The value of the attribute
 */
- (void)addAttributeWithName: (OFString*)name
		 stringValue: (OFString*)stringValue;

/*!
 * @brief Adds the specified attribute with the specified namespace and string
 *	  value.
 *
 * If an attribute with the same name and namespace already exists, it is not
 * added.
 *
 * @param name The name of the attribute
 * @param namespace_ The namespace of the attribute
 * @param stringValue The value of the attribute
 */
- (void)addAttributeWithName: (OFString*)name
		   namespace: (OFString*)namespace_
		 stringValue: (OFString*)stringValue;

/*!
 * @brief Returns the attribute with the specified name.
 *
 * @param attributeName The name of the attribute
 * @return The attribute with the specified name
 */
- (OFXMLAttribute*)attributeForName: (OFString*)attributeName;

/*!
 * @brief Returns the attribute with the specified name and namespace.
 *
 * @param attributeName The name of the attribute
 * @param attributeNS The namespace of the attribute
 * @return The attribute with the specified name and namespace
 */
- (OFXMLAttribute*)attributeForName: (OFString*)attributeName
			  namespace: (OFString*)attributeNS;

/*!
 * @brief Removes the attribute with the specified name.
 *
 * @param attributeName The name of the attribute
 */
- (void)removeAttributeForName: (OFString*)attributeName;

/*!
 * @brief Removes the attribute with the specified name and namespace.
 *
 * @param attributeName The name of the attribute
 * @param attributeNS The namespace of the attribute
 */
- (void)removeAttributeForName: (OFString*)attributeName
		     namespace: (OFString*)attributeNS;

/*!
 * @brief Sets a prefix for a namespace.
 *
 * @param prefix The prefix for the namespace
 * @param namespace_ The namespace for which the prefix is set
 */
- (void)setPrefix: (OFString*)prefix
     forNamespace: (OFString*)namespace_;

/*!
 * @brief Binds a prefix for a namespace.
 *
 * @param prefix The prefix for the namespace
 * @param namespace_ The namespace for which the prefix is bound
 */
- (void)bindPrefix: (OFString*)prefix
      forNamespace: (OFString*)namespace_;

/*!
 * @brief Sets the default namespace for the element to be used if there is no
 *	  parent.
 *
 * @param defaultNamespace The default namespace for the element
 */
- (void)setDefaultNamespace: (OFString*)defaultNamespace;

/*!
 * @brief Adds a child to the OFXMLElement.
 *
 * @param child An OFXMLNode which is added as a child
 */
- (void)addChild: (OFXMLNode*)child;

/*!
 * @brief Inserts a child at the specified index.
 *
 * @param child An OFXMLNode which is added as a child
 * @param index The index where the child is added
 */
- (void)insertChild: (OFXMLNode*)child
	    atIndex: (size_t)index;

/*!
 * @brief Inserts the specified children at the specified index.
 *
 * @param children An array of OFXMLNodes which are added as children
 * @param index The index where the child is added
 */
- (void)insertChildren: (OFArray*)children
	       atIndex: (size_t)index;

/*!
 * @brief Removes the first child that is equal to the specified OFXMLNode.
 *
 * @param child The child to remove from the OFXMLElement
 */
- (void)removeChild: (OFXMLNode*)child;

/*!
 * @brief Removes the child at the specified index.
 *
 * @param index The index of the child to remove
 */

- (void)removeChildAtIndex: (size_t)index;
/*!
 * @brief Replaces the first child that is equal to the specified OFXMLNode
 *	  with the specified node.
 *
 * @param child The child to replace
 * @param node The node to replace the child with
 */
- (void)replaceChild: (OFXMLNode*)child
	    withNode: (OFXMLNode*)node;

/*!
 * @brief Replaces the child at the specified index with the specified node.
 *
 * @param index The index of the child to replace
 * @param node The node to replace the child with
 */
- (void)replaceChildAtIndex: (size_t)index
		   withNode: (OFXMLNode*)node;

/*!
 * @brief Returns all children that are elements.
 *
 * @return All children that are elements
 */
- (OFArray*)elements;

/*!
 * @brief Returns all children that have the specified namespace.
 *
 * @return All children that have the specified namespace
 */
- (OFArray*)elementsForNamespace: (OFString*)elementNS;

/*!
 * @brief Returns the first child element with the specified name.
 *
 * @param elementName The name of the element
 * @return The first child element with the specified name
 */
- (OFXMLElement*)elementForName: (OFString*)elementName;

/*!
 * @brief Returns the child elements with the specified name.
 *
 * @param elementName The name of the elements
 * @return The child elements with the specified name
 */
- (OFArray*)elementsForName: (OFString*)elementName;

/*!
 * @brief Returns the first child element with the specified name and namespace.
 *
 * @param elementName The name of the element
 * @param elementNS The namespace of the element
 * @return The first child element with the specified name and namespace
 */
- (OFXMLElement*)elementForName: (OFString*)elementName
		      namespace: (OFString*)elementNS;

/*!
 * @brief Returns the child elements with the specified name and namespace.
 *
 * @param elementName The name of the elements
 * @param elementNS The namespace of the elements
 * @return The child elements with the specified name and namespace
 */
- (OFArray*)elementsForName: (OFString*)elementName
		  namespace: (OFString*)elementNS;
@end

#import "OFXMLElement+Serialization.h"
