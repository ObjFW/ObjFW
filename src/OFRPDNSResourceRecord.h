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
 * @class OFRPDNSResourceRecord \
 *	  OFDNSResourceRecord.h ObjFW/OFDNSResourceRecord.h
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
