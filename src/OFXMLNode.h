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

#import "OFObject.h"
#import "OFSerialization.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFXMLNode OFXMLNode.h ObjFW/OFXMLNode.h
 *
 * @brief A class which stores an XML element.
 */
@interface OFXMLNode: OFObject <OFCopying, OFSerialization>
/*!
 * @brief Returns the contents of the receiver as a string value.
 *
 * @return A string with the string value
 */
- (OFString*)stringValue;

/*!
 * @brief Sets the string value of the receiver to the specified string.
 *
 * For an @ref OFXMLElement, it removes all children and creates a single child
 * with the specified string value.
 *
 * @param stringValue The new string value for the node
 */
- (void)setStringValue: (OFString*)stringValue;

/*!
 * @brief Returns the contents of the receiver as a decimal value.
 *
 * @return An integer with the decimal value
 */
- (intmax_t)decimalValue;

/*!
 * @brief Returns the contents of the receiver as a hexadecimal value.
 *
 * @return An integer with the hexadecimal value
 */
- (uintmax_t)hexadecimalValue;

/*!
 * @brief Returns the contents of the receiver as a float value.
 *
 * @return A float with the float value
 */
- (float)floatValue;

/*!
 * @brief Returns the contents of the receiver as a double value.
 *
 * @return A double with the double value
 */
- (double)doubleValue;

/*!
 * @brief Returns an OFString representing the OFXMLNode as an XML string.
 *
 * @return An OFString representing the OFXMLNode as an XML string
 */
- (OFString*)XMLString;

/*!
 * @brief Returns an OFString representing the OFXMLNode as an XML string with
 *	  indentation.
 *
 * @param indentation The indentation for the XML string
 * @return An OFString representing the OFXMLNode as an XML string with
 *	   indentation
 */
- (OFString*)XMLStringWithIndentation: (unsigned int)indentation;

/*!
 * @brief Returns an OFString representing the OFXMLNode as an XML string with
 *	  indentation for the specified level.
 *
 * @param indentation The indentation for the XML string
 * @param level The level of indentation
 * @return An OFString representing the OFXMLNode as an XML string with
 *	   indentation
 */
- (OFString*)XMLStringWithIndentation: (unsigned int)indentation
				level: (unsigned int)level;
@end

OF_ASSUME_NONNULL_END
