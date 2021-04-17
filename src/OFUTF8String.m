/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#ifdef OF_HAVE_SYS_TYPES_H
# include <sys/types.h>
#endif

#import "OFUTF8String.h"
#import "OFUTF8String+Private.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFMutableUTF8String.h"

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

#import "of_asprintf.h"
#import "unicode.h"

extern const OFChar16 of_iso_8859_2_table[];
extern const size_t of_iso_8859_2_table_offset;
extern const OFChar16 of_iso_8859_3_table[];
extern const size_t of_iso_8859_3_table_offset;
extern const OFChar16 of_iso_8859_15_table[];
extern const size_t of_iso_8859_15_table_offset;
extern const OFChar16 of_windows_1251_table[];
extern const size_t of_windows_1251_table_offset;
extern const OFChar16 of_windows_1252_table[];
extern const size_t of_windows_1252_table_offset;
extern const OFChar16 of_codepage_437_table[];
extern const size_t of_codepage_437_table_offset;
extern const OFChar16 of_codepage_850_table[];
extern const size_t of_codepage_850_table_offset;
extern const OFChar16 of_codepage_858_table[];
extern const size_t of_codepage_858_table_offset;
extern const OFChar16 of_mac_roman_table[];
extern const size_t of_mac_roman_table_offset;
extern const OFChar16 of_koi8_r_table[];
extern const size_t of_koi8_r_table_offset;
extern const OFChar16 of_koi8_u_table[];
extern const size_t of_koi8_u_table_offset;

static inline int
memcasecmp(const char *first, const char *second, size_t length)
{
	for (size_t i = 0; i < length; i++) {
		unsigned char f = first[i];
		unsigned char s = second[i];

		f = of_ascii_toupper(f);
		s = of_ascii_toupper(s);

		if (f > s)
			return OFOrderedDescending;
		if (f < s)
			return OFOrderedAscending;
	}

	return OFOrderedSame;
}

int
of_string_utf8_check(const char *UTF8String, size_t UTF8Length, size_t *length)
{
	size_t tmpLength = UTF8Length;
	int isUTF8 = 0;

	for (size_t i = 0; i < UTF8Length; i++) {
		/* No sign of UTF-8 here */
		if OF_LIKELY (!(UTF8String[i] & 0x80))
			continue;

		isUTF8 = 1;

		/* We're missing a start byte here */
		if OF_UNLIKELY (!(UTF8String[i] & 0x40))
			return -1;

		/* 2 byte sequences for code points 0 - 127 are forbidden */
		if OF_UNLIKELY ((UTF8String[i] & 0x7E) == 0x40)
			return -1;

		/* We have at minimum a 2 byte character -> check next byte */
		if OF_UNLIKELY (UTF8Length <= i + 1 ||
		    (UTF8String[i + 1] & 0xC0) != 0x80)
			return -1;

		/* Check if we have at minimum a 3 byte character */
		if OF_LIKELY (!(UTF8String[i] & 0x20)) {
			i++;
			tmpLength--;
			continue;
		}

		/* We have at minimum a 3 byte char -> check second next byte */
		if OF_UNLIKELY (UTF8Length <= i + 2 ||
		    (UTF8String[i + 2] & 0xC0) != 0x80)
			return -1;

		/* Check if we have a 4 byte character */
		if OF_LIKELY (!(UTF8String[i] & 0x10)) {
			i += 2;
			tmpLength -= 2;
			continue;
		}

		/* We have a 4 byte character -> check third next byte */
		if OF_UNLIKELY (UTF8Length <= i + 3 ||
		    (UTF8String[i + 3] & 0xC0) != 0x80)
			return -1;

		/*
		 * Just in case, check if there's a 5th character, which is
		 * forbidden by UTF-8
		 */
		if OF_UNLIKELY (UTF8String[i] & 0x08)
			return -1;

		i += 3;
		tmpLength -= 3;
	}

	if (length != NULL)
		*length = tmpLength;

	return isUTF8;
}

size_t
of_string_utf8_get_index(const char *string, size_t position)
{
	size_t idx = position;

	for (size_t i = 0; i < position; i++)
		if OF_UNLIKELY ((string[i] & 0xC0) == 0x80)
			idx--;

	return idx;
}

size_t
of_string_utf8_get_position(const char *string, size_t idx, size_t length)
{
	for (size_t i = 0; i <= idx; i++)
		if OF_UNLIKELY ((string[i] & 0xC0) == 0x80)
			if (++idx > length)
				@throw [OFInvalidFormatException exception];

	return idx;
}

@implementation OFUTF8String
- (instancetype)init
{
	self = [super init];

	@try {
		_s = &_storage;

		_s->cString = of_alloc_zeroed(1, 1);
		_s->freeWhenDone = true;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)of_initWithUTF8String: (const char *)UTF8String
			       length: (size_t)UTF8StringLength
			      storage: (char *)storage
{
	self = [super init];

	@try {
		if (UTF8StringLength >= 3 &&
		    memcmp(UTF8String, "\xEF\xBB\xBF", 3) == 0) {
			UTF8String += 3;
			UTF8StringLength -= 3;
		}

		_s = &_storage;

		_s->cString = storage;
		_s->cStringLength = UTF8StringLength;

		switch (of_string_utf8_check(UTF8String, UTF8StringLength,
		    &_s->length)) {
		case 1:
			_s->isUTF8 = true;
			break;
		case -1:
			@throw [OFInvalidEncodingException exception];
		}

		memcpy(_s->cString, UTF8String, UTF8StringLength);
		_s->cString[UTF8StringLength] = 0;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithCString: (const char *)cString
		       encoding: (OFStringEncoding)encoding
			 length: (size_t)cStringLength
{
	self = [super init];

	@try {
		const OFChar16 *table;
		size_t tableOffset, j;

		if (encoding == OFStringEncodingUTF8 &&
		    cStringLength >= 3 &&
		    memcmp(cString, "\xEF\xBB\xBF", 3) == 0) {
			cString += 3;
			cStringLength -= 3;
		}

		_s = &_storage;

		_s->cString = of_alloc(cStringLength + 1, 1);
		_s->cStringLength = cStringLength;
		_s->freeWhenDone = true;

		if (encoding == OFStringEncodingUTF8 ||
		    encoding == OFStringEncodingASCII) {
			switch (of_string_utf8_check(cString, cStringLength,
			    &_s->length)) {
			case 1:
				if (encoding == OFStringEncodingASCII)
					@throw [OFInvalidEncodingException
					    exception];

				_s->isUTF8 = true;
				break;
			case -1:
				@throw [OFInvalidEncodingException exception];
			}

			memcpy(_s->cString, cString, cStringLength);
			_s->cString[cStringLength] = 0;

			return self;
		}

		/* All other encodings we support are single byte encodings */
		_s->length = cStringLength;

		if (encoding == OFStringEncodingISO8859_1) {
			j = 0;
			for (size_t i = 0; i < cStringLength; i++) {
				char buffer[4];
				size_t bytes;

				if (!(cString[i] & 0x80)) {
					_s->cString[j++] = cString[i];
					continue;
				}

				_s->isUTF8 = true;
				bytes = of_string_utf8_encode(
				    (uint8_t)cString[i], buffer);

				if (bytes == 0)
					@throw [OFInvalidEncodingException
					    exception];

				_s->cStringLength += bytes - 1;
				_s->cString = of_realloc(_s->cString,
				    _s->cStringLength + 1, 1);

				memcpy(_s->cString + j, buffer, bytes);
				j += bytes;
			}

			_s->cString[_s->cStringLength] = 0;

			return self;
		}

		switch (encoding) {
#define CASE(encoding, var)				\
		case encoding:				\
			table = var;			\
			tableOffset = var##_offset;	\
			break;
#ifdef HAVE_ISO_8859_2
		CASE(OFStringEncodingISO8859_2, of_iso_8859_2_table)
#endif
#ifdef HAVE_ISO_8859_3
		CASE(OFStringEncodingISO8859_3, of_iso_8859_3_table)
#endif
#ifdef HAVE_ISO_8859_15
		CASE(OFStringEncodingISO8859_15, of_iso_8859_15_table)
#endif
#ifdef HAVE_WINDOWS_1251
		CASE(OFStringEncodingWindows1251, of_windows_1251_table)
#endif
#ifdef HAVE_WINDOWS_1252
		CASE(OFStringEncodingWindows1252, of_windows_1252_table)
#endif
#ifdef HAVE_CODEPAGE_437
		CASE(OFStringEncodingCodepage437, of_codepage_437_table)
#endif
#ifdef HAVE_CODEPAGE_850
		CASE(OFStringEncodingCodepage850, of_codepage_850_table)
#endif
#ifdef HAVE_CODEPAGE_858
		CASE(OFStringEncodingCodepage858, of_codepage_858_table)
#endif
#ifdef HAVE_MAC_ROMAN
		CASE(OFStringEncodingMacRoman, of_mac_roman_table)
#endif
#ifdef HAVE_KOI8_R
		CASE(OFStringEncodingKOI8R, of_koi8_r_table)
#endif
#ifdef HAVE_KOI8_U
		CASE(OFStringEncodingKOI8U, of_koi8_u_table)
#endif
#undef CASE
		default:
			@throw [OFInvalidEncodingException exception];
		}

		j = 0;
		for (size_t i = 0; i < cStringLength; i++) {
			unsigned char character = (unsigned char)cString[i];
			OFUnichar unichar;
			char buffer[4];
			size_t byteLength;

			if (character < tableOffset) {
				_s->cString[j++] = cString[i];
				continue;
			}

			unichar = table[character - tableOffset];

			if (unichar == 0xFFFF)
				@throw [OFInvalidEncodingException exception];

			_s->isUTF8 = true;
			byteLength = of_string_utf8_encode(unichar, buffer);

			if (byteLength == 0)
				@throw [OFInvalidEncodingException exception];

			_s->cStringLength += byteLength - 1;
			_s->cString = of_realloc(_s->cString,
			    _s->cStringLength + 1, 1);

			memcpy(_s->cString + j, buffer, byteLength);
			j += byteLength;
		}

		_s->cString[_s->cStringLength] = 0;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithUTF8StringNoCopy: (char *)UTF8String
			    freeWhenDone: (bool)freeWhenDone
{
	return [self initWithUTF8StringNoCopy: UTF8String
				       length: strlen(UTF8String)
				 freeWhenDone: freeWhenDone];

}

- (instancetype)initWithUTF8StringNoCopy: (char *)UTF8String
				  length: (size_t)UTF8StringLength
			    freeWhenDone: (bool)freeWhenDone
{
	self = [super init];

	@try {
		_s = &_storage;

		if (UTF8StringLength >= 3 &&
		    memcmp(UTF8String, "\xEF\xBB\xBF", 3) == 0) {
			UTF8String += 3;
			UTF8StringLength -= 3;
		}

		switch (of_string_utf8_check(UTF8String, UTF8StringLength,
		    &_s->length)) {
		case 1:
			_s->isUTF8 = true;
			break;
		case -1:
			@throw [OFInvalidEncodingException exception];
		}

		_s->cString = (char *)UTF8String;
		_s->cStringLength = UTF8StringLength;
		_s->freeWhenDone = freeWhenDone;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithString: (OFString *)string
{
	self = [super init];

	@try {
		_s = &_storage;

		_s->cStringLength = string.UTF8StringLength;

		if ([string isKindOfClass: [OFUTF8String class]] ||
		    [string isKindOfClass: [OFMutableUTF8String class]])
			_s->isUTF8 = ((OFUTF8String *)string)->_s->isUTF8;
		else
			_s->isUTF8 = true;

		_s->length = string.length;

		_s->cString = of_alloc(_s->cStringLength + 1, 1);
		memcpy(_s->cString, string.UTF8String, _s->cStringLength + 1);
		_s->freeWhenDone = true;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithCharacters: (const OFUnichar *)characters
			    length: (size_t)length
{
	self = [super init];

	@try {
		size_t j;

		_s = &_storage;

		_s->cString = of_alloc((length * 4) + 1, 1);
		_s->length = length;
		_s->freeWhenDone = true;

		j = 0;
		for (size_t i = 0; i < length; i++) {
			size_t len = of_string_utf8_encode(characters[i],
			    _s->cString + j);

			if (len == 0)
				@throw [OFInvalidEncodingException exception];

			if (len > 1)
				_s->isUTF8 = true;

			j += len;
		}

		_s->cString[j] = '\0';
		_s->cStringLength = j;

		@try {
			_s->cString = of_realloc(_s->cString, j + 1, 1);
		} @catch (OFOutOfMemoryException *e) {
			/* We don't care, as we only tried to make it smaller */
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithUTF16String: (const OFChar16 *)string
			     length: (size_t)length
			  byteOrder: (OFByteOrder)byteOrder
{
	self = [super init];

	@try {
		size_t j;
		bool swap = false;

		if (length > 0 && *string == 0xFEFF) {
			string++;
			length--;
		} else if (length > 0 && *string == 0xFFFE) {
			swap = true;
			string++;
			length--;
		} else if (byteOrder != OFByteOrderNative)
			swap = true;

		_s = &_storage;

		_s->cString = of_alloc((length * 4) + 1, 1);
		_s->length = length;
		_s->freeWhenDone = true;

		j = 0;
		for (size_t i = 0; i < length; i++) {
			OFUnichar character =
			    (swap ? OF_BSWAP16(string[i]) : string[i]);
			size_t len;

			/* Missing high surrogate */
			if ((character & 0xFC00) == 0xDC00)
				@throw [OFInvalidEncodingException exception];

			if ((character & 0xFC00) == 0xD800) {
				OFChar16 nextCharacter;

				if (length <= i + 1)
					@throw [OFInvalidEncodingException
					    exception];

				nextCharacter = (swap
				    ? OF_BSWAP16(string[i + 1])
				    : string[i + 1]);

				if ((nextCharacter & 0xFC00) != 0xDC00)
					@throw [OFInvalidEncodingException
					    exception];

				character = (((character & 0x3FF) << 10) |
				    (nextCharacter & 0x3FF)) + 0x10000;

				i++;
				_s->length--;
			}

			len = of_string_utf8_encode(character, _s->cString + j);

			if (len == 0)
				@throw [OFInvalidEncodingException exception];

			if (len > 1)
				_s->isUTF8 = true;

			j += len;
		}

		_s->cString[j] = '\0';
		_s->cStringLength = j;

		@try {
			_s->cString = of_realloc(_s->cString, j + 1, 1);
		} @catch (OFOutOfMemoryException *e) {
			/* We don't care, as we only tried to make it smaller */
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithUTF32String: (const OFChar32 *)characters
			     length: (size_t)length
			  byteOrder: (OFByteOrder)byteOrder
{
	self = [super init];

	@try {
		size_t j;
		bool swap = false;

		if (length > 0 && *characters == 0xFEFF) {
			characters++;
			length--;
		} else if (length > 0 && *characters == 0xFFFE0000) {
			swap = true;
			characters++;
			length--;
		} else if (byteOrder != OFByteOrderNative)
			swap = true;

		_s = &_storage;

		_s->cString = of_alloc((length * 4) + 1, 1);
		_s->length = length;
		_s->freeWhenDone = true;

		j = 0;
		for (size_t i = 0; i < length; i++) {
			char buffer[4];
			size_t len = of_string_utf8_encode(
			    (swap ? OF_BSWAP32(characters[i]) : characters[i]),
			    buffer);

			switch (len) {
			case 1:
				_s->cString[j++] = buffer[0];
				break;
			case 2:
			case 3:
			case 4:
				_s->isUTF8 = true;

				memcpy(_s->cString + j, buffer, len);
				j += len;

				break;
			default:
				@throw [OFInvalidEncodingException exception];
			}
		}

		_s->cString[j] = '\0';
		_s->cStringLength = j;

		@try {
			_s->cString = of_realloc(_s->cString, j + 1, 1);
		} @catch (OFOutOfMemoryException *e) {
			/* We don't care, as we only tried to make it smaller */
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithFormat: (OFConstantString *)format
		     arguments: (va_list)arguments
{
	self = [super init];

	@try {
		char *tmp;
		int cStringLength;

		if (format == nil)
			@throw [OFInvalidArgumentException exception];

		_s = &_storage;

		if ((cStringLength = of_vasprintf(&tmp, format.UTF8String,
		    arguments)) == -1)
			@throw [OFInvalidFormatException exception];

		_s->cStringLength = cStringLength;

		@try {
			switch (of_string_utf8_check(tmp, cStringLength,
			    &_s->length)) {
			case 1:
				_s->isUTF8 = true;
				break;
			case -1:
				@throw [OFInvalidEncodingException exception];
			}

			_s->cString = of_alloc(cStringLength + 1, 1);
			memcpy(_s->cString, tmp, cStringLength + 1);
			_s->freeWhenDone = true;
		} @finally {
			free(tmp);
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_s != NULL && _s->freeWhenDone)
		free(_s->cString);

	[super dealloc];
}

- (size_t)getCString: (char *)cString
	   maxLength: (size_t)maxLength
	    encoding: (OFStringEncoding)encoding
{
	switch (encoding) {
	case OFStringEncodingASCII:
		if (_s->isUTF8)
			@throw [OFInvalidEncodingException exception];
		/* intentional fall-through */
	case OFStringEncodingUTF8:
		if (_s->cStringLength + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		memcpy(cString, _s->cString, _s->cStringLength + 1);

		return _s->cStringLength;
	default:
		return [super getCString: cString
			       maxLength: maxLength
				encoding: encoding];
	}
}

- (const char *)cStringWithEncoding: (OFStringEncoding)encoding
{
	switch (encoding) {
	case OFStringEncodingASCII:
		if (_s->isUTF8)
			@throw [OFInvalidEncodingException exception];
		/* intentional fall-through */
	case OFStringEncodingUTF8:
		return _s->cString;
	default:
		return [super cStringWithEncoding: encoding];
	}
}

- (const char *)UTF8String
{
	return _s->cString;
}

- (size_t)length
{
	return _s->length;
}

- (size_t)cStringLengthWithEncoding: (OFStringEncoding)encoding
{
	switch (encoding) {
	case OFStringEncodingUTF8:
	case OFStringEncodingASCII:
		return _s->cStringLength;
	default:
		return [super cStringLengthWithEncoding: encoding];
	}
}

- (size_t)UTF8StringLength
{
	return _s->cStringLength;
}

- (bool)isEqual: (id)object
{
	OFUTF8String *string;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFString class]])
		return false;

	string = object;

	if (string.UTF8StringLength != _s->cStringLength ||
	    string.length != _s->length)
		return false;

	if (([string isKindOfClass: [OFUTF8String class]] ||
	    [string isKindOfClass: [OFMutableUTF8String class]]) &&
	    _s->hashed && string->_s->hashed && _s->hash != string->_s->hash)
		return false;

	if (strcmp(_s->cString, string.UTF8String) != 0)
		return false;

	return true;
}

- (OFComparisonResult)compare: (OFString *)string
{
	size_t otherCStringLength, minimumCStringLength;
	int compare;

	if (string == self)
		return OFOrderedSame;

	if (![string isKindOfClass: [OFString class]])
		@throw [OFInvalidArgumentException exception];

	otherCStringLength = string.UTF8StringLength;
	minimumCStringLength = (_s->cStringLength > otherCStringLength
	    ? otherCStringLength : _s->cStringLength);

	if ((compare = memcmp(_s->cString, string.UTF8String,
	    minimumCStringLength)) == 0) {
		if (_s->cStringLength > otherCStringLength)
			return OFOrderedDescending;
		if (_s->cStringLength < otherCStringLength)
			return OFOrderedAscending;
		return OFOrderedSame;
	}

	if (compare > 0)
		return OFOrderedDescending;
	else
		return OFOrderedAscending;
}

- (OFComparisonResult)caseInsensitiveCompare: (OFString *)string
{
	const char *otherCString;
	size_t otherCStringLength, minimumCStringLength;
#ifdef OF_HAVE_UNICODE_TABLES
	size_t i, j;
#endif
	int compare;

	if (string == self)
		return OFOrderedSame;

	otherCString = string.UTF8String;
	otherCStringLength = string.UTF8StringLength;

#ifdef OF_HAVE_UNICODE_TABLES
	if (!_s->isUTF8) {
#endif
		minimumCStringLength = (_s->cStringLength > otherCStringLength
		    ? otherCStringLength : _s->cStringLength);

		if ((compare = memcasecmp(_s->cString, otherCString,
		    minimumCStringLength)) == 0) {
			if (_s->cStringLength > otherCStringLength)
				return OFOrderedDescending;
			if (_s->cStringLength < otherCStringLength)
				return OFOrderedAscending;
			return OFOrderedSame;
		}

		if (compare > 0)
			return OFOrderedDescending;
		else
			return OFOrderedAscending;
#ifdef OF_HAVE_UNICODE_TABLES
	}

	i = j = 0;

	while (i < _s->cStringLength && j < otherCStringLength) {
		OFUnichar c1, c2;
		ssize_t l1, l2;

		l1 = of_string_utf8_decode(_s->cString + i,
		    _s->cStringLength - i, &c1);
		l2 = of_string_utf8_decode(otherCString + j,
		    otherCStringLength - j, &c2);

		if (l1 <= 0 || l2 <= 0 || c1 > 0x10FFFF || c2 > 0x10FFFF)
			@throw [OFInvalidEncodingException exception];

		if (c1 >> 8 < OF_UNICODE_CASEFOLDING_TABLE_SIZE) {
			OFUnichar tc =
			    of_unicode_casefolding_table[c1 >> 8][c1 & 0xFF];

			if (tc)
				c1 = tc;
		}

		if (c2 >> 8 < OF_UNICODE_CASEFOLDING_TABLE_SIZE) {
			OFUnichar tc =
			    of_unicode_casefolding_table[c2 >> 8][c2 & 0xFF];

			if (tc)
				c2 = tc;
		}

		if (c1 > c2)
			return OFOrderedDescending;
		if (c1 < c2)
			return OFOrderedAscending;

		i += l1;
		j += l2;
	}

	if (_s->cStringLength - i > otherCStringLength - j)
		return OFOrderedDescending;
	else if (_s->cStringLength - i < otherCStringLength - j)
		return OFOrderedAscending;
#endif

	return OFOrderedSame;
}

- (unsigned long)hash
{
	uint32_t hash;

	if (_s->hashed)
		return _s->hash;

	OF_HASH_INIT(hash);

	for (size_t i = 0; i < _s->cStringLength; i++) {
		OFUnichar c;
		ssize_t length;

		if ((length = of_string_utf8_decode(_s->cString + i,
		    _s->cStringLength - i, &c)) <= 0)
			@throw [OFInvalidEncodingException exception];

		OF_HASH_ADD(hash, (c & 0xFF0000) >> 16);
		OF_HASH_ADD(hash, (c & 0x00FF00) >> 8);
		OF_HASH_ADD(hash, c & 0x0000FF);

		i += length - 1;
	}

	OF_HASH_FINALIZE(hash);

	_s->hash = hash;
	_s->hashed = true;

	return hash;
}

- (OFUnichar)characterAtIndex: (size_t)idx
{
	OFUnichar character;

	if (idx >= _s->length)
		@throw [OFOutOfRangeException exception];

	if (!_s->isUTF8)
		return _s->cString[idx];

	idx = of_string_utf8_get_position(_s->cString, idx, _s->cStringLength);

	if (of_string_utf8_decode(_s->cString + idx,
	    _s->cStringLength - idx, &character) <= 0)
		@throw [OFInvalidEncodingException exception];

	return character;
}

- (void)getCharacters: (OFUnichar *)buffer inRange: (OFRange)range
{
	/* TODO: Could be slightly optimized */
	void *pool = objc_autoreleasePoolPush();
	const OFUnichar *characters = self.characters;

	if (range.length > SIZE_MAX - range.location ||
	    range.location + range.length > _s->length)
		@throw [OFOutOfRangeException exception];

	memcpy(buffer, characters + range.location,
	    range.length * sizeof(OFUnichar));

	objc_autoreleasePoolPop(pool);
}

- (OFRange)rangeOfString: (OFString *)string
		 options: (OFStringSearchOptions)options
		   range: (OFRange)range
{
	const char *cString = string.UTF8String;
	size_t cStringLength = string.UTF8StringLength;
	size_t rangeLocation, rangeLength;

	if (range.length > SIZE_MAX - range.location ||
	    range.location + range.length > _s->length)
		@throw [OFOutOfRangeException exception];

	if (_s->isUTF8) {
		rangeLocation = of_string_utf8_get_position(
		    _s->cString, range.location, _s->cStringLength);
		rangeLength = of_string_utf8_get_position(
		    _s->cString + rangeLocation, range.length,
		    _s->cStringLength - rangeLocation);
	} else {
		rangeLocation = range.location;
		rangeLength = range.length;
	}

	if (cStringLength == 0)
		return OFMakeRange(0, 0);

	if (cStringLength > rangeLength)
		return OFMakeRange(OFNotFound, 0);

	if (options & OFStringSearchBackwards) {
		for (size_t i = rangeLength - cStringLength;; i--) {
			if (memcmp(_s->cString + rangeLocation + i, cString,
			    cStringLength) == 0) {
				range.location += of_string_utf8_get_index(
				    _s->cString + rangeLocation, i);
				range.length = string.length;

				return range;
			}

			/* Did not match and we're at the last char */
			if (i == 0)
				return OFMakeRange(OFNotFound, 0);
		}
	} else {
		for (size_t i = 0; i <= rangeLength - cStringLength; i++) {
			if (memcmp(_s->cString + rangeLocation + i, cString,
			    cStringLength) == 0) {
				range.location += of_string_utf8_get_index(
				    _s->cString + rangeLocation, i);
				range.length = string.length;

				return range;
			}
		}
	}

	return OFMakeRange(OFNotFound, 0);
}

- (bool)containsString: (OFString *)string
{
	const char *cString = string.UTF8String;
	size_t cStringLength = string.UTF8StringLength;

	if (cStringLength == 0)
		return true;

	if (cStringLength > _s->cStringLength)
		return false;

	for (size_t i = 0; i <= _s->cStringLength - cStringLength; i++)
		if (memcmp(_s->cString + i, cString, cStringLength) == 0)
			return true;

	return false;
}

- (OFString *)substringWithRange: (OFRange)range
{
	size_t start = range.location;
	size_t end = range.location + range.length;

	if (range.length > SIZE_MAX - range.location || end > _s->length)
		@throw [OFOutOfRangeException exception];

	if (_s->isUTF8) {
		start = of_string_utf8_get_position(_s->cString, start,
		    _s->cStringLength);
		end = of_string_utf8_get_position(_s->cString, end,
		    _s->cStringLength);
	}

	return [OFString stringWithUTF8String: _s->cString + start
				       length: end - start];
}

- (bool)hasPrefix: (OFString *)prefix
{
	size_t cStringLength = prefix.UTF8StringLength;

	if (cStringLength > _s->cStringLength)
		return false;

	return (memcmp(_s->cString, prefix.UTF8String, cStringLength) == 0);
}

- (bool)hasSuffix: (OFString *)suffix
{
	size_t cStringLength = suffix.UTF8StringLength;

	if (cStringLength > _s->cStringLength)
		return false;

	return (memcmp(_s->cString + (_s->cStringLength - cStringLength),
	    suffix.UTF8String, cStringLength) == 0);
}

- (OFArray *)componentsSeparatedByString: (OFString *)delimiter
				 options: (OFStringSeparationOptions)options
{
	void *pool;
	OFMutableArray *array;
	const char *cString;
	size_t cStringLength;
	bool skipEmpty = (options & OFStringSkipEmptyComponents);
	size_t last;
	OFString *component;

	if (delimiter == nil)
		@throw [OFInvalidArgumentException exception];

	if (delimiter.length == 0)
		return [OFArray arrayWithObject: self];

	array = [OFMutableArray array];
	pool = objc_autoreleasePoolPush();
	cString = delimiter.UTF8String;
	cStringLength = delimiter.UTF8StringLength;

	if (cStringLength > _s->cStringLength) {
		[array addObject: [[self copy] autorelease]];
		objc_autoreleasePoolPop(pool);

		return array;
	}

	last = 0;
	for (size_t i = 0; i <= _s->cStringLength - cStringLength; i++) {
		if (memcmp(_s->cString + i, cString, cStringLength) != 0)
			continue;

		component = [OFString stringWithUTF8String: _s->cString + last
						    length: i - last];
		if (!skipEmpty || component.length > 0)
			[array addObject: component];

		i += cStringLength - 1;
		last = i + 1;
	}
	component = [OFString stringWithUTF8String: _s->cString + last];
	if (!skipEmpty || component.length > 0)
		[array addObject: component];

	[array makeImmutable];

	objc_autoreleasePoolPop(pool);

	return array;
}

- (const OFUnichar *)characters
{
	OFUnichar *buffer = of_alloc(_s->length, sizeof(OFUnichar));
	size_t i = 0, j = 0;

	while (i < _s->cStringLength) {
		OFUnichar c;
		ssize_t cLen;

		cLen = of_string_utf8_decode(_s->cString + i,
		    _s->cStringLength - i, &c);

		if (cLen <= 0 || c > 0x10FFFF) {
			free(buffer);
			@throw [OFInvalidEncodingException exception];
		}

		buffer[j++] = c;
		i += cLen;
	}

	return [[OFData dataWithItemsNoCopy: buffer
				      count: _s->length
				   itemSize: sizeof(OFUnichar)
			       freeWhenDone: true] items];
}

- (const OFChar32 *)UTF32StringWithByteOrder: (OFByteOrder)byteOrder
{
	OFChar32 *buffer = of_alloc(_s->length + 1, sizeof(OFChar32));
	size_t i = 0, j = 0;

	while (i < _s->cStringLength) {
		OFChar32 c;
		ssize_t cLen;

		cLen = of_string_utf8_decode(_s->cString + i,
		    _s->cStringLength - i, &c);

		if (cLen <= 0 || c > 0x10FFFF) {
			free(buffer);
			@throw [OFInvalidEncodingException exception];
		}

		if (byteOrder != OFByteOrderNative)
			buffer[j++] = OF_BSWAP32(c);
		else
			buffer[j++] = c;

		i += cLen;
	}
	buffer[j] = 0;

	return [[OFData dataWithItemsNoCopy: buffer
				      count: _s->length + 1
				   itemSize: sizeof(OFChar32)
			       freeWhenDone: true] items];
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateLinesUsingBlock: (of_string_line_enumeration_block_t)block
{
	void *pool;
	const char *cString = _s->cString;
	const char *last = cString;
	bool stop = false, lastCarriageReturn = false;

	while (!stop && *cString != 0) {
		if (lastCarriageReturn && *cString == '\n') {
			lastCarriageReturn = false;

			cString++;
			last++;

			continue;
		}

		if (*cString == '\n' || *cString == '\r') {
			pool = objc_autoreleasePoolPush();

			block([OFString stringWithUTF8String: last
						      length: cString - last],
			    &stop);
			last = cString + 1;

			objc_autoreleasePoolPop(pool);
		}

		lastCarriageReturn = (*cString == '\r');
		cString++;
	}

	pool = objc_autoreleasePoolPush();

	if (!stop)
		block([OFString stringWithUTF8String: last
					      length: cString - last], &stop);

	objc_autoreleasePoolPop(pool);
}
#endif
@end
