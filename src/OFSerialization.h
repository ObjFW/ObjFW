/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#define OF_SERIALIZATION_NS @"https://webkeks.org/objfw/serialization"

@class OFXMLElement;

/**
 * \brief A protocol for serializing objects.
 */
@protocol OFSerialization
/**
 * \brief Initializes the object with the specified XML element serialization.
 *
 * \param element An OFXMLElement with the serialized object
 * \return An initialized object
 */
- initWithSerialization: (OFXMLElement*)element;

/**
 * \brief Serializes the object into an XML element.
 *
 * \return The object serialized into an XML element
 */
- (OFXMLElement*)XMLElementBySerializing;
@end
