/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#ifdef STDOUT
#include <stdio.h>
#endif
#include <stdlib.h>

#import "OFString.h"
#import "OFAutoreleasePool.h"

extern void array_tests();
extern void dictionary_tests();
extern void object_tests();
extern void string_tests();

static int fails = 0;

static void
output(OFString *str, int color)
{
#ifdef STDOUT
	switch (color) {
	case 0:
		fputs("\r\033[K\033[1;33m", stdout);
		break;
	case 1:
		fputs("\r\033[K\033[1;32m", stdout);
		break;
	case 2:
		fputs("\r\033[K\033[1;31m", stdout);
		break;
	}

	fputs([str cString], stdout);
	fputs("\033[m", stdout);
	fflush(stdout);
#else
#error No output method!
#endif
}

void
testing(OFString *module, OFString *test)
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFString *str = [OFString stringWithFormat: @"[%s] %s: testing...",
						    [module cString],
						    [test cString]];
	output(str, 0);
	[pool release];
}

void
success(OFString *module, OFString *test)
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFString *str = [OFString stringWithFormat: @"[%s] %s: ok\n",
						    [module cString],
						    [test cString]];
	output(str, 1);
	[pool release];
}

void
failed(OFString *module, OFString *test)
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFString *str = [OFString stringWithFormat: @"[%s] %s: failed\n",
						    [module cString],
						    [test cString]];
	output(str, 2);
	fails++;
	[pool release];
}

int
main()
{
	object_tests();
	string_tests();
	array_tests();
	dictionary_tests();

	return fails;
}
