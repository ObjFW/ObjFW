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

#include "config.h"

#import "TestsAppDelegate.h"

static OFString *const module = @"OFStream";

@interface StreamTest: OFStream
{
	int state;
}
@end

@implementation StreamTest
- (bool)lowlevelIsAtEndOfStream
{
	return (state > 1);
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer length: (size_t)size
{
	size_t pageSize = [OFSystemInfo pageSize];

	switch (state) {
	case 0:
		if (size < 1)
			return 0;

		memcpy(buffer, "f", 1);

		state++;
		return 1;
	case 1:
		if (size < pageSize)
			return 0;

		memcpy(buffer, "oo\n", 3);
		memset((char *)buffer + 3, 'X', pageSize - 3);

		state++;
		return pageSize;
	}

	return 0;
}
@end

@implementation TestsAppDelegate (OFStreamTests)
- (void)streamTests
{
	void *pool = objc_autoreleasePoolPush();
	size_t pageSize = [OFSystemInfo pageSize];
	StreamTest *test = [[[StreamTest alloc] init] autorelease];
	OFString *string;
	char *cString;

	cString = OFAllocMemory(pageSize - 2, 1);
	memset(cString, 'X', pageSize - 3);
	cString[pageSize - 3] = '\0';

	TEST(@"-[readLine] #1", [[test readLine] isEqual: @"foo"])

	string = [test readLine];
	TEST(@"-[readLine] #2", string != nil &&
	    string.length == pageSize - 3 &&
	    !strcmp(string.UTF8String, cString))

	OFFreeMemory(cString);

	objc_autoreleasePoolPop(pool);
}
@end
