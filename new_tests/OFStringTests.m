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

#include <stdlib.h>
#include <string.h>
#include <math.h>

#import "OFStringTests.h"

#ifndef INFINITY
# define INFINITY __builtin_inf()
#endif

static const OFUnichar unicharString[] = {
	0xFEFF, 'f', 0xF6, 0xF6, 'b', 0xE4, 'r', 0x1F03A, 0
};
static const OFUnichar swappedUnicharString[] = {
	0xFFFE0000, 0x66000000, 0xF6000000, 0xF6000000, 0x62000000, 0xE4000000,
	0x72000000, 0x3AF00100, 0
};
static const OFChar16 char16String[] = {
	0xFEFF, 'f', 0xF6, 0xF6, 'b', 0xE4, 'r', 0xD83C, 0xDC3A, 0
};
static const OFChar16 swappedChar16String[] = {
	0xFFFE, 0x6600, 0xF600, 0xF600, 0x6200, 0xE400, 0x7200, 0x3CD8, 0x3ADC,
	0
};

@interface CustomString: OFString
{
	OFMutableString *_string;
}
@end

@interface CustomMutableString: OFMutableString
{
	OFMutableString *_string;
}
@end

@interface EntityHandler: OFObject <OFStringXMLUnescapingDelegate>
@end

@implementation OFStringTests
- (Class)stringClass
{
	return [CustomString class];
}

- (void)setUp
{
	[super setUp];

	_string = [[self.stringClass alloc] initWithString: @"täṠ€🤔"];
}

- (void)dealloc
{
	[_string release];

	[super dealloc];
}

- (void)testIsEqual
{
	OTAssertEqualObjects(_string, @"täṠ€🤔");
	OTAssertEqualObjects(@"täṠ€🤔", _string);
	OTAssertNotEqualObjects([self.stringClass stringWithString: @"test"],
	    @"täṠ€🤔");
	OTAssertNotEqualObjects(@"täṠ€🤔",
	    [self.stringClass stringWithString: @"test"]);
}

- (void)testHash
{
	OTAssertEqual(_string.hash, @"täṠ€🤔".hash);
	OTAssertNotEqual([[self.stringClass stringWithString: @"test"] hash],
	    @"täṠ€".hash);
}

- (void)testCompare
{
	OTAssertEqual([_string compare: @"täṠ€🤔"], OFOrderedSame);
	OTAssertEqual([[self.stringClass stringWithString: @""]
	    compare: @"a"], OFOrderedAscending);
	OTAssertEqual([[self.stringClass stringWithString: @"a"]
	    compare: @"b"], OFOrderedAscending);
	OTAssertEqual([[self.stringClass stringWithString: @"cd"]
	    compare: @"bc"], OFOrderedDescending);
	OTAssertEqual([[self.stringClass stringWithString: @"ä"]
	    compare: @"ö"], OFOrderedAscending);
	OTAssertEqual([[self.stringClass stringWithString: @"€"]
	    compare: @"ß"], OFOrderedDescending);
	OTAssertEqual([[self.stringClass stringWithString: @"aa"]
	    compare: @"z"], OFOrderedAscending);
	OTAssertEqual([@"aa" compare:
	    [self.stringClass stringWithString: @"z"]], OFOrderedAscending);
}

- (void)testCaseInsensitiveCompare
{
#ifdef OF_HAVE_UNICODE_TABLES
	OTAssertEqual([[self.stringClass stringWithString: @"a"]
	    caseInsensitiveCompare: @"A"], OFOrderedSame);
	OTAssertEqual([[self.stringClass stringWithString: @"Ä"]
	    caseInsensitiveCompare: @"ä"], OFOrderedSame);
	OTAssertEqual([[self.stringClass stringWithString: @"я"]
	    caseInsensitiveCompare: @"Я"], OFOrderedSame);
	OTAssertEqual([[self.stringClass stringWithString: @"€"]
	    caseInsensitiveCompare: @"ß"], OFOrderedDescending);
	OTAssertEqual([[self.stringClass stringWithString: @"ß"]
	    caseInsensitiveCompare: @"→"], OFOrderedAscending);
	OTAssertEqual([[self.stringClass stringWithString: @"AA"]
	    caseInsensitiveCompare: @"z"], OFOrderedAscending);
	OTAssertEqual([[self.stringClass stringWithString: @"ABC"]
	    caseInsensitiveCompare: @"AbD"], OFOrderedAscending);
#else
	OTAssertEqual([[self.stringClass stringWithString: @"a"]
	    caseInsensitiveCompare: @"A"], OFOrderedSame);
	OTAssertEqual([[self.stringClass stringWithString: @"AA"]
	    caseInsensitiveCompare: @"z"], OFOrderedAscending);
	OTAssertEqual([[self.stringClass stringWithString: @"ABC"]
	    caseInsensitiveCompare: @"AbD"], OFOrderedAscending);
#endif
}

- (void)testDescription
{
	OTAssertEqualObjects(_string.description, @"täṠ€🤔");
}

- (void)testLength
{
	OTAssertEqual(_string.length, 5);
}

- (void)testUTF8StringLength
{
	OTAssertEqual(_string.UTF8StringLength, 13);
}

- (void)testCharacterAtIndex
{
	OTAssertEqual([_string characterAtIndex: 0], 't');
	OTAssertEqual([_string characterAtIndex: 1], 0xE4);
	OTAssertEqual([_string characterAtIndex: 2], 0x1E60);
	OTAssertEqual([_string characterAtIndex: 3], 0x20AC);
	OTAssertEqual([_string characterAtIndex: 4], 0x1F914);
}

- (void)testCharacterAtIndexFailsWithOutOfRangeIndex
{
	OTAssertThrowsSpecific([_string characterAtIndex: 5],
	    OFOutOfRangeException);
}

- (void)testUppercaseString
{
#ifdef OF_HAVE_UNICODE_TABLES
	OTAssertEqualObjects(_string.uppercaseString, @"TÄṠ€🤔");
#else
	OTAssertEqualObjects(_string.uppercaseString, @"TäṠ€🤔");
#endif
}

- (void)testLowercaseString
{
#ifdef OF_HAVE_UNICODE_TABLES
	OTAssertEqualObjects(_string.lowercaseString, @"täṡ€🤔");
#else
	OTAssertEqualObjects(_string.lowercaseString, @"täṠ€🤔");
#endif
}

- (void)testCapitalizedString
{
#ifdef OF_HAVE_UNICODE_TABLES
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"täṠ€🤔täṠ€🤔 täṠ€🤔"] capitalizedString], @"Täṡ€🤔täṡ€🤔 Täṡ€🤔");
#else
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"täṠ€🤔täṠ€🤔 täṠ€🤔"] capitalizedString], @"TäṠ€🤔täṠ€🤔 TäṠ€🤔");
#endif
}

- (void)testStringWithUTF8StringLength
{
	OTAssertEqualObjects([self.stringClass
	    stringWithUTF8String: "\xEF\xBB\xBF" "foobar"
			  length: 6], @"foo");
}

- (void)testStringWithUTF16String
{
	OTAssertEqualObjects([self.stringClass
	    stringWithUTF16String: char16String], @"fööbär🀺");
	OTAssertEqualObjects([self.stringClass
	    stringWithUTF16String: swappedChar16String], @"fööbär🀺");
}

- (void)testStringWithUTF32String
{
	OTAssertEqualObjects([self.stringClass
	    stringWithUTF32String: unicharString], @"fööbär🀺");
	OTAssertEqualObjects([self.stringClass
	    stringWithUTF32String: swappedUnicharString], @"fööbär🀺");
}

- (void)testStringWithUTF8StringFailsWithInvalidUTF8
{
	OTAssertThrowsSpecific(
	    [self.stringClass stringWithUTF8String: "\xE0\x80"],
	    OFInvalidEncodingException);

	OTAssertThrowsSpecific(
	    [self.stringClass stringWithUTF8String: "\xF0\x80\x80\xC0"],
	    OFInvalidEncodingException);
}

- (void)testStringWithCStringEncodingISO8859_1
{
	OTAssertEqualObjects([self.stringClass
	    stringWithCString: "\xE4\xF6\xFC"
		     encoding: OFStringEncodingISO8859_1], @"äöü");
}

#ifdef HAVE_ISO_8859_15
- (void)testStringWithCStringEncodingISO8859_15
{
	OTAssertEqualObjects([self.stringClass
	    stringWithCString: "\xA4\xA6\xA8\xB4\xB8\xBC\xBD\xBE"
		     encoding: OFStringEncodingISO8859_15], @"€ŠšŽžŒœŸ");
}
#endif

#ifdef HAVE_WINDOWS_1252
- (void)testStringWithCStringEncodingWindows1252
{
	OTAssertEqualObjects([self.stringClass
	    stringWithCString: "\x80\x82\x83\x84\x85\x86\x87\x88\x89\x8A\x8B"
			       "\x8C\x8E\x91\x92\x93\x94\x95\x96\x97\x98\x99"
			       "\x9A\x9B\x9C\x9E\x9F"
		     encoding: OFStringEncodingWindows1252],
	    @"€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ");
}
#endif

#ifdef HAVE_CODEPAGE_437
- (void)testStringWithCStringEncodingCodepage437
{
	OTAssertEqualObjects([self.stringClass
	    stringWithCString: "\xB0\xB1\xB2\xDB"
		     encoding: OFStringEncodingCodepage437], @"░▒▓█");
}
#endif

#ifdef OF_HAVE_FILES
- (void)testStringWithContentsOfFileEncoding
{
	OTAssertEqualObjects([self.stringClass
	    stringWithContentsOfFile: @"testfile.txt"
			    encoding: OFStringEncodingISO8859_1], @"testäöü");
}

- (void)testStringWithContentsOfIRIEncoding
{
	OTAssertEqualObjects([self.stringClass
	    stringWithContentsOfIRI: [OFIRI fileIRIWithPath: @"testfile.txt"]
			   encoding: OFStringEncodingISO8859_1], @"testäöü");
}
#endif

- (void)testCStringWithEncodingASCII
{
	OTAssertEqual(strcmp([[self.stringClass stringWithString:
	    @"This is a test"] cStringWithEncoding: OFStringEncodingASCII],
	    "This is a test"), 0);

	OTAssertThrowsSpecific([[self.stringClass stringWithString:
	    @"This is a tést"] cStringWithEncoding: OFStringEncodingASCII],
	    OFInvalidEncodingException);
}

- (void)testCStringWithEncodingISO8859_1
{
	OTAssertEqual(strcmp([[self.stringClass stringWithString:
	    @"This is ä test"] cStringWithEncoding: OFStringEncodingISO8859_1],
	    "This is \xE4 test"), 0);

	OTAssertThrowsSpecific([[self.stringClass stringWithString:
	    @"This is ä t€st"] cStringWithEncoding: OFStringEncodingISO8859_1],
	    OFInvalidEncodingException);
}

#ifdef HAVE_ISO_8859_15
- (void)testCStringWithEncodingISO8859_15
{
	OTAssertEqual(strcmp([[self.stringClass stringWithString:
	    @"This is ä t€st"] cStringWithEncoding: OFStringEncodingISO8859_15],
	    "This is \xE4 t\xA4st"), 0);

	OTAssertThrowsSpecific(
	    [[self.stringClass stringWithString: @"This is ä t€st…"]
	    cStringWithEncoding: OFStringEncodingISO8859_15],
	    OFInvalidEncodingException);
}
#endif

#ifdef HAVE_WINDOWS_1252
- (void)testCStringWithEncodingWindows1252
{
	OTAssertEqual(
	    strcmp([[self.stringClass stringWithString: @"This is ä t€st…"]
	    cStringWithEncoding: OFStringEncodingWindows1252],
	    "This is \xE4 t\x80st\x85"), 0);

	OTAssertThrowsSpecific(
	    [[self.stringClass stringWithString: @"This is ä t€st…‼"]
	    cStringWithEncoding: OFStringEncodingWindows1252],
	    OFInvalidEncodingException);
}
#endif

#ifdef HAVE_CODEPAGE_437
- (void)testCStringWithEncodingCodepage437
{
	OTAssertEqual(
	    strcmp([[self.stringClass stringWithString: @"Tést strîng ░▒▓"]
	    cStringWithEncoding: OFStringEncodingCodepage437],
	    "T\x82st str\x8Cng \xB0\xB1\xB2"), 0);

	OTAssertThrowsSpecific(
	    [[self.stringClass stringWithString: @"T€st strîng ░▒▓"]
	    cStringWithEncoding: OFStringEncodingCodepage437],
	    OFInvalidEncodingException);
}
#endif

- (void)testLossyCStringWithEncodingASCII
{
	OTAssertEqual(strcmp([[self.stringClass stringWithString:
	    @"This is a tést"] lossyCStringWithEncoding: OFStringEncodingASCII],
	    "This is a t?st"), 0);
}

- (void)testLossyCStringWithEncodingISO8859_1
{
	OTAssertEqual(
	    strcmp([[self.stringClass stringWithString: @"This is ä t€st"]
	    lossyCStringWithEncoding: OFStringEncodingISO8859_1],
	    "This is \xE4 t?st"), 0);
}

#ifdef HAVE_ISO_8859_15
- (void)testLossyCStringWithEncodingISO8859_15
{
	OTAssertEqual(
	    strcmp([[self.stringClass stringWithString: @"This is ä t€st…"]
	    lossyCStringWithEncoding: OFStringEncodingISO8859_15],
	    "This is \xE4 t\xA4st?"), 0);
}
#endif

#ifdef HAVE_WINDOWS_1252
- (void)testLossyCStringWithEncodingWindows1252
{
	OTAssertEqual(
	    strcmp([[self.stringClass stringWithString: @"This is ä t€st…‼"]
	    lossyCStringWithEncoding: OFStringEncodingWindows1252],
	    "This is \xE4 t\x80st\x85?"), 0);
}
#endif

#ifdef HAVE_CODEPAGE_437
- (void)testLossyCStringWithEncodingCodepage437
{
	OTAssertEqual(
	    strcmp([[self.stringClass stringWithString: @"T€st strîng ░▒▓"]
	    lossyCStringWithEncoding: OFStringEncodingCodepage437],
	    "T?st str\x8Cng \xB0\xB1\xB2"), 0);
}
#endif

- (void)testStringWithFormat
{
	OTAssertEqualObjects(
	    ([self.stringClass stringWithFormat: @"%@:%d", @"test", 123]),
	    @"test:123");
}

- (void)testRangeOfString
{
	OFString *string = [self.stringClass stringWithString: @"𝄞öö"];

	OTAssertEqual([string rangeOfString: @"öö"].location, 1);
	OTAssertEqual([string rangeOfString: @"ö"].location, 1);
	OTAssertEqual([string rangeOfString: @"𝄞"].location, 0);
	OTAssertEqual([string rangeOfString: @"x"].location, OFNotFound);

	OTAssertEqual([string
	    rangeOfString: @"öö"
		  options: OFStringSearchBackwards].location, 1);

	OTAssertEqual([string
	    rangeOfString: @"ö"
		  options: OFStringSearchBackwards].location, 2);

	OTAssertEqual([string
	    rangeOfString: @"𝄞"
		  options: OFStringSearchBackwards].location, 0);

	OTAssertEqual([string
	    rangeOfString: @"x"
		  options: OFStringSearchBackwards].location, OFNotFound);
}

- (void)testRangeOfStringFailsWithOutOfRangeRange
{
	OTAssertThrowsSpecific(
	    [_string rangeOfString: @"t" options: 0 range: OFMakeRange(6, 1)],
	    OFOutOfRangeException);
}

- (void)testIndexOfCharacterFromSet
{
	OFCharacterSet *characterSet =
	    [OFCharacterSet characterSetWithCharactersInString: @"cđ"];

	OTAssertEqual([[self.stringClass stringWithString: @"abcđabcđe"]
	    indexOfCharacterFromSet: characterSet], 2);

	OTAssertEqual([[self.stringClass stringWithString: @"abcđabcđë"]
	    indexOfCharacterFromSet: characterSet
			    options: OFStringSearchBackwards], 7);

	OTAssertEqual([[self.stringClass stringWithString: @"abcđabcđë"]
	    indexOfCharacterFromSet: characterSet
			    options: 0
			      range: OFMakeRange(4, 4)], 6);

	OTAssertEqual([[self.stringClass stringWithString: @"abcđabcđëf"]
	    indexOfCharacterFromSet: characterSet
			    options: 0
			      range: OFMakeRange(8, 2)], OFNotFound);
}

- (void)testIndexOfCharacterFromSetFailsWithOutOfRangeRange
{
	OFCharacterSet *characterSet =
	    [OFCharacterSet characterSetWithCharactersInString: @"cđ"];

	OTAssertThrowsSpecific([[self.stringClass stringWithString: @"𝄞öö"]
	    indexOfCharacterFromSet: characterSet
			    options: 0
			      range: OFMakeRange(3, 1)],
	    OFOutOfRangeException);
}

- (void)testSubstringWithRange
{
	OTAssertEqualObjects([_string substringWithRange: OFMakeRange(1, 2)],
	    @"äṠ");

	OTAssertEqualObjects([_string substringWithRange: OFMakeRange(3, 0)],
	    @"");
}

- (void)testSubstringWithRangeFailsWithOutOfRangeRange
{
	OTAssertThrowsSpecific([_string substringWithRange: OFMakeRange(4, 2)],
	    OFOutOfRangeException);

	OTAssertThrowsSpecific([_string substringWithRange: OFMakeRange(6, 0)],
	    OFOutOfRangeException);
}

- (void)testStringByAppendingString
{
	OTAssertEqualObjects([_string stringByAppendingString: @"äöü"],
	    @"täṠ€🤔äöü");
}

- (void)testHasPrefix
{
	OTAssertTrue([_string hasPrefix: @"täṠ"]);
	OTAssertFalse([_string hasPrefix: @"🤔"]);
}

- (void)testHasSuffix
{
	OTAssertTrue([_string hasSuffix: @"🤔"]);
	OTAssertFalse([_string hasSuffix: @"täṠ"]);
}

- (void)testComponentsSeparatedByString
{
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"fooXXbarXXXXbazXXXX"] componentsSeparatedByString: @"XX"],
	    ([OFArray arrayWithObjects: @"foo", @"bar", @"", @"baz", @"", @"",
	    nil]));

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo"] componentsSeparatedByString: @""],
	    [OFArray arrayWithObject: @"foo"]);
}

- (void)testComponentsSeparatedByStringOptions
{
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"fooXXbarXXXXbazXXXX"]
	    componentsSeparatedByString: @"XX"
				options: OFStringSkipEmptyComponents],
	    ([OFArray arrayWithObjects: @"foo", @"bar", @"baz", nil]));
}

- (void)testComponentsSeparatedByCharactersInSet
{
	OFCharacterSet *characterSet =
	    [OFCharacterSet characterSetWithCharactersInString: @"XYZ"];

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"fooXYbarXYZXbazXYXZx"]
	    componentsSeparatedByCharactersInSet: characterSet],
	    ([OFArray arrayWithObjects: @"foo", @"", @"bar", @"", @"", @"",
	    @"baz", @"", @"", @"", @"x", nil]));
}

- (void)testComponentsSeparatedByCharactersInSetOptions
{
	OFCharacterSet *characterSet =
	    [OFCharacterSet characterSetWithCharactersInString: @"XYZ"];

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"fooXYbarXYZXbazXYXZ"]
	    componentsSeparatedByCharactersInSet: characterSet
					 options: OFStringSkipEmptyComponents],
	    ([OFArray arrayWithObjects: @"foo", @"bar", @"baz", nil]));
}

- (void)testLongLongValue
{
	OTAssertEqual([[self.stringClass stringWithString:
	    @"1234"] longLongValue], 1234);

	OTAssertEqual([[self.stringClass stringWithString:
	    @"\r\n+123  "] longLongValue], 123);

	OTAssertEqual([[self.stringClass stringWithString:
	    @"-500\t"] longLongValue], -500);

	OTAssertEqual([[self.stringClass stringWithString:
	    @"-0x10\t"] longLongValueWithBase: 0], -0x10);

	OTAssertEqual([[self.stringClass stringWithString:
	    @"\t\t\r\n"] longLongValue], 0);

	OTAssertEqual([[self.stringClass stringWithString:
	    @"123f"] longLongValueWithBase: 16], 0x123f);

	OTAssertEqual([[self.stringClass stringWithString:
	    @"-1234"] longLongValueWithBase: 0], -1234);

	OTAssertEqual([[self.stringClass stringWithString:
	    @"\t\n0xABcd\r"] longLongValueWithBase: 0], 0xABCD);

	OTAssertEqual([[self.stringClass stringWithString:
	    @"1234567"] longLongValueWithBase: 8], 01234567);

	OTAssertEqual([[self.stringClass stringWithString:
	    @"\r\n0123"] longLongValueWithBase: 0], 0123);

	OTAssertEqual([[self.stringClass stringWithString:
	    @"765\t"] longLongValueWithBase: 8], 0765);

	OTAssertEqual([[self.stringClass stringWithString:
	    @"\t\t\r\n"] longLongValueWithBase: 8], 0);
}

- (void)testLongLongValueThrowsOnInvalidFormat
{
	OTAssertThrowsSpecific(
	    [[self.stringClass stringWithString: @"abc"] longLongValue],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [[self.stringClass stringWithString: @"0a"] longLongValue],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [[self.stringClass stringWithString: @"0 1"] longLongValue],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [[self.stringClass stringWithString: @"0xABCDEFG"]
	    longLongValueWithBase: 0],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [[self.stringClass stringWithString: @"0x"]
	    longLongValueWithBase: 0],
	    OFInvalidFormatException);
}

- (void)testLongLongValueThrowsOnOutOfRange
{
	OTAssertThrowsSpecific([[self.stringClass stringWithString:
	    @"-12345678901234567890123456789012345678901234567890"
	    @"12345678901234567890123456789012345678901234567890"]
	    longLongValueWithBase: 16], OFOutOfRangeException)
}

- (void)testUnsignedLongLongValue
{
	OTAssertEqual([[self.stringClass stringWithString:
	    @"1234"] unsignedLongLongValue], 1234);

	OTAssertEqual([[self.stringClass stringWithString:
	    @"\r\n+123  "] unsignedLongLongValue], 123);

	OTAssertEqual([[self.stringClass stringWithString:
	    @"\t\t\r\n"] unsignedLongLongValue], 0);

	OTAssertEqual([[self.stringClass stringWithString:
	    @"123f"] unsignedLongLongValueWithBase: 16], 0x123f);

	OTAssertEqual([[self.stringClass stringWithString:
	    @"1234"] unsignedLongLongValueWithBase: 0], 1234);

	OTAssertEqual([[self.stringClass stringWithString:
	    @"\t\n0xABcd\r"] unsignedLongLongValueWithBase: 0], 0xABCD);

	OTAssertEqual([[self.stringClass stringWithString:
	    @"1234567"] unsignedLongLongValueWithBase: 8], 01234567);

	OTAssertEqual([[self.stringClass stringWithString:
	    @"\r\n0123"] unsignedLongLongValueWithBase: 0], 0123);

	OTAssertEqual([[self.stringClass stringWithString: @"765\t"]
	    unsignedLongLongValueWithBase: 8], 0765);

	OTAssertEqual([[self.stringClass stringWithString: @"\t\t\r\n"]
	    unsignedLongLongValueWithBase: 8], 0);
}

- (void)testUnsignedLongLongValueThrowsOnOutOfRange
{
	OTAssertThrowsSpecific([[self.stringClass stringWithString:
	    @"0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF"
	    @"0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF"]
	    unsignedLongLongValueWithBase: 16], OFOutOfRangeException);
}

- (void)testFloatValue
{
	/*
	 * These test numbers can be generated without rounding if we have IEEE
	 * floating point numbers, thus we can use OTAssertEqual on them.
	 */

	OTAssertEqual([[self.stringClass stringWithString:
	    @"\t-0.25 "] floatValue], -0.25);

	OTAssertEqual([[self.stringClass stringWithString:
	    @"\r\n\tINF\t\n"] floatValue], INFINITY);
	OTAssertEqual([[self.stringClass stringWithString:
	    @"\r -INFINITY\n"] floatValue], -INFINITY);

	OTAssertTrue(isnan([[self.stringClass stringWithString:
	    @"   NAN\t\t"] floatValue]));
	OTAssertTrue(isnan([[self.stringClass stringWithString:
	    @"   -NaN\t\t"] floatValue]));
}

- (void)testFloatValueThrowsOnInvalidFormat
{
	OTAssertThrowsSpecific([[self.stringClass stringWithString:
	    @"0.0a"] floatValue], OFInvalidFormatException);
	OTAssertThrowsSpecific([[self.stringClass stringWithString:
	    @"0 0"] floatValue], OFInvalidFormatException);
	OTAssertThrowsSpecific([[self.stringClass stringWithString:
	    @"0,0"] floatValue], OFInvalidFormatException);
}

- (void)testDoubleValue
{
#if (defined(OF_SOLARIS) && defined(OF_X86)) || defined(OF_AMIGAOS_M68K)
	/*
	 * Solaris' strtod() has weird rounding on x86, but not on AMD64.
	 * AmigaOS 3 with libnix has weird rounding as well.
	 */
	OTAssertEqual([[self.stringClass stringWithString:
	    @"\t-0.125 "] doubleValue], -0.125);
#elif defined(OF_ANDROID) || defined(OF_SOLARIS) || defined(OF_HPUX) || \
    defined(OF_DJGPP) || defined(OF_AMIGAOS_M68K)
	/*
	 * Android, Solaris, HP-UX, DJGPP and AmigaOS 3 do not accept 0x for
	 * strtod().
	 */
	OTAssertEqual([[self.stringClass stringWithString:
	    @"\t-0.123456789 "] doubleValue], -0.123456789);
#else
	OTAssertEqual([[self.stringClass stringWithString:
	    @"\t-0x1.FFFFFFFFFFFFFP-1020 "] doubleValue],
	    -0x1.FFFFFFFFFFFFFP-1020);
#endif

	OTAssertEqual([[self.stringClass stringWithString:
	    @"\r\n\tINF\t\n"] doubleValue], INFINITY);
	OTAssertEqual([[self.stringClass stringWithString:
	    @"\r -INFINITY\n"] doubleValue], -INFINITY);

	OTAssert(isnan([[self.stringClass stringWithString:
	    @"   NAN\t\t"] doubleValue]));
	OTAssert(isnan([[self.stringClass stringWithString:
	    @"   -NaN\t\t"] doubleValue]));
}

- (void)testDoubleValueThrowsOnInvalidFormat
{
	OTAssertThrowsSpecific([[self.stringClass stringWithString:
	    @"0.0a"] doubleValue], OFInvalidFormatException);
	OTAssertThrowsSpecific([[self.stringClass stringWithString:
	    @"0 0"] doubleValue], OFInvalidFormatException);
	OTAssertThrowsSpecific([[self.stringClass stringWithString:
	    @"0,0"] doubleValue], OFInvalidFormatException);
}

- (void)testCharacters
{
	OTAssertEqual(memcmp([[self.stringClass stringWithString: @"fööbär🀺"]
	    characters], unicharString + 1, sizeof(unicharString) - 8), 0);
}

- (void)testUTF16String
{
	OFString *string = [self.stringClass stringWithString: @"fööbär🀺"];

	OTAssertEqual(memcmp(string.UTF16String, char16String + 1,
	    OFUTF16StringLength(char16String) * 2), 0);

#ifdef OF_BIG_ENDIAN
	OTAssertEqual(memcmp([string UTF16StringWithByteOrder:
	    OFByteOrderLittleEndian], swappedChar16String + 1,
	    OFUTF16StringLength(swappedChar16String) * 2), 0);
#else
	OTAssertEqual(memcmp([string UTF16StringWithByteOrder:
	    OFByteOrderBigEndian], swappedChar16String + 1,
	    OFUTF16StringLength(swappedChar16String) * 2), 0);
#endif
}

- (void)testUTF16StringLength
{
	OTAssertEqual(_string.UTF16StringLength, 6);
}

- (void)testUTF32String
{
	OFString *string = [self.stringClass stringWithString: @"fööbär🀺"];

	OTAssertEqual(memcmp(string.UTF32String, unicharString + 1,
	    OFUTF32StringLength(unicharString) * 4), 0);

#ifdef OF_BIG_ENDIAN
	OTAssertEqual(memcmp([string UTF32StringWithByteOrder:
	    OFByteOrderLittleEndian], swappedUnicharString + 1,
	    OFUTF32StringLength(swappedUnicharString) * 4), 0);
#else
	OTAssertEqual(memcmp([string UTF32StringWithByteOrder:
	    OFByteOrderBigEndian], swappedUnicharString + 1,
	    OFUTF32StringLength(swappedUnicharString) * 4), 0);
#endif
}

- (void)testStringByMD5Hashing
{
	OTAssertEqualObjects(_string.stringByMD5Hashing,
	    @"7e6bef5fe100d93e808d15b1c6e6145a");
}

- (void)testStringByRIPEMD160Hashing
{
	OTAssertEqualObjects(_string.stringByRIPEMD160Hashing,
	    @"2fd0ec899c55cf2821a2f844b9d80887fc351103");
}

- (void)testStringBySHA1Hashing
{
	OTAssertEqualObjects(_string.stringBySHA1Hashing,
	    @"3f76f9358b372b7147344b7a3ba6d309e4466b3a");
}

- (void)testStringBySHA224Hashing
{
	OTAssertEqualObjects(_string.stringBySHA224Hashing,
	    @"6e57ec72e4da55c46d88a15ce7ce4d8db83d0493a263134a3734259d");
}

- (void)testStringBySHA256Hashing
{
	OTAssertEqualObjects(_string.stringBySHA256Hashing,
	    @"6eac4d3d0b4152c82ff88599482696ca"
	    @"d6dca0b533e8a2e6963d995b19b0a683");
}

- (void)testStringBySHA384Hashing
{
	OTAssertEqualObjects(_string.stringBySHA384Hashing,
	    @"d9bd6a671407d01cee4022888677040d"
	    @"108dd0270c38e0ce755d6dcadb4bf9c1"
	    @"89204dd2a51f954be55ea5d5fe00667b");
}

- (void)testStringBySHA512Hashing
{
	OTAssertEqualObjects(_string.stringBySHA512Hashing,
	    @"64bec66b3633c585da6d32760fa3617a"
	    @"47ca4c247472bdbbfb452b2dbf5a3612"
	    @"5629053394a16ecd08f8a21d461537c5"
	    @"f1224cbb379589e73dcd6763ec4f886c");
}

- (void)testStringByAddingPercentEncodingWithAllowedCharacters
{
	OFCharacterSet *characterSet =
	    [OFCharacterSet characterSetWithCharactersInString: @"abfo'_~$🍏"];

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo\"ba'_~$]🍏🍌"]
	    stringByAddingPercentEncodingWithAllowedCharacters: characterSet],
	    @"foo%22ba'_~$%5D🍏%F0%9F%8D%8C");
}

- (void)testStringByRemovingPercentEncoding
{
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo%20bar%22+%24%F0%9F%8D%8C"] stringByRemovingPercentEncoding],
	    @"foo bar\"+$🍌");
}

- (void)testStringByRemovingPercentEncodingThrowsOnInvalidFormat
{
	OTAssertThrowsSpecific([[self.stringClass stringWithString:
	    @"foo%xbar"] stringByRemovingPercentEncoding],
	    OFInvalidFormatException);
}

- (void)testStringByRemovingPercentEncodingThrowsOnInvalidEncoding
{
	OTAssertThrowsSpecific([[self.stringClass stringWithString:
	    @"foo%FFbar"] stringByRemovingPercentEncoding],
	    OFInvalidEncodingException);
}

- (void)testStringByXMLEscaping
{
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"<hello> &world'\"!&"] stringByXMLEscaping],
	    @"&lt;hello&gt; &amp;world&apos;&quot;!&amp;");
}

- (void)testStringByXMLUnescaping
{
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"&lt;hello&gt; &amp;world&apos;&quot;!&amp;"]
	    stringByXMLUnescaping],
	    @"<hello> &world'\"!&");

	OTAssertEqualObjects([[self.stringClass stringWithString: @"&#x79;"]
	    stringByXMLUnescaping], @"y");
	OTAssertEqualObjects([[self.stringClass stringWithString: @"&#xe4;"]
	    stringByXMLUnescaping], @"ä");
	OTAssertEqualObjects([[self.stringClass stringWithString: @"&#8364;"]
	    stringByXMLUnescaping], @"€");
	OTAssertEqualObjects([[self.stringClass stringWithString: @"&#x1D11E;"]
	    stringByXMLUnescaping], @"𝄞");
}

- (void)testStringByXMLUnescapingThrowsOnUnknownEntities
{
	OTAssertThrowsSpecific([[self.stringClass stringWithString: @"&foo;"]
	    stringByXMLUnescaping], OFUnknownXMLEntityException);
}

- (void)testStringByXMLUnescapingThrowsOnInvalidFormat
{
	OTAssertThrowsSpecific([[self.stringClass stringWithString: @"x&amp"]
	    stringByXMLUnescaping], OFInvalidFormatException);
	OTAssertThrowsSpecific([[self.stringClass stringWithString: @"&#;"]
	    stringByXMLUnescaping], OFInvalidFormatException);
	OTAssertThrowsSpecific([[self.stringClass stringWithString: @"&#x;"]
	    stringByXMLUnescaping], OFInvalidFormatException);
	OTAssertThrowsSpecific([[self.stringClass stringWithString: @"&#g;"]
	    stringByXMLUnescaping], OFInvalidFormatException);
	OTAssertThrowsSpecific([[self.stringClass stringWithString: @"&#xg;"]
	    stringByXMLUnescaping], OFInvalidFormatException);
}

- (void)testStringByXMLUnescapingWithDelegate
{
	EntityHandler *entityHandler =
	    [[[EntityHandler alloc] init] autorelease];

	OTAssertEqualObjects([[self.stringClass stringWithString: @"x&foo;y"]
	    stringByXMLUnescapingWithDelegate: entityHandler],
	    @"xbary");
}

#ifdef OF_HAVE_BLOCKS
- (void)testStringByXMLUnescapingWithBlock
{
	OTAssertEqualObjects([[self.stringClass stringWithString: @"x&foo;y"]
	    stringByXMLUnescapingWithBlock: ^ OFString * (OFString *string,
							  OFString *entity) {
		if ([entity isEqual: @"foo"])
			return @"bar";

		return nil;
	    }], @"xbary");
}

- (void)testEnumerateLinesUsingBlock
{
	__block size_t count = 0;

	[[self.stringClass stringWithString: @"foo\nbar\nbaz"]
	    enumerateLinesUsingBlock: ^ (OFString *line, bool *stop) {
		switch (count++) {
		case 0:
			OTAssertEqualObjects(line, @"foo");
			break;
		case 1:
			OTAssertEqualObjects(line, @"bar");
			break;
		case 2:
			OTAssertEqualObjects(line, @"baz");
			break;
		default:
			OTAssert(false);
		}
	}];

	OTAssertEqual(count, 3);
}
#endif

#ifdef OF_HAVE_FILES
- (void)testIsAbsolutePath
{
# if defined(OF_WINDOWS) || defined(OF_MSDOS)
	OTAssertTrue(
	    [[self.stringClass stringWithString: @"C:\\foo"] isAbsolutePath]);
	OTAssertTrue(
	    [[self.stringClass stringWithString: @"a:/foo"] isAbsolutePath]);
	OTAssertFalse(
	    [[self.stringClass stringWithString: @"foo"] isAbsolutePath]);
	OTAssertFalse(
	    [[self.stringClass stringWithString: @"b:foo"] isAbsolutePath]);
#  ifdef OF_WINDOWS
	OTAssertTrue(
	    [[self.stringClass stringWithString: @"\\\\foo"] isAbsolutePath]);
#  endif
# elif defined(OF_AMIGAOS)
	OTAssertTrue(
	    [[self.stringClass stringWithString: @"dh0:foo"] isAbsolutePath]);
	OTAssertTrue(
	    [[self.stringClass stringWithString: @"dh0:a/b"] isAbsolutePath]);
	OTAssertFalse(
	    [[self.stringClass stringWithString: @"foo/bar"] isAbsolutePath]);
	OTAssertFalse(
	    [[self.stringClass stringWithString: @"foo"] isAbsolutePath]);
# elif defined(OF_NINTENDO_DS) || defined(OF_NINTENDO_3DS) || \
    defined(OF_WII) || defined(OF_NINTENDO_SWITCH)
	OTAssertTrue(
	    [[self.stringClass stringWithString: @"sdmc:/foo"] isAbsolutePath]);
	OTAssertFalse(
	    [[self.stringClass stringWithString: @"sdmc:foo"] isAbsolutePath]);
	OTAssertFalse(
	    [[self.stringClass stringWithString: @"foo/bar"] isAbsolutePath]);
	OTAssertFalse(
	    [[self.stringClass stringWithString: @"foo"] isAbsolutePath]);
# else
	OTAssertTrue(
	    [[self.stringClass stringWithString: @"/foo"] isAbsolutePath]);
	OTAssertTrue(
	    [[self.stringClass stringWithString: @"/foo/bar"] isAbsolutePath]);
	OTAssertFalse(
	    [[self.stringClass stringWithString: @"foo/bar"] isAbsolutePath]);
	OTAssertFalse(
	    [[self.stringClass stringWithString: @"foo"] isAbsolutePath]);
# endif
}

- (void)testStringByAppendingPathComponent
{
# if defined(OF_WINDOWS) || defined(OF_MSDOS)
	OTAssertEqualObjects([[self.stringClass stringWithString: @"foo\\bar"]
	    stringByAppendingPathComponent: @"baz"],
	    @"foo\\bar\\baz");

	OTAssertEqualObjects([[self.stringClass stringWithString: @"foo\\bar\\"]
	    stringByAppendingPathComponent: @"baz"],
	    @"foo\\bar\\baz");
# else
	OTAssertEqualObjects([[self.stringClass stringWithString: @"foo/bar"]
	    stringByAppendingPathComponent: @"baz"],
	    @"foo/bar/baz");

	OTAssertEqualObjects([[self.stringClass stringWithString: @"foo/bar/"]
	    stringByAppendingPathComponent: @"baz"],
	    @"foo/bar/baz");
# endif
}

- (void)testStringByAppendingPathExtension
{
# if defined(OF_WINDOWS) || defined(OF_MSDOS)
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo"] stringByAppendingPathExtension: @"bar"],
	    @"foo.bar");

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"c:\\tmp\\foo"] stringByAppendingPathExtension: @"bar"],
	    @"c:\\tmp\\foo.bar");

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"c:\\tmp\\/\\"] stringByAppendingPathExtension: @"bar"],
	    @"c:\\tmp.bar");
# elif defined(OF_AMIGAOS)
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo"] stringByAppendingPathExtension: @"bar"],
	    @"foo.bar");

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo/bar"] stringByAppendingPathExtension: @"baz"],
	    @"foo/bar.baz");
# else
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo"] stringByAppendingPathExtension: @"bar"],
	    @"foo.bar");

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo/bar"] stringByAppendingPathExtension: @"baz"],
	    @"foo/bar.baz");

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo///"] stringByAppendingPathExtension: @"bar"],
	    @"foo.bar");
# endif
}

- (void)testPathWithComponents
{
# if defined(OF_WINDOWS) || defined(OF_MSDOS)
	OTAssertEqualObjects([self.stringClass pathWithComponents:
	    ([OFArray arrayWithObjects: @"foo", @"bar", @"baz", nil])],
	    @"foo\\bar\\baz");

	OTAssertEqualObjects([self.stringClass pathWithComponents:
	    ([OFArray arrayWithObjects: @"c:\\", @"foo", @"bar", @"baz", nil])],
	    @"c:\\foo\\bar\\baz");

	OTAssertEqualObjects([self.stringClass pathWithComponents:
	    ([OFArray arrayWithObjects: @"c:", @"foo", @"bar", @"baz", nil])],
	    @"c:foo\\bar\\baz");

	OTAssertEqualObjects([self.stringClass pathWithComponents:
	    ([OFArray arrayWithObjects: @"c:", @"\\", @"foo", @"bar", @"baz",
	    nil])], @"c:\\foo\\bar\\baz");

	OTAssertEqualObjects([self.stringClass pathWithComponents:
	    ([OFArray arrayWithObjects: @"c:", @"/", @"foo", @"bar", @"baz",
	    nil])], @"c:/foo\\bar\\baz");

	OTAssertEqualObjects([self.stringClass pathWithComponents:
	    ([OFArray arrayWithObjects: @"foo/", @"bar\\", @"", @"baz", @"\\",
	    nil])], @"foo/bar\\baz");

	OTAssertEqualObjects([self.stringClass pathWithComponents:
	    [OFArray arrayWithObject: @"foo"]], @"foo");

	OTAssertEqualObjects([self.stringClass pathWithComponents:
	    [OFArray arrayWithObject: @"c:"]], @"c:");

	OTAssertEqualObjects([self.stringClass pathWithComponents:
	    [OFArray arrayWithObject: @"c:\\"]], @"c:\\");

	OTAssertEqualObjects([self.stringClass pathWithComponents:
	    [OFArray arrayWithObject: @"\\"]], @"\\");

	OTAssertEqualObjects([self.stringClass pathWithComponents:
	    [OFArray arrayWithObject: @"/"]], @"/");

#  ifdef OF_WINDOWS
	OTAssertEqualObjects([self.stringClass pathWithComponents:
	    ([OFArray arrayWithObjects: @"\\\\", @"foo", @"bar", nil])],
	    @"\\\\foo\\bar");
#  endif
# elif defined(OF_AMIGAOS)
	OTAssertEqualObjects([self.stringClass pathWithComponents:
	    ([OFArray arrayWithObjects: @"dh0:", @"foo", @"bar", @"baz", nil])],
	    @"dh0:foo/bar/baz");

	OTAssertEqualObjects([self.stringClass pathWithComponents:
	    ([OFArray arrayWithObjects: @"foo", @"bar", @"baz", nil])],
	    @"foo/bar/baz");

	OTAssertEqualObjects([self.stringClass pathWithComponents:
	    ([OFArray arrayWithObjects: @"foo/", @"bar", @"", @"baz", @"/",
	    nil])], @"foo//bar/baz//");

	OTAssertEqualObjects([self.stringClass pathWithComponents:
	    [OFArray arrayWithObject: @"foo"]], @"foo");
# elif defined(OF_WII) || defined(OF_NINTENDO_DS) || \
    defined(OF_NINTENDO_3DS) || defined(OF_NINTENDO_SWITCH)
	OTAssertEqualObjects([self.stringClass pathWithComponents:
	    ([OFArray arrayWithObjects: @"foo", @"bar", @"baz", nil])],
	    @"foo/bar/baz");

	OTAssertEqualObjects([self.stringClass pathWithComponents:
	    ([OFArray arrayWithObjects: @"sdmc:", @"foo", @"bar", @"baz",
	    nil])], @"sdmc:/foo/bar/baz");

	OTAssertEqualObjects([self.stringClass pathWithComponents:
	    ([OFArray arrayWithObjects: @"foo/", @"bar/", @"", @"baz", @"/",
	    nil])], @"foo/bar/baz");

	OTAssertEqualObjects([self.stringClass pathWithComponents:
	    [OFArray arrayWithObject: @"foo"]], @"foo");

	OTAssertEqualObjects([self.stringClass pathWithComponents:
	    [OFArray arrayWithObject: @"sdmc:"]], @"sdmc:/");
# else
	OTAssertEqualObjects([self.stringClass pathWithComponents:
	    ([OFArray arrayWithObjects: @"/", @"foo", @"bar", @"baz", nil])],
	    @"/foo/bar/baz");

	OTAssertEqualObjects([self.stringClass pathWithComponents:
	    ([OFArray arrayWithObjects: @"foo", @"bar", @"baz", nil])],
	    @"foo/bar/baz");

	OTAssertEqualObjects([self.stringClass pathWithComponents:
	    ([OFArray arrayWithObjects: @"foo/", @"bar", @"", @"baz", @"/",
	    nil])], @"foo/bar/baz");

	OTAssertEqualObjects([self.stringClass pathWithComponents:
	    [OFArray arrayWithObject: @"foo"]], @"foo");
# endif
}

- (void)testPathComponents
{
# if defined(OF_WINDOWS) || defined(OF_MSDOS)
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"c:/tmp"] pathComponents],
	    ([OFArray arrayWithObjects: @"c:/", @"tmp", nil]));

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"c:\\tmp\\"] pathComponents],
	    ([OFArray arrayWithObjects: @"c:\\", @"tmp", nil]));

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"c:\\"] pathComponents], [OFArray arrayWithObject: @"c:\\"]);

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"c:/"] pathComponents], [OFArray arrayWithObject: @"c:/"]);

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"c:"] pathComponents], [OFArray arrayWithObject: @"c:"]);

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo\\bar"] pathComponents],
	    ([OFArray arrayWithObjects: @"foo", @"bar", nil]));

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo\\bar/baz/"] pathComponents],
	    ([OFArray arrayWithObjects: @"foo", @"bar", @"baz", nil]));

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo\\/"] pathComponents], [OFArray arrayWithObject: @"foo"]);

#  ifdef OF_WINDOWS
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"\\\\foo\\bar"] pathComponents],
	    ([OFArray arrayWithObjects: @"\\\\", @"foo", @"bar", nil]));
#  endif

	OTAssertEqualObjects([[self.stringClass stringWithString: @""]
	    pathComponents], [OFArray array]);
# elif defined(OF_AMIGAOS)
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"dh0:tmp"] pathComponents],
	    ([OFArray arrayWithObjects: @"dh0:", @"tmp", nil]));

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"dh0:tmp/"] pathComponents],
	    ([OFArray arrayWithObjects: @"dh0:", @"tmp", nil]));

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"dh0:/"] pathComponents],
	    ([OFArray arrayWithObjects: @"dh0:", @"/", nil]));

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo/bar"] pathComponents],
	    ([OFArray arrayWithObjects: @"foo", @"bar", nil]));

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo/bar/baz/"] pathComponents],
	    ([OFArray arrayWithObjects: @"foo", @"bar", @"baz", nil]));

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo//"] pathComponents],
	    ([OFArray arrayWithObjects: @"foo", @"/", nil]));

	OTAssertEqualObjects([[self.stringClass stringWithString: @""]
	    pathComponents], [OFArray array]);
# elif defined(OF_NINTENDO_3DS) || defined(OF_WII) || \
    defined(OF_NINTENDO_SWITCH)
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"sdmc:/tmp"] pathComponents],
	    ([OFArray arrayWithObjects: @"sdmc:", @"tmp", nil]));

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"sdmc:/"] pathComponents], [OFArray arrayWithObject: @"sdmc:"]);

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo/bar"] pathComponents],
	    ([OFArray arrayWithObjects: @"foo", @"bar", nil]));

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo/bar/baz/"] pathComponents],
	    ([OFArray arrayWithObjects: @"foo", @"bar", @"baz", nil]));

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo//"] pathComponents], [OFArray arrayWithObject: @"foo"]);

	OTAssertEqualObjects([[self.stringClass stringWithString: @""]
	    pathComponents], [OFArray array]);
# else
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"/tmp"] pathComponents],
	    ([OFArray arrayWithObjects: @"/", @"tmp", nil]));

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"/tmp/"] pathComponents],
	    ([OFArray arrayWithObjects: @"/", @"tmp", nil]));

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"/"] pathComponents], [OFArray arrayWithObject: @"/"]);

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo/bar"] pathComponents],
	    ([OFArray arrayWithObjects: @"foo", @"bar", nil]));

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo/bar/baz/"] pathComponents],
	    ([OFArray arrayWithObjects: @"foo", @"bar", @"baz", nil]));

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo//"] pathComponents], [OFArray arrayWithObject: @"foo"]);

	OTAssertEqualObjects([[self.stringClass stringWithString: @""]
	    pathComponents], [OFArray array]);
# endif
}

- (void)testLastPathComponent
{
# if defined(OF_WINDOWS) || defined(OF_MSDOS)
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"c:/tmp"] lastPathComponent], @"tmp");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"c:\\tmp\\"] lastPathComponent], @"tmp");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"c:\\"] lastPathComponent], @"c:\\");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"c:/"] lastPathComponent], @"c:/");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"\\"] lastPathComponent], @"\\");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo"] lastPathComponent], @"foo");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo\\bar"] lastPathComponent], @"bar");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo/bar/baz/"] lastPathComponent], @"baz");
#  ifdef OF_WINDOWS
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"\\\\foo\\bar"] lastPathComponent], @"bar");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"\\\\"] lastPathComponent], @"\\\\");
#  endif
# elif defined(OF_AMIGAOS)
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"dh0:tmp"] lastPathComponent], @"tmp");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"dh0:tmp/"] lastPathComponent], @"tmp");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"dh0:/"] lastPathComponent], @"/");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"dh0:"] lastPathComponent], @"dh0:");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo"] lastPathComponent], @"foo");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo/bar"] lastPathComponent], @"bar");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo/bar/baz/"] lastPathComponent], @"baz");
# elif defined(OF_WII) || defined(OF_NINTENDO_DS) || \
    defined(OF_NINTENDO_3DS) || defined(OF_NINTENDO_SWITCH)
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"sdmc:/tmp"] lastPathComponent], @"tmp");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"sdmc:/tmp/"] lastPathComponent], @"tmp");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"sdmc:/"] lastPathComponent], @"sdmc:/");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"sdmc:"] lastPathComponent], @"sdmc:");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo"] lastPathComponent], @"foo");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo/bar"] lastPathComponent], @"bar");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo/bar/baz/"] lastPathComponent], @"baz");
# else
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"/tmp"] lastPathComponent], @"tmp");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"/tmp/"] lastPathComponent], @"tmp");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"/"] lastPathComponent], @"/");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo"] lastPathComponent], @"foo");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo/bar"] lastPathComponent], @"bar");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo/bar/baz/"] lastPathComponent], @"baz");
# endif
}

- (void)testPathExtension
{
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo.bar"] pathExtension], @"bar");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo/.bar"] pathExtension], @"");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo/.bar.baz"] pathExtension], @"baz");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo/bar.baz/"] pathExtension], @"baz");
}

- (void)testStringByDeletingLastPathComponent
{
# if defined(OF_WINDOWS) || defined(OF_MSDOS)
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"\\tmp"] stringByDeletingLastPathComponent], @"\\");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"/tmp/"] stringByDeletingLastPathComponent], @"/");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"c:\\"] stringByDeletingLastPathComponent], @"c:\\");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"c:/"] stringByDeletingLastPathComponent], @"c:/");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"c:\\tmp/foo/"] stringByDeletingLastPathComponent], @"c:\\tmp");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo\\bar"] stringByDeletingLastPathComponent], @"foo");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"\\"] stringByDeletingLastPathComponent], @"\\");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo"] stringByDeletingLastPathComponent], @".");
#  ifdef OF_WINDOWS
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"\\\\foo\\bar"] stringByDeletingLastPathComponent], @"\\\\foo");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"\\\\foo"] stringByDeletingLastPathComponent], @"\\\\");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"\\\\"] stringByDeletingLastPathComponent], @"\\\\");
#  endif
# elif defined(OF_AMIGAOS)
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"dh0:"] stringByDeletingLastPathComponent], @"dh0:");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"dh0:tmp"] stringByDeletingLastPathComponent], @"dh0:");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"dh0:tmp/"] stringByDeletingLastPathComponent], @"dh0:");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"dh0:/"] stringByDeletingLastPathComponent], @"dh0:");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"dh0:tmp/foo/"] stringByDeletingLastPathComponent], @"dh0:tmp");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo/bar"] stringByDeletingLastPathComponent], @"foo");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo"] stringByDeletingLastPathComponent], @"");
# elif defined(OF_NINTENDO_3DS) || defined(OF_WII) || \
    defined(OF_NINTENDO_SWITCH)
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"/tmp/"] stringByDeletingLastPathComponent], @"");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"sdmc:/tmp/foo/"] stringByDeletingLastPathComponent],
	    @"sdmc:/tmp");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"sdmc:/"] stringByDeletingLastPathComponent], @"sdmc:/");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo/bar"] stringByDeletingLastPathComponent], @"foo");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"/"] stringByDeletingLastPathComponent], @"");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo"] stringByDeletingLastPathComponent], @".");
# else
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"/tmp"] stringByDeletingLastPathComponent], @"/");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"/tmp/"] stringByDeletingLastPathComponent], @"/");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"/tmp/foo/"] stringByDeletingLastPathComponent], @"/tmp");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo/bar"] stringByDeletingLastPathComponent], @"foo");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"/"] stringByDeletingLastPathComponent], @"/");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo"] stringByDeletingLastPathComponent], @".");
# endif
}

- (void)testStringByDeletingPathExtension
{
# if defined(OF_WINDOWS) || defined(OF_MSDOS)
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo.bar"] stringByDeletingPathExtension], @"foo");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo..bar"] stringByDeletingPathExtension], @"foo.");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"c:/foo.\\bar"] stringByDeletingPathExtension], @"c:/foo.\\bar");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"c:\\foo./bar.baz"] stringByDeletingPathExtension],
	    @"c:\\foo.\\bar");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo.bar/"] stringByDeletingPathExtension], @"foo");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @".foo"] stringByDeletingPathExtension], @".foo");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @".foo.bar"] stringByDeletingPathExtension], @".foo");
# elif defined(OF_AMIGAOS)
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo.bar"] stringByDeletingPathExtension], @"foo");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo..bar"] stringByDeletingPathExtension], @"foo.");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"dh0:foo.bar"] stringByDeletingPathExtension], @"dh0:foo");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"dh0:foo./bar"] stringByDeletingPathExtension], @"dh0:foo./bar");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"dh0:foo./bar.baz"] stringByDeletingPathExtension],
	    @"dh0:foo./bar");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo.bar/"] stringByDeletingPathExtension], @"foo");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @".foo"] stringByDeletingPathExtension], @".foo");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @".foo\\bar"] stringByDeletingPathExtension], @".foo\\bar");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @".foo.bar"] stringByDeletingPathExtension], @".foo");
# elif defined(OF_WII) || defined(OF_NINTENDO_DS) || \
    defined(OF_NINTENDO_3DS) || defined(OF_NINTENDO_SWITCH)
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo.bar"] stringByDeletingPathExtension], @"foo");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo..bar"] stringByDeletingPathExtension], @"foo.");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"sdmc:/foo./bar"] stringByDeletingPathExtension],
	    @"sdmc:/foo./bar");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"sdmc:/foo./bar.baz"] stringByDeletingPathExtension],
	    @"sdmc:/foo./bar");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo.bar/"] stringByDeletingPathExtension], @"foo");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @".foo"] stringByDeletingPathExtension], @".foo");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @".foo.bar"] stringByDeletingPathExtension], @".foo");
# else
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo.bar"] stringByDeletingPathExtension], @"foo");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo..bar"] stringByDeletingPathExtension], @"foo.");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"/foo./bar"] stringByDeletingPathExtension], @"/foo./bar");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"/foo./bar.baz"] stringByDeletingPathExtension], @"/foo./bar");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"foo.bar/"] stringByDeletingPathExtension], @"foo");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @".foo"] stringByDeletingPathExtension], @".foo");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @".foo\\bar"] stringByDeletingPathExtension], @".foo\\bar");
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @".foo.bar"] stringByDeletingPathExtension], @".foo");
# endif
}

# if defined(OF_WINDOWS) || defined(OF_MSDOS)
- (void)testStringByStandardizingPath
{
	/* TODO: Add more tests */

	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"c:\\..\\asd"] stringByStandardizingPath],
	    @"c:\\..\\asd");

#  ifndef OF_MSDOS
	OTAssertEqualObjects([[self.stringClass stringWithString:
	    @"\\\\foo\\..\\bar\\qux"] stringByStandardizingPath],
	    @"\\\\bar\\qux");
#  endif
}
# endif
#endif
@end

@implementation CustomString
- (instancetype)init
{
	self = [super init];

	@try {
		_string = [[OFMutableString alloc] init];
	} @catch (id e) {
		[self release];
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
		[self release];
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
		[self release];
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
		[self release];
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
		[self release];
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
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_string release];

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
@end

@implementation EntityHandler
-	  (OFString *)string: (OFString *)string
  containsUnknownEntityNamed: (OFString *)entity
{
	if ([entity isEqual: @"foo"])
		return @"bar";

	return nil;
}
@end
