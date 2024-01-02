/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFChangeCurrentDirectoryFailedException.h"
#import "OFString.h"

@implementation OFChangeCurrentDirectoryFailedException
@synthesize path = _path, errNo = _errNo;

+ (instancetype)exceptionWithPath: (OFString *)path errNo: (int)errNo
{
	return [[[self alloc] initWithPath: path errNo: errNo] autorelease];
}

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

- (instancetype)initWithPath: (OFString *)path errNo: (int)errNo
{
	self = [super init];

	@try {
		_path = [path copy];
		_errNo = errNo;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	[_path release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Failed to change the current directory to %@: %@",
	    _path, OFStrError(_errNo)];
}
@end
