/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFString.h"

extern void testing(OFString*, OFString*);
extern void success(OFString*, OFString*);
extern void failed(OFString*, OFString*);

#define TEST(test, cond)			\
	{					\
		testing(module, test);		\
						\
		if (cond)			\
			success(module, test);	\
		else				\
			failed(module, test);	\
	}
#define EXPECT_EXCEPTION(test, exception, code)	\
	{					\
		BOOL caught = NO;		\
						\
		testing(module, test);		\
						\
		@try {				\
			code;			\
		} @catch (exception *e) {	\
			caught = YES;		\
			[e dealloc];		\
		}				\
						\
		if (caught)			\
			success(module, test);	\
		else				\
			failed(module, test);	\
	}
