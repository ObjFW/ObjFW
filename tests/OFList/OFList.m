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

#import "OFString.h"
#import "OFList.h"
 
int
main()
{
	OFList	     *list;
	OFListObject *iter;

	list = [OFList new];
 
	[list addNew: [OFString new: "First String Object"]];
	[list addNew: [OFString new: "Second String Object"]];
	[list addNew: [OFString new: "Third String Object"]];
 
	for (iter = [list first]; iter != nil; iter = [iter next])
		printf("%s\n", [(OFString*)[iter data] cString]);
 
	[iter free];
	[list free];

	return 0;
}
