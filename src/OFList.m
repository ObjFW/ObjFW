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

#include <string.h>
#include <assert.h>

#import "OFList.h"
#import "OFString.h"
#import "OFXMLElement.h"
#import "OFArray.h"

#import "OFEnumerationMutationException.h"
#import "OFInvalidArgumentException.h"

@implementation OFList
@synthesize firstListObject = _firstListObject;
@synthesize lastListObject = _lastListObject;

+ (instancetype)list
{
	return [[[self alloc] init] autorelease];
}

- (instancetype)initWithSerialization: (OFXMLElement *)element
{
	self = [self init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		if (![element.name isEqual: self.className] ||
		    ![element.namespace isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException exception];

		for (OFXMLElement *child in
		    [element elementsForNamespace: OF_SERIALIZATION_NS]) {
			void *pool2 = objc_autoreleasePoolPush();

			[self appendObject: child.objectByDeserializing];

			objc_autoreleasePoolPop(pool2);
		}

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	for (of_list_object_t *iter = _firstListObject;
	    iter != NULL; iter = iter->next)
		[iter->object release];

	[super dealloc];
}

- (of_list_object_t *)appendObject: (id)object
{
	of_list_object_t *listObject;

	listObject = [self allocMemoryWithSize: sizeof(of_list_object_t)];
	listObject->object = [object retain];
	listObject->next = NULL;
	listObject->previous = _lastListObject;

	if (_lastListObject != NULL)
		_lastListObject->next = listObject;

	_lastListObject = listObject;

	if (_firstListObject == NULL)
		_firstListObject = listObject;

	_count++;
	_mutations++;

	return listObject;
}

- (of_list_object_t *)prependObject: (id)object
{
	of_list_object_t *listObject;

	listObject = [self allocMemoryWithSize: sizeof(of_list_object_t)];
	listObject->object = [object retain];
	listObject->next = _firstListObject;
	listObject->previous = NULL;

	if (_firstListObject != NULL)
		_firstListObject->previous = listObject;

	_firstListObject = listObject;
	if (_lastListObject == NULL)
		_lastListObject = listObject;

	_count++;
	_mutations++;

	return listObject;
}

- (of_list_object_t *)insertObject: (id)object
		  beforeListObject: (of_list_object_t *)listObject
{
	of_list_object_t *newListObject;

	newListObject = [self allocMemoryWithSize: sizeof(of_list_object_t)];
	newListObject->object = [object retain];
	newListObject->next = listObject;
	newListObject->previous = listObject->previous;

	if (listObject->previous != NULL)
		listObject->previous->next = newListObject;

	listObject->previous = newListObject;

	if (listObject == _firstListObject)
		_firstListObject = newListObject;

	_count++;
	_mutations++;

	return newListObject;
}

- (of_list_object_t *)insertObject: (id)object
		   afterListObject: (of_list_object_t *)listObject
{
	of_list_object_t *newListObject;

	newListObject = [self allocMemoryWithSize: sizeof(of_list_object_t)];
	newListObject->object = [object retain];
	newListObject->next = listObject->next;
	newListObject->previous = listObject;

	if (listObject->next != NULL)
		listObject->next->previous = newListObject;

	listObject->next = newListObject;

	if (listObject == _lastListObject)
		_lastListObject = newListObject;

	_count++;
	_mutations++;

	return newListObject;
}

- (void)removeListObject: (of_list_object_t *)listObject
{
	if (listObject->previous != NULL)
		listObject->previous->next = listObject->next;
	if (listObject->next != NULL)
		listObject->next->previous = listObject->previous;

	if (_firstListObject == listObject)
		_firstListObject = listObject->next;
	if (_lastListObject == listObject)
		_lastListObject = listObject->previous;

	_count--;
	_mutations++;

	[listObject->object release];

	[self freeMemory: listObject];
}

- (id)firstObject
{
	return (_firstListObject != NULL ? _firstListObject->object : nil);
}

- (id)lastObject
{
	return (_lastListObject != NULL ? _lastListObject->object : nil);
}

- (size_t)count
{
	return _count;
}

- (bool)isEqual: (id)object
{
	OFList *list;
	of_list_object_t *iter, *iter2;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFList class]])
		return false;

	list = object;

	if (list.count != _count)
		return false;

	for (iter = _firstListObject, iter2 = list.firstListObject;
	    iter != NULL && iter2 != NULL;
	    iter = iter->next, iter2 = iter2->next)
		if (![iter->object isEqual: iter2->object])
			return false;

	/* One is bigger than the other even though we checked the count */
	assert(iter == NULL && iter2 == NULL);

	return true;
}

- (bool)containsObject: (id)object
{
	if (_count == 0)
		return false;

	for (of_list_object_t *iter = _firstListObject;
	    iter != NULL; iter = iter->next)
		if ([iter->object isEqual: object])
			return true;

	return false;
}

- (bool)containsObjectIdenticalTo: (id)object
{
	if (_count == 0)
		return false;

	for (of_list_object_t *iter = _firstListObject;
	    iter != NULL; iter = iter->next)
		if (iter->object == object)
			return true;

	return false;
}

- (void)removeAllObjects
{
	of_list_object_t *iter, *next;

	_mutations++;

	for (iter = _firstListObject; iter != NULL; iter = next) {
		next = iter->next;

		[iter->object release];
		[self freeMemory: iter];
	}

	_firstListObject = _lastListObject = NULL;
}

- (id)copy
{
	OFList *copy = [[[self class] alloc] init];
	of_list_object_t *listObject, *previous;

	listObject = NULL;
	previous = NULL;

	@try {
		for (of_list_object_t *iter = _firstListObject;
		    iter != NULL; iter = iter->next) {
			listObject = [copy allocMemoryWithSize:
			    sizeof(of_list_object_t)];
			listObject->object = [iter->object retain];
			listObject->next = NULL;
			listObject->previous = previous;

			if (copy->_firstListObject == NULL)
				copy->_firstListObject = listObject;
			if (previous != NULL)
				previous->next = listObject;

			copy->_count++;

			previous = listObject;
		}
	} @catch (id e) {
		[copy release];
		@throw e;
	}

	copy->_lastListObject = listObject;

	return copy;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	for (of_list_object_t *iter = _firstListObject;
	    iter != NULL; iter = iter->next)
		OF_HASH_ADD_HASH(hash, [iter->object hash]);

	OF_HASH_FINALIZE(hash);

	return hash;
}

- (OFString *)description
{
	OFMutableString *ret;

	if (_count == 0)
		return @"[]";

	ret = [OFMutableString stringWithString: @"[\n"];

	for (of_list_object_t *iter = _firstListObject;
	    iter != NULL; iter = iter->next) {
		void *pool = objc_autoreleasePoolPush();

		[ret appendString: [iter->object description]];

		if (iter->next != NULL)
			[ret appendString: @",\n"];

		objc_autoreleasePoolPop(pool);
	}
	[ret replaceOccurrencesOfString: @"\n"
			     withString: @"\n\t"];
	[ret appendString: @"\n]"];

	[ret makeImmutable];

	return ret;
}

- (OFXMLElement *)XMLElementBySerializing
{
	OFXMLElement *element =
	    [OFXMLElement elementWithName: self.className
				namespace: OF_SERIALIZATION_NS];

	for (of_list_object_t *iter = _firstListObject;
	    iter != NULL; iter = iter->next) {
		void *pool = objc_autoreleasePoolPush();

		[element addChild: [iter->object XMLElementBySerializing]];

		objc_autoreleasePoolPop(pool);
	}

	return element;
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t *)state
			   objects: (id *)objects
			     count: (int)count
{
	of_list_object_t *listObject;

	memcpy(&listObject, state->extra, sizeof(listObject));

	state->itemsPtr = objects;
	state->mutationsPtr = &_mutations;

	if (state->state == 0) {
		listObject = _firstListObject;
		state->state = 1;
	}

	for (int i = 0; i < count; i++) {
		if (listObject == NULL)
			return i;

		objects[i] = listObject->object;
		listObject = listObject->next;
	}

	memcpy(state->extra, &listObject, sizeof(listObject));

	return count;
}

- (OFEnumerator *)objectEnumerator
{
	return [[[OFListEnumerator alloc]
		initWithList: self
	    mutationsPointer: &_mutations] autorelease];
}
@end

@implementation OFListEnumerator
- (instancetype)initWithList: (OFList *)list
	    mutationsPointer: (unsigned long *)mutationsPtr
{
	self = [super init];

	_list = [list retain];
	_current = _list.firstListObject;
	_mutations = *mutationsPtr;
	_mutationsPtr = mutationsPtr;

	return self;
}

- (void)dealloc
{
	[_list release];

	[super dealloc];
}

- (id)nextObject
{
	id ret;

	if (*_mutationsPtr != _mutations)
		@throw [OFEnumerationMutationException
		    exceptionWithObject: _list];

	if (_current == NULL)
		return nil;

	ret = _current->object;
	_current = _current->next;

	return ret;
}
@end
