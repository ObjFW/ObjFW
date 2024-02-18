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

@interface OFXMLElementBuilderTests: OTTestCase <OFXMLElementBuilderDelegate>
{
	OFXMLNode *_nodes[2];
	size_t _i;
}
@end

@implementation OFXMLElementBuilderTests
- (void)dealloc
{
	[_nodes[0] release];
	[_nodes[1] release];

	[super dealloc];
}

- (void)elementBuilder: (OFXMLElementBuilder *)builder
       didBuildElement: (OFXMLElement *)element
{
	OTAssertEqual(_i, 0);
	_nodes[_i++] = [element retain];
}

- (void)elementBuilder: (OFXMLElementBuilder *)builder
    didBuildOrphanNode: (OFXMLNode *)node
{
	OTAssertEqual(_i, 1);
	_nodes[_i++] = [node retain];
}

- (void)testElementBuilder
{
	OFXMLParser *parser = [OFXMLParser parser];
	OFXMLElementBuilder *builder = [OFXMLElementBuilder builder];
	OFString *string = @"<foo>bar<![CDATA[f<oo]]>baz<qux/>"
	    " <qux xmlns:qux='urn:qux'><?asd?><qux:bar/><x qux:y='z'/></qux>"
	    "</foo>";

	parser.delegate = builder;
	builder.delegate = self;

	[parser parseString: string];
	OTAssertEqualObjects(_nodes[0].XMLString, string);

	[parser parseString: @"<!--foo-->"];
	OTAssertEqualObjects(_nodes[1].XMLString, @"<!--foo-->");

	OTAssertEqual(_i, 2);
}
@end
