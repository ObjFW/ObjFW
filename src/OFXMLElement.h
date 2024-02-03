/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

@class OFArray OF_GENERIC(ObjectType);
@class OFMutableArray OF_GENERIC(ObjectType);
@class OFMutableDictionary OF_GENERIC(KeyType, ObjectType);
@class OFMutableString;
@class OFStream;
@class OFString;
@class OFXMLAttribute;

/**
 * @class OFXMLElement OFXMLElement.h ObjFW/OFXMLElement.h
 *
 * @brief A class which stores an XML element.
 */
@interface OFXMLElement: OFXMLNode
{
	OFString *_name, *_Nullable _namespace;
	OFMutableArray OF_GENERIC(OFXMLAttribute *) *_Nullable _attributes;
	OFMutableDictionary OF_GENERIC(OFString *, OFString *) *_Nullable
	    _namespaces;
	OFMutableArray OF_GENERIC(OFXMLNode *) *_Nullable _children;
	OF_RESERVE_IVARS(OFXMLElement, 4)
}

/**
 * @brief The name of the element.
 */
@property (copy, nonatomic) OFString *name;

/**
 * @brief The namespace of the element.
 */
#ifndef __cplusplus
@property OF_NULLABLE_PROPERTY (copy, nonatomic) OFString *namespace;
#else
@property OF_NULLABLE_PROPERTY (copy, nonatomic,
    getter=namespace, setter=setNamespace:) OFString *nameSpace;
#endif

/**
 * @brief An array with the attributes of the element.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic)
    OFArray OF_GENERIC(OFXMLAttribute *) *attributes;

/**
 * @brief An array of @ref OFXMLNode with all children of the element.
 */
@property OF_NULLABLE_PROPERTY (nonatomic, copy)
    OFArray OF_GENERIC(OFXMLNode *) *children;

/**
 * @brief All children that are elements.
 */
@property (readonly, nonatomic) OFArray OF_GENERIC(OFXMLElement *) *elements;

/**
 * @brief Creates a new XML element with the specified name.
 *
 * @param name The name for the element
 * @return A new autoreleased OFXMLElement with the specified element name
 */
+ (instancetype)elementWithName: (OFString *)name;

/**
 * @brief Creates a new XML element with the specified name and string value.
 *
 * @param name The name for the element
 * @param stringValue The value for the element
 * @return A new autoreleased OFXMLElement with the specified element name and
 *	   value
 */
+ (instancetype)elementWithName: (OFString *)name
		    stringValue: (nullable OFString *)stringValue;

/**
 * @brief Creates a new XML element with the specified name and namespace.
 *
 * @param name The name for the element
 * @param nameSpace The namespace for the element
 * @return A new autoreleased OFXMLElement with the specified element name and
 *	   namespace
 */
+ (instancetype)elementWithName: (OFString *)name
		      namespace: (nullable OFString *)nameSpace;

/**
 * @brief Creates a new XML element with the specified name, namespace and
 * 	  string value.
 *
 * @param name The name for the element
 * @param nameSpace The namespace for the element
 * @param stringValue The value for the element
 * @return A new autoreleased OFXMLElement with the specified element name,
 *	   namespace and value
 */
+ (instancetype)elementWithName: (OFString *)name
		      namespace: (nullable OFString *)nameSpace
		    stringValue: (nullable OFString *)stringValue;

/**
 * @brief Parses the string and returns an OFXMLElement for it.
 *
 * @param string The string to parse
 * @return A new autoreleased OFXMLElement with the contents of the string
 * @throw OFMalformedXMLException The XML was malformed
 * @throw OFUnboundPrefixException A prefix was used that was not bound to any
 *				   namespace
 * @throw OFInvalidEncodingException The XML is not in the encoding it specified
 */
+ (instancetype)elementWithXMLString: (OFString *)string;

/**
 * @brief Parses the specified stream and returns an OFXMLElement for it.
 *
 * @param stream The stream to parse
 * @return A new autoreleased OFXMLElement with the contents of the specified
 *	   stream
 * @throw OFMalformedXMLException The XML was malformed
 * @throw OFUnboundPrefixException A prefix was used that was not bound to any
 *				   namespace
 * @throw OFInvalidEncodingException The XML is not in the encoding it specified
 */
+ (instancetype)elementWithStream: (OFStream *)stream;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFXMLElement with the specified name.
 *
 * @param name The name for the element
 * @return An initialized OFXMLElement with the specified element name
 */
- (instancetype)initWithName: (OFString *)name;

/**
 * @brief Initializes an already allocated OFXMLElement with the specified name
 *	  and string value.
 *
 * @param name The name for the element
 * @param stringValue The value for the element
 * @return An initialized OFXMLElement with the specified element name and
 *	   value
 */
- (instancetype)initWithName: (OFString *)name
		 stringValue: (nullable OFString *)stringValue;

/**
 * @brief Initializes an already allocated OFXMLElement with the specified name
 *	  and namespace.
 *
 * @param name The name for the element
 * @param nameSpace The namespace for the element
 * @return An initialized OFXMLElement with the specified element name and
 *	   namespace
 */
- (instancetype)initWithName: (OFString *)name
		   namespace: (nullable OFString *)nameSpace
    OF_DESIGNATED_INITIALIZER;

/**
 * @brief Initializes an already allocated OFXMLElement with the specified name,
 *	  namespace and value.
 *
 * @param name The name for the element
 * @param nameSpace The namespace for the element
 * @param stringValue The value for the element
 * @return An initialized OFXMLElement with the specified element name,
 *	   namespace and value
 */
- (instancetype)initWithName: (OFString *)name
		   namespace: (nullable OFString *)nameSpace
		 stringValue: (nullable OFString *)stringValue;

/**
 * @brief Parses the string and initializes an already allocated OFXMLElement
 *	  with it.
 *
 * @param string The string to parse
 * @return An initialized OFXMLElement with the contents of the string
 * @throw OFMalformedXMLException The XML was malformed
 * @throw OFUnboundPrefixException A prefix was used that was not bound to any
 *				   namespace
 * @throw OFInvalidEncodingException The XML is not in the encoding it specified
 */
- (instancetype)initWithXMLString: (OFString *)string;

/**
 * @brief Parses the specified stream and initializes an already allocated
 *	  OFXMLElement with it.
 *
 * @param stream The stream to parse
 * @return An initialized OFXMLElement with the contents of the specified stream
 * @throw OFMalformedXMLException The XML was malformed
 * @throw OFUnboundPrefixException A prefix was used that was not bound to any
 *				   namespace
 * @throw OFInvalidEncodingException The XML is not in the encoding it specified
 */
- (instancetype)initWithStream: (OFStream *)stream;

/**
 * @brief Sets a prefix for a namespace.
 *
 * @param prefix The prefix for the namespace
 * @param nameSpace The namespace for which the prefix is set
 */
- (void)setPrefix: (OFString *)prefix forNamespace: (OFString *)nameSpace;

/**
 * @brief Binds a prefix for a namespace.
 *
 * @param prefix The prefix for the namespace
 * @param nameSpace The namespace for which the prefix is bound
 */
- (void)bindPrefix: (OFString *)prefix forNamespace: (OFString *)nameSpace;

/**
 * @brief Adds the specified attribute.
 *
 * If an attribute with the same name and namespace already exists, it is not
 * added.
 *
 * @param attribute The attribute to add
 */
- (void)addAttribute: (OFXMLAttribute *)attribute;

/**
 * @brief Adds the specified attribute with the specified string value.
 *
 * If an attribute with the same name and namespace already exists, it is not
 * added.
 *
 * @param name The name of the attribute
 * @param stringValue The value of the attribute
 */
- (void)addAttributeWithName: (OFString *)name
		 stringValue: (OFString *)stringValue;

/**
 * @brief Adds the specified attribute with the specified namespace and string
 *	  value.
 *
 * If an attribute with the same name and namespace already exists, it is not
 * added.
 *
 * @param name The name of the attribute
 * @param nameSpace The namespace of the attribute
 * @param stringValue The value of the attribute
 */
- (void)addAttributeWithName: (OFString *)name
		   namespace: (nullable OFString *)nameSpace
		 stringValue: (OFString *)stringValue;

/**
 * @brief Returns the attribute with the specified name.
 *
 * @param attributeName The name of the attribute
 * @return The attribute with the specified name
 */
- (nullable OFXMLAttribute *)attributeForName: (OFString *)attributeName;

/**
 * @brief Returns the attribute with the specified name and namespace.
 *
 * @param attributeName The name of the attribute
 * @param attributeNS The namespace of the attribute
 * @return The attribute with the specified name and namespace
 */
- (nullable OFXMLAttribute *)attributeForName: (OFString *)attributeName
				    namespace: (nullable OFString *)attributeNS;

/**
 * @brief Removes the attribute with the specified name.
 *
 * @param attributeName The name of the attribute
 */
- (void)removeAttributeForName: (OFString *)attributeName;

/**
 * @brief Removes the attribute with the specified name and namespace.
 *
 * @param attributeName The name of the attribute
 * @param attributeNS The namespace of the attribute
 */
- (void)removeAttributeForName: (OFString *)attributeName
		     namespace: (nullable OFString *)attributeNS;

/**
 * @brief Adds a child to the OFXMLElement.
 *
 * @param child An OFXMLNode which is added as a child
 */
- (void)addChild: (OFXMLNode *)child;

/**
 * @brief Inserts a child at the specified index.
 *
 * @param child An OFXMLNode which is added as a child
 * @param index The index where the child is added
 */
- (void)insertChild: (OFXMLNode *)child atIndex: (size_t)index;

/**
 * @brief Inserts the specified children at the specified index.
 *
 * @param children An array of @ref OFXMLNode which are added as children
 * @param index The index where the child is added
 */
- (void)insertChildren: (OFArray OF_GENERIC(OFXMLNode *) *)children
	       atIndex: (size_t)index;

/**
 * @brief Removes the first child that is equal to the specified OFXMLNode.
 *
 * @param child The child to remove from the OFXMLElement
 */
- (void)removeChild: (OFXMLNode *)child;

/**
 * @brief Removes the child at the specified index.
 *
 * @param index The index of the child to remove
 */
- (void)removeChildAtIndex: (size_t)index;

/**
 * @brief Replaces the first child that is equal to the specified OFXMLNode
 *	  with the specified node.
 *
 * @param child The child to replace
 * @param node The node to replace the child with
 */
- (void)replaceChild: (OFXMLNode *)child withNode: (OFXMLNode *)node;

/**
 * @brief Replaces the child at the specified index with the specified node.
 *
 * @param index The index of the child to replace
 * @param node The node to replace the child with
 */
- (void)replaceChildAtIndex: (size_t)index withNode: (OFXMLNode *)node;

/**
 * @brief Returns all children that have the specified namespace.
 *
 * @return All children that have the specified namespace
 */
- (OFArray OF_GENERIC(OFXMLElement *) *)
    elementsForNamespace: (nullable OFString *)elementNS;

/**
 * @brief Returns the first child element with the specified name.
 *
 * @param elementName The name of the element
 * @return The first child element with the specified name
 */
- (nullable OFXMLElement *)elementForName: (OFString *)elementName;

/**
 * @brief Returns the child elements with the specified name.
 *
 * @param elementName The name of the elements
 * @return The child elements with the specified name
 */
- (OFArray OF_GENERIC(OFXMLElement *) *)
    elementsForName: (OFString *)elementName;

/**
 * @brief Returns the first child element with the specified name and namespace.
 *
 * @param elementName The name of the element
 * @param elementNS The namespace of the element
 * @return The first child element with the specified name and namespace
 */
- (nullable OFXMLElement *)elementForName: (OFString *)elementName
				namespace: (nullable OFString *)elementNS;

/**
 * @brief Returns the child elements with the specified name and namespace.
 *
 * @param elementName The name of the elements
 * @param elementNS The namespace of the elements
 * @return The child elements with the specified name and namespace
 */
- (OFArray OF_GENERIC(OFXMLElement *) *)
    elementsForName: (OFString *)elementName
	  namespace: (nullable OFString *)elementNS;

/**
 * @brief Returns an OFString representing the OFXMLElement as an XML string
 *	  with the specified indentation per level.
 *
 * @param indentation The indentation per level
 * @return An OFString representing the OFXMLNode as an XML string with
 *	   indentation
 * @throw OFUnboundNamespaceException The node uses a namespace that was not
 *				      bound to a prefix in a context where it
 *				      needs a prefix
 */
- (OFString *)XMLStringWithIndentation: (unsigned int)indentation;

/**
 * @brief Returns an OFString representing the OFXMLElement as an XML string
 *	  with the specified default namespace and indentation per level.
 *
 * @param defaultNS The default namespace
 * @param indentation The indentation per level
 * @return An OFString representing the OFXMLNode as an XML string with
 *	   indentation
 * @throw OFUnboundNamespaceException The node uses a namespace that was not
 *				      bound to a prefix in a context where it
 *				      needs a prefix
 */
- (OFString *)XMLStringWithDefaultNamespace: (OFString *)defaultNS
				indentation: (unsigned int)indentation;
@end

OF_ASSUME_NONNULL_END
