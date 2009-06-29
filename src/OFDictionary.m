/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <string.h>

#import "OFDictionary.h"
#import "OFIterator.h"
#import "OFExceptions.h"

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

+ dictionaryWithHashSize: (int)hashsize
{
	return [[[self alloc] initWithHashSize: hashsize] autorelease];
}

+ dictionaryWithKey: (OFObject <OFCopying>*)key
	  andObject: (OFObject*)obj
{
	return [[[self alloc] initWithKey: key
				andObject: obj] autorelease];
}

+ dictionaryWithKeys: (OFArray*)keys
	  andObjects: (OFArray*)objs
{
	return [[[self alloc] initWithKeys: keys
				andObjects: objs] autorelease];
}

+ dictionaryWithKeysAndObjects: (OFObject <OFCopying>*)first, ...
{
	id ret;
	va_list args;

	va_start(args, first);
	ret = [[[self alloc] initWithKey: first
			      andArgList: args] autorelease];
	va_end(args);

	return ret;
}

- init
{
	self = [super init];

	size = 4096;

	@try {
		data = [self allocMemoryForNItems: size
					 withSize: sizeof(OFList*)];
	} @catch (OFException *e) {
		/*
		 * We can't use [super dealloc] on OS X here. Compiler bug?
		 * Anyway, set size to 0 so that [self dealloc] works.
		 */
		size = 0;
		[self dealloc];
		@throw e;
	}
	memset(data, 0, size * sizeof(OFList*));

	return self;
}

- initWithHashSize: (int)hashsize
{
	self = [super init];

	if (hashsize < 8 || hashsize >= 28) {
		Class c = isa;
		[super dealloc];
		@throw [OFInvalidArgumentException newWithClass: c
						    andSelector: _cmd];
	}

	size = (size_t)1 << hashsize;

	@try {
		data = [self allocMemoryForNItems: size
					 withSize: sizeof(OFList*)];
	} @catch (OFException *e) {
		/*
		 * We can't use [super dealloc] on OS X here. Compiler bug?
		 * Anyway, set size to 0 so that [self dealloc] works.
		 */
		size = 0;
		[self dealloc];
		@throw e;
	}
	memset(data, 0, size * sizeof(OFList*));

	return self;
}

- initWithKey: (OFObject <OFCopying>*)key
    andObject: (OFObject*)obj
{
	Class c;
	uint32_t fullhash, hash;

	self = [self init];

	if (key == nil || obj == nil) {
		c = isa;
		[self dealloc];
		@throw [OFInvalidArgumentException newWithClass: isa
						    andSelector: _cmd];
	}

	fullhash = [key hash];
	hash = fullhash & (size - 1);

	@try {
		key = [key copy];
	} @catch (OFException *e) {
		[self dealloc];
		@throw e;
	}

	@try {
		of_dictionary_list_object_t *o;

		data[hash] = [[OFList alloc] initWithListObjectSize:
		    sizeof(of_dictionary_list_object_t)];

		o = (of_dictionary_list_object_t*)[data[hash] append: obj];
		o->key = key;
		o->hash = fullhash;
	} @catch (OFException *e) {
		[key release];
		[self dealloc];
		@throw e;
	}

	return self;
}

- initWithKeys: (OFArray*)keys
    andObjects: (OFArray*)objs
{
	Class c;
	OFObject <OFCopying> **keys_data;
	OFObject **objs_data;
	size_t count, i;

	self = [self init];
	count = [keys count];

	if (keys == nil || objs == nil || count != [objs count]) {
		c = isa;
		[self dealloc];
		@throw [OFInvalidArgumentException newWithClass: isa
						    andSelector: _cmd];
	}

	keys_data = [keys data];
	objs_data = [objs data];

	for (i = 0; i < count; i++) {
		uint32_t fullhash, hash;
		OFObject <OFCopying> *key;

		if (keys_data[i] == nil || objs_data[i] == nil) {
			c = isa;
			[self dealloc];
			@throw [OFInvalidArgumentException newWithClass: isa
							    andSelector: _cmd];
		}

		fullhash = [keys_data[i] hash];
		hash = fullhash & (size - 1);

		@try {
			key = [keys_data[i] copy];
		} @catch (OFException *e) {
			[self dealloc];
			@throw e;
		}

		@try {
			of_dictionary_list_object_t *o;

			if (data[hash] == nil)
				data[hash] = [[OFList alloc]
				    initWithListObjectSize:
				    sizeof(of_dictionary_list_object_t)];

			o = (of_dictionary_list_object_t*)
			    [data[hash] append: objs_data[i]];
			o->key = key;
			o->hash = fullhash;
		} @catch (OFException *e) {
			[key release];
			[self dealloc];
			@throw e;
		}
	}

	return self;
}

- initWithKeysAndObjects: (OFObject <OFCopying>*)first, ...
{
	id ret;
	va_list args;

	va_start(args, first);
	ret = [self initWithKey: first
		     andArgList: args];
	va_end(args);

	return ret;
}

- initWithKey: (OFObject <OFCopying>*)first
   andArgList: (va_list)args
{
	OFObject <OFCopying> *key;
	OFObject *obj;
	Class c;
	uint32_t fullhash, hash;

	self = [self init];
	obj = va_arg(args, OFObject*);

	if (first == nil || obj == nil) {
		c = isa;
		[self dealloc];
		@throw [OFInvalidArgumentException newWithClass: isa
						    andSelector: _cmd];
	}

	fullhash = [first hash];
	hash = fullhash & (size - 1);

	@try {
		key = [first copy];
	} @catch (OFException *e) {
		[self dealloc];
		@throw e;
	}

	@try {
		of_dictionary_list_object_t *o;

		if (data[hash] == nil)
			data[hash] = [[OFList alloc] initWithListObjectSize:
			    sizeof(of_dictionary_list_object_t)];

		o = (of_dictionary_list_object_t*)[data[hash] append: obj];
		o->key = key;
		o->hash = fullhash;
	} @catch (OFException *e) {
		[key release];
		[self dealloc];
		@throw e;
	}

	while ((key = va_arg(args, OFObject <OFCopying>*)) != nil) {
		if ((obj = va_arg(args, OFObject*)) == nil) {
			c = isa;
			[self dealloc];
			@throw [OFInvalidArgumentException newWithClass: isa
							    andSelector: _cmd];
		}

		fullhash = [key hash];
		hash = fullhash & (size - 1);

		@try {
			key = [key copy];
		} @catch (OFException *e) {
			[self dealloc];
			@throw e;
		}

		@try {
			of_dictionary_list_object_t *o;

			if (data[hash] == nil)
				data[hash] = [[OFList alloc]
				    initWithListObjectSize:
				    sizeof(of_dictionary_list_object_t)];

			o = (of_dictionary_list_object_t*)
			    [data[hash] append: obj];
			o->key = key;
			o->hash = fullhash;
		} @catch (OFException *e) {
			[key release];
			[self dealloc];
			@throw e;
		}
	}

	return self;
}

- (float)averageItemsPerBucket
{
	size_t items, buckets, i;

	items = 0;
	buckets = 0;

	for (i = 0; i < size; i++) {
		if (data[i] != nil) {
			items += [data[i] count];
			buckets++;
		}
	}

	return (float)items / buckets;
}

- (id)objectForKey: (OFObject*)key
{
	uint32_t hash;
	of_dictionary_list_object_t *iter;

	if (key == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						    andSelector: _cmd];

	hash = [key hash] & (size - 1);

	if (data[hash] == nil)
		return nil;

	for (iter = (of_dictionary_list_object_t*)[data[hash] first];
	    iter != NULL; iter = iter->next)
		if ([iter->key isEqual: key])
			return iter->object;

	return nil;
}

/* FIXME: Implement this! */
/*
- (BOOL)isEqual
{
}

- (id)copy
{
}

- (id)mutableCopy
{
}
*/

- (void)dealloc
{
	size_t i;

	for (i = 0; i < size; i++) {
		if (data[i] != nil) {
			of_dictionary_list_object_t *iter;

			for (iter = (of_dictionary_list_object_t*)
			    [data[i] first]; iter != NULL; iter = iter->next)
				[iter->key release];

			[data[i] release];
		}
	}

	[super dealloc];
}

- setObject: (OFObject*)obj
     forKey: (OFObject <OFCopying>*)key
{
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}

- removeObjectForKey: (OFObject*)key
{
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}

- changeHashSize: (int)hashsize
{
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}
@end
