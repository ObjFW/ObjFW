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

#import "OFLinkFailedException.h"
#import "OFString.h"

#ifdef OF_HAVE_LINK
@implementation OFLinkFailedException
+ (instancetype)exceptionWithSourcePath: (OFString*)sourcePath
			destinationPath: (OFString*)destinationPath
				  errNo: (int)errNo
{
	return [[[self alloc] initWithSourcePath: sourcePath
				 destinationPath: destinationPath
					   errNo: errNo] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithSourcePath: (OFString*)sourcePath
     destinationPath: (OFString*)destinationPath
	       errNo: (int)errNo
{
	self = [super init];

	@try {
		_sourcePath = [sourcePath copy];
		_destinationPath = [destinationPath copy];
		_errNo = errNo;
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
	    @"Failed to link file %@ to %@: %@",
	    _sourcePath, _destinationPath, of_strerror(_errNo)];
}

- (OFString*)sourcePath
{
	OF_GETTER(_sourcePath, true)
}

- (OFString*)destinationPath
{
	OF_GETTER(_destinationPath, true)
}

- (int)errNo
{
	return _errNo;
}
@end
#endif
