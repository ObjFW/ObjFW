/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#include <stdlib.h>
#include <string.h>
#include <limits.h>

#import "OFData.h"
#import "OFData+Private.h"
#import "OFString.h"
#ifdef OF_HAVE_FILES
# import "OFFile.h"
# import "OFFileManager.h"
#endif
#import "OFURL.h"
#import "OFDictionary.h"
#import "OFXMLElement.h"
#import "OFSystemInfo.h"

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
_references_to_categories_of_OFData(void)
{
	_OFData_CryptoHashing_reference = 1;
	_OFData_MessagePackValue_reference = 1;
}

@implementation OFData
@synthesize itemSize = _itemSize;

+ (instancetype)dataWithItems: (const void *)items
			count: (size_t)count
{
	return [[[self alloc] initWithItems: items
				      count: count] autorelease];
}

+ (instancetype)dataWithItems: (const void *)items
		     itemSize: (size_t)itemSize
			count: (size_t)count
{
	return [[[self alloc] initWithItems: items
				   itemSize: itemSize
				      count: count] autorelease];
}

+ (instancetype)dataWithItemsNoCopy: (const void *)items
			      count: (size_t)count
		       freeWhenDone: (bool)freeWhenDone
{
	return [[[self alloc] initWithItemsNoCopy: items
					    count: count
				     freeWhenDone: freeWhenDone] autorelease];
}

+ (instancetype)dataWithItemsNoCopy: (const void *)items
			   itemSize: (size_t)itemSize
			      count: (size_t)count
		       freeWhenDone: (bool)freeWhenDone
{
	return [[[self alloc] initWithItemsNoCopy: items
					 itemSize: itemSize
					    count: count
				     freeWhenDone: freeWhenDone] autorelease];
}

#ifdef OF_HAVE_FILES
+ (instancetype)dataWithContentsOfFile: (OFString *)path
{
	return [[[self alloc] initWithContentsOfFile: path] autorelease];
}
#endif

#if defined(OF_HAVE_FILES) || defined(OF_HAVE_SOCKETS)
+ (instancetype)dataWithContentsOfURL: (OFURL *)URL
{
	return [[[self alloc] initWithContentsOfURL: URL] autorelease];
}
#endif

+ (instancetype)dataWithStringRepresentation: (OFString *)string
{
	return [[[self alloc]
	    initWithStringRepresentation: string] autorelease];
}

+ (instancetype)dataWithBase64EncodedString: (OFString *)string
{
	return [[[self alloc] initWithBase64EncodedString: string] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_init
{
	return [super init];
}

- (instancetype)initWithItems: (const void *)items
			count: (size_t)count
{
	return [self initWithItems: items
			  itemSize: 1
			     count: count];
}

- (instancetype)initWithItems: (const void *)items
		     itemSize: (size_t)itemSize
			count: (size_t)count
{
	self = [super init];

	@try {
		if (itemSize == 0)
			@throw [OFInvalidArgumentException exception];

		_itemSize = itemSize;
		_count = count;
		_items = [self allocMemoryWithSize: itemSize
					     count: count];

		memcpy(_items, items, itemSize * count);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithItemsNoCopy: (const void *)items
			      count: (size_t)count
		       freeWhenDone: (bool)freeWhenDone
{
	return [self initWithItemsNoCopy: items
				itemSize: 1
				   count: count
			    freeWhenDone: freeWhenDone];
}

- (instancetype)initWithItemsNoCopy: (const void *)items
			   itemSize: (size_t)itemSize
			      count: (size_t)count
		       freeWhenDone: (bool)freeWhenDone
{
	self = [super init];

	@try {
		if (itemSize == 0)
			@throw [OFInvalidArgumentException exception];

		_items = (unsigned char *)items;
		_itemSize = itemSize;
		_count = count;
		_freeWhenDone = freeWhenDone;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

#ifdef OF_HAVE_FILES
- (instancetype)initWithContentsOfFile: (OFString *)path
{
	@try {
		of_offset_t size = [[OFFileManager defaultManager]
		    sizeOfFileAtPath: path];
		char *buffer;

		if (sizeof(of_offset_t) > sizeof(size_t) &&
		    size > (of_offset_t)SIZE_MAX)
			@throw [OFOutOfRangeException exception];

		buffer = malloc((size_t)size);
		if (buffer == NULL)
			@throw [OFOutOfMemoryException
			    exceptionWithRequestedSize: (size_t)size];

		@try {
			OFFile *file = [[OFFile alloc] initWithPath: path
							       mode: @"r"];
			@try {
				[file readIntoBuffer: buffer
					 exactLength: (size_t)size];
			} @finally {
				[file release];
			}

			self = [self initWithItemsNoCopy: buffer
						   count: (size_t)size
					    freeWhenDone: true];
		} @catch (id e) {
			free(buffer);
			@throw e;
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}
#endif

#if defined(OF_HAVE_FILES) || defined(OF_HAVE_SOCKETS)
- (instancetype)initWithContentsOfURL: (OFURL *)URL
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
		@throw [OFUnsupportedProtocolException exceptionWithURL: URL];

	objc_autoreleasePoolPop(pool);

	return self;
}
#endif

- (instancetype)initWithStringRepresentation: (OFString *)string
{
	self = [super init];

	@try {
		size_t count = [string
		    cStringLengthWithEncoding: OF_STRING_ENCODING_ASCII];
		const char *cString;

		if (count % 2 != 0)
			@throw [OFInvalidFormatException exception];

		count /= 2;

		_items = [self allocMemoryWithSize: count];
		_itemSize = 1;
		_count = count;

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

			_items[i] = byte;
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithBase64EncodedString: (OFString *)string
{
	bool mutable = [self isKindOfClass: [OFMutableData class]];

	if (!mutable) {
		[self release];
		self = [OFMutableData alloc];
	}

	self = [(OFMutableData *)self initWithCapacity: [string length] / 3];

	@try {
		if (!of_base64_decode((OFMutableData *)self,
		    [string cStringWithEncoding: OF_STRING_ENCODING_ASCII],
		    [string cStringLengthWithEncoding:
		    OF_STRING_ENCODING_ASCII]))
			@throw [OFInvalidFormatException exception];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	if (!mutable)
		[(OFMutableData *)self makeImmutable];

	return self;
}

- (instancetype)initWithSerialization: (OFXMLElement *)element
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

- (void)dealloc
{
	if (_freeWhenDone)
		free(_items);

	[super dealloc];
}

- (size_t)count
{
	return _count;
}

- (const void *)items
{
	return _items;
}

- (const void *)itemAtIndex: (size_t)idx
{
	if (idx >= _count)
		@throw [OFOutOfRangeException exception];

	return _items + idx * _itemSize;
}

- (const void *)firstItem
{
	if (_items == NULL || _count == 0)
		return NULL;

	return _items;
}

- (const void *)lastItem
{
	if (_items == NULL || _count == 0)
		return NULL;

	return _items + (_count - 1) * _itemSize;
}

- (id)copy
{
	return [self retain];
}

- (id)mutableCopy
{
	return [[OFMutableData alloc] initWithItems: _items
					   itemSize: _itemSize
					      count: _count];
}

- (bool)isEqual: (id)object
{
	OFData *data;

	if (![object isKindOfClass: [OFData class]])
		return false;

	data = object;

	if ([data count] != _count || [data itemSize] != _itemSize)
		return false;
	if (memcmp([data items], _items, _count * _itemSize) != 0)
		return false;

	return true;
}

- (of_comparison_result_t)compare: (id <OFComparing>)object
{
	OFData *data;
	int comparison;
	size_t count, minCount;

	if (![object isKindOfClass: [OFData class]])
		@throw [OFInvalidArgumentException exception];

	data = (OFData *)object;

	if ([data itemSize] != _itemSize)
		@throw [OFInvalidArgumentException exception];

	count = [data count];
	minCount = (_count > count ? count : _count);

	if ((comparison = memcmp(_items, [data items],
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
		OF_HASH_ADD(hash, ((uint8_t *)_items)[i]);

	OF_HASH_FINALIZE(hash);

	return hash;
}

- (OFString *)description
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

- (OFString *)stringRepresentation
{
	OFMutableString *ret = [OFMutableString string];

	for (size_t i = 0; i < _count; i++)
		for (size_t j = 0; j < _itemSize; j++)
			[ret appendFormat: @"%02x", _items[i * _itemSize + j]];

	[ret makeImmutable];
	return ret;
}

- (OFString *)stringByBase64Encoding
{
	return of_base64_encode(_items, _count * _itemSize);
}

#ifdef OF_HAVE_FILES
- (void)writeToFile: (OFString *)path
{
	OFFile *file = [[OFFile alloc] initWithPath: path
					       mode: @"w"];

	@try {
		[file writeBuffer: _items
			   length: _count * _itemSize];
	} @finally {
		[file release];
	}
}
#endif

- (OFXMLElement *)XMLElementBySerializing
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

- (OFData *)messagePackRepresentation
{
	OFMutableData *data;

	if (_itemSize != 1)
		@throw [OFInvalidArgumentException exception];

	if (_count <= UINT8_MAX) {
		uint8_t type = 0xC4;
		uint8_t tmp = (uint8_t)_count;

		data = [OFMutableData dataWithItemSize: 1
					      capacity: _count + 2];

		[data addItem: &type];
		[data addItem: &tmp];
	} else if (_count <= UINT16_MAX) {
		uint8_t type = 0xC5;
		uint16_t tmp = OF_BSWAP16_IF_LE((uint16_t)_count);

		data = [OFMutableData dataWithItemSize: 1
					      capacity: _count + 3];

		[data addItem: &type];
		[data addItems: &tmp
			 count: sizeof(tmp)];
	} else if (_count <= UINT32_MAX) {
		uint8_t type = 0xC6;
		uint32_t tmp = OF_BSWAP32_IF_LE((uint32_t)_count);

		data = [OFMutableData dataWithItemSize: 1
					      capacity: _count + 5];

		[data addItem: &type];
		[data addItems: &tmp
			 count: sizeof(tmp)];
	} else
		@throw [OFOutOfRangeException exception];

	[data addItems: _items
		 count: _count];

	[data makeImmutable];

	return data;
}
@end
