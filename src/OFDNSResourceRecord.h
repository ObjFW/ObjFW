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

#import "OFObject.h"
#import "OFSocket.h"
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

@class OFArray OF_GENERIC(ObjectType);
@class OFData;

/**
 * @brief The DNS class.
 */
typedef enum {
	/** IN */
	OFDNSClassIN  =   1,
	/** Any class. Only for queries. */
	OFDNSClassAny = 255,
} OFDNSClass;

/**
 * @brief The type of a DNS resource record.
 */
typedef enum {
	/** A */
	OFDNSRecordTypeA     =   1,
	/** NS */
	OFDNSRecordTypeNS    =   2,
	/** CNAME */
	OFDNSRecordTypeCNAME =   5,
	/** SOA */
	OFDNSRecordTypeSOA   =   6,
	/** PTR */
	OFDNSRecordTypePTR   =  12,
	/** HINFO */
	OFDNSRecordTypeHINFO =  13,
	/** MX */
	OFDNSRecordTypeMX    =  15,
	/** TXT */
	OFDNSRecordTypeTXT   =  16,
	/** RP */
	OFDNSRecordTypeRP    =  17,
	/** AAAA */
	OFDNSRecordTypeAAAA  =  28,
	/** LOC */
	OFDNSRecordTypeLOC   =  29,
	/** SRV */
	OFDNSRecordTypeSRV   =  33,
	/** All types. Only for queries. */
	OFDNSRecordTypeAll   = 255,
	/** URI */
	OFDNSRecordTypeURI   = 256,
} OFDNSRecordType;

/**
 * @class OFDNSResourceRecord OFDNSResourceRecord.h ObjFW/ObjFW.h
 *
 * @brief A class representing a DNS resource record.
 */
@interface OFDNSResourceRecord: OFObject <OFCopying>
{
	OFString *_name;
	OFDNSClass _DNSClass;
	OFDNSRecordType _recordType;
	uint32_t _TTL;
	OF_RESERVE_IVARS(OFDNSResourceRecord, 4)
}

/**
 * @brief The domain name to which the resource record belongs.
 */
@property (readonly, nonatomic) OFString *name;

/**
 * @brief The DNS class.
 */
@property (readonly, nonatomic) OFDNSClass DNSClass;

/**
 * @brief The resource record type code.
 */
@property (readonly, nonatomic) OFDNSRecordType recordType;

/**
 * @brief The number of seconds after which the resource record should be
 *	  discarded from the cache.
 */
@property (readonly, nonatomic) uint32_t TTL;

/**
 * @brief Initializes an already allocated OFDNSResourceRecord with the
 *	  specified name, class, type, data and time to live.
 *
 * @param name The name for the resource record
 * @param DNSClass The class code for the resource record
 * @param recordType The type code for the resource record
 * @param TTL The time to live for the resource record
 * @return An initialized OFDNSResourceRecord
 */
- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  recordType: (OFDNSRecordType)recordType
			 TTL: (uint32_t)TTL OF_DESIGNATED_INITIALIZER;
@end

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief Returns the name for the specified OFDNSClass.
 *
 * @param DNSClass The OFDNSClass to return the name for
 * @return The name for the specified OFDNSClass
 */
extern OFString *_Nonnull OFDNSClassName(OFDNSClass DNSClass);

/**
 * @brief Returns the name for the specified OFDNSRecordType.
 *
 * @param recordType The OFDNSRecordType to return the name for
 * @return The name for the specified OFDNSRecordType
 */
extern OFString *_Nonnull OFDNSRecordTypeName(OFDNSRecordType recordType);

/**
 * @brief Parses the specified string as an @ref OFDNSClass.
 *
 * @param string The string to parse as an @ref OFDNSClass
 * @return The parsed OFDNSClass
 * @throw OFInvalidFormatException The specified string is not valid DNS class
 */
extern OFDNSClass OFDNSClassParseName(OFString *_Nonnull string);

/**
 * @brief Parses the specified string as an @ref OFDNSRecordType.
 *
 * @param string The string to parse as an @ref OFDNSRecordType
 * @return The parsed OFDNSRecordType
 * @throw OFInvalidFormatException The specified string is not valid DNS class
 */
extern OFDNSRecordType OFDNSRecordTypeParseName(OFString *_Nonnull string);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END

#import "OFAAAADNSResourceRecord.h"
#import "OFADNSResourceRecord.h"
#import "OFCNAMEDNSResourceRecord.h"
#import "OFHINFODNSResourceRecord.h"
#import "OFLOCDNSResourceRecord.h"
#import "OFMXDNSResourceRecord.h"
#import "OFNSDNSResourceRecord.h"
#import "OFPTRDNSResourceRecord.h"
#import "OFRPDNSResourceRecord.h"
#import "OFSOADNSResourceRecord.h"
#import "OFSRVDNSResourceRecord.h"
#import "OFTXTDNSResourceRecord.h"
#import "OFURIDNSResourceRecord.h"
