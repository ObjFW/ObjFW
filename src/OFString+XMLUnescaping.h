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

#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFString_XMLUnescaping_reference OF_VISIBILITY_HIDDEN;
#ifdef __cplusplus
}
#endif

#ifdef OF_HAVE_BLOCKS
/**
 * @brief A block which is called to replace unknown XML entities in an XML
 *	  string.
 *
 * @param string The XML string which contains an unknown entity
 * @param entity The XML entity which is unknown
 * @return A replacement string for the unknown entity
 */
typedef OFString *_Nullable (^OFStringXMLUnescapingBlock)(OFString *string,
    OFString *entity);
#endif

/**
 * @protocol OFStringXMLUnescapingDelegate OFString.h ObjFW/ObjFW.h
 *
 * @brief A protocol that needs to be implemented by delegates for
 *	  stringByXMLUnescapingWithHandler:.
 */
@protocol OFStringXMLUnescapingDelegate <OFObject>
/**
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
/**
 * @brief The string with XML entities unescapted.
 */
@property (readonly, nonatomic) OFString *stringByXMLUnescaping;

/**
 * @brief Unescapes XML in the string and uses the specified delegate for
 *	  unknown entities.
 *
 * @param delegate An OFXMLUnescapingDelegate as a handler for unknown entities
 * @throw OFInvalidFormatException The string is not a valid XML string
 * @throw OFUnknownXMLEntityException The string contains unknown XML entities
 */
- (OFString *)stringByXMLUnescapingWithDelegate:
    (nullable id <OFStringXMLUnescapingDelegate>)delegate;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief Unescapes XML in the string and uses the specified block for unknown
 *	  entities.
 *
 * @param block A block which handles unknown entities
 * @throw OFInvalidFormatException The string is not a valid XML string
 * @throw OFUnknownXMLEntityException The string contains unknown XML entities
 */
- (OFString *)stringByXMLUnescapingWithBlock: (OFStringXMLUnescapingBlock)block;
#endif
@end

OF_ASSUME_NONNULL_END
