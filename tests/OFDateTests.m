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

#include "config.h"

#include <time.h>

#import "ObjFW.h"
#import "ObjFWTest.h"

#import "OFStrPTime.h"

@interface OFDateTests: OTTestCase
{
	OFDate *_date[2];
}
@end

@implementation OFDateTests
- (void)setUp
{
	[super setUp];

	_date[0] = [[OFDate alloc] initWithTimeIntervalSince1970: 0];
	_date[1] = [[OFDate alloc]
	    initWithTimeIntervalSince1970: 3600 * 25 + 5.000002];
}

- (void)dealloc
{
	[_date[0] release];
	[_date[1] release];

	[super dealloc];
}

- (void)testStrPTime
{
	struct tm tm;
	int16_t timeZone;
	const char *dateString = "Wed, 09 Jun 2021 +0200x";

	OTAssertEqual(OFStrPTime(dateString, "%a, %d %b %Y %z", &tm, &timeZone),
	    dateString + 22);
	OTAssertEqual(tm.tm_wday, 3);
	OTAssertEqual(tm.tm_mday, 9);
	OTAssertEqual(tm.tm_mon, 5);
	OTAssertEqual(tm.tm_year, 2021 - 1900);
	OTAssertEqual(timeZone, 2 * 60);
}

- (void)testDateByAddingTimeInterval
{
	OTAssertEqualObjects(
	    [_date[0] dateByAddingTimeInterval: 3600 * 25 + 5.000002],
	    _date[1]);
}

- (void)testDescription
{
	OTAssertEqualObjects(_date[0].description, @"1970-01-01T00:00:00Z");
	OTAssertEqualObjects(_date[1].description, @"1970-01-02T01:00:05Z");
}

- (void)testDateWithDateStringFormat
{
	OTAssertEqualObjects(
	    [[OFDate dateWithDateString: @"2000-06-20T12:34:56+0200"
				 format: @"%Y-%m-%dT%H:%M:%S%z"] description],
	    @"2000-06-20T10:34:56Z");
}

- (void)testDateWithDateStringFormatFailsWithTrailingCharacters
{
	OTAssertThrowsSpecific(
	    [OFDate dateWithDateString: @"2000-06-20T12:34:56+0200x"
				format: @"%Y-%m-%dT%H:%M:%S%z"],
	    OFInvalidFormatException);
}

- (void)testDateWithLocalDateStringFormatFormat
{
	OTAssertEqualObjects(
	    [[OFDate dateWithLocalDateString: @"2000-06-20T12:34:56"
				      format: @"%Y-%m-%dT%H:%M:%S"]
	    localDateStringWithFormat: @"%Y-%m-%dT%H:%M:%S"],
	    @"2000-06-20T12:34:56");

	OTAssertEqualObjects(
	    [[OFDate dateWithLocalDateString: @"2000-06-20T12:34:56-0200"
				      format: @"%Y-%m-%dT%H:%M:%S%z"]
	    description],
	    @"2000-06-20T14:34:56Z");
}

- (void)testDateWithLocalDateStringFormatFailsWithTrailingCharacters
{
	OTAssertThrowsSpecific(
	    [OFDate dateWithLocalDateString: @"2000-06-20T12:34:56x"
				     format: @"%Y-%m-%dT%H:%M:%S"],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [OFDate dateWithLocalDateString: @"2000-06-20T12:34:56+0200x"
				     format: @"%Y-%m-%dT%H:%M:%S%z"],
	    OFInvalidFormatException);
}

- (void)testIsEqual
{
	OTAssertEqualObjects(_date[0],
	    [OFDate dateWithTimeIntervalSince1970: 0]);

	OTAssertNotEqualObjects(_date[0],
	    [OFDate dateWithTimeIntervalSince1970: 0.0000001]);
}

- (void)testCompare
{
	OTAssertEqual([_date[0] compare: _date[1]], OFOrderedAscending);
}

- (void)testSecond
{
	OTAssertEqual(_date[0].second, 0);
	OTAssertEqual(_date[1].second, 5);
}

- (void)testMicrosecond
{
	OTAssertEqual(_date[0].microsecond, 0);
	OTAssertEqual(_date[1].microsecond, 2);
}

- (void)testMinute
{
	OTAssertEqual(_date[0].minute, 0);
	OTAssertEqual(_date[1].minute, 0);
}

- (void)testHour
{
	OTAssertEqual(_date[0].hour, 0);
	OTAssertEqual(_date[1].hour, 1);
}

- (void)testDayOfMonth
{
	OTAssertEqual(_date[0].dayOfMonth, 1);
	OTAssertEqual(_date[1].dayOfMonth, 2);
}

- (void)testMonthOfYear
{
	OTAssertEqual(_date[0].monthOfYear, 1);
	OTAssertEqual(_date[1].monthOfYear, 1);
}

- (void)testYear
{
	OTAssertEqual(_date[0].year, 1970);
	OTAssertEqual(_date[1].year, 1970);
}

- (void)testDayOfWeek
{
	OTAssertEqual(_date[0].dayOfWeek, 4);
	OTAssertEqual(_date[1].dayOfWeek, 5);
}

- (void)testDayOfYear
{
	OTAssertEqual(_date[0].dayOfYear, 1);
	OTAssertEqual(_date[1].dayOfYear, 2);
}

- (void)testEarlierDate
{
	OTAssertEqualObjects([_date[0] earlierDate: _date[1]], _date[0]);
}

- (void)testLaterDate
{
	OTAssertEqualObjects([_date[0] laterDate: _date[1]], _date[1]);
}
@end
