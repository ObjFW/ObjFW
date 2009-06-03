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

extern int of_string_check_utf8(const char *str, size_t len);

/**
 * A class for managing strings.
 */
@interface OFString: OFObject <OFCopying, OFMutableCopying>
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
	BOOL	     is_utf8;
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
 * Creates a new OFString from a format string.
 * See printf for the format syntax.
 *
 * \param fmt A string used as format to initialize the OFString
 * \return A new autoreleased OFString
 */
+ stringWithFormat: (OFString*)fmt, ...;

/**
 * Creates a new OFString from another string.
 *
 * \param str A string to initialize the OFString with
 * \return A new autoreleased OFString
 */
+ stringWithString: (OFString*)str;

/**
 * Initializes an already allocated OFString.
 *
 * \return An initialized OFString
 */
- init;

/**
 * Initializes an already allocated OFString with a C string.
 *
 * \param str A C string to initialize the OFString with
 * \return An initialized OFString
 */
- initWithCString: (const char*)str;

/**
 * Initializes an already allocated OFString with a format string.
 * See printf for the format syntax.
 *
 * \param fmt A string used as format to initialize the OFString
 * \return An initialized OFString
 */
- initWithFormat: (OFString*)fmt, ...;

/**
 * Initializes an already allocated OFString with a format string.
 * See printf for the format syntax.
 *
 * \param fmt A string used as format to initialize the OFString
 * \param args The arguments used in the format string
 * \return An initialized OFString
 */
- initWithFormat: (OFString*)fmt
    andArguments: (va_list)args;

/**
 * Initializes an already allocated OFString with another string.
 *
 * \param str A string to initialize the OFString with
 * \return An initialized OFString
 */
- initWithString: (OFString*)str;

/**
 * \return The OFString as a C string
 */
- (const char*)cString;

/**
 * \return The length of the OFString
 */
- (size_t)length;

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
- setToCString: (const char*)str;

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
 * Replaces all occurrences of a string with another string.
 *
 * \param str The string to replace
 * \param repl The string with which it should be replaced
 */
- replaceOccurrencesOfString: (OFString*)str
		  withString: (OFString*)repl;

/**
 * Removes all whitespaces at the beginning of a string.
 */
- removeLeadingWhitespaces;

/**
 * Removes all whitespaces at the end of a string.
 */
- removeTrailingWhitespaces;

/**
 * Removes all whitespaces at the beginning and the end of a string.
 */
- removeLeadingAndTrailingWhitespaces;

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
#import "OFURLEncoding.h"
