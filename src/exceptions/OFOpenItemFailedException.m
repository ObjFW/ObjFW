/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#import "OFOpenItemFailedException.h"
#import "OFString.h"

@implementation OFOpenItemFailedException
@synthesize path = _path, mode = _mode, errNo = _errNo;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithPath: (OFString *)path
			     mode: (OFString *)mode
			    errNo: (int)errNo
{
	return [[[self alloc] initWithPath: path
				      mode: mode
				     errNo: errNo] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithPath: (OFString *)path
	  mode: (OFString *)mode
	 errNo: (int)errNo
{
	self = [super init];

	@try {
		_path  = [path copy];
		_mode  = [mode copy];
		_errNo = errNo;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_path release];
	[_mode release];

	[super dealloc];
}

- (OFString *)description
{
	if (_mode != nil)
		return [OFString stringWithFormat:
		    @"Failed to open item %@ with mode %@: %@",
		    _path, _mode, of_strerror(_errNo)];
	else
		return [OFString stringWithFormat:
		    @"Failed to open item %@: %@", _path, of_strerror(_errNo)];
}
@end
