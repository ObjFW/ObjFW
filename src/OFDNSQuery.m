/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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
@synthesize domainName = _domainName, DNSClass = _DNSClass;
@synthesize recordType = _recordType;

+ (instancetype)queryWithDomainName: (OFString *)domainName
			   DNSClass: (of_dns_class_t)DNSClass
			 recordType: (of_dns_record_type_t)recordType
{
	return [[[self alloc] initWithDomainName: domainName
					DNSClass: DNSClass
				      recordType: recordType] autorelease];
}

- (instancetype)initWithDomainName: (OFString *)domainName
			  DNSClass: (of_dns_class_t)DNSClass
			recordType: (of_dns_record_type_t)recordType
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		if (![domainName hasSuffix: @"."])
			domainName = [domainName stringByAppendingString: @"."];

		_domainName = [domainName copy];
		_DNSClass = DNSClass;
		_recordType = recordType;

		objc_autoreleasePoolPop(pool);
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
	[_domainName release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFDNSQuery *query;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFDNSQuery class]])
		return false;

	query = object;

	if (query->_domainName != _domainName &&
	    ![query->_domainName isEqual: _domainName])
		return false;
	if (query->_DNSClass != _DNSClass)
		return false;
	if (query->_recordType != _recordType)
		return false;

	return true;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);
	OF_HASH_ADD_HASH(hash, _domainName.hash);
	OF_HASH_ADD(hash, _DNSClass);
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
	    self.className, _domainName, of_dns_class_to_string(_DNSClass),
	    of_dns_record_type_to_string(_recordType)];
}
@end
