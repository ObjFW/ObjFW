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

#include <stdlib.h>
#include <string.h>

#import "ObjFW.h"
#import "ObjFWTest.h"

@interface OFXMLParserTests: OTTestCase <OFXMLParserDelegate>
{
	int _i;
}
@end

enum EventType {
	eventTypeProcessingInstruction,
	eventTypeTagOpen,
	eventTypeTagClose,
	eventTypeString,
	eventTypeCDATA,
	eventTypeComment
};

@implementation OFXMLParserTests
-   (void)parser: (OFXMLParser *)parser
  didCreateEvent: (enum EventType)type
	    name: (OFString *)name
	  prefix: (OFString *)prefix
       namespace: (OFString *)namespace
      attributes: (OFArray *)attrs
	  string: (OFString *)string
{
	switch (_i++) {
	case 0:
		OTAssertEqual(type, eventTypeProcessingInstruction);
		OTAssertEqualObjects(name, @"xml");
		OTAssertEqualObjects(string, @"version='1.0'");
		break;
	case 1:
		OTAssertEqual(type, eventTypeProcessingInstruction);
		OTAssertEqualObjects(name, @"p?i");
		OTAssertNil(string);
		break;
	case 2:
		OTAssertEqual(type, eventTypeTagOpen);
		OTAssertEqualObjects(name, @"root");
		OTAssertNil(prefix);
		OTAssertNil(namespace);
		OTAssertEqual(attrs.count, 0);
		break;
	case 3:
		OTAssertEqual(type, eventTypeString);
		OTAssertEqualObjects(string, @"\n\n ");
		break;
	case 4:
		OTAssertEqual(type, eventTypeCDATA);
		OTAssertEqualObjects(string, @"f<]]]oo]");
		OTAssertEqual(parser.lineNumber, 3);
		break;
	case 5:
		OTAssertEqual(type, eventTypeTagOpen);
		OTAssertEqualObjects(name, @"bar");
		OTAssertNil(prefix);
		OTAssertNil(namespace);
		OTAssertNil(attrs);
		break;
	case 6:
		OTAssertEqual(type, eventTypeTagClose);
		OTAssertEqualObjects(name, @"bar");
		OTAssertNil(prefix);
		OTAssertNil(namespace);
		OTAssertNil(attrs);
		break;
	case 7:
		OTAssertEqual(type, eventTypeString);
		OTAssertEqualObjects(string, @"\n ");
		break;
	case 8:
		OTAssertEqual(type, eventTypeTagOpen);
		OTAssertEqualObjects(name, @"foobar");
		OTAssertNil(prefix);
		OTAssertEqualObjects(namespace, @"urn:objfw:test:foobar");
		OTAssertEqualObjects(attrs, [OFArray arrayWithObject:
		    [OFXMLAttribute attributeWithName: @"xmlns"
					  stringValue: @"urn:objfw:test:"
						       @"foobar"]]);
		break;
	case 9:
		OTAssertEqual(type, eventTypeString);
		OTAssertEqualObjects(string, @"\n  ");
		break;
	case 10:
		OTAssertEqual(type, eventTypeTagOpen);
		OTAssertEqualObjects(name, @"qux");
		OTAssertNil(prefix);
		OTAssertEqualObjects(namespace, @"urn:objfw:test:foobar");
		OTAssertEqualObjects(attrs, [OFArray arrayWithObject:
		    [OFXMLAttribute attributeWithName: @"foo"
					    namespace: @"http://www.w3.org/"
						       @"2000/xmlns/"
					  stringValue: @"urn:objfw:test:foo"]]);
		break;
	case 11:
		OTAssertEqual(type, eventTypeString);
		OTAssertEqualObjects(string, @"\n   ");
		break;
	case 12:
		OTAssertEqual(type, eventTypeTagOpen);
		OTAssertEqualObjects(name, @"bla");
		OTAssertEqualObjects(prefix, @"foo");
		OTAssertEqualObjects(namespace, @"urn:objfw:test:foo");
		OTAssertEqualObjects(attrs, ([OFArray arrayWithObjects:
		    [OFXMLAttribute attributeWithName: @"bla"
					    namespace: @"urn:objfw:test:foo"
					  stringValue: @"bla"],
		    [OFXMLAttribute attributeWithName: @"blafoo"
					  stringValue: @"foo"], nil]));
		break;
	case 13:
		OTAssertEqual(type, eventTypeString);
		OTAssertEqualObjects(string, @"\n    ");
		break;
	case 14:
		OTAssertEqual(type, eventTypeTagOpen);
		OTAssertEqualObjects(name, @"blup");
		OTAssertNil(prefix);
		OTAssertEqualObjects(namespace, @"urn:objfw:test:foobar");
		OTAssertEqualObjects(attrs, ([OFArray arrayWithObjects:
		    [OFXMLAttribute attributeWithName: @"qux"
					    namespace: @"urn:objfw:test:foo"
					  stringValue: @"asd"],
		    [OFXMLAttribute attributeWithName: @"quxqux"
					  stringValue: @"test"], nil]));
		break;
	case 15:
		OTAssertEqual(type, eventTypeTagClose);
		OTAssertEqualObjects(name, @"blup");
		OTAssertNil(prefix);
		OTAssertEqualObjects(namespace, @"urn:objfw:test:foobar");
		break;
	case 16:
		OTAssertEqual(type, eventTypeString);
		OTAssertEqualObjects(string, @"\n    ");
		break;
	case 17:
		OTAssertEqual(type, eventTypeTagOpen);
		OTAssertEqualObjects(name, @"bla");
		OTAssertEqualObjects(prefix, @"bla");
		OTAssertEqualObjects(namespace, @"urn:objfw:test:bla");
		OTAssertEqualObjects(attrs, ([OFArray arrayWithObjects:
		    [OFXMLAttribute attributeWithName: @"bla"
					    namespace: @"http://www.w3.org/"
						       @"2000/xmlns/"
					  stringValue: @"urn:objfw:test:bla"],
		    [OFXMLAttribute attributeWithName: @"qux"
					  stringValue: @"qux"],
		    [OFXMLAttribute attributeWithName: @"foo"
					    namespace: @"urn:objfw:test:bla"
					  stringValue: @"blafoo"], nil]));
		break;
	case 18:
		OTAssertEqual(type, eventTypeTagClose);
		OTAssertEqualObjects(name, @"bla");
		OTAssertEqualObjects(prefix, @"bla");
		OTAssertEqualObjects(namespace, @"urn:objfw:test:bla");
		break;
	case 19:
		OTAssertEqual(type, eventTypeString);
		OTAssertEqualObjects(string, @"\n    ");
		break;
	case 20:
		OTAssertEqual(type, eventTypeTagOpen);
		OTAssertEqualObjects(name, @"abc");
		OTAssertNil(prefix);
		OTAssertEqualObjects(namespace, @"urn:objfw:test:abc");
		OTAssertEqualObjects(attrs, ([OFArray arrayWithObjects:
		    [OFXMLAttribute attributeWithName: @"xmlns"
					  stringValue: @"urn:objfw:test:abc"],
		    [OFXMLAttribute attributeWithName: @"abc"
					  stringValue: @"abc"],
		    [OFXMLAttribute attributeWithName: @"abc"
					    namespace: @"urn:objfw:test:foo"
					  stringValue: @"abc"], nil]));
		break;
	case 21:
		OTAssertEqual(type, eventTypeTagClose);
		OTAssertEqualObjects(name, @"abc");
		OTAssertNil(prefix);
		OTAssertEqualObjects(namespace, @"urn:objfw:test:abc");
		break;
	case 22:
		OTAssertEqual(type, eventTypeString);
		OTAssertEqualObjects(string, @"\n   ");
		break;
	case 23:
		OTAssertEqual(type, eventTypeTagClose);
		OTAssertEqualObjects(name, @"bla");
		OTAssertEqualObjects(prefix, @"foo");
		OTAssertEqualObjects(namespace, @"urn:objfw:test:foo");
		break;
	case 24:
		OTAssertEqual(type, eventTypeString);
		OTAssertEqualObjects(string, @"\n   ");
		break;
	case 25:
		OTAssertEqual(type, eventTypeComment);
		OTAssertEqualObjects(string, @" commänt ");
		break;
	case 26:
		OTAssertEqual(type, eventTypeString);
		OTAssertEqualObjects(string, @"\n  ");
		break;
	case 27:
		OTAssertEqual(type, eventTypeTagClose);
		OTAssertEqualObjects(name, @"qux");
		OTAssertNil(prefix);
		OTAssertEqualObjects(namespace, @"urn:objfw:test:foobar");
		break;
	case 28:
		OTAssertEqual(type, eventTypeString);
		OTAssertEqualObjects(string, @"\n ");
		break;
	case 29:
		OTAssertEqual(type, eventTypeTagClose);
		OTAssertEqualObjects(name, @"foobar");
		OTAssertNil(prefix);
		OTAssertEqualObjects(namespace, @"urn:objfw:test:foobar");
		break;
	case 30:
		OTAssertEqual(type, eventTypeString);
		OTAssertEqualObjects(string, @"\n");
		break;
	case 31:
		OTAssertEqual(type, eventTypeTagClose);
		OTAssertEqualObjects(name, @"root");
		OTAssertNil(prefix);
		OTAssertNil(namespace);
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

- (void)testParser
{
	static const char *string = "\xEF\xBB\xBF<?xml version='1.0'?><?p?i?>"
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

	parser = [OFXMLParser parser];
	parser.delegate = self;

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

	OTAssertEqual(_i, 32);
	OTAssertEqual(parser.lineNumber, 18);
	OTAssertTrue(parser.hasFinishedParsing);

	/* Parsing whitespaces after the document */
	[parser parseString: @" \t\r\n "];

	/* Parsing comments after the document */
	[parser parseString: @" \t<!-- foo -->\r<!--bar-->\n "];

	/* Detection of junk after the document */
	OTAssertThrowsSpecific([parser parseString: @"a"],
	    OFMalformedXMLException);
	OTAssertThrowsSpecific([parser parseString: @"<!["],
	    OFMalformedXMLException);
}

- (void)testDetectionOfInvalidXMLProcessingInstructions
{
	OFXMLParser *parser;

	parser = [OFXMLParser parser];
	OTAssertThrowsSpecific([parser parseString: @"<?xml version='2.0'?>"],
	    OFMalformedXMLException);

	parser = [OFXMLParser parser];
	OTAssertThrowsSpecific([parser parseString: @"<x><?xml?></x>"],
	    OFMalformedXMLException);
}

- (void)testDetectionOfInvalidEncoding
{
	OFXMLParser *parser = [OFXMLParser parser];

	OTAssertThrowsSpecific(
	    [parser parseString: @"<?xml encoding='UTF-7'?>"],
	    OFInvalidEncodingException);
}
@end
