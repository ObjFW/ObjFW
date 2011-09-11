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

#import "OFAlreadyConnectedException.h"
#import "OFString.h"
#import "OFTCPSocket.h"

#import "OFNotImplementedException.h"

@implementation OFAlreadyConnectedException
+ newWithClass: (Class)class_
	socket: (OFTCPSocket*)socket
{
	return [[self alloc] initWithClass: class_
				    socket: socket];
}

- initWithClass: (Class)class_
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithClass: (Class)class_
	 socket: (OFTCPSocket*)socket_
{
	self = [super initWithClass: class_];

	socket = [socket_ retain];

	return self;
}

- (void)dealloc
{
	[socket release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"The socket of type %@ is already connected or bound and thus "
	    @"can't be connected or bound again!", inClass];

	return description;
}

- (OFTCPSocket*)socket
{
	return socket;
}
@end
