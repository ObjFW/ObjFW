/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#import "OFSeekFailedException.h"
#import "OFString.h"
#import "OFSeekableStream.h"

#import "OFNotImplementedException.h"

#import "common.h"

@implementation OFSeekFailedException
+ exceptionWithClass: (Class)class_
	      stream: (OFSeekableStream*)stream
	      offset: (off_t)offset
	      whence: (int)whence
{
	return [[[self alloc] initWithClass: class_
				     stream: stream
				     offset: offset
				     whence: whence] autorelease];
}

- initWithClass: (Class)class_
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithClass: (Class)class_
	 stream: (OFSeekableStream*)stream_
	 offset: (off_t)offset_
	 whence: (int)whence_
{
	self = [super initWithClass: class_];

	stream = [stream_ retain];
	offset = offset_;
	whence = whence_;
	errNo = GET_ERRNO;

	return self;
}

- (void)dealloc
{
	[stream	release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Seeking failed in class %@! " ERRFMT, inClass, ERRPARAM];

	return description;
}

- (OFSeekableStream*)stream
{
	return stream;
}

- (off_t)offset
{
	return offset;
}

- (int)whence
{
	return whence;
}

- (int)errNo
{
	return errNo;
}
@end
