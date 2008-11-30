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
#import <stdlib.h>
#import <string.h>

#import "OFArray.h"
#import "OFExceptions.h"

#define CATCH_EXCEPTION(code, exception)		\
	caught = NO;					\
	@try {						\
		code;					\
	} @catch (exception *e) {			\
		caught = YES;				\
		puts("CAUGHT! Error string was:");	\
		fputs([e cString], stdout);		\
		puts("Resuming...");			\
	}						\
	if (!caught) {					\
		puts("NOT CAUGHT!");			\
		return 1;				\
	}

const char *str = "Hallo!";

#define TEST(type) \
	puts("Trying to add too much to an array...");			\
	a = [type newWithItemSize: 4096];				\
	CATCH_EXCEPTION([a addNItems: SIZE_MAX				\
			  fromCArray: NULL],				\
	    OFOutOfRangeException)					\
									\
	puts("Trying to add something after that error...");		\
	p = [a getMemWithSize: 4096];					\
	memset(p, 255, 4096);						\
	[a add: p];							\
	if (!memcmp([a last], p, 4096))					\
		puts("[a last] matches with p!");			\
	else {								\
		puts("[a last] does not match p!");			\
		abort();						\
	}								\
	[a freeMem: p];							\
									\
	puts("Adding more data...");					\
	q = [a getMemWithSize: 4096];					\
	memset(q, 42, 4096);						\
	[a add: q];							\
	if (!memcmp([a last], q, 4096))					\
		puts("[a last] matches with q!");			\
	else {								\
		puts("[a last] does not match q!");			\
		abort();						\
	}								\
	[a freeMem: q];							\
									\
	puts("Adding multiple items at once...");			\
	p = [a getMemWithSize: 8192];					\
	memset(p, 64, 8192);						\
	[a addNItems: 2							\
	  fromCArray: p];						\
	if (!memcmp([a last], [a item: [a items] - 2], 4096) &&		\
	    !memcmp([a item: [a items] - 2], p, 4096))			\
		puts("[a last], [a item: [a items] - 2] and p match!");	\
	else {								\
		puts("[a last], [a item: [a items] - 2] and p did not match!");\
		abort();						\
	}								\
	[a freeMem: p];							\
									\
	i = [a items];							\
	puts("Removing 2 items...");					\
	[a removeNItems: 2];						\
	if ([a items] + 2 != i) {					\
		puts("[a items] + 2 != i!");				\
		abort();						\
	}								\
									\
	puts("Trying to remove more data than we added...");		\
	CATCH_EXCEPTION([a removeNItems: [a items] + 1],		\
	    OFOutOfRangeException);					\
									\
	puts("Trying to access an index that does not exist...");	\
	CATCH_EXCEPTION([a item: [a items]], OFOutOfRangeException);	\
									\
	[a free];							\
									\
	puts("Creating new array and using it to build a string...");	\
	a = [type newWithItemSize: 1];				\
									\
	for (i = 0; i < strlen(str); i++)				\
		[a add: (void*)(str + i)];				\
	[a add: ""];							\
									\
	if (!strcmp([a data], str))					\
		puts("Built string matches!");				\
	else {								\
		puts("Built string does not match!");			\
		abort();						\
	}								\
									\
	[a free];

int
main()
{
	BOOL caught;
	id a;
	void *p, *q;
	size_t i;

	puts("== TESTING OFArray ==");
	TEST(OFArray)

	puts("== TESTING OFBigArray ==");
	TEST(OFBigArray)

	return 0;
}
