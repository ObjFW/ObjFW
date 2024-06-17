/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
 * @class OFXMLComment OFXMLComment.h ObjFW/ObjFW.h
 *
 * @brief A class for representing XML comments.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFXMLComment: OFXMLNode
{
	OFString *_text;
}

/**
 * @brief The comment text.
 */
@property (readonly, nonatomic) OFString *text;

/**
 * @brief Creates a new OFXMLComment with the specified text.
 *
 * @param text The text for the comment
 * @return A new OFXMLComment
 */
+ (instancetype)commentWithText: (OFString *)text;

/**
 * @brief Initializes an already allocated OFXMLComment with the specified
 *	  text.
 *
 * @param text The text for the comment
 * @return An initialized OFXMLComment
 */
- (instancetype)initWithText: (OFString *)text;
@end

OF_ASSUME_NONNULL_END
