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
#import "OFArray.h"

/**
 * A class for managing strings.
 */
@interface OFString: OFObject
{
	char	     *string;
#ifdef __objc_INCLUDE_GNU
	unsigned int length;
#else
	int	     length;
#if __LP64__
	int	     _unused;
#endif
#endif
}

/**
 * \return A new autoreleased OFMutableString
 */
+ string;

/**
 * Creates a new OFMutableString from a C string.
 *
 * \param str A C string to initialize the OFMutableString with
 * \return A new autoreleased OFMutableString
 */
+ stringWithCString: (const char*)str;

/**
 * Creates a new OFMutableString from a format C string.
 * See printf for the format syntax.
 *
 * \param fmt A string used as format to initialize the OFMutableString
 * \return A new autoreleased OFMutableString
 */
+ stringWithFormat: (OFString*)fmt, ...;

/**
 * Creates a new OFMutableString from a format C string.
 * See printf for the format syntax.
 *
 * \param fmt A string used as format to initialize the OFMutableString
 * \param args The arguments used in the format string
 * \return A new autoreleased OFMutableString
 */
+ stringWithFormat: (OFString*)fmt
      andArguments: (va_list)args;

/**
 * Initializes an already allocated OFString.
 *
 * \return An initialized OFString
 */
- init;

/**
 * \return The OFString as a C string
 */
- (const char*)cString;

/**
 * \return The length of the OFString
 */
- (size_t)length;

/**
 * Clones the OFString, creating a new one.
 *
 * \return A new autoreleased copy of the OFString as a OFMutableString
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
 * Appends another OFString to the OFString.
 *
 * \param str An OFString to append
 */
- append: (OFString*)str;

/**
 * Appends a C string to the OFString.
 *
 * \param str A C string to append
 */
- appendCString: (const char*)str;

/**
 * Appends a formatted C string to the OFString.
 * See printf for the format syntax.
 *
 * \param fmt A format string which generates the string to append
 */
- appendWithFormat: (OFString*)fmt, ...;

/**
 * Appends a formatted C string to the OFString.
 * See printf for the format syntax.
 *
 * \param fmt A format string which generates the string to append
 * \param args The arguments used in the format string
 */
- appendWithFormat: (OFString*)fmt
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

/**
 * Splits an OFString into an OFArray of OFStrings.
 *
 * \param delimiter The delimiter for splitting
 * \return An autoreleased OFArray with the splitted string
 */
- (OFArray*)splitWithDelimiter: (OFString*)delimiter;
@end

#import "OFConstString.h"
#import "OFMutableString.h"
