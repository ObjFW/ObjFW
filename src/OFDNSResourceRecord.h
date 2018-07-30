/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

/*! @file */

@class OFData;

/*!
 * @brief The class of a DNS resource record.
 */
typedef enum {
	/*! IN */
	OF_DNS_RESOURCE_RECORD_CLASS_IN	 =   1,
	/*! Any class. Only for queries. */
	OF_DNS_RESOURCE_RECORD_CLASS_ANY = 255,
} of_dns_resource_record_class_t;

/*!
 * @brief The type of a DNS resource record.
 */
typedef enum {
	/*! A */
	OF_DNS_RESOURCE_RECORD_TYPE_A	  =   1,
	/*! NS */
	OF_DNS_RESOURCE_RECORD_TYPE_NS	  =   2,
	/*! CNAME */
	OF_DNS_RESOURCE_RECORD_TYPE_CNAME =   5,
	/*! SOA */
	OF_DNS_RESOURCE_RECORD_TYPE_SOA	  =   6,
	/*! PTR */
	OF_DNS_RESOURCE_RECORD_TYPE_PTR	  =  12,
	/*! MX */
	OF_DNS_RESOURCE_RECORD_TYPE_MX	  =  15,
	/*! TXT */
	OF_DNS_RESOURCE_RECORD_TYPE_TXT	  =  16,
	/*! AAAA */
	OF_DNS_RESOURCE_RECORD_TYPE_AAAA  =  28,
	/*! All types. Only for queries. */
	OF_DNS_RESOURCE_RECORD_TYPE_ALL	  = 255,
} of_dns_resource_record_type_t;

/*!
 * @class OFDNSResourceRecord OFDNSResourceRecord.h ObjFW/OFDNSResourceRecord.h
 *
 * @brief A class representing a DNS resource record.
 */
@interface OFDNSResourceRecord: OFObject
{
	OFString *_name;
	of_dns_resource_record_class_t _recordClass;
	of_dns_resource_record_type_t _recordType;
	id _data;
	uint32_t _TTL;
}

/**
 * @brief The domain name to which the resource record belongs.
 */
@property (readonly, nonatomic) OFString *name;

/*!
 * @brief The class of the data.
 */
@property (readonly, nonatomic) of_dns_resource_record_class_t recordClass;

/*!
 * @brief The resource record type code.
 */
@property (readonly, nonatomic) of_dns_resource_record_type_t recordType;

/*!
 * The class and type-dependent data of the resource.
 */
@property (readonly, nonatomic) id data;

/*!
 * @brief The number of seconds after which the resource record should be
 *	  discarded from the cache.
 */
@property (readonly, nonatomic) uint32_t TTL;

- (instancetype)initWithName: (OFString *)name
		 recordClass: (of_dns_resource_record_class_t)recordClass
		  recordType: (of_dns_resource_record_type_t)recordType
			data: (id)data
			 TTL: (uint32_t)TTL OF_DESIGNATED_INITIALIZER;
@end

/*!
 * @class OFADNSResourceRecord OFDNSResourceRecord.h ObjFW/OFDNSResourceRecord.h
 *
 * @brief A class representing an A DNS resource record.
 */
@interface OFADNSResourceRecord: OFDNSResourceRecord
/*!
 * A string with the IP address.
 */
@property (readonly, nonatomic) OFString *data;
@end

/*!
 * @class OFAAAADNSResourceRecord \
 *	  OFDNSResourceRecord.h ObjFW/OFDNSResourceRecord.h
 *
 * @brief A class represenging a DNS resource record.
 */
@interface OFAAAADNSResourceRecord: OFDNSResourceRecord
/*!
 * A string with the IP address.
 */
@property (readonly, nonatomic) OFString *data;
@end

/*!
 * @class OFCNAMEDNSResourceRecord \
 *	  OFDNSResourceRecord.h ObjFW/OFDNSResourceRecord.h
 *
 * @brief A class representing a CNAME DNS resource record.
 */
@interface OFCNAMEDNSResourceRecord: OFDNSResourceRecord
/*!
 * A string with the alias.
 */
@property (readonly, nonatomic) OFString *data;
@end

#ifdef __cplusplus
extern "C" {
#endif
extern OFString *_Nonnull of_dns_resource_record_class_to_string(
    of_dns_resource_record_class_t recordClass);
extern OFString *_Nonnull of_dns_resource_record_type_to_string(
    of_dns_resource_record_type_t recordType);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
