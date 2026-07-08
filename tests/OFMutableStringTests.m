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

#include <string.h>

#import "OFMutableStringTests.h"

@interface CustomMutableString: OFMutableString
{
	OFMutableString *_string;
}
@end

static OFString *const whitespace[] = {
	@" \r \t\n\t \tasd  \t \t\t\r\n",
	@" \t\t  \t\t  \t \t"
};

@implementation OFMutableStringTests
- (Class)stringClass
{
	return [CustomMutableString class];
}

- (void)setUp
{
	[super setUp];

	_mutableString = [[self.stringClass alloc] initWithString: @"täṠ€🤔"];
}

- (void)dealloc
{
	objc_release(_mutableString);

	[super dealloc];
}

- (void)testAppendString
{
	[_mutableString appendString: @"ö"];

	OTAssertEqualObjects(_mutableString, @"täṠ€🤔ö");
}

- (void)testAppendUTF8String
{
	[_mutableString appendUTF8String: "ö"];

	OTAssertEqualObjects(_mutableString, @"täṠ€🤔ö");
}

- (void)testAppendUTF8StringLength
{
	[_mutableString appendUTF8String: "öÖ" length: 4];

	OTAssertEqualObjects(_mutableString, @"täṠ€🤔öÖ");
}

- (void)testAppendFormat
{
	[_mutableString appendFormat: @"%02X", 15];

	OTAssertEqualObjects(_mutableString, @"täṠ€🤔0F");
}

- (void)testAppendCharactersLength
{
	[_mutableString appendCharacters: (OFUnichar []){ 0xF6, 0xD6 }
				  length: 2];

	OTAssertEqualObjects(_mutableString, @"täṠ€🤔öÖ");
}

- (void)testUppercase
{
	[_mutableString uppercase];

#ifdef OF_HAVE_UNICODE_TABLES
	OTAssertEqualObjects(_mutableString, @"TÄṠ€🤔");
#else
	OTAssertEqualObjects(_mutableString, @"TäṠ€🤔");
#endif
}

- (void)testLowercase
{
	[_mutableString lowercase];

#ifdef OF_HAVE_UNICODE_TABLES
	OTAssertEqualObjects(_mutableString, @"täṡ€🤔");
#else
	OTAssertEqualObjects(_mutableString, @"täṠ€🤔");
#endif
}

- (void)testCapitalize
{
	OFMutableString *string =
	    [self.stringClass stringWithString: @"täṠ€🤔täṠ€🤔 täṠ€🤔"];

	[string capitalize];

#ifdef OF_HAVE_UNICODE_TABLES
	OTAssertEqualObjects(string, @"Täṡ€🤔täṡ€🤔 Täṡ€🤔");
#else
	OTAssertEqualObjects(string, @"TäṠ€🤔täṠ€🤔 TäṠ€🤔");
#endif
}

- (void)testInsertStringAtIndex
{
	[_mutableString insertString: @"fööbär" atIndex: 2];

	OTAssertEqualObjects(_mutableString, @"täfööbärṠ€🤔");
}

- (void)testSetCharacterAtIndex
{
	[_mutableString setCharacter: 0x1F600 atIndex: 2];

	OTAssertEqualObjects(_mutableString, @"tä😀€🤔");
}

- (void)testDeleteCharactersInRange
{
	[_mutableString deleteCharactersInRange: OFMakeRange(2, 2)];

	OTAssertEqualObjects(_mutableString, @"tä🤔");
}

- (void)testDeleteCharactersInRangeThrowsWithOutOfRangeRange
{
	OTAssertThrowsSpecific(
	    [_mutableString deleteCharactersInRange: OFMakeRange(4, 2)],
	    OFOutOfRangeException);

	OTAssertThrowsSpecific(
	    [_mutableString deleteCharactersInRange: OFMakeRange(5, 1)],
	    OFOutOfRangeException);

	OTAssertThrowsSpecific(
	    [_mutableString deleteCharactersInRange: OFMakeRange(6, 0)],
	    OFOutOfRangeException);
}

- (void)testReplaceCharactersInRangeWithString
{
	OFMutableString *string =
	    [self.stringClass stringWithString: @"𝄞öööbä€"];

	[string replaceCharactersInRange: OFMakeRange(1, 3)
			      withString: @"äöüß"];
	OTAssertEqualObjects(string, @"𝄞äöüßbä€");

	[string replaceCharactersInRange: OFMakeRange(4, 2) withString: @"b"];
	OTAssertEqualObjects(string, @"𝄞äöübä€");

	[string replaceCharactersInRange: OFMakeRange(0, 7) withString: @""];
	OTAssertEqualObjects(string, @"");
}

- (void)testReplaceCharactersInRangeWithStringFailsWithOutOfRangeRange
{
	OTAssertThrowsSpecific(
	    [_mutableString replaceCharactersInRange: OFMakeRange(4, 2)
					  withString: @"abc"],
	    OFOutOfRangeException);

	OTAssertThrowsSpecific(
	    [_mutableString replaceCharactersInRange: OFMakeRange(5, 1)
					  withString: @"abc"],
	    OFOutOfRangeException);

	OTAssertThrowsSpecific(
	    [_mutableString replaceCharactersInRange: OFMakeRange(6, 0)
					  withString: @""],
	    OFOutOfRangeException);
}

- (void)testReplaceOccurrencesOfStringWithString
{
	OFMutableString *string;

	string = [self.stringClass stringWithString: @"asd fo asd fofo asd"];
	[string replaceOccurrencesOfString: @"fo" withString: @"foo"];
	OTAssertEqualObjects(string, @"asd foo asd foofoo asd");

	string = [self.stringClass stringWithString: @"XX"];
	[string replaceOccurrencesOfString: @"X" withString: @"XX"];
	OTAssertEqualObjects(string, @"XXXX");
}

- (void)testReplaceOccurrencesOfStringWithStringOptionsRange
{
	OFMutableString *string =
	    [self.stringClass stringWithString: @"foofoobarfoobarfoo"];

	[string replaceOccurrencesOfString: @"oo"
				withString: @"óò"
				   options: 0
				     range: OFMakeRange(2, 15)];
	OTAssertEqualObjects(string, @"foofóòbarfóòbarfoo");
}

- (void)
  testReplaceOccurrencesOfStringWithStringOptionsRangeThrowsWithOutOfRangeRange
{
	OTAssertThrowsSpecific(
	    [_mutableString replaceOccurrencesOfString: @"t"
					    withString: @"abc"
					       options: 0
						 range: OFMakeRange(4, 2)],
	    OFOutOfRangeException);

	OTAssertThrowsSpecific(
	    [_mutableString replaceOccurrencesOfString: @"t"
					    withString: @"abc"
					       options: 0
						 range: OFMakeRange(5, 1)],
	    OFOutOfRangeException);

	OTAssertThrowsSpecific(
	    [_mutableString replaceOccurrencesOfString: @"t"
					    withString: @""
					       options: 0
						 range: OFMakeRange(6, 0)],
	    OFOutOfRangeException);
}

- (void)testDeleteLeadingWhitespaces
{
	OFMutableString *string;

	string = [self.stringClass stringWithString: whitespace[0]];
	[string deleteLeadingWhitespaces];
	OTAssertEqualObjects(string, @"asd  \t \t\t\r\n");

	string = [self.stringClass stringWithString: whitespace[1]];
	[string deleteLeadingWhitespaces];
	OTAssertEqualObjects(string, @"");
}

- (void)testDeleteTrailingWhitespaces
{
	OFMutableString *string;

	string = [self.stringClass stringWithString: whitespace[0]];
	[string deleteTrailingWhitespaces];
	OTAssertEqualObjects(string,  @" \r \t\n\t \tasd");

	string = [self.stringClass stringWithString: whitespace[1]];
	[string deleteTrailingWhitespaces];
	OTAssertEqualObjects(string, @"");
}

- (void)testDeleteEnclosingWhitespaces
{
	OFMutableString *string;

	string = [self.stringClass stringWithString: whitespace[0]];
	[string deleteEnclosingWhitespaces];
	OTAssertEqualObjects(string, @"asd");

	string = [self.stringClass stringWithString: whitespace[1]];
	[string deleteEnclosingWhitespaces];
	OTAssertEqualObjects(string, @"");
}

- (void)testReplaceControlCharacters
{
	OFMutableString *string;

	string = [self.stringClass stringWithString: @"foo\0bar"];
	[string replaceControlCharacters];
	OTAssertEqualObjects(string, @"foo␀bar");

	string = [self.stringClass stringWithString: @"foo\x1F" @"bar"];
	[string replaceControlCharacters];
	OTAssertEqualObjects(string, @"foo␟bar");

	string = [self.stringClass stringWithString: @"foo\x20" @"bar"];
	[string replaceControlCharacters];
	OTAssertEqualObjects(string, @"foo bar");

	string = [self.stringClass stringWithString: @"foo\x7F" @"bar"];
	[string replaceControlCharacters];
	OTAssertEqualObjects(string, @"foo␡bar");

	string = [self.stringClass stringWithString: @"foo\xC2\x80" @"bar"];
	[string replaceControlCharacters];
	OTAssertEqualObjects(string, @"foo␛@bar");

	string = [self.stringClass stringWithString: @"foo\xC2\x9F" @"bar"];
	[string replaceControlCharacters];
	OTAssertEqualObjects(string, @"foo␛_bar");

	string = [self.stringClass stringWithString: @"foo\xC2\xA0" @"bar"];
	[string replaceControlCharacters];
	OTAssertEqualObjects(string, @"foo\xC2\xA0" @"bar");
}
@end

@implementation CustomMutableString
- (instancetype)init
{
	self = [super init];

	@try {
		_string = [[OFMutableString alloc] init];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)initWithString: (OFString *)string
{
	self = [super init];

	@try {
		_string = [string mutableCopy];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)initWithCString: (const char *)cString
		       encoding: (OFStringEncoding)encoding
			 length: (size_t)length
{
	self = [super init];

	@try {
		_string = [[OFMutableString alloc] initWithCString: cString
							  encoding: encoding
							    length: length];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)initWithUTF16String: (const OFChar16 *)UTF16String
			     length: (size_t)length
			  byteOrder: (OFByteOrder)byteOrder
{
	self = [super init];

	@try {
		_string = [[OFMutableString alloc]
		    initWithUTF16String: UTF16String
				 length: length
			      byteOrder: byteOrder];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)initWithUTF32String: (const OFChar32 *)UTF32String
			     length: (size_t)length
			  byteOrder: (OFByteOrder)byteOrder
{
	self = [super init];

	@try {
		_string = [[OFMutableString alloc]
		    initWithUTF32String: UTF32String
				 length: length
			      byteOrder: byteOrder];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)initWithFormat: (OFConstantString *)format
		     arguments: (va_list)arguments
{
	self = [super init];

	@try {
		_string = [[OFMutableString alloc] initWithFormat: format
							arguments: arguments];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_string);

	[super dealloc];
}

- (OFUnichar)characterAtIndex: (size_t)idx
{
	return [_string characterAtIndex: idx];
}

- (size_t)length
{
	return _string.length;
}

- (void)replaceCharactersInRange: (OFRange)range
		      withString: (OFString *)string
{
	[_string replaceCharactersInRange: range withString: string];
}
@end
