/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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
#import "OFURL.h"

@implementation OFSetItemAttributesFailedException
@synthesize URL = _URL, attributes = _attributes;
@synthesize failedAttribute = _failedAttribute, errNo = _errNo;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithURL: (OFURL *)URL
		      attributes: (of_file_attributes_t)attributes
		 failedAttribute: (of_file_attribute_key_t)failedAttribute
			   errNo: (int)errNo
{
	return [[[self alloc] initWithURL: URL
			       attributes: attributes
			  failedAttribute: failedAttribute
				    errNo: errNo] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithURL: (OFURL *)URL
		 attributes: (of_file_attributes_t)attributes
	    failedAttribute: (of_file_attribute_key_t)failedAttribute
		      errNo: (int)errNo
{
	self = [super init];

	@try {
		_URL = [URL copy];
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
	[_URL release];
	[_attributes release];
	[_failedAttribute release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Failed to set attribute %@ for item %@: %@",
	    _failedAttribute, _URL, of_strerror(_errNo)];
}
@end
