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
	struct tm tm;							  \
									  \
	if (gmtime_r(&sec, &tm) == NULL)				  \
		@throw [OFOutOfRangeException newWithClass: isa];	  \
									  \
	return tm.field;
# define LOCALTIME_RET(field)						  \
	struct tm tm;							  \
									  \
	if (localtime_r(&sec, &tm) == NULL)				  \
		@throw [OFOutOfRangeException newWithClass: isa];	  \
									  \
	return tm.field;
#else
# ifdef OF_THREADS
#  define GMTIME_RET(field)						  \
	struct tm *tm;							  \
									  \
	[mutex lock];							  \
									  \
	@try {								  \
		if ((tm = gmtime(&sec)) == NULL)			  \
			@throw [OFOutOfRangeException newWithClass: isa]; \
									  \
		return tm->field;					  \
	} @finally {							  \
		[mutex unlock];						  \
	}
#  define LOCALTIME_RET(field)						  \
	struct tm *tm;							  \
									  \
	[mutex lock];							  \
									  \
	@try {								  \
		if ((tm = localtime(&sec)) == NULL)			  \
			@throw [OFOutOfRangeException newWithClass: isa]; \
									  \
		return tm->field;					  \
	} @finally {							  \
		[mutex unlock];						  \
	}
# else
#  define GMTIME_RET(field)						  \
	struct tm *tm;							  \
									  \
	if ((tm = gmtime(&sec)) == NULL)				  \
		@throw [OFOutOfRangeException newWithClass: isa];	  \
									  \
	return tm->field;
#  define LOCALTIME_RET(field)						  \
	struct tm *tm;							  \
									  \
	if ((tm = localtime(&sec)) == NULL)				  \
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

+ dateWithTimeIntervalSince1970: (time_t)sec
{
	return [[[self alloc] initWithTimeIntervalSince1970: sec] autorelease];
}

+ dateWithTimeIntervalSince1970: (time_t)sec
		   microseconds: (suseconds_t)usec
{
	return [[[self alloc] initWithTimeIntervalSince1970: sec
					       microseconds: usec] autorelease];
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

- initWithTimeIntervalSince1970: (time_t)sec_
{
	return [self initWithTimeIntervalSince1970: sec_
				      microseconds: 0];
}

- initWithTimeIntervalSince1970: (time_t)sec_
		   microseconds: (suseconds_t)usec_
{
	self = [super init];

	sec = sec_;
	usec = usec_;

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
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFString *tmp, *ret;

	tmp = [self dateStringWithFormat: @"%Y-%m-%dT%H:%M:%S"];

	if (usec == 0)
		ret = [OFString stringWithFormat: @"%sZ", [tmp cString]];
	else
		ret = [OFString stringWithFormat: @"%s.%06dZ", [tmp cString],
						  usec];

	[ret retain];
	[pool release];

	return [ret autorelease];
}

- (suseconds_t)microsecond
{
	return usec;
}

- (int)second
{
	GMTIME_RET(tm_sec)
}

- (int)minute
{
	GMTIME_RET(tm_min)
}

- (int)hour
{
	GMTIME_RET(tm_hour)
}

- (int)localHour
{
	LOCALTIME_RET(tm_hour)
}

- (int)dayOfMonth
{
	GMTIME_RET(tm_mday)
}

- (int)localDayOfMonth
{
	LOCALTIME_RET(tm_mday)
}

- (int)monthOfYear
{
	GMTIME_RET(tm_mon + 1)
}

- (int)localMonthOfYear
{
	LOCALTIME_RET(tm_mon + 1)
}

- (int)year
{
	GMTIME_RET(tm_year + 1900)
}

- (int)dayOfWeek
{
	GMTIME_RET(tm_wday)
}

- (int)localDayOfWeek
{
	LOCALTIME_RET(tm_wday)
}

- (int)dayOfYear
{
	GMTIME_RET(tm_yday + 1)
}

- (int)localDayOfYear
{
	LOCALTIME_RET(tm_yday + 1)
}

- (OFString*)dateStringWithFormat: (OFString*)fmt
{
	struct tm tm;
	char *buf;

#ifdef HAVE_GMTIME_R
	if (gmtime_r(&sec, &tm) == NULL)
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
	struct tm tm;
	char *buf;

#ifdef HAVE_LOCALTIME_R
	if (localtime_r(&sec, &tm) == NULL)
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
@end
