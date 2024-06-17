/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
 * @class OFRPDNSResourceRecord OFRPDNSResourceRecord.h ObjFW/ObjFW.h
 *
 * @brief A class representing an RP DNS resource record.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFRPDNSResourceRecord: OFDNSResourceRecord
{
	OFString *_mailbox, *_TXTDomainName;
}

/**
 * @brief The mailbox of the responsible person of the resource record.
 */
@property (readonly, nonatomic) OFString *mailbox;

/**
 * @brief A domain name that contains a TXT resource record for the responsible
 *	  person of the resource record.
 */
@property (readonly, nonatomic) OFString *TXTDomainName;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  recordType: (OFDNSRecordType)recordType
			 TTL: (uint32_t)TTL OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFRPDNSResourceRecord with the
 *	  specified name, class, alias and time to live.
 *
 * @param name The name for the resource record
 * @param DNSClass The class code for the resource record
 * @param mailbox The mailbox of the responsible person of the resource record
 * @param TXTDomainName A domain name that contains a TXT resource record for
 *			the responsible person of the resource record
 * @param TTL The time to live for the resource record
 * @return An initialized OFRPDNSResourceRecord
 */
- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		     mailbox: (OFString *)mailbox
	       TXTDomainName: (OFString *)TXTDomainName
			 TTL: (uint32_t)TTL OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
