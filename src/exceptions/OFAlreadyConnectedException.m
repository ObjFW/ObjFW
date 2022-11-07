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

#import "OFAlreadyConnectedException.h"
#import "OFString.h"

@implementation OFAlreadyConnectedException
@synthesize socket = _socket;

+ (instancetype)exceptionWithSocket: (id)sock
{
	return [[[self alloc] initWithSocket: sock] autorelease];
}

- (instancetype)init
{
	return [self initWithSocket: nil];
}

- (instancetype)initWithSocket: (id)sock
{
	self = [super init];

	_socket = [sock retain];

	return self;
}

- (void)dealloc
{
	[_socket release];

	[super dealloc];
}

- (OFString *)description
{
	if (_socket)
		return [OFString stringWithFormat:
		    @"The socket of type %@ is already connected or bound and "
		    @"thus can't be connected or bound again!",
		    [_socket class]];
	else
		return @"A connection has already been established!";
}
@end
