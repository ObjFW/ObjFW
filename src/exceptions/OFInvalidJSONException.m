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

#import "OFInvalidJSONException.h"
#import "OFString.h"

#import "OFNotImplementedException.h"

@implementation OFInvalidJSONException
+ exceptionWithClass: (Class)class_
		line: (size_t)line
{
	return [[[self alloc] initWithClass: class_
				       line: line] autorelease];
}

- initWithClass: (Class)class_
	   line: (size_t)line_
{
	self = [super initWithClass: class_];

	line = line_;

	return self;
}

- init
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"The JSON representation class %@ tried to parse is invalid in "
	    @"line %zd!", inClass, line];

	return description;
}

- (size_t)line
{
	return line;
}
@end
