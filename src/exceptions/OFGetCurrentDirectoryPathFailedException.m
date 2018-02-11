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

#import "OFGetCurrentDirectoryPathFailedException.h"
#import "OFString.h"

@implementation OFGetCurrentDirectoryPathFailedException
@synthesize errNo = _errNo;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithErrNo: (int)errNo
{
	return [[[self alloc] initWithErrNo: errNo] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithErrNo: (int)errNo
{
	self = [super init];

	_errNo = errNo;

	return self;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Getting the current directory path failed: %@",
	    of_strerror(_errNo)];
}
@end
