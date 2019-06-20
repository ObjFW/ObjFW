/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFCharacterSet OFCharacterSet.h ObjFW/OFCharacterSet.h
 *
 * @brief A class cluster representing a character set.
 *
 * @note Subclasses must implement @ref characterIsMember:.
 */
@interface OFCharacterSet: OFObject
#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nonatomic) OFCharacterSet *whitespaceCharacterSet;
#endif

/*!
 * @brief The inverted set, containing only the characters that do not exist in
 *	  the receiver.
 */
@property (readonly, nonatomic) OFCharacterSet *invertedSet;

/*!
 * @brief Creates a new character set containing the characters of the
 *	  specified string.
 *
 * @param characters The characters for the character set
 * @return A new OFCharacterSet
 */
+ (instancetype)characterSetWithCharactersInString: (OFString *)characters;

/*!
 * @brief Creates a new character set containing the characters in the specified
 *	  range.
 *
 * @param range The range of characters for the character set
 * @return A new OFCharacterSet
 */
+ (instancetype)characterSetWithRange: (of_range_t)range;

/*!
 * @brief A character set containing all Unicode characters in the category
 *	  `Zs` plus CHARACTER TABULATION (U+0009).
 */
+ (OFCharacterSet *)whitespaceCharacterSet;

/*!
 * @brief Initializes an already allocated character set with the characters of
 *	  the specified string.
 *
 * @param characters The characters for the character set
 * @return An initialized OFCharacterSet
 */
- (instancetype)initWithCharactersInString: (OFString *)characters;

/*!
 * @brief Initializes an already allocated character set with the characters in
 *	  the specified range.
 *
 * @param range The range of characters for the character set
 * @return An initialized OFCharacterSet
 */
- (instancetype)initWithRange: (of_range_t)range;

/*!
 * @brief Returns whether the specified character is a member of the character
 *	  set.
 *
 * @param character The character that is checked for being a member of the
 *		    character set
 * @return Whether the specified character is a member of the character set.
 */
- (bool)characterIsMember: (of_unichar_t)character;
@end

OF_ASSUME_NONNULL_END
