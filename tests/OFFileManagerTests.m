/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#include <errno.h>

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

	OTAssertFalse([_fileManager fileExistsAtPath: @"test.txt"]);

	[_fileManager changeCurrentDirectoryPath:
	    _testsDirectoryIRI.fileSystemRepresentation];
	@try {
		/*
		 * We can't check whether currentDirectoryPath is
		 * _testsDirectoryIRI.fileSystemRepresentation because they
		 * could be different due to symlinks. Therefore check for
		 * presence of test.txt instead.
		 */
		OTAssertTrue([_fileManager fileExistsAtPath: @"test.txt"]);
	} @finally {
		[_fileManager changeCurrentDirectoryPath: oldDirectoryPath];
	}
}

- (void)testCopyItemAtPathToPath
{
	OFIRI *sourceIRI = [_testsDirectoryIRI
	    IRIByAppendingPathComponent: @"source"];
	OFIRI *destinationIRI = [_testsDirectoryIRI
	    IRIByAppendingPathComponent: @"destination"];
	OFIRI *subdirectory1IRI = [sourceIRI
	    IRIByAppendingPathComponent: @"a"];
	OFIRI *subdirectory2IRI = [sourceIRI
	    IRIByAppendingPathComponent: @"b"];
	OFIRI *file1IRI = [subdirectory1IRI
	    IRIByAppendingPathComponent: @"1.txt"];
	OFIRI *file2IRI = [subdirectory2IRI
	    IRIByAppendingPathComponent: @"2.txt"];

	[_fileManager createDirectoryAtIRI: subdirectory1IRI
			     createParents: true];
	[_fileManager createDirectoryAtIRI: subdirectory2IRI
			     createParents: true];
	[@"1" writeToIRI: file1IRI];
	[@"2" writeToIRI: file2IRI];

	subdirectory1IRI = [destinationIRI IRIByAppendingPathComponent: @"a"];
	subdirectory2IRI = [destinationIRI IRIByAppendingPathComponent: @"b"];
	file1IRI = [subdirectory1IRI IRIByAppendingPathComponent: @"1.txt"];
	file2IRI = [subdirectory2IRI IRIByAppendingPathComponent: @"2.txt"];

	OTAssertFalse([_fileManager directoryExistsAtIRI: subdirectory1IRI]);
	OTAssertFalse([_fileManager directoryExistsAtIRI: subdirectory2IRI]);
	OTAssertFalse([_fileManager fileExistsAtIRI: file1IRI]);
	OTAssertFalse([_fileManager fileExistsAtIRI: file2IRI]);

	[_fileManager copyItemAtPath: sourceIRI.fileSystemRepresentation
			      toPath: destinationIRI.fileSystemRepresentation];

	OTAssertTrue([_fileManager directoryExistsAtIRI: subdirectory1IRI]);
	OTAssertTrue([_fileManager directoryExistsAtIRI: subdirectory2IRI]);
	OTAssertEqualObjects([OFString stringWithContentsOfIRI: file1IRI],
	    @"1");
	OTAssertEqualObjects([OFString stringWithContentsOfIRI: file2IRI],
	    @"2");
}

- (void)testMoveItemAtPathToPath
{
	OFIRI *sourceIRI = [_testsDirectoryIRI
	    IRIByAppendingPathComponent: @"source"];
	OFIRI *destinationIRI = [_testsDirectoryIRI
	    IRIByAppendingPathComponent: @"destination"];
	OFIRI *subdirectory1IRI = [sourceIRI
	    IRIByAppendingPathComponent: @"a"];
	OFIRI *subdirectory2IRI = [sourceIRI
	    IRIByAppendingPathComponent: @"b"];
	OFIRI *file1IRI = [subdirectory1IRI
	    IRIByAppendingPathComponent: @"1.txt"];
	OFIRI *file2IRI = [subdirectory2IRI
	    IRIByAppendingPathComponent: @"2.txt"];

	[_fileManager createDirectoryAtIRI: subdirectory1IRI
			     createParents: true];
	[_fileManager createDirectoryAtIRI: subdirectory2IRI
			     createParents: true];
	[@"1" writeToIRI: file1IRI];
	[@"2" writeToIRI: file2IRI];

	[_fileManager moveItemAtPath: sourceIRI.fileSystemRepresentation
			      toPath: destinationIRI.fileSystemRepresentation];

	OTAssertFalse([_fileManager directoryExistsAtIRI: subdirectory1IRI]);
	OTAssertFalse([_fileManager directoryExistsAtIRI: subdirectory2IRI]);
	OTAssertFalse([_fileManager fileExistsAtIRI: file1IRI]);
	OTAssertFalse([_fileManager fileExistsAtIRI: file2IRI]);

	subdirectory1IRI = [destinationIRI IRIByAppendingPathComponent: @"a"];
	subdirectory2IRI = [destinationIRI IRIByAppendingPathComponent: @"b"];
	file1IRI = [subdirectory1IRI IRIByAppendingPathComponent: @"1.txt"];
	file2IRI = [subdirectory2IRI IRIByAppendingPathComponent: @"2.txt"];

	OTAssertTrue([_fileManager directoryExistsAtIRI: subdirectory1IRI]);
	OTAssertTrue([_fileManager directoryExistsAtIRI: subdirectory2IRI]);
	OTAssertEqualObjects([OFString stringWithContentsOfIRI: file1IRI],
	    @"1");
	OTAssertEqualObjects([OFString stringWithContentsOfIRI: file2IRI],
	    @"2");
}

- (void)testRemoveItemAtPath
{
	OFIRI *subdirectoryIRI = [_testsDirectoryIRI
	    IRIByAppendingPathComponent: @"dir"];
	OFIRI *fileIRI = [subdirectoryIRI
	    IRIByAppendingPathComponent: @"file.txt"];

	[_fileManager createDirectoryAtIRI: subdirectoryIRI];
	[@"file" writeToIRI: fileIRI];

	OTAssertTrue([_fileManager directoryExistsAtIRI: subdirectoryIRI]);
	OTAssertTrue([_fileManager fileExistsAtIRI: fileIRI]);

	[_fileManager removeItemAtPath:
	    subdirectoryIRI.fileSystemRepresentation];

	OTAssertFalse([_fileManager fileExistsAtIRI: fileIRI]);
	OTAssertFalse([_fileManager directoryExistsAtIRI: subdirectoryIRI]);
}

#ifdef OF_FILE_MANAGER_SUPPORTS_LINKS
- (void)testLinkItemAtPathToPath
{
	OFIRI *sourceIRI = [_testsDirectoryIRI
	    IRIByAppendingPathComponent: @"source"];
	OFIRI *destinationIRI = [_testsDirectoryIRI
	    IRIByAppendingPathComponent: @"destination"];
	OFFileAttributes attributes;

	[@"test" writeToIRI: sourceIRI];

	[_fileManager linkItemAtPath: sourceIRI.fileSystemRepresentation
			      toPath: destinationIRI.fileSystemRepresentation];

	attributes = [_fileManager attributesOfItemAtIRI: destinationIRI];
	OTAssertEqual(attributes.fileType, OFFileTypeRegular);
	OTAssertEqual(attributes.fileSize, 4);
	OTAssertEqualObjects([OFString stringWithContentsOfIRI: destinationIRI],
	    @"test");
}
#endif

#ifdef OF_FILE_MANAGER_SUPPORTS_SYMLINKS
- (void)testCreateSymbolicLinkAtPathWithDestinationPath
{
	OFIRI *sourceIRI, *destinationIRI;
	OFFileAttributes attributes;

# ifdef OF_WINDOWS
	if ([OFSystemInfo wineVersion] != nil)
		OTSkip(@"Wine creates broken symlinks");
# endif

	sourceIRI = [_testsDirectoryIRI IRIByAppendingPathComponent: @"source"];
	destinationIRI = [_testsDirectoryIRI
	    IRIByAppendingPathComponent: @"destination"];

	[@"test" writeToIRI: sourceIRI];

	@try {
		OFString *sourcePath = sourceIRI.fileSystemRepresentation;
		OFString *destinationPath =
		    destinationIRI.fileSystemRepresentation;

		[_fileManager createSymbolicLinkAtPath: destinationPath
				   withDestinationPath: sourcePath];
	} @catch (OFCreateSymbolicLinkFailedException *e) {
		if (e.errNo != EPERM)
			@throw e;

		OTSkip(@"No permission to create symlink.\n"
		    @"On Windows, only the administrator can create symbolic "
		    @"links.");
	}

	attributes = [_fileManager attributesOfItemAtIRI: destinationIRI];
	OTAssertEqual(attributes.fileType, OFFileTypeSymbolicLink);
	OTAssertEqualObjects([OFString stringWithContentsOfIRI: destinationIRI],
	    @"test");
}
#endif

#ifdef OF_FILE_MANAGER_SUPPORTS_EXTENDED_ATTRIBUTES
- (void)testExtendedAttributes
{
	OFData *data = [OFData dataWithItems: "test" count: 4];
	OFString *testFilePath = _testFileIRI.fileSystemRepresentation;
	OFFileAttributes attributes;
	OFArray *extendedAttributeNames;

	@try {
		[_fileManager setExtendedAttributeData: data
					       forName: @"user.test"
					  ofItemAtPath: testFilePath];
	} @catch (OFSetItemAttributesFailedException *e) {
		if (e.errNo != ENOTSUP && e.errNo != EOPNOTSUPP)
			@throw e;

		OTSkip(@"Extended attributes are not supported");
	}

	attributes = [_fileManager attributesOfItemAtIRI: _testFileIRI];
	extendedAttributeNames =
	    [attributes objectForKey: OFFileExtendedAttributesNames];
	OTAssertNotNil(extendedAttributeNames);
	OTAssertTrue([extendedAttributeNames containsObject: @"user.test"]);
	OTAssertEqualObjects(
	    [_fileManager extendedAttributeDataForName: @"user.test"
					  ofItemAtPath: testFilePath],
	    data);

	[_fileManager removeExtendedAttributeForName: @"user.test"
					ofItemAtPath: testFilePath];

	attributes = [_fileManager attributesOfItemAtIRI: _testFileIRI];
	extendedAttributeNames =
	    [attributes objectForKey: OFFileExtendedAttributesNames];
	OTAssertNotNil(extendedAttributeNames);
	OTAssertFalse([extendedAttributeNames containsObject: @"user.test"]);
	OTAssertThrowsSpecific(
	    [_fileManager extendedAttributeDataForName: @"user.test"
					  ofItemAtPath: testFilePath],
	    OFGetItemAttributesFailedException);
}
#endif

#ifdef OF_HAIKU
- (void)testGetExtendedAttributeDataAndTypeForNameOfItemAtPath
{
	OFData *data;
	id type;

	[_fileManager getExtendedAttributeData: &data
				       andType: &type
				       forName: @"BEOS:TYPE"
				  ofItemAtPath: @"/boot/system/lib/libbe.so"];
	OTAssertEqualObjects(type,
	    [OFNumber numberWithUnsignedLong: B_MIME_STRING_TYPE]);
	OTAssertEqualObjects(data,
	    [OFData dataWithItems: "application/x-vnd.Be-elfexecutable"
			    count: 35]);
}

- (void)testSetExtendedAttributeDataAndTypeForNameOfItemAtPath
{
	OFString *testFilePath = _testFileIRI.fileSystemRepresentation;
	OFData *data, *expectedData = [OFData dataWithItems: "foobar" count: 6];
	id type, expectedType = [OFNumber numberWithUnsignedLong: 1234];

	[_fileManager setExtendedAttributeData: expectedData
				       andType: expectedType
				       forName: @"testattribute"
				  ofItemAtPath: testFilePath];

	[_fileManager getExtendedAttributeData: &data
				       andType: &type
				       forName: @"testattribute"
				  ofItemAtPath: testFilePath];

	OTAssertEqualObjects(data, expectedData);
	OTAssertEqualObjects(type, expectedType);

	[_fileManager removeExtendedAttributeForName: @"testattribute"
					ofItemAtPath: testFilePath];

	OTAssertThrowsSpecific(
	    [_fileManager getExtendedAttributeData: &data
					   andType: &type
					   forName: @"testattribute"
				      ofItemAtPath: testFilePath],
	    OFGetItemAttributesFailedException);
}
#endif
@end
