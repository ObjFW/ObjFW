/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#import "OFChangeFileModeFailedException.h"
#import "OFString.h"

#import "OFNotImplementedException.h"

#import "common.h"

@implementation OFChangeFileModeFailedException
+ exceptionWithClass: (Class)class_
		path: (OFString*)path
		mode: (mode_t)mode
{
	return [(OFChangeFileModeFailedException*)[[self alloc]
	    initWithClass: class_
		     path: path
		     mode: mode] autorelease];
}

- initWithClass: (Class)class_
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithClass: (Class)class_
	   path: (OFString*)path_
	   mode: (mode_t)mode_
{
	self = [super initWithClass: class_];

	@try {
		path  = [path_ copy];
		mode  = mode_;
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

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Failed to change mode for file %@ to %d in class %@! " ERRFMT,
	    path, mode, inClass, ERRPARAM];

	return description;
}

- (int)errNo
{
	return errNo;
}

- (OFString*)path
{
	return path;
}

- (mode_t)mode
{
	return mode;
}
@end
