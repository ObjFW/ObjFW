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

#import "OFChecksumMismatchException.h"
#import "OFString.h"

@implementation OFChecksumMismatchException
@synthesize actualChecksum = _actualChecksum;
@synthesize expectedChecksum = _expectedChecksum;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithActualChecksum: (OFString *)actualChecksum
			   expectedChecksum: (OFString *)expectedChecksum
{
	return [[[self alloc]
	    initWithActualChecksum: actualChecksum
		  expectedChecksum: expectedChecksum] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithActualChecksum: (OFString *)actualChecksum
		      expectedChecksum: (OFString *)expectedChecksum
{
	self = [super init];

	@try {
		_actualChecksum = [actualChecksum copy];
		_expectedChecksum = [expectedChecksum copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_actualChecksum release];
	[_expectedChecksum release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Checksum was %@ but %@ was expected!",
	    _actualChecksum, _expectedChecksum];
}
@end
