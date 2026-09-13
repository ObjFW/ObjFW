/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFObject.h"
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFCharacterSet OFCharacterSet.h ObjFW/ObjFW.h
 *
 * @brief A class cluster representing a character set.
 *
 * @note Subclasses must implement @ref characterIsMember:.
 */
@interface OFCharacterSet: OFObject
{
	OF_RESERVE_IVARS(OFCharacterSet, 4)
}

#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nonatomic) OFCharacterSet *whitespaceCharacterSet;
@property (class, readonly, nonatomic) OFCharacterSet *newlineCharacterSet;
@property (class, readonly, nonatomic) OFCharacterSet *controlCharacterSet;
#endif

/**
 * @brief The inverted set, containing only the characters that do not exist in
 *	  the receiver.
 */
@property (readonly, nonatomic) OFCharacterSet *invertedSet;

/**
 * @brief Creates a new character set containing the characters of the
 *	  specified string.
 *
 * @param characters The characters for the character set
 * @return A new OFCharacterSet
 */
+ (instancetype)characterSetWithCharactersInString: (OFString *)characters;

/**
 * @brief Creates a new character set containing the characters in the specified
 *	  range.
 *
 * @param range The range of characters for the character set
 * @return A new OFCharacterSet
 */
+ (instancetype)characterSetWithRange: (OFRange)range;

/**
 * @brief A character set containing all Unicode characters in the category
 *	  `Zs` plus CHARACTER TABULATION (U+0009).
 */
+ (OFCharacterSet *)whitespaceCharacterSet;

/**
 * @brief A character set containing U+000A to U+000D, U+0085, U+2028 and
 *	  U+2029.
 */
+ (OFCharacterSet *)newlineCharacterSet;

/**
 * @brief A character set containing all Unicode characters in the category
 *	  `Cc`.
 */
+ (OFCharacterSet *)controlCharacterSet;

/**
 * @brief Initializes an already allocated character set with the characters of
 *	  the specified string.
 *
 * @param characters The characters for the character set
 * @return An initialized OFCharacterSet
 */
- (instancetype)initWithCharactersInString: (OFString *)characters;

/**
 * @brief Initializes an already allocated character set with the characters in
 *	  the specified range.
 *
 * @param range The range of characters for the character set
 * @return An initialized OFCharacterSet
 */
- (instancetype)initWithRange: (OFRange)range;

/**
 * @brief Returns whether the specified character is a member of the character
 *	  set.
 *
 * @param character The character that is checked for being a member of the
 *		    character set
 * @return Whether the specified character is a member of the character set.
 */
- (bool)characterIsMember: (OFUnichar)character;
@end

OF_ASSUME_NONNULL_END
