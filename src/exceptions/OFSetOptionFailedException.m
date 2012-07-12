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

#import "OFSetOptionFailedException.h"
#import "OFString.h"
#import "OFStream.h"

#import "OFNotImplementedException.h"

@implementation OFSetOptionFailedException
+ exceptionWithClass: (Class)class_
	      stream: (OFStream*)stream
{
	return [[[self alloc] initWithClass: class_
				     stream: stream] autorelease];
}

- initWithClass: (Class)class_
{
	Class c = [self class];
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithClass: (Class)class_
	 stream: (OFStream*)stream_
{
	self = [super initWithClass: class_];

	stream = [stream_ retain];

	return self;
}

- (void)dealloc
{
	[stream release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Setting an option in class %@ failed!", inClass];

	return description;
}

- (OFStream*)stream
{
	return stream;
}
@end
