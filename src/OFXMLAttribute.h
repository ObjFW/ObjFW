/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

/*!
 * @class OFXMLAttribute OFXMLAttribute.h ObjFW/OFXMLAttribute.h
 *
 * @brief A representation of an attribute of an XML element as an object.
 */
@interface OFXMLAttribute: OFXMLNode
{
#if defined(OF_XML_ELEMENT_M) || defined(OF_XML_PARSER_M)
@public
#endif
	OFString *_name, *_Nullable _namespace, *_stringValue;
}

/*!
 * @brief The name of the attribute.
 */
@property (readonly, nonatomic) OFString *name;

/*!
 * @brief The namespace of the attribute.
 */
#ifndef __cplusplus
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *namespace;
#else
@property OF_NULLABLE_PROPERTY (readonly, nonatomic, getter=namespace)
    OFString *namespace_;
#endif

/*!
 * @brief Creates a new XML attribute.
 *
 * @param name The name of the attribute
 * @param stringValue The string value of the attribute
 * @return A new autoreleased OFXMLAttribute with the specified parameters
 */
+ (instancetype)attributeWithName: (OFString *)name
		      stringValue: (OFString *)stringValue;

/*!
 * @brief Creates a new XML attribute.
 *
 * @param name The name of the attribute
 * @param namespace_ The namespace of the attribute
 * @param stringValue The string value of the attribute
 * @return A new autoreleased OFXMLAttribute with the specified parameters
 */
+ (instancetype)attributeWithName: (OFString *)name
			namespace: (nullable OFString *)namespace_
		      stringValue: (OFString *)stringValue;

/*!
 * @brief Initializes an already allocated OFXMLAttribute.
 *
 * @param name The name of the attribute
 * @param stringValue The string value of the attribute
 * @return An initialized OFXMLAttribute with the specified parameters
 */
- (instancetype)initWithName: (OFString *)name
		 stringValue: (OFString *)stringValue;

/*!
 * @brief Initializes an already allocated OFXMLAttribute.
 *
 * @param name The name of the attribute
 * @param namespace_ The namespace of the attribute
 * @param stringValue The string value of the attribute
 * @return An initialized OFXMLAttribute with the specified parameters
 */
- (instancetype)initWithName: (OFString *)name
		   namespace: (nullable OFString *)namespace_
		 stringValue: (OFString *)stringValue;

- (instancetype)initWithSerialization: (OFXMLElement *)element;
@end

OF_ASSUME_NONNULL_END
