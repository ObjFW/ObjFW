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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFXMLNode OFXMLNode.h ObjFW/ObjFW.h
 *
 * @brief A class which stores an XML element.
 */
@interface OFXMLNode: OFObject <OFCopying>
{
	OF_RESERVE_IVARS(OFXMLNode, 4)
}

/**
 * @brief The contents of the node as a string value.
 *
 * For an @ref OFXMLElement, setting it removes all children and creates a
 * single child with the specified string value.
 */
@property (nonatomic, copy) OFString *stringValue;

/**
 * @brief The contents of the receiver as a `long long` value.
 *
 * @throw OFInvalidFormatException The node cannot be parsed as a `long long`
 */
@property (readonly, nonatomic) long long longLongValue;

/**
 * @brief The contents of the receiver as an `unsigned long long` value.
 *
 * @throw OFInvalidFormatException The node cannot be parsed as an
 *				   `unsigned long long`
 */
@property (readonly, nonatomic) unsigned long long unsignedLongLongValue;

/**
 * @brief The contents of the receiver as a float value.
 *
 * @throw OFInvalidFormatException The node cannot be parsed as a `float`
 */
@property (readonly, nonatomic) float floatValue;

/**
 * @brief The contents of the receiver as a double value.
 *
 * @throw OFInvalidFormatException The node cannot be parsed as a `double`
 */
@property (readonly, nonatomic) double doubleValue;

/**
 * @brief A string representing the node as an XML string.
 *
 * @throw OFUnboundNamespaceException The node uses a namespace that was not
 *				      bound to a prefix in a context where it
 *				      needs a prefix
 */
@property (readonly, nonatomic) OFString *XMLString;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief The contents of the receiver as a `long long` value in the specified
 *	  base.
 *
 * @param base The base to use. If the base is 0, base 16 is assumed if the
 * 	       string starts with 0x (after stripping white spaces). If the
 * 	       string starts with 0, base 8 is assumed. Otherwise, base 10 is
 * 	       assumed.
 * @return The contents of the receiver as a `long long` value in the specified
 *	   base
 */
- (long long)longLongValueWithBase: (unsigned char)base;

/**
 * @brief The contents of the receiver as an `unsigned long long` value in the
 *	  specified base.
 *
 * @param base The base to use. If the base is 0, base 16 is assumed if the
 * 	       string starts with 0x (after stripping white spaces). If the
 * 	       string starts with 0, base 8 is assumed. Otherwise, base 10 is
 * 	       assumed.
 * @return The contents of the receiver as an `unsigned long long` value in the
 * 	   specified base
 */
- (unsigned long long)unsignedLongLongValueWithBase: (unsigned char)base;
@end

OF_ASSUME_NONNULL_END
