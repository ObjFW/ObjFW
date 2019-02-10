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

#import "OFOpenWindowsRegistryKeyFailedException.h"

@implementation OFOpenWindowsRegistryKeyFailedException
@synthesize registryKey = _registryKey, path = _path, options = _options;
@synthesize securityAndAccessRights = _securityAndAccessRights;
@synthesize status = _status;

+ (instancetype)
    exceptionWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			path: (OFString *)path
		     options: (DWORD)options
     securityAndAccessRights: (REGSAM)securityAndAccessRights
		      status: (LSTATUS)status
{
	return [[[self alloc] initWithRegistryKey: registryKey
					     path: path
					  options: options
			  securityAndAccessRights: securityAndAccessRights
					   status: status] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)
	initWithRegistryKey: (OFWindowsRegistryKey *)registryKey
		       path: (OFString *)path
		    options: (DWORD)options
    securityAndAccessRights: (REGSAM)securityAndAccessRights
		     status: (LSTATUS)status
{
	self = [super init];

	@try {
		_registryKey = [registryKey retain];
		_path = [path copy];
		_options = options;
		_securityAndAccessRights = securityAndAccessRights;
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
	    @"Failed to open subkey at path %@: Status code %u!",
	    _path, _status];
}
@end
