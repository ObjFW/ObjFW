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

#import "OFUnsupportedProtocolException.h"
#import "OFString.h"
#import "OFURL.h"

@implementation OFUnsupportedProtocolException
@synthesize URL = _URL;

+ (instancetype)exceptionWithURL: (OFURL *)URL
{
	return [[[self alloc] initWithURL: URL] autorelease];
}

- (instancetype)initWithURL: (OFURL *)URL
{
	self = [super init];

	_URL = [URL retain];

	return self;
}

- (void)dealloc
{
	[_URL release];

	[super dealloc];
}

- (OFString *)description
{
	if (_URL != nil)
		return [OFString stringWithFormat:
		    @"The protocol of URL %@ is not supported!", _URL];
	else
		return @"The requested protocol is unsupported!";
}
@end
