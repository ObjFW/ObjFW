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

#include "assert.h"

#import "OFList.h"
#import "OFString.h"
#import "OFXMLElement.h"
#import "OFArray.h"

#import "OFEnumerationMutationException.h"
#import "OFInvalidArgumentException.h"

#import "autorelease.h"
#import "macros.h"

@implementation OFList
+ (instancetype)list
{
	return [[[self alloc] init] autorelease];
}

- initWithSerialization: (OFXMLElement*)element
{
	self = [self init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFEnumerator *enumerator;
		OFXMLElement *child;

		if (![[element name] isEqual: [self className]] ||
		    ![[element namespace] isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException
			    exceptionWithClass: [self class]
				      selector: _cmd];

		enumerator = [[element elementsForNamespace:
		    OF_SERIALIZATION_NS] objectEnumerator];
		while ((child = [enumerator nextObject]) != nil) {
			void *pool2 = objc_autoreleasePoolPush();

			[self appendObject: [child objectByDeserializing]];

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
	of_list_object_t *iter;

	for (iter = _firstListObject; iter != NULL; iter = iter->next)
		[iter->object release];

	[super dealloc];
}

- (of_list_object_t*)firstListObject
{
	return _firstListObject;
}

- (of_list_object_t*)lastListObject
{
	return _lastListObject;
}

- (of_list_object_t*)appendObject: (id)object
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

- (of_list_object_t*)prependObject: (id)object
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

- (of_list_object_t*)insertObject: (id)object
		 beforeListObject: (of_list_object_t*)listObject
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

- (of_list_object_t*)insertObject: (id)object
		  afterListObject: (of_list_object_t*)listObject
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

- (void)removeListObject: (of_list_object_t*)listObject
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

- (BOOL)isEqual: (id)object
{
	OFList *list;
	of_list_object_t *iter, *iter2;

	if (![object isKindOfClass: [OFList class]])
		return NO;

	list = object;

	if ([list count] != _count)
		return NO;

	for (iter = _firstListObject, iter2 = [list firstListObject];
	    iter != NULL && iter2 != NULL;
	    iter = iter->next, iter2 = iter2->next)
		if (![iter->object isEqual: iter2->object])
			return NO;

	/* One is bigger than the other even though we checked the count */
	assert(iter == NULL && iter2 == NULL);

	return YES;
}

- (BOOL)containsObject: (id)object
{
	of_list_object_t *iter;

	if (_count == 0)
		return NO;

	for (iter = _firstListObject; iter != NULL; iter = iter->next)
		if ([iter->object isEqual: object])
			return YES;

	return NO;
}

- (BOOL)containsObjectIdenticalTo: (id)object
{
	of_list_object_t *iter;

	if (_count == 0)
		return NO;

	for (iter = _firstListObject; iter != NULL; iter = iter->next)
		if (iter->object == object)
			return YES;

	return NO;
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

- copy
{
	OFList *copy = [[[self class] alloc] init];
	of_list_object_t *iter, *listObject, *previous;

	listObject = NULL;
	previous = NULL;

	@try {
		for (iter = _firstListObject; iter != NULL; iter = iter->next) {
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
	of_list_object_t *iter;
	uint32_t hash;

	OF_HASH_INIT(hash);

	for (iter = _firstListObject; iter != NULL; iter = iter->next)
		OF_HASH_ADD_HASH(hash, [iter->object hash]);

	OF_HASH_FINALIZE(hash);

	return hash;
}

- (OFString*)description
{
	OFMutableString *ret;
	of_list_object_t *iter;

	if (_count == 0)
		return @"[]";

	ret = [OFMutableString stringWithString: @"[\n"];

	for (iter = _firstListObject; iter != NULL; iter = iter->next) {
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

- (OFXMLElement*)XMLElementBySerializing
{
	OFXMLElement *element;
	of_list_object_t *iter;

	element = [OFXMLElement elementWithName: [self className]
				      namespace: OF_SERIALIZATION_NS];

	for (iter = _firstListObject; iter != NULL; iter = iter->next) {
		void *pool = objc_autoreleasePoolPush();

		[element addChild: [iter->object XMLElementBySerializing]];

		objc_autoreleasePoolPop(pool);
	}

	return element;
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t*)state
			   objects: (id*)objects
			     count: (int)count
{
	of_list_object_t **listObject = (of_list_object_t**)&state->extra[0];
	int i;

	state->itemsPtr = objects;
	state->mutationsPtr = &_mutations;

	if (state->state == 0) {
		*listObject = _firstListObject;
		state->state = 1;
	}

	for (i = 0; i < count; i++) {
		if (*listObject == NULL)
			return i;

		objects[i] = (*listObject)->object;
		*listObject = (*listObject)->next;
	}

	return count;
}

- (OFEnumerator*)objectEnumerator
{
	return [[[OFListEnumerator alloc]
		initWithList: self
	    mutationsPointer: &_mutations] autorelease];
}
@end

@implementation OFListEnumerator
-     initWithList: (OFList*)list
  mutationsPointer: (unsigned long*)mutationsPtr
{
	self = [super init];

	_list = [list retain];
	_current = [list firstListObject];
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
		    exceptionWithClass: [self class]
				object: _list];

	if (_current == NULL)
		return nil;

	ret = _current->object;
	_current = _current->next;

	return ret;
}

- (void)reset
{
	if (*_mutationsPtr != _mutations)
		@throw [OFEnumerationMutationException
		    exceptionWithClass: [self class]
				object: _list];

	_current = [_list firstListObject];
}
@end
