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

/* TODO: Do real checks */
 
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
			wprintf(L"Element %zu is expected element. GOOD!\n", i);
		else {
			wprintf(L"Element %zu is not expected element!\n", i);
			return 1;
		}

	if (!wcscmp([(OFString*)[[list first] data] wideCString], strings[0]))
		wprintf(L"First element is expected element. GOOD!\n");
	else {
		wprintf(L"First element is not expected element!\n");
		return 1;
	}

	if (!wcscmp([(OFString*)[[list last] data] wideCString], strings[2]))
		wprintf(L"Last element is expected element. GOOD!\n");
	else {
		wprintf(L"Last element is not expected element!\n");
		return 1;
	}
 
	[list freeIncludingData];

	return 0;
}
