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

#import "OFUnsupportedVersionException.h"
#import "OFString.h"

#import "common.h"

@implementation OFUnsupportedVersionException
+ (instancetype)exceptionWithClass: (Class)class
			   version: (OFString*)version
{
	return [[[self alloc] initWithClass: class
				    version: version] autorelease];
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
	version: (OFString*)version
{
	self = [super initWithClass: class];

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
	    @"Version %@ of the format or protocol is not supported by class "
	    @"%@", _version, _inClass];
}

- (OFString*)version
{
	OF_GETTER(_version, NO)
}
@end
