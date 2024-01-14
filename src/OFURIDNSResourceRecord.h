/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFDNSResourceRecord.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFURIDNSResourceRecord \
 *	  OFDNSResourceRecord.h ObjFW/OFDNSResourceRecord.h
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
