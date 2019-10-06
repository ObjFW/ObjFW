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

#import "OFObject.h"
#import "OFDNSResourceRecord.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFDNSQuery OFDNSQuery.h ObjFW/OFDNSQuery.h
 *
 * @brief A class representing a DNS query.
 */
@interface OFDNSQuery: OFObject <OFCopying>
{
	OFString *_host;
	of_dns_resource_record_class_t _recordClass;
	of_dns_resource_record_type_t _recordType;
	OF_RESERVE_IVARS(4)
}

/*!
 * @brief The host to resolve.
 */
@property (readonly, nonatomic) OFString *host;

/*!
 * @brief The record class of the query.
 */
@property (readonly, nonatomic) of_dns_resource_record_class_t recordClass;

/*!
 * @brief The record type of the query.
 */
@property (readonly, nonatomic) of_dns_resource_record_type_t recordType;

/*!
 * @brief Creates a new, autoreleased OFDNSQuery with IN class and type ALL.
 *
 * @param host The host to resolve
 * @return A new, autoreleased OFDNSQuery
 */
+ (instancetype)queryWithHost: (OFString *)host;

/*!
 * @brief Creates a new, autoreleased OFDNSQuery.
 *
 * @param host The host to resolve
 * @param recordClass The record class of the query
 * @param recordType The record type of the query
 * @return A new, autoreleased OFDNSQuery
 */
+ (instancetype)queryWithHost: (OFString *)host
		  recordClass: (of_dns_resource_record_class_t)recordClass
		   recordType: (of_dns_resource_record_type_t)recordType;

/*!
 * @brief Initializes an already allocated OFDNSQuery with IN class and type
 *	  ALL.
 *
 * @param host The host to resolve
 * @return An initialized OFDNSQuery
 */
- (instancetype)initWithHost: (OFString *)host;

/*!
 * @brief Initializes an already allocated OFDNSQuery.
 *
 * @param host The host to resolve
 * @param recordClass The record class of the query
 * @param recordType The record type of the query
 * @return An initialized OFDNSQuery
 */
- (instancetype)initWithHost: (OFString *)host
		 recordClass: (of_dns_resource_record_class_t)recordClass
		  recordType: (of_dns_resource_record_type_t)recordType
    OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
