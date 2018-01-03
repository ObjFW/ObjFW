/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
 *   Jonathan Schleifer <js@heap.zone>
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
@synthesize requestedSize = _requestedSize;

+ (instancetype)exceptionWithRequestedSize: (size_t)requestedSize
{
	return [[[self alloc]
	    initWithRequestedSize: requestedSize] autorelease];
}

- (instancetype)init
{
	return [self initWithRequestedSize: 0];
}

- (instancetype)initWithRequestedSize: (size_t)requestedSize
{
	self = [super init];

	_requestedSize = requestedSize;

	return self;
}

- (OFString *)description
{
	if (_requestedSize != 0)
		return [OFString stringWithFormat:
		    @"Could not allocate %zu bytes!", _requestedSize];
	else
		return @"Could not allocate enough memory!";
}
@end
