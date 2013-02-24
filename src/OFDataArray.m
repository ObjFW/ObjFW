/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#include <stdio.h>
#include <string.h>
#include <limits.h>

#import "OFDataArray.h"
#import "OFString.h"
#import "OFFile.h"
#import "OFURL.h"
#import "OFHTTPClient.h"
#import "OFHTTPRequest.h"
#import "OFHTTPRequestReply.h"
#import "OFDictionary.h"
#import "OFXMLElement.h"
#import "OFSystemInfo.h"

#import "OFHTTPRequestFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"

#import "autorelease.h"
#import "base64.h"
#import "macros.h"

/* References for static linking */
void _references_to_categories_of_OFDataArray(void)
{
	_OFDataArray_BinaryPackValue_reference = 1;
	_OFDataArray_Hashing_reference = 1;
}

@implementation OFDataArray
+ (instancetype)dataArray
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)dataArrayWithItemSize: (size_t)itemSize
{
	return [[[self alloc] initWithItemSize: itemSize] autorelease];
}

+ (instancetype)dataArrayWithItemSize: (size_t)itemSize
			     capacity: (size_t)capacity
{
	return [[[self alloc] initWithItemSize: itemSize
				      capacity: capacity] autorelease];
}

+ (instancetype)dataArrayWithContentsOfFile: (OFString*)path
{
	return [[[self alloc] initWithContentsOfFile: path] autorelease];
}

+ (instancetype)dataArrayWithContentsOfURL: (OFURL*)URL
{
	return [[[self alloc] initWithContentsOfURL: URL] autorelease];
}

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
	return [self initWithItemSize: 1
			     capacity: 0];
}

- initWithItemSize: (size_t)itemSize
{
	return [self initWithItemSize: itemSize
			     capacity: 0];
}

- initWithItemSize: (size_t)itemSize
	  capacity: (size_t)capacity
{
	self = [super init];

	if (itemSize == 0) {
		Class c = [self class];
		[self release];
		@throw [OFInvalidArgumentException exceptionWithClass: c
							     selector: _cmd];
	}

	_items = [self allocMemoryWithSize: itemSize
				     count: capacity];

	_itemSize = itemSize;
	_capacity = capacity;

	return self;
}

- initWithContentsOfFile: (OFString*)path
{
	@try {
		OFFile *file = [[OFFile alloc] initWithPath: path
						       mode: @"rb"];
		off_t size = [OFFile sizeOfFileAtPath: path];

		if (size > SIZE_MAX)
			@throw [OFOutOfRangeException
			    exceptionWithClass: [self class]];

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

- initWithContentsOfURL: (OFURL*)URL
{
	void *pool;
	OFHTTPClient *client;
	OFHTTPRequest *request;
	OFHTTPRequestReply *reply;
	OFDictionary *headers;
	OFString *contentLength;
	Class c;

	c = [self class];
	[self release];

	pool = objc_autoreleasePoolPush();

	if ([[URL scheme] isEqual: @"file"]) {
		self = [[c alloc] initWithContentsOfFile: [URL path]];
		objc_autoreleasePoolPop(pool);
		return self;
	}

	client = [OFHTTPClient client];
	request = [OFHTTPRequest requestWithURL: URL];
	reply = [client performRequest: request];

	if ([reply statusCode] != 200)
		@throw [OFHTTPRequestFailedException
		    exceptionWithClass: [request class]
			       request: request
				 reply: reply];

	/*
	 * TODO: This can be optimized by allocating a data array with the
	 * capacity from the Content-Length header.
	 */
	self = [[reply readDataArrayTillEndOfStream] retain];

	headers = [reply headers];
	if ((contentLength = [headers objectForKey: @"Content-Length"]) != nil)
		if ([self count] != (size_t)[contentLength decimalValue])
			@throw [OFTruncatedDataException
			    exceptionWithClass: [self class]];

	objc_autoreleasePoolPop(pool);

	return self;
}

- initWithStringRepresentation: (OFString*)string
{
	self = [super init];

	@try {
		const char *cString;
		size_t i;

		_itemSize = 1;
		_count = [string
		    cStringLengthWithEncoding: OF_STRING_ENCODING_ASCII];

		if (_count & 1)
			@throw [OFInvalidFormatException
			    exceptionWithClass: [self class]];

		_count >>= 1;
		cString = [string
		    cStringWithEncoding: OF_STRING_ENCODING_ASCII];
		_items = [self allocMemoryWithSize: _count];

		for (i = 0; i < _count; i++) {
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
				@throw [OFInvalidFormatException
				    exceptionWithClass: [self class]];

			if (c2 >= '0' && c2 <= '9')
				byte |= c2 - '0';
			else if (c2 >= 'a' && c2 <= 'f')
				byte |= c2 - 'a' + 10;
			else if (c2 >= 'A' && c2 <= 'F')
				byte |= c2 - 'A' + 10;
			else
				@throw [OFInvalidFormatException
				    exceptionWithClass: [self class]];

			_items[i] = byte;
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
		    cStringLengthWithEncoding: OF_STRING_ENCODING_ASCII])) {
			Class c = [self class];
			[self release];
			@throw [OFInvalidFormatException exceptionWithClass: c];
		}
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
			@throw [OFInvalidArgumentException
			    exceptionWithClass: [self class]
				      selector: _cmd];

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

- (size_t)itemSize
{
	return _itemSize;
}

- (void*)items
{
	return _items;
}

- (void*)itemAtIndex: (size_t)index
{
	if (index >= _count)
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

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
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

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
	if (count > SIZE_MAX - count)
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

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
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

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
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

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

- (BOOL)isEqual: (id)object
{
	OFDataArray *dataArray;

	if (![object isKindOfClass: [OFDataArray class]])
		return NO;

	dataArray = object;

	if ([dataArray count] != _count ||
	    [dataArray itemSize] != _itemSize)
		return NO;
	if (memcmp([dataArray items], _items, _count * _itemSize))
		return NO;

	return YES;
}

- (of_comparison_result_t)compare: (id <OFComparing>)object
{
	OFDataArray *dataArray;
	int comparison;
	size_t count, minCount;

	if (![object isKindOfClass: [OFDataArray class]])
		@throw [OFInvalidArgumentException
		    exceptionWithClass: [self class]
			      selector: _cmd];
	dataArray = (OFDataArray*)object;

	if ([dataArray itemSize] != _itemSize)
		@throw [OFInvalidArgumentException
		    exceptionWithClass: [self class]
			      selector: _cmd];

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
	size_t i;

	OF_HASH_INIT(hash);

	for (i = 0; i < _count * _itemSize; i++)
		OF_HASH_ADD(hash, ((uint8_t*)_items)[i]);

	OF_HASH_FINALIZE(hash);

	return hash;
}

- (OFString*)description
{
	OFMutableString *ret = [OFMutableString stringWithString: @"<"];
	size_t i;

	for (i = 0; i < _count; i++) {
		size_t j;

		if (i > 0)
			[ret appendString: @" "];

		for (j = 0; j < _itemSize; j++)
			[ret appendFormat: @"%02x", _items[i * _itemSize + j]];
	}

	[ret appendString: @">"];

	[ret makeImmutable];
	return ret;
}

- (OFString*)stringRepresentation
{
	OFMutableString *ret = [OFMutableString string];
	size_t i, j;

	for (i = 0; i < _count; i++)
		for (j = 0; j < _itemSize; j++)
			[ret appendFormat: @"%02x", _items[i * _itemSize + j]];

	[ret makeImmutable];
	return ret;
}

- (OFString*)stringByBase64Encoding
{
	return of_base64_encode(_items, _count * _itemSize);
}

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

- (OFXMLElement*)XMLElementBySerializing
{
	void *pool;
	OFXMLElement *element;

	if (_itemSize != 1)
		@throw [OFInvalidArgumentException
		    exceptionWithClass: [self class]];

	pool = objc_autoreleasePoolPush();
	element = [OFXMLElement
	    elementWithName: [self className]
		  namespace: OF_SERIALIZATION_NS
		stringValue: of_base64_encode(_items, _count * _itemSize)];

	[element retain];

	objc_autoreleasePoolPop(pool);

	return [element autorelease];
}

- (OFDataArray*)binaryPackRepresentation
{
	OFDataArray *data;

	if (_itemSize != 1)
		@throw [OFInvalidArgumentException
		    exceptionWithClass: [self class]
			      selector: _cmd];

	if (_count <= UINT8_MAX) {
		uint8_t type = 0xD5;
		uint8_t tmp = (uint8_t)_count;

		data = [OFDataArray dataArrayWithItemSize: 1
						 capacity: _count + 2];

		[data addItem: &type];
		[data addItem: &tmp];
	} else if (_count <= UINT16_MAX) {
		uint8_t type = 0xD6;
		uint16_t tmp = OF_BSWAP16_IF_LE((uint16_t)_count);

		data = [OFDataArray dataArrayWithItemSize: 1
						 capacity: _count + 3];

		[data addItem: &type];
		[data addItems: &tmp
			 count: sizeof(tmp)];
	} else if (_count <= UINT32_MAX) {
		uint8_t type = 0xD7;
		uint32_t tmp = OF_BSWAP32_IF_LE((uint32_t)_count);

		data = [OFDataArray dataArrayWithItemSize: 1
						 capacity: _count + 5];

		[data addItem: &type];
		[data addItems: &tmp
			 count: sizeof(tmp)];
	} else
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

	[data addItems: _items
		 count: _count];

	return data;
}
@end

@implementation OFBigDataArray
- initWithItemSize: (size_t)itemSize
	  capacity: (size_t)capacity
{
	size_t lastPageByte = [OFSystemInfo pageSize] - 1;

	capacity = (capacity * itemSize + lastPageByte) & ~lastPageByte;

	return [super initWithItemSize: itemSize
			      capacity: capacity];
}

- (void)addItem: (const void*)item
{
	size_t size, lastPageByte;

	if (SIZE_MAX - _count < 1 || _count + 1 > SIZE_MAX / _itemSize)
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

	lastPageByte = [OFSystemInfo pageSize] - 1;
	size = ((_count + 1) * _itemSize + lastPageByte) & ~lastPageByte;

	if (size > _capacity) {
		_items = [self resizeMemory: _items
				       size: size];
		_capacity = size;
	}

	memcpy(_items + _count * _itemSize, item, _itemSize);

	_count++;
	_size = size;
}

- (void)addItems: (const void*)items
	   count: (size_t)count
{
	size_t size, lastPageByte;

	if (count > SIZE_MAX - _count || _count + count > SIZE_MAX / _itemSize)
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

	lastPageByte = [OFSystemInfo pageSize] - 1;
	size = ((_count + count) * _itemSize + lastPageByte) & ~lastPageByte;

	if (size > _capacity) {
		_items = [self resizeMemory: _items
				       size: size];
		_capacity = size;
	}

	memcpy(_items + _count * _itemSize, items, count * _itemSize);

	_count += count;
	_size = size;
}

- (void)insertItems: (const void*)items
	    atIndex: (size_t)index
	      count: (size_t)count
{
	size_t size, lastPageByte;

	if (count > SIZE_MAX - _count || index > _count ||
	    _count + count > SIZE_MAX / _itemSize)
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

	lastPageByte = [OFSystemInfo pageSize] - 1;
	size = ((_count + count) * _itemSize + lastPageByte) & ~lastPageByte;

	if (size > _capacity) {
		_items = [self resizeMemory: _items
				       size: size];
		_capacity = size;
	}

	memmove(_items + (index + count) * _itemSize,
	    _items + index * _itemSize, (_count - index) * _itemSize);
	memcpy(_items + index * _itemSize, items, count * _itemSize);

	_count += count;
	_size = size;
}

- (void)removeItemsInRange: (of_range_t)range
{
	size_t pageSize, size;

	if (range.length > SIZE_MAX - range.location ||
	    range.location + range.length > _count)
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

	memmove(_items + range.location * _itemSize,
	    _items + (range.location + range.length) * _itemSize,
	    (_count - range.location - range.length) * _itemSize);

	_count -= range.length;
	pageSize = [OFSystemInfo pageSize];
	size = (_count * _itemSize + pageSize - 1) & ~(pageSize - 1);

	if (_size != size && size >= pageSize) {
		@try {
			_items = [self resizeMemory: _items
					       size: size];
			_capacity = size;
		} @catch (OFOutOfMemoryException *e) {
			/* We don't care, as we only made it smaller */
		}

		_size = size;
	}
}

- (void)removeLastItem
{
	size_t pageSize, size;

	if (_count == 0)
		return;

	_count--;
	pageSize = [OFSystemInfo pageSize];
	size = (_count * _itemSize + pageSize - 1) & ~(pageSize - 1);

	if (_size != size && size >= pageSize) {
		@try {
			_items = [self resizeMemory: _items
					       size: size];
			_capacity = size;
		} @catch (OFOutOfMemoryException *e) {
			/* We don't care, as we only made it smaller */
		}

		_size = size;
	}
}

- (void)removeAllItems
{
	size_t pageSize = [OFSystemInfo pageSize];

	@try {
		_items = [self resizeMemory: _items
				       size: pageSize];
		_capacity = pageSize;
		_size = pageSize;
	} @catch (OFOutOfMemoryException *e) {
		/* We don't care, as we only made it smaller */
	}

	_count = 0;
}
@end
