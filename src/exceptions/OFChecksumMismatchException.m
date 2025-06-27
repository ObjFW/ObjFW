/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
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
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithActualChecksum: actualChecksum
				expectedChecksum: expectedChecksum]);
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
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_actualChecksum);
	objc_release(_expectedChecksum);

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Checksum was %@ but %@ was expected!",
	    _actualChecksum, _expectedChecksum];
}
@end
