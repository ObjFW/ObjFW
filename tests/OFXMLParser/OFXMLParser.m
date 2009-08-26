/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <stdio.h>
#include <string.h>

#import "OFXMLParser.h"

@interface ParserDelegate: OFObject
@end

@implementation ParserDelegate
-     (void)xmlParser: (OFXMLParser*)parser
  didStartTagWithName: (OFString*)name
	       prefix: (OFString*)prefix
	    namespace: (OFString*)ns
	   attributes: (OFArray*)attrs
{
	OFXMLAttribute **attrs_data;
	size_t i, attrs_count;

	printf("START\nname=\"%s\"\nprefix=\"%s\"\nns=\"%s\"\n",
	    [name cString], [prefix cString], [ns cString]);

	attrs_data = [attrs data];
	attrs_count = [attrs count];

	for (i = 0; i < attrs_count; i++) {
		OFString *attr_name = [attrs_data[i] name];
		OFString *attr_prefix = [attrs_data[i] prefix];
		OFString *attr_ns = [attrs_data[i] namespace];
		OFString *attr_value = [attrs_data[i] stringValue];

		printf("ATTR:\n      name=\"%s\"\n", [attr_name cString]);
		if (attr_prefix != nil)
			printf("      prefix=\"%s\"\n", [attr_prefix cString]);
		if (attr_ns != nil)
			printf("      ns=\"%s\"\n", [attr_ns cString]);
		printf("      value=\"%s\"\n", [attr_value cString]);
	}

	puts("");
}

-   (void)xmlParser: (OFXMLParser*)parser
  didEndTagWithName: (OFString*)name
	     prefix: (OFString*)prefix
	  namespace: (OFString*)ns
{
	printf("END\nname=\"%s\"\nprefix=\"%s\"\nns=\"%s\"\n\n",
	    [name cString], [prefix cString], [ns cString]);
}

- (void)xmlParser: (OFXMLParser*)parser
      foundString: (OFString*)string
{
	printf("STRING\n\"%s\"\n\n", [string cString]);
}

- (void)xmlParser: (OFXMLParser*)parser
     foundComment: (OFString*)comment
{
	printf("COMMENT\n\"%s\"\n\n", [comment cString]);
}

-    (OFString*)xmlParser: (OFXMLParser*)parser
  foundUnknownEntityNamed: (OFString*)entity
{
	if ([entity isEqual: @"foo"])
		return @"foobar";

	return nil;
}
@end

int
main()
{
	const char *foo = "bar<foo:bar  bar='b&amp;az'  qux:qux=\" quux \">\r\n"
	    "foo&lt;bar<qux  >bar <baz name='' test='&foo;'/>  quxbar\r\n</qux>"
	    "</foo:bar><!-- foo bar-baz -->";
	size_t len = strlen(foo);
	size_t i;
	OFXMLParser *parser = [OFXMLParser xmlParser];

	[parser setDelegate: [[ParserDelegate alloc] init]];

	/* Simulate a stream where we only get chunks */
	for (i = 0; i < len; i += 2) {
		if (i + 2 > len)
			[parser parseBuffer: foo + i
				   withSize: 1];
		else
			[parser parseBuffer: foo + i
				   withSize: 2];
	}
	/*
	for (i = 0; i < len; i++)
		[parser parseBuffer: foo + i
			   withSize: 1];
	*/

	return 0;
}
