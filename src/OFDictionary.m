/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <string.h>

#import "OFDictionary.h"
#import "OFIterator.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"
#import "OFMacros.h"

#define BUCKET_SIZE sizeof(struct of_dictionary_bucket)

/* References for static linking */
void _references_to_categories_of_OFDictionary()
{
	_OFIterator_reference = 1;
}

@implementation OFDictionary
+ dictionary;
{
	return [[[self alloc] init] autorelease];
}

+ dictionaryWithDictionary: (OFDictionary*)dict
{
	return [[[self alloc] initWithDictionary: dict] autorelease];
}

+ dictionaryWithObject: (OFObject*)obj
		forKey: (OFObject <OFCopying>*)key
{
	return [[[self alloc] initWithObject: obj
				      forKey: key] autorelease];
}

+ dictionaryWithObjects: (OFArray*)objs
		forKeys: (OFArray*)keys
{
	return [[[self alloc] initWithObjects: objs
				      forKeys: keys] autorelease];
}

+ dictionaryWithKeysAndObjects: (OFObject <OFCopying>*)first, ...
{
	id ret;
	va_list args;

	va_start(args, first);
	ret = [[[self alloc] initWithKey: first
				 argList: args] autorelease];
	va_end(args);

	return ret;
}

- init
{
	self = [super init];

	size = 1;

	@try {
		data = [self allocMemoryWithSize: BUCKET_SIZE];
	} @catch (OFException *e) {
		/*
		 * We can't use [super dealloc] on OS X here. Compiler bug?
		 * Anyway, set size to 0 so that [self dealloc] works.
		 */
		size = 0;
		[self dealloc];
		@throw e;
	}
	data[0].key = nil;

	return self;
}

- initWithDictionary: (OFDictionary*)dict
{
	size_t i;

	self = [super init];

	if (dict == nil) {
		Class c = isa;
		size = 0;
		[self dealloc];
		@throw [OFInvalidArgumentException newWithClass: c
						       selector: _cmd];
	}

	@try {
		data = [self allocMemoryForNItems: dict->size
					 withSize: BUCKET_SIZE];
	} @catch (OFException *e) {
		/*
		 * We can't use [super dealloc] on OS X here. Compiler bug?
		 * Anyway, we didn't do anything yet anyway, so [self dealloc]
		 * works.
		 */
		[self dealloc];
		@throw e;
	}

	size = dict->size;
	count = dict->count;

	for (i = 0; i < size; i++) {
		if (dict->data[i].key != nil) {
			data[i].key = [dict->data[i].key copy];
			data[i].object = [dict->data[i].object retain];
			data[i].hash = dict->data[i].hash;
		} else
			data[i].key = nil;
	}

	return self;
}

- initWithObject: (OFObject*)obj
	  forKey: (OFObject <OFCopying>*)key
{
	const SEL sel = @selector(setObject:forKey:);
	IMP set = [OFMutableDictionary instanceMethodForSelector: sel];

	self = [self init];

	@try {
		set(self, sel, obj, key);
	} @catch (OFException *e) {
		[self dealloc];
		@throw e;
	}

	return self;
}

/* FIXME: Do it without resizing! */
- initWithObjects: (OFArray*)objs
	  forKeys: (OFArray*)keys
{
	id *objs_carray, *keys_carray;
	size_t objs_count, i;
	const SEL sel = @selector(setObject:forKey:);
	IMP set = [OFMutableDictionary instanceMethodForSelector: sel];

	self = [self init];

	objs_carray = [objs cArray];
	keys_carray = [keys cArray];
	objs_count = [objs count];

	if (objs == nil || keys == nil || objs_count != [keys count]) {
		Class c = isa;
		[self dealloc];
		@throw [OFInvalidArgumentException newWithClass: c
						       selector: _cmd];
	}

	@try {
		for (i = 0; i < objs_count; i++)
			set(self, sel, objs_carray[i], keys_carray[i]);
	} @catch (OFException *e) {
		[self dealloc];
		@throw e;
	}

	return self;
}

- initWithKeysAndObjects: (OFObject <OFCopying>*)first, ...
{
	id ret;
	va_list args;

	va_start(args, first);
	ret = [self initWithKey: first
			argList: args];
	va_end(args);

	return ret;
}

/* FIXME: Possible without resizing? */
- initWithKey: (OFObject <OFCopying>*)key
      argList: (va_list)args
{
	const SEL sel = @selector(setObject:forKey:);
	IMP set = [OFMutableDictionary instanceMethodForSelector: sel];

	self = [self init];

	@try {
		set(self, sel, va_arg(args, OFObject*), key);
		while ((key = va_arg(args, OFObject <OFCopying>*)) != nil)
			set(self, sel, va_arg(args, OFObject*), key);
	} @catch (OFException *e) {
		[self dealloc];
		@throw e;
	}

	return self;
}

- (id)objectForKey: (OFObject <OFCopying>*)key
{
	uint32_t i, hash;

	if (key == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	hash = [key hash];

	for (i = hash & (size - 1); i < size && data[i].key != nil &&
	    ![data[i].key isEqual: key]; i++);

	/* In case the last bucket is already used */
	if (i >= size)
		for (i = 0; i < size && data[i].key != nil &&
		    ![data[i].key isEqual: key]; i++);

	/* Key not in dictionary */
	if (i >= size || data[i].key == nil)
		return nil;

	return data[i].object;
}

- (size_t)count
{
	return count;
}

- (id)copy
{
	return [self retain];
}

- (id)mutableCopy
{
	return [[OFMutableDictionary alloc] initWithDictionary: self];
}

- (BOOL)isEqual: (OFDictionary*)dict
{
	size_t i;

	if ([dict count] != count)
		return NO;

	for (i = 0; i < size; i++)
		if (data[i].key != nil &&
		    ![[dict objectForKey: data[i].key] isEqual: data[i].object])
			return NO;

	return YES;
}

- (void)dealloc
{
	size_t i;

	for (i = 0; i < size; i++) {
		if (data[i].key != nil) {
			[data[i].key release];
			[data[i].object release];
		}
	}

	[super dealloc];
}

- setObject: (OFObject*)obj
     forKey: (OFObject <OFCopying>*)key
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- removeObjectForKey: (OFObject*)key
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (uint32_t)hash
{
	size_t i;
	uint32_t hash;

	OF_HASH_INIT(hash);

	for (i = 0; i < size; i++) {
		if (data[i].key != nil) {
			uint32_t kh = [data[i].key hash];

			OF_HASH_ADD(hash, kh >> 24);
			OF_HASH_ADD(hash, (kh >> 16) & 0xFF);
			OF_HASH_ADD(hash, (kh >> 8) & 0xFF);
			OF_HASH_ADD(hash, kh & 0xFF);

			OF_HASH_ADD(hash, data[i].hash >> 24);
			OF_HASH_ADD(hash, (data[i].hash >> 16) & 0xFF);
			OF_HASH_ADD(hash, (data[i].hash >> 8) & 0xFF);
			OF_HASH_ADD(hash, data[i].hash & 0xFF);
		}
	}

	OF_HASH_FINALIZE(hash);

	return hash;
}
@end
