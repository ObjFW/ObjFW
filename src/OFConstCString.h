/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFString.h"

/**
 * An OFString using a constant C string as internal storage.
 */
@interface OFConstCString: OFString
{
	const char *string;
	size_t	   length;
}

/**
 * Initializes an already allocated OFConstCString.
 * 
 * \param str A constant C string to initialize the OFConstCString with
 * \return An initialized OFConstCString
 */
- initAsConstCString: (const char*)str;

/**
 * \return The OFConstCString as a constant C strin
 */
- (const char*)cString;

/**
 * \return The length of the OFConstCString
 */
- (size_t)length;

/**
 * Clones the OFConstCString, creating a new one.
 * 
 * \return A copy of the OFConstCString
 */
- (OFString*)clone;

/**
 * Compares the OFConstCString to another OFString.
 *
 * \param str An OFString in a compatible type to compare with
 * \return An integer which is the result of the comparison, see strcmp
 */
- (int)compareTo: (OFString*)str;
@end
