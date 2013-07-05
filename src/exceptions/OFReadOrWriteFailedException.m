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

#import "OFReadOrWriteFailedException.h"
#import "OFString.h"
#import "OFStream.h"
#ifdef OF_HAVE_SOCKETS
# import "OFStreamSocket.h"
#endif

#import "common.h"

@implementation OFReadOrWriteFailedException
+ (instancetype)exceptionWithStream: (OFStream*)stream
		    requestedLength: (size_t)requestedLength
{
	return [[[self alloc] initWithStream: stream
			     requestedLength: requestedLength] autorelease];
}

- init
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	abort();
}

-  initWithStream: (OFStream*)stream
  requestedLength: (size_t)requestedLength
{
	self = [super init];

	_stream = [stream retain];
	_requestedLength = requestedLength;

#ifdef OF_HAVE_SOCKETS
	if ([stream isKindOfClass: [OFStreamSocket class]])
		_errNo = GET_SOCK_ERRNO;
	else
#endif
		_errNo = GET_ERRNO;

	return self;
}

- (void)dealloc
{
	[_stream release];

	[super dealloc];
}

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"Failed to read or write %zu bytes in a stream of type "
	    @"%@! " ERRFMT, _requestedLength, [_stream class], ERRPARAM];
}

- (OFStream*)stream
{
	OF_GETTER(_stream, false)
}

- (size_t)requestedLength
{
	return _requestedLength;
}

- (int)errNo
{
#ifdef _WIN32
	return of_wsaerr_to_errno(_errNo);
#else
	return _errNo;
#endif
}
@end
