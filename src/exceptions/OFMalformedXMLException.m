/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#import "OFNotImplementedException.h"

#import "common.h"

@implementation OFMalformedXMLException
+ exceptionWithClass: (Class)class_
	      parser: (OFXMLParser*)parser
{
	return [[[self alloc] initWithClass: class_
				     parser: parser] autorelease];
}

- initWithClass: (Class)class_
	 parser: (OFXMLParser*)parser_
{
	self = [super initWithClass: class_];

	parser = [parser_ retain];

	return self;
}

- (void)dealloc
{
	[parser release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	if (parser != nil)
		description = [[OFString alloc] initWithFormat:
		    @"The parser in class %@ encountered malformed XML!",
		    inClass];
	else
		description = @"A parser encountered malformed XML!";

	return description;
}

- (OFXMLParser*)parser
{
	OF_GETTER(parser, NO)
}
@end
