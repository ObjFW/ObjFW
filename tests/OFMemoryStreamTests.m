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
	OTAssertEqual(OFCompareMemory(buffer, "abcde", 5), OFOrderedSame);
	OTAssertEqual([stream lowlevelReadIntoBuffer: buffer length: 3], 3);
	OTAssertEqual(OFCompareMemory(buffer, "fgh", 3), OFOrderedSame);
	OTAssertEqual([stream lowlevelReadIntoBuffer: buffer length: 10], 5);
	OTAssertEqual(OFCompareMemory(buffer, "ijkl", 5), OFOrderedSame);
	OTAssertTrue([stream lowlevelIsAtEndOfStream]);

	OTAssertEqual([stream lowlevelSeekToOffset: 0 whence: OFSeekCurrent],
	    sizeof(string));
	OTAssertTrue([stream lowlevelIsAtEndOfStream]);

	OTAssertEqual([stream lowlevelSeekToOffset: 4 whence: OFSeekSet], 4);
	OTAssertFalse([stream lowlevelIsAtEndOfStream]);
	OTAssertEqual([stream lowlevelReadIntoBuffer: buffer length: 10], 9);
	OTAssertEqual(OFCompareMemory(buffer, "efghijkl", 9), OFOrderedSame);

	OTAssertEqual([stream lowlevelSeekToOffset: -2 whence: OFSeekEnd], 11);
	OTAssertEqual([stream lowlevelReadIntoBuffer: buffer length: 10], 2);
	OTAssertEqual(OFCompareMemory(buffer, "l", 2), OFOrderedSame);
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
	OTAssertEqual(OFCompareMemory(data.items, string, data.count),
	    OFOrderedSame);
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
