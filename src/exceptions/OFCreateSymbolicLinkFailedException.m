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

#import "OFCreateSymbolicLinkFailedException.h"
#import "OFIRI.h"
#import "OFString.h"

@implementation OFCreateSymbolicLinkFailedException
@synthesize IRI = _IRI, target = _target, errNo = _errNo;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithIRI: (OFIRI *)IRI
			  target: (OFString *)target
			   errNo: (int)errNo
{
	return objc_autoreleaseReturnValue([[self alloc] initWithIRI: IRI
							      target: target
							       errNo: errNo]);
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithIRI: (OFIRI *)IRI
		     target: (OFString *)target
		      errNo: (int)errNo
{
	self = [super init];

	@try {
		_IRI = [IRI copy];
		_target = [target copy];
		_errNo = errNo;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_IRI);
	objc_release(_target);

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Failed to create symbolic link %@ with target %@: %@",
	    _IRI, _target, OFStrError(_errNo)];
}
@end
