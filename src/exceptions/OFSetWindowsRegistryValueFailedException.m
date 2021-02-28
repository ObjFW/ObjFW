/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#import "OFSetWindowsRegistryValueFailedException.h"

#import "OFData.h"

@implementation OFSetWindowsRegistryValueFailedException
@synthesize registryKey = _registryKey, valueName = _valueName, data = _data;
@synthesize type = _type, status = _status;

+ (instancetype)exceptionWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			       valueName: (OFString *)valueName
				    data: (OFData *)data
				    type: (DWORD)type
				  status: (LSTATUS)status
{
	return [[[self alloc] initWithRegistryKey: registryKey
					valueName: valueName
					     data: data
					     type: type
					   status: status] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			  valueName: (OFString *)valueName
			       data: (OFData *)data
			       type: (DWORD)type
			     status: (LSTATUS)status
{
	self = [super init];

	@try {
		_registryKey = [registryKey retain];
		_valueName = [valueName copy];
		_data = [data copy];
		_type = type;
		_status = status;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_registryKey release];
	[_valueName release];
	[_data release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Failed to set value named %@ of type %u: %@",
	    _valueName, _type, of_windows_status_to_string(_status)];
}
@end
