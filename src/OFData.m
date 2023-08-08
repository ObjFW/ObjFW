/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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
#import "OFAdjacentData.h"
#import "OFBase64.h"
#import "OFDictionary.h"
#ifdef OF_HAVE_FILES
# import "OFFile.h"
# import "OFFileManager.h"
#endif
#import "OFIRI.h"
#import "OFIRIHandler.h"
#import "OFStream.h"
#import "OFString.h"
#import "OFSystemInfo.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"
#import "OFUnsupportedProtocolException.h"

static struct {
	Class isa;
} placeholder;

@interface OFDataPlaceholder: OFString
@end

/* References for static linking */
void
_references_to_categories_of_OFData(void)
{
	_OFData_CryptographicHashing_reference = 1;
	_OFData_MessagePackParsing_reference = 1;
}

@implementation OFDataPlaceholder
- (instancetype)init
{
	return (id)[[OFAdjacentData alloc] init];
}

- (instancetype)initWithItemSize: (size_t)itemSize
{
	return (id)[[OFAdjacentData alloc] initWithItemSize: itemSize];
}

- (instancetype)initWithItems: (const void *)items count: (size_t)count
{
	return (id)[[OFAdjacentData alloc] initWithItems: items count: count];
}

- (instancetype)initWithItems: (const void *)items
			count: (size_t)count
		     itemSize: (size_t)itemSize
{
	return (id)[[OFAdjacentData alloc] initWithItems: items
						   count: count
						itemSize: itemSize];
}

- (instancetype)initWithItemsNoCopy: (void *)items
			      count: (size_t)count
		       freeWhenDone: (bool)freeWhenDone
{
	return (id)[[OFAdjacentData alloc] initWithItemsNoCopy: items
							 count: count
						  freeWhenDone: freeWhenDone];
}

- (instancetype)initWithItemsNoCopy: (void *)items
			      count: (size_t)count
			   itemSize: (size_t)itemSize
		       freeWhenDone: (bool)freeWhenDone
{
	return (id)[[OFAdjacentData alloc] initWithItemsNoCopy: items
							 count: count
						      itemSize: itemSize
						  freeWhenDone: freeWhenDone];
}

#ifdef OF_HAVE_FILES
- (instancetype)initWithContentsOfFile: (OFString *)path
{
	return (id)[[OFAdjacentData alloc] initWithContentsOfFile: path];
}
#endif

- (instancetype)initWithContentsOfIRI: (OFIRI *)IRI
{
	return (id)[[OFAdjacentData alloc] initWithContentsOfIRI: IRI];
}

- (instancetype)initWithStringRepresentation: (OFString *)string
{
	return (id)[[OFAdjacentData alloc]
	    initWithStringRepresentation: string];
}

- (instancetype)initWithBase64EncodedString: (OFString *)string
{
	return (id)[[OFAdjacentData alloc] initWithBase64EncodedString: string];
}
@end

@implementation OFData
+ (void)initialize
{
	if (self == [OFData class])
		object_setClass((id)&placeholder, [OFDataPlaceholder class]);
}

+ (instancetype)alloc
{
	if (self == [OFData class])
		return (id)&placeholder;

	return [super alloc];
}

+ (instancetype)data
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)dataWithItemSize: (size_t)itemSize
{
	return [[[self alloc] initWithItemSize: itemSize] autorelease];
}

+ (instancetype)dataWithItems: (const void *)items count: (size_t)count
{
	return [[[self alloc] initWithItems: items count: count] autorelease];
}

+ (instancetype)dataWithItems: (const void *)items
			count: (size_t)count
		     itemSize: (size_t)itemSize
{
	return [[[self alloc] initWithItems: items
				      count: count
				   itemSize: itemSize] autorelease];
}

+ (instancetype)dataWithItemsNoCopy: (void *)items
			      count: (size_t)count
		       freeWhenDone: (bool)freeWhenDone
{
	return [[[self alloc] initWithItemsNoCopy: items
					    count: count
				     freeWhenDone: freeWhenDone] autorelease];
}

+ (instancetype)dataWithItemsNoCopy: (void *)items
			      count: (size_t)count
			   itemSize: (size_t)itemSize
		       freeWhenDone: (bool)freeWhenDone
{
	return [[[self alloc] initWithItemsNoCopy: items
					    count: count
					 itemSize: itemSize
				     freeWhenDone: freeWhenDone] autorelease];
}

#ifdef OF_HAVE_FILES
+ (instancetype)dataWithContentsOfFile: (OFString *)path
{
	return [[[self alloc] initWithContentsOfFile: path] autorelease];
}
#endif

+ (instancetype)dataWithContentsOfIRI: (OFIRI *)IRI
{
	return [[[self alloc] initWithContentsOfIRI: IRI] autorelease];
}

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
	if ([self isMemberOfClass: [OFData class]] ||
	    [self isMemberOfClass: [OFMutableData class]]) {
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

- (instancetype)initWithItemSize: (size_t)itemSize
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithItems: (const void *)items count: (size_t)count
{
	return [self initWithItems: items count: count itemSize: 1];
}

- (instancetype)initWithItems: (const void *)items
			count: (size_t)count
		     itemSize: (size_t)itemSize
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithItemsNoCopy: (void *)items
			      count: (size_t)count
		       freeWhenDone: (bool)freeWhenDone
{
	return [self initWithItemsNoCopy: items
				   count: count
				itemSize: 1
			    freeWhenDone: freeWhenDone];
}

- (instancetype)initWithItemsNoCopy: (void *)items
			      count: (size_t)count
			   itemSize: (size_t)itemSize
		       freeWhenDone: (bool)freeWhenDone
{
	OF_INVALID_INIT_METHOD
}

#ifdef OF_HAVE_FILES
- (instancetype)initWithContentsOfFile: (OFString *)path
{
	char *buffer = NULL;
	OFStreamOffset fileSize;

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFFile *file = [OFFile fileWithPath: path mode: @"r"];
		fileSize = [file seekToOffset: 0 whence: OFSeekEnd];

		if (fileSize < 0 || (unsigned long long)fileSize > SIZE_MAX)
			@throw [OFOutOfRangeException exception];

		[file seekToOffset: 0 whence: OFSeekSet];

		buffer = OFAllocMemory((size_t)fileSize, 1);
		[file readIntoBuffer: buffer exactLength: (size_t)fileSize];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		OFFreeMemory(buffer);
		[self release];

		@throw e;
	}

	@try {
		self = [self initWithItemsNoCopy: buffer
					   count: (size_t)fileSize
				    freeWhenDone: true];
	} @catch (id e) {
		OFFreeMemory(buffer);
		@throw e;
	}

	return self;
}
#endif

- (instancetype)initWithContentsOfIRI: (OFIRI *)IRI
{
	char *items = NULL, *buffer = NULL;
	size_t count = 0;

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFStream *stream = [OFIRIHandler openItemAtIRI: IRI mode: @"r"];
		size_t pageSize;

		pageSize = [OFSystemInfo pageSize];
		buffer = OFAllocMemory(1, pageSize);

		while (!stream.atEndOfStream) {
			size_t length = [stream readIntoBuffer: buffer
							length: pageSize];

			if (SIZE_MAX - count < length)
				@throw [OFOutOfRangeException exception];

			items = OFResizeMemory(items, count + length, 1);
			memcpy(items + count, buffer, length);
			count += length;
		}

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		OFFreeMemory(buffer);
		OFFreeMemory(items);
		[self release];

		@throw e;
	}

	@try {
		self = [self initWithItemsNoCopy: items
					   count: count
				    freeWhenDone: true];
	} @catch (id e) {
		OFFreeMemory(items);
		@throw e;
	}

	return self;
}

- (instancetype)initWithStringRepresentation: (OFString *)string
{
	char *items = NULL;
	size_t count = 0;

	@try {
		const char *cString;

		count = [string
		    cStringLengthWithEncoding: OFStringEncodingASCII];

		if (count % 2 != 0)
			@throw [OFInvalidFormatException exception];

		count /= 2;
		items = OFAllocMemory(count, 1);

		cString = [string cStringWithEncoding: OFStringEncodingASCII];

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

			items[i] = byte;
		}
	} @catch (id e) {
		OFFreeMemory(items);
		[self release];

		@throw e;
	}

	@try {
		self = [self initWithItemsNoCopy: items
					   count: count
				    freeWhenDone: true];
	} @catch (id e) {
		OFFreeMemory(items);
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

	self = [(OFMutableData *)self initWithCapacity: string.length / 3];

	@try {
		if (!OFBase64Decode((OFMutableData *)self,
		    [string cStringWithEncoding: OFStringEncodingASCII],
		    [string cStringLengthWithEncoding: OFStringEncodingASCII]))
			@throw [OFInvalidFormatException exception];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	if (!mutable)
		[(OFMutableData *)self makeImmutable];

	return self;
}

- (size_t)count
{
	OF_UNRECOGNIZED_SELECTOR
}

- (size_t)itemSize
{
	OF_UNRECOGNIZED_SELECTOR
}

- (const void *)items
{
	OF_UNRECOGNIZED_SELECTOR
}

- (const void *)itemAtIndex: (size_t)idx
{
	if (idx >= self.count)
		@throw [OFOutOfRangeException exception];

	return (const unsigned char *)self.items + idx * self.itemSize;
}

- (const void *)firstItem
{
	const void *items = self.items;

	if (items == NULL || self.count == 0)
		return NULL;

	return items;
}

- (const void *)lastItem
{
	const unsigned char *items = self.items;
	size_t count = self.count;

	if (items == NULL || count == 0)
		return NULL;

	return items + (count - 1) * self.itemSize;
}

- (id)copy
{
	return [self retain];
}

- (id)mutableCopy
{
	return [[OFMutableData alloc] initWithItems: self.items
					      count: self.count
					   itemSize: self.itemSize];
}

- (bool)isEqual: (id)object
{
	size_t count, itemSize;
	OFData *data;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFData class]])
		return false;

	count = self.count;
	itemSize = self.itemSize;
	data = object;

	if (data.count != count || data.itemSize != itemSize)
		return false;
	if (memcmp(data.items, self.items, count * itemSize) != 0)
		return false;

	return true;
}

- (OFComparisonResult)compare: (OFData *)data
{
	int comparison;
	size_t count, dataCount, minCount;

	if (![data isKindOfClass: [OFData class]])
		@throw [OFInvalidArgumentException exception];

	if (data.itemSize != self.itemSize)
		@throw [OFInvalidArgumentException exception];

	count = self.count;
	dataCount = data.count;
	minCount = (count > dataCount ? dataCount : count);

	if ((comparison = memcmp(self.items, data.items,
	    minCount * self.itemSize)) == 0) {
		if (count > dataCount)
			return OFOrderedDescending;
		if (count < dataCount)
			return OFOrderedAscending;

		return OFOrderedSame;
	}

	if (comparison > 0)
		return OFOrderedDescending;
	else
		return OFOrderedAscending;
}

- (unsigned long)hash
{
	const unsigned char *items = self.items;
	size_t count = self.count, itemSize = self.itemSize;
	unsigned long hash;

	OFHashInit(&hash);

	for (size_t i = 0; i < count * itemSize; i++)
		OFHashAddByte(&hash, items[i]);

	OFHashFinalize(&hash);

	return hash;
}

- (OFData *)subdataWithRange: (OFRange)range
{
	size_t itemSize;

	if (range.length > SIZE_MAX - range.location ||
	    range.location + range.length > self.count)
		@throw [OFOutOfRangeException exception];

	itemSize = self.itemSize;
	return [OFData dataWithItems: (const unsigned char *)self.items +
				      (range.location * itemSize)
			       count: range.length
			    itemSize: itemSize];
}

- (OFString *)description
{
	OFMutableString *ret = [OFMutableString stringWithString: @"<"];
	const unsigned char *items = self.items;
	size_t count = self.count, itemSize = self.itemSize;

	for (size_t i = 0; i < count; i++) {
		if (i > 0)
			[ret appendString: @" "];

		for (size_t j = 0; j < itemSize; j++)
			[ret appendFormat: @"%02x", items[i * itemSize + j]];
	}

	[ret appendString: @">"];

	[ret makeImmutable];
	return ret;
}

- (OFString *)stringRepresentation
{
	OFMutableString *ret = [OFMutableString string];
	const unsigned char *items = self.items;
	size_t count = self.count, itemSize = self.itemSize;

	for (size_t i = 0; i < count; i++)
		for (size_t j = 0; j < itemSize; j++)
			[ret appendFormat: @"%02x", items[i * itemSize + j]];

	[ret makeImmutable];
	return ret;
}

- (OFString *)stringByBase64Encoding
{
	return OFBase64Encode(self.items, self.count * self.itemSize);
}

- (OFRange)rangeOfData: (OFData *)data
	       options: (OFDataSearchOptions)options
		 range: (OFRange)range
{
	const unsigned char *items = self.items;
	size_t count = self.count, itemSize = self.itemSize;
	const char *search;
	size_t searchLength;

	if (range.length > SIZE_MAX - range.location ||
	    range.location + range.length > count)
		@throw [OFOutOfRangeException exception];

	if (data == nil || data.itemSize != itemSize)
		@throw [OFInvalidArgumentException exception];

	if ((searchLength = data.count) == 0)
		return OFMakeRange(0, 0);

	if (searchLength > range.length)
		return OFMakeRange(OFNotFound, 0);

	search = data.items;

	if (options & OFDataSearchBackwards) {
		for (size_t i = range.length - searchLength;; i--) {
			if (memcmp(items + i * itemSize, search,
			    searchLength * itemSize) == 0)
				return OFMakeRange(i, searchLength);

			/* No match and we're at the last item */
			if (i == 0)
				break;
		}
	} else {
		for (size_t i = range.location;
		    i <= range.length - searchLength; i++)
			if (memcmp(items + i * itemSize, search,
			    searchLength * itemSize) == 0)
				return OFMakeRange(i, searchLength);
	}

	return OFMakeRange(OFNotFound, 0);
}

#ifdef OF_HAVE_FILES
- (void)writeToFile: (OFString *)path
{
	OFFile *file = [[OFFile alloc] initWithPath: path mode: @"w"];
	@try {
		[file writeBuffer: self.items
			   length: self.count * self.itemSize];
	} @finally {
		[file release];
	}
}
#endif

- (void)writeToIRI: (OFIRI *)IRI
{
	void *pool = objc_autoreleasePoolPush();

	[[OFIRIHandler openItemAtIRI: IRI mode: @"w"] writeData: self];

	objc_autoreleasePoolPop(pool);
}

- (OFData *)messagePackRepresentation
{
	OFMutableData *data;
	size_t count;

	if (self.itemSize != 1)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	count = self.count;

	if (count <= UINT8_MAX) {
		uint8_t type = 0xC4;
		uint8_t tmp = (uint8_t)count;

		data = [OFMutableData dataWithCapacity: count + 2];
		[data addItem: &type];
		[data addItem: &tmp];
	} else if (count <= UINT16_MAX) {
		uint8_t type = 0xC5;
		uint16_t tmp = OFToBigEndian16((uint16_t)count);

		data = [OFMutableData dataWithCapacity: count + 3];
		[data addItem: &type];
		[data addItems: &tmp count: sizeof(tmp)];
	} else if (count <= UINT32_MAX) {
		uint8_t type = 0xC6;
		uint32_t tmp = OFToBigEndian32((uint32_t)count);

		data = [OFMutableData dataWithCapacity: count + 5];
		[data addItem: &type];
		[data addItems: &tmp count: sizeof(tmp)];
	} else
		@throw [OFOutOfRangeException exception];

	[data addItems: self.items count: count];
	[data makeImmutable];

	return data;
}
@end
