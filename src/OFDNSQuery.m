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

#import "OFDNSQuery.h"
#import "OFString.h"

@implementation OFDNSQuery
@synthesize host = _host, recordClass = _recordClass, recordType = _recordType;

+ (instancetype)queryWithHost: (OFString *)host
{
	return [[[self alloc] initWithHost: host] autorelease];
}

+ (instancetype)queryWithHost: (OFString *)host
		  recordClass: (of_dns_resource_record_class_t)recordClass
		   recordType: (of_dns_resource_record_type_t)recordType
{
	return [[[self alloc] initWithHost: host
			       recordClass: recordClass
				recordType: recordType] autorelease];
}

- (instancetype)initWithHost: (OFString *)host
{
	return [self initWithHost: host
		      recordClass: OF_DNS_RESOURCE_RECORD_CLASS_IN
		       recordType: OF_DNS_RESOURCE_RECORD_TYPE_ALL];
}

- (instancetype)initWithHost: (OFString *)host
		 recordClass: (of_dns_resource_record_class_t)recordClass
		  recordType: (of_dns_resource_record_type_t)recordType
{
	self = [super init];

	@try {
		_host = [host copy];
		_recordClass = recordClass;
		_recordType = recordType;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	[_host release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFDNSQuery *query;

	if (![object isKindOfClass: [OFDNSQuery class]])
		return false;

	query = object;

	if (query->_host != _host && ![query->_host isEqual: _host])
		return false;
	if (query->_recordClass != _recordClass)
		return false;
	if (query->_recordType != _recordType)
		return false;

	return true;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);
	OF_HASH_ADD_HASH(hash, _host.hash);
	OF_HASH_ADD(hash, _recordClass);
	OF_HASH_ADD(hash, _recordType);
	OF_HASH_FINALIZE(hash);

	return hash;
}

- (id)copy
{
	return [self retain];
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<%@ %@ %@ %@>",
	    self.className, _host,
	    of_dns_resource_record_class_to_string(_recordClass),
	    of_dns_resource_record_type_to_string(_recordType)];
}
@end
