/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#import "OFLinkItemFailedException.h"
#import "OFString.h"
#import "OFURI.h"

@implementation OFLinkItemFailedException
@synthesize sourceURI = _sourceURI, destinationURI = _destinationURI;
@synthesize errNo = _errNo;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithSourceURI: (OFURI *)sourceURI
			destinationURI: (OFURI *)destinationURI
				 errNo: (int)errNo
{
	return [[[self alloc] initWithSourceURI: sourceURI
				 destinationURI: destinationURI
					  errNo: errNo] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithSourceURI: (OFURI *)sourceURI
		   destinationURI: (OFURI *)destinationURI
			    errNo: (int)errNo
{
	self = [super init];

	@try {
		_sourceURI = [sourceURI copy];
		_destinationURI = [destinationURI copy];
		_errNo = errNo;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_sourceURI release];
	[_destinationURI release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"Failed to link file %@ to %@: %@",
	    _sourceURI, _destinationURI, OFStrError(_errNo)];
}
@end
