/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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
#include <ctype.h>

#include <sys/stat.h>

#import "OFString.h"
#import "OFString_UTF8.h"
#import "OFString_UTF8+Private.h"
#import "OFArray.h"
#import "OFDictionary.h"
#ifdef OF_HAVE_FILES
# import "OFFile.h"
#endif
#import "OFURL.h"
#ifdef OF_HAVE_SOCKETS
# import "OFHTTPClient.h"
# import "OFHTTPRequest.h"
# import "OFHTTPResponse.h"
#endif
#import "OFDataArray.h"
#import "OFXMLElement.h"

#ifdef OF_HAVE_SOCKETS
# import "OFHTTPRequestFailedException.h"
#endif
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"
#import "OFOpenFileFailedException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"
#import "OFUnsupportedProtocolException.h"

#import "autorelease.h"
#import "macros.h"
#import "of_asprintf.h"
#import "unicode.h"

/*
 * It seems strtod is buggy on Win32.
 * However, the MinGW version __strtod seems to be ok.
 */
#ifdef _WIN32
# define strtod __strtod
#endif

@interface OFString (OF_PRIVATE_CATEGORY)
- (size_t)OF_getCString: (char*)cString
	      maxLength: (size_t)maxLength
	       encoding: (of_string_encoding_t)encoding
		  lossy: (bool)lossy;
- (const char*)OF_cStringWithEncoding: (of_string_encoding_t)encoding
				lossy: (bool)lossy;
- (OFString*)OF_JSONRepresentationWithOptions: (int)options
					depth: (size_t)depth;
@end

extern bool of_unicode_to_iso_8859_15(const of_unichar_t*, char*, size_t, bool);
extern bool of_unicode_to_windows_1252(const of_unichar_t*, char*, size_t,
    bool);
extern bool of_unicode_to_codepage_437(const of_unichar_t*, char*, size_t,
    bool);

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

void _reference_to_OFConstantString(void)
{
	[OFConstantString class];
}

size_t
of_string_utf8_encode(of_unichar_t character, char *buffer)
{
	size_t i = 0;

	if (character < 0x80) {
		buffer[i] = character;
		return 1;
	} else if (character < 0x800) {
		buffer[i++] = 0xC0 | (character >> 6);
		buffer[i] = 0x80 | (character & 0x3F);
		return 2;
	} else if (character < 0x10000) {
		buffer[i++] = 0xE0 | (character >> 12);
		buffer[i++] = 0x80 | (character >> 6 & 0x3F);
		buffer[i] = 0x80 | (character & 0x3F);
		return 3;
	} else if (character < 0x110000) {
		buffer[i++] = 0xF0 | (character >> 18);
		buffer[i++] = 0x80 | (character >> 12 & 0x3F);
		buffer[i++] = 0x80 | (character >> 6 & 0x3F);
		buffer[i] = 0x80 | (character & 0x3F);
		return 4;
	}

	return 0;
}

size_t
of_string_utf8_decode(const char *buffer_, size_t length, of_unichar_t *ret)
{
	const uint8_t *buffer = (const uint8_t*)buffer_;

	if (!(*buffer & 0x80)) {
		*ret = buffer[0];
		return 1;
	}

	if ((*buffer & 0xE0) == 0xC0) {
		if OF_UNLIKELY (length < 2)
			return 0;

		*ret = ((buffer[0] & 0x1F) << 6) | (buffer[1] & 0x3F);
		return 2;
	}

	if ((*buffer & 0xF0) == 0xE0) {
		if OF_UNLIKELY (length < 3)
			return 0;

		*ret = ((buffer[0] & 0x0F) << 12) | ((buffer[1] & 0x3F) << 6) |
		    (buffer[2] & 0x3F);
		return 3;
	}

	if ((*buffer & 0xF8) == 0xF0) {
		if OF_UNLIKELY (length < 4)
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

static OFString*
standardizePath(OFArray *components, OFString *currentDirectory,
    OFString *parentDirectory, OFString *joinString)
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableArray *array;
	OFString *ret;
	bool done = false, startsWithEmpty, endsWithEmpty;

	array = [[components mutableCopy] autorelease];

	if ((startsWithEmpty = [[array firstObject] isEqual: @""]))
		[array removeObjectAtIndex: 0];
	endsWithEmpty = [[array lastObject] isEqual: @""];

	while (!done) {
		size_t i, length = [array count];

		done = true;

		for (i = 0; i < length; i++) {
			id object = [array objectAtIndex: i];
			id parent;

			if (i > 0)
				parent = [array objectAtIndex: i - 1];
			else
				parent = nil;

			if ([object isEqual: currentDirectory] ||
			   [object length] == 0) {
				[array removeObjectAtIndex: i];

				done = false;
				break;
			}

			if ([object isEqual: parentDirectory] &&
			    parent != nil &&
			    ![parent isEqual: parentDirectory]) {
				[array removeObjectsInRange:
				    of_range(i - 1, 2)];

				done = false;
				break;
			}
		}
	}

	if (startsWithEmpty)
		[array insertObject: @""
			    atIndex: 0];
	if (endsWithEmpty)
		[array addObject: @""];

	ret = [[array componentsJoinedByString: joinString] retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
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
	id string;
	size_t length;
	void *storage;

	length = strlen(UTF8String);
	string = of_alloc_object([OFString_UTF8 class],
	    length + 1, 1, &storage);

	return (id)[string OF_initWithUTF8String: UTF8String
					  length: length
					 storage: storage];
}

- initWithUTF8String: (const char*)UTF8String
	      length: (size_t)UTF8StringLength
{
	id string;
	void *storage;

	string = of_alloc_object([OFString_UTF8 class],
	    UTF8StringLength + 1, 1, &storage);

	return (id)[string OF_initWithUTF8String: UTF8String
					  length: UTF8StringLength
					 storage: storage];
}

- initWithUTF8StringNoCopy: (char*)UTF8String
	      freeWhenDone: (bool)freeWhenDone
{
	return (id)[[OFString_UTF8 alloc]
	    initWithUTF8StringNoCopy: UTF8String
			freeWhenDone: freeWhenDone];
}

- initWithCString: (const char*)cString
	 encoding: (of_string_encoding_t)encoding
{
	if (encoding == OF_STRING_ENCODING_UTF_8) {
		id string;
		size_t length;
		void *storage;

		length = strlen(cString);
		string = of_alloc_object([OFString_UTF8 class],
		    length + 1, 1, &storage);

		return (id)[string OF_initWithUTF8String: cString
						  length: length
						 storage: storage];
	}

	return (id)[[OFString_UTF8 alloc] initWithCString: cString
						 encoding: encoding];
}

- initWithCString: (const char*)cString
	 encoding: (of_string_encoding_t)encoding
	   length: (size_t)cStringLength
{
	if (encoding == OF_STRING_ENCODING_UTF_8) {
		id string;
		void *storage;

		string = of_alloc_object([OFString_UTF8 class],
		    cStringLength + 1, 1, &storage);

		return (id)[string OF_initWithUTF8String: cString
						  length: cStringLength
						 storage: storage];
	}

	return (id)[[OFString_UTF8 alloc] initWithCString: cString
						 encoding: encoding
						   length: cStringLength];
}

- initWithString: (OFString*)string
{
	return (id)[[OFString_UTF8 alloc] initWithString: string];
}

- initWithCharacters: (const of_unichar_t*)string
	      length: (size_t)length
{
	return (id)[[OFString_UTF8 alloc] initWithCharacters: string
						      length: length];
}

- initWithUTF16String: (const of_char16_t*)string
{
	return (id)[[OFString_UTF8 alloc] initWithUTF16String: string];
}

- initWithUTF16String: (const of_char16_t*)string
	       length: (size_t)length
{
	return (id)[[OFString_UTF8 alloc] initWithUTF16String: string
						       length: length];
}

- initWithUTF16String: (const of_char16_t*)string
	    byteOrder: (of_byte_order_t)byteOrder
{
	return (id)[[OFString_UTF8 alloc] initWithUTF16String: string
						    byteOrder: byteOrder];
}

- initWithUTF16String: (const of_char16_t*)string
	       length: (size_t)length
	    byteOrder: (of_byte_order_t)byteOrder
{
	return (id)[[OFString_UTF8 alloc] initWithUTF16String: string
						       length: length
						    byteOrder: byteOrder];
}

- initWithUTF32String: (const of_char32_t*)string
{
	return (id)[[OFString_UTF8 alloc] initWithUTF32String: string];
}

- initWithUTF32String: (const of_char32_t*)string
	       length: (size_t)length
{
	return (id)[[OFString_UTF8 alloc] initWithUTF32String: string
						       length: length];
}

- initWithUTF32String: (const of_char32_t*)string
	    byteOrder: (of_byte_order_t)byteOrder
{
	return (id)[[OFString_UTF8 alloc] initWithUTF32String: string
						    byteOrder: byteOrder];
}

- initWithUTF32String: (const of_char32_t*)string
	       length: (size_t)length
	    byteOrder: (of_byte_order_t)byteOrder
{
	return (id)[[OFString_UTF8 alloc] initWithUTF32String: string
						       length: length
						    byteOrder: byteOrder];
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

#ifdef OF_HAVE_FILES
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
#endif

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
	OF_UNRECOGNIZED_SELECTOR

	/* Get rid of a stupid warning */
	[super dealloc];
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

+ (instancetype)string
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)stringWithUTF8String: (const char*)UTF8String
{
	return [[[self alloc] initWithUTF8String: UTF8String] autorelease];
}

+ (instancetype)stringWithUTF8String: (const char*)UTF8String
			      length: (size_t)UTF8StringLength
{
	return [[[self alloc]
	    initWithUTF8String: UTF8String
			length: UTF8StringLength] autorelease];
}

+ (instancetype)stringWithUTF8StringNoCopy: (char*)UTF8String
			      freeWhenDone: (bool)freeWhenDone
{
	return [[[self alloc]
	    initWithUTF8StringNoCopy: UTF8String
			freeWhenDone: freeWhenDone] autorelease];
}

+ (instancetype)stringWithCString: (const char*)cString
			 encoding: (of_string_encoding_t)encoding
{
	return [[[self alloc] initWithCString: cString
				     encoding: encoding] autorelease];
}

+ (instancetype)stringWithCString: (const char*)cString
			 encoding: (of_string_encoding_t)encoding
			   length: (size_t)cStringLength
{
	return [[[self alloc] initWithCString: cString
				     encoding: encoding
				       length: cStringLength] autorelease];
}

+ (instancetype)stringWithString: (OFString*)string
{
	return [[[self alloc] initWithString: string] autorelease];
}

+ (instancetype)stringWithCharacters: (const of_unichar_t*)string
			      length: (size_t)length
{
	return [[[self alloc] initWithCharacters: string
					  length: length] autorelease];
}

+ (instancetype)stringWithUTF16String: (const of_char16_t*)string
{
	return [[[self alloc] initWithUTF16String: string] autorelease];
}

+ (instancetype)stringWithUTF16String: (const of_char16_t*)string
			       length: (size_t)length
{
	return [[[self alloc] initWithUTF16String: string
					   length: length] autorelease];
}

+ (instancetype)stringWithUTF16String: (const of_char16_t*)string
			    byteOrder: (of_byte_order_t)byteOrder
{
	return [[[self alloc] initWithUTF16String: string
					byteOrder: byteOrder] autorelease];
}

+ (instancetype)stringWithUTF16String: (const of_char16_t*)string
			       length: (size_t)length
			    byteOrder: (of_byte_order_t)byteOrder
{
	return [[[self alloc] initWithUTF16String: string
					   length: length
					byteOrder: byteOrder] autorelease];
}

+ (instancetype)stringWithUTF32String: (const of_char32_t*)string
{
	return [[[self alloc] initWithUTF32String: string] autorelease];
}

+ (instancetype)stringWithUTF32String: (const of_char32_t*)string
			       length: (size_t)length
{
	return [[[self alloc] initWithUTF32String: string
					   length: length] autorelease];
}

+ (instancetype)stringWithUTF32String: (const of_char32_t*)string
			    byteOrder: (of_byte_order_t)byteOrder
{
	return [[[self alloc] initWithUTF32String: string
					byteOrder: byteOrder] autorelease];
}

+ (instancetype)stringWithUTF32String: (const of_char32_t*)string
			       length: (size_t)length
			    byteOrder: (of_byte_order_t)byteOrder
{
	return [[[self alloc] initWithUTF32String: string
					   length: length
					byteOrder: byteOrder] autorelease];
}

+ (instancetype)stringWithFormat: (OFConstantString*)format, ...
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
+ (instancetype)stringWithContentsOfFile: (OFString*)path
{
	return [[[self alloc] initWithContentsOfFile: path] autorelease];
}

+ (instancetype)stringWithContentsOfFile: (OFString*)path
				encoding: (of_string_encoding_t)encoding
{
	return [[[self alloc] initWithContentsOfFile: path
					    encoding: encoding] autorelease];
}
#endif

+ (instancetype)stringWithContentsOfURL: (OFURL*)URL
{
	return [[[self alloc] initWithContentsOfURL: URL] autorelease];
}

+ (instancetype)stringWithContentsOfURL: (OFURL*)URL
			       encoding: (of_string_encoding_t)encoding
{
	return [[[self alloc] initWithContentsOfURL: URL
					   encoding: encoding] autorelease];
}

+ (OFString*)pathWithComponents: (OFArray*)components
{
	OFMutableString *ret = [OFMutableString string];
	void *pool = objc_autoreleasePoolPush();
	OFEnumerator *enumerator = [components objectEnumerator];
	OFString *component;

	if ((component = [enumerator nextObject]) != nil)
		[ret appendString: component];
	while ((component = [enumerator nextObject]) != nil) {
		[ret appendString: OF_PATH_DELIMITER_STRING];
		[ret appendString: component];
	}

	objc_autoreleasePoolPop(pool);

	return ret;
}

+ (of_string_encoding_t)nativeOSEncoding
{
	/* FIXME */
	return OF_STRING_ENCODING_UTF_8;
}

- init
{
	if (object_getClass(self) == [OFString class]) {
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

- initWithUTF8StringNoCopy: (char*)UTF8String
	      freeWhenDone: (bool)freeWhenDone
{
	return [self initWithUTF8String: UTF8String];
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
	OF_INVALID_INIT_METHOD
}

- initWithString: (OFString*)string
{
	OF_INVALID_INIT_METHOD
}

- initWithCharacters: (const of_unichar_t*)string
	      length: (size_t)length
{
	OF_INVALID_INIT_METHOD
}

- initWithUTF16String: (const of_char16_t*)string
{
	return [self initWithUTF16String: string
				  length: of_string_utf16_length(string)
			       byteOrder: OF_BYTE_ORDER_NATIVE];
}

- initWithUTF16String: (const of_char16_t*)string
	       length: (size_t)length
{
	return [self initWithUTF16String: string
				  length: length
			       byteOrder: OF_BYTE_ORDER_NATIVE];
}

- initWithUTF16String: (const of_char16_t*)string
	    byteOrder: (of_byte_order_t)byteOrder
{
	return [self initWithUTF16String: string
				  length: of_string_utf16_length(string)
			       byteOrder: byteOrder];
}

- initWithUTF16String: (const of_char16_t*)string
	       length: (size_t)length
	    byteOrder: (of_byte_order_t)byteOrder
{
	OF_INVALID_INIT_METHOD
}

- initWithUTF32String: (const of_char32_t*)string
{
	return [self initWithUTF32String: string
				  length: of_string_utf32_length(string)
			       byteOrder: OF_BYTE_ORDER_NATIVE];
}

- initWithUTF32String: (const of_char32_t*)string
	       length: (size_t)length
{
	return [self initWithUTF32String: string
				  length: length
			       byteOrder: OF_BYTE_ORDER_NATIVE];
}

- initWithUTF32String: (const of_char32_t*)string
	    byteOrder: (of_byte_order_t)byteOrder
{
	return [self initWithUTF32String: string
				  length: of_string_utf32_length(string)
			       byteOrder: byteOrder];
}

- initWithUTF32String: (const of_char32_t*)string
	       length: (size_t)length
	    byteOrder: (of_byte_order_t)byteOrder
{
	OF_INVALID_INIT_METHOD
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
	OF_INVALID_INIT_METHOD
}

#ifdef OF_HAVE_FILES
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

		if (stat([path cStringWithEncoding: [OFString
		    nativeOSEncoding]], &st) == -1)
			@throw [OFOpenFileFailedException
			    exceptionWithPath: path
					 mode: @"rb"];

		if (st.st_size > SIZE_MAX)
			@throw [OFOutOfRangeException exception];

		file = [[OFFile alloc] initWithPath: path
					       mode: @"rb"];

		@try {
			tmp = [self allocMemoryWithSize: (size_t)st.st_size];

			[file readIntoBuffer: tmp
				 exactLength: (size_t)st.st_size];
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
#endif

- initWithContentsOfURL: (OFURL*)URL
{
	return [self initWithContentsOfURL: URL
				  encoding: OF_STRING_ENCODING_AUTODETECT];
}

- initWithContentsOfURL: (OFURL*)URL
	       encoding: (of_string_encoding_t)encoding
{
	void *pool;
#ifdef OF_HAVE_SOCKETS
	OFHTTPClient *client;
	OFHTTPRequest *request;
	OFHTTPResponse *response;
	OFDictionary *headers;
	OFString *contentType, *contentLength;
	OFDataArray *data;
#endif
	Class c;

	c = [self class];
	[self release];

	pool = objc_autoreleasePoolPush();

	if ([[URL scheme] isEqual: @"file"]) {
#ifdef OF_HAVE_FILES
		if (encoding == OF_STRING_ENCODING_AUTODETECT)
			encoding = OF_STRING_ENCODING_UTF_8;

		self = [[c alloc] initWithContentsOfFile: [URL path]
						encoding: encoding];
		objc_autoreleasePoolPop(pool);
		return self;
#else
		@throw [OFUnsupportedProtocolException exceptionWithURL: URL];
#endif
	}

#ifdef OF_HAVE_SOCKETS
	client = [OFHTTPClient client];
	request = [OFHTTPRequest requestWithURL: URL];
	response = [client performRequest: request];

	if ([response statusCode] != 200)
		@throw [OFHTTPRequestFailedException
		    exceptionWithRequest: request
				response: response];

	headers = [response headers];

	if (encoding == OF_STRING_ENCODING_AUTODETECT &&
	    (contentType = [headers objectForKey: @"Content-Type"]) != nil) {
		contentType = [contentType lowercaseString];

		if ([contentType hasSuffix: @"charset=utf-8"])
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

	data = [response readDataArrayTillEndOfStream];

	if ((contentLength = [headers objectForKey: @"Content-Length"]) != nil)
		if ([data count] != (size_t)[contentLength decimalValue])
			@throw [OFTruncatedDataException exception];

	self = [[c alloc] initWithCString: (char*)[data items]
				 encoding: encoding
				   length: [data count]];
#else
	@throw [OFUnsupportedProtocolException exceptionWithURL: URL];
#endif

	objc_autoreleasePoolPop(pool);

	return self;
}

- initWithSerialization: (OFXMLElement*)element
{
	@try {
		void *pool = objc_autoreleasePoolPush();

		if (![[element namespace] isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException exception];

		if ([self isKindOfClass: [OFMutableString class]]) {
			if (![[element name] isEqual: @"OFMutableString"])
				@throw [OFInvalidArgumentException exception];
		} else {
			if (![[element name] isEqual: @"OFString"])
				@throw [OFInvalidArgumentException exception];
		}

		self = [self initWithString: [element stringValue]];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (size_t)OF_getCString: (char*)cString
	      maxLength: (size_t)maxLength
	       encoding: (of_string_encoding_t)encoding
		  lossy: (bool)lossy
{
	const of_unichar_t *characters = [self characters];
	size_t i, length = [self length];

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
				cString[i] = (char)characters[i];
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
				cString[i] = (uint8_t)characters[i];
		}

		cString[i] = '\0';

		return length;
	case OF_STRING_ENCODING_ISO_8859_15:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!of_unicode_to_iso_8859_15(characters, cString, length,
		    lossy))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
	case OF_STRING_ENCODING_WINDOWS_1252:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!of_unicode_to_windows_1252(characters, cString, length,
		    lossy))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
	case OF_STRING_ENCODING_CODEPAGE_437:
		if (length + 1 > maxLength)
			@throw [OFOutOfRangeException exception];

		if (!of_unicode_to_codepage_437(characters, cString, length,
		    lossy))
			@throw [OFInvalidEncodingException exception];

		cString[length] = '\0';

		return length;
	default:
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];
	}
}

- (size_t)getCString: (char*)cString
	   maxLength: (size_t)maxLength
	    encoding: (of_string_encoding_t)encoding
{
	return [self OF_getCString: cString
			 maxLength: maxLength
			  encoding: encoding
			     lossy: false];
}

- (size_t)getLossyCString: (char*)cString
		maxLength: (size_t)maxLength
		 encoding: (of_string_encoding_t)encoding
{
	return [self OF_getCString: cString
			 maxLength: maxLength
			  encoding: encoding
			     lossy: true];
}

- (const char*)OF_cStringWithEncoding: (of_string_encoding_t)encoding
				lossy: (bool)lossy
{
	OFObject *object = [[[OFObject alloc] init] autorelease];
	size_t length = [self length];
	char *cString;

	switch (encoding) {
	case OF_STRING_ENCODING_UTF_8:;
		size_t cStringLength;

		cString = [object allocMemoryWithSize: (length * 4) + 1];

		cStringLength = [self OF_getCString: cString
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
	case OF_STRING_ENCODING_ISO_8859_15:
	case OF_STRING_ENCODING_WINDOWS_1252:
	case OF_STRING_ENCODING_CODEPAGE_437:
		cString = [object allocMemoryWithSize: length + 1];

		[self OF_getCString: cString
			  maxLength: length + 1
			   encoding: encoding
			      lossy: lossy];

		break;
	default:
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];
	}

	return cString;
}

- (const char*)cStringWithEncoding: (of_string_encoding_t)encoding
{
	return [self OF_cStringWithEncoding: encoding
				      lossy: false];
}

- (const char*)lossyCStringWithEncoding: (of_string_encoding_t)encoding
{
	return [self OF_cStringWithEncoding: encoding
				      lossy: true];
}

- (const char*)UTF8String
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
		size_t i, length, UTF8StringLength = 0;

		characters = [self characters];
		length = [self length];

		for (i = 0; i < length; i++) {
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
	case OF_STRING_ENCODING_ISO_8859_15:
	case OF_STRING_ENCODING_WINDOWS_1252:
	case OF_STRING_ENCODING_CODEPAGE_437:
		return [self length];
	default:
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];
	}
}

- (size_t)UTF8StringLength
{
	return [self cStringLengthWithEncoding: OF_STRING_ENCODING_UTF_8];
}

- (of_unichar_t)characterAtIndex: (size_t)index
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)getCharacters: (of_unichar_t*)buffer
	      inRange: (of_range_t)range
{
	size_t i;

	for (i = 0; i < range.length; i++)
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
	length = [self length];

	if ([otherString length] != length)
		return false;

	pool = objc_autoreleasePoolPush();

	characters = [self characters];
	otherCharacters = [otherString characters];

	if (memcmp(characters, otherCharacters,
	    length * sizeof(of_unichar_t)) != 0) {
		objc_autoreleasePoolPop(pool);
		return false;
	}

	objc_autoreleasePoolPop(pool);

	return true;
}

- copy
{
	return [self retain];
}

- mutableCopy
{
	return [[OFMutableString alloc] initWithString: self];
}

- (of_comparison_result_t)compare: (id <OFComparing>)object
{
	void *pool;
	OFString *otherString;
	const of_unichar_t *characters, *otherCharacters;
	size_t i, minimumLength;

	if (object == self)
		return OF_ORDERED_SAME;

	if (![object isKindOfClass: [OFString class]])
		@throw [OFInvalidArgumentException exception];

	otherString = (OFString*)object;
	minimumLength = ([self length] > [otherString length]
	    ? [otherString length] : [self length]);

	pool = objc_autoreleasePoolPush();

	characters = [self characters];
	otherCharacters = [otherString characters];

	for (i = 0; i < minimumLength; i++) {
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

	if ([self length] > [otherString length])
		return OF_ORDERED_DESCENDING;
	if ([self length] < [otherString length])
		return OF_ORDERED_ASCENDING;

	return OF_ORDERED_SAME;
}

- (of_comparison_result_t)caseInsensitiveCompare: (OFString*)otherString
{
	void *pool = objc_autoreleasePoolPush();
	const of_unichar_t *characters, *otherCharacters;
	size_t i, length, otherLength, minimumLength;

	if (otherString == self)
		return OF_ORDERED_SAME;

	characters = [self characters];
	otherCharacters = [otherString characters];
	length = [self length];
	otherLength = [otherString length];

	minimumLength = (length > otherLength ? otherLength : length);

	for (i = 0; i < minimumLength; i++) {
		of_unichar_t c = characters[i];
		of_unichar_t oc = otherCharacters[i];

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
	const of_unichar_t *characters = [self characters];
	size_t i, length = [self length];
	uint32_t hash;

	OF_HASH_INIT(hash);

	for (i = 0; i < length; i++) {
		const of_unichar_t c = characters[i];

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

- (OFString*)JSONRepresentation
{
	return [self OF_JSONRepresentationWithOptions: 0
						depth: 0];
}

- (OFString*)JSONRepresentationWithOptions: (int)options
{
	return [self OF_JSONRepresentationWithOptions: options
						depth: 0];
}

- (OFString*)OF_JSONRepresentationWithOptions: (int)options
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
			const char *cString = [self UTF8String];

			if ((!isalpha((int)cString[0]) && cString[0] != '_' &&
			    cString[0] != '$') ||
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

- (OFDataArray*)messagePackRepresentation
{
	OFDataArray *data;
	size_t length;

	length = [self UTF8StringLength];

	if (length <= 31) {
		uint8_t tmp = 0xA0 | ((uint8_t)length & 0x1F);

		data = [OFDataArray dataArrayWithItemSize: 1
						 capacity: length + 1];

		[data addItem: &tmp];
	} else if (length <= UINT8_MAX) {
		uint8_t type = 0xD9;
		uint8_t tmp = (uint8_t)length;

		data = [OFDataArray dataArrayWithItemSize: 1
						 capacity: length + 2];

		[data addItem: &type];
		[data addItem: &tmp];
	} else if (length <= UINT16_MAX) {
		uint8_t type = 0xDA;
		uint16_t tmp = OF_BSWAP16_IF_LE((uint16_t)length);

		data = [OFDataArray dataArrayWithItemSize: 1
						 capacity: length + 3];

		[data addItem: &type];
		[data addItems: &tmp
			 count: sizeof(tmp)];
	} else if (length <= UINT32_MAX) {
		uint8_t type = 0xDB;
		uint32_t tmp = OF_BSWAP32_IF_LE((uint32_t)length);

		data = [OFDataArray dataArrayWithItemSize: 1
						 capacity: length + 5];

		[data addItem: &type];
		[data addItems: &tmp
			 count: sizeof(tmp)];
	} else
		@throw [OFOutOfRangeException exception];

	[data addItems: [self UTF8String]
		 count: length];

	return data;
}

- (of_range_t)rangeOfString: (OFString*)string
{
	return [self rangeOfString: string
			   options: 0
			     range: of_range(0, [self length])];
}

- (of_range_t)rangeOfString: (OFString*)string
		    options: (int)options
{
	return [self rangeOfString: string
			   options: options
			     range: of_range(0, [self length])];
}

- (of_range_t)rangeOfString: (OFString*)string
		    options: (int)options
		      range: (of_range_t)range
{
	void *pool;
	const of_unichar_t *searchCharacters;
	of_unichar_t *characters;
	size_t i, searchLength;

	if ((searchLength = [string length]) == 0)
		return of_range(0, 0);

	if (searchLength > range.length)
		return of_range(OF_NOT_FOUND, 0);

	if (range.length > SIZE_MAX / sizeof(of_unichar_t))
		@throw [OFOutOfRangeException exception];

	pool = objc_autoreleasePoolPush();

	searchCharacters = [string characters];
	characters = malloc(range.length * sizeof(of_unichar_t));

	if (characters == NULL)
		@throw [OFOutOfMemoryException exceptionWithRequestedSize:
		    range.length * sizeof(of_unichar_t)];

	@try {
		[self getCharacters: characters
			    inRange: range];

		if (options & OF_STRING_SEARCH_BACKWARDS) {
			for (i = range.length - searchLength;; i--) {
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
			for (i = 0; i <= range.length - searchLength; i++) {
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

- (bool)containsString: (OFString*)string
{
	void *pool;
	const of_unichar_t *characters, *searchCharacters;
	size_t i, length, searchLength;

	if ((searchLength = [string length]) == 0)
		return true;

	if (searchLength > (length = [self length]))
		return false;

	pool = objc_autoreleasePoolPush();

	characters = [self characters];
	searchCharacters = [string characters];

	for (i = 0; i <= length - searchLength; i++) {
		if (memcmp(characters + i, searchCharacters,
		    searchLength * sizeof(of_unichar_t)) == 0) {
			objc_autoreleasePoolPop(pool);
			return true;
		}
	}

	objc_autoreleasePoolPop(pool);

	return false;
}

- (OFString*)substringWithRange: (of_range_t)range
{
	void *pool;
	OFString *ret;

	if (range.length > SIZE_MAX - range.location ||
	    range.location + range.length > [self length])
		@throw [OFOutOfRangeException exception];

	pool = objc_autoreleasePoolPush();
	ret = [[OFString alloc]
	    initWithCharacters: [self characters] + range.location
			length: range.length];
	objc_autoreleasePoolPop(pool);

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

- (OFString*)stringByAppendingFormat: (OFConstantString*)format, ...
{
	OFString *ret;
	va_list arguments;

	va_start(arguments, format);
	ret = [self stringByAppendingFormat: format
				  arguments: arguments];
	va_end(arguments);

	return ret;
}

- (OFString*)stringByAppendingFormat: (OFConstantString*)format
			   arguments: (va_list)arguments
{
	OFMutableString *new;

	new = [OFMutableString stringWithString: self];
	[new appendFormat: format
		arguments: arguments];

	[new makeImmutable];

	return new;
}

- (OFString*)stringByAppendingPathComponent: (OFString*)component
{
	void *pool = objc_autoreleasePoolPush();
	OFString *ret;

	ret = [OFString pathWithComponents:
	    [OFArray arrayWithObjects: self, component, nil]];

	[ret retain];
	objc_autoreleasePoolPop(pool);
	return [ret autorelease];
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

- (OFString*)uppercaseString
{
	OFMutableString *new = [[self mutableCopy] autorelease];

	[new uppercase];

	[new makeImmutable];

	return new;
}

- (OFString*)lowercaseString
{
	OFMutableString *new = [[self mutableCopy] autorelease];

	[new lowercase];

	[new makeImmutable];

	return new;
}

- (OFString*)capitalizedString
{
	OFMutableString *new = [[self mutableCopy] autorelease];

	[new capitalize];

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

- (bool)hasPrefix: (OFString*)prefix
{
	of_unichar_t *tmp;
	const of_unichar_t *prefixCharacters;
	size_t prefixLength;
	bool hasPrefix;

	if ((prefixLength = [prefix length]) > [self length])
		return false;

	tmp = [self allocMemoryWithSize: sizeof(of_unichar_t)
				  count: prefixLength];
	@try {
		void *pool = objc_autoreleasePoolPush();

		[self getCharacters: tmp
			    inRange: of_range(0, prefixLength)];

		prefixCharacters = [prefix characters];
		hasPrefix = (memcmp(tmp, prefixCharacters,
		    prefixLength * sizeof(of_unichar_t)) == 0);

		objc_autoreleasePoolPop(pool);
	} @finally {
		[self freeMemory: tmp];
	}

	return hasPrefix;
}

- (bool)hasSuffix: (OFString*)suffix
{
	of_unichar_t *tmp;
	const of_unichar_t *suffixCharacters;
	size_t length, suffixLength;
	bool hasSuffix;

	if ((suffixLength = [suffix length]) > [self length])
		return false;

	length = [self length];

	tmp = [self allocMemoryWithSize: sizeof(of_unichar_t)
				  count: suffixLength];
	@try {
		void *pool = objc_autoreleasePoolPush();

		[self getCharacters: tmp
			    inRange: of_range(length - suffixLength,
					 suffixLength)];

		suffixCharacters = [suffix characters];
		hasSuffix = (memcmp(tmp, suffixCharacters,
		    suffixLength * sizeof(of_unichar_t)) == 0);

		objc_autoreleasePoolPop(pool);
	} @finally {
		[self freeMemory: tmp];
	}

	return hasSuffix;
}

- (OFArray*)componentsSeparatedByString: (OFString*)delimiter
{
	return [self componentsSeparatedByString: delimiter
					 options: 0];
}

- (OFArray*)componentsSeparatedByString: (OFString*)delimiter
				options: (int)options
{
	void *pool;
	OFMutableArray *array = [OFMutableArray array];
	const of_unichar_t *characters, *delimiterCharacters;
	bool skipEmpty = (options & OF_STRING_SKIP_EMPTY);
	size_t length = [self length];
	size_t delimiterLength = [delimiter length];
	size_t i, last;
	OFString *component;

	pool = objc_autoreleasePoolPush();

	characters = [self characters];
	delimiterCharacters = [delimiter characters];

	if (delimiterLength > length) {
		[array addObject: [[self copy] autorelease]];
		[array makeImmutable];

		objc_autoreleasePoolPop(pool);

		return array;
	}

	for (i = 0, last = 0; i <= length - delimiterLength; i++) {
		if (memcmp(characters + i, delimiterCharacters,
		    delimiterLength * sizeof(of_unichar_t)) != 0)
			continue;

		component = [self substringWithRange: of_range(last, i - last)];
		if (!skipEmpty || [component length] > 0)
			[array addObject: component];

		i += delimiterLength - 1;
		last = i + 1;
	}
	component = [self substringWithRange: of_range(last, length - last)];
	if (!skipEmpty || [component length] > 0)
		[array addObject: component];

	[array makeImmutable];

	objc_autoreleasePoolPop(pool);

	return array;
}

- (OFArray*)pathComponents
{
	OFMutableArray *ret;
	void *pool;
	const of_unichar_t *characters;
	size_t i, last = 0, length = [self length];

	ret = [OFMutableArray array];

	if (length == 0)
		return ret;

	pool = objc_autoreleasePoolPush();

	characters = [self characters];

	if (OF_IS_PATH_DELIMITER(characters[length - 1]))
		length--;

	for (i = 0; i < length; i++) {
		if (OF_IS_PATH_DELIMITER(characters[i])) {
			[ret addObject: [self substringWithRange:
			    of_range(last, i - last)]];

			last = i + 1;
		}
	}

	[ret addObject: [self substringWithRange: of_range(last, i - last)]];

	[ret makeImmutable];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (OFString*)lastPathComponent
{
	void *pool;
	const of_unichar_t *characters;
	size_t length = [self length];
	ssize_t i;

	if (length == 0)
		return @"";

	pool = objc_autoreleasePoolPush();

	characters = [self characters];

	if (OF_IS_PATH_DELIMITER(characters[length - 1]))
		length--;

	for (i = length - 1; i >= 0; i--) {
		if (OF_IS_PATH_DELIMITER(characters[i])) {
			i++;
			break;
		}
	}

	objc_autoreleasePoolPop(pool);

	/*
	 * Only one component, but the trailing delimiter might have been
	 * removed, so return a new string anyway.
	 */
	if (i < 0)
		i = 0;

	return [self substringWithRange: of_range(i, length - i)];
}

- (OFString*)pathExtension
{
	void *pool = objc_autoreleasePoolPush();
	OFString *ret, *fileName;
	size_t pos;

	fileName = [self lastPathComponent];
	pos = [fileName rangeOfString: @"."
			      options: OF_STRING_SEARCH_BACKWARDS].location;
	if (pos == OF_NOT_FOUND || pos == 0)
		return @"";

	ret = [fileName substringWithRange:
	    of_range(pos + 1, [fileName length] - pos - 1)];

	[ret retain];
	objc_autoreleasePoolPop(pool);
	return [ret autorelease];
}

- (OFString*)stringByDeletingLastPathComponent
{
	void *pool;
	const of_unichar_t *characters;
	size_t i, length = [self length];

	if (length == 0)
		return @"";

	pool = objc_autoreleasePoolPush();

	characters = [self characters];

	if (OF_IS_PATH_DELIMITER(characters[length - 1]))
		length--;

	if (length == 0) {
		objc_autoreleasePoolPop(pool);
		return [self substringWithRange: of_range(0, 1)];
	}

	for (i = length - 1; i >= 1; i--) {
		if (OF_IS_PATH_DELIMITER(characters[i])) {
			objc_autoreleasePoolPop(pool);
			return [self substringWithRange: of_range(0, i)];
		}
	}

	if (OF_IS_PATH_DELIMITER(characters[0])) {
		objc_autoreleasePoolPop(pool);
		return [self substringWithRange: of_range(0, 1)];
	}

	objc_autoreleasePoolPop(pool);

	return OF_PATH_CURRENT_DIRECTORY;
}

- (OFString*)stringByDeletingPathExtension
{
	void *pool;
	OFMutableArray *components;
	OFString *ret, *fileName;
	size_t pos;

	if ([self length] == 0)
		return [[self copy] autorelease];

	pool = objc_autoreleasePoolPush();
	components = [[[self pathComponents] mutableCopy] autorelease];
	fileName = [components lastObject];

	pos = [fileName rangeOfString: @"."
			      options: OF_STRING_SEARCH_BACKWARDS].location;
	if (pos == OF_NOT_FOUND || pos == 0) {
		objc_autoreleasePoolPop(pool);
		return [[self copy] autorelease];
	}

	fileName = [fileName substringWithRange: of_range(0, pos)];
	[components replaceObjectAtIndex: [components count] - 1
			      withObject: fileName];

	ret = [OFString pathWithComponents: components];

	[ret retain];
	objc_autoreleasePoolPop(pool);
	return [ret autorelease];
}

- (OFString*)stringByStandardizingPath
{
	return standardizePath([self pathComponents],
	    OF_PATH_CURRENT_DIRECTORY, OF_PATH_PARENT_DIRECTORY,
	    OF_PATH_DELIMITER_STRING);
}

- (OFString*)stringByStandardizingURLPath
{
	return standardizePath([self componentsSeparatedByString: @"/"],
	    @".", @"..", @"/");
}

- (intmax_t)decimalValue
{
	void *pool = objc_autoreleasePoolPush();
	const of_unichar_t *characters = [self characters];
	size_t length = [self length];
	int i = 0;
	intmax_t value = 0;
	bool expectWhitespace = false;

	while (length > 0 && (*characters == ' ' || *characters == '\t' ||
	    *characters == '\n' || *characters == '\r' ||
	    *characters == '\f')) {
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
			if (characters[i] != ' ' && characters[i] != '\t' &&
			    characters[i] != '\n' && characters[i] != '\r' &&
			    characters[i] != '\f')
				@throw [OFInvalidFormatException exception];
			continue;
		}

		if (characters[i] >= '0' && characters[i] <= '9') {
			if (INTMAX_MAX / 10 < value ||
			    INTMAX_MAX - value * 10 < characters[i] - '0')
				@throw [OFOutOfRangeException exception];

			value = (value * 10) + (characters[i] - '0');
		} else if (characters[i] == ' ' || characters[i] == '\t' ||
		    characters[i] == '\n' || characters[i] == '\r' ||
		    characters[i] == '\f')
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
	const of_unichar_t *characters = [self characters];
	size_t length = [self length];
	int i = 0;
	uintmax_t value = 0;
	bool expectWhitespace = false, foundValue = false;

	while (length > 0 && (*characters == ' ' || *characters == '\t' ||
	    *characters == '\n' || *characters == '\r' ||
	    *characters == '\f')) {
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
			if (characters[i] != ' ' && characters[i] != '\t' &&
			    characters[i] != '\n' && characters[i] != '\r' &&
			    characters[i] != '\f')
				@throw [OFInvalidFormatException exception];
			continue;
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
		} else if (characters[i] == 'h' || characters[i] == ' ' ||
		    characters[i] == '\t' || characters[i] == '\n' ||
		    characters[i] == '\r' || characters[i] == '\f') {
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

- (float)floatValue
{
	void *pool = objc_autoreleasePoolPush();
	const char *UTF8String = [self UTF8String];
	char *endPointer = NULL;
	float value;

	while (*UTF8String == ' ' || *UTF8String == '\t' ||
	    *UTF8String == '\n' || *UTF8String == '\r' || *UTF8String == '\f')
		UTF8String++;

	value = strtof(UTF8String, &endPointer);

	/* Check if there are any invalid chars left */
	if (endPointer != NULL)
		for (; *endPointer != '\0'; endPointer++)
			if (*endPointer != ' ' && *endPointer != '\t' &&
			    *endPointer != '\n' && *endPointer != '\r' &&
			    *endPointer != '\f')
				@throw [OFInvalidFormatException exception];

	objc_autoreleasePoolPop(pool);

	return value;
}

- (double)doubleValue
{
	void *pool = objc_autoreleasePoolPush();
	const char *UTF8String = [self UTF8String];
	char *endPointer = NULL;
	double value;

	while (*UTF8String == ' ' || *UTF8String == '\t' ||
	    *UTF8String == '\n' || *UTF8String == '\r' || *UTF8String == '\f')
		UTF8String++;

	value = strtod(UTF8String, &endPointer);

	/* Check if there are any invalid chars left */
	if (endPointer != NULL)
		for (; *endPointer != '\0'; endPointer++)
			if (*endPointer != ' ' && *endPointer != '\t' &&
			    *endPointer != '\n' && *endPointer != '\r' &&
			    *endPointer != '\f')
				@throw [OFInvalidFormatException exception];

	objc_autoreleasePoolPop(pool);

	return value;
}

- (const of_unichar_t*)characters
{
	OFObject *object = [[[OFObject alloc] init] autorelease];
	size_t length = [self length];
	of_unichar_t *ret;

	ret = [object allocMemoryWithSize: sizeof(of_unichar_t)
				    count: length];
	[self getCharacters: ret
		    inRange: of_range(0, length)];

	return ret;
}

- (const of_char16_t*)UTF16String
{
	return [self UTF16StringWithByteOrder: OF_BYTE_ORDER_NATIVE];
}

- (const of_char16_t*)UTF16StringWithByteOrder: (of_byte_order_t)byteOrder
{
	OFObject *object = [[[OFObject alloc] init] autorelease];
	void *pool = objc_autoreleasePoolPush();
	const of_unichar_t *characters = [self characters];
	size_t length = [self length];
	of_char16_t *ret;
	size_t i, j;
	bool swap = (byteOrder != OF_BYTE_ORDER_NATIVE);

	/* Allocate memory for the worst case */
	ret = [object allocMemoryWithSize: sizeof(of_char16_t)
				    count: (length + 1) * 2];

	j = 0;

	for (i = 0; i < length; i++) {
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
	const of_unichar_t *characters = [self characters];
	size_t i, length, UTF16StringLength;

	length = UTF16StringLength = [self length];

	for (i = 0; i < length; i++)
		if (characters[i] > 0xFFFF)
			UTF16StringLength++;

	return UTF16StringLength;
}

- (const of_char32_t*)UTF32String
{
	return [self UTF32StringWithByteOrder: OF_BYTE_ORDER_NATIVE];
}

- (const of_char32_t*)UTF32StringWithByteOrder: (of_byte_order_t)byteOrder
{
	OFObject *object = [[[OFObject alloc] init] autorelease];
	size_t length = [self length];
	of_char32_t *ret;

	ret = [object allocMemoryWithSize: sizeof(of_char32_t)
				    count: length + 1];
	[self getCharacters: ret
		    inRange: of_range(0, length)];
	ret[length] = 0;

	if (byteOrder != OF_BYTE_ORDER_NATIVE) {
		size_t i;

		for (i = 0; i < length; i++)
			ret[i] = OF_BSWAP32(ret[i]);
	}

	return ret;
}

#ifdef OF_HAVE_FILES
- (void)writeToFile: (OFString*)path
{
	return [self writeToFile: path
			encoding: OF_STRING_ENCODING_UTF_8];
}

- (void)writeToFile: (OFString*)path
	   encoding: (of_string_encoding_t)encoding
{
	void *pool = objc_autoreleasePoolPush();
	OFFile *file;

	file = [OFFile fileWithPath: path
			       mode: @"wb"];
	[file writeString: self
		 encoding: encoding];

	objc_autoreleasePoolPop(pool);
}
#endif

#ifdef OF_HAVE_BLOCKS
- (void)enumerateLinesUsingBlock: (of_string_line_enumeration_block_t)block
{
	void *pool = objc_autoreleasePoolPush();
	const of_unichar_t *characters = [self characters];
	size_t i, last = 0, length = [self length];
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
