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
