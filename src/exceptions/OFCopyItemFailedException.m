/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFCopyItemFailedException.h"
#import "OFIRI.h"
#import "OFString.h"

@implementation OFCopyItemFailedException
@synthesize sourceIRI = _sourceIRI, destinationIRI = _destinationIRI;
@synthesize errNo = _errNo;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithSourceIRI: (OFIRI *)sourceIRI
			destinationIRI: (OFIRI *)destinationIRI
				 errNo: (int)errNo
{
	return [[[self alloc] initWithSourceIRI: sourceIRI
				 destinationIRI: destinationIRI
					  errNo: errNo] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithSourceIRI: (OFIRI *)sourceIRI
		   destinationIRI: (OFIRI *)destinationIRI
			    errNo: (int)errNo
{
	self = [super init];

	@try {
		_sourceIRI = [sourceIRI copy];
		_destinationIRI = [destinationIRI copy];
		_errNo = errNo;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_sourceIRI release];
	[_destinationIRI release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"Failed to copy item %@ to %@: %@",
	    _sourceIRI, _destinationIRI, OFStrError(_errNo)];
}
@end
