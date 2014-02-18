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

/*!
 * @class OFXMLAttribute OFXMLAttribute.h ObjFW/OFXMLAttribute.h
 *
 * @brief A representation of an attribute of an XML element as an object.
 */
@interface OFXMLAttribute: OFXMLNode
{
@public
	OFString *_name, *_namespace, *_stringValue;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, copy) OFString *name;
# ifdef __cplusplus
@property (readonly, copy, getter=namespace) OFString *namespace_;
# else
@property (readonly, copy) OFString *namespace;
# endif
@property (readonly, copy) OFString *stringValue;
#endif

/*!
 * @brief Creates a new XML attribute.
 *
 * @param name The name of the attribute
 * @param stringValue The string value of the attribute
 * @return A new autoreleased OFXMLAttribute with the specified parameters
 */
+ (instancetype)attributeWithName: (OFString*)name
		      stringValue: (OFString*)stringValue;

/*!
 * @brief Creates a new XML attribute.
 *
 * @param name The name of the attribute
 * @param namespace_ The namespace of the attribute
 * @param stringValue The string value of the attribute
 * @return A new autoreleased OFXMLAttribute with the specified parameters
 */
+ (instancetype)attributeWithName: (OFString*)name
			namespace: (OFString*)namespace_
		      stringValue: (OFString*)stringValue;

/*!
 * @brief Initializes an already allocated OFXMLAttribute.
 *
 * @param name The name of the attribute
 * @param stringValue The string value of the attribute
 * @return An initialized OFXMLAttribute with the specified parameters
 */
- initWithName: (OFString*)name
   stringValue: (OFString*)stringValue;

/*!
 * @brief Initializes an already allocated OFXMLAttribute.
 *
 * @param name The name of the attribute
 * @param namespace_ The namespace of the attribute
 * @param stringValue The string value of the attribute
 * @return An initialized OFXMLAttribute with the specified parameters
 */
- initWithName: (OFString*)name
     namespace: (OFString*)namespace_
   stringValue: (OFString*)stringValue;

/*!
 * @brief Returns the name of the attribute as an autoreleased OFString.
 *
 * @return The name of the attribute as an autoreleased OFString
 */
- (OFString*)name;

/*!
 * @brief Returns the namespace of the attribute as an autoreleased OFString.
 *
 * @return The namespace of the attribute as an autoreleased OFString
 */
- (OFString*)namespace;
@end
