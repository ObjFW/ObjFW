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

#import "OFXMLNode.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFXMLCharacters OFXMLCharacters.h ObjFW/ObjFW.h
 *
 * @brief A class representing XML characters.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFXMLCharacters: OFXMLNode
{
	OFString *_characters;
}

/**
 * @brief Creates a new OFXMLCharacters with the specified string.
 *
 * @param string The string value for the characters
 * @return A new OFXMLCharacters
 */
+ (instancetype)charactersWithString: (OFString *)string;

/**
 * @brief Initializes an already allocated OFXMLCharacters with the specified
 *	  string.
 *
 * @param string The string value for the characters
 * @return An initialized OFXMLCharacters
 */
- (instancetype)initWithString: (OFString *)string;
@end

OF_ASSUME_NONNULL_END
