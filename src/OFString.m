/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#include "config.h"

#include <stdarg.h>
#include <stdlib.h>
#include <string.h>

#include <sys/stat.h>

#import "OFString.h"
#import "OFString_UTF8.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFFile.h"
#import "OFURL.h"
#import "OFHTTPRequest.h"
#import "OFDataArray.h"
#import "OFXMLElement.h"
#import "OFAutoreleasePool.h"

#import "OFHTTPRequestFailedException.h"
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"
#import "OFOpenFileFailedException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

#import "macros.h"
#import "of_asprintf.h"
#import "unicode.h"

/* References for static linking */
void _references_to_categories_of_OFString(void)
{
	_OFString_Hashing_reference = 1;
	_OFString_JSONValue_reference = 1;
	_OFString_Serialization_reference = 1;
	_OFString_URLEncoding_reference = 1;
	_OFString_XMLEscaping_reference = 1;
	_OFString_XMLUnescaping_reference = 1;
}

int
of_string_check_utf8(const char *cString, size_t cStringLength, size_t *length)
{
	size_t i, tmpLength = cStringLength;
	int UTF8 = 0;

	for (i = 0; i < cStringLength; i++) {
		/* No sign of UTF-8 here */
		if (OF_LIKELY(!(cString[i] & 0x80)))
			continue;

		UTF8 = 1;

		/* We're missing a start byte here */
		if (OF_UNLIKELY(!(cString[i] & 0x40)))
			return -1;

		/* 2 byte sequences for code points 0 - 127 are forbidden */
		if (OF_UNLIKELY((cString[i] & 0x7E) == 0x40))
			return -1;

		/* We have at minimum a 2 byte character -> check next byte */
		if (OF_UNLIKELY(cStringLength <= i + 1 ||
		    (cString[i + 1] & 0xC0) != 0x80))
			return -1;

		/* Check if we have at minimum a 3 byte character */
		if (OF_LIKELY(!(cString[i] & 0x20))) {
			i++;
			tmpLength--;
			continue;
		}

		/* We have at minimum a 3 byte char -> check second next byte */
		if (OF_UNLIKELY(cStringLength <= i + 2 ||
		    (cString[i + 2] & 0xC0) != 0x80))
			return -1;

		/* Check if we have a 4 byte character */
		if (OF_LIKELY(!(cString[i] & 0x10))) {
			i += 2;
			tmpLength -= 2;
			continue;
		}

		/* We have a 4 byte character -> check third next byte */
		if (OF_UNLIKELY(cStringLength <= i + 3 ||
		    (cString[i + 3] & 0xC0) != 0x80))
			return -1;

		/*
		 * Just in case, check if there's a 5th character, which is
		 * forbidden by UTF-8
		 */
		if (OF_UNLIKELY(cString[i] & 0x08))
			return -1;

		i += 3;
		tmpLength -= 3;
	}

	if (length != NULL)
		*length = tmpLength;

	return UTF8;
}

size_t
of_string_unicode_to_utf8(of_unichar_t character, char *buffer)
{
	size_t i = 0;

	if (character < 0x80) {
		buffer[i] = character;
		return 1;
	}
	if (character < 0x800) {
		buffer[i++] = 0xC0 | (character >> 6);
		buffer[i] = 0x80 | (character & 0x3F);
		return 2;
	}
	if (character < 0x10000) {
		buffer[i++] = 0xE0 | (character >> 12);
		buffer[i++] = 0x80 | (character >> 6 & 0x3F);
		buffer[i] = 0x80 | (character & 0x3F);
		return 3;
	}
	if (character < 0x110000) {
		buffer[i++] = 0xF0 | (character >> 18);
		buffer[i++] = 0x80 | (character >> 12 & 0x3F);
		buffer[i++] = 0x80 | (character >> 6 & 0x3F);
		buffer[i] = 0x80 | (character & 0x3F);
		return 4;
	}

	return 0;
}

size_t
of_string_utf8_to_unicode(const char *buffer_, size_t length, of_unichar_t *ret)
{
	const uint8_t *buffer = (const uint8_t*)buffer_;

	if (!(*buffer & 0x80)) {
		*ret = buffer[0];
		return 1;
	}

	if ((*buffer & 0xE0) == 0xC0) {
		if (OF_UNLIKELY(length < 2))
			return 0;

		*ret = ((buffer[0] & 0x1F) << 6) | (buffer[1] & 0x3F);
		return 2;
	}

	if ((*buffer & 0xF0) == 0xE0) {
		if (OF_UNLIKELY(length < 3))
			return 0;

		*ret = ((buffer[0] & 0x0F) << 12) | ((buffer[1] & 0x3F) << 6) |
		    (buffer[2] & 0x3F);
		return 3;
	}

	if ((*buffer & 0xF8) == 0xF0) {
		if (OF_UNLIKELY(length < 4))
			return 0;

		*ret = ((buffer[0] & 0x07) << 18) | ((buffer[1] & 0x3F) << 12) |
		    ((buffer[2] & 0x3F) << 6) | (buffer[3] & 0x3F);
		return 4;
	}

	return 0;
}

size_t
of_string_position_to_index(const char *string, size_t position)
{
	size_t i, index = position;

	for (i = 0; i < position; i++)
		if (OF_UNLIKELY((string[i] & 0xC0) == 0x80))
			index--;

	return index;
}

size_t
of_string_index_to_position(const char *string, size_t index, size_t length)
{
	size_t i;

	for (i = 0; i <= index; i++)
		if (OF_UNLIKELY((string[i] & 0xC0) == 0x80))
			if (++index > length)
				return OF_INVALID_INDEX;

	return index;
}

size_t
of_unicode_string_length(const of_unichar_t *string)
{
	const of_unichar_t *string_ = string;

	while (*string_ != 0)
		string_++;

	return (size_t)(string_ - string);
}

size_t
of_utf16_string_length(const uint16_t *string)
{
	const uint16_t *string_ = string;

	while (*string_ != 0)
		string_++;

	return (size_t)(string_ - string);
}

static struct {
	Class isa;
} placeholder;

@interface OFString_placeholder: OFString
@end

@implementation OFString_placeholder
- init
{
	return (id)[[OFString_UTF8 alloc] init];
}

- initWithUTF8String: (const char*)UTF8String
{
	return (id)[[OFString_UTF8 alloc] initWithUTF8String: UTF8String];
}

- initWithUTF8String: (const char*)UTF8String
	      length: (size_t)UTF8StringLength
{
	return (id)[[OFString_UTF8 alloc] initWithUTF8String: UTF8String
						      length: UTF8StringLength];
}

- initWithCString: (const char*)cString
	 encoding: (of_string_encoding_t)encoding
{
	return (id)[[OFString_UTF8 alloc] initWithCString: cString
						 encoding: encoding];
}

- initWithCString: (const char*)cString
	 encoding: (of_string_encoding_t)encoding
	   length: (size_t)cStringLength
{
	return (id)[[OFString_UTF8 alloc] initWithCString: cString
						 encoding: encoding
						   length: cStringLength];
}

- initWithString: (OFString*)string
{
	return (id)[[OFString_UTF8 alloc] initWithString: string];
}

- initWithUnicodeString: (const of_unichar_t*)string
{
	return (id)[[OFString_UTF8 alloc] initWithUnicodeString: string];
}

- initWithUnicodeString: (const of_unichar_t*)string
	      byteOrder: (of_endianess_t)byteOrder
{
	return (id)[[OFString_UTF8 alloc] initWithUnicodeString: string
						      byteOrder: byteOrder];
}

- initWithUnicodeString: (const of_unichar_t*)string
		 length: (size_t)length
{
	return (id)[[OFString_UTF8 alloc] initWithUnicodeString: string
							 length: length];
}

- initWithUnicodeString: (const of_unichar_t*)string
	      byteOrder: (of_endianess_t)byteOrder
		 length: (size_t)length
{
	return (id)[[OFString_UTF8 alloc] initWithUnicodeString: string
						      byteOrder: byteOrder
							 length: length];
}

- initWithUTF16String: (const uint16_t*)string
{
	return (id)[[OFString_UTF8 alloc] initWithUTF16String: string];
}

- initWithUTF16String: (const uint16_t*)string
	    byteOrder: (of_endianess_t)byteOrder
{
	return (id)[[OFString_UTF8 alloc] initWithUTF16String: string
						    byteOrder: byteOrder];
}

- initWithUTF16String: (const uint16_t*)string
	       length: (size_t)length
{
	return (id)[[OFString_UTF8 alloc] initWithUTF16String: string
						       length: length];
}

- initWithUTF16String: (const uint16_t*)string
	    byteOrder: (of_endianess_t)byteOrder
	       length: (size_t)length
{
	return (id)[[OFString_UTF8 alloc] initWithUTF16String: string
						    byteOrder: byteOrder
						       length: length];
}

- initWithFormat: (OFConstantString*)format, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, format);
	ret = [[OFString_UTF8 alloc] initWithFormat: format
					  arguments: arguments];
	va_end(arguments);

	return ret;
}

- initWithFormat: (OFConstantString*)format
       arguments: (va_list)arguments
{
	return (id)[[OFString_UTF8 alloc] initWithFormat: format
					       arguments: arguments];
}

- initWithPath: (OFString*)firstComponent, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstComponent);
	ret = [[OFString_UTF8 alloc] initWithPath: firstComponent
					arguments: arguments];
	va_end(arguments);

	return ret;
}

- initWithPath: (OFString*)firstComponent
     arguments: (va_list)arguments
{
	return (id)[[OFString_UTF8 alloc] initWithPath: firstComponent
					     arguments: arguments];
}

- initWithContentsOfFile: (OFString*)path
{
	return (id)[[OFString_UTF8 alloc] initWithContentsOfFile: path];
}

- initWithContentsOfFile: (OFString*)path
		encoding: (of_string_encoding_t)encoding
{
	return (id)[[OFString_UTF8 alloc] initWithContentsOfFile: path
							encoding: encoding];
}

- initWithContentsOfURL: (OFURL*)URL
{
	return (id)[[OFString_UTF8 alloc] initWithContentsOfURL: URL];
}

- initWithContentsOfURL: (OFURL*)URL
	       encoding: (of_string_encoding_t)encoding
{
	return (id)[[OFString_UTF8 alloc] initWithContentsOfURL: URL
						       encoding: encoding];
}

- initWithSerialization: (OFXMLElement*)element
{
	return (id)[[OFString_UTF8 alloc] initWithSerialization: element];
}

- retain
{
	return self;
}

- autorelease
{
	return self;
}

- (void)release
{
}

- (void)dealloc
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
	[super dealloc];	/* Get rid of a stupid warning */
}
@end

@implementation OFString
+ (void)initialize
{
	if (self == [OFString class])
		placeholder.isa = [OFString_placeholder class];
}

+ alloc
{
	if (self == [OFString class])
		return (id)&placeholder;

	return [super alloc];
}

+ string
{
	return [[[self alloc] init] autorelease];
}

+ stringWithUTF8String: (const char*)UTF8String
{
	return [[[self alloc] initWithUTF8String: UTF8String] autorelease];
}

+ stringWithUTF8String: (const char*)UTF8String
		length: (size_t)UTF8StringLength
{
	return [[[self alloc]
	    initWithUTF8String: UTF8String
			length: UTF8StringLength] autorelease];
}

+ stringWithCString: (const char*)cString
	   encoding: (of_string_encoding_t)encoding
{
	return [[[self alloc] initWithCString: cString
				     encoding: encoding] autorelease];
}

+ stringWithCString: (const char*)cString
	   encoding: (of_string_encoding_t)encoding
	     length: (size_t)cStringLength
{
	return [[[self alloc] initWithCString: cString
				     encoding: encoding
				       length: cStringLength] autorelease];
}

+ stringWithString: (OFString*)string
{
	return [[[self alloc] initWithString: string] autorelease];
}

+ stringWithUnicodeString: (const of_unichar_t*)string
{
	return [[[self alloc] initWithUnicodeString: string] autorelease];
}

+ stringWithUnicodeString: (const of_unichar_t*)string
		byteOrder: (of_endianess_t)byteOrder
{
	return [[[self alloc] initWithUnicodeString: string
					  byteOrder: byteOrder] autorelease];
}

+ stringWithUnicodeString: (const of_unichar_t*)string
		   length: (size_t)length
{
	return [[[self alloc] initWithUnicodeString: string
					     length: length] autorelease];
}

+ stringWithUnicodeString: (const of_unichar_t*)string
		byteOrder: (of_endianess_t)byteOrder
		   length: (size_t)length
{
	return [[[self alloc] initWithUnicodeString: string
					  byteOrder: byteOrder
					     length: length] autorelease];
}

+ stringWithUTF16String: (const uint16_t*)string
{
	return [[[self alloc] initWithUTF16String: string] autorelease];
}

+ stringWithUTF16String: (const uint16_t*)string
	      byteOrder: (of_endianess_t)byteOrder
{
	return [[[self alloc] initWithUTF16String: string
					byteOrder: byteOrder] autorelease];
}

+ stringWithUTF16String: (const uint16_t*)string
		 length: (size_t)length
{
	return [[[self alloc] initWithUTF16String: string
					   length: length] autorelease];
}

+ stringWithUTF16String: (const uint16_t*)string
	      byteOrder: (of_endianess_t)byteOrder
		 length: (size_t)length
{
	return [[[self alloc] initWithUTF16String: string
					byteOrder: byteOrder
					   length: length] autorelease];
}

+ stringWithFormat: (OFConstantString*)format, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, format);
	ret = [[[self alloc] initWithFormat: format
				  arguments: arguments] autorelease];
	va_end(arguments);

	return ret;
}

+ stringWithPath: (OFString*)firstComponent, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstComponent);
	ret = [[[self alloc] initWithPath: firstComponent
				arguments: arguments] autorelease];
	va_end(arguments);

	return ret;
}

+ stringWithContentsOfFile: (OFString*)path
{
	return [[[self alloc] initWithContentsOfFile: path] autorelease];
}

+ stringWithContentsOfFile: (OFString*)path
		  encoding: (of_string_encoding_t)encoding
{
	return [[[self alloc] initWithContentsOfFile: path
					    encoding: encoding] autorelease];
}

+ stringWithContentsOfURL: (OFURL*)URL
{
	return [[[self alloc] initWithContentsOfURL: URL] autorelease];
}

+ stringWithContentsOfURL: (OFURL*)URL
		 encoding: (of_string_encoding_t)encoding
{
	return [[[self alloc] initWithContentsOfURL: URL
					   encoding: encoding] autorelease];
}

- init
{
	if (isa == [OFString class]) {
		Class c = isa;
		[self release];
		@throw [OFNotImplementedException exceptionWithClass: c
							    selector: _cmd];
	}

	return [super init];
}

- initWithUTF8String: (const char*)UTF8String
{
	return [self initWithCString: UTF8String
			    encoding: OF_STRING_ENCODING_UTF_8
			      length: strlen(UTF8String)];
}

- initWithUTF8String: (const char*)UTF8String
	      length: (size_t)UTF8StringLength
{
	return [self initWithCString: UTF8String
			    encoding: OF_STRING_ENCODING_UTF_8
			      length: UTF8StringLength];
}

- initWithCString: (const char*)cString
	 encoding: (of_string_encoding_t)encoding
{
	return [self initWithCString: cString
			    encoding: encoding
			      length: strlen(cString)];
}

- initWithCString: (const char*)cString
	 encoding: (of_string_encoding_t)encoding
	   length: (size_t)cStringLength
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithString: (OFString*)string
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithUnicodeString: (const of_unichar_t*)string
{
	return [self initWithUnicodeString: string
				 byteOrder: OF_ENDIANESS_NATIVE
				    length: of_unicode_string_length(string)];
}

- initWithUnicodeString: (const of_unichar_t*)string
	      byteOrder: (of_endianess_t)byteOrder
{
	return [self initWithUnicodeString: string
				 byteOrder: byteOrder
				    length: of_unicode_string_length(string)];
}

- initWithUnicodeString: (const of_unichar_t*)string
		 length: (size_t)length
{
	return [self initWithUnicodeString: string
				 byteOrder: OF_ENDIANESS_NATIVE
				    length: length];
}

- initWithUnicodeString: (const of_unichar_t*)string
	      byteOrder: (of_endianess_t)byteOrder
		 length: (size_t)length
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithUTF16String: (const uint16_t*)string
{
	return [self initWithUTF16String: string
			       byteOrder: OF_ENDIANESS_BIG_ENDIAN
				  length: of_utf16_string_length(string)];
}

- initWithUTF16String: (const uint16_t*)string
	    byteOrder: (of_endianess_t)byteOrder
{
	return [self initWithUTF16String: string
			       byteOrder: byteOrder
				  length: of_utf16_string_length(string)];
}

- initWithUTF16String: (const uint16_t*)string
	       length: (size_t)length
{
	return [self initWithUTF16String: string
			       byteOrder: OF_ENDIANESS_BIG_ENDIAN
				  length: length];
}

- initWithUTF16String: (const uint16_t*)string
	    byteOrder: (of_endianess_t)byteOrder
	       length: (size_t)length
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithFormat: (OFConstantString*)format, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, format);
	ret = [self initWithFormat: format
			 arguments: arguments];
	va_end(arguments);

	return ret;
}

- initWithFormat: (OFConstantString*)format
       arguments: (va_list)arguments
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithPath: (OFString*)firstComponent, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstComponent);
	ret = [self initWithPath: firstComponent
		       arguments: arguments];
	va_end(arguments);

	return ret;
}

- initWithPath: (OFString*)firstComponent
     arguments: (va_list)arguments
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithContentsOfFile: (OFString*)path
{
	return [self initWithContentsOfFile: path
				   encoding: OF_STRING_ENCODING_UTF_8];
}

- initWithContentsOfFile: (OFString*)path
		encoding: (of_string_encoding_t)encoding
{
	char *tmp;
	struct stat st;

	@try {
		OFFile *file;

		if (stat([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
		    &st) == -1)
			@throw [OFOpenFileFailedException
			    exceptionWithClass: isa
					  path: path
					  mode: @"rb"];

		if (st.st_size > SIZE_MAX)
			@throw [OFOutOfRangeException exceptionWithClass: isa];

		file = [[OFFile alloc] initWithPath: path
					       mode: @"rb"];

		@try {
			tmp = [self allocMemoryWithSize: (size_t)st.st_size];

			[file readExactlyNBytes: (size_t)st.st_size
				     intoBuffer: tmp];
		} @finally {
			[file release];
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	self = [self initWithCString: tmp
			    encoding: encoding
			      length: (size_t)st.st_size];
	[self freeMemory: tmp];

	return self;
}

- initWithContentsOfURL: (OFURL*)URL
{
	return [self initWithContentsOfURL: URL
				  encoding: OF_STRING_ENCODING_AUTODETECT];
}

- initWithContentsOfURL: (OFURL*)URL
	       encoding: (of_string_encoding_t)encoding
{
	OFAutoreleasePool *pool;
	OFHTTPRequest *request;
	OFHTTPRequestResult *result;
	OFMutableString *contentType;
	Class c;

	c = isa;
	[self release];

	pool = [[OFAutoreleasePool alloc] init];

	if ([[URL scheme] isEqual: @"file"]) {
		if (encoding == OF_STRING_ENCODING_AUTODETECT)
			encoding = OF_STRING_ENCODING_UTF_8;

		self = [[c alloc] initWithContentsOfFile: [URL path]
						encoding: encoding];
		[pool release];
		return self;
	}

	request = [OFHTTPRequest requestWithURL: URL];
	result = [request perform];

	if ([result statusCode] != 200)
		@throw [OFHTTPRequestFailedException
		    exceptionWithClass: [request class]
			   HTTPRequest: request
				result: result];

	if (encoding == OF_STRING_ENCODING_AUTODETECT &&
	    (contentType = [[result headers] objectForKey: @"Content-Type"])) {
		contentType = [[contentType mutableCopy] autorelease];
		[contentType lower];

		if ([contentType hasSuffix: @"charset=UTF-8"])
			encoding = OF_STRING_ENCODING_UTF_8;
		if ([contentType hasSuffix: @"charset=iso-8859-1"])
			encoding = OF_STRING_ENCODING_ISO_8859_1;
		if ([contentType hasSuffix: @"charset=iso-8859-15"])
			encoding = OF_STRING_ENCODING_ISO_8859_15;
		if ([contentType hasSuffix: @"charset=windows-1252"])
			encoding = OF_STRING_ENCODING_WINDOWS_1252;
	}

	if (encoding == OF_STRING_ENCODING_AUTODETECT)
		encoding = OF_STRING_ENCODING_UTF_8;

	self = [[c alloc] initWithCString: (char*)[[result data] cArray]
				 encoding: encoding
				   length: [[result data] count]];

	[pool release];
	return self;
}

- initWithSerialization: (OFXMLElement*)element
{
	@try {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

		if (![[element namespace] isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException
			    exceptionWithClass: isa
				      selector: _cmd];

		if ([self isKindOfClass: [OFMutableString class]]) {
			if (![[element name] isEqual: @"OFMutableString"])
				@throw [OFInvalidArgumentException
				    exceptionWithClass: isa
					      selector: _cmd];
		} else {
			if (![[element name] isEqual: @"OFString"])
				@throw [OFInvalidArgumentException
				    exceptionWithClass: isa
					      selector: _cmd];
		}

		self = [self initWithString: [element stringValue]];

		[pool release];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (const char*)UTF8String
{
	const of_unichar_t *unicodeString = [self unicodeString];
	char *UTF8String;
	size_t i, j = 0, length = [self length];
	size_t UTF8StringLength = length;
	OFObject *object;

	object = [[[OFObject alloc] init] autorelease];
	UTF8String = [object allocMemoryWithSize: (length * 4) + 1];

	for (i = 0; i < length; i++) {
		char buffer[4];
		size_t characterLen = of_string_unicode_to_utf8(
		    unicodeString[i], buffer);

		switch (characterLen) {
		case 1:
			UTF8String[j++] = buffer[0];
			break;
		case 2:
			UTF8StringLength++;

			memcpy(UTF8String + j, buffer, 2);
			j += 2;

			break;
		case 3:
			UTF8StringLength += 2;

			memcpy(UTF8String + j, buffer, 3);
			j += 3;

			break;
		case 4:
			UTF8StringLength += 3;

			memcpy(UTF8String + j, buffer, 4);
			j += 4;

			break;
		default:
			@throw [OFInvalidEncodingException
			    exceptionWithClass: isa];
		}
	}

	UTF8String[j] = '\0';

	@try {
		UTF8String = [object resizeMemory: UTF8String
					   toSize: UTF8StringLength + 1];
	} @catch (OFOutOfMemoryException *e) {
		/* We don't care, as we only tried to make it smaller */
	}

	return UTF8String;
}

- (const char*)cStringWithEncoding: (of_string_encoding_t)encoding
{
	if (encoding == OF_STRING_ENCODING_UTF_8)
		return [self UTF8String];

	/* TODO: Implement! */
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (size_t)length
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (size_t)UTF8StringLength
{
	const of_unichar_t *unicodeString = [self unicodeString];
	size_t length = [self length];
	size_t i, UTF8StringLength = 0;

	for (i = 0; i < length; i++) {
		char buffer[4];
		size_t characterLen = of_string_unicode_to_utf8(
		    unicodeString[i], buffer);

		if (characterLen == 0)
			@throw [OFInvalidEncodingException
			    exceptionWithClass: isa];

		UTF8StringLength += characterLen;
	}

	return UTF8StringLength;
}

- (size_t)cStringLengthWithEncoding: (of_string_encoding_t)encoding
{
	if (encoding == OF_STRING_ENCODING_UTF_8)
		return [self UTF8StringLength];

	/* TODO: Implement! */
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (of_unichar_t)characterAtIndex: (size_t)index
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (void)getCharacters: (of_unichar_t*)buffer
	      inRange: (of_range_t)range
{
	size_t i;

	for (i = 0; i < range.length; i++)
		buffer[i] = [self characterAtIndex: range.start + i];
}

- (BOOL)isEqual: (id)object
{
	OFAutoreleasePool *pool;
	OFString *otherString;
	const of_unichar_t *unicodeString, *otherUnicodeString;
	size_t length;

	if (object == self)
		return YES;

	if (![object isKindOfClass: [OFString class]])
		return NO;

	otherString = object;
	length = [self length];

	if ([otherString length] != length)
		return NO;

	pool = [[OFAutoreleasePool alloc] init];

	unicodeString = [self unicodeString];
	otherUnicodeString = [otherString unicodeString];

	if (memcmp(unicodeString, otherUnicodeString,
	    length * sizeof(of_unichar_t))) {
		[pool release];
		return NO;
	}

	[pool release];

	return YES;
}

- copy
{
	return [self retain];
}

- mutableCopy
{
	return [[OFMutableString alloc] initWithString: self];
}

- (of_comparison_result_t)compare: (id)object
{
	OFAutoreleasePool *pool;
	OFString *otherString;
	const of_unichar_t *unicodeString, *otherUnicodeString;
	size_t i, minimumLength;

	if (object == self)
		return OF_ORDERED_SAME;

	if (![object isKindOfClass: [OFString class]])
		@throw [OFInvalidArgumentException exceptionWithClass: isa
							     selector: _cmd];

	otherString = object;
	minimumLength = ([self length] > [otherString length]
	    ? [otherString length] : [self length]);

	pool = [[OFAutoreleasePool alloc] init];

	unicodeString = [self unicodeString];
	otherUnicodeString = [otherString unicodeString];

	for (i = 0; i < minimumLength; i++) {
		if (unicodeString[i] > otherUnicodeString[i]) {
			[pool release];
			return OF_ORDERED_DESCENDING;
		}

		if (unicodeString[i] < otherUnicodeString[i]) {
			[pool release];
			return OF_ORDERED_ASCENDING;
		}
	}

	[pool release];

	if ([self length] > [otherString length])
		return OF_ORDERED_DESCENDING;
	if ([self length] < [otherString length])
		return OF_ORDERED_ASCENDING;

	return OF_ORDERED_SAME;
}

- (of_comparison_result_t)caseInsensitiveCompare: (OFString*)otherString
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	const of_unichar_t *string, *otherUnicodeString;
	size_t i, length, otherLength, minimumLength;

	if (otherString == self)
		return OF_ORDERED_SAME;

	string = [self unicodeString];
	otherUnicodeString = [otherString unicodeString];
	length = [self length];
	otherLength = [otherString length];

	minimumLength = (length > otherLength ? otherLength : length);

	for (i = 0; i < minimumLength; i++) {
		of_unichar_t c = string[i];
		of_unichar_t oc = otherUnicodeString[i];

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

		if (c > oc) {
			[pool release];
			return OF_ORDERED_DESCENDING;
		}
		if (c < oc) {
			[pool release];
			return OF_ORDERED_ASCENDING;
		}
	}

	[pool release];

	if (length > otherLength)
		return OF_ORDERED_DESCENDING;
	if (length < otherLength)
		return OF_ORDERED_ASCENDING;

	return OF_ORDERED_SAME;
}

- (uint32_t)hash
{
	const of_unichar_t *unicodeString = [self unicodeString];
	size_t i, length = [self length];
	uint32_t hash;

	OF_HASH_INIT(hash);

	for (i = 0; i < length; i++) {
		const of_unichar_t c = unicodeString[i];

		OF_HASH_ADD(hash, (c & 0xFF0000) >> 16);
		OF_HASH_ADD(hash, (c & 0x00FF00) >>  8);
		OF_HASH_ADD(hash,  c & 0x0000FF);
	}

	OF_HASH_FINALIZE(hash);

	return hash;
}

- (OFString*)description
{
	return [[self copy] autorelease];
}

- (OFXMLElement*)XMLElementBySerializing
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
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
	[pool release];
	[element autorelease];

	return element;
}

- (OFString*)JSONRepresentation
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
	[JSON replaceOccurrencesOfString: @"\n"
			      withString: @"\\n"];
	[JSON replaceOccurrencesOfString: @"\r"
			      withString: @"\\r"];
	[JSON replaceOccurrencesOfString: @"\t"
			      withString: @"\\t"];

	[JSON prependString: @"\""];
	[JSON appendString: @"\""];

	[JSON makeImmutable];

	return JSON;
}

- (size_t)indexOfFirstOccurrenceOfString: (OFString*)string
{
	OFAutoreleasePool *pool;
	const of_unichar_t *unicodeString, *searchString;
	size_t i, length, searchLength;

	if ((searchLength = [string length]) == 0)
		return [self length];

	if (searchLength > (length = [self length]))
		return OF_INVALID_INDEX;

	pool = [[OFAutoreleasePool alloc] init];

	unicodeString = [self unicodeString];
	searchString = [string unicodeString];

	for (i = 0; i <= length - searchLength; i++) {
		if (!memcmp(unicodeString + i, searchString,
		    searchLength * sizeof(of_unichar_t))) {
			[pool release];
			return i;
		}
	}

	[pool release];

	return OF_INVALID_INDEX;
}

- (size_t)indexOfLastOccurrenceOfString: (OFString*)string
{
	OFAutoreleasePool *pool;
	const of_unichar_t *unicodeString, *searchString;
	size_t i, length, searchLength;

	if ((searchLength = [string length]) == 0)
		return [self length];

	if (searchLength > (length = [self length]))
		return OF_INVALID_INDEX;

	pool = [[OFAutoreleasePool alloc] init];

	unicodeString = [self unicodeString];
	searchString = [string unicodeString];

	for (i = length - searchLength;; i--) {
		if (!memcmp(unicodeString + i, searchString,
		    searchLength * sizeof(of_unichar_t))) {
			[pool release];
			return i;
		}

		/* Did not match and we're at the last character */
		if (i == 0)
			break;
	}

	[pool release];

	return OF_INVALID_INDEX;
}

- (BOOL)containsString: (OFString*)string
{
	OFAutoreleasePool *pool;
	const of_unichar_t *unicodeString, *searchString;
	size_t i, length, searchLength;

	if ((searchLength = [string length]) == 0)
		return YES;

	if (searchLength > (length = [self length]))
		return NO;

	pool = [[OFAutoreleasePool alloc] init];

	unicodeString = [self unicodeString];
	searchString = [string unicodeString];

	for (i = 0; i <= length - searchLength; i++) {
		if (!memcmp(unicodeString + i, searchString,
		    searchLength * sizeof(of_unichar_t))) {
			[pool release];
			return YES;
		}
	}

	[pool release];

	return NO;
}

- (OFString*)substringWithRange: (of_range_t)range
{
	OFAutoreleasePool *pool;
	OFString *ret;

	if (range.start + range.length > [self length])
		@throw [OFOutOfRangeException exceptionWithClass: isa];

	pool = [[OFAutoreleasePool alloc] init];
	ret = [[OFString alloc]
	    initWithUnicodeString: [self unicodeString] + range.start
			   length: range.length];
	[pool release];

	return [ret autorelease];
}

- (OFString*)stringByAppendingString: (OFString*)string
{
	OFMutableString *new;

	new = [OFMutableString stringWithString: self];
	[new appendString: string];

	[new makeImmutable];

	return new;
}

- (OFString*)stringByPrependingString: (OFString*)string
{
	OFMutableString *new = [[string mutableCopy] autorelease];

	[new appendString: self];

	[new makeImmutable];

	return new;
}

- (OFString*)stringByReplacingOccurrencesOfString: (OFString*)string
				       withString: (OFString*)replacement
{
	OFMutableString *new = [[self mutableCopy] autorelease];

	[new replaceOccurrencesOfString: string
			     withString: replacement];

	[new makeImmutable];

	return new;
}

- (OFString*)stringByReplacingOccurrencesOfString: (OFString*)string
				       withString: (OFString*)replacement
					  inRange: (of_range_t)range
{
	OFMutableString *new = [[self mutableCopy] autorelease];

	[new replaceOccurrencesOfString: string
			     withString: replacement
				inRange: range];

	[new makeImmutable];

	return new;
}

- (OFString*)uppercaseString
{
	OFMutableString *new = [[self mutableCopy] autorelease];

	[new upper];

	[new makeImmutable];

	return new;
}

- (OFString*)lowercaseString
{
	OFMutableString *new = [[self mutableCopy] autorelease];

	[new lower];

	[new makeImmutable];

	return new;
}

- (OFString*)stringByDeletingLeadingWhitespaces
{
	OFMutableString *new = [[self mutableCopy] autorelease];

	[new deleteLeadingWhitespaces];

	[new makeImmutable];

	return new;
}

- (OFString*)stringByDeletingTrailingWhitespaces
{
	OFMutableString *new = [[self mutableCopy] autorelease];

	[new deleteTrailingWhitespaces];

	[new makeImmutable];

	return new;
}

- (OFString*)stringByDeletingEnclosingWhitespaces
{
	OFMutableString *new = [[self mutableCopy] autorelease];

	[new deleteEnclosingWhitespaces];

	[new makeImmutable];

	return new;
}

- (BOOL)hasPrefix: (OFString*)prefix
{
	of_unichar_t *tmp;
	const of_unichar_t *prefixString;
	size_t prefixLength;
	int compare;

	if ((prefixLength = [prefix length]) > [self length])
		return NO;

	tmp = [self allocMemoryForNItems: prefixLength
				  ofSize: sizeof(of_unichar_t)];
	@try {
		OFAutoreleasePool *pool;

		[self getCharacters: tmp
			    inRange: of_range(0, prefixLength)];

		pool = [[OFAutoreleasePool alloc] init];

		prefixString = [prefix unicodeString];
		compare = memcmp(tmp, prefixString,
		    prefixLength * sizeof(of_unichar_t));

		[pool release];
	} @finally {
		[self freeMemory: tmp];
	}

	return !compare;
}

- (BOOL)hasSuffix: (OFString*)suffix
{
	of_unichar_t *tmp;
	const of_unichar_t *suffixString;
	size_t length, suffixLength;
	int compare;

	if ((suffixLength = [suffix length]) > [self length])
		return NO;

	length = [self length];

	tmp = [self allocMemoryForNItems: suffixLength
				  ofSize: sizeof(of_unichar_t)];
	@try {
		OFAutoreleasePool *pool;

		[self getCharacters: tmp
			    inRange: of_range(length - suffixLength,
					 suffixLength)];

		pool = [[OFAutoreleasePool alloc] init];

		suffixString = [suffix unicodeString];
		compare = memcmp(tmp, suffixString,
		    suffixLength * sizeof(of_unichar_t));

		[pool release];
	} @finally {
		[self freeMemory: tmp];
	}

	return !compare;
}

- (OFArray*)componentsSeparatedByString: (OFString*)delimiter
{
	return [self componentsSeparatedByString: delimiter
				       skipEmpty: NO];
}

- (OFArray*)componentsSeparatedByString: (OFString*)delimiter
			      skipEmpty: (BOOL)skipEmpty
{
	OFAutoreleasePool *pool;
	OFMutableArray *array = [OFMutableArray array];
	const of_unichar_t *string, *delimiterString;
	size_t length = [self length];
	size_t delimiterLength = [delimiter length];
	size_t i, last;
	OFString *component;

	pool = [[OFAutoreleasePool alloc] init];

	string = [self unicodeString];
	delimiterString = [delimiter unicodeString];

	if (delimiterLength > length) {
		[array addObject: [[self copy] autorelease]];
		[array makeImmutable];

		[pool release];

		return array;
	}

	for (i = 0, last = 0; i <= length - delimiterLength; i++) {
		if (memcmp(string + i, delimiterString,
		    delimiterLength * sizeof(of_unichar_t)))
			continue;

		component = [self substringWithRange: of_range(last, i - last)];
		if (!skipEmpty || ![component isEqual: @""])
			[array addObject: component];

		i += delimiterLength - 1;
		last = i + 1;
	}
	component = [self substringWithRange: of_range(last, length - last)];
	if (!skipEmpty || ![component isEqual: @""])
		[array addObject: component];

	[array makeImmutable];

	[pool release];

	return array;
}

- (OFArray*)pathComponents
{
	OFMutableArray *ret;
	OFAutoreleasePool *pool;
	const of_unichar_t *string;
	size_t i, last = 0, length = [self length];

	ret = [OFMutableArray array];

	if (length == 0)
		return ret;

	pool = [[OFAutoreleasePool alloc] init];

	string = [self unicodeString];

#ifndef _WIN32
	if (string[length - 1] == OF_PATH_DELIMITER)
#else
	if (string[length - 1] == '/' || string[length - 1] == '\\')
#endif
		length--;

	for (i = 0; i < length; i++) {
#ifndef _WIN32
		if (string[i] == OF_PATH_DELIMITER) {
#else
		if (string[i] == '/' || string[i] == '\\') {
#endif
			[ret addObject: [self substringWithRange:
			    of_range(last, i - last)]];

			last = i + 1;
		}
	}

	[ret addObject: [self substringWithRange: of_range(last, i - last)]];

	[ret makeImmutable];

	[pool release];

	return ret;
}

- (OFString*)lastPathComponent
{
	OFAutoreleasePool *pool;
	const of_unichar_t *string;
	size_t length = [self length];
	ssize_t i;

	if (length == 0)
		return @"";

	pool = [[OFAutoreleasePool alloc] init];

	string = [self unicodeString];

#ifndef _WIN32
	if (string[length - 1] == OF_PATH_DELIMITER)
#else
	if (string[length - 1] == '/' || string[length - 1] == '\\')
#endif
		length--;

	for (i = length - 1; i >= 0; i--) {
#ifndef _WIN32
		if (string[i] == OF_PATH_DELIMITER) {
#else
		if (string[i] == '/' || string[i] == '\\') {
#endif
			i++;
			break;
		}
	}

	[pool release];

	/*
	 * Only one component, but the trailing delimiter might have been
	 * removed, so return a new string anyway.
	 */
	if (i < 0)
		i = 0;

	return [self substringWithRange: of_range(i, length - i)];
}

- (OFString*)stringByDeletingLastPathComponent
{
	OFAutoreleasePool *pool;
	const of_unichar_t *string;
	size_t i, length = [self length];

	if (length == 0)
		return @"";

	pool = [[OFAutoreleasePool alloc] init];

	string = [self unicodeString];

#ifndef _WIN32
	if (string[length - 1] == OF_PATH_DELIMITER)
#else
	if (string[length - 1] == '/' || string[length - 1] == '\\')
#endif
		length--;

	if (length == 0) {
		[pool release];
		return [self substringWithRange: of_range(0, 1)];
	}

	for (i = length - 1; i >= 1; i--) {
#ifndef _WIN32
		if (string[i] == OF_PATH_DELIMITER) {
#else
		if (string[i] == '/' || string[i] == '\\') {
#endif
			[pool release];
			return [self substringWithRange: of_range(0, i)];
		}
	}

#ifndef _WIN32
	if (string[0] == OF_PATH_DELIMITER) {
#else
	if (string[0] == '/' || string[0] == '\\') {
#endif
		[pool release];
		return [self substringWithRange: of_range(0, 1)];
	}

	[pool release];

	return @".";
}

- (intmax_t)decimalValue
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	const of_unichar_t *string = [self unicodeString];
	size_t length = [self length];
	int i = 0;
	intmax_t value = 0;
	BOOL expectWhitespace = NO;

	while (*string == ' ' || *string == '\t' || *string == '\n' ||
	    *string == '\r' || *string == '\f') {
		string++;
		length--;
	}

	if (length == 0) {
		[pool release];
		return 0;
	}

	if (string[0] == '-' || string[0] == '+')
		i++;

	for (; i < length; i++) {
		if (expectWhitespace) {
			if (string[i] != ' ' && string[i] != '\t' &&
			    string[i] != '\n' && string[i] != '\r' &&
			    string[i] != '\f')
				@throw [OFInvalidFormatException
				    exceptionWithClass: isa];
			continue;
		}

		if (string[i] >= '0' && string[i] <= '9') {
			if (INTMAX_MAX / 10 < value ||
			    INTMAX_MAX - value * 10 < string[i] - '0')
				@throw [OFOutOfRangeException
				    exceptionWithClass: isa];

			value = (value * 10) + (string[i] - '0');
		} else if (string[i] == ' ' || string[i] == '\t' ||
		    string[i] == '\n' || string[i] == '\r' ||
		    string[i] == '\f')
			expectWhitespace = YES;
		else
			@throw [OFInvalidFormatException
			    exceptionWithClass: isa];
	}

	if (string[0] == '-')
		value *= -1;

	[pool release];

	return value;
}

- (uintmax_t)hexadecimalValue
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	const of_unichar_t *string = [self unicodeString];
	size_t length = [self length];
	int i = 0;
	uintmax_t value = 0;
	BOOL expectWhitespace = NO, foundValue = NO;

	while (*string == ' ' || *string == '\t' || *string == '\n' ||
	    *string == '\r' || *string == '\f') {
		string++;
		length--;
	}

	if (length == 0) {
		[pool release];
		return 0;
	}

	if (length >= 2 && string[0] == '0' && string[1] == 'x')
		i = 2;
	else if (length >= 1 && (string[0] == 'x' || string[0] == '$'))
		i = 1;

	for (; i < length; i++) {
		uintmax_t newValue;

		if (expectWhitespace) {
			if (string[i] != ' ' && string[i] != '\t' &&
			    string[i] != '\n' && string[i] != '\r' &&
			    string[i] != '\f')
				@throw [OFInvalidFormatException
				    exceptionWithClass: isa];
			continue;
		}

		if (string[i] >= '0' && string[i] <= '9') {
			newValue = (value << 4) | (string[i] - '0');
			foundValue = YES;
		} else if (string[i] >= 'A' && string[i] <= 'F') {
			newValue = (value << 4) | (string[i] - 'A' + 10);
			foundValue = YES;
		} else if (string[i] >= 'a' && string[i] <= 'f') {
			newValue = (value << 4) | (string[i] - 'a' + 10);
			foundValue = YES;
		} else if (string[i] == 'h' || string[i] == ' ' ||
		    string[i] == '\t' || string[i] == '\n' ||
		    string[i] == '\r' || string[i] == '\f') {
			expectWhitespace = YES;
			continue;
		} else
			@throw [OFInvalidFormatException
			    exceptionWithClass: isa];

		if (newValue < value)
			@throw [OFOutOfRangeException exceptionWithClass: isa];

		value = newValue;
	}

	if (!foundValue)
		@throw [OFInvalidFormatException exceptionWithClass: isa];

	[pool release];

	return value;
}

- (float)floatValue
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	const char *cString = [self UTF8String];
	char *endPointer = NULL;
	float value;

	while (*cString == ' ' || *cString == '\t' || *cString == '\n' ||
	    *cString == '\r' || *cString == '\f')
		cString++;

	value = strtof(cString, &endPointer);

	/* Check if there are any invalid chars left */
	if (endPointer != NULL)
		for (; *endPointer != '\0'; endPointer++)
			if (*endPointer != ' ' && *endPointer != '\t' &&
			    *endPointer != '\n' && *endPointer != '\r' &&
			    *endPointer != '\f')
				@throw [OFInvalidFormatException
				    exceptionWithClass: isa];

	[pool release];

	return value;
}

- (double)doubleValue
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	const char *cString = [self UTF8String];
	char *endPointer = NULL;
	double value;

	while (*cString == ' ' || *cString == '\t' || *cString == '\n' ||
	    *cString == '\r' || *cString == '\f')
		cString++;

	value = strtod(cString, &endPointer);

	/* Check if there are any invalid chars left */
	if (endPointer != NULL)
		for (; *endPointer != '\0'; endPointer++)
			if (*endPointer != ' ' && *endPointer != '\t' &&
			    *endPointer != '\n' && *endPointer != '\r' &&
			    *endPointer != '\f')
				@throw [OFInvalidFormatException
				    exceptionWithClass: isa];

	[pool release];

	return value;
}

- (const of_unichar_t*)unicodeString
{
	OFObject *object = [[[OFObject alloc] init] autorelease];
	size_t length = [self length];
	of_unichar_t *ret;

	ret = [object allocMemoryForNItems: length + 1
				    ofSize: sizeof(of_unichar_t)];
	[self getCharacters: ret
		    inRange: of_range(0, length)];
	ret[length] = 0;

	return ret;
}

- (const uint16_t*)UTF16String
{
	OFObject *object = [[[OFObject alloc] init] autorelease];
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	const of_unichar_t *unicodeString = [self unicodeString];
	size_t length = [self length];
	uint16_t *ret;
	size_t i, j;

	/* Allocate memory for the worst case */
	ret = [object allocMemoryForNItems: length * 2 + 1
				    ofSize: sizeof(uint16_t)];

	j = 0;

	for (i = 0; i < length; i++) {
		of_unichar_t c = unicodeString[i];

		if (c > 0x10FFFF)
			@throw [OFInvalidEncodingException
			    exceptionWithClass: isa];

		if (c > 0xFFFF) {
			c -= 0x10000;
			ret[j++] = of_bswap16_if_le(0xD800 | (c >> 10));
			ret[j++] = of_bswap16_if_le(0xDC00 | (c & 0x3FF));
		} else
			ret[j++] = of_bswap16_if_le(c);
	}

	ret[j] = 0;

	@try {
		ret = [object resizeMemory: ret
				  toNItems: j + 1
				    ofSize: sizeof(uint16_t)];
	} @catch (OFOutOfMemoryException *e) {
		/* We don't care, as we only tried to make it smaller */
	}

	[pool release];

	return ret;
}

- (void)writeToFile: (OFString*)path
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFFile *file;

	file = [OFFile fileWithPath: path
			       mode: @"wb"];
	[file writeString: self];

	[pool release];
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateLinesUsingBlock: (of_string_line_enumeration_block_t)block
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init], *pool2;
	const of_unichar_t *string = [self unicodeString];
	size_t i, last = 0, length = [self length];
	BOOL stop = NO, lastCarriageReturn = NO;

	pool2 = [[OFAutoreleasePool alloc] init];

	for (i = 0; i < length && !stop; i++) {
		if (lastCarriageReturn && string[i] == '\n') {
			lastCarriageReturn = NO;
			last++;

			continue;
		}

		if (string[i] == '\n' || string[i] == '\r') {
			block([self substringWithRange:
			    of_range(last, i - last)], &stop);
			last = i + 1;

			[pool2 releaseObjects];
		}

		lastCarriageReturn = (string[i] == '\r');
	}

	if (!stop)
		block([self substringWithRange: of_range(last, i - last)],
		    &stop);

	[pool release];
}
#endif
@end
