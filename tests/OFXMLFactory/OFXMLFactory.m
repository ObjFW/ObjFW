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

#import "config.h"

#define _ISOC99_SOURCE

#import <stdlib.h>
#import <string.h>
#import <wchar.h>

#import "OFXMLFactory.h"

#define NUM_TESTS 10

static int i;

inline void
check_result(char *result, const char *should)
{
	/* Use wprintf here so we don't mix printf and wprintf! */
	i++;

	if (!strcmp(result, should)) {
		wprintf(L"\r\033[1;%dmchar* tests successful:    %2d/%d\033[0m",
		    (i == NUM_TESTS ? 32 : 33), i, NUM_TESTS);
		fflush(stdout);
	} else {
		wprintf(L"\r\033[K\033[1;31mchar* test %d/%d failed!\033[0m\n",
		    i, NUM_TESTS);
		wprintf(L"%s is NOT expected result!\n", result);
		exit(1);
	}

	free(result);
}

inline void
check_result_wide(wchar_t *result, const wchar_t *should)
{
	i++;

	if (!wcscmp(result, should)) {
		wprintf(L"\r\033[1;%dmwchar_t* tests successful: %2d/%d\033[0m",
		    (i == NUM_TESTS ? 32 : 33), i, NUM_TESTS);
		fflush(stdout);
	} else {
		wprintf(L"\r\033[K\033[1;31mwchar_t* test %d/%d failed!\033[0m"
		    "\n", i, NUM_TESTS);
		wprintf(L"%s is NOT expected result!\n", result);
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
test_concat_wide()
{
	const wchar_t *c1 = L"<foo>", *c2 = L"bar", *c3 = L"<test/>";
	wchar_t *s1, *s2, *s3;
	wchar_t *strs[4];

	if ((s1 = malloc((wcslen(c1) + 1) * sizeof(wchar_t))) == NULL ||
	    (s2 = malloc((wcslen(c2) + 1) * sizeof(wchar_t))) == NULL ||
	    (s3 = malloc((wcslen(c3) + 1) * sizeof(wchar_t))) == NULL)
		exit(1);

	wcsncpy(s1, c1, wcslen(c1) + 1);
	wcsncpy(s2, c2, wcslen(c2) + 1);
	wcsncpy(s3, c3, wcslen(c3) + 1);

	strs[0] = s1;
	strs[1] = s2;
	strs[2] = s3;
	strs[3] = NULL;

	check_result_wide([OFXMLFactory concatAndFreeWideCStrings: strs],
	    L"<foo>bar<test/>");
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
test_create_stanza_wide()
{
	check_result_wide([OFXMLFactory createWideStanza: L"foo"
					    withCloseTag: NO
						 andData: NULL,
							  NULL],
	    L"<foo>");

	check_result_wide([OFXMLFactory createWideStanza: L"foo"
					    withCloseTag: NO
						 andData: NULL,
							  L"bar", L"baz",
							  L"blub", L"asd",
							  NULL],
	    L"<foo bar='baz' blub='asd'>");
	check_result_wide([OFXMLFactory createWideStanza: L"foo"
					    withCloseTag: YES
						 andData: NULL,
							  NULL],
	    L"<foo/>");
	check_result_wide([OFXMLFactory createWideStanza: L"foo"
					    withCloseTag: YES
						 andData: L"bar",
							  NULL],
	    L"<foo>bar</foo>");
	check_result_wide([OFXMLFactory createWideStanza: L"foo"
					    withCloseTag: YES
						 andData: NULL,
							  L"bar", L"b&az",
							  NULL],
	    L"<foo bar='b&amp;az'/>");
	check_result_wide([OFXMLFactory createWideStanza: L"foo"
					    withCloseTag: YES
						 andData: L"bar",
							  L"bar", L"b'az",
							  NULL],
	    L"<foo bar='b&apos;az'>bar</foo>");
	check_result_wide([OFXMLFactory createWideStanza: L"foo"
					    withCloseTag: YES
						 andData: NULL,
							  L"bar", L"b&az",
							  L"x", L"asd\"",
							  NULL],
	    L"<foo bar='b&amp;az' x='asd&quot;'/>");
	check_result_wide([OFXMLFactory createWideStanza: L"foo"
					    withCloseTag: YES
						 andData: L"bar",
							  L"bar", L"b'az",
							  L"x", L"y",
							  L"a", L"b",
							  NULL],
	    L"<foo bar='b&apos;az' x='y' a='b'>bar</foo>");
}

inline void
test_escape()
{
	check_result([OFXMLFactory escapeCString: "<hallo> &welt'\"!&"],
	    "&lt;hallo&gt; &amp;welt&apos;&quot;!&amp;");
}

inline void
test_escape_wide()
{
	check_result_wide(
	    [OFXMLFactory escapeWideCString: L"<hallo> &welt'\"!&"],
	    L"&lt;hallo&gt; &amp;welt&apos;&quot;!&amp;");
}


int main()
{
	i = 0;
	test_escape();
       	test_create_stanza();
       	test_concat();
	wprintf(L"\n");

	i = 0;
	test_escape_wide();
	test_create_stanza_wide();
	test_concat_wide();
	wprintf(L"\n");

	return 0;
}
