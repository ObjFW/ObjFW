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

#import "OFUnsupportedProtocolException.h"
#import "OFString.h"
#import "OFURL.h"

@implementation OFUnsupportedProtocolException
+ (instancetype)exceptionWithURL: (OFURL*)url
{
	return [[[self alloc] initWithURL: url] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithURL: (OFURL*)URL
{
	self = [super init];

	@try {
		_URL = [URL copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_URL release];

	[super dealloc];
}

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"The protocol of URL %@ is not supported!", _URL];
}

- (OFURL*)URL
{
	OF_GETTER(_URL, true)
}
@end
