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
#include <assert.h>

#import "OFArray.h"
#import "OFAutoreleasePool.h"
#import "OFString.h"
#import "OFExceptions.h"

#define CATCH_EXCEPTION(code, exception)		\
	@try {						\
		code;					\
							\
		puts("NOT CAUGHT!");			\
		return 1;				\
	} @catch (exception *e) {			\
		puts("CAUGHT! Error string was:");	\
		puts([[e string] cString]);		\
		puts("Resuming...");			\
	}

id c_array[] = {
	@"Foo",
	@"Bar",
	@"Baz",
	nil
};

int
main()
{
	OFArray *a = [OFArray arrayWithObjects: @"Foo", @"Bar", @"Baz", nil];
	OFArray *b = [OFMutableArray array];
	OFArray *c = [OFArray arrayWithCArray: c_array];

	[b addObject: @"Foo"];
	[b addObject: @"Bar"];
	[b addObject: @"Baz"];

	assert([a count] == 3);
	assert([b count] == 3);
	assert([c count] == 3);
	assert([a isEqual: b]);
	assert([a isEqual: c]);

	[b removeNObjects: 1];
	[b addObject: @"Baz"];
	assert([a isEqual: b]);

	[b removeNObjects: 1];
	[b addObject: @"Qux"];
	assert(![a isEqual: b]);

	CATCH_EXCEPTION([a objectAtIndex: 3], OFOutOfRangeException)
	CATCH_EXCEPTION([a addObject: @"foo"], OFNotImplementedException)

	return 0;
}
