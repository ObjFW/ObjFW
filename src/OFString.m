/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#include <ctype.h>
#include <errno.h>
#include <math.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>

#if defined(HAVE_STRTOF_L) || defined(HAVE_STRTOD_L) || defined(HAVE_USELOCALE)
# include <locale.h>
#endif
#ifdef HAVE_XLOCALE_H
# include <xlocale.h>
#endif

#import "OFString.h"
#import "OFString+Private.h"
#import "OFASPrintF.h"
#import "OFArray.h"
#import "OFCharacterSet.h"
#import "OFData.h"
#import "OFDictionary.h"
#ifdef OF_HAVE_FILES
# import "OFFile.h"
# import "OFFileManager.h"
#endif
#import "OFIRI.h"
#import "OFIRIHandler.h"
#import "OFJSONRepresentationPrivate.h"
#import "OFLocale.h"
#import "OFStream.h"
#import "OFSystemInfo.h"
#import "OFTaggedPointerString.h"
#import "OFUTF8String.h"
#import "OFUTF8String+Private.h"

#import "OFGetItemAttributesFailedException.h"
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"
#import "OFOpenItemFailedException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"
#import "OFUnsupportedProtocolException.h"

#import "unicode.h"

/*
 * It seems strtod is buggy on Win32.
 * However, the MinGW version __strtod seems to be ok.
 */
#ifdef __MINGW32__
# define strtod __strtod
#endif

#ifndef HAVE_STRTOF
# define strtof strtod
#endif

#ifndef INFINITY
# define INFINITY __builtin_inf()
#endif

static struct {
	Class isa;
} placeholder;

#if defined(HAVE_STRTOF_L) || defined(HAVE_STRTOD_L) || defined(HAVE_USELOCALE)
static locale_t cLocale;
#endif

#ifdef OF_OBJFW_RUNTIME
# if UINTPTR_MAX == UINT64_MAX
#  define MAX_TAGGED_POINTER_LENGTH 8
# else
#  define MAX_TAGGED_POINTER_LENGTH 4
# endif
#endif

OF_DIRECT_MEMBERS
@interface OFString () <OFJSONRepresentationPrivate>
- (size_t)of_getCString: (char *)cString
	      maxLength: (size_t)maxLength
	       encoding: (OFStringEncoding)encoding
		  lossy: (bool)lossy
	       insecure: (bool)insecure;
- (const char *)of_cStringWithEncoding: (OFStringEncoding)encoding
				 lossy: (bool)lossy
			      insecure: (bool)insecure;
@end

@interface OFPlaceholderString: OFString
@end

extern bool _OFUnicodeToISO8859_2(const OFUnichar *, unsigned char *,
    size_t, bool, bool);
extern bool _OFUnicodeToISO8859_3(const OFUnichar *, unsigned char *,
    size_t, bool, bool);
extern bool _OFUnicodeToISO8859_15(const OFUnichar *, unsigned char *,
    size_t, bool, bool);
extern bool _OFUnicodeToWindows1250(const OFUnichar *, unsigned char *,
    size_t, bool, bool);
extern bool _OFUnicodeToWindows1251(const OFUnichar *, unsigned char *,
    size_t, bool, bool);
extern bool _OFUnicodeToWindows1252(const OFUnichar *, unsigned char *,
    size_t, bool, bool);
extern bool _OFUnicodeToCodepage437(const OFUnichar *, unsigned char *,
    size_t, bool, bool);
extern bool _OFUnicodeToCodepage850(const OFUnichar *, unsigned char *,
    size_t, bool, bool);
extern bool _OFUnicodeToCodepage852(const OFUnichar *, unsigned char *,
    size_t, bool, bool);
extern bool _OFUnicodeToCodepage858(const OFUnichar *, unsigned char *,
    size_t, bool, bool);
extern bool _OFUnicodeToMacRoman(const OFUnichar *, unsigned char *,
    size_t, bool, bool);
extern bool _OFUnicodeToKOI8R(const OFUnichar *, unsigned char *,
    size_t, bool, bool);
extern bool _OFUnicodeToKOI8U(const OFUnichar *, unsigned char *,
    size_t, bool, bool);

/* References for static linking */
void OF_VISIBILITY_HIDDEN
_references_to_categories_of_OFString(void)
{
	_OFString_CryptographicHashing_reference = 1;
	_OFString_JSONParsing_reference = 1;
#ifdef OF_HAVE_FILES
	_OFString_PathAdditions_reference = 1;
#endif
	_OFString_PercentEncoding_reference = 1;
	_OFString_PropertyListParsing_reference = 1;
	_OFString_XMLEscaping_reference = 1;
	_OFString_XMLUnescaping_reference = 1;
}

void OF_VISIBILITY_HIDDEN
_reference_to_OFConstantString(void)
{
	[OFConstantString class];
}

OFStringEncoding
OFStringEncodingParseName(OFString *string)
{
	void *pool = objc_autoreleasePoolPush();
	OFStringEncoding encoding;

	string = string.lowercaseString;

	if ([string isEqual: @"utf8"] || [string isEqual: @"utf-8"])
		encoding = OFStringEncodingUTF8;
	else if ([string isEqual: @"ascii"] || [string isEqual: @"us-ascii"])
		encoding = OFStringEncodingASCII;
	else if ([string isEqual: @"iso-8859-1"] ||
	    [string isEqual: @"iso_8859-1"])
		encoding = OFStringEncodingISO8859_1;
	else if ([string isEqual: @"iso-8859-2"] ||
	    [string isEqual: @"iso_8859-2"])
		encoding = OFStringEncodingISO8859_2;
	else if ([string isEqual: @"iso-8859-3"] ||
	    [string isEqual: @"iso_8859-3"])
		encoding = OFStringEncodingISO8859_3;
	else if ([string isEqual: @"iso-8859-15"] ||
	    [string isEqual: @"iso_8859-15"])
		encoding = OFStringEncodingISO8859_15;
	else if ([string isEqual: @"windows-1250"] ||
	    [string isEqual: @"cp1250"] || [string isEqual: @"cp-1250"] ||
	    [string isEqual: @"1250"])
		encoding = OFStringEncodingWindows1250;
	else if ([string isEqual: @"windows-1251"] ||
	    [string isEqual: @"cp1251"] || [string isEqual: @"cp-1251"] ||
	    [string isEqual: @"1251"])
		encoding = OFStringEncodingWindows1251;
	else if ([string isEqual: @"windows-1252"] ||
	    [string isEqual: @"cp1252"] || [string isEqual: @"cp-1252"] ||
	    [string isEqual: @"1252"])
		encoding = OFStringEncodingWindows1252;
	else if ([string isEqual: @"cp437"] || [string isEqual: @"cp-437"] ||
	    [string isEqual: @"ibm437"] || [string isEqual: @"437"])
		encoding = OFStringEncodingCodepage437;
	else if ([string isEqual: @"cp850"] || [string isEqual: @"cp-850"] ||
	    [string isEqual: @"ibm850"] || [string isEqual: @"850"])
		encoding = OFStringEncodingCodepage850;
	else if ([string isEqual: @"cp852"] || [string isEqual: @"cp-852"] ||
	    [string isEqual: @"ibm852"] || [string isEqual: @"852"])
		encoding = OFStringEncodingCodepage852;
	else if ([string isEqual: @"cp858"] || [string isEqual: @"cp-858"] ||
	    [string isEqual: @"ibm858"] || [string isEqual: @"858"])
		encoding = OFStringEncodingCodepage858;
	else if ([string isEqual: @"macintosh"] || [string isEqual: @"mac"])
		encoding = OFStringEncodingMacRoman;
	else if ([string isEqual: @"koi8-r"])
		encoding = OFStringEncodingKOI8R;
	else if ([string isEqual: @"koi8-u"])
		encoding = OFStringEncodingKOI8U;
	else
		@throw [OFInvalidArgumentException exception];

	objc_autoreleasePoolPop(pool);

	return encoding;
}

OFString *
OFStringEncodingName(OFStringEncoding encoding)
{
	switch (encoding) {
	case OFStringEncodingUTF8:
		return @"UTF-8";
	case OFStringEncodingASCII:
		return @"ASCII";
	case OFStringEncodingISO8859_1:
		return @"ISO 8859-1";
	case OFStringEncodingISO8859_2:
		return @"ISO 8859-2";
	case OFStringEncodingISO8859_3:
		return @"ISO 8859-3";
	case OFStringEncodingISO8859_15:
		return @"ISO 8859-15";
	case OFStringEncodingWindows1250:
		return @"Windows-1250";
	case OFStringEncodingWindows1251:
		return @"Windows-1251";
	case OFStringEncodingWindows1252:
		return @"Windows-1252";
	case OFStringEncodingCodepage437:
		return @"Codepage 437";
	case OFStringEncodingCodepage850:
		return @"Codepage 850";
	case OFStringEncodingCodepage852:
		return @"Codepage 852";
	case OFStringEncodingCodepage858:
		return @"Codepage 858";
	case OFStringEncodingMacRoman:
		return @"Mac Roman";
	case OFStringEncodingKOI8R:
		return @"KOI8-R";
	case OFStringEncodingKOI8U:
		return @"KOI8-U";
	case OFStringEncodingAutodetect:
		return @"autodetect";
	}

	return nil;
}

size_t
_OFUTF8StringEncode(OFUnichar character, char *buffer)
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
_OFUTF8StringDecode(const char *buffer_, size_t length, OFUnichar *ret)
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
OFUTF16StringLength(const OFChar16 *string)
{
	size_t length = 0;

	while (*string++ != 0)
		length++;

	return length;
}

size_t
OFUTF32StringLength(const OFChar32 *string)
{
	size_t length = 0;

	while (*string++ != 0)
		length++;

	return length;
}

char *
_OFStrDup(const char *string)
{
	size_t length = strlen(string);
	char *copy = (char *)OFAllocMemory(1, length + 1);
	memcpy(copy, string, length + 1);

	return copy;
}

#ifdef OF_OBJFW_RUNTIME
static bool
isASCIIWithoutNull(const char *string, size_t length)
{
	uint8_t combined = 0;
	bool containsNull = false;

	for (size_t i = 0; i < length; i++) {
		combined |= string[i];

		if (string[i] == '\0')
			containsNull = true;
	}

	return !(combined & ~0x7F) && !containsNull;
}
#endif

@implementation OFPlaceholderString
#ifdef __clang__
/* We intentionally don't call into super, so silence the warning. */
# pragma clang diagnostic push
# pragma clang diagnostic ignored "-Wunknown-pragmas"
# pragma clang diagnostic ignored "-Wobjc-designated-initializers"
#endif
- (instancetype)init
{
	return (id)@"";
}

- (instancetype)initWithUTF8String: (const char *)UTF8String
{
	size_t length = strlen(UTF8String);
	OFUTF8String *string;
	void *storage;

	if (length == 0)
		return (id)@"";

#ifdef OF_OBJFW_RUNTIME
	if (length <= MAX_TAGGED_POINTER_LENGTH &&
	    isASCIIWithoutNull(UTF8String, length)) {
		id ret = [OFTaggedPointerString
		    stringWithASCIIString: UTF8String
				   length: length];

		if (ret != nil)
			return ret;
	}
#endif

	string = OFAllocObject([OFUTF8String class], length + 1, 1, &storage);

	return (id)[string of_initWithUTF8String: UTF8String
					  length: length
					 storage: storage];
}

- (instancetype)initWithUTF8String: (const char *)UTF8String
			    length: (size_t)UTF8StringLength
{
	OFUTF8String *string;
	void *storage;

	if (UTF8StringLength == 0)
		return (id)@"";

#ifdef OF_OBJFW_RUNTIME
	if (UTF8StringLength <= MAX_TAGGED_POINTER_LENGTH &&
	    isASCIIWithoutNull(UTF8String, UTF8StringLength)) {
		id ret = [OFTaggedPointerString
		    stringWithASCIIString: UTF8String
				   length: UTF8StringLength];

		if (ret != nil)
			return ret;
	}
#endif

	string = OFAllocObject([OFUTF8String class], UTF8StringLength + 1, 1,
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
		       encoding: (OFStringEncoding)encoding
{
	if (encoding == OFStringEncodingUTF8 ||
	    encoding == OFStringEncodingASCII) {
		size_t length = strlen(cString);
		OFUTF8String *string;
		void *storage;

		if (length == 0)
			return (id)@"";

#ifdef OF_OBJFW_RUNTIME
		if (length <= MAX_TAGGED_POINTER_LENGTH &&
		    isASCIIWithoutNull(cString, length)) {
			id ret = [OFTaggedPointerString
			    stringWithASCIIString: cString
					   length: length];

			if (ret != nil)
				return ret;
		}
#endif

		string = OFAllocObject([OFUTF8String class], length + 1, 1,
		    &storage);

		return (id)[string of_initWithUTF8String: cString
						  length: length
						 storage: storage];
	}

	return (id)[[OFUTF8String alloc] initWithCString: cString
						encoding: encoding];
}

- (instancetype)initWithCString: (const char *)cString
		       encoding: (OFStringEncoding)encoding
			 length: (size_t)cStringLength
{
	if (encoding == OFStringEncodingUTF8 ||
	    encoding == OFStringEncodingASCII) {
		OFUTF8String *string;
		void *storage;

		if (cStringLength == 0)
			return (id)@"";

#ifdef OF_OBJFW_RUNTIME
		if (cStringLength <= MAX_TAGGED_POINTER_LENGTH &&
		    isASCIIWithoutNull(cString, cStringLength)) {
			id ret = [OFTaggedPointerString
			    stringWithASCIIString: cString
					   length: cStringLength];

			if (ret != nil)
				return ret;
		}
#endif

		string = OFAllocObject([OFUTF8String class], cStringLength + 1,
		    1, &storage);

		return (id)[string of_initWithUTF8String: cString
						  length: cStringLength
						 storage: storage];
	}

	return (id)[[OFUTF8String alloc] initWithCString: cString
						encoding: encoding
						  length: cStringLength];
}

- (instancetype)initWithData: (OFData *)data
		    encoding: (OFStringEncoding)encoding
{
	return (id)[[OFUTF8String alloc] initWithData: data
					     encoding: encoding];
}

- (instancetype)initWithString: (OFString *)string
{
	return (id)[[OFUTF8String alloc] initWithString: string];
}

- (instancetype)initWithCharacters: (const OFUnichar *)string
			    length: (size_t)length
{
	if (length == 0)
		return (id)@"";

#ifdef OF_OBJFW_RUNTIME
	if (length <= MAX_TAGGED_POINTER_LENGTH) {
		char buffer[MAX_TAGGED_POINTER_LENGTH];
		bool useTaggedPointer = true;

		for (size_t i = 0; i < length; i++) {
			if (string[i] >= 0x80 || string[i] == 0) {
				useTaggedPointer = false;
				break;
			}

			buffer[i] = (char)string[i];
		}

		if (useTaggedPointer) {
			id ret = [OFTaggedPointerString
			    stringWithASCIIString: buffer
					   length: length];

			if (ret != nil)
				return ret;
		}
	}
#endif

	return (id)[[OFUTF8String alloc] initWithCharacters: string
						     length: length];
}

- (instancetype)initWithUTF16String: (const OFChar16 *)string
{
	return (id)[[OFUTF8String alloc] initWithUTF16String: string];
}

- (instancetype)initWithUTF16String: (const OFChar16 *)string
			     length: (size_t)length
{
	return (id)[[OFUTF8String alloc] initWithUTF16String: string
						      length: length];
}

- (instancetype)initWithUTF16String: (const OFChar16 *)string
			  byteOrder: (OFByteOrder)byteOrder
{
	return (id)[[OFUTF8String alloc] initWithUTF16String: string
						   byteOrder: byteOrder];
}

- (instancetype)initWithUTF16String: (const OFChar16 *)string
			     length: (size_t)length
			  byteOrder: (OFByteOrder)byteOrder
{
	return (id)[[OFUTF8String alloc] initWithUTF16String: string
						      length: length
						   byteOrder: byteOrder];
}

- (instancetype)initWithUTF32String: (const OFChar32 *)string
{
	return (id)[[OFUTF8String alloc] initWithUTF32String: string];
}

- (instancetype)initWithUTF32String: (const OFChar32 *)string
			     length: (size_t)length
{
	return (id)[[OFUTF8String alloc] initWithUTF32String: string
						      length: length];
}

- (instancetype)initWithUTF32String: (const OFChar32 *)string
			  byteOrder: (OFByteOrder)byteOrder
{
	return (id)[[OFUTF8String alloc] initWithUTF32String: string
						   byteOrder: byteOrder];
}

- (instancetype)initWithUTF32String: (const OFChar32 *)string
			     length: (size_t)length
			  byteOrder: (OFByteOrder)byteOrder
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
			      encoding: (OFStringEncoding)encoding
{
	return (id)[[OFUTF8String alloc] initWithContentsOfFile: path
						       encoding: encoding];
}
#endif

- (instancetype)initWithContentsOfIRI: (OFIRI *)IRI
{
	return (id)[[OFUTF8String alloc] initWithContentsOfIRI: IRI];
}

- (instancetype)initWithContentsOfIRI: (OFIRI *)IRI
			     encoding: (OFStringEncoding)encoding
{
	return (id)[[OFUTF8String alloc] initWithContentsOfIRI: IRI
						      encoding: encoding];
}
#ifdef __clang__
# pragma clang diagnostic pop
#endif

OF_SINGLETON_METHODS
@end

@implementation OFString
+ (void)initialize
{
	if (self != [OFString class])
		return;

	object_setClass((id)&placeholder, [OFPlaceholderString class]);

#if defined(HAVE_STRTOF_L) || defined(HAVE_STRTOD_L) || defined(HAVE_USELOCALE)
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
			 encoding: (OFStringEncoding)encoding
{
	return [[[self alloc] initWithCString: cString
				     encoding: encoding] autorelease];
}

+ (instancetype)stringWithCString: (const char *)cString
			 encoding: (OFStringEncoding)encoding
			   length: (size_t)cStringLength
{
	return [[[self alloc] initWithCString: cString
				     encoding: encoding
				       length: cStringLength] autorelease];
}

+ (instancetype)stringWithData: (OFData *)data
		      encoding: (OFStringEncoding)encoding
{
	return [[[self alloc] initWithData: data
				  encoding: encoding] autorelease];
}

+ (instancetype)stringWithString: (OFString *)string
{
	return [[[self alloc] initWithString: string] autorelease];
}

+ (instancetype)stringWithCharacters: (const OFUnichar *)string
			      length: (size_t)length
{
	return [[[self alloc] initWithCharacters: string
					  length: length] autorelease];
}

+ (instancetype)stringWithUTF16String: (const OFChar16 *)string
{
	return [[[self alloc] initWithUTF16String: string] autorelease];
}

+ (instancetype)stringWithUTF16String: (const OFChar16 *)string
			       length: (size_t)length
{
	return [[[self alloc] initWithUTF16String: string
					   length: length] autorelease];
}

+ (instancetype)stringWithUTF16String: (const OFChar16 *)string
			    byteOrder: (OFByteOrder)byteOrder
{
	return [[[self alloc] initWithUTF16String: string
					byteOrder: byteOrder] autorelease];
}

+ (instancetype)stringWithUTF16String: (const OFChar16 *)string
			       length: (size_t)length
			    byteOrder: (OFByteOrder)byteOrder
{
	return [[[self alloc] initWithUTF16String: string
					   length: length
					byteOrder: byteOrder] autorelease];
}

+ (instancetype)stringWithUTF32String: (const OFChar32 *)string
{
	return [[[self alloc] initWithUTF32String: string] autorelease];
}

+ (instancetype)stringWithUTF32String: (const OFChar32 *)string
			       length: (size_t)length
{
	return [[[self alloc] initWithUTF32String: string
					   length: length] autorelease];
}

+ (instancetype)stringWithUTF32String: (const OFChar32 *)string
			    byteOrder: (OFByteOrder)byteOrder
{
	return [[[self alloc] initWithUTF32String: string
					byteOrder: byteOrder] autorelease];
}

+ (instancetype)stringWithUTF32String: (const OFChar32 *)string
			       length: (size_t)length
			    byteOrder: (OFByteOrder)byteOrder
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
				encoding: (OFStringEncoding)encoding
{
	return [[[self alloc] initWithContentsOfFile: path
					    encoding: encoding] autorelease];
}
#endif

+ (instancetype)stringWithContentsOfIRI: (OFIRI *)IRI
{
	return [[[self alloc] initWithContentsOfIRI: IRI] autorelease];
}

+ (instancetype)stringWithContentsOfIRI: (OFIRI *)IRI
			       encoding: (OFStringEncoding)encoding
{
	return [[[self alloc] initWithContentsOfIRI: IRI
					   encoding: encoding] autorelease];
}

- (instancetype)init
{
	if ([self isMemberOfClass: [OFString class]] ||
	    [self isMemberOfClass: [OFMutableString class]]) {
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
			    encoding: OFStringEncodingUTF8
			      length: strlen(UTF8String)];
}

- (instancetype)initWithUTF8String: (const char *)UTF8String
			    length: (size_t)UTF8StringLength
{
	return [self initWithCString: UTF8String
			    encoding: OFStringEncodingUTF8
			      length: UTF8StringLength];
}

- (instancetype)initWithUTF8StringNoCopy: (char *)UTF8String
			    freeWhenDone: (bool)freeWhenDone
{
	id ret = [self initWithUTF8String: UTF8String];

	if (freeWhenDone)
		OFFreeMemory(UTF8String);

	return ret;
}

- (instancetype)initWithUTF8StringNoCopy: (char *)UTF8String
				  length: (size_t)UTF8StringLength
			    freeWhenDone: (bool)freeWhenDone
{
	id ret = [self initWithUTF8String: UTF8String length: UTF8StringLength];

	if (freeWhenDone)
		OFFreeMemory(UTF8String);

	return ret;
}

- (instancetype)initWithCString: (const char *)cString
		       encoding: (OFStringEncoding)encoding
{
	return [self initWithCString: cString
			    encoding: encoding
			      length: strlen(cString)];
}

#ifdef __clang__
/* We intentionally don't call into super, so silence the warning. */
# pragma clang diagnostic push
# pragma clang diagnostic ignored "-Wunknown-pragmas"
# pragma clang diagnostic ignored "-Wobjc-designated-initializers"
#endif
- (instancetype)initWithCString: (const char *)cString
		       encoding: (OFStringEncoding)encoding
			 length: (size_t)cStringLength
{
	OF_INVALID_INIT_METHOD
}
#ifdef __clang__
# pragma clang diagnostic pop
#endif

- (instancetype)initWithData: (OFData *)data
		    encoding: (OFStringEncoding)encoding
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

#ifdef __clang__
/* We intentionally don't call into super, so silence the warning. */
# pragma clang diagnostic push
# pragma clang diagnostic ignored "-Wunknown-pragmas"
# pragma clang diagnostic ignored "-Wobjc-designated-initializers"
#endif
- (instancetype)initWithString: (OFString *)string
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithCharacters: (const OFUnichar *)string
			    length: (size_t)length
{
	OF_INVALID_INIT_METHOD
}
#ifdef __clang__
# pragma clang diagnostic pop
#endif

- (instancetype)initWithUTF16String: (const OFChar16 *)string
{
	return [self initWithUTF16String: string
				  length: OFUTF16StringLength(string)
			       byteOrder: OFByteOrderNative];
}

- (instancetype)initWithUTF16String: (const OFChar16 *)string
			     length: (size_t)length
{
	return [self initWithUTF16String: string
				  length: length
			       byteOrder: OFByteOrderNative];
}

- (instancetype)initWithUTF16String: (const OFChar16 *)string
			  byteOrder: (OFByteOrder)byteOrder
{
	return [self initWithUTF16String: string
				  length: OFUTF16StringLength(string)
			       byteOrder: byteOrder];
}

#ifdef __clang__
/* We intentionally don't call into super, so silence the warning. */
# pragma clang diagnostic push
# pragma clang diagnostic ignored "-Wunknown-pragmas"
# pragma clang diagnostic ignored "-Wobjc-designated-initializers"
#endif
- (instancetype)initWithUTF16String: (const OFChar16 *)string
			     length: (size_t)length
			  byteOrder: (OFByteOrder)byteOrder
{
	OF_INVALID_INIT_METHOD
}
#ifdef __clang__
# pragma clang diagnostic pop
#endif

- (instancetype)initWithUTF32String: (const OFChar32 *)string
{
	return [self initWithUTF32String: string
				  length: OFUTF32StringLength(string)
			       byteOrder: OFByteOrderNative];
}

- (instancetype)initWithUTF32String: (const OFChar32 *)string
			     length: (size_t)length
{
	return [self initWithUTF32String: string
				  length: length
			       byteOrder: OFByteOrderNative];
}

- (instancetype)initWithUTF32String: (const OFChar32 *)string
			  byteOrder: (OFByteOrder)byteOrder
{
	return [self initWithUTF32String: string
				  length: OFUTF32StringLength(string)
			       byteOrder: byteOrder];
}

#ifdef __clang__
/* We intentionally don't call into super, so silence the warning. */
# pragma clang diagnostic push
# pragma clang diagnostic ignored "-Wunknown-pragmas"
# pragma clang diagnostic ignored "-Wobjc-designated-initializers"
#endif
- (instancetype)initWithUTF32String: (const OFChar32 *)string
			     length: (size_t)length
			  byteOrder: (OFByteOrder)byteOrder
{
	OF_INVALID_INIT_METHOD
}
#ifdef __clang__
# pragma clang diagnostic pop
#endif

- (instancetype)initWithFormat: (OFConstantString *)format, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, format);
	ret = [self initWithFormat: format arguments: arguments];
	va_end(arguments);

	return ret;
}

#ifdef __clang__
/* We intentionally don't call into super, so silence the warning. */
# pragma clang diagnostic push
# pragma clang diagnostic ignored "-Wunknown-pragmas"
# pragma clang diagnostic ignored "-Wobjc-designated-initializers"
#endif
- (instancetype)initWithFormat: (OFConstantString *)format
		     arguments: (va_list)arguments
{
	OF_INVALID_INIT_METHOD
}
#ifdef __clang__
# pragma clang diagnostic pop
#endif

#ifdef OF_HAVE_FILES
- (instancetype)initWithContentsOfFile: (OFString *)path
{
	return [self initWithContentsOfFile: path
				   encoding: OFStringEncodingUTF8];
}

- (instancetype)initWithContentsOfFile: (OFString *)path
			      encoding: (OFStringEncoding)encoding
{
	void *pool = objc_autoreleasePoolPush();
	OFIRI *IRI;

	@try {
		IRI = [OFIRI fileIRIWithPath: path isDirectory: false];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	self = [self initWithContentsOfIRI: IRI encoding: encoding];

	objc_autoreleasePoolPop(pool);

	return self;
}
#endif

- (instancetype)initWithContentsOfIRI: (OFIRI *)IRI
{
	return [self initWithContentsOfIRI: IRI
				  encoding: OFStringEncodingAutodetect];
}

- (instancetype)initWithContentsOfIRI: (OFIRI *)IRI
			     encoding: (OFStringEncoding)encoding
{
	void *pool = objc_autoreleasePoolPush();
	OFData *data;

	@try {
		data = [OFData dataWithContentsOfIRI: IRI];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	/* FIXME: Detect encoding where we can. */
	if (encoding == OFStringEncodingAutodetect)
		encoding = OFStringEncodingUTF8;

	self = [self initWithCString: data.items
			    encoding: encoding
			      length: data.count * data.itemSize];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (size_t)of_getCString: (char *)cString
	      maxLength: (size_t)maxLength
	       encoding: (OFStringEncoding)encoding
		  lossy: (bool)lossy
	       insecure: (bool)insecure
{
	const OFUnichar *characters = self.characters;
	size_t i, length = self.length;

	switch (encoding) {
	case OFStringEncodingUTF8:;
		size_t j = 0;

		for (i = 0; i < length; i++) {
			char buffer[4];
			size_t len;

			if OF_UNLIKELY (!insecure && characters[i] == 0)
				@throw [OFInvalidEncodingException exception];

			len = _OFUTF8StringEncode(characters[i], buffer);

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
	case OFStringEncodingASCII:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		for (i = 0; i < length; i++) {
			if OF_UNLIKELY (!insecure && characters[i] == 0)
				@throw [OFInvalidEncodingException exception];

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
	case OFStringEncodingISO8859_1:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		for (i = 0; i < length; i++) {
			if OF_UNLIKELY (!insecure && characters[i] == 0)
				@throw [OFInvalidEncodingException exception];

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
	case OFStringEncodingISO8859_2:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!_OFUnicodeToISO8859_2(characters, (unsigned char *)cString,
		    length, lossy, insecure))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
#endif
#ifdef HAVE_ISO_8859_3
	case OFStringEncodingISO8859_3:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!_OFUnicodeToISO8859_3(characters, (unsigned char *)cString,
		    length, lossy, insecure))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
#endif
#ifdef HAVE_ISO_8859_15
	case OFStringEncodingISO8859_15:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!_OFUnicodeToISO8859_15(characters,
		    (unsigned char *)cString, length, lossy, insecure))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
#endif
#ifdef HAVE_WINDOWS_1250
	case OFStringEncodingWindows1250:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!_OFUnicodeToWindows1250(characters,
		    (unsigned char *)cString, length, lossy, insecure))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
#endif
#ifdef HAVE_WINDOWS_1251
	case OFStringEncodingWindows1251:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!_OFUnicodeToWindows1251(characters,
		    (unsigned char *)cString, length, lossy, insecure))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
#endif
#ifdef HAVE_WINDOWS_1252
	case OFStringEncodingWindows1252:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!_OFUnicodeToWindows1252(characters,
		    (unsigned char *)cString, length, lossy, insecure))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
#endif
#ifdef HAVE_CODEPAGE_437
	case OFStringEncodingCodepage437:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!_OFUnicodeToCodepage437(characters,
		    (unsigned char *)cString, length, lossy, insecure))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
#endif
#ifdef HAVE_CODEPAGE_850
	case OFStringEncodingCodepage850:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!_OFUnicodeToCodepage850(characters,
		    (unsigned char *)cString, length, lossy, insecure))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
#endif
#ifdef HAVE_CODEPAGE_852
	case OFStringEncodingCodepage852:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!_OFUnicodeToCodepage852(characters,
		    (unsigned char *)cString, length, lossy, insecure))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
#endif
#ifdef HAVE_CODEPAGE_858
	case OFStringEncodingCodepage858:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!_OFUnicodeToCodepage858(characters,
		    (unsigned char *)cString, length, lossy, insecure))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
#endif
#ifdef HAVE_MAC_ROMAN
	case OFStringEncodingMacRoman:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!_OFUnicodeToMacRoman(characters, (unsigned char *)cString,
		    length, lossy, insecure))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
#endif
#ifdef HAVE_KOI8_R
	case OFStringEncodingKOI8R:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!_OFUnicodeToKOI8R(characters, (unsigned char *)cString,
		    length, lossy, insecure))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
#endif
#ifdef HAVE_KOI8_U
	case OFStringEncodingKOI8U:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!_OFUnicodeToKOI8U(characters, (unsigned char *)cString,
		    length, lossy, insecure))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
#endif
	default:
		@throw [OFInvalidArgumentException exception];
	}
}

- (size_t)getCString: (char *)cString
	   maxLength: (size_t)maxLength
	    encoding: (OFStringEncoding)encoding
{
	return [self of_getCString: cString
			 maxLength: maxLength
			  encoding: encoding
			     lossy: false
			  insecure: false];
}

- (size_t)getLossyCString: (char *)cString
		maxLength: (size_t)maxLength
		 encoding: (OFStringEncoding)encoding
{
	return [self of_getCString: cString
			 maxLength: maxLength
			  encoding: encoding
			     lossy: true
			  insecure: false];
}

- (const char *)of_cStringWithEncoding: (OFStringEncoding)encoding
				 lossy: (bool)lossy
			      insecure: (bool)insecure
{
	size_t length = self.length;
	char *cString;
	size_t cStringLength;
	const char *ret;

	switch (encoding) {
	case OFStringEncodingUTF8:
		cString = OFAllocMemory((length * 4) + 1, 1);

		@try {
			cStringLength = [self
			    of_getCString: cString
				maxLength: (length * 4) + 1
				 encoding: OFStringEncodingUTF8
				    lossy: lossy
				 insecure: insecure];
		} @catch (id e) {
			OFFreeMemory(cString);
			@throw e;
		}

		@try {
			cString = OFResizeMemory(cString, cStringLength + 1, 1);
		} @catch (OFOutOfMemoryException *e) {
			/* We don't care, as we only tried to make it smaller */
		}

		break;
	case OFStringEncodingASCII:
	case OFStringEncodingISO8859_1:
	case OFStringEncodingISO8859_2:
	case OFStringEncodingISO8859_3:
	case OFStringEncodingISO8859_15:
	case OFStringEncodingWindows1250:
	case OFStringEncodingWindows1251:
	case OFStringEncodingWindows1252:
	case OFStringEncodingCodepage437:
	case OFStringEncodingCodepage850:
	case OFStringEncodingCodepage852:
	case OFStringEncodingCodepage858:
	case OFStringEncodingMacRoman:
	case OFStringEncodingKOI8R:
	case OFStringEncodingKOI8U:
		cString = OFAllocMemory(length + 1, 1);

		@try {
			cStringLength = [self of_getCString: cString
						  maxLength: length + 1
						   encoding: encoding
						      lossy: lossy
						   insecure: insecure];
		} @catch (id e) {
			OFFreeMemory(cString);
			@throw e;
		}

		break;
	default:
		@throw [OFInvalidArgumentException exception];
	}

	@try {
		ret = [[OFData dataWithItemsNoCopy: cString
					     count: cStringLength + 1
				      freeWhenDone: true] items];
	} @catch (id e) {
		OFFreeMemory(cString);
		@throw e;
	}

	return ret;
}

- (const char *)cStringWithEncoding: (OFStringEncoding)encoding
{
	return [self of_cStringWithEncoding: encoding
				      lossy: false
				   insecure: false];
}

- (const char *)lossyCStringWithEncoding: (OFStringEncoding)encoding
{
	return [self of_cStringWithEncoding: encoding
				      lossy: true
				   insecure: false];
}

- (const char *)insecureCStringWithEncoding: (OFStringEncoding)encoding
{
	return [self of_cStringWithEncoding: encoding
				      lossy: false
				   insecure: true];
}

- (const char *)UTF8String
{
	return [self of_cStringWithEncoding: OFStringEncodingUTF8
				      lossy: false
				   insecure: false];
}

- (size_t)length
{
	OF_UNRECOGNIZED_SELECTOR
}

- (size_t)cStringLengthWithEncoding: (OFStringEncoding)encoding
{
	switch (encoding) {
	case OFStringEncodingUTF8:;
		const OFUnichar *characters;
		size_t length, UTF8StringLength = 0;

		characters = self.characters;
		length = self.length;

		for (size_t i = 0; i < length; i++) {
			char buffer[4];
			size_t len;

			if (characters[i] == 0)
				@throw [OFInvalidArgumentException exception];

			len = _OFUTF8StringEncode(characters[i], buffer);
			if (len == 0)
				@throw [OFInvalidEncodingException exception];

			UTF8StringLength += len;
		}

		return UTF8StringLength;
	case OFStringEncodingASCII:
	case OFStringEncodingISO8859_1:
	case OFStringEncodingISO8859_2:
	case OFStringEncodingISO8859_3:
	case OFStringEncodingISO8859_15:
	case OFStringEncodingWindows1250:
	case OFStringEncodingWindows1251:
	case OFStringEncodingWindows1252:
	case OFStringEncodingCodepage437:
	case OFStringEncodingCodepage850:
	case OFStringEncodingCodepage852:
	case OFStringEncodingCodepage858:
	case OFStringEncodingMacRoman:
	case OFStringEncodingKOI8R:
	case OFStringEncodingKOI8U:
		return self.length;
	default:
		@throw [OFInvalidArgumentException exception];
	}
}

- (size_t)UTF8StringLength
{
	return [self cStringLengthWithEncoding: OFStringEncodingUTF8];
}

- (OFUnichar)characterAtIndex: (size_t)idx
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)getCharacters: (OFUnichar *)buffer inRange: (OFRange)range
{
	for (size_t i = 0; i < range.length; i++)
		buffer[i] = [self characterAtIndex: range.location + i];
}

- (bool)isEqual: (id)object
{
	void *pool;
	OFString *string;
	const OFUnichar *characters, *otherCharacters;
	size_t length;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFString class]])
		return false;

	string = object;
	length = self.length;

	if (string.length != length)
		return false;

	pool = objc_autoreleasePoolPush();

	characters = self.characters;
	otherCharacters = string.characters;

	if (memcmp(characters, otherCharacters,
	    length * sizeof(OFUnichar)) != 0) {
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

- (OFComparisonResult)compare: (OFString *)string
{
	void *pool;
	const OFUnichar *characters, *otherCharacters;
	size_t minimumLength;

	if (string == self)
		return OFOrderedSame;

	if (![string isKindOfClass: [OFString class]])
		@throw [OFInvalidArgumentException exception];

	minimumLength = (self.length > string.length
	    ? string.length : self.length);

	pool = objc_autoreleasePoolPush();

	characters = self.characters;
	otherCharacters = string.characters;

	for (size_t i = 0; i < minimumLength; i++) {
		if (characters[i] > otherCharacters[i]) {
			objc_autoreleasePoolPop(pool);
			return OFOrderedDescending;
		}

		if (characters[i] < otherCharacters[i]) {
			objc_autoreleasePoolPop(pool);
			return OFOrderedAscending;
		}
	}

	objc_autoreleasePoolPop(pool);

	if (self.length > string.length)
		return OFOrderedDescending;
	if (self.length < string.length)
		return OFOrderedAscending;

	return OFOrderedSame;
}

- (OFComparisonResult)caseInsensitiveCompare: (OFString *)string
{
	void *pool = objc_autoreleasePoolPush();
	const OFUnichar *characters, *otherCharacters;
	size_t length, otherLength, minimumLength;

	if (string == self)
		return OFOrderedSame;

	characters = self.characters;
	otherCharacters = string.characters;
	length = self.length;
	otherLength = string.length;

	minimumLength = (length > otherLength ? otherLength : length);

	for (size_t i = 0; i < minimumLength; i++) {
		OFUnichar c = characters[i];
		OFUnichar oc = otherCharacters[i];

#ifdef OF_HAVE_UNICODE_TABLES
		if (c >> 8 < _OFUnicodeCaseFoldingTableSize) {
			OFUnichar tc =
			    _OFUnicodeCaseFoldingTable[c >> 8][c & 0xFF];

			if (tc)
				c = tc;
		}
		if (oc >> 8 < _OFUnicodeCaseFoldingTableSize) {
			OFUnichar tc =
			    _OFUnicodeCaseFoldingTable[oc >> 8][oc & 0xFF];

			if (tc)
				oc = tc;
		}
#else
		c = OFASCIIToUpper(c);
		oc = OFASCIIToUpper(oc);
#endif

		if (c > oc) {
			objc_autoreleasePoolPop(pool);
			return OFOrderedDescending;
		}
		if (c < oc) {
			objc_autoreleasePoolPop(pool);
			return OFOrderedAscending;
		}
	}

	objc_autoreleasePoolPop(pool);

	if (length > otherLength)
		return OFOrderedDescending;
	if (length < otherLength)
		return OFOrderedAscending;

	return OFOrderedSame;
}

- (unsigned long)hash
{
	const OFUnichar *characters = self.characters;
	size_t length = self.length;
	unsigned long hash;

	OFHashInit(&hash);

	for (size_t i = 0; i < length; i++) {
		const OFUnichar c = characters[i];

		OFHashAddByte(&hash, (c & 0xFF0000) >> 16);
		OFHashAddByte(&hash, (c & 0x00FF00) >> 8);
		OFHashAddByte(&hash, c & 0x0000FF);
	}

	OFHashFinalize(&hash);

	return hash;
}

- (OFString *)description
{
	return [[self copy] autorelease];
}

- (OFString *)JSONRepresentation
{
	return [self of_JSONRepresentationWithOptions: 0 depth: 0];
}

- (OFString *)JSONRepresentationWithOptions:
    (OFJSONRepresentationOptions)options
{
	return [self of_JSONRepresentationWithOptions: options depth: 0];
}

- (OFString *)
    of_JSONRepresentationWithOptions: (OFJSONRepresentationOptions)options
			       depth: (size_t)depth
{
	OFMutableString *JSON = [[self mutableCopy] autorelease];

	/* FIXME: This is slow! Write it in pure C! */
	[JSON replaceOccurrencesOfString: @"\\" withString: @"\\\\"];
	[JSON replaceOccurrencesOfString: @"\"" withString: @"\\\""];
	[JSON replaceOccurrencesOfString: @"\b" withString: @"\\b"];
	[JSON replaceOccurrencesOfString: @"\f" withString: @"\\f"];
	[JSON replaceOccurrencesOfString: @"\r" withString: @"\\r"];
	[JSON replaceOccurrencesOfString: @"\t" withString: @"\\t"];

	if (options & OFJSONRepresentationOptionJSON5) {
		[JSON replaceOccurrencesOfString: @"\n" withString: @"\\\n"];
		[JSON replaceOccurrencesOfString: @"\0" withString: @"\\0"];

		if (options & OFJSONRepresentationOptionIsIdentifier) {
			const char *cString = JSON.UTF8String;

			if ((!OFASCIIIsAlpha(cString[0]) &&
			    cString[0] != '_' && cString[0] != '$') ||
			    strpbrk(cString, " \n\r\t\b\f\\\"'") != NULL) {
				[JSON insertString: @"\"" atIndex: 0];
				[JSON appendString: @"\""];
			}
		} else {
			[JSON insertString: @"\"" atIndex: 0];
			[JSON appendString: @"\""];
		}
	} else {
		[JSON replaceOccurrencesOfString: @"\n" withString: @"\\n"];
		[JSON replaceOccurrencesOfString: @"\0" withString: @"\\u0000"];

		[JSON insertString: @"\"" atIndex: 0];
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

		data = [OFMutableData dataWithCapacity: length + 1];
		[data addItem: &tmp];
	} else if (length <= UINT8_MAX) {
		uint8_t type = 0xD9;
		uint8_t tmp = (uint8_t)length;

		data = [OFMutableData dataWithCapacity: length + 2];
		[data addItem: &type];
		[data addItem: &tmp];
	} else if (length <= UINT16_MAX) {
		uint8_t type = 0xDA;
		uint16_t tmp = OFToBigEndian16((uint16_t)length);

		data = [OFMutableData dataWithCapacity: length + 3];
		[data addItem: &type];
		[data addItems: &tmp count: sizeof(tmp)];
	} else if (length <= UINT32_MAX) {
		uint8_t type = 0xDB;
		uint32_t tmp = OFToBigEndian32((uint32_t)length);

		data = [OFMutableData dataWithCapacity: length + 5];
		[data addItem: &type];
		[data addItems: &tmp count: sizeof(tmp)];
	} else
		@throw [OFOutOfRangeException exception];

	[data addItems: [self insecureCStringWithEncoding: OFStringEncodingUTF8]
		 count: length];

	return data;
}

- (OFRange)rangeOfString: (OFString *)string
{
	return [self rangeOfString: string
			   options: 0
			     range: OFMakeRange(0, self.length)];
}

- (OFRange)rangeOfString: (OFString *)string
		 options: (OFStringSearchOptions)options
{
	return [self rangeOfString: string
			   options: options
			     range: OFMakeRange(0, self.length)];
}

- (OFRange)rangeOfString: (OFString *)string
		 options: (OFStringSearchOptions)options
		   range: (OFRange)range
{
	void *pool;
	const OFUnichar *searchCharacters;
	OFUnichar *characters;
	size_t searchLength;

	if ((searchLength = string.length) == 0)
		return OFMakeRange(0, 0);

	if (searchLength > range.length)
		return OFMakeRange(OFNotFound, 0);

	if (range.length > SIZE_MAX / sizeof(OFUnichar))
		@throw [OFOutOfRangeException exception];

	pool = objc_autoreleasePoolPush();

	searchCharacters = string.characters;

	characters = OFAllocMemory(range.length, sizeof(OFUnichar));
	@try {
		[self getCharacters: characters inRange: range];

		if (options & OFStringSearchBackwards) {
			for (size_t i = range.length - searchLength;; i--) {
				if (memcmp(characters + i, searchCharacters,
				    searchLength * sizeof(OFUnichar)) == 0) {
					objc_autoreleasePoolPop(pool);
					return OFMakeRange(range.location + i,
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
				    searchLength * sizeof(OFUnichar)) == 0) {
					objc_autoreleasePoolPop(pool);
					return OFMakeRange(range.location + i,
					    searchLength);
				}
			}
		}
	} @finally {
		OFFreeMemory(characters);
	}

	objc_autoreleasePoolPop(pool);

	return OFMakeRange(OFNotFound, 0);
}

- (OFRange)rangeOfCharacterFromSet: (OFCharacterSet *)characterSet
{
	return [self rangeOfCharacterFromSet: characterSet
				     options: 0
				       range: OFMakeRange(0, self.length)];
}

- (OFRange)rangeOfCharacterFromSet: (OFCharacterSet *)characterSet
			   options: (OFStringSearchOptions)options
{
	return [self rangeOfCharacterFromSet: characterSet
				     options: options
				       range: OFMakeRange(0, self.length)];
}

- (OFRange)rangeOfCharacterFromSet: (OFCharacterSet *)characterSet
			   options: (OFStringSearchOptions)options
			     range: (OFRange)range
{
	bool (*characterIsMember)(id, SEL, OFUnichar) =
	    (bool (*)(id, SEL, OFUnichar))[characterSet
	    methodForSelector: @selector(characterIsMember:)];
	OFUnichar *characters;

	if (range.length == 0)
		return OFMakeRange(OFNotFound, 0);

	if (range.length > SIZE_MAX / sizeof(OFUnichar))
		@throw [OFOutOfRangeException exception];

	characters = OFAllocMemory(range.length, sizeof(OFUnichar));
	@try {
		[self getCharacters: characters inRange: range];

		if (options & OFStringSearchBackwards) {
			for (size_t i = range.length - 1;; i--) {
				if (characterIsMember(characterSet,
				    @selector(characterIsMember:),
				    characters[i]))
					return OFMakeRange(
					    range.location + i, 1);

				/* No match and we're at the last character */
				if (i == 0)
					break;
			}
		} else {
			for (size_t i = 0; i < range.length; i++)
				if (characterIsMember(characterSet,
				    @selector(characterIsMember:),
				    characters[i]))
					return OFMakeRange(
					    range.location + i, 1);
		}
	} @finally {
		OFFreeMemory(characters);
	}

	return OFMakeRange(OFNotFound, 0);
}

- (size_t)indexOfCharacterFromSet: (OFCharacterSet *)characterSet
{
	return [self
	    rangeOfCharacterFromSet: characterSet
			    options: 0
			      range: OFMakeRange(0, self.length)].location;
}

- (size_t)indexOfCharacterFromSet: (OFCharacterSet *)characterSet
			  options: (OFStringSearchOptions)options
{
	return [self
	    rangeOfCharacterFromSet: characterSet
			    options: options
			      range: OFMakeRange(0, self.length)].location;
}

- (size_t)indexOfCharacterFromSet: (OFCharacterSet *)characterSet
			  options: (OFStringSearchOptions)options
			    range: (OFRange)range
{
	return [self rangeOfCharacterFromSet: characterSet
				     options: options
				       range: range].location;
}

- (bool)containsString: (OFString *)string
{
	void *pool;
	const OFUnichar *characters, *searchCharacters;
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
		    searchLength * sizeof(OFUnichar)) == 0) {
			objc_autoreleasePoolPop(pool);
			return true;
		}
	}

	objc_autoreleasePoolPop(pool);

	return false;
}

- (OFString *)substringFromIndex: (size_t)idx
{
	return [self substringWithRange: OFMakeRange(idx, self.length - idx)];
}

- (OFString *)substringToIndex: (size_t)idx
{
	return [self substringWithRange: OFMakeRange(0, idx)];
}

- (OFString *)substringWithRange: (OFRange)range
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
	ret = [self stringByAppendingFormat: format arguments: arguments];
	va_end(arguments);

	return ret;
}

- (OFString *)stringByAppendingFormat: (OFConstantString *)format
			    arguments: (va_list)arguments
{
	OFMutableString *new = [OFMutableString stringWithString: self];
	[new appendFormat: format arguments: arguments];
	[new makeImmutable];
	return new;
}

- (OFString *)stringByReplacingOccurrencesOfString: (OFString *)string
					withString: (OFString *)replacement
{
	OFMutableString *new = [[self mutableCopy] autorelease];
	[new replaceOccurrencesOfString: string withString: replacement];
	[new makeImmutable];
	return new;
}

- (OFString *)stringByReplacingOccurrencesOfString: (OFString *)string
					withString: (OFString *)replacement
					   options: (int)options
					     range: (OFRange)range
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
	OFUnichar *tmp;
	size_t prefixLength;
	bool hasPrefix;

	if ((prefixLength = prefix.length) > self.length)
		return false;

	tmp = OFAllocMemory(prefixLength, sizeof(OFUnichar));
	@try {
		void *pool = objc_autoreleasePoolPush();

		[self getCharacters: tmp inRange: OFMakeRange(0, prefixLength)];

		hasPrefix = (memcmp(tmp, prefix.characters,
		    prefixLength * sizeof(OFUnichar)) == 0);

		objc_autoreleasePoolPop(pool);
	} @finally {
		OFFreeMemory(tmp);
	}

	return hasPrefix;
}

- (bool)hasSuffix: (OFString *)suffix
{
	OFUnichar *tmp;
	const OFUnichar *suffixCharacters;
	size_t length, suffixLength;
	bool hasSuffix;

	if ((suffixLength = suffix.length) > self.length)
		return false;

	length = self.length;

	tmp = OFAllocMemory(suffixLength, sizeof(OFUnichar));
	@try {
		void *pool = objc_autoreleasePoolPush();

		[self getCharacters: tmp
			    inRange: OFMakeRange(length - suffixLength,
					 suffixLength)];

		suffixCharacters = suffix.characters;
		hasSuffix = (memcmp(tmp, suffixCharacters,
		    suffixLength * sizeof(OFUnichar)) == 0);

		objc_autoreleasePoolPop(pool);
	} @finally {
		OFFreeMemory(tmp);
	}

	return hasSuffix;
}

- (OFArray *)componentsSeparatedByString: (OFString *)delimiter
{
	return [self componentsSeparatedByString: delimiter options: 0];
}

- (OFArray *)componentsSeparatedByString: (OFString *)delimiter
				 options: (OFStringSeparationOptions)options
{
	void *pool;
	OFMutableArray *array;
	const OFUnichar *characters, *delimiterCharacters;
	bool skipEmpty = (options & OFStringSkipEmptyComponents);
	size_t length = self.length;
	size_t delimiterLength = delimiter.length;
	size_t last;
	OFString *component;

	if (delimiter == nil)
		@throw [OFInvalidArgumentException exception];

	if (delimiter.length == 0)
		return [OFArray arrayWithObject: self];

	array = [OFMutableArray array];
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
		    delimiterLength * sizeof(OFUnichar)) != 0)
			continue;

		component = [self substringWithRange:
		    OFMakeRange(last, i - last)];
		if (!skipEmpty || component.length > 0)
			[array addObject: component];

		i += delimiterLength - 1;
		last = i + 1;
	}
	component = [self substringWithRange: OFMakeRange(last, length - last)];
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
				options: (OFStringSeparationOptions)options
{
	OFMutableArray *array = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();
	bool skipEmpty = (options & OFStringSkipEmptyComponents);
	const OFUnichar *characters = self.characters;
	size_t length = self.length;
	bool (*characterIsMember)(id, SEL, OFUnichar) =
	    (bool (*)(id, SEL, OFUnichar))[characterSet
	    methodForSelector: @selector(characterIsMember:)];
	size_t last;

	last = 0;
	for (size_t i = 0; i < length; i++) {
		if (characterIsMember(characterSet,
		    @selector(characterIsMember:), characters[i])) {
			if (!skipEmpty || i != last) {
				OFString *component = [self substringWithRange:
				    OFMakeRange(last, i - last)];
				[array addObject: component];
			}

			last = i + 1;
		}
	}
	if (!skipEmpty || length != last) {
		OFString *component = [self substringWithRange:
		    OFMakeRange(last, length - last)];
		[array addObject: component];
	}

	[array makeImmutable];

	objc_autoreleasePoolPop(pool);

	return array;
}

static long long
longLongValueWithBase(OFString *self, unsigned char base, long long min,
    long long max)
{
	void *pool = objc_autoreleasePoolPush();
	const char *UTF8String = self.UTF8String;
	bool negative = false;
	unsigned long long value = 0;

	while (OFASCIIIsSpace(*UTF8String))
		UTF8String++;

	switch (*UTF8String) {
	case '-':
		negative = true;
	case '+':
		UTF8String++;
	}

	if (UTF8String[0] == '0') {
		if (UTF8String[1] == 'x') {
			if (base == 0)
				base = 16;

			if (base != 16 || UTF8String[2] == '\0')
				@throw [OFInvalidFormatException exception];

			UTF8String += 2;
		} else {
			if (base == 0)
				base = 8;

			UTF8String++;
		}
	}

	if (base == 0)
		base = 10;

	while (*UTF8String != '\0') {
		unsigned char c = OFASCIIToUpper(*UTF8String++);

		if (c >= '0' && c <= '9')
			c -= '0';
		else if (c >= 'A' && c <= 'Z')
			c -= ('A' - 10);
		else if (OFASCIIIsSpace(c)) {
			while (*UTF8String != '\0')
				if (!OFASCIIIsSpace(*UTF8String++))
					@throw [OFInvalidFormatException
					    exception];

			break;
		} else
			@throw [OFInvalidFormatException exception];

		if (c >= base)
			@throw [OFInvalidFormatException exception];

		if (ULLONG_MAX / base < value ||
		    ULLONG_MAX - (value * base) < c)
			@throw [OFOutOfRangeException exception];

		value = (value * base) + c;
	}

	objc_autoreleasePoolPop(pool);

	if (negative) {
		if (value > -(unsigned long long)min)
			@throw [OFOutOfRangeException exception];

		return (long long)-value;
	} else {
		if (value > (unsigned long long)max)
			@throw [OFOutOfRangeException exception];

		return (long long)value;
	}
}

- (signed char)charValue
{
	return (signed char)longLongValueWithBase(
	    self, 10, SCHAR_MIN, SCHAR_MAX);
}

- (signed char)charValueWithBase: (unsigned char)base
{
	return (signed char)longLongValueWithBase(
	    self, base, SCHAR_MIN, SCHAR_MAX);
}

- (short)shortValue
{
	return (short)longLongValueWithBase(self, 10, SHRT_MIN, SHRT_MAX);
}

- (short)shortValueWithBase: (unsigned char)base
{
	return (short)longLongValueWithBase(self, base, SHRT_MIN, SHRT_MAX);
}

- (int)intValue
{
	return (int)longLongValueWithBase(self, 10, INT_MIN, INT_MAX);
}

- (int)intValueWithBase: (unsigned char)base
{
	return (int)longLongValueWithBase(self, base, INT_MIN, INT_MAX);
}

- (long)longValue
{
	return (long)longLongValueWithBase(self, 10, LONG_MIN, LONG_MAX);
}

- (long)longValueWithBase: (unsigned char)base
{
	return (long)longLongValueWithBase(self, base, LONG_MIN, LONG_MAX);
}

- (long long)longLongValue
{
	return longLongValueWithBase(self, 10, LLONG_MIN, LLONG_MAX);
}

- (long long)longLongValueWithBase: (unsigned char)base
{
	return longLongValueWithBase(self, base, LLONG_MIN, LLONG_MAX);
}

static unsigned long long
unsignedLongLongValueWithBase(OFString *self, unsigned char base,
    unsigned long long max)
{
	void *pool = objc_autoreleasePoolPush();
	const char *UTF8String = self.UTF8String;
	unsigned long long value = 0;

	while (OFASCIIIsSpace(*UTF8String))
		UTF8String++;

	switch (*UTF8String) {
	case '-':
		@throw [OFOutOfRangeException exception];
	case '+':
		UTF8String++;
	}

	if (UTF8String[0] == '0') {
		if (UTF8String[1] == 'x') {
			if (base == 0)
				base = 16;

			if (base != 16 || UTF8String[2] == '\0')
				@throw [OFInvalidFormatException exception];

			UTF8String += 2;
		} else {
			if (base == 0)
				base = 8;

			UTF8String++;
		}
	}

	if (base == 0)
		base = 10;

	while (*UTF8String != '\0') {
		unsigned char c = OFASCIIToUpper(*UTF8String++);

		if (c >= '0' && c <= '9')
			c -= '0';
		else if (c >= 'A' && c <= 'Z')
			c -= ('A' - 10);
		else if (OFASCIIIsSpace(c)) {
			while (*UTF8String != '\0')
				if (!OFASCIIIsSpace(*UTF8String++))
					@throw [OFInvalidFormatException
					    exception];

			break;
		} else
			@throw [OFInvalidFormatException exception];

		if (c >= base)
			@throw [OFInvalidFormatException exception];

		if (max / base < value || max - (value * base) < c)
			@throw [OFOutOfRangeException exception];

		value = (value * base) + c;
	}

	objc_autoreleasePoolPop(pool);

	return value;
}

- (unsigned char)unsignedCharValue
{
	return (unsigned char)unsignedLongLongValueWithBase(
	    self, 10, UCHAR_MAX);
}

- (unsigned char)unsignedCharValueWithBase: (unsigned char)base
{
	return (unsigned char)unsignedLongLongValueWithBase(
	    self, base, UCHAR_MAX);
}

- (unsigned short)unsignedShortValue
{
	return (unsigned short)unsignedLongLongValueWithBase(
	    self, 10, USHRT_MAX);
}

- (unsigned short)unsignedShortValueWithBase: (unsigned char)base
{
	return (unsigned short)unsignedLongLongValueWithBase(
	    self, base, USHRT_MAX);
}

- (unsigned int)unsignedIntValue
{
	return (unsigned int)unsignedLongLongValueWithBase(self, 10, UINT_MAX);
}

- (unsigned int)unsignedIntValueWithBase: (unsigned char)base
{
	return (unsigned int)unsignedLongLongValueWithBase(
	    self, base, UINT_MAX);
}

- (unsigned long)unsignedLongValue
{
	return (unsigned long)unsignedLongLongValueWithBase(
	    self, 10, ULONG_MAX);
}

- (unsigned long)unsignedLongValueWithBase: (unsigned char)base
{
	return (unsigned long)unsignedLongLongValueWithBase(
	    self, base, ULONG_MAX);
}

- (unsigned long long)unsignedLongLongValue
{
	return unsignedLongLongValueWithBase(self, 10, ULLONG_MAX);
}

- (unsigned long long)unsignedLongLongValueWithBase: (unsigned char)base
{
	return unsignedLongLongValueWithBase(self, base, ULLONG_MAX);
}

- (float)floatValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *stripped = self.stringByDeletingEnclosingWhitespaces;

	if ([stripped caseInsensitiveCompare: @"INF"] == OFOrderedSame ||
	    [stripped caseInsensitiveCompare: @"INFINITY"] == OFOrderedSame)
		return INFINITY;
	if ([stripped caseInsensitiveCompare: @"-INF"] == OFOrderedSame ||
	    [stripped caseInsensitiveCompare: @"-INFINITY"] == OFOrderedSame)
		return -INFINITY;
	if ([stripped caseInsensitiveCompare: @"NAN"] == OFOrderedSame)
		return NAN;
	if ([stripped caseInsensitiveCompare: @"-NAN"] == OFOrderedSame)
		return -NAN;

#if defined(HAVE_STRTOF_L) || defined(HAVE_USELOCALE)
	const char *UTF8String = self.UTF8String;
#else
	OFString *decimalSeparator = [OFLocale decimalSeparator];
	const char *UTF8String;

	if ([decimalSeparator isEqual: @"."])
		UTF8String = self.UTF8String;
	else
		/*
		 * If we have no strtof_l, we have no other choice than to
		 * replace the locale's decimal point with something that will
		 * be rejected and replacing "." with the locale's decimal
		 * point.
		 */
		UTF8String = [[self
		    stringByReplacingOccurrencesOfString: decimalSeparator
					      withString: @"!"]
		    stringByReplacingOccurrencesOfString: @"."
					      withString: decimalSeparator]
		    .UTF8String;
#endif
	char *endPtr = NULL;
	float value;

	errno = 0;
#if defined(HAVE_STRTOF_L)
	value = strtof_l(UTF8String, &endPtr, cLocale);
#elif defined(HAVE_USELOCALE)
	locale_t previousLocale = uselocale(cLocale);
	value = strtof(UTF8String, &endPtr);
	uselocale(previousLocale);
#else
	value = strtof(UTF8String, &endPtr);
#endif

	if (value == HUGE_VALF && errno == ERANGE)
		@throw [OFOutOfRangeException exception];

	/* Check if there are any invalid chars left */
	if (endPtr != NULL)
		for (; *endPtr != '\0'; endPtr++)
			/* Use isspace since strtof uses the same. */
			if (!isspace((unsigned char)*endPtr))
				@throw [OFInvalidFormatException exception];

	objc_autoreleasePoolPop(pool);

	return value;
}

- (double)doubleValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *stripped = self.stringByDeletingEnclosingWhitespaces;

	if ([stripped caseInsensitiveCompare: @"INF"] == OFOrderedSame ||
	    [stripped caseInsensitiveCompare: @"INFINITY"] == OFOrderedSame)
		return INFINITY;
	if ([stripped caseInsensitiveCompare: @"-INF"] == OFOrderedSame ||
	    [stripped caseInsensitiveCompare: @"-INFINITY"] == OFOrderedSame)
		return -INFINITY;
	if ([stripped caseInsensitiveCompare: @"NAN"] == OFOrderedSame)
		return NAN;
	if ([stripped caseInsensitiveCompare: @"-NAN"] == OFOrderedSame)
		return -NAN;

#if defined(HAVE_STRTOD_L) || defined(HAVE_USELOCALE)
	const char *UTF8String = self.UTF8String;
#else
	OFString *decimalSeparator = [OFLocale decimalSeparator];
	const char *UTF8String;

	if ([decimalSeparator isEqual: @"."])
		UTF8String = self.UTF8String;
	else
		/*
		 * If we have no strtod_l, we have no other choice than to
		 * replace the locale's decimal point with something that will
		 * be rejected and replacing "." with the locale's decimal
		 * point.
		 */
		UTF8String = [[self
		    stringByReplacingOccurrencesOfString: decimalSeparator
					      withString: @"!"]
		    stringByReplacingOccurrencesOfString: @"."
					      withString: decimalSeparator]
		    .UTF8String;
#endif
	char *endPtr = NULL;
	double value;

	errno = 0;
#if defined(HAVE_STRTOD_L)
	value = strtod_l(UTF8String, &endPtr, cLocale);
#elif defined(HAVE_USELOCALE)
	locale_t previousLocale = uselocale(cLocale);
	value = strtod(UTF8String, &endPtr);
	uselocale(previousLocale);
#else
	value = strtod(UTF8String, &endPtr);
#endif

	if (value == HUGE_VAL && errno == ERANGE)
		@throw [OFOutOfRangeException exception];

	/* Check if there are any invalid chars left */
	if (endPtr != NULL)
		for (; *endPtr != '\0'; endPtr++)
			/* Use isspace since strtod uses the same. */
			if (!isspace((unsigned char)*endPtr))
				@throw [OFInvalidFormatException exception];

	objc_autoreleasePoolPop(pool);

	return value;
}

- (const OFUnichar *)characters
{
	size_t length = self.length;
	OFUnichar *buffer;
	const OFUnichar *ret;

	buffer = OFAllocMemory(length, sizeof(OFUnichar));
	@try {
		[self getCharacters: buffer inRange: OFMakeRange(0, length)];

		ret = [[OFData dataWithItemsNoCopy: buffer
					     count: length
					  itemSize: sizeof(OFUnichar)
				      freeWhenDone: true] items];
	} @catch (id e) {
		OFFreeMemory(buffer);
		@throw e;
	}

	return ret;
}

- (const OFChar16 *)UTF16String
{
	return [self UTF16StringWithByteOrder: OFByteOrderNative];
}

- (const OFChar16 *)UTF16StringWithByteOrder: (OFByteOrder)byteOrder
{
	void *pool = objc_autoreleasePoolPush();
	const OFUnichar *characters = self.characters;
	size_t length = self.length;
	OFChar16 *buffer;
	size_t j;
	bool swap = (byteOrder != OFByteOrderNative);
	const OFChar16 *ret;

	/* Allocate memory for the worst case */
	buffer = OFAllocMemory((length + 1) * 2, sizeof(OFChar16));

	j = 0;
	for (size_t i = 0; i < length; i++) {
		OFUnichar c = characters[i];

		if (c > 0x10FFFF || c == 0) {
			OFFreeMemory(buffer);
			@throw [OFInvalidEncodingException exception];
		}

		if (swap) {
			if (c > 0xFFFF) {
				c -= 0x10000;
				buffer[j++] = OFByteSwap16(0xD800 | (c >> 10));
				buffer[j++] =
				    OFByteSwap16(0xDC00 | (c & 0x3FF));
			} else
				buffer[j++] = OFByteSwap16(c);
		} else {
			if (c > 0xFFFF) {
				c -= 0x10000;
				buffer[j++] = 0xD800 | (c >> 10);
				buffer[j++] = 0xDC00 | (c & 0x3FF);
			} else
				buffer[j++] = c;
		}
	}
	buffer[j] = 0;

	@try {
		buffer = OFResizeMemory(buffer, j + 1, sizeof(OFChar16));
	} @catch (OFOutOfMemoryException *e) {
		/* We don't care, as we only tried to make it smaller */
	}

	objc_autoreleasePoolPop(pool);

	@try {
		ret = [[OFData dataWithItemsNoCopy: buffer
					     count: j + 1
					  itemSize: sizeof(OFChar16)
				      freeWhenDone: true] items];
	} @catch (id e) {
		OFFreeMemory(buffer);
		@throw e;
	}

	return ret;
}

- (size_t)UTF16StringLength
{
	const OFUnichar *characters = self.characters;
	size_t length, UTF16StringLength;

	length = UTF16StringLength = self.length;

	for (size_t i = 0; i < length; i++)
		if (characters[i] > 0xFFFF)
			UTF16StringLength++;

	return UTF16StringLength;
}

- (const OFChar32 *)UTF32String
{
	return [self UTF32StringWithByteOrder: OFByteOrderNative];
}

- (const OFChar32 *)UTF32StringWithByteOrder: (OFByteOrder)byteOrder
{
	size_t length = self.length;
	OFChar32 *buffer;
	const OFChar32 *ret;

	buffer = OFAllocMemory(length + 1, sizeof(OFChar32));
	@try {
		[self getCharacters: buffer inRange: OFMakeRange(0, length)];
		buffer[length] = 0;

		for (size_t i = 0; i < length; i++) {
			if (buffer[i] == 0)
				@throw [OFInvalidEncodingException exception];

			if (byteOrder != OFByteOrderNative)
				buffer[i] = OFByteSwap32(buffer[i]);
		}

		ret = [[OFData dataWithItemsNoCopy: buffer
					     count: length + 1
					  itemSize: sizeof(OFChar32)
				      freeWhenDone: true] items];
	} @catch (id e) {
		OFFreeMemory(buffer);
		@throw e;
	}

	return ret;
}

- (OFData *)dataWithEncoding: (OFStringEncoding)encoding
{
	void *pool = objc_autoreleasePoolPush();
	OFData *data =
	    [OFData dataWithItems: [self cStringWithEncoding: encoding]
			    count: [self cStringLengthWithEncoding: encoding]];

	[data retain];

	objc_autoreleasePoolPop(pool);

	return [data autorelease];
}

#ifdef OF_WINDOWS
- (OFString *)stringByExpandingWindowsEnvironmentStrings
{
	if ([OFSystemInfo isWindowsNT]) {
		wchar_t buffer[512];
		size_t length;

		if ((length = ExpandEnvironmentStringsW(self.UTF16String,
		    buffer, sizeof(buffer))) == 0)
			return self;

		return [OFString stringWithUTF16String: buffer
						length: length - 1];
	} else {
		OFStringEncoding encoding = [OFLocale encoding];
		char buffer[512];
		size_t length;

		if ((length = ExpandEnvironmentStringsA(
		    [self cStringWithEncoding: encoding], buffer,
		    sizeof(buffer))) == 0)
			return self;

		return [OFString stringWithCString: buffer
					  encoding: encoding
					    length: length - 1];
	}
}
#endif

#ifdef OF_HAVE_FILES
- (void)writeToFile: (OFString *)path
{
	[self writeToFile: path encoding: OFStringEncodingUTF8];
}

- (void)writeToFile: (OFString *)path encoding: (OFStringEncoding)encoding
{
	void *pool = objc_autoreleasePoolPush();
	OFFile *file = [OFFile fileWithPath: path mode: @"w"];
	[file writeString: self encoding: encoding];
	objc_autoreleasePoolPop(pool);
}
#endif

- (void)writeToIRI: (OFIRI *)IRI
{
	[self writeToIRI: IRI encoding: OFStringEncodingUTF8];
}

- (void)writeToIRI: (OFIRI *)IRI encoding: (OFStringEncoding)encoding
{
	void *pool = objc_autoreleasePoolPush();
	OFStream *stream;

	stream = [OFIRIHandler openItemAtIRI: IRI mode: @"w"];
	[stream writeString: self encoding: encoding];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateLinesUsingBlock: (OFStringLineEnumerationBlock)block
{
	void *pool = objc_autoreleasePoolPush();
	const OFUnichar *characters = self.characters;
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
			    OFMakeRange(last, i - last)], &stop);
			last = i + 1;

			objc_autoreleasePoolPop(pool2);
		}

		lastCarriageReturn = (characters[i] == '\r');
	}

	if (!stop)
		block([self substringWithRange: OFMakeRange(last, i - last)],
		    &stop);

	objc_autoreleasePoolPop(pool);
}
#endif
@end
