/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include <stdio.h>
#include <stdarg.h>

#import "OFObject.h"

/**
 * A class for storing and modifying strings.
 */
@interface OFString: OFObject
{
	char   *string;
	size_t length;
	BOOL   is_utf8;
}

/**
 * \return A new autoreleased OFString
 */
+ string;

/**
 * Creates a new OFString from a C string.
 *
 * \param str A C string to initialize the OFString with
 * \return A new autoreleased OFString
 */
+ stringWithCString: (const char*)str;

/**
 * Creates a new OFString from a format C string.
 * See printf for the format syntax.
 *
 * \param fmt A C string used as format to initialize the OFString
 * \return A new autoreleased OFString
 */
+ stringWithFormat: (const char*)fmt, ...;

/**
 * Creates a new OFString from a format C string.
 * See printf for the format syntax.
 *
 * \param fmt A C string used as format to initialize the OFString
 * \param args The arguments used in the format string
 * \return A new autoreleased OFString
 */
+ stringWithFormat: (const char*)fmt
      andArguments: (va_list)args;

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
- initWithCString: (const char*)str;

/**
 * Initializes an already allocated OFString from a format C string.
 * See printf for the format syntax.
 *
 * \param fmt A C string used as format to initialize the OFString
 * \return An initialized OFString
 */
- initWithFormat: (const char*)fmt, ...;

/**
 * Initializes an already allocated OFString from a format C string.
 * See printf for the format syntax.
 *
 * \param fmt A C string used as format to initialize the OFString
 * \param args The arguments used in the format string
 * \return An initialized OFString
 */
- initWithFormat: (const char*)fmt
    andArguments: (va_list)args;

/**
 * \return The OFString as a wide C string
 */
- (const char*)cString;

/**
 * \return The length of the OFString
 */
- (size_t)length;

/**
 * Clones the OFString, creating a new one.
 *
 * \return A new autoreleased copy of the OFString
 */
- (id)copy;

/**
 * Compares the OFString to another object.
 *
 * \param obj An object to compare with
 * \return An integer which is the result of the comparison, see for example
 *	   strcmp
 */
- (int)compare: (id)obj;

/**
 * Sets the OFString to the specified OFString.
 *
 * \param str An OFString to set the OFString to.
 */
- setTo: (const char*)str;

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
 * Append a formatted C string to the OFString.
 * See printf for the format syntax.
 *
 * \param fmt A format C string which generates the string to append
 */
- appendWithFormatCString: (const char*)fmt, ...;

/**
 * Append a formatted C string to the OFString.
 * See printf for the format syntax.
 *
 * \param fmt A format C string which generates the string to append
 * \param args The arguments used in the format string
 */
- appendWithFormatCString: (const char*)fmt
	     andArguments: (va_list)args;

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
