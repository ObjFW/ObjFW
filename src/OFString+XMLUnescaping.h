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

#import "OFString.h"

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFString_XMLUnescaping_reference;
#ifdef __cplusplus
}
#endif

#ifdef OF_HAVE_BLOCKS
typedef OFString* (^of_string_xml_unescaping_block_t)(OFString *str,
    OFString *entity);
#endif

/*!
 * @brief A protocol that needs to be implemented by delegates for
 *	  -[stringByXMLUnescapingWithHandler:].
 */
@protocol OFStringXMLUnescapingDelegate <OFObject>
/*!
 * @brief This callback is called when an unknown entity was found while trying
 *	  to unescape XML.
 *
 * The callback is supposed to return a substitution for the entity or nil if
 * it is unknown to the callback as well, in which case an exception will be
 * thrown.
 *
 * @param str The string which contains the unknown entity
 * @param entity The name of the entity that is unknown
 * @return A substitution for the entity or nil
 */
-	   (OFString*)string: (OFString*)str
  containsUnknownEntityNamed: (OFString*)entity;
@end

/*!
 * @brief A category for unescaping XML in strings.
 */
@interface OFString (XMLUnescaping)
/*!
 * @brief Unescapes XML in the string.
 */
- (OFString*)stringByXMLUnescaping;

/*!
 * @brief Unescapes XML in the string and uses the specified delegate for
 *	  unknown entities.
 *
 * @param delegate An OFXMLUnescapingDelegate as a handler for unknown entities
 */
- (OFString*)stringByXMLUnescapingWithDelegate:
    (id <OFStringXMLUnescapingDelegate>)delegate;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief Unescapes XML in the string and uses the specified block for unknown
 *	  entities.
 *
 * @param block A block which handles unknown entities
 */
- (OFString*)stringByXMLUnescapingWithBlock:
    (of_string_xml_unescaping_block_t)block;
#endif
@end
