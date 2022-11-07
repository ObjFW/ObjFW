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

#import "OFUnsupportedProtocolException.h"
#import "OFString.h"
#import "OFURI.h"

@implementation OFUnsupportedProtocolException
@synthesize URI = _URI;

+ (instancetype)exceptionWithURI: (OFURI *)URI
{
	return [[[self alloc] initWithURI: URI] autorelease];
}

- (instancetype)initWithURI: (OFURI *)URI
{
	self = [super init];

	_URI = [URI retain];

	return self;
}

- (void)dealloc
{
	[_URI release];

	[super dealloc];
}

- (OFString *)description
{
	if (_URI != nil)
		return [OFString stringWithFormat:
		    @"The protocol of URI %@ is not supported!", _URI];
	else
		return @"The requested protocol is unsupported!";
}
@end
