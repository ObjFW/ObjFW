/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "OFXMLParser.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFAutoreleasePool.h"

#import "OFMalformedXMLException.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFXMLParser";
static OFXMLParser *parser;
static int i = 0;

enum event_type {
	PROCESSING_INSTRUCTIONS,
	TAG_START,
	TAG_END,
	STRING,
	CDATA,
	COMMENT
};

@implementation TestsAppDelegate (OFXMLParser)
- (void)parserCallbackWithEventType: (enum event_type)et
			       name: (OFString*)name
			     prefix: (OFString*)prefix
			  namespace: (OFString*)ns
			 attributes: (OFArray*)attrs
			     string: (OFString*)string
{
	OFString *msg;

	i++;
	msg = [OFString stringWithFormat: @"Parsing part #%d", i];

	switch (i) {
	case 1:
		TEST(msg, et == PROCESSING_INSTRUCTIONS &&
		    [string isEqual: @"xml version='1.0'"])
		break;
	case 2:
		TEST(msg, et == PROCESSING_INSTRUCTIONS &&
		    [string isEqual: @"p?i"])
		break;
	case 3:
		TEST(msg, et == TAG_START && [name isEqual: @"root"] &&
		    prefix == nil && ns == nil && [attrs count] == 0)
		break;
	case 4:
		TEST(msg, et == STRING && [string isEqual: @"\n\n "])
		break;
	case 5:
		TEST(msg, et == CDATA && [string isEqual: @"f<]]]oo"] &&
		    [parser lineNumber] == 3)
		break;
	case 6:
		TEST(msg, et == TAG_START && [name isEqual: @"bar"] &&
		    prefix == nil && ns == nil && attrs == nil)
		break;
	case 7:
		TEST(msg, et == TAG_END && [name isEqual: @"bar"] &&
		    prefix == nil && ns == nil && attrs == nil)
		break;
	case 8:
		TEST(msg, et == STRING && [string isEqual: @"\n "])
		break;
	case 9:
		TEST(msg, et == TAG_START && [name isEqual: @"foobar"] &&
		    prefix == nil && [ns isEqual: @"urn:objfw:test:foobar"] &&
		    [attrs count] == 1 &&
		    /* xmlns attr */
		    [[[attrs objectAtIndex: 0] name] isEqual: @"xmlns"] &&
		    [[attrs objectAtIndex: 0] namespace] == nil &&
		    [[[attrs objectAtIndex: 0] stringValue] isEqual:
		    @"urn:objfw:test:foobar"])
		break;
	case 10:
		TEST(msg, et == STRING && [string isEqual: @"\n  "])
		break;
	case 11:
		TEST(msg, et == TAG_START && [name isEqual: @"qux"] &&
		    prefix == nil && [ns isEqual: @"urn:objfw:test:foobar"] &&
		    [attrs count] == 1 &&
		    /* xmlns:foo attr */
		    [[[attrs objectAtIndex: 0] name] isEqual: @"foo"] &&
		    [[[attrs objectAtIndex: 0] namespace] isEqual:
		    @"http://www.w3.org/2000/xmlns/"] &&
		    [[[attrs objectAtIndex: 0] stringValue] isEqual:
		    @"urn:objfw:test:foo"])
		break;
	case 12:
		TEST(msg, et == STRING && [string isEqual: @"\n   "])
		break;
	case 13:
		TEST(msg, et == TAG_START && [name isEqual: @"bla"] &&
		    [prefix isEqual: @"foo"] &&
		    [ns isEqual: @"urn:objfw:test:foo"] &&
		    [attrs count] == 2 &&
		    /* foo:bla attr */
		    [[[attrs objectAtIndex: 0] name] isEqual: @"bla"] &&
		    [[[attrs objectAtIndex: 0] namespace] isEqual:
		    @"urn:objfw:test:foo"] &&
		    [[[attrs objectAtIndex: 0] stringValue] isEqual: @"bla"] &&
		    /* blafoo attr */
		    [[[attrs objectAtIndex: 1] name] isEqual: @"blafoo"] &&
		    [[attrs objectAtIndex: 1] namespace] == nil &&
		    [[[attrs objectAtIndex: 1] stringValue] isEqual: @"foo"])
		break;
	case 14:
		TEST(msg, et == STRING && [string isEqual: @"\n    "])
		break;
	case 15:
		TEST(msg, et == TAG_START && [name isEqual: @"blup"] &&
		    prefix == nil && [ns isEqual: @"urn:objfw:test:foobar"] &&
		    [attrs count] == 2 &&
		    /* foo:qux attr */
		    [[[attrs objectAtIndex: 0] name] isEqual: @"qux"] &&
		    [[[attrs objectAtIndex: 0] namespace] isEqual:
		    @"urn:objfw:test:foo"] &&
		    [[[attrs objectAtIndex: 0] stringValue] isEqual: @"asd"] &&
		    /* quxqux attr */
		    [[[attrs objectAtIndex: 1] name] isEqual: @"quxqux"] &&
		    [[attrs objectAtIndex: 1] namespace] == nil &&
		    [[[attrs objectAtIndex: 1] stringValue] isEqual: @"test"])
		break;
	case 16:
		TEST(msg, et == TAG_END && [name isEqual: @"blup"] &&
		    prefix == nil && [ns isEqual: @"urn:objfw:test:foobar"])
		break;
	case 17:
		TEST(msg, et == STRING && [string isEqual: @"\n    "])
		break;
	case 18:
		TEST(msg, et == TAG_START && [name isEqual: @"bla"] &&
		    [prefix isEqual: @"bla"] &&
		    [ns isEqual: @"urn:objfw:test:bla"] && [attrs count] == 3 &&
		    /* xmlns:bla attr */
		    [[[attrs objectAtIndex: 0] name] isEqual: @"bla"] &&
		    [[[attrs objectAtIndex: 0] namespace] isEqual:
		    @"http://www.w3.org/2000/xmlns/"] &&
		    [[[attrs objectAtIndex: 0] stringValue] isEqual:
		    @"urn:objfw:test:bla"] &&
		    /* qux attr */
		    [[[attrs objectAtIndex: 1] name] isEqual: @"qux"] &&
		    [[attrs objectAtIndex: 1] namespace] == nil &&
		    [[[attrs objectAtIndex: 1] stringValue] isEqual: @"qux"] &&
		    /* bla:foo attr */
		    [[[attrs objectAtIndex: 2] name] isEqual: @"foo"] &&
		    [[[attrs objectAtIndex: 2] namespace] isEqual:
		    @"urn:objfw:test:bla"] &&
		    [[[attrs objectAtIndex: 2] stringValue] isEqual: @"blafoo"])
		break;
	case 19:
		TEST(msg, et == TAG_END && [name isEqual: @"bla"] &&
		    [prefix isEqual: @"bla"] &&
		    [ns isEqual: @"urn:objfw:test:bla"])
		break;
	case 20:
		TEST(msg, et == STRING && [string isEqual: @"\n    "])
		break;
	case 21:
		TEST(msg, et == TAG_START && [name isEqual: @"abc"] &&
		    prefix == nil && [ns isEqual: @"urn:objfw:test:abc"] &&
		    [attrs count] == 3 &&
		    /* xmlns attr */
		    [[[attrs objectAtIndex: 0] name] isEqual: @"xmlns"] &&
		    [[attrs objectAtIndex: 0] namespace] == nil &&
		    [[[attrs objectAtIndex: 0] stringValue] isEqual:
		    @"urn:objfw:test:abc"] &&
		    /* abc attr */
		    [[[attrs objectAtIndex: 1] name] isEqual: @"abc"] &&
		    [[attrs objectAtIndex: 1] namespace] == nil &&
		    [[[attrs objectAtIndex: 1] stringValue] isEqual: @"abc"] &&
		    /* foo:abc attr */
		    [[[attrs objectAtIndex: 2] name] isEqual: @"abc"] &&
		    [[[attrs objectAtIndex: 2] namespace] isEqual:
		    @"urn:objfw:test:foo"] &&
		    [[[attrs objectAtIndex: 2] stringValue] isEqual: @"abc"])
		break;
	case 22:
		TEST(msg, et == TAG_END && [name isEqual: @"abc"] &&
		    prefix == nil && [ns isEqual: @"urn:objfw:test:abc"])
		break;
	case 23:
		TEST(msg, et == STRING && [string isEqual: @"\n   "])
		break;
	case 24:
		TEST(msg, et == TAG_END && [name isEqual: @"bla"] &&
		    [prefix isEqual: @"foo"] &&
		    [ns isEqual: @"urn:objfw:test:foo"])
		break;
	case 25:
		TEST(msg, et == STRING && [string isEqual: @"\n   "])
		break;
	case 26:
		TEST(msg, et == COMMENT && [string isEqual: @" commänt "])
		break;
	case 27:
		TEST(msg, et == STRING && [string isEqual: @"\n  "])
		break;
	case 28:
		TEST(msg, et == TAG_END && [name isEqual: @"qux"] &&
		    prefix == nil && [ns isEqual: @"urn:objfw:test:foobar"])
		break;
	case 29:
		TEST(msg, et == STRING && [string isEqual: @"\n "])
		break;
	case 30:
		TEST(msg, et == TAG_END && [name isEqual: @"foobar"] &&
		    prefix == nil && [ns isEqual: @"urn:objfw:test:foobar"])
		break;
	case 31:
		TEST(msg, et == STRING && [string isEqual: @"\n"])
		break;
	case 32:
		TEST(msg, et == TAG_END && [name isEqual: @"root"] &&
		    prefix == nil && ns == nil);
		break;
	}
}

-		 (void)parser: (OFXMLParser*)parser
  foundProcessingInstructions: (OFString*)pi
{
	[self parserCallbackWithEventType: PROCESSING_INSTRUCTIONS
				     name: nil
				   prefix: nil
				namespace: nil
			       attributes: nil
				   string: pi];
}

-    (void)parser: (OFXMLParser*)parser
  didStartElement: (OFString*)name
	   prefix: (OFString*)prefix
	namespace: (OFString*)ns
       attributes: (OFArray*)attrs
{
	[self parserCallbackWithEventType: TAG_START
				     name: name
				   prefix: prefix
				namespace: ns
			       attributes: attrs
				   string: nil];
}

-  (void)parser: (OFXMLParser*)parser
  didEndElement: (OFString*)name
	 prefix: (OFString*)prefix
      namespace: (OFString*)ns
{
	[self parserCallbackWithEventType: TAG_END
				     name: name
				   prefix: prefix
				namespace: ns
			       attributes: nil
				   string: nil];
}

-    (void)parser: (OFXMLParser*)parser
  foundCharacters: (OFString*)string
{
	[self parserCallbackWithEventType: STRING
				     name: nil
				   prefix: nil
				namespace: nil
			       attributes: nil
				   string: string];
}

- (void)parser: (OFXMLParser*)parser
    foundCDATA: (OFString*)cdata
{
	[self parserCallbackWithEventType: CDATA
				     name: nil
				   prefix: nil
				namespace: nil
			       attributes: nil
				   string: cdata];
}

- (void)parser: (OFXMLParser*)parser
  foundComment: (OFString*)comment
{
	[self parserCallbackWithEventType: COMMENT
				     name: nil
				   prefix: nil
				namespace: nil
			       attributes: nil
				   string: comment];
}

-	(OFString*)parser: (OFXMLParser*)parser
  foundUnknownEntityNamed: (OFString*)entity
{
	if ([entity isEqual: @"foo"])
		return @"foobar";

	return nil;
}

- (void)XMLParserTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	const char *str = "<?xml version='1.0'?><?p?i?>"
	    "<!DOCTYPE <<><<>>>><root>\r\r"
	    " <![CDATA[f<]]]oo]]><bar/>\n"
	    " <foobar xmlns='urn:objfw:test:foobar'>\r\n"
	    "  <qux xmlns:foo='urn:objfw:test:foo'>\n"
	    "   <foo:bla foo:bla = '&#x62;&#x6c;&#x61;' blafoo='foo'>\n"
	    "    <blup foo:qux='asd' quxqux='test'/>\n"
	    "    <bla:bla\r\rxmlns:bla\r=\t\"urn:objfw:test:bla\" qux='qux'\r\n"
	    "     bla:foo='blafoo'/>\n"
	    "    <abc xmlns='urn:objfw:test:abc' abc='abc' foo:abc='abc'/>\n"
	    "   </foo:bla>\n"
	    "   <!-- commänt -->\n"
	    "  </qux>\n"
	    " </foobar>\n"
	    "</root>";
	size_t j, len;

	TEST(@"+[xmlParser]", (parser = [OFXMLParser parser]))

	TEST(@"-[setDelegate:]", R([parser setDelegate: self]))

	/* Simulate a stream where we only get chunks */
	len = strlen(str);

	for (j = 0; j < len; j+= 2) {
		if ([parser finishedParsing])
			abort();

		if (j + 2 > len)
			[parser parseBuffer: str + j
				     length: 1];
		else
			[parser parseBuffer: str + j
				     length: 2];
	}

	TEST(@"Checking if everything was parsed",
	    i == 32 && [parser lineNumber] == 18)

	TEST(@"-[finishedParsing]", [parser finishedParsing])

	TEST(@"Parsing whitespaces after the document",
	    R([parser parseString: @" \t\r\n "]))

	TEST(@"Parsing comments after the document",
	    R([parser parseString: @" \t<!-- foo -->\r<!--bar-->\n "]))

	EXPECT_EXCEPTION(@"Detection of junk after the document #1",
	    OFMalformedXMLException, [parser parseString: @"a"])

	EXPECT_EXCEPTION(@"Detection of junk after the document #2",
	    OFMalformedXMLException, [parser parseString: @"<!["])

	parser = [OFXMLParser parser];
	EXPECT_EXCEPTION(@"Detection of invalid XML processing instructions #1",
	    OFMalformedXMLException,
	    [parser parseString: @"<?xml version='2.0'?>"])

	parser = [OFXMLParser parser];
	EXPECT_EXCEPTION(@"Detection of invalid XML processing instructions #2",
	    OFMalformedXMLException,
	    [parser parseString: @"<?xml encoding='UTF-7'?>"])

	parser = [OFXMLParser parser];
	EXPECT_EXCEPTION(@"Detection of invalid XML processing instructions #3",
	    OFMalformedXMLException,
	    [parser parseString: @"<x><?xml?></x>"])

	[pool drain];
}
@end
