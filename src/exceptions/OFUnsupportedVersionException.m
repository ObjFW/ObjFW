/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

#import "OFUnsupportedVersionException.h"
#import "OFString.h"

@implementation OFUnsupportedVersionException
@synthesize version = _version;

+ (instancetype)exceptionWithVersion: (OFString*)version
{
	return [[[self alloc] initWithVersion: version] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithVersion: (OFString*)version
{
	self = [super init];

	@try {
		_version = [version copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_version release];

	[super dealloc];
}

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"Version %@ of the format or protocol is not supported!",
	    _version];
}
@end
