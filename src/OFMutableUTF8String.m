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
#include <assert.h>

#import "OFMutableUTF8String.h"
#import "OFString.h"
#import "OFUTF8String.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

#import "of_asprintf.h"
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
	@try {
		self = [self initWithUTF8String: UTF8String];
	} @finally {
		if (freeWhenDone)
			free(UTF8String);
	}

	return self;
}

- (instancetype)initWithUTF8StringNoCopy: (char *)UTF8String
				  length: (size_t)UTF8StringLength
			    freeWhenDone: (bool)freeWhenDone
{
	@try {
		self = [self initWithUTF8String: UTF8String
					 length: UTF8StringLength];
	} @finally {
		if (freeWhenDone)
			free(UTF8String);
	}

	return self;
}

- (void)of_convertWithWordStartTable: (const of_unichar_t *const[])startTable
		     wordMiddleTable: (const of_unichar_t *const[])middleTable
		  wordStartTableSize: (size_t)startTableSize
		 wordMiddleTableSize: (size_t)middleTableSize
{
	of_unichar_t *unicodeString;
	size_t unicodeLen, newCStringLength;
	size_t i, j;
	char *newCString;
	bool isStart = true;

	if (!_s->isUTF8) {
		uint8_t t;
		const of_unichar_t *const *table;

		assert(startTableSize >= 1 && middleTableSize >= 1);

		_s->hashed = false;

		for (i = 0; i < _s->cStringLength; i++) {
			if (isStart)
				table = startTable;
			else
				table = middleTable;

			isStart = of_ascii_isspace(_s->cString[i]);

			if ((t = table[0][(uint8_t)_s->cString[i]]) != 0)
				_s->cString[i] = t;
		}

		return;
	}

	unicodeLen = self.length;
	unicodeString = [self allocMemoryWithSize: sizeof(of_unichar_t)
					    count: unicodeLen];

	i = j = 0;
	newCStringLength = 0;

	while (i < _s->cStringLength) {
		const of_unichar_t *const *table;
		size_t tableSize;
		of_unichar_t c;
		ssize_t cLen;

		if (isStart) {
			table = startTable;
			tableSize = middleTableSize;
		} else {
			table = middleTable;
			tableSize = middleTableSize;
		}

		cLen = of_string_utf8_decode(_s->cString + i,
		    _s->cStringLength - i, &c);

		if (cLen <= 0 || c > 0x10FFFF) {
			[self freeMemory: unicodeString];
			@throw [OFInvalidEncodingException exception];
		}

		isStart = of_ascii_isspace(c);

		if (c >> 8 < tableSize) {
			of_unichar_t tc = table[c >> 8][c & 0xFF];

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
			[self freeMemory: unicodeString];
			@throw [OFInvalidEncodingException exception];
		}

		i += cLen;
	}

	@try {
		newCString = [self allocMemoryWithSize: newCStringLength + 1];
	} @catch (id e) {
		[self freeMemory: unicodeString];
		@throw e;
	}

	j = 0;

	for (i = 0; i < unicodeLen; i++) {
		size_t d;

		if ((d = of_string_utf8_encode(unicodeString[i],
		    newCString + j)) == 0) {
			[self freeMemory: unicodeString];
			[self freeMemory: newCString];
			@throw [OFInvalidEncodingException exception];
		}
		j += d;
	}

	assert(j == newCStringLength);
	newCString[j] = 0;
	[self freeMemory: unicodeString];

	[self freeMemory: _s->cString];
	_s->hashed = false;
	_s->cString = newCString;
	_s->cStringLength = newCStringLength;

	/*
	 * Even though cStringLength can change, length cannot, therefore no
	 * need to change it.
	 */
}

- (void)setCharacter: (of_unichar_t)character
	     atIndex: (size_t)idx
{
	char buffer[4];
	of_unichar_t c;
	size_t lenNew;
	ssize_t lenOld;

	if (_s->isUTF8)
		idx = of_string_utf8_get_position(_s->cString, idx,
		    _s->cStringLength);

	if (idx >= _s->cStringLength)
		@throw [OFOutOfRangeException exception];

	/* Shortcut if old and new character both are ASCII */
	if (character < 0x80 && !(_s->cString[idx] & 0x80)) {
		_s->hashed = false;
		_s->cString[idx] = character;
		return;
	}

	if ((lenNew = of_string_utf8_encode(character, buffer)) == 0)
		@throw [OFInvalidEncodingException exception];

	if ((lenOld = of_string_utf8_decode(_s->cString + idx,
	    _s->cStringLength - idx, &c)) <= 0)
		@throw [OFInvalidEncodingException exception];

	_s->hashed = false;

	if (lenNew == (size_t)lenOld)
		memcpy(_s->cString + idx, buffer, lenNew);
	else if (lenNew > (size_t)lenOld) {
		_s->cString = [self resizeMemory: _s->cString
					    size: _s->cStringLength -
						  lenOld + lenNew + 1];

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
			_s->cString = [self
			    resizeMemory: _s->cString
				    size: _s->cStringLength + 1];
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

	switch (of_string_utf8_check(UTF8String, UTF8StringLength, &length)) {
	case 1:
		_s->isUTF8 = true;
		break;
	case -1:
		@throw [OFInvalidEncodingException exception];
	}

	_s->hashed = false;
	_s->cString = [self resizeMemory: _s->cString
				    size: _s->cStringLength +
					  UTF8StringLength + 1];
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

	switch (of_string_utf8_check(UTF8String, UTF8StringLength, &length)) {
	case 1:
		_s->isUTF8 = true;
		break;
	case -1:
		@throw [OFInvalidEncodingException exception];
	}

	_s->hashed = false;
	_s->cString = [self resizeMemory: _s->cString
				    size: _s->cStringLength +
					  UTF8StringLength + 1];
	memcpy(_s->cString + _s->cStringLength, UTF8String, UTF8StringLength);

	_s->cStringLength += UTF8StringLength;
	_s->length += length;

	_s->cString[_s->cStringLength] = 0;
}

- (void)appendCString: (const char *)cString
	     encoding: (of_string_encoding_t)encoding
{
	[self appendCString: cString
		   encoding: encoding
		     length: strlen(cString)];
}

- (void)appendCString: (const char *)cString
	     encoding: (of_string_encoding_t)encoding
	       length: (size_t)cStringLength
{
	if (encoding == OF_STRING_ENCODING_UTF_8)
		[self appendUTF8String: cString
				length: cStringLength];
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
	size_t UTF8StringLength;

	if (string == nil)
		@throw [OFInvalidArgumentException exception];

	UTF8StringLength = string.UTF8StringLength;

	_s->hashed = false;
	_s->cString = [self resizeMemory: _s->cString
				    size: _s->cStringLength +
					  UTF8StringLength + 1];
	memcpy(_s->cString + _s->cStringLength, string.UTF8String,
	    UTF8StringLength);

	_s->cStringLength += UTF8StringLength;
	_s->length += string.length;

	_s->cString[_s->cStringLength] = 0;

	if ([string isKindOfClass: [OFUTF8String class]] ||
	    [string isKindOfClass: [OFMutableUTF8String class]]) {
		if (((OFUTF8String *)string)->_s->isUTF8)
			_s->isUTF8 = true;
	} else
		_s->isUTF8 = true;
}

- (void)appendCharacters: (const of_unichar_t *)characters
		  length: (size_t)length
{
	char *tmp;

	tmp = [self allocMemoryWithSize: (length * 4) + 1];
	@try {
		size_t j = 0;
		bool isUTF8 = false;

		for (size_t i = 0; i < length; i++) {
			size_t len = of_string_utf8_encode(characters[i],
			    tmp + j);

			if (len == 0)
				@throw [OFInvalidEncodingException exception];

			if (len > 1)
				isUTF8 = true;

			j += len;
		}

		tmp[j] = '\0';

		_s->hashed = false;
		_s->cString = [self resizeMemory: _s->cString
					    size: _s->cStringLength + j + 1];
		memcpy(_s->cString + _s->cStringLength, tmp, j + 1);

		_s->cStringLength += j;
		_s->length += length;

		if (isUTF8)
			_s->isUTF8 = true;
	} @finally {
		[self freeMemory: tmp];
	}
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

- (void)reverse
{
	size_t i, j;

	_s->hashed = false;

	/* We reverse all bytes and restore UTF-8 later, if necessary */
	for (i = 0, j = _s->cStringLength - 1; i < _s->cStringLength / 2;
	    i++, j--) {
		_s->cString[i] ^= _s->cString[j];
		_s->cString[j] ^= _s->cString[i];
		_s->cString[i] ^= _s->cString[j];
	}

	if (!_s->isUTF8)
		return;

	for (i = 0; i < _s->cStringLength; i++) {
		/* ASCII */
		if OF_LIKELY (!(_s->cString[i] & 0x80))
			continue;

		/* A start byte can't happen first as we reversed everything */
		if OF_UNLIKELY (_s->cString[i] & 0x40)
			@throw [OFInvalidEncodingException exception];

		/* Next byte must not be ASCII */
		if OF_UNLIKELY (_s->cStringLength < i + 1 ||
		    !(_s->cString[i + 1] & 0x80))
			@throw [OFInvalidEncodingException exception];

		/* Next byte is the start byte */
		if OF_LIKELY (_s->cString[i + 1] & 0x40) {
			_s->cString[i] ^= _s->cString[i + 1];
			_s->cString[i + 1] ^= _s->cString[i];
			_s->cString[i] ^= _s->cString[i + 1];

			i++;
			continue;
		}

		/* Second next byte must not be ASCII */
		if OF_UNLIKELY (_s->cStringLength < i + 2 ||
		    !(_s->cString[i + 2] & 0x80))
			@throw [OFInvalidEncodingException exception];

		/* Second next byte is the start byte */
		if OF_LIKELY (_s->cString[i + 2] & 0x40) {
			_s->cString[i] ^= _s->cString[i + 2];
			_s->cString[i + 2] ^= _s->cString[i];
			_s->cString[i] ^= _s->cString[i + 2];

			i += 2;
			continue;
		}

		/* Third next byte must not be ASCII */
		if OF_UNLIKELY (_s->cStringLength < i + 3 ||
		    !(_s->cString[i + 3] & 0x80))
			@throw [OFInvalidEncodingException exception];

		/* Third next byte is the start byte */
		if OF_LIKELY (_s->cString[i + 3] & 0x40) {
			_s->cString[i] ^= _s->cString[i + 3];
			_s->cString[i + 3] ^= _s->cString[i];
			_s->cString[i] ^= _s->cString[i + 3];

			_s->cString[i + 1] ^= _s->cString[i + 2];
			_s->cString[i + 2] ^= _s->cString[i + 1];
			_s->cString[i + 1] ^= _s->cString[i + 2];

			i += 3;
			continue;
		}

		/* UTF-8 does not allow more than 4 bytes per character */
		@throw [OFInvalidEncodingException exception];
	}
}

- (void)insertString: (OFString *)string
	     atIndex: (size_t)idx
{
	size_t newCStringLength;

	if (idx > _s->length)
		@throw [OFOutOfRangeException exception];

	if (_s->isUTF8)
		idx = of_string_utf8_get_position(_s->cString, idx,
		    _s->cStringLength);

	newCStringLength = _s->cStringLength + string.UTF8StringLength;
	_s->hashed = false;
	_s->cString = [self resizeMemory: _s->cString
				    size: newCStringLength + 1];

	memmove(_s->cString + idx + string.UTF8StringLength,
	    _s->cString + idx, _s->cStringLength - idx);
	memcpy(_s->cString + idx, string.UTF8String,
	    string.UTF8StringLength);
	_s->cString[newCStringLength] = '\0';

	_s->cStringLength = newCStringLength;
	_s->length += string.length;

	if ([string isKindOfClass: [OFUTF8String class]] ||
	    [string isKindOfClass: [OFMutableUTF8String class]]) {
		if (((OFUTF8String *)string)->_s->isUTF8)
			_s->isUTF8 = true;
	} else
		_s->isUTF8 = true;
}

- (void)deleteCharactersInRange: (of_range_t)range
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

	memmove(_s->cString + start, _s->cString + end,
	    _s->cStringLength - end);
	_s->hashed = false;
	_s->length -= range.length;
	_s->cStringLength -= end - start;
	_s->cString[_s->cStringLength] = 0;

	@try {
		_s->cString = [self resizeMemory: _s->cString
					    size: _s->cStringLength + 1];
	} @catch (OFOutOfMemoryException *e) {
		/* We don't really care, as we only made it smaller */
	}
}

- (void)replaceCharactersInRange: (of_range_t)range
		      withString: (OFString *)replacement
{
	size_t start = range.location;
	size_t end = range.location + range.length;
	size_t newCStringLength, newLength;

	if (replacement == nil)
		@throw [OFInvalidArgumentException exception];

	if (range.length > SIZE_MAX - range.location || end > _s->length)
		@throw [OFOutOfRangeException exception];

	newLength = _s->length - range.length + replacement.length;

	if (_s->isUTF8) {
		start = of_string_utf8_get_position(_s->cString, start,
		    _s->cStringLength);
		end = of_string_utf8_get_position(_s->cString, end,
		    _s->cStringLength);
	}

	newCStringLength = _s->cStringLength - (end - start) +
	    replacement.UTF8StringLength;
	_s->hashed = false;

	/*
	 * If the new string is bigger, we need to resize it first so we can
	 * memmove() the rest of the string to the end.
	 *
	 * We must not resize the string if the new string is smaller, because
	 * then we can't memmove() the rest of the string forward as the rest is
	 * lost due to the resize!
	 */
	if (newCStringLength > _s->cStringLength)
		_s->cString = [self resizeMemory: _s->cString
					    size: newCStringLength + 1];

	memmove(_s->cString + start + replacement.UTF8StringLength,
	    _s->cString + end, _s->cStringLength - end);
	memcpy(_s->cString + start, replacement.UTF8String,
	    replacement.UTF8StringLength);
	_s->cString[newCStringLength] = '\0';

	/*
	 * If the new string is smaller, we can safely resize it now as we're
	 * done with memmove().
	 */
	if (newCStringLength < _s->cStringLength)
		_s->cString = [self resizeMemory: _s->cString
					    size: newCStringLength + 1];

	_s->cStringLength = newCStringLength;
	_s->length = newLength;

	if ([replacement isKindOfClass: [OFUTF8String class]] ||
	    [replacement isKindOfClass: [OFMutableUTF8String class]]) {
		if (((OFUTF8String *)replacement)->_s->isUTF8)
			_s->isUTF8 = true;
	} else
		_s->isUTF8 = true;
}

- (void)replaceOccurrencesOfString: (OFString *)string
			withString: (OFString *)replacement
			   options: (int)options
			     range: (of_range_t)range
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
		range.location = of_string_utf8_get_position(_s->cString,
		    range.location, _s->cStringLength);
		range.length = of_string_utf8_get_position(
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
			newCString = [self resizeMemory: newCString
						   size: newCStringLength +
							 i - last +
							 replacementLength + 1];
		} @catch (id e) {
			[self freeMemory: newCString];
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
		newCString = [self resizeMemory: newCString
					   size: newCStringLength +
						 _s->cStringLength - last + 1];
	} @catch (id e) {
		[self freeMemory: newCString];
		@throw e;
	}
	memcpy(newCString + newCStringLength, _s->cString + last,
	    _s->cStringLength - last);
	newCStringLength += _s->cStringLength - last;
	newCString[newCStringLength] = 0;

	[self freeMemory: _s->cString];
	_s->hashed = false;
	_s->cString = newCString;
	_s->cStringLength = newCStringLength;
	_s->length = newLength;

	if ([replacement isKindOfClass: [OFUTF8String class]] ||
	    [replacement isKindOfClass: [OFMutableUTF8String class]]) {
		if (((OFUTF8String *)replacement)->_s->isUTF8)
			_s->isUTF8 = true;
	} else
		_s->isUTF8 = true;
}

- (void)deleteLeadingWhitespaces
{
	size_t i;

	for (i = 0; i < _s->cStringLength; i++)
		if (!of_ascii_isspace(_s->cString[i]))
			break;

	_s->hashed = false;
	_s->cStringLength -= i;
	_s->length -= i;

	memmove(_s->cString, _s->cString + i, _s->cStringLength);
	_s->cString[_s->cStringLength] = '\0';

	@try {
		_s->cString = [self resizeMemory: _s->cString
					    size: _s->cStringLength + 1];
	} @catch (OFOutOfMemoryException *e) {
		/* We don't really care, as we only made it smaller */
	}
}

- (void)deleteTrailingWhitespaces
{
	size_t d;
	char *p;

	_s->hashed = false;

	d = 0;
	for (p = _s->cString + _s->cStringLength - 1; p >= _s->cString; p--) {
		if (!of_ascii_isspace(*p))
			break;

		*p = '\0';
		d++;
	}

	_s->cStringLength -= d;
	_s->length -= d;

	@try {
		_s->cString = [self resizeMemory: _s->cString
					    size: _s->cStringLength + 1];
	} @catch (OFOutOfMemoryException *e) {
		/* We don't really care, as we only made it smaller */
	}
}

- (void)deleteEnclosingWhitespaces
{
	size_t d, i;
	char *p;

	_s->hashed = false;

	d = 0;
	for (p = _s->cString + _s->cStringLength - 1; p >= _s->cString; p--) {
		if (!of_ascii_isspace(*p))
			break;

		*p = '\0';
		d++;
	}

	_s->cStringLength -= d;
	_s->length -= d;

	for (i = 0; i < _s->cStringLength; i++)
		if (!of_ascii_isspace(_s->cString[i]))
			break;

	_s->cStringLength -= i;
	_s->length -= i;

	memmove(_s->cString, _s->cString + i, _s->cStringLength);
	_s->cString[_s->cStringLength] = '\0';

	@try {
		_s->cString = [self resizeMemory: _s->cString
					    size: _s->cStringLength + 1];
	} @catch (OFOutOfMemoryException *e) {
		/* We don't really care, as we only made it smaller */
	}
}

- (void)makeImmutable
{
	object_setClass(self, [OFUTF8String class]);
}
@end
