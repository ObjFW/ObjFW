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

#import "OFDNSQuery.h"
#import "OFString.h"

@implementation OFDNSQuery
@synthesize domainName = _domainName, DNSClass = _DNSClass;
@synthesize recordType = _recordType;

+ (instancetype)queryWithDomainName: (OFString *)domainName
			   DNSClass: (OFDNSClass)DNSClass
			 recordType: (OFDNSRecordType)recordType
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithDomainName: domainName
				    DNSClass: DNSClass
				  recordType: recordType]);
}

- (instancetype)initWithDomainName: (OFString *)domainName
			  DNSClass: (OFDNSClass)DNSClass
			recordType: (OFDNSRecordType)recordType
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		if (![domainName hasSuffix: @"."])
			domainName = [domainName stringByAppendingString: @"."];

		_domainName = [domainName.lowercaseString copy];
		_DNSClass = DNSClass;
		_recordType = recordType;

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
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
	objc_release(_domainName);

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

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);
	OFHashAddHash(&hash, _domainName.hash);
	OFHashAddByte(&hash, _DNSClass);
	OFHashAddByte(&hash, _recordType);
	OFHashFinalize(&hash);

	return hash;
}

- (id)copy
{
	return objc_retain(self);
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<%@ %@ %@ %@>",
	    self.className, _domainName, OFDNSClassName(_DNSClass),
	    OFDNSRecordTypeName(_recordType)];
}
@end
