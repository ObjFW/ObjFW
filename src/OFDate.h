/*
 * Copyright (c) 2008, 2009, 2010, 2011
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "OFObject.h"

@class OFString;

/**
 * \brief A class for storing, accessing and comparing dates.
 */
@interface OFDate: OFObject <OFCopying, OFComparing>
{
	int64_t sec;
	uint32_t usec;
}

/**
 * \return A new, autoreleased OFDate with the current date and time
 */
+ date;

/**
 * \param sec The seconds since 1970-01-01T00:00:00Z
 * \return A new, autoreleased OFDate with the specified date and time
 */
+ dateWithTimeIntervalSince1970: (int64_t)sec;

/**
 * \param sec The seconds since 1970-01-01T00:00:00Z
 * \param usec The microsecond part of the time
 * \return A new, autoreleased OFDate with the specified date and time
 */
+ dateWithTimeIntervalSince1970: (int64_t)sec
		   microseconds: (uint32_t)usec;

/**
 * \param sec The seconds since now
 * \return A new, autoreleased OFDate with the specified date and time
 */
+ dateWithTimeIntervalSinceNow: (int64_t)sec;

/**
 * \param sec The seconds since now
 * \param usec The microsecond part of the time
 * \return A new, autoreleased OFDate with the specified date and time
 */
+ dateWithTimeIntervalSinceNow: (int64_t)sec
		  microseconds: (uint32_t)usec;

/**
 * Returns a date in the distant future. The date is system-dependant.
 *
 * \return A date in the distant future
 */
+ distantFuture;

/**
 * Returns a date in the distant past. The date is system-dependant.
 *
 * \return A date in the distant past
 */
+ distantPast;

/**
 * Initializes an already allocated OFDate with the specified date and time.
 *
 * \param sec The seconds since 1970-01-01T00:00:00Z
 * \return An initialized OFDate with the specified date and time
 */
- initWithTimeIntervalSince1970: (int64_t)sec;

/**
 * Initializes an already allocated OFDate with the specified date and time.
 *
 * \param sec The seconds since 1970-01-01T00:00:00Z
 * \param usec The microsecond part of the time
 * \return An initialized OFDate with the specified date and time
 */
- initWithTimeIntervalSince1970: (int64_t)sec
		   microseconds: (uint32_t)usec;

/**
 * Initializes an already allocated OFDate with the specified date and time.
 *
 * \param sec The seconds since now
 * \param usec The microsecond part of the time
 * \return A new, autoreleased OFDate with the specified date and time
 */
- initWithTimeIntervalSinceNow: (int64_t)sec;

/**
 * Initializes an already allocated OFDate with the specified date and time.
 *
 * \param sec The seconds since now
 * \param usec The microsecond part of the time
 * \return A new, autoreleased OFDate with the specified date and time
 */
- initWithTimeIntervalSinceNow: (int64_t)sec
		  microseconds: (uint32_t)usec;

/**
 * \return The microsecond of the date
 */
- (uint32_t)microsecond;

/**
 * \return The seconds of the date
 */
- (uint8_t)second;

/**
 * \return The minute of the date
 */
- (uint8_t)minute;

/**
 * \return The hour of the date
 */
- (uint8_t)hour;

/**
 * \return The hour of the date in local time
 */
- (uint8_t)localHour;

/**
 * \return The day of the month of the date
 */
- (uint8_t)dayOfMonth;

/**
 * \return The day of the month of the date in local time
 */
- (uint8_t)localDayOfMonth;

/**
 * \return The month of the year of the date
 */
- (uint8_t)monthOfYear;

/**
 * \return The month of the year of the date in local time
 */
- (uint8_t)localMonthOfYear;

/**
 * \return The year of the date
 */
- (uint16_t)year;

/**
 * \return The day of the week of the date
 */
- (uint8_t)dayOfWeek;

/**
 * \return The day of the week of the date in local time
 */
- (uint8_t)localDayOfWeek;

/**
 * \return The day of the year of the date
 */
- (uint16_t)dayOfYear;

/**
 * \return The day of the year of the date in local time
 */
- (uint16_t)localDayOfYear;

/**
 * Creates a string of the date with the specified format.
 *
 * See the manpage for strftime for information on the format.
 *
 * \param fmt The format for the date string
 * \return A new, autoreleased OFString
 */
- (OFString*)dateStringWithFormat: (OFString*)fmt;

/**
 * Creates a string of the local date with the specified format.
 *
 * See the manpage for strftime for information on the format.
 *
 * \param fmt The format for the date string
 * \return A new, autoreleased OFString
 */
- (OFString*)localDateStringWithFormat: (OFString*)fmt;

/**
 * \param date Another date
 * \return The earlier date of the two dates
 */
- (OFDate*)earlierDate: (OFDate*)date;

/**
 * \param date Another date
 * \return The later date of the two dates
 */
- (OFDate*)laterDate: (OFDate*)date;

/**
 * \return The seconds since 1970-01-01T00:00:00Z
 */
- (int64_t)timeIntervalSince1970;

/**
 * \return The microseconds part of the seconds since 1970-01-01T00:00:00Z
 */
- (uint32_t)microsecondsOfTimeIntervalSince1970;

/**
 * \return The seconds the date is after the receiver
 */
- (int64_t)timeIntervalSinceDate: (OFDate*)date;

/**
 * \return The microseconds part of the seconds the date is after the receiver
 */
- (uint32_t)microsecondsOfTimeIntervalSinceDate: (OFDate*)date;

/**
 * Returns a new date with the specified time interval added.
 *
 * \param sec The seconds after the date
 * \return A new, autoreleased OFDate
 */
- (OFDate*)dateByAddingTimeInterval: (int64_t)sec;

/**
 * Returns a new date with the specified time interval added.
 *
 * \param sec The seconds after the date
 * \param usec The microseconds after the date
 * \return A new, autoreleased OFDate
 */
- (OFDate*)dateByAddingTimeInterval: (int64_t)sec
		   withMicroseconds: (uint32_t)usec;
@end
