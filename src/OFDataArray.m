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

#include <stdio.h>
#include <string.h>
#include <limits.h>

#import "OFDataArray.h"
#import "OFString.h"
#import "OFFile.h"
#import "OFURL.h"
#import "OFHTTPRequest.h"
#import "OFXMLElement.h"
#import "OFAutoreleasePool.h"

#import "OFHTTPRequestFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

#import "base64.h"
#import "macros.h"

/* References for static linking */
void _references_to_categories_of_OFDataArray(void)
{
	_OFDataArray_Hashing_reference = 1;
}

@implementation OFDataArray
+ dataArray
{
	return [[[self alloc] init] autorelease];
}

+ dataArrayWithItemSize: (size_t)itemSize
{
	return [[[self alloc] initWithItemSize: itemSize] autorelease];
}

+ dataArrayWithContentsOfFile: (OFString*)path
{
	return [[[self alloc] initWithContentsOfFile: path] autorelease];
}

+ dataArrayWithContentsOfURL: (OFURL*)URL
{
	return [[[self alloc] initWithContentsOfURL: URL] autorelease];
}

+ dataArrayWithBase64EncodedString: (OFString*)string
{
	return [[[self alloc] initWithBase64EncodedString: string] autorelease];
}

- init
{
	self = [super init];

	itemSize = 1;

	return self;
}

- initWithItemSize: (size_t)itemSize_
{
	self = [super init];

	if (itemSize_ == 0) {
		Class c = isa;
		[self release];
		@throw [OFInvalidArgumentException exceptionWithClass: c
							     selector: _cmd];
	}

	itemSize = itemSize_;

	return self;
}

- initWithContentsOfFile: (OFString*)path
{
	self = [super init];

	@try {
		OFFile *file = [[OFFile alloc] initWithPath: path
						       mode: @"rb"];

		itemSize = 1;

		@try {
			char *buffer = [self allocMemoryWithSize: of_pagesize];

			while (![file isAtEndOfStream]) {
				size_t length;

				length = [file readIntoBuffer: buffer
						       length: of_pagesize];
				[self addItemsFromCArray: buffer
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
	OFAutoreleasePool *pool;
	OFHTTPRequest *request;
	OFHTTPRequestResult *result;
	Class c;

	c = isa;
	[self release];

	pool = [[OFAutoreleasePool alloc] init];

	if ([[URL scheme] isEqual: @"file"]) {
		self = [[c alloc] initWithContentsOfFile: [URL path]];
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

	self = [[result data] retain];
	[pool release];
	return self;
}

- initWithBase64EncodedString: (OFString*)string
{
	self = [super init];

	itemSize = 1;

	if (!of_base64_decode(self,
	    [string cStringWithEncoding: OF_STRING_ENCODING_ASCII],
	    [string cStringLengthWithEncoding: OF_STRING_ENCODING_ASCII])) {
		Class c = isa;
		[self release];
		@throw [OFInvalidEncodingException exceptionWithClass: c];
	}

	return self;
}

- initWithSerialization: (OFXMLElement*)element
{
	self = [super init];

	itemSize = 1;

	@try {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
		OFString *stringValue;

		if (![[element name] isEqual: [self className]] ||
		    ![[element namespace] isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException
			    exceptionWithClass: isa
				      selector: _cmd];

		stringValue = [element stringValue];

		if (!of_base64_decode(self,
		    [stringValue cStringWithEncoding: OF_STRING_ENCODING_ASCII],
		    [stringValue cStringLengthWithEncoding:
		    OF_STRING_ENCODING_ASCII]))
			@throw [OFInvalidEncodingException
			    exceptionWithClass: isa];

		[pool release];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (size_t)count
{
	return count;
}

- (size_t)itemSize
{
	return itemSize;
}

- (void*)cArray
{
	return data;
}

- (void*)itemAtIndex: (size_t)index
{
	if (index >= count)
		@throw [OFOutOfRangeException exceptionWithClass: isa];

	return data + index * itemSize;
}

- (void*)firstItem
{
	if (data == NULL || count == 0)
		return NULL;

	return data;
}

- (void*)lastItem
{
	if (data == NULL || count == 0)
		return NULL;

	return data + (count - 1) * itemSize;
}

- (void)addItem: (const void*)item
{
	if (SIZE_MAX - count < 1)
		@throw [OFOutOfRangeException exceptionWithClass: isa];

	data = [self resizeMemory: data
			 itemSize: itemSize
			    count: count + 1];

	memcpy(data + count * itemSize, item, itemSize);

	count++;
}

- (void)insertItem: (const void*)item
	   atIndex: (size_t)index
{
	[self insertItemsFromCArray: item
			    atIndex: index
			      count: 1];
}

- (void)addItemsFromCArray: (const void*)cArray
		     count: (size_t)nItems
{
	if (nItems > SIZE_MAX - count)
		@throw [OFOutOfRangeException exceptionWithClass: isa];

	data = [self resizeMemory: data
			 itemSize: itemSize
			    count: count + nItems];

	memcpy(data + count * itemSize, cArray, nItems * itemSize);
	count += nItems;
}

- (void)insertItemsFromCArray: (const void*)cArray
		      atIndex: (size_t)index
			count: (size_t)nItems
{
	if (nItems > SIZE_MAX - count || index > count)
		@throw [OFOutOfRangeException exceptionWithClass: isa];

	data = [self resizeMemory: data
			 itemSize: itemSize
			    count: count + nItems];

	memmove(data + (index + nItems) * itemSize, data + index * itemSize,
	    (count - index) * itemSize);
	memcpy(data + index * itemSize, cArray, nItems * itemSize);

	count += nItems;
}

- (void)removeItemAtIndex: (size_t)index
{
	[self removeItemsInRange: of_range(index, 1)];
}

- (void)removeItemsInRange: (of_range_t)range
{
	if (range.start + range.length > count)
		@throw [OFOutOfRangeException exceptionWithClass: isa];

	memmove(data + range.start * itemSize,
	    data + (range.start + range.length) * itemSize,
	    (count - range.start - range.length) * itemSize);

	count -= range.length;
	@try {
		data = [self resizeMemory: data
				 itemSize: itemSize
				    count: count];
	} @catch (OFOutOfMemoryException *e) {
		/* We don't really care, as we only made it smaller */
	}
}

- (void)removeLastItem
{
	if (count < 1)
		@throw [OFOutOfRangeException exceptionWithClass: isa];

	count--;
	@try {
		data = [self resizeMemory: data
				 itemSize: itemSize
				    count: count];
	} @catch (OFOutOfMemoryException *e) {
		/* We don't care, as we only made it smaller */
	}
}

- (void)removeAllItems
{
	[self freeMemory: data];

	data = NULL;
	count = 0;
}

- copy
{
	OFDataArray *copy = [[isa alloc] initWithItemSize: itemSize];

	[copy addItemsFromCArray: data
			   count: count];

	return copy;
}

- (BOOL)isEqual: (id)object
{
	OFDataArray *otherDataArray;

	if (![object isKindOfClass: [OFDataArray class]])
		return NO;

	otherDataArray = object;

	if ([otherDataArray count] != count ||
	    [otherDataArray itemSize] != itemSize)
		return NO;
	if (memcmp([otherDataArray cArray], data, count * itemSize))
		return NO;

	return YES;
}

- (of_comparison_result_t)compare: (id)object
{
	OFDataArray *otherDataArray;
	int comparison;
	size_t otherCount, minimumCount;

	if (![object isKindOfClass: [OFDataArray class]])
		@throw [OFInvalidArgumentException exceptionWithClass: isa
							     selector: _cmd];
	otherDataArray = object;

	if ([otherDataArray itemSize] != itemSize)
		@throw [OFInvalidArgumentException exceptionWithClass: isa
							     selector: _cmd];

	otherCount = [otherDataArray count];
	minimumCount = (count > otherCount ? otherCount : count);

	if ((comparison = memcmp(data, [otherDataArray cArray],
	    minimumCount * itemSize)) == 0) {
		if (count > otherCount)
			return OF_ORDERED_DESCENDING;
		if (count < otherCount)
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
	for (i = 0; i < count * itemSize; i++)
		OF_HASH_ADD(hash, ((char*)data)[i]);
	OF_HASH_FINALIZE(hash);

	return hash;
}

- (OFString*)stringByBase64Encoding
{
	return of_base64_encode(data, count * itemSize);
}

- (void)writeToFile: (OFString*)path
{
	OFFile *file = [[OFFile alloc] initWithPath: path
					       mode: @"wb"];

	@try {
		[file writeBuffer: data
			   length: count * itemSize];
	} @finally {
		[file release];
	}
}

- (OFXMLElement*)XMLElementBySerializing
{
	OFAutoreleasePool *pool;
	OFXMLElement *element;

	if (itemSize != 1)
		@throw [OFNotImplementedException exceptionWithClass: isa
							    selector: _cmd];

	pool = [[OFAutoreleasePool alloc] init];
	element = [OFXMLElement
	    elementWithName: [self className]
		  namespace: OF_SERIALIZATION_NS
		stringValue: of_base64_encode(data, count * itemSize)];

	[element retain];
	[pool release];
	[element autorelease];

	return element;
}
@end

@implementation OFBigDataArray
- (void)addItem: (const void*)item
{
	size_t newSize, lastPageByte;

	if (SIZE_MAX - count < 1 || count + 1 > SIZE_MAX / itemSize)
		@throw [OFOutOfRangeException exceptionWithClass: isa];

	lastPageByte = of_pagesize - 1;
	newSize = ((count + 1) * itemSize + lastPageByte) & ~lastPageByte;

	if (size != newSize)
		data = [self resizeMemory: data
				   toSize: newSize];

	memcpy(data + count * itemSize, item, itemSize);

	count++;
	size = newSize;
}

- (void)addItemsFromCArray: (const void*)cArray
		     count: (size_t)nItems
{
	size_t newSize, lastPageByte;

	if (nItems > SIZE_MAX - count || count + nItems > SIZE_MAX / itemSize)
		@throw [OFOutOfRangeException exceptionWithClass: isa];

	lastPageByte = of_pagesize - 1;
	newSize = ((count + nItems) * itemSize + lastPageByte) & ~lastPageByte;

	if (size != newSize)
		data = [self resizeMemory: data
				   toSize: newSize];

	memcpy(data + count * itemSize, cArray, nItems * itemSize);

	count += nItems;
	size = newSize;
}

- (void)insertItemsFromCArray: (const void*)cArray
		      atIndex: (size_t)index
			count: (size_t)nItems
{
	size_t newSize, lastPageByte;

	if (nItems > SIZE_MAX - count || index > count ||
	    count + nItems > SIZE_MAX / itemSize)
		@throw [OFOutOfRangeException exceptionWithClass: isa];

	lastPageByte = of_pagesize - 1;
	newSize = ((count + nItems) * itemSize + lastPageByte) & ~lastPageByte;

	if (size != newSize)
		data = [self resizeMemory: data
				   toSize: newSize];

	memmove(data + (index + nItems) * itemSize, data + index * itemSize,
	    (count - index) * itemSize);
	memcpy(data + index * itemSize, cArray, nItems * itemSize);

	count += nItems;
	size = newSize;
}

- (void)removeItemsInRange: (of_range_t)range
{
	size_t newSize, lastPageByte;

	if (range.start + range.length > count)
		@throw [OFOutOfRangeException exceptionWithClass: isa];

	memmove(data + range.start * itemSize,
	    data + (range.start + range.length) * itemSize,
	    (count - range.start - range.length) * itemSize);

	count -= range.length;
	lastPageByte = of_pagesize - 1;
	newSize = (count * itemSize + lastPageByte) & ~lastPageByte;

	if (size != newSize)
		data = [self resizeMemory: data
				   toSize: newSize];
	size = newSize;
}

- (void)removeLastItem
{
	size_t newSize, lastPageByte;

	if (count < 1)
		@throw [OFOutOfRangeException exceptionWithClass: isa];

	count--;
	lastPageByte = of_pagesize - 1;
	newSize = (count * itemSize + lastPageByte) & ~lastPageByte;

	if (size != newSize) {
		@try {
			data = [self resizeMemory: data
					   toSize: newSize];
		} @catch (OFOutOfMemoryException *e) {
			/* We don't care, as we only made it smaller */
		}

		size = newSize;
	}
}

- (void)removeAllItems
{
	[self freeMemory: data];

	data = NULL;
	count = 0;
	size = 0;
}
@end
