/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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
#ifdef OF_HAVE_SOCKETS
# import "OFStreamSocket.h"
# import "OFUDPSocket.h"
#endif

#import "common.h"

@implementation OFReadOrWriteFailedException
+ (instancetype)exceptionWithObject: (id)object
		    requestedLength: (size_t)requestedLength
{
	return [[[self alloc] initWithObject: object
			     requestedLength: requestedLength] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

-  initWithObject: (id)object
  requestedLength: (size_t)requestedLength
{
	self = [super init];

	_object = [object retain];
	_requestedLength = requestedLength;

#ifdef OF_HAVE_SOCKETS
	if ([object isKindOfClass: [OFStreamSocket class]] ||
	    [object isKindOfClass: [OFUDPSocket class]])
		_errNo = GET_SOCK_ERRNO;
	else
#endif
		_errNo = GET_ERRNO;

	return self;
}

- (void)dealloc
{
	[_object release];

	[super dealloc];
}

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"Failed to read or write %zu bytes from / to an object of type "
	    @"%@! " ERRFMT, _requestedLength, [_object class], ERRPARAM];
}

- (id)object
{
	OF_GETTER(_object, true)
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
