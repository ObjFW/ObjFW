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

#include <stdlib.h>

#import "OFChangeDirectoryFailedException.h"
#import "OFString.h"

#import "common.h"

@implementation OFChangeDirectoryFailedException
+ (instancetype)exceptionWithClass: (Class)class
			      path: (OFString*)path
{
	return [[[self alloc] initWithClass: class
				       path: path] autorelease];
}

- initWithClass: (Class)class
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	abort();
}

- initWithClass: (Class)class
	   path: (OFString*)path
{
	self = [super initWithClass: class];

	@try {
		_path  = [path copy];
		_errNo = GET_ERRNO;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_path release];

	[super dealloc];
}

- (OFString*)description
{
	if (_description != nil)
		return _description;

	_description = [[OFString alloc] initWithFormat:
	    @"Failed to change to directory %@ in class %@! " ERRFMT, _path,
	    _inClass, ERRPARAM];

	return _description;
}

- (int)errNo
{
	return _errNo;
}

- (OFString*)path
{
	OF_GETTER(_path, NO)
}
@end
