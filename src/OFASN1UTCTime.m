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

#import "OFASN1UTCTime.h"
#import "OFASN1Value+Private.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidFormatException.h"

@implementation OFASN1UTCTime
@synthesize yearOfCentury = _yearOfCentury, month = _month;
@synthesize dayOfMonth = _dayOfMonth, hour = _hour, minute = _minute;
@synthesize second = _second;

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

- (instancetype)initWithString: (OFString *)string
{
	return [self initWithString: string
			   tagClass: OFASN1TagClassUniversal
			  tagNumber: OFASN1TagNumberUTCTime];
}

- (instancetype)initWithString: (OFString *)string
		      tagClass: (OFASN1TagClass)tagClass
		     tagNumber: (OFASN1TagNumber)tagNumber
{
	void *pool = objc_autoreleasePoolPush();

	OFData *DEREncodedContents;
	@try {
		const char *cString =
		    [string insecureCStringWithEncoding: OFStringEncodingASCII];
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

- (instancetype)initWithDEREncodedContents: (OFData *)DEREncodedContents
{
	return [self initWithDEREncodedContents: DEREncodedContents
				       tagClass: OFASN1TagClassUniversal
				      tagNumber: OFASN1TagNumberUTCTime];
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
		if (count != 13)
			@throw [OFInvalidFormatException exception];

		const unsigned char *items = DEREncodedContents.items;

		for (size_t i = 0; i < 12; i++)
			if (!OFASCIIIsDigit(items[i]))
				@throw [OFInvalidFormatException exception];

		if (items[12] != 'Z')
			@throw [OFInvalidFormatException exception];

		_yearOfCentury = (items[0] - '0') * 10 + items[1] - '0';

		_month = (items[2] - '0') * 10 + items[3] - '0';
		if (_month == 0 || _month > 12)
			@throw [OFInvalidFormatException exception];

		_dayOfMonth = (items[4] - '0') * 10 + items[5] - '0';
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
			/*
			 * We cannot check the "not divisible by 100, except if
			 * divisible by 400" rule since we do not have the full
			 * year. So we just always accept everything divisble
			 * by 100.
			 */
			if (_yearOfCentury % 4 == 0) {
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

		_hour = (items[6] - '0') * 10 + items[7] - '0';
		if (_hour > 23)
			@throw [OFInvalidFormatException exception];

		_minute = (items[8] - '0') * 10 + items[9] - '0';
		if (_minute > 59)
			@throw [OFInvalidFormatException exception];

		_second = (items[8] - '0') * 10 + items[9] - '0';
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

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@ [%@ %@]: %02u-%02u-%02uT%02u:%02u:%02uZ>",
	    self.class, OFASN1TagClassDescription(_tagClass),
	    OFASN1TagNumberDescription(_tagClass, _tagNumber),
	    _yearOfCentury, _month, _dayOfMonth, _hour, _minute, _second];
}
@end
