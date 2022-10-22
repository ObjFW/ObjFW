/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#import "OFBindIPXSocketFailedException.h"
#import "OFString.h"

@implementation OFBindIPXSocketFailedException
@synthesize port = _port, packetType = _packetType;

+ (instancetype)exceptionWithSocket: (id)sock errNo: (int)errNo
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithPort: (uint16_t)port
		       packetType: (uint8_t)packetType
			   socket: (id)sock
			    errNo: (int)errNo
{
	return [[[self alloc] initWithPort: port
				packetType: packetType
				    socket: sock
				     errNo: errNo] autorelease];
}

- (instancetype)initWithSocket: (id)sock errNo: (int)errNo
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithPort: (uint16_t)port
		  packetType: (uint8_t)packetType
		      socket: (id)sock
		       errNo: (int)errNo
{
	self = [super initWithSocket: sock errNo: errNo];

	@try {
		_port = port;
		_packetType = packetType;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Binding to port %" @PRIx16 @" for packet type %" @PRIx8
	    @" failed in socket of type %@: %@",
	    _port, _packetType, [_socket class], OFStrError(_errNo)];
}
@end
