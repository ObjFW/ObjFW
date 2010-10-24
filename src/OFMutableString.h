/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include <stdio.h>
#include <stdarg.h>

#import "OFString.h"

/**
 * \brief A class for storing and modifying strings.
 */
@interface OFMutableString: OFString {}
/**
 * Sets the OFString to the specified UTF-8 encoded C string.
 *
 * \param str A UTF-8 encoded C string to set the OFString to.
 */
- (void)setToCString: (const char*)str;

/**
 * Appends a UTF-8 encoded C string to the OFString.
 *
 * \param str A UTF-8 encoded C string to append
 */
- (void)appendCString: (const char*)str;

/**
 * Appends a UTF-8 encoded C string with the specified length to the OFString.
 *
 * \param str A UTF-8 encoded C string to append
 * \param len The length of the UTF-8 encoded C string
 */
- (void)appendCString: (const char*)str
	   withLength: (size_t)len;

/**
 * Appends a UTF-8 encoded C string to the OFString without checking whether it
 * is valid UTF-8.
 *
 * Only use this if you are 100% sure the string you append is either ASCII or
 * UTF-8!
 *
 * \param str A UTF-8 encoded C string to append
 */
- (void)appendCStringWithoutUTF8Checking: (const char*)str;

/**
 * Appends a UTF-8 encoded C string with the specified length to the OFString
 * without checking whether it is valid UTF-8.
 *
 * Only use this if you are 100% sure the string you append is either ASCII or
 * UTF-8!
 *
 * \param str A UTF-8 encoded C string to append
 * \param len The length of the UTF-8 encoded C string
 */
- (void)appendCStringWithoutUTF8Checking: (const char*)str
				  length: (size_t)len;

/**
 * Appends another OFString to the OFString.
 *
 * \param str An OFString to append
 */
- (void)appendString: (OFString*)str;

/**
 * Appends a formatted UTF-8 encoded C string to the OFString.
 * See printf for the format syntax.
 *
 * \param fmt A format string which generates the string to append
 */
- (void)appendFormat: (OFString*)fmt, ...;

/**
 * Appends a formatted UTF-8 encoded C string to the OFString.
 * See printf for the format syntax.
 *
 * \param fmt A format string which generates the string to append
 * \param args The arguments used in the format string
 */
- (void)appendFormat: (OFString*)fmt
       withArguments: (va_list)args;

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
 * Removes the characters at the specified range.
 *
 * \param start The index where the deletion should be started
 * \param end The index until which the characters should be deleted.
 *	      This points BEHIND the last character!
 */
- (void)removeCharactersFromIndex: (size_t)start
			  toIndex: (size_t)end;

/**
 * Removes the characters at the specified range.
 *
 * \param range The range of the characters which should be removed
 */
- (void)removeCharactersInRange: (of_range_t)range;

/**
 * Removes the characters at the specified range.
 *
 * \param start The index where the replacement should be started
 * \param end The index until which the characters should be replaced.
 *	      This points BEHIND the last character!
 * \param repl The string to the replace the characters with
 */
- (void)replaceCharactersFromIndex: (size_t)start
			   toIndex: (size_t)end
			withString: (OFString*)repl;

/**
 * Removes the characters at the specified range.
 *
 * \param range The range of the characters which should be replaced
 * \param repl The string to the replace the characters with
 */
- (void)replaceCharactersInRange: (of_range_t)range
		      withString: (OFString*)repl;

/**
 * Replaces all occurrences of a string with another string.
 *
 * \param str The string to replace
 * \param repl The string with which it should be replaced
 */
- (void)replaceOccurrencesOfString: (OFString*)str
			withString: (OFString*)repl;

/**
 * Removes all whitespaces at the beginning of a string.
 */
- (void)removeLeadingWhitespaces;

/**
 * Removes all whitespaces at the end of a string.
 */
- (void)removeTrailingWhitespaces;

/**
 * Removes all whitespaces at the beginning and the end of a string.
 */
- (void)removeLeadingAndTrailingWhitespaces;
@end
