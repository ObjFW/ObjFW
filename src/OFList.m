/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#include <string.h>

#import "OFList.h"
#import "OFString.h"
#import "OFArray.h"

#import "OFEnumerationMutationException.h"
#import "OFInvalidArgumentException.h"

struct _OFListItem {
	struct _OFListItem *previous, *next;
	id object;
};

OF_DIRECT_MEMBERS
@interface OFListEnumerator: OFEnumerator
{
	OFList *_list;
	OFListItem _current;
	unsigned long _mutations, *_mutationsPtr;
}

- (instancetype)initWithList: (OFList *)list
	    mutationsPointer: (unsigned long *)mutationsPtr;
@end

OFListItem
OFListItemNext(OFListItem listItem)
{
	return listItem->next;
}

OFListItem
OFListItemPrevious(OFListItem listItem)
{
	return listItem->previous;
}

id
OFListItemObject(OFListItem listItem)
{
	return listItem->object;
}

@implementation OFList
@synthesize firstListItem = _firstListItem, lastListItem = _lastListItem;

+ (instancetype)list
{
	return objc_autoreleaseReturnValue([[self alloc] init]);
}

- (void)dealloc
{
	OFListItem next;

	for (OFListItem iter = _firstListItem; iter != NULL; iter = next) {
		objc_release(iter->object);
		next = iter->next;
		OFFreeMemory(iter);
	}

	[super dealloc];
}

- (OFListItem)appendObject: (id)object
{
	OFListItem listItem = OFAllocMemory(1, sizeof(*listItem));

	listItem->object = objc_retain(object);
	listItem->next = NULL;
	listItem->previous = _lastListItem;

	if (_lastListItem != NULL)
		_lastListItem->next = listItem;

	_lastListItem = listItem;

	if (_firstListItem == NULL)
		_firstListItem = listItem;

	_count++;
	_mutations++;

	return listItem;
}

- (OFListItem)prependObject: (id)object
{
	OFListItem listItem = OFAllocMemory(1, sizeof(*listItem));

	listItem->object = objc_retain(object);
	listItem->next = _firstListItem;
	listItem->previous = NULL;

	if (_firstListItem != NULL)
		_firstListItem->previous = listItem;

	_firstListItem = listItem;
	if (_lastListItem == NULL)
		_lastListItem = listItem;

	_count++;
	_mutations++;

	return listItem;
}

- (OFListItem)insertObject: (id)object beforeListItem: (OFListItem)listItem
{
	OFListItem newListItem = OFAllocMemory(1, sizeof(*newListItem));

	newListItem->object = objc_retain(object);
	newListItem->next = listItem;
	newListItem->previous = listItem->previous;

	if (listItem->previous != NULL)
		listItem->previous->next = newListItem;

	listItem->previous = newListItem;

	if (listItem == _firstListItem)
		_firstListItem = newListItem;

	_count++;
	_mutations++;

	return newListItem;
}

- (OFListItem)insertObject: (id)object afterListItem: (OFListItem)listItem
{
	OFListItem newListItem = OFAllocMemory(1, sizeof(*newListItem));

	newListItem->object = objc_retain(object);
	newListItem->next = listItem->next;
	newListItem->previous = listItem;

	if (listItem->next != NULL)
		listItem->next->previous = newListItem;

	listItem->next = newListItem;

	if (listItem == _lastListItem)
		_lastListItem = newListItem;

	_count++;
	_mutations++;

	return newListItem;
}

- (void)removeListItem: (OFListItem)listItem
{
	if (listItem->previous != NULL)
		listItem->previous->next = listItem->next;
	if (listItem->next != NULL)
		listItem->next->previous = listItem->previous;

	if (_firstListItem == listItem)
		_firstListItem = listItem->next;
	if (_lastListItem == listItem)
		_lastListItem = listItem->previous;

	_count--;
	_mutations++;

	objc_release(listItem->object);
	OFFreeMemory(listItem);
}

- (id)firstObject
{
	return (_firstListItem != NULL ? _firstListItem->object : nil);
}

- (id)lastObject
{
	return (_lastListItem != NULL ? _lastListItem->object : nil);
}

- (size_t)count
{
	return _count;
}

- (bool)isEqual: (id)object
{
	OFList *list;
	OFListItem iter, iter2;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFList class]])
		return false;

	list = object;

	if (list.count != _count)
		return false;

	for (iter = _firstListItem, iter2 = list.firstListItem;
	    iter != NULL && iter2 != NULL;
	    iter = iter->next, iter2 = iter2->next)
		if (![iter->object isEqual: iter2->object])
			return false;

	/* One is bigger than the other even though we checked the count */
	OFAssert(iter == NULL && iter2 == NULL);

	return true;
}

- (bool)containsObject: (id)object
{
	if (_count == 0)
		return false;

	for (OFListItem iter = _firstListItem; iter != NULL; iter = iter->next)
		if ([iter->object isEqual: object])
			return true;

	return false;
}

- (bool)containsObjectIdenticalTo: (id)object
{
	if (_count == 0)
		return false;

	for (OFListItem iter = _firstListItem; iter != NULL; iter = iter->next)
		if (iter->object == object)
			return true;

	return false;
}

- (void)removeAllObjects
{
	OFListItem next;

	_mutations++;

	for (OFListItem iter = _firstListItem; iter != NULL; iter = next) {
		objc_release(iter->object);
		next = iter->next;
		OFFreeMemory(iter);
	}

	_firstListItem = _lastListItem = NULL;
}

- (id)copy
{
	OFList *copy = [[[self class] alloc] init];
	OFListItem listItem = NULL, previous = NULL;

	@try {
		for (OFListItem iter = _firstListItem;
		    iter != NULL; iter = iter->next) {
			listItem = OFAllocMemory(1, sizeof(*listItem));
			listItem->object = objc_retain(iter->object);
			listItem->next = NULL;
			listItem->previous = previous;

			if (copy->_firstListItem == NULL)
				copy->_firstListItem = listItem;
			if (previous != NULL)
				previous->next = listItem;

			copy->_count++;

			previous = listItem;
		}
	} @catch (id e) {
		objc_release(copy);
		@throw e;
	}

	copy->_lastListItem = listItem;

	return copy;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	for (OFListItem iter = _firstListItem; iter != NULL; iter = iter->next)
		OFHashAddHash(&hash, [iter->object hash]);

	OFHashFinalize(&hash);

	return hash;
}

- (OFString *)description
{
	OFMutableString *ret;

	if (_count == 0)
		return @"[]";

	ret = [OFMutableString stringWithString: @"[\n"];

	for (OFListItem iter = _firstListItem;
	    iter != NULL; iter = iter->next) {
		void *pool = objc_autoreleasePoolPush();

		[ret appendString: [iter->object description]];

		if (iter->next != NULL)
			[ret appendString: @",\n"];

		objc_autoreleasePoolPop(pool);
	}
	[ret replaceOccurrencesOfString: @"\n" withString: @"\n\t"];
	[ret appendString: @"\n]"];

	[ret makeImmutable];

	return ret;
}

- (int)countByEnumeratingWithState: (OFFastEnumerationState *)state
			   objects: (id *)objects
			     count: (int)count
{
	OFListItem listItem;

	memcpy(&listItem, state->extra, sizeof(listItem));

	state->itemsPtr = objects;
	state->mutationsPtr = &_mutations;

	if (state->state == 0) {
		listItem = _firstListItem;
		state->state = 1;
	}

	for (int i = 0; i < count; i++) {
		if (listItem == NULL)
			return i;

		objects[i] = listItem->object;
		listItem = listItem->next;
	}

	memcpy(state->extra, &listItem, sizeof(listItem));

	return count;
}

- (OFEnumerator *)objectEnumerator
{
	return objc_autoreleaseReturnValue(
	    [[OFListEnumerator alloc] initWithList: self
				  mutationsPointer: &_mutations]);
}
@end

@implementation OFListEnumerator
- (instancetype)initWithList: (OFList *)list
	    mutationsPointer: (unsigned long *)mutationsPtr
{
	self = [super init];

	_list = objc_retain(list);
	_current = _list.firstListItem;
	_mutations = *mutationsPtr;
	_mutationsPtr = mutationsPtr;

	return self;
}

- (void)dealloc
{
	objc_release(_list);

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
