/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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
 * @class OFSRVDNSResourceRecord OFSRVDNSResourceRecord.h ObjFW/ObjFW.h
 *
 * @brief A class representing an SRV DNS resource record.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFSRVDNSResourceRecord: OFDNSResourceRecord
{
	uint16_t _priority, _weight;
	OFString *_target;
	uint16_t _port;
}

/**
 * @brief The priority of the resource record.
 */
@property (readonly, nonatomic) uint16_t priority;

/**
 * @brief The weight of the resource record.
 */
@property (readonly, nonatomic) uint16_t weight;

/**
 * @brief The target of the resource record.
 */
@property (readonly, nonatomic) OFString *target;

/**
 * @brief The port on the target of the resource record.
 */
@property (readonly, nonatomic) uint16_t port;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  recordType: (OFDNSRecordType)recordType
			 TTL: (uint32_t)TTL OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFSRVDNSResourceRecord with the
 *	  specified name, priority, weight, target, port and time to live.
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

OF_ASSUME_NONNULL_END
