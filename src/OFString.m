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

#include <errno.h>
#include <math.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>

#if defined(HAVE_STRTOF_L) || defined(HAVE_STRTOD_L)
# include <locale.h>
#endif
#ifdef HAVE_XLOCALE_H
# include <xlocale.h>
#endif

#import "OFString.h"
#import "OFArray.h"
#import "OFCharacterSet.h"
#import "OFData.h"
#import "OFDictionary.h"
#ifdef OF_HAVE_FILES
# import "OFFile.h"
# import "OFFileManager.h"
#endif
#import "OFLocale.h"
#import "OFStream.h"
#import "OFURL.h"
#import "OFURLHandler.h"
#import "OFUTF8String.h"
#import "OFUTF8String+Private.h"
#import "OFXMLElement.h"

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"
#import "OFOpenItemFailedException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFRetrieveItemAttributesFailedException.h"
#import "OFTruncatedDataException.h"
#import "OFUnsupportedProtocolException.h"

#import "of_asprintf.h"
#import "unicode.h"

/*
 * It seems strtod is buggy on Win32.
 * However, the MinGW version __strtod seems to be ok.
 */
#ifdef __MINGW32__
# define strtod __strtod
#endif

#ifdef OF_AMIGAOS_M68K
/* libnix has strtod, but not strtof */
# define strtof strtod
#endif

static struct {
	Class isa;
} placeholder;

#if defined(HAVE_STRTOF_L) || defined(HAVE_STRTOD_L)
static locale_t cLocale;
#endif

@interface OFString ()
- (size_t)of_getCString: (char *)cString
	      maxLength: (size_t)maxLength
	       encoding: (of_string_encoding_t)encoding
		  lossy: (bool)lossy;
- (const char *)of_cStringWithEncoding: (of_string_encoding_t)encoding
				 lossy: (bool)lossy;
- (OFString *)of_JSONRepresentationWithOptions: (int)options
					 depth: (size_t)depth;
@end

@interface OFStringPlaceholder: OFString
@end

extern bool of_unicode_to_iso_8859_2(const of_unichar_t *, unsigned char *,
    size_t, bool);
extern bool of_unicode_to_iso_8859_3(const of_unichar_t *, unsigned char *,
    size_t, bool);
extern bool of_unicode_to_iso_8859_15(const of_unichar_t *, unsigned char *,
    size_t, bool);
extern bool of_unicode_to_windows_1251(const of_unichar_t *, unsigned char *,
    size_t, bool);
extern bool of_unicode_to_windows_1252(const of_unichar_t *, unsigned char *,
    size_t, bool);
extern bool of_unicode_to_codepage_437(const of_unichar_t *, unsigned char *,
    size_t, bool);
extern bool of_unicode_to_codepage_850(const of_unichar_t *, unsigned char *,
    size_t, bool);
extern bool of_unicode_to_codepage_858(const of_unichar_t *, unsigned char *,
    size_t, bool);
extern bool of_unicode_to_mac_roman(const of_unichar_t *, unsigned char *,
    size_t, bool);
extern bool of_unicode_to_koi8_r(const of_unichar_t *, unsigned char *,
    size_t, bool);
extern bool of_unicode_to_koi8_u(const of_unichar_t *, unsigned char *,
    size_t, bool);

/* References for static linking */
void
_references_to_categories_of_OFString(void)
{
	_OFString_CryptoHashing_reference = 1;
	_OFString_JSONValue_reference = 1;
#ifdef OF_HAVE_FILES
	_OFString_PathAdditions_reference = 1;
#endif
	_OFString_PropertyListValue_reference = 1;
	_OFString_Serialization_reference = 1;
	_OFString_URLEncoding_reference = 1;
	_OFString_XMLEscaping_reference = 1;
	_OFString_XMLUnescaping_reference = 1;
}

void
_reference_to_OFConstantString(void)
{
	[OFConstantString class];
}

of_string_encoding_t
of_string_parse_encoding(OFString *string)
{
	void *pool = objc_autoreleasePoolPush();
	of_string_encoding_t encoding;

	string = string.lowercaseString;

	if ([string isEqual: @"utf8"] || [string isEqual: @"utf-8"])
		encoding = OF_STRING_ENCODING_UTF_8;
	else if ([string isEqual: @"ascii"] || [string isEqual: @"us-ascii"])
		encoding = OF_STRING_ENCODING_ASCII;
	else if ([string isEqual: @"iso-8859-1"] ||
	    [string isEqual: @"iso_8859-1"])
		encoding = OF_STRING_ENCODING_ISO_8859_1;
	else if ([string isEqual: @"iso-8859-2"] ||
	    [string isEqual: @"iso_8859-2"])
		encoding = OF_STRING_ENCODING_ISO_8859_2;
	else if ([string isEqual: @"iso-8859-3"] ||
	    [string isEqual: @"iso_8859-3"])
		encoding = OF_STRING_ENCODING_ISO_8859_3;
	else if ([string isEqual: @"iso-8859-15"] ||
	    [string isEqual: @"iso_8859-15"])
		encoding = OF_STRING_ENCODING_ISO_8859_15;
	else if ([string isEqual: @"windows-1251"] ||
	    [string isEqual: @"cp1251"] || [string isEqual: @"cp-1251"] ||
	    [string isEqual: @"1251"])
		encoding = OF_STRING_ENCODING_WINDOWS_1251;
	else if ([string isEqual: @"windows-1252"] ||
	    [string isEqual: @"cp1252"] || [string isEqual: @"cp-1252"] ||
	    [string isEqual: @"1252"])
		encoding = OF_STRING_ENCODING_WINDOWS_1252;
	else if ([string isEqual: @"cp437"] || [string isEqual: @"cp-437"] ||
	    [string isEqual: @"ibm437"] || [string isEqual: @"437"])
		encoding = OF_STRING_ENCODING_CODEPAGE_437;
	else if ([string isEqual: @"cp850"] || [string isEqual: @"cp-850"] ||
	    [string isEqual: @"ibm850"] || [string isEqual: @"850"])
		encoding = OF_STRING_ENCODING_CODEPAGE_850;
	else if ([string isEqual: @"cp858"] || [string isEqual: @"cp-858"] ||
	    [string isEqual: @"ibm858"] || [string isEqual: @"858"])
		encoding = OF_STRING_ENCODING_CODEPAGE_858;
	else if ([string isEqual: @"macintosh"] || [string isEqual: @"mac"])
		encoding = OF_STRING_ENCODING_MAC_ROMAN;
	else if ([string isEqual: @"koi8-r"])
		encoding = OF_STRING_ENCODING_KOI8_R;
	else if ([string isEqual: @"koi8-u"])
		encoding = OF_STRING_ENCODING_KOI8_U;
	else
		@throw [OFInvalidEncodingException exception];

	objc_autoreleasePoolPop(pool);

	return encoding;
}

OFString *
of_string_name_of_encoding(of_string_encoding_t encoding)
{
	switch (encoding) {
	case OF_STRING_ENCODING_UTF_8:
		return @"UTF-8";
	case OF_STRING_ENCODING_ASCII:
		return @"ASCII";
	case OF_STRING_ENCODING_ISO_8859_1:
		return @"ISO 8859-1";
	case OF_STRING_ENCODING_ISO_8859_2:
		return @"ISO 8859-2";
	case OF_STRING_ENCODING_ISO_8859_3:
		return @"ISO 8859-3";
	case OF_STRING_ENCODING_ISO_8859_15:
		return @"ISO 8859-15";
	case OF_STRING_ENCODING_WINDOWS_1251:
		return @"Windows-1251";
	case OF_STRING_ENCODING_WINDOWS_1252:
		return @"Windows-1252";
	case OF_STRING_ENCODING_CODEPAGE_437:
		return @"Codepage 437";
	case OF_STRING_ENCODING_CODEPAGE_850:
		return @"Codepage 850";
	case OF_STRING_ENCODING_CODEPAGE_858:
		return @"Codepage 858";
	case OF_STRING_ENCODING_MAC_ROMAN:
		return @"Mac Roman";
	case OF_STRING_ENCODING_KOI8_R:
		return @"KOI8-R";
	case OF_STRING_ENCODING_KOI8_U:
		return @"KOI8-U";
	case OF_STRING_ENCODING_AUTODETECT:
		return @"autodetect";
	}

	return nil;
}

size_t
of_string_utf8_encode(of_unichar_t character, char *buffer)
{
	if (character < 0x80) {
		buffer[0] = character;
		return 1;
	} else if (character < 0x800) {
		buffer[0] = 0xC0 | (character >> 6);
		buffer[1] = 0x80 | (character & 0x3F);
		return 2;
	} else if (character < 0x10000) {
		buffer[0] = 0xE0 | (character >> 12);
		buffer[1] = 0x80 | (character >> 6 & 0x3F);
		buffer[2] = 0x80 | (character & 0x3F);
		return 3;
	} else if (character < 0x110000) {
		buffer[0] = 0xF0 | (character >> 18);
		buffer[1] = 0x80 | (character >> 12 & 0x3F);
		buffer[2] = 0x80 | (character >> 6 & 0x3F);
		buffer[3] = 0x80 | (character & 0x3F);
		return 4;
	}

	return 0;
}

ssize_t
of_string_utf8_decode(const char *buffer_, size_t length, of_unichar_t *ret)
{
	const unsigned char *buffer = (const unsigned char *)buffer_;

	if (!(*buffer & 0x80)) {
		*ret = buffer[0];
		return 1;
	}

	if ((*buffer & 0xE0) == 0xC0) {
		if OF_UNLIKELY (length < 2)
			return -2;

		if OF_UNLIKELY ((buffer[1] & 0xC0) != 0x80)
			return 0;

		*ret = ((buffer[0] & 0x1F) << 6) | (buffer[1] & 0x3F);
		return 2;
	}

	if ((*buffer & 0xF0) == 0xE0) {
		if OF_UNLIKELY (length < 3)
			return -3;

		if OF_UNLIKELY ((buffer[1] & 0xC0) != 0x80 ||
		    (buffer[2] & 0xC0) != 0x80)
			return 0;

		*ret = ((buffer[0] & 0x0F) << 12) | ((buffer[1] & 0x3F) << 6) |
		    (buffer[2] & 0x3F);
		return 3;
	}

	if ((*buffer & 0xF8) == 0xF0) {
		if OF_UNLIKELY (length < 4)
			return -4;

		if OF_UNLIKELY ((buffer[1] & 0xC0) != 0x80 ||
		    (buffer[2] & 0xC0) != 0x80 || (buffer[3] & 0xC0) != 0x80)
			return 0;

		*ret = ((buffer[0] & 0x07) << 18) | ((buffer[1] & 0x3F) << 12) |
		    ((buffer[2] & 0x3F) << 6) | (buffer[3] & 0x3F);
		return 4;
	}

	return 0;
}

size_t
of_string_utf16_length(const of_char16_t *string)
{
	size_t length = 0;

	while (*string++ != 0)
		length++;

	return length;
}

size_t
of_string_utf32_length(const of_char32_t *string)
{
	size_t length = 0;

	while (*string++ != 0)
		length++;

	return length;
}

#ifdef OF_HAVE_UNICODE_TABLES
static OFString *
decomposedString(OFString *self, const char *const *const *table, size_t size)
{
	OFMutableString *ret = [OFMutableString string];
	void *pool = objc_autoreleasePoolPush();
	const of_unichar_t *characters = self.characters;
	size_t length = self.length;

	for (size_t i = 0; i < length; i++) {
		of_unichar_t c = characters[i];
		const char *const *page;

		if (c >= size) {
			[ret appendCharacters: &c
				       length: 1];
			continue;
		}

		page = table[c >> 8];
		if (page != NULL && page[c & 0xFF] != NULL)
			[ret appendUTF8String: page[c & 0xFF]];
		else
			[ret appendCharacters: &c
				       length: 1];
	}

	objc_autoreleasePoolPop(pool);

	return ret;
}
#endif

@implementation OFStringPlaceholder
- (instancetype)init
{
	return (id)[[OFUTF8String alloc] init];
}

- (instancetype)initWithUTF8String: (const char *)UTF8String
{
	id string;
	size_t length;
	void *storage;

	length = strlen(UTF8String);
	string = of_alloc_object([OFUTF8String class], length + 1, 1, &storage);

	return (id)[string of_initWithUTF8String: UTF8String
					  length: length
					 storage: storage];
}

- (instancetype)initWithUTF8String: (const char *)UTF8String
			    length: (size_t)UTF8StringLength
{
	id string;
	void *storage;

	string = of_alloc_object([OFUTF8String class], UTF8StringLength + 1, 1,
	    &storage);

	return (id)[string of_initWithUTF8String: UTF8String
					  length: UTF8StringLength
					 storage: storage];
}

- (instancetype)initWithUTF8StringNoCopy: (char *)UTF8String
			    freeWhenDone: (bool)freeWhenDone
{
	return (id)[[OFUTF8String alloc]
	    initWithUTF8StringNoCopy: UTF8String
			freeWhenDone: freeWhenDone];
}

- (instancetype)initWithUTF8StringNoCopy: (char *)UTF8String
				  length: (size_t)UTF8StringLength
			    freeWhenDone: (bool)freeWhenDone
{
	return (id)[[OFUTF8String alloc]
	    initWithUTF8StringNoCopy: UTF8String
			      length: UTF8StringLength
			freeWhenDone: freeWhenDone];
}

- (instancetype)initWithCString: (const char *)cString
		       encoding: (of_string_encoding_t)encoding
{
	if (encoding == OF_STRING_ENCODING_UTF_8) {
		id string;
		size_t length;
		void *storage;

		length = strlen(cString);
		string = of_alloc_object([OFUTF8String class], length + 1, 1,
		    &storage);

		return (id)[string of_initWithUTF8String: cString
						  length: length
						 storage: storage];
	}

	return (id)[[OFUTF8String alloc] initWithCString: cString
						encoding: encoding];
}

- (instancetype)initWithCString: (const char *)cString
		       encoding: (of_string_encoding_t)encoding
			 length: (size_t)cStringLength
{
	if (encoding == OF_STRING_ENCODING_UTF_8) {
		id string;
		void *storage;

		string = of_alloc_object([OFUTF8String class],
		    cStringLength + 1, 1, &storage);

		return (id)[string of_initWithUTF8String: cString
						  length: cStringLength
						 storage: storage];
	}

	return (id)[[OFUTF8String alloc] initWithCString: cString
						encoding: encoding
						  length: cStringLength];
}

- (instancetype)initWithData: (OFData *)data
		    encoding: (of_string_encoding_t)encoding
{
	return (id)[[OFUTF8String alloc] initWithData: data
					     encoding: encoding];
}

- (instancetype)initWithString: (OFString *)string
{
	return (id)[[OFUTF8String alloc] initWithString: string];
}

- (instancetype)initWithCharacters: (const of_unichar_t *)string
			    length: (size_t)length
{
	return (id)[[OFUTF8String alloc] initWithCharacters: string
						     length: length];
}

- (instancetype)initWithUTF16String: (const of_char16_t *)string
{
	return (id)[[OFUTF8String alloc] initWithUTF16String: string];
}

- (instancetype)initWithUTF16String: (const of_char16_t *)string
			     length: (size_t)length
{
	return (id)[[OFUTF8String alloc] initWithUTF16String: string
						      length: length];
}

- (instancetype)initWithUTF16String: (const of_char16_t *)string
			  byteOrder: (of_byte_order_t)byteOrder
{
	return (id)[[OFUTF8String alloc] initWithUTF16String: string
						   byteOrder: byteOrder];
}

- (instancetype)initWithUTF16String: (const of_char16_t *)string
			     length: (size_t)length
			  byteOrder: (of_byte_order_t)byteOrder
{
	return (id)[[OFUTF8String alloc] initWithUTF16String: string
						      length: length
						   byteOrder: byteOrder];
}

- (instancetype)initWithUTF32String: (const of_char32_t *)string
{
	return (id)[[OFUTF8String alloc] initWithUTF32String: string];
}

- (instancetype)initWithUTF32String: (const of_char32_t *)string
			     length: (size_t)length
{
	return (id)[[OFUTF8String alloc] initWithUTF32String: string
						      length: length];
}

- (instancetype)initWithUTF32String: (const of_char32_t *)string
			  byteOrder: (of_byte_order_t)byteOrder
{
	return (id)[[OFUTF8String alloc] initWithUTF32String: string
						   byteOrder: byteOrder];
}

- (instancetype)initWithUTF32String: (const of_char32_t *)string
			     length: (size_t)length
			  byteOrder: (of_byte_order_t)byteOrder
{
	return (id)[[OFUTF8String alloc] initWithUTF32String: string
						      length: length
						   byteOrder: byteOrder];
}

- (instancetype)initWithFormat: (OFConstantString *)format, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, format);
	ret = [[OFUTF8String alloc] initWithFormat: format
					 arguments: arguments];
	va_end(arguments);

	return ret;
}

- (instancetype)initWithFormat: (OFConstantString *)format
		     arguments: (va_list)arguments
{
	return (id)[[OFUTF8String alloc] initWithFormat: format
					      arguments: arguments];
}

#ifdef OF_HAVE_FILES
- (instancetype)initWithContentsOfFile: (OFString *)path
{
	return (id)[[OFUTF8String alloc] initWithContentsOfFile: path];
}

- (instancetype)initWithContentsOfFile: (OFString *)path
			      encoding: (of_string_encoding_t)encoding
{
	return (id)[[OFUTF8String alloc] initWithContentsOfFile: path
						       encoding: encoding];
}
#endif

#if defined(OF_HAVE_FILES) || defined(OF_HAVE_SOCKETS)
- (instancetype)initWithContentsOfURL: (OFURL *)URL
{
	return (id)[[OFUTF8String alloc] initWithContentsOfURL: URL];
}

- (instancetype)initWithContentsOfURL: (OFURL *)URL
			     encoding: (of_string_encoding_t)encoding
{
	return (id)[[OFUTF8String alloc] initWithContentsOfURL: URL
						      encoding: encoding];
}
#endif

- (instancetype)initWithSerialization: (OFXMLElement *)element
{
	return (id)[[OFUTF8String alloc] initWithSerialization: element];
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

@implementation OFString
+ (void)initialize
{
	if (self != [OFString class])
		return;

	placeholder.isa = [OFStringPlaceholder class];

#if defined(HAVE_STRTOF_L) || defined(HAVE_STRTOD_L)
	if ((cLocale = newlocale(LC_ALL_MASK, "C", NULL)) == NULL)
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
#endif
}

+ (instancetype)alloc
{
	if (self == [OFString class])
		return (id)&placeholder;

	return [super alloc];
}

+ (instancetype)string
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)stringWithUTF8String: (const char *)UTF8String
{
	return [[[self alloc] initWithUTF8String: UTF8String] autorelease];
}

+ (instancetype)stringWithUTF8String: (const char *)UTF8String
			      length: (size_t)UTF8StringLength
{
	return [[[self alloc]
	    initWithUTF8String: UTF8String
			length: UTF8StringLength] autorelease];
}

+ (instancetype)stringWithUTF8StringNoCopy: (char *)UTF8String
			      freeWhenDone: (bool)freeWhenDone
{
	return [[[self alloc]
	    initWithUTF8StringNoCopy: UTF8String
			freeWhenDone: freeWhenDone] autorelease];
}

+ (instancetype)stringWithUTF8StringNoCopy: (char *)UTF8String
				    length: (size_t)UTF8StringLength
			      freeWhenDone: (bool)freeWhenDone
{
	return [[[self alloc]
	    initWithUTF8StringNoCopy: UTF8String
			      length: UTF8StringLength
			freeWhenDone: freeWhenDone] autorelease];
}

+ (instancetype)stringWithCString: (const char *)cString
			 encoding: (of_string_encoding_t)encoding
{
	return [[[self alloc] initWithCString: cString
				     encoding: encoding] autorelease];
}

+ (instancetype)stringWithCString: (const char *)cString
			 encoding: (of_string_encoding_t)encoding
			   length: (size_t)cStringLength
{
	return [[[self alloc] initWithCString: cString
				     encoding: encoding
				       length: cStringLength] autorelease];
}

+ (instancetype)stringWithData: (OFData *)data
		      encoding: (of_string_encoding_t)encoding
{
	return [[[self alloc] initWithData: data
				  encoding: encoding] autorelease];
}

+ (instancetype)stringWithString: (OFString *)string
{
	return [[[self alloc] initWithString: string] autorelease];
}

+ (instancetype)stringWithCharacters: (const of_unichar_t *)string
			      length: (size_t)length
{
	return [[[self alloc] initWithCharacters: string
					  length: length] autorelease];
}

+ (instancetype)stringWithUTF16String: (const of_char16_t *)string
{
	return [[[self alloc] initWithUTF16String: string] autorelease];
}

+ (instancetype)stringWithUTF16String: (const of_char16_t *)string
			       length: (size_t)length
{
	return [[[self alloc] initWithUTF16String: string
					   length: length] autorelease];
}

+ (instancetype)stringWithUTF16String: (const of_char16_t *)string
			    byteOrder: (of_byte_order_t)byteOrder
{
	return [[[self alloc] initWithUTF16String: string
					byteOrder: byteOrder] autorelease];
}

+ (instancetype)stringWithUTF16String: (const of_char16_t *)string
			       length: (size_t)length
			    byteOrder: (of_byte_order_t)byteOrder
{
	return [[[self alloc] initWithUTF16String: string
					   length: length
					byteOrder: byteOrder] autorelease];
}

+ (instancetype)stringWithUTF32String: (const of_char32_t *)string
{
	return [[[self alloc] initWithUTF32String: string] autorelease];
}

+ (instancetype)stringWithUTF32String: (const of_char32_t *)string
			       length: (size_t)length
{
	return [[[self alloc] initWithUTF32String: string
					   length: length] autorelease];
}

+ (instancetype)stringWithUTF32String: (const of_char32_t *)string
			    byteOrder: (of_byte_order_t)byteOrder
{
	return [[[self alloc] initWithUTF32String: string
					byteOrder: byteOrder] autorelease];
}

+ (instancetype)stringWithUTF32String: (const of_char32_t *)string
			       length: (size_t)length
			    byteOrder: (of_byte_order_t)byteOrder
{
	return [[[self alloc] initWithUTF32String: string
					   length: length
					byteOrder: byteOrder] autorelease];
}

+ (instancetype)stringWithFormat: (OFConstantString *)format, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, format);
	ret = [[[self alloc] initWithFormat: format
				  arguments: arguments] autorelease];
	va_end(arguments);

	return ret;
}

#ifdef OF_HAVE_FILES
+ (instancetype)stringWithContentsOfFile: (OFString *)path
{
	return [[[self alloc] initWithContentsOfFile: path] autorelease];
}

+ (instancetype)stringWithContentsOfFile: (OFString *)path
				encoding: (of_string_encoding_t)encoding
{
	return [[[self alloc] initWithContentsOfFile: path
					    encoding: encoding] autorelease];
}
#endif

#if defined(OF_HAVE_FILES) || defined(OF_HAVE_SOCKETS)
+ (instancetype)stringWithContentsOfURL: (OFURL *)URL
{
	return [[[self alloc] initWithContentsOfURL: URL] autorelease];
}

+ (instancetype)stringWithContentsOfURL: (OFURL *)URL
			       encoding: (of_string_encoding_t)encoding
{
	return [[[self alloc] initWithContentsOfURL: URL
					   encoding: encoding] autorelease];
}
#endif

- (instancetype)init
{
	if ([self isMemberOfClass: [OFString class]]) {
		@try {
			[self doesNotRecognizeSelector: _cmd];
		} @catch (id e) {
			[self release];
			@throw e;
		}

		abort();
	}

	return [super init];
}

- (instancetype)initWithUTF8String: (const char *)UTF8String
{
	return [self initWithCString: UTF8String
			    encoding: OF_STRING_ENCODING_UTF_8
			      length: strlen(UTF8String)];
}

- (instancetype)initWithUTF8String: (const char *)UTF8String
			    length: (size_t)UTF8StringLength
{
	return [self initWithCString: UTF8String
			    encoding: OF_STRING_ENCODING_UTF_8
			      length: UTF8StringLength];
}

- (instancetype)initWithUTF8StringNoCopy: (char *)UTF8String
			    freeWhenDone: (bool)freeWhenDone
{
	@try {
		return [self initWithUTF8String: UTF8String];
	} @finally {
		if (freeWhenDone)
			free(UTF8String);
	}
}

- (instancetype)initWithUTF8StringNoCopy: (char *)UTF8String
				  length: (size_t)UTF8StringLength
			    freeWhenDone: (bool)freeWhenDone
{
	@try {
		return [self initWithUTF8String: UTF8String
					 length: UTF8StringLength];
	} @finally {
		if (freeWhenDone)
			free(UTF8String);
	}
}

- (instancetype)initWithCString: (const char *)cString
		       encoding: (of_string_encoding_t)encoding
{
	return [self initWithCString: cString
			    encoding: encoding
			      length: strlen(cString)];
}

- (instancetype)initWithCString: (const char *)cString
		       encoding: (of_string_encoding_t)encoding
			 length: (size_t)cStringLength
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithData: (OFData *)data
		    encoding: (of_string_encoding_t)encoding
{
	@try {
		if (data.itemSize != 1)
			@throw [OFInvalidArgumentException exception];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	self = [self initWithCString: data.items
			    encoding: encoding
			      length: data.count];

	return self;
}

- (instancetype)initWithString: (OFString *)string
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithCharacters: (const of_unichar_t *)string
			    length: (size_t)length
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithUTF16String: (const of_char16_t *)string
{
	return [self initWithUTF16String: string
				  length: of_string_utf16_length(string)
			       byteOrder: OF_BYTE_ORDER_NATIVE];
}

- (instancetype)initWithUTF16String: (const of_char16_t *)string
			     length: (size_t)length
{
	return [self initWithUTF16String: string
				  length: length
			       byteOrder: OF_BYTE_ORDER_NATIVE];
}

- (instancetype)initWithUTF16String: (const of_char16_t *)string
			  byteOrder: (of_byte_order_t)byteOrder
{
	return [self initWithUTF16String: string
				  length: of_string_utf16_length(string)
			       byteOrder: byteOrder];
}

- (instancetype)initWithUTF16String: (const of_char16_t *)string
			     length: (size_t)length
			  byteOrder: (of_byte_order_t)byteOrder
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithUTF32String: (const of_char32_t *)string
{
	return [self initWithUTF32String: string
				  length: of_string_utf32_length(string)
			       byteOrder: OF_BYTE_ORDER_NATIVE];
}

- (instancetype)initWithUTF32String: (const of_char32_t *)string
			     length: (size_t)length
{
	return [self initWithUTF32String: string
				  length: length
			       byteOrder: OF_BYTE_ORDER_NATIVE];
}

- (instancetype)initWithUTF32String: (const of_char32_t *)string
			  byteOrder: (of_byte_order_t)byteOrder
{
	return [self initWithUTF32String: string
				  length: of_string_utf32_length(string)
			       byteOrder: byteOrder];
}

- (instancetype)initWithUTF32String: (const of_char32_t *)string
			     length: (size_t)length
			  byteOrder: (of_byte_order_t)byteOrder
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithFormat: (OFConstantString *)format, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, format);
	ret = [self initWithFormat: format
			 arguments: arguments];
	va_end(arguments);

	return ret;
}

- (instancetype)initWithFormat: (OFConstantString *)format
		     arguments: (va_list)arguments
{
	OF_INVALID_INIT_METHOD
}

#ifdef OF_HAVE_FILES
- (instancetype)initWithContentsOfFile: (OFString *)path
{
	return [self initWithContentsOfFile: path
				   encoding: OF_STRING_ENCODING_UTF_8];
}

- (instancetype)initWithContentsOfFile: (OFString *)path
			      encoding: (of_string_encoding_t)encoding
{
	char *tmp;
	uintmax_t fileSize;

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFFile *file = nil;

		@try {
			fileSize = [[OFFileManager defaultManager]
			    attributesOfItemAtPath: path].fileSize;
		} @catch (OFRetrieveItemAttributesFailedException *e) {
			@throw [OFOpenItemFailedException
			    exceptionWithPath: path
					 mode: @"r"
					errNo: e.errNo];
		}

		objc_autoreleasePoolPop(pool);

# if UINTMAX_MAX > SIZE_MAX
		if (fileSize > SIZE_MAX)
			@throw [OFOutOfRangeException exception];
#endif

		/*
		 * We need one extra byte for the terminating zero if we want
		 * to use -[initWithUTF8StringNoCopy:length:freeWhenDone:].
		 */
		if (SIZE_MAX - (size_t)fileSize < 1)
			@throw [OFOutOfRangeException exception];

		if ((tmp = malloc((size_t)fileSize + 1)) == NULL)
			@throw [OFOutOfMemoryException
			    exceptionWithRequestedSize: (size_t)fileSize];

		@try {
			file = [[OFFile alloc] initWithPath: path
						       mode: @"r"];

			[file readIntoBuffer: tmp
				 exactLength: (size_t)fileSize];
		} @catch (id e) {
			free(tmp);
			@throw e;
		} @finally {
			[file release];
		}

		tmp[(size_t)fileSize] = '\0';
	} @catch (id e) {
		[self release];
		@throw e;
	}

	if (encoding == OF_STRING_ENCODING_UTF_8)
		self = [self initWithUTF8StringNoCopy: tmp
					       length: (size_t)fileSize
					 freeWhenDone: true];
	else {
		@try {
			self = [self initWithCString: tmp
					    encoding: encoding
					      length: (size_t)fileSize];
		} @finally {
			free(tmp);
		}
	}

	return self;
}
#endif

- (instancetype)initWithContentsOfURL: (OFURL *)URL
{
	return [self initWithContentsOfURL: URL
				  encoding: OF_STRING_ENCODING_AUTODETECT];
}

- (instancetype)initWithContentsOfURL: (OFURL *)URL
			     encoding: (of_string_encoding_t)encoding
{
	void *pool = objc_autoreleasePoolPush();
	OFData *data;

	@try {
		data = [OFData dataWithContentsOfURL: URL];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	self = [self initWithCString: data.items
			    encoding: encoding
			      length: data.count * data.itemSize];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (instancetype)initWithSerialization: (OFXMLElement *)element
{
	void *pool = objc_autoreleasePoolPush();
	OFString *stringValue;

	@try {
		if (![element.namespace isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException exception];

		if ([self isKindOfClass: [OFMutableString class]]) {
			if (![element.name isEqual: @"OFMutableString"])
				@throw [OFInvalidArgumentException exception];
		} else {
			if (![element.name isEqual: @"OFString"])
				@throw [OFInvalidArgumentException exception];
		}

		stringValue = element.stringValue;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	self = [self initWithString: stringValue];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (size_t)of_getCString: (char *)cString
	      maxLength: (size_t)maxLength
	       encoding: (of_string_encoding_t)encoding
		  lossy: (bool)lossy
{
	const of_unichar_t *characters = self.characters;
	size_t i, length = self.length;

	switch (encoding) {
	case OF_STRING_ENCODING_UTF_8:;
		size_t j = 0;

		for (i = 0; i < length; i++) {
			char buffer[4];
			size_t len = of_string_utf8_encode(characters[i],
			    buffer);

			/*
			 * Check for one more than the current index, as we
			 * need one for the terminating zero.
			 */
			if (j + len >= maxLength)
				@throw [OFOutOfRangeException exception];

			switch (len) {
			case 1:
				cString[j++] = buffer[0];

				break;
			case 2:
			case 3:
			case 4:
				memcpy(cString + j, buffer, len);
				j += len;

				break;
			default:
				@throw [OFInvalidEncodingException exception];

				break;
			}
		}

		cString[j] = '\0';

		return j;
	case OF_STRING_ENCODING_ASCII:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		for (i = 0; i < length; i++) {
			if OF_UNLIKELY (characters[i] > 0x80) {
				if (lossy)
					cString[i] = '?';
				else
					@throw [OFInvalidEncodingException
					    exception];
			} else
				cString[i] = (unsigned char)characters[i];
		}

		cString[i] = '\0';

		return length;
	case OF_STRING_ENCODING_ISO_8859_1:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		for (i = 0; i < length; i++) {
			if OF_UNLIKELY (characters[i] > 0xFF) {
				if (lossy)
					cString[i] = '?';
				else
					@throw [OFInvalidEncodingException
					    exception];
			} else
				cString[i] = (unsigned char)characters[i];
		}

		cString[i] = '\0';

		return length;
#ifdef HAVE_ISO_8859_2
	case OF_STRING_ENCODING_ISO_8859_2:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!of_unicode_to_iso_8859_2(characters,
		    (unsigned char *)cString, length, lossy))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
#endif
#ifdef HAVE_ISO_8859_3
	case OF_STRING_ENCODING_ISO_8859_3:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!of_unicode_to_iso_8859_3(characters,
		    (unsigned char *)cString, length, lossy))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
#endif
#ifdef HAVE_ISO_8859_15
	case OF_STRING_ENCODING_ISO_8859_15:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!of_unicode_to_iso_8859_15(characters,
		    (unsigned char *)cString, length, lossy))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
#endif
#ifdef HAVE_WINDOWS_1251
	case OF_STRING_ENCODING_WINDOWS_1251:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!of_unicode_to_windows_1251(characters,
		    (unsigned char *)cString, length, lossy))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
#endif
#ifdef HAVE_WINDOWS_1252
	case OF_STRING_ENCODING_WINDOWS_1252:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!of_unicode_to_windows_1252(characters,
		    (unsigned char *)cString, length, lossy))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
#endif
#ifdef HAVE_CODEPAGE_437
	case OF_STRING_ENCODING_CODEPAGE_437:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!of_unicode_to_codepage_437(characters,
		    (unsigned char *)cString, length, lossy))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
#endif
#ifdef HAVE_CODEPAGE_850
	case OF_STRING_ENCODING_CODEPAGE_850:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!of_unicode_to_codepage_850(characters,
		    (unsigned char *)cString, length, lossy))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
#endif
#ifdef HAVE_CODEPAGE_858
	case OF_STRING_ENCODING_CODEPAGE_858:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!of_unicode_to_codepage_858(characters,
		    (unsigned char *)cString, length, lossy))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
#endif
#ifdef HAVE_MAC_ROMAN
	case OF_STRING_ENCODING_MAC_ROMAN:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!of_unicode_to_mac_roman(characters,
		    (unsigned char *)cString, length, lossy))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
#endif
#ifdef HAVE_KOI8_R
	case OF_STRING_ENCODING_KOI8_R:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!of_unicode_to_koi8_r(characters,
		    (unsigned char *)cString, length, lossy))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
#endif
#ifdef HAVE_KOI8_U
	case OF_STRING_ENCODING_KOI8_U:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!of_unicode_to_koi8_u(characters,
		    (unsigned char *)cString, length, lossy))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
#endif
	default:
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];
	}
}

- (size_t)getCString: (char *)cString
	   maxLength: (size_t)maxLength
	    encoding: (of_string_encoding_t)encoding
{
	return [self of_getCString: cString
			 maxLength: maxLength
			  encoding: encoding
			     lossy: false];
}

- (size_t)getLossyCString: (char *)cString
		maxLength: (size_t)maxLength
		 encoding: (of_string_encoding_t)encoding
{
	return [self of_getCString: cString
			 maxLength: maxLength
			  encoding: encoding
			     lossy: true];
}

- (const char *)of_cStringWithEncoding: (of_string_encoding_t)encoding
				 lossy: (bool)lossy
{
	OFObject *object = [[[OFObject alloc] init] autorelease];
	size_t length = self.length;
	char *cString;

	switch (encoding) {
	case OF_STRING_ENCODING_UTF_8:;
		size_t cStringLength;

		cString = [object allocMemoryWithSize: (length * 4) + 1];

		cStringLength = [self of_getCString: cString
					  maxLength: (length * 4) + 1
					   encoding: OF_STRING_ENCODING_UTF_8
					      lossy: lossy];

		@try {
			cString = [object resizeMemory: cString
						  size: cStringLength + 1];
		} @catch (OFOutOfMemoryException *e) {
			/* We don't care, as we only tried to make it smaller */
		}

		break;
	case OF_STRING_ENCODING_ASCII:
	case OF_STRING_ENCODING_ISO_8859_1:
	case OF_STRING_ENCODING_ISO_8859_2:
	case OF_STRING_ENCODING_ISO_8859_3:
	case OF_STRING_ENCODING_ISO_8859_15:
	case OF_STRING_ENCODING_WINDOWS_1251:
	case OF_STRING_ENCODING_WINDOWS_1252:
	case OF_STRING_ENCODING_CODEPAGE_437:
	case OF_STRING_ENCODING_CODEPAGE_850:
	case OF_STRING_ENCODING_CODEPAGE_858:
	case OF_STRING_ENCODING_MAC_ROMAN:
	case OF_STRING_ENCODING_KOI8_R:
	case OF_STRING_ENCODING_KOI8_U:
		cString = [object allocMemoryWithSize: length + 1];

		[self of_getCString: cString
			  maxLength: length + 1
			   encoding: encoding
			      lossy: lossy];

		break;
	default:
		@throw [OFInvalidEncodingException exception];
	}

	return cString;
}

- (const char *)cStringWithEncoding: (of_string_encoding_t)encoding
{
	return [self of_cStringWithEncoding: encoding
				      lossy: false];
}

- (const char *)lossyCStringWithEncoding: (of_string_encoding_t)encoding
{
	return [self of_cStringWithEncoding: encoding
				      lossy: true];
}

- (const char *)UTF8String
{
	return [self cStringWithEncoding: OF_STRING_ENCODING_UTF_8];
}

- (size_t)length
{
	OF_UNRECOGNIZED_SELECTOR
}

- (size_t)cStringLengthWithEncoding: (of_string_encoding_t)encoding
{
	switch (encoding) {
	case OF_STRING_ENCODING_UTF_8:;
		const of_unichar_t *characters;
		size_t length, UTF8StringLength = 0;

		characters = self.characters;
		length = self.length;

		for (size_t i = 0; i < length; i++) {
			char buffer[4];
			size_t len = of_string_utf8_encode(characters[i],
			    buffer);

			if (len == 0)
				@throw [OFInvalidEncodingException exception];

			UTF8StringLength += len;
		}

		return UTF8StringLength;
	case OF_STRING_ENCODING_ASCII:
	case OF_STRING_ENCODING_ISO_8859_1:
	case OF_STRING_ENCODING_ISO_8859_2:
	case OF_STRING_ENCODING_ISO_8859_3:
	case OF_STRING_ENCODING_ISO_8859_15:
	case OF_STRING_ENCODING_WINDOWS_1251:
	case OF_STRING_ENCODING_WINDOWS_1252:
	case OF_STRING_ENCODING_CODEPAGE_437:
	case OF_STRING_ENCODING_CODEPAGE_850:
	case OF_STRING_ENCODING_CODEPAGE_858:
	case OF_STRING_ENCODING_MAC_ROMAN:
	case OF_STRING_ENCODING_KOI8_R:
	case OF_STRING_ENCODING_KOI8_U:
		return self.length;
	default:
		@throw [OFInvalidEncodingException exception];
	}
}

- (size_t)UTF8StringLength
{
	return [self cStringLengthWithEncoding: OF_STRING_ENCODING_UTF_8];
}

- (of_unichar_t)characterAtIndex: (size_t)idx
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)getCharacters: (of_unichar_t *)buffer
	      inRange: (of_range_t)range
{
	for (size_t i = 0; i < range.length; i++)
		buffer[i] = [self characterAtIndex: range.location + i];
}

- (bool)isEqual: (id)object
{
	void *pool;
	OFString *otherString;
	const of_unichar_t *characters, *otherCharacters;
	size_t length;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFString class]])
		return false;

	otherString = object;
	length = self.length;

	if (otherString.length != length)
		return false;

	pool = objc_autoreleasePoolPush();

	characters = self.characters;
	otherCharacters = otherString.characters;

	if (memcmp(characters, otherCharacters,
	    length * sizeof(of_unichar_t)) != 0) {
		objc_autoreleasePoolPop(pool);
		return false;
	}

	objc_autoreleasePoolPop(pool);

	return true;
}

- (id)copy
{
	return [self retain];
}

- (id)mutableCopy
{
	return [[OFMutableString alloc] initWithString: self];
}

- (of_comparison_result_t)compare: (id <OFComparing>)object
{
	void *pool;
	OFString *otherString;
	const of_unichar_t *characters, *otherCharacters;
	size_t minimumLength;

	if (object == self)
		return OF_ORDERED_SAME;

	if (![(id)object isKindOfClass: [OFString class]])
		@throw [OFInvalidArgumentException exception];

	otherString = (OFString *)object;
	minimumLength = (self.length > otherString.length
	    ? otherString.length : self.length);

	pool = objc_autoreleasePoolPush();

	characters = self.characters;
	otherCharacters = otherString.characters;

	for (size_t i = 0; i < minimumLength; i++) {
		if (characters[i] > otherCharacters[i]) {
			objc_autoreleasePoolPop(pool);
			return OF_ORDERED_DESCENDING;
		}

		if (characters[i] < otherCharacters[i]) {
			objc_autoreleasePoolPop(pool);
			return OF_ORDERED_ASCENDING;
		}
	}

	objc_autoreleasePoolPop(pool);

	if (self.length > otherString.length)
		return OF_ORDERED_DESCENDING;
	if (self.length < otherString.length)
		return OF_ORDERED_ASCENDING;

	return OF_ORDERED_SAME;
}

- (of_comparison_result_t)caseInsensitiveCompare: (OFString *)otherString
{
	void *pool = objc_autoreleasePoolPush();
	const of_unichar_t *characters, *otherCharacters;
	size_t length, otherLength, minimumLength;

	if (otherString == self)
		return OF_ORDERED_SAME;

	characters = self.characters;
	otherCharacters = otherString.characters;
	length = self.length;
	otherLength = otherString.length;

	minimumLength = (length > otherLength ? otherLength : length);

	for (size_t i = 0; i < minimumLength; i++) {
		of_unichar_t c = characters[i];
		of_unichar_t oc = otherCharacters[i];

#ifdef OF_HAVE_UNICODE_TABLES
		if (c >> 8 < OF_UNICODE_CASEFOLDING_TABLE_SIZE) {
			of_unichar_t tc =
			    of_unicode_casefolding_table[c >> 8][c & 0xFF];

			if (tc)
				c = tc;
		}
		if (oc >> 8 < OF_UNICODE_CASEFOLDING_TABLE_SIZE) {
			of_unichar_t tc =
			    of_unicode_casefolding_table[oc >> 8][oc & 0xFF];

			if (tc)
				oc = tc;
		}
#else
		c = of_ascii_toupper(c);
		oc = of_ascii_toupper(oc);
#endif

		if (c > oc) {
			objc_autoreleasePoolPop(pool);
			return OF_ORDERED_DESCENDING;
		}
		if (c < oc) {
			objc_autoreleasePoolPop(pool);
			return OF_ORDERED_ASCENDING;
		}
	}

	objc_autoreleasePoolPop(pool);

	if (length > otherLength)
		return OF_ORDERED_DESCENDING;
	if (length < otherLength)
		return OF_ORDERED_ASCENDING;

	return OF_ORDERED_SAME;
}

- (uint32_t)hash
{
	const of_unichar_t *characters = self.characters;
	size_t length = self.length;
	uint32_t hash;

	OF_HASH_INIT(hash);

	for (size_t i = 0; i < length; i++) {
		const of_unichar_t c = characters[i];

		OF_HASH_ADD(hash, (c & 0xFF0000) >> 16);
		OF_HASH_ADD(hash, (c & 0x00FF00) >> 8);
		OF_HASH_ADD(hash, c & 0x0000FF);
	}

	OF_HASH_FINALIZE(hash);

	return hash;
}

- (OFString *)description
{
	return [[self copy] autorelease];
}

- (OFXMLElement *)XMLElementBySerializing
{
	void *pool = objc_autoreleasePoolPush();
	OFXMLElement *element;
	OFString *className;

	if ([self isKindOfClass: [OFMutableString class]])
		className = @"OFMutableString";
	else
		className = @"OFString";

	element = [OFXMLElement elementWithName: className
				      namespace: OF_SERIALIZATION_NS
				    stringValue: self];

	[element retain];

	objc_autoreleasePoolPop(pool);

	return [element autorelease];
}

- (OFString *)JSONRepresentation
{
	return [self of_JSONRepresentationWithOptions: 0
						depth: 0];
}

- (OFString *)JSONRepresentationWithOptions: (int)options
{
	return [self of_JSONRepresentationWithOptions: options
						depth: 0];
}

- (OFString *)of_JSONRepresentationWithOptions: (int)options
					 depth: (size_t)depth
{
	OFMutableString *JSON = [[self mutableCopy] autorelease];

	/* FIXME: This is slow! Write it in pure C! */
	[JSON replaceOccurrencesOfString: @"\\"
			      withString: @"\\\\"];
	[JSON replaceOccurrencesOfString: @"\""
			      withString: @"\\\""];
	[JSON replaceOccurrencesOfString: @"\b"
			      withString: @"\\b"];
	[JSON replaceOccurrencesOfString: @"\f"
			      withString: @"\\f"];
	[JSON replaceOccurrencesOfString: @"\r"
			      withString: @"\\r"];
	[JSON replaceOccurrencesOfString: @"\t"
			      withString: @"\\t"];

	if (options & OF_JSON_REPRESENTATION_JSON5) {
		[JSON replaceOccurrencesOfString: @"\n"
				      withString: @"\\\n"];

		if (options & OF_JSON_REPRESENTATION_IDENTIFIER) {
			const char *cString = self.UTF8String;

			if ((!of_ascii_isalpha(cString[0]) &&
			    cString[0] != '_' && cString[0] != '$') ||
			    strpbrk(cString, " \n\r\t\b\f\\\"'") != NULL) {
				[JSON prependString: @"\""];
				[JSON appendString: @"\""];
			}
		} else {
			[JSON prependString: @"\""];
			[JSON appendString: @"\""];
		}
	} else {
		[JSON replaceOccurrencesOfString: @"\n"
				      withString: @"\\n"];

		[JSON prependString: @"\""];
		[JSON appendString: @"\""];
	}

	[JSON makeImmutable];

	return JSON;
}

- (OFData *)messagePackRepresentation
{
	OFMutableData *data;
	size_t length;

	length = self.UTF8StringLength;

	if (length <= 31) {
		uint8_t tmp = 0xA0 | ((uint8_t)length & 0x1F);

		data = [OFMutableData dataWithItemSize: 1
					      capacity: length + 1];

		[data addItem: &tmp];
	} else if (length <= UINT8_MAX) {
		uint8_t type = 0xD9;
		uint8_t tmp = (uint8_t)length;

		data = [OFMutableData dataWithItemSize: 1
					      capacity: length + 2];

		[data addItem: &type];
		[data addItem: &tmp];
	} else if (length <= UINT16_MAX) {
		uint8_t type = 0xDA;
		uint16_t tmp = OF_BSWAP16_IF_LE((uint16_t)length);

		data = [OFMutableData dataWithItemSize: 1
					      capacity: length + 3];

		[data addItem: &type];
		[data addItems: &tmp
			 count: sizeof(tmp)];
	} else if (length <= UINT32_MAX) {
		uint8_t type = 0xDB;
		uint32_t tmp = OF_BSWAP32_IF_LE((uint32_t)length);

		data = [OFMutableData dataWithItemSize: 1
					      capacity: length + 5];

		[data addItem: &type];
		[data addItems: &tmp
			 count: sizeof(tmp)];
	} else
		@throw [OFOutOfRangeException exception];

	[data addItems: self.UTF8String
		 count: length];

	return data;
}

- (of_range_t)rangeOfString: (OFString *)string
{
	return [self rangeOfString: string
			   options: 0
			     range: of_range(0, self.length)];
}

- (of_range_t)rangeOfString: (OFString *)string
		    options: (int)options
{
	return [self rangeOfString: string
			   options: options
			     range: of_range(0, self.length)];
}

- (of_range_t)rangeOfString: (OFString *)string
		    options: (int)options
		      range: (of_range_t)range
{
	void *pool;
	const of_unichar_t *searchCharacters;
	of_unichar_t *characters;
	size_t searchLength;

	if ((searchLength = string.length) == 0)
		return of_range(0, 0);

	if (searchLength > range.length)
		return of_range(OF_NOT_FOUND, 0);

	if (range.length > SIZE_MAX / sizeof(of_unichar_t))
		@throw [OFOutOfRangeException exception];

	pool = objc_autoreleasePoolPush();

	searchCharacters = string.characters;

	if ((characters = malloc(range.length * sizeof(of_unichar_t))) == NULL)
		@throw [OFOutOfMemoryException exceptionWithRequestedSize:
		    range.length * sizeof(of_unichar_t)];

	@try {
		[self getCharacters: characters
			    inRange: range];

		if (options & OF_STRING_SEARCH_BACKWARDS) {
			for (size_t i = range.length - searchLength;; i--) {
				if (memcmp(characters + i, searchCharacters,
				    searchLength * sizeof(of_unichar_t)) == 0) {
					objc_autoreleasePoolPop(pool);
					return of_range(range.location + i,
					    searchLength);
				}

				/* No match and we're at the last character */
				if (i == 0)
					break;
			}
		} else {
			for (size_t i = 0;
			    i <= range.length - searchLength; i++) {
				if (memcmp(characters + i, searchCharacters,
				    searchLength * sizeof(of_unichar_t)) == 0) {
					objc_autoreleasePoolPop(pool);
					return of_range(range.location + i,
					    searchLength);
				}
			}
		}
	} @finally {
		free(characters);
	}

	objc_autoreleasePoolPop(pool);

	return of_range(OF_NOT_FOUND, 0);
}

- (size_t)indexOfCharacterFromSet: (OFCharacterSet *)characterSet
{
	return [self indexOfCharacterFromSet: characterSet
				     options: 0
				       range: of_range(0, self.length)];
}

- (size_t)indexOfCharacterFromSet: (OFCharacterSet *)characterSet
			  options: (int)options
{
	return [self indexOfCharacterFromSet: characterSet
				     options: options
				       range: of_range(0, self.length)];
}

- (size_t)indexOfCharacterFromSet: (OFCharacterSet *)characterSet
			  options: (int)options
			    range: (of_range_t)range
{
	bool (*characterIsMember)(id, SEL, of_unichar_t) =
	    (bool (*)(id, SEL, of_unichar_t))[characterSet
	    methodForSelector: @selector(characterIsMember:)];
	of_unichar_t *characters;

	if (range.length == 0)
		return OF_NOT_FOUND;

	if (range.length > SIZE_MAX / sizeof(of_unichar_t))
		@throw [OFOutOfRangeException exception];

	if ((characters = malloc(range.length * sizeof(of_unichar_t))) == NULL)
		@throw [OFOutOfMemoryException exceptionWithRequestedSize:
		    range.length * sizeof(of_unichar_t)];

	@try {
		[self getCharacters: characters
			    inRange: range];

		if (options & OF_STRING_SEARCH_BACKWARDS) {
			for (size_t i = range.length - 1;; i--) {
				if (characterIsMember(characterSet,
				    @selector(characterIsMember:),
				    characters[i]))
					return range.location + i;

				/* No match and we're at the last character */
				if (i == 0)
					break;
			}
		} else {
			for (size_t i = 0; i < range.length; i++)
				if (characterIsMember(characterSet,
				    @selector(characterIsMember:),
				    characters[i]))
					return range.location + i;
		}
	} @finally {
		free(characters);
	}

	return OF_NOT_FOUND;
}

- (bool)containsString: (OFString *)string
{
	void *pool;
	const of_unichar_t *characters, *searchCharacters;
	size_t length, searchLength;

	if ((searchLength = string.length) == 0)
		return true;

	if (searchLength > (length = self.length))
		return false;

	pool = objc_autoreleasePoolPush();

	characters = self.characters;
	searchCharacters = string.characters;

	for (size_t i = 0; i <= length - searchLength; i++) {
		if (memcmp(characters + i, searchCharacters,
		    searchLength * sizeof(of_unichar_t)) == 0) {
			objc_autoreleasePoolPop(pool);
			return true;
		}
	}

	objc_autoreleasePoolPop(pool);

	return false;
}

- (OFString *)substringWithRange: (of_range_t)range
{
	void *pool;
	OFString *ret;

	if (range.length > SIZE_MAX - range.location ||
	    range.location + range.length > self.length)
		@throw [OFOutOfRangeException exception];

	pool = objc_autoreleasePoolPush();
	ret = [[OFString alloc]
	    initWithCharacters: self.characters + range.location
			length: range.length];
	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (OFString *)stringByAppendingString: (OFString *)string
{
	OFMutableString *new;

	new = [OFMutableString stringWithString: self];
	[new appendString: string];

	[new makeImmutable];

	return new;
}

- (OFString *)stringByAppendingFormat: (OFConstantString *)format, ...
{
	OFString *ret;
	va_list arguments;

	va_start(arguments, format);
	ret = [self stringByAppendingFormat: format
				  arguments: arguments];
	va_end(arguments);

	return ret;
}

- (OFString *)stringByAppendingFormat: (OFConstantString *)format
			    arguments: (va_list)arguments
{
	OFMutableString *new;

	new = [OFMutableString stringWithString: self];
	[new appendFormat: format
		arguments: arguments];

	[new makeImmutable];

	return new;
}

- (OFString *)stringByPrependingString: (OFString *)string
{
	OFMutableString *new = [[string mutableCopy] autorelease];

	[new appendString: self];

	[new makeImmutable];

	return new;
}

- (OFString *)stringByReplacingOccurrencesOfString: (OFString *)string
					withString: (OFString *)replacement
{
	OFMutableString *new = [[self mutableCopy] autorelease];

	[new replaceOccurrencesOfString: string
			     withString: replacement];

	[new makeImmutable];

	return new;
}

- (OFString *)stringByReplacingOccurrencesOfString: (OFString *)string
					withString: (OFString *)replacement
					   options: (int)options
					     range: (of_range_t)range
{
	OFMutableString *new = [[self mutableCopy] autorelease];

	[new replaceOccurrencesOfString: string
			     withString: replacement
				options: options
				  range: range];

	[new makeImmutable];

	return new;
}

- (OFString *)uppercaseString
{
	OFMutableString *new = [[self mutableCopy] autorelease];

	[new uppercase];

	[new makeImmutable];

	return new;
}

- (OFString *)lowercaseString
{
	OFMutableString *new = [[self mutableCopy] autorelease];

	[new lowercase];

	[new makeImmutable];

	return new;
}

- (OFString *)capitalizedString
{
	OFMutableString *new = [[self mutableCopy] autorelease];

	[new capitalize];

	[new makeImmutable];

	return new;
}

- (OFString *)stringByDeletingLeadingWhitespaces
{
	OFMutableString *new = [[self mutableCopy] autorelease];

	[new deleteLeadingWhitespaces];

	[new makeImmutable];

	return new;
}

- (OFString *)stringByDeletingTrailingWhitespaces
{
	OFMutableString *new = [[self mutableCopy] autorelease];

	[new deleteTrailingWhitespaces];

	[new makeImmutable];

	return new;
}

- (OFString *)stringByDeletingEnclosingWhitespaces
{
	OFMutableString *new = [[self mutableCopy] autorelease];

	[new deleteEnclosingWhitespaces];

	[new makeImmutable];

	return new;
}

- (bool)hasPrefix: (OFString *)prefix
{
	of_unichar_t *tmp;
	size_t prefixLength;
	bool hasPrefix;

	if ((prefixLength = prefix.length) > self.length)
		return false;

	tmp = [self allocMemoryWithSize: sizeof(of_unichar_t)
				  count: prefixLength];
	@try {
		void *pool = objc_autoreleasePoolPush();

		[self getCharacters: tmp
			    inRange: of_range(0, prefixLength)];

		hasPrefix = (memcmp(tmp, prefix.characters,
		    prefixLength * sizeof(of_unichar_t)) == 0);

		objc_autoreleasePoolPop(pool);
	} @finally {
		[self freeMemory: tmp];
	}

	return hasPrefix;
}

- (bool)hasSuffix: (OFString *)suffix
{
	of_unichar_t *tmp;
	const of_unichar_t *suffixCharacters;
	size_t length, suffixLength;
	bool hasSuffix;

	if ((suffixLength = suffix.length) > self.length)
		return false;

	length = self.length;

	tmp = [self allocMemoryWithSize: sizeof(of_unichar_t)
				  count: suffixLength];
	@try {
		void *pool = objc_autoreleasePoolPush();

		[self getCharacters: tmp
			    inRange: of_range(length - suffixLength,
					 suffixLength)];

		suffixCharacters = suffix.characters;
		hasSuffix = (memcmp(tmp, suffixCharacters,
		    suffixLength * sizeof(of_unichar_t)) == 0);

		objc_autoreleasePoolPop(pool);
	} @finally {
		[self freeMemory: tmp];
	}

	return hasSuffix;
}

- (OFArray *)componentsSeparatedByString: (OFString *)delimiter
{
	return [self componentsSeparatedByString: delimiter
					 options: 0];
}

- (OFArray *)componentsSeparatedByString: (OFString *)delimiter
				 options: (int)options
{
	void *pool;
	OFMutableArray *array = [OFMutableArray array];
	const of_unichar_t *characters, *delimiterCharacters;
	bool skipEmpty = (options & OF_STRING_SKIP_EMPTY);
	size_t length = self.length;
	size_t delimiterLength = delimiter.length;
	size_t last;
	OFString *component;

	pool = objc_autoreleasePoolPush();

	characters = self.characters;
	delimiterCharacters = delimiter.characters;

	if (delimiterLength > length) {
		[array addObject: [[self copy] autorelease]];
		[array makeImmutable];

		objc_autoreleasePoolPop(pool);

		return array;
	}

	last = 0;
	for (size_t i = 0; i <= length - delimiterLength; i++) {
		if (memcmp(characters + i, delimiterCharacters,
		    delimiterLength * sizeof(of_unichar_t)) != 0)
			continue;

		component = [self substringWithRange: of_range(last, i - last)];
		if (!skipEmpty || component.length > 0)
			[array addObject: component];

		i += delimiterLength - 1;
		last = i + 1;
	}
	component = [self substringWithRange: of_range(last, length - last)];
	if (!skipEmpty || component.length > 0)
		[array addObject: component];

	[array makeImmutable];

	objc_autoreleasePoolPop(pool);

	return array;
}

- (OFArray *)
    componentsSeparatedByCharactersInSet: (OFCharacterSet *)characterSet
{
	return [self componentsSeparatedByCharactersInSet: characterSet
						  options: 0];
}

- (OFArray *)
   componentsSeparatedByCharactersInSet: (OFCharacterSet *)characterSet
				options: (int)options
{
	OFMutableArray *array = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();
	bool skipEmpty = (options & OF_STRING_SKIP_EMPTY);
	const of_unichar_t *characters = self.characters;
	size_t length = self.length;
	bool (*characterIsMember)(id, SEL, of_unichar_t) =
	    (bool (*)(id, SEL, of_unichar_t))[characterSet
	    methodForSelector: @selector(characterIsMember:)];
	size_t last;

	last = 0;
	for (size_t i = 0; i < length; i++) {
		if (characterIsMember(characterSet,
		    @selector(characterIsMember:), characters[i])) {
			if (!skipEmpty || i != last) {
				OFString *component = [self substringWithRange:
				    of_range(last, i - last)];
				[array addObject: component];
			}

			last = i + 1;
		}
	}
	if (!skipEmpty || length != last) {
		OFString *component = [self substringWithRange:
		    of_range(last, length - last)];
		[array addObject: component];
	}

	[array makeImmutable];

	objc_autoreleasePoolPop(pool);

	return array;
}

- (intmax_t)decimalValue
{
	void *pool = objc_autoreleasePoolPush();
	const of_unichar_t *characters = self.characters;
	size_t i = 0, length = self.length;
	intmax_t value = 0;
	bool expectWhitespace = false;

	while (length > 0 && of_ascii_isspace(*characters)) {
		characters++;
		length--;
	}

	if (length == 0) {
		objc_autoreleasePoolPop(pool);
		return 0;
	}

	if (characters[0] == '-' || characters[0] == '+')
		i++;

	for (; i < length; i++) {
		if (expectWhitespace) {
			if (of_ascii_isspace(characters[i]))
				continue;

			@throw [OFInvalidFormatException exception];
		}

		if (characters[i] >= '0' && characters[i] <= '9') {
			if (INTMAX_MAX / 10 < value ||
			    INTMAX_MAX - value * 10 < characters[i] - '0')
				@throw [OFOutOfRangeException exception];

			value = (value * 10) + (characters[i] - '0');
		} else if (of_ascii_isspace(characters[i]))
			expectWhitespace = true;
		else
			@throw [OFInvalidFormatException exception];
	}

	if (characters[0] == '-')
		value *= -1;

	objc_autoreleasePoolPop(pool);

	return value;
}

- (uintmax_t)hexadecimalValue
{
	void *pool = objc_autoreleasePoolPush();
	const of_unichar_t *characters = self.characters;
	size_t i = 0, length = self.length;
	uintmax_t value = 0;
	bool expectWhitespace = false, foundValue = false;

	while (length > 0 && of_ascii_isspace(*characters)) {
		characters++;
		length--;
	}

	if (length == 0) {
		objc_autoreleasePoolPop(pool);
		return 0;
	}

	if (length >= 2 && characters[0] == '0' && characters[1] == 'x')
		i = 2;
	else if (length >= 1 && (characters[0] == 'x' || characters[0] == '$'))
		i = 1;

	for (; i < length; i++) {
		uintmax_t newValue;

		if (expectWhitespace) {
			if (of_ascii_isspace(characters[i]))
				continue;

			@throw [OFInvalidFormatException exception];
		}

		if (characters[i] >= '0' && characters[i] <= '9') {
			newValue = (value << 4) | (characters[i] - '0');
			foundValue = true;
		} else if (characters[i] >= 'A' && characters[i] <= 'F') {
			newValue = (value << 4) | (characters[i] - 'A' + 10);
			foundValue = true;
		} else if (characters[i] >= 'a' && characters[i] <= 'f') {
			newValue = (value << 4) | (characters[i] - 'a' + 10);
			foundValue = true;
		} else if (characters[i] == 'h' ||
		    of_ascii_isspace(characters[i])) {
			expectWhitespace = true;
			continue;
		} else
			@throw [OFInvalidFormatException exception];

		if (newValue < value)
			@throw [OFOutOfRangeException exception];

		value = newValue;
	}

	if (!foundValue)
		@throw [OFInvalidFormatException exception];

	objc_autoreleasePoolPop(pool);

	return value;
}

- (uintmax_t)octalValue
{
	void *pool = objc_autoreleasePoolPush();
	const of_unichar_t *characters = self.characters;
	size_t i = 0, length = self.length;
	uintmax_t value = 0;
	bool expectWhitespace = false;

	while (length > 0 && of_ascii_isspace(*characters)) {
		characters++;
		length--;
	}

	if (length == 0) {
		objc_autoreleasePoolPop(pool);
		return 0;
	}

	for (; i < length; i++) {
		uintmax_t newValue;

		if (expectWhitespace) {
			if (of_ascii_isspace(characters[i]))
				continue;

			@throw [OFInvalidFormatException exception];
		}

		if (characters[i] >= '0' && characters[i] <= '7')
			newValue = (value << 3) | (characters[i] - '0');
		else if (of_ascii_isspace(characters[i])) {
			expectWhitespace = true;
			continue;
		} else
			@throw [OFInvalidFormatException exception];

		if (newValue < value)
			@throw [OFOutOfRangeException exception];

		value = newValue;
	}

	objc_autoreleasePoolPop(pool);

	return value;
}

- (float)floatValue
{
	void *pool = objc_autoreleasePoolPush();

#if defined(OF_AMIGAOS_M68K) || defined(OF_MORPHOS)
	OFString *stripped = self.stringByDeletingEnclosingWhitespaces;

	if ([stripped caseInsensitiveCompare: @"INF"] == OF_ORDERED_SAME ||
	    [stripped caseInsensitiveCompare: @"INFINITY"] == OF_ORDERED_SAME)
		return INFINITY;
	if ([stripped caseInsensitiveCompare: @"-INF"] == OF_ORDERED_SAME ||
	    [stripped caseInsensitiveCompare: @"-INFINITY"] == OF_ORDERED_SAME)
		return -INFINITY;
#endif

#ifdef HAVE_STRTOF_L
	const char *UTF8String = self.UTF8String;
#else
	/*
	 * If we have no strtof_l, we have no other choice but to replace "."
	 * with the locale's decimal point.
	 */
	OFString *decimalPoint = [OFLocale decimalPoint];
	const char *UTF8String = [self
	    stringByReplacingOccurrencesOfString: @"."
				      withString: decimalPoint].UTF8String;
#endif
	char *endPointer = NULL;
	float value;

	while (of_ascii_isspace(*UTF8String))
		UTF8String++;

#ifdef HAVE_STRTOF_L
	value = strtof_l(UTF8String, &endPointer, cLocale);
#else
	value = strtof(UTF8String, &endPointer);
#endif

	/* Check if there are any invalid chars left */
	if (endPointer != NULL)
		for (; *endPointer != '\0'; endPointer++)
			if (!of_ascii_isspace(*endPointer))
				@throw [OFInvalidFormatException exception];

	objc_autoreleasePoolPop(pool);

	return value;
}

- (double)doubleValue
{
	void *pool = objc_autoreleasePoolPush();

#if defined(OF_AMIGAOS_M68K) || defined(OF_MORPHOS)
	OFString *stripped = self.stringByDeletingEnclosingWhitespaces;

	if ([stripped caseInsensitiveCompare: @"INF"] == OF_ORDERED_SAME ||
	    [stripped caseInsensitiveCompare: @"INFINITY"] == OF_ORDERED_SAME)
		return INFINITY;
	if ([stripped caseInsensitiveCompare: @"-INF"] == OF_ORDERED_SAME ||
	    [stripped caseInsensitiveCompare: @"-INFINITY"] == OF_ORDERED_SAME)
		return -INFINITY;
#endif

#ifdef HAVE_STRTOD_L
	const char *UTF8String = self.UTF8String;
#else
	/*
	 * If we have no strtod_l, we have no other choice but to replace "."
	 * with the locale's decimal point.
	 */
	OFString *decimalPoint = [OFLocale decimalPoint];
	const char *UTF8String = [self
	    stringByReplacingOccurrencesOfString: @"."
				      withString: decimalPoint].UTF8String;
#endif
	char *endPointer = NULL;
	double value;

	while (of_ascii_isspace(*UTF8String))
		UTF8String++;

#ifdef HAVE_STRTOD_L
	value = strtod_l(UTF8String, &endPointer, cLocale);
#else
	value = strtod(UTF8String, &endPointer);
#endif

	/* Check if there are any invalid chars left */
	if (endPointer != NULL)
		for (; *endPointer != '\0'; endPointer++)
			if (!of_ascii_isspace(*endPointer))
				@throw [OFInvalidFormatException exception];

	objc_autoreleasePoolPop(pool);

	return value;
}

- (const of_unichar_t *)characters
{
	OFObject *object = [[[OFObject alloc] init] autorelease];
	size_t length = self.length;
	of_unichar_t *ret;

	ret = [object allocMemoryWithSize: sizeof(of_unichar_t)
				    count: length];
	[self getCharacters: ret
		    inRange: of_range(0, length)];

	return ret;
}

- (const of_char16_t *)UTF16String
{
	return [self UTF16StringWithByteOrder: OF_BYTE_ORDER_NATIVE];
}

- (const of_char16_t *)UTF16StringWithByteOrder: (of_byte_order_t)byteOrder
{
	OFObject *object = [[[OFObject alloc] init] autorelease];
	void *pool = objc_autoreleasePoolPush();
	const of_unichar_t *characters = self.characters;
	size_t length = self.length;
	of_char16_t *ret;
	size_t j;
	bool swap = (byteOrder != OF_BYTE_ORDER_NATIVE);

	/* Allocate memory for the worst case */
	ret = [object allocMemoryWithSize: sizeof(of_char16_t)
				    count: (length + 1) * 2];

	j = 0;
	for (size_t i = 0; i < length; i++) {
		of_unichar_t c = characters[i];

		if (c > 0x10FFFF)
			@throw [OFInvalidEncodingException exception];

		if (swap) {
			if (c > 0xFFFF) {
				c -= 0x10000;
				ret[j++] = OF_BSWAP16(0xD800 | (c >> 10));
				ret[j++] = OF_BSWAP16(0xDC00 | (c & 0x3FF));
			} else
				ret[j++] = OF_BSWAP16(c);
		} else {
			if (c > 0xFFFF) {
				c -= 0x10000;
				ret[j++] = 0xD800 | (c >> 10);
				ret[j++] = 0xDC00 | (c & 0x3FF);
			} else
				ret[j++] = c;
		}
	}
	ret[j] = 0;

	@try {
		ret = [object resizeMemory: ret
				      size: sizeof(of_char16_t)
				     count: j + 1];
	} @catch (OFOutOfMemoryException *e) {
		/* We don't care, as we only tried to make it smaller */
	}

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (size_t)UTF16StringLength
{
	const of_unichar_t *characters = self.characters;
	size_t length, UTF16StringLength;

	length = UTF16StringLength = self.length;

	for (size_t i = 0; i < length; i++)
		if (characters[i] > 0xFFFF)
			UTF16StringLength++;

	return UTF16StringLength;
}

- (const of_char32_t *)UTF32String
{
	return [self UTF32StringWithByteOrder: OF_BYTE_ORDER_NATIVE];
}

- (const of_char32_t *)UTF32StringWithByteOrder: (of_byte_order_t)byteOrder
{
	OFObject *object = [[[OFObject alloc] init] autorelease];
	size_t length = self.length;
	of_char32_t *ret;

	ret = [object allocMemoryWithSize: sizeof(of_char32_t)
				    count: length + 1];
	[self getCharacters: ret
		    inRange: of_range(0, length)];
	ret[length] = 0;

	if (byteOrder != OF_BYTE_ORDER_NATIVE)
		for (size_t i = 0; i < length; i++)
			ret[i] = OF_BSWAP32(ret[i]);

	return ret;
}

- (OFData *)dataWithEncoding: (of_string_encoding_t)encoding
{
	void *pool = objc_autoreleasePoolPush();
	OFData *data =
	    [OFData dataWithItems: [self cStringWithEncoding: encoding]
			    count: [self cStringLengthWithEncoding: encoding]];

	[data retain];

	objc_autoreleasePoolPop(pool);

	return [data autorelease];
}

#ifdef OF_HAVE_UNICODE_TABLES
- (OFString *)decomposedStringWithCanonicalMapping
{
	return decomposedString(self, of_unicode_decomposition_table,
	    OF_UNICODE_DECOMPOSITION_TABLE_SIZE);
}

- (OFString *)decomposedStringWithCompatibilityMapping
{
	return decomposedString(self, of_unicode_decomposition_compat_table,
	    OF_UNICODE_DECOMPOSITION_COMPAT_TABLE_SIZE);
}
#endif

#ifdef OF_HAVE_FILES
- (void)writeToFile: (OFString *)path
{
	[self writeToFile: path
		 encoding: OF_STRING_ENCODING_UTF_8];
}

- (void)writeToFile: (OFString *)path
	   encoding: (of_string_encoding_t)encoding
{
	void *pool = objc_autoreleasePoolPush();
	OFFile *file;

	file = [OFFile fileWithPath: path
			       mode: @"w"];
	[file writeString: self
		 encoding: encoding];

	objc_autoreleasePoolPop(pool);
}
#endif

- (void)writeToURL: (OFURL *)URL
{
	[self writeToURL: URL
		encoding: OF_STRING_ENCODING_UTF_8];
}

- (void)writeToURL: (OFURL *)URL
	  encoding: (of_string_encoding_t)encoding
{
	void *pool = objc_autoreleasePoolPush();
	OFURLHandler *URLHandler;
	OFStream *stream;

	if ((URLHandler = [OFURLHandler handlerForURL: URL]) == nil)
		@throw [OFUnsupportedProtocolException exceptionWithURL: URL];

	stream = [URLHandler openItemAtURL: URL
				      mode: @"w"];
	[stream writeString: self
		   encoding: encoding];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateLinesUsingBlock: (of_string_line_enumeration_block_t)block
{
	void *pool = objc_autoreleasePoolPush();
	const of_unichar_t *characters = self.characters;
	size_t i, last = 0, length = self.length;
	bool stop = false, lastCarriageReturn = false;

	for (i = 0; i < length && !stop; i++) {
		if (lastCarriageReturn && characters[i] == '\n') {
			lastCarriageReturn = false;
			last++;

			continue;
		}

		if (characters[i] == '\n' || characters[i] == '\r') {
			void *pool2 = objc_autoreleasePoolPush();

			block([self substringWithRange:
			    of_range(last, i - last)], &stop);
			last = i + 1;

			objc_autoreleasePoolPop(pool2);
		}

		lastCarriageReturn = (characters[i] == '\r');
	}

	if (!stop)
		block([self substringWithRange: of_range(last, i - last)],
		    &stop);

	objc_autoreleasePoolPop(pool);
}
#endif
@end
