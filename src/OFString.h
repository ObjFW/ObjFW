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

enum of_string_encoding {
	OF_STRING_ENCODING_UTF_8,
	OF_STRING_ENCODING_ISO_8859_1,
	OF_STRING_ENCODING_ISO_8859_15,
	OF_STRING_ENCODING_WINDOWS_1252
};

extern int of_string_check_utf8(const char*, size_t);
extern size_t of_string_unicode_to_utf8(uint32_t, char*);

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
 * Creates a new OFString from a UTF-8 encoded C string.
 *
 * \param str A UTF-8 encoded C string to initialize the OFString with
 * \return A new autoreleased OFString
 */
+ stringWithCString: (const char*)str;

/**
 * Creates a new OFString from a C string with the specified encoding.
 *
 * \param str A C string to initialize the OFString with
 * \param encoding The encoding of the C string
 * \return A new autoreleased OFString
 */
+ stringWithCString: (const char*)str
	   encoding: (enum of_string_encoding)encoding;

/**
 * Creates a new OFString from a C string with the specified encoding and
 * length.
 *
 * \param str A C string to initialize the OFString with
 * \param encoding The encoding of the C string
 * \param len The length of the string
 * \return A new autoreleased OFString
 */
+ stringWithCString: (const char*)str
	   encoding: (enum of_string_encoding)encoding
	     length: (size_t)len;

/**
 * Creates a new OFString from a UTF-8 encoded C string with the specified
 * length.
 *
 * \param str A UTF-8 encoded C string to initialize the OFString with
 * \param len The length of the string
 * \return A new autoreleased OFString
 */
+ stringWithCString: (const char*)str
	     length: (size_t)len;

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
 * Initializes an already allocated OFString from a UTF-8 encoded C string.
 *
 * \param str A UTF-8 encoded C string to initialize the OFString with
 * \return An initialized OFString
 */
- initWithCString: (const char*)str;

/**
 * Initializes an already allocated OFString from a C string with the specified
 * encoding.
 *
 * \param str A C string to initialize the OFString with
 * \param encoding The encoding of the C string
 * \return An initialized OFString
 */
- initWithCString: (const char*)str
	 encoding: (enum of_string_encoding)encoding;

/**
 * Initializes an already allocated OFString from a C string with the specified
 * encoding and length.
 *
 * \param str A C string to initialize the OFString with
 * \param encoding The encoding of the C string
 * \param len The length of the string
 * \return An initialized OFString
 */
- initWithCString: (const char*)str
	 encoding: (enum of_string_encoding)encoding
	   length: (size_t)len;

/**
 * Initializes an already allocated OFString from a UTF-8 encoded C string with
 * the specified length.
 *
 * \param str A UTF-8 encoded C string to initialize the OFString with
 * \param len The length of the string
 * \return An initialized OFString
 */
- initWithCString: (const char*)str
	   length: (size_t)len;

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
       arguments: (va_list)args;

/**
 * Initializes an already allocated OFString with another string.
 *
 * \param str A string to initialize the OFString with
 * \return An initialized OFString
 */
- initWithString: (OFString*)str;

/**
 * \return The OFString as a UTF-8 encoded C string
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
 * \param str The string to search
 * \return The index of the first occurrence of the string or SIZE_MAX if it
 *	   wasn't found
 */
- (size_t)indexOfFirstOccurrenceOfString: (OFString*)str;

/**
 * \param str The string to search
 * \return The index of the last occurrence of the string or SIZE_MAX if it
 *	   wasn't found
 */
- (size_t)indexOfLastOccurrenceOfString: (OFString*)str;

/**
 * \param start The index where the substring starts
 * \param end The index where the substring ends.
 *	      This points BEHIND the last character!
 * \return The substring as a new autoreleased OFString
 */
- (OFString*)substringFromIndex: (size_t)start
			toIndex: (size_t)end;

/**
 * Creates a new string by appending another string.
 *
 * \param str The string to append
 * \return A new autoreleased OFString with the specified string appended
 */
- (OFString*)stringByAppendingString: (OFString*)str;

/**
 * Checks whether the string has the specified prefix.
 *
 * \param prefix The prefix to check for
 * \return A boolean whether the string has the specified prefix
 */
- (BOOL)hasPrefix: (OFString*)prefix;

/**
 * Checks whether the string has the specified suffix.
 *
 * \param suffix The suffix to check for
 * \return A boolean whether the string has the specified suffix
 */
- (BOOL)hasSuffix: (OFString*)suffix;

/**
 * Splits an OFString into an OFArray of OFStrings.
 *
 * \param delimiter The delimiter for splitting
 * \return An autoreleased OFArray with the splitted string
 */
- (OFArray*)splitWithDelimiter: (OFString*)delimiter;

- setToCString: (const char*)str;
- appendCString: (const char*)str;
- appendCString: (const char*)str
     withLength: (size_t)len;
- appendCStringWithoutUTF8Checking: (const char*)str;
- appendCStringWithoutUTF8Checking: (const char*)str
			    length: (size_t)len;
- appendString: (OFString*)str;
- appendWithFormat: (OFString*)fmt, ...;
- appendWithFormat: (OFString*)fmt
	 arguments: (va_list)args;
- reverse;
- upper;
- lower;
- removeCharactersFromIndex: (size_t)start
		    toIndex: (size_t)end;
- replaceOccurrencesOfString: (OFString*)str
		  withString: (OFString*)repl;
- removeLeadingWhitespaces;
- removeTrailingWhitespaces;
- removeLeadingAndTrailingWhitespaces;
@end

#import "OFConstString.h"
#import "OFMutableString.h"
#import "OFHashes.h"
#import "OFURLEncoding.h"
#import "OFXMLElement.h"
#import "OFXMLParser.h"
