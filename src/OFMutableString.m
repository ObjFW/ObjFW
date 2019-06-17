/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

#include "config.h"

#include <stdarg.h>
#include <stdlib.h>
#include <string.h>

#import "OFString.h"
#import "OFMutableUTF8String.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

#import "of_asprintf.h"
#import "unicode.h"

static struct {
	Class isa;
} placeholder;

@interface OFMutableStringPlaceholder: OFMutableString
@end

@implementation OFMutableStringPlaceholder
- (instancetype)init
{
	return (id)[[OFMutableUTF8String alloc] init];
}

- (instancetype)initWithUTF8String: (const char *)UTF8String
{
	return (id)[[OFMutableUTF8String alloc] initWithUTF8String: UTF8String];
}

- (instancetype)initWithUTF8String: (const char *)UTF8String
			    length: (size_t)UTF8StringLength
{
	return (id)[[OFMutableUTF8String alloc]
	    initWithUTF8String: UTF8String
			length: UTF8StringLength];
}

- (instancetype)initWithCString: (const char *)cString
		       encoding: (of_string_encoding_t)encoding
{
	return (id)[[OFMutableUTF8String alloc] initWithCString: cString
						       encoding: encoding];
}

- (instancetype)initWithCString: (const char *)cString
		       encoding: (of_string_encoding_t)encoding
			 length: (size_t)cStringLength
{
	return (id)[[OFMutableUTF8String alloc] initWithCString: cString
						       encoding: encoding
							 length: cStringLength];
}

- (instancetype)initWithString: (OFString *)string
{
	return (id)[[OFMutableUTF8String alloc] initWithString: string];
}

- (instancetype)initWithCharacters: (const of_unichar_t *)characters
			    length: (size_t)length
{
	return (id)[[OFMutableUTF8String alloc] initWithCharacters: characters
							    length: length];
}

- (instancetype)initWithUTF16String: (const of_char16_t *)string
{
	return (id)[[OFMutableUTF8String alloc] initWithUTF16String: string];
}

- (instancetype)initWithUTF16String: (const of_char16_t *)string
			     length: (size_t)length
{
	return (id)[[OFMutableUTF8String alloc] initWithUTF16String: string
							      length: length];
}

- (instancetype)initWithUTF16String: (const of_char16_t *)string
			  byteOrder: (of_byte_order_t)byteOrder
{
	return (id)[[OFMutableUTF8String alloc] initWithUTF16String: string
							  byteOrder: byteOrder];
}

- (instancetype)initWithUTF16String: (const of_char16_t *)string
			     length: (size_t)length
			  byteOrder: (of_byte_order_t)byteOrder
{
	return (id)[[OFMutableUTF8String alloc] initWithUTF16String: string
							     length: length
							  byteOrder: byteOrder];
}

- (instancetype)initWithUTF32String: (const of_char32_t *)string
{
	return (id)[[OFMutableUTF8String alloc] initWithUTF32String: string];
}

- (instancetype)initWithUTF32String: (const of_char32_t *)string
			     length: (size_t)length
{
	return (id)[[OFMutableUTF8String alloc] initWithUTF32String: string
							     length: length];
}

- (instancetype)initWithUTF32String: (const of_char32_t *)string
			  byteOrder: (of_byte_order_t)byteOrder
{
	return (id)[[OFMutableUTF8String alloc] initWithUTF32String: string
							  byteOrder: byteOrder];
}

- (instancetype)initWithUTF32String: (const of_char32_t *)string
			     length: (size_t)length
			  byteOrder: (of_byte_order_t)byteOrder
{
	return (id)[[OFMutableUTF8String alloc] initWithUTF32String: string
							     length: length
							  byteOrder: byteOrder];
}

- (instancetype)initWithFormat: (OFConstantString *)format, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, format);
	ret = [[OFMutableUTF8String alloc] initWithFormat: format
						arguments: arguments];
	va_end(arguments);

	return ret;
}

- (instancetype)initWithFormat: (OFConstantString *)format
		     arguments: (va_list)arguments
{
	return (id)[[OFMutableUTF8String alloc] initWithFormat: format
						     arguments: arguments];
}

#ifdef OF_HAVE_FILES
- (instancetype)initWithContentsOfFile: (OFString *)path
{
	return (id)[[OFMutableUTF8String alloc] initWithContentsOfFile: path];
}

- (instancetype)initWithContentsOfFile: (OFString *)path
			      encoding: (of_string_encoding_t)encoding
{
	return (id)[[OFMutableUTF8String alloc]
	    initWithContentsOfFile: path
			  encoding: encoding];
}
#endif

#if defined(OF_HAVE_FILES) || defined(OF_HAVE_SOCKETS)
- (instancetype)initWithContentsOfURL: (OFURL *)URL
{
	return (id)[[OFMutableUTF8String alloc] initWithContentsOfURL: URL];
}

- (instancetype)initWithContentsOfURL: (OFURL *)URL
			     encoding: (of_string_encoding_t)encoding
{
	return (id)[[OFMutableUTF8String alloc]
	    initWithContentsOfURL: URL
			 encoding: encoding];
}
#endif

- (instancetype)initWithSerialization: (OFXMLElement *)element
{
	return (id)[[OFMutableUTF8String alloc] initWithSerialization: element];
}

- (instancetype)retain
{
	return self;
}

- (instancetype)autorelease
{
	return self;
}

- (void)release
{
}

- (void)dealloc
{
	OF_DEALLOC_UNSUPPORTED
}
@end

@implementation OFMutableString
+ (void)initialize
{
	if (self == [OFMutableString class])
		placeholder.isa = [OFMutableStringPlaceholder class];
}

+ (instancetype)alloc
{
	if (self == [OFMutableString class])
		return (id)&placeholder;

	return [super alloc];
}

#ifdef OF_HAVE_UNICODE_TABLES
- (void)of_convertWithWordStartTable: (const of_unichar_t *const [])startTable
		     wordMiddleTable: (const of_unichar_t *const [])middleTable
		  wordStartTableSize: (size_t)startTableSize
		 wordMiddleTableSize: (size_t)middleTableSize
{
	void *pool = objc_autoreleasePoolPush();
	const of_unichar_t *characters = self.characters;
	size_t length = self.length;
	bool isStart = true;

	for (size_t i = 0; i < length; i++) {
		const of_unichar_t *const *table;
		size_t tableSize;
		of_unichar_t c = characters[i];

		if (isStart) {
			table = startTable;
			tableSize = middleTableSize;
		} else {
			table = middleTable;
			tableSize = middleTableSize;
		}

		if (c >> 8 < tableSize && table[c >> 8][c & 0xFF])
			[self setCharacter: table[c >> 8][c & 0xFF]
				   atIndex: i];

		isStart = of_ascii_isspace(c);
	}

	objc_autoreleasePoolPop(pool);
}
#else
- (void)of_convertWithWordStartFunction: (char (*)(char))startFunction
		     wordMiddleFunction: (char (*)(char))middleFunction
{
	void *pool = objc_autoreleasePoolPush();
	const of_unichar_t *characters = self.characters;
	size_t length = self.length;
	bool isStart = true;

	for (size_t i = 0; i < length; i++) {
		char (*function)(char) =
		    (isStart ? startFunction : middleFunction);
		of_unichar_t c = characters[i];

		if (c <= 0x7F)
			[self setCharacter: (int)function(c)
				   atIndex: i];

		isStart = of_ascii_isspace(c);
	}

	objc_autoreleasePoolPop(pool);
}
#endif

- (void)setCharacter: (of_unichar_t)character
	     atIndex: (size_t)idx
{
	void *pool = objc_autoreleasePoolPush();
	OFString *string;

	string = [OFString stringWithCharacters: &character
					 length: 1];

	[self replaceCharactersInRange: of_range(idx, 1)
			    withString: string];

	objc_autoreleasePoolPop(pool);
}

- (void)appendString: (OFString *)string
{
	[self insertString: string
		   atIndex: self.length];
}

- (void)appendCharacters: (const of_unichar_t *)characters
		  length: (size_t)length
{
	void *pool = objc_autoreleasePoolPush();

	[self appendString: [OFString stringWithCharacters: characters
						    length: length]];

	objc_autoreleasePoolPop(pool);
}

- (void)appendUTF8String: (const char *)UTF8String
{
	void *pool = objc_autoreleasePoolPush();

	[self appendString: [OFString stringWithUTF8String: UTF8String]];

	objc_autoreleasePoolPop(pool);
}

- (void)appendUTF8String: (const char *)UTF8String
		  length: (size_t)UTF8StringLength
{
	void *pool = objc_autoreleasePoolPush();

	[self appendString: [OFString stringWithUTF8String: UTF8String
						    length: UTF8StringLength]];

	objc_autoreleasePoolPop(pool);
}

- (void)appendCString: (const char *)cString
	     encoding: (of_string_encoding_t)encoding
{
	void *pool = objc_autoreleasePoolPush();

	[self appendString: [OFString stringWithCString: cString
					       encoding: encoding]];

	objc_autoreleasePoolPop(pool);
}

- (void)appendCString: (const char *)cString
	     encoding: (of_string_encoding_t)encoding
	       length: (size_t)cStringLength
{
	void *pool = objc_autoreleasePoolPush();

	[self appendString: [OFString stringWithCString: cString
					       encoding: encoding
						 length: cStringLength]];

	objc_autoreleasePoolPop(pool);
}

- (void)appendFormat: (OFConstantString *)format, ...
{
	va_list arguments;

	va_start(arguments, format);
	[self appendFormat: format
		 arguments: arguments];
	va_end(arguments);
}

- (void)appendFormat: (OFConstantString *)format
	   arguments: (va_list)arguments
{
	char *UTF8String;
	int UTF8StringLength;

	if (format == nil)
		@throw [OFInvalidArgumentException exception];

	if ((UTF8StringLength = of_vasprintf(&UTF8String, format.UTF8String,
	    arguments)) == -1)
		@throw [OFInvalidFormatException exception];

	@try {
		[self appendUTF8String: UTF8String
				length: UTF8StringLength];
	} @finally {
		free(UTF8String);
	}
}

- (void)prependString: (OFString *)string
{
	[self insertString: string
		   atIndex: 0];
}

- (void)reverse
{
	size_t i, j, length = self.length;

	for (i = 0, j = length - 1; i < length / 2; i++, j--) {
		of_unichar_t tmp = [self characterAtIndex: j];
		[self setCharacter: [self characterAtIndex: i]
			   atIndex: j];
		[self setCharacter: tmp
			   atIndex: i];
	}
}

#ifdef OF_HAVE_UNICODE_TABLES
- (void)uppercase
{
	[self of_convertWithWordStartTable: of_unicode_uppercase_table
			   wordMiddleTable: of_unicode_uppercase_table
			wordStartTableSize: OF_UNICODE_UPPERCASE_TABLE_SIZE
		       wordMiddleTableSize: OF_UNICODE_UPPERCASE_TABLE_SIZE];
}

- (void)lowercase
{
	[self of_convertWithWordStartTable: of_unicode_lowercase_table
			   wordMiddleTable: of_unicode_lowercase_table
			wordStartTableSize: OF_UNICODE_LOWERCASE_TABLE_SIZE
		       wordMiddleTableSize: OF_UNICODE_LOWERCASE_TABLE_SIZE];
}

- (void)capitalize
{
	[self of_convertWithWordStartTable: of_unicode_titlecase_table
			   wordMiddleTable: of_unicode_lowercase_table
			wordStartTableSize: OF_UNICODE_TITLECASE_TABLE_SIZE
		       wordMiddleTableSize: OF_UNICODE_LOWERCASE_TABLE_SIZE];
}
#else
- (void)uppercase
{
	[self of_convertWithWordStartFunction: of_ascii_toupper
			   wordMiddleFunction: of_ascii_toupper];
}

- (void)lowercase
{
	[self of_convertWithWordStartFunction: of_ascii_tolower
			   wordMiddleFunction: of_ascii_tolower];
}

- (void)capitalize
{
	[self of_convertWithWordStartFunction: of_ascii_toupper
			   wordMiddleFunction: of_ascii_tolower];
}
#endif

- (void)insertString: (OFString *)string
	     atIndex: (size_t)idx
{
	[self replaceCharactersInRange: of_range(idx, 0)
			    withString: string];
}

- (void)deleteCharactersInRange: (of_range_t)range
{
	[self replaceCharactersInRange: range
			    withString: @""];
}

- (void)replaceCharactersInRange: (of_range_t)range
		      withString: (OFString *)replacement
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)replaceOccurrencesOfString: (OFString *)string
			withString: (OFString *)replacement
{
	[self replaceOccurrencesOfString: string
			      withString: replacement
				 options: 0
				   range: of_range(0, self.length)];
}

- (void)replaceOccurrencesOfString: (OFString *)string
			withString: (OFString *)replacement
			   options: (int)options
			     range: (of_range_t)range
{
	void *pool = objc_autoreleasePoolPush(), *pool2;
	const of_unichar_t *characters;
	const of_unichar_t *searchCharacters = string.characters;
	size_t searchLength = string.length;
	size_t replacementLength = replacement.length;

	if (string == nil || replacement == nil)
		@throw [OFInvalidArgumentException exception];

	if (range.length > SIZE_MAX - range.location ||
	    range.location + range.length > self.length)
		@throw [OFOutOfRangeException exception];

	if (searchLength > range.length) {
		objc_autoreleasePoolPop(pool);
		return;
	}

	pool2 = objc_autoreleasePoolPush();
	characters = self.characters;

	for (size_t i = range.location; i <= range.length - searchLength; i++) {
		if (memcmp(characters + i, searchCharacters,
		    searchLength * sizeof(of_unichar_t)) != 0)
			continue;

		[self replaceCharactersInRange: of_range(i, searchLength)
				    withString: replacement];

		range.length -= searchLength;
		range.length += replacementLength;

		i += replacementLength - 1;

		objc_autoreleasePoolPop(pool2);
		pool2 = objc_autoreleasePoolPush();

		characters = self.characters;
	}

	objc_autoreleasePoolPop(pool);
}

- (void)deleteLeadingWhitespaces
{
	void *pool = objc_autoreleasePoolPush();
	const of_unichar_t *characters = self.characters;
	size_t i, length = self.length;

	for (i = 0; i < length; i++) {
		of_unichar_t c = characters[i];

		if (!of_ascii_isspace(c))
			break;
	}

	objc_autoreleasePoolPop(pool);

	[self deleteCharactersInRange: of_range(0, i)];
}

- (void)deleteTrailingWhitespaces
{
	void *pool;
	const of_unichar_t *characters, *p;
	size_t length, d;

	length = self.length;

	if (length == 0)
		return;

	pool = objc_autoreleasePoolPush();
	characters = self.characters;

	d = 0;
	for (p = characters + length - 1; p >= characters; p--) {
		if (!of_ascii_isspace(*p))
			break;

		d++;
	}

	objc_autoreleasePoolPop(pool);

	[self deleteCharactersInRange: of_range(length - d, d)];
}

- (void)deleteEnclosingWhitespaces
{
	[self deleteLeadingWhitespaces];
	[self deleteTrailingWhitespaces];
}

- (id)copy
{
	return [[OFString alloc] initWithString: self];
}

- (void)makeImmutable
{
}
@end
