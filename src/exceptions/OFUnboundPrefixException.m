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

#import "OFUnboundPrefixException.h"
#import "OFString.h"
#import "OFXMLParser.h"

#import "common.h"

@implementation OFUnboundPrefixException
+ (instancetype)exceptionWithClass: (Class)class
			    prefix: (OFString*)prefix
			    parser: (OFXMLParser*)parser
{
	return [[[self alloc] initWithClass: class
				     prefix: prefix
				     parser: parser] autorelease];
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
	 prefix: (OFString*)prefix
	 parser: (OFXMLParser*)parser
{
	self = [super initWithClass: class];

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
	    @"The XML parser in class %@ encountered the unbound prefix %@ in "
	    @"line %zd!", _inClass, _prefix, [_parser lineNumber]];
}

- (OFString*)prefix
{
	OF_GETTER(_prefix, false)
}

- (OFXMLParser*)parser
{
	OF_GETTER(_parser, false)
}
@end
