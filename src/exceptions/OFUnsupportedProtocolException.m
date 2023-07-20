/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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
#import "OFIRI.h"
#import "OFString.h"

@implementation OFUnsupportedProtocolException
@synthesize IRI = _IRI;

+ (instancetype)exceptionWithIRI: (OFIRI *)IRI
{
	return [[[self alloc] initWithIRI: IRI] autorelease];
}

- (instancetype)initWithIRI: (OFIRI *)IRI
{
	self = [super init];

	_IRI = [IRI retain];

	return self;
}

- (void)dealloc
{
	[_IRI release];

	[super dealloc];
}

- (OFString *)description
{
	if (_IRI != nil)
		return [OFString stringWithFormat:
		    @"The protocol of IRI %@ is not supported!", _IRI];
	else
		return @"The requested protocol is unsupported!";
}
@end
