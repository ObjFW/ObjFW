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

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

int
vasprintf(char **string, const char *format, va_list arguments)
{
	int length;
	va_list argumentsCopy;

	va_copy(argumentsCopy, arguments);

	if ((length = vsnprintf(NULL, 0, format, argumentsCopy)) < 0)
		return length;
	if ((*string = malloc((size_t)length + 1)) == NULL)
		return -1;

	return vsnprintf(*string, (size_t)length + 1, format, arguments);
}

int
asprintf(char **string, const char *format, ...)
{
	int ret;
	va_list arguments;

	va_start(arguments, format);
	ret = vasprintf(string, format, arguments);
	va_end(arguments);

	return ret;
}
