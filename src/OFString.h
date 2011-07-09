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
#include <inttypes.h>

#import "OFObject.h"
#import "OFSerialization.h"

@class OFConstantString;

typedef uint32_t of_unichar_t;

/**
 * \brief The encoding of a string.
 */
typedef enum of_string_encoding_t {
	OF_STRING_ENCODING_UTF_8,
	OF_STRING_ENCODING_ISO_8859_1,
	OF_STRING_ENCODING_ISO_8859_15,
	OF_STRING_ENCODING_WINDOWS_1252,
	OF_STRING_ENCODING_AUTODETECT = 0xFF
} of_string_encoding_t;

#ifdef __cplusplus
extern "C" {
#endif
extern int of_string_check_utf8(const char*, size_t, size_t*);
extern size_t of_string_unicode_to_utf8(of_unichar_t, char*);
extern size_t of_string_utf8_to_unicode(const char*, size_t, of_unichar_t*);
extern size_t of_string_position_to_index(const char*, size_t);
extern size_t of_string_index_to_position(const char*, size_t, size_t);
extern size_t of_unicode_string_length(const of_unichar_t*);
extern size_t of_utf16_string_length(const uint16_t*);
#ifdef __cplusplus
}
#endif

@class OFArray;
@class OFURL;

/**
 * \brief A class for handling strings.
 *
 * <b>Warning:</b> If you add methods to OFString using a category, you are not
 * allowed to access the ivars directly, as these might be still uninitialized
 * for a constant string and get initialized on the first message! Therefore,
 * you should use the corresponding methods to get the ivars, which ensures the
 * constant string is initialized.
 */
@interface OFString: OFObject <OFCopying, OFMutableCopying, OFComparing,
    OFSerialization>
{
	/*
	 * The ivars have to be like this because OFConstantString bases on
	 * OFString.
	 *
	 * The compiler generates an instance with a const char* and a size_t
	 * for each constant string. We change the const char* to point to our
	 * struct on the first call to a constant string so we can have more
	 * than those two ivars.
	 */
	struct of_string_ivars {
		char   *cString;
		size_t cStringLength;
		BOOL   isUTF8;
		size_t length;
	} *restrict s;
	/*
	 * Unused in OFString, however, OFConstantString sets this to SIZE_MAX
	 * once it allocated and initialized the struct.
	 */
	size_t initialized;
}

/**
 * \return A new autoreleased OFString
 */
+ string;

/**
 * Creates a new OFString from a UTF-8 encoded C string.
 *
 * \param cString A UTF-8 encoded C string to initialize the OFString with
 * \return A new autoreleased OFString
 */
+ stringWithCString: (const char*)cString;

/**
 * Creates a new OFString from a C string with the specified encoding.
 *
 * \param string A C string to initialize the OFString with
 * \param encoding The encoding of the C string
 * \return A new autoreleased OFString
 */
+ stringWithCString: (const char*)cString
	   encoding: (of_string_encoding_t)encoding;

/**
 * Creates a new OFString from a C string with the specified encoding and
 * length.
 *
 * \param cString A C string to initialize the OFString with
 * \param encoding The encoding of the C string
 * \param cStringLength The length of the C string
 * \return A new autoreleased OFString
 */
+ stringWithCString: (const char*)cString
	   encoding: (of_string_encoding_t)encoding
	     length: (size_t)cStringLength;

/**
 * Creates a new OFString from a UTF-8 encoded C string with the specified
 * length.
 *
 * \param cString A UTF-8 encoded C string to initialize the OFString with
 * \param cStringLength The length of the UTF-8 encoded C string
 * \return A new autoreleased OFString
 */
+ stringWithCString: (const char*)cString
	     length: (size_t)cStringLength;

/**
 * Creates a new OFString from another string.
 *
 * \param string A string to initialize the OFString with
 * \return A new autoreleased OFString
 */
+ stringWithString: (OFString*)string;

/**
 * Creates a new OFString from a unicode string.
 *
 * \param string The unicode string
 * \return A new autoreleased OFString
 */
+ stringWithUnicodeString: (of_unichar_t*)string;

/**
 * Creates a new OFString from a unicode string, assuming the specified byte
 * order if no BOM is found.
 *
 * \param string The unicode string
 * \param byteOrder The byte order to assume if there is no BOM
 * \return A new autoreleased OFString
 */
+ stringWithUnicodeString: (of_unichar_t*)string
		byteOrder: (of_endianess_t)byteOrder;

/**
 * Creates a new OFString from a unicode string with the specified length.
 *
 * \param string The unicode string
 * \param length The length of the unicode string
 * \return A new autoreleased OFString
 */
+ stringWithUnicodeString: (of_unichar_t*)string
		   length: (size_t)length;

/**
 * Creates a new OFString from a unicode string with the specified length,
 * assuming the specified byte order if no BOM is found.
 *
 * \param string The unicode string
 * \param byteOrder The byte order to assume if there is no BOM
 * \param length The length of the unicode string
 * \return A new autoreleased OFString
 */
+ stringWithUnicodeString: (of_unichar_t*)string
		byteOrder: (of_endianess_t)byteOrder
		   length: (size_t)length;

/**
 * Creates a new OFString from a UTF-16 encoded string.
 *
 * \param string The UTF-16 string
 * \return A new autoreleased OFString
 */
+ stringWithUTF16String: (uint16_t*)string;

/**
 * Creates a new OFString from a UTF-16 encoded string, assuming the specified
 * byte order if no BOM is found.
 *
 * \param string The UTF-16 string
 * \param byteOrder The byte order to assume if there is no BOM
 * \return A new autoreleased OFString
 */
+ stringWithUTF16String: (uint16_t*)string
	      byteOrder: (of_endianess_t)byteOrder;

/**
 * Creates a new OFString from a UTF-16 encoded string with the specified
 * length.
 *
 * \param string The UTF-16 string
 * \param length The length of the unicode string
 * \return A new autoreleased OFString
 */
+ stringWithUTF16String: (uint16_t*)string
		 length: (size_t)length;

/**
 * Creates a new OFString from a UTF-16 encoded string with the specified
 * length, assuming the specified byte order if no BOM is found.
 *
 * \param string The UTF-16 string
 * \param byteOrder The byte order to assume if there is no BOM
 * \param length The length of the unicode string
 * \return A new autoreleased OFString
 */
+ stringWithUTF16String: (uint16_t*)string
	      byteOrder: (of_endianess_t)byteOrder
		 length: (size_t)length;

/**
 * Creates a new OFString from a format string.
 *
 * See printf for the format syntax. As an addition, %@ is available as format
 * specifier for objects.
 *
 * \param format A string used as format to initialize the OFString
 * \return A new autoreleased OFString
 */
+ stringWithFormat: (OFConstantString*)format, ...;

/**
 * Creates a new OFString containing the constructed specified path.
 *
 * \param firstComponent The first component of the path
 * \return A new autoreleased OFString
 */
+ stringWithPath: (OFString*)firstComponent, ...;

/**
 * Creates a new OFString with the contents of the specified UTF-8 encoded file.
 *
 * \param path The path to the file
 * \return A new autoreleased OFString
 */
+ stringWithContentsOfFile: (OFString*)path;

/**
 * Creates a new OFString with the contents of the specified file in the
 * specified encoding.
 *
 * \param path The path to the file
 * \param encoding The encoding of the file
 * \return A new autoreleased OFString
 */
+ stringWithContentsOfFile: (OFString*)path
		  encoding: (of_string_encoding_t)encoding;

/**
 * Creates a new OFString with the contents of the specified URL.
 *
 * If the URL's scheme is file, it tries UTF-8 encoding.
 *
 * If the URL's scheme is http(s), it tries to detect the encoding from the HTTP
 * headers. If it could not detect the encoding using the HTTP headers, it tries
 * UTF-8.
 *
 * \param URL The URL to the contents for the string
 * \return A new autoreleased OFString
 */
+ stringWithContentsOfURL: (OFURL*)URL;

/**
 * Creates a new OFString with the contents of the specified URL in the
 * specified encoding.
 *
 * \param URL The URL to the contents for the string
 * \param encoding The encoding to assume
 * \return A new autoreleased OFString
 */
+ stringWithContentsOfURL: (OFURL*)URL
		 encoding: (of_string_encoding_t)encoding;

/**
 * Initializes an already allocated OFString from a UTF-8 encoded C string.
 *
 * \param cString A UTF-8 encoded C string to initialize the OFString with
 * \return An initialized OFString
 */
- initWithCString: (const char*)cString;

/**
 * Initializes an already allocated OFString from a C string with the specified
 * encoding.
 *
 * \param cString A C string to initialize the OFString with
 * \param encoding The encoding of the C string
 * \return An initialized OFString
 */
- initWithCString: (const char*)cString
	 encoding: (of_string_encoding_t)encoding;

/**
 * Initializes an already allocated OFString from a C string with the specified
 * encoding and length.
 *
 * \param cString A C string to initialize the OFString with
 * \param encoding The encoding of the C string
 * \param cStringLength The length of the C string
 * \return An initialized OFString
 */
- initWithCString: (const char*)cString
	 encoding: (of_string_encoding_t)encoding
	   length: (size_t)cStringLength;

/**
 * Initializes an already allocated OFString from a UTF-8 encoded C string with
 * the specified length.
 *
 * \param cString A UTF-8 encoded C string to initialize the OFString with
 * \param cStringLength The length of the UTF-8 encoded C string
 * \return An initialized OFString
 */
- initWithCString: (const char*)cString
	   length: (size_t)cStringLength;

/**
 * Initializes an already allocated OFString with another string.
 *
 * \param string A string to initialize the OFString with
 * \return An initialized OFString
 */
- initWithString: (OFString*)string;

/**
 * Initializes an already allocated OFString with a unicode string.
 *
 * \param string The unicode string
 * \return An initialized OFString
 */
- initWithUnicodeString: (of_unichar_t*)string;

/**
 * Initializes an already allocated OFString with a unicode string, assuming the
 * specified byte order if no BOM is found.
 *
 * \param string The unicode string
 * \param byteOrder The byte order to assume if there is no BOM
 * \return An initialized OFString
 */
- initWithUnicodeString: (of_unichar_t*)string
	      byteOrder: (of_endianess_t)byteOrder;

/**
 * Initializes an already allocated OFString with a unicode string with the
 * specified length.
 *
 * \param string The unicode string
 * \param length The length of the unicode string
 * \return An initialized OFString
 */
- initWithUnicodeString: (of_unichar_t*)string
		 length: (size_t)length;

/**
 * Initializes an already allocated OFString with a unicode string with the
 * specified length, assuming the specified byte order if no BOM is found.
 *
 * \param string The unicode string
 * \param byteOrder The byte order to assume if there is no BOM
 * \param length The length of the unicode string
 * \return An initialized OFString
 */
- initWithUnicodeString: (of_unichar_t*)string
	      byteOrder: (of_endianess_t)byteOrder
		 length: (size_t)length;

/**
 * Initializes an already allocated OFString with a UTF-16 string.
 *
 * \param string The UTF-16 string
 * \return An initialized OFString
 */
- initWithUTF16String: (uint16_t*)string;

/**
 * Initializes an already allocated OFString with a UTF-16 string, assuming the
 * specified byte order if no BOM is found.
 *
 * \param string The UTF-16 string
 * \param byteOrder The byte order to assume if there is no BOM
 * \return An initialized OFString
 */
- initWithUTF16String: (uint16_t*)string
	    byteOrder: (of_endianess_t)byteOrder;

/**
 * Initializes an already allocated OFString with a UTF-16 string with the
 * specified length.
 *
 * \param string The UTF-16 string
 * \param length The length of the UTF-16 string
 * \return An initialized OFString
 */
- initWithUTF16String: (uint16_t*)string
	       length: (size_t)length;

/**
 * Initializes an already allocated OFString with a UTF-16 string with the
 * specified length, assuming the specified byte order if no BOM is found.
 *
 * \param string The UTF-16 string
 * \param byteOrder The byte order to assume if there is no BOM
 * \param length The length of the UTF-16 string
 * \return An initialized OFString
 */
- initWithUTF16String: (uint16_t*)string
	    byteOrder: (of_endianess_t)byteOrder
	       length: (size_t)length;

/**
 * Initializes an already allocated OFString with a format string.
 *
 * See printf for the format syntax. As an addition, %@ is available as format
 * specifier for objects.
 *
 * \param format A string used as format to initialize the OFString
 * \return An initialized OFString
 */
- initWithFormat: (OFConstantString*)format, ...;

/**
 * Initializes an already allocated OFString with a format string.
 *
 * See printf for the format syntax. As an addition, %@ is available as format
 * specifier for objects.
 *
 * \param format A string used as format to initialize the OFString
 * \param arguments The arguments used in the format string
 * \return An initialized OFString
 */
- initWithFormat: (OFConstantString*)format
       arguments: (va_list)arguments;

/**
 * Initializes an already allocated OFString with the constructed specified
 * path.
 *
 * \param firstComponent The first component of the path
 * \return A new autoreleased OFString
 */
- initWithPath: (OFString*)firstComponent, ...;

/**
 * Initializes an already allocated OFString with the constructed specified
 * path.
 *
 * \param firstComponent The first component of the path
 * \param arguments A va_list with the other components of the path
 * \return A new autoreleased OFString
 */
- initWithPath: (OFString*)firstComponent
     arguments: (va_list)arguments;

/**
 * Initializes an already allocated OFString with the contents of the specified
 * file in the specified encoding.
 *
 * \param path The path to the file
 * \return An initialized OFString
 */
- initWithContentsOfFile: (OFString*)path;

/**
 * Initializes an already allocated OFString with the contents of the specified
 * file in the specified encoding.
 *
 * \param path The path to the file
 * \param encoding The encoding of the file
 * \return An initialized OFString
 */
- initWithContentsOfFile: (OFString*)path
		encoding: (of_string_encoding_t)encoding;

/**
 * Initializes an already allocated OFString with the contents of the specified
 * URL.
 *
 * If the URL's scheme is file, it tries UTF-8 encoding.
 *
 * If the URL's scheme is http(s), it tries to detect the encoding from the HTTP
 * headers. If it could not detect the encoding using the HTTP headers, it tries
 * UTF-8.
 *
 * \param URL The URL to the contents for the string
 * \return An initialized OFString
 */
- initWithContentsOfURL: (OFURL*)URL;

/**
 * Initializes an already allocated OFString with the contents of the specified
 * URL in the specified encoding.
 *
 * \param URL The URL to the contents for the string
 * \param encoding The encoding to assume
 * \return An initialized OFString
 */
- initWithContentsOfURL: (OFURL*)URL
	       encoding: (of_string_encoding_t)encoding;

/**
 * \return The OFString as a UTF-8 encoded C string
 */
- (const char*)cString;

/**
 * \return The length of the string in Unicode characters
 */
- (size_t)length;

/**
 * \return The length of the string which cString would return
 */
- (size_t)cStringLength;

/**
 * Compares the OFString to another OFString without caring about the case.
 *
 * \param otherString A string to compare with
 * \return An of_comparison_result_t
 */
- (of_comparison_result_t)caseInsensitiveCompare: (OFString*)otherString;

/**
 * \param index The index of the Unicode character to return
 * \return The Unicode character at the specified index
 */
- (of_unichar_t)characterAtIndex: (size_t)index;

/**
 * \param string The string to search
 * \return The index of the first occurrence of the string or OF_INVALID_INDEX
 *	   if it was not found
 */
- (size_t)indexOfFirstOccurrenceOfString: (OFString*)string;

/**
 * \param string The string to search
 * \return The index of the last occurrence of the string or OF_INVALID_INDEX if
 *	   it was not found
 */
- (size_t)indexOfLastOccurrenceOfString: (OFString*)string;

/**
 * \param string The string to search
 * \return Whether the string contains the specified string
 */
- (BOOL)containsString: (OFString*)string;

/**
 * \param start The index where the substring starts
 * \param end The index where the substring ends.
 *	      This points BEHIND the last character!
 * \return The substring as a new autoreleased OFString
 */
- (OFString*)substringFromIndex: (size_t)start
			toIndex: (size_t)end;

/**
 * \param range The range of the substring
 * \return The substring as a new autoreleased OFString
 */
- (OFString*)substringWithRange: (of_range_t)range;

/**
 * Creates a new string by appending another string.
 *
 * \param string The string to append
 * \return A new autoreleased OFString with the specified string appended
 */
- (OFString*)stringByAppendingString: (OFString*)string;

/**
 * Creates a new string by prepending another string.
 *
 * \param string The string to prepend
 * \return A new autoreleased OFString with the specified string prepended
 */
- (OFString*)stringByPrependingString: (OFString*)string;

/**
 * \return The string in uppercase
 */
- (OFString*)uppercaseString;

/**
 * \return The string in lowercase
 */
- (OFString*)lowercaseString;

/**
 * Creates a new string by deleting leading whitespaces.
 *
 * \return A new autoreleased OFString with leading whitespaces deleted
 */
- (OFString*)stringByDeletingLeadingWhitespaces;

/**
 * Creates a new string by deleting trailing whitespaces.
 *
 * \return A new autoreleased OFString with trailing whitespaces deleted
 */
- (OFString*)stringByDeletingTrailingWhitespaces;

/**
 * Creates a new string by deleting leading and trailing whitespaces.
 *
 * \return A new autoreleased OFString with leading and trailing whitespaces
 *	   deleted
 */
- (OFString*)stringByDeletingEnclosingWhitespaces;

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
- (OFArray*)componentsSeparatedByString: (OFString*)delimiter;

/**
 * \return The components of the path
 */
- (OFArray*)pathComponents;

/**
 * \return The last component of the path
 */
- (OFString*)lastPathComponent;

/**
 * \return The directory name of the path
 */
- (OFString*)stringByDeletingLastPathComponent;

/**
 * Returns the decimal value of the string as an intmax_t or throws an
 * OFInvalidEncodingException if the string contains any non-number characters.
 * Leading and trailing whitespaces are ignored.
 *
 * If the number is too big to fit into an intmax_t, an OFOutOfRangeException
 * is thrown.
 *
 * \return An intmax_t with the value of the string
 */
- (intmax_t)decimalValue;

/**
 * Returns the hexadecimal value of the string as an uintmax_t or throws an
 * OFInvalidEncodingException if the string contains any non-number characters.
 * Leading and trailing whitespaces are ignored.
 *
 * If the number is too big to fit into an uintmax_t, an OFOutOfRangeException
 * is thrown.
 *
 * \return A uintmax_t with the value of the string
 */
- (uintmax_t)hexadecimalValue;

/**
 * Returns the float value of the string as a float or throws an
 * OFInvalidEncodingException if the string contains any non-number characters.
 *
 * \return A float with the value of the string
 */
- (float)floatValue;

/**
 * Returns the double value of the string as a float or throws an
 * OFInvalidEncodingException if the string contains any non-number characters.
 *
 * \return A double with the value of the string
 */
- (double)doubleValue;

/**
 * Returns the string as an array of of_unichar_t.
 *
 * The result is valid until the autorelease pool is released. If you want to
 * use the result outside the scope of the current autorelease pool, you have to
 * copy it.
 *
 * \return The string as an array of Unicode characters
 */
- (of_unichar_t*)unicodeString;

/**
 * Writes the string into the specified file using UTF-8 encoding.
 *
 * \param path The path of the file to write to
 */
- (void)writeToFile: (OFString*)path;
@end

#import "OFConstantString.h"
#import "OFMutableString.h"
#import "OFString+Hashing.h"
#import "OFString+Serialization.h"
#import "OFString+URLEncoding.h"
#import "OFString+XMLEscaping.h"
#import "OFString+XMLUnescaping.h"
