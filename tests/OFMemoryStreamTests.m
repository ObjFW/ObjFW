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

@interface OFMemoryStreamTests: OTTestCase
@end

static const char string[] = "abcdefghijkl";

@implementation OFMemoryStreamTests
- (void)testReadOnlyMemoryStream
{
	OFMemoryStream *stream = [OFMemoryStream
	    streamWithMemoryAddress: (char *)string
			       size: sizeof(string)
			   writable: false];
	char buffer[10];

	/*
	 * Test the lowlevel methods, as otherwise OFStream will do one big
	 * read and we will not test OFMemoryStream.
	 */

	OTAssertEqual([stream lowlevelReadIntoBuffer: buffer length: 5], 5);
	OTAssertEqual(memcmp(buffer, "abcde", 5), 0);
	OTAssertEqual([stream lowlevelReadIntoBuffer: buffer length: 3], 3);
	OTAssertEqual(memcmp(buffer, "fgh", 3), 0);
	OTAssertEqual([stream lowlevelReadIntoBuffer: buffer length: 10], 5);
	OTAssertEqual(memcmp(buffer, "ijkl", 5), 0);
	OTAssertTrue([stream lowlevelIsAtEndOfStream]);

	OTAssertEqual([stream lowlevelSeekToOffset: 0 whence: OFSeekCurrent],
	    sizeof(string));
	OTAssertTrue([stream lowlevelIsAtEndOfStream]);

	OTAssertEqual([stream lowlevelSeekToOffset: 4 whence: OFSeekSet], 4);
	OTAssertFalse([stream lowlevelIsAtEndOfStream]);
	OTAssertEqual([stream lowlevelReadIntoBuffer: buffer length: 10], 9);
	OTAssertEqual(memcmp(buffer, "efghijkl", 9), 0);

	OTAssertEqual([stream lowlevelSeekToOffset: -2 whence: OFSeekEnd], 11);
	OTAssertEqual([stream lowlevelReadIntoBuffer: buffer length: 10], 2);
	OTAssertEqual(memcmp(buffer, "l", 2), 0);
	OTAssertEqual([stream lowlevelReadIntoBuffer: buffer length: 10], 0);

	OTAssertThrowsSpecific([stream lowlevelWriteBuffer: "" length: 1],
	    OFWriteFailedException);
}

- (void)testReadWriteMemoryStream
{
	OFMutableData *data = [OFMutableData dataWithCapacity: 13];
	OFMemoryStream *stream;

	[data increaseCountBy: 13];
	stream = [OFMemoryStream streamWithMemoryAddress: data.mutableItems
						    size: data.count
						writable: true];

	OTAssertEqual([stream lowlevelWriteBuffer: "abcde" length: 5], 5);
	OTAssertEqual([stream lowlevelWriteBuffer: "fgh" length: 3], 3);
	OTAssertEqual([stream lowlevelWriteBuffer: "ijkl" length: 5], 5);
	OTAssertEqual(memcmp(data.items, string, data.count), 0);
	OTAssertEqual([stream lowlevelSeekToOffset: -3 whence: OFSeekEnd], 10);

	OTAssertThrowsSpecific([stream lowlevelWriteBuffer: "xyz" length: 4],
	    OFWriteFailedException);
}

- (void)testWritingTooMuchThrows
{
	char buffer;
	OFMemoryStream *stream = [OFMemoryStream
	    streamWithMemoryAddress: &buffer
			       size: 1
			   writable: true];

	OTAssertThrowsSpecific([stream writeBuffer: "ab" length: 2],
	    OFWriteFailedException);
}
@end
