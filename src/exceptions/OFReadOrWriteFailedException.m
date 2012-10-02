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

#import "OFReadOrWriteFailedException.h"
#import "OFString.h"
#import "OFStreamSocket.h"

#import "OFNotImplementedException.h"

#import "common.h"

@implementation OFReadOrWriteFailedException
+ exceptionWithClass: (Class)class_
	      stream: (OFStream*)stream
     requestedLength: (size_t)length
{
	return [[[self alloc] initWithClass: class_
				     stream: stream
			    requestedLength: length] autorelease];
}

- initWithClass: (Class)class_
{
	Class c = [self class];
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

-   initWithClass: (Class)class_
	   stream: (OFStream*)stream_
  requestedLength: (size_t)length
{
	self = [super initWithClass: class_];

	stream = [stream_ retain];
	requestedLength = length;

	if ([class_ isSubclassOfClass: [OFStreamSocket class]])
		errNo = GET_SOCK_ERRNO;
	else
		errNo = GET_ERRNO;

	return self;
}

- (void)dealloc
{
	[stream release];

	[super dealloc];
}

- (OFStream*)stream
{
	OF_GETTER(stream, NO)
}

- (size_t)requestedLength
{
	return requestedLength;
}

- (int)errNo
{
	return errNo;
}
@end
