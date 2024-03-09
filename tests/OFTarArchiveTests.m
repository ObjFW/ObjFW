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

	size = [stream seekToOffset: 0 whence: OFSeekCurrent];
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
