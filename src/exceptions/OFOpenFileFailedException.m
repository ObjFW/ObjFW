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

#import "OFOpenFileFailedException.h"
#import "OFString.h"

@implementation OFOpenFileFailedException
+ (instancetype)exceptionWithPath: (OFString*)path
			     mode: (OFString*)mode
{
	return [[[self alloc] initWithPath: path
				      mode: mode] autorelease];
}

+ (instancetype)exceptionWithPath: (OFString*)path
			     mode: (OFString*)mode
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

- initWithPath: (OFString*)path
	  mode: (OFString*)mode
{
	self = [super init];

	@try {
		_path  = [path copy];
		_mode  = [mode copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithPath: (OFString*)path
	  mode: (OFString*)mode
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

- (OFString*)description
{
	if (_errNo != 0)
		return [OFString stringWithFormat:
		    @"Failed to open file %@ with mode %@: %@",
		    _path, _mode, of_strerror(_errNo)];
	else
		return [OFString stringWithFormat:
		    @"Failed to open file %@ with mode %@!",
		    _path, _mode];
}

- (OFString*)path
{
	OF_GETTER(_path, true)
}

- (OFString*)mode
{
	OF_GETTER(_mode, true)
}

- (int)errNo
{
	return _errNo;
}
@end
