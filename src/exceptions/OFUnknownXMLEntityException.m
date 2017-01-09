/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#import "OFUnknownXMLEntityException.h"
#import "OFString.h"

@implementation OFUnknownXMLEntityException
@synthesize entityName = _entityName;

+ (instancetype)exceptionWithEntityName: (OFString*)entityName
{
	return [[[self alloc] initWithEntityName: entityName] autorelease];
}

- initWithEntityName: (OFString*)entityName
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

- (void)dealloc
{
	[_entityName release];

	[super dealloc];
}

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"A parser encountered an unknown XML entity named %@!",
	    _entityName];
}
@end
