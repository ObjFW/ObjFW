/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#define bufferSize 4096

@interface OFLHAArchiveTests: OTTestCase
{
	char _buffer[bufferSize];
}
@end

@implementation OFLHAArchiveTests
- (void)testCreateAndExtractArchive
{
	OFMemoryStream *stream = [OFMemoryStream
	    streamWithMemoryAddress: _buffer
			       size: bufferSize
			   writable: true];
	OFLHAArchive *archive = [OFLHAArchive archiveWithStream: stream
							   mode: @"w"];
	OFLHAArchiveEntry *entry =
	    [OFMutableLHAArchiveEntry entryWithFileName: @"testfile.txt"];
	OFStream *entryStream = [archive streamForWritingEntry: entry];
	size_t size;

	[entryStream writeString: @"Hello World!"];
	[archive close];

	size = (size_t)[stream seekToOffset: 0 whence: OFSeekCurrent];
	OTAssertLessThanOrEqual(size, bufferSize);

	stream = [OFMemoryStream streamWithMemoryAddress: _buffer
						    size: size
						writable: false];
	archive = [OFLHAArchive archiveWithStream: stream mode: @"r"];

	entry = [archive nextEntry];
	OTAssertEqualObjects(entry.fileName, @"testfile.txt");

	entryStream = [archive streamForReadingCurrentEntry];
	OTAssertEqualObjects([entryStream readLine], @"Hello World!");
	OTAssertNil([entryStream readLine]);

	OTAssertNil([archive nextEntry]);
}
@end
