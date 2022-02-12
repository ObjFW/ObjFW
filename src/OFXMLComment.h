/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#import "OFXMLNode.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFXMLComment OFXMLComment.h ObjFW/OFXMLComment.h
 *
 * @brief A class for representing XML comments.
 */
@interface OFXMLComment: OFXMLNode
{
	OFString *_text;
	OF_RESERVE_IVARS(OFXMLComment, 4)
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

- (instancetype)initWithSerialization: (OFXMLElement *)element;
@end

OF_ASSUME_NONNULL_END
