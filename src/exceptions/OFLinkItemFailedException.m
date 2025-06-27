/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#import "OFLinkItemFailedException.h"
#import "OFIRI.h"
#import "OFString.h"

@implementation OFLinkItemFailedException
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
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithSourceIRI: sourceIRI
			     destinationIRI: destinationIRI
				      errNo: errNo]);
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
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_sourceIRI);
	objc_release(_destinationIRI);

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"Failed to link file %@ to %@: %@",
	    _sourceIRI, _destinationIRI, OFStrError(_errNo)];
}
@end
