/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

#import "TestsAppDelegate.h"

#import "OFString.h"
#import "OFMutableUTF8String.h"
#import "OFUTF8String.h"

#ifndef INFINITY
# define INFINITY __builtin_inf()
#endif

static OFString *module;
static OFString *const whitespace[] = {
	@" \r \t\n\t \tasd  \t \t\t\r\n",
	@" \t\t  \t\t  \t \t"
};
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

@interface SimpleString: OFString
{
	OFMutableString *_string;
}
@end

@interface SimpleMutableString: OFMutableString
{
	OFMutableString *_string;
}
@end

@implementation SimpleString
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

@implementation SimpleMutableString
+ (void)initialize
{
	if (self == [SimpleMutableString class])
		[self inheritMethodsFromClass: [SimpleString class]];
}

- (void)replaceCharactersInRange: (OFRange)range
		      withString: (OFString *)string
{
	[_string replaceCharactersInRange: range withString: string];
}
@end

@interface EntityHandler: OFObject <OFStringXMLUnescapingDelegate>
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

@implementation TestsAppDelegate (OFStringTests)
- (void)stringTestsWithClass: (Class)stringClass
		mutableClass: (Class)mutableStringClass
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableString *mutableString1, *mutableString2, *mutableString3;
	OFString *string;
	OFArray *array;
	size_t i;
	const OFUnichar *characters;
	const uint16_t *UTF16Characters;
	OFCharacterSet *characterSet;
	EntityHandler *entityHandler;
#ifdef OF_HAVE_BLOCKS
	__block int j;
	__block bool ok;
#endif

#define C(s) ((OFString *)[stringClass stringWithString: s])

	mutableString1 = [mutableStringClass stringWithString: @"täs€"];
	mutableString2 = [mutableStringClass string];
	mutableString3 = [[mutableString1 copy] autorelease];

	TEST(@"-[isEqual:]", [mutableString1 isEqual: mutableString3] &&
	    ![mutableString1 isEqual: [[[OFObject alloc] init] autorelease]])

	TEST(@"-[compare:]",
	    [mutableString1 compare: mutableString3] == OFOrderedSame &&
	    [mutableString1 compare: @""] != OFOrderedSame &&
	    [C(@"") compare: @"a"] == OFOrderedAscending &&
	    [C(@"a") compare: @"b"] == OFOrderedAscending &&
	    [C(@"cd") compare: @"bc"] == OFOrderedDescending &&
	    [C(@"ä") compare: @"ö"] == OFOrderedAscending &&
	    [C(@"€") compare: @"ß"] == OFOrderedDescending &&
	    [C(@"aa") compare: @"z"] == OFOrderedAscending)

#ifdef OF_HAVE_UNICODE_TABLES
	TEST(@"-[caseInsensitiveCompare:]",
	    [C(@"a") caseInsensitiveCompare: @"A"] == OFOrderedSame &&
	    [C(@"Ä") caseInsensitiveCompare: @"ä"] == OFOrderedSame &&
	    [C(@"я") caseInsensitiveCompare: @"Я"] == OFOrderedSame &&
	    [C(@"€") caseInsensitiveCompare: @"ß"] == OFOrderedDescending &&
	    [C(@"ß") caseInsensitiveCompare: @"→"] == OFOrderedAscending &&
	    [C(@"AA") caseInsensitiveCompare: @"z"] == OFOrderedAscending &&
	    [[stringClass stringWithUTF8String: "ABC"] caseInsensitiveCompare:
	    [stringClass stringWithUTF8String: "AbD"]] ==
	    [C(@"abc") compare: @"abd"])
#else
	TEST(@"-[caseInsensitiveCompare:]",
	    [C(@"a") caseInsensitiveCompare: @"A"] == OFOrderedSame &&
	    [C(@"AA") caseInsensitiveCompare: @"z"] == OFOrderedAscending &&
	    [[stringClass stringWithUTF8String: "ABC"] caseInsensitiveCompare:
	    [stringClass stringWithUTF8String: "AbD"]] ==
	    [C(@"abc") compare: @"abd"])
#endif

	TEST(@"-[hash] is the same if -[isEqual:] is true",
	    mutableString1.hash == mutableString3.hash)

	TEST(@"-[description]",
	    [mutableString1.description isEqual: mutableString1])

	TEST(@"-[appendString:] and -[appendUTF8String:]",
	    R([mutableString2 appendUTF8String: "1𝄞"]) &&
	    R([mutableString2 appendString: @"3"]) &&
	    R([mutableString1 appendString: mutableString2]) &&
	    [mutableString1 isEqual: @"täs€1𝄞3"])

	TEST(@"-[appendCharacters:length:]",
	    R([mutableString2 appendCharacters: unicharString + 6 length: 2]) &&
	    [mutableString2 isEqual: @"1𝄞3r🀺"])

	TEST(@"-[length]", mutableString1.length == 7)
	TEST(@"-[UTF8StringLength]", mutableString1.UTF8StringLength == 13)
	TEST(@"-[hash]", mutableString1.hash == 0x705583C0)

	TEST(@"-[characterAtIndex:]",
	    [mutableString1 characterAtIndex: 0] == 't' &&
	    [mutableString1 characterAtIndex: 1] == 0xE4 &&
	    [mutableString1 characterAtIndex: 3] == 0x20AC &&
	    [mutableString1 characterAtIndex: 5] == 0x1D11E)

	EXPECT_EXCEPTION(@"Detect out of range in -[characterAtIndex:]",
	    OFOutOfRangeException, [mutableString1 characterAtIndex: 7])

	mutableString2 = [mutableStringClass stringWithString: @"abc"];

#ifdef OF_HAVE_UNICODE_TABLES
	TEST(@"-[uppercase]", R([mutableString1 uppercase]) &&
	    [mutableString1 isEqual: @"TÄS€1𝄞3"] &&
	    R([mutableString2 uppercase]) && [mutableString2 isEqual: @"ABC"])

	TEST(@"-[lowercase]", R([mutableString1 lowercase]) &&
	    [mutableString1 isEqual: @"täs€1𝄞3"] &&
	    R([mutableString2 lowercase]) && [mutableString2 isEqual: @"abc"])

	TEST(@"-[uppercaseString]",
	    [[mutableString1 uppercaseString] isEqual: @"TÄS€1𝄞3"])

	TEST(@"-[lowercaseString]", R([mutableString1 uppercase]) &&
	    [[mutableString1 lowercaseString] isEqual: @"täs€1𝄞3"])

	TEST(@"-[capitalizedString]", [C(@"ǆbla tǆst TǄST").capitalizedString
	    isEqual: @"ǅbla Tǆst Tǆst"])
#else
	TEST(@"-[uppercase]", R([mutableString1 uppercase]) &&
	    [mutableString1 isEqual: @"3𝄞1€SäT"] &&
	    R([mutableString2 uppercase]) && [mutableString2 isEqual: @"ABC"])

	TEST(@"-[lowercase]", R([mutableString1 lowercase]) &&
	    [mutableString1 isEqual: @"3𝄞1€sät"] &&
	    R([mutableString2 lowercase]) && [mutableString2 isEqual: @"abc"])

	TEST(@"-[uppercaseString]",
	    [mutableString1.uppercaseString isEqual: @"3𝄞1€SäT"])

	TEST(@"-[lowercaseString]",
	    R([mutableString1 uppercase]) &&
	    [mutableString1.lowercaseString isEqual: @"3𝄞1€sät"])

	TEST(@"-[capitalizedString]", [C(@"ǆbla tǆst TǄST").capitalizedString
	    isEqual: @"ǆbla Tǆst TǄst"])
#endif

	TEST(@"+[stringWithUTF8String:length:]",
	    (mutableString1 = [mutableStringClass
	    stringWithUTF8String: "\xEF\xBB\xBF" "foobar"
			  length: 6]) &&
	    [mutableString1 isEqual: @"foo"])

	TEST(@"+[stringWithUTF16String:]",
	    (string = [stringClass stringWithUTF16String: char16String]) &&
	    [string isEqual: @"fööbär🀺"] &&
	    (string = [stringClass stringWithUTF16String:
	    swappedChar16String]) && [string isEqual: @"fööbär🀺"])

	TEST(@"+[stringWithUTF32String:]",
	    (string = [stringClass stringWithUTF32String: unicharString]) &&
	    [string isEqual: @"fööbär🀺"] &&
	    (string = [stringClass stringWithUTF32String:
	    swappedUnicharString]) && [string isEqual: @"fööbär🀺"])

#ifdef OF_HAVE_FILES
	TEST(@"+[stringWithContentsOfFile:encoding]", (string = [stringClass
	    stringWithContentsOfFile: @"testfile.txt"
			    encoding: OFStringEncodingISO8859_1]) &&
	    [string isEqual: @"testäöü"])

	TEST(@"+[stringWithContentsOfIRI:encoding]", (string = [stringClass
	    stringWithContentsOfIRI: [OFIRI fileIRIWithPath: @"testfile.txt"]
			   encoding: OFStringEncodingISO8859_1]) &&
	    [string isEqual: @"testäöü"])
#endif

	TEST(@"-[appendUTFString:length:]",
	    R([mutableString1 appendUTF8String: "\xEF\xBB\xBF" "barqux"
					length: 6]) &&
	    [mutableString1 isEqual: @"foobar"])

	EXPECT_EXCEPTION(@"Detection of invalid UTF-8 encoding #1",
	    OFInvalidEncodingException,
	    [stringClass stringWithUTF8String: "\xE0\x80"])
	EXPECT_EXCEPTION(@"Detection of invalid UTF-8 encoding #2",
	    OFInvalidEncodingException,
	    [stringClass stringWithUTF8String: "\xF0\x80\x80\xC0"])

	TEST(@"Conversion of ISO 8859-1 to Unicode",
	    [[stringClass stringWithCString: "\xE4\xF6\xFC"
				   encoding: OFStringEncodingISO8859_1]
	    isEqual: @"äöü"])

#ifdef HAVE_ISO_8859_15
	TEST(@"Conversion of ISO 8859-15 to Unicode",
	    [[stringClass stringWithCString: "\xA4\xA6\xA8\xB4\xB8\xBC\xBD\xBE"
				   encoding: OFStringEncodingISO8859_15]
	    isEqual: @"€ŠšŽžŒœŸ"])
#endif

#ifdef HAVE_WINDOWS_1252
	TEST(@"Conversion of Windows 1252 to Unicode",
	    [[stringClass stringWithCString: "\x80\x82\x83\x84\x85\x86\x87\x88"
					     "\x89\x8A\x8B\x8C\x8E\x91\x92\x93"
					     "\x94\x95\x96\x97\x98\x99\x9A\x9B"
					     "\x9C\x9E\x9F"
				   encoding: OFStringEncodingWindows1252]
	    isEqual: @"€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ"])
#endif

#ifdef HAVE_CODEPAGE_437
	TEST(@"Conversion of Codepage 437 to Unicode",
	    [[stringClass stringWithCString: "\xB0\xB1\xB2\xDB"
				   encoding: OFStringEncodingCodepage437]
	    isEqual: @"░▒▓█"])
#endif

	TEST(@"Conversion of Unicode to ASCII #1",
	    !strcmp([C(@"This is a test") cStringWithEncoding:
	    OFStringEncodingASCII], "This is a test"))

	EXPECT_EXCEPTION(@"Conversion of Unicode to ASCII #2",
	    OFInvalidEncodingException,
	    [C(@"This is a tést")
	    cStringWithEncoding: OFStringEncodingASCII])

	TEST(@"Conversion of Unicode to ISO-8859-1 #1",
	    !strcmp([C(@"This is ä test") cStringWithEncoding:
	    OFStringEncodingISO8859_1], "This is \xE4 test"))

	EXPECT_EXCEPTION(@"Conversion of Unicode to ISO-8859-1 #2",
	    OFInvalidEncodingException,
	    [C(@"This is ä t€st") cStringWithEncoding:
	    OFStringEncodingISO8859_1])

#ifdef HAVE_ISO_8859_15
	TEST(@"Conversion of Unicode to ISO-8859-15 #1",
	    !strcmp([C(@"This is ä t€st") cStringWithEncoding:
	    OFStringEncodingISO8859_15], "This is \xE4 t\xA4st"))

	EXPECT_EXCEPTION(@"Conversion of Unicode to ISO-8859-15 #2",
	    OFInvalidEncodingException,
	    [C(@"This is ä t€st…") cStringWithEncoding:
	    OFStringEncodingISO8859_15])
#endif

#ifdef HAVE_WINDOWS_1252
	TEST(@"Conversion of Unicode to Windows-1252 #1",
	    !strcmp([C(@"This is ä t€st…") cStringWithEncoding:
	    OFStringEncodingWindows1252], "This is \xE4 t\x80st\x85"))

	EXPECT_EXCEPTION(@"Conversion of Unicode to Windows-1252 #2",
	    OFInvalidEncodingException, [C(@"This is ä t€st…‼")
	    cStringWithEncoding: OFStringEncodingWindows1252])
#endif

#ifdef HAVE_CODEPAGE_437
	TEST(@"Conversion of Unicode to Codepage 437 #1",
	    !strcmp([C(@"Tést strîng ░▒▓") cStringWithEncoding:
	    OFStringEncodingCodepage437], "T\x82st str\x8Cng \xB0\xB1\xB2"))

	EXPECT_EXCEPTION(@"Conversion of Unicode to Codepage 437 #2",
	    OFInvalidEncodingException, [C(@"T€st strîng ░▒▓")
	    cStringWithEncoding: OFStringEncodingCodepage437])
#endif

	TEST(@"Lossy conversion of Unicode to ASCII",
	    !strcmp([C(@"This is a tést") lossyCStringWithEncoding:
	    OFStringEncodingASCII], "This is a t?st"))

	TEST(@"Lossy conversion of Unicode to ISO-8859-1",
	    !strcmp([C(@"This is ä t€st") lossyCStringWithEncoding:
	    OFStringEncodingISO8859_1], "This is \xE4 t?st"))

#ifdef HAVE_ISO_8859_15
	TEST(@"Lossy conversion of Unicode to ISO-8859-15",
	    !strcmp([C(@"This is ä t€st…") lossyCStringWithEncoding:
	    OFStringEncodingISO8859_15], "This is \xE4 t\xA4st?"))
#endif

#ifdef HAVE_WINDOWS_1252
	TEST(@"Lossy conversion of Unicode to Windows-1252",
	    !strcmp([C(@"This is ä t€st…‼") lossyCStringWithEncoding:
	    OFStringEncodingWindows1252], "This is \xE4 t\x80st\x85?"))
#endif

#ifdef HAVE_CODEPAGE_437
	TEST(@"Lossy conversion of Unicode to Codepage 437",
	    !strcmp([C(@"T€st strîng ░▒▓") lossyCStringWithEncoding:
	    OFStringEncodingCodepage437], "T?st str\x8Cng \xB0\xB1\xB2"))
#endif

	TEST(@"+[stringWithFormat:]",
	    [(mutableString1 = [mutableStringClass stringWithFormat: @"%@:%d",
								     @"test",
								     123])
	    isEqual: @"test:123"])

	TEST(@"-[appendFormat:]",
	    R(([mutableString1 appendFormat: @"%02X", 15])) &&
	    [mutableString1 isEqual: @"test:1230F"])

	TEST(@"-[rangeOfString:]",
	    [C(@"𝄞öö") rangeOfString: @"öö"].location == 1 &&
	    [C(@"𝄞öö") rangeOfString: @"ö"].location == 1 &&
	    [C(@"𝄞öö") rangeOfString: @"𝄞"].location == 0 &&
	    [C(@"𝄞öö") rangeOfString: @"x"].location == OFNotFound &&
	    [C(@"𝄞öö") rangeOfString: @"öö"
	    options: OFStringSearchBackwards].location == 1 &&
	    [C(@"𝄞öö") rangeOfString: @"ö"
	    options: OFStringSearchBackwards].location == 2 &&
	    [C(@"𝄞öö") rangeOfString: @"𝄞"
	    options: OFStringSearchBackwards].location == 0 &&
	    [C(@"𝄞öö") rangeOfString: @"x"
	    options: OFStringSearchBackwards].location == OFNotFound)

	EXPECT_EXCEPTION(
	    @"Detect out of range in -[rangeOfString:options:range:]",
	    OFOutOfRangeException,
	    [C(@"𝄞öö") rangeOfString: @"ö" options: 0 range: OFMakeRange(3, 1)])

	characterSet =
	    [OFCharacterSet characterSetWithCharactersInString: @"cđ"];
	TEST(@"-[indexOfCharacterFromSet:]",
	    [C(@"abcđabcđe") indexOfCharacterFromSet: characterSet] == 2 &&
	    [C(@"abcđabcđë")
	    indexOfCharacterFromSet: characterSet
			    options: OFStringSearchBackwards] == 7 &&
	    [C(@"abcđabcđë") indexOfCharacterFromSet: characterSet
					     options: 0
					       range: OFMakeRange(4, 4)] == 6 &&
	    [C(@"abcđabcđëf")
	    indexOfCharacterFromSet: characterSet
			    options: 0
			      range: OFMakeRange(8, 2)] == OFNotFound)

	EXPECT_EXCEPTION(
	    @"Detect out of range in -[indexOfCharacterFromSet:options:range:]",
	    OFOutOfRangeException,
	    [C(@"𝄞öö") indexOfCharacterFromSet: characterSet
				       options: 0
					 range: OFMakeRange(3, 1)])

	TEST(@"-[substringWithRange:]",
	    [[C(@"𝄞öö") substringWithRange: OFMakeRange(1, 1)] isEqual: @"ö"] &&
	    [[C(@"𝄞öö") substringWithRange: OFMakeRange(3, 0)] isEqual: @""])

	EXPECT_EXCEPTION(@"Detect out of range in -[substringWithRange:] #1",
	    OFOutOfRangeException,
	    [C(@"𝄞öö") substringWithRange: OFMakeRange(2, 2)])
	EXPECT_EXCEPTION(@"Detect out of range in -[substringWithRange:] #2",
	    OFOutOfRangeException,
	    [C(@"𝄞öö") substringWithRange: OFMakeRange(4, 0)])

	TEST(@"-[stringByAppendingString:]",
	    [[C(@"foo") stringByAppendingString: @"bar"] isEqual: @"foobar"])

#ifdef OF_HAVE_FILES
# if defined(OF_WINDOWS)
	TEST(@"-[isAbsolutePath]",
	    C(@"C:\\foo").absolutePath && C(@"a:/foo").absolutePath &&
	    !C(@"foo").absolutePath && !C(@"b:foo").absolutePath &&
	    C(@"\\\\foo").absolutePath)
# elif  defined(OF_MSDOS)
	TEST(@"-[isAbsolutePath]",
	    C(@"C:\\foo").absolutePath && C(@"a:/foo").absolutePath &&
	    !C(@"foo").absolutePath && !C(@"b:foo").absolutePath)
# elif defined(OF_AMIGAOS)
	TEST(@"-[isAbsolutePath]",
	    C(@"dh0:foo").absolutePath && C(@"dh0:a/b").absolutePath &&
	    !C(@"foo/bar").absolutePath && !C(@"foo").absolutePath)
# elif defined(OF_NINTENDO_3DS) || defined(OF_WII) || \
    defined(OF_NINTENDO_SWITCH)
	TEST(@"-[isAbsolutePath]",
	    C(@"sdmc:/foo").absolutePath && !C(@"sdmc:foo").absolutePath &&
	    !C(@"foo/bar").absolutePath && !C(@"foo").absolutePath)
# else
	TEST(@"-[isAbsolutePath]",
	    C(@"/foo").absolutePath && C(@"/foo/bar").absolutePath &&
	    !C(@"foo/bar").absolutePath && !C(@"foo").absolutePath)
# endif

	mutableString1 = [mutableStringClass stringWithString: @"foo"];
# if defined(OF_WINDOWS) || defined(OF_MSDOS)
	[mutableString1 appendString: @"\\"];
# else
	[mutableString1 appendString: @"/"];
# endif
	[mutableString1 appendString: @"bar"];
	mutableString2 = [mutableStringClass stringWithString: mutableString1];
# if defined(OF_WINDOWS) || defined(OF_MSDOS)
	[mutableString2 appendString: @"\\"];
# else
	[mutableString2 appendString: @"/"];
# endif
	string = [stringClass stringWithString: mutableString2];
	[mutableString2 appendString: @"baz"];
	TEST(@"-[stringByAppendingPathComponent:]",
	    [[mutableString1 stringByAppendingPathComponent: @"baz"]
	    isEqual: mutableString2] &&
	    [[string stringByAppendingPathComponent: @"baz"]
	    isEqual: mutableString2])

# if defined(OF_WINDOWS) || defined(OF_MSDOS)
	TEST(@"-[stringByAppendingPathExtension:]",
	    [[C(@"foo") stringByAppendingPathExtension: @"bar"]
	    isEqual: @"foo.bar"] &&
	    [[C(@"c:\\tmp\\foo") stringByAppendingPathExtension: @"bar"]
	    isEqual: @"c:\\tmp\\foo.bar"] &&
	    [[C(@"c:\\tmp\\/\\") stringByAppendingPathExtension: @"bar"]
	    isEqual: @"c:\\tmp.bar"])
# elif defined(OF_AMIGAOS)
	TEST(@"-[stringByAppendingPathExtension:]",
	    [[C(@"foo") stringByAppendingPathExtension: @"bar"]
	    isEqual: @"foo.bar"] &&
	    [[C(@"foo/bar") stringByAppendingPathExtension: @"baz"]
	    isEqual: @"foo/bar.baz"])
# else
	TEST(@"-[stringByAppendingPathExtension:]",
	    [[C(@"foo") stringByAppendingPathExtension: @"bar"]
	    isEqual: @"foo.bar"] &&
	    [[C(@"foo/bar") stringByAppendingPathExtension: @"baz"]
	    isEqual: @"foo/bar.baz"] &&
	    [[C(@"foo///") stringByAppendingPathExtension: @"bar"]
	    isEqual: @"foo.bar"])
# endif
#endif

	TEST(@"-[hasPrefix:]", [C(@"foobar") hasPrefix: @"foo"] &&
	    ![C(@"foobar") hasPrefix: @"foobar0"])

	TEST(@"-[hasSuffix:]", [C(@"foobar") hasSuffix: @"bar"] &&
	    ![C(@"foobar") hasSuffix: @"foobar0"])

	i = 0;
	TEST(@"-[componentsSeparatedByString:]",
	    (array = [C(@"fooXXbarXXXXbazXXXX")
	    componentsSeparatedByString: @"XX"]) &&
	    [[array objectAtIndex: i++] isEqual: @"foo"] &&
	    [[array objectAtIndex: i++] isEqual: @"bar"] &&
	    [[array objectAtIndex: i++] isEqual: @""] &&
	    [[array objectAtIndex: i++] isEqual: @"baz"] &&
	    [[array objectAtIndex: i++] isEqual: @""] &&
	    [[array objectAtIndex: i++] isEqual: @""] &&
	    array.count == i &&
	    (array = [C(@"foo") componentsSeparatedByString: @""]) &&
	    [[array objectAtIndex: 0] isEqual: @"foo"] &&
	    array.count == 1)

	i = 0;
	TEST(@"-[componentsSeparatedByString:options:]",
	    (array = [C(@"fooXXbarXXXXbazXXXX")
	    componentsSeparatedByString: @"XX"
				options: OFStringSkipEmptyComponents]) &&
	    [[array objectAtIndex: i++] isEqual: @"foo"] &&
	    [[array objectAtIndex: i++] isEqual: @"bar"] &&
	    [[array objectAtIndex: i++] isEqual: @"baz"] &&
	    array.count == i)

	characterSet =
	    [OFCharacterSet characterSetWithCharactersInString: @"XYZ"];

	i = 0;
	TEST(@"-[componentsSeparatedByCharactersInSet:]",
	    (array = [C(@"fooXYbarXYZXbazXYXZx")
	    componentsSeparatedByCharactersInSet: characterSet]) &&
	    [[array objectAtIndex: i++] isEqual: @"foo"] &&
	    [[array objectAtIndex: i++] isEqual: @""] &&
	    [[array objectAtIndex: i++] isEqual: @"bar"] &&
	    [[array objectAtIndex: i++] isEqual: @""] &&
	    [[array objectAtIndex: i++] isEqual: @""] &&
	    [[array objectAtIndex: i++] isEqual: @""] &&
	    [[array objectAtIndex: i++] isEqual: @"baz"] &&
	    [[array objectAtIndex: i++] isEqual: @""] &&
	    [[array objectAtIndex: i++] isEqual: @""] &&
	    [[array objectAtIndex: i++] isEqual: @""] &&
	    [[array objectAtIndex: i++] isEqual: @"x"] &&
	    array.count == i)

	i = 0;
	TEST(@"-[componentsSeparatedByCharactersInSet:options:]",
	    (array = [C(@"fooXYbarXYZXbazXYXZ")
	    componentsSeparatedByCharactersInSet: characterSet
	    options: OFStringSkipEmptyComponents]) &&
	    [[array objectAtIndex: i++] isEqual: @"foo"] &&
	    [[array objectAtIndex: i++] isEqual: @"bar"] &&
	    [[array objectAtIndex: i++] isEqual: @"baz"] &&
	    array.count == i)

#ifdef OF_HAVE_FILES
# if defined(OF_WINDOWS)
	TEST(@"+[pathWithComponents:]",
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"foo", @"bar", @"baz", nil]] isEqual: @"foo\\bar\\baz"] &&
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"c:\\", @"foo", @"bar", @"baz", nil]]
	    isEqual: @"c:\\foo\\bar\\baz"] &&
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"c:", @"foo", @"bar", @"baz", nil]]
	    isEqual: @"c:foo\\bar\\baz"] &&
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"c:", @"\\", @"foo", @"bar", @"baz", nil]]
	    isEqual: @"c:\\foo\\bar\\baz"] &&
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"c:", @"/", @"foo", @"bar", @"baz", nil]]
	    isEqual: @"c:/foo\\bar\\baz"] &&
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"foo/", @"bar\\", @"", @"baz", @"\\", nil]]
	    isEqual: @"foo/bar\\baz"] &&
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"foo", nil]] isEqual: @"foo"] &&
	    [[stringClass pathWithComponents: [OFArray arrayWithObject: @"c:"]]
	    isEqual: @"c:"] &&
	    [[stringClass pathWithComponents:
	    [OFArray arrayWithObject: @"c:\\"]] isEqual: @"c:\\"] &&
	    [[stringClass pathWithComponents:
	    [OFArray arrayWithObject: @"\\"]] isEqual: @"\\"] &&
	    [[stringClass pathWithComponents:
	    [OFArray arrayWithObject: @"/"]] isEqual: @"/"] &&
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"\\\\", @"foo", @"bar", nil]] isEqual: @"\\\\foo\\bar"])
# elif defined(OF_MSDOS)
	TEST(@"+[pathWithComponents:]",
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"foo", @"bar", @"baz", nil]] isEqual: @"foo\\bar\\baz"] &&
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"c:\\", @"foo", @"bar", @"baz", nil]]
	    isEqual: @"c:\\foo\\bar\\baz"] &&
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"c:", @"foo", @"bar", @"baz", nil]]
	    isEqual: @"c:foo\\bar\\baz"] &&
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"c:", @"\\", @"foo", @"bar", @"baz", nil]]
	    isEqual: @"c:\\foo\\bar\\baz"] &&
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"c:", @"/", @"foo", @"bar", @"baz", nil]]
	    isEqual: @"c:/foo\\bar\\baz"] &&
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"foo/", @"bar\\", @"", @"baz", @"\\", nil]]
	    isEqual: @"foo/bar\\baz"] &&
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"foo", nil]] isEqual: @"foo"] &&
	    [[stringClass pathWithComponents: [OFArray arrayWithObject: @"c:"]]
	    isEqual: @"c:"] &&
	    [[stringClass pathWithComponents:
	    [OFArray arrayWithObject: @"c:\\"]] isEqual: @"c:\\"] &&
	    [[stringClass pathWithComponents:
	    [OFArray arrayWithObject: @"\\"]] isEqual: @"\\"] &&
	    [[stringClass pathWithComponents:
	    [OFArray arrayWithObject: @"/"]] isEqual: @"/"])
# elif defined(OF_AMIGAOS)
	TEST(@"+[pathWithComponents:]",
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"dh0:", @"foo", @"bar", @"baz", nil]]
	    isEqual: @"dh0:foo/bar/baz"] &&
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"foo", @"bar", @"baz", nil]] isEqual: @"foo/bar/baz"] &&
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"foo/", @"bar", @"", @"baz", @"/", nil]]
	    isEqual: @"foo//bar/baz//"] &&
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"foo", nil]] isEqual: @"foo"])
# elif defined(OF_NINTENDO_3DS) || defined(OF_WII) || \
    defined(OF_NINTENDO_SWITCH)
	TEST(@"+[pathWithComponents:]",
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"foo", @"bar", @"baz", nil]] isEqual: @"foo/bar/baz"] &&
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"sdmc:", @"foo", @"bar", @"baz", nil]]
	    isEqual: @"sdmc:/foo/bar/baz"] &&
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"foo/", @"bar/", @"", @"baz", @"/", nil]]
	    isEqual: @"foo/bar/baz"] &&
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"foo", nil]] isEqual: @"foo"] &&
	    [[stringClass pathWithComponents: [OFArray arrayWithObject:
	    @"sdmc:"]] isEqual: @"sdmc:/"])
# else
	TEST(@"+[pathWithComponents:]",
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"/", @"foo", @"bar", @"baz", nil]] isEqual: @"/foo/bar/baz"] &&
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"foo", @"bar", @"baz", nil]] isEqual: @"foo/bar/baz"] &&
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"foo/", @"bar", @"", @"baz", @"/", nil]]
	    isEqual: @"foo/bar/baz"] &&
	    [[stringClass pathWithComponents: [OFArray arrayWithObjects:
	    @"foo", nil]] isEqual: @"foo"])
# endif

# if defined(OF_WINDOWS)
	TEST(@"-[pathComponents]",
	    /* c:/tmp */
	    (array = C(@"c:/tmp").pathComponents) && array.count == 2 &&
	    [[array objectAtIndex: 0] isEqual: @"c:/"] &&
	    [[array objectAtIndex: 1] isEqual: @"tmp"] &&
	    /* c:\tmp\ */
	    (array = C(@"c:\\tmp\\").pathComponents) && array.count == 2 &&
	    [[array objectAtIndex: 0] isEqual: @"c:\\"] &&
	    [[array objectAtIndex: 1] isEqual: @"tmp"] &&
	    /* c:\ */
	    (array = C(@"c:\\").pathComponents) && array.count == 1 &&
	    [[array objectAtIndex: 0] isEqual: @"c:\\"] &&
	    /* c:/ */
	    (array = C(@"c:/").pathComponents) && array.count == 1 &&
	    [[array objectAtIndex: 0] isEqual: @"c:/"] &&
	    /* c: */
	    (array = C(@"c:").pathComponents) && array.count == 1 &&
	    [[array objectAtIndex: 0] isEqual: @"c:"] &&
	    /* foo\bar */
	    (array = C(@"foo\\bar").pathComponents) && array.count == 2 &&
	    [[array objectAtIndex: 0] isEqual: @"foo"] &&
	    [[array objectAtIndex: 1] isEqual: @"bar"] &&
	    /* foo\bar/baz/ */
	    (array = C(@"foo\\bar/baz/").pathComponents) && array.count == 3 &&
	    [[array objectAtIndex: 0] isEqual: @"foo"] &&
	    [[array objectAtIndex: 1] isEqual: @"bar"] &&
	    [[array objectAtIndex: 2] isEqual: @"baz"] &&
	    /* foo\/ */
	    (array = C(@"foo\\/").pathComponents) && array.count == 1 &&
	    [[array objectAtIndex: 0] isEqual: @"foo"] &&
	    /* \\foo\bar */
	    (array = C(@"\\\\foo\\bar").pathComponents) && array.count == 3 &&
	    [[array objectAtIndex: 0] isEqual: @"\\\\"] &&
	    [[array objectAtIndex: 1] isEqual: @"foo"] &&
	    [[array objectAtIndex: 2] isEqual: @"bar"] &&
	    C(@"").pathComponents.count == 0)
# elif defined(OF_MSDOS)
	TEST(@"-[pathComponents]",
	    /* c:/tmp */
	    (array = C(@"c:/tmp").pathComponents) && array.count == 2 &&
	    [[array objectAtIndex: 0] isEqual: @"c:/"] &&
	    [[array objectAtIndex: 1] isEqual: @"tmp"] &&
	    /* c:\tmp\ */
	    (array = C(@"c:\\tmp\\").pathComponents) && array.count == 2 &&
	    [[array objectAtIndex: 0] isEqual: @"c:\\"] &&
	    [[array objectAtIndex: 1] isEqual: @"tmp"] &&
	    /* c:\ */
	    (array = C(@"c:\\").pathComponents) && array.count == 1 &&
	    [[array objectAtIndex: 0] isEqual: @"c:\\"] &&
	    /* c:/ */
	    (array = C(@"c:/").pathComponents) && array.count == 1 &&
	    [[array objectAtIndex: 0] isEqual: @"c:/"] &&
	    /* c: */
	    (array = C(@"c:").pathComponents) && array.count == 1 &&
	    [[array objectAtIndex: 0] isEqual: @"c:"] &&
	    /* foo\bar */
	    (array = C(@"foo\\bar").pathComponents) && array.count == 2 &&
	    [[array objectAtIndex: 0] isEqual: @"foo"] &&
	    [[array objectAtIndex: 1] isEqual: @"bar"] &&
	    /* foo\bar/baz/ */
	    (array = C(@"foo\\bar/baz/").pathComponents) && array.count == 3 &&
	    [[array objectAtIndex: 0] isEqual: @"foo"] &&
	    [[array objectAtIndex: 1] isEqual: @"bar"] &&
	    [[array objectAtIndex: 2] isEqual: @"baz"] &&
	    /* foo\/ */
	    (array = C(@"foo\\/").pathComponents) && array.count == 1 &&
	    [[array objectAtIndex: 0] isEqual: @"foo"] &&
	    C(@"").pathComponents.count == 0)
# elif defined(OF_AMIGAOS)
	TEST(@"-[pathComponents]",
	    /* dh0:tmp */
	    (array = C(@"dh0:tmp").pathComponents) && array.count == 2 &&
	    [[array objectAtIndex: 0] isEqual: @"dh0:"] &&
	    [[array objectAtIndex: 1] isEqual: @"tmp"] &&
	    /* dh0:tmp/ */
	    (array = C(@"dh0:tmp/").pathComponents) && array.count == 2 &&
	    [[array objectAtIndex: 0] isEqual: @"dh0:"] &&
	    [[array objectAtIndex: 1] isEqual: @"tmp"] &&
	    /* dh0: */
	    (array = C(@"dh0:/").pathComponents) && array.count == 2 &&
	    [[array objectAtIndex: 0] isEqual: @"dh0:"] &&
	    [[array objectAtIndex: 1] isEqual: @"/"] &&
	    /* foo/bar */
	    (array = C(@"foo/bar").pathComponents) && array.count == 2 &&
	    [[array objectAtIndex: 0] isEqual: @"foo"] &&
	    [[array objectAtIndex: 1] isEqual: @"bar"] &&
	    /* foo/bar/baz/ */
	    (array = C(@"foo/bar/baz/").pathComponents) && array.count == 3 &&
	    [[array objectAtIndex: 0] isEqual: @"foo"] &&
	    [[array objectAtIndex: 1] isEqual: @"bar"] &&
	    [[array objectAtIndex: 2] isEqual: @"baz"] &&
	    /* foo// */
	    (array = C(@"foo//").pathComponents) && array.count == 2 &&
	    [[array objectAtIndex: 0] isEqual: @"foo"] &&
	    [[array objectAtIndex: 1] isEqual: @"/"] &&
	    C(@"").pathComponents.count == 0)
# elif defined(OF_NINTENDO_3DS) || defined(OF_WII) || \
    defined(OF_NINTENDO_SWITCH)
	TEST(@"-[pathComponents]",
	    /* sdmc:/tmp */
	    (array = C(@"sdmc:/tmp").pathComponents) && array.count == 2 &&
	    [[array objectAtIndex: 0] isEqual: @"sdmc:"] &&
	    [[array objectAtIndex: 1] isEqual: @"tmp"] &&
	    /* sdmc:/ */
	    (array = C(@"sdmc:/").pathComponents) && array.count == 1 &&
	    [[array objectAtIndex: 0] isEqual: @"sdmc:"] &&
	    /* foo/bar */
	    (array = C(@"foo/bar").pathComponents) && array.count == 2 &&
	    [[array objectAtIndex: 0] isEqual: @"foo"] &&
	    [[array objectAtIndex: 1] isEqual: @"bar"] &&
	    /* foo/bar/baz/ */
	    (array = C(@"foo/bar/baz/").pathComponents) && array.count == 3 &&
	    [[array objectAtIndex: 0] isEqual: @"foo"] &&
	    [[array objectAtIndex: 1] isEqual: @"bar"] &&
	    [[array objectAtIndex: 2] isEqual: @"baz"] &&
	    /* foo// */
	    (array = C(@"foo//").pathComponents) && array.count == 1 &&
	    [[array objectAtIndex: 0] isEqual: @"foo"] &&
	    C(@"").pathComponents.count == 0)
# else
	TEST(@"-[pathComponents]",
	    /* /tmp */
	    (array = C(@"/tmp").pathComponents) && array.count == 2 &&
	    [[array objectAtIndex: 0] isEqual: @"/"] &&
	    [[array objectAtIndex: 1] isEqual: @"tmp"] &&
	    /* /tmp/ */
	    (array = C(@"/tmp/").pathComponents) && array.count == 2 &&
	    [[array objectAtIndex: 0] isEqual: @"/"] &&
	    [[array objectAtIndex: 1] isEqual: @"tmp"] &&
	    /* / */
	    (array = C(@"/").pathComponents) && array.count == 1 &&
	    [[array objectAtIndex: 0] isEqual: @"/"] &&
	    /* foo/bar */
	    (array = C(@"foo/bar").pathComponents) && array.count == 2 &&
	    [[array objectAtIndex: 0] isEqual: @"foo"] &&
	    [[array objectAtIndex: 1] isEqual: @"bar"] &&
	    /* foo/bar/baz/ */
	    (array = C(@"foo/bar/baz/").pathComponents) && array.count == 3 &&
	    [[array objectAtIndex: 0] isEqual: @"foo"] &&
	    [[array objectAtIndex: 1] isEqual: @"bar"] &&
	    [[array objectAtIndex: 2] isEqual: @"baz"] &&
	    /* foo// */
	    (array = C(@"foo//").pathComponents) && array.count == 1 &&
	    [[array objectAtIndex: 0] isEqual: @"foo"] &&
	    C(@"").pathComponents.count == 0)
# endif

# if defined(OF_WINDOWS)
	TEST(@"-[lastPathComponent]",
	    [C(@"c:/tmp").lastPathComponent isEqual: @"tmp"] &&
	    [C(@"c:\\tmp\\").lastPathComponent isEqual: @"tmp"] &&
	    [C(@"c:\\").lastPathComponent isEqual: @"c:\\"] &&
	    [C(@"c:/").lastPathComponent isEqual: @"c:/"] &&
	    [C(@"\\").lastPathComponent isEqual: @"\\"] &&
	    [C(@"foo").lastPathComponent isEqual: @"foo"] &&
	    [C(@"foo\\bar").lastPathComponent isEqual: @"bar"] &&
	    [C(@"foo/bar/baz/").lastPathComponent isEqual: @"baz"] &&
	    [C(@"\\\\foo\\bar").lastPathComponent isEqual: @"bar"] &&
	    [C(@"\\\\").lastPathComponent isEqual: @"\\\\"])
# elif defined(OF_MSDOS)
	TEST(@"-[lastPathComponent]",
	    [C(@"c:/tmp").lastPathComponent isEqual: @"tmp"] &&
	    [C(@"c:\\tmp\\").lastPathComponent isEqual: @"tmp"] &&
	    [C(@"c:\\").lastPathComponent isEqual: @"c:\\"] &&
	    [C(@"c:/").lastPathComponent isEqual: @"c:/"] &&
	    [C(@"\\").lastPathComponent isEqual: @"\\"] &&
	    [C(@"foo").lastPathComponent isEqual: @"foo"] &&
	    [C(@"foo\\bar").lastPathComponent isEqual: @"bar"] &&
	    [C(@"foo/bar/baz/").lastPathComponent isEqual: @"baz"])
# elif defined(OF_AMIGAOS)
	TEST(@"-[lastPathComponent]",
	    [C(@"dh0:tmp").lastPathComponent isEqual: @"tmp"] &&
	    [C(@"dh0:tmp/").lastPathComponent isEqual: @"tmp"] &&
	    [C(@"dh0:/").lastPathComponent isEqual: @"/"] &&
	    [C(@"dh0:").lastPathComponent isEqual: @"dh0:"] &&
	    [C(@"foo").lastPathComponent isEqual: @"foo"] &&
	    [C(@"foo/bar").lastPathComponent isEqual: @"bar"] &&
	    [C(@"foo/bar/baz/").lastPathComponent isEqual: @"baz"])
# elif defined(OF_NINTENDO_3DS) || defined(OF_WII) || \
    defined(OF_NINTENDO_SWITCH)
	TEST(@"-[lastPathComponent]",
	    [C(@"sdmc:/tmp").lastPathComponent isEqual: @"tmp"] &&
	    [C(@"sdmc:/tmp/").lastPathComponent isEqual: @"tmp"] &&
	    [C(@"sdmc:/").lastPathComponent isEqual: @"sdmc:/"] &&
	    [C(@"sdmc:").lastPathComponent isEqual: @"sdmc:"] &&
	    [C(@"foo").lastPathComponent isEqual: @"foo"] &&
	    [C(@"foo/bar").lastPathComponent isEqual: @"bar"] &&
	    [C(@"foo/bar/baz/").lastPathComponent isEqual: @"baz"])
# else
	TEST(@"-[lastPathComponent]",
	    [C(@"/tmp").lastPathComponent isEqual: @"tmp"] &&
	    [C(@"/tmp/").lastPathComponent isEqual: @"tmp"] &&
	    [C(@"/").lastPathComponent isEqual: @"/"] &&
	    [C(@"foo").lastPathComponent isEqual: @"foo"] &&
	    [C(@"foo/bar").lastPathComponent isEqual: @"bar"] &&
	    [C(@"foo/bar/baz/").lastPathComponent isEqual: @"baz"])
# endif

	TEST(@"-[pathExtension]",
	    [C(@"foo.bar").pathExtension isEqual: @"bar"] &&
	    [C(@"foo/.bar").pathExtension isEqual: @""] &&
	    [C(@"foo/.bar.baz").pathExtension isEqual: @"baz"] &&
	    [C(@"foo/bar.baz/").pathExtension isEqual: @"baz"])

# if defined(OF_WINDOWS)
	TEST(@"-[stringByDeletingLastPathComponent]",
	    [C(@"\\tmp").stringByDeletingLastPathComponent isEqual: @"\\"] &&
	    [C(@"/tmp/").stringByDeletingLastPathComponent isEqual: @"/"] &&
	    [C(@"c:\\").stringByDeletingLastPathComponent isEqual: @"c:\\"] &&
	    [C(@"c:/").stringByDeletingLastPathComponent isEqual: @"c:/"] &&
	    [C(@"c:\\tmp/foo/").stringByDeletingLastPathComponent
	    isEqual: @"c:\\tmp"] &&
	    [C(@"foo\\bar").stringByDeletingLastPathComponent
	    isEqual: @"foo"] &&
	    [C(@"\\").stringByDeletingLastPathComponent isEqual: @"\\"] &&
	    [C(@"foo").stringByDeletingLastPathComponent isEqual: @"."] &&
	    [C(@"\\\\foo\\bar").stringByDeletingLastPathComponent
	    isEqual: @"\\\\foo"] &&
	    [C(@"\\\\foo").stringByDeletingLastPathComponent
	    isEqual: @"\\\\"] &&
	    [C(@"\\\\").stringByDeletingLastPathComponent isEqual: @"\\\\"])
# elif defined(OF_MSDOS)
	TEST(@"-[stringByDeletingLastPathComponent]",
	    [C(@"\\tmp").stringByDeletingLastPathComponent isEqual: @"\\"] &&
	    [C(@"/tmp/").stringByDeletingLastPathComponent isEqual: @"/"] &&
	    [C(@"c:\\").stringByDeletingLastPathComponent isEqual: @"c:\\"] &&
	    [C(@"c:/").stringByDeletingLastPathComponent isEqual: @"c:/"] &&
	    [C(@"c:\\tmp/foo/").stringByDeletingLastPathComponent
	    isEqual: @"c:\\tmp"] &&
	    [C(@"foo\\bar").stringByDeletingLastPathComponent
	    isEqual: @"foo"] &&
	    [C(@"\\").stringByDeletingLastPathComponent isEqual: @"\\"] &&
	    [C(@"foo").stringByDeletingLastPathComponent isEqual: @"."])
# elif defined(OF_AMIGAOS)
	TEST(@"-[stringByDeletingLastPathComponent]",
	    [C(@"dh0:").stringByDeletingLastPathComponent isEqual: @"dh0:"] &&
	    [C(@"dh0:tmp").stringByDeletingLastPathComponent
	    isEqual: @"dh0:"] &&
	    [C(@"dh0:tmp/").stringByDeletingLastPathComponent
	    isEqual: @"dh0:"] &&
	    [C(@"dh0:/").stringByDeletingLastPathComponent isEqual: @"dh0:"] &&
	    [C(@"dh0:tmp/foo/").stringByDeletingLastPathComponent
	    isEqual: @"dh0:tmp"] &&
	    [C(@"foo/bar").stringByDeletingLastPathComponent isEqual: @"foo"] &&
	    [C(@"foo").stringByDeletingLastPathComponent isEqual: @""])
# elif defined(OF_NINTENDO_3DS) || defined(OF_WII) || \
    defined(OF_NINTENDO_SWITCH)
	TEST(@"-[stringByDeletingLastPathComponent]",
	    [C(@"/tmp/").stringByDeletingLastPathComponent isEqual: @""] &&
	    [C(@"sdmc:/tmp/foo/").stringByDeletingLastPathComponent
	    isEqual: @"sdmc:/tmp"] &&
	    [C(@"sdmc:/").stringByDeletingLastPathComponent
	    isEqual: @"sdmc:/"] &&
	    [C(@"foo/bar").stringByDeletingLastPathComponent isEqual: @"foo"] &&
	    [C(@"/").stringByDeletingLastPathComponent isEqual: @""] &&
	    [C(@"foo").stringByDeletingLastPathComponent isEqual: @"."])
# else
	TEST(@"-[stringByDeletingLastPathComponent]",
	    [C(@"/tmp").stringByDeletingLastPathComponent isEqual: @"/"] &&
	    [C(@"/tmp/").stringByDeletingLastPathComponent isEqual: @"/"] &&
	    [C(@"/tmp/foo/").stringByDeletingLastPathComponent
	    isEqual: @"/tmp"] &&
	    [C(@"foo/bar").stringByDeletingLastPathComponent isEqual: @"foo"] &&
	    [C(@"/").stringByDeletingLastPathComponent isEqual: @"/"] &&
	    [C(@"foo").stringByDeletingLastPathComponent isEqual: @"."])
# endif

# if defined(OF_WINDOWS) || defined(OF_MSDOS)
	TEST(@"-[stringByDeletingPathExtension]",
	    [C(@"foo.bar").stringByDeletingPathExtension isEqual: @"foo"] &&
	    [C(@"foo..bar").stringByDeletingPathExtension isEqual: @"foo."] &&
	    [C(@"c:/foo.\\bar").stringByDeletingPathExtension
	    isEqual: @"c:/foo.\\bar"] &&
	    [C(@"c:\\foo./bar.baz").stringByDeletingPathExtension
	    isEqual: @"c:\\foo.\\bar"] &&
	    [C(@"foo.bar/").stringByDeletingPathExtension isEqual: @"foo"] &&
	    [C(@".foo").stringByDeletingPathExtension isEqual: @".foo"] &&
	    [C(@".foo.bar").stringByDeletingPathExtension isEqual: @".foo"])
# elif defined(OF_AMIGAOS)
	TEST(@"-[stringByDeletingPathExtension]",
	    [C(@"foo.bar").stringByDeletingPathExtension isEqual: @"foo"] &&
	    [C(@"foo..bar").stringByDeletingPathExtension isEqual: @"foo."] &&
	    [C(@"dh0:foo.bar").stringByDeletingPathExtension
	    isEqual: @"dh0:foo"] &&
	    [C(@"dh0:foo./bar").stringByDeletingPathExtension
	    isEqual: @"dh0:foo./bar"] &&
	    [C(@"dh0:foo./bar.baz").stringByDeletingPathExtension
	    isEqual: @"dh0:foo./bar"] &&
	    [C(@"foo.bar/").stringByDeletingPathExtension isEqual: @"foo"] &&
	    [C(@".foo").stringByDeletingPathExtension isEqual: @".foo"] &&
	    [C(@".foo\\bar").stringByDeletingPathExtension
	    isEqual: @".foo\\bar"] &&
	    [C(@".foo.bar").stringByDeletingPathExtension isEqual: @".foo"])
# elif defined(OF_NINTENDO_3DS) || defined(OF_WII) || \
    defined(OF_NINTENDO_SWITCH)
	TEST(@"-[stringByDeletingPathExtension]",
	    [C(@"foo.bar").stringByDeletingPathExtension isEqual: @"foo"] &&
	    [C(@"foo..bar").stringByDeletingPathExtension isEqual: @"foo."] &&
	    [C(@"sdmc:/foo./bar").stringByDeletingPathExtension
	    isEqual: @"sdmc:/foo./bar"] &&
	    [C(@"sdmc:/foo./bar.baz").stringByDeletingPathExtension
	    isEqual: @"sdmc:/foo./bar"] &&
	    [C(@"foo.bar/").stringByDeletingPathExtension isEqual: @"foo"] &&
	    [C(@".foo").stringByDeletingPathExtension isEqual: @".foo"] &&
	    [C(@".foo.bar").stringByDeletingPathExtension isEqual: @".foo"])
# else
	TEST(@"-[stringByDeletingPathExtension]",
	    [C(@"foo.bar").stringByDeletingPathExtension isEqual: @"foo"] &&
	    [C(@"foo..bar").stringByDeletingPathExtension isEqual: @"foo."] &&
	    [C(@"/foo./bar").stringByDeletingPathExtension
	    isEqual: @"/foo./bar"] &&
	    [C(@"/foo./bar.baz").stringByDeletingPathExtension
	    isEqual: @"/foo./bar"] &&
	    [C(@"foo.bar/").stringByDeletingPathExtension isEqual: @"foo"] &&
	    [C(@".foo").stringByDeletingPathExtension isEqual: @".foo"] &&
	    [C(@".foo\\bar").stringByDeletingPathExtension
	    isEqual: @".foo\\bar"] &&
	    [C(@".foo.bar").stringByDeletingPathExtension isEqual: @".foo"])
# endif

# ifdef OF_WINDOWS
	/* TODO: Add more tests */
	TEST(@"-[stringByStandardizingPath]",
	    [C(@"\\\\foo\\..\\bar\\qux").stringByStandardizingPath
	    isEqual: @"\\\\bar\\qux"] &&
	    [C(@"c:\\..\\asd").stringByStandardizingPath
	    isEqual: @"c:\\..\\asd"])
# endif
#endif

	TEST(@"-[longLongValue]",
	    C(@"1234").longLongValue == 1234 &&
	    C(@"\r\n+123  ").longLongValue == 123 &&
	    C(@"-500\t").longLongValue == -500 &&
	    [C(@"-0x10\t") longLongValueWithBase: 0] == -0x10 &&
	    C(@"\t\t\r\n").longLongValue == 0 &&
	    [C(@"123f") longLongValueWithBase: 16] == 0x123f &&
	    [C(@"-1234") longLongValueWithBase: 0] == -1234 &&
	    [C(@"\t\n0xABcd\r") longLongValueWithBase: 0] == 0xABCD &&
	    [C(@"1234567") longLongValueWithBase: 8] == 01234567 &&
	    [C(@"\r\n0123") longLongValueWithBase: 0] == 0123 &&
	    [C(@"765\t") longLongValueWithBase: 8] == 0765 &&
	    [C(@"\t\t\r\n") longLongValueWithBase: 8] == 0)

	TEST(@"-[unsignedLongLongValue]",
	    C(@"1234").unsignedLongLongValue == 1234 &&
	    C(@"\r\n+123  ").unsignedLongLongValue == 123 &&
	    C(@"\t\t\r\n").unsignedLongLongValue == 0 &&
	    [C(@"123f") unsignedLongLongValueWithBase: 16] == 0x123f &&
	    [C(@"1234") unsignedLongLongValueWithBase: 0] == 1234 &&
	    [C(@"\t\n0xABcd\r") unsignedLongLongValueWithBase: 0] == 0xABCD &&
	    [C(@"1234567") unsignedLongLongValueWithBase: 8] == 01234567 &&
	    [C(@"\r\n0123") unsignedLongLongValueWithBase: 0] == 0123 &&
	    [C(@"765\t") unsignedLongLongValueWithBase: 8] == 0765 &&
	    [C(@"\t\t\r\n") unsignedLongLongValueWithBase: 8] == 0)

	/*
	 * These test numbers can be generated without rounding if we have IEEE
	 * floating point numbers, thus we can use == on them.
	 */
	TEST(@"-[floatValue]",
	    C(@"\t-0.25 ").floatValue == -0.25 &&
	    C(@"\r\n\tINF\t\n").floatValue == INFINITY &&
	    C(@"\r -INFINITY\n").floatValue == -INFINITY &&
	    isnan(C(@"   NAN\t\t").floatValue) &&
	    isnan(C(@"   -NaN\t\t").floatValue))

#if !defined(OF_ANDROID) && !defined(OF_SOLARIS) && !defined(OF_HPUX) && \
    !defined(OF_DJGPP) && !defined(OF_AMIGAOS_M68K)
# define INPUT @"\t-0x1.FFFFFFFFFFFFFP-1020 "
# define EXPECTED -0x1.FFFFFFFFFFFFFP-1020
#else
/* Android, Solaris, HP-UX, DJGPP and AmigaOS 3 do not accept 0x for strtod() */
# if (!defined(OF_SOLARIS) || !defined(OF_X86)) && !defined(OF_AMIGAOS_M68K)
#  define INPUT @"\t-0.123456789 "
#  define EXPECTED -0.123456789
# else
/*
 * Solaris' strtod() has weird rounding on x86, but not on x86_64.
 * AmigaOS 3 with libnix has weird rounding as well.
 */
#  define INPUT @"\t-0.125 "
#  define EXPECTED -0.125
# endif
#endif
	TEST(@"-[doubleValue]",
	    INPUT.doubleValue == EXPECTED &&
	    C(@"\r\n\tINF\t\n").doubleValue == INFINITY &&
	    C(@"\r -INFINITY\n").doubleValue == -INFINITY &&
	    isnan(C(@"   NAN\t\t").doubleValue))
#undef INPUT
#undef EXPECTED

	EXPECT_EXCEPTION(@"Detect invalid chars in -[longLongValue] #1",
	    OFInvalidFormatException, [C(@"abc") longLongValue])
	EXPECT_EXCEPTION(@"Detect invalid chars in -[longLongValue] #2",
	    OFInvalidFormatException, [C(@"0a") longLongValue])
	EXPECT_EXCEPTION(@"Detect invalid chars in -[longLongValue] #3",
	    OFInvalidFormatException, [C(@"0 1") longLongValue])
	EXPECT_EXCEPTION(@"Detect invalid chars in -[longLongValue] #4",
	    OFInvalidFormatException,
	    [C(@"0xABCDEFG") longLongValueWithBase: 0])
	EXPECT_EXCEPTION(@"Detect invalid chars in -[longLongValue] #5",
	    OFInvalidFormatException, [C(@"0x") longLongValueWithBase: 0])

	EXPECT_EXCEPTION(@"Detect invalid chars in -[floatValue] #1",
	    OFInvalidFormatException, [C(@"0.0a") floatValue])
	EXPECT_EXCEPTION(@"Detect invalid chars in -[floatValue] #2",
	    OFInvalidFormatException, [C(@"0 0") floatValue])
#ifdef HAVE_STRTOF_L
	/*
	 * Only do this if we have strtof_l, as the locale might allow the
	 * comma.
	 */
	EXPECT_EXCEPTION(@"Detect invalid chars in -[floatValue] #3",
	    OFInvalidFormatException, [C(@"0,0") floatValue])
#endif

	EXPECT_EXCEPTION(@"Detect invalid chars in -[doubleValue] #1",
	    OFInvalidFormatException, [C(@"0.0a") doubleValue])
	EXPECT_EXCEPTION(@"Detect invalid chars in -[doubleValue] #2",
	    OFInvalidFormatException, [C(@"0 0") doubleValue])
#ifdef HAVE_STRTOD_L
	/*
	 * Only do this if we have strtod_l, as the locale might allow the
	 * comma.
	 */
	EXPECT_EXCEPTION(@"Detect invalid chars in -[doubleValue] #3",
	    OFInvalidFormatException, [C(@"0,0") doubleValue])
#endif

	EXPECT_EXCEPTION(@"Detect out of range in -[longLongValue]",
	    OFOutOfRangeException,
	    [C(@"-12345678901234567890123456789012345678901234567890"
	       @"12345678901234567890123456789012345678901234567890")
	    longLongValueWithBase: 16])

	EXPECT_EXCEPTION(@"Detect out of range in -[unsignedLongLongValue]",
	    OFOutOfRangeException,
	    [C(@"0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF"
	       @"0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF")
	    unsignedLongLongValueWithBase: 16])

	TEST(@"-[characters]", (characters = C(@"fööbär🀺").characters) &&
	    !memcmp(characters, unicharString + 1, sizeof(unicharString) - 8))

#ifdef OF_BIG_ENDIAN
# define swappedByteOrder OFByteOrderLittleEndian
#else
# define swappedByteOrder OFByteOrderBigEndian
#endif
	TEST(@"-[UTF16String]", (UTF16Characters = C(@"fööbär🀺").UTF16String) &&
	    !memcmp(UTF16Characters, char16String + 1,
	    OFUTF16StringLength(char16String) * 2) &&
	    (UTF16Characters = [C(@"fööbär🀺")
	    UTF16StringWithByteOrder: swappedByteOrder]) &&
	    !memcmp(UTF16Characters, swappedChar16String + 1,
	    OFUTF16StringLength(swappedChar16String) * 2))

	TEST(@"-[UTF16StringLength]", C(@"fööbär🀺").UTF16StringLength == 8)

	TEST(@"-[UTF32String]", (characters = C(@"fööbär🀺").UTF32String) &&
	    !memcmp(characters, unicharString + 1,
	    OFUTF32StringLength(unicharString) * 4) &&
	    (characters = [C(@"fööbär🀺") UTF32StringWithByteOrder:
	    swappedByteOrder]) &&
	    !memcmp(characters, swappedUnicharString + 1,
	    OFUTF32StringLength(swappedUnicharString) * 4))
#undef swappedByteOrder

	TEST(@"-[stringByMD5Hashing]", [C(@"asdfoobar").stringByMD5Hashing
	    isEqual: @"184dce2ec49b5422c7cfd8728864db4c"])

	TEST(@"-[stringByRIPEMD160Hashing]",
	    [C(@"asdfoobar").stringByRIPEMD160Hashing
	    isEqual: @"021d773b0fac06eb6755ca6aa58a580c980f7f13"])

	TEST(@"-[stringBySHA1Hashing]", [C(@"asdfoobar").stringBySHA1Hashing
	    isEqual: @"f5f81ac0a8b5cbfdc4585ec1ad32e7b3a12b9b49"])

	TEST(@"-[stringBySHA224Hashing]", [C(@"asdfoobar").stringBySHA224Hashing
	    isEqual: @"5a06822dcbd5a874f67d062b80b9d8a9cb9b5b303960b9da9290c192"
	    ])

	TEST(@"-[stringBySHA256Hashing]", [C(@"asdfoobar").stringBySHA256Hashing
	    isEqual: @"28e65b1dcd7f6ce2ea6277b15f87b913628b5500bf7913a2bbf4cedc"
		     @"fa1215f6"])

	TEST(@"-[stringBySHA384Hashing]", [C(@"asdfoobar").stringBySHA384Hashing
	    isEqual: @"73286da882ffddca2f45e005cfa6b44f3fc65bfb26db1d087ded2f9c"
		     @"279e5addf8be854044bca0cece073fce28eec7d9"])

	TEST(@"-[stringBySHA512Hashing]", [C(@"asdfoobar").stringBySHA512Hashing
	    isEqual: @"0464c427da158b02161bb44a3090bbfc594611ef6a53603640454b56"
		     @"412a9247c3579a329e53a5dc74676b106755e3394f9454a2d4227324"
		     @"2615d32f80437d61"])

	characterSet =
	    [OFCharacterSet characterSetWithCharactersInString: @"abfo'_~$🍏"];
	TEST(@"-[stringByAddingPercentEncodingWithAllowedCharacters:]",
	    [[C(@"foo\"ba'_~$]🍏🍌")
	    stringByAddingPercentEncodingWithAllowedCharacters: characterSet]
	    isEqual: @"foo%22ba'_~$%5D🍏%F0%9F%8D%8C"])

	TEST(@"-[stringByRemovingPercentEncoding]",
	    [C(@"foo%20bar%22+%24%F0%9F%8D%8C").stringByRemovingPercentEncoding
	    isEqual: @"foo bar\"+$🍌"])

	TEST(@"-[insertString:atIndex:]",
	    (mutableString1 = [mutableStringClass
	    stringWithString: @"𝄞öööbä€"]) &&
	    R([mutableString1 insertString: @"äöü" atIndex: 3]) &&
	    [mutableString1 isEqual: @"𝄞ööäöüöbä€"])

	EXPECT_EXCEPTION(@"Detect invalid format in "
	    @"-[stringByRemovingPercentEncoding] #1",
	    OFInvalidFormatException,
	    [C(@"foo%xbar") stringByRemovingPercentEncoding])
	EXPECT_EXCEPTION(@"Detect invalid encoding in "
	    @"-[stringByRemovingPercentEncoding] #2",
	    OFInvalidEncodingException,
	    [C(@"foo%FFbar") stringByRemovingPercentEncoding])

	TEST(@"-[setCharacter:atIndex:]",
	    (mutableString1 = [mutableStringClass
	    stringWithString: @"abäde"]) &&
	    R([mutableString1 setCharacter: 0xF6 atIndex: 2]) &&
	    [mutableString1 isEqual: @"aböde"] &&
	    R([mutableString1 setCharacter: 'c' atIndex: 2]) &&
	    [mutableString1 isEqual: @"abcde"] &&
	    R([mutableString1 setCharacter: 0x20AC atIndex: 3]) &&
	    [mutableString1 isEqual: @"abc€e"] &&
	    R([mutableString1 setCharacter: 'x' atIndex: 1]) &&
	    [mutableString1 isEqual: @"axc€e"])

	TEST(@"-[deleteCharactersInRange:]",
	    (mutableString1 = [mutableStringClass
	    stringWithString: @"𝄞öööbä€"]) &&
	    R([mutableString1 deleteCharactersInRange: OFMakeRange(1, 3)]) &&
	    [mutableString1 isEqual: @"𝄞bä€"] &&
	    R([mutableString1 deleteCharactersInRange: OFMakeRange(0, 4)]) &&
	    [mutableString1 isEqual: @""])

	TEST(@"-[replaceCharactersInRange:withString:]",
	    (mutableString1 = [mutableStringClass
	    stringWithString: @"𝄞öööbä€"]) &&
	    R([mutableString1 replaceCharactersInRange: OFMakeRange(1, 3)
					    withString: @"äöüß"]) &&
	    [mutableString1 isEqual: @"𝄞äöüßbä€"] &&
	    R([mutableString1 replaceCharactersInRange: OFMakeRange(4, 2)
					    withString: @"b"]) &&
	    [mutableString1 isEqual: @"𝄞äöübä€"] &&
	    R([mutableString1 replaceCharactersInRange: OFMakeRange(0, 7)
					    withString: @""]) &&
	    [mutableString1 isEqual: @""])

	EXPECT_EXCEPTION(@"Detect OoR in -[deleteCharactersInRange:] #1",
	    OFOutOfRangeException,
	    {
		mutableString1 = [mutableStringClass stringWithString: @"𝄞öö"];
		[mutableString1 deleteCharactersInRange: OFMakeRange(2, 2)];
	    })

	EXPECT_EXCEPTION(@"Detect OoR in -[deleteCharactersInRange:] #2",
	    OFOutOfRangeException,
	    [mutableString1 deleteCharactersInRange: OFMakeRange(4, 0)])

	EXPECT_EXCEPTION(@"Detect OoR in "
	    @"-[replaceCharactersInRange:withString:] #1",
	    OFOutOfRangeException,
	    [mutableString1 replaceCharactersInRange: OFMakeRange(2, 2)
					  withString: @""])

	EXPECT_EXCEPTION(@"Detect OoR in "
	    @"-[replaceCharactersInRange:withString:] #2",
	    OFOutOfRangeException,
	    [mutableString1 replaceCharactersInRange: OFMakeRange(4, 0)
					  withString: @""])

	TEST(@"-[replaceOccurrencesOfString:withString:]",
	    (mutableString1 = [mutableStringClass stringWithString:
	    @"asd fo asd fofo asd"]) &&
	    R([mutableString1 replaceOccurrencesOfString: @"fo"
					      withString: @"foo"]) &&
	    [mutableString1 isEqual: @"asd foo asd foofoo asd"] &&
	    (mutableString1 = [mutableStringClass stringWithString: @"XX"]) &&
	    R([mutableString1 replaceOccurrencesOfString: @"X"
					      withString: @"XX"]) &&
	    [mutableString1 isEqual: @"XXXX"])

	TEST(@"-[replaceOccurrencesOfString:withString:options:range:]",
	    (mutableString1 = [mutableStringClass stringWithString:
	    @"foofoobarfoobarfoo"]) && R([mutableString1
	    replaceOccurrencesOfString: @"oo"
			    withString: @"óò"
			       options: 0
				 range: OFMakeRange(2, 15)]) &&
	    [mutableString1 isEqual: @"foofóòbarfóòbarfoo"])

	TEST(@"-[deleteLeadingWhitespaces]",
	    (mutableString1 = [mutableStringClass
	    stringWithString: whitespace[0]]) &&
	    R([mutableString1 deleteLeadingWhitespaces]) &&
	    [mutableString1 isEqual: @"asd  \t \t\t\r\n"] &&
	    (mutableString1 = [mutableStringClass
	    stringWithString: whitespace[1]]) &&
	    R([mutableString1 deleteLeadingWhitespaces]) &&
	    [mutableString1 isEqual: @""])

	TEST(@"-[deleteTrailingWhitespaces]",
	    (mutableString1 = [mutableStringClass
	    stringWithString: whitespace[0]]) &&
	    R([mutableString1 deleteTrailingWhitespaces]) &&
	    [mutableString1 isEqual: @" \r \t\n\t \tasd"] &&
	    (mutableString1 = [mutableStringClass
	    stringWithString: whitespace[1]]) &&
	    R([mutableString1 deleteTrailingWhitespaces]) &&
	    [mutableString1 isEqual: @""])

	TEST(@"-[deleteEnclosingWhitespaces]",
	    (mutableString1 = [mutableStringClass
	    stringWithString: whitespace[0]]) &&
	    R([mutableString1 deleteEnclosingWhitespaces]) &&
	    [mutableString1 isEqual: @"asd"] &&
	    (mutableString1 = [mutableStringClass
	    stringWithString: whitespace[1]]) &&
	    R([mutableString1 deleteEnclosingWhitespaces]) &&
	    [mutableString1 isEqual: @""])

#ifdef OF_HAVE_UNICODE_TABLES
	TEST(@"-[decomposedStringWithCanonicalMapping]",
	    [C(@"H\xC3\xA4lǉ\xC3\xB6").decomposedStringWithCanonicalMapping
	    isEqual: @"H\x61\xCC\x88lǉ\x6F\xCC\x88"]);

	TEST(@"-[decomposedStringWithCompatibilityMapping]",
	    [C(@"H\xC3\xA4lǉ\xC3\xB6").decomposedStringWithCompatibilityMapping
	    isEqual: @"H\x61\xCC\x88llj\x6F\xCC\x88"]);
#endif

	TEST(@"-[stringByXMLEscaping]",
	    (string = C(@"<hello> &world'\"!&").stringByXMLEscaping) &&
	    [string isEqual: @"&lt;hello&gt; &amp;world&apos;&quot;!&amp;"])

	TEST(@"-[stringByXMLUnescaping]",
	    [string.stringByXMLUnescaping isEqual: @"<hello> &world'\"!&"] &&
	    [C(@"&#x79;").stringByXMLUnescaping isEqual: @"y"] &&
	    [C(@"&#xe4;").stringByXMLUnescaping isEqual: @"ä"] &&
	    [C(@"&#8364;").stringByXMLUnescaping isEqual: @"€"] &&
	    [C(@"&#x1D11E;").stringByXMLUnescaping isEqual: @"𝄞"])

	EXPECT_EXCEPTION(@"Detect unknown entities in -[stringByXMLUnescaping]",
	    OFUnknownXMLEntityException, [C(@"&foo;") stringByXMLUnescaping])
	EXPECT_EXCEPTION(@"Detect invalid entities in -[stringByXMLUnescaping] "
	    @"#1", OFInvalidFormatException,
	    [C(@"x&amp") stringByXMLUnescaping])
	EXPECT_EXCEPTION(@"Detect invalid entities in -[stringByXMLUnescaping] "
	    @"#2", OFInvalidFormatException, [C(@"&#;") stringByXMLUnescaping])
	EXPECT_EXCEPTION(@"Detect invalid entities in -[stringByXMLUnescaping] "
	    @"#3", OFInvalidFormatException, [C(@"&#x;") stringByXMLUnescaping])
	EXPECT_EXCEPTION(@"Detect invalid entities in -[stringByXMLUnescaping] "
	    @"#4", OFInvalidFormatException, [C(@"&#g;") stringByXMLUnescaping])
	EXPECT_EXCEPTION(@"Detect invalid entities in -[stringByXMLUnescaping] "
	    @"#5", OFInvalidFormatException,
	    [C(@"&#xg;") stringByXMLUnescaping])

	TEST(@"-[stringByXMLUnescapingWithDelegate:]",
	    (entityHandler = [[[EntityHandler alloc] init] autorelease]) &&
	    [[C(@"x&foo;y") stringByXMLUnescapingWithDelegate: entityHandler]
	    isEqual: @"xbary"])

#ifdef OF_HAVE_BLOCKS
	TEST(@"-[stringByXMLUnescapingWithBlock:]",
	    [[C(@"x&foo;y") stringByXMLUnescapingWithBlock:
		^ OFString *(OFString *str, OFString *entity) {
		    if ([entity isEqual: @"foo"])
			    return @"bar";

		    return nil;
	    }] isEqual: @"xbary"])

	j = 0;
	ok = true;
	[C(@"foo\nbar\nbaz") enumerateLinesUsingBlock:
	    ^ (OFString *line, bool *stop) {
		switch (j) {
		case 0:
			if (![line isEqual: @"foo"])
				ok = false;
			break;
		case 1:
			if (![line isEqual: @"bar"])
				ok = false;
			break;
		case 2:
			if (![line isEqual: @"baz"])
				ok = false;
			break;
		default:
			ok = false;
		}

		j++;
	}];
	TEST(@"-[enumerateLinesUsingBlock:]", ok)
#endif

#undef C

	objc_autoreleasePoolPop(pool);
}

- (void)stringTests
{
	module = @"OFString";
	[self stringTestsWithClass: [SimpleString class]
		      mutableClass: [SimpleMutableString class]];

	module = @"OFString_UTF8";
	[self stringTestsWithClass: [OFUTF8String class]
		      mutableClass: [OFMutableUTF8String class]];
}
@end
