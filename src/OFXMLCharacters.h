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

#import "OFXMLNode.h"

/**
 * \brief A class representing XML characters.
 */
@interface OFXMLCharacters: OFXMLNode
{
	OFString *characters;
}

/**
 * \brief Creates a new OFXMLCharacters with the specified string.
 *
 * \param string The string value for the characters
 * \return A new OFXMLCharacters
 */
+ (instancetype)charactersWithString: (OFString*)string;

/**
 * \brief Initializes an already allocated OFXMLCharacters with the specified
 *	  string.
 *
 * \param string The string value for the characters
 * \return An initialized OFXMLCharacters
 */
- initWithString: (OFString*)string;
@end
