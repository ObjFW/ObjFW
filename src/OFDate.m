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

#include "config.h"

#include <stdint.h>
#include <limits.h>
#include <time.h>

#include <sys/time.h>

#import "OFDate.h"
#import "OFString.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"

#if (!defined(HAVE_GMTIME_R) || !defined(HAVE_LOCALTIME_R)) && \
    defined(OF_THREADS)
# import "OFThread.h"

static OFMutex *mutex;
#endif

#ifdef HAVE_GMTIME_R
# define GMTIME_RET(field)						  \
	time_t sec_ = sec;						  \
	struct tm tm;							  \
									  \
	if (sec != sec_)						  \
		@throw [OFOutOfRangeException newWithClass: isa];	  \
									  \
	if (gmtime_r(&sec_, &tm) == NULL)				  \
		@throw [OFOutOfRangeException newWithClass: isa];	  \
									  \
	return tm.field;
# define LOCALTIME_RET(field)						  \
	time_t sec_ = sec;						  \
	struct tm tm;							  \
									  \
	if (sec != sec_)						  \
		@throw [OFOutOfRangeException newWithClass: isa];	  \
									  \
	if (localtime_r(&sec_, &tm) == NULL)				  \
		@throw [OFOutOfRangeException newWithClass: isa];	  \
									  \
	return tm.field;
#else
# ifdef OF_THREADS
#  define GMTIME_RET(field)						  \
	time_t sec_ = sec;						  \
	struct tm *tm;							  \
									  \
	if (sec != sec_)						  \
		@throw [OFOutOfRangeException newWithClass: isa];	  \
									  \
	[mutex lock];							  \
									  \
	@try {								  \
		if ((tm = gmtime(&sec_)) == NULL)			  \
			@throw [OFOutOfRangeException newWithClass: isa]; \
									  \
		return tm->field;					  \
	} @finally {							  \
		[mutex unlock];						  \
	}
#  define LOCALTIME_RET(field)						  \
	time_t sec_ = sec;						  \
	struct tm *tm;							  \
									  \
	if (sec != sec_)						  \
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
	time_t sec_ = sec;						  \
	struct tm *tm;							  \
									  \
	if (sec != sec_)						  \
		@throw [OFOutOfRangeException newWithClass: isa];	  \
									  \
	if ((tm = gmtime(&sec_)) == NULL)				  \
		@throw [OFOutOfRangeException newWithClass: isa];	  \
									  \
	return tm->field;
#  define LOCALTIME_RET(field)						  \
	time_t sec_ = sec;						  \
	struct tm *tm;							  \
									  \
	if (sec != sec_)						  \
		@throw [OFOutOfRangeException newWithClass: isa];	  \
									  \
	if ((tm = localtime(&sec_)) == NULL)				  \
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

+ dateWithTimeIntervalSince1970: (int64_t)sec
{
	return [[[self alloc] initWithTimeIntervalSince1970: sec] autorelease];
}

+ dateWithTimeIntervalSince1970: (int64_t)sec
		   microseconds: (uint32_t)usec
{
	return [[[self alloc] initWithTimeIntervalSince1970: sec
					       microseconds: usec] autorelease];
}

+ dateWithTimeIntervalSinceNow: (int64_t)sec
{
	return [[[self alloc] initWithTimeIntervalSinceNow: sec] autorelease];
}

+ dateWithTimeIntervalSinceNow: (int64_t)sec
		  microseconds: (uint32_t)usec
{
	return [[[self alloc] initWithTimeIntervalSinceNow: sec
					      microseconds: usec] autorelease];
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
				      microseconds: t.tv_usec];
}

- initWithTimeIntervalSince1970: (int64_t)sec_
{
	return [self initWithTimeIntervalSince1970: sec_
				      microseconds: 0];
}

- initWithTimeIntervalSince1970: (int64_t)sec_
		   microseconds: (uint32_t)usec_
{
	self = [super init];

	sec = sec_;
	usec = usec_;

	return self;
}

- initWithTimeIntervalSinceNow: (int64_t)sec_
{
	return [self initWithTimeIntervalSinceNow: sec_
				     microseconds: 0];
}

- initWithTimeIntervalSinceNow: (int64_t)sec_
		  microseconds: (uint32_t)usec_
{
	self = [self init];

	sec += sec_;
	usec += usec_;

	while (usec > 999999) {
		usec -= 999999;
		sec++;
	}

	return self;
}

- (BOOL)isEqual: (id)obj
{
	if (![obj isKindOfClass: [OFDate class]])
		return NO;
	if (((OFDate*)obj)->sec != sec || ((OFDate*)obj)->usec != usec)
		return NO;

	return YES;
}

- copy
{
	return [self retain];
}

- (of_comparison_result_t)compare: (id)obj
{
	if (![obj isKindOfClass: [OFDate class]])
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	if (sec < ((OFDate*)obj)->sec)
		return OF_ORDERED_ASCENDING;
	if (sec > ((OFDate*)obj)->sec)
		return OF_ORDERED_DESCENDING;

	if (usec < ((OFDate*)obj)->usec)
		return OF_ORDERED_ASCENDING;
	if (usec > ((OFDate*)obj)->usec)
		return OF_ORDERED_DESCENDING;

	return OF_ORDERED_SAME;
}

- (OFString*)description
{
	return [self dateStringWithFormat: @"%Y-%m-%dT%H:%M:%SZ"];
}

- (uint32_t)microsecond
{
	return usec;
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

- (OFString*)dateStringWithFormat: (OFString*)fmt
{
	time_t sec_ = sec;
	struct tm tm;
	char *buf;

	if (sec != sec_)
		@throw [OFOutOfRangeException newWithClass: isa];

#ifdef HAVE_GMTIME_R
	if (gmtime_r(&sec_, &tm) == NULL)
		@throw [OFOutOfRangeException newWithClass: isa];
#else
# ifdef OF_THREADS
	[mutex lock];

	@try {
# endif
		struct tm *tmp;

		if ((tmp = gmtime(&sec)) == NULL)
			@throw [OFOutOfRangeException newWithClass: isa];

		tm = *tmp;
# ifdef OF_THREADS
	} @finally {
		[mutex unlock];
	}
# endif
#endif

	buf = [self allocMemoryWithSize: of_pagesize];

	@try {
		if (!strftime(buf, of_pagesize, [fmt cString], &tm))
			@throw [OFOutOfRangeException newWithClass: isa];

		return [OFString stringWithCString: buf];
	} @finally {
		[self freeMemory: buf];
	}
}

- (OFString*)localDateStringWithFormat: (OFString*)fmt
{
	time_t sec_ = sec;
	struct tm tm;
	char *buf;

	if (sec != sec_)
		@throw [OFOutOfRangeException newWithClass: isa];

#ifdef HAVE_LOCALTIME_R
	if (localtime_r(&sec_, &tm) == NULL)
		@throw [OFOutOfRangeException newWithClass: isa];
#else
# ifdef OF_THREADS
	[mutex lock];

	@try {
# endif
		struct tm *tmp;

		if ((tmp = localtime(&sec)) == NULL)
			@throw [OFOutOfRangeException newWithClass: isa];

		tm = *tmp;
# ifdef OF_THREADS
	} @finally {
		[mutex unlock];
	}
# endif
#endif

	buf = [self allocMemoryWithSize: of_pagesize];

	@try {
		if (!strftime(buf, of_pagesize, [fmt cString], &tm))
			@throw [OFOutOfRangeException newWithClass: isa];

		return [OFString stringWithCString: buf];
	} @finally {
		[self freeMemory: buf];
	}
}

- (OFDate*)earlierDate: (OFDate*)date
{
	if ([self compare: date] == OF_ORDERED_DESCENDING)
		return [[date retain] autorelease];

	return [[self retain] autorelease];
}

- (OFDate*)laterDate: (OFDate*)date
{
	if ([self compare: date] == OF_ORDERED_ASCENDING)
		return [[date retain] autorelease];

	return [[self retain] autorelease];
}

- (OFDate*)dateByAddingTimeInterval: (int64_t)sec_
{
	return [self dateByAddingTimeInterval: sec_
			     withMicroseconds: 0];
}

- (OFDate*)dateByAddingTimeInterval: (int64_t)sec_
		   withMicroseconds: (uint32_t)usec_
{
	sec_ += sec;
	usec_ += usec;

	while (usec_ > 999999) {
		usec_ -= 999999;
		sec_++;
	}

	return [OFDate dateWithTimeIntervalSince1970: sec_
					microseconds: usec_];
}
@end
