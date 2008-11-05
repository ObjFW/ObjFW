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
 * An OFString using a constant wide C string as internal storage.
 */
@interface OFConstWideCString: OFString
{
	const wchar_t *string;
	size_t	      length;
}

/**
 * Initializes an already allocated OFConstWideCString.
 * 
 * \param str A constant wide C string to initialize the OFConstWideCString
 * 	  with.
 * \returns An initialized OFConstWideCString
 */
- initAsConstWideCString: (const wchar_t*)wstr;

/**
 * \return The OFConstWideCString as a constant wide C string.
 */
- (const wchar_t*)wcString;

/**
 * \return The length of the OFConstWideCString.
 */
- (size_t)length;

/**
 * Clones the OFConstWideCString, creating a new one.
 * 
 * \return A copy of the OFConstWideCString
 */
- (OFString*)clone;

/**
 * Compares the OFConstWideCString to another OFString.
 *
 * \param str An OFString in a compatible type to compare with
 * \return An integer which is the result of the comparison, see wcscmp.
 */
- (int)compareTo: (OFString*)str;
@end
