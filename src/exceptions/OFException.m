/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE.QPL included in
 * the packaging of this file.
 *
 * Alternatively, it may be distributed under the terms of the GNU General
 * Public License, either version 2 or 3, which can be found in the file
 * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the packaging of this
 * file.
 */

#include "config.h"

#include <stdlib.h>

#ifdef HAVE_EXECINFO_H
# include <execinfo.h>
#endif
#ifdef HAVE_DLFCN_H
# include <dlfcn.h>
#endif

#import "OFException.h"
#import "OFString.h"
#import "OFArray.h"

#import "autorelease.h"

@implementation OFException
+ (instancetype)exceptionWithClass: (Class)class
{
	return [[[self alloc] initWithClass: class] autorelease];
}

- init
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	abort();
}

- initWithClass: (Class)class
{
	self = [super init];

	_inClass = class;
#if defined(HAVE_EXECINFO_H) && defined(HAVE_BACKTRACE)
	_backtraceSize = backtrace(_backtrace, 32);
#elif defined(HAVE_BUILTIN_RETURN_ADDRESS)
	/*
	 * We can't use a loop here, as __builtin_return_address() and
	 * __builtin_frame_address() only allow a constant as parameter.
	 */
# define GET_FRAME(i)							\
	if (__builtin_frame_address(i + 1) == NULL)			\
		goto backtrace_done;					\
	if ((_backtrace[i] = (__builtin_return_address(i))) == NULL)	\
		goto backtrace_done;
	GET_FRAME(0)
	GET_FRAME(1)
	GET_FRAME(2)
	GET_FRAME(3)
	GET_FRAME(4)
	GET_FRAME(5)
	GET_FRAME(6)
	GET_FRAME(7)
	GET_FRAME(8)
	GET_FRAME(9)
	GET_FRAME(10)
	GET_FRAME(11)
	GET_FRAME(12)
	GET_FRAME(13)
	GET_FRAME(14)
	GET_FRAME(15)
	GET_FRAME(16)
	GET_FRAME(17)
	GET_FRAME(18)
	GET_FRAME(19)
	GET_FRAME(20)
	GET_FRAME(21)
	GET_FRAME(22)
	GET_FRAME(23)
	GET_FRAME(24)
	GET_FRAME(25)
	GET_FRAME(26)
	GET_FRAME(27)
	GET_FRAME(28)
	GET_FRAME(29)
	GET_FRAME(30)
	GET_FRAME(31)
# undef GET_FRAME
backtrace_done:
#endif

	return self;
}

- (Class)inClass
{
	return _inClass;
}

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"An exception of class %@ occurred in class %@!",
	    object_getClass(self), _inClass];
}

- (OFArray*)backtrace
{
#if defined(HAVE_EXECINFO_H) && defined(HAVE_BACKTRACE)
	OFMutableArray *backtrace = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();
	char **symbols;

	if (_backtraceSize < 0)
		return nil;

	symbols = backtrace_symbols(_backtrace, _backtraceSize);
	@try {
		int i;

		for (i = 0; i < _backtraceSize; i++) {
			OFString *symbol = [OFString
			    stringWithCString: symbols[i]
				     encoding: OF_STRING_ENCODING_NATIVE];
			[backtrace addObject: symbol];
		}
	} @finally {
		free(symbols);
	}

	objc_autoreleasePoolPop(pool);

	[backtrace makeImmutable];

	return backtrace;
#elif defined(HAVE_BUILTIN_RETURN_ADDRESS)
	OFMutableArray *backtrace = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();
	uint_fast8_t i;

	for (i = 0; i < 32 && _backtrace[i] != NULL; i++) {
		void *addr =
		    __builtin_extract_return_addr(_backtrace[i]);
# ifdef HAVE_DLFCN_H
		Dl_info info;

		if (dladdr(addr, &info)) {
			ptrdiff_t offset = (char*)addr - (char*)info.dli_saddr;

			if (info.dli_sname == NULL)
				info.dli_sname = "??";

			[backtrace addObject:
			    [OFString stringWithFormat: @"%p <%s+%td> at %s",
							addr, info.dli_sname,
							offset,
							info.dli_fname]];
		} else
# endif
			[backtrace addObject:
			    [OFString stringWithFormat: @"%p", addr]];
	}

	objc_autoreleasePoolPop(pool);

	[backtrace makeImmutable];

	return backtrace;
#else
	return nil;
#endif
}
@end
