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
#import "OFExceptions.h"

#if !defined(HAVE_GMTIME_R) && defined(OF_THREADS)
# import "OFThread.h"

static OFMutex *mutex;
#endif

@implementation OFDate
#if !defined(HAVE_GMTIME_R) && defined(OF_THREADS)
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
	char str[20];	/* YYYY-MM-DD hh:mm:ss */

#ifdef HAVE_GMTIME_R
	struct tm tm;

	if (gmtime_r(&sec, &tm) == NULL)
		@throw [OFOutOfRangeException newWithClass: isa];

	strftime(str, 20, "%Y-%m-%dT%H:%M:%S", &tm);
#else
	struct tm *tm;

# ifdef OF_THREADS
	[mutex lock];

	@try {
# endif
		if ((tm = gmtime(&sec)) == NULL)
			@throw [OFOutOfRangeException newWithClass: isa];

		strftime(str, 20, "%Y-%m-%dT%H:%M:%S", tm);
# ifdef OF_THREADS
	} @finally {
		[mutex unlock];
	}
# endif
#endif

	if (usec == 0)
		return [OFString stringWithFormat: @"%sZ", str];

	return [OFString stringWithFormat: @"%s.%06dZ", str, usec];
}
@end
