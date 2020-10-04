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

#import "OFObject.h"
#import "OFDNSResourceRecord.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;

/**
 * @class OFDNSQuery OFDNSQuery.h ObjFW/OFDNSQuery.h
 *
 * @brief A class representing a DNS query.
 */
@interface OFDNSQuery: OFObject <OFCopying>
{
	OFString *_domainName;
	of_dns_class_t _DNSClass;
	of_dns_record_type_t _recordType;
	OF_RESERVE_IVARS(OFDNSQuery, 4)
}

/**
 * @brief The domain name of the query.
 */
@property (readonly, nonatomic) OFString *domainName;

/**
 * @brief The DNS class of the query.
 */
@property (readonly, nonatomic) of_dns_class_t DNSClass;

/**
 * @brief The record type of the query.
 */
@property (readonly, nonatomic) of_dns_record_type_t recordType;

/**
 * @brief Creates a new, autoreleased OFDNSQuery.
 *
 * @param domainName The domain name to query
 * @param DNSClass The DNS class of the query
 * @param recordType The record type of the query
 * @return A new, autoreleased OFDNSQuery
 */
+ (instancetype)queryWithDomainName: (OFString *)domainName
			   DNSClass: (of_dns_class_t)DNSClass
			 recordType: (of_dns_record_type_t)recordType;

/**
 * @brief Initializes an already allocated OFDNSQuery.
 *
 * @param domainName The domain name to query
 * @param DNSClass The DNS class of the query
 * @param recordType The record type of the query
 * @return An initialized OFDNSQuery
 */
- (instancetype)initWithDomainName: (OFString *)domainName
			  DNSClass: (of_dns_class_t)DNSClass
			recordType: (of_dns_record_type_t)recordType
    OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
