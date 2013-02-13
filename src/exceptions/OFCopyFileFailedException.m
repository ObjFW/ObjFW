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

#import "OFCopyFileFailedException.h"
#import "OFString.h"

#import "common.h"

@implementation OFCopyFileFailedException
+ (instancetype)exceptionWithClass: (Class)class
			sourcePath: (OFString*)sourcePath
		   destinationPath: (OFString*)destinationPath
{
	return [[[self alloc] initWithClass: class
				 sourcePath: sourcePath
			    destinationPath: destinationPath] autorelease];
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

-   initWithClass: (Class)class
       sourcePath: (OFString*)sourcePath
  destinationPath: (OFString*)destinationPath
{
	self = [super initWithClass: class];

	@try {
		_sourcePath = [sourcePath copy];
		_destinationPath = [destinationPath copy];
		_errNo = GET_ERRNO;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_sourcePath release];
	[_destinationPath release];

	[super dealloc];
}

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"Failed to copy file %@ to %@ in class %@! " ERRFMT,
	    _sourcePath, _destinationPath, _inClass, ERRPARAM];
}

- (int)errNo
{
	return _errNo;
}

- (OFString*)sourcePath
{
	OF_GETTER(_sourcePath, NO)
}

- (OFString*)destinationPath
{
	OF_GETTER(_destinationPath, NO)
}
@end
