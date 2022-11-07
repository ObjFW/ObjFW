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

#import "OFOpenWindowsRegistryKeyFailedException.h"

@implementation OFOpenWindowsRegistryKeyFailedException
@synthesize registryKey = _registryKey, path = _path;
@synthesize accessRights = _accessRights, options = _options, status = _status;

+ (instancetype)exceptionWithRegistryKey: (OFWindowsRegistryKey *)registryKey
				    path: (OFString *)path
			    accessRights: (REGSAM)accessRights
				 options: (DWORD)options
				  status: (LSTATUS)status
{
	return [[[self alloc] initWithRegistryKey: registryKey
					     path: path
				     accessRights: accessRights
					  options: options
					   status: status] autorelease];
}

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

- (instancetype)initWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			       path: (OFString *)path
		       accessRights: (REGSAM)accessRights
			    options: (DWORD)options
			     status: (LSTATUS)status
{
	self = [super init];

	@try {
		_registryKey = [registryKey retain];
		_path = [path copy];
		_accessRights = accessRights;
		_options = options;
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
	[_path release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Failed to open subkey at path %@: %@",
	    _path, OFWindowsStatusToString(_status)];
}
@end
