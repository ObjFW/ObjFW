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
{
	BOOL   is_utf8;
}

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
@end
