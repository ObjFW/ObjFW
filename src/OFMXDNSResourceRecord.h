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
 * @class OFMXDNSResourceRecord \
 *	  OFDNSResourceRecord.h ObjFW/OFDNSResourceRecord.h
 *
 * @brief A class representing an MX DNS resource record.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFMXDNSResourceRecord: OFDNSResourceRecord
{
	uint16_t _preference;
	OFString *_mailExchange;
}

/**
 * @brief The preference of the resource record.
 */
@property (readonly, nonatomic) uint16_t preference;

/**
 * @brief The mail exchange of the resource record.
 */
@property (readonly, nonatomic) OFString *mailExchange;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  recordType: (OFDNSRecordType)recordType
			 TTL: (uint32_t)TTL OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFMXDNSResourceRecord with the
 *	  specified name, class, preference, mail exchange and time to live.
 *
 * @param name The name for the resource record
 * @param DNSClass The class code for the resource record
 * @param preference The preference for the resource record
 * @param mailExchange The mail exchange for the resource record
 * @param TTL The time to live for the resource record
 * @return An initialized OFMXDNSResourceRecord
 */
- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  preference: (uint16_t)preference
		mailExchange: (OFString *)mailExchange
			 TTL: (uint32_t)TTL OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
