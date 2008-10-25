/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import <stdio.h>
#import <stdlib.h>
#import <string.h>

#import <assert.h>

#import "OFXMLFactory.h"

/* TODO: Do not only print, but check if it's the output it should be */

inline int
test_concat()
{
	const char *c1 = "<foo>", *c2 = "bar", *c3 = "<test/>";
	char *s1, *s2, *s3, *str;
	char *strs[4];

	if ((s1 = malloc(strlen(c1) + 1)) == NULL ||
	    (s2 = malloc(strlen(c2) + 1)) == NULL ||
	    (s3 = malloc(strlen(c3) + 1)) == NULL)
		return 1;

	strncpy(s1, c1, strlen(c1) + 1);
	strncpy(s2, c2, strlen(c2) + 1);
	strncpy(s3, c3, strlen(c3) + 1);

	strs[0] = s1;
	strs[1] = s2;
	strs[2] = s3;
	strs[3] = NULL;

	puts((str = [OFXMLFactory concatAndFreeCStrings: strs]));
	free(str);

	return 0;
}

inline int
test_create_stanza()
{
	char *xml;

	xml = [OFXMLFactory createStanza: "foo"
			    withCloseTag: NO
				andCData: NULL,
					  NULL];
	puts(xml);
	free(xml);

	xml = [OFXMLFactory createStanza: "foo"
			    withCloseTag: NO
				andCData: NULL,
					  "bar", "baz",
					  "blub", "asd",
					  NULL];
	puts(xml);
	free(xml);

	xml = [OFXMLFactory createStanza: "foo"
			    withCloseTag: YES
				andCData: NULL,
					  NULL];
	puts(xml);
	free(xml);

	xml = [OFXMLFactory createStanza: "foo"
			    withCloseTag: YES
				andCData: "bar",
					  NULL];
	puts(xml);
	free(xml);

	xml = [OFXMLFactory createStanza: "foo"
			    withCloseTag: YES
				andCData: NULL,
					  "bar", "b&az",
					  NULL];
	puts(xml);
	free(xml);

	xml = [OFXMLFactory createStanza: "foo"
			    withCloseTag: YES
				andCData: "bar",
					  "bar", "b'az",
					  NULL];
	puts(xml);
	free(xml);

	xml = [OFXMLFactory createStanza: "foo"
			    withCloseTag: YES
				andCData: NULL,
					  "bar", "b&az",
					  "x", "asd\"",
					  NULL];
	puts(xml);
	free(xml);

	xml = [OFXMLFactory createStanza: "foo"
			    withCloseTag: YES
				andCData: "bar",
					  "bar", "b'az",
					  "x", "y",
					  "a", "b",
					  NULL];
	puts(xml);
	free(xml);

	return 0;
}

inline int
test_escape()
{
	char *tmp;

	tmp = [OFXMLFactory escapeCString: "<hallo> &welt'\"!&"];
	puts(tmp);
	free(tmp);

	return 0;
}

int main()
{
	assert(test_escape() == 0);
	assert(test_create_stanza() == 0);
	assert(test_concat() == 0);

	return 0;
}
