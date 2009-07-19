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

@interface ParserDelegate: OFObject <OFXMLParserDelegate>
@end

@implementation ParserDelegate
-     (BOOL)xmlParser: (OFXMLParser*)parser
  didStartTagWithName: (OFString*)name
	       prefix: (OFString*)prefix
	    namespace: (OFString*)ns
	   attributes: (OFDictionary*)attrs
{
	printf("START\nname=\"%s\"\nprefix=\"%s\"\nns=\"%s\"\n",
	    [name cString], [prefix cString], [ns cString]);

	if (attrs) {
		OFIterator *iter = [attrs iterator];

		for (;;) {
			of_iterator_pair_t pair;

			pair = [iter nextKeyObjectPair];

			if (pair.key == nil || pair.object == nil)
				break;

			printf("ATTR: \"%s\"=\"%s\"\n",
			    [pair.key cString], [pair.object cString]);
		}
	}

	puts("");

	return YES;
}

-   (BOOL)xmlParser: (OFXMLParser*)parser
  didEndTagWithName: (OFString*)name
	     prefix: (OFString*)prefix
	  namespace: (OFString*)ns
{
	printf("END\nname=\"%s\"\nprefix=\"%s\"\nns=\"%s\"\n\n",
	    [name cString], [prefix cString], [ns cString]);

	return YES;
}

- (BOOL)xmlParser: (OFXMLParser*)parser
      foundString: (OFString*)string
{
	printf("STRING\n\"%s\"\n\n", [string cString]);

	return YES;
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
	const char *foo = "bar<foo:bar  bar='b&amp;az'  qux=\"quux\">foo&lt;bar"
	    "<qux  >bar<baz name='' test='&foo;'/>quxbar</xasd>";
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
