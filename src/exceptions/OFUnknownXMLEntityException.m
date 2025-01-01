/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#import "OFUnknownXMLEntityException.h"
#import "OFString.h"

@implementation OFUnknownXMLEntityException
@synthesize entityName = _entityName;

+ (instancetype)exceptionWithEntityName: (OFString *)entityName
{
	return [[[self alloc] initWithEntityName: entityName] autorelease];
}

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

- (instancetype)initWithEntityName: (OFString *)entityName
{
	self = [super init];

	@try {
		_entityName = [entityName copy];
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
	[_entityName release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"A parser encountered an unknown XML entity named %@!",
	    _entityName];
}
@end
