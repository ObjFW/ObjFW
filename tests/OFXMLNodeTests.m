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

#import "OFXMLElement.h"
#import "OFXMLCharacters.h"
#import "OFXMLCDATA.h"
#import "OFXMLComment.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFAutoreleasePool.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFXMLNode";

@implementation TestsAppDelegate (OFXMLNodeTests)
- (void)XMLNodeTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	id nodes[4];
	OFArray *a;

	TEST(@"+[elementWithName:]",
	    (nodes[0] = [OFXMLElement elementWithName: @"foo"]) &&
	    [[nodes[0] XMLString] isEqual: @"<foo/>"])

	TEST(@"+[elementWithName:stringValue:]",
	    (nodes[1] = [OFXMLElement elementWithName: @"foo"
					  stringValue: @"b&ar"]) &&
	    [[nodes[1] XMLString] isEqual: @"<foo>b&amp;ar</foo>"])

	TEST(@"+[elementWithName:namespace:]",
	    (nodes[2] = [OFXMLElement elementWithName: @"foo"
					    namespace: @"urn:objfw:test"]) &&
	    R([nodes[2] addAttributeWithName: @"test"
				 stringValue: @"test"]) &&
	    R([nodes[2] setPrefix: @"objfw-test"
		     forNamespace: @"urn:objfw:test"]) &&
	    [[nodes[2] XMLString] isEqual: @"<objfw-test:foo test='test'/>"] &&
	    (nodes[3] = [OFXMLElement elementWithName: @"foo"
					    namespace: @"urn:objfw:test"]) &&
	    R([nodes[3] addAttributeWithName: @"test"
				 stringValue: @"test"]) &&
	    [[nodes[3] XMLString] isEqual:
	    @"<foo xmlns='urn:objfw:test' test='test'/>"])

	TEST(@"+[elementWithName:namespace:stringValue:]",
	    (nodes[3] = [OFXMLElement elementWithName: @"foo"
					    namespace: @"urn:objfw:test"
					  stringValue: @"x"]) &&
	    R([nodes[3] setPrefix: @"objfw-test"
		     forNamespace: @"urn:objfw:test"]) &&
	    [[nodes[3] XMLString] isEqual:
	    @"<objfw-test:foo>x</objfw-test:foo>"])

	TEST(@"+[charactersWithString:]",
	    (nodes[3] = [OFXMLCharacters charactersWithString: @"<foo>"]) &&
	    [[nodes[3] XMLString] isEqual: @"&lt;foo&gt;"])

	TEST(@"+[CDATAWithString:]",
	    (nodes[3] = [OFXMLCDATA CDATAWithString: @"<foo>"]) &&
	    [[nodes[3] XMLString] isEqual: @"<![CDATA[<foo>]]>"]);

	TEST(@"+[commentWithString:]",
	    (nodes[3] = [OFXMLComment commentWithString: @" comment "]) &&
	    [[nodes[3] XMLString] isEqual: @"<!-- comment -->"])

	module = @"OFXMLElement";

	TEST(@"-[addAttributeWithName:stringValue:]",
	    R([nodes[0] addAttributeWithName: @"foo"
				 stringValue: @"b&ar"]) &&
	    [[nodes[0] XMLString] isEqual: @"<foo foo='b&amp;ar'/>"] &&
	    R([nodes[1] addAttributeWithName: @"foo"
				 stringValue: @"b&ar"]) &&
	    [[nodes[1] XMLString] isEqual:
	    @"<foo foo='b&amp;ar'>b&amp;ar</foo>"])

	TEST(@"-[setPrefix:forNamespace:]",
	    R([nodes[1] setPrefix: @"objfw-test"
		     forNamespace: @"urn:objfw:test"]))

	TEST(@"-[addAttributeWithName:namespace:stringValue:]",
	    R([nodes[1] addAttributeWithName: @"foo"
				   namespace: @"urn:objfw:test"
				 stringValue: @"bar"]) &&
	    R([nodes[1] addAttributeWithName: @"foo"
				   namespace: @"urn:objfw:test"
				 stringValue: @"ignored"]) &&
	    [[nodes[1] XMLString] isEqual:
	    @"<foo foo='b&amp;ar' objfw-test:foo='bar'>b&amp;ar</foo>"])

	TEST(@"-[removeAttributeForName:namespace:]",
	    R([nodes[1] removeAttributeForName: @"foo"]) &&
	    [[nodes[1] XMLString] isEqual:
	    @"<foo objfw-test:foo='bar'>b&amp;ar</foo>"] &&
	    R([nodes[1] removeAttributeForName: @"foo"
				     namespace: @"urn:objfw:test"]) &&
	    [[nodes[1] XMLString] isEqual: @"<foo>b&amp;ar</foo>"])

	TEST(@"-[addChild:]",
	    R([nodes[0] addChild: [OFXMLElement elementWithName: @"bar"]]) &&
	    [[nodes[0] XMLString] isEqual:
	    @"<foo foo='b&amp;ar'><bar/></foo>"] &&
	    R([nodes[2] addChild: [OFXMLElement elementWithName: @"bar"
		       namespace: @"urn:objfw:test"]]) &&
	    [[nodes[2] XMLString] isEqual:
	    @"<objfw-test:foo test='test'><objfw-test:bar/></objfw-test:foo>"])

	TEST(@"+[elementWithXMLString:] and -[stringValue]",
	    [[[OFXMLElement elementWithXMLString:
	    @"<?xml version='1.0' encoding='UTF-8'?>\r\n<x>foo<![CDATA[bar]]>"
	    @"<y>b<!-- fooo -->az</y>qux</x>"] stringValue]
	    isEqual: @"foobarbazqux"])

	TEST(@"-[elementsForName:namespace:]",
	    (a = [nodes[2] elementsForName: @"bar"
				 namespace: @"urn:objfw:test"]) &&
	    [a count] == 1 && [[[a firstObject] XMLString] isEqual:
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

	[pool drain];
}
@end
