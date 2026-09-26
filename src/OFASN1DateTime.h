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

@class OFDate;

/**
 * @brief An ASN.1 DATE-TIME.
 */
OF_SUBCLASSING_RESTRICTED

@interface OFASN1DateTime: OFPrimitiveASN1Value
{
	unsigned short _year;
	unsigned char _month, _dayOfMonth, _hour, _minute, _second;
}

/**
 * @brief The string value of the DATE-TIME.
 */
@property (readonly, retain, nonatomic) OFString *stringValue;

/**
 * @brief The date value of the DATE-TIME.
 */
@property (readonly, retain, nonatomic) OFDate *dateValue;

/**
 * @brief The year of the DATE-TIME.
 */
@property (readonly, nonatomic) unsigned short year;

/**
 * @brief The month of the DATE-TIME.
 */
@property (readonly, nonatomic) unsigned char month;

/**
 * @brief The day of the month of the DATE-TIME.
 */
@property (readonly, nonatomic) unsigned char dayOfMonth;

/**
 * @brief The hour of the DATE-TIME.
 */
@property (readonly, nonatomic) unsigned char hour;

/**
 * @brief The minute of the DATE-TIME.
 */
@property (readonly, nonatomic) unsigned char minute;

/**
 * @brief The second of the DATE-TIME.
 */
@property (readonly, nonatomic) unsigned char second;

/**
 * @brief Creates an ASN.1 DATE-TIME with the specified string value.
 *
 * @param string The string value of the DATE-TIME
 * @return A new, autoreleased OFASN1DateTime
 */
+ (instancetype)timeWithString: (OFString *)string;

/**
 * @brief Creates an ASN.1 DATE-TIME with the specified string value.
 *
 * @param string The string value of the DATE-TIME
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return A new, autoreleased OFASN1DateTime
 */
+ (instancetype)timeWithString: (OFString *)string
		      tagClass: (OFASN1TagClass)tagClass
		     tagNumber: (OFASN1TagNumber)tagNumber;

/**
 * @brief Creates an ASN.1 DATE-TIME with the specified date value.
 *
 * @param date The date value of the DATE-TIME
 * @return A new, autoreleased OFASN1DateTime
 */
+ (instancetype)timeWithDate: (OFDate *)date;

/**
 * @brief Creates an ASN.1 DATE-TIME with the specified date value.
 *
 * @param date The date value of the DATE-TIME
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return A new, autoreleased OFASN1DateTime
 */
+ (instancetype)timeWithDate: (OFDate *)date
		    tagClass: (OFASN1TagClass)tagClass
		   tagNumber: (OFASN1TagNumber)tagNumber;

/**
 * @brief Initializes an already allocated ASN.1 DATE-TIME with the specified
 *	  string value.
 *
 * @param string The string value of the DATE-TIME
 * @return An initialized OFASN1DateTime
 */
- (instancetype)initWithString: (OFString *)string;

/**
 * @brief Initializes an already allocated ASN.1 DATE-TIME with the specified
 *	  string value.
 *
 * @param string The string value of the DATE-TIME
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return An initialized OFASN1DateTime
 */
- (instancetype)initWithString: (OFString *)string
		      tagClass: (OFASN1TagClass)tagClass
		     tagNumber: (OFASN1TagNumber)tagNumber;

/**
 * @brief Initializes an already allocated ASN.1 DATE-TIME with the specified
 *	  date value.
 *
 * @param date The date value of the DATE-TIME
 * @return An initialized OFASN1DateTime
 */
- (instancetype)initWithDate: (OFDate *)date;

/**
 * @brief Initializes an already allocated ASN.1 DATE-TIME with the specified
 *	  date value.
 *
 * @param date The date value of the DATE-TIME
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return An initialized OFASN1DateTime
 */
- (instancetype)initWithDate: (OFDate *)date
		    tagClass: (OFASN1TagClass)tagClass
		   tagNumber: (OFASN1TagNumber)tagNumber;
@end

OF_ASSUME_NONNULL_END
