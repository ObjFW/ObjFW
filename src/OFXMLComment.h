/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#import "OFXMLNode.h"

/**
 * \brief A class for representing XML comments.
 */
@interface OFXMLComment: OFXMLNode
{
	OFString *comment;
}

/**
 * \brief Creates a new OFXMLComment with the specified string.
 *
 * \param string The string for the comment
 * \return A new OFXMLComment
 */
+ commentWithString: (OFString*)string;

/**
 * \brief Initializes an already allocated OFXMLComment with the specified
 *	  string.
 *
 * \param string The string for the comment
 * \return An initialized OFXMLComment
 */
- initWithString: (OFString*)string;
@end
