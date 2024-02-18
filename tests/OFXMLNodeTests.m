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

#import "ObjFW.h"
#import "ObjFWTest.h"

@interface OFXMLNodeTests: OTTestCase
@end

@implementation OFXMLNodeTests
- (void)testElementWithName
{
	OTAssertEqualObjects(
	    [[OFXMLElement elementWithName: @"foo"] XMLString],
	    @"<foo/>");
}

- (void)testElementWithNameStringValue
{
	OTAssertEqualObjects(
	    [[OFXMLElement elementWithName: @"foo"
			       stringValue: @"b&ar"] XMLString],
	    @"<foo>b&amp;ar</foo>");
}

- (void)testElementWithNameNamespace
{
	OFXMLElement *element;

	element = [OFXMLElement elementWithName: @"foo"
				      namespace: @"urn:objfw:test"];
	[element addAttributeWithName: @"test" stringValue: @"test"];
	[element setPrefix: @"objfw-test" forNamespace: @"urn:objfw:test"];
	OTAssertEqualObjects(element.XMLString,
	    @"<objfw-test:foo test='test'/>");

	element = [OFXMLElement elementWithName: @"foo"
				      namespace: @"urn:objfw:test"];
	[element addAttributeWithName: @"test" stringValue: @"test"];
	OTAssertEqualObjects(element.XMLString,
	    @"<foo xmlns='urn:objfw:test' test='test'/>");
}

- (void)testElementWithNameNamespaceStringValue
{
	OFXMLElement *element = [OFXMLElement elementWithName: @"foo"
						    namespace: @"urn:objfw:test"
						  stringValue: @"x"];
	[element setPrefix: @"objfw-test" forNamespace: @"urn:objfw:test"];
	OTAssertEqualObjects(element.XMLString,
	    @"<objfw-test:foo>x</objfw-test:foo>");
}

- (void)testElementWithXMLStringAndStringValue
{
	OTAssertEqualObjects([[OFXMLElement elementWithXMLString:
	    @"<?xml version='1.0' encoding='UTF-8'?>\r\n<x>foo<![CDATA[bar]]>"
	    @"<y>b<!-- fooo -->az</y>qux</x>"] stringValue],
	    @"foobarbazqux");
}

- (void)testCharactersWithString
{
	OTAssertEqualObjects(
	    [[OFXMLCharacters charactersWithString: @"<foo>"] XMLString],
	    @"&lt;foo&gt;");
}

- (void)testCDATAWithString
{
	OTAssertEqualObjects(
	    [[OFXMLCDATA CDATAWithString: @"<foo>"] XMLString],
	    @"<![CDATA[<foo>]]>");
}

- (void)testCommentWithText
{
	OTAssertEqualObjects(
	    [[OFXMLComment commentWithText: @" comment "] XMLString],
	    @"<!-- comment -->");
}

- (void)testIsEqual
{
	OTAssertEqualObjects(
	    [OFXMLElement elementWithXMLString: @"<foo bar='asd'/>"],
	    [OFXMLElement elementWithXMLString: @"<foo bar='asd'></foo>"]);

	OTAssertEqualObjects(
	    [OFXMLElement elementWithXMLString: @"<x><y/></x>"],
	    [OFXMLElement elementWithXMLString: @"<x><y></y></x>"]);

	OTAssertNotEqualObjects(
	    [OFXMLElement elementWithXMLString: @"<x><Y/></x>"],
	    [OFXMLElement elementWithXMLString: @"<x><y></y></x>"]);
}

- (void)testHash
{
	OTAssertEqual(
	    [[OFXMLElement elementWithXMLString: @"<foo bar='asd'/>"] hash],
	    [[OFXMLElement elementWithXMLString: @"<foo bar='asd'></foo>"]
	    hash]);

	OTAssertEqual(
	    [[OFXMLElement elementWithXMLString: @"<x><y/></x>"] hash],
	    [[OFXMLElement elementWithXMLString: @"<x><y></y></x>"] hash]);

	OTAssertNotEqual(
	    [[OFXMLElement elementWithXMLString: @"<x><Y/></x>"] hash],
	    [[OFXMLElement elementWithXMLString: @"<x><y></y></x>"] hash]);
}

- (void)testAddAttributeWithNameStringValue
{
	OFXMLElement *element = [OFXMLElement elementWithName: @"foo"
						  stringValue: @"b&ar"];

	[element setPrefix: @"objfw-test" forNamespace: @"urn:objfw:test"];
	[element addAttributeWithName: @"foo"
			  stringValue: @"b&ar"];
	[element addAttributeWithName: @"foo"
			    namespace: @"urn:objfw:test"
			  stringValue: @"bar"];

	OTAssertEqualObjects(element.XMLString,
	    @"<foo foo='b&amp;ar' objfw-test:foo='bar'>b&amp;ar</foo>");
}

- (void)testRemoveAttributeForNameNamespace
{
	OFXMLElement *element = [OFXMLElement elementWithName: @"foo"
						  stringValue: @"b&ar"];

	[element setPrefix: @"objfw-test" forNamespace: @"urn:objfw:test"];
	[element addAttributeWithName: @"foo"
			  stringValue: @"b&ar"];
	[element addAttributeWithName: @"foo"
			    namespace: @"urn:objfw:test"
			  stringValue: @"bar"];

	[element removeAttributeForName: @"foo"];
	OTAssertEqualObjects(element.XMLString,
	    @"<foo objfw-test:foo='bar'>b&amp;ar</foo>");

	[element removeAttributeForName: @"foo" namespace: @"urn:objfw:test"];
	OTAssertEqualObjects(element.XMLString, @"<foo>b&amp;ar</foo>");
}

- (void)testAddChild
{
	OFXMLElement *element;

	element = [OFXMLElement elementWithName: @"foo"];
	[element addAttributeWithName: @"foo" stringValue: @"b&ar"];
	[element addChild: [OFXMLElement elementWithName: @"bar"]];
	OTAssertEqualObjects(element.XMLString,
	    @"<foo foo='b&amp;ar'><bar/></foo>");

	element = [OFXMLElement elementWithName: @"foo"
				      namespace: @"urn:objfw:test"];
	[element setPrefix: @"objfw-test" forNamespace: @"urn:objfw:test"];
	[element addAttributeWithName: @"test" stringValue: @"test"];
	[element addChild: [OFXMLElement elementWithName: @"bar"
					       namespace: @"urn:objfw:test"]];
	OTAssertEqualObjects(element.XMLString,
	    @"<objfw-test:foo test='test'><objfw-test:bar/></objfw-test:foo>");
}

- (void)testElementsForNameNamespace
{
	OFXMLElement *element = [OFXMLElement elementWithName: @"foo"];
	OFXMLElement *bar;

	[element addChild: [OFXMLElement elementWithName: @"foo"]];
	bar = [OFXMLElement elementWithName: @"bar"
				  namespace: @"urn:objfw:test"];
	[element addChild: bar];

	OTAssertEqualObjects([element elementsForName: @"bar"
					    namespace: @"urn:objfw:test"],
	    [OFArray arrayWithObject: bar]);
}

- (void)testXMLStringWithIndentation
{
	OTAssertEqualObjects([[OFXMLElement
	    elementWithXMLString: @"<x><y><z>a\nb</z><!-- foo --></y></x>"]
	    XMLStringWithIndentation: 2],
	    @"<x>\n  <y>\n    <z>a\nb</z>\n    <!-- foo -->\n  </y>\n</x>");
}
@end
