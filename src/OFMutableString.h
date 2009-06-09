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

#import "OFString.h"

/**
 * A class for storing and modifying strings.
 */
@interface OFMutableString: OFString
/**
 * Sets the OFString to the specified OFString.
 *
 * \param str An OFString to set the OFString to.
 */
- setToCString: (const char*)str;

/**
 * Appends a C string to the OFString.
 *
 * \param str A C string to append
 */
- appendCString: (const char*)str;

/**
 * Appends another OFString to the OFString.
 *
 * \param str An OFString to append
 */
- appendString: (OFString*)str;

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
@end
