/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#import "OFString.h"
#import "OFArray.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"

#import "main.h"

static OFString *module = @"OFString";
static OFString* whitespace[] = {
	@" \r \t\n\t \tasd  \t \t\t\r\n",
	@" \t\t  \t\t  \t \t"
};

@interface EntityHandler: OFObject <OFXMLUnescapingDelegate>
@end

@implementation EntityHandler
- (OFString*)foundUnknownEntityNamed: (OFString*)entity
{
	if ([entity isEqual: @"foo"])
		return @"bar";

	return nil;
}
@end

void
string_tests()
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFString *s[3];
	OFArray *a;
	int i;
	EntityHandler *h;

	s[0] = [OFMutableString stringWithString: @"täs€"];
	s[1] = [OFMutableString string];
	s[2] = [[s[0] copy] autorelease];

	TEST(@"-[isEqual:]", [s[0] isEqual: s[2]] &&
	    ![s[0] isEqual: [[[OFObject alloc] init] autorelease]])

	TEST(@"-[compare:]", [s[0] compare: s[2]] == OF_ORDERED_SAME &&
	    [s[0] compare: @""] != OF_ORDERED_SAME &&
	    [@"" compare: @"a"] == OF_ORDERED_ASCENDING &&
	    [@"a" compare: @"b"] == OF_ORDERED_ASCENDING &&
	    [@"cd" compare: @"bc"] == OF_ORDERED_DESCENDING &&
	    [@"ä" compare: @"ö"] == OF_ORDERED_ASCENDING &&
	    [@"€" compare: @"ß"] == OF_ORDERED_DESCENDING &&
	    [@"aa" compare: @"z"] == OF_ORDERED_ASCENDING)

	TEST(@"-[caseInsensitiveCompare:]",
	    [@"a" caseInsensitiveCompare: @"A"] == OF_ORDERED_SAME &&
	    [@"Ä" caseInsensitiveCompare: @"ä"] == OF_ORDERED_SAME &&
	    [@"я" caseInsensitiveCompare: @"Я"] == OF_ORDERED_SAME &&
	    [@"€" caseInsensitiveCompare: @"ß"] == OF_ORDERED_DESCENDING &&
	    [@"ß" caseInsensitiveCompare: @"→"] == OF_ORDERED_ASCENDING &&
	    [@"AA" caseInsensitiveCompare: @"z"] == OF_ORDERED_ASCENDING)

	TEST(@"-[hash] is the same if -[isEqual:] is YES",
	    [s[0] hash] == [s[2] hash])

	TEST(@"-[appendString:] and -[appendCString:]",
	    [s[1] appendCString: "1𝄞"] && [s[1] appendString: @"3"] &&
	    [[s[0] appendString: s[1]] isEqual: @"täs€1𝄞3"])

	TEST(@"-[length]", [s[0] length] == 7)
	TEST(@"-[cStringLength]", [s[0] cStringLength] == 13)
	TEST(@"-[hash]", [s[0] hash] == 0x8AC1EEF6)

	TEST(@"-[characterAtIndex:]", [s[0] characterAtIndex: 0] == 't' &&
	    [s[0] characterAtIndex: 1] == 0xE4 &&
	    [s[0] characterAtIndex: 3] == 0x20AC &&
	    [s[0] characterAtIndex: 5] == 0x1D11E)

	EXPECT_EXCEPTION(@"Detect out of range in -[characterAtIndex:]",
	    OFOutOfRangeException, [s[0] characterAtIndex: 7])

	TEST(@"-[reverse]", [[s[0] reverse] isEqual: @"3𝄞1€sät"])

	s[1] = [OFMutableString stringWithString: @"abc"];

	TEST(@"-[upper]", [[s[0] upper] isEqual: @"3𝄞1€SÄT"] &&
	    [[s[1] upper] isEqual: @"ABC"])

	TEST(@"-[lower]", [[s[0] lower] isEqual: @"3𝄞1€sät"] &&
	    [[s[1] lower] isEqual: @"abc"])

	TEST(@"+[stringWithCString:length:]",
	    (s[0] = [OFMutableString stringWithCString: "foobar"
					      length: 3]) &&
	    [s[0] isEqual: @"foo"])

	TEST(@"-[appendCStringWithLength:]",
	    [[s[0] appendCString: "foobarqux" + 3
		      withLength: 3] isEqual: @"foobar"])

	EXPECT_EXCEPTION(@"Detection of invalid UTF-8 encoding #1",
	    OFInvalidEncodingException,
	    [OFString stringWithCString: "\xE0\x80"])
	EXPECT_EXCEPTION(@"Detection of invalid UTF-8 encoding #2",
	    OFInvalidEncodingException,
	    [OFString stringWithCString: "\xF0\x80\x80\xC0"])

	TEST(@"-[reverse] on UTF-8 strings",
	    (s[0] = [[OFMutableString stringWithCString: "äöü€𝄞"] reverse]) &&
	    [s[0] isEqual: @"𝄞€üöä"])

	TEST(@"Conversion of ISO 8859-1 to UTF-8",
	    [[OFString stringWithCString: "\xE4\xF6\xFC"
				encoding: OF_STRING_ENCODING_ISO_8859_1]
	    isEqual: @"äöü"])

	TEST(@"Conversion of ISO 8859-15 to UTF-8",
	    [[OFString stringWithCString: "\xA4\xA6\xA8\xB4\xB8\xBC\xBD\xBE"
				encoding: OF_STRING_ENCODING_ISO_8859_15]
	    isEqual: @"€ŠšŽžŒœŸ"])

	TEST(@"Conversion of Windows 1252 to UTF-8",
	    [[OFString stringWithCString: "\x80\x82\x83\x84\x85\x86\x87\x88"
					  "\x89\x8A\x8B\x8C\x8E\x91\x92\x93"
					  "\x94\x95\x96\x97\x98\x99\x9A\x9B"
					  "\x9C\x9E\x9F"
				encoding: OF_STRING_ENCODING_WINDOWS_1252]
	    isEqual: @"€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ"])

	TEST(@"+[stringWithFormat:]",
	    [(s[0] = [OFMutableString stringWithFormat: @"%s: %d", "test", 123])
	    isEqual: @"test: 123"])

	TEST(@"-[appendWithFormat:]",
	    [([s[0] appendWithFormat: @"%02X", 15]) isEqual: @"test: 1230F"])

	TEST(@"-[indexOfFirstOccurrenceOfString:]",
	    [@"𝄞öö" indexOfFirstOccurrenceOfString: @"öö"] == 1 &&
	    [@"𝄞öö" indexOfFirstOccurrenceOfString: @"ö"] == 1 &&
	    [@"𝄞öö" indexOfFirstOccurrenceOfString: @"𝄞"] == 0 &&
	    [@"𝄞öö" indexOfFirstOccurrenceOfString: @"x"] == SIZE_MAX)

	TEST(@"-[indexOfLastOccurrenceOfString:]",
	    [@"𝄞öö" indexOfLastOccurrenceOfString: @"öö"] == 1 &&
	    [@"𝄞öö" indexOfLastOccurrenceOfString: @"ö"] == 2 &&
	    [@"𝄞öö" indexOfLastOccurrenceOfString: @"𝄞"] == 0 &&
	    [@"𝄞öö" indexOfLastOccurrenceOfString: @"x"] == SIZE_MAX)

	TEST(@"-[substringFromIndexToIndex:]",
	    [[@"𝄞öö" substringFromIndex: 1
				toIndex: 2] isEqual: @"ö"] &&
	    [[@"𝄞öö" substringFromIndex: 3
				toIndex: 3] isEqual: @""])

	EXPECT_EXCEPTION(@"Detect out of range in "
	    @"-[substringFromIndex:toIndex:] #1", OFOutOfRangeException,
	    [@"𝄞öö" substringFromIndex: 2
			       toIndex: 4])
	EXPECT_EXCEPTION(@"Detect out of range in "
	    @"-[substringFromIndex:toIndex:] #2", OFOutOfRangeException,
	    [@"𝄞öö" substringFromIndex: 4
			       toIndex: 4])

	EXPECT_EXCEPTION(@"Detect start > end in "
	    @"-[substringFromIndex:toIndex:]", OFInvalidArgumentException,
	    [@"𝄞öö" substringFromIndex: 2
			       toIndex: 0])

	TEST(@"-[stringByAppendingString:]",
	    [[@"foo" stringByAppendingString: @"bar"] isEqual: @"foobar"])

	TEST(@"-[hasPrefix:]", [@"foobar" hasPrefix: @"foo"] &&
	    ![@"foobar" hasPrefix: @"foobar0"])

	TEST(@"-[hasSuffix:]", [@"foobar" hasSuffix: @"bar"] &&
	    ![@"foobar" hasSuffix: @"foobar0"])

	i = 0;
	TEST(@"-[splitWithDelimiter:]",
	    (a = [@"fooXXbarXXXXbazXXXX" splitWithDelimiter: @"XX"]) &&
	    [[a objectAtIndex: i++] isEqual: @"foo"] &&
	    [[a objectAtIndex: i++] isEqual: @"bar"] &&
	    [[a objectAtIndex: i++] isEqual: @""] &&
	    [[a objectAtIndex: i++] isEqual: @"baz"] &&
	    [[a objectAtIndex: i++] isEqual: @""] &&
	    [[a objectAtIndex: i++] isEqual: @""])

	TEST(@"-[decimalValueAsInteger]",
	    [@"1234" decimalValueAsInteger] == 1234 &&
	    [@"-500" decimalValueAsInteger] == -500 &&
	    [@"" decimalValueAsInteger] == 0)

	TEST(@"-[hexadecimalValueAsInteger]",
	    [@"123f" hexadecimalValueAsInteger] == 0x123f &&
	    [@"0xABcd" hexadecimalValueAsInteger] == 0xABCD &&
	    [@"xbCDE" hexadecimalValueAsInteger] == 0xBCDE &&
	    [@"$CdEf" hexadecimalValueAsInteger] == 0xCDEF &&
	    [@"" hexadecimalValueAsInteger] == 0)

	EXPECT_EXCEPTION(@"Detect invalid characters in "
	    @"-[decimalValueAsInteger] #1", OFInvalidEncodingException,
	    [@"abc" decimalValueAsInteger])
	EXPECT_EXCEPTION(@"Detect invalid characters in "
	    @"-[decimalValueAsInteger] #2", OFInvalidEncodingException,
	    [@"0a" decimalValueAsInteger])

	EXPECT_EXCEPTION(@"Detect invalid chars in "
	    @"-[hexadecimalValueAsInteger] #1", OFInvalidEncodingException,
	    [@"0xABCDEFG" hexadecimalValueAsInteger])
	EXPECT_EXCEPTION(@"Detect invalid chars in "
	    @"-[hexadecimalValueAsInteger] #2", OFInvalidEncodingException,
	    [@"0x" hexadecimalValueAsInteger])
	EXPECT_EXCEPTION(@"Detect invalid chars in "
	    @"-[hexadecimalValueAsInteger] #3", OFInvalidEncodingException,
	    [@"$" hexadecimalValueAsInteger])

	EXPECT_EXCEPTION(@"Detect out of range in -[decimalValueAsInteger",
	    OFOutOfRangeException,
	    [@"12345678901234567890123456789012345678901234567890"
	     @"12345678901234567890123456789012345678901234567890"
	    decimalValueAsInteger])

	EXPECT_EXCEPTION(@"Detect out of range in -[hexadecilamValueAsInteger",
	    OFOutOfRangeException,
	    [@"0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF"
	     @"0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF"
	    hexadecimalValueAsInteger])

	TEST(@"-[md5Hash]", [[@"asdfoobar" md5Hash]
	    isEqual: @"184dce2ec49b5422c7cfd8728864db4c"])

	TEST(@"-[sha1Hash]", [[@"asdfoobar" sha1Hash]
	    isEqual: @"f5f81ac0a8b5cbfdc4585ec1ad32e7b3a12b9b49"])

	TEST(@"-[stringByURLEncoding]",
	    [[@"foo\"ba'_~$" stringByURLEncoding] isEqual: @"foo%22ba%27_~%24"])

	TEST(@"-[stringByURLDecoding]",
	    [[@"foo%20bar%22+%24" stringByURLDecoding] isEqual: @"foo bar\" $"])

	EXPECT_EXCEPTION(@"Detect invalid encoding in -[stringByURLDecoding] "
	    @"#1", OFInvalidEncodingException, [@"foo%bar" stringByURLDecoding])
	EXPECT_EXCEPTION(@"Detect invalid encoding in -[stringByURLDecoding] "
	    @"#2", OFInvalidEncodingException,
	    [@"foo%FFbar" stringByURLDecoding])

	TEST(@"-[removeCharactersFromIndex:toIndex:]",
	    (s[0] = [OFMutableString stringWithString: @"𝄞öööbä€"]) &&
	    [s[0] removeCharactersFromIndex: 1
				    toIndex: 4] &&
	    [s[0] isEqual: @"𝄞bä€"] &&
	    [s[0] removeCharactersFromIndex: 0
				    toIndex: 4] &&
	    [s[0] isEqual: @""])

	EXPECT_EXCEPTION(@"Detect OoR in "
	    @"-[removeCharactersFromIndex:toIndex:] #1", OFOutOfRangeException,
	    {
		s[0] = [OFMutableString stringWithString: @"𝄞öö"];
		[s[0] substringFromIndex: 2
				 toIndex: 4];
	    })

	EXPECT_EXCEPTION(@"Detect OoR in "
	    @"-[removeCharactersFromIndex:toIndex:] #2", OFOutOfRangeException,
	    [s[0] substringFromIndex: 4
			     toIndex: 4])

	EXPECT_EXCEPTION(@"Detect s > e in "
	    @"-[removeCharactersFromIndex:toIndex:]",
	    OFInvalidArgumentException,
	    [s[0] substringFromIndex: 2
			     toIndex: 0])

	TEST(@"-[replaceOccurrencesOfString:withString:]",
	    [[[OFMutableString stringWithString: @"asd fo asd fofo asd"]
	    replaceOccurrencesOfString: @"fo"
			    withString: @"foo"]
	    isEqual: @"asd foo asd foofoo asd"] &&
	    [[[OFMutableString stringWithString: @"XX"]
	    replaceOccurrencesOfString: @"X"
			    withString: @"XX"]
	    isEqual: @"XXXX"])

	TEST(@"-[removeLeadingWhitespaces]",
	    (s[0] = [OFMutableString stringWithString: whitespace[0]]) &&
	    [[s[0] removeLeadingWhitespaces] isEqual: @"asd  \t \t\t\r\n"] &&
	    (s[0] = [OFMutableString stringWithString: whitespace[1]]) &&
	    [[s[0] removeLeadingWhitespaces] isEqual: @""])

	TEST(@"-[removeTrailingWhitespaces]",
	    (s[0] = [OFMutableString stringWithString: whitespace[0]]) &&
	    [[s[0] removeTrailingWhitespaces] isEqual: @" \r \t\n\t \tasd"] &&
	    (s[0] = [OFMutableString stringWithString: whitespace[1]]) &&
	    [[s[0] removeTrailingWhitespaces] isEqual: @""])

	TEST(@"-[removeLeadingAndTrailingWhitespaces]",
	    (s[0] = [OFMutableString stringWithString: whitespace[0]]) &&
	    [[s[0] removeLeadingAndTrailingWhitespaces] isEqual: @"asd"] &&
	    (s[0] = [OFMutableString stringWithString: whitespace[1]]) &&
	    [[s[0] removeLeadingAndTrailingWhitespaces] isEqual: @""])

	TEST(@"-[stringByXMLEscaping]",
	    (s[0] = [@"<hello> &world'\"!&" stringByXMLEscaping]) &&
	    [s[0] isEqual: @"&lt;hello&gt; &amp;world&apos;&quot;!&amp;"])

	TEST(@"-[stringByXMLUnescaping]",
	    [[s[0] stringByXMLUnescaping] isEqual: @"<hello> &world'\"!&"] &&
	    [[@"&#x79;" stringByXMLUnescaping] isEqual: @"y"] &&
	    [[@"&#xe4;" stringByXMLUnescaping] isEqual: @"ä"] &&
	    [[@"&#8364;" stringByXMLUnescaping] isEqual: @"€"] &&
	    [[@"&#x1D11E;" stringByXMLUnescaping] isEqual: @"𝄞"])

	EXPECT_EXCEPTION(@"Detect invalid entities in -[stringByXMLUnescaping] "
	    @"#1", OFInvalidEncodingException, [@"&foo;" stringByXMLUnescaping])
	EXPECT_EXCEPTION(@"Detect invalid entities in -[stringByXMLUnescaping] "
	    @"#2", OFInvalidEncodingException, [@"x&amp" stringByXMLUnescaping])
	EXPECT_EXCEPTION(@"Detect invalid entities in -[stringByXMLUnescaping] "
	    @"#3", OFInvalidEncodingException, [@"&#;" stringByXMLUnescaping])
	EXPECT_EXCEPTION(@"Detect invalid entities in -[stringByXMLUnescaping] "
	    @"#4", OFInvalidEncodingException, [@"&#x;" stringByXMLUnescaping])
	EXPECT_EXCEPTION(@"Detect invalid entities in -[stringByXMLUnescaping] "
	    @"#5", OFInvalidEncodingException, [@"&#g;" stringByXMLUnescaping])
	EXPECT_EXCEPTION(@"Detect invalid entities in -[stringByXMLUnescaping] "
	    @"#6", OFInvalidEncodingException, [@"&#xg;" stringByXMLUnescaping])

	TEST(@"-[stringByXMLUnescapingWithHandler:]",
	    (h = [[[EntityHandler alloc] init] autorelease]) &&
	    (s[0] = [@"x&foo;y" stringByXMLUnescapingWithHandler: h]) &&
	    [s[0] isEqual: @"xbary"])

	[pool drain];
}
