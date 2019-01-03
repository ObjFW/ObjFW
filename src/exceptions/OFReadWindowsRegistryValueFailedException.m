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

#import "OFReadWindowsRegistryValueFailedException.h"

@implementation OFReadWindowsRegistryValueFailedException
@synthesize registryKey = _registryKey, value = _value;
@synthesize subKeyPath = _subKeyPath, flags = _flags, status = _status;

+ (instancetype)exceptionWithRegistryKey: (OFWindowsRegistryKey *)registryKey
				   value: (nullable OFString *)value
			      subKeyPath: (nullable OFString *)subKeyPath
				   flags: (DWORD)flags
				  status: (LSTATUS)status
{
	return [[[self alloc] initWithRegistryKey: registryKey
					    value: value
				       subKeyPath: subKeyPath
					    flags: flags
					   status: status] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			      value: (nullable OFString *)value
			 subKeyPath: (nullable OFString *)subKeyPath
			      flags: (DWORD)flags
			     status: (LSTATUS)status
{
	self = [super init];

	@try {
		_registryKey = [registryKey retain];
		_value = [value copy];
		_subKeyPath = [subKeyPath copy];
		_flags = flags;
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
	[_subKeyPath release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Failed to read value %@ at sub key path %@: Status code %u!",
	    _value, _subKeyPath, _status];
}
@end
