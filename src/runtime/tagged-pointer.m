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

#import "ObjFWRT.h"

#import "private.h"

#define numTaggedPointerBits 4
#define maxNumTaggedPointerClasses (1 << (numTaggedPointerBits - 1))

Class _objc_taggedPointerClasses[maxNumTaggedPointerClasses];
static int taggedPointerClassesCount;
uintptr_t _objc_taggedPointerSecret;

void
objc_setTaggedPointerSecret(uintptr_t secret)
{
	_objc_taggedPointerSecret = secret & ~(uintptr_t)1;
}

int
objc_registerTaggedPointerClass(Class class)
{
	int i;

	_objc_globalMutex_lock();

	if (taggedPointerClassesCount == maxNumTaggedPointerClasses) {
		_objc_globalMutex_unlock();
		return -1;
	}

	i = taggedPointerClassesCount++;
	_objc_taggedPointerClasses[i] = class;

	_objc_globalMutex_unlock();

	return i;
}

bool
object_isTaggedPointer(id object)
{
	uintptr_t pointer = (uintptr_t)object;

	return pointer & 1;
}

Class
_object_getTaggedPointerClass(id object)
{
	uintptr_t pointer = (uintptr_t)object ^ _objc_taggedPointerSecret;

	pointer &= (1 << numTaggedPointerBits) - 1;
	pointer >>= 1;

	if (pointer >= maxNumTaggedPointerClasses)
		return Nil;

	return _objc_taggedPointerClasses[pointer];
}

uintptr_t
object_getTaggedPointerValue(id object)
{
	uintptr_t pointer = (uintptr_t)object ^ _objc_taggedPointerSecret;

	pointer >>= numTaggedPointerBits;

	return pointer;
}

id
objc_createTaggedPointer(int class, uintptr_t value)
{
	uintptr_t pointer;

	if (class < 0 || class >= maxNumTaggedPointerClasses)
		return nil;

	if (value > (UINTPTR_MAX >> numTaggedPointerBits))
		return nil;

	pointer = (class << 1) | 1;
	pointer |= (value << numTaggedPointerBits);

	return (id)(pointer ^ _objc_taggedPointerSecret);
}
