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
#import "OFSerialization.h"

@class OFString;

/**
 * \brief A representation of an attribute of an XML element as an object.
 */
@interface OFXMLAttribute: OFObject <OFSerialization>
{
@public
	OFString *name;
	OFString *ns;
	OFString *stringValue;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, retain) OFString *name;
@property (readonly, retain, getter=namespace) OFString *ns;
@property (readonly, retain) OFString *stringValue;
#endif

/**
 * \brief Creates a new XML attribute.
 *
 * \param name The name of the attribute
 * \param ns The namespace of the attribute
 * \param value The string value of the attribute
 * \return A new autoreleased OFXMLAttribute with the specified parameters
 */
+ attributeWithName: (OFString*)name
	  namespace: (OFString*)ns
	stringValue: (OFString*)value;

/**
 * \brief Initializes an already allocated OFXMLAttribute.
 *
 * \param name The name of the attribute
 * \param ns The namespace of the attribute
 * \param value The string value of the attribute
 * \return An initialized OFXMLAttribute with the specified parameters
 */
- initWithName: (OFString*)name
     namespace: (OFString*)ns
   stringValue: (OFString*)value;

/**
 * \brief Returns the name of the attribute as an autoreleased OFString.
 *
 * \return The name of the attribute as an autoreleased OFString
 */
- (OFString*)name;

/**
 * \brief Returns the namespace of the attribute as an autoreleased OFString.
 *
 * \return The namespace of the attribute as an autoreleased OFString
 */
- (OFString*)namespace;

/**
 * \brief Returns the string value of the attribute as an autoreleased OFString.
 *
 * \return The string value of the attribute as an autoreleased OFString
 */
- (OFString*)stringValue;

/**
 * \brief Returns an integer with the decimal value of the attribute.
 *
 * \return An integer with the decimal value of the attribute
 */
- (intmax_t)decimalValue;

/**
 * \brief Returns an integer with the hexadecimal value of the attribute.
 *
 * \return An integer with the hexadecimal value of the attribute
 */
- (uintmax_t)hexadecimalValue;

/**
 * \brief Returns a float with the float value of the attribute.
 *
 * \return A float with the float value of the attribute
 */
- (float)floatValue;

/**
 * \brief Returns a double with the double value of the attribute.
 *
 * \return A double with the double value of the attribute
 */
- (double)doubleValue;
@end
