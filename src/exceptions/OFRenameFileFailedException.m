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

#import "OFRenameFileFailedException.h"
#import "OFString.h"

#import "OFNotImplementedException.h"

#import "common.h"

@implementation OFRenameFileFailedException
+ exceptionWithClass: (Class)class_
	  sourcePath: (OFString*)src
     destinationPath: (OFString*)dst
{
	return [[[self alloc] initWithClass: class_
				 sourcePath: src
			    destinationPath: dst] autorelease];
}

- initWithClass: (Class)class_
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

-   initWithClass: (Class)class_
       sourcePath: (OFString*)src
  destinationPath: (OFString*)dst
{
	self = [super initWithClass: class_];

	@try {
		sourcePath = [src copy];
		destinationPath = [dst copy];
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
	    @"Failed to rename file %@ to %@ in class %@! " ERRFMT, sourcePath,
	    destinationPath, inClass, ERRPARAM];

	return description;
}

- (int)errNo
{
	return errNo;
}

- (OFString*)sourcePath
{
	return sourcePath;
}

- (OFString*)destinationPath
{
	return destinationPath;
}
@end
