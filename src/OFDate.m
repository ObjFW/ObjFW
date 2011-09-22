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

#include "config.h"

#define _GNU_SOURCE
#include <stdint.h>
#include <limits.h>
#include <time.h>
#include <math.h>
#include <float.h>
#include <assert.h>

#include <sys/time.h>

#import "OFDate.h"
#import "OFString.h"
#import "OFDictionary.h"
#import "OFXMLElement.h"
#import "OFAutoreleasePool.h"
#ifdef OF_THREADS
# import "OFThread.h"
#endif

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

#import "macros.h"

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
		@throw [OFOutOfRangeException exceptionWithClass: isa];	\
									\
	if (gmtime_r(&seconds_, &tm) == NULL)				\
		@throw [OFOutOfRangeException exceptionWithClass: isa];	\
									\
	return tm.field;
# define LOCALTIME_RET(field)						\
	time_t seconds_ = (time_t)seconds;				\
	struct tm tm;							\
									\
	if (seconds_ != floor(seconds))					\
		@throw [OFOutOfRangeException exceptionWithClass: isa];	\
									\
	if (localtime_r(&seconds_, &tm) == NULL)			\
		@throw [OFOutOfRangeException exceptionWithClass: isa];	\
									\
	return tm.field;
#else
# ifdef OF_THREADS
#  define GMTIME_RET(field)						\
	time_t seconds_ = (time_t)seconds;				\
	struct tm *tm;							\
									\
	if (seconds_ != floor(seconds))					\
		@throw [OFOutOfRangeException exceptionWithClass: isa];	\
									\
	[mutex lock];							\
									\
	@try {								\
		if ((tm = gmtime(&seconds_)) == NULL)			\
			@throw [OFOutOfRangeException			\
			    exceptionWithClass: isa];			\
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
		@throw [OFOutOfRangeException exceptionWithClass: isa];	\
									\
	[mutex lock];							\
									\
	@try {								\
		if ((tm = localtime(&seconds_)) == NULL)		\
			@throw [OFOutOfRangeException			\
			    exceptionWithClass: isa];			\
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
		@throw [OFOutOfRangeException exceptionWithClass: isa];	\
									\
	if ((tm = gmtime(&seconds_)) == NULL)				\
		@throw [OFOutOfRangeException exceptionWithClass: isa];	\
									\
	return tm->field;
#  define LOCALTIME_RET(field)						\
	time_t seconds_ = (time_t)seconds;				\
	struct tm *tm;							\
									\
	if (seconds_ != floor(seconds))					\
		@throw [OFOutOfRangeException exceptionWithClass: isa];	\
									\
	if ((tm = localtime(&seconds_)) == NULL)			\
		@throw [OFOutOfRangeException exceptionWithClass: isa];	\
									\
	return tm->field;
# endif
#endif

@implementation OFDate
#if (!defined(HAVE_GMTIME_R) || !defined(HAVE_LOCALTIME_R)) && \
    defined(OF_THREADS)
+ (void)initialize
{
	if (self == [OFDate class])
		mutex = [[OFMutex alloc] init];
}
#endif

+ date
{
	return [[[self alloc] init] autorelease];
}

+ dateWithTimeIntervalSince1970: (double)seconds
{
	return [[[self alloc]
	    initWithTimeIntervalSince1970: seconds] autorelease];
}

+ dateWithTimeIntervalSinceNow: (double)seconds
{
	return [[[self alloc]
	    initWithTimeIntervalSinceNow: seconds] autorelease];
}

+ dateWithDateString: (OFString*)string
	      format: (OFString*)format
{
	return [[[self alloc] initWithDateString: string
					  format: format] autorelease];
}

+ dateWithLocalDateString: (OFString*)string
		   format: (OFString*)format
{
	return [[[self alloc] initWithLocalDateString: string
					       format: format] autorelease];
}

+ distantFuture
{
	return [[[self alloc]
	    initWithTimeIntervalSince1970: DBL_MAX] autorelease];
}

+ distantPast
{
	return [[[self alloc]
	    initWithTimeIntervalSince1970: DBL_MIN] autorelease];
}

- init
{
	struct timeval t;

	self = [super init];

	assert(!gettimeofday(&t, NULL));

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

		if (strptime([string UTF8String], [format UTF8String],
		    &tm) == NULL)
			@throw [OFInvalidFormatException
			    exceptionWithClass: isa];

		if (tm.tm_gmtoff)
			@throw [OFInvalidFormatException
			    exceptionWithClass: isa];

		if ((seconds = mktime(&tm)) == -1)
			@throw [OFInvalidFormatException
			    exceptionWithClass: isa];

		seconds += tm.tm_gmtoff;
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

		if (strptime([string UTF8String], [format UTF8String],
		    &tm) == NULL)
			@throw [OFInvalidFormatException
			    exceptionWithClass: isa];

		if ((seconds = mktime(&tm)) == -1)
			@throw [OFInvalidFormatException
			    exceptionWithClass: isa];
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
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

		if (![[element name] isEqual: [self className]] ||
		    ![[element namespace] isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException
			    exceptionWithClass: isa
				      selector: _cmd];

		seconds = [element doubleValue];

		[pool release];
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

	d.d = of_bswap_double_if_le(seconds);

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

- (of_comparison_result_t)compare: (id)object
{
	OFDate *otherDate;

	if (![object isKindOfClass: [OFDate class]])
		@throw [OFInvalidArgumentException exceptionWithClass: isa
							     selector: _cmd];

	otherDate = object;

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
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFXMLElement *element;

	element = [OFXMLElement elementWithName: [self className]
				      namespace: OF_SERIALIZATION_NS];
	[element setStringValue: [OFString stringWithFormat: @"%la", seconds]];

	[element retain];
	[pool release];
	[element autorelease];

	return element;
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
		@throw [OFOutOfRangeException exceptionWithClass: isa];

#ifdef HAVE_GMTIME_R
	if (gmtime_r(&seconds_, &tm) == NULL)
		@throw [OFOutOfRangeException exceptionWithClass: isa];
#else
# ifdef OF_THREADS
	[mutex lock];

	@try {
# endif
		struct tm *tmp;

		if ((tmp = gmtime(&seconds_)) == NULL)
			@throw [OFOutOfRangeException exceptionWithClass: isa];

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
			@throw [OFOutOfRangeException exceptionWithClass: isa];

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
		@throw [OFOutOfRangeException exceptionWithClass: isa];

#ifdef HAVE_LOCALTIME_R
	if (localtime_r(&seconds_, &tm) == NULL)
		@throw [OFOutOfRangeException exceptionWithClass: isa];
#else
# ifdef OF_THREADS
	[mutex lock];

	@try {
# endif
		struct tm *tmp;

		if ((tmp = localtime(&seconds_)) == NULL)
			@throw [OFOutOfRangeException exceptionWithClass: isa];

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
			@throw [OFOutOfRangeException exceptionWithClass: isa];

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

	assert(!gettimeofday(&t, NULL));

	seconds_ = t.tv_sec;
	seconds_ += (double)t.tv_usec / 1000000;

	return seconds - seconds_;
}

- (OFDate*)dateByAddingTimeInterval: (double)seconds_
{
	return [OFDate dateWithTimeIntervalSince1970: seconds + seconds_];
}
@end
