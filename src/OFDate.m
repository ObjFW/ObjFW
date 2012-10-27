/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#include "config.h"

#define _GNU_SOURCE
#include <stdint.h>
#include <limits.h>
#include <time.h>
#include <math.h>
#include <float.h>

#include <sys/time.h>

#import "OFDate.h"
#import "OFString.h"
#import "OFDictionary.h"
#import "OFXMLElement.h"
#ifdef OF_THREADS
# import "OFMutex.h"
#endif

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

#import "autorelease.h"
#import "macros.h"
#import "of_strptime.h"

#if (!defined(HAVE_GMTIME_R) || !defined(HAVE_LOCALTIME_R)) && \
    defined(OF_THREADS)
static OFMutex *mutex;
#endif

#ifdef HAVE_GMTIME_R
# define GMTIME_RET(field)						\
	time_t seconds_ = (time_t)seconds;				\
	struct tm tm;							\
									\
	if (seconds_ != floor(seconds))					\
		@throw [OFOutOfRangeException				\
		    exceptionWithClass: [self class]];			\
									\
	if (gmtime_r(&seconds_, &tm) == NULL)				\
		@throw [OFOutOfRangeException				\
		    exceptionWithClass: [self class]];			\
									\
	return tm.field;
# define LOCALTIME_RET(field)						\
	time_t seconds_ = (time_t)seconds;				\
	struct tm tm;							\
									\
	if (seconds_ != floor(seconds))					\
		@throw [OFOutOfRangeException				\
		    exceptionWithClass: [self class]];			\
									\
	if (localtime_r(&seconds_, &tm) == NULL)			\
		@throw [OFOutOfRangeException				\
		    exceptionWithClass: [self class]];			\
									\
	return tm.field;
#else
# ifdef OF_THREADS
#  define GMTIME_RET(field)						\
	time_t seconds_ = (time_t)seconds;				\
	struct tm *tm;							\
									\
	if (seconds_ != floor(seconds))					\
		@throw [OFOutOfRangeException				\
		    exceptionWithClass: [self class]];			\
									\
	[mutex lock];							\
									\
	@try {								\
		if ((tm = gmtime(&seconds_)) == NULL)			\
			@throw [OFOutOfRangeException			\
			    exceptionWithClass: [self class]];		\
									\
		return tm->field;					\
	} @finally {							\
		[mutex unlock];						\
	}
#  define LOCALTIME_RET(field)						\
	time_t seconds_ = (time_t)seconds;				\
	struct tm *tm;							\
									\
	if (seconds_ != floor(seconds))					\
		@throw [OFOutOfRangeException				\
		    exceptionWithClass: [self class]];			\
									\
	[mutex lock];							\
									\
	@try {								\
		if ((tm = localtime(&seconds_)) == NULL)		\
			@throw [OFOutOfRangeException			\
			    exceptionWithClass: [self class]];		\
									\
		return tm->field;					\
	} @finally {							\
		[mutex unlock];						\
	}
# else
#  define GMTIME_RET(field)						\
	time_t seconds_ = (time_t)seconds;				\
	struct tm *tm;							\
									\
	if (seconds_ != floor(seconds))					\
		@throw [OFOutOfRangeException				\
		    exceptionWithClass: [self class]];			\
									\
	if ((tm = gmtime(&seconds_)) == NULL)				\
		@throw [OFOutOfRangeException				\
		    exceptionWithClass: [self class]];			\
									\
	return tm->field;
#  define LOCALTIME_RET(field)						\
	time_t seconds_ = (time_t)seconds;				\
	struct tm *tm;							\
									\
	if (seconds_ != floor(seconds))					\
		@throw [OFOutOfRangeException				\
		    exceptionWithClass: [self class]];			\
									\
	if ((tm = localtime(&seconds_)) == NULL)			\
		@throw [OFOutOfRangeException				\
		    exceptionWithClass: [self class]];			\
									\
	return tm->field;
# endif
#endif

static int month_to_day_of_year[12] = {
	0,
	31,
	31 + 28,
	31 + 28 + 31,
	31 + 28 + 31 + 30,
	31 + 28 + 31 + 30 + 31,
	31 + 28 + 31 + 30 + 31 + 30,
	31 + 28 + 31 + 30 + 31 + 30 + 31,
	31 + 28 + 31 + 30 + 31 + 30 + 31 + 31,
	31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30,
	31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31,
	31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30,
};

@implementation OFDate
#if (!defined(HAVE_GMTIME_R) || !defined(HAVE_LOCALTIME_R)) && \
    defined(OF_THREADS)
+ (void)initialize
{
	if (self == [OFDate class])
		mutex = [[OFMutex alloc] init];
}
#endif

+ (instancetype)date
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)dateWithTimeIntervalSince1970: (double)seconds
{
	return [[[self alloc]
	    initWithTimeIntervalSince1970: seconds] autorelease];
}

+ (instancetype)dateWithTimeIntervalSinceNow: (double)seconds
{
	return [[[self alloc]
	    initWithTimeIntervalSinceNow: seconds] autorelease];
}

+ (instancetype)dateWithDateString: (OFString*)string
			    format: (OFString*)format
{
	return [[[self alloc] initWithDateString: string
					  format: format] autorelease];
}

+ (instancetype)dateWithLocalDateString: (OFString*)string
				 format: (OFString*)format
{
	return [[[self alloc] initWithLocalDateString: string
					       format: format] autorelease];
}

+ (instancetype)distantFuture
{
	return [[[self alloc]
	    initWithTimeIntervalSince1970: DBL_MAX] autorelease];
}

+ (instancetype)distantPast
{
	return [[[self alloc]
	    initWithTimeIntervalSince1970: DBL_MIN] autorelease];
}

- init
{
	struct timeval t;

	self = [super init];

	OF_ENSURE(!gettimeofday(&t, NULL));

	seconds = t.tv_sec;
	seconds += (double)t.tv_usec / 1000000;

	return self;
}

- initWithTimeIntervalSince1970: (double)seconds_
{
	self = [super init];

	seconds = seconds_;

	return self;
}

- initWithTimeIntervalSinceNow: (double)seconds_
{
	self = [self init];

	seconds += seconds_;

	return self;
}

- initWithDateString: (OFString*)string
	      format: (OFString*)format
{
	self = [super init];

	@try {
		struct tm tm = {};

		tm.tm_isdst = -1;

		if (of_strptime([string UTF8String], [format UTF8String],
		    &tm) == NULL)
			@throw [OFInvalidFormatException
			    exceptionWithClass: [self class]];

		/* Years */
		seconds = (int64_t)(tm.tm_year - 70) * 31536000;
		/* Days of leap years, excluding the year to look at */
		seconds += (((tm.tm_year + 1899) / 4) - 492) * 86400;
		seconds -= (((tm.tm_year + 1899) / 100) - 19) * 86400;
		seconds += (((tm.tm_year + 1899) / 400) - 4) * 86400;
		/* Leap day */
		if (tm.tm_mon >= 2 && (((tm.tm_year + 1900) % 4 == 0 &&
		    (tm.tm_year + 1900) % 100 != 0) ||
		    (tm.tm_year + 1900) % 400 == 0))
			seconds += 86400;
		/* Months */
		if (tm.tm_mon < 0 || tm.tm_mon > 12)
			@throw [OFInvalidFormatException
			    exceptionWithClass: [self class]];
		seconds += month_to_day_of_year[tm.tm_mon] * 86400;
		/* Days */
		seconds += (tm.tm_mday - 1) * 86400;
		/* Hours */
		seconds += tm.tm_hour * 3600;
		/* Minutes */
		seconds += tm.tm_min * 60;
		/* Seconds */
		seconds += tm.tm_sec;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithLocalDateString: (OFString*)string
		   format: (OFString*)format
{
	self = [super init];

	@try {
		struct tm tm = {};

		tm.tm_isdst = -1;

		if (of_strptime([string UTF8String], [format UTF8String],
		    &tm) == NULL)
			@throw [OFInvalidFormatException
			    exceptionWithClass: [self class]];

		if ((seconds = mktime(&tm)) == -1)
			@throw [OFInvalidFormatException
			    exceptionWithClass: [self class]];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithSerialization: (OFXMLElement*)element
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		union {
			double d;
			uint64_t u;
		} d;

		if (![[element name] isEqual: [self className]] ||
		    ![[element namespace] isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException
			    exceptionWithClass: [self class]
				      selector: _cmd];

		d.u = (uint64_t)[element hexadecimalValue];
		seconds = d.d;

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (BOOL)isEqual: (id)object
{
	OFDate *otherDate;

	if (![object isKindOfClass: [OFDate class]])
		return NO;

	otherDate = object;

	if (otherDate->seconds != seconds)
		return NO;

	return YES;
}

- (uint32_t)hash
{
	uint32_t hash;
	union {
		double d;
		uint8_t b[sizeof(double)];
	} d;
	uint8_t i;

	d.d = OF_BSWAP_DOUBLE_IF_LE(seconds);

	OF_HASH_INIT(hash);

	for (i = 0; i < sizeof(double); i++)
		OF_HASH_ADD(hash, d.b[i]);

	OF_HASH_FINALIZE(hash);

	return hash;
}

- copy
{
	return [self retain];
}

- (of_comparison_result_t)compare: (id <OFComparing>)object
{
	OFDate *otherDate;

	if (![object isKindOfClass: [OFDate class]])
		@throw [OFInvalidArgumentException
		    exceptionWithClass: [self class]
			      selector: _cmd];

	otherDate = (OFDate*)object;

	if (seconds < otherDate->seconds)
		return OF_ORDERED_ASCENDING;
	if (seconds > otherDate->seconds)
		return OF_ORDERED_DESCENDING;

	return OF_ORDERED_SAME;
}

- (OFString*)description
{
	return [self dateStringWithFormat: @"%Y-%m-%dT%H:%M:%SZ"];
}

- (OFXMLElement*)XMLElementBySerializing
{
	void *pool = objc_autoreleasePoolPush();
	OFXMLElement *element;
	union {
		double d;
		uint64_t u;
	} d;

	element = [OFXMLElement elementWithName: [self className]
				      namespace: OF_SERIALIZATION_NS];

	d.d = seconds;
	[element setStringValue:
	    [OFString stringWithFormat: @"%016" PRIx64, d.u]];

	[element retain];

	objc_autoreleasePoolPop(pool);

	return [element autorelease];
}

- (uint32_t)microsecond
{
	return (uint32_t)rint((seconds - floor(seconds)) * 1000000);
}

- (uint8_t)second
{
	GMTIME_RET(tm_sec)
}

- (uint8_t)minute
{
	GMTIME_RET(tm_min)
}

- (uint8_t)hour
{
	GMTIME_RET(tm_hour)
}

- (uint8_t)localHour
{
	LOCALTIME_RET(tm_hour)
}

- (uint8_t)dayOfMonth
{
	GMTIME_RET(tm_mday)
}

- (uint8_t)localDayOfMonth
{
	LOCALTIME_RET(tm_mday)
}

- (uint8_t)monthOfYear
{
	GMTIME_RET(tm_mon + 1)
}

- (uint8_t)localMonthOfYear
{
	LOCALTIME_RET(tm_mon + 1)
}

- (uint16_t)year
{
	GMTIME_RET(tm_year + 1900)
}

- (uint16_t)localYear
{
	LOCALTIME_RET(tm_year + 1900)
}

- (uint8_t)dayOfWeek
{
	GMTIME_RET(tm_wday)
}

- (uint8_t)localDayOfWeek
{
	LOCALTIME_RET(tm_wday)
}

- (uint16_t)dayOfYear
{
	GMTIME_RET(tm_yday + 1)
}

- (uint16_t)localDayOfYear
{
	LOCALTIME_RET(tm_yday + 1)
}

- (OFString*)dateStringWithFormat: (OFConstantString*)format
{
	OFString *ret;
	time_t seconds_ = (time_t)seconds;
	struct tm tm;
	char *buffer;

	if (seconds_ != floor(seconds))
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

#ifdef HAVE_GMTIME_R
	if (gmtime_r(&seconds_, &tm) == NULL)
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];
#else
# ifdef OF_THREADS
	[mutex lock];

	@try {
# endif
		struct tm *tmp;

		if ((tmp = gmtime(&seconds_)) == NULL)
			@throw [OFOutOfRangeException
			    exceptionWithClass: [self class]];

		tm = *tmp;
# ifdef OF_THREADS
	} @finally {
		[mutex unlock];
	}
# endif
#endif

	buffer = [self allocMemoryWithSize: of_pagesize];

	@try {
		if (!strftime(buffer, of_pagesize, [format UTF8String], &tm))
			@throw [OFOutOfRangeException
			    exceptionWithClass: [self class]];

		ret = [OFString stringWithUTF8String: buffer];
	} @finally {
		[self freeMemory: buffer];
	}

	return ret;
}

- (OFString*)localDateStringWithFormat: (OFConstantString*)format
{
	OFString *ret;
	time_t seconds_ = (time_t)seconds;
	struct tm tm;
	char *buffer;

	if (seconds_ != floor(seconds))
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

#ifdef HAVE_LOCALTIME_R
	if (localtime_r(&seconds_, &tm) == NULL)
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];
#else
# ifdef OF_THREADS
	[mutex lock];

	@try {
# endif
		struct tm *tmp;

		if ((tmp = localtime(&seconds_)) == NULL)
			@throw [OFOutOfRangeException
			    exceptionWithClass: [self class]];

		tm = *tmp;
# ifdef OF_THREADS
	} @finally {
		[mutex unlock];
	}
# endif
#endif

	buffer = [self allocMemoryWithSize: of_pagesize];

	@try {
		if (!strftime(buffer, of_pagesize, [format UTF8String], &tm))
			@throw [OFOutOfRangeException
			    exceptionWithClass: [self class]];

		ret = [OFString stringWithUTF8String: buffer];
	} @finally {
		[self freeMemory: buffer];
	}

	return ret;
}

- (OFDate*)earlierDate: (OFDate*)otherDate
{
	if ([self compare: otherDate] == OF_ORDERED_DESCENDING)
		return [[otherDate retain] autorelease];

	return [[self retain] autorelease];
}

- (OFDate*)laterDate: (OFDate*)otherDate
{
	if ([self compare: otherDate] == OF_ORDERED_ASCENDING)
		return [[otherDate retain] autorelease];

	return [[self retain] autorelease];
}

- (double)timeIntervalSince1970
{
	return seconds;
}

- (double)timeIntervalSinceDate: (OFDate*)otherDate
{
	return seconds - otherDate->seconds;
}

- (double)timeIntervalSinceNow
{
	struct timeval t;
	double seconds_;

	OF_ENSURE(!gettimeofday(&t, NULL));

	seconds_ = t.tv_sec;
	seconds_ += (double)t.tv_usec / 1000000;

	return seconds - seconds_;
}

- (OFDate*)dateByAddingTimeInterval: (double)seconds_
{
	return [OFDate dateWithTimeIntervalSince1970: seconds + seconds_];
}
@end
