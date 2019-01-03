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
#import "OFString.h"

#import "socket.h"

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
	/*! HINFO */
	OF_DNS_RESOURCE_RECORD_TYPE_HINFO =  13,
	/*! MX */
	OF_DNS_RESOURCE_RECORD_TYPE_MX	  =  15,
	/*! TXT */
	OF_DNS_RESOURCE_RECORD_TYPE_TXT	  =  16,
	/*! RP */
	OF_DNS_RESOURCE_RECORD_TYPE_RP	  =  17,
	/*! AAAA */
	OF_DNS_RESOURCE_RECORD_TYPE_AAAA  =  28,
	/*! SRV */
	OF_DNS_RESOURCE_RECORD_TYPE_SRV	  =  33,
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
	uint32_t _TTL;
}

/**
 * @brief The domain name to which the resource record belongs.
 */
@property (readonly, nonatomic) OFString *name;

/*!
 * @brief The resource record class code.
 */
@property (readonly, nonatomic) of_dns_resource_record_class_t recordClass;

/*!
 * @brief The resource record type code.
 */
@property (readonly, nonatomic) of_dns_resource_record_type_t recordType;

/*!
 * @brief The number of seconds after which the resource record should be
 *	  discarded from the cache.
 */
@property (readonly, nonatomic) uint32_t TTL;

/*!
 * @brief Initializes an already allocated OFDNSResourceRecord with the
 *	  specified name, class, type, data and time to live.
 *
 * @param name The name for the resource record
 * @param recordClass The class code for the resource record
 * @param recordType The type code for the resource record
 * @param TTL The time to live for the resource record
 * @return An initialized OFDNSResourceRecord
 */
- (instancetype)initWithName: (OFString *)name
		 recordClass: (of_dns_resource_record_class_t)recordClass
		  recordType: (of_dns_resource_record_type_t)recordType
			 TTL: (uint32_t)TTL OF_DESIGNATED_INITIALIZER;
@end

/*!
 * @class OFADNSResourceRecord OFDNSResourceRecord.h ObjFW/OFDNSResourceRecord.h
 *
 * @brief A class representing an A DNS resource record.
 */
@interface OFADNSResourceRecord: OFDNSResourceRecord
{
	of_socket_address_t _address;
}

/*!
 * @brief The IPv4 address of the resource record.
 */
@property (readonly, nonatomic) const of_socket_address_t *address;

- (instancetype)initWithName: (OFString *)name
		 recordClass: (of_dns_resource_record_class_t)recordClass
		  recordType: (of_dns_resource_record_type_t)recordType
			 TTL: (uint32_t)TTL OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated OFADNSResourceRecord with the
 *	  specified name, class, address and time to live.
 *
 * @param name The name for the resource record
 * @param address The address for the resource record
 * @param TTL The time to live for the resource record
 * @return An initialized OFADNSResourceRecord
 */
- (instancetype)initWithName: (OFString *)name
		     address: (const of_socket_address_t *)address
			 TTL: (uint32_t)TTL OF_DESIGNATED_INITIALIZER;
@end

/*!
 * @class OFAAAADNSResourceRecord \
 *	  OFDNSResourceRecord.h ObjFW/OFDNSResourceRecord.h
 *
 * @brief A class represenging a DNS resource record.
 */
@interface OFAAAADNSResourceRecord: OFDNSResourceRecord
{
	of_socket_address_t _address;
}

/*!
 * @brief The IPv6 address of the resource record.
 */
@property (readonly, nonatomic) const of_socket_address_t *address;

- (instancetype)initWithName: (OFString *)name
		 recordClass: (of_dns_resource_record_class_t)recordClass
		  recordType: (of_dns_resource_record_type_t)recordType
			 TTL: (uint32_t)TTL OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated OFAAAADNSResourceRecord with the
 *	  specified name, class, address and time to live.
 *
 * @param name The name for the resource record
 * @param address The address for the resource record
 * @param TTL The time to live for the resource record
 * @return An initialized OFAAAADNSResourceRecord
 */
- (instancetype)initWithName: (OFString *)name
		     address: (const of_socket_address_t *)address
			 TTL: (uint32_t)TTL OF_DESIGNATED_INITIALIZER;
@end

/*!
 * @class OFCNAMEDNSResourceRecord \
 *	  OFDNSResourceRecord.h ObjFW/OFDNSResourceRecord.h
 *
 * @brief A class representing a CNAME DNS resource record.
 */
@interface OFCNAMEDNSResourceRecord: OFDNSResourceRecord
{
	OFString *_alias;
}

/*!
 * @brief The alias of the resource record.
 */
@property (readonly, nonatomic) OFString *alias;

- (instancetype)initWithName: (OFString *)name
		 recordClass: (of_dns_resource_record_class_t)recordClass
		  recordType: (of_dns_resource_record_type_t)recordType
			 TTL: (uint32_t)TTL OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated OFCNAMEDNSResourceRecord with the
 *	  specified name, class, alias and time to live.
 *
 * @param name The name for the resource record
 * @param recordClass The class code for the resource record
 * @param alias The alias for the resource record
 * @param TTL The time to live for the resource record
 * @return An initialized OFCNAMEDNSResourceRecord
 */
- (instancetype)initWithName: (OFString *)name
		 recordClass: (of_dns_resource_record_class_t)recordClass
		       alias: (OFString *)alias
			 TTL: (uint32_t)TTL OF_DESIGNATED_INITIALIZER;
@end

/*!
 * @class OFHINFODNSResourceRecord \
 *	  OFDNSResourceRecord.h ObjFW/OFDNSResourceRecord.h
 *
 * @brief A class representing an HINFO DNS resource record.
 */
@interface OFHINFODNSResourceRecord: OFDNSResourceRecord
{
	OFString *_CPU, *_OS;
}

/*!
 * @brief The CPU of the host info of the resource record.
 */
@property (readonly, nonatomic) OFString *CPU;

/*!
 * @brief The OS of the host info of the resource record.
 */
@property (readonly, nonatomic) OFString *OS;

- (instancetype)initWithName: (OFString *)name
		 recordClass: (of_dns_resource_record_class_t)recordClass
		  recordType: (of_dns_resource_record_type_t)recordType
			 TTL: (uint32_t)TTL OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated OFHINFODNSResourceRecord with the
 *	  specified name, class, domain name and time to live.
 *
 * @param name The name for the resource record
 * @param recordClass The class code for the resource record
 * @param CPU The CPU of the host info for the resource record
 * @param OS The OS of the host info for the resource record
 * @param TTL The time to live for the resource record
 * @return An initialized OFHINFODNSResourceRecord
 */
- (instancetype)initWithName: (OFString *)name
		 recordClass: (of_dns_resource_record_class_t)recordClass
			 CPU: (OFString *)CPU
			  OS: (OFString *)OS
			 TTL: (uint32_t)TTL OF_DESIGNATED_INITIALIZER;
@end

/*!
 * @class OFMXDNSResourceRecord \
 *	  OFDNSResourceRecord.h ObjFW/OFDNSResourceRecord.h
 *
 * @brief A class representing an MX DNS resource record.
 */
@interface OFMXDNSResourceRecord: OFDNSResourceRecord
{
	uint16_t _preference;
	OFString *_mailExchange;
}

/*!
 * @brief The preference of the resource record.
 */
@property (readonly, nonatomic) uint16_t preference;

/*!
 * @brief The mail exchange of the resource record.
 */
@property (readonly, nonatomic) OFString *mailExchange;

- (instancetype)initWithName: (OFString *)name
		 recordClass: (of_dns_resource_record_class_t)recordClass
		  recordType: (of_dns_resource_record_type_t)recordType
			 TTL: (uint32_t)TTL OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated OFMXDNSResourceRecord with the
 *	  specified name, class, preference, mail exchange and time to live.
 *
 * @param name The name for the resource record
 * @param recordClass The class code for the resource record
 * @param preference The preference for the resource record
 * @param mailExchange The mail exchange for the resource record
 * @param TTL The time to live for the resource record
 * @return An initialized OFMXDNSResourceRecord
 */
- (instancetype)initWithName: (OFString *)name
		 recordClass: (of_dns_resource_record_class_t)recordClass
		  preference: (uint16_t)preference
		mailExchange: (OFString *)mailExchange
			 TTL: (uint32_t)TTL OF_DESIGNATED_INITIALIZER;
@end

/*!
 * @class OFNSDNSResourceRecord \
 *	  OFDNSResourceRecord.h ObjFW/OFDNSResourceRecord.h
 *
 * @brief A class representing an NS DNS resource record.
 */
@interface OFNSDNSResourceRecord: OFDNSResourceRecord
{
	OFString *_authoritativeHost;
}

/*!
 * @brief The authoritative host of the resource record.
 */
@property (readonly, nonatomic) OFString *authoritativeHost;

- (instancetype)initWithName: (OFString *)name
		 recordClass: (of_dns_resource_record_class_t)recordClass
		  recordType: (of_dns_resource_record_type_t)recordType
			 TTL: (uint32_t)TTL OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated OFNSDNSResourceRecord with the
 *	  specified name, class, authoritative host and time to live.
 *
 * @param name The name for the resource record
 * @param recordClass The class code for the resource record
 * @param authoritativeHost The authoritative host for the resource record
 * @param TTL The time to live for the resource record
 * @return An initialized OFNSDNSResourceRecord
 */
- (instancetype)initWithName: (OFString *)name
		 recordClass: (of_dns_resource_record_class_t)recordClass
	   authoritativeHost: (OFString *)authoritativeHost
			 TTL: (uint32_t)TTL OF_DESIGNATED_INITIALIZER;
@end

/*!
 * @class OFPTRDNSResourceRecord \
 *	  OFDNSResourceRecord.h ObjFW/OFDNSResourceRecord.h
 *
 * @brief A class representing a PTR DNS resource record.
 */
@interface OFPTRDNSResourceRecord: OFDNSResourceRecord
{
	OFString *_domainName;
}

/*!
 * @brief The domain name of the resource record.
 */
@property (readonly, nonatomic) OFString *domainName;

- (instancetype)initWithName: (OFString *)name
		 recordClass: (of_dns_resource_record_class_t)recordClass
		  recordType: (of_dns_resource_record_type_t)recordType
			 TTL: (uint32_t)TTL OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated OFPTRDNSResourceRecord with the
 *	  specified name, class, domain name and time to live.
 *
 * @param name The name for the resource record
 * @param recordClass The class code for the resource record
 * @param domainName The domain name for the resource record
 * @param TTL The time to live for the resource record
 * @return An initialized OFPTRDNSResourceRecord
 */
- (instancetype)initWithName: (OFString *)name
		 recordClass: (of_dns_resource_record_class_t)recordClass
		  domainName: (OFString *)domainName
			 TTL: (uint32_t)TTL OF_DESIGNATED_INITIALIZER;
@end

/*!
 * @class OFRPNSResourceRecord \
 *	  OFDNSResourceRecord.h ObjFW/OFDNSResourceRecord.h
 *
 * @brief A class representing an RP DNS resource record.
 */
@interface OFRPDNSResourceRecord: OFDNSResourceRecord
{
	OFString *_mailbox, *_TXTDomainName;
}

/*!
 * @brief The mailbox of the responsible person of the resource record.
 */
@property (readonly, nonatomic) OFString *mailbox;

/*!
 * @brief A domain name that contains a TXT resource record for the responsible
 *	  person of the resource record.
 */
@property (readonly, nonatomic) OFString *TXTDomainName;

- (instancetype)initWithName: (OFString *)name
		 recordClass: (of_dns_resource_record_class_t)recordClass
		  recordType: (of_dns_resource_record_type_t)recordType
			 TTL: (uint32_t)TTL OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated OFRPDNSResourceRecord with the
 *	  specified name, class, alias and time to live.
 *
 * @param name The name for the resource record
 * @param recordClass The class code for the resource record
 * @param mailbox The mailbox of the responsible person of the resource record
 * @param TXTDomainName A domain name that contains a TXT resource record for
 *			the responsible person of the resource record
 * @param TTL The time to live for the resource record
 * @return An initialized OFRPDNSResourceRecord
 */
- (instancetype)initWithName: (OFString *)name
		 recordClass: (of_dns_resource_record_class_t)recordClass
		     mailbox: (OFString *)mailbox
	       TXTDomainName: (OFString *)TXTDomainName
			 TTL: (uint32_t)TTL OF_DESIGNATED_INITIALIZER;
@end

/*!
 * @class OFSOADNSResourceRecord \
 *	  OFDNSResourceRecord.h ObjFW/OFDNSResourceRecord.h
 *
 * @brief A class representing an SOA DNS resource record.
 */
@interface OFSOADNSResourceRecord: OFDNSResourceRecord
{
	OFString *_primaryNameServer, *_responsiblePerson;
	uint32_t _serialNumber, _refreshInterval, _retryInterval;
	uint32_t _expirationInterval, _minTTL;
}

/*!
 * @brief The the primary name server for the zone.
 */
@property (readonly, nonatomic) OFString *primaryNameServer;

/*!
 * @brief The mailbox of the person responsible for the zone.
 */
@property (readonly, nonatomic) OFString *responsiblePerson;

/*!
 * @brief The serial number of the original copy of the zone.
 */
@property (readonly, nonatomic) uint32_t serialNumber;

/*!
 * @brief The refresh interval of the zone.
 */
@property (readonly, nonatomic) uint32_t refreshInterval;

/*!
 * @brief The retry interval of the zone.
 */
@property (readonly, nonatomic) uint32_t retryInterval;

/*!
 * @brief The expiration interval of the zone.
 */
@property (readonly, nonatomic) uint32_t expirationInterval;

/*!
 * @brief The minimum TTL of the zone.
 */
@property (readonly, nonatomic) uint32_t minTTL;

- (instancetype)initWithName: (OFString *)name
		 recordClass: (of_dns_resource_record_class_t)recordClass
		  recordType: (of_dns_resource_record_type_t)recordType
			 TTL: (uint32_t)TTL OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated OFSOADNSResourceRecord with the
 *	  specified name, class, text data and time to live.
 *
 * @param name The name for the resource record
 * @param recordClass The class code for the resource record
 * @param primaryNameServer The the primary name server for the zone
 * @param responsiblePerson The mailbox of the person responsible for the zone
 * @param serialNumber The serial number of the original copy of the zone
 * @param refreshInterval The refresh interval of the zone
 * @param retryInterval The retry interval of the zone
 * @param expirationInterval The expiration interval of the zone
 * @param minTTL The minimum TTL of the zone
 * @param TTL The time to live for the resource record
 * @return An initialized OFSOADNSResourceRecord
 */
- (instancetype)initWithName: (OFString *)name
		 recordClass: (of_dns_resource_record_class_t)recordClass
	   primaryNameServer: (OFString *)primaryNameServer
	   responsiblePerson: (OFString *)responsiblePerson
		serialNumber: (uint32_t)serialNumber
	     refreshInterval: (uint32_t)refreshInterval
	       retryInterval: (uint32_t)retryInterval
	  expirationInterval: (uint32_t)expirationInterval
		      minTTL: (uint32_t)minTTL
			 TTL: (uint32_t)TTL OF_DESIGNATED_INITIALIZER;
@end

/*!
 * @class OFSRVDNSResourceRecord \
 *	  OFDNSResourceRecord.h ObjFW/OFDNSResourceRecord.h
 *
 * @brief A class representing an SRV DNS resource record.
 */
@interface OFSRVDNSResourceRecord: OFDNSResourceRecord
{
	uint16_t _priority, _weight;
	OFString *_target;
	uint16_t _port;
}

/*!
 * @brief The priority of the resource record.
 */
@property (readonly, nonatomic) uint16_t priority;

/*!
 * @brief The weight of the resource record.
 */
@property (readonly, nonatomic) uint16_t weight;

/*!
 * @brief The target of the resource record.
 */
@property (readonly, nonatomic) OFString *target;

/*!
 * @brief The port on the target of the resource record.
 */
@property (readonly, nonatomic) uint16_t port;

- (instancetype)initWithName: (OFString *)name
		 recordClass: (of_dns_resource_record_class_t)recordClass
		  recordType: (of_dns_resource_record_type_t)recordType
			 TTL: (uint32_t)TTL OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated OFSRVDNSResourceRecord with the
 *	  specified name, class, preference, mail exchange and time to live.
 *
 * @param name The name for the resource record
 * @param priority The priority for the resource record
 * @param weight The weight for the resource record
 * @param target The target for the resource record
 * @param port The port on the target for the resource record
 * @param TTL The time to live for the resource record
 * @return An initialized OFSRVDNSResourceRecord
 */
- (instancetype)initWithName: (OFString *)name
		    priority: (uint16_t)priority
		      weight: (uint16_t)weight
		      target: (OFString *)target
			port: (uint16_t)port
			 TTL: (uint32_t)TTL OF_DESIGNATED_INITIALIZER;
@end

/*!
 * @class OFTXTDNSResourceRecord \
 *	  OFDNSResourceRecord.h ObjFW/OFDNSResourceRecord.h
 *
 * @brief A class representing a TXT DNS resource record.
 */
@interface OFTXTDNSResourceRecord: OFDNSResourceRecord
{
	OFData *_textData;
}

/*!
 * @brief The text of the resource record.
 */
@property (readonly, nonatomic) OFData *textData;

- (instancetype)initWithName: (OFString *)name
		 recordClass: (of_dns_resource_record_class_t)recordClass
		  recordType: (of_dns_resource_record_type_t)recordType
			 TTL: (uint32_t)TTL OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated OFTXTDNSResourceRecord with the
 *	  specified name, class, text data and time to live.
 *
 * @param name The name for the resource record
 * @param recordClass The class code for the resource record
 * @param textData The data for the resource record
 * @param TTL The time to live for the resource record
 * @return An initialized OFTXTDNSResourceRecord
 */
- (instancetype)initWithName: (OFString *)name
		 recordClass: (of_dns_resource_record_class_t)recordClass
		    textData: (OFData *)textData
			 TTL: (uint32_t)TTL OF_DESIGNATED_INITIALIZER;
@end

#ifdef __cplusplus
extern "C" {
#endif
extern OFString *_Nonnull of_dns_resource_record_class_to_string(
    of_dns_resource_record_class_t recordClass);
extern OFString *_Nonnull of_dns_resource_record_type_to_string(
    of_dns_resource_record_type_t recordType);
extern of_dns_resource_record_class_t of_dns_resource_record_class_parse(
    OFString *_Nonnull string);
extern of_dns_resource_record_type_t of_dns_resource_record_type_parse(
    OFString *_Nonnull string);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
