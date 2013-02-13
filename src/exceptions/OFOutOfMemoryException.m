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

#import "OFOutOfMemoryException.h"
#import "OFString.h"

@implementation OFOutOfMemoryException
+ (instancetype)exceptionWithClass: (Class)class
		     requestedSize: (size_t)requestedSize
{
	return [[[self alloc] initWithClass: class
			      requestedSize: requestedSize] autorelease];
}

- initWithClass: (Class)class
  requestedSize: (size_t)requestedSize
{
	self = [super initWithClass: class];

	_requestedSize = requestedSize;

	return self;
}

- (OFString*)description
{
	if (_requestedSize != 0)
		return [OFString stringWithFormat:
		    @"Could not allocate %zu bytes in class %@!",
		    _requestedSize, _inClass];
	else
		return [OFString stringWithFormat:
		    @"Could not allocate enough memory in class %@!", _inClass];
}

- (size_t)requestedSize
{
	return _requestedSize;
}
@end
