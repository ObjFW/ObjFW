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

extern int _OFString_XMLUnescaping_reference;

#ifdef OF_HAVE_BLOCKS
typedef OFString* (^of_string_xml_unescaping_block_t)(OFString *str,
    OFString *entity);
#endif

/**
 * \brief A protocol that needs to be implemented by delegates for
 *	  -[stringByXMLUnescapingWithHandler:].
 */
@protocol OFStringXMLUnescapingDelegate
/**
 * This callback is called when an unknown entity was found while trying to
 * unescape XML. The callback is supposed to return a substitution for the
 * entity or nil if it is unknown to the callback as well, in which case an
 * exception will be thrown.
 *
 * \param entity The name of the entity that is unknown
 * \return A substitution for the entity or nil
 */
-	   (OFString*)string: (OFString*)str
  containsUnknownEntityNamed: (OFString*)entity;
@end

/**
 * \brief A category for unescaping XML in strings.
 */
@interface OFString (XMLUnescaping)
/**
 * Unescapes XML in the string.
 */
- (OFString*)stringByXMLUnescaping;

/**
 * Unescapes XML in the string and uses the specified delegate for unknown
 * entities.
 *
 * \param h An OFXMLUnescapingDelegate as a handler for unknown entities
 */
- (OFString*)stringByXMLUnescapingWithDelegate:
    (id <OFStringXMLUnescapingDelegate>)delegate;

/**
 * Unescapes XML in the string and uses the specified block for unknown
 * entities.
 *
 * \param h A block as a handler for unknown entities
 */
- (OFString*)stringByXMLUnescapingWithBlock:
    (of_string_xml_unescaping_block_t)block;
@end
