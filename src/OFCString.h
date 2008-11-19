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

#import <stddef.h>

#import "OFString.h"

/**
 * An OFString using a C string as internal storage.
 */
@interface OFCString: OFString
{
	char   *string;
	size_t length;
}

/**
 * Initializes an already allocated OFCString.
 * 
 * \param str A C string to initialize the OFCString with
 * \return An initialized OFCString
 */
- initAsCString: (char*)str;

/**
 * \return The OFCString as a C string
 */
- (char*)cString;

/**
 * \return The length of the OFCString
 */
- (size_t)length;

/**
 * Clones the OFCString, creating a new one.
 * 
 * \return A copy of the OFCString
 */
- (OFString*)clone;

/**
 * Compares the OFCString to another OFString.
 *
 * \param str An OFString in a compatible type to compare with
 * \return An integer which is the result of the comparison, see strcmp
 */
- (int)compareTo: (OFString*)str;

/**
 * Append another OFString to the OFCString.
 *
 * \param str An OFString in a compatible type to append
 */
- append: (OFString*)str;

/**
 * Append a C string to the OFCString.
 *
 * \param str A C string to append
 */
- appendCString: (const char*)str;

/**
 * Reverse the OFCString.
 */
- reverse;
@end
