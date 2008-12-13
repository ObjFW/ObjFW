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

#import <string.h>
#import <wchar.h>

#import "OFString.h"
#import "OFList.h"

#define NUM_TESTS 5
#define SUCCESS								\
{									\
	wprintf(L"\r\033[1;%dmTests successful: %d/%d\033[0m",		\
	    (i == NUM_TESTS - 1 ? 32 : 33), i + 1, NUM_TESTS);		\
	fflush(stdout);							\
}
#define FAIL								\
{									\
	wprintf(L"\r\033[K\033[1;31mTest %d/%d failed!\033[m\n",	\
	    i + 1, NUM_TESTS);						\
	return 1;							\
}
#define CHECK(cond)							\
	if (cond)							\
		SUCCESS							\
	else								\
		FAIL							\
	i++;
 
const wchar_t *strings[] = {
	L"First String Object",
	L"Second String Object",
	L"Third String Object"
};

int
main()
{
	size_t	     i;
	OFList	     *list;
	OFListObject *iter;

	list = [OFList new];
 
	[list addNew: [OFString newFromWideCString: strings[0]]];
	[list addNew: [OFString newFromWideCString: strings[1]]];
	[list addNew: [OFString newFromWideCString: strings[2]]];
 
	for (iter = [list first], i = 0; iter != nil; iter = [iter next], i++)
		if (!wcscmp([(OFString*)[iter data] wideCString], strings[i]))
			SUCCESS
		else
			FAIL

	CHECK(!wcscmp([(OFString*)[[list first] data] wideCString], strings[0]))
	CHECK(!wcscmp([(OFString*)[[list last] data] wideCString], strings[2]))

	wprintf(L"\n");
 
	[list freeIncludingData];

	return 0;
}
