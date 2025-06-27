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

#include <stdarg.h>
#include <stdlib.h>
#include <string.h>

#ifdef OF_HAVE_SYS_TYPES_H
# include <sys/types.h>
#endif

#import "OFUTF8String.h"
#import "OFUTF8String+Private.h"
#import "OFASPrintF.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFMutableUTF8String.h"
#import "OFString.h"
#import "OFString+Private.h"

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

#import "unicode.h"

extern const OFChar16 _OFISO8859_2Table[];
extern const size_t _OFISO8859_2TableOffset;
extern const OFChar16 _OFISO8859_3Table[];
extern const size_t _OFISO8859_3TableOffset;
extern const OFChar16 _OFISO8859_15Table[];
extern const size_t _OFISO8859_15TableOffset;
extern const OFChar16 _OFWindows1250Table[];
extern const size_t _OFWindows1250TableOffset;
extern const OFChar16 _OFWindows1251Table[];
extern const size_t _OFWindows1251TableOffset;
extern const OFChar16 _OFWindows1252Table[];
extern const size_t _OFWindows1252TableOffset;
extern const OFChar16 _OFCodepage437Table[];
extern const size_t _OFCodepage437TableOffset;
extern const OFChar16 _OFCodepage850Table[];
extern const size_t _OFCodepage850TableOffset;
extern const OFChar16 _OFCodepage852Table[];
extern const size_t _OFCodepage852TableOffset;
extern const OFChar16 _OFCodepage858Table[];
extern const size_t _OFCodepage858TableOffset;
extern const OFChar16 _OFMacRomanTable[];
extern const size_t _OFMacRomanTableOffset;
extern const OFChar16 _OFKOI8RTable[];
extern const size_t _OFKOI8RTableOffset;
extern const OFChar16 _OFKOI8UTable[];
extern const size_t _OFKOI8UTableOffset;

static inline int
memcasecmp(const char *first, const char *second, size_t length)
{
	for (size_t i = 0; i < length; i++) {
		unsigned char f = first[i];
		unsigned char s = second[i];

		f = OFASCIIToUpper(f);
		s = OFASCIIToUpper(s);

		if (f > s)
			return OFOrderedDescending;
		if (f < s)
			return OFOrderedAscending;
	}

	return OFOrderedSame;
}

int
_OFUTF8StringCheck(const char *UTF8String, size_t UTF8Length, size_t *length,
    bool *containsNull)
{
	size_t tmpLength = UTF8Length;
	int isUTF8 = 0;
	bool tmpContainsNull = false;

	for (size_t i = 0; i < UTF8Length; i++) {
		if OF_UNLIKELY (UTF8String[i] == '\0')
			tmpContainsNull = true;

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

	if (containsNull != NULL)
		*containsNull = tmpContainsNull;

	return isUTF8;
}

static size_t
positionToIndex(const char *string, size_t position)
{
	size_t idx = position;

	for (size_t i = 0; i < position; i++)
		if OF_UNLIKELY ((string[i] & 0xC0) == 0x80)
			idx--;

	return idx;
}

size_t
_OFUTF8StringIndexToPosition(const char *string, size_t idx, size_t length)
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

		_s->cString = OFAllocZeroedMemory(1, 1);
		_s->freeWhenDone = true;
	} @catch (id e) {
		objc_release(self);
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
		bool containsNull;

		if (UTF8StringLength >= 3 &&
		    memcmp(UTF8String, "\xEF\xBB\xBF", 3) == 0) {
			UTF8String += 3;
			UTF8StringLength -= 3;
		}

		_s = &_storage;

		_s->cString = storage;
		_s->cStringLength = UTF8StringLength;

		switch (_OFUTF8StringCheck(UTF8String, UTF8StringLength,
		    &_s->length, &containsNull)) {
		case 1:
			_s->isUTF8 = true;
			break;
		case -1:
			@throw [OFInvalidEncodingException exception];
		}

		memcpy(_s->cString, UTF8String, UTF8StringLength);
		_s->cString[UTF8StringLength] = 0;

		_s->containsNull = containsNull;
	} @catch (id e) {
		objc_release(self);
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

		_s->cString = OFAllocMemory(cStringLength + 1, 1);
		_s->cStringLength = cStringLength;
		_s->freeWhenDone = true;

		if (encoding == OFStringEncodingUTF8 ||
		    encoding == OFStringEncodingASCII) {
			bool containsNull;

			switch (_OFUTF8StringCheck(cString, cStringLength,
			    &_s->length, &containsNull)) {
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

			_s->containsNull = containsNull;

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

				if OF_UNLIKELY (cString[i] == '\0')
					_s->containsNull = true;

				bytes = _OFUTF8StringEncode(
				    (uint8_t)cString[i], buffer);
				if (bytes == 0)
					@throw [OFInvalidEncodingException
					    exception];

				_s->cStringLength += bytes - 1;
				_s->cString = OFResizeMemory(_s->cString,
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
			tableOffset = var##Offset;	\
			break;
#ifdef HAVE_ISO_8859_2
		CASE(OFStringEncodingISO8859_2, _OFISO8859_2Table)
#endif
#ifdef HAVE_ISO_8859_3
		CASE(OFStringEncodingISO8859_3, _OFISO8859_3Table)
#endif
#ifdef HAVE_ISO_8859_15
		CASE(OFStringEncodingISO8859_15, _OFISO8859_15Table)
#endif
#ifdef HAVE_WINDOWS_1250
		CASE(OFStringEncodingWindows1250, _OFWindows1250Table)
#endif
#ifdef HAVE_WINDOWS_1251
		CASE(OFStringEncodingWindows1251, _OFWindows1251Table)
#endif
#ifdef HAVE_WINDOWS_1252
		CASE(OFStringEncodingWindows1252, _OFWindows1252Table)
#endif
#ifdef HAVE_CODEPAGE_437
		CASE(OFStringEncodingCodepage437, _OFCodepage437Table)
#endif
#ifdef HAVE_CODEPAGE_850
		CASE(OFStringEncodingCodepage850, _OFCodepage850Table)
#endif
#ifdef HAVE_CODEPAGE_852
		CASE(OFStringEncodingCodepage852, _OFCodepage852Table)
#endif
#ifdef HAVE_CODEPAGE_858
		CASE(OFStringEncodingCodepage858, _OFCodepage858Table)
#endif
#ifdef HAVE_MAC_ROMAN
		CASE(OFStringEncodingMacRoman, _OFMacRomanTable)
#endif
#ifdef HAVE_KOI8_R
		CASE(OFStringEncodingKOI8R, _OFKOI8RTable)
#endif
#ifdef HAVE_KOI8_U
		CASE(OFStringEncodingKOI8U, _OFKOI8UTable)
#endif
#undef CASE
		default:
			@throw [OFInvalidArgumentException exception];
		}

		j = 0;
		for (size_t i = 0; i < cStringLength; i++) {
			unsigned char character = (unsigned char)cString[i];
			OFUnichar unichar;
			char buffer[4];
			size_t byteLength;

			if (character >= tableOffset)
				unichar = table[character - tableOffset];
			else
				unichar = character;

			if (unichar == 0xFFFF)
				@throw [OFInvalidEncodingException exception];

			if (unichar < 0x7F) {
				_s->cString[j++] = (char)unichar;
				continue;
			}

			_s->isUTF8 = true;

			if OF_UNLIKELY (cString[i] == '\0')
				_s->containsNull = true;

			byteLength = _OFUTF8StringEncode(unichar, buffer);
			if (byteLength == 0)
				@throw [OFInvalidEncodingException exception];

			_s->cStringLength += byteLength - 1;
			_s->cString = OFResizeMemory(_s->cString,
			    _s->cStringLength + 1, 1);

			memcpy(_s->cString + j, buffer, byteLength);
			j += byteLength;
		}

		_s->cString[_s->cStringLength] = 0;
	} @catch (id e) {
		objc_release(self);
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
		bool containsNull;

		_s = &_storage;

		if (UTF8StringLength >= 3 &&
		    memcmp(UTF8String, "\xEF\xBB\xBF", 3) == 0) {
			UTF8String += 3;
			UTF8StringLength -= 3;
		}

		switch (_OFUTF8StringCheck(UTF8String, UTF8StringLength,
		    &_s->length, &containsNull)) {
		case 1:
			_s->isUTF8 = true;
			break;
		case -1:
			@throw [OFInvalidEncodingException exception];
		}

		_s->cString = (char *)UTF8String;
		_s->cStringLength = UTF8StringLength;
		_s->containsNull = containsNull;
		_s->freeWhenDone = freeWhenDone;
	} @catch (id e) {
		objc_release(self);
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
		_s->length = string.length;

		_s->cString = OFAllocMemory(_s->cStringLength + 1, 1);
		memcpy(_s->cString,
		    [string insecureCStringWithEncoding: OFStringEncodingUTF8],
		    _s->cStringLength + 1);
		_s->freeWhenDone = true;

		if ([string isKindOfClass: [OFUTF8String class]] ||
		    [string isKindOfClass: [OFMutableUTF8String class]]) {
			_s->isUTF8 = ((OFUTF8String *)string)->_s->isUTF8;
			_s->containsNull =
			    ((OFUTF8String *)string)->_s->containsNull;
		} else {
			bool containsNull;

			switch (_OFUTF8StringCheck(_s->cString,
			    _s->cStringLength, NULL, &containsNull)) {
			case 1:
				_s->isUTF8 = true;
				break;
			case -1:
				@throw [OFInvalidEncodingException exception];
			}

			_s->containsNull = containsNull;
		}
	} @catch (id e) {
		objc_release(self);
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

		_s->cString = OFAllocMemory((length * 4) + 1, 1);
		_s->length = length;
		_s->freeWhenDone = true;

		j = 0;
		for (size_t i = 0; i < length; i++) {
			size_t len = _OFUTF8StringEncode(characters[i],
			    _s->cString + j);

			if (len == 0)
				@throw [OFInvalidEncodingException exception];

			if (len > 1)
				_s->isUTF8 = true;

			if OF_UNLIKELY (characters[i] == 0)
				_s->containsNull = true;

			j += len;
		}

		_s->cString[j] = '\0';
		_s->cStringLength = j;

		@try {
			_s->cString = OFResizeMemory(_s->cString, j + 1, 1);
		} @catch (OFOutOfMemoryException *e) {
			/* We don't care, as we only tried to make it smaller */
		}
	} @catch (id e) {
		objc_release(self);
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

		_s->cString = OFAllocMemory((length * 4) + 1, 1);
		_s->length = length;
		_s->freeWhenDone = true;

		j = 0;
		for (size_t i = 0; i < length; i++) {
			OFUnichar character =
			    (swap ? OFByteSwap16(string[i]) : string[i]);
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
				    ? OFByteSwap16(string[i + 1])
				    : string[i + 1]);

				if ((nextCharacter & 0xFC00) != 0xDC00)
					@throw [OFInvalidEncodingException
					    exception];

				character = (((character & 0x3FF) << 10) |
				    (nextCharacter & 0x3FF)) + 0x10000;

				i++;
				_s->length--;
			}

			len = _OFUTF8StringEncode(character, _s->cString + j);

			if (len == 0)
				@throw [OFInvalidEncodingException exception];

			if (len > 1)
				_s->isUTF8 = true;

			if OF_UNLIKELY (character == 0)
				_s->containsNull = true;

			j += len;
		}

		_s->cString[j] = '\0';
		_s->cStringLength = j;

		@try {
			_s->cString = OFResizeMemory(_s->cString, j + 1, 1);
		} @catch (OFOutOfMemoryException *e) {
			/* We don't care, as we only tried to make it smaller */
		}
	} @catch (id e) {
		objc_release(self);
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

		_s->cString = OFAllocMemory((length * 4) + 1, 1);
		_s->length = length;
		_s->freeWhenDone = true;

		j = 0;
		for (size_t i = 0; i < length; i++) {
			char buffer[4];
			OFUnichar character = (swap
			    ? OFByteSwap32(characters[i]) : characters[i]);
			size_t len = _OFUTF8StringEncode(character, buffer);

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

			if OF_UNLIKELY (character == 0)
				_s->containsNull = true;
		}

		_s->cString[j] = '\0';
		_s->cStringLength = j;

		@try {
			_s->cString = OFResizeMemory(_s->cString, j + 1, 1);
		} @catch (OFOutOfMemoryException *e) {
			/* We don't care, as we only tried to make it smaller */
		}
	} @catch (id e) {
		objc_release(self);
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

		if ((cStringLength = _OFVASPrintF(&tmp, format.UTF8String,
		    arguments)) == -1)
			@throw [OFInvalidFormatException exception];

		_s->cStringLength = cStringLength;

		@try {
			bool containsNull;

			switch (_OFUTF8StringCheck(tmp, cStringLength,
			    &_s->length, &containsNull)) {
			case 1:
				_s->isUTF8 = true;
				break;
			case -1:
				@throw [OFInvalidEncodingException exception];
			}

			_s->cString = OFAllocMemory(cStringLength + 1, 1);
			memcpy(_s->cString, tmp, cStringLength + 1);
			_s->containsNull = containsNull;
			_s->freeWhenDone = true;
		} @finally {
			OFFreeMemory(tmp);
		}
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_s != NULL && _s->freeWhenDone)
		OFFreeMemory(_s->cString);

	[super dealloc];
}

- (size_t)getCString: (char *)cString
	   maxLength: (size_t)maxLength
	    encoding: (OFStringEncoding)encoding
{
	if (_s->containsNull)
		@throw [OFInvalidEncodingException exception];

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
	if (_s->containsNull)
		@throw [OFInvalidEncodingException exception];

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

- (const char *)insecureCStringWithEncoding: (OFStringEncoding)encoding
{
	switch (encoding) {
	case OFStringEncodingASCII:
		if (_s->isUTF8)
			@throw [OFInvalidEncodingException exception];
		/* intentional fall-through */
	case OFStringEncodingUTF8:
		return _s->cString;
	default:
		return [super insecureCStringWithEncoding: encoding];
	}
}

- (const char *)UTF8String
{
	if (_s->containsNull)
		@throw [OFInvalidEncodingException exception];

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
	    _s->hasHash && string->_s->hasHash && _s->hash != string->_s->hash)
		return false;

	if (memcmp(_s->cString,
	    [string insecureCStringWithEncoding: OFStringEncodingUTF8],
	    _s->cStringLength) != 0)
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

	if ((compare = memcmp(_s->cString,
	    [string insecureCStringWithEncoding: OFStringEncodingUTF8],
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

	otherCString =
	    [string insecureCStringWithEncoding: OFStringEncodingUTF8];
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

		l1 = _OFUTF8StringDecode(_s->cString + i,
		    _s->cStringLength - i, &c1);
		l2 = _OFUTF8StringDecode(otherCString + j,
		    otherCStringLength - j, &c2);

		if (l1 <= 0 || l2 <= 0 || c1 > 0x10FFFF || c2 > 0x10FFFF)
			@throw [OFInvalidEncodingException exception];

		if (c1 >> 8 < _OFUnicodeCaseFoldingTableSize) {
			OFUnichar tc =
			    _OFUnicodeCaseFoldingTable[c1 >> 8][c1 & 0xFF];

			if (tc)
				c1 = tc;
		}

		if (c2 >> 8 < _OFUnicodeCaseFoldingTableSize) {
			OFUnichar tc =
			    _OFUnicodeCaseFoldingTable[c2 >> 8][c2 & 0xFF];

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
	unsigned long hash;

	if (_s->hasHash)
		return _s->hash;

	OFHashInit(&hash);

	for (size_t i = 0; i < _s->cStringLength; i++) {
		OFUnichar c;
		ssize_t length;

		if ((length = _OFUTF8StringDecode(_s->cString + i,
		    _s->cStringLength - i, &c)) <= 0)
			@throw [OFInvalidEncodingException exception];

		OFHashAddByte(&hash, (c & 0xFF0000) >> 16);
		OFHashAddByte(&hash, (c & 0x00FF00) >> 8);
		OFHashAddByte(&hash, c & 0x0000FF);

		i += length - 1;
	}

	OFHashFinalize(&hash);

	_s->hash = hash;
	_s->hasHash = true;

	return hash;
}

- (OFUnichar)characterAtIndex: (size_t)idx
{
	OFUnichar character;

	if (idx >= _s->length)
		@throw [OFOutOfRangeException exception];

	if (!_s->isUTF8)
		return _s->cString[idx];

	idx = _OFUTF8StringIndexToPosition(_s->cString, idx, _s->cStringLength);

	if (_OFUTF8StringDecode(_s->cString + idx, _s->cStringLength - idx,
	    &character) <= 0)
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
	const char *cString =
	    [string insecureCStringWithEncoding: OFStringEncodingUTF8];
	size_t cStringLength = string.UTF8StringLength;
	size_t rangeLocation, rangeLength;

	if (range.length > SIZE_MAX - range.location ||
	    range.location + range.length > _s->length)
		@throw [OFOutOfRangeException exception];

	if (_s->isUTF8) {
		rangeLocation = _OFUTF8StringIndexToPosition(
		    _s->cString, range.location, _s->cStringLength);
		rangeLength = _OFUTF8StringIndexToPosition(
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
				range.location += positionToIndex(
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
				range.location += positionToIndex(
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
	const char *cString =
	    [string insecureCStringWithEncoding: OFStringEncodingUTF8];
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
		start = _OFUTF8StringIndexToPosition(_s->cString, start,
		    _s->cStringLength);
		end = _OFUTF8StringIndexToPosition(_s->cString, end,
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

	return (memcmp(_s->cString,
	    [prefix insecureCStringWithEncoding: OFStringEncodingUTF8],
	    cStringLength) == 0);
}

- (bool)hasSuffix: (OFString *)suffix
{
	size_t cStringLength = suffix.UTF8StringLength;

	if (cStringLength > _s->cStringLength)
		return false;

	return (memcmp(_s->cString + (_s->cStringLength - cStringLength),
	    [suffix insecureCStringWithEncoding: OFStringEncodingUTF8],
	    cStringLength) == 0);
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
	cString = [delimiter insecureCStringWithEncoding: OFStringEncodingUTF8];
	cStringLength = delimiter.UTF8StringLength;

	if (cStringLength > _s->cStringLength) {
		[array addObject: objc_autorelease([self copy])];
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
	OFUnichar *buffer = OFAllocMemory(_s->length, sizeof(OFUnichar));
	size_t i = 0, j = 0;
	const OFUnichar *ret;

	while (i < _s->cStringLength) {
		OFUnichar c;
		ssize_t cLen;

		cLen = _OFUTF8StringDecode(_s->cString + i,
		    _s->cStringLength - i, &c);

		if (cLen <= 0 || c > 0x10FFFF) {
			OFFreeMemory(buffer);
			@throw [OFInvalidEncodingException exception];
		}

		buffer[j++] = c;
		i += cLen;
	}

	@try {
		ret = [[OFData dataWithItemsNoCopy: buffer
					     count: _s->length
					  itemSize: sizeof(OFUnichar)
				      freeWhenDone: true] items];
	} @catch (id e) {
		OFFreeMemory(buffer);
		@throw e;
	}

	return ret;
}

- (const OFChar32 *)UTF32StringWithByteOrder: (OFByteOrder)byteOrder
{
	OFChar32 *buffer;
	size_t i = 0, j = 0;
	const OFChar32 *ret;

	if (_s->containsNull)
		@throw [OFInvalidEncodingException exception];

	buffer = OFAllocMemory(_s->length + 1, sizeof(OFChar32));

	while (i < _s->cStringLength) {
		OFChar32 c;
		ssize_t cLen;

		cLen = _OFUTF8StringDecode(_s->cString + i,
		    _s->cStringLength - i, &c);

		if (cLen <= 0 || c > 0x10FFFF) {
			OFFreeMemory(buffer);
			@throw [OFInvalidEncodingException exception];
		}

		if (byteOrder != OFByteOrderNative)
			buffer[j++] = OFByteSwap32(c);
		else
			buffer[j++] = c;

		i += cLen;
	}
	buffer[j] = 0;

	@try {
		ret = [[OFData dataWithItemsNoCopy: buffer
					     count: _s->length + 1
					  itemSize: sizeof(OFChar32)
				      freeWhenDone: true] items];
	} @catch (id e) {
		OFFreeMemory(buffer);
		@throw e;
	}

	return ret;
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateLinesUsingBlock: (OFStringLineEnumerationBlock)block
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
