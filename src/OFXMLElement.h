/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#import "OFXMLNode.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;
@class OFMutableString;
#ifndef DOXYGEN
@class OFArray OF_GENERIC(ObjectType);
@class OFMutableArray OF_GENERIC(ObjectType);
@class OFMutableDictionary OF_GENERIC(KeyType, ObjectType);
#endif
@class OFXMLAttribute;

/*!
 * @class OFXMLElement OFXMLElement.h ObjFW/OFXMLElement.h
 *
 * @brief A class which stores an XML element.
 */
@interface OFXMLElement: OFXMLNode
{
	OFString *_name, *_namespace, *_defaultNamespace;
	OFMutableArray OF_GENERIC(OFXMLAttribute*) *_attributes;
	OFMutableDictionary OF_GENERIC(OFString*, OFString*) *_namespaces;
	OFMutableArray OF_GENERIC(OFXMLNode*) *_children;
}

/*!
 * The name of the element.
 */
@property (copy) OFString *name;

/*!
 * The namespace of the element.
 */
#ifndef __cplusplus
@property OF_NULLABLE_PROPERTY (copy) OFString *namespace;
#else
@property OF_NULLABLE_PROPERTY (copy, getter=namespace, setter=setNamespace:)
    OFString *namespace_;
#endif

/*!
 * The default namespace for the element to be used if there is no parent.
 */
@property OF_NULLABLE_PROPERTY (copy) OFString *defaultNamespace;

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
		    stringValue: (nullable OFString*)stringValue;

/*!
 * @brief Creates a new XML element with the specified name and namespace.
 *
 * @param name The name for the element
 * @param namespace_ The namespace for the element
 * @return A new autoreleased OFXMLElement with the specified element name and
 *	   namespace
 */
+ (instancetype)elementWithName: (OFString*)name
		      namespace: (nullable OFString*)namespace_;

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
		      namespace: (nullable OFString*)namespace_
		    stringValue: (nullable OFString*)stringValue;

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
   stringValue: (nullable OFString*)stringValue;

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
     namespace: (nullable OFString*)namespace_;

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
     namespace: (nullable OFString*)namespace_
   stringValue: (nullable OFString*)stringValue;

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
 * @brief Returns an OFArray with the attributes of the element.
 *
 * @return An OFArray with the attributes of the element
 */
- (nullable OFArray OF_GENERIC(OFXMLAttribute*)*)attributes;

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
		   namespace: (nullable OFString*)namespace_
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
			  namespace: (nullable OFString*)attributeNS;

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
		     namespace: (nullable OFString*)attributeNS;

/*!
 * @brief Removes all children and adds the children from the specified array.
 *
 * @param children The new children to add
 */
- (void)setChildren: (nullable OFArray OF_GENERIC(OFXMLNode*)*)children;

/*!
 * @brief Returns an array of OFXMLNodes with all children of the element.
 *
 * @return An array of OFXMLNodes with all children of the element
 */
- (nullable OFArray OF_GENERIC(OFXMLNode*)*)children;

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
- (void)insertChildren: (OFArray OF_GENERIC(OFXMLNode*)*)children
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
- (OFArray OF_GENERIC(OFXMLElement*)*)elements;

/*!
 * @brief Returns all children that have the specified namespace.
 *
 * @return All children that have the specified namespace
 */
- (OFArray OF_GENERIC(OFXMLElement*)*)elementsForNamespace:
    (nullable OFString*)elementNS;

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
- (OFArray OF_GENERIC(OFXMLElement*)*)elementsForName: (OFString*)elementName;

/*!
 * @brief Returns the first child element with the specified name and namespace.
 *
 * @param elementName The name of the element
 * @param elementNS The namespace of the element
 * @return The first child element with the specified name and namespace
 */
- (OFXMLElement*)elementForName: (OFString*)elementName
		      namespace: (nullable OFString*)elementNS;

/*!
 * @brief Returns the child elements with the specified name and namespace.
 *
 * @param elementName The name of the elements
 * @param elementNS The namespace of the elements
 * @return The child elements with the specified name and namespace
 */
- (OFArray OF_GENERIC(OFXMLElement*)*)
    elementsForName: (OFString*)elementName
	  namespace: (nullable OFString*)elementNS;
@end

OF_ASSUME_NONNULL_END

#import "OFXMLElement+Serialization.h"
