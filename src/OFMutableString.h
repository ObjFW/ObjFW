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
 * Sets the OFString to the specified UTF-8 encoded C string.
 *
 * \param string A UTF-8 encoded C string to set the OFString to.
 */
- (void)setToCString: (const char*)string;

/**
 * Appends a UTF-8 encoded C string to the OFString.
 *
 * \param string A UTF-8 encoded C string to append
 */
- (void)appendCString: (const char*)string;

/**
 * Appends a UTF-8 encoded C string with the specified length to the OFString.
 *
 * \param string A UTF-8 encoded C string to append
 * \param length The length of the UTF-8 encoded C string
 */
- (void)appendCString: (const char*)string
	   withLength: (size_t)length;

/**
 * Appends a UTF-8 encoded C string to the OFString without checking whether it
 * is valid UTF-8.
 *
 * Only use this if you are 100% sure the string you append is either ASCII or
 * UTF-8!
 *
 * \param string A UTF-8 encoded C string to append
 */
- (void)appendCStringWithoutUTF8Checking: (const char*)string;

/**
 * Appends a UTF-8 encoded C string with the specified length to the OFString
 * without checking whether it is valid UTF-8.
 *
 * Only use this if you are 100% sure the string you append is either ASCII or
 * UTF-8!
 *
 * \param string A UTF-8 encoded C string to append
 * \param length The length of the UTF-8 encoded C string
 */
- (void)appendCStringWithoutUTF8Checking: (const char*)string
				  length: (size_t)length;

/**
 * Appends another OFString to the OFString.
 *
 * \param string An OFString to append
 */
- (void)appendString: (OFString*)string;

/**
 * Appends a formatted UTF-8 encoded C string to the OFString.
 * See printf for the format syntax.
 *
 * \param format A format string which generates the string to append
 */
- (void)appendFormat: (OFString*)format, ...;

/**
 * Appends a formatted UTF-8 encoded C string to the OFString.
 * See printf for the format syntax.
 *
 * \param format A format string which generates the string to append
 * \param arguments The arguments used in the format string
 */
- (void)appendFormat: (OFString*)format
       withArguments: (va_list)arguments;

/**
 * Prepends another OFString to the OFString.
 *
 * \param string An OFString to prepend
 */
- (void)prependString: (OFString*)string;

/**
 * Reverse the OFString.
 */
- (void)reverse;

/**
 * Upper the OFString.
 */
- (void)upper;

/**
 * Lower the OFString.
 */
- (void)lower;

/**
 * Inserts a string at the specified index.
 *
 * \param string The string to insert
 * \param index The index
 */
- (void)insertString: (OFString*)string
	     atIndex: (size_t)index;

/**
 * Deletes the characters at the specified range.
 *
 * \param start The index where the deletion should be started
 * \param end The index until which the characters should be deleted.
 *	      This points BEHIND the last character!
 */
- (void)deleteCharactersFromIndex: (size_t)start
			  toIndex: (size_t)end;

/**
 * Deletes the characters at the specified range.
 *
 * \param range The range of the characters which should be removed
 */
- (void)deleteCharactersInRange: (of_range_t)range;

/**
 * Replaces the characters at the specified range.
 *
 * \param start The index where the replacement should be started
 * \param end The index until which the characters should be replaced.
 *	      This points BEHIND the last character!
 * \param replacement The string to the replace the characters with
 */
- (void)replaceCharactersFromIndex: (size_t)start
			   toIndex: (size_t)end
			withString: (OFString*)replacement;

/**
 * Deletes the characters at the specified range.
 *
 * \param range The range of the characters which should be replaced
 * \param replacement The string to the replace the characters with
 */
- (void)replaceCharactersInRange: (of_range_t)range
		      withString: (OFString*)replacement;

/**
 * Deletes all occurrences of a string with another string.
 *
 * \param string The string to replace
 * \param replacement The string with which it should be replaced
 */
- (void)replaceOccurrencesOfString: (OFString*)string
			withString: (OFString*)replacement;

/**
 * Deletes all whitespaces at the beginning of a string.
 */
- (void)deleteLeadingWhitespaces;

/**
 * Deletes all whitespaces at the end of a string.
 */
- (void)deleteTrailingWhitespaces;

/**
 * Deletes all whitespaces at the beginning and the end of a string.
 */
- (void)deleteLeadingAndTrailingWhitespaces;
@end
