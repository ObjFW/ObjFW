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

#import "OFObject.h"

/**
 * A class for storing and modifying strings.
 */
@interface OFString: OFObject
{
	wchar_t	*string;
	size_t  length;
}

/**
 * Creates a new OFString.
 * 
 * \return An initialized OFString
 */
+ new;

/**
 * Creates a new OFString from a C string.
 * 
 * \param str A C string to initialize the OFString with
 * \return A new OFString
 */
+ newFromCString: (const char*)str;

/**
 * Creates a new OFString from a wide C string.
 * 
 * \param str A wide C string to initialize the OFString with
 * \return A new OFString
 */
+ newFromWideCString: (const wchar_t*)str;

/**
 * Initializes an already allocated OFString.
 *
 * \return An initialized OFString
 */
- init;

/**
 * Initializes an already allocated OFString from a C string.
 * 
 * \param str A C string to initialize the OFString with
 * \return An initialized OFString
 */
- initFromCString: (const char*)str;

/**
 * Initializes an already allocated OFString from a wide C string.
 * 
 * \param str A wide C string to initialize the OFString with
 * \return An initialized OFString
 */
- initFromWideCString: (const wchar_t*)str;

/**
 * \return The OFString as a wide C string
 */
- (const wchar_t*)wideCString;

/**
 * \return The length of the OFString
 */
- (size_t)length;

/**
 * \return The OFString as a C string, if possible (if not, returns NULL).
 *         If not needed anymore, it is usefull to call freeMem:.
 */
- (char*)getCString;

/**
 * Clones the OFString, creating a new one.
 * 
 * \return A copy of the OFString
 */
- (OFString*)clone;

/**
 * Frees the OFString and sets it to the specified OFString.
 *
 * \param str An OFString to set the OFString to.
 * \return The new OFString
 */
- (OFString*)setTo: (OFString*)str;

/**
 * Compares the OFString to another OFString.
 *
 * \param str An OFString to compare with
 * \return An integer which is the result of the comparison, see wcscmp
 */
- (int)compareTo: (OFString*)str;

/**
 * Append another OFString to the OFString.
 *
 * \param str An OFString to append
 */
- append: (OFString*)str;

/**
 * Append a C string to the OFString.
 *
 * \param str A C string to append
 */
- appendCString: (const char*)str;

/**
 * Append a wide C string to the OFString.
 *
 * \param str A wide C string to append
 */
- appendWideCString: (const wchar_t*)str;

/**
 * Reverse the OFString.
 */
- reverse;

/**
 * Upper the OFString.
 */
- upper;

/**
 * Lower the OFString.
 */
- lower;
@end
