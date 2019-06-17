/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

static OFString *module = nil;
static OFString *whitespace[] = {
	@" \r \t\n\t \tasd  \t \t\t\r\n",
	@" \t\t  \t\t  \t \t"
};
static of_unichar_t ucstr[] = {
	0xFEFF, 'f', 0xF6, 0xF6, 'b', 0xE4, 'r', 0x1F03A, 0
};
static of_unichar_t sucstr[] = {
	0xFFFE0000, 0x66000000, 0xF6000000, 0xF6000000, 0x62000000, 0xE4000000,
	0x72000000, 0x3AF00100, 0
};
static uint16_t utf16str[] = {
	0xFEFF, 'f', 0xF6, 0xF6, 'b', 0xE4, 'r', 0xD83C, 0xDC3A, 0
};
static uint16_t sutf16str[] = {
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
		       encoding: (of_string_encoding_t)encoding
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

- (instancetype)initWithUTF16String: (const of_char16_t *)UTF16String
			     length: (size_t)length
			  byteOrder: (of_byte_order_t)byteOrder
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

- (instancetype)initWithUTF32String: (const of_char32_t *)UTF32String
			     length: (size_t)length
			  byteOrder: (of_byte_order_t)byteOrder
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

- (of_unichar_t)characterAtIndex: (size_t)idx
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

- (void)replaceCharactersInRange: (of_range_t)range
		      withString: (OFString *)string
{
	[_string replaceCharactersInRange: range
			       withString: string];
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
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFMutableString *s[3];
	OFString *is;
	OFArray *a;
	size_t i;
	const of_unichar_t *ua;
	const uint16_t *u16a;
	OFCharacterSet *cs;
	EntityHandler *h;
#ifdef OF_HAVE_BLOCKS
	__block int j;
	__block bool ok;
#endif

#define C(s) ((OFString *)[stringClass stringWithString: s])

	s[0] = [mutableStringClass stringWithString: @"täs€"];
	s[1] = [mutableStringClass string];
	s[2] = [[s[0] copy] autorelease];

	TEST(@"-[isEqual:]", [s[0] isEqual: s[2]] &&
	    ![s[0] isEqual: [[[OFObject alloc] init] autorelease]])

	TEST(@"-[compare:]", [s[0] compare: s[2]] == OF_ORDERED_SAME &&
	    [s[0] compare: @""] != OF_ORDERED_SAME &&
	    [C(@"") compare: @"a"] == OF_ORDERED_ASCENDING &&
	    [C(@"a") compare: @"b"] == OF_ORDERED_ASCENDING &&
	    [C(@"cd") compare: @"bc"] == OF_ORDERED_DESCENDING &&
	    [C(@"ä") compare: @"ö"] == OF_ORDERED_ASCENDING &&
	    [C(@"€") compare: @"ß"] == OF_ORDERED_DESCENDING &&
	    [C(@"aa") compare: @"z"] == OF_ORDERED_ASCENDING)

#ifdef OF_HAVE_UNICODE_TABLES
	TEST(@"-[caseInsensitiveCompare:]",
	    [C(@"a") caseInsensitiveCompare: @"A"] == OF_ORDERED_SAME &&
	    [C(@"Ä") caseInsensitiveCompare: @"ä"] == OF_ORDERED_SAME &&
	    [C(@"я") caseInsensitiveCompare: @"Я"] == OF_ORDERED_SAME &&
	    [C(@"€") caseInsensitiveCompare: @"ß"] == OF_ORDERED_DESCENDING &&
	    [C(@"ß") caseInsensitiveCompare: @"→"] == OF_ORDERED_ASCENDING &&
	    [C(@"AA") caseInsensitiveCompare: @"z"] == OF_ORDERED_ASCENDING &&
	    [[stringClass stringWithUTF8String: "ABC"] caseInsensitiveCompare:
	    [stringClass stringWithUTF8String: "AbD"]] ==
	    [C(@"abc") compare: @"abd"])
#else
	TEST(@"-[caseInsensitiveCompare:]",
	    [C(@"a") caseInsensitiveCompare: @"A"] == OF_ORDERED_SAME &&
	    [C(@"AA") caseInsensitiveCompare: @"z"] == OF_ORDERED_ASCENDING &&
	    [[stringClass stringWithUTF8String: "ABC"] caseInsensitiveCompare:
	    [stringClass stringWithUTF8String: "AbD"]] ==
	    [C(@"abc") compare: @"abd"])
#endif

	TEST(@"-[hash] is the same if -[isEqual:] is true",
	    s[0].hash == s[2].hash)

	TEST(@"-[description]", [s[0].description isEqual: s[0]])

	TEST(@"-[appendString:] and -[appendUTF8String:]",
	    R([s[1] appendUTF8String: "1𝄞"]) && R([s[1] appendString: @"3"]) &&
	    R([s[0] appendString: s[1]]) && [s[0] isEqual: @"täs€1𝄞3"])

	TEST(@"-[appendCharacters:length:]",
	    R([s[1] appendCharacters: ucstr + 6
			      length: 2]) && [s[1] isEqual: @"1𝄞3r🀺"])

	TEST(@"-[length]", s[0].length == 7)
	TEST(@"-[UTF8StringLength]", s[0].UTF8StringLength == 13)
	TEST(@"-[hash]", s[0].hash == 0x705583C0)

	TEST(@"-[characterAtIndex:]", [s[0] characterAtIndex: 0] == 't' &&
	    [s[0] characterAtIndex: 1] == 0xE4 &&
	    [s[0] characterAtIndex: 3] == 0x20AC &&
	    [s[0] characterAtIndex: 5] == 0x1D11E)

	EXPECT_EXCEPTION(@"Detect out of range in -[characterAtIndex:]",
	    OFOutOfRangeException, [s[0] characterAtIndex: 7])

	TEST(@"-[reverse]", R([s[0] reverse]) && [s[0] isEqual: @"3𝄞1€sät"])

	s[1] = [mutableStringClass stringWithString: @"abc"];

#ifdef OF_HAVE_UNICODE_TABLES
	TEST(@"-[uppercase]", R([s[0] uppercase]) &&
	    [s[0] isEqual: @"3𝄞1€SÄT"] &&
	    R([s[1] uppercase]) && [s[1] isEqual: @"ABC"])

	TEST(@"-[lowercase]", R([s[0] lowercase]) &&
	    [s[0] isEqual: @"3𝄞1€sät"] &&
	    R([s[1] lowercase]) && [s[1] isEqual: @"abc"])

	TEST(@"-[uppercaseString]",
	    [[s[0] uppercaseString] isEqual: @"3𝄞1€SÄT"])

	TEST(@"-[lowercaseString]", R([s[0] uppercase]) &&
	    [[s[0] lowercaseString] isEqual: @"3𝄞1€sät"])

	TEST(@"-[capitalizedString]", [C(@"ǆbla tǆst TǄST").capitalizedString
	    isEqual: @"ǅbla Tǆst Tǆst"])
#else
	TEST(@"-[uppercase]", R([s[0] uppercase]) &&
	    [s[0] isEqual: @"3𝄞1€SäT"] &&
	    R([s[1] uppercase]) && [s[1] isEqual: @"ABC"])

	TEST(@"-[lowercase]", R([s[0] lowercase]) &&
	    [s[0] isEqual: @"3𝄞1€sät"] &&
	    R([s[1] lowercase]) && [s[1] isEqual: @"abc"])

	TEST(@"-[uppercaseString]", [s[0].uppercaseString isEqual: @"3𝄞1€SäT"])

	TEST(@"-[lowercaseString]", R([s[0] uppercase]) &&
	    [s[0].lowercaseString isEqual: @"3𝄞1€sät"])

	TEST(@"-[capitalizedString]", [C(@"ǆbla tǆst TǄST").capitalizedString
	    isEqual: @"ǆbla Tǆst TǄst"])
#endif

	TEST(@"+[stringWithUTF8String:length:]",
	    (s[0] = [mutableStringClass stringWithUTF8String: "\xEF\xBB\xBF"
							      "foobar"
						      length: 6]) &&
	    [s[0] isEqual: @"foo"])

	TEST(@"+[stringWithUTF16String:]",
	    (is = [stringClass stringWithUTF16String: utf16str]) &&
	    [is isEqual: @"fööbär🀺"] &&
	    (is = [stringClass stringWithUTF16String: sutf16str]) &&
	    [is isEqual: @"fööbär🀺"])

	TEST(@"+[stringWithUTF32String:]",
	    (is = [stringClass stringWithUTF32String: ucstr]) &&
	    [is isEqual: @"fööbär🀺"] &&
	    (is = [stringClass stringWithUTF32String: sucstr]) &&
	    [is isEqual: @"fööbär🀺"])

#ifdef OF_HAVE_FILES
	TEST(@"+[stringWithContentsOfFile:encoding]", (is = [stringClass
	    stringWithContentsOfFile: @"testfile.txt"
			    encoding: OF_STRING_ENCODING_ISO_8859_1]) &&
	    [is isEqual: @"testäöü"])

	TEST(@"+[stringWithContentsOfURL:encoding]", (is = [stringClass
	    stringWithContentsOfURL: [OFURL fileURLWithPath: @"testfile.txt"]
			   encoding: OF_STRING_ENCODING_ISO_8859_1]) &&
	    [is isEqual: @"testäöü"])
#endif

	TEST(@"-[appendUTFString:length:]",
	    R([s[0] appendUTF8String: "\xEF\xBB\xBF" "barqux"
			      length: 6]) && [s[0] isEqual: @"foobar"])

	EXPECT_EXCEPTION(@"Detection of invalid UTF-8 encoding #1",
	    OFInvalidEncodingException,
	    [stringClass stringWithUTF8String: "\xE0\x80"])
	EXPECT_EXCEPTION(@"Detection of invalid UTF-8 encoding #2",
	    OFInvalidEncodingException,
	    [stringClass stringWithUTF8String: "\xF0\x80\x80\xC0"])

	TEST(@"Conversion of ISO 8859-1 to Unicode",
	    [[stringClass stringWithCString: "\xE4\xF6\xFC"
				   encoding: OF_STRING_ENCODING_ISO_8859_1]
	    isEqual: @"äöü"])

#ifdef HAVE_ISO_8859_15
	TEST(@"Conversion of ISO 8859-15 to Unicode",
	    [[stringClass stringWithCString: "\xA4\xA6\xA8\xB4\xB8\xBC\xBD\xBE"
				   encoding: OF_STRING_ENCODING_ISO_8859_15]
	    isEqual: @"€ŠšŽžŒœŸ"])
#endif

#ifdef HAVE_WINDOWS_1252
	TEST(@"Conversion of Windows 1252 to Unicode",
	    [[stringClass stringWithCString: "\x80\x82\x83\x84\x85\x86\x87\x88"
					     "\x89\x8A\x8B\x8C\x8E\x91\x92\x93"
					     "\x94\x95\x96\x97\x98\x99\x9A\x9B"
					     "\x9C\x9E\x9F"
				   encoding: OF_STRING_ENCODING_WINDOWS_1252]
	    isEqual: @"€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ"])
#endif

#ifdef HAVE_CODEPAGE_437
	TEST(@"Conversion of Codepage 437 to Unicode",
	    [[stringClass stringWithCString: "\xB0\xB1\xB2\xDB"
				   encoding: OF_STRING_ENCODING_CODEPAGE_437]
	    isEqual: @"░▒▓█"])
#endif

	TEST(@"Conversion of Unicode to ASCII #1",
	    !strcmp([C(@"This is a test") cStringWithEncoding:
	    OF_STRING_ENCODING_ASCII], "This is a test"))

	EXPECT_EXCEPTION(@"Conversion of Unicode to ASCII #2",
	    OFInvalidEncodingException,
	    [C(@"This is a tést")
	    cStringWithEncoding: OF_STRING_ENCODING_ASCII])

	TEST(@"Conversion of Unicode to ISO-8859-1 #1",
	    !strcmp([C(@"This is ä test") cStringWithEncoding:
	    OF_STRING_ENCODING_ISO_8859_1], "This is \xE4 test"))

	EXPECT_EXCEPTION(@"Conversion of Unicode to ISO-8859-1 #2",
	    OFInvalidEncodingException,
	    [C(@"This is ä t€st") cStringWithEncoding:
	    OF_STRING_ENCODING_ISO_8859_1])

#ifdef HAVE_ISO_8859_15
	TEST(@"Conversion of Unicode to ISO-8859-15 #1",
	    !strcmp([C(@"This is ä t€st") cStringWithEncoding:
	    OF_STRING_ENCODING_ISO_8859_15], "This is \xE4 t\xA4st"))

	EXPECT_EXCEPTION(@"Conversion of Unicode to ISO-8859-15 #2",
	    OFInvalidEncodingException,
	    [C(@"This is ä t€st…") cStringWithEncoding:
	    OF_STRING_ENCODING_ISO_8859_15])
#endif

#ifdef HAVE_WINDOWS_1252
	TEST(@"Conversion of Unicode to Windows-1252 #1",
	    !strcmp([C(@"This is ä t€st…") cStringWithEncoding:
	    OF_STRING_ENCODING_WINDOWS_1252], "This is \xE4 t\x80st\x85"))

	EXPECT_EXCEPTION(@"Conversion of Unicode to Windows-1252 #2",
	    OFInvalidEncodingException, [C(@"This is ä t€st…‼")
	    cStringWithEncoding: OF_STRING_ENCODING_WINDOWS_1252])
#endif

#ifdef HAVE_CODEPAGE_437
	TEST(@"Conversion of Unicode to Codepage 437 #1",
	    !strcmp([C(@"Tést strîng ░▒▓") cStringWithEncoding:
	    OF_STRING_ENCODING_CODEPAGE_437], "T\x82st str\x8Cng \xB0\xB1\xB2"))

	EXPECT_EXCEPTION(@"Conversion of Unicode to Codepage 437 #2",
	    OFInvalidEncodingException, [C(@"T€st strîng ░▒▓")
	    cStringWithEncoding: OF_STRING_ENCODING_CODEPAGE_437])
#endif

	TEST(@"Lossy conversion of Unicode to ASCII",
	    !strcmp([C(@"This is a tést") lossyCStringWithEncoding:
	    OF_STRING_ENCODING_ASCII], "This is a t?st"))

	TEST(@"Lossy conversion of Unicode to ISO-8859-1",
	    !strcmp([C(@"This is ä t€st") lossyCStringWithEncoding:
	    OF_STRING_ENCODING_ISO_8859_1], "This is \xE4 t?st"))

#ifdef HAVE_ISO_8859_15
	TEST(@"Lossy conversion of Unicode to ISO-8859-15",
	    !strcmp([C(@"This is ä t€st…") lossyCStringWithEncoding:
	    OF_STRING_ENCODING_ISO_8859_15], "This is \xE4 t\xA4st?"))
#endif

#ifdef HAVE_WINDOWS_1252
	TEST(@"Lossy conversion of Unicode to Windows-1252",
	    !strcmp([C(@"This is ä t€st…‼") lossyCStringWithEncoding:
	    OF_STRING_ENCODING_WINDOWS_1252], "This is \xE4 t\x80st\x85?"))
#endif

#ifdef HAVE_CODEPAGE_437
	TEST(@"Lossy conversion of Unicode to Codepage 437",
	    !strcmp([C(@"T€st strîng ░▒▓") lossyCStringWithEncoding:
	    OF_STRING_ENCODING_CODEPAGE_437], "T?st str\x8Cng \xB0\xB1\xB2"))
#endif

	TEST(@"+[stringWithFormat:]",
	    [(s[0] = [mutableStringClass stringWithFormat: @"%@:%d", @"test",
							   123])
	    isEqual: @"test:123"])

	TEST(@"-[appendFormat:]",
	    R(([s[0] appendFormat: @"%02X", 15])) &&
	    [s[0] isEqual: @"test:1230F"])

	TEST(@"-[rangeOfString:]",
	    [C(@"𝄞öö") rangeOfString: @"öö"].location == 1 &&
	    [C(@"𝄞öö") rangeOfString: @"ö"].location == 1 &&
	    [C(@"𝄞öö") rangeOfString: @"𝄞"].location == 0 &&
	    [C(@"𝄞öö") rangeOfString: @"x"].location == OF_NOT_FOUND &&
	    [C(@"𝄞öö") rangeOfString: @"öö"
	    options: OF_STRING_SEARCH_BACKWARDS].location == 1 &&
	    [C(@"𝄞öö") rangeOfString: @"ö"
	    options: OF_STRING_SEARCH_BACKWARDS].location == 2 &&
	    [C(@"𝄞öö") rangeOfString: @"𝄞"
	    options: OF_STRING_SEARCH_BACKWARDS].location == 0 &&
	    [C(@"𝄞öö") rangeOfString: @"x"
	    options: OF_STRING_SEARCH_BACKWARDS].location == OF_NOT_FOUND)

	EXPECT_EXCEPTION(
	    @"Detect out of range in -[rangeOfString:options:range:]",
	    OFOutOfRangeException,
	    [C(@"𝄞öö") rangeOfString: @"ö"
			     options: 0
			       range: of_range(3, 1)])

	cs = [OFCharacterSet characterSetWithCharactersInString: @"cđ"];
	TEST(@"-[indexOfCharacterFromSet:]",
	     [C(@"abcđabcđe") indexOfCharacterFromSet: cs] == 2 &&
	     [C(@"abcđabcđë")
	     indexOfCharacterFromSet: cs
			     options: OF_STRING_SEARCH_BACKWARDS] == 7 &&
	     [C(@"abcđabcđë")
	     indexOfCharacterFromSet: cs
			     options: 0
			       range: of_range(4, 4)] == 6 &&
	     [C(@"abcđabcđëf")
	     indexOfCharacterFromSet: cs
			     options: 0
			       range: of_range(8, 2)] == OF_NOT_FOUND)

	EXPECT_EXCEPTION(
	    @"Detect out of range in -[indexOfCharacterFromSet:options:range:]",
	    OFOutOfRangeException,
	    [C(@"𝄞öö") indexOfCharacterFromSet: cs
				       options: 0
					 range: of_range(3, 1)])

	TEST(@"-[substringWithRange:]",
	    [[C(@"𝄞öö") substringWithRange: of_range(1, 1)] isEqual: @"ö"] &&
	    [[C(@"𝄞öö") substringWithRange: of_range(3, 0)] isEqual: @""])

	EXPECT_EXCEPTION(@"Detect out of range in -[substringWithRange:] #1",
	    OFOutOfRangeException,
	    [C(@"𝄞öö") substringWithRange: of_range(2, 2)])
	EXPECT_EXCEPTION(@"Detect out of range in -[substringWithRange:] #2",
	    OFOutOfRangeException,
	    [C(@"𝄞öö") substringWithRange: of_range(4, 0)])

	TEST(@"-[stringByAppendingString:]",
	    [[C(@"foo") stringByAppendingString: @"bar"] isEqual: @"foobar"])

	TEST(@"-[stringByPrependingString:]",
	    [[C(@"foo") stringByPrependingString: @"bar"] isEqual: @"barfoo"])

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
# elif defined(OF_NINTENDO_3DS) || defined(OF_WII)
	TEST(@"-[isAbsolutePath]",
	    C(@"sdmc:/foo").absolutePath && !C(@"sdmc:foo").absolutePath &&
	    !C(@"foo/bar").absolutePath && !C(@"foo").absolutePath)
# else
	TEST(@"-[isAbsolutePath]",
	    C(@"/foo").absolutePath && C(@"/foo/bar").absolutePath &&
	    !C(@"foo/bar").absolutePath && !C(@"foo").absolutePath)
# endif

	s[0] = [mutableStringClass stringWithString: @"foo"];
# if defined(OF_WINDOWS) || defined(OF_MSDOS)
	[s[0] appendString: @"\\"];
# else
	[s[0] appendString: @"/"];
# endif
	[s[0] appendString: @"bar"];
	s[1] = [mutableStringClass stringWithString: s[0]];
# if defined(OF_WINDOWS) || defined(OF_MSDOS)
	[s[1] appendString: @"\\"];
# else
	[s[1] appendString: @"/"];
# endif
	is = [stringClass stringWithString: s[1]];
	[s[1] appendString: @"baz"];
	TEST(@"-[stringByAppendingPathComponent:]",
	    [[s[0] stringByAppendingPathComponent: @"baz"] isEqual: s[1]] &&
	    [[is stringByAppendingPathComponent: @"baz"] isEqual: s[1]])
#endif

	TEST(@"-[hasPrefix:]", [C(@"foobar") hasPrefix: @"foo"] &&
	    ![C(@"foobar") hasPrefix: @"foobar0"])

	TEST(@"-[hasSuffix:]", [C(@"foobar") hasSuffix: @"bar"] &&
	    ![C(@"foobar") hasSuffix: @"foobar0"])

	i = 0;
	TEST(@"-[componentsSeparatedByString:]",
	    (a = [C(@"fooXXbarXXXXbazXXXX")
	    componentsSeparatedByString: @"XX"]) &&
	    [[a objectAtIndex: i++] isEqual: @"foo"] &&
	    [[a objectAtIndex: i++] isEqual: @"bar"] &&
	    [[a objectAtIndex: i++] isEqual: @""] &&
	    [[a objectAtIndex: i++] isEqual: @"baz"] &&
	    [[a objectAtIndex: i++] isEqual: @""] &&
	    [[a objectAtIndex: i++] isEqual: @""] &&
	    a.count == i)

	i = 0;
	TEST(@"-[componentsSeparatedByString:options:]",
	    (a = [C(@"fooXXbarXXXXbazXXXX")
	    componentsSeparatedByString: @"XX"
				options: OF_STRING_SKIP_EMPTY]) &&
	    [[a objectAtIndex: i++] isEqual: @"foo"] &&
	    [[a objectAtIndex: i++] isEqual: @"bar"] &&
	    [[a objectAtIndex: i++] isEqual: @"baz"] &&
	    a.count == i)

	cs = [OFCharacterSet characterSetWithCharactersInString: @"XYZ"];

	i = 0;
	TEST(@"-[componentsSeparatedByCharactersInSet:]",
	    (a = [C(@"fooXYbarXYZXbazXYXZx")
	    componentsSeparatedByCharactersInSet: cs]) &&
	    [[a objectAtIndex: i++] isEqual: @"foo"] &&
	    [[a objectAtIndex: i++] isEqual: @""] &&
	    [[a objectAtIndex: i++] isEqual: @"bar"] &&
	    [[a objectAtIndex: i++] isEqual: @""] &&
	    [[a objectAtIndex: i++] isEqual: @""] &&
	    [[a objectAtIndex: i++] isEqual: @""] &&
	    [[a objectAtIndex: i++] isEqual: @"baz"] &&
	    [[a objectAtIndex: i++] isEqual: @""] &&
	    [[a objectAtIndex: i++] isEqual: @""] &&
	    [[a objectAtIndex: i++] isEqual: @""] &&
	    [[a objectAtIndex: i++] isEqual: @"x"] &&
	    a.count == i)

	i = 0;
	TEST(@"-[componentsSeparatedByCharactersInSet:options:]",
	    (a = [C(@"fooXYbarXYZXbazXYXZ")
	    componentsSeparatedByCharactersInSet: cs
					 options: OF_STRING_SKIP_EMPTY]) &&
	    [[a objectAtIndex: i++] isEqual: @"foo"] &&
	    [[a objectAtIndex: i++] isEqual: @"bar"] &&
	    [[a objectAtIndex: i++] isEqual: @"baz"] &&
	    a.count == i)

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
# elif defined(OF_NINTENDO_3DS) || defined(OF_WII)
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
	    (a = C(@"c:/tmp").pathComponents) && a.count == 2 &&
	    [[a objectAtIndex: 0] isEqual: @"c:/"] &&
	    [[a objectAtIndex: 1] isEqual: @"tmp"] &&
	    /* c:\tmp\ */
	    (a = C(@"c:\\tmp\\").pathComponents) && a.count == 2 &&
	    [[a objectAtIndex: 0] isEqual: @"c:\\"] &&
	    [[a objectAtIndex: 1] isEqual: @"tmp"] &&
	    /* c:\ */
	    (a = C(@"c:\\").pathComponents) && a.count == 1 &&
	    [[a objectAtIndex: 0] isEqual: @"c:\\"] &&
	    /* c:/ */
	    (a = C(@"c:/").pathComponents) && a.count == 1 &&
	    [[a objectAtIndex: 0] isEqual: @"c:/"] &&
	    /* c: */
	    (a = C(@"c:").pathComponents) && a.count == 1 &&
	    [[a objectAtIndex: 0] isEqual: @"c:"] &&
	    /* foo\bar */
	    (a = C(@"foo\\bar").pathComponents) && a.count == 2 &&
	    [[a objectAtIndex: 0] isEqual: @"foo"] &&
	    [[a objectAtIndex: 1] isEqual: @"bar"] &&
	    /* foo\bar/baz/ */
	    (a = C(@"foo\\bar/baz/").pathComponents) && a.count == 3 &&
	    [[a objectAtIndex: 0] isEqual: @"foo"] &&
	    [[a objectAtIndex: 1] isEqual: @"bar"] &&
	    [[a objectAtIndex: 2] isEqual: @"baz"] &&
	    /* foo\/ */
	    (a = C(@"foo\\/").pathComponents) && a.count == 1 &&
	    [[a objectAtIndex: 0] isEqual: @"foo"] &&
	    /* \\foo\bar */
	    (a = C(@"\\\\foo\\bar").pathComponents) && a.count == 3 &&
	    [[a objectAtIndex: 0] isEqual: @"\\\\"] &&
	    [[a objectAtIndex: 1] isEqual: @"foo"] &&
	    [[a objectAtIndex: 2] isEqual: @"bar"] &&
	    C(@"").pathComponents.count == 0)
# elif defined(OF_MSDOS)
	TEST(@"-[pathComponents]",
	    /* c:/tmp */
	    (a = C(@"c:/tmp").pathComponents) && a.count == 2 &&
	    [[a objectAtIndex: 0] isEqual: @"c:/"] &&
	    [[a objectAtIndex: 1] isEqual: @"tmp"] &&
	    /* c:\tmp\ */
	    (a = C(@"c:\\tmp\\").pathComponents) && a.count == 2 &&
	    [[a objectAtIndex: 0] isEqual: @"c:\\"] &&
	    [[a objectAtIndex: 1] isEqual: @"tmp"] &&
	    /* c:\ */
	    (a = C(@"c:\\").pathComponents) && a.count == 1 &&
	    [[a objectAtIndex: 0] isEqual: @"c:\\"] &&
	    /* c:/ */
	    (a = C(@"c:/").pathComponents) && a.count == 1 &&
	    [[a objectAtIndex: 0] isEqual: @"c:/"] &&
	    /* c: */
	    (a = C(@"c:").pathComponents) && a.count == 1 &&
	    [[a objectAtIndex: 0] isEqual: @"c:"] &&
	    /* foo\bar */
	    (a = C(@"foo\\bar").pathComponents) && a.count == 2 &&
	    [[a objectAtIndex: 0] isEqual: @"foo"] &&
	    [[a objectAtIndex: 1] isEqual: @"bar"] &&
	    /* foo\bar/baz/ */
	    (a = C(@"foo\\bar/baz/").pathComponents) && a.count == 3 &&
	    [[a objectAtIndex: 0] isEqual: @"foo"] &&
	    [[a objectAtIndex: 1] isEqual: @"bar"] &&
	    [[a objectAtIndex: 2] isEqual: @"baz"] &&
	    /* foo\/ */
	    (a = C(@"foo\\/").pathComponents) && a.count == 1 &&
	    [[a objectAtIndex: 0] isEqual: @"foo"] &&
	    C(@"").pathComponents.count == 0)
# elif defined(OF_AMIGAOS)
	TEST(@"-[pathComponents]",
	    /* dh0:tmp */
	    (a = C(@"dh0:tmp").pathComponents) && a.count == 2 &&
	    [[a objectAtIndex: 0] isEqual: @"dh0:"] &&
	    [[a objectAtIndex: 1] isEqual: @"tmp"] &&
	    /* dh0:tmp/ */
	    (a = C(@"dh0:tmp/").pathComponents) && a.count == 2 &&
	    [[a objectAtIndex: 0] isEqual: @"dh0:"] &&
	    [[a objectAtIndex: 1] isEqual: @"tmp"] &&
	    /* dh0: */
	    (a = C(@"dh0:/").pathComponents) && a.count == 2 &&
	    [[a objectAtIndex: 0] isEqual: @"dh0:"] &&
	    [[a objectAtIndex: 1] isEqual: @"/"] &&
	    /* foo/bar */
	    (a = C(@"foo/bar").pathComponents) && a.count == 2 &&
	    [[a objectAtIndex: 0] isEqual: @"foo"] &&
	    [[a objectAtIndex: 1] isEqual: @"bar"] &&
	    /* foo/bar/baz/ */
	    (a = C(@"foo/bar/baz/").pathComponents) && a.count == 3 &&
	    [[a objectAtIndex: 0] isEqual: @"foo"] &&
	    [[a objectAtIndex: 1] isEqual: @"bar"] &&
	    [[a objectAtIndex: 2] isEqual: @"baz"] &&
	    /* foo// */
	    (a = C(@"foo//").pathComponents) && a.count == 2 &&
	    [[a objectAtIndex: 0] isEqual: @"foo"] &&
	    [[a objectAtIndex: 1] isEqual: @"/"] &&
	    C(@"").pathComponents.count == 0)
# elif defined(OF_NINTENDO_3DS) || defined(OF_WII)
	TEST(@"-[pathComponents]",
	    /* sdmc:/tmp */
	    (a = C(@"sdmc:/tmp").pathComponents) && a.count == 2 &&
	    [[a objectAtIndex: 0] isEqual: @"sdmc:"] &&
	    [[a objectAtIndex: 1] isEqual: @"tmp"] &&
	    /* sdmc:/ */
	    (a = C(@"sdmc:/").pathComponents) && a.count == 1 &&
	    [[a objectAtIndex: 0] isEqual: @"sdmc:"] &&
	    /* foo/bar */
	    (a = C(@"foo/bar").pathComponents) && a.count == 2 &&
	    [[a objectAtIndex: 0] isEqual: @"foo"] &&
	    [[a objectAtIndex: 1] isEqual: @"bar"] &&
	    /* foo/bar/baz/ */
	    (a = C(@"foo/bar/baz/").pathComponents) && a.count == 3 &&
	    [[a objectAtIndex: 0] isEqual: @"foo"] &&
	    [[a objectAtIndex: 1] isEqual: @"bar"] &&
	    [[a objectAtIndex: 2] isEqual: @"baz"] &&
	    /* foo// */
	    (a = C(@"foo//").pathComponents) && a.count == 1 &&
	    [[a objectAtIndex: 0] isEqual: @"foo"] &&
	    C(@"").pathComponents.count == 0)
# else
	TEST(@"-[pathComponents]",
	    /* /tmp */
	    (a = C(@"/tmp").pathComponents) && a.count == 2 &&
	    [[a objectAtIndex: 0] isEqual: @"/"] &&
	    [[a objectAtIndex: 1] isEqual: @"tmp"] &&
	    /* /tmp/ */
	    (a = C(@"/tmp/").pathComponents) && a.count == 2 &&
	    [[a objectAtIndex: 0] isEqual: @"/"] &&
	    [[a objectAtIndex: 1] isEqual: @"tmp"] &&
	    /* / */
	    (a = C(@"/").pathComponents) && a.count == 1 &&
	    [[a objectAtIndex: 0] isEqual: @"/"] &&
	    /* foo/bar */
	    (a = C(@"foo/bar").pathComponents) && a.count == 2 &&
	    [[a objectAtIndex: 0] isEqual: @"foo"] &&
	    [[a objectAtIndex: 1] isEqual: @"bar"] &&
	    /* foo/bar/baz/ */
	    (a = C(@"foo/bar/baz/").pathComponents) && a.count == 3 &&
	    [[a objectAtIndex: 0] isEqual: @"foo"] &&
	    [[a objectAtIndex: 1] isEqual: @"bar"] &&
	    [[a objectAtIndex: 2] isEqual: @"baz"] &&
	    /* foo// */
	    (a = C(@"foo//").pathComponents) && a.count == 1 &&
	    [[a objectAtIndex: 0] isEqual: @"foo"] &&
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
# elif defined(OF_NINTENDO_3DS) || defined(OF_WII)
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
# elif defined(OF_NINTENDO_3DS) || defined(OF_WII)
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
# elif defined(OF_NINTENDO_3DS) || defined(OF_WII)
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

	TEST(@"-[decimalValue]",
	    C(@"1234").decimalValue == 1234 &&
	    C(@"\r\n+123  ").decimalValue == 123 &&
	    C(@"-500\t").decimalValue == -500 &&
	    C(@"\t\t\r\n").decimalValue == 0)

	TEST(@"-[hexadecimalValue]",
	    C(@"123f").hexadecimalValue == 0x123f &&
	    C(@"\t\n0xABcd\r").hexadecimalValue == 0xABCD &&
	    C(@"  xbCDE").hexadecimalValue == 0xBCDE &&
	    C(@"$CdEf").hexadecimalValue == 0xCDEF &&
	    C(@"\rFeh ").hexadecimalValue == 0xFE &&
	    C(@"\r\t").hexadecimalValue == 0)

	TEST(@"-[octalValue]",
	    C(@"1234567").octalValue == 01234567 &&
	    C(@"\r\n123").octalValue == 0123 &&
	    C(@"765\t").octalValue == 0765 && C(@"\t\t\r\n").octalValue == 0)

	/*
	 * These test numbers can be generated without rounding if we have IEEE
	 * floating point numbers, thus we can use == on them.
	 */
	TEST(@"-[floatValue]",
	    C(@"\t-0.25 ").floatValue == -0.25 &&
	    C(@"\r\n\tINF\t\n").floatValue == INFINITY &&
	    C(@"\r -INFINITY\n").floatValue == -INFINITY &&
	    isnan(C(@"   NAN\t\t").floatValue))

#if !defined(OF_ANDROID) && !defined(OF_SOLARIS) && !defined(OF_DJGPP) && \
    !defined(OF_AMIGAOS_M68K)
# define INPUT @"\t-0x1.FFFFFFFFFFFFFP-1020 "
# define EXPECTED -0x1.FFFFFFFFFFFFFP-1020
#else
/* Android, Solaris, DJGPP and AmigaOS3 do not accept 0x for strtod() */
# if (!defined(OF_SOLARIS) || !defined(OF_X86)) && !defined(OF_AMIGAOS_M68K)
#  define INPUT @"\t-0.123456789 "
#  define EXPECTED -0.123456789
# else
/*
 * Solaris' strtod() has weird rounding on x86, but not on x86_64/
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

	EXPECT_EXCEPTION(@"Detect invalid characters in -[decimalValue] #1",
	    OFInvalidFormatException, [C(@"abc") decimalValue])
	EXPECT_EXCEPTION(@"Detect invalid characters in -[decimalValue] #2",
	    OFInvalidFormatException, [C(@"0a") decimalValue])
	EXPECT_EXCEPTION(@"Detect invalid characters in -[decimalValue] #3",
	    OFInvalidFormatException, [C(@"0 1") decimalValue])

	EXPECT_EXCEPTION(@"Detect invalid chars in -[hexadecimalValue] #1",
	    OFInvalidFormatException, [C(@"0xABCDEFG") hexadecimalValue])
	EXPECT_EXCEPTION(@"Detect invalid chars in -[hexadecimalValue] #2",
	    OFInvalidFormatException, [C(@"0x") hexadecimalValue])
	EXPECT_EXCEPTION(@"Detect invalid chars in -[hexadecimalValue] #3",
	    OFInvalidFormatException, [C(@"$") hexadecimalValue])
	EXPECT_EXCEPTION(@"Detect invalid chars in -[hexadecimalValue] #4",
	    OFInvalidFormatException, [C(@"$ ") hexadecimalValue])

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

	EXPECT_EXCEPTION(@"Detect out of range in -[decimalValue]",
	    OFOutOfRangeException,
	    [C(@"12345678901234567890123456789012345678901234567890"
	       @"12345678901234567890123456789012345678901234567890")
	    decimalValue])

	EXPECT_EXCEPTION(@"Detect out of range in -[hexadecimalValue]",
	    OFOutOfRangeException,
	    [C(@"0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF"
	       @"0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF")
	    hexadecimalValue])

	TEST(@"-[characters]", (ua = C(@"fööbär🀺").characters) &&
	    !memcmp(ua, ucstr + 1, sizeof(ucstr) - 8))

#ifdef OF_BIG_ENDIAN
# define SWAPPED_BYTE_ORDER OF_BYTE_ORDER_LITTLE_ENDIAN
#else
# define SWAPPED_BYTE_ORDER OF_BYTE_ORDER_BIG_ENDIAN
#endif
	TEST(@"-[UTF16String]", (u16a = C(@"fööbär🀺").UTF16String) &&
	    !memcmp(u16a, utf16str + 1, of_string_utf16_length(utf16str) * 2) &&
	    (u16a = [C(@"fööbär🀺")
	    UTF16StringWithByteOrder: SWAPPED_BYTE_ORDER]) &&
	    !memcmp(u16a, sutf16str + 1, of_string_utf16_length(sutf16str) * 2))

	TEST(@"-[UTF16StringLength]", C(@"fööbär🀺").UTF16StringLength == 8)

	TEST(@"-[UTF32String]", (ua = C(@"fööbär🀺").UTF32String) &&
	    !memcmp(ua, ucstr + 1, of_string_utf32_length(ucstr) * 4) &&
	    (ua = [C(@"fööbär🀺") UTF32StringWithByteOrder:
	    SWAPPED_BYTE_ORDER]) &&
	    !memcmp(ua, sucstr + 1, of_string_utf32_length(sucstr) * 4))
#undef SWAPPED_BYTE_ORDER

	TEST(@"-[MD5Hash]", [C(@"asdfoobar").MD5Hash
	    isEqual: @"184dce2ec49b5422c7cfd8728864db4c"])

	TEST(@"-[RIPEMD160Hash]", [C(@"asdfoobar").RIPEMD160Hash
	    isEqual: @"021d773b0fac06eb6755ca6aa58a580c980f7f13"])

	TEST(@"-[SHA1Hash]", [C(@"asdfoobar").SHA1Hash
	    isEqual: @"f5f81ac0a8b5cbfdc4585ec1ad32e7b3a12b9b49"])

	TEST(@"-[SHA224Hash]", [C(@"asdfoobar").SHA224Hash
	    isEqual:
	    @"5a06822dcbd5a874f67d062b80b9d8a9cb9b5b303960b9da9290c192"])

	TEST(@"-[SHA256Hash]", [C(@"asdfoobar").SHA256Hash isEqual:
	    @"28e65b1dcd7f6ce2ea6277b15f87b913"
	    @"628b5500bf7913a2bbf4cedcfa1215f6"])

	TEST(@"-[SHA384Hash]", [C(@"asdfoobar").SHA384Hash isEqual:
	    @"73286da882ffddca2f45e005cfa6b44f3fc65bfb26db1d08"
	    @"7ded2f9c279e5addf8be854044bca0cece073fce28eec7d9"])

	TEST(@"-[SHA512Hash]", [C(@"asdfoobar").SHA512Hash isEqual:
	    @"0464c427da158b02161bb44a3090bbfc594611ef6a53603640454b56412a9247c"
	    @"3579a329e53a5dc74676b106755e3394f9454a2d42273242615d32f80437d61"])

	cs = [OFCharacterSet characterSetWithCharactersInString: @"abfo'_~$🍏"];
	TEST(@"-[stringByURLEncodingWithAllowedCharacters:]",
	    [[C(@"foo\"ba'_~$]🍏🍌") stringByURLEncodingWithAllowedCharacters:
	    cs] isEqual: @"foo%22ba'_~$%5D🍏%F0%9F%8D%8C"])

	TEST(@"-[stringByURLDecoding]",
	    [C(@"foo%20bar%22+%24%F0%9F%8D%8C").stringByURLDecoding
	    isEqual: @"foo bar\"+$🍌"])

	TEST(@"-[insertString:atIndex:]",
	    (s[0] = [mutableStringClass stringWithString: @"𝄞öööbä€"]) &&
	    R([s[0] insertString: @"äöü"
			 atIndex: 3]) &&
	    [s[0] isEqual: @"𝄞ööäöüöbä€"])

	EXPECT_EXCEPTION(@"Detect invalid format in -[stringByURLDecoding] "
	    @"#1", OFInvalidFormatException,
	    [C(@"foo%xbar") stringByURLDecoding])
	EXPECT_EXCEPTION(@"Detect invalid encoding in -[stringByURLDecoding] "
	    @"#2", OFInvalidEncodingException,
	    [C(@"foo%FFbar") stringByURLDecoding])

	TEST(@"-[setCharacter:atIndex:]",
	    (s[0] = [mutableStringClass stringWithString: @"abäde"]) &&
	    R([s[0] setCharacter: 0xF6
			 atIndex: 2]) &&
	    [s[0] isEqual: @"aböde"] &&
	    R([s[0] setCharacter: 'c'
			 atIndex: 2]) &&
	    [s[0] isEqual: @"abcde"] &&
	    R([s[0] setCharacter: 0x20AC
			 atIndex: 3]) &&
	    [s[0] isEqual: @"abc€e"] &&
	    R([s[0] setCharacter: 'x'
			 atIndex: 1]) &&
	    [s[0] isEqual: @"axc€e"])

	TEST(@"-[deleteCharactersInRange:]",
	    (s[0] = [mutableStringClass stringWithString: @"𝄞öööbä€"]) &&
	    R([s[0] deleteCharactersInRange: of_range(1, 3)]) &&
	    [s[0] isEqual: @"𝄞bä€"] &&
	    R([s[0] deleteCharactersInRange: of_range(0, 4)]) &&
	    [s[0] isEqual: @""])

	TEST(@"-[replaceCharactersInRange:withString:]",
	    (s[0] = [mutableStringClass stringWithString: @"𝄞öööbä€"]) &&
	    R([s[0] replaceCharactersInRange: of_range(1, 3)
				  withString: @"äöüß"]) &&
	    [s[0] isEqual: @"𝄞äöüßbä€"] &&
	    R([s[0] replaceCharactersInRange: of_range(4, 2)
				  withString: @"b"]) &&
	    [s[0] isEqual: @"𝄞äöübä€"] &&
	    R([s[0] replaceCharactersInRange: of_range(0, 7)
				  withString: @""]) &&
	    [s[0] isEqual: @""])

	EXPECT_EXCEPTION(@"Detect OoR in -[deleteCharactersInRange:] #1",
	    OFOutOfRangeException,
	    {
		s[0] = [mutableStringClass stringWithString: @"𝄞öö"];
		[s[0] deleteCharactersInRange: of_range(2, 2)];
	    })

	EXPECT_EXCEPTION(@"Detect OoR in -[deleteCharactersInRange:] #2",
	    OFOutOfRangeException,
	    [s[0] deleteCharactersInRange: of_range(4, 0)])

	EXPECT_EXCEPTION(@"Detect OoR in "
	    @"-[replaceCharactersInRange:withString:] #1",
	    OFOutOfRangeException,
	    [s[0] replaceCharactersInRange: of_range(2, 2)
				withString: @""])

	EXPECT_EXCEPTION(@"Detect OoR in "
	    @"-[replaceCharactersInRange:withString:] #2",
	    OFOutOfRangeException,
	    [s[0] replaceCharactersInRange: of_range(4, 0)
				withString: @""])

	TEST(@"-[replaceOccurrencesOfString:withString:]",
	    (s[0] = [mutableStringClass stringWithString:
	    @"asd fo asd fofo asd"]) &&
	    R([s[0] replaceOccurrencesOfString: @"fo"
				    withString: @"foo"]) &&
	    [s[0] isEqual: @"asd foo asd foofoo asd"] &&
	    (s[0] = [mutableStringClass stringWithString: @"XX"]) &&
	    R([s[0] replaceOccurrencesOfString: @"X"
				    withString: @"XX"]) &&
	    [s[0] isEqual: @"XXXX"])

	TEST(@"-[replaceOccurrencesOfString:withString:options:range:]",
	    (s[0] = [mutableStringClass stringWithString:
	    @"foofoobarfoobarfoo"]) &&
	    R([s[0] replaceOccurrencesOfString: @"oo"
				    withString: @"óò"
				       options: 0
					 range: of_range(2, 15)]) &&
	    [s[0] isEqual: @"foofóòbarfóòbarfoo"])

	TEST(@"-[deleteLeadingWhitespaces]",
	    (s[0] = [mutableStringClass stringWithString: whitespace[0]]) &&
	    R([s[0] deleteLeadingWhitespaces]) &&
	    [s[0] isEqual: @"asd  \t \t\t\r\n"] &&
	    (s[0] = [mutableStringClass stringWithString: whitespace[1]]) &&
	    R([s[0] deleteLeadingWhitespaces]) && [s[0] isEqual: @""])

	TEST(@"-[deleteTrailingWhitespaces]",
	    (s[0] = [mutableStringClass stringWithString: whitespace[0]]) &&
	    R([s[0] deleteTrailingWhitespaces]) &&
	    [s[0] isEqual: @" \r \t\n\t \tasd"] &&
	    (s[0] = [mutableStringClass stringWithString: whitespace[1]]) &&
	    R([s[0] deleteTrailingWhitespaces]) && [s[0] isEqual: @""])

	TEST(@"-[deleteEnclosingWhitespaces]",
	    (s[0] = [mutableStringClass stringWithString: whitespace[0]]) &&
	    R([s[0] deleteEnclosingWhitespaces]) && [s[0] isEqual: @"asd"] &&
	    (s[0] = [mutableStringClass stringWithString: whitespace[1]]) &&
	    R([s[0] deleteEnclosingWhitespaces]) && [s[0] isEqual: @""])

#ifdef OF_HAVE_UNICODE_TABLES
	TEST(@"-[decomposedStringWithCanonicalMapping]",
	    [C(@"H\xC3\xA4lǉ\xC3\xB6").decomposedStringWithCanonicalMapping
	    isEqual: @"H\x61\xCC\x88lǉ\x6F\xCC\x88"]);

	TEST(@"-[decomposedStringWithCompatibilityMapping]",
	    [C(@"H\xC3\xA4lǉ\xC3\xB6").decomposedStringWithCompatibilityMapping
	    isEqual: @"H\x61\xCC\x88llj\x6F\xCC\x88"]);
#endif

	TEST(@"-[stringByXMLEscaping]",
	    (is = C(@"<hello> &world'\"!&").stringByXMLEscaping) &&
	    [is isEqual: @"&lt;hello&gt; &amp;world&apos;&quot;!&amp;"])

	TEST(@"-[stringByXMLUnescaping]",
	    [is.stringByXMLUnescaping isEqual: @"<hello> &world'\"!&"] &&
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
	    (h = [[[EntityHandler alloc] init] autorelease]) &&
	    [[C(@"x&foo;y") stringByXMLUnescapingWithDelegate: h]
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

	[pool drain];
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
