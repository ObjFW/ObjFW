/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#import "OFXMLNode.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;

/**
 * @class OFXMLAttribute OFXMLAttribute.h ObjFW/ObjFW.h
 *
 * @brief A representation of an attribute of an XML element as an object.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFXMLAttribute: OFXMLNode
{
#if defined(OF_XML_ELEMENT_M) || defined(OF_XML_PARSER_M)
@public
#endif
	OFString *_name, *_Nullable _namespace, *_stringValue;
	bool _useDoubleQuotes;
}

/**
 * @brief The name of the attribute.
 */
@property (readonly, nonatomic) OFString *name;

/**
 * @brief The namespace of the attribute.
 */
#ifndef __cplusplus
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *namespace;
#else
@property OF_NULLABLE_PROPERTY (readonly, nonatomic, getter=namespace)
    OFString *nameSpace;
#endif

/**
 * @brief Creates a new XML attribute.
 *
 * @param name The name of the attribute
 * @param stringValue The string value of the attribute
 * @return A new autoreleased OFXMLAttribute with the specified parameters
 */
+ (instancetype)attributeWithName: (OFString *)name
		      stringValue: (OFString *)stringValue;

/**
 * @brief Creates a new XML attribute.
 *
 * @param name The name of the attribute
 * @param nameSpace The namespace of the attribute
 * @param stringValue The string value of the attribute
 * @return A new autoreleased OFXMLAttribute with the specified parameters
 */
+ (instancetype)attributeWithName: (OFString *)name
			namespace: (nullable OFString *)nameSpace
		      stringValue: (OFString *)stringValue;

/**
 * @brief Initializes an already allocated OFXMLAttribute.
 *
 * @param name The name of the attribute
 * @param stringValue The string value of the attribute
 * @return An initialized OFXMLAttribute with the specified parameters
 */
- (instancetype)initWithName: (OFString *)name
		 stringValue: (OFString *)stringValue;

/**
 * @brief Initializes an already allocated OFXMLAttribute.
 *
 * @param name The name of the attribute
 * @param nameSpace The namespace of the attribute
 * @param stringValue The string value of the attribute
 * @return An initialized OFXMLAttribute with the specified parameters
 */
- (instancetype)initWithName: (OFString *)name
		   namespace: (nullable OFString *)nameSpace
		 stringValue: (OFString *)stringValue OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
