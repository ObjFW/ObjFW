/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFSetItemAttributesFailedException.h"
#import "OFIRI.h"
#import "OFString.h"

@implementation OFSetItemAttributesFailedException
@synthesize IRI = _IRI, attributes = _attributes;
@synthesize failedAttribute = _failedAttribute, errNo = _errNo;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithIRI: (OFIRI *)IRI
		      attributes: (OFFileAttributes)attributes
		 failedAttribute: (OFFileAttributeKey)failedAttribute
			   errNo: (int)errNo
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithIRI: IRI
			   attributes: attributes
		      failedAttribute: failedAttribute
				errNo: errNo]);
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithIRI: (OFIRI *)IRI
		 attributes: (OFFileAttributes)attributes
	    failedAttribute: (OFFileAttributeKey)failedAttribute
		      errNo: (int)errNo
{
	self = [super init];

	@try {
		_IRI = [IRI copy];
		_attributes = [attributes copy];
		_failedAttribute = [failedAttribute copy];
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
	objc_release(_attributes);
	objc_release(_failedAttribute);

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Failed to set attribute %@ for item %@: %@",
	    _failedAttribute, _IRI, OFStrError(_errNo)];
}
@end
