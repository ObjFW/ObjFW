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

#define NUM_TAGGED_POINTER_CLASSES 0x7F

Class objc_tagged_pointer_classes[NUM_TAGGED_POINTER_CLASSES];
static uint_fast8_t taggedPointerClassesCount;

int_fast8_t
objc_registerTaggedPointerClass(Class class)
{
	uint_fast8_t i;

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

Class
object_getTaggedPointerClass(id object)
{
	uintptr_t pointer = (uintptr_t)object;

	pointer &= 0x7E;
	pointer >>= 1;

	if (pointer >= NUM_TAGGED_POINTER_CLASSES)
		return Nil;

	return objc_tagged_pointer_classes[pointer];
}

uintptr_t
object_getTaggedPointerValue(id object)
{
	uintptr_t pointer = (uintptr_t)object;

	pointer &= ~(uintptr_t)0xFF;
	pointer >>= 8;

	return pointer;
}

id
objc_createTaggedPointer(uint_fast8_t class, uintptr_t value)
{
	uintptr_t pointer;

	if (class >= NUM_TAGGED_POINTER_CLASSES)
		return nil;

	if (value > (UINTPTR_MAX >> 8))
		return nil;

	pointer = (class << 1) | 1;
	pointer |= (value << 8);

	return (id)pointer;
}
