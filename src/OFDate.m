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

#include <stdint.h>
#include <limits.h>
#include <time.h>

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
#import "OFOutOfRangeException.h"

#if (!defined(HAVE_GMTIME_R) || !defined(HAVE_LOCALTIME_R)) && \
    defined(OF_THREADS)
static OFMutex *mutex;
#endif

#ifdef HAVE_GMTIME_R
# define GMTIME_RET(field)						  \
	time_t seconds_ = (time_t)seconds;				  \
	struct tm tm;							  \
									  \
	if (seconds != seconds_)					  \
		@throw [OFOutOfRangeException newWithClass: isa];	  \
									  \
	if (gmtime_r(&seconds_, &tm) == NULL)				  \
		@throw [OFOutOfRangeException newWithClass: isa];	  \
									  \
	return tm.field;
# define LOCALTIME_RET(field)						  \
	time_t seconds_ = (time_t)seconds;				  \
	struct tm tm;							  \
									  \
	if (seconds != seconds_)					  \
		@throw [OFOutOfRangeException newWithClass: isa];	  \
									  \
	if (localtime_r(&seconds_, &tm) == NULL)			  \
		@throw [OFOutOfRangeException newWithClass: isa];	  \
									  \
	return tm.field;
#else
# ifdef OF_THREADS
#  define GMTIME_RET(field)						  \
	time_t seconds_ = (time_t)seconds;				  \
	struct tm *tm;							  \
									  \
	if (seconds != seconds_)					  \
		@throw [OFOutOfRangeException newWithClass: isa];	  \
									  \
	[mutex lock];							  \
									  \
	@try {								  \
		if ((tm = gmtime(&seconds_)) == NULL)			  \
			@throw [OFOutOfRangeException newWithClass: isa]; \
									  \
		return tm->field;					  \
	} @finally {							  \
		[mutex unlock];						  \
	}
#  define LOCALTIME_RET(field)						  \
	time_t seconds_ = (time_t)seconds;				  \
	struct tm *tm;							  \
									  \
	if (seconds != seconds_)					  \
		@throw [OFOutOfRangeException newWithClass: isa];	  \
									  \
	[mutex lock];							  \
									  \
	@try {								  \
		if ((tm = localtime(&sec_)) == NULL)			  \
			@throw [OFOutOfRangeException newWithClass: isa]; \
									  \
		return tm->field;					  \
	} @finally {							  \
		[mutex unlock];						  \
	}
# else
#  define GMTIME_RET(field)						  \
	time_t seconds_ = (time_t)seconds;				  \
	struct tm *tm;							  \
									  \
	if (seconds != seconds_)					  \
		@throw [OFOutOfRangeException newWithClass: isa];	  \
									  \
	if ((tm = gmtime(&seconds_)) == NULL)				  \
		@throw [OFOutOfRangeException newWithClass: isa];	  \
									  \
	return tm->field;
#  define LOCALTIME_RET(field)						  \
	time_t seconds_ = (time_t)seconds;				  \
	struct tm *tm;							  \
									  \
	if (seconds != seconds_)					  \
		@throw [OFOutOfRangeException newWithClass: isa];	  \
									  \
	if ((tm = localtime(&seconds_)) == NULL)			  \
		@throw [OFOutOfRangeException newWithClass: isa];	  \
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

+ dateWithTimeIntervalSince1970: (int64_t)seconds
{
	return [[[self alloc]
	    initWithTimeIntervalSince1970: seconds] autorelease];
}

+ dateWithTimeIntervalSince1970: (int64_t)seconds
		   microseconds: (uint32_t)microseconds
{
	return [[[self alloc]
	    initWithTimeIntervalSince1970: seconds
			     microseconds: microseconds] autorelease];
}

+ dateWithTimeIntervalSinceNow: (int64_t)seconds
{
	return [[[self alloc]
	    initWithTimeIntervalSinceNow: seconds] autorelease];
}

+ dateWithTimeIntervalSinceNow: (int64_t)seconds
		  microseconds: (uint32_t)microseconds
{
	return [[[self alloc]
	    initWithTimeIntervalSinceNow: seconds
			    microseconds: microseconds] autorelease];
}

+ distantFuture
{
	if (sizeof(time_t) == sizeof(int64_t))
		return [[[self alloc]
		    initWithTimeIntervalSince1970: INT64_MAX
				     microseconds: 999999] autorelease];
	if (sizeof(time_t) == sizeof(int32_t))
		return [[[self alloc]
		    initWithTimeIntervalSince1970: INT32_MAX
				     microseconds: 999999] autorelease];

	/* Neither 64 nor 32 bit. But it's guaranteed to be at least an int */
	return [[[self alloc]
	    initWithTimeIntervalSince1970: INT_MAX
			     microseconds: 999999] autorelease];
}

+ distantPast
{
	/* We don't know if time_t is signed or unsigned. Use 0 to be safe */
	return [[[self alloc] initWithTimeIntervalSince1970: 0] autorelease];
}

- init
{
	struct timeval t;

	if (gettimeofday(&t, NULL)) {
		Class c = isa;
		[self release];
		@throw [OFInitializationFailedException newWithClass: c];
	}

	return [self initWithTimeIntervalSince1970: t.tv_sec
				      microseconds: (uint32_t)t.tv_usec];
}

- initWithTimeIntervalSince1970: (int64_t)seconds_
{
	return [self initWithTimeIntervalSince1970: seconds_
				      microseconds: 0];
}

- initWithTimeIntervalSince1970: (int64_t)seconds_
		   microseconds: (uint32_t)microseconds_
{
	self = [super init];

	seconds = seconds_;
	microseconds = microseconds_;

	return self;
}

- initWithTimeIntervalSinceNow: (int64_t)seconds_
{
	return [self initWithTimeIntervalSinceNow: seconds_
				     microseconds: 0];
}

- initWithTimeIntervalSinceNow: (int64_t)seconds_
		  microseconds: (uint32_t)microseconds_
{
	self = [self init];

	seconds += seconds_;
	microseconds += microseconds_;

	seconds += microseconds / 1000000;
	microseconds %= 1000000;

	return self;
}

- (BOOL)isEqual: (id)object
{
	OFDate *otherDate;

	if (![object isKindOfClass: [OFDate class]])
		return NO;

	otherDate = (OFDate*)object;

	if (otherDate->seconds != seconds ||
	    otherDate->microseconds != microseconds)
		return NO;

	return YES;
}

- copy
{
	return [self retain];
}

- (of_comparison_result_t)compare: (id)object
{
	OFDate *otherDate;

	if (![object isKindOfClass: [OFDate class]])
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	otherDate = (OFDate*)object;

	if (seconds < otherDate->seconds)
		return OF_ORDERED_ASCENDING;
	if (seconds > otherDate->seconds)
		return OF_ORDERED_DESCENDING;

	if (microseconds < otherDate->microseconds)
		return OF_ORDERED_ASCENDING;
	if (microseconds > otherDate->microseconds)
		return OF_ORDERED_DESCENDING;

	return OF_ORDERED_SAME;
}

- (OFString*)description
{
	return [self dateStringWithFormat: @"%Y-%m-%dT%H:%M:%SZ"];
}

- (OFXMLElement*)XMLElementBySerializing
{
	OFAutoreleasePool *pool;
	OFXMLElement *element;

	element = [OFXMLElement elementWithName: @"object"
				      namespace: OF_SERIALIZATION_NS];

	pool = [[OFAutoreleasePool alloc] init];
	[element addAttributeWithName: @"class"
			  stringValue: [self className]];

	[element addChild:
	    [OFXMLElement elementWithName: @"seconds"
				namespace: OF_SERIALIZATION_NS
			      stringValue: [OFString stringWithFormat:
					       @"%" PRId64, seconds]]];
	[element addChild:
	    [OFXMLElement elementWithName: @"microseconds"
				namespace: OF_SERIALIZATION_NS
			      stringValue: [OFString stringWithFormat:
					       @"%" PRIu32, microseconds]]];

	[pool release];

	return element;
}

- (uint32_t)microsecond
{
	return microseconds;
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

- (OFString*)dateStringWithFormat: (OFString*)format
{
	OFString *ret;
	time_t seconds_ = (time_t)seconds;
	struct tm tm;
	char *buffer;

	if (seconds != seconds_)
		@throw [OFOutOfRangeException newWithClass: isa];

#ifdef HAVE_GMTIME_R
	if (gmtime_r(&seconds_, &tm) == NULL)
		@throw [OFOutOfRangeException newWithClass: isa];
#else
# ifdef OF_THREADS
	[mutex lock];

	@try {
# endif
		struct tm *tmp;

		if ((tmp = gmtime(&seconds_)) == NULL)
			@throw [OFOutOfRangeException newWithClass: isa];

		tm = *tmp;
# ifdef OF_THREADS
	} @finally {
		[mutex unlock];
	}
# endif
#endif

	buffer = [self allocMemoryWithSize: of_pagesize];

	@try {
		if (!strftime(buffer, of_pagesize, [format cString], &tm))
			@throw [OFOutOfRangeException newWithClass: isa];

		ret = [OFString stringWithCString: buffer];
	} @finally {
		[self freeMemory: buffer];
	}

	return ret;
}

- (OFString*)localDateStringWithFormat: (OFString*)format
{
	OFString *ret;
	time_t seconds_ = (time_t)seconds;
	struct tm tm;
	char *buffer;

	if (seconds != seconds_)
		@throw [OFOutOfRangeException newWithClass: isa];

#ifdef HAVE_LOCALTIME_R
	if (localtime_r(&seconds_, &tm) == NULL)
		@throw [OFOutOfRangeException newWithClass: isa];
#else
# ifdef OF_THREADS
	[mutex lock];

	@try {
# endif
		struct tm *tmp;

		if ((tmp = localtime(&seconds_)) == NULL)
			@throw [OFOutOfRangeException newWithClass: isa];

		tm = *tmp;
# ifdef OF_THREADS
	} @finally {
		[mutex unlock];
	}
# endif
#endif

	buffer = [self allocMemoryWithSize: of_pagesize];

	@try {
		if (!strftime(buffer, of_pagesize, [format cString], &tm))
			@throw [OFOutOfRangeException newWithClass: isa];

		ret = [OFString stringWithCString: buffer];
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

- (int64_t)timeIntervalSince1970
{
	return seconds;
}

- (uint32_t)microsecondsOfTimeIntervalSince1970
{
	return microseconds;
}

- (int64_t)timeIntervalSinceDate: (OFDate*)otherDate
{
	int64_t seconds_ = seconds - otherDate->seconds;
	int32_t microseconds_ = (int32_t)microseconds - otherDate->microseconds;

	seconds_ += microseconds_ / 1000000;
	microseconds_ %= 1000000;

	while (microseconds_ < 0) {
		microseconds_ += 1000000;
		seconds_--;
	}

	return seconds_;
}

- (uint32_t)microsecondsOfTimeIntervalSinceDate: (OFDate*)otherDate
{
	int32_t microseconds_ = (int32_t)microseconds - otherDate->microseconds;

	microseconds_ %= 1000000;

	while (microseconds_ < 0)
		microseconds_ += 1000000;

	return microseconds_;
}

- (OFDate*)dateByAddingTimeInterval: (int64_t)sec_
{
	return [self dateByAddingTimeInterval: sec_
			     withMicroseconds: 0];
}

- (OFDate*)dateByAddingTimeInterval: (int64_t)seconds_
		   withMicroseconds: (uint32_t)microseconds_
{
	seconds_ += seconds;
	microseconds_ += microseconds;

	seconds_ += microseconds_ / 1000000;
	microseconds_ %= 1000000;

	return [OFDate dateWithTimeIntervalSince1970: seconds_
					microseconds: microseconds_];
}
@end
