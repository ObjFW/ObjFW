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

#import "OFReadOrWriteFailedException.h"
#import "OFString.h"
#import "OFStreamSocket.h"

#import "OFNotImplementedException.h"

#import "common.h"

@implementation OFReadOrWriteFailedException
+  newWithClass: (Class)class_
	 stream: (OFStream*)stream
  requestedSize: (size_t)size
{
	return [[self alloc] initWithClass: class_
				    stream: stream
			     requestedSize: size];
}

- initWithClass: (Class)class_
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithClass: (Class)class_
	 stream: (OFStream*)stream_
  requestedSize: (size_t)size
{
	self = [super initWithClass: class_];

	@try {
		stream = [stream_ retain];
		requestedSize = size;

		if ([class_ isSubclassOfClass: [OFStreamSocket class]])
			errNo = GET_SOCK_ERRNO;
		else
			errNo = GET_ERRNO;
	} @catch (id e) {
		return e;
	}

	return self;
}

- (void)dealloc
{
	[stream release];

	[super dealloc];
}

- (OFStream*)stream
{
	return stream;
}

- (size_t)requestedSize
{
	return requestedSize;
}

- (int)errNo
{
	return errNo;
}
@end
