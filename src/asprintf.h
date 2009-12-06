/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "objfw-defs.h"

#ifndef OF_HAVE_ASPRINTF
#include <stdarg.h>

extern int asprintf(char**, const char*, ...);
extern int vasprintf(char**, const char*, va_list);
#endif
