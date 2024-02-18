/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "ObjFW.h"
#import "ObjFWTest.h"

@interface OFStreamTests: OTTestCase
@end

@interface OFTestStream: OFStream
{
	int _state;
}
@end

@implementation OFStreamTests
- (void)testStream
{
	size_t pageSize = [OFSystemInfo pageSize];
	OFTestStream *stream = [[[OFTestStream alloc] init] autorelease];
	char *cString = OFAllocMemory(pageSize - 2, 1);

	@try {
		OFString *string;

		memset(cString, 'X', pageSize - 3);
		cString[pageSize - 3] = '\0';

		OTAssertEqualObjects([stream readLine], @"foo");

		string = [stream readLine];
		OTAssertNotNil(string);
		OTAssertEqual(string.length, pageSize - 3);
		OTAssertEqual(strcmp(string.UTF8String, cString), 0);
	} @finally {
		OFFreeMemory(cString);
	}
}
@end

@implementation OFTestStream
- (bool)lowlevelIsAtEndOfStream
{
	return (_state > 1);
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer length: (size_t)size
{
	size_t pageSize = [OFSystemInfo pageSize];

	switch (_state) {
	case 0:
		if (size < 1)
			return 0;

		memcpy(buffer, "f", 1);

		_state++;
		return 1;
	case 1:
		if (size < pageSize)
			return 0;

		memcpy(buffer, "oo\n", 3);
		memset((char *)buffer + 3, 'X', pageSize - 3);

		_state++;
		return pageSize;
	}

	return 0;
}
@end
