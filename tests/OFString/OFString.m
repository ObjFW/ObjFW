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

int
main()
{
	OFString *s1 = [OFString new:"foo"];
	OFString *s2 = [[OFString alloc] init:""];
	OFString *s3;
	OFString *s4 = [OFString new];

	[s2 append:"bar"];
	s3 = [s1 clone];

	[s4 setTo:[s2 cString]];

	printf("s1 = %s\n", [s1 cString]);
	printf("s2 = %s\n", [s2 cString]);
	printf("s3 = %s\n", [s3 cString]);
	printf("s4 = %s\n", [s4 cString]);

	[s1 append: [s2 cString]];
	printf("s1 append s2 = %s\n", [s1 cString]);
	printf("strlen(s1) = %ld, [s1 length] = %ld\n",
	    strlen([s1 cString]), [s1 length]);
	[s1 free];
	[s2 free];
	[s3 free];
	[s4 free];

	return 0;
}
