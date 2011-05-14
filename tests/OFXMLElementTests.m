/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#import "OFXMLElement.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFAutoreleasePool.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFXMLElement";

@implementation TestsAppDelegate (OFXMLElementTests)
- (void)XMLElementTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFXMLElement *elem[4];
	OFArray *a;

	TEST(@"+[elementWithName:]",
	    (elem[0] = [OFXMLElement elementWithName: @"foo"]) &&
	    [[elem[0] XMLString] isEqual: @"<foo/>"])

	TEST(@"+[elementWithName:stringValue:]",
	    (elem[1] = [OFXMLElement elementWithName: @"foo"
					 stringValue: @"b&ar"]) &&
	    [[elem[1] XMLString] isEqual: @"<foo>b&amp;ar</foo>"])

	TEST(@"+[elementWithName:namespace:]",
	    (elem[2] = [OFXMLElement elementWithName: @"foo"
					   namespace: @"urn:objfw:test"]) &&
	    R([elem[2] addAttributeWithName: @"test"
				stringValue: @"test"]) &&
	    R([elem[2] setPrefix: @"objfw-test"
		    forNamespace: @"urn:objfw:test"]) &&
	    [[elem[2] XMLString] isEqual: @"<objfw-test:foo test='test'/>"] &&
	    (elem[3] = [OFXMLElement elementWithName: @"foo"
					   namespace: @"urn:objfw:test"]) &&
	    R([elem[3] addAttributeWithName: @"test"
				stringValue: @"test"]) &&
	    [[elem[3] XMLString] isEqual:
	    @"<foo xmlns='urn:objfw:test' test='test'/>"])

	TEST(@"+[elementWithName:namespace:stringValue:]",
	    (elem[3] = [OFXMLElement elementWithName: @"foo"
					   namespace: @"urn:objfw:test"
					 stringValue: @"x"]) &&
	    R([elem[3] setPrefix: @"objfw-test"
		    forNamespace: @"urn:objfw:test"]) &&
	    [[elem[3] XMLString] isEqual:
	    @"<objfw-test:foo>x</objfw-test:foo>"])

	TEST(@"+[elementWithCharacters:]",
	    (elem[3] = [OFXMLElement elementWithCharacters: @"<foo>"]) &&
	    [[elem[3] XMLString] isEqual: @"&lt;foo&gt;"])

	TEST(@"+[elementWithCDATA:]",
	    (elem[3] = [OFXMLElement elementWithCDATA: @"<foo>"]) &&
	    [[elem[3] XMLString] isEqual: @"<![CDATA[<foo>]]>"]);

	TEST(@"+[elementWithComment:]",
	    (elem[3] = [OFXMLElement elementWithComment: @" comment "]) &&
	    [[elem[3] XMLString] isEqual: @"<!-- comment -->"])

	TEST(@"-[addAttributeWithName:stringValue:]",
	    R([elem[0] addAttributeWithName: @"foo"
				stringValue: @"b&ar"]) &&
	    [[elem[0] XMLString] isEqual: @"<foo foo='b&amp;ar'/>"] &&
	    R([elem[1] addAttributeWithName: @"foo"
				stringValue: @"b&ar"]) &&
	    [[elem[1] XMLString] isEqual:
	    @"<foo foo='b&amp;ar'>b&amp;ar</foo>"])

	TEST(@"-[setPrefix:forNamespace:]",
	    R([elem[1] setPrefix: @"objfw-test"
		    forNamespace: @"urn:objfw:test"]))

	TEST(@"-[addAttributeWithName:namespace:stringValue:]",
	    R([elem[1] addAttributeWithName: @"foo"
				  namespace: @"urn:objfw:test"
				stringValue: @"bar"]) &&
	    R([elem[1] addAttributeWithName: @"foo"
				  namespace: @"urn:objfw:test"
				stringValue: @"ignored"]) &&
	    [[elem[1] XMLString] isEqual:
	    @"<foo foo='b&amp;ar' objfw-test:foo='bar'>b&amp;ar</foo>"])

	TEST(@"-[removeAttributeForName:namespace:]",
	    R([elem[1] removeAttributeForName: @"foo"]) &&
	    [[elem[1] XMLString] isEqual:
	    @"<foo objfw-test:foo='bar'>b&amp;ar</foo>"] &&
	    R([elem[1] removeAttributeForName: @"foo"
				    namespace: @"urn:objfw:test"]) &&
	    [[elem[1] XMLString] isEqual: @"<foo>b&amp;ar</foo>"])

	TEST(@"-[addChild:]",
	    R([elem[0] addChild: [OFXMLElement elementWithName: @"bar"]]) &&
	    [[elem[0] XMLString] isEqual:
	    @"<foo foo='b&amp;ar'><bar/></foo>"] &&
	    R([elem[2] addChild: [OFXMLElement elementWithName: @"bar"
		      namespace: @"urn:objfw:test"]]) &&
	    [[elem[2] XMLString] isEqual:
	    @"<objfw-test:foo test='test'><objfw-test:bar/></objfw-test:foo>"])

	TEST(@"+[elementWithXMLString:] and -[stringValue]",
	    [[[OFXMLElement elementWithXMLString:
	    @"<?xml version='1.0' encoding='UTF-8'?>\r\n<x>foo<![CDATA[bar]]>"
	    @"<y>b<!-- fooo -->az</y>qux</x>"] stringValue]
	    isEqual: @"foobarbazqux"])

	TEST(@"-[elementsForName:namespace:]",
	    (a = [elem[2] elementsForName: @"bar"
				namespace: @"urn:objfw:test"]) &&
	    [a count] == 1 && [[[a firstObject] XMLString] isEqual:
	    @"<bar xmlns='urn:objfw:test'/>"])

	[pool drain];
}
@end
