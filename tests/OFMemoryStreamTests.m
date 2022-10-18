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

static OFString *const module = @"OFMemoryStream";
static const char string[] = "abcdefghijkl";

@implementation TestsAppDelegate (OFMemoryStreamTests)
- (void)memoryStreamTests
{
	void *pool = objc_autoreleasePoolPush();
	OFMemoryStream *stream;
	char buffer[10];
	OFMutableData *data;

	TEST(@"+[streamWithMemoryAddress:size:writable:]",
	    (stream = [OFMemoryStream streamWithMemoryAddress: (char *)string
							 size: sizeof(string)
						     writable: false]));

	/*
	 * Test the lowlevel methods, as otherwise OFStream will do one big
	 * read and we will not test OFMemoryStream.
	 */

	TEST(@"-[lowlevelReadIntoBuffer:length:]",
	    [stream lowlevelReadIntoBuffer: buffer length: 5] == 5 &&
	    memcmp(buffer, "abcde", 5) == 0 &&
	    [stream lowlevelReadIntoBuffer: buffer length: 3] == 3 &&
	    memcmp(buffer, "fgh", 3) == 0 &&
	    [stream lowlevelReadIntoBuffer: buffer length: 10] == 5 &&
	    memcmp(buffer, "ijkl", 5) == 0)

	TEST(@"-[lowlevelIsAtEndOfStream]", [stream lowlevelIsAtEndOfStream])

	TEST(@"-[lowlevelSeekToOffset:whence:]",
	    [stream lowlevelSeekToOffset: 0 whence: OFSeekCurrent] ==
	    sizeof(string) && [stream lowlevelIsAtEndOfStream] &&
	    [stream lowlevelSeekToOffset: 4 whence: OFSeekSet] == 4 &&
	    ![stream lowlevelIsAtEndOfStream] &&
	    [stream lowlevelReadIntoBuffer: buffer length: 10] == 9 &&
	    memcmp(buffer, "efghijkl", 9) == 0 &&
	    [stream lowlevelSeekToOffset: -2 whence: OFSeekEnd] == 11 &&
	    [stream lowlevelReadIntoBuffer: buffer length: 10] == 2 &&
	    memcmp(buffer, "l", 2) == 0 &&
	    [stream lowlevelReadIntoBuffer: buffer length: 10] == 0)

	EXPECT_EXCEPTION(@"Writes rejected on read-only stream",
	    OFWriteFailedException, [stream lowlevelWriteBuffer: "" length: 1])

	data = [OFMutableData dataWithCapacity: 13];
	[data increaseCountBy: 13];
	stream = [OFMemoryStream streamWithMemoryAddress: data.mutableItems
						    size: data.count
						writable: true];
	TEST(@"-[lowlevelWriteBuffer:length:]",
	    [stream lowlevelWriteBuffer: "abcde" length: 5] == 5 &&
	    [stream lowlevelWriteBuffer: "fgh" length: 3] == 3 &&
	    [stream lowlevelWriteBuffer: "ijkl" length: 5] == 5 &&
	    memcmp(data.items, string, data.count) == 0 &&
	    [stream lowlevelSeekToOffset: -3 whence: OFSeekEnd] == 10)

	EXPECT_EXCEPTION(@"Out of bound writes rejected",
	    OFWriteFailedException,
	    [stream lowlevelWriteBuffer: "xyz" length: 4])

	TEST(@"Partial write for too long write",
	    memcmp(data.items, "abcdefghijxyz", 13) == 0)

	objc_autoreleasePoolPop(pool);
}
@end
