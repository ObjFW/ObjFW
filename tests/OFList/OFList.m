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

#import <string.h>

#import "OFString.h"
#import "OFList.h"

#import <stdio.h>

#ifndef _WIN32
#define ZD "%zd"
#else
#define ZD "%u"
#endif

#define NUM_TESTS 10
#define SUCCESS								\
{									\
	printf("\r\033[1;%dmTests successful: " ZD "/%d\033[0m",	\
	    (i == NUM_TESTS - 1 ? 32 : 33), i + 1, NUM_TESTS);		\
	fflush(stdout);							\
}
#define FAIL								\
{									\
	printf("\r\033[K\033[1;31mTest " ZD "/%d failed!\033[m\n",	\
	    i + 1, NUM_TESTS);						\
	return 1;							\
}
#define CHECK(cond)							\
{									\
	if (cond)							\
		SUCCESS							\
	else								\
		FAIL							\
	i++;								\
}

const char *strings[] = {
	"First String Object",
	"Second String Object",
	"Third String Object"
};

int
main()
{
	size_t i, j;
	OFList *list;
	of_list_object_t *iter;

	list = [OFList new];

	[list append: [OFString newFromCString: strings[0]]];
	[list append: [OFString newFromCString: strings[1]]];
	[list append: [OFString newFromCString: strings[2]]];

	for (iter = [list first], i = 0; iter != NULL; iter = iter->next, i++)
		if (!strcmp([iter->object cString], strings[i]))
			SUCCESS
		else
			FAIL

	CHECK(!strcmp([[list first]->object cString], strings[0]))
	CHECK(!strcmp([[list last]->object cString], strings[2]))

	[list remove: [list last]];
	CHECK(!strcmp([[list last]->object cString], strings[1]))

	[list remove: [list first]];
	CHECK(!strcmp([[list first]->object cString],
	    [[list last]->object cString]))

	[list insert: [OFString newFromCString: strings[0]]
	      before: [list last]];
	[list insert: [OFString newFromCString: strings[2]]
	       after: [list first]->next];

	for (iter = [list first], j = 0; iter != NULL; iter = iter->next, j++)
		CHECK(!strcmp([iter->object cString], strings[j]))

	puts("");

	return 0;
}
