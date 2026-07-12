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

@interface OFTitanRequestTests: OTTestCase
{
	OFTitanRequest *_request;
}
@end

@implementation OFTitanRequestTests
- (void)setUp
{
	OFIRI *IRI;

	[super setUp];

	IRI = [OFIRI IRIWithString:
	    @"titan://foo/bar;size=1234;token=TOKEN%3B;mime=MIME%3b"];
	_request = [[OFTitanRequest alloc] initWithIRI: IRI];
}

- (void)dealloc
{
	objc_release(_request);

	[super dealloc];
}

- (void)testUploadSize
{
	OTAssertEqual(_request.uploadSize, 1234);
}

- (void)testMissingUploadSizeThrows
{
	_request.IRI = [OFIRI IRIWithString: @"titan://foo/bar"];
	OTAssertThrowsSpecific([_request uploadSize],
	    OFInvalidArgumentException);
}

- (void)testSetUploadSize
{
	_request.uploadSize = 2345;
	OTAssertEqualObjects(_request.IRI.string,
	    @"titan://foo/bar;size=2345;token=TOKEN%3B;mime=MIME%3b");

	_request.uploadSize = 0;
	OTAssertEqualObjects(_request.IRI.string,
	    @"titan://foo/bar;size=0;token=TOKEN%3B;mime=MIME%3b");
}

- (void)testUploadMIMEType
{
	OTAssertEqualObjects(_request.uploadMIMEType, @"MIME;");

	_request.IRI = [OFIRI IRIWithString:
	    @"titan://foo/bar;size=1234;token=TOKEN%3B"];
	OTAssertNil(_request.uploadMIMEType);
}

- (void)testSetUploadMIMEType
{
	_request.uploadMIMEType = @"text/gemini; lang=en";
	OTAssertEqualObjects(_request.IRI.string,
	    @"titan://foo/bar;size=1234;token=TOKEN%3B;"
	    @"mime=text/gemini%3B%20lang=en");

	_request.uploadMIMEType = nil;
	OTAssertEqualObjects(_request.IRI.string,
	    @"titan://foo/bar;size=1234;token=TOKEN%3B");
}

- (void)testUploadToken
{
	OTAssertEqualObjects(_request.uploadToken, @"TOKEN;");

	_request.IRI = [OFIRI IRIWithString:
	    @"titan://foo/bar;size=1234;mime=MIME%3b"];
	OTAssertNil(_request.uploadToken);
}

- (void)testSetUploadToken
{
	_request.uploadToken = @"t0;ken";
	OTAssertEqualObjects(_request.IRI.string,
	    @"titan://foo/bar;size=1234;token=t0%3Bken;mime=MIME%3b");

	_request.uploadToken = nil;
	OTAssertEqualObjects(_request.IRI.string,
	    @"titan://foo/bar;size=1234;mime=MIME%3b");
}

- (void)testInvalidSizeThrows
{
	_request.IRI = [OFIRI IRIWithString: @"titan://foo/bar;size=a"];
	OTAssertThrowsSpecific([_request uploadSize], OFInvalidFormatException);

	_request.IRI = [OFIRI IRIWithString:
	    @"titan://foo/bar;size=18446744073709551616"];
	OTAssertThrowsSpecific([_request uploadSize], OFOutOfRangeException);
}

- (void)testNonTitanIRIThrows
{
	OFMutableIRI *IRI = objc_autorelease(_request.IRI.mutableCopy);
	IRI.scheme = @"gemini";
	_request.IRI = IRI;

	OTAssertThrowsSpecific([_request uploadSize],
	    OFInvalidArgumentException);
	OTAssertThrowsSpecific([_request setUploadSize: 0],
	    OFInvalidArgumentException);

	OTAssertThrowsSpecific([_request uploadMIMEType],
	    OFInvalidArgumentException);
	OTAssertThrowsSpecific([_request setUploadMIMEType: @""],
	    OFInvalidArgumentException);

	OTAssertThrowsSpecific([_request uploadToken],
	    OFInvalidArgumentException);
	OTAssertThrowsSpecific([_request setUploadToken: @""],
	    OFInvalidArgumentException);
}
@end
