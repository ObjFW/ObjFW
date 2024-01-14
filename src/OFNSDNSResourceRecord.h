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
 * @class OFNSDNSResourceRecord \
 *	  OFDNSResourceRecord.h ObjFW/OFDNSResourceRecord.h
 *
 * @brief A class representing an NS DNS resource record.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFNSDNSResourceRecord: OFDNSResourceRecord
{
	OFString *_authoritativeHost;
}

/**
 * @brief The authoritative host of the resource record.
 */
@property (readonly, nonatomic) OFString *authoritativeHost;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  recordType: (OFDNSRecordType)recordType
			 TTL: (uint32_t)TTL OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFNSDNSResourceRecord with the
 *	  specified name, class, authoritative host and time to live.
 *
 * @param name The name for the resource record
 * @param DNSClass The class code for the resource record
 * @param authoritativeHost The authoritative host for the resource record
 * @param TTL The time to live for the resource record
 * @return An initialized OFNSDNSResourceRecord
 */
- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
	   authoritativeHost: (OFString *)authoritativeHost
			 TTL: (uint32_t)TTL OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
