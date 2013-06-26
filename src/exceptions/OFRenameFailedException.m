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

#import "OFRenameFailedException.h"
#import "OFString.h"

#import "common.h"

@implementation OFRenameFailedException
+ (instancetype)exceptionWithSourcePath: (OFString*)sourcePath
			destinationPath: (OFString*)destinationPath
{
	return [[[self alloc] initWithSourcePath: sourcePath
				 destinationPath: destinationPath] autorelease];
}

- init
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	abort();
}

- initWithSourcePath: (OFString*)sourcePath
     destinationPath: (OFString*)destinationPath
{
	self = [super init];

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
	    @"Failed to rename item at path %@ to %@! " ERRFMT, _sourcePath,
	    _destinationPath, ERRPARAM];
}

- (OFString*)sourcePath
{
	OF_GETTER(_sourcePath, false)
}

- (OFString*)destinationPath
{
	OF_GETTER(_destinationPath, false)
}

- (int)errNo
{
	return _errNo;
}
@end
