/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#define OF_DATE_M

#include "config.h"

#include <limits.h>
#include <time.h>
#include <math.h>

#include <sys/time.h>

#import "OFDate.h"
#import "OFConcreteDate.h"
#import "OFData.h"
#import "OFDictionary.h"
#import "OFMessagePackExtension.h"
#ifdef OF_HAVE_THREADS
# import "OFMutex.h"
#endif
#import "OFStrFTime.h"
#import "OFStrPTime.h"
#import "OFString.h"
#import "OFSystemInfo.h"
#import "OFTaggedPointerDate.h"
#import "OFXMLAttribute.h"

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

#if defined(OF_AMIGAOS_M68K) || defined(OF_MINT)
/* amiga-gcc and freemint-gcc do not have trunc() */
# define trunc(x) ((int64_t)(x))
#endif

#ifdef OF_MORPHOS
# include <devices/timer.h>
# include <ppcinline/timer.h>

extern struct Device *TimerBase;
#endif

@interface OFPlaceholderDate: OFDate
@end

@interface OFConcreteDateSingleton: OFConcreteDate
@end

static struct {
	Class isa;
} placeholder;

static OFConcreteDateSingleton *zeroDate, *distantFuture, *distantPast;

static void
initZeroDate(void)
{
	zeroDate = [[OFConcreteDateSingleton alloc]
	    initWithTimeIntervalSince1970: 0];
}

static void
initDistantFuture(void)
{
	distantFuture = [[OFConcreteDateSingleton alloc]
	    initWithTimeIntervalSince1970: 64060588800.0];
}

static void
initDistantPast(void)
{
	distantPast = [[OFConcreteDateSingleton alloc]
	    initWithTimeIntervalSince1970: -62167219200.0];
}

static OFTimeInterval
now(void)
{
#if defined(OF_MORPHOS)
	struct timeval tv;

	GetUTCSysTime(&tv);

	return 252460800.0 + tv.tv_secs + (OFTimeInterval)tv.tv_usec / 1000000;
#elif defined(HAVE_CLOCK_GETTIME)
	struct timespec ts;

	OFEnsure(clock_gettime(CLOCK_REALTIME, &ts) == 0);

	return ts.tv_sec + (OFTimeInterval)ts.tv_nsec / 1000000000;
#else
	struct timeval tv;

	OFEnsure(gettimeofday(&tv, NULL) == 0);

	return tv.tv_sec + (OFTimeInterval)tv.tv_usec / 1000000;
#endif
}

#if (!defined(HAVE_GMTIME_R) || !defined(HAVE_LOCALTIME_R)) && \
    defined(OF_HAVE_THREADS)
static OFMutex *mutex;

static void
releaseMutex(void)
{
	objc_release(mutex);
}
#endif

#ifdef OF_WINDOWS
static __time64_t (*_mktime64FuncPtr)(struct tm *);
#endif

#ifdef HAVE_GMTIME_R
# define GMTIME_RET(field)						\
	OFTimeInterval timeInterval = self.timeIntervalSince1970;	\
	time_t seconds = (time_t)timeInterval;				\
	struct tm tm;							\
									\
	if (seconds != trunc(timeInterval))				\
		@throw [OFOutOfRangeException exception];		\
									\
	if (gmtime_r(&seconds, &tm) == NULL)				\
		@throw [OFOutOfRangeException exception];		\
									\
	return tm.field;
# define LOCALTIME_RET(field)						\
	OFTimeInterval timeInterval = self.timeIntervalSince1970;	\
	time_t seconds = (time_t)timeInterval;				\
	struct tm tm;							\
									\
	if (seconds != trunc(timeInterval))				\
		@throw [OFOutOfRangeException exception];		\
									\
	if (localtime_r(&seconds, &tm) == NULL)				\
		@throw [OFOutOfRangeException exception];		\
									\
	return tm.field;
#else
# ifdef OF_HAVE_THREADS
#  define GMTIME_RET(field)						\
	OFTimeInterval timeInterval = self.timeIntervalSince1970;	\
	time_t seconds = (time_t)timeInterval;				\
	struct tm *tm;							\
									\
	if (seconds != trunc(timeInterval))				\
		@throw [OFOutOfRangeException exception];		\
									\
	[mutex lock];							\
									\
	@try {								\
		if ((tm = gmtime(&seconds)) == NULL)			\
			@throw [OFOutOfRangeException exception];	\
									\
		return tm->field;					\
	} @finally {							\
		[mutex unlock];						\
	}
#  define LOCALTIME_RET(field)						\
	OFTimeInterval timeInterval = self.timeIntervalSince1970;	\
	time_t seconds = (time_t)timeInterval;				\
	struct tm *tm;							\
									\
	if (seconds != trunc(timeInterval))				\
		@throw [OFOutOfRangeException exception];		\
									\
	[mutex lock];							\
									\
	@try {								\
		if ((tm = localtime(&seconds)) == NULL)			\
			@throw [OFOutOfRangeException exception];	\
									\
		return tm->field;					\
	} @finally {							\
		[mutex unlock];						\
	}
# else
#  define GMTIME_RET(field)						\
	OFTimeInterval timeInterval = self.timeIntervalSince1970;	\
	time_t seconds = (time_t)timeInterval;				\
	struct tm *tm;							\
									\
	if (seconds != trunc(timeInterval))				\
		@throw [OFOutOfRangeException exception];		\
									\
	if ((tm = gmtime(&seconds)) == NULL)				\
		@throw [OFOutOfRangeException exception];		\
									\
	return tm->field;
#  define LOCALTIME_RET(field)						\
	OFTimeInterval timeInterval = self.timeIntervalSince1970;	\
	time_t seconds = (time_t)timeInterval;				\
	struct tm *tm;							\
									\
	if (seconds != trunc(timeInterval))				\
		@throw [OFOutOfRangeException exception];		\
									\
	if ((tm = localtime(&seconds)) == NULL)				\
		@throw [OFOutOfRangeException exception];		\
									\
	return tm->field;
# endif
#endif

static int monthToDayOfYear[12] = {
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

static double
tmAndTzToTime(const struct tm *tm, short tz)
{
	double seconds;

	/* Years */
	seconds = (int64_t)(tm->tm_year - 70) * 31536000;
	/* Days of leap years, excluding the year to look at */
	seconds += (((tm->tm_year + 1899) / 4) - 492) * 86400;
	seconds -= (((tm->tm_year + 1899) / 100) - 19) * 86400;
	seconds += (((tm->tm_year + 1899) / 400) - 4) * 86400;
	/* Leap day */
	if (tm->tm_mon >= 2 && (((tm->tm_year + 1900) % 4 == 0 &&
	    (tm->tm_year + 1900) % 100 != 0) ||
	    (tm->tm_year + 1900) % 400 == 0))
		seconds += 86400;
	/* Months */
	if (tm->tm_mon < 0 || tm->tm_mon > 12)
		@throw [OFInvalidFormatException exception];
	seconds += monthToDayOfYear[tm->tm_mon] * 86400;
	/* Days */
	seconds += (tm->tm_mday - 1) * 86400;
	/* Hours */
	seconds += tm->tm_hour * 3600;
	/* Minutes */
	seconds += tm->tm_min * 60;
	/* Seconds */
	seconds += tm->tm_sec;
	/* Time zone */
	seconds += -(double)tz * 60;

	return seconds;
}

@implementation OFConcreteDateSingleton
OF_SINGLETON_METHODS
@end

@implementation OFPlaceholderDate
#ifdef __clang__
/* We intentionally don't call into super, so silence the warning. */
# pragma clang diagnostic push
# pragma clang diagnostic ignored "-Wunknown-pragmas"
# pragma clang diagnostic ignored "-Wobjc-designated-initializers"
#endif
- (instancetype)initWithTimeIntervalSince1970: (OFTimeInterval)seconds
{
#if defined(OF_OBJFW_RUNTIME) && UINTPTR_MAX == UINT64_MAX
	uint64_t value;
#endif

	if (seconds == 0) {
		static OFOnceControl once = OFOnceControlInitValue;
		OFOnce(&once, initZeroDate);
		return (id)zeroDate;
	}

#if defined(OF_OBJFW_RUNTIME) && UINTPTR_MAX == UINT64_MAX
	value = OFFromBigEndian64(OFBitConvertDoubleToUInt64(
	    OFToBigEndianDouble(seconds)));

	/* Almost all dates fall into this range. */
	if (value & (UINT64_C(4) << 60)) {
		id ret = [OFTaggedPointerDate
		    dateWithUInt64TimeIntervalSince1970: value];

		if (ret != nil)
			return ret;
	}
#endif

	return (id)[[OFConcreteDate alloc]
	    initWithTimeIntervalSince1970: seconds];
}
#ifdef __clang__
# pragma clang diagnostic pop
#endif

OF_SINGLETON_METHODS
@end

@implementation OFDate
+ (void)initialize
{
#ifdef OF_WINDOWS
	HMODULE module;
#endif

	if (self != [OFDate class])
		return;

	object_setClass((id)&placeholder, [OFPlaceholderDate class]);

#if (!defined(HAVE_GMTIME_R) || !defined(HAVE_LOCALTIME_R)) && \
    defined(OF_HAVE_THREADS)
	mutex = [[OFMutex alloc] init];
	atexit(releaseMutex);
#endif

#ifdef OF_WINDOWS
	if ((module = GetModuleHandle("msvcrt.dll")) != NULL)
		_mktime64FuncPtr = (__time64_t (*)(struct tm *))
		    GetProcAddress(module, "_mktime64");
#endif
}

+ (instancetype)alloc
{
	if (self == [OFDate class])
		return (id)&placeholder;

	return [super alloc];
}

+ (instancetype)date
{
	return objc_autoreleaseReturnValue([[self alloc] init]);
}

+ (instancetype)dateWithTimeIntervalSince1970: (OFTimeInterval)seconds
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithTimeIntervalSince1970: seconds]);
}

+ (instancetype)dateWithTimeIntervalSinceNow: (OFTimeInterval)seconds
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithTimeIntervalSinceNow: seconds]);
}

+ (instancetype)dateWithDateString: (OFString *)string
			    format: (OFString *)format
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithDateString: string
				      format: format]);
}

+ (instancetype)dateWithLocalDateString: (OFString *)string
				 format: (OFString *)format
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithLocalDateString: string
					   format: format]);
}

+ (instancetype)distantFuture
{
	static OFOnceControl once = OFOnceControlInitValue;
	OFOnce(&once, initDistantFuture);
	return distantFuture;
}

+ (instancetype)distantPast
{
	static OFOnceControl once = OFOnceControlInitValue;
	OFOnce(&once, initDistantPast);
	return distantPast;
}

- (instancetype)init
{
	return [self initWithTimeIntervalSince1970: now()];
}

- (instancetype)initWithTimeIntervalSince1970: (OFTimeInterval)seconds
{
	if ([self isMemberOfClass: [OFDate class]]) {
		@try {
			[self doesNotRecognizeSelector: _cmd];
		} @catch (id e) {
			objc_release(self);
			@throw e;
		}

		abort();
	}

	return [super init];
}

- (instancetype)initWithTimeIntervalSinceNow: (OFTimeInterval)seconds
{
	return [self initWithTimeIntervalSince1970: now() + seconds];
}

- (instancetype)initWithDateString: (OFString *)string
			    format: (OFString *)format
{
	void *pool = objc_autoreleasePoolPush();
	const char *UTF8String = string.UTF8String;
	struct tm tm = { .tm_isdst = -1 };
	short tz = 0;

	if (_OFStrPTime(UTF8String, format.UTF8String, &tm, &tz) !=
	    UTF8String + string.UTF8StringLength)
		@throw [OFInvalidFormatException exception];

	objc_autoreleasePoolPop(pool);

	return [self initWithTimeIntervalSince1970: tmAndTzToTime(&tm, tz)];
}

- (instancetype)initWithLocalDateString: (OFString *)string
				 format: (OFString *)format
{
	void *pool = objc_autoreleasePoolPush();
	const char *UTF8String = string.UTF8String;
	struct tm tm = { .tm_isdst = -1 };
	/*
	 * _OFStrPTime() can never set this to SHRT_MAX, no matter what is
	 * passed to it, so this is a safe way to figure out if the date
	 * contains a time zone.
	 */
	short tz = SHRT_MAX;
	OFTimeInterval seconds;

	if (_OFStrPTime(UTF8String, format.UTF8String, &tm, &tz) !=
	    UTF8String + string.UTF8StringLength)
		@throw [OFInvalidFormatException exception];

	if (tz == SHRT_MAX) {
#ifdef OF_WINDOWS
		if (_mktime64FuncPtr != NULL) {
			if ((seconds = _mktime64FuncPtr(&tm)) == -1)
				@throw [OFInvalidFormatException exception];
		} else {
#endif
			if ((seconds = mktime(&tm)) == -1)
				@throw [OFInvalidFormatException exception];
#ifdef OF_WINDOWS
		}
#endif
	} else
		seconds = tmAndTzToTime(&tm, tz);

	objc_autoreleasePoolPop(pool);

	return [self initWithTimeIntervalSince1970: seconds];
}

- (bool)isEqual: (id)object
{
	OFDate *otherDate;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFDate class]])
		return false;

	otherDate = object;

	if (otherDate.timeIntervalSince1970 != self.timeIntervalSince1970)
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;
	double tmp;

	OFHashInit(&hash);

	tmp = OFToLittleEndianDouble(self.timeIntervalSince1970);

	for (size_t i = 0; i < sizeof(double); i++)
		OFHashAddByte(&hash, ((char *)&tmp)[i]);

	OFHashFinalize(&hash);

	return hash;
}

- (id)copy
{
	return objc_retain(self);
}

- (OFComparisonResult)compare: (OFDate *)date
{
	if (![date isKindOfClass: [OFDate class]])
		@throw [OFInvalidArgumentException exception];

	if (self.timeIntervalSince1970 < date.timeIntervalSince1970)
		return OFOrderedAscending;
	if (self.timeIntervalSince1970 > date.timeIntervalSince1970)
		return OFOrderedDescending;

	return OFOrderedSame;
}

- (OFString *)description
{
	return [self dateStringWithFormat: @"%Y-%m-%dT%H:%M:%S%z"];
}

- (OFData *)messagePackRepresentation
{
	void *pool = objc_autoreleasePoolPush();
	OFTimeInterval timeInterval = self.timeIntervalSince1970;
	int64_t seconds = (int64_t)timeInterval;
	uint32_t nanoseconds =
	    (uint32_t)((timeInterval - trunc(timeInterval)) * 1000000000);
	OFData *ret;

	if (seconds >= 0 && seconds < 0x400000000) {
		if (seconds <= UINT32_MAX && nanoseconds == 0) {
			uint32_t seconds32 = (uint32_t)seconds;
			OFData *data;

			seconds32 = OFToBigEndian32(seconds32);
			data = [OFData dataWithItems: &seconds32
					       count: sizeof(seconds32)];

			ret = [[OFMessagePackExtension
			    extensionWithType: -1
					 data: data] messagePackRepresentation];
		} else {
			uint64_t combined = ((uint64_t)nanoseconds << 34) |
			    (uint64_t)seconds;
			OFData *data;

			combined = OFToBigEndian64(combined);
			data = [OFData dataWithItems: &combined
					       count: sizeof(combined)];

			ret = [[OFMessagePackExtension
			    extensionWithType: -1
					 data: data] messagePackRepresentation];
		}
	} else {
		OFMutableData *data = [OFMutableData dataWithCapacity: 12];

		nanoseconds = OFToBigEndian32(nanoseconds);
		[data addItems: &nanoseconds count: sizeof(nanoseconds)];
		seconds = OFToBigEndian64(seconds);
		[data addItems: &seconds count: sizeof(seconds)];

		ret = [[OFMessagePackExtension
		    extensionWithType: -1
				 data: data] messagePackRepresentation];
	}

	objc_retain(ret);

	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(ret);
}

- (unsigned long)microsecond
{
	OFTimeInterval timeInterval = self.timeIntervalSince1970;

	return (unsigned long)((timeInterval - trunc(timeInterval)) * 1000000);
}

- (unsigned char)second
{
	GMTIME_RET(tm_sec)
}

- (unsigned char)minute
{
	GMTIME_RET(tm_min)
}

- (unsigned char)localMinute
{
	LOCALTIME_RET(tm_min)
}

- (unsigned char)hour
{
	GMTIME_RET(tm_hour)
}

- (unsigned char)localHour
{
	LOCALTIME_RET(tm_hour)
}

- (unsigned char)dayOfMonth
{
	GMTIME_RET(tm_mday)
}

- (unsigned char)localDayOfMonth
{
	LOCALTIME_RET(tm_mday)
}

- (unsigned char)monthOfYear
{
	GMTIME_RET(tm_mon + 1)
}

- (unsigned char)localMonthOfYear
{
	LOCALTIME_RET(tm_mon + 1)
}

- (unsigned short)year
{
	GMTIME_RET(tm_year + 1900)
}

- (unsigned short)localYear
{
	LOCALTIME_RET(tm_year + 1900)
}

- (unsigned char)dayOfWeek
{
	GMTIME_RET(tm_wday)
}

- (unsigned char)localDayOfWeek
{
	LOCALTIME_RET(tm_wday)
}

- (unsigned short)dayOfYear
{
	GMTIME_RET(tm_yday + 1)
}

- (unsigned short)localDayOfYear
{
	LOCALTIME_RET(tm_yday + 1)
}

- (OFString *)dateStringWithFormat: (OFConstantString *)format
{
	OFString *ret;
	OFTimeInterval timeInterval = self.timeIntervalSince1970;
	time_t seconds = (time_t)timeInterval;
	struct tm tm;
	size_t pageSize;
	char *buffer;

	if (seconds != trunc(timeInterval))
		@throw [OFOutOfRangeException exception];

#ifdef HAVE_GMTIME_R
	if (gmtime_r(&seconds, &tm) == NULL)
		@throw [OFOutOfRangeException exception];
#else
# ifdef OF_HAVE_THREADS
	[mutex lock];

	@try {
# endif
		struct tm *tmp;

		if ((tmp = gmtime(&seconds)) == NULL)
			@throw [OFOutOfRangeException exception];

		tm = *tmp;
# ifdef OF_HAVE_THREADS
	} @finally {
		[mutex unlock];
	}
# endif
#endif

	pageSize = [OFSystemInfo pageSize];
	buffer = OFAllocMemory(1, pageSize);
	@try {
		if (_OFStrFTime(buffer, pageSize, format.UTF8String, &tm,
		    0) == 0)
			@throw [OFOutOfRangeException exception];

		ret = [OFString stringWithUTF8String: buffer];
	} @finally {
		OFFreeMemory(buffer);
	}

	return ret;
}

- (OFString *)localDateStringWithFormat: (OFConstantString *)format
{
	OFString *ret;
	OFTimeInterval timeInterval = self.timeIntervalSince1970;
	time_t seconds = (time_t)timeInterval;
	struct tm tm;
	size_t pageSize;
	char *buffer;

	if (seconds != trunc(timeInterval))
		@throw [OFOutOfRangeException exception];

#ifdef HAVE_LOCALTIME_R
	if (localtime_r(&seconds, &tm) == NULL)
		@throw [OFOutOfRangeException exception];
#else
# ifdef OF_HAVE_THREADS
	[mutex lock];

	@try {
# endif
		struct tm *tmp;

		if ((tmp = localtime(&seconds)) == NULL)
			@throw [OFOutOfRangeException exception];

		tm = *tmp;
# ifdef OF_HAVE_THREADS
	} @finally {
		[mutex unlock];
	}
# endif
#endif

	pageSize = [OFSystemInfo pageSize];
	buffer = OFAllocMemory(1, pageSize);
	@try {
		if (_OFStrFTime(buffer, pageSize, format.UTF8String, &tm,
		    0) == 0)
			@throw [OFOutOfRangeException exception];

		ret = [OFString stringWithUTF8String: buffer];
	} @finally {
		OFFreeMemory(buffer);
	}

	return ret;
}

- (OFDate *)earlierDate: (OFDate *)otherDate
{
	if (otherDate == nil)
		return self;

	if ([self compare: otherDate] == OFOrderedDescending)
		return otherDate;

	return self;
}

- (OFDate *)laterDate: (OFDate *)otherDate
{
	if (otherDate == nil)
		return self;

	if ([self compare: otherDate] == OFOrderedAscending)
		return otherDate;

	return self;
}

- (OFTimeInterval)timeIntervalSince1970
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFTimeInterval)timeIntervalSinceDate: (OFDate *)otherDate
{
	return self.timeIntervalSince1970 - otherDate.timeIntervalSince1970;
}

- (OFTimeInterval)timeIntervalSinceNow
{
	struct timeval t;
	OFTimeInterval seconds;

	OFEnsure(gettimeofday(&t, NULL) == 0);

	seconds = t.tv_sec;
	seconds += (OFTimeInterval)t.tv_usec / 1000000;

	return self.timeIntervalSince1970 - seconds;
}

- (OFDate *)dateByAddingTimeInterval: (OFTimeInterval)seconds
{
	return [OFDate dateWithTimeIntervalSince1970:
	    self.timeIntervalSince1970 + seconds];
}
@end
