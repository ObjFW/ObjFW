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

#import "OFString.h"
#import "OFList.h"

#ifndef _WIN32
#define ZD "%zd"
#else
#define ZD "%u"
#endif

#define NUM_TESTS 23
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

const OFString *strings[] = {
	@"First String Object",
	@"Second String Object",
	@"Third String Object"
};

int
main()
{
	size_t i, j;
	OFList *list, *list2, *list3;
	of_list_object_t *iter, *iter2;

	list = [OFList list];

	[list append: strings[0]];
	[list append: strings[1]];
	[list append: strings[2]];

	for (iter = [list first], i = 0; iter != NULL; iter = iter->next, i++)
		if ([iter->object isEqual: strings[i]])
			SUCCESS
		else
			FAIL

	CHECK([[list first]->object isEqual: strings[0]])
	CHECK([[list last]->object isEqual: strings[2]])

	[list remove: [list last]];
	CHECK([[list last]->object isEqual: strings[1]])

	[list remove: [list first]];
	CHECK([[list first]->object isEqual: [list last]->object])

	[list insert: strings[0]
	      before: [list last]];
	[list insert: strings[2]
	       after: [list first]->next];

	for (iter = [list first], j = 0; iter != NULL; iter = iter->next, j++)
		CHECK([iter->object isEqual: strings[j]])

	CHECK([list count] == 3)

	list2 = [OFList list];

	[list2 append: strings[0]];
	[list2 append: strings[1]];
	[list2 append: strings[2]];
	CHECK([list2 isEqual: list]);

	[list2 remove: [list2 last]];
	CHECK(![list2 isEqual: list]);

	/*
	 * Only mutableCopy is guaranteed to return a real copy instead of just
	 * increasing the reference counter.
	 */
	[list2 append: [@"foo" mutableCopy]];
	CHECK(![list2 isEqual: list]);

	list3 = [list2 copy];
	CHECK([list2 isEqual: list3]);

	for (iter = [list2 first], iter2 = [list3 first];
	    iter != NULL && iter2 != NULL;
	    iter = iter->next, iter2 = iter2->next) {
		CHECK(iter != iter2)
		CHECK(iter->object == iter2->object)
	}
	CHECK(iter == NULL && iter2 == NULL)
	CHECK([[list2 last]->object retainCount] == 3)

	puts("");

	return 0;
}
