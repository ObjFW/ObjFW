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

@interface OFTarArchiveTests: OTTestCase
{
	char _buffer[bufferSize];
}
@end

@implementation OFTarArchiveTests
- (void)testCreateAndExtractArchive
{
	OFMemoryStream *stream = [OFMemoryStream
	    streamWithMemoryAddress: _buffer
			       size: bufferSize
			   writable: true];
	OFTarArchive *archive = [OFTarArchive archiveWithStream: stream
							   mode: @"w"];
	OFMutableTarArchiveEntry *entry =
	    [OFMutableTarArchiveEntry entryWithFileName: @"testfile.txt"];
	OFTarArchiveEntry *entry2;
	OFStream *entryStream;
	size_t size;

	entry.uncompressedSize = 12;

	entryStream = [archive streamForWritingEntry: entry];
	[entryStream writeString: @"Hello World!"];

	[archive close];

	size = (size_t)[stream seekToOffset: 0 whence: OFSeekCurrent];
	OTAssertLessThanOrEqual(size, bufferSize);

	stream = [OFMemoryStream streamWithMemoryAddress: _buffer
						    size: size
						writable: false];
	archive = [OFTarArchive archiveWithStream: stream mode: @"r"];

	entry2 = [archive nextEntry];
	OTAssertEqualObjects(entry2.fileName, @"testfile.txt");

	entryStream = [archive streamForReadingCurrentEntry];
	OTAssertEqualObjects([entryStream readLine], @"Hello World!");
	OTAssertNil([entryStream readLine]);

	OTAssertNil([archive nextEntry]);
}
@end
