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

#import <wchar.h>

#import "OFWideString.h"

/* TODO: Do real checks */

int
main()
{
	OFWideString *s1 = [OFWideString new: L"test"];
	OFWideString *s2 = [[OFWideString alloc] init: L""];
	OFWideString *s3;
	OFWideString *s4 = [OFWideString new];

	[s2 append: L"123"];
	s3 = [s1 clone];

	[s4 setTo: [s2 wcString]];

	if (![s1 compare: s3])
		puts("s1 and s3 match! GOOD!");
	else {
		puts("s1 and s3 don't match!");
		return 1;
	}

	if (![s2 compare: s4])
		puts("s2 and s4 match! GOOD!");
	else {
		puts("s1 and s3 don't match!");
		return 1;
	}

	if (!wcscmp([[s1 append: [s2 wcString]] wcString], L"test123"))
		puts("s1 appended with s2 is the expected string! GOOD!");
	else {
		puts("s1 appended with s2 is not the expected string!");
		return 1;
	}

	if (wcslen([s1 wcString]) == [s1 length] && [s1 length] == 7)
		puts("s1 has the expected length. GOOD!");
	else {
		puts("s1 does not have the expected length!");
		return 1;
	}

	[s1 free];
	[s2 free];
	[s3 free];
	[s4 free];

	return 0;
}
