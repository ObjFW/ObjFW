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

#import <wchar.h>
#import <stddef.h>

#import "OFString.h"

/**
 * An OFString using a wide C string as internal storage.
 */
@interface OFWideCString: OFString
{
	wchar_t	*string;
	size_t  length;
}

/**
 * Initializes an already allocated OFWideCString.
 * 
 * \param str A wide C string to initialize the OFWideCString with
 * \return An initialized OFWideCString
 */
- initAsWideCString: (wchar_t*)str;

/**
 * \return The OFWideCString as a wide C string
 */
- (wchar_t*)wCString;

/**
 * \return The length of the OFWideCString
 */
- (size_t)length;

/**
 * Clones the OFWideCString, creating a new one.
 * 
 * \return A copy of the OFWideCString
 */
- (OFString*)clone;

/**
 * Compares the OFWideCString to another OFString.
 *
 * \param str An OFString in a compatible type to compare with
 * \return An integer which is the result of the comparison, see wcscmp
 */
- (int)compareTo: (OFString*)str;

/**
 * Append another OFString to the OFWideCString.
 *
 * \param str An OFString in a compatible type to append
 */
- append: (OFString*)str;

/**
 * Append a wide C string to the OFWideCString.
 *
 * \param str A wide C string to append
 */
- appendWideCString: (const wchar_t*)str;

/**
 * Reverse the OFWideCString.
 */
- reverse;
@end
