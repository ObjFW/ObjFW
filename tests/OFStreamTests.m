/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#include <string.h>

#import "OFStream.h"
#import "OFString.h"
#import "OFAutoreleasePool.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFStream";

@interface StreamTester: OFStream
{
	int state;
}
@end

@implementation StreamTester
- (BOOL)lowlevelIsAtEndOfStream
{
	return (state > 1 ? YES : NO);
}

- (size_t)lowlevelReadIntoBuffer: (void*)buffer
			  length: (size_t)size
{
	switch (state) {
	case 0:
		if (size < 1)
			return 0;

		memcpy(buffer, "f", 1);

		state++;
		return 1;
	case 1:
		if (size < of_pagesize)
			return 0;

		memcpy(buffer, "oo\n", 3);
		memset((char*)buffer + 3, 'X', of_pagesize - 3);

		state++;
		return of_pagesize;
	}

	return 0;
}
@end

@implementation TestsAppDelegate (OFStreamTests)
- (void)streamTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	StreamTester *t = [[[StreamTester alloc] init] autorelease];
	OFString *str;
	char *cstr;

	cstr = [t allocMemoryWithSize: of_pagesize - 2];
	memset(cstr, 'X', of_pagesize - 3);
	cstr[of_pagesize - 3] = '\0';

	TEST(@"-[readLine]", [[t readLine] isEqual: @"foo"] &&
	    [(str = [t readLine]) length] == of_pagesize - 3 &&
	    !strcmp([str UTF8String], cstr))

	[pool drain];
}
@end
