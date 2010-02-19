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

#import "main.h"

static OFString *module = @"OFXMLParser";
static int i = 0;

enum event_type {
	TAG_START,
	TAG_END,
	STRING,
	COMMENT
};

static void
callback(enum event_type et, OFString *name, OFString *prefix, OFString *ns,
    OFArray *attrs, OFString *string, OFString *comment)
{
	OFString *msg;
	id *carray;
	size_t count;

	i++;
	msg = [OFString stringWithFormat: @"Parsing part #%d", i];

	switch (i) {
	case 1:
	case 5:
		TEST(msg, et == STRING && [string isEqual: @"bar"])
		break;
	case 2:
		/* FIXME: Namespace */
		carray = [attrs cArray];
		count = [attrs count];

		TEST(msg, et == TAG_START && [name isEqual: @"bar"] &&
		    [prefix isEqual: @"foo"] && ns == nil &&
		    attrs != nil && count == 2 &&
		    /* Attribute 1 */
		    [[carray[0] name] isEqual: @"bar"] &&
		    [carray[0] prefix] == nil &&
		    [[carray[0] stringValue] isEqual: @"b&az"] &&
		    [carray[0] namespace] == nil &&
		    /* Attribute 2 */
		    [[carray[1] name] isEqual: @"qux"] &&
		    [[carray[1] prefix] isEqual: @"qux"] &&
		    [[carray[1] stringValue] isEqual: @" quux "] &&
		    [carray[1] namespace] == nil)
		break;
	case 3:
		TEST(msg, et == STRING && [string isEqual: @"foo<bar"])
		break;
	case 4:
		TEST(msg, et == TAG_START && [name isEqual: @"qux"] &&
		    prefix == nil && ns == nil)
		break;
	case 6:
		carray = [attrs cArray];
		count = [attrs count];

		TEST(msg, et == TAG_START && [name isEqual: @"baz"] &&
		    prefix == nil && ns == nil && attrs != nil && count == 2 &&
		    /* Attribute 1 */
		    [[carray[0] name] isEqual: @"name"] &&
		    [carray[0] prefix] == nil &&
		    [[carray[0] stringValue] isEqual: @""] &&
		    [carray[0] namespace] == nil &&
		    /* Attribute 2 */
		    [[carray[1] name] isEqual: @"test"] &&
		    [carray[1] prefix] == nil &&
		    [[carray[1] stringValue] isEqual: @"foobar"] &&
		    [carray[1] namespace] == nil)
		break;
	case 7:
		TEST(msg, et == TAG_END && [name isEqual: @"baz"] &&
		    prefix == nil && ns == nil)
		break;
	case 8:
		TEST(msg, et == STRING && [string isEqual: @"quxbar"])
		break;
	case 9:
		TEST(msg, et == TAG_END && [name isEqual: @"qux"] &&
		    prefix == nil && ns == nil)
		break;
	case 10:
		/* FIXME: Namespace */
		TEST(msg, et == TAG_END && [name isEqual: @"bar"] &&
		    [prefix isEqual: @"foo"] && ns == nil)
		break;
	case 11:
		TEST(msg, et == COMMENT && [comment isEqual: @"foo bär-baz"])
		break;
	default:
		TEST(msg, NO)
		break;
	}
}

@interface ParserDelegate: OFObject
@end

@implementation ParserDelegate
-     (void)xmlParser: (OFXMLParser*)parser
  didStartTagWithName: (OFString*)name
	       prefix: (OFString*)prefix
	    namespace: (OFString*)ns
	   attributes: (OFArray*)attrs
{
	callback(TAG_START, name, prefix, ns, attrs, nil, nil);
}

-   (void)xmlParser: (OFXMLParser*)parser
  didEndTagWithName: (OFString*)name
	     prefix: (OFString*)prefix
	  namespace: (OFString*)ns
{
	callback(TAG_END, name, prefix, ns, nil, nil, nil);
}

- (void)xmlParser: (OFXMLParser*)parser
      foundString: (OFString*)string
{
	callback(STRING, nil, nil, nil, nil, string, nil);
}

- (void)xmlParser: (OFXMLParser*)parser
     foundComment: (OFString*)comment
{
	callback(COMMENT, nil, nil, nil, nil, nil, comment);
}

-    (OFString*)xmlParser: (OFXMLParser*)parser
  foundUnknownEntityNamed: (OFString*)entity
{
	if ([entity isEqual: @"foo"])
		return @"foobar";

	return nil;
}
@end

void
xmlparser_tests()
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFXMLParser *parser;
	const char *str = "bar<foo:bar  bar='b&amp;az'  qux:qux=\" quux \">\r\n"
	    "foo&lt;bar<qux  >bar <baz name='' test='&foo;'/>  quxbar\r\n</qux>"
	    "</foo:bar><!-- foo bär-baz -->";
	size_t j, len;

	TEST(@"+[xmlParser]", (parser = [OFXMLParser xmlParser]))

	TEST(@"-[setDelegate:]",
	    [parser setDelegate: [[[ParserDelegate alloc] init] autorelease]])

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

	TEST(@"Checking if everything was parsed", i == 11)

	[pool drain];
}
