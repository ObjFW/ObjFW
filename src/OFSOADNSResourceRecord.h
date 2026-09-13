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

#import "OFDNSResourceRecord.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFSOADNSResourceRecord OFSOADNSResourceRecord.h ObjFW/ObjFW.h
 *
 * @brief A class representing an SOA DNS resource record.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFSOADNSResourceRecord: OFDNSResourceRecord
{
	OFString *_primaryNameServer, *_responsiblePerson;
	uint32_t _serialNumber, _refreshInterval, _retryInterval;
	uint32_t _expirationInterval, _minTTL;
}

/**
 * @brief The the primary name server for the zone.
 */
@property (readonly, nonatomic) OFString *primaryNameServer;

/**
 * @brief The mailbox of the person responsible for the zone.
 */
@property (readonly, nonatomic) OFString *responsiblePerson;

/**
 * @brief The serial number of the original copy of the zone.
 */
@property (readonly, nonatomic) uint32_t serialNumber;

/**
 * @brief The refresh interval of the zone.
 */
@property (readonly, nonatomic) uint32_t refreshInterval;

/**
 * @brief The retry interval of the zone.
 */
@property (readonly, nonatomic) uint32_t retryInterval;

/**
 * @brief The expiration interval of the zone.
 */
@property (readonly, nonatomic) uint32_t expirationInterval;

/**
 * @brief The minimum TTL of the zone.
 */
@property (readonly, nonatomic) uint32_t minTTL;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  recordType: (OFDNSRecordType)recordType
			 TTL: (uint32_t)TTL OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFSOADNSResourceRecord with the
 *	  specified name, class, text data and time to live.
 *
 * @param name The name for the resource record
 * @param DNSClass The class code for the resource record
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
		    DNSClass: (OFDNSClass)DNSClass
	   primaryNameServer: (OFString *)primaryNameServer
	   responsiblePerson: (OFString *)responsiblePerson
		serialNumber: (uint32_t)serialNumber
	     refreshInterval: (uint32_t)refreshInterval
	       retryInterval: (uint32_t)retryInterval
	  expirationInterval: (uint32_t)expirationInterval
		      minTTL: (uint32_t)minTTL
			 TTL: (uint32_t)TTL OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
