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

#import "OFObject.h"

/**
 * The OFString class can store and modify string of different types.
 */
@interface OFString: OFObject {}
/**
 * \param str A constant C string from which the new OFConstCString will be
 *	  created
 * \return A new OFConstCString
 */
+ newAsConstCString: (const char*)str;

/**
 * \param str A constant wide C string from which the new OFConstCString will be
 *	  created
 * \return A new OFConstWideCString
 */
+ newAsConstWideCString: (const wchar_t*)str;

/**
 * \param str A C string from which the new OFConstCString will be created
 * \return A new OFCString
 */
+ newAsCString: (char*)str;

/**
 * \param str A wide C string from which the new OFConstCString will be created
 * \return A new OFWideCString
 */
+ newAsWideCString: (wchar_t*)str;

/**
 * \return The OFString as a C-type string of the type it was created as
 */
- (char*)cString;

/**
 * \return The OFString as a C-type wide string of the type it was created as
 */
- (wchar_t*)wCString;

/**
 * \return The length of the OFString
 */
- (size_t)length;

/**
 * Sets the OFString to the specified OFString.
 *
 * \param str The OFString to set the current OFString to
 */
- (OFString*)setTo: (OFString*)str;

/**
 * Clones the OFString, creating a new one.
 * 
 * \return A copy of the OFString
 */
- (OFString*)clone;

/**
 * Compares the OFString to another OFString.
 *
 * \param str An OFString in a compatible type to compare with
 * \return An integer which is the result of the comparison, see strcmp
 */
- (int)compareTo: (OFString*)str;

/**
 * Append another OFString to the OFString.
 *
 * \param str An OFString in a compatible type to append
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
@end
