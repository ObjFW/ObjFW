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

#import "OFAlreadyConnectedException.h"
#import "OFString.h"
#import "OFTCPSocket.h"

#import "common.h"

@implementation OFAlreadyConnectedException
+ (instancetype)exceptionWithSocket: (OFTCPSocket*)socket
{
	return [[[self alloc] initWithSocket: socket] autorelease];
}

- initWithSocket: (OFTCPSocket*)socket
{
	self = [super init];

	_socket = [socket retain];

	return self;
}

- (void)dealloc
{
	[_socket release];

	[super dealloc];
}

- (OFString*)description
{
	if (_socket)
		return [OFString stringWithFormat:
		    @"The socket of type %@ is already connected or bound and "
		    @"thus can't be connected or bound again!",
		    [_socket class]];
	else
		return @"A connection has already been established!";
}

- (OFTCPSocket*)socket
{
	OF_GETTER(_socket, true)
}
@end
