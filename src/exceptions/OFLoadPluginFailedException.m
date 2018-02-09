/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#import "OFLoadPluginFailedException.h"
#import "OFString.h"

@implementation OFLoadPluginFailedException
@synthesize path = _path, error = _error;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithPath: (OFString *)path
			    error: (OFString *)error
{
	return [[[self alloc] initWithPath: path
				     error: error] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithPath: (OFString *)path
		       error: (OFString *)error
{
	self = [super init];

	@try {
		_path = [path copy];
		_error = [error copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_path release];
	[_error release];

	[super dealloc];
}

- (OFString *)description
{
	if (_error != nil)
		return [OFString stringWithFormat:
		    @"Failed to load plugin %@: %@", _path, _error];
	else
		return [OFString stringWithFormat:
		    @"Failed to load plugin: %@", _path];
}
@end
