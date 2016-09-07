/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

#include <stdio.h>
#include <string.h>
#include <limits.h>

#import "OFDataArray.h"
#import "OFString.h"
#ifdef OF_HAVE_FILES
# import "OFFile.h"
# import "OFFileManager.h"
#endif
#import "OFURL.h"
#ifdef OF_HAVE_SOCKETS
# import "OFHTTPClient.h"
# import "OFHTTPRequest.h"
# import "OFHTTPResponse.h"
#endif
#import "OFDictionary.h"
#import "OFXMLElement.h"
#import "OFSystemInfo.h"

#ifdef OF_HAVE_SOCKETS
# import "OFHTTPRequestFailedException.h"
#endif
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFInvalidServerReplyException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"
#import "OFUnsupportedProtocolException.h"

#import "base64.h"

/* References for static linking */
void
_references_to_categories_of_OFDataArray(void)
{
	_OFDataArray_CryptoHashing_reference = 1;
	_OFDataArray_MessagePackValue_reference = 1;
}

@implementation OFDataArray
@synthesize itemSize = _itemSize;

+ (instancetype)dataArray
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)dataArrayWithItemSize: (size_t)itemSize
{
	return [[[self alloc] initWithItemSize: itemSize] autorelease];
}

+ (instancetype)dataArrayWithCapacity: (size_t)capacity
{
	return [[[self alloc] initWithCapacity: capacity] autorelease];
}

+ (instancetype)dataArrayWithItemSize: (size_t)itemSize
			     capacity: (size_t)capacity
{
	return [[[self alloc] initWithItemSize: itemSize
				      capacity: capacity] autorelease];
}

#ifdef OF_HAVE_FILES
+ (instancetype)dataArrayWithContentsOfFile: (OFString*)path
{
	return [[[self alloc] initWithContentsOfFile: path] autorelease];
}
#endif

#if defined(OF_HAVE_FILES) || defined(OF_HAVE_SOCKETS)
+ (instancetype)dataArrayWithContentsOfURL: (OFURL*)URL
{
	return [[[self alloc] initWithContentsOfURL: URL] autorelease];
}
#endif

+ (instancetype)dataArrayWithStringRepresentation: (OFString*)string
{
	return [[[self alloc]
	    initWithStringRepresentation: string] autorelease];
}

+ (instancetype)dataArrayWithBase64EncodedString: (OFString*)string
{
	return [[[self alloc] initWithBase64EncodedString: string] autorelease];
}

- init
{
	self = [super init];

	_itemSize = 1;

	return self;
}

- initWithItemSize: (size_t)itemSize
{
	self = [super init];

	_itemSize = itemSize;

	return self;
}

- initWithCapacity: (size_t)capacity
{
	return [self initWithItemSize: 1
			     capacity: capacity];
}

- initWithItemSize: (size_t)itemSize
	  capacity: (size_t)capacity
{
	self = [super init];

	@try {
		if (itemSize == 0)
			@throw [OFInvalidArgumentException exception];

		_items = [self allocMemoryWithSize: itemSize
					     count: capacity];

		_itemSize = itemSize;
		_capacity = capacity;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

#ifdef OF_HAVE_FILES
- initWithContentsOfFile: (OFString*)path
{
	@try {
		OFFile *file = [[OFFile alloc] initWithPath: path
						       mode: @"rb"];
		of_offset_t size = [[OFFileManager defaultManager]
		    sizeOfFileAtPath: path];

		if (sizeof(of_offset_t) > sizeof(size_t) &&
		    size > (of_offset_t)SIZE_MAX)
			@throw [OFOutOfRangeException exception];

		self = [self initWithItemSize: 1
				     capacity: (size_t)size];

		@try {
			size_t pageSize = [OFSystemInfo pageSize];
			char *buffer = [self allocMemoryWithSize: pageSize];

			while (![file isAtEndOfStream]) {
				size_t length;

				length = [file readIntoBuffer: buffer
						       length: pageSize];
				[self addItems: buffer
					 count: length];
			}

			[self freeMemory: buffer];
		} @finally {
			[file release];
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}
#endif

#if defined(OF_HAVE_FILES) || defined(OF_HAVE_SOCKETS)
- initWithContentsOfURL: (OFURL*)URL
{
	void *pool;
	OFString *scheme;

	pool = objc_autoreleasePoolPush();

	scheme = [URL scheme];

# ifdef OF_HAVE_FILES
	if ([scheme isEqual: @"file"])
		self = [self initWithContentsOfFile: [URL path]];
	else
# endif
# ifdef OF_HAVE_SOCKETS
	if ([scheme isEqual: @"http"] || [scheme isEqual: @"https"]) {
		self = [self init];

		@try {
			OFHTTPClient *client = [OFHTTPClient client];
			OFHTTPRequest *request = [OFHTTPRequest
			    requestWithURL: URL];
			OFHTTPResponse *response = [client
			    performRequest: request];
			size_t pageSize;
			char *buffer;
			OFDictionary *headers;
			OFString *contentLengthString;

			if ([response statusCode] != 200)
				@throw [OFHTTPRequestFailedException
				    exceptionWithRequest: request
						response: response];

			pageSize = [OFSystemInfo pageSize];
			buffer = [self allocMemoryWithSize: pageSize];

			@try {
				while (![response isAtEndOfStream]) {
					size_t length;

					length = [response
					    readIntoBuffer: buffer
						    length: pageSize];
					[self addItems: buffer
						 count: length];
				}
			} @finally {
				[self freeMemory: buffer];
			}

			headers = [response headers];
			if ((contentLengthString =
			    [headers objectForKey: @"Content-Length"]) != nil) {
				intmax_t contentLength =
				    [contentLengthString decimalValue];

				if (contentLength < 0)
					@throw [OFInvalidServerReplyException
					    exception];

				if ((uintmax_t)[self count] !=
				    (uintmax_t)contentLength)
					@throw [OFTruncatedDataException
					    exception];
			}
		} @catch (id e) {
			[self release];
			@throw e;
		}
	} else
# endif
		@throw [OFUnsupportedProtocolException exceptionWithURL: URL];

	objc_autoreleasePoolPop(pool);

	return self;
}
#endif

- initWithStringRepresentation: (OFString*)string
{
	@try {
		const char *cString;
		size_t count;

		count = [string
		    cStringLengthWithEncoding: OF_STRING_ENCODING_ASCII];

		if (count % 2 != 0)
			@throw [OFInvalidFormatException exception];

		count /= 2;

		self = [self initWithCapacity: count];

		cString = [string
		    cStringWithEncoding: OF_STRING_ENCODING_ASCII];

		for (size_t i = 0; i < count; i++) {
			uint8_t c1 = cString[2 * i];
			uint8_t c2 = cString[2 * i + 1];
			uint8_t byte;

			if (c1 >= '0' && c1 <= '9')
				byte = (c1 - '0') << 4;
			else if (c1 >= 'a' && c1 <= 'f')
				byte = (c1 - 'a' + 10) << 4;
			else if (c1 >= 'A' && c1 <= 'F')
				byte = (c1 - 'A' + 10) << 4;
			else
				@throw [OFInvalidFormatException exception];

			if (c2 >= '0' && c2 <= '9')
				byte |= c2 - '0';
			else if (c2 >= 'a' && c2 <= 'f')
				byte |= c2 - 'a' + 10;
			else if (c2 >= 'A' && c2 <= 'F')
				byte |= c2 - 'A' + 10;
			else
				@throw [OFInvalidFormatException exception];

			[self addItem: &byte];
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithBase64EncodedString: (OFString*)string
{
	self = [self initWithItemSize: 1
			     capacity: [string length] / 3];

	@try {
		if (!of_base64_decode(self, [string cStringWithEncoding:
		    OF_STRING_ENCODING_ASCII], [string
		    cStringLengthWithEncoding: OF_STRING_ENCODING_ASCII]))
			@throw [OFInvalidFormatException exception];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithSerialization: (OFXMLElement*)element
{
	@try {
		void *pool = objc_autoreleasePoolPush();
		OFString *stringValue;

		if (![[element name] isEqual: [self className]] ||
		    ![[element namespace] isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException exception];

		stringValue = [element stringValue];

		self = [self initWithBase64EncodedString: stringValue];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (size_t)count
{
	return _count;
}

- (void*)items
{
	return _items;
}

- (void*)itemAtIndex: (size_t)index
{
	if (index >= _count)
		@throw [OFOutOfRangeException exception];

	return _items + index * _itemSize;
}

- (void*)firstItem
{
	if (_items == NULL || _count == 0)
		return NULL;

	return _items;
}

- (void*)lastItem
{
	if (_items == NULL || _count == 0)
		return NULL;

	return _items + (_count - 1) * _itemSize;
}

- (void)addItem: (const void*)item
{
	if (SIZE_MAX - _count < 1)
		@throw [OFOutOfRangeException exception];

	if (_count + 1 > _capacity) {
		_items = [self resizeMemory: _items
				       size: _itemSize
				      count: _count + 1];
		_capacity = _count + 1;
	}

	memcpy(_items + _count * _itemSize, item, _itemSize);

	_count++;
}

- (void)insertItem: (const void*)item
	   atIndex: (size_t)index
{
	[self insertItems: item
		  atIndex: index
		    count: 1];
}

- (void)addItems: (const void*)items
	   count: (size_t)count
{
	if (count > SIZE_MAX - _count)
		@throw [OFOutOfRangeException exception];

	if (_count + count > _capacity) {
		_items = [self resizeMemory: _items
				       size: _itemSize
				      count: _count + count];
		_capacity = _count + count;
	}

	memcpy(_items + _count * _itemSize, items, count * _itemSize);
	_count += count;
}

- (void)insertItems: (const void*)items
	    atIndex: (size_t)index
	      count: (size_t)count
{
	if (count > SIZE_MAX - _count || index > _count)
		@throw [OFOutOfRangeException exception];

	if (_count + count > _capacity) {
		_items = [self resizeMemory: _items
				       size: _itemSize
				      count: _count + count];
		_capacity = _count + count;
	}

	memmove(_items + (index + count) * _itemSize,
	    _items + index * _itemSize, (_count - index) * _itemSize);
	memcpy(_items + index * _itemSize, items, count * _itemSize);

	_count += count;
}

- (void)removeItemAtIndex: (size_t)index
{
	[self removeItemsInRange: of_range(index, 1)];
}

- (void)removeItemsInRange: (of_range_t)range
{
	if (range.length > SIZE_MAX - range.location ||
	    range.location + range.length > _count)
		@throw [OFOutOfRangeException exception];

	memmove(_items + range.location * _itemSize,
	    _items + (range.location + range.length) * _itemSize,
	    (_count - range.location - range.length) * _itemSize);

	_count -= range.length;
	@try {
		_items = [self resizeMemory: _items
				       size: _itemSize
				      count: _count];
		_capacity = _count;
	} @catch (OFOutOfMemoryException *e) {
		/* We don't really care, as we only made it smaller */
	}
}

- (void)removeLastItem
{
	if (_count == 0)
		return;

	_count--;
	@try {
		_items = [self resizeMemory: _items
				       size: _itemSize
				      count: _count];
		_capacity = _count;
	} @catch (OFOutOfMemoryException *e) {
		/* We don't care, as we only made it smaller */
	}
}

- (void)removeAllItems
{
	[self freeMemory: _items];

	_items = NULL;
	_count = 0;
	_capacity = 0;
}

- copy
{
	OFDataArray *copy = [[[self class] alloc] initWithItemSize: _itemSize
							  capacity: _count];

	[copy addItems: _items
		 count: _count];

	return copy;
}

- (bool)isEqual: (id)object
{
	OFDataArray *dataArray;

	if (![object isKindOfClass: [OFDataArray class]])
		return false;

	dataArray = object;

	if ([dataArray count] != _count ||
	    [dataArray itemSize] != _itemSize)
		return false;
	if (memcmp([dataArray items], _items, _count * _itemSize) != 0)
		return false;

	return true;
}

- (of_comparison_result_t)compare: (id <OFComparing>)object
{
	OFDataArray *dataArray;
	int comparison;
	size_t count, minCount;

	if (![object isKindOfClass: [OFDataArray class]])
		@throw [OFInvalidArgumentException exception];

	dataArray = (OFDataArray*)object;

	if ([dataArray itemSize] != _itemSize)
		@throw [OFInvalidArgumentException exception];

	count = [dataArray count];
	minCount = (_count > count ? count : _count);

	if ((comparison = memcmp(_items, [dataArray items],
	    minCount * _itemSize)) == 0) {
		if (_count > count)
			return OF_ORDERED_DESCENDING;
		if (_count < count)
			return OF_ORDERED_ASCENDING;

		return OF_ORDERED_SAME;
	}

	if (comparison > 0)
		return OF_ORDERED_DESCENDING;
	else
		return OF_ORDERED_ASCENDING;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	for (size_t i = 0; i < _count * _itemSize; i++)
		OF_HASH_ADD(hash, ((uint8_t*)_items)[i]);

	OF_HASH_FINALIZE(hash);

	return hash;
}

- (OFString*)description
{
	OFMutableString *ret = [OFMutableString stringWithString: @"<"];

	for (size_t i = 0; i < _count; i++) {
		if (i > 0)
			[ret appendString: @" "];

		for (size_t j = 0; j < _itemSize; j++)
			[ret appendFormat: @"%02x", _items[i * _itemSize + j]];
	}

	[ret appendString: @">"];

	[ret makeImmutable];
	return ret;
}

- (OFString*)stringRepresentation
{
	OFMutableString *ret = [OFMutableString string];

	for (size_t i = 0; i < _count; i++)
		for (size_t j = 0; j < _itemSize; j++)
			[ret appendFormat: @"%02x", _items[i * _itemSize + j]];

	[ret makeImmutable];
	return ret;
}

- (OFString*)stringByBase64Encoding
{
	return of_base64_encode(_items, _count * _itemSize);
}

#ifdef OF_HAVE_FILES
- (void)writeToFile: (OFString*)path
{
	OFFile *file = [[OFFile alloc] initWithPath: path
					       mode: @"wb"];

	@try {
		[file writeBuffer: _items
			   length: _count * _itemSize];
	} @finally {
		[file release];
	}
}
#endif

- (OFXMLElement*)XMLElementBySerializing
{
	void *pool;
	OFXMLElement *element;

	if (_itemSize != 1)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();
	element = [OFXMLElement
	    elementWithName: [self className]
		  namespace: OF_SERIALIZATION_NS
		stringValue: of_base64_encode(_items, _count * _itemSize)];

	[element retain];

	objc_autoreleasePoolPop(pool);

	return [element autorelease];
}

- (OFDataArray*)messagePackRepresentation
{
	OFDataArray *data;

	if (_itemSize != 1)
		@throw [OFInvalidArgumentException exception];

	if (_count <= UINT8_MAX) {
		uint8_t type = 0xC4;
		uint8_t tmp = (uint8_t)_count;

		data = [OFDataArray dataArrayWithItemSize: 1
						 capacity: _count + 2];

		[data addItem: &type];
		[data addItem: &tmp];
	} else if (_count <= UINT16_MAX) {
		uint8_t type = 0xC5;
		uint16_t tmp = OF_BSWAP16_IF_LE((uint16_t)_count);

		data = [OFDataArray dataArrayWithItemSize: 1
						 capacity: _count + 3];

		[data addItem: &type];
		[data addItems: &tmp
			 count: sizeof(tmp)];
	} else if (_count <= UINT32_MAX) {
		uint8_t type = 0xC6;
		uint32_t tmp = OF_BSWAP32_IF_LE((uint32_t)_count);

		data = [OFDataArray dataArrayWithItemSize: 1
						 capacity: _count + 5];

		[data addItem: &type];
		[data addItems: &tmp
			 count: sizeof(tmp)];
	} else
		@throw [OFOutOfRangeException exception];

	[data addItems: _items
		 count: _count];

	return data;
}
@end
