/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OTTestSkippedException.h"

@implementation OTTestSkippedException
@synthesize message = _message;

+ (instancetype)exceptionWithMessage: (OFString *)message
{
	return [[[self alloc] initWithMessage: message] autorelease];
}

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

- (instancetype)initWithMessage: (OFString *)message
{
	self = [super init];

	@try {
		_message = [message copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	[_message release];

	[super dealloc];
}

- (OFString *)description
{
	if (_message != nil)
		return [OFString stringWithFormat: @"Test skipped: %@",
						   _message];
	else
		return nil;
}
@end
