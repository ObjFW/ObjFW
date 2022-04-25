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

#import "OFOpenItemFailedException.h"
#import "OFString.h"
#import "OFURL.h"

@implementation OFOpenItemFailedException
@synthesize URL = _URL, mode = _mode, errNo = _errNo;

+ (instancetype)exceptionWithURL: (OFURL *)URL
			    mode: (OFString *)mode
			   errNo: (int)errNo
{
	return [[[self alloc] initWithURL: URL
				     mode: mode
				    errNo: errNo] autorelease];
}

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

- (instancetype)initWithURL: (OFURL *)URL
		       mode: (OFString *)mode
		      errNo: (int)errNo
{
	self = [super init];

	@try {
		_URL = [URL copy];
		_mode = [mode copy];
		_errNo = errNo;
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
	[_URL release];
	[_mode release];

	[super dealloc];
}

- (OFString *)description
{
	if (_mode != nil)
		return [OFString stringWithFormat:
		    @"Failed to open item %@ with mode %@: %@",
		    _URL, _mode, OFStrError(_errNo)];
	else
		return [OFString stringWithFormat:
		    @"Failed to open item %@: %@", _URL, OFStrError(_errNo)];
}
@end
