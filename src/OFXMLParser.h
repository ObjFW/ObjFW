/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFString.h"

extern int _OFXMLParser_reference;

/**
 * \brief A protocol that needs to be implemented by delegates for
 *	  -[stringByXMLUnescapingWithHandler:].
 */
@protocol OFXMLUnescapingDelegate
/**
 * This callback is called when an unknown entity was found while trying to
 * unescape XML. The callback is supposed to return a substitution for the
 * entity or nil if it is unknown to the callback as well, in which case an
 * exception will be thrown.
 *
 * \param entity The name of the entity that is unknown
 * \return A substitution for the entity or nil
 */
- (OFString*)foundUnknownEntityNamed: (OFString*)entity;
@end

/**
 * \brief A category for unescaping XML in strings.
 */
@interface OFString (OFXMLUnescaping)
/**
 * Unescapes XML in the string.
 */
- stringByXMLUnescaping;

/**
 * Unescapes XML in the string and uses the specified handler for unknown
 * entities.
 *
 * \param h An OFXMLUnescapingDelegate as a handler for unknown entities
 */
- stringByXMLUnescapingWithHandler: (OFObject <OFXMLUnescapingDelegate>*)h;
@end
