/*
 * Copyright (c) 2008, 2009, 2010, 2011
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
vasprintf(char **strp, const char *fmt, va_list args)
{
	int size;

	if ((size = vsnprintf(NULL, 0, fmt, args)) < 0)
		return size;
	if ((*strp = malloc((size_t)size + 1)) == NULL)
		return -1;

	return vsnprintf(*strp, (size_t)size + 1, fmt, args);
}

int
asprintf(char **strp, const char *fmt, ...)
{
	int ret;
	va_list args;

	va_start(args, fmt);
	ret = vasprintf(strp, fmt, args);
	va_end(args);

	return ret;
}
