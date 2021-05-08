/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#import "TestsAppDelegate.h"

static OFString *module;

@implementation TestsAppDelegate (OFXMLNodeTests)
- (void)XMLNodeTests
{
	void *pool = objc_autoreleasePoolPush();
	id node1, node2, node3, node4;
	OFArray *array;

	module = @"OFXMLNode";

	TEST(@"+[elementWithName:]",
	    (node1 = [OFXMLElement elementWithName: @"foo"]) &&
	    [[node1 XMLString] isEqual: @"<foo/>"])

	TEST(@"+[elementWithName:stringValue:]",
	    (node2 = [OFXMLElement elementWithName: @"foo"
				       stringValue: @"b&ar"]) &&
	    [[node2 XMLString] isEqual: @"<foo>b&amp;ar</foo>"])

	TEST(@"+[elementWithName:namespace:]",
	    (node3 = [OFXMLElement elementWithName: @"foo"
					 namespace: @"urn:objfw:test"]) &&
	    R([node3 addAttributeWithName: @"test" stringValue: @"test"]) &&
	    R([node3 setPrefix: @"objfw-test"
		  forNamespace: @"urn:objfw:test"]) &&
	    [[node3 XMLString] isEqual: @"<objfw-test:foo test='test'/>"] &&
	    (node4 = [OFXMLElement elementWithName: @"foo"
					 namespace: @"urn:objfw:test"]) &&
	    R([node4 addAttributeWithName: @"test" stringValue: @"test"]) &&
	    [[node4 XMLString] isEqual:
	    @"<foo xmlns='urn:objfw:test' test='test'/>"])

	TEST(@"+[elementWithName:namespace:stringValue:]",
	    (node4 = [OFXMLElement elementWithName: @"foo"
					 namespace: @"urn:objfw:test"
				       stringValue: @"x"]) &&
	    R([node4 setPrefix: @"objfw-test"
		  forNamespace: @"urn:objfw:test"]) &&
	    [[node4 XMLString] isEqual: @"<objfw-test:foo>x</objfw-test:foo>"])

	TEST(@"+[charactersWithString:]",
	    (node4 = [OFXMLCharacters charactersWithString: @"<foo>"]) &&
	    [[node4 XMLString] isEqual: @"&lt;foo&gt;"])

	TEST(@"+[CDATAWithString:]",
	    (node4 = [OFXMLCDATA CDATAWithString: @"<foo>"]) &&
	    [[node4 XMLString] isEqual: @"<![CDATA[<foo>]]>"]);

	TEST(@"+[commentWithText:]",
	    (node4 = [OFXMLComment commentWithText: @" comment "]) &&
	    [[node4 XMLString] isEqual: @"<!-- comment -->"])

	module = @"OFXMLElement";

	TEST(@"-[addAttributeWithName:stringValue:]",
	    R([node1 addAttributeWithName: @"foo" stringValue: @"b&ar"]) &&
	    [[node1 XMLString] isEqual: @"<foo foo='b&amp;ar'/>"] &&
	    R([node2 addAttributeWithName: @"foo" stringValue: @"b&ar"]) &&
	    [[node2 XMLString] isEqual: @"<foo foo='b&amp;ar'>b&amp;ar</foo>"])

	TEST(@"-[setPrefix:forNamespace:]",
	    R([node2 setPrefix: @"objfw-test"
		  forNamespace: @"urn:objfw:test"]))

	TEST(@"-[addAttributeWithName:namespace:stringValue:]",
	    R([node2 addAttributeWithName: @"foo"
				namespace: @"urn:objfw:test"
			      stringValue: @"bar"]) &&
	    R([node2 addAttributeWithName: @"foo"
				namespace: @"urn:objfw:test"
			      stringValue: @"ignored"]) &&
	    [[node2 XMLString] isEqual:
	    @"<foo foo='b&amp;ar' objfw-test:foo='bar'>b&amp;ar</foo>"])

	TEST(@"-[removeAttributeForName:namespace:]",
	    R([node2 removeAttributeForName: @"foo"]) &&
	    [[node2 XMLString] isEqual:
	    @"<foo objfw-test:foo='bar'>b&amp;ar</foo>"] &&
	    R([node2 removeAttributeForName: @"foo"
				  namespace: @"urn:objfw:test"]) &&
	    [[node2 XMLString] isEqual: @"<foo>b&amp;ar</foo>"])

	TEST(@"-[addChild:]",
	    R([node1 addChild: [OFXMLElement elementWithName: @"bar"]]) &&
	    [[node1 XMLString] isEqual:
	    @"<foo foo='b&amp;ar'><bar/></foo>"] &&
	    R([node3 addChild: [OFXMLElement elementWithName: @"bar"
		    namespace: @"urn:objfw:test"]]) &&
	    [[node3 XMLString] isEqual:
	    @"<objfw-test:foo test='test'><objfw-test:bar/></objfw-test:foo>"])

	TEST(@"+[elementWithXMLString:] and -[stringValue]",
	    [[[OFXMLElement elementWithXMLString:
	    @"<?xml version='1.0' encoding='UTF-8'?>\r\n<x>foo<![CDATA[bar]]>"
	    @"<y>b<!-- fooo -->az</y>qux</x>"] stringValue]
	    isEqual: @"foobarbazqux"])

	TEST(@"-[elementsForName:namespace:]",
	    (array = [node3 elementsForName: @"bar"
				  namespace: @"urn:objfw:test"]) &&
	    array.count == 1 && [[array.firstObject XMLString] isEqual:
	    @"<bar xmlns='urn:objfw:test'/>"])

	TEST(@"-[isEqual:]",
	    [[OFXMLElement elementWithXMLString: @"<foo bar='asd'/>"] isEqual:
	    [OFXMLElement elementWithXMLString: @"<foo bar='asd'></foo>"]] &&
	    [[OFXMLElement elementWithXMLString: @"<x><y/></x>"] isEqual:
	    [OFXMLElement elementWithXMLString: @"<x><y></y></x>"]])

	TEST(@"-[XMLStringWithIndentation:]",
	    [[[OFXMLElement elementWithXMLString: @"<x><y><z>a\nb</z>"
	    @"<!-- foo --></y></x>"] XMLStringWithIndentation: 2] isEqual:
	    @"<x>\n  <y>\n    <z>a\nb</z>\n    <!-- foo -->\n  </y>\n</x>"])

	objc_autoreleasePoolPop(pool);
}
@end
