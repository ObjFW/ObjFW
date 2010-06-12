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

extern int _OFString_XMLEscaping_reference;

/**
 * \brief A category to escape strings for use in an XML document.
 */
@interface OFString (XMLEscaping)
/**
 * Escapes a string for use in an XML document.
 *
 * \return A new autoreleased string
 */
- (OFString*)stringByXMLEscaping;
@end
