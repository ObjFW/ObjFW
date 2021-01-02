/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

OF_ASSUME_NONNULL_BEGIN

@class OFXMLElement;

/**
 * @class OFXMLNode OFXMLNode.h ObjFW/OFXMLNode.h
 *
 * @brief A class which stores an XML element.
 */
@interface OFXMLNode: OFObject <OFCopying, OFSerialization>
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
 */
@property (readonly, nonatomic) long long longLongValue;

/**
 * @brief The contents of the receiver as an `unsigned long long` value.
 */
@property (readonly, nonatomic) unsigned long long unsignedLongLongValue;

/**
 * @brief The contents of the receiver as a float value.
 */
@property (readonly, nonatomic) float floatValue;

/**
 * @brief The contents of the receiver as a double value.
 */
@property (readonly, nonatomic) double doubleValue;

/**
 * @brief A string representing the node as an XML string.
 */
@property (readonly, nonatomic) OFString *XMLString;

- (instancetype)init OF_UNAVAILABLE;
- (instancetype)initWithSerialization: (OFXMLElement *)element OF_UNAVAILABLE;

/**
 * @brief Returns an OFString representing the OFXMLNode as an XML string with
 *	  indentation.
 *
 * @param indentation The indentation for the XML string
 * @return An OFString representing the OFXMLNode as an XML string with
 *	   indentation
 */
- (OFString *)XMLStringWithIndentation: (unsigned int)indentation;

/**
 * @brief Returns an OFString representing the OFXMLNode as an XML string with
 *	  indentation for the specified level.
 *
 * @param indentation The indentation for the XML string
 * @param level The level of indentation
 * @return An OFString representing the OFXMLNode as an XML string with
 *	   indentation
 */
- (OFString *)XMLStringWithIndentation: (unsigned int)indentation
				 level: (unsigned int)level;

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
- (long long)longLongValueWithBase: (int)base;

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
- (unsigned long long)unsignedLongLongValueWithBase: (int)base;
@end

OF_ASSUME_NONNULL_END
