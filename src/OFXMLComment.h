/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#import "OFXMLNode.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFXMLComment OFXMLComment.h ObjFW/OFXMLComment.h
 *
 * @brief A class for representing XML comments.
 */
@interface OFXMLComment: OFXMLNode
{
	OFString *_comment;
}

/*!
 * @brief Creates a new OFXMLComment with the specified string.
 *
 * @param string The string for the comment
 * @return A new OFXMLComment
 */
+ (instancetype)commentWithString: (OFString *)string;

/*!
 * @brief Initializes an already allocated OFXMLComment with the specified
 *	  string.
 *
 * @param string The string for the comment
 * @return An initialized OFXMLComment
 */
- initWithString: (OFString *)string;
@end

OF_ASSUME_NONNULL_END
