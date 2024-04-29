/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFCreateWindowsRegistryKeyFailedException.h"

@implementation OFCreateWindowsRegistryKeyFailedException
@synthesize registryKey = _registryKey, path = _path;
@synthesize accessRights = _accessRights;
@synthesize securityAttributes = _securityAttributes, options = _options;
@synthesize status = _status;

+ (instancetype)
    exceptionWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			path: (OFString *)path
		accessRights: (REGSAM)accessRights
	  securityAttributes: (LPSECURITY_ATTRIBUTES)securityAttributes
		     options: (DWORD)options
		      status: (LSTATUS)status
{
	return [[[self alloc] initWithRegistryKey: registryKey
					     path: path
				     accessRights: accessRights
			       securityAttributes: securityAttributes
					  options: options
					   status: status] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			       path: (OFString *)path
		       accessRights: (REGSAM)accessRights
		 securityAttributes: (LPSECURITY_ATTRIBUTES)securityAttributes
			    options: (DWORD)options
			     status: (LSTATUS)status
{
	self = [super init];

	@try {
		_registryKey = [registryKey retain];
		_path = [path copy];
		_accessRights = accessRights;
		_securityAttributes = securityAttributes;
		_options = options;
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
	[_path release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Failed to create subkey at path %@: %@",
	    _path, _OFWindowsStatusToString(_status)];
}
@end
