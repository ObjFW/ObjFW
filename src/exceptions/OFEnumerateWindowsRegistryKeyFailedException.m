/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFEnumerateWindowsRegistryKeyFailedException.h"

@implementation OFEnumerateWindowsRegistryKeyFailedException
@synthesize registryKey = _registryKey, status = _status;

+ (instancetype)exceptionWithRegistryKey: (OFWindowsRegistryKey *)registryKey
				  status: (LSTATUS)status
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithRegistryKey: registryKey
				       status: status]);
}

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

- (instancetype)initWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			     status: (LSTATUS)status
{
	self = [super init];

	@try {
		_registryKey = objc_retain(registryKey);
		_status = status;
	} @catch (id e) {
		objc_release(self);
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
	objc_release(_registryKey);

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Failed to enumerate registry key: %@",
	    _OFWindowsStatusToString(_status)];
}
@end
