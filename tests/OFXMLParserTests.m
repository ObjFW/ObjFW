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

#include <string.h>

#import "OFXMLParser.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFAutoreleasePool.h"
#import "OFString.h"
#import "OFExceptions.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFXMLParser";
static int i = 0;

enum event_type {
	TAG_START,
	TAG_END,
	STRING,
	COMMENT
};

@implementation TestsAppDelegate (OFXMLParser)
- (void)xmlParserCallbackWithEventType: (enum event_type)et
				  name: (OFString*)name
				prefix: (OFString*)prefix
			     namespace: (OFString*)ns
			    attributes: (OFArray*)attrs
				string: (OFString*)string
			       comment: (OFString*)comment
{
	OFString *msg;

	i++;
	msg = [OFString stringWithFormat: @"Parsing part #%d", i];

	switch (i) {
	case 1:
		TEST(msg, et == STRING && [string isEqual: @"foo"])
		break;
	case 2:
		TEST(msg, et == TAG_START && [name isEqual: @"bar"] &&
		    prefix == nil && ns == nil && attrs == nil)
		break;
	case 3:
		TEST(msg, et == TAG_END && [name isEqual: @"bar"] &&
		    prefix == nil && ns == nil && attrs == nil)
		break;
	case 4:
		TEST(msg, et == STRING && [string isEqual: @"\n"])
		break;
	case 5:
		TEST(msg, et == TAG_START && [name isEqual: @"foobar"] &&
		    prefix == nil && [ns isEqual: @"urn:objfw:test:foobar"] &&
		    [attrs count] == 1 &&
		    /* xmlns attr */
		    [[[attrs objectAtIndex: 0] name] isEqual: @"xmlns"] &&
		    [[attrs objectAtIndex: 0] namespace] == nil &&
		    [[[attrs objectAtIndex: 0] stringValue] isEqual:
		    @"urn:objfw:test:foobar"])
		break;
	case 6:
		TEST(msg, et == STRING && [string isEqual: @"\n "])
		break;
	case 7:
		TEST(msg, et == TAG_START && [name isEqual: @"qux"] &&
		    prefix == nil && [ns isEqual: @"urn:objfw:test:foobar"] &&
		    [attrs count] == 1 &&
		    /* xmlns:foo attr */
		    [[[attrs objectAtIndex: 0] name] isEqual: @"foo"] &&
		    [[[attrs objectAtIndex: 0] namespace] isEqual:
		    @"http://www.w3.org/2000/xmlns/"] &&
		    [[[attrs objectAtIndex: 0] stringValue] isEqual:
		    @"urn:objfw:test:foo"])
		break;
	case 8:
		TEST(msg, et == STRING && [string isEqual: @"\n  "])
		break;
	case 9:
		TEST(msg, et == TAG_START && [name isEqual: @"bla"] &&
		    [prefix isEqual: @"foo"] &&
		    [ns isEqual: @"urn:objfw:test:foo"] &&
		    [attrs count] == 2 &&
		    /* foo:bla attr */
		    [[[attrs objectAtIndex: 0] name] isEqual: @"bla"] &&
		    [[[attrs objectAtIndex: 0] namespace] isEqual:
		    @"urn:objfw:test:foo"] &&
		    [[[attrs objectAtIndex: 0] stringValue] isEqual: @"bla"] &&
		    /* blafoo attr */
		    [[[attrs objectAtIndex: 1] name] isEqual: @"blafoo"] &&
		    [[[attrs objectAtIndex: 1] namespace] isEqual:
		    @"urn:objfw:test:foo"] &&
		    [[[attrs objectAtIndex: 1] stringValue] isEqual: @"foo"])
		break;
	case 10:
		TEST(msg, et == STRING && [string isEqual: @"\n   "])
		break;
	case 11:
		TEST(msg, et == TAG_START && [name isEqual: @"blup"] &&
		    prefix == nil && [ns isEqual: @"urn:objfw:test:foobar"] &&
		    [attrs count] == 2 &&
		    /* foo:qux attr */
		    [[[attrs objectAtIndex: 0] name] isEqual: @"qux"] &&
		    [[[attrs objectAtIndex: 0] namespace] isEqual:
		    @"urn:objfw:test:foo"] &&
		    [[[attrs objectAtIndex: 0] stringValue] isEqual: @"asd"] &&
		    /* quxqux attr */
		    [[[attrs objectAtIndex: 1] name] isEqual: @"quxqux"] &&
		    [[[attrs objectAtIndex: 1] namespace] isEqual:
		    @"urn:objfw:test:foobar"] &&
		    [[[attrs objectAtIndex: 1] stringValue] isEqual: @"test"])
		break;
	case 12:
		TEST(msg, et == TAG_END && [name isEqual: @"blup"] &&
		    prefix == nil && [ns isEqual: @"urn:objfw:test:foobar"])
		break;
	case 13:
		TEST(msg, et == STRING && [string isEqual: @"\n   "])
		break;
	case 14:
		TEST(msg, et == TAG_START && [name isEqual: @"bla"] &&
		    [prefix isEqual: @"bla"] &&
		    [ns isEqual: @"urn:objfw:test:bla"] && [attrs count] == 3 &&
		    /* xmlns:bla attr */
		    [[[attrs objectAtIndex: 0] name] isEqual: @"bla"] &&
		    [[[attrs objectAtIndex: 0] namespace] isEqual:
		    @"http://www.w3.org/2000/xmlns/"] &&
		    [[[attrs objectAtIndex: 0] stringValue] isEqual:
		    @"urn:objfw:test:bla"] &&
		    /* qux attr */
		    [[[attrs objectAtIndex: 1] name] isEqual: @"qux"] &&
		    [[[attrs objectAtIndex: 1] namespace] isEqual:
		    @"urn:objfw:test:bla"] &&
		    [[[attrs objectAtIndex: 1] stringValue] isEqual: @"qux"] &&
		    /* bla:foo attr */
		    [[[attrs objectAtIndex: 2] name] isEqual: @"foo"] &&
		    [[[attrs objectAtIndex: 2] namespace] isEqual:
		    @"urn:objfw:test:bla"] &&
		    [[[attrs objectAtIndex: 2] stringValue] isEqual: @"blafoo"])
		break;
	case 15:
		TEST(msg, et == TAG_END && [name isEqual: @"bla"] &&
		    [prefix isEqual: @"bla"] &&
		    [ns isEqual: @"urn:objfw:test:bla"])
		break;
	case 16:
		TEST(msg, et == STRING && [string isEqual: @"\n   "])
		break;
	case 17:
		TEST(msg, et == TAG_START && [name isEqual: @"abc"] &&
		    prefix == nil && [ns isEqual: @"urn:objfw:test:abc"] &&
		    [attrs count] == 3 &&
		    /* xmlns attr */
		    [[[attrs objectAtIndex: 0] name] isEqual: @"xmlns"] &&
		    [[attrs objectAtIndex: 0] namespace] == nil &&
		    [[[attrs objectAtIndex: 0] stringValue] isEqual:
		    @"urn:objfw:test:abc"] &&
		    /* abc attr */
		    [[[attrs objectAtIndex: 1] name] isEqual: @"abc"] &&
		    [[[attrs objectAtIndex: 1] namespace] isEqual:
		    @"urn:objfw:test:abc"] &&
		    [[[attrs objectAtIndex: 1] stringValue] isEqual: @"abc"] &&
		    /* foo:abc attr */
		    [[[attrs objectAtIndex: 2] name] isEqual: @"abc"] &&
		    [[[attrs objectAtIndex: 2] namespace] isEqual:
		    @"urn:objfw:test:foo"] &&
		    [[[attrs objectAtIndex: 2] stringValue] isEqual: @"abc"])
		break;
	case 18:
		TEST(msg, et == TAG_END && [name isEqual: @"abc"] &&
		    prefix == nil && [ns isEqual: @"urn:objfw:test:abc"])
		break;
	case 19:
		TEST(msg, et == STRING && [string isEqual: @"\n  "])
		break;
	case 20:
		TEST(msg, et == TAG_END && [name isEqual: @"bla"] &&
		    [prefix isEqual: @"foo"] &&
		    [ns isEqual: @"urn:objfw:test:foo"])
		break;
	case 21:
		TEST(msg, et == STRING && [string isEqual: @"\n  "])
		break;
	case 22:
		TEST(msg, et == COMMENT && [comment isEqual: @"commänt"])
		break;
	case 23:
		TEST(msg, et == STRING && [string isEqual: @"\n "])
		break;
	case 24:
		TEST(msg, et == TAG_END && [name isEqual: @"qux"] &&
		    prefix == nil && [ns isEqual: @"urn:objfw:test:foobar"])
		break;
	case 25:
		TEST(msg, et == STRING && [string isEqual: @"\n"])
		break;
	case 26:
		TEST(msg, et == TAG_END && [name isEqual: @"foobar"] &&
		    prefix == nil && [ns isEqual: @"urn:objfw:test:foobar"])
		break;
	}
}

-     (void)xmlParser: (OFXMLParser*)parser
  didStartTagWithName: (OFString*)name
	       prefix: (OFString*)prefix
	    namespace: (OFString*)ns
	   attributes: (OFArray*)attrs
{
	[self xmlParserCallbackWithEventType: TAG_START
					name: name
				      prefix: prefix
				   namespace: ns
				  attributes: attrs
				      string: nil
				     comment: nil];
}

-   (void)xmlParser: (OFXMLParser*)parser
  didEndTagWithName: (OFString*)name
	     prefix: (OFString*)prefix
	  namespace: (OFString*)ns
{
	[self xmlParserCallbackWithEventType: TAG_END
					name: name
				      prefix: prefix
				   namespace: ns
				  attributes: nil
				      string: nil
				     comment: nil];
}

- (void)xmlParser: (OFXMLParser*)parser
      foundString: (OFString*)string
{
	[self xmlParserCallbackWithEventType: STRING
					name: nil
				      prefix: nil
				   namespace: nil
				  attributes: nil
				      string: string
				     comment: nil];
}

- (void)xmlParser: (OFXMLParser*)parser
     foundComment: (OFString*)comment
{
	[self xmlParserCallbackWithEventType: COMMENT
					name: nil
				      prefix: nil
				   namespace: nil
				  attributes: nil
				      string: nil
				     comment: comment];
}

-    (OFString*)xmlParser: (OFXMLParser*)parser
  foundUnknownEntityNamed: (OFString*)entity
{
	if ([entity isEqual: @"foo"])
		return @"foobar";

	return nil;
}

- (void)XMLParserTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFXMLParser *parser;
	const char *str = "foo<bar/>\n"
	    "<foobar xmlns='urn:objfw:test:foobar'>\n"
	    " <qux xmlns:foo='urn:objfw:test:foo'>\n"
	    "  <foo:bla foo:bla='&#x62;&#x6c;&#x61;' blafoo='foo'>\n"
	    "   <blup foo:qux='asd' quxqux='test'/>\n"
	    "   <bla:bla\rxmlns:bla=\"urn:objfw:test:bla\" qux='qux'\r\n"
	    "    bla:foo='blafoo'/>\n"
	    "   <abc xmlns='urn:objfw:test:abc' abc='abc' foo:abc='abc'/>\n"
	    "  </foo:bla>\n"
	    "  <!-- commänt -->\n"
	    " </qux>\n"
	    "</foobar>";
	size_t j, len;

	TEST(@"+[xmlParser]", (parser = [OFXMLParser xmlParser]))

	TEST(@"-[setDelegate:]", R([parser setDelegate: self]))

	/* Simulate a stream where we only get chunks */
	len = strlen(str);

	for (j = 0; j < len; j+= 2) {
		if (j + 2 > len)
			[parser parseBuffer: str + j
				   withSize: 1];
		else
			[parser parseBuffer: str + j
				   withSize: 2];
	}

	TEST(@"Checking if everything was parsed", i == 26)

	[pool drain];
}
@end
