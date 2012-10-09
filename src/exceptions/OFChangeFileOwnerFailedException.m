/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#import "OFChangeFileOwnerFailedException.h"
#import "OFString.h"

#import "OFNotImplementedException.h"

#import "common.h"

#ifndef _WIN32
@implementation OFChangeFileOwnerFailedException
+ (instancetype)exceptionWithClass: (Class)class_
			      path: (OFString*)path
			     owner: (OFString*)owner
			     group: (OFString*)group
{
	return [[[self alloc] initWithClass: class_
				       path: path
				      owner: owner
				      group: group] autorelease];
}

- initWithClass: (Class)class_
{
	Class c = [self class];
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithClass: (Class)class_
	   path: (OFString*)path_
	  owner: (OFString*)owner_
	  group: (OFString*)group_
{
	self = [super initWithClass: class_];

	@try {
		path  = [path_ copy];
		owner = [owner_ copy];
		group = [group_ copy];
		errNo = GET_ERRNO;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[path release];
	[owner release];
	[group release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	if (group == nil)
		description = [[OFString alloc] initWithFormat:
		    @"Failed to change owner for file %@ to %@ in class %@! "
		    ERRFMT, path, owner, inClass, ERRPARAM];
	else if (owner == nil)
		description = [[OFString alloc] initWithFormat:
		    @"Failed to change group for file %@ to %@ in class %@! "
		    ERRFMT, path, group, inClass, ERRPARAM];
	else
		description = [[OFString alloc] initWithFormat:
		    @"Failed to change owner for file %@ to %@:%@ in class %@! "
		    ERRFMT, path, owner, group, inClass, ERRPARAM];

	return description;
}

- (int)errNo
{
	return errNo;
}

- (OFString*)path
{
	OF_GETTER(path, NO)
}

- (OFString*)owner
{
	OF_GETTER(owner, NO)
}

- (OFString*)group
{
	OF_GETTER(group, NO)
}
@end
#endif
