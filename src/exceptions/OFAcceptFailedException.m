/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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

#import "OFAcceptFailedException.h"
#import "OFString.h"

@implementation OFAcceptFailedException
@synthesize socket = _socket, errNo = _errNo;

+ (instancetype)exceptionWithSocket: (id)socket
			      errNo: (int)errNo
{
	return [[[self alloc] initWithSocket: socket
				       errNo: errNo] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithSocket: (id)socket
	   errNo: (int)errNo
{
	self = [super init];

	_socket = [socket retain];
	_errNo = errNo;

	return self;
}

- (void)dealloc
{
	[_socket release];

	[super dealloc];
}

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"Failed to accept connection in socket of class %@: %@",
	    [_socket class], of_strerror(_errNo)];
}
@end
