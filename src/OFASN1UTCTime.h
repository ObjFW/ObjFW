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

#import "OFPrimitiveASN1Value.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @brief An ASN.1 UTCTime.
 */
OF_SUBCLASSING_RESTRICTED

@interface OFASN1UTCTime: OFPrimitiveASN1Value
{
	unsigned char _yearOfCentury, _month, _dayOfMonth, _hour, _minute;
	unsigned char _second;
}

/**
 * @brief The string value of the UTCTime.
 */
@property (readonly, retain, nonatomic) OFString *stringValue;

/**
 * @brief The two-digit year of the UTCTime.
 */
@property (readonly, nonatomic) unsigned char yearOfCentury;

/**
 * @brief The month of the UTCTime.
 */
@property (readonly, nonatomic) unsigned char month;

/**
 * @brief The day of the month of the UTCTime.
 */
@property (readonly, nonatomic) unsigned char dayOfMonth;

/**
 * @brief The hour of the UTCTime.
 */
@property (readonly, nonatomic) unsigned char hour;

/**
 * @brief The minute of the UTCTime.
 */
@property (readonly, nonatomic) unsigned char minute;

/**
 * @brief The second of the UTCTime.
 */
@property (readonly, nonatomic) unsigned char second;

/**
 * @brief Creates an ASN.1 Integer with the specified string.
 *
 * @param string The string value of the UTCTime
 * @return A new, autoreleased OFASN1UTCTime
 */
+ (instancetype)timeWithString: (OFString *)string;

/**
 * @brief Creates an ASN.1 UTCTime with the specified string.
 *
 * @param string The string value of the UTCTime
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return A new, autoreleased OFASN1UTCTime
 */
+ (instancetype)timeWithString: (OFString *)string
		      tagClass: (OFASN1TagClass)tagClass
		     tagNumber: (OFASN1TagNumber)tagNumber;

/**
 * @brief Initializes an already allocated ASN.1 UTCTime with the specified
 *	  string.
 *
 * @param string The string value of the UTCTime
 * @return An initialized OFASN1UTCTime
 */
- (instancetype)initWithString: (OFString *)string;

/**
 * @brief Initializes an already allocated ASN.1 UTCTime with the specified
 *	  string value.
 *
 * @param string The string value of the UTCTime
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return An initialized OFASN1UTCTime
 */
- (instancetype)initWithString: (OFString *)string
		      tagClass: (OFASN1TagClass)tagClass
		     tagNumber: (OFASN1TagNumber)tagNumber;
@end

OF_ASSUME_NONNULL_END
