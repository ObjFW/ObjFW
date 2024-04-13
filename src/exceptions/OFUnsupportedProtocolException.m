/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
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
