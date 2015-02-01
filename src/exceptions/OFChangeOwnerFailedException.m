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

#import "OFChangeOwnerFailedException.h"
#import "OFString.h"

#ifdef OF_HAVE_CHOWN
@implementation OFChangeOwnerFailedException
+ (instancetype)exceptionWithPath: (OFString*)path
			    owner: (OFString*)owner
			    group: (OFString*)group
			    errNo: (int)errNo
{
	return [[[self alloc] initWithPath: path
				     owner: owner
				     group: group
				     errNo: errNo] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithPath: (OFString*)path
	 owner: (OFString*)owner
	 group: (OFString*)group
	 errNo: (int)errNo
{
	self = [super init];

	@try {
		_path  = [path copy];
		_owner = [owner copy];
		_group = [group copy];
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
	[_owner release];
	[_group release];

	[super dealloc];
}

- (OFString*)description
{
	if (_group == nil)
		return [OFString stringWithFormat:
		    @"Failed to change owner of item at path %@ to %@: %@",
		    _path, _owner, of_strerror(_errNo)];
	else if (_owner == nil)
		return [OFString stringWithFormat:
		    @"Failed to change group of item at path %@ to %@: %@",
		     _path, _group, of_strerror(_errNo)];
	else
		return [OFString stringWithFormat:
		    @"Failed to change owner of item at path %@ to %@:%@: %@",
		    _path, _owner, _group, of_strerror(_errNo)];
}

- (OFString*)path
{
	OF_GETTER(_path, true)
}

- (OFString*)owner
{
	OF_GETTER(_owner, true)
}

- (OFString*)group
{
	OF_GETTER(_group, true)
}

- (int)errNo
{
	return _errNo;
}
@end
#endif
