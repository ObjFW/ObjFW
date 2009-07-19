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

#import "OFXMLElement.h"

#ifndef _WIN32
#define ZD "%zd"
#else
#define ZD "%u"
#endif

#define NUM_TESTS 5
#define SUCCESS								\
	printf("\r\033[1;%dmTests successful: " ZD "/%d\033[0m",	\
	    (i == NUM_TESTS - 1 ? 32 : 33), i + 1, NUM_TESTS);		\
	fflush(stdout);
#define FAIL								\
	printf("\r\033[K\033[1;31mTest " ZD "/%d failed!\033[m\n",	\
	    i + 1, NUM_TESTS);						\
	return 1;
#define CHECK(cond)							\
	if (cond) {							\
		SUCCESS							\
	} else {							\
		FAIL							\
	}								\
	i++;
#define CHECK_EXCEPT(code, exception)					\
	@try {								\
		code;							\
		FAIL							\
	} @catch (exception *e) {					\
		SUCCESS							\
	}								\
	i++;

int
main()
{
	size_t i = 0;

	OFXMLElement *elem;

	elem = [OFXMLElement elementWithName: @"foo"];
	CHECK([[elem string] isEqual: @"<foo/>"]);

	[elem addAttributeWithName: @"foo"
		       stringValue: @"b&ar"];
	CHECK([[elem string] isEqual: @"<foo foo='b&amp;ar'/>"])

	[elem addChild: [OFXMLElement elementWithName: @"bar"]];
	CHECK([[elem string] isEqual: @"<foo foo='b&amp;ar'><bar/></foo>"])

	elem = [OFXMLElement elementWithName: @"foo"
				 stringValue: @"b&ar"];
	CHECK([[elem string] isEqual: @"<foo>b&amp;ar</foo>"])

	[elem addAttributeWithName: @"foo"
		       stringValue: @"b&ar"];
	CHECK([[elem string] isEqual: @"<foo foo='b&amp;ar'>b&amp;ar</foo>"])

	puts("");

	return 0;
}
