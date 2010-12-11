/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <assert.h>

#import "OFXMLElement.h"
#import "OFXMLParser.h"
#import "OFXMLElementBuilder.h"
#import "OFAutoreleasePool.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFXMLElementBuilder";
static OFXMLElement *elem = nil;

@implementation TestsAppDelegate (OFXMLElementBuilderTests)
- (void)elementBuilder: (OFXMLElementBuilder*)builder
       didBuildElement: (OFXMLElement*)elem_
{
	assert(elem == nil);
	elem = [elem_ retain];
}

- (void)XMLElementBuilderTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFXMLParser *p = [OFXMLParser parser];
	OFXMLElementBuilder *builder = [OFXMLElementBuilder elementBuilder];
	OFString *str = @"<foo>bar<![CDATA[f<oo]]>baz<qux/>"
	    " <qux xmlns:qux='urn:qux'><qux:bar/><x qux:y='z'/></qux>"
	    "</foo>";

	[p setDelegate: builder];
	[builder setDelegate: self];

	TEST(@"Building element from parsed XML",
	    R([p parseString: str]) &&
	    elem != nil && [[elem stringValue] isEqual: str])

	[elem release];
	[pool drain];
}
@end
