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
#import "OFJSONEncoding.h"

#import "macros.h"

@class OFConstantString;

typedef uint32_t of_unichar_t;

/**
 * \brief The encoding of a string.
 */
typedef enum of_string_encoding_t {
	OF_STRING_ENCODING_UTF_8,
	OF_STRING_ENCODING_ASCII,
	OF_STRING_ENCODING_ISO_8859_1,
	OF_STRING_ENCODING_ISO_8859_15,
	OF_STRING_ENCODING_WINDOWS_1252,
	OF_STRING_ENCODING_AUTODETECT = 0xFF
} of_string_encoding_t;

/* FIXME */
#define OF_STRING_ENCODING_NATIVE OF_STRING_ENCODING_UTF_8

#ifdef OF_HAVE_BLOCKS
typedef void (^of_string_line_enumeration_block_t)(OFString *line, BOOL *stop);
#endif

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
    OFSerialization, OFJSON>
#ifdef OF_HAVE_PROPERTIES
@property (readonly) size_t length;
#endif

/**
 * \brief Creates a new OFString.
 *
 * \return A new, autoreleased OFString
 */
+ string;

/**
 * \brief Creates a new OFString from a UTF-8 encoded C string.
 *
 * \param UTF8String A UTF-8 encoded C string to initialize the OFString with
 * \return A new autoreleased OFString
 */
+ stringWithUTF8String: (const char*)UTF8String;

/**
 * \brief Creates a new OFString from a UTF-8 encoded C string with the
 *	  specified length.
 *
 * \param UTF8String A UTF-8 encoded C string to initialize the OFString with
 * \param UTF8StringLength The length of the UTF-8 encoded C string
 * \return A new autoreleased OFString
 */
+ stringWithUTF8String: (const char*)UTF8String
		length: (size_t)UTF8StringLength;

/**
 * \brief Creates a new OFString from a C string with the specified encoding.
 *
 * \param string A C string to initialize the OFString with
 * \param encoding The encoding of the C string
 * \return A new autoreleased OFString
 */
+ stringWithCString: (const char*)cString
	   encoding: (of_string_encoding_t)encoding;

/**
 * \brief Creates a new OFString from a C string with the specified encoding
 *	  and length.
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
 * \brief Creates a new OFString from another string.
 *
 * \param string A string to initialize the OFString with
 * \return A new autoreleased OFString
 */
+ stringWithString: (OFString*)string;

/**
 * \brief Creates a new OFString from a unicode string.
 *
 * \param string The unicode string
 * \return A new autoreleased OFString
 */
+ stringWithUnicodeString: (const of_unichar_t*)string;

/**
 * \brief Creates a new OFString from a unicode string, assuming the specified
 *	  byte order if no BOM is found.
 *
 * \param string The unicode string
 * \param byteOrder The byte order to assume if there is no BOM
 * \return A new autoreleased OFString
 */
+ stringWithUnicodeString: (const of_unichar_t*)string
		byteOrder: (of_endianess_t)byteOrder;

/**
 * \brief Creates a new OFString from a unicode string with the specified
 *	  length.
 *
 * \param string The unicode string
 * \param length The length of the unicode string
 * \return A new autoreleased OFString
 */
+ stringWithUnicodeString: (const of_unichar_t*)string
		   length: (size_t)length;

/**
 * \brief Creates a new OFString from a unicode string with the specified
 *	  length, assuming the specified byte order if no BOM is found.
 *
 * \param string The unicode string
 * \param byteOrder The byte order to assume if there is no BOM
 * \param length The length of the unicode string
 * \return A new autoreleased OFString
 */
+ stringWithUnicodeString: (const of_unichar_t*)string
		byteOrder: (of_endianess_t)byteOrder
		   length: (size_t)length;

/**
 * \brief Creates a new OFString from a UTF-16 encoded string.
 *
 * \param string The UTF-16 string
 * \return A new autoreleased OFString
 */
+ stringWithUTF16String: (const uint16_t*)string;

/**
 * \brief Creates a new OFString from a UTF-16 encoded string, assuming the
 *	  specified byte order if no BOM is found.
 *
 * \param string The UTF-16 string
 * \param byteOrder The byte order to assume if there is no BOM
 * \return A new autoreleased OFString
 */
+ stringWithUTF16String: (const uint16_t*)string
	      byteOrder: (of_endianess_t)byteOrder;

/**
 * \brief Creates a new OFString from a UTF-16 encoded string with the specified
 *	  length.
 *
 * \param string The UTF-16 string
 * \param length The length of the unicode string
 * \return A new autoreleased OFString
 */
+ stringWithUTF16String: (const uint16_t*)string
		 length: (size_t)length;

/**
 * \brief Creates a new OFString from a UTF-16 encoded string with the
 *	  specified length, assuming the specified byte order if no BOM is
 *	  found.
 *
 * \param string The UTF-16 string
 * \param byteOrder The byte order to assume if there is no BOM
 * \param length The length of the unicode string
 * \return A new autoreleased OFString
 */
+ stringWithUTF16String: (const uint16_t*)string
	      byteOrder: (of_endianess_t)byteOrder
		 length: (size_t)length;

/**
 * \brief Creates a new OFString from a format string.
 *
 * See printf for the format syntax. As an addition, %@ is available as format
 * specifier for objects.
 *
 * \param format A string used as format to initialize the OFString
 * \return A new autoreleased OFString
 */
+ stringWithFormat: (OFConstantString*)format, ...;

/**
 * \brief Creates a new OFString containing the constructed specified path.
 *
 * \param firstComponent The first component of the path
 * \return A new autoreleased OFString
 */
+ stringWithPath: (OFString*)firstComponent, ...;

/**
 * \brief Creates a new OFString with the contents of the specified UTF-8
 *	  encoded file.
 *
 * \param path The path to the file
 * \return A new autoreleased OFString
 */
+ stringWithContentsOfFile: (OFString*)path;

/**
 * \brief Creates a new OFString with the contents of the specified file in the
 *	  specified encoding.
 *
 * \param path The path to the file
 * \param encoding The encoding of the file
 * \return A new autoreleased OFString
 */
+ stringWithContentsOfFile: (OFString*)path
		  encoding: (of_string_encoding_t)encoding;

/**
 * \brief Creates a new OFString with the contents of the specified URL.
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
 * \brief Creates a new OFString with the contents of the specified URL in the
 *	  specified encoding.
 *
 * \param URL The URL to the contents for the string
 * \param encoding The encoding to assume
 * \return A new autoreleased OFString
 */
+ stringWithContentsOfURL: (OFURL*)URL
		 encoding: (of_string_encoding_t)encoding;

/**
 * \brief Initializes an already allocated OFString from a UTF-8 encoded C
 *	  string.
 *
 * \param UTF8String A UTF-8 encoded C string to initialize the OFString with
 * \return An initialized OFString
 */
- initWithUTF8String: (const char*)UTF8String;

/**
 * \brief Initializes an already allocated OFString from a UTF-8 encoded C
 *	  string with the specified length.
 *
 * \param UTF8String A UTF-8 encoded C string to initialize the OFString with
 * \param UTF8StringLength The length of the UTF-8 encoded C string
 * \return An initialized OFString
 */
- initWithUTF8String: (const char*)UTF8String
	      length: (size_t)UTF8StringLength;

/**
 * \brief Initializes an already allocated OFString from a C string with the
 *	  specified encoding.
 *
 * \param cString A C string to initialize the OFString with
 * \param encoding The encoding of the C string
 * \return An initialized OFString
 */
- initWithCString: (const char*)cString
	 encoding: (of_string_encoding_t)encoding;

/**
 * \brief Initializes an already allocated OFString from a C string with the
 *	  specified encoding and length.
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
 * \brief Initializes an already allocated OFString with another string.
 *
 * \param string A string to initialize the OFString with
 * \return An initialized OFString
 */
- initWithString: (OFString*)string;

/**
 * \brief Initializes an already allocated OFString with a unicode string.
 *
 * \param string The unicode string
 * \return An initialized OFString
 */
- initWithUnicodeString: (const of_unichar_t*)string;

/**
 * \brief Initializes an already allocated OFString with a unicode string,
 *	  assuming the specified byte order if no BOM is found.
 *
 * \param string The unicode string
 * \param byteOrder The byte order to assume if there is no BOM
 * \return An initialized OFString
 */
- initWithUnicodeString: (const of_unichar_t*)string
	      byteOrder: (of_endianess_t)byteOrder;

/**
 * \brief Initializes an already allocated OFString with a unicode string with
 *	  the specified length.
 *
 * \param string The unicode string
 * \param length The length of the unicode string
 * \return An initialized OFString
 */
- initWithUnicodeString: (const of_unichar_t*)string
		 length: (size_t)length;

/**
 * \brief Initializes an already allocated OFString with a unicode string with
 *	  the specified length, assuming the specified byte order if no BOM is
 *	  found.
 *
 * \param string The unicode string
 * \param byteOrder The byte order to assume if there is no BOM
 * \param length The length of the unicode string
 * \return An initialized OFString
 */
- initWithUnicodeString: (const of_unichar_t*)string
	      byteOrder: (of_endianess_t)byteOrder
		 length: (size_t)length;

/**
 * \brief Initializes an already allocated OFString with a UTF-16 string.
 *
 * \param string The UTF-16 string
 * \return An initialized OFString
 */
- initWithUTF16String: (const uint16_t*)string;

/**
 * \brief Initializes an already allocated OFString with a UTF-16 string,
 *	  assuming the specified byte order if no BOM is found.
 *
 * \param string The UTF-16 string
 * \param byteOrder The byte order to assume if there is no BOM
 * \return An initialized OFString
 */
- initWithUTF16String: (const uint16_t*)string
	    byteOrder: (of_endianess_t)byteOrder;

/**
 * \brief Initializes an already allocated OFString with a UTF-16 string with
 *	  the specified length.
 *
 * \param string The UTF-16 string
 * \param length The length of the UTF-16 string
 * \return An initialized OFString
 */
- initWithUTF16String: (const uint16_t*)string
	       length: (size_t)length;

/**
 * \brief Initializes an already allocated OFString with a UTF-16 string with
 *	  the specified length, assuming the specified byte order if no BOM is
 *	  found.
 *
 * \param string The UTF-16 string
 * \param byteOrder The byte order to assume if there is no BOM
 * \param length The length of the UTF-16 string
 * \return An initialized OFString
 */
- initWithUTF16String: (const uint16_t*)string
	    byteOrder: (of_endianess_t)byteOrder
	       length: (size_t)length;

/**
 * \brief Initializes an already allocated OFString with a format string.
 *
 * See printf for the format syntax. As an addition, %@ is available as format
 * specifier for objects.
 *
 * \param format A string used as format to initialize the OFString
 * \return An initialized OFString
 */
- initWithFormat: (OFConstantString*)format, ...;

/**
 * \brief Initializes an already allocated OFString with a format string.
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
 * \brief Initializes an already allocated OFString with the constructed
 *	  specified path.
 *
 * \param firstComponent The first component of the path
 * \return A new autoreleased OFString
 */
- initWithPath: (OFString*)firstComponent, ...;

/**
 * \brief Initializes an already allocated OFString with the constructed
 *	  specified path.
 *
 * \param firstComponent The first component of the path
 * \param arguments A va_list with the other components of the path
 * \return A new autoreleased OFString
 */
- initWithPath: (OFString*)firstComponent
     arguments: (va_list)arguments;

/**
 * \brief Initializes an already allocated OFString with the contents of the
 *	  specified file in the specified encoding.
 *
 * \param path The path to the file
 * \return An initialized OFString
 */
- initWithContentsOfFile: (OFString*)path;

/**
 * \brief Initializes an already allocated OFString with the contents of the
 *	  specified file in the specified encoding.
 *
 * \param path The path to the file
 * \param encoding The encoding of the file
 * \return An initialized OFString
 */
- initWithContentsOfFile: (OFString*)path
		encoding: (of_string_encoding_t)encoding;

/**
 * \brief Initializes an already allocated OFString with the contents of the
 *	  specified URL.
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
 * \brief Initializes an already allocated OFString with the contents of the
 *	  specified URL in the specified encoding.
 *
 * \param URL The URL to the contents for the string
 * \param encoding The encoding to assume
 * \return An initialized OFString
 */
- initWithContentsOfURL: (OFURL*)URL
	       encoding: (of_string_encoding_t)encoding;

/**
 * \brief Returns the OFString as a UTF-8 encoded C string.
 *
 * The result is valid until the autorelease pool is released. If you want to
 * use the result outside the scope of the current autorelease pool, you have to
 * copy it.
 *
 * \return The OFString as a UTF-8 encoded C string
 */
- (const char*)UTF8String;

/**
 * \brief Returns the OFString as a C string in the specified encoding.
 *
 * The result is valid until the autorelease pool is released. If you want to
 * use the result outside the scope of the current autorelease pool, you have to
 * copy it.
 *
 * \param encoding The encoding for the C string
 * \return The OFString as a C string in the specified encoding
 */
- (const char*)cStringWithEncoding: (of_string_encoding_t)encoding;;

/**
 * \brief Returns the length of the string in Unicode characters.
 *
 * \return The length of the string in Unicode characters
 */
- (size_t)length;

/**
 * \brief Returns the number of bytes the string needs in UTF-8 encoding.
 *
 * \return The number of bytes the string needs in UTF-8 encoding.
 */
- (size_t)UTF8StringLength;

/**
 * \brief Returns the number of bytes the string needs in the specified
 *	  encoding.
 *
 * \param encoding The encoding for the string
 * \return The number of bytes the string needs in the specified encoding.
 */
- (size_t)cStringLengthWithEncoding: (of_string_encoding_t)encoding;

/**
 * \brief Compares the OFString to another OFString without caring about the
 *	  case.
 *
 * \param otherString A string to compare with
 * \return An of_comparison_result_t
 */
- (of_comparison_result_t)caseInsensitiveCompare: (OFString*)otherString;

/**
 * \brief Returns the Unicode character at the specified index.
 *
 * \param index The index of the Unicode character to return
 * \return The Unicode character at the specified index
 */
- (of_unichar_t)characterAtIndex: (size_t)index;

/**
 * \brief Copies the Unicode characters in the specified range to the specified
 *	  buffer.
 *
 * \param buffer The buffer to store the Unicode characters
 * \param range The range of the Unicode characters to copy
 */
- (void)getCharacters: (of_unichar_t*)buffer
	      inRange: (of_range_t)range;

/**
 * \brief Returns the index of the first occurrence of the string.
 *
 * \param string The string to search
 * \return The index of the first occurrence of the string or OF_INVALID_INDEX
 *	   if it was not found
 */
- (size_t)indexOfFirstOccurrenceOfString: (OFString*)string;

/**
 * \brief Returns the index of the last occurrence of the string.
 *
 * \param string The string to search
 * \return The index of the last occurrence of the string or OF_INVALID_INDEX if
 *	   it was not found
 */
- (size_t)indexOfLastOccurrenceOfString: (OFString*)string;

/**
 * \brief Returns whether the string contains the specified string.
 *
 * \param string The string to search
 * \return Whether the string contains the specified string
 */
- (BOOL)containsString: (OFString*)string;

/**
 * \brief Creates a substring with the specified range.
 *
 * \param range The range of the substring
 * \return The substring as a new autoreleased OFString
 */
- (OFString*)substringWithRange: (of_range_t)range;

/**
 * \brief Creates a new string by appending another string.
 *
 * \param string The string to append
 * \return A new autoreleased OFString with the specified string appended
 */
- (OFString*)stringByAppendingString: (OFString*)string;

/**
 * \brief Creates a new string by prepending another string.
 *
 * \param string The string to prepend
 * \return A new autoreleased OFString with the specified string prepended
 */
- (OFString*)stringByPrependingString: (OFString*)string;

/**
 * \brief Creates a new string by replacing the occurrences of the specified
 *	  string with the specified replacement.
 *
 * \param string The string to replace
 * \param replacement The string with which it should be replaced
 * \return A new string with the occurrences of the specified string replaced
 */
- (OFString*)stringByReplacingOccurrencesOfString: (OFString*)string
				       withString: (OFString*)replacement;

/**
 * \brief Returns the string in uppercase.
 *
 * \return The string in uppercase
 */
- (OFString*)uppercaseString;

/**
 * \brief Returns the string in lowercase.
 *
 * \return The string in lowercase
 */
- (OFString*)lowercaseString;

/**
 * \brief Creates a new string by deleting leading whitespaces.
 *
 * \return A new autoreleased OFString with leading whitespaces deleted
 */
- (OFString*)stringByDeletingLeadingWhitespaces;

/**
 * \brief Creates a new string by deleting trailing whitespaces.
 *
 * \return A new autoreleased OFString with trailing whitespaces deleted
 */
- (OFString*)stringByDeletingTrailingWhitespaces;

/**
 * \brief Creates a new string by deleting leading and trailing whitespaces.
 *
 * \return A new autoreleased OFString with leading and trailing whitespaces
 *	   deleted
 */
- (OFString*)stringByDeletingEnclosingWhitespaces;

/**
 * \brief Checks whether the string has the specified prefix.
 *
 * \param prefix The prefix to check for
 * \return A boolean whether the string has the specified prefix
 */
- (BOOL)hasPrefix: (OFString*)prefix;

/**
 * \brief Checks whether the string has the specified suffix.
 *
 * \param suffix The suffix to check for
 * \return A boolean whether the string has the specified suffix
 */
- (BOOL)hasSuffix: (OFString*)suffix;

/**
 * \brief Splits an OFString into an OFArray of OFStrings.
 *
 * \param delimiter The delimiter for splitting
 * \return An autoreleased OFArray with the split string
 */
- (OFArray*)componentsSeparatedByString: (OFString*)delimiter;

/**
 * \brief Returns the components of the path.
 *
 * \return The components of the path
 */
- (OFArray*)pathComponents;

/**
 * \brief Returns the last component of the path.
 *
 * \return The last component of the path
 */
- (OFString*)lastPathComponent;

/**
 * \brief Returns the directory name of the path.
 *
 * \return The directory name of the path
 */
- (OFString*)stringByDeletingLastPathComponent;

/**
 * \brief Returns the decimal value of the string as an intmax_t.
 *
 * Leading and trailing whitespaces are ignored.
 *
 * If the string contains any non-number characters, an
 * OFInvalidEncodingException is thrown.
 *
 * If the number is too big to fit into an intmax_t, an OFOutOfRangeException
 * is thrown.
 *
 * \return An intmax_t with the value of the string
 */
- (intmax_t)decimalValue;

/**
 * \brief Returns the hexadecimal value of the string as an uintmax_t.
 *
 * Leading and trailing whitespaces are ignored.
 *
 * If the string contains any non-number characters, an
 * OFInvalidEncodingException is thrown.
 *
 * If the number is too big to fit into an uintmax_t, an OFOutOfRangeException
 * is thrown.
 *
 * \return A uintmax_t with the value of the string
 */
- (uintmax_t)hexadecimalValue;

/**
 * \brief Returns the float value of the string as a float.
 *
 * If the string contains any non-number characters, an
 * OFInvalidEncodingException is thrown.
 *
 * \return A float with the value of the string
 */
- (float)floatValue;

/**
 * \brief Returns the double value of the string as a double.
 *
 * If the string contains any non-number characters, an
 * OFInvalidEncodingException is thrown.
 *
 * \return A double with the value of the string
 */
- (double)doubleValue;

/**
 * \brief Returns the string as an array of Unicode characters.
 *
 * The result is valid until the autorelease pool is released. If you want to
 * use the result outside the scope of the current autorelease pool, you have to
 * copy it.
 *
 * \return The string as an array of Unicode characters
 */
- (const of_unichar_t*)unicodeString;

/**
 * \brief Returns the string in big endian UTF-16 encoding.
 *
 * The result is valid until the autorelease pool is released. If you want to
 * use the result outside the scope of the current autorelease pool, you have to
 * copy it.
 *
 * \return The string in big endian UTF-16 encoding
 */
- (const uint16_t*)UTF16String;

/**
 * \brief Writes the string into the specified file using UTF-8 encoding.
 *
 * \param path The path of the file to write to
 */
- (void)writeToFile: (OFString*)path;

#ifdef OF_HAVE_BLOCKS
/**
 * Enumerates all lines in the receiver using the specified block.
 *
 * \brief block The block to call for each line
 */
- (void)enumerateLinesUsingBlock: (of_string_line_enumeration_block_t)block;
#endif
@end

#import "OFConstantString.h"
#import "OFMutableString.h"
#import "OFString+Hashing.h"
#import "OFString+JSONValue.h"
#import "OFString+Serialization.h"
#import "OFString+URLEncoding.h"
#import "OFString+XMLEscaping.h"
#import "OFString+XMLUnescaping.h"
