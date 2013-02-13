/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
 *   Jonathan Schleifer <js@webkeks.org>
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

#include <stdlib.h>

#import "OFUnsupportedProtocolException.h"
#import "OFString.h"
#import "OFURL.h"

#import "common.h"

@implementation OFUnsupportedProtocolException
+ (instancetype)exceptionWithClass: (Class)class
			       URL: (OFURL*)url
{
	return [[[self alloc] initWithClass: class
					URL: url] autorelease];
}

- initWithClass: (Class)class
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	abort();
}

- initWithClass: (Class)class
	    URL: (OFURL*)URL
{
	self = [super initWithClass: class];

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
	    @"The protocol of URL %@ is not supported by class %@", _URL,
	    _inClass];
}

- (OFURL*)URL
{
	OF_GETTER(_URL, NO)
}
@end
