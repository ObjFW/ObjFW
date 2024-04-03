/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

Method *
class_copyMethodList(Class class, unsigned int *outCount)
{
	unsigned int i, count;
	struct objc_method_list *iter;
	Method *methods;

	if (class == Nil) {
		if (outCount != NULL)
			*outCount = 0;

		return NULL;
	}

	objc_globalMutex_lock();

	count = 0;
	for (iter = class->methodList; iter != NULL; iter = iter->next)
		count += iter->count;

	if (count == 0) {
		if (outCount != NULL)
			*outCount = 0;

		objc_globalMutex_unlock();
		return NULL;
	}

	if ((methods = malloc((count + 1) * sizeof(Method))) == NULL)
		OBJC_ERROR("Not enough memory to copy methods");

	i = 0;
	for (iter = class->methodList; iter != NULL; iter = iter->next)
		for (unsigned int j = 0; j < iter->count; j++)
			methods[i++] = &iter->methods[j];

	if (i != count)
		OBJC_ERROR("Fatal internal inconsistency!");

	methods[count] = NULL;

	if (outCount != NULL)
		*outCount = count;

	objc_globalMutex_unlock();

	return methods;
}

SEL
method_getName(Method method)
{
	return (SEL)&method->selector;
}

const char *
method_getTypeEncoding(Method method)
{
	return method->selector.typeEncoding;
}
