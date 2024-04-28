/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFObject.h"
#import "OFDNSResourceRecord.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;

/**
 * @class OFDNSQuery OFDNSQuery.h ObjFW/OFDNSQuery.h
 *
 * @brief A class representing a DNS query.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFDNSQuery: OFObject <OFCopying>
{
	OFString *_domainName;
	OFDNSClass _DNSClass;
	OFDNSRecordType _recordType;
}

/**
 * @brief The domain name of the query.
 */
@property (readonly, nonatomic) OFString *domainName;

/**
 * @brief The DNS class of the query.
 */
@property (readonly, nonatomic) OFDNSClass DNSClass;

/**
 * @brief The record type of the query.
 */
@property (readonly, nonatomic) OFDNSRecordType recordType;

/**
 * @brief Creates a new, autoreleased OFDNSQuery.
 *
 * @param domainName The domain name to query
 * @param DNSClass The DNS class of the query
 * @param recordType The record type of the query
 * @return A new, autoreleased OFDNSQuery
 */
+ (instancetype)queryWithDomainName: (OFString *)domainName
			   DNSClass: (OFDNSClass)DNSClass
			 recordType: (OFDNSRecordType)recordType;

/**
 * @brief Initializes an already allocated OFDNSQuery.
 *
 * @param domainName The domain name to query
 * @param DNSClass The DNS class of the query
 * @param recordType The record type of the query
 * @return An initialized OFDNSQuery
 */
- (instancetype)initWithDomainName: (OFString *)domainName
			  DNSClass: (OFDNSClass)DNSClass
			recordType: (OFDNSRecordType)recordType
    OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
