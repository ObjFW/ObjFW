/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

#define TAGGED_POINTER_BITS 4
#define NUM_TAGGED_POINTER_CLASSES (1 << (TAGGED_POINTER_BITS - 1))

Class objc_tagged_pointer_classes[NUM_TAGGED_POINTER_CLASSES];
static int taggedPointerClassesCount;
uintptr_t objc_tagged_pointer_secret;

void
objc_setTaggedPointerSecret(uintptr_t secret)
{
	objc_tagged_pointer_secret = secret & ~(uintptr_t)1;
}

int
objc_registerTaggedPointerClass(Class class)
{
	int i;

	objc_global_mutex_lock();

	if (taggedPointerClassesCount == NUM_TAGGED_POINTER_CLASSES) {
		objc_global_mutex_unlock();
		return -1;
	}

	i = taggedPointerClassesCount++;
	objc_tagged_pointer_classes[i] = class;

	objc_global_mutex_unlock();

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
	uintptr_t pointer = (uintptr_t)object ^ objc_tagged_pointer_secret;

	pointer &= (1 << TAGGED_POINTER_BITS) - 1;
	pointer >>= 1;

	if (pointer >= NUM_TAGGED_POINTER_CLASSES)
		return Nil;

	return objc_tagged_pointer_classes[pointer];
}

uintptr_t
object_getTaggedPointerValue(id object)
{
	uintptr_t pointer = (uintptr_t)object ^ objc_tagged_pointer_secret;

	pointer >>= TAGGED_POINTER_BITS;

	return pointer;
}

id
objc_createTaggedPointer(int class, uintptr_t value)
{
	uintptr_t pointer;

	if (class < 0 || class >= NUM_TAGGED_POINTER_CLASSES)
		return nil;

	if (value > (UINTPTR_MAX >> TAGGED_POINTER_BITS))
		return nil;

	pointer = (class << 1) | 1;
	pointer |= (value << TAGGED_POINTER_BITS);

	return (id)(pointer ^ objc_tagged_pointer_secret);
}
