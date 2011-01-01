/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include <sys/time.h>

#import "OFObject.h"

@class OFString;

#ifdef __MINGW32__
/*
 * They think they don't need suseconds_t and can use long instead in
 * struct timeval... POSIX demands suseconds_t, of course.
 */
typedef long suseconds_t;
#endif

/**
 * \brief A class for storing, accessing and comparing dates.
 */
@interface OFDate: OFObject <OFCopying, OFComparing>
{
	time_t sec;
	suseconds_t usec;
}

/**
 * \return A new, autoreleased OFDate with the current date and time
 */
+ date;

/**
 * \param sec The seconds since 1970-01-01 00:00:00
 * \return A new, autoreleased OFDate with the specified date and time
 */
+ dateWithTimeIntervalSince1970: (time_t)sec;

/**
 * \param sec The seconds since 1970-01-01 00:00:00
 * \param usec The microsecond part of the time
 * \return A new, autoreleased OFDate with the specified date and time
 */
+ dateWithTimeIntervalSince1970: (time_t)sec
		   microseconds: (suseconds_t)usec;

/**
 * \return A date in the distant future
 */
+ distantFuture;

/**
 * \return A date in the distant past
 */
+ distantPast;

/**
 * Initializes an already allocated OFDate with the specified date and time.
 *
 * \param sec The seconds since 1970-01-01 00:00:00
 * \return An initialized OFDate with the specified date and time
 */
- initWithTimeIntervalSince1970: (time_t)sec;

/**
 * Initializes an already allocated OFDate with the specified date and time.
 *
 * \param sec The seconds since 1970-01-01 00:00:00
 * \param usec The microsecond part of the time
 * \return An initialized OFDate with the specified date and time
 */
- initWithTimeIntervalSince1970: (time_t)sec
		   microseconds: (suseconds_t)usec;

/**
 * \return The microsecond of the date
 */
- (suseconds_t)microsecond;

/**
 * \return The seconds of the date
 */
- (int)second;

/**
 * \return The minute of the date
 */
- (int)minute;

/**
 * \return The hour of the date
 */
- (int)hour;

/**
 * \return The hour of the date in local time
 */
- (int)localHour;

/**
 * \return The day of the month of the date
 */
- (int)dayOfMonth;

/**
 * \return The day of the month of the date in local time
 */
- (int)localDayOfMonth;

/**
 * \return The month of the year of the date
 */
- (int)monthOfYear;

/**
 * \return The month of the year of the date in local time
 */
- (int)localMonthOfYear;

/**
 * \return The year of the date
 */
- (int)year;

/**
 * \return The day of the week of the date
 */
- (int)dayOfWeek;

/**
 * \return The day of the week of the date in local time
 */
- (int)localDayOfWeek;

/**
 * \return The day of the year of the date
 */
- (int)dayOfYear;

/**
 * \return The day of the year of the date in local time
 */
- (int)localDayOfYear;

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
@end
