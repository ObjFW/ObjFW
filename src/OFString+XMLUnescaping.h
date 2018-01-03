/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

/*! @file */

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFString_XMLUnescaping_reference;
#ifdef __cplusplus
}
#endif

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief A block which is called to replace unknown XML entities in an XML
 *	  string.
 *
 * @param string The XML string which contains an unknown entity
 * @param entity The XML entity which is unknown
 * @return A replacement string for the unknown entity
 */
typedef OFString *_Nullable (^of_string_xml_unescaping_block_t)(
    OFString *string, OFString *entity);
#endif

/*!
 * @protocol OFStringXMLUnescapingDelegate OFString.h ObjFW/OFString.h
 *
 * @brief A protocol that needs to be implemented by delegates for
 *	  stringByXMLUnescapingWithHandler:.
 */
@protocol OFStringXMLUnescapingDelegate <OFObject>
/*!
 * @brief This callback is called when an unknown entity was found while trying
 *	  to unescape XML.
 *
 * The callback is supposed to return a substitution for the entity or `nil` if
 * it is unknown to the callback as well, in which case an exception will be
 * thrown.
 *
 * @param string The string which contains the unknown entity
 * @param entity The name of the entity that is unknown
 * @return A substitution for the entity or `nil`
 */
- (nullable OFString *)string: (OFString *)string
   containsUnknownEntityNamed: (OFString *)entity;
@end

@interface OFString (XMLUnescaping)
/*!
 * @brief The string with XML entities unescapted.
 */
@property (readonly, nonatomic) OFString *stringByXMLUnescaping;

/*!
 * @brief Unescapes XML in the string and uses the specified delegate for
 *	  unknown entities.
 *
 * @param delegate An OFXMLUnescapingDelegate as a handler for unknown entities
 */
- (OFString *)stringByXMLUnescapingWithDelegate:
    (nullable id <OFStringXMLUnescapingDelegate>)delegate;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief Unescapes XML in the string and uses the specified block for unknown
 *	  entities.
 *
 * @param block A block which handles unknown entities
 */
- (OFString *)stringByXMLUnescapingWithBlock:
    (of_string_xml_unescaping_block_t)block;
#endif
@end

OF_ASSUME_NONNULL_END
