/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#import "ObjFWRT.h"

#import "private.h"

#define numTaggedPointerBits 4
#define maxNumTaggedPointerClasses (1 << (numTaggedPointerBits - 1))

Class objc_taggedPointerClasses[maxNumTaggedPointerClasses];
static int taggedPointerClassesCount;
uintptr_t objc_taggedPointerSecret;

void
objc_setTaggedPointerSecret(uintptr_t secret)
{
	objc_taggedPointerSecret = secret & ~(uintptr_t)1;
}

int
objc_registerTaggedPointerClass(Class class)
{
	int i;

	objc_globalMutex_lock();

	if (taggedPointerClassesCount == maxNumTaggedPointerClasses) {
		objc_globalMutex_unlock();
		return -1;
	}

	i = taggedPointerClassesCount++;
	objc_taggedPointerClasses[i] = class;

	objc_globalMutex_unlock();

	return i;
}

bool
object_isTaggedPointer(id object)
{
	uintptr_t pointer = (uintptr_t)object;

	return pointer & 1;
}

Class
object_getTaggedPointerClass(id object)
{
	uintptr_t pointer = (uintptr_t)object ^ objc_taggedPointerSecret;

	pointer &= (1 << numTaggedPointerBits) - 1;
	pointer >>= 1;

	if (pointer >= maxNumTaggedPointerClasses)
		return Nil;

	return objc_taggedPointerClasses[pointer];
}

uintptr_t
object_getTaggedPointerValue(id object)
{
	uintptr_t pointer = (uintptr_t)object ^ objc_taggedPointerSecret;

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

	return (id)(pointer ^ objc_taggedPointerSecret);
}
