/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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
#import "OFXMLParser.h"
#import "OFXMLElementBuilder.h"
#import "OFAutoreleasePool.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFXMLElementBuilder";
static OFXMLNode *nodes[2];
static size_t i = 0;

@implementation TestsAppDelegate (OFXMLElementBuilderTests)
- (void)elementBuilder: (OFXMLElementBuilder*)builder
       didBuildElement: (OFXMLElement*)element
{
	OF_ENSURE(i == 0);
	nodes[i++] = [element retain];
}

-   (void)elementBuilder: (OFXMLElementBuilder*)builder
  didBuildParentlessNode: (OFXMLNode*)node
{
	OF_ENSURE(i == 1);
	nodes[i++] = [node retain];
}

- (void)XMLElementBuilderTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFXMLParser *p = [OFXMLParser parser];
	OFXMLElementBuilder *builder = [OFXMLElementBuilder elementBuilder];
	OFString *str = @"<foo>bar<![CDATA[f<oo]]>baz<qux/>"
	    " <qux xmlns:qux='urn:qux'><?asd?><qux:bar/><x qux:y='z'/></qux>"
	    "</foo>";

	[p setDelegate: builder];
	[builder setDelegate: self];

	TEST(@"Building elements from parsed XML",
	    R([p parseString: str]) &&
	    nodes[0] != nil && [[nodes[0] XMLString] isEqual: str] &&
	    R([p parseString: @"<!--foo-->"]) &&
	    nodes[1] != nil && [[nodes[1] XMLString] isEqual: @"<!--foo-->"] &&
	    i == 2)

	[nodes[0] release];
	[nodes[1] release];
	[pool drain];
}
@end
