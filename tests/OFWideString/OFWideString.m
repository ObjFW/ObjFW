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
#import <wchar.h>

#import "OFWideString.h"

/* TODO: Do real checks */

int
main()
{
	OFWideString *s1 = [OFWideString new: L"foo"];
	OFWideString *s2 = [[OFWideString alloc] init: L""];
	OFWideString *s3;
	OFWideString *s4 = [OFWideString new];

	printf("%p\n", [s2 append: L"bar"]);
	s3 = [s1 clone];

	[s4 setTo: [s2 wcString]];

	wprintf(L"s1 = %S\n", [s1 wcString]);
	wprintf(L"s2 = %S\n", [s2 wcString]);
	wprintf(L"s3 = %S\n", [s3 wcString]);
	wprintf(L"s4 = %S\n", [s4 wcString]);

	[s1 append: [s2 wcString]];
	wprintf(L"s1 append s2 = %S\n", [s1 wcString]);
	wprintf(L"strlen(s1) = %zd, [s1 length] = %zd\n",
	    wcslen([s1 wcString]), [s1 length]);
	[s1 free];
	[s2 free];
	[s3 free];
	[s4 free];

	return 0;
}
