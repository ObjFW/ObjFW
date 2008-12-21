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
#import "OFExceptions.h"

int
main()
{
	OFString *s1 = [OFString newFromCString: "test"];
	OFString *s2 = [OFString newFromCString: ""];
	OFString *s3;
	OFString *s4 = [OFString new];

	s3 = [s1 clone];

	if (![s1 compareTo: s3])
		puts("s1 and s3 match! GOOD!");
	else {
		puts("s1 and s3 don't match!");
		return 1;
	}

	[s2 appendCString: "123"];
	[s4 setTo: s2];

	if (![s2 compareTo: s4])
		puts("s2 and s4 match! GOOD!");
	else {
		puts("s2 and s4 don't match!");
		return 1;
	}

	if (!strcmp([[s1 append: s2] cString], "test123"))
		puts("s1 appended with s2 is the expected string! GOOD!");
	else {
		puts("s1 appended with s2 is not the expected string!");
		return 1;
	}

	if (strlen([s1 cString]) == [s1 length] && [s1 length] == 7)
		puts("s1 has the expected length. GOOD!");
	else {
		puts("s1 does not have the expected length!");
		return 1;
	}

	if (!strcmp([[s1 reverse] cString], "321tset"))
		puts("Reversed s1 is expected string! GOOD!");
	else {
		puts("Reversed s1 is NOT the expected string!");
		return 1;
	}

	if (!strcmp([[s1 upper] cString], "321TSET"))
		puts("Upper s1 is expected string! GOOD!");
	else {
		puts("Upper s1 is NOT expected string!");
		return 1;
	}

	if (!strcmp([[s1 lower] cString], "321tset"))
		puts("Lower s1 is expected string! GOOD!");
	else {
		puts("Lower s1 is NOT expected string!");
		return 1;
	}

	/* Also clears all the memory of the returned C strings */
	[s1 free];
	[s2 free];
	[s3 free];
	[s4 free];

	/* UTF-8 tests */
	@try {
		s1 = [OFString newFromCString: "\xE0\x80"];

		puts("First invalid UTF-8 not detected!");
		return 1;
	} @catch (OFInvalidEncodingException *e) {
		puts("First invalid UTF-8 successfully detected!");
	}

	@try {
		s1 = [OFString newFromCString: "\xF0\x80\x80\xC0"];

		puts("Second UTF-8 not detected!");
		return 1;
	} @catch (OFInvalidEncodingException *e) {
		puts("Second UTF-8 successfully detected!");
	}

	s1 = [OFString newFromCString: "äöü€𝄞"];
	if (!strcmp([[s1 reverse] cString], "𝄞€üöä"))
		puts("Reversed UTF-8 string is expected string! GOOD!");
	else {
		puts("Reversed UTF-8 string is NOT expected string!");
		return 1;
	}

	return 0;
}
