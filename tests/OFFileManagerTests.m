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

@interface OFFileManagerTests: OTTestCase
{
	OFFileManager *_fileManager;
	OFIRI *_testsDirectoryIRI, *_testFileIRI;
}
@end

@implementation OFFileManagerTests
- (void)setUp
{
	_fileManager = [[OFFileManager defaultManager] retain];
	_testsDirectoryIRI = [[[OFSystemInfo temporaryDirectoryIRI]
	    IRIByAppendingPathComponent: @"objfw-tests"] retain];
	_testFileIRI = [[_testsDirectoryIRI
	    IRIByAppendingPathComponent: @"test.txt"] retain];

	/* In case a previous test run failed and left things. */
	if ([_fileManager directoryExistsAtIRI: _testsDirectoryIRI])
		[_fileManager removeItemAtIRI: _testsDirectoryIRI];

	[_fileManager createDirectoryAtIRI: _testsDirectoryIRI];
	[@"test" writeToIRI: _testFileIRI];
}

- (void)tearDown
{
	[_fileManager removeItemAtIRI: _testsDirectoryIRI];
}

- (void)dealloc
{
	[_fileManager release];
	[_testsDirectoryIRI release];
	[_testFileIRI release];

	[super dealloc];
}

- (void)testCurrentDirectoryPath
{
	OTAssertEqualObjects(
	    _fileManager.currentDirectoryPath.lastPathComponent, @"tests");
}

- (void)testAttributesOfItemAtPath
{
	OFFileAttributes attributes;

	attributes = [_fileManager attributesOfItemAtPath:
	    _testsDirectoryIRI.fileSystemRepresentation];
	OTAssertEqual(attributes.fileType, OFFileTypeDirectory);

	attributes = [_fileManager attributesOfItemAtPath:
	    _testFileIRI.fileSystemRepresentation];
	OTAssertEqual(attributes.fileType, OFFileTypeRegular);
	OTAssertEqual(attributes.fileSize, 4);
}

- (void)testSetAttributesOfItemAtPath
{
	OFDate *date = [OFDate dateWithTimeIntervalSince1970: 946681200];
	OFFileAttributes attributes;

	attributes = [OFDictionary
	    dictionaryWithObject: date
			  forKey: OFFileModificationDate];
	[_fileManager setAttributes: attributes
		       ofItemAtPath: _testFileIRI.fileSystemRepresentation];

	attributes = [_fileManager attributesOfItemAtPath:
	    _testFileIRI.fileSystemRepresentation];
	OTAssertEqual(attributes.fileType, OFFileTypeRegular);
	OTAssertEqual(attributes.fileSize, 4);
	OTAssertEqualObjects(attributes.fileModificationDate, date);
}

- (void)testFileExistsAtPath
{
	OTAssertTrue([_fileManager fileExistsAtPath:
	    _testsDirectoryIRI.fileSystemRepresentation]);
	OTAssertTrue([_fileManager fileExistsAtPath:
	    _testFileIRI.fileSystemRepresentation]);
}

- (void)testDirectoryExistsAtPath
{
	OTAssertTrue([_fileManager directoryExistsAtPath:
	    _testsDirectoryIRI.fileSystemRepresentation]);
	OTAssertFalse([_fileManager directoryExistsAtPath:
	    _testFileIRI.fileSystemRepresentation]);
}

- (void)testDirectoryAtPathCreateParents
{
	OFIRI *nestedDirectoryIRI = [_testsDirectoryIRI
	    IRIByAppendingPathComponent: @"0/1/2/3/4/5"];

	[_fileManager
	    createDirectoryAtPath: nestedDirectoryIRI.fileSystemRepresentation
		    createParents: true];
	OTAssertTrue([_fileManager directoryExistsAtPath:
	    nestedDirectoryIRI.fileSystemRepresentation]);
}

- (void)testContentsOfDirectoryAtPath
{
	OFIRI *file1IRI = [_testsDirectoryIRI
	    IRIByAppendingPathComponent: @"1.txt"];
	OFIRI *file2IRI = [_testsDirectoryIRI
	    IRIByAppendingPathComponent: @"2.txt"];

	[@"1" writeToIRI: file1IRI];
	[@"2" writeToIRI: file2IRI];

	OTAssertEqualObjects([_fileManager contentsOfDirectoryAtPath:
	    _testsDirectoryIRI.fileSystemRepresentation].sortedArray,
	    ([OFArray arrayWithObjects: @"1.txt", @"2.txt", @"test.txt", nil]));
}

- (void)testSubpathsOfDirectoryAtPath
{
	OFIRI *subdirectory1IRI = [_testsDirectoryIRI
	    IRIByAppendingPathComponent: @"a"];
	OFIRI *subdirectory2IRI = [_testsDirectoryIRI
	    IRIByAppendingPathComponent: @"b"];
	OFIRI *file1IRI = [subdirectory1IRI
	    IRIByAppendingPathComponent: @"1.txt"];
	OFIRI *file2IRI = [subdirectory2IRI
	    IRIByAppendingPathComponent: @"2.txt"];

	[_fileManager createDirectoryAtIRI: subdirectory1IRI];
	[_fileManager createDirectoryAtIRI: subdirectory2IRI];
	[@"1" writeToIRI: file1IRI];
	[@"2" writeToIRI: file2IRI];

	OTAssertEqualObjects([_fileManager subpathsOfDirectoryAtPath:
	    _testsDirectoryIRI.fileSystemRepresentation].sortedArray,
	    ([OFArray arrayWithObjects:
	    _testsDirectoryIRI.fileSystemRepresentation,
	    subdirectory1IRI.fileSystemRepresentation,
	    file1IRI.fileSystemRepresentation,
	    subdirectory2IRI.fileSystemRepresentation,
	    file2IRI.fileSystemRepresentation,
	    _testFileIRI.fileSystemRepresentation, nil]));
}

- (void)testChangeCurrentDirectoryPath
{
	OFString *oldDirectoryPath = _fileManager.currentDirectoryPath;

	[_fileManager changeCurrentDirectoryPath:
	    _testsDirectoryIRI.fileSystemRepresentation];
	OTAssertEqualObjects(_fileManager.currentDirectoryPath,
	    _testsDirectoryIRI.fileSystemRepresentation);

	[_fileManager changeCurrentDirectoryPath: oldDirectoryPath];
}
@end
