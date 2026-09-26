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

#import "OFASN1GeneralizedTime.h"
#import "OFASN1Value+Private.h"
#import "OFData.h"
#import "OFDate.h"
#import "OFString.h"

#import "OFInvalidFormatException.h"

@implementation OFASN1GeneralizedTime
@synthesize year = _year, month = _month, dayOfMonth = _dayOfMonth;
@synthesize hour = _hour, minute = _minute, second = _second;
@synthesize millisecond = _millisecond;

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
			  tagNumber: OFASN1TagNumberGeneralizedTime];
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
			tagNumber: OFASN1TagNumberGeneralizedTime];
}

- (instancetype)initWithDate: (OFDate *)date
		    tagClass: (OFASN1TagClass)tagClass
		   tagNumber: (OFASN1TagNumber)tagNumber
{
	void *pool = objc_autoreleasePoolPush();

	OFString *string;
	@try {
		string = [date dateStringWithFormat: @"%Y%m%d%H%M%S"];

		if (date.microsecond / 1000 > 0)
			string = [string stringByAppendingFormat:
			    @".%06u", date.microsecond / 1000];

		string = [string stringByAppendingString: @"Z"];
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
	return [self
	    initWithDEREncodedContents: DEREncodedContents
			      tagClass: OFASN1TagClassUniversal
			     tagNumber: OFASN1TagNumberGeneralizedTime];
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
		if (count != 15 && count != 19)
			@throw [OFInvalidFormatException exception];

		const unsigned char *items = DEREncodedContents.items;

		for (size_t i = 0; i < 14; i++)
			if (!OFASCIIIsDigit(items[i]))
				@throw [OFInvalidFormatException exception];

		if (count == 19) {
			if (items[14] != '.')
				@throw [OFInvalidFormatException exception];

			for (size_t i = 15; i < 18; i++)
				if (!OFASCIIIsDigit(items[i]))
					@throw [OFInvalidFormatException
					    exception];

			if (items[18] != 'Z')
				@throw [OFInvalidFormatException exception];
		} else if (items[14] != 'Z')
			@throw [OFInvalidFormatException exception];

		_year = (items[0] - '0') * 1000 + (items[1] - '0') * 100 +
		    (items[2] - '0') * 10 + items[3] - '0';

		_month = (items[4] - '0') * 10 + items[5] - '0';
		if (_month == 0 || _month > 12)
			@throw [OFInvalidFormatException exception];

		_dayOfMonth = (items[6] - '0') * 10 + items[7] - '0';
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

		_hour = (items[8] - '0') * 10 + items[9] - '0';
		if (_hour > 23)
			@throw [OFInvalidFormatException exception];

		_minute = (items[10] - '0') * 10 + items[11] - '0';
		if (_minute > 59)
			@throw [OFInvalidFormatException exception];

		_second = (items[12] - '0') * 10 + items[13] - '0';
		if (_second > 59)
			@throw [OFInvalidFormatException exception];

		if (count == 19) {
			_millisecond = (items[15] - '0') * 100 +
			    (items[16] - '0') * 10 + items[17] - '0';

			if (_millisecond == 0)
				@throw [OFInvalidFormatException exception];
		}
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
	void *pool = objc_autoreleasePoolPush();
	struct tm tm = {
		.tm_year = _year - 1900,
		.tm_mon = _month - 1,
		.tm_mday = _dayOfMonth,
		.tm_hour = _hour,
		.tm_min = _minute,
		.tm_sec = _second
	};
	OFDate *date = [OFDate dateWithStructTm: &tm];

	if (_millisecond > 0)
		date = [date dateByAddingTimeInterval: _millisecond / 1000.0];

	objc_retain(date);

	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(date);
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@ [%@ %@]: %04u-%02u-%02uT%02u:%02u:%02u.%03uZ>",
	    self.class, OFASN1TagClassDescription(_tagClass),
	    OFASN1TagNumberDescription(_tagClass, _tagNumber),
	    _year, _month, _dayOfMonth, _hour, _minute, _second, _millisecond];
}
@end
