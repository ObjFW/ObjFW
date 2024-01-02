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

#import "TestsAppDelegate.h"

static OFString *const module = @"OFXMLParser";
static int i = 0;

enum EventType {
	eventTypeProcessingInstruction,
	eventTypeTagOpen,
	eventTypeTagClose,
	eventTypeString,
	eventTypeCDATA,
	eventTypeComment
};

@implementation TestsAppDelegate (OFXMLParser)
-   (void)parser: (OFXMLParser *)parser
  didCreateEvent: (enum EventType)type
	    name: (OFString *)name
	  prefix: (OFString *)prefix
       namespace: (OFString *)namespace
      attributes: (OFArray *)attrs
	  string: (OFString *)string
{
	OFString *message;

	i++;
	message = [OFString stringWithFormat: @"Parsing part #%d", i];

	switch (i) {
	case 1:
		TEST(message,
		    type == eventTypeProcessingInstruction &&
		    [name isEqual: @"xml"] &&
		    [string isEqual: @"version='1.0'"])
		break;
	case 2:
		TEST(message,
		    type == eventTypeProcessingInstruction &&
		    [name isEqual: @"p?i"] && string == nil)
		break;
	case 3:
		TEST(message,
		    type == eventTypeTagOpen && [name isEqual: @"root"] &&
		    prefix == nil && namespace == nil && attrs.count == 0)
		break;
	case 4:
		TEST(message,
		    type == eventTypeString && [string isEqual: @"\n\n "])
		break;
	case 5:
		TEST(message,
		    type == eventTypeCDATA && [string isEqual: @"f<]]]oo]"] &&
		    parser.lineNumber == 3)
		break;
	case 6:
		TEST(message,
		    type == eventTypeTagOpen && [name isEqual: @"bar"] &&
		    prefix == nil && namespace == nil && attrs == nil)
		break;
	case 7:
		TEST(message,
		    type == eventTypeTagClose && [name isEqual: @"bar"] &&
		    prefix == nil && namespace == nil && attrs == nil)
		break;
	case 8:
		TEST(message,
		    type == eventTypeString && [string isEqual: @"\n "])
		break;
	case 9:
		TEST(message,
		    type == eventTypeTagOpen && [name isEqual: @"foobar"] &&
		    prefix == nil &&
		    [namespace isEqual: @"urn:objfw:test:foobar"] &&
		    attrs.count == 1 &&
		    /* xmlns attr */
		    [[[attrs objectAtIndex: 0] name] isEqual: @"xmlns"] &&
		    [[attrs objectAtIndex: 0] namespace] == nil &&
		    [[[attrs objectAtIndex: 0] stringValue] isEqual:
		    @"urn:objfw:test:foobar"])
		break;
	case 10:
		TEST(message,
		    type == eventTypeString && [string isEqual: @"\n  "])
		break;
	case 11:
		TEST(message,
		    type == eventTypeTagOpen && [name isEqual: @"qux"] &&
		    prefix == nil &&
		    [namespace isEqual: @"urn:objfw:test:foobar"] &&
		    attrs.count == 1 &&
		    /* xmlns:foo attr */
		    [[[attrs objectAtIndex: 0] name] isEqual: @"foo"] &&
		    [[[attrs objectAtIndex: 0] namespace] isEqual:
		    @"http://www.w3.org/2000/xmlns/"] &&
		    [[[attrs objectAtIndex: 0] stringValue] isEqual:
		    @"urn:objfw:test:foo"])
		break;
	case 12:
		TEST(message,
		    type == eventTypeString && [string isEqual: @"\n   "])
		break;
	case 13:
		TEST(message,
		    type == eventTypeTagOpen && [name isEqual: @"bla"] &&
		    [prefix isEqual: @"foo"] &&
		    [namespace isEqual: @"urn:objfw:test:foo"] &&
		    attrs.count == 2 &&
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
		TEST(message,
		    type == eventTypeString && [string isEqual: @"\n    "])
		break;
	case 15:
		TEST(message,
		    type == eventTypeTagOpen && [name isEqual: @"blup"] &&
		    prefix == nil &&
		    [namespace isEqual: @"urn:objfw:test:foobar"] &&
		    attrs.count == 2 &&
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
		TEST(message,
		    type == eventTypeTagClose && [name isEqual: @"blup"] &&
		    prefix == nil &&
		    [namespace isEqual: @"urn:objfw:test:foobar"])
		break;
	case 17:
		TEST(message,
		    type == eventTypeString && [string isEqual: @"\n    "])
		break;
	case 18:
		TEST(message,
		    type == eventTypeTagOpen && [name isEqual: @"bla"] &&
		    [prefix isEqual: @"bla"] &&
		    [namespace isEqual: @"urn:objfw:test:bla"] &&
		    attrs.count == 3 &&
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
		TEST(message,
		    type == eventTypeTagClose && [name isEqual: @"bla"] &&
		    [prefix isEqual: @"bla"] &&
		    [namespace isEqual: @"urn:objfw:test:bla"])
		break;
	case 20:
		TEST(message,
		    type == eventTypeString && [string isEqual: @"\n    "])
		break;
	case 21:
		TEST(message,
		    type == eventTypeTagOpen && [name isEqual: @"abc"] &&
		    prefix == nil &&
		    [namespace isEqual: @"urn:objfw:test:abc"] &&
		    attrs.count == 3 &&
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
		TEST(message,
		    type == eventTypeTagClose && [name isEqual: @"abc"] &&
		    prefix == nil && [namespace isEqual: @"urn:objfw:test:abc"])
		break;
	case 23:
		TEST(message,
		    type == eventTypeString && [string isEqual: @"\n   "])
		break;
	case 24:
		TEST(message,
		    type == eventTypeTagClose && [name isEqual: @"bla"] &&
		    [prefix isEqual: @"foo"] &&
		    [namespace isEqual: @"urn:objfw:test:foo"])
		break;
	case 25:
		TEST(message,
		    type == eventTypeString && [string isEqual: @"\n   "])
		break;
	case 26:
		TEST(message,
		    type == eventTypeComment && [string isEqual: @" commänt "])
		break;
	case 27:
		TEST(message,
		    type == eventTypeString && [string isEqual: @"\n  "])
		break;
	case 28:
		TEST(message,
		    type == eventTypeTagClose && [name isEqual: @"qux"] &&
		    prefix == nil &&
		    [namespace isEqual: @"urn:objfw:test:foobar"])
		break;
	case 29:
		TEST(message,
		    type == eventTypeString && [string isEqual: @"\n "])
		break;
	case 30:
		TEST(message,
		    type == eventTypeTagClose && [name isEqual: @"foobar"] &&
		    prefix == nil &&
		    [namespace isEqual: @"urn:objfw:test:foobar"])
		break;
	case 31:
		TEST(message,
		    type == eventTypeString && [string isEqual: @"\n"])
		break;
	case 32:
		TEST(message,
		    type == eventTypeTagClose && [name isEqual: @"root"] &&
		    prefix == nil && namespace == nil);
		break;
	}
}

-			  (void)parser: (OFXMLParser *)parser
  foundProcessingInstructionWithTarget: (OFString *)target
				  text: (OFString *)text
{
	[self	    parser: parser
	    didCreateEvent: eventTypeProcessingInstruction
		      name: target
		    prefix: nil
		 namespace: nil
		attributes: nil
		    string: text];
}

-    (void)parser: (OFXMLParser *)parser
  didStartElement: (OFString *)name
	   prefix: (OFString *)prefix
	namespace: (OFString *)namespace
       attributes: (OFArray *)attrs
{
	[self	    parser: parser
	    didCreateEvent: eventTypeTagOpen
		      name: name
		    prefix: prefix
		 namespace: namespace
		attributes: attrs
		    string: nil];
}

-  (void)parser: (OFXMLParser *)parser
  didEndElement: (OFString *)name
	 prefix: (OFString *)prefix
      namespace: (OFString *)namespace
{
	[self	    parser: parser
	    didCreateEvent: eventTypeTagClose
		      name: name
		    prefix: prefix
		 namespace: namespace
		attributes: nil
		    string: nil];
}

- (void)parser: (OFXMLParser *)parser foundCharacters: (OFString *)string
{
	[self	    parser: parser
	    didCreateEvent: eventTypeString
		      name: nil
		    prefix: nil
		 namespace: nil
		attributes: nil
		    string: string];
}

- (void)parser: (OFXMLParser *)parser foundCDATA: (OFString *)CDATA
{
	[self	    parser: parser
	    didCreateEvent: eventTypeCDATA
		      name: nil
		    prefix: nil
		 namespace: nil
		attributes: nil
		    string: CDATA];
}

- (void)parser: (OFXMLParser *)parser foundComment: (OFString *)comment
{
	[self	    parser: parser
	    didCreateEvent: eventTypeComment
		      name: nil
		    prefix: nil
		 namespace: nil
		attributes: nil
		    string: comment];
}

-      (OFString *)parser: (OFXMLParser *)parser
  foundUnknownEntityNamed: (OFString *)entity
{
	if ([entity isEqual: @"foo"])
		return @"foobar";

	return nil;
}

- (void)XMLParserTests
{
	void *pool = objc_autoreleasePoolPush();
	const char *string = "\xEF\xBB\xBF<?xml version='1.0'?><?p?i?>"
	    "<!DOCTYPE foo><root>\r\r"
	    " <![CDATA[f<]]]oo]]]><bar/>\n"
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
	OFXMLParser *parser;
	size_t j, length;

	TEST(@"+[parser]", (parser = [OFXMLParser parser]))

	TEST(@"-[setDelegate:]", (parser.delegate = self))

	/* Simulate a stream where we only get chunks */
	length = strlen(string);

	for (j = 0; j < length; j+= 2) {
		if (parser.hasFinishedParsing)
			abort();

		if (j + 2 > length)
			[parser parseBuffer: string + j length: 1];
		else
			[parser parseBuffer: string + j length: 2];
	}

	TEST(@"Checking if everything was parsed",
	    i == 32 && parser.lineNumber == 18)

	TEST(@"-[hasFinishedParsing]", parser.hasFinishedParsing)

	TEST(@"Parsing whitespaces after the document",
	    R([parser parseString: @" \t\r\n "]))

	TEST(@"Parsing comments after the document",
	    R([parser parseString: @" \t<!-- foo -->\r<!--bar-->\n "]))

	EXPECT_EXCEPTION(@"Detection of junk after the document #1",
	    OFMalformedXMLException, [parser parseString: @"a"])

	EXPECT_EXCEPTION(@"Detection of junk after the document #2",
	    OFMalformedXMLException, [parser parseString: @"<!["])

	parser = [OFXMLParser parser];
	EXPECT_EXCEPTION(@"Detection of invalid XML processing instruction #1",
	    OFMalformedXMLException,
	    [parser parseString: @"<?xml version='2.0'?>"])

	parser = [OFXMLParser parser];
	EXPECT_EXCEPTION(@"Detection of invalid XML processing instruction #2",
	    OFInvalidEncodingException,
	    [parser parseString: @"<?xml encoding='UTF-7'?>"])

	parser = [OFXMLParser parser];
	EXPECT_EXCEPTION(@"Detection of invalid XML processing instruction #3",
	    OFMalformedXMLException,
	    [parser parseString: @"<x><?xml?></x>"])

	objc_autoreleasePoolPop(pool);
}
@end
