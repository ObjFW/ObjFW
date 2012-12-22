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

#include <stdlib.h>

#import "OFCopyFileFailedException.h"
#import "OFString.h"

#import "common.h"

@implementation OFCopyFileFailedException
+ (instancetype)exceptionWithClass: (Class)class_
			sourcePath: (OFString*)source
		   destinationPath: (OFString*)destination
{
	return [[[self alloc] initWithClass: class_
				 sourcePath: source
			    destinationPath: destination] autorelease];
}

- initWithClass: (Class)class_
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
		abort();
	} @catch (id e) {
		[self release];
		@throw e;
	}
}

-   initWithClass: (Class)class_
       sourcePath: (OFString*)source
  destinationPath: (OFString*)destination
{
	self = [super initWithClass: class_];

	@try {
		sourcePath = [source copy];
		destinationPath = [destination copy];
		errNo = GET_ERRNO;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[sourcePath release];
	[destinationPath release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Failed to copy file %@ to %@ in class %@! " ERRFMT,
	    sourcePath, destinationPath, inClass, ERRPARAM];

	return description;
}

- (int)errNo
{
	return errNo;
}

- (OFString*)sourcePath
{
	OF_GETTER(sourcePath, NO)
}

- (OFString*)destinationPath
{
	OF_GETTER(destinationPath, NO)
}
@end
