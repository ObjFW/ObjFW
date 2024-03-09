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

#define bufferSize 4096

@interface OFZIPArchiveTests: OTTestCase
{
	char _buffer[bufferSize];
}
@end

@implementation OFZIPArchiveTests
- (void)testCreateAndExtractArchive
{
	OFMemoryStream *stream = [OFMemoryStream
	    streamWithMemoryAddress: _buffer
			       size: bufferSize
			   writable: true];
	OFZIPArchive *archive = [OFZIPArchive archiveWithStream: stream
							   mode: @"w"];
	OFZIPArchiveEntry *entry =
	    [OFMutableZIPArchiveEntry entryWithFileName: @"testfile.txt"];
	OFStream *entryStream = [archive streamForWritingEntry: entry];
	size_t size;

	[entryStream writeString: @"Hello World!"];
	[archive close];

	size = (size_t)[stream seekToOffset: 0 whence: OFSeekCurrent];
	OTAssertLessThanOrEqual(size, bufferSize);

	stream = [OFMemoryStream streamWithMemoryAddress: _buffer
						    size: size
						writable: false];
	archive = [OFZIPArchive archiveWithStream: stream mode: @"r"];

	OTAssertEqual(archive.entries.count, 1);

	entry = archive.entries.firstObject;
	OTAssertEqualObjects(entry.fileName, @"testfile.txt");

	entryStream = [archive streamForReadingFile: entry.fileName];
	OTAssertEqualObjects([entryStream readLine], @"Hello World!");
	OTAssertNil([entryStream readLine]);
}
@end
