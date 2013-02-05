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

#import "OFOpenFileFailedException.h"
#import "OFString.h"

#import "common.h"

@implementation OFOpenFileFailedException
+ (instancetype)exceptionWithClass: (Class)class_
			      path: (OFString*)path
			      mode: (OFString*)mode
{
	return [[[self alloc] initWithClass: class_
				       path: path
				       mode: mode] autorelease];
}

- initWithClass: (Class)class_
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	abort();
}

- initWithClass: (Class)class_
	   path: (OFString*)path_
	   mode: (OFString*)mode_
{
	self = [super initWithClass: class_];

	@try {
		path  = [path_ copy];
		mode  = [mode_ copy];
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
	[mode release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Failed to open file %@ with mode %@ in class %@! " ERRFMT, path,
	    mode, inClass, ERRPARAM];

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

- (OFString*)mode
{
	OF_GETTER(mode, NO)
}
@end
