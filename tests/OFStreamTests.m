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
	OFTestStream *stream = objc_autorelease([[OFTestStream alloc] init]);
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

		string = [stream readString];
		OTAssertEqualObjects(string, @"aaa");

		string = [stream readString];
		OTAssertEqualObjects(string, @"b");
	} @finally {
		OFFreeMemory(cString);
	}
}
@end

@implementation OFTestStream
- (bool)lowlevelIsAtEndOfStream
{
	return (_state > 7);
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
	case 2:
		if (size < 1)
			return 0;

		memcpy(buffer, "", 1);

		_state++;
		return 1;
	case 3:
	case 4:
	case 5:
		if (size < 1)
			return 0;

		memcpy(buffer, "a", 1);

		_state++;
		return 1;
	case 6:
		if (size < 1)
			return 0;

		memcpy(buffer, "", 1);

		_state++;
		return 1;
	case 7:
		if (size < 1)
			return 0;

		memcpy(buffer, "b", 1);

		_state++;
		return 1;
	}

	return 0;
}
@end
