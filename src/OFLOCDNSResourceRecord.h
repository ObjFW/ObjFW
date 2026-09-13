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
 * @class OFLOCDNSResourceRecord OFLOCDNSResourceRecord.h ObjFW/ObjFW.h
 *
 * @brief A class representing an LOC DNS resource record.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFLOCDNSResourceRecord: OFDNSResourceRecord
{
	uint8_t _size, _horizontalPrecision, _verticalPrecision;
	uint32_t _latitude, _longitude, _altitude;
}

/**
 * @brief The diameter in centimeters of a sphere enclosing the position,
 *	  encoded as per RFC 1876.
 */
@property (readonly, nonatomic) uint8_t size;

/**
 * @brief The horizontal precision in centimeters, encoded as per RFC 1876.
 */
@property (readonly, nonatomic) uint8_t horizontalPrecision;

/**
 * @brief The vertical precision in centimeters, encoded as per RFC 1876.
 */
@property (readonly, nonatomic) uint8_t verticalPrecision;

/**
 * @brief The latitude in thousands of a second of an arc.
 */
@property (readonly, nonatomic) uint32_t latitude;

/**
 * @brief The longitude in thousands of a second of an arc.
 */
@property (readonly, nonatomic) uint32_t longitude;

/**
 * @brief The altitude in centimeters from a base of 100000 meters below the
 *	  GPS reference.
 */
@property (readonly, nonatomic) uint32_t altitude;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  recordType: (OFDNSRecordType)recordType
			 TTL: (uint32_t)TTL OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFLOCDNSResourceRecord with the
 *	  specified name, class, domain name and time to live.
 *
 * @param name The name for the resource record
 * @param DNSClass The class code for the resource record
 * @param size The diameter in centimeters of a sphere enclosing the position,
 *	       encoded as per RFC 1876
 * @param horizontalPrecision The horizontal precision in centimeters, encoded
 *			      as per RFC 1876
 * @param verticalPrecision The vertical precision in centimeters, encoded as
 *			    per RFC 1876
 * @param latitude The latitude in thousands of a second of an arc
 * @param longitude The longitude in thousands of a second of an arc
 * @param altitude The altitude in centimeters from a base of 100000 meters
 *		   below the GPS reference
 * @param TTL The time to live for the resource record
 * @return An initialized OFLOCDNSResourceRecord
 */
- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
			size: (uint8_t)size
	 horizontalPrecision: (uint8_t)horizontalPrecision
	   verticalPrecision: (uint8_t)verticalPrecision
		    latitude: (uint32_t)latitude
		   longitude: (uint32_t)longitude
		    altitude: (uint32_t)altitude
			 TTL: (uint32_t)TTL OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
