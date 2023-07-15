/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

#import "OFSetOptionFailedException.h"
#import "OFString.h"

@implementation OFSetOptionFailedException
@synthesize object = _object, errNo = _errNo;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithObject: (id)object errNo: (int)errNo
{
	return [[[self alloc] initWithObject: object errNo: errNo] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithObject: (id)object errNo: (int)errNo
{
	self = [super init];

	_object = [object retain];
	_errNo = errNo;

	return self;
}

- (void)dealloc
{
	[_object release];

	[super dealloc];
}

- (OFString *)description
{
	if (_object != nil)
		return [OFString stringWithFormat:
		    @"Setting an option in an object of type %@ failed: %@",
		    [_object class], OFStrError(_errNo)];
	else
		return [OFString stringWithFormat:
		    @"Setting an option failed: %@", OFStrError(_errNo)];
}
@end
