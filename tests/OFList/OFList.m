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

#import <stdio.h>
#import <string.h>

#import "OFString.h"
#import "OFList.h"

#define NUM_TESTS 5
#define SUCCESS								\
{									\
	printf("\r\033[1;%dmTests successful: %zd/%d\033[0m",		\
	    (i == NUM_TESTS - 1 ? 32 : 33), i + 1, NUM_TESTS);		\
	fflush(stdout);							\
}
#define FAIL								\
{									\
	printf("\r\033[K\033[1;31mTest %zd/%d failed!\033[m\n",		\
	    i + 1, NUM_TESTS);						\
	return 1;							\
}
#define CHECK(cond)							\
	if (cond)							\
		SUCCESS							\
	else								\
		FAIL							\
	i++;
 
const char *strings[] = {
	"First String Object",
	"Second String Object",
	"Third String Object"
};

int
main()
{
	size_t	     i;
	OFList	     *list;
	OFListObject *iter;

	list = [OFList new];
 
	[list addNew: [OFString newFromCString: strings[0]]];
	[list addNew: [OFString newFromCString: strings[1]]];
	[list addNew: [OFString newFromCString: strings[2]]];
 
	for (iter = [list first], i = 0; iter != nil; iter = [iter next], i++)
		if (!strcmp([(OFString*)[iter data] cString], strings[i]))
			SUCCESS
		else
			FAIL

	CHECK(!strcmp([(OFString*)[[list first] data] cString], strings[0]))
	CHECK(!strcmp([(OFString*)[[list last] data] cString], strings[2]))

	puts("");
 
	[list freeIncludingData];

	return 0;
}
