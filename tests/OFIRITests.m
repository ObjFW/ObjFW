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

#import "ObjFW.h"
#import "ObjFWTest.h"

@interface OFIRITests: OTTestCase
{
	OFIRI *_IRI[11];
	OFMutableIRI *_mutableIRI;
}
@end

static OFString *IRI0String = @"ht+tp://us%3Aer:p%40w@ho%3Ast:1234/"
    @"pa%3Fth?que%23ry=1&f%26oo=b%3dar#frag%23ment";

@implementation OFIRITests
- (void)setUp
{
	[super setUp];

	_IRI[0] = [[OFIRI alloc] initWithString: IRI0String];
	_IRI[1] = [[OFIRI alloc] initWithString: @"http://foo:80"];
	_IRI[2] = [[OFIRI alloc] initWithString: @"http://bar/"];
	_IRI[3] = [[OFIRI alloc] initWithString: @"file:///etc/passwd"];
	_IRI[4] = [[OFIRI alloc]
	    initWithString: @"http://foo/bar/qux/foo%2fbar"];
	_IRI[5] = [[OFIRI alloc] initWithString: @"https://[12:34::56:abcd]/"];
	_IRI[6] = [[OFIRI alloc]
	    initWithString: @"https://[12:34::56:abcd]:234/"];
	_IRI[7] = [[OFIRI alloc] initWithString: @"urn:qux:foo"];
	_IRI[8] = [[OFIRI alloc] initWithString: @"file:/foo?query#frag"];
	_IRI[9] = [[OFIRI alloc]
	    initWithString: @"file:foo@bar/qux?query#frag"];
	_IRI[10] = [[OFIRI alloc] initWithString: @"http://ä/ö?ü"];

	_mutableIRI = [[OFMutableIRI alloc] initWithScheme: @"dummy"];
}

- (void)dealloc
{
	for (uint_fast8_t i = 0; i < 11; i++)
		[_IRI[i] release];

	[_mutableIRI release];

	[super dealloc];
}

- (void)testIRIWithStringFailsWithInvalidCharacters
{
	OTAssertThrowsSpecific([OFIRI IRIWithString: @"ht,tp://foo"],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific([OFIRI IRIWithString: @"http://f`oo"],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific([OFIRI IRIWithString: @"http://foo/`"],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific([OFIRI IRIWithString: @"http://foo/foo?`"],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific([OFIRI IRIWithString: @"http://foo/foo?foo#`"],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific([OFIRI IRIWithString: @"https://[g]/"],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific([OFIRI IRIWithString: @"https://[f]:/"],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific([OFIRI IRIWithString: @"https://[f]:f/"],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific([OFIRI IRIWithString: @"foo:"],
	    OFInvalidFormatException);
}

- (void)testIRIWithStringRelativeToIRI
{
	OTAssertEqualObjects([[OFIRI IRIWithString: @"/foo"
				     relativeToIRI: _IRI[0]] string],
	    @"ht+tp://us%3Aer:p%40w@ho%3Ast:1234/foo");

	OTAssertEqualObjects(
	    [[OFIRI IRIWithString: @"foo/bar?q"
		    relativeToIRI: [OFIRI IRIWithString: @"http://h/qux/quux"]]
	    string],
	    @"http://h/qux/foo/bar?q");

	OTAssertEqualObjects(
	    [[OFIRI IRIWithString: @"foo/bar"
		    relativeToIRI: [OFIRI IRIWithString: @"http://h/qux/?x"]]
	    string],
	    @"http://h/qux/foo/bar");

	OTAssertEqualObjects([[OFIRI IRIWithString: @"http://foo/?q"
				     relativeToIRI: _IRI[0]] string],
	    @"http://foo/?q");

	OTAssertEqualObjects(
	    [[OFIRI IRIWithString: @"foo"
		    relativeToIRI: [OFIRI IRIWithString: @"http://foo/bar"]]
	    string],
	    @"http://foo/foo");

	OTAssertEqualObjects(
	    [[OFIRI IRIWithString: @"foo"
		    relativeToIRI: [OFIRI IRIWithString: @"http://foo"]]
	    string],
	    @"http://foo/foo");
}

- (void)testIRIWithStringRelativeToIRIFailsWithInvalidCharacters
{
	OTAssertThrowsSpecific(
	    [OFIRI IRIWithString: @"`" relativeToIRI: _IRI[0]],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [OFIRI IRIWithString: @"/`" relativeToIRI: _IRI[0]],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [OFIRI IRIWithString: @"?`" relativeToIRI: _IRI[0]],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [OFIRI IRIWithString: @"#`" relativeToIRI: _IRI[0]],
	    OFInvalidFormatException);
}

#ifdef OF_HAVE_FILES
- (void)testFileIRIWithPath
{
	OTAssertEqualObjects(
	    [[OFIRI fileIRIWithPath: @"testfile.txt"] fileSystemRepresentation],
	    [[OFFileManager defaultManager].currentDirectoryPath
	    stringByAppendingPathComponent: @"testfile.txt"]);
}

# if defined(OF_WINDOWS) || defined(OF_MSDOS)
- (void)testFileIRWithPathC
{
	OFIRI *IRI = [OFIRI fileIRIWithPath: @"c:\\"];
	OTAssertEqualObjects(IRI.string, @"file:/c:/");
	OTAssertEqualObjects(IRI.fileSystemRepresentation, @"c:\\");
}
# endif

# ifdef OF_WINDOWS
- (void)testFileIRIWithPathUNC
{
	OFIRI *IRI;

	IRI = [OFIRI fileIRIWithPath: @"\\\\foo\\bar" isDirectory: false];
	OTAssertEqualObjects(IRI.host, @"foo");
	OTAssertEqualObjects(IRI.path, @"/bar");
	OTAssertEqualObjects(IRI.string, @"file://foo/bar");
	OTAssertEqualObjects(IRI.fileSystemRepresentation, @"\\\\foo\\bar");

	IRI = [OFIRI fileIRIWithPath: @"\\\\test" isDirectory: true];
	OTAssertEqualObjects(IRI.host, @"test");
	OTAssertEqualObjects(IRI.path, @"/");
	OTAssertEqualObjects(IRI.string, @"file://test/");
	OTAssertEqualObjects(IRI.fileSystemRepresentation, @"\\\\test");
}
# endif
#endif

- (void)testString
{
	OTAssertEqualObjects(_IRI[0].string, IRI0String);
	OTAssertEqualObjects(_IRI[1].string, @"http://foo:80");
	OTAssertEqualObjects(_IRI[2].string, @"http://bar/");
	OTAssertEqualObjects(_IRI[3].string, @"file:///etc/passwd");
	OTAssertEqualObjects(_IRI[4].string, @"http://foo/bar/qux/foo%2fbar");
	OTAssertEqualObjects(_IRI[5].string, @"https://[12:34::56:abcd]/");
	OTAssertEqualObjects(_IRI[6].string, @"https://[12:34::56:abcd]:234/");
	OTAssertEqualObjects(_IRI[7].string, @"urn:qux:foo");
	OTAssertEqualObjects(_IRI[8].string, @"file:/foo?query#frag");
	OTAssertEqualObjects(_IRI[9].string, @"file:foo@bar/qux?query#frag");
	OTAssertEqualObjects(_IRI[10].string, @"http://ä/ö?ü");
}

- (void)testScheme
{
	OTAssertEqualObjects(_IRI[0].scheme, @"ht+tp");
	OTAssertEqualObjects(_IRI[3].scheme, @"file");
	OTAssertEqualObjects(_IRI[8].scheme, @"file");
	OTAssertEqualObjects(_IRI[9].scheme, @"file");
	OTAssertEqualObjects(_IRI[10].scheme, @"http");
}

- (void)testUser
{
	OTAssertEqualObjects(_IRI[0].user, @"us:er");
	OTAssertNil(_IRI[3].user);
	OTAssertNil(_IRI[9].user);
	OTAssertNil(_IRI[10].user);
}

- (void)testPassword
{
	OTAssertEqualObjects(_IRI[0].password, @"p@w");
	OTAssertNil(_IRI[3].password);
	OTAssertNil(_IRI[9].password);
	OTAssertNil(_IRI[10].password);
}

- (void)testHost
{
	OTAssertEqualObjects(_IRI[0].host, @"ho:st");
	OTAssertEqualObjects(_IRI[5].host, @"12:34::56:abcd");
	OTAssertEqualObjects(_IRI[6].host, @"12:34::56:abcd");
	OTAssertNil(_IRI[7].host);
	OTAssertNil(_IRI[8].host);
	OTAssertNil(_IRI[9].host);
	OTAssertEqualObjects(_IRI[10].host, @"ä");
}

- (void)testPort
{
	OTAssertEqual(_IRI[0].port.unsignedShortValue, 1234);
	OTAssertNil(_IRI[3].port);
	OTAssertEqual(_IRI[6].port.unsignedShortValue, 234);
	OTAssertNil(_IRI[7].port);
	OTAssertNil(_IRI[8].port);
	OTAssertNil(_IRI[9].port);
	OTAssertNil(_IRI[10].port);
}

- (void)testPath
{
	OTAssertEqualObjects(_IRI[0].path, @"/pa?th");
	OTAssertEqualObjects(_IRI[3].path, @"/etc/passwd");
	OTAssertEqualObjects(_IRI[7].path, @"qux:foo");
	OTAssertEqualObjects(_IRI[8].path, @"/foo");
	OTAssertEqualObjects(_IRI[9].path, @"foo@bar/qux");
	OTAssertEqualObjects(_IRI[10].path, @"/ö");
}

- (void)testPathComponents
{
	OTAssertEqualObjects(_IRI[0].pathComponents,
	    ([OFArray arrayWithObjects: @"/", @"pa?th", nil]));

	OTAssertEqualObjects(_IRI[3].pathComponents,
	    ([OFArray arrayWithObjects: @"/", @"etc", @"passwd", nil]));

	OTAssertEqualObjects(_IRI[4].pathComponents,
	    ([OFArray arrayWithObjects: @"/", @"bar", @"qux", @"foo/bar",
	    nil]));
}

- (void)testLastPathComponent
{
	OTAssertEqualObjects([[OFIRI IRIWithString: @"http://host/foo//bar/baz"]
	    lastPathComponent],
	    @"baz");

	OTAssertEqualObjects(
	    [[OFIRI IRIWithString: @"http://host/foo//bar/baz/"]
	    lastPathComponent],
	    @"baz");

	OTAssertEqualObjects([[OFIRI IRIWithString: @"http://host/foo/"]
	    lastPathComponent],
	    @"foo");

	OTAssertEqualObjects([[OFIRI IRIWithString: @"http://host/"]
	    lastPathComponent],
	    @"/");

	OTAssertEqualObjects(_IRI[4].lastPathComponent, @"foo/bar");
}

- (void)testPathExtension
{
	OTAssertEqualObjects(
	    [[OFIRI IRIWithString: @"http://host/path.dir/path.file"]
	    pathExtension], @"file");

	OTAssertEqualObjects(
	    [[OFIRI IRIWithString: @"http://host/path/path.dir/"]
	    pathExtension], @"dir");
}

- (void)testQuery
{
	OTAssertEqualObjects(_IRI[0].query, @"que#ry=1&f&oo=b=ar");
	OTAssertNil(_IRI[3].query);
	OTAssertEqualObjects(_IRI[8].query, @"query");
	OTAssertEqualObjects(_IRI[9].query, @"query");
	OTAssertEqualObjects(_IRI[10].query, @"ü");
}

- (void)testQueryItems
{
	OTAssertEqualObjects(_IRI[0].queryItems,
	    ([OFArray arrayWithObjects:
	    [OFPair pairWithFirstObject: @"que#ry" secondObject: @"1"],
	    [OFPair pairWithFirstObject: @"f&oo" secondObject: @"b=ar"], nil]));
}

- (void)testFragment
{
	OTAssertEqualObjects(_IRI[0].fragment, @"frag#ment");
	OTAssertNil(_IRI[3].fragment);
	OTAssertEqualObjects(_IRI[8].fragment, @"frag");
	OTAssertEqualObjects(_IRI[9].fragment, @"frag");
}

- (void)testCopy
{
	OTAssertEqualObjects([[_IRI[0] copy] autorelease], _IRI[0]);
}

- (void)testIsEqual
{
	OTAssertEqualObjects(_IRI[0], [OFIRI IRIWithString: IRI0String]);
	OTAssertNotEqualObjects(_IRI[1], _IRI[2]);
	OTAssertEqualObjects([OFIRI IRIWithString: @"HTTP://bar/"], _IRI[2]);
}

- (void)testHash
{
	OTAssertEqual(_IRI[0].hash, [[OFIRI IRIWithString: IRI0String] hash]);
	OTAssertNotEqual(_IRI[1].hash, _IRI[2].hash);
}

- (void)testIRIWithStringFailsWithInvalidFormat
{
	OTAssertThrowsSpecific([OFIRI IRIWithString: @"http"],
	    OFInvalidFormatException);
}

- (void)testIRIByAppendingPathComponent
{
	OTAssertEqualObjects(
	    [[[OFIRI IRIWithString: @"http://host/path/component"]
	    IRIByAppendingPathComponent: @"foo/bar"] path],
	    @"/path/component/foo/bar");

	OTAssertEqualObjects(
	    [[[OFIRI IRIWithString: @"http://host/path/component/"]
	    IRIByAppendingPathComponent: @"foo/bar"] path],
	    @"/path/component/foo/bar");

	OTAssertEqualObjects(
	    [[[OFIRI IRIWithString: @"http://host/path/component/"]
	    IRIByAppendingPathComponent: @"foo/bar"
			    isDirectory: true] path],
	    @"/path/component/foo/bar/");
}

- (void)testIRIByDeletingLastPathComponent
{
	OTAssertEqualObjects(
	    [[[OFIRI IRIWithString: @"http://host/path/component"]
	    IRIByDeletingLastPathComponent] path], @"/path/");

	OTAssertEqualObjects(
	    [[[OFIRI IRIWithString: @"http://host/path/directory/"]
	    IRIByDeletingLastPathComponent] path], @"/path/");

	OTAssertEqualObjects(
	    [[[OFIRI IRIWithString: @"http://host/path"]
	    IRIByDeletingLastPathComponent] path], @"/");

	OTAssertEqualObjects(
	    [[[OFIRI IRIWithString: @"http://host/"]
	    IRIByDeletingLastPathComponent] path], @"/");

	OTAssertEqualObjects(
	    [[[OFIRI IRIWithString: @"http://host"]
	    IRIByDeletingLastPathComponent] path], @"");
}

- (void)testIRIByAppendingPathExtension
{
	OTAssertEqualObjects(
	    [[[OFIRI IRIWithString: @"http://host/path.dir/path"]
	    IRIByAppendingPathExtension: @"file"] path],
	    @"/path.dir/path.file");

	OTAssertEqualObjects(
	    [[[OFIRI IRIWithString: @"http://host/path/path/"]
	    IRIByAppendingPathExtension: @"dir"] path],
	    @"/path/path.dir/");
}

- (void)testIRIByDeletingPathExtension
{
	OTAssertEqualObjects(
	    [[[OFIRI IRIWithString: @"http://host/path.dir/path.file"]
	    IRIByDeletingPathExtension] path],
	    @"/path.dir/path");

	OTAssertEqualObjects(
	    [[[OFIRI IRIWithString: @"http://host/path/path.dir/"]
	    IRIByDeletingPathExtension] path],
	    @"/path/path/");
}

- (void)testIRIByAddingPercentEncodingForUnicodeCharacters
{
	OTAssertEqualObjects(
	    _IRI[10].IRIByAddingPercentEncodingForUnicodeCharacters,
	    [OFIRI IRIWithString: @"http://%C3%A4/%C3%B6?%C3%BC"]);
}

- (void)testSetPercentEncodedSchemeFailsWithInvalidCharacters
{
	OTAssertThrowsSpecific(_mutableIRI.scheme = @"%20",
	    OFInvalidFormatException);
}

- (void)testSetHost
{
	_mutableIRI.host = @"ho:st";
	OTAssertEqualObjects(_mutableIRI.percentEncodedHost, @"ho%3Ast");

	_mutableIRI.host = @"12:34:ab";
	OTAssertEqualObjects(_mutableIRI.percentEncodedHost, @"[12:34:ab]");

	_mutableIRI.host = @"12:34:aB";
	OTAssertEqualObjects(_mutableIRI.percentEncodedHost, @"[12:34:aB]");

	_mutableIRI.host = @"12:34:g";
	OTAssertEqualObjects(_mutableIRI.percentEncodedHost, @"12%3A34%3Ag");
}

- (void)testSetPercentEncodedHost
{
	_mutableIRI.percentEncodedHost = @"ho%3Ast";
	OTAssertEqualObjects(_mutableIRI.host, @"ho:st");

	_mutableIRI.percentEncodedHost = @"[12:34]";
	OTAssertEqualObjects(_mutableIRI.host, @"12:34");

	_mutableIRI.percentEncodedHost = @"[12::ab]";
	OTAssertEqualObjects(_mutableIRI.host, @"12::ab");
}

- (void)testSetPercentEncodedHostFailsWithInvalidCharacters
{
	OTAssertThrowsSpecific(_mutableIRI.percentEncodedHost = @"/",
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(_mutableIRI.percentEncodedHost = @"[12:34",
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(_mutableIRI.percentEncodedHost = @"[a::g]",
	    OFInvalidFormatException);
}

- (void)testSetUser
{
	_mutableIRI.user = @"us:er";
	OTAssertEqualObjects(_mutableIRI.percentEncodedUser, @"us%3Aer");
}

- (void)testSetPercentEncodedUser
{
	_mutableIRI.percentEncodedUser = @"us%3Aer";
	OTAssertEqualObjects(_mutableIRI.user, @"us:er");
}

- (void)testSetPercentEncodedUserFailsWithInvalidCharacters
{
	OTAssertThrowsSpecific(_mutableIRI.percentEncodedHost = @"/",
	    OFInvalidFormatException);
}

- (void)testSetPassword
{
	_mutableIRI.password = @"pass:word";
	OTAssertEqualObjects(_mutableIRI.percentEncodedPassword,
	    @"pass%3Aword");
}

- (void)testSetPercentEncodedPassword
{
	_mutableIRI.percentEncodedPassword = @"pass%3Aword";
	OTAssertEqualObjects(_mutableIRI.password, @"pass:word");
}

- (void)testSetPercentEncodedPasswordFailsWithInvalidCharacters
{
	OTAssertThrowsSpecific(_mutableIRI.percentEncodedPassword = @"/",
	    OFInvalidFormatException);
}

- (void)testSetPath
{
	_mutableIRI.path = @"pa/th@?";
	OTAssertEqualObjects(_mutableIRI.percentEncodedPath, @"pa/th@%3F");
}

- (void)testSetPercentEncodedPath
{
	_mutableIRI.percentEncodedPath = @"pa/th@%3F";
	OTAssertEqualObjects(_mutableIRI.path, @"pa/th@?");
}

- (void)testSetPercentEncodedPathFailsWithInvalidCharacters
{
	OTAssertThrowsSpecific(_mutableIRI.percentEncodedPath = @"?",
	    OFInvalidFormatException);
}

- (void)testSetQuery
{
	_mutableIRI.query = @"que/ry?#";
	OTAssertEqualObjects(_mutableIRI.percentEncodedQuery, @"que/ry?%23");
}

- (void)testSetPercentEncodedQuery
{
	_mutableIRI.percentEncodedQuery = @"que/ry?%23";
	OTAssertEqualObjects(_mutableIRI.query, @"que/ry?#");
}

- (void)testSetPercentEncodedQueryFailsWithInvalidCharacters
{
	OTAssertThrowsSpecific(_mutableIRI.percentEncodedQuery = @"`",
	    OFInvalidFormatException);
}

- (void)testSetQueryItems
{
	_mutableIRI.queryItems = [OFArray arrayWithObjects:
	    [OFPair pairWithFirstObject: @"foo&bar" secondObject: @"baz=qux"],
	    [OFPair pairWithFirstObject: @"f=oobar" secondObject: @"b&azqux"],
	    nil];
	OTAssertEqualObjects(_mutableIRI.percentEncodedQuery,
	    @"foo%26bar=baz%3Dqux&f%3Doobar=b%26azqux");
}

- (void)testSetFragment
{
	_mutableIRI.fragment = @"frag/ment?#";
	OTAssertEqualObjects(_mutableIRI.percentEncodedFragment,
	    @"frag/ment?%23");
}

- (void)testSetPercentEncodedFragment
{
	_mutableIRI.percentEncodedFragment = @"frag/ment?%23";
	OTAssertEqualObjects(_mutableIRI.fragment, @"frag/ment?#");
}

- (void)testSetPercentEncodedFragmentFailsWithInvalidCharacters
{
	OTAssertThrowsSpecific(_mutableIRI.percentEncodedFragment = @"`",
	    OFInvalidFormatException);
}

-(void)testIRIByAppendingPathComponentIsDirectory
{
	OTAssertEqualObjects([[OFIRI IRIWithString: @"file:///foo/bar"]
	    IRIByAppendingPathComponent: @"qux"
			    isDirectory: false],
	    [OFIRI IRIWithString: @"file:///foo/bar/qux"]);

	OTAssertEqualObjects([[OFIRI IRIWithString: @"file:///foo/bar/"]
	    IRIByAppendingPathComponent: @"qux"
			    isDirectory: false],
	    [OFIRI IRIWithString: @"file:///foo/bar/qux"]);

	OTAssertEqualObjects([[OFIRI IRIWithString: @"file:///foo/bar/"]
	    IRIByAppendingPathComponent: @"qu?x"
			    isDirectory: false],
	    [OFIRI IRIWithString: @"file:///foo/bar/qu%3Fx"]);

	OTAssertEqualObjects([[OFIRI IRIWithString: @"file:///foo/bar/"]
	    IRIByAppendingPathComponent: @"qu?x"
			    isDirectory: true],
	    [OFIRI IRIWithString: @"file:///foo/bar/qu%3Fx/"]);
}

- (void)testIRIByStandardizingPath
{
	OTAssertEqualObjects([[OFIRI IRIWithString: @"http://foo/bar/.."]
	    IRIByStandardizingPath],
	    [OFIRI IRIWithString: @"http://foo/"]);

	OTAssertEqualObjects(
	    [[OFIRI IRIWithString: @"http://foo/bar/%2E%2E/../qux/"]
	    IRIByStandardizingPath],
	    [OFIRI IRIWithString: @"http://foo/bar/qux/"]);

	OTAssertEqualObjects(
	    [[OFIRI IRIWithString: @"http://foo/bar/./././qux/./"]
	    IRIByStandardizingPath],
	    [OFIRI IRIWithString: @"http://foo/bar/qux/"]);

	OTAssertEqualObjects([[OFIRI IRIWithString: @"http://foo/bar/../../qux"]
	    IRIByStandardizingPath],
	    [OFIRI IRIWithString: @"http://foo/../qux"]);
}
@end
