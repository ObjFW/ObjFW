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

#import "OFMalformedXMLException.h"
#import "OFString.h"
#import "OFXMLParser.h"

#import "common.h"

@implementation OFMalformedXMLException
+ (instancetype)exceptionWithClass: (Class)class
			    parser: (OFXMLParser*)parser
{
	return [[[self alloc] initWithClass: class
				     parser: parser] autorelease];
}

- initWithClass: (Class)class
	 parser: (OFXMLParser*)parser
{
	self = [super initWithClass: class];

	_parser = [parser retain];

	return self;
}

- (void)dealloc
{
	[_parser release];

	[super dealloc];
}

- (OFString*)description
{
	if (_description != nil)
		return _description;

	if (_parser != nil)
		_description = [[OFString alloc] initWithFormat:
		    @"The XML parser in class %@ encountered malformed XML!",
		    _inClass];
	else
		_description = @"An XML parser encountered malformed XML!";

	return _description;
}

- (OFXMLParser*)parser
{
	OF_GETTER(_parser, NO)
}
@end
