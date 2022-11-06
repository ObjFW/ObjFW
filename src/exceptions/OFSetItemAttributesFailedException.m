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

#import "OFSetItemAttributesFailedException.h"
#import "OFString.h"
#import "OFURI.h"

@implementation OFSetItemAttributesFailedException
@synthesize URI = _URI, attributes = _attributes;
@synthesize failedAttribute = _failedAttribute, errNo = _errNo;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithURI: (OFURI *)URI
		      attributes: (OFFileAttributes)attributes
		 failedAttribute: (OFFileAttributeKey)failedAttribute
			   errNo: (int)errNo
{
	return [[[self alloc] initWithURI: URI
			       attributes: attributes
			  failedAttribute: failedAttribute
				    errNo: errNo] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithURI: (OFURI *)URI
		 attributes: (OFFileAttributes)attributes
	    failedAttribute: (OFFileAttributeKey)failedAttribute
		      errNo: (int)errNo
{
	self = [super init];

	@try {
		_URI = [URI copy];
		_attributes = [attributes copy];
		_failedAttribute = [failedAttribute copy];
		_errNo = errNo;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_URI release];
	[_attributes release];
	[_failedAttribute release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Failed to set attribute %@ for item %@: %@",
	    _failedAttribute, _URI, OFStrError(_errNo)];
}
@end
