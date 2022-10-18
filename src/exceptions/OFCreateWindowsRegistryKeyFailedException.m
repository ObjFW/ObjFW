/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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
	    _path, OFWindowsStatusToString(_status)];
}
@end
