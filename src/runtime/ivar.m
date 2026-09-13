/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

Ivar *
class_copyIvarList(Class class, unsigned int *outCount)
{
	unsigned int count;
	Ivar *ivars;

	if (class == Nil) {
		if (outCount != NULL)
			*outCount = 0;

		return NULL;
	}

	_objc_globalMutex_lock();

	count = (class->ivars != NULL ? class->ivars->count : 0);

	if (count == 0) {
		if (outCount != NULL)
			*outCount = 0;

		_objc_globalMutex_unlock();
		return NULL;
	}

	if ((ivars = malloc((count + 1) * sizeof(Ivar))) == NULL)
		_OBJC_ERROR("Not enough memory to copy ivars!");

	for (unsigned int i = 0; i < count; i++)
		ivars[i] = &class->ivars->ivars[i];
	ivars[count] = NULL;

	if (outCount != NULL)
		*outCount = count;

	_objc_globalMutex_unlock();

	return ivars;
}

const char *
ivar_getName(Ivar ivar)
{
	return ivar->name;
}

const char *
ivar_getTypeEncoding(Ivar ivar)
{
	return ivar->typeEncoding;
}

ptrdiff_t
ivar_getOffset(Ivar ivar)
{
	return ivar->offset;
}
