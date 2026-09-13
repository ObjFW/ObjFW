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
 * @class OFURIDNSResourceRecord OFURIDNSResourceRecord.h ObjFW/ObjFW.h
 *
 * @brief A class representing an URI DNS resource record.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFURIDNSResourceRecord: OFDNSResourceRecord
{
	uint16_t _priority, _weight;
	OFString *_target;
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

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  recordType: (OFDNSRecordType)recordType
			 TTL: (uint32_t)TTL OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFURIDNSResourceRecord with the
 *	  specified name, class, priority, weight, target and time to live.
 *
 * @param name The name for the resource record
 * @param DNSClass The class code for the resource record
 * @param priority The priority for the resource record
 * @param weight The weight for the resource record
 * @param target The target for the resource record
 * @param TTL The time to live for the resource record
 * @return An initialized OFURIDNSResourceRecord
 */
- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		    priority: (uint16_t)priority
		      weight: (uint16_t)weight
		      target: (OFString *)target
			 TTL: (uint32_t)TTL OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
