/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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

#import "OFUnboundPrefixException.h"
#import "OFString.h"
#import "OFXMLParser.h"

#import "common.h"

@implementation OFUnboundPrefixException
+ (instancetype)exceptionWithPrefix: (OFString*)prefix
			     parser: (OFXMLParser*)parser
{
	return [[[self alloc] initWithPrefix: prefix
				      parser: parser] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithPrefix: (OFString*)prefix
	  parser: (OFXMLParser*)parser
{
	self = [super init];

	@try {
		_prefix = [prefix copy];
		_parser = [parser retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_prefix release];
	[_parser release];

	[super dealloc];
}

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"An XML parser of type %@ encountered the unbound prefix %@ in "
	    @"line %zu!", [_parser class], _prefix, [_parser lineNumber]];
}

- (OFString*)prefix
{
	OF_GETTER(_prefix, true)
}

- (OFXMLParser*)parser
{
	OF_GETTER(_parser, true)
}
@end
