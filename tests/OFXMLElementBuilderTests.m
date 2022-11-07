/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

static OFString *const module = @"OFXMLElementBuilder";
static OFXMLNode *nodes[2];
static size_t i = 0;

@implementation TestsAppDelegate (OFXMLElementBuilderTests)
- (void)elementBuilder: (OFXMLElementBuilder *)builder
       didBuildElement: (OFXMLElement *)element
{
	OFEnsure(i == 0);
	nodes[i++] = [element retain];
}

- (void)elementBuilder: (OFXMLElementBuilder *)builder
    didBuildOrphanNode: (OFXMLNode *)node
{
	OFEnsure(i == 1);
	nodes[i++] = [node retain];
}

- (void)XMLElementBuilderTests
{
	void *pool = objc_autoreleasePoolPush();
	OFXMLParser *parser = [OFXMLParser parser];
	OFXMLElementBuilder *builder = [OFXMLElementBuilder builder];
	OFString *string = @"<foo>bar<![CDATA[f<oo]]>baz<qux/>"
	    " <qux xmlns:qux='urn:qux'><?asd?><qux:bar/><x qux:y='z'/></qux>"
	    "</foo>";

	parser.delegate = builder;
	builder.delegate = self;

	TEST(@"Building elements from parsed XML",
	    R([parser parseString: string]) &&
	    nodes[0] != nil && [nodes[0].XMLString isEqual: string] &&
	    R([parser parseString: @"<!--foo-->"]) &&
	    nodes[1] != nil && [nodes[1].XMLString isEqual: @"<!--foo-->"] &&
	    i == 2)

	[nodes[0] release];
	[nodes[1] release];
	objc_autoreleasePoolPop(pool);
}
@end
