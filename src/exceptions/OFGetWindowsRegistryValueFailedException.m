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

#import "OFGetWindowsRegistryValueFailedException.h"

@implementation OFGetWindowsRegistryValueFailedException
@synthesize registryKey = _registryKey, valueName = _valueName;
@synthesize status = _status;

+ (instancetype)exceptionWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			       valueName: (OFString *)valueName
				  status: (LSTATUS)status
{
	return [[[self alloc] initWithRegistryKey: registryKey
					valueName: valueName
					   status: status] autorelease];
}

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

- (instancetype)initWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			  valueName: (OFString *)valueName
			     status: (LSTATUS)status
{
	self = [super init];

	@try {
		_registryKey = [registryKey retain];
		_valueName = [valueName copy];
		_status = status;
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
	[_registryKey release];
	[_valueName release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Failed to get value named %@: %@",
	    _valueName, OFWindowsStatusToString(_status)];
}
@end
