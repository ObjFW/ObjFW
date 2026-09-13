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
	objc_release(_nodes[0]);
	objc_release(_nodes[1]);

	[super dealloc];
}

- (void)elementBuilder: (OFXMLElementBuilder *)builder
       didBuildElement: (OFXMLElement *)element
{
	OTAssertEqual(_i, 0);
	_nodes[_i++] = objc_retain(element);
}

- (void)elementBuilder: (OFXMLElementBuilder *)builder
    didBuildOrphanNode: (OFXMLNode *)node
{
	OTAssertEqual(_i, 1);
	_nodes[_i++] = objc_retain(node);
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
