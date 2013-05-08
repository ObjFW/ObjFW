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
#ifdef HAVE_EXECINFO_H
	_backtraceSize = backtrace(_backtraceBuffer,
	    OF_EXCEPTION_MAX_BACKTRACE_SIZE);
#endif

	return self;
}

- (void)dealloc
{
	[_backtrace release];

	[super dealloc];
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
#ifdef HAVE_EXECINFO_H
	char **symbols;

	if (_backtrace != nil)
		return _backtrace;

	if (_backtraceSize < 1)
		return nil;

	symbols = backtrace_symbols(_backtraceBuffer, _backtraceSize);
	@try {
		int i;

		_backtrace = [[OFMutableArray alloc] init];

		for (i = 0; i < _backtraceSize; i++) {
			void *pool = objc_autoreleasePoolPush();
			OFString *symbol;

			symbol = [OFString
			    stringWithCString: symbols[i]
				     encoding: OF_STRING_ENCODING_NATIVE];
			[_backtrace addObject: symbol];

			objc_autoreleasePoolPop(pool);
		}
	} @finally {
		free(symbols);
	}

	[_backtrace makeImmutable];

	return _backtrace;
#else
	return nil;
#endif
}
@end
