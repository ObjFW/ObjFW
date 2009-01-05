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

#import "config.h"

#import <stdio.h>
#import <stdlib.h>
#import <string.h>

#import "OFXMLFactory.h"

#define NUM_TESTS 10

#ifndef _WIN32
#define ZD "zd"
#else
#define ZD "u"
#endif

static size_t i;

inline void
check_result(char *result, const char *should)
{
	i++;

	if (!strcmp(result, should)) {
		printf("\r\033[1;%dmTests successful: %2" ZD "/%d\033[0m",
		    (i == NUM_TESTS ? 32 : 33), i, NUM_TESTS);
		fflush(stdout);
	} else {
		printf("\r\033[K\033[1;31mTest %" ZD "/%d failed!\033[0m\n",
		    i, NUM_TESTS);
		printf("%s is NOT expected result!\n", result);
		exit(1);
	}

	free(result);
}

inline void
test_concat()
{
	const char *c1 = "<foo>", *c2 = "bar", *c3 = "<test/>";
	char *s1, *s2, *s3;
	char *strs[4];

	if ((s1 = malloc(strlen(c1) + 1)) == NULL ||
	    (s2 = malloc(strlen(c2) + 1)) == NULL ||
	    (s3 = malloc(strlen(c3) + 1)) == NULL)
		exit(1);

	strncpy(s1, c1, strlen(c1) + 1);
	strncpy(s2, c2, strlen(c2) + 1);
	strncpy(s3, c3, strlen(c3) + 1);

	strs[0] = s1;
	strs[1] = s2;
	strs[2] = s3;
	strs[3] = NULL;

	check_result([OFXMLFactory concatAndFreeCStrings: strs],
	    "<foo>bar<test/>");
}

inline void
test_create_stanza()
{
	check_result([OFXMLFactory createStanza: "foo"
				   withCloseTag: NO
					andData: NULL,
						 NULL],
	    "<foo>");

	check_result([OFXMLFactory createStanza: "foo"
				   withCloseTag: NO
					andData: NULL,
						 "bar", "baz",
						 "blub", "asd",
						 NULL],
	    "<foo bar='baz' blub='asd'>");
	check_result([OFXMLFactory createStanza: "foo"
				   withCloseTag: YES
					andData: NULL,
						 NULL],
	    "<foo/>");
	check_result([OFXMLFactory createStanza: "foo"
				   withCloseTag: YES
					andData: "bar",
						 NULL],
	    "<foo>bar</foo>");
	check_result([OFXMLFactory createStanza: "foo"
				   withCloseTag: YES
					andData: NULL,
						 "bar", "b&az",
						 NULL],
	    "<foo bar='b&amp;az'/>");
	check_result([OFXMLFactory createStanza: "foo"
				   withCloseTag: YES
					andData: "bar",
						 "bar", "b'az",
						 NULL],
	    "<foo bar='b&apos;az'>bar</foo>");
	check_result([OFXMLFactory createStanza: "foo"
				   withCloseTag: YES
					andData: NULL,
						 "bar", "b&az",
						 "x", "asd\"",
						 NULL],
	    "<foo bar='b&amp;az' x='asd&quot;'/>");
	check_result([OFXMLFactory createStanza: "foo"
				   withCloseTag: YES
					andData: "bar",
						 "bar", "b'az",
						 "x", "y",
						 "a", "b",
						 NULL],
	    "<foo bar='b&apos;az' x='y' a='b'>bar</foo>");
}

inline void
test_escape()
{
	check_result([OFXMLFactory escapeCString: "<hallo> &welt'\"!&"],
	    "&lt;hallo&gt; &amp;welt&apos;&quot;!&amp;");
}

int main()
{
	i = 0;
	test_escape();
       	test_create_stanza();
       	test_concat();
	puts("");

	return 0;
}
