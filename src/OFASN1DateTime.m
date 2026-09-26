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

#include "config.h"

#import "OFASN1DateTime.h"
#import "OFASN1Value+Private.h"
#import "OFData.h"
#import "OFDate.h"
#import "OFString.h"

#import "OFInvalidFormatException.h"

@implementation OFASN1DateTime
@synthesize year = _year, month = _month, dayOfMonth = _dayOfMonth;
@synthesize hour = _hour, minute = _minute, second = _second;

+ (instancetype)timeWithString: (OFString *)string
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithString: string]);
}

+ (instancetype)timeWithString: (OFString *)string
		      tagClass: (OFASN1TagClass)tagClass
		     tagNumber: (OFASN1TagNumber)tagNumber
{
	return objc_autoreleaseReturnValue([[self alloc]
	    initWithString: string
		  tagClass: tagClass
		 tagNumber: tagNumber]);
}

+ (instancetype)timeWithDate: (OFDate *)date
{
	return objc_autoreleaseReturnValue([[self alloc] initWithDate: date]);
}

+ (instancetype)timeWithDate: (OFDate *)date
		    tagClass: (OFASN1TagClass)tagClass
		   tagNumber: (OFASN1TagNumber)tagNumber
{
	return objc_autoreleaseReturnValue([[self alloc]
	    initWithDate: date
		tagClass: tagClass
	       tagNumber: tagNumber]);
}

- (instancetype)initWithString: (OFString *)string
{
	return [self initWithString: string
			   tagClass: OFASN1TagClassUniversal
			  tagNumber: OFASN1TagNumberDateTime];
}

- (instancetype)initWithString: (OFString *)string
		      tagClass: (OFASN1TagClass)tagClass
		     tagNumber: (OFASN1TagNumber)tagNumber
{
	void *pool = objc_autoreleasePoolPush();

	OFData *DEREncodedContents;
	@try {
		const char *cString =
		    [string cStringWithEncoding: OFStringEncodingASCII];
		size_t cStringLength =
		    [string cStringLengthWithEncoding: OFStringEncodingASCII];
		DEREncodedContents = [OFData dataWithItems: cString
						     count: cStringLength];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	self = [self initWithDEREncodedContents: DEREncodedContents
				       tagClass: tagClass
				      tagNumber: tagNumber];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (instancetype)initWithDate: (OFDate *)date
{
	return [self initWithDate: date
			 tagClass: OFASN1TagClassUniversal
			tagNumber: OFASN1TagNumberDateTime];
}

- (instancetype)initWithDate: (OFDate *)date
		    tagClass: (OFASN1TagClass)tagClass
		   tagNumber: (OFASN1TagNumber)tagNumber
{
	void *pool = objc_autoreleasePoolPush();

	OFString *string;
	@try {
		if (date.microsecond > 0)
			@throw [OFInvalidFormatException exception];

		string = [date dateStringWithFormat: @"%Y-%m-%dT%H:%M:%S"];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	self = [self initWithString: string
			   tagClass: tagClass
			  tagNumber: tagNumber];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (instancetype)initWithDEREncodedContents: (OFData *)DEREncodedContents
{
	return [self initWithDEREncodedContents: DEREncodedContents
				       tagClass: OFASN1TagClassUniversal
				      tagNumber: OFASN1TagNumberDateTime];
}

- (instancetype)initWithDEREncodedContents: (OFData *)DEREncodedContents
				  tagClass: (OFASN1TagClass)tagClass
				 tagNumber: (OFASN1TagNumber)tagNumber
{
	self = [super initWithDEREncodedContents: DEREncodedContents
					tagClass: tagClass
				       tagNumber: tagNumber];

	@try {
		size_t count = DEREncodedContents.count;
		if (count != 19)
			@throw [OFInvalidFormatException exception];

		const unsigned char *items = DEREncodedContents.items;

		if (!OFASCIIIsDigit(items[0]) || !OFASCIIIsDigit(items[1]) ||
		    !OFASCIIIsDigit(items[2]) || !OFASCIIIsDigit(items[3]))
			@throw [OFInvalidFormatException exception];

		_year = (items[0] - '0') * 1000 + (items[1] - '0') * 100 +
		    (items[2] - '0') * 10 + items[3] - '0';

		if (items[4] != '-' || !OFASCIIIsDigit(items[5]) ||
		    !OFASCIIIsDigit(items[6]))
			@throw [OFInvalidFormatException exception];

		_month = (items[5] - '0') * 10 + items[6] - '0';
		if (_month == 0 || _month > 12)
			@throw [OFInvalidFormatException exception];

		if (items[7] != '-' || !OFASCIIIsDigit(items[8]) ||
		    !OFASCIIIsDigit(items[9]))
			@throw [OFInvalidFormatException exception];

		_dayOfMonth = (items[8] - '0') * 10 + items[9] - '0';
		if (_dayOfMonth == 0)
			@throw [OFInvalidFormatException exception];

		switch (_month) {
		case 1:
		case 3:
		case 5:
		case 7:
		case 8:
		case 10:
		case 12:
			if (_dayOfMonth > 31)
				@throw [OFInvalidFormatException exception];
			break;
		case 4:
		case 6:
		case 9:
		case 11:
			if (_dayOfMonth > 30)
				@throw [OFInvalidFormatException exception];
			break;
		case 2:
			if (_year % 4 == 0 &&
			    (_year % 100 != 0 || _year % 400 == 0)) {
				if (_dayOfMonth > 29)
					@throw [OFInvalidFormatException
					    exception];
			} else {
				if (_dayOfMonth > 28)
					@throw [OFInvalidFormatException
					    exception];
			}
			break;
		}

		if (items[10] != 'T' || !OFASCIIIsDigit(items[11]) ||
		    !OFASCIIIsDigit(items[12]))
			@throw [OFInvalidFormatException exception];

		_hour = (items[11] - '0') * 10 + items[12] - '0';
		if (_hour > 23)
			@throw [OFInvalidFormatException exception];

		if (items[13] != ':' || !OFASCIIIsDigit(items[14]) ||
		    !OFASCIIIsDigit(items[15]))
			@throw [OFInvalidFormatException exception];

		_minute = (items[14] - '0') * 10 + items[15] - '0';
		if (_minute > 59)
			@throw [OFInvalidFormatException exception];

		if (items[16] != ':' || !OFASCIIIsDigit(items[17]) ||
		    !OFASCIIIsDigit(items[18]))
			@throw [OFInvalidFormatException exception];

		_second = (items[17] - '0') * 10 + items[18] - '0';
		if (_second > 59)
			@throw [OFInvalidFormatException exception];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (OFString *)stringValue
{
	return [OFString stringWithCString: _DEREncodedContents.items
				  encoding: OFStringEncodingASCII
				    length: _DEREncodedContents.count];
}

- (OFDate *)dateValue
{
	struct tm tm = {
		.tm_year = _year - 1900,
		.tm_mon = _month - 1,
		.tm_mday = _dayOfMonth,
		.tm_hour = _hour,
		.tm_min = _minute,
		.tm_sec = _second
	};

	return [OFDate dateWithStructTm: &tm];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@ [%@ %@]: %04u-%02u-%02uT%02u:%02u:%02uZ>",
	    self.class, OFASN1TagClassDescription(_tagClass),
	    OFASN1TagNumberDescription(_tagClass, _tagNumber),
	    _year, _month, _dayOfMonth, _hour, _minute, _second];
}
@end
