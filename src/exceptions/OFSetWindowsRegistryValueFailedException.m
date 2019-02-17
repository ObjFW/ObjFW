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

#import "OFSetWindowsRegistryValueFailedException.h"

#import "OFData.h"

@implementation OFSetWindowsRegistryValueFailedException
@synthesize registryKey = _registryKey, value = _value, data = _data;
@synthesize type = _type, status = _status;

+ (instancetype)exceptionWithRegistryKey: (OFWindowsRegistryKey *)registryKey
				   value: (OFString *)value
				    data: (OFData *)data
				    type: (DWORD)type
				  status: (LSTATUS)status
{
	return [[[self alloc] initWithRegistryKey: registryKey
					    value: value
					     data: data
					     type: type
					   status: status] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			      value: (OFString *)value
			       data: (OFData *)data
			       type: (DWORD)type
			     status: (LSTATUS)status
{
	self = [super init];

	@try {
		_registryKey = [registryKey retain];
		_value = [value copy];
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
	[_value release];
	[_data release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Failed to set value %@ of type %u: %@",
	    _value, _type, of_windows_status_to_string(_status)];
}
@end
