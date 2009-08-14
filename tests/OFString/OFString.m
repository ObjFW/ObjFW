/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <stdio.h>

#import "OFString.h"
#import "OFArray.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"

#ifndef _WIN32
#define ZD "%zd"
#else
#define ZD "%u"
#endif

#define NUM_TESTS 71
#define SUCCESS								\
	printf("\r\033[1;%dmTests successful: " ZD "/%d\033[0m",	\
	    (i == NUM_TESTS - 1 ? 32 : 33), i + 1, NUM_TESTS);		\
	fflush(stdout);
#define FAIL								\
	printf("\r\033[K\033[1;31mTest " ZD "/%d failed!\033[m\n",	\
	    i + 1, NUM_TESTS);						\
	return 1;
#define CHECK(cond)							\
	if (cond) {							\
		SUCCESS							\
	} else {							\
		FAIL							\
	}								\
	i++;
#define CHECK_EXCEPT(code, exception)					\
	@try {								\
		code;							\
		FAIL							\
	} @catch (exception *e) {					\
		SUCCESS							\
	}								\
	i++;

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

int
main()
{
	size_t i = 0;
	size_t j = 0;

	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFString *s1 = [OFMutableString stringWithCString: "test"];
	OFString *s2 = [OFMutableString stringWithCString: ""];
	OFString *s3;
	OFString *s4 = [OFMutableString string];
	OFArray *a;
	EntityHandler *h;

	s3 = [s1 copy];

	CHECK([s1 isEqual: s3])
	CHECK(![s1 isEqual: [[OFObject alloc] init]])
	CHECK([s1 hash] == [s3 hash])

	[s2 appendCString: "12"];
	[s2 appendString: @"3"];
	[s4 setToCString: [s2 cString]];

	CHECK(![s2 compare: s4])
	CHECK([[s1 appendString: s2] isEqual: @"test123"])
	CHECK([s1 length] == 7)
	CHECK([s1 hash] == 0xC44F49A4)
	CHECK([[s1 reverse] isEqual: @"321tset"])
	CHECK([[s1 upper] isEqual: @"321TSET"])
	CHECK([[s1 lower] isEqual: @"321tset"])

	/* Also clears all the memory of the returned C strings */
	[pool release];

	s1 = [OFMutableString stringWithCString: "foobar"
					 length: 3];
	CHECK([s1 isEqual: @"foo"])

	[s1 appendCString: "foobarqux" + 3
	       withLength: 3];
	CHECK([s1 isEqual: @"foobar"])

	/* UTF-8 tests */
	CHECK_EXCEPT(s1 = [OFString stringWithCString: "\xE0\x80"],
	    OFInvalidEncodingException)
	CHECK_EXCEPT(s1 = [OFString stringWithCString: "\xF0\x80\x80\xC0"],
	    OFInvalidEncodingException)

	s1 = [OFMutableString stringWithCString: "äöü€𝄞"];
	CHECK([[s1 reverse] isEqual: @"𝄞€üöä"])
	[s1 dealloc];

	/* Encoding tests */
	CHECK([[OFString stringWithCString: "\xE4\xF6\xFC"
				 encoding: OF_STRING_ENCODING_ISO_8859_1]
	    isEqual: @"äöü"])

	CHECK([[OFString stringWithCString: "\xA4\xA6\xA8\xB4\xB8\xBC\xBD\xBE"
				  encoding: OF_STRING_ENCODING_ISO_8859_15]
	    isEqual: @"€ŠšŽžŒœŸ"])
	CHECK([[OFString stringWithCString: "\x80\x82\x83\x84\x85\x86\x87\x88"
					    "\x89\x8A\x8B\x8C\x8E\x91\x92\x93"
					    "\x94\x95\x96\x97\x98\x99\x9A\x9B"
					    "\x9C\x9E\x9F"
				  encoding: OF_STRING_ENCODING_WINDOWS_1252]
	    isEqual: @"€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ"])

	/* Format tests */
	s1 = [OFMutableString stringWithFormat: @"%s: %d", "test", 123];
	CHECK([s1 isEqual: @"test: 123"])

	[s1 appendWithFormat: @"%02X", 15];
	CHECK([s1 isEqual: @"test: 1230F"])

	/* Find index tests */
	CHECK([@"foo" indexOfFirstOccurrenceOfString: @"oo"] == 1)
	CHECK([@"foo" indexOfLastOccurrenceOfString: @"oo"] == 1)
	CHECK([@"foo" indexOfFirstOccurrenceOfString: @"o"] == 1)
	CHECK([@"foo" indexOfLastOccurrenceOfString: @"o"] == 2)
	CHECK([@"foo" indexOfFirstOccurrenceOfString: @"f"] == 0)
	CHECK([@"foo" indexOfLastOccurrenceOfString: @"f"] == 0)
	CHECK([@"foo" indexOfFirstOccurrenceOfString: @"x"] == SIZE_MAX)
	CHECK([@"foo" indexOfLastOccurrenceOfString: @"x"] == SIZE_MAX)

	/* Substring tests */
	CHECK([[@"foo" substringFromIndex: 1
				  toIndex: 2] isEqual: @"o"]);
	CHECK([[@"foo" substringFromIndex: 3
				  toIndex: 3] isEqual: @""]);
	CHECK_EXCEPT([@"foo" substringFromIndex: 2
					toIndex: 4], OFOutOfRangeException)
	CHECK_EXCEPT([@"foo" substringFromIndex: 4
					toIndex: 4], OFOutOfRangeException)
	CHECK_EXCEPT([@"foo" substringFromIndex: 2
					toIndex: 0], OFInvalidArgumentException)

	/* Misc tests */
	CHECK([[@"foo" stringByAppendingString: @"bar"] isEqual: @"foobar"])
	CHECK([@"foobar" hasPrefix: @"foo"])
	CHECK([@"foobar" hasSuffix: @"bar"])
	CHECK(![@"foobar" hasPrefix: @"foobar0"])
	CHECK(![@"foobar" hasSuffix: @"foobar0"])

	/* Split tests */
	a = [@"fooXXbarXXXXbazXXXX" splitWithDelimiter: @"XX"];
	CHECK([[a objectAtIndex: j++] isEqual: @"foo"])
	CHECK([[a objectAtIndex: j++] isEqual: @"bar"])
	CHECK([[a objectAtIndex: j++] isEqual: @""])
	CHECK([[a objectAtIndex: j++] isEqual: @"baz"])
	CHECK([[a objectAtIndex: j++] isEqual: @""])
	CHECK([[a objectAtIndex: j++] isEqual: @""])

	/* Hash tests */
	CHECK([[@"asdfoobar" md5Hash]
	    isEqual: @"184dce2ec49b5422c7cfd8728864db4c"]);
	CHECK([[@"asdfoobar" sha1Hash]
	    isEqual: @"f5f81ac0a8b5cbfdc4585ec1ad32e7b3a12b9b49"]);

	/* URL encoding tests */
	CHECK([[@"foo\"ba'_~$" stringByURLEncoding]
	    isEqual: @"foo%22ba%27_~%24"])
	CHECK([[@"foo%20bar%22+%24" stringByURLDecoding]
	    isEqual: @"foo bar\" $"])
	CHECK_EXCEPT([@"foo%bar" stringByURLDecoding],
	    OFInvalidEncodingException)
	CHECK_EXCEPT([@"foo%FFbar" stringByURLDecoding],
	    OFInvalidEncodingException)

	/* Replace tests */
	s1 = [@"asd fo asd fofo asd" mutableCopy];
	[s1 replaceOccurrencesOfString: @"fo"
			    withString: @"foo"];
	CHECK([s1 isEqual: @"asd foo asd foofoo asd"])
	s1 = [@"XX" mutableCopy];
	[s1 replaceOccurrencesOfString: @"X"
			    withString: @"XX"];
	CHECK([s1 isEqual: @"XXXX"])

	/* Whitespace removing tests */
	s1 = [@" \r \t\n\t \tasd  \t \t\t\r\n" mutableCopy];
	s2 = [s1 mutableCopy];
	s3 = [s1 mutableCopy];
	CHECK([[s1 removeLeadingWhitespaces] isEqual: @"asd  \t \t\t\r\n"])
	CHECK([[s2 removeTrailingWhitespaces] isEqual: @" \r \t\n\t \tasd"])
	CHECK([[s3 removeLeadingAndTrailingWhitespaces] isEqual: @"asd"])

	s1 = [@" \t\t  \t\t  \t \t" mutableCopy];
	s2 = [s1 mutableCopy];
	s3 = [s1 mutableCopy];
	CHECK([[s1 removeLeadingWhitespaces] isEqual: @""])
	CHECK([[s2 removeTrailingWhitespaces] isEqual: @""])
	CHECK([[s3 removeLeadingAndTrailingWhitespaces] isEqual: @""])

	/* XML escaping tests */
	s1 = [@"<hello> &world'\"!&" stringByXMLEscaping];
	CHECK([s1 isEqual: @"&lt;hello&gt; &amp;world&apos;&quot;!&amp;"])

	/* XML unescaping tests */
	CHECK([[s1 stringByXMLUnescaping] isEqual: @"<hello> &world'\"!&"]);
	CHECK_EXCEPT([@"&foo;" stringByXMLUnescaping],
	    OFInvalidEncodingException)

	h = [[EntityHandler alloc] init];
	s1 = [@"x&foo;y" stringByXMLUnescapingWithHandler: h];
	CHECK([s1 isEqual: @"xbary"]);

	CHECK_EXCEPT([@"x&amp" stringByXMLUnescaping],
	    OFInvalidEncodingException)

	CHECK([[@"&#x79;" stringByXMLUnescaping] isEqual: @"y"]);
	CHECK([[@"&#xE4;" stringByXMLUnescaping] isEqual: @"ä"]);
	CHECK([[@"&#8364;" stringByXMLUnescaping] isEqual: @"€"]);
	CHECK([[@"&#x1D11E;" stringByXMLUnescaping] isEqual: @"𝄞"]);

	CHECK_EXCEPT([@"&#;" stringByXMLUnescaping], OFInvalidEncodingException)
	CHECK_EXCEPT([@"&#x;" stringByXMLUnescaping],
	    OFInvalidEncodingException)
	CHECK_EXCEPT([@"&#g;" stringByXMLUnescaping],
	    OFInvalidEncodingException)
	CHECK_EXCEPT([@"&#xg;" stringByXMLUnescaping],
	    OFInvalidEncodingException)

	puts("");

	return 0;
}
