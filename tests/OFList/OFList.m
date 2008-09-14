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
#import <string.h>

#import "OFString.h"
#import "OFList.h"

/* TODO: Do real checks */
 
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
 
	[list addNew: [OFString new: strings[0]]];
	[list addNew: [OFString new: strings[1]]];
	[list addNew: [OFString new: strings[2]]];
 
	for (iter = [list first], i = 0; iter != nil; iter = [iter next], i++)
		if (!strcmp([(OFString*)[iter data] cString], strings[i]))
			printf("Element %zu is expected element. GOOD!\n", i);
		else {
			printf("Element %zu is not expected element!\n", i);
			return 1;
		}

	if (!strcmp([(OFString*)[[list first] data] cString], strings[0]))
		puts("First element is expected element. GOOD!");
	else {
		puts("First element is not expected element!");
		return 1;
	}

	if (!strcmp([(OFString*)[[list last] data] cString], strings[2]))
		puts("Last element is expected element. GOOD!");
	else {
		puts("Last element is not expected element!");
		return 1;
	}
 
	[iter free];
	[list free];

	return 0;
}
