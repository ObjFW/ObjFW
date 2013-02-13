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

#import "OFInvalidJSONException.h"
#import "OFString.h"

@implementation OFInvalidJSONException
+ (instancetype)exceptionWithClass: (Class)class
			      line: (size_t)line
{
	return [[[self alloc] initWithClass: class
				       line: line] autorelease];
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
	   line: (size_t)line
{
	self = [super initWithClass: class];

	_line = line;

	return self;
}

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"The JSON representation class %@ tried to parse is invalid in "
	    @"line %zd!", _inClass, _line];
}

- (size_t)line
{
	return _line;
}
@end
