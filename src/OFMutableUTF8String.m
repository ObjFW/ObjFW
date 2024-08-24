/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFMutableUTF8String.h"
#import "OFASPrintF.h"
#import "OFString.h"
#import "OFUTF8String.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

#import "unicode.h"

@implementation OFMutableUTF8String
+ (void)initialize
{
	if (self == [OFMutableUTF8String class])
		[self inheritMethodsFromClass: [OFUTF8String class]];
}

- (instancetype)initWithUTF8StringNoCopy: (char *)UTF8String
			    freeWhenDone: (bool)freeWhenDone
{
	self = [self initWithUTF8String: UTF8String];

	if (freeWhenDone)
		OFFreeMemory(UTF8String);

	return self;
}

- (instancetype)initWithUTF8StringNoCopy: (char *)UTF8String
				  length: (size_t)UTF8StringLength
			    freeWhenDone: (bool)freeWhenDone
{
	self = [self initWithUTF8String: UTF8String length: UTF8StringLength];

	if (freeWhenDone)
		OFFreeMemory(UTF8String);

	return self;
}

#ifdef OF_HAVE_UNICODE_TABLES
- (void)of_convertWithWordStartTable: (const OFUnichar *const [])startTable
		     wordMiddleTable: (const OFUnichar *const [])middleTable
		  wordStartTableSize: (size_t)startTableSize
		 wordMiddleTableSize: (size_t)middleTableSize
{
	OFUnichar *unicodeString;
	size_t unicodeLen, newCStringLength;
	size_t i, j;
	char *newCString;
	bool isStart = true;

	if (!_s->isUTF8) {
		uint8_t t;
		const OFUnichar *const *table;

		OFAssert(startTableSize >= 1 && middleTableSize >= 1);

		_s->hasHash = false;

		for (i = 0; i < _s->cStringLength; i++) {
			if (isStart)
				table = startTable;
			else
				table = middleTable;

			isStart = OFASCIIIsSpace(_s->cString[i]);

			if ((t = table[0][(uint8_t)_s->cString[i]]) != 0)
				_s->cString[i] = t;
		}

		return;
	}

	unicodeLen = self.length;
	unicodeString = OFAllocMemory(unicodeLen, sizeof(OFUnichar));

	i = j = 0;
	newCStringLength = 0;

	while (i < _s->cStringLength) {
		const OFUnichar *const *table;
		size_t tableSize;
		OFUnichar c;
		ssize_t cLen;

		if (isStart) {
			table = startTable;
			tableSize = middleTableSize;
		} else {
			table = middleTable;
			tableSize = middleTableSize;
		}

		cLen = _OFUTF8StringDecode(_s->cString + i,
		    _s->cStringLength - i, &c);

		if (cLen <= 0 || c > 0x10FFFF) {
			OFFreeMemory(unicodeString);
			@throw [OFInvalidEncodingException exception];
		}

		isStart = OFASCIIIsSpace(c);

		if (c >> 8 < tableSize) {
			OFUnichar tc = table[c >> 8][c & 0xFF];

			if (tc)
				c = tc;
		}
		unicodeString[j++] = c;

		if (c < 0x80)
			newCStringLength++;
		else if (c < 0x800)
			newCStringLength += 2;
		else if (c < 0x10000)
			newCStringLength += 3;
		else if (c < 0x110000)
			newCStringLength += 4;
		else {
			OFFreeMemory(unicodeString);
			@throw [OFInvalidEncodingException exception];
		}

		i += cLen;
	}

	@try {
		newCString = OFAllocMemory(newCStringLength + 1, 1);
	} @catch (id e) {
		OFFreeMemory(unicodeString);
		@throw e;
	}

	j = 0;

	for (i = 0; i < unicodeLen; i++) {
		size_t d;

		if ((d = _OFUTF8StringEncode(unicodeString[i],
		    newCString + j)) == 0) {
			OFFreeMemory(unicodeString);
			OFFreeMemory(newCString);
			@throw [OFInvalidEncodingException exception];
		}
		j += d;
	}

	OFAssert(j == newCStringLength);
	newCString[j] = 0;
	OFFreeMemory(unicodeString);

	OFFreeMemory(_s->cString);
	_s->hasHash = false;
	_s->cString = newCString;
	_s->cStringLength = newCStringLength;

	/*
	 * Even though cStringLength can change, length cannot, therefore no
	 * need to change it.
	 */
}
#endif

- (void)setCharacter: (OFUnichar)character atIndex: (size_t)idx
{
	char buffer[4];
	OFUnichar c;
	size_t lenNew;
	ssize_t lenOld;

	if (_s->isUTF8)
		idx = _OFUTF8StringIndexToPosition(_s->cString, idx,
		    _s->cStringLength);

	if (idx >= _s->cStringLength)
		@throw [OFOutOfRangeException exception];

	/* Shortcut if old and new character both are ASCII */
	if (character < 0x80 && !(_s->cString[idx] & 0x80)) {
		_s->hasHash = false;
		_s->cString[idx] = character;
		return;
	}

	if ((lenNew = _OFUTF8StringEncode(character, buffer)) == 0)
		@throw [OFInvalidEncodingException exception];

	if ((lenOld = _OFUTF8StringDecode(_s->cString + idx,
	    _s->cStringLength - idx, &c)) <= 0)
		@throw [OFInvalidEncodingException exception];

	_s->hasHash = false;

	if (lenNew == (size_t)lenOld)
		memcpy(_s->cString + idx, buffer, lenNew);
	else if (lenNew > (size_t)lenOld) {
		_s->cString = OFResizeMemory(_s->cString,
		    _s->cStringLength - lenOld + lenNew + 1, 1);

		memmove(_s->cString + idx + lenNew, _s->cString + idx + lenOld,
		    _s->cStringLength - idx - lenOld);
		memcpy(_s->cString + idx, buffer, lenNew);

		_s->cStringLength -= lenOld;
		_s->cStringLength += lenNew;
		_s->cString[_s->cStringLength] = '\0';

		if (character >= 0x80)
			_s->isUTF8 = true;
	} else if (lenNew < (size_t)lenOld) {
		memmove(_s->cString + idx + lenNew, _s->cString + idx + lenOld,
		    _s->cStringLength - idx - lenOld);
		memcpy(_s->cString + idx, buffer, lenNew);

		_s->cStringLength -= lenOld;
		_s->cStringLength += lenNew;
		_s->cString[_s->cStringLength] = '\0';

		if (character >= 0x80)
			_s->isUTF8 = true;

		@try {
			_s->cString = OFResizeMemory(_s->cString,
			    _s->cStringLength + 1, 1);
		} @catch (OFOutOfMemoryException *e) {
			/* We don't really care, as we only made it smaller */
		}
	}
}

- (void)appendUTF8String: (const char *)UTF8String
{
	size_t UTF8StringLength = strlen(UTF8String);
	size_t length;

	if (UTF8StringLength >= 3 &&
	    memcmp(UTF8String, "\xEF\xBB\xBF", 3) == 0) {
		UTF8String += 3;
		UTF8StringLength -= 3;
	}

	switch (_OFUTF8StringCheck(UTF8String, UTF8StringLength, &length)) {
	case 1:
		_s->isUTF8 = true;
		break;
	case -1:
		@throw [OFInvalidEncodingException exception];
	}

	_s->hasHash = false;
	_s->cString = OFResizeMemory(_s->cString,
	    _s->cStringLength + UTF8StringLength + 1, 1);
	memcpy(_s->cString + _s->cStringLength, UTF8String,
	    UTF8StringLength + 1);

	_s->cStringLength += UTF8StringLength;
	_s->length += length;
}

- (void)appendUTF8String: (const char *)UTF8String
		  length: (size_t)UTF8StringLength
{
	size_t length;

	if (UTF8StringLength >= 3 &&
	    memcmp(UTF8String, "\xEF\xBB\xBF", 3) == 0) {
		UTF8String += 3;
		UTF8StringLength -= 3;
	}

	switch (_OFUTF8StringCheck(UTF8String, UTF8StringLength, &length)) {
	case 1:
		_s->isUTF8 = true;
		break;
	case -1:
		@throw [OFInvalidEncodingException exception];
	}

	_s->hasHash = false;
	_s->cString = OFResizeMemory(_s->cString,
	    _s->cStringLength + UTF8StringLength + 1, 1);
	memcpy(_s->cString + _s->cStringLength, UTF8String, UTF8StringLength);

	_s->cStringLength += UTF8StringLength;
	_s->length += length;

	_s->cString[_s->cStringLength] = 0;
}

- (void)appendCString: (const char *)cString
	     encoding: (OFStringEncoding)encoding
{
	[self appendCString: cString
		   encoding: encoding
		     length: strlen(cString)];
}

- (void)appendCString: (const char *)cString
	     encoding: (OFStringEncoding)encoding
	       length: (size_t)cStringLength
{
	if (encoding == OFStringEncodingUTF8)
		[self appendUTF8String: cString length: cStringLength];
	else {
		void *pool = objc_autoreleasePoolPush();

		[self appendString:
		    [OFString stringWithCString: cString
				       encoding: encoding
					 length: cStringLength]];

		objc_autoreleasePoolPop(pool);
	}
}

- (void)appendString: (OFString *)string
{
	const char *UTF8String;
	size_t UTF8StringLength;

	if (string == nil)
		@throw [OFInvalidArgumentException exception];

	UTF8String = string.UTF8String;
	UTF8StringLength = string.UTF8StringLength;

	_s->hasHash = false;
	_s->cString = OFResizeMemory(_s->cString,
	    _s->cStringLength + UTF8StringLength + 1, 1);
	memcpy(_s->cString + _s->cStringLength, UTF8String, UTF8StringLength);

	_s->cStringLength += UTF8StringLength;
	_s->length += string.length;

	_s->cString[_s->cStringLength] = 0;

	if ([string isKindOfClass: [OFUTF8String class]] ||
	    [string isKindOfClass: [OFMutableUTF8String class]]) {
		if (((OFMutableUTF8String *)string)->_s->isUTF8)
			_s->isUTF8 = true;
	} else {
		switch (_OFUTF8StringCheck(UTF8String, UTF8StringLength,
		    NULL)) {
		case 1:
			_s->isUTF8 = true;
			break;
		case -1:
			@throw [OFInvalidEncodingException exception];
		}
	}
}

- (void)appendCharacters: (const OFUnichar *)characters length: (size_t)length
{
	char *tmp = OFAllocMemory((length * 4) + 1, 1);

	@try {
		size_t j = 0;
		bool isUTF8 = false;

		for (size_t i = 0; i < length; i++) {
			size_t len = _OFUTF8StringEncode(characters[i],
			    tmp + j);

			if (len == 0)
				@throw [OFInvalidEncodingException exception];

			if (len > 1)
				isUTF8 = true;

			j += len;
		}

		tmp[j] = '\0';

		_s->hasHash = false;
		_s->cString = OFResizeMemory(_s->cString,
		    _s->cStringLength + j + 1, 1);
		memcpy(_s->cString + _s->cStringLength, tmp, j + 1);

		_s->cStringLength += j;
		_s->length += length;

		if (isUTF8)
			_s->isUTF8 = true;
	} @finally {
		OFFreeMemory(tmp);
	}
}

- (void)appendFormat: (OFConstantString *)format arguments: (va_list)arguments
{
	char *UTF8String;
	int UTF8StringLength;

	if (format == nil)
		@throw [OFInvalidArgumentException exception];

	if ((UTF8StringLength = _OFVASPrintF(&UTF8String, format.UTF8String,
	    arguments)) == -1)
		@throw [OFInvalidFormatException exception];

	@try {
		[self appendUTF8String: UTF8String length: UTF8StringLength];
	} @finally {
		free(UTF8String);
	}
}

- (void)insertString: (OFString *)string atIndex: (size_t)idx
{
	const char *UTF8String;
	size_t UTF8StringLength, newCStringLength;

	if (idx > _s->length)
		@throw [OFOutOfRangeException exception];

	if (_s->isUTF8)
		idx = _OFUTF8StringIndexToPosition(_s->cString, idx,
		    _s->cStringLength);

	UTF8String = string.UTF8String;
	UTF8StringLength = string.UTF8StringLength;

	newCStringLength = _s->cStringLength + UTF8StringLength;
	_s->hasHash = false;
	_s->cString = OFResizeMemory(_s->cString, newCStringLength + 1, 1);

	memmove(_s->cString + idx + UTF8StringLength, _s->cString + idx,
	    _s->cStringLength - idx);
	memcpy(_s->cString + idx, UTF8String, UTF8StringLength);
	_s->cString[newCStringLength] = '\0';

	_s->cStringLength = newCStringLength;
	_s->length += string.length;

	if ([string isKindOfClass: [OFUTF8String class]] ||
	    [string isKindOfClass: [OFMutableUTF8String class]]) {
		if (((OFMutableUTF8String *)string)->_s->isUTF8)
			_s->isUTF8 = true;
	} else {
		switch (_OFUTF8StringCheck(UTF8String, UTF8StringLength,
		    NULL)) {
		case 1:
			_s->isUTF8 = true;
			break;
		case -1:
			@throw [OFInvalidEncodingException exception];
		}
	}
}

- (void)deleteCharactersInRange: (OFRange)range
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

	memmove(_s->cString + start, _s->cString + end,
	    _s->cStringLength - end);
	_s->hasHash = false;
	_s->length -= range.length;
	_s->cStringLength -= end - start;
	_s->cString[_s->cStringLength] = 0;

	@try {
		_s->cString = OFResizeMemory(_s->cString, _s->cStringLength + 1,
		    1);
	} @catch (OFOutOfMemoryException *e) {
		/* We don't really care, as we only made it smaller */
	}
}

- (void)replaceCharactersInRange: (OFRange)range
		      withString: (OFString *)replacement
{
	size_t start = range.location;
	size_t end = range.location + range.length;
	size_t newCStringLength, newLength;
	const char *replacementString;
	size_t replacementLength;

	if (replacement == nil)
		@throw [OFInvalidArgumentException exception];

	if (range.length > SIZE_MAX - range.location || end > _s->length)
		@throw [OFOutOfRangeException exception];

	newLength = _s->length - range.length + replacement.length;

	if (_s->isUTF8) {
		start = _OFUTF8StringIndexToPosition(_s->cString, start,
		    _s->cStringLength);
		end = _OFUTF8StringIndexToPosition(_s->cString, end,
		    _s->cStringLength);
	}

	replacementString = replacement.UTF8String;
	replacementLength = replacement.UTF8StringLength;

	newCStringLength =
	    _s->cStringLength - (end - start) + replacementLength;
	_s->hasHash = false;

	/*
	 * If the new string is bigger, we need to resize it first so we can
	 * memmove() the rest of the string to the end.
	 *
	 * We must not resize the string if the new string is smaller, because
	 * then we can't memmove() the rest of the string forward as the rest is
	 * lost due to the resize!
	 */
	if (newCStringLength > _s->cStringLength)
		_s->cString = OFResizeMemory(_s->cString, newCStringLength + 1,
		    1);

	memmove(_s->cString + start + replacementLength, _s->cString + end,
	    _s->cStringLength - end);
	memcpy(_s->cString + start, replacementString, replacementLength);
	_s->cString[newCStringLength] = '\0';

	/*
	 * If the new string is smaller, we can safely resize it now as we're
	 * done with memmove().
	 */
	if (newCStringLength < _s->cStringLength)
		_s->cString = OFResizeMemory(_s->cString, newCStringLength + 1,
		    1);

	_s->cStringLength = newCStringLength;
	_s->length = newLength;

	if ([replacement isKindOfClass: [OFUTF8String class]] ||
	    [replacement isKindOfClass: [OFMutableUTF8String class]]) {
		if (((OFMutableUTF8String *)replacement)->_s->isUTF8)
			_s->isUTF8 = true;
	} else {
		switch (_OFUTF8StringCheck(replacementString, replacementLength,
		    NULL)) {
		case 1:
			_s->isUTF8 = true;
			break;
		case -1:
			@throw [OFInvalidEncodingException exception];
		}
	}
}

- (void)replaceOccurrencesOfString: (OFString *)string
			withString: (OFString *)replacement
			   options: (int)options
			     range: (OFRange)range
{
	const char *searchString = string.UTF8String;
	const char *replacementString = replacement.UTF8String;
	size_t searchLength = string.UTF8StringLength;
	size_t replacementLength = replacement.UTF8StringLength;
	size_t last, newCStringLength, newLength;
	char *newCString;

	if (string == nil || replacement == nil)
		@throw [OFInvalidArgumentException exception];

	if (range.length > SIZE_MAX - range.location ||
	    range.location + range.length > self.length)
		@throw [OFOutOfRangeException exception];

	if (_s->isUTF8) {
		range.location = _OFUTF8StringIndexToPosition(_s->cString,
		    range.location, _s->cStringLength);
		range.length = _OFUTF8StringIndexToPosition(
		    _s->cString + range.location, range.length,
		    _s->cStringLength - range.location);
	}

	if (string.UTF8StringLength > range.length)
		return;

	newCString = NULL;
	newCStringLength = 0;
	newLength = _s->length;
	last = 0;

	for (size_t i = range.location; i <= range.length - searchLength; i++) {
		if (memcmp(_s->cString + i, searchString, searchLength) != 0)
			continue;

		@try {
			newCString = OFResizeMemory(newCString,
			    newCStringLength + i - last + replacementLength + 1,
			    1);
		} @catch (id e) {
			OFFreeMemory(newCString);
			@throw e;
		}
		memcpy(newCString + newCStringLength, _s->cString + last,
		    i - last);
		memcpy(newCString + newCStringLength + i - last,
		    replacementString, replacementLength);

		newCStringLength += i - last + replacementLength;
		newLength = newLength - string.length + replacement.length;

		i += searchLength - 1;
		last = i + 1;
	}

	@try {
		newCString = OFResizeMemory(newCString,
		    newCStringLength + _s->cStringLength - last + 1, 1);
	} @catch (id e) {
		OFFreeMemory(newCString);
		@throw e;
	}
	memcpy(newCString + newCStringLength, _s->cString + last,
	    _s->cStringLength - last);
	newCStringLength += _s->cStringLength - last;
	newCString[newCStringLength] = 0;

	OFFreeMemory(_s->cString);
	_s->hasHash = false;
	_s->cString = newCString;
	_s->cStringLength = newCStringLength;
	_s->length = newLength;

	if ([replacement isKindOfClass: [OFUTF8String class]] ||
	    [replacement isKindOfClass: [OFMutableUTF8String class]]) {
		if (((OFMutableUTF8String *)replacement)->_s->isUTF8)
			_s->isUTF8 = true;
	} else {
		switch (_OFUTF8StringCheck(replacementString, replacementLength,
		    NULL)) {
		case 1:
			_s->isUTF8 = true;
			break;
		case -1:
			@throw [OFInvalidEncodingException exception];
		}
	}
}

- (void)deleteLeadingWhitespaces
{
	size_t i;

	for (i = 0; i < _s->cStringLength; i++)
		if (!OFASCIIIsSpace(_s->cString[i]))
			break;

	_s->hasHash = false;
	_s->cStringLength -= i;
	_s->length -= i;

	memmove(_s->cString, _s->cString + i, _s->cStringLength);
	_s->cString[_s->cStringLength] = '\0';

	@try {
		_s->cString = OFResizeMemory(_s->cString, _s->cStringLength + 1,
		    1);
	} @catch (OFOutOfMemoryException *e) {
		/* We don't really care, as we only made it smaller */
	}
}

- (void)deleteTrailingWhitespaces
{
	size_t d;
	char *p;

	_s->hasHash = false;

	d = 0;
	for (p = _s->cString + _s->cStringLength - 1; p >= _s->cString; p--) {
		if (!OFASCIIIsSpace(*p))
			break;

		*p = '\0';
		d++;
	}

	_s->cStringLength -= d;
	_s->length -= d;

	@try {
		_s->cString = OFResizeMemory(_s->cString, _s->cStringLength + 1,
		    1);
	} @catch (OFOutOfMemoryException *e) {
		/* We don't really care, as we only made it smaller */
	}
}

- (void)deleteEnclosingWhitespaces
{
	size_t d, i;
	char *p;

	_s->hasHash = false;

	d = 0;
	for (p = _s->cString + _s->cStringLength - 1; p >= _s->cString; p--) {
		if (!OFASCIIIsSpace(*p))
			break;

		*p = '\0';
		d++;
	}

	_s->cStringLength -= d;
	_s->length -= d;

	for (i = 0; i < _s->cStringLength; i++)
		if (!OFASCIIIsSpace(_s->cString[i]))
			break;

	_s->cStringLength -= i;
	_s->length -= i;

	memmove(_s->cString, _s->cString + i, _s->cStringLength);
	_s->cString[_s->cStringLength] = '\0';

	@try {
		_s->cString = OFResizeMemory(_s->cString, _s->cStringLength + 1,
		    1);
	} @catch (OFOutOfMemoryException *e) {
		/* We don't really care, as we only made it smaller */
	}
}

- (void)makeImmutable
{
	object_setClass(self, [OFUTF8String class]);
}
@end
