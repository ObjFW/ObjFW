/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
 *   Jonathan Schleifer <js@heap.zone>
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

#import "OFListenFailedException.h"
#import "OFString.h"

@implementation OFListenFailedException
@synthesize socket = _socket, backLog = _backLog, errNo = _errNo;

+ (instancetype)exceptionWithSocket: (id)socket
			    backLog: (int)backLog
			      errNo: (int)errNo
{
	return [[[self alloc] initWithSocket: socket
				     backLog: backLog
				       errNo: errNo] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithSocket: (id)socket
	 backLog: (int)backLog
	   errNo: (int)errNo
{
	self = [super init];

	_socket = [socket retain];
	_backLog = backLog;
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
	    @"Failed to listen in socket of type %@ with a back log of %d: %@",
	    [_socket class], _backLog, of_strerror(_errNo)];
}
@end
