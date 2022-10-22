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

#import "OFBindDDPSocketFailedException.h"
#import "OFData.h"
#import "OFString.h"

@implementation OFBindDDPSocketFailedException
@synthesize port = _port;

+ (instancetype)exceptionWithSocket: (id)sock errNo: (int)errNo
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithPort: (uint8_t)port
			   socket: (id)sock
			    errNo: (int)errNo
{
	return [[[self alloc] initWithPort: port
				    socket: sock
				     errNo: errNo] autorelease];
}

- (instancetype)initWithSocket: (id)sock errNo: (int)errNo
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithPort: (uint8_t)port
		      socket: (id)sock
		       errNo: (int)errNo
{
	self = [super initWithSocket: sock errNo: errNo];

	@try {
		_port = port;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Binding to port %" @PRIx8 @" failed in socket of type %@: %@",
	    _port, [_socket class], OFStrError(_errNo)];
}
@end
