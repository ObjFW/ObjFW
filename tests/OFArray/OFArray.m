/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>

#import "OFArray.h"
#import "OFExceptions.h"
#import "OFAutoreleasePool.h"

#define CATCH_EXCEPTION(code, exception)		\
	@try {						\
		code;					\
							\
		puts("NOT CAUGHT!");			\
		return 1;				\
	} @catch (exception *e) {			\
		puts("CAUGHT! Error string was:");	\
		puts([e cString]);			\
		puts("Resuming...");			\
	}

const char *str = "Hallo!";

#define TEST(type) \
	puts("Trying to add too much to an array...");			\
	a = [[type alloc] initWithItemSize: 4096];			\
	CATCH_EXCEPTION([a addNItems: SIZE_MAX				\
			  fromCArray: NULL],				\
	    OFOutOfRangeException)					\
									\
	puts("Trying to add something after that error...");		\
	p = [a allocWithSize: 4096];					\
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
	q = [a allocWithSize: 4096];					\
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
	p = [a allocWithSize: 8192];					\
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
	[a release];							\
									\
	puts("Creating new array and using it to build a string...");	\
	a = [[type alloc] initWithItemSize: 1];				\
									\
	for (i = 0; i < strlen(str); i++)				\
		[a add: (void*)&str[i]];				\
	[a add: ""];							\
									\
	if (!strcmp([a data], str))					\
		puts("Built string matches!");				\
	else {								\
		puts("Built string does not match!");			\
		abort();						\
	}								\
									\
	[a release];

int
main()
{
	id a;
	void *p, *q;
	size_t i;
	OFArray *x, *y;
	OFAutoreleasePool *pool;

	puts("== TESTING OFArray ==");
	TEST(OFArray)

	puts("== TESTING OFBigArray ==");
	TEST(OFBigArray)

	pool = [[OFAutoreleasePool alloc] init];
	x = [OFArray arrayWithItemSize: 1];
	y = [OFArray bigArrayWithItemSize: 1];

	if (![x isEqual: y]) {
		puts("FAIL 1!");
		return 1;
	}

	if ([x hash] != [y hash]) {
		puts("FAIL 2!");
		return 1;
	}

	[x add: "x"];
	if ([x isEqual: y]) {
		puts("FAIL 3!");
		return 1;
	}
	[pool releaseObjects];

	x = [OFArray arrayWithItemSize: 2];
	y = [OFArray bigArrayWithItemSize: 4];

	if ([x isEqual: y]) {
		puts("FAIL 4!");
		return 1;
	}
	[pool releaseObjects];

	x = [OFArray arrayWithItemSize: 1];
	[x addNItems: 3
	  fromCArray: "abc"];
	y = [x copy];
	if ([x compare: y]) {
		puts("FAIL 5!");
		return 1;
	}

	[y add: "de"];
	if ([x compare: y] != -100) {
		puts("FAIL 6!");
		return 1;
	}

	if ([y hash] != 0xCD8B6206) {
		puts("FAIL 7!");
		return 1;
	}
	[pool release];

	return 0;
}
