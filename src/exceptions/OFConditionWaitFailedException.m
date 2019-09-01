/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#include <string.h>

#import "OFConditionWaitFailedException.h"
#import "OFString.h"
#import "OFCondition.h"

@implementation OFConditionWaitFailedException
@synthesize condition = _condition, errNo = _errNo;

+ (instancetype)exceptionWithCondition: (OFCondition *)condition
				 errNo: (int)errNo
{
	return [[[self alloc] initWithCondition: condition
					  errNo: errNo] autorelease];
}

- (instancetype)initWithCondition: (OFCondition *)condition
			    errNo: (int)errNo
{
	self = [super init];

	_condition = [condition retain];
	_errNo = errNo;

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	[_condition release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Waiting for a condition of type %@ failed: %s",
	    _condition.class, strerror(_errNo)];
}
@end
