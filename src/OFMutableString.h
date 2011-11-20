/*
 * Copyright (c) 2008, 2009, 2010, 2011
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE.QPL included in
 * the packaging of this file.
 *
 * Alternatively, it may be distributed under the terms of the GNU General
 * Public License, either version 2 or 3, which can be found in the file
 * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the packaging of this
 * file.
 */

#include <stdio.h>
#include <stdarg.h>

#import "OFString.h"

/**
 * \brief A class for storing and modifying strings.
 */
@interface OFMutableString: OFString
/**
 * \brief Sets the character at the specified index.
 *
 * \param character The character to set
 * \param index The index where to set the character
 */
- (void)setCharacter: (of_unichar_t)character
	     atIndex: (size_t)index;

/**
 * \brief Appends a UTF-8 encoded C string to the OFMutableString.
 *
 * \param UTF8String A UTF-8 encoded C string to append
 */
- (void)appendUTF8String: (const char*)UTF8String;

/**
 * \brief Appends a UTF-8 encoded C string with the specified length to the
 *	  OFMutableString.
 *
 * \param UTF8String A UTF-8 encoded C string to append
 * \param UTF8StringLength The length of the UTF-8 encoded C string
 */
- (void)appendUTF8String: (const char*)UTF8String
	      withLength: (size_t)UTF8StringLength;

/**
 * \brief Appends a C string with the specified encoding to the OFMutableString.
 *
 * \param cString A C string to append
 * \param encoding The encoding of the C string
 */
- (void)appendCString: (const char*)cString
	 withEncoding: (of_string_encoding_t)encoding;

/**
 * \brief Appends a C string with the specified encoding and length to the
 *	  OFMutableString.
 *
 * \param cString A C string to append
 * \param encoding The encoding of the C string
 * \param cStringLength The length of the UTF-8 encoded C string
 */
- (void)appendCString: (const char*)cString
	 withEncoding: (of_string_encoding_t)encoding
	       length: (size_t)cStringLength;

/**
 * \brief Appends another OFString to the OFMutableString.
 *
 * \param string An OFString to append
 */
- (void)appendString: (OFString*)string;

/**
 * \brief Appends a formatted string to the OFMutableString.
 *
 * See printf for the format syntax. As an addition, %@ is available as format
 * specifier for objects.
 *
 * \param format A format string which generates the string to append
 */
- (void)appendFormat: (OFConstantString*)format, ...;

/**
 * \brief Appends a formatted string to the OFMutableString.
 *
 * See printf for the format syntax. As an addition, %@ is available as format
 * specifier for objects.
 *
 * \param format A format string which generates the string to append
 * \param arguments The arguments used in the format string
 */
- (void)appendFormat: (OFConstantString*)format
       withArguments: (va_list)arguments;

/**
 * \brief Prepends another OFString to the OFMutableString.
 *
 * \param string An OFString to prepend
 */
- (void)prependString: (OFString*)string;

/**
 * \brief Reverses the OFMutableString.
 */
- (void)reverse;

/**
 * \brief Converts the OFMutableString to uppercase.
 */
- (void)upper;

/**
 * \brief Converts the OFMutableString to lowercase.
 */
- (void)lower;

/**
 * \brief Inserts a string at the specified index.
 *
 * \param string The string to insert
 * \param index The index
 */
- (void)insertString: (OFString*)string
	     atIndex: (size_t)index;

/**
 * \brief Deletes the characters at the specified range.
 *
 * \param range The range of the characters which should be removed
 */
- (void)deleteCharactersInRange: (of_range_t)range;

/**
 * \brief Replaces the characters at the specified range.
 *
 * \param range The range of the characters which should be replaced
 * \param replacement The string to the replace the characters with
 */
- (void)replaceCharactersInRange: (of_range_t)range
		      withString: (OFString*)replacement;

/**
 * \brief Replaces all occurrences of a string with another string.
 *
 * \param string The string to replace
 * \param replacement The string with which it should be replaced
 */
- (void)replaceOccurrencesOfString: (OFString*)string
			withString: (OFString*)replacement;

/**
 * \brief Deletes all whitespaces at the beginning of the string.
 */
- (void)deleteLeadingWhitespaces;

/**
 * \brief Deletes all whitespaces at the end of the string.
 */
- (void)deleteTrailingWhitespaces;

/**
 * \brief Deletes all whitespaces at the beginning and the end of the string.
 */
- (void)deleteEnclosingWhitespaces;

/**
 * \brief Converts the mutable string to an immutable string.
 */
- (void)makeImmutable;
@end
