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

#import "OFDeleteWindowsRegistryKeyFailedException.h"

#import "OFData.h"

@implementation OFDeleteWindowsRegistryKeyFailedException
@synthesize registryKey = _registryKey, subkeyPath = _subkeyPath;
@synthesize status = _status;

+ (instancetype)exceptionWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			      subkeyPath: (OFString *)subkeyPath
				  status: (LSTATUS)status
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithRegistryKey: registryKey
				   subkeyPath: subkeyPath
				       status: status]);
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			 subkeyPath: (OFString *)subkeyPath
			     status: (LSTATUS)status
{
	self = [super init];

	@try {
		_registryKey = objc_retain(registryKey);
		_subkeyPath = [subkeyPath copy];
		_status = status;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_registryKey);
	objc_release(_subkeyPath);

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Failed to delete subkey at path %@: %@",
	    _subkeyPath, _OFWindowsStatusToString(_status)];
}
@end
