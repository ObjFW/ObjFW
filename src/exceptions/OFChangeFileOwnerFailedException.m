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

#import "OFChangeFileOwnerFailedException.h"
#import "OFString.h"

#import "common.h"

#ifndef _WIN32
@implementation OFChangeFileOwnerFailedException
+ (instancetype)exceptionWithClass: (Class)class
			      path: (OFString*)path
			     owner: (OFString*)owner
			     group: (OFString*)group
{
	return [[[self alloc] initWithClass: class
				       path: path
				      owner: owner
				      group: group] autorelease];
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
	  owner: (OFString*)owner
	  group: (OFString*)group
{
	self = [super initWithClass: class];

	@try {
		_path  = [path copy];
		_owner = [owner copy];
		_group = [group copy];
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
	[_owner release];
	[_group release];

	[super dealloc];
}

- (OFString*)description
{
	if (_group == nil)
		return [OFString stringWithFormat:
		    @"Failed to change owner for file %@ to %@ in class %@! "
		    ERRFMT, _path, _owner, _inClass, ERRPARAM];
	else if (_owner == nil)
		return [OFString stringWithFormat:
		    @"Failed to change group for file %@ to %@ in class %@! "
		    ERRFMT, _path, _group, _inClass, ERRPARAM];
	else
		return [OFString stringWithFormat:
		    @"Failed to change owner for file %@ to %@:%@ in class %@! "
		    ERRFMT, _path, _owner, _group, _inClass, ERRPARAM];
}

- (int)errNo
{
	return _errNo;
}

- (OFString*)path
{
	OF_GETTER(_path, NO)
}

- (OFString*)owner
{
	OF_GETTER(_owner, NO)
}

- (OFString*)group
{
	OF_GETTER(_group, NO)
}
@end
#endif
